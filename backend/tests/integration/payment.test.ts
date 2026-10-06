import { describe, it, expect, beforeEach } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { prisma } from "../../src/lib/prisma.js";
import {
  createCustomer,
  createAdmin,
  createBranch,
  createCategory,
  createProduct,
  createProductVariant,
  createInventory,
} from "../helpers/fixtures.js";

describe("Payment Flow", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  const setupOrder = async (token: string, branchId: bigint) => {
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branchId, variant.id, 10);
    
    const cartRes = await request.post("/api/cart/items").set("Authorization", `Bearer ${token}`).send({ productVariantId: variant.id.toString(), quantity: 2 });
    expect(cartRes.status).toBe(200);
    const postRes = await request.post("/api/orders").set("Authorization", `Bearer ${token}`).send({ branchId: branchId.toString() });
    expect(postRes.status).toBe(201);
    
    return { orderId: postRes.body.data.order.id, totalAmount: postRes.body.data.order.totalAmount as string };
  };

  it("Customer creates payment for an eligible order, amount is calculated from server-side order total", async () => {
    const branch = await createBranch();
    const { token } = await createCustomer();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);

    const res = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.amount).toBe(totalAmount.toString());
    expect(res.body.data.status).toBe("PENDING");
  });

  it("Includes delivery shipping fee in the order payment amount", async () => {
    const branch = await createBranch();
    const { token } = await createCustomer();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);

    const fulfillmentRes = await request
      .post(`/api/fulfillments/orders/${orderId}`)
      .set("Authorization", `Bearer ${token}`)
      .send({
        fulfillmentType: "DELIVERY",
        recipientName: "Khach Hang",
        phone: "0900000000",
        addressLine: "123 Duong Mau",
        city: "TP HCM",
      });
    expect(fulfillmentRes.status).toBe(201);

    const paymentRes = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });

    expect(paymentRes.status).toBe(201);
    expect(paymentRes.body.data.amount).toBe(
      (Number(totalAmount) + 30000).toString(),
    );
  });

  it("Reject payment for a resource owned by another customer", async () => {
    const branch = await createBranch();
    const { token: token1 } = await createCustomer();
    const { token: token2 } = await createCustomer();
    
    const { orderId } = await setupOrder(token1, branch.id);
    const paymentCountBefore = await prisma.payment.count();

    const res = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token2}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });

    expect(res.status).toBe(403);
    expect(await prisma.payment.count()).toBe(paymentCountBefore);
  });

  it("Reject invalid target type or target ID", async () => {
    const { token } = await createCustomer();
    const paymentCountBefore = await prisma.payment.count();

    const res1 = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token}`)
      .send({ targetType: "INVALID", targetId: 1, provider: "MOCK" });
    expect(res1.status).toBe(400);

    const res2 = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token}`)
      .send({ targetType: "ORDER", targetId: "abc", provider: "MOCK" });
    expect(res2.status).toBe(400);
    expect(await prisma.payment.count()).toBe(paymentCountBefore);
  });

  it("Reject duplicate payment when current rules prohibit it (returns existing PENDING or 409 if PAID)", async () => {
    const branch = await createBranch();
    const { token } = await createCustomer();
    const { orderId } = await setupOrder(token, branch.id);

    // Create first payment
    const res1 = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });
    
    expect(res1.status).toBe(201);
    const paymentId = res1.body.data.id;

    // Create second time (should return existing PENDING)
    const res2 = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });

    expect(res2.status).toBe(200);
    expect(res2.body.data.id).toBe(paymentId);
    expect(res2.body.message).toMatch(/Returning existing pending payment/i);

    // Pay it
    await request
      .patch(`/api/payments/${paymentId}/mock-success`)
      .set("Authorization", `Bearer ${token}`);

    // Create third time (should return 409 PAID)
    const res3 = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });

    expect(res3.status).toBe(409);
    expect(res3.body.message).toMatch(/already paid/i);
  });

  it("Test valid and invalid payment status transitions", async () => {
    const branch = await createBranch();
    const { token } = await createCustomer();
    const { orderId } = await setupOrder(token, branch.id);

    const postRes = await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });
    const paymentId = postRes.body.data.id;

    // Valid: PENDING -> PAID
    const successRes = await request
      .patch(`/api/payments/${paymentId}/mock-success`)
      .set("Authorization", `Bearer ${token}`);
    
    expect(successRes.status).toBe(200);
    expect(successRes.body.data.status).toBe("PAID");

    // Invalid: PAID -> FAILED (already paid)
    const failRes = await request
      .patch(`/api/payments/${paymentId}/mock-fail`)
      .set("Authorization", `Bearer ${token}`);
    
    expect(failRes.status).toBe(400);
    expect(failRes.body.message).toMatch(/already PAID/i);
  });

  it("Customer can view only their own payments", async () => {
    const branch = await createBranch();
    const { token: token1 } = await createCustomer();
    const { token: token2 } = await createCustomer();
    const { orderId } = await setupOrder(token1, branch.id);

    await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${token1}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });

    const get1 = await request.get("/api/payments/me").set("Authorization", `Bearer ${token1}`);
    expect(get1.status).toBe(200);
    expect(get1.body.data.items.length).toBe(1);

    const get2 = await request.get("/api/payments/me").set("Authorization", `Bearer ${token2}`);
    expect(get2.status).toBe(200);
    expect(get2.body.data.items.length).toBe(0);
  });

  it("Admin can access the permitted payment management flow", async () => {
    const branch = await createBranch();
    const { token: custToken } = await createCustomer();
    const { token: adminToken } = await createAdmin();
    const { orderId } = await setupOrder(custToken, branch.id);

    await request
      .post("/api/payments/mock")
      .set("Authorization", `Bearer ${custToken}`)
      .send({ targetType: "ORDER", targetId: orderId, provider: "MOCK" });

    const getRes = await request.get("/api/payments").set("Authorization", `Bearer ${adminToken}`);
    expect(getRes.status).toBe(200);
    expect(getRes.body.data.items.length).toBeGreaterThan(0);
  });
});
