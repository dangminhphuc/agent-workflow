# Review — <TÊN TÍNH NĂNG>

> Sinh bởi phase `05-review`, chạy bằng ngữ cảnh sạch.

<!-- Tree của code đã rà: chép dòng "- Tree:" trong test-results.md (máy đã kiểm
     nó khớp code hiện tại). Code đổi sau khi rà thì máy chặn — rà lại. -->
- Reviewed tree: `<sha>`
<!-- Chỉ khi diff đụng sensitive_code: NGƯỜI rà bảo mật tự ghi tên sau khi đọc
     Lens 4 và diff. Agent không điền. Không đụng: xoá dòng này. -->
- Security reviewer: <tên người>

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
- Repro test fails because: <trích dòng lỗi trong repro.md>

<!-- refactor / perf: với từng file ở "Modified existing tests" của plan.md, xác nhận diff chỉ
     đổi import/cấu trúc, không đổi assertion.
     perf: đọc perf.md, kết luận YC performance pass/fail theo số đo.
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

## Durable knowledge

<!-- Mỗi tài liệu `aw check implement` / `aw check review` báo bị diff đụng phạm vi (tài liệu
     module, ADR, file luật BR-) một dòng — thiếu là máy chặn. Không có: xoá mục này.
     Verdict: pass (đã đọc, vẫn đúng) | updated (đã sửa trong diff) | not applicable (kèm lý do). -->

| File | Verdict | Reason |
|---|---|---|
| `src/<module>/ARCHITECTURE.md` | pass | |

## Lens 3 — Quality

<!-- Không có finding nào: xoá ba mục mẫu, ghi đúng một dòng "- None".
     [Blocker] / [Should fix]: Location dạng `file:dòng` (số dòng thật).
     [Blocker]: thêm Failure scenario — đầu vào cụ thể → kết quả sai.
     [Blocker] / [Should fix]: Category — loại lỗi kebab-case (vd missing-null-check,
     sql-injection). Dùng lại tên đã có trong `aw journal` để đếm được lặp lại. -->

### [Blocker] <tiêu đề>
- Category: <loại-lỗi>
- Location: `file:dòng`
- Problem: <...>
- Failure scenario: <đầu vào cụ thể → kết quả sai>

### [Should fix] <tiêu đề>
- Category: <loại-lỗi>
- Location: `file:dòng`
- Problem: <...>

### [Nit] <tiêu đề>
- Location: `file:dòng`

## Lens 4 — Security

<!-- Đủ cả bảy dòng, không đổi tên hạng mục — máy chặn nếu thiếu.
     Verdict: pass | finding (kèm file:dòng, thêm finding ở Lens 3) | not applicable (kèm lý do).
     Authn / authz: đối chiếu YC Phân quyền trong spec.md. -->

| Item | Verdict | Location / reason |
|---|---|---|
| Input validation / injection | <pass \| finding \| not applicable> | <...> |
| Authn / authz | <...> | <...> |
| Sensitive data / PII in logs | <...> | <...> |
| Secrets / config | <...> | <...> |
| Crypto | <...> | <...> |
| SSRF / path traversal / deserialization | <...> | <...> |
| New dependencies | <...> | <...> |

## Carried-over warnings

Lỗi "Cảnh báo chưa xử lý" từ `aw check review` (YC chưa có test, diff ngoài
phạm vi, artifact lỗi thời). Còn mục nào thì review không đạt.

- <...>

## Conclusion

- Blocker findings: <n>   <!-- phải bằng số mục [Blocker] ở Lens 3 -->
- Mergeable: <no / yes after fixing Blockers>
