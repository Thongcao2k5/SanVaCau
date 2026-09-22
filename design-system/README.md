# Hệ Thống Thiết Kế Sân&Cầu (Design System)

**Bắt đầu thiết kế App:** đọc [APP_UI_RULES.md](./APP_UI_RULES.md), sau đó mở [app-ui-preview.html](./app-ui-preview.html). [APP_UI_PLAN.md](./APP_UI_PLAN.md) ghi phạm vi thiết kế và bước triển khai sau này. Đợt này chỉ tạo tài liệu và preview trong `design-system/`.

Thư mục này chứa toàn bộ tài nguyên, quy chuẩn và công cụ xem trước giao diện cho hệ thống **Sân&Cầu** (dùng chung cho cả **Flutter Mobile App** và **Web App**).

---

## 📂 Cấu Trúc Thư Mục

```text
design-system/
├── showcase.html                 # Trang showroom tương tác trực quan (Mockups + Component Library)
├── assets/
│   ├── icons/                    # Bộ icon vector SVG thể thao độc quyền
│   │   ├── racket.svg            # Vợt cầu lông
│   │   ├── shuttlecock.svg       # Quả cầu lông
│   │   ├── court.svg             # Sân cầu lông
│   │   └── shoes.svg             # Giày cầu lông
│   └── images/                   # Hình ảnh mẫu sản phẩm và cụm sân thực tế
│       ├── racket_astrox.jpg     # Vợt Yonex Astrox 88D Pro
│       ├── shoes_yonex.jpg       # Giày Yonex Power Cushion 65Z3
│       └── court_indoor.jpg      # Sân thi đấu thảm Yonex
└── README.md                     # Tài liệu hướng dẫn này
```

---

## 🌟 Các Quy Chuẩn UI Đã Được Chuẩn Hóa

Trang [showcase.html](./showcase.html) cung cấp bản mô phỏng trực quan tương tác 100% cho các thành phần:

1. **Giao diện Trang Chủ (Home):**
   - Định vị chi nhánh (`branch`).
   - Hero Section (`HomeHeroSection`) tông đỏ `#DC2626` với 2 nút CTA "Đặt sân" & "Sản phẩm".
   - Khám phá nhanh 4 ô (`HomeQuickActions`): Đặt sân, Sản phẩm, Tin tức, Chi nhánh.
   - Sản phẩm nổi bật (`featured_products_section`).

2. **Giao diện Cửa Hàng (Products):**
   - Bộ lọc danh mục (`category`) & thương hiệu (`brand`).
   - Thẻ sản phẩm chuẩn cấu trúc `product_card.dart` trong Flutter.
   - Drawer xem biến thể (Size 39-43 hoặc 3U/4U) và tình trạng tồn kho (`inventory`).

3. **Giao diện Đặt Sân (Court Booking):**
   - Thanh chọn ngày (Date Scroller).
   - Bảng Ma Trận Sân & Khung Giờ (`court` x `time_slot`).
   - Phân biệt trạng thái: Còn trống (`#F0FDF4`), Đang chọn (`#DC2626`), Đã kín lịch (mờ).
   - Thanh Sticky Bar tính tổng tiền theo thời gian thực (Real-time Calculator).

4. **Thư Viện Components Đầy Đủ:**
   - **Icon Vector riêng:** Vợt, Cầu, Sân, Giày dạng SVG sắc nét.
   - **Hệ thống Nút bấm:** Primary Red (`#DC2626`), Outlined, Ghost, Disabled.
   - **Điều khiển nhập liệu:** Combobox chọn chi nhánh/size, Switch Box lọc sân máy lạnh, Radio chọn phương thức thanh toán, Checkbox dịch vụ đi kèm.
   - **Trạng thái tải (Loading):** Shimmer skeleton loaders.
   - **Màn hình động:** FlashScreen Splash khởi động với logo thể thao và Modal Confirm xác nhận đặt sân / hủy đơn.

---

## 🚀 Cách Mở Và Xem Trước

Mở trực tiếp file [design-system/showcase.html](./showcase.html) bằng bất kỳ trình duyệt nào (Safari, Chrome, Edge) mà không cần cài đặt hoặc chạy server phụ thuộc.
