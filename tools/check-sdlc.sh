#!/usr/bin/env sh
# Kiểm engine có tuân thủ interface SDLC không (sdlc/stages/*.md, sdlc/invariants.md).
#
#   sh tools/check-sdlc.sh [<engine-root>]     # mặc định: engine chứa script này
#
# Chỉ kiểm CẤU TRÚC của ánh xạ stage → phase, không kiểm phase làm stage tốt tới đâu
# (docs/kien-truc.md § Interface SDLC). Chặn:
#   - File stage: id lệch tên file, thiếu purpose / provides, exit không phải machine | human | both,
#     requires không do stage trước nó provides, invariant không có trong sdlc/invariants.md.
#   - Invariant: thiếu "Enforced by:" (tools/check-*.sh, tools/lib/*.sh) hoặc "Tested by:"
#     (tools/tests/*.sh), hoặc trỏ tới file không có.
#   - Khối sdlc: của workflow.yaml: stage không có, status lạ, partial / gap thiếu note.
#   - Phase: thiếu implements hoặc implements stage không có; provides sai dạng, file không nằm
#     trong outputs, loại mà stage không khai; thứ tự phase lệch thứ tự stage.
#   - Stage: không phase nào implement mà không khai gap; gap mà có phase implement; partial mà
#     không phase nào implement; provides của các phase không phủ provides của stage; exit
#     human | both mà không phase nào có exit_human, machine | both mà không phase nào có exit_machine.
#   - Utility command khai implements (utility command không ánh xạ vào stage).
#
# Không đăng ký trong tools/lib/commands.sh: bảng đó cho `aw check` trên job dir của target
# repo; script này kiểm chính repo engine (như tools/check-release.sh), chạy bằng test.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tools/lib/result.sh"
kq_khai check-sdlc.sh \
  "0=ĐẠT — engine tuân thủ interface SDLC" \
  "1=KHÔNG ĐẠT — xem các dòng LỖI phía trên" \
  "2=SAI THAM SỐ — thừa tham số, hoặc không phải thư mục engine (thiếu workflow.yaml, sdlc/stages/)"
. "$ROOT/tools/lib/md.sh"

