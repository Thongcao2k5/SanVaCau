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
4. **Quy Chuẩn Tiêu Đề & Nút Back (Topbar / AppBar Navigation Spec):**
   - **Màn hình KHÔNG NÊN CÓ nút Back (Root / Top-level Screens):**
     - *Splash & Onboarding (Màn 01, 02):* Tự chuyển cảnh hoặc dùng nút "Bỏ qua".
     - *6 Tab điều hướng chính (Màn 04 Trang chủ, 05 Pro Shop, 08 Chọn sân, 12 Ghép kèo, 13 Lịch sử, 14 Tài khoản):* Đây là các màn hình cấp cao nhất (Root Views) được chuyển đổi qua Bottom Navigation Bar. Tuyệt đối không đặt nút Back ở các màn hình này; Header chỉ hiển thị Brand Logo, Vị trí chi nhánh, Thanh tìm kiếm, Chuông thông báo hoặc Cài đặt.
   - **Màn hình BẮT BUỘC PHẢI CÓ nút Back (Child / Flow / Detail Screens):**
     - *Màn hình xác thực (Màn 03 Đăng nhập, 15 Đăng ký, 16 Quên mật khẩu):* Nút Back góc trái để quay về màn hình trước đó.
     - *Màn hình con & Luồng thao tác (Màn 06 Chi tiết SP, 07 Giỏ hàng, 09 Ma trận giờ, 10 Đặt sân, 11 Vé QR, 17 Thanh toán, 18 Chi tiết đơn, 19 Sửa hồ sơ, 20 Sổ địa chỉ, 21 Ví voucher):* Bắt buộc có nút Back để người dùng quay lại mà không bị kẹt luồng.
   - **Quy tắc Neo Cố Định (Sticky Topbar Pinning):**
     - Mọi Topbar chứa nút Back ở các màn hình con có nội dung cuộn (Đặc biệt: Màn 06, 07, 09, 10, 11, 17, 18, 19, 20, 21) **BẮT BUỘC PHẢI NEO CỐ ĐỊNH Ở ĐỈNH** (`position: sticky; top: 0; z-index: 30 / 40; background: white` hoặc glassmorphism `rgba(255,255,255,0.95); backdrop-filter: blur(12px); border-bottom: 1px solid var(--border)`).
     - Khi người dùng cuộn nội dung dài (lưới ma trận 17 khung giờ sân, gallery ảnh, thông số kỹ thuật, vé QR), **nút Back và Tiêu đề KHÔNG ĐƯỢC trôi mất** mà luôn giữ cố định ở đỉnh để bấm quay về tức thì.
   - **Định dạng Tiêu đề:**
     - Tiêu đề màn hình luôn là 1 dòng duy nhất (`white-space: nowrap`), không chèn các tag rườm rà (mã đơn, tag shop) gây tràn dòng.
     - Nút Back chuẩn: Class `.icon-round-btn`, touch target 36×36px, icon mũi tên `line x1="19" y1="12" x2="5" y2="12"`, viền tròn tinh tế.
5. **Khung chứa & Khoảng đệm màn hình con (Secondary / Commerce Screens):**
   - Thẻ container `.screen-content`: Tuyệt đối không đặt `padding` toàn khung (`padding: 0`) ở các màn hình có Topbar sticky hoặc Bottom Bar dính đáy.
   - Topbar đặt chuẩn: `position: sticky; top: 0; z-index: 30; padding: 14px 16px 10px; background: white; border-bottom: 1px solid var(--border);`.
   - Các khối thẻ card / tabs / danh sách con: Luôn căn lề đều `margin: 0 16px 12px;` để canh lề 16px hai bên đồng bộ tuyệt đối với Topbar và khung nhìn chuẩn.
6. **Bộ lọc Sản phẩm Pro Shop (`ProductFilterSheet`):**
   - Không dàn trải các chip filter phụ dài ngắn khác nhau (`sub-filter-row`) trực tiếp trên feed chính của màn hình Pro Shop để tránh rối mắt và chiếm diện tích hiển thị sản phẩm.
   - Các tiêu chí lọc chuyên sâu (Thương hiệu, Khoảng giá, Độ cứng thân vợt, Điểm cân bằng) được gom gọn gàng trong `ModalBottomSheet` (hoặc Bottom Sheet vuốt lên).
   - Nút mở bộ lọc cạnh thanh tìm kiếm hiển thị huy hiệu số lượng tiêu chí đang kích hoạt (VD: badge `2`).
