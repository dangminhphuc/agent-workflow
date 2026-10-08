# Adapter Claude Code

Biên dịch định nghĩa phase trung lập sang `.claude/` của Claude Code.

```sh
aw adapter build claude-code [--out <thư-mục>] [--force]
```

Thường không gọi trực tiếp — `aw init` và `aw worktree new … --create` gọi nó. File sinh ra nằm
trong `.claude/` (khai ở [`exclude`](exclude), `aw init` thêm vào `.git/info/exclude`). File
`.claude/` git đang theo dõi thì bỏ qua. `--out` trỏ vào repo agent-workflow bị từ chối.

Việc sinh dùng chung `adapters/lib/common.sh`; file này chỉ khai hook
([../README.md](../README.md#hook-của-adapter)). Mỗi file sinh ra có dòng **"Dành cho Claude
Code"**: Cursor nạp `.claude/` để tương thích, nên agent không có `AskUserQuestion` thì dừng và
dùng bản `.cursor/`.

## Biên dịch ra gì

| Nguồn | Artifact |
|---|---|
| `workflow/phases/<id>.md` | `.claude/commands/aw-<id>.md` (`/aw-intake` … `/aw-ship`) |
| `commands:` trong `workflow.yaml` | `.claude/commands/aw-<id>.md` (`/aw-import`, `/aw-clarify`, `/aw-bootstrap`) |
| Phase `requires_fresh_agent: true` (`05-review`) | `.claude/agents/independent-reviewer.md` — subagent ngữ cảnh sạch, mang mô tả phase đầy đủ |
| `llm_checker:` (`workflow/checkers/<id>.md`) | `.claude/agents/<id>-checker.md` |
| `approval_gate: true` (`02-design`, `03-plan`) | Bước "Approval gate": `aw approval <phase>` + hộp xác nhận `AskUserQuestion` |
| `workflow.yaml` + tóm tắt luật | `.claude/skills/agent-workflow/SKILL.md` |

Mỗi lệnh phase gồm:

1. **Step 0** — `aw feature $ARGUMENTS`: suy feature từ branch → tham số → hỏi người. Ở checkout
   chính: dừng (trừ `arguments: input` — `/aw-intake` đề xuất worktree — và
   `runs_on_main_checkout: true` — `/aw-ship` dọn việc đã merge). Logic nằm trong script, không
   trong prompt.
2. **Hợp đồng phase** dựng từ frontmatter: đọc gì, ghi gì, mẫu nào, checker LLM, điều kiện ra
   máy/người, file luật phải đọc (`trace_rule: true` thêm `source-tracing.md`).
3. **Mô tả phase** lấy nguyên văn từ thân file nguồn. Riêng phase `requires_fresh_agent`: lệnh
   chỉ bàn giao cho subagent, không nạp mô tả vào phiên chính.

Lệnh tiện ích chỉ có Step 0 và thân file (`argument_hint`, `arguments: mixed` khi tham số có thứ
khác ngoài tên feature). Luật theo loại việc nằm hoàn toàn trong thân phase và checker — adapter
không sinh nhánh nào theo loại.

## Phần không portable và cách xử lý

| Khả năng | Claude Code | Agent không có |
|---|---|---|
| Ngữ cảnh sạch cho review | Subagent `independent-reviewer` | Người tự mở phiên mới — adapter phải ghi rõ |
| Hook gác ô duyệt | `aw guard` (người tự cài, mục dưới) | Chỉ còn lời dặn + dấu duyệt mà `aw check` vẫn kiểm |
| Confluence/Jira | MCP Atlassian | Tải tài liệu về repo, nhãn `[FILE]` |
| Cách gọi | Slash command | Lời dặn / rules của agent đó |
| Checker LLM | Subagent `design-checker`; thiếu file phát hiện thì `aw check design` fail | Người tự chạy; không có file ≠ đạt |
| Câu hỏi lựa chọn (`choice_ui`) | `AskUserQuestion`; "Type something" / "Chat about this" có sẵn nên không thêm vào `options` | In lựa chọn đánh số + lối tự nhập / trao đổi |
| Hộp xác nhận cổng duyệt | `AskUserQuestion` + `preview` (file/dòng phải tick) | In ba lựa chọn đánh số |

Luôn portable: artifact trong `.agent-workflow/<tên-branch>/`, `conventions.md`, mẫu (chép vào
`.agent-workflow/.engine/`), lệnh `aw check`.

## Dọn file cũ khi sinh lại

Sau khi sinh, xoá file trong `.claude/commands/`, `.claude/agents/` **mang dấu "SINH TỰ ĐỘNG"**
mà lần này không sinh ra (lệnh đổi tên/bỏ). File không có dấu đó là người viết — không đụng.

## Hook gác ô duyệt

Thêm vào `.claude/settings.json` (hoặc `settings.local.json`) của repo đích — adapter không tự
ghi file này (ghi đè settings của người khác không đảo ngược được):

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write|Edit|MultiEdit|NotebookEdit|Bash",
        "hooks": [{ "type": "command", "command": "aw guard pre" }] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit|MultiEdit|NotebookEdit|Bash",
        "hooks": [{ "type": "command", "command": "aw guard post" }] }
    ]
  }
}
```

- `pre`: ghi dấu duyệt cho ô người vừa tick, đặt mốc. Luôn cho qua.
- `post`: ô được tick trong lúc lệnh agent chạy (chưa có dấu), hoặc có dấu mà nội dung đổi → bỏ
  tick, trả mã 2 để agent đọc lý do.
- Hai hook **phải cùng matcher** (`post` chỉ bỏ tick khi thấy mốc của `pre`). Bắt cả `sed -i`
  qua Bash vì so trạng thái file.
- Giới hạn: bạn tick đúng lúc lệnh dài của agent đang chạy thì tick bị bỏ — tick lại. Dấu giả do
  agent tự tính thì không phân biệt được.
- Cursor cũng chạy hook này; chạy `aw guard` hai lần là vô hại. Cấu hình cho Cursor:
  [../cursor/README.md](../cursor/README.md#hook-gác-ô-duyệt).

Tuỳ chọn — nhắc chạy checker mỗi lần `spec.md` bị sửa (gây nhiễu khi agent mới viết nửa file;
mặc định cổng chặn đặt ở cuối phase):

```json
{ "hooks": { "PostToolUse": [ { "matcher": "Write|Edit", "hooks": [ { "type": "command",
  "command": "sh -c 'for f in $CLAUDE_FILE_PATHS; do case \"$f\" in *.agent-workflow/*/spec.md) aw check spec \"$(dirname \"$f\")\" >&2 ;; esac; done' || true" } ] } ] } }
```

## Kết quả

| Nhãn | Nghĩa |
|---|---|
| `ĐÃ SINH` | Thành công |
| `SAI THAM SỐ` | Sai tham số |
| `CÓ FILE VIẾT TAY` | Đích có file người viết — `--force` để ghi đè |
| `ĐỊNH NGHĨA QUY TRÌNH LỖI` | Nguồn sai: `exit_machine` không phải `aw check <tên>` có thật, `llm_checker`/`commands:` trỏ file không có, giá trị frontmatter sai, adapter thiếu hook |
| `SAI CHUẨN Claude Code` | File sinh ra không đúng định dạng Claude Code đọc (frontmatter YAML hỏng, khoá ngoài chuẩn, `name` khác tên file…) — file sai không được ghi; xem [../README.md](../README.md#chuẩn-định-dạng-của-agent) |

`ĐỊNH NGHĨA QUY TRÌNH LỖI` giữ "điều kiện ra loại MÁY" luôn là lệnh thật — không thì một dòng chữ
lọt vào và agent tự đánh giá là đạt.
