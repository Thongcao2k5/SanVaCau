import { Prisma } from "@prisma/client";
import { hashPassword } from "../src/lib/auth.js";
import { prisma } from "../src/lib/prisma.js";

const timeOfDay = (hhmm: string) => new Date(`1970-01-01T${hhmm}:00.000Z`);

const upsertByNaturalKey = async <T>(
  find: () => Promise<T | null>,
  create: () => Promise<T>,
  update: (existing: T) => Promise<T>,
) => {
  const existing = await find();
  return existing ? update(existing) : create();
};

const seedAdmin = async () => {
  await prisma.app_user.upsert({
    where: { email: "admin@shopvacau.com" },
    update: {
      password_hash: await hashPassword("Admin123456"),
      full_name: "SanVaCau Admin",
      role: "ADMIN",
      status: "ACTIVE",
      branch_id: null,
      must_change_password: false,
      updated_at: new Date(),
    },
    create: {
      email: "admin@shopvacau.com",
      password_hash: await hashPassword("Admin123456"),
      full_name: "SanVaCau Admin",
      role: "ADMIN",
      status: "ACTIVE",
      must_change_password: false,
    },
  });
  console.log("[seed] admin account done");
};

const seedBranches = async () => {
  const branches = [
    {
      name: "SanVaCau Quận 1",
      address: "12 Nguyễn Trãi, Phường Bến Thành, Quận 1, TP.HCM",
      phone: "0901000001",
    },
    {
      name: "SanVaCau Thủ Đức",
      address: "45 Võ Văn Ngân, Phường Linh Chiểu, TP. Thủ Đức, TP.HCM",
      phone: "0901000002",
    },
    {
      name: "SanVaCau Bình Thạnh",
      address: "88 Xô Viết Nghệ Tĩnh, Phường 21, Bình Thạnh, TP.HCM",
      phone: "0901000003",
    },
  ];

  for (const branch of branches) {
    await upsertByNaturalKey(
      () => prisma.branch.findFirst({ where: { name: branch.name } }),
      () =>
        prisma.branch.create({
          data: {
            ...branch,
            opening_time: timeOfDay("06:00"),
            closing_time: timeOfDay("22:00"),
            status: "ACTIVE",
          },
        }),
      (existing) =>
        prisma.branch.update({
          where: { id: existing.id },
          data: {
            ...branch,
            opening_time: timeOfDay("06:00"),
            closing_time: timeOfDay("22:00"),
            status: "ACTIVE",
            updated_at: new Date(),
          },
        }),
    );
  }

  console.log("[seed] branches done");
};

