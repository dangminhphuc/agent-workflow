### Thêm

- **Nhãn nguồn `[INCIDENT]`.** `intake.md` ghi được sự cố hoặc postmortem bằng `[INCIDENT] <định danh>` — cùng luật với `[FILE]`: phải có định danh, không còn chỗ giữ chỗ. Bugfix được trỏ về sự cố gốc. Không bắt buộc: lời người không có mã sự cố vẫn là `[HUMAN]`.

### Thay đổi

- `CAP-operate-02` vẫn do người phán, stage `operate` vẫn gap. Intake implement stage `plan`, không nhận capability của stage khác, và một phase operate phải đứng sau ship — sự cố lại là đầu vào của việc mới.
