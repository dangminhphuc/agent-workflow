### Nội bộ
- **`tools/check-sdlc.sh` còn ~0,55 giây mỗi lượt** (bản trên `main` ~0,92 s, trước đó ~1,1 s — đo cặp
  hai bản trên cùng máy, cùng lúc). PR #119 đã gộp ba vòng (kiểm invariant, đếm luật `# giữ:`, đọc
  frontmatter phase); PR này gộp tiếp phần còn lại — chi phí chính của script là fork process, không
  phải đọc file:
  - một lượt awk dựng **toàn bộ bảng stage ↔ phase** (trạng thái suy ra, có note hay không, `provides`
    chưa phase nào map, `exit_machine` / `exit_human` của phase) — trước: mỗi stage vài lần awk/grep;
  - vòng **profile**: `tools/lib/md.sh` thêm `fm_all` đọc mọi khoá frontmatter một lượt (thay bảy lần
    awk trên cùng file), và `kc_bo_design` vẫn được hỏi thật nhưng `tools/lib/cross-check.sh` chỉ
    **source một lần** cho hết mọi cặp (job type × Design) thay vì mười;
  - tra bảng bằng `case` trên chuỗi tính một lần, kết quả trả qua biến `_R` — bỏ subshell ở
    `stage_so`, `ph_ten`, `kieu`, `co_note` và các `grep -qxF` trong vòng.
  Output và luật chặn **không đổi**: `tools/tests/20-sdlc-conformance.sh` vẫn so ảnh chụp từng bảng với
  output, `sh tools/check-sdlc.sh --dem-luat` vẫn in đúng danh sách trong
  `tools/unclassified-rules.txt`. Người dùng `aw` không thấy gì — script chỉ chạy trên repo engine.
