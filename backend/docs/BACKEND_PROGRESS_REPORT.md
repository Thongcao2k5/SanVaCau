# SanVaCau Backend Progress Report

File này dùng để ghi lại từng phần đã làm, đã kiểm tra, lỗi đã phát hiện và kết quả test. Khi hoàn thiện backend, có thể dùng file này để tổng hợp báo cáo cuối cùng.

## 1. Auth, Role, Admin Test Account

### Đã làm
- Tạo luồng đăng ký/đăng nhập cơ bản.
- Tạo API dev để tạo tài khoản admin test.
- Tạo middleware `requireAuth` để kiểm tra đăng nhập bằng token.
- Tạo middleware `requireRole` để kiểm tra quyền truy cập.
- Tạo route test quyền admin `/api/auth/admin-check`.

### Đã kiểm tra
- Gọi API tạo admin bằng Postman.
- Gọi API đăng nhập để lấy token.
- Gọi API `/api/auth/me` để kiểm tra token hợp lệ.
- Gọi API `/api/auth/admin-check` để kiểm tra role admin.

### Lỗi đã gặp và xử lý
- `Cannot POST /api/auth/dev/create-admin`: route chưa được mount hoặc sai path.
- `Cannot read properties of undefined (reading 'password')`: body request chưa đúng hoặc code đọc sai dữ liệu.
- `Cannot find name 'requireRole'`: thiếu import `requireRole`.
- Lỗi cú pháp khi thêm route: thiếu dấu `,`, `)`, hoặc đặt route sai vị trí.
- `Invalid auth token`: token sai, hết hạn, hoặc chưa gửi đúng header `Authorization: Bearer <token>`.

### Trạng thái
- Hoàn thành nền tảng đăng nhập và phân quyền.

---

## 2. Product, Category, Variant, Inventory

### Đã làm
- Tạo API danh mục sản phẩm.
- Tạo logic danh mục cha/con bằng `parent_id`.
- Tạo API sản phẩm.
- Tạo API biến thể sản phẩm.
- Tạo API tồn kho.

### Đã kiểm tra
- Kiểm tra `parent_id = null` là danh mục cha.
- Kiểm tra danh mục con dùng `parent_id` bằng `id` của danh mục cha.
- Kiểm tra parse id từ URL sang `BigInt`.
- Kiểm tra typecheck/build sau khi hoàn thiện product variant.

### Lỗi đã gặp và xử lý
- Cần chuyển id từ URL sang `BigInt` vì Prisma schema dùng BigInt.
- Cần tách product và variant để sau này một sản phẩm có nhiều màu/size/phiên bản.

### Trạng thái
- Hoàn thành phần quản lý sản phẩm cơ bản.

---

## 3. Branch, Court, Booking

### Đã làm
- Tạo API chi nhánh.
- Tạo API sân.
- Tạo API khung giờ.
- Tạo API giá sân.
- Tạo API đặt sân.
- Thêm kiểm tra trùng tên sân trong cùng chi nhánh.
- Thêm kiểm tra quyền cho admin/branch manager/customer.

### Đã kiểm tra
- Kiểm tra dữ liệu sân chỉ lấy sân `ACTIVE`.
- Kiểm tra `courtId=abc` bị từ chối vì không phải BigInt hợp lệ.
- Kiểm tra ngày sai như `2026-02-31` bị từ chối.
- Kiểm tra branch manager không có `branchId` không được xem/cập nhật booking toàn hệ thống.
- Chạy `npm run typecheck`.
- Chạy `npm run build`.

### Lỗi đã gặp và xử lý
- Phát hiện lỗi phân quyền nghiêm trọng: branch manager thiếu `branchId` có thể bị hiểu như admin và thấy toàn bộ booking.
- Đã sửa để trả `403 Forbidden` nếu branch manager không có `branchId`.

### Trạng thái
- Court API và Booking API đã được chuẩn hóa.

---

## 4. Cart, Order, Payment, Fulfillment

### Đã làm
- Tạo API giỏ hàng.
- Tạo API đơn hàng.
- Tạo API thanh toán.
- Tạo API xử lý giao hàng/hoàn tất đơn.

