import { Router } from "express";
import { randomUUID } from "node:crypto";
import { Prisma, type payment } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { createNotification } from "../lib/notification.js";
import { MomoError, momoConfig, momoRequest, momoSignature, verifyMomoIpn, validMomoPayUrl, isMomoFinalFailure } from "../lib/momo.js";

export const momoRouter = Router();
const serialize = (p: payment) => ({
  id: p.id.toString(), targetType: p.target_type, targetId: p.target_id.toString(),
  provider: p.provider, amount: p.amount.toString(), status: p.status,
  transactionRef: p.transaction_ref, checkoutUrl: p.checkout_url,
  createdAt: p.created_at.toISOString(), paidAt: p.paid_at?.toISOString() ?? null,
  failedAt: p.failed_at?.toISOString() ?? null,
});
const id = (value: unknown) => typeof value === "string" && /^[1-9]\d*$/.test(value) ? BigInt(value) : null;
const orderInfo = (p: payment) => `SanVaCau ${p.target_type} #${p.target_id}`;

const applyResult = async (p: payment, result: Record<string, unknown>) => {
  const config = momoConfig();
  if (result.partnerCode !== config.partnerCode || result.orderId !== p.transaction_ref ||
      Number(result.amount) !== Number(p.amount) || !Number.isInteger(result.resultCode)) {
    throw new MomoError("Thông tin giao dịch MoMo không khớp.", 400);
  }
  const code = Number(result.resultCode);
  if (code !== 0 && !isMomoFinalFailure(code)) return p;
  const status = code === 0 ? "PAID" : "FAILED";
  const changed = await prisma.$transaction(async tx => {
    const update = await tx.payment.updateMany({
      where: { id: p.id, status: "PENDING", provider: "MOMO_SANDBOX" },
      data: { status, paid_at: code === 0 ? new Date() : null,
        failed_at: code === 0 ? null : new Date(), updated_at: new Date(),
        gateway_trans_id: String(result.transId ?? "") },
    });
    if (update.count && code === 0 && p.target_type === "BOOKING") {
      await tx.booking.update({ where: { id: p.target_id }, data: { payment_status: "PAID" } });
    }
    return update.count > 0;
  });
  if (changed) createNotification({ userId: p.user_id.toString(), type: code === 0 ? "PAYMENT_SUCCESS" : "PAYMENT_FAILED",
    title: code === 0 ? "MoMo Sandbox thành công" : "MoMo Sandbox thất bại",
    message: `Giao dịch thử nghiệm ${p.transaction_ref}: ${code === 0 ? "thành công" : "thất bại"}.`,
    data: { paymentId: p.id.toString() },
  });
  return (await prisma.payment.findUniqueOrThrow({ where: { id: p.id } }));
};

momoRouter.get("/config", requireAuth, (_req, res) => {
  try { momoConfig(); res.json({ success: true, data: { configured: true, environment: "sandbox" } }); }
  catch (error) { res.status(503).json({ success: false, message: (error as Error).message }); }
});

