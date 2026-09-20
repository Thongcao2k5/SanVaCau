# Quy Tắc Git & Quy Trình Làm Việc (Git & Workflow Rules)

Mọi thành viên trong dự án (bao gồm cả AI Agent và Lập trình viên) bắt buộc tuân thủ các quy tắc dưới đây khi làm việc với Git và phiên bản mã nguồn.

---

## 1. Nguyên Tắc An Toàn Cốt Lõi (Critical Safety Rule)
- **TUYỆT ĐỐI KHÔNG TỰ Ý COMMIT HOẶC PUSH CODE** khi chưa có yêu cầu, mệnh lệnh hoặc xác nhận trực tiếp từ người dùng / Tech Lead.
- Khi hoàn thành một tác vụ, Agent chỉ trình bày kết quả đã thay đổi và hỏi ý kiến trước khi thực hiện commit.
- Tuyệt đối không sử dụng lệnh `git push --force` lên các nhánh chính (`main`, `master`, `develop`).
- Không commit các thông tin nhạy cảm: file `.env`, mật khẩu, database connection string, API keys, private keys, thư mục `node_modules/`, `.dart_tool/`, `build/`, `dist/`.

---

## 2. Quy Chuẩn Đặt Tên Commit (Conventional Commits)
Thông điệp commit bắt buộc viết theo định dạng chuẩn:

```text
<type>(<scope>): <mô tả ngắn gọn>
```

### Các Type quy định:
| Type | Mục đích | Ví dụ |
| :--- | :--- | :--- |
| **`feat`** | Thêm một tính năng mới | `feat(booking): add court slot selection api` |
| **`fix`** | Sửa một lỗi / bug | `fix(auth): fix token expiration issue` |
| **`refactor`** | Tái cấu trúc code (không đổi tính năng bên ngoài) | `refactor(court): split court controller into service layer` |
| **`style`** | Chỉnh sửa UI, format code, khoảng trắng, dấu chấm phẩy | `style(home): update badminton court card padding` |
| **`docs`** | Thêm hoặc cập nhật tài liệu (README, API docs, rules) | `docs(api): add swagger documentation for booking routes` |
| **`chore`** | Các công việc phụ: cập nhật thư viện, config, build tool | `chore(deps): bump express to 5.2.1` |
| **`test`** | Thêm hoặc sửa đổi unit test, integration test | `test(booking): add test cases for overlapping booking slots` |

### Quy cách viết mô tả (Description):
- Sử dụng chữ thường ở đầu mô tả (trừ danh từ riêng).
- Không để dấu chấm `.` ở cuối dòng commit.
- Mô tả rõ ràng hành động thực hiện.

---

## 3. Quy Chuẩn Đặt Tên Nhánh (Branching Strategy)
- Nhánh tính năng mới: `feature/<tên-tính-năng>` (VD: `feature/court-search`, `feature/payment-vnpay`)
- Nhánh sửa lỗi: `bugfix/<tên-lỗi>` (VD: `bugfix/calendar-timezone`)
- Nhánh sửa gấp: `hotfix/<tên-lỗi>` (VD: `hotfix/crash-on-launch`)
- Tên nhánh dùng chữ thường và phân tách bằng dấu gạch ngang (`kebab-case`).
