import { Router, type Request, type Response } from "express";
import { Prisma, type PrismaClient } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const reportRouter = Router();

reportRouter.use(requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]));

type DateFilter = {
  gte?: Date;
  lte?: Date;
};

type BranchScope = bigint | null;

type TopProductRow = {
  productId: bigint;
  productName: string;
  variantName: string;
  totalQuantity: bigint | number;
  totalRevenue: Prisma.Decimal | string | number | null;
};

type TopCourtRow = {
  courtId: bigint;
  courtName: string;
  branchName: string;
  bookingCount: bigint | number;
  totalRevenue: Prisma.Decimal | string | number | null;
};

const parseBigIntId = (value: unknown) => {
  if (typeof value !== "string" || !/^\d+$/.test(value)) {
    return null;
  }

  return BigInt(value);
};

const parseDateOnly = (value: unknown) => {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return null;
  }

  const date = new Date(`${value}T00:00:00.000Z`);
  return date.toISOString().slice(0, 10) === value ? date : null;
};

const parseLimit = (value: unknown) => {
  if (value === undefined) {
    return 10;
  }

  if (typeof value !== "string" || !/^\d+$/.test(value)) {
    return null;
  }

  const limit = Number(value);
  if (!Number.isSafeInteger(limit) || limit < 1) {
    return null;
  }

  return Math.min(limit, 50);
};

const getBranchScope = (req: Request, res: Response): BranchScope | undefined => {
  const user = req.user!;
  const isBranchScopedRole = user.role === "BRANCH_MANAGER" || user.role === "STAFF";

  if (isBranchScopedRole) {
    if (!user.branchId) {
      res.status(403).json({ success: false, message: "Forbidden: No assigned branch" });
      return undefined;
    }

    return BigInt(user.branchId);
  }

  if (req.query.branchId !== undefined) {
    const branchId = parseBigIntId(req.query.branchId);
    if (!branchId) {
      res.status(400).json({ success: false, message: "Invalid branchId" });
      return undefined;
    }

    return branchId;
  }

  return null;
};

const getDateFilter = (req: Request, res: Response): DateFilter | undefined | null => {
  const filter: DateFilter = {};

  if (req.query.from !== undefined) {
    const from = parseDateOnly(req.query.from);
    if (!from) {
      res.status(400).json({ success: false, message: "Invalid from date format, expected YYYY-MM-DD" });
      return undefined;
    }
    filter.gte = from;
  }

  if (req.query.to !== undefined) {
    const toDate = parseDateOnly(req.query.to);
    if (!toDate) {
      res.status(400).json({ success: false, message: "Invalid to date format, expected YYYY-MM-DD" });
      return undefined;
    }
    filter.lte = new Date(toDate.getTime() + 24 * 60 * 60 * 1000 - 1);
  }

  if (filter.gte && filter.lte && filter.gte > filter.lte) {
    res.status(400).json({ success: false, message: "from must be before or equal to to" });
    return undefined;
  }

  return Object.keys(filter).length > 0 ? filter : null;
};

const decimalToString = (value: Prisma.Decimal | string | number | null | undefined) => {
  return value?.toString() ?? "0";
};

const dateWhere = (dateFilter: DateFilter | null) => {
  return dateFilter ? { created_at: dateFilter } : {};
};

const getPaymentBranchWhere = (branchId: BranchScope) => {
  if (branchId === null) {
    return Prisma.empty;
  }

  return Prisma.sql`
    AND (
      (p.target_type = 'ORDER' AND EXISTS (
        SELECT 1 FROM customer_order o
        WHERE o.id = p.target_id AND o.branch_id = ${branchId}
      ))
      OR
      (p.target_type = 'BOOKING' AND EXISTS (
        SELECT 1 FROM booking b
        JOIN court c ON c.id = b.court_id
        WHERE b.id = p.target_id AND c.branch_id = ${branchId}
      ))
    )
  `;
};

