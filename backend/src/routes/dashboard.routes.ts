import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const dashboardRouter = Router();

const parseDateOnly = (value: unknown) => {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return null;
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  return date.toISOString().slice(0, 10) === value ? value : null;
};

const getTodayDateString = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
};

const getLocalDateRange = (dateString: string) => {
  const [year, month, day] = dateString.split("-").map(Number);
  const start = new Date(year, month - 1, day);
  const end = new Date(year, month - 1, day + 1);

  return { start, end };
};

dashboardRouter.get("/summary", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const isInternalStaff = req.user!.role === "BRANCH_MANAGER" || req.user!.role === "STAFF";
    
    if (isInternalStaff && !req.user!.branchId) {
      res.status(403).json({ success: false, message: "Forbidden: No assigned branch" });
      return;
    }

    const branchId = isInternalStaff ? BigInt(req.user!.branchId!) : null;

    let targetDateString = getTodayDateString();
    if (req.query.date) {
      const parsedDate = parseDateOnly(req.query.date);
      if (!parsedDate) {
        res.status(400).json({ success: false, message: "Invalid date format, expected YYYY-MM-DD or real date" });
        return;
      }
      targetDateString = parsedDate;
    }
    const { start: startOfDay, end: endOfDay } = getLocalDateRange(targetDateString);
    const bookingDate = new Date(`${targetDateString}T00:00:00.000Z`);

    // 1. Booking summary
    const bookingWhere = {
      booking_date: bookingDate,
      ...(branchId ? { court: { branch_id: branchId } } : {}),
    };

    const bookingsRaw = await prisma.booking.groupBy({
      by: ["status"],
      where: bookingWhere,
      _count: { _all: true },
    });

    const bookingsCount = {
      total: 0,
      booked: 0,
      checkedIn: 0,
      completed: 0,
      cancelled: 0,
    };

    for (const b of bookingsRaw) {
      bookingsCount.total += b._count._all;
      if (b.status === "BOOKED") bookingsCount.booked += b._count._all;
      if (b.status === "CHECKED_IN") bookingsCount.checkedIn += b._count._all;
      if (b.status === "COMPLETED") bookingsCount.completed += b._count._all;
      if (b.status === "CANCELLED") bookingsCount.cancelled += b._count._all;
    }

    // 2. Order summary
    const orderWhere = {
      created_at: {
        gte: startOfDay,
        lt: endOfDay,
      },
      ...(branchId ? { branch_id: branchId } : {}),
    };

    const ordersRaw = await prisma.customer_order.groupBy({
      by: ["status"],
      where: orderWhere,
      _count: { _all: true },
    });

    const revenueAggr = await prisma.customer_order.aggregate({
      where: { ...orderWhere, status: "COMPLETED" },
      _sum: { total_amount: true },
    });

    const ordersCount = {
      total: 0,
      pending: 0,
      readyForPickup: 0,
      completed: 0,
      cancelled: 0,
      revenueCompleted: revenueAggr._sum.total_amount?.toString() ?? "0",
    };

    for (const o of ordersRaw) {
      ordersCount.total += o._count._all;
      if (o.status === "PENDING") ordersCount.pending += o._count._all;
      if (o.status === "READY_FOR_PICKUP") ordersCount.readyForPickup += o._count._all;
      if (o.status === "COMPLETED") ordersCount.completed += o._count._all;
      if (o.status === "CANCELLED") ordersCount.cancelled += o._count._all;
    }

    // 3. Inventory low stock
    const inventoryWhere = {
      quantity: { lte: 5 },
      branch: { status: "ACTIVE" },
      ...(branchId ? { branch_id: branchId } : {}),
    };

    const lowStockCount = await prisma.inventory.count({ where: inventoryWhere });
    const lowStockItems = await prisma.inventory.findMany({
      where: inventoryWhere,
      orderBy: { quantity: "asc" },
      take: 10,
      include: {
        branch: true,
        product_variant: {
          include: {
            product: true,
          },
        },
      },
    });

    const mappedLowStock = lowStockItems.map((inv) => ({
      inventoryId: inv.id.toString(),
      branchId: inv.branch_id.toString(),
      branchName: inv.branch.name,
      productVariantId: inv.product_variant_id.toString(),
      productName: inv.product_variant.product.name,
      variantName: inv.product_variant.variant_name,
      sku: inv.product_variant.sku,
      quantity: inv.quantity,
    }));

    // 4. Court summary
    const courtWhere = {
      ...(branchId ? { branch_id: branchId } : {}),
    };

    const courtsRaw = await prisma.court.groupBy({
      by: ["status"],
      where: courtWhere,
      _count: { _all: true },
    });

    const courtsCount = {
      active: 0,
      maintenance: 0,
      inactive: 0,
    };

    for (const c of courtsRaw) {
      if (c.status === "ACTIVE") courtsCount.active += c._count._all;
      if (c.status === "MAINTENANCE") courtsCount.maintenance += c._count._all;
      if (c.status === "INACTIVE") courtsCount.inactive += c._count._all;
    }

    // 5. latestBookings
    const latestBookings = await prisma.booking.findMany({
      where: branchId ? { court: { branch_id: branchId } } : {},
      orderBy: { id: "desc" },
      take: 5,
      include: {
        court: { include: { branch: true } },
        app_user: true,
      },
    });

    const mappedLatestBookings = latestBookings.map((b) => ({
      id: b.id.toString(),
      bookingDate: b.booking_date.toISOString().slice(0, 10),
      status: b.status,
      totalAmount: b.total_amount.toString(),
      court: {
        id: b.court.id.toString(),
        name: b.court.name,
      },
      branch: {
        id: b.court.branch.id.toString(),
        name: b.court.branch.name,
      },
      customer: b.app_user
        ? {
            id: b.app_user.id.toString(),
            fullName: b.app_user.full_name,
          }
        : undefined,
    }));

    // 6. latestOrders
    const latestOrders = await prisma.customer_order.findMany({
      where: branchId ? { branch_id: branchId } : {},
      orderBy: { id: "desc" },
      take: 5,
      include: {
        branch: true,
        app_user: true,
      },
    });

    const mappedLatestOrders = latestOrders.map((o) => ({
      id: o.id.toString(),
      status: o.status,
      totalAmount: o.total_amount.toString(),
      createdAt: o.created_at.toISOString(),
      branch: {
        id: o.branch.id.toString(),
        name: o.branch.name,
      },
      customer: {
        id: o.app_user.id.toString(),
        fullName: o.app_user.full_name,
      },
    }));

    res.json({
      success: true,
      data: {
        scope: {
          role: req.user!.role,
          branchId: branchId ? branchId.toString() : null,
        },
        date: targetDateString,
        bookings: bookingsCount,
        orders: ordersCount,
        inventory: {
          lowStockCount,
          lowStockItems: mappedLowStock,
        },
        courts: courtsCount,
        latestBookings: mappedLatestBookings,
        latestOrders: mappedLatestOrders,
      },
    });
  } catch (error) {
    next(error);
  }
});
