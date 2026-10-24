# Spec: SP9b — Nhật ký đo lường để biết engine cần cải thiện gì

- Ngày: 2026-10-24 · Branch: `claude/sleepy-tesla-k2c0xj`
- Roadmap: làm nốt phần công cụ của § SP9 (Chạy thật + gom nhật ký). Phần chạy thật vẫn là việc người làm.
- Interface: không đổi — harness journal là công cụ phát triển engine, không thuộc stage SDLC nào.

## 0. Mục tiêu và giới hạn

**Người dùng:** một người (chủ engine) chạy `aw` trên 1–2 repo đích trong 2–4 tuần, gom nhật ký bằng
`aw journal export` / `aw journal report <file>…` như hiện nay.

**Thành công khi:** sau đợt chạy, `aw journal report` trên các file export trả lời được:

1. checker nào chặn nhầm nhiều (độ chính xác theo checker);
2. phase nào tốn thời gian / công người nhất;
3. việc phân bố theo loại và cỡ diff ra sao (đầu vào SP10);
4. lỗi lọt sau merge rơi vào lớp nào;

và so được hai version engine với nhau.

**Ràng buộc:** POSIX sh + awk + sed + git; nhật ký ở `$AW_CONFIG/journal/`, không commit vào repo đích;
ghi tự động không bao giờ đổi mã thoát hay output của lệnh chính.

**Không làm:** đếm token (agent không báo cho engine), kho gom chung nhiều người, ẩn dữ liệu nhạy cảm,
tự thêm luật từ số liệu, gộp bốn nguồn hiện có thành một luồng sự kiện (hướng B — xem § 6).

## 1. Hiện trạng

`tools/journal.sh` có bốn nguồn TSV: `checks.tsv` (engine ghi mỗi `aw check`, qua `bin/aw-engine`),
`failures.tsv` (`aw journal add`), `approvals.tsv` (`aw approvals tick`), `findings.tsv` (`aw check review`
khi ĐẠT). `export` thêm hai cột đầu (nguồn, máy); `report` tách lại theo số cột cố định mỗi nguồn
(`cot[]`), dòng sai số cột bị bỏ.

Thiếu: version engine của dòng; mốc phase; phân loại lần chặn đúng / nhầm; một dòng tổng kết mỗi việc;
nối bug về việc gây ra nó.

## 2. Dữ liệu

Mọi cột tách bằng tab, nội dung tự do qua `bay` (một dòng, không tab) như hiện nay.

### 2.1. Cột version cho nguồn cũ

`checks.tsv`, `failures.tsv`, `approvals.tsv`, `findings.tsv`: thêm **một cột cuối** = version engine
đang chạy (`VERSION` của thư mục engine). Không đọc được → `?`.

### 2.2. `phases.tsv` (mới, engine ghi)

`<thời điểm>  <việc>  <phase>  <version>`

Ghi khi `aw rules <phase>` chạy (mọi lệnh phase do adapter sinh đều gọi nó ở đầu phase —
`adapters/lib/common.sh`). `<việc>` suy như `aw feature` (tên branch khớp `branch_patterns` → tên
thư mục việc). Không ghi khi: đang ở checkout chính, không suy ra việc, `AW_JOURNAL=0`. Chạy nhiều lần
trong một phase → nhiều dòng; report chỉ lấy dòng đầu mỗi (việc, phase).

Intake chạy ở checkout chính nên không có dòng `phases.tsv`: mốc bắt đầu việc = lần `aw check intake`
đầu tiên của việc trong `checks.tsv`.

### 2.3. `jobs.tsv` (mới, `aw journal retro` ghi)

Một dòng mỗi việc; chạy lại `retro` thì thay dòng của việc đó (cách `findings.tsv` đang làm).

