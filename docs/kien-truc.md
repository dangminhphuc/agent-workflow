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
                        01-spec ─▶ spec.md ─▶ 02-design ─▶ tdd.md    (chore, Design: skip: bỏ design)
                                   ▼                       ▼
                                03-plan ◀──────────────────┘
                                   ▼
                                plan.md ─▶ 04-implement ─▶ diff + *-results.md
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
- **Artifact ngoài vẫn qua human gate** của phase lẽ ra sinh ra nó.
- **Import có kiểm soát** (`/aw-import`): chỉ sắp lại theo mẫu, **không thêm nội dung** — nếu
  được thêm, suy đoán của agent sẽ mang source label như có trong tài liệu gốc.

### `00-intake`: một gốc cho mọi việc

`intake.md` = job type + input + một câu mục tiêu. Bắt buộc vì:

- **Job type đổi luật** (bugfix cần test tái hiện, refactor cấm hành vi mới, perf cần số đo,
  chore không đụng production) — nên phải là dữ liệu máy đọc.
- **Mọi REQ có đúng một gốc**: spec chỉ đọc input được liệt kê.

Intake chỉ **trỏ tới** tài liệu, nhận tài liệu có định danh hoặc lời người **nguyên văn**
(`[HUMAN]`); cấm `[INFERRED]` — nếu không, suy đoán sẽ sang spec với nhãn `[FILE] intake.md`.

**Nhãn input do máy gán** (`aw input`): checker chỉ kiểm được cú pháp nhãn, agent gắn `[JIRA]` cho
URL GitHub vẫn lọt. Quyết trên **cả chuỗi**: một từ không nhận ra là cả tham số thành lời người —
tách từng từ sẽ thành input rác và mất câu gốc. Chạy lại chỉ **gộp thêm**; `spec.md` ghi
`based_on: intake.md` nên input mới làm spec stale.

**Nguồn sự thật của job type** là `intake.md`. Tiền tố branch chỉ gợi ý; lệch thì review chặn,
không có ngoại lệ "ghi lý do" (ngoại lệ dễ ghi hơn sửa, tiền tố sẽ mất nghĩa). `aw rename` đổi
branch, thư mục artifact, worktree trong một lệnh.

Phân loại theo **thay đổi gì về hành vi**: loại chỉ tồn tại khi nó đổi luật — nên không có
`utils`, `hotfix`, `security`; `spike` nằm ngoài (output là kết luận, không phải code).

Mẫu chung cho bằng chứng theo loại: **máy tự chạy và tự ghi**, **máy chặn phần chính xác**,
**người phán phần mơ hồ**:

| Loại | Máy chặn | Người phán | Vì sao không để máy phán |
|---|---|---|---|
| `bugfix` | `repro.md` ghi lúc diff chỉ đụng file test, `ĐỎ` | Đỏ **đúng vì bug** | Test mới trên code cũ có thể đỏ vì lỗi biên dịch |
| `refactor` | Xoá test cũ; sửa test cũ không khai; REQ preserve không có test trên nhánh gốc | Diff test cũ chỉ đổi import | "Chỉ đổi import" phụ thuộc ngôn ngữ, hay báo nhầm |
| `perf` | Thiếu số đo trước/sau | Đạt mục tiêu chưa | Số đo dao động; chặn theo ngưỡng sẽ nhầm |
| `chore` | Đụng `production_code`; dependency không khai; khai `major` | Mức phiên bản đúng | Cú pháp phiên bản mỗi hệ sinh thái mỗi khác |

Không dựng lại code cũ để chạy test tái hiện: trông chặt hơn nhưng kết luận sai mà tự tin (đỏ vì
thiếu hàm vẫn tính là "tái hiện được").

### Artifact theo feature, worktree bắt buộc

- Artifact ở `docs/sdlc/<tên-branch>/`, tên branch **đầy đủ** để feat và refactor cùng tên
  không đè nhau. Agent luôn in `Đang làm với: …` — ghi nhầm feature là lỗi im lặng.
- **Artifact commit vào branch của việc, không bao giờ vào nhánh đích.** Trước đây artifact chỉ ở
  máy (`.agent-workflow/`, bị exclude): mất máy hay gỡ worktree là mất. Mở phiên ở máy khác cũng
  không có. Giờ:
  - Mỗi `aw check` ĐẠT (và `aw approvals tick`) commit **chỉ** thư mục việc. Lệnh dùng
    `git add -f`, commit với pathspec để không cuốn phần người đã stage, và `--no-verify`.
    Hook của repo viết cho code: lint-staged định dạng lại artifact thì mất approval hash,
    commit-msg có thể từ chối.
  - `aw ship create` gỡ thư mục khỏi branch bằng một commit trước khi push. Diff của MR không có
    artifact, nên lý do cũ, reviewer đọc nhiễu, vẫn được giữ.
  - Đặt commit trong `aw check`, không tách thành lệnh agent tự gọi: agent quên thì artifact không
    vào git mà không ai biết, và cùng một bước sẽ phải lặp ở mọi phase.
  - `docs/sdlc/` vẫn bị exclude: file đã track thì git vẫn theo dõi, file mới thì `git add -A`
    không kéo vào commit code. Sau khi ship, file thành chưa track (bị exclude); dấu `.local-only`
    giữ cho `aw check` không commit lại, vì commit lại là artifact quay về MR.
  - Diff, `Tree`, quét tài liệu bỏ qua cả `docs/sdlc/` lẫn `.agent-workflow/` (`tm_bo`,
    `tools/lib/md.sh`). Commit artifact không làm `stale` kết quả máy ghi, cũng không bị tính là
    file ngoài phạm vi.
  - Lớp chặn ở `aw ship create`: sau khi gỡ mà MR vẫn mang file trong `docs/sdlc/` (thư mục việc
    khác, từ branch xếp chồng hoặc commit tay) thì chặn. Máy không tự gỡ thư mục của việc khác.
  - Đường dẫn cố định (`TM_VIEC`), không cấu hình, cùng lý do với `conventions.md`.
  - Tương thích ngược: việc bắt đầu bằng engine cũ vẫn ở `.agent-workflow/<tên>/` (`tm_viec`):
    đọc được, không commit. `.agent-workflow/` vẫn là thư mục cục bộ của engine (`.engine/`,
    `.adapters`, `.guard-pre`).
  - Giới hạn: lịch sử artifact chỉ còn trong commit của branch, nên squash-merge hay xoá branch là
    mất (archive vẫn còn). Merge tay không qua `aw ship create` thì artifact vào nhánh đích; engine
    không chặn được ở phía server.
- Main checkout chỉ chạy `/aw-intake`, `/aw-bootstrap` (đề xuất worktree) và dọn ở `/aw-ship`; `aw feature`
  chặn mọi lệnh khác ở đó.
  Chốt đặt ở script mọi phase đều gọi — "fresh session" thành cấu trúc, không còn là khuyến nghị.
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

Bộ cài cũ chép quy trình vào target repo và bắt commit vào nhánh gốc. Đổi vì:

1. **Protected branch** — cài/nâng cấp phải qua PR vào nhánh được bảo vệ. Giờ engine ở
   `~/.agent-workflow/engine/<V>/`, cấu hình ở `$(git rev-parse --git-common-dir)/agent-workflow/`,
   file sinh ra bị `.git/info/exclude` → **base tuỳ ý**. Quy ước của repo thì ngược lại: nằm trong
   git và qua PR (mục "Trạng thái của việc và durable knowledge") — lý do trên nhắm vào *cài/nâng cấp
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
| `tools/lib/env.sh` | Tool đọc đường dẫn **chỉ** từ biến môi trường; không tự suy từ vị trí của nó |
| `checksums` | sha256 ghim lần đầu. Lần sau phải khớp sha đã ghim, không tin lại `SHA256SUMS` (cùng nguồn với tarball, chỉ bắt file hỏng, không bắt nguồn bị tráo) |

