# SP20 — File tiến độ của việc · Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ghi mốc bắt đầu phase, lượt và token (hook Claude Code), rồi sinh `progress.md` (bảng + Gantt + pie
Mermaid), `aw status`, mục `## Progress` trong mô tả MR, và hai nguồn mới cho `aw journal export/report`.

**Architecture:** Mọi ghi nhật ký nằm ở `tools/journal.sh` (`_phase`, `_turn`). Mọi phép tính tiến độ nằm ở
một thư viện `tools/lib/progress.sh`: gom **sự kiện chuẩn hoá** của một việc (máy này từ journal + máy khác
từ khối `aw-progress` của `progress.md`) → một awk tính số liệu từng phase → các hàm in (terminal, bảng MD,
file đầy đủ). `tools/status.sh` là lệnh mỏng trên thư viện; `bin/aw-engine` (check ĐẠT) và `tools/ship.sh`
gọi `status.sh`.

**Tech Stack:** POSIX sh + awk (mawk-safe: ERE không `{n}`) + sed + git. Không jq/Node/Python.

**Spec:** `docs/superpowers/specs/2026-10-23-sp20-tien-do-phase-design.md`

## Global Constraints

- POSIX sh, không bashism; awk nhiều file dùng `FILENAME == ARGV[i]`, không `FNR==1` (`AGENTS.md` § Code).
- Hàm/biến shell: tiếng Việt không dấu (tiền tố thư viện mới: `td_`); file, cột TSV, khoá: tiếng Anh.
- `progress.md`, mục `## Progress`: heading, tên cột, enum tiếng Anh (`✓ done`, `▶ active`, `— skipped`,
  `· pending`); câu giải thích tiếng Việt. Output terminal `aw status`: tiếng Việt.
- Mỗi script mới khai nhãn bằng `kq_khai`; `status.sh`: `0=XONG …`, `2=SAI THAM SỐ …`.
- Hook `_turn` và `_phase`: **không in gì ra stdout, luôn thoát 0**, mọi lỗi im lặng.
- `AW_JOURNAL=0` → không ghi `phases.tsv`, `turns.tsv`, và `aw check` không sinh `progress.md`.
- Tên máy: `bay "${AW_JOURNAL_MACHINE:-$(uname -n)}"` (như `export` hiện có) — đưa thành hàm dùng chung.
- Không thêm luật chặn/cảnh báo nào ⇒ không `# giữ:`; `sh tools/check-sdlc.sh` vẫn ĐẠT.
- Chữ sinh trong lệnh phase phải giống hệt nhau giữa adapter (`AW_COMPARE=1`).
- Thời gian UTC ISO `YYYY-MM-DDTHH:MM:SSZ` trong TSV (như `checks.tsv`); epoch chỉ tính trong awk.

## Định dạng dữ liệu (chốt cho mọi task)

`$AW_CONFIG/journal/phases.tsv`: `ts  worktree  feature  phase`

`$AW_CONFIG/journal/turns.tsv`:
`ts_begin  ts_end  worktree  feature  phase  session  kind  seconds  in  out  cache_read  cache_write`
(`kind` = `main|subagent`; ô không biết = rỗng; không gắn được = `-`).

`$AW_CONFIG/journal/.turn/<session>`: một dòng `ts_begin_iso<TAB>ts_begin_epoch<TAB>offset` (offset = số byte transcript đã đọc; hai cột đầu rỗng sau `end`).

**Sự kiện chuẩn hoá** (một việc; cũng là dòng trong khối `aw-progress v1`; tab giữa cột):

```
phases  <machine>  <ts>  <phase>
turns   <machine>  <ts_begin>  <ts_end>  <phase>  <kind>  <seconds>  <in>  <out>  <cache_read>  <cache_write>
checks  <machine>  <ts>  <checker>  <exit>
```

Không có đường dẫn, session hay chữ người viết ⇒ không thể chứa `-->`. `<machine>` qua `bay` rồi xoá `<>`.
Khối giữ sự kiện thô (không phải tổng) để máy khác dựng lại được trạng thái và Gantt — spec § 5 đã ghi vậy.

