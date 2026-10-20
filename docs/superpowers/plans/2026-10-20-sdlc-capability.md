# Capability cho interface SDLC — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mỗi stage SDLC có capability có id mô tả trạng thái đích; trạng thái stage do `check-sdlc.sh` suy ra từ `capabilities:` của phase; `AGENTS.md` buộc "interface trước"; người đọc có `docs/interface-sdlc.md`.

**Architecture:** Capability khai trong thân `sdlc/stages/*.md` (dạng giống `sdlc/invariants.md`); phase nhận bằng khoá frontmatter `capabilities:`. `tools/check-sdlc.sh` đọc cả hai, suy ra `implemented | partial | gap`, thay cho khoá `status` khai tay trong khối `sdlc:` của `workflow.yaml`, và in bảng roadmap capability còn thiếu.

**Tech Stack:** POSIX sh + awk + sed (mawk-safe: ERE không `{n}`; multi-file awk dùng `FILENAME == ARGV[i]`).

**Spec:** `docs/superpowers/specs/2026-10-20-sdlc-capability-design.md`

## Global Constraints

- Worktree: `/home/dangminhphuc/github/agent-workflow-sdlc-cap`, branch `feat/sdlc-capability`. Không sửa `main`.
- Commit: `git -c user.name="Đặng Minh Phúc" -c user.email="dangminhphuc.dev@gmail.com" commit …` (máy chưa có git identity); message kết thúc bằng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Id capability: `CAP-<stage>-NN`, heading `### CAP-<stage>-NN — <tên>` (em dash `—`), ERE `^### CAP-[a-z]+-[0-9][0-9] — .`.
- `Judged by` chỉ nhận `machine | agent | human`.
- Thân file stage + capability: tiếng Anh, ngắn, không tên file engine (`spec.md`…). Thông báo `check-sdlc.sh`, docs, `changes/`: tiếng Việt.
- YAML chỉ tập con `tools/lib/md.sh` đọc: `k: v`, `k:` + `  - item`, `k: []`.
- Shell function/biến: tiếng Việt không dấu, giống code xung quanh (`loi`, `co`, `stage_co`).
- Mọi luật mới test cả hai chiều trong `tools/tests/20-sdlc-conformance.sh` bằng `moi` + `thay`/`awk` + `vi_pham "<ca>" "<chuỗi lỗi>"`.
- Đổi chuỗi mà test grep → sửa test trong cùng commit.
- Cuối cùng `sh tools/run-tests.sh` in `MỌI CA ĐẠT`; part chậm (`CẢNH BÁO … nên tách`) → tách ở ranh giới fixture.

## Review Focus

1. Heading gõ `-` thay vì `—` (`### CAP-deploy-01 - Rollback`) → người viết kỳ vọng lỗi "sai dạng", không phải capability bị lờ đi. Test ở Task 1.
2. File stage CRLF → capability vẫn đọc được (awk `sub(/\r$/, "")` như khối invariant). Test ở Task 1.
3. `- Rule:` nằm dưới một heading khác sau capability (`## Notes`) → không được tính cho capability đó (khối kết thúc ở heading `#` kế tiếp). Test ở Task 1.
4. Hai phase cùng nhận một capability (stage `implement` có `03-plan` + `04-implement`) → ĐẠT. Test ở Task 2.
5. Người cũ còn để `status: partial` trong khối `sdlc:` → lỗi nói xoá dòng, không âm thầm bỏ qua. Test ở Task 3.

---

## File Structure

| File | Trách nhiệm | Task |
|---|---|---|
| `sdlc/stages/0*.md` (7 file) | Thêm `## Capabilities` theo spec § 4 | 1 |
| `tools/check-sdlc.sh` | Đọc + kiểm capability (1), `capabilities:` của phase (2), suy ra trạng thái + roadmap (3) | 1–3 |
| `workflow/phases/0*.md` (7 file) | Khoá `capabilities:` theo spec § 4 | 2 |
| `workflow.yaml` | Khối `sdlc:` bỏ `status` | 3 |
| `tools/tests/20-sdlc-conformance.sh` | Ca mới + sửa ca cũ về `status` | 1–3 |
| `AGENTS.md` | "Interface trước" | 4 |
| `docs/interface-sdlc.md` (mới), `docs/kien-truc.md`, `docs/thuat-ngu.md`, `docs/viec-can-lam.md`, `README.md`, `changes/feat-sdlc-capability.md` | Tài liệu cho người | 5 |

