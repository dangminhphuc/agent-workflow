# Stage: implement

## Definition
Làm lần lượt từng task theo thứ tự của kế hoạch, mỗi task chỉ xong khi cách chứng minh xong của nó đạt — do máy chạy, hoặc, khi kế hoạch ghi cách đó là kiểm tay, có bản ghi kiểm tay; test và quét bảo mật do máy chạy, kết quả do máy ghi.
Thiếu stage này thì "đã xong" và "test đạt" chỉ là lời agent kể, và thay đổi có thể ra ngoài kế hoạch mà không ai biết.

## Input
| Artifact     | Required | Used for                                                                                     |
|--------------|----------|----------------------------------------------------------------------------------------------|
| work-item    | yes      | điểm xuất phát: thay đổi bắt đầu từ đó và được so với nó; test được chạy trên mã ở điểm xuất phát trước task đầu tiên |
| requirements | yes      | tiêu chí chấp nhận mà test kiểm; mỗi yêu cầu có test hoặc được kiểm tay (`INV-006`)          |
| design       | yes      | quyết định và phần mô tả mà các task làm theo                                                |
| task-plan    | yes      | thứ tự task, phần mã mỗi task được đụng, cách chứng minh mỗi task xong                       |

## Output
| Artifact          | Approval | Description                                                                                  |
|-------------------|----------|----------------------------------------------------------------------------------------------|
| change            | no       | thay đổi mã so với điểm xuất phát; test nào kiểm một yêu cầu thì ghi yêu cầu đó; kèm lời khai: file ngoài kế hoạch và lý do, test có sẵn bị sửa hay xoá và lý do |
| test-evidence     | no       | kết quả chạy toàn bộ test do máy ghi: một lần trên điểm xuất phát (nếu đã có mã), và trên phiên bản hiện tại của thay đổi |
| task-evidence     | no       | với mỗi task: kết quả cách chứng minh xong do máy chạy, hoặc bản ghi kiểm tay nói ai kiểm, kiểm gì, thấy gì và vì sao không viết test được |
| security-evidence | no       | kết quả quét bảo mật do máy chạy trên phiên bản hiện tại của thay đổi                        |

## Capabilities

### CAP-implement-01 — Task chỉ xong khi máy thấy cách chứng minh xong đạt
- Rule: task được làm lần lượt theo thứ tự của kế hoạch — task sau chỉ bắt đầu khi task trước đã xong; một task chỉ được ghi là xong khi máy chạy cách chứng minh xong của nó trên phiên bản của thay đổi lúc đó và đạt, hoặc, nếu kế hoạch ghi cách chứng minh của task là kiểm tay, khi có bản ghi kiểm tay đủ ai kiểm, kiểm gì, thấy gì và vì sao không viết test được; người kiểm tay là người duyệt hoặc một agent khác với agent đang làm task; mọi task của kế hoạch đã xong. Máy chỉ kiểm bản ghi kiểm tay đủ các ý trên; nội dung của nó đúng hay không do `verify` phán.
- Judged by: machine
- Artifact: task-evidence
- Fail example: agent ghi task 2 là xong rồi sang task 3, nhưng test của task 2 chưa từng được máy chạy.

### CAP-implement-02 — Test do máy chạy, và thay đổi không làm hỏng test đang đạt
- Rule: máy chạy toàn bộ test trên điểm xuất phát (nếu đã có mã) trước task đầu tiên, và trên phiên bản hiện tại của thay đổi, rồi ghi kết quả; agent không tự báo kết quả. Mọi test đạt trên thay đổi; riêng test đã không đạt ở điểm xuất phát thì được phép vẫn không đạt.
- Judged by: machine
- Artifact: test-evidence
- Fail example: agent ghi "toàn bộ test đạt", nhưng lần chạy cuối của máy là trước khi agent sửa thêm hai file.

### CAP-implement-03 — Thay đổi nằm trong phần mã của task đang làm
- Rule: mỗi file thay đổi nằm trong phần mã của task đang làm lúc nó đổi, hoặc được khai là ngoài kế hoạch kèm lý do; file đổi khi không có task nào đang làm cũng phải được khai.
- Judged by: machine
- Artifact: change
- Fail example: task "sửa hàm gia hạn phiên" chỉ được đụng mô-đun phiên, nhưng thay đổi sửa cả cấu hình gửi email mà không khai.

### CAP-implement-04 — Test có sẵn bị sửa hay xoá đều được khai
- Rule: mỗi test có ở điểm xuất phát mà thay đổi sửa hay xoá được khai trong thay đổi, kèm lý do.
- Judged by: machine
- Artifact: change
- Fail example: test "phiên hết hạn sau 30 phút" không đạt sau thay đổi, bị xoá, và không có lời khai nào.

### CAP-implement-05 — Quét bảo mật đạt trước khi rời stage
- Rule: máy quét bảo mật phiên bản hiện tại của thay đổi và ghi kết quả; stage không xong khi lần quét không đạt. Phát hiện ở mức nào thì tính là không đạt thuộc cách agent làm việc, ngoài interface.
- Judged by: machine
- Artifact: security-evidence
- Fail example: kết quả quét báo một khoá bí mật bị ghi thẳng vào mã, nhưng việc vẫn sang `verify`.

## Not in this stage
- Thêm, bỏ hay đổi thứ tự task — quay lại `breakdown`.
- Lựa chọn kỹ thuật mà thiết kế không có — quay lại `design`.
- Thêm hay bỏ yêu cầu, trả lời câu hỏi mở — thuộc `require` và người duyệt.
- Phán thay đổi đã đạt yêu cầu và thiết kế chưa — thuộc `verify`.
- Merge — chỉ người duyệt merge, sau khi `verify` xong.

## Rationale
- Đã loại: agent tự báo "test đạt" hay "task xong" — chỉ kiểm được điều agent nói, không phải điều đã xảy ra.
- Đã loại: capability `agent` hay `human` ở stage này — stage chỉ làm theo kế hoạch đã chia; điều cần phán (thay đổi có đạt yêu cầu không) thuộc `verify`, nơi một agent khác rà toàn bộ.
- Đã loại: quét bảo mật ở `verify` — lỗi quét ra là việc sửa mã, nên quét ở đây để sửa ngay trong vòng làm task.
- Đã loại: chỉ cảnh báo file ngoài kế hoạch ở đây và đợi tới `verify` mới chặn — mã chỉ đổi ở stage này (`verify` không sửa mã), nên chặn lúc stage này kết thúc là sớm nhất và rẻ nhất.
- Đã loại: không chạy test trên điểm xuất phát — không phân biệt được lỗi do thay đổi với lỗi có sẵn, và agent dễ "sửa" test vốn đã không đạt.