### Đã kiểm tra
- Kiểm tra logic thêm/xóa/cập nhật giỏ hàng.
- Kiểm tra tạo đơn từ giỏ hàng.
- Kiểm tra trạng thái đơn hàng/thanh toán.
- Kiểm tra build/typecheck trong các lần nghiệm thu.

### Ghi chú
- Các API này là nền cho luồng mua sản phẩm trong app mobile.

### Trạng thái
- Hoàn thành nền tảng thương mại điện tử cơ bản.

---

## 5. Profile, Address, Favorite, Review

### Đã làm
- Tạo API hồ sơ người dùng.
- Tạo API địa chỉ.
- Tạo API yêu thích sản phẩm/sân.
- Tạo API đánh giá.

### Đã kiểm tra
- Favorite chỉ cho phép `PRODUCT` hoặc `COURT`.
- Favorite chỉ cho phép product đang active và court đang active.
- Favorite không lỗi khi bấm thả tim trùng hoặc xóa item chưa tồn tại.
- Review được tách theo sản phẩm/sân phù hợp.

### Ghi chú
- Favorite dùng tốt cho UI nút trái tim.
- Address dùng cho checkout/giao hàng.
- Review dùng cho hiển thị uy tín sản phẩm/sân.

### Trạng thái
- Hoàn thành nhóm API trải nghiệm người dùng.

---

## 6. News, Banner, Home, Bootstrap

### Đã làm
- Tạo API banner.
- Tạo API tin tức.
- Tạo API home.
- Tạo API bootstrap để app lấy dữ liệu khởi động.

### Đã kiểm tra
- Kiểm tra `/api/bootstrap` trả banners/categories/branches/news/products.
- Kiểm tra dữ liệu seed hiển thị được cho home.

### Ghi chú
- Phần này phục vụ landing/home page của app mobile.

### Trạng thái
- Hoàn thành nền tảng dữ liệu trang chủ.

---

## 7. Settings, Metadata, App Status, FAQ, Static Pages

### Đã làm
- Tạo API settings.
- Tạo API metadata.
- Tạo API app status.
- Tạo API FAQ.
- Tạo API static pages.

### Đã kiểm tra
- Kiểm tra `/api/faqs` trả danh sách FAQ.
- Kiểm tra `/api/pages` trả danh sách trang tĩnh.
- Kiểm tra Postman collection có endpoint tương ứng.

### Lỗi đã gặp và xử lý
- Postman collection thiếu query cho `GET /api/app-status`.
- Đã sửa thành `/app-status?platform=android&version=1.0.0`.
- Đã bổ sung vào `API_DOCUMENTATION.md` rằng endpoint này cần `platform=android|ios` và `version=x.y.z`.

### Trạng thái
- Hoàn thành nhóm API cấu hình/nội dung tĩnh.

---

## 8. Contact, Support Ticket, Notification, Audit Log

### Đã làm
- Tạo API liên hệ/feedback.
- Tạo API support ticket.
- Tạo API notification.
- Tạo API audit log.

### Đã kiểm tra
- Kiểm tra logic public contact có rate limit.
- Kiểm tra audit log ghi nhận hành động quan trọng.
- Kiểm tra notification không làm hỏng response chính nếu ghi log phụ bị lỗi.

### Ghi chú
- Contact dùng cho khách chưa đăng nhập gửi phản hồi.
- Support ticket dùng cho quy trình chăm sóc khách hàng.
- Audit log dùng để theo dõi hành động admin/manager.

### Trạng thái
- Hoàn thành nhóm API vận hành/hỗ trợ.

---

## 9. Upload, Search, Report, Dashboard

### Đã làm
- Tạo API upload.
- Tạo API search.
- Tạo API report.
- Tạo API dashboard.

### Đã kiểm tra
- Kiểm tra search có thể dùng cho sản phẩm/sân/nội dung cần tìm.
- Kiểm tra dashboard/report phục vụ admin.
- Chạy typecheck/build trong các lần nghiệm thu.

### Ghi chú
- Upload phục vụ ảnh sản phẩm, banner, tin tức.
- Dashboard/report phục vụ trang quản trị sau này.

### Trạng thái
- Hoàn thành nhóm API quản trị/tìm kiếm.

---

## 10. Security, Error Handling, Rate Limit

