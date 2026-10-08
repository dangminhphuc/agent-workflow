# Kiến trúc

Vì sao thiết kế như vậy, và cách mở rộng. Luật cụ thể nằm ở `workflow/`; file này chỉ giữ lý do.

## Vấn đề

Muốn quy trình dựa trên AI agent **không khoá vào một agent**. Lớp trừu tượng hoá API hỏng ngay:
agent khác nhau ở chỗ không trừu tượng được (subagent, hook, MCP), nên nó rút về mẫu số chung nhỏ
nhất — quá yếu để dùng.

## Giải pháp: bàn giao bằng file

```
tài liệu / lời người ─▶ 00-intake ─▶ intake.md
                                       ▼
                        01-spec ─▶ spec.md ─▶ 02-design ─▶ tdd.md    (chore: bỏ design)
                                   ▼                       ▼
                                03-plan ◀──────────────────┘
                                   ▼
                                plan.md ─▶ 04-implement ─▶ diff + ket-qua-*.md
                                                              ▼
                                                   05-review ─▶ review.md ─▶ [06-ship]
```

Phase chỉ nối nhau qua file — thứ mọi agent đọc/ghi được. Phép thử: **mỗi phase chạy được từ phiên
trắng**. Phase cần nhớ điều phase trước nói *trong hội thoại* thì chỉ chạy được khi cùng phiên,
cùng agent, chưa nén ngữ cảnh — mất cả tính portable lẫn lặp lại. Adapter chỉ dịch định nghĩa
phase sang dạng native; mất hết adapter thì vẫn chạy được bằng copy-paste.

### Vào ở phase nào cũng được

Đây là mục đích gốc của tính trung lập: artifact làm bằng tool bất kỳ đưa vào đúng phase cần. Để
không thành đường tắt:

- **Entry check của phase N = checker của phase N-1 chạy lại trên input** (cả bộ file tham chiếu).
- **Artifact ngoài vẫn qua gate người** của phase lẽ ra sinh ra nó.
- **Import có kiểm soát** (`/aw-import`): chỉ sắp lại theo mẫu, **không thêm nội dung** — nếu
  được thêm, suy đoán của agent sẽ mang nhãn nguồn như có trong tài liệu gốc.

### `00-intake`: một gốc cho mọi việc

`intake.md` = loại việc + input + một câu mục tiêu. Bắt buộc vì:

- **Loại việc đổi luật** (bugfix cần test tái hiện, refactor cấm hành vi mới, perf cần số đo,
  chore không đụng production) — nên phải là dữ liệu máy đọc.
- **Mọi YC có đúng một gốc**: spec chỉ đọc input được liệt kê.

Intake chỉ **trỏ tới** tài liệu, nhận tài liệu có định danh hoặc lời người **nguyên văn**
(`[HUMAN]`); cấm `[INFERRED]` — nếu không, suy đoán sẽ sang spec với nhãn `[FILE] intake.md`.

**Nhãn input do máy gán** (`aw input`): checker chỉ kiểm được cú pháp nhãn, agent gắn `[JIRA]` cho
URL GitHub vẫn lọt. Quyết trên **cả chuỗi**: một từ không nhận ra là cả tham số thành lời người —
tách từng từ sẽ thành input rác và mất câu gốc. Chạy lại chỉ **gộp thêm**; `spec.md` ghi
`based_on: intake.md` nên input mới làm spec lỗi thời.

**Nguồn sự thật của loại việc** là `intake.md`. Tiền tố branch chỉ gợi ý; lệch thì review chặn,
không có ngoại lệ "ghi lý do" (ngoại lệ dễ ghi hơn sửa, tiền tố sẽ mất nghĩa). `aw rename` đổi
branch, thư mục artifact, worktree trong một lệnh.

Phân loại theo **thay đổi gì về hành vi**: loại chỉ tồn tại khi nó đổi luật — nên không có
`utils`, `hotfix`, `security`; `spike` nằm ngoài (output là kết luận, không phải code).

Mẫu chung cho bằng chứng theo loại: **máy tự chạy và tự ghi**, **máy chặn phần chính xác**,
**người phán phần mơ hồ**:

| Loại | Máy chặn | Người phán | Vì sao không để máy phán |
|---|---|---|---|
| `bugfix` | `tai-hien.md` ghi lúc diff chỉ đụng file test, `ĐỎ` | Đỏ **đúng vì bug** | Test mới trên code cũ có thể đỏ vì lỗi biên dịch |
| `refactor` | Xoá test cũ; sửa test cũ không khai; YC preserve không có test trên nhánh gốc | Diff test cũ chỉ đổi import | "Chỉ đổi import" phụ thuộc ngôn ngữ, hay báo nhầm |
| `perf` | Thiếu số đo trước/sau | Đạt mục tiêu chưa | Số đo dao động; chặn theo ngưỡng sẽ nhầm |
| `chore` | Đụng `production_code`; dependency không khai; khai `major` | Mức phiên bản đúng | Cú pháp phiên bản mỗi hệ sinh thái mỗi khác |

Không dựng lại code cũ để chạy test tái hiện: trông chặt hơn nhưng kết luận sai mà tự tin (đỏ vì
thiếu hàm vẫn tính là "tái hiện được").

### Artifact theo feature, worktree bắt buộc

- Artifact ở `.agent-workflow/<tên-branch>/`, tên branch **đầy đủ** để feat và refactor cùng tên
  không đè nhau. Agent luôn in `Đang làm với: …` — ghi nhầm feature là lỗi im lặng.
- Checkout chính chỉ chạy `/aw-intake`, `/aw-bootstrap` (đề xuất worktree) và dọn ở `/aw-ship`; `aw feature`
  chặn mọi lệnh khác ở đó.
  Chốt đặt ở script mọi phase đều gọi — "phiên trắng" thành cấu trúc, không còn là khuyến nghị.
- Worktree **ngoài** repo (`../{repo}.wt/{ten}`): bên trong thì jest/tsc/grep quét trùng và agent
  đọc nhầm artifact worktree khác. Branch, worktree, thư mục artifact cùng một tên.
