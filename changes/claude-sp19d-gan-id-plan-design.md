### Nội bộ
- **Gắn id cho 45 luật của checker `plan` và `design` (SP19 đợt 19d).** Mỗi chỗ chặn/cảnh báo
  trong `tools/check-plan.sh` và `tools/check-design.sh` nay có chú thích `# giữ: CAP-…/INV-…` ngay
  trên, để người review PR truy được một luật engine phục vụ capability / invariant nào của
  interface SDLC. Số luật chưa gắn của hai file giảm 25 → 2 và 25 → 3 (cả repo: 126 → 81).
  Người dùng `aw` không thấy khác.
- **Bốn chỗ còn lại chờ người duyệt capability mới** (không gắn id "gần đúng", theo spec SP19 § 3):
  file luật khai ở `conventions.md` phải tồn tại và đã commit (`kc_quy_tac_loi`), REQ `Promote:` phải
  có task nâng (`luat_loi_ke_hoach`), trường Promote/Scope/Supersedes của DEC
  (`adr_loi_truong`), và Mode 2 — `Risk: high` đòi ít nhất một DEC do người viết. Danh sách chi tiết
  ở mô tả PR. (`adr_loi_ke_hoach` nêu ở bản đầu thực ra gắn được CAP-breakdown-02 — sửa 2026-10-29.)
- **Số đo bộ test trên CI** (roadmap § Việc nhỏ): 2136 ca, ALL PASS — Ubuntu 3 phút 42 giây, macOS
  11 phút 35 giây. Thay số đo cũ (1963 ca, 5 phút 23 giây, chỉ đo máy cục bộ). Không đổi hành vi.