**Số liệu từng phase** (output của `td_tinh`, mỗi phase một dòng, theo thứ tự `wf_phases`):

```
P  <phase>  <status>  <active_s>  <wall_s>  <turns>  <blocked>  <in>  <out>  <cache_read>  <cache_write>
R  <phase>  <start_epoch>  <end_epoch>  <done|active>         # mỗi lần chạy (Gantt)
B  <phase>  <epoch>                                           # mỗi check chặn (milestone)
M  <current_phase>  <last_event_iso>  <machines, phẩy-cách>  <has_starts 0|1>  <has_main_turns 0|1>
```

`<status>` ∈ `done active skipped pending`. Ô số không có dữ liệu = rỗng (in ra `—`).

## Review Focus

- **Payload hook không phải của Claude Code** (Cursor chạy cả `.claude/settings.json`): không
  `transcript_path` → không ghi, stdout rỗng — ca ở task 2.
- **Transcript lặp `message.id`** qua nhiều dòng (streaming tách khối nội dung): đếm một lần — ca ở task 2.
- **Transcript bị cắt/xoay** (file mới ngắn hơn offset cũ, vd `/clear` cùng session): đọc lại từ đầu thay
  vì im lặng bỏ lượt — ca ở task 2.
- **`progress.md` có khối của máy khác, máy này chưa có journal**: không xoá dữ liệu máy kia, tổng vẫn đúng
  — ca ở task 4.
- **Việc bắt đầu trước SP20** (có `checks.tsv`, không `phases.tsv`): không vỡ, phase ĐẠT hiện `✓ done`,
  không dòng nhắc hook — ca ở task 3.

---

### Task 1: Mốc bắt đầu phase (`aw feature --phase`)

**Files:**
- Modify: `tools/journal.sh` (nhánh nội bộ `_phase`, hàm `may_nay`)
- Modify: `tools/feature.sh` (đọc `--phase <id>`)
- Modify: `adapters/lib/common.sh` (`buoc_xac_dinh_feature` tham số 4 = phase id; `sinh_command` truyền `$id`)
- Create: `tools/tests/26-progress.sh` (phần mới; dựng repo như `09-worktree-input.sh` § aw feature)
- Modify: `tools/tests/08-adapters.sh`

**Interfaces:**
- Produces: `journal.sh _phase <worktree> <feature> <phase>` → một dòng `phases.tsv`, im lặng, thoát 0.
- Produces: `may_nay` (trong `journal.sh`, cũng định nghĩa lại ở `tools/lib/progress.sh` task 3 — một bản:
  task 3 chuyển nó sang thư viện và `journal.sh` nạp thư viện) → tên máy đã làm sạch.
- Produces: `aw feature [tên] --phase <id>`; `<id>` phải nằm trong `wf_phases "${AW_ENGINE:-$HERE/..}/workflow.yaml"`.

- [ ] **Step 1: Viết ca thất bại trong `26-progress.sh`** (nhóm `aw feature --phase`): trong worktree của
  fixture `09`-kiểu, `awd "$WT" feature --phase spec` → mã 0 và `phases.tsv` có đúng 1 dòng, cột 4 = `spec`,
  cột 3 = tên việc; `--phase khong-co` → mã 2, không thêm dòng; checkout chính `--phase spec` → mã 6, không
  thêm dòng; không `--phase` → mã 0, không thêm dòng; `AW_JOURNAL=0 … --phase spec` → không thêm dòng;
  `feature feat_x --phase plan` (tham số trước cờ) vẫn nhận `feat_x`.
