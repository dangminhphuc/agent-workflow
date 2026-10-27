### Nội bộ
- **`tools/check-sdlc.sh` nhanh hơn ~2,4 lần** (đo cùng máy, cùng lúc: 2,02s → 0,87s thấp nhất,
  trung vị 2,23s → 0,93s). Chi phí chính của script là fork process (awk/grep/subshell), không phải
  đọc file; các vòng "một process cho mỗi mục" nhân lên hàng trăm lần mỗi lượt chạy. Nay: một lượt awk
  cho mọi invariant, một lượt awk cho mọi file đếm luật `# giữ:` (`--dem-luat` cũng dùng chung), một
  lượt awk dựng bảng stage ↔ phase, và tra bảng bằng chuỗi `case` trong shell thay `$(grep …)`.
  `tools/lib/md.sh` thêm `fm_all` — đọc mọi khoá frontmatter của một file trong một lượt, dùng cho
  phase và profile (trước đây bảy lần awk trên cùng một file). Output và luật chặn **không đổi**:
  `tools/tests/20-sdlc-conformance.sh` vẫn so ảnh chụp từng bảng với output, chạy `sh
  tools/check-sdlc.sh --dem-luat` vẫn in đúng danh sách trong `tools/unclassified-rules.txt`.
  Người dùng `aw` không thấy gì — script chỉ chạy trên repo engine.