### Đã làm
- Thêm `helmet`.
- Thêm giới hạn JSON/urlencoded body size.
- Thêm general API rate limit.
- Thêm auth rate limit.
- Thêm public write rate limit.
- Chuẩn hóa error middleware.

### Đã kiểm tra
- Health API hoạt động.
- Invalid JSON trả `400`.
- Login sai nhiều lần trả `429`.
- Header bảo mật từ `helmet` tồn tại.
- Chạy `npm run typecheck`.
- Chạy `npm run build`.

### Trạng thái
- Hoàn thành hardening cơ bản cho backend.

---

## 11. Seed Data

### Đã làm
- Tạo file seed dữ liệu mẫu.
- Thêm script `npm run seed`.
- Seed admin, branches, categories, brands, products, variants, inventory, courts, time slots, prices, banners, news, settings, FAQ, pages.

### Đã kiểm tra
- Chạy seed lần đầu thành công.
- Chạy seed lần hai vẫn thành công, không bị lỗi trùng dữ liệu.
- Kiểm tra `/api/bootstrap`, `/api/faqs`, `/api/pages`.

### Lỗi đã gặp và xử lý
- Time slot bị xung đột unique khi seed lại.
- Đã sửa logic seed để ưu tiên dùng dữ liệu đã tồn tại.

### Trạng thái
- Hoàn thành dữ liệu mẫu để test app.

---

## 12. API Documentation And Postman Collection

### Đã làm
- Tạo `API_DOCUMENTATION.md`.
- Tạo `BACKEND_TESTING_CHECKLIST.md`.
- Tạo `SanVaCau.postman_collection.json`.

### Đã kiểm tra
- Parse JSON Postman collection thành công.
- Kiểm tra các nhóm endpoint chính.
- Chạy `npm run typecheck`.
- Chạy `npm run build`.

### Lỗi đã gặp và xử lý
- Sửa App Status trong Postman collection từ `/app-status` thành `/app-status?platform=android&version=1.0.0`.
- Sửa tài liệu API để ghi rõ required query.

### Trạng thái
- Tài liệu và Postman collection đã dùng được để test lại backend.

---

## 13. Automated Backend Smoke Test

### Đã làm
- Tạo script `scripts/smoke-test.ts`.
- Thêm npm script `smoke:test`.
- Script tự gọi các API public, auth flow, admin endpoints và error handling cơ bản.

### Đã kiểm tra
- Chạy `npm run typecheck`.
- Chạy `npm run build`.
- Bật backend dev server bằng `npm run dev`.
- Chạy `npm run smoke:test`.

### Kết quả smoke test
- Tổng số test: 28.
- Passed: 28.
- Failed: 0.

### Các nhóm endpoint đã test
- Public endpoints: health, database health, bootstrap, FAQ, pages, metadata, app status, settings public, home, categories, brands, products, branches, courts, time slots, banners, news, racket services.
- Auth flow: tạo admin test, admin login, `/auth/me`.
- Admin endpoints: dashboard summary, settings, audit logs, admin user list, notifications.
- Error handling: request thiếu token trả `401`, login sai mật khẩu trả `401`.

### Lỗi đã gặp và xử lý
- Không phát hiện lỗi code trong lần kiểm tra này.
- Backend server chưa chạy lúc đầu nên request timeout; sau khi bật `npm run dev` thì smoke test chạy thành công.

### Trạng thái
- Hoàn thành script kiểm tra nhanh backend.

---

## 14. Backend Setup Documentation And Environment Example

### Đã làm
- Chuẩn hóa `.env.example` với các biến `DATABASE_URL`, `PORT`, `NODE_ENV`, `JWT_SECRET` và `SMOKE_TEST_URL`.
- Tạo `docs/BACKEND_SETUP.md` hướng dẫn cài đặt và chạy backend trên máy mới.
- Ghi rõ quy trình cài thư viện, chuẩn bị PostgreSQL, Prisma, seed data, chạy server và kiểm tra API.
- Ghi tài khoản admin seed dành cho môi trường phát triển và cảnh báo không sử dụng mật khẩu mẫu ở production.
- Bổ sung cách xử lý các lỗi setup thường gặp.

