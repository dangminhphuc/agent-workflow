#!/usr/bin/env sh
# Xac dinh thu muc artifact cua feature dang lam.
#
#   sh .agent-workflow/.quy-trinh/tools/xac-dinh-feature.sh [ten-feature]
#
# Thu tu (da chot, la giao dien chung giua cac adapter):
#   0. Dang o checkout CHINH -> ma 6. Worktree la bat buoc: moi viec lam trong
#      worktree rieng; checkout chinh chi chay /intake de tao worktree.
#   1. Suy tu ten branch hien tai, neu khop mau_branch trong conventions.md;
#   2. khong khop thi lay tham so;
#   3. khong co tham so thi ma 3 — agent phai DUNG LAI HOI, khong tu dat ten.
#
# In ra stdout: <artifact_dir>/<ten-feature>, vd .agent-workflow/feat_tao-todo
# Ten branch co "/" duoc doi thanh "_" de khong tao thu muc long nhau.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai xac-dinh-feature.sh \
  "0=ĐÃ XÁC ĐỊNH — stdout là thư mục feature" \
  "2=TÊN KHÔNG HỢP LỆ — báo lại người dùng" \
  "3=CẦN HỎI NGƯỜI — branch không khớp quy ước và không có tham số" \
  "6=ĐANG Ở CHECKOUT CHÍNH — việc phải làm trong worktree"
. "$HERE/lib/md.sh"
. "$HERE/lib/worktree.sh"

# Script nam o <repo>/<artifact_dir>/.quy-trinh/tools/
ART_ABS=$(CDPATH= cd -- "$HERE/../.." && pwd)
ART=$(basename "$ART_ABS")
CONV="$ART_ABS/conventions.md"

if wt_la_chinh "$ART_ABS"; then
  echo "ĐANG Ở CHECKOUT CHÍNH ($(wt_chinh "$ART_ABS")) — quy trình bắt buộc làm trong worktree." >&2
  ds=$(git -C "$ART_ABS" worktree list 2>/dev/null | tail -n +2)
  if [ -n "$ds" ]; then
    echo "  Worktree đang có:" >&2
    printf '%s\n' "$ds" | sed 's/^/    /' >&2
  fi
  echo "  Agent: /intake → đề xuất worktree bằng tao-worktree.sh cho NGƯỜI chọn base;" >&2
  echo "  lệnh khác → DỪNG LẠI, bảo người mở phiên mới trong worktree của việc. Không tự chuyển." >&2
  exit 6
fi

ten=""; tu=""
branch=$(git -C "$ART_ABS" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
  mau=$(conv_get "$CONV" mau_branch)
  set -f
  # shellcheck disable=SC2086
  if [ -n "$mau" ] && khop_glob "$branch" $mau; then
    ten=$(printf '%s' "$branch" | tr '/' '_'); tu="suy từ branch \"$branch\""
  fi
  set +f
fi

if [ -z "$ten" ] && [ -n "$1" ]; then
  ten="$1"; tu="từ tham số"
elif [ -n "$ten" ] && [ -n "$1" ] && [ "$1" != "$ten" ]; then
  echo "Lưu ý: branch khớp quy ước nên dùng \"$ten\", bỏ qua tham số \"$1\"." >&2
fi

if [ -z "$ten" ]; then
  echo "KHÔNG XÁC ĐỊNH ĐƯỢC FEATURE." >&2
  echo "  Branch \"${branch:-?}\" không khớp mau_branch trong $ART/conventions.md, và không có tham số." >&2
  echo "  Agent: DỪNG LẠI hỏi tên feature. Không tự đặt tên." >&2
  exit 3
fi

case "$ten" in
  *" "*|*/*|*..*|.*) echo "LỖI: tên feature \"$ten\" không hợp lệ (không được có dấu cách, \"/\", \"..\", hay bắt đầu bằng \".\")." >&2; exit 2 ;;
esac

echo "Đang làm với: $ART/$ten ($tu)" >&2
echo "$ART/$ten"
