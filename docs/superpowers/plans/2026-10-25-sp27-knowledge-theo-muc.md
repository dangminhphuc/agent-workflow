# SP27 — Durable knowledge theo mục và khối ID Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `aw knowledge` và cross-check stale làm việc ở mức **ref** (`<file>` hoặc `<file>#<neo>`) thay vì cả file:
tài liệu module chia theo mục `##` có `- Scope:`, luật `BR-` theo khối ID.

**Architecture:** Thêm hai hàm đọc mục ở `tools/lib/knowledge.sh` (`kt_muc` liệt kê mục khai `Scope` kèm dải
dòng, `kt_khoi` in một khối). `kt_tai_lieu` / `kt_lay` phát ref thay cho file; `kt_anh_huong` tính theo ref,
cột "đổi" của ref có neo = diff đổi dòng trong dải của khối. `aw knowledge show <ref>…` in khối; phase đọc
qua `show`. Tài liệu không khai mục nào → ref `<file>`, output như cũ.

**Tech Stack:** POSIX sh + awk + sed + git (`AGENTS.md` § Code).

**Spec:** `docs/superpowers/specs/2026-10-23-sp26-30-rag-markdown-design.md` § B (kể cả **Đã chốt** 1–7)

## Global Constraints

- POSIX sh + awk + sed + git; không bashism; ERE không `{n}`; awk nhiều file dùng `FILENAME == ARGV[i]`;
  chuỗi nhiều dòng / có `\` vào awk qua `ENVIRON`, không `-v`; `case` trong `$(…)` viết `(pattern)`.
- Ref = `<file>` hoặc `<file>#<neo>`; neo = phần sau `#` **đầu tiên**. Neo tài liệu module = heading `##`
  nguyên văn (sau `## `, bỏ khoảng trắng hai đầu); neo luật = ID `BR-…`. ADR luôn là `<file>`.
- `- Scope:` của mục = dòng không trống đầu tiên dưới heading `##`; mục `###` không khai được.
- Khối: từ heading tới heading cùng cấp hoặc cao hơn kế tiếp (luật: heading `###` của nó).
- Tài liệu không có mục nào khai `Scope` → mọi output y như trước SP27 (ca hồi quy, từng byte).
- Hàm/biến shell: tiếng Việt không dấu, tiền tố `kt_` / `_k…`. Output `aw`, docs, `changes/`: tiếng Việt;
  text phase: tiếng Anh, mệnh lệnh, không nhắc lại điều checker kiểm.
- Mỗi chỗ chặn/cảnh báo mới có `# giữ: CAP-verify-06` (hoặc `CAP-implement-07`) ngay trên.
- Không thêm capability; Rule của `CAP-verify-06`, `CAP-implement-07` không đổi.
- Kết thúc: `sh tools/run-tests.sh` → `MỌI CA ĐẠT`; `sh tools/check-sdlc.sh` → ĐẠT; không phần test nào
  in `CẢNH BÁO … nên tách`.

## Review Focus

- Heading có khoảng trắng cuối dòng hoặc `\r` (file CRLF) → neo vẫn là heading đã trim; `show` tìm thấy. Test ở Task 1.
- Heading có dấu tiếng Việt (`## Thanh toán`) → ref nguyên văn, `show` khớp byte (`LC_ALL=C`). Test ở Task 1.
- Heading chứa `#` (`## Mục #2`) → neo là `Mục #2` (cắt ở `#` đầu của ref, không phải `#` cuối). Test ở Task 1.
- Mục khai `Scope` là mục cuối file → khối kéo tới hết file, dải dòng đúng. Test ở Task 3.
- Diff xoá hẳn một mục có `Scope` (có trên `Base:`, không còn trên cây làm việc) → ref vẫn cần verdict, cột đổi = 1. Test ở Task 3.

---

### Task 1: Đọc mục — `kt_muc`, `kt_khoi`, `aw knowledge show`

**Files:**
- Modify: `tools/lib/knowledge.sh` (thêm hai hàm trước `kt_lay`)
- Modify: `tools/knowledge.sh` (nhánh `show`, chú thích đầu file, `BL_KIEN_THUC`)
- Modify: `bin/aw-engine` (dòng trợ giúp `aw knowledge`)
- Create: `tools/tests/28-knowledge-sections.sh` (fixture riêng; không thêm vào `26-` để khỏi chậm)