- **Agent không chọn base.** `aw worktree new` liệt kê ứng viên, ★ theo một luật máy (giữa `main`
  và `origin/main`, bản nào chứa bản kia; phân kỳ thì không gợi ý). Không tự fetch (kết quả sẽ phụ
  thuộc thời điểm) — in thời điểm fetch cuối. Branch tạo `--no-track`: mặc định upstream là
  `origin/main` và `git push` trơn sẽ đẩy thẳng lên `main`.
- **Base ghi vào `intake.md`**; checker so diff với điểm rẽ khỏi base đó. So với `main` local khi
  tạo từ `origin/main` (local chậm) hay `release/*` sẽ tính commit người khác cho việc này. Xếp
  chồng lên branch việc khác được, nhưng review cảnh báo (dựa trên code chưa review).
- Dọn worktree không bao giờ `--force`/`branch -D`: `git branch -d` để git tự từ chối khi chưa
  merge. Squash-merge git không nhận ra → người tự quyết.

## Engine có version, cài ngoài repo

Bộ cài cũ chép quy trình vào repo đích và bắt commit vào nhánh gốc. Đổi vì:

1. **Protected branch** — cài/nâng cấp phải qua PR vào nhánh được bảo vệ. Giờ engine ở
   `~/.agent-workflow/engine/<V>/`, cấu hình ở `$(git rev-parse --git-common-dir)/agent-workflow/`,
   file sinh ra bị `.git/info/exclude` → **base tuỳ ý**. Quy ước của repo thì ngược lại: nằm trong
   git và qua PR (mục "Trạng thái của việc và kiến thức bền") — lý do trên nhắm vào *cài/nâng cấp
   engine*, còn quy ước của team đi qua review là điều mong muốn.
2. **Version theo việc** — đồng bộ bộ cài giữa chừng đổi luật mọi việc đang làm. Giờ `intake.md`
   ghi `Engine:`; mọi `aw check` chạy đúng version đó, không có thì `KHÔNG HỢP LỆ` (chạy tạm bằng
   version khác = chấm theo luật việc đó không được đặt ra). So khớp chính xác, không suy "tương thích".
3. **Độc lập agent** — luật cứng trong checker (`aw …`, mã thoát + nhãn `Kết quả`); adapter chỉ là
   lớp mỏng.

| Mảnh | Vai trò |
|---|---|
| `bin/aw` | Tìm repo; chọn version (dòng `Engine:` hoặc file `version`); tải, kiểm sha256; chuyển lệnh kèm `AW_REPO`, `AW_CONFIG`, `AW_ENGINE` |
| `bin/aw-engine` | Điểm vào engine |
| `tools/lib/moi-truong.sh` | Tool đọc đường dẫn **chỉ** từ biến môi trường; không tự suy từ vị trí của nó |
| `checksums` | sha256 ghim lần đầu. Lần sau phải khớp sha đã ghim, không tin lại `SHA256SUMS` (cùng nguồn với tarball, chỉ bắt file hỏng, không bắt nguồn bị tráo) |

- Kênh tải: Release của repo này, file `agent-workflow-V.tar.gz` do workflow đóng gói — không dùng
  tarball GitHub tự sinh (byte không được hứa giữ nguyên).
- **Version đặt trong PR** (`tools/chuan-bi-phat-hanh.sh`), không để CI tự tăng (bot phải commit
  thẳng vào `main`, vượt bảo vệ nhánh). Merge chỉ *phát hành*: workflow `release` tạo tag + Release
  trong cùng job (tag tạo bằng `GITHUB_TOKEN` không kích được workflow khác). Hai PR cùng số: CI
  của PR chặn PR merge sau.
- Wrapper và engine có số giao thức (`AW_PROTOCOL`): lệch thì dừng, không chạy thiếu biến.
- **Artifact chỉ ở máy**: không vào PR; gỡ worktree thì chép vào `archive/` trước.

## Trạng thái của việc và kiến thức bền

Bài kiểm tra phiên mới cho **repo đích**: một phiên agent chỉ có repo phải trả lời được hệ thống là
gì, tổ chức ra sao, chạy và kiểm thế nào, **vì sao code như vậy**, đang ở đâu. Thứ gì chỉ ở một
máy thì với phiên đó coi như không có. Ranh giới:

| | Trạng thái của việc | Kiến thức bền |
|---|---|---|
| Là gì | `intake/spec/tdd/plan/review`, `ket-qua-*`, ô duyệt đang chờ | Quy ước, quyết định, ràng buộc, luật nghiệp vụ còn đúng sau khi việc xong |
| Ở đâu | `.agent-workflow/<branch>/` — bị exclude, gỡ worktree thì vào `archive/` | Trong git của repo đích, qua PR |
| Vì sao | Nhiều, đổi liên tục, chỉ có nghĩa trong việc; vào PR thì reviewer đọc nhiễu | Phải đúng cho mọi bản clone và mọi việc sau |

Các mục dưới: `conventions.md` trong git, mẫu điểm vào và lệnh kiểm, ADR từ D-xx, luật nghiệp vụ
`BR-`, kiểm chéo lỗi thời. Ba rủi ro chung: **lỗi thời** (tài liệu lệch code còn tệ hơn không có —
mục kiểm chéo), **nhồi nhét** (chỉ thứ người chọn nâng, không chép PRD — mục ADR, luật), **nguồn đổi
sau khi nâng** (điểm yếu 20). "Phiên mới trả lời được năm câu" máy chỉ kiểm điều kiện cần (đủ file,
`aw knowledge` in đúng file); phép thử với phiên agent thật là bước tay (README).

### `conventions.md` trong git, bản clone chỉ ghi đè khoá máy

- **Vị trí cố định** `docs/agent-workflow/conventions.md` (`QU_DUONG_DAN`, `tools/lib/md.sh`).
  Không cho cấu hình: chỗ đặt nó lại phải nằm trong một cấu hình khác, và mỗi máy trỏ một file là
  đúng thứ cần bỏ. Không đặt dưới `.agent-workflow/` (bị exclude; `--from-legacy` dùng
  `.agent-workflow/conventions.md` làm dấu hiệu bộ cài cũ).
