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
  nguồn trỏ về tài liệu gốc; chỗ không rõ ghi `[CẦN-HỎI]`. Kết quả qua checker và
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
**chép nguyên văn** (`[NGƯỜI-DÙNG]`). `[SUY-RA]` bị cấm ở input — nếu không, điều
agent tự suy ra sẽ sang spec với nhãn `[FILE] intake.md` như có nguồn thật.

**Nguồn sự thật của loại việc** là `intake.md` (người xác nhận). Tiền tố branch
chỉ để gợi ý và đối chiếu; lệch thì cảnh báo, `review` chặn, không có ngoại lệ
"ghi lý do chấp nhận lệch" — vì ngoại lệ dễ ghi hơn sửa, và tiền tố sẽ mất nghĩa.
`tools/doi-ten-feature.sh` đổi tên branch và dời thư mục artifact trong một lệnh.

Phân loại theo **thay đổi gì về hành vi**, không theo "xây cái gì": một loại chỉ
đáng tồn tại khi nó đổi luật. Vì vậy không có `utils`, `hotfix`, `security`;
`spike` nằm ngoài quy trình (output là kết luận, không phải code để merge).

Cùng một mẫu cho mọi bằng chứng theo loại: **máy tự chạy và tự ghi** (không để
agent chép kết quả), **máy chặn phần chính xác**, **người phán phần mơ hồ**:

| Loại | Máy chặn (chính xác) | Người phán (mơ hồ) | Vì sao không để máy phán |
|---|---|---|---|
| `bugfix` | Có `tai-hien.md` ghi lúc diff chỉ đụng file test, mã thoát ≠ 0 | Đỏ **đúng vì bug** | Test mới trên code cũ có thể đỏ vì lỗi biên dịch |
| `refactor` | Xoá test cũ; sửa test cũ không khai; YC giữ nguyên không có test trên nhánh gốc | Diff test cũ chỉ đổi import | Heuristic "chỉ đổi import" phụ thuộc ngôn ngữ, hay báo nhầm |
| `perf` | Thiếu số đo trước hoặc sau (`do-hieu-nang.md`) | Đạt mục tiêu chưa | Số đo dao động; chặn theo ngưỡng sẽ chặn nhầm |
| `chore` | Đụng `mau_code_production`; đụng dependency mà không khai; khai `major` | Mức phiên bản khai đúng | Cú pháp phiên bản mỗi hệ sinh thái mỗi khác |

Không dựng lại code cũ trong worktree để chạy test tái hiện: trông chặt hơn nhưng
cho kết luận sai mà tự tin (đỏ vì thiếu hàm vẫn tính là "tái hiện được").

### Artifact theo feature

Artifact nằm trong `.agent-workflow/<tên-branch>/`, dùng tên branch **đầy đủ**
(`feat_tao-todo`, `refactor_tao-todo`) để hai loại việc cùng tên không đè nhau.
Quy ước tên branch nằm trong `conventions.md` của repo đích vì nó tuỳ hoàn cảnh
từng team; bộ cài chỉ tạo mẫu và không ghi đè.

Thứ tự xác định feature: suy từ branch theo `conventions.md` → không khớp thì lấy
tham số lệnh → không có thì dừng hỏi. Agent luôn in `Đang làm với: …` — ghi nhầm
artifact sang feature khác là lỗi im lặng, khó phát hiện về sau.

## Hai loại điều kiện ra

Mỗi phase khai `exit_machine` và `exit_human`.

- **MÁY** — lệnh trả mã thoát 0/1. Agent không được tự tuyên bố đạt.
- **NGƯỜI** — cần người xác nhận. Agent nêu ra và dừng.

Nguyên tắc: tiêu chí nào diễn đạt được dưới dạng máy thì **phải** để máy kiểm.
"Agent tự đánh giá là đã đạt" không phải tiêu chí — nó là chỗ trống có hình dáng
của một tiêu chí.

Adapter thực thi nguyên tắc này bằng cách **từ chối build** nếu một mục
`exit_machine` không phải lệnh chạy được (mã thoát 4). Không có chốt này, một
dòng mô tả bằng chữ sẽ lọt vào mục MÁY và agent sẽ tự duyệt — đã xảy ra một lần
trong chính quá trình xây repo này, ở phase `review`.

### Người ở đâu

Gate người cố định ở `intake`, `spec`, `design`, `review` (và `ship` nếu dùng).
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

## Quyết định là thứ người duyệt, không phải văn xuôi

Người duyệt một tài liệu thiết kế dài thường lướt, vì văn xuôi không cho thấy
chỗ nào là lựa chọn thật. Vì vậy `design` tách các lựa chọn thành mục **D-xx**
riêng trong `tdd.md`; người duyệt từng D, phần còn lại là hệ quả.