- Kênh tải: Release của repo này, file `agent-workflow-V.tar.gz` do workflow đóng gói — không dùng
  tarball GitHub tự sinh (byte không được hứa giữ nguyên).
- **Version đặt trong PR** (`tools/prepare-release.sh`), không để CI tự tăng (bot phải commit
  thẳng vào `main`, vượt bảo vệ nhánh). Merge chỉ *phát hành*: workflow `release` tạo tag + Release
  trong cùng job (tag tạo bằng `GITHUB_TOKEN` không kích được workflow khác). Hai PR cùng số: CI
  của PR chặn PR merge sau.
- Wrapper và engine có số giao thức (`AW_PROTOCOL`): lệch thì dừng, không chạy thiếu biến.
- **Artifact không vào PR**: commit vào branch của việc, gỡ trước khi tạo MR (mục "Artifact theo
  feature"); gỡ worktree thì chép vào `archive/` trước.

## Trạng thái của việc và durable knowledge

Bài kiểm tra phiên mới cho **target repo**: một phiên agent chỉ có repo phải trả lời được hệ thống là
gì, tổ chức ra sao, chạy và kiểm thế nào, **vì sao code như vậy**, đang ở đâu. Thứ gì chỉ ở một
máy thì với phiên đó coi như không có. Ranh giới:

| | Trạng thái của việc | Durable knowledge |
|---|---|---|
| Là gì | `intake/spec/tdd/plan/review`, `*-results.md`, approval checkbox đang chờ | Quy ước, quyết định, ràng buộc, luật nghiệp vụ còn đúng sau khi việc xong |
| Ở đâu | `docs/sdlc/<branch>/` — trong branch của việc, gỡ trước MR; gỡ worktree thì vào `archive/` | Trong git của target repo, qua PR |
| Vì sao | Nhiều, đổi liên tục, chỉ có nghĩa trong việc; vào PR thì reviewer đọc nhiễu | Phải đúng cho mọi bản clone và mọi việc sau |

Các mục dưới: `conventions.md` trong git, mẫu điểm vào và lệnh kiểm, ADR từ DEC-xxx, luật nghiệp vụ
`BR-`, cross-check stale. Ba rủi ro chung: **stale** (tài liệu lệch code còn tệ hơn không có —
mục cross-check), **nhồi nhét** (chỉ thứ người chọn nâng, không chép PRD — mục ADR, luật), **nguồn đổi
sau khi nâng** (điểm yếu 20). "Phiên mới trả lời được năm câu" máy chỉ kiểm điều kiện cần (đủ file,
`aw knowledge` in đúng file); phép thử với phiên agent thật là bước tay (README).

### `conventions.md` trong git, bản clone chỉ ghi đè khoá máy

- **Vị trí cố định** `docs/agent-workflow/conventions.md` (`QU_DUONG_DAN`, `tools/lib/md.sh`).
  Không cho cấu hình: chỗ đặt nó lại phải nằm trong một cấu hình khác, và mỗi máy trỏ một file là
  đúng thứ cần bỏ. Không đặt dưới `.agent-workflow/` (bị exclude; `--from-legacy` dùng
  `.agent-workflow/conventions.md` làm dấu hiệu bộ cài cũ) hay `docs/sdlc/` (gỡ khỏi branch trước MR).
- **Bản clone chỉ ghi đè `worktree_dir`** (`QU_KHOA_MAY`) — khoá duy nhất chỉ ảnh hưởng máy cục
  bộ. Khoá khác ở bản clone: `aw conventions check` báo ✗ và không có hiệu lực (nếu không, một máy
  lặng lẽ chạy luật khác cả team). Thêm khoá máy là thay đổi engine, có lý do.
- **Việc đọc bản ở điểm rẽ khỏi base** (`git show <merge-base>:…`), không đọc bản trong worktree.
  Đọc worktree thì việc tự nới luật của chính nó (xoá `sensitive_code`, đổi `test_files`) rồi
  checker chấm theo luật đã nới — trái "agent không tự duyệt". Như version engine ghim trong
  `intake.md`: luật của việc cố định lúc bắt đầu; sửa quy ước có hiệu lực cho việc sau khi merge.
  Main checkout, worktree chưa có `intake.md`, và việc rẽ từ base chưa có file đọc bản ở cây làm
  việc của main checkout (nhánh gốc — không phải chỗ agent của việc ghi vào).
- **Một bản hiệu lực**: `qu_hieu_luc` gộp hai nguồn thành `/quy-uoc-hieu-luc/<khoá>.md`
  (ngoài cây làm việc, không đổi `Tree`); mọi script và `.agent-workflow/.engine/conventions.md`
  đọc file đó — một chỗ quyết định, không có script nào đọc lệch.
- **Tương thích ngược**: repo chỉ có bản clone (init bằng engine cũ) chạy như cũ, `aw conventions
  check` cảnh báo kèm cách chuyển. `aw init`/`aw upgrade` không tự tạo file trong repo khi bản clone
  đã có — nếu tạo, mẫu sẽ thay giá trị team đang dùng. `aw init --from` chỉ bỏ `conventions.md` của
  repo cấu hình khi target repo đã có file (nếu chưa, bỏ là clone mới chạy bằng mẫu).


### Điểm vào và lệnh kiểm của target repo: khuyến nghị, không ép

- **Mẫu, không checker.** `templates/target-repo/AGENTS.md`, `Makefile`; `aw init` chỉ nhắc khi repo
  chưa có `AGENTS.md` lẫn `CLAUDE.md`. Máy kiểm được file *có*, không kiểm được nó trả lời đúng năm
  câu của phiên mới — chặn theo "có file" chỉ sinh file rỗng cho qua cổng. Mỗi repo cũng đã có bố
  trí riêng; engine ép một bố trí là đòi sửa repo để hợp công cụ.
- **`AGENTS.md` chỉ trỏ tới, 50–100 dòng.** Chép luật vào đó là luật có hai chỗ, một chỗ sẽ cũ —
  tài liệu lệch code còn tệ hơn không có. Nó đọc vào mọi phiên, nên mỗi dòng tốn ngữ cảnh mọi lần.
- **Lệnh kiểm nằm trong git (`make test`), `config.sh` chỉ trỏ tới.** Chép lệnh vào `config.sh`
  (ngoài git, mỗi máy một bản) thì local và CI lệch dần: local xanh mà pipeline chặn. Target mẫu
  chưa khai thoát mã 1 — "quên khai" không bao giờ thành xanh, đúng như `TEST_CMD` trống.
- `ARCHITECTURE.md` của module đi vào phase qua `rules_<phase>` có sẵn; cách nạp theo phạm vi diff
  là bước sau.

### `/aw-bootstrap`: dựng bản đồ một lần cho repo có sẵn

Các cơ chế trên chỉ đưa kiến thức vào git **theo từng việc**; repo đã chạy nhiều năm thì quyết định cũ
vẫn nằm ngoài. `/aw-bootstrap` làm phần đó một lần, theo đúng các luật trên:

- **Utility command, không phải job type mới.** Không có REQ, DEC-xxx hay human gate để kiểm — thêm loại
  việc là thêm checker cho thứ máy không chấm được (tài liệu có trả lời đúng năm câu không). Nó chạy
  trong worktree `chore` như mọi việc (main checkout chỉ đề xuất, người chọn base); kết quả là PR
  người duyệt.
- **Chỉ từ bằng chứng.** Mọi dòng ghi vào tài liệu kèm `file:dòng` hay commit; "vì sao" không có
  bằng chứng thành câu hỏi trong báo cáo. Bịa lý do cho một quyết định là tạo đúng loại tài liệu sai
  mà agent sau tin là thật.
- **ADR viết tay cho quyết định cũ**: đúng định dạng `aw adr check` nhận, `Origin` là commit/tài liệu
  gốc. Implement và review chỉ đối chiếu ADR nâng từ DEC-xxx của việc, nên ADR cũ không bị dựng lại để
  so — người duyệt PR là chốt nội dung.
- **Không viết luật `BR-`**: luật cần nguồn có phiên bản và người có quyền xác nhận — chỉ liệt kê ứng
  viên, chúng vào qua `/aw-spec` của việc kế tiếp chạm tới.
- **Trạng thái của việc vẫn ngoài git**: `## Status` của `AGENTS.md` trỏ tới nơi giữ tiến độ thật
  (issue tracker), không chép artifact của việc.
- Báo cáo (`<thư-mục-feature>/bootstrap.md`, ngoài git) đo **khoảng cách hiển thị** — số mục kiến
  thức còn ngoài repo trên tổng số — và ghi kết quả bài kiểm tra phiên mới; làm mô tả PR.

### ADR: DEC-xxx đã duyệt thành "vì sao" của repo

DEC-xxx là quyết định có giá trị nhất mà quy trình sinh ra, nhưng `tdd.md` là trạng thái của việc —
gỡ worktree là nó vào `archive/` của một máy. ADR đưa phần còn đúng sau việc vào git.

- **Người quyết nâng, trong chính DEC**: `- Promote: adr`, `- Scope:`, `- Supersedes:` nằm dưới dấu
  duyệt, nên duyệt DEC là duyệt luôn việc nâng. Không có cờ dòng lệnh `--supersedes`: tham số do
  agent gõ, không ai duyệt. Agent đề xuất được, không tự quyết được — như mọi trường khác của DEC.
- **Nâng ở implement, không sau review**: ADR là file trong diff; nâng sau review thì `Reviewed tree`
  lệch, `aw check ship` chặn mãi. Plan buộc có task `Based on: DEC-NNN` với `Expected files` gồm thư mục
  ADR (không thì diff lệch phạm vi); implement chạy `aw adr promote`; review đọc ADR như mọi code.
- **Chỉ chép**: nội dung DEC (trừ approval checkbox và ba trường trên) cộng nguồn. Nguồn không ghi `REQ-NNN` trần
  — số REQ theo từng spec, vô nghĩa sau việc — mà là `Source:` của các REQ mà task "Based on: DEC-NNN" phủ
  (plan → spec): truy được về Jira/Confluence. Máy dựng lại ADR từ DEC và so (bỏ `Date`, `Status`):
  sửa ADR bằng tay, hay DEC đổi sau khi nâng, đều chặn ở implement và review — chính xác nên chặn.
- **`Scope` bắt buộc**: không có phạm vi thì `aw knowledge` không biết ADR nào liên quan việc nào,
  và cross-check stale (bước sau) không có dữ liệu.
- **Không xoá ADR**: thay bằng `Status: superseded by NNNN`; người đọc sau vẫn thấy vì sao từng làm
  khác. Chỉ mục `README.md` dựng lại từ các file (giữ phần người viết phía trên bảng).
- **`aw knowledge` tách khỏi `aw rules`**: `rules` nghĩa là "đọc hết, review chấm từng file"; kiến
  thức bền lọc theo phạm vi (đường dẫn trong `## Existing code`) — trộn vào thì bảng `## Repo rules`
  phình theo số module. Design gọi hai lần: trước khảo sát (chỉ mục) và sau khi ghi `Existing code`.
- Đi ngược ADR mà không khai `Supersedes` máy không phát hiện được (cần hiểu nội dung) → LLM checker
  thiết kế chặn (`trái ADR`).

### Luật nghiệp vụ `BR-`: REQ đã duyệt thành bất biến của sản phẩm

`REQ-NNN` đánh số theo từng spec — việc sau không nhắc lại được, và luật từ PRD chỉ sống trong một
`spec.md`. Luật `BR-` là phần của REQ còn đúng sau việc: bất biến, không phải chi tiết màn hình.

- **Không chép PRD**: chỉ REQ người chọn. Chép toàn văn thì repo thành bản sao lệch của Confluence —
  nhồi nhét làm agent đọc nhiều mà quyết định không tốt hơn.
- **Người quyết trong REQ**: `- Promote: BR-<MIỀN>-NNN` nằm dưới approval hash spec. ID, file đích
  (`<knowledge_rules_dir>/<miền>.md`), nội dung đều lấy từ artifact đã duyệt — lệnh không có tham số
  `--id`, `--file` cho agent tự chọn. ID trùng luật của việc khác → spec chặn.
- **Nguồn bền, có phiên bản**: `[JIRA]`/`[CONFLUENCE]` lấy phiên bản ở bảng `## Sources` của spec;
  `[FILE]` lấy sha commit cuối của file. Lời người (`intake.md`, câu trả lời trong `open-questions.md`)
  là trạng thái của việc, sẽ mất — nên ghi `[HUMAN]` và **chép nguyên văn** vào `Quote:`; phiên bản là
  ngày trong câu trả lời, không có thì approval hash spec. `[INFERRED]`/`[OPEN-QUESTION]` không nâng được:
  luật phải truy được về người có quyền nói. Định dạng `(version: …)` thay cho `v<version>` vì phiên
  bản Jira là thời điểm `updated`.
- **Phạm vi máy suy**: `Expected files` của task phủ REQ, trừ file test và thư mục ADR/luật — truy được,
  không do agent khai.
- **Khối tìm theo ID, không theo file**: người được dời khối vào `ARCHITECTURE.md` của module (một chỗ
  cho mọi thứ của module); checker quét thư mục luật và `knowledge_files`.
- Implement và review dựng lại khối từ REQ và so (bỏ `Status`) — như ADR. Không xoá luật: đổi
  `Status: superseded by BR-…`; đổi luật cũ là một PR có người duyệt, không đi qua lệnh nâng.
- `aw rule check` chặn hình thức (ID duy nhất, đủ trường, `Source` có nhãn và phiên bản, `Status` hợp
  lệ, `superseded by` trỏ tới luật có thật); luật active chưa có test `covers:` chỉ cảnh báo.

### Cross-check stale: cảnh báo ở implement, verdict ở review

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

### Human gate để lại dấu trong file

Gate ở `intake`, `spec`, `design`, `review` (và `ship`). Gate nào có phase máy chạy ngay sau thì
phải để lại dấu trong file: ô `- [ ] **Approved by human**` ở spec và từng DEC-xxx. Gate chỉ nằm
trong tài liệu thì agent chạy tiếp trên spec chưa ai đọc.

Checkbox chứ không phải chữ gõ tay (gõ sai một dấu là checker không nhận). Vì LLM quen tick
checklist, approval checkbox có thêm hai lớp (`tools/lib/approval-tick.sh`):

- **Approval hash**: lần đầu thấy tick, máy ghi hash nội dung `<!-- approval-hash: … -->`. Nội dung đổi
  mà tick còn → chặn. Hash bỏ qua dòng trống, chú thích, `- Critique (agent):` (Mode 2 phản biện
  không làm mất duyệt). `based_on` bỏ qua approval hash nên ghi dấu không làm artifact sau stale.
- **Hook `aw guard`** (người tự cài; adapter không ghi settings): `pre` ghi dấu cho ô người vừa
  tick và đặt mốc; `post` thấy ô được tick **trong lúc lệnh agent chạy** hoặc nội dung đổi sau dấu
  → bỏ tick, trả mã 2. So trạng thái file trước/sau nên bắt được Edit, Write lẫn `sed -i`, không
  cần đọc JSON (không có jq).

**Cổng duyệt** (`approval_gate: true`): gõ lệnh phase sau khi chưa duyệt thì `aw approval` in tóm
tắt **do máy dựng** (file/dòng phải tick, REQ `[INFERRED]`, Out of scope, Risk, open question; hay DEC nào
chưa duyệt) rồi agent hỏi hộp xác nhận. Máy dựng để thông tin ổn định, không bị chọn lọc. Hộp
cổng **không** tick hộ: nó hỏi "đã duyệt xong chưa", không hỏi duyệt mục nào.

**Duyệt tập trung** (`/aw-approvals`, `tools/approvals.sh`): nhiều việc song song thì mở từng
artifact để tick là việc tay lặp lại, dễ sót. Luật được nới **về hình thức, không về thực chất**:
điều phải giữ là *quyết định* đến từ người, không phải *phím `x`*. Người chọn **Duyệt** cho đúng
một mục → agent chạy `aw approvals tick <dir> <khoá> <hash>`. Chặn agent tự duyệt bằng nhiều lớp:

- **Hash bản người thấy**: danh sách in hash nội dung hiện tại; `tick` chỉ ghi khi hash vẫn khớp —
  nội dung đổi giữa lúc hỏi và lúc tick thì không tick. Ngoại lệ chỉ cho `tick`, không cho sửa file:
  `aw guard` vẫn bỏ tick ghi bằng Edit/Write/`sed`.
- **Luật hỏi quyền của agent** (Claude Code `permissions.ask`, Cursor: ngoài allowlist): mỗi lần
  tick, harness hỏi người — lớp duy nhất agent không tự vượt được. Người tự cài, như hook.
- **Nhật ký** `journal/approvals.tsv`: tick qua lệnh để lại dòng, tick tay thì không.

Không dùng "một nút duyệt tất cả": một câu trả lời duyệt đúng một mục, để mỗi lần bấm gắn với một
nội dung cụ thể. Liệt kê mặc định chỉ worktree hiện tại (mỗi việc một phiên); `--global` gom mọi
worktree của bản clone, chạy được cả ở main checkout — lệnh khai `feature_dir: none` để không chạy
`aw feature`.

Parser chỉ nhận ô đúng chỗ (spec: trước `##` đầu tiên; DEC-xxx: trong `### DEC-NNN`), đúng một ô; ô
trong chú thích hay khối code không tính; sai dạng là lỗi, không đoán.

`plan` và `implement` **không có người**: chỉ thực thi điều đã duyệt; đặt người ở đó chỉ thêm
một chỗ duyệt văn xuôi không có quyết định thật.

### LLM checker: chỉ được chặn

Điều script không kiểm được (lệch DEC-xxx, quyết định ngầm) giao LLM checker, với ràng buộc: ghi phát
hiện ra **file**; script fail nếu còn `Chặn` chưa xử lý; LLM **không bao giờ** nói "đạt"; người là
trọng tài theo ngoại lệ. Cho LLM duyệt là quay lại "agent tự đánh giá là đạt"; cho nó chỉ chặn thì
sai sót chỉ tốn thời gian người.

### Chặn hay cảnh báo

| Loại checker | Ví dụ | Hành vi |
|---|---|---|
| **Chính xác** — hợp đồng output của chính phase | truy vết nguồn, phủ REQ, test xanh | **Chặn** |
| **Cross-check giữa phase**, hay báo nhầm | stale, test ↔ REQ, phạm vi diff | **Cảnh báo**; `review` chặn |

Chặn nhầm làm tắc flow và người học cách lách. Mọi cảnh báo dồn về `review` (cổng cuối). Tiêu chí
xếp checker mới: độ chính xác, chi phí nếu lọt, nơi sửa rẻ nhất.

### Mã định danh: một dạng cho mọi mã

Trước đây mã mỗi loại một kiểu: `YC`/`PH` là chữ Việt viết tắt, `D`/`T` một chữ, phần số khi 2 khi
3 chữ số. Người phải nhớ riêng từng loại, mã một chữ (`D`, `T`) lẫn với chữ thường trong câu và khó
grep. Giờ mọi mã trong job dir là `<TIỀN TỐ>-NNN` (`REQ`, `DEC`, `FND`, `TSK`, `RFR`):

- **Ba chữ tiếng Anh**, viết tắt đúng thuật ngữ — cùng luật với tên trường trong artifact (tiếng
  Anh, checker khớp đúng chữ). Ba chữ đủ để thêm loại mới mà không đụng loại cũ; một chữ thì sớm hết.
- **Đúng 3 chữ số**: mã cùng độ dài thì bảng thẳng hàng và sắp theo chữ cũng là sắp theo số.
- **Không đọc mã cũ.** Mỗi job ghim version engine trong `intake.md` và chạy hết bằng version đó,
  nên job cũ vẫn dùng `YC-`/`D-`… với engine cũ; job mới dùng mã mới. Đọc cả hai thì mọi parser
  phải mang hai regex mãi, và job trộn hai kiểu không ai bắt.
- **`BR-<MIỀN>-NNN` và `ADR-NNNN` giữ nguyên**: chúng sống trong git của `target repo`, dùng chung
  mọi job, đã có trong code (`covers: BR-…`) và theo quy ước ADR thông dụng.

### Mục lục và link tới mục

Artifact viết cho người đọc, và người đọc nhảy giữa chúng: plan trỏ tới DEC-xxx, spec trỏ tới điểm
mù, review trỏ tới REQ. Chữ trơn `open-questions.md § REQ-002` bắt người tự tìm; link chỉ tới file
cũng vậy. Nên luật là: artifact có heading `##`/`###` thì có `## Contents`, và tham chiếu sang
artifact khác là link có anchor tới đúng mục.

- **Máy sinh, không để agent gõ.** Anchor tính như GitHub / VS Code (chữ thường gồm cả chữ Việt,
  bỏ dấu câu, dấu cách thành `-`, trùng thì `-1`): `### REQ-001 — Đăng nhập` → `#req-001--đăng-nhập`.
  Agent gõ tay thì sai một dấu là link chết. `aw toc` sinh mục lục và mở rộng anchor rút gọn
  (`#req-001` → anchor đầy đủ) khi chỉ khớp một heading; agent chỉ cần viết mã.
- **Chặn, không cảnh báo.** Kiểm chính xác: mục lục khớp heading hay không, anchor có trong file đích
  hay không — không có báo nhầm. Checker phase chặn trên artifact đầu ra của chính nó; link sang
  artifact phase trước có thể gãy khi file đó đổi heading sau này, nên `review` chặn lại trên mọi
  artifact.
- **Chạy trước `aw based-on`.** `based_on` là hash cả file: mục lục của `spec.md` đổi sau khi `tdd.md`
  đã ghi `based_on` thì `tdd.md` thành stale. `aw toc` chỉ ghi file khi nội dung đổi, nên chạy lại
  khi heading không đổi là vô hại.
- **Chỉ artifact agent viết.** File máy ghi (`*-results.md`, `repro.md`, `perf.md`, `ship.md`) không có
  mục lục và không phải đích bắt buộc có anchor.

### Câu trích nguyên văn của REQ

Phase spec bảo agent trích câu nguồn trước khi diễn giải, nhưng không có chỗ ghi thì bước đó không để
lại dấu vết: người duyệt phải tự mở nguồn để so. Nên REQ có nguồn `[CONFLUENCE]` `[JIRA]` `[FILE]` có
`- Quote:` + các dòng `> …` — "nguồn nói gì" tách khỏi "agent hiểu thế nào" (`Description`).

- **Bắt buộc, không tuỳ chọn.** Tuỳ chọn thì agent bỏ, và người không phân biệt được "không có câu
  gốc" với "quên trích". `[INFERRED]`, `[OPEN-QUESTION]` không có câu gốc (open question đã có
  `Source says`).
