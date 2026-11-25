# Invariants

Luật nối nhiều stage, luôn do máy kiểm. Mỗi luật có các trường:

- **Rule** — điều phải đúng.
- **Checked at** — phải đúng khi kết thúc stage nào.
- **Warned from** — không bắt buộc: stage bắt đầu báo sớm.
- **Only for** — không bắt buộc: chỉ áp cho job type nào. Không có trường này = áp cho mọi loại việc.
- **Fail example** — một ví dụ vi phạm.
- **Why** — vì sao cần.

### INV-001 — Chỉ dùng artifact đã duyệt và chưa bị sửa sau khi duyệt
- Rule: mọi artifact ghi Approval `yes` ở bảng Output của stage tạo ra nó phải có dấu duyệt khớp với nội dung hiện tại.
- Checked at: `all`
- Fail example: người duyệt danh sách 5 yêu cầu; agent thêm yêu cầu thứ 6 rồi chạy `design` trên danh sách mới mà không ai duyệt lại.
- Why: người duyệt một nội dung thì stage sau phải dùng đúng nội dung đó, không phải một bản đã đổi mà không ai thấy.
