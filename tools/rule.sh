#!/usr/bin/env sh
# Luật nghiệp vụ bền của repo đích (tools/lib/rule.sh).
#
#   aw rule promote <thư-mục-feature> YC-NNN   chép YC đã duyệt thành khối luật BR- trong worktree
#   aw rule check                              kiểm hình thức mọi khối luật trong repo
#
# promote chỉ chạy khi NGƯỜI đã quyết trong chính YC đó — "Promote: BR-<MIỀN>-NNN"
# nằm dưới dấu duyệt spec — và spec đang ở trạng thái đã duyệt. ID, file đích, nội dung
# đều lấy từ artifact đã duyệt; không có tham số nào để agent tự chọn. Chạy lại an toàn:
# khối của cùng việc + YC được viết lại tại chỗ. Không commit gì.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
case "${1:-}" in
  promote) kq_khai rule.sh \
    "0=ĐÃ NÂNG — khối luật đã ghi trong worktree, commit cùng việc" \
    "1=TỪ CHỐI — YC chưa đủ điều kiện, lý do phía trên; không viết luật bằng tay" \
    "2=SAI THAM SỐ" ;;
  *) kq_khai rule.sh \
    "0=HỢP LỆ — đọc các dòng ! (nếu có)" \
    "1=KHÔNG HỢP LỆ — sửa các dòng ✗" \
    "2=SAI THAM SỐ" ;;
esac
. "$HERE/lib/md.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/approval-tick.sh"
. "$HERE/lib/adr.sh"
. "$HERE/lib/rule.sh"
. "$HERE/lib/env.sh"
mt_dat

DUNG="Dùng: aw rule promote <thư-mục-feature> YC-NNN | aw rule check"
LENH="${1:-}"; [ $# -gt 0 ] && shift

case "$LENH" in
  check)
    [ $# -eq 0 ] || { echo "$DUNG" >&2; exit 2; }
    echo "Kiểm luật nghiệp vụ (BR-)"
    DS=$(luat_ds "$MT_REPO" "$MT_CONV")
    l=$(luat_loi_hinh_thuc "$MT_REPO" "$MT_CONV")
    if [ -n "$l" ]; then
      printf '%s\n' "$l" | while IFS= read -r x; do echo "  ✗ $x"; done
      exit 1
    fi
    echo "  ✓ $(printf '%s\n' "$DS" | grep -c .) luật đúng dạng"
    PHU=$(luat_duoc_phu "$MT_REPO" "$MT_CONV")
    printf '%s\n' "$DS" | while IFS='|' read -r f id st sc; do
      [ "$st" = active ] || continue
      printf '%s\n' "$PHU" | grep -qx "$id" || echo "  ! $id ($f): active nhưng chưa test nào gắn tag covers $id"
    done
    exit 0 ;;
  promote) ;;
  *) echo "$DUNG" >&2; exit 2 ;;
esac

[ $# -eq 2 ] || { echo "$DUNG" >&2; exit 2; }
DIR=${1%/}; YC=$2
case "$YC" in YC-[0-9]*) ;; *) echo "LỖI: \"$YC\" không phải mã YC-NNN." >&2; exit 2 ;; esac
SPEC="$DIR/spec.md"
for f in "$SPEC" "$DIR/plan.md"; do
  [ -f "$f" ] || { echo "LỖI: không có $f" >&2; exit 2; }
done
[ -n "$(yc_noi_dung "$SPEC" "$YC")" ] || { echo "LỖI: spec.md không có $YC." >&2; exit 2; }

n_tc=0
tu_choi() { echo "  ✗ $1"; n_tc=$((n_tc + 1)); }
dy_dong_dau "$SPEC" spec >/dev/null
tt=$(dy_trang_thai "$SPEC" spec | awk -F'|' '$1 == "S" { print $3; exit }')
[ "$tt" = approved ] || tu_choi "spec.md chưa được người duyệt (${tt:-?}) — chỉ nâng YC trong spec đã duyệt"
ID=$(yc_truong "$SPEC" "$YC" Promote | tr -d '`')
[ -n "$ID" ] || tu_choi "$YC không khai \"- Promote: BR-<MIỀN>-NNN\" — người quyết nâng YC nào, trong chính YC đó (dưới ô duyệt spec)"
ls_=$(luat_loi_spec "$DIR" | awk -v yc="$YC" 'index($0, yc ":") == 1')
[ -z "$ls_" ] || { printf '%s\n' "$ls_" | while IFS= read -r x; do echo "  ✗ $x"; done; n_tc=$((n_tc + 1)); }
KHOI="${TMPDIR:-/tmp}/aw-luat-moi.$$"
if [ "$n_tc" = 0 ]; then
  if ! luat_khoi_moi "$DIR" "$YC" "$ID" "$MT_CONV" > "$KHOI"; then
    sed -n 's/^L|//p' "$KHOI" | while IFS= read -r x; do echo "  ✗ $x"; done; n_tc=$((n_tc + 1))
  fi
fi
[ "$n_tc" = 0 ] || { rm -f "$KHOI"; echo ""; echo "Không nâng $YC."; exit 1; }

# File đích: nơi khối đang nằm (người có thể đã dời), không thì <thư mục luật>/<miền>.md.
CU=$(luat_ds "$MT_REPO" "$MT_CONV" | awk -F'|' -v id="$ID" '$2 == id { print $1; exit }')
DICH=${CU:-$(luat_dich "$ID" "$MT_CONV")}
mkdir -p "$(dirname "$MT_REPO/$DICH")" || exit 2
if [ ! -f "$MT_REPO/$DICH" ]; then
  printf '# Business rules — %s\n\n> Luật nghiệp vụ bền: bất biến còn đúng sau từng việc. `aw rule promote` thêm khối từ YC\n> đã duyệt; sửa qua PR. Không xoá luật — đổi `Status: superseded by BR-…`.\n' \
    "$(printf '%s' "$ID" | awk -F- '{ print tolower($2) }')" > "$MT_REPO/$DICH"
fi
awk -v id="$ID" -v khoi="$KHOI" '
  function in_khoi(   l) { while ((getline l < khoi) > 0) print l; close(khoi) }
  { sub(/\r$/, "") }
  /^##/ {
    if (trong) { trong = 0; print "" }
    s = $0; sub(/^###[ \t]+/, "", s); sub(/[: \t].*$/, "", s)
    if ($0 ~ /^###[ \t]/ && s == id) { in_khoi(); trong = 1; da = 1; next }
  }
  trong { next }
  { print }
  END { if (!da) { print ""; in_khoi() } }
' "$MT_REPO/$DICH" > "$MT_REPO/$DICH.tam.$$" && mv "$MT_REPO/$DICH.tam.$$" "$MT_REPO/$DICH"
rm -f "$KHOI"
echo "  ghi     $DICH ($ID)"
l=$(luat_loi_hinh_thuc "$MT_REPO" "$MT_CONV")
if [ -n "$l" ]; then
  printf '%s\n' "$l" | while IFS= read -r x; do echo "  ✗ $x"; done
  echo ""; echo "Đã ghi nhưng còn lỗi hình thức — sửa rồi chạy aw rule check."; exit 1
fi
echo ""
echo "Đã nâng $YC thành $ID. Commit cùng việc này (nằm trong \"Expected files\" của task phủ $YC)."
exit 0
