import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma, customer_address } from "@prisma/client";
import { createAuditLog } from "../lib/audit-log.js";

export const addressRouter = Router();

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const toAddressResponse = (address: customer_address) => ({
  id: address.id.toString(),
  customerId: address.customer_id.toString(),
  recipientName: address.recipient_name,
  phone: address.phone,
  addressLine: address.address_line,
  ward: address.ward,
  district: address.district,
  city: address.city,
  note: address.note,
  isDefault: address.is_default,
  createdAt: address.created_at.toISOString(),
  updatedAt: address.updated_at.toISOString(),
});

// GET /api/addresses
addressRouter.get("/", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);

    const addresses = await prisma.customer_address.findMany({
      where: { customer_id: customerId },
      orderBy: [{ is_default: "desc" }, { created_at: "desc" }],
    });

    res.json({
      success: true,
      data: {
        addresses: addresses.map(toAddressResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/addresses
addressRouter.post("/", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const { recipientName, phone, addressLine, ward, district, city, note, isDefault } = req.body;

    if (!recipientName || typeof recipientName !== "string" || recipientName.trim().length === 0 || recipientName.trim().length > 150) {
      res.status(400).json({ success: false, message: "Valid recipientName is required (max 150)" });
      return;
    }

    if (!phone || typeof phone !== "string" || phone.trim().length === 0 || phone.trim().length > 20) {
      res.status(400).json({ success: false, message: "Valid phone is required (max 20)" });
      return;
    }

    if (!addressLine || typeof addressLine !== "string" || addressLine.trim().length === 0 || addressLine.trim().length > 300) {
      res.status(400).json({ success: false, message: "Valid addressLine is required (max 300)" });
      return;
    }

    const trimmedWard = typeof ward === "string" ? ward.trim() : null;
    const finalWard = trimmedWard === "" ? null : trimmedWard;
    
    const trimmedDistrict = typeof district === "string" ? district.trim() : null;
    const finalDistrict = trimmedDistrict === "" ? null : trimmedDistrict;
    
    const trimmedCity = typeof city === "string" ? city.trim() : null;
    const finalCity = trimmedCity === "" ? null : trimmedCity;
    
    const trimmedNote = typeof note === "string" ? note.trim() : null;
    const finalNote = trimmedNote === "" ? null : trimmedNote;

    if (finalWard && finalWard.length > 120) return res.status(400).json({ success: false, message: "ward max 120" });
    if (finalDistrict && finalDistrict.length > 120) return res.status(400).json({ success: false, message: "district max 120" });
    if (finalCity && finalCity.length > 120) return res.status(400).json({ success: false, message: "city max 120" });
    if (finalNote && finalNote.length > 500) return res.status(400).json({ success: false, message: "note max 500" });

    let shouldBeDefault = isDefault === true;

    const existingAddressesCount = await prisma.customer_address.count({
      where: { customer_id: customerId },
    });

    if (existingAddressesCount === 0) {
      shouldBeDefault = true;
    }

    const newAddress = await prisma.$transaction(async (tx) => {
      if (shouldBeDefault && existingAddressesCount > 0) {
        await tx.customer_address.updateMany({
          where: { customer_id: customerId, is_default: true },
          data: { is_default: false },
        });
      }

      return tx.customer_address.create({
        data: {
          customer_id: customerId,
          recipient_name: recipientName.trim(),
          phone: phone.trim(),
          address_line: addressLine.trim(),
          ward: finalWard,
          district: finalDistrict,
          city: finalCity,
          note: finalNote,
          is_default: shouldBeDefault,
        },
      });
    });

    res.status(201).json({
      success: true,
      message: "Address created successfully",
      data: { address: toAddressResponse(newAddress) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "ADDRESS_CREATED",
      entityType: "address",
      entityId: newAddress.id,
      afterData: toAddressResponse(newAddress),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/addresses/:id
addressRouter.patch("/:id", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({ success: false, message: "Invalid address id" });
      return;
    }

    const existingAddress = await prisma.customer_address.findUnique({
      where: { id },
    });

    if (!existingAddress || existingAddress.customer_id !== customerId) {
      res.status(404).json({ success: false, message: "Address not found" });
      return;
    }

    const { recipientName, phone, addressLine, ward, district, city, note, isDefault } = req.body;

    const dataToUpdate: Prisma.customer_addressUpdateInput = {
      updated_at: new Date(),
    };

    if (recipientName !== undefined) {
      if (typeof recipientName !== "string" || recipientName.trim().length === 0 || recipientName.trim().length > 150) {
        res.status(400).json({ success: false, message: "Valid recipientName is required (max 150)" });
        return;
      }
      dataToUpdate.recipient_name = recipientName.trim();
    }

    if (phone !== undefined) {
      if (typeof phone !== "string" || phone.trim().length === 0 || phone.trim().length > 20) {
        res.status(400).json({ success: false, message: "Valid phone is required (max 20)" });
        return;
      }
      dataToUpdate.phone = phone.trim();
    }

    if (addressLine !== undefined) {
      if (typeof addressLine !== "string" || addressLine.trim().length === 0 || addressLine.trim().length > 300) {
        res.status(400).json({ success: false, message: "Valid addressLine is required (max 300)" });
        return;
      }
      dataToUpdate.address_line = addressLine.trim();
    }

    if (ward !== undefined) {
      if (typeof ward === "string") {
        const trimmed = ward.trim();
        if (trimmed.length > 120) return res.status(400).json({ success: false, message: "ward max 120" });
        dataToUpdate.ward = trimmed === "" ? null : trimmed;
      } else {
        dataToUpdate.ward = null;
      }
    }

    if (district !== undefined) {
      if (typeof district === "string") {
        const trimmed = district.trim();
        if (trimmed.length > 120) return res.status(400).json({ success: false, message: "district max 120" });
        dataToUpdate.district = trimmed === "" ? null : trimmed;
      } else {
        dataToUpdate.district = null;
      }
    }

    if (city !== undefined) {
      if (typeof city === "string") {
        const trimmed = city.trim();
        if (trimmed.length > 120) return res.status(400).json({ success: false, message: "city max 120" });
        dataToUpdate.city = trimmed === "" ? null : trimmed;
      } else {
        dataToUpdate.city = null;
      }
    }

    if (note !== undefined) {
      if (typeof note === "string") {
        const trimmed = note.trim();
        if (trimmed.length > 500) return res.status(400).json({ success: false, message: "note max 500" });
        dataToUpdate.note = trimmed === "" ? null : trimmed;
      } else {
        dataToUpdate.note = null;
      }
    }

    if (isDefault !== undefined && typeof isDefault === "boolean") {
      if (isDefault === false && existingAddress.is_default) {
        res.status(400).json({ success: false, message: "At least one default address is required" });
        return;
      }
      dataToUpdate.is_default = isDefault;
    }

    const updatedAddress = await prisma.$transaction(async (tx) => {
      if (dataToUpdate.is_default === true) {
        await tx.customer_address.updateMany({
          where: { customer_id: customerId, is_default: true, id: { not: id } },
          data: { is_default: false },
        });
      }

      return tx.customer_address.update({
        where: { id },
        data: dataToUpdate,
      });
    });

    res.json({
      success: true,
      message: "Address updated successfully",
      data: { address: toAddressResponse(updatedAddress) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "ADDRESS_UPDATED",
      entityType: "address",
      entityId: updatedAddress.id,
      beforeData: toAddressResponse(existingAddress),
      afterData: toAddressResponse(updatedAddress),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/addresses/:id
addressRouter.delete("/:id", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({ success: false, message: "Invalid address id" });
      return;
    }

    const existingAddress = await prisma.customer_address.findUnique({
      where: { id },
    });

    if (!existingAddress || existingAddress.customer_id !== customerId) {
      res.status(404).json({ success: false, message: "Address not found" });
      return;
    }

    await prisma.$transaction(async (tx) => {
      await tx.customer_address.delete({
        where: { id },
      });

      if (existingAddress.is_default) {
        const newestRemaining = await tx.customer_address.findFirst({
          where: { customer_id: customerId },
          orderBy: { created_at: "desc" },
        });

        if (newestRemaining) {
          await tx.customer_address.update({
            where: { id: newestRemaining.id },
            data: { is_default: true },
          });
        }
      }
    });

    res.json({
      success: true,
      message: "Address deleted successfully",
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "ADDRESS_DELETED",
      entityType: "address",
      entityId: existingAddress.id,
      beforeData: toAddressResponse(existingAddress),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/addresses/:id/default
addressRouter.patch("/:id/default", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({ success: false, message: "Invalid address id" });
      return;
    }

    const existingAddress = await prisma.customer_address.findUnique({
      where: { id },
    });

    if (!existingAddress || existingAddress.customer_id !== customerId) {
      res.status(404).json({ success: false, message: "Address not found" });
      return;
    }
    
    if (existingAddress.is_default) {
      res.json({
        success: true,
        message: "Address is already default",
        data: { address: toAddressResponse(existingAddress) },
      });
      return;
    }

    const updatedAddress = await prisma.$transaction(async (tx) => {
      await tx.customer_address.updateMany({
        where: { customer_id: customerId, is_default: true },
        data: { is_default: false },
      });

      return tx.customer_address.update({
        where: { id },
        data: { is_default: true },
      });
    });

    res.json({
      success: true,
      message: "Default address updated successfully",
      data: { address: toAddressResponse(updatedAddress) },
    });

    createAuditLog({
      actorId: req.user!.id,
      actorRole: req.user!.role,
      action: "ADDRESS_SET_DEFAULT",
      entityType: "address",
      entityId: updatedAddress.id,
      beforeData: toAddressResponse(existingAddress),
      afterData: toAddressResponse(updatedAddress),
      ipAddress: req.ip ?? null,
      userAgent: req.headers["user-agent"] ?? null,
    });
  } catch (error) {
    next(error);
  }
});
