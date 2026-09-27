import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma, order_fulfillment } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";
import { createNotification } from "../lib/notification.js";

export const fulfillmentRouter = Router();

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const toFulfillmentResponse = (f: order_fulfillment) => ({
  id: f.id.toString(),
  orderId: f.order_id.toString(),
  fulfillmentType: f.fulfillment_type,
  status: f.status,
  recipientName: f.recipient_name,
  phone: f.phone,
  addressLine: f.address_line,
  ward: f.ward,
  district: f.district,
  city: f.city,
  note: f.note,
  shippingFee: f.shipping_fee.toString(),
  trackingCode: f.tracking_code,
  shippedAt: f.shipped_at?.toISOString() ?? null,
  deliveredAt: f.delivered_at?.toISOString() ?? null,
  pickedUpAt: f.picked_up_at?.toISOString() ?? null,
  cancelledAt: f.cancelled_at?.toISOString() ?? null,
  createdAt: f.created_at.toISOString(),
  updatedAt: f.updated_at.toISOString(),
});

const toFulfillmentAuditData = (f: order_fulfillment) => toFulfillmentResponse(f);

// A. POST /api/fulfillments/orders/:orderId
fulfillmentRouter.post("/orders/:orderId", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const orderId = parseBigIntId(req.params.orderId);

    if (!orderId) {
      res.status(400).json({ success: false, message: "Invalid order id" });
      return;
    }

    const { fulfillmentType, addressId, recipientName, phone, addressLine, ward, district, city, note } = req.body;

    if (fulfillmentType !== "PICKUP" && fulfillmentType !== "DELIVERY") {
      res.status(400).json({ success: false, message: "fulfillmentType must be PICKUP or DELIVERY" });
      return;
    }

    const order = await prisma.customer_order.findUnique({
      where: { id: orderId },
      include: { order_fulfillment: true },
    });

    if (!order || order.customer_id !== customerId) {
      res.status(404).json({ success: false, message: "Order not found" });
      return;
    }

    if (order.status === "CANCELLED" || order.status === "COMPLETED") {
      res.status(400).json({ success: false, message: "Order cannot have fulfillment created at this status" });
      return;
    }

    if (order.order_fulfillment) {
      res.status(409).json({ success: false, message: "Fulfillment already exists for this order" });
      return;
    }

    const data: Prisma.order_fulfillmentCreateInput = {
      fulfillment_type: fulfillmentType,
      status: "PENDING",
      shipping_fee: new Prisma.Decimal(0),
      note: typeof note === "string" ? note.trim() : null,
      customer_order: { connect: { id: orderId } },
    };

    if (fulfillmentType === "DELIVERY") {
      data.shipping_fee = new Prisma.Decimal(30000); // fixed fee

      if (addressId) {
        const aId = parseBigIntId(addressId);
        if (!aId) return res.status(400).json({ success: false, message: "Invalid addressId" });
        const address = await prisma.customer_address.findUnique({ where: { id: aId } });
        if (!address || address.customer_id !== customerId) {
          return res.status(404).json({ success: false, message: "Address not found" });
        }
        data.recipient_name = address.recipient_name;
        data.phone = address.phone;
        data.address_line = address.address_line;
        data.ward = address.ward;
        data.district = address.district;
        data.city = address.city;
      } else {
        if (!recipientName || typeof recipientName !== "string" || recipientName.trim().length === 0) {
          return res.status(400).json({ success: false, message: "recipientName is required" });
        }
        if (!phone || typeof phone !== "string" || phone.trim().length === 0) {
          return res.status(400).json({ success: false, message: "phone is required" });
        }
        if (!addressLine || typeof addressLine !== "string" || addressLine.trim().length === 0) {
          return res.status(400).json({ success: false, message: "addressLine is required" });
        }
        
        data.recipient_name = recipientName.trim();
        data.phone = phone.trim();
        data.address_line = addressLine.trim();
        data.ward = typeof ward === "string" ? ward.trim() : null;
        data.district = typeof district === "string" ? district.trim() : null;
        data.city = typeof city === "string" ? city.trim() : null;
      }
    }

    const fulfillment = await prisma.order_fulfillment.create({ data });

    res.status(201).json({
      success: true,
      message: "Fulfillment created successfully",
      data: { fulfillment: toFulfillmentResponse(fulfillment) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "FULFILLMENT_CREATED",
      entityType: "order_fulfillment",
      entityId: fulfillment.id,
      afterData: toFulfillmentAuditData(fulfillment),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});

// B. GET /api/fulfillments/orders/:orderId
fulfillmentRouter.get("/orders/:orderId", requireAuth, async (req, res, next) => {
  try {
    const orderId = parseBigIntId(req.params.orderId);
    if (!orderId) {
      res.status(400).json({ success: false, message: "Invalid order id" });
      return;
    }

    const fulfillment = await prisma.order_fulfillment.findUnique({
      where: { order_id: orderId },
      include: {
        customer_order: true,
      },
    });

    if (!fulfillment) {
      res.status(404).json({ success: false, message: "Fulfillment not found" });
      return;
    }

    const userRole = req.user!.role;
    const userId = BigInt(req.user!.id);
    
    if (userRole === "CUSTOMER") {
      if (fulfillment.customer_order.customer_id !== userId) {
        res.status(403).json({ success: false, message: "Forbidden: Order belongs to another customer" });
        return;
      }
    } else if (userRole === "BRANCH_MANAGER" || userRole === "STAFF") {
      if (!req.user!.branchId) {
        res.status(403).json({ success: false, message: "Forbidden: No assigned branch" });
        return;
      }
      if (fulfillment.customer_order.branch_id.toString() !== req.user!.branchId) {
        res.status(403).json({ success: false, message: "Forbidden: Order does not belong to your branch" });
        return;
      }
    }

    res.json({
      success: true,
      data: { fulfillment: toFulfillmentResponse(fulfillment) },
    });
  } catch (error) {
    next(error);
  }
});

// C. GET /api/fulfillments/me
fulfillmentRouter.get("/me", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const page = Math.max(1, parseInt(req.query.page as string || "1", 10));
    const limit = Math.max(1, Math.min(100, parseInt(req.query.limit as string || "20", 10)));
    const skip = (page - 1) * limit;

    const status = req.query.status as string;
    const fulfillmentType = req.query.fulfillmentType as string;

    const where: Prisma.order_fulfillmentWhereInput = {
      customer_order: { customer_id: customerId },
      ...(status ? { status } : {}),
      ...(fulfillmentType ? { fulfillment_type: fulfillmentType } : {}),
    };

    const [total, fulfillments] = await Promise.all([
      prisma.order_fulfillment.count({ where }),
      prisma.order_fulfillment.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
        include: {
          customer_order: {
            select: {
              id: true,
              status: true,
              total_amount: true,
              branch: {
                select: { id: true, name: true },
              },
            },
          },
        },
      }),
    ]);

    const formatted = fulfillments.map((f) => {
      return {
        ...toFulfillmentResponse(f),
        order: {
          id: f.customer_order.id.toString(),
          status: f.customer_order.status,
          totalAmount: f.customer_order.total_amount.toString(),
          branch: {
            id: f.customer_order.branch.id.toString(),
            name: f.customer_order.branch.name,
          },
        },
      };
    });

    res.json({
      success: true,
      data: {
        fulfillments: formatted,
        pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
      },
    });
  } catch (error) {
    next(error);
  }
});