- **Bản clone chỉ ghi đè `worktree_dir`** (`QU_KHOA_MAY`) — khoá duy nhất chỉ ảnh hưởng máy cục
  bộ. Khoá khác ở bản clone: `aw conventions check` báo ✗ và không có hiệu lực (nếu không, một máy
  lặng lẽ chạy luật khác cả team). Thêm khoá máy là thay đổi engine, có lý do.
- **Việc đọc bản ở điểm rẽ khỏi base** (`git show <merge-base>:…`), không đọc bản trong worktree.
  Đọc worktree thì việc tự nới luật của chính nó (xoá `sensitive_code`, đổi `test_files`) rồi
  checker chấm theo luật đã nới — trái "agent không tự duyệt". Như version engine ghim trong
  `intake.md`: luật của việc cố định lúc bắt đầu; sửa quy ước có hiệu lực cho việc sau khi merge.
  Checkout chính, worktree chưa có `intake.md`, và việc rẽ từ base chưa có file đọc bản ở cây làm
  việc của checkout chính (nhánh gốc — không phải chỗ agent của việc ghi vào).
- **Một bản hiệu lực**: `qu_hieu_luc` gộp hai nguồn thành `/quy-uoc-hieu-luc/<khoá>.md`
  (ngoài cây làm việc, không đổi `Tree`); mọi script và `.agent-workflow/.engine/conventions.md`
  đọc file đó — một chỗ quyết định, không có script nào đọc lệch.
- **Tương thích ngược**: repo chỉ có bản clone (init bằng engine cũ) chạy như cũ, `aw conventions
  check` cảnh báo kèm cách chuyển. `aw init`/`aw upgrade` không tự tạo file trong repo khi bản clone
  đã có — nếu tạo, mẫu sẽ thay giá trị team đang dùng. `aw init --from` chỉ bỏ `conventions.md` của
  repo cấu hình khi repo đích đã có file (nếu chưa, bỏ là clone mới chạy bằng mẫu).


### Điểm vào và lệnh kiểm của repo đích: khuyến nghị, không ép

- **Mẫu, không checker.** `templates/repo-dich/AGENTS.md`, `Makefile`; `aw init` chỉ nhắc khi repo
  chưa có `AGENTS.md` lẫn `CLAUDE.md`. Máy kiểm được file *có*, không kiểm được nó trả lời đúng năm
  câu của phiên mới — chặn theo "có file" chỉ sinh file rỗng cho qua cổng. Mỗi repo cũng đã có bố
  trí riêng; engine ép một bố trí là đòi sửa repo để hợp công cụ.
- **`AGENTS.md` chỉ trỏ tới, 50–100 dòng.** Chép luật vào đó là luật có hai chỗ, một chỗ sẽ cũ —
  tài liệu lệch code còn tệ hơn không có. Nó đọc vào mọi phiên, nên mỗi dòng tốn ngữ cảnh mọi lần.
- **Lệnh kiểm nằm trong git (`make test`), `config.sh` chỉ trỏ tới.** Chép lệnh vào `config.sh`
  (ngoài git, mỗi máy một bản) thì local và CI lệch dần: local xanh mà pipeline chặn. Target mẫu
  chưa khai thoát mã 1 — "quên khai" không bao giờ thành xanh, đúng như `LENH_KIEM_THU` trống.
- `ARCHITECTURE.md` của module đi vào phase qua `rules_<phase>` có sẵn; cách nạp theo phạm vi diff
  là bước sau.

### `/aw-bootstrap`: dựng bản đồ một lần cho repo có sẵn

Các cơ chế trên chỉ đưa kiến thức vào git **theo từng việc**; repo đã chạy nhiều năm thì quyết định cũ
vẫn nằm ngoài. `/aw-bootstrap` làm phần đó một lần, theo đúng các luật trên:

- **Lệnh tiện ích, không phải loại việc mới.** Không có YC, D-xx hay gate người để kiểm — thêm loại
  việc là thêm checker cho thứ máy không chấm được (tài liệu có trả lời đúng năm câu không). Nó chạy
  trong worktree `chore` như mọi việc (checkout chính chỉ đề xuất, người chọn base); kết quả là PR
  người duyệt.
- **Chỉ từ bằng chứng.** Mọi dòng ghi vào tài liệu kèm `file:dòng` hay commit; "vì sao" không có
  bằng chứng thành câu hỏi trong báo cáo. Bịa lý do cho một quyết định là tạo đúng loại tài liệu sai
  mà agent sau tin là thật.
- **ADR viết tay cho quyết định cũ**: đúng định dạng `aw adr check` nhận, `Origin` là commit/tài liệu
  gốc. Implement và review chỉ đối chiếu ADR nâng từ D-xx của việc, nên ADR cũ không bị dựng lại để
  so — người duyệt PR là chốt nội dung.
- **Không viết luật `BR-`**: luật cần nguồn có phiên bản và người có quyền xác nhận — chỉ liệt kê ứng
  viên, chúng vào qua `/aw-spec` của việc kế tiếp chạm tới.
- **Trạng thái của việc vẫn ngoài git**: `## Status` của `AGENTS.md` trỏ tới nơi giữ tiến độ thật
  (issue tracker), không chép artifact của việc.
- Báo cáo (`<thư-mục-feature>/bootstrap.md`, ngoài git) đo **khoảng cách hiển thị** — số mục kiến
  thức còn ngoài repo trên tổng số — và ghi kết quả bài kiểm tra phiên mới; làm mô tả PR.

### ADR: D-xx đã duyệt thành "vì sao" của repo

D-xx là quyết định có giá trị nhất mà quy trình sinh ra, nhưng `tdd.md` là trạng thái của việc —
gỡ worktree là nó vào `archive/` của một máy. ADR đưa phần còn đúng sau việc vào git.

