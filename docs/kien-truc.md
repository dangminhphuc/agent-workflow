# Kiến trúc

Tài liệu này giải thích *vì sao* thiết kế như vậy, và cách mở rộng.

## Vấn đề cần giải

Muốn một quy trình phát triển dựa trên AI agent mà **không khoá vào một agent cụ
thể**. Cách làm hiển nhiên — dựng một lớp trừu tượng hoá phía trên API của từng
agent — hỏng ngay từ đầu vì các agent khác nhau ở những chỗ không trừu tượng hoá
được: agent này có subagent, agent kia không; agent này có hook, agent kia không;
agent này có MCP, agent kia không. Lớp trừu tượng hoá sẽ rút về mẫu số chung nhỏ
nhất, và mẫu số chung nhỏ nhất thì quá yếu để làm được việc gì.

## Giải pháp: bàn giao bằng file

Quy trình được chia thành phase, và **phase chỉ nối nhau qua file**:

```
tài liệu / lời người dùng ─▶ 00-intake ──▶ intake.md (loại việc + input)
                                            │
                                            ▼
                             01-spec ──▶ spec.md ──▶ 02-design ──▶ tdd.md   (chore: bỏ design)
                                        │                        │
                                        ▼                        ▼
                                     03-plan ◀───────────────────┘
                                        │
                                        ▼
                                     plan.md ──▶ 04-implement ──▶ diff + ket-qua-kiem-thu.md
                                                                        │
             spec.md + tdd.md + plan.md + diff ─────────────────────────┤
                                                                        ▼
                                                                    05-review ──▶ review.md
                                                                        │
                                                                        ▼
                                                                   [06-ship]
```

File là thứ mọi agent đều đọc và ghi được. Không cần API chung, không cần trừu
tượng hoá khả năng. Khi `03-plan` chỉ cần `spec.md` + `tdd.md` để làm việc, nó
chạy được bằng Claude Code, bằng Cursor, hay bằng một người.

Tính chất kiểm chứng được rút ra từ đó: **mỗi phase phải chạy được từ phiên
trắng.** Đây không phải khuyến nghị cho gọn — nó là phép thử xem thiết kế có
đúng không. Nếu một phase cần nhớ điều phase trước nói *trong hội thoại*, thì
quy trình chỉ chạy khi cả hai phase nằm trong cùng phiên, cùng agent, chưa bị nén
ngữ cảnh. Ràng buộc đó phá cả tính portable lẫn tính lặp lại.

Adapter vì thế chỉ làm một việc nhỏ: dịch định nghĩa phase sang dạng native cho
tiện gọi. Nếu ngày mai mọi adapter biến mất, quy trình vẫn chạy được — chỉ là
phải copy-paste nội dung phase vào chat bằng tay.

### Vào quy trình ở phase nào cũng được

Đây là **mục đích gốc** của tính trung lập, không chỉ là hệ quả phụ. Mỗi phase là
một hộp input → output; người dùng có thể tạo artifact bằng tool bất kỳ (AI khác,
Confluence, viết tay…) rồi đưa vào đúng phase cần.

Để việc này không thành đường tắt vòng qua cổng chặn:

- **Entry check của phase N = checker của phase N-1 chạy lại trên input.** Input
  là cả bộ file được tham chiếu, không chỉ file liền trước.
- **Artifact từ ngoài vẫn phải qua gate người của phase lẽ ra sinh ra nó.** Một
  `tdd.md` viết tay vẫn cần người duyệt từng D-xx như khi agent viết.
- **Input không đúng mẫu đi qua bước import có kiểm soát** — lệnh riêng, không
  phải phase. Nó chỉ sắp xếp lại theo mẫu, **không thêm nội dung**; gắn nhãn
  nguồn trỏ về tài liệu gốc; chỗ không rõ ghi `[OPEN-QUESTION]`. Kết quả qua checker và
  người xác nhận bản chuyển đổi.

Import không được thêm nội dung vì nếu được, agent sẽ lặng lẽ lấp chỗ trống bằng
suy đoán, và suy đoán đó mang nhãn nguồn như thể có trong tài liệu gốc.

### `00-intake`: một gốc cho mọi việc

Mọi việc bắt đầu bằng `intake.md`: **loại việc**, **input**, **một câu mục
tiêu**. Trước đây `ideation` chỉ chạy khi không có BRD; giờ nó bắt buộc, vì hai lẽ:

- **Loại việc đổi luật.** Bugfix cần test tái hiện, refactor cấm hành vi mới,
  perf cần số đo, chore không được đụng production. Một bộ luật chung cho tất cả
  là sai; loại việc phải là dữ liệu máy đọc được.
- **Mọi YC có đúng một gốc.** `spec` chỉ đọc những input được liệt kê.

Điều giữ cho `00` không thành một lớp diễn giải chen giữa BRD và spec: nó chỉ
**trỏ tới** tài liệu, và input chỉ nhận tài liệu có định danh hoặc lời người dùng
**chép nguyên văn** (`[HUMAN]`). `[INFERRED]` bị cấm ở input — nếu không, điều
agent tự suy ra sẽ sang spec với nhãn `[FILE] intake.md` như có nguồn thật.

**Nhãn input do máy gán** (`aw input`), không do agent đoán:
checker chỉ kiểm được cú pháp nhãn, nên agent gắn `[JIRA]` cho một URL GitHub
vẫn lọt tới `spec`. Luật chọn quyết định trên **cả chuỗi**, không trên từng từ:
một từ không nhận ra là cả tham số thành lời người dùng nguyên văn. Tách từng từ
sẽ biến một câu thành vài input rác và làm mất câu gốc — đúng thứ `[HUMAN]`
sinh ra để giữ. Chạy lại `/aw-intake` chỉ **gộp thêm** (không xoá, không đổi loại
việc), và `spec.md` ghi `based_on: intake.md` để input mới làm spec lỗi thời.

**Nguồn sự thật của loại việc** là `intake.md` (người xác nhận). Tiền tố branch
chỉ để gợi ý và đối chiếu; lệch thì cảnh báo, `review` chặn, không có ngoại lệ
"ghi lý do chấp nhận lệch" — vì ngoại lệ dễ ghi hơn sửa, và tiền tố sẽ mất nghĩa.
`aw rename` đổi tên branch, dời thư mục artifact và dời worktree trong một lệnh.