// D. GET /api/fulfillments
fulfillmentRouter.get("/", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const isInternalStaff = req.user!.role === "BRANCH_MANAGER" || req.user!.role === "STAFF";
    
    if (isInternalStaff && !req.user!.branchId) {
      res.status(403).json({ success: false, message: "Forbidden: No assigned branch" });
      return;
    }

    const assignedBranchId = isInternalStaff ? BigInt(req.user!.branchId!) : null;
    const branchIdQuery = parseBigIntId(req.query.branchId as string);
    const orderIdQuery = parseBigIntId(req.query.orderId as string);

    if (req.query.branchId !== undefined && !branchIdQuery) return res.status(400).json({ success: false, message: "Invalid branchId" });
    if (req.query.orderId !== undefined && !orderIdQuery) return res.status(400).json({ success: false, message: "Invalid orderId" });

    const page = Math.max(1, parseInt(req.query.page as string || "1", 10));
    const limit = Math.max(1, Math.min(100, parseInt(req.query.limit as string || "20", 10)));
    const skip = (page - 1) * limit;

    const status = req.query.status as string;
    const fulfillmentType = req.query.fulfillmentType as string;
    const branchId = isInternalStaff ? assignedBranchId : branchIdQuery;

    const where: Prisma.order_fulfillmentWhereInput = {
      ...(status ? { status } : {}),
      ...(fulfillmentType ? { fulfillment_type: fulfillmentType } : {}),
      ...(orderIdQuery ? { order_id: orderIdQuery } : {}),
      customer_order: {
        ...(branchId ? { branch_id: branchId } : {}),
      },
    };

    const [total, fulfillments] = await Promise.all([
      prisma.order_fulfillment.count({ where }),
      prisma.order_fulfillment.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
    ]);

    res.json({
      success: true,
      data: {
        fulfillments: fulfillments.map(toFulfillmentResponse),
        pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
      },
    });
  } catch (error) {
    next(error);
  }
});

