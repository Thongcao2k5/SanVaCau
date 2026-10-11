import { Router } from "express";
import { randomUUID } from "node:crypto";
import { Prisma, type payment } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { createNotification } from "../lib/notification.js";
import { VnpayError, vnpayConfig, vnpayPaymentUrl, verifyVnpay, queryVnpay } from "../lib/vnpay.js";

export const vnpayRouter = Router();
const serialize = (p: payment) => ({
  id: p.id.toString(), targetType: p.target_type, targetId: p.target_id.toString(),
  provider: p.provider, amount: p.amount.toString(), status: p.status,
  transactionRef: p.transaction_ref, checkoutUrl: p.checkout_url,
  createdAt: p.created_at.toISOString(), paidAt: p.paid_at?.toISOString() ?? null,
  failedAt: p.failed_at?.toISOString() ?? null,
});
const id = (value: unknown) => typeof value === "string" && /^[1-9]\d*$/.test(value) ? BigInt(value) : null;
vnpayRouter.get("/config", requireAuth, (_req, res) => {
  try { vnpayConfig(); res.json({ success: true, data: { configured: true, environment: "sandbox" } }); }
  catch (error) { res.status(503).json({ success: false, message: (error as Error).message }); }
});

vnpayRouter.post("/", requireAuth, async (req, res, next) => {
  try {
    vnpayConfig();
    const targetType = req.body.targetType;
    const targetId = id(String(req.body.targetId ?? ""));
    if (!["ORDER", "BOOKING"].includes(targetType) || !targetId) throw new VnpayError("Đối tượng thanh toán không hợp lệ.", 400);
    const userId = BigInt(req.user!.id);
    const p = await prisma.$transaction(async tx => {
      // Serialize payment attempts for the same order/booking.
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${`${targetType}:${targetId}`}))`;
      let amount: Prisma.Decimal;
      if (targetType === "ORDER") {
        const order = await tx.customer_order.findUnique({ where: { id: targetId }, include: { order_fulfillment: true } });
        if (!order || order.customer_id !== userId) throw new VnpayError("Không tìm thấy đơn hàng của bạn.", 404);
        if (order.status === "CANCELLED") throw new VnpayError("Đơn hàng đã hủy.", 409);
        amount = order.total_amount.add(order.order_fulfillment?.shipping_fee ?? 0);
      } else {
        const booking = await tx.booking.findUnique({ where: { id: targetId } });
        if (!booking || booking.customer_id !== userId) throw new VnpayError("Không tìm thấy lịch đặt của bạn.", 404);
        if (booking.status === "CANCELLED" || booking.payment_status === "PAID") throw new VnpayError("Lịch đặt không thể thanh toán.", 409);
        amount = booking.total_amount;
      }
      if (!amount.isInteger() || amount.lt(1000) || amount.gt(50000000)) throw new VnpayError("Ứng dụng hỗ trợ VNPay Sandbox với số tiền nguyên từ 1.000 đến 50.000.000 đ.", 400);
      const existing = await tx.payment.findFirst({ where: { target_type: targetType, target_id: targetId, status: { in: ["PENDING", "PAID"] } }, orderBy: { created_at: "desc" } });
      if (existing) {
        if (existing.status === "PAID") throw new VnpayError("Đơn này đã thanh toán.", 409);
        if (existing.provider !== "VNPAY_SANDBOX") throw new VnpayError("Đơn này đang có phương thức thanh toán khác.", 409);
        if (!existing.amount.equals(amount)) throw new VnpayError("Số tiền đơn hàng đã thay đổi, cần kiểm tra giao dịch đang chờ.", 409);
        return existing;
      }
      return tx.payment.create({ data: { user_id: userId, target_type: targetType, target_id: targetId,
        provider: "VNPAY_SANDBOX", amount, transaction_ref: `SVC${randomUUID().replace(/-/g, "")}` } });
    });
    if (p.checkout_url) { res.json({ success: true, data: serialize(p) }); return; }
    const checkoutUrl = vnpayPaymentUrl(p.transaction_ref!, p.amount.toFixed(0),
      `SanVaCau ${p.target_type} ${p.target_id}`, req.ip ?? "127.0.0.1");
    const updated = await prisma.payment.update({ where: { id: p.id }, data: { checkout_url: checkoutUrl, updated_at: new Date() } });
    res.json({ success: true, data: serialize(updated) });
  } catch (error) {
    if (error instanceof VnpayError) { res.status(error.status).json({ success: false, message: error.message }); return; }
    next(error);
  }
});


// Only a verified server callback can settle a transaction. Browser redirects never settle it.
vnpayRouter.get("/ipn", async (req, res) => {
  const reply = (RspCode: string, Message: string) => res.json({ RspCode, Message });
  try {
    const config = vnpayConfig();
    const fields: Record<string, string> = {};
    for (const [key, value] of Object.entries(req.query)) {
      if (!key.startsWith("vnp_")) continue;
      if (typeof value !== "string") { reply("97", "Invalid parameters"); return; }
      fields[key] = value;
    }
    if (!verifyVnpay(fields, config.hashSecret) || fields.vnp_TmnCode !== config.tmnCode) {
      reply("97", "Invalid signature"); return;
    }
    const p = await prisma.payment.findUnique({ where: { transaction_ref: fields.vnp_TxnRef ?? "" } });
    if (!p || p.provider !== "VNPAY_SANDBOX") { reply("01", "Order not found"); return; }
    if (fields.vnp_Amount !== p.amount.mul(100).toFixed(0)) { reply("04", "Invalid amount"); return; }
    if (!/^\d{2}$/.test(fields.vnp_ResponseCode ?? "") || !/^\d{2}$/.test(fields.vnp_TransactionStatus ?? "") ||
        !/^\d{1,100}$/.test(fields.vnp_TransactionNo ?? "")) { reply("99", "Invalid result"); return; }
    const paid = fields.vnp_ResponseCode === "00" && fields.vnp_TransactionStatus === "00";
    // Pending/uncertain results must not enable another charge.
    const failed = fields.vnp_TransactionStatus === "02" &&
      ["09", "10", "11", "12", "13", "24", "51", "65", "75", "79", "99"].includes(fields.vnp_ResponseCode!);
    if (!paid && !failed) {
      reply("99", "Transaction requires reconciliation"); return;
    }
    const changed = await prisma.$transaction(async tx => {
      const updated = await tx.payment.updateMany({ where: { id: p.id, status: "PENDING" },
        data: { status: paid ? "PAID" : "FAILED", paid_at: paid ? new Date() : null,
          failed_at: paid ? null : new Date(), updated_at: new Date(), gateway_trans_id: fields.vnp_TransactionNo } });
      if (updated.count && paid && p.target_type === "BOOKING") {
        await tx.booking.update({ where: { id: p.target_id }, data: { payment_status: "PAID" } });
      }
      return updated.count > 0;
    });
    if (changed) createNotification({ userId: p.user_id.toString(), type: paid ? "PAYMENT_SUCCESS" : "PAYMENT_FAILED",
      title: paid ? "VNPay Sandbox thành công" : "VNPay Sandbox thất bại",
      message: `Giao dịch ${p.transaction_ref}: ${paid ? "thành công" : "thất bại"}.`, data: { paymentId: p.id.toString() } });
    reply(changed ? "00" : "02", changed ? "Confirm Success" : "Order already confirmed");
  } catch { reply("99", "Unable to confirm transaction"); }
});

vnpayRouter.get("/return", (_req, res) => {
  res.type("html").send('<!doctype html><html lang="vi"><meta name="viewport" content="width=device-width,initial-scale=1"><title>VNPay Sandbox</title><body><h2>Trở về Sân &amp; Cầu</h2><p>Mở ứng dụng và kiểm tra kết quả thanh toán.</p><a href="sanvacau://vnpay-return">Mở ứng dụng</a></body></html>');
});

vnpayRouter.post("/:id/check", requireAuth, async (req, res, next) => {
  try {
    const paymentId = id(req.params.id);
    if (!paymentId) { res.status(400).json({ success: false, message: "Mã thanh toán không hợp lệ." }); return; }
    const p = await prisma.payment.findUnique({ where: { id: paymentId } });
    if (!p || p.user_id !== BigInt(req.user!.id) || p.provider !== "VNPAY_SANDBOX") {
      res.status(404).json({ success: false, message: "Không tìm thấy giao dịch của bạn." }); return;
    }
    if (p.status === "PENDING" && p.checkout_url && p.transaction_ref) {
      const result = await queryVnpay(p.transaction_ref, p.checkout_url, p.amount.toFixed(0));
      const status = result.vnp_TransactionStatus === "00" ? "PAID" : result.vnp_TransactionStatus === "02" ? "FAILED" : null;
      if (status) {
        await prisma.$transaction(async tx => {
          const changed = await tx.payment.updateMany({ where: { id: p.id, status: "PENDING" },
            data: { status, paid_at: status === "PAID" ? new Date() : null,
              failed_at: status === "FAILED" ? new Date() : null, updated_at: new Date(), gateway_trans_id: result.vnp_TransactionNo } });
          if (changed.count && status === "PAID" && p.target_type === "BOOKING") {
            await tx.booking.update({ where: { id: p.target_id }, data: { payment_status: "PAID" } });
          }
        });
      }
    }
    res.json({ success: true, data: serialize(await prisma.payment.findUniqueOrThrow({ where: { id: p.id } })) });
  } catch (error) {
    if (error instanceof VnpayError) { res.status(error.status).json({ success: false, message: error.message }); return; }
    next(error);
  }
});
