### Nội bộ
- `tools/check-sdlc.sh`: gom việc đọc frontmatter các stage file và việc thu các dòng `# giữ:`
  về một lượt awk mỗi loại thay vì chạy lại per-file — chạy nhanh hơn (~ 1,42s → ~ 1,18s), đầu ra
  y hệt trước.
