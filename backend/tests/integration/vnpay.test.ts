import { createHmac } from "node:crypto";
import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { prisma } from "../../src/lib/prisma.js";
import { createCustomer, createBranch, createCategory, createProduct, createProductVariant, createInventory,
  createCourt, createTimeSlot, createCourtPrice } from "../helpers/fixtures.js";
import { verifyVnpay, vnpaySignature, vnpayDate } from "../../src/lib/vnpay.js";

describe("VNPay Sandbox", () => {
  beforeEach(async () => {
    await clearDatabase();
    vi.stubEnv("VNPAY_TMN_CODE", "TESTCODE");
    vi.stubEnv("VNPAY_HASH_SECRET", "test-secret");
    vi.stubEnv("VNPAY_RETURN_URL", "https://example.com/api/payments/vnpay/return");
  });
  afterEach(() => { vi.unstubAllEnvs(); vi.unstubAllGlobals(); });
  const setup = async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branch.id, variant.id, 10);
    await request.post("/api/cart/items").set("Authorization", `Bearer ${token}`).send({ productVariantId: String(variant.id), quantity: 2 });
    const order = await request.post("/api/orders").set("Authorization", `Bearer ${token}`).send({ branchId: String(branch.id) });
    return { token, orderId: order.body.data.order.id };
  };
  const create = (token: string, targetId: string, targetType = "ORDER") => request.post("/api/payments/vnpay")
    .set("Authorization", `Bearer ${token}`).send({ targetType, targetId, amount: 1 });
  const callback = (ref: string, extra: Record<string, string> = {}) => {
    const fields = { vnp_TmnCode: "TESTCODE", vnp_TxnRef: ref, vnp_Amount: "10000000", vnp_OrderInfo: "SanVaCau ORDER 1",
      vnp_ResponseCode: "00", vnp_TransactionStatus: "00", vnp_TransactionNo: "12345", ...extra };
    return { ...fields, vnp_SecureHash: vnpaySignature(fields, "test-secret") };
  };
  it("uses GMT+7 and rejects tampered signatures", () => {
    expect(vnpayDate(new Date("2026-10-10T18:00:00Z"))).toBe("20261011010000");
    const signed = callback("ABC", { vnp_OrderInfo: "Thanh toan don hang" });
    expect(verifyVnpay(signed, "test-secret")).toBe(true);
    expect(verifyVnpay({ ...signed, vnp_Amount: "1" }, "test-secret")).toBe(false);
  });
  it("requires configuration before creating a payment", async () => {
    const { token, orderId } = await setup();
    vi.stubEnv("VNPAY_HASH_SECRET", "");
    expect((await create(token, orderId)).status).toBe(503);
    expect(await prisma.payment.count()).toBe(0);
  });
  it("signs the server amount, reuses pending payments, and blocks mock completion", async () => {
    const { token, orderId } = await setup();
    const first = await create(token, orderId);
    expect(first.status).toBe(200);
    const url = new URL(first.body.data.checkoutUrl);
    expect(url.hostname).toBe("sandbox.vnpayment.vn");
    expect(url.searchParams.get("vnp_Amount")).toBe("10000000");
    expect(verifyVnpay(Object.fromEntries(url.searchParams), "test-secret")).toBe(true);
    expect((await create(token, orderId)).body.data.id).toBe(first.body.data.id);
    for (const action of ["mock-success", "mock-fail"]) {
      expect((await request.patch(`/api/payments/${first.body.data.id}/${action}`).set("Authorization", `Bearer ${token}`)).status).toBe(403);
    }
  });
  it("enforces ownership and keeps MoMo transactions separate", async () => {
    const { token, orderId } = await setup();
    const other = await createCustomer();
    expect((await create(other.token, orderId)).status).toBe(404);
    const first = await create(token, orderId);
    expect((await request.post(`/api/payments/vnpay/${first.body.data.id}/check`).set("Authorization", `Bearer ${other.token}`)).status).toBe(404);
    await prisma.payment.update({ where: { id: BigInt(first.body.data.id) }, data: { provider: "MOMO_SANDBOX" } });
    expect((await create(token, orderId)).status).toBe(409);
    expect((await request.get("/api/payments/vnpay/ipn").query(callback(first.body.data.transactionRef))).body.RspCode).toBe("01");
  });
  it("rejects bad signatures and wrong amounts; redirects cannot settle; IPN replay is idempotent", async () => {
    const { token, orderId } = await setup();
    const p = (await create(token, orderId)).body.data;
    const body = callback(p.transactionRef);
    expect((await request.get("/api/payments/vnpay/ipn").query({ ...body, vnp_SecureHash: "0".repeat(128) })).body.RspCode).toBe("97");
    expect((await request.get("/api/payments/vnpay/ipn").query(callback(p.transactionRef, { vnp_Amount: "100" }))).body.RspCode).toBe("04");
    await request.get("/api/payments/vnpay/return").query(body);
    expect((await prisma.payment.findUniqueOrThrow({ where: { id: BigInt(p.id) } })).status).toBe("PENDING");
    expect((await request.get("/api/payments/vnpay/ipn").query(body)).body.RspCode).toBe("00");
    expect((await request.get("/api/payments/vnpay/ipn").query(body)).body.RspCode).toBe("02");
    expect((await request.post(`/api/payments/vnpay/${p.id}/check`).set("Authorization", `Bearer ${token}`)).body.data.status).toBe("PAID");
    expect((await create(token, orderId)).status).toBe(409);
  });
  it("allows retry after confirmed cancellation and preserves uncertain results", async () => {
    const { token, orderId } = await setup();
    const p = (await create(token, orderId)).body.data;
    expect((await request.get("/api/payments/vnpay/ipn").query(callback(p.transactionRef, { vnp_ResponseCode: "07", vnp_TransactionStatus: "02" }))).body.RspCode).toBe("99");
    expect((await prisma.payment.findUniqueOrThrow({ where: { id: BigInt(p.id) } })).status).toBe("PENDING");
    expect((await request.get("/api/payments/vnpay/ipn").query(callback(p.transactionRef, { vnp_ResponseCode: "24", vnp_TransactionStatus: "01" }))).body.RspCode).toBe("99");
    expect((await request.get("/api/payments/vnpay/ipn").query(callback(p.transactionRef, { vnp_ResponseCode: "24", vnp_TransactionStatus: "02" }))).body.RspCode).toBe("00");
    expect((await prisma.payment.findUniqueOrThrow({ where: { id: BigInt(p.id) } })).status).toBe("FAILED");
    expect((await create(token, orderId)).body.data.id).not.toBe(p.id);
  });
  it("settles booking payment together with the gateway payment", async () => {
    const { token } = await createCustomer();
    const branch = await createBranch();
    const court = await createCourt(branch.id);
    const slot = await createTimeSlot(6, 7);
    await createCourtPrice(court.id, slot.id, 100000);
    const date = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
    const booking = await request.post("/api/bookings").set("Authorization", `Bearer ${token}`).send({ courtId: String(court.id), bookingDate: date, timeSlotIds: [String(slot.id)] });
    expect(booking.status).toBe(201);
    const p = (await create(token, booking.body.data.id, "BOOKING")).body.data;
    expect((await request.get("/api/payments/vnpay/ipn").query(callback(p.transactionRef))).body.RspCode).toBe("00");
    expect((await prisma.booking.findUniqueOrThrow({ where: { id: BigInt(booking.body.data.id) } })).payment_status).toBe("PAID");
  });
  it("checks the gateway, rejects tampered responses, and settles verified success", async () => {
    const { token, orderId } = await setup();
    const p = (await create(token, orderId)).body.data;
    const check = () => request.post(`/api/payments/vnpay/${p.id}/check`).set("Authorization", `Bearer ${token}`);
    const fields = { vnp_ResponseId: "response1", vnp_Command: "querydr", vnp_ResponseCode: "00", vnp_Message: "QueryDR success",
      vnp_TmnCode: "TESTCODE", vnp_TxnRef: p.transactionRef, vnp_Amount: "10000000", vnp_BankCode: "NCB", vnp_PayDate: "20261011120000",
      vnp_TransactionNo: "12345", vnp_TransactionType: "01", vnp_TransactionStatus: "00", vnp_OrderInfo: "Kiem tra giao dich",
      vnp_PromotionCode: "", vnp_PromotionAmount: "" };
    const signed = { ...fields, vnp_SecureHash: createHmac("sha512", "test-secret").update(Object.values(fields).join("|")).digest("hex") };
    vi.stubGlobal("fetch", vi.fn(async () => new Response(JSON.stringify({ ...signed, vnp_Amount: "1" }))));
    expect((await check()).status).toBe(502);
    expect((await prisma.payment.findUniqueOrThrow({ where: { id: BigInt(p.id) } })).status).toBe("PENDING");
    vi.stubGlobal("fetch", vi.fn(async (_url: unknown, init: RequestInit) => {
      const body = JSON.parse(String(init.body));
      expect(body.vnp_Command).toBe("querydr");
      expect(body.vnp_TxnRef).toBe(p.transactionRef);
      expect(body.vnp_TransactionDate).toBe(new URL(p.checkoutUrl).searchParams.get("vnp_CreateDate"));
      return new Response(JSON.stringify(signed));
    }));
    expect((await check()).body.data.status).toBe("PAID");
    expect((await check()).body.data.status).toBe("PAID");
    expect(fetch).toHaveBeenCalledTimes(1);
  });

});
