# SanVaCau Backend Setup

Tài liệu này hướng dẫn chạy backend SanVaCau trên máy mới từ đầu.

## 1. Phần mềm cần cài

- Node.js và npm.
- PostgreSQL.
- Git nếu cần tải source code từ repository.
- Postman nếu muốn test API thủ công.

Kiểm tra Node.js và npm:

```bash
node --version
npm --version
```

## 2. Cài thư viện

Mở terminal tại thư mục `backend`, sau đó chạy:

```bash
npm install
```

Lệnh này đọc `package.json` và cài các thư viện backend vào `node_modules`.

## 3. Tạo file môi trường

Sao chép `.env.example` thành `.env`, sau đó thay các giá trị mẫu bằng cấu hình trên máy đang chạy.

PowerShell:

```powershell
Copy-Item .env.example .env
```

Ý nghĩa các biến:

| Biến | Bắt buộc | Tác dụng |
| --- | --- | --- |
| `DATABASE_URL` | Có | Chuỗi kết nối PostgreSQL mà Prisma sử dụng. |
| `PORT` | Không | Cổng của backend; mặc định là `3000`. |
| `NODE_ENV` | Không | Môi trường chạy, ví dụ `development` hoặc `production`. |
| `JWT_SECRET` | Có | Khóa bí mật để ký và kiểm tra token đăng nhập. Phải đổi thành chuỗi dài, khó đoán. |
| `SMOKE_TEST_URL` | Không | URL gốc để script smoke test gọi API; mặc định là `http://localhost:3000/api`. |

Không commit file `.env` vì file này chứa mật khẩu database và khóa JWT thật. Chỉ commit `.env.example` với giá trị mẫu.

## 4. Chuẩn bị PostgreSQL

Khởi động PostgreSQL, sau đó tạo database tên `sanvacau`. Đảm bảo user, mật khẩu, host và port trong `DATABASE_URL` đúng với PostgreSQL trên máy.

Ví dụ định dạng:

```env
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/sanvacau?schema=public"
```

## 5. Chuẩn bị Prisma và database

Tạo Prisma Client:

```bash
npx prisma generate
```

Đồng bộ schema hiện tại vào database trong môi trường phát triển:

```bash
npx prisma db push
```

Tạo dữ liệu mẫu:

```bash
npm run seed
```

Seed có thể chạy lại. Tài khoản quản trị dùng để test ở môi trường phát triển:

```text
Email: admin@shopvacau.com
Password: Admin123456
```

Không dùng mật khẩu mẫu này ở production.

## 6. Chạy backend

Chế độ phát triển:

```bash
npm run dev
```

API mặc định chạy tại `http://localhost:3000/api`. Kiểm tra nhanh bằng:

```text
GET http://localhost:3000/api/health
GET http://localhost:3000/api/health/db
```

Build và chạy bản đã biên dịch:

```bash
npm run build
npm start
```

## 7. Kiểm tra source code

Kiểm tra TypeScript mà không tạo file build:

```bash
npm run typecheck
```

Kiểm tra build:

```bash
npm run build
```

Kiểm tra nhanh các luồng API chính: trước tiên giữ backend đang chạy trong một terminal, rồi mở terminal thứ hai tại thư mục `backend` và chạy:

```bash
npm run smoke:test
```

Kết quả hiện tại mong đợi là `28 passed, 0 failed` khi PostgreSQL, seed data và backend đều sẵn sàng.

## 8. Test bằng Postman

Import file `docs/SanVaCau.postman_collection.json` vào Postman. Sau khi đăng nhập, đặt token vào biến collection hoặc gửi header:

```text
Authorization: Bearer <token>
```

Danh sách endpoint và quy trình test đầy đủ nằm trong:

- `docs/API_DOCUMENTATION.md`
- `docs/BACKEND_TESTING_CHECKLIST.md`

## 9. Lỗi thường gặp

### PostgreSQL connection timeout hoặc Prisma `P1001`

PostgreSQL chưa chạy, sai host/port, hoặc `DATABASE_URL` không đúng. Khởi động PostgreSQL và kiểm tra lại cổng `5432`.

### Prisma authentication error hoặc `P1000`

User hoặc mật khẩu PostgreSQL trong `DATABASE_URL` bị sai. Sửa `.env`, sau đó chạy lại lệnh.

### `JWT_SECRET is required`

File `.env` chưa tồn tại hoặc thiếu `JWT_SECRET`. Tạo `.env` từ `.env.example` và điền khóa bí mật.

### `EADDRINUSE: address already in use :::3000`

Cổng `3000` đang được chương trình khác sử dụng. Dừng tiến trình backend cũ hoặc đổi `PORT` trong `.env`.

### `Cannot POST /api/...`

Kiểm tra method, URL và route đã mount. Không gõ thêm chữ `GET` hoặc `POST` vào ô URL của Postman.

### `Invalid auth token`

Đăng nhập lại để lấy token mới và gửi đúng header `Authorization: Bearer <token>`.

### Smoke test bị timeout

Backend chưa chạy hoặc `SMOKE_TEST_URL` sai. Chạy `npm run dev` trước rồi mới chạy `npm run smoke:test` ở terminal khác.

## 10. Integration test

Integration test dùng Vitest và Supertest để gọi trực tiếp Express app. Bộ test này có xóa dữ liệu giữa các test, vì vậy bắt buộc phải dùng database riêng có tên kết thúc bằng `_test`.

Tạo database PostgreSQL riêng:

```sql
CREATE DATABASE sanvacau_test;
```

Tạo file cấu hình cục bộ:

```powershell
Copy-Item .env.test.example .env.test
```

Điền mật khẩu PostgreSQL thật vào `.env.test`, sau đó đồng bộ schema vào database test:

```powershell
$env:DATABASE_URL = (Get-Content .env.test | Where-Object { $_ -match '^DATABASE_URL=' } | ForEach-Object { ($_ -replace '^DATABASE_URL=', '').Trim('"') })
npx prisma db push
Remove-Item Env:DATABASE_URL
```

Chạy test một lần hoặc chạy chế độ theo dõi:

```bash
npm run test:integration
npm run test:watch
```

Các lớp bảo vệ sẽ từ chối chạy nếu thiếu `DATABASE_URL` hoặc tên database không kết thúc bằng `_test`. File `.env.test` chứa mật khẩu thật và đã được Git bỏ qua; chỉ `.env.test.example` được commit.

## 11. Continuous Integration (CI)

Backend sử dụng GitHub Actions workflow (`.github/workflows/backend-ci.yml`) với Node.js 24 và PostgreSQL 17 để tự động kiểm tra code mỗi khi có pull request hoặc push lên nhánh `main`.

- **Mục tiêu**: Tự động chạy `npm ci`, tạo Prisma client, kiểm tra type (`npm run typecheck`), build, và chạy integration test.
- **Tại sao dùng `sanvacau_test`**: Workflow thiết lập một service PostgreSQL container tách biệt hoàn toàn dùng dữ liệu `sanvacau_test` nhằm thoả mãn lớp bảo vệ database, không có bất kì liên kết nào với database development của môi trường thật. Dữ liệu bị xóa đi sau mỗi lần test, đảm bảo tính biệt lập.
- **Lưu ý**: Việc bạn chạy integration test cục bộ và vượt qua toàn bộ test là bắt buộc nhưng không đồng nghĩa với workflow trên GitHub Actions sẽ ngay lập tức thành công do những khác biệt nhỏ trong môi trường máy chủ CI hoặc phiên bản thư viện. Bạn cần kiểm tra kết quả CI trên GitHub sau khi push để xác nhận.