- [ ] **Step 2:** `sh tools/tests/26-progress.sh` → các ca trên FAIL.
- [ ] **Step 3: Cài.** `feature.sh`: vòng `while` đầu file tách `--phase <id>` ra khỏi tham số vị trí
  (thiếu giá trị → mã 2). Kiểm id trước bước checkout chính. Ngay trước `echo "$TM"`:
  `[ -z "$PH" ] || sh "$HERE/journal.sh" _phase "$MT_REPO" "$(basename "$TM")" "$PH" >/dev/null 2>&1`
  (dùng `if`, không `&&` cuối khối). `journal.sh _phase`: thoát 0 khi `AW_JOURNAL=0`; ghi
  `gio`, worktree, feature, phase.
- [ ] **Step 4: Adapter — ca thất bại** trong `08-adapters.sh`: `aw-spec.md` sinh ra chứa
  `aw feature $ARGUMENTS --phase spec`; `aw-intake.md` chứa `aw feature --phase intake`; lệnh tiện ích
  `aw-clarify.md` **không** chứa `--phase`. Chạy → FAIL.
- [ ] **Step 5: Cài** `buoc_xac_dinh_feature <ts> [input] [cmc] [phase]`: có `$4` thì nối ` --phase $4`
  vào cả hai câu `Run \`aw feature …\``; `sinh_command` gọi với `"$id"`; hai chỗ gọi của lệnh tiện ích giữ nguyên.
- [ ] **Step 6:** `sh tools/run-tests.sh 26-progress 08-adapters 09-worktree-input` → `MỌI CA ĐẠT`
  (gồm ca `AW_COMPARE=1`).
- [ ] **Step 7: Commit** `feat(journal): ghi mốc bắt đầu phase qua aw feature --phase`.

### Task 2: Lượt và token — `aw journal _turn begin|end|sub`

**Files:**
- Modify: `tools/journal.sh`
- Create: `tools/tests/fixtures/transcript-claude.jsonl` (5–6 dòng: 1 `user`, 3 `assistant` trong đó 2 dòng
  cùng `message.id`, 1 dòng `system`)
- Modify: `tools/tests/26-progress.sh`
- Modify: `adapters/claude-code/README.md` § Hook (ba hook, JSON mẫu như khối `aw guard`), `adapters/cursor/README.md`
  (một dòng: không đo token, chỉ Wall)

**Interfaces:**
- Consumes: `phases.tsv` (task 1).
- Produces: `journal.sh _turn <begin|end|sub>` đọc payload ở stdin → dòng `turns.tsv` (định dạng ở đầu plan).

- [ ] **Step 1: Ca thất bại** (nhóm `aw journal _turn`), payload dựng bằng `printf` với `session_id`,
  `transcript_path` (copy fixture vào `$TMP`), `cwd` = worktree đã `--phase plan`:
  - `begin` rồi `end` → 1 dòng, `kind=main`, `phase=plan`, `in/out/cache_read/cache_write` = tổng tay của
    fixture với dòng trùng `message.id` tính **một** lần, `seconds` là số ≥ 0;
  - cả hai lệnh: stdout rỗng (`bang "$(… _turn begin < p)" ""`), mã 0;
  - nối thêm 1 dòng `assistant` mới vào transcript, `begin`+`end` lần hai → dòng thứ hai chỉ có token dòng mới;
  - transcript bị thay bằng file ngắn hơn offset → `end` đọc lại từ đầu (token = toàn file mới);
  - `end` không có `begin` trước → `seconds` rỗng, token vẫn có;
  - `sub` với `agent_transcript_path` → `kind=subagent`, `seconds=0`;
  - payload không `transcript_path` / JSON hỏng / transcript không tồn tại → mã 0, stdout rỗng, không thêm dòng;
  - `cwd` ở worktree chưa có `phases.tsv` → `feature` và `phase` = `-`;
  - `AW_JOURNAL=0` → không ghi.
