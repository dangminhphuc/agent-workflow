### Thay đổi
- **`.git/info/exclude` chỉ giấu file adapter tự sinh.** Trước đây `aw init` exclude cả `/.claude/` nên skill, subagent, `settings.json` của team phải `git add -f`. Nay Claude Code chỉ exclude `.claude/commands/aw-*.md`, `.claude/agents/{independent-reviewer,spec-checker,design-checker}.md` và `.claude/skills/agent-workflow/`; Cursor thu hẹp tương tự (`commands/aw-*.md`, các subagent sinh ra, skill `agent-workflow`). Không còn cần `-f`. Repo đã init: chạy lại `aw init` (thêm mẫu hẹp), rồi xoá tay dòng `/.claude/` (và `/.cursor/commands/`, `/.cursor/agents/` nếu có) trong `.git/info/exclude`; engine không tự xoá vì file đó là của người dùng.

### Thêm
- **`aw doctor` cảnh báo dòng exclude rộng cũ** (`/.claude/`, `/.cursor/commands/`, `/.cursor/agents/`) và nói cách xoá; chỉ cảnh báo, không làm doctor thất bại.

### Nội bộ
- Thêm checker LLM hoặc đổi tên file sinh ra thì phải thêm dòng vào `adapters/*/exclude`; test "exclude của adapter" bắt thiếu. Không đổi interface SDLC (adapter).
