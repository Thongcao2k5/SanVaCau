import { PrismaClient } from "@prisma/client";
import { seedAdmin } from "./01-users.js";
import { seedBranches } from "./02-branches.js";
import { seedCourtsAndPrices } from "./03-courts.js";
import { seedCategories, seedBrands, seedProducts, seedInventory } from "./04-products.js";
import { seedRacketServices } from "./05-services.js";
import { seedBanners, seedNews, seedSettings, seedFaqs, seedStaticPages } from "./06-content.js";
import { prisma } from "../../lib/prisma.js";

async function main() {
  console.log("🌱 Bắt đầu chạy Seed Data...");

  try {
    console.log("⏳ Đang seed Users...");
    await seedAdmin();

    console.log("⏳ Đang seed Branches...");
    await seedBranches();

    console.log("⏳ Đang seed Courts & Prices...");
    await seedCourtsAndPrices();

    console.log("⏳ Đang seed Products (Categories, Brands, Products, Inventory)...");
    await seedCategories();
    await seedBrands();
    await seedProducts();
    await seedInventory();

    console.log("⏳ Đang seed Racket Services...");
    await seedRacketServices();

    console.log("⏳ Đang seed Content...");
    await seedBanners();
    await seedNews();
    await seedSettings();
    await seedFaqs();
    await seedStaticPages();

    console.log("✅ Seed Data hoàn tất thành công!");
  } catch (error) {
    console.error("❌ Xảy ra lỗi trong quá trình Seed:", error);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
}

main();
