import { beforeEach, expect, it } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { createAdmin, createBranch, createBranchManager, createCourt, createCustomer } from "../helpers/fixtures.js";
import { prisma } from "../../src/lib/prisma.js";

beforeEach(clearDatabase);

it("separates actual receipts and unpaid balances, uses Vietnam payment dates and branch scope", async () => {
  const { user } = await createCustomer();
  const admin = await createAdmin();
  const branch = await createBranch();
  const manager = await createBranchManager(branch.id);
  const court = await createCourt(branch.id);
  const booking = await prisma.booking.create({ data: { customer_id: user.id, court_id: court.id, booking_date: new Date("2026-10-14"), total_amount: 120000, payment_status: "PAID" } });
  await prisma.payment.create({ data: { user_id: user.id, target_type: "BOOKING", target_id: booking.id, provider: "CASH", status: "PAID", amount: 120000, paid_at: new Date("2026-10-14T17:30:00Z") } });
  await prisma.booking.create({ data: { customer_id: user.id, court_id: court.id, booking_date: new Date("2026-10-15"), total_amount: 80000 } });
  await prisma.booking.create({ data: { customer_id: user.id, court_id: court.id, booking_date: new Date("2026-10-15"), total_amount: 999000, status: "CANCELLED" } });
  const order = await prisma.customer_order.create({ data: { customer_id: user.id, branch_id: branch.id, total_amount: 250000, created_at: new Date("2026-10-15T02:00:00Z") } });
  await prisma.payment.create({ data: { user_id: user.id, target_type: "ORDER", target_id: order.id, provider: "CASH", status: "PAID", amount: 250000, paid_at: new Date("2026-10-15T02:01:00Z") } });
  await prisma.customer_order.create({ data: { customer_id: user.id, branch_id: branch.id, total_amount: 50000, status: "COMPLETED", created_at: new Date("2026-10-15T02:00:00Z") } });
  const otherBranch = await createBranch();
  const otherOrder = await prisma.customer_order.create({ data: { customer_id: user.id, branch_id: otherBranch.id, total_amount: 10000, created_at: new Date("2026-10-15T02:00:00Z") } });
  await prisma.payment.create({ data: { user_id: user.id, target_type: "ORDER", target_id: otherOrder.id, provider: "MOCK", status: "PAID", amount: 10000, paid_at: new Date("2026-10-15T02:00:00Z") } });
  const summary = await request.get("/api/dashboard/summary?date=2026-10-15").set("Authorization", `Bearer ${manager.token}`);
  expect(summary.status).toBe(200);
  expect(summary.body.data.cashflow).toEqual({ totalCollected: "370000", bookingCollected: "120000", orderCollected: "250000", totalOutstanding: "130000", bookingOutstanding: "80000", orderOutstanding: "50000" });
  const all = await request.get("/api/dashboard/summary?date=2026-10-15").set("Authorization", `Bearer ${admin.token}`);
  expect(all.body.data.cashflow.totalCollected).toBe("370000");
  expect(all.body.data.cashflow.orderOutstanding).toBe("60000");
  const previous = await request.get("/api/dashboard/summary?date=2026-10-14").set("Authorization", `Bearer ${admin.token}`);
  expect(previous.body.data.cashflow.totalCollected).toBe("0");
});