- **Người quyết nâng, trong chính D**: `- Promote: adr`, `- Scope:`, `- Supersedes:` nằm dưới dấu
  duyệt, nên duyệt D là duyệt luôn việc nâng. Không có cờ dòng lệnh `--supersedes`: tham số do
  agent gõ, không ai duyệt. Agent đề xuất được, không tự quyết được — như mọi trường khác của D.
- **Nâng ở implement, không sau review**: ADR là file trong diff; nâng sau review thì `Reviewed tree`
  lệch, `aw check ship` chặn mãi. Plan buộc có task `Based on: D-NN` với `Expected files` gồm thư mục
  ADR (không thì diff lệch phạm vi); implement chạy `aw adr promote`; review đọc ADR như mọi code.
- **Chỉ chép**: nội dung D (trừ ô duyệt và ba trường trên) cộng nguồn. Nguồn không ghi `YC-NNN` trần
  — số YC theo từng spec, vô nghĩa sau việc — mà là `Source:` của các YC mà task "Based on: D-NN" phủ
  (plan → spec): truy được về Jira/Confluence. Máy dựng lại ADR từ D và so (bỏ `Date`, `Status`):
  sửa ADR bằng tay, hay D đổi sau khi nâng, đều chặn ở implement và review — chính xác nên chặn.
- **`Scope` bắt buộc**: không có phạm vi thì `aw knowledge` không biết ADR nào liên quan việc nào,
  và kiểm chéo lỗi thời (bước sau) không có dữ liệu.
- **Không xoá ADR**: thay bằng `Status: superseded by NNNN`; người đọc sau vẫn thấy vì sao từng làm
  khác. Chỉ mục `README.md` dựng lại từ các file (giữ phần người viết phía trên bảng).
- **`aw knowledge` tách khỏi `aw rules`**: `rules` nghĩa là "đọc hết, review chấm từng file"; kiến
  thức bền lọc theo phạm vi (đường dẫn trong `## Existing code`) — trộn vào thì bảng `## Repo rules`
  phình theo số module. Design gọi hai lần: trước khảo sát (chỉ mục) và sau khi ghi `Existing code`.
- Đi ngược ADR mà không khai `Supersedes` máy không phát hiện được (cần hiểu nội dung) → checker LLM
  thiết kế chặn (`trái ADR`).

### Luật nghiệp vụ `BR-`: YC đã duyệt thành bất biến của sản phẩm

`YC-NNN` đánh số theo từng spec — việc sau không nhắc lại được, và luật từ PRD chỉ sống trong một
`spec.md`. Luật `BR-` là phần của YC còn đúng sau việc: bất biến, không phải chi tiết màn hình.

- **Không chép PRD**: chỉ YC người chọn. Chép toàn văn thì repo thành bản sao lệch của Confluence —
  nhồi nhét làm agent đọc nhiều mà quyết định không tốt hơn.
- **Người quyết trong YC**: `- Promote: BR-<MIỀN>-NNN` nằm dưới dấu duyệt spec. ID, file đích
  (`<knowledge_rules_dir>/<miền>.md`), nội dung đều lấy từ artifact đã duyệt — lệnh không có tham số
  `--id`, `--file` cho agent tự chọn. ID trùng luật của việc khác → spec chặn.
- **Nguồn bền, có phiên bản**: `[JIRA]`/`[CONFLUENCE]` lấy phiên bản ở bảng `## Sources` của spec;
  `[FILE]` lấy sha commit cuối của file. Lời người (`intake.md`, câu trả lời trong `open-questions.md`)
  là trạng thái của việc, sẽ mất — nên ghi `[HUMAN]` và **chép nguyên văn** vào `Quote:`; phiên bản là
  ngày trong câu trả lời, không có thì dấu duyệt spec. `[INFERRED]`/`[OPEN-QUESTION]` không nâng được:
  luật phải truy được về người có quyền nói. Định dạng `(version: …)` thay cho `v<version>` vì phiên
  bản Jira là thời điểm `updated`.
- **Phạm vi máy suy**: `Expected files` của task phủ YC, trừ file test và thư mục ADR/luật — truy được,
  không do agent khai.
- **Khối tìm theo ID, không theo file**: người được dời khối vào `ARCHITECTURE.md` của module (một chỗ
  cho mọi thứ của module); checker quét thư mục luật và `knowledge_files`.
- Implement và review dựng lại khối từ YC và so (bỏ `Status`) — như ADR. Không xoá luật: đổi
  `Status: superseded by BR-…`; đổi luật cũ là một PR có người duyệt, không đi qua lệnh nâng.
- `aw rule check` chặn hình thức (ID duy nhất, đủ trường, `Source` có nhãn và phiên bản, `Status` hợp
  lệ, `superseded by` trỏ tới luật có thật); luật active chưa có test `covers:` chỉ cảnh báo.

### Kiểm chéo lỗi thời: cảnh báo ở implement, verdict ở review

Tài liệu lệch code đẩy agent đi sai mà nó vẫn tin là đúng. Máy không biết một thay đổi có làm tài
liệu sai không, nhưng biết diff có đụng **phạm vi** của tài liệu không:

- Phạm vi: tài liệu module = thư mục chứa nó; ADR accepted = `Scope`; file luật = hợp `Scope` các luật
  active. Diff không tính chính các tài liệu và thư mục ADR/luật.
- Đụng phạm vi mà tài liệu không đổi → **cảnh báo** ở implement: hay báo nhầm (sửa lỗi nhỏ không đổi
  kiến trúc), chặn ở đây làm tắc flow và người học cách lách.
- Review **chặn** khi thiếu verdict cho tài liệu bị ảnh hưởng (`## Durable knowledge`): `pass` (đã
  đọc, vẫn đúng), `updated` (sửa trong diff — máy kiểm có sửa thật), `not applicable` + lý do. Máy
  không kiểm verdict đúng — như `## Repo rules`; tài liệu sai mà không ai sửa là finding của Lens 3.
- Luật active trong phạm vi diff chưa có test `covers:` chỉ cảnh báo ở implement, không thành điều
  kiện review: thiếu test cho luật cũ không phải lỗi của việc này.
