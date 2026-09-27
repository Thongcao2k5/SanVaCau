import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma, support_ticket, support_ticket_message } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";
import { createNotification } from "../lib/notification.js";

export const supportRouter = Router();

type SupportTicketResponseRow = support_ticket & {
  customer?: { full_name: string } | null;
  assignee?: { full_name: string } | null;
  support_ticket_message?: Array<support_ticket_message & { sender?: { full_name: string; role: string } }>;
};

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const toMessageResponse = (msg: support_ticket_message & { sender?: { full_name: string; role: string } }) => ({
  id: msg.id.toString(),
  ticketId: msg.ticket_id.toString(),
  senderId: msg.sender_id.toString(),
  senderName: msg.sender?.full_name,
  senderRole: msg.sender?.role,
  message: msg.message,
  isStaff: msg.is_staff,
  createdAt: msg.created_at.toISOString(),
});

const toTicketResponse = (ticket: SupportTicketResponseRow) => ({
  id: ticket.id.toString(),
  customerId: ticket.customer_id.toString(),
  customerName: ticket.customer?.full_name,
  subject: ticket.subject,
  message: ticket.message,
  category: ticket.category,
  status: ticket.status,
  priority: ticket.priority,
  targetType: ticket.target_type,
  targetId: ticket.target_id?.toString() ?? null,
  assignedTo: ticket.assigned_to?.toString() ?? null,
  assigneeName: ticket.assignee?.full_name,
  createdAt: ticket.created_at.toISOString(),
  updatedAt: ticket.updated_at.toISOString(),
  resolvedAt: ticket.resolved_at?.toISOString() ?? null,
  closedAt: ticket.closed_at?.toISOString() ?? null,
  messages: ticket.support_ticket_message ? ticket.support_ticket_message.map(toMessageResponse) : undefined,
});

// A. POST /api/support/tickets
supportRouter.post("/tickets", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const { subject, message, category, targetType, targetId, priority } = req.body;

    if (!subject || typeof subject !== "string" || subject.trim().length === 0 || subject.trim().length > 200) {
      return res.status(400).json({ success: false, message: "Valid subject required (max 200)" });
    }
    if (!message || typeof message !== "string" || message.trim().length === 0 || message.trim().length > 2000) {
      return res.status(400).json({ success: false, message: "Valid message required (max 2000)" });
    }

    const validCategories = ["ORDER", "BOOKING", "PAYMENT", "ACCOUNT", "OTHER"];
    if (!validCategories.includes(category)) {
      return res.status(400).json({ success: false, message: "Invalid category" });
    }

    const validPriorities = ["LOW", "NORMAL", "HIGH"];
    const finalPriority = validPriorities.includes(priority) ? priority : "NORMAL";

    let tType: string | null = null;
    let tId: bigint | null = null;

    if (targetType && targetId) {
      const validTargets = ["ORDER", "BOOKING", "PAYMENT"];
      if (!validTargets.includes(targetType)) {
        return res.status(400).json({ success: false, message: "Invalid targetType" });
      }
      
      const parsedId = parseBigIntId(targetId);
      if (!parsedId) return res.status(400).json({ success: false, message: "Invalid targetId" });

      if (targetType === "ORDER") {
        const order = await prisma.customer_order.findUnique({ where: { id: parsedId } });
        if (!order || order.customer_id !== customerId) return res.status(404).json({ success: false, message: "Order not found" });
      } else if (targetType === "BOOKING") {
        const booking = await prisma.booking.findUnique({ where: { id: parsedId } });
        if (!booking || booking.customer_id !== customerId) return res.status(404).json({ success: false, message: "Booking not found" });
      } else if (targetType === "PAYMENT") {
        const payment = await prisma.payment.findUnique({ where: { id: parsedId } });
        if (!payment || payment.user_id !== customerId) return res.status(404).json({ success: false, message: "Payment not found" });
      }
      
      tType = targetType;
      tId = parsedId;
    }

    const ticket = await prisma.$transaction(async (tx) => {
      const newTicket = await tx.support_ticket.create({
        data: {
          customer_id: customerId,
          subject: subject.trim(),
          message: message.trim(),
          category,
          status: "OPEN",
          priority: finalPriority,
          target_type: tType,
          target_id: tId,
        },
      });

      await tx.support_ticket_message.create({
        data: {
          ticket_id: newTicket.id,
          sender_id: customerId,
          message: message.trim(),
          is_staff: false,
        },
      });

      return tx.support_ticket.findUniqueOrThrow({
        where: { id: newTicket.id },
        include: {
          support_ticket_message: {
            include: { sender: { select: { full_name: true, role: true } } },
            orderBy: { created_at: "asc" },
          },
        },
      });
    });

    res.status(201).json({
      success: true,
      message: "Support ticket created successfully",
      data: { ticket: toTicketResponse(ticket) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "SUPPORT_TICKET_CREATED",
      entityType: "support_ticket",
      entityId: ticket!.id,
      afterData: { id: ticket!.id.toString(), subject: ticket!.subject },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});

// B. GET /api/support/tickets/me
supportRouter.get("/tickets/me", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const page = Math.max(1, parseInt(req.query.page as string || "1", 10));
    const limit = Math.max(1, Math.min(100, parseInt(req.query.limit as string || "20", 10)));
    const skip = (page - 1) * limit;

    const status = req.query.status as string;
    const category = req.query.category as string;

    const where: Prisma.support_ticketWhereInput = {
      customer_id: customerId,
      ...(status ? { status } : {}),
      ...(category ? { category } : {}),
    };

    const [total, tickets] = await Promise.all([
      prisma.support_ticket.count({ where }),
      prisma.support_ticket.findMany({
        where,
        orderBy: { updated_at: "desc" },
        skip,
        take: limit,
      }),
    ]);

    res.json({
      success: true,
      data: {
        tickets: tickets.map(toTicketResponse),
        pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
      },
    });
  } catch (error) {
    next(error);
  }
});

