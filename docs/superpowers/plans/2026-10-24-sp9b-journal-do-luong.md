# SP9b — Nhật ký đo lường: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm cột version, mốc phase (`phases.tsv`), tổng kết cuối việc (`aw journal retro` → `jobs.tsv`) và các mục report mới, để sau đợt chạy thật biết engine cần cải thiện gì.

**Architecture:** `tools/journal.sh` giữ vai trò dispatcher và bốn nguồn cũ; logic `retro` nằm ở file mới `tools/journal-retro.sh` để `journal.sh` không phình quá. `bin/aw-engine` truyền version khi ghi `checks.tsv` và gọi `journal.sh _phase` ở nhánh `rules`. `report`/`export` đọc được cả file cũ (không cột version) lẫn mới. Mọi ghi tự động im lặng và tôn trọng `AW_JOURNAL=0`.

**Tech Stack:** POSIX sh, awk (mawk/BSD), sed, git. Không bashism, không Node/Python/jq.

**Spec:** [docs/superpowers/specs/2026-10-24-sp9b-journal-do-luong-design.md](../specs/2026-10-24-sp9b-journal-do-luong-design.md)

## Global Constraints

- POSIX sh + awk + sed + git only; ERE không dùng `{n}` (mawk); CI macOS: bash 3.2 làm `sh`, BSD awk/sed — chuỗi nhiều dòng hoặc có `\` đi qua `ENVIRON`, không `-v`.
- Chạy dưới `LC_ALL=C` (`tools/lib/result.sh`).
- Nhãn kết quả qua `kq_khai`; prompt và tài liệu nhắc nhãn, không nhắc mã thoát.
- Đường dẫn repo/cấu hình chỉ từ `AW_REPO`, `AW_CONFIG`.
- Ghi tự động (`checks.tsv` version, `phases.tsv`, cột version của `failures/approvals/findings`) không bao giờ đổi mã thoát hay stdout/stderr của `aw check` / `aw rules`. `AW_JOURNAL=0` tắt cả hai.
- Output người đọc: tiếng Việt. Commit message không ghi tên model.
- Mỗi task kết thúc bằng `sh tools/tests/27-journal-retro.sh` xanh; trước khi push: `sh tools/run-tests.sh` → `MỌI CA ĐẠT`.

## Review Focus

1. `aw journal retro <dir>` ở checkout chính hoặc khi `<dir>` không có `intake.md` → báo rõ, không ghi `jobs.tsv`.
2. `retro` chạy lại với cờ khác → thay dòng cũ của việc, không thành hai dòng.
3. `report` trên nhật ký trống hoặc chỉ có export cũ → in `(chưa có — …)` cho mục thiếu dữ liệu, không lỗi awk.
4. Export cũ (không cột version) và mới trộn trong một `report` → không bỏ dòng, cột thiếu hiện là `?`.
5. `aw rules <phase>` ngoài worktree việc (checkout chính, nhánh không khớp `branch_patterns`) → không ghi `phases.tsv`, mã thoát và stdout của `rules` giữ nguyên.

## File Structure

- Modify `tools/journal.sh` — dispatcher: thêm `_phase`, `retro`, cột version ở `_check`/`add`/`_findings`, `export` thêm `phases jobs`, `report` nhận `--version` và số cột cũ/mới, các mục report mới.
- Create `tools/journal-retro.sh` — `retro` (in phần máy + danh sách chặn; ghi `jobs.tsv` khi có cờ).
- Modify `bin/aw-engine` — `checks.tsv` ghi kèm version; nhánh `rules)` gọi `journal.sh _phase`.
- Modify `tools/approvals.sh` — cột version khi ghi `approvals.tsv`.
- Create `tools/tests/27-journal-retro.sh` — mọi ca mới (phần cũ ở `16` giữ nguyên).
- Modify `workflow/phases/05-review.md` — bước `aw journal retro` cuối phase (tiếng Anh, ngắn).
- Modify `docs/huong-dan.md`, `docs/kien-truc.md`, `docs/thuat-ngu.md`, `docs/superpowers/2026-10-22-roadmap-cai-thien.md` (SP9 — đã có dòng "Đang làm", sửa khi xong).
- Create `changes/claude-sleepy-tesla-k2c0xj.md` đã có — sửa mục `Nội bộ` thành `Thêm` / `Thay đổi` khi xong.

Lý do tách `journal-retro.sh`: `retro` có ~120 dòng logic riêng (đọc intake, tính giây, đánh số lần chặn, ghi thay dòng); để chung một file khiến `journal.sh` khó đọc. Đây là sai khác nhỏ so với spec § 8 — ghi vào phần "Thay đổi" của fragment.

---

### Task 1: Cột version cho mọi nguồn ghi

**Files:**
- Modify: `bin/aw-engine` (nhánh ghi `checks.tsv`, khoảng dòng 89–97)
- Modify: `tools/journal.sh` (`_check`, `_findings`, `add`)
- Modify: `tools/approvals.sh` (dòng ghi `approvals.tsv`, khoảng dòng 74–77)
- Create: `tools/tests/27-journal-retro.sh`

**Interfaces:**
- Consumes: `AW_ENGINE` (tools/lib/env.sh) — thư mục engine đang chạy; `VERSION` là file trong đó (cùng cách `bin/aw` đọc ở dòng 145).
- Produces: `journal.sh _check <checker> <feature> <dir> <ma> <file>` giữ nguyên số tham số, thêm version qua biến môi trường `AW_JOURNAL_VERSION` (aw-engine đặt; rỗng → `?`). Mọi dòng mới của bốn nguồn có cột version **cuối cùng**. Hàm đọc version: `jv_version` trong `journal.sh`, trả `?` khi không đọc được.

- [ ] **Step 1: Viết ca test thất bại trong `27-journal-retro.sh`**

Phần mở đầu giống `16` (`. lib.sh`, `tao_fixture`, `nhom`). Ca cần có:
- `aw-engine check plan "$F"` → mọi dòng mới của `checks.tsv` có cột cuối khớp `^[0-9]{4}\.[0-9]+\.[0-9]+$` hoặc `?` (dùng `grep -E '\.[0-9]+\.[0-9]+$|\t\?$'`, không `{n}`).
- `journal.sh add env "…"` → dòng cuối của `failures.tsv` có cột version.
- Số cột `checks.tsv` mỗi dòng = 5 + 1 (version).

Run: `sh tools/tests/27-journal-retro.sh` — Expected: FAIL ở các ca version.

- [ ] **Step 2: Chạy để thấy thất bại** (bước trên đã làm — ghi nhận output FAIL vào ghi chú khi báo cáo).

- [ ] **Step 3: Thêm `jv_version` và cột version**

Trong `tools/journal.sh`: `jv_version` đọc `$AW_ENGINE/VERSION` (dùng `tr -d ' \r\n'`), rỗng → `?`. Thêm `$(jv_version)` làm cột cuối trong `_findings`, `add`. `_check` nhận version từ `AW_JOURNAL_VERSION` (đặt trong `bin/aw-engine` trước khi gọi `_check`, bằng `AW_JOURNAL_VERSION=$(...)` theo dạng `VAR=value cmd`, không gán biến trước lời gọi hàm shell). `approvals.sh` cũng ghi cột version qua cùng cách đọc (đặt hàm đọc ở `tools/lib/` nếu hai nơi dùng chung — một file mới `tools/lib/journal-version.sh`, nạp ở cả hai).

- [ ] **Step 4: Chạy lại test** — Expected: `ĐẠT` các ca version.

- [ ] **Step 5: Kiểm `AW_JOURNAL=0` vẫn không ghi và mã thoát không đổi** (đã có ca ở `16`; chạy `sh tools/tests/16-journal-adr.sh` — Expected: `MỌI CA ĐẠT`; nếu ca `16` so số cột cũ thì sửa ca đó trong cùng commit).

- [ ] **Step 6: Commit** — `git add` theo đường dẫn, message: `journal: thêm cột version cho mọi nguồn ghi nhật ký`.

---

### Task 2: `export` và `report` đọc cả cột cũ lẫn mới

**Files:**
- Modify: `tools/journal.sh` (phần `export`, `report`: bảng `cot[]`, vòng tách file)
- Modify: `tools/tests/27-journal-retro.sh`

**Interfaces:**
- Consumes: Task 1 (cột version cuối).
- Produces: `report` nhận `--version <v>` đứng trước danh sách file (bỏ qua dòng có version khác; `?` chỉ khớp `?`). `export` thêm hai nguồn `phases jobs` (file có thể chưa tồn tại → bỏ qua, như bốn nguồn hiện có).

- [ ] **Step 1: Viết ca test thất bại**
  - Export cũ (không cột version, lấy từ fixture `16` bằng cách cắt cột cuối) và export mới trộn trong một `report` → số lần chạy `plan` bằng tổng hai file, không dòng nào bị đếm `bỏ`.
  - `report --version 2026.10.31 <file>` → chỉ tính dòng có version đó.
  - `export` có dòng `phases` / `jobs` khi hai file đó tồn tại.

- [ ] **Step 2: Chạy, thấy FAIL.**

- [ ] **Step 3: Sửa `cot[]`** — mỗi nguồn chấp nhận `cot` và `cot+1`; dòng khớp `cot` (cũ) được ghi ra file tạm với cột version `?` để phần còn lại không phải biết. Thêm `--version` vào bước lọc trước khi tổng hợp.

- [ ] **Step 4: Chạy lại test** — Expected: ĐẠT; `sh tools/tests/16-journal-adr.sh` vẫn ĐẠT.

- [ ] **Step 5: Commit** — `journal: report đọc được export cũ lẫn mới, thêm --version`.

---

### Task 3: `phases.tsv` — mốc bắt đầu phase

**Files:**
- Modify: `bin/aw-engine` (nhánh `rules)`, dòng ~116)
- Modify: `tools/journal.sh` (thêm `_phase` vào khối nội bộ)
- Modify: `tools/tests/27-journal-retro.sh`

**Interfaces:**
- Consumes: `tools/feature.sh` — thành công (mã 0, stdout là thư mục việc) khi ở worktree có branch khớp `branch_patterns`; mã khác = không suy ra việc.
- Produces: `journal.sh _phase <phase>` ghi `<thời điểm>\t<việc>\t<phase>\t<version>` vào `phases.tsv`, hoặc không ghi gì. Luôn thoát 0.

- [ ] **Step 1: Viết ca test thất bại**
  - `aw-engine rules spec` trong worktree việc → đúng một dòng `phases.tsv`, cột phase = `spec`.
  - Cùng lệnh ở checkout chính → không tạo `phases.tsv`.
  - `AW_JOURNAL=0 aw-engine rules spec` → không ghi.
  - `aw-engine rules spec` trả cùng mã thoát và cùng stdout như trước khi có thay đổi (so với `sh tools/rules.sh spec` trực tiếp).
  - `aw-engine rules khong-co` → mã 2 như cũ (không ghi dòng).

- [ ] **Step 2: Chạy, thấy FAIL.**

- [ ] **Step 3: Sửa nhánh `rules)`** — không `exec` nữa: chạy `sh "$T/rules.sh" "$@"`, giữ `_ma`, gọi `_phase` khi `_ma` là 0 và `AW_JOURNAL` không phải 0, rồi `exit "$_ma"`. Ở `_phase`, gọi `sh "$T/feature.sh"` trong `AW_REPO` (không truyền tham số) — thoát 0 mới lấy `basename` của stdout làm việc. Mọi lỗi trong `_phase` bị nuốt (`2>/dev/null || true`, dùng `if`, không `[ ] && …` cuối khối — xem AGENTS.md về `set -e`).

- [ ] **Step 4: Chạy lại test** — Expected: ĐẠT. `sh tools/tests/12-perf-guard-chore.sh` và `sh tools/tests/14-ship-ready.sh` vẫn ĐẠT (chúng gọi `rules` gián tiếp).

- [ ] **Step 5: Commit** — `journal: ghi mốc bắt đầu phase vào phases.tsv khi aw rules chạy trong việc`.

---

### Task 4: `aw journal retro`

**Files:**
- Create: `tools/journal-retro.sh`
- Modify: `tools/journal.sh` (dispatch `retro)` sang `journal-retro.sh`, cập nhật dòng `Dùng:` và phần đầu file)
- Modify: `tools/tests/27-journal-retro.sh`

**Interfaces:**
- Consumes: `kc_loai` và `intake_base_dong` (tools/lib/cross-check.sh, md.sh); dòng `- **Engine:**` trong `intake.md` (version đã ghim); `checks.tsv`, `phases.tsv`, `approvals.tsv`; `git diff --shortstat <merge-base>...HEAD` trong `AW_REPO` với mục tiêu bỏ `docs/sdlc/` và `.agent-workflow/`.
- Produces: không cờ → in phần máy (một dòng `khoá: giá trị` mỗi mục trong § 2.3 của spec) và danh sách lần chặn đánh số `#n` (chỉ dòng `mã ≠ 0` trong `checks.tsv` của việc). Có cờ `--nham <n,…> --phut <n> --vuong "<text>" [--gay-boi <việc|PR> --lop <layer>]` hoặc `--bo-qua` → thay dòng việc trong `jobs.tsv` (cột đúng thứ tự spec § 2.3, tab-separated, `bay` cho chuỗi tự do).

