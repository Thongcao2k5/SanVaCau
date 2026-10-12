import { test } from "node:test";
import assert from "node:assert/strict";
import { vnpayQuery, vnpaySignature, verifyVnpay, vnpayDate, vnpayPaymentUrl, vnpayConfig } from "../../src/lib/vnpay.js";

test("VNPay canonical encoding matches an independently calculated HMAC fixture", () => {
  const fields = { vnp_TxnRef: "ABC", vnp_TmnCode: "TESTCODE", vnp_OrderInfo: "Thanh toan don hang", vnp_Amount: "10000000" };
  const hash = "af34274593047ddd68f62fbea2d8957d103cf388421072ee7ac3f7220e2ad941b0b7b2f1112307af3fadbc220e5047a3ac3fd381197a4e04fdd14a8f1589464e";
  assert.equal(vnpayQuery(fields), "vnp_Amount=10000000&vnp_OrderInfo=Thanh+toan+don+hang&vnp_TmnCode=TESTCODE&vnp_TxnRef=ABC");
  assert.equal(vnpaySignature(fields, "test-secret"), hash);
  assert.equal(verifyVnpay({ ...fields, vnp_SecureHash: hash, vnp_SecureHashType: "SHA512" }, "test-secret"), true);
  assert.equal(verifyVnpay({ ...fields, vnp_SecureHash: hash, vnp_Amount: "1" }, "test-secret"), false);
  for (const invalid of ["", "oops", "a".repeat(127), "x".repeat(128)]) {
    assert.equal(verifyVnpay({ ...fields, vnp_SecureHash: invalid }, "test-secret"), false);
  }
});

test("VNPay dates use Vietnam time across midnight", () => {
  assert.equal(vnpayDate(new Date("2026-10-10T18:00:00Z")), "20261011010000");
});

test("payment URL signs exact VND cents and 15-minute expiration without exposing the secret", () => {
  const names = ["VNPAY_TMN_CODE", "VNPAY_HASH_SECRET", "VNPAY_RETURN_URL"];
  const previous = names.map(name => process.env[name]);
  try {
    process.env.VNPAY_TMN_CODE = "TESTCODE";
    process.env.VNPAY_HASH_SECRET = "test-secret";
    process.env.VNPAY_RETURN_URL = "https://example.com/api/payments/vnpay/return";
    const url = new URL(vnpayPaymentUrl("ABC", "100000", "Thanh toan don hang", "::ffff:127.0.0.1", new Date("2026-10-10T18:00:00Z")));
    assert.equal(url.origin, "https://sandbox.vnpayment.vn");
    assert.equal(url.searchParams.get("vnp_Amount"), "10000000");
    assert.equal(url.searchParams.get("vnp_CreateDate"), "20261011010000");
    assert.equal(url.searchParams.get("vnp_ExpireDate"), "20261011011500");
    assert.equal(url.searchParams.get("vnp_IpAddr"), "127.0.0.1");
    assert.equal(verifyVnpay(Object.fromEntries(url.searchParams), "test-secret"), true);
    assert.equal(url.toString().includes("test-secret"), false);
    process.env.VNPAY_HASH_SECRET = "";
    assert.throws(vnpayConfig);
    process.env.VNPAY_HASH_SECRET = "test-secret";
    process.env.VNPAY_RETURN_URL = "http://example.com/return";
    assert.throws(vnpayConfig);
  } finally {
    names.forEach((name, index) => {
      if (previous[index] === undefined) delete process.env[name]; else process.env[name] = previous[index];
    });
  }
});
