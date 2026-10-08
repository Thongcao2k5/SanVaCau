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



const seedRacketServices = async () => {
  const services = [
    {
      name: "Căng dây vợt",
      description: "Căng dây theo mức cân và loại dây khách hàng yêu cầu.",
      referencePrice: "120000",
      estimatedDuration: "30 - 45 phút",
    },
    {
      name: "Thay quấn cán",
      description: "Tháo lớp quấn cũ, vệ sinh cán và thay quấn cán mới.",
      referencePrice: "50000",
      estimatedDuration: "15 - 20 phút",
    },
    {
      name: "Kiểm tra và sửa khung vợt",
      description: "Kiểm tra khung, gen và tư vấn phương án sửa phù hợp.",
      referencePrice: "100000",
      estimatedDuration: "1 - 2 ngày",
    },
  ];

  const branches = await prisma.branch.findMany({
    where: { name: { startsWith: "SanVaCau" }, status: "ACTIVE" },
  });

  for (const item of services) {
    const service = await upsertByNaturalKey(
      () => prisma.racket_service.findFirst({ where: { name: item.name } }),
      () =>
        prisma.racket_service.create({
          data: {
            name: item.name,
            description: item.description,
            is_active: true,
          },
        }),
      (existing) =>
        prisma.racket_service.update({
          where: { id: existing.id },
          data: {
            description: item.description,
            is_active: true,
          },
        }),
    );

    for (const branch of branches) {
      await prisma.branch_service.upsert({
        where: {
          branch_id_service_id: {
            branch_id: branch.id,
            service_id: service.id,
          },
        },
        update: {
          reference_price: new Prisma.Decimal(item.referencePrice),
          description: item.description,
          estimated_duration: item.estimatedDuration,
          is_available: true,
        },
        create: {
          branch_id: branch.id,
          service_id: service.id,
          reference_price: new Prisma.Decimal(item.referencePrice),
          description: item.description,
          estimated_duration: item.estimatedDuration,
          is_available: true,
        },
      });
    }
  }

  console.log("[seed] racket services done");
};

export { seedRacketServices };
