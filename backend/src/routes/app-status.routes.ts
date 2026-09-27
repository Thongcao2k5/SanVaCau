import { Router, type Request, type Response, type NextFunction } from "express";
import { prisma } from "../lib/prisma.js";
import { createAuditLog } from "../lib/audit-log.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const appStatusRouter = Router();

// ── Types ────────────────────────────────────────────────────────────────────

type PlatformConfig = {
  minimumSupportedVersion: string;
  latestVersion: string;
  storeUrl: string | null;
  forceUpdateMessage: string;
  optionalUpdateMessage: string;
};

type MaintenanceConfig = {
  enabled: boolean;
  message: string;
};

type AppStatusConfig = {
  maintenance: MaintenanceConfig;
  android: PlatformConfig;
  ios: PlatformConfig;
};

// ── Helpers ──────────────────────────────────────────────────────────────────

const SEMVER_REGEX = /^\d+\.\d+\.\d+$/;
const ALLOWED_PLATFORMS = ["android", "ios"] as const;
type Platform = (typeof ALLOWED_PLATFORMS)[number];

const isValidSemver = (v: string): boolean => SEMVER_REGEX.test(v);

/**
 * Compare two semantic version strings (x.y.z).
 * Returns -1 if a < b, 0 if a == b, 1 if a > b.
 */
const compareSemver = (a: string, b: string): -1 | 0 | 1 => {
  const pa = a.split(".").map(Number);
  const pb = b.split(".").map(Number);

  for (let i = 0; i < 3; i++) {
    if (pa[i] < pb[i]) return -1;
    if (pa[i] > pb[i]) return 1;
  }
  return 0;
};

const DEFAULT_CONFIG: AppStatusConfig = {
  maintenance: {
    enabled: false,
    message: "Hệ thống đang bảo trì, vui lòng quay lại sau.",
  },
  android: {
    minimumSupportedVersion: "1.0.0",
    latestVersion: "1.0.0",
    storeUrl: null,
    forceUpdateMessage: "Vui lòng cập nhật ứng dụng để tiếp tục.",
    optionalUpdateMessage: "Đã có phiên bản mới.",
  },
  ios: {
    minimumSupportedVersion: "1.0.0",
    latestVersion: "1.0.0",
    storeUrl: null,
    forceUpdateMessage: "Vui lòng cập nhật ứng dụng để tiếp tục.",
    optionalUpdateMessage: "Đã có phiên bản mới.",
  },
};

const isPlatformConfig = (obj: unknown): obj is PlatformConfig => {
  if (typeof obj !== "object" || obj === null) return false;
  const o = obj as Record<string, unknown>;
  return (
    typeof o.minimumSupportedVersion === "string" &&
    isValidSemver(o.minimumSupportedVersion) &&
    typeof o.latestVersion === "string" &&
    isValidSemver(o.latestVersion) &&
    (o.storeUrl === null || typeof o.storeUrl === "string") &&
    typeof o.forceUpdateMessage === "string" &&
    typeof o.optionalUpdateMessage === "string"
  );
};

const isMaintenanceConfig = (obj: unknown): obj is MaintenanceConfig => {
  if (typeof obj !== "object" || obj === null) return false;
  const o = obj as Record<string, unknown>;
  return typeof o.enabled === "boolean" && typeof o.message === "string";
};

const isAppStatusConfig = (obj: unknown): obj is AppStatusConfig => {
  if (typeof obj !== "object" || obj === null) return false;
  const o = obj as Record<string, unknown>;
  return isMaintenanceConfig(o.maintenance) && isPlatformConfig(o.android) && isPlatformConfig(o.ios);
};

const loadAppStatusConfig = async (): Promise<AppStatusConfig> => {
  const setting = await prisma.system_setting.findUnique({
    where: { key: "app_status" },
  });

  if (!setting) return DEFAULT_CONFIG;

  if (isAppStatusConfig(setting.value)) {
    return setting.value;
  }

  return DEFAULT_CONFIG;
};