**Interfaces:**
- Produces: `kt_muc <file>` → stdout mỗi mục `##` khai `Scope` một dòng
  `<neo>\t<dòng đầu>\t<dòng cuối>\t<glob…>` (glob bỏ backtick, cách nhau một dấu cách). Đọc stdin khi
  `<file>` là `-` (để Task 3 đưa nội dung `git show <sha>:<file>`).
- Produces: `kt_khoi <file> <neo>` → in khối; mã 1 khi không có. Neo `BR-…` tìm heading `### BR-…:`;
  neo khác tìm heading `##` khớp nguyên văn, mục trùng lấy mục đầu.
- Produces: `kt_phan_con <file>` → in file trừ các khối mà `kt_muc` liệt kê.
- Produces: `aw knowledge show <ref>…` (chạy ở gốc repo `MT_REPO`): in từng ref, mỗi khối mở bằng dòng
  `==> <ref> <==`. Ref `<file>` của tài liệu có mục khai → `kt_phan_con`. Ref/file/neo không có →
  `SAI THAM SỐ`, không in phần nào.

- [ ] **Step 1: Viết test** (`28-knowledge-sections.sh`, nhóm "knowledge show"): fixture `src/ARCHITECTURE.md`
  có `## Tổng quan` (không Scope), `## Thanh toán ` (khoảng trắng cuối, `- Scope: \`src/pay/*\``),
  `## Mục #2` (`- Scope: \`src/b/*\``), file luật có `BR-BILLING-001`, `BR-BILLING-002`. Ca:
  - `kt_muc` in đúng 2 dòng, neo `Thanh toán` và `Mục #2`, dải dòng đúng; mục cuối kéo tới dòng cuối file;
  - bản CRLF của cùng file → cùng output `kt_muc`;
  - `show 'src/ARCHITECTURE.md#Thanh toán'` in heading + `- Scope:` và không chứa `## Mục #2`;
  - `show 'src/ARCHITECTURE.md#Mục #2'` thấy khối;
  - `show src/ARCHITECTURE.md` có `## Tổng quan`, không có `## Thanh toán`;
  - `show 'docs/product/rules/billing.md#BR-BILLING-002'` có `BR-BILLING-002`, không có `BR-BILLING-001`;
  - `ky_vong 2` cho neo không có, file không có, không tham số;
  - hai mục cùng heading → `show` in mục đầu.
- [ ] **Step 2:** `sh tools/tests/28-knowledge-sections.sh` → các ca mới KHÔNG ĐẠT.
- [ ] **Step 3:** Viết `kt_muc`, `kt_khoi`, `kt_phan_con` (một awk mỗi hàm; `sub(/\r$/, "")` từng dòng) và nhánh
  `show`; khai nhãn có sẵn của `knowledge.sh`.
- [ ] **Step 4:** Chạy lại phần 28 → ĐẠT; `sh tools/run-tests.sh 26-knowledge-retrieval` vẫn ĐẠT.
- [ ] **Step 5:** Commit `feat(knowledge): aw knowledge show <ref> — đọc khối theo mục và ID luật`.

### Task 2: Truy xuất phát ref

**Files:**
- Modify: `tools/lib/knowledge.sh` (`kt_lay`, `kt_tai_lieu`)
- Modify: `tools/knowledge.sh` (nhánh `spec`)
- Modify: `workflow/phases/01-spec.md:56`, `02-design.md:70`, `04-implement.md:50`, `05-review.md:59`
- Test: `tools/tests/28-knowledge-sections.sh`, sửa ca grep tên file luật ở `tools/tests/26-knowledge-retrieval.sh`

**Interfaces:**
- Consumes: `kt_muc` (Task 1).
- Produces: `kt_tai_lieu <gốc> <conv>` → `<ref>|<glob…>`: tài liệu không khai mục → `<file>|<dir>/*` (như cũ);
  có khai → mỗi mục `<file>#<neo>|<glob mục>` cộng `<file>|<dir>/*`; luật → `<file>#<BR-ID>|<scope luật>`
  (thay dòng hợp scope của cả file); ADR như cũ.
