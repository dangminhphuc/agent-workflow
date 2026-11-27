# Interface SDLC — tổng quan

Interface nói một quy trình phát triển phần mềm **phải có gì**: các bước, mỗi bước nhận gì, trả gì,
thế nào là làm đủ. Nó không nói các bước được thực hiện bằng công cụ nào. Đọc file này trước, rồi đọc
trang của từng stage (thư mục **stages**) và danh sách luật xuyên stage (**invariants.md**).

Interface **không quy định định dạng file hay nơi lưu** của artifact, cũng không quy định dấu duyệt
trông ra sao. Những thứ đó thuộc cách agent làm việc, được đặc tả riêng, ngoài interface.

## Khái niệm

| Khái niệm  | Nghĩa |
|------------|-------|
| Stage      | Một bước của quy trình. Có 8 stage, chạy theo thứ tự ở mục Luồng; job type có thể cho bỏ một số stage (job-types.md). |
| Artifact   | Thứ một stage tạo ra để stage sau dùng, ví dụ danh sách yêu cầu, thiết kế, kế hoạch. Tên viết thường, nối bằng gạch ngang, ví dụ `work-item`. Mỗi artifact ghi phiên bản của các input nó được dựng từ (`INV-005`). |
| Work item  | Một việc đã được nhận vào quy trình, kèm loại việc, điểm xuất phát và các nguồn mô tả nó: ticket (một mục trong hệ thống theo dõi công việc), tài liệu, lời người duyệt chép nguyên văn. Là artifact đầu tiên, do `plan` tạo. |
| Điểm xuất phát | Phiên bản mã nguồn mà thay đổi bắt đầu từ đó; thay đổi được so với nó. Dự án mới chưa có mã thì điểm xuất phát là "chưa có mã". |
| Thay đổi   | Phần mã nguồn việc này đổi so với điểm xuất phát, do `implement` làm ra; là artifact `change`. Thay đổi có phiên bản như mọi artifact: `verify` rà và `deploy` merge một phiên bản cụ thể. |
| Phạm vi    | Những gì work item mô tả là việc cần làm. Việc nằm ngoài đó là thêm phạm vi. |
| Yêu cầu    | Một điều mà thay đổi sắp làm phải đạt được, rút từ nguồn trong work item, hoặc từ giả định của một câu hỏi mở. Danh sách yêu cầu là artifact `requirements`. |
| Tiêu chí chấp nhận | Điều quan sát được cho biết một yêu cầu đã đạt hay chưa. |
| Câu hỏi mở | Điều các nguồn không nói mà việc cần biết; ghi kèm giả định tạm dùng và mức chặn. Danh sách câu hỏi mở là artifact `open-questions`. |
| Quyết định | Một lựa chọn trong thiết kế mà người có hiểu biết có thể chọn khác và đổi về sau thì tốn (xem trang `design`), ghi kèm vấn đề, các phương án, đánh đổi, phương án được chọn và yêu cầu nó phục vụ. Người duyệt duyệt từng quyết định. Ngoài nghĩa này, "người duyệt quyết" ở các trang dùng theo nghĩa thường. |
| Phát hiện  | Điều `verify` thấy sai hay thiếu trong thay đổi, ghi trong artifact `review-report`. Phát hiện cần sửa thành task ở `breakdown` — trực tiếp, hoặc sau khi `design` hay `require` sửa nếu nó đụng quyết định hay yêu cầu. |
| Phán quyết | Kết luận của agent rà ở `verify`, ghi trong `review-report`. Phán quyết hợp lệ cho một yêu cầu là "đạt", "đạt một phần", "không đạt", hoặc "chưa quyết" (kèm câu hỏi mở đang chờ); phán quyết merge cho cả thay đổi là "nên merge" hoặc "không nên merge". Mỗi phát hiện có mức "chặn" (phải sửa trước khi merge) hoặc "nên sửa" (người duyệt quyết sửa hay không). |
| Phiên bản (artifact) | Nội dung của một artifact tại một lúc; nội dung đổi là phiên bản mới. |
| Task       | Một phần việc nhỏ của kế hoạch, do `breakdown` tạo. Kế hoạch — danh sách task có thứ tự — là artifact `task-plan`. Mỗi task có cách chứng minh xong: thường là test máy chạy, hoặc kiểm tay khi kế hoạch ghi vậy. |
| Bằng chứng | Kết quả do máy chạy và ghi, không do agent kể: `test-evidence` (chạy test), `task-evidence` (từng task xong, bản ghi kiểm tay), `security-evidence` (quét bảo mật), và theo job type `reproduction-evidence`, `performance-evidence`. Do `implement` tạo, `verify` đọc. |
| Agent      | Trợ lý AI thực hiện các stage. |
| Người duyệt | Người chịu trách nhiệm về việc: trả lời câu hỏi mở, duyệt artifact, merge. |
| Dấu duyệt  | Bằng chứng người duyệt đã duyệt một artifact, gắn với nội dung lúc duyệt: nội dung đổi thì dấu duyệt mất hiệu lực. Người duyệt "xác nhận" một điều cụ thể (phán quyết, đường lui) là duyệt điều đó; với artifact Approval `yes`, xác nhận cũng là duyệt cả khối. |
| Merge      | Người duyệt đưa thay đổi đã duyệt vào nhánh chính — nhánh mã nguồn mà sản phẩm được xây từ đó. Agent không bao giờ merge. |
| Phát hành  | Đưa phiên bản đã merge tới môi trường chạy (ví dụ môi trường chính thức). Hệ thống triển khai bên ngoài làm việc này và báo kết quả về. |
| Đường lui  | Cách hoàn tác một bản phát hành — đưa môi trường chạy về bản trước, kể cả xử lý dữ liệu đã đổi. Người duyệt xác nhận nó ở `deploy`, trước khi merge. |
| Capability | Một điều phải đúng để coi một stage là làm đủ. Mã dạng CAP-<stage>-NN, ví dụ `CAP-require-01`. |
| Invariant  | Một luật nối nhiều stage, luôn do máy kiểm, để chuỗi artifact từ yêu cầu tới thay đổi không đứt (ví dụ: mọi yêu cầu đều có test). Mã dạng INV-NNN, ví dụ `INV-001`. Luật không đúng thì stage ở Checked at của nó chưa xong. Invariant chỉ chứa luật máy kiểm được; mọi luật xuyên stage cần người hay agent phán đều là capability của `verify`. |
| Job type   | Loại việc (tính năng mới, sửa lỗi…). Quyết định đi qua stage nào và cần bảo đảm thêm gì. Danh sách các loại nằm ở job-types.md; luật riêng của từng loại là invariant có trường Only for. |