7. **Quy Chuẩn Ghim Đáy Cho Thanh Thanh Toán & Hành Động (Sticky Bottom Checkout / Action Bar):**
   - **Bắt buộc ghim dính đáy (`margin-top: auto`):** Đối với các màn hình thanh toán hoặc có thanh tác vụ đáy (Màn 06, 07, 10, 17, 18), thanh đáy PHẢI LUÔN LUÔN nằm sát mép dưới màn hình.
     - *Lý do kỹ thuật (Web/CSS):* Trong flexbox column, khi nội dung ngắn (VD: giỏ hàng 1-2 món ở Màn 07, form xác nhận ở Màn 10), `position: sticky; bottom: 0` chỉ có tác dụng khi cuộn, dẫn đến việc thanh bị kéo lên lơ lửng giữa màn hình tạo khoảng trống hở đáy. Thuộc tính `margin-top: auto;` hấp thụ toàn bộ khoảng trống thừa theo chiều dọc và đẩy thanh sát đáy tuyệt đối.
     - *Trong Flutter:* Luôn đặt thanh hành động trong thuộc tính `bottomNavigationBar: SafeArea(...)` của `Scaffold`, hoặc bọc nội dung cuộn trong `Expanded(child: SingleChildScrollView(...))` và đặt thanh cố định bên dưới trong `Column`.
   - **Khung chứa tràn viền (`padding: 0`):** Container `.screen-content` phải đặt `padding: 0` để thanh đáy và Topbar chạm sát viền màn hình (Edge-to-Edge 100% width), không để padding toàn khung làm thanh đáy bị co lọt thỏm tạo viền trắng thừa xung quanh.
   - **Chống co rúm card (`flex-shrink: 0`):** Tất cả các card/khối con trong container (`.screen-content > *`) phải khai báo `flex-shrink: 0;` để không bị ép co dẹp chiều cao khi màn hình ngắn hoặc nội dung nở rộng.
   - **Đồng bộ bố cục 2 khối chuẩn:**
     - Trái: Nhãn phụ (`Tổng thanh toán:`) + Số tiền VNĐ nổi bật (Đỏ Yonex `#DC2626`, font 16.5px Bold 900).
     - Phải: Nút CTA chính cao 46px, bo R14 (`--r-md`), nhãn 2 dòng (Dòng 1: Tiêu đề hành động 12.5px Bold 800; Dòng 2: Chi tiết 8.5px opacity 85%), icon điều hướng 17px.
     - Home Indicator: Thanh capsule xám `#CBD5E1` (124px × 4.5px) tại `bottom: 7px` căn giữa chuẩn iOS HIG.

---

## 5. Quy Chuẩn Đáy Màn Hình & Vùng An Toàn (Bottom Margins & Safe Area Spec)

Mọi màn hình trên Mobile App và Web đều phải tuân thủ 1 trong 4 nhóm quy chuẩn đáy:

### 1. Nhóm 1: Floating Bottom Navigation (6 Tab chính)
* **Áp dụng:** 04 Dashboard, 05 Pro Shop, 08 Chi Nhánh, 12 Ghép Kèo, 13 Lịch Sử, 14 Tài Khoản.
* **Quy cách:**
  - Thanh capsule nổi: Cao `52px`, bo góc `9999px`, nền glassmorphism `rgba(255,255,255,0.92)` blur 20px.
  - **Khoảng cách đáy cố định:** Đúng `12px` (`bottom: 12px; margin-bottom: 0;`).
  - Container cuộn phải có `padding-bottom: 12px;` kèm khoảng đệm an toàn `68px` cho nội dung cuối cùng.

