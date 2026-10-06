---
based_on: []
---

# Đặc tả — <TÊN TÍNH NĂNG>

> Sinh bởi phase `01-spec`. Người sửa tay được; chạy lại phase sẽ cập nhật,
> không ghi đè trắng. `based_on` do `aw based-on` ghi — không sửa tay.

- **Mức rủi ro:** `<cao | thường>`
- **Lý do:** <cao khi đụng tiền/hạch toán, tích hợp mới, schema lõi, hoặc khó đảo ngược>
- **Trạng thái spec:** `đề xuất`   <!-- đề xuất | đã duyệt — CHỈ NGƯỜI đổi sang đã duyệt; sửa nội dung thì agent đặt lại đề xuất -->

## Nguồn

<!-- Phiên bản: Confluence = số version của page; Jira = thời điểm `updated` của issue;
[FILE] = sha commit đã đọc. Nguồn đổi sau đó thì so phiên bản để biết spec có lỗi thời. -->

| # | Loại | Định danh | Phiên bản | Ngày đọc |
|---|---|---|---|---|
| 1 | Confluence | [Tên page](URL) | v12 | YYYY-MM-DD |
| 2 | Jira | [ABC-123](URL) | updated YYYY-MM-DDTHH:MM | YYYY-MM-DD |

## Bối cảnh

<2–4 câu: vấn đề nghiệp vụ đang giải, cho ai.>

- **Người dùng / vai trò liên quan:** <vai trò nào dùng, vai trò nào bị ảnh hưởng — theo nguồn>

<!-- Tuỳ chọn — chỉ thêm khi domain có từ dễ hiểu lệch (vd "kỳ", "hạch toán", "khách hàng" vs "người dùng"):
## Thuật ngữ

| Thuật ngữ | Nghĩa trong việc này | Nguồn |
|---|---|---|
| | | |
-->

## Yêu cầu

<!-- Nguồn, Ưu tiên, Loại YC, Được bảo vệ bởi, Mục tiêu phải nằm ngay dưới "### YC-NNN".
Heading "###" khác (vd "### Ghi chú") đóng vùng YC; muốn chia nhỏ một YC thì dùng "####".
Mỗi YC có ít nhất một tiêu chí chấp nhận dạng "- [ ] …" — checker chặn nếu thiếu. -->

### YC-001 — <tiêu đề ngắn>

- Nguồn: `[CONFLUENCE]` [Tên page](URL) § Tên heading
- Ưu tiên: `bắt buộc`   <!-- bắt buộc | nên có — "nên có" chỉ khi NGUỒN nói vậy; nguồn im lặng = bắt buộc -->
- Mô tả: <yêu cầu, diễn đạt lại cho rõ>
- Tiêu chí chấp nhận:
  - [ ] <quan sát được từ bên ngoài, có số liệu nếu là yêu cầu phi chức năng>

### YC-002 — <tiêu đề ngắn>

- Nguồn: `[CẦN-HỎI]` → `open-questions.md` § YC-002
- Ưu tiên: `bắt buộc`
- Mô tả: <...>
- Giả định tạm: <đang hiểu thế nào để đi tiếp>
- Tiêu chí chấp nhận:
  - [ ] <...>

<!-- CHỈ refactor / perf: mỗi YC có thêm
- Loại YC: `giữ nguyên | cấu trúc | hiệu năng`   (hiệu năng: chỉ perf)
- Được bảo vệ bởi: `test/<file>.test.ts`         (YC giữ nguyên — file có sẵn trên nhánh gốc)
- Mục tiêu: p95 < 150 ms với 10k bản ghi         (YC hiệu năng — có số liệu)
Không có YC hành vi mới. -->

<!-- CHỈ bugfix: thêm mục dưới, bỏ comment
## Tái hiện lỗi

- Cách tái hiện: <các bước / đầu vào cụ thể>
- Hành vi sai: <điều đang xảy ra>
- Hành vi đúng: <điều phải xảy ra, theo nguồn nào>
-->

## Ràng buộc & phụ thuộc

<!-- Điều kiện bên ngoài mà việc này phải chịu — không phải yêu cầu, không phải giải pháp.
`Mức rủi ro` và các quyết định D-xx ở `02-design` dựa vào mục này. -->

- <hệ thống ngoài / quy định pháp lý–kế toán / deadline / việc của team khác> — nguồn: <...>

<Không có thì ghi "Không có ràng buộc hay phụ thuộc ngoài.">

## Ngoài phạm vi

<!-- Những thứ KHÔNG làm lần này. Mục này chặn phase sau làm quá tay.
Không có gì thì ghi "Không có." — checker chặn mục rỗng. -->

- <...> — lý do: <...>

## Mâu thuẫn giữa các nguồn

<!-- Cột "Xử lý" CHỈ được: trỏ tới điểm mù `open-questions.md § YC-NNN`, hoặc trỏ tới
nguồn đã chốt (`[JIRA]` comment của PO, `[CONFLUENCE]` page mới hơn, `[FILE]` …).
Agent không tự phân xử mâu thuẫn nghiệp vụ — checker chặn. -->

| Nguồn A nói | Nguồn B nói | Xử lý |
|---|---|---|
| | | |

<Không có thì ghi "Không phát hiện mâu thuẫn.">
