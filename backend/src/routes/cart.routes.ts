import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { Prisma } from "@prisma/client";

export const cartRouter = Router();

const parseBigIntId = (value: string | string[] | undefined | null) => {
  return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const cartInclude = {
  cart_item: {
    include: {
      product_variant: {
        include: {
          product: {
            include: {
              category: true,
              brand: true,
            },
          },
        },
      },
    },
  },
} satisfies Prisma.cartInclude;

type CartWithDetails = Prisma.cartGetPayload<{ include: typeof cartInclude }>;

const toCartResponse = (cart: CartWithDetails) => {
  let totalAmount = 0;
  const items = cart.cart_item.map((item) => {
    const unitPrice = Number(item.product_variant.price);
    const lineTotal = unitPrice * item.quantity;
    totalAmount += lineTotal;

    return {
      id: item.id.toString(),
      productVariantId: item.product_variant_id.toString(),
      quantity: item.quantity,
      unitPrice: unitPrice.toString(),
      lineTotal: lineTotal.toString(),
      variant: {
        id: item.product_variant.id.toString(),
        sku: item.product_variant.sku,
        variantName: item.product_variant.variant_name,
        price: unitPrice.toString(),
        imageUrl: item.product_variant.image_url,
        product: {
          id: item.product_variant.product.id.toString(),
          name: item.product_variant.product.name,
          imageUrl: item.product_variant.product.image_url,
          category: item.product_variant.product.category
            ? {
                id: item.product_variant.product.category.id.toString(),
                name: item.product_variant.product.category.name,
              }
            : null,
          brand: item.product_variant.product.brand
            ? {
                id: item.product_variant.product.brand.id.toString(),
                name: item.product_variant.product.brand.name,
              }
            : null,
        },
      },
    };
  });

  return {
    id: cart.id.toString(),
    customerId: cart.customer_id.toString(),
    updatedAt: cart.updated_at.toISOString(),
    items: items,
    totalAmount: totalAmount.toString(),
  };
};

const getOrCreateCart = async (customerId: bigint) => {
  let cart = await prisma.cart.findUnique({
    where: { customer_id: customerId },
    include: cartInclude,
  });

  if (!cart) {
    cart = await prisma.cart.create({
      data: { customer_id: customerId },
      include: cartInclude,
    });
  }

  return cart;
};

const getAvailableInventory = async (productVariantId: bigint) => {
  const inventories = await prisma.inventory.findMany({
    where: {
      product_variant_id: productVariantId,
      branch: {
        status: "ACTIVE",
      },
    },
  });

  return inventories.reduce((sum, inv) => sum + inv.quantity, 0);
};

// GET /api/cart
cartRouter.get("/", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const cart = await getOrCreateCart(customerId);
    res.json({
      success: true,
      data: { cart: toCartResponse(cart) },
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/cart/items
cartRouter.post("/items", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const productVariantId = parseBigIntId(req.body?.productVariantId);
    const quantity = req.body?.quantity;

    if (!productVariantId) {
      res.status(400).json({ success: false, message: "Invalid productVariantId" });
      return;
    }
    if (!Number.isInteger(quantity) || quantity <= 0) {
      res.status(400).json({ success: false, message: "quantity must be an integer greater than 0" });
      return;
    }

    const variant = await prisma.product_variant.findUnique({
      where: { id: productVariantId },
      include: { product: true },
    });

    if (!variant || !variant.is_active || !variant.product.is_active) {
      res.status(400).json({ success: false, message: "product variant is not available" });
      return;
    }

    const availableQuantity = await getAvailableInventory(productVariantId);
    if (availableQuantity <= 0) {
      res.status(400).json({ success: false, message: "product variant is out of stock" });
      return;
    }

    const cart = await getOrCreateCart(customerId);
    const existingItem = cart.cart_item.find((item) => item.product_variant_id === productVariantId);
    const currentQuantity = existingItem ? existingItem.quantity : 0;
    const finalQuantity = currentQuantity + quantity;

    if (finalQuantity > availableQuantity) {
      res.status(400).json({
        success: false,
        message: `cannot add ${quantity} items. Available quantity is ${availableQuantity}, and you already have ${currentQuantity} in your cart.`,
      });
      return;
    }

    await prisma.$transaction(async (tx) => {
      if (existingItem) {
        await tx.cart_item.update({
          where: { id: existingItem.id },
          data: { quantity: finalQuantity },
        });
      } else {
        await tx.cart_item.create({
          data: {
            cart_id: cart.id,
            product_variant_id: productVariantId,
            quantity: quantity,
          },
        });
      }
      await tx.cart.update({
        where: { id: cart.id },
        data: { updated_at: new Date() },
      });
    });

    const updatedCart = await getOrCreateCart(customerId);
    res.status(200).json({
      success: true,
      message: "Item added to cart",
      data: { cart: toCartResponse(updatedCart) },
    });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/cart/items/:id
cartRouter.patch("/items/:id", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const itemId = parseBigIntId(req.params.id);
    const quantity = req.body?.quantity;

    if (!itemId) {
      res.status(400).json({ success: false, message: "Invalid item id" });
      return;
    }
    if (!Number.isInteger(quantity) || quantity <= 0) {
      res.status(400).json({ success: false, message: "quantity must be an integer greater than 0" });
      return;
    }

    const cart = await getOrCreateCart(customerId);
    const existingItem = cart.cart_item.find((item) => item.id === itemId);

    if (!existingItem) {
      res.status(404).json({ success: false, message: "Item not found in your cart" });
      return;
    }

    const availableQuantity = await getAvailableInventory(existingItem.product_variant_id);
    if (quantity > availableQuantity) {
      res.status(400).json({
        success: false,
        message: `Cannot set quantity to ${quantity}. Available quantity is ${availableQuantity}.`,
      });
      return;
    }

    await prisma.$transaction(async (tx) => {
      await tx.cart_item.update({
        where: { id: existingItem.id },
        data: { quantity },
      });
      await tx.cart.update({
        where: { id: cart.id },
        data: { updated_at: new Date() },
      });
    });

    const updatedCart = await getOrCreateCart(customerId);
    res.json({
      success: true,
      message: "Cart item updated",
      data: { cart: toCartResponse(updatedCart) },
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/cart/items/:id
cartRouter.delete("/items/:id", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const itemId = parseBigIntId(req.params.id);

    if (!itemId) {
      res.status(400).json({ success: false, message: "Invalid item id" });
      return;
    }

    const cart = await getOrCreateCart(customerId);
    const existingItem = cart.cart_item.find((item) => item.id === itemId);

    if (!existingItem) {
      res.status(404).json({ success: false, message: "Item not found in your cart" });
      return;
    }

    await prisma.$transaction(async (tx) => {
      await tx.cart_item.delete({
        where: { id: existingItem.id },
      });
      await tx.cart.update({
        where: { id: cart.id },
        data: { updated_at: new Date() },
      });
    });

    const updatedCart = await getOrCreateCart(customerId);
    res.json({
      success: true,
      message: "Cart item removed",
      data: { cart: toCartResponse(updatedCart) },
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/cart
cartRouter.delete("/", requireAuth, requireRole("CUSTOMER"), async (req, res, next) => {
  try {
    const customerId = BigInt(req.user!.id);
    const cart = await getOrCreateCart(customerId);

    await prisma.$transaction(async (tx) => {
      await tx.cart_item.deleteMany({
        where: { cart_id: cart.id },
      });
      await tx.cart.update({
        where: { id: cart.id },
        data: { updated_at: new Date() },
      });
    });

    const updatedCart = await getOrCreateCart(customerId);
    res.json({
      success: true,
      message: "Cart cleared",
      data: { cart: toCartResponse(updatedCart) },
    });
  } catch (error) {
    next(error);
  }
});
