#!/usr/bin/env sh
# Tổng kết cuối việc (SP9b): phần máy tính được, danh sách lần bị chặn, và — khi có cờ — ghi jobs.tsv.
#
#   aw journal retro <thư-mục-việc>                       in phần máy và các lần bị chặn (không ghi)
#   aw journal retro <thư-mục-việc> --nham <n,…> --phut <n> [--vuong "<một dòng>"]
#                                   [--gay-boi <việc|PR> --lop <layer>]     ghi jobs.tsv
#   aw journal retro <thư-mục-việc> --bo-qua             ghi chỉ phần máy, phần người để "-"
#
# Chạy trong worktree của việc (không ở checkout chính). Gọi qua journal.sh (dispatch "retro").
# jobs.tsv: một dòng mỗi việc, chạy lại thì thay dòng cũ. Cột version là cột cuối, như mọi nguồn khác.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai journal-retro.sh \
  "0=XONG — đã in phần máy, hoặc đã ghi jobs.tsv" \
  "2=SAI THAM SỐ — xem thông báo phía trên" \
  "1=KHÔNG GHI ĐƯỢC jobs.tsv — xem thông báo phía trên" \
  "6=ĐANG Ở CHECKOUT CHÍNH — retro chạy trong worktree của việc"
. "$HERE/lib/md.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/worktree.sh"
. "$HERE/lib/journal-util.sh"

[ -n "${AW_CONFIG:-}" ] || { echo "LỖI: thiếu AW_CONFIG — gọi qua aw." >&2; exit 9; }
AWR=${AW_REPO:-.}
JDIR="$AW_CONFIG/journal"

usage() { echo "Dùng: aw journal retro <thư-mục-việc> [--nham <n,…> --phut <n>] [--vuong \"…\"] [--gay-boi <việc|PR> --lop <layer>] | --bo-qua" >&2; }
sai() { echo "LỖI: $1" >&2; usage; exit 2; }

[ $# -ge 1 ] || { usage; exit 2; }
DIR=$1; shift
NHAM=""; PHUT=""; VUONG=""; GAY=""; LOP=""; BO=0
while [ $# -gt 0 ]; do
  case "$1" in
    --nham)   [ $# -ge 2 ] || sai "--nham cần danh sách số."; NHAM=$2; shift 2 ;;
    --phut)   [ $# -ge 2 ] || sai "--phut cần một số."; PHUT=$2; shift 2 ;;
    --vuong)  [ $# -ge 2 ] || sai "--vuong cần một dòng chữ."; VUONG=$2; shift 2 ;;
    --gay-boi) [ $# -ge 2 ] || sai "--gay-boi cần việc hoặc PR."; GAY=$2; shift 2 ;;
    --lop)    [ $# -ge 2 ] || sai "--lop cần một layer."; LOP=$2; shift 2 ;;
    --bo-qua) BO=1; shift ;;
    *) sai "tham số lạ \"$1\"." ;;
  esac
done

[ -f "$DIR/intake.md" ] || sai "không có $DIR/intake.md — retro chỉ chạy trên thư mục việc."
if wt_la_chinh "$AWR"; then
  echo "ĐANG Ở CHECKOUT CHÍNH — retro chạy trong worktree của việc." >&2
  exit 6
fi

VIEC=$(basename "$(CDPATH= cd -- "$DIR" && pwd)")
LOAI=$(kc_loai "$DIR")
CO_NGUOI=0
{ [ "$BO" = 1 ] || [ -n "$NHAM" ] || [ -n "$PHUT" ] || [ -n "$VUONG" ] || [ -n "$GAY" ] || [ -n "$LOP" ]; } && CO_NGUOI=1

# Các lần bị chặn của việc (mã khác 0 trong checks.tsv), đánh số theo thời gian.
CK="$JDIR/checks.tsv"
CHAN=""
if [ -f "$CK" ]; then
  CHAN=$(awk -F'\t' -v v="$VIEC" '$2 == v && $4 != 0 { k++; printf "  #%d  %s  %-10s %s\n", k, $1, $3, $5 }' "$CK")
fi
N_CHAN=0
[ -n "$CHAN" ] && N_CHAN=$(printf '%s\n' "$CHAN" | wc -l | tr -d ' ')

if [ "$CO_NGUOI" = 1 ]; then
  if [ "$BO" = 1 ] && { [ -n "$NHAM" ] || [ -n "$PHUT" ] || [ -n "$VUONG" ] || [ -n "$GAY" ] || [ -n "$LOP" ]; }; then
    sai "--bo-qua không đi kèm cờ của người."
  fi
  if [ -n "$PHUT" ]; then
    case "$PHUT" in *[!0-9]*) sai "--phut phải là số nguyên ≥ 0." ;; esac
  fi
  if [ -n "$NHAM" ]; then
    # Chuẩn hoá (bỏ số 0 đầu, bỏ trùng) để report khớp đúng số thứ tự lần chặn.
    NORM=""
    for x in $(printf '%s' "$NHAM" | tr ',' ' '); do
      case "$x" in ""|*[!0-9]*) sai "--nham phải là các số cách nhau bằng dấu phẩy." ;; esac
      [ "${#x}" -le 6 ] || sai "--nham $x quá lớn."
      x=$(printf '%s' "$x" | sed 's/^0*//')
      [ -n "$x" ] || sai "--nham phải từ 1."
      if [ "$x" -gt "$N_CHAN" ]; then sai "--nham $x không có trong danh sách lần bị chặn (1–$N_CHAN)."; fi
      case ",$NORM," in *",$x,"*) ;; *) NORM="${NORM:+$NORM,}$x" ;; esac
    done
    NHAM=$NORM
  fi
  if [ -n "$LOP" ]; then
    case " $LOP_HOP_LE " in *" $LOP "*) ;; *) sai "--lop phải là một trong: $LOP_HOP_LE." ;; esac
  fi
  if [ -n "$GAY" ] || [ -n "$LOP" ]; then
    [ "$LOAI" = bugfix ] || sai "--gay-boi và --lop chỉ dùng cho việc bugfix (việc này là \"$LOAI\")."
    [ -n "$GAY" ] && [ -n "$LOP" ] || sai "--gay-boi và --lop đi cùng nhau."
  fi