| Cột | Nguồn | Ghi chú |
|---|---|---|
| thời điểm | máy | lúc chạy `retro` |
| việc | máy | basename thư mục việc |
| version | máy | `Engine` trong `intake.md`; thiếu → version đang chạy |
| loại | máy | job type trong `intake.md` |
| phase | máy | danh sách phase có dòng `phases.tsv`, cách nhau `,` |
| design | máy | `ran` / `skipped` (theo `kc_bo_design`) |
| file | máy | số file đổi, `git diff --shortstat <merge-base Base>...HEAD`, bỏ `docs/sdlc/`, `.agent-workflow/` |
| dòng | máy | thêm + xoá, cùng phạm vi |
| trượt | máy | `checker:n` cho mỗi checker có lần không đạt, cách nhau `,`; không có → `-` |
| tick | máy | số dòng `approvals.tsv` của việc — chỉ tick qua `aw approvals tick`; tick tay không có dấu vết nên không đếm |
| giây | máy | từ mốc bắt đầu việc (§ 2.2) tới lúc `retro` |
| nhầm | người | số thứ tự lần chặn bị coi là nhầm (§ 3), cách nhau `,`; không có → `-` |
| phút | người | phút người bỏ ra, số nguyên; bỏ qua → `-` |
| vướng | người | một dòng chỗ vướng nhất; bỏ qua → `-` |
| gây bởi | người | chỉ bugfix: việc / PR gây ra lỗi; không biết → `-` |
| lọt lớp | người | chỉ bugfix: lớp lỗi lọt (`task context env verify state model`); không biết → `-` |

## 3. `aw journal retro <dir>`

**Không cờ** — in phần máy (§ 2.3) và danh sách các lần bị chặn của việc, đánh số theo thứ tự thời gian
trong `checks.tsv` (chỉ dòng mã thoát ≠ 0):

```
  #1  2026-10-24T03:10Z  spec       REQ-* thiếu Quote
  #2  2026-10-24T05:42Z  implement  test đỏ: …
```

rồi in câu hỏi cho người (lần nào nhầm, bao nhiêu phút, vướng nhất ở đâu, bugfix: do việc nào, lọt lớp
nào). Không ghi gì.

**Có cờ** — ghi dòng `jobs.tsv`:

```
aw journal retro <dir> [--nham <n,n…>] [--phut <n>] [--vuong "<một dòng>"] [--gay-boi <việc|PR>] [--lop <layer>]
aw journal retro <dir> --bo-qua          # chỉ phần máy, phần người để "-"
```

Nhãn: `XONG` (đã ghi / đã in) · `SAI THAM SỐ` — số trong `--nham` không có trong danh sách, `--phut`
không phải số nguyên ≥ 0, `--lop` lạ, `--gay-boi`/`--lop` ở việc không phải bugfix, `--bo-qua` cùng cờ
người, thiếu `<dir>` hoặc `<dir>` không có `intake.md`.

**Phase review:** thêm một bước cuối vào `workflow/phases/05-review.md` (tiếng Anh, ngắn): sau khi người
xác nhận kết luận, chạy `aw journal retro <dir>`, đưa danh sách cho người, ghi câu trả lời bằng lệnh có
cờ; người không trả lời → `--bo-qua`. Không thêm chữ ở adapter.

## 4. `report` và `export`

**`export`:** thêm `phases`, `jobs` vào danh sách nguồn.

**Đọc file export:** `cot[]` nhận cả số cột cũ (thiếu version → coi là `?`) và số cột mới, cho bốn nguồn
cũ; `phases`, `jobs` chỉ có dạng mới. Nhật ký cục bộ cũ dùng tiếp, không chuyển đổi.

**`report [--version <v>] [<file>…]`** — `--version` chỉ tính dòng có version đó. Mục mới, sau các mục
hiện có:

- **Độ chính xác checker:** mỗi checker: số lần chặn ở các việc có dòng `jobs.tsv` có phần người, số lần
  bị đánh nhầm, tỉ lệ đúng. Lần chặn của việc chưa retro hoặc `--bo-qua` không tính (in số bị loại).