- [ ] **Step 2:** chạy phần → FAIL.
- [ ] **Step 3: Cài.** Toàn nhánh `_turn` bọc `{ …; } >/dev/null 2>&1; exit 0`. Lấy trường bằng
  `sed -n 's/.*"<key>"[ ]*:[ ]*"\([^"]*\)".*/\1/p'`. Worktree = `git -C "$cwd" rev-parse --show-toplevel`;
  phase/feature = dòng cuối của `awk -F'\t' -v w="$wt" '$2 == w'` trên `phases.tsv`. Offset: kích thước
  file `wc -c`; nếu `< offset` thì offset = 0; đọc `tail -c +$((offset + 1))`. Cộng token:

  ```awk
  /"type"[ ]*:[ ]*"assistant"/ {
    id = trich("\"id\"[ ]*:[ ]*\"msg_[^\"]*\"")
    if (id != "" && (id in thay)) next; thay[id] = 1
    vao += so("input_tokens"); ra += so("output_tokens")
    cd += so("cache_read_input_tokens"); cg += so("cache_creation_input_tokens"); co = 1
  }
  END { if (co) print vao "\t" ra "\t" cd "\t" cg; else print "\t\t\t" }
  ```

  (`so(k)` = số sau `"k":`, 0 nếu thiếu). Khử trùng `message.id` chỉ trong phần mới đọc: một message không
  vắt qua hai lượt nên không cần nhớ id giữa các lượt.
  `seconds` = hiệu epoch hai mốc (`date -u +%s` lúc `begin` lưu kèm; ghi `ts_begin` ISO + epoch vào
  `.turn/<session>` dạng `iso<TAB>epoch<TAB>offset`). Xoá `begin` sau `end` (giữ offset).
- [ ] **Step 4:** chạy phần → `MỌI CA ĐẠT`.
- [ ] **Step 5: README** hai adapter như trên; ca `08-adapters` hiện có không grep chữ này (kiểm lại).
- [ ] **Step 6: Commit** `feat(journal): ghi lượt và token từ hook Claude Code`.

### Task 3: Tính tiến độ + `aw status` (terminal, dòng nhắc hook)

**Files:**
- Create: `tools/lib/progress.sh`
- Create: `tools/status.sh`
- Modify: `bin/aw-engine` (`status) can_repo; exec sh "$T/status.sh" "$@" ;;` + dòng usage đầu file),
  `bin/aw` (usage), `tools/journal.sh` (dùng `may_nay` từ thư viện)
- Modify: `tools/tests/26-progress.sh`

**Interfaces:**
- Consumes: `phases.tsv`, `turns.tsv`, `checks.tsv`; `wf_phases`; `kc_bo_design` (`tools/lib/cross-check.sh`).
- Produces (thư viện, nạp sau `md.sh`, `cross-check.sh`):
  - `may_nay` → tên máy.
  - `td_su_kien <feature-dir>` → stdout: sự kiện chuẩn hoá của việc (`feature` = `basename`): dòng máy này từ
    journal + dòng máy khác từ khối `aw-progress v1` của `<dir>/progress.md` (bỏ dòng của máy này trong khối).
    Khối sai dạng (dòng không khớp số cột theo `source`) → bỏ cả khối, `TD_CANH_BAO=1`.
  - `td_tinh <feature-dir>` → stdin không dùng; stdout dòng `P/R/B/M` (định dạng ở đầu plan).
  - `td_tg <giây>` → `2h10m` | `25m` | `40s` | rỗng → `—`. `td_tk <số>` → `<1000` nguyên; `<1e6`
    `round(n/1000)k`; còn lại `%.1fM`; rỗng → `—`.
- Produces: `aw status <feature-dir>` (terminal), nhãn `0=XONG — đã in tiến độ (--write: đã ghi progress.md)`,
  `2=SAI THAM SỐ`.

