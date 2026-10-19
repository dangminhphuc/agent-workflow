# Open questions

<!-- Blocking (agent đề xuất, NGƯỜI duyệt): blocking | review-blocking | non-blocking —
     chọn theo "nếu giả định sai thì phải làm lại gì"; bảng đầy đủ: rules/source-tracing.md.
     Agent không hạ mức để khỏi bị chặn. Lệnh `clarify` dẫn người trả lời từng mục.
     Trả lời: ghi Answer, Status → answered, và đổi source label của REQ trong spec.md
     (vd `[FILE]` [open-questions.md § REQ-002](open-questions.md#req-002)) — checker đối chiếu hai chiều.
     Người không đồng ý một REQ đã có nguồn: `/aw-clarify REQ-NNN` ghi việc đổi thành một mục ở đây
     (Status answered); câu trả lời cũ, nếu có, chuyển thành `Superseded answer:`. -->

<Nếu không có `open question` nào, ghi đúng dòng dưới đây rồi xoá phần còn lại:>
<No open questions.>

## Contents

<!-- Mục lục — máy sinh bằng `aw toc <thư-mục-feature>`, không viết tay. Mỗi heading ## / ### một link. -->

## REQ-002 — <tiêu đề trùng với mục trong spec.md>

- **Source says:** <trích nguyên văn, hoặc "không đề cập">
- **Question:** <câu hỏi cụ thể, trả lời được bằng một câu>
- **Ask:** <BA / PO / tên người>
- **Assumption:** <...>
- **If wrong, redo:** <task/module cụ thể>
- **Blocking:** `<blocking | review-blocking | non-blocking>`   <!-- agent đề xuất, người duyệt -->
- **Status:** `open`   <!-- open | answered -->
- **Answer:** <nguyên văn câu trả lời — ai trả lời, ngày; khi đó sửa luôn source label trong spec.md>
