import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { Prisma } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";

export const favoriteRouter = Router();

// ── helpers ────────────────────────────────────────────────

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const VALID_TARGET_TYPES = ["PRODUCT", "COURT"] as const;
type TargetType = (typeof VALID_TARGET_TYPES)[number];

const buildPagination = (page: number, limit: number, total: number) => ({
  page,
  limit,
  total,
  totalPages: Math.ceil(total / limit),
});

const parsePage = (value: unknown) => Math.max(1, parseInt(value as string) || 1);
const parseLimit = (value: unknown) => Math.min(100, Math.max(1, parseInt(value as string) || 20));

// ── A. POST /api/favorites ───────────────────────────────────

favoriteRouter.post("/", requireAuth, async (req, res, next) => {
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

    // --- business rule: verify target exists and active ---
    if (targetType === "PRODUCT") {
      const product = await prisma.product.findUnique({ where: { id: targetId } });
      if (!product) {
        res.status(404).json({ success: false, message: "Product not found" });
        return;
      }
      if (!product.is_active) {
        res.status(400).json({ success: false, message: "Cannot favorite an inactive product" });
        return;
      }
    } else {
      const court = await prisma.court.findUnique({ where: { id: targetId } });
      if (!court) {
        res.status(404).json({ success: false, message: "Court not found" });
        return;
      }
      if (court.status !== "ACTIVE") {
        res.status(400).json({ success: false, message: "Cannot favorite an inactive court" });
        return;
      }
    }

    // --- check duplicate ---
    const existing = await prisma.favorite.findUnique({
      where: {
        user_id_target_type_target_id: {
          user_id: userId,
          target_type: targetType,
          target_id: targetId,
        },
      },
    });

    if (existing) {
      res.status(200).json({
        success: true,
        message: "Item is already favorited",
        data: {
          favorite: {
            id: existing.id.toString(),
            userId: existing.user_id.toString(),
            targetType: existing.target_type,
            targetId: existing.target_id.toString(),
            createdAt: existing.created_at.toISOString(),
          }
        },
      });
      return;
    }

    // --- create favorite ---
    const favorite = await prisma.favorite.create({
      data: {
        user_id: userId,
        target_type: targetType,
        target_id: targetId,
      },
    });

    // --- audit log (fire-and-forget) ---
    createAuditLog({
      actorId: user.id,
      actorRole: user.role,
      action: "FAVORITE_CREATED",
      entityType: "favorite",
      entityId: favorite.id,
      afterData: { targetType, targetId: targetId.toString() },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    res.status(201).json({
      success: true,
      message: "Favorite added successfully",
      data: {
        favorite: {
          id: favorite.id.toString(),
          userId: favorite.user_id.toString(),
          targetType: favorite.target_type,
          targetId: favorite.target_id.toString(),
          createdAt: favorite.created_at.toISOString(),
        }
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── B. DELETE /api/favorites ─────────────────────────────────

favoriteRouter.delete("/", requireAuth, async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);

    // Accept targetType & targetId from body or query
    const requestBody = typeof req.body === "object" && req.body !== null ? req.body : {};
    const targetTypeRaw = "targetType" in requestBody ? requestBody.targetType : req.query.targetType;
    const targetIdRaw = "targetId" in requestBody ? requestBody.targetId : req.query.targetId;

    const targetType = typeof targetTypeRaw === "string" ? targetTypeRaw.trim().toUpperCase() : "";
    if (!VALID_TARGET_TYPES.includes(targetType as TargetType)) {
      res.status(400).json({
        success: false,
        message: "targetType must be PRODUCT or COURT",
      });
      return;
    }

    const targetId = parseBigIntId(targetIdRaw?.toString());
    if (!targetId) {
      res.status(400).json({
        success: false,
        message: "targetId must be a valid positive integer",
      });
      return;
    }

    const existing = await prisma.favorite.findUnique({
      where: {
        user_id_target_type_target_id: {
          user_id: userId,
          target_type: targetType as TargetType,
          target_id: targetId,
        },
      },
    });

    if (!existing) {
      res.status(200).json({
        success: true,
        message: "Favorite removed successfully (was not favorited)",
      });
      return;
    }

    await prisma.favorite.delete({
      where: { id: existing.id },
    });

    // --- audit log (fire-and-forget) ---
    createAuditLog({
      actorId: user.id,
      actorRole: user.role,
      action: "FAVORITE_REMOVED",
      entityType: "favorite",
      entityId: existing.id,
      beforeData: { targetType, targetId: targetId.toString() },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    res.status(200).json({
      success: true,
      message: "Favorite removed successfully",
    });
  } catch (error) {
    next(error);
  }
});

// ── C. GET /api/favorites ────────────────────────────────────

favoriteRouter.get("/", requireAuth, async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);

    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit);
    const skip = (page - 1) * limit;

    const where: Prisma.favoriteWhereInput = { user_id: userId };

    const targetTypeFilter = typeof req.query.targetType === "string" ? req.query.targetType.trim().toUpperCase() : undefined;
    if (targetTypeFilter && VALID_TARGET_TYPES.includes(targetTypeFilter as TargetType)) {
      where.target_type = targetTypeFilter;
    }

    const [items, total] = await Promise.all([
      prisma.favorite.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
      prisma.favorite.count({ where }),
    ]);

    // Gather targets
    const productIds = items.filter(i => i.target_type === "PRODUCT").map(i => i.target_id);
    const courtIds = items.filter(i => i.target_type === "COURT").map(i => i.target_id);

    const [products, courts] = await Promise.all([
      productIds.length > 0 ? prisma.product.findMany({
        where: { id: { in: productIds } },
        include: { category: true, brand: true }
      }) : Promise.resolve([]),
      courtIds.length > 0 ? prisma.court.findMany({
        where: { id: { in: courtIds } },
        include: { branch: true }
      }) : Promise.resolve([]),
    ]);

    const productMap = new Map(products.map(p => [p.id.toString(), p]));
    const courtMap = new Map(courts.map(c => [c.id.toString(), c]));

    const mappedItems = items.map(item => {
      let target = null;
      if (item.target_type === "PRODUCT") {
        const p = productMap.get(item.target_id.toString());
        if (p) {
          target = {
            id: p.id.toString(),
            name: p.name,
            imageUrl: p.image_url,
            isActive: p.is_active,
            category: p.category ? { id: p.category.id.toString(), name: p.category.name } : null,
            brand: p.brand ? { id: p.brand.id.toString(), name: p.brand.name } : null,
          };
        }
      } else {
        const c = courtMap.get(item.target_id.toString());
        if (c) {
          target = {
            id: c.id.toString(),
            name: c.name,
            status: c.status,
            branch: {
              id: c.branch.id.toString(),
              name: c.branch.name,
              address: c.branch.address,
            }
          };
        }
      }

      return {
        id: item.id.toString(),
        userId: item.user_id.toString(),
        targetType: item.target_type,
        targetId: item.target_id.toString(),
        createdAt: item.created_at.toISOString(),
        target
      };
    });

    res.json({
      success: true,
      data: {
        items: mappedItems,
        pagination: buildPagination(page, limit, Number(total)),
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── D. GET /api/favorites/check ───────────────────────────────

favoriteRouter.get("/check", requireAuth, async (req, res, next) => {
  try {
    const user = req.user!;
    const userId = BigInt(user.id);

    const targetType = typeof req.query.targetType === "string" ? req.query.targetType.trim().toUpperCase() : "";
    if (!VALID_TARGET_TYPES.includes(targetType as TargetType)) {
      res.status(400).json({
        success: false,
        message: "targetType must be PRODUCT or COURT",
      });
      return;
    }

    const targetId = parseBigIntId(req.query.targetId?.toString());
    if (!targetId) {
      res.status(400).json({
        success: false,
        message: "targetId must be a valid positive integer",
      });
      return;
    }

    const existing = await prisma.favorite.findUnique({
      where: {
        user_id_target_type_target_id: {
          user_id: userId,
          target_type: targetType as TargetType,
          target_id: targetId,
        },
      },
    });

    res.status(200).json({
      success: true,
      data: {
        isFavorited: !!existing,
        favorite: existing ? {
          id: existing.id.toString(),
          userId: existing.user_id.toString(),
          targetType: existing.target_type,
          targetId: existing.target_id.toString(),
          createdAt: existing.created_at.toISOString(),
        } : null,
      },
    });
  } catch (error) {
    next(error);
  }
});
