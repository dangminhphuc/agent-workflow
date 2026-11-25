# Interface SDLC — tổng quan

Interface nói một quy trình phát triển phần mềm **phải có gì**: các bước, mỗi bước nhận gì, trả gì,
thế nào là làm đủ. Nó không nói các bước được thực hiện bằng công cụ nào. Đọc file này trước, rồi đọc
trang của từng stage (thư mục **stages**) và danh sách luật xuyên stage (**invariants.md**).

Interface **không quy định định dạng file hay nơi lưu** của artifact, cũng không quy định dấu duyệt
trông ra sao. Những thứ đó thuộc cách agent làm việc, được đặc tả riêng, ngoài interface.

## Khái niệm

| Khái niệm  | Nghĩa |
|------------|-------|
| Stage      | Một bước của quy trình. Có 8 stage, chạy theo thứ tự ở mục Luồng. |
| Artifact   | Thứ một stage tạo ra để stage sau dùng, ví dụ danh sách yêu cầu, thiết kế, kế hoạch. Tên viết thường, nối bằng gạch ngang, ví dụ `work-item`. |
| Work item  | Một việc đã được nhận vào quy trình, kèm các nguồn mô tả nó: ticket (một mục trong hệ thống theo dõi công việc), tài liệu, lời người duyệt chép nguyên văn. Là artifact đầu tiên, do `plan` tạo. |
| Điểm xuất phát | Phiên bản mã nguồn mà thay đổi bắt đầu từ đó; thay đổi được so với nó. Dự án mới chưa có mã thì điểm xuất phát là "chưa có mã". |
| Phạm vi    | Những gì work item mô tả là việc cần làm. Việc nằm ngoài đó là thêm phạm vi. |
| Yêu cầu    | Một điều mà thay đổi sắp làm phải đạt được, rút từ nguồn trong work item, hoặc từ giả định của một câu hỏi mở. |
| Tiêu chí chấp nhận | Điều quan sát được cho biết một yêu cầu đã đạt hay chưa. |
| Câu hỏi mở | Điều các nguồn không nói mà việc cần biết; ghi kèm giả định tạm dùng và mức chặn. |
| Task       | Một phần việc nhỏ của kế hoạch, do `breakdown` tạo. |
| Agent      | Trợ lý AI thực hiện các stage. |
| Người duyệt | Người chịu trách nhiệm về việc: trả lời câu hỏi mở, duyệt artifact, merge. |
| Dấu duyệt  | Bằng chứng người duyệt đã duyệt một artifact, gắn với nội dung lúc duyệt: nội dung đổi thì dấu duyệt mất hiệu lực. |
| Merge      | Người duyệt đưa thay đổi đã duyệt vào nhánh chính — nhánh mã nguồn mà sản phẩm được xây từ đó. Agent không bao giờ merge. |
| Capability | Một điều phải đúng để coi một stage là làm đủ. Mã dạng CAP-<stage>-NN, ví dụ `CAP-require-01`. |
| Invariant  | Một luật nối nhiều stage, luôn do máy kiểm, để chuỗi artifact từ yêu cầu tới thay đổi không đứt (ví dụ: mọi yêu cầu đều có test). Mã dạng INV-NNN, ví dụ `INV-001`. Luật xuyên stage cần người hay agent phán thì viết thành capability của `verify`. |
| Job type   | Loại việc (tính năng mới, sửa lỗi…). Quyết định đi qua stage nào và cần bảo đảm thêm gì. Danh sách các loại và luật của từng loại nằm ở file job-types (chưa viết). |

## Luồng

```
plan ─▶ require ─▶ design ─▶ breakdown ─▶ implement ─▶ verify ─▶ deploy ─▶ operate
                                                                              │
         ◀──────────────── sự cố, phản hồi thành work item mới ◀──────────────┘
```

