import { Router, type Request, type Response } from "express";

export const metadataRouter = Router();

type MetadataOption = {
  value: string;
  label: string;
  description?: string;
};

type MetadataGroups = Record<string, MetadataOption[]>;

const metadata: MetadataGroups = {
  roles: [
    { value: "ADMIN", label: "Quản trị viên", description: "Toàn quyền quản lý hệ thống" },
    { value: "BRANCH_MANAGER", label: "Quản lý chi nhánh", description: "Quản lý hoạt động chi nhánh" },
    { value: "STAFF", label: "Nhân viên", description: "Nhân viên vận hành" },
    { value: "CUSTOMER", label: "Khách hàng", description: "Người dùng cuối" },
  ],

  userStatuses: [
    { value: "ACTIVE", label: "Hoạt động" },
    { value: "INACTIVE", label: "Ngừng hoạt động" },
    { value: "BLOCKED", label: "Bị khóa" },
  ],

  branchStatuses: [
    { value: "ACTIVE", label: "Hoạt động" },
    { value: "INACTIVE", label: "Ngừng hoạt động" },
  ],

  courtStatuses: [
    { value: "ACTIVE", label: "Hoạt động" },
    { value: "INACTIVE", label: "Ngừng hoạt động" },
    { value: "MAINTENANCE", label: "Bảo trì" },
  ],

  orderStatuses: [
    { value: "PENDING", label: "Chờ xử lý" },
    { value: "CONFIRMED", label: "Đã xác nhận" },
    { value: "READY_FOR_PICKUP", label: "Sẵn sàng lấy hàng" },
    { value: "COMPLETED", label: "Hoàn thành" },
    { value: "CANCELLED", label: "Đã hủy" },
  ],

  bookingStatuses: [
    { value: "BOOKED", label: "Đã đặt" },
    { value: "CHECKED_IN", label: "Đã check-in" },
    { value: "COMPLETED", label: "Hoàn thành" },
    { value: "CANCELLED", label: "Đã hủy" },
  ],

  paymentStatuses: [
    { value: "PENDING", label: "Chờ thanh toán" },
    { value: "COMPLETED", label: "Đã thanh toán" },
    { value: "FAILED", label: "Thất bại" },
    { value: "REFUNDED", label: "Đã hoàn tiền" },
  ],

  paymentProviders: [
    { value: "CASH", label: "Tiền mặt" },
    { value: "MOMO", label: "MoMo" },
    { value: "VNPAY", label: "VNPay" },
    { value: "BANK_TRANSFER", label: "Chuyển khoản ngân hàng" },
    { value: "MOCK", label: "Thanh toán thử nghiệm" },
  ],

  paymentTargetTypes: [
    { value: "ORDER", label: "Đơn hàng" },
    { value: "BOOKING", label: "Đặt sân" },
  ],

  fulfillmentTypes: [
    { value: "PICKUP", label: "Nhận tại quầy" },
    { value: "DELIVERY", label: "Giao hàng" },
  ],

  fulfillmentStatuses: [
    { value: "PENDING", label: "Chờ xử lý" },
    { value: "PREPARING", label: "Đang chuẩn bị" },
    { value: "READY_FOR_PICKUP", label: "Sẵn sàng lấy hàng" },
    { value: "SHIPPING", label: "Đang giao hàng" },
    { value: "DELIVERED", label: "Đã giao" },
    { value: "PICKED_UP", label: "Đã nhận hàng" },
    { value: "CANCELLED", label: "Đã hủy" },
  ],

  supportTicketCategories: [
    { value: "ORDER", label: "Đơn hàng" },
    { value: "BOOKING", label: "Đặt sân" },
    { value: "PAYMENT", label: "Thanh toán" },
    { value: "ACCOUNT", label: "Tài khoản" },
    { value: "OTHER", label: "Khác" },
  ],

  supportTicketStatuses: [
    { value: "OPEN", label: "Mở" },
    { value: "IN_PROGRESS", label: "Đang xử lý" },
    { value: "RESOLVED", label: "Đã giải quyết" },
    { value: "CLOSED", label: "Đã đóng" },
  ],

  supportTicketPriorities: [
    { value: "LOW", label: "Thấp" },
    { value: "NORMAL", label: "Bình thường" },
    { value: "HIGH", label: "Cao" },
  ],

  voucherDiscountTypes: [
    { value: "PERCENTAGE", label: "Phần trăm" },
    { value: "FIXED_AMOUNT", label: "Số tiền cố định" },
  ],

  voucherTargetTypes: [
    { value: "ALL", label: "Tất cả" },
    { value: "ORDER", label: "Đơn hàng" },
    { value: "BOOKING", label: "Đặt sân" },
  ],

  voucherStatuses: [
    { value: "ACTIVE", label: "Hoạt động" },
    { value: "INACTIVE", label: "Ngừng hoạt động" },
  ],

  reviewStatuses: [
    { value: "PUBLISHED", label: "Đã đăng" },
    { value: "HIDDEN", label: "Ẩn" },
  ],

  newsStatuses: [
    { value: "DRAFT", label: "Bản nháp" },
    { value: "PUBLISHED", label: "Đã đăng" },
    { value: "ARCHIVED", label: "Đã lưu trữ" },
  ],

  favoriteTargetTypes: [
    { value: "PRODUCT", label: "Sản phẩm" },
    { value: "COURT", label: "Sân" },
  ],
};

metadataRouter.get("/", (_req: Request, res: Response) => {
  res.json({
    success: true,
    data: {
      ...metadata,
      updatedAt: new Date().toISOString(),
    },
  });
});

metadataRouter.get("/:group", (req: Request, res: Response) => {
  const group = req.params.group as string;

  if (!(group in metadata)) {
    res.status(404).json({ success: false, message: `Metadata group '${group}' not found` });
    return;
  }

  res.json({
    success: true,
    data: {
      [group]: metadata[group],
      updatedAt: new Date().toISOString(),
    },
  });
});
