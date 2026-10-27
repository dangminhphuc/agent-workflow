# Spec: Nhãn máy và heading tiếng Anh

- Ngày: 2026-10-27 · Branch: `claude/blissful-darwin-t5ekcm` · PR: một PR duy nhất vào `main`
- Trạng thái: **đã chốt** — người duyệt bảng ánh xạ ở §3 (ngày 2026-10-27), không đổi thêm.
- Interface: **no interface change: chỉ đổi chữ hiển thị; mã thoát, capability, invariant và luật
  của checker giữ nguyên.** Mọi checker vẫn in khối `Kết quả` (tiếng Anh: `Result`), chỉ đổi nhãn.

## 0. Vấn đề

Nhãn `[x]` của mỗi checker và heading của prompt sinh ra đang tiếng Việt, gồm khoảng 100 nhãn khác
nhau (`ĐẠT`, `KHÔNG ĐẠT`, `SAI THAM SỐ`, `CHƯA DUYỆT`, `XANH`, `ĐỎ`, `Cần bạn`…). Người dùng và agent
đọc các nhãn này nhiều nhất, nhưng nhiều nhãn dài, lặp chữ, và các nhãn đúng/sai không nhất quán
(`ĐẠT` / `KHÔNG ĐẠT` ở checker, `ĐÃ DUYỆT` / `CHƯA DUYỆT` ở approval, `XANH` / `ĐỎ` ở test).

## 1. Quyết định

1. **Nhãn máy và heading sinh ra bằng tiếng Anh, viết ngắn.** Nhãn đúng/sai dùng cặp đối xứng
   (`PASS` / `FAIL`, `APPROVED` / `NOT APPROVED`, `GREEN` / `RED`, `VALID` / `INVALID`).
2. **Phần mô tả sau dấu ` — ` giữ tiếng Việt.** Đó là lời giải thích cho người đọc, không phải nhãn.
   Ví dụ: `[x] PASS — được sang phase sau` (nhãn tiếng Anh, mô tả tiếng Việt).
3. **Chú thích trong mã (dòng bắt đầu bằng `#`) giữ tiếng Việt.** Không đổi.
4. **Lịch sử không đổi:** `CHANGELOG.md`, `docs/superpowers/specs/` và `plans/` cũ giữ nguyên.
5. **Đồng bộ một lượt:** mỗi nhãn đổi đi kèm checker, test và tài liệu cùng commit. Test mới khoá
   quy tắc: mọi nhãn `kq_khai` là chữ ASCII in hoa (xem §5).

## 2. Phạm vi

Đổi trong:

- Nhãn `kq_khai` của mọi script `tools/*.sh`, `tools/lib/result.sh`, `bin/aw`.
- Chuỗi checker/test so khớp đúng (`grep`, `case`, `[ "$x" = … ]`) và chuỗi in ra của script.
- Heading và nhãn sinh trong prompt: `adapters/lib/common.sh`, `adapters/*/build.sh`,
  `adapters/*/README.md`.
- Heading và nhãn trong artifact do máy ghi: `security-results.md`, `test-results.md`,
  `repro.md`, `task-results.md` (xem §4).
- Tài liệu và prompt nói về nhãn: `README.md`, `docs/huong-dan.md`, `docs/thuat-ngu.md`,
  `docs/kien-truc.md`, `docs/interface-sdlc.md`, `AGENTS.md`, `workflow/**`, `sdlc/invariants.md`,
  `workflow.yaml`, `workflow/templates/*`.

Heading tiếng Việt khác (ví dụ `## Kết quả` trong README) đổi theo §4.

## 3. Bảng ánh xạ nhãn

Mỗi dòng: nhãn cũ → nhãn mới. Nhãn dài khớp trước nhãn ngắn (`KHÔNG ĐẠT` trước `ĐẠT`).

