import { Router, type Request, type Response, type NextFunction } from "express";
import { Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { createAuditLog } from "../lib/audit-log.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import type { static_page } from "@prisma/client";

export const staticPageRouter = Router();

const PAGE_STATUSES = ["DRAFT", "PUBLISHED", "ARCHIVED"] as const;
type PageStatus = (typeof PAGE_STATUSES)[number];

const PAGE_TYPES = [
  "TERMS",
  "PRIVACY",
  "RETURN_POLICY",
  "PAYMENT_GUIDE",
  "BOOKING_GUIDE",
  "WARRANTY",
  "ABOUT",
  "OTHER",
] as const;
type PageType = (typeof PAGE_TYPES)[number];

const parseBigIntId = (value: unknown): bigint | null => {
  if (typeof value !== "string" || !/^\d+$/.test(value)) return null;
  return BigInt(value);
};

const parseOptionalPositiveInt = (value: unknown): number | null | undefined => {
  if (value === undefined) return undefined;
  if (typeof value !== "string" || !/^\d+$/.test(value)) return null;

  const n = Number(value);
  return Number.isSafeInteger(n) && n > 0 ? n : null;
};

const SLUG_REGEX = /^[a-z0-9-]+$/;

const toPageResponse = (page: static_page) => ({
  id: page.id.toString(),
  slug: page.slug,
  title: page.title,
  summary: page.summary,
  content: page.content,
  type: page.type,
  status: page.status,
  sortOrder: page.sort_order,
  createdAt: page.created_at.toISOString(),
  updatedAt: page.updated_at.toISOString(),
  publishedAt: page.published_at?.toISOString() ?? null,
  archivedAt: page.archived_at?.toISOString() ?? null,
});

const toPublicListResponse = (page: static_page) => ({
  id: page.id.toString(),
  slug: page.slug,
  title: page.title,
  summary: page.summary,
  type: page.type,
  sortOrder: page.sort_order,
  publishedAt: page.published_at?.toISOString() ?? null,
});

const toPublicDetailResponse = (page: static_page) => ({
  id: page.id.toString(),
  slug: page.slug,
  title: page.title,
  summary: page.summary,
  content: page.content,
  type: page.type,
  sortOrder: page.sort_order,
  publishedAt: page.published_at?.toISOString() ?? null,
});

const toAuditData = (page: static_page): Record<string, unknown> => ({
  id: page.id.toString(),
  slug: page.slug,
  title: page.title,
  type: page.type,
  status: page.status,
});

// ── Public endpoints ─────────────────────────────────────────────────────────

// GET /api/pages
staticPageRouter.get("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const pageInput = parseOptionalPositiveInt(req.query.page);
    const limitInput = parseOptionalPositiveInt(req.query.limit);

    if (pageInput === null) {
      res.status(400).json({ success: false, message: "Invalid page" });
      return;
    }
    if (limitInput === null) {
      res.status(400).json({ success: false, message: "Invalid limit" });
      return;
    }

    const page = pageInput ?? 1;
    const limit = Math.min(limitInput ?? 20, 100);

    const type = req.query.type as string | undefined;
    const search = req.query.search as string | undefined;

    const where: Prisma.static_pageWhereInput = {
      status: "PUBLISHED",
    };

    if (type) {
      where.type = type;
    }

    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { summary: { contains: search, mode: "insensitive" } },
        { content: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, pages] = await Promise.all([
      prisma.static_page.count({ where }),
      prisma.static_page.findMany({
        where,
        orderBy: [
          { sort_order: "asc" },
          { published_at: "desc" },
        ],
        skip: (page - 1) * limit,
        take: limit,
      }),
    ]);

    res.json({
      success: true,
      data: {
        total,
        page,
        limit,
        pages: pages.map(toPublicListResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── Admin endpoints ──────────────────────────────────────────────────────────

const adminMiddleware = [requireAuth, requireRole("ADMIN")];

// GET /api/pages/admin
staticPageRouter.get("/admin", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const pageInput = parseOptionalPositiveInt(req.query.page);
    const limitInput = parseOptionalPositiveInt(req.query.limit);

    if (pageInput === null) {
      res.status(400).json({ success: false, message: "Invalid page" });
      return;
    }
    if (limitInput === null) {
      res.status(400).json({ success: false, message: "Invalid limit" });
      return;
    }

    const page = pageInput ?? 1;
    const limit = Math.min(limitInput ?? 20, 100);

    const status = req.query.status as string | undefined;
    const type = req.query.type as string | undefined;
    const search = req.query.search as string | undefined;

    if (status && !PAGE_STATUSES.includes(status as PageStatus)) {
      res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${PAGE_STATUSES.join(", ")}`,
      });
      return;
    }

    const where: Prisma.static_pageWhereInput = {};

    if (status) where.status = status;
    if (type) where.type = type;

    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { summary: { contains: search, mode: "insensitive" } },
        { content: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, pages] = await Promise.all([
      prisma.static_page.count({ where }),
      prisma.static_page.findMany({
        where,
        orderBy: [{ created_at: "desc" }],
        skip: (page - 1) * limit,
        take: limit,
      }),
    ]);

    res.json({
      success: true,
      data: {
        total,
        page,
        limit,
        pages: pages.map(toPageResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/pages/:slug
staticPageRouter.get("/:slug", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const slug = req.params.slug as string;
    
    if (slug === "admin") {
      next();
      return;
    }

    const page = await prisma.static_page.findUnique({
      where: { slug },
    });

    if (!page || page.status !== "PUBLISHED") {
      res.status(404).json({ success: false, message: "Page not found" });
      return;
    }

    res.json({
      success: true,
      data: toPublicDetailResponse(page),
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/pages
staticPageRouter.post("/", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { slug, title, summary, content, type, status, sortOrder } = req.body as {
      slug?: string;
      title?: string;
      summary?: string | null;
      content?: string;
      type?: string;
      status?: string;
      sortOrder?: number;
    };

    if (!slug || typeof slug !== "string" || !SLUG_REGEX.test(slug) || slug.length > 120) {
      res.status(400).json({ success: false, message: "slug is required, max 120 chars, and must contain only lowercase letters, numbers, and hyphens" });
      return;
    }

    if (!title || typeof title !== "string" || title.trim().length === 0 || title.trim().length > 250) {
      res.status(400).json({ success: false, message: "title is required and max 250 characters" });
      return;
    }

    if (summary !== undefined && summary !== null) {
      if (typeof summary !== "string" || summary.length > 500) {
        res.status(400).json({ success: false, message: "summary max 500 characters" });
        return;
      }
    }

    if (!content || typeof content !== "string" || content.trim().length === 0) {
      res.status(400).json({ success: false, message: "content is required" });
      return;
    }

    if (!type || !PAGE_TYPES.includes(type as PageType)) {
      res.status(400).json({ success: false, message: `Invalid type. Allowed: ${PAGE_TYPES.join(", ")}` });
      return;
    }

    if (status && !PAGE_STATUSES.includes(status as PageStatus)) {
      res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${PAGE_STATUSES.join(", ")}`,
      });
      return;
    }

    if (sortOrder !== undefined && (!Number.isInteger(sortOrder) || sortOrder < 0)) {
      res.status(400).json({ success: false, message: "sortOrder must be a non-negative integer" });
      return;
    }

    const existingPage = await prisma.static_page.findUnique({ where: { slug } });
    if (existingPage) {
      res.status(409).json({ success: false, message: "Slug already exists" });
      return;
    }

    const resolvedStatus = (status as PageStatus) || "DRAFT";
    const now = new Date();

    const created = await prisma.static_page.create({
      data: {
        slug,
        title: title.trim(),
        summary: summary || null,
        content: content.trim(),
        type: type as PageType,
        status: resolvedStatus,
        sort_order: sortOrder ?? 0,
        published_at: resolvedStatus === "PUBLISHED" ? now : null,
      },
    });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "STATIC_PAGE_CREATED",
      entityType: "static_page",
      entityId: created.id.toString(),
      afterData: toAuditData(created),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.status(201).json({
      success: true,
      data: toPageResponse(created),
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/pages/:id
staticPageRouter.patch("/:id", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Invalid id" });
      return;
    }

    const { slug, title, summary, content, type, status, sortOrder } = req.body as {
      slug?: string;
      title?: string;
      summary?: string | null;
      content?: string;
      type?: string;
      status?: string;
      sortOrder?: number;
    };

    if (slug !== undefined) {
      if (typeof slug !== "string" || !SLUG_REGEX.test(slug) || slug.length > 120) {
        res.status(400).json({ success: false, message: "slug max 120 chars, and must contain only lowercase letters, numbers, and hyphens" });
        return;
      }
    }

    if (title !== undefined) {
      if (typeof title !== "string" || title.trim().length === 0 || title.trim().length > 250) {
        res.status(400).json({ success: false, message: "title is required and max 250 characters" });
        return;
      }
    }

    if (summary !== undefined) {
      if (summary !== null && (typeof summary !== "string" || summary.length > 500)) {
        res.status(400).json({ success: false, message: "summary max 500 characters" });
        return;
      }
    }

    if (content !== undefined) {
      if (typeof content !== "string" || content.trim().length === 0) {
        res.status(400).json({ success: false, message: "content must not be empty" });
        return;
      }
    }

    if (type !== undefined && !PAGE_TYPES.includes(type as PageType)) {
      res.status(400).json({ success: false, message: `Invalid type. Allowed: ${PAGE_TYPES.join(", ")}` });
      return;
    }

    if (status !== undefined && !PAGE_STATUSES.includes(status as PageStatus)) {
      res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${PAGE_STATUSES.join(", ")}`,
      });
      return;
    }

    if (sortOrder !== undefined && (!Number.isInteger(sortOrder) || sortOrder < 0)) {
      res.status(400).json({ success: false, message: "sortOrder must be a non-negative integer" });
      return;
    }

    const existing = await prisma.static_page.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ success: false, message: "Page not found" });
      return;
    }

    if (slug !== undefined && slug !== existing.slug) {
      const slugConflict = await prisma.static_page.findUnique({ where: { slug } });
      if (slugConflict) {
        res.status(409).json({ success: false, message: "Slug already exists" });
        return;
      }
    }

    const now = new Date();
    const updateData: Prisma.static_pageUpdateInput = {
      updated_at: now,
    };

    if (slug !== undefined) updateData.slug = slug;
    if (title !== undefined) updateData.title = title.trim();
    if (summary !== undefined) updateData.summary = summary;
    if (content !== undefined) updateData.content = content.trim();
    if (type !== undefined) updateData.type = type;
    if (sortOrder !== undefined) updateData.sort_order = sortOrder;

    if (status !== undefined && status !== existing.status) {
      updateData.status = status;
      if (status === "PUBLISHED" && !existing.published_at) {
        updateData.published_at = now;
      }
      if (status === "ARCHIVED") {
        updateData.archived_at = now;
      }
    }

    const updated = await prisma.static_page.update({
      where: { id },
      data: updateData,
    });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "STATIC_PAGE_UPDATED",
      entityType: "static_page",
      entityId: id.toString(),
      beforeData: toAuditData(existing),
      afterData: toAuditData(updated),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.json({
      success: true,
      data: toPageResponse(updated),
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/pages/:id
staticPageRouter.delete("/:id", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Invalid id" });
      return;
    }

    const existing = await prisma.static_page.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ success: false, message: "Page not found" });
      return;
    }

    await prisma.static_page.delete({ where: { id } });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "STATIC_PAGE_DELETED",
      entityType: "static_page",
      entityId: id.toString(),
      beforeData: toAuditData(existing),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.json({
      success: true,
      message: "Page deleted",
    });
  } catch (error) {
    next(error);
  }
});
