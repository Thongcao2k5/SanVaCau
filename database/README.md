# Database mẫu từ môi trường local

`schema.sql` tạo cấu trúc tương thích với Prisma hiện tại. `data.sql` chứa snapshot dữ liệu local: sản phẩm, chi nhánh, sân, bảng giá 30 phút từ 06:00–22:00, lịch đặt sân và nội dung app. `counts.json` ghi số bản ghi từng bảng.

Clone nhánh `tesst/thuc_branch`, tạo một database PostgreSQL **trống**, rồi trong thư mục `backend`:

```powershell
Copy-Item .env.example .env
# Sửa DATABASE_URL và JWT_SECRET trong .env theo máy của bạn.
npm ci
npx prisma generate
npm run db:restore-demo
npm run dev
```

Không chạy `prisma db push` hoặc `npm run seed` trước khi nhập snapshot. Lệnh nhập từ chối database đã có bảng và không ghi đè dữ liệu. Database không tự được cài đặt chỉ bằng thao tác clone; cần chạy lệnh nhập trên.

Tài khoản demo trong snapshot:

| Vai trò | Email | Mật khẩu |
| --- | --- | --- |
| Quản trị | admin-1@example.com | Admin123456 |
| Khách hàng | customer-3@example.com | Customer123456 |

Đây là tài khoản demo cho phát triển local. Email, tên, số điện thoại, địa chỉ và mật khẩu gốc đã được thay thế trong bản xuất. OTP, audit log, liên hệ/hỗ trợ khách hàng và cấu hình riêng tư không được xuất. Database nguồn không bị thay đổi. Tồn kho theo chi nhánh ở database cũ được cộng gộp thành tồn kho toàn hệ thống theo schema app.

Snapshot giữ cả lịch đặt hiện có, nên một số giờ có thể đã được đặt. Chọn ngày khác để thử tạo lịch mới.

Để tạo lại snapshot sau khi cập nhật dữ liệu local:

```powershell
npx prisma migrate diff --from-empty --to-schema prisma/schema.prisma --script --output ../database/schema.sql
npm run db:export-demo
```

Kiểm tra lại bản xuất trước khi chia sẻ; tài khoản demo được tạo theo ID tài khoản trong database nguồn.
