#!/usr/bin/env sh
# Liệt kê quy tắc riêng của repo mà một phase phải đọc và tuân theo.
#
#   aw rules <phase>        phase: spec design plan implement review
#
# Nguồn: khoá rules_<phase> trong conventions.md của bản clone. Đọc lúc chạy,
# không chép vào lệnh của agent lúc `aw adapter build` — sửa conventions.md là có
# hiệu lực ngay, không phải build lại. review = hợp mọi khoá rules_*.
#
# Stdout là DỮ LIỆU: mỗi dòng một đường dẫn (tương đối với gốc repo). Không in
# gì = phase này không có quy tắc riêng. Lỗi khai báo in ra stderr.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai rules.sh \
  "0=ĐÃ LIỆT KÊ — đọc từng file in ra (không in gì = không có quy tắc riêng)" \
  "1=KHAI SAI — sửa khoá rules_* trong conventions.md, lý do phía trên" \
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
esac || { echo "Dùng: aw rules <phase>   (phase: $BL_QUY_TAC)" >&2; exit 2; }

loi=$( { kc_quy_tac_khoa_la "$MT_REPO"; kc_quy_tac_loi "$MT_REPO" "$PH"; } )
kc_quy_tac "$MT_REPO" "$PH"
if [ -n "$loi" ]; then
  printf '%s\n' "$loi" | while IFS= read -r l; do echo "  [LỖI] $l" >&2; done
  exit 1
fi
exit 0
