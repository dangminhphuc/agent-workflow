#!/usr/bin/env sh
# Chuẩn bị một bản phát hành trong PR: đặt version vào mọi chỗ phải khớp.
#
#   sh tools/chuan-bi-phat-hanh.sh [YYYY.M.N]
#
# Không truyền version: lấy năm, tháng hôm nay (theo TZ của máy — đặt
# TZ=Asia/Ho_Chi_Minh nếu cần) và N = số lớn nhất trong tháng đó cộng 1. "Số lớn
# nhất" tính trên tag ở remote (AW_REMOTE, mặc định origin) và VERSION hiện tại.
# Không đọc được remote thì dùng tag ở máy và cảnh báo.
#
# Ghi:
#   VERSION                         <version>
#   bin/aw                          AW_WRAPPER_VERSION="<version>"
#   CHANGELOG.md                    "## [Chưa phát hành]" → "## [<version>]"
#   README.md                       link tải wrapper releases/download/<version>/aw
#
# Merge PR vào main là workflow release tự tạo tag + Release (xem README, mục
# "Chạy test và phát hành").
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tools/lib/ket-qua.sh"
. "$ROOT/tools/lib/version.sh"
kq_khai chuan-bi-phat-hanh.sh \
  "0=ĐÃ CHUẨN BỊ — commit các file đã đổi vào PR" \
  "2=SAI THAM SỐ" \
  "3=KHÔNG CÓ GÌ ĐỂ PHÁT HÀNH — CHANGELOG.md thiếu mục \"## [Chưa phát hành]\" có nội dung" \
  "4=VERSION LỖI — sai dạng YYYY.M.N hoặc tag đã có"

REMOTE="${AW_REMOTE:-origin}"
[ $# -le 1 ] || { echo "Dùng: sh tools/chuan-bi-phat-hanh.sh [YYYY.M.N]" >&2; exit 2; }

# Tag ở remote; không đọc được thì tag ở máy.
if TAGS=$(git -C "$ROOT" ls-remote --tags --refs "$REMOTE" 2>/dev/null); then
  TAGS=$(printf '%s\n' "$TAGS" | sed -n 's#.*refs/tags/##p')
else
  echo "CẢNH BÁO: không đọc được tag ở remote \"$REMOTE\" — dùng tag ở máy (có thể thiếu tag mới)." >&2
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
awk '
  /^## \[Chưa phát hành\][ \t]*$/ { on = 1; next }
  on && /^## \[/ { exit }
  on && NF { co = 1 }
  END { exit co ? 0 : 1 }
' "$CL" || { echo "LỖI: CHANGELOG.md không có mục \"## [Chưa phát hành]\" có nội dung — ghi thay đổi vào đó trước." >&2; exit 3; }

TMPF="$ROOT/.chuan-bi-phat-hanh.$$"
kq_don 'rm -f "$TMPF"'   # không đặt trap EXIT riêng — kq_khai đã giữ trap đó
thay_file() { sed "$1" "$2" > "$TMPF" && cat "$TMPF" > "$2"; }

printf '%s\n' "$V" > "$ROOT/VERSION"
thay_file "s/^AW_WRAPPER_VERSION=\"[^\"]*\"/AW_WRAPPER_VERSION=\"$V\"/" "$ROOT/bin/aw"
awk -v v="$V" '!xong && /^## \[Chưa phát hành\][ \t]*$/ { print "## [" v "]"; xong = 1; next } { print }' "$CL" > "$TMPF" && cat "$TMPF" > "$CL"
thay_file "s#releases/download/[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/aw#releases/download/$V/aw#" "$ROOT/README.md"

echo "Version $V:"
echo "  VERSION, bin/aw (AW_WRAPPER_VERSION), CHANGELOG.md ([Chưa phát hành] → [$V]), README.md (link tải wrapper)"
echo "Kiểm lại: sh tools/kiem-tra-phat-hanh.sh"
exit 0
