# Stage: design

## Definition
Chọn cách xây dựng để đạt các yêu cầu, và tách mỗi lựa chọn mà người khác có thể chọn khác và đổi về sau thì tốn thành một quyết định riêng cho người duyệt duyệt.
Thiếu stage này thì lựa chọn kỹ thuật nằm lẫn trong văn xuôi hay trong code, người duyệt không thấy mình đang đồng ý với điều gì, và lựa chọn khó đảo ngược được làm mà không ai quyết.

## Input
| Artifact       | Required | Used for                                                                 |
|----------------|----------|--------------------------------------------------------------------------|
| work-item      | yes      | điểm xuất phát: mã hiện có mà thiết kế phải khớp, và phải đọc trước khi chọn |
| requirements   | yes      | những gì thiết kế phải đạt; mỗi quyết định và mỗi phần thiết kế ghi các yêu cầu nó phục vụ |
| open-questions | yes      | giả định đang tạm dùng (có thể không có câu hỏi nào), để biết điều nào trong thiết kế còn dựa trên giả định |

## Output
| Artifact | Approval | Description                                                                                   |
|----------|----------|-----------------------------------------------------------------------------------------------|
| design   | yes      | ba thứ: mã hiện có bị đụng tới; các quyết định — mỗi cái có vấn đề, các phương án, đánh đổi, phương án được chọn, yêu cầu nó phục vụ; các phần mô tả — mỗi phần là một mục nói cách xây dựng một điều, ghi các yêu cầu nó phục vụ |

## Capabilities

### CAP-design-01 — Quyết định có đủ phương án, và mọi yêu cầu có chỗ trong thiết kế
- Rule: thiết kế nêu mã hiện có bị đụng tới (hoặc ghi "chưa có mã"); mỗi quyết định ghi vấn đề, ít nhất hai phương án kèm đánh đổi, phương án được chọn, và ít nhất một yêu cầu nó phục vụ; mỗi yêu cầu được ít nhất một phần mô tả (không tính quyết định) ghi là yêu cầu nó phục vụ.
- Judged by: machine
- Artifact: design
- Fail example: quyết định "dùng hàng đợi để gửi email" chỉ có một phương án, và không nói phục vụ yêu cầu nào.

### CAP-design-02 — Không có quyết định ngầm, không phần nào lệch quyết định
- Rule: một agent không viết thiết kế đọc nó và không thấy lựa chọn nào đáng thành quyết định mà nằm trong văn xuôi, cũng không thấy phần nào trái với quyết định nó dựa vào. Một lựa chọn đáng thành quyết định khi một người có hiểu biết có thể chọn khác, và đổi nó về sau tốn hơn một lần sửa nhỏ: đụng nhiều chỗ, đụng dữ liệu đã lưu, đụng giao diện mà hệ thống hay người bên ngoài dùng, hoặc không đảo ngược được.
- Judged by: agent
- Artifact: design
- Fail example: phần luồng dữ liệu viết "lưu phiên trong bộ nhớ đệm 30 ngày" — một lựa chọn khó đổi — mà không có quyết định nào cho nó.

### CAP-design-03 — Thiết kế nói rõ cách đạt từng yêu cầu, và không thêm gì ngoài yêu cầu
- Rule: mỗi phần mô tả ghi phục vụ một yêu cầu nói rõ yêu cầu đó được đạt thế nào; thiết kế không thêm hành vi nào mà người dùng hay hệ thống bên ngoài quan sát được nếu yêu cầu không có — cơ chế bên trong để đạt yêu cầu thì không tính.
- Judged by: agent
- Artifact: design
- Fail example: phần mô tả "kiến trúc dịch vụ đăng nhập" ghi phục vụ yêu cầu "đăng nhập trả kết quả trong 2 giây", nhưng không nói gì về thời gian trả kết quả.

### CAP-design-04 — Người duyệt duyệt từng quyết định
- Rule: người duyệt đọc và duyệt từng quyết định, rồi duyệt thiết kế; thiết kế không có quyết định nào vẫn phải được duyệt.
- Judged by: human
- Artifact: design
- Fail example: thiết kế có ba quyết định, người duyệt mới duyệt hai, nhưng việc đã chuyển sang `breakdown`.

## Not in this stage
- Viết code, kể cả code mẫu — thuộc `implement`.
- Thêm yêu cầu mới — phải quay lại `require`.
- Chia việc thành các task — thuộc `breakdown`.
- Trả lời câu hỏi mở thay người duyệt — chỉ người duyệt trả lời; thiết kế dùng giả định đã ghi.
- Quyết định việc nhỏ có được bỏ stage này hay không — job type cho phép, người duyệt duyệt việc bỏ (`INV-013`).

## Rationale
- Đã loại: thiết kế là văn xuôi dài để người duyệt đọc soát — người lướt văn xuôi và không thấy đâu là lựa chọn thật; tách thành quyết định thì người quyết thay vì đọc soát.
- Đã loại: agent viết thiết kế tự tìm quyết định ngầm của chính mình — nó không thấy điều nó đã coi là hiển nhiên; agent khác không biết lập luận ban đầu nên đọc như người lạ.
- Đã loại: bắt buộc ít nhất một quyết định — việc không có lựa chọn thật sẽ sinh quyết định giả để qua kiểm.
- Đã loại: tách quyết định ra artifact riêng — hai artifact về cùng một thiết kế sẽ lệch nhau mà không ai thấy.
- Đã loại: chỉ duyệt cả khối mà không duyệt từng quyết định — người duyệt sẽ duyệt cả khối mà bỏ qua quyết định khó nhất.