- [ ] **Step 1: Ca thất bại.** Dựng `phases.tsv`/`turns.tsv`/`checks.tsv` tay (giờ cố định) cho việc fixture:
  intake bắt đầu → ĐẠT; spec bắt đầu → 2 check mã 1 → ĐẠT; việc `chore` để design bỏ qua (hoặc `Design: skip`);
  plan bắt đầu, có lượt, chưa check. Kỳ vọng `td_tinh`:
  `P intake done`, `P spec done … blocked=2`, `P design skipped`, `P plan active`, `P implement pending`;
  `wall_s` spec = hiệu (plan_start − spec_start); `active_s` = tổng `seconds` lượt main; token cộng cả subagent;
  2 dòng `B spec`; `M plan <ts cuối> <máy> 1 1`.
  `aw status` in `ĐẠT`, `đang làm`, `bỏ qua` và `Phase hiện tại: plan`.
  Thêm: không journal → mọi ô `—`, mã 0; chỉ `checks.tsv` (việc cũ) → intake `done`, wall `—`, **không** nhắc
  hook; có `phases.tsv`, không lượt main → `aw status` có dòng `· Chưa ghi được lượt nào`; có 1 lượt main token
  rỗng → không nhắc; `td_tg 7800` = `2h10m`, `td_tk 1234567` = `1.2M`, `td_tk 82400` = `82k`.
- [ ] **Step 2:** chạy → FAIL.
- [ ] **Step 3: Cài `td_tinh`** — một awk đọc ba nguồn qua `ARGV`: danh sách phase (`wf_phases`), cờ
  bỏ-design, sự kiện. Epoch từ ISO trong awk:

  ```awk
  function ep(s,  y,m,d) { y = substr(s,1,4)+0; m = substr(s,6,2)+0; d = substr(s,9,2)+0
    if (m <= 2) { y--; m += 12 }
    return ((365*y + int(y/4) - int(y/100) + int(y/400) + int((153*(m-3)+2)/5) + d - 719469) * 86400 \
            + substr(s,12,2)*3600 + substr(s,15,2)*60 + substr(s,18,2)) }
  ```

  Lần chạy: sắp mọi `phases` theo ts; lần i kết thúc ở lần i+1, lần cuối ở sự kiện cuối của việc. Lượt gắn
  phase theo cột `phase` của nó. Chặn = `checks` của checker phase đó, `exit != 0`, nằm trong một lần chạy
  của phase đó. `done` = có `checks` mã 0 sau lần bắt đầu cuối (không có lần bắt đầu nào → có mã 0 bất kỳ).
  `active` = phase của lần bắt đầu cuối, chưa `done`. `skipped` = design + `kc_bo_design`.
- [ ] **Step 4: Cài `status.sh`** (in terminal, tiếng Việt) + đăng ký `aw status`; `journal.sh` nạp
  `lib/progress.sh` để lấy `may_nay`.
- [ ] **Step 5:** `sh tools/run-tests.sh 26-progress 16-journal-adr` → `MỌI CA ĐẠT`.
- [ ] **Step 6: Commit** `feat(status): aw status — tiến độ từng phase từ nhật ký`.

### Task 4: `progress.md` (`--write`, Mermaid, khối nhiều máy) + ghi khi `aw check` ĐẠT

**Files:**
- Modify: `tools/lib/progress.sh` (`td_md_bang`, `td_md_file`), `tools/status.sh` (`--write`, `--table`)
- Modify: `bin/aw-engine` (nhánh `check`, trước `ar_commit`)
- Modify: `tools/tests/26-progress.sh`
- Modify: `docs/huong-dan.md` (mục xem tiến độ + cài hook).

**Interfaces:**
- Consumes: `td_su_kien`, `td_tinh`, `td_tg`, `td_tk`, `may_nay` (task 3).
- Produces: `td_md_bang <feature-dir>` → bảng Markdown (header + dòng phase + `**Total**`), rỗng nếu mọi ô
  rỗng và không phase nào khác `pending`/`skipped`. `aw status <dir> --table` in đúng nó (task 5 dùng).
  `aw status <dir> --write` ghi `<dir>/progress.md` = `td_md_file`.

