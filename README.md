# agent-workflow

Quy trình phát triển phần mềm dựa trên AI agent, **không phụ thuộc vào một agent cụ thể**.

Repo này là *nguồn*. Bạn cài nó vào repo dự án thật, nó sinh ra artifact riêng cho
agent bạn đang dùng. Hiện có adapter cho **Claude Code**; Cursor và Copilot đã có
khe cắm trong manifest nhưng chưa hiện thực.

## Ý tưởng cốt lõi

Tính không-phụ-thuộc-agent **không đến từ lớp trừu tượng hoá API**. Nó đến từ một
quy ước đơn giản hơn nhiều:

> Mỗi phase nhận đầu vào là **file** do phase trước ghi ra, không phải ngữ cảnh hội thoại.

Agent nào cũng đọc và ghi được file. Khi `02-plan` chỉ cần `spec.md` để làm việc,
nó chạy được bằng Claude Code, bằng Cursor, bằng một người, hay bằng một phiên
mới sau khi phiên cũ đã bị nén ngữ cảnh. Adapter chỉ làm một việc: dịch định
nghĩa phase sang dạng native của từng agent cho tiện gọi.

Hệ quả kiểm chứng được: **mỗi phase phải chạy được từ một phiên trắng.** Nếu một
phase không chạy nổi khi mở phiên mới, phase trước đã ghi thiếu.

## Các phase

```
00-ideation   [tuỳ chọn]  chỉ khi KHÔNG có BRD/PRD/ticket  →  brief.md
01-spec       [bắt buộc]  BRD/PRD/Jira/Confluence          →  spec.md + open-questions.md
02-plan       [bắt buộc]  spec.md                          →  plan.md
03-implement  [bắt buộc]  plan.md                          →  diff + ket-qua-kiem-thu.md
04-review     [bắt buộc]  spec.md + plan.md + diff         →  review.md
05-ship       [khe trống] chưa hiện thực — xem ghi chú bên dưới
```

Không có phase `test` riêng. Test là **điều kiện ra** của `03-implement`: chưa
xanh nghĩa là chưa xong. Một phase test đặt phía sau sẽ biến "code xong" thành
trạng thái hợp lệ dù chưa ai chạy gì.

## Cài vào một repo

```sh
sh tools/cai-dat.sh /đường/dẫn/repo-của-bạn --lenh-kiem-thu "npm test"
```

Sinh ra trong repo đích:

```
.claude/
  commands/{ideation,spec,plan,implement,review}.md
  agents/ra-soat-doc-lap.md
  skills/quy-trinh-agent/SKILL.md
.agent-workflow/
  .quy-trinh/{rules,templates,tools,cau-hinh.sh}   ← bộ cài, cài lại sẽ ghi đè
  (spec.md, plan.md, review.md, ...)               ← artifact, commit vào git
```

Rồi mở Claude Code trong repo đích: `/spec` → `/plan` → `/implement` → `/review`.

Cài lại sau khi sửa quy trình: chạy lại đúng lệnh trên. Adapter **từ chối ghi đè**
file bạn viết tay (file do nó sinh ra đều mang dấu "SINH TỰ ĐỘNG"); dùng `--force`
nếu thật sự muốn mất nội dung cũ.

## Cổng chặn bằng máy

Điều kiện ra chia hai loại. Loại **NGƯỜI** thì agent nêu ra rồi dừng. Loại **MÁY**
thì agent không được tự tuyên bố đạt — phải chạy lệnh:

| Phase | Lệnh | Bắt cái gì |
|---|---|---|
| `01-spec` | `kiem-tra-truy-vet.sh` | Yêu cầu không truy được về nguồn → agent bịa yêu cầu |
| `02-plan` | `kiem-tra-ke-hoach.sh` | Task thừa, và **yêu cầu bị bỏ sót** (kiểm hai chiều) |
| `03-implement` | `kiem-tra-hien-thuc.sh` | Test chưa xanh, task còn dở |
| `04-review` | `kiem-tra-ra-soat.sh` | Bỏ sót yêu cầu khi rà, kết luận "đạt" cho giả định chưa xác nhận |

`kiem-tra-hien-thuc.sh` **tự chạy lệnh test và tự ghi output** vào
`ket-qua-kiem-thu.md`. Agent không có cơ hội viết lại kết quả bằng lời hay bịa
một dòng "tất cả test đã xanh".

Adapter cũng tự từ chối build nếu một mục `exit_machine` không phải lệnh chạy
được — nếu không, điều kiện loại NGƯỜI sẽ đội lốt loại MÁY và agent sẽ tự duyệt.

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

## Vì sao `05-ship` để trống

Nội dung của nó gần như hoàn toàn là đặc thù **hạ tầng CI của từng repo**
(GitHub Actions / GitLab CI / Jenkins), chứ không phải đặc thù agent. Viết bây
giờ thì spec trung lập sẽ đầy nhánh điều kiện cho những hạ tầng chưa biết.

Đây là chỗ tính không-phụ-thuộc-agent yếu nhất trong cả quy trình — đáng thừa
nhận thẳng hơn là che bằng một lớp trừu tượng hoá đoán mò. Thêm sau chỉ cần viết
nội dung `workflow/phases/05-ship.md` và đổi `status` trong manifest; không phase
nào khác phải sửa, vì không phase nào biết gì về phase đứng sau nó.

## Chạy test

```sh
sh tools/chay-thu.sh
```