// C. GET /api/support/tickets/:id
supportRouter.get("/tickets/:id", requireAuth, async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) return res.status(400).json({ success: false, message: "Invalid ticket id" });

    const ticket = await prisma.support_ticket.findUnique({
      where: { id },
      include: {
        customer: { select: { full_name: true } },
        assignee: { select: { full_name: true } },
        support_ticket_message: {
          include: { sender: { select: { full_name: true, role: true } } },
          orderBy: { created_at: "asc" },
        },
      },
    });

    if (!ticket) return res.status(404).json({ success: false, message: "Ticket not found" });

    if (req.user!.role === "CUSTOMER" && ticket.customer_id.toString() !== req.user!.id) {
      return res.status(403).json({ success: false, message: "Forbidden" });
    }

    res.json({
      success: true,
      data: { ticket: toTicketResponse(ticket) },
    });
  } catch (error) {
    next(error);
  }
});

// D. POST /api/support/tickets/:id/messages
supportRouter.post("/tickets/:id/messages", requireAuth, async (req, res, next) => {
  try {
    const userId = BigInt(req.user!.id);
    const userRole = req.user!.role;
    const id = parseBigIntId(req.params.id);
    if (!id) return res.status(400).json({ success: false, message: "Invalid ticket id" });

    const { message } = req.body;
    if (!message || typeof message !== "string" || message.trim().length === 0 || message.trim().length > 2000) {
      return res.status(400).json({ success: false, message: "Valid message required (max 2000)" });
    }

    const ticket = await prisma.support_ticket.findUnique({ where: { id } });
    if (!ticket) return res.status(404).json({ success: false, message: "Ticket not found" });

    const isCustomer = userRole === "CUSTOMER";
    if (isCustomer && ticket.customer_id !== userId) {
      return res.status(403).json({ success: false, message: "Forbidden" });
    }

    if (ticket.status === "CLOSED") {
      return res.status(400).json({ success: false, message: "Cannot reply to a closed ticket" });
    }

    const isStaff = !isCustomer;
    let newStatus = ticket.status;
    if (isStaff && ticket.status === "OPEN") {
      newStatus = "IN_PROGRESS";
    }

    const createdMsg = await prisma.$transaction(async (tx) => {
      const msg = await tx.support_ticket_message.create({
        data: {
          ticket_id: id,
          sender_id: userId,
          message: message.trim(),
          is_staff: isStaff,
        },
        include: { sender: { select: { full_name: true, role: true } } },
      });

      await tx.support_ticket.update({
        where: { id },
        data: {
          status: newStatus,
          updated_at: new Date(),
        },
      });

      return msg;
    });

    res.status(201).json({
      success: true,
      message: "Message sent",
      data: { message: toMessageResponse(createdMsg) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "SUPPORT_TICKET_REPLIED",
      entityType: "support_ticket",
      entityId: id,
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    if (isStaff) {
      createNotification({
        userId: ticket.customer_id,
        type: "SUPPORT_TICKET_REPLY",
        title: "Phản hồi từ hỗ trợ",
        message: `Vé hỗ trợ #${id} của bạn đã có phản hồi mới.`,
        data: { ticketId: id.toString() },
      });
    }

  } catch (error) {
    next(error);
  }
});

// E. GET /api/support/tickets
supportRouter.get("/tickets", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string || "1", 10));
    const limit = Math.max(1, Math.min(100, parseInt(req.query.limit as string || "20", 10)));
    const skip = (page - 1) * limit;

    const status = req.query.status as string;
    const category = req.query.category as string;
    const priority = req.query.priority as string;
    const customerId = parseBigIntId(req.query.customerId as string);
    const assignedTo = parseBigIntId(req.query.assignedTo as string);

    const where: Prisma.support_ticketWhereInput = {
      ...(status ? { status } : {}),
      ...(category ? { category } : {}),
      ...(priority ? { priority } : {}),
      ...(customerId ? { customer_id: customerId } : {}),
      ...(assignedTo ? { assigned_to: assignedTo } : {}),
    };

    const [total, tickets] = await Promise.all([
      prisma.support_ticket.count({ where }),
      prisma.support_ticket.findMany({
        where,
        orderBy: { updated_at: "desc" },
        skip,
        take: limit,
        include: {
          customer: { select: { full_name: true } },
          assignee: { select: { full_name: true } },
        },
      }),
    ]);

    res.json({
      success: true,
      data: {
        tickets: tickets.map(toTicketResponse),
        pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
      },
    });
  } catch (error) {
    next(error);
  }
});

