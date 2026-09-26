# agent-workflow

Quy trình phát triển phần mềm dựa trên AI agent, **không phụ thuộc vào một agent cụ thể**.

Repo này là *nguồn*. Bạn cài nó vào repo dự án thật, nó sinh ra artifact riêng cho
agent bạn đang dùng. Hiện có adapter cho **Claude Code**; Cursor và Copilot đã có
khe cắm trong manifest nhưng chưa hiện thực.

## Ý tưởng cốt lõi

Tính không-phụ-thuộc-agent **không đến từ lớp trừu tượng hoá API**. Nó đến từ một
quy ước đơn giản hơn nhiều:

> Mỗi phase là một hộp **file vào → file ra**, không dựa vào ngữ cảnh hội thoại.

Agent nào cũng đọc và ghi được file. Vì vậy mỗi phase chạy được bằng Claude Code,
bằng Cursor, bằng một người, hay bằng một phiên mới sau khi phiên cũ đã bị nén
ngữ cảnh. Adapter chỉ làm một việc: dịch định nghĩa phase sang dạng native của
từng agent cho tiện gọi.

Hệ quả kiểm chứng được: **mỗi phase phải chạy được từ một phiên trắng.** Nếu một
phase không chạy nổi khi mở phiên mới, phase trước đã ghi thiếu.

