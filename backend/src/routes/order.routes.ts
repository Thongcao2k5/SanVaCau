import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";
import { createNotification } from "../lib/notification.js";

export const orderRouter = Router();

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const validOrderStatuses = ["PENDING", "READY_FOR_PICKUP", "COMPLETED", "CANCELLED"] as const;

const normalizeOrderStatus = (value: unknown) => {
  if (typeof value !== "string") {
    return undefined;
  }

  const status = value.trim().toUpperCase();

  return status === "READY" ? "READY_FOR_PICKUP" : status;
};

const orderInclude = {
  branch: {
    select: {
      id: true,
      name: true,
      address: true,
    },
  },
  app_user: {
    select: {
      id: true,
      full_name: true,
      phone: true,
    },
  },
  order_item: {
    include: {
      product_variant: {
        select: {
          image_url: true,
        },
      },
    },
  },
} satisfies Prisma.customer_orderInclude;

type OrderWithDetails = Prisma.customer_orderGetPayload<{ include: typeof orderInclude }>;

const toOrderResponse = (order: OrderWithDetails) => ({
  id: order.id.toString(),
  customerId: order.customer_id.toString(),
  branchId: order.branch_id.toString(),
  status: order.status,
  totalAmount: order.total_amount.toString(),
  createdAt: order.created_at.toISOString(),
  readyAt: order.ready_at?.toISOString() ?? null,
  completedAt: order.completed_at?.toISOString() ?? null,
  cancelledAt: order.cancelled_at?.toISOString() ?? null,
  branch: {
    id: order.branch.id.toString(),
    name: order.branch.name,
    address: order.branch.address,
  },
  customer: {
    id: order.app_user.id.toString(),
    fullName: order.app_user.full_name,
    phone: order.app_user.phone,
  },
  items: order.order_item.map((item) => ({
    id: item.id.toString(),
    productVariantId: item.product_variant_id.toString(),
    productName: item.product_name,
    variantName: item.variant_name,
    unitPrice: item.unit_price.toString(),
    quantity: item.quantity,
    imageUrl: item.product_variant.image_url,
  })),
});

// POST /api/orders
orderRouter.post("/", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const branchId = parseBigIntId(req.body?.branchId);

    if (!branchId) {
      res.status(400).json({ success: false, message: "Valid branchId is required" });
      return;
    }

    const branch = await prisma.branch.findFirst({
      where: {
        id: branchId,
        status: "ACTIVE",
      },
    });

    if (!branch) {
      res.status(400).json({ success: false, message: "Branch not found or inactive" });
      return;
    }

    const cart = await prisma.cart.findUnique({
      where: { customer_id: customerId },
      include: {
        cart_item: {
          include: {
            product_variant: {
              include: {
                product: true,
              },
            },
          },
        },
      },
    });

    if (!cart || cart.cart_item.length === 0) {
      res.status(400).json({ success: false, message: "Cart is empty" });
      return;
    }

    // Check inventory
    const inventoryChecks = await Promise.all(
      cart.cart_item.map(async (item) => {
        const inventory = await prisma.inventory.findUnique({
          where: {
            branch_id_product_variant_id: {
              branch_id: branchId,
              product_variant_id: item.product_variant_id,
            },
          },
        });
        return { item, inventory };
      })
    );

    for (const { item, inventory } of inventoryChecks) {
      if (!item.product_variant.is_active || !item.product_variant.product.is_active) {
        res.status(400).json({
          success: false,
          message: `Product ${item.product_variant.product.name} - ${item.product_variant.variant_name} is no longer available`,
        });
        return;
      }
      if (!inventory || inventory.quantity < item.quantity) {
        res.status(400).json({
          success: false,
          message: `Not enough stock for ${item.product_variant.product.name} - ${item.product_variant.variant_name} at this branch`,
        });
        return;
      }
    }

    let totalAmount = 0;
    const orderItemsData = cart.cart_item.map((item) => {
      const unitPrice = Number(item.product_variant.price);
      totalAmount += unitPrice * item.quantity;

      return {
        product_variant_id: item.product_variant_id,
        product_name: item.product_variant.product.name,
        variant_name: item.product_variant.variant_name,
        unit_price: item.product_variant.price,
        quantity: item.quantity,
      };
    });

    const order = await prisma.$transaction(async (tx) => {
      const newOrder = await tx.customer_order.create({
        data: {
          customer_id: customerId,
          branch_id: branchId,
          status: "PENDING",
          total_amount: totalAmount,
          order_item: {
            createMany: {
              data: orderItemsData,
            },
          },
        },
      });

      // Decrease inventory only if enough stock is still available inside the transaction.
      for (const item of cart.cart_item) {
        const inventoryUpdate = await tx.inventory.updateMany({
          where: {
            branch_id: branchId,
            product_variant_id: item.product_variant_id,
            quantity: {
              gte: item.quantity,
            },
          },
          data: {
            quantity: {
              decrement: item.quantity,
            },
          },
        });

        if (inventoryUpdate.count !== 1) {
          throw new Error("INSUFFICIENT_STOCK");
        }
      }

      // Clear cart
      await tx.cart_item.deleteMany({
        where: { cart_id: cart.id },
      });
      await tx.cart.update({
        where: { id: cart.id },
        data: { updated_at: new Date() },
      });

      return tx.customer_order.findUnique({
        where: { id: newOrder.id },
        include: orderInclude,
      });
    });

    if (!order) {
      throw new Error("Failed to create order");
    }

    res.status(201).json({
      success: true,
      message: "Order created successfully",
      data: { order: toOrderResponse(order) },
    });

    createNotification({
      userId: order.customer_id,
      type: "ORDER_CREATED",
      title: "Đơn hàng đã được tạo",
      message: `Đơn hàng #${order.id.toString()} của bạn đang chờ xử lý.`,
      data: {
        orderId: order.id.toString(),
        status: order.status,
        totalAmount: order.total_amount.toString(),
      },
    });
  } catch (error) {
    if (error instanceof Error && error.message === "INSUFFICIENT_STOCK") {
      res.status(400).json({
        success: false,
        message: "Not enough stock for one or more items",
      });
      return;
    }

    next(error);
  }
});

