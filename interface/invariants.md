# Invariants

Luật nối nhiều stage, luôn do máy kiểm. Mỗi luật có các trường:

- **Rule** — điều phải đúng.
- **Checked at** — phải đúng khi kết thúc stage nào.
- **Warned from** — không bắt buộc: từ stage này trở đi, vi phạm được báo nhưng không chặn, để sửa sớm khi còn rẻ; tới stage ở Checked at thì chặn.
- **Only for** — không bắt buộc: chỉ áp cho job type nào. Không có trường này = áp cho mọi loại việc.
- **Fail example** — một ví dụ vi phạm.
- **Why** — vì sao cần.

### INV-001 — Chỉ dùng artifact đã duyệt và chưa bị sửa sau khi duyệt
- Rule: mọi artifact đã có, ghi Approval `yes` ở bảng Output của stage tạo ra nó, phải có dấu duyệt khớp với nội dung hiện tại.
- Checked at: all
- Fail example: người duyệt danh sách 5 yêu cầu; agent thêm yêu cầu thứ 6 rồi chạy stage `design` trên danh sách mới mà không ai duyệt lại.
- Why: người duyệt một nội dung thì stage sau phải dùng đúng nội dung đó, không phải một bản đã đổi mà không ai thấy.

### INV-002 — Câu hỏi chặn review đã được trả lời trước khi merge
- Rule: mọi câu hỏi mở mức `review-blocking` đã có câu trả lời của người duyệt.
- Checked at: verify
- Fail example: câu hỏi "có cần ghi log mỗi lần đăng nhập thất bại không?" mức `review-blocking` chưa ai trả lời, nhưng `verify` đã xong và thay đổi chờ merge.
- Why: mức `review-blocking` chỉ có nghĩa nếu có luật buộc câu trả lời trước merge; không có luật thì nó không khác `non-blocking`.

### INV-003 — Mọi task truy về yêu cầu hoặc phát hiện, mọi yêu cầu và phát hiện cần sửa có task
- Rule: mọi task phục vụ ít nhất một yêu cầu có thật hoặc sửa một phát hiện có thật của `verify`; mọi yêu cầu có ít nhất một task phục vụ; mọi phát hiện mà `review-report` hiện tại đòi sửa có ít nhất một task ghi là sửa nó.
- Checked at: breakdown
- Fail example: danh sách có 6 yêu cầu, kế hoạch chỉ có task cho 5; yêu cầu thứ 6 không ai làm mà không ai biết.
- Why: task không truy về đâu là việc thừa không ai duyệt; yêu cầu không có task là việc bị bỏ quên.

### INV-004 — Task chỉ dựa trên quyết định có trong thiết kế
- Rule: mọi quyết định mà một task ghi là dựa vào đều có trong thiết kế.
- Checked at: breakdown
- Fail example: task ghi dựa vào quyết định "dùng bộ nhớ đệm phân tán", nhưng thiết kế không có quyết định nào như vậy.
- Why: task dựa vào quyết định không có trong thiết kế là lựa chọn kỹ thuật lọt vào mà người duyệt chưa thấy.

### INV-005 — Artifact được dựng từ bản hiện hành của input
- Rule: mỗi artifact ghi nó được dựng từ phiên bản nào của từng input, và các phiên bản đó trùng với nội dung hiện tại của input.
- Checked at: verify
- Warned from: design
- Fail example: người duyệt trả lời một câu hỏi mở làm danh sách yêu cầu đổi và được duyệt lại, nhưng thiết kế và kế hoạch vẫn dựng từ danh sách cũ.
- Why: dấu duyệt chỉ bảo đảm một artifact không đổi sau khi duyệt; nó không bảo đảm artifact đó còn khớp với input đã đổi.

### INV-006 — Mọi yêu cầu có test, hoặc được kiểm tay có lý do
- Rule: mỗi yêu cầu có ít nhất một test ghi là kiểm nó, hoặc có một task phục vụ nó mà kế hoạch ghi cách chứng minh là kiểm tay và `task-evidence` có bản ghi kiểm tay của task đó, kèm lý do vì sao không viết test được.
- Checked at: implement
- Fail example: yêu cầu "khoá tài khoản sau 5 lần đăng nhập sai" không có test nào ghi là kiểm nó; mọi task vẫn xong vì test của từng task chỉ kiểm hàm đếm số lần sai.
- Why: task xong không có nghĩa yêu cầu đạt; liên kết yêu cầu → test là thứ `verify` dựa vào để phán từng yêu cầu.
