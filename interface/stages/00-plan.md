# Stage: plan

## Definition
Nhận một việc từ bên ngoài quy trình vào làm, và ghi lại thành work item: loại việc, các nguồn mô tả nó, điểm xuất phát.
Thiếu stage này thì mọi yêu cầu về sau không có chung một gốc, và việc chạy theo luật của loại việc sai.

## Input
| Artifact             | Required | Used for                                                                                   |
|----------------------|----------|--------------------------------------------------------------------------------------------|
| operational-feedback | no       | sự cố hay phát hiện từ vận hành; thành một nguồn của work item mới. Yêu cầu từ bên ngoài quy trình (ticket, tài liệu, lời người duyệt) không phải artifact: người duyệt hoặc hệ thống bên ngoài đưa thẳng vào stage này |

## Output
| Artifact  | Approval | Description                                                                 |
|-----------|----------|-----------------------------------------------------------------------------|
| work-item | yes      | một việc đã được nhận: loại việc, các nguồn của nó, điểm xuất phát          |

## Capabilities

### CAP-plan-01 — Work item ghi đủ loại việc, nguồn và điểm xuất phát
- Rule: mọi work item ghi một loại việc có trong danh sách job type (xem overview), ít nhất một nguồn, và một điểm xuất phát — một phiên bản mã nguồn có thật, hoặc "chưa có mã" nếu là dự án mới.
- Judged by: machine
- Artifact: work-item
- Fail example: work item ghi loại việc là "cải tiến" — không có trong danh sách — và không ghi điểm xuất phát.

### CAP-plan-02 — Nguồn chỉ là tham chiếu hoặc lời người duyệt nguyên văn
- Rule: mỗi nguồn là một tham chiếu tới tài liệu có định danh (mã ticket, địa chỉ tài liệu), hoặc lời người duyệt nói với agent, chép nguyên văn; không có nguồn nào là bản tóm tắt hay điều agent tự suy ra.
- Judged by: agent
- Artifact: work-item
- Fail example: nguồn ghi "khách hàng muốn đăng nhập nhanh hơn" — không trỏ tới tài liệu nào, và không phải câu người duyệt đã nói.
- Pass example: nguồn là ticket PROJ-42, và câu của người duyệt chép nguyên văn: "Đăng nhập chậm quá, sửa đi."

### CAP-plan-03 — Người duyệt xác nhận loại việc, nguồn và điểm xuất phát
- Rule: người duyệt xác nhận loại việc, danh sách nguồn và điểm xuất phát; sự xác nhận này là việc nhận việc vào quy trình, và có trước khi yêu cầu nào được viết.
- Judged by: human
- Artifact: work-item
- Fail example: agent ghi work item, đặt loại việc là sửa lỗi, rồi chuyển sang `require` khi người duyệt chưa xác nhận.

## Not in this stage
- Xếp ưu tiên giữa các việc và ước lượng công sức — việc của người, ngoài quy trình.
- Giải thích nguồn nói gì và viết yêu cầu — thuộc `require`.
- Thêm điều nguồn không nói — stage này chỉ trỏ tới nguồn; điều nguồn không nói được ghi ở `require` thành câu hỏi mở.

## Rationale
- Đã loại: để agent tự quyết loại việc — loại việc đổi luật của mọi stage sau, nên chọn sai thì mọi stage sau kiểm sai; người duyệt xác nhận.
- Đã loại: work item chứa bản tóm tắt nguồn — chỗ suy đoán của agent lọt vào mà trông như từ nguồn; chỉ trỏ tới nguồn hoặc chép nguyên văn lời người duyệt.
- Đã loại: xếp ưu tiên và ước lượng thành capability — máy không phán được và người làm ngoài quy trình; đưa vào chỉ thành thủ tục không ai kiểm.
- Đã loại: nhận việc không cần người xác nhận — việc sai loại hay sai nguồn đi thẳng vào `require`.
