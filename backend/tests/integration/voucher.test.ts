import { describe, it, expect, beforeEach } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { prisma } from "../../src/lib/prisma.js";
import {
  createCustomer,
  createVoucher,
  createBranch,
  createCategory,
  createProduct,
  createProductVariant,
  createInventory,
} from "../helpers/fixtures.js";

describe("Voucher Flow", () => {
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

  it("Apply a valid active voucher (FIXED discount)", async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);
    
    const voucher = await createVoucher({
      discountType: "FIXED",
      discountValue: 20000,
      targetType: "ORDER",
    });

    const res = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: orderId, amount: totalAmount });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.discountAmount).toBe("20000");
    expect(res.body.data.finalAmount).toBe("80000"); // 100000 - 20000
    
    const usageCount = await prisma.voucher_usage.count({ where: { voucher_id: voucher.id } });
    expect(usageCount).toBe(1);
  });

  it("Apply a valid active voucher (PERCENT discount)", async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);
    
    const voucher = await createVoucher({
      discountType: "PERCENT",
      discountValue: 10, // 10%
      targetType: "ORDER",
    });

    const res = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: orderId, amount: totalAmount });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.discountAmount).toBe("10000"); // 10% of 100000
    expect(res.body.data.finalAmount).toBe("90000");
  });

  it("Ensure discount never produces a negative payable total", async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);
    
    const voucher = await createVoucher({
      discountType: "FIXED",
      discountValue: 200000, // Greater than totalAmount
      targetType: "ORDER",
    });

    const res = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: orderId, amount: totalAmount });

    expect(res.status).toBe(201);
    expect(res.body.data.discountAmount).toBe("100000"); // Capped at totalAmount
    expect(res.body.data.finalAmount).toBe("0"); // Cannot be negative
  });

  it("Reject an expired voucher", async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);
    const voucher = await createVoucher({ discountType: "FIXED", discountValue: 10000 });
    
    // Make it expired
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - 1);
    await prisma.voucher.update({ where: { id: voucher.id }, data: { end_at: pastDate } });

    const res = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: orderId, amount: totalAmount });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/expired/i);
    expect(await prisma.voucher_usage.count()).toBe(0);
  });

  it("Reject an inactive voucher", async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);
    const voucher = await createVoucher({ discountType: "FIXED", discountValue: 10000 });
    
    await prisma.voucher.update({ where: { id: voucher.id }, data: { status: "INACTIVE" } });

    const res = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: orderId, amount: totalAmount });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/inactive/i);
    expect(await prisma.voucher_usage.count()).toBe(0);
  });

  it("Reject a voucher before its start date", async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);
    const voucher = await createVoucher({ discountType: "FIXED", discountValue: 10000 });
    
    // Future start date
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 1);
    await prisma.voucher.update({ where: { id: voucher.id }, data: { start_at: futureDate } });

    const res = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: orderId, amount: totalAmount });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/not yet active/i);
    expect(await prisma.voucher_usage.count()).toBe(0);
  });

  it("Reject an order below the voucher's minimum value", async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const { orderId, totalAmount } = await setupOrder(token, branch.id);
    
    const voucher = await createVoucher({
      discountType: "FIXED",
      discountValue: 10000,
      minOrderAmount: 200000, // higher than 100000
    });

    const res = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: orderId, amount: totalAmount });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/minimum amount/i);
    expect(await prisma.voucher_usage.count()).toBe(0);
  });

  it("Enforce usage limits and ensure failed applications do not increment usage counters", async () => {
    const { token: token1 } = await createCustomer();
    const { token: token2 } = await createCustomer();
    const branch = await createBranch();
    
    const { orderId: order1Id } = await setupOrder(token1, branch.id);
    const { orderId: order2Id } = await setupOrder(token2, branch.id);
    
    const voucher = await createVoucher({
      discountType: "FIXED",
      discountValue: 10000,
      usageLimit: 1, // Max 1 usage total
    });

    // First use (Success)
    const res1 = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token1}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: order1Id, amount: 100000 });
    
    expect(res1.status).toBe(201);

    const initialUsages = await prisma.voucher_usage.count();
    expect(initialUsages).toBe(1);

    // Second use (Fail)
    const res2 = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token2}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: order2Id, amount: 100000 });
    
    expect(res2.status).toBe(400);
    expect(res2.body.message).toMatch(/limit reached/i);

    // Verify usage didn't increase
    const finalUsages = await prisma.voucher_usage.count();
    expect(finalUsages).toBe(initialUsages);
  });

  it("Reject voucher use by another user if the order belongs to someone else", async () => {
    const { token: token1 } = await createCustomer();
    const { token: token2 } = await createCustomer(); // token2 will try to use token1's order
    const branch = await createBranch();
    
    const { orderId, totalAmount } = await setupOrder(token1, branch.id);
    
    const voucher = await createVoucher({
      discountType: "FIXED",
      discountValue: 10000,
    });

    const res = await request
      .post("/api/vouchers/apply")
      .set("Authorization", `Bearer ${token2}`)
      .send({ code: voucher.code, targetType: "ORDER", targetId: orderId, amount: totalAmount });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/access denied/i);
    expect(await prisma.voucher_usage.count()).toBe(0);
  });
});
