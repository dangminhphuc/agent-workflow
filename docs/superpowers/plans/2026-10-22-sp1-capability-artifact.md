# SP1 — Capability gắn artifact, capability phạm vi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Interface có capability phạm vi (`CAP-implement-04…06`) và `CAP-breakdown-02`, stage `implement` thành `partial`; mọi capability khai `- Artifact:` và `check-sdlc.sh` chặn khi một loại trong `provides` của stage không capability nào trỏ tới.

**Architecture:** Task 1 thêm capability mới (đã kèm `- Artifact:`, checker hiện tại bỏ qua dòng lạ) và cho phase nhận — bản thật ĐẠT ngay. Task 2 bật luật: khối awk đọc capability trong `tools/check-sdlc.sh` bắt `- Artifact:`, kiểm từng giá trị với `provides` của stage, ghi cặp `stage|loại` ra `$W/capart`; sau vòng stage, mỗi dòng `$W/prov` phải có cặp tương ứng. Thứ tự này giữ bản thật ĐẠT sau mỗi commit.

**Tech Stack:** POSIX sh + awk + sed (mawk-safe: ERE không `{n}`).

**Spec:** `docs/superpowers/specs/2026-10-22-sp1-capability-artifact-design.md`

## Global Constraints

- Branch `claude/brave-heisenberg-t70jup`; không sửa `main`. Trước push: `git fetch origin && git merge origin/main`, rồi `sh tools/run-tests.sh`.
- Commit: `git -c user.name="Đặng Minh Phúc" -c user.email="dangminhphuc.dev@gmail.com" commit …`; message kết thúc bằng hai dòng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` và `Claude-Session: https://claude.ai/code/session_01FY47vXcyouyJW7vwkQnCMT`.
- Thân file stage, `Rule:` tiếng Anh, không tên file / cú pháp engine. Thông báo `check-sdlc.sh`, docs, `changes/`: tiếng Việt.
- `- Artifact:` bắt buộc; giá trị cách nhau `,`, viết trơn, khoảng trắng quanh giá trị bỏ qua; phải nằm trong `provides` của chính stage. `adds_provides` của profile không chịu luật.
- Ba thông báo lỗi, đúng nguyên văn (`S` = stage, `t` = loại, `<danh sách>` = provides của stage theo thứ tự trong file, nối bằng `, `):
  - `CAP-x: thiếu "- Artifact:" — thêm loại artifact capability này bảo đảm, lấy trong provides của stage S: <danh sách>.`
  - `CAP-x: Artifact "t" không có trong provides của stage S (<danh sách>) — sửa tên loại, hoặc chuyển capability sang stage provides loại đó.`
  - `stage S: provides "t" — không capability nào khai "Artifact: t"; thêm hoặc gắn một capability.`
- Không đổi dạng output bảng stage → phase / roadmap / ma trận profile.
- Hoàn thành: `sh tools/check-sdlc.sh` ĐẠT; `sh tools/run-tests.sh` → `MỌI CA ĐẠT`.

## Review Focus

1. `- Artifact:` lạc dưới heading khác (`## Notes`) sau capability cuối — không được tính (test ở Task 2).
2. Giá trị có khoảng trắng / nhiều giá trị (`requirements ,open-questions `) — ĐẠT (Task 2).
3. File stage CRLF — `\r` cuối giá trị không làm giá trị lệch provides (ca CRLF sẵn có ở `22-…` phải vẫn ĐẠT; Task 2 chạy lại).
4. Bỏ một loại khỏi `provides` của stage mà capability vẫn trỏ tới — báo thêm lỗi Artifact; ca cũ "bỏ security-evidence khỏi provides" phải vẫn khớp thông báo cũ (Task 2 chạy lại `20-…`).
5. Phase nhận nốt `CAP-implement-05` (sau SP3) mà còn note — phải bị chặn (test ở Task 1).

---

### Task 1: Capability phạm vi, `CAP-breakdown-02`, `implement` thành partial

