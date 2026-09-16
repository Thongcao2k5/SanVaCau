import type { RequestHandler } from "express";
import { verifyAuthToken } from "../lib/auth.js";

export const requireAuth: RequestHandler = (req, res, next) => {
  const authorization = req.header("authorization");

  if (!authorization?.startsWith("Bearer ")) {
    res.status(401).json({
      success: false,
      message: "Missing auth token",
    });
    return;
  }

  try {
    const token = authorization.slice("Bearer ".length);
    req.user = verifyAuthToken(token);
    next();
  } catch {
    res.status(401).json({
      success: false,
      message: "Invalid auth token",
    });
  }
};

