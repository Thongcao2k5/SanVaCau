import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma } from "@prisma/client";

export const branchServiceRouter = Router();

const parseBigIntId = (value: string) => {
  return /^\d+$/.test(value) ? BigInt(value) : null;
};

const getParamValue = (value: unknown) => {
  return typeof value === "string" ? value : "";
};

const parsePrice = (value: unknown): Prisma.Decimal | null => {
  if (value === null || value === undefined) return null;
  const numValue = Number(value);
  if (isNaN(numValue) || numValue < 0) return null;
  return new Prisma.Decimal(numValue);
};

const branchServiceSelect = {
  id: true,
  branch_id: true,
  service_id: true,
  reference_price: true,
  description: true,
  estimated_duration: true,
  is_available: true,
  racket_service: {
    select: {
      id: true,
      name: true,
      description: true,
      image_url: true,
    },
  },
} as const;

type BranchServiceRow = Prisma.branch_serviceGetPayload<{
  select: typeof branchServiceSelect;
}>;

const toBranchServiceResponse = (branchService: BranchServiceRow) => ({
  id: branchService.id.toString(),
  branchId: branchService.branch_id.toString(),
  serviceId: branchService.service_id.toString(),
  referencePrice: branchService.reference_price ? branchService.reference_price.toString() : null,
  description: branchService.description,
  estimatedDuration: branchService.estimated_duration,
  isAvailable: branchService.is_available,
  service: {
    id: branchService.racket_service.id.toString(),
    name: branchService.racket_service.name,
    description: branchService.racket_service.description,
    imageUrl: branchService.racket_service.image_url,
  },
});

