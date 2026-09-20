# Quy Tắc Thiết Kế & Kiến Trúc (Architecture & Design Rules)

Dự án **Sân&Cầu** tuân thủ mô hình kiến trúc phân lớp rõ ràng (Layered / Clean Architecture) nhằm tách biệt giữa giao diện, luồng xử lý nghiệp vụ và lưu trữ dữ liệu.

---

## 1. Kiến Trúc Tổng Thể (System Architecture)
```text
[Flutter Client] 
      │ (HTTPS / JSON REST API)
      ▼
[Express Server] 
      │ (Router)
      ▼
[Controllers] ── (Data Validation)
      │
      ▼
[Services] ───── (Business Logic: Pricing, Slot Availability, Match Algorithm)
      │
      ▼
[Prisma ORM] ─── (Database Abstraction)
      │
      ▼
[PostgreSQL DB]
```

---

## 2. Quy Chuẩn Kiến Trúc Backend (`backend/`)

Bố trí thư mục trong `backend/src/` theo cấu trúc:
```text
backend/src/
├── config/           # Cấu hình môi trường, Prisma client instance, constants
├── controllers/      # Tiếp nhận HTTP request, gọi service, trả response
├── services/         # Toàn bộ business logic (không thao tác trực tiếp với req/res)
├── routes/           # Định nghĩa router và middleware tương ứng
├── middlewares/      # Auth (JWT), Validation, Error handler, Request logger
├── types/            # TypeScript interfaces, DTOs, Enums
└── utils/            # Các hàm tiện ích dùng chung (format date, hash password...)
```

### Nguyên tắc phân tầng:
1. **Router:** Chỉ chịu trách nhiệm kết nối URL path với Middleware và Controller tương ứng.
2. **Controller:** 
   - Nhận `req` và `res`.
   - Validate tham số đầu vào.
   - Gọi hàm từ tầng `Service`.
   - Trả về HTTP status code phù hợp (`200 OK`, `201 Created`, `400 Bad Request`, `404 Not Found`...).
   - **Tuyệt đối không viết logic nghiệp vụ phức tạp trực tiếp trong Controller.**
3. **Service:**
   - Xử lý toàn bộ tính toán, điều kiện logic, gọi Prisma để đọc/ghi database.
   - Tầng Service hoàn toàn độc lập với Express `req` / `res`, giúp dễ dàng viết Unit Test.
4. **Chuẩn REST API Response Format:**
   Mọi API trả về định dạng JSON nhất quán:
   ```json
   // Khi thành công:
   {
     "success": true,
     "data": { ... },
     "message": "Court fetched successfully"
   }

   // Khi có lỗi:
   {
     "success": false,
     "error": {
       "code": "SLOT_ALREADY_BOOKED",
       "message": "Khung giờ này đã có người đặt trước"
     }
   }
   ```

---

## 3. Quy Chuẩn Kiến Trúc Frontend (`frontend/san_va_cau_app/`)

Cấu trúc mã nguồn Flutter theo hướng **Feature-First**:
```text
lib/
├── core/             # Dùng chung cho toàn bộ app
│   ├── constants/    # Màu sắc (AppColors), cỡ chữ (AppTextStyles), API endpoints
│   ├── network/      # API client (Dio / Http wrapper), Interceptor xử lý token
│   ├── theme/        # ThemeData (Light/Dark mode)
│   ├── utils/        # Format ngày giờ, định dạng tiền VNĐ, validators
│   └── widgets/      # Các widget UI tái sử dụng (CustomButton, CustomTextField...)
└── features/         # Từng phân hệ tính năng độc lập
    ├── auth/         # Đăng nhập, đăng ký, quên mật khẩu
    ├── court/        # Xem danh sách sân, chi tiết sân, hình ảnh sân
    ├── booking/      # Chọn khung giờ, đặt sân, thanh toán
    ├── match/        # Tìm bạn đấu, ghép trận cầu lông
    └── profile/      # Quản lý hồ sơ, lịch sử đặt sân
```

### Nguyên tắc giao diện:
- Không hardcode màu sắc (VD: `Color(0xFF123456)`) hoặc kích thước chữ rải rác trong widget; hãy định nghĩa tập trung trong `core/constants/` hoặc `AppTheme`.
- Chia nhỏ Widget thành các sub-widget riêng biệt, tránh một hàm `build()` vượt quá 100 dòng.
- Luôn hỗ trợ cả màn hình kích thước nhỏ và lớn, tránh lỗi tràn viền (RenderFlex overflow).
