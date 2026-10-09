#!/usr/bin/env sh
# Adapter Cursor — bien dich spec trung lap thanh artifact native cua Cursor.
#
#   aw adapter build cursor [--out <thu-muc>] [--force]
#   (hoặc trực tiếp: sh adapters/cursor/build.sh --out <thu-muc> [--force])
#
# Sinh ra trong repo dich:
#   .cursor/commands/aw-<id>.md            lenh / cho tung phase va lenh tien ich
#   .cursor/agents/independent-reviewer.md   subagent ra soat (ngu canh sach)
#   .cursor/agents/<checker>-checker.md   subagent cho tung checker LLM
#   .cursor/skills/agent-workflow/SKILL.md
#
# Ten lenh / subagent / skill TRUNG voi adapter Claude Code: Cursor nap ca .claude/
# (che do tuong thich, bat san) va uu tien .cursor/ khi trung ten — ban nay che
# ban cua Claude Code. File cua Claude Code con dong "Danh cho Claude Code" de
# Cursor nap nham thi dung.
#
# Lop mong: viec sinh nam o adapters/lib/common.sh (ad_sinh); file nay chi khai
# cac hook rieng cua Cursor. KHONG tu ghi .cursor/hooks.json — xem README.md.

set -e
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
AD_ID=cursor
AD_TEN=Cursor
AD_GOC=.cursor
# Chuẩn định dạng Cursor (cursor.com/docs: commands, subagents, skills) — lệnh là
# markdown thường; adapters/lib/format.sh kiểm mọi file sinh ra trước khi ghi.
AD_LENH_FM=khong
AD_LENH_KHOA=""
AD_AGENT_KHOA="name description model readonly is_background"
AD_SKILL_KHOA="name description license compatibility metadata allowed-tools disable-model-invocation"
. "$ROOT/adapters/lib/common.sh"

# Cursor không thay biến trong file lệnh: phần người gõ sau tên lệnh đi kèm tin
# nhắn. Lời dặn gọi nó là <tham-số>; ad_mo_dau_lenh nói cách chép. Engine từ chối
# chữ <tham-số> còn nguyên (aw input, aw feature) — agent quên thay thì bị chặn.
ad_tham_so() { printf '%s' '<tham-số>'; }

# Lệnh của Cursor là markdown thường — không frontmatter.
ad_dau_lenh() {
  printf '# /%s — %s\n\n%s\n\n' "$1" "$2" "$3"
}

ad_mo_dau_lenh() {
  printf '## Command arguments in Cursor\n\n'
  printf 'Cursor does not substitute variables: the text typed after `/%s` (hint: `%s`) comes with the message. Below, `<tham-số>` means **exactly that text, copied verbatim** (no summarising, no fixes, no added/removed quotes).\n\n' "$1" "$2"
  printf -- '- Nothing typed: drop `<tham-số>` from `aw …` entirely (`aw feature`, not `aw feature ""`).\n'
  if [ "$3" = "input" ]; then
    printf -- '- Nothing typed: leave the line inside the `aw input` heredoc empty — the engine returns `KHÔNG CÓ THAM SỐ`.\n'
  fi
  printf -- '- **Never** run a command still containing the literal `<tham-số>` (the engine refuses: `SAI CÁCH GỌI` / `TÊN KHÔNG HỢP LỆ`).\n\n'
}

# Mục `aw uses`. POC với cursor-agent (2026-10): không có tool gọi skill theo tên,
# agent tự đọc SKILL.md — frontmatter của skill không có hiệu lực. Bản Cursor nào
# có tool đó thì dùng; không thì đọc file như chỉ dẫn.
ad_goi_uses() {
  printf -- '- `skill:<name>` → if you have a tool that invokes a skill by name, use it with `<name>`; otherwise **read the printed file** and follow it as instructions — **before the first piece of work**. Paths it mentions are relative to its own folder; its frontmatter (e.g. `allowed-tools`) does not apply.\n'
  printf -- '- `agent:<name>` → delegate to subagent `<name>` the work its description covers, passing `%s` and the task (Cursor loads `.cursor/agents/` and `.claude/agents/`). No subagent support → read the printed file and do that work in this session following it.\n\n' "$FD"
}

ad_danh_cho() {
  printf '**Dành cho Cursor:** Cursor also loads `.claude/` — for a same-named command, subagent or skill, use this `.cursor/` copy.'
}

# Lenh khai choice_ui: true. Cursor co the co tool hoi lua chon, co the khong (tuy
# ban, IDE hay CLI) — loi dan phai chay dung ca hai truong hop, va luon chua loi
# tu nhap / "Chat ve cau nay" vi khong chac tool tu them.
ad_hoi_lua_chon() {
  printf '## Asking choice questions in Cursor\n\n'
  printf 'Each question turn = **one choice question**, then **stop and wait**. Several decisions of one item: ask each, in the same turn. Question and option text are in Vietnamese.\n\n'
  printf -- '- Question: one sentence ending with `?`, starting with the header named below, else id and position, e.g. `YC-001 1/8`.\n'
  printf -- '- ≤ 4 options in the order described below; the recommended label **starts with** `(Đề xuất)`; each option has a one-line consequence.\n'
  printf -- '- If a Cursor choice tool exists (e.g. `AskQuestion`), use it. None or it fails: print numbered options `1.` `2.` … — the human answers by number or text.\n'
  printf -- '- **Always** keep the free-text and "Chat about this" exits. If the tool does not add them, end with the line: `Hoặc gõ câu trả lời khác / hỏi lại để trao đổi về câu này.`\n\n'
}

# Hộp xác nhận của cổng duyệt (approval_gate: true). Câu hỏi và ba nhãn giống hệt
# bản Claude Code (test đối chiếu kiểm); Cursor không có preview nên phần
# "Cách duyệt" phải nằm nguyên trong khối text in ngay trước.
ad_hoi_cong_duyet() {
  printf '### Confirmation box in Cursor\n\n'
  printf '**One choice question**: use a Cursor choice tool (e.g. `AskQuestion`) if present; otherwise print the three numbered options and wait. Cursor has no hover preview: the `Cách duyệt` part must be **complete** in the ```` ```text ```` block printed right before the question.\n\n'
  if [ "$1" = design ]; then
    printf -- '- Question: `Spec chưa được duyệt nên chưa vào /aw-design được — bạn muốn làm gì?` (stdout says `ĐÃ ĐỔI SAU KHI DUYỆT`: `Spec đã đổi sau khi bạn duyệt nên chưa vào /aw-design được — bạn muốn làm gì?`)\n'
  else
    printf -- '- Question: `Còn <N>/<tổng> quyết định chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?` (numbers from the `Trạng thái` line)\n'
    printf -- '- Chore (stdout is the **spec** gate): `Spec chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?`\n'
  fi
  printf -- '- Options — exactly three, in order, labels verbatim, **no** `(Đề xuất)`:\n'
  printf '  1. `Tôi đã duyệt xong — kiểm lại` — chạy lại kiểm tra; đạt thì vào phase ngay.\n'
  printf '  2. `Giải thích từng điểm cần duyệt` — đi qua từng mục, nói nguồn và hậu quả. Không tick hộ.\n'
  printf '  3. `Dừng — tôi duyệt sau` — không chạy phase này; duyệt xong gõ lại lệnh.\n'
  printf -- '- No other options. Typed text → handle as above ("duyệt hộ" → refuse).\n\n'
}

ad_sinh "$@"