momoRouter.post("/", requireAuth, async (req, res, next) => {
  try {
    const config = momoConfig();
    const targetType = req.body.targetType;
    const targetId = id(String(req.body.targetId ?? ""));
    if (!["ORDER", "BOOKING"].includes(targetType) || !targetId) throw new MomoError("Đối tượng thanh toán không hợp lệ.", 400);
    const userId = BigInt(req.user!.id);
    const p = await prisma.$transaction(async tx => {
      // Serialize payment attempts for the same order/booking.
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${`${targetType}:${targetId}`}))`;
      let amount: Prisma.Decimal;
      if (targetType === "ORDER") {
        const order = await tx.customer_order.findUnique({ where: { id: targetId }, include: { order_fulfillment: true } });
        if (!order || order.customer_id !== userId) throw new MomoError("Không tìm thấy đơn hàng của bạn.", 404);
        if (order.status === "CANCELLED") throw new MomoError("Đơn hàng đã hủy.", 409);
        amount = order.total_amount.add(order.order_fulfillment?.shipping_fee ?? 0);
      } else {
        const booking = await tx.booking.findUnique({ where: { id: targetId } });
        if (!booking || booking.customer_id !== userId) throw new MomoError("Không tìm thấy lịch đặt của bạn.", 404);
        if (booking.status === "CANCELLED" || booking.payment_status === "PAID") throw new MomoError("Lịch đặt không thể thanh toán.", 409);
        amount = booking.total_amount;
      }
      if (!amount.isInteger() || amount.lt(1000) || amount.gt(50000000)) throw new MomoError("MoMo chấp nhận số tiền nguyên từ 1.000 đến 50.000.000 đ.", 400);
      const existing = await tx.payment.findFirst({ where: { target_type: targetType, target_id: targetId, status: { in: ["PENDING", "PAID"] } }, orderBy: { created_at: "desc" } });
      if (existing) {
        if (existing.status === "PAID") throw new MomoError("Đơn này đã thanh toán.", 409);
        if (existing.provider !== "MOMO_SANDBOX") throw new MomoError("Đơn này đang có phương thức thanh toán khác.", 409);
        if (!existing.amount.equals(amount)) throw new MomoError("Số tiền đơn hàng đã thay đổi, cần kiểm tra giao dịch đang chờ.", 409);
        return existing;
      }
      return tx.payment.create({ data: { user_id: userId, target_type: targetType, target_id: targetId,
        provider: "MOMO_SANDBOX", amount, transaction_ref: `SVC_${randomUUID()}` } });
    });
    if (p.checkout_url) { res.json({ success: true, data: serialize(p) }); return; }
    const fields = { accessKey: config.accessKey, amount: Number(p.amount), extraData: "", ipnUrl: config.ipnUrl,
      orderId: p.transaction_ref!, orderInfo: orderInfo(p), partnerCode: config.partnerCode,
      redirectUrl: config.redirectUrl, requestId: p.transaction_ref!, requestType: "captureWallet" };
    const { accessKey: _, ...body } = fields;
    const result = await momoRequest("create", { ...body, signature: momoSignature(fields, config.secretKey), autoCapture: true, lang: "vi" });
    if (result.resultCode !== 0) throw new MomoError(`MoMo Sandbox: ${String(result.message ?? "Không tạo được giao dịch")} (mã ${result.resultCode}).`);
    if (result.partnerCode !== config.partnerCode || result.orderId !== p.transaction_ref || result.requestId !== p.transaction_ref ||
        Number(result.amount) !== Number(p.amount) || !validMomoPayUrl(result.payUrl)) throw new MomoError("Phản hồi tạo giao dịch MoMo không hợp lệ.");
    const expected = momoSignature({ accessKey: config.accessKey, amount: result.amount, orderId: result.orderId,
      partnerCode: result.partnerCode, payUrl: result.payUrl, requestId: result.requestId, responseTime: result.responseTime, resultCode: result.resultCode }, config.secretKey);
    if (result.signature !== expected) throw new MomoError("Chữ ký phản hồi MoMo không hợp lệ.");
    const updated = await prisma.payment.update({ where: { id: p.id }, data: { checkout_url: result.payUrl, updated_at: new Date() } });
    res.json({ success: true, data: serialize(updated) });
  } catch (error) {
    if (error instanceof MomoError) { res.status(error.status).json({ success: false, message: error.message }); return; }
    next(error);
  }
});

momoRouter.post("/ipn", async (req, res, next) => {
  try {
    if (!verifyMomoIpn(req.body)) throw new MomoError("Chữ ký MoMo không hợp lệ.", 400);
    const p = await prisma.payment.findUnique({ where: { transaction_ref: String(req.body.orderId) } });
    if (!p || p.provider !== "MOMO_SANDBOX" || req.body.requestId !== p.transaction_ref || req.body.orderInfo !== orderInfo(p)) throw new MomoError("Không tìm thấy giao dịch MoMo tương ứng.", 400);
    await applyResult(p, req.body);
    res.status(204).end();
  } catch (error) {
    if (error instanceof MomoError) { res.status(error.status).json({ success: false, message: error.message }); return; }
    next(error);
  }
});

// Redirect only returns to the app; query parameters never mark a payment paid.
momoRouter.get("/return", (_req, res) => {
  res.type("html").send('<!doctype html><html lang="vi"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MoMo Sandbox</title><body><h2>Trở về Sân &amp; Cầu</h2><p>Mở ứng dụng và kiểm tra kết quả thanh toán.</p><a href="sanvacau://momo-return">Mở ứng dụng</a></body></html>');
});

momoRouter.post("/:id/check", requireAuth, async (req, res, next) => {
  try {
    const paymentId = id(req.params.id);
    if (!paymentId) throw new MomoError("Mã thanh toán không hợp lệ.", 400);
    const p = await prisma.payment.findUnique({ where: { id: paymentId } });
    if (!p || p.user_id !== BigInt(req.user!.id) || p.provider !== "MOMO_SANDBOX") throw new MomoError("Không tìm thấy giao dịch của bạn.", 404);
    if (p.status !== "PENDING") { res.json({ success: true, data: serialize(p) }); return; }
    const config = momoConfig();
    const requestId = randomUUID();
    const fields = { accessKey: config.accessKey, orderId: p.transaction_ref!, partnerCode: config.partnerCode, requestId };
    const result = await momoRequest("query", { partnerCode: config.partnerCode, orderId: p.transaction_ref, requestId,
      lang: "vi", signature: momoSignature(fields, config.secretKey) });
    if (result.requestId !== requestId) throw new MomoError("Phản hồi truy vấn MoMo không khớp.");
    res.json({ success: true, data: serialize(await applyResult(p, result)) });
  } catch (error) {
    if (error instanceof MomoError) { res.status(error.status).json({ success: false, message: error.message }); return; }
    next(error);
  }
});