- Hình thức thư mục ADR chỉ chặn việc có nâng ADR: thư mục hỏng sẵn trên base không được chặn mọi việc.

## Hai loại điều kiện ra

- **MÁY** — lệnh in `Kết quả` `[x] ĐẠT`/`KHÔNG ĐẠT`. Tiêu chí diễn đạt được bằng máy thì **phải**
  để máy kiểm; "agent tự đánh giá là đạt" là chỗ trống có hình dáng tiêu chí.
- **NGƯỜI** — agent nêu ra và dừng.

Adapter **từ chối build** nếu `exit_machine` không phải lệnh chạy được — nếu không, dòng chữ lọt
vào mục MÁY và agent tự duyệt (đã xảy ra một lần ở `review` khi xây repo này).

### Gate người để lại dấu trong file

Gate ở `intake`, `spec`, `design`, `review` (và `ship`). Gate nào có phase máy chạy ngay sau thì
phải để lại dấu trong file: ô `- [ ] **Approved by human**` ở spec và từng D-xx. Gate chỉ nằm
trong tài liệu thì agent chạy tiếp trên spec chưa ai đọc.

Checkbox chứ không phải chữ gõ tay (gõ sai một dấu là checker không nhận). Vì LLM quen tick
checklist, ô duyệt có thêm hai lớp (`tools/lib/duyet.sh`):

- **Dấu duyệt**: lần đầu thấy tick, máy ghi hash nội dung `<!-- approval-hash: … -->`. Nội dung đổi
  mà tick còn → chặn. Hash bỏ qua dòng trống, chú thích, `- Critique (agent):` (Mode 2 phản biện
  không làm mất duyệt). `based_on` bỏ qua dấu duyệt nên ghi dấu không làm artifact sau lỗi thời.
- **Hook `aw guard`** (người tự cài; adapter không ghi settings): `pre` ghi dấu cho ô người vừa
  tick và đặt mốc; `post` thấy ô được tick **trong lúc lệnh agent chạy** hoặc nội dung đổi sau dấu
  → bỏ tick, trả mã 2. So trạng thái file trước/sau nên bắt được Edit, Write lẫn `sed -i`, không
  cần đọc JSON (không có jq).

**Cổng duyệt** (`approval_gate: true`): gõ lệnh phase sau khi chưa duyệt thì `aw approval` in tóm
tắt **do máy dựng** (file/dòng phải tick, YC `[INFERRED]`, Out of scope, Risk, điểm mù; hay D nào
chưa duyệt) rồi agent hỏi hộp xác nhận. Máy dựng để thông tin ổn định, không bị chọn lọc. Hộp
**không** tick hộ: bấm nút không chứng minh người đã đọc, và máy không phân biệt "agent tick vì
người bấm" với "agent tự tick".

Parser chỉ nhận ô đúng chỗ (spec: trước `##` đầu tiên; D-xx: trong `### D-NN`), đúng một ô; ô
trong chú thích hay khối code không tính; sai dạng là lỗi, không đoán.

`plan` và `implement` **không có người**: chỉ thực thi điều đã duyệt; đặt người ở đó chỉ thêm
một chỗ duyệt văn xuôi không có quyết định thật.

### Checker LLM: chỉ được chặn

Điều script không kiểm được (lệch D-xx, quyết định ngầm) giao checker LLM, với ràng buộc: ghi phát
hiện ra **file**; script fail nếu còn `Chặn` chưa xử lý; LLM **không bao giờ** nói "đạt"; người là
trọng tài theo ngoại lệ. Cho LLM duyệt là quay lại "agent tự đánh giá là đạt"; cho nó chỉ chặn thì
sai sót chỉ tốn thời gian người.

### Chặn hay cảnh báo

| Loại checker | Ví dụ | Hành vi |
|---|---|---|
| **Chính xác** — hợp đồng output của chính phase | truy vết nguồn, phủ YC, test xanh | **Chặn** |
| **Kiểm chéo giữa phase**, hay báo nhầm | lỗi thời, test ↔ YC, phạm vi diff | **Cảnh báo**; `review` chặn |

Chặn nhầm làm tắc flow và người học cách lách. Mọi cảnh báo dồn về `review` (cổng cuối). Tiêu chí
xếp checker mới: độ chính xác, chi phí nếu lọt, nơi sửa rẻ nhất.

### Artifact lỗi thời

`based_on` là hash **cả file** đầu vào, dạng phẳng `- spec.md@<hash>` (đọc được bằng tập con
YAML). Cả file thay vì từng mục: đơn giản, không bỏ sót — nhưng báo cả sửa chính tả, nên chỉ cảnh
báo. Chuỗi: `spec` ← `intake`; `tdd` ← `spec` + `open-questions`; `plan` ← `spec` + `tdd`.

## Quyết định là thứ người duyệt

Người lướt văn xuôi dài vì không thấy đâu là lựa chọn thật. Nên `design` tách lựa chọn thành
**D-xx**; mục chi tiết ghi `Based on: D-xx`; checker LLM chặn chỗ lệch và quyết định ngầm. D được
phép rỗng. `tdd.md` là output duy nhất (tách file quyết định thì hai file lệch nhau).

- **Mode 2 chống neo**: agent đưa phương án trước thì người neo vào nó. `Risk: high` → người phác
  D-xx trước, agent chỉ phản biện; chưa có bản phác → chặn.
- **Mở lại**: đúng một D, sửa tại chỗ (git giữ lịch sử), bỏ tick + `Reopen reason:`; grep
  `Based on: D-xx` ra task bị ảnh hưởng, chỉ chúng về `[ ]`.
- **`plan` tách khỏi `tdd.md`**: plan là ranh giới do **phiên khác** đặt cho `implement`, và tick
  task không được sửa vào thiết kế đã duyệt.

## Giả định chưa xác nhận

`[OPEN-QUESTION]` mang **một trong ba mức chặn** (thêm mức thì người phải phân biệt ranh giới không
ai đo được). Mỗi mức đặt cổng ở **phase rẻ nhất để sửa** nếu giả định sai: lật hướng thiết kế
(`blocking`) phải biết trước design; sai một phần code (`review-blocking`) biết trước merge là đủ;
còn lại (`non-blocking`) giao trên giả định, review ghi `pending`.

