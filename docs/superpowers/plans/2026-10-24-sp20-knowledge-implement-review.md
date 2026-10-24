# SP20 — `aw knowledge implement|review` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement và review được nạp durable knowledge theo phạm vi của chính chúng; việc bỏ design vẫn đọc chỉ mục ADR.

**Architecture:** Tách phần khớp `Scope`/thư mục của nhánh `design` (`tools/knowledge.sh`) thành `kt_lay` ở
`tools/lib/knowledge.sh`. `implement` đổi `Expected files` của `plan.md` thành đường dẫn rồi gọi `kt_lay`;
`review` in cột tài liệu của `kt_anh_huong`, đúng tập mà review phải ghi verdict. Không thêm luật chặn.

**Tech Stack:** POSIX sh + awk + sed + git (`AGENTS.md` § Code).

**Spec:** `docs/superpowers/specs/2026-10-23-sp20-24-rag-markdown-design.md` § A

## Global Constraints

- POSIX sh + awk + sed + git; không bashism; ERE không `{n}`; awk nhiều file dùng `FILENAME == ARGV[i]`.
- Mỗi script khai nhãn qua `kq_khai`; prompt/doc nhắc nhãn, không nhắc mã thoát.
- Đường dẫn repo/cấu hình chỉ lấy từ `AW_REPO`, `AW_CONFIG` (`MT_REPO`, `MT_CONV` qua `mt_dat`).
- Text cho agent (phase): tiếng Anh, ngắn, mệnh lệnh. Docs, `changes/`, output `aw`: tiếng Việt.
- Hàm/biến shell: tiếng Việt không dấu, tiền tố `kt_` / `_kl…` như code xung quanh.
- Phase không nhắc lại hợp đồng I/O hay điều checker kiểm.
- Stdout của `aw knowledge` là dữ liệu, mỗi dòng một đường dẫn tương đối với gốc repo; không in gì = không có.
- Output `aw knowledge design` không đổi byte nào (ca hồi quy).
- Kết thúc: `sh tools/run-tests.sh` → `MỌI CA ĐẠT`; `sh tools/check-sdlc.sh` → ĐẠT.

## Review Focus

- `Expected files` có token chỉ là thư mục mới chưa có trên base (`src/moi/**`) → vẫn khớp `src/ARCHITECTURE.md` và ADR có `Scope` `src/*` (nhờ tiền tố thư mục). Test ở Task 2.
- `plan.md` không có hoặc không có dòng `Expected files:` → `implement` không in gì ngoài chỉ mục (việc bỏ design), mã ĐÃ LIỆT KÊ. Test ở Task 2.
- Token trỏ thư mục ADR/luật (`docs/adr/*`, task nâng ADR) → không kéo theo mọi ADR. Test ở Task 2.
- `Base:` thiếu sha hoặc sha không có trong repo → token glob chỉ dùng tiền tố thư mục, không lỗi. Test ở Task 2.
- Việc chưa có diff → `review` không in gì, mã ĐÃ LIỆT KÊ. Test ở Task 3.

---

### Task 1: Tách `kt_lay`, giữ nguyên output `design`

**Files:**
- Modify: `tools/lib/knowledge.sh` (thêm `kt_lay` sau phần chú thích đầu file)
- Modify: `tools/knowledge.sh` (khối `{ … } | awk '!t[$0]++'` của nhánh design → gọi `kt_lay`; nạp `tools/lib/cross-check.sh`, `tools/lib/knowledge.sh`)
- Create: `tools/tests/26-knowledge-retrieval.sh`

**Interfaces:**
- Produces: `kt_lay <gốc repo> <conventions.md>` — stdin: các đường dẫn (mỗi dòng một, tương đối với gốc repo, có thể chưa tồn tại); stdout: ADR accepted có `Scope` khớp, file luật có luật active khớp (`luat_lien_quan`), file `knowledge_files` đã commit có thư mục là cha của đường dẫn — đúng thứ tự và khử trùng như code hiện nay. Đường dẫn là thư mục có thật → khớp thêm `<p>/x` như hiện nay.

- [ ] **Step 1: Viết phần test mới với fixture riêng**