Phân loại theo **thay đổi gì về hành vi**, không theo "xây cái gì": một loại chỉ
đáng tồn tại khi nó đổi luật. Vì vậy không có `utils`, `hotfix`, `security`;
`spike` nằm ngoài quy trình (output là kết luận, không phải code để merge).

Cùng một mẫu cho mọi bằng chứng theo loại: **máy tự chạy và tự ghi** (không để
agent chép kết quả), **máy chặn phần chính xác**, **người phán phần mơ hồ**:

| Loại | Máy chặn (chính xác) | Người phán (mơ hồ) | Vì sao không để máy phán |
|---|---|---|---|
| `bugfix` | Có `tai-hien.md` ghi lúc diff chỉ đụng file test, `Kết quả: ĐỎ` | Đỏ **đúng vì bug** | Test mới trên code cũ có thể đỏ vì lỗi biên dịch |
| `refactor` | Xoá test cũ; sửa test cũ không khai; YC giữ nguyên không có test trên nhánh gốc | Diff test cũ chỉ đổi import | Heuristic "chỉ đổi import" phụ thuộc ngôn ngữ, hay báo nhầm |
| `perf` | Thiếu số đo trước hoặc sau (`do-hieu-nang.md`) | Đạt mục tiêu chưa | Số đo dao động; chặn theo ngưỡng sẽ chặn nhầm |
| `chore` | Đụng `mau_code_production`; đụng dependency mà không khai; khai `major` | Mức phiên bản khai đúng | Cú pháp phiên bản mỗi hệ sinh thái mỗi khác |

Không dựng lại code cũ trong worktree để chạy test tái hiện: trông chặt hơn nhưng
cho kết luận sai mà tự tin (đỏ vì thiếu hàm vẫn tính là "tái hiện được").

### Artifact theo feature

Artifact nằm trong `.agent-workflow/<tên-branch>/`, dùng tên branch **đầy đủ**
(`feat_tao-todo`, `refactor_tao-todo`) để hai loại việc cùng tên không đè nhau.
Quy ước tên branch nằm trong `conventions.md` của repo đích vì nó tuỳ hoàn cảnh
từng team; nó nằm trong cấu hình của bản clone (`.git/agent-workflow/`), `aw init`
chỉ tạo mẫu và không ghi đè.

Thứ tự xác định feature: suy từ branch theo `conventions.md` → không khớp thì lấy
tham số lệnh → không có thì dừng hỏi. Agent luôn in `Đang làm với: …` — ghi nhầm
artifact sang feature khác là lỗi im lặng, khó phát hiện về sau.

### Worktree bắt buộc, base do người chọn

Mỗi việc làm trong một worktree riêng; checkout chính chỉ đứng ở `nhanh_goc` và
chỉ chạy `/aw-intake`. Mọi lệnh khác chạy ở checkout chính bị `aw feature`
chặn (`ĐANG Ở CHECKOUT CHÍNH`) — chốt đặt ở script mọi phase đều gọi, không phải trong từng phase.
Hệ quả mong muốn: "mỗi phase chạy được từ phiên trắng" không còn là khuyến nghị
mà là cấu trúc — tạo worktree xong thì người **phải** mở phiên mới ở đó.

Worktree đặt **ngoài** repo (`../{repo}.wt/{ten}`): đặt bên trong thì jest, tsc,
grep quét trùng code, và agent ở worktree này đọc nhầm artifact của worktree khác
— đúng lỗi "ghi nhầm feature" mà quy trình cố chặn. Branch, thư mục worktree và
thư mục artifact dùng một tên: nhìn đường dẫn là biết đang ở việc nào.

Agent không chọn base. `aw worktree new` liệt kê ứng viên kèm dữ kiện và gợi ý ★
theo một luật máy duy nhất (giữa `main` và `origin/main`, bản nào chứa bản kia);
phân kỳ thì không gợi ý. `--create` thiếu `--base` bị từ chối. Script không tự fetch:
thao tác mạng làm kết quả phụ thuộc thời điểm chạy — nó in thời điểm fetch cuối
để người tự cân nhắc. Branch tạo `--no-track`: mặc định git đặt upstream là
`origin/main`, và `git push` trơn trong worktree sẽ đẩy thẳng lên `main`.

Base được ghi vào `intake.md` (`ref @ sha`) và checker so diff với điểm rẽ nhánh
khỏi base đó thay vì `nhanh_goc`. Đo trên repo thử: việc chỉ sửa một file, tạo từ
`origin/main` trong khi `main` local chậm 2 commit — so với `main` thì phạm vi
diff thấy thêm file của đồng nghiệp; tạo từ `release/1.2` thì thấy thêm commit
bump version của nhánh phát hành. Ref không còn (branch cha đã xoá) thì dùng sha.
Xếp chồng lên branch việc khác không bị cấm (nhập qua "ref khác") nhưng không nằm
trong danh sách gợi ý, và review cảnh báo: việc dựa trên code chưa được review.

Dọn worktree (`aw worktree remove`) không bao giờ `--force` hay `branch -D`: gỡ
worktree không mất commit; xoá branch dùng `git branch -d` để git tự từ chối khi
chưa merge. Squash-merge git không nhận ra — script dừng, người tự quyết.

## Engine có version, cài ngoài repo (từ 2026.10.6)

Bộ cài cũ chép cả quy trình vào repo đích (`.agent-workflow/.quy-trinh/`) và bắt
commit vào nhánh gốc, vì worktree chỉ có file đã commit. Ba lý do khiến bản 2026.10.6 đổi
sang **engine có version + cấu hình cục bộ**:

1. **Protected branch.** Repo thật có `main`, `develop`, `uat` không ai được tự
   commit hay merge. Bộ cài phải vào base trước mới tạo được worktree — tức là
   mỗi lần cài hay nâng cấp quy trình phải qua một PR vào nhánh được bảo vệ. Bản mới
   không ghi gì vào cây làm việc mà git theo dõi: engine nằm trong
   `~/.agent-workflow/engine/<YYYY.M.N>/`, cấu hình nằm trong
   `$(git rev-parse --git-common-dir)/agent-workflow/` (dùng chung mọi worktree,
   không bao giờ vào commit), file sinh ra bị `.git/info/exclude`. Vì vậy **base
   tuỳ ý**: điều kiện "base phải có bộ cài" bị bỏ.
