import { createHmac, timingSafeEqual, randomUUID } from "node:crypto";

export class VnpayError extends Error {
  constructor(message: string, public status = 400) { super(message); }
}

export const vnpayConfig = () => {
  const tmnCode = process.env.VNPAY_TMN_CODE?.trim();
  const hashSecret = process.env.VNPAY_HASH_SECRET?.trim();
  const returnUrl = process.env.VNPAY_RETURN_URL?.trim();
  if (!tmnCode || !hashSecret || !returnUrl || !URL.canParse(returnUrl) || new URL(returnUrl).protocol !== "https:") {
    throw new VnpayError("VNPay Sandbox chưa được cấu hình. Điền VNPAY_TMN_CODE, VNPAY_HASH_SECRET và VNPAY_RETURN_URL HTTPS trong backend/.env.", 503);
  }
  return { tmnCode, hashSecret, returnUrl };
};

const encode = (value: string) => encodeURIComponent(value).replace(/%20/g, "+");
export const vnpayQuery = (fields: Record<string, string>) => Object.keys(fields)
  .filter(key => key.startsWith("vnp_") && !["vnp_SecureHash", "vnp_SecureHashType"].includes(key))
  .sort().map(key => `${encode(key)}=${encode(fields[key]!)}`).join("&");
export const vnpaySignature = (fields: Record<string, string>, secret: string) =>
  createHmac("sha512", secret).update(vnpayQuery(fields)).digest("hex");
export const verifyVnpay = (fields: Record<string, string>, secret: string) => {
  const hash = fields.vnp_SecureHash;
  return typeof hash === "string" && /^[a-f0-9]{128}$/i.test(hash) &&
    timingSafeEqual(Buffer.from(hash, "hex"), Buffer.from(vnpaySignature(fields, secret), "hex"));
};
export const vnpayDate = (date: Date) => new Date(date.getTime() + 7 * 3600000)
  .toISOString().slice(0, 19).replace(/[-T:]/g, "");

export const queryVnpay = async (ref: string, checkoutUrl: string, amount: string) => {
  const config = vnpayConfig();
  const transactionDate = new URL(checkoutUrl).searchParams.get("vnp_CreateDate");
  if (!transactionDate || !/^\d{14}$/.test(transactionDate)) throw new VnpayError("Thiếu thời gian giao dịch VNPay.", 502);
  const body = { vnp_RequestId: randomUUID().replace(/-/g, ""), vnp_Version: "2.1.0", vnp_Command: "querydr",
    vnp_TmnCode: config.tmnCode, vnp_TxnRef: ref, vnp_TransactionDate: transactionDate,
    vnp_CreateDate: vnpayDate(new Date()), vnp_IpAddr: "127.0.0.1", vnp_OrderInfo: "Kiem tra giao dich" };
  const hash = createHmac("sha512", config.hashSecret).update(Object.values(body).join("|")).digest("hex");
  let result: Record<string, string>;
  try {
    const response = await fetch("https://sandbox.vnpayment.vn/merchant_webapi/api/transaction", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...body, vnp_SecureHash: hash }), signal: AbortSignal.timeout(20000),
    });
    if (!response.ok) throw new Error("Gateway unavailable");
    result = await response.json() as Record<string, string>;
  } catch { throw new VnpayError("Không kết nối được VNPay để kiểm tra giao dịch. Vui lòng thử lại.", 502); }
  const keys = ["vnp_ResponseId", "vnp_Command", "vnp_ResponseCode", "vnp_Message", "vnp_TmnCode", "vnp_TxnRef",
    "vnp_Amount", "vnp_BankCode", "vnp_PayDate", "vnp_TransactionNo", "vnp_TransactionType", "vnp_TransactionStatus",
    "vnp_OrderInfo", "vnp_PromotionCode", "vnp_PromotionAmount"];
  const expected = createHmac("sha512", config.hashSecret).update(keys.map(key => result[key] ?? "").join("|")).digest("hex");
  if (typeof result.vnp_SecureHash !== "string" || !/^[a-f0-9]{128}$/i.test(result.vnp_SecureHash) ||
      !timingSafeEqual(Buffer.from(expected, "hex"), Buffer.from(result.vnp_SecureHash, "hex"))) {
    throw new VnpayError("Chữ ký truy vấn VNPay không hợp lệ. Giao dịch chưa được cập nhật.", 502);
  }
  if (result.vnp_ResponseCode !== "00") {
    throw new VnpayError(result.vnp_ResponseCode === "94" ? "VNPay giới hạn truy vấn lặp lại. Hãy chờ 5 phút rồi kiểm tra lại."
      : result.vnp_ResponseCode === "91" ? "VNPay chưa tìm thấy giao dịch. Vui lòng kiểm tra lại sau."
      : `VNPay chưa xác nhận kết quả (mã ${result.vnp_ResponseCode}).`, 502);
  }
  if (result.vnp_TmnCode !== config.tmnCode || result.vnp_TxnRef !== ref ||
      result.vnp_Amount !== (BigInt(amount) * 100n).toString() || result.vnp_TransactionType !== "01" ||
      !/^\d{1,15}$/.test(result.vnp_TransactionNo ?? "")) throw new VnpayError("Phản hồi VNPay không khớp giao dịch.", 502);
  return result;
};

export const vnpayPaymentUrl = (ref: string, amount: string, info: string, ip: string, now = new Date()) => {
  const config = vnpayConfig();
  const fields = { vnp_Version: "2.1.0", vnp_Command: "pay", vnp_TmnCode: config.tmnCode,
    vnp_Amount: (BigInt(amount) * 100n).toString(), vnp_CurrCode: "VND", vnp_TxnRef: ref,
    vnp_OrderInfo: info, vnp_OrderType: "other", vnp_Locale: "vn", vnp_ReturnUrl: config.returnUrl,
    vnp_IpAddr: ip.replace(/^::ffff:/, ""), vnp_CreateDate: vnpayDate(now),
    vnp_ExpireDate: vnpayDate(new Date(now.getTime() + 15 * 60000)) };
  return `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?${vnpayQuery(fields)}&vnp_SecureHash=${vnpaySignature(fields, config.hashSecret)}`;
};