## Luồng

```
plan ─▶ require ─▶ design ─▶ breakdown ─▶ implement ─▶ verify ─▶ deploy ─▶ operate
                                ▲                            │                  │
                                └── phát hiện cần sửa ◀──────┘                  │
         ◀──────────────── sự cố, phản hồi thành work item mới ◀────────────────┘
```

| Stage       | Một câu |
|-------------|---------|
| `plan`      | Nhận một việc vào quy trình thành work item: loại việc, nguồn, điểm xuất phát; người duyệt xác nhận. |
| `require`   | Biến work item thành yêu cầu kiểm chứng được và câu hỏi mở; người duyệt trả lời câu `blocking` và duyệt yêu cầu. |
| `design`    | Chọn cách làm; mỗi lựa chọn đáng kể là một quyết định được người duyệt duyệt. |
| `breakdown` | Chia thiết kế đã duyệt thành các task nhỏ có thứ tự, mỗi task truy về một yêu cầu hay một phát hiện. |
| `implement` | Làm lần lượt từng task; task xong khi cách chứng minh xong của nó đạt; máy chạy test, quét bảo mật và ghi bằng chứng. |
| `verify`    | Một agent không làm ra thay đổi rà nó so với yêu cầu, thiết kế, kế hoạch, cho phán quyết; người duyệt xác nhận. |
| `deploy`    | Người duyệt merge đúng phiên bản đã rà; nếu phát hành, xác nhận đường lui trước, rồi hệ thống triển khai bên ngoài đưa nó tới môi trường chạy. |
| `operate`   | Trong khoảng theo dõi, tín hiệu từ hệ thống giám sát bên ngoài thành các mục; người duyệt quyết mục nào thành việc mới. |

## Khi nào một stage xong

Một stage xong khi mọi capability của nó đạt và mọi invariant phải đúng ở stage đó đều đúng. Thứ tự:

1. Máy và agent kiểm nội dung artifact, và những điều phải đúng trước việc người làm ở bước 2 (ví dụ phiên bản sắp
   merge là phiên bản đã rà).
2. Người duyệt đọc, trả lời câu hỏi, duyệt, hoặc làm việc chỉ người được làm (như merge) — chỉ khi stage có capability `human`.
3. Máy xác nhận dấu duyệt của mọi artifact cần duyệt khớp với nội dung (`INV-001`), kiểm các capability
   `machine` về kết quả việc người làm ở bước 2, và kiểm các invariant còn lại.