- Produces: `kt_lay` in ref theo cùng quy tắc (đường dẫn trong thư mục → `<file>`; khớp glob mục → `<file>#<neo>`;
  luật active khớp → `<file>#<BR-ID>`).

- [ ] **Step 1: Viết test**: tài liệu không khai mục → `design`/`implement` in `src/ARCHITECTURE.md` (byte như
  trước); token `src/pay/x.txt` → in cả `src/ARCHITECTURE.md#Thanh toán` và `src/ARCHITECTURE.md`; token
  `src/b/y.txt` không in `#Thanh toán`; `spec` in `docs/product/rules/billing.md#BR-BILLING-001` và `#BR-BILLING-002`,
  không in dòng file trần; luật `deprecated` không in; mỗi ref một lần; lệnh phase sinh ra chứa
  `aw knowledge show` (grep như `08-adapters`).
- [ ] **Step 2:** Chạy phần 26 và 28 → ca mới KHÔNG ĐẠT, ca ref luật cũ ở 26 đã sửa theo output mới KHÔNG ĐẠT.
- [ ] **Step 3:** Sửa `kt_tai_lieu`, `kt_lay`, nhánh `spec`; bốn phase đổi "read every file it prints" thành
  "`aw knowledge show` every ref it prints".
- [ ] **Step 4:** `sh tools/run-tests.sh 26-knowledge-retrieval 28-knowledge-sections 08-adapters` → ĐẠT.
- [ ] **Step 5:** Commit `feat(knowledge): spec/design/implement/review in ref theo mục và ID luật`.

### Task 3: Cross-check stale theo ref

**Files:**
- Modify: `tools/lib/knowledge.sh` (`kt_anh_huong`, `kt_canh_bao`, `kt_loi_review`)
- Test: `tools/tests/17-rule-crosscheck.sh` (helper `kt_ah` đọc cột 1,2 — giữ), `28-knowledge-sections.sh`

**Interfaces:**
- Consumes: `kt_muc` (đọc `-` cho bản trên `Base:`), `kt_tai_lieu` (Task 2).
- Produces: `kt_dong_doi <thư-mục-feature> <file>` → số dòng (trên cây làm việc) diff thêm/sửa, từ
  `git diff -U0 <base> -- <file>`; dòng xoá ghi số dòng kề sau nó.
- Produces: `kt_anh_huong` giữ dạng `<ref>|<0|1>|<file đổi trong phạm vi>`; tập ref = hợp ref trên cây làm
  việc và ref trên `Base:` (Đã chốt 5). Cột 2 của `<file>#<neo>` = 1 khi: khối có ở cả hai bên và
  `kt_dong_doi` có dòng trong dải; hoặc neo chỉ có ở một bên (đổi tên / thêm / xoá). Ref `<file>` giữ nghĩa
  "file đổi". Luật `BR-` có neo dùng cùng quy tắc với dải khối luật.

- [ ] **Step 1: Viết test** (fixture hai mục khai): diff đụng `src/pay/x.txt` → `kt_anh_huong` có
  `#Thanh toán`, không có `#Mục #2`; `aw check implement` cảnh báo stale chỉ cho `#Thanh toán`;
  sửa dòng trong `## Mục #2` + review ghi `#Thanh toán` `updated` → `aw check review` KHÔNG ĐẠT;
  sửa dòng trong `## Thanh toán` → ĐẠT; mục cuối file sửa dòng cuối → ĐẠT; đổi tên heading
  `## Thanh toán` → `## Thanh toán 2` → cả hai ref cần verdict, cả hai cột đổi = 1; xoá hẳn mục → ref
  cũ cần verdict; review chỉ ghi `src/ARCHITECTURE.md` (file trần) cho ref có neo → KHÔNG ĐẠT (Đã chốt 4);
  tài liệu không khai mục → `17-rule-crosscheck` không đổi.
