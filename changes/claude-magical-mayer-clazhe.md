### Nội bộ
- **Repo engine: thay đổi ghi vào mảnh `changes/<tên-nhánh>.md`, không sửa `CHANGELOG.md` nữa.**
  Trước đây PR nào cũng chèn vào cùng một chỗ dưới `## [Chưa phát hành]`, nên hai PR mở song song
  gần như luôn conflict ở `CHANGELOG.md` (13 lần trong lịch sử merge, file kế tiếp chỉ 3). Mỗi PR
  giờ thêm một file riêng; `tools/prepare-release.sh` gom các mảnh vào `## [<version>]` (gộp theo
  mục) rồi xoá, và vẫn gom cả nội dung `## [Chưa phát hành]` còn sót từ PR mở trước thay đổi này.
  `tools/check-release.sh` (workflow `kiem-tra`) chặn mảnh sai dạng ngay ở PR. Dạng mảnh:
  `changes/README.md`. Người dùng `aw` không bị ảnh hưởng.
- **`AGENTS.md`: merge `origin/main` mới nhất và chạy lại test trước mỗi lần push PR; sau khi một PR
  được merge, kiểm các PR còn mở có conflict không** — conflict được phát hiện và giải khi còn nhỏ.
