### Nội bộ
- **Gắn id cho 45 luật của checker `plan` và `design` (SP19 đợt 19d).** Mỗi chỗ chặn/cảnh báo
  trong `tools/check-plan.sh` và `tools/check-design.sh` nay có chú thích `# giữ: CAP-…/INV-…` ngay
  trên, để người review PR truy được một luật engine phục vụ capability / invariant nào của
  interface SDLC. Số luật chưa gắn của hai file giảm 25 → 2 và 25 → 3 (cả repo: 126 → 81).
  Người dùng `aw` không thấy khác.
- **Năm chỗ còn lại chờ người duyệt capability mới** (không gắn id "gần đúng", theo spec SP19 § 3):
  file luật khai ở `conventions.md` phải tồn tại và đã commit (`kc_quy_tac_loi`), REQ/DEC
  `Promote:` phải có task nâng (`luat_loi_ke_hoach`, `adr_loi_ke_hoach`), trường ADR của DEC
  (`adr_loi_truong`), và Mode 2 — `Risk: high` đòi ít nhất một DEC do người viết. Danh sách chi tiết
  ở mô tả PR.