- **`[FILE]`: máy kiểm câu có thật trong file** (`tools/lib/quote.sh`) — thu hẹp điểm yếu 3 cho nguồn
  máy đọc được, gồm lời người trong `intake.md` và câu trả lời trong `open-questions.md`. So chuỗi con,
  chỉ gộp khoảng trắng / xuống dòng và bỏ `>` đầu dòng; không chuẩn hoá thêm (markdown, dấu nháy):
  nới thêm là bắt đầu đoán "gần giống", còn chép đúng thì sửa mất vài giây. Mỗi dòng `>` một câu,
  so riêng — một REQ thường gộp vài câu ở vài chỗ trong nguồn. Confluence/Jira script không gọi được
  MCP: câu trích chỉ cho người đọc.
- **Chặn ở spec, cảnh báo khi phase sau chạy lại spec** (`check-spec.sh --entry`, design và plan
  không có design gọi). Lúc viết spec, lệch nguồn là lỗi của chính phase đó — chính xác, chặn. Về sau
  lệch thường do file nguồn đổi, không phải lỗi của phase đang chạy; chặn ở đó làm tắc việc. Thiếu
  `Quote` vẫn chặn ở mọi phase — đó là lỗi của spec.
- **Không kiểm theo phiên bản trong `## Sources`.** Bảng Sources không gắn với từng REQ, nên không
  biết câu trích nào ứng với sha nào; so với file hiện tại, lệch thì cảnh báo như trên.
