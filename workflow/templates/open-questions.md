# Điểm mù cần làm rõ

> Sinh bởi phase `01-spec`. File này phải tồn tại kể cả khi rỗng.
> Rỗng = đã rà và không thấy gì. Thiếu file = chưa rà. Hai việc khác nhau.

<!-- Mức chặn — agent đề xuất, NGƯỜI duyệt ở gate spec. Chỉ ba mức:

     | Mức           | Khi nào                                  | Chặn gì                                              |
     |---------------|------------------------------------------|------------------------------------------------------|
     | `chặn`        | Sai giả định thì cả thiết kế đổi hướng   | Phase ngay sau spec: /design (chore: /plan) và mọi phase sau |
     | `chặn review` | Sai thì làm lại một phần code            | Flow đi tiếp trên giả định tạm; /review chặn         |
     | `không chặn`  | Sai thì sửa nhỏ, chấp nhận giao trước    | Không chặn; review ghi YC đó "chờ xác nhận"          |

     "Nếu giả định sai" là căn cứ để chọn mức. Agent không được hạ mức để khỏi bị chặn.

     Lệnh `clarify` liệt kê các mục còn mở theo thứ tự phải giải quyết trước
     (aw pending) và dẫn người trả lời từng mục.

     Checker đối chiếu hai chiều với `spec.md`: mỗi mục phải trỏ về một YC có thật;
     `mở` ↔ spec gắn `[CẦN-HỎI]`; `đã trả lời` ↔ có dòng "Trả lời" và spec đã đổi
     nhãn nguồn (vd `[FILE]` open-questions.md § YC-002). -->

<Nếu không có điểm mù nào, ghi đúng dòng dưới đây rồi xoá phần còn lại:>
<Không có điểm mù.>

## YC-002 — <tiêu đề trùng với mục trong spec.md>

- **Tài liệu nói gì:** <trích nguyên văn, hoặc "không đề cập">
- **Chỗ chưa rõ:** <câu hỏi cụ thể, trả lời được bằng một câu>
- **Hỏi ai:** <BA / PO / tên người>
- **Giả định tạm đang dùng:** <...>
- **Nếu giả định sai thì phải làm lại gì:** <task/module cụ thể>
- **Mức chặn:** `<chặn | chặn review | không chặn>`   <!-- agent đề xuất, người duyệt -->
- **Trạng thái:** `mở`   <!-- mở | đã trả lời -->
- **Trả lời:** <nguyên văn câu trả lời — ai trả lời, ngày; khi đó sửa luôn nhãn nguồn trong spec.md>