---

### Task 1: Capability trong file stage + kiểm dạng

**Files:**
- Modify: `sdlc/stages/00-plan.md` … `06-operate.md`
- Modify: `tools/check-sdlc.sh` (khối "---- stage", sau dòng `echo "$i|$id|$ex|$sk" >> "$W/stages"`; khối comment đầu file)
- Test: `tools/tests/20-sdlc-conformance.sh` (nhóm mới `check-sdlc.sh: capability trong file stage`, đặt sau nhóm "file stage")

**Interfaces:**
- Produces: file tạm `$W/cap`, mỗi dòng `stage|CAP-id|judged|tên`, theo thứ tự stage rồi thứ tự trong file. Hàm `cap_co <id>` → 0 nếu id có trong `$W/cap`; `cap_stage <id>` → in stage của id.

- [ ] **Step 1: Viết ca test (đỏ)**

Thêm nhóm, mỗi ca sửa một file stage của bản chép `$E` (dùng `thay` / `awk` như các ca hiện có):

```sh
nhom "check-sdlc.sh: capability trong file stage"
moi; awk '/^## Capabilities/ { exit } { print }' "$E/sdlc/stages/06-operate.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-operate.md"
vi_pham "stage không có capability → chặn" "stage operate: không có capability"
moi; thay "$E/sdlc/stages/05-deploy.md" '### CAP-deploy-01 — ' '### CAP-deploy-01 - '
vi_pham "heading capability gõ - thay vì — → chặn" "stage deploy: heading capability \"### CAP-deploy-01 - "
moi; thay "$E/sdlc/stages/05-deploy.md" '### CAP-deploy-01 — ' '### CAP-verify-01 — '
vi_pham "id capability mang stage khác → chặn" "stage deploy: heading capability \"### CAP-verify-01"
moi; thay "$E/sdlc/stages/05-deploy.md" '### CAP-deploy-02 — ' '### CAP-deploy-01 — '
vi_pham "id capability trùng → chặn" "stage deploy: CAP-deploy-01 trùng"
moi; awk '!(/^- Rule:/ && ++n == 1)' "$E/sdlc/stages/05-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/05-deploy.md"
vi_pham "capability thiếu Rule → chặn" "CAP-deploy-01: thiếu \"- Rule:\""
moi; awk '!(/^- Judged by:/ && ++n == 1)' "$E/sdlc/stages/05-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/05-deploy.md"
vi_pham "capability thiếu Judged by → chặn" "CAP-deploy-01: thiếu \"- Judged by:\""
moi; thay "$E/sdlc/stages/05-deploy.md" '- Judged by: human' '- Judged by: robot'
vi_pham "Judged by lạ → chặn" "Judged by \"robot\" — chỉ nhận machine | agent | human"
# Review Focus 3: Rule dưới heading khác không tính cho capability
moi; awk '!(/^- Rule:/ && ++n == 1)' "$E/sdlc/stages/05-deploy.md" > "$E/s" && printf '\n## Notes\n\n- Rule: lạc chỗ\n' >> "$E/s" && mv "$E/s" "$E/sdlc/stages/05-deploy.md"
vi_pham "Rule nằm dưới heading khác không tính → chặn" "CAP-deploy-01: thiếu \"- Rule:\""
# Review Focus 2: CRLF
moi; sed 's/$/\r/' "$E/sdlc/stages/05-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/05-deploy.md"
ky_vong 0 "file stage CRLF → vẫn ĐẠT" sh "$SC" "$E"
```

(`CAP-deploy-01` là capability đầu tiên của `05-deploy.md`, `Judged by: human` — xem spec § 4.)

- [ ] **Step 2: Chạy test, xác nhận đỏ**

Run: `sh tools/tests/20-sdlc-conformance.sh`
Expected: các ca nhóm mới HỎNG (chưa có capability, checker chưa đọc). Các nhóm cũ vẫn ĐẠT.

- [ ] **Step 3: Viết `## Capabilities` vào 7 file stage**

Đúng 23 capability, đúng id, tên, `Judged by` theo bảng spec § 4. Mỗi khối:

```markdown
### CAP-deploy-01 — Change is delivered as a reviewed MR/PR that only a human merges
- Rule: <một câu tiếng Anh, điều phải đúng, không tên file engine>
- Judged by: human
```

