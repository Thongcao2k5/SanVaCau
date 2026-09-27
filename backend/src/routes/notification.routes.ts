import { Router } from "express";
import { Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const notificationRouter = Router();

const parsePositiveInt = (value: unknown, fallback: number, max?: number) => {
  const parsed = typeof value === "string" ? Number.parseInt(value, 10) : fallback;
  const normalized = Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;

  return max ? Math.min(normalized, max) : normalized;
};

const parseBigIntId = (value: unknown) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

type NotificationRow = Prisma.notificationGetPayload<Record<string, never>>;

const toNotificationResponse = (notification: NotificationRow) => ({
  id: notification.id.toString(),
  userId: notification.user_id.toString(),
  type: notification.type,
  title: notification.title,
  message: notification.message,
  data: notification.data,
  isRead: notification.read_at !== null,
  readAt: notification.read_at?.toISOString() ?? null,
  createdAt: notification.created_at.toISOString(),
});

// GET /api/notifications
notificationRouter.get("/", requireAuth, async (req, res, next) => {
  try {
    const page = parsePositiveInt(req.query.page, 1);
    const limit = parsePositiveInt(req.query.limit, 20, 100);
    const type = typeof req.query.type === "string" ? req.query.type.trim() : null;
    const isReadRaw = typeof req.query.isRead === "string" ? req.query.isRead : null;

    if (isReadRaw !== null && isReadRaw !== "true" && isReadRaw !== "false") {
      res.status(400).json({ success: false, message: "isRead must be true or false" });
      return;
    }

    const where: Prisma.notificationWhereInput = {
      user_id: BigInt(req.user!.id),
      ...(type ? { type } : {}),
      ...(isReadRaw === "true" ? { read_at: { not: null } } : {}),
      ...(isReadRaw === "false" ? { read_at: null } : {}),
    };

    const [items, total] = await Promise.all([
      prisma.notification.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.notification.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        items: items.map(toNotificationResponse),
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/notifications/unread-count
notificationRouter.get("/unread-count", requireAuth, async (req, res, next) => {
  try {
    const count = await prisma.notification.count({
      where: {
        user_id: BigInt(req.user!.id),
        read_at: null,
      },
    });

    res.json({
      success: true,
      data: { count },
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/notifications/read-all
notificationRouter.patch("/read-all", requireAuth, async (req, res, next) => {
  try {
    const result = await prisma.notification.updateMany({
      where: {
        user_id: BigInt(req.user!.id),
        read_at: null,
      },
      data: {
        read_at: new Date(),
      },
    });

    res.json({
      success: true,
      message: "All notifications marked as read",
      data: {
        updatedCount: result.count,
      },
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/notifications/:id/read
notificationRouter.patch("/:id/read", requireAuth, async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({ success: false, message: "invalid notification id" });
      return;
    }

    const notification = await prisma.notification.findFirst({
      where: {
        id,
        user_id: BigInt(req.user!.id),
      },
    });

    if (!notification) {
      res.status(404).json({ success: false, message: "notification not found" });
      return;
    }

    const updatedNotification = notification.read_at
      ? notification
      : await prisma.notification.update({
          where: { id },
          data: { read_at: new Date() },
        });

    res.json({
      success: true,
      message: "Notification marked as read",
      data: {
        notification: toNotificationResponse(updatedNotification),
      },
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/notifications/admin
notificationRouter.post("/admin", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const userId = parseBigIntId(req.body?.userId);
    const type = typeof req.body?.type === "string" ? req.body.type.trim() : "";
    const title = typeof req.body?.title === "string" ? req.body.title.trim() : "";
    const message = typeof req.body?.message === "string" ? req.body.message.trim() : "";
    const data = req.body?.data;

    if (!userId || !type || !title || !message) {
      res.status(400).json({
        success: false,
        message: "userId, type, title, and message are required",
      });
      return;
    }

    if (typeof data !== "undefined" && (data === null || Array.isArray(data) || typeof data !== "object")) {
      res.status(400).json({ success: false, message: "data must be an object" });
      return;
    }

    const user = await prisma.app_user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!user) {
      res.status(404).json({ success: false, message: "user not found" });
      return;
    }

    const notification = await prisma.notification.create({
      data: {
        user_id: userId,
        type: type.slice(0, 80),
        title: title.slice(0, 200),
        message: message.slice(0, 1000),
        data: data ? (data as Prisma.InputJsonValue) : Prisma.JsonNull,
      },
    });

    res.status(201).json({
      success: true,
      message: "Notification created successfully",
      data: {
        notification: toNotificationResponse(notification),
      },
    });
  } catch (error) {
    next(error);
  }
});