const getSupportBranchWhere = (branchId: BranchScope) => {
  if (branchId === null) {
    return Prisma.empty;
  }

  return Prisma.sql`
    AND (
      (st.target_type = 'ORDER' AND EXISTS (
        SELECT 1 FROM customer_order o
        WHERE o.id = st.target_id AND o.branch_id = ${branchId}
      ))
      OR
      (st.target_type = 'BOOKING' AND EXISTS (
        SELECT 1 FROM booking b
        JOIN court c ON c.id = b.court_id
        WHERE b.id = st.target_id AND c.branch_id = ${branchId}
      ))
    )
  `;
};

const paymentSummaryByBranch = async (client: PrismaClient, branchId: BranchScope, dateFilter: DateFilter | null) => {
  const rows = await client.$queryRaw<Array<{ count: bigint; total: Prisma.Decimal | null }>>(Prisma.sql`
    SELECT COUNT(*) AS count, COALESCE(SUM(p.amount), 0) AS total
    FROM payment p
    WHERE p.status = 'COMPLETED'
    ${dateFilter?.gte ? Prisma.sql`AND p.created_at >= ${dateFilter.gte}` : Prisma.empty}
    ${dateFilter?.lte ? Prisma.sql`AND p.created_at <= ${dateFilter.lte}` : Prisma.empty}
    ${getPaymentBranchWhere(branchId)}
  `);

  return rows[0] ?? { count: BigInt(0), total: new Prisma.Decimal(0) };
};

const supportCountByBranch = async (
  client: PrismaClient,
  branchId: BranchScope,
  dateFilter: DateFilter | null,
  statusSql = Prisma.empty,
) => {
  const rows = await client.$queryRaw<Array<{ count: bigint }>>(Prisma.sql`
    SELECT COUNT(*) AS count
    FROM support_ticket st
    WHERE 1 = 1
    ${statusSql}
    ${dateFilter?.gte ? Prisma.sql`AND st.created_at >= ${dateFilter.gte}` : Prisma.empty}
    ${dateFilter?.lte ? Prisma.sql`AND st.created_at <= ${dateFilter.lte}` : Prisma.empty}
    ${getSupportBranchWhere(branchId)}
  `);

  return Number(rows[0]?.count ?? 0);
};

reportRouter.get("/overview", async (req, res, next) => {
  try {
    const branchId = getBranchScope(req, res);
    if (branchId === undefined) return;

    const dateFilter = getDateFilter(req, res);
    if (dateFilter === undefined) return;

    const orderWhere: Prisma.customer_orderWhereInput = {
      ...dateWhere(dateFilter),
      ...(branchId !== null ? { branch_id: branchId } : {}),
    };

    const bookingWhere: Prisma.bookingWhereInput = {
      ...dateWhere(dateFilter),
      ...(branchId !== null ? { court: { branch_id: branchId } } : {}),
    };

    const customerWhere: Prisma.app_userWhereInput = {
      role: "CUSTOMER",
      ...dateWhere(dateFilter),
      ...(branchId !== null
        ? {
            OR: [
              { customer_order: { some: { branch_id: branchId } } },
              { booking: { some: { court: { branch_id: branchId } } } },
            ],
          }
        : {}),
    };

    const [
      totalOrders,
      orderRevenueResult,
      totalBookings,
      bookingRevenueResult,
      totalCustomers,
      totalSupportTickets,
      openSupportTickets,
      resolvedSupportTickets,
      paymentSummary,
    ] = await Promise.all([
      prisma.customer_order.count({ where: orderWhere }),
      prisma.customer_order.aggregate({
        where: { ...orderWhere, status: "COMPLETED" },
        _sum: { total_amount: true },
      }),
      prisma.booking.count({ where: bookingWhere }),
      prisma.booking.aggregate({
        where: { ...bookingWhere, status: "COMPLETED" },
        _sum: { total_amount: true },
      }),
      prisma.app_user.count({ where: customerWhere }),
      supportCountByBranch(prisma, branchId, dateFilter),
      supportCountByBranch(prisma, branchId, dateFilter, Prisma.sql`AND st.status = 'OPEN'`),
      supportCountByBranch(prisma, branchId, dateFilter, Prisma.sql`AND st.status IN ('RESOLVED', 'CLOSED')`),
      paymentSummaryByBranch(prisma, branchId, dateFilter),
    ]);

    res.json({
      success: true,
      data: {
        totalOrders,
        totalOrderRevenue: decimalToString(orderRevenueResult._sum.total_amount),
        totalBookings,
        totalBookingRevenue: decimalToString(bookingRevenueResult._sum.total_amount),
        totalPayments: Number(paymentSummary.count),
        totalPaidAmount: decimalToString(paymentSummary.total),
        totalCustomers,
        totalSupportTickets,
        openSupportTickets,
        resolvedSupportTickets,
      },
    });
  } catch (error) {
    next(error);
  }
});

