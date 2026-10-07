---
based_on: []
---

# Spec — <TÊN TÍNH NĂNG>

> Sinh bởi phase `01-spec`. Người sửa tay được; chạy lại phase sẽ cập nhật,
> không ghi đè trắng. `based_on` do `aw based-on` ghi — không sửa tay.

- **Risk:** `<high | normal>`
- **Reason:** <high khi đụng tiền/hạch toán, tích hợp mới, schema lõi, hoặc khó đảo ngược>
- **Status:** `proposed`   <!-- proposed | approved — CHỈ NGƯỜI đổi sang approved; sửa nội dung thì agent đặt lại proposed -->

## Sources

<!-- Phiên bản: Confluence = số version của page; Jira = thời điểm `updated` của issue;
[FILE] = sha commit đã đọc. Nguồn đổi sau đó thì so phiên bản để biết spec có lỗi thời. -->

| # | Type | Identifier | Version | Read on |
|---|---|---|---|---|
| 1 | Confluence | [Tên page](URL) | v12 | YYYY-MM-DD |
| 2 | Jira | [ABC-123](URL) | updated YYYY-MM-DDTHH:MM | YYYY-MM-DD |

## Context

<2–4 câu: vấn đề nghiệp vụ đang giải, cho ai.>

- **Users / roles:** <vai trò nào dùng, vai trò nào bị ảnh hưởng — theo nguồn>

<!-- Tuỳ chọn — chỉ thêm khi domain có từ dễ hiểu lệch (vd "kỳ", "hạch toán", "khách hàng" vs "người dùng"):
## Glossary

| Term | Meaning here | Source |
|---|---|---|
| | | |
-->

## Requirements

<!-- Source, Priority, Type, Protected by, Target phải nằm ngay dưới "### YC-NNN".
Heading "###" khác (vd "### Ghi chú") đóng vùng YC; muốn chia nhỏ một YC thì dùng "####".
Mỗi YC có ít nhất một tiêu chí chấp nhận dạng "- [ ] …" — checker chặn nếu thiếu. -->

### YC-001 — <tiêu đề ngắn>

- Source: `[CONFLUENCE]` [Tên page](URL) § Tên heading
- Priority: `must`   <!-- must | should — "should" chỉ khi NGUỒN nói vậy; nguồn im lặng = must -->
- Description: <yêu cầu, diễn đạt lại cho rõ>
- Acceptance criteria:
  - [ ] <quan sát được từ bên ngoài, có số liệu nếu là yêu cầu phi chức năng>

### YC-002 — <tiêu đề ngắn>

- Source: `[OPEN-QUESTION]` → `open-questions.md` § YC-002
- Priority: `must`
- Description: <...>
- Assumption: <đang hiểu thế nào để đi tiếp>
- Acceptance criteria:
  - [ ] <...>

<!-- CHỈ refactor / perf: mỗi YC có thêm
- Type: `preserve | structural | performance`   (performance: chỉ perf)
- Protected by: `test/<file>.test.ts`         (YC preserve — file có sẵn trên nhánh gốc)
- Target: p95 < 150 ms với 10k bản ghi         (YC performance — có số liệu)
Không có YC hành vi mới. -->

<!-- CHỈ bugfix: thêm mục dưới, bỏ comment
## Reproduction

- Steps to reproduce: <các bước / đầu vào cụ thể>
- Actual behavior: <điều đang xảy ra>
- Expected behavior: <điều phải xảy ra, theo nguồn nào>
-->

## Constraints & dependencies

<!-- Điều kiện bên ngoài mà việc này phải chịu — không phải yêu cầu, không phải giải pháp.
`Risk` và các quyết định D-xx ở `02-design` dựa vào mục này. -->

- <hệ thống ngoài / quy định pháp lý–kế toán / deadline / việc của team khác> — nguồn: <...>

<Không có thì ghi "Không có ràng buộc hay phụ thuộc ngoài.">

## Out of scope

<!-- Những thứ KHÔNG làm lần này. Mục này chặn phase sau làm quá tay.
Không có gì thì ghi "Không có." — checker chặn mục rỗng. -->

- <...> — lý do: <...>

## Source conflicts

<!-- Cột "Resolution" CHỈ được: trỏ tới điểm mù `open-questions.md § YC-NNN`, hoặc trỏ tới
nguồn đã chốt (`[JIRA]` comment của PO, `[CONFLUENCE]` page mới hơn, `[FILE]` …).
Agent không tự phân xử mâu thuẫn nghiệp vụ — checker chặn. -->

| Source A says | Source B says | Resolution |
|---|---|---|
| | | |

<Không có thì ghi "Không phát hiện mâu thuẫn.">
