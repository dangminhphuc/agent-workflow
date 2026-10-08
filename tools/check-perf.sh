#!/usr/bin/env sh
# perf: ghi số đo hiệu năng TRƯỚC và SAU khi sửa, do máy chạy.
#
#   aw check perf <thư-mục-feature> --before   # trước khi sửa code
#   aw check perf <thư-mục-feature> --after    # sau khi sửa code
#
# Lệnh đo: PERF_CMD trong config.sh, phải in một dòng "RESULT: <số> <đơn vị>" (tên cũ KET_QUA: vẫn nhận).
# --before từ chối nếu diff đã đụng code production (production_code).
# Script chỉ GHI số; có đạt mục tiêu hay không thì người kết luận ở review —
# số đo dao động nên máy chặn theo ngưỡng sẽ chặn nhầm.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
. "$HERE/lib/config.sh"
kq_khai check-perf.sh \
  "0=ĐÃ GHI SỐ ĐO" \
  "1=KHÔNG HỢP LỆ — lý do in phía trên" \
  "2=KHÔNG CHẠY ĐƯỢC — sai tham số, sai loại việc hoặc thiếu cấu hình"
. "$HERE/lib/md.sh"
. "$HERE/lib/cross-check.sh"

DIR="${1:-}"; PHA="${2:-}"
case "$PHA" in
  --before) TEN="Trước" ;;
  --after)  TEN="Sau" ;;
  *) echo "Dùng: aw check perf <thư-mục-feature> --before|--after" >&2; exit 2 ;;
esac
OUT="$DIR/perf.md"
CAUHINH=$(kc_cau_hinh "$DIR")

[ "$(kc_loai "$DIR")" = "perf" ] || { echo "LỖI: chỉ dùng cho loại việc perf (intake.md)." >&2; exit 2; }
PERF_CMD=""
# shellcheck disable=SC1090
ch_nap "$CAUHINH"
[ -n "$PERF_CMD" ] || { echo "LỖI: chưa khai PERF_CMD trong $CAUHINH" >&2; exit 2; }

if [ "$PHA" = "--before" ]; then
  DOI=$(kc_doi "$DIR") || { echo "LỖI: không xác định được base (dòng Base: trong intake.md, hoặc base_branch trong conventions.md)." >&2; exit 2; }
  ngoai=$(printf '%s\n' "$DOI" | while IFS="$(printf '\t')" read -r s p q; do
    [ -n "$p" ] && kc_khop_khoa "$DIR" production_code "${q:-$p}" && echo "  - ${q:-$p}"; done)
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
sh -c "$PERF_CMD" > "$TMP" 2>&1
ma=$?
# Dòng kết quả: "RESULT: <số> <đơn vị>" (tên cũ KET_QUA: vẫn nhận); ghi vào perf.md dạng RESULT:.
kq=$(grep -E '^(RESULT|KET_QUA):' "$TMP" | tail -1 | sed 's/^KET_QUA:/RESULT:/')
cat "$TMP"
if [ "$ma" -ne 0 ] || [ -z "$kq" ]; then
  rm -f "$TMP"
  echo ""
  echo "KHÔNG HỢP LỆ — lệnh đo trả mã $ma hoặc không in dòng \"RESULT: <số> <đơn vị>\". Không ghi gì."
  exit 1
fi

hash=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
MOI="${TMPDIR:-/tmp}/donang-moi.$$"
{
  echo "## $TEN"
  echo ""
  echo "- Lệnh: \`$PERF_CMD\`"
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
  echo "> File này do \`check-perf.sh\` ghi tự động. Người kết luận đạt/chưa đạt ở review."
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
