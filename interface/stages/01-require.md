# Stage: require

## Definition
Biến work item thành danh sách yêu cầu kiểm chứng được, và liệt kê những điều các nguồn chưa nói rõ.
Thiếu stage này thì thiết kế và code dựa trên điều chưa ai xác nhận, và không ai biết lúc nào thì xong.

## Input
| Artifact  | Required | Used for                                                                          |
|-----------|----------|-----------------------------------------------------------------------------------|
| work-item | yes      | việc cần làm và các nguồn của nó (ticket, tài liệu, lời người duyệt); yêu cầu chỉ được rút từ các nguồn này, hoặc từ giả định của một câu hỏi mở |

## Output
| Artifact       | Approval | Description                                                                         |
|----------------|----------|-------------------------------------------------------------------------------------|
| requirements   | yes      | danh sách yêu cầu; mỗi yêu cầu chỉ ra nguồn, và có tiêu chí chấp nhận quan sát được; stage tuỳ chọn mà việc này bỏ, kèm lý do (`INV-013`) |
| open-questions | no       | những điều các nguồn không nói; mỗi điều có giả định tạm dùng, mức chặn, và câu trả lời của người duyệt khi đã có; người duyệt trả lời từng câu, vào lúc mức chặn của câu đó đòi hỏi |

## Capabilities

### CAP-require-01 — Mỗi yêu cầu có nguồn và tiêu chí chấp nhận
- Rule: mọi yêu cầu chỉ ra ít nhất một nguồn — một nguồn có trong work item, hoặc một câu hỏi mở nếu yêu cầu dựa trên giả định của câu hỏi đó — và có ít nhất một tiêu chí chấp nhận.
- Judged by: machine
- Artifact: requirements
- Fail example: yêu cầu ghi nguồn là "ticket PROJ-99", nhưng work item chỉ có ticket PROJ-42.

### CAP-require-02 — Tiêu chí chấp nhận quan sát được
- Rule: mỗi tiêu chí chấp nhận nói rõ cái gì xảy ra hay đo được bao nhiêu, để bất kỳ ai quan sát cũng kết luận được đạt hay không; không dùng từ mơ hồ như "nhanh", "dễ dùng" mà không có con số hay hành vi cụ thể.
- Judged by: agent
- Artifact: requirements
- Fail example: "Trang đăng nhập phải nhanh" — "nhanh" không có con số nào để kiểm.
- Pass example: "Đăng nhập trả kết quả trong 2 giây với 100 người cùng lúc."

### CAP-require-03 — Mỗi câu hỏi mở có giả định tạm và mức chặn; câu chặn đã được trả lời
- Rule: mọi câu hỏi mở ghi giả định đang tạm dùng, và một mức chặn: `blocking`, `review-blocking` hoặc `non-blocking`; mọi câu mức `blocking` đã có câu trả lời của người duyệt.
- Judged by: machine
- Artifact: open-questions
- Fail example: "Có cần hỗ trợ đăng nhập bằng Google không?" — không có giả định tạm, không có mức chặn.

### CAP-require-04 — Người duyệt trả lời câu hỏi chặn và duyệt yêu cầu
- Rule: chính người duyệt trả lời mọi câu hỏi mở mức `blocking` — câu trả lời là việc duyệt câu hỏi đó, câu hỏi không cần dấu duyệt riêng — rồi, sau khi yêu cầu đã được sửa theo câu trả lời (`CAP-require-05`), đọc và duyệt danh sách yêu cầu.
- Judged by: human
- Artifact: requirements, open-questions
- Fail example: agent tự điền câu trả lời cho câu hỏi `blocking` "giữ phiên đăng nhập bao lâu?" rồi coi như người duyệt đã trả lời.

### CAP-require-05 — Câu trả lời khác giả định thì yêu cầu được sửa theo
- Rule: khi người duyệt trả lời một câu hỏi mở khác với giả định tạm, mọi yêu cầu trỏ tới câu hỏi đó được sửa theo câu trả lời.
- Judged by: agent
- Artifact: requirements
- Fail example: giả định "giữ phiên 30 ngày", người duyệt trả lời "1 ngày", nhưng yêu cầu vẫn ghi 30 ngày.

## Not in this stage
- Chọn giải pháp kỹ thuật (thư viện, cấu trúc dữ liệu, API) — thuộc `design`.
- Quyết định việc có được làm hay không, và thuộc loại việc nào — thuộc `plan`.
- Tự trả lời điều nguồn không nói mà không ghi lại — điều việc cần biết mà nguồn không nói thì ghi thành câu hỏi mở có giả định.
- Thêm việc nằm ngoài phạm vi work item — phạm vi đổi thì work item phải sửa ở `plan` trước.
- Viết test — thuộc `implement`; ở đây chỉ viết tiêu chí chấp nhận.

## Rationale
- Đã loại: yêu cầu không cần chỉ ra nguồn — người duyệt không phân biệt được "nguồn nói" với "agent nghĩ", nên duyệt cả điều agent tự đặt ra.
- Đã loại: để agent tự quyết điều nguồn không nói — agent sẽ đoán mà không ai thấy; ghi thành câu hỏi mở có giả định thì điều đoán thành thứ người duyệt được.
- Đã loại: một, hai, hay nhiều hơn ba mức chặn — một mức thì câu hỏi nhỏ cũng chặn cả việc; hai mức (chặn / không chặn) không tách được câu phải biết trước khi thiết kế với câu chỉ cần biết trước khi merge; nhiều hơn ba thì không ai phân biệt được ranh giới. Mỗi mức ứng với lúc muộn nhất mà sửa một giả định sai còn rẻ.
- Đã loại: một capability gộp "có tiêu chí" với "tiêu chí quan sát được" — máy kiểm chính xác được cái đầu, không phán được cái sau; gộp lại thì hoặc máy báo nhầm, hoặc lỗi "nhanh" lọt qua.
- Đã loại: duyệt `open-questions` như một khối — câu `non-blocking` được trả lời bất cứ lúc nào, nên mỗi câu trả lời sẽ làm mất dấu duyệt của cả khối. Duyệt từng câu thì chỉ câu trả lời khác giả định mới kéo theo duyệt lại, và chỉ duyệt lại `requirements`.