2. **Version theo việc.** Với bộ cài cũ, đồng bộ bộ cài giữa chừng đổi luật của mọi
   việc đang làm cùng lúc. Bản mới ghi `- **Engine:** YYYY.M.N` vào `intake.md` lúc tạo
   worktree; mọi `aw check` của việc chạy đúng version đó. Không có version đó
   và không tải được thì báo `KHÔNG HỢP LỆ` — chạy tạm bằng version khác là
   chấm một việc theo luật nó không được đặt ra. Luật so: khớp chính xác `YYYY.M.N`,
   không suy "tương thích" từ số phiên bản.
3. **Độc lập với agent.** Luật cứng nằm trong checker của engine (mã thoát +
   nhãn `Kết quả`), gọi bằng `aw …` — lệnh shell agent nào cũng chạy được.
   Adapter chỉ còn là lớp mỏng dịch `workflow/` sang dạng native và dặn agent
   gọi `aw`; thêm agent mới không đụng tới luật.

Các mảnh:

| Mảnh | Vai trò |
|---|---|
| `bin/aw` (wrapper, cài global) | Tìm repo bằng `git rev-parse`; chọn version (dòng `Engine:` của việc, hoặc file `version` của bản clone); tải bản thiếu vào cache, kiểm sha256; chuyển lệnh sang engine kèm `AW_REPO`, `AW_CONFIG`, `AW_ENGINE` |
| `bin/aw-engine` | Điểm vào của engine: `init`, `check`, `worktree`, `adapter build`, `feature`… |
| `tools/lib/moi-truong.sh` | Tool đọc đường dẫn repo và cấu hình **chỉ** từ biến môi trường; thiếu thì dừng. Không tool nào tự suy chúng từ vị trí của chính nó |
| `checksums` trong cấu hình | sha256 ghim lần đầu tải (`aw init`/`aw upgrade`). Lần tải sau phải khớp sha đã ghim, không tin lại `SHA256SUMS` — `SHA256SUMS` cùng nguồn với tarball chỉ bắt được file hỏng, không bắt được nguồn bị tráo. Chia sẻ qua repo cấu hình của team (`aw init --from`) |

Kênh tải mặc định là GitHub Release của repo này: file `agent-workflow-YYYY.M.N.tar.gz`
do workflow `release` đóng gói và gắn vào — không dùng tarball GitHub tự sinh từ
tag, vì byte của nó không được hứa giữ nguyên. `AW_MIRROR` đổi nguồn,
`AW_ENGINE_DIR` dùng engine có sẵn cho máy không có mạng.

**Version `YYYY.M.N` và phát hành bằng merge.** `N` là số thứ tự bản phát hành
trong tháng (không còn là ngày — một ngày một bản quá ít). Version vẫn được
**đặt trong PR** (`tools/chuan-bi-phat-hanh.sh`), không để CI tự tăng sau merge:
CI tự tăng thì bot phải commit thẳng vào `main` (cần vượt bảo vệ nhánh) và lịch
sử có commit không qua review. Merge vào `main` chỉ *phát hành* version đã nằm
trong PR: workflow `release` thấy tag chưa có thì tạo tag + Release ngay trong
job đó — tách ra workflow tạo tag riêng thì tag tạo bằng `GITHUB_TOKEN` không
kích hoạt được workflow `release`. Hai PR cùng lấy một số: CI của PR
(`tools/kiem-tra-phat-hanh.sh`) chặn PR merge sau vì tag đã có.

Wrapper và engine nói chuyện qua một số giao thức (`AW_PROTOCOL`): wrapper cũ
gặp engine đổi giao thức thì dừng, không truyền thiếu biến rồi chạy tiếp.

**Artifact chỉ ở máy.** `.agent-workflow/` bị exclude, nên artifact không vào PR.
Checker so diff vốn đã bỏ qua thư mục này nên không phải đổi. Cái giá: gỡ
worktree là mất artifact — `aw worktree remove` chép nó vào
`.git/agent-workflow/archive/<tên>/` trước khi gỡ; và reviewer của PR không thấy
`spec.md`/`tdd.md` (xem điểm yếu 7, 10).

## Hai loại điều kiện ra

Mỗi phase khai `exit_machine` và `exit_human`.

- **MÁY** — lệnh in khối `Kết quả` đánh `[x] ĐẠT` hoặc `[x] KHÔNG ĐẠT`. Agent không được tự tuyên bố đạt.
- **NGƯỜI** — cần người xác nhận. Agent nêu ra và dừng.

Nguyên tắc: tiêu chí nào diễn đạt được dưới dạng máy thì **phải** để máy kiểm.
"Agent tự đánh giá là đã đạt" không phải tiêu chí — nó là chỗ trống có hình dáng
của một tiêu chí.

Adapter thực thi nguyên tắc này bằng cách **từ chối build** nếu một mục
`exit_machine` không phải lệnh chạy được (`ĐỊNH NGHĨA QUY TRÌNH LỖI`). Không có chốt này, một
dòng mô tả bằng chữ sẽ lọt vào mục MÁY và agent sẽ tự duyệt — đã xảy ra một lần
trong chính quá trình xây repo này, ở phase `review`.

### Người ở đâu

Gate người cố định ở `intake`, `spec`, `design`, `review` (và `ship` nếu dùng).
Gate nào có phase máy chạy ngay sau thì phải để lại **dấu vết trong file** để
phase sau chặn được: spec và mỗi D-xx có một **ô duyệt** `- [ ] **Approved by human**`.
Gate chỉ nằm trong tài liệu thì agent chạy tiếp được trên một spec chưa ai đọc.

Ô duyệt là checkbox chứ không phải chữ gõ tay (`proposed` → `approved`): gõ sai một
dấu là checker không nhận. Đổi lại, LLM quen tick checklist khi xong việc, nên ô
duyệt có thêm hai lớp, cùng nằm ở `tools/lib/duyet.sh`:

- **Dấu duyệt.** Lần đầu thấy tick, máy ghi hash nội dung (spec, hoặc riêng D đó)
  vào cuối dòng: `<!-- approval-hash: <hex> -->`. Nội dung đổi mà tick còn thì
  `aw check` chặn ("đổi sau duyệt"). Đây là chỗ trước kia máy mù: agent sửa spec
  mà quên đặt lại trạng thái thì bản "đã duyệt" không còn là bản người đọc. Hash bỏ
  qua dòng trống, chú thích, và `- Critique (agent):` dưới D — agent phản biện ở
  Mode 2 mà không làm mất duyệt. `file_hash` (based_on) bỏ qua dấu duyệt, nên máy
  ghi dấu không làm artifact phía sau lỗi thời.
- **Hook `aw guard`** (Claude Code, người tự cài — adapter không ghi settings).
  `pre` trước mỗi lệnh ghi của agent: ghi dấu cho ô người vừa tick, đặt mốc. `post`
  sau lệnh đó: ô tick mà chưa có dấu thì được tick **trong lúc lệnh của agent
  chạy** → bỏ tick, trả mã 2 để agent đọc lý do; ô có dấu mà nội dung đổi cũng bỏ
  tick. Không cần đọc JSON của tool (không có jq trong yêu cầu môi trường): so
  trạng thái file trước/sau là đủ, và bắt được cả Edit, Write lẫn `sed -i` qua Bash.

Người gõ lệnh phase sau khi phần trước chưa duyệt thì lệnh mở đầu bằng **cổng
duyệt** (`approval_gate: true`): `aw approval <phase>` in bản tóm tắt cho người —
file/dòng phải tick, YC `[INFERRED]`, "Out of scope", `Risk` và Mode kéo theo,
điểm mù còn mở; hay D nào chưa duyệt, ai viết, chọn gì, có phản biện không — rồi
agent hỏi bằng hộp xác nhận. Bản tóm tắt do **máy** dựng từ file chứ không để
agent tự diễn giải: hộp xác nhận là chỗ người quyết, thông tin trong đó phải ổn
định và không bị chọn lọc. Hộp xác nhận **không** tick hộ — bấm một nút không
chứng minh người đã đọc, và máy không phân biệt được "agent tick vì người vừa
bấm" với "agent tự tick" (hook `aw guard` sẽ bỏ tick đó). Nó chỉ dẫn người tới
đúng chỗ rồi kiểm lại.