### 2. Nhóm 2: Sticky Edge-to-Edge Bottom Checkout Bar (Thanh Thanh Toán Dính Đáy)
* **Áp dụng:** 06 Chi Tiết SP, 07 Giỏ Hàng, 10 Đặt Sân, 17 Mua Hàng Pro Shop, 18 Chi Tiết Đơn Hàng.
* **Quy cách:**
  - Trải dài 100% mép-đến-mép (`width: 100%`), nền trắng `#FFFFFF`, viền trên `1px solid var(--border)`, bóng đổ `0 -8px 24px rgba(31,41,55,0.1)`.
  - **Luôn đẩy dính đáy (`margin-top: auto;`):** Đảm bảo thanh luôn nằm áp sát mép dưới màn hình ngay cả khi nội dung ngắn (như Màn 07 ít món, Màn 10 ít dịch vụ), không trôi lơ lửng ở giữa khung nhìn.
  - **Khoảng đệm đáy Safe Area:** `padding: 10px 14px calc(22px + env(safe-area-inset-bottom));`.
  - **Thanh Home Indicator:** `124px × 4.5px`, bo tròn, màu `#CBD5E1`, đặt tại `bottom: 7px; left: 50%; transform: translateX(-50%)`.
  - **Layout 2 khối:**
    - Trái: `Tổng thanh toán:` (10.5px) + Số tiền (16.5px, Bold 900, đỏ Yonex `#DC2626`).
    - Phải: Nút CTA chính (Cao 46px, bo R14, nhãn 2 dòng: Tiêu đề 12.5px + Chi tiết 8.5px, icon mũi tên 17px).
  - **Mã mẫu chuẩn CSS (Web):**
    ```css
    .screen-content {
      padding: 0;
      display: flex;
      flex-direction: column;
    }
    .screen-content > * {
      flex-shrink: 0;
    }
    .checkout-bottom-bar {
      position: sticky;
      bottom: 0;
      margin-top: auto;
      width: 100%;
      background: #FFFFFF !important;
      border-top: 1px solid var(--border);
      padding: 10px 14px calc(22px + env(safe-area-inset-bottom));
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      z-index: 50;
      box-shadow: 0 -8px 24px rgba(31,41,55,0.1);
    }
    ```
  - **Mã mẫu chuẩn Dart (Flutter):**
    ```dart
    Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(...),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng thanh toán:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('600.000đ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
              ElevatedButton(...),
            ],
          ),
        ),
      ),
    );
    ```

### 3. Nhóm 3: Full-Width Single Action CTA (Nút Đơn Lẻ Cuối Màn Hình & Form Cuộn)
* **Áp dụng:** 06 Chi Tiết Sản Phẩm (Mua ngay), 15 Đăng Ký (Đăng ký tài khoản), 16 Quên Mật Khẩu (Xác nhận & đổi MK), 18 Chi Tiết Đơn Hàng (Xem vị trí tài xế), 19 Sửa Hồ Sơ (Lưu thay đổi), 20 Sổ Địa Chỉ (Thêm địa chỉ nhận hàng).
* **Quy cách Chuẩn:**
  - **BẮT BUỘC PHẢI ĐƯỢC NEO LẠI (STICKY BOTTOM)** khi người dùng cuộn: `position: sticky; bottom: 0; margin-top: auto; z-index: 40;`.
  - Thanh neo đáy luôn có **nền trắng**, viền trên `1px solid var(--border)`, đổ bóng nhẹ phía trên `box-shadow: 0 -8px 24px rgba(0,0,0,0.08)`, đệm đáy an toàn `calc(24px + env(safe-area-inset-bottom))` tích hợp Home Indicator thanh xám mảnh (`#CBD5E1`).
  - Nút bấm chính full-width cao `46px - 48px` (Touch target chuẩn Apple HIG), bo góc `14px` (`--r-md`), chữ đậm 800, icon sắc nét.
  - Form cuộn bên trên phải có khoảng đệm cuối (`padding-bottom: 12px - 16px`) để nội dung trường nhập liệu cuối cùng không bao giờ bị che khuất sau thanh neo đáy.
  - *Ngoại lệ duy nhất:* Màn 03 Đăng nhập hoặc Màn 02 Onboarding nếu toàn bộ nội dung nằm vừa trọn vẹn trong 1 viewport không phát sinh thanh cuộn.

### 4. Nhóm 4: Scrollable Card List (Màn Hình Cuộn Không Nút Đáy)
* **Áp dụng:** 11 Vé QR, 21 Ví Voucher.
* **Quy cách:** Thẻ card cuối cùng luôn có `margin-bottom: 24px` hoặc container có `padding-bottom: 24px`. Tuyệt đối không để card dính sát mép đáy `0px`.