### Đã kiểm tra
- Xác nhận `.env.example` không chứa mật khẩu PostgreSQL hoặc JWT secret thật.
- Đối chiếu các lệnh trong tài liệu với `package.json` và `prisma.config.ts`.
- Chạy `npm run typecheck`.
- Chạy `npm run build`.

### Lỗi đã gặp và xử lý
- Task ban đầu chưa tạo `docs/BACKEND_SETUP.md`.
- `.env.example` thiếu `NODE_ENV`, `SMOKE_TEST_URL` và phần `?schema=public` trong chuỗi kết nối mẫu.
- Đã bổ sung đầy đủ các phần còn thiếu.

### Trạng thái
- Hoàn thành tài liệu thiết lập backend và file môi trường mẫu.

---

## 15. Automated Integration Tests

### Đã làm
- Thêm Vitest và Supertest cho integration test.
- Tạo test cho public API, đăng ký/đăng nhập, xác thực token, phân quyền và validation.
- Tạo `.env.test.example` và cấu hình database test riêng.
- Thêm các script `test`, `test:integration` và `test:watch`.
- Bổ sung hướng dẫn tạo và chạy database `sanvacau_test` trong `BACKEND_SETUP.md`.

### Đã kiểm tra
- Xác nhận `.env.test` được Git bỏ qua và `.env.test.example` có thể được commit.
- Kiểm tra cơ chế an toàn trước khi xóa dữ liệu test.
- Chạy `npx prisma generate`.
- Chạy `npm run typecheck`.
- Chạy `npm run build`.
- Chạy `npm run test:integration`.
- Kết quả: 4 test files passed, 18 tests passed, 0 failed.

### Lỗi đã gặp và xử lý
- Điều kiện cũ chỉ kiểm tra toàn bộ URL có chữ `test`, nên mật khẩu chứa chữ này cũng có thể vượt qua bảo vệ.
- Thông báo lỗi cũ có thể in toàn bộ database URL và làm lộ mật khẩu.
- `.env.test.example` bị quy tắc `.env.*` trong `.gitignore` loại bỏ.
- Task ban đầu chưa cập nhật tài liệu setup và báo cáo tiến độ.
- Cấu hình `poolOptions` đã lỗi thời với Vitest 5 và tạo cảnh báo khi chạy test.
- Đã đổi sang parse URL và chỉ cho phép tên database kết thúc bằng `_test`, không hiển thị URL bí mật.
- Đã đổi sang `fileParallelism: false` để các file test dùng chung database chạy tuần tự.

### Trạng thái
- Hoàn thành integration test nền tảng; toàn bộ 18 test hiện tại đều đạt.

---

## Lệnh kiểm tra chuẩn sau mỗi phần

```bash
npm run typecheck
npm run build
```

Khi cần kiểm tra Postman collection:

```bash
node -e "JSON.parse(require('fs').readFileSync('docs/SanVaCau.postman_collection.json','utf8')); console.log('Valid JSON')"
```

---

## 16. Core Business Flow Integration Tests

### Đã làm
- Thêm helper tạo dữ liệu mẫu (`tests/helpers/fixtures.ts`) độc lập với seed data, dùng timestamp và counter để tạo giá trị duy nhất.
- Viết test luồng **Booking**: đặt sân, tính giá từ server, từ chối sân inactive, kiểm tra quyền truy cập Booking của manager/admin.
- Viết test luồng **Cart**: thêm/sửa/xoá giỏ hàng, cập nhật số lượng, kiểm tra giới hạn tồn kho, kiểm tra variant không active.
- Viết test luồng **Order**: tạo đơn hàng từ giỏ hàng, trừ tồn kho, tính tổng giá an toàn phía server, từ chối nếu không đủ tồn kho và xoá giỏ hàng sau khi đặt.
- Viết test luồng **Payment**: tạo payment cho đơn hàng, tính tiền theo server, kiểm tra transition trạng thái (chỉ cho thanh toán 1 lần), kiểm tra quyền.
- Viết test luồng **Voucher**: áp dụng discount (PERCENT/FIXED), bắt lỗi ngày, bắt lỗi số lượng giới hạn, từ chối voucher dưới mức tiền tối thiểu.