Parser chỉ nhận ô duyệt đúng chỗ: spec ở phần đầu file (trước `##` đầu tiên), D-xx
trong mục `### D-NN` của nó, đúng một ô; ô trong chú thích hay khối ``` không được
tính; dòng mang nhãn ô duyệt mà sai dạng là lỗi, không đoán.
`plan` và `implement` **không có người**: chúng chỉ thực thi những gì đã duyệt
ở `spec` và `design`. Đặt người ở đó chỉ tạo thêm một chỗ duyệt văn xuôi mà
không có quyết định thật nào để duyệt.

### Checker LLM: chỉ được chặn, không được duyệt

Có những điều kiện script không kiểm được — ví dụ một mục trong `tdd.md` có lệch
khỏi D-xx đã duyệt không, hay có quyết định ngầm nào chưa được nêu thành D.
Những chỗ đó dùng checker LLM, với một ràng buộc cứng:

- Checker ghi phát hiện ra **file**; script **fail nếu còn mục `Chặn`** chưa xử lý.
- LLM **không bao giờ** là bên nói "đạt". Không có phát hiện ≠ đạt; nó chỉ nghĩa
  là không có gì bị chặn.
- Người là **trọng tài theo ngoại lệ**: xác nhận phát hiện, hoặc bác bỏ kèm lý do.

Lý do: nếu LLM được duyệt, ta quay lại đúng chỗ "agent tự đánh giá là đã đạt".
Cho nó chỉ chặn thì sai sót của nó chỉ tốn thời gian người, không lọt lỗi.
Đây là mở rộng cách `review` vốn đã chạy.

### Chặn hay cảnh báo

Không phải checker nào cũng nên chặn. Chặn nhầm làm tắc flow, và người sẽ học
cách lách cổng.

| Loại checker | Ví dụ | Hành vi |
|---|---|---|
| **Chính xác** — hợp đồng output của chính phase | truy vết nguồn, phủ YC, test xanh | **Chặn** |
| **Kiểm chéo giữa phase**, hay báo nhầm | artifact lỗi thời, test ↔ YC, phạm vi diff | **Cảnh báo** |

Mọi cảnh báo dồn về `review`, là **cổng chặn cuối**: cảnh báo nào chưa xử lý thì
`review` chặn. Như vậy flow đi tiếp được ở giữa, nhưng không có gì lọt qua cuối.

Tiêu chí xếp một checker mới vào cột nào: **độ chính xác**, **chi phí nếu lọt**,
và **nơi sửa rẻ nhất**.

### Artifact lỗi thời

Mỗi artifact ghi `based_on` là hash **cả file** của đầu vào, dạng phẳng
(`- spec.md@<hash>`) để đọc được bằng tập con YAML. Hash cả file thay vì từng
mục vì đơn giản và không bỏ sót — đổi lại nó báo cả khi chỉ sửa chính tả, nên
lệch hash chỉ là **cảnh báo**; `review` chặn nếu còn artifact lỗi thời.

Chuỗi phụ thuộc: `spec.md` ← `intake.md`; `tdd.md` ← `spec.md` + `open-questions.md`;
`plan.md` ← `spec.md` + `tdd.md`. Thiếu một mắt xích (trước đây spec không ghi
`based_on`) thì đổi input sau khi viết spec sẽ lọt qua im lặng.

## Quyết định là thứ người duyệt, không phải văn xuôi

Người duyệt một tài liệu thiết kế dài thường lướt, vì văn xuôi không cho thấy
chỗ nào là lựa chọn thật. Vì vậy `design` tách các lựa chọn thành mục **D-xx**
riêng trong `tdd.md`; người duyệt từng D, phần còn lại là hệ quả.

- Mục chi tiết ghi `Based on: D-xx`; checker LLM chặn chỗ lệch D và quyết định
  ngầm. Mục D **được phép rỗng** — thay đổi nhỏ có thể không có quyết định nào.
- `tdd.md` là **output duy nhất** của `design`, không có file quyết định riêng:
  tách ra thì hai file sẽ lệch nhau.

### Chống neo: Mode 2

Khi agent đưa phương án trước, người duyệt có xu hướng neo vào nó. Với thay đổi
`Risk: high` (tiền/hạch toán, tích hợp mới, schema lõi, khó đảo ngược — agent
đề xuất nhãn, người duyệt ở gate spec), `design` **chặn** nếu chưa có bản phác
mục D-xx do người viết (`Author: human`). Có bản phác thì agent chỉ phản biện.
Rủi ro thường dùng Mode 1: agent viết cả `tdd.md`, người duyệt.

### Mở lại một quyết định

Mở lại **đúng một D-xx**, sửa tại chỗ; lịch sử để git giữ, không giữ bản cũ trong
file. D đó bỏ tick ô duyệt + thêm `Reopen reason:` (trạng thái `reopened`). Grep `Based on: D-xx` ra task và test
bị ảnh hưởng; chỉ các task đó đặt lại `[ ]`, người chỉ duyệt lại D đang mở.

### Vì sao `plan` vẫn tách khỏi `tdd.md`

`plan.md` chỉ còn quản lý thực thi: task, phụ thuộc, `Covers: YC`, `Based on: D-xx`,
`Design: tdd.md § …`, Expected files, Verify, trạng thái, Unplanned,
Deferred. Giữ riêng vì hai lẽ: plan là ranh giới do **phiên khác** đặt cho
`implement`, và tick task không được phép sửa vào `tdd.md` đã duyệt.

## Giả định chưa xác nhận

Chỗ chưa rõ trong spec ghi `[OPEN-QUESTION]` kèm **mức chặn**; agent đề xuất, người
duyệt nhãn ở gate spec. Đúng ba mức — thêm mức nữa thì người duyệt phải phân
biệt những ranh giới không ai đo được:

| Mức | Sai giả định thì | Chặn |
|---|---|---|
| `blocking` | Cả thiết kế đổi hướng | Phase ngay sau spec (`design`; chore: `plan`) — và mọi phase sau, vì checker mỗi phase chạy lại checker phase trước |
| `review-blocking` | Làm lại một phần code | Như một kiểm chéo: `implement` cảnh báo, `review` chặn |
| `non-blocking` | Sửa nhỏ | Không chặn; `review` ghi YC đó `pending` thay vì `pass` |

Ba mức đặt cổng chặn ở **phase rẻ nhất để sửa** nếu giả định sai: lật hướng thiết
kế thì phải biết trước khi thiết kế; sai một phần code thì biết trước khi merge
là đủ; còn lại thì chấp nhận giao trên giả định và ghi rõ là chưa xác nhận.

Lệnh tiện ích `clarify` (`workflow/clarify.md`) dẫn người đi qua
các mục còn mở: `aw pending` xếp thứ tự bằng máy (mức chặn → YC
`must` trước → nhiều task đứng trên giả định hơn → mã YC) và chỉ ra mục nào
đang chặn phase kế tiếp; agent hỏi **từng mục một**, đưa phương án lấy từ nguồn,
ghi nguyên văn câu trả lời của người. Agent không tự trả lời và không tự hạ mức.
Câu trả lời của người trong hội thoại **chính là** gate người của điểm mù; dấu vết
nằm ở dòng `Answer:` — ai, ngày, nguyên văn. Nhưng spec đã được tick duyệt thì
sửa YC (hay chỉ đổi nhãn nguồn) làm nó khác bản đã duyệt: agent bỏ tick, người
tick lại. Trước kia `Status` của spec được giữ nguyên ở đây cho đỡ một bước; khi
duyệt gắn với hash nội dung thì ngoại lệ đó không còn đứng được — máy không phân
biệt "sửa người vừa xác nhận" với "sửa người chưa thấy".

Cùng lệnh đó dẫn người **phân xử phát hiện của checker LLM** (`phat-hien-*.md`):
đồng ý thì agent sửa đúng chỗ (người xem trước → sau) rồi ghi `đã sửa`; bác bỏ
thì ghi lý do nguyên văn. Hàng đợi xếp theo phase bị chặn sớm nhất: điểm mù
`blocking` (chặn `design`) trước phát hiện `Chặn` (chặn `plan`) trước điểm mù
`review-blocking`.

**Gộp ở chỗ người nhìn, không gộp chỗ lưu.** Điểm mù và phát hiện vẫn ở file
riêng: mỗi file có một bên ghi và vòng đời riêng (checker LLM ghi đè cả file
mỗi lần chạy), và `based_on` băm cả file — chung một file thì checker ghi phát
hiện sẽ làm chính `tdd.md` vừa viết bị báo lỗi thời. Checker LLM mới chỉ cần
ghi `phat-hien-<id>.md` đúng mẫu (`### PH-NN`, `Mức`, `Xử lý`) là `aw pending`
tự gom.

### Vì sao checker tự chạy test thay vì đọc kết quả

`aw check implement` tự chạy lệnh test và tự ghi output vào
`ket-qua-kiem-thu.md`. Nếu để agent chạy rồi dán kết quả vào, ta chỉ kiểm được
*cái agent nói*, không kiểm được *cái đã xảy ra*. Tự chạy thì bỏ hẳn khoảng cách
đó — agent không có chỗ nào để bịa.

### Quét bảo mật: chạy ở implement, review kiểm độ mới

Pipeline CI/CD chạy secret scan, SAST, SCA; quy trình trước đây thì không. Kết quả:
việc qua `aw check review` local rồi mới bị pipeline chặn release. Sửa bằng cách
chạy **đúng lệnh của CI** (`LENH_KIEM_TRA_BAO_MAT` trong `config.sh`, mỗi dòng
`<nhóm>: <lệnh>`, nhóm `secret | sast | sca | other`) theo cùng mẫu với test: máy
tự chạy, tự ghi `ket-qua-bao-mat.md`, chưa khai là KHÔNG ĐẠT.

