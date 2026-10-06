import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";
import { createNotification } from "../lib/notification.js";

export const reviewRouter = Router();

// ── helpers ────────────────────────────────────────────────

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const VALID_TARGET_TYPES = ["PRODUCT", "COURT"] as const;
type TargetType = (typeof VALID_TARGET_TYPES)[number];

const VALID_STATUSES = ["PUBLISHED", "HIDDEN"] as const;
type ReviewStatus = (typeof VALID_STATUSES)[number];

const reviewInclude = {
  app_user: {
    select: {
      id: true,
      full_name: true,
    },
  },
} satisfies Prisma.reviewInclude;

type ReviewWithUser = Prisma.reviewGetPayload<{ include: typeof reviewInclude }>;

const toReviewResponse = (r: ReviewWithUser) => ({
  id: r.id.toString(),
  userId: r.user_id.toString(),
  targetType: r.target_type,
  targetId: r.target_id.toString(),
  rating: r.rating,
  comment: r.comment,
  status: r.status,
  createdAt: r.created_at.toISOString(),
  updatedAt: r.updated_at.toISOString(),
  user: {
    id: r.app_user.id.toString(),
    fullName: r.app_user.full_name,
  },
});

const reviewTargetKey = (targetType: string, targetId: bigint) => `${targetType}:${targetId}`;

const addTargetMetadata = async (reviews: ReviewWithUser[]) => {
  const productIds = reviews
    .filter((review) => review.target_type === "PRODUCT")
    .map((review) => review.target_id);
  const courtIds = reviews
    .filter((review) => review.target_type === "COURT")
    .map((review) => review.target_id);

  const [products, courts] = await Promise.all([
    productIds.length
      ? prisma.product.findMany({
          where: { id: { in: productIds } },
          select: { id: true, name: true },
        })
      : [],
    courtIds.length
      ? prisma.court.findMany({
          where: { id: { in: courtIds } },
          select: { id: true, name: true },
        })
      : [],
  ]);

  const targetNames = new Map<string, string>();
  products.forEach((product) => targetNames.set(reviewTargetKey("PRODUCT", product.id), product.name));
  courts.forEach((court) => targetNames.set(reviewTargetKey("COURT", court.id), court.name));

  return reviews.map((review) => ({
    ...toReviewResponse(review),
    target: {
      type: review.target_type,
      id: review.target_id.toString(),
      name:
        targetNames.get(reviewTargetKey(review.target_type, review.target_id)) ??
        `${review.target_type === "PRODUCT" ? "Product" : "Court"} #${review.target_id}`,
    },
  }));
};

type ReviewRow = Prisma.reviewGetPayload<{}>;

const toReviewResponseBasic = (r: ReviewRow) => ({
  id: r.id.toString(),
  userId: r.user_id.toString(),
  targetType: r.target_type,
  targetId: r.target_id.toString(),
  rating: r.rating,
  comment: r.comment,
  status: r.status,
  createdAt: r.created_at.toISOString(),
  updatedAt: r.updated_at.toISOString(),
});

const buildPagination = (page: number, limit: number, total: number) => ({
  page,
  limit,
  total,
  totalPages: Math.ceil(total / limit),
});

const parsePage = (value: unknown) => Math.max(1, parseInt(value as string) || 1);
const parseLimit = (value: unknown) => Math.min(100, Math.max(1, parseInt(value as string) || 20));

// ── A. POST /api/reviews ───────────────────────────────────

