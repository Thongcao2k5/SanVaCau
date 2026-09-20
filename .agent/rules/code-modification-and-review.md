# Quy Tắc Sửa Code & Kiểm Thử (Code Modification & Review Rules)

Quy chuẩn này nhằm đảm bảo mọi can thiệp vào mã nguồn đều an toàn, chính xác và không gây hiệu ứng phụ (side effects) không mong muốn.

---

## 1. Tối Thiểu Hóa Phạm Vi Ảnh Hưởng (Minimal Blast Radius)
- **Chỉ sửa đúng phạm vi yêu cầu:** Không tự ý sửa đổi, format lại (reformat style) hoặc đổi cấu trúc các file không liên quan trực tiếp đến tác vụ được giao.
- Không tự tiện xoá bỏ code cũ hoặc refactor code của người khác nếu chưa thảo luận và có sự đồng ý.
- Nếu phát hiện code cũ có lỗi hoặc tiềm ẩn rủi ro nằm ngoài phạm vi tác vụ, hãy ghi chú và báo cáo lại thay vì âm thầm tự sửa.

---

## 2. Bảo Toàn Tài Liệu & Chú Thích (Documentation Integrity)
- **Bắt buộc giữ nguyên** các comment, docstring, chú thích bản quyền và giải thích thuật toán đã có trong code, trừ khi đoạn code đó bị xoá hoặc logic đã thay đổi hoàn toàn.
- Khi viết hàm mới có logic nghiệp vụ phức tạp (ví dụ: thuật toán ghép cặp đấu, logic tính tiền giờ cao điểm), bắt buộc phải có comment giải thích rõ ràng đầu vào, đầu ra và mục đích.

---

## 3. Quy Trình Kiểm Thử Bắt Buộc Trước Khi Báo Hoàn Thành (Verification)
Mọi thay đổi code bắt buộc phải vượt qua bước kiểm tra tĩnh (Static Analysis & Typecheck) trước khi thông báo hoàn tất cho người dùng:

### Đối với Backend:
```bash
cd backend
npm run typecheck    # hoặc tsc --noEmit: Đảm bảo 0 lỗi TypeScript
npm run build        # Đảm bảo quá trình biên dịch không có lỗi
```

### Đối với Frontend:
```bash
cd frontend/san_va_cau_app
flutter analyze      # Đảm bảo không có warning hoặc lint error nghiêm trọng
```

---

## 4. Quy Chuẩn Báo Cáo Thay Đổi
Khi báo cáo kết quả hoàn thành tác vụ cho team/lead:
1. Tóm tắt ngắn gọn các file đã thay đổi (kèm đường dẫn link file).
2. Nêu rõ nguyên nhân hoặc quyết định kỹ thuật quan trọng nếu có.
3. Kết quả chạy kiểm thử (Verification: passed).
