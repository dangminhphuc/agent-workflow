#!/usr/bin/env sh
# Dọn worktree của một việc. NGƯỜI hoặc agent chạy, từ checkout CHÍNH.
#
#   sh .agent-workflow/.quy-trinh/tools/don-worktree.sh <tên-branch>                     # chỉ in trạng thái
#   sh .agent-workflow/.quy-trinh/tools/don-worktree.sh <tên-branch> --xoa               # gỡ worktree, giữ branch
#   sh .agent-workflow/.quy-trinh/tools/don-worktree.sh <tên-branch> --xoa --ca-branch   # + xoá branch LOCAL
#
# An toàn theo thiết kế — không bao giờ dùng --force hay "branch -D", không đụng remote:
#   - Chặn nếu thư mục đang đứng (hay chính script này) nằm trong worktree cần dọn:
#     phiên agent đang ở đó sẽ mất thư mục làm việc.
#   - Chặn nếu còn thay đổi chưa commit / file chưa track (file bị .gitignore thì
#     không tính: node_modules, build… đi theo worktree).
#   - Gỡ worktree không mất commit: branch vẫn còn. Xoá branch chỉ khi --ca-branch,
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

ART_ABS=$(CDPATH= cd -- "$HERE/../.." && pwd)
CONV="$ART_ABS/conventions.md"

TEN="${1:-}"; [ $# -ge 1 ] && shift
XOA=""; CA=""
for a in "$@"; do
  case "$a" in --xoa) XOA=1 ;; --ca-branch) CA=1 ;; *) echo "LỖI: tham số lạ \"$a\" (chỉ nhận --xoa, --ca-branch)" >&2; exit 2 ;; esac
done
[ -n "$TEN" ] || { echo "Dùng: sh don-worktree.sh <tên-branch> [--xoa [--ca-branch]]" >&2; exit 2; }
[ -z "$CA" ] || [ -n "$XOA" ] || { echo "LỖI: --ca-branch phải đi kèm --xoa." >&2; exit 2; }

WT=$(wt_cua_branch "$ART_ABS" "$TEN")
[ -n "$WT" ] || { echo "LỖI: branch \"$TEN\" không có worktree nào (xem: git worktree list)." >&2; exit 2; }
CHINH=$(wt_chinh "$ART_ABS")
[ "$WT" != "$CHINH" ] || { echo "LỖI: \"$TEN\" đang ở checkout chính — không phải worktree để dọn." >&2; exit 2; }

up=$(git -C "$ART_ABS" rev-parse --abbrev-ref "$TEN@{upstream}" 2>/dev/null)
if [ -n "$up" ]; then
  tt_push="upstream $up — $(git -C "$ART_ABS" rev-list --count "$up..$TEN") commit chưa push"
else
  tt_push="chưa có upstream (chưa push lần nào)"
fi
g=$(conv_get "$CONV" nhanh_goc); g=${g:-main}
goc=$g; git -C "$ART_ABS" rev-parse --verify --quiet "refs/remotes/origin/$g" >/dev/null && goc="origin/$g"
if git -C "$ART_ABS" merge-base --is-ancestor "$TEN" "$goc" 2>/dev/null; then tt_merge="đã nằm trong $goc"
else tt_merge="CHƯA nằm trong $goc (hoặc đã merge kiểu squash/rebase)"; fi
bn=$(git -C "$WT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

echo "Worktree  $WT"
echo "Branch    $TEN — $tt_push"
echo "Merge     $tt_merge"
echo "Sạch      $([ "$bn" = 0 ] && echo có || echo KHÔNG)"

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
  echo "Sẽ làm khi chạy lại với --xoa:"
  echo "  git worktree remove $WT   (branch giữ nguyên, không mất commit)"
  echo "  + --ca-branch: git branch -d $TEN   (git tự từ chối nếu chưa merge)"
  [ "$chan" = 0 ] || { echo ""; echo "Hiện đang BỊ CHẶN — xử lý các mục ✗ trước."; }
  exit 0
fi

[ "$chan" = 0 ] || { echo "BỊ CHẶN — không gỡ gì."; exit 7; }
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
