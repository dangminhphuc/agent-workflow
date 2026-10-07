#!/usr/bin/env sh
# Adapter Cursor — bien dich spec trung lap thanh artifact native cua Cursor.
#
#   aw adapter build cursor [--out <thu-muc>] [--force]
#   (hoặc trực tiếp: sh adapters/cursor/build.sh --out <thu-muc> [--force])
#
# Sinh ra trong repo dich:
#   .cursor/commands/<id>.md            lenh / cho tung phase va lenh tien ich
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
  printf '# /%s — %s\n\n' "$1" "$2"
}

ad_mo_dau_lenh() {
  printf '## Tham số của lệnh trong Cursor\n\n'
  printf 'Cursor không thay biến trong file lệnh: phần chữ người dùng gõ sau `/%s` (gợi ý: `%s`) đi kèm tin nhắn, ngay sau nội dung này. Bên dưới, `<tham-số>` là **đúng phần chữ đó, chép nguyên văn** — không tóm tắt, không sửa chính tả, không thêm bớt dấu nháy.\n\n' "$1" "$2"
  printf -- '- Người không gõ gì sau `/%s`: `<tham-số>` rỗng → bỏ hẳn nó khỏi lệnh `aw …` (chạy `aw feature`, không phải `aw feature ""`).\n' "$1"
  if [ "$3" = "input" ]; then
    printf -- '- Người không gõ gì thì dòng giữa heredoc của `aw input` để trống — engine trả `KHÔNG CÓ THAM SỐ`.\n'
  fi
  printf -- '- **Không bao giờ** chạy lệnh còn nguyên chữ `<tham-số>`: engine từ chối (`SAI CÁCH GỌI` / `TÊN KHÔNG HỢP LỆ`).\n\n'
}

ad_danh_cho() {
  printf '**Dành cho Cursor.** Bản cho Claude Code nằm ở `.claude/` và Cursor cũng nạp được thư mục đó: gặp lệnh, subagent hay skill cùng tên thì dùng bản trong `.cursor/` này, không làm theo bản `.claude/`.'
}

# Lenh khai choice_ui: true. Cursor co the co tool hoi lua chon, co the khong (tuy
# ban, IDE hay CLI) — loi dan phai chay dung ca hai truong hop, va luon chua loi
# tu nhap / "Chat ve cau nay" vi khong chac tool tu them.
ad_hoi_lua_chon() {
  printf '## Cách hỏi lựa chọn trong Cursor\n\n'
  printf 'Mỗi lượt hỏi trong mô tả bên dưới là **một câu hỏi lựa chọn**; hỏi xong thì **dừng chờ** người trả lời. Một mục gói nhiều quyết định thì hỏi từng quyết định một, trong cùng một lượt.\n\n'
  printf -- '- **Phân tích trước khi hỏi** (mục "Nghĩ kỹ trước khi hỏi"): lựa chọn là phương án giải pháp thật, không phải thủ tục.\n'
  printf -- '- Ngữ cảnh ngắn (nguồn nói gì, vì sao đề xuất) viết **ngay trước** câu hỏi, tối đa 4 dòng.\n'
  printf -- '- Câu hỏi: một câu, kết thúc bằng dấu `?`, mở đầu bằng mã và vị trí, vd `YC-001 1/8`.\n'
  printf -- '- Tối đa 4 lựa chọn, theo thứ tự mô tả bên dưới; phương án đề xuất đứng đầu, nhãn **bắt đầu bằng** `(Đề xuất)`. Mỗi lựa chọn kèm hệ quả/đánh đổi một dòng.\n'
  printf -- '- Phiên có tool hỏi lựa chọn của Cursor (vd `AskQuestion`) thì dùng nó. Không có tool, hoặc tool lỗi: in lựa chọn đánh số `1.` `2.` … — người trả lời bằng số hoặc bằng chữ.\n'
  printf -- '- **Luôn** có hai lối ngoài các lựa chọn: tự nhập câu trả lời khác, và "Chat về câu này". Tool không tự có hai lối đó thì ghi dòng cuối: `Hoặc gõ câu trả lời khác / hỏi lại để trao đổi về câu này.` Không bao giờ để người chỉ còn các lựa chọn cố định.\n'
  printf -- '- Người muốn trao đổi thì trả lời bằng văn bản thường; khi người đã rõ, hỏi lại đúng câu đó.\n\n'
}

# Hộp xác nhận của cổng duyệt (approval_gate: true). Câu hỏi và ba nhãn giống hệt
# bản Claude Code (test đối chiếu kiểm); Cursor không có preview nên phần
# "Cách duyệt" phải nằm nguyên trong khối text in ngay trước.
ad_hoi_cong_duyet() {
  printf '### Hộp xác nhận trong Cursor\n\n'
  printf 'Hộp xác nhận là **một câu hỏi lựa chọn**: có tool hỏi lựa chọn của Cursor (vd `AskQuestion`) thì dùng nó; không có thì in ba lựa chọn đánh số rồi dừng chờ người trả lời.\n\n'
  if [ "$1" = design ]; then
    printf -- '- Câu hỏi: `Spec chưa được duyệt nên chưa vào /design được — bạn muốn làm gì?` (stdout ghi `ĐÃ ĐỔI SAU KHI DUYỆT` thì: `Spec đã đổi sau khi bạn duyệt nên chưa vào /design được — bạn muốn làm gì?`)\n'
  else
    printf -- '- Câu hỏi: `Còn <N>/<tổng> quyết định chưa được duyệt nên chưa vào /plan được — bạn muốn làm gì?` — số lấy ở dòng `Trạng thái` của stdout.\n'
    printf -- '- Việc chore (stdout là cổng duyệt **spec**): câu hỏi là `Spec chưa được duyệt nên chưa vào /plan được — bạn muốn làm gì?`.\n'
  fi
  printf -- '- Lựa chọn (đúng ba, đúng thứ tự, nhãn giữ nguyên; **không** gắn `(Đề xuất)` — đây không phải chọn phương án):\n'
  printf '  1. `Tôi đã duyệt xong — kiểm lại` — Agent chạy lại kiểm tra; đạt thì vào phase ngay.\n'
  printf '  2. `Giải thích từng điểm cần duyệt` — Agent đi qua từng mục, nói nguồn và hậu quả. Không tick hộ.\n'
  printf '  3. `Dừng — tôi duyệt sau` — Không chạy phase này. Duyệt xong thì gõ lại lệnh.\n'
  printf -- '- Không thêm lựa chọn nào khác. Người gõ chữ thay vì chọn thì xử lý như mô tả ở trên (kể cả "duyệt hộ" → từ chối).\n'
  printf -- '- Cursor không có ô xem trước khi rê chuột: phần `Cách duyệt` (file, dòng phải tick) nằm trong khối ```` ```text ```` in **ngay trước** câu hỏi — in đủ, không cắt; tối đa một câu mở đầu.\n\n'
}

ad_sinh "$@"