`## Capabilities` đứng sau các gạch đầu dòng hiện có. Ở `00-plan.md`, xoá dòng `- Out of this stage: roadmap, estimation, prioritisation …` (nay là `CAP-plan-03`/`CAP-plan-04`).

- [ ] **Step 4: Đọc + kiểm capability trong `tools/check-sdlc.sh`**

Trong vòng lặp stage, sau khi ghi `$W/stages`: một lệnh awk trên `$f` (bỏ `\r`), bỏ frontmatter, theo dõi khối hiện tại — mở ở dòng `^### CAP`, đóng ở mọi dòng `^#` khác. In bản ghi để shell gọi `loi`:
- dòng bắt đầu `### CAP` không khớp `^### CAP-[a-z]+-[0-9][0-9] — .` hoặc phần stage khác `$id` → `loi "stage $id: heading capability \"$h\" sai dạng — cần \"### CAP-$id-NN — <tên>\"."`
- id đã gặp → `loi "stage $id: $cap trùng — mỗi id chỉ khai một lần."`
- khối không có `- Rule:` → `loi "$cap: thiếu \"- Rule:\" — thêm một câu nói điều phải đúng."`
- khối không có `- Judged by:` → `loi "$cap: thiếu \"- Judged by:\" — thêm machine | agent | human."`
- giá trị lạ → `loi "$cap: Judged by \"$j\" — chỉ nhận machine | agent | human."`
- stage không có capability hợp lệ nào → `loi "stage $id: không có capability — thêm \"## Capabilities\" với ít nhất một \"### CAP-$id-NN — <tên>\"."`

Capability hợp lệ (heading đúng dạng, không trùng) ghi vào `$W/cap` dạng `stage|id|judged|tên`. Khởi tạo `: > "$W/cap"` cùng chỗ `: > "$W/stages"`. Định nghĩa `cap_co` / `cap_stage` cạnh `stage_co`. Cập nhật khối comment đầu file (mục "File stage").

- [ ] **Step 5: Chạy test, xác nhận xanh**

Run: `sh tools/tests/20-sdlc-conformance.sh && sh tools/tests/21-sdlc-profiles.sh`
Expected: mọi ca ĐẠT.

- [ ] **Step 6: Commit**

```bash
git add sdlc/stages tools/check-sdlc.sh tools/tests/20-sdlc-conformance.sh
git commit -m "Interface SDLC: capability CAP-<stage>-NN trong file stage, check-sdlc kiểm dạng"
```

---

### Task 2: Phase nhận capability

**Files:**
- Modify: `workflow/phases/00-intake.md` … `06-ship.md` (frontmatter, ngay sau `provides:`)
- Modify: `tools/check-sdlc.sh` (khối "---- phase", khối "---- utility command", comment đầu file)
- Test: `tools/tests/20-sdlc-conformance.sh` (nhóm `check-sdlc.sh: phase khai implements / provides`)

**Interfaces:**
- Consumes: `cap_co`, `cap_stage`, `$W/cap` (Task 1).
- Produces: file tạm `$W/nhan`, mỗi dòng `phase|stage|CAP-id` cho mỗi capability hợp lệ một phase nhận.

- [ ] **Step 1: Viết ca test (đỏ)**

```sh
moi; thay "$E/workflow/phases/06-ship.md" '  - CAP-deploy-01' '  - CAP-deploy-09'
vi_pham "phase nhận capability không tồn tại → chặn" "phase ship: capabilities \"CAP-deploy-09\" — không có capability đó"
moi; thay "$E/workflow/phases/06-ship.md" '  - CAP-deploy-01' '  - CAP-deploy-01
  - CAP-verify-03'
vi_pham "phase nhận capability của stage khác → chặn" "phase ship: capabilities \"CAP-verify-03\" thuộc stage verify, phase implements deploy"
# Review Focus 4
moi; thay "$E/workflow/phases/04-implement.md" 'capabilities:' 'capabilities:
  - CAP-implement-01'
ky_vong 0 "hai phase cùng nhận một capability → ĐẠT" sh "$SC" "$E"
moi; thay "$E/workflow/clarify.md" 'id: clarify' 'id: clarify
capabilities:
  - CAP-require-01'
vi_pham "utility command khai capabilities → chặn" "utility command clarify: khai capabilities"
```