- Mục chi tiết ghi `Dựa trên: D-xx`; checker LLM chặn chỗ lệch D và quyết định
  ngầm. Mục D **được phép rỗng** — thay đổi nhỏ có thể không có quyết định nào.
- `tdd.md` là **output duy nhất** của `design`, không có file quyết định riêng:
  tách ra thì hai file sẽ lệch nhau.

### Chống neo: Mode 2

Khi agent đưa phương án trước, người duyệt có xu hướng neo vào nó. Với thay đổi
`Mức rủi ro: cao` (tiền/hạch toán, tích hợp mới, schema lõi, khó đảo ngược — agent
đề xuất nhãn, người duyệt ở gate spec), `design` **chặn** nếu chưa có bản phác
mục D-xx do người viết (`tac_gia: nguoi`). Có bản phác thì agent chỉ phản biện.
Rủi ro thường dùng Mode 1: agent viết cả `tdd.md`, người duyệt.

### Mở lại một quyết định

Mở lại **đúng một D-xx**, sửa tại chỗ; lịch sử để git giữ, không giữ bản cũ trong
file. D đó mang trạng thái `mở lại` + lý do. Grep `Dựa trên: D-xx` ra task và test
bị ảnh hưởng; chỉ các task đó đặt lại `[ ]`, người chỉ duyệt lại D đang mở.

### Vì sao `plan` vẫn tách khỏi `tdd.md`

`plan.md` chỉ còn quản lý thực thi: task, phụ thuộc, `Phủ: YC`, `Dựa trên: D-xx`,
`Theo: tdd.md § …`, File dự kiến, Cách kiểm chứng, trạng thái, Phát sinh, Hoãn
lại. Giữ riêng vì hai lẽ: plan là ranh giới do **phiên khác** đặt cho
`implement`, và tick task không được phép sửa vào `tdd.md` đã duyệt.

## Giả định chưa xác nhận

Chỗ chưa rõ trong spec ghi `[CẦN-HỎI]` kèm **mức ảnh hưởng**; agent đề xuất,
người duyệt nhãn ở gate spec. Mặc định **không chặn** — ưu tiên flow đi tiếp. Chỉ
mục ảnh hưởng toàn bộ thiết kế phải được trả lời trước khi vào `design`. Mục còn
mở thì `review` không được kết luận "đạt".

### Vì sao checker tự chạy test thay vì đọc kết quả

`kiem-tra-hien-thuc.sh` tự chạy lệnh test và tự ghi output vào
`ket-qua-kiem-thu.md`. Nếu để agent chạy rồi dán kết quả vào, ta chỉ kiểm được
*cái agent nói*, không kiểm được *cái đã xảy ra*. Tự chạy thì bỏ hẳn khoảng cách
đó — agent không có chỗ nào để bịa.

### Test ↔ YC và phạm vi diff

Hai kiểm chéo của `implement`, đều chỉ **cảnh báo** (`review` chặn):

- Test gắn tag `covers: YC-xxx`. YC chưa có test thì cảnh báo; YC không test tự
  động được ghi `Kiểm chứng: thủ công` + lý do.
- So `git diff --name-only <nhánh-gốc>...HEAD` với "File dự kiến" (cho phép glob)
  và "Phát sinh" trong plan.

