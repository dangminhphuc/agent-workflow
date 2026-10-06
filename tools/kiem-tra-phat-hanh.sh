#!/usr/bin/env sh
# Kiểm version của repo engine có phát hành được không.
#
#   sh tools/kiem-tra-phat-hanh.sh [<base-ref>]
#
# Luôn kiểm: VERSION đúng dạng YYYY.M.N; AW_WRAPPER_VERSION trong bin/aw khớp;
# CHANGELOG.md có mục "## [<version>]" có nội dung.
# Có <base-ref> (CI của PR truyền nhánh đích) và VERSION khác VERSION ở base —
# tức PR này là một bản phát hành: tag <version> chưa được có ở remote (AW_REMOTE,
# mặc định origin). Hai PR cùng lấy một số thì PR merge sau bị chặn ở đây: chạy lại
# tools/chuan-bi-phat-hanh.sh để lấy số kế tiếp.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tools/lib/ket-qua.sh"
. "$ROOT/tools/lib/version.sh"
kq_khai kiem-tra-phat-hanh.sh \
  "0=ĐẠT — version nhất quán" \
  "1=KHÔNG ĐẠT — xem các dòng LỖI phía trên" \
  "2=SAI THAM SỐ HOẶC REF"

REMOTE="${AW_REMOTE:-origin}"
BASE="${1:-}"
[ $# -le 1 ] || { echo "Dùng: sh tools/kiem-tra-phat-hanh.sh [<base-ref>]" >&2; exit 2; }

n_loi=0
loi() { echo "  [LỖI] $*"; n_loi=$((n_loi + 1)); }

V=$(tr -d ' \r\n' < "$ROOT/VERSION" 2>/dev/null)
echo "VERSION: $V"
ver_hop_le "$V" || loi "VERSION \"$V\" không phải YYYY.M.N (vd 2026.10.8 — không số 0 đứng đầu, N từ 1)."

WV=$(awk -F'"' '/^AW_WRAPPER_VERSION=/ { print $2; exit }' "$ROOT/bin/aw")
[ "$WV" = "$V" ] || loi "bin/aw có AW_WRAPPER_VERSION=\"$WV\", lệch VERSION \"$V\"."

awk -v v="$V" '
  index($0, "## [" v "]") == 1 { on = 1; next }
  on && /^## \[/ { exit }
  on && NF { co = 1 }
  END { exit co ? 0 : 1 }
' "$ROOT/CHANGELOG.md" || loi "CHANGELOG.md thiếu mục \"## [$V]\" có nội dung (chạy tools/chuan-bi-phat-hanh.sh)."

if [ -n "$BASE" ]; then
  git -C "$ROOT" rev-parse --verify --quiet "$BASE^{commit}" >/dev/null || { echo "LỖI: không có ref \"$BASE\"." >&2; exit 2; }
  BV=$(git -C "$ROOT" show "$BASE:VERSION" 2>/dev/null | tr -d ' \r\n')
  if [ "$BV" = "$V" ]; then
    echo "VERSION không đổi so với $BASE — PR này không phải bản phát hành."
  else
    echo "VERSION đổi $BV → $V — PR này là bản phát hành $V."
    if git -C "$ROOT" ls-remote --exit-code --tags "$REMOTE" "refs/tags/$V" >/dev/null 2>&1; then
      loi "tag $V đã có ở $REMOTE — chạy lại tools/chuan-bi-phat-hanh.sh để lấy số kế tiếp."
    fi
  fi
fi

[ "$n_loi" = 0 ] || exit 1
echo "Version nhất quán."
exit 0
