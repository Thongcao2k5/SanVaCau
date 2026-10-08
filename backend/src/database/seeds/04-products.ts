import { PrismaClient, Prisma } from "@prisma/client";
import { hashPassword } from "../../lib/auth.js";
import { prisma } from "../../lib/prisma.js";

const timeOfDay = (hhmm: string) => new Date(`1970-01-01T${hhmm}:00.000Z`);

const upsertByNaturalKey = async <T>(
  find: () => Promise<T | null>,
  create: () => Promise<T>,
  update: (existing: T) => Promise<T>,
) => {
  const existing = await find();
  return existing ? update(existing) : create();
};



const seedCategories = async () => {
  const rootCategories = [
    { name: "Vợt cầu lông", sortOrder: 1 },
    { name: "Giày cầu lông", sortOrder: 2 },
    { name: "Áo thể thao", sortOrder: 3 },
    { name: "Phụ kiện", sortOrder: 4 },
  ];

  const roots = new Map<string, bigint>();

  for (const category of rootCategories) {
    const saved = await upsertByNaturalKey(
      () => prisma.category.findFirst({ where: { name: category.name, parent_id: null } }),
      () =>
        prisma.category.create({
          data: {
            name: category.name,
            parent_id: null,
            description: `Danh mục demo ${category.name}`,
            sort_order: category.sortOrder,
            is_active: true,
          },
        }),
      (existing) =>
        prisma.category.update({
          where: { id: existing.id },
          data: {
            description: `Danh mục demo ${category.name}`,
            sort_order: category.sortOrder,
            is_active: true,
          },
        }),
    );
    roots.set(category.name, saved.id);
  }

  const racketRootId = roots.get("Vợt cầu lông");
  if (racketRootId) {
    const children = [
      { name: "Vợt Yonex", sortOrder: 1 },
      { name: "Vợt Lining", sortOrder: 2 },
    ];

    for (const child of children) {
      await upsertByNaturalKey(
        () => prisma.category.findFirst({ where: { name: child.name, parent_id: racketRootId } }),
        () =>
          prisma.category.create({
            data: {
              name: child.name,
              parent_id: racketRootId,
              description: `Danh mục demo ${child.name}`,
              sort_order: child.sortOrder,
              is_active: true,
            },
          }),
        (existing) =>
          prisma.category.update({
            where: { id: existing.id },
            data: {
              description: `Danh mục demo ${child.name}`,
              sort_order: child.sortOrder,
              is_active: true,
            },
          }),
      );
    }
  }

  console.log("[seed] categories done");
};

const seedBrands = async () => {
  for (const name of ["Yonex", "Lining", "Victor", "Kawasaki", "SanVaCau"]) {
    await prisma.brand.upsert({
      where: { name },
      update: {
        description: `Thương hiệu demo ${name}`,
        is_active: true,
      },
      create: {
        name,
        description: `Thương hiệu demo ${name}`,
        is_active: true,
      },
    });
  }

  console.log("[seed] brands done");
};

const getCategoryId = async (name: string) => {
  const category = await prisma.category.findFirst({ where: { name, is_active: true } });
  if (!category) throw new Error(`Missing category: ${name}`);
  return category.id;
};

const getBrandId = async (name: string) => {
  const brand = await prisma.brand.findUnique({ where: { name } });
  if (!brand) throw new Error(`Missing brand: ${name}`);
  return brand.id;
};

