import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const racketServiceRouter = Router();

const parseBigIntId = (value: string) => {
  return /^\d+$/.test(value) ? BigInt(value) : null;
};

const getParamValue = (value: unknown) => {
  return typeof value === "string" ? value : "";
};

const toRacketServiceResponse = (service: {
  id: bigint;
  name: string;
  description: string | null;
  image_url: string | null;
  is_active: boolean;
}) => ({
  id: service.id.toString(),
  name: service.name,
  description: service.description,
  imageUrl: service.image_url,
  isActive: service.is_active,
});

const racketServiceSelect = {
  id: true,
  name: true,
  description: true,
  image_url: true,
  is_active: true,
} as const;

racketServiceRouter.get("/", async (_req, res, next) => {
  try {
    const services = await prisma.racket_service.findMany({
      where: {
        is_active: true,
      },
      orderBy: {
        id: "asc",
      },
      select: racketServiceSelect,
    });

    res.json({
      success: true,
      data: {
        services: services.map(toRacketServiceResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

racketServiceRouter.get("/:id", async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid racket service id",
      });
      return;
    }

    const service = await prisma.racket_service.findUnique({
      where: { id },
      select: racketServiceSelect,
    });

    if (!service || !service.is_active) {
      res.status(404).json({
        success: false,
        message: "racket service not found",
      });
      return;
    }

    res.json({
      success: true,
      data: {
        service: toRacketServiceResponse(service),
      },
    });
  } catch (error) {
    next(error);
  }
});

racketServiceRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
    const description = typeof req.body?.description === "string" ? req.body.description.trim() : null;
    const imageUrl = typeof req.body?.imageUrl === "string" ? req.body.imageUrl.trim() : null;

    if (!name) {
      res.status(400).json({
        success: false,
        message: "name is required and cannot be empty",
      });
      return;
    }

    const service = await prisma.racket_service.create({
      data: {
        name,
        description,
        image_url: imageUrl,
        is_active: true,
      },
      select: racketServiceSelect,
    });

    res.status(201).json({
      success: true,
      message: "Racket service created successfully",
      data: {
        service: toRacketServiceResponse(service),
      },
    });
  } catch (error) {
    next(error);
  }
});

racketServiceRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid racket service id",
      });
      return;
    }

    const existingService = await prisma.racket_service.findUnique({
      where: { id },
      select: { id: true },
    });

    if (!existingService) {
      res.status(404).json({
        success: false,
        message: "racket service not found",
      });
      return;
    }

    const name = typeof req.body?.name === "string" ? req.body.name.trim() : undefined;
    const description =
      req.body?.description === null
        ? null
        : typeof req.body?.description === "string"
        ? req.body.description.trim()
        : undefined;
    const imageUrl =
      req.body?.imageUrl === null
        ? null
        : typeof req.body?.imageUrl === "string"
        ? req.body.imageUrl.trim()
        : undefined;
    const isActive = typeof req.body?.isActive === "boolean" ? req.body.isActive : undefined;

    if (name === "") {
      res.status(400).json({
        success: false,
        message: "name cannot be empty",
      });
      return;
    }

    const data = {
      ...(name !== undefined ? { name } : {}),
      ...(description !== undefined ? { description } : {}),
      ...(imageUrl !== undefined ? { image_url: imageUrl } : {}),
      ...(isActive !== undefined ? { is_active: isActive } : {}),
    };

    const service = await prisma.racket_service.update({
      where: { id },
      data,
      select: racketServiceSelect,
    });

    res.json({
      success: true,
      message: "Racket service updated successfully",
      data: {
        service: toRacketServiceResponse(service),
      },
    });
  } catch (error) {
    next(error);
  }
});

racketServiceRouter.patch("/:id/inactivate", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(getParamValue(req.params.id));

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid racket service id",
      });
      return;
    }

    const existingService = await prisma.racket_service.findUnique({
      where: { id },
      select: { id: true },
    });

    if (!existingService) {
      res.status(404).json({
        success: false,
        message: "racket service not found",
      });
      return;
    }

    const service = await prisma.racket_service.update({
      where: { id },
      data: {
        is_active: false,
      },
      select: racketServiceSelect,
    });

    res.json({
      success: true,
      message: "Racket service inactivated successfully",
      data: {
        service: toRacketServiceResponse(service),
      },
    });
  } catch (error) {
    next(error);
  }
});