- [ ] **Step 1: Viết ca test thất bại** (fixture: `tao_fixture feature`, chạy `aw-engine check` vài lần để có `checks.tsv`)
  - `retro <F>` không cờ → stdout có `#1`, không tạo `jobs.tsv`.
  - `retro <F> --bo-qua` → `jobs.tsv` có đúng một dòng, cột `nhầm`, `phút`, `vướng`, `gây bởi`, `lọt lớp` = `-`.
  - Chạy `retro <F> --nham 1 --phut 40` rồi `retro <F> --nham 1 --phut 55` → vẫn một dòng, phút = 55.
  - `--nham 9` (không có lần chặn số 9) → `SAI THAM SỐ`, không ghi.
  - `--phut abc` → `SAI THAM SỐ`.
  - `--lop mood` → `SAI THAM SỐ`.
  - `--gay-boi` với việc không phải `bugfix` → `SAI THAM SỐ`.
  - `--bo-qua` cùng `--phut` → `SAI THAM SỐ`.
  - `retro` ở checkout chính → mã và thông báo rõ, không ghi.
  - `retro` trên thư mục không có `intake.md` → `SAI THAM SỐ`.

- [ ] **Step 2: Chạy, thấy FAIL.**

- [ ] **Step 3: Viết `journal-retro.sh`** theo spec § 3: parse cờ bằng `while [ $# -gt 0 ]; case`, kiểm tham số trước khi đọc dữ liệu, `kq_khai` với các nhãn `XONG` và `SAI THAM SỐ`. Tính giây = thời điểm `retro` − mốc bắt đầu (dòng đầu của `phases.tsv` hoặc, không có, dòng đầu của `checks.tsv` cho việc). Ghi `jobs.tsv` bằng mẫu "lọc dòng của việc cũ rồi nối dòng mới vào file tạm rồi `mv`" — giống `findings.tsv` trong `journal.sh`, dùng `if`, không `&&` cuối khối.

