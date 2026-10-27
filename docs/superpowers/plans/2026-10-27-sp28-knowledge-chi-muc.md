# SP28 — Chỉ mục kiến thức chung Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chỉ mục chung `docs/knowledge-index.md` — bảng máy dựng lại từ mọi kiến thức bền (ADR, luật
`BR-`, mục tài liệu module khai `Scope`), để kiến thức không gắn đường dẫn (luật xuyên module, quyết
định toàn repo) tìm được mà agent không phải đọc hết. Máy dựng lại rồi so chính xác; bảng lệch dựng
lại → chặn.

**Architecture:** Thêm `kt_chi_muc_du` (in bảng dựng lại ra stdout) và `kt_chi_muc_kiem` (so bảng
trong file chỉ mục với dựng lại, kèm chặn heading trùng — nâng cảnh báo SP27 lên chặn) ở
`tools/lib/knowledge.sh`. `aw knowledge index` dựng lại file (giữ phần người viết phía trên bảng,
như `adr_lam_chi_muc`); `aw knowledge check` là checker, được `aw check implement` / `aw check review`
gọi khi diff đụng tài liệu kiến thức hoặc chính file chỉ mục. Khoá `conventions.md` mới
`knowledge_index`, mặc định `docs/knowledge-index.md`, trống = tắt; chỉ kiểm khi file chỉ mục đã có
trong git.

**Tech Stack:** POSIX sh + awk + sed + git (`AGENTS.md` § Code).

**Spec:** `docs/superpowers/specs/2026-10-23-sp26-30-rag-markdown-design.md` § C (kể cả **Đã chốt**:
khoá có giá trị mặc định nhưng máy chỉ kiểm khi file đã có trong git — không ép repo cũ).

## Lệch spec (để người duyệt plan xác nhận)

