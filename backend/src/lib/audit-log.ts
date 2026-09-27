import { Prisma } from "@prisma/client";
import { prisma } from "./prisma.js";

interface AuditLogParams {
  actorId?: string | bigint | null;
  actorRole?: string | null;
  action: string;
  entityType: string;
  entityId?: bigint | string | null;
  beforeData?: Record<string, unknown> | null;
  afterData?: Record<string, unknown> | null;
  ipAddress?: string | null;
  userAgent?: string | null;
}

const toBigIntOrNull = (value: string | bigint | null | undefined) => {
  if (typeof value === "bigint") {
    return value;
  }

  if (typeof value === "string" && /^\d+$/.test(value)) {
    return BigInt(value);
  }

  return null;
};

const toJsonOrNull = (value: Record<string, unknown> | null | undefined) => {
  return value ? (value as Prisma.InputJsonValue) : Prisma.JsonNull;
};

/**
 * Ghi audit log vào database.
 * Hàm này KHÔNG BAO GIỜ throw lỗi ra ngoài — nếu ghi log thất bại
 * chỉ console.error, tránh ảnh hưởng API chính.
 */
export const createAuditLog = async (params: AuditLogParams): Promise<void> => {
  try {
    await prisma.audit_log.create({
      data: {
        actor_id: toBigIntOrNull(params.actorId),
        actor_role: params.actorRole ?? null,
        action: params.action.slice(0, 100),
        entity_type: params.entityType.slice(0, 100),
        entity_id: toBigIntOrNull(params.entityId),
        before_data: toJsonOrNull(params.beforeData),
        after_data: toJsonOrNull(params.afterData),
        ip_address: params.ipAddress ?? null,
        user_agent: params.userAgent?.slice(0, 500) ?? null,
      },
    });
  } catch (error) {
    console.error("[AuditLog] Failed to create audit log:", error);
  }
};