`/aw-clarify` dẫn người qua hàng đợi do **máy** xếp (`aw pending`: mức chặn → `must` trước → nhiều
task đứng trên giả định hơn), hỏi từng mục với phương án agent đã phân tích. Câu trả lời trong hội
thoại **là** gate người của điểm mù; dấu vết ở `Answer:` (ai, ngày, nguyên văn). Spec đã tick mà bị
sửa theo câu trả lời thì bỏ tick, người tick lại — máy không phân biệt "sửa người vừa xác nhận" với
"sửa người chưa thấy".

**Gộp ở chỗ người nhìn, không gộp chỗ lưu**: điểm mù và phát hiện LLM ở file riêng (mỗi file một
bên ghi, checker LLM ghi đè cả file, `based_on` băm cả file — chung file thì checker ghi phát hiện
làm `tdd.md` lỗi thời). Checker LLM mới chỉ cần ghi `phat-hien-<id>.md` đúng mẫu là `aw pending` gom.

## Bằng chứng do máy ghi

- **Checker tự chạy test** và ghi `ket-qua-kiem-thu.md`: để agent dán kết quả thì chỉ kiểm được
  *cái agent nói*.
- **Trạng thái task do máy giữ**: chỉ `aw task done` lên `[x]` — chạy lệnh của `Verify`, ghi
  `ket-qua-task.md`, xanh mới đổi. Chặn `[x]` thiếu bằng chứng hoặc bằng chứng của lệnh `Verify`
  cũ. **WIP = 1** (`start` từ chối khi đã có `[~]`). Thủ công thì `--manual "<bằng chứng>"`.
  **Đỏ liên tiếp có trần** (`SO_LAN_DO_TOI_DA`) — điều kiện dừng của vòng lặp, không thì thử tới
  hết token. Vòng lặp nằm ở lệnh `aw`, nên agent nào chạy shell cũng lặp được.
- **`aw ready`** đầu phiên: test xanh trên code chưa sửa. Base đỏ mà vẫn làm thì không phân biệt
  lỗi mình với lỗi có sẵn, và agent hay "sửa" test có sẵn. Nó cũng in bước tiếp.
- **Quét bảo mật chạy ở `implement`** bằng đúng lệnh CI (`LENH_KIEM_TRA_BAO_MAT`, nhóm `secret |
  sast | sca | other`): lỗi quét ra là việc sửa code; review bị cấm sửa code, và quét chậm. Review
  chỉ kiểm kết quả xanh và **còn mới**. Thiếu nhóm chỉ cảnh báo; riêng chore đụng dependency phải
  có `sca` xanh.
- **Độ mới theo `Tree`**, không theo HEAD: tree SHA của nội dung worktree (đã/chưa commit, chưa
  track, trừ `.agent-workflow/`), tính bằng index tạm. Theo HEAD thì sửa chưa commit lọt, còn commit
  đúng code đã review lại bị coi lỗi thời. `review.md` ghi `Reviewed tree:` để kết luận gắn với
  đúng code đã rà.

## Review

- **Phiên chính chỉ bàn giao**: lệnh `/aw-review` không nạp mô tả phase — subagent ngữ cảnh sạch
  (`ra-soat-doc-lap`) mang mô tả đầy đủ và làm việc. Nạp vào phiên chính chỉ tốn ngữ cảnh.
- **Lens 4 — bảng bảy hạng mục cố định**: máy quét bắt *mẫu*, người rà bắt *ý đồ* (thiếu kiểm
  quyền, log lộ PII, IDOR). Danh sách mở thì "không thấy gì" và "không xét" trông như nhau. Máy
  kiểm hình dạng (đủ dòng, verdict hợp lệ, có vị trí/lý do), không biết `pass` có đúng không.
  Parser Lens 1 chỉ đọc dòng có **ô đầu** là mã YC.
- **Lens 3 và Conclusion**: có finding **hoặc** `- None`; finding đủ trường để người khác kiểm lại;
  số Blocker ở Conclusion khớp số mục (`aw check ship` đếm theo đó).
- **Code nhạy cảm theo đường dẫn, không theo loại việc**: rủi ro nằm ở chỗ code bị đụng
  (`sensitive_code`). Diff đụng vào → một **người** ghi `Security reviewer:`. Máy chỉ kiểm dòng có
  và không phải tên agent; bỏ trống khoá = tắt luật.
- **Category tự do (kebab-case)**: danh sách cố định hoặc quá thô hoặc dài tới mức chọn bừa;
  `aw journal` liệt kê tên đã có để dùng lại.

## Kiểm chéo, trạng thái sạch, nhật ký

- Test ↔ YC (`covers:`) và phạm vi diff ("Expected files" + "Unplanned") chỉ cảnh báo. Phạm vi so
  từ `git merge-base <base> HEAD` **tới cây làm việc** + file chưa track, bỏ `.agent-workflow/`.
- **Trạng thái sạch**: task `[ ]` sót, dấu xung đột merge → chặn. Dòng test *thêm mới* khớp
  `skipped_test_regex` → cảnh báo (chỉ dòng mới, để test tắt từ trước không đổ lên việc này).
- **Nhật ký harness** (`$AW_CONFIG/journal/`): `checks.tsv` (engine ghi mỗi `aw check`),
  `failures.tsv` (người/agent ghi lỗi checker không bắt, gắn một lớp `task | context | env |
  verify | state | model` — `model` là lớp cuối, đổi model là lựa chọn đắt nhất), `findings.tsv`
  (finding theo `Category` khi review đạt). Loại lặp ở ≥ 2 việc → `[GỢI Ý]` nâng thành luật máy;
  máy không tự thêm luật vì luật sai chặn mọi việc sau.

## Quy tắc riêng của repo

Khoá `rules_<phase>` trong `conventions.md`, agent lấy bằng `aw rules <phase>`:

