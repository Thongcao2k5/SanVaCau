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
import { courtRouter } from "./court.routes.js";
import { bookingRouter } from "./booking.routes.js";
import { cartRouter } from "./cart.routes.js";
import { orderRouter } from "./order.routes.js";
import { dashboardRouter } from "./dashboard.routes.js";
import { profileRouter } from "./profile.routes.js";
import { racketServiceRouter } from "./racket-service.routes.js";
import { branchServiceRouter } from "./branch-service.routes.js";
import { uploadRouter } from "./upload.routes.js";
import { auditLogRouter } from "./audit-log.routes.js";
import { notificationRouter } from "./notification.routes.js";
import { paymentRouter } from "./payment.routes.js";
import { reviewRouter } from "./review.routes.js";
import { favoriteRouter } from "./favorite.routes.js";
import { searchRouter } from "./search.routes.js";
import { addressRouter } from "./address.routes.js";
import { voucherRouter } from "./voucher.routes.js";
import { fulfillmentRouter } from "./fulfillment.routes.js";
import { supportRouter } from "./support.routes.js";
import { reportRouter } from "./report.routes.js";
import { settingRouter } from "./setting.routes.js";
import { bootstrapRouter } from "./bootstrap.routes.js";
import { metadataRouter } from "./metadata.routes.js";
import { appStatusRouter } from "./app-status.routes.js";
import { contactRouter } from "./contact.routes.js";
import { faqRouter } from "./faq.routes.js";
import { staticPageRouter } from "./static-page.routes.js";
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
router.use("/courts", courtRouter);
router.use("/bookings", bookingRouter);
router.use("/cart", cartRouter);
router.use("/orders", orderRouter);
router.use("/dashboard", dashboardRouter);
router.use("/profile", profileRouter);
router.use("/racket-services", racketServiceRouter);
router.use("/branch-services", branchServiceRouter);
router.use("/uploads", uploadRouter);
router.use("/audit-logs", auditLogRouter);
router.use("/notifications", notificationRouter);
router.use("/payments", paymentRouter);
router.use("/reviews", reviewRouter);
router.use("/favorites", favoriteRouter);
router.use("/search", searchRouter);
router.use("/addresses", addressRouter);
router.use("/vouchers", voucherRouter);
router.use("/fulfillments", fulfillmentRouter);
router.use("/support", supportRouter);
router.use("/reports", reportRouter);
router.use("/settings", settingRouter);
router.use("/bootstrap", bootstrapRouter);
router.use("/metadata", metadataRouter);
router.use("/app-status", appStatusRouter);
router.use("/contact", contactRouter);
router.use("/faqs", faqRouter);
router.use("/pages", staticPageRouter);