// F. PATCH /api/support/tickets/:id/status
supportRouter.patch("/tickets/:id/status", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER", "STAFF"]), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) return res.status(400).json({ success: false, message: "Invalid ticket id" });

    const { status } = req.body;
    const validStatuses = ["OPEN", "IN_PROGRESS", "RESOLVED", "CLOSED"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: "Invalid status" });
    }

    const ticket = await prisma.support_ticket.findUnique({ where: { id } });
    if (!ticket) return res.status(404).json({ success: false, message: "Ticket not found" });

    const updateData: Prisma.support_ticketUpdateInput = {
      status,
      updated_at: new Date(),
    };

    if (status === "RESOLVED" && ticket.status !== "RESOLVED") updateData.resolved_at = new Date();
    if (status === "CLOSED" && ticket.status !== "CLOSED") updateData.closed_at = new Date();

    const updated = await prisma.support_ticket.update({
      where: { id },
      data: updateData,
    });

    res.json({
      success: true,
      message: "Ticket status updated",
      data: { ticket: toTicketResponse(updated) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "SUPPORT_TICKET_STATUS_UPDATED",
      entityType: "support_ticket",
      entityId: id,
      beforeData: { status: ticket.status },
      afterData: { status: updated.status },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    if (status !== ticket.status) {
      createNotification({
        userId: ticket.customer_id,
        type: "SUPPORT_TICKET_STATUS",
        title: "Cập nhật trạng thái hỗ trợ",
        message: `Vé hỗ trợ #${id} của bạn đã chuyển sang trạng thái ${status}.`,
        data: { ticketId: id.toString(), status },
      });
    }

  } catch (error) {
    next(error);
  }
});

// G. PATCH /api/support/tickets/:id/assign
supportRouter.patch("/tickets/:id/assign", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);
    if (!id) return res.status(400).json({ success: false, message: "Invalid ticket id" });

    const { assignedTo } = req.body;

    const ticket = await prisma.support_ticket.findUnique({ where: { id } });
    if (!ticket) return res.status(404).json({ success: false, message: "Ticket not found" });

    let finalAssignee: bigint | null = null;
    if (assignedTo !== undefined && assignedTo !== null) {
      const aId = parseBigIntId(assignedTo?.toString());
      if (!aId) return res.status(400).json({ success: false, message: "Invalid assignedTo id" });
      
      const user = await prisma.app_user.findUnique({ where: { id: aId } });
      if (!user || user.role === "CUSTOMER") {
        return res.status(400).json({ success: false, message: "Assignee must be a valid staff/admin" });
      }
      finalAssignee = aId;
    }

    const updated = await prisma.support_ticket.update({
      where: { id },
      data: {
        assigned_to: finalAssignee,
        updated_at: new Date(),
      },
    });

    res.json({
      success: true,
      message: "Ticket assigned successfully",
      data: { ticket: toTicketResponse(updated) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "SUPPORT_TICKET_ASSIGNED",
      entityType: "support_ticket",
      entityId: id,
      afterData: { assigned_to: finalAssignee?.toString() ?? null },
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });

    if (finalAssignee) {
      createNotification({
        userId: finalAssignee,
        type: "SUPPORT_TICKET_ASSIGNED",
        title: "Phân công hỗ trợ",
        message: `Bạn đã được phân công xử lý vé hỗ trợ #${id}.`,
        data: { ticketId: id.toString() },
      });
    }

  } catch (error) {
    next(error);
  }
});
