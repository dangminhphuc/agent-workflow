#!/usr/bin/env sh
# Chuẩn bị một bản phát hành trong PR: đặt version vào mọi chỗ phải khớp.
#
#   sh tools/prepare-release.sh [YYYY.M.N]
#
# Không truyền version: lấy năm, tháng hôm nay (theo TZ của máy — đặt
# TZ=Asia/Ho_Chi_Minh nếu cần) và N = số lớn nhất trong tháng đó cộng 1. "Số lớn
# nhất" tính trên tag ở remote (AW_REMOTE, mặc định origin) và VERSION hiện tại.
# Không đọc được remote thì dùng tag ở máy và cảnh báo.
#
# Ghi:
#   VERSION                         <version>
#   bin/aw                          AW_WRAPPER_VERSION="<version>"
#   CHANGELOG.md                    "## [<version>]" = mảnh changes/*.md (tools/lib/changelog.sh)
#                                   + nội dung "## [Chưa phát hành]" nếu còn, gộp theo mục;
#                                   các mảnh bị xoá
#   README.md, docs/huong-dan.md    link tải wrapper releases/download/<version>/aw
#
# Merge PR vào main là workflow release tự tạo tag + Release (xem README, mục
# "Chạy test và phát hành").
#
# Result: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tools/lib/result.sh"
. "$ROOT/tools/lib/version.sh"
. "$ROOT/tools/lib/changelog.sh"
kq_khai prepare-release.sh \
  "0=PREPARED — commit các file đã đổi vào PR (cả các mảnh changes/ đã xoá)" \
  "2=BAD ARGS" \
  "3=NOTHING TO RELEASE — không có mảnh changes/*.md, CHANGELOG.md cũng không có \"## [Chưa phát hành]\" có nội dung" \
  "4=VERSION ERROR — sai dạng YYYY.M.N hoặc tag đã có" \
  "5=CHANGELOG FRAGMENT ERROR — xem các dòng LỖI phía trên"

REMOTE="${AW_REMOTE:-origin}"
[ $# -le 1 ] || { echo "Dùng: sh tools/prepare-release.sh [YYYY.M.N]" >&2; exit 2; }

# Tag ở remote; không đọc được thì tag ở máy.
if TAGS=$(git -C "$ROOT" ls-remote --tags --refs "$REMOTE" 2>/dev/null); then
  TAGS=$(printf '%s\n' "$TAGS" | sed -n 's#.*refs/tags/##p')
else
  echo "WARN: không đọc được tag ở remote \"$REMOTE\" — dùng tag ở máy (có thể thiếu tag mới)." >&2
  TAGS=$(git -C "$ROOT" tag -l)
fi

if [ $# = 1 ]; then
  V=$1
else
  NAM=$(date +%Y); THANG=$(date +%m | sed 's/^0//')
  HIEN=$(tr -d ' \r\n' < "$ROOT/VERSION" 2>/dev/null)
  N=$(printf '%s\n%s\n' "$TAGS" "$HIEN" | awk -F. -v p="$NAM.$THANG" '
    $1 "." $2 == p && NF == 3 && $3 ~ /^[0-9]+$/ && $3 + 0 > m { m = $3 + 0 }
    END { print m + 1 }')
  V="$NAM.$THANG.$N"
fi

ver_hop_le "$V" || { echo "LỖI: \"$V\" không phải YYYY.M.N (vd 2026.10.8 — không số 0 đứng đầu, N từ 1)." >&2; exit 4; }
if printf '%s\n' "$TAGS" | grep -qxF "$V"; then
  echo "LỖI: tag $V đã có — chọn số kế tiếp (bỏ tham số để tự tính)." >&2; exit 4
fi

CL="$ROOT/CHANGELOG.md"
MANH=$(cl_manh "$ROOT")
# Tên file mảnh không có khoảng trắng (changes/<tên-nhánh>.md) — tách theo dòng là đủ.
OIFS=$IFS; IFS='
'
# shellcheck disable=SC2086
set -- $MANH
IFS=$OIFS
if [ $# -gt 0 ]; then
  LOI_MANH=$(cl_kiem_manh "$@")
  if [ -n "$LOI_MANH" ]; then
    printf '%s\n' "$LOI_MANH" | sed 's/^/  [ERROR] changes\//'
    exit 5
  fi
fi

TMPF="$ROOT/.chuan-bi-phat-hanh.$$"
kq_don 'rm -f "$TMPF" "$TMPF.cu" "$TMPF.moi"'   # không đặt trap EXIT riêng — kq_khai đã giữ trap đó
thay_file() { sed "$1" "$2" > "$TMPF" && cat "$TMPF" > "$2"; }

# Nội dung "## [Chưa phát hành]" (cách ghi trước khi có mảnh) vẫn được gom cùng.
awk '
  /^## \[Chưa phát hành\][ \t]*$/ { on = 1; next }
  on && /^## \[/ { exit }
  on { print }
' "$CL" > "$TMPF.cu"
cl_gom "$TMPF.cu" "$@" > "$TMPF.moi"
grep -q '[^[:space:]]' "$TMPF.moi" || {
  echo "LỖI: không có gì để phát hành — mỗi PR ghi thay đổi vào changes/<tên-nhánh>.md (xem changes/README.md)." >&2
  exit 3
}

printf '%s\n' "$V" > "$ROOT/VERSION"
thay_file "s/^AW_WRAPPER_VERSION=\"[^\"]*\"/AW_WRAPPER_VERSION=\"$V\"/" "$ROOT/bin/aw"
# Mục mới thay chỗ "## [Chưa phát hành]"; không có thì đứng trước bản phát hành mới nhất.
awk -v v="$V" -v moi="$TMPF.moi" '
  function in_moi(  l) {
    print "## [" v "]"; print ""
    while ((getline l < moi) > 0) print l
    close(moi); print ""; xong = 1
  }
  !xong && /^## \[Chưa phát hành\][ \t]*$/ { in_moi(); bo = 1; next }
  bo && /^## \[/ { bo = 0 }
  bo { next }
  !xong && /^## \[/ { in_moi() }
  { print }
  END { if (!xong) { print ""; in_moi() } }
' "$CL" > "$TMPF" && cat "$TMPF" > "$CL"
for tep in "$ROOT/README.md" "$ROOT/docs/huong-dan.md"; do
  thay_file "s#releases/download/[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/aw#releases/download/$V/aw#" "$tep"
done
for m in "$@"; do rm -f "$m"; done

echo "Version $V:"
echo "  VERSION, bin/aw (AW_WRAPPER_VERSION), CHANGELOG.md ([$V]), README.md, docs/huong-dan.md (link tải wrapper)"
[ $# = 0 ] || echo "  Đã gom và xoá $# mảnh trong changes/"
echo "Kiểm lại: sh tools/check-release.sh"
exit 0
