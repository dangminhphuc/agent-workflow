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
BRD/Jira ──▶ 01-spec ──▶ spec.md ──▶ 02-plan ──▶ plan.md ──▶ 03-implement ──▶ diff
                            │                                                   │
                            └────────────────────┬──────────────────────────────┘
                                                 ▼
                                             04-review ──▶ review.md
```

File là thứ mọi agent đều đọc và ghi được. Không cần API chung, không cần trừu
tượng hoá khả năng. Khi `02-plan` chỉ cần `spec.md` để làm việc, nó chạy được
bằng Claude Code, bằng Cursor, hay bằng một người.

Tính chất kiểm chứng được rút ra từ đó: **mỗi phase phải chạy được từ phiên
trắng.** Đây không phải khuyến nghị cho gọn — nó là phép thử xem thiết kế có
đúng không. Nếu một phase cần nhớ điều phase trước nói *trong hội thoại*, thì
quy trình chỉ chạy khi cả hai phase nằm trong cùng phiên, cùng agent, chưa bị nén
ngữ cảnh. Ràng buộc đó phá cả tính portable lẫn tính lặp lại.

Adapter vì thế chỉ làm một việc nhỏ: dịch định nghĩa phase sang dạng native cho
tiện gọi. Nếu ngày mai mọi adapter biến mất, quy trình vẫn chạy được — chỉ là
phải copy-paste nội dung phase vào chat bằng tay.

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
trong chính quá trình xây repo này, ở phase `04-review`.

### Vì sao checker tự chạy test thay vì đọc kết quả

`kiem-tra-hien-thuc.sh` tự chạy lệnh test và tự ghi output vào
`ket-qua-kiem-thu.md`. Nếu để agent chạy rồi dán kết quả vào, ta chỉ kiểm được
*cái agent nói*, không kiểm được *cái đã xảy ra*. Tự chạy thì bỏ hẳn khoảng cách
đó — agent không có chỗ nào để bịa.

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
inputs: [confluence, jira, file, brief]
outputs: [spec.md, open-questions.md]
exit_machine: [sh tools/kiem-tra-truy-vet.sh]
exit_human: [...]
needs_clean_context: true   # phải chạy được từ phiên trắng
requires_fresh_agent: true  # không được dùng chính phiên vừa làm việc trước đó
---
```

Thân file có các mục cố định: **Mục tiêu**, **Đầu vào**, **Việc phải làm**,
**Đầu ra**, **Cấm**, **Điều kiện ra**.

Mục **Cấm** không phải trang trí. Nó liệt kê việc thuộc phase khác, và là chỗ
chặn thất bại đặc trưng nhất của agent trong quy trình có phase: `01-spec` chọn
luôn giải pháp kỹ thuật, `03-implement` sửa thêm những thứ "tiện tay thấy chưa
đẹp". Cả hai đều xoá mất điểm dừng để người xem lại.

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
Đó là lý do `05-ship` thêm được sau mà không phải viết lại.

## Cách thêm một adapter

Xem `adapters/claude-code/README.md`, mục "Viết adapter mới". Điểm quan trọng
nhất: với mỗi khả năng không dịch được sang agent đích (subagent, hook, MCP),
adapter phải **ghi rõ trong output** rằng người dùng phải tự làm — không im lặng
bỏ qua. Bỏ qua âm thầm khiến quy trình *nhìn như* đang chạy đủ trong khi đã mất
một ràng buộc.

## Những chỗ thiết kế này yếu

Nói thẳng để người đọc sau khỏi phải tự phát hiện:

1. **`05-ship` chưa có nội dung.** Phát hành đặc thù CI từng repo, không đặc thù
   agent — đây là chỗ mô hình "một spec, nhiều adapter" ít giá trị nhất.

2. **Ràng buộc "ngữ cảnh sạch" không tự cưỡng chế được ở agent không có
   subagent.** Nó lùi về một dòng hướng dẫn cho người, và người thì hay bỏ qua.

3. **Cổng chặn kiểm được *hình thức*, không kiểm được *nội dung*.** Checker biết
   mọi `YC` đều có nhãn nguồn; nó không biết nội dung yêu cầu có phản ánh đúng
   BRD hay không. Đó vẫn là việc của người — mục `exit_human` tồn tại vì vậy.
   Đừng nhầm "qua hết checker" với "làm đúng".

4. **Tập con YAML dễ vỡ nếu ai đó viết manifest theo kiểu khác.** Trình đọc
   không báo lỗi cú pháp; nó chỉ trả về giá trị rỗng, và lỗi sẽ lộ ra muộn ở
   chỗ khác.