**Chạy ở `implement`, không ở `review`.** Lỗi quét ra là việc phải sửa code — việc
của `implement`; review chạy ngữ cảnh trắng và bị **cấm sửa code**, nên quét ở đó
chỉ để báo đỏ rồi quay về implement, tốn một vòng. Quét cũng chậm (SAST, SCA tải
CSDL CVE), không nên chạy lại mỗi lần sửa một dòng `review.md`. Review chỉ kiểm
phần chính xác: kết quả xanh, và còn mới.

**Độ mới theo `Tree`, không theo SHA của HEAD.** `ket-qua-kiem-thu.md` và
`ket-qua-bao-mat.md` ghi `HEAD`, `Tree`, thời điểm. `Tree` là tree SHA của nội dung
worktree (đã commit + chưa commit + chưa track, trừ `.agent-workflow/`), tính bằng
index tạm nên không đụng staging của người. So theo HEAD thì sửa code chưa commit
sau khi chạy test vẫn lọt (diff mà checker so có tính file chưa commit); còn commit
đúng code đã review (bước trước `/aw-ship`) lại làm kết quả "lỗi thời" dù code không
đổi. `Tree` đúng cả hai chiều. HEAD ghi để người đọc, máy không so.

Trước đây (giới hạn 8 cũ) review chỉ đọc dòng kết quả, sửa code sau lần chạy
`implement` cuối vẫn qua — nay chặn.

**Không bắt đủ ba nhóm.** Thiếu `secret`/`sast`/`sca` chỉ cảnh báo: repo có thể
không dùng nhóm đó, và người khai `config.sh` biết pipeline của mình. Ngoại lệ là
`chore` đụng file dependency — đúng chỗ SCA sinh ra để bắt — thì phải có lệnh `sca`
xanh.

### Lens 4 — bảo mật do người rà phán, bảng cố định

Máy quét bắt **mẫu**: secret khớp regex, CVE trong lockfile, pattern SAST. Nó
không biết **ý đồ**: endpoint mới thiếu kiểm quyền theo YC Phân quyền, log in số
tài khoản, id lấy từ request mà không kiểm chủ sở hữu. Đó là việc của người rà.

Bảng **bảy hạng mục cố định** chứ không phải "ghi finding bảo mật nếu có": danh
sách mở thì "không thấy gì" và "không xét" trông giống hệt nhau. Mỗi hạng mục một
dòng `pass | finding | not applicable` — cùng cách máy kiểm bảng Repo rules: thiếu
dòng, verdict lạ, `finding`/`not applicable` không vị trí/lý do thì chặn. Máy không
biết `pass` có đúng không (giới hạn 12), nhưng biết người rà đã phải nhìn từng mục.
`finding` thì Lens 3 phải có ít nhất một finding — mức (`Blocker`…) nằm ở đó, nơi
`aw check ship` đã đếm.

Parser Lens 1 chỉ đọc dòng bảng có **ô đầu** là mã YC: dòng Authn của Lens 4 hay
nhắc YC Phân quyền ở cột lý do, trước đây sẽ ghi đè kết luận của YC đó.

### Test ↔ YC và phạm vi diff

Hai kiểm chéo của `implement`, đều chỉ **cảnh báo** (`review` chặn):

- Test gắn tag `covers: YC-xxx`. YC chưa có test thì cảnh báo; YC không test tự
  động được ghi `Kiểm chứng: thủ công` + lý do.
- So `git diff --name-only <nhánh-gốc>...HEAD` với "Expected files" (cho phép glob)
  và "Unplanned" trong plan.

Mẫu file test, cú pháp tag, nhánh gốc và danh sách file bỏ qua khai trong
`conventions.md` của repo đích — phần máy đọc phải parse được bằng sh/awk.

### Quy tắc riêng của repo

Repo đích khai file quy tắc cho từng phase ở khoá `quy_tac_<phase>` của
`conventions.md`; agent lấy danh sách bằng `aw rules <phase>`. Ba lựa chọn:

- **Đọc lúc chạy, không chép vào lệnh lúc build.** `conventions.md` do người sửa
  sau khi cài và sửa nhiều lần; chép vào lúc `aw adapter build` thì lệnh của
  agent lệch cấu hình mà không ai biết.
- **Agent đọc file như tài liệu, không dựa vào skill tự kích hoạt.** Skill của
  Claude Code chỉ chạy khi agent thấy mô tả khớp, và agent khác không thấy nó.
  Đưa đường dẫn vào thì mọi agent đọc được như nhau.
- **Máy chỉ kiểm phần chính xác:** file có thật, đã commit, khoá không gõ nhầm
  (chặn ở phase khai nó), và `review.md` có kết luận cho từng file (chặn ở
  review). Code có theo quy tắc hay không là việc người rà soát phán — như với
  `tdd.md`.

Quy tắc repo xếp dưới `spec.md`, `tdd.md`, `plan.md`: một skill bảo "dọn file
đụng tới" không được thắng luật giữ diff trong phạm vi.

Không có phase test riêng: test là điều kiện ra của `implement`. Một phase test
đặt phía sau sẽ biến "code xong" thành trạng thái hợp lệ dù chưa ai chạy gì.

## Định dạng file phase

Frontmatter YAML (tập con) + thân markdown:

```yaml
---
id: spec                    # định danh, ASCII, trùng tên slash command
name: Đặc tả                # tên hiển thị
summary: ...                # một dòng, dùng cho mô tả lệnh
required: true              # false = phase tuỳ chọn
when: ...                   # điều kiện kích hoạt, chỉ khi required: false
status: chưa hiện thực      # có mặt = adapter bỏ qua phase này
inputs: [intake.md, confluence, jira, file]
outputs: [spec.md, open-questions.md]
exit_machine: [aw check spec]
exit_human: [...]
needs_clean_context: true   # phải chạy được từ phiên trắng
requires_fresh_agent: true  # không được dùng chính phiên vừa làm việc trước đó
llm_checker: workflow/checkers/thiet-ke.md   # có checker LLM; adapter từ chối build nếu file không có
arguments: input            # tham số lệnh là input, không phải tên feature (chỉ 00-intake)
approval_gate: true         # lệnh phase mở đầu bằng cổng duyệt (aw approval) — 02-design, 03-plan
---
```