| Cũ | Mới |
|---|---|
| `KHÔNG ĐẠT` | `FAIL` |
| `ĐẠT` | `PASS` |
| `THIẾU ĐẦU VÀO` | `NO INPUT` |
| `SAI THAM SỐ HOẶC THIẾU FILE` | `BAD ARGS OR MISSING FILE` |
| `SAI THAM SỐ HOẶC REF` | `BAD ARGS OR REF` |
| `SAI THAM SỐ` | `BAD ARGS` |
| `SAI CÁCH GỌI` | `BAD CALL` |
| `SAI CHUẨN AGENT` | `BAD AGENT FORMAT` |
| `ĐỊNH NGHĨA QUY TRÌNH LỖI` | `PROCESS DEFINITION ERROR` |
| `KHÔNG HỢP LỆ` | `INVALID` |
| `HỢP LỆ` | `VALID` |
| `TÊN KHÔNG HỢP LỆ` | `INVALID NAME` |
| `ĐÃ NÂNG` | `UPGRADED` |
| `TỪ CHỐI / ĐỎ` | `REJECTED / RED` |
| `TỪ CHỐI` | `REJECTED` |
| `ĐÃ DUYỆT` | `APPROVED` |
| `CHƯA DUYỆT` | `NOT APPROVED` |
| `KHÔNG TICK` | `NOT TICKED` |
| `ĐÃ BỎ TICK` | `UNTICKED` |
| `KHÔNG CÒN Ô CHỜ DUYỆT` | `NONE PENDING` |
| `CÓ Ô CHỜ DUYỆT` | `PENDING` |
| `ĐÃ GHI SỐ ĐO` | `WRITTEN` |
| `ĐÃ GHI` | `WRITTEN` |
| `KHÔNG CHẠY ĐƯỢC` | `CANNOT RUN` |
| `ĐÃ BỎ` | `REMOVED` |
| `ĐÃ LIỆT KÊ` | `LISTED` |
| `ĐÃ INIT` | `INITIALIZED` |
| `CÓ FILE VIẾT TAY` | `HAND-WRITTEN FILE` |
| `KHÔNG CÓ GÌ PHẢI CHẶN` | `NOTHING TO BLOCK` |
| `ĐÃ ĐỔI TÊN` | `RENAMED` |
| `KHÔNG ĐỔI ĐƯỢC` | `CANNOT RENAME` |
| `ĐÃ ĐÓNG GÓI` | `PACKAGED` |
| `VERSION LỖI` | `VERSION ERROR` |
| `ĐÃ CHUẨN BỊ` | `PREPARED` |
| `KHÔNG CÓ GÌ ĐỂ PHÁT HÀNH` | `NOTHING TO RELEASE` |
| `MẢNH CHANGELOG LỖI` | `CHANGELOG FRAGMENT ERROR` |
| `SẴN SÀNG` | `READY` |
| `CHƯA SẴN SÀNG` | `NOT READY` |
| `ĐÃ CÓ WORKTREE` | `WORKTREE EXISTS` |
| `NGUỒN` | `SOURCE` |
| `ĐƯỜNG DẪN KHÔNG TỒN TẠI` | `PATH NOT FOUND` |
| `KHÔNG CÓ THAM SỐ` | `NO ARGS` |
| `LỜI NGƯỜI DÙNG` | `USER WORDS` |
| `ĐANG Ở CHECKOUT CHÍNH` | `ON MAIN CHECKOUT` |
| `ĐÃ XÁC ĐỊNH` | `RESOLVED` |
| `CẦN HỎI NGƯỜI` | `ASK HUMAN` |
| `CÓ VIỆC ĐANG CHẶN` | `BLOCKED` |
| `CÓ VIỆC BỊ CHẶN` | `BLOCKED` |
| `BỊ CHẶN` | `BLOCKED` |
| `CÒN VIỆC CHỜ NGƯỜI, CHƯA CHẶN phase kế tiếp` | `WAITING, NOT BLOCKING the next phase` |
| `KHÔNG CÒN VIỆC CHỜ NGƯỜI` | `NOTHING WAITING` |
| `XONG` | `DONE` |
| `DỪNG` | `STOP` |
| `KẸT` | `STUCK` |
| `HẾT TASK` | `NO TASKS LEFT` |
| `KHÔNG CÓ NHÁNH ĐÍCH` | `NO TARGET BRANCH` |
| `ĐÃ CÓ MR ĐANG MỞ` | `MR ALREADY OPEN` |
| `KÉO THEO COMMIT NGOÀI VIỆC` | `EXTRA COMMITS` |
| `KHÔNG TẠO ĐƯỢC MR` | `MR NOT CREATED` |
| `ĐÃ TẠO MR` | `MR CREATED` |
| `ĐÃ MERGE HẾT` | `ALL MERGED` |
| `CÒN MR ĐANG MỞ` | `MR OPEN` |
| `CÓ MR BỊ ĐÓNG KHÔNG MERGE` | `MR CLOSED UNMERGED` |
| `CHƯA RÕ` | `UNKNOWN` |
| `CÒN LINK SAI` | `BAD LINKS` |
| `CHƯA ĐỦ ĐIỀU KIỆN` | `NOT ELIGIBLE` |
| `MỌI CA ĐẠT` | `ALL PASS` |
| `CÓ CA HỎNG` | `FAILED CASES` |
| `CÓ VẤN ĐỀ` | `PROBLEMS` |
| `CHƯA ĐỦ` | `NOT ENOUGH` |
| `ĐANG Ở CHECKOUT CHÍNH` | `ON MAIN CHECKOUT` |
| `KHÔNG CÒN` | `NONE LEFT` |
| `KHÔNG HỢP LỆ` | `INVALID` |

