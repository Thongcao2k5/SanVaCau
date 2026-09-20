# Quy Chuẩn Hệ Thống Thiết Kế UI/UX Dùng Chung (Design System Rules)

Tài liệu này định nghĩa hệ thống **Design Tokens** và **Quy chuẩn Component** dùng chung cho cả **Mobile App (Flutter)** và **Web App**, đảm bảo mọi màn hình do AI Agent hoặc Developer tạo ra đều có cùng một ngôn ngữ thiết kế, màu sắc, phong cách và trải nghiệm người dùng nhất quán.

---

## 1. Triết Lý Thiết Kế & Định Vị Thương Hiệu (Design Philosophy)

Hệ sinh thái **Sân&Cầu** là sự kết hợp giữa **Hệ thống Đặt Sân Cầu Lông (Badminton Court Booking)** và **Cửa Hàng Thể Thao Chuyên Nghiệp (Pro Shop)**:
- **Tone màu nhận diện (Brand Identity):** **Đỏ Thể Thao Yonex / Crimson Red (`#DC2626`)** kết hợp nền phớt ấm (`#FFFBFB`) và viền thẻ đỏ nhạt (`#FECACA`). Màu đỏ biểu trưng cho tốc độ, nhiệt huyết thể thao và độ chính xác cao.
- **Trải nghiệm:** Hiện đại, trực quan, thao tác nhanh để người dùng đặt sân và mua dụng cụ cầu lông chỉ trong 2-3 bước chạm.
- **Tính nhất quán:** Dù chạy trên Flutter (iOS/Android) hay Web (Responsive), toàn bộ màu sắc, bo góc, khoảng cách (spacing) và kiểu chữ đều dùng chung một bộ Token được quy định dưới đây.

---

## 2. Bảng Mã Design Tokens (Tokens Specification)

### A. Bảng Màu Chuẩn (Đồng bộ với `AppColors` trong Flutter & CSS Web)

| Token Name | Hex Code | Ý Nghĩa / Mục Đích | Ánh Xạ Flutter (`AppColors`) | Ánh Xạ Web (`CSS / Tailwind`) |
| :--- | :--- | :--- | :--- | :--- |
| **`primary`** | `#DC2626` | Đỏ thể thao nhận diện (Yonex Red) | `Color(0xFFDC2626)` | `var(--primary)` / `red-600` |
| **`primary-dark`** | `#991B1B` | Đỏ sẫm (Nút khi bấm, hover, header nhấn) | `Color(0xFF991B1B)` | `var(--primary-dark)` / `red-800` |
| **`primary-soft`** | `#FCE7E7` | Đỏ nền nhạt (Badge, icon background) | `Color(0xFFFCE7E7)` | `var(--primary-soft)` / `red-100` |
| **`border-color`** | `#FECACA` | Đường viền thẻ card phớt đỏ nhẹ | `Color(0xFFFECACA)` | `var(--border-color)` / `red-200` |
| **`bg-main`** | `#FFFBFB` | Nền tổng thể trang (Light mode) | `Color(0xFFFFFBFB)` | `var(--bg-main)` |
| **`surface`** | `#FFFFFF` | Nền thẻ Card sản phẩm, Card sân, Dialog | `Color(0xFFFFFFFF)` | `var(--surface)` / `white` |
| **`text-primary`** | `#1F2937` | Tiêu đề, chữ chính (Đậm, rõ nét) | `Color(0xFF1F2937)` | `var(--text-primary)` / `gray-800` |
| **`text-secondary`**| `#64748B` | Chú thích, địa chỉ, mô tả phụ | `Color(0xFF64748B)` | `var(--text-secondary)` / `slate-500` |
| **`status-free`** | `#16A34A` | Khung giờ còn trống (Xanh lá thể thao) | `Color(0xFF16A34A)` | `var(--status-free)` / `green-600` |
| **`status-booked`** | `#94A3B8` | Khung giờ đã kín / Hết hàng (Xám) | `Color(0xFF94A3B8)` | `var(--text-muted)` / `slate-400` |

---

### B. Kiểu Chữ (Typography Hierarchy)
- **Font Family chuẩn:** Sử dụng **`Plus Jakarta Sans`** hoặc **`Be Vietnam Pro`**.

| Cấp Bậc | Kích Thước | Trọng Số | Sử Dụng |
| :--- | :--- | :--- | :--- |
| **Heading 1** | `22px` - `26px` | `800` (Bold) | Tiêu đề Hero Banner ("Đặt sân nhanh, mua đồ dễ dàng") |
| **Heading 2** | `18px` - `20px` | `700` (Bold) | Tiêu đề màn hình (Sản phẩm, Đặt sân) |
| **Heading 3** | `15px` - `16px` | `700` (SemiBold) | Tên mục ("Khám phá nhanh", "Sản phẩm nổi bật") |
| **Body Large** | `14px` | `700` | Tên sản phẩm, Tên sân, Nút bấm CTA |
| **Body Small** | `12px` - `13px` | `400` - `500` | Mô tả ngắn sản phẩm, địa chỉ chi nhánh |
| **Caption/Tag**| `10px` - `11px` | `600` (SemiBold) | Nhãn thương hiệu (Yonex, Victor), SKU biến thể |

