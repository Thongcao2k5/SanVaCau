import * as fs from 'fs';
import * as path from 'path';

const seedPath = path.join(process.cwd(), 'prisma/seed.ts');
const outDir = path.join(process.cwd(), 'src/database/seeds');

if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

const content = fs.readFileSync(seedPath, 'utf8');

// We will split the file by "const seed" to identify functions.
// But first, let's extract the imports and helpers.
const importsMatch = content.match(/import .*?;/gs);
const imports = importsMatch ? importsMatch.join('\n') : '';

// Helper functions
const helpersMatch = content.match(/const timeOfDay.*?};/s);
const upsertMatch = content.match(/const upsertByNaturalKey.*?};\n};/s);
const helpers = (helpersMatch ? helpersMatch[0] : '') + '\n\n' + (upsertMatch ? upsertMatch[0] : '');

function extractFunction(name) {
  const regex = new RegExp(`const ${name} = async \\(\\) => \\{.*?^\\};`, 'ms');
  const match = content.match(regex);
  return match ? match[0] : '';
}

const f01 = extractFunction('seedAdmin');
const f02 = extractFunction('seedBranches');
const f03 = extractFunction('seedCourtsAndPrices');
const f04 = [extractFunction('seedCategories'), extractFunction('seedBrands'), extractFunction('seedProducts'), extractFunction('seedInventory')].join('\n\n');
const f05 = extractFunction('seedRacketServices');
const f06 = [extractFunction('seedBanners'), extractFunction('seedNews'), extractFunction('seedSettings'), extractFunction('seedFaqs'), extractFunction('seedStaticPages')].join('\n\n');

function writeModule(filename, fns, exports) {
  let fileContent = `import { PrismaClient, Prisma } from "@prisma/client";\nimport { hashPassword } from "../../lib/auth.js";\nimport { prisma } from "../../lib/prisma.js";\n\n${helpers}\n\n${fns}\n\nexport { ${exports.join(', ')} };\n`;
  fs.writeFileSync(path.join(outDir, filename), fileContent);
}

writeModule('01-users.ts', f01, ['seedAdmin']);
writeModule('02-branches.ts', f02, ['seedBranches']);
writeModule('03-courts.ts', f03, ['seedCourtsAndPrices']);
writeModule('04-products.ts', f04, ['seedCategories', 'seedBrands', 'seedProducts', 'seedInventory']);
writeModule('05-services.ts', f05, ['seedRacketServices']);
writeModule('06-content.ts', f06, ['seedBanners', 'seedNews', 'seedSettings', 'seedFaqs', 'seedStaticPages']);

const seedTsContent = `import { PrismaClient } from "@prisma/client";
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
`;

fs.writeFileSync(path.join(outDir, 'seed.ts'), seedTsContent);
console.log("Done splitting.");
