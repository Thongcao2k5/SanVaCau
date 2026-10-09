import { randomInt } from "node:crypto";
import { Router } from "express";
import { hashPassword, signAuthToken, verifyPassword } from "../lib/auth.js";
import { prisma } from "../lib/prisma.js";
import { authRateLimit } from "../middleware/rate-limit.middleware.js";
import { sendOtpEmail } from "../services/otp-email.service.js";

export const otpAuthRouter = Router();

const OTP_TTL_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;

const normalizeEmail = (value: unknown) =>
  typeof value === "string" ? value.trim().toLowerCase() : "";
const isValidEmail = (email: string) =>
  email.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
const generateOtp = () => randomInt(100000, 1000000).toString();
const debugOtp = (code: string) =>
  process.env.NODE_ENV === "test" ? { debugOtp: code } : {};

const findActiveOtp = (email: string, purpose: string) =>
  prisma.auth_otp.findFirst({
    where: { email, purpose, consumed_at: null },
    orderBy: { created_at: "desc" },
  });

const createOtp = async (
  email: string,
  purpose: "REGISTER" | "RESET_PASSWORD",
  payload?: Record<string, string | null>,
) => {
  const latest = await findActiveOtp(email, purpose);
  if (latest && Date.now() - latest.last_sent_at.getTime() < RESEND_COOLDOWN_MS) {
    return null;
  }

  const code = generateOtp();
  await prisma.$transaction([
    prisma.auth_otp.updateMany({
      where: { email, purpose, consumed_at: null },
      data: { consumed_at: new Date() },
    }),
    prisma.auth_otp.create({
      data: {
        email,
        purpose,
        code_hash: await hashPassword(code),
        payload,
        expires_at: new Date(Date.now() + OTP_TTL_MS),
      },
    }),
  ]);
  await sendOtpEmail({ email, code, purpose });
  return code;
};

const verifyOtp = async (email: string, purpose: string, code: string) => {
  const otp = await findActiveOtp(email, purpose);
  if (!otp || otp.expires_at <= new Date() || otp.attempts >= MAX_ATTEMPTS) {
    return null;
  }
  if (!(await verifyPassword(code, otp.code_hash))) {
    await prisma.auth_otp.update({
      where: { id: otp.id },
      data: { attempts: { increment: 1 } },
    });
    return null;
  }
  return otp;
};

otpAuthRouter.post("/register", authRateLimit, requestRegistrationOtp);
otpAuthRouter.post("/register/request-otp", authRateLimit, requestRegistrationOtp);

async function requestRegistrationOtp(req: Parameters<Parameters<typeof otpAuthRouter.post>[1]>[0], res: Parameters<Parameters<typeof otpAuthRouter.post>[1]>[1], next: Parameters<Parameters<typeof otpAuthRouter.post>[1]>[2]) {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = typeof req.body?.password === "string" ? req.body.password : "";
    const fullName = typeof req.body?.fullName === "string" ? req.body.fullName.trim() : "";
    const phone = typeof req.body?.phone === "string" ? req.body.phone.trim() || null : null;
    if (!isValidEmail(email) || !fullName || password.length < 6) {
      res.status(400).json({ success: false, message: "registration data is invalid" });
      return;
    }
    if (await prisma.app_user.findUnique({ where: { email }, select: { id: true } })) {
      res.status(409).json({ success: false, message: "email already exists" });
      return;
    }
    const code = await createOtp(email, "REGISTER", {
      passwordHash: await hashPassword(password), fullName, phone,
    });
    if (!code) {
      res.status(429).json({ success: false, message: "please wait before requesting another OTP" });
      return;
    }
    res.status(202).json({ success: true, message: "OTP sent", data: { expiresInSeconds: 300, resendAfterSeconds: 60, ...debugOtp(code) } });
  } catch (error) { next(error); }
}

otpAuthRouter.post("/register/verify-otp", authRateLimit, async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const code = typeof req.body?.code === "string" ? req.body.code.trim() : "";
    if (!isValidEmail(email) || !/^\d{6}$/.test(code)) {
      res.status(400).json({ success: false, message: "OTP is invalid or expired" }); return;
    }
    const otp = await verifyOtp(email, "REGISTER", code);
    const payload = otp?.payload as { passwordHash?: string; fullName?: string; phone?: string | null } | null;
    if (!otp || !payload?.passwordHash || !payload.fullName) {
      res.status(400).json({ success: false, message: "OTP is invalid or expired" }); return;
    }
    const user = await prisma.$transaction(async (tx) => {
      if (await tx.app_user.findUnique({ where: { email }, select: { id: true } })) {
        throw Object.assign(new Error("email already exists"), { statusCode: 409 });
      }
      const created = await tx.app_user.create({
        data: { email, password_hash: payload.passwordHash!, full_name: payload.fullName!, phone: payload.phone ?? null, role: "CUSTOMER", status: "ACTIVE" },
      });
      await tx.auth_otp.update({ where: { id: otp.id }, data: { consumed_at: new Date() } });
      return created;
    });
    const authUser = { id: user.id.toString(), email: user.email, role: user.role, branchId: user.branch_id?.toString() ?? null };
    res.status(201).json({ success: true, data: { user: { id: authUser.id, email: user.email, fullName: user.full_name, phone: user.phone, role: user.role, status: user.status, branchId: authUser.branchId, mustChangePassword: user.must_change_password }, token: signAuthToken(authUser) } });
  } catch (error) { next(error); }
});

otpAuthRouter.post("/forgot-password/request-otp", authRateLimit, async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    let code: string | null = null;
    if (isValidEmail(email) && await prisma.app_user.findUnique({ where: { email }, select: { id: true } })) {
      code = await createOtp(email, "RESET_PASSWORD");
    }
    res.json({ success: true, message: "If the email exists, an OTP has been sent", data: { expiresInSeconds: 300, resendAfterSeconds: 60, ...(code ? debugOtp(code) : {}) } });
  } catch (error) { next(error); }
});

otpAuthRouter.post("/forgot-password/reset", authRateLimit, async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const code = typeof req.body?.code === "string" ? req.body.code.trim() : "";
    const newPassword = typeof req.body?.newPassword === "string" ? req.body.newPassword : "";
    if (!isValidEmail(email) || !/^\d{6}$/.test(code) || newPassword.length < 6) {
      res.status(400).json({ success: false, message: "reset data is invalid" }); return;
    }
    const otp = await verifyOtp(email, "RESET_PASSWORD", code);
    if (!otp) { res.status(400).json({ success: false, message: "OTP is invalid or expired" }); return; }
    await prisma.$transaction([
      prisma.app_user.update({ where: { email }, data: { password_hash: await hashPassword(newPassword), must_change_password: false, updated_at: new Date() } }),
      prisma.auth_otp.update({ where: { id: otp.id }, data: { consumed_at: new Date() } }),
    ]);
    res.json({ success: true, message: "Password reset successfully" });
  } catch (error) { next(error); }
});
