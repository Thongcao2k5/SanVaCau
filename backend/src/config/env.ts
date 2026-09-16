import "dotenv/config";

const port = Number(process.env.PORT);
const jwtSecret = process.env.JWT_SECRET;

if (!jwtSecret) {
  throw new Error("JWT_SECRET is required");
}

export const env = {
  NODE_ENV: process.env.NODE_ENV ?? "development",
  PORT: Number.isFinite(port) && port > 0 ? port : 3000,
  JWT_SECRET: jwtSecret,
} as const;