- **Đọc lúc chạy**, không chép vào lệnh lúc build (cấu hình sửa nhiều lần; chép thì lệch mà không ai biết).
- **Đọc như tài liệu**, không dựa vào skill tự kích hoạt (agent khác không thấy skill).
- **Máy kiểm phần chính xác**: file có, đã commit, khoá không gõ nhầm; `review.md` có kết luận
  từng file. Tuân thủ thật là người phán.
- Xếp **dưới** artifact: skill bảo "dọn file đụng tới" không thắng luật giữ diff trong phạm vi.

## Tiết kiệm ngữ cảnh của agent

Mỗi lần gọi `/aw-*`, agent nạp file lệnh + những gì lệnh bảo đọc. Vì vậy:

- File phase chỉ giữ **chỉ thị** (mục tiêu, đầu vào, việc phải làm, cấm, điều kiện ra); lý do nằm
  ở file này.
- **Agent đọc tiếng Anh, người đọc tiếng Việt.** Cùng một ý, tiếng Việt tốn nhiều token hơn đáng
  kể, nên thân phase, rules, checker LLM và lời dặn adapter viết tiếng Anh. Mọi thứ người thấy giữ
  tiếng Việt: `name`/`summary`, mẫu artifact, output và nhãn `Kết quả` của `aw`, câu hỏi/lựa chọn
  hiện cho người; agent được dặn nói và viết artifact bằng tiếng Việt. Nhãn của `aw` được nhắc
  nguyên văn trong chữ tiếng Anh như hằng số.
- Mỗi luật một chỗ: bảng mức chặn ở `rules/truy-vet-nguon.md`; hợp đồng vào/ra do adapter dựng từ
  frontmatter, thân phase không lặp lại.
- `rules/truy-vet-nguon.md` chỉ nạp cho lệnh khai `trace_rule: true`; `conventions.md` để "tra khi
  cần", không bắt đọc hết.
- Danh sách điều máy kiểm nằm trong checker và in ra khi vi phạm; file phase chỉ tóm tắt.

## Định dạng file phase

Frontmatter (tập con YAML) + thân markdown:

```yaml
---
id: spec                    # ASCII, trùng tên lệnh
name: Viết đặc tả           # tên hiển thị
summary: ...                # một dòng, mô tả lệnh
required: true              # false = tuỳ chọn
when: ...                   # chỉ khi required: false
status: chưa hiện thực      # có mặt = adapter bỏ qua
inputs: [intake.md, confluence, jira, file]
outputs: [spec.md, open-questions.md]
exit_machine: [aw check spec]          # phải là "aw check <tên>" có trong tools/lib/bang-lenh.sh
exit_human: [...]
needs_clean_context: true   # chạy được từ phiên trắng
requires_fresh_agent: true  # chạy qua subagent ngữ cảnh sạch; lệnh chính chỉ bàn giao
llm_checker: workflow/checkers/thiet-ke.md
arguments: input            # tham số là input, không phải tên feature (00-intake)
approval_gate: true         # mở đầu bằng cổng duyệt (02-design, 03-plan)
runs_on_main_checkout: true # có việc ở checkout chính (06-ship)
trace_rule: true            # lệnh bảo đọc rules/truy-vet-nguon.md
---
```

Thân có mục cố định: **Mục tiêu**, **Đầu vào**, **Việc phải làm**, **Đầu ra**, **Cấm**, **Điều
kiện ra**. Mục **Cấm** chặn thất bại đặc trưng nhất: `01-spec` chọn giải pháp kỹ thuật,
`04-implement` sửa "tiện tay" — cả hai xoá mất điểm dừng để người xem lại.

Lệnh tiện ích (`commands:` trong manifest — `import`, `clarify`, `bootstrap`): `id`, `name`, `summary`,
tuỳ chọn `argument_hint`, `arguments: mixed`, `choice_ui: true`, `trace_rule: true`,
`runs_on_main_checkout: true`. Checker LLM
(`workflow/checkers/*.md`): `id`, `summary`, `inputs`, `output`, `quy_tac`; adapter biến thành
subagent `soat-<id>`.

## Hiện thực các cơ chế

