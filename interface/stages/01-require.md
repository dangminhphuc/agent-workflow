# Stage: require

## Definition
Biến work item thành danh sách yêu cầu kiểm chứng được, và liệt kê những điều các nguồn chưa nói rõ.
Thiếu stage này thì thiết kế và code dựa trên điều chưa ai xác nhận, và không ai biết lúc nào thì xong.

## Input
| Artifact  | Required | Used for                                                                          |
|-----------|----------|-----------------------------------------------------------------------------------|
| work-item | yes      | việc cần làm và các nguồn của nó (ticket, tài liệu, lời người); yêu cầu chỉ được rút từ các nguồn này |

## Output
| Artifact       | Description                                                                              |
|----------------|------------------------------------------------------------------------------------------|
| requirements   | danh sách yêu cầu; mỗi yêu cầu chỉ ra nguồn nào trong work item, và có tiêu chí chấp nhận quan sát được |
| open-questions | những điều các nguồn không nói; mỗi điều có giả định tạm dùng và mức chặn                |

## Exit
Máy kiểm mỗi yêu cầu có nguồn và tiêu chí chấp nhận, mỗi câu hỏi mở có giả định và mức chặn, và dấu
duyệt còn khớp với nội dung. Người trả lời các câu hỏi mở mức `blocking` và duyệt danh sách yêu cầu.
`design` chỉ dùng yêu cầu đã duyệt.

## Capabilities

### CAP-require-01 — Mỗi yêu cầu có nguồn và tiêu chí chấp nhận
- Rule: mọi yêu cầu chỉ ra nó lấy từ nguồn nào trong work item, và có tiêu chí chấp nhận mà một người quan sát kiểm được là đạt hay không.
- Judged by: machine
- Artifact: requirements
- Fail example: "Trang đăng nhập phải nhanh" — không chỉ ra nguồn, và "nhanh" không có con số nào để kiểm.
- Pass example: "Đăng nhập trả kết quả trong 2 giây với 100 người cùng lúc" — nguồn: ticket PROJ-42 trong work item.

### CAP-require-02 — Mỗi câu hỏi mở có giả định tạm và mức chặn
- Rule: mọi câu hỏi mở ghi giả định đang tạm dùng, và một mức chặn: `blocking`, `review-blocking` hoặc `non-blocking`.
- Judged by: machine
- Artifact: open-questions
- Fail example: "Có cần hỗ trợ đăng nhập bằng Google không?" — không có giả định tạm, không có mức chặn.

### CAP-require-03 — Dấu duyệt gắn với nội dung
- Rule: stage sau chỉ dùng yêu cầu có dấu duyệt còn hiệu lực; sửa nội dung sau khi duyệt, kể cả sửa theo câu trả lời của người, thì dấu duyệt mất hiệu lực.
- Judged by: machine
- Artifact: requirements
- Fail example: người duyệt 5 yêu cầu, agent thêm yêu cầu thứ 6 rồi chuyển sang `design` mà không ai duyệt lại.

### CAP-require-04 — Người trả lời câu hỏi chặn và duyệt yêu cầu
- Rule: người trả lời mọi câu hỏi mở mức `blocking` — câu trả lời của người là phần duyệt cho câu hỏi đó — rồi đọc và duyệt danh sách yêu cầu.
- Judged by: human
- Artifact: requirements, open-questions
- Fail example: câu hỏi "giữ phiên đăng nhập bao lâu?" mức `blocking` chưa ai trả lời, nhưng danh sách yêu cầu đã được đánh dấu duyệt.

## Not in this stage
- Chọn giải pháp kỹ thuật (thư viện, cấu trúc dữ liệu, API) — thuộc `design`.
- Quyết định việc có được làm hay không, và thuộc loại việc nào — thuộc `plan`.
- Tự trả lời điều nguồn không nói mà không ghi lại — phải ghi thành câu hỏi mở có giả định, để người thấy.
- Thêm hay bớt phạm vi so với work item — quay lại `plan`.
- Viết test — thuộc `implement`; ở đây chỉ viết tiêu chí chấp nhận.

## Rationale
- Đã loại: yêu cầu không cần chỉ ra nguồn — người duyệt không phân biệt được "nguồn nói" với "agent nghĩ", nên duyệt cả điều agent tự đặt ra.
- Đã loại: để agent tự quyết điều nguồn không nói — agent sẽ đoán mà không ai thấy; ghi thành câu hỏi mở có giả định thì điều đoán thành thứ người duyệt được.
- Đã loại: một mức chặn, hoặc nhiều hơn ba — một mức thì câu hỏi nhỏ cũng chặn cả việc; nhiều mức thì không ai phân biệt được ranh giới. Mỗi mức ứng với lúc muộn nhất mà sửa một giả định sai còn rẻ.
- Đã loại: duyệt một lần rồi cho sửa tự do — người duyệt một nội dung, stage sau dùng một nội dung khác.