[ $# -le 1 ] || { echo "Dùng: sh tools/check-sdlc.sh [<engine-root>]" >&2; exit 2; }
E="${1:-$ROOT}"
if [ ! -f "$E/workflow.yaml" ] || [ ! -d "$E/sdlc/stages" ]; then
  echo "LỖI: \"$E\" thiếu workflow.yaml hoặc sdlc/stages/." >&2; exit 2
fi
W="${TMPDIR:-/tmp}/aw-check-sdlc.$$"
mkdir -p "$W"
kq_don 'rm -rf "$W"'

n_loi=0
loi() { echo "  [LỖI] $*"; n_loi=$((n_loi + 1)); }
# co <file> <dòng> -> 0 nếu file có đúng dòng đó
co() { [ -f "$1" ] && grep -qxF -- "$2" "$1"; }

# ---- invariant: "### INV-NNN — …" + "- Enforced by:" / "- Tested by:" với đường dẫn trong `…`
INV="$E/sdlc/invariants.md"
: > "$W/inv"
if [ -f "$INV" ]; then
  awk '
    { sub(/\r$/, "") }
    /^### INV-[0-9]+/ { match($0, /INV-[0-9]+/); cur = substr($0, RSTART, RLENGTH); print cur "|id|"; next }
    /^#/ { cur = ""; next }
    cur != "" && /^- (Enforced|Tested) by:/ {
      k = ($0 ~ /^- Enforced/) ? "enf" : "test"; s = $0; n = 0
      while (match(s, /`[^`]+`/)) { print cur "|" k "|" substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH); n++ }
      if (n == 0) print cur "|" k "|"
    }
  ' "$INV" > "$W/inv"
fi
for inv in $(awk -F'|' '$2 == "id" { print $1 }' "$W/inv"); do
  awk -F'|' -v i="$inv" '$1 == i && $2 == "enf" && $3 != ""' "$W/inv" | grep -q . \
    || loi "$inv: thiếu \"Enforced by:\" trỏ tới checker (tools/check-*.sh, tools/lib/*.sh)."
  awk -F'|' -v i="$inv" '$1 == i && $2 == "test" && $3 != ""' "$W/inv" | grep -q . \
    || loi "$inv: thiếu \"Tested by:\" trỏ tới test (tools/tests/*.sh)."
  awk -F'|' -v i="$inv" '$1 == i && $3 != "" { print $2 "|" $3 }' "$W/inv" > "$W/inv1"
  while IFS='|' read -r k p; do
    case "$k|$p" in
      enf\|tools/check-*.sh|enf\|tools/lib/*.sh|test\|tools/tests/*.sh) ;;
      enf\|*) loi "$inv: \"Enforced by:\" \`$p\` không phải tools/check-*.sh hay tools/lib/*.sh."; continue ;;
      *) loi "$inv: \"Tested by:\" \`$p\` không phải tools/tests/*.sh."; continue ;;
    esac
    [ -f "$E/$p" ] || loi "$inv: \`$p\` không tồn tại."
  done < "$W/inv1"
done

# ---- stage: theo thứ tự NN của tên file
: > "$W/stages"; : > "$W/prov"; i=0
for f in "$E"/sdlc/stages/[0-9]*.md; do
  [ -f "$f" ] || continue
  i=$((i + 1)); ten=${f##*/}; ten=${ten%.md}; ten=${ten#*-}
  id=$(fm_scalar "$f" id)
  if [ "$id" != "$ten" ]; then
    loi "sdlc/stages/${f##*/}: id \"$id\" lệch tên file (cần \"$ten\")."; id=$ten
  fi
  [ -n "$(fm_scalar "$f" purpose)" ] || loi "stage $id: thiếu purpose."
  ex=$(fm_scalar "$f" exit)
  case "$ex" in
    machine|human|both) ;;
    *) loi "stage $id: exit \"$ex\" — chỉ nhận machine | human | both." ;;
  esac
  fm_list "$f" requires > "$W/r"
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    awk -F'|' -v t="$t" '$2 == t' "$W/prov" | grep -q . \
      || loi "stage $id: requires \"$t\" — không stage nào trước nó provides."
  done < "$W/r"
  fm_list "$f" provides > "$W/p"
  [ -s "$W/p" ] || loi "stage $id: thiếu provides."
  while IFS= read -r t; do if [ -n "$t" ]; then echo "$id|$t" >> "$W/prov"; fi; done < "$W/p"
  for inv in $(fm_list "$f" invariants); do
    awk -F'|' -v i="$inv" '$1 == i && $2 == "id"' "$W/inv" | grep -q . \
      || loi "stage $id: invariant $inv không có trong sdlc/invariants.md."
  done
  echo "$i|$id|$ex" >> "$W/stages"
done
stage_co() { awk -F'|' -v s="$1" '$2 == s' "$W/stages" | grep -q .; }
stage_so() { awk -F'|' -v s="$1" '$2 == s { print $1 }' "$W/stages"; }

# ---- khối sdlc: của workflow.yaml
wf_sdlc "$E/workflow.yaml" > "$W/khai"
while IFS='|' read -r s st note; do
  [ -n "$s" ] || continue
  if ! stage_co "$s"; then loi "khối sdlc: khai stage \"$s\" không có trong sdlc/stages/."; continue; fi
  case "$st" in
    implemented) ;;
    partial|gap) [ -n "$note" ] || loi "stage $s: status $st thiếu note (nói phần engine không làm)." ;;
    *) loi "stage $s: status \"$st\" — chỉ nhận implemented | partial | gap." ;;
  esac
done < "$W/khai"
trang_thai() { _tt=$(awk -F'|' -v s="$1" '$1 == s { print $2; exit }' "$W/khai"); echo "${_tt:-implemented}"; }

# ---- phase: implements + provides, theo thứ tự trong workflow.yaml
: > "$W/phases"; : > "$W/pprov"; truoc=""; truoc_so=0
wf_phases "$E/workflow.yaml" > "$W/wf"
while IFS='|' read -r pid pfile _req _when; do
  [ -n "$pid" ] || continue
  src="$E/$pfile"
  if [ ! -f "$src" ]; then loi "phase $pid: không có file $pfile."; continue; fi
  s=$(fm_scalar "$src" implements)
  if [ -z "$s" ]; then loi "phase $pid: thiếu implements (stage SDLC phase này implement)."; continue; fi
  if ! stage_co "$s"; then loi "phase $pid: implements \"$s\" — không có stage đó trong sdlc/stages/."; continue; fi
  so=$(stage_so "$s")
  if [ "$so" -lt "$truoc_so" ]; then
    loi "phase $pid (stage $s) đứng sau phase $truoc — thứ tự phase lệch thứ tự stage."
  fi
  truoc_so=$so; truoc="$pid (stage $s)"
  em=$(fm_list "$src" exit_machine); eh=$(fm_list "$src" exit_human)
  echo "$pid|$s|${em:+1}|${eh:+1}" >> "$W/phases"
  fm_list "$src" outputs | sed 's/ (.*$//' > "$W/out"
  fm_list "$src" provides > "$W/pp"
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    case "$m" in
      *": "*) t=${m%%: *}; fo=${m#*: } ;;
      *) loi "phase $pid: provides \"$m\" — cần dạng <loại>: <file>."; continue ;;
    esac
    co "$W/out" "$fo" || loi "phase $pid: provides \"$m\" — $fo không nằm trong outputs."
    co "$W/prov" "$s|$t" || loi "phase $pid: provides \"$t\" — stage $s không khai loại đó."
    echo "$s|$t" >> "$W/pprov"
  done < "$W/pp"
done < "$W/wf"

# ---- stage ↔ phase
echo "Stage → phase (trạng thái khai trong workflow.yaml):"
while IFS='|' read -r _so s ex; do
  st=$(trang_thai "$s")
  ph=$(awk -F'|' -v s="$s" '$2 == s { printf "%s%s", (n++ ? ", " : ""), $1 }' "$W/phases")
  printf '  %-10s %-12s %s\n' "$s" "$st" "${ph:-—}"
  if [ "$st" = gap ]; then
    [ -z "$ph" ] || loi "stage $s: khai gap nhưng phase $ph implement nó."
    continue
  fi
  if [ -z "$ph" ]; then
    if [ "$st" = partial ]; then loi "stage $s: khai partial nhưng không phase nào implement."
    else loi "stage $s: không phase nào implement và không khai gap (khối sdlc: của workflow.yaml)."; fi
    continue
  fi
  awk -F'|' -v s="$s" '$1 == s { print $2 }' "$W/prov" > "$W/sp"
  while IFS= read -r t; do
    co "$W/pprov" "$s|$t" || loi "stage $s: không phase nào provides \"$t\"."
  done < "$W/sp"
  case "$ex" in
    human|both) awk -F'|' -v s="$s" '$2 == s && $4 == 1' "$W/phases" | grep -q . \
      || loi "stage $s: exit $ex nhưng không phase nào có exit_human." ;;
  esac
  case "$ex" in
    machine|both) awk -F'|' -v s="$s" '$2 == s && $3 == 1' "$W/phases" | grep -q . \
      || loi "stage $s: exit $ex nhưng không phase nào có exit_machine." ;;
  esac
done < "$W/stages"

# ---- utility command không ánh xạ vào stage
wf_commands "$E/workflow.yaml" > "$W/cmd"
while IFS='|' read -r cid cfile; do
  [ -n "$cid" ] && [ -f "$E/$cfile" ] || continue
  [ -z "$(fm_scalar "$E/$cfile" implements)" ] \
    || loi "utility command $cid: khai implements — utility command không ánh xạ vào stage SDLC."
done < "$W/cmd"

[ "$n_loi" = 0 ] || exit 1
echo "Engine tuân thủ interface SDLC."
exit 0