- [ ] **Step 2:** Chạy phần 17 và 28 → ca mới KHÔNG ĐẠT.
- [ ] **Step 3:** Viết `kt_dong_doi`; sửa `kt_anh_huong`; câu `kt_canh_bao` khi file đổi mà khối không đổi:
  "durable knowledge có thể stale: diff đụng <p> (phạm vi của <ref>) mà khối <ref> không đổi — …"; `kt_loi_review`
  so cột `File` với ref, câu `updated`: "verdict \"updated\" nhưng diff không đổi dòng nào trong khối này".
- [ ] **Step 4:** `sh tools/run-tests.sh 17-rule-crosscheck 28-knowledge-sections 05-review-quality` → ĐẠT.
- [ ] **Step 5:** Commit `feat(knowledge): cross-check stale và verdict theo ref`.

### Task 4: Vệ sinh mục — heading trùng, `|` trong heading

**Files:**
- Modify: `tools/lib/knowledge.sh` (thêm `kt_loi_muc`, `kt_canh_bao_muc`)
- Modify: `tools/check-implement.sh:187` (cảnh báo), chỗ gom lỗi của `tools/check-implement.sh` và `tools/check-review.sh:115` (lỗi)
- Test: `tools/tests/28-knowledge-sections.sh`

**Interfaces:**
- Produces: `kt_canh_bao_muc <thư-mục-feature>` → mỗi tài liệu trong `kt_anh_huong` có hai mục `##` cùng
  heading: "<file>: hai mục \"## <h>\" — ref <file>#<h> chỉ trỏ mục đầu; đổi tên một mục" (Đã chốt 3).
- Produces: `kt_loi_muc <thư-mục-feature>` → mỗi mục khai `Scope` có `|` trong heading:
  "<file>: heading \"## <h>\" có ký tự | — làm vỡ bảng \"## Durable knowledge\"; đổi tên mục" (Đã chốt 6).

- [ ] **Step 1: Viết test**: heading trùng → `check-implement` có cảnh báo, vẫn ĐẠT; mục khai `Scope` có `|`
  → `check-implement` và `check-review` KHÔNG ĐẠT; mục **không** khai `Scope` có `|` → không lỗi.
- [ ] **Step 2:** Chạy phần 28 → KHÔNG ĐẠT.
- [ ] **Step 3:** Viết hai hàm; gắn `# giữ: CAP-verify-06` trên mỗi chỗ gọi mới; `sh tools/check-sdlc.sh` ĐẠT.
- [ ] **Step 4:** Phần 28 ĐẠT.
- [ ] **Step 5:** Commit `feat(knowledge): chặn | trong heading mục, cảnh báo heading trùng`.

### Task 5: Tài liệu và hoàn tất

**Files:**
- Modify: `workflow/templates/conventions-reference.md` § `knowledge_files` (Scope theo mục, ref)
- Modify: `workflow/templates/review.md` (chú thích `## Durable knowledge`: cột `File` nhận ref)
- Modify: `docs/huong-dan.md` § 7, `docs/kien-truc.md` § Cross-check stale, `docs/thuat-ngu.md` (thêm "ref")
- Modify: `changes/claude-dazzling-tesla-x1iwj2.md` (`Thêm`: `aw knowledge show`, Scope theo mục; `Thay đổi`:
  `aw knowledge` in `<file>#BR-…`, verdict cũ ở mức file không phủ ref có neo — việc đang dở ghi lại verdict)
- Modify: roadmap — dòng SP27 trạng thái `đang làm`, cột Plan trỏ file này

- [ ] **Step 1:** Sửa các tài liệu trên; grep test nào đọc chuỗi đã đổi (`grep -rn 'read every file' tools/tests`) và sửa cùng commit.
- [ ] **Step 2:** `git fetch origin && git merge origin/main`; `sh tools/run-tests.sh` → `MỌI CA ĐẠT`, không `nên tách`;
  `sh tools/check-sdlc.sh` → ĐẠT.
- [ ] **Step 3:** Commit `docs(knowledge): ref theo mục — hướng dẫn, kiến trúc, thuật ngữ, changes`; push; mở PR
  (spec + plan + code), dòng "Interface: CAP-verify-06, CAP-implement-07 (mịn hơn, Rule không đổi)".