const seedRacketServices = async () => {
  const services = [
    {
      name: "Căng dây vợt",
      description: "Căng dây theo mức cân và loại dây khách hàng yêu cầu.",
      referencePrice: "120000",
      estimatedDuration: "30 - 45 phút",
    },
    {
      name: "Thay quấn cán",
      description: "Tháo lớp quấn cũ, vệ sinh cán và thay quấn cán mới.",
      referencePrice: "50000",
      estimatedDuration: "15 - 20 phút",
    },
    {
      name: "Kiểm tra và sửa khung vợt",
      description: "Kiểm tra khung, gen và tư vấn phương án sửa phù hợp.",
      referencePrice: "100000",
      estimatedDuration: "1 - 2 ngày",
    },
  ];

  const branches = await prisma.branch.findMany({
    where: { name: { startsWith: "SanVaCau" }, status: "ACTIVE" },
  });

  for (const item of services) {
    const service = await upsertByNaturalKey(
      () => prisma.racket_service.findFirst({ where: { name: item.name } }),
      () =>
        prisma.racket_service.create({
          data: {
            name: item.name,
            description: item.description,
            is_active: true,
          },
        }),
      (existing) =>
        prisma.racket_service.update({
          where: { id: existing.id },
          data: {
            description: item.description,
            is_active: true,
          },
        }),
    );

    for (const branch of branches) {
      await prisma.branch_service.upsert({
        where: {
          branch_id_service_id: {
            branch_id: branch.id,
            service_id: service.id,
          },
        },
        update: {
          reference_price: new Prisma.Decimal(item.referencePrice),
          description: item.description,
          estimated_duration: item.estimatedDuration,
          is_available: true,
        },
        create: {
          branch_id: branch.id,
          service_id: service.id,
          reference_price: new Prisma.Decimal(item.referencePrice),
          description: item.description,
          estimated_duration: item.estimatedDuration,
          is_available: true,
        },
      });
    }
  }

  console.log("[seed] racket services done");
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
      featured: true,
    },
    {
      name: "Yonex Nanoflare 700 Play",
      category: "Vợt Yonex",
      brand: "Yonex",
      price: "1490000",
      sku: "DEMO-YONEX-NF700-PLAY",
      featured: true,
    },
    {
      name: "Lining Axforce Cannon",
      category: "Vợt Lining",
      brand: "Lining",
      price: "1890000",
      sku: "DEMO-LINING-AXFORCE-CANNON",
      featured: true,
    },
    {
      name: "Victor Thruster Ryuga TD",
      category: "Vợt cầu lông",
      brand: "Victor",
      price: "2150000",
      sku: "DEMO-VICTOR-RYUGA-TD",
      featured: false,
    },
    {
      name: "Giày Yonex Power Cushion 65Z",
      category: "Giày cầu lông",
      brand: "Yonex",
      price: "2190000",
      sku: "DEMO-YONEX-SHOE-65Z",
      featured: true,
    },
    {
      name: "Giày Lining Saga Lite",
      category: "Giày cầu lông",
      brand: "Lining",
      price: "1390000",
      sku: "DEMO-LINING-SAGA-LITE",
      featured: false,
    },
    {
      name: "Áo thể thao SanVaCau Pro",
      category: "Áo thể thao",
      brand: "SanVaCau",
      price: "290000",
      sku: "DEMO-SVC-SHIRT-PRO",
      featured: true,
    },
    {
      name: "Quấn cán vợt SanVaCau Comfort",
      category: "Phụ kiện",
      brand: "SanVaCau",
      price: "45000",
      sku: "DEMO-SVC-GRIP-COMFORT",
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
            image_url: `https://example.com/sanvacau/products/${item.sku.toLowerCase()}.jpg`,
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
            image_url: `https://example.com/sanvacau/products/${item.sku.toLowerCase()}.jpg`,
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
        image_url: `https://example.com/sanvacau/products/${item.sku.toLowerCase()}.jpg`,
        is_active: true,
      },
      create: {
        product_id: product.id,
        sku: item.sku,
        variant_name: "Tiêu chuẩn",
        price: new Prisma.Decimal(item.price),
        image_url: `https://example.com/sanvacau/products/${item.sku.toLowerCase()}.jpg`,
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

const seedCourtsAndPrices = async () => {
  const branches = await prisma.branch.findMany({ where: { name: { startsWith: "SanVaCau" }, status: "ACTIVE" } });
  const slotValues = [
    ["06:00", "07:00"],
    ["07:00", "08:00"],
    ["08:00", "09:00"],
    ["17:00", "18:00"],
    ["18:00", "19:00"],
    ["19:00", "20:00"],
    ["20:00", "21:00"],
    ["21:00", "22:00"],
  ] as const;

  const slots = [];
  for (const [index, [start, end]] of slotValues.entries()) {
    const startTime = timeOfDay(start);
    const endTime = timeOfDay(end);
    const sortOrder = index + 1;
    const exactSlot = await prisma.time_slot.findFirst({
      where: { start_time: startTime, end_time: endTime },
    });
    const sortSlot = exactSlot ? null : await prisma.time_slot.findUnique({ where: { sort_order: sortOrder } });
    const slot =
      exactSlot ??
      (sortSlot
        ? await prisma.time_slot.update({
            where: { id: sortSlot.id },
            data: {
              start_time: startTime,
              end_time: endTime,
              is_active: true,
            },
          })
        : await prisma.time_slot.create({
            data: {
              start_time: startTime,
              end_time: endTime,
              sort_order: sortOrder,
              is_active: true,
            },
          }));

    if (!slot.is_active) {
      await prisma.time_slot.update({
        where: { id: slot.id },
        data: { is_active: true },
      });
    }
    slots.push(slot);
  }

  for (const branch of branches) {
    for (const courtName of ["Sân 1", "Sân 2", "Sân 3"]) {
      const court = await prisma.court.upsert({
        where: {
          branch_id_name: {
            branch_id: branch.id,
            name: courtName,
          },
        },
        update: {
          description: `${courtName} demo tại ${branch.name}`,
          status: "ACTIVE",
        },
        create: {
          branch_id: branch.id,
          name: courtName,
          description: `${courtName} demo tại ${branch.name}`,
          status: "ACTIVE",
        },
      });

      for (const slot of slots) {
        const hour = slot.start_time.getUTCHours();
        const price = hour < 12 ? "80000" : "120000";
        await prisma.court_price.upsert({
          where: {
            court_id_time_slot_id: {
              court_id: court.id,
              time_slot_id: slot.id,
            },
          },
          update: {
            price: new Prisma.Decimal(price),
          },
          create: {
            court_id: court.id,
            time_slot_id: slot.id,
            price: new Prisma.Decimal(price),
          },
        });
      }
    }
  }

  console.log("[seed] courts, time slots and prices done");
};

const seedBanners = async () => {
  const banners = [
    {
      title: "Đặt sân nhanh cùng SanVaCau",
      imageUrl: "https://example.com/sanvacau/banners/booking.jpg",
      linkUrl: "sanvacau://booking",
      sortOrder: 1,
    },
    {
      title: "Ưu đãi vợt cầu lông chính hãng",
      imageUrl: "https://example.com/sanvacau/banners/products.jpg",
      linkUrl: "sanvacau://products",
      sortOrder: 2,
    },
    {
      title: "Chi nhánh mới đã khai trương",
      imageUrl: "https://example.com/sanvacau/banners/branch.jpg",
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
            thumbnail_url: `https://example.com/sanvacau/news/${index + 1}.jpg`,
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
            thumbnail_url: `https://example.com/sanvacau/news/${index + 1}.jpg`,
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

const main = async () => {
  console.log("[seed] starting SanVaCau demo seed");
  await seedAdmin();
  await seedBranches();
  await seedRacketServices();
  await seedCategories();
  await seedBrands();
  await seedProducts();
  await seedInventory();
  await seedCourtsAndPrices();
  await seedBanners();
  await seedNews();
  await seedSettings();
  await seedFaqs();
  await seedStaticPages();
  console.log("[seed] completed successfully");
};

main()
  .catch((error: unknown) => {
    console.error("[seed] failed", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