- [ ] **Step 4: Chạy lại test** — Expected: ĐẠT.

- [ ] **Step 5: Commit** — `journal: thêm aw journal retro — tổng kết cuối việc vào jobs.tsv`.

---

### Task 5: Mục report mới

**Files:**
- Modify: `tools/journal.sh` (phần `report`, sau mục hiện có)
- Modify: `tools/tests/27-journal-retro.sh`

**Interfaces:**
- Consumes: `jobs.tsv` (Task 4), `phases.tsv` (Task 3), `checks.tsv`.
- Produces: bốn mục in sau phần `Finding của review`: độ chính xác checker, thời gian phase trung vị, việc theo loại (+ trung vị file/dòng/phút), lỗi lọt theo lớp. Thiếu dữ liệu → `  (chưa có — …)`.

- [ ] **Step 1: Viết ca test thất bại** — trên fixture dữ liệu cố định (viết trực tiếp `jobs.tsv`, `phases.tsv`, `checks.tsv` vào `$JD`, không dựa vào chạy thật):
  - 4 lần chặn `spec`, 1 bị đánh nhầm (`nhầm = 2`) trên một việc → độ chính xác `spec` = `3/4` (in `75%`).
  - Lần chặn của việc `--bo-qua` không được tính; báo số bị loại.
  - Phase `spec` ở `t=0`, `plan` ở `t=60`, `retro` ở `t=180` → trung vị `spec` = 60 giây, trung vị `plan` = 120 giây; ghi chú "gồm thời gian chờ người".
  - `--version 2026.10.31` lọc đúng.
  - Không có `jobs.tsv` → mỗi mục in `(chưa có — …)`, không lỗi.

