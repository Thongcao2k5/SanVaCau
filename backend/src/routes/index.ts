import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { authRouter } from "./auth.routes.js";
import { branchRouter } from "./branch.routes.js";
import { categoryRouter } from "./category.routes.js";
import { brandRouter } from "./brand.routes.js"; // Import route brand
import { productRouter } from "./product.routes.js";
import { productVariantRouter } from "./product-variant.routes.js";
import { inventoryRouter } from "./inventory.routes.js";
import { newsRouter } from "./news.routes.js";
import { bannerRouter } from "./banner.routes.js";
import { homeRouter } from "./home.routes.js";
export const router = Router();

router.get("/health", (_req, res) => {
  res.json({
    success: true,
    message: "SanVaCau API is running",
  });
});

router.get("/health/db", async (_req, res, next) => {
  try {
    await prisma.$queryRaw`SELECT 1`;

    res.json({
      success: true,
      database: "connected",
    });
  } catch (error) {
    next(error);
  }
});
router.use("/brands", brandRouter); // Gắn brand API vào /api/brands
router.use("/auth", authRouter);
router.use("/branches", branchRouter);
router.use("/categories", categoryRouter);
router.use("/products", productRouter);
router.use("/product-variants", productVariantRouter);
router.use("/inventories", inventoryRouter);
router.use("/news", newsRouter);
router.use("/banners", bannerRouter);
router.use("/home", homeRouter);