const toAppStatusAuditData = (setting: { key: string; value: unknown }): Record<string, unknown> => ({
  key: setting.key,
  value: isAppStatusConfig(setting.value) ? setting.value : DEFAULT_CONFIG,
});

// ── GET /api/app-status (public) ─────────────────────────────────────────────

appStatusRouter.get("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const platform = req.query.platform as string | undefined;
    const version = req.query.version as string | undefined;

    if (!platform || !ALLOWED_PLATFORMS.includes(platform as Platform)) {
      res.status(400).json({
        success: false,
        message: "Invalid or missing platform. Allowed: android, ios",
      });
      return;
    }

    if (!version || !isValidSemver(version)) {
      res.status(400).json({
        success: false,
        message: "Invalid or missing version. Expected format: x.y.z",
      });
      return;
    }

    const config = await loadAppStatusConfig();
    const platformConfig = config[platform as Platform];

    const maintenanceMode = config.maintenance.enabled;
    const maintenanceMessage = config.maintenance.enabled ? config.maintenance.message : null;

    const updateRequired = compareSemver(version, platformConfig.minimumSupportedVersion) < 0;
    const updateAvailable =
      !updateRequired && compareSemver(version, platformConfig.latestVersion) < 0;

    let updateMessage: string | null = null;
    if (updateRequired) {
      updateMessage = platformConfig.forceUpdateMessage;
    } else if (updateAvailable) {
      updateMessage = platformConfig.optionalUpdateMessage;
    }

    res.json({
      success: true,
      data: {
        platform,
        currentVersion: version,
        latestVersion: platformConfig.latestVersion,
        minimumSupportedVersion: platformConfig.minimumSupportedVersion,
        maintenanceMode,
        maintenanceMessage,
        updateRequired,
        updateAvailable,
        updateMessage,
        storeUrl: platformConfig.storeUrl,
      },
    });
  } catch (error) {
    next(error);
  }
});

// ── PUT /api/app-status (admin) ──────────────────────────────────────────────

appStatusRouter.put(
  "/",
  requireAuth,
  requireRole("ADMIN"),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const body = req.body as unknown;

      if (!isAppStatusConfig(body)) {
        res.status(400).json({
          success: false,
          message:
            "Invalid config format. Required: maintenance (enabled: boolean, message: string), " +
            "android and ios (minimumSupportedVersion, latestVersion as x.y.z, storeUrl as string|null, " +
            "forceUpdateMessage, optionalUpdateMessage as strings).",
        });
        return;
      }

      // Validate latestVersion >= minimumSupportedVersion for each platform
      for (const p of ALLOWED_PLATFORMS) {
        const pc = body[p];
        if (compareSemver(pc.latestVersion, pc.minimumSupportedVersion) < 0) {
          res.status(400).json({
            success: false,
            message: `${p}: latestVersion must be >= minimumSupportedVersion`,
          });
          return;
        }
      }

      const existingSetting = await prisma.system_setting.findUnique({
        where: { key: "app_status" },
      });

      const setting = await prisma.system_setting.upsert({
        where: { key: "app_status" },
        update: {
          value: body,
          description: "Mobile app version and maintenance configuration",
          is_public: false,
          updated_at: new Date(),
        },
        create: {
          key: "app_status",
          value: body,
          description: "Mobile app version and maintenance configuration",
          is_public: false,
        },
      });

      void createAuditLog({
        actorId: req.user!.id,
        actorRole: req.user!.role,
        action: "APP_STATUS_UPDATED",
        entityType: "system_setting",
        entityId: null,
        beforeData: existingSetting ? toAppStatusAuditData(existingSetting) : null,
        afterData: toAppStatusAuditData(setting),
        ipAddress: req.ip ?? null,
        userAgent: req.get("user-agent") ?? null,
      });

      res.json({
        success: true,
        data: {
          key: setting.key,
          value: setting.value,
          description: setting.description,
          isPublic: setting.is_public,
          createdAt: setting.created_at.toISOString(),
          updatedAt: setting.updated_at.toISOString(),
        },
      });
    } catch (error) {
      next(error);
    }
  }
);
