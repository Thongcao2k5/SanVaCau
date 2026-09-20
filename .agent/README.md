# Quy Chuẩn & Hướng Dẫn Phát Triển Dự Án Sân&Cầu (.agent)

Thư mục này lưu trữ các bộ quy chuẩn và chỉ dẫn cho cả **Thành viên trong nhóm (Team Members)** và **AI Coding Agents** (Antigravity, Cursor, Claude Code...) khi tham gia phát triển dự án Sân&Cầu.

---

## Danh Mục Quy Chuẩn Trong `rules/`

| Tệp Quy Chuẩn | Mô Tả Tóm Tắt |
| :--- | :--- |
| **[git-and-workflow.md](./rules/git-and-workflow.md)** | **QUAN TRỌNG:** Tuyệt đối không tự ý commit khi chưa có lệnh. Chuẩn commit Conventional Commits, quy tắc đặt tên nhánh an toàn. |
| **[code-modification-and-review.md](./rules/code-modification-and-review.md)** | Giới hạn phạm vi sửa code, bảo toàn docstring/comment, quy trình bắt buộc chạy `typecheck` / `flutter analyze` trước khi báo xong. |
| **[architecture-and-design.md](./rules/architecture-and-design.md)** | Kiến trúc phân tầng Backend (Router -> Controller -> Service -> Prisma), cấu trúc Feature-First cho Flutter, chuẩn RESTful JSON response. |
| **[coding-standards.md](./rules/coding-standards.md)** | Tiêu chuẩn TypeScript (no `any`, async/await), tiêu chuẩn Flutter/Dart (`const` widget, null-safety, naming conventions). |
| **[ui-ux-design-system.md](./rules/ui-ux-design-system.md)** | Hệ thống Design Tokens dùng chung cho WebApp và Mobile App (Màu sắc, Typography, Spacing, Radius, Component Cards/Chips/Buttons). |

---

> **Lưu ý dành cho AI Agent:** Bắt buộc đọc và tuân thủ tuyệt đối các file quy chuẩn trên trước khi thực hiện bất kỳ thao tác chỉnh sửa mã nguồn hoặc câu lệnh terminal nào.
