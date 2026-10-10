import { randomInt } from "node:crypto";
import { Router } from "express";
import {
  hashPassword,
  signAuthToken,
  signPasswordResetToken,
  verifyPassword,
  verifyPasswordResetToken,
} from "../lib/auth.js";
import { prisma } from "../lib/prisma.js";
import { authRateLimit } from "../middleware/rate-limit.middleware.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { sendOtpEmail } from "../services/otp-email.service.js";

export const otpAuthRouter = Router();

const OTP_TTL_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;

const normalizeEmail = (value: unknown) =>
  typeof value === "string" ? value.trim().toLowerCase() : "";
const isValidEmail = (email: string) =>
  email.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
const generateOtp = () =>
  process.env.NODE_ENV === "test"
    ? "123456"
    : randomInt(100000, 1000000).toString();

const findActiveOtp = (email: string, purpose: string) =>
  prisma.auth_otp.findFirst({
    where: { email, purpose, consumed_at: null },
    orderBy: { created_at: "desc" },
  });

const createOtp = async (
  email: string,
  purpose: "REGISTER" | "RESET_PASSWORD" | "CHANGE_EMAIL",
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
    res.status(202).json({ success: true, message: "OTP sent", data: { expiresInSeconds: 300, resendAfterSeconds: 60 } });
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
    if (isValidEmail(email) && await prisma.app_user.findUnique({ where: { email }, select: { id: true } })) {
      await createOtp(email, "RESET_PASSWORD");
    }
    res.json({ success: true, message: "If the email exists, an OTP has been sent", data: { expiresInSeconds: 300, resendAfterSeconds: 60 } });
  } catch (error) { next(error); }
});

otpAuthRouter.post("/forgot-password/verify-otp", authRateLimit, async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const code = typeof req.body?.code === "string" ? req.body.code.trim() : "";
    if (!isValidEmail(email) || !/^\d{6}$/.test(code)) {
      res.status(400).json({ success: false, message: "OTP is invalid or expired" });
      return;
    }

    const otp = await verifyOtp(email, "RESET_PASSWORD", code);
    if (!otp) {
      res.status(400).json({ success: false, message: "OTP is invalid or expired" });
      return;
    }

    const resetToken = signPasswordResetToken({
      email,
      otpId: otp.id.toString(),
      purpose: "RESET_PASSWORD",
    });
    res.json({ success: true, data: { resetToken } });
  } catch (error) { next(error); }
});

otpAuthRouter.post("/forgot-password/reset", authRateLimit, async (req, res, next) => {
  try {
    const resetToken = typeof req.body?.resetToken === "string" ? req.body.resetToken : "";
    const newPassword = typeof req.body?.newPassword === "string" ? req.body.newPassword : "";
    if (!resetToken || newPassword.length < 6) {
      res.status(400).json({ success: false, message: "reset data is invalid" }); return;
    }

    let resetPayload;
    try {
      resetPayload = verifyPasswordResetToken(resetToken);
    } catch {
      res.status(400).json({ success: false, message: "Password reset session is invalid or expired" });
      return;
    }

    const otpId = BigInt(resetPayload.otpId);
    const otp = await prisma.auth_otp.findFirst({
      where: {
        id: otpId,
        email: resetPayload.email,
        purpose: "RESET_PASSWORD",
        consumed_at: null,
        expires_at: { gt: new Date() },
      },
    });
    if (!otp) {
      res.status(400).json({ success: false, message: "Password reset session is invalid or expired" });
      return;
    }

    await prisma.$transaction([
      prisma.app_user.update({ where: { email: resetPayload.email }, data: { password_hash: await hashPassword(newPassword), must_change_password: false, updated_at: new Date() } }),
      prisma.auth_otp.update({ where: { id: otp.id }, data: { consumed_at: new Date() } }),
    ]);
    res.json({ success: true, message: "Password reset successfully" });
  } catch (error) { next(error); }
});

otpAuthRouter.post(
  "/email-change/request-otp",
  requireAuth,
  authRateLimit,
  async (req, res, next) => {
    try {
      const newEmail = normalizeEmail(req.body?.newEmail);
      if (!isValidEmail(newEmail)) {
        res.status(400).json({ success: false, message: "email is invalid" });
        return;
      }

      const userId = BigInt(req.user!.id);
      const [currentUser, emailOwner] = await Promise.all([
        prisma.app_user.findUnique({
          where: { id: userId },
          select: { email: true, status: true },
        }),
        prisma.app_user.findUnique({
          where: { email: newEmail },
          select: { id: true },
        }),
      ]);

      if (!currentUser) {
        res.status(404).json({ success: false, message: "user not found" });
        return;
      }
      if (currentUser.status !== "ACTIVE") {
        res.status(403).json({ success: false, message: "account is not active" });
        return;
      }
      if (currentUser.email.toLowerCase() === newEmail || emailOwner) {
        res.status(409).json({ success: false, message: "email already exists" });
        return;
      }

      const code = await createOtp(newEmail, "CHANGE_EMAIL", {
        userId: userId.toString(),
      });
      if (!code) {
        res.status(429).json({
          success: false,
          message: "please wait before requesting another OTP",
        });
        return;
      }

      res.status(202).json({
        success: true,
        message: "OTP sent",
        data: { expiresInSeconds: 300, resendAfterSeconds: 60 },
      });
    } catch (error) {
      next(error);
    }
  },
);

otpAuthRouter.post(
  "/email-change/verify-otp",
  requireAuth,
  authRateLimit,
  async (req, res, next) => {
    try {
      const newEmail = normalizeEmail(req.body?.newEmail);
      const code = typeof req.body?.code === "string" ? req.body.code.trim() : "";
      if (!isValidEmail(newEmail) || !/^\d{6}$/.test(code)) {
        res.status(400).json({ success: false, message: "OTP is invalid or expired" });
        return;
      }

      const otp = await verifyOtp(newEmail, "CHANGE_EMAIL", code);
      const payload = otp?.payload as { userId?: string } | null;
      if (!otp || payload?.userId !== req.user!.id) {
        res.status(400).json({ success: false, message: "OTP is invalid or expired" });
        return;
      }

      const user = await prisma.$transaction(async (tx) => {
        if (await tx.app_user.findUnique({ where: { email: newEmail }, select: { id: true } })) {
          throw Object.assign(new Error("email already exists"), { statusCode: 409 });
        }

        const updated = await tx.app_user.update({
          where: { id: BigInt(req.user!.id) },
          data: { email: newEmail, updated_at: new Date() },
        });
        await tx.auth_otp.update({
          where: { id: otp.id },
          data: { consumed_at: new Date() },
        });
        return updated;
      });

      res.json({
        success: true,
        message: "Email changed successfully",
        data: {
          user: {
            id: user.id.toString(),
            email: user.email,
            fullName: user.full_name,
            phone: user.phone,
            avatarUrl: user.avatar_url,
            role: user.role,
            status: user.status,
            branchId: user.branch_id?.toString() ?? null,
            mustChangePassword: user.must_change_password,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },
);