---

### C. Khoảng Cách (Spacing) & Bo Góc (Border Radius)
- **Spacing:** `xs: 4px` | `sm: 8px` | `md: 12px` | `lg: 16px` (mặc định) | `xl: 20px`.
- **Border Radius:**
  - `6px` - `8px`: Dành cho Card sản phẩm (`ProductCard` bo 8px), ô chọn size biến thể.
  - `10px` - `12px`: Dành cho Nút CTA, ô khung giờ trong ma trận sân.
  - `18px`: Dành cho Hero Card (`HomeHeroSection`).
  - `9999px`: Dành cho Pill tag lọc danh mục, thanh chi nhánh.

---

## 3. Quy Chuẩn Các Component Cốt Lõi (Core Components)

### 1. Home Hero Banner (`HomeHeroSection`):
- Background: `AppColors.primary` (`#DC2626`), bo góc `18px`, đổ bóng `box-shadow: 0 10px 18px rgba(220, 38, 38, 0.22)`.
- Chứa tag "SanVaCau App", tiêu đề 2 dòng đậm, 2 nút bấm:
  - Nút chính "Đặt sân" (Nền trắng, chữ đỏ `#DC2626`).
  - Nút phụ "Sản phẩm" (Viền trắng, chữ trắng).

### 2. Phím Tắt Khám Phá Nhanh (`HomeQuickActions`):
- Lưới 2x2 gồm 4 Card bo góc 8px, có viền đỏ nhạt `#FECACA`:
  - **Đặt sân:** Icon xanh lá (`#16A34A` / nền nhạt `#DCFCE7`).
  - **Sản phẩm:** Icon đỏ thể thao (`#DC2626` / nền nhạt `#FCE7E7`).
  - **Tin tức:** Icon xanh dương (`#2563EB` / nền nhạt `#DBEAFE`).
  - **Chi nhánh:** Icon tím (`#7C3AED` / nền nhạt `#F3E8FF`).

### 3. Thẻ Sản Phẩm (`ProductCard`):
- Bo góc `8px`, viền `#FECACA`, padding `12px`.
- Bên trái: Khung ảnh kích thước `82x82px`, bo góc `8px`, nền `rgba(220, 38, 38, 0.08)`.
- Bên phải:
  - Tên sản phẩm (Font `14px`, Bold, tối đa 2 dòng).
  - Tên Thương hiệu (Màu `#DC2626` in đậm).
  - Tên Danh mục + Biến thể (Màu xám `AppColors.textSecondary`).
  - Mô tả ngắn (2 dòng rút gọn `ellipsis`).
  - Khoảng giá (`product_variant.price`) in đậm màu đỏ.
  - Icon mũi tên chuyển hướng (`›`).

### 4. Ma Trận Đặt Sân (`CourtBookingMatrix`):
- **Cấu trúc:** Cột là các sân (`court`: Sân 1, Sân 2...) thuộc Chi nhánh (`branch`); Hàng là các khung giờ (`time_slot`: 06:00 - 23:00).
- **Ô thời gian (Cell Slot):**
  - **Trống (Available):** Nền xanh lá nhạt `#F0FDF4`, viền `#BBF7D0`, chữ xanh sẫm `#166534`, hiển thị giá niêm yết theo giờ (`court_price`).
  - **Đang chọn (Selected):** Đổi sang màu đỏ `AppColors.primary` (`#DC2626`), chữ trắng in đậm.
  - **Đã đặt (Booked):** Nền xám mờ `#F1F5F9`, gạch ngang chữ, không thể click.
- **Thanh tổng hợp (Sticky Booking Bar):** Hiển thị số khung giờ đã chọn và tổng tiền VNĐ tính theo thời gian thực + Nút "Đặt sân ngay" màu đỏ.

---

## 4. Quy Tắc Bắt Buộc Dành Cho Agent Khi Sinh Mã UI

1. **Tuyệt đối không dùng mã màu tùy tiện:** Cả Flutter và Web đều phải gọi qua hằng số tokens (`AppColors.primary` trong Flutter hoặc `var(--primary)` trên Web).
2. **Tuân thủ đúng dữ liệu từ Schema PostgreSQL:**
   - Sản phẩm luôn gắn với `category` và `brand`.
   - Giá bán lấy theo `product_variant.price`.
   - Sân cầu thuộc `branch`, giá sân lấy theo `court_price` ứng với `time_slot`.
3. **Định dạng tiền tệ chuẩn:** Mọi mức giá hiển thị phải định dạng tiền tệ VNĐ (VD: `4.200.000 đ` hoặc `120.000 đ/giờ`).