const seedProducts = async () => {
  const products = [
    {
      name: "Yonex Astrox 88D Game",
      category: "Vợt Yonex",
      brand: "Yonex",
      price: "2350000",
      sku: "DEMO-YONEX-AX88D-GAME",
      imageUrl: "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=800&q=80",
      featured: true,
    },
    {
      name: "Yonex Nanoflare 700 Play",
      category: "Vợt Yonex",
      brand: "Yonex",
      price: "1490000",
      sku: "DEMO-YONEX-NF700-PLAY",
      imageUrl: "https://images.unsplash.com/photo-1613918431703-8671060938f3?auto=format&fit=crop&w=800&q=80",
      featured: true,
    },
    {
      name: "Lining Axforce Cannon",
      category: "Vợt Lining",
      brand: "Lining",
      price: "1890000",
      sku: "DEMO-LINING-AXFORCE-CANNON",
      imageUrl: "https://images.unsplash.com/photo-1521537634581-0dced2efa2a3?auto=format&fit=crop&w=800&q=80",
      featured: true,
    },
    {
      name: "Victor Thruster Ryuga TD",
      category: "Vợt cầu lông",
      brand: "Victor",
      price: "2150000",
      sku: "DEMO-VICTOR-RYUGA-TD",
      imageUrl: "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=800&q=80",
      featured: false,
    },
    {
      name: "Giày Yonex Power Cushion 65Z",
      category: "Giày cầu lông",
      brand: "Yonex",
      price: "2190000",
      sku: "DEMO-YONEX-SHOE-65Z",
      imageUrl: "https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=80",
      featured: true,
    },
    {
      name: "Giày Lining Saga Lite",
      category: "Giày cầu lông",
      brand: "Lining",
      price: "1390000",
      sku: "DEMO-LINING-SAGA-LITE",
      imageUrl: "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&w=800&q=80",
      featured: false,
    },
    {
      name: "Áo thể thao SanVaCau Pro",
      category: "Áo thể thao",
      brand: "SanVaCau",
      price: "290000",
      sku: "DEMO-SVC-SHIRT-PRO",
      imageUrl: "https://images.unsplash.com/photo-1581655353564-df123a1eb820?auto=format&fit=crop&w=800&q=80",
      featured: true,
    },
    {
      name: "Quấn cán vợt SanVaCau Comfort",
      category: "Phụ kiện",
      brand: "SanVaCau",
      price: "45000",
      sku: "DEMO-SVC-GRIP-COMFORT",
      imageUrl: "https://images.unsplash.com/photo-1617083934555-ac7d4fed8889?auto=format&fit=crop&w=800&q=80",
      featured: false,
    },
  ];

  for (const item of products) {
    const categoryId = await getCategoryId(item.category);
    const brandId = await getBrandId(item.brand);
    const product = await upsertByNaturalKey(
      () => prisma.product.findFirst({ where: { name: item.name } }),
      () =>
        prisma.product.create({
          data: {
            category_id: categoryId,
            brand_id: brandId,
            name: item.name,
            description: `Sản phẩm demo ${item.name} cho SanVaCau.`,
            image_url: item.imageUrl,
            is_active: true,
            is_featured: item.featured,
          },
        }),
      (existing) =>
        prisma.product.update({
          where: { id: existing.id },
          data: {
            category_id: categoryId,
            brand_id: brandId,
            description: `Sản phẩm demo ${item.name} cho SanVaCau.`,
            image_url: item.imageUrl,
            is_active: true,
            is_featured: item.featured,
            updated_at: new Date(),
          },
        }),
    );

    await prisma.product_variant.upsert({
      where: { sku: item.sku },
      update: {
        product_id: product.id,
        variant_name: "Tiêu chuẩn",
        price: new Prisma.Decimal(item.price),
        image_url: item.imageUrl,
        is_active: true,
      },
      create: {
        product_id: product.id,
        sku: item.sku,
        variant_name: "Tiêu chuẩn",
        price: new Prisma.Decimal(item.price),
        image_url: item.imageUrl,
        is_active: true,
      },
    });
  }

  console.log("[seed] products and variants done");
};

const seedInventory = async () => {
  const branches = await prisma.branch.findMany({ where: { name: { startsWith: "SanVaCau" }, status: "ACTIVE" } });
  const variants = await prisma.product_variant.findMany({ where: { sku: { startsWith: "DEMO-" } } });

  for (const branch of branches) {
    for (const [index, variant] of variants.entries()) {
      await prisma.inventory.upsert({
        where: {
          branch_id_product_variant_id: {
            branch_id: branch.id,
            product_variant_id: variant.id,
          },
        },
        update: {
          quantity: 20 + index,
          updated_at: new Date(),
        },
        create: {
          branch_id: branch.id,
          product_variant_id: variant.id,
          quantity: 20 + index,
        },
      });
    }
  }

  console.log("[seed] inventory done");
};

export { seedCategories, seedBrands, seedProducts, seedInventory };
