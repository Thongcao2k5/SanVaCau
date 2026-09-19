import { Router } from "express";
import { prisma } from "../lib/prisma.js";

export const homeRouter = Router();

const toBannerResponse = (banner: {
  id: bigint;
  title: string | null;
  image_url: string;
  link_url: string | null;
  sort_order: number;
}) => ({
  id: banner.id.toString(),
  title: banner.title,
  imageUrl: banner.image_url,
  linkUrl: banner.link_url,
  sortOrder: banner.sort_order,
});

const toProductResponse = (product: {
  id: bigint;
  category_id: bigint;
  brand_id: bigint | null;
  name: string;
  description: string | null;
  image_url: string | null;
  is_featured: boolean;
  category: {
    id: bigint;
    name: string;
  };
  brand: {
    id: bigint;
    name: string;
  } | null;
}) => ({
  id: product.id.toString(),
  categoryId: product.category_id.toString(),
  brandId: product.brand_id?.toString() ?? null,
  name: product.name,
  description: product.description,
  imageUrl: product.image_url,
  isFeatured: product.is_featured,
  category: {
    id: product.category.id.toString(),
    name: product.category.name,
  },
  brand: product.brand
    ? {
        id: product.brand.id.toString(),
        name: product.brand.name,
      }
    : null,
});

const toNewsResponse = (news: {
  id: bigint;
  title: string;
  summary: string | null;
  thumbnail_url: string | null;
  published_at: Date | null;
  branch: {
    id: bigint;
    name: string;
  } | null;
}) => ({
  id: news.id.toString(),
  title: news.title,
  summary: news.summary,
  thumbnailUrl: news.thumbnail_url,
  publishedAt: news.published_at,
  branch: news.branch
    ? {
        id: news.branch.id.toString(),
        name: news.branch.name,
      }
    : null,
});

const formatTime = (value: Date) => {
  return value.toISOString().slice(11, 19);
};

const toBranchResponse = (branch: {
  id: bigint;
  name: string;
  address: string;
  phone: string | null;
  opening_time: Date;
  closing_time: Date;
  status: string;
}) => ({
  id: branch.id.toString(),
  name: branch.name,
  address: branch.address,
  phone: branch.phone,
  openingTime: formatTime(branch.opening_time),
  closingTime: formatTime(branch.closing_time),
  status: branch.status,
});

homeRouter.get("/", async (_req, res, next) => {
  try {
    const now = new Date();

    const [banners, featuredProducts, latestNews, branches] = await Promise.all([
      prisma.banner.findMany({
        where: {
          is_active: true,
          OR: [{ start_at: null }, { start_at: { lte: now } }],
          AND: [{ OR: [{ end_at: null }, { end_at: { gte: now } }] }],
        },
        orderBy: [{ sort_order: "asc" }, { id: "desc" }],
        take: 5,
        select: {
          id: true,
          title: true,
          image_url: true,
          link_url: true,
          sort_order: true,
        },
      }),
      prisma.product.findMany({
        where: {
          is_active: true,
          is_featured: true,
        },
        orderBy: [{ updated_at: "desc" }, { id: "desc" }],
        take: 8,
        select: {
          id: true,
          category_id: true,
          brand_id: true,
          name: true,
          description: true,
          image_url: true,
          is_featured: true,
          category: {
            select: {
              id: true,
              name: true,
            },
          },
          brand: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      prisma.news.findMany({
        where: {
          status: "PUBLISHED",
        },
        orderBy: [{ published_at: "desc" }, { created_at: "desc" }],
        take: 5,
        select: {
          id: true,
          title: true,
          summary: true,
          thumbnail_url: true,
          published_at: true,
          branch: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      prisma.branch.findMany({
        where: {
          status: "ACTIVE",
        },
        orderBy: {
          id: "asc",
        },
        take: 5,
        select: {
          id: true,
          name: true,
          address: true,
          phone: true,
          opening_time: true,
          closing_time: true,
          status: true,
        },
      }),
    ]);

    res.json({
      success: true,
      data: {
        banners: banners.map(toBannerResponse),
        featuredProducts: featuredProducts.map(toProductResponse),
        latestNews: latestNews.map(toNewsResponse),
        branches: branches.map(toBranchResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});