`tools/tests/26-knowledge-retrieval.sh` theo khuôn `16-journal-adr.sh` (`. lib.sh`, `tao_fixture`, `nhom`, `ket_thuc`). Hàm dựng fixture `kt_fixture` (dùng lại ở Task 2–3):
- `docs/adr/0001-x-dec-001.md`: `# ADR-0001: a`, `- Status: accepted`, `- Scope: \`src/*\``; `docs/adr/0002-x-dec-002.md`: tương tự nhưng `- Status: superseded by 0001`; `docs/adr/0003-x-dec-003.md`: accepted, `- Scope: \`lib/*\``; `docs/adr/README.md` dựng bằng `adr_lam_chi_muc` (hoặc chép dòng bảng đúng dạng `| [0001](…) | a | accepted | \`src/*\` |`).
- `src/ARCHITECTURE.md`, `lib/ARCHITECTURE.md`; `docs/product/rules/billing.md` có một khối `### BR-BILLING-001: x` với `- Scope: \`src/*\`` và `- Status: active` (đủ trường như khối trong `17-rule-crosscheck.sh`).
- Commit tất cả lên `main` trước `viet_intake` để chúng nằm trên `Base:`.

Ca:
```sh
thay "$F/tdd.md" 'Module src/a.' 'Module `src/a.txt`.'
dung "design: output không đổi (hồi quy)" bang "$(sh "$KT" design "$F" 2>/dev/null | tr '\n' ' ')" \
  "docs/adr/README.md docs/adr/0001-x-dec-001.md docs/product/rules/billing.md src/ARCHITECTURE.md "
```

- [ ] **Step 2: Chạy, xác nhận ĐẠT trên code hiện tại** (ca hồi quy phải xanh trước khi refactor)

Run: `sh tools/tests/26-knowledge-retrieval.sh`
Expected: `Tổng: … 0 hỏng`. Nếu thứ tự khác, sửa chuỗi mong đợi theo output thật của code hiện tại — không sửa code.

- [ ] **Step 3: Tách `kt_lay`; `design` gọi nó**

Thân hàm là khối hiện có, thay `$DD` bằng stdin (đọc vào biến một lần), `$R` → `$1`, `$MT_CONV` → `$2`. Tên biến nội bộ tiền tố `_kl` (sh không có biến cục bộ).

- [ ] **Step 4: Chạy lại `26`, `16`, `17`**

Run: `sh tools/run-tests.sh 26-knowledge-retrieval 16-journal-adr 17-rule-crosscheck`
Expected: `MỌI CA ĐẠT`

- [ ] **Step 5: Commit** `git add tools/lib/knowledge.sh tools/knowledge.sh tools/tests/26-knowledge-retrieval.sh` — `Tách kt_lay khỏi aw knowledge design`

### Task 2: `aw knowledge implement`

**Files:**
- Modify: `tools/knowledge.sh` (`BL_KIEN_THUC`, nhánh `implement`, chú thích đầu file)
- Modify: `tools/lib/knowledge.sh` (thêm `kt_duong_plan`)
- Modify: `bin/aw-engine:13` (dòng trợ giúp: `knowledge spec|design|implement|review`)
- Test: `tools/tests/26-knowledge-retrieval.sh`

**Interfaces:**
- Consumes: `kt_lay` (Task 1); `kc_bo_design <dir>`, `kc_khop_khoa <dir> test_files <p>`, `intake_base_dong <dir>`, `kc_mb <dir>`, `adr_thu_muc`, `luat_thu_muc`, `MAU_ERE_AWK`/`mau_ere(m, 0)` (nghĩa glob hiện hành của `Expected files`, như `kc_glob_rong`).
- Produces: `kt_duong_plan <thư-mục-feature>` → stdout các đường dẫn suy từ `Expected files:` (khử trùng, sắp xếp).

Quy tắc của `kt_duong_plan` (từ spec, chép đúng):
- token không có `*`, `?`, `[` → chính token;
- token có glob → file trong `git ls-tree -r --name-only <sha Base:>` khớp `mau_ere(token, 0)` **và** tiền tố thư mục trước ký tự glob đầu tiên (bỏ `/` cuối; rỗng thì bỏ);
- sha: phần sha của `Base:`; thiếu → `kc_mb`; không có commit → chỉ dùng tiền tố;
- bỏ đường dẫn khớp `test_files`, nằm trong thư mục ADR hoặc thư mục luật, hoặc `tm_bo`.

Nhánh `implement` của `tools/knowledge.sh`: `kc_bo_design "$DIR"` thành công và có `<adr>/README.md` → in nó trước; rồi `kt_duong_plan "$DIR" | kt_lay "$R" "$MT_CONV"`.

- [ ] **Step 1: Viết các ca (đỏ)**

