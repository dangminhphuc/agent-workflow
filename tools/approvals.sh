#!/usr/bin/env sh
# Duyệt tập trung — mọi ô "Approved by human" đang chờ người, và lối ghi tick
# sau khi NGƯỜI đã chọn duyệt (lệnh /aw-approvals).
#
#   aw approvals [--global]
#       Liệt kê ô duyệt chưa đạt (spec.md, từng D-xx trong tdd.md) của mọi việc
#       trong worktree hiện tại; --global: mọi worktree của bản clone. Mỗi mục có
#       đường dẫn tuyệt đối:dòng của ô duyệt (mở thẳng tới artifact), hash nội dung
#       hiện tại, và đúng lệnh tick.
#   aw approvals tick <thư-mục-feature> <spec|D-NN> <hash>
#       Tick ô đó và ghi dấu duyệt = <hash>. Chỉ ghi khi mục còn chờ duyệt VÀ hash
#       nội dung hiện tại đúng bằng <hash> (bản người vừa thấy khi chọn duyệt) —
#       nội dung đổi giữa chừng thì không tick. Ghi một dòng vào
#       $AW_CONFIG/journal/approvals.tsv để phân biệt với tick tay.
#
# Luật: agent chỉ chạy `tick` trong /aw-approvals, ngay sau khi người chọn
# "Duyệt" cho đúng mục đó (workflow/rules/general.md). Chặn agent tự duyệt:
# luật ask của Claude Code cho lệnh này (người bấm cho phép mỗi lần), aw guard
# (tick ghi bằng Edit/Write vẫn bị bỏ), nhật ký. Lý do: docs/kien-truc.md.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"

if [ "${1:-}" = tick ]; then
  kq_khai approvals.sh \
    "0=ĐÃ DUYỆT — đã tick và ghi approval hash" \
    "1=KHÔNG TICK — mục không chờ duyệt, hoặc nội dung đổi so với bản người đã thấy; chạy lại aw approvals rồi hỏi lại người" \
    "2=SAI THAM SỐ HOẶC THIẾU FILE"
else
  kq_khai approvals.sh \
    "0=KHÔNG CÒN Ô CHỜ DUYỆT" \
    "1=CÓ Ô CHỜ DUYỆT — hỏi người từng mục; chỉ chạy lệnh tick sau khi người chọn duyệt mục đó" \
    "2=SAI THAM SỐ"
fi
. "$HERE/lib/env.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/approval-tick.sh"
mt_dat

# ------------------------------------------------------------------ tick
if [ "${1:-}" = tick ]; then
  [ $# -eq 4 ] || { echo "Dùng: aw approvals tick <thư-mục-feature> <spec|D-NN> <hash>" >&2; exit 2; }
  DIR=$2; KHOA=$3; HASH=$4
  [ -d "$DIR" ] || { echo "LỖI: không có thư mục feature \"$DIR\"" >&2; exit 2; }
  DIR=$(CDPATH= cd -- "$DIR" && pwd)
  case "$KHOA" in
    spec) LOAI=spec ;;
    D-[0-9]*) LOAI=tdd ;;
    *) echo "LỖI: khoá \"$KHOA\" — chỉ nhận spec hoặc D-NN" >&2; exit 2 ;;
  esac
  F="$DIR/$LOAI.md"
  [ -f "$F" ] || { echo "LỖI: không tìm thấy $F" >&2; exit 2; }
  TT=$(dy_trang_thai "$F" "$LOAI" | awk -F'|' -v k="$KHOA" '$1 == "S" && $2 == k { print $3; exit }')
  case "$TT" in
    proposed|reopened|changed-after-approval) ;;
    approved) echo "$KHOA đã được duyệt sẵn — không làm gì."; exit 0 ;;
    missing-box) echo "KHÔNG TICK: $KHOA thiếu approval checkbox — agent thêm ô (chưa tick) trước." >&2; exit 1 ;;
    *) echo "KHÔNG TICK: không thấy approval checkbox của $KHOA trong $F." >&2; exit 1 ;;
  esac
  HIEN=$(dy_hash "$F" "$LOAI" "$KHOA")
  if [ "$HIEN" != "$HASH" ]; then
    echo "KHÔNG TICK: nội dung $KHOA đã đổi so với bản người đã thấy (hash $HASH, giờ là $HIEN)." >&2
    exit 1
  fi
  dy_tick "$F" "$LOAI" "$KHOA" "$HASH" || { echo "KHÔNG TICK: không ghi được approval checkbox của $KHOA." >&2; exit 1; }
  TT=$(dy_trang_thai "$F" "$LOAI" | awk -F'|' -v k="$KHOA" '$1 == "S" && $2 == k { print $3; exit }')
  [ "$TT" = approved ] || { echo "KHÔNG TICK: sau khi ghi, $KHOA vẫn là \"$TT\"." >&2; exit 1; }
  # Nhật ký: lỗi ở đây không làm hỏng lệnh.
  if mkdir -p "$AW_CONFIG/journal" 2>/dev/null; then
    printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$(basename "$DIR")" "$KHOA" "$HASH" "aw approvals tick" \
      >> "$AW_CONFIG/journal/approvals.tsv" 2>/dev/null
  fi
  echo "Đã duyệt $KHOA ($(basename "$DIR")) — $F"
  exit 0
