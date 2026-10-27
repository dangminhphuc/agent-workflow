#!/usr/bin/env sh
# Kiểm version của repo engine có phát hành được không.
#
#   sh tools/check-release.sh [<base-ref>]
#
# Luôn kiểm: VERSION đúng dạng YYYY.M.N; AW_WRAPPER_VERSION trong bin/aw khớp;
# CHANGELOG.md có mục "## [<version>]" có nội dung; mảnh changes/*.md đúng dạng
# (tools/lib/changelog.sh) — lỗi hiện ngay ở PR, không đợi lúc chuẩn bị phát hành.
# Có <base-ref> (CI của PR truyền nhánh đích) và VERSION khác VERSION ở base —
# tức PR này là một bản phát hành: tag <version> chưa được có ở remote (AW_REMOTE,
# mặc định origin). Hai PR cùng lấy một số thì PR merge sau bị chặn ở đây: chạy lại
# tools/prepare-release.sh để lấy số kế tiếp.
#
# Result: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tools/lib/result.sh"
. "$ROOT/tools/lib/version.sh"
. "$ROOT/tools/lib/changelog.sh"
kq_khai check-release.sh \
  "0=PASS — version nhất quán" \
  "1=FAIL — xem các dòng LỖI phía trên" \
  "2=BAD ARGS OR REF"

REMOTE="${AW_REMOTE:-origin}"
BASE="${1:-}"
[ $# -le 1 ] || { echo "Dùng: sh tools/check-release.sh [<base-ref>]" >&2; exit 2; }

n_loi=0
loi() { echo "  [ERROR] $*"; n_loi=$((n_loi + 1)); }

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
' "$ROOT/CHANGELOG.md" || loi "CHANGELOG.md thiếu mục \"## [$V]\" có nội dung (chạy tools/prepare-release.sh)."

MANH=$(cl_manh "$ROOT")
if [ -n "$MANH" ]; then
  OIFS=$IFS; IFS='
'
  # shellcheck disable=SC2086
  set -- $MANH
  IFS=$OIFS
  LOI_MANH=$(cl_kiem_manh "$@")
  while IFS= read -r l; do if [ -n "$l" ]; then loi "changes/$l"; fi; done <<EOF
$LOI_MANH
EOF
fi

if [ -n "$BASE" ]; then
  git -C "$ROOT" rev-parse --verify --quiet "$BASE^{commit}" >/dev/null || { echo "LỖI: không có ref \"$BASE\"." >&2; exit 2; }
  BV=$(git -C "$ROOT" show "$BASE:VERSION" 2>/dev/null | tr -d ' \r\n')
  if [ "$BV" = "$V" ]; then
    echo "VERSION không đổi so với $BASE — PR này không phải bản phát hành."
  else
    echo "VERSION đổi $BV → $V — PR này là bản phát hành $V."
    if git -C "$ROOT" ls-remote --exit-code --tags "$REMOTE" "refs/tags/$V" >/dev/null 2>&1; then
      loi "tag $V đã có ở $REMOTE — chạy lại tools/prepare-release.sh để lấy số kế tiếp."
    fi
  fi
fi

[ "$n_loi" = 0 ] || exit 1
echo "Version nhất quán."
exit 0
