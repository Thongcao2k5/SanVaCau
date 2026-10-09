import { migrateHalfHourSlots } from '../src/lib/half-hour-slots.js';
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
      description: "Chi nhánh trung tâm với hệ thống sân thảm tiêu chuẩn, ánh sáng ổn định và khu vực nghỉ tiện nghi.",
      image_url: "assets/demo/banner-court.jpg",
      is_featured: true,
      sort_order: 1,
    },
    {
      name: "SanVaCau Thủ Đức",
      address: "45 Võ Văn Ngân, Phường Linh Chiểu, TP. Thủ Đức, TP.HCM",
      phone: "0901000002",
      description: "Không gian rộng rãi gần khu vực Làng Đại học, phù hợp tập luyện thường xuyên và thi đấu theo nhóm.",
      image_url: "assets/demo/branch-thu-duc.jpg",
      is_featured: true,
      sort_order: 2,
    },
    {
      name: "SanVaCau Bình Thạnh",
      address: "88 Xô Viết Nghệ Tĩnh, Phường 21, Bình Thạnh, TP.HCM",
      phone: "0901000003",
      description: "Cụm sân thuận tiện di chuyển, có khu vực chờ và dịch vụ hỗ trợ dụng cụ dành cho người chơi.",
      image_url: "assets/demo/branch-binh-thanh.jpg",
      is_featured: true,
      sort_order: 3,
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
      featured: true,
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
      featured: false,
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

  const productImageBySku: Record<string, string> = {
    "DEMO-YONEX-AX88D-GAME": "assets/demo/product-racket-yonex.jpg",
    "DEMO-YONEX-NF700-PLAY": "assets/demo/product-racket-flypower.jpg",
    "DEMO-LINING-AXFORCE-CANNON": "assets/demo/product-racket-blue.jpg",
    "DEMO-VICTOR-RYUGA-TD": "assets/demo/product-racket-carlton.jpg",
    "DEMO-YONEX-SHOE-65Z": "assets/demo/product-shoes.jpg",
    "DEMO-LINING-SAGA-LITE": "assets/demo/product-shoes.jpg",
    "DEMO-SVC-SHIRT-PRO": "assets/demo/product-racket-blue.jpg",
    "DEMO-SVC-GRIP-COMFORT": "assets/demo/product-racket-carlton.jpg",
  };

  const buildVariants = (item: (typeof products)[number]) => {
    const basePrice = Number(item.price);
    if (item.category.includes("Vợt")) {
      return ["4U", "3U"].flatMap((weight) =>
        ["G5", "G6"].map((grip) => ({
          suffix: `${weight}-${grip}`,
          option1Name: "Trọng lượng",
          option1Value: weight,
          option2Name: "Cỡ cán",
          option2Value: grip,
          price: basePrice + (weight === "3U" ? 100000 : 0) + (grip === "G6" ? 50000 : 0),
        })),
      );
    }
    if (item.category === "Giày cầu lông") {
      return ["38", "39", "40", "41", "42", "43", "44"].flatMap((size) => [
        { suffix: `WR-${size}`, option1Name: "Màu", option1Value: "Trắng/Đỏ", option2Name: "Size", option2Value: size, price: basePrice },
        { suffix: `BLACK-${size}`, option1Name: "Màu", option1Value: "Đen", option2Name: "Size", option2Value: size, price: basePrice + 50000 },
      ]);
    }
    if (item.category === "Áo thể thao") {
      return ["S", "M", "L", "XL", "XXL"].flatMap((size) => [
        { suffix: `RED-${size}`, option1Name: "Màu", option1Value: "Đỏ", option2Name: "Size", option2Value: size, price: basePrice },
        { suffix: `BLACK-${size}`, option1Name: "Màu", option1Value: "Đen", option2Name: "Size", option2Value: size, price: basePrice },
        { suffix: `WHITE-${size}`, option1Name: "Màu", option1Value: "Trắng", option2Name: "Size", option2Value: size, price: basePrice },
      ]);
    }
    return ["Đỏ", "Đen", "Trắng"].flatMap((color) =>
      [1, 3, 10].map((pack) => ({
        suffix: `${color === "Đỏ" ? "RED" : color === "Đen" ? "BLACK" : "WHITE"}-${pack}`,
        option1Name: "Màu",
        option1Value: color,
        option2Name: "Quy cách",
        option2Value: `${pack} cuộn`,
        price: Math.round(basePrice * pack * (pack === 10 ? 0.9 : pack === 3 ? 0.95 : 1)),
      })),
    );
  };

  for (const item of products) {
    const categoryId = await getCategoryId(item.category);
    const brandId = await getBrandId(item.brand);
    const imageUrl = productImageBySku[item.sku];
    if (!imageUrl) throw new Error(`Missing demo image for SKU: ${item.sku}`);
    const product = await upsertByNaturalKey(
      () => prisma.product.findFirst({ where: { name: item.name } }),
      () =>
        prisma.product.create({
          data: {
            category_id: categoryId,
            brand_id: brandId,
            name: item.name,
            description: `Sản phẩm demo ${item.name} cho SanVaCau.`,
            image_url: imageUrl,
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
            image_url: imageUrl,
            is_active: true,
            is_featured: item.featured,
            updated_at: new Date(),
          },
        }),
    );

    for (const [variantIndex, spec] of buildVariants(item).entries()) {
      const sku = variantIndex === 0 ? item.sku : `${item.sku}-${spec.suffix}`;
      const variantName = `${spec.option1Value} - ${spec.option2Value}`;
      await prisma.product_variant.upsert({
        where: { sku },
        update: {
          product_id: product.id,
          variant_name: variantName,
          option_1_name: spec.option1Name,
          option_1_value: spec.option1Value,
          option_2_name: spec.option2Name,
          option_2_value: spec.option2Value,
          price: new Prisma.Decimal(spec.price),
          image_url: imageUrl,
          is_active: true,
        },
        create: {
          product_id: product.id,
          sku,
          variant_name: variantName,
          option_1_name: spec.option1Name,
          option_1_value: spec.option1Value,
          option_2_name: spec.option2Name,
          option_2_value: spec.option2Value,
          price: new Prisma.Decimal(spec.price),
          image_url: imageUrl,
          is_active: true,
        },
      });
    }
  }

  console.log("[seed] products and variants done");
};