**Files:**
- Modify: `sdlc/stages/03-breakdown.md`, `sdlc/stages/04-implement.md` (capability mới — nguyên văn spec § 3.3, gồm dòng `- Artifact:`)
- Modify: `workflow/phases/03-plan.md` (`capabilities:` thêm `CAP-breakdown-02`), `workflow/phases/04-implement.md` (thêm `CAP-implement-04`, `CAP-implement-06`)
- Modify: `workflow.yaml` khối `sdlc:` (mục `implement` + note — spec § 3.4, đặt trước mục `verify`)
- Test: `tools/tests/20-sdlc-conformance.sh`
- Modify: `docs/interface-sdlc.md` § 6, `docs/kien-truc.md` bảng ánh xạ § Interface SDLC, `changes/claude-brave-heisenberg-t70jup.md`

**Interfaces:**
- Produces: `CAP-implement-04` (`Artifact: change`), `CAP-implement-06` (`Artifact: task-evidence`) — Task 2 dựa vào chúng để `change`, `task-evidence` có capability trỏ tới.

- [ ] **Step 1: Sửa test (đỏ).** Trong `tools/tests/20-sdlc-conformance.sh`:
  - Ca "…in ánh xạ stage → phase": `'^  implement +implemented +implement$'` → `'^  implement +partial +implement$'`.
  - Chuỗi "trạng thái suy ra đúng cả 8 stage": `implement=implemented` → `implement=partial`.
  - Chuỗi "roadmap liệt kê đúng…": chèn `CAP-implement-05 ` sau `CAP-plan-04 `.
  - Thêm cuối nhóm "trạng thái stage" (sau ca "khối sdlc: khai stage không có"):
```sh
moi; thay "$E/workflow/phases/04-implement.md" '  - CAP-implement-06' '  - CAP-implement-06
  - CAP-implement-05'
vi_pham "implement nhận đủ capability mà còn note → chặn" "stage implement: suy ra implemented nhưng khối sdlc: còn note"
awk '/^  - stage: implement$/ { bo = 1; next } bo && /^    / { next } { bo = 0; print }' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
ky_vong 0 "implement nhận đủ + xoá note → ĐẠT" sh "$SC" "$E"
dung "…stage implement thành implemented" sh -c "sh '$SC' '$E' 2>/dev/null | grep -Eq '^  implement +implemented +implement$'"
```

- [ ] **Step 2: Chạy, thấy đỏ.**
Run: `sh tools/tests/20-sdlc-conformance.sh`
Expected: FAIL ở ca ánh xạ, chuỗi trạng thái, chuỗi roadmap và các ca mới.

- [ ] **Step 3: Thêm capability, nhận capability, note** — nguyên văn spec § 3.3 (bốn khối, mỗi khối có `- Artifact:`) và § 3.4.

- [ ] **Step 4: Chạy, thấy xanh.**
Run: `sh tools/check-sdlc.sh | grep -E '^  implement|CAP-implement' && sh tools/tests/20-sdlc-conformance.sh && sh tools/tests/22-sdlc-stage-files.sh`
Expected: `  implement  partial  implement`; `  implement (partial): Phạm vi diff chỉ kiểm theo cả việc…`; đúng một dòng `    CAP-implement-05  machine  Each task changes only its own files…`; hai phần test không FAIL.

- [ ] **Step 5: Docs.**
  - `docs/interface-sdlc.md` § 6: dán lại output `sh tools/check-sdlc.sh` (Stage → phase + roadmap) vào khối ảnh chụp; thêm gạch **`implement` — partial**: phạm vi diff đã kiểm theo cả việc (`CAP-implement-04`); chưa kiểm theo từng task và chưa cảnh báo glob rộng (`CAP-implement-05`, SP3).
  - `docs/kien-truc.md` bảng ánh xạ: dòng `implement` → `partial`, cột thiếu `CAP-implement-05` phạm vi theo task.
  - `changes/claude-brave-heisenberg-t70jup.md` mục `### Nội bộ`, thêm: "**Interface SDLC: capability phạm vi.** Thêm `CAP-breakdown-02` (task nêu file được đổi và cách kiểm), `CAP-implement-04` (file đổi nằm trong kế hoạch hoặc khai ngoài kế hoạch), `CAP-implement-05` (phạm vi theo từng task, glob hẹp — chưa làm), `CAP-implement-06` (task chỉ xong khi máy ghi bước kiểm đạt). Stage `implement` thành `partial`. Người dùng `aw` không thấy gì khác."