Mẫu file test, cú pháp tag, nhánh gốc và danh sách file bỏ qua khai trong
`conventions.md` của repo đích — phần máy đọc phải parse được bằng sh/awk.

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
exit_machine: [sh tools/kiem-tra-truy-vet.sh]
exit_human: [...]
needs_clean_context: true   # phải chạy được từ phiên trắng
requires_fresh_agent: true  # không được dùng chính phiên vừa làm việc trước đó
llm_checker: workflow/checkers/thiet-ke.md   # có checker LLM; adapter từ chối build nếu file không có
---
```

Checker LLM (`workflow/checkers/*.md`) có frontmatter `id`, `summary`, `inputs`,
`output` (tên file phát hiện). Adapter Claude Code biến nó thành subagent
`soat-<id>`. Script của phase đọc file phát hiện; thiếu file là fail.

## Hiện thực các cơ chế

| Cơ chế | Nằm ở | Ghi chú |
|---|---|---|
| Xác định feature | `tools/xac-dinh-feature.sh` | Script nằm ở `<repo>/.agent-workflow/.quy-trinh/tools/`, suy ra thư mục artifact từ vị trí của chính nó |
| Đọc `conventions.md` | `conv_get` trong `tools/lib/md.sh` | Chỉ đọc khối ` ```conventions `; phần còn lại là văn xuôi cho người |
| Hash `based_on` | `tools/cap-nhat-based-on.sh`, `file_hash` | `cksum` sau khi bỏ `\r` — POSIX, CRLF/LF cho cùng kết quả |
| Kiểm chéo | `tools/lib/kiem-cheo.sh` | Một hàm in phát hiện; `implement` gọi là cảnh báo, `review` gọi là lỗi |
| Entry check | Đầu mỗi `kiem-tra-*.sh` | Gọi checker phase trước; chuỗi `ra-soat → ke-hoach → thiet-ke → truy-vet` |
| Cấu hình lệnh test | `.agent-workflow/.quy-trinh/cau-hinh.sh` | Checker tìm ở `<thư-mục-feature>/../.quy-trinh/` |

Phạm vi diff so với `git merge-base <nhanh_goc> HEAD` **tới cây làm việc**, cộng
file mới chưa track — rộng hơn `<nhanh_goc>...HEAD`, để thay đổi chưa commit
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
3. Nếu có `exit_machine`, viết script tương ứng trong `tools/` — adapter sẽ từ
   chối build nếu script không tồn tại.
4. Nếu phase sinh artifact mới, thêm mẫu vào `workflow/templates/`.
5. Thêm ca kiểm vào `tools/chay-thu.sh`.
6. Chạy lại `sh tools/cai-dat.sh <repo-đích>`.

Không phase nào khác phải sửa — vì không phase nào biết gì về phase đứng sau nó.
Đó là lý do `06-ship` thêm được sau mà không phải viết lại.

## Cách thêm một adapter

Xem `adapters/claude-code/README.md`, mục "Viết adapter mới". Điểm quan trọng
nhất: với mỗi khả năng không dịch được sang agent đích (subagent, hook, MCP),
adapter phải **ghi rõ trong output** rằng người dùng phải tự làm — không im lặng
bỏ qua. Bỏ qua âm thầm khiến quy trình *nhìn như* đang chạy đủ trong khi đã mất
một ràng buộc.

## Những chỗ thiết kế này yếu

Nói thẳng để người đọc sau khỏi phải tự phát hiện:

1. **`06-ship` chưa có nội dung.** Phát hành đặc thù CI từng repo, không đặc thù
   agent — đây là chỗ mô hình "một spec, nhiều adapter" ít giá trị nhất.

2. **Ràng buộc "ngữ cảnh sạch" không tự cưỡng chế được ở agent không có
   subagent.** Nó lùi về một dòng hướng dẫn cho người, và người thì hay bỏ qua.

3. **Cổng chặn kiểm được *hình thức*, không kiểm được *nội dung*.** Checker biết
   mọi `YC` đều có nhãn nguồn; nó không biết nội dung yêu cầu có phản ánh đúng
   BRD hay không. Đó vẫn là việc của người — mục `exit_human` tồn tại vì vậy.
   Đừng nhầm "qua hết checker" với "làm đúng". Checker LLM thu hẹp khoảng trống
   này một phần, nhưng vì nó chỉ được chặn, những gì nó bỏ sót vẫn lọt qua.

4. **Mode 2 dựa trên nhãn rủi ro đúng.** Nhãn `Mức rủi ro` do agent đề xuất; nếu
   người duyệt ở gate spec cho qua nhãn `thường` sai, `design` sẽ chạy Mode 1 và
   hiện tượng neo quay lại.

5. **Hash cả file báo cả thay đổi vô hại.** Sửa chính tả trong `spec.md` cũng làm
   mọi artifact sau thành "lỗi thời". Đây là lý do nó chỉ cảnh báo — và cũng là
   lý do người có thể quen tay bỏ qua cảnh báo này.

6. **Tập con YAML dễ vỡ nếu ai đó viết manifest theo kiểu khác.** Trình đọc
   không báo lỗi cú pháp; nó chỉ trả về giá trị rỗng, và lỗi sẽ lộ ra muộn ở
   chỗ khác.

7. **"Duyệt" là một dòng chữ trong file.** Máy phân biệt được `đề xuất` với
   `đã duyệt`, và `tac_gia: agent` với `tac_gia: nguoi`, nhưng không biết **ai** ghi
   dòng đó. Agent vi phạm luật mà tự ghi thì checker không bắt được — chỉ `git
   blame`/review diff của `tdd.md` mới thấy.

8. **`review` không chạy lại test.** Nó đọc mã thoát trong `ket-qua-kiem-thu.md`;
   sửa code sau lần chạy `kiem-tra-hien-thuc.sh` cuối cùng thì kết quả đó đã cũ.
   Chạy lại `implement` checker trước khi review là việc của người/agent.

9. **Glob trong `conventions.md` và "File dự kiến" dùng `case` của shell**, nên
   `*` khớp cả `/` và không có `**`. `src/*` vì vậy rộng hơn người đọc tưởng.
