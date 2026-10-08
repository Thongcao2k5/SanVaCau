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



const seedCourtsAndPrices = async () => {
  const branches = await prisma.branch.findMany({ where: { name: { startsWith: "SanVaCau" }, status: "ACTIVE" } });
  const slotValues = [
    ["06:00", "07:00"],
    ["07:00", "08:00"],
    ["08:00", "09:00"],
    ["17:00", "18:00"],
    ["18:00", "19:00"],
    ["19:00", "20:00"],
    ["20:00", "21:00"],
    ["21:00", "22:00"],
  ] as const;

  const slots = [];
  for (const [index, [start, end]] of slotValues.entries()) {
    const startTime = timeOfDay(start);
    const endTime = timeOfDay(end);
    const sortOrder = index + 1;
    const exactSlot = await prisma.time_slot.findFirst({
      where: { start_time: startTime, end_time: endTime },
    });
    const sortSlot = exactSlot ? null : await prisma.time_slot.findUnique({ where: { sort_order: sortOrder } });
    const slot =
      exactSlot ??
      (sortSlot
        ? await prisma.time_slot.update({
            where: { id: sortSlot.id },
            data: {
              start_time: startTime,
              end_time: endTime,
              is_active: true,
            },
          })
        : await prisma.time_slot.create({
            data: {
              start_time: startTime,
              end_time: endTime,
              sort_order: sortOrder,
              is_active: true,
            },
          }));

    if (!slot.is_active) {
      await prisma.time_slot.update({
        where: { id: slot.id },
        data: { is_active: true },
      });
    }
    slots.push(slot);
  }

  for (const branch of branches) {
    for (const courtName of ["Sân 1", "Sân 2", "Sân 3"]) {
      const court = await prisma.court.upsert({
        where: {
          branch_id_name: {
            branch_id: branch.id,
            name: courtName,
          },
        },
        update: {
          description: `${courtName} demo tại ${branch.name}`,
          status: "ACTIVE",
        },
        create: {
          branch_id: branch.id,
          name: courtName,
          description: `${courtName} demo tại ${branch.name}`,
          status: "ACTIVE",
        },
      });

      for (const slot of slots) {
        const hour = slot.start_time.getUTCHours();
        const price = hour < 12 ? "80000" : "120000";
        await prisma.court_price.upsert({
          where: {
            court_id_time_slot_id: {
              court_id: court.id,
              time_slot_id: slot.id,
            },
          },
          update: {
            price: new Prisma.Decimal(price),
          },
          create: {
            court_id: court.id,
            time_slot_id: slot.id,
            price: new Prisma.Decimal(price),
          },
        });
      }
    }
  }

  console.log("[seed] courts, time slots and prices done");
};

export { seedCourtsAndPrices };
