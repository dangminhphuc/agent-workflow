# Plan: SP19 đợt 19c — gắn `# giữ:` cho 60 chỗ luật của `tools/check-spec.sh`

- Spec: [`2026-10-23-sp19-gan-id-con-lai-design.md`](../specs/2026-10-23-sp19-gan-id-con-lai-design.md) § 2 (bảng đợt), § 3 (cách chọn id)
- Đợt trước: 19b xong ở #97; đợt sau: 19d (`check-plan.sh`, `check-design.sh`)
- **Không gắn hàng loạt** — mỗi dòng dưới đây chọn theo § 3, người review đọc lại trong diff.

## Bảng mapping (60 chỗ; dòng số theo `main` 727383d)

| id | Dòng (check-spec.sh) | Lý do (spec § 3) |
|---|---|---|
| INV-005 | 64 | Entry check: spec chỉ chạy khi intake qua checker của nó — "next stage consumes only approved output". Thêm `tools/check-spec.sh` vào `Enforced by` của INV-005 + thêm ca test ở `tools/tests/02-spec.sh`. |
| CAP-require-03, INV-005 | 72 | `kc_loi_duyet`: spec đổi sau khi người tick — approval binds to content. |
| INV-012 | 77 | `toc_loi` — INV-012 (SP35, #109) nay có id; Enforced by đã nêu check-spec.sh. |
| CAP-require-01 | 88 | `luat_loi_spec`: `Promote:` sai dạng ID, nguồn không bền, ID trùng — hình thức trường của spec.md (§ 3.3, như ví dụ `Type` của intake). |
| CAP-require-01 | 103 | RFR: cấp heading cũ, sai dạng 3 chữ số, trùng — hình thức ID/heading của artifact trong thư mục spec. |
| CAP-require-02 | 188, 189 | open-questions.md: cấp heading cũ `## Q-NNN`, sai dạng 3 chữ số. |
| CAP-require-01 | 229, 230 | spec.md: mã REQ trùng, sai dạng. |
| CAP-require-02 | 269 | Mâu thuẫn trỏ tới Q-NNN mà open-questions.md không có mục (khớp tag sẵn ở 409 cho cùng loại lỗi). |
| CAP-require-01 | 271 | Cột "Resolution" phải trỏ tới open question hoặc nguồn đã chốt — yêu cầu phải truy về nguồn, agent không tự phân xử. |
| CAP-require-01 | 317, 319, 327 | `Risk:` thiếu / sai enum / cảnh báo từ khoá rủi ro — hình thức trường của spec.md. |
| CAP-require-01 | 334, 336, 338, 340 | `Design:` sai enum, chore ghi required, skip ngoài bugfix/refactor, skip khi Risk ≠ normal — hình thức trường của spec.md. |
| CAP-require-01 | 343 | spec không có yêu cầu nào. |
| CAP-require-01 | 346, 348 | Mục `## Out of scope` thiếu / rỗng / giữ chỗ. |
| CAP-require-01 | 349, 351 | Mục `## Constraints & dependencies` thiếu / rỗng / giữ chỗ. |
| CAP-require-01 | 352, 354 | Mục `## Source conflicts` thiếu / không có dòng nào. |
| CAP-require-01 | 364, 368, 370, 372 | REQ: hai dòng Source, thiếu tiêu chí chấp nhận, thiếu Priority, Priority sai enum — lõi của CAP-require-01. |
| CAP-require-01 | 375, 379, 385, 390 | Source: không nhãn, nhãn ngoài tập hợp, [INFERRED] không lý do, [JIRA] sai regex — truy nguồn. |
| CAP-plan-01 | 394 | Cảnh báo nguồn không có trong `## Input` của intake.md — giữ quan hệ spec ↔ input của work item (19b gắn CAP-plan-01 cho mọi dòng Input của intake). |
| CAP-require-01 | 398 | Nguồn thiếu câu trích `- Quote:` — truy nguồn nguyên văn. |
| CAP-require-02 | 413, 420, 423, 426, 429, 435 | Open question: gắn nhãn mà không trỏ tới câu hỏi; thiếu Assumption; nhãn cũ; thiếu Blocking; Blocking sai enum; `[FILE]` trỏ § Q không có mục. |
| CAP-require-02 | 446, 450, 454, 456, 459, 467 | OQ ↔ spec khớp trạng thái: mục mồ côi, Status sai enum, answered mà Answer trống, answered mà REQ vẫn [OPEN-QUESTION], open mà REQ gắn [FILE], open mà không REQ nào trỏ tới. |
| CAP-require-01 | 477, 479, 480, 481 | bugfix: mục `## Reproduction` thiếu / thiếu từng trường — hình thức mục bắt buộc của spec.md. |
| INV-008 | 489, 490 | refactor/perf: REQ thiếu `Type:` / Type sai enum — Engine của INV-008 là `preserve | structural | performance`. |
| INV-008 | 493 | REQ performance thiếu `Target:` kèm số liệu — "perf: or states a numeric performance target". |
| INV-008 | 496 | perf mà không có REQ nào `Type: performance`. |
| INV-008 | 515, 517 | Test bảo vệ preserve phải có sẵn trên base — "protected by a test that exists on the base branch". |
| CAP-require-01 | 545, 547 | Câu trích [FILE] phải có trong file nguồn (entry: chỉ cảnh báo) — truy nguồn nguyên văn. |

## Chưa gắn — chờ người duyệt capability mới (1 chỗ)

- **67** — `kc_quy_tac_loi`: file khai `rules_spec` (conventions.md) không có / chưa commit; `uses_*` khai skill / subagent không tìm thấy. Không capability nào nói "repo cung cấp luật và skill/subagent riêng cho từng phase" — không dùng id gần đúng (spec § 3.4). `check-conventions.sh` (242) và các checker khác cùng mẫu — đề xuất một capability chung khi duyệt.

## Các bước

1. [x] Viết ca test mới: entry check — `02-spec.sh`: "chặn khi intake.md không qua aw check intake" (INV-005 giờ nêu check-spec).
2. [x] Gắn 59 tag theo bảng trên (một tag phủ đúng một chỗ luật ngay dưới).
3. [x] `sdlc/invariants.md`: INV-005 `Enforced by` thêm `tools/check-spec.sh`.
4. [x] `sh tools/check-sdlc.sh --dem-luat` → `tools/check-spec.sh` còn 1; sửa `tools/unclassified-rules.txt` (60 → 1).
5. [x] `sh tools/check-sdlc.sh` → PASS; `sh tools/run-tests.sh` → ALL PASS (2125 ca).
6. [x] Roadmap: dòng SP19 ghi đợt 19c; changes mảnh `Nội bộ`.
