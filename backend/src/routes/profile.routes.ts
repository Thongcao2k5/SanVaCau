import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { Prisma } from "@prisma/client";

export const profileRouter = Router();

const profileInclude = {
  branch: {
    select: {
      id: true,
      name: true,
      address: true,
    },
  },
} satisfies Prisma.app_userInclude;

type UserWithBranch = Prisma.app_userGetPayload<{ include: typeof profileInclude }>;

const toProfileResponse = (user: UserWithBranch) => ({
  id: user.id.toString(),
  email: user.email,
  fullName: user.full_name,
  phone: user.phone,
  role: user.role,
  status: user.status,
  branchId: user.branch_id?.toString() ?? null,
  branch: user.branch
    ? {
        id: user.branch.id.toString(),
        name: user.branch.name,
        address: user.branch.address,
      }
    : undefined,
  mustChangePassword: user.must_change_password,
  createdAt: user.created_at,
  updatedAt: user.updated_at,
});

profileRouter.get("/", requireAuth, async (req, res, next) => {
  try {
    const user = await prisma.app_user.findUnique({
      where: { id: BigInt(req.user!.id) },
      include: profileInclude,
    });

    if (!user) {
      res.status(404).json({ success: false, message: "user not found" });
      return;
    }

    if (user.status !== "ACTIVE") {
      res.status(403).json({ success: false, message: "account is not active" });
      return;
    }

    res.json({
      success: true,
      data: {
        profile: toProfileResponse(user),
      },
    });
  } catch (error) {
    next(error);
  }
});

profileRouter.patch("/", requireAuth, async (req, res, next) => {
  try {
    const fullName = typeof req.body?.fullName === "string" ? req.body.fullName.trim() : undefined;
    const phoneInput = req.body?.phone;

    let phone: string | null | undefined = undefined;

    if (fullName !== undefined && fullName.length === 0) {
      res.status(400).json({ success: false, message: "fullName cannot be empty" });
      return;
    }

    if (phoneInput !== undefined) {
      if (phoneInput === null || phoneInput === "") {
        phone = null;
      } else if (typeof phoneInput === "string") {
        const trimmed = phoneInput.trim();
        if (trimmed === "") {
          phone = null;
        } else {
          // validate: 8-20 chars, only digits, plus, space, dash
          if (!/^[0-9+\- ]{8,20}$/.test(trimmed)) {
            res.status(400).json({
              success: false,
              message: "phone must be 8-20 characters long and contain only numbers, +, -, and spaces",
            });
            return;
          }
          phone = trimmed;
        }
      } else {
        res.status(400).json({ success: false, message: "phone must be a string or null" });
        return;
      }
    }

    const existingUser = await prisma.app_user.findUnique({
      where: { id: BigInt(req.user!.id) },
      select: { id: true, status: true },
    });

    if (!existingUser) {
      res.status(404).json({ success: false, message: "user not found" });
      return;
    }

    if (existingUser.status !== "ACTIVE") {
      res.status(403).json({ success: false, message: "account is not active" });
      return;
    }

    const updatedUser = await prisma.app_user.update({
      where: { id: BigInt(req.user!.id) },
      data: {
        ...(fullName !== undefined ? { full_name: fullName } : {}),
        ...(phone !== undefined ? { phone } : {}),
        updated_at: new Date(),
      },
      include: profileInclude,
    });

    res.json({
      success: true,
      message: "Profile updated successfully",
      data: {
        profile: toProfileResponse(updatedUser),
      },
    });
  } catch (error) {
    next(error);
  }
});