reportRouter.get("/orders", async (req, res, next) => {
  try {
    const branchId = getBranchScope(req, res);
    if (branchId === undefined) return;

    const dateFilter = getDateFilter(req, res);
    if (dateFilter === undefined) return;

    const status = typeof req.query.status === "string" ? req.query.status : undefined;

    const orderWhere: Prisma.customer_orderWhereInput = {
      ...dateWhere(dateFilter),
      ...(branchId !== null ? { branch_id: branchId } : {}),
      ...(status ? { status } : {}),
    };

    const [total, revenueResult, statusCountsRaw, latestOrdersRaw] = await Promise.all([
      prisma.customer_order.count({ where: orderWhere }),
      prisma.customer_order.aggregate({
        where: { ...orderWhere, status: "COMPLETED" },
        _sum: { total_amount: true },
      }),
      prisma.customer_order.groupBy({
        by: ["status"],
        where: {
          ...dateWhere(dateFilter),
          ...(branchId !== null ? { branch_id: branchId } : {}),
        },
        _count: { _all: true },
      }),
      prisma.customer_order.findMany({
        where: orderWhere,
        orderBy: { created_at: "desc" },
        take: 10,
        include: {
          app_user: { select: { full_name: true } },
          branch: { select: { name: true } },
        },
      }),
    ]);

    res.json({
      success: true,
      data: {
        total,
        revenue: decimalToString(revenueResult._sum.total_amount),
        countByStatus: statusCountsRaw.map((item) => ({
          status: item.status,
          count: item._count._all,
        })),
        latestOrders: latestOrdersRaw.map((order) => ({
          id: order.id.toString(),
          customerName: order.app_user.full_name,
          branchName: order.branch.name,
          status: order.status,
          totalAmount: order.total_amount.toString(),
          createdAt: order.created_at.toISOString(),
        })),
      },
    });
  } catch (error) {
    next(error);
  }
});

reportRouter.get("/bookings", async (req, res, next) => {
  try {
    const branchId = getBranchScope(req, res);
    if (branchId === undefined) return;

    const dateFilter = getDateFilter(req, res);
    if (dateFilter === undefined) return;

    const status = typeof req.query.status === "string" ? req.query.status : undefined;

    const bookingWhere: Prisma.bookingWhereInput = {
      ...dateWhere(dateFilter),
      ...(branchId !== null ? { court: { branch_id: branchId } } : {}),
      ...(status ? { status } : {}),
    };

    const [total, revenueResult, statusCountsRaw, latestBookingsRaw] = await Promise.all([
      prisma.booking.count({ where: bookingWhere }),
      prisma.booking.aggregate({
        where: { ...bookingWhere, status: "COMPLETED" },
        _sum: { total_amount: true },
      }),
      prisma.booking.groupBy({
        by: ["status"],
        where: {
          ...dateWhere(dateFilter),
          ...(branchId !== null ? { court: { branch_id: branchId } } : {}),
        },
        _count: { _all: true },
      }),
      prisma.booking.findMany({
        where: bookingWhere,
        orderBy: { created_at: "desc" },
        take: 10,
        include: {
          app_user: { select: { full_name: true } },
          court: {
            select: {
              name: true,
              branch: { select: { name: true } },
            },
          },
        },
      }),
    ]);

    res.json({
      success: true,
      data: {
        total,
        revenue: decimalToString(revenueResult._sum.total_amount),
        countByStatus: statusCountsRaw.map((item) => ({
          status: item.status,
          count: item._count._all,
        })),
        latestBookings: latestBookingsRaw.map((booking) => ({
          id: booking.id.toString(),
          customerName: booking.app_user.full_name,
          branchName: booking.court.branch.name,
          courtName: booking.court.name,
          bookingDate: booking.booking_date.toISOString().slice(0, 10),
          status: booking.status,
          totalAmount: booking.total_amount.toString(),
          createdAt: booking.created_at.toISOString(),
        })),
      },
    });
  } catch (error) {
    next(error);
  }
});