Lệnh tiện ích (`workflow/<id>.md`, khai ở `commands:` của manifest — hiện có
`import`, `clarify`) không phải phase: frontmatter chỉ có `id`, `name`,
`summary`, tuỳ chọn `argument_hint`, `arguments: mixed`, và `choice_ui: true` khi
lệnh hỏi người bằng câu hỏi lựa chọn (adapter dịch sang giao diện của agent).

Checker LLM (`workflow/checkers/*.md`) có frontmatter `id`, `summary`, `inputs`,
`output` (tên file phát hiện). Adapter Claude Code biến nó thành subagent
`soat-<id>`. Script của phase đọc file phát hiện; thiếu file là fail.

## Hiện thực các cơ chế

| Cơ chế | Nằm ở | Ghi chú |
|---|---|---|
| Xác định feature | `tools/xac-dinh-feature.sh` (`aw feature`) | Đọc gốc worktree từ `AW_REPO`; thư mục artifact là `$AW_REPO/.agent-workflow/<tên>` |
| Đọc `conventions.md` | `conv_get` trong `tools/lib/md.sh` | Chỉ đọc khối ` ```conventions `; phần còn lại là văn xuôi cho người |
| Hash `based_on` | `tools/cap-nhat-based-on.sh`, `file_hash` | `cksum` sau khi bỏ `\r` — POSIX, CRLF/LF cho cùng kết quả |
| Kiểm chéo | `tools/lib/kiem-cheo.sh` | Một hàm in phát hiện; `implement` gọi là cảnh báo, `review` gọi là lỗi |
| Mức chặn của điểm mù | `kc_diem_mu_mo` trong `tools/lib/kiem-cheo.sh` | Cùng một hàm: `design` (chore: `plan`) chặn mức `blocking`; `implement` cảnh báo, `review` chặn mức `blocking` + `review-blocking` |
| Hàng đợi việc chờ người | `tools/liet-ke-viec-cho.sh` (`aw pending`) | Gom điểm mù + mọi `phat-hien-*.md`; máy xếp, agent không xếp lại; chỉ đọc, không sửa file |
| Entry check | Đầu mỗi `kiem-tra-*.sh` | Gọi checker phase trước; chuỗi `ra-soat → ke-hoach → thiet-ke → truy-vet` |
| Cấu hình lệnh test | `$AW_CONFIG/config.sh` | `AW_CONFIG` = `$(git rev-parse --git-common-dir)/agent-workflow`, wrapper truyền vào |
| Ghim version của việc | `kc_engine_dong`; `bin/aw-engine check`; `bin/aw` | Wrapper chọn engine theo dòng `Engine:`; engine từ chối chấm việc ghim version khác; `aw check intake` chặn khi thiếu dòng |
| Tên checker | `tools/lib/bang-lenh.sh` | Một bảng cho `aw check <tên>` và cho adapter kiểm `exit_machine` |
| Quy tắc riêng của repo | `kc_quy_tac*` trong `tools/lib/kiem-cheo.sh`; `tools/quy-tac-repo.sh` (`aw rules`) | Phase có khoá: `BL_QUY_TAC` trong `bang-lenh.sh`. Checker phase gọi `kc_quy_tac_loi`; review thêm khoá gõ nhầm + mục "Repo rules" |
| Một awk đọc nhiều file | Mọi `kiem-tra-*.sh`, `kiem-cheo.sh` | Xác định file bằng `FILENAME == ARGV[i]`, **không** đếm `FNR==1`: file 0 byte không có dòng nào, bộ đếm lệch và file sau bị đọc như file trước |

Phạm vi diff so với `git merge-base <base> HEAD` **tới cây làm việc** (`<base>` là
dòng Base của `intake.md`, thiếu thì `nhanh_goc`), cộng file mới chưa track —
rộng hơn `<base>...HEAD`, để thay đổi chưa commit
trong lúc `implement` cũng bị thấy. Thư mục `.agent-workflow/` luôn được bỏ qua.

Thân file có các mục cố định: **Mục tiêu**, **Đầu vào**, **Việc phải làm**,
**Đầu ra**, **Cấm**, **Điều kiện ra**.

Mục **Cấm** không phải trang trí. Nó liệt kê việc thuộc phase khác, và là chỗ
chặn thất bại đặc trưng nhất của agent trong quy trình có phase: `01-spec` chọn
luôn giải pháp kỹ thuật (việc của `02-design`), `04-implement` sửa thêm những thứ
"tiện tay thấy chưa đẹp". Cả hai đều xoá mất điểm dừng để người xem lại.

## Tập con YAML

`tools/lib/md.sh` đọc một tập con YAML cố ý giữ hẹp, để không phải phụ thuộc
runtime nào ngoài POSIX shell + awk:

```yaml
khoa: gia tri
khoa:
  - muc
  - muc
