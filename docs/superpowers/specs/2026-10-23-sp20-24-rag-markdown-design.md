# Spec: SP20–SP24 — Durable knowledge của repo đích như RAG (không vector)

- Ngày: 2026-10-23 · Branch: `claude/kind-cray-3yf0ca`
- Roadmap: `docs/superpowers/2026-10-22-roadmap-cai-thien.md` § SP20–SP24
- Trạng thái: **đề xuất, chờ người duyệt**. Năm dự án con, mỗi cái một PR (nguyên tắc 4), thứ tự SP20 →
  SP21 → SP22; SP23, SP24 chờ số liệu SP9. Spec này không đổi code hay interface; capability/invariant
  mới chỉ thêm vào `sdlc/` trong PR của dự án con tương ứng.

## 0. Bối cảnh

Durable knowledge của repo đích (`docs/kien-truc.md` § Trạng thái của việc và durable knowledge) đã là
một RAG cấp file, truy xuất tất định:

| Bước RAG | Đã có | Thiếu |
|---|---|---|
| Đơn vị (chunk) | cả file: ADR, file luật `BR-`, `ARCHITECTURE.md` | mục, khối ID |
| Metadata | `Scope` (ADR, `BR-`); thư mục (`knowledge_files`) | tóm tắt, từ khoá, liên kết |
| Chỉ mục | bảng ADR `docs/adr/README.md` (`adr_lam_chi_muc`) | một chỉ mục cho mọi loại |
| Truy vấn | đường dẫn trong `## Existing code` (`aw knowledge design`); spec in **mọi** luật active | `Expected files`, diff; từ khoá |
| Phase đọc | spec, design | implement, review; việc bỏ design (`chore`, `Design: skip`) không bao giờ đọc ADR |
| Trích nguồn | verdict `## Durable knowledge` ở review (tài liệu bị diff đụng) | đã dùng khối nào khi quyết định |

**Giữ nguyên nguyên tắc:** truy xuất tất định bằng sh + awk + git, không embedding/vector. Lý do: kết quả
theo độ tương đồng không lặp lại được, nên checker không kiểm được "đọc đúng tài liệu", và cross-check
stale lẫn verdict review mất chỗ bám (cùng một `Scope` cho cả ba). Ghi vào § Không làm của roadmap.

**Thành công (toàn đợt):** mọi phase đụng code nhận đúng các khối kiến thức trong phạm vi của nó, ở mức
mục thay vì cả file; kiến thức không gắn đường dẫn tìm được qua chỉ mục; repo chưa dùng tính năng mới
chạy y như cũ.

## A. SP20 — Truy xuất theo phạm vi ở implement và review

**Vấn đề.** `aw knowledge` chỉ có `spec|design` (`tools/knowledge.sh`). Implement chỉ biết tài liệu bị đụng
qua cảnh báo stale *sau khi* sửa; việc bỏ design không đọc ADR nào.

**Thiết kế.**
- Tách phần khớp của nhánh `design` trong `tools/knowledge.sh` thành hàm `kt_lay <gốc repo> <conventions>`
  ở `tools/lib/knowledge.sh`: stdin = danh sách đường dẫn, stdout = ADR accepted có `Scope` khớp, file luật
  có luật active khớp (`luat_lien_quan`), tài liệu `knowledge_files` ở thư mục cha — đúng thứ tự và khử
  trùng như hiện nay. `design` gọi lại hàm này (output không đổi — test cũ giữ nguyên).
- `aw knowledge implement <dir>`:
  - in chỉ mục ADR (`<knowledge_adr_dir>/README.md`) khi việc bỏ design (`kc_bo_design`) — việc có design
    đã đọc nó;
  - đường dẫn = mỗi token backtick của `Expected files:` trong `plan.md`: token không có ký tự glob → chính
    nó; có glob → các file đã track trên `Base:` khớp token (hàm khớp của `Expected files`, như
    `scope_glob_max_files`) cộng tiền tố thư mục trước ký tự glob đầu tiên (để thư mục mới vẫn khớp
    `ARCHITECTURE.md` cha). Bỏ file test (`test_files`), thư mục ADR/luật;
  - `kt_lay` trên tập đó.
- `aw knowledge review <dir>` = cột tài liệu của `kt_anh_huong` (tài liệu mà diff đụng phạm vi) — cùng
  tập review đã phải ghi verdict, nên review đọc đúng thứ nó chấm.
- `BL_KIEN_THUC="spec design implement review"`; `bin/aw-engine` dòng trợ giúp.
- Phase: `04-implement.md` thêm một bước trước loop "`aw knowledge implement <dir>` — read every file it
  prints"; `05-review.md` Lens 3 "`aw knowledge review <dir>` — read before writing `## Durable knowledge`".
  Không restate checker.
