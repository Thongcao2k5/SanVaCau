import { Router } from "express";
import { hashPassword, signAuthToken, verifyPassword } from "../lib/auth.js";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import type { AuthUser } from "../types/auth.js";

export const authRouter = Router();

const toAuthUser = (user: {
  id: bigint;
  email: string;
  role: string;
  branch_id: bigint | null;
}): AuthUser => ({
  id: user.id.toString(),
  email: user.email,
  role: user.role,
  branchId: user.branch_id?.toString() ?? null,
});

const normalizeEmail = (email: unknown) =>
  typeof email === "string" ? email.trim().toLowerCase() : "";

authRouter.post("/register", async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = typeof req.body?.password === "string" ? req.body.password : "";
    const fullName = typeof req.body?.fullName === "string" ? req.body.fullName.trim() : "";
    const phone = typeof req.body?.phone === "string" ? req.body.phone.trim() : null;

    if (!email || !password || !fullName) {
      res.status(400).json({
        success: false,
        message: "email, password, and fullName are required",
      });
      return;
    }

    if (password.length < 6) {
      res.status(400).json({
        success: false,
        message: "password must be at least 6 characters",
      });
      return;
    }

    const existingUser = await prisma.app_user.findUnique({
      where: { email },
      select: { id: true },
    });

    if (existingUser) {
      res.status(409).json({
        success: false,
        message: "email already exists",
      });
      return;
    }

    const user = await prisma.app_user.create({
      data: {
        email,
        password_hash: await hashPassword(password),
        full_name: fullName,
        phone,
        role: "CUSTOMER",
        status: "ACTIVE",
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
      },
    });

    const authUser = toAuthUser(user);

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: authUser.id,
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: authUser.branchId,
        },
        token: signAuthToken(authUser),
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/login", async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = typeof req.body?.password === "string" ? req.body.password : "";

    if (!email || !password) {
      res.status(400).json({
        success: false,
        message: "email and password are required",
      });
      return;
    }

    const user = await prisma.app_user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        password_hash: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
      },
    });

    if (!user || !(await verifyPassword(password, user.password_hash))) {
      res.status(401).json({
        success: false,
        message: "invalid email or password",
      });
      return;
    }

    if (user.status !== "ACTIVE") {
      res.status(403).json({
        success: false,
        message: "account is not active",
      });
      return;
    }

    const authUser = toAuthUser(user);

    res.json({
      success: true,
      data: {
        user: {
          id: authUser.id,
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: authUser.branchId,
        },
        token: signAuthToken(authUser),
      },
    });
  } catch (error) {
    next(error);
  }
});


authRouter.post("/dev/create-admin", async (req, res, next) => {
  try {
    const password = typeof req.body?.password === "string" ? req.body.password : "";
    const fullName =
      typeof req.body?.fullName === "string" && req.body.fullName.trim()
        ? req.body.fullName.trim()
        : "Quản trị viên";

    if (password.length < 6) {
      res.status(400).json({
        success: false,
        message: "password must be at least 6 characters",
      });
      return;
    }

    const user = await prisma.app_user.upsert({
      where: { email: "admin@shopvacau.com" },
      create: {
        email: "admin@shopvacau.com",
        password_hash: await hashPassword(password),
        full_name: fullName,
        role: "ADMIN",
        status: "ACTIVE",
        branch_id: null,
      },
      update: {
        password_hash: await hashPassword(password),
        full_name: fullName,
        role: "ADMIN",
        status: "ACTIVE",
        branch_id: null,
        must_change_password: false,
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
      },
    });

    const authUser = toAuthUser(user);

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: authUser.id,
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: authUser.branchId,
        },
        token: signAuthToken(authUser),
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.get("/me", requireAuth, (req, res) => {
  res.json({
    success: true,
    data: {
      user: req.user,
    },
  });
});

authRouter.get("/admin-check", requireAuth, requireRole("ADMIN"), (req, res) => {
  res.json({
    success: true,
    message: "Admin access granted",
    data: {
      user: req.user,
    },
  });
});