fi

# ------------------------------------------------------------------ liệt kê
PHAM_VI=wt
case "${1:-}" in
  "") ;;
  --global) PHAM_VI=all ;;
  *) echo "Dùng: aw approvals [--global] | aw approvals tick <thư-mục-feature> <spec|D-NN> <hash>" >&2; exit 2 ;;
esac

# Danh sách "worktree|branch"
DS="${TMPDIR:-/tmp}/aw-approvals.$$"
kq_don 'rm -f "$DS"'
if [ "$PHAM_VI" = all ]; then
  git -C "$MT_REPO" worktree list --porcelain 2>/dev/null | awk '
    /^worktree / { if (p != "") print p "|" b; p = substr($0, 10); b = "(detached)" }
    /^branch /   { b = substr($0, 8); sub(/^refs\/heads\//, "", b) }
    END          { if (p != "") print p "|" b }' > "$DS"
else
  printf '%s|%s\n' "$MT_REPO" "$(git -C "$MT_REPO" rev-parse --abbrev-ref HEAD 2>/dev/null)" > "$DS"
fi

nhan_tt() {
  case "$1" in
    proposed) echo "chưa tick" ;;
    reopened) echo "đang mở lại" ;;
    changed-after-approval) echo "ĐÃ ĐỔI sau khi duyệt — đọc lại cả mục (máy không chỉ ra được dòng nào đổi)" ;;
    missing-box) echo "thiếu approval checkbox — agent thêm ô (chưa tick), chưa duyệt được" ;;
    *) echo "$1" ;;
  esac
}

# ten_muc <file> <spec|tdd> -> "khoá|tiêu đề" mỗi dòng
ten_muc() {
  awk -v loai="$2" '
    { sub(/\r$/, "") }
    loai == "spec" && /^#[ \t]/ { t = $0; sub(/^#[ \t]+/, "", t); print "spec|" t; exit }
    loai == "tdd" && /^###[ \t]+D-[0-9]+/ {
      match($0, /D-[0-9]+/); d = substr($0, RSTART, RLENGTH)
      t = $0; sub(/^###[ \t]+D-[0-9]+[ \t]*[—:-]*[ \t]*/, "", t); print d "|" t
    }' "$1"
}

if [ "$PHAM_VI" = all ]; then echo "Ô DUYỆT CHỜ BẠN — mọi worktree ($(wc -l < "$DS" | tr -d ' '))"
else echo "Ô DUYỆT CHỜ BẠN — worktree hiện tại ($MT_REPO)"; fi

TONG=0; N_VIEC=0; N_LOI=0
while IFS='|' read -r WT BR; do
  for d in "$WT/$MT_ART_DIR"/*/; do
    [ -d "$d" ] || continue
    d=${d%/}; MUC=""; LOI=""; SO=0
    for LOAI in spec tdd; do
      f="$d/$LOAI.md"; [ -f "$f" ] || continue
      TT=$(dy_trang_thai "$f" "$LOAI")
      QU=$(dy_quet "$f" "$LOAI")
      TEN=$(ten_muc "$f" "$LOAI")
      l=$(printf '%s\n' "$TT" | awk -F'|' '$1 == "L" { print "      " $2 }')
      if [ -n "$l" ]; then LOI="$LOI$l
"; fi
      for r in $(printf '%s\n' "$TT" | awk -F'|' '$1 == "S" && $3 != "approved" { print $2 "=" $3 }'); do
        k=${r%%=*}; s=${r#*=}; SO=$((SO + 1))
        t=$(printf '%s\n' "$TEN" | awk -F'|' -v k="$k" '$1 == k { print $2; exit }')
        nr=$(printf '%s\n' "$QU" | awk -F'|' -v k="$k" '$1 == "O" && $2 == k { print $5; exit }')
        MUC="$MUC      $k — ${t:-?}
           $(nhan_tt "$s")
           $f${nr:+:$nr}
"
        if [ "$s" != missing-box ]; then
          MUC="$MUC           duyệt: aw approvals tick $d $k $(dy_hash "$f" "$LOAI" "$k")
"
        fi
      done
    done
    [ "$SO" -gt 0 ] || [ -n "$LOI" ] || continue
    N_VIEC=$((N_VIEC + 1)); TONG=$((TONG + SO))
    printf '\n  [%d] %s · branch %s · %d mục\n' "$N_VIEC" "$(basename "$d")" "$BR" "$SO"
    printf '%s' "$MUC"
    if [ -n "$LOI" ]; then
      N_LOI=$((N_LOI + 1))
      echo "      Approval checkbox sai dạng/chỗ (agent sửa dạng, không tick):"
      printf '%s' "$LOI"
    fi
  done
done < "$DS"

echo ""
if [ "$TONG" -eq 0 ] && [ "$N_LOI" -eq 0 ]; then
  echo "Không còn ô nào chờ duyệt."
  [ "$PHAM_VI" = wt ] && echo "(Chỉ xét worktree hiện tại — thêm --global để xét mọi worktree.)"
  exit 0
fi
echo "Tổng: $TONG ô chờ duyệt ở $N_VIEC việc."
exit 1