- **Không đặt độ dài tối thiểu.** Trích qua loa ("khách") là gian lận có chủ ý — ngoài mục tiêu
  (chặn quên, không chặn cố tình); người duyệt thấy ngay trong spec.

### Nguồn của REQ: phần máy kiểm thêm

Bảng nhãn ở `workflow/rules/source-tracing.md` ghi mỗi nhãn "phải có gì"; máy kiểm phần chính xác,
cảnh báo phần hay báo nhầm.

- **Chặn `[JIRA]` không có mã issue** — cùng `jira_key_regex` với `aw check intake`; thiếu mã thì
  không ai mở lại được issue để so.
- **Chặn `[INFERRED]` không có chữ nào sau nhãn** (hay còn `<…>`). Chỉ kiểm có/không: máy không đánh
  giá được lý do hay hay dở — đó là việc của người duyệt.
- **Cảnh báo nguồn không có trong `## Input` của `intake.md`** (mã Jira, URL Confluence bỏ anchor,
  đường dẫn `[FILE]`; trừ `intake.md`/`open-questions.md` của việc). Spec hay trích thêm link phụ,
  file trong repo mà intake không liệt kê — chặn sẽ báo nhầm nhiều. Cảnh báo để người duyệt thấy
  agent đi lấy nguồn ngoài phạm vi được giao.
