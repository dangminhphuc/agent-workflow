#!/usr/bin/env sh
# Trạng thái task trong plan.md do MÁY giữ, không do agent tự đánh.
#
#   aw task next  <thư-mục-feature>              in task phải làm tiếp (stdout)
#   aw task start <thư-mục-feature> <T-NN>       [ ] -> [~]  (WIP=1: chỉ một task [~])
#   aw task done  <thư-mục-feature> <T-NN>       chạy lệnh Verify; XANH thì [~] -> [x]
#   aw task done  <thư-mục-feature> <T-NN> --manual "<bằng chứng>"
#                                                task mà Verify không có lệnh (thủ công)
#   aw task reopen <thư-mục-feature> <YC-NNN|D-NN>
#                                                người vừa đổi YC / mở lại D: task phủ YC đó
#                                                (Covers, On assumption) hay dựa trên D đó
#                                                (Based on) về [ ] — chỉ đúng các task ấy
#
# `done` chạy lệnh trong cặp backtick đầu tiên của dòng "Verify" ở gốc repo, ghi
# output thật vào task-results.md (mục "## T-NN", lần chạy sau thay lần trước).
# aw check implement chặn task [x] không có bằng chứng xanh khớp lệnh Verify
# hiện tại — tự sửa ô Status thành [x] không qua được.
#
# Đỏ liên tiếp: mỗi lần `done` đỏ tăng một, xanh về 0. Tới MAX_RED_RUNS
# (config.sh, mặc định 3) thì `done` và `next` báo DỪNG: lặp tiếp là đoán mò —
# ghi "Unplanned" và báo người. Đây là điều kiện dừng của vòng lặp implement.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
. "$HERE/lib/config.sh"
kq_khai task.sh \
  "0=XONG — start: đã đánh [~] · done: Verify XANH, đã đánh [x] · next: stdout là task tiếp · reopen: task bị ảnh hưởng đã về [ ]" \
  "1=TỪ CHỐI / ĐỎ — lý do phía trên; sửa trong task này rồi chạy lại" \
  "2=SAI THAM SỐ" \
  "4=HẾT TASK — mọi task đã [x]: chạy aw check implement" \
  "5=KẸT — task còn lại đều chờ phụ thuộc chưa xong: xem \"Depends on\" trong plan.md, báo người" \
  "6=DỪNG — task đỏ liên tiếp tới giới hạn: ghi \"Unplanned\" trong plan.md và báo người, không thử tiếp"
. "$HERE/lib/md.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/task.sh"

dung() { echo "Dùng: aw task next|start|done <thư-mục-feature> [T-NN] [--manual \"<bằng chứng>\"] · aw task reopen <thư-mục-feature> <YC-NNN|D-NN>" >&2; exit 2; }

LENH="${1:-}"; DIR="${2:-}"; TASK="${3:-}"
case "$LENH" in next|start|done|reopen) ;; *) dung ;; esac
[ -n "$DIR" ] || dung
PLAN="$DIR/plan.md"; KQ="$DIR/task-results.md"

# ---------------------------------------------------------------- reopen
# Trước kiểm plan.md: đổi YC khi chưa có plan là chuyện thường — không có task nào phải làm lại.
if [ "$LENH" = reopen ]; then
  [ $# -eq 3 ] || dung
  case "$TASK" in YC-[0-9]*|D-[0-9]*) ;; *) dung ;; esac
  if [ ! -f "$PLAN" ]; then echo "Chưa có plan.md — không task nào phải làm lại vì $TASK."; exit 0; fi
  ds=$(tk_phu "$PLAN" "$TASK")
  if [ -z "$ds" ]; then echo "Không task nào trong plan.md phủ $TASK — không có gì để làm lại."; exit 0; fi
  printf '%s\n' "$ds" | while IFS='|' read -r t s; do
    case "$s" in
      " ") echo "$t: đã ở [ ]" ;;
      *) tk_dat "$PLAN" "$t" " " || { echo "LỖI: không ghi được ô Status của $t." >&2; exit 1; }
         echo "$t: [$s] → [ ]" ;;
    esac
  done || exit 1
  exit 0
fi

[ -f "$PLAN" ] || { echo "LỖI: không tìm thấy $PLAN" >&2; exit 2; }

MAX_RED_RUNS=3
CH=$(kc_cau_hinh "$DIR")
# shellcheck disable=SC1090
ch_nap "$CH"
case "$MAX_RED_RUNS" in ""|*[!0-9]*|0) MAX_RED_RUNS=3 ;; esac