- [ ] **Step 2: Chạy, thấy FAIL.**

- [ ] **Step 3: Viết các mục report** bằng awk, cùng khuôn `top` / `uniq -c` như mục hiện có. Trung vị: sort số rồi lấy giữa, awk không có hàm sẵn — viết hàm `trung_vi` trong awk qua một `END` block.

- [ ] **Step 4: Chạy lại test** — Expected: ĐẠT; `sh tools/tests/16-journal-adr.sh` vẫn ĐẠT.

- [ ] **Step 5: Commit** — `journal: report thêm độ chính xác checker, thời gian phase, việc theo loại, lỗi lọt`.

---

### Task 6: Bước retro trong phase review và tài liệu

**Files:**
- Modify: `workflow/phases/05-review.md` (một bước cuối, tiếng Anh)
- Modify: `docs/huong-dan.md`, `docs/kien-truc.md`, `docs/thuat-ngu.md`
- Modify: `docs/superpowers/2026-10-22-roadmap-cai-thien.md` (dòng SP9: vẫn "một phần"; cập nhật phần "Đang làm" thành "công cụ xong ở SP9b, còn chạy thật")
- Modify: `changes/claude-sleepy-tesla-k2c0xj.md`

**Interfaces:**
- Consumes: `aw journal retro` (Task 4) và các mục report (Task 5).
- Produces: một bước trong `05-review.md` — sau khi người xác nhận kết luận, chạy `aw journal retro <dir>`, đưa danh sách chặn cho người, ghi câu trả lời bằng cờ; người không trả lời → `--bo-qua`.

