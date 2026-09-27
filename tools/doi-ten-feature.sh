#!/usr/bin/env sh
# Đổi tên branch hiện tại VÀ dời thư mục artifact theo.
#
#   sh .agent-workflow/.quy-trinh/tools/doi-ten-feature.sh <tên-branch-mới>
#
# Dùng khi loại việc lệch tiền tố branch (vd fix_ nhưng thực ra là feature) —
# quy trình không có ngoại lệ "chấp nhận lệch", nên phải sửa cho khớp. Đổi tên
# branch mà quên dời .agent-workflow/<tên-cũ>/ thì artifact nằm lại ở chỗ không
# ai tìm, nên hai việc này đi cùng một lệnh.
#
# Không đụng remote: branch đã push thì tự push tên mới / xoá tên cũ / mở lại PR.
#
# Mã thoát: 0 = xong, 2 = sai tham số / trạng thái không cho phép.

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ART_ABS=$(CDPATH= cd -- "$HERE/../.." && pwd)
ART=$(basename "$ART_ABS")

MOI="${1:-}"
[ -n "$MOI" ] || { echo "Dùng: sh doi-ten-feature.sh <tên-branch-mới>" >&2; exit 2; }
CU=$(git -C "$ART_ABS" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -n "$CU" ] && [ "$CU" != "HEAD" ] || { echo "LỖI: không xác định được branch hiện tại." >&2; exit 2; }
[ "$CU" != "$MOI" ] || { echo "LỖI: tên mới trùng tên cũ." >&2; exit 2; }
git -C "$ART_ABS" check-ref-format --branch "$MOI" >/dev/null 2>&1 || { echo "LỖI: \"$MOI\" không phải tên branch hợp lệ." >&2; exit 2; }

D_CU="$ART_ABS/$(printf '%s' "$CU" | tr '/' '_')"
D_MOI="$ART_ABS/$(printf '%s' "$MOI" | tr '/' '_')"
[ ! -e "$D_MOI" ] || { echo "LỖI: $D_MOI đã tồn tại — không ghi đè." >&2; exit 2; }

git -C "$ART_ABS" branch -m "$CU" "$MOI" || exit 2
if [ -d "$D_CU" ]; then
  mv "$D_CU" "$D_MOI" || { git -C "$ART_ABS" branch -m "$MOI" "$CU"; echo "LỖI: không dời được thư mục — đã đổi lại tên branch." >&2; exit 2; }
  echo "Dời  $ART/$(basename "$D_CU") → $ART/$(basename "$D_MOI")"
fi
echo "Đổi  branch $CU → $MOI"
echo ""
echo "Branch đã push thì tự làm tiếp: git push -u origin $MOI && git push origin --delete $CU"
