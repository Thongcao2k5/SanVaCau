import { describe, it, expect, beforeEach } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { prisma } from "../../src/lib/prisma.js";
import { migrateHalfHourSlots } from '../../src/lib/half-hour-slots.js';
import {
  createCustomer,
  createAdmin,
  createBranchManager,
  createBranch,
  createCourt,
  createTimeSlot,
  createCourtPrice,
} from "../helpers/fixtures.js";

describe("Booking Flow", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  const getNextDate = () => {
    const d = new Date();
    d.setDate(d.getDate() + 1);
    return d.toISOString().split("T")[0]; // YYYY-MM-DD
  };

  it('30-minute migration preserves old bookings, blocks overlaps, and allows 30 or 90 minutes', async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const hour1 = await createTimeSlot(6, 7);
    const hour2 = await createTimeSlot(7, 8);
    await createCourtPrice(court.id, hour1.id, 80000);
    await createCourtPrice(court.id, hour2.id, 80000);
    const { token } = await createCustomer();
    const date = getNextDate();
    const original = await request.post('/api/bookings').set('Authorization', `Bearer ${token}`).send({
      courtId: String(court.id), bookingDate: date, timeSlotIds: [String(hour1.id)],
    });
    expect(original.status).toBe(201);
    expect(await migrateHalfHourSlots(prisma)).toBe(2);
    expect(await migrateHalfHourSlots(prisma)).toBe(0);
    const availability = await request.get('/api/bookings/availability').query({ courtId: String(court.id), date });
    const slots = availability.body.data.slots;
    expect(slots.map((s: { startTime: string }) => s.startTime)).toEqual(['06:00:00', '06:30:00', '07:00:00', '07:30:00']);
    expect(slots.map((s: { price: string }) => s.price)).toEqual(['40000', '40000', '40000', '40000']);
    expect(slots.map((s: { isBooked: boolean }) => s.isBooked)).toEqual([true, true, false, false]);
    const history = await prisma.booking.findUnique({ where: { id: BigInt(original.body.data.id) }, include: { booking_slot: true } });
    expect(String(history!.total_amount)).toBe('80000');
    expect(history!.booking_slot[0].time_slot_id).toBe(hour1.id);
    const conflict = await request.post('/api/bookings/batch').set('Authorization', `Bearer ${token}`).send({
      bookingDate: date, courts: [{ courtId: String(court.id), timeSlotIds: [slots[1].timeSlotId] }],
    });
    expect(conflict.status).toBe(409);
    const singleConflict = await request.post('/api/bookings').set('Authorization', `Bearer ${token}`).send({
      bookingDate: date, courtId: String(court.id), timeSlotIds: [slots[0].timeSlotId],
    });
    expect(singleConflict.status).toBe(400);
    const half = await request.post('/api/bookings/batch').set('Authorization', `Bearer ${token}`).send({
      bookingDate: date, courts: [{ courtId: String(court.id), timeSlotIds: [slots[2].timeSlotId] }],
    });
    expect(half.status).toBe(201);
    expect(half.body.data.bookings[0].totalAmount).toBe('40000');
    const nextDate = new Date(`${date}T00:00:00Z`);
    nextDate.setUTCDate(nextDate.getUTCDate() + 1);
    const ninety = await request.post('/api/bookings/batch').set('Authorization', `Bearer ${token}`).send({
      bookingDate: nextDate.toISOString().slice(0, 10), courts: [{ courtId: String(court.id), timeSlotIds: slots.slice(0, 3).map((s: { timeSlotId: string }) => s.timeSlotId) }],
    });
    expect(ninety.status).toBe(201);
    expect(ninety.body.data.bookings[0].totalAmount).toBe('120000');
    expect(ninety.body.data.bookings[0].slots.at(-1).endTime).toBe('07:30:00');
  });

  it('Batch booking creates all courts with server-calculated totals', async () => {
    const branch = await createBranch();
    const court1 = await createCourt(branch.id);
    const court2 = await createCourt(branch.id);
    const slot1 = await createTimeSlot(8, 9);
    const slot2 = await createTimeSlot(9, 10);
    await createCourtPrice(court1.id, slot1.id, 100000);
    await createCourtPrice(court1.id, slot2.id, 120000);
    await createCourtPrice(court2.id, slot1.id, 150000);
    const { token } = await createCustomer();
    const res = await request.post('/api/bookings/batch').set('Authorization', `Bearer ${token}`).send({
      bookingDate: getNextDate(), paymentMethod: 'CASH', courts: [
        { courtId: String(court1.id), timeSlotIds: [String(slot1.id), String(slot2.id)] },
        { courtId: String(court2.id), timeSlotIds: [String(slot1.id)] },
      ],
    });
    expect(res.status).toBe(201);
    expect(res.body.data.bookings.map((b: { totalAmount: string }) => b.totalAmount)).toEqual(['220000', '150000']);
    expect(await prisma.booking.count()).toBe(2);
    expect(await prisma.booking_slot.count()).toBe(3);
  });

  it('Batch conflict on a later court rolls back earlier court booking', async () => {
    const branch = await createBranch();
    const court1 = await createCourt(branch.id);
    const court2 = await createCourt(branch.id);
    const slot = await createTimeSlot(8, 9);
    await createCourtPrice(court1.id, slot.id, 100000);
    await createCourtPrice(court2.id, slot.id, 150000);
    const { token } = await createCustomer();
    const date = getNextDate();
    await request.post('/api/bookings').set('Authorization', `Bearer ${token}`).send({
      courtId: String(court2.id), bookingDate: date, timeSlotIds: [String(slot.id)],
    });
    const res = await request.post('/api/bookings/batch').set('Authorization', `Bearer ${token}`).send({
      bookingDate: date, courts: [
        { courtId: String(court1.id), timeSlotIds: [String(slot.id)] },
        { courtId: String(court2.id), timeSlotIds: [String(slot.id)] },
      ],
    });
    expect(res.status).toBe(409);
    expect(await prisma.booking.count()).toBe(1);
    expect(await prisma.booking.count({ where: { court_id: court1.id } })).toBe(0);
    expect(await prisma.booking_slot.count()).toBe(1);
  });

  it('Batch rejects duplicate court or slot selections without creating bookings', async () => {
    const { token } = await createCustomer();
    for (const courts of [
      [{ courtId: '1', timeSlotIds: ['1'] }, { courtId: '1', timeSlotIds: ['2'] }],
      [{ courtId: '1', timeSlotIds: ['1', '1'] }],
    ]) {
      const res = await request.post('/api/bookings/batch').set('Authorization', `Bearer ${token}`).send({ bookingDate: getNextDate(), courts });
      expect(res.status).toBe(400);
    }
    expect(await prisma.booking.count()).toBe(0);
  });

  it("Customer successfully creates a booking for an active court and valid time slot, total is calculated correctly", async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const timeSlot = await createTimeSlot(8, 9);
    await createCourtPrice(court.id, timeSlot.id, 100000);
    const { token, user } = await createCustomer();

    const date = getNextDate();
    const res = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${token}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: date,
        timeSlotIds: [timeSlot.id.toString()],
        paymentMethod: "CASH",
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.totalAmount).toBe("100000"); // Calculated from server

    const dbBooking = await prisma.booking.findFirst({ where: { customer_id: user.id } });
    expect(dbBooking).toBeDefined();
    expect(dbBooking!.total_amount.toString()).toBe("100000");
  });

  it("Reject an invalid date", async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const timeSlot = await createTimeSlot(8, 9);
    await createCourtPrice(court.id, timeSlot.id, 100000);
    const { token } = await createCustomer();

    const res = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${token}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: "2026-02-31", // invalid date
        timeSlotIds: [timeSlot.id.toString()],
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("Reject booking an inactive court", async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    await prisma.court.update({ where: { id: court.id }, data: { status: "INACTIVE" } });
    const timeSlot = await createTimeSlot(8, 9);
    await createCourtPrice(court.id, timeSlot.id, 100000);
    const { token } = await createCustomer();

    const res = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${token}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: getNextDate(),
        timeSlotIds: [timeSlot.id.toString()],
      });

    expect(res.status).toBe(404);
  });

  it("Reject a time slot without a configured court price", async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const timeSlot = await createTimeSlot(8, 9);
    // Intentionally omitting createCourtPrice
    const { token } = await createCustomer();

    const res = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${token}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: getNextDate(),
        timeSlotIds: [timeSlot.id.toString()],
      });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/do not have a price/i);
  });

  it("Reject duplicate or overlapping booking, and do not create partial records", async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const timeSlot = await createTimeSlot(8, 9);
    await createCourtPrice(court.id, timeSlot.id, 100000);
    const { token: token1 } = await createCustomer();
    const { token: token2, user: user2 } = await createCustomer();

    const date = getNextDate();
    
    // First booking
    await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${token1}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: date,
        timeSlotIds: [timeSlot.id.toString()],
      });

    // Count before second attempt
    const beforeBookingsCount = await prisma.booking.count();
    const beforeSlotsCount = await prisma.booking_slot.count();

    // Second booking attempt on same slot
    const res = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${token2}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: date,
        timeSlotIds: [timeSlot.id.toString()],
      });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/already booked/i);

    // Verify no partial records
    const afterBookingsCount = await prisma.booking.count();
    const afterSlotsCount = await prisma.booking_slot.count();
    expect(afterBookingsCount).toBe(beforeBookingsCount);
    expect(afterSlotsCount).toBe(beforeSlotsCount);
    
    const user2Bookings = await prisma.booking.count({ where: { customer_id: user2.id } });
    expect(user2Bookings).toBe(0);
  });

  it("Customer can view their own booking but cannot view or cancel another customer's booking", async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const timeSlot = await createTimeSlot(8, 9);
    await createCourtPrice(court.id, timeSlot.id, 100000);
    
    const { token: token1 } = await createCustomer();
    const { token: token2 } = await createCustomer();

    const postRes = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${token1}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: getNextDate(),
        timeSlotIds: [timeSlot.id.toString()],
      });

    const bookingId = postRes.body.data.id;

    // View own bookings
    const myBookings = await request
      .get("/api/bookings/me")
      .set("Authorization", `Bearer ${token1}`);
    expect(myBookings.status).toBe(200);
    expect(myBookings.body.data.bookings.length).toBe(1);

    // Other customer trying to cancel
    const cancelRes = await request
      .patch(`/api/bookings/${bookingId}/cancel`)
      .set("Authorization", `Bearer ${token2}`);
    expect(cancelRes.status).toBe(403);
  });

  it("Customer can cancel only when the current status allows cancellation", async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const timeSlot = await createTimeSlot(8, 9);
    await createCourtPrice(court.id, timeSlot.id, 100000);
    const { token, user } = await createCustomer();

    const postRes = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${token}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: getNextDate(),
        timeSlotIds: [timeSlot.id.toString()],
      });

    const bookingId = postRes.body.data.id;

    // Change status to completed bypassing API
    await prisma.booking.update({ where: { id: BigInt(bookingId) }, data: { status: "COMPLETED" } });

    const cancelRes = await request
      .patch(`/api/bookings/${bookingId}/cancel`)
      .set("Authorization", `Bearer ${token}`);
    
    expect(cancelRes.status).toBe(400); // Cannot cancel COMPLETED

    // Reset status to BOOKED
    await prisma.booking.update({ where: { id: BigInt(bookingId) }, data: { status: "BOOKED" } });
    const cancelRes2 = await request
      .patch(`/api/bookings/${bookingId}/cancel`)
      .set("Authorization", `Bearer ${token}`);
    
    expect(cancelRes2.status).toBe(200);
    expect(cancelRes2.body.data.status).toBe("CANCELLED");
  });

  it("Branch manager can only access or update bookings belonging to their branch", async () => {
    const branch1 = await createBranch();
    const branch2 = await createBranch();
    const court1 = await createCourt(branch1.id);
    const court2 = await createCourt(branch2.id);
    
    const timeSlot = await createTimeSlot(8, 9);
    await createCourtPrice(court1.id, timeSlot.id, 100000);
    await createCourtPrice(court2.id, timeSlot.id, 100000);
    
    const { token: custToken } = await createCustomer();
    const { token: managerToken } = await createBranchManager(branch1.id);

    // Create booking in branch 1
    const b1Res = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${custToken}`)
      .send({
        courtId: court1.id.toString(),
        bookingDate: getNextDate(),
        timeSlotIds: [timeSlot.id.toString()],
      });
    const booking1Id = b1Res.body.data.id;

    // Create booking in branch 2
    const timeSlot2 = await createTimeSlot(9, 10);
    await createCourtPrice(court2.id, timeSlot2.id, 100000);

    const b2Res = await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${custToken}`)
      .send({
        courtId: court2.id.toString(),
        bookingDate: getNextDate(),
        timeSlotIds: [timeSlot2.id.toString()],
      });
    const booking2Id = b2Res.body.data.id;

    const listRes = await request
      .get("/api/bookings")
      .set("Authorization", `Bearer ${managerToken}`);
    
    expect(listRes.status).toBe(200);
    // Manager 1 should only see booking from branch 1
    expect(listRes.body.data.bookings.length).toBe(1);
    expect(listRes.body.data.bookings[0].id).toBe(booking1Id);

    // Try to update booking 2
    const updateRes = await request
      .patch(`/api/bookings/${booking2Id}/status`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ status: "CHECKED_IN" });
    
    expect(updateRes.status).toBe(403);
  });

  it("Admin can access the permitted booking management flow", async () => {
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const timeSlot = await createTimeSlot(8, 9);
    await createCourtPrice(court.id, timeSlot.id, 100000);
    
    const { token: custToken } = await createCustomer();
    const { token: adminToken } = await createAdmin();

    await request
      .post("/api/bookings")
      .set("Authorization", `Bearer ${custToken}`)
      .send({
        courtId: court.id.toString(),
        bookingDate: getNextDate(),
        timeSlotIds: [timeSlot.id.toString()],
      });

    const listRes = await request
      .get("/api/bookings")
      .set("Authorization", `Bearer ${adminToken}`);
    
    expect(listRes.status).toBe(200);
    expect(listRes.body.data.bookings.length).toBeGreaterThan(0);
  });
});