Artifact cần duyệt là artifact ghi Approval `yes` ở bảng Output. Nội dung do agent viết đổi sau bước 1, kể
cả sửa theo câu trả lời của người duyệt, thì quay lại bước 1; kết quả máy ghi từ hệ thống bên ngoài (như kết
quả phát hành) không làm quay lại. Bước kiểm cuối cùng luôn do máy.

## Giá trị

| Giá trị           | Dùng ở              | Nghĩa |
|-------------------|---------------------|-------|
| `machine`         | Judged by           | Một lệnh kiểm tra tự động phán đạt hay không. |
| `agent`           | Judged by           | Một agent khác với agent đang làm việc phán. Ở `verify`, đó là chính agent rà, vì nó không làm ra thay đổi. |
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

Chữ trong backtick luôn là tên stage, tên artifact, tên job type, mã, hoặc một giá trị ở bảng trên. Trong bảng, tên artifact
hay tên stage có thể có hoặc không có backtick.

## Lý do chung

- Các stage chỉ nối nhau qua artifact, nên mỗi stage chạy được từ một phiên làm việc mới — một lần chạy
  agent không mang theo trí nhớ của lần chạy trước — bởi bất kỳ agent nào.
- Điều máy kiểm được thì máy phải kiểm; người duyệt chỉ quyết những điều máy không quyết được.
- Lõi quy trình đi tới lúc người duyệt merge (ở `deploy`); phần phát hành của `deploy` và cả `operate` chỉ là điểm nối với
  hệ thống bên ngoài: interface đòi kết quả họ báo về, không nói họ làm thế nào.

## Kịch bản xuyên suốt

Một việc `feature` nhỏ: "khoá tài khoản sau 5 lần đăng nhập sai". Mỗi dòng nhận cái các dòng trước trả.

| Stage | Nhận | Trả | Người duyệt làm gì | Nội dung ví dụ |
|---|---|---|---|---|
| `plan` | ticket từ bên ngoài | `work-item` | xác nhận loại việc, nguồn, điểm xuất phát | loại `feature`; nguồn: ticket PROJ-77; điểm xuất phát: phiên bản hiện tại của nhánh chính |
| `require` | `work-item` | `requirements`, `open-questions` | trả lời câu `blocking`, duyệt danh sách yêu cầu | yêu cầu: (1) sau 5 lần sai liên tiếp, tài khoản bị khoá; (2) khoá có thời hạn rồi tự mở; (3) người bị khoá thấy thông báo "tài khoản tạm khoá". Câu hỏi `blocking` "khoá bao lâu?", giả định 15 phút; người duyệt trả lời "30 phút", yêu cầu (2) được sửa theo rồi mới duyệt. Câu `non-blocking` "có gửi email báo khoá không?", giả định không |
| `design` | `work-item`, `requirements`, `open-questions` | `design` | duyệt từng quyết định | quyết định: lưu số lần sai trong bảng người dùng (giữ được qua lần khởi động lại) thay vì bộ nhớ đệm (nhanh hơn, mất khi khởi động lại) |
| `breakdown` | `requirements`, `design` | `task-plan` | — | task 1 đếm lần sai (yêu cầu 1); task 2 khoá và tự mở sau 30 phút (yêu cầu 2); task 3 thông báo (yêu cầu 3); mỗi task ghi phần mã được đụng và test chứng minh xong |
| `implement` | `work-item`, `requirements`, `design`, `task-plan` | `change`, `test-evidence`, `task-evidence`, `security-evidence` | — | máy chạy test trên điểm xuất phát, rồi sau từng task; mỗi yêu cầu có test ghi là kiểm nó; quét bảo mật đạt |
| `verify` | `requirements`, `open-questions`, `design`, `task-plan`, `change`, `test-evidence`, `task-evidence`, `security-evidence` | `review-report` | xác nhận phán quyết | lượt 1: 3 yêu cầu "đạt"; một phát hiện "nên sửa": thông báo cho biết tài khoản có tồn tại. Người duyệt chọn sửa → `breakdown` nhận `review-report`, nối task 4 → `implement` → `verify` lượt 2: "nên merge", người duyệt xác nhận |
| `deploy` | `change`, `review-report` | `delivery` | xác nhận đường lui, merge | đường lui: quay về bản trước; cột số lần sai thêm vào bảng được giữ, bản trước không đọc nó. Hệ thống triển khai báo phát hành đạt |
| `operate` | `delivery`, `requirements` | `operational-feedback` | quyết từng mục | khoảng theo dõi 7 ngày; số tài khoản bị khoá tăng gấp mười ở một khách hàng dùng công cụ tự động đăng nhập → mục; người duyệt quyết thành việc mới → `plan` |
