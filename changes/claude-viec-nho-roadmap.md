### Thêm
- **`aw input` nhận thêm URL issue/PR dạng mới vào `[ISSUE]`.** Trước đây các URL này rơi về
  `[CONFLUENCE]`/`[HUMAN]`, phải sửa tay. Nay nhận thêm: discussion GitHub (`…/<o>/<r>/discussions/N`,
  `github.com` hoặc host của `origin`), issue/PR Gitea/Forgejo (`…/pulls/N`, host của `origin`),
  issue và PR Bitbucket Cloud (`bitbucket.org`, `…/<w>/<r>/issues/N`, `…/<w>/<r>/pull-requests/N`),
  PR Bitbucket Data Center (host của `origin`, `…/projects/<P>/repos/<R>/pull-requests/N`). Checker
  intake/spec cho qua cùng các dạng này; nhắc URL trong `00-intake.md`, `source-tracing.md`,
  `docs/huong-dan.md` cập nhật theo.

### Nội bộ
- `tools/check-sdlc.sh` bớt thời gian chạy (~1,3 s → ~0,9 s): kiểm invariant một lượt thay vì một awk
  cho mỗi INV; đếm luật chưa gắn `# giữ:` của mọi file một lượt thay vì một awk mỗi file; frontmatter
  của phase đọc một lượt thay vì `fm_scalar`/`fm_list` gọi 6 lần. Hành vi không đổi, ca lỗi giữ nguyên
  chữ (tests 20–25).
