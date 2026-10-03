#!/usr/bin/env sh
# Dong bo bo cai voi ban moi cua repo agent-workflow. NGUOI chay, tu checkout CHINH
# cua repo dich (dung o nhanh goc) — khong phai trong worktree cua mot viec.
#
#   sh .agent-workflow/.quy-trinh/tools/dong-bo.sh               # keo ban moi + cai lai
#   sh .agent-workflow/.quy-trinh/tools/dong-bo.sh --kiem-tra    # chi bao co ban moi hay khong
#
# Tuy chon:
#   --nguon <url|thu-muc>  doi repo nguon (mac dinh: url trong nguon.txt)
#   --nhanh <ten>          doi nhanh nguon (mac dinh: nhanh trong nguon.txt, rong = nhanh mac dinh)
#   --cai-lai              cai lai ca khi da o commit moi nhat
#
# Cach lam: clone nguon vao thu muc tam roi chay chinh tools/cai-dat.sh CUA BAN MOI
# vao repo nay. Vi vay moi luat cua cai-dat.sh van giu: cau-hinh.sh, conventions.md
# va file nguoi viet tay khong bi ghi de; file ban moi bo di thi bi xoa.
# Khong tu commit — nguoi xem diff roi commit vao nhanh goc; worktree dang lam
# nhan ban moi khi merge nhanh goc vao.
#
# Ma thoat: 0 = xong / da moi nhat, 1 = (--kiem-tra) co ban moi,
#           2 = sai tham so / khong biet nguon, 5 = khong lay duoc nguon,
#           7 = bi chan (ly do in ra).
#
# Toan bo nam trong main(): cai-dat.sh xoa roi chep lai thu muc tools/ — gom ca
# file nay — nen shell phai doc het script truoc khi chay.