- [ ] **Step 1: Ca thất bại** (cùng dữ liệu task 3):
  - `--write` → file có `# Progress — <feature>`, `- Current phase: **plan**`, dòng bảng
    `| spec | ✓ done |`, `| design | — skipped |`, `| plan | ▶ active |`, `| **Total** |`;
    khối ` ```mermaid` + `gantt` + `dateFormat X` + đúng 2 dòng `:milestone, crit,`; khối `pie` có 3 dòng
    `"…" :` (intake, spec, plan); khối `<!-- aw-progress v1` … `-->` có dòng `phases\t<máy>\t`;
  - `--write` hai lần → `cmp` hai bản giống nhau từng byte;
  - không token nào → không có `pie`; không lượt main → có `> Chưa ghi được lượt nào` ngay dưới bảng;
  - thêm vào khối dòng `turns\tmay-khac\t…` (in=1000) rồi `--write` → giữ dòng đó, Total `Tokens in` tăng 1000;
    máy này rỗng journal → dòng `may-khac` vẫn còn;
  - khối có dòng sai số cột → stderr có `CẢNH BÁO`, file sinh lại chỉ từ journal máy này;
  - `--table` → chỉ bảng, không `mermaid`, không `<!--`; không dữ liệu → stdout rỗng;
  - `sh "$AWE" check plan "$F"` ĐẠT → `git show --stat HEAD` có `progress.md`; `status.sh` bị làm hỏng
    (biến `AW_TD_HONG=1` chỉ test dùng, hoặc `progress.md` là thư mục) → check vẫn mã 0, stderr có `CẢNH BÁO`;
    `AW_JOURNAL=0` → không sinh file.
- [ ] **Step 2:** chạy → FAIL.
- [ ] **Step 3: Cài `td_md_file`** theo mẫu spec § 5 (đã đổi sang tiếng Anh). Gantt: mỗi `R` một dòng
  `  <phase> :<done|active>, <start>, <end>` dưới `section <phase>`; mỗi `B` một dòng
  `  blocked :milestone, crit, <epoch>, <epoch>`. Pie: `"<phase>" : <(in+out)/1000, %.1f>` cho phase có
  in+out > 0. `Updated` = `M` ts cuối dạng `YYYY-MM-DD HH:MM UTC`; không sự kiện → dòng `- Updated: —`.
  Khối cuối file: `td_su_kien` (đã gồm máy khác), sắp `sort` để tất định.
- [ ] **Step 4: Cài trong `bin/aw-engine`** ngay trước `AR_DA_COMMIT=""`: nếu `AW_JOURNAL` ≠ 0 thì
  `sh "$T/status.sh" "$1" --write >/dev/null 2>&1 || echo "CẢNH BÁO: không sinh được $1/progress.md — chạy aw status $1 --write để xem lỗi." >&2`.
- [ ] **Step 5:** `sh tools/run-tests.sh` (cả bộ: `progress.md` giờ xuất hiện trong mọi thư mục việc fixture
  sau check ĐẠT). Ca nào hỏng vì liệt kê file của thư mục việc/commit → sửa ca đó, không sửa engine, trừ khi
  checker thật sự coi `progress.md` là file lạ (khi đó thêm `progress.md` vào danh sách artifact máy sinh của
  checker đó và ghi vào commit message). → `MỌI CA ĐẠT`.
- [ ] **Step 6:** Viết mục `docs/huong-dan.md` như mục Files.
- [ ] **Step 7: Commit** `feat(status): progress.md với Gantt, pie và khối nhiều máy; ghi khi aw check ĐẠT`.

### Task 5: Mục `## Progress` trong mô tả MR

**Files:**
- Modify: `tools/ship.sh` (sau khi tạo `$MO`, dòng ~228)
- Modify: `tools/tests/14-ship-ready.sh` (nhóm `aw ship …`)

**Interfaces:**
- Consumes: `aw status <dir> --table` (task 4).

- [ ] **Step 1: Ca thất bại:** với journal có dữ liệu cho việc `$FS`, đường "mô tả để sẵn ở
  mr-description.md" (ca dòng 68 hiện có) → file kết thúc bằng `## Progress` + `| Phase | Status |`, không có
  `mermaid`; journal rỗng → không có `## Progress`; `status.sh` lỗi → MR vẫn tạo (mã như cũ) + `CẢNH BÁO`;
  đường "MR đang mở — đã push" (mã 5) → không tạo `mr-description.md`.