- [ ] **Step 1: Kiểm test hiện có không đổi** — `sh tools/tests/` (phần liên quan review: `05`, `06`, `14`) chạy trước sửa để có đường cơ sở.

- [ ] **Step 2: Sửa `05-review.md`** — thêm bước; không thêm chữ ở adapter. Nếu một ca trong `05`/`06` grep đúng một câu của file này, sửa ca đó trong cùng commit.

- [ ] **Step 3: Cập nhật docs** — `huong-dan.md`: cách chạy đợt đo và `retro`; `kien-truc.md`: mục nhật ký (bốn → sáu nguồn, cột version, thời gian phase là xấp xỉ gồm thời gian chờ) và điểm yếu liên quan; `thuat-ngu.md`: thêm `retro` (kiểm bằng ca test `13` nếu thuật ngữ được so với `terms.md`).

- [ ] **Step 4: Sửa `changes/claude-sleepy-tesla-k2c0xj.md`** — tách thành `### Thêm` (retro, report mới, `phases.tsv`), `### Thay đổi` (cột version; `report` đọc export cũ; `rules` nay chạy qua wrapper và ghi `phases.tsv`), `### Nội bộ` (tách `journal-retro.sh`, phần test). Viết tiếng Việt.

- [ ] **Step 5: Chạy đầy đủ**
  - `sh tools/run-tests.sh` → `MỌI CA ĐẠT`; thời gian từng phần không có `CẢNH BÁO … nên tách` (nếu `27` hoặc `16` bị cảnh báo → tách tại ranh giới fixture trong cùng commit).
  - `sh tools/check-sdlc.sh` → ĐẠT (không đổi interface).
  - `sh tools/check-release.sh` → ĐẠT.

- [ ] **Step 6: Commit** — `journal: bước retro trong review, tài liệu và fragment changelog`.

---

## Thứ tự và phụ thuộc

Task 1 → 2 (cột version cần có trước khi đọc). Task 3 độc lập với 2. Task 4 cần Task 3 (mốc phase). Task 5 cần Task 3 và 4. Task 6 cần Task 4 và 5. Thực hiện tuần tự.

## Self-Review

- **Spec coverage:** § 2.1 → Task 1; § 2.2 → Task 3; § 2.3 và § 3 → Task 4; § 4 → Tasks 2 và 5; § 5 → ràng buộc chung + ca ở Task 1, 3, 4; § 7 → test trong mỗi task; § 8 (file đổi) → Task 6 và file structure (kèm sai khác `journal-retro.sh`).
- **Type consistency:** `jobs.tsv` cột theo đúng thứ tự spec § 2.3 (15 cột: thời điểm, việc, version, loại, phase, design, file, dòng, trượt, tick, giây, nhầm, phút, vướng, gây bởi, lọt lớp — kiểm lại khi viết Task 4; spec liệt kê 16 hàng, nhớ đếm đủ). Cột version cuối ở mọi nguồn (Task 1) khớp `cot+1` (Task 2).
- **Review Focus:** mỗi dòng có ca test: 1 → Task 4; 2 → Task 4; 3 → Task 5; 4 → Task 2; 5 → Task 3.
- **Tỉ lệ:** plan ngắn hơn spec, không chứa thân hàm; các bước code mô tả hướng, không dán code.

## Execution Handoff

Plan đã lưu tại `docs/superpowers/plans/2026-10-24-sp9b-journal-do-luong.md`. Các task dùng chung `tools/journal.sh` và tuần tự, nên mình đề xuất **Native** (một phiên làm lần lượt, cuối cùng một reviewer độc lập duyệt toàn nhánh). Subagent-driven sẽ tốn thêm một ngữ cảnh mới cho mỗi task mà không giảm rủi ro nhiều, vì rủi ro chính nằm ở `journal.sh` và đã được test từng bước.

Bạn xem plan và cho biết:
1. Plan đã đúng ý chưa.
2. Chọn cách thực thi nào: **Native** (khuyên dùng) hay **Subagent-driven**.

Lưu ý nhỏ: commit message sẽ không ghi tên model, theo quy tắc của phiên. Dòng `Co-Authored-By` nêu model cũng không đưa vào.
