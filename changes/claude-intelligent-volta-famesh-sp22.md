### Sửa
- **Hai việc song song không còn tạo ADR trùng số trên `main`.** `aw adr promote` cấp số lớn hơn mọi số
  trong worktree và trên base của việc (`origin/<Base>`, fetch trước; không fetch được thì báo và dùng
  bản đã có). Số của việc đã bị một ADR khác chiếm trên base thì `aw check implement`, `aw check review`
  và `aw ship create` (so với nhánh đích) **chặn**, nêu file trên base. Cách sửa: chạy lại
  `aw adr promote <dir> DEC-NNN` — máy cấp số mới, đổi tên file, sửa `superseded by` của ADR bị thay và
  dựng lại bảng chỉ mục.
