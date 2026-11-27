# Stage: verify

## Definition
Một agent không làm ra thay đổi rà độc lập thay đổi so với yêu cầu, thiết kế và kế hoạch, cho phán quyết từng yêu cầu, ghi các phát hiện và đưa ra phán quyết merge; người duyệt đọc và xác nhận phán quyết.
Thiếu stage này thì chính agent làm ra thay đổi tự chấm bài của mình, và lỗi mà test không bắt (yêu cầu bị hiểu lệch, câu trả lời đến muộn bị bỏ sót, mã nhạy cảm không ai đọc) đi thẳng tới merge.

## Input
| Artifact              | Required | Used for                                                                                       |
|-----------------------|----------|------------------------------------------------------------------------------------------------|
| requirements          | yes      | mỗi yêu cầu cần một phán quyết                                                                 |
| open-questions        | yes      | câu trả lời của người duyệt (kể cả câu đến sau khi `require` xong) và các câu `review-blocking` còn chờ |
| design                | yes      | thay đổi có làm đúng các quyết định và phần mô tả đã duyệt không                               |
| task-plan             | yes      | thay đổi có nằm trong kế hoạch không, mỗi task có thật sự làm điều nó nói                      |
| change                | yes      | (do `implement` tạo) thứ được rà, kèm lời khai ngoài kế hoạch và test bị sửa hay xoá                                |
| test-evidence         | yes      | (do `implement` tạo) kết quả chạy test do máy ghi, để biết yêu cầu nào đã có test đạt                               |
| task-evidence         | yes      | (do `implement` tạo) kết quả từng task và bản ghi kiểm tay, để phán nội dung bản ghi kiểm tay có đúng không         |
| security-evidence     | yes      | (do `implement` tạo) kết quả quét bảo mật do máy ghi                                                                |
| reproduction-evidence | no       | (do `implement` tạo) chỉ có ở việc sửa lỗi: test tái hiện lỗi đỏ trên mã chưa sửa, và xanh sau khi sửa              |
| performance-evidence  | no       | (do `implement` tạo) chỉ có ở việc tối ưu hiệu năng: số đo trước và sau do máy ghi                                  |

## Output
| Artifact      | Approval | Description                                                                                         |
|---------------|----------|-----------------------------------------------------------------------------------------------------|
| review-report | yes      | phiên bản của thay đổi đã rà; phán quyết từng yêu cầu (đạt, đạt một phần, không đạt, hoặc chưa quyết kèm câu hỏi mở đang chờ); các phát hiện, mỗi cái có mức (chặn: phải sửa trước khi merge; nên sửa: không chặn merge, sửa hay không do người duyệt quyết), mô tả, vị trí, yêu cầu liên quan nếu có; phán quyết merge (nên merge hay không); lựa chọn của người duyệt với từng phát hiện mức nên sửa (sửa hay không); các bản ghi người và agent đã rà |

## Capabilities

### CAP-verify-01 — Một agent không làm thay đổi cho phán quyết từng yêu cầu
- Rule: một agent chạy ở phiên làm việc mới, không phải agent đã làm thay đổi, đọc thay đổi và cho phán quyết cho mọi yêu cầu, ghi mỗi phát hiện kèm mức, mô tả và vị trí, rồi cho phán quyết merge. Phán quyết "đạt" chỉ khi agent thấy yêu cầu đạt trong thay đổi — có test đạt kiểm nó, hoặc bản ghi kiểm tay mà agent thấy là đúng — không chỉ vì task của yêu cầu đã xong.
- Judged by: agent
- Artifact: review-report
- Fail example: yêu cầu "khoá tài khoản sau 5 lần sai" được phán "đạt" vì task "đếm lần sai" xong, nhưng thay đổi không khoá tài khoản ở đâu.

### CAP-verify-02 — Báo cáo đủ phán quyết và phán quyết merge khớp với phát hiện
- Rule: báo cáo ghi phiên bản của thay đổi đã rà; mỗi phát hiện đủ mức, mô tả, vị trí; phán quyết merge là "nên merge" chỉ khi không có phát hiện mức chặn, mọi yêu cầu "đạt" (hoặc "chưa quyết" chỉ vì câu hỏi mở mức `non-blocking` còn chờ), lần chạy test và lần quét bảo mật cuối cùng trong bằng chứng đều đạt. Không thoả thì phán quyết merge là "không nên merge". Câu hỏi mở mức `review-blocking` chưa có câu trả lời thì lượt rà cho "nên merge" chưa xong được (`INV-002`). Máy kiểm các điều này; phát hiện hay phán quyết đúng hay sai do agent và người duyệt phán.
- Judged by: machine
- Artifact: review-report
- Fail example: báo cáo ghi một phát hiện mức chặn "mật khẩu ghi vào log" nhưng phán quyết merge là "nên merge".

### CAP-verify-03 — Mọi yêu cầu khớp với câu trả lời của câu hỏi mở nó trỏ tới
- Rule: với mỗi yêu cầu trỏ tới một câu hỏi mở đã có câu trả lời, agent đối chiếu yêu cầu với câu trả lời và ghi mọi chỗ khác nhau thành phát hiện; việc này bắt câu trả lời đến sau khi `require` xong mà yêu cầu chưa được sửa theo (`CAP-require-05`).
- Judged by: agent
- Artifact: review-report
- Fail example: giả định "giữ phiên 30 ngày", người duyệt trả lời "1 ngày" sau khi `require` xong; yêu cầu và thay đổi vẫn là 30 ngày, báo cáo không ghi phát hiện nào.

