import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { createAuditLog } from "../lib/audit-log.js";

export const branchRouter = Router();

const parseBigIntId = (value: string) => {
  return /^\d+$/.test(value) ? BigInt(value) : null;
};

const getParamValue = (value: unknown) => {
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

const parseDateOnly = (value: unknown) => {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return null;
  }

  const date = new Date(`${value}T00:00:00.000Z`);

  return date.toISOString().slice(0, 10) === value ? date : null;
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

branchRouter.get("/:id/availability", async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));
    const date = parseDateOnly(req.query.date);

    if (!id) {
      res.status(400).json({ success: false, message: "invalid branch id" });
      return;
    }

    if (!date) {
      res.status(400).json({ success: false, message: "invalid or missing date (YYYY-MM-DD)" });
      return;
    }

    const branch = await prisma.branch.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        address: true,
        status: true,
      },
    });

    if (!branch || branch.status !== "ACTIVE") {
      res.status(404).json({ success: false, message: "branch not found or inactive" });
      return;
    }

    const courts = await prisma.court.findMany({
      where: {
        branch_id: id,
        status: "ACTIVE",
      },
      include: {
        court_price: {
          where: {
            time_slot: {
              is_active: true,
            },
          },
          include: {
            time_slot: true,
          },
          orderBy: {
            time_slot: {
              sort_order: "asc",
            },
          },
        },
      },
      orderBy: {
        id: "asc",
      },
    });

    const bookingSlots = await prisma.booking_slot.findMany({
      where: {
        court: {
          branch_id: id,
        },
        booking_date: date,
        booking: {
          status: {
            not: "CANCELLED",
          },
        },
      },
      select: {
        court_id: true,
        time_slot_id: true,
      },
    });

    const bookedSet = new Set(
      bookingSlots.map((bs) => `${bs.court_id.toString()}-${bs.time_slot_id.toString()}`)
    );

    const formattedCourts = courts.map((court) => {
      const slots = court.court_price.map((cp) => {
        const timeSlotIdStr = cp.time_slot_id.toString();
        const courtIdStr = court.id.toString();
        const isBooked = bookedSet.has(`${courtIdStr}-${timeSlotIdStr}`);

        return {
          timeSlotId: timeSlotIdStr,
          startTime: formatTime(cp.time_slot.start_time),
          endTime: formatTime(cp.time_slot.end_time),
          price: cp.price.toString(),
          isBooked,
        };
      });

      return {
        id: court.id.toString(),
        name: court.name,
        description: court.description,
        status: court.status,
        slots,
      };
    });

    res.json({
      success: true,
      data: {
        branch: {
          id: branch.id.toString(),
          name: branch.name,
          address: branch.address,
        },
        date: date.toISOString().slice(0, 10),
        courts: formattedCourts,
      },
    });
  } catch (error) {
    next(error);
  }
});

branchRouter.get("/:id/services", async (req, res, next) => {
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
      select: {
        id: true,
        status: true,
      },
    });

    if (!branch || branch.status !== "ACTIVE") {
      res.status(404).json({
        success: false,
        message: "branch not found or inactive",
      });
      return;
    }

    const branchServices = await prisma.branch_service.findMany({
      where: {
        branch_id: id,
        is_available: true,
        racket_service: {
          is_active: true,
        },
      },
      orderBy: {
        id: "asc",
      },
      include: {
        racket_service: true,
      },
    });

    const formattedServices = branchServices.map((bs) => ({
      id: bs.id.toString(),
      branchId: bs.branch_id.toString(),
      serviceId: bs.service_id.toString(),
      referencePrice: bs.reference_price ? bs.reference_price.toString() : null,
      description: bs.description,
      estimatedDuration: bs.estimated_duration,
      isAvailable: bs.is_available,
      service: {
        id: bs.racket_service.id.toString(),
        name: bs.racket_service.name,
        description: bs.racket_service.description,
        imageUrl: bs.racket_service.image_url,
      },
    }));

    res.json({
      success: true,
      data: {
        services: formattedServices,
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

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "BRANCH_CREATED",
      entityType: "branch",
      entityId: branch.id,
      afterData: { name, address },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
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

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "BRANCH_UPDATED",
      entityType: "branch",
      entityId: branch.id,
      afterData: data as Record<string, unknown>,
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
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

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "BRANCH_INACTIVATED",
      entityType: "branch",
      entityId: branch.id,
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});
