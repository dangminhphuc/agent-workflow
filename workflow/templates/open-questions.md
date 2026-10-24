# Open questions

<!-- Blocking (agent đề xuất, NGƯỜI duyệt): blocking | review-blocking | non-blocking —
     chọn theo "nếu giả định sai thì phải làm lại gì"; bảng đầy đủ: rules/source-tracing.md.
     Agent không hạ mức để khỏi bị chặn. Lệnh `clarify` dẫn người trả lời từng mục.
     Mã câu hỏi Q-NNN đánh số riêng, không theo số REQ. Câu hỏi phủ REQ nào thì KHÔNG ghi ở đây:
     REQ trỏ tới câu hỏi bằng dòng Source trong spec.md, máy suy ngược (aw pending in danh sách REQ).
     Trả lời: ghi Answer, Status → answered, và đổi source label của mọi REQ trỏ tới câu hỏi
     (vd `[FILE]` [open-questions.md § Q-001](open-questions.md#q-001)) — checker đối chiếu hai chiều.
     Người không đồng ý một REQ đã có nguồn: `/aw-clarify REQ-NNN` ghi một Q-NNN mới, Status answered,
     chỉ Question ("REQ-NNN nên hiểu là X hay Y?") + Answer; câu trả lời cũ chuyển thành `Superseded answer:`. -->

<Nếu không có `open question` nào, ghi đúng dòng dưới đây rồi xoá phần còn lại:>
<No open questions.>

## Contents

<!-- Mục lục — máy sinh bằng `aw toc <thư-mục-feature>`, không viết tay. Mỗi heading ## / ### một link. -->

## Questions

### Q-001 — <câu hỏi ngắn>

- **Source says:** <trích nguyên văn, hoặc "không đề cập">
- **Question:** <câu hỏi cụ thể, trả lời được bằng một câu>
- **Ask:** <BA / PO / tên người>
- **Assumption:** <...>
- **If wrong, redo:** <task/module cụ thể>
- **Blocking:** `<blocking | review-blocking | non-blocking>`   <!-- agent đề xuất, người duyệt -->
- **Status:** `open`   <!-- open | answered -->
- **Answer:** <nguyên văn câu trả lời — ai trả lời, ngày; khi đó sửa luôn source label trong spec.md>
