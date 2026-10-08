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



const seedBanners = async () => {
  const banners = [
    {
      title: "Đặt sân nhanh cùng SanVaCau",
      imageUrl: "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=1200&q=80",
      linkUrl: "sanvacau://booking",
      sortOrder: 1,
    },
    {
      title: "Ưu đãi vợt cầu lông chính hãng",
      imageUrl: "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=1200&q=80",
      linkUrl: "sanvacau://products",
      sortOrder: 2,
    },
    {
      title: "Chi nhánh mới đã khai trương",
      imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=1200&q=80",
      linkUrl: "sanvacau://branches",
      sortOrder: 3,
    },
  ];

  for (const banner of banners) {
    await upsertByNaturalKey(
      () => prisma.banner.findFirst({ where: { title: banner.title } }),
      () =>
        prisma.banner.create({
          data: {
            title: banner.title,
            image_url: banner.imageUrl,
            link_url: banner.linkUrl,
            sort_order: banner.sortOrder,
            is_active: true,
          },
        }),
      (existing) =>
        prisma.banner.update({
          where: { id: existing.id },
          data: {
            image_url: banner.imageUrl,
            link_url: banner.linkUrl,
            sort_order: banner.sortOrder,
            is_active: true,
            updated_at: new Date(),
          },
        }),
    );
  }

  console.log("[seed] banners done");
};

const seedNews = async () => {
  const admin = await prisma.app_user.findUnique({ where: { email: "admin@shopvacau.com" } });
  if (!admin) throw new Error("Missing admin account");

  const firstBranch = await prisma.branch.findFirst({ where: { name: { startsWith: "SanVaCau" } } });
  const newsItems = [
    ["5 mẹo cải thiện phản xạ khi chơi cầu lông", null],
    ["SanVaCau khai trương chi nhánh mới", firstBranch?.id ?? null],
    ["Ưu đãi sản phẩm cầu lông trong tháng", null],
    ["Hướng dẫn đặt sân trên ứng dụng SanVaCau", null],
    ["Cách bảo quản vợt và dây căng hiệu quả", null],
  ] as const;

  for (const [index, [title, branchId]] of newsItems.entries()) {
    await upsertByNaturalKey(
      () => prisma.news.findFirst({ where: { title } }),
      () =>
        prisma.news.create({
          data: {
            title,
            summary: `Tin tức demo ${index + 1} cho SanVaCau.`,
            content: `Nội dung demo cho bài viết "${title}".`,
            thumbnail_url: [
              "https://images.unsplash.com/photo-1613918431703-8671060938f3?auto=format&fit=crop&w=800&q=80",
              "https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80",
              "https://images.unsplash.com/photo-1521537634581-0dced2efa2a3?auto=format&fit=crop&w=800&q=80",
              "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=800&q=80",
              "https://images.unsplash.com/photo-1617083934555-ac7d4fed8889?auto=format&fit=crop&w=800&q=80",
            ][index % 5],
            author_user_id: admin.id,
            branch_id: branchId,
            status: "PUBLISHED",
            published_at: new Date(),
          },
        }),
      (existing) =>
        prisma.news.update({
          where: { id: existing.id },
          data: {
            summary: `Tin tức demo ${index + 1} cho SanVaCau.`,
            content: `Nội dung demo cho bài viết "${title}".`,
            thumbnail_url: [
              "https://images.unsplash.com/photo-1613918431703-8671060938f3?auto=format&fit=crop&w=800&q=80",
              "https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80",
              "https://images.unsplash.com/photo-1521537634581-0dced2efa2a3?auto=format&fit=crop&w=800&q=80",
              "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=800&q=80",
              "https://images.unsplash.com/photo-1617083934555-ac7d4fed8889?auto=format&fit=crop&w=800&q=80",
            ][index % 5],
            author_user_id: admin.id,
            branch_id: branchId,
            status: "PUBLISHED",
            published_at: existing.published_at ?? new Date(),
            updated_at: new Date(),
          },
        }),
    );
  }

  console.log("[seed] news done");
};

