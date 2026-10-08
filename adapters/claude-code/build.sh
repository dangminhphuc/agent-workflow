#!/usr/bin/env sh
# Adapter Claude Code — bien dich spec trung lap thanh artifact native.
#
#   aw adapter build claude-code [--out <thu-muc>] [--force]
#   (hoặc trực tiếp: sh adapters/claude-code/build.sh --out <thu-muc> [--force])
#
# Sinh ra trong repo dich:
#   .claude/commands/aw-<id>.md            slash command cho tung phase
#   .claude/commands/aw-<id>.md            lenh tien ich (commands: trong manifest) —
#                                       import, clarify, bootstrap
#   .claude/agents/independent-reviewer.md   subagent ra soat (ngu canh sach)
#   .claude/agents/<checker>-checker.md   subagent cho tung checker LLM
#   .claude/skills/agent-workflow/SKILL.md
#
# Lop mong: viec sinh nam o adapters/lib/common.sh (ad_sinh); file nay chi khai
# cac hook rieng cua Claude Code. File sinh ra nam trong .claude/ — aw init them
# vao .git/info/exclude (xem file exclude canh build.sh), khong lot vao commit.
#
# KHONG tu ghi .claude/settings.json — xem README.md muc "Hook".
# Ghi de settings cua repo dich la thao tac khong dao nguoc duoc.

set -e
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
AD_ID=claude-code
AD_TEN="Claude Code"
AD_GOC=.claude
# Chuẩn định dạng Claude Code (docs.claude.com: slash commands, subagents, skills) —
# adapters/lib/format.sh kiểm mọi file sinh ra theo đây trước khi ghi.
AD_LENH_FM=co
AD_LENH_KHOA="description argument-hint allowed-tools model disable-model-invocation"
AD_AGENT_KHOA="name description tools disallowedTools model permissionMode skills hooks color"
AD_SKILL_KHOA="name description allowed-tools model license metadata disable-model-invocation user-invocable argument-hint"
. "$ROOT/adapters/lib/common.sh"

# Claude Code thay $ARGUMENTS bằng phần người gõ sau tên lệnh.
ad_tham_so() { printf '%s' '$ARGUMENTS'; }

ad_dau_lenh() {
  printf -- '---\n'
  # Nháy kép: summary có thể chứa ": " — YAML không nhận ở giá trị không nháy.
  printf 'description: "%s"\n' "$(printf '%s' "$3" | sed 's/[\\"]/\\&/g')"
  # Nháy kép: gợi ý hay mở bằng "[" — YAML không nháy hiểu thành danh sách.
  printf 'argument-hint: "%s"\n' "$(printf '%s' "$4" | sed 's/[\\"]/\\&/g')"
  # Chỉ người gõ /<lệnh> mới chạy: model không tự gọi qua Skill tool.
  printf 'disable-model-invocation: true\n'
  printf -- '---\n\n'
}

ad_mo_dau_lenh() { :; }

# Mục `aw uses`: gọi skill qua Skill tool thì frontmatter (allowed-tools, hook),
# thay tham số và dòng chèn lệnh shell mới có hiệu lực — đọc file thì mất hết.
# Không viết nguyên văn biến tham số hay dấu chấm than liền backtick ở đây:
# Claude Code xử lý chúng ngay trong file lệnh này.
ad_goi_uses() {
  printf -- '- `skill:<name>` → invoke it with the **Skill tool** (`skill: <name>`, `args: %s`) **before the first piece of work**, then follow what it returns. Never just read its file: that drops argument substitution, shell-injection lines, `allowed-tools` and its hooks. Skill tool denied → ask the human to approve it, or to allow `Skill(<name>)` in `.claude/settings.json`; do not fall back to reading.\n' "$FD"
  printf -- '- `agent:<name>` → delegate to that subagent (`subagent_type: <name>`) the work its description covers, passing `%s` and the task. Do not do that work yourself instead.\n\n' "$FD"
}

# Cursor nạp .claude/ để tương thích (bật sẵn): lời dặn dưới đây gọi tool riêng
# của Claude Code, agent khác làm theo sẽ sai mà không ai thấy.
ad_danh_cho() {
  printf '**Dành cho Claude Code.** No `AskUserQuestion` tool = you are another agent (e.g. Cursor loading `.claude/`) → **stop**, use the same-named file in your own folder (Cursor: `.cursor/`).'
}

# Lenh khai choice_ui: true — "cau hoi lua chon" trong mo ta trung lap dich sang
# tool AskUserQuestion cua Claude Code. O "Other" cua tool la lua chon tu nhap.
ad_hoi_lua_chon() {
  printf '## Asking choice questions in Claude Code\n\n'
  printf 'Each question turn = **one `AskUserQuestion` call**, `multiSelect: false`; several decisions of one item = several `questions` entries in the **same** call (max 4). Never print options as text. Question and option text are in Vietnamese.\n\n'
  printf -- '- `question`: one sentence ending with `?`. `header` (≤ 12 chars): id and position, e.g. `YC-001 1/8`.\n'
  printf -- '- `options` (≤ 4) in the order described below; the recommended option'"'"'s `label` **starts with** `(Đề xuất)`; `description` = one-line consequence.\n'
  printf -- '- **Do not** add "Other" or "Chat về câu này": Claude Code already provides "Type something" and "Chat about this". If the human picks "Chat about this" → answer in plain text; once clear, call `AskUserQuestion` again for the same question.\n\n'
}

# Hộp xác nhận của cổng duyệt (approval_gate: true) → AskUserQuestion. preview hiện
# khi người rê vào lựa chọn: để người thấy đúng việc phải làm mà không phải cuộn lên.
ad_hoi_cong_duyet() {
  printf '### Confirmation box in Claude Code\n\n'
  printf '**One `AskUserQuestion` call**, `multiSelect: false`, one question. The ```` ```text ```` stdout block goes **right before** the call (at most one intro sentence).\n\n'
  if [ "$1" = design ]; then
    printf -- '- `question`: `Spec chưa được duyệt nên chưa vào /aw-design được — bạn muốn làm gì?` (stdout says `ĐÃ ĐỔI SAU KHI DUYỆT`: `Spec đã đổi sau khi bạn duyệt nên chưa vào /aw-design được — bạn muốn làm gì?`) · `header`: `Duyệt spec`\n'
  else
    printf -- '- `question`: `Còn <N>/<tổng> quyết định chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?` (numbers from the `Trạng thái` line) · `header`: `Duyệt D-xx`\n'
    printf -- '- Chore (stdout is the **spec** gate): `question` = `Spec chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?`, `header` = `Duyệt spec`.\n'
  fi
  printf -- '- `options` — exactly three, in order, labels verbatim, **no** `(Đề xuất)`:\n'
  printf '  1. `Tôi đã duyệt xong — kiểm lại` · `description`: `Agent chạy lại kiểm tra; đạt thì vào phase ngay.` · `preview`: the `Cách duyệt` part of stdout.\n'
  printf '  2. `Giải thích từng điểm cần duyệt` · `description`: `Agent đi qua từng mục, nói nguồn và hậu quả. Không tick hộ.` · `preview`: the `Nên đọc kỹ…` (spec) or `Chưa duyệt:` (D-xx) part.\n'
  printf '  3. `Dừng — tôi duyệt sau` · `description`: `Không chạy phase này. Duyệt xong thì gõ lại lệnh.`\n'
  printf -- '- No other options (Claude Code adds "Type something", "Chat about this"). Typed text → handle as above ("duyệt hộ" → refuse).\n\n'
}

ad_sinh "$@"
