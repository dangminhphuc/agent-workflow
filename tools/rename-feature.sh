#!/usr/bin/env sh
# Đổi tên việc: branch + thư mục artifact + thư mục worktree, trong một lệnh.
#
#   aw rename <tên-branch-mới>
#
# Dùng khi loại việc lệch tiền tố branch (vd fix_ nhưng thực ra là feature) —
# quy trình không có ngoại lệ "chấp nhận lệch", nên phải sửa cho khớp. Ba thứ
# mang cùng một tên; đổi một mà quên hai cái kia thì artifact nằm lại ở chỗ
# không ai tìm, và nhìn đường dẫn không còn biết đang ở việc nào.
#
# Chạy TRONG worktree của việc. Worktree được dời sang tên mới, cùng thư mục cha
# — thư mục làm việc của phiên hiện tại biến mất: NGƯỜI phải mở phiên mới ở
# đường dẫn mới (script in ra).
#
# Không đụng remote: branch đã push thì tự push tên mới / xoá tên cũ / mở lại PR.
#
# Result: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai rename-feature.sh \
  "0=RENAMED" \
  "2=CANNOT RENAME — tham số hoặc trạng thái không cho phép"
. "$HERE/lib/worktree.sh"
. "$HERE/lib/md.sh"
. "$HERE/lib/env.sh"
. "$HERE/lib/adapter.sh"
. "$HERE/lib/artifact.sh"
mt_dat "$HERE"

MOI="${1:-}"
[ -n "$MOI" ] || { echo "Dùng: aw rename <tên-branch-mới>" >&2; exit 2; }
if wt_la_chinh "$MT_REPO"; then
  echo "LỖI: đang ở main checkout — chạy lệnh này trong worktree của việc cần đổi tên." >&2; exit 2
fi
CU=$(git -C "$MT_REPO" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -n "$CU" ] && [ "$CU" != "HEAD" ] || { echo "LỖI: không xác định được branch hiện tại." >&2; exit 2; }
[ "$CU" != "$MOI" ] || { echo "LỖI: tên mới trùng tên cũ." >&2; exit 2; }
git -C "$MT_REPO" check-ref-format --branch "$MOI" >/dev/null 2>&1 || { echo "LỖI: \"$MOI\" không phải tên branch hợp lệ." >&2; exit 2; }
if git -C "$MT_REPO" rev-parse --verify --quiet "refs/heads/$MOI" >/dev/null; then
  echo "LỖI: branch \"$MOI\" đã tồn tại." >&2; exit 2
fi

TM_MOI=$(printf '%s' "$MOI" | tr '/' '_')
TEN_CU=$(printf '%s' "$CU" | tr '/' '_')
ART=$(dirname "$(tm_viec "$MT_REPO" "$TEN_CU")")   # việc cũ ở TM_CU thì dời trong TM_CU
D_CU="$MT_REPO/$ART/$TEN_CU"
D_MOI="$MT_REPO/$ART/$TM_MOI"
[ ! -e "$D_MOI" ] || { echo "LỖI: $D_MOI đã tồn tại — không ghi đè." >&2; exit 2; }

WT=$(git -C "$MT_REPO" rev-parse --show-toplevel)
WT_MOI="$(dirname "$WT")/$TM_MOI"
[ ! -e "$WT_MOI" ] || { echo "LỖI: $WT_MOI đã tồn tại — không ghi đè." >&2; exit 2; }

# Thứ tự: branch → artifact (trong worktree) → dời worktree (cuối cùng, vì sau
# bước này thư mục hiện tại không còn). Bước nào hỏng thì hoàn tác các bước trước.
git -C "$MT_REPO" branch -m "$CU" "$MOI" || exit 2
if [ -d "$D_CU" ]; then
  mv "$D_CU" "$D_MOI" || { git -C "$MT_REPO" branch -m "$MOI" "$CU"; echo "LỖI: không dời được thư mục artifact — đã đổi lại tên branch." >&2; exit 2; }
  echo "Dời  $ART/$(basename "$D_CU") → $ART/$TM_MOI"
fi
if ! git -C "$WT" worktree move "$WT" "$WT_MOI"; then
  [ -d "$D_MOI" ] && mv "$D_MOI" "$D_CU"
  git -C "$MT_REPO" branch -m "$MOI" "$CU"
  echo "LỖI: git không dời được worktree — đã hoàn tác branch và thư mục artifact." >&2
  exit 2
fi
# Thư mục việc đang trong git: commit việc dời (cả xoá chỗ cũ) — lỗi chỉ báo.
if [ -d "$WT_MOI/$ART/$TM_MOI" ]; then
  set --; [ -z "$(git -C "$WT_MOI" ls-files -- "$ART/$TEN_CU")" ] || set -- "$ART/$TEN_CU"
  ar_commit "$WT_MOI/$ART/$TM_MOI" "chore(sdlc): rename $TEN_CU -> $TM_MOI" "$@" ||
    echo "WARN: không commit được việc dời artifact — xem thông báo của git phía trên." >&2
fi
echo "Đổi  branch $CU → $MOI"
echo "Dời  worktree $WT → $WT_MOI"
echo ""
echo "Thư mục làm việc cũ KHÔNG CÒN. NGƯỜI mở phiên agent mới tại: $WT_MOI"
echo "Branch đã push thì tự làm tiếp: git push -u origin $MOI && git push origin --delete $CU"