do_lien_tiep() { _n=$(tk_bc "$KQ" "$1" "Đỏ liên tiếp"); echo "${_n:-0}"; }

# ---------------------------------------------------------------- next
if [ "$LENH" = next ]; then
  t=$(tk_tiep "$PLAN")
  if [ -z "$t" ]; then
    con=$(tk_ds "$PLAN" | awk -F'|' 'NF && $2 != "x"' | cut -d'|' -f1 | tr '\n' ' ' | sed 's/ $//')
    if [ -z "$con" ]; then echo "Mọi task đã [x]." >&2; exit 4; fi
    echo "Còn $con nhưng đều chờ phụ thuộc chưa [x]." >&2; exit 5
  fi
  n=$(do_lien_tiep "$t")
  if [ "$n" -ge "$MAX_RED_RUNS" ]; then
    echo "$t đã đỏ $n lần liên tiếp (giới hạn MAX_RED_RUNS=$MAX_RED_RUNS)." >&2
    exit 6
  fi
  echo "$t"
  v=$(tk_verify "$PLAN" "$t")
  st=$(tk_dong "$PLAN" "$t" | cut -d'|' -f2)
  {
    [ "$st" = "~" ] && echo "  đang làm dở — làm cho xong task này trước (WIP=1)" || echo "  bắt đầu: aw task start $DIR $t"
    [ -n "$v" ] && echo "  kiểm chứng: aw task done $DIR $t   (chạy: $v)" \
                || echo "  kiểm chứng: thủ công — aw task done $DIR $t --manual \"<bằng chứng>\""
    [ "$n" -gt 0 ] && echo "  đã đỏ $n/$MAX_RED_RUNS lần liên tiếp"
  } >&2
  exit 0
fi

# ---------------------------------------------------------------- start / done
case "$TASK" in T-[0-9]*) ;; *) dung ;; esac
dong=$(tk_dong "$PLAN" "$TASK") || { echo "LỖI: plan.md không có task $TASK." >&2; exit 1; }
st=$(printf '%s' "$dong" | cut -d'|' -f2)
dep=$(printf '%s' "$dong" | cut -d'|' -f3)

if [ "$LENH" = start ]; then
  [ $# -le 3 ] || dung
  case "$st" in
    x) echo "$TASK đã xong [x]. Làm lại thì người quyết — sửa tay ô Status về \`[ ]\` rồi start." >&2; exit 1 ;;
    "~") echo "$TASK đã đang làm [~]."; exit 0 ;;
    "?") echo "LỖI: ô Status của $TASK không đọc được — phải là \`[ ]\`." >&2; exit 1 ;;
  esac
  khac=$(tk_ds "$PLAN" | awk -F'|' -v t="$TASK" '$2 == "~" && $1 != t { print $1 }' | tr '\n' ' ' | sed 's/ $//')
  if [ -n "$khac" ]; then
    echo "TỪ CHỐI: $khac đang làm dở [~]. WIP=1 — làm xong (aw task done) trước khi mở task khác." >&2; exit 1
  fi
  chua=""
  for d in $(printf '%s' "$dep" | tr ',' ' '); do
    sd=$(tk_dong "$PLAN" "$d" | cut -d'|' -f2)
    [ "$sd" = x ] || chua="$chua $d"
  done
  if [ -n "$chua" ]; then
    echo "TỪ CHỐI: $TASK phụ thuộc$chua — chưa [x]." >&2; exit 1
  fi
  tk_dat "$PLAN" "$TASK" "~" || { echo "LỖI: không ghi được ô Status của $TASK." >&2; exit 1; }
  echo "$TASK: [ ] → [~]"
  exit 0
fi

# done
MANUAL=""; CO_MANUAL=""
shift 3
while [ $# -gt 0 ]; do
  case "$1" in
    --manual) [ $# -ge 2 ] || dung; MANUAL=$2; CO_MANUAL=1; shift 2 ;;
    *) echo "LỖI: tham số lạ \"$1\"." >&2; exit 2 ;;
  esac
done
case "$st" in
  "~") ;;
  x) echo "$TASK đã [x] — chạy lại để làm mới bằng chứng." ;;
  *) echo "TỪ CHỐI: $TASK chưa bắt đầu — chạy: aw task start $DIR $TASK" >&2; exit 1 ;;
