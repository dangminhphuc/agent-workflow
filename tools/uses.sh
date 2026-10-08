#!/usr/bin/env sh
# Liệt kê skill / subagent của repo mà một phase phải GỌI (không chỉ đọc).
#
#   aw uses <phase>        phase: spec design plan implement review
#
# Nguồn: khoá uses_<phase> trong conventions.md của bản clone, mục dạng
# skill:<tên> / agent:<tên>. Đọc lúc chạy như `aw rules` — sửa conventions.md là
# có hiệu lực ngay, không phải build lại. review = chỉ uses_review (skill gọi lúc
# rà soát); file định nghĩa của mọi uses_* thì nằm trong `aw rules review`.
#
# Stdout là DỮ LIỆU: mỗi dòng "<mục> <file>" (file tương đối với gốc repo). Không
# in gì = phase này không gọi gì. Lỗi khai báo in ra stderr.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai uses.sh \
  "0=ĐÃ LIỆT KÊ — gọi từng mục in ra (không in gì = không có)" \
  "1=KHAI SAI — sửa khoá uses_* trong conventions.md, lý do phía trên" \
  "2=SAI THAM SỐ"
. "$HERE/lib/md.sh"
. "$HERE/lib/commands.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/env.sh"
mt_dat

PH="${1:-}"
case " $BL_QUY_TAC " in
  *" $PH "*) [ -n "$PH" ] ;;
  *) false ;;
esac || { echo "Dùng: aw uses <phase>   (phase: $BL_QUY_TAC)" >&2; exit 2; }

loi=$( { kc_quy_tac_khoa_la "$MT_REPO"; kc_uses_loi "$MT_REPO" "$PH"; } )
kc_uses "$MT_REPO" "$PH"
if [ -n "$loi" ]; then
  printf '%s\n' "$loi" | while IFS= read -r l; do echo "  [LỖI] $l" >&2; done
  exit 1
fi
exit 0
