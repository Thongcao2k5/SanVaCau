import { createHmac, timingSafeEqual } from "node:crypto";

export class MomoError extends Error {
  constructor(message: string, public status = 502) { super(message); }
}

export const momoConfig = () => {
  const partnerCode = process.env.MOMO_PARTNER_CODE?.trim();
  const accessKey = process.env.MOMO_ACCESS_KEY?.trim();
  const secretKey = process.env.MOMO_SECRET_KEY?.trim();
  const ipnUrl = process.env.MOMO_IPN_URL?.trim();
  const redirectUrl = process.env.MOMO_REDIRECT_URL?.trim();
  if (!partnerCode || !accessKey || !secretKey || !ipnUrl || !redirectUrl) {
    throw new MomoError("MoMo Sandbox chưa được cấu hình. Điền khóa Sandbox và URL callback trong backend/.env.", 503);
  }
  for (const url of [ipnUrl, redirectUrl]) {
    if (!URL.canParse(url) || new URL(url).protocol !== "https:") {
      throw new MomoError("MoMo Sandbox cần URL IPN và redirect HTTPS công khai.", 503);
    }
  }
  return { partnerCode, accessKey, secretKey, ipnUrl, redirectUrl };
};

export const momoSignature = (fields: Record<string, unknown>, secretKey: string) =>
  createHmac("sha256", secretKey).update(Object.keys(fields).sort().map(key => `${key}=${fields[key] ?? ""}`).join("&")).digest("hex");

export const verifyMomoIpn = (body: Record<string, unknown>) => {
  const config = momoConfig();
  const fields: Record<string, unknown> = { accessKey: config.accessKey };
  for (const key of ["amount", "extraData", "message", "orderId", "orderInfo", "orderType", "partnerCode", "payType", "requestId", "responseTime", "resultCode", "transId"]) {
    if (body[key] === undefined || body[key] === null) return false;
    fields[key] = body[key];
  }
  if (body.partnerCode !== config.partnerCode || typeof body.signature !== "string" || !/^[a-f0-9]{64}$/i.test(body.signature)) return false;
  return timingSafeEqual(Buffer.from(momoSignature(fields, config.secretKey), "hex"), Buffer.from(body.signature, "hex"));
};

export const momoRequest = async (action: "create" | "query", body: Record<string, unknown>) => {
  try {
    const response = await fetch(`https://test-payment.momo.vn/v2/gateway/api/${action}`, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body), signal: AbortSignal.timeout(35000),
    });
    if (!response.ok) throw new MomoError("MoMo Sandbox đang không phản hồi. Vui lòng thử lại.");
    const result = await response.json() as Record<string, unknown>;
    if (!Number.isInteger(result.resultCode)) throw new MomoError("Phản hồi MoMo không hợp lệ.");
    return result;
  } catch (error) {
    if (error instanceof MomoError) throw error;
    throw new MomoError("Không kết nối được MoMo Sandbox. Giao dịch vẫn chờ kiểm tra; vui lòng thử lại.");
  }
};

export const isMomoFinalFailure = (code: number) => [98, 99, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1017, 1026, 2019, 4001, 4002, 4100].includes(code);

export const validMomoPayUrl = (value: unknown): value is string => {
  if (typeof value !== "string" || !URL.canParse(value)) return false;
  const url = new URL(value);
  return url.protocol === "https:" && url.hostname === "test-payment.momo.vn" && !url.username && !url.password;
};
