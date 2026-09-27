import { Router } from "express";
import { Prisma, type system_setting } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const settingRouter = Router();

const isValidKey = (key: string) => /^[a-z0-9_.-]+$/i.test(key) && key.length <= 100;

const parsePositiveInt = (value: unknown) => {
  if (value === undefined) {
    return undefined;
  }

  if (typeof value !== "string" || !/^\d+$/.test(value)) {
    return null;
  }

  const parsed = Number(value);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : null;
};

const toSettingResponse = (setting: system_setting) => ({
  key: setting.key,
  value: setting.value,
  description: setting.description,
  isPublic: setting.is_public,
  createdAt: setting.created_at.toISOString(),
  updatedAt: setting.updated_at.toISOString(),
});

const toSettingAuditData = (setting: system_setting): Record<string, unknown> => ({
  key: setting.key,
  value: setting.value,
  description: setting.description,
  isPublic: setting.is_public,
  createdAt: setting.created_at.toISOString(),
  updatedAt: setting.updated_at.toISOString(),
});

settingRouter.get("/public", async (_req, res, next) => {
  try {
    const settings = await prisma.system_setting.findMany({
      where: { is_public: true },
      orderBy: { key: "asc" },
    });

    const data: Record<string, Prisma.JsonValue> = {};
    for (const setting of settings) {
      data[setting.key] = setting.value;
    }

    res.json({
      success: true,
      data,
    });
  } catch (error) {
    next(error);
  }
});

settingRouter.use(requireAuth, requireRole("ADMIN"));

settingRouter.get("/", async (req, res, next) => {
  try {
    const search = typeof req.query.search === "string" ? req.query.search.trim() : "";
    const pageInput = parsePositiveInt(req.query.page);
    const limitInput = parsePositiveInt(req.query.limit);

    if (pageInput === null) {
      return res.status(400).json({ success: false, message: "Invalid page" });
    }

    if (limitInput === null) {
      return res.status(400).json({ success: false, message: "Invalid limit" });
    }

    const page = pageInput ?? 1;
    const limit = Math.min(limitInput ?? 20, 100);

    const where: Prisma.system_settingWhereInput = search
      ? {
          OR: [
            { key: { contains: search, mode: "insensitive" } },
            { description: { contains: search, mode: "insensitive" } },
          ],
        }
      : {};

    const [total, settings] = await Promise.all([
      prisma.system_setting.count({ where }),
      prisma.system_setting.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { created_at: "desc" },
      }),
    ]);

    res.json({
      success: true,
      data: {
        total,
        page,
        limit,
        settings: settings.map(toSettingResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

settingRouter.get("/:key", async (req, res, next) => {
  try {
    const { key } = req.params;

    if (!isValidKey(key)) {
      return res.status(400).json({ success: false, message: "Invalid key format" });
    }

    const setting = await prisma.system_setting.findUnique({
      where: { key },
    });

    if (!setting) {
      return res.status(404).json({ success: false, message: "Setting not found" });
    }

    res.json({
      success: true,
      data: toSettingResponse(setting),
    });
  } catch (error) {
    next(error);
  }
});

settingRouter.put("/:key", async (req, res, next) => {
  try {
    const { key } = req.params;
    const value = req.body?.value as Prisma.InputJsonValue | undefined;
    const description = req.body?.description as unknown;
    const isPublic = req.body?.isPublic as unknown;

    if (!isValidKey(key)) {
      return res.status(400).json({ success: false, message: "Invalid key format" });
    }

    if (value === undefined) {
      return res.status(400).json({ success: false, message: "value is required" });
    }

    if (description !== undefined && description !== null && typeof description !== "string") {
      return res.status(400).json({ success: false, message: "description must be a string or null" });
    }

    if (typeof description === "string" && description.length > 500) {
      return res.status(400).json({ success: false, message: "description length max 500" });
    }

    if (isPublic !== undefined && typeof isPublic !== "boolean") {
      return res.status(400).json({ success: false, message: "isPublic must be a boolean" });
    }

    const existingSetting = await prisma.system_setting.findUnique({
      where: { key },
    });

    const updateData: Prisma.system_settingUpdateInput = {
      value,
      updated_at: new Date(),
      ...(description !== undefined ? { description } : {}),
      ...(isPublic !== undefined ? { is_public: isPublic } : {}),
    };

    const setting = await prisma.system_setting.upsert({
      where: { key },
      update: updateData,
      create: {
        key,
        value,
        description: description === undefined ? null : description,
        is_public: typeof isPublic === "boolean" ? isPublic : false,
      },
    });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "SYSTEM_SETTING_UPSERTED",
      entityType: "system_setting",
      entityId: null,
      beforeData: existingSetting ? toSettingAuditData(existingSetting) : null,
      afterData: toSettingAuditData(setting),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    res.json({
      success: true,
      data: toSettingResponse(setting),
    });
  } catch (error) {
    next(error);
  }
});

settingRouter.delete("/:key", async (req, res, next) => {
  try {
    const { key } = req.params;

    if (!isValidKey(key)) {
      return res.status(400).json({ success: false, message: "Invalid key format" });
    }

    const setting = await prisma.system_setting.findUnique({
      where: { key },
    });

    if (!setting) {
      return res.status(404).json({ success: false, message: "Setting not found" });
    }

    await prisma.system_setting.delete({
      where: { key },
    });

    void createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "SYSTEM_SETTING_DELETED",
      entityType: "system_setting",
      entityId: null,
      beforeData: toSettingAuditData(setting),
      afterData: null,
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    res.json({
      success: true,
      message: "Setting deleted",
    });
  } catch (error) {
    next(error);
  }
});
