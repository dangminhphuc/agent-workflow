### Sửa
- **`aw` chạy đúng với awk của macOS.** Mọi script của engine giờ chạy với `LC_ALL=C`: awk đếm theo
  byte như mawk (bản engine được viết và thử). Trước đó, ở locale UTF-8, awk của macOS cắt chuỗi giữa
  một ký tự có dấu (`towc: multibyte conversion failure`) — vd `aw check implement` không nhận ra task
  `Kiểm chứng: thủ công`. Chữ tiếng Việt trong artifact và output không đổi.

### Nội bộ
- **Sửa workflow `kiem-tra` không parse được sau #96, rồi gỡ bước chẩn đoán tạm.** Bước đó viết
  `run:` một dòng có `": "` nên YAML không đọc được: mọi lần chạy `kiem-tra` (cả job Ubuntu) thất bại
  ngay, không job nào chạy. Bước đó đã xong việc (job macOS xanh) nên gỡ hẳn; `AW_TEST_SHOW_FAIL=1`
  (in output của ca hỏng) giữ lại ở cả hai job.
- **Bộ test chạy đúng trên bash 3.2 (sh của macOS):** không còn gán biến ngay trước lời gọi hàm
  (`X=… ham` — bash 3.2 giữ X sau khi hàm chạy, làm hỏng chuỗi ca `aw worktree` phía sau); helper
  frontmatter của test SP20 truyền chuỗi qua `ENVIRON`. Phần `26-posix-macos.sh` thêm ca chặn
  `X=… ham` ngay trên Ubuntu.
