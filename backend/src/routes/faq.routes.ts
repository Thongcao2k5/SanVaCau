import { Router, type Request, type Response, type NextFunction } from "express";
import { Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { createAuditLog } from "../lib/audit-log.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import type { faq_item } from "@prisma/client";

export const faqRouter = Router();

const FAQ_STATUSES = ["DRAFT", "PUBLISHED", "ARCHIVED"] as const;
type FaqStatus = (typeof FAQ_STATUSES)[number];

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

const toFaqResponse = (faq: faq_item) => ({
  id: faq.id.toString(),
  category: faq.category,
  question: faq.question,
  answer: faq.answer,
  status: faq.status,
  sortOrder: faq.sort_order,
  viewCount: faq.view_count,
  createdAt: faq.created_at.toISOString(),
  updatedAt: faq.updated_at.toISOString(),
  publishedAt: faq.published_at?.toISOString() ?? null,
  archivedAt: faq.archived_at?.toISOString() ?? null,
});

const toPublicFaqResponse = (faq: faq_item) => ({
  id: faq.id.toString(),
  category: faq.category,
  question: faq.question,
  answer: faq.answer,
  sortOrder: faq.sort_order,
  viewCount: faq.view_count,
  publishedAt: faq.published_at?.toISOString() ?? null,
});

const toAuditData = (faq: faq_item): Record<string, unknown> => ({
  id: faq.id.toString(),
  category: faq.category,
  question: faq.question,
  status: faq.status,
});

// ── Public endpoints ─────────────────────────────────────────────────────────

// GET /api/faqs
faqRouter.get("/", async (req: Request, res: Response, next: NextFunction) => {
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

    const category = req.query.category as string | undefined;
    const search = req.query.search as string | undefined;

    const where: Prisma.faq_itemWhereInput = {
      status: "PUBLISHED",
    };

    if (category) {
      where.category = category;
    }

    if (search) {
      where.OR = [
        { question: { contains: search, mode: "insensitive" } },
        { answer: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, faqs] = await Promise.all([
      prisma.faq_item.count({ where }),
      prisma.faq_item.findMany({
        where,
        orderBy: [
          { category: "asc" },
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
        faqs: faqs.map(toPublicFaqResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/faqs/categories
faqRouter.get("/categories", async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const categoriesCount = await prisma.faq_item.groupBy({
      by: ["category"],
      where: {
        status: "PUBLISHED",
      },
      _count: {
        id: true,
      },
      orderBy: {
        category: "asc",
      },
    });

    res.json({
      success: true,
      data: categoriesCount.map((c) => ({
        category: c.category,
        count: c._count.id,
      })),
    });
  } catch (error) {
    next(error);
  }
});

// ── Admin endpoints ──────────────────────────────────────────────────────────

const adminMiddleware = [requireAuth, requireRole("ADMIN")];

// GET /api/faqs/admin
faqRouter.get("/admin", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
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
    const category = req.query.category as string | undefined;
    const search = req.query.search as string | undefined;

    if (status && !FAQ_STATUSES.includes(status as FaqStatus)) {
      res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${FAQ_STATUSES.join(", ")}`,
      });
      return;
    }

    const where: Prisma.faq_itemWhereInput = {};

    if (status) where.status = status;
    if (category) where.category = category;

    if (search) {
      where.OR = [
        { question: { contains: search, mode: "insensitive" } },
        { answer: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, faqs] = await Promise.all([
      prisma.faq_item.count({ where }),
      prisma.faq_item.findMany({
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
        faqs: faqs.map(toFaqResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/faqs/:id
faqRouter.get("/:id", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Invalid id" });
      return;
    }

    const faq = await prisma.faq_item.findUnique({
      where: { id },
    });

    if (!faq || faq.status !== "PUBLISHED") {
      res.status(404).json({ success: false, message: "FAQ not found" });
      return;
    }

    const updatedFaq = await prisma.faq_item.update({
      where: { id },
      data: { view_count: { increment: 1 } },
    });

    res.json({
      success: true,
      data: toPublicFaqResponse(updatedFaq),
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/faqs
faqRouter.post("/", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { category, question, answer, status, sortOrder } = req.body as {
      category?: string;
      question?: string;
      answer?: string;
      status?: string;
      sortOrder?: number;
    };

    if (!category || typeof category !== "string" || category.trim().length === 0) {
      res.status(400).json({ success: false, message: "category is required" });
      return;
    }
    if (category.trim().length > 80) {
      res.status(400).json({ success: false, message: "category max 80 characters" });
      return;
    }

    if (!question || typeof question !== "string" || question.trim().length === 0) {
      res.status(400).json({ success: false, message: "question is required" });
      return;
    }
    if (question.trim().length > 250) {
      res.status(400).json({ success: false, message: "question max 250 characters" });
      return;
    }

    if (!answer || typeof answer !== "string" || answer.trim().length === 0) {
      res.status(400).json({ success: false, message: "answer is required" });
      return;
    }

    if (status && !FAQ_STATUSES.includes(status as FaqStatus)) {
      res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${FAQ_STATUSES.join(", ")}`,
      });
      return;
    }

    if (sortOrder !== undefined && (!Number.isInteger(sortOrder) || sortOrder < 0)) {
      res.status(400).json({ success: false, message: "sortOrder must be a non-negative integer" });
      return;
    }

    const resolvedStatus = (status as FaqStatus) || "DRAFT";
    const now = new Date();

    const created = await prisma.faq_item.create({
      data: {
        category: category.trim(),
        question: question.trim(),
        answer: answer.trim(),
        status: resolvedStatus,
        sort_order: sortOrder ?? 0,
        published_at: resolvedStatus === "PUBLISHED" ? now : null,
      },
    });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "FAQ_CREATED",
      entityType: "faq_item",
      entityId: created.id.toString(),
      afterData: toAuditData(created),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.status(201).json({
      success: true,
      data: toFaqResponse(created),
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/faqs/:id
faqRouter.patch("/:id", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Invalid id" });
      return;
    }

    const { category, question, answer, status, sortOrder } = req.body as {
      category?: string;
      question?: string;
      answer?: string;
      status?: string;
      sortOrder?: number;
    };

    if (category !== undefined) {
      if (typeof category !== "string" || category.trim().length === 0) {
        res.status(400).json({ success: false, message: "category must not be empty" });
        return;
      }
      if (category.trim().length > 80) {
        res.status(400).json({ success: false, message: "category max 80 characters" });
        return;
      }
    }

    if (question !== undefined) {
      if (typeof question !== "string" || question.trim().length === 0) {
        res.status(400).json({ success: false, message: "question must not be empty" });
        return;
      }
      if (question.trim().length > 250) {
        res.status(400).json({ success: false, message: "question max 250 characters" });
        return;
      }
    }

    if (answer !== undefined) {
      if (typeof answer !== "string" || answer.trim().length === 0) {
        res.status(400).json({ success: false, message: "answer must not be empty" });
        return;
      }
    }

    if (status !== undefined && !FAQ_STATUSES.includes(status as FaqStatus)) {
      res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${FAQ_STATUSES.join(", ")}`,
      });
      return;
    }

    if (sortOrder !== undefined && (!Number.isInteger(sortOrder) || sortOrder < 0)) {
      res.status(400).json({ success: false, message: "sortOrder must be a non-negative integer" });
      return;
    }

    const existing = await prisma.faq_item.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ success: false, message: "FAQ not found" });
      return;
    }

    const now = new Date();
    const updateData: Prisma.faq_itemUpdateInput = {
      updated_at: now,
    };

    if (category !== undefined) updateData.category = category.trim();
    if (question !== undefined) updateData.question = question.trim();
    if (answer !== undefined) updateData.answer = answer.trim();
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

    const updated = await prisma.faq_item.update({
      where: { id },
      data: updateData,
    });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "FAQ_UPDATED",
      entityType: "faq_item",
      entityId: id.toString(),
      beforeData: toAuditData(existing),
      afterData: toAuditData(updated),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.json({
      success: true,
      data: toFaqResponse(updated),
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/faqs/:id
faqRouter.delete("/:id", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Invalid id" });
      return;
    }

    const existing = await prisma.faq_item.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ success: false, message: "FAQ not found" });
      return;
    }

    await prisma.faq_item.delete({ where: { id } });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "FAQ_DELETED",
      entityType: "faq_item",
      entityId: id.toString(),
      beforeData: toAuditData(existing),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.json({
      success: true,
      message: "FAQ deleted",
    });
  } catch (error) {
    next(error);
  }
});
