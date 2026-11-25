# Interface SDLC — tổng quan

Interface nói một quy trình phát triển phần mềm **phải có gì**: các bước, mỗi bước nhận gì, trả gì,
thế nào là làm đủ. Nó không nói engine làm thế nào. Đọc file này trước, rồi đọc trang của từng stage
trong `stages/`.

Interface **không quy định định dạng file hay nơi lưu** của artifact, cũng không quy định dấu duyệt
trông ra sao. Những thứ đó thuộc mô hình làm việc của agent, nằm ngoài interface.

## Khái niệm

| Khái niệm  | Nghĩa |
|------------|-------|
| Stage      | Một bước của quy trình. Có 8 stage, chạy theo thứ tự ở mục Luồng. |
| Artifact   | Thứ một stage tạo ra để stage sau dùng, ví dụ danh sách yêu cầu, thiết kế, kế hoạch. Mỗi artifact có tên viết thường, nối bằng gạch ngang, ví dụ `work-item`. |
| Work item  | Một việc đã được nhận vào quy trình, kèm các nguồn mô tả nó (ticket, tài liệu, lời người). Là artifact đầu tiên, do `plan` tạo. |
| Capability | Một điều phải đúng để coi một stage là làm đủ. Mã `CAP-<stage>-NN`, ví dụ `CAP-require-01`. Mỗi capability có một ví dụ làm sai cụ thể. |
| Invariant  | Một luật nối nhiều stage, luôn do máy kiểm, để chuỗi không đứt (ví dụ: mọi yêu cầu đều có test). Mã `INV-NNN`. Luật xuyên stage cần người hay agent phán thì viết thành capability của `verify`. |
| Job type   | Loại việc (tính năng mới, sửa lỗi…). Quyết định đi qua stage nào và cần bảo đảm thêm gì. |
| Dấu duyệt  | Bằng chứng người đã duyệt một artifact, gắn với nội dung lúc duyệt: nội dung đổi thì dấu duyệt mất hiệu lực. |
| Merge      | Người đưa thay đổi đã duyệt vào nhánh chính. Agent không bao giờ merge. |

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
| `design`    | Chọn cách làm; mỗi lựa chọn là một quyết định người duyệt. |
| `breakdown` | Chia thiết kế thành các task nhỏ có thứ tự. |
| `implement` | Làm từng task; task xong khi test đạt. |
| `verify`    | Kiểm tra độc lập thay đổi so với yêu cầu, thiết kế, kế hoạch. |
| `deploy`    | Đưa thay đổi đã merge tới nơi chạy (điểm nối với CI/CD bên ngoài). |
| `operate`   | Vận hành và đưa phản hồi về thành việc mới (điểm nối với hệ thống giám sát bên ngoài). |

## Ai cho stage kết thúc

Mỗi capability ghi ai phán nó đạt (`Judged by`). Một stage có capability của máy thì máy kiểm **trước**;
có capability của người thì người duyệt **sau** khi máy đạt. Stage xong khi mọi capability của nó đạt.

## Giá trị

| Giá trị           | Dùng ở           | Nghĩa |
|-------------------|------------------|-------|
| `machine`         | Judged by        | Một lệnh kiểm tra tự động phán đạt hay không. |
| `agent`           | Judged by        | Một agent khác với agent đang làm việc phán. |
| `human`           | Judged by        | Người phán. |
| `yes` / `no`      | Required (Input) | Input bắt buộc hay không. |
| `blocking`        | Mức chặn câu hỏi mở | Người phải trả lời trước khi `design` bắt đầu. |
| `review-blocking` | Mức chặn câu hỏi mở | Người phải trả lời trước khi merge. |
| `non-blocking`    | Mức chặn câu hỏi mở | Được giao trên giả định đã ghi; trả lời lúc nào cũng được. |

## Cách đọc một trang stage

Mỗi trang có 7 mục theo thứ tự: Definition (là gì, vì sao cần) · Input · Output · Exit (xong khi nào) ·
Capabilities (làm đủ là gì, kèm ví dụ làm sai) · Not in this stage (ranh giới) · Rationale (các lựa chọn
đã loại và vì sao). Chữ trong backtick luôn là tên stage, tên artifact, mã, hoặc một giá trị ở bảng trên.

## Lý do chung

- Các stage chỉ nối nhau qua artifact, nên mỗi stage chạy được từ một phiên làm việc mới, bởi bất kỳ agent nào.
- Điều máy kiểm được thì máy phải kiểm; người chỉ quyết những điều máy không quyết được.
- Lõi quy trình đi tới lúc người merge; `deploy` và `operate` chỉ là điểm nối với hệ thống bên ngoài.

## Kịch bản xuyên suốt

*Viết khi đủ 8 trang stage.*