- **`high_risk_keywords`: cảnh báo, không chặn.** "thanh toán" xuất hiện trong spec không có nghĩa
  việc đụng tiền; `Risk` là quyết định của người duyệt. Không khai từ khoá thì không bật.

### Artifact stale

`based_on` là hash **cả file** đầu vào, dạng phẳng `- spec.md@<hash>` (đọc được bằng tập con
YAML). Cả file thay vì từng mục: đơn giản, không bỏ sót — nhưng báo cả sửa chính tả, nên chỉ cảnh
báo. Chuỗi: `spec` ← `intake`; `tdd` ← `spec` + `open-questions`; `plan` ← `spec` + `tdd`.

## Quyết định là thứ người duyệt

Người lướt văn xuôi dài vì không thấy đâu là lựa chọn thật. Nên `design` tách lựa chọn thành
**DEC-xxx**; mục chi tiết ghi `Based on: DEC-xxx`; LLM checker chặn chỗ lệch và quyết định ngầm. DEC được
phép rỗng. `tdd.md` là output duy nhất (tách file quyết định thì hai file lệch nhau).

- **Mode 2 chống neo**: agent đưa phương án trước thì người neo vào nó. `Risk: high` → người phác
  DEC-xxx trước, agent chỉ phản biện; chưa có bản phác → chặn. Agent được **hỏi dẫn** người phác (nêu
  điểm cần quyết + dữ kiện từ code, hỏi câu mở) nhưng không nêu phương án: dừng trơn thì người
  phải tự nghĩ ra các điểm cần quyết từ trang giấy trắng, hay bỏ sót; hỏi dẫn giữ được chống neo vì
  câu hỏi và dữ kiện không chứa lựa chọn.
- **Mở lại**: đúng một DEC, sửa tại chỗ (git giữ lịch sử), bỏ tick + `Reopen reason:`;
  `aw task reopen <dir> DEC-xxx` đưa task `Based on` DEC đó về `[ ]`, chỉ chúng.
- **`plan` tách khỏi `tdd.md`**: plan là ranh giới do **phiên khác** đặt cho `implement`, và tick
  task không được sửa vào thiết kế đã duyệt.
- **Bỏ design cho việc nhỏ (`Design: skip`)**: bugfix/refactor sửa vài dòng không có lựa chọn
  kỹ thuật nào — `tdd.md` thành 8 mục "Not applicable" cộng một phiên và một lượt LLM checker, không
  đổi lại được gì. Phần bảo đảm của bugfix nằm ở test tái hiện đỏ (`aw check repro`) và review, không
  ở design. **Người** quyết, không phải máy: lúc viết spec chưa có diff để đo "nhỏ", nên agent đề xuất
  `skip` trong `spec.md` và người duyệt cùng spec (đổi sau khi duyệt → duyệt lại). Máy chỉ chặn chỗ
  chắc chắn sai: `skip` ngoài bugfix/refactor (feature thêm hành vi, perf cần thiết kế đo), hoặc khi
  `Risk: high` (Mode 2 là để người phác DEC-xxx trước — bỏ design là bỏ luôn nó). Việc bỏ design đi
  đúng đường của chore (`kc_bo_design`): plan nhận cổng duyệt spec và cổng open question `blocking`.

## Giả định chưa xác nhận

`[OPEN-QUESTION]` mang **một trong ba mức `Blocking`** (thêm mức thì người phải phân biệt ranh giới không
ai đo được). Mỗi mức đặt cổng ở **phase rẻ nhất để sửa** nếu giả định sai: lật hướng thiết kế
(`blocking`) phải biết trước design; sai một phần code (`review-blocking`) biết trước merge là đủ;
còn lại (`non-blocking`) giao trên giả định, review ghi `pending`.

`/aw-clarify` dẫn người qua hàng đợi do **máy** xếp (`aw pending`: mức `Blocking` → `must` trước → nhiều
task đứng trên giả định hơn), hỏi từng mục với phương án agent đã phân tích. Câu trả lời trong hội
thoại **là** human gate của open question; dấu vết ở `Answer:` (ai, ngày, nguyên văn). Spec đã tick mà bị
sửa theo câu trả lời thì bỏ tick, người tick lại — máy không phân biệt "sửa người vừa xác nhận" với
"sửa người chưa thấy".

