import { seedProducts, seedInventory } from "./product-seeder.js";
import { prisma } from "../../lib/prisma.js";

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
      (existing) => Promise.resolve(existing),
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
        (existing) => Promise.resolve(existing),
      );
    }
  }

  console.log("[seed] categories done");
};

const seedBrands = async () => {
  for (const name of ["Yonex", "Lining", "Victor", "Kawasaki", "SanVaCau"]) {
    await prisma.brand.upsert({
      where: { name },
      update: {},
      create: {
        name,
        description: `Thương hiệu demo ${name}`,
        is_active: true,
      },
    });
  }

  console.log("[seed] brands done");
};

export { seedCategories, seedBrands, seedProducts, seedInventory };
