import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma, voucher } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";

export const voucherRouter = Router();

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const toVoucherResponse = (v: voucher) => ({
  id: v.id.toString(),
  code: v.code,
  title: v.title,
  description: v.description,
  discountType: v.discount_type,
  discountValue: v.discount_value.toString(),
  maxDiscountAmount: v.max_discount_amount?.toString() ?? null,
  minOrderAmount: v.min_order_amount?.toString() ?? null,
  targetType: v.target_type,
  usageLimit: v.usage_limit,
  usedCount: v.used_count,
  perUserLimit: v.per_user_limit,
  startAt: v.start_at?.toISOString() ?? null,
  endAt: v.end_at?.toISOString() ?? null,
  status: v.status,
  createdAt: v.created_at.toISOString(),
  updatedAt: v.updated_at.toISOString(),
});

const toVoucherAuditData = (v: voucher) => toVoucherResponse(v);

const toUsageAuditData = (usage: {
  id: bigint;
  voucher_id: bigint;
  user_id: bigint;
  target_type: string;
  target_id: bigint;
  discount_amount: Prisma.Decimal;
  created_at: Date;
}) => ({
  id: usage.id.toString(),
  voucherId: usage.voucher_id.toString(),
  userId: usage.user_id.toString(),
  targetType: usage.target_type,
  targetId: usage.target_id.toString(),
  discountAmount: usage.discount_amount.toString(),
  createdAt: usage.created_at.toISOString(),
});

const isPrismaKnownRequestError = (error: unknown): error is Prisma.PrismaClientKnownRequestError => {
  return error instanceof Prisma.PrismaClientKnownRequestError;
};

const parseDecimalInput = (value: unknown) => {
  try {
    if (value === undefined || value === null || value === "") {
      return null;
    }

    return new Prisma.Decimal(value as string | number);
  } catch {
    return null;
  }
};

const validTargetTypes = ["ALL", "ORDER", "BOOKING"] as const;
const validStatuses = ["ACTIVE", "INACTIVE"] as const;