- [ ] **Step 6: Commit.**
```bash
git add sdlc/stages workflow/phases/03-plan.md workflow/phases/04-implement.md workflow.yaml tools/tests/20-sdlc-conformance.sh docs/interface-sdlc.md docs/kien-truc.md changes
git commit -m "Interface SDLC: CAP-breakdown-02, CAP-implement-04…06; implement thành partial"
```

### Task 2: Luật `- Artifact:` — checker, dữ liệu interface, test, docs

**Files:**
- Modify: `tools/check-sdlc.sh` (chú thích đầu file dòng 9–12; khởi tạo file tạm ~dòng 45; khối awk capability ~138–176; kiểm phủ provides ngay sau vòng stage, trước `stage_co()`)
- Modify: `sdlc/stages/00-plan.md` … `07-operate.md` (thêm `- Artifact:` vào 23 capability có sẵn)
- Test: `tools/tests/22-sdlc-stage-files.sh` (nhóm "check-sdlc.sh: capability trong file stage")
- Modify: `docs/interface-sdlc.md` § 2, § 3, § 4.3, § 5; `docs/kien-truc.md` § Interface SDLC (khối **Quyết định:**); `changes/claude-brave-heisenberg-t70jup.md`; `docs/superpowers/2026-10-22-roadmap-cai-thien.md`

**Interfaces:**
- Consumes: capability Task 1 (`change`, `task-evidence`, `task-plan` đã có capability khai `Artifact`).
- Produces: file tạm `$W/capart`, mỗi dòng `<stage>|<loại>` cho mỗi giá trị Artifact hợp lệ.

- [ ] **Step 1: Viết test (đỏ).** Thêm vào cuối nhóm capability của `tools/tests/22-sdlc-stage-files.sh`, sau ca "heading lạ trong ## Capabilities". Trong `06-deploy.md` có ba dòng `- Artifact: delivery` nên dùng `awk … ++n == k`, không dùng `thay`:

```sh
moi; awk '!(/^- Artifact:/ && ++n == 1)' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "capability thiếu Artifact → chặn" "CAP-deploy-01: thiếu \"- Artifact:\" — thêm loại artifact capability này bảo đảm, lấy trong provides của stage deploy: delivery."
moi; awk '{ if (/^- Artifact:/ && ++n == 1) print "- Artifact:"; else print }' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "Artifact rỗng → chặn" "CAP-deploy-01: thiếu \"- Artifact:\""
moi; awk '{ if (/^- Artifact:/ && ++n == 1) print "- Artifact: deliveryx"; else print }' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "Artifact không có trong provides → chặn" "CAP-deploy-01: Artifact \"deliveryx\" không có trong provides của stage deploy (delivery)"
moi; thay "$E/sdlc/stages/04-implement.md" '- Artifact: task-evidence' '- Artifact: change'
vi_pham "provides không capability nào trỏ tới → chặn" "stage implement: provides \"task-evidence\" — không capability nào khai \"Artifact: task-evidence\""
moi; awk '!(/^- Artifact:/ && ++n == 3)' "$E/sdlc/stages/06-deploy.md" > "$E/s" && printf '\n## Notes\n\n- Artifact: delivery\n' >> "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "Artifact nằm dưới heading khác không tính → chặn" "CAP-deploy-03: thiếu \"- Artifact:\""
moi; thay "$E/sdlc/stages/01-require.md" '- Artifact: open-questions' '- Artifact:  requirements ,open-questions '
ky_vong 0 "Artifact nhiều giá trị, có khoảng trắng → ĐẠT" sh "$SC" "$E"
```

Lưu ý: ca "thiếu Artifact" và "lạc dưới heading" cần Step 4 (dữ liệu có `- Artifact:`) mới có dòng để xoá — trước Step 4 chúng ĐẠT nhầm, đó chính là "đỏ".

- [ ] **Step 2: Chạy, thấy đỏ.**
Run: `sh tools/tests/22-sdlc-stage-files.sh`
Expected: các ca mới (trừ ca nhiều giá trị) FAIL — mã 0 thay vì 1; ca cũ vẫn đạt.