**Người đổi REQ đã có nguồn** đi cùng đường open question (`/aw-clarify REQ-NNN`): ghi thành mục `answered`
trong `open-questions.md` (cách hiểu cũ ở `Assumption`, lời người ở `Answer`), REQ đổi nhãn sang
`[FILE] open-questions.md § REQ-NNN`. Không thêm source label thứ sáu; checker spec chặn nhãn
trỏ vào `open-questions.md § REQ-NNN` mà mục đó không có — chính xác nên chặn. Sửa thẳng `spec.md` thì nhãn cũ
(`[CONFLUENCE]`…) nói dối về nguồn và không máy nào bắt. Thêm/bỏ REQ là đổi phạm vi → `[HUMAN]` trong
`intake.md`, chạy lại spec. Lan xuống dưới: `based_on` chỉ biết *file* đã đổi, nên `aw task reopen`
đưa đúng task `Covers`/`On assumption` REQ đó (hay `Based on` DEC đó) về `[ ]` — máy làm, khỏi để agent
grep tay và sót.

**Gộp ở chỗ người nhìn, không gộp chỗ lưu**: open question và phát hiện LLM ở file riêng (mỗi file một
bên ghi, LLM checker ghi đè cả file, `based_on` băm cả file — chung file thì checker ghi phát hiện
làm `tdd.md` stale). LLM checker mới chỉ cần ghi `<id>-findings.md` đúng mẫu là `aw pending` gom.

## Bằng chứng do máy ghi

- **Checker tự chạy test** và ghi `test-results.md`: để agent dán kết quả thì chỉ kiểm được
  *cái agent nói*.
- **Trạng thái task do máy giữ**: chỉ `aw task done` lên `[x]` — chạy lệnh của `Verify`, ghi
  `task-results.md`, xanh mới đổi. Chặn `[x]` thiếu bằng chứng hoặc bằng chứng của lệnh `Verify`
  cũ. **WIP = 1** (`start` từ chối khi đã có `[~]`). Thủ công thì `--manual "<bằng chứng>"`.
  **Đỏ liên tiếp có trần** (`MAX_RED_RUNS`) — điều kiện dừng của vòng lặp, không thì thử tới
  hết token. Vòng lặp nằm ở lệnh `aw`, nên agent nào chạy shell cũng lặp được.
- **`aw ready`** đầu phiên: test xanh trên code chưa sửa. Base đỏ mà vẫn làm thì không phân biệt
  lỗi mình với lỗi có sẵn, và agent hay "sửa" test có sẵn. Nó cũng in bước tiếp.
- **Quét bảo mật chạy ở `implement`** bằng đúng lệnh CI (`SECURITY_CMDS`, nhóm `secret |
  sast | sca | other`): lỗi quét ra là việc sửa code; review bị cấm sửa code, và quét chậm. Review
  chỉ kiểm kết quả xanh và **còn mới**. Thiếu nhóm chỉ cảnh báo; riêng chore đụng dependency phải
  có `sca` xanh.
- **Độ mới theo `Tree`**, không theo HEAD: tree SHA của nội dung worktree (đã/chưa commit, chưa
  track, trừ thư mục việc `docs/sdlc/`, `.agent-workflow/`), tính bằng index tạm. Theo HEAD thì sửa chưa commit lọt, còn commit
  đúng code đã review lại bị coi stale. `review.md` ghi `Reviewed tree:` để kết luận gắn với
  đúng code đã rà.

## Review

- **Phiên chính chỉ bàn giao**: lệnh `/aw-review` không nạp mô tả phase — subagent clean context
  (`independent-reviewer`) mang mô tả đầy đủ và làm việc. Nạp vào phiên chính chỉ tốn ngữ cảnh.
- **Lens 4 — bảng bảy hạng mục cố định**: máy quét bắt *mẫu*, người rà bắt *ý đồ* (thiếu kiểm
  quyền, log lộ PII, IDOR). Danh sách mở thì "không thấy gì" và "không xét" trông như nhau. Máy
  kiểm hình dạng (đủ dòng, verdict hợp lệ, có vị trí/lý do), không biết `pass` có đúng không.
  Parser Lens 1 chỉ đọc dòng có **ô đầu** là mã REQ.
- **Lens 3 và Conclusion**: có finding **hoặc** `- None`; finding đủ trường để người khác kiểm lại;
  số Blocker ở Conclusion khớp số mục (`aw check ship` đếm theo đó).
- **Code nhạy cảm theo đường dẫn, không theo job type**: rủi ro nằm ở chỗ code bị đụng
  (`sensitive_code`). Diff đụng vào → một **người** ghi `Security reviewer:`. Máy chỉ kiểm dòng có
  và không phải tên agent; bỏ trống khoá = tắt luật.
- **Category tự do (kebab-case)**: danh sách cố định hoặc quá thô hoặc dài tới mức chọn bừa;
  `aw journal` liệt kê tên đã có để dùng lại.

## Cross-check, trạng thái sạch, nhật ký

- Test ↔ REQ (`covers:`) và phạm vi diff ("Expected files" + "Unplanned") chỉ cảnh báo. Phạm vi so
  từ `git merge-base <base> HEAD` **tới cây làm việc** + file chưa track, bỏ `docs/sdlc/` và `.agent-workflow/`.
- **Trạng thái sạch**: task `[ ]` sót, dấu xung đột merge → chặn. Dòng test *thêm mới* khớp
  `skipped_test_regex` → cảnh báo (chỉ dòng mới, để test tắt từ trước không đổ lên việc này).
- **harness journal** (`$AW_CONFIG/journal/`): `checks.tsv` (engine ghi mỗi `aw check`),
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

### Skill, subagent gọi theo phase (`uses_<phase>`)

`rules_*` chỉ cho agent **đọc**. Đọc `SKILL.md` thì agent theo được chữ, nhưng mất phần khung chạy
skill xử lý: thay tham số, dòng chèn lệnh shell, `allowed-tools`, `hooks`. POC 2026-10 (Claude Code
2.1.294, repo tạm, chạy `-p` không cấp quyền Bash): gọi qua Skill tool — kể cả từ trong lệnh
`/aw-*` — cả bốn đều có hiệu lực, 4/4 lần; đọc file thì không cái nào. `cursor-agent` không có tool
gọi skill, tự đọc file: không cái nào. Nên có khoá thứ hai, `uses_<phase>`, cho thứ phải **gọi**.

- **Gọi tường minh theo lệnh phase**, không trông vào skill tự kích hoạt — vẫn đúng lý do ở trên
  (agent khác không thấy skill; tự kích hoạt không chắc xảy ra). Cách gọi là chữ riêng của từng
  agent (hook `ad_goi_uses`): Claude Code gọi Skill tool / `subagent_type`; Cursor đọc file khi
  không có tool. Hook Claude không được viết nguyên văn biến tham số hay dấu chấm than liền
  backtick: Claude Code xử lý chúng ngay trong file lệnh.
- **Chỉ thứ nằm trong repo**: tên `skill:<tên>` / `agent:<tên>` phân giải ra file đã commit
  (`.claude/` rồi `.cursor/`). Skill của plugin, skill cài cho cả máy: máy khác, CI, người review
  không có, máy cũng không kiểm được — từ chối, bảo chép vào repo.
- **Máy chặn phần chính xác**: dạng mục, file có / đã commit, skill có `disable-model-invocation:
  true` (Skill tool từ chối hẳn — POC thấy — phase sẽ kẹt). Quyền `Skill(<tên>)` thì không kiểm:
  có thể nằm ở cấu hình của máy; thiếu thì agent hỏi người, lời dặn bảo không quay về đọc file.
- **Máy không biết agent đã gọi thật chưa.** Lưới cuối là review: `aw rules review` in thêm file
  định nghĩa của mọi `uses_*`, `review.md` kết luận từng file như quy tắc.
