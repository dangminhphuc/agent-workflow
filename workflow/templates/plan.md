---
based_on: []
---

# Plan — <TÊN TÍNH NĂNG>

## Contents

<!-- Mục lục — máy sinh bằng `aw toc <thư-mục-feature>`, không viết tay. Mỗi heading ## / ### một link. -->

## Tasks

### TSK-001 — <tiêu đề>
- Covers: `REQ-001`
- Based on: `DEC-001`
- Design: [tdd.md § Contract / API](tdd.md#contract--api)
- Depends on: none
- Expected files: `src/<...>` `test/<...>`
- Verify: `<lệnh cụ thể>` → `<kết quả mong đợi>`
- On assumption: no
- Status: `[ ]`

### TSK-002 — <tiêu đề>
- Covers: `REQ-002`
- Design: [tdd.md § Data model](tdd.md#data-model)
- Depends on: TSK-001
- Expected files: `<...>`
- Verify: `<...>`
- On assumption: **yes** — [open-questions.md § REQ-002](open-questions.md#req-002)
- Status: `[ ]`

> **Status:** `[ ]` chưa làm · `[~]` đang làm · `[x]` xong.
> Còn `[~]` nào thì phase 04 chưa đạt điều kiện ra.
> `Expected files` cho phép glob: `**` khớp qua thư mục (`src/**`), `*` trong một thư mục (`src/*`).
> Bản này `*` vẫn còn khớp qua `/` nhưng máy cảnh báo — bản sau thì không; cần đệ quy thì viết `**`.

## Deferred

Mã `REQ` không có task nào phủ, kèm lý do. Để trống mục này mà vẫn thiếu phủ thì
kiểm tra bằng máy sẽ fail.

| ID | Reason |
|---|---|
| | |

## Manual verification

REQ không test tự động được, kèm lý do. Không ghi ở đây mà cũng không có test gắn
tag `covers:` thì `/aw-implement` cảnh báo, `/aw-review` chặn.

| ID | Why not automated |
|---|---|
| | |

## Modified existing tests

CHỈ refactor / perf. Test có sẵn trên nhánh gốc mà bị sửa hay đổi tên phải khai ở
đây (đường dẫn trong backtick) kèm lý do — người rà soát đọc diff để xác nhận chỉ
đổi import/cấu trúc, không đổi assertion. **Xoá** test cũ thì bị chặn, không khai được.

| Test file | Reason |
|---|---|
| | |

## Dependency upgrades

CHỈ chore. Diff đụng `dependency_files` thì phải khai từng thư viện. Chỉ
`patch | minor`; nâng major là việc `refactor` riêng.

| Library | Old → new | Level |
|---|---|---|
| | | |

## Unplanned

Do `04-implement` ghi khi gặp điều kế hoạch chưa lường. File ngoài "Expected
files" phải ghi ở đây (trong backtick) kèm lý do.

| Task | What came up | Extra files | Resolution |
|---|---|---|---|
| | | | |
