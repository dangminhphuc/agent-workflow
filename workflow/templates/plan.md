---
based_on: []
---

# Plan — <TÊN TÍNH NĂNG>

## Tasks

### T-01 — <tiêu đề>
- Covers: `YC-001`
- Based on: `D-01`
- Design: `tdd.md` § Contract / API
- Depends on: none
- Expected files: `src/<...>` `test/<...>`
- Verify: `<lệnh cụ thể>` → `<kết quả mong đợi>`
- On assumption: no
- Status: `[ ]`

### T-02 — <tiêu đề>
- Covers: `YC-002`
- Design: `tdd.md` § Data model
- Depends on: T-01
- Expected files: `<...>`
- Verify: `<...>`
- On assumption: **yes** — `open-questions.md` § YC-002
- Status: `[ ]`

> **Status:** `[ ]` chưa làm · `[~]` đang làm · `[x]` xong.
> Còn `[~]` nào thì phase 04 chưa đạt điều kiện ra.
> `Expected files` cho phép glob; `*` khớp cả `/`.

## Deferred

Mã `YC` không có task nào phủ, kèm lý do. Để trống mục này mà vẫn thiếu phủ thì
kiểm tra bằng máy sẽ fail.

| ID | Reason |
|---|---|
| | |

## Manual verification

YC không test tự động được, kèm lý do. Không ghi ở đây mà cũng không có test gắn
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