- **Đánh đổi**: skill cho model gọi thì model cũng tự gọi được ngoài phase — ngược "chỉ người kích
  hoạt" (mục dưới). Đó là skill của team, team chọn; chỉ chặn mềm bằng `description`.

## Tiết kiệm ngữ cảnh của agent

Mỗi lần gọi `/aw-*`, agent nạp file lệnh + những gì lệnh bảo đọc. Vì vậy:

- File phase chỉ giữ **chỉ thị** (mục tiêu, đầu vào, việc phải làm, cấm, điều kiện ra); lý do nằm
  ở file này.
- **Agent đọc tiếng Anh, người đọc tiếng Việt.** Cùng một ý, tiếng Việt tốn nhiều token hơn đáng
  kể, nên thân phase, rules, LLM checker và lời dặn adapter viết tiếng Anh. Mọi thứ người thấy giữ
  tiếng Việt: `name`/`summary`, mẫu artifact, output và nhãn `Kết quả` của `aw`, câu hỏi/lựa chọn
  hiện cho người; agent được dặn nói và viết artifact bằng tiếng Việt. Nhãn của `aw` được nhắc
  nguyên văn trong chữ tiếng Anh như hằng số.
- **Thuật ngữ giữ tiếng Anh gốc, cả khi câu là tiếng Việt.** Từ dịch ("điểm mù", "cổng người",
  "lỗi thời") không có trong tên field, file hay output `aw`, nên người phải tự dịch ngược mới tìm
  được chỗ agent nói tới, và mỗi agent lại dịch một kiểu. Danh sách chuẩn ở `rules/terms.md` (agent
  đọc qua `general.md` §5). Cột `Not` của nó ghi các từ dịch đã gặp. Lời trong chat thì không kiểm
  được. Trong artifact thì máy kiểm được, nhưng hay báo nhầm (một câu tiếng Việt bình thường có thể
  trùng chữ) nên theo luật cross-check: implement cảnh báo, review chặn (`kc_tu_dich`). Không kiểm
  `intake.md`, `refactor-requests.md`, dòng trích `>` (nguyên văn lời người, agent không được sửa)
  và `*-results.md` (máy ghi). Chỉ ghi vào `Not` cụm đặc thù: từ chung như "việc", "yêu cầu",
  "phát hiện" báo nhầm quá nhiều. `docs/thuat-ngu.md` giải thích cho người; test giữ hai file cùng
  một bộ thuật ngữ.
- Mỗi luật một chỗ: bảng mức `Blocking` ở `rules/source-tracing.md`; hợp đồng vào/ra do adapter dựng từ
  frontmatter, thân phase không lặp lại.
- `rules/source-tracing.md` chỉ nạp cho lệnh khai `trace_rule: true`; `conventions.md` để "tra khi
  cần", không bắt đọc hết.
