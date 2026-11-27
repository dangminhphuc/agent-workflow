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
- Rule: khi `review-report` cho phán quyết "nên merge", mọi câu hỏi mở mức `review-blocking` đã có câu trả lời của người duyệt. Lượt rà cho "không nên merge" không cần, vì nó không dẫn tới merge.
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
- Rule: mỗi artifact ghi nó được dựng từ phiên bản nào của từng input, và các phiên bản đó trùng với nội dung hiện tại của input. Không tính hai input: `open-questions` — câu trả lời khác giả định đã buộc sửa `requirements` (`CAP-require-05`, `CAP-verify-03`), còn câu khớp giả định không làm gì cũ; và `review-report` khi kiểm ở `verify` — kế hoạch chỉ cần dựng từ báo cáo của lượt rà trước.
- Checked at: verify
- Warned from: design
- Fail example: người duyệt trả lời một câu hỏi mở làm danh sách yêu cầu đổi và được duyệt lại, nhưng thiết kế và kế hoạch vẫn dựng từ danh sách cũ.
- Why: dấu duyệt chỉ bảo đảm một artifact không đổi sau khi duyệt; nó không bảo đảm artifact đó còn khớp với input đã đổi.

### INV-006 — Mọi yêu cầu có test, hoặc được kiểm tay có lý do
- Rule: mỗi yêu cầu có ít nhất một test ghi là kiểm nó, hoặc có một task phục vụ nó mà kế hoạch ghi cách chứng minh là kiểm tay và `task-evidence` có bản ghi kiểm tay của task đó, kèm lý do vì sao không viết test được.
- Checked at: implement
- Fail example: yêu cầu "khoá tài khoản sau 5 lần đăng nhập sai" không có test nào ghi là kiểm nó; mọi task vẫn xong vì test của từng task chỉ kiểm hàm đếm số lần sai.
- Why: task xong không có nghĩa yêu cầu đạt; liên kết yêu cầu → test là thứ `verify` dựa vào để phán từng yêu cầu.

### INV-007 — Mọi yêu cầu có phán quyết trong báo cáo rà
- Rule: mọi yêu cầu có thật có một phán quyết hợp lệ trong `review-report` hiện tại.
- Checked at: verify
- Fail example: danh sách có 6 yêu cầu, báo cáo rà phán quyết 5; yêu cầu thứ 6 không ai nhìn mà báo cáo vẫn được xác nhận.
- Why: báo cáo chỉ phủ một phần yêu cầu thì "nên merge" chỉ đúng với phần đó; người duyệt xác nhận mà không biết có chỗ chưa ai nhìn.

### INV-008 — Test tái hiện lỗi đỏ trên mã chưa sửa, xanh sau khi sửa
- Rule: `reproduction-evidence` ghi một test mà máy đã chạy trên mã chưa sửa — điểm xuất phát, chỉ thêm chính test đó — và không đạt; và cùng test đó máy chạy trên phiên bản hiện tại của thay đổi và đạt.
- Checked at: implement
- Only for: bugfix
- Fail example: test tái hiện được viết sau khi đã sửa mã, nên chưa từng được máy chạy trên mã chưa sửa.
- Why: một test chưa từng đỏ trên lỗi thì không chứng minh nó bắt được lỗi đó.

### INV-009 — Yêu cầu không thêm hành vi
- Rule: mỗi yêu cầu ghi một loại: giữ hành vi, tái cấu trúc, hoặc — chỉ với `perf` — mục tiêu hiệu năng bằng số; mỗi yêu cầu giữ hành vi có ít nhất một test có ở điểm xuất phát ghi là kiểm nó.
- Checked at: implement
- Warned from: require
- Only for: refactor, perf
- Fail example: việc refactor có yêu cầu "hiện thông báo lỗi mới khi đăng nhập sai", không ghi loại nào.
- Why: loại việc không thêm hành vi được làm nhẹ hơn; yêu cầu thêm hành vi lọt vào thì đi đường nhẹ mà không ai duyệt như một tính năng.

### INV-010 — Không xoá test có sẵn
- Rule: không test nào có ở điểm xuất phát bị thay đổi xoá; đổi tên hay chuyển chỗ một test là sửa, phải khai như mọi test bị sửa.
- Checked at: implement
- Only for: refactor, perf
- Fail example: refactor mô-đun phiên xoá test "phiên hết hạn sau 30 phút" vì nó gọi hàm đã đổi tên, dù đã khai lý do.
- Why: với việc không đổi hành vi, test có sẵn là bằng chứng hành vi cũ còn đúng; xoá nó là bỏ bằng chứng.

### INV-011 — Số đo trước và sau do máy ghi
- Rule: `performance-evidence` có số đo trên điểm xuất phát và trên phiên bản hiện tại của thay đổi, cùng một cách đo, do máy chạy và ghi.
- Checked at: implement
- Only for: perf
- Fail example: agent ghi "nhanh hơn 40%" nhưng chỉ có số đo sau khi thay đổi.
- Why: không có số đo trước do máy ghi thì mục tiêu hiệu năng chỉ là lời agent kể.

### INV-012 — Không đụng mã production, thư viện đổi được khai
- Rule: không file nào của thay đổi là mã production (nghĩa ở job-types.md); mỗi thư viện đổi phiên bản được khai trong lời khai của thay đổi (như file ngoài kế hoạch), kèm phiên bản cũ và mới.
- Checked at: implement
- Only for: chore
- Fail example: việc "cập nhật tài liệu" sửa thêm một dòng trong mô-đun thanh toán.
- Why: `chore` không chạy `design`; không chặn mã production thì nó thành lối tắt cho mọi thay đổi.

### INV-013 — Stage tuỳ chọn bị bỏ có người duyệt việc bỏ
- Rule: với loại việc của work item, mỗi stage ghi Optional mà việc này không chạy thì phải được ghi là bỏ trong `requirements`, kèm lý do; dấu duyệt của `requirements` phủ việc bỏ đó (`INV-001`).
- Checked at: breakdown
- Fail example: việc `bugfix` đi thẳng từ `require` sang `breakdown`, `requirements` không ghi bỏ `design`.
- Why: bỏ một stage là bỏ một lớp bảo đảm; người duyệt phải thấy và đồng ý, không để agent tự chọn đường nhẹ.