const seedInventory = async () => {
  const variants = await prisma.product_variant.findMany({ where: { sku: { startsWith: "DEMO-" } } });

  for (const [index, variant] of variants.entries()) {
    const quantity = index === 0 ? 0 : index === 1 ? 3 : 20 + index;
    await prisma.inventory.upsert({
      where: { product_variant_id: variant.id },
      update: { quantity, updated_at: new Date() },
      create: { product_variant_id: variant.id, quantity },
    });
  }

  console.log("[seed] global inventory done");
};

const seedCourtsAndPrices = async () => {
  const branches = await prisma.branch.findMany({ where: { name: { startsWith: "SanVaCau" }, status: "ACTIVE" } });
  await migrateHalfHourSlots(prisma);
  const slots = [];
  let sortOrder = (await prisma.time_slot.aggregate({ _max: { sort_order: true } }))._max.sort_order ?? 0;
  for (const [from, until] of [[6, 22]]) {
    for (let minute = from * 60; minute < until * 60; minute += 30) {
      const format = (value: number) => `${Math.floor(value / 60).toString().padStart(2, '0')}:${(value % 60).toString().padStart(2, '0')}`;
      const start = timeOfDay(format(minute));
      const end = timeOfDay(format(minute + 30));
      const slot = await prisma.time_slot.upsert({
        where: { start_time_end_time: { start_time: start, end_time: end } },
        update: { is_active: true },
        create: { start_time: start, end_time: end, sort_order: ++sortOrder, is_active: true },
      });
      slots.push(slot);
    }
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
        const price = hour < 12 ? "40000" : "60000";
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
      imageUrl: "assets/demo/banner-court.jpg",
      linkUrl: "sanvacau://booking",
      sortOrder: 1,
    },
    {
      title: "Ưu đãi vợt cầu lông chính hãng",
      imageUrl: "assets/demo/product-racket-flypower.jpg",
      linkUrl: "sanvacau://products",
      sortOrder: 2,
    },
    {
      title: "Chi nhánh mới đã khai trương",
      imageUrl: "assets/demo/branch-thu-duc.jpg",
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
  const newsImages = [
    "assets/demo/news-stringing.png",
    "assets/demo/branch-thu-duc.jpg",
    "assets/demo/news-shuttlecock.jpg",
    "assets/demo/banner-court.jpg",
    "assets/demo/news-stringing.png",
  ];

  for (const [index, [title, branchId]] of newsItems.entries()) {
    await upsertByNaturalKey(
      () => prisma.news.findFirst({ where: { title } }),
      () =>
        prisma.news.create({
          data: {
            title,
            summary: `Tin tức demo ${index + 1} cho SanVaCau.`,
            content: `Nội dung demo cho bài viết "${title}".`,
            thumbnail_url: newsImages[index],
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
            thumbnail_url: newsImages[index],
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
