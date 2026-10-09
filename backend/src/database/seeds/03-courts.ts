import { migrateHalfHourSlots } from '../../lib/half-hour-slots.js';
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
  await migrateHalfHourSlots(prisma);
  const slots = [];
  let sortOrder = (await prisma.time_slot.aggregate({ _max: { sort_order: true } }))._max.sort_order ?? 0;
  for (const [from, until] of [[6, 22]]) {
    for (let minute = from * 60; minute < until * 60; minute += 30) {
      const format = (value: number) => `${Math.floor(value / 60).toString().padStart(2, '0')}:${(value % 60).toString().padStart(2, '0')}`;
      const start = timeOfDay(format(minute));
      const end = timeOfDay(format(minute + 30));
      const slot = await prisma.time_slot.upsert({
        where: { start_time_end_time: { start_time: start, end_time: end } },
        update: { is_active: true },
        create: { start_time: start, end_time: end, sort_order: ++sortOrder, is_active: true },
      });
      slots.push(slot);
    }
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
        const price = hour < 12 ? "40000" : "60000";
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