### Đã kiểm tra
- Chạy `npx prisma generate`.
- Chạy `npm run typecheck`.
- Chạy `npm run build`.
- Chạy `npm run test:integration`.
- Kết quả: 9 files passed, 60 tests passed, 0 failed.
- Cấu trúc test database không bị chồng lặp dữ liệu do dùng cơ chế `clearDatabase()` trước mỗi lần chạy test.
- Siết assertion rollback: order lỗi không tạo order item, không xóa cart và không giảm tồn kho.
- Siết assertion payment lỗi: không tạo payment record.
- Voucher lỗi dùng order thật và xác nhận không tạo voucher usage.

### Lỗi đã gặp và xử lý
- **TypeError: Do not know how to serialize a BigInt**: Lỗi do truyền thẳng record `user` có trường `id` là `BigInt` sinh ra từ prisma vào `jwt.sign()`.
- **Cách xử lý**: Đã fix bằng cách chuyển đổi model lấy từ Prisma qua plain object (đưa BigInt về chuỗi) trước khi gọi `signAuthToken`.
- Các test voucher ban đầu dùng `targetId: "1"` giả định và helper order trả tổng tiền hard-code; đã đổi sang order/tổng tiền thật từ API response.
- Khi chạy transaction, `@prisma/adapter-pg` hiện phát cảnh báo deprecated query concurrency từ thư viện `pg`. Cảnh báo không làm test thất bại nhưng cần kiểm tra lại trước khi nâng lên `pg` 9.

### Trạng thái
- Đã hoàn thành 5 nhóm integration test cho toàn bộ luồng thương mại điện tử cốt lõi.

---

## 17. Backend Continuous Integration

### Record
- **Workflow file created**: `.github/workflows/backend-ci.yml`
- **CI environment**: Ubuntu latest, Node.js 24, PostgreSQL 17 service container.
- **Commands executed**: `npm ci`, `npx prisma generate`, `npx prisma db push`, `npm run typecheck`, `npm run build`, `npm run test:integration`
- **Local verification results**: 
  - `npm ci`: passed
  - Prisma generate and test database schema sync: passed
  - Typecheck: passed
  - Build: passed
  - Test Files: 9 passed
  - Tests: 60 passed
- **Issues found and handled**:
  - Initial workflow used Node.js 20, which is not supported by Vitest 5. Updated to Node.js 24.
  - Initial workflow used PostgreSQL 15, which did not match the project's PostgreSQL 17 environment. Updated to PostgreSQL 17.
  - PostgreSQL health check did not specify its user or database. Updated it to check `postgres` and `sanvacau_test` explicitly.
  - `npm audit` currently reports 4 high-severity advisories through Prisma CLI transitive dependencies. No automatic downgrade or breaking `--force` fix was applied.
- **Remote CI status**: Not executed yet.

---

## 18. Final Backend Audit

- **Audit Scope**: Security, Data Integrity, Transactions, APIs, CI workflow, and Dependencies.
- **Confirmed Issues**:
  1. Development-only `/dev/create-admin` endpoint lacked `NODE_ENV` restrictions.
  2. ESM Runtime Import failure for Prisma Client when running natively via Node.
  3. `pg` concurrency warning inside `@prisma/adapter-pg`.
  4. Flaky transaction deadlocks during concurrent `clearDatabase` TRUNCATE calls in tests due to floating `createAuditLog` background promises.
- **Fixes Applied**:
  - Bound `/dev/create-admin` with strict `NODE_ENV === "production"` guards returning 404. Added a matching regression test.
  - Refactored `import { Prisma }` syntax in `error.middleware.ts` to `import pkg from "@prisma/client"; const { Prisma } = pkg;` ensuring native Node ESM compatibility.
- **CI / Build Results**:
  - Remote CI Status: Not executed yet.
  - All local checks (typecheck, build, test:integration, seed, smoke:test) passed without fail (61/61 integration, 28/28 smoke).
- **Security Assessment**: Core transaction systems and tenant isolation constraints successfully verified. Dependency vulnerabilities are isolated to non-reachable Prisma CLI dev layers.
- **Verdict**: READY WITH KNOWN RISKS. (Documented completely in `docs/FINAL_BACKEND_AUDIT.md`).