- [ ] **Step 2:** `sh tools/run-tests.sh 14-ship-ready` → FAIL.
- [ ] **Step 3: Cài:** `bang=$(sh "$HERE/status.sh" "$DIR" --table 2>/dev/null) || echo "CẢNH BÁO: …" >&2`;
  có `bang` thì `printf '\n## Progress\n\n%s\n' "$bang" >> "$MO"`. Dùng `if`.
- [ ] **Step 4:** chạy phần → `MỌI CA ĐẠT`.
- [ ] **Step 5: Commit** `feat(ship): chèn bảng tiến độ vào mô tả MR`.

### Task 6: `aw journal export` / `report` — nguồn `phases`, `turns`

**Files:**
- Modify: `tools/journal.sh` (vòng `for s in checks failures approvals findings` + phần tách lại khi report
  file export + mục report mới)
- Modify: `tools/tests/16-journal-adr.sh`

**Interfaces:**
- Consumes: `td_tinh` không dùng (report tổng hợp trên nhiều việc, tính thẳng từ `turns.tsv`/`phases.tsv`).

- [ ] **Step 1: Ca thất bại:** export có dòng `phases\tmay-a\t` và `turns\tmay-a\t`; report trên file export
  và report trực tiếp cùng in mục `Thời gian và token theo phase` với cùng số; hai file export của hai máy →
  token cộng dồn; file export cũ (không hai nguồn) → report vẫn chạy, mục mới ghi `chưa có dữ liệu`.
- [ ] **Step 2:** chạy `16-journal-adr` → FAIL.
- [ ] **Step 3: Cài:** thêm `phases turns` vào vòng export và tách; mục report: theo phase — số việc, tổng và
  trung vị `active` (tổng `seconds` lượt main mỗi việc), tổng token vào/ra.
- [ ] **Step 4:** chạy phần → `MỌI CA ĐẠT`.
- [ ] **Step 5: Commit** `feat(journal): export/report thời gian và token theo phase`.

### Task 7: Tài liệu, roadmap, kiểm cuối

**Files:**
- Modify: `docs/kien-truc.md` (mục mới "Tiến độ của việc": số liệu suy từ journal, không agent khai; token chỉ
  Claude Code; ghi lúc check ĐẠT không mỗi lượt; khối `aw-progress` cho nhiều máy; § điểm yếu: transcript không
  phải API công khai), `docs/thuat-ngu.md` (lượt, thời gian tương tác/Active, thời gian đồng hồ/Wall),
  `README.md` (dòng `aw status` trong bảng lệnh nếu có), `docs/superpowers/2026-10-22-roadmap-cai-thien.md`
  (SP20: cột Plan; SP9: "thời gian phase, token: có công cụ (SP20)"), `changes/claude-modest-hypatia-h7npnz.md`
  (đổi sang `### Thêm`: `aw status`, `progress.md`, hook token, `## Progress` trong MR — ai làm gì: cài hook
  theo `adapters/claude-code/README.md` § Hook).

- [ ] **Step 1:** Viết tài liệu như trên.
- [ ] **Step 2:** `git fetch origin && git merge origin/main`; `sh tools/run-tests.sh` → `MỌI CA ĐẠT`;
  `sh tools/check-sdlc.sh` → ĐẠT; `sh tools/check-release.sh` → ĐẠT. Không phần nào `CẢNH BÁO … nên tách`
  (nếu `26-progress` chậm → tách tại ranh giới fixture).
- [ ] **Step 3: Thủ công:** sinh `progress.md` từ dữ liệu task 4, dán vào một gist/issue nháp trên GitHub,
  xác nhận Gantt và pie vẽ được; ghi kết quả vào mô tả PR. Hỏng cú pháp → sửa `td_md_file` + ca grep tương ứng.
- [ ] **Step 4: Commit** `docs: SP20 — tiến độ của việc` và mở PR (Interface: "no interface change: đo đạc
  harness, không phải năng lực stage SDLC").