- [ ] **Step 2: Chạy test, xác nhận đỏ**

Run: `sh tools/tests/20-sdlc-conformance.sh`
Expected: 4 ca mới HỎNG.

- [ ] **Step 3: Thêm `capabilities:` vào phase theo cột "Phase nhận" spec § 4**

`00-intake`: `CAP-plan-01`, `CAP-plan-02` · `01-spec`: `CAP-require-01..03` · `02-design`: `CAP-design-01..03` · `03-plan`: `CAP-implement-01` · `04-implement`: `CAP-implement-02`, `CAP-implement-03` · `05-review`: `CAP-verify-01`, `CAP-verify-02` · `06-ship`: `CAP-deploy-01`.

- [ ] **Step 4: Kiểm trong `tools/check-sdlc.sh`**

Trong vòng lặp phase, sau phần `provides`, với mỗi `c` trong `fm_list "$src" capabilities`:
- `! cap_co "$c"` → `loi "phase $pid: capabilities \"$c\" — không có capability đó; sửa id hoặc thêm vào sdlc/stages/."`
- `cap_stage "$c"` ≠ `$s` → `loi "phase $pid: capabilities \"$c\" thuộc stage $cs, phase implements $s — chuyển id sang phase của stage $cs."`
- hợp lệ → `echo "$pid|$s|$c" >> "$W/nhan"`.

Khối utility command: thêm `[ -z "$(fm_list "$E/$cfile" capabilities)" ] || loi "utility command $cid: khai capabilities — xoá khoá; utility command không ánh xạ vào stage SDLC."`. Cập nhật comment đầu file.

- [ ] **Step 5: Chạy test, xác nhận xanh + adapter không đổi**

Run: `sh tools/tests/20-sdlc-conformance.sh && sh tools/run-tests.sh`
Expected: `MỌI CA ĐẠT` (test so adapter `AW_COMPARE=1` giữ nguyên — `capabilities:` không vào lệnh sinh ra).

- [ ] **Step 6: Commit**

```bash
git add workflow/phases tools/check-sdlc.sh tools/tests/20-sdlc-conformance.sh
git commit -m "Interface SDLC: phase khai capabilities:, check-sdlc kiểm id và stage"
```

---

### Task 3: Trạng thái stage suy ra + bảng roadmap

**Files:**
- Modify: `workflow.yaml` (khối `sdlc:`)
- Modify: `tools/check-sdlc.sh` (khối "---- khối sdlc:", "---- stage ↔ phase", `GAP`/`la_gap`, comment đầu file)
- Test: `tools/tests/20-sdlc-conformance.sh` (viết lại nhóm `check-sdlc.sh: trạng thái stage`)

**Interfaces:**
- Consumes: `$W/cap`, `$W/nhan` (Task 1, 2).
- Produces: hàm `trang_thai <stage>` → `implemented | partial | gap` suy ra (giữ tên, đổi nghĩa); `GAP` dựng từ suy ra; `la_gap` không đổi chữ ký.

Luật suy ra (spec § 3.3): đếm capability của stage trong `$W/cap` và số được nhận (id khác nhau) trong `$W/nhan`: bằng nhau → `implemented`; 0 → `gap`; còn lại → `partial`.

- [ ] **Step 1: Viết lại nhóm test trạng thái (đỏ)**

Xoá các ca cũ dùng `status:` (`stage không phase nào implement…`, `partial thiếu note`, `gap thiếu note`, `gap mà có phase implement`, `partial mà không phase nào implement`, `status lạ`). Giữ ca `khối sdlc: khai stage không có` (đổi chuỗi tìm `'  - stage: operate'` vẫn đúng). Thêm:

```sh
moi; thay "$E/workflow.yaml" '  - stage: deploy
    note:' '  - stage: deploy
    status: partial
    note:'
vi_pham "khối sdlc: còn khoá status → chặn" "khối sdlc: stage deploy còn khoá status — xoá dòng status"
moi; awk '!/note: Dừng ở MR\/PR/' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
vi_pham "suy ra partial mà thiếu note → chặn" "stage deploy: suy ra partial nhưng khối sdlc: không có note"
moi; awk '!/note: CI\/CD/' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
vi_pham "suy ra gap mà thiếu note → chặn" "stage operate: suy ra gap nhưng khối sdlc: không có note"
moi; thay "$E/workflow/phases/06-ship.md" '  - CAP-deploy-01' '  - CAP-deploy-01
  - CAP-deploy-02
  - CAP-deploy-03'
vi_pham "nhận đủ capability mà còn note → chặn" "stage deploy: suy ra implemented nhưng khối sdlc: còn note"
# chiều ngược: nhận đủ + xoá mục khối sdlc: → ĐẠT, stage thành implemented
awk '/^  - stage: deploy$/ { skip = 1; next } skip && /^    / { next } { skip = 0; print }' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
ky_vong 0 "nhận đủ capability + xoá note → ĐẠT" sh "$SC" "$E"
dung "…stage deploy thành implemented" sh -c "sh '$SC' '$E' 2>/dev/null | grep -Eq '^  deploy +implemented +ship'"
moi; awk '!/^  - CAP-/' "$E/workflow/phases/06-ship.md" > "$E/p" && thay "$E/p" 'capabilities:' 'capabilities: []' && mv "$E/p" "$E/workflow/phases/06-ship.md"
vi_pham "phase implements mà không nhận capability nào → chặn" "phase ship: implements deploy nhưng không nhận capability nào"
```

Ở nhóm "engine hiện tại" thêm:

```sh
dung "…bảng ánh xạ in trạng thái suy ra" sh -c "sh '$SC' '$ROOT' 2>/dev/null | grep -Eq '^  verify +partial +review'"
dung "…in bảng roadmap capability còn thiếu" sh -c "sh '$SC' '$ROOT' 2>/dev/null | grep -Eq '^    CAP-deploy-02 +machine +'"
dung "…roadmap không liệt kê capability đã nhận" sh -c "! sh '$SC' '$ROOT' 2>/dev/null | grep -q '^    CAP-deploy-01 '"
```

(`thay` trên `$E/p` trước khi `mv` — hoặc tách hai lệnh; miễn file kết quả có `capabilities: []`.)

- [ ] **Step 2: Chạy test, xác nhận đỏ**

Run: `sh tools/tests/20-sdlc-conformance.sh`
Expected: ca mới HỎNG; `sh tools/tests/21-sdlc-profiles.sh` vẫn ĐẠT.

- [ ] **Step 3: `workflow.yaml` bỏ `status`**

Khối `sdlc:` còn `stage` + `note` cho `plan`, `verify`, `deploy`, `operate`. Sửa `note` cho khớp capability còn thiếu (ví dụ `deploy`: "Dừng ở MR/PR đã merge; release, triển khai và rollback chưa làm"). Chuỗi `note` của `plan` phải còn chứa "Chỉ nhận việc đã có", của `deploy` "Dừng ở MR/PR", của `operate` "CI/CD" (test grep).

- [ ] **Step 4: Suy ra trạng thái trong `tools/check-sdlc.sh`**

- Khối "---- khối sdlc:": `status` khác rỗng → `loi "khối sdlc: stage $s còn khoá status — xoá dòng status; trạng thái do máy suy ra từ capabilities: của phase."`; bỏ `case "$st"` cũ. Giữ lỗi "khai stage không có".
- Chuyển định nghĩa `trang_thai` xuống sau vòng lặp phase, đổi thân thành luật suy ra ở trên. Thêm `co_note <stage>` → 0 nếu `$W/khai` có note khác rỗng cho stage.
- Khối "---- stage ↔ phase": tiêu đề `echo "Stage → phase (trạng thái suy ra từ capabilities: của phase):"`. Thay các nhánh `gap`/`partial` cũ bằng:
  - `implemented` mà có note → `loi "stage $s: suy ra implemented nhưng khối sdlc: còn note — xoá mục stage $s khỏi khối sdlc:."`
  - `partial`/`gap` mà không note → `loi "stage $s: suy ra $st nhưng khối sdlc: không có note — thêm note nói phần thiếu và lý do."`
  - `gap` → `continue` (không kiểm provides/exit, như cũ).
- Vòng lặp phase: phase không ghi dòng nào vào `$W/nhan` → `loi "phase $pid: implements $s nhưng không nhận capability nào — thêm id vào capabilities: (xem sdlc/stages/)."`
- `GAP=` dựng bằng `trang_thai` cho từng stage trong `$W/stages` thay vì đọc `$W/khai`.
- Sau bảng ánh xạ, in roadmap (chỉ khi có stage không `implemented`):

