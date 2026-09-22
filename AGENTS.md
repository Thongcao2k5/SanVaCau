# AI Agent Guidelines - Dự Án Sân&Cầu

Chào mừng AI Agent và các cộng sự! Tài liệu này là chỉ dẫn bắt buộc cho mọi Agent khi tham gia phát triển dự án Sân&Cầu.

---

## ⚠️ CÁC QUY TẮC BẮT BUỘC TUÂN THỦ (CRITICAL RULES)

1. **TUYỆT ĐỐI KHÔNG TỰ Ý COMMIT HOẶC PUSH CODE:**
   - Không chạy `git commit`, `git push` nếu chưa nhận được lệnh hoặc xác nhận trực tiếp từ developer.
   - Khi hoàn thành tác vụ, chỉ trình bày thay đổi và chờ xác nhận.

2. **KIỂM THỬ XÁC MINH TRƯỚC KHI BÁO HOÀN THÀNH:**
   - Backend: Luôn chạy `npm run typecheck` hoặc `npm run build` trong `backend/` để đảm bảo 0 lỗi.
   - Frontend: Luôn chạy `flutter analyze` trong `frontend/san_va_cau_app/`.

3. **TỐI THIỂU PHẠM VI ẢNH HƯỞNG & BẢO TOÀN TÀI LIỆU:**
   - Chỉ sửa đúng file và chức năng được giao.
   - Giữ nguyên các comment, docstrings hiện hữu.

---

## 📚 HỆ THỐNG QUY CHUẨN CHI TIẾT THEO TỪNG VẤN ĐỀ

Chi tiết từng quy chuẩn chuyên biệt được lưu trữ trong thư mục [`.agent/rules/`](file:///Users/tyson/Library/CloudStorage/GoogleDrive-philip@mtglobal.tech/Drive%20c%E1%BB%A7a%20t%C3%B4i/SanVaCau/.agent/rules):

1. **[Git & Quy trình làm việc](file:///Users/tyson/Library/CloudStorage/GoogleDrive-philip@mtglobal.tech/Drive%20c%E1%BB%A7a%20t%C3%B4i/SanVaCau/.agent/rules/git-and-workflow.md)**: Chuẩn Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`), quy tắc đặt tên nhánh `feature/`, `bugfix/`.
2. **[Sửa Code & Review](file:///Users/tyson/Library/CloudStorage/GoogleDrive-philip@mtglobal.tech/Drive%20c%E1%BB%A7a%20t%C3%B4i/SanVaCau/.agent/rules/code-modification-and-review.md)**: Quy chuẩn an toàn khi sửa code, bảo toàn documentation, checklist kiểm thử tĩnh.
3. **[Kiến trúc & Thiết kế](file:///Users/tyson/Library/CloudStorage/GoogleDrive-philip@mtglobal.tech/Drive%20c%E1%BB%A7a%20t%C3%B4i/SanVaCau/.agent/rules/architecture-and-design.md)**: Mô hình phân tầng Backend (Router -> Controller -> Service -> Prisma), cấu trúc Feature-First của Flutter, định dạng chuẩn RESTful response.
4. **[Tiêu chuẩn Lập trình](file:///Users/tyson/Library/CloudStorage/GoogleDrive-philip@mtglobal.tech/Drive%20c%E1%BB%A7a%20t%C3%B4i/SanVaCau/.agent/rules/coding-standards.md)**: Tiêu chuẩn TypeScript (no `any`, async/await), tiêu chuẩn Flutter/Dart (`const` widget, null-safety).
5. **[Hệ Thống Thiết Kế UI/UX](file:///Users/tyson/Library/CloudStorage/GoogleDrive-philip@mtglobal.tech/Drive%20c%E1%BB%A7a%20t%C3%B4i/SanVaCau/.agent/rules/ui-ux-design-system.md)**: Design Tokens dùng chung cho WebApp và Mobile App (Bảng màu Đỏ Yonex #DC2626, Typography, Spacing, Thẻ sản phẩm, Ma trận đặt sân, Quy chuẩn thanh thanh toán ghim đáy `margin-top: auto`).