- **Thời gian phase:** trung vị giây mỗi phase = mốc phase kế tiếp − mốc phase này (phase cuối: tới
  `retro`). Ghi chú ngay dưới: gồm cả thời gian chờ người.
- **Việc:** đếm theo loại; trung vị file, dòng, phút người theo loại; số việc bỏ design.
- **Lỗi lọt:** đếm `lọt lớp` của các dòng bugfix có giá trị.

Ít hơn 1 dòng dữ liệu cho một mục → in `(chưa có — …)` như các mục hiện có.

## 5. Lỗi và tắt

- Ghi tự động (cột version, `phases.tsv`) im lặng: mọi lỗi bị bỏ, mã thoát và stdout/stderr của
  `aw check` / `aw rules` không đổi. `AW_JOURNAL=0` tắt cả hai.
- `retro` là lệnh người gọi nên báo lỗi rõ (§ 3); `AW_JOURNAL=0` không ảnh hưởng `retro`.

## 6. Hướng đã cân nhắc

- **B. Một luồng `events.tsv` (`k=v`)** thay bốn nguồn: gọn về lâu dài nhưng phải chuyển đổi định dạng,
  sửa test hiện có, tách `k=v` trong awk dễ vỡ; lợi không đủ cho một người dùng.
- **C. Quét artifact sau khi xong:** `aw ship create` gỡ artifact khỏi branch trước MR — dữ liệu mất.

## 7. Test

Thêm vào `tools/tests/16-journal-adr.sh`; phần này thành `CẢNH BÁO … nên tách` → tách phần journal ra
phần riêng tại ranh giới fixture, cùng PR. Mỗi ca hai chiều:

- `aw check` ghi cột version; report đọc được export cũ (không version) lẫn mới, không bỏ dòng.
- `aw rules spec` trong worktree việc → một dòng `phases.tsv`; ở checkout chính → không; `AW_JOURNAL=0` → không.
- Thư mục journal không ghi được (file chiếm chỗ) → `aw check plan`, `aw rules spec` giữ mã thoát và output.
- `retro` không cờ: in đúng danh sách chặn đánh số, không ghi file.
- `retro` có cờ: phần máy đúng trên fixture (loại, trượt, tick, file); chạy lại thay dòng, không nhân đôi;
  `--nham` số lạ, `--phut abc`, `--lop mood`, `--gay-boi` ở việc không phải bugfix, `--bo-qua` kèm cờ
  người → `SAI THAM SỐ`.
- Report trên dữ liệu mẫu cố định: tỉ lệ đúng checker, trung vị phase, đếm theo loại, lỗi lọt; `--version`
  lọc đúng; export có `phases`, `jobs`.

`sh tools/run-tests.sh` → `MỌI CA ĐẠT`; `sh tools/check-sdlc.sh` → ĐẠT.

## 8. File đổi

- `tools/journal.sh` — cột version, `retro`, `export`, `report`.
- `bin/aw-engine` — truyền version khi ghi `checks.tsv`; ghi `phases.tsv` ở nhánh `rules`.
- `tools/approvals.sh` — cột version.
- `workflow/phases/05-review.md` — bước retro cuối phase.
- `tools/tests/16-journal-adr.sh` (hoặc phần tách mới) — § 7.
- `changes/claude-sleepy-tesla-k2c0xj.md` — `Thêm` (retro, report mới), `Thay đổi` (cột version).
- `docs/huong-dan.md` — cách chạy đợt đo và retro; `docs/kien-truc.md` § Cross-check, trạng thái sạch,
  nhật ký + § Những chỗ thiết kế này yếu (thời gian phase là xấp xỉ, gồm thời gian chờ); `docs/thuat-ngu.md`
  nếu thêm thuật ngữ (`retro`); roadmap § SP9 (công cụ xong, còn chạy thật).
