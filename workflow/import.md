---
id: import
name: Nhập artifact ngoài
summary: Đưa spec/tdd/plan viết bằng tool khác vào quy trình: chỉ sắp lại theo mẫu, không thêm nội dung
arguments: mixed
argument_hint: <file-nguồn> <spec.md|tdd.md|plan.md> [tên-feature]
trace_rule: true
---

# Import artifact từ ngoài vào

**Không phải phase.** Đưa tài liệu làm bằng tool khác (AI khác, Confluence, viết tay…) vào giữa quy trình — chỉ **sắp lại theo mẫu**, không thêm nội dung.

## Tham số

File nguồn (hoặc URL Confluence/Jira) và artifact đích (`spec.md` | `tdd.md` | `plan.md`). Thiếu một trong hai → dừng, hỏi.

## Việc phải làm

1. Đọc hết nguồn, ghi định danh chính xác (đường dẫn / URL).
2. Đọc `templates/<artifact-đích>` và điều kiện ra của phase sinh ra nó.
3. Sắp lại nội dung nguồn theo mẫu:
   - mỗi mục mang nhãn nguồn về tài liệu gốc (`[FILE] <đường dẫn> § <heading>`, `[CONFLUENCE] <URL> § <heading>`…);
   - mẫu đòi mà nguồn không có → **không lấp**: `spec.md` ghi `[OPEN-QUESTION]` + mục trong `open-questions.md`; mục khác của `tdd.md`/`plan.md` ghi `<THIẾU TRONG NGUỒN: …>` để checker chặn;
   - D-xx từ tài liệu người viết: `Author: human`, ô duyệt chưa tick.
4. Chạy checker của phase sinh ra artifact (`aw check spec` / `design` / `plan`), báo kết quả thật.
5. Dừng cho **người xác nhận bản chuyển đổi** — rồi mới qua gate người của phase đó như bình thường.

## Cấm

- **Thêm nội dung** không có trong nguồn, kể cả "hiển nhiên".
- Tick ô duyệt D-xx hay spec, kể cả khi nguồn nói đã duyệt — duyệt ở tool khác không phải duyệt trong quy trình này.
- Bỏ qua checker vì "đã duyệt ở chỗ khác".
