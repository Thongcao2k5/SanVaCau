import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { Prisma } from "@prisma/client";

export const searchRouter = Router();

const VALID_TYPES = ["ALL", "PRODUCT", "COURT", "BRANCH", "NEWS"] as const;
type SearchType = (typeof VALID_TYPES)[number];

interface SearchResultItem {
  type: Exclude<SearchType, "ALL">;
  id: string;
  title: string;
  subtitle: string;
  imageUrl: string | null;
  metadata: Record<string, unknown>;
}

const buildPagination = (page: number, limit: number, total: number) => ({
  page,
  limit,
  total,
  totalPages: Math.ceil(total / limit),
});

const parsePage = (value: unknown) => Math.max(1, parseInt(value as string) || 1);
const parseLimit = (value: unknown) => Math.min(50, Math.max(1, parseInt(value as string) || 20));

searchRouter.get("/", async (req, res, next) => {
  try {
    const rawQ = typeof req.query.q === "string" ? req.query.q.trim() : "";
    if (rawQ.length < 2) {
      res.status(400).json({
        success: false,
        message: "Search keyword 'q' is required and must be at least 2 characters long",
      });
      return;
    }

    const typeStr = typeof req.query.type === "string" ? req.query.type.trim().toUpperCase() : "ALL";
    if (!VALID_TYPES.includes(typeStr as SearchType)) {
      res.status(400).json({
        success: false,
        message: `type must be one of: ${VALID_TYPES.join(", ")}`,
      });
      return;
    }
    const type = typeStr as SearchType;

    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit);
    const skip = (page - 1) * limit;

    const q = rawQ;

    // Build independent queries
    const searchProduct = async (take: number, skipRec: number = 0) => {
      const where: Prisma.productWhereInput = {
        is_active: true,
        OR: [
          { name: { contains: q, mode: "insensitive" } },
          { description: { contains: q, mode: "insensitive" } },
          { brand: { name: { contains: q, mode: "insensitive" } } },
          { category: { name: { contains: q, mode: "insensitive" } } },
        ],
      };
      const [data, count] = await Promise.all([
        prisma.product.findMany({
          where,
          include: { brand: true, category: true },
          take,
          skip: skipRec,
          orderBy: { created_at: "desc" },
        }),
        prisma.product.count({ where }),
      ]);
      return {
        count,
        items: data.map((p): SearchResultItem => ({
          type: "PRODUCT",
          id: p.id.toString(),
          title: p.name,
          subtitle: `${p.brand?.name ?? "No Brand"} • ${p.category?.name ?? "No Category"}`,
          imageUrl: p.image_url,
          metadata: {
            brandId: p.brand_id?.toString() ?? null,
            brandName: p.brand?.name ?? null,
            categoryId: p.category_id.toString(),
            categoryName: p.category?.name ?? null,
            isFeatured: p.is_featured,
          },
        })),
      };
    };

    const searchCourt = async (take: number, skipRec: number = 0) => {
      const where: Prisma.courtWhereInput = {
        status: "ACTIVE",
        OR: [
          { name: { contains: q, mode: "insensitive" } },
          { description: { contains: q, mode: "insensitive" } },
          { branch: { name: { contains: q, mode: "insensitive" } } },
          { branch: { address: { contains: q, mode: "insensitive" } } },
        ],
      };
      const [data, count] = await Promise.all([
        prisma.court.findMany({
          where,
          include: { branch: true },
          take,
          skip: skipRec,
          orderBy: { id: "desc" },
        }),
        prisma.court.count({ where }),
      ]);
      return {
        count,
        items: data.map((c): SearchResultItem => ({
          type: "COURT",
          id: c.id.toString(),
          title: c.name,
          subtitle: c.branch.name,
          imageUrl: null,
          metadata: {
            branchId: c.branch.id.toString(),
            branchName: c.branch.name,
            branchAddress: c.branch.address,
            status: c.status,
          },
        })),
      };
    };

    const searchBranch = async (take: number, skipRec: number = 0) => {
      const where: Prisma.branchWhereInput = {
        status: "ACTIVE",
        OR: [
          { name: { contains: q, mode: "insensitive" } },
          { address: { contains: q, mode: "insensitive" } },
          { phone: { contains: q, mode: "insensitive" } },
        ],
      };
      const [data, count] = await Promise.all([
        prisma.branch.findMany({
          where,
          take,
          skip: skipRec,
          orderBy: { created_at: "desc" },
        }),
        prisma.branch.count({ where }),
      ]);
      return {
        count,
        items: data.map((b): SearchResultItem => ({
          type: "BRANCH",
          id: b.id.toString(),
          title: b.name,
          subtitle: b.address,
          imageUrl: null,
          metadata: {
            phone: b.phone,
            openingTime: b.opening_time.toISOString(),
            closingTime: b.closing_time.toISOString(),
            status: b.status,
          },
        })),
      };
    };

    const searchNews = async (take: number, skipRec: number = 0) => {
      const where: Prisma.newsWhereInput = {
        status: "PUBLISHED",
        published_at: { not: null, lte: new Date() },
        OR: [
          { title: { contains: q, mode: "insensitive" } },
          { summary: { contains: q, mode: "insensitive" } },
          { content: { contains: q, mode: "insensitive" } },
        ],
      };
      const [data, count] = await Promise.all([
        prisma.news.findMany({
          where,
          include: { branch: true },
          take,
          skip: skipRec,
          orderBy: { published_at: "desc" },
        }),
        prisma.news.count({ where }),
      ]);
      return {
        count,
        items: data.map((n): SearchResultItem => ({
          type: "NEWS",
          id: n.id.toString(),
          title: n.title,
          subtitle: n.summary ?? "",
          imageUrl: n.thumbnail_url,
          metadata: {
            publishedAt: n.published_at?.toISOString() ?? null,
            branchId: n.branch_id?.toString() ?? null,
            branchName: n.branch?.name ?? null,
          },
        })),
      };
    };

    // Execute based on type
    let items: SearchResultItem[] = [];
    const counts = { PRODUCT: 0, COURT: 0, BRANCH: 0, NEWS: 0 };
    let total = 0;

    if (type === "ALL") {
      // For ALL, we fetch `limit` from each type, combine and take `limit`
      // It's a simple mixed approach.
      const [prodRes, courtRes, branchRes, newsRes] = await Promise.all([
        searchProduct(limit, 0),
        searchCourt(limit, 0),
        searchBranch(limit, 0),
        searchNews(limit, 0),
      ]);

      counts.PRODUCT = prodRes.count;
      counts.COURT = courtRes.count;
      counts.BRANCH = branchRes.count;
      counts.NEWS = newsRes.count;

      // Mix items: simple interleave or just concat and sort
      // To keep it deterministic and simple, we concat and then sort by type, or just slice.
      const combined = [...prodRes.items, ...courtRes.items, ...branchRes.items, ...newsRes.items];
      
      // Simple logic: we don't do real cross-table pagination for ALL. 
      // We just return the first page of everything mixed up to `limit`.
      items = combined.slice(0, limit);
      
      total = counts.PRODUCT + counts.COURT + counts.BRANCH + counts.NEWS;

      // For ALL type, we just force page 1 since cross-pagination is complex and usually not needed in this simplified ALL view
      res.json({
        success: true,
        data: {
          query: q,
          type: "ALL",
          items,
          counts,
          pagination: buildPagination(1, limit, total),
        },
      });
      return;
    }

    // Type-specific search
    if (type === "PRODUCT") {
      const resData = await searchProduct(limit, skip);
      items = resData.items;
      total = resData.count;
      counts.PRODUCT = total;
    } else if (type === "COURT") {
      const resData = await searchCourt(limit, skip);
      items = resData.items;
      total = resData.count;
      counts.COURT = total;
    } else if (type === "BRANCH") {
      const resData = await searchBranch(limit, skip);
      items = resData.items;
      total = resData.count;
      counts.BRANCH = total;
    } else if (type === "NEWS") {
      const resData = await searchNews(limit, skip);
      items = resData.items;
      total = resData.count;
      counts.NEWS = total;
    }

    res.json({
      success: true,
      data: {
        query: q,
        type,
        items,
        counts,
        pagination: buildPagination(page, limit, total),
      },
    });
  } catch (error) {
    next(error);
  }
});