branchServiceRouter.get("/", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER"]), async (req, res, next) => {
  try {
    const user = req.user!;
    const isAdmin = user.role === "ADMIN";
    
    let targetBranchId: bigint | undefined = undefined;
    
    if (!isAdmin) {
      if (!user.branchId) {
        res.status(403).json({
          success: false,
          message: "Forbidden: branch manager does not have a branch assigned",
        });
        return;
      }
      targetBranchId = BigInt(user.branchId);
    } else if (req.query.branchId) {
      const parsedId = parseBigIntId(getParamValue(req.query.branchId));
      if (!parsedId) {
        res.status(400).json({
          success: false,
          message: "branchId is invalid",
        });
        return;
      }

      targetBranchId = parsedId;
    }

    const serviceId = req.query.serviceId === undefined ? null : parseBigIntId(getParamValue(req.query.serviceId));

    if (req.query.serviceId !== undefined && !serviceId) {
      res.status(400).json({
        success: false,
        message: "serviceId is invalid",
      });
      return;
    }
    
    let isAvailable: boolean | undefined = undefined;
    if (req.query.available === "true") isAvailable = true;
    else if (req.query.available === "false") isAvailable = false;
    else if (req.query.available !== undefined) {
      res.status(400).json({
        success: false,
        message: "available must be true or false",
      });
      return;
    }

    const where: Prisma.branch_serviceWhereInput = {
      ...(targetBranchId !== undefined ? { branch_id: targetBranchId } : {}),
      ...(serviceId ? { service_id: serviceId } : {}),
      ...(isAvailable !== undefined ? { is_available: isAvailable } : {}),
    };

    const branchServices = await prisma.branch_service.findMany({
      where,
      orderBy: {
        id: "asc",
      },
      select: branchServiceSelect,
    });

    res.json({
      success: true,
      data: {
        branchServices: branchServices.map(toBranchServiceResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

branchServiceRouter.post("/", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER"]), async (req, res, next) => {
  try {
    const user = req.user!;
    const isAdmin = user.role === "ADMIN";
    
    let branchIdStr = req.body?.branchId;
    
    if (!isAdmin) {
      if (!user.branchId) {
        res.status(403).json({
          success: false,
          message: "Forbidden: branch manager does not have a branch assigned",
        });
        return;
      }
      if (!branchIdStr) {
        branchIdStr = user.branchId;
      } else if (branchIdStr.toString() !== user.branchId) {
        res.status(403).json({
          success: false,
          message: "Forbidden: cannot create service for another branch",
        });
        return;
      }
    } else {
      if (!branchIdStr) {
        res.status(400).json({
          success: false,
          message: "branchId is required for ADMIN",
        });
        return;
      }
    }

    const branchId = parseBigIntId(branchIdStr.toString());
    const serviceIdStr = req.body?.serviceId;
    const serviceId = serviceIdStr ? parseBigIntId(serviceIdStr.toString()) : null;

    if (!branchId || !serviceId) {
      res.status(400).json({
        success: false,
        message: "invalid branchId or serviceId",
      });
      return;
    }

    const branch = await prisma.branch.findUnique({
      where: { id: branchId },
    });
    if (!branch || branch.status !== "ACTIVE") {
      res.status(400).json({
        success: false,
        message: "branch not found or inactive",
      });
      return;
    }

    const racketService = await prisma.racket_service.findUnique({
      where: { id: serviceId },
    });
    if (!racketService || !racketService.is_active) {
      res.status(400).json({
        success: false,
        message: "racket service not found or inactive",
      });
      return;
    }

    const existingBranchService = await prisma.branch_service.findUnique({
      where: {
        branch_id_service_id: {
          branch_id: branchId,
          service_id: serviceId,
        },
      },
    });

    if (existingBranchService) {
      res.status(409).json({
        success: false,
        message: "This service is already added to the branch",
      });
      return;
    }

    const referencePriceRaw = req.body?.referencePrice;
    let referencePrice: Prisma.Decimal | null = null;
    if (referencePriceRaw !== undefined && referencePriceRaw !== null) {
      referencePrice = parsePrice(referencePriceRaw);
      if (referencePrice === null) {
        res.status(400).json({
          success: false,
          message: "invalid referencePrice, must be >= 0",
        });
        return;
      }
    }

    const description = typeof req.body?.description === "string" ? req.body.description.trim() : null;
    const estimatedDuration = typeof req.body?.estimatedDuration === "string" ? req.body.estimatedDuration.trim() : null;

    const branchService = await prisma.branch_service.create({
      data: {
        branch_id: branchId,
        service_id: serviceId,
        reference_price: referencePrice,
        description,
        estimated_duration: estimatedDuration,
        is_available: true,
      },
      select: branchServiceSelect,
    });

    res.status(201).json({
      success: true,
      message: "Branch service created successfully",
      data: {
        branchService: toBranchServiceResponse(branchService),
      },
    });
  } catch (error) {
    next(error);
  }
});

branchServiceRouter.patch("/:id", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER"]), async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid branch service id",
      });
      return;
    }

    const existingService = await prisma.branch_service.findUnique({
      where: { id },
      select: { branch_id: true },
    });

    if (!existingService) {
      res.status(404).json({
        success: false,
        message: "branch service not found",
      });
      return;
    }

    const user = req.user!;
    if (user.role === "BRANCH_MANAGER") {
      if (!user.branchId || existingService.branch_id.toString() !== user.branchId) {
        res.status(403).json({
          success: false,
          message: "Forbidden: cannot modify service from another branch",
        });
        return;
      }
    }

    const data: Prisma.branch_serviceUpdateInput = {};

    const referencePriceRaw = req.body?.referencePrice;
    if (referencePriceRaw !== undefined) {
      if (referencePriceRaw === null) {
        data.reference_price = null;
      } else {
        const referencePrice = parsePrice(referencePriceRaw);
        if (referencePrice === null) {
          res.status(400).json({
            success: false,
            message: "invalid referencePrice, must be >= 0",
          });
          return;
        }
        data.reference_price = referencePrice;
      }
    }

    if (req.body?.description !== undefined) {
      data.description = req.body.description === null ? null : String(req.body.description).trim();
    }

    if (req.body?.estimatedDuration !== undefined) {
      data.estimated_duration = req.body.estimatedDuration === null ? null : String(req.body.estimatedDuration).trim();
    }

    if (req.body?.isAvailable !== undefined) {
      if (typeof req.body.isAvailable !== "boolean") {
        res.status(400).json({
          success: false,
          message: "isAvailable must be a boolean",
        });
        return;
      }
      data.is_available = req.body.isAvailable;
    }

    const branchService = await prisma.branch_service.update({
      where: { id },
      data,
      select: branchServiceSelect,
    });

    res.json({
      success: true,
      message: "Branch service updated successfully",
      data: {
        branchService: toBranchServiceResponse(branchService),
      },
    });
  } catch (error) {
    next(error);
  }
});

branchServiceRouter.patch("/:id/unavailable", requireAuth, requireRole(["ADMIN", "BRANCH_MANAGER"]), async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid branch service id",
      });
      return;
    }

    const existingService = await prisma.branch_service.findUnique({
      where: { id },
      select: { branch_id: true },
    });

    if (!existingService) {
      res.status(404).json({
        success: false,
        message: "branch service not found",
      });
      return;
    }

    const user = req.user!;
    if (user.role === "BRANCH_MANAGER") {
      if (!user.branchId || existingService.branch_id.toString() !== user.branchId) {
        res.status(403).json({
          success: false,
          message: "Forbidden: cannot modify service from another branch",
        });
        return;
      }
    }

    const branchService = await prisma.branch_service.update({
      where: { id },
      data: {
        is_available: false,
      },
      select: branchServiceSelect,
    });

    res.json({
      success: true,
      message: "Branch service marked as unavailable successfully",
      data: {
        branchService: toBranchServiceResponse(branchService),
      },
    });
  } catch (error) {
    next(error);
  }
});
