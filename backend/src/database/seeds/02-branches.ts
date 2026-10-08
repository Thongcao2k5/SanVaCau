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



const seedBranches = async () => {
  const branches = [
    {
      name: "SanVaCau Quận 1",
      address: "12 Nguyễn Trãi, Phường Bến Thành, Quận 1, TP.HCM",
      phone: "0901000001",
    },
    {
      name: "SanVaCau Thủ Đức",
      address: "45 Võ Văn Ngân, Phường Linh Chiểu, TP. Thủ Đức, TP.HCM",
      phone: "0901000002",
    },
    {
      name: "SanVaCau Bình Thạnh",
      address: "88 Xô Viết Nghệ Tĩnh, Phường 21, Bình Thạnh, TP.HCM",
      phone: "0901000003",
    },
  ];

  for (const branch of branches) {
    await upsertByNaturalKey(
      () => prisma.branch.findFirst({ where: { name: branch.name } }),
      () =>
        prisma.branch.create({
          data: {
            ...branch,
            opening_time: timeOfDay("06:00"),
            closing_time: timeOfDay("22:00"),
            status: "ACTIVE",
          },
        }),
      (existing) =>
        prisma.branch.update({
          where: { id: existing.id },
          data: {
            ...branch,
            opening_time: timeOfDay("06:00"),
            closing_time: timeOfDay("22:00"),
            status: "ACTIVE",
            updated_at: new Date(),
          },
        }),
    );
  }

  console.log("[seed] branches done");
};

export { seedBranches };
