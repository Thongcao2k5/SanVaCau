import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const newsRouter = Router();

type NewsRow = {
  id: bigint;
  title: string;
  summary: string | null;
  content: string;
  thumbnail_url: string | null;
  author_user_id: bigint;
  branch_id: bigint | null;
  status: string;
  published_at: Date | null;
  created_at: Date;
  updated_at: Date;
  app_user: {
    id: bigint;
    full_name: string;
  };
  branch: {
    id: bigint;
    name: string;
  } | null;
};

const newsSelect = {
  id: true,
  title: true,
  summary: true,
  content: true,
  thumbnail_url: true,
  author_user_id: true,
  branch_id: true,
  status: true,
  published_at: true,
  created_at: true,
  updated_at: true,
  app_user: {
    select: {
      id: true,
      full_name: true,
    },
  },
  branch: {
    select: {
      id: true,
      name: true,
    },
  },
} as const;

const parseBigIntId = (value: string | string[] | undefined) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const parseLimit = (value: string | string[] | undefined, defaultValue = 10) => {
  if (value === undefined) {
    return defaultValue;
  }

  const limit = typeof value === "string" ? Number(value) : NaN;
  return Number.isInteger(limit) && limit > 0 && limit <= 50 ? limit : null;
};

const toNewsResponse = (news: NewsRow) => ({
  id: news.id.toString(),
  title: news.title,
  summary: news.summary,
  content: news.content,
  thumbnailUrl: news.thumbnail_url,
  authorUserId: news.author_user_id.toString(),
  branchId: news.branch_id?.toString() ?? null,
  status: news.status,
  publishedAt: news.published_at,
  createdAt: news.created_at,
  updatedAt: news.updated_at,
  author: {
    id: news.app_user.id.toString(),
    fullName: news.app_user.full_name,
  },
  branch: news.branch
    ? {
        id: news.branch.id.toString(),
        name: news.branch.name,
      }
    : null,
});

const getAuthUserId = (user: unknown) => {
  const id = (user as { id?: unknown } | undefined)?.id;

  if (typeof id === "string" && /^\d+$/.test(id)) {
    return BigInt(id);
  }

  if (typeof id === "number" && Number.isInteger(id) && id > 0) {
    return BigInt(id);
  }

  return null;
};

newsRouter.get("/", async (req, res, next) => {
  try {
    const limit = parseLimit(typeof req.query.limit === "string" ? req.query.limit : req.query.limit === undefined ? undefined : "");

    if (!limit) {
      res.status(400).json({
        success: false,
        message: "limit is invalid",
      });
      return;
    }

    const status = typeof req.query.status === "string" ? req.query.status.trim().toUpperCase() : "PUBLISHED";
    const branchId =
      req.query.branchId === undefined
        ? null
        : typeof req.query.branchId === "string"
          ? parseBigIntId(req.query.branchId)
          : null;

    if (!["DRAFT", "PUBLISHED", "ARCHIVED"].includes(status)) {
      res.status(400).json({
        success: false,
        message: "status is invalid",
      });
      return;
    }

    if (req.query.branchId !== undefined && !branchId) {
      res.status(400).json({
        success: false,
        message: "branchId is invalid",
      });
      return;
    }

    const news = await prisma.news.findMany({
      where: {
        status,
        ...(branchId ? { branch_id: branchId } : {}),
      },
      orderBy: [{ published_at: "desc" }, { created_at: "desc" }],
      take: limit,
      select: newsSelect,
    });

    res.json({
      success: true,
      data: {
        news: news.map(toNewsResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

newsRouter.get("/:id", async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid news id",
      });
      return;
    }

    const news = await prisma.news.findUnique({
      where: { id },
      select: newsSelect,
    });

    if (!news || news.status !== "PUBLISHED") {
      res.status(404).json({
        success: false,
        message: "news not found",
      });
      return;
    }

    res.json({
      success: true,
      data: {
        news: toNewsResponse(news),
      },
    });
  } catch (error) {
    next(error);
  }
});

newsRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const authorUserId = getAuthUserId(req.user);
    const title = typeof req.body?.title === "string" ? req.body.title.trim() : "";
    const summary = typeof req.body?.summary === "string" ? req.body.summary.trim() : null;
    const content = typeof req.body?.content === "string" ? req.body.content.trim() : "";
    const thumbnailUrl = typeof req.body?.thumbnailUrl === "string" ? req.body.thumbnailUrl.trim() : null;
    const branchId = req.body?.branchId === null || req.body?.branchId === undefined ? null : parseBigIntId(String(req.body.branchId));

    if (!authorUserId) {
      res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
      return;
    }

    if (!title || !content) {
      res.status(400).json({
        success: false,
        message: "title and content are required",
      });
      return;
    }

    if (req.body?.branchId !== null && req.body?.branchId !== undefined && !branchId) {
      res.status(400).json({
        success: false,
        message: "branchId is invalid",
      });
      return;
    }

    const news = await prisma.news.create({
      data: {
        title,
        summary,
        content,
        thumbnail_url: thumbnailUrl,
        author_user_id: authorUserId,
        branch_id: branchId,
        status: "DRAFT",
      },
      select: newsSelect,
    });

    res.status(201).json({
      success: true,
      message: "News created successfully",
      data: {
        news: toNewsResponse(news),
      },
    });
  } catch (error) {
    next(error);
  }
});

newsRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid news id",
      });
      return;
    }

    const title = typeof req.body?.title === "string" ? req.body.title.trim() : undefined;
    const summary =
      req.body?.summary === null ? null : typeof req.body?.summary === "string" ? req.body.summary.trim() : undefined;
    const content = typeof req.body?.content === "string" ? req.body.content.trim() : undefined;
    const thumbnailUrl =
      req.body?.thumbnailUrl === null
        ? null
        : typeof req.body?.thumbnailUrl === "string"
          ? req.body.thumbnailUrl.trim()
          : undefined;
    const branchId =
      req.body?.branchId === undefined
        ? undefined
        : req.body.branchId === null
          ? null
          : parseBigIntId(String(req.body.branchId));

    if (title === "" || content === "") {
      res.status(400).json({
        success: false,
        message: "title and content cannot be empty",
      });
      return;
    }

    if (req.body?.branchId !== undefined && req.body.branchId !== null && !branchId) {
      res.status(400).json({
        success: false,
        message: "branchId is invalid",
      });
      return;
    }

    const news = await prisma.news.update({
      where: { id },
      data: {
        ...(title !== undefined ? { title } : {}),
        ...(summary !== undefined ? { summary } : {}),
        ...(content !== undefined ? { content } : {}),
        ...(thumbnailUrl !== undefined ? { thumbnail_url: thumbnailUrl } : {}),
        ...(branchId !== undefined ? { branch_id: branchId } : {}),
        updated_at: new Date(),
      },
      select: newsSelect,
    });

    res.json({
      success: true,
      message: "News updated successfully",
      data: {
        news: toNewsResponse(news),
      },
    });
  } catch (error) {
    next(error);
  }
});

newsRouter.patch("/:id/publish", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid news id",
      });
      return;
    }

    const news = await prisma.news.update({
      where: { id },
      data: {
        status: "PUBLISHED",
        published_at: new Date(),
        updated_at: new Date(),
      },
      select: newsSelect,
    });

    res.json({
      success: true,
      message: "News published successfully",
      data: {
        news: toNewsResponse(news),
      },
    });
  } catch (error) {
    next(error);
  }
});

newsRouter.patch("/:id/archive", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid news id",
      });
      return;
    }

    const news = await prisma.news.update({
      where: { id },
      data: {
        status: "ARCHIVED",
        updated_at: new Date(),
      },
      select: newsSelect,
    });

    res.json({
      success: true,
      message: "News archived successfully",
      data: {
        news: toNewsResponse(news),
      },
    });
  } catch (error) {
    next(error);
  }
});
