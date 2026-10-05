#!/usr/bin/env sh
# perf: ghi số đo hiệu năng TRƯỚC và SAU khi sửa, do máy chạy.
#
#   sh tools/kiem-tra-hieu-nang.sh <thư-mục-feature> --truoc   # trước khi sửa code
#   sh tools/kiem-tra-hieu-nang.sh <thư-mục-feature> --sau     # sau khi sửa code
#
# Lệnh đo: LENH_DO_HIEU_NANG trong cau-hinh.sh, phải in một dòng "KET_QUA: <số> <đơn vị>".
# --truoc từ chối nếu diff đã đụng code production (mau_code_production).
# Script chỉ GHI số; có đạt mục tiêu hay không thì người kết luận ở review —
# số đo dao động nên máy chặn theo ngưỡng sẽ chặn nhầm.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai kiem-tra-hieu-nang.sh \
  "0=ĐÃ GHI SỐ ĐO" \
  "1=KHÔNG HỢP LỆ — lý do in phía trên" \
  "2=KHÔNG CHẠY ĐƯỢC — sai tham số, sai loại việc hoặc thiếu cấu hình"
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

DIR="${1:-}"; PHA="${2:-}"
case "$PHA" in
  --truoc) TEN="Trước" ;;
  --sau)   TEN="Sau" ;;
  *) echo "Dùng: sh kiem-tra-hieu-nang.sh <thư-mục-feature> --truoc|--sau" >&2; exit 2 ;;
esac
OUT="$DIR/do-hieu-nang.md"
CAUHINH=$(kc_cau_hinh "$DIR")

[ "$(kc_loai "$DIR")" = "perf" ] || { echo "LỖI: chỉ dùng cho loại việc perf (intake.md)." >&2; exit 2; }
LENH_DO_HIEU_NANG=""
# shellcheck disable=SC1090
[ -f "$CAUHINH" ] && . "$CAUHINH"
[ -n "$LENH_DO_HIEU_NANG" ] || { echo "LỖI: chưa khai LENH_DO_HIEU_NANG trong $CAUHINH" >&2; exit 2; }

if [ "$PHA" = "--truoc" ]; then
  DOI=$(kc_doi "$DIR") || { echo "LỖI: không xác định được base (dòng Base: trong intake.md, hoặc nhanh_goc trong conventions.md)." >&2; exit 2; }
  ngoai=$(printf '%s\n' "$DOI" | while IFS="$(printf '\t')" read -r s p q; do
    [ -n "$p" ] && kc_khop_khoa "$DIR" mau_code_production "${q:-$p}" && echo "  - ${q:-$p}"; done)
  if [ -n "$ngoai" ]; then
    echo "KHÔNG HỢP LỆ — đo \"trước\" nhưng diff đã đụng code production:"
    echo "$ngoai"
    echo "Hoàn tác phần sửa (git stash), đo lại, rồi mới sửa."
    exit 1
  fi
elif ! grep -q '^## Trước' "$OUT" 2>/dev/null; then
  echo "KHÔNG HỢP LỆ — chưa có số đo trước. Số đo sau không có số đo trước thì không so được gì."
  exit 1
fi

TMP="${TMPDIR:-/tmp}/donang.$$"
sh -c "$LENH_DO_HIEU_NANG" > "$TMP" 2>&1
ma=$?
kq=$(grep '^KET_QUA:' "$TMP" | tail -1)
cat "$TMP"
if [ "$ma" -ne 0 ] || [ -z "$kq" ]; then
  rm -f "$TMP"
  echo ""
  echo "KHÔNG HỢP LỆ — lệnh đo trả mã $ma hoặc không in dòng \"KET_QUA: <số> <đơn vị>\". Không ghi gì."
  exit 1
fi

hash=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
MOI="${TMPDIR:-/tmp}/donang-moi.$$"
{
  echo "## $TEN"
  echo ""
  echo "- Lệnh: \`$LENH_DO_HIEU_NANG\`"
  echo "- Commit: \`$hash\`"
  echo ""
  echo "$kq"
  echo ""
  echo '```'
  cat "$TMP"
  echo '```'
  echo ""
} > "$MOI"
rm -f "$TMP"

# Giữ phần còn lại của file, thay đúng mục "## $TEN". Luôn để "Trước" đứng trước "Sau".
{
  echo "# Số đo hiệu năng"
  echo ""
  echo "> File này do \`kiem-tra-hieu-nang.sh\` ghi tự động. Người kết luận đạt/chưa đạt ở review."
  echo ""
  for muc in "Trước" "Sau"; do
    if [ "$muc" = "$TEN" ]; then cat "$MOI"
    elif [ -f "$OUT" ]; then
      awk -v m="$muc" '{ sub(/\r$/, "") } /^## / { vao = ($0 == "## " m) } vao { print }' "$OUT"
    fi
  done
} > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
rm -f "$MOI"

echo ""
echo "Đã ghi mục \"$TEN\" vào $OUT: $kq"
