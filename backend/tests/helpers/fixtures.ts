import { prisma } from "../../src/lib/prisma.js";
import { signAuthToken } from "../../src/lib/auth.js";

// Counter for generating unique values
let idCounter = 1;

const uniqueString = (prefix: string) => `${prefix}_${Date.now()}_${idCounter++}`;

export const createCustomer = async () => {
  const email = uniqueString("customer") + "@example.com";
  const user = await prisma.app_user.create({
    data: {
      email,
      password_hash: "hashed_password", // not used for login, we sign token directly
      full_name: "Test Customer",
      role: "CUSTOMER",
    },
  });
  const token = signAuthToken({ id: user.id.toString(), email: user.email, role: user.role, branchId: null });
  return { user, token };
};

export const createAdmin = async () => {
  const email = uniqueString("admin") + "@example.com";
  const user = await prisma.app_user.create({
    data: {
      email,
      password_hash: "hashed_password",
      full_name: "Test Admin",
      role: "ADMIN",
    },
  });
  const token = signAuthToken({ id: user.id.toString(), email: user.email, role: user.role, branchId: null });
  return { user, token };
};

export const createBranchManager = async (branchId: bigint) => {
  const email = uniqueString("manager") + "@example.com";
  const user = await prisma.app_user.create({
    data: {
      email,
      password_hash: "hashed_password",
      full_name: "Test Manager",
      role: "BRANCH_MANAGER",
      branch_id: branchId,
    },
  });
  const token = signAuthToken({ id: user.id.toString(), email: user.email, role: user.role, branchId: branchId.toString() });
  return { user, token };
};

export const createBranch = async () => {
  return prisma.branch.create({
    data: {
      name: uniqueString("Branch"),
      address: "123 Test St",
      opening_time: new Date("1970-01-01T06:00:00Z"),
      closing_time: new Date("1970-01-01T22:00:00Z"),
    },
  });
};

export const createCategory = async () => {
  return prisma.category.create({
    data: {
      name: uniqueString("Category"),
    },
  });
};

export const createBrand = async () => {
  return prisma.brand.create({
    data: {
      name: uniqueString("Brand"),
    },
  });
};

export const createProduct = async (categoryId: bigint, brandId?: bigint) => {
  return prisma.product.create({
    data: {
      name: uniqueString("Product"),
      category_id: categoryId,
      brand_id: brandId,
    },
  });
};

export const createProductVariant = async (productId: bigint, price: number) => {
  return prisma.product_variant.create({
    data: {
      product_id: productId,
      sku: uniqueString("SKU"),
      variant_name: "Default",
      price,
    },
  });
};

export const createInventory = async (branchId: bigint, productVariantId: bigint, quantity: number) => {
  return prisma.inventory.create({
    data: {
      branch_id: branchId,
      product_variant_id: productVariantId,
      quantity,
    },
  });
};

export const createCourt = async (branchId: bigint) => {
  return prisma.court.create({
    data: {
      branch_id: branchId,
      name: uniqueString("Court"),
    },
  });
};

export const createTimeSlot = async (startHour: number, endHour: number) => {
  return prisma.time_slot.create({
    data: {
      start_time: new Date(`1970-01-01T${startHour.toString().padStart(2, "0")}:00:00Z`),
      end_time: new Date(`1970-01-01T${endHour.toString().padStart(2, "0")}:00:00Z`),
      sort_order: idCounter++, // needs unique sort_order
    },
  });
};

export const createCourtPrice = async (courtId: bigint, timeSlotId: bigint, price: number) => {
  return prisma.court_price.create({
    data: {
      court_id: courtId,
      time_slot_id: timeSlotId,
      price,
    },
  });
};

export const createVoucher = async (params: {
  discountType: "FIXED" | "PERCENT",
  discountValue: number,
  targetType?: "ALL" | "ORDER" | "BOOKING",
  usageLimit?: number,
  perUserLimit?: number,
  minOrderAmount?: number
}) => {
  return prisma.voucher.create({
    data: {
      code: uniqueString("VOUCHER").toUpperCase(),
      title: "Test Voucher",
      discount_type: params.discountType,
      discount_value: params.discountValue,
      target_type: params.targetType ?? "ALL",
      usage_limit: params.usageLimit,
      per_user_limit: params.perUserLimit,
      min_order_amount: params.minOrderAmount,
    },
  });
};