reportRouter.get("/top-products", async (req, res, next) => {
  try {
    const branchId = getBranchScope(req, res);
    if (branchId === undefined) return;

    const dateFilter = getDateFilter(req, res);
    if (dateFilter === undefined) return;

    const limit = parseLimit(req.query.limit);
    if (limit === null) {
      return res.status(400).json({ success: false, message: "Invalid limit" });
    }

    const rawResults = await prisma.$queryRaw<TopProductRow[]>(Prisma.sql`
      SELECT
        oi.product_variant_id AS "productId",
        MAX(oi.product_name) AS "productName",
        MAX(oi.variant_name) AS "variantName",
        SUM(oi.quantity) AS "totalQuantity",
        SUM(oi.quantity * oi.unit_price) AS "totalRevenue"
      FROM order_item oi
      JOIN customer_order o ON oi.order_id = o.id
      WHERE o.status = 'COMPLETED'
      ${branchId !== null ? Prisma.sql`AND o.branch_id = ${branchId}` : Prisma.empty}
      ${dateFilter?.gte ? Prisma.sql`AND o.created_at >= ${dateFilter.gte}` : Prisma.empty}
      ${dateFilter?.lte ? Prisma.sql`AND o.created_at <= ${dateFilter.lte}` : Prisma.empty}
      GROUP BY oi.product_variant_id
      ORDER BY "totalQuantity" DESC
      LIMIT ${limit}
    `);

    res.json({
      success: true,
      data: rawResults.map((row) => ({
        productId: row.productId.toString(),
        productName:
          row.variantName && row.variantName !== "Default Title"
            ? `${row.productName} - ${row.variantName}`
            : row.productName,
        totalQuantity: Number(row.totalQuantity),
        totalRevenue: decimalToString(row.totalRevenue),
      })),
    });
  } catch (error) {
    next(error);
  }
});

reportRouter.get("/top-courts", async (req, res, next) => {
  try {
    const branchId = getBranchScope(req, res);
    if (branchId === undefined) return;

    const dateFilter = getDateFilter(req, res);
    if (dateFilter === undefined) return;

    const limit = parseLimit(req.query.limit);
    if (limit === null) {
      return res.status(400).json({ success: false, message: "Invalid limit" });
    }

    const rawResults = await prisma.$queryRaw<TopCourtRow[]>(Prisma.sql`
      SELECT
        b.court_id AS "courtId",
        MAX(c.name) AS "courtName",
        MAX(br.name) AS "branchName",
        COUNT(b.id) AS "bookingCount",
        SUM(b.total_amount) AS "totalRevenue"
      FROM booking b
      JOIN court c ON b.court_id = c.id
      JOIN branch br ON c.branch_id = br.id
      WHERE b.status = 'COMPLETED'
      ${branchId !== null ? Prisma.sql`AND c.branch_id = ${branchId}` : Prisma.empty}
      ${dateFilter?.gte ? Prisma.sql`AND b.created_at >= ${dateFilter.gte}` : Prisma.empty}
      ${dateFilter?.lte ? Prisma.sql`AND b.created_at <= ${dateFilter.lte}` : Prisma.empty}
      GROUP BY b.court_id
      ORDER BY "bookingCount" DESC
      LIMIT ${limit}
    `);

    res.json({
      success: true,
      data: rawResults.map((row) => ({
        courtId: row.courtId.toString(),
        courtName: row.courtName,
        branchName: row.branchName,
        bookingCount: Number(row.bookingCount),
        totalRevenue: decimalToString(row.totalRevenue),
      })),
    });
  } catch (error) {
    next(error);
  }
});