- **Invariant id.** Spec viết `INV-012`, nhưng SP35 (#109, 2026-10-26) đã chiếm INV-012. Plan này dùng
  **INV-013** — "The knowledge index is rebuilt from the documents it lists", Checked by:
  `aw knowledge check`, test: `29-knowledge-index.sh`.
- **File test.** Spec viết test `26`; ca mới cho vào part **`29-knowledge-index.sh`** (fixture riêng)
  — cùng lý do plan SP27 tách part `28`: không nhồi vào part sẵn chậm, tách theo biên fixture.
- **Cột `Status` của dòng `module`.** Spec không nói; đề nghị: ADR → trường `Status` của ADR, luật →
  `Status:` của khối `BR-`, mục module → hằng `active` (tài liệu module không có trường status).
  Người duyệt plan chốt.
- **`Summary` chứa `|`.** Cột sẽ vỡ bảng markdown → khi dựng, máy thay `|` trong Summary bằng dấu chấm
  phẩy và trim khoảng trắng hai đầu. Người duyệt plan chốt: thay ký tự, không chặn.

## Global Constraints

- POSIX sh + awk + sed + git; không bashism; ERE không `{n}`; awk nhiều file dùng `FILENAME == ARGV[i]`;
  chuỗi nhiều dòng / có `\` vào awk qua `ENVIRON`, không `-v`; `case` trong `$(…)` viết `(pattern)`.
- Khoá `knowledge_index`: đọc bằng `conv_get` (`tools/lib/md.sh:144`); không khai hay khai trống = tắt;
  không khai và khai đúng giá trị mặc định `docs/knowledge-index.md` thì hành vi như nhau.
- Bảng chỉ mục: `| Ref | Kind | Scope | Status | Summary |`; `Kind` ∈ `adr | rule | module`; `Ref` =
  `<file>` hoặc `<file>#<neo>` (SP27); hàng xếp theo `Kind` (alphabetical: `adr` < `module` < `rule`),
  trong một Kind xếp theo `Ref`.
  - ADR → Ref `<file>`; `Summary` = tiêu đề ADR; `Status` = trường `Status` của ADR; `Scope` = trống.
  - Luật → Ref `<file>#<BR-ID>`; `Summary` = câu đầu của `Rule:`; `Status` = `Status:` của khối;
    `Scope` = phạm vi của luật (như `aw knowledge spec` in).
  - Mục module → Ref `<file>#<neo>` (chỉ mục khai `- Scope:`); `Summary` = dòng `- Summary:` của mục
    nếu có, không thì heading nguyên văn; `Scope` = glob của mục; `Status` = hằng `active` (điểm
    chốt trạng thái ở đầu plan).
- Ref/heading và mọi cột là nguyên văn byte (`LC_ALL=C`); dựng lại quyết định đúng–sai, không đoán
  gần đúng.
- `aw knowledge index` khi khoá tắt → `SAI THAM SỐ`; `aw knowledge check` khi khoá tắt → không kiểm
  gì, ĐẠT.
- "File chỉ mục đã có trong git" = tracked ở HEAD (hoặc trên `Base:`). Chỉ mục hỏng sẵn trên `Base:`
  mà diff của feature không đụng tài liệu kiến thức lẫn file chỉ mục → không chặn (như hình thức thư
  mục ADR).
- Heading trùng trong một tài liệu có mục khai `Scope`: SP27 đã cảnh báo (`kt_canh_bao_muc`,
  `tools/check-implement.sh:203`) — **giữ** cảnh báo đó; `aw knowledge check` nâng thành **chặn** khi
  diff đụng tài liệu (spec § B Đã chốt 3).
- Hàm/biến shell: tiếng Việt không dấu, tiền tố `kt_`. Output `aw`, docs, `changes/`: tiếng Việt;
  text phase: tiếng Anh, mệnh lệnh, không nhắc lại điều checker kiểm.
- Mỗi chỗ chặn/cảnh báo mới có `# giữ:` ngay trên: `# giữ: CAP-implement-07` (lỗi/cảnh báo in ở
  `aw check implement`), `# giữ: CAP-verify-06` (ở `aw check review`), kèm `, INV-013` ở chỗ luật mới
  theo invariant. Không thêm capability; Rule của `CAP-implement-07`, `CAP-verify-06` không đổi.
- Kết thúc: `sh tools/run-tests.sh` → `MỌI CA ĐẠT`; `sh tools/check-sdlc.sh` → ĐẠT; không part test
  nào in `CẢNH BÁO … nên tách`.

## Review Focus

- Repo không khai khoá và chưa có file chỉ mục → mọi lệnh như trước SP28 (hồi quy từng byte). Test ở
  Task 1.
- Khoá khai trống (`knowledge_index:` hay `knowledge_index: ""`) → tắt: `aw knowledge index` SAI THAM
  SỐ, `aw knowledge check` không kiểm. Test ở Task 1, Task 3.
- `Summary` chứa `|` (tiêu đề ADR hoặc câu `Rule:` dài có dấu `|`) → bảng vẫn dựng đúng một hàng.
  Test ở Task 1.
- Cột `Ref` với neo chứa khoảng trắng / tiếng Việt (`#Thanh toán`, `## Thanh toán ` có khoảng trắng
  cuối) giữ nguyên văn.
  Test ở Task 1.
- Chỉ mục đúng trên `Base:`, diff sửa một tài liệu → check vẫn chạy (điều kiện là "diff đụng", không
  phải "chỉ mục sai"). Test ở Task 3.
- Diff xoá hẳn một tài liệu mà chỉ mục còn hàng của nó → check chặn cho tới khi chỉ mục dựng lại.
  Test ở Task 3.
- Dựng lại là bất biến: chạy `aw knowledge index` hai lần liên tiếp cho cùng nội dung (không tự thêm
  dòng). Test ở Task 1.

---

### Task 1: Dựng chỉ mục — `kt_chi_muc_du`, `kt_chi_muc_lai`, `aw knowledge index`

> Đổi tên file test nếu part `29-` đã tồn tại trên `origin/main` khi bắt đầu (một PR khác chiếm trước).

**Files:**
- Modify: `tools/lib/knowledge.sh` (thêm hai hàm sau `kt_tai_lieu_quet` — cuối file)
- Modify: `tools/knowledge.sh` (nhánh `index`; chú thích đầu file, `BL_KIEN_THUC`)
- Modify: `bin/aw-engine` (dòng trợ giúp `aw knowledge`, mục 13–14)
- Create: `tools/tests/29-knowledge-index.sh` (fixture riêng, theo khung `28-knowledge-sections.sh`)

**Interfaces:**
- Consumes: `kt_muc` (SP27), `adr_*` (`tools/lib/adr.sh`), hàm luật (`tools/lib/rule.sh`),
  conv_get (`tools/lib/md.sh`).
- Produces: `kt_chi_muc_du <gốc repo> <conv>` → stdout: in bảng các hàng `| Ref | Kind | Scope |
  Status | Summary |` (không tiêu đề file — chỉ phần hàng); nguồn: file ADR trong thư mục ADR (cách
  `adr_lam_chi_muc` liệt kê file, `tools/lib/adr.sh:201`), file luật có khối `BR-` (qua
  `luat_thu_muc` + ID khối — như `aw rule check` liệt kê), tài liệu khớp `knowledge_files` có mục
  khai `Scope` (qua `kt_muc`).
- Produces: `kt_chi_muc_lai <gốc repo> <conv>` → ghi file chỉ mục (đường dẫn theo khoá): giữ nguyên
  phần người viết phía trên bảng (so cách `adr_lam_chi_muc` giữ phần trên, `tools/lib/adr.sh:177`);
  file chưa có → tạo mới với phần đầu tối thiểu (heading + một dòng giải thích) + bảng. Máy thay `|`
  trong `Summary` → `;`, trim hai đầu cột.
- Produces: `aw knowledge index` (chạy ở gốc repo `MT_REPO`): dựng lại theo khoá, in đường dẫn file;
  khoá tắt → `SAI THAM SỐ` (nhãn + mã như nhánh `show` dùng cho SAI THAM SỐ).

- [x] **Step 1: Viết test** (`29-knowledge-index.sh`): fixture repo có 1 ADR, 1 file luật hai khối
  (`BR-A-001` active, `BR-A-002` deprecated), 1 tài liệu module hai mục khai `Scope` (một mục có
  `- Summary:`) + một mục không khai. Ca:
  - `kt_chi_muc_du` in đúng số hàng, đúng thứ tự Kind rồi Ref; cột `Summary` đúng nguồn (tiêu đề ADR /
    câu đầu `Rule:` / `- Summary:` / heading);
  - cột `Scope` của ADR trống, của luật đúng phạm vi, của mục đúng glob;
  - heading mục có khoảng trắng cuối và tiếng Việt → Ref nguyên văn;
  - `Summary` chứa `|` → hàng không vỡ (`|` thành `;`);
  - `aw knowledge index` lần đầu tạo file; chạy hai lần → nội dung bảng y như nhau (dựng lại bất biến);
  - phần người viết phía trên bảng giữ nguyên khi dựng lại;
  - khoá không khai → hành vi như khai đúng giá trị mặc định (mặc định bật; "chỉ file có mới kiểm"
    ở Task 1 chỉ thấy `aw knowledge index` dùng `docs/knowledge-index.md`);
  - khoá khai trống → SAI THAM SỐ (khoá tắt); khoá khai đường dẫn khác (`docs/trang-tri.md`) → dùng
    đường dẫn đó.
- [x] **Step 2:** `sh tools/tests/29-knowledge-index.sh` → ca mới KHÔNG ĐẠT.
- [x] **Step 3:** Viết `kt_chi_muc_du`, `kt_chi_muc_lai`, nhánh `index`; khai nhãn kq mới của
  `knowledge.sh` (theo `kq_khai`).
- [x] **Step 4:** Phần 29 ĐẠT; `sh tools/run-tests.sh 26-knowledge-retrieval 28-knowledge-sections`
  vẫn ĐẠT (hồi quy sau khi thêm key đọc).
- [x] **Step 5:** Commit `feat(knowledge): aw knowledge index — dựng bảng chỉ mục chung`.

### Task 2: Truy xuất đọc chỉ mục

**Files:**
- Modify: `tools/knowledge.sh` (nhánh `design`, `implement` — khi file chỉ mục có trong git, in dòng
  đường dẫn chỉ mục thay dòng `<adr>/README.md`)
- Modify: `workflow/phases/01-spec.md`, `02-design.md` (đọc chỉ mục chung trước; đoạn chỉ mục ADR chỉ
  khi chỉ mục chung không có)
- Test: `tools/tests/29-knowledge-index.sh` (fixture có chỉ mục), `tools/tests/26-knowledge-retrieval.sh`
  (fixture không có chỉ mục → byte như cũ)

**Interfaces:**
- Consumes: hàm kiểm tra "file chỉ mục có trong git" (Task 3 khai thành `kt_chi_muc_file <gốc> <conv>`
  nếu để dùng chung — đặt ở Task 1 vẫn được, ghi rõ ở Task 1).
- Produces: lệnh `aw knowledge design|implement` khi file chỉ mục có → đầu ra chứa dòng
  `docs/knowledge-index.md` (đường dẫn theo khoá), thay dòng `<adr>/README.md`; file không có →
  đầu ra byte như cũ (chỉ mục ADR).

- [x] **Step 1: Viết test**: fixture có chỉ mục → `design`/`implement` in `docs/knowledge-index.md`,
  không in `README.md` của thư mục ADR; fixture không có chỉ mục → đầu ra không đổi byte nào (ca hồi
  quy); phase `01-spec`, `02-design` sinh text nhắc đọc chỉ mục chung (grep như `08-adapters`).
- [x] **Step 2:** Phần 26, 29 → ca mới KHÔNG ĐẠT.
- [x] **Step 3:** Sửa nhánh `design`/`implement` của `knowledge.sh`; sửa hai phase.
- [x] **Step 4:** `sh tools/run-tests.sh 26-knowledge-retrieval 28-knowledge-sections 29-knowledge-index
  08-adapters` → ĐẠT.
- [x] **Step 5:** Commit `feat(knowledge): phase đọc chỉ mục chung thay chỉ mục ADR khi file có`.

### Task 3: `aw knowledge check` + gắn vào checker

**Files:**
- Modify: `tools/lib/knowledge.sh` (thêm `kt_chi_muc_file`, `kt_chi_muc_kiem`)
- Modify: `tools/knowledge.sh` (nhánh `check`)
- Modify: `tools/check-implement.sh` (gom lỗi), `tools/check-review.sh:115` (gom lỗi)
- Test: `tools/tests/29-knowledge-index.sh`

**Interfaces:**
- Consumes: `kt_chi_muc_du` (Task 1), `kt_muc`, hàm diff (`kt_dong_doi` — chỉ để tính "diff đụng gì").
- Produces: `kt_chi_muc_file <gốc repo> <conv>` → in đường dẫn file chỉ mục nếu tracked ở HEAD;
  không in gì (mã 0) nếu không có — điều kiện "đã có trong git" dùng chung Task 2, Task 3, Task 4.
- Produces: `kt_chi_muc_kiem <gốc repo> <conv> <thư-mục-feature>` → lỗi khi: (a) bảng trong file chỉ
  mục lệch dựng lại trên cây làm việc (so từng hàng, đúng thứ tự); (b) hai mục `##` cùng heading
  trong một tài liệu khớp `knowledge_files` khai `Scope` (mỗi lỗi một dòng `<file>: <lý do>`).
- Produces: `aw knowledge check [<thư-mục-feature>]` — có thư mục feature → kiểm khi có file chỉ mục
  và diff đụng file chỉ mục hay tài liệu kiến thức (file ADR, file luật, tài liệu
  `knowledge_files`); diff không đụng → không kiểm, ĐẠT (kể cả chỉ mục hỏng trên `Base:`). Không có
  thư mục feature → chỉ so bảng với dựng lại (chạy một mình trong CI, như `aw adr check`).

- [x] **Step 1: Viết test**: dựng chỉ mục đúng → `aw check implement` ĐẠT, `aw check review` ĐẠT; sửa
  tay một hàng cột `Summary` → cả hai checker KHÔNG ĐẠT, câu lỗi nói đúng file chỉ mục; xoá hàng của
  tài liệu mới thêm → KHÔNG ĐẠT; xoá hẳn tài liệu mà chỉ mục còn hàng → KHÔNG ĐẠT; đổi tên heading
  mục → hàng `Ref` cũ thành lệch → chặn cho tới khi dựng lại; heading trùng → cả hai checker KHÔNG
  ĐẠT, cảnh báo cũ `kt_canh_bao_muc` của implement vẫn in (giữ như cũ); diff không đụng tài liệu gì →
  chỉ mục hỏng sẵn trên `Base:` không chặn; không có file chỉ mục → không kiểm (ca hồi quy ĐẠT);
  `aw knowledge check` một mình: feature hợp lệ → ĐẠT, feature lệch → KHÔNG ĐẠT.
- [x] **Step 2:** Phần 29 → KHÔNG ĐẠT.
- [x] **Step 3:** Viết hai hàm + nhánh `check`; gắn `# giữ: CAP-implement-07`,
  `# giữ: CAP-verify-06, INV-013` trên chỗ gom lỗi mới; `sh tools/check-sdlc.sh` → ĐẠT (lỗi id chưa
  gắn thì chạy `--dem-luat`, gắn đúng id).
- [x] **Step 4:** Phần 29 ĐẠT; các part checker implement/review cũ vẫn ĐẠT:
  `sh tools/run-tests.sh 05-review-quality 09-implement-quality` (tên part xem lại `ls tools/tests/`
  khi làm — chọn part checker implement/review).
- [x] **Step 5:** Commit `feat(knowledge): aw knowledge check — bảng lệch dựng lại chặn`.

### Task 4: Promote dựng lại chỉ mục; khoá conventions; bootstrap; mẫu AGENTS.md

**Files:**
- Modify: `tools/adr.sh:121` (khi có file chỉ mục đã tracked → gọi `kt_chi_muc_lai` sau
  `adr_lam_chi_muc "$D_ADR"`)
- Modify: `tools/rule.sh` (sau khi chép khối luật: khi có file chỉ mục đã tracked → dựng lại)
- Modify: `tools/check-conventions.sh` (khoá `knowledge_index` sai dạng — không trống mà không kết
  thúc `.md` — báo lỗi, cùng nhãn kq với các khoá khác của script; gắn `# giữ:` đúng capability)
- Modify: `workflow/bootstrap.md` (§ Decisions: đề xuất tạo `docs/knowledge-index.md` qua
  `aw knowledge index`; chỉ mục chung thay README ADR khi file có)
- Modify: `workflow/templates/target-repo/AGENTS.md` (§ Decisions trỏ tới file chỉ mục)
- Test: `tools/tests/29-knowledge-index.sh`, part test conventions hiện có

**Interfaces:**
- Consumes: `kt_chi_muc_file`, `kt_chi_muc_lai` (Task 1, Task 3).
- Produces: `aw adr promote` / `aw rule promote` khi file chỉ mục có → chỉ mục có hàng mới đúng cột
  sau promote; khi không có → không tạo file nào.
- Produces: `aw conventions check` báo lỗi cho `knowledge_index` sai dạng; không khai, trống, hay
  đúng dạng → không báo.

- [x] **Step 1: Viết test**: có chỉ mục + promote DEC-NNN → hàng ADR mới; có chỉ mục + promote REQ →
  hàng `rule` mới; không có chỉ mục + promote → không tạo file nào; `conventions.md` khai
  `knowledge_index: docs/knowledge-index.md` → `aw conventions check` ĐẠT; khai không phải `.md`
  (vd `docs/knowledge-index`) → KHÔNG ĐẠT với câu báo khoá.
- [x] **Step 2:** Phần 29 + part conventions → KHÔNG ĐẠT (part conventions xem
  `grep -rln 'conventions' tools/tests/ | head` khi làm).
- [x] **Step 3:** Sửa `tools/adr.sh`, `tools/rule.sh`, `tools/check-conventions.sh`,
  `workflow/bootstrap.md`, mẫu AGENTS.md; gắn `# giữ: CAP-implement-07, INV-013` (hoặc capability của
  `aw conventions check` — xem `# giữ:` kề trên các khoá khác trong `check-conventions.sh`).
- [x] **Step 4:** Phần 29 + part conventions + `01-adrs` (ADR promote) → ĐẠT.
- [x] **Step 5:** Commit `feat(knowledge): promote dựng lại chỉ mục; khoá knowledge_index kiểm dạng`.

### Task 5: INV-013, tài liệu, roadmap, hoàn tất

**Files:**
- Modify: `sdlc/invariants.md` (thêm `### INV-013 — The knowledge index is rebuilt from the documents
  it lists`; Rule: an index that differs from its rebuild blocks; Checked by: `aw knowledge check`;
  test `29-knowledge-index.sh`)
- Modify: `sdlc/stages/04-implement.md`, `05-verify.md` (khai `INV-013` trong danh sách invariant của
  stage — so cách INV-012 được khai ở cùng vị trí)
- Modify: `workflow/templates/conventions.md`, `conventions-reference.md` (khoá `knowledge_index`)
- Modify: `docs/huong-dan.md` § 7, `docs/kien-truc.md` (chỉ mục thay bước tìm thô; lý do không vector
  — dẫn bảng "Không làm" của roadmap), `docs/thuat-ngu.md` (mục "ref" nhắc chỉ mục chung)
- Modify: `changes/<tên-nhánh>.md` (tên nhánh: `feat-knowledge-index.md`; `Thêm`: `aw knowledge
  index`, `aw knowledge check`, khoá `knowledge_index`; `Thay đổi`: `aw knowledge design|implement`
  in chỉ mục chung thay README ADR khi file có; heading trùng thành chặn; `Nội bộ`: INV-012 của spec
  § C thành INV-013 — SP35 chiếm id cũ)
- Modify: roadmap — dòng SP28 trạng thái `đang làm`, cột Plan trỏ file này

- [x] **Step 1:** Sửa `sdlc/` trước; `sh tools/check-sdlc.sh` → ĐẠT (invariant mới nhận, stage mới
  khai); test mapping/trạng thái (`22-*`, `24-*`) — sửa ca nào khớp chuỗi đã đổi
  (`grep -rn 'INV-012' tools/tests sdlc` và so ca khai danh sách invariant).
- [x] **Step 2:** Sửa tài liệu còn lại; grep test đọc chuỗi đã đổi (`grep -rn 'README.md' tools/tests/`
  chỗ đầu ra `aw knowledge design|implement`) và sửa cùng commit.
- [x] **Step 3:** `git fetch origin && git merge origin/main`; `sh tools/run-tests.sh` → `MỌI CA ĐẠT`,
  không part nào in `nên tách`; `sh tools/check-sdlc.sh` → ĐẠT.
- [x] **Step 4:** Commit `docs(knowledge): chỉ mục chung — invariants, hướng dẫn, kiến trúc, changes`;
  push; mở PR (spec + plan + code), dòng "Interface: INV-013 (mới); CAP-implement-07,
  CAP-verify-06 (Rule không đổi)".
