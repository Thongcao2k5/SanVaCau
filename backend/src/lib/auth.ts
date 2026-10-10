import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import type { AuthUser } from "../types/auth.js";

const SALT_ROUNDS = 10;

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new Error("JWT_SECRET is required");
  }

  return secret;
};

export const hashPassword = (password: string) => {
  return bcrypt.hash(password, SALT_ROUNDS);
};

export const verifyPassword = (password: string, passwordHash: string) => {
  return bcrypt.compare(password, passwordHash);
};

export const signAuthToken = (user: AuthUser) => {
  return jwt.sign(user, getJwtSecret(), { expiresIn: "7d" });
};

export const verifyAuthToken = (token: string) => {
  return jwt.verify(token, getJwtSecret()) as AuthUser;
};

type PasswordResetToken = {
  email: string;
  otpId: string;
  purpose: "RESET_PASSWORD";
};

export const signPasswordResetToken = (payload: PasswordResetToken) => {
  return jwt.sign(payload, getJwtSecret(), { expiresIn: "10m" });
};

export const verifyPasswordResetToken = (token: string) => {
  const payload = jwt.verify(token, getJwtSecret()) as PasswordResetToken;
  if (payload.purpose !== "RESET_PASSWORD" || !payload.email || !payload.otpId) {
    throw new Error("invalid password reset token");
  }
  return payload;
};
