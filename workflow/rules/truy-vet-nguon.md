# Luật: Truy vết nguồn

Áp dụng cho `01-spec`; checker của `02-design`, `03-plan`, `05-review` chạy lại checker của spec.

Lỗi nguy hiểm nhất: agent tự nghĩ ra yêu cầu rồi trình bày như thể tài liệu đã nói. Luật này biến nó thành lỗi máy kiểm được.

## Nhãn nguồn

Mỗi `### YC-NNN` trong `spec.md` có **đúng một** dòng `Source:` mang một nhãn:

| Nhãn | Nghĩa | Kèm theo |
|---|---|---|
| `[CONFLUENCE]` | Trích từ page Confluence | URL page + heading |
| `[JIRA]` | Trích từ issue Jira | Mã issue + URL |
| `[FILE]` | Trích từ file trong repo | Đường dẫn + heading |
| `[INFERRED]` | Quyết định kỹ thuật tự suy ra | Lý do + YC gốc nó phục vụ |
| `[OPEN-QUESTION]` | Chưa có nguồn, dùng giả định tạm | Mục cùng mã trong `open-questions.md` |

Không có nhãn thứ sáu. Không xếp được vào năm nhãn → không phải yêu cầu → ghi vào `open-questions.md`.

## `[INFERRED]` hay `[OPEN-QUESTION]`

- `[INFERRED]` — quyết định **kỹ thuật** tài liệu không cần nói, ai đọc cũng thấy hiển nhiên. Vd: index cột `created_at` khi BRD đòi lọc theo ngày.
- `[OPEN-QUESTION]` — quyết định **nghiệp vụ** tài liệu bỏ trống, người khác có thể chọn khác. Vd: BRD nói "thông báo" nhưng không nói email hay in-app.

Phép thử: BA/PO có thể nói "không, ý tôi khác" → `[OPEN-QUESTION]`. Gắn `[INFERRED]` cho quyết định nghiệp vụ là vi phạm nặng hơn bỏ trống nhãn — máy không bắt được.

## Mức chặn của `[OPEN-QUESTION]`

Agent đề xuất `Blocking`, người duyệt. Chọn theo "nếu giả định sai thì phải làm lại gì". Chỉ người được hạ mức.

| Mức | Khi nào | Chặn gì |
|---|---|---|
| `blocking` | Sai thì cả thiết kế đổi hướng | `02-design` (chore: `03-plan`) và mọi phase sau, tới khi `answered` |
| `review-blocking` | Sai thì làm lại một phần code | Flow đi tiếp trên giả định tạm; `04-implement` cảnh báo, `05-review` chặn |
| `non-blocking` | Sai thì sửa nhỏ, giao trước được | Không chặn; review ghi YC đó `pending` |

Trả lời một điểm mù: ghi `Answer:`, đổi `Status: answered`, **và** đổi nhãn nguồn của YC trong spec (vd `[FILE]` open-questions.md § YC-002). Hai file lệch nhau thì checker chặn.

## `aw check spec <thư-mục-feature>` kiểm

1. Mỗi `### YC-NNN` có đúng một `Source:` hợp lệ. Vùng YC kết thúc ở heading `##`/`###` kế tiếp (dòng `Source:` dưới `### Ghi chú` không tính cho YC trên). Mã YC không trùng.
2. Mỗi YC có `Priority: must | should` và ít nhất một `- [ ] …` có nội dung thật (không `<...>`, không trong comment HTML).
3. Mỗi `[OPEN-QUESTION]` có mục cùng mã trong `open-questions.md`, có `Assumption`, có `Blocking` hợp lệ.
4. Ngược lại: mỗi mục `open-questions.md` trỏ về YC có thật; `Status: open | answered`; `open` ↔ spec còn `[OPEN-QUESTION]`; `answered` ↔ có `Answer` và spec đã đổi nhãn. File 0 byte hợp lệ (đã rà, không có điểm mù).
5. `spec.md` có `Risk: high | normal` và đúng một ô `- [ ] **Approved by human**` ở phần đầu; đã tick thì dấu duyệt phải khớp nội dung.
6. Có đủ `## Constraints & dependencies`, `## Out of scope`, `## Source conflicts` với nội dung thật (không có gì thì ghi thẳng "Không có…" / "Không phát hiện mâu thuẫn.").
7. Mỗi dòng mâu thuẫn có cột "Xử lý" trỏ tới điểm mù (`open-questions.md § YC-NNN`) hoặc nguồn đã chốt (`[CONFLUENCE]` `[JIRA]` `[FILE]`). Agent tự phân xử mâu thuẫn nghiệp vụ = tự nghĩ ra yêu cầu.
8. Mục `blocking` còn `open` chặn design (chore: plan); `review-blocking` còn mở: implement cảnh báo, review chặn.
