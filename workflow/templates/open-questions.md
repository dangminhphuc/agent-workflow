# Open questions

> Sinh bởi phase `01-spec`. File này phải tồn tại kể cả khi rỗng.
> Rỗng = đã rà và không thấy gì. Thiếu file = chưa rà. Hai việc khác nhau.

<!-- Blocking — agent đề xuất, NGƯỜI duyệt ở gate spec. Chỉ ba mức:

     | Mức               | Khi nào                                  | Chặn gì                                              |
     |-------------------|------------------------------------------|------------------------------------------------------|
     | `blocking`        | Sai giả định thì cả thiết kế đổi hướng   | Phase ngay sau spec: /aw-design (chore: /aw-plan) và mọi phase sau |
     | `review-blocking` | Sai thì làm lại một phần code            | Flow đi tiếp trên giả định tạm; /aw-review chặn         |
     | `non-blocking`    | Sai thì sửa nhỏ, chấp nhận giao trước    | Không chặn; review ghi YC đó `pending`               |

     "Nếu giả định sai" là căn cứ để chọn mức. Agent không được hạ mức để khỏi bị chặn.

     Lệnh `clarify` liệt kê các mục còn mở theo thứ tự phải giải quyết trước
     (aw pending) và dẫn người trả lời từng mục.

     Checker đối chiếu hai chiều với `spec.md`: mỗi mục phải trỏ về một YC có thật;
     `open` ↔ spec gắn `[OPEN-QUESTION]`; `answered` ↔ có dòng "Answer" và spec đã đổi
     nhãn nguồn (vd `[FILE]` open-questions.md § YC-002). -->

<Nếu không có điểm mù nào, ghi đúng dòng dưới đây rồi xoá phần còn lại:>
<No open questions.>

## YC-002 — <tiêu đề trùng với mục trong spec.md>

- **Source says:** <trích nguyên văn, hoặc "không đề cập">
- **Question:** <câu hỏi cụ thể, trả lời được bằng một câu>
- **Ask:** <BA / PO / tên người>
- **Assumption:** <...>
- **If wrong, redo:** <task/module cụ thể>
- **Blocking:** `<blocking | review-blocking | non-blocking>`   <!-- agent đề xuất, người duyệt -->
- **Status:** `open`   <!-- open | answered -->
- **Answer:** <nguyên văn câu trả lời — ai trả lời, ngày; khi đó sửa luôn nhãn nguồn trong spec.md>
