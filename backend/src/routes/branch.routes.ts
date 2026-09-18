import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const branchRouter = Router();

const parseBigIntId = (value: string) => {
  return /^\d+$/.test(value) ? BigInt(value) : null;
};

const getParamValue = (value: string | string[] | undefined) => {
  return typeof value === "string" ? value : "";
};

const parseTime = (value: unknown) => {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  const match = /^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$/.exec(trimmed);

  if (!match) {
    return null;
  }

  const seconds = match[3] ?? "00";
  return new Date(`1970-01-01T${match[1]}:${match[2]}:${seconds}.000Z`);
};

const formatTime = (value: Date) => {
  return value.toISOString().slice(11, 19);
};

const toBranchResponse = (branch: {
  id: bigint;
  name: string;
  address: string;
  phone: string | null;
  opening_time: Date;
  closing_time: Date;
  status: string;
  created_at: Date;
  updated_at: Date;
}) => ({
  id: branch.id.toString(),
  name: branch.name,
  address: branch.address,
  phone: branch.phone,
  openingTime: formatTime(branch.opening_time),
  closingTime: formatTime(branch.closing_time),
  status: branch.status,
  createdAt: branch.created_at,
  updatedAt: branch.updated_at,
});

const branchSelect = {
  id: true,
  name: true,
  address: true,
  phone: true,
  opening_time: true,
  closing_time: true,
  status: true,
  created_at: true,
  updated_at: true,
} as const;

branchRouter.get("/", async (_req, res, next) => {
  try {
    const branches = await prisma.branch.findMany({
      where: {
        status: "ACTIVE",
      },
      orderBy: {
        id: "asc",
      },
      select: branchSelect,
    });

    res.json({
      success: true,
      data: {
        branches: branches.map(toBranchResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

branchRouter.get("/:id", async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid branch id",
      });
      return;
    }

    const branch = await prisma.branch.findUnique({
      where: { id },
      select: branchSelect,
    });

    if (!branch || branch.status !== "ACTIVE") {
      res.status(404).json({
        success: false,
        message: "branch not found",
      });
      return;
    }

    res.json({
      success: true,
      data: {
        branch: toBranchResponse(branch),
      },
    });
  } catch (error) {
    next(error);
  }
});

branchRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
    const address = typeof req.body?.address === "string" ? req.body.address.trim() : "";
    const phone = typeof req.body?.phone === "string" ? req.body.phone.trim() : null;
    const openingTime = parseTime(req.body?.openingTime);
    const closingTime = parseTime(req.body?.closingTime);

    if (!name || !address || !openingTime || !closingTime) {
      res.status(400).json({
        success: false,
        message: "name, address, openingTime, and closingTime are required",
      });
      return;
    }

    if (openingTime >= closingTime) {
      res.status(400).json({
        success: false,
        message: "openingTime must be before closingTime",
      });
      return;
    }

    const branch = await prisma.branch.create({
      data: {
        name,
        address,
        phone,
        opening_time: openingTime,
        closing_time: closingTime,
        status: "ACTIVE",
      },
      select: branchSelect,
    });

    res.status(201).json({
      success: true,
      message: "Branch created successfully",
      data: {
        branch: toBranchResponse(branch),
      },
    });
  } catch (error) {
    next(error);
  }
});

branchRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid branch id",
      });
      return;
    }

    const existingBranch = await prisma.branch.findUnique({
      where: { id },
      select: {
        id: true,
        opening_time: true,
        closing_time: true,
      },
    });

    if (!existingBranch) {
      res.status(404).json({
        success: false,
        message: "branch not found",
      });
      return;
    }

    const name = typeof req.body?.name === "string" ? req.body.name.trim() : undefined;
    const address = typeof req.body?.address === "string" ? req.body.address.trim() : undefined;
    const phone =
      req.body?.phone === null
        ? null
        : typeof req.body?.phone === "string"
          ? req.body.phone.trim()
          : undefined;
    const openingTime = req.body?.openingTime === undefined ? undefined : parseTime(req.body.openingTime);
    const closingTime = req.body?.closingTime === undefined ? undefined : parseTime(req.body.closingTime);
    const status = typeof req.body?.status === "string" ? req.body.status.trim().toUpperCase() : undefined;

    if (name === "" || address === "") {
      res.status(400).json({
        success: false,
        message: "name and address cannot be empty",
      });
      return;
    }

    if (req.body?.openingTime !== undefined && !openingTime) {
      res.status(400).json({
        success: false,
        message: "openingTime is invalid",
      });
      return;
    }

    if (req.body?.closingTime !== undefined && !closingTime) {
      res.status(400).json({
        success: false,
        message: "closingTime is invalid",
      });
      return;
    }

    if (status !== undefined && !["ACTIVE", "INACTIVE"].includes(status)) {
      res.status(400).json({
        success: false,
        message: "status must be ACTIVE or INACTIVE",
      });
      return;
    }

    const nextOpeningTime = openingTime ?? existingBranch.opening_time;
    const nextClosingTime = closingTime ?? existingBranch.closing_time;

    if (nextOpeningTime >= nextClosingTime) {
      res.status(400).json({
        success: false,
        message: "openingTime must be before closingTime",
      });
      return;
    }

    const data = {
      ...(name !== undefined ? { name } : {}),
      ...(address !== undefined ? { address } : {}),
      ...(phone !== undefined ? { phone } : {}),
      ...(openingTime ? { opening_time: openingTime } : {}),
      ...(closingTime ? { closing_time: closingTime } : {}),
      ...(status !== undefined ? { status } : {}),
      updated_at: new Date(),
    };

    const branch = await prisma.branch.update({
      where: { id },
      data,
      select: branchSelect,
    });

    res.json({
      success: true,
      message: "Branch updated successfully",
      data: {
        branch: toBranchResponse(branch),
      },
    });
  } catch (error) {
    next(error);
  }
});

branchRouter.patch("/:id/inactivate", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid branch id",
      });
      return;
    }

    const branch = await prisma.branch.update({
      where: { id },
      data: {
        status: "INACTIVE",
        updated_at: new Date(),
      },
      select: branchSelect,
    });

    res.json({
      success: true,
      message: "Branch inactivated successfully",
      data: {
        branch: toBranchResponse(branch),
      },
    });
  } catch (error) {
    next(error);
  }
});