```sh
dung "implement: Expected files src/* → ADR Scope src/*, luật, ARCHITECTURE cha; không ADR superseded/lib" \
  bang "$(sh "$KT" implement "$F" 2>/dev/null | tr '\n' ' ')" \
  "docs/adr/0001-x-dec-001.md docs/product/rules/billing.md src/ARCHITECTURE.md "
dung "implement: feature (có design) → không in chỉ mục ADR" sh -c "! sh '$KT' implement '$F' 2>/dev/null | grep -qx 'docs/adr/README.md'"
thay "$F/plan.md" '`src/*` `test/*`' '`src/moi/**` `test/*`'
dung "implement: thư mục mới chưa có trên base → vẫn khớp qua tiền tố" sh -c "sh '$KT' implement '$F' 2>/dev/null | grep -qx 'src/ARCHITECTURE.md'"
thay "$F/plan.md" '`src/moi/**` `test/*`' '`test/*` `docs/adr/*`'
dung "implement: chỉ file test và thư mục ADR → không in gì" bang "$(sh "$KT" implement "$F" 2>/dev/null)" ""
rm -f "$F/plan.md"
ky_vong 0 "implement: không có plan.md → ĐÃ LIỆT KÊ" sh "$KT" implement "$F"
# Base: thiếu sha → token glob chỉ dùng tiền tố
thay "$F/intake.md" "@ \`$(git -C "$R" rev-parse --short main)\`" ''
```
cộng một ca với `plan.md` khôi phục (`viet_plan`) sau khi bỏ sha: vẫn in `src/ARCHITECTURE.md`. Và nhóm `chore` (`tao_fixture chore chore_v` + `kt_fixture`): `implement` in `docs/adr/README.md` ở dòng đầu.

- [ ] **Step 2: Chạy, xác nhận đỏ**

Run: `sh tools/tests/26-knowledge-retrieval.sh`
Expected: FAIL ở các ca `implement` (lệnh trả `SAI THAM SỐ`).

- [ ] **Step 3: Viết `kt_duong_plan` và nhánh `implement`**; thêm `implement` vào `BL_KIEN_THUC`, chú thích đầu `tools/knowledge.sh`, `bin/aw-engine:13`.

- [ ] **Step 4: Chạy `26`, rồi `16` (ca "phase chưa hỗ trợ" dùng `plan`, vẫn SAI THAM SỐ)**

Run: `sh tools/run-tests.sh 26-knowledge-retrieval 16-journal-adr`
Expected: `MỌI CA ĐẠT`

- [ ] **Step 5: Commit** — `aw knowledge implement: kiến thức bền theo Expected files`

### Task 3: `aw knowledge review`

**Files:**
- Modify: `tools/knowledge.sh` (nhánh `review`; nạp các lib `kt_anh_huong` cần: `cross-check.sh`, `knowledge.sh` đã có từ Task 1)
- Test: `tools/tests/26-knowledge-retrieval.sh`

**Interfaces:**
- Consumes: `kt_anh_huong <dir>` → `"<tài liệu>|<0/1>|<file>"`.
- Produces: `aw knowledge review <dir>` → cột 1 của `kt_anh_huong`, khử trùng, giữ thứ tự.

- [ ] **Step 1: Viết các ca (đỏ)**

```sh
dung "review: chưa có diff → không in gì" bang "$(sh "$KT" review "$F" 2>/dev/null)" ""
echo moi > "$R/src/a.txt"
dung "review: diff đụng src/ → đúng tập kt_anh_huong" \
  bang "$(sh "$KT" review "$F" 2>/dev/null | sort | tr '\n' ' ')" \
  "docs/adr/0001-x-dec-001.md docs/product/rules/billing.md src/ARCHITECTURE.md "
echo x > "$R/lib/b.txt"
dung "review: diff đụng lib/ → thêm ADR 0003, lib/ARCHITECTURE.md" sh -c "sh '$KT' review '$F' 2>/dev/null | grep -qx 'lib/ARCHITECTURE.md'"
```
(Chuỗi mong đợi lấy từ `kt_ah` của `17-rule-crosscheck.sh` nếu khác — tập phải bằng tập `kt_anh_huong`.)

- [ ] **Step 2: Chạy, xác nhận đỏ** — `sh tools/tests/26-knowledge-retrieval.sh`, FAIL ở ca `review`.

- [ ] **Step 3: Viết nhánh `review`**; `BL_KIEN_THUC="spec design implement review"`.

- [ ] **Step 4: Chạy** `sh tools/run-tests.sh 26-knowledge-retrieval` → `MỌI CA ĐẠT`

- [ ] **Step 5: Commit** — `aw knowledge review: tài liệu mà diff đụng phạm vi`

### Task 4: Phase, interface, tag luật

**Files:**
- Modify: `workflow/phases/04-implement.md` (`## Loop`: dòng trước `aw ready`; `capabilities:` + `CAP-implement-07`)
- Modify: `workflow/phases/05-review.md:58` (đoạn **Durable knowledge**)
- Modify: `workflow/phases/02-design.md` (`capabilities:` + `CAP-design-04`)
- Modify: `sdlc/stages/04-implement.md`, `02-design.md`, `05-verify.md` (khối capability mới)
- Modify: `tools/check-review.sh:110-113` (`# giữ: CAP-verify-06` ngay trên dòng `while … loi_truoc "$l"` của khối `KT`), `tools/unclassified-rules.txt` (`tools/check-review.sh 38` → số `--dem-luat` in)
- Test: `tools/tests/08-adapters.sh`, `tools/tests/25-sdlc-capabilities.sh`

Khối capability (chép đúng, theo dạng `### CAP-… — …` / `- Rule:` / `- Judged by:` / `- Artifact:`):
- `CAP-implement-07 — Durable knowledge in scope of the planned files is retrieved before building`; Rule: `the set of durable-knowledge documents is computed by the machine from the task plan's files, not chosen by the agent, and is read before the first task starts.`; Judged by: `agent`; Artifact: `change`.
- `CAP-design-04 — Design reads durable knowledge in scope of the code it surveys`; Rule: `the machine computes the documents from the paths the design records as existing code; the design reads them before deciding.`; Judged by: `agent`; Artifact: `design`.
- `CAP-verify-06 — Every durable-knowledge document whose scope the change touches has a review verdict`; Rule: `for each document whose scope the change touches, the review records whether it is still true, was updated in the change, or does not apply with a reason; a missing verdict blocks.`; Judged by: `machine`; Artifact: `review-report`.

Text phase (tiếng Anh, chép đúng):
- `04-implement.md`, ngay trên khối ```` ``` ```` của Loop: `**Before the first task:** \`aw knowledge implement <dir>\` — read every file it prints.`
- `05-review.md`, đầu đoạn Durable knowledge: thêm `Read them first: \`aw knowledge review <dir>\` prints the same set.` ngay sau cụm `(\`aw check review\` lists them)`.

- [ ] **Step 1: Ca test (đỏ)**
  - `08-adapters.sh`: lệnh implement sinh ra chứa `aw knowledge implement`; lệnh review chứa `aw knowledge review` (grep trên output `build.sh --out`, như ca khác của phần này).
  - `25-sdlc-capabilities.sh`: `CAP-implement-07`, `CAP-design-04`, `CAP-verify-06` có trong stage file và được phase nhận (theo khuôn ca hiện có của phần).

- [ ] **Step 2: Chạy, xác nhận đỏ** — `sh tools/run-tests.sh 08-adapters 25-sdlc-capabilities`

- [ ] **Step 3: Sửa phase, stage file, `capabilities:`, tag `# giữ:`; chạy `sh tools/check-sdlc.sh --dem-luat`, chép số của `tools/check-review.sh` vào `tools/unclassified-rules.txt`.**

- [ ] **Step 4: Chạy** `sh tools/check-sdlc.sh` → `[x] ĐẠT`; bảng "Stage → phase" vẫn `implemented` cho design, implement và `partial` cho verify (khối § 6 của `docs/interface-sdlc.md` không đổi — `20-sdlc-conformance` kiểm). Rồi `sh tools/run-tests.sh` → `MỌI CA ĐẠT`.

- [ ] **Step 5: Commit** — `Phase implement/review đọc aw knowledge; CAP-implement-07, CAP-design-04, CAP-verify-06`

### Task 5: Tài liệu người đọc

**Files:**
- Modify: `docs/huong-dan.md:878` (bảng § 7, dòng "Việc sau đọc": ADR → `design, implement, review`; BR → `spec, design, implement, review`) và đoạn dưới bảng một câu: việc bỏ design vẫn đọc chỉ mục ADR ở implement.
- Modify: `docs/kien-truc.md:212` (thay "cách nạp theo phạm vi diff là bước sau" bằng: `aw knowledge implement` theo `Expected files`, `aw knowledge review` theo diff — cùng tập review chấm verdict), `:258` (`aw knowledge` gọi ở spec, design, implement, review; implement và review không có luật chặn mới vì máy không kiểm được agent đã đọc).
- Modify: `docs/superpowers/2026-10-22-roadmap-cai-thien.md` (dòng SP20: `xong`, cột Plan link file này, cột PR).
- Create: `changes/<branch>.md` — `### Thêm`: `aw knowledge implement` / `review`, ai được lợi (`chore`, `Design: skip` giờ đọc ADR); `### Nội bộ`: `kt_lay`, ba capability, tag `CAP-verify-06`.

- [ ] **Step 1: Sửa các file trên.**
- [ ] **Step 2: Chạy** `sh tools/check-release.sh` → ĐẠT (mảnh changelog đúng dạng); `sh tools/run-tests.sh` → `MỌI CA ĐẠT` (docs có thể bị test grep).
- [ ] **Step 3: Commit** — `Docs SP20`; PR mô tả: `Interface: CAP-implement-07, CAP-design-04, CAP-verify-06`.
