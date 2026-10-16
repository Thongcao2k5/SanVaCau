import { beforeEach, expect, it } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { createAdmin, createBranch, createBranchManager, createCustomer } from "../helpers/fixtures.js";
import { prisma } from "../../src/lib/prisma.js";

beforeEach(clearDatabase);

const setup = async (status = "PENDING") => {
  const customer = await createCustomer();
  const admin = await createAdmin();
  const branch = await createBranch();
  const order = await prisma.customer_order.create({ data: { customer_id: customer.user.id, branch_id: branch.id, total_amount: 2165000, status } });
  return { order, customer, admin, auth: `Bearer ${admin.token}` };
};

it("blocks unpaid completion, confirms an existing cash payment once and updates receipts", async () => {
  const { order, customer, admin, auth } = await setup();
  const payment = await prisma.payment.create({ data: { user_id: customer.user.id, target_type: "ORDER", target_id: order.id, provider: "CASH", amount: order.total_amount } });
  expect((await request.patch(`/api/orders/${order.id}/status`).set("Authorization", auth).send({ status: "COMPLETED" })).status).toBe(409);
  const results = await Promise.all([1, 2].map(() => request.post(`/api/orders/${order.id}/collect-cash`).set("Authorization", auth).send({})));
  expect(results.map(result => result.status)).toEqual([200, 200]);
  const paid = await prisma.payment.findMany({ where: { target_type: "ORDER", target_id: order.id } });
  expect(paid).toHaveLength(1);
  expect(paid[0].id).toBe(payment.id);
  expect(paid[0].status).toBe("PAID");
  expect(paid[0].paid_at).not.toBeNull();
  const audit = await prisma.audit_log.findMany({ where: { entity_type: "order", entity_id: order.id, action: "ORDER_CASH_COLLECTED" } });
  expect(audit).toHaveLength(1);
  expect(audit[0].actor_id).toBe(admin.user.id);
  const detail = await request.get(`/api/orders/${order.id}`).set("Authorization", auth);
  expect(detail.body.data.order.paymentStatus).toBe("PAID");
  expect(detail.body.data.order.amountDue).toBe("0");
  expect((await request.patch(`/api/orders/${order.id}/status`).set("Authorization", auth).send({ status: "COMPLETED" })).status).toBe(200);
  const summary = await request.get("/api/dashboard/summary").set("Authorization", auth);
  expect(summary.body.data.cashflow.orderCollected).toBe("2165000");
});

it("allows collecting legacy completed orders without a payment record", async () => {
  const { order, auth } = await setup("COMPLETED");
  expect((await request.post(`/api/orders/${order.id}/collect-cash`).set("Authorization", auth).send({})).status).toBe(200);
  expect(await prisma.payment.count({ where: { target_type: "ORDER", target_id: order.id, status: "PAID" } })).toBe(1);
});

it("includes shipping and blocks fulfillment completion until payment is collected", async () => {
  const { order, auth } = await setup();
  const fulfillment = await prisma.order_fulfillment.create({ data: { order_id: order.id, fulfillment_type: "DELIVERY", shipping_fee: 30000 } });
  const detail = await request.get(`/api/orders/${order.id}`).set("Authorization", auth);
  expect(detail.body.data.order.amountDue).toBe("2195000");
  const url = `/api/fulfillments/${fulfillment.id}/status`;
  expect((await request.patch(url).set("Authorization", auth).send({ status: "DELIVERED" })).status).toBe(409);
  expect((await request.post(`/api/orders/${order.id}/collect-cash`).set("Authorization", auth).send({})).status).toBe(200);
  const payment = await prisma.payment.findFirstOrThrow({ where: { target_type: "ORDER", target_id: order.id } });
  expect(String(payment.amount)).toBe("2195000");
  expect((await request.patch(url).set("Authorization", auth).send({ status: "DELIVERED" })).status).toBe(200);
});

it("rejects customers, other branches, cancelled orders and pending online payments", async () => {
  const { order, customer, auth } = await setup();
  const manager = await createBranchManager((await createBranch()).id);
  const url = `/api/orders/${order.id}/collect-cash`;
  expect((await request.post(url).set("Authorization", `Bearer ${customer.token}`).send({})).status).toBe(403);
  expect((await request.post(url).set("Authorization", `Bearer ${manager.token}`).send({})).status).toBe(403);
  await prisma.customer_order.update({ where: { id: order.id }, data: { status: "CANCELLED" } });
  expect((await request.post(url).set("Authorization", auth).send({})).status).toBe(409);
  await prisma.customer_order.update({ where: { id: order.id }, data: { status: "PENDING" } });
  await prisma.payment.create({ data: { user_id: customer.user.id, target_type: "ORDER", target_id: order.id, provider: "VNPAY_SANDBOX", amount: order.total_amount } });
  expect((await request.post(url).set("Authorization", auth).send({})).status).toBe(409);
});