// A. POST /api/vouchers
voucherRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const {
      code,
      title,
      description,
      discountType,
      discountValue,
      maxDiscountAmount,
      minOrderAmount,
      targetType,
      usageLimit,
      perUserLimit,
      startAt,
      endAt,
      status,
    } = req.body;

    if (!code || typeof code !== "string" || code.trim().length === 0 || code.trim().length > 50) {
      res.status(400).json({ success: false, message: "Valid code is required (max 50)" });
      return;
    }
    const finalCode = code.trim().toUpperCase();

    if (!title || typeof title !== "string" || title.trim().length === 0 || title.trim().length > 200) {
      res.status(400).json({ success: false, message: "Valid title is required (max 200)" });
      return;
    }

    if (discountType !== "PERCENT" && discountType !== "FIXED") {
      res.status(400).json({ success: false, message: "discountType must be PERCENT or FIXED" });
      return;
    }

    const dv = parseDecimalInput(discountValue);
    if (!dv) {
      res.status(400).json({ success: false, message: "discountValue must be a valid decimal" });
      return;
    }
    if (discountType === "PERCENT" && (dv.lte(0) || dv.gt(100))) {
      res.status(400).json({ success: false, message: "PERCENT discountValue must be > 0 and <= 100" });
      return;
    }
    if (discountType === "FIXED" && dv.lte(0)) {
      res.status(400).json({ success: false, message: "FIXED discountValue must be > 0" });
      return;
    }

    const finalMaxDiscountAmount = parseDecimalInput(maxDiscountAmount);
    if (maxDiscountAmount !== undefined && maxDiscountAmount !== null && maxDiscountAmount !== "" && !finalMaxDiscountAmount) {
      res.status(400).json({ success: false, message: "maxDiscountAmount must be a valid decimal" });
      return;
    }
    if (finalMaxDiscountAmount && finalMaxDiscountAmount.lt(0)) {
      res.status(400).json({ success: false, message: "maxDiscountAmount must be >= 0" });
      return;
    }

    const finalMinOrderAmount = parseDecimalInput(minOrderAmount);
    if (minOrderAmount !== undefined && minOrderAmount !== null && minOrderAmount !== "" && !finalMinOrderAmount) {
      res.status(400).json({ success: false, message: "minOrderAmount must be a valid decimal" });
      return;
    }
    if (finalMinOrderAmount && finalMinOrderAmount.lt(0)) {
      res.status(400).json({ success: false, message: "minOrderAmount must be >= 0" });
      return;
    }

    const finalTargetType = targetType ?? "ALL";
    if (!validTargetTypes.includes(finalTargetType)) {
      res.status(400).json({ success: false, message: "targetType must be ALL, ORDER, or BOOKING" });
      return;
    }

    const finalUsageLimit = usageLimit !== undefined ? parseInt(usageLimit, 10) : null;
    if (finalUsageLimit !== null && (isNaN(finalUsageLimit) || finalUsageLimit <= 0)) {
      res.status(400).json({ success: false, message: "usageLimit must be a positive integer" });
      return;
    }

    const finalPerUserLimit = perUserLimit !== undefined ? parseInt(perUserLimit, 10) : null;
    if (finalPerUserLimit !== null && (isNaN(finalPerUserLimit) || finalPerUserLimit <= 0)) {
      res.status(400).json({ success: false, message: "perUserLimit must be a positive integer" });
      return;
    }

    const finalStartAt = startAt ? new Date(startAt) : null;
    const finalEndAt = endAt ? new Date(endAt) : null;

    if (finalStartAt && isNaN(finalStartAt.getTime())) return res.status(400).json({ success: false, message: "Invalid startAt date" });
    if (finalEndAt && isNaN(finalEndAt.getTime())) return res.status(400).json({ success: false, message: "Invalid endAt date" });
    if (finalStartAt && finalEndAt && finalEndAt <= finalStartAt) {
      res.status(400).json({ success: false, message: "endAt must be after startAt" });
      return;
    }

    const finalStatus = status ?? "ACTIVE";
    if (!validStatuses.includes(finalStatus)) {
      res.status(400).json({ success: false, message: "status must be ACTIVE or INACTIVE" });
      return;
    }

    // check duplicate code
    const existing = await prisma.voucher.findUnique({ where: { code: finalCode } });
    if (existing) {
      res.status(400).json({ success: false, message: "Voucher code already exists" });
      return;
    }

    const newVoucher = await prisma.voucher.create({
      data: {
        code: finalCode,
        title: title.trim(),
        description: typeof description === "string" ? description.trim() : null,
        discount_type: discountType,
        discount_value: dv,
        max_discount_amount: finalMaxDiscountAmount,
        min_order_amount: finalMinOrderAmount,
        target_type: finalTargetType,
        usage_limit: finalUsageLimit,
        per_user_limit: finalPerUserLimit,
        start_at: finalStartAt,
        end_at: finalEndAt,
        status: finalStatus,
      },
    });

    res.status(201).json({
      success: true,
      message: "Voucher created successfully",
      data: { voucher: toVoucherResponse(newVoucher) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "VOUCHER_CREATED",
      entityType: "voucher",
      entityId: newVoucher.id,
      afterData: toVoucherAuditData(newVoucher),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});

// B. GET /api/vouchers
voucherRouter.get("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string || "1", 10));
    const limit = Math.max(1, Math.min(100, parseInt(req.query.limit as string || "20", 10)));
    const skip = (page - 1) * limit;

    const status = req.query.status as string;
    const targetType = req.query.targetType as string;
    const q = req.query.q as string;

    const where: Prisma.voucherWhereInput = {
      ...(status ? { status } : {}),
      ...(targetType ? { target_type: targetType } : {}),
      ...(q ? {
        OR: [
          { code: { contains: q, mode: "insensitive" } },
          { title: { contains: q, mode: "insensitive" } },
        ],
      } : {}),
    };

    const [total, vouchers] = await Promise.all([
      prisma.voucher.count({ where }),
      prisma.voucher.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
    ]);

    res.json({
      success: true,
      data: {
        vouchers: vouchers.map(toVoucherResponse),
        pagination: {
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

// C. PATCH /api/vouchers/:id
voucherRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) return res.status(400).json({ success: false, message: "Invalid voucher id" });

    const existingVoucher = await prisma.voucher.findUnique({ where: { id } });
    if (!existingVoucher) return res.status(404).json({ success: false, message: "Voucher not found" });

    const {
      title,
      description,
      discountType,
      discountValue,
      maxDiscountAmount,
      minOrderAmount,
      targetType,
      usageLimit,
      perUserLimit,
      startAt,
      endAt,
      status,
    } = req.body;

    const dataToUpdate: Prisma.voucherUpdateInput = { updated_at: new Date() };

    if (title !== undefined) {
      if (typeof title !== "string" || title.trim().length === 0 || title.trim().length > 200) {
        return res.status(400).json({ success: false, message: "Valid title is required (max 200)" });
      }
      dataToUpdate.title = title.trim();
    }
    if (description !== undefined) {
      dataToUpdate.description = typeof description === "string" ? description.trim() : null;
    }

    if (discountType !== undefined || discountValue !== undefined) {
      const dt = discountType !== undefined ? discountType : existingVoucher.discount_type;
      const parsedDiscountValue = discountValue !== undefined ? parseDecimalInput(discountValue) : existingVoucher.discount_value;
      if (!parsedDiscountValue) {
        return res.status(400).json({ success: false, message: "discountValue must be a valid decimal" });
      }
      const dv = parsedDiscountValue;

      if (dt !== "PERCENT" && dt !== "FIXED") {
        return res.status(400).json({ success: false, message: "discountType must be PERCENT or FIXED" });
      }
      if (dt === "PERCENT" && (dv.lte(0) || dv.gt(100))) {
        return res.status(400).json({ success: false, message: "PERCENT discountValue must be > 0 and <= 100" });
      }
      if (dt === "FIXED" && dv.lte(0)) {
        return res.status(400).json({ success: false, message: "FIXED discountValue must be > 0" });
      }
      
      dataToUpdate.discount_type = dt;
      dataToUpdate.discount_value = dv;
    }

    if (maxDiscountAmount !== undefined) {
      const maxD = parseDecimalInput(maxDiscountAmount);
      if (maxDiscountAmount !== null && maxDiscountAmount !== "" && !maxD) {
        return res.status(400).json({ success: false, message: "maxDiscountAmount must be a valid decimal" });
      }
      if (maxD && maxD.lt(0)) return res.status(400).json({ success: false, message: "maxDiscountAmount must be >= 0" });
      dataToUpdate.max_discount_amount = maxD;
    }

    if (minOrderAmount !== undefined) {
      const minO = parseDecimalInput(minOrderAmount);
      if (minOrderAmount !== null && minOrderAmount !== "" && !minO) {
        return res.status(400).json({ success: false, message: "minOrderAmount must be a valid decimal" });
      }
      if (minO && minO.lt(0)) return res.status(400).json({ success: false, message: "minOrderAmount must be >= 0" });
      dataToUpdate.min_order_amount = minO;
    }

    if (targetType !== undefined) {
      if (!validTargetTypes.includes(targetType)) {
        return res.status(400).json({ success: false, message: "targetType must be ALL, ORDER, or BOOKING" });
      }
      dataToUpdate.target_type = targetType;
    }

    if (usageLimit !== undefined) {
      const finalUsageLimit = usageLimit !== null ? parseInt(usageLimit, 10) : null;
      if (finalUsageLimit !== null && (isNaN(finalUsageLimit) || finalUsageLimit <= 0)) {
        return res.status(400).json({ success: false, message: "usageLimit must be a positive integer or null" });
      }
      dataToUpdate.usage_limit = finalUsageLimit;
    }

    if (perUserLimit !== undefined) {
      const finalPerUserLimit = perUserLimit !== null ? parseInt(perUserLimit, 10) : null;
      if (finalPerUserLimit !== null && (isNaN(finalPerUserLimit) || finalPerUserLimit <= 0)) {
        return res.status(400).json({ success: false, message: "perUserLimit must be a positive integer or null" });
      }
      dataToUpdate.per_user_limit = finalPerUserLimit;
    }

    if (startAt !== undefined || endAt !== undefined) {
      const finalStartAt = startAt !== undefined ? (startAt ? new Date(startAt) : null) : existingVoucher.start_at;
      const finalEndAt = endAt !== undefined ? (endAt ? new Date(endAt) : null) : existingVoucher.end_at;
      
      if (finalStartAt && isNaN(finalStartAt.getTime())) return res.status(400).json({ success: false, message: "Invalid startAt date" });
      if (finalEndAt && isNaN(finalEndAt.getTime())) return res.status(400).json({ success: false, message: "Invalid endAt date" });
      if (finalStartAt && finalEndAt && finalEndAt <= finalStartAt) {
        return res.status(400).json({ success: false, message: "endAt must be after startAt" });
      }
      
      dataToUpdate.start_at = finalStartAt;
      dataToUpdate.end_at = finalEndAt;
    }

    if (status !== undefined) {
      if (!validStatuses.includes(status)) {
        return res.status(400).json({ success: false, message: "status must be ACTIVE or INACTIVE" });
      }
      dataToUpdate.status = status;
    }

    const updatedVoucher = await prisma.voucher.update({
      where: { id },
      data: dataToUpdate,
    });

    res.json({
      success: true,
      message: "Voucher updated successfully",
      data: { voucher: toVoucherResponse(updatedVoucher) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "VOUCHER_UPDATED",
      entityType: "voucher",
      entityId: updatedVoucher.id,
      beforeData: toVoucherAuditData(existingVoucher),
      afterData: toVoucherAuditData(updatedVoucher),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});

// D. PATCH /api/vouchers/:id/inactive
voucherRouter.patch("/:id/inactive", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) return res.status(400).json({ success: false, message: "Invalid voucher id" });

    const existingVoucher = await prisma.voucher.findUnique({ where: { id } });
    if (!existingVoucher) return res.status(404).json({ success: false, message: "Voucher not found" });

    if (existingVoucher.status === "INACTIVE") {
      res.json({ success: true, message: "Voucher is already inactive" });
      return;
    }

    const updatedVoucher = await prisma.voucher.update({
      where: { id },
      data: { status: "INACTIVE", updated_at: new Date() },
    });

    res.json({
      success: true,
      message: "Voucher marked as INACTIVE",
      data: { voucher: toVoucherResponse(updatedVoucher) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "VOUCHER_INACTIVATED",
      entityType: "voucher",
      entityId: updatedVoucher.id,
      beforeData: toVoucherAuditData(existingVoucher),
      afterData: toVoucherAuditData(updatedVoucher),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});

const calculateDiscount = (voucher: voucher, amount: Prisma.Decimal) => {
  let discountAmount = new Prisma.Decimal(0);

  if (voucher.discount_type === "PERCENT") {
    discountAmount = amount.mul(voucher.discount_value).div(100);
  } else {
    discountAmount = voucher.discount_value;
  }

  if (voucher.max_discount_amount && discountAmount.gt(voucher.max_discount_amount)) {
    discountAmount = voucher.max_discount_amount;
  }

  if (discountAmount.gt(amount)) {
    discountAmount = amount;
  }

  return {
    discountAmount,
    finalAmount: amount.sub(discountAmount),
  };
};

// E. POST /api/vouchers/validate
voucherRouter.post("/validate", requireAuth, async (req, res, next) => {
  try {
    const userId = BigInt(req.user!.id);
    const { code, targetType, targetId, amount } = req.body;

    if (!code || typeof code !== "string") return res.status(400).json({ success: false, message: "Voucher code required" });
    if (targetType !== "ORDER" && targetType !== "BOOKING") return res.status(400).json({ success: false, message: "targetType must be ORDER or BOOKING" });
    if (!amount) return res.status(400).json({ success: false, message: "amount required" });
    
    const decAmount = parseDecimalInput(amount);
    if (!decAmount) return res.status(400).json({ success: false, message: "amount must be a valid decimal" });
    if (decAmount.lte(0)) return res.status(400).json({ success: false, message: "amount must be positive" });

    const v = await prisma.voucher.findUnique({ where: { code: code.trim().toUpperCase() } });
    if (!v) return res.status(400).json({ success: false, message: "Voucher not found" });

    if (v.status !== "ACTIVE") return res.status(400).json({ success: false, message: "Voucher is inactive" });

    const now = new Date();
    if (v.start_at && now < v.start_at) return res.status(400).json({ success: false, message: "Voucher is not yet active" });
    if (v.end_at && now > v.end_at) return res.status(400).json({ success: false, message: "Voucher is expired" });

    if (v.target_type !== "ALL" && v.target_type !== targetType) return res.status(400).json({ success: false, message: `Voucher is only valid for ${v.target_type}` });

    if (v.min_order_amount && decAmount.lt(v.min_order_amount)) {
      return res.status(400).json({ success: false, message: `Minimum amount required is ${v.min_order_amount.toString()}` });
    }

    const tId = targetId === undefined || targetId === null || targetId === "" ? null : parseBigIntId(targetId?.toString());
    if (targetId !== undefined && targetId !== null && targetId !== "" && !tId) {
      return res.status(400).json({ success: false, message: "targetId must be a valid positive integer" });
    }

    if (tId) {
      if (targetType === "ORDER") {
        const order = await prisma.customer_order.findUnique({ where: { id: tId } });
        if (!order || order.customer_id !== userId) return res.status(400).json({ success: false, message: "Order not found or access denied" });
      } else if (targetType === "BOOKING") {
        const booking = await prisma.booking.findUnique({ where: { id: tId } });
        if (!booking || booking.customer_id !== userId) return res.status(400).json({ success: false, message: "Booking not found or access denied" });
      }
    }

    if (v.usage_limit !== null && v.used_count >= v.usage_limit) {
      return res.status(400).json({ success: false, message: "Voucher usage limit reached" });
    }

    if (v.per_user_limit !== null) {
      const userUsageCount = await prisma.voucher_usage.count({
        where: { voucher_id: v.id, user_id: userId },
      });
      if (userUsageCount >= v.per_user_limit) {
        return res.status(400).json({ success: false, message: "You have reached the usage limit for this voucher" });
      }
    }

    const { discountAmount, finalAmount } = calculateDiscount(v, decAmount);

    res.json({
      success: true,
      data: {
        voucher: toVoucherResponse(v),
        amount: decAmount.toString(),
        discountAmount: discountAmount.toString(),
        finalAmount: finalAmount.toString(),
      },
    });
  } catch (error) {
    next(error);
  }
});

// F. POST /api/vouchers/apply
voucherRouter.post("/apply", requireAuth, async (req, res, next) => {
  try {
    const userId = BigInt(req.user!.id);
    const { code, targetType, targetId, amount } = req.body;

    if (!code || typeof code !== "string") return res.status(400).json({ success: false, message: "Voucher code required" });
    if (targetType !== "ORDER" && targetType !== "BOOKING") return res.status(400).json({ success: false, message: "targetType must be ORDER or BOOKING" });
    if (!amount) return res.status(400).json({ success: false, message: "amount required" });
    
    const tId = parseBigIntId(targetId);
    if (!tId) return res.status(400).json({ success: false, message: "targetId required for apply" });

    const decAmount = parseDecimalInput(amount);
    if (!decAmount) return res.status(400).json({ success: false, message: "amount must be a valid decimal" });
    if (decAmount.lte(0)) return res.status(400).json({ success: false, message: "amount must be positive" });

    const v = await prisma.voucher.findUnique({ where: { code: code.trim().toUpperCase() } });
    if (!v) return res.status(400).json({ success: false, message: "Voucher not found" });

    if (v.status !== "ACTIVE") return res.status(400).json({ success: false, message: "Voucher is inactive" });

    const now = new Date();
    if (v.start_at && now < v.start_at) return res.status(400).json({ success: false, message: "Voucher is not yet active" });
    if (v.end_at && now > v.end_at) return res.status(400).json({ success: false, message: "Voucher is expired" });

    if (v.target_type !== "ALL" && v.target_type !== targetType) return res.status(400).json({ success: false, message: `Voucher is only valid for ${v.target_type}` });

    if (v.min_order_amount && decAmount.lt(v.min_order_amount)) {
      return res.status(400).json({ success: false, message: `Minimum amount required is ${v.min_order_amount.toString()}` });
    }

    if (targetType === "ORDER") {
      const order = await prisma.customer_order.findUnique({ where: { id: tId } });
      if (!order || order.customer_id !== userId) return res.status(400).json({ success: false, message: "Order not found or access denied" });
    } else if (targetType === "BOOKING") {
      const booking = await prisma.booking.findUnique({ where: { id: tId } });
      if (!booking || booking.customer_id !== userId) return res.status(400).json({ success: false, message: "Booking not found or access denied" });
    }

    const { discountAmount, finalAmount } = calculateDiscount(v, decAmount);

    try {
      const { usage, updatedVoucher } = await prisma.$transaction(async (tx) => {
        // Re-check limits in tx for concurrency
        const currentVoucher = await tx.voucher.findUniqueOrThrow({ where: { id: v.id } });

        const existingTargetUsage = await tx.voucher_usage.findUnique({
          where: {
            voucher_id_target_type_target_id: {
              voucher_id: currentVoucher.id,
              target_type: targetType,
              target_id: tId,
            },
          },
        });

        if (existingTargetUsage) {
          throw new Error("DUPLICATE_TARGET");
        }
        
        if (currentVoucher.usage_limit !== null && currentVoucher.used_count >= currentVoucher.usage_limit) {
          throw new Error("LIMIT_REACHED");
        }

        if (currentVoucher.per_user_limit !== null) {
          const userUsageCount = await tx.voucher_usage.count({
            where: { voucher_id: currentVoucher.id, user_id: userId },
          });
          if (userUsageCount >= currentVoucher.per_user_limit) {
            throw new Error("USER_LIMIT_REACHED");
          }
        }

        const createdUsage = await tx.voucher_usage.create({
          data: {
            voucher_id: currentVoucher.id,
            user_id: userId,
            target_type: targetType,
            target_id: tId,
            discount_amount: discountAmount,
          },
        });

        const nextVoucher = await tx.voucher.update({
          where: { id: currentVoucher.id },
          data: { used_count: { increment: 1 }, updated_at: new Date() },
        });

        return { usage: createdUsage, updatedVoucher: nextVoucher };
      });

      res.status(201).json({
        success: true,
        message: "Voucher applied successfully",
        data: {
          usageId: usage.id.toString(),
          voucher: toVoucherResponse(updatedVoucher),
          amount: decAmount.toString(),
          discountAmount: discountAmount.toString(),
          finalAmount: finalAmount.toString(),
        },
      });

      createAuditLog({
        actorId: req.user!.id,
        actorRole: req.user!.role,
        action: "VOUCHER_APPLIED",
        entityType: "voucher_usage",
        entityId: usage.id,
        afterData: toUsageAuditData(usage),
        ipAddress: req.ip ?? null,
        userAgent: req.headers["user-agent"] ?? null,
      });

    } catch (e: unknown) {
      if ((isPrismaKnownRequestError(e) && e.code === "P2002") || (e instanceof Error && e.message === "DUPLICATE_TARGET")) {
        res.status(409).json({ success: false, message: "Voucher already applied to this target" });
        return;
      }
      if (e instanceof Error && e.message === "LIMIT_REACHED") {
        res.status(400).json({ success: false, message: "Voucher usage limit reached" });
        return;
      }
      if (e instanceof Error && e.message === "USER_LIMIT_REACHED") {
        res.status(400).json({ success: false, message: "You have reached the usage limit for this voucher" });
        return;
      }
      throw e;
    }
  } catch (error) {
    next(error);
  }
});
