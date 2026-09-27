#!/usr/bin/env sh
# Đề xuất / tạo branch theo quy ước từ loại việc — dùng ở /intake khi branch
# hiện tại không khớp quy ước (vd đang ở main).
#
#   sh .agent-workflow/.quy-trinh/tools/tao-branch.sh <loại-việc> <mô-tả>          # chỉ in tên đề xuất
#   sh .agent-workflow/.quy-trinh/tools/tao-branch.sh <loại-việc> <mô-tả> --tao    # tạo branch (sau khi NGƯỜI xác nhận)
#
# Tiền tố lấy từ loai_theo_tien_to trong conventions.md, không để agent tự đặt:
# tiền tố sai thì loại việc lệch branch ngay từ đầu, và review sẽ chặn.
# <mô-tả>: chữ thường ASCII, số, dấu "-" (vd phi-hoan-tien).
#
# Stdout (cả hai chế độ): tên branch. Mã thoát: 0 = được, 2 = tham số / trạng thái không hợp lệ.

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/md.sh"

# Script nằm ở <repo>/<artifact_dir>/.quy-trinh/tools/
ART_ABS=$(CDPATH= cd -- "$HERE/../.." && pwd)
CONV="$ART_ABS/conventions.md"

LOAI="${1:-}"; MOTA="${2:-}"; TAO="${3:-}"
[ -n "$LOAI" ] && [ -n "$MOTA" ] || { echo "Dùng: sh tao-branch.sh <loại-việc> <mô-tả> [--tao]" >&2; exit 2; }
case "$TAO" in ""|--tao) ;; *) echo "LỖI: tham số lạ \"$TAO\" (chỉ nhận --tao)" >&2; exit 2 ;; esac

case "$MOTA" in
  *[!a-z0-9-]*|-*|*-) echo "LỖI: mô tả \"$MOTA\" phải là chữ thường ASCII, số và \"-\", không bắt đầu/kết thúc bằng \"-\" (vd phi-hoan-tien)." >&2; exit 2 ;;
esac

tien_to=""
for _cap in $(conv_get "$CONV" loai_theo_tien_to); do
  [ "${_cap#*=}" = "$LOAI" ] && { tien_to=${_cap%%=*}; break; }
done
if [ -z "$tien_to" ]; then
  echo "LỖI: loại việc \"$LOAI\" không có tiền tố trong loai_theo_tien_to ($CONV)." >&2
  echo "      Loại hợp lệ: feature | bugfix | refactor | perf | chore." >&2
  exit 2
fi

TEN="$tien_to$MOTA"
git -C "$ART_ABS" check-ref-format --branch "$TEN" >/dev/null 2>&1 || { echo "LỖI: \"$TEN\" không phải tên branch hợp lệ." >&2; exit 2; }
if git -C "$ART_ABS" rev-parse --verify --quiet "refs/heads/$TEN" >/dev/null; then
  echo "LỖI: branch \"$TEN\" đã tồn tại. Chọn mô tả khác, hoặc chuyển sang branch đó." >&2
  exit 2
fi

if [ "$TAO" != "--tao" ]; then
  echo "Đề xuất: $TEN — hỏi NGƯỜI xác nhận, rồi chạy lại với --tao." >&2
  echo "$TEN"
  exit 0
fi

git -C "$ART_ABS" checkout -q -b "$TEN" || { echo "LỖI: không tạo được branch \"$TEN\"." >&2; exit 2; }
echo "Đã tạo và chuyển sang branch $TEN" >&2
echo "$TEN"
