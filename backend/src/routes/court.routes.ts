import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const courtRouter = Router();

type CourtRow = {
  id: bigint;
  branch_id: bigint;
  name: string;
  description: string | null;
  status: string;
  branch: {
    id: bigint;
    name: string;
    address: string;
  };
};

type TimeSlotRow = {
  id: bigint;
  start_time: Date;
  end_time: Date;
  sort_order: number;
  is_active: boolean;
};

type CourtPriceRow = {
  id: bigint;
  court_id: bigint;
  time_slot_id: bigint;
  price: { toString: () => string };
  time_slot: TimeSlotRow;
};

type CourtPriceInput = {
  timeSlotId: unknown;
  price: unknown;
};

const courtSelect = {
  id: true,
  branch_id: true,
  name: true,
  description: true,
  status: true,
  branch: {
    select: {
      id: true,
      name: true,
      address: true,
    },
  },
} as const;

const timeSlotSelect = {
  id: true,
  start_time: true,
  end_time: true,
  sort_order: true,
  is_active: true,
} as const;

const courtPriceSelect = {
  id: true,
  court_id: true,
  time_slot_id: true,
  price: true,
  time_slot: {
    select: timeSlotSelect,
  },
} as const;

const parseBigIntId = (value: string | string[] | undefined) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const parseBodyBigIntId = (value: unknown) => {
  if (typeof value === "string" && /^\d+$/.test(value)) {
    return BigInt(value);
  }

  if (typeof value === "number" && Number.isInteger(value) && value > 0) {
    return BigInt(value);
  }

  return null;
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

const parsePrice = (value: unknown) => {
  const price = typeof value === "number" ? value : typeof value === "string" ? Number(value) : NaN;

  return Number.isFinite(price) && price > 0 ? price : null;
};

const formatTime = (value: Date) => {
  return value.toISOString().slice(11, 19);
};

const toCourtResponse = (court: CourtRow) => ({
  id: court.id.toString(),
  branchId: court.branch_id.toString(),
  name: court.name,
  description: court.description,
  status: court.status,
  branch: {
    id: court.branch.id.toString(),
    name: court.branch.name,
    address: court.branch.address,
  },
});

const toTimeSlotResponse = (timeSlot: TimeSlotRow) => ({
  id: timeSlot.id.toString(),
  startTime: formatTime(timeSlot.start_time),
  endTime: formatTime(timeSlot.end_time),
  sortOrder: timeSlot.sort_order,
  isActive: timeSlot.is_active,
});

const toCourtPriceResponse = (courtPrice: CourtPriceRow) => ({
  id: courtPrice.id.toString(),
  courtId: courtPrice.court_id.toString(),
  timeSlotId: courtPrice.time_slot_id.toString(),
  price: courtPrice.price.toString(),
  timeSlot: toTimeSlotResponse(courtPrice.time_slot),
});

const findActiveBranch = (id: bigint) => {
  return prisma.branch.findFirst({
    where: {
      id,
      status: "ACTIVE",
    },
    select: {
      id: true,
    },
  });
};

const findCourt = (id: bigint) => {
  return prisma.court.findUnique({
    where: { id },
    select: courtSelect,
  });
};

courtRouter.get("/time-slots", async (_req, res, next) => {
  try {
    const timeSlots = await prisma.time_slot.findMany({
      where: {
        is_active: true,
      },
      orderBy: {
        sort_order: "asc",
      },
      select: timeSlotSelect,
    });

    res.json({
      success: true,
      data: {
        timeSlots: timeSlots.map(toTimeSlotResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.post("/time-slots", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const startTime = parseTime(req.body?.startTime);
    const endTime = parseTime(req.body?.endTime);
    const sortOrder = typeof req.body?.sortOrder === "number" ? req.body.sortOrder : null;

    if (!startTime || !endTime || sortOrder === null || !Number.isInteger(sortOrder)) {
      res.status(400).json({
        success: false,
        message: "startTime, endTime, and sortOrder are required",
      });
      return;
    }

    if (startTime >= endTime) {
      res.status(400).json({
        success: false,
        message: "startTime must be before endTime",
      });
      return;
    }

    const duplicatedTimeSlot = await prisma.time_slot.findFirst({
      where: {
        OR: [
          {
            start_time: startTime,
            end_time: endTime,
          },
          {
            sort_order: sortOrder,
          },
        ],
      },
      select: {
        id: true,
      },
    });

    if (duplicatedTimeSlot) {
      res.status(409).json({
        success: false,
        message: "time slot already exists",
      });
      return;
    }

    const timeSlot = await prisma.time_slot.create({
      data: {
        start_time: startTime,
        end_time: endTime,
        sort_order: sortOrder,
        is_active: true,
      },
      select: timeSlotSelect,
    });

    res.status(201).json({
      success: true,
      message: "Time slot created successfully",
      data: {
        timeSlot: toTimeSlotResponse(timeSlot),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.patch("/time-slots/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid time slot id",
      });
      return;
    }

    const existingTimeSlot = await prisma.time_slot.findUnique({
      where: { id },
      select: timeSlotSelect,
    });

    if (!existingTimeSlot) {
      res.status(404).json({
        success: false,
        message: "time slot not found",
      });
      return;
    }

    const startTime = req.body?.startTime === undefined ? undefined : parseTime(req.body.startTime);
    const endTime = req.body?.endTime === undefined ? undefined : parseTime(req.body.endTime);
    const sortOrder = typeof req.body?.sortOrder === "number" ? req.body.sortOrder : undefined;
    const isActive = typeof req.body?.isActive === "boolean" ? req.body.isActive : undefined;

    if (req.body?.startTime !== undefined && !startTime) {
      res.status(400).json({
        success: false,
        message: "startTime is invalid",
      });
      return;
    }

    if (req.body?.endTime !== undefined && !endTime) {
      res.status(400).json({
        success: false,
        message: "endTime is invalid",
      });
      return;
    }

    if (req.body?.sortOrder !== undefined && (sortOrder === undefined || !Number.isInteger(sortOrder))) {
      res.status(400).json({
        success: false,
        message: "sortOrder is invalid",
      });
      return;
    }

    const nextStartTime = startTime ?? existingTimeSlot.start_time;
    const nextEndTime = endTime ?? existingTimeSlot.end_time;

    if (nextStartTime >= nextEndTime) {
      res.status(400).json({
        success: false,
        message: "startTime must be before endTime",
      });
      return;
    }

    const duplicatedTimeSlot = await prisma.time_slot.findFirst({
      where: {
        id: {
          not: id,
        },
        OR: [
          {
            start_time: nextStartTime,
            end_time: nextEndTime,
          },
          ...(sortOrder !== undefined ? [{ sort_order: sortOrder }] : []),
        ],
      },
      select: {
        id: true,
      },
    });

    if (duplicatedTimeSlot) {
      res.status(409).json({
        success: false,
        message: "time slot already exists",
      });
      return;
    }

    const timeSlot = await prisma.time_slot.update({
      where: { id },
      data: {
        ...(startTime ? { start_time: startTime } : {}),
        ...(endTime ? { end_time: endTime } : {}),
        ...(sortOrder !== undefined ? { sort_order: sortOrder } : {}),
        ...(isActive !== undefined ? { is_active: isActive } : {}),
      },
      select: timeSlotSelect,
    });

    res.json({
      success: true,
      message: "Time slot updated successfully",
      data: {
        timeSlot: toTimeSlotResponse(timeSlot),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.get("/", async (req, res, next) => {
  try {
    const branchId = req.query.branchId === undefined ? null : parseBodyBigIntId(req.query.branchId);

    if (req.query.branchId !== undefined && !branchId) {
      res.status(400).json({
        success: false,
        message: "branchId is invalid",
      });
      return;
    }

    const courts = await prisma.court.findMany({
      where: {
        status: "ACTIVE",
        branch: {
          status: "ACTIVE",
        },
        ...(branchId ? { branch_id: branchId } : {}),
      },
      orderBy: {
        id: "asc",
      },
      select: courtSelect,
    });

    res.json({
      success: true,
      data: {
        courts: courts.map(toCourtResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.get("/:id", async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid court id",
      });
      return;
    }

    const court = await findCourt(id);

    if (!court || court.status !== "ACTIVE") {
      res.status(404).json({
        success: false,
        message: "court not found",
      });
      return;
    }

    res.json({
      success: true,
      data: {
        court: toCourtResponse(court),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const branchId = parseBodyBigIntId(req.body?.branchId);
    const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
    const description = typeof req.body?.description === "string" ? req.body.description.trim() : null;

    if (!branchId || !name) {
      res.status(400).json({
        success: false,
        message: "branchId and name are required",
      });
      return;
    }

    const branch = await findActiveBranch(branchId);

    if (!branch) {
      res.status(400).json({
        success: false,
        message: "branch not found",
      });
      return;
    }

    const duplicatedCourt = await prisma.court.findFirst({
      where: {
        branch_id: branchId,
        name: name,
      },
      select: { id: true },
    });

    if (duplicatedCourt) {
      res.status(409).json({
        success: false,
        message: "court with this name already exists in the branch",
      });
      return;
    }

    const court = await prisma.court.create({
      data: {
        branch_id: branchId,
        name,
        description,
        status: "ACTIVE",
      },
      select: courtSelect,
    });

    res.status(201).json({
      success: true,
      message: "Court created successfully",
      data: {
        court: toCourtResponse(court),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid court id",
      });
      return;
    }

    const existingCourt = await findCourt(id);

    if (!existingCourt) {
      res.status(404).json({
        success: false,
        message: "court not found",
      });
      return;
    }

    const branchId = req.body?.branchId === undefined ? undefined : parseBodyBigIntId(req.body.branchId);
    const name = typeof req.body?.name === "string" ? req.body.name.trim() : undefined;
    const description =
      req.body?.description === null
        ? null
        : typeof req.body?.description === "string"
          ? req.body.description.trim()
          : undefined;
    const status = typeof req.body?.status === "string" ? req.body.status.trim().toUpperCase() : undefined;

    if (req.body?.branchId !== undefined && !branchId) {
      res.status(400).json({
        success: false,
        message: "branchId is invalid",
      });
      return;
    }

    if (name === "") {
      res.status(400).json({
        success: false,
        message: "name cannot be empty",
      });
      return;
    }

    if (status !== undefined && !["ACTIVE", "INACTIVE", "MAINTENANCE"].includes(status)) {
      res.status(400).json({
        success: false,
        message: "status must be ACTIVE, INACTIVE, or MAINTENANCE",
      });
      return;
    }

    if (branchId) {
      const branch = await findActiveBranch(branchId);

      if (!branch) {
        res.status(400).json({
          success: false,
          message: "branch not found",
        });
        return;
      }
    }

    if (name !== undefined || branchId !== undefined) {
      const targetBranchId = branchId ?? existingCourt.branch_id;
      const targetName = name ?? existingCourt.name;

      const duplicatedCourt = await prisma.court.findFirst({
        where: {
          id: { not: id },
          branch_id: targetBranchId,
          name: targetName,
        },
        select: { id: true },
      });

      if (duplicatedCourt) {
        res.status(409).json({
          success: false,
          message: "court with this name already exists in the branch",
        });
        return;
      }
    }

    const court = await prisma.court.update({
      where: { id },
      data: {
        ...(branchId ? { branch_id: branchId } : {}),
        ...(name !== undefined ? { name } : {}),
        ...(description !== undefined ? { description } : {}),
        ...(status !== undefined ? { status } : {}),
      },
      select: courtSelect,
    });

    res.json({
      success: true,
      message: "Court updated successfully",
      data: {
        court: toCourtResponse(court),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.patch("/:id/inactivate", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid court id",
      });
      return;
    }

    const court = await prisma.court.update({
      where: { id },
      data: {
        status: "INACTIVE",
      },
      select: courtSelect,
    });

    res.json({
      success: true,
      message: "Court inactivated successfully",
      data: {
        court: toCourtResponse(court),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.get("/:id/prices", async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid court id",
      });
      return;
    }

    const court = await findCourt(id);

    if (!court || court.status !== "ACTIVE") {
      res.status(404).json({
        success: false,
        message: "court not found",
      });
      return;
    }

    const prices = await prisma.court_price.findMany({
      where: {
        court_id: id,
        time_slot: {
          is_active: true,
        },
      },
      orderBy: {
        time_slot: {
          sort_order: "asc",
        },
      },
      select: courtPriceSelect,
    });

    res.json({
      success: true,
      data: {
        court: toCourtResponse(court),
        prices: prices.map(toCourtPriceResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

courtRouter.put("/:id/prices", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    const items: CourtPriceInput[] | null = Array.isArray(req.body?.prices) ? req.body.prices : null;

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid court id",
      });
      return;
    }

    if (!items || items.length === 0) {
      res.status(400).json({
        success: false,
        message: "prices must be a non-empty array",
      });
      return;
    }

    const court = await findCourt(id);

    if (!court) {
      res.status(404).json({
        success: false,
        message: "court not found",
      });
      return;
    }

    const parsedItems = items.map((item) => ({
      timeSlotId: parseBodyBigIntId(item?.timeSlotId),
      price: parsePrice(item?.price),
    }));

    const invalidItem = parsedItems.find((item) => !item.timeSlotId || !item.price);

    if (invalidItem) {
      res.status(400).json({
        success: false,
        message: "each price item requires valid timeSlotId and price",
      });
      return;
    }

    const timeSlotIds = parsedItems.map((item) => item.timeSlotId!);
    const uniqueTimeSlotIds = new Set(timeSlotIds.map((timeSlotId) => timeSlotId.toString()));

    if (uniqueTimeSlotIds.size !== timeSlotIds.length) {
      res.status(400).json({
        success: false,
        message: "timeSlotId cannot be duplicated",
      });
      return;
    }

    const activeTimeSlotCount = await prisma.time_slot.count({
      where: {
        id: {
          in: timeSlotIds,
        },
        is_active: true,
      },
    });

    if (activeTimeSlotCount !== timeSlotIds.length) {
      res.status(400).json({
        success: false,
        message: "time slot not found",
      });
      return;
    }

    await prisma.$transaction(
      parsedItems.map((item) =>
        prisma.court_price.upsert({
          where: {
            court_id_time_slot_id: {
              court_id: id,
              time_slot_id: item.timeSlotId!,
            },
          },
          update: {
            price: item.price!,
          },
          create: {
            court_id: id,
            time_slot_id: item.timeSlotId!,
            price: item.price!,
          },
        }),
      ),
    );

    const prices = await prisma.court_price.findMany({
      where: {
        court_id: id,
      },
      orderBy: {
        time_slot: {
          sort_order: "asc",
        },
      },
      select: courtPriceSelect,
    });

    res.json({
      success: true,
      message: "Court prices updated successfully",
      data: {
        court: toCourtResponse(court),
        prices: prices.map(toCourtPriceResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});
