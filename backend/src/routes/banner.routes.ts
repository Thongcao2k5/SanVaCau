import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const bannerRouter = Router();

type BannerRow = {
  id: bigint;
  title: string | null;
  image_url: string;
  link_url: string | null;
  sort_order: number;
  start_at: Date | null;
  end_at: Date | null;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
};

const bannerSelect = {
  id: true,
  title: true,
  image_url: true,
  link_url: true,
  sort_order: true,
  start_at: true,
  end_at: true,
  is_active: true,
  created_at: true,
  updated_at: true,
} as const;

const parseBigIntId = (value: string | string[] | undefined) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const parseDate = (value: unknown) => {
  if (value === null || value === undefined || value === "") {
    return null;
  }

  if (typeof value !== "string") {
    return undefined;
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? undefined : date;
};

const toBannerResponse = (banner: BannerRow) => ({
  id: banner.id.toString(),
  title: banner.title,
  imageUrl: banner.image_url,
  linkUrl: banner.link_url,
  sortOrder: banner.sort_order,
  startAt: banner.start_at,
  endAt: banner.end_at,
  isActive: banner.is_active,
  createdAt: banner.created_at,
  updatedAt: banner.updated_at,
});

bannerRouter.get("/", async (_req, res, next) => {
  try {
    const now = new Date();
    const banners = await prisma.banner.findMany({
      where: {
        is_active: true,
        OR: [{ start_at: null }, { start_at: { lte: now } }],
        AND: [{ OR: [{ end_at: null }, { end_at: { gte: now } }] }],
      },
      orderBy: [{ sort_order: "asc" }, { id: "desc" }],
      select: bannerSelect,
    });

    res.json({
      success: true,
      data: {
        banners: banners.map(toBannerResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

bannerRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const title = typeof req.body?.title === "string" ? req.body.title.trim() : null;
    const imageUrl = typeof req.body?.imageUrl === "string" ? req.body.imageUrl.trim() : "";
    const linkUrl = typeof req.body?.linkUrl === "string" ? req.body.linkUrl.trim() : null;
    const sortOrder = typeof req.body?.sortOrder === "number" && Number.isInteger(req.body.sortOrder) ? req.body.sortOrder : 0;
    const startAt = parseDate(req.body?.startAt);
    const endAt = parseDate(req.body?.endAt);

    if (!imageUrl) {
      res.status(400).json({
        success: false,
        message: "imageUrl is required",
      });
      return;
    }

    if (startAt === undefined || endAt === undefined) {
      res.status(400).json({
        success: false,
        message: "startAt or endAt is invalid",
      });
      return;
    }

    if (startAt && endAt && startAt >= endAt) {
      res.status(400).json({
        success: false,
        message: "startAt must be before endAt",
      });
      return;
    }

    const banner = await prisma.banner.create({
      data: {
        title,
        image_url: imageUrl,
        link_url: linkUrl,
        sort_order: sortOrder,
        start_at: startAt,
        end_at: endAt,
        is_active: true,
      },
      select: bannerSelect,
    });

    res.status(201).json({
      success: true,
      message: "Banner created successfully",
      data: {
        banner: toBannerResponse(banner),
      },
    });
  } catch (error) {
    next(error);
  }
});

bannerRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid banner id",
      });
      return;
    }

    const title = req.body?.title === null ? null : typeof req.body?.title === "string" ? req.body.title.trim() : undefined;
    const imageUrl = typeof req.body?.imageUrl === "string" ? req.body.imageUrl.trim() : undefined;
    const linkUrl = req.body?.linkUrl === null ? null : typeof req.body?.linkUrl === "string" ? req.body.linkUrl.trim() : undefined;
    const sortOrder =
      req.body?.sortOrder === undefined
        ? undefined
        : typeof req.body.sortOrder === "number" && Number.isInteger(req.body.sortOrder)
          ? req.body.sortOrder
          : null;
    const startAt = req.body?.startAt === undefined ? undefined : parseDate(req.body.startAt);
    const endAt = req.body?.endAt === undefined ? undefined : parseDate(req.body.endAt);
    const isActive = typeof req.body?.isActive === "boolean" ? req.body.isActive : undefined;

    if (imageUrl === "") {
      res.status(400).json({
        success: false,
        message: "imageUrl cannot be empty",
      });
      return;
    }

    if (sortOrder === null) {
      res.status(400).json({
        success: false,
        message: "sortOrder is invalid",
      });
      return;
    }

    if (startAt === undefined || endAt === undefined) {
      res.status(400).json({
        success: false,
        message: "startAt or endAt is invalid",
      });
      return;
    }

    if (startAt && endAt && startAt >= endAt) {
      res.status(400).json({
        success: false,
        message: "startAt must be before endAt",
      });
      return;
    }

    const banner = await prisma.banner.update({
      where: { id },
      data: {
        ...(title !== undefined ? { title } : {}),
        ...(imageUrl !== undefined ? { image_url: imageUrl } : {}),
        ...(linkUrl !== undefined ? { link_url: linkUrl } : {}),
        ...(sortOrder !== undefined ? { sort_order: sortOrder } : {}),
        ...(startAt !== undefined ? { start_at: startAt } : {}),
        ...(endAt !== undefined ? { end_at: endAt } : {}),
        ...(isActive !== undefined ? { is_active: isActive } : {}),
        updated_at: new Date(),
      },
      select: bannerSelect,
    });

    res.json({
      success: true,
      message: "Banner updated successfully",
      data: {
        banner: toBannerResponse(banner),
      },
    });
  } catch (error) {
    next(error);
  }
});

bannerRouter.patch("/:id/inactivate", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid banner id",
      });
      return;
    }

    const banner = await prisma.banner.update({
      where: { id },
      data: {
        is_active: false,
        updated_at: new Date(),
      },
      select: bannerSelect,
    });

    res.json({
      success: true,
      message: "Banner inactivated successfully",
      data: {
        banner: toBannerResponse(banner),
      },
    });
  } catch (error) {
    next(error);
  }
});
