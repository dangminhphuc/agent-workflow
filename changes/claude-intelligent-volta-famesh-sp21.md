### Sửa
- **`aw ship status` / `aw ship sweep` và kiểm kiến thức bền ↔ diff chạy được trên macOS.** `/bin/sh` của
  macOS (bash 3.2) báo lỗi cú pháp ở hai câu `case` nằm trong `$(…)` (`tools/lib/mr.sh`,
  `tools/lib/knowledge.sh`) — giờ viết dạng `(pattern)`.

### Nội bộ
- **CI chạy bộ test trên macOS** (job `kiem-tra-macos`: bash 3.2, BSD awk, BSD sed), cạnh job Ubuntu
  `kiem-tra` (tên giữ nguyên). Helper `thay` của test truyền chuỗi qua `ENVIRON` (BSD awk từ chối
  `-v` có xuống dòng); `TMP` của test là đường dẫn thật (`/var` → `/private/var` trên macOS). Phần test
  mới `26-posix-macos.sh` chặn `case` thiếu `(` trong `$(…)` ngay trên Ubuntu.
