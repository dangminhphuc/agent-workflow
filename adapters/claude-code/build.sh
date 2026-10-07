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
  printf '**Dành cho Claude Code.** Không có tool `AskUserQuestion` tức là bạn đang chạy trong agent khác (vd Cursor nạp `.claude/` để tương thích) → **dừng**, dùng lệnh/subagent cùng tên trong thư mục của agent đó (Cursor: `.cursor/`), không làm theo file này.'
}

# Lenh khai choice_ui: true — "cau hoi lua chon" trong mo ta trung lap dich sang
# tool AskUserQuestion cua Claude Code. O "Other" cua tool la lua chon tu nhap.
ad_hoi_lua_chon() {
  printf '## Cách hỏi lựa chọn trong Claude Code\n\n'
  printf 'Mỗi lượt hỏi trong mô tả bên dưới là **một lần gọi tool `AskUserQuestion`**, `multiSelect: false`. Một mục gói nhiều quyết định thì mỗi quyết định là một phần tử của `questions` trong **cùng** lần gọi (tối đa 4). Không in lựa chọn thành văn bản rồi bắt người gõ chữ cái.\n\n'
  printf -- '- **Phân tích trước khi gọi** (mục "Nghĩ kỹ trước khi hỏi"): lựa chọn là phương án giải pháp thật, không phải thủ tục.\n'
  printf -- '- Ngữ cảnh ngắn (nguồn nói gì, vì sao đề xuất) viết thành văn bản **ngay trước** lần gọi, tối đa 4 dòng.\n'
  printf -- '- `question`: câu hỏi, một câu, kết thúc bằng dấu `?`.\n'
  printf -- '- `header` (≤ 12 ký tự): mã và vị trí, vd `YC-001 1/8`.\n'
  printf -- '- `options` (tối đa 4), theo thứ tự mô tả bên dưới; phương án đề xuất đứng đầu, `label` **bắt đầu bằng** `(Đề xuất)`. `description` là hệ quả/đánh đổi một dòng.\n'
  printf -- '- **Không** thêm lựa chọn "Khác" hay "Chat về câu này": Claude Code tự thêm ô "Type something" (lối tự nhập) và "Chat about this" (lối Chat về câu này). Câu trả lời trả về là nhãn được chọn, hoặc nguyên văn người gõ.\n'
  printf -- '- Người chọn "Chat about this" thì trả lời bằng văn bản thường; khi người đã rõ, gọi lại `AskUserQuestion` cho đúng câu đó.\n\n'
}

# Hộp xác nhận của cổng duyệt (approval_gate: true) → AskUserQuestion. preview hiện
# khi người rê vào lựa chọn: để người thấy đúng việc phải làm mà không phải cuộn lên.
ad_hoi_cong_duyet() {
  printf '### Hộp xác nhận trong Claude Code\n\n'
  printf 'Hộp xác nhận là **một lần gọi tool `AskUserQuestion`**, `multiSelect: false`, một phần tử trong `questions`:\n\n'
  if [ "$1" = design ]; then
    printf -- '- `question`: `Spec chưa được duyệt nên chưa vào /aw-design được — bạn muốn làm gì?` (stdout ghi `ĐÃ ĐỔI SAU KHI DUYỆT` thì: `Spec đã đổi sau khi bạn duyệt nên chưa vào /aw-design được — bạn muốn làm gì?`)\n'
    printf -- '- `header`: `Duyệt spec`\n'
  else
    printf -- '- `question`: `Còn <N>/<tổng> quyết định chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?` — số lấy ở dòng `Trạng thái` của stdout.\n'
    printf -- '- `header`: `Duyệt D-xx`\n'
    printf -- '- Việc chore (stdout là cổng duyệt **spec**): `question` là `Spec chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?`, `header` là `Duyệt spec`.\n'
  fi
  printf -- '- `options` (đúng ba, đúng thứ tự, nhãn giữ nguyên; **không** gắn `(Đề xuất)` — đây không phải chọn phương án):\n'
  printf '  1. `label`: `Tôi đã duyệt xong — kiểm lại` · `description`: `Agent chạy lại kiểm tra; đạt thì vào phase ngay.` · `preview`: chép phần `Cách duyệt` của stdout (file, dòng, dòng trước → sau).\n'
  printf '  2. `label`: `Giải thích từng điểm cần duyệt` · `description`: `Agent đi qua từng mục, nói nguồn và hậu quả. Không tick hộ.` · `preview`: chép phần `Nên đọc kỹ…` (spec) hoặc `Chưa duyệt:` (D-xx) của stdout.\n'
  printf '  3. `label`: `Dừng — tôi duyệt sau` · `description`: `Không chạy phase này. Duyệt xong thì gõ lại lệnh.` · không cần `preview`.\n'
  printf -- '- Claude Code tự thêm ô "Type something" và "Chat about this" — không thêm lựa chọn nào khác. Người gõ chữ thì xử lý như mô tả ở trên (kể cả "duyệt hộ" → từ chối).\n'
  printf -- '- Khối ```` ```text ```` in stdout đứng **ngay trước** lần gọi, không chen lời dẫn dài; tối đa một câu mở đầu.\n\n'
}

ad_sinh "$@"
