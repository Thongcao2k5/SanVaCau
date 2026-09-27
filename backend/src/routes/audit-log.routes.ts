import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const auditLogRouter = Router();

const parseBigIntId = (value: unknown) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const parseDateParam = (value: unknown): Date | null => {
  if (typeof value !== "string" || !value.trim()) {
    return null;
  }

  const date = new Date(value.trim());

  return isNaN(date.getTime()) ? null : date;
};

interface AuditLogRow {
  id: bigint;
  actor_id: bigint | null;
  actor_role: string | null;
  action: string;
  entity_type: string;
  entity_id: bigint | null;
  before_data: unknown;
  after_data: unknown;
  ip_address: string | null;
  user_agent: string | null;
  created_at: Date;
  app_user: {
    id: bigint;
    full_name: string;
    email: string;
    role: string;
  } | null;
}

const toAuditLogResponse = (log: AuditLogRow) => {
  return {
    id: log.id.toString(),
    actorId: log.actor_id?.toString() ?? null,
    actorRole: log.actor_role,
    action: log.action,
    entityType: log.entity_type,
    entityId: log.entity_id?.toString() ?? null,
    beforeData: log.before_data,
    afterData: log.after_data,
    ipAddress: log.ip_address,
    userAgent: log.user_agent,
    createdAt: log.created_at.toISOString(),
    actor: log.app_user ? {
      id: log.app_user.id.toString(),
      fullName: log.app_user.full_name,
      email: log.app_user.email,
      role: log.app_user.role,
    } : null,
  };
};

// GET /api/audit-logs
auditLogRouter.get("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    // Pagination
    const pageRaw = typeof req.query.page === "string" ? parseInt(req.query.page, 10) : 1;
    const limitRaw = typeof req.query.limit === "string" ? parseInt(req.query.limit, 10) : 20;
    const page = Number.isFinite(pageRaw) && pageRaw > 0 ? pageRaw : 1;
    const limit = Number.isFinite(limitRaw) && limitRaw > 0 ? Math.min(limitRaw, 100) : 20;
    const skip = (page - 1) * limit;

    // Filters
    const actorId = req.query.actorId !== undefined ? parseBigIntId(req.query.actorId) : null;
    const entityId = req.query.entityId !== undefined ? parseBigIntId(req.query.entityId) : null;
    const action = typeof req.query.action === "string" ? req.query.action.trim() : null;
    const entityType = typeof req.query.entityType === "string" ? req.query.entityType.trim() : null;
    const from = req.query.from !== undefined ? parseDateParam(req.query.from) : null;
    const to = req.query.to !== undefined ? parseDateParam(req.query.to) : null;

    // Validate
    if (req.query.actorId !== undefined && !actorId) {
      res.status(400).json({ success: false, message: "invalid actorId" });
      return;
    }

    if (req.query.entityId !== undefined && !entityId) {
      res.status(400).json({ success: false, message: "invalid entityId" });
      return;
    }

    if (req.query.from !== undefined && !from) {
      res.status(400).json({ success: false, message: "invalid from date" });
      return;
    }

    if (req.query.to !== undefined && !to) {
      res.status(400).json({ success: false, message: "invalid to date" });
      return;
    }

    // Build where clause
    const where: {
      actor_id?: bigint;
      action?: string;
      entity_type?: string;
      entity_id?: bigint;
      created_at?: { gte?: Date; lte?: Date };
    } = {};

    if (actorId) where.actor_id = actorId;
    if (action) where.action = action;
    if (entityType) where.entity_type = entityType;
    if (entityId) where.entity_id = entityId;

    if (from || to) {
      where.created_at = {};
      if (from) where.created_at.gte = from;
      if (to) where.created_at.lte = to;
    }

    const [items, total] = await Promise.all([
      prisma.audit_log.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
        include: {
          app_user: {
            select: {
              id: true,
              full_name: true,
              email: true,
              role: true,
            },
          },
        },
      }),
      prisma.audit_log.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: {
        items: items.map(toAuditLogResponse),
        pagination: {
          page,
          limit,
          total,
          totalPages,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});
