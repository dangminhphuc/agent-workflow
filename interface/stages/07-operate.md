# Stage: operate

## Definition
Trong một khoảng theo dõi người duyệt đặt, hệ thống giám sát bên ngoài báo về tín hiệu của bản phát hành; mỗi sự cố hay điều bất thường — kể cả lỗi đã gây hoàn tác ở `deploy` — được ghi thành một mục, và người duyệt quyết cái nào thành việc mới cho `plan`.
Thiếu stage này thì điều production cho thấy không quay lại quy trình: lỗi chỉ sống trong hệ thống giám sát, và lỗi đã gây hoàn tác bị quên vì thay đổi không còn chạy.

## Input
| Artifact     | Required | Used for                                                                                       |
|--------------|----------|------------------------------------------------------------------------------------------------|
| delivery     | yes      | (do `deploy` tạo) phiên bản và nơi phát hành để biết theo dõi gì; kết quả phát hành, kể cả việc hoàn tác và lỗi gây ra nó; hoặc "không phát hành" |
| requirements | yes      | (do `require` tạo) tiêu chí chấp nhận, để biết tín hiệu nào cho thấy thay đổi không làm đúng yêu cầu |

## Output
| Artifact             | Approval | Description                                                                                  |
|----------------------|----------|----------------------------------------------------------------------------------------------|
| operational-feedback | no       | khoảng theo dõi; tín hiệu do hệ thống giám sát báo về; các mục (sự cố hay điều bất thường), mỗi mục có nguồn (tín hiệu nào, lúc nào), mô tả, yêu cầu liên quan nếu có, quyết định hoàn tác nếu có, và lựa chọn của người duyệt: thành việc mới, hoặc không kèm lý do |

## Capabilities

### CAP-operate-01 — Tín hiệu do hệ thống giám sát báo về, không do agent kể
- Rule: bản phát hành có kết quả phát hành đạt ở `deploy` thì `operational-feedback` ghi khoảng theo dõi — một khoảng thời gian tính từ lúc phát hành, độ dài do người duyệt đặt khi stage bắt đầu, kết thúc khi hết thời gian hoặc ngay khi bản phát hành bị hoàn tác — và các tín hiệu (chỉ số, log, cảnh báo) của bản phát hành trong khoảng đó, lấy từ hệ thống giám sát bên ngoài và do máy ghi; mỗi mục trỏ tới tín hiệu là nguồn của nó. Bản phát hành đã bị hoàn tác ở `deploy` thì không còn gì để theo dõi: không có khoảng theo dõi, và lỗi đã gây hoàn tác là một mục, nguồn là kết quả phát hành trong `delivery`. Hoàn tác quyết trong stage này thì kết quả hoàn tác do hệ thống triển khai báo về, máy ghi vào mục của sự cố đã gây hoàn tác (tạo mục đó nếu chưa có).
- Judged by: machine
- Artifact: operational-feedback
- Fail example: agent ghi "sau phát hành không có lỗi" nhưng không có tín hiệu nào từ hệ thống giám sát trong khoảng theo dõi.

### CAP-operate-02 — Tín hiệu bất thường được ghi thành mục
- Rule: một agent, không phải agent đã làm ra thay đổi, đọc tín hiệu trong khoảng theo dõi, đối chiếu với tiêu chí chấp nhận của các yêu cầu, và ghi mọi điều bất thường thấy được (lỗi tăng, chậm hơn mục tiêu, hành vi khác yêu cầu) thành mục; agent không bỏ một điều bất thường vì cho là không đáng — bỏ hay không là quyết định của người duyệt.
- Judged by: agent
- Artifact: operational-feedback
- Fail example: tỉ lệ đăng nhập thất bại tăng gấp ba sau phát hành, tín hiệu đã được ghi, nhưng không có mục nào.

### CAP-operate-03 — Người duyệt quyết hoàn tác và quyết từng mục
- Rule: người duyệt đặt độ dài khoảng theo dõi khi stage bắt đầu. Với mỗi mục, người duyệt chọn: thành việc mới (`plan` nhận mục đó làm nguồn), hoặc không, kèm lý do; chọn ngay khi mục được ghi, không phải đợi hết khoảng theo dõi. Mục là sự cố của bản phát hành đang chạy thì người duyệt còn quyết có hoàn tác theo đường lui đã xác nhận ở `deploy` hay không, và quyết định đó ghi vào mục. Mục là lỗi đã gây hoàn tác — ở `deploy`, hoặc do người duyệt quyết hoàn tác theo đường lui đã xác nhận ở `deploy` khi sự cố xảy ra trong khoảng theo dõi — luôn thành việc mới, vì thay đổi không còn chạy. Stage xong khi mọi mục đã có quyết định và khoảng theo dõi, nếu có, đã kết thúc (`CAP-operate-01`); việc không phát hành thì không có mục, người duyệt không phải làm gì, stage xong ngay.
- Judged by: human
- Artifact: operational-feedback
- Fail example: hết khoảng theo dõi, còn một mục "lỗi gửi email xác nhận" chưa ai quyết, nhưng việc được ghi là đã xong.

## Not in this stage
- Giám sát, cảnh báo, trực sự cố, và thực hiện hoàn tác — việc của hệ thống và người bên ngoài; stage này chỉ có quyết định hoàn tác của người duyệt (`CAP-operate-03`), và nhận tín hiệu cùng kết quả họ báo về.
- Sửa sự cố — sự cố thành việc mới, đi lại từ `plan`.
- Viết work item từ một mục — thuộc `plan`; xếp ưu tiên giữa các việc mới — việc của người, ngoài quy trình.
- Hậu kiểm sự cố (tìm nguyên nhân gốc, bài học) — tìm nguyên nhân là việc của việc mới; interface không đòi thêm.

## Rationale
- Đã loại: agent tự tóm tắt tình trạng production — chỉ kiểm được điều agent nói, không phải điều đã xảy ra.
- Đã loại: mọi tín hiệu bất thường tự động thành việc mới — nhiều nhiễu; người duyệt quyết, và lý do bỏ được ghi lại.
- Đã loại: stage không có điểm kết thúc — không biết khi nào thôi theo dõi một thay đổi; khoảng theo dõi do người duyệt đặt.
- Đã loại: đặt việc quan sát production ngoài interface — khi đó không gì bảo đảm phản hồi đến từ tín hiệu thật; interface chỉ đòi kết quả từ hệ thống giám sát, không nói cách giám sát.
- Đã loại: hậu kiểm sự cố là capability — chưa có nhu cầu; việc mới từ sự cố đã đi qua `require` và `design`, nơi nguyên nhân được làm rõ.