Hệ quả thứ hai: **vào quy trình ở phase nào cũng được.** Artifact có thể được tạo
bằng tool bất kỳ — AI khác, Confluence, viết tay — rồi đưa vào đúng phase cần.
Điều kiện: nó vẫn phải qua checker và gate người của phase lẽ ra đã sinh ra nó
(xem [Đưa artifact từ ngoài vào](#đưa-artifact-từ-ngoài-vào)).

Nền tảng gồm bốn nguyên tắc:

1. **Bàn giao bằng file** — không phase nào biết gì về phase đứng sau nó.
2. **Trung lập agent** — phần lõi nằm trong file, mẫu và script, không nằm trong prompt.
3. **Agent không tự duyệt** — điều gì máy kiểm được thì máy kiểm; còn lại người quyết.
4. **Flow không tắc** — chỉ chặn khi checker chính xác; kiểm chéo hay báo nhầm thì
   cảnh báo, `review` là cổng chặn cuối.

Và một lớp quản trị quyết định: các quyết định kỹ thuật được tách thành mục
**D-xx** riêng, để người duyệt *quyết định* chứ không phải đọc duyệt cả một bài
văn xuôi.

## Các phase

```mermaid
flowchart TD
    START{"Có BRD / PRD /<br/>Jira / Confluence / incident?"}
    IDEA["00-ideation · tuỳ chọn<br/>→ brief.md<br/><i>NGƯỜI: duyệt brief</i>"]
    SPEC["01-spec<br/>→ spec.md + open-questions.md<br/><i>MÁY: kiem-tra-truy-vet.sh</i><br/><i>NGƯỜI: duyệt YC, mức ảnh hưởng, Mức rủi ro</i>"]
    PHAC[/"Người phác D-xx trước<br/>(bắt buộc khi Mức rủi ro: cao)"/]
    DESIGN["02-design<br/>→ tdd.md (quyết định D-xx)<br/><i>MÁY: checker LLM — chỉ chặn</i><br/><i>NGƯỜI: duyệt từng D-xx</i>"]
    PLAN["03-plan<br/>→ plan.md<br/><i>MÁY: kiem-tra-ke-hoach.sh</i>"]
    IMPL["04-implement<br/>→ diff + ket-qua-kiem-thu.md<br/><i>MÁY: kiem-tra-hien-thuc.sh (tự chạy test)</i>"]
    REVIEW["05-review · ngữ cảnh trắng<br/>đọc mọi artifact + diff → review.md<br/><i>MÁY: kiem-tra-ra-soat.sh</i><br/><i>NGƯỜI: xác nhận kết luận</i>"]
    SHIP["06-ship · tuỳ chọn"]

    NGOAI[/"Artifact làm bằng tool khác<br/>(AI khác, Confluence, viết tay)"/]
    IMPORT["Import có kiểm soát<br/>lệnh riêng, không thêm nội dung"]

    START -- có --> SPEC
    START -- không --> IDEA --> SPEC
    SPEC --> DESIGN
    PHAC -.-> DESIGN
    DESIGN --> PLAN --> IMPL --> REVIEW --> SHIP

    IMPL -. "cảnh báo dồn về: artifact lỗi thời,<br/>test ↔ YC, phạm vi diff" .-> REVIEW

    NGOAI --> IMPORT
    IMPORT -. "vào giữa chừng" .-> SPEC
    IMPORT -. "vào giữa chừng" .-> DESIGN
    IMPORT -. "vào giữa chừng" .-> PLAN

    classDef nguoi stroke-width:3px
    classDef tuychon stroke-dasharray:5 5
    class IDEA,SPEC,DESIGN,REVIEW nguoi
    class SHIP tuychon
```

Cách đọc:

- **Viền đậm** = phase có gate **NGƯỜI**. `plan` và `implement` không có người —
  chúng chỉ thực thi những gì đã duyệt ở `spec` và `design`.
- **MÁY** = lệnh phải chạy xanh trước khi agent được nói "xong". Lệnh fail thì
  quay lại sửa trong chính phase đó.
- **Mũi tên nét đứt "cảnh báo"** = kiểm chéo giữa phase: không chặn giữa chừng,
  nhưng dồn về `review` — cổng chặn cuối — và chưa xử lý thì `review` chặn.
- **"Vào giữa chừng"** = artifact từ tool khác, sau khi import, vẫn phải qua
  checker và gate người của phase lẽ ra đã sinh ra nó.

```
00-ideation   [tuỳ chọn]  chỉ khi KHÔNG có BRD/PRD/ticket     →  brief.md
01-spec       [bắt buộc]  BRD/PRD/Jira/Confluence/incident   →  spec.md + open-questions.md
02-design     [bắt buộc]  spec.md                            →  tdd.md
03-plan       [bắt buộc]  spec.md + tdd.md                   →  plan.md
04-implement  [bắt buộc]  plan.md + tdd.md                   →  diff + ket-qua-kiem-thu.md
05-review     [bắt buộc]  mọi artifact + diff                →  review.md
06-ship       [tuỳ chọn]  phụ thuộc hạ tầng CI của repo đích
```

- **Không có phase test riêng.** Test là **điều kiện ra** của `implement`: chưa
  xanh nghĩa là chưa xong. Một phase test đặt phía sau sẽ biến "code xong" thành
  trạng thái hợp lệ dù chưa ai chạy gì.
- **Vận hành không phải phase.** Incident note là một loại nguồn đầu vào của `spec`.

### Người tham gia ở đâu

| Phase | Người | Người làm gì |
|---|---|---|
| `ideation` | có | Duyệt `brief.md` |
| `spec` | có | Duyệt yêu cầu, nhãn mức ảnh hưởng của `[CẦN-HỎI]`, và `Mức rủi ro` |
| `design` | có | Duyệt **từng D-xx** trong `tdd.md` |
| `plan` | không | — |
| `implement` | không | — |
| `review` | có | Xác nhận kết luận; làm trọng tài cho phát hiện của checker |
| `ship` | có | Tuỳ hạ tầng |

`plan` và `implement` không có người vì chúng chỉ thực thi những gì đã được duyệt
ở `spec` và `design`.

### `01-spec` — yêu cầu

Mỗi yêu cầu `YC-xxx` phải truy được về tài liệu nguồn (Confluence, Jira, file cục
bộ). Chỗ chưa rõ ghi `[CẦN-HỎI]` kèm **mức ảnh hưởng** do agent đề xuất, người
duyệt ở gate spec. Mặc định **không chặn** — chỉ mục ảnh hưởng toàn bộ thiết kế
mới phải được trả lời trước khi vào `design`. Mục còn mở thì `review` không được
kết luận "đạt".

Spec cũng gắn `Mức rủi ro: cao | thường`. **Cao** khi đụng tiền/hạch toán, tích
hợp mới, schema lõi, hoặc thay đổi khó đảo ngược.

### `02-design` — Technical Design Document

Output duy nhất: `tdd.md` (Technical Design Document, **không phải** Test-Driven
Development). Nó chứa mọi thông tin `implement` cần để làm đúng kỹ thuật:

- Bối cảnh code hiện có
- **Quyết định D-xx** — người duyệt từng mục; mục này được phép rỗng
- Mô hình dữ liệu + ERD
- Contract / API
- Flow, sequence, state (Mermaid)
- Yêu cầu phi chức năng
- Chiến lược test
- Ánh xạ YC → mục thiết kế

Mục không áp dụng ghi `Không áp dụng: <lý do>` chứ không bỏ trống. Mục chi tiết
ghi `Dựa trên: D-xx`; checker LLM tìm chỗ lệch D-xx và các quyết định ngầm chưa
được nêu thành D.

Hai cách làm:

- **Mode 1** — agent viết cả `tdd.md` một lần, người duyệt.
- **Mode 2** — người phác các mục D-xx trước (`tac_gia: nguoi`), agent viết phần
  còn lại và chỉ **phản biện** quyết định của người. Spec có `Mức rủi ro: cao` mà
  chưa có bản phác của người thì `design` chặn — để tránh người duyệt bị neo vào
  phương án agent đưa ra.

**Mở lại quyết định:** mở lại đúng một D-xx, sửa tại chỗ (lịch sử để git giữ), ghi
trạng thái `mở lại` + lý do. Grep `Dựa trên: D-xx` ra các task bị ảnh hưởng, chỉ
các task đó đặt lại `[ ]`; người chỉ duyệt lại D đang mở.

### `03-plan` — quản lý thực thi

`plan.md` chỉ còn phần thực thi: task, thứ tự/phụ thuộc, `Phủ: YC-xxx`,
`Dựa trên: D-xx`, `Theo: tdd.md § …`, File dự kiến, Cách kiểm chứng, task dựa
trên giả định, trạng thái, Phát sinh, Hoãn lại. Nó tách khỏi `tdd.md` để việc
tick task không bao giờ sửa vào tài liệu thiết kế đã duyệt.

### `04-implement` — code + test

- Test gắn tag `covers: YC-xxx`. YC chưa có test → **cảnh báo**. YC không test tự
  động được ghi `Kiểm chứng: thủ công` + lý do.
- So `git diff --name-only <nhánh-gốc>...HEAD` với "File dự kiến" (cho phép glob)
  và "Phát sinh" của plan. File ngoài phạm vi → **cảnh báo**.

### `05-review` — rà soát độc lập

Chạy bằng phiên/subagent có ngữ cảnh trắng, không phải phiên vừa viết code. Đây
là **cổng chặn cuối**: mọi cảnh báo từ phase trước (artifact lỗi thời, YC chưa có
test, diff ngoài phạm vi) chưa xử lý thì `review` chặn.

## Cổng chặn

Điều kiện ra chia hai loại. Loại **NGƯỜI** thì agent nêu ra rồi dừng. Loại **MÁY**
thì agent không được tự tuyên bố đạt — phải chạy lệnh:

| Phase | Lệnh | Bắt cái gì |
|---|---|---|
| `spec` | `kiem-tra-truy-vet.sh` | Yêu cầu không truy được về nguồn → agent bịa yêu cầu |
| `design` | checker LLM | Lệch D-xx, quyết định ngầm, YC chưa được ánh xạ |
| `plan` | `kiem-tra-ke-hoach.sh` | Task thừa, và **yêu cầu bị bỏ sót** (kiểm hai chiều) |
| `implement` | `kiem-tra-hien-thuc.sh` | Test chưa xanh, task còn dở |
| `review` | `kiem-tra-ra-soat.sh` | Bỏ sót yêu cầu, kết luận "đạt" khi còn giả định chưa xác nhận hoặc cảnh báo chưa xử lý |

`kiem-tra-hien-thuc.sh` **tự chạy lệnh test và tự ghi output** vào
`ket-qua-kiem-thu.md`. Agent không có cơ hội viết lại kết quả bằng lời hay bịa
một dòng "tất cả test đã xanh".

Adapter tự từ chối build nếu một mục `exit_machine` không phải lệnh chạy được —
nếu không, điều kiện loại NGƯỜI sẽ đội lốt loại MÁY và agent sẽ tự duyệt.

### Chặn hay cảnh báo

| Loại checker | Ví dụ | Hành vi |
|---|---|---|
| **Chính xác** — hợp đồng output của chính phase | truy vết nguồn, phủ YC, test xanh | **Chặn** |
| **Kiểm chéo giữa phase**, hay báo nhầm | artifact lỗi thời, test ↔ YC, phạm vi diff | **Cảnh báo**; `review` chặn |

Tiêu chí xếp một checker mới: độ chính xác, chi phí nếu lọt, và nơi sửa rẻ nhất.

### Checker LLM: chỉ được chặn, không được duyệt

Checker dùng LLM ghi phát hiện ra file; script fail nếu còn mục `Chặn` chưa xử
lý. Người là **trọng tài theo ngoại lệ**: xác nhận, hoặc bác bỏ kèm lý do. LLM
không bao giờ là bên nói "đạt".

### Artifact lỗi thời

Mỗi artifact ghi `based_on` là hash **cả file** của đầu vào:

```
based_on:
  - spec.md@<hash>
```

Lệch hash chỉ **cảnh báo** ở các phase sau; `review` chặn nếu còn artifact lỗi thời.

## Đưa artifact từ ngoài vào

Artifact làm bằng tool khác thường không đúng mẫu. Nó đi qua **bước import có
kiểm soát** — một lệnh riêng, không phải phase:

- Chỉ sắp xếp lại theo mẫu, **không thêm nội dung**.
- Gắn nhãn nguồn trỏ về tài liệu gốc; chỗ không rõ ghi `[CẦN-HỎI]`.
- Kết quả chạy qua checker của phase tương ứng, và người xác nhận bản chuyển đổi.

Entry check của phase N chính là checker của phase N-1 chạy lại trên input, nên
không có đường tắt nào bỏ qua cổng chặn.

## Cài vào một repo

```sh
sh tools/cai-dat.sh /đường/dẫn/repo-của-bạn --lenh-kiem-thu "npm test"
```

Sinh ra trong repo đích:

```
.claude/
  commands/{ideation,spec,design,plan,implement,review}.md
  agents/ra-soat-doc-lap.md
  skills/quy-trinh-agent/SKILL.md
.agent-workflow/
  .quy-trinh/{rules,templates,tools,cau-hinh.sh}   ← bộ cài, cài lại sẽ ghi đè
  conventions.md                                   ← bạn viết; bộ cài chỉ tạo mẫu, không ghi đè
  <tên-branch>/                                    ← artifact của từng feature, commit vào git
    spec.md, open-questions.md, tdd.md, plan.md,
    ket-qua-kiem-thu.md, review.md, ...
```

Rồi mở Claude Code trong repo đích:
`/spec` → `/design` → `/plan` → `/implement` → `/review`.

Cài lại sau khi sửa quy trình: chạy lại đúng lệnh trên. Adapter **từ chối ghi đè**
file bạn viết tay (file do nó sinh ra đều mang dấu "SINH TỰ ĐỘNG"); dùng `--force`
nếu thật sự muốn mất nội dung cũ.

### Artifact theo feature và `conventions.md`

Artifact của mỗi feature nằm trong `.agent-workflow/<tên-branch>/`, dùng **tên
branch đầy đủ** (vd `feat_tao-todo`) để feat và refactor cùng tên không đè nhau.

Cách xác định feature đang làm:

1. Suy từ tên branch hiện tại theo quy ước trong `conventions.md`;
2. không khớp thì lấy tham số của lệnh;
3. không có tham số thì dừng lại hỏi.

Agent luôn in `Đang làm với: …` trước khi bắt đầu.

`conventions.md` là của repo đích, do bạn viết, và khai:

- quy ước tên branch (`feat_xxx`, `refactor_xxx`… — `xxx` không nhất thiết là mã Jira);
- nhánh gốc để so diff, và danh sách file bỏ qua;
- mẫu file test và cú pháp tag `covers:`.

Phần máy đọc của file này phải parse được bằng sh/awk.

## Cấu trúc repo

```
workflow.yaml            manifest trung lập — nguồn sự thật duy nhất
workflow/
  phases/*.md            định nghĩa phase (frontmatter + mô tả)
  rules/*.md             luật áp dụng cho mọi phase
  templates/*.md         mẫu cho từng artifact
adapters/
  claude-code/build.sh   biên dịch sang .claude/**
tools/
  cai-dat.sh             cài vào repo đích
  kiem-tra-*.sh          các cổng chặn bằng máy
  chay-thu.sh            test hồi quy cho chính các cổng chặn
  lib/md.sh              đọc frontmatter (tập con YAML)
docs/kien-truc.md        vì sao thiết kế như vậy, cách thêm phase/adapter
```

## Yêu cầu môi trường

POSIX shell + `awk` + `sed`. Không cần Node, Python, hay cài đặt gì thêm.
Trên Windows dùng Git Bash (Claude Code có sẵn Bash trên mọi nền tảng).

## Vì sao `06-ship` để tuỳ chọn

Nội dung của nó gần như hoàn toàn là đặc thù **hạ tầng CI của từng repo**
(GitHub Actions / GitLab CI / Jenkins), chứ không phải đặc thù agent. Viết chung
thì spec trung lập sẽ đầy nhánh điều kiện cho những hạ tầng chưa biết.

Đây là chỗ tính không-phụ-thuộc-agent yếu nhất trong cả quy trình — đáng thừa
nhận thẳng hơn là che bằng một lớp trừu tượng hoá đoán mò. Thêm sau chỉ cần viết
nội dung `workflow/phases/06-ship.md` và đổi `status` trong manifest; không phase
nào khác phải sửa, vì không phase nào biết gì về phase đứng sau nó.

## Chạy test

```sh
sh tools/chay-thu.sh
```
