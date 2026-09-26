---
id: spec
name: Đặc tả
summary: Chưng cất BRD/PRD/ticket thành đặc tả kiểm chứng được và soi ra điểm mù
required: true
inputs:
  - confluence
  - jira
  - file
  - brief
outputs:
  - spec.md
  - open-questions.md
exit_machine:
  - sh tools/kiem-tra-truy-vet.sh
exit_human:
  - Chủ repo duyệt danh sách yêu cầu và phần "Ngoài phạm vi"
  - Chủ repo duyệt nhãn "Mức ảnh hưởng" của từng [CẦN-HỎI]
  - Chủ repo duyệt "Mức rủi ro" (cao → design chạy Mode 2, người phác D-xx trước)
needs_clean_context: true
---

# Phase 01 — Đặc tả

## Mục tiêu

Chưng cất yêu cầu nghiệp vụ thành đặc tả kỹ thuật **kiểm chứng được**, và soi ra
những chỗ tài liệu thượng nguồn nói chưa rõ hoặc tự mâu thuẫn.

Phase này **không sinh ra yêu cầu mới**. Nó dịch và làm sắc yêu cầu đã có. Mọi
thứ không truy về được nguồn đều phải lộ ra chứ không được trộn lẫn vào.

## Đầu vào

Ít nhất một trong:

| Nguồn | Cách lấy | Định danh ghi lại |
|---|---|---|
| Confluence | MCP Atlassian, đọc page | URL page + tên heading |
| Jira | MCP Atlassian, đọc issue | Mã issue + URL |
| File cục bộ (kể cả incident note) | Đọc trực tiếp | Đường dẫn + heading |
| `brief.md` | Do `00-ideation` sinh ra | Tên mục |

Nếu không có nguồn nào: dừng lại và chạy `00-ideation` trước. Không tự bịa
yêu cầu để có cái mà làm.

## Việc phải làm

1. **Thu thập nguồn.** Đọc hết tài liệu được trỏ tới. Ghi lại định danh chính
   xác của từng nguồn — sẽ dùng làm nhãn truy vết. Không đọc lướt rồi tóm tắt.

2. **Trích yêu cầu thô.** Trích *nguyên văn* các câu mang yêu cầu, chưa diễn
   giải. Bước này tách riêng để phân biệt rõ "tài liệu nói gì" với "ta hiểu thế
   nào" — hai thứ này trộn vào nhau là gốc của phần lớn sai lệch về sau.

3. **Chuyển thành yêu cầu kiểm chứng được.** Mỗi yêu cầu nhận mã `YC-NNN` và
   phải có tiêu chí chấp nhận **quan sát được từ bên ngoài**. "Hệ thống phải
   nhanh" không đạt; "trả kết quả tìm kiếm dưới 300ms với 10k bản ghi" thì đạt.

4. **Gắn nhãn nguồn** cho từng yêu cầu theo `rules/truy-vet-nguon.md`.

5. **Tách điểm mù.** Chỗ nào tài liệu không nói rõ: gắn `[CẦN-HỎI]`, ghi vào
   `open-questions.md` kèm:
   - **giả định tạm** đang dùng để đi tiếp;
   - *điều gì sẽ phải làm lại nếu giả định sai*;
   - **Mức ảnh hưởng** do bạn đề xuất: `toàn bộ thiết kế` (sai thì cả thiết kế
     đổi hướng) hoặc `cục bộ` (sai thì sửa vài chỗ). Người duyệt nhãn này.

   Mặc định điểm mù **không chặn** — ưu tiên flow đi tiếp. Chỉ mục `toàn bộ
   thiết kế` phải được trả lời (Trạng thái: `đã trả lời`) trước khi vào
   `02-design`.

6. **Rà mâu thuẫn.** Đối chiếu các nguồn với nhau. Mâu thuẫn giữa BRD và ticket
   là chuyện thường; phát hiện ở đây rẻ hơn phát hiện lúc đang code rất nhiều.

7. **Xác định "Ngoài phạm vi".** Liệt kê thẳng những thứ *không* làm lần này.
   Mục này tồn tại để chặn các phase sau làm quá tay — không có nó, agent sẽ coi
   mọi thứ liền kề là "hợp lý nên làm luôn".

8. **Đề xuất `Mức rủi ro`**: `cao` khi đụng tiền/hạch toán, tích hợp mới, schema
   lõi, hoặc thay đổi khó đảo ngược; còn lại `thường`. Ghi lý do một dòng.
   Nhãn này quyết định `02-design` chạy Mode 1 hay Mode 2.

## Đầu ra

- `spec.md` — theo `templates/spec.md`
- `open-questions.md` — theo `templates/open-questions.md`.
  Phải tồn tại kể cả khi rỗng, và khi rỗng phải ghi rõ "Không có điểm mù".
  File rỗng và file thiếu là hai chuyện khác nhau: một cái nghĩa là đã rà và
  không thấy gì, cái kia nghĩa là chưa rà.

## Cấm

- Bịa yêu cầu không truy được về nguồn.
- **Chọn giải pháp kỹ thuật** (chọn thư viện, thiết kế bảng, chia module) —
  việc của `02-design`.
- Tự chọn một cách hiểu cho chỗ mơ hồ rồi đi tiếp mà không ghi `[CẦN-HỎI]`.
- Gắn `[SUY-RA]` cho một quyết định nghiệp vụ để né việc phải hỏi.
- Hạ `Mức rủi ro` hoặc `Mức ảnh hưởng` xuống để khỏi bị chặn.
- Viết code, kể cả code minh hoạ.

## Điều kiện ra

**Máy:**
- `sh tools/kiem-tra-truy-vet.sh` trả về 0 — mọi YC có đúng một nhãn nguồn hợp
  lệ; mọi `[CẦN-HỎI]` có mục trong `open-questions.md` với giả định tạm và mức
  ảnh hưởng; spec có `Mức rủi ro` hợp lệ.

**Người:**
- Duyệt yêu cầu và "Ngoài phạm vi" — chỗ hiểu lệch nhau nhiều nhất, máy không
  kiểm thay được.
- Duyệt nhãn `Mức ảnh hưởng` và `Mức rủi ro` do agent đề xuất.

Mục `[CẦN-HỎI]` còn mở không được để `05-review` kết luận "đạt" cho YC đó.
