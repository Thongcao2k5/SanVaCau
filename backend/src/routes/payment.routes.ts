import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";
import { createNotification } from "../lib/notification.js";

export const paymentRouter = Router();

// ── helpers ────────────────────────────────────────────────

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const VALID_TARGET_TYPES = ["ORDER", "BOOKING"] as const;
type TargetType = (typeof VALID_TARGET_TYPES)[number];

const VALID_PROVIDERS = ["CASH", "MOCK"] as const;
type Provider = (typeof VALID_PROVIDERS)[number];

const VALID_STATUSES = ["PENDING", "PAID", "FAILED"] as const;

type PaymentRow = Prisma.paymentGetPayload<{}>;

const toPaymentResponse = (p: PaymentRow) => ({
  id: p.id.toString(),
  userId: p.user_id.toString(),
  targetType: p.target_type,
  targetId: p.target_id.toString(),
  provider: p.provider,
  amount: p.amount.toString(),
  status: p.status,
  transactionRef: p.transaction_ref,
  paidAt: p.paid_at?.toISOString() ?? null,
  failedAt: p.failed_at?.toISOString() ?? null,
  createdAt: p.created_at.toISOString(),
  updatedAt: p.updated_at.toISOString(),
});

const padTwo = (n: number) => n.toString().padStart(2, "0");

const buildTransactionRef = (provider: string, targetType: string, targetId: bigint) => {
  const now = new Date();
  const ts =
    `${now.getFullYear()}${padTwo(now.getMonth() + 1)}${padTwo(now.getDate())}` +
    `${padTwo(now.getHours())}${padTwo(now.getMinutes())}${padTwo(now.getSeconds())}`;
  return `${provider}_${targetType}_${targetId}_${ts}`;
};

// ── A. POST /api/payments/mock ─────────────────────────────

paymentRouter.post("/mock", requireAuth, async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);

    // --- validate targetType ---
    const targetType = (typeof req.body.targetType === "string" ? req.body.targetType.trim().toUpperCase() : "") as string;
    if (!VALID_TARGET_TYPES.includes(targetType as TargetType)) {
      res.status(400).json({
        success: false,
        message: "targetType must be ORDER or BOOKING",
      });
      return;
    }

    // --- validate targetId ---
    const targetId = parseBigIntId(req.body.targetId?.toString());
    if (!targetId) {
      res.status(400).json({
        success: false,
        message: "targetId must be a valid positive integer",
      });
      return;
    }

    // --- validate provider ---
    const rawProvider = typeof req.body.provider === "string" ? req.body.provider.trim().toUpperCase() : "MOCK";
    if (!VALID_PROVIDERS.includes(rawProvider as Provider)) {
      res.status(400).json({
        success: false,
        message: `provider must be one of: ${VALID_PROVIDERS.join(", ")}`,
      });
      return;
    }
    const provider = rawProvider as Provider;

    // --- resolve target and determine amount ---
    let amount: Prisma.Decimal;

    if (targetType === "ORDER") {
      const order = await prisma.customer_order.findUnique({ where: { id: targetId } });
      if (!order) {
        res.status(404).json({ success: false, message: "Order not found" });
        return;
      }
      if (order.customer_id !== userId) {
        res.status(403).json({ success: false, message: "You can only create payment for your own order" });
        return;
      }
      if (order.status === "CANCELLED") {
        res.status(400).json({ success: false, message: "Cannot create payment for a cancelled order" });
        return;
      }
      amount = order.total_amount;
    } else {
      // BOOKING
      const booking = await prisma.booking.findUnique({ where: { id: targetId } });
      if (!booking) {
        res.status(404).json({ success: false, message: "Booking not found" });
        return;
      }
      if (booking.customer_id !== userId) {
        res.status(403).json({ success: false, message: "You can only create payment for your own booking" });
        return;
      }
      if (booking.status === "CANCELLED") {
        res.status(400).json({ success: false, message: "Cannot create payment for a cancelled booking" });
        return;
      }
      amount = booking.total_amount;
    }

    // --- check existing payments for this target ---
    const existing = await prisma.payment.findFirst({
      where: {
        target_type: targetType,
        target_id: targetId,
        status: { in: ["PENDING", "PAID"] },
      },
      orderBy: { created_at: "desc" },
    });

    if (existing) {
      if (existing.status === "PAID") {
        res.status(409).json({
          success: false,
          message: "Target already paid",
          data: toPaymentResponse(existing),
        });
        return;
      }

      // PENDING — return existing, don't duplicate
      res.status(200).json({
        success: true,
        message: "Returning existing pending payment",
        data: toPaymentResponse(existing),
      });
      return;
    }

    // --- create payment ---
    const transactionRef = buildTransactionRef(provider, targetType, targetId);

    const payment = await prisma.payment.create({
      data: {
        user_id: userId,
        target_type: targetType,
        target_id: targetId,
        provider,
        amount,
        status: "PENDING",
        transaction_ref: transactionRef,
      },
    });

    res.status(201).json({
      success: true,
      data: toPaymentResponse(payment),
    });
  } catch (error) {
    next(error);
  }
});

// ── B. PATCH /api/payments/:id/mock-success ─────────────────

