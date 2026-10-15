import { beforeEach, expect, it } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { createAdmin, createBranch, createBranchManager, createCourt, createCustomer } from "../helpers/fixtures.js";
import { prisma } from "../../src/lib/prisma.js";

beforeEach(clearDatabase);

const setupBooking = async () => {
  const customer = await createCustomer();
  const admin = await createAdmin();
  const branch = await createBranch();
  const court = await createCourt(branch.id);
  const booking = await prisma.booking.create({ data: {
    customer_id: customer.user.id, court_id: court.id, booking_date: new Date("2026-12-01"),
    total_amount: 120000, payment_method: "CASH",
  } });
  return { customer, admin, booking };
};

it("checks in unpaid, blocks completion, collects cash exactly once, then completes", async () => {
  const { admin, booking } = await setupBooking();
  const auth = `Bearer ${admin.token}`;
  const statusUrl = `/api/bookings/${booking.id}/status`;
  const checkedIn = await request.patch(statusUrl).set("Authorization", auth).send({ status: "CHECKED_IN" });
  expect(checkedIn.body.data.paymentStatus).toBe("UNPAID");
  expect((await request.patch(statusUrl).set("Authorization", auth).send({ status: "COMPLETED" })).status).toBe(409);
  const results = await Promise.all([1, 2].map(() => request.post(`/api/bookings/${booking.id}/collect-cash`).set("Authorization", auth).send({})));
  expect(results.map(result => result.status)).toEqual([200, 200]);
  const payments = await prisma.payment.findMany({ where: { target_type: "BOOKING", target_id: booking.id } });
  expect(payments).toHaveLength(1);
  expect(payments[0].status).toBe("PAID");
  expect(payments[0].paid_at).not.toBeNull();
  expect(String(payments[0].amount)).toBe("120000");
  const audits = await prisma.audit_log.findMany({ where: { entity_id: booking.id, action: "BOOKING_CASH_COLLECTED" } });
  expect(audits).toHaveLength(1);
  expect(audits[0].actor_id).toBe(admin.user.id);
  expect((await request.patch(statusUrl).set("Authorization", auth).send({ status: "COMPLETED" })).status).toBe(200);
});

it("allows collection before check-in and rejects customers and other branches", async () => {
  const { admin, customer, booking } = await setupBooking();
  const manager = await createBranchManager((await createBranch()).id);
  const url = `/api/bookings/${booking.id}/collect-cash`;
  expect((await request.post(url).set("Authorization", `Bearer ${customer.token}`).send({})).status).toBe(403);
  expect((await request.post(url).set("Authorization", `Bearer ${manager.token}`).send({})).status).toBe(403);
  const collected = await request.post(url).set("Authorization", `Bearer ${admin.token}`).send({});
  expect(collected.status).toBe(200);
  expect(collected.body.data.status).toBe("BOOKED");
  expect(collected.body.data.paymentStatus).toBe("PAID");
});

it("does not allow a customer to confirm their own cash payment", async () => {
  const { customer, booking } = await setupBooking();
  const payment = await prisma.payment.create({ data: {
    user_id: customer.user.id, target_type: "BOOKING", target_id: booking.id, provider: "CASH", amount: 120000,
  } });
  expect((await request.patch(`/api/payments/${payment.id}/mock-success`).set("Authorization", `Bearer ${customer.token}`)).status).toBe(403);
  expect((await prisma.booking.findUniqueOrThrow({ where: { id: booking.id } })).payment_status).toBe("UNPAID");
});

it("rejects cancelled bookings and pending online payments without recording cash", async () => {
  const { admin, customer, booking } = await setupBooking();
  const url = `/api/bookings/${booking.id}/collect-cash`;
  await prisma.booking.update({ where: { id: booking.id }, data: { status: "CANCELLED" } });
  expect((await request.post(url).set("Authorization", `Bearer ${admin.token}`).send({})).status).toBe(409);
  await prisma.booking.update({ where: { id: booking.id }, data: { status: "BOOKED" } });
  await prisma.payment.create({ data: { user_id: customer.user.id, target_type: "BOOKING", target_id: booking.id, provider: "VNPAY_SANDBOX", amount: 120000 } });
  expect((await request.post(url).set("Authorization", `Bearer ${admin.token}`).send({})).status).toBe(409);
  expect((await prisma.booking.findUniqueOrThrow({ where: { id: booking.id } })).payment_status).toBe("UNPAID");
});
