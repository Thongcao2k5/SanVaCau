import { Router, type Request, type Response, type NextFunction } from "express";
import { Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { createAuditLog } from "../lib/audit-log.js";
import { optionalAuth, requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { publicWriteRateLimit } from "../middleware/rate-limit.middleware.js";
import type { contact_message } from "@prisma/client";

export const contactRouter = Router();

// ── Constants ────────────────────────────────────────────────────────────────

const CONTACT_TYPES = ["GENERAL", "BUG", "FEATURE_REQUEST", "COMPLAINT", "PARTNERSHIP"] as const;
const CONTACT_STATUSES = ["NEW", "READ", "IN_PROGRESS", "RESOLVED", "ARCHIVED"] as const;

type ContactType = (typeof CONTACT_TYPES)[number];
type ContactStatus = (typeof CONTACT_STATUSES)[number];

// ── Helpers ──────────────────────────────────────────────────────────────────

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

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

const toContactResponse = (msg: contact_message) => ({
  id: msg.id.toString(),
  userId: msg.user_id?.toString() ?? null,
  fullName: msg.full_name,
  email: msg.email,
  phone: msg.phone,
  type: msg.type,
  subject: msg.subject,
  message: msg.message,
  status: msg.status,
  adminNote: msg.admin_note,
  createdAt: msg.created_at.toISOString(),
  updatedAt: msg.updated_at.toISOString(),
  resolvedAt: msg.resolved_at?.toISOString() ?? null,
  archivedAt: msg.archived_at?.toISOString() ?? null,
});

const toAuditData = (msg: contact_message): Record<string, unknown> => ({
  id: msg.id.toString(),
  userId: msg.user_id?.toString() ?? null,
  fullName: msg.full_name,
  type: msg.type,
  subject: msg.subject,
  status: msg.status,
});

// ── POST /api/contact (public / optionalAuth) ────────────────────────────────

contactRouter.post("/", publicWriteRateLimit, optionalAuth, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { fullName, email, phone, type, subject, message } = req.body as {
      fullName?: string;
      email?: string;
      phone?: string;
      type?: string;
      subject?: string;
      message?: string;
    };

    // Validate type
    if (!type || !CONTACT_TYPES.includes(type as ContactType)) {
      res.status(400).json({
        success: false,
        message: `Invalid type. Allowed: ${CONTACT_TYPES.join(", ")}`,
      });
      return;
    }

    // Validate subject
    if (!subject || typeof subject !== "string" || subject.trim().length === 0) {
      res.status(400).json({ success: false, message: "subject is required" });
      return;
    }
    if (subject.trim().length > 200) {
      res.status(400).json({ success: false, message: "subject max 200 characters" });
      return;
    }

    // Validate message
    if (!message || typeof message !== "string" || message.trim().length === 0) {
      res.status(400).json({ success: false, message: "message is required" });
      return;
    }
    if (message.trim().length > 2000) {
      res.status(400).json({ success: false, message: "message max 2000 characters" });
      return;
    }

    // Validate email if provided
    if (email !== undefined && email !== null && email !== "") {
      if (typeof email !== "string" || !EMAIL_REGEX.test(email)) {
        res.status(400).json({ success: false, message: "Invalid email format" });
        return;
      }
      if (email.trim().length > 150) {
        res.status(400).json({ success: false, message: "email max 150 characters" });
        return;
      }
    }

    // Validate phone if provided
    if (phone !== undefined && phone !== null && phone !== "") {
      if (typeof phone !== "string" || phone.trim().length > 20) {
        res.status(400).json({ success: false, message: "phone max 20 characters" });
        return;
      }
    }

    // Resolve fullName and userId
    let resolvedFullName = fullName;
    let userId: bigint | null = null;

    if (req.user) {
      userId = BigInt(req.user.id);

      if (!resolvedFullName || resolvedFullName.trim().length === 0) {
        const user = await prisma.app_user.findUnique({
          where: { id: userId },
          select: { full_name: true },
        });
        resolvedFullName = user?.full_name ?? undefined;
      }
    }

    if (!resolvedFullName || typeof resolvedFullName !== "string" || resolvedFullName.trim().length === 0) {
      res.status(400).json({ success: false, message: "fullName is required" });
      return;
    }
    if (resolvedFullName.trim().length > 150) {
      res.status(400).json({ success: false, message: "fullName max 150 characters" });
      return;
    }

    const created = await prisma.contact_message.create({
      data: {
        user_id: userId,
        full_name: resolvedFullName.trim(),
        email: email?.trim() || null,
        phone: phone?.trim() || null,
        type,
        subject: subject.trim(),
        message: message.trim(),
        status: "NEW",
      },
    });

    void createAuditLog({
      actorId: req.user?.id ?? null,
      actorRole: req.user?.role ?? "GUEST",
      action: "CONTACT_MESSAGE_CREATED",
      entityType: "contact_message",
      entityId: created.id.toString(),
      afterData: toAuditData(created),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.status(201).json({
      success: true,
      data: toContactResponse(created),
    });
  } catch (error) {
    next(error);
  }
});

// ── Admin endpoints ──────────────────────────────────────────────────────────

const adminMiddleware = [requireAuth, requireRole("ADMIN")];

// GET /api/contact
contactRouter.get("/", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
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
    const includeArchived = req.query.includeArchived === "true";

    // Validate status enum if provided
    if (status && !CONTACT_STATUSES.includes(status as ContactStatus)) {
      res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${CONTACT_STATUSES.join(", ")}`,
      });
      return;
    }

    // Validate type enum if provided
    if (type && !CONTACT_TYPES.includes(type as ContactType)) {
      res.status(400).json({
        success: false,
        message: `Invalid type. Allowed: ${CONTACT_TYPES.join(", ")}`,
      });
      return;
    }

    const where: Prisma.contact_messageWhereInput = {};

    if (status) where.status = status;
    if (type) where.type = type;

    if (!includeArchived) {
      where.archived_at = null;
    }

    if (search) {
      where.OR = [
        { subject: { contains: search, mode: "insensitive" } },
        { message: { contains: search, mode: "insensitive" } },
        { full_name: { contains: search, mode: "insensitive" } },
        { email: { contains: search, mode: "insensitive" } },
        { phone: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, messages] = await Promise.all([
      prisma.contact_message.count({ where }),
      prisma.contact_message.findMany({
        where,
        orderBy: { created_at: "desc" },
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
        messages: messages.map(toContactResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/contact/:id
contactRouter.get("/:id", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Invalid id" });
      return;
    }

    const msg = await prisma.contact_message.findUnique({ where: { id } });
    if (!msg) {
      res.status(404).json({ success: false, message: "Contact message not found" });
      return;
    }

    res.json({ success: true, data: toContactResponse(msg) });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/contact/:id/status
contactRouter.patch("/:id/status", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Invalid id" });
      return;
    }

    const { status, adminNote } = req.body as { status?: string; adminNote?: string | null };

    if (!status || !CONTACT_STATUSES.includes(status as ContactStatus)) {
      res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${CONTACT_STATUSES.join(", ")}`,
      });
      return;
    }

    if (adminNote !== undefined && adminNote !== null) {
      if (typeof adminNote !== "string") {
        res.status(400).json({ success: false, message: "adminNote must be a string or null" });
        return;
      }
      if (adminNote.trim().length > 1000) {
        res.status(400).json({ success: false, message: "adminNote max 1000 characters" });
        return;
      }
    }

    const existing = await prisma.contact_message.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ success: false, message: "Contact message not found" });
      return;
    }

    const now = new Date();
    const updateData: Prisma.contact_messageUpdateInput = {
      status,
      updated_at: now,
    };

    if (adminNote !== undefined) {
      updateData.admin_note = adminNote;
    }

    if (status === "RESOLVED" && !existing.resolved_at) {
      updateData.resolved_at = now;
    }

    if (status === "ARCHIVED") {
      updateData.archived_at = now;
    }

    const updated = await prisma.contact_message.update({
      where: { id },
      data: updateData,
    });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "CONTACT_MESSAGE_STATUS_UPDATED",
      entityType: "contact_message",
      entityId: id.toString(),
      beforeData: toAuditData(existing),
      afterData: toAuditData(updated),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.json({ success: true, data: toContactResponse(updated) });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/contact/:id
contactRouter.delete("/:id", ...adminMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Invalid id" });
      return;
    }

    const existing = await prisma.contact_message.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ success: false, message: "Contact message not found" });
      return;
    }

    await prisma.contact_message.delete({ where: { id } });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "CONTACT_MESSAGE_DELETED",
      entityType: "contact_message",
      entityId: id.toString(),
      beforeData: toAuditData(existing),
      ipAddress: req.ip ?? null,
      userAgent: req.get("user-agent") ?? null,
    });

    res.json({ success: true, message: "Contact message deleted" });
  } catch (error) {
    next(error);
  }
});
