import { Prisma } from "@prisma/client";
import { prisma } from "./prisma.js";

interface NotificationParams {
  userId: string | bigint;
  type: string;
  title: string;
  message: string;
  data?: Record<string, unknown> | null;
}

const toBigIntOrNull = (value: string | bigint) => {
  if (typeof value === "bigint") {
    return value;
  }

  return /^\d+$/.test(value) ? BigInt(value) : null;
};

export const createNotification = async (params: NotificationParams): Promise<void> => {
  try {
    const userId = toBigIntOrNull(params.userId);

    if (!userId) {
      return;
    }

    await prisma.notification.create({
      data: {
        user_id: userId,
        type: params.type.slice(0, 80),
        title: params.title.slice(0, 200),
        message: params.message.slice(0, 1000),
        data: params.data ? (params.data as Prisma.InputJsonValue) : Prisma.JsonNull,
      },
    });
  } catch (error) {
    console.error("[Notification] Failed to create notification:", error);
  }
};