// E. PATCH /api/fulfillments/:id/status
fulfillmentRouter.patch("/:id/status", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) return res.status(400).json({ success: false, message: "Invalid fulfillment id" });

    const { status, trackingCode } = req.body;

    const fulfillment = await prisma.order_fulfillment.findUnique({
      where: { id },
      include: { customer_order: true },
    });

    if (!fulfillment) return res.status(404).json({ success: false, message: "Fulfillment not found" });

    const isInternalStaff = req.user!.role === "BRANCH_MANAGER" || req.user!.role === "STAFF";
    if (isInternalStaff) {
      if (!req.user!.branchId) return res.status(403).json({ success: false, message: "Forbidden: No assigned branch" });
      if (fulfillment.customer_order.branch_id.toString() !== req.user!.branchId) {
        return res.status(403).json({ success: false, message: "Forbidden: Order does not belong to your branch" });
      }
    }

    if (fulfillment.status === "CANCELLED" || fulfillment.status === "DELIVERED" || fulfillment.status === "PICKED_UP") {
      res.status(400).json({ success: false, message: "Fulfillment is already in a terminal state" });
      return;
    }

    let validStatuses: string[] = [];
    if (fulfillment.fulfillment_type === "PICKUP") {
      validStatuses = ["PENDING", "PREPARING", "READY_FOR_PICKUP", "PICKED_UP", "CANCELLED"];
    } else {
      validStatuses = ["PENDING", "PREPARING", "SHIPPED", "DELIVERED", "CANCELLED"];
    }

    if (!status || !validStatuses.includes(status)) {
      res.status(400).json({ success: false, message: `Invalid status for ${fulfillment.fulfillment_type}. Allowed: ${validStatuses.join(", ")}` });
      return;
    }

    const updateData: Prisma.order_fulfillmentUpdateInput = {
      status,
      updated_at: new Date(),
    };

    if (trackingCode !== undefined) {
      updateData.tracking_code = typeof trackingCode === "string" ? trackingCode.trim() : null;
    }

    if (status === "SHIPPED" && fulfillment.status !== "SHIPPED") updateData.shipped_at = new Date();
    if (status === "DELIVERED" && fulfillment.status !== "DELIVERED") updateData.delivered_at = new Date();
    if (status === "PICKED_UP" && fulfillment.status !== "PICKED_UP") updateData.picked_up_at = new Date();
    if (status === "CANCELLED" && fulfillment.status !== "CANCELLED") updateData.cancelled_at = new Date();

    const updated = await prisma.$transaction(async (tx) => {
      const f = await tx.order_fulfillment.update({
        where: { id },
        data: updateData,
        include: { customer_order: true },
      });

      if (status === "PICKED_UP" || status === "DELIVERED") {
        if (f.customer_order.status !== "COMPLETED") {
          await tx.customer_order.update({
            where: { id: f.order_id },
            data: { status: "COMPLETED", completed_at: new Date() },
          });
        }
      }

      return f;
    });

    res.json({
      success: true,
      message: "Fulfillment status updated",
      data: { fulfillment: toFulfillmentResponse(updated) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "FULFILLMENT_STATUS_UPDATED",
      entityType: "order_fulfillment",
      entityId: updated.id,
      beforeData: { status: fulfillment.status },
      afterData: { status: updated.status },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    const notifiableStatuses = ["READY_FOR_PICKUP", "SHIPPED", "DELIVERED", "PICKED_UP", "CANCELLED"];
    if (notifiableStatuses.includes(status) && status !== fulfillment.status) {
      let title = "Cập nhật đơn hàng";
      let message = `Đơn hàng #${updated.order_id.toString()} của bạn đã chuyển sang trạng thái ${status}.`;

      if (status === "READY_FOR_PICKUP") {
        title = "Đơn hàng đã sẵn sàng";
        message = `Đơn hàng #${updated.order_id.toString()} đã sẵn sàng để nhận tại cửa hàng.`;
      } else if (status === "SHIPPED") {
        title = "Đơn hàng đang được giao";
        message = `Đơn hàng #${updated.order_id.toString()} đã được giao cho đơn vị vận chuyển.`;
      } else if (status === "DELIVERED") {
        title = "Giao hàng thành công";
        message = `Đơn hàng #${updated.order_id.toString()} đã được giao thành công.`;
      } else if (status === "PICKED_UP") {
        title = "Nhận hàng thành công";
        message = `Cảm ơn bạn đã nhận đơn hàng #${updated.order_id.toString()} tại cửa hàng.`;
      } else if (status === "CANCELLED") {
        title = "Đơn hàng bị huỷ";
        message = `Quá trình giao nhận đơn hàng #${updated.order_id.toString()} đã bị huỷ.`;
      }

      createNotification({
        userId: updated.customer_order.customer_id,
        type: "FULFILLMENT_UPDATE",
        title,
        message,
        data: {
          fulfillmentId: updated.id.toString(),
          orderId: updated.order_id.toString(),
          status: updated.status,
        },
      });
    }

  } catch (error) {
    next(error);
  }
});
