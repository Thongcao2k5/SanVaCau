import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { prisma } from "../../src/lib/prisma.js";
import { createCustomer, createBranch, createCategory, createProduct, createProductVariant, createInventory } from "../helpers/fixtures.js";
import { momoSignature } from "../../src/lib/momo.js";

describe("MoMo Sandbox", () => {
  beforeEach(async () => {
    await clearDatabase();
    for (const [key, value] of Object.entries({ MOMO_PARTNER_CODE: "TEST", MOMO_ACCESS_KEY: "test-access", MOMO_SECRET_KEY: "test-secret",
      MOMO_IPN_URL: "https://merchant.example/api/payments/momo/ipn", MOMO_REDIRECT_URL: "https://merchant.example/api/payments/momo/return" })) vi.stubEnv(key, value);
  });
  afterEach(() => { vi.unstubAllEnvs(); vi.unstubAllGlobals(); });

  const setup = async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branch.id, variant.id, 10);
    await request.post("/api/cart/items").set("Authorization", `Bearer ${token}`).send({ productVariantId: variant.id.toString(), quantity: 2 });
    const order = await request.post("/api/orders").set("Authorization", `Bearer ${token}`).send({ branchId: branch.id.toString() });
    return { token, orderId: order.body.data.order.id };
  };
  const mockCreate = (badSignature = false) => {
    const fetchMock = vi.fn(async (_url: unknown, init: RequestInit) => {
      const body = JSON.parse(String(init.body));
      const fields = { accessKey: "test-access", amount: body.amount, extraData: "", ipnUrl: body.ipnUrl, orderId: body.orderId,
        orderInfo: body.orderInfo, partnerCode: "TEST", redirectUrl: body.redirectUrl, requestId: body.requestId, requestType: "captureWallet" };
      expect(body.signature).toBe(momoSignature(fields, "test-secret"));
      expect(body.amount).toBe(100000);
      const response = { partnerCode: "TEST", requestId: body.requestId, orderId: body.orderId, amount: body.amount, responseTime: 123,
        resultCode: 0, payUrl: "https://test-payment.momo.vn/v2/gateway/pay?token=test" };
      return new Response(JSON.stringify({ ...response, signature: badSignature ? "wrong" : momoSignature({ accessKey: "test-access", ...response }, "test-secret") }));
    });
    vi.stubGlobal("fetch", fetchMock);
    return fetchMock;
  };
  const create = (token: string, orderId: string) => request.post("/api/payments/momo").set("Authorization", `Bearer ${token}`)
    .send({ targetType: "ORDER", targetId: orderId, amount: 1 });
  const ipn = (payment: { transactionRef: string }, orderId: string, code = 0) => {
    const body = { amount: 100000, extraData: "", message: "Test", orderId: payment.transactionRef, orderInfo: `SanVaCau ORDER #${orderId}`,
      orderType: "momo_wallet", partnerCode: "TEST", payType: "qr", requestId: payment.transactionRef, responseTime: 123, resultCode: code, transId: 1234 };
    return { ...body, signature: momoSignature({ accessKey: "test-access", ...body }, "test-secret") };
  };

  it("requires configuration and never falls back to demo", async () => {
    const { token, orderId } = await setup();
    vi.stubEnv("MOMO_SECRET_KEY", "");
    expect((await create(token, orderId)).status).toBe(503);
    expect(await prisma.payment.count()).toBe(0);
    expect((await request.post("/api/payments/mock").set("Authorization", `Bearer ${token}`).send({ targetType: "ORDER", targetId: orderId, provider: "MOMO_DEMO" })).status).toBe(400);
  });
  it("signs the server amount, reuses pending payment, and prevents client mock confirmation", async () => {
    const { token, orderId } = await setup();
    const fetchMock = mockCreate();
    const first = await create(token, orderId);
    expect(first.status).toBe(200);
    expect(first.body.data.provider).toBe("MOMO_SANDBOX");
    expect(first.body.data.checkoutUrl).toContain("test-payment.momo.vn");
    const second = await create(token, orderId);
    expect(second.body.data.id).toBe(first.body.data.id);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect((await request.patch(`/api/payments/${first.body.data.id}/mock-success`).set("Authorization", `Bearer ${token}`)).status).toBe(403);
    expect((await request.patch(`/api/payments/${first.body.data.id}/mock-fail`).set("Authorization", `Bearer ${token}`)).status).toBe(403);
  });
  it("rejects invalid create signature without marking payment paid", async () => {
    const { token, orderId } = await setup();
    mockCreate(true);
    expect((await create(token, orderId)).status).toBe(502);
    const p = await prisma.payment.findFirstOrThrow();
    expect(p.status).toBe("PENDING");
    expect(p.checkout_url).toBeNull();
  });
  it("validates IPN signature and amount, handles replay once, and does not let redirect confirm payment", async () => {
    const { token, orderId } = await setup();
    mockCreate();
    const created = await create(token, orderId);
    const body = ipn(created.body.data, orderId);
    expect((await request.post("/api/payments/momo/ipn").send({ ...body, signature: "00".repeat(32) })).status).toBe(400);
    const mismatch = { ...body, amount: 1 };
    expect((await request.post("/api/payments/momo/ipn").send({ ...mismatch, signature: momoSignature({ accessKey: "test-access", ...Object.fromEntries(Object.entries(mismatch).filter(([k]) => k !== "signature")) }, "test-secret") })).status).toBe(400);
    await request.get(`/api/payments/momo/return?resultCode=0&orderId=${body.orderId}`);
    expect((await prisma.payment.findFirstOrThrow()).status).toBe("PENDING");
    expect((await request.post("/api/payments/momo/ipn").send(body)).status).toBe(204);
    expect((await request.post("/api/payments/momo/ipn").send(body)).status).toBe(204);
    expect((await prisma.payment.findFirstOrThrow()).status).toBe("PAID");
    expect((await create(token, orderId)).status).toBe(409);
  });
  it("checks status server-to-server and rejects another user's access", async () => {
    const { token, orderId } = await setup();
    mockCreate();
    const created = await create(token, orderId);
    const { token: otherToken } = await createCustomer();
    expect((await create(otherToken, orderId)).status).toBe(404);
    expect((await request.post(`/api/payments/momo/${created.body.data.id}/check`).set("Authorization", `Bearer ${otherToken}`)).status).toBe(404);
    vi.stubGlobal("fetch", vi.fn(async (url: string, init: RequestInit) => {
      expect(url).toBe("https://test-payment.momo.vn/v2/gateway/api/query");
      const body = JSON.parse(String(init.body));
      expect(body.signature).toBe(momoSignature({ accessKey: "test-access", orderId: body.orderId, partnerCode: "TEST", requestId: body.requestId }, "test-secret"));
      return new Response(JSON.stringify({ partnerCode: "TEST", requestId: body.requestId, orderId: body.orderId, amount: 100000, resultCode: 1000 }));
    }));
    const pending = await request.post(`/api/payments/momo/${created.body.data.id}/check`).set("Authorization", `Bearer ${token}`);
    expect(pending.status).toBe(200);
    expect(pending.body.data.status).toBe("PENDING");
    expect((await request.post("/api/payments/momo/ipn").send(ipn(created.body.data, orderId, 1006))).status).toBe(204);
    expect((await prisma.payment.findFirstOrThrow()).status).toBe("FAILED");
  });
});
