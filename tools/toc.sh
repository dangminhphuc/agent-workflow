#!/usr/bin/env sh
# Viết lại mục lục "## Contents" của artifact theo heading, mở rộng anchor rút gọn
# trong link (spec.md#yc-001 → spec.md#yc-001--đăng-nhập), rồi kiểm link còn sai.
#
#   aw toc <thư-mục-feature> [artifact...]     bỏ trống artifact = mọi artifact agent viết
#
# Mục lục và anchor do MÁY tính (tools/lib/toc.sh), không để agent tự gõ: gõ sai
# một dấu là link chết. Chỉ ghi file khi nội dung đổi — chạy lại không làm
# artifact phía sau lỗi thời (based_on). Chạy TRƯỚC aw based-on.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai toc.sh \
  "0=ĐÃ KHỚP — mục lục và link trỏ đúng mục" \
  "1=CÒN LINK SAI — sửa theo danh sách phía trên rồi chạy lại" \
  "2=SAI THAM SỐ HOẶC THIẾU FILE"
. "$HERE/lib/toc.sh"

[ $# -ge 1 ] || { echo "Dùng: aw toc <thư-mục-feature> [artifact...]" >&2; exit 2; }
DIR="$1"; shift
[ -d "$DIR" ] || { echo "LỖI: không tìm thấy thư mục $DIR" >&2; exit 2; }

if [ $# -eq 0 ]; then
  for _a in $TOC_ART; do [ -f "$DIR/$_a" ] && set -- "$@" "$_a"; done
  [ $# -gt 0 ] || { echo "LỖI: $DIR chưa có artifact nào ($TOC_ART)" >&2; exit 2; }
else
  for _a in "$@"; do
    case " $TOC_ART " in *" $_a "*) ;; *) echo "LỖI: $_a không phải artifact agent viết ($TOC_ART)" >&2; exit 2 ;; esac
    [ -f "$DIR/$_a" ] || { echo "LỖI: không tìm thấy $DIR/$_a" >&2; exit 2; }
  done
fi

for _a in "$@"; do
  _g=$(toc_ghi "$DIR" "$_a")
  [ -n "$_g" ] && echo "Đã cập nhật: $_a"
done
_l=$(toc_loi "$DIR" "$@")
if [ -n "$_l" ]; then
  printf '%s\n' "$_l" | while IFS= read -r _d; do echo "  [LỖI] $_d"; done
  exit 1
fi
echo "Mục lục và link của $* khớp heading."