- Danh sách điều máy kiểm nằm trong checker và in ra khi vi phạm; file phase chỉ tóm tắt.
- **Chỉ người kích hoạt quy trình.** Agent tự đọc `description` rồi tự chạy lệnh/skill/subagent khi
  thấy việc "na ná" thì vừa tốn token vừa kéo phiên đi lan man. Lệnh `/aw-*` và skill tổng
  `agent-workflow` mang `disable-model-invocation: true`: chỉ chạy khi người gõ, description của skill
  không chiếm ngữ cảnh. Subagent không có cờ tương đương (cấm bằng permission thì chính `/aw-review`
  cũng không gọi được), nên chỉ chặn mềm: description dặn chỉ gọi khi lệnh `/aw-*` bảo. Hook
  `PreToolUse` chặn cứng được nhưng phải ghi `settings.json` của target repo và dễ chặn nhầm lượt
  sau của cùng lệnh — không làm.

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
exit_machine: [aw check spec]          # phải là "aw check <tên>" có trong tools/lib/commands.sh
exit_human: [...]
needs_clean_context: true   # chạy được từ fresh session
requires_fresh_agent: true  # chạy qua subagent clean context; lệnh chính chỉ bàn giao
llm_checker: workflow/checkers/design.md
arguments: input            # tham số là input, không phải tên feature (00-intake)
approval_gate: true         # mở đầu bằng cổng duyệt (02-design, 03-plan)
choice_ui: true             # hỏi người bằng câu hỏi lựa chọn (00-intake: lượt xác nhận)
runs_on_main_checkout: true # có việc ở main checkout (06-ship)
trace_rule: true            # lệnh bảo đọc rules/source-tracing.md
---
```

Thân có mục cố định: **Mục tiêu**, **Đầu vào**, **Việc phải làm**, **Đầu ra**, **Cấm**, **Điều
kiện ra**. Mục **Cấm** chặn thất bại đặc trưng nhất: `01-spec` chọn giải pháp kỹ thuật,
`04-implement` sửa "tiện tay" — cả hai xoá mất điểm dừng để người xem lại.

Utility command (`commands:` trong manifest — `import`, `clarify`, `bootstrap`): `id`, `name`, `summary`,
tuỳ chọn `argument_hint`, `arguments: mixed`, `choice_ui: true`, `trace_rule: true`,
`runs_on_main_checkout: true`. LLM checker
(`workflow/checkers/*.md`): `id`, `summary`, `inputs`, `output`, `repo_rules`; adapter biến thành
subagent `<id>-checker`.

## Hiện thực các cơ chế

| Cơ chế | Nằm ở | Ghi chú |
|---|---|---|
| Xác định feature | `tools/feature.sh` | Gốc worktree từ `AW_REPO` |
| Đọc `conventions.md` | `conv_get` (`tools/lib/md.sh`) | Chỉ đọc khối ` ```conventions ` |
| Quy ước hiệu lực | `qu_hieu_luc` (`tools/lib/md.sh`); `mt_dat`, `kc_conventions` gọi | Repo (điểm rẽ khỏi base) + khoá máy của bản clone |
| Kiểm `conventions.md` | `tools/check-conventions.sh` | Khoá biết = khoá trong mẫu + `rules_<phase>`; `aw ready` gọi |
| Hash `based_on` | `tools/based-on.sh`, `file_hash` | `cksum` sau khi bỏ `\r` |
| Cross-check | `tools/lib/cross-check.sh` | Một hàm; `implement` gọi là cảnh báo, `review` gọi là lỗi |
| `Blocking` của open question | `kc_diem_mu_mo` | design (không có design: plan) chặn `blocking`; implement cảnh báo, review chặn cả `review-blocking` |
| Từ dịch trong artifact | `kc_tu_dich` | Đọc cột `Not` của `workflow/rules/terms.md`; implement cảnh báo, review chặn |
| Hàng đợi việc chờ người | `tools/pending.sh` | Chỉ đọc |
| Entry check | Đầu mỗi `check-*.sh` | `review → plan → design → spec` |
| Ghim version của việc | `kc_engine_dong`; `bin/aw-engine check`; `bin/aw` | |
| Tên checker, phase có quy tắc | `tools/lib/commands.sh` | Một bảng cho `aw check` và cho adapter |
| Một awk đọc nhiều file | mọi `check-*.sh` | Dùng `FILENAME == ARGV[i]`, **không** đếm `FNR==1` (file 0 byte làm lệch) |

## Tập con YAML

`tools/lib/md.sh` chỉ đọc `khoa: gia tri`, `khoa:` + `  - muc`, `khoa: []`. Không có map lồng,
khối nhiều dòng, flow không rỗng, chú thích cuối dòng, anchor. Đánh đổi có chủ ý: trình đọc đầy đủ
kéo theo Node/Python (máy dựng repo này không có). Chỉ áp cho cấu hình của engine.

## Cách thêm một phase

1. `workflow/phases/NN-<id>.md` với frontmatter đầy đủ; thêm vào `phases:` của `workflow.yaml`.
2. Có `exit_machine` → script trong `tools/`, thêm tên vào `tools/lib/commands.sh`.
3. Artifact mới → mẫu trong `workflow/templates/`.
4. Ca kiểm trong phần cùng chủ đề ở `tools/tests/` (chạy bằng `tools/run-tests.sh`).
5. Thử: `AW_ENGINE_DIR=<repo này> aw adapter build claude-code` (VERSION khớp target repo).

Không phase nào khác phải sửa — không phase nào biết về phase sau nó (vì vậy `06-ship` thêm được sau).

**Test chia phần chạy song song.** Bộ test hồi quy gọi checker thật hàng nghìn lần nên tốn CPU; chạy
tuần tự một file thì ~8,5 phút trên 4 lõi chỉ dùng một. Ca kiểm chia thành các phần trong `tools/tests/`,
mỗi phần tự dựng fixture và thư mục tạm, nên `tools/run-tests.sh` chạy song song (nhanh ~3 lần trên 4 lõi).
Ranh giới phần đặt ở chỗ trạng thái fixture trùng với fixture dựng mới (hoặc trạng thái như sau nhóm
check-security: `fixture_sau_bao_mat`), để không ca nào đổi điều kiện đầu vào. Phần dừng giữa
chừng (không in `Tổng:`) tính là hỏng — không ca nào bị bỏ qua câm. Không bớt ca để nhanh hơn:
release vẫn chạy lại test trên đúng commit được đóng gói.

## Cách thêm một adapter

Xem `adapters/README.md`. Việc sinh ở `adapters/lib/common.sh`; adapter chỉ khai hook (chữ riêng
của agent). Test đối chiếu đòi output mọi adapter giống hệt nhau khi hook thay bằng tên. Khả năng
nào không dịch được sang agent đích (subagent, hook, MCP) thì **ghi rõ trong output** người phải
tự làm — bỏ qua âm thầm khiến quy trình *nhìn như* đủ mà đã mất ràng buộc.

File sinh ra còn phải đúng **định dạng** agent đọc (`adapters/lib/format.sh`), và phép kiểm này
**chặn** chứ không cảnh báo: nó chính xác (YAML, khoá, tên — không phán đoán), còn lỗi thì im lặng ở
phía agent — frontmatter hỏng hay `name` lệch tên file làm lệnh biến khỏi menu, subagent không gọi
được, không ai được báo. Test đối chiếu không bắt được loại lỗi này vì nó thay hook bằng tên; chuẩn
riêng của từng agent (`AD_LENH_FM`, `AD_*_KHOA`) nằm trong `build.sh` cạnh hook, luật chung một chỗ.

## Những chỗ thiết kế này yếu

1. **`06-ship` chỉ lo MR**, không lo deploy/tag/release note. Không có `gh`/`glab` thì trạng thái MR
   chỉ suy từ git, không nhận ra squash có sửa xung đột.
2. **"clean context" không cưỡng chế được ở agent không có subagent** — lùi về lời dặn người.
3. **Checker kiểm hình thức, không kiểm nội dung.** Mọi REQ có nhãn ≠ REQ đúng với BRD. Đừng nhầm "qua
   hết checker" với "làm đúng"; LLM checker chỉ thu hẹp khoảng trống này. Câu trích `[FILE]` máy kiểm
   được có thật trong nguồn — nhưng REQ diễn giải đúng câu trích hay không vẫn là việc của người.
4. **Mode 2 dựa vào nhãn `Risk` đúng** — người cho qua `normal` sai thì neo quay lại.
5. **Hash cả file báo cả thay đổi vô hại** — nên chỉ cảnh báo, và người có thể quen tay bỏ qua.
6. **Tập con YAML dễ vỡ** — sai cú pháp trả về rỗng, lỗi lộ muộn.
7. **Máy không biết ai tick.** Hook chỉ có khi repo cài và agent có hook; không có hook thì agent tự
   tick vẫn lọt (artifact ngoài git, không có `git blame`). Hook không bắt dấu giả agent tự tính, và
   bỏ nhầm tick nếu người tick đúng lúc lệnh agent đang chạy. Nội dung đổi **trước** lần ghi dấu
   đầu tiên cũng lọt. `aw approvals tick` ghi dấu hợp lệ nên hook không phân biệt được với người
   duyệt: chặn nó là việc của luật hỏi quyền — không cài, chạy ở chế độ bỏ qua quyền, hay agent gọi
   thẳng script engine thì chỉ còn nhật ký.
8. **`review` không chạy lại test hay quét** — biết kết quả cũ, không biết lệnh có đủ. Lệnh lệch
   pipeline thì local xanh mà CI chặn. Lệnh ghi file vào repo (không `.gitignore`) làm `Tree` đổi.
9. **Glob dùng `case` của shell**: `*` khớp cả `/`, không có `**` — `src/*` rộng hơn người đọc tưởng.
10. **Artifact không đi theo PR** — reviewer chỉ thấy code. DEC-xxx người chọn nâng thì đi theo PR dưới
    dạng ADR; phần còn lại của `tdd.md` thì không.
11. **Ghim sha256 là tin lần đầu (TOFU)**; repo cấu hình chung của team thu hẹp, không xoá rủi ro.
12. **Tuân thủ quy tắc repo chỉ do người phán** — quy tắc viết được thành lệnh nên vào `TEST_CMD`.
13. **File máy ghi giả được** (`task-results.md`, `test-results.md`): chặn việc *quên*, không chặn
    gian lận có chủ ý; review clean context là lớp sau.
14. **harness journal chỉ ở từng máy**; `Category` tự do có thể đếm hụt.
15. **Việc không thấy quy ước mới của chính nó** — đúng ý đồ, nhưng việc sửa `conventions.md` để
    hợp lệ hoá thay đổi của mình (vd thêm `production_code`) sẽ bị chấm theo luật cũ tới khi merge.
16. **Quy ước chưa commit ở main checkout** có hiệu lực ngay cho mọi việc rẽ từ base chưa có file;
    trước khi pull bản đã merge, người phải xoá bản chưa track (git từ chối ghi đè).
17. **Bản hiệu lực làm mới khi script đọc quy ước**: agent mở `.engine/conventions.md` trước mọi
    lệnh `aw` của phiên thì có thể thấy bản cũ (mọi phase đều chạy `aw feature` trước).
18. **Số ADR cấp lúc nâng, theo thư mục ở worktree**: hai việc song song cùng lấy `0004`; PR merge sau
    có hai file trùng số (`aw adr check` chặn ở việc kế tiếp) và xung đột ở bảng chỉ mục — người
    đổi số, chạy lại `aw adr promote`.
19. **"Đi ngược ADR" chỉ LLM checker thấy** — máy chỉ kiểm `Supersedes` khi DEC tự khai.
    Tương tự, nguồn mới mâu thuẫn với luật `BR-` active chỉ agent spec và người phát hiện.
20. **PRD đổi sau khi luật đã nâng**: máy không theo dõi Confluence/Jira; phiên bản ghi trong `Source`
    chỉ cho người so tay. Luật cũ vẫn `active` tới khi một việc thay nó.
21. **Phạm vi thô**: glob `case` (`*` khớp cả `/`), tài liệu module phủ cả thư mục — sửa một file test
    trong `src/` cũng đòi verdict cho `src/ARCHITECTURE.md`. Verdict `pass` rẻ, nhưng người có thể quen
    tay ghi `pass` không đọc.
