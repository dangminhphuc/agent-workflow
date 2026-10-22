### Thêm

- **Checker LLM cho spec.** Sau khi viết `spec.md`, agent gọi subagent `spec-checker`. Checker chỉ đối chiếu mô tả và tiêu chí chấp nhận với `Quote` và lời `[HUMAN]` trong `intake.md` — không đọc lại file, Jira, Confluence. Nó chỉ được chặn. Kết quả ghi `spec-findings.md`.
- **`aw check spec` chặn** khi thiếu `spec-findings.md`, hoặc còn phát hiện `block` chưa `fixed` / `rejected: <lý do>`. Cảnh báo (`warn`) không chặn. Người phân xử qua `/aw-clarify` trước khi tick duyệt spec. Khi không có phase design, phát hiện `block` của spec chặn `/aw-plan`.
- **`aw approval`** (cổng vào design hoặc plan) in một dòng nếu finding của spec còn chưa phân xử.

### Thay đổi

- Việc mới phải có `spec-findings.md`. Việc đã ghim engine cũ không bị ảnh hưởng.
