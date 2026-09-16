import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { authRouter } from "./auth.routes.js";

export const router = Router();

router.get("/health", (_req, res) => {
  res.json({
    success: true,
    message: "SanVaCau API is running",
  });
});

router.get("/health/db", async (_req, res, next) => {
  try {
    await prisma.$queryRaw`SELECT 1`;

    res.json({
      success: true,
      database: "connected",
    });
  } catch (error) {
    next(error);
  }
});

router.use("/auth", authRouter);
