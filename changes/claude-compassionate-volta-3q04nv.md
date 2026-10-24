### Thay đổi
- **Open question có mã riêng `Q-NNN`, không còn lặp lại `spec.md`.** Trước đây mỗi mục trong
  `open-questions.md` mang mã và tiêu đề của một REQ, `Assumption` ghi ở cả hai file, đổi một REQ
  (`/aw-clarify REQ-NNN`) chép lại cả REQ đó, một câu hỏi đụng nhiều REQ phải ghi nhiều mục. Nay:
  - mục là `### Q-NNN — <câu hỏi ngắn>`, đánh số riêng; **một câu hỏi phủ được nhiều REQ**, mỗi REQ
    đứng trên tối đa một câu hỏi;
  - REQ trỏ tới câu hỏi ở dòng `Source: [OPEN-QUESTION] → [open-questions.md § Q-NNN](…)` — chỉ ở đó;
    câu hỏi không liệt kê REQ, `aw pending` và cổng mức chặn in sẵn câu hỏi phủ REQ nào;
  - giả định tạm chỉ ghi ở câu hỏi, REQ không còn dòng `Assumption:`;
  - đổi một REQ ghi thành một `Q-NNN` đã trả lời chỉ có `Question` + `Answer`;
  - `plan.md` ghi `On assumption: **yes** — [open-questions.md § Q-NNN](…)`; `aw task reopen <dir> Q-NNN`
    đưa task đứng trên câu hỏi đó về `[ ]`.
  - `aw check spec` chặn thêm: câu hỏi còn `open` mà không REQ nào trỏ tới, mã câu hỏi trùng, REQ
    `[OPEN-QUESTION]` không trỏ tới câu hỏi nào.

  **Việc đang chạy dở không phải làm gì:** mục dạng cũ `### REQ-NNN` và link `§ REQ-NNN` vẫn đọc được
  như trước, `aw check spec` chỉ in một dòng cảnh báo. Việc mới do `/aw-spec` viết theo dạng mới.

### Nội bộ
- Spec SP25 (`docs/superpowers/specs/2026-10-23-sp25-open-question-ma-rieng-design.md`) ghi lý do và
  các phương án đã loại.
