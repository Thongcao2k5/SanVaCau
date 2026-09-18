import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";

export const inventoryRouter = Router();

type InventoryRow = {
  id: bigint;
  branch_id: bigint;
  product_variant_id: bigint;
  quantity: number;
  updated_at: Date;
  branch: {
    id: bigint;
    name: string;
  };
  product_variant: {
    id: bigint;
    sku: string;
    variant_name: string;
    product: {
      id: bigint;
      name: string;
    };
  };
};

const inventorySelect = {
  id: true,
  branch_id: true,
  product_variant_id: true,
  quantity: true,
  updated_at: true,
  branch: {
    select: {
      id: true,
      name: true,
    },
  },
  product_variant: {
    select: {
      id: true,
      sku: true,
      variant_name: true,
      product: {
        select: {
          id: true,
          name: true,
        },
      },
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

const parseQuantity = (value: unknown) => {
  const quantity = typeof value === "number" ? value : typeof value === "string" ? Number(value) : NaN;

  return Number.isInteger(quantity) && quantity >= 0 ? quantity : null;
};

const toInventoryResponse = (inventory: InventoryRow) => ({
  id: inventory.id.toString(),
  branchId: inventory.branch_id.toString(),
  productVariantId: inventory.product_variant_id.toString(),
  quantity: inventory.quantity,
  updatedAt: inventory.updated_at,
  branch: {
    id: inventory.branch.id.toString(),
    name: inventory.branch.name,
  },
  productVariant: {
    id: inventory.product_variant.id.toString(),
    sku: inventory.product_variant.sku,
    variantName: inventory.product_variant.variant_name,
    product: {
      id: inventory.product_variant.product.id.toString(),
      name: inventory.product_variant.product.name,
    },
  },
});

const findActiveBranch = (id: bigint) => {
  return prisma.branch.findFirst({
    where: {
      id,
      status: "ACTIVE",
    },
    select: {
      id: true,
    },
  });
};

const findActiveProductVariant = (id: bigint) => {
  return prisma.product_variant.findFirst({
    where: {
      id,
      is_active: true,
      product: {
        is_active: true,
      },
    },
    select: {
      id: true,
    },
  });
};

inventoryRouter.get("/", async (req, res, next) => {
  try {
    const branchId = req.query.branchId === undefined ? null : parseBodyBigIntId(req.query.branchId);
    const productVariantId =
      req.query.productVariantId === undefined ? null : parseBodyBigIntId(req.query.productVariantId);

    if (req.query.branchId !== undefined && !branchId) {
      res.status(400).json({
        success: false,
        message: "branchId is invalid",
      });
      return;
    }

    if (req.query.productVariantId !== undefined && !productVariantId) {
      res.status(400).json({
        success: false,
        message: "productVariantId is invalid",
      });
      return;
    }

    const inventories = await prisma.inventory.findMany({
      where: {
        branch: {
          status: "ACTIVE",
        },
        product_variant: {
          is_active: true,
          product: {
            is_active: true,
          },
        },
        ...(branchId ? { branch_id: branchId } : {}),
        ...(productVariantId ? { product_variant_id: productVariantId } : {}),
      },
      orderBy: {
        id: "desc",
      },
      select: inventorySelect,
    });

    res.json({
      success: true,
      data: {
        inventories: inventories.map(toInventoryResponse),
      },
    });
  } catch (error) {
    next(error);
  }
});

inventoryRouter.get("/:id", async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid inventory id",
      });
      return;
    }

    const inventory = await prisma.inventory.findUnique({
      where: { id },
      select: inventorySelect,
    });

    if (!inventory) {
      res.status(404).json({
        success: false,
        message: "inventory not found",
      });
      return;
    }

    res.json({
      success: true,
      data: {
        inventory: toInventoryResponse(inventory),
      },
    });
  } catch (error) {
    next(error);
  }
});

inventoryRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const branchId = parseBodyBigIntId(req.body?.branchId);
    const productVariantId = parseBodyBigIntId(req.body?.productVariantId);
    const quantity = parseQuantity(req.body?.quantity);

    if (!branchId || !productVariantId || quantity === null) {
      res.status(400).json({
        success: false,
        message: "branchId, productVariantId and quantity are required",
      });
      return;
    }

    const branch = await findActiveBranch(branchId);

    if (!branch) {
      res.status(400).json({
        success: false,
        message: "branch not found",
      });
      return;
    }

    const productVariant = await findActiveProductVariant(productVariantId);

    if (!productVariant) {
      res.status(400).json({
        success: false,
        message: "product variant not found",
      });
      return;
    }

    const existingInventory = await prisma.inventory.findUnique({
      where: {
        branch_id_product_variant_id: {
          branch_id: branchId,
          product_variant_id: productVariantId,
        },
      },
      select: {
        id: true,
      },
    });

    if (existingInventory) {
      res.status(409).json({
        success: false,
        message: "inventory already exists",
      });
      return;
    }

    const inventory = await prisma.inventory.create({
      data: {
        branch_id: branchId,
        product_variant_id: productVariantId,
        quantity,
        updated_at: new Date(),
      },
      select: inventorySelect,
    });

    res.status(201).json({
      success: true,
      message: "Inventory created successfully",
      data: {
        inventory: toInventoryResponse(inventory),
      },
    });
  } catch (error) {
    next(error);
  }
});

inventoryRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const id = parseBigIntId(req.params.id);

    if (!id) {
      res.status(400).json({
        success: false,
        message: "invalid inventory id",
      });
      return;
    }

    const quantity = parseQuantity(req.body?.quantity);

    if (quantity === null) {
      res.status(400).json({
        success: false,
        message: "quantity is required",
      });
      return;
    }

    const existingInventory = await prisma.inventory.findUnique({
      where: { id },
      select: {
        id: true,
      },
    });

    if (!existingInventory) {
      res.status(404).json({
        success: false,
        message: "inventory not found",
      });
      return;
    }

    const inventory = await prisma.inventory.update({
      where: { id },
      data: {
        quantity,
        updated_at: new Date(),
      },
      select: inventorySelect,
    });

    res.json({
      success: true,
      message: "Inventory updated successfully",
      data: {
        inventory: toInventoryResponse(inventory),
      },
    });
  } catch (error) {
    next(error);
  }
});