// GET /api/orders/me
orderRouter.get("/me", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);

    const orders = await prisma.customer_order.findMany({
      where: { customer_id: customerId },
      orderBy: [{ created_at: "desc" }, { id: "desc" }],
      include: orderInclude,
    });

    res.json({
      success: true,
      data: {
        orders: orders.map(toOrderResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/orders/me/:id
orderRouter.get("/me/:id", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({ success: false, message: "Invalid order id" });
      return;
    }

    const order = await prisma.customer_order.findUnique({
      where: { id },
      include: orderInclude,
    });

    if (!order || order.customer_id !== customerId) {
      res.status(404).json({ success: false, message: "Order not found" });
      return;
    }

    res.json({
      success: true,
      data: {
        order: toOrderResponse(order),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/orders
orderRouter.get("/", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const isInternalStaff = req.user!.role === "BRANCH_MANAGER" || req.user!.role === "STAFF";
    
    if (isInternalStaff && !req.user!.branchId) {
      res.status(403).json({ success: false, message: "Forbidden: No assigned branch" });
      return;
    }

    const assignedBranchId = isInternalStaff ? BigInt(req.user!.branchId!) : null;
    const branchIdQuery = parseBigIntId(req.query.branchId as string);
    const customerId = parseBigIntId(req.query.customerId as string);
    const status = normalizeOrderStatus(req.query.status);

    if (req.query.branchId !== undefined && !branchIdQuery) {
      res.status(400).json({ success: false, message: "Invalid branchId" });
      return;
    }

    if (req.query.customerId !== undefined && !customerId) {
      res.status(400).json({ success: false, message: "Invalid customerId" });
      return;
    }

    if (status !== undefined && !validOrderStatuses.includes(status as (typeof validOrderStatuses)[number])) {
      res.status(400).json({ success: false, message: "Invalid status" });
      return;
    }

    const branchId = isInternalStaff ? assignedBranchId : branchIdQuery;

    const orders = await prisma.customer_order.findMany({
      where: {
        ...(branchId ? { branch_id: branchId } : {}),
        ...(customerId ? { customer_id: customerId } : {}),
        ...(status ? { status } : {}),
      },
      orderBy: [{ created_at: "desc" }, { id: "desc" }],
      include: orderInclude,
    });

    res.json({
      success: true,
      data: {
        orders: orders.map(toOrderResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/orders/:id
orderRouter.get("/:id", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({ success: false, message: "Invalid order id" });
      return;
    }

    const order = await prisma.customer_order.findUnique({
      where: { id },
      include: orderInclude,
    });

    if (!order) {
      res.status(404).json({ success: false, message: "Order not found" });
      return;
    }

    const isInternalStaff = req.user!.role === "BRANCH_MANAGER" || req.user!.role === "STAFF";
    
    if (isInternalStaff) {
      if (!req.user!.branchId) {
        res.status(403).json({ success: false, message: "Forbidden: No assigned branch" });
        return;
      }
      if (order.branch_id.toString() !== req.user!.branchId) {
        res.status(403).json({ success: false, message: "Forbidden: Order does not belong to your branch" });
        return;
      }
    }

    res.json({
      success: true,
      data: {
        order: toOrderResponse(order),
      },
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/orders/:id/status
orderRouter.patch("/:id/status", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    const status = normalizeOrderStatus(req.body?.status);

    if (!id) {
      res.status(400).json({ success: false, message: "Invalid order id" });
      return;
    }

    if (!status || !validOrderStatuses.includes(status as (typeof validOrderStatuses)[number])) {
      res.status(400).json({ success: false, message: "Invalid status" });
      return;
    }

    const existingOrder = await prisma.customer_order.findUnique({
      where: { id },
      include: {
        order_item: true,
      },
    });

    if (!existingOrder) {
      res.status(404).json({ success: false, message: "Order not found" });
      return;
    }

    const isInternalStaff = req.user!.role === "BRANCH_MANAGER" || req.user!.role === "STAFF";

    if (isInternalStaff) {
      if (!req.user!.branchId) {
        res.status(403).json({ success: false, message: "Forbidden: No assigned branch" });
        return;
      }
      if (existingOrder.branch_id.toString() !== req.user!.branchId) {
        res.status(403).json({ success: false, message: "Forbidden: Order does not belong to your branch" });
        return;
      }
    }

    if (existingOrder.status === "COMPLETED") {
      res.status(400).json({ success: false, message: "Order is already completed and cannot be modified" });
      return;
    }

    if (existingOrder.status === "CANCELLED") {
      res.status(400).json({ success: false, message: "Order is already cancelled and cannot be modified" });
      return;
    }

    const now = new Date();
    const updateData: {
      status: string;
      ready_at?: Date;
      completed_at?: Date;
      cancelled_at?: Date;
    } = { status };

    if (status === "READY_FOR_PICKUP" && existingOrder.status !== "READY_FOR_PICKUP") {
      updateData.ready_at = now;
    } else if (status === "COMPLETED" && existingOrder.status !== "COMPLETED") {
      updateData.completed_at = now;
    } else if (status === "CANCELLED" && existingOrder.status !== "CANCELLED") {
      updateData.cancelled_at = now;
    }

    const updatedOrder = await prisma.$transaction(async (tx) => {
      // Re-increment inventory if cancelled
      if (status === "CANCELLED" && existingOrder.status !== "CANCELLED") {
        for (const item of existingOrder.order_item) {
          await tx.inventory.update({
            where: {
              branch_id_product_variant_id: {
                branch_id: existingOrder.branch_id,
                product_variant_id: item.product_variant_id,
              },
            },
            data: {
              quantity: {
                increment: item.quantity,
              },
            },
          });
        }
      }

      return tx.customer_order.update({
        where: { id },
        data: updateData,
        include: orderInclude,
      });
    });

    res.json({
      success: true,
      message: "Order status updated successfully",
      data: { order: toOrderResponse(updatedOrder) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "ORDER_STATUS_UPDATED",
      entityType: "order",
      entityId: updatedOrder.id,
      beforeData: { status: existingOrder.status },
      afterData: { status: updatedOrder.status },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    createNotification({
      userId: updatedOrder.customer_id,
      type: "ORDER_STATUS_UPDATED",
      title: "Trạng thái đơn hàng đã cập nhật",
      message: `Đơn hàng #${updatedOrder.id.toString()} chuyển sang trạng thái ${updatedOrder.status}.`,
      data: {
        orderId: updatedOrder.id.toString(),
        oldStatus: existingOrder.status,
        newStatus: updatedOrder.status,
      },
    });
  } catch (error) {
    next(error);
  }
});
