#!/usr/bin/env sh
# ADR của repo đích (tools/lib/adr.sh).
#
#   aw adr promote <thư-mục-feature> D-NN   chép D-NN đã duyệt thành ADR trong worktree
#   aw adr check                            kiểm hình thức thư mục ADR (knowledge_adr_dir)
#
# promote chỉ chạy khi NGƯỜI đã quyết trong chính D đó — "Promote: adr" nằm dưới dấu
# duyệt — và D đang ở trạng thái đã duyệt (dấu duyệt khớp). Agent không tự chọn D
# nào được nâng, không truyền "supersedes" bằng tham số: "Supersedes: ADR-NNNN" cũng
# nằm trong D. Chạy lại an toàn: ADR của cùng việc + D giữ số cũ, viết lại nội dung.
# Không commit gì.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
case "${1:-}" in
  promote) kq_khai adr.sh \
    "0=ĐÃ NÂNG — ADR và chỉ mục đã ghi trong worktree, commit cùng việc" \
    "1=TỪ CHỐI — D chưa đủ điều kiện, lý do phía trên; không sửa ADR bằng tay" \
    "2=SAI THAM SỐ" ;;
  *) kq_khai adr.sh \
    "0=HỢP LỆ" \
    "1=KHÔNG HỢP LỆ — sửa các dòng ✗" \
    "2=SAI THAM SỐ" ;;
esac
. "$HERE/lib/md.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/approval-tick.sh"
. "$HERE/lib/adr.sh"
. "$HERE/lib/env.sh"
mt_dat

DUNG="Dùng: aw adr promote <thư-mục-feature> D-NN | aw adr check"
LENH="${1:-}"; [ $# -gt 0 ] && shift
TM=$(adr_thu_muc "$MT_CONV"); D_ADR="$MT_REPO/$TM"

case "$LENH" in
  check)
    [ $# -eq 0 ] || { echo "$DUNG" >&2; exit 2; }
    echo "Kiểm $TM/"
    l=$(adr_loi_hinh_thuc "$D_ADR")
    if [ -n "$l" ]; then
      printf '%s\n' "$l" | while IFS= read -r x; do echo "  ✗ $x"; done
      exit 1
    fi
    echo "  ✓ $(adr_ds "$D_ADR" | grep -c .) ADR, chỉ mục khớp"
    exit 0 ;;
  promote) ;;
  *) echo "$DUNG" >&2; exit 2 ;;
esac

[ $# -eq 2 ] || { echo "$DUNG" >&2; exit 2; }
DIR=${1%/}; D=$2
case "$D" in D-[0-9]*) ;; *) echo "LỖI: \"$D\" không phải mã D-NN." >&2; exit 2 ;; esac
TDD="$DIR/tdd.md"
for f in "$TDD" "$DIR/plan.md" "$DIR/spec.md"; do
  [ -f "$f" ] || { echo "LỖI: không có $f" >&2; exit 2; }
done

tu_choi() { echo "  ✗ $1"; n_tc=$((n_tc + 1)); }
n_tc=0
dy_dong_dau "$TDD" tdd >/dev/null
tt=$(dy_trang_thai "$TDD" tdd | awk -F'|' -v d="$D" '$1 == "S" && $2 == d { print $3; exit }')
[ -n "$tt" ] || { echo "LỖI: tdd.md không có $D." >&2; exit 2; }
[ "$tt" = approved ] || tu_choi "$D chưa được người duyệt ($tt) — chỉ nâng D đã duyệt"
[ "$(d_truong "$TDD" "$D" Promote)" = adr ] ||
  tu_choi "$D không khai \"- Promote: adr\" — người quyết nâng D nào, trong chính D đó (dưới ô duyệt)"
SC=$(d_truong "$TDD" "$D" Scope)
case "$SC" in ""|"<"*) tu_choi "$D thiếu \"- Scope: \`<glob>\`\" — phần code ADR ràng buộc" ;; esac
SS=$(d_truong "$TDD" "$D" Supersedes); SO_CU=""
case "$SS" in
  ""|none|None|no) ;;
  ADR-[0-9][0-9][0-9][0-9])
    SO_CU=${SS#ADR-}
    set -- "$D_ADR/$SO_CU"-*.md
    if [ ! -f "$1" ]; then tu_choi "$D: Supersedes $SS nhưng không có ADR $SO_CU trong $TM/"; F_CU=""
    else F_CU=$1; fi ;;
  *) tu_choi "$D: Supersedes \"$SS\" — dạng ADR-NNNN" ;;
esac
VIEC=$(basename "$DIR")
CU=$(adr_cua_d "$D_ADR" "$VIEC" "$D")
if [ -n "$CU" ]; then SO=$(basename "$CU" | cut -c1-4)
else SO=$(adr_so_moi "$D_ADR"); fi
if [ -n "$SO_CU" ] && [ -n "${F_CU:-}" ]; then
  case "$(adr_truong "$F_CU" Status)" in
    accepted|"superseded by $SO") ;;
    *) tu_choi "$SS đã \"$(adr_truong "$F_CU" Status)\" — chỉ thay được ADR accepted" ;;
  esac
fi
[ "$n_tc" = 0 ] || { echo ""; echo "Không nâng $D."; exit 1; }

mkdir -p "$D_ADR" || exit 2
DICH="$D_ADR/$SO-$(printf '%s' "$VIEC" | tr 'A-Z' 'a-z')-$(printf '%s' "$D" | tr 'A-Z' 'a-z').md"
[ -z "$CU" ] || [ "$CU" = "$DICH" ] || rm -f "$CU"
adr_noi_dung "$DIR" "$D" "$SO" "$(date +%Y-%m-%d)" > "$DICH.tam.$$" && mv "$DICH.tam.$$" "$DICH"
echo "  ghi     $TM/$(basename "$DICH")"
if [ -n "${F_CU:-}" ]; then
  awk -v so="$SO" '
    { cr = sub(/\r$/, "") }
    !xong && /^- Status:/ { $0 = "- Status: superseded by " so; xong = 1 }
    { printf "%s%s\n", $0, (cr ? "\r" : "") }
  ' "$F_CU" > "$F_CU.tam.$$" && mv "$F_CU.tam.$$" "$F_CU"
  echo "  sửa     $TM/$(basename "$F_CU") → superseded by $SO"
fi
adr_lam_chi_muc "$D_ADR"
echo "  ghi     $TM/README.md (chỉ mục)"
l=$(adr_loi_hinh_thuc "$D_ADR")
if [ -n "$l" ]; then
  printf '%s\n' "$l" | while IFS= read -r x; do echo "  ✗ $x"; done
  echo ""; echo "Đã ghi nhưng thư mục ADR còn lỗi hình thức — sửa rồi chạy aw adr check."; exit 1
fi
echo ""
echo "Đã nâng $D thành ADR-$SO. Commit cùng việc này (nằm trong \"Expected files\" của task nâng)."
exit 0
