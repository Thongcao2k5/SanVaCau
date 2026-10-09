import { Prisma, type PrismaClient } from '@prisma/client';

// Keep historical slots and bookings intact; new bookings use 30-minute slots.
export async function migrateHalfHourSlots(client: PrismaClient) {
  return client.$transaction(async tx => {
    const slots = await tx.time_slot.findMany({ where: { is_active: true }, orderBy: { start_time: 'asc' } });
    let sortOrder = (await tx.time_slot.aggregate({ _max: { sort_order: true } }))._max.sort_order ?? 0;
    let converted = 0;
    for (const source of slots) {
      const duration = source.end_time.getTime() - source.start_time.getTime();
      const halfHour = 30 * 60 * 1000;
      if (duration <= halfHour) continue;
      if (duration % halfHour !== 0) throw new Error('Time slots must be divisible into 30-minute intervals');
      const prices = await tx.court_price.findMany({ where: { time_slot_id: source.id } });
      for (let offset = 0; offset < duration; offset += halfHour) {
        const start = new Date(source.start_time.getTime() + offset);
        const end = new Date(start.getTime() + halfHour);
        const target = await tx.time_slot.upsert({ where: { start_time_end_time: { start_time: start, end_time: end } },
          update: { is_active: true }, create: { start_time: start, end_time: end, sort_order: ++sortOrder, is_active: true } });
        for (const price of prices) {
          await tx.court_price.upsert({ where: { court_id_time_slot_id: { court_id: price.court_id, time_slot_id: target.id } },
            update: {}, create: { court_id: price.court_id, time_slot_id: target.id,
              price: new Prisma.Decimal(price.price).div(duration / halfHour).toDecimalPlaces(2) } });
        }
      }
      await tx.time_slot.update({ where: { id: source.id }, data: { is_active: false } });
      converted++;
    }
    return converted;
  }, { timeout: 30000 });
}
