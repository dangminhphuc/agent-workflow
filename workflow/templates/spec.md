---
based_on: []
---

# Spec — <TÊN TÍNH NĂNG>

- **Risk:** `<high | normal>`
- **Reason:** <high khi đụng tiền/hạch toán, tích hợp mới, schema lõi, hoặc khó đảo ngược>
- **Design:** `<required | skip>`   <!-- skip: chỉ bugfix/refactor nhỏ có Risk normal, không có lựa chọn kỹ thuật — bỏ phase design, đi thẳng /aw-plan. Người duyệt cùng spec -->
- [ ] **Approved by human** — đã đọc và đồng ý toàn bộ spec   <!-- CHỈ NGƯỜI tick [x]; agent không bao giờ tick, sửa nội dung thì agent bỏ tick. Máy ghi approval hash (hash nội dung) cạnh tick; nội dung đổi sau đó thì bị chặn tới khi người duyệt lại -->

## Contents

<!-- Mục lục — máy sinh bằng `aw toc <thư-mục-feature>`, không viết tay. Mỗi heading ## / ### một link. -->

## Sources

<!-- Phiên bản: Confluence = số version của page; Jira = thời điểm `updated` của issue;
[ISSUE] = thời điểm `updated` của issue/PR/MR; [FILE] = sha commit đã đọc. Nguồn đổi sau đó thì so phiên bản để biết spec có bị `stale` không. -->

| # | Type | Identifier | Version | Read on |
|---|---|---|---|---|
| 1 | Confluence | [Tên page](URL) | v12 | YYYY-MM-DD |
| 2 | Jira | [ABC-123](URL) | updated YYYY-MM-DDTHH:MM | YYYY-MM-DD |
| 3 | Issue | [o/r#12](URL) | updated YYYY-MM-DDTHH:MM | YYYY-MM-DD |

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

<!-- Source, Quote, Priority, Type, Protected by, Target phải nằm ngay dưới "### REQ-NNN".
Heading "###" khác (vd "### Ghi chú") đóng vùng REQ; muốn chia nhỏ một REQ thì dùng "####".
Mỗi REQ có ít nhất một tiêu chí chấp nhận dạng "- [ ] …" — checker chặn nếu thiếu.
Quote: nguồn [CONFLUENCE] [JIRA] [ISSUE] [FILE] bắt buộc — chép NGUYÊN VĂN câu nguồn, mỗi câu một dòng "> …"
(không thêm ngoặc kép). [FILE]: máy kiểm từng câu có trong file (khoảng trắng, xuống dòng không tính). -->

### REQ-001 — <tiêu đề ngắn>

- Source: `[CONFLUENCE]` [Tên page](URL) § Tên heading
- Quote:
  > <chép nguyên văn câu nguồn>
- Priority: `must`   <!-- must | should — "should" chỉ khi NGUỒN nói vậy; nguồn im lặng = must -->
- Description: <yêu cầu, diễn đạt lại cho rõ>
- Acceptance criteria:
  - [ ] <quan sát được từ bên ngoài, có số liệu nếu là yêu cầu phi chức năng>

### REQ-002 — <tiêu đề ngắn>

- Source: `[OPEN-QUESTION]` → [open-questions.md § Q-001](open-questions.md#q-001)   <!-- giả định tạm ghi ở câu hỏi, không chép vào đây -->
- Priority: `must`
- Description: <viết theo giả định tạm của Q-001>
- Acceptance criteria:
  - [ ] <...>

<!-- Luật bền (tuỳ chọn, NGƯỜI quyết bằng cách duyệt spec): REQ là bất biến nghiệp vụ còn đúng
sau việc này (không phải chi tiết màn hình), nguồn bền ([JIRA] [CONFLUENCE] [ISSUE] [FILE], hay lời người
đã ghi trong intake.md / open-questions.md) → thêm dưới REQ:
- Promote: BR-<MIỀN>-NNN       vd BR-BILLING-003; 04-implement chép REQ thành luật (aw rule promote) -->

<!-- CHỈ refactor / perf: mỗi REQ có thêm
- Type: `preserve | structural | performance`   (performance: chỉ perf)
- Protected by: `test/<file>.test.ts`         (REQ preserve — file có sẵn trên nhánh gốc)
- Target: p95 < 150 ms với 10k bản ghi         (REQ performance — có số liệu)
Không có REQ hành vi mới. -->

<!-- CHỈ bugfix: thêm mục dưới, bỏ comment
## Reproduction

- Steps to reproduce: <các bước / đầu vào cụ thể>
- Actual behavior: <điều đang xảy ra>
- Expected behavior: <điều phải xảy ra, theo nguồn nào>
-->

## Constraints & dependencies

<!-- Điều kiện bên ngoài mà việc này phải chịu — không phải yêu cầu, không phải giải pháp.
`Risk` và các quyết định DEC-xxx ở `02-design` dựa vào mục này. -->

- <hệ thống ngoài / quy định pháp lý–kế toán / deadline / việc của team khác> — nguồn: <...>

<Không có thì ghi "Không có ràng buộc hay phụ thuộc ngoài.">

## Out of scope

<!-- Những thứ KHÔNG làm lần này. Mục này chặn phase sau làm quá tay.
Không có gì thì ghi "Không có." — checker chặn mục rỗng. -->

- <...> — lý do: <...>

## Source conflicts

<!-- Cột "Resolution" CHỈ được: trỏ tới `open question` `[open-questions.md § Q-NNN](open-questions.md#q-nnn)`, hoặc trỏ tới
nguồn đã chốt (`[JIRA]` comment của PO, `[CONFLUENCE]` page mới hơn, `[FILE]` …).
Agent không tự phân xử mâu thuẫn nghiệp vụ — checker chặn. -->

| Source A says | Source B says | Resolution |
|---|---|---|
| | | |

<Không có thì ghi "Không phát hiện mâu thuẫn.">
