# Stage: require

## Definition
Biến work item thành danh sách yêu cầu kiểm chứng được, và liệt kê những điều nguồn chưa nói rõ.
Thiếu stage này thì thiết kế và code dựa trên điều chưa ai xác nhận, và không ai biết lúc nào thì xong.

## Input
| Artifact  | Required | Used for                                              |
|-----------|----------|-------------------------------------------------------|
| work-item | yes      | nguồn duy nhất để rút ra yêu cầu: việc gì, từ đâu tới |

## Output
| Artifact       | Description                                                                         |
|----------------|-------------------------------------------------------------------------------------|
| requirements   | danh sách yêu cầu; mỗi yêu cầu ghi nguồn và có tiêu chí chấp nhận quan sát được     |
| open-questions | những điều nguồn không nói; mỗi điều có giả định tạm dùng và mức chặn               |

## Exit
- Judged by: both
Máy kiểm mỗi yêu cầu có nguồn và tiêu chí chấp nhận, mỗi câu hỏi mở có giả định và mức chặn, và dấu
duyệt của người còn khớp với nội dung. Người đọc danh sách yêu cầu, trả lời các câu hỏi mở mức
`blocking`, rồi duyệt; `design` chỉ bắt đầu sau khi người duyệt.

## Capabilities

### CAP-require-01 — Mỗi yêu cầu có nguồn và tiêu chí chấp nhận
- Rule: mọi yêu cầu ghi rõ nó đến từ nguồn nào, và có tiêu chí chấp nhận mà một người quan sát kiểm được là đạt hay không.
- Judged by: machine
- Artifact: requirements
- Fail example: "Trang đăng nhập phải nhanh" — không ghi nguồn, và "nhanh" không có con số nào để kiểm.
- Pass example: "Đăng nhập trả kết quả trong 2 giây với 100 người cùng lúc" — nguồn: ticket PROJ-42.

### CAP-require-02 — Mỗi câu hỏi mở có giả định tạm và mức chặn
- Rule: mọi câu hỏi mở ghi giả định đang tạm dùng, và một trong ba mức chặn: `blocking` (phải trả lời trước `design`), `review-blocking` (phải trả lời trước khi merge), `non-blocking` (giao được trên giả định).
- Judged by: machine
- Artifact: open-questions
- Fail example: "Có cần hỗ trợ đăng nhập bằng Google không?" — không có giả định tạm, không có mức chặn.

### CAP-require-03 — Người duyệt yêu cầu, và dấu duyệt gắn với nội dung
- Rule: stage sau chỉ dùng yêu cầu đã được người duyệt; sửa nội dung sau khi duyệt thì dấu duyệt mất hiệu lực, phải duyệt lại.
- Judged by: machine
- Artifact: requirements
- Fail example: người duyệt 5 yêu cầu, agent thêm yêu cầu thứ 6 rồi chuyển sang `design` mà không ai duyệt lại.

## Not in this stage
- Chọn giải pháp kỹ thuật (thư viện, cấu trúc dữ liệu, API) — thuộc `design`.
- Quyết định việc có được làm hay không, và thuộc loại việc nào — thuộc `plan`.
- Tự trả lời điều nguồn không nói — ghi thành câu hỏi mở để người trả lời.
- Thêm hay bớt phạm vi so với work item — quay lại `plan`.
- Viết test — thuộc `implement`; ở đây chỉ viết tiêu chí chấp nhận.

## Rationale
- Bỏ: yêu cầu không cần ghi nguồn — người duyệt không phân biệt được "nguồn nói" với "agent nghĩ", nên duyệt cả điều agent tự đặt ra.
- Bỏ: để agent tự quyết điều nguồn không nói — agent sẽ đoán, mà đoán thì không ai duyệt; ghi thành câu hỏi mở có giả định thì điều đoán thành thứ người thấy.
- Bỏ: một mức chặn duy nhất, hoặc nhiều hơn ba mức — một mức thì mọi câu hỏi đều chặn hết; nhiều mức thì không ai đo được ranh giới. Ba mức gắn với stage rẻ nhất để sửa nếu giả định sai.
- Bỏ: duyệt một lần rồi cho sửa tự do — người sẽ duyệt một nội dung và stage sau dùng một nội dung khác.
