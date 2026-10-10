import { prisma } from "../../lib/prisma.js";
import { seedCategories, seedBrands, seedProducts, seedInventory } from "./04-products.js";

try {
  await seedCategories();
  await seedBrands();
  await seedProducts();
  await seedInventory();
} catch (error) {
  console.error("Product seed failed:", error);
  process.exitCode = 1;
} finally {
  await prisma.$disconnect();
}