reviewRouter.post("/", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);

    // --- validate targetType ---
    const rawTargetType = typeof req.body.targetType === "string" ? req.body.targetType.trim().toUpperCase() : "";
    if (!VALID_TARGET_TYPES.includes(rawTargetType as TargetType)) {
      res.status(400).json({
        success: false,
        message: "targetType must be PRODUCT or COURT",
      });
      return;
    }
    const targetType = rawTargetType as TargetType;

    // --- validate targetId ---
    const targetId = parseBigIntId(req.body.targetId?.toString());
    if (!targetId) {
      res.status(400).json({
        success: false,
        message: "targetId must be a valid positive integer",
      });
      return;
    }

    // --- validate rating ---
    const rating = typeof req.body.rating === "number" ? req.body.rating : parseInt(req.body.rating);
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      res.status(400).json({
        success: false,
        message: "rating must be an integer from 1 to 5",
      });
      return;
    }

    // --- validate comment ---
    const comment = typeof req.body.comment === "string" ? req.body.comment.trim() : null;
    if (comment && comment.length > 1000) {
      res.status(400).json({
        success: false,
        message: "comment must be at most 1000 characters",
      });
      return;
    }

    // --- business rule: verify purchase / booking eligibility ---
    if (targetType === "PRODUCT") {
      // Check product exists
      const product = await prisma.product.findUnique({ where: { id: targetId } });
      if (!product) {
        res.status(404).json({ success: false, message: "Product not found" });
        return;
      }

      // Customer must have at least one COMPLETED order containing a variant of this product
      const completedOrderWithProduct = await prisma.order_item.findFirst({
        where: {
          customer_order: {
            customer_id: userId,
            status: "COMPLETED",
          },
          product_variant: {
            product_id: targetId,
          },
        },
      });

      if (!completedOrderWithProduct) {
        res.status(403).json({
          success: false,
          message: "You can only review a product you have purchased (completed order required)",
        });
        return;
      }
    } else {
      // COURT
      const court = await prisma.court.findUnique({ where: { id: targetId } });
      if (!court) {
        res.status(404).json({ success: false, message: "Court not found" });
        return;
      }

      // Customer must have at least one COMPLETED booking for this court
      const completedBooking = await prisma.booking.findFirst({
        where: {
          customer_id: userId,
          court_id: targetId,
          status: "COMPLETED",
        },
      });

      if (!completedBooking) {
        res.status(403).json({
          success: false,
          message: "You can only review a court you have booked (completed booking required)",
        });
        return;
      }
    }

    // --- check duplicate ---
    const existing = await prisma.review.findUnique({
      where: {
        user_id_target_type_target_id: {
          user_id: userId,
          target_type: targetType,
          target_id: targetId,
        },
      },
    });

    if (existing) {
      res.status(409).json({
        success: false,
        message: "You have already reviewed this " + targetType.toLowerCase(),
      });
      return;
    }

    // --- create review ---
    const review = await prisma.review.create({
      data: {
        user_id: userId,
        target_type: targetType,
        target_id: targetId,
        rating,
        comment: comment || null,
        status: "PUBLISHED",
      },
      include: reviewInclude,
    });

    res.status(201).json({
      success: true,
      message: "Review created successfully",
      data: {
        review: toReviewResponse(review),
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── B. PATCH /api/reviews/:id ──────────────────────────────

reviewRouter.patch("/:id", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);
    const reviewId = parseBigIntId(req.params.id);

    if (!reviewId) {
      res.status(400).json({ success: false, message: "Invalid review id" });
      return;
    }

    const review = await prisma.review.findUnique({ where: { id: reviewId } });

    if (!review) {
      res.status(404).json({ success: false, message: "Review not found" });
      return;
    }

    if (review.user_id !== userId) {
      res.status(403).json({ success: false, message: "You can only update your own review" });
      return;
    }

    // --- validate rating (optional) ---
    const updateData: Prisma.reviewUpdateInput = {
      updated_at: new Date(),
    };

    if (req.body.rating !== undefined) {
      const rating = typeof req.body.rating === "number" ? req.body.rating : parseInt(req.body.rating);
      if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
        res.status(400).json({
          success: false,
          message: "rating must be an integer from 1 to 5",
        });
        return;
      }
      updateData.rating = rating;
    }

    // --- validate comment (optional) ---
    if (req.body.comment !== undefined) {
      if (req.body.comment === null) {
        updateData.comment = null;
      } else {
        const comment = typeof req.body.comment === "string" ? req.body.comment.trim() : "";
        if (comment.length > 1000) {
          res.status(400).json({
            success: false,
            message: "comment must be at most 1000 characters",
          });
          return;
        }
        updateData.comment = comment || null;
      }
    }

    const updated = await prisma.review.update({
      where: { id: reviewId },
      data: updateData,
      include: reviewInclude,
    });

    res.json({
      success: true,
      message: "Review updated successfully",
      data: {
        review: toReviewResponse(updated),
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── C. GET /api/reviews/products/:productId ─────────────────

reviewRouter.get("/products/:productId", async (req, res, next) => {
  try {
    const productId = parseBigIntId(req.params.productId);

    if (!productId) {
      res.status(400).json({ success: false, message: "Invalid productId" });
      return;
    }

    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit);
    const skip = (page - 1) * limit;

    const where: Prisma.reviewWhereInput = {
      target_type: "PRODUCT",
      target_id: productId,
      status: "PUBLISHED",
    };

    // optional rating filter
    const ratingFilter = parseInt(req.query.rating as string);
    if (Number.isInteger(ratingFilter) && ratingFilter >= 1 && ratingFilter <= 5) {
      where.rating = ratingFilter;
    }

    const [items, total, aggregation] = await Promise.all([
      prisma.review.findMany({
        where,
        include: reviewInclude,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
      prisma.review.count({ where }),
      prisma.review.aggregate({
        where: {
          target_type: "PRODUCT",
          target_id: productId,
          status: "PUBLISHED",
        },
        _avg: { rating: true },
        _count: { id: true },
      }),
    ]);

    res.json({
      success: true,
      data: {
        summary: {
          averageRating: aggregation._avg.rating ? Number(aggregation._avg.rating.toFixed(1)) : null,
          totalReviews: Number(aggregation._count.id),
        },
        items: items.map(toReviewResponse),
        pagination: buildPagination(page, limit, Number(total)),
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── D. GET /api/reviews/courts/:courtId ─────────────────────

reviewRouter.get("/courts/:courtId", async (req, res, next) => {
  try {
    const courtId = parseBigIntId(req.params.courtId);

    if (!courtId) {
      res.status(400).json({ success: false, message: "Invalid courtId" });
      return;
    }

    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit);
    const skip = (page - 1) * limit;

    const where: Prisma.reviewWhereInput = {
      target_type: "COURT",
      target_id: courtId,
      status: "PUBLISHED",
    };

    // optional rating filter
    const ratingFilter = parseInt(req.query.rating as string);
    if (Number.isInteger(ratingFilter) && ratingFilter >= 1 && ratingFilter <= 5) {
      where.rating = ratingFilter;
    }

    const [items, total, aggregation] = await Promise.all([
      prisma.review.findMany({
        where,
        include: reviewInclude,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
      prisma.review.count({ where }),
      prisma.review.aggregate({
        where: {
          target_type: "COURT",
          target_id: courtId,
          status: "PUBLISHED",
        },
        _avg: { rating: true },
        _count: { id: true },
      }),
    ]);

    res.json({
      success: true,
      data: {
        summary: {
          averageRating: aggregation._avg.rating ? Number(aggregation._avg.rating.toFixed(1)) : null,
          totalReviews: Number(aggregation._count.id),
        },
        items: items.map(toReviewResponse),
        pagination: buildPagination(page, limit, Number(total)),
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── E. GET /api/reviews/me ──────────────────────────────────

reviewRouter.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);

    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit);
    const skip = (page - 1) * limit;

    const where: Prisma.reviewWhereInput = { user_id: userId };

    // optional targetType filter
    const targetTypeFilter = typeof req.query.targetType === "string" ? req.query.targetType.trim().toUpperCase() : undefined;
    if (targetTypeFilter && VALID_TARGET_TYPES.includes(targetTypeFilter as TargetType)) {
      where.target_type = targetTypeFilter;
    }

    // optional status filter (user can see own HIDDEN reviews too)
    const statusFilter = typeof req.query.status === "string" ? req.query.status.trim().toUpperCase() : undefined;
    if (statusFilter && VALID_STATUSES.includes(statusFilter as ReviewStatus)) {
      where.status = statusFilter;
    }

    const [items, total] = await Promise.all([
      prisma.review.findMany({
        where,
        include: reviewInclude,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
      prisma.review.count({ where }),
    ]);
    const itemsWithTargets = await addTargetMetadata(items);

    res.json({
      success: true,
      data: {
        items: itemsWithTargets,
        pagination: buildPagination(page, limit, Number(total)),
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── F. GET /api/reviews (ADMIN only) ────────────────────────

reviewRouter.get("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit);
    const skip = (page - 1) * limit;

    const where: Prisma.reviewWhereInput = {};

    // optional userId filter
    const userIdFilter = parseBigIntId(req.query.userId as string);
    if (userIdFilter) {
      where.user_id = userIdFilter;
    }

    // optional targetType filter
    const targetTypeFilter = typeof req.query.targetType === "string" ? req.query.targetType.trim().toUpperCase() : undefined;
    if (targetTypeFilter && VALID_TARGET_TYPES.includes(targetTypeFilter as TargetType)) {
      where.target_type = targetTypeFilter;
    }

    // optional targetId filter
    const targetIdFilter = parseBigIntId(req.query.targetId as string);
    if (targetIdFilter) {
      where.target_id = targetIdFilter;
    }

    // optional status filter
    const statusFilter = typeof req.query.status === "string" ? req.query.status.trim().toUpperCase() : undefined;
    if (statusFilter && VALID_STATUSES.includes(statusFilter as ReviewStatus)) {
      where.status = statusFilter;
    }

    // optional rating filter
    const ratingFilter = parseInt(req.query.rating as string);
    if (Number.isInteger(ratingFilter) && ratingFilter >= 1 && ratingFilter <= 5) {
      where.rating = ratingFilter;
    }

    const [items, total] = await Promise.all([
      prisma.review.findMany({
        where,
        include: reviewInclude,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
      prisma.review.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        items: items.map(toReviewResponse),
        pagination: buildPagination(page, limit, Number(total)),
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── G. PATCH /api/reviews/:id/status (ADMIN moderation) ─────

reviewRouter.patch("/:id/status", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const admin = req.user!;
    const reviewId = parseBigIntId(req.params.id);

    if (!reviewId) {
      res.status(400).json({ success: false, message: "Invalid review id" });
      return;
    }

    const rawStatus = typeof req.body.status === "string" ? req.body.status.trim().toUpperCase() : "";
    if (!VALID_STATUSES.includes(rawStatus as ReviewStatus)) {
      res.status(400).json({
        success: false,
        message: "status must be PUBLISHED or HIDDEN",
      });
      return;
    }
    const newStatus = rawStatus as ReviewStatus;

    const review = await prisma.review.findUnique({ where: { id: reviewId } });

    if (!review) {
      res.status(404).json({ success: false, message: "Review not found" });
      return;
    }

    if (review.status === newStatus) {
      res.status(400).json({
        success: false,
        message: `Review is already ${newStatus}`,
      });
      return;
    }

    const oldStatus = review.status;

    const updated = await prisma.review.update({
      where: { id: reviewId },
      data: {
        status: newStatus,
        updated_at: new Date(),
      },
      include: reviewInclude,
    });

    // --- audit log (fire-and-forget) ---
    createAuditLog({
      actorId: admin.id,
      actorRole: admin.role,
      action: "REVIEW_STATUS_CHANGE",
      entityType: "review",
      entityId: updated.id,
      beforeData: { status: oldStatus },
      afterData: { status: newStatus },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    // --- notify review owner when hidden (fire-and-forget) ---
    if (newStatus === "HIDDEN") {
      createNotification({
        userId: review.user_id.toString(),
        type: "REVIEW_HIDDEN",
        title: "Đánh giá bị ẩn",
        message: `Đánh giá của bạn cho ${review.target_type === "PRODUCT" ? "sản phẩm" : "sân"} đã bị ẩn bởi quản trị viên.`,
        data: { reviewId: review.id.toString(), targetType: review.target_type, targetId: review.target_id.toString() },
      });
    }

    res.json({
      success: true,
      message: `Review status changed to ${newStatus}`,
      data: {
        review: toReviewResponse(updated),
      },
    });
  } catch (error) {
    next(error);
  }
});