| Cơ chế | Nằm ở | Ghi chú |
|---|---|---|
| Xác định feature | `tools/xac-dinh-feature.sh` | Gốc worktree từ `AW_REPO` |
| Đọc `conventions.md` | `conv_get` (`tools/lib/md.sh`) | Chỉ đọc khối ` ```conventions ` |
| Quy ước hiệu lực | `qu_hieu_luc` (`tools/lib/md.sh`); `mt_dat`, `kc_conventions` gọi | Repo (điểm rẽ khỏi base) + khoá máy của bản clone |
| Kiểm `conventions.md` | `tools/kiem-tra-quy-uoc.sh` | Khoá biết = khoá trong mẫu + `rules_<phase>`; `aw ready` gọi |
| Hash `based_on` | `tools/cap-nhat-based-on.sh`, `file_hash` | `cksum` sau khi bỏ `\r` |
| Kiểm chéo | `tools/lib/kiem-cheo.sh` | Một hàm; `implement` gọi là cảnh báo, `review` gọi là lỗi |
| Mức chặn điểm mù | `kc_diem_mu_mo` | design (chore: plan) chặn `blocking`; implement cảnh báo, review chặn cả `review-blocking` |
| Hàng đợi việc chờ người | `tools/liet-ke-viec-cho.sh` | Chỉ đọc |
| Entry check | Đầu mỗi `kiem-tra-*.sh` | `ra-soat → ke-hoach → thiet-ke → truy-vet` |
| Ghim version của việc | `kc_engine_dong`; `bin/aw-engine check`; `bin/aw` | |
| Tên checker, phase có quy tắc | `tools/lib/bang-lenh.sh` | Một bảng cho `aw check` và cho adapter |
| Một awk đọc nhiều file | mọi `kiem-tra-*.sh` | Dùng `FILENAME == ARGV[i]`, **không** đếm `FNR==1` (file 0 byte làm lệch) |

## Tập con YAML

`tools/lib/md.sh` chỉ đọc `khoa: gia tri`, `khoa:` + `  - muc`, `khoa: []`. Không có map lồng,
khối nhiều dòng, flow không rỗng, chú thích cuối dòng, anchor. Đánh đổi có chủ ý: trình đọc đầy đủ
kéo theo Node/Python (máy dựng repo này không có). Chỉ áp cho cấu hình của engine.

## Cách thêm một phase

1. `workflow/phases/NN-<id>.md` với frontmatter đầy đủ; thêm vào `phases:` của `workflow.yaml`.
2. Có `exit_machine` → script trong `tools/`, thêm tên vào `tools/lib/bang-lenh.sh`.
3. Artifact mới → mẫu trong `workflow/templates/`.
4. Ca kiểm trong `tools/chay-thu.sh`.
5. Thử: `AW_ENGINE_DIR=<repo này> aw adapter build claude-code` (VERSION khớp repo đích).

Không phase nào khác phải sửa — không phase nào biết về phase sau nó (vì vậy `06-ship` thêm được sau).

## Cách thêm một adapter

Xem `adapters/README.md`. Việc sinh ở `adapters/lib/chung.sh`; adapter chỉ khai hook (chữ riêng
của agent). Test đối chiếu đòi output mọi adapter giống hệt nhau khi hook thay bằng tên. Khả năng
nào không dịch được sang agent đích (subagent, hook, MCP) thì **ghi rõ trong output** người phải
tự làm — bỏ qua âm thầm khiến quy trình *nhìn như* đủ mà đã mất ràng buộc.

## Những chỗ thiết kế này yếu

1. **`06-ship` chỉ lo MR**, không lo deploy/tag/release note. Không có `gh`/`glab` thì trạng thái MR
   chỉ suy từ git, không nhận ra squash có sửa xung đột.
2. **"Ngữ cảnh sạch" không cưỡng chế được ở agent không có subagent** — lùi về lời dặn người.
3. **Checker kiểm hình thức, không kiểm nội dung.** Mọi YC có nhãn ≠ YC đúng với BRD. Đừng nhầm "qua
   hết checker" với "làm đúng"; checker LLM chỉ thu hẹp khoảng trống này.
4. **Mode 2 dựa vào nhãn `Risk` đúng** — người cho qua `normal` sai thì neo quay lại.
5. **Hash cả file báo cả thay đổi vô hại** — nên chỉ cảnh báo, và người có thể quen tay bỏ qua.
6. **Tập con YAML dễ vỡ** — sai cú pháp trả về rỗng, lỗi lộ muộn.
7. **Máy không biết ai tick.** Hook chỉ có khi repo cài và agent có hook; không có hook thì agent tự
   tick vẫn lọt (artifact ngoài git, không có `git blame`). Hook không bắt dấu giả agent tự tính, và
   bỏ nhầm tick nếu người tick đúng lúc lệnh agent đang chạy. Nội dung đổi **trước** lần ghi dấu
   đầu tiên cũng lọt.
8. **`review` không chạy lại test hay quét** — biết kết quả cũ, không biết lệnh có đủ. Lệnh lệch
   pipeline thì local xanh mà CI chặn. Lệnh ghi file vào repo (không `.gitignore`) làm `Tree` đổi.
9. **Glob dùng `case` của shell**: `*` khớp cả `/`, không có `**` — `src/*` rộng hơn người đọc tưởng.
10. **Artifact không đi theo PR** — reviewer chỉ thấy code. D-xx người chọn nâng thì đi theo PR dưới
    dạng ADR; phần còn lại của `tdd.md` thì không.
11. **Ghim sha256 là tin lần đầu (TOFU)**; repo cấu hình chung của team thu hẹp, không xoá rủi ro.
12. **Tuân thủ quy tắc repo chỉ do người phán** — quy tắc viết được thành lệnh nên vào `LENH_KIEM_THU`.
13. **File máy ghi giả được** (`ket-qua-task.md`, `ket-qua-kiem-thu.md`): chặn việc *quên*, không chặn
    gian lận có chủ ý; review ngữ cảnh sạch là lớp sau.
14. **Nhật ký harness chỉ ở từng máy**; `Category` tự do có thể đếm hụt.
15. **Việc không thấy quy ước mới của chính nó** — đúng ý đồ, nhưng việc sửa `conventions.md` để
    hợp lệ hoá thay đổi của mình (vd thêm `production_code`) sẽ bị chấm theo luật cũ tới khi merge.
16. **Quy ước chưa commit ở checkout chính** có hiệu lực ngay cho mọi việc rẽ từ base chưa có file;
    trước khi pull bản đã merge, người phải xoá bản chưa track (git từ chối ghi đè).
17. **Bản hiệu lực làm mới khi script đọc quy ước**: agent mở `.engine/conventions.md` trước mọi
    lệnh `aw` của phiên thì có thể thấy bản cũ (mọi phase đều chạy `aw feature` trước).
18. **Số ADR cấp lúc nâng, theo thư mục ở worktree**: hai việc song song cùng lấy `0004`; PR merge sau
    có hai file trùng số (`aw adr check` chặn ở việc kế tiếp) và xung đột ở bảng chỉ mục — người
    đổi số, chạy lại `aw adr promote`.
19. **"Đi ngược ADR" chỉ checker LLM thấy** — máy chỉ kiểm `Supersedes` khi D tự khai.
    Tương tự, nguồn mới mâu thuẫn với luật `BR-` active chỉ agent spec và người phát hiện.
20. **PRD đổi sau khi luật đã nâng**: máy không theo dõi Confluence/Jira; phiên bản ghi trong `Source`
    chỉ cho người so tay. Luật cũ vẫn `active` tới khi một việc thay nó.
21. **Phạm vi thô**: glob `case` (`*` khớp cả `/`), tài liệu module phủ cả thư mục — sửa một file test
    trong `src/` cũng đòi verdict cho `src/ARCHITECTURE.md`. Verdict `pass` rẻ, nhưng người có thể quen
    tay ghi `pass` không đọc.
