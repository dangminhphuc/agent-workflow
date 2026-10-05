#!/usr/bin/env sh
# Dọn worktree của một việc. NGƯỜI hoặc agent chạy, từ checkout CHÍNH.
#
#   aw worktree status <tên-branch>                   # chỉ in trạng thái
#   aw worktree remove <tên-branch>                   # gỡ worktree, giữ branch
#   aw worktree remove <tên-branch> --delete-branch   # + xoá branch LOCAL
#
# Artifact của việc (.agent-workflow/) bị exclude, không nằm trong commit nào —
# git worktree remove sẽ xoá luôn mà không hỏi. Vì vậy trước khi gỡ, script
# CHÉP nó vào $AW_CONFIG/archive/<tên>/ (đã có thì thêm hậu tố thời gian).
#
# An toàn theo thiết kế — không bao giờ dùng --force hay "branch -D", không đụng remote:
#   - Chặn nếu thư mục đang đứng (hay chính script này) nằm trong worktree cần dọn:
#     phiên agent đang ở đó sẽ mất thư mục làm việc.
#   - Chặn nếu còn thay đổi chưa commit / file chưa track (file bị .gitignore thì
#     không tính: node_modules, build… đi theo worktree).
#   - Gỡ worktree không mất commit: branch vẫn còn. Xoá branch chỉ khi --delete-branch,
#     bằng "git branch -d" — git tự từ chối nếu chưa merge. Squash/rebase merge
#     git không nhận ra → dừng, NGƯỜI tự quyết "git branch -D". Không đoán "chắc merge rồi".
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai don-worktree.sh \
  "0=XONG" \
  "2=SAI THAM SỐ" \
  "7=BỊ CHẶN — lý do in phía trên"
. "$HERE/lib/md.sh"
. "$HERE/lib/worktree.sh"

. "$HERE/lib/moi-truong.sh"
mt_dat "$HERE"
CONV="$MT_CONV"

TEN="${1:-}"; [ $# -ge 1 ] && shift
XOA=""; CA=""
for a in "$@"; do
  case "$a" in --remove) XOA=1 ;; --delete-branch) CA=1 ;; *) echo "LỖI: tham số lạ \"$a\" (chỉ nhận --delete-branch)" >&2; exit 2 ;; esac
done
[ -n "$TEN" ] || { echo "Dùng: aw worktree status|remove <tên-branch> [--delete-branch]" >&2; exit 2; }
[ -z "$CA" ] || [ -n "$XOA" ] || { echo "LỖI: --delete-branch chỉ dùng với aw worktree remove." >&2; exit 2; }

WT=$(wt_cua_branch "$MT_REPO" "$TEN")
[ -n "$WT" ] || { echo "LỖI: branch \"$TEN\" không có worktree nào (xem: git worktree list)." >&2; exit 2; }
CHINH=$(wt_chinh "$MT_REPO")
[ "$WT" != "$CHINH" ] || { echo "LỖI: \"$TEN\" đang ở checkout chính — không phải worktree để dọn." >&2; exit 2; }

up=$(git -C "$MT_REPO" rev-parse --abbrev-ref "$TEN@{upstream}" 2>/dev/null)
if [ -n "$up" ]; then
  tt_push="upstream $up — $(git -C "$MT_REPO" rev-list --count "$up..$TEN") commit chưa push"
else
  tt_push="chưa có upstream (chưa push lần nào)"
fi
g=$(conv_get "$CONV" nhanh_goc); g=${g:-main}
goc=$g; git -C "$MT_REPO" rev-parse --verify --quiet "refs/remotes/origin/$g" >/dev/null && goc="origin/$g"
if git -C "$MT_REPO" merge-base --is-ancestor "$TEN" "$goc" 2>/dev/null; then tt_merge="đã nằm trong $goc"
else tt_merge="CHƯA nằm trong $goc (hoặc đã merge kiểu squash/rebase)"; fi
bn=$(git -C "$WT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

echo "Worktree  $WT"
echo "Branch    $TEN — $tt_push"
echo "Merge     $tt_merge"
echo "Sạch      $([ "$bn" = 0 ] && echo có || echo KHÔNG)"
LUU=""
if [ -n "${AW_CONFIG:-}" ] && [ -d "$WT/$MT_ART_DIR" ] && [ -n "$(ls -A "$WT/$MT_ART_DIR" 2>/dev/null)" ]; then
  LUU="$AW_CONFIG/archive/$(printf '%s' "$TEN" | tr '/' '_')"
  [ -e "$LUU" ] && LUU="$LUU-$(date +%Y%m%d-%H%M%S)"
  echo "Artifact  $MT_ART_DIR/ → chép vào $LUU trước khi gỡ (không nằm trong commit nào)"
fi

chan=0
dang_o=$(pwd -P)
case "$dang_o/" in "$WT"/*) echo "  ✗ Đang đứng trong chính worktree này — chạy từ checkout chính ($CHINH)."; chan=1 ;; esac
case "$HERE/" in "$WT"/*) [ "$chan" = 1 ] || echo "  ✗ Script đang chạy là bản nằm trong worktree cần dọn — chạy bản ở checkout chính ($CHINH)."; chan=1 ;; esac
if [ "$bn" != 0 ]; then
  echo "  ✗ Còn $bn thay đổi chưa commit / file chưa track:"
  git -C "$WT" status --short | head -5 | sed 's/^/      /'
  chan=1
fi
echo ""

if [ -z "$XOA" ]; then
  echo "Sẽ làm khi chạy: aw worktree remove $TEN"
  [ -n "$LUU" ] && echo "  chép $MT_ART_DIR/ vào $LUU"
  echo "  git worktree remove $WT   (branch giữ nguyên, không mất commit)"
  echo "  + --delete-branch: git branch -d $TEN   (git tự từ chối nếu chưa merge)"
  [ "$chan" = 0 ] || { echo ""; echo "Hiện đang BỊ CHẶN — xử lý các mục ✗ trước."; }
  exit 0
fi

[ "$chan" = 0 ] || { echo "BỊ CHẶN — không gỡ gì."; exit 7; }
if [ -n "$LUU" ]; then
  mkdir -p "$(dirname "$LUU")" && cp -R "$WT/$MT_ART_DIR" "$LUU" || { echo "BỊ CHẶN — không chép được artifact vào $LUU, không gỡ gì."; exit 7; }
  echo "  copy    $MT_ART_DIR/ → $LUU"
fi
git -C "$CHINH" worktree remove "$WT" || { echo "BỊ CHẶN — git từ chối gỡ worktree."; exit 7; }
git -C "$CHINH" worktree prune
echo "Đã gỡ worktree $WT"
[ -n "$CA" ] || exit 0
if git -C "$CHINH" branch -d "$TEN" >/dev/null 2>&1; then
  echo "Đã xoá branch local $TEN"
else
  echo "  ✗ git từ chối xoá branch \"$TEN\": chưa merge theo cách git nhận ra được."
  echo "    Nếu đã squash/rebase merge trên remote, NGƯỜI tự chạy: git branch -D $TEN"
  echo "    Worktree đã gỡ; branch còn nguyên, không mất commit."
  exit 7
fi
