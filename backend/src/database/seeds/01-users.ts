import { PrismaClient, Prisma } from "@prisma/client";
import { hashPassword } from "../../lib/auth.js";
import { prisma } from "../../lib/prisma.js";

const timeOfDay = (hhmm: string) => new Date(`1970-01-01T${hhmm}:00.000Z`);

const upsertByNaturalKey = async <T>(
  find: () => Promise<T | null>,
  create: () => Promise<T>,
  update: (existing: T) => Promise<T>,
) => {
  const existing = await find();
  return existing ? update(existing) : create();
};



const seedAdmin = async () => {
  await prisma.app_user.upsert({
    where: { email: "admin@shopvacau.com" },
    update: {
      password_hash: await hashPassword("Admin123456"),
      full_name: "SanVaCau Admin",
      role: "ADMIN",
      status: "ACTIVE",
      branch_id: null,
      must_change_password: false,
      updated_at: new Date(),
    },
    create: {
      email: "admin@shopvacau.com",
      password_hash: await hashPassword("Admin123456"),
      full_name: "SanVaCau Admin",
      role: "ADMIN",
      status: "ACTIVE",
      must_change_password: false,
    },
  });
  console.log("[seed] admin account done");
};

export { seedAdmin };
