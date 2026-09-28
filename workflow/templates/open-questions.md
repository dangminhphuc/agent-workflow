# Điểm mù cần làm rõ

> Sinh bởi phase `01-spec`. File này phải tồn tại kể cả khi rỗng.
> Rỗng = đã rà và không thấy gì. Thiếu file = chưa rà. Hai việc khác nhau.

<Nếu không có điểm mù nào, ghi đúng dòng dưới đây rồi xoá phần còn lại:>
<Không có điểm mù.>

## YC-002 — <tiêu đề trùng với mục trong spec.md>

- **Tài liệu nói gì:** <trích nguyên văn, hoặc "không đề cập">
- **Chỗ chưa rõ:** <câu hỏi cụ thể, trả lời được bằng một câu>
- **Hỏi ai:** <BA / PO / tên người>
- **Giả định tạm đang dùng:** <...>
- **Nếu giả định sai thì phải làm lại gì:** <task/module cụ thể>
- **Mức ảnh hưởng:** `<toàn bộ thiết kế | cục bộ>`   <!-- agent đề xuất, người duyệt -->
- **Trạng thái:** `mở`   <!-- mở | đã trả lời -->
- **Trả lời:** <người trả lời ghi vào đây; khi đó sửa luôn nhãn nguồn trong spec.md>

> "Nếu giả định sai" và "Mức ảnh hưởng" cho người đọc quyết định được: chặn lại
> hỏi ngay, hay cứ cho chạy tiếp rồi sửa sau. Mục `toàn bộ thiết kế` còn `mở`
> thì `/design` chặn; mục `cục bộ` thì không.
>
> Checker đối chiếu hai chiều với `spec.md`: mỗi mục phải trỏ về một YC có thật;
> `mở` ↔ spec gắn `[CẦN-HỎI]`; `đã trả lời` ↔ có dòng "Trả lời" và spec đã đổi
> nhãn nguồn (vd `[FILE]` open-questions.md § YC-002).
