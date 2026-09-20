# Quy Chuẩn Lập Trình (Coding Standards)

Tài liệu này quy định các tiêu chuẩn về cú pháp, kiểu dữ liệu và cách viết code cho Backend (TypeScript) và Frontend (Flutter / Dart).

---

## 1. Tiêu Chuẩn Backend (Node.js + TypeScript + Prisma)

### TypeScript:
- **Nghiêm cấm lạm dụng kiểu `any`:** 
  - Luôn định nghĩa rõ ràng kiểu dữ liệu (`interface` hoặc `type`).
  - Trong trường hợp chưa xác định kiểu dữ liệu từ bên thứ 3, dùng `unknown` kèm Type Guard hoặc Zod schema validator thay vì `any`.
- **Xử lý Bất đồng bộ (Async/Await):**
  - Luôn sử dụng cú pháp `async/await` thay vì lồng ghép `.then().catch()`.
  - Bao bọc các lời gọi bất đồng bộ với khối `try/catch` hoặc dùng async wrapper để chuyển lỗi về Express Error Middleware:
    ```typescript
    try {
      const result = await bookingService.createBooking(data);
      return res.status(201).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
    ```

### Prisma & Database:
- Đặt tên Model trong `schema.prisma` theo chuẩn **PascalCase** số ít: `User`, `Court`, `Booking`, `TimeSlot`.
- Tên trường trong bảng theo chuẩn **camelCase**: `courtId`, `startTime`, `createdAt`.
- Quan hệ nhiều-nhiều hoặc logic ghi đồng thời (ví dụ: trừ tiền và giữ chỗ sân) bắt buộc sử dụng **Prisma Interactive Transactions (`prisma.$transaction`)** để tránh xung đột dữ liệu (race conditions).

---

## 2. Tiêu Chuẩn Frontend (Flutter + Dart)

### Dart Conventions:
- Đặt tên file: **`snake_case.dart`** (ví dụ: `court_detail_screen.dart`, `booking_card.dart`).
- Đặt tên Class/Widget: **`PascalCase`** (ví dụ: `CourtDetailScreen`, `BookingCard`).
- Đặt tên biến, hàm: **`camelCase`** (ví dụ: `fetchCourts()`, `selectedSlot`).
- Đặt tên hằng số: **`camelCase`** hoặc **`lowerCamelCase`** theo chuẩn chính thức của Dart (ví dụ: `kPrimaryColor`, `apiBaseUrl`).

### Tối ưu Hiệu năng Widget:
- **Luôn thêm từ khóa `const`** trước các Widget không thay đổi trạng thái để Flutter không phải rebuild lại trên widget tree:
  ```dart
  // Đúng:
  const SizedBox(height: 16);
  const Text('Danh sách sân cầu lông');

  // Sai:
  SizedBox(height: 16);
  Text('Danh sách sân cầu lông');
  ```
- **Null Safety chặt chẽ:** 
  - Tuyệt đối hạn chế sử dụng toán tử force unwrap `!`.
  - Sử dụng toán tử an toàn: `?.` (null-aware), `??` (fallback default value).
- Không gọi hàm bất đồng bộ nặng hoặc gọi API trực tiếp trong hàm `build()`. Chỉ gọi trong `initState()` hoặc thông qua State Management (Riverpod / Bloc / Provider).
