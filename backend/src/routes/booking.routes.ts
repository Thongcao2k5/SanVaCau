import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

import { Prisma } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";
import { createNotification } from "../lib/notification.js";

export const bookingRouter = Router();

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const validBookingStatuses = ["BOOKED", "CHECKED_IN", "COMPLETED", "CANCELLED"] as const;

const parseDateOnly = (value: unknown) => {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return null;
  }

  const date = new Date(`${value}T00:00:00.000Z`);

  return date.toISOString().slice(0, 10) === value ? date : null;
};

const bookingInclude = {
  court: {
    include: { branch: true },
  },
  app_user: true,
  booking_slot: {
    include: { time_slot: true },
  },
} satisfies Prisma.bookingInclude;

type BookingWithDetails = Prisma.bookingGetPayload<{
  include: typeof bookingInclude;
}>;

const toBookingResponse = (b: BookingWithDetails) => ({
  id: b.id.toString(),
  customer: b.app_user
    ? {
        id: b.app_user.id.toString(),
        fullName: b.app_user.full_name,
        phone: b.app_user.phone,
      }
    : undefined,
  court: {
    id: b.court.id.toString(),
    name: b.court.name,
  },
  branch: {
    id: b.court.branch.id.toString(),
    name: b.court.branch.name,
  },
  bookingDate: b.booking_date,
  status: b.status,
  totalAmount: b.total_amount.toString(),
  paymentMethod: b.payment_method,
  paymentStatus: b.payment_status,
  createdAt: b.created_at,
  checkedInAt: b.checked_in_at,
  completedAt: b.completed_at,
  cancelledAt: b.cancelled_at,
  slots: b.booking_slot.map((bs) => ({
    id: bs.id.toString(),
    timeSlotId: bs.time_slot_id.toString(),
    startTime: bs.time_slot.start_time.toISOString().slice(11, 19),
    endTime: bs.time_slot.end_time.toISOString().slice(11, 19),
    priceAtBooking: bs.price_at_booking.toString(),
  })),
});