const seedSettings = async () => {
  const settings: Array<{ key: string; value: Prisma.InputJsonValue; description: string; isPublic: boolean }> = [
    { key: "app_name", value: "SanVaCau", description: "Tên ứng dụng", isPublic: true },
    { key: "support_phone", value: "0901000000", description: "Số điện thoại hỗ trợ", isPublic: true },
    { key: "support_email", value: "support@sanvacau.local", description: "Email hỗ trợ", isPublic: true },
    { key: "business_hours", value: { open: "06:00", close: "22:00" }, description: "Giờ hoạt động", isPublic: true },
    {
      key: "social_links",
      value: { facebook: "https://facebook.com/sanvacau", zalo: "https://zalo.me/sanvacau" },
      description: "Liên kết mạng xã hội",
      isPublic: true,
    },
    {
      key: "app_status",
      value: {
        maintenance: { enabled: false, message: "Hệ thống đang bảo trì, vui lòng quay lại sau." },
        android: {
          minimumSupportedVersion: "1.0.0",
          latestVersion: "1.0.0",
          storeUrl: "https://play.google.com/store/apps/details?id=com.sanvacau.app",
          forceUpdateMessage: "Vui lòng cập nhật ứng dụng để tiếp tục.",
          optionalUpdateMessage: "Đã có phiên bản mới.",
        },
        ios: {
          minimumSupportedVersion: "1.0.0",
          latestVersion: "1.0.0",
          storeUrl: "https://apps.apple.com/app/sanvacau",
          forceUpdateMessage: "Vui lòng cập nhật ứng dụng để tiếp tục.",
          optionalUpdateMessage: "Đã có phiên bản mới.",
        },
      },
      description: "Mobile app version and maintenance configuration",
      isPublic: false,
    },
  ];

  for (const setting of settings) {
    await prisma.system_setting.upsert({
      where: { key: setting.key },
      update: {
        value: setting.value,
        description: setting.description,
        is_public: setting.isPublic,
        updated_at: new Date(),
      },
      create: {
        key: setting.key,
        value: setting.value,
        description: setting.description,
        is_public: setting.isPublic,
      },
    });
  }

  console.log("[seed] settings done");
};

const seedFaqs = async () => {
  const faqs = [
    ["Đặt sân", "Làm sao để đặt sân?", "Bạn chọn chi nhánh, sân, ngày và khung giờ còn trống rồi xác nhận đặt sân."],
    ["Đặt sân", "Tôi có thể hủy lịch đặt không?", "Bạn có thể hủy lịch theo chính sách hiển thị trong ứng dụng."],
    ["Thanh toán", "SanVaCau hỗ trợ thanh toán nào?", "Bạn có thể thanh toán tiền mặt, chuyển khoản hoặc ví điện tử tùy thời điểm hỗ trợ."],
    ["Đơn hàng", "Tôi theo dõi đơn hàng ở đâu?", "Bạn vào mục Tài khoản > Đơn hàng của tôi để xem trạng thái."],
    ["Đổi trả", "Sản phẩm có được đổi trả không?", "Sản phẩm còn nguyên tem mác có thể đổi trả theo chính sách cửa hàng."],
    ["Bảo hành", "Vợt có bảo hành không?", "Vợt chính hãng được bảo hành theo chính sách của hãng sản xuất."],
    ["Hỗ trợ", "Tôi liên hệ hỗ trợ bằng cách nào?", "Bạn có thể gửi ticket hỗ trợ hoặc gọi hotline trong ứng dụng."],
    ["Tài khoản", "Tôi quên mật khẩu thì làm sao?", "Bạn liên hệ hỗ trợ để được hướng dẫn khôi phục tài khoản."],
  ];

  for (const [index, [category, question, answer]] of faqs.entries()) {
    await upsertByNaturalKey(
      () => prisma.faq_item.findFirst({ where: { question } }),
      () =>
        prisma.faq_item.create({
          data: {
            category,
            question,
            answer,
            status: "PUBLISHED",
            sort_order: index + 1,
            published_at: new Date(),
          },
        }),
      (existing) =>
        prisma.faq_item.update({
          where: { id: existing.id },
          data: {
            category,
            answer,
            status: "PUBLISHED",
            sort_order: index + 1,
            published_at: existing.published_at ?? new Date(),
            updated_at: new Date(),
          },
        }),
    );
  }

  console.log("[seed] FAQs done");
};

const seedStaticPages = async () => {
  const pages = [
    ["terms", "Điều khoản sử dụng", "TERMS"],
    ["privacy", "Chính sách bảo mật", "PRIVACY"],
    ["return-policy", "Chính sách đổi trả", "RETURN_POLICY"],
    ["payment-guide", "Hướng dẫn thanh toán", "PAYMENT_GUIDE"],
    ["booking-guide", "Hướng dẫn đặt sân", "BOOKING_GUIDE"],
    ["warranty-policy", "Chính sách bảo hành", "WARRANTY"],
    ["about-sanvacau", "Về SanVaCau", "ABOUT"],
  ] as const;

  for (const [index, [slug, title, type]] of pages.entries()) {
    await prisma.static_page.upsert({
      where: { slug },
      update: {
        title,
        summary: `${title} của SanVaCau.`,
        content: `Nội dung demo cho trang "${title}". Vui lòng cập nhật nội dung chính thức trước khi phát hành.`,
        type,
        status: "PUBLISHED",
        sort_order: index + 1,
        published_at: new Date(),
        updated_at: new Date(),
      },
      create: {
        slug,
        title,
        summary: `${title} của SanVaCau.`,
        content: `Nội dung demo cho trang "${title}". Vui lòng cập nhật nội dung chính thức trước khi phát hành.`,
        type,
        status: "PUBLISHED",
        sort_order: index + 1,
        published_at: new Date(),
      },
    });
  }

  console.log("[seed] static pages done");
};

export { seedBanners, seedNews, seedSettings, seedFaqs, seedStaticPages };