fi

# Phần máy.
VER=$(sed -n 's/^- \*\*Engine:\*\* *//p' "$DIR/intake.md" | sed 's/<!--.*//; s/[` \r]//g' | head -n 1)
VER=${VER:-$(jv_version "$HERE")}

FASES=""
if [ -f "$JDIR/phases.tsv" ]; then
  FASES=$(awk -F'\t' -v v="$VIEC" '$2 == v && !s[$3]++ { out = out (out == "" ? "" : ",") $3 } END { print out }' "$JDIR/phases.tsv")
fi
FASES=${FASES:--}

if kc_bo_design "$DIR"; then DESIGN=skipped; else DESIGN=ran; fi

FILE=-; DONG=-
BASE=$(intake_base_dong "$DIR")
REF=${BASE%% *}
if [ -n "$REF" ]; then
  MB=$(git -C "$AWR" merge-base "$REF" HEAD 2>/dev/null)
  if [ -n "$MB" ]; then
    read -r FILE DONG <<STAT
$(git -C "$AWR" diff --numstat "$MB" HEAD -- . ':(exclude)docs/sdlc' ':(exclude).agent-workflow' 2>/dev/null | awk -F'\t' '{ f++; d += $1 + $2 } END { printf "%d %d\n", f + 0, d + 0 }')
STAT
  fi
fi

TRUOT=""
if [ -f "$CK" ]; then
  TRUOT=$(awk -F'\t' -v v="$VIEC" '$2 == v && $4 != 0 { n[$3]++; if (!($3 in o)) { o[$3] = 1; ord[++k] = $3 } } END { for (i = 1; i <= k; i++) printf "%s%s:%d", (i > 1 ? "," : ""), ord[i], n[ord[i]] }' "$CK")
fi
TRUOT=${TRUOT:--}

TICK=0
if [ -f "$JDIR/approvals.tsv" ]; then
  TICK=$(awk -F'\t' -v v="$VIEC" '$2 == v { n++ } END { print n + 0 }' "$JDIR/approvals.tsv")
fi

NOW=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
set --
for f in checks phases; do
  if [ -f "$JDIR/$f.tsv" ]; then set -- "$@" "$JDIR/$f.tsv"; fi
done
T0=""
[ $# -gt 0 ] && T0=$(awk -F'\t' -v v="$VIEC" '$2 == v && (m == "" || $1 < m) { m = $1 } END { print m }' "$@")
GIAY=-
if [ -n "$T0" ]; then
  GIAY=$(awk -v a="$T0" -v b="$NOW" "$JU_EPOCH"' BEGIN { print epoch(b) - epoch(a) }')
fi

# Phần người (chỉ khi có cờ).
NHAM_OUT=-; PHUT_OUT=-; VUONG_OUT=-; GAY_OUT=-; LOP_OUT=-
if [ "$CO_NGUOI" = 1 ]; then
  [ -n "$NHAM" ] && NHAM_OUT=$NHAM
  [ -n "$PHUT" ] && PHUT_OUT=$PHUT
  [ -n "$VUONG" ] && VUONG_OUT=$(bay "$VUONG")
  [ -n "$GAY" ] && GAY_OUT=$(bay "$GAY")
  [ -n "$LOP" ] && LOP_OUT=$LOP
fi
[ -n "$VUONG_OUT" ] || VUONG_OUT=-

echo "Việc: $VIEC (loại $LOAI, version $VER)"
echo "Phần máy:"
echo "  phase:   $FASES"
echo "  design:  $DESIGN"
echo "  file:    $FILE"
echo "  dòng:    $DONG"
echo "  trượt:   $TRUOT"
echo "  tick:    $TICK"
echo "  giây:    $GIAY"
echo ""
echo "Lần bị chặn ($N_CHAN):"
if [ -n "$CHAN" ]; then printf '%s\n' "$CHAN"; else echo "  (không có)"; fi

if [ "$CO_NGUOI" = 0 ] && [ "$BO" = 0 ]; then
  echo ""
  echo "Trả lời để ghi: aw journal retro $DIR --nham <số…> --phut <n> [--vuong \"…\"] [--gay-boi … --lop …]  hoặc --bo-qua"
  exit 0
fi

ROW=$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$NOW" "$VIEC" "$LOAI" "$FASES" "$DESIGN" "$FILE" "$DONG" "$TRUOT" "$TICK" "$GIAY" \
  "$NHAM_OUT" "$PHUT_OUT" "$VUONG_OUT" "$GAY_OUT" "$LOP_OUT" "$VER")
mkdir -p "$JDIR" || exit 2
TMPF="$JDIR/jobs.tsv.$$"
if { if [ -f "$JDIR/jobs.tsv" ]; then awk -F'\t' -v v="$VIEC" '$2 != v' "$JDIR/jobs.tsv"; fi; printf '%s\n' "$ROW"; } > "$TMPF" && mv "$TMPF" "$JDIR/jobs.tsv"; then
  echo ""
  echo "Đã ghi jobs.tsv: $VIEC"
  exit 0
fi
rm -f "$TMPF"
echo "KHÔNG GHI ĐƯỢC $JDIR/jobs.tsv — kiểm quyền ghi thư mục nhật ký." >&2
exit 1
