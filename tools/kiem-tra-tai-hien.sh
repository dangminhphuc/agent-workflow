#!/usr/bin/env sh
# bugfix: ghi bằng chứng test tái hiện ĐỎ trên code chưa sửa.
#
#   aw check repro <thư-mục-feature>
#
# Chạy SAU khi viết test tái hiện, TRƯỚC khi sửa code production:
#   - diff so với base của việc (intake.md) chỉ được đụng file test (mau_file_test) và file bỏ qua;
#     đã đụng code production thì từ chối và KHÔNG ghi đè tai-hien.md cũ;
#   - tự chạy LENH_KIEM_THU, tự ghi tai-hien.md (output thật, mã thoát, commit);
#   - test phải ĐỎ (mã thoát ≠ 0). Xanh nghĩa là test không tái hiện được lỗi.
#
# Máy chỉ biết test ĐÃ đỏ, không biết nó đỏ ĐÚNG VÌ BUG (hay vì lỗi biên dịch):
# phần đó người đọc output ở review ("Repro test fails because: …").
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai kiem-tra-tai-hien.sh \
  "0=ĐẠT — test tái hiện đỏ trên code chưa sửa, giờ mới được sửa code" \
  "1=KHÔNG HỢP LỆ — lý do in phía trên" \
  "2=KHÔNG CHẠY ĐƯỢC — sai loại việc hoặc thiếu cấu hình"
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

DIR="${1:-.}"
OUT="$DIR/tai-hien.md"
CAUHINH=$(kc_cau_hinh "$DIR")

[ "$(kc_loai "$DIR")" = "bugfix" ] || { echo "LỖI: chỉ dùng cho loại việc bugfix (intake.md)." >&2; exit 2; }
LENH_KIEM_THU=""
# shellcheck disable=SC1090
[ -f "$CAUHINH" ] && . "$CAUHINH"
[ -n "$LENH_KIEM_THU" ] || { echo "LỖI: chưa khai LENH_KIEM_THU trong $CAUHINH" >&2; exit 2; }

DOI=$(kc_doi "$DIR") || { echo "LỖI: không xác định được base (dòng Base: trong intake.md, hoặc nhanh_goc trong conventions.md)." >&2; exit 2; }

n_test=0; ngoai=""
TAB=$(printf '\t')
while IFS="$TAB" read -r s p q; do
  [ -n "$p" ] || continue
  f=${q:-$p}
  if kc_khop_khoa "$DIR" mau_file_test "$f"; then n_test=$((n_test + 1)); continue; fi
  kc_khop_khoa "$DIR" bo_qua "$f" && continue
  ngoai="$ngoai
  - $f"
done <<EOF
$DOI
EOF

if [ -n "$ngoai" ]; then
  echo "KHÔNG HỢP LỆ — diff đã đụng file ngoài test:$ngoai"
  echo ""
  echo "Tái hiện phải chạy TRƯỚC khi sửa code. Hoàn tác phần sửa (git stash), chạy lại,"
  echo "rồi mới sửa. tai-hien.md cũ (nếu có) được giữ nguyên."
  exit 1
fi
if [ "$n_test" -eq 0 ]; then
  echo "KHÔNG HỢP LỆ — chưa có file test nào thay đổi. Viết test tái hiện trước."
  exit 1
fi

TMP="${TMPDIR:-/tmp}/taihien.$$"
sh -c "$LENH_KIEM_THU" > "$TMP" 2>&1
ma=$?
if [ "$ma" -eq 0 ]; then nhan_kt="XANH"; else nhan_kt="ĐỎ"; fi
hash=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
{
  echo "# Tái hiện lỗi"
  echo ""
  echo "> File này do \`kiem-tra-tai-hien.sh\` ghi tự động, trên code CHƯA sửa."
  echo "> Đây là output thật của lệnh, không phải mô tả lại bằng lời."
  echo ""
  echo "- Lệnh: \`$LENH_KIEM_THU\`"
  echo "- Commit: \`$hash\` (+ thay đổi chưa commit, chỉ gồm file test)"
  echo "- Kết quả: **$nhan_kt**"
  echo "- Mã thoát: \`$ma\` (bằng chứng thô của lệnh)"
  echo "- File thay đổi lúc chạy:"
  printf '%s\n' "$DOI" | awk -F'\t' 'NF { print "  - `" ($3 != "" ? $3 : $2) "`" }'
  echo ""
  echo '```'
  cat "$TMP"
  echo '```'
} > "$OUT"
cat "$TMP"
rm -f "$TMP"
echo ""
echo "Đã ghi $OUT (test $nhan_kt)."

if [ "$ma" -eq 0 ]; then
  echo "KHÔNG HỢP LỆ — test XANH trên code chưa sửa: nó không tái hiện được lỗi."
  exit 1
fi
echo "ĐẠT — test tái hiện đỏ trên code chưa sửa. Giờ mới được sửa code."
