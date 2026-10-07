# Review — <TÊN TÍNH NĂNG>

> Sinh bởi phase `05-review`, chạy bằng ngữ cảnh sạch.

## Lens 1 — Spec conformance

Mọi mã `YC` trong `spec.md` phải có mặt ở bảng này.

| ID | Verdict | Evidence | Notes |
|---|---|---|---|
| YC-001 | pass | `file.ts:42` | |
| YC-002 | pending | `file.ts:88` | Giả định tạm chưa được xác nhận |

Verdict hợp lệ: `pass` / `partial` / `fail` / `pending`.

## By work type

<!-- bugfix — BẮT BUỘC, máy chặn nếu thiếu. Máy chỉ biết test tái hiện đã đỏ;
     bạn xác nhận nó đỏ ĐÚNG VÌ BUG, không phải vì lỗi biên dịch / thiếu hàm. -->
- Repro test fails because: <trích dòng lỗi trong tai-hien.md>

<!-- refactor / perf: với từng file ở "Modified existing tests" của plan.md, xác nhận diff chỉ
     đổi import/cấu trúc, không đổi assertion.
     perf: đọc do-hieu-nang.md, kết luận YC performance pass/fail theo số đo.
     chore: xác nhận mức "patch | minor" ở "Dependency upgrades" là đúng.
     Loại việc khác: xoá mục này. -->

## Lens 2 — Design and scope

- Deviations from `tdd.md` (D-xx / contract / data model): <liệt kê, hoặc "không có">
- Changes outside any task: <...>
- Tasks marked done with no trace in the diff: <...>
- Unplanned items handled silently: <...>

## Repo rules

<!-- Mỗi file `aw rules review` in ra một dòng — thiếu là máy chặn. Không in gì:
     xoá mục này. Verdict: pass | violation (kèm file:dòng, thêm finding ở Lens 3)
     | not applicable (kèm lý do). -->

| File | Verdict | Location / reason |
|---|---|---|
| `docs/coding-style.md` | pass | |

## Lens 3 — Quality

### [Blocker] <tiêu đề>
- Location: `file:dòng`
- Problem: <...>
- Failure scenario: <đầu vào cụ thể → kết quả sai>

### [Should fix] <tiêu đề>
- Location: `file:dòng`
- Problem: <...>

### [Nit] <tiêu đề>
- Location: `file:dòng`

## Carried-over warnings

Lỗi "Cảnh báo chưa xử lý" từ `aw check review` (YC chưa có test, diff ngoài
phạm vi, artifact lỗi thời). Còn mục nào thì review không đạt.

- <...>

## Conclusion

- Blocker findings: <n>
- Mergeable: <no / yes after fixing Blockers>
