# Stage: breakdown

## Definition
Chia thiết kế đã duyệt thành các task nhỏ có thứ tự, mỗi task nói nó phục vụ yêu cầu nào (hoặc sửa phát hiện nào của `verify`), được đụng phần mã nào, và làm sao chứng minh nó xong.
Thiếu stage này thì `implement` tự chọn thứ tự và phạm vi, không ai kiểm được một thay đổi có ra ngoài kế hoạch không, và "xong" không có tiêu chí.

## Input
| Artifact      | Required | Used for                                                                                     |
|---------------|----------|----------------------------------------------------------------------------------------------|
| requirements  | yes      | mỗi task phục vụ một hay nhiều yêu cầu; mọi yêu cầu phải có task. Yêu cầu hay thiết kế đổi sau khi kế hoạch đã có thì kế hoạch được dựng lại từ bản mới (`INV-005`) |
| design        | yes      | task làm theo các quyết định và phần mô tả của thiết kế đã duyệt; không thêm lựa chọn kỹ thuật mới |
| review-report | no       | phát hiện của lượt `verify` trước mà chưa có task sửa; phát hiện không đụng tới quyết định hay yêu cầu thành task mới, **nối thêm** vào cuối kế hoạch đã có — task cũ giữ nguyên, không sửa, không đổi thứ tự. Phát hiện đã đi qua `require` hay `design` thì kế hoạch dựng lại từ yêu cầu hay thiết kế mới, như dòng trên |

## Output
| Artifact  | Approval | Description                                                                                       |
|-----------|----------|---------------------------------------------------------------------------------------------------|
| task-plan | no       | danh sách task có thứ tự; mỗi task ghi yêu cầu nó phục vụ hoặc phát hiện nó sửa, quyết định nó dựa vào (nếu có), phần mã (file hay nhóm file) nó được đụng, và cách chứng minh nó xong |

## Capabilities

### CAP-breakdown-01 — Mỗi task đủ thông tin để làm và để kiểm
- Rule: mỗi task ghi ít nhất một yêu cầu nó phục vụ hoặc một phát hiện nó sửa, phần mã nó được đụng, và một cách chứng minh xong; không trường nào rỗng hay để chỗ trống.
- Judged by: machine
- Artifact: task-plan
- Fail example: task "dọn dẹp mã đăng nhập" không ghi yêu cầu nào, và cách chứng minh xong để trống.

### CAP-breakdown-02 — Task đủ nhỏ, thứ tự làm được
- Rule: mỗi task làm trọn và kiểm được trước khi sang task kế, và sau khi xong thì test đang có vẫn đạt; task nào cần kết quả của task khác thì đứng sau task đó.
- Judged by: agent
- Artifact: task-plan
- Fail example: task 1 là "viết test cho hàm gia hạn phiên" trong khi hàm đó chỉ được tạo ở task 3.

### CAP-breakdown-03 — Không lựa chọn kỹ thuật nào ngoài thiết kế
- Rule: một agent không viết kế hoạch đọc nó và không thấy task nào đưa vào một lựa chọn đáng thành quyết định (theo ngưỡng ở trang `design`) mà thiết kế không có.
- Judged by: agent
- Artifact: task-plan
- Fail example: thiết kế không nói gì về cơ sở dữ liệu, nhưng task 2 ghi "chuyển bảng phiên sang cơ sở dữ liệu khác".

## Not in this stage
- Viết code — thuộc `implement`.
- Chọn cách làm mới mà thiết kế chưa có — quay lại `design`.
- Thêm yêu cầu, bỏ hay hoãn một yêu cầu — quay lại `require`, người duyệt duyệt lại.
- Sửa phát hiện của `verify` mà đụng tới quyết định hay yêu cầu — quay lại `design` hay `require` trước; task sửa nó sau đó vẫn ghi phát hiện đó.

## Rationale
- Đã loại: người duyệt duyệt kế hoạch — kế hoạch chỉ chia việc đã duyệt; máy kiểm nó chỉ trỏ tới yêu cầu và quyết định có thật, agent kiểm nó không thêm lựa chọn mới, nên thêm một cổng người chỉ tốn thời gian.
- Đã loại: cho phép hoãn yêu cầu ngay trong kế hoạch — hoãn là đổi phạm vi mà không ai duyệt; muốn hoãn thì sửa danh sách yêu cầu và người duyệt duyệt lại.
- Đã loại: task không ghi phần mã được đụng — không kiểm được thay đổi có ra ngoài kế hoạch không.
- Đã loại: task kiểu "dọn dẹp toàn bộ mô-đun" — không có tiêu chí xong, nên không bao giờ chứng minh được là xong.
