### Nội bộ
- **Gắn id cho 31 chỗ luật của checker `implement` và `review` (SP19 đợt 19e).** Mỗi chỗ chặn/cảnh báo
  trong `tools/check-implement.sh` và `tools/check-review.sh` nay có chú thích `# giữ: CAP-…/INV-…`
  ngay trên, để người review PR truy được một luật engine phục vụ capability / invariant nào của
  interface SDLC. Số chỗ chưa gắn của hai file giảm 15 → 5 và 37 → 16 (cả repo: 81 → 58).
  Người dùng `aw` không thấy khác — không đổi luật, không đổi lời lỗi, chỉ có thứ tự in một nhóm
  cảnh báo thay đổi (nêu ở mục dưới).
- **Ba chỗ mang list id.** Hai chỗ in gộp output của nhiều helper (`cb` ở cả `check-implement.sh`
  mục "Kiem cheo" và `check-review.sh`), một chỗ gọi helper phân theo loại việc
  (`kc_chan_theo_loai`): dòng `# giữ:` liệt kê id của từng helper hoặc từng loại việc, kèm chú thích
  nêu cách đọc. Mỗi id vẫn ứng với đúng một luật, chỉ là luật ấy nằm trong helper chứ không tự in lời
  lỗi tại chỗ gọi. Một trường hợp phải tách: `kt_canh_bao` (tài liệu tri thức bền bị diff đụng mà
  không đổi) ra khỏi khối `cb` của `check-implement.sh`, vì `check-sdlc.sh` đếm id theo chuỗi — để nó
  trong list gộp thì capability CAP-verify-06 còn được khai dù đã bỏ chú thích riêng, và test
  "CAP-verify-06 machine mà luật không gắn # giữ → chặn" mất tác dụng. Cảnh báo này nay in thành
  khối riêng ngay sau các cảnh báo khác của `cb`; nội dung từng dòng không đổi.
- **21 chỗ chưa gắn của hai file, thuộc chín luật** chờ người duyệt capability mới (không gắn id "gần
  đúng", theo spec SP19 § 3): dấu xung đột merge còn trong file thay đổi (`kc_dau_xung_dot`), ADR và
  file luật phải khớp nội dung DEC / REQ đã duyệt (`adr_loi_viec`, `luat_loi_viec`), từ dịch lẫn trong
  artifact (`kc_tu_dich`), file quy tắc khai ở `conventions.md` phải tồn tại và đã commit
  (`kc_quy_tac_loi`), bảng kết luận cho quy tắc riêng của repo ("## Repo rules"), bảng bảy hạng mục
  Lens 4 — Security và cấu trúc finding của Lens 3, base xếp chồng (`kc_base_la`). Danh sách chi tiết
  ở mô tả PR đợt 19e.
- **Sửa hai chỗ nói sai ở đợt 19d** (`changes/claude-sp19d-gan-id-plan-design.md` và roadmap):
  `adr_loi_ke_hoach` được kể là chờ capability mới, kỳ thực nó gắn được CAP-breakdown-02 (task nâng
  ADR phải có trong plan). Không ảnh hưởng số đếm.
