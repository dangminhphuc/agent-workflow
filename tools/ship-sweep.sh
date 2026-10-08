#!/usr/bin/env sh
# Dọn việc đã merge: worktree, branch local, branch trên origin. Chạy từ checkout CHÍNH.
#
#   aw ship sweep [<branch>]           # chỉ in: việc nào dọn được, việc nào còn chờ
#   aw ship sweep [<branch>] --apply   # dọn các việc dọn được
#
# Duyệt mọi worktree có <thư-mục-feature>/ship.md (aw ship create ghi), hỏi lại
# trạng thái MR (như aw ship status). Một việc DỌN ĐƯỢC khi mọi MR trong ship.md
# đã merged. Còn MR mở → chờ; MR bị đóng / chưa rõ → người quyết, không đụng.
#
# Cách dọn (--apply), cùng các chặn an toàn của aw worktree remove:
#   1. aw worktree remove <branch> — chép artifact (kể cả ship.md) vào archive,
#      chặn nếu còn thay đổi chưa commit.
#   2. Xoá branch local: "git branch -d"; git từ chối (merge kiểu squash/rebase)
#      thì "git branch -D" CHỈ KHI đầu branch trùng đúng sha mà MR đã merge —
#      tức không có commit nào chưa vào đích. Lệch sha → dừng, người quyết.
#   3. Xoá branch trên origin khi nó còn và trỏ đúng sha đó (GitLab thường đã tự
#      xoá nhờ --remove-source-branch). Lệch sha → không xoá.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai "aw ship sweep" \
  "0=XONG — xem từng việc phía trên" \
  "2=SAI THAM SỐ" \
  "7=CÓ VIỆC BỊ CHẶN — lý do phía trên; các việc khác vẫn được xử lý"
. "$HERE/lib/md.sh"
. "$HERE/lib/worktree.sh"
. "$HERE/lib/mr.sh"
. "$HERE/lib/env.sh"
mt_dat "$HERE"

CHI=""; AP=""
for a in "$@"; do
  case "$a" in
    --apply) AP=1 ;;
    -*) echo "LỖI: tham số lạ \"$a\" (chỉ nhận --apply)" >&2; exit 2 ;;
    *) [ -z "$CHI" ] || { echo "LỖI: chỉ nhận một branch." >&2; exit 2; }; CHI=$a ;;
  esac
done
wt_la_chinh "$MT_REPO" || { echo "LỖI: aw ship sweep chạy từ checkout chính ($(wt_chinh "$MT_REPO")) — không thể gỡ worktree đang đứng." >&2; exit 2; }
CHINH=$(wt_chinh "$MT_REPO")

DS="${TMPDIR:-/tmp}/aw-sweep.$$"; kq_don 'rm -f "$DS" "$DS.err"'
git -C "$CHINH" worktree list --porcelain | awk '
  /^worktree / { p = substr($0, 10) }
  /^branch refs\/heads\// { b = substr($0, 19); if (p != "") print p "\t" b }
  /^$/ { p = "" }' | tail -n +2 > "$DS"
if [ -n "$CHI" ] && ! awk -F'\t' -v b="$CHI" '$2 == b { f = 1 } END { exit !f }' "$DS"; then
  echo "LỖI: branch \"$CHI\" không có worktree nào (xem: git worktree list)." >&2; exit 2
fi

git -C "$CHINH" fetch -q --prune origin 2>/dev/null
chan=0; n_xet=0; n_don=0
TAB=$(printf '\t')
while IFS="$TAB" read -r wt b; do
  [ -z "$CHI" ] || [ "$b" = "$CHI" ] || continue
  sf="$wt/$MT_ART_DIR/$(printf '%s' "$b" | tr '/' '_')/ship.md"
  [ -f "$sf" ] || continue
  n_xet=$((n_xet + 1))
  sm_cap_nhat "$wt" "$sf"
  st=$(sm_dong "$sf" | cut -d'|' -f2 | sort -u | tr '\n' ' ' | sed 's/ $//')
  echo "$b  ($wt)"
  sm_dong "$sf" | while IFS='|' read -r d s h u; do printf '    %-8s → %-14s %s\n' "$s" "$d" "$u"; done
  case " $st " in
    *" open "*)    echo "    · còn MR đang mở — chờ merge"; continue ;;
    *" closed "*)  echo "    ✗ có MR bị đóng không merge — người quyết (mở lại / tạo MR mới / dọn tay)"; chan=1; continue ;;
    *" unknown "*) echo "    ✗ chưa rõ trạng thái — cài và đăng nhập gh/glab, hoặc kiểm trên web rồi dọn tay"; chan=1; continue ;;
  esac
  [ -n "$st" ] || { echo "    ✗ ship.md không có MR nào"; chan=1; continue; }

  # Mọi MR đã merged. Đầu branch local phải là thứ đã vào đích.
  dau=$(git -C "$CHINH" rev-parse --verify --quiet "refs/heads/$b")
  khop=""
  for h in $(sm_dong "$sf" | cut -d'|' -f3); do [ "$h" = "$dau" ] && khop=1; done
  if [ -z "$khop" ]; then
    for d in $(sm_dong "$sf" | cut -d'|' -f1); do
      git -C "$CHINH" merge-base --is-ancestor "$dau" "refs/remotes/origin/$d" 2>/dev/null && khop=1
    done
  fi
  if [ -z "$khop" ]; then
    echo "    ✗ branch local ($(git -C "$CHINH" rev-parse --short "$dau")) có commit chưa nằm trong MR đã merge — người quyết (MR mới cho phần còn lại?)"
    chan=1; continue
  fi
  rx=$(git -C "$CHINH" ls-remote --heads origin "refs/heads/$b" 2>/dev/null | cut -f1)

  if [ -z "$AP" ]; then
    echo "    ✓ dọn được: gỡ worktree (artifact chép vào archive), xoá branch local$( [ "$rx" = "$dau" ] && echo ", xoá origin/$b")"
    n_don=$((n_don + 1)); continue
  fi

  if ! sh "$HERE/worktree-cleanup.sh" "$b" --remove >/dev/null 2>"$DS.err"; then
    echo "    ✗ không gỡ được worktree:"; grep '✗\|LỖI\|BỊ CHẶN' "$DS.err" | sed 's/^ */      /'
    chan=1; continue
  fi
  echo "    ✓ đã gỡ worktree (artifact: $AW_CONFIG/archive/)"
  if git -C "$CHINH" branch -d "$b" >/dev/null 2>&1 || git -C "$CHINH" branch -D "$b" >/dev/null 2>&1; then
    echo "    ✓ đã xoá branch local $b"
  else
    echo "    ✗ không xoá được branch local $b"; chan=1
  fi
  if [ -z "$rx" ]; then
    echo "    · origin/$b không còn (nền tảng đã xoá)"
  elif [ "$rx" = "$dau" ]; then
    if git -C "$CHINH" push -q origin --delete "$b" 2>/dev/null; then echo "    ✓ đã xoá origin/$b"
    else echo "    ✗ không xoá được origin/$b (quyền? branch được bảo vệ?)"; chan=1; fi
  else
    echo "    ✗ origin/$b trỏ sha khác MR đã merge — không xoá; người kiểm"; chan=1
  fi
  n_don=$((n_don + 1))
done < "$DS"

echo ""
if [ "$n_xet" = 0 ]; then
  echo "Không worktree nào có MR (ship.md) — chưa có gì để dọn."
elif [ -z "$AP" ]; then
  echo "$n_don việc dọn được. Chạy lại với --apply để dọn."
else
  echo "Đã dọn $n_don việc."
fi
[ "$chan" = 0 ] || exit 7
