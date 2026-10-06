#!/usr/bin/env sh
# Đóng gói engine thành file phát hành. Chạy trong repo agent-workflow.
#
#   sh tools/dong-goi.sh <thư-mục-ra> [ref]      # ref mặc định: HEAD
#
# Ra trong <thư-mục-ra>:
#   agent-workflow-<YYYY.MM.DD>.tar.gz   toàn bộ file đã commit ở <ref>, thư mục gốc agent-workflow-<YYYY.MM.DD>/
#   aw                              wrapper — người cài vào ~/.local/bin/aw
#   SHA256SUMS                      sha256 của hai file trên (định dạng sha256sum)
#
# Lấy từ git (git archive), không lấy từ thư mục làm việc: file chưa commit
# không lọt vào bản phát hành. gzip -n: không ghi tên file và giờ vào gói.
# <YYYY.MM.DD> đọc từ VERSION ở <ref>; wrapper bin/aw phải cùng version.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tools/lib/ket-qua.sh"
. "$ROOT/tools/lib/sha256.sh"
. "$ROOT/tools/lib/version.sh"
kq_khai dong-goi.sh \
  "0=ĐÃ ĐÓNG GÓI" \
  "2=SAI THAM SỐ HOẶC REF" \
  "4=VERSION LỖI — VERSION sai dạng YYYY.MM.DD hoặc lệch với bin/aw"

OUT="${1:-}"; REF="${2:-HEAD}"
[ -n "$OUT" ] || { echo "Dùng: sh tools/dong-goi.sh <thư-mục-ra> [ref]" >&2; exit 2; }
git -C "$ROOT" rev-parse --verify --quiet "$REF^{commit}" >/dev/null || { echo "LỖI: không có ref \"$REF\"." >&2; exit 2; }

V=$(git -C "$ROOT" show "$REF:VERSION" 2>/dev/null | tr -d ' \r\n')
ver_hop_le "$V" || { echo "LỖI: VERSION ở $REF là \"$V\" — phải là ngày phát hành YYYY.MM.DD (vd 2026.10.06)." >&2; exit 4; }
CO_AW=""
if git -C "$ROOT" cat-file -e "$REF:bin/aw" 2>/dev/null; then
  CO_AW=1
  WV=$(git -C "$ROOT" show "$REF:bin/aw" | awk -F'"' '/^AW_WRAPPER_VERSION=/ { print $2; exit }')
  [ "$WV" = "$V" ] || { echo "LỖI: bin/aw ở $REF có AW_WRAPPER_VERSION=\"$WV\", VERSION là \"$V\" — sửa cho khớp." >&2; exit 4; }
fi

mkdir -p "$OUT" || exit 2
OUT=$(CDPATH= cd -- "$OUT" && pwd)
GOI="agent-workflow-$V.tar.gz"
git -C "$ROOT" archive --format=tar --prefix="agent-workflow-$V/" "$REF" | gzip -n -9 > "$OUT/$GOI" || exit 2
printf '%s  %s\n' "$(sha256_file "$OUT/$GOI")" "$GOI" > "$OUT/SHA256SUMS"
echo "  write   $GOI"
if [ -n "$CO_AW" ]; then
  git -C "$ROOT" show "$REF:bin/aw" > "$OUT/aw" || exit 2
  chmod +x "$OUT/aw"
  printf '%s  %s\n' "$(sha256_file "$OUT/aw")" "aw" >> "$OUT/SHA256SUMS"
  echo "  write   aw"
fi
echo "  write   SHA256SUMS"