Tag đánh dấu và nhóm heading mà máy in ra (test và checker khớp đúng; cũng dùng dạng escape `\[…\]` trong regex):

| Cũ | Mới |
|---|---|
| `[LỖI]` | `[ERROR]` |
| `[CẢNH BÁO]` | `[WARN]` |
| `CẢNH BÁO` đứng riêng (dòng tiến độ test, `CẢNH BÁO:` của task) | `WARN` |
| `[ĐÃ XỬ LÝ]` | `[HANDLED]` |
| `[ĐÃ KHỚP]` / `ĐÃ KHỚP` | `MATCHED` |
| `CHƯA PHÂN MỨC` | `UNRATED` |
| `PHÁT HIỆN — CHẶN` | `FOUND — BLOCKING` |
| `PHÁT HIỆN — CẢNH BÁO` | `FOUND — WARN` |
| `LỖI NGOÀI DỰ KIẾN` | `UNEXPECTED ERROR` |

Không đổi (văn xuôi cho người đọc, không ai khớp chữ): tiền tố `LỖI:` và `LỖI [<agent>]:` trong các
câu thông báo lỗi tiếng Việt, tên test, chú thích trong mã, và văn xuôi trong tài liệu.

Heading và cụm cố định (chỉ đổi phần heading, không đổi lời dặn xung quanh):

| Cũ | Mới |
|---|---|
| `Kết quả` (heading, khối cuối lệnh, `Kết quả:`) | `Result` |
| `Cần bạn:` | `Needs you:` |
| `Tiếp theo:` | `Next:` |
| `Đang làm với:` | `Working on:` |
| `XANH` (trong artifact và test) | `GREEN` |
| `ĐỎ` (trong artifact và test) | `RED` |
| `Kết quả kiểm thử` / `kiểm chứng task` / `quét bảo mật` (heading artifact) | `Test result` / `Task verification` / `Security scan` |

## 4. Artifact do máy ghi

- `security-results.md`: `- Kết quả: **XANH**` → `- Result: **GREEN**`; `- Kết quả: **ĐỎ**` → `- Result: **RED**`.
- `tools/check-review.sh` đọc đúng dòng này; đổi cùng commit với nơi ghi (`check-security.sh`,
  `check-implement.sh`, `check-repro.sh`) và test (`06-review-freshness.sh`, `03-implement-security.sh`).
- **Job đang chạy dở:** artifact ghi trước khi nâng cấp còn dòng tiếng Việt. Muốn qua cổng
  `check-review` thì chạy lại `aw check security` (hoặc `aw check implement`). Ghi vào mảnh
  changelog mục `Thay đổi`. Không giữ đọc song song hai dạng: một nhãn, một chỗ.

## 5. Kiểm thử

- **Test mới (tools/tests/01-fixture-engine-toc.sh):** mọi `N=LABEL` trong `kq_khai` có `LABEL` chỉ gồm
  chữ ASCII in hoa, số, khoảng trắng, `-`, `/`, `,`, `(`, `)`. Chặn tái phát nhãn tiếng Việt.
- **Test cũ cập nhật cùng commit:** mọi chuỗi trong §3 trong `tools/tests/*.sh` và `08-adapters.sh`
  (`Cần bạn:`, `Tiếp theo: /aw-review`…).
- **Test chứng minh:** checker vẫn chặn khi nên chặn (`KHÔNG ĐẠT` cũ → `FAIL`) và vẫn đạt khi nên đạt.
  Khối `Result` vẫn chỉ có một `[x]`.
- `sh tools/run-tests.sh` phải kết thúc bằng nhãn `ALL PASS` (trước đây `MỌI CA ĐẠT`).

## 6. Tài liệu

- `docs/thuat-ngu.md` mục `Khối Kết quả`: ghi lại quyết định ở §1 (đảo quyết định cũ "giữ tiếng Việt").
- `docs/huong-dan.md` mục 1.5 và `README.md` mục "Kết quả của mọi lệnh": ví dụ dùng nhãn mới.
- `changes/claude-blissful-darwin-t5ekcm.md`: mục `Thay đổi` (nhãn đổi, job đang chạy phải chạy lại
  `aw check security`) và `Nội bộ` (test mới).

## 7. Ngoài phạm vi

- Đổi tên lệnh `/aw-*` (SP31).
- Đổi phần mô tả sau dấu ` — ` sang tiếng Anh.
- Đổi nội dung checker, luật, mã thoát.
