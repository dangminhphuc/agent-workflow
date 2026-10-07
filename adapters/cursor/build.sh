#!/usr/bin/env sh
# Adapter Cursor — bien dich spec trung lap thanh artifact native cua Cursor.
#
#   aw adapter build cursor [--out <thu-muc>] [--force]
#   (hoặc trực tiếp: sh adapters/cursor/build.sh --out <thu-muc> [--force])
#
# Sinh ra trong repo dich:
#   .cursor/commands/aw-<id>.md            lenh / cho tung phase va lenh tien ich
#   .cursor/agents/ra-soat-doc-lap.md   subagent ra soat (ngu canh sach)
#   .cursor/agents/soat-<checker>.md    subagent cho tung checker LLM
#   .cursor/skills/quy-trinh-agent/SKILL.md
#
# Ten lenh / subagent / skill TRUNG voi adapter Claude Code: Cursor nap ca .claude/
# (che do tuong thich, bat san) va uu tien .cursor/ khi trung ten — ban nay che
# ban cua Claude Code. File cua Claude Code con dong "Danh cho Claude Code" de
# Cursor nap nham thi dung.
#
# Lop mong: viec sinh nam o adapters/lib/chung.sh (ad_sinh); file nay chi khai
# cac hook rieng cua Cursor. KHONG tu ghi .cursor/hooks.json — xem README.md.

set -e
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
AD_ID=cursor
AD_TEN=Cursor
AD_GOC=.cursor
. "$ROOT/adapters/lib/chung.sh"

# Cursor không thay biến trong file lệnh: phần người gõ sau tên lệnh đi kèm tin
# nhắn. Lời dặn gọi nó là <tham-số>; ad_mo_dau_lenh nói cách chép. Engine từ chối
# chữ <tham-số> còn nguyên (aw input, aw feature) — agent quên thay thì bị chặn.
ad_tham_so() { printf '%s' '<tham-số>'; }

# Lệnh của Cursor là markdown thường — không frontmatter.
ad_dau_lenh() {
  printf '# /%s — %s\n\n%s\n\n' "$1" "$2" "$3"
}

ad_mo_dau_lenh() {
  printf '## Tham số của lệnh trong Cursor\n\n'
  printf 'Cursor không thay biến: phần chữ người gõ sau `/%s` (gợi ý: `%s`) đi kèm tin nhắn. Bên dưới, `<tham-số>` là **đúng phần chữ đó, chép nguyên văn** (không tóm tắt, không sửa, không thêm bớt dấu nháy).\n\n' "$1" "$2"
  printf -- '- Không gõ gì: bỏ hẳn `<tham-số>` khỏi lệnh `aw …` (`aw feature`, không phải `aw feature ""`).\n'
  if [ "$3" = "input" ]; then
    printf -- '- Không gõ gì: dòng giữa heredoc của `aw input` để trống — engine trả `KHÔNG CÓ THAM SỐ`.\n'
  fi
  printf -- '- **Không bao giờ** chạy lệnh còn nguyên chữ `<tham-số>` (engine từ chối: `SAI CÁCH GỌI` / `TÊN KHÔNG HỢP LỆ`).\n\n'
}

ad_danh_cho() {
  printf '**Dành cho Cursor.** Cursor cũng nạp bản Claude Code ở `.claude/`: gặp lệnh, subagent, skill cùng tên thì dùng bản `.cursor/` này.'
}

# Lenh khai choice_ui: true. Cursor co the co tool hoi lua chon, co the khong (tuy
# ban, IDE hay CLI) — loi dan phai chay dung ca hai truong hop, va luon chua loi
# tu nhap / "Chat ve cau nay" vi khong chac tool tu them.
ad_hoi_lua_chon() {
  printf '## Cách hỏi lựa chọn trong Cursor\n\n'
  printf 'Mỗi lượt hỏi = **một câu hỏi lựa chọn**, hỏi xong **dừng chờ** người. Nhiều quyết định của một mục: hỏi từng cái, trong cùng lượt.\n\n'
  printf -- '- Câu hỏi: một câu, kết thúc `?`, mở đầu bằng mã và vị trí, vd `YC-001 1/8`.\n'
  printf -- '- ≤ 4 lựa chọn theo thứ tự mô tả bên dưới; nhãn phương án đề xuất **bắt đầu bằng** `(Đề xuất)`; mỗi lựa chọn kèm hệ quả một dòng.\n'
  printf -- '- Có tool hỏi lựa chọn của Cursor (vd `AskQuestion`) thì dùng. Không có hoặc lỗi: in lựa chọn đánh số `1.` `2.` … — người trả lời bằng số hoặc chữ.\n'
  printf -- '- **Luôn** còn lối tự nhập và "Chat về câu này". Tool không tự có thì ghi dòng cuối: `Hoặc gõ câu trả lời khác / hỏi lại để trao đổi về câu này.`\n\n'
}

# Hộp xác nhận của cổng duyệt (approval_gate: true). Câu hỏi và ba nhãn giống hệt
# bản Claude Code (test đối chiếu kiểm); Cursor không có preview nên phần
# "Cách duyệt" phải nằm nguyên trong khối text in ngay trước.
ad_hoi_cong_duyet() {
  printf '### Hộp xác nhận trong Cursor\n\n'
  printf '**Một câu hỏi lựa chọn**: có tool (vd `AskQuestion`) thì dùng; không thì in ba lựa chọn đánh số rồi dừng chờ. Cursor không có ô xem trước: phần `Cách duyệt` phải nằm **đủ** trong khối ```` ```text ```` in ngay trước câu hỏi.\n\n'
  if [ "$1" = design ]; then
    printf -- '- Câu hỏi: `Spec chưa được duyệt nên chưa vào /aw-design được — bạn muốn làm gì?` (stdout ghi `ĐÃ ĐỔI SAU KHI DUYỆT`: `Spec đã đổi sau khi bạn duyệt nên chưa vào /aw-design được — bạn muốn làm gì?`)\n'
  else
    printf -- '- Câu hỏi: `Còn <N>/<tổng> quyết định chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?` (số lấy ở dòng `Trạng thái`)\n'
    printf -- '- Chore (stdout là cổng duyệt **spec**): `Spec chưa được duyệt nên chưa vào /aw-plan được — bạn muốn làm gì?`\n'
  fi
  printf -- '- Lựa chọn — đúng ba, đúng thứ tự, nhãn giữ nguyên, **không** gắn `(Đề xuất)`:\n'
  printf '  1. `Tôi đã duyệt xong — kiểm lại` — chạy lại kiểm tra; đạt thì vào phase ngay.\n'
  printf '  2. `Giải thích từng điểm cần duyệt` — đi qua từng mục, nói nguồn và hậu quả. Không tick hộ.\n'
  printf '  3. `Dừng — tôi duyệt sau` — không chạy phase này; duyệt xong gõ lại lệnh.\n'
  printf -- '- Không thêm lựa chọn khác. Người gõ chữ → xử lý như trên (kể cả "duyệt hộ" → từ chối).\n\n'
}

ad_sinh "$@"
