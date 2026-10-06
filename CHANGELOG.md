# Changelog

Version là **ngày phát hành** `YYYY.M.D` (tháng, ngày **không** có số 0 đứng đầu, vd
`2026.10.6`). Mỗi bản phát hành là một git tag đúng chuỗi đó, không có tiền tố
`v`; mỗi ngày tối đa một bản. Repo đích ghim version
cần dùng (xem README, mục "Nâng cấp"); một việc đã bắt đầu thì chạy hết bằng
version ghi trong `intake.md` của nó.

So version theo luật **khớp chính xác `YYYY.M.D`** — không có "tương thích ngược"
ngầm giữa các bản.

## [2026.10.8]

### Đổi
- `/clarify`: lựa chọn là **phương án giải pháp agent đã phân tích**, không còn
  chỉ "giữ giả định / chưa trả lời được". Trước mỗi mục, agent đọc nguồn, spec,
  thiết kế, code đã có; đưa 2–3 phương án khác nhau về hệ quả, mỗi phương án
  kèm đánh đổi một dòng; phương án nên chọn đứng đầu, nhãn **bắt đầu bằng
  `(Đề xuất)`**, ngữ cảnh nói vì sao. Mục gói nhiều quyết định thì tách thành
  nhiều câu hỏi trong cùng lượt. Phát hiện checker LLM: các cách sửa cụ thể +
  Bác bỏ (agent thấy phát hiện sai thì đề xuất bác bỏ).
- Adapter Claude Code: không thêm "Chat về câu này" vào `options` nữa — dùng
  "Chat about this" / "Type something" có sẵn của `AskUserQuestion`, để đủ chỗ
  cho phương án thật. Mẫu câu hỏi luôn kết thúc bằng hai dòng `Type something.`
  và `Chat about this.`; agent không có giao diện lựa chọn thì tự in hai dòng đó.
- Người chọn phương án agent đề xuất thì `Trả lời:` ghi nhãn phương án kèm
  `(chọn từ phương án agent đề xuất)`.

## [2026.10.7]

### Đổi (phá tương thích)
- `/open-questions` → **`/clarify`**: một hàng đợi cho mọi việc máy/LLM cần người
  quyết. Ngoài điểm mù (`open-questions.md`), lệnh dẫn người **phân xử phát hiện
  của checker LLM** (`phat-hien-*.md`, hiện có `phat-hien-thiet-ke.md`) từng mục
  bằng câu hỏi lựa chọn: Đồng ý — sửa · Bác bỏ (kèm lý do) · Chat về câu này, mục
  `Cảnh báo` thêm Để sau. Đồng ý thì agent cho xem dòng `tdd.md` sẽ đổi rồi ghi
  `đã sửa`; quyết định mới thành D-xx `đề xuất` để người duyệt. Phát hiện agent
  đã tự sửa lúc `/design` được nêu lại trong tổng kết.
- `aw questions` → **`aw pending`** (`tools/liet-ke-viec-cho.sh`): gom điểm mù và
  mọi `phat-hien-*.md`, xếp theo phase bị chặn sớm nhất (điểm mù chưa phân mức →
  `chặn` → phát hiện `Chặn` → `chặn review` → phát hiện `Cảnh báo` → `không chặn`).
  Nhãn kết quả đổi theo: `KHÔNG CÒN VIỆC CHỜ NGƯỜI` / `CÓ VIỆC ĐANG CHẶN` /
  `CÒN VIỆC CHỜ NGƯỜI, CHƯA CHẶN`. Wrapper vẫn chuyển `aw questions` cho việc đã
  ghim engine 2026.10.6.
- Tên và cấu trúc file trong `.agent-workflow/<tên-branch>/` **không đổi**. Repo
  đích chạy lại `aw adapter build claude-code`: `/open-questions` cũ tự bị xoá.
- Wrapper `aw` 2026.10.6 không biết `aw pending` — cài lại wrapper từ bản này
  (README, mục cài đặt) trước khi dùng `/clarify`.

## [2026.10.6]

Bản đầu tiên có version: đổi cách cài, **phá tương thích** với bộ cài cũ. Không còn file nào
phải commit vào repo đích — chạy được khi nhánh gốc là protected branch.

### Thêm
- Wrapper `aw` (POSIX sh, cài global). Tìm repo bằng `git rev-parse`, lấy engine
  đúng version vào `~/.agent-workflow/engine/<YYYY.M.D>/`, kiểm và ghim sha256,
  chuyển lệnh sang engine. `AW_ENGINE_DIR` (không mạng), `AW_MIRROR`, `AW_CACHE`.
- Lệnh: `aw init [--from <url>] [--from-legacy]`, `aw upgrade <YYYY.M.D>`,
  `aw version`, `aw doctor`, `aw check <tên> <thư-mục>`, `aw worktree new|status|remove`,
  `aw adapter build <agent>`, `aw feature`, `aw input`, `aw questions`,
  `aw based-on`, `aw rename`. Tên lệnh và cờ đều tiếng Anh.
- Ghim version theo việc: dòng `- **Engine:** YYYY.M.D` trong `intake.md`; mọi
  `aw check` của việc chạy đúng version đó, không có thì `KHÔNG HỢP LỆ`.
- Đóng gói phát hành (`tools/dong-goi.sh`) và workflow `release` gắn
  `agent-workflow-YYYY.M.D.tar.gz`, `aw`, `SHA256SUMS` vào GitHub Release.
- `adapters/lib/chung.sh` và `adapters/README.md` (hợp đồng adapter, ghi chú Codex/Cursor).
- Mẫu mô tả MR/PR `workflow/templates/merge-request.md` và quy ước mặc định ở
  mục "Merge request" của `conventions.md` (tiêu đề, phạm vi, mục bắt buộc,
  điều kiện trước khi review/merge).

### Đổi
- `/open-questions` hỏi **từng điểm mù một bằng câu hỏi lựa chọn** thay vì dán cả
  danh sách: giữ giả định tạm · cách hiểu khác có trong nguồn · Chưa trả lời được
  · Chat về câu này, luôn kèm ô tự nhập. Output của `aw questions` là dữ liệu cho
  agent; người chỉ thấy một dòng tóm tắt. Lệnh tiện ích khai `choice_ui: true`;
  adapter Claude Code dịch sang tool `AskUserQuestion`.
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