// GET /api/bookings/availability
bookingRouter.get("/availability", async (req, res, next) => {
  try {
    const courtId = parseBigIntId(req.query.courtId as string);
    const date = parseDateOnly(req.query.date);

    if (!courtId || !date) {
      res.status(400).json({
        success: false,
        message: "courtId and valid date (YYYY-MM-DD) are required",
      });
      return;
    }

    const court = await prisma.court.findFirst({
      where: {
        id: courtId,
        status: "ACTIVE",
      },
    });

    if (!court) {
      res.status(404).json({
        success: false,
        message: "court not found or not active",
      });
      return;
    }

    const courtPrices = await prisma.court_price.findMany({
      where: {
        court_id: courtId,
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
    });

    const bookingSlots = await prisma.booking_slot.findMany({
      where: {
        court_id: courtId,
        booking_date: date,
        booking: {
          status: {
            not: "CANCELLED",
          },
        },
      },
    });

    const bookedSlotIds = new Set(bookingSlots.map((bs) => bs.time_slot_id.toString()));

    const slots = courtPrices.map((cp) => ({
      timeSlotId: cp.time_slot.id.toString(),
      startTime: cp.time_slot.start_time.toISOString().slice(11, 19),
      endTime: cp.time_slot.end_time.toISOString().slice(11, 19),
      price: cp.price.toString(),
      isBooked: bookedSlotIds.has(cp.time_slot.id.toString()),
    }));

    res.json({
      success: true,
      data: {
        slots,
      },
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
      res.status(409).json({
        success: false,
        message: "One or more time slots are already booked",
      });
      return;
    }

    next(error);
  }
});

// POST /api/bookings
bookingRouter.post("/", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const courtId = parseBigIntId(req.body?.courtId);
    const bookingDate = parseDateOnly(req.body?.bookingDate);
    const timeSlotIdsInput = req.body?.timeSlotIds as unknown;
    const paymentMethod = typeof req.body?.paymentMethod === "string" ? req.body.paymentMethod : null;

    if (!courtId || !bookingDate) {
      res.status(400).json({
        success: false,
        message: "courtId and valid bookingDate (YYYY-MM-DD) are required",
      });
      return;
    }

    if (!Array.isArray(timeSlotIdsInput) || timeSlotIdsInput.length === 0) {
      res.status(400).json({
        success: false,
        message: "timeSlotIds must be a non-empty array",
      });
      return;
    }

    const timeSlotIds = timeSlotIdsInput.map((id) => parseBigIntId(id as string)).filter(Boolean) as bigint[];
    const uniqueTimeSlotIds = new Set(timeSlotIds.map((id) => id.toString()));

    if (uniqueTimeSlotIds.size !== timeSlotIdsInput.length) {
      res.status(400).json({
        success: false,
        message: "timeSlotIds contains invalid or duplicate IDs",
      });
      return;
    }

    const court = await prisma.court.findFirst({
      where: {
        id: courtId,
        status: "ACTIVE",
      },
    });

    if (!court) {
      res.status(404).json({
        success: false,
        message: "court not found or not active",
      });
      return;
    }

    const courtPrices = await prisma.court_price.findMany({
      where: {
        court_id: courtId,
        time_slot_id: {
          in: timeSlotIds,
        },
        time_slot: {
          is_active: true,
        },
      },
      include: {
        time_slot: true,
      },
    });

    if (courtPrices.length !== timeSlotIds.length) {
      res.status(400).json({
        success: false,
        message: "One or more time slots are invalid, inactive, or do not have a price",
      });
      return;
    }

    const existingBookings = await prisma.booking_slot.findMany({
      where: {
        court_id: courtId,
        booking_date: bookingDate,
        time_slot_id: {
          in: timeSlotIds,
        },
        booking: {
          status: {
            not: "CANCELLED",
          },
        },
      },
    });

    if (existingBookings.length > 0) {
      res.status(400).json({
        success: false,
        message: "One or more time slots are already booked",
      });
      return;
    }

    let totalAmount = 0;
    for (const cp of courtPrices) {
      totalAmount += Number(cp.price);
    }

    const booking = await prisma.$transaction(async (tx) => {
      const newBooking = await tx.booking.create({
        data: {
          customer_id: BigInt(req.user!.id),
          court_id: courtId,
          booking_date: bookingDate,
          status: "BOOKED",
          total_amount: totalAmount,
          payment_method: paymentMethod,
          payment_status: "UNPAID",
        },
      });

      await tx.booking_slot.createMany({
        data: courtPrices.map((cp) => ({
          booking_id: newBooking.id,
          court_id: courtId,
          booking_date: bookingDate,
          time_slot_id: cp.time_slot_id,
          price_at_booking: cp.price,
        })),
      });

      return await tx.booking.findUnique({
        where: { id: newBooking.id },
        include: bookingInclude,
      });
    });

    if (!booking) {
      throw new Error("Failed to create booking");
    }

    res.status(201).json({
      success: true,
      message: "Booking created successfully",
      data: toBookingResponse(booking),
    });

    createNotification({
      userId: booking.customer_id,
      type: "BOOKING_CREATED",
      title: "Lịch đặt sân đã được tạo",
      message: `Bạn đã đặt ${booking.court.name} ngày ${booking.booking_date.toISOString().slice(0, 10)}.`,
      data: {
        bookingId: booking.id.toString(),
        courtId: booking.court_id.toString(),
        bookingDate: booking.booking_date.toISOString().slice(0, 10),
        status: booking.status,
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/bookings/me
bookingRouter.get("/me", requireAuth, async (req, res, next) => {
  try {
    const bookings = await prisma.booking.findMany({
      where: {
        customer_id: BigInt(req.user!.id),
      },
      orderBy: [{ booking_date: "desc" }, { id: "desc" }],
      include: bookingInclude,
    });

    res.json({
      success: true,
      data: {
        bookings: bookings.map((b) => toBookingResponse(b)),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/bookings
bookingRouter.get("/", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const isInternalStaff = req.user!.role === "BRANCH_MANAGER" || req.user!.role === "STAFF";
    const branchIdQuery = parseBigIntId(req.query.branchId as string);
    const courtId = parseBigIntId(req.query.courtId as string);
    const bookingDate = req.query.date === undefined ? undefined : parseDateOnly(req.query.date);
    const status = typeof req.query.status === "string" ? req.query.status.trim().toUpperCase() : undefined;

    if (req.query.branchId !== undefined && !branchIdQuery) {
      res.status(400).json({
        success: false,
        message: "branchId is invalid",
      });
      return;
    }

    if (req.query.courtId !== undefined && !courtId) {
      res.status(400).json({
        success: false,
        message: "courtId is invalid",
      });
      return;
    }

    if (req.query.date !== undefined && !bookingDate) {
      res.status(400).json({
        success: false,
        message: "date is invalid",
      });
      return;
    }

    if (status !== undefined && !validBookingStatuses.includes(status as (typeof validBookingStatuses)[number])) {
      res.status(400).json({
        success: false,
        message: "status is invalid",
      });
      return;
    }

    if (isInternalStaff && !req.user!.branchId) {
      res.status(403).json({
        success: false,
        message: "Forbidden: Staff has no assigned branch",
      });
      return;
    }

    const branchId = isInternalStaff ? BigInt(req.user!.branchId!) : branchIdQuery;

    const bookings = await prisma.booking.findMany({
      where: {
        ...(branchId ? { court: { branch_id: branchId } } : {}),
        ...(courtId ? { court_id: courtId } : {}),
        ...(bookingDate ? { booking_date: bookingDate } : {}),
        ...(status ? { status } : {}),
      },
      orderBy: [{ booking_date: "desc" }, { id: "desc" }],
      include: bookingInclude,
    });

    res.json({
      success: true,
      data: {
        bookings: bookings.map((b) => toBookingResponse(b)),
      },
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/bookings/:id/status
bookingRouter.patch("/:id/status", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    const status = req.body?.status as string;

    if (!id) {
      res.status(400).json({ success: false, message: "invalid booking id" });
      return;
    }

    if (!validBookingStatuses.includes(status as (typeof validBookingStatuses)[number])) {
      res.status(400).json({ success: false, message: "invalid status" });
      return;
    }

    const existingBooking = await prisma.booking.findUnique({
      where: { id },
      include: {
        court: true,
      },
    });

    if (!existingBooking) {
      res.status(404).json({ success: false, message: "booking not found" });
      return;
    }

    const isInternalStaff = req.user!.role === "BRANCH_MANAGER" || req.user!.role === "STAFF";

    if (isInternalStaff) {
      if (!req.user!.branchId) {
        res.status(403).json({ success: false, message: "Forbidden: Staff has no assigned branch" });
        return;
      }
      if (existingBooking.court.branch_id.toString() !== req.user!.branchId) {
        res.status(403).json({ success: false, message: "Forbidden: booking does not belong to your branch" });
        return;
      }
    }

    const now = new Date();
    const updateData: {
      status: string;
      checked_in_at?: Date;
      completed_at?: Date;
      cancelled_at?: Date;
    } = { status };

    if (status === "CHECKED_IN" && existingBooking.status !== "CHECKED_IN") {
      updateData.checked_in_at = now;
    } else if (status === "COMPLETED" && existingBooking.status !== "COMPLETED") {
      updateData.completed_at = now;
    } else if (status === "CANCELLED" && existingBooking.status !== "CANCELLED") {
      updateData.cancelled_at = now;
    }

    const updatedBooking = await prisma.$transaction(async (tx) => {
      if (status === "CANCELLED" && existingBooking.status !== "CANCELLED") {
        await tx.booking_slot.deleteMany({
          where: {
            booking_id: id,
          },
        });
      }

      return tx.booking.update({
        where: { id },
        data: updateData,
        include: bookingInclude,
      });
    });

    res.json({
      success: true,
      message: "Status updated successfully",
      data: toBookingResponse(updatedBooking),
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "BOOKING_STATUS_UPDATED",
      entityType: "booking",
      entityId: updatedBooking.id,
      beforeData: { status: existingBooking.status },
      afterData: { status: updatedBooking.status },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    createNotification({
      userId: updatedBooking.customer_id,
      type: "BOOKING_STATUS_UPDATED",
      title: "Trạng thái đặt sân đã cập nhật",
      message: `Lịch đặt sân #${updatedBooking.id.toString()} chuyển sang trạng thái ${updatedBooking.status}.`,
      data: {
        bookingId: updatedBooking.id.toString(),
        oldStatus: existingBooking.status,
        newStatus: updatedBooking.status,
      },
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/bookings/:id/cancel
bookingRouter.patch("/:id/cancel", requireAuth, async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({ success: false, message: "invalid booking id" });
      return;
    }

    const existingBooking = await prisma.booking.findUnique({
      where: { id },
    });

    if (!existingBooking) {
      res.status(404).json({ success: false, message: "booking not found" });
      return;
    }

    if (existingBooking.customer_id.toString() !== req.user!.id) {
      res.status(403).json({ success: false, message: "Forbidden: not your booking" });
      return;
    }

    if (existingBooking.status !== "BOOKED") {
      res.status(400).json({ success: false, message: "Only BOOKED status can be cancelled" });
      return;
    }

    const updatedBooking = await prisma.$transaction(async (tx) => {
      await tx.booking_slot.deleteMany({
        where: {
          booking_id: id,
        },
      });

      return tx.booking.update({
        where: { id },
        data: {
          status: "CANCELLED",
          cancelled_at: new Date(),
        },
        include: bookingInclude,
      });
    });

    res.json({
      success: true,
      message: "Booking cancelled successfully",
      data: toBookingResponse(updatedBooking),
    });

    createNotification({
      userId: updatedBooking.customer_id,
      type: "BOOKING_CANCELLED",
      title: "Lịch đặt sân đã hủy",
      message: `Lịch đặt sân #${updatedBooking.id.toString()} đã được hủy.`,
      data: {
        bookingId: updatedBooking.id.toString(),
        status: updatedBooking.status,
      },
    });
  } catch (error) {
    next(error);
  }
});
