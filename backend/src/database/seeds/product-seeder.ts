import { Prisma } from "@prisma/client";
import { prisma } from "../../lib/prisma.js";
import { productCatalog } from "./product-catalog.js";

export const seedProducts = async () => {
  const skus = productCatalog.flatMap((item) => item.variants.map((variant) => variant.sku));
  if (new Set(skus).size !== skus.length || skus.some((sku) => sku.length > 80)) {
    throw new Error("Invalid or duplicate DEMO SKU in product catalog");
  }

  await prisma.$transaction(async (tx) => {
    // Serialize both seed entry points: product.name has no database unique constraint.
    await tx.$queryRaw`SELECT 1 AS locked FROM pg_advisory_xact_lock(74042801)`;
    for (const item of productCatalog) {
      const matches = await tx.product.findMany({ where: { name: item.name }, take: 2 });
      if (matches.length > 1) throw new Error(`Ambiguous product name: ${item.name}`);
      const legacy = await tx.product_variant.findUnique({
        where: { sku: item.sku }, include: { product: true },
      });
      if (legacy && (legacy.product.name !== item.name || (matches[0] && matches[0].id !== legacy.product_id))) {
        throw new Error(`SKU/product conflict: ${item.sku}`);
      }
      let product = legacy?.product ?? matches[0];
      if (!product) {
        const categories = await tx.category.findMany({ where: { name: item.category }, take: 2 });
        const brand = await tx.brand.findUnique({ where: { name: item.brand } });
        if (categories.length !== 1 || !brand) throw new Error(`Missing/ambiguous category or brand: ${item.name}`);
        product = await tx.product.create({
          data: {
            name: item.name, category_id: categories[0].id, brand_id: brand.id,
            description: `Sản phẩm demo ${item.name} cho SanVaCau.`,
            image_url: item.imageUrl, is_active: true, is_featured: item.featured,
          },
        });
      }
      for (const variant of item.variants) {
        const existing = await tx.product_variant.findUnique({ where: { sku: variant.sku } });
        if (existing) {
          if (existing.product_id !== product.id) throw new Error(`SKU/product conflict: ${variant.sku}`);
          continue; // Preserve every existing field and inventory, including the legacy variant.
        }
        await tx.product_variant.create({
          data: {
            product_id: product.id, sku: variant.sku, variant_name: variant.variantName,
            price: new Prisma.Decimal(variant.price), image_url: item.imageUrl,
            is_active: true,
            inventory: { create: { quantity: variant.quantity } },
          },
        });
      }
    }
  }, { maxWait: 10000, timeout: 30000 });
  console.log("[seed] DEMO products and variants done; existing data preserved");
};

// Compatibility with both entry points. New inventory is created atomically with
// its variant above; existing variants (even those without inventory) stay untouched.
export const seedInventory = async () => {
  console.log("[seed] DEMO inventory initialized with new variants; existing inventory preserved");
};
