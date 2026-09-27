import { Router, type Request, type Response, type NextFunction } from "express";
import { Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma.js";

export const bootstrapRouter = Router();

const parseBigIntId = (value: unknown) => {
  if (typeof value !== "string" || !/^\d+$/.test(value)) {
    return null;
  }
  return BigInt(value);
};

bootstrapRouter.get("/", async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    let branchId: bigint | null = null;
    
    // Validate branchId
    if (req.query.branchId) {
      branchId = parseBigIntId(req.query.branchId);
      if (branchId === null) {
        res.status(400).json({ success: false, message: "Invalid branchId format" });
        return;
      }
      
      const branchExists = await prisma.branch.findUnique({
        where: { id: branchId },
      });
      
      if (!branchExists || branchExists.status !== "ACTIVE") {
        res.status(404).json({ success: false, message: "Branch not found or inactive" });
        return;
      }
    }

    // A. Settings
    const settingsRaw = await prisma.system_setting.findMany({
      where: { is_public: true },
    });
    
    const settings: Record<string, unknown> = {};
    for (const setting of settingsRaw) {
      settings[setting.key] = setting.value;
    }

    // B. Banners
    const now = new Date();
    const bannersRaw = await prisma.banner.findMany({
      where: { 
        is_active: true,
        OR: [
          { start_at: null },
          { start_at: { lte: now } }
        ],
        AND: [
          {
            OR: [
              { end_at: null },
              { end_at: { gte: now } }
            ]
          }
        ]
      },
      orderBy: [
        { sort_order: "asc" },
        { created_at: "desc" }
      ],
      take: 10,
    });
    
    const banners = bannersRaw.map(b => ({
      id: b.id.toString(),
      title: b.title,
      imageUrl: b.image_url,
      linkUrl: b.link_url,
      sortOrder: b.sort_order,
      startAt: b.start_at?.toISOString() || null,
      endAt: b.end_at?.toISOString() || null,
      isActive: b.is_active,
    }));

    // C. Categories
    const categoriesRaw = await prisma.category.findMany({
      where: { is_active: true },
      orderBy: { sort_order: "asc" },
    });
    
    type CategoryNode = {
      id: string;
      name: string;
      parentId: string | null;
      description: string | null;
      sortOrder: number;
      children: CategoryNode[];
    };
    
    const categoriesMap = new Map<string, CategoryNode>();
    categoriesRaw.forEach(c => {
      categoriesMap.set(c.id.toString(), {
        id: c.id.toString(),
        name: c.name,
        parentId: c.parent_id?.toString() || null,
        description: c.description,
        sortOrder: c.sort_order,
        children: []
      });
    });
    
    const categories: CategoryNode[] = [];
    categoriesMap.forEach(cat => {
      if (cat.parentId && categoriesMap.has(cat.parentId)) {
        categoriesMap.get(cat.parentId)!.children.push(cat);
      } else {
        categories.push(cat);
      }
    });

    // D. Branches
    const branchesRaw = await prisma.branch.findMany({
      where: { status: "ACTIVE" },
      orderBy: { created_at: "asc" },
    });
    
    const branches = branchesRaw.map(b => ({
      id: b.id.toString(),
      name: b.name,
      address: b.address,
      phone: b.phone,
      openingTime: b.opening_time.toISOString(),
      closingTime: b.closing_time.toISOString(),
    }));

    // E. Latest News
    const newsWhere: Prisma.newsWhereInput = {
      status: "PUBLISHED",
      published_at: { lte: now }
    };
    
    if (branchId !== null) {
      newsWhere.OR = [
        { branch_id: null },
        { branch_id: branchId }
      ];
    }
    
    const latestNewsRaw = await prisma.news.findMany({
      where: newsWhere,
      orderBy: { published_at: "desc" },
      take: 5,
    });
    
    const latestNews = latestNewsRaw.map(n => ({
      id: n.id.toString(),
      title: n.title,
      summary: n.summary,
      thumbnailUrl: n.thumbnail_url,
      branchId: n.branch_id?.toString() || null,
      publishedAt: n.published_at?.toISOString() || null,
    }));

    // F. Featured Products
    const productsRaw = await prisma.product.findMany({
      where: { is_active: true },
      orderBy: [
        { is_featured: "desc" },
        { created_at: "desc" }
      ],
      take: 10,
      include: {
        category: true,
        brand: true,
        product_variant: {
          where: { is_active: true },
          select: { price: true }
        }
      }
    });
    
    const featuredProducts = productsRaw.map(p => {
      let minPrice: string | null = null;
      if (p.product_variant.length > 0) {
        const prices = p.product_variant.map(v => v.price);
        const lowestPrice = prices.reduce((lowest, current) => current.lessThan(lowest) ? current : lowest, prices[0]);
        minPrice = lowestPrice.toString();
      }
      
      return {
        id: p.id.toString(),
        name: p.name,
        thumbnailUrl: p.image_url,
        categoryName: p.category?.name || null,
        brandName: p.brand?.name || null,
        minPrice,
      };
    });

    res.json({
      success: true,
      data: {
        settings,
        banners,
        categories,
        branches,
        latestNews,
        featuredProducts
      }
    });
  } catch (error) {
    next(error);
  }
});
