import { prisma } from '../src/lib/prisma.js';
import { migrateHalfHourSlots } from '../src/lib/half-hour-slots.js';

try {
  console.log(`Converted ${await migrateHalfHourSlots(prisma)} time slots to 30-minute intervals.`);
} finally {
  await prisma.$disconnect();
}
