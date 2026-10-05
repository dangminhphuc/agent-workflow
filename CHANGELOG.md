# Changelog

Mỗi bản phát hành là một git tag `vX.Y.Z` của repo này. Repo đích ghim version
cần dùng (xem README, mục "Nâng cấp"); một việc đã bắt đầu thì chạy hết bằng
version ghi trong `intake.md` của nó.

So version theo luật **khớp chính xác `X.Y.Z`** — không có "tương thích ngược"
ngầm giữa các bản.

## [2.0.0] — chưa phát hành

Bản major: đổi cách cài, **phá tương thích** với bộ cài 1.x. Không còn file nào
phải commit vào repo đích — chạy được khi nhánh gốc là protected branch.

### Thêm
- Wrapper `aw` (POSIX sh, cài global). Tìm repo bằng `git rev-parse`, lấy engine
  đúng version vào `~/.agent-workflow/engine/<X.Y.Z>/`, kiểm và ghim sha256,
  chuyển lệnh sang engine. `AW_ENGINE_DIR` (không mạng), `AW_MIRROR`, `AW_CACHE`.
- Lệnh: `aw init [--from <url>] [--from-legacy]`, `aw upgrade <X.Y.Z>`,
  `aw version`, `aw doctor`, `aw check <tên> <thư-mục>`, `aw worktree new|status|remove`,
  `aw adapter build <agent>`, `aw feature`, `aw input`, `aw questions`,
  `aw based-on`, `aw rename`. Tên lệnh và cờ đều tiếng Anh.
- Ghim version theo việc: dòng `- **Engine:** X.Y.Z` trong `intake.md`; mọi
  `aw check` của việc chạy đúng version đó, không có thì `KHÔNG HỢP LỆ`.
- Đóng gói phát hành (`tools/dong-goi.sh`) và workflow `release` gắn
  `agent-workflow-X.Y.Z.tar.gz`, `aw`, `SHA256SUMS` vào GitHub Release.
- `adapters/lib/chung.sh` và `adapters/README.md` (hợp đồng adapter, ghi chú Codex/Cursor).
- Mẫu mô tả MR/PR `workflow/templates/merge-request.md` và quy ước mặc định ở
  mục "Merge request" của `conventions.md` (tiêu đề, phạm vi, mục bắt buộc,
  điều kiện trước khi review/merge).

### Đổi
- Cấu hình nằm trong `$(git rev-parse --git-common-dir)/agent-workflow/`:
  `version`, `checksums`, `conventions.md`, `config.sh` (thay `.quy-trinh/cau-hinh.sh`,
  thêm `ADAPTER`). Dùng chung mọi worktree, không commit.
- `/.agent-workflow/` và thư mục adapter (`/.claude/`) vào `.git/info/exclude`.
  Artifact của việc chỉ ở máy; `aw worktree remove` chép nó vào
  `.git/agent-workflow/archive/` trước khi gỡ.
- Base của worktree tuỳ ý — bỏ điều kiện "base phải có bộ cài".
- Adapter sinh lệnh gọi `aw …`; `exit_machine` là `aw check <tên>`. Rules,
  templates, checkers chép vào `.agent-workflow/.engine/` khi sinh adapter.
- Tool đọc đường dẫn từ `AW_REPO`, `AW_CONFIG`, `AW_ENGINE`; không còn suy từ vị
  trí của chính nó.
- Cờ: `--create --base` (thay `--tao --goc`), `--delete-branch` (thay
  `--xoa --ca-branch`), `--skip` (thay `--tru`), `--before|--after` (thay `--truoc|--sau`).

### Bỏ
- `tools/cai-dat.sh`, `tools/dong-bo.sh`: chỉ in hướng dẫn chuyển sang
  `aw init` / `aw upgrade`. Chuyển repo cũ: `aw init --from-legacy` (không xoá,
  không commit; in lệnh `git rm` để người dọn bằng PR).
