### Nội bộ
- **Checker LLM khai `Serves` cho từng dòng finding (SP19 đợt 19f).** Bảng "Look for" của
  `workflow/checkers/spec.md` và `design.md` thêm cột `Serves`: một hoặc nhiều `CAP-…`/`INV-…` mà dòng
  finding đó phục vụ. Cột chỉ để người và máy truy vết — checker lúc chạy không đọc. `check-sdlc.sh`
  chặn khi bảng thiếu cột, một dòng để trống `Serves`, id không có, hoặc id là capability của stage
  khác stage mà phase khai `llm_checker:` implements. Người dùng `aw` không thấy khác. Một chỗ không
  có capability riêng: `risk-understated` gắn CAP-require-01, cùng cách `check-spec.sh` đã gắn luật
  "Risk: normal mà có từ khoá rủi ro cao" — luật Risk nằm chung một capability.
- **Đếm hàm thư viện trả finding (SP19 đợt 19g).** `check-sdlc.sh --dem-luat` đếm thêm mỗi định nghĩa
  hàm `kc_*`, `tk_*`, `kt_*`, `adr_loi*`, `toc_loi` trong `tools/lib/` chưa có `# giữ:` trong khối chú
  thích liền trên; hàm mới không gắn id làm số chưa gắn của file vượt mức cho phép nên bị chặn.
  `tools/unclassified-rules.txt` thêm bốn dòng `tools/lib/*.sh` (87 hàm chưa gắn) — hạ dần như các file
  `check-*`. Người dùng `aw` không thấy khác.
- **`check-sdlc.sh` chặn thêm hai kiểu lỗi** (Serves nêu trên, hàm thư viện mới chưa gắn); mọi thông
  điệp lỗi mới có trong `docs/interface-sdlc.md` § 5.