```
Capability còn thiếu (roadmap — mô tả ở sdlc/stages/):
  deploy (partial): <note>
    CAP-deploy-02  machine  Change is released or deployed to its target environment
```

  Dòng capability: 4 dấu cách, id, 2 dấu cách, `judged` đệm 7, 2 dấu cách, tên (`printf '    %s  %-7s  %s\n'`).
- Cập nhật comment đầu file: mục "Khối sdlc:" và "Stage" theo luật mới; dòng "In …" thêm bảng roadmap.

- [ ] **Step 5: Chạy test, xác nhận xanh**

Run: `sh tools/tests/20-sdlc-conformance.sh && sh tools/tests/21-sdlc-profiles.sh && sh tools/check-sdlc.sh`
Expected: mọi ca ĐẠT; output `check-sdlc.sh` có bảng ánh xạ với `plan partial`, `require/design/implement implemented`, `verify/deploy partial`, `operate gap`, và bảng roadmap đúng 9 capability (`CAP-plan-03`, `CAP-plan-04`, `CAP-verify-03..05`, `CAP-deploy-02`, `CAP-deploy-03`, `CAP-operate-01`, `CAP-operate-02`).

- [ ] **Step 6: Commit**

```bash
git add workflow.yaml tools/check-sdlc.sh tools/tests/20-sdlc-conformance.sh
git commit -m "Interface SDLC: trạng thái stage suy ra từ capability, bỏ status khai tay, in roadmap"
```

---

### Task 4: `AGENTS.md` — interface trước

**Files:**
- Modify: `AGENTS.md` (§ Map, § Making a change, § Change together)

**Interfaces:** không (văn bản). Link tới `docs/interface-sdlc.md` (tạo ở Task 5 — cùng PR).

- [ ] **Step 1: Sửa theo spec § 6**

Tiếng Anh, ngắn, giọng hiện có. Nội dung đúng spec § 6:
- § Map, gạch `sdlc/`: thêm "Source of every engine change"; stage files list capabilities `CAP-<stage>-NN`; phases claim them in `capabilities:`; stage status is derived (`docs/interface-sdlc.md`).
- § Making a change, bullet đầu mới **Locate in the interface**: name the `CAP-…`/`INV-…` the change serves; none fits → change the interface (capability or invariant) in the same PR; a behavior/rule proposal names those ids; PR description has "Interface: CAP-…, INV-…" or "no interface change: <reason>" (convention, not machine-checked).
- § Change together, 3 dòng: implement a missing capability; add a capability; weaken the interface (drop/relax a capability or invariant) → ids + reason under `### Bỏ` / `### Thay đổi` in `changes/<branch>.md`.

- [ ] **Step 2: Kiểm không phá test**