esac
VF=$(tk_verify "$PLAN" "$TASK")
if [ -n "$CO_MANUAL" ]; then
  [ -z "$VF" ] || { echo "TỪ CHỐI: Verify của $TASK có lệnh \`$VF\` — máy chạy được thì không kiểm chứng thủ công." >&2; exit 1; }
  case "$MANUAL" in ""|*"<"*">"*) echo "TỪ CHỐI: --manual cần bằng chứng cụ thể (đã làm gì, thấy gì)." >&2; exit 1 ;; esac
elif [ -z "$VF" ]; then
  echo "TỪ CHỐI: dòng Verify của $TASK không có lệnh trong backtick." >&2
  echo "  Kiểm được bằng lệnh: sửa plan.md thành \"Verify: \`<lệnh>\` → <kết quả>\"." >&2
  echo "  Chỉ kiểm được bằng tay: aw task done $DIR $TASK --manual \"<đã làm gì, thấy gì>\"" >&2
  exit 1
fi

GOC="${AW_REPO:-$(git -C "$DIR" rev-parse --show-toplevel)}"
TMP="${TMPDIR:-/tmp}/aw-task.$$"
kq_don 'rm -f "$TMP" "$TMP.kq"'
if [ -n "$CO_MANUAL" ]; then
  printf '%s\n' "$MANUAL" > "$TMP"; ma=0
else
  echo "Chạy Verify của $TASK: $VF"
  echo "────────────────────────────────────────────────────"
  (cd "$GOC" && sh -c "$VF") > "$TMP" 2>&1
  ma=$?
  tail -n 40 "$TMP"
  echo "────────────────────────────────────────────────────"
fi
truoc=$(do_lien_tiep "$TASK")
if [ "$ma" -eq 0 ]; then do_moi=0; else do_moi=$((truoc + 1)); fi

# Ghi lại mục của task (bỏ mục cũ cùng mã).
{
  if [ -f "$KQ" ]; then
    # Gộp dòng trống liên tiếp ngoài khối code — chạy lại nhiều lần không dồn dòng trống.
    awk -v t="$TASK" '
      /^##[ \t]/ { bo = ($0 ~ ("^##[ \t]+" t "([ \t]|$)")) }
      bo { next }
      /^```/ { code = !code }
      !code && $0 == "" { if (trong) next; trong = 1; print; next }
      { trong = 0; print }
    ' "$KQ" | awk '{ l[NR] = $0 } END { n = NR; while (n > 0 && l[n] == "") n--; for (i = 1; i <= n; i++) print l[i] }'
  else
    echo "# Kết quả kiểm chứng task"
    echo ""
    echo "> File này do \`aw task done\` ghi tự động — không sửa tay."
    echo "> aw check implement chặn task [x] không có mục xanh ở đây."
  fi
  echo ""
  echo "## $TASK"
  echo ""
  if [ -n "$CO_MANUAL" ]; then
    echo "- Kiểm chứng: thủ công"
    echo "- Lệnh: \`\`"
  else
    echo "- Lệnh: \`$VF\`"
  fi
  echo "- Mã thoát: \`$ma\`"
  echo "- Đỏ liên tiếp: $do_moi"
  kc_dong_moi "$DIR"
  echo ""
  echo '```'
  tail -n 200 "$TMP"
  echo '```'
} > "$TMP.kq" && mv "$TMP.kq" "$KQ"

if [ "$ma" -ne 0 ]; then
  [ "$st" = x ] && tk_dat "$PLAN" "$TASK" "~"
  echo "$TASK: Verify ĐỎ (mã $ma) — ở [~]. Đỏ liên tiếp: $do_moi/$MAX_RED_RUNS."
  if [ "$do_moi" -ge "$MAX_RED_RUNS" ]; then
    echo "DỪNG: đỏ $do_moi lần liên tiếp. Ghi vào \"Unplanned\" (đã thử gì, lỗi gì) và báo người — đừng thử tiếp."
    exit 6
  fi
  exit 1
fi
tk_dat "$PLAN" "$TASK" "x" || { echo "LỖI: không ghi được ô Status của $TASK." >&2; exit 1; }
echo "$TASK: Verify XANH → [x]. Bằng chứng: $KQ"
[ -n "$CO_MANUAL" ] && echo "  (kiểm chứng thủ công — người rà soát sẽ thấy bằng chứng này)"
exit 0
