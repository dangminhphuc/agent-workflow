# Stage: deploy

## Definition
Người duyệt merge đúng phiên bản thay đổi mà `verify` đã rà và cho "nên merge", rồi — nếu người duyệt quyết việc này cần phát hành — thay đổi được hệ thống triển khai bên ngoài đưa tới môi trường chạy, sau khi người duyệt đã xác nhận cách hoàn tác.
Thiếu stage này thì thứ vào nhánh chính có thể không phải thứ đã được rà, và một bản phát hành hỏng không có đường lui đã được ai nghĩ trước.

## Input
| Artifact      | Required | Used for                                                                                     |
|---------------|----------|----------------------------------------------------------------------------------------------|
| change        | yes      | (do `implement` tạo) thứ được merge; phiên bản của nó phải trùng phiên bản báo cáo rà đã rà  |
| review-report | yes      | (do `verify` tạo) phiên bản đã rà và phán quyết merge; chỉ phán quyết "nên merge" mới cho merge |

## Output
| Artifact | Approval | Description                                                                                       |
|----------|----------|---------------------------------------------------------------------------------------------------|
| delivery | no       | phiên bản thay đổi đã merge và người merge; nơi phát hành, hoặc "không phát hành" kèm lý do; đường lui (cách hoàn tác bản phát hành) và người duyệt đã xác nhận nó; kết quả phát hành do hệ thống triển khai báo về |

## Capabilities

### CAP-deploy-01 — Chỉ merge đúng phiên bản đã rà và được phán "nên merge"
- Rule: trước khi người duyệt merge, máy kiểm: phiên bản thay đổi sắp merge trùng phiên bản mà `review-report` ghi là đã rà, và phán quyết merge của báo cáo là "nên merge"; không đạt thì không được merge. Người duyệt không đồng ý với phán quyết thì yêu cầu sửa báo cáo ở `verify`, không merge vượt phán quyết.
- Judged by: machine
- Artifact: delivery
- Fail example: sau khi báo cáo rà được xác nhận, agent sửa thêm một dòng ở thay đổi rồi phiên bản mới được merge.

### CAP-deploy-02 — Người duyệt merge, không phải agent
- Rule: người merge là người duyệt của việc này, có tên ghi trong `delivery`; agent không merge. Merge là quyết định của người đó, và người đó chịu trách nhiệm về nó.
- Judged by: human
- Artifact: delivery
- Fail example: agent tự merge vì phán quyết là "nên merge" và mọi kiểm tra đã đạt.

### CAP-deploy-03 — Đường lui được người duyệt xác nhận trước khi phát hành
- Rule: người duyệt quyết việc có phát hành hay không. Phát hành thì `delivery` ghi cách hoàn tác bản phát hành (kể cả dữ liệu đã đổi, nếu có), và người duyệt xác nhận cách đó trước khi merge (merge có thể tự kích hoạt phát hành); đường lui đổi sau khi xác nhận thì phải xác nhận lại. Không phát hành thì ghi "không phát hành" kèm lý do, và người duyệt xác nhận điều đó trước khi merge, thay cho đường lui.
- Judged by: human
- Artifact: delivery
- Fail example: thay đổi đổi cấu trúc bảng người dùng, được phát hành, nhưng đường lui chỉ ghi "quay về bản trước" mà không nói dữ liệu đã đổi xử lý thế nào, và không ai xác nhận.

### CAP-deploy-04 — Kết quả phát hành do hệ thống triển khai báo về
- Rule: việc được phát hành thì `delivery` ghi nơi phát hành (môi trường chạy, ví dụ môi trường chính thức), phiên bản được phát hành và kết quả, lấy từ hệ thống triển khai bên ngoài và do máy ghi; agent không tự kể kết quả. Phiên bản được phát hành trùng phiên bản đã merge. Stage chỉ xong khi kết quả là đạt, hoặc bản phát hành đã được hoàn tác theo đường lui đã xác nhận và máy ghi việc hoàn tác. Kết quả không đạt thì người duyệt quyết: hoàn tác, hoặc phát hành lại (khi lỗi nằm ở hệ thống triển khai, không ở thay đổi) — kết quả mới thay kết quả cũ; chưa có một trong hai thì stage chưa xong; lỗi gây ra việc hoàn tác đi qua `operate` thành việc mới ở `plan`, không quay lại `implement` vì thay đổi đã merge. Việc không phát hành thì stage xong sau khi merge.
- Judged by: machine
- Artifact: delivery
- Fail example: agent ghi "đã triển khai lên môi trường chính thức thành công", nhưng không có kết quả nào từ hệ thống triển khai.

## Not in this stage
- Triển khai thật (dựng, đẩy lên máy chủ, chuyển lưu lượng) — việc của hệ thống triển khai bên ngoài; stage này chỉ nhận kết quả nó báo về.
- Rà lại thay đổi hay sửa mã — thuộc `verify` và `implement`; phán quyết không đúng thì quay lại `verify`.
- Theo dõi bản phát hành, quyết định hoàn tác vì sự cố xảy ra sau khi kết quả phát hành đã đạt, và đưa sự cố (kể cả lỗi đã gây hoàn tác ở đây) về thành việc mới — thuộc `operate`.
- Chọn thời điểm phát hành, gộp nhiều thay đổi vào một bản phát hành — việc của người, ngoài quy trình.

## Rationale
- Đã loại: agent merge khi mọi kiểm tra đạt — merge là điểm người duyệt chịu trách nhiệm cho thay đổi; máy và agent chỉ chuẩn bị cho quyết định đó.
- Đã loại: người duyệt merge dù phán quyết là "không nên merge" — phán quyết sai thì sửa ở báo cáo, để lý do merge còn lại trong báo cáo, không mất trong một cú bấm.
- Đã loại: `delivery` Approval `yes` — kết quả phát hành được ghi sau khi người xác nhận đường lui, nên duyệt cả khối sẽ mất hiệu lực mỗi lần hệ thống triển khai báo về; người duyệt xác nhận từng phần (đường lui, merge).
- Đã loại: bỏ cả stage khi việc không phát hành — merge nằm ở đây, mà merge là điểm cuối của lõi quy trình; chỉ phần phát hành được phép vắng.
- Đã loại: quy trình tự triển khai — interface chỉ đặc tả điểm nối với hệ thống triển khai bên ngoài; quy trình không kiểm được việc triển khai thật.
