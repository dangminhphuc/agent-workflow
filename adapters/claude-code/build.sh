#!/usr/bin/env sh
# Adapter Claude Code — bien dich spec trung lap thanh artifact native.
#
#   aw adapter build claude-code [--out <thu-muc>] [--force]
#   (hoặc trực tiếp: sh adapters/claude-code/build.sh --out <thu-muc> [--force])
#
# Sinh ra trong repo dich:
#   .claude/commands/aw-<id>.md            slash command cho tung phase
#   .claude/commands/aw-<id>.md            lenh tien ich (commands: trong manifest) —
#                                       import, clarify
#   .claude/agents/ra-soat-doc-lap.md   subagent ra soat (ngu canh sach)
#   .claude/agents/soat-<checker>.md    subagent cho tung checker LLM
#   .claude/skills/quy-trinh-agent/SKILL.md
#
# Lop mong: viec sinh nam o adapters/lib/chung.sh (ad_sinh); file nay chi khai
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
. "$ROOT/adapters/lib/chung.sh"

# Claude Code thay $ARGUMENTS bằng phần người gõ sau tên lệnh.
ad_tham_so() { printf '%s' '$ARGUMENTS'; }

ad_dau_lenh() {
  printf -- '---\n'
  # Nháy kép: summary có thể chứa ": " — YAML không nhận ở giá trị không nháy.
  printf 'description: "%s"\n' "$(printf '%s' "$3" | sed 's/[\\"]/\\&/g')"
  printf 'argument-hint: %s\n' "$4"
  printf -- '---\n\n'
}

ad_mo_dau_lenh() { :; }

# Cursor nạp .claude/ để tương thích (bật sẵn): lời dặn dưới đây gọi tool riêng
# của Claude Code, agent khác làm theo sẽ sai mà không ai thấy.
ad_danh_cho() {
  printf '**Dành cho Claude Code.** Không có tool `AskUserQuestion` = bạn là agent khác (vd Cursor nạp `.claude/`) → **dừng**, dùng bản cùng tên trong thư mục của agent đó (Cursor: `.cursor/`).'
}

# Lenh khai choice_ui: true — "cau hoi lua chon" trong mo ta trung lap dich sang
# tool AskUserQuestion cua Claude Code. O "Other" cua tool la lua chon tu nhap.
ad_hoi_lua_chon() {
  printf '## Cách hỏi lựa chọn trong Claude Code\n\n'
  printf 'Mỗi lượt hỏi = **một lần gọi `AskUserQuestion`**, `multiSelect: false`; nhiều quyết định của một mục = nhiều phần tử `questions` trong **cùng** lần gọi (tối đa 4). Không in lựa chọn thành văn bản.\n\n'
  printf -- '- `question`: một câu, kết thúc `?`. `header` (≤ 12 ký tự): mã và vị trí, vd `YC-001 1/8`.\n'
  printf -- '- `options` (≤ 4) theo thứ tự mô tả bên dưới; `label` của phương án đề xuất **bắt đầu bằng** `(Đề xuất)`; `description` = hệ quả một dòng.\n'
  printf -- '- **Không** thêm "Khác" hay "Chat về câu này": Claude Code tự có "Type something" và "Chat about this". Người chọn "Chat about this" → trả lời văn bản thường; rõ rồi thì gọi lại `AskUserQuestion` cho đúng câu đó.\n\n'
}

# Hộp xác nhận của cổng duyệt (approval_gate: true) → AskUserQuestion. preview hiện
# khi người rê vào lựa chọn: để người thấy đúng việc phải làm mà không phải cuộn lên.
ad_hoi_cong_duyet() {
  printf '### Hộp xác nhận trong Claude Code\n\n'
  printf '**Một lần gọi `AskUserQuestion`**, `multiSelect: false`, một câu hỏi. Khối ```` ```text ```` stdout đứng **ngay trước** lần gọi (tối đa một câu mở đầu).\n\n'
  if [ "$1" = design ]; then
    printf -- '- `question`: `Spec chưa được duyệt nên chưa vào /aw-design được — bạn muốn làm gì?` (stdout ghi `ĐÃ ĐỔI SAU KHI DUYỆT`: `Spec đã đổi sau khi bạn duyệt nên chưa vào /aw-design được — bạn muốn làm gì?`) · `header`: `Duyệt spec`\n'
  else
    printf -- '- `question`: `Còn <N>/<tổng> quyết định chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?` (số lấy ở dòng `Trạng thái`) · `header`: `Duyệt D-xx`\n'
    printf -- '- Chore (stdout là cổng duyệt **spec**): `question` = `Spec chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?`, `header` = `Duyệt spec`.\n'
  fi
  printf -- '- `options` — đúng ba, đúng thứ tự, nhãn giữ nguyên, **không** gắn `(Đề xuất)`:\n'
  printf '  1. `Tôi đã duyệt xong — kiểm lại` · `description`: `Agent chạy lại kiểm tra; đạt thì vào phase ngay.` · `preview`: phần `Cách duyệt` của stdout.\n'
  printf '  2. `Giải thích từng điểm cần duyệt` · `description`: `Agent đi qua từng mục, nói nguồn và hậu quả. Không tick hộ.` · `preview`: phần `Nên đọc kỹ…` (spec) hoặc `Chưa duyệt:` (D-xx).\n'
  printf '  3. `Dừng — tôi duyệt sau` · `description`: `Không chạy phase này. Duyệt xong thì gõ lại lệnh.`\n'
  printf -- '- Không thêm lựa chọn khác (Claude Code tự có "Type something", "Chat about this"). Người gõ chữ → xử lý như trên (kể cả "duyệt hộ" → từ chối).\n\n'
}

ad_sinh "$@"
