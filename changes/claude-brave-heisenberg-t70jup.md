### Nội bộ
- **Roadmap cải thiện engine theo dự án con.** `docs/superpowers/2026-10-22-roadmap-cai-thien.md` chia
  kết quả lượt đánh giá 10/2026 (engine và interface SDLC) thành 12 dự án con có thứ tự, phụ thuộc và
  câu cần người quyết; mỗi dự án con đi spec → plan → PR theo luồng Superpowers. `docs/viec-can-lam.md`
  trỏ tới roadmap. Không đổi hành vi `aw`.
- **Interface SDLC: capability phạm vi.** Thêm `CAP-breakdown-02` (task nêu file được đổi và cách kiểm),
  `CAP-implement-04` (file đổi nằm trong kế hoạch hoặc khai ngoài kế hoạch), `CAP-implement-05` (phạm vi
  theo từng task, mẫu file hẹp — chưa làm), `CAP-implement-06` (task chỉ xong khi máy ghi bước kiểm đạt).
  Stage `implement` thành `partial`. Người dùng `aw` không thấy gì khác.
- **Interface SDLC: capability khai `Artifact`.** Mỗi capability ghi loại artifact nó bảo đảm
  (`- Artifact:`); `tools/check-sdlc.sh` chặn khi thiếu, khi loại không thuộc `provides` của stage, và
  khi một loại `provides` của stage không capability nào trỏ tới.