paymentRouter.patch("/:id/mock-success", requireAuth, async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);
    const paymentId = parseBigIntId(req.params.id);

    if (!paymentId) {
      res.status(400).json({ success: false, message: "Invalid payment id" });
      return;
    }

    const payment = await prisma.payment.findUnique({ where: { id: paymentId } });

    if (!payment) {
      res.status(404).json({ success: false, message: "Payment not found" });
      return;
    }

    if (payment.user_id !== userId) {
      res.status(403).json({ success: false, message: "You can only update your own payment" });
      return;
    }

    if (payment.status !== "PENDING") {
      res.status(400).json({ success: false, message: `Payment is already ${payment.status}` });
      return;
    }

    const now = new Date();

    const updated = await prisma.$transaction(async (tx) => {
      const paidPayment = await tx.payment.update({
        where: { id: paymentId },
        data: {
          status: "PAID",
          paid_at: now,
          updated_at: now,
        },
      });

      if (payment.target_type === "BOOKING") {
        await tx.booking.update({
          where: { id: payment.target_id },
          data: { payment_status: "PAID" },
        });
      }

      return paidPayment;
    });

    // --- notification (fire-and-forget) ---
    createNotification({
      userId: user.id,
      type: "PAYMENT_SUCCESS",
      title: "Thanh toán thành công",
      message: `Thanh toán ${payment.transaction_ref ?? ""} đã hoàn tất.`,
      data: { paymentId: updated.id.toString(), targetType: payment.target_type, targetId: payment.target_id.toString() },
    });

    // --- audit log (fire-and-forget) ---
    createAuditLog({
      actorId: user.id,
      actorRole: user.role,
      action: "PAYMENT_MOCK_SUCCESS",
      entityType: "payment",
      entityId: updated.id,
      beforeData: { status: "PENDING" },
      afterData: { status: "PAID" },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    res.json({
      success: true,
      data: toPaymentResponse(updated),
    });
  } catch (error) {
    next(error);
  }
});

// ── C. PATCH /api/payments/:id/mock-fail ────────────────────

paymentRouter.patch("/:id/mock-fail", requireAuth, async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);
    const paymentId = parseBigIntId(req.params.id);

    if (!paymentId) {
      res.status(400).json({ success: false, message: "Invalid payment id" });
      return;
    }

    const payment = await prisma.payment.findUnique({ where: { id: paymentId } });

    if (!payment) {
      res.status(404).json({ success: false, message: "Payment not found" });
      return;
    }

    if (payment.user_id !== userId) {
      res.status(403).json({ success: false, message: "You can only update your own payment" });
      return;
    }

    if (payment.status !== "PENDING") {
      res.status(400).json({ success: false, message: `Payment is already ${payment.status}` });
      return;
    }

    const now = new Date();

    const updated = await prisma.payment.update({
      where: { id: paymentId },
      data: {
        status: "FAILED",
        failed_at: now,
        updated_at: now,
      },
    });

    // --- notification (fire-and-forget) ---
    createNotification({
      userId: user.id,
      type: "PAYMENT_FAILED",
      title: "Thanh toán thất bại",
      message: `Thanh toán ${payment.transaction_ref ?? ""} đã thất bại.`,
      data: { paymentId: updated.id.toString(), targetType: payment.target_type, targetId: payment.target_id.toString() },
    });

    // --- audit log (fire-and-forget) ---
    createAuditLog({
      actorId: user.id,
      actorRole: user.role,
      action: "PAYMENT_MOCK_FAIL",
      entityType: "payment",
      entityId: updated.id,
      beforeData: { status: "PENDING" },
      afterData: { status: "FAILED" },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    res.json({
      success: true,
      data: toPaymentResponse(updated),
    });
  } catch (error) {
    next(error);
  }
});

// ── D. GET /api/payments/me ──────────────────────────────────

paymentRouter.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);

    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit as string) || 20));
    const skip = (page - 1) * limit;

    const where: Prisma.paymentWhereInput = { user_id: userId };

    // optional status filter
    const statusFilter = typeof req.query.status === "string" ? req.query.status.trim().toUpperCase() : undefined;
    if (statusFilter && VALID_STATUSES.includes(statusFilter as (typeof VALID_STATUSES)[number])) {
      where.status = statusFilter;
    }

    // optional targetType filter
    const targetTypeFilter = typeof req.query.targetType === "string" ? req.query.targetType.trim().toUpperCase() : undefined;
    if (targetTypeFilter && VALID_TARGET_TYPES.includes(targetTypeFilter as TargetType)) {
      where.target_type = targetTypeFilter;
    }

    const [items, total] = await Promise.all([
      prisma.payment.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
      prisma.payment.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        items: items.map(toPaymentResponse),
        pagination: {
          page,
          limit,
          total: Number(total),
          totalPages: Math.ceil(Number(total) / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── E. GET /api/payments (ADMIN only) ────────────────────────

paymentRouter.get("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit as string) || 20));
    const skip = (page - 1) * limit;

    const where: Prisma.paymentWhereInput = {};

    // optional userId filter
    const userIdFilter = parseBigIntId(req.query.userId as string);
    if (userIdFilter) {
      where.user_id = userIdFilter;
    }

    // optional status filter
    const statusFilter = typeof req.query.status === "string" ? req.query.status.trim().toUpperCase() : undefined;
    if (statusFilter && VALID_STATUSES.includes(statusFilter as (typeof VALID_STATUSES)[number])) {
      where.status = statusFilter;
    }

    // optional targetType filter
    const targetTypeFilter = typeof req.query.targetType === "string" ? req.query.targetType.trim().toUpperCase() : undefined;
    if (targetTypeFilter && VALID_TARGET_TYPES.includes(targetTypeFilter as TargetType)) {
      where.target_type = targetTypeFilter;
    }

    const [items, total] = await Promise.all([
      prisma.payment.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
      prisma.payment.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        items: items.map(toPaymentResponse),
        pagination: {
          page,
          limit,
          total: Number(total),
          totalPages: Math.ceil(Number(total) / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});