Run: `sh tools/run-tests.sh`
Expected: `MỌI CA ĐẠT` (test 19 block-main hook đọc `.claude/`, không đọc AGENTS.md — xác nhận bằng chạy).

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "AGENTS.md: thay đổi engine bắt đầu từ interface SDLC (CAP/INV)"
```

---

### Task 5: Tài liệu cho người

**Files:**
- Create: `docs/interface-sdlc.md`, `changes/feat-sdlc-capability.md`
- Modify: `docs/kien-truc.md` (§ Interface SDLC), `docs/thuat-ngu.md`, `docs/viec-can-lam.md` (§ Interface SDLC), `README.md` (danh sách tài liệu)

**Interfaces:**
- Consumes: output thật của `sh tools/check-sdlc.sh` (Task 3) — ảnh chụp bảng chép từ output, không gõ tay.

- [ ] **Step 1: `docs/interface-sdlc.md`**

Tiếng Việt, 6 mục đúng spec § 7.1. Ràng buộc:
- Giải thích + trỏ tới luật; không chép lại luật (trỏ `AGENTS.md`, `tools/check-sdlc.sh`, `docs/kien-truc.md`).
- Mục 4 có đủ 7 công thức; mỗi công thức: các bước theo thứ tự, file, lệnh (`sh tools/check-sdlc.sh`, `sh tools/run-tests.sh`), mục ghi vào `changes/`.
- Mục 5 liệt kê mọi chuỗi `[LỖI]` liên quan capability/trạng thái (Task 1–3) với cách sửa.
- Mục 6: ảnh chụp bảng roadmap + một đoạn tiếng Việt cho mỗi stage `partial`/`gap`; dòng "`sh tools/check-sdlc.sh` in lại bảng này".
- Sơ đồ quan hệ ở mục 1: khối text/ASCII (không cần ảnh).

- [ ] **Step 2: `docs/kien-truc.md` § Interface SDLC**

- Đoạn mô hình: thêm capability (`CAP-<stage>-NN`, `Rule`, `Judged by`), phase `capabilities:`, trạng thái suy ra; bỏ câu "Khối `sdlc:` … chỉ khai stage không làm đủ: `partial` hay `gap`" thay bằng mô hình mới.
- Bảng ánh xạ: tiêu đề cột `trạng thái (suy ra)`, chép từ output.
- **Quyết định**: thêm D1–D10 spec § 2 (mỗi cái một gạch, có lý do) + "phase implements mà không nhận capability → chặn" (spec § 3.3). Sửa gạch cũ "Không làm thì khai `gap`, không im lặng" cho khớp: giờ là suy ra + note bắt buộc.
- Trỏ tới `docs/interface-sdlc.md` cho phần thực hành.

- [ ] **Step 3: `docs/thuat-ngu.md`, `docs/viec-can-lam.md`, `README.md`**

- Thuật ngữ: `capability`, `trạng thái stage` (suy ra), `hạ chuẩn interface` — theo định dạng mục hiện có của file.
- Việc cần làm § Interface SDLC: bỏ danh sách phần thiếu tự viết → trỏ bảng roadmap (`sh tools/check-sdlc.sh`, `docs/interface-sdlc.md` mục 6); thêm "Bước A — gắn mọi luật checker vào CAP/INV" (tóm tắt spec § 9) và "Test so ảnh chụp bảng trong docs với output `check-sdlc.sh`".
- README: link `docs/interface-sdlc.md` cạnh các link docs hiện có.

- [ ] **Step 4: `changes/feat-sdlc-capability.md`**

Theo `changes/README.md`. `### Thêm`: capability cho mỗi stage, bảng roadmap trong `check-sdlc.sh`, `docs/interface-sdlc.md`. `### Thay đổi`: khối `sdlc:` của `workflow.yaml` bỏ `status` (trạng thái suy ra) — người fork engine có khối `sdlc:` riêng phải xoá dòng `status`. `### Nội bộ`: `check-sdlc.sh` luật mới, `capabilities:` trong phase, `AGENTS.md` interface trước. Ghi rõ người dùng `aw` không thấy gì khác.

- [ ] **Step 5: Kiểm**

Run: `sh tools/run-tests.sh`; rồi đọc output `sh tools/check-sdlc.sh` và so bằng mắt với bảng trong `docs/interface-sdlc.md` mục 6 và `docs/kien-truc.md`.
Expected: `MỌI CA ĐẠT`; bảng khớp output.

- [ ] **Step 6: Commit**

```bash
git add docs/interface-sdlc.md docs/kien-truc.md docs/thuat-ngu.md docs/viec-can-lam.md README.md changes/feat-sdlc-capability.md
git commit -m "Docs: hướng dẫn interface SDLC cho người, quyết định capability, roadmap"
```

---

### Task 6: Kiểm cả nhánh, chuẩn bị PR

- [ ] **Step 1: Đồng bộ main**

Run: `git fetch origin && git merge origin/main` rồi `sh tools/run-tests.sh`
Expected: không conflict (hoặc đã giải), `MỌI CA ĐẠT`, không `CẢNH BÁO … nên tách` cho part 20 (có → tách part ở ranh giới fixture, cùng PR).

- [ ] **Step 2: Lệnh sinh ra không đổi**

Run: `sh adapters/claude-code/build.sh --out <tmp-git-dir>` trên nhánh này và trên `origin/main` (worktree tạm), `diff -r`.
Expected: không khác.

- [ ] **Step 3: Mở PR (sau khi người đồng ý)**

Dùng superpowers:finishing-a-development-branch. Mô tả PR (tiếng Việt): thay đổi gì, vì sao, test nào cover; dòng "Interface: CAP-* (thêm mới cho mọi stage)"; "`docs/huong-dan.md` không đổi — người dùng `aw` không thấy gì khác"; hỏi người có giữ `docs/superpowers/` trong PR không. Kết thúc bằng `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
