# Gộp SP28 + SP19 (19c–19g) + việc nhỏ — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Một PR gồm mọi việc trên roadmap không chờ ai quyết (người chọn 2026-10-25, trái nguyên tắc 4
"một dự án con = một PR" có chủ ý): SP28, SP19 đợt 19c–19g, dọn lỗi nhỏ SP27, `[ISSUE]` cho URL khác.

**Architecture:** Mỗi task một commit, độc lập trừ chỗ ghi ở Interfaces. Task 1 đổi `check-implement.sh`
trước khi Task 6 gắn tag file đó.

**Tech Stack:** POSIX sh + awk + sed + git (`AGENTS.md` § Code).

**Spec:**
- SP28: `docs/superpowers/specs/2026-10-23-sp26-30-rag-markdown-design.md` § C
- SP19: `docs/superpowers/specs/2026-10-23-sp19-gan-id-con-lai-design.md` §§ 2–6
- Việc nhỏ: roadmap § Việc nhỏ; review cuối SP27 (PR #107, các mục M1, M3, Task 1 minors)

## Quyết định thay người (cần người duyệt plan này)

1. SP19 § 7: gộp 19c–19g vào PR này (người đã chọn); cột `Serves` của stage khác **chặn** (đề xuất của spec).
2. SP19 § 3 bước 4: chỗ luật không khớp id nào → để nguyên (vẫn đếm), liệt kê trong mô tả PR; không gắn id gần đúng, không thêm capability trong PR này.
3. `[ISSUE]` dạng mới (giữ nhãn `[ISSUE]`, không khoá conventions mới):
   GitLab `…/-/work_items/N` (mọi host); GitHub `github.com` hoặc host origin `/<o>/<r>/discussions/N`;
   Bitbucket `bitbucket.org/<w>/<r>/(issues|pull-requests)/N`; Gitea/Forgejo chỉ host origin `/<o>/<r>/(issues|pulls)/N`.
4. SP28 thêm `INV-012` (thêm invariant, không làm yếu interface).

## Global Constraints

- POSIX sh + awk + sed + git; ERE không `{n}`; chuỗi có `\`/nhiều dòng vào awk qua `ENVIRON`; `case` trong `$(…)` viết `(pattern)`.
- Mỗi luật chặn/cảnh báo mới có `# giữ: …` ngay trên (phủ đúng một chỗ luật); `tools/unclassified-rules.txt` chỉ giảm khi gắn đúng.
- Output `aw`, docs, `changes/`: tiếng Việt; text phase/checker: tiếng Anh.
- Repo không có `docs/knowledge-index.md` trong git → hành vi y như cũ.
- Kết thúc: `sh tools/run-tests.sh` → `MỌI CA ĐẠT`, không `nên tách`; `sh tools/check-sdlc.sh` → ĐẠT; `AW_COMPARE=1` byte-identical.

## Review Focus

- Chỉ mục hỏng sẵn trên `Base:` mà diff không đụng tài liệu kiến thức → không chặn. Test ở Task 2.
- Heading `## ` nằm trong khối code ``` của tài liệu module → không thành mục, không thành ref. Test ở Task 1.
- URL `github.com/<o>/<r>/discussions/N` có `?query`/`#frag` → vẫn `[ISSUE]`. Test ở Task 3.
- Gắn tag một dòng phủ nhiều luật (khối chung như `cb=`) → không được hạ số đếm. Kiểm ở Task 4–6 bằng `--dem-luat` trước/sau.
- Hàm thư viện tên `kt_*` không trả finding (vd `kt_muc`, `kt_khoi`) → 19g đếm nhầm. Task 8 chốt danh sách tên theo spec § 4 và test.

---

### Task 1: Dọn lỗi nhỏ SP27

**Files:** Modify `tools/lib/knowledge.sh`, `tools/check-implement.sh`, `tools/check-review.sh`, `tools/knowledge.sh`; Test `tools/tests/28-knowledge-sections.sh`

**Interfaces:** Produces: `kt_loi_muc`, `kt_canh_bao_muc`, `kt_canh_bao`, `kt_loi_review` nhận thêm tham số tuỳ chọn = output `kt_anh_huong` đã tính (rỗng → tự tính). Checker tính `kt_anh_huong` một lần.

- [ ] Test: (a) `## X` trong khối ``` không ra ref, `show` không cắt ở đó; (b) heading `## ` rỗng có `- Scope:` → `kt_phan_con` vẫn in nội dung; (c) `aw knowledge show ../x` → SAI THAM SỐ; (d) `check-implement` gọi `kt_anh_huong` đúng một lần (đếm bằng biến môi trường thử nghiệm hoặc stub hàm trong test).
- [ ] RED → code → GREEN (`28`, `17`, `05-review-quality`) → commit `fix(knowledge): dọn lỗi nhỏ SP27 (khối code, heading rỗng, ../, tính ảnh hưởng một lần)`.

### Task 2: SP28 — chỉ mục kiến thức chung

**Files:** `tools/lib/knowledge.sh` (`kt_lam_chi_muc`, `kt_loi_chi_muc`), `tools/knowledge.sh` (`index`, `check`), `tools/check-implement.sh`, `tools/check-review.sh`, `tools/adr.sh`/`tools/rule.sh` (promote dựng lại), `tools/lib/config.sh` / `check-conventions.sh` (khoá `knowledge_index`), `workflow/templates/conventions.md` + `conventions-reference.md`, `workflow/templates/target-repo/AGENTS.md`, `workflow/phases/01-spec.md`, `02-design.md`, `/aw-bootstrap` (`workflow/bootstrap.md` hoặc tương ứng), `sdlc/invariants.md` (`INV-012`), tests `26-knowledge-retrieval.sh` (hoặc phần mới `29-knowledge-index.sh` nếu 26 chậm), `22-sdlc-stage-files.sh`.

**Interfaces:** `kt_lam_chi_muc <gốc> <conv>` → bảng `| Ref | Kind | Scope | Status | Summary |` (sau phần người viết, như `adr_lam_chi_muc`); `kt_loi_chi_muc <dir>` → lỗi khi bảng lệch dựng lại, chỉ khi file có trong git và diff đụng tài liệu kiến thức hoặc chỉ mục; gộp cảnh báo heading trùng của SP27 thành chặn tại đây (Đã chốt 3 của § B).

- [ ] Test theo spec § C **Test** (6 ca) + heading trùng bị `aw knowledge check` chặn + `design|implement` in chỉ mục chung thay `<adr>/README.md` khi có.
- [ ] RED → code → GREEN → `check-sdlc` ĐẠT → commit `feat(knowledge): chỉ mục kiến thức chung (SP28, INV-012)`.

### Task 3: `[ISSUE]` cho URL khác

**Files:** `tools/input.sh` (`la_issue` + chú thích), test phần đang test `la_issue` (grep `ISSUE` trong `tools/tests/`).

- [ ] Test: mỗi dạng ở Quyết định 3 → `[ISSUE]`; Gitea dạng `pulls` trên host lạ (không phải origin) → không `[ISSUE]`; Bitbucket host khác `bitbucket.org` → không; query/fragment bị bỏ.
- [ ] RED → code → GREEN → commit `feat(input): [ISSUE] cho work item GitLab, discussion GitHub, Bitbucket, Gitea`.

### Task 4: SP19 đợt 19c — `check-spec.sh`

**Files:** `tools/check-spec.sh`, `tools/unclassified-rules.txt`.

- [ ] `sh tools/check-sdlc.sh --dem-luat` ghi số trước. Gắn `# giữ:` từng chỗ theo spec SP19 § 3; chỗ không khớp → ghi vào report (Quyết định 2). Hạ số; xoá dòng khi về 0.
- [ ] `check-sdlc` ĐẠT, `run-tests` các phần `01-…`/spec ĐẠT → commit `chore(sdlc): gắn id luật check-spec (19c)`.

### Task 5: SP19 đợt 19d — `check-plan.sh`, `check-design.sh`

Như Task 4. Commit `chore(sdlc): gắn id luật check-plan, check-design (19d)`.

### Task 6: SP19 đợt 19e — `check-implement.sh`, `check-review.sh`

Như Task 4; sau Task 1–2 (cùng file). Commit `chore(sdlc): gắn id luật check-implement, check-review (19e)`.

### Task 7: SP19 đợt 19f — cột `Serves` của checker LLM

**Files:** `workflow/checkers/*.md`, `tools/check-sdlc.sh`, `tools/tests/23-sdlc-syntax.sh`.

- [ ] Test theo spec § 5 (thiếu `Serves`, id lạ, id stage khác → chặn; đúng → đạt); `AW_COMPARE=1` vẫn giống hệt.
- [ ] RED → code → GREEN → commit `feat(sdlc): cột Serves cho checker LLM (19f)`.

### Task 8: SP19 đợt 19g — đếm hàm thư viện

**Files:** `tools/check-sdlc.sh` (`dem_luat`), `tools/unclassified-rules.txt`, `tools/tests/23-sdlc-syntax.sh`.

- [ ] Test theo spec § 4 (4 ca). Tên đếm: `kc_*`, `tk_*`, `kt_loi*`, `kt_canh_bao*`, `adr_loi*`, `toc_loi` — `kt_*` khác (đọc/tính, không trả finding) không đếm (Review Focus 5; ghi vào changes).
- [ ] RED → code → GREEN → thêm dòng `tools/lib/*.sh <n>` bằng `--dem-luat` → commit `feat(sdlc): đếm luật trong tools/lib (19g)`.

### Task 9: Tài liệu và hoàn tất

**Files:** `changes/claude-dazzling-tesla-x1iwj2.md` (mảnh mới cho PR này — file cũ đã phát hành? kiểm `git log`; nếu còn trên main thì thêm mục), `docs/huong-dan.md` § 7, `docs/kien-truc.md` (chỉ mục; mục 22 bước A), `docs/interface-sdlc.md` (`# giữ:` cho lib, cột `Serves`), `docs/thuat-ngu.md` + `workflow/rules/terms.md` nếu thêm thuật ngữ, roadmap (SP28 `xong`/link PR sau merge; SP19 `xong`; bỏ hai dòng § Việc nhỏ đã làm).

- [ ] Sửa tài liệu; `git fetch origin && git merge origin/main`; `sh tools/run-tests.sh` → MỌI CA ĐẠT; `sh tools/check-sdlc.sh` → ĐẠT.
- [ ] Commit `docs: SP28, SP19 xong, việc nhỏ — hướng dẫn, kiến trúc, interface, changes`; push; mở PR với danh sách chỗ luật chưa gắn (Quyết định 2) và dòng "Interface: INV-012 (mới); CAP-… gắn tag; không bỏ/nới capability".