- Không thêm luật chặn: máy không kiểm được agent đã đọc. Verdict ở review vẫn là chốt.

**Interface.**
- `CAP-implement-07 — Durable knowledge in scope of the planned files is retrieved before building`;
  Rule: the set is computed by the machine from the plan's files, not chosen by the agent. Judged by:
  agent (review chấm qua `## Durable knowledge`). Artifact: change. Phase `04-implement` nhận luôn.
- `CAP-design-04 — Design reads durable knowledge in scope of the code it surveys` — engine đã làm
  (`aw knowledge design`); Judged by: agent. Phase `02-design` nhận luôn (§ 4.3 bước 3 của
  `docs/interface-sdlc.md`).
- `CAP-verify-06 — Every durable-knowledge document whose scope the change touches has a review verdict`;
  Judged by: machine — đã làm (`kt_loi_review`). Gắn `# giữ: CAP-verify-06` cho chỗ luật đó, hạ số đếm
  trong `tools/unclassified-rules.txt` nếu chỗ đó đang được đếm.
- Ba stage vẫn `implemented`; `docs/interface-sdlc.md` § 6 không đổi (không thêm capability thiếu).

**Test** (phần mới `tools/tests/26-knowledge-retrieval.sh`, fixture riêng — không làm chậm `16`/`17`):
plan có token trỏ file trong phạm vi ADR → in ADR; token glob `src/billing/**` → in `src/billing/ARCHITECTURE.md`
và luật có `Scope` trong đó; token chỉ là file test → không in; việc `chore` → in chỉ mục ADR, việc
`feature` → không; ADR `superseded` → không in; `review` in đúng tập `kt_anh_huong`; `design` output
không đổi so với trước (ca hồi quy); phase sinh ra chứa lệnh mới (`08-adapters` grep).