| Stage       | Một câu |
|-------------|---------|
| `plan`      | Nhận một việc vào quy trình thành work item. |
| `require`   | Biến work item thành yêu cầu kiểm chứng được và câu hỏi mở. |
| `design`    | Chọn cách làm; mỗi lựa chọn là một quyết định được người duyệt duyệt. |
| `breakdown` | Chia thiết kế thành các task nhỏ có thứ tự. |
| `implement` | Làm từng task; task xong khi test đạt. |
| `verify`    | Kiểm tra độc lập thay đổi so với yêu cầu, thiết kế, kế hoạch. |
| `deploy`    | Đưa thay đổi đã merge tới nơi chạy (điểm nối với hệ thống triển khai bên ngoài). |
| `operate`   | Vận hành và đưa phản hồi về thành việc mới (điểm nối với hệ thống giám sát bên ngoài). |

## Khi nào một stage xong

Một stage xong khi mọi capability của nó đạt và mọi invariant phải đúng ở stage đó đều đúng. Thứ tự:

1. Máy và agent kiểm nội dung artifact.
2. Người duyệt đọc, trả lời câu hỏi, duyệt — chỉ khi stage có capability `human`.
3. Máy xác nhận dấu duyệt của mọi artifact cần duyệt khớp với nội dung (`INV-001`) và kiểm các
   invariant còn lại.

Artifact cần duyệt là artifact ghi Approval `yes` ở bảng Output. Nội dung artifact đổi sau bước 1, kể cả
sửa theo câu trả lời của người duyệt, thì quay lại bước 1. Bước kiểm cuối cùng luôn do máy.

## Giá trị

| Giá trị           | Dùng ở              | Nghĩa |
|-------------------|---------------------|-------|
| `machine`         | Judged by           | Một lệnh kiểm tra tự động phán đạt hay không. |
| `agent`           | Judged by           | Một agent khác với agent đang làm việc phán. |
| `human`           | Judged by           | Người duyệt phán. |
| `yes` / `no`      | Required (Input)    | Input bắt buộc hay không. |
| `yes` / `no`      | Approval (Output)   | Artifact có được người duyệt duyệt cả khối, kèm dấu duyệt, hay không. `no` không có nghĩa người duyệt không đụng tới: một capability `human` có thể đòi người duyệt từng phần (ví dụ trả lời từng câu hỏi mở). |
| `all`             | Checked at (invariant) | Luật phải đúng khi kết thúc mọi stage. |
| `blocking`        | Mức chặn câu hỏi mở | Người duyệt phải trả lời trước khi `require` xong. |
| `review-blocking` | Mức chặn câu hỏi mở | Người duyệt phải trả lời trước khi `verify` xong, tức trước khi merge (`INV-002`). |
| `non-blocking`    | Mức chặn câu hỏi mở | Việc được làm tiếp và merge trên giả định đã ghi; trả lời lúc nào cũng được. |

## Cách đọc một trang stage

Mỗi trang có 6 mục theo thứ tự:

- **Definition** — là gì, vì sao cần.
- **Input** — bảng: artifact, bắt buộc hay không (Required), dùng để làm gì (Used for).
- **Output** — bảng: artifact, có cần duyệt không (Approval), mô tả.
- **Capabilities** — mỗi capability có: **Rule** (điều phải đúng), **Judged by** (ai phán), **Artifact**
  (artifact nó bảo đảm), **Fail example** (một ví dụ làm sai), **Pass example** (ví dụ làm đúng, không bắt buộc).
- **Not in this stage** — việc dễ tưởng thuộc stage này nhưng không phải.
- **Rationale** — các lựa chọn đã loại và vì sao.

Stage xong khi nào thì đọc ở mục "Khi nào một stage xong" phía trên: mỗi capability đã ghi ai phán nó.

Chữ trong backtick luôn là tên stage, tên artifact, mã, hoặc một giá trị ở bảng trên. Trong bảng, tên artifact
hay tên stage có thể có hoặc không có backtick.

## Lý do chung

- Các stage chỉ nối nhau qua artifact, nên mỗi stage chạy được từ một phiên làm việc mới — một lần chạy
  agent không mang theo trí nhớ của lần chạy trước — bởi bất kỳ agent nào.
- Điều máy kiểm được thì máy phải kiểm; người duyệt chỉ quyết những điều máy không quyết được.
- Lõi quy trình đi tới lúc người duyệt merge; `deploy` và `operate` chỉ là điểm nối với hệ thống bên ngoài.

## Kịch bản xuyên suốt

*Viết khi đủ 8 trang stage.*