khoa: []
```

**Không** hỗ trợ: map lồng nhau, khối nhiều dòng (`|`, `>`), flow không rỗng,
chú thích cuối dòng, anchor/alias.

Đây là đánh đổi có chủ ý. Một trình đọc YAML đầy đủ nghĩa là kéo theo Node hoặc
Python — mà máy phát triển không phải lúc nào cũng có (máy dựng repo này không
có cả hai). Đổi lại, manifest và frontmatter phải viết bám đúng tập con. Ràng
buộc này chỉ áp dụng cho *cấu hình*, không áp dụng cho repo đích.

## Cách thêm một phase

1. Tạo `workflow/phases/NN-<id>.md` với frontmatter đầy đủ.
2. Thêm mục vào `phases:` trong `workflow.yaml` (`id`, `file`, `required`).
3. Nếu có `exit_machine`, viết script tương ứng trong `tools/` và thêm tên vào
   `tools/lib/bang-lenh.sh`; frontmatter ghi `aw check <tên>`. Adapter từ chối
   build nếu tên không có trong bảng.
4. Nếu phase sinh artifact mới, thêm mẫu vào `workflow/templates/`.
5. Thêm ca kiểm vào `tools/chay-thu.sh`.
6. Thử trên một repo đích: `AW_ENGINE_DIR=<repo này> aw adapter build claude-code`
   (VERSION phải khớp version của repo đích). Phát hành bằng một version mới —
   việc đang làm vẫn chạy version cũ.

Không phase nào khác phải sửa — vì không phase nào biết gì về phase đứng sau nó.
Đó là lý do `06-ship` thêm được sau mà không phải viết lại.

## Cách thêm một adapter

Xem `adapters/README.md` (hợp đồng: `build.sh`, file `exclude`, hook của adapter,
nhiều adapter, mục "Viết adapter mới"). Việc sinh nằm trong `adapters/lib/chung.sh`
(`ad_sinh`); adapter chỉ khai hook — chữ riêng của agent (cách hỏi lựa chọn, cách
viết tham số, đầu file). Test đối chiếu build mọi adapter với hook thay bằng tên và
đòi output giống hệt nhau: hợp đồng phase không thể lệch giữa các agent.
Adapter chỉ dặn agent gọi `aw …`, không mang luật. Điểm quan trọng
nhất: với mỗi khả năng không dịch được sang agent đích (subagent, hook, MCP),
adapter phải **ghi rõ trong output** rằng người dùng phải tự làm — không im lặng
bỏ qua. Bỏ qua âm thầm khiến quy trình *nhìn như* đang chạy đủ trong khi đã mất
một ràng buộc.

## Những chỗ thiết kế này yếu

Nói thẳng để người đọc sau khỏi phải tự phát hiện:

1. **`06-ship` chỉ lo phần MR, không lo phần phát hành.** Tạo MR/PR, theo dõi,
   dọn worktree là việc chung (qua `gh`/`glab`); deploy, tag, release note đặc thù
   CI từng repo nên nằm ngoài quy trình. Trạng thái MR dựa vào CLI của nền tảng —
   không có CLI thì chỉ suy được từ git, và git không nhận ra squash merge.

2. **Ràng buộc "ngữ cảnh sạch" không tự cưỡng chế được ở agent không có
   subagent.** Nó lùi về một dòng hướng dẫn cho người, và người thì hay bỏ qua.

3. **Cổng chặn kiểm được *hình thức*, không kiểm được *nội dung*.** Checker biết
   mọi `YC` đều có nhãn nguồn; nó không biết nội dung yêu cầu có phản ánh đúng
   BRD hay không. Đó vẫn là việc của người — mục `exit_human` tồn tại vì vậy.
   Đừng nhầm "qua hết checker" với "làm đúng". Checker LLM thu hẹp khoảng trống
   này một phần, nhưng vì nó chỉ được chặn, những gì nó bỏ sót vẫn lọt qua.

4. **Mode 2 dựa trên nhãn rủi ro đúng.** Nhãn `Risk` do agent đề xuất; nếu
   người duyệt ở gate spec cho qua nhãn `normal` sai, `design` sẽ chạy Mode 1 và
   hiện tượng neo quay lại.

5. **Hash cả file báo cả thay đổi vô hại.** Sửa chính tả trong `spec.md` cũng làm
   mọi artifact sau thành "lỗi thời". Đây là lý do nó chỉ cảnh báo — và cũng là
   lý do người có thể quen tay bỏ qua cảnh báo này.

6. **Tập con YAML dễ vỡ nếu ai đó viết manifest theo kiểu khác.** Trình đọc
   không báo lỗi cú pháp; nó chỉ trả về giá trị rỗng, và lỗi sẽ lộ ra muộn ở
   chỗ khác.

7. **"Duyệt" là một ô tick trong file** (ô "Approved by human" ở đầu `spec.md` và ở
   từng D-xx). Máy không biết **ai** tick. Hook
   `aw guard` bắt agent tick trong lúc lệnh của nó chạy — nhưng chỉ khi repo cài
   hook, và chỉ với agent có hook (Claude Code). Không có hook thì agent vi phạm
   luật mà tự tick vẫn lọt; artifact không nằm trong git (từ 2026.10.6) nên cũng
   không có `git blame` để soi. Hook cũng không phân biệt được agent cố tình tự
   tính hash rồi ghi dấu giả, và sẽ bỏ nhầm tick nếu người tick đúng lúc một lệnh
   dài của agent đang chạy (người tick lại). Dấu duyệt bắt được nội dung đổi sau
   khi tick ở mọi agent — trừ khi nội dung đổi **trước** lần ghi dấu đầu tiên
   (người tick, rồi agent sửa trước khi có `aw check` hay hook nào chạy).

8. **`review` không chạy lại test hay quét.** Nó đọc kết quả và so `Tree` với code
   hiện tại — biết kết quả **cũ**, không biết lệnh có **đủ**. `LENH_KIEM_TRA_BAO_MAT`
   lệch pipeline (thiếu công cụ, ngưỡng lỏng hơn, rule khác) thì local vẫn xanh mà
   CI vẫn chặn; đồng bộ với file pipeline là việc của người giữ `config.sh`. Lệnh
   test/quét ghi file vào repo (không `.gitignore`) làm `Tree` đổi sau mỗi lần chạy.

9. **Glob trong `conventions.md` và "Expected files" dùng `case` của shell**, nên
   `*` khớp cả `/` và không có `**`. `src/*` vì vậy rộng hơn người đọc tưởng.

10. **Artifact không đi theo PR.** Reviewer của PR chỉ thấy code; đặc tả và quyết
    định D-xx nằm ở máy người làm (và `archive/` sau khi gỡ worktree). Muốn chia
    sẻ thì phải chép ra chỗ khác bằng tay — quy trình không tự làm.

11. **Ghim sha256 là tin lần đầu (TOFU).** Lần tải đầu tiên tin `SHA256SUMS` của
    bản phát hành; nếu lần đó đã bị tráo thì sha bị ghim sai. Repo cấu hình chung
    của team thu hẹp rủi ro (một người ghim, mọi người kiểm theo), không xoá được.

12. **Tuân thủ quy tắc repo chỉ do người phán.** Máy biết `review.md` có một dòng
    kết luận cho mỗi file quy tắc, không biết dòng `pass` có đúng không. Quy tắc
    nào viết được thành lệnh (lint, type, kiến trúc) thì nên nằm trong
    `LENH_KIEM_THU`.