**Tài liệu.** `docs/huong-dan.md` § 7 bảng "Việc sau đọc"; `docs/kien-truc.md` § Điểm vào… (bỏ "cách nạp
theo phạm vi diff là bước sau") và § ADR (`aw knowledge` gọi ở bốn phase); `changes/…` `Thêm`.

**Cần quyết.** Không có — đề xuất làm trước.

## B. SP21 — Chunk theo mục và khối ID

**Vấn đề.** Một `ARCHITECTURE.md` lớn bị nạp cả file khi việc chỉ đụng một file con; cross-check stale
cũng ở mức file, nên một module lớn sinh verdict cho mọi việc chạm nó.

**Thiết kế.**
- **Ref**: `<file>` (cả file, như nay) hoặc `<file>#<neo>`. Neo: ID của khối luật (`BR-BILLING-003`), hoặc
  nguyên văn heading `##` của tài liệu module (sau `## `, bỏ khoảng trắng hai đầu). ADR luôn là cả file
  (đã nhỏ, một quyết định).
- **Scope theo mục** (chỉ `knowledge_files`): dòng `- Scope: <glob…>` là dòng không trống đầu tiên dưới
  heading `##`. Mục không khai → thuộc phạm vi thư mục như nay.
- **Tương thích ngược**: tài liệu không có mục nào khai `Scope` → ref `<file>`, output y như cũ. Tài liệu có
  ≥1 mục khai → mỗi mục khai là ref `<file>#<heading>`; các mục còn lại gộp thành ref `<file>` (phạm vi thư
  mục).
- **Luật `BR-`**: `aw knowledge spec|design|implement|review` in `<file>#BR-…` thay cho cả file luật — khối đã
  có ID và `Scope` riêng. Đổi output với repo có luật: ghi `Thay đổi` trong changelog.
- `aw knowledge show <ref>…`: in khối — từ heading tới heading cùng cấp hoặc cao hơn kế tiếp; ref `<file>`
  của tài liệu có mục khai `Scope` in file **trừ** các mục đó. Ref không có → `SAI THAM SỐ`.
- Phase đổi "read every file it prints" thành "`aw knowledge show` every ref it prints".
- **Cross-check stale theo mục**: `kt_anh_huong` tính theo ref; cột `File` của `## Durable knowledge` nhận ref.
  Verdict `updated` của ref có neo: máy kiểm diff đổi dòng nằm trong khối (dải dòng của khối trên cây
  làm việc), không chỉ "file đổi". Heading của khối bị đổi tên trong diff → coi như đổi.
- `aw rule check`, `aw adr check` không đổi (đã tìm luật theo ID).

**Interface.** Không thêm capability; `CAP-verify-06`, `CAP-implement-07` mịn hơn, Rule trừu tượng không đổi.

**Test** (`26-knowledge-retrieval.sh`, `17-rule-crosscheck.sh`): tài liệu không khai mục → ref như cũ (hồi
quy); hai mục khai, diff đụng phạm vi một mục → chỉ ref mục đó, cảnh báo stale chỉ cho mục đó; verdict
`updated` khi diff sửa file nhưng ngoài khối → chặn, trong khối → ĐẠT; `show` neo không có → SAI THAM SỐ;
`show <file>` bỏ mục đã khai; heading trùng trong một file → `aw knowledge check` (SP22) báo, `show` lấy mục đầu.

**Tài liệu.** `conventions-reference.md` § `knowledge_files` (Scope theo mục); `docs/huong-dan.md` § 7;
`docs/kien-truc.md` § Cross-check stale; mẫu `review.md` (`File` nhận ref); `docs/thuat-ngu.md` thêm "ref".

**Cần quyết.**
1. Neo là heading nguyên văn (đọc được, nhưng đổi tên mục là đổi ref) hay slug kiểu GitHub (không ổn
   định với tiếng Việt trong mawk). **Nghiêng về:** nguyên văn.
2. Có cho mục `###` khai `Scope` không. **Nghiêng về:** không — chỉ `##`, tránh khối lồng nhau.

## C. SP22 — Chỉ mục kiến thức chung

**Vấn đề.** Kiến thức không gắn đường dẫn (luật xuyên module, quyết định toàn repo) chỉ tìm được nếu agent
đọc hết; chỉ mục hiện chỉ có ADR.

**Thiết kế.**
- Khoá `conventions.md` mới `knowledge_index`, mặc định `docs/knowledge-index.md`; trống = tắt.
- `aw knowledge index`: dựng lại bảng (giữ phần người viết phía trên, như `adr_lam_chi_muc`):
  `| Ref | Kind | Scope | Status | Summary |`, `Kind` ∈ `adr | rule | module`. `Summary` lấy từ thứ đã có:
  ADR → tiêu đề; luật → câu đầu của `Rule:`; mục tài liệu module → dòng `- Summary:` nếu có, không thì
  heading. Không thêm trường bắt buộc. Thứ tự: theo `Kind`, rồi ref.
- **Opt-in theo file**: chỉ kiểm khi file chỉ mục đã có trong git. `aw knowledge index` tạo nó;
  `/aw-bootstrap` đề xuất tạo; mẫu `target-repo/AGENTS.md` § Decisions trỏ tới nó.
- `aw adr promote`, `aw rule promote` dựng lại chỉ mục nếu file có (như ADR README).
- **Kiểm** (`aw knowledge check`, gọi trong `aw check implement` và `aw check review` khi diff đụng tài liệu
  kiến thức hoặc chính chỉ mục): bảng lệch với dựng lại → **chặn** (máy dựng, so chính xác — luật "precise →
  block"). Kèm: heading trùng trong một tài liệu có mục khai `Scope` (SP21). Chỉ mục hỏng sẵn trên base mà
  diff không đụng → không chặn (như hình thức thư mục ADR).
- Phase: `01-spec`, `02-design` đọc chỉ mục trước (thay chỉ mục ADR khi chỉ mục chung có); `aw knowledge
  design|implement` in `knowledge_index` thay `<adr>/README.md` khi có.

**Interface.** `INV-012 — The knowledge index is rebuilt from the documents it lists`; Rule: an index that
differs from its rebuild blocks; Checked by: `aw knowledge check`; test 26. `sdlc/invariants.md` + test `22`.

**Test** (`26`): dựng chỉ mục từ fixture có ADR, luật, mục module → bảng đúng; sửa tay một dòng → `check`
chặn; không có file → không kiểm; promote ADR khi có chỉ mục → chỉ mục có dòng mới; diff không đụng tài
liệu, chỉ mục hỏng trên base → không chặn; khoá sai giá trị → `aw conventions check` báo.

**Tài liệu.** `conventions.md` + `conventions-reference.md` (khoá mới); `docs/huong-dan.md` § 7;
`docs/kien-truc.md` (chỉ mục thay bước tìm thô, vì sao không vector); mẫu `AGENTS.md`; `changes/…` `Thêm`.

**Cần quyết.** Mặc định bật (`docs/knowledge-index.md`) nhưng chỉ kiểm khi file có — hay mặc định trống.
**Nghiêng về:** mặc định có giá trị, kiểm theo file có (không ép repo cũ).

## D. SP23 — Tìm theo từ khoá

**Vấn đề.** Spec chưa có đường dẫn code nên `aw knowledge spec` in mọi file luật active; repo nhiều miền
thì phình. Kiến thức không gắn đường dẫn chỉ tìm được nhờ chỉ mục đọc hết.

**Thiết kế.**
- `aw knowledge find <từ>…`: tìm trong các dòng chỉ mục (Ref, Scope, Summary), heading `##`, dòng
  `- Keywords:` (tuỳ chọn, dưới heading hoặc khối luật). Không phân biệt hoa thường **chỉ với ASCII**
  (mawk không hạ chữ UTF-8 — ghi giới hạn). Hạng = số từ khác nhau khớp; hoà → thứ tự chỉ mục. In tối đa
  10 ref; `--all` in hết.
- `aw knowledge spec`: in như cũ khi số luật active ≤ ngưỡng; vượt ngưỡng → in chỉ mục (hoặc các dòng
  `rule` của nó) và phase yêu cầu `find` theo thuật ngữ của nguồn rồi `show` từng ref. Ngưỡng: khoá
  `knowledge_spec_max_rules` (mặc định 50; `0` = luôn in hết).

**Interface.** `CAP-require-04 — Requirements are checked against the active business rules they may
contradict`; Judged by: agent (checker LLM spec — SP13 — chấm mâu thuẫn). Engine đã làm phần "in hết";
nhận capability ngay ở SP23.

**Test** (`26`): `find` khớp heading/Summary/Keywords, xếp hạng đúng, giới hạn 10, `--all`; từ có dấu khớp
đúng dạng viết; `spec` dưới ngưỡng in như cũ, trên ngưỡng in chỉ mục; khoá sai giá trị bị báo.

**Cần quyết.** Chỉ làm khi số liệu SP9 cho thấy repo thật có nhiều luật hơn agent đọc nổi (nguyên tắc 3).

## E. SP24 — Theo liên kết một bước, trích nguồn

**Vấn đề.** Một khối hay trỏ tới khối khác (luật nhắc ADR, ADR thay ADR) mà agent không được đưa; không ai
ghi quyết định đã dựa vào khối nào, nên review không biết khối được lấy có được dùng không.

**Thiết kế.**
- **Một bước**: sau tập chính, `aw knowledge` thêm ref mà khối trong tập nhắc tới: `ADR-NNNN`, `BR-…-NNN`
  (theo ID, trạng thái `accepted`/`active` — không theo về bản `superseded`). Không đệ quy. Dòng thêm
  nằm sau tập chính, cùng dạng (stdout vẫn là dữ liệu một ref mỗi dòng).
- **Trích nguồn**: mẫu `tdd.md` thêm `## Knowledge used` — bảng `| Ref | Use | Reason |`, `Use` ∈
  `applied | not relevant` (+ lý do), mỗi ref `aw knowledge design` in ra một dòng. Việc bỏ design: bảng
  cùng dạng trong `plan.md` (`aw knowledge implement`).
- **Kiểm**: thiếu dòng cho ref đã in → **cảnh báo** ở `aw check design` / `aw check implement`, **chặn** ở
  `aw check review` (xuyên phase, dễ báo nhầm khi tập đổi giữa các phase — luật warn/block của
  `AGENTS.md`). Máy không kiểm `applied` đúng — như `## Repo rules`.

**Interface.** `CAP-design-04`, `CAP-implement-07` đổi `Judged by: agent` → `machine` (máy kiểm có dòng cho
mọi ref) — làm chặt, không hạ chuẩn; luật mới gắn `# giữ:` hai id này.

**Test** (`26`, `05-review-quality.sh`): luật nhắc ADR → ADR có trong output, ADR superseded → không;
không đệ quy hai bước; `tdd.md` thiếu dòng → design cảnh báo, review chặn; đủ dòng → ĐẠT; `not relevant`
không lý do → chặn ở review.

**Cần quyết.** Chặn ở review hay chỉ cảnh báo cả hai nơi. **Nghiêng về:** chờ số liệu SP9 về tần suất
"có tài liệu đúng mà không dùng" trước khi chặn.

## Không làm

- Embedding, vector DB, tìm theo độ tương đồng (lý do § 0).
- Xếp hạng BM25/TF-IDF: `find` đếm từ khớp là đủ với chỉ mục vài trăm dòng; thêm khi số liệu cho thấy
  hạng sai.
- Tự sinh `Summary`/`Keywords` bằng LLM: dữ liệu do agent viết không ai duyệt sẽ thành nguồn truy xuất
  (giống lý do ADR chỉ chép từ DEC đã duyệt). `/aw-bootstrap` được đề xuất, người duyệt qua PR.
