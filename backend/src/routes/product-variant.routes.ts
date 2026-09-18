import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const productVariantRouter = Router();

type ProductVariantRow = {
  id: bigint;
  product_id: bigint;
  sku: string;
  variant_name: string;
  price: { toString: () => string };
  image_url: string | null;
  is_active: boolean;
  product: {
    id: bigint;
    name: string;
  };
};

const productVariantSelect = {
  id: true,
  product_id: true,
  sku: true,
  variant_name: true,
  price: true,
  image_url: true,
  is_active: true,
  product: {
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

const parsePrice = (value: unknown) => {
  const price = typeof value === "number" ? value : typeof value === "string" ? Number(value) : NaN;

  return Number.isFinite(price) && price > 0 ? price : null;
};

const toProductVariantResponse = (variant: ProductVariantRow) => ({
  id: variant.id.toString(),
  productId: variant.product_id.toString(),
  sku: variant.sku,
  variantName: variant.variant_name,
  price: variant.price.toString(),
  imageUrl: variant.image_url,
  isActive: variant.is_active,
  product: {
    id: variant.product.id.toString(),
    name: variant.product.name,
  },
});

const findActiveProduct = (id: bigint) => {
  return prisma.product.findFirst({
    where: {
      id,
      is_active: true,
    },
    select: {
      id: true,
    },
  });
};

productVariantRouter.get("/", async (req, res, next) => {
  try {
    const productId = req.query.productId === undefined ? null : parseBodyBigIntId(req.query.productId);

    if (req.query.productId !== undefined && !productId) {
      res.status(400).json({
        success: false,
        message: "productId is invalid",
      });
      return;
    }

    const variants = await prisma.product_variant.findMany({
      where: {
        is_active: true,
        product: {
          is_active: true,
        },
        ...(productId ? { product_id: productId } : {}),
      },
      orderBy: {
        id: "desc",
      },
      select: productVariantSelect,
    });

    res.json({
      success: true,
      data: {
        variants: variants.map(toProductVariantResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

productVariantRouter.get("/:id", async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid product variant id",
      });
      return;
    }

    const variant = await prisma.product_variant.findUnique({
      where: { id },
      select: productVariantSelect,
    });

    if (!variant || !variant.is_active) {
      res.status(404).json({
        success: false,
        message: "product variant not found",
      });
      return;
    }

    const product = await findActiveProduct(variant.product_id);

    if (!product) {
      res.status(404).json({
        success: false,
        message: "product variant not found",
      });
      return;
    }

    res.json({
      success: true,
      data: {
        variant: toProductVariantResponse(variant),
      },
    });
  } catch (error) {
    next(error);
  }
});

productVariantRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const productId = parseBodyBigIntId(req.body?.productId);
    const sku = typeof req.body?.sku === "string" ? req.body.sku.trim() : "";
    const variantName = typeof req.body?.variantName === "string" ? req.body.variantName.trim() : "";
    const price = parsePrice(req.body?.price);
    const imageUrl = typeof req.body?.imageUrl === "string" ? req.body.imageUrl.trim() : null;

    if (!productId || !sku || !variantName || !price) {
      res.status(400).json({
        success: false,
        message: "productId, sku, variantName and price are required",
      });
      return;
    }

    const product = await findActiveProduct(productId);

    if (!product) {
      res.status(400).json({
        success: false,
        message: "product not found",
      });
      return;
    }

    const existingVariant = await prisma.product_variant.findUnique({
      where: { sku },
      select: {
        id: true,
      },
    });

    if (existingVariant) {
      res.status(409).json({
        success: false,
        message: "sku already exists",
      });
      return;
    }

    const variant = await prisma.product_variant.create({
      data: {
        product_id: productId,
        sku,
        variant_name: variantName,
        price,
        image_url: imageUrl,
        is_active: true,
      },
      select: productVariantSelect,
    });

    res.status(201).json({
      success: true,
      message: "Product variant created successfully",
      data: {
        variant: toProductVariantResponse(variant),
      },
    });
  } catch (error) {
    next(error);
  }
});

productVariantRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid product variant id",
      });
      return;
    }

    const existingVariant = await prisma.product_variant.findUnique({
      where: { id },
      select: {
        id: true,
      },
    });

    if (!existingVariant) {
      res.status(404).json({
        success: false,
        message: "product variant not found",
      });
      return;
    }

    const productId =
      req.body?.productId === undefined ? undefined : parseBodyBigIntId(req.body.productId);
    const sku = typeof req.body?.sku === "string" ? req.body.sku.trim() : undefined;
    const variantName =
      typeof req.body?.variantName === "string" ? req.body.variantName.trim() : undefined;
    const price = req.body?.price === undefined ? undefined : parsePrice(req.body.price);
    const imageUrl =
      req.body?.imageUrl === null
        ? null
        : typeof req.body?.imageUrl === "string"
          ? req.body.imageUrl.trim()
          : undefined;
    const isActive = typeof req.body?.isActive === "boolean" ? req.body.isActive : undefined;

    if (req.body?.productId !== undefined && !productId) {
      res.status(400).json({
        success: false,
        message: "productId is invalid",
      });
      return;
    }

    if (sku === "") {
      res.status(400).json({
        success: false,
        message: "sku cannot be empty",
      });
      return;
    }

    if (variantName === "") {
      res.status(400).json({
        success: false,
        message: "variantName cannot be empty",
      });
      return;
    }

    if (req.body?.price !== undefined && !price) {
      res.status(400).json({
        success: false,
        message: "price is invalid",
      });
      return;
    }

    if (productId) {
      const product = await findActiveProduct(productId);

      if (!product) {
        res.status(400).json({
          success: false,
          message: "product not found",
        });
        return;
      }
    }

    if (sku !== undefined) {
      const duplicatedVariant = await prisma.product_variant.findUnique({
        where: { sku },
        select: {
          id: true,
        },
      });

      if (duplicatedVariant && duplicatedVariant.id !== id) {
        res.status(409).json({
          success: false,
          message: "sku already exists",
        });
        return;
      }
    }

    const data = {
      ...(productId ? { product_id: productId } : {}),
      ...(sku !== undefined ? { sku } : {}),
      ...(variantName !== undefined ? { variant_name: variantName } : {}),
      ...(price !== undefined && price !== null ? { price } : {}),
      ...(imageUrl !== undefined ? { image_url: imageUrl } : {}),
      ...(isActive !== undefined ? { is_active: isActive } : {}),
    };

    const variant = await prisma.product_variant.update({
      where: { id },
      data,
      select: productVariantSelect,
    });

    res.json({
      success: true,
      message: "Product variant updated successfully",
      data: {
        variant: toProductVariantResponse(variant),
      },
    });
  } catch (error) {
    next(error);
  }
});

productVariantRouter.patch("/:id/inactivate", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid product variant id",
      });
      return;
    }

    const variant = await prisma.product_variant.update({
      where: { id },
      data: {
        is_active: false,
      },
      select: productVariantSelect,
    });

    res.json({
      success: true,
      message: "Product variant inactivated successfully",
      data: {
        variant: toProductVariantResponse(variant),
      },
    });
  } catch (error) {
    next(error);
  }
});
