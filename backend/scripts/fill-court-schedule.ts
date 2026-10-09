import { Prisma } from '@prisma/client';
import { prisma } from '../src/lib/prisma.js';

try {
  const result = await prisma.$transaction(async tx => {
    const courts = await tx.court.findMany({ where: { status: 'ACTIVE', branch: { status: 'ACTIVE' } } });
    let sortOrder = (await tx.time_slot.aggregate({ _max: { sort_order: true } }))._max.sort_order ?? 0;
    let addedPrices = 0;
    for (let minute = 6 * 60; minute < 22 * 60; minute += 30) {
      const start = new Date(Date.UTC(1970, 0, 1, 0, minute));
      const end = new Date(Date.UTC(1970, 0, 1, 0, minute + 30));
      const slot = await tx.time_slot.upsert({ where: { start_time_end_time: { start_time: start, end_time: end } },
        update: { is_active: true }, create: { start_time: start, end_time: end, sort_order: ++sortOrder, is_active: true } });
      const created = await tx.court_price.createMany({ skipDuplicates: true, data: courts.map(court => ({
        court_id: court.id, time_slot_id: slot.id, price: new Prisma.Decimal(minute < 12 * 60 ? 40000 : 60000),
      })) });
      addedPrices += created.count;
    }
    return { courts: courts.length, addedPrices };
  });
  console.log(result);
} finally {
  await prisma.$disconnect();
}
