import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const productRouter = Router();

type ProductRow = {
  id: bigint;
  category_id: bigint;
  brand_id: bigint | null;
  name: string;
  description: string | null;
  image_url: string | null;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
  category: {
    id: bigint;
    name: string;
  };
  brand: {
    id: bigint;
    name: string;
  } | null;
};

const productSelect = {
  id: true,
  category_id: true,
  brand_id: true,
  name: true,
  description: true,
  image_url: true,
  is_active: true,
  created_at: true,
  updated_at: true,
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
} as const;

const parseBigIntId = (value: string | string[] | undefined) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const parseBodyBigIntId = (value: unknown) => {
  if (typeof value === "string" && /^\d+$/.test(value)) {
    return BigInt(value);
  }

  if (typeof value === "number" && Number.isInteger(value) && value > 0) {
    return BigInt(value);
  }

  return null;
};

const toProductResponse = (product: ProductRow) => ({
  id: product.id.toString(),
  categoryId: product.category_id.toString(),
  brandId: product.brand_id?.toString() ?? null,
  name: product.name,
  description: product.description,
  imageUrl: product.image_url,
  isActive: product.is_active,
  createdAt: product.created_at,
  updatedAt: product.updated_at,
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

const findActiveCategory = (id: bigint) => {
  return prisma.category.findFirst({
    where: {
      id,
      is_active: true,
    },
    select: {
      id: true,
    },
  });
};

const findActiveBrand = (id: bigint) => {
  return prisma.brand.findFirst({
    where: {
      id,
      is_active: true,
    },
    select: {
      id: true,
    },
  });
};

productRouter.get("/", async (req, res, next) => {
  try {
    const categoryId = req.query.categoryId === undefined ? null : parseBodyBigIntId(req.query.categoryId);
    const brandId = req.query.brandId === undefined ? null : parseBodyBigIntId(req.query.brandId);

    if (req.query.categoryId !== undefined && !categoryId) {
      res.status(400).json({
        success: false,
        message: "categoryId is invalid",
      });
      return;
    }

    if (req.query.brandId !== undefined && !brandId) {
      res.status(400).json({
        success: false,
        message: "brandId is invalid",
      });
      return;
    }

    const products = await prisma.product.findMany({
      where: {
        is_active: true,
        ...(categoryId ? { category_id: categoryId } : {}),
        ...(brandId ? { brand_id: brandId } : {}),
      },
      orderBy: {
        id: "desc",
      },
      select: productSelect,
    });

    res.json({
      success: true,
      data: {
        products: products.map(toProductResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

productRouter.get("/:id", async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid product id",
      });
      return;
    }

    const product = await prisma.product.findUnique({
      where: { id },
      select: productSelect,
    });

    if (!product || !product.is_active) {
      res.status(404).json({
        success: false,
        message: "product not found",
      });
      return;
    }

    res.json({
      success: true,
      data: {
        product: toProductResponse(product),
      },
    });
  } catch (error) {
    next(error);
  }
});

productRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const categoryId = parseBodyBigIntId(req.body?.categoryId);
    const brandId =
      req.body?.brandId === null || req.body?.brandId === undefined
        ? null
        : parseBodyBigIntId(req.body.brandId);
    const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
    const description = typeof req.body?.description === "string" ? req.body.description.trim() : null;
    const imageUrl = typeof req.body?.imageUrl === "string" ? req.body.imageUrl.trim() : null;

    if (!categoryId || !name) {
      res.status(400).json({
        success: false,
        message: "categoryId and name are required",
      });
      return;
    }

    if (req.body?.brandId !== null && req.body?.brandId !== undefined && !brandId) {
      res.status(400).json({
        success: false,
        message: "brandId is invalid",
      });
      return;
    }

    const category = await findActiveCategory(categoryId);

    if (!category) {
      res.status(400).json({
        success: false,
        message: "category not found",
      });
      return;
    }

    if (brandId) {
      const brand = await findActiveBrand(brandId);

      if (!brand) {
        res.status(400).json({
          success: false,
          message: "brand not found",
        });
        return;
      }
    }

    const product = await prisma.product.create({
      data: {
        category_id: categoryId,
        brand_id: brandId,
        name,
        description,
        image_url: imageUrl,
        is_active: true,
      },
      select: productSelect,
    });

    res.status(201).json({
      success: true,
      message: "Product created successfully",
      data: {
        product: toProductResponse(product),
      },
    });
  } catch (error) {
    next(error);
  }
});

productRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid product id",
      });
      return;
    }

    const existingProduct = await prisma.product.findUnique({
      where: { id },
      select: {
        id: true,
      },
    });

    if (!existingProduct) {
      res.status(404).json({
        success: false,
        message: "product not found",
      });
      return;
    }

    const categoryId =
      req.body?.categoryId === undefined ? undefined : parseBodyBigIntId(req.body.categoryId);
    const brandId =
      req.body?.brandId === undefined
        ? undefined
        : req.body.brandId === null
          ? null
          : parseBodyBigIntId(req.body.brandId);
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

    if (req.body?.categoryId !== undefined && !categoryId) {
      res.status(400).json({
        success: false,
        message: "categoryId is invalid",
      });
      return;
    }

    if (req.body?.brandId !== undefined && req.body.brandId !== null && !brandId) {
      res.status(400).json({
        success: false,
        message: "brandId is invalid",
      });
      return;
    }

    if (categoryId) {
      const category = await findActiveCategory(categoryId);

      if (!category) {
        res.status(400).json({
          success: false,
          message: "category not found",
        });
        return;
      }
    }

    if (brandId) {
      const brand = await findActiveBrand(brandId);

      if (!brand) {
        res.status(400).json({
          success: false,
          message: "brand not found",
        });
        return;
      }
    }

    const data = {
      ...(categoryId ? { category_id: categoryId } : {}),
      ...(brandId !== undefined ? { brand_id: brandId } : {}),
      ...(name !== undefined ? { name } : {}),
      ...(description !== undefined ? { description } : {}),
      ...(imageUrl !== undefined ? { image_url: imageUrl } : {}),
      ...(isActive !== undefined ? { is_active: isActive } : {}),
      updated_at: new Date(),
    };

    const product = await prisma.product.update({
      where: { id },
      data,
      select: productSelect,
    });

    res.json({
      success: true,
      message: "Product updated successfully",
      data: {
        product: toProductResponse(product),
      },
    });
  } catch (error) {
    next(error);
  }
});

productRouter.patch("/:id/inactivate", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid product id",
      });
      return;
    }

    const product = await prisma.product.update({
      where: { id },
      data: {
        is_active: false,
        updated_at: new Date(),
      },
      select: productSelect,
    });

    res.json({
      success: true,
      message: "Product inactivated successfully",
      data: {
        product: toProductResponse(product),
      },
    });
  } catch (error) {
    next(error);
  }
});