- [ ] **Step 3: Sửa `tools/check-sdlc.sh`.**
  - Cạnh `: > "$W/cap"` (~dòng 45): thêm `: > "$W/capart"`.
  - Khối awk capability: thêm `-v pv="$(awk 'NF' "$W/p" | tr '\n' ',')"`; trong `BEGIN` tách `pv` theo `,` vào `prov[]` và chuỗi `ds` (nối `, `, giữ thứ tự). Khi mở capability đặt `coa = 0; av = ""`. Dòng `cur != "" && /^- Artifact:/` → `coa = 1; av = phần sau "- Artifact:"` (sau `sub(/\r$/, "")` sẵn có).
  - Trong `dong()`: tách `av` theo `,`, bỏ khoảng trắng hai đầu từng phần, bỏ phần rỗng. Không còn phần nào (hoặc `!coa`) → `print "E|" cur ": thiếu …"` (nguyên văn Global Constraints, `<danh sách>` = `ds`). Phần không có trong `prov[]` → `E|` thông báo Artifact lạ. Phần hợp lệ → `print "A|" t`.
  - Vòng đọc `$W/c1`: thêm nhánh `A\|*) echo "$id|${l#A|}" >> "$W/capart" ;;`.
  - Sau vòng stage, trước `stage_co()`: với mỗi dòng `s|t` của `$W/prov`, nếu không `grep -qxF "$s|$t" "$W/capart"` → `loi "stage $s: provides \"$t\" — không capability nào khai \"Artifact: $t\"; thêm hoặc gắn một capability."`.
  - Chú thích đầu file, câu Capability: thêm `thiếu "- Artifact:" hoặc Artifact không có trong provides của stage; loại trong provides không capability nào khai Artifact.`

- [ ] **Step 4: Thêm `- Artifact:` vào 23 capability có sẵn** — đúng bảng spec § 3.2, ngay sau dòng `- Judged by:` của từng capability.

- [ ] **Step 5: Chạy, thấy xanh.**
Run: `sh tools/check-sdlc.sh && sh tools/tests/22-sdlc-stage-files.sh && sh tools/tests/20-sdlc-conformance.sh && sh tools/tests/21-sdlc-profiles.sh`
Expected: `ĐẠT — engine tuân thủ interface SDLC`; ba phần test không FAIL (gồm ca CRLF và ca "bỏ security-evidence khỏi provides").

- [ ] **Step 6: Docs.**
  - `docs/interface-sdlc.md` § 2: thêm `- Artifact: delivery` vào ví dụ `CAP-deploy-01`/`-02`; bảng trường thêm dòng `` `- Artifact:` `` — "Loại artifact (trong `provides` của stage) capability bảo đảm; một hoặc nhiều, cách nhau dấu phẩy; bắt buộc". § 3: thêm gạch "Mỗi loại trong `provides` của stage phải có ít nhất một capability khai `Artifact` loại đó (không áp cho `adds_provides` của profile)". § 4.3 bước 1: thêm `- Artifact:`. § 5: ba dòng lỗi mới vào bảng (Nghĩa / Sửa).
  - `docs/kien-truc.md` § Interface SDLC, khối **Quyết định:** — thêm gạch: "**Capability khai `Artifact`, bắt buộc.** Mỗi loại `provides` của stage có capability trỏ tới, máy chặn: stage ít capability không còn rẻ thành `implemented`. Không áp cho `adds_provides` của profile: các loại đó đã có invariant máy giữ, nêu tên ca test (INV-007, INV-010) — capability thêm là nói lại một điều."
  - `changes/claude-brave-heisenberg-t70jup.md` mục `### Nội bộ`, thêm: "**Interface SDLC: capability khai `Artifact`.** Mỗi capability ghi loại artifact nó bảo đảm; `check-sdlc.sh` chặn khi thiếu, khi loại không thuộc stage, và khi một loại `provides` của stage không capability nào trỏ tới."
  - Roadmap: cột Plan của SP1 → `[plan](plans/2026-10-22-sp1-capability-artifact.md)`.

- [ ] **Step 7: Kiểm toàn bộ.**
Run: `git fetch origin && git merge origin/main && sh tools/check-release.sh && sh tools/run-tests.sh`
Expected: `ĐẠT — version nhất quán`; `MỌI CA ĐẠT` (gồm `08-adapters` — lệnh sinh không đổi).

- [ ] **Step 8: Commit + push.**
```bash
git add tools/check-sdlc.sh tools/tests/22-sdlc-stage-files.sh sdlc/stages docs changes
git commit -m "check-sdlc: capability khai Artifact; provides của stage phải có capability trỏ tới"
git push -u origin claude/brave-heisenberg-t70jup
```