main() {
  HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$HERE/lib/worktree.sh"
  QT=$(CDPATH= cd -- "$HERE/.." && pwd)
  DICH=$(CDPATH= cd -- "$QT/../.." && pwd)
  NT="$QT/nguon.txt"

  doc() { [ -f "$NT" ] && awk -v k="$1" 'index($0, k "=") == 1 { print substr($0, length(k) + 2); exit }' "$NT"; }

  URL=$(doc url); NHANH=$(doc nhanh); CU=$(doc commit); ADAPTER=$(doc adapter)
  KIEM=""; CAI_LAI=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --nguon)    [ -n "${2:-}" ] || { echo "LỖI: --nguon cần giá trị." >&2; return 2; }; URL="$2"; shift 2 ;;
      --nhanh)    [ -n "${2:-}" ] || { echo "LỖI: --nhanh cần giá trị." >&2; return 2; }; NHANH="$2"; shift 2 ;;
      --kiem-tra) KIEM=1; shift ;;
      --cai-lai)  CAI_LAI=1; shift ;;
      *) echo "LỖI: tham số lạ \"$1\" (nhận --nguon, --nhanh, --kiem-tra, --cai-lai)" >&2; return 2 ;;
    esac
  done
  ADAPTER="${ADAPTER:-claude-code}"

  if [ -z "$URL" ]; then
    echo "LỖI: không biết repo nguồn — bộ cài này cài trước khi có nguon.txt." >&2
    echo "      Chạy lại với: --nguon <url-hoặc-thư-mục-repo-agent-workflow> [--nhanh main]" >&2
    return 2
  fi
  # Thu muc local: doi sang duong dan tuyet doi, vi git clone chay o thu muc khac.
  if [ -d "$URL" ]; then URL=$(CDPATH= cd -- "$URL" && pwd); fi

  # ---- Chi kiem tra: ls-remote, khong clone ----
  if [ -n "$KIEM" ]; then
    ref="${NHANH:+refs/heads/$NHANH}"
    MOI=$(git ls-remote "$URL" "${ref:-HEAD}" 2>/dev/null | awk 'NR == 1 { print $1 }')
    [ -n "$MOI" ] || { echo "LỖI: không đọc được ${ref:-HEAD} từ $URL" >&2; return 5; }
    echo "Nguồn:    $URL${NHANH:+ @ $NHANH}"
    echo "Đang cài: ${CU:-(không rõ)}"
    echo "Mới nhất: $MOI"
    if [ "$MOI" = "$CU" ]; then echo "Đã mới nhất."; return 0; fi
    echo "Có bản mới — chạy lại không có --kiem-tra để cập nhật."
    return 1
  fi

  # ---- Chan: chi dong bo o checkout chinh, va khi bo cai khong co thay doi do dang ----
  if git -C "$DICH" rev-parse --git-dir >/dev/null 2>&1; then
    if ! wt_la_chinh "$DICH"; then
      echo "BỊ CHẶN: đang ở worktree ($DICH)." >&2
      echo "         Đồng bộ ở checkout chính (nhánh gốc), commit, rồi merge nhánh gốc vào worktree." >&2
      return 7
    fi
    ART=${QT#"$DICH"/}; ART=${ART%/.quy-trinh}
    do_dang=$(git -C "$DICH" status --porcelain -- "$ART/.quy-trinh" .claude 2>/dev/null)
    if [ -n "$do_dang" ]; then
      echo "BỊ CHẶN: bộ cài đang có thay đổi chưa commit — đồng bộ đè lên thì không còn xem được diff:" >&2
      printf '%s\n' "$do_dang" | sed 's/^/           /' >&2
      echo "         Commit hoặc stash trước rồi chạy lại." >&2
      return 7
    fi
  fi

  # ---- Lay ban moi ----
  TAM="${TMPDIR:-/tmp}/aw-dong-bo.$$"
  trap 'rm -rf "$TAM"' EXIT INT TERM
  echo "Lấy bản mới: $URL${NHANH:+ @ $NHANH}"
  # blob:none: du lich su de in log cu..moi ma khong tai het noi dung cu.
  if ! git clone -q --filter=blob:none ${NHANH:+--branch "$NHANH"} "$URL" "$TAM" 2>/dev/null; then
    rm -rf "$TAM"
    git clone -q ${NHANH:+--branch "$NHANH"} "$URL" "$TAM" || { echo "LỖI: không clone được $URL" >&2; return 5; }
  fi
  [ -f "$TAM/tools/cai-dat.sh" ] || { echo "LỖI: $URL không phải repo agent-workflow (thiếu tools/cai-dat.sh)." >&2; return 5; }
  MOI=$(git -C "$TAM" rev-parse HEAD)

  if [ "$MOI" = "$CU" ] && [ -z "$CAI_LAI" ]; then
    echo "Đã mới nhất (${MOI%"${MOI#???????}"}). Dùng --cai-lai nếu vẫn muốn cài lại."
    return 0
  fi

  if [ -n "$CU" ] && git -C "$TAM" cat-file -e "$CU^{commit}" 2>/dev/null; then
    echo ""
    echo "Thay đổi ${CU%"${CU#???????}"}..${MOI%"${MOI#???????}"}:"
    git -C "$TAM" log --oneline --no-decorate -n 30 "$CU..$MOI" | sed 's/^/  /'
  elif [ -n "$CU" ]; then
    echo "  (commit đang cài ${CU%"${CU#???????}"} không có trong nhánh nguồn — đổi nhánh hoặc lịch sử bị viết lại)"
  fi
  echo ""

  # Truyen --nguon/--nhanh de nguon.txt giu nguon nguoi da chon, khong ghi
  # duong dan thu muc tam (origin cua ban clone).
  sh "$TAM/tools/cai-dat.sh" "$DICH" --adapter "$ADAPTER" --nguon "$URL" ${NHANH:+--nhanh "$NHANH"} || {
    rc=$?
    echo "" >&2
    echo "LỖI: cài bản mới thất bại (mã $rc). Xem lỗi phía trên." >&2
    echo "      Bộ cài có thể đã đổi một phần; khôi phục: git checkout -- $ART/.quy-trinh .claude" >&2
    return "$rc"
  }

  if git -C "$DICH" rev-parse --git-dir >/dev/null 2>&1; then
    echo ""
    echo "File đổi trong bộ cài:"
    git -C "$DICH" status --short -- "$ART" .claude | sed 's/^/  /'
    echo ""
    echo "Xem diff, rồi COMMIT vào nhánh gốc. Worktree đang làm nhận bản mới khi merge nhánh gốc vào."
  fi
  return 0
}

main "$@"; exit $?