### CAP-verify-04 — Kiểm thử đầu-cuối chạy trên hệ thống đã ghép
- Rule: kiểm thử đầu-cuối chạy trên hệ thống đã ghép các phần lại, kết quả do máy ghi vào báo cáo; không đạt thì có phát hiện. Capability này bắt buộc với mọi dự án: chưa có công cụ làm được thì lượt rà cho "nên merge" chưa xong. Chỉ bắt buộc ở lượt rà cho phán quyết "nên merge"; lượt cho "không nên merge" không cần.
- Judged by: machine
- Artifact: review-report
- Fail example: báo cáo ghi "kiểm thử đầu-cuối đạt" nhưng không có lần chạy nào do máy ghi.

### CAP-verify-05 — Thay đổi có thể ảnh hưởng tải hay độ trễ được đo với mục tiêu đã nêu
- Rule: mọi thay đổi có thể ảnh hưởng tải hay độ trễ, dù thuộc loại việc nào, được máy đo so với một mục tiêu đã nêu trong yêu cầu, kết quả ghi vào báo cáo. Yêu cầu không nêu mục tiêu nào thì agent rà ghi một phát hiện mức chặn, và việc quay lại `require` để thêm mục tiêu (qua một câu hỏi mở nếu nguồn không nêu). Chỉ bắt buộc ở lượt rà cho phán quyết "nên merge"; lượt cho "không nên merge" không cần.
- Judged by: machine
- Artifact: review-report
- Fail example: thay đổi thêm một truy vấn vào mỗi lần đăng nhập, yêu cầu nêu "trả kết quả trong 2 giây", nhưng không có số đo nào.

### CAP-verify-06 — Mã nhạy cảm được một người đọc
- Rule: nếu người duyệt đã khai một phần mã là nhạy cảm (khai ở đâu thuộc cách agent làm việc, ngoài interface), và thay đổi đụng tới phần đó, thì một người, có tên ghi trong báo cáo và không phải agent, đọc phần đó trước khi merge. Máy chỉ kiểm có tên người; người đó đọc kỹ hay không do chính người đó chịu.
- Judged by: human
- Artifact: review-report
- Fail example: thay đổi sửa mô-đun xác thực, được khai là nhạy cảm, nhưng chỗ ghi người đọc bảo mật để trống.

### CAP-verify-07 — Người yêu cầu chấp nhận thay đổi (UAT)
- Rule: những người đã yêu cầu thay đổi chấp nhận nó so với các yêu cầu trước khi merge. Người yêu cầu là người đặt ra việc, có thể trùng với người duyệt; có tên và lời chấp nhận trong báo cáo là đủ. Chỉ bắt buộc ở lượt rà cho phán quyết "nên merge"; lượt cho "không nên merge" không cần.
- Judged by: human
- Artifact: review-report
- Fail example: người đặt yêu cầu chưa xem thay đổi lần nào, nhưng phán quyết merge đã là "nên merge" và được xác nhận.

### CAP-verify-08 — Người duyệt xác nhận phán quyết
- Rule: người duyệt đọc báo cáo — phán quyết từng yêu cầu, các phát hiện, phán quyết merge — rồi duyệt (xác nhận phán quyết) hoặc yêu cầu sửa; báo cáo được duyệt cả khi phán quyết merge là "không nên merge"; nội dung báo cáo đổi sau khi duyệt thì phải duyệt lại. Phát hiện quay lại `breakdown` để sửa gồm mọi phát hiện mức chặn và những phát hiện mức nên sửa mà người duyệt chọn sửa.
- Judged by: human
- Artifact: review-report
- Fail example: người duyệt chỉ đọc dòng phán quyết merge "nên merge" rồi xác nhận, bỏ qua hai phát hiện mức nên sửa mà agent đã ghi.

## Not in this stage
- Sửa mã — `verify` chỉ rà; phát hiện cần sửa quay lại `breakdown` (trực tiếp, hoặc qua `design` hay `require` nếu đụng quyết định hay yêu cầu).
- Chạy lại test của task hay quét bảo mật để thay bằng chứng của `implement` — bằng chứng đó do máy ghi ở `implement`; stage này chỉ đọc chúng (kiểm thử đầu-cuối và đo tải ở `CAP-verify-04` và `CAP-verify-05` là kiểm thêm, không thay chúng).
- Merge — chỉ người duyệt merge, ở `deploy`, sau khi `verify` xong.
- Trả lời câu hỏi mở thay người duyệt — agent chỉ ghi câu nào còn chờ.
- Ghi lại tri thức bền vững của dự án (quy ước, quyết định kiến trúc) — chưa thuộc interface.

## Rationale
- Đã loại: chính agent làm thay đổi tự rà — nó đã coi nhiều điều là hiển nhiên, nên không thấy chúng sai; agent khác phiên trắng đọc như người lạ.
- Đã loại: để `verify` quét bảo mật hay chạy lại test — lỗi quét ra là việc sửa mã, mà `verify` không sửa mã; kết quả đã có từ `implement`.
- Đã loại: phán quyết merge không có luật máy — người duyệt dễ chỉ đọc dòng cuối, nên máy chặn phán quyết "nên merge" khi báo cáo tự nó nêu lý do không merge.
- Đã loại: phán quyết "đạt" cho yêu cầu chỉ vì task của nó xong — task xong là điều `implement` đã bảo đảm; điều `verify` phải trả lời là yêu cầu có đạt không.
- Đã loại: đẩy mọi phán quyết cho người duyệt — người duyệt không đọc nổi từng yêu cầu của thay đổi lớn; agent rà trước, người duyệt xác nhận và chỉ đọc kỹ chỗ agent nêu.
