#!/usr/bin/env sh
# Kiểm engine có tuân thủ interface SDLC không (sdlc/stages/*.md, sdlc/invariants.md).
#
#   sh tools/check-sdlc.sh [<engine-root>]     # mặc định: engine chứa script này
#
# Chỉ kiểm CẤU TRÚC của ánh xạ stage → phase, không kiểm phase làm stage tốt tới đâu
# (docs/kien-truc.md § Interface SDLC). Chặn:
#   - File stage: id lệch tên file, thiếu purpose / provides, exit không phải machine | human | both,
#     requires không do stage trước nó provides, invariant không có trong sdlc/invariants.md,
#     skippable không phải true | false. Capability (thân file, "### CAP-<stage>-NN — <tên>"):
#     không có cái nào, heading sai dạng hoặc mang stage khác (kể cả #### / Cap- / heading lạ trong ## Capabilities), id trùng, thiếu "- Rule:" /
#     "- Judged by:", Judged by không phải machine | agent | human.
#   - Invariant: thiếu "Enforced by:" (tools/check-*.sh, tools/lib/*.sh) hoặc "Tested by:"
#     (tools/tests/*.sh), hoặc trỏ tới file không có; ca test nêu tên ("…" sau file) không có trong file.
#   - Khối sdlc: của workflow.yaml: stage không có, còn khoá status (trạng thái do máy suy ra).
#   - Phase: thiếu implements hoặc implements stage không có; provides sai dạng, file không nằm
#     trong outputs, loại mà stage không khai và không profile nào thêm; thứ tự phase lệch thứ tự stage;
#     capabilities: id không có, thuộc stage khác stage phase implements, hoặc không nhận cái nào.
#   - Stage: trạng thái suy ra từ capability được phase nhận (hết = implemented, một phần = partial,
#     không = gap); partial / gap thiếu note, implemented còn note; provides của các phase không phủ
#     provides của stage; exit human | both mà không phase nào có exit_human, machine | both mà không
#     phase nào có exit_machine.
#   - Utility command khai implements hoặc capabilities (utility command không ánh xạ vào stage).
#   - Profile (sdlc/profiles/<job-type>.md): tập profile khác tập job type engine nhận (LOAI_HOP_LE,
#     nguồn check-intake.sh kiểm); id lệch tên file; thiếu purpose.
#     skippable / skipped: stage không có, có cả hai, skippable: false, là gap; lệch hành vi engine —
#     stage mà mọi phase required: false phải skippable, design phải khớp kc_bo_design (hỏi thẳng
#     engine), stage khác luôn chạy. adds_provides: sai dạng, stage không có hoặc có thể không chạy,
#     không phase nào của stage map loại đó ra file. adds_requires: sai dạng, stage không có hoặc bị
#     bỏ, không stage nào trước nó luôn chạy và provides loại đó. adds_invariants không có.
#   In bảng ánh xạ stage → phase, bảng capability còn thiếu (roadmap), ma trận job type × stage và loại có thể vắng theo profile (requires mà mọi stage cung cấp đều
#   bỏ được / bị bỏ — khai qua skippable / skipped, không ngầm định).
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
      while (match(s, /`[^`]+`/)) {
        p = substr(s, RSTART + 1, RLENGTH - 2); print cur "|" k "|" p; s = substr(s, RSTART + RLENGTH); n++
        # Tested by: `<file>` "ca", "ca" — tên ca test cụ thể trong file đó
        while (k == "test" && match(s, /^[ ,]*"[^"]+"/)) {
          q = substr(s, RSTART, RLENGTH); sub(/^[ ,]*"/, "", q); sub(/"$/, "", q)
          print cur "|case|" p "|" q; s = substr(s, RSTART + RLENGTH)
        }
      }
      if (n == 0) print cur "|" k "|"
    }
  ' "$INV" > "$W/inv"
fi
for inv in $(awk -F'|' '$2 == "id" { print $1 }' "$W/inv"); do
  awk -F'|' -v i="$inv" '$1 == i && $2 == "enf" && $3 != ""' "$W/inv" | grep -q . \
    || loi "$inv: thiếu \"Enforced by:\" trỏ tới checker (tools/check-*.sh, tools/lib/*.sh)."
  awk -F'|' -v i="$inv" '$1 == i && $2 == "test" && $3 != ""' "$W/inv" | grep -q . \
    || loi "$inv: thiếu \"Tested by:\" trỏ tới test (tools/tests/*.sh)."
  awk -F'|' -v i="$inv" '$1 == i && $2 != "case" && $3 != "" { print $2 "|" $3 }' "$W/inv" > "$W/inv1"
  while IFS='|' read -r k p; do
    case "$k|$p" in
      enf\|tools/check-*.sh|enf\|tools/lib/*.sh|test\|tools/tests/*.sh) ;;
      enf\|*) loi "$inv: \"Enforced by:\" \`$p\` không phải tools/check-*.sh hay tools/lib/*.sh."; continue ;;
      *) loi "$inv: \"Tested by:\" \`$p\` không phải tools/tests/*.sh."; continue ;;
    esac
    [ -f "$E/$p" ] || loi "$inv: \`$p\` không tồn tại."
  done < "$W/inv1"
  awk -F'|' -v i="$inv" '$1 == i && $2 == "case" { print $3 "|" $4 }' "$W/inv" > "$W/inv1"
  while IFS='|' read -r p ca; do
    [ ! -f "$E/$p" ] || grep -qF -- "\"$ca\"" "$E/$p" || loi "$inv: ca \"$ca\" không có trong $p."
  done < "$W/inv1"
done

# ---- stage: theo thứ tự NN của tên file
: > "$W/stages"; : > "$W/prov"; : > "$W/cap"; i=0
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
  sk=$(fm_scalar "$f" skippable)
  case "$sk" in
    ""|true) sk=true ;;
    false) ;;
    *) loi "stage $id: skippable \"$sk\" — chỉ nhận true | false."; sk=true ;;
  esac
  echo "$i|$id|$ex|$sk" >> "$W/stages"
  # capability: "### CAP-<stage>-NN — <tên>" + "- Rule:" + "- Judged by:", khối hết ở heading kế tiếp
  md_body "$f" | awk -v s="$id" '
    function dong() {
      if (cur == "") return
      if (!rule) print "E|" cur ": thiếu \"- Rule:\" — thêm một câu nói điều phải đúng."
      if (!coj) print "E|" cur ": thiếu \"- Judged by:\" — thêm machine | agent | human."
      else if (jd != "machine" && jd != "agent" && jd != "human")
        print "E|" cur ": Judged by \"" jd "\" — chỉ nhận machine | agent | human."
      print "C|" cur "|" jd "|" ten; cur = ""
    }
    { sub(/\r$/, "") }
    /^## Capabilities[ \t]*$/ { dong(); trong = 1; next }
    /^##? / { dong(); trong = 0; next }
    /^#/ {
      dong()
      # heading khác trong ## Capabilities, hay heading trông như capability (####, Cap-): báo, không lờ đi
      if ($0 !~ /^### CAP/) {
        if (trong || toupper($0) ~ /^#+ *CAP-/)
          print "E|stage " s ": heading capability \"" $0 "\" sai dạng — cần \"### CAP-" s "-NN — <tên>\"."
        next
      }
      c = $0; sub(/^### /, "", c); sub(/ — .*$/, "", c); st = c; sub(/^CAP-/, "", st); sub(/-[0-9][0-9]$/, "", st)
      if ($0 !~ /^### CAP-[a-z]+-[0-9][0-9] — ./ || st != s) {
        print "E|stage " s ": heading capability \"" $0 "\" sai dạng — cần \"### CAP-" s "-NN — <tên>\"."; next
      }
      if (c in da_co) { print "E|stage " s ": " c " trùng — mỗi id chỉ khai một lần."; next }
      da_co[c] = 1; cur = c; ten = $0; sub(/^### [^ ]+ — /, "", ten); rule = 0; coj = 0; jd = ""; next
    }
    cur != "" && /^- Rule:/ { rule = 1 }
    cur != "" && /^- Judged by:/ { coj = 1; jd = $0; sub(/^- Judged by:[ \t]*/, "", jd); sub(/[ \t]+$/, "", jd) }
    END { dong() }
  ' > "$W/c1"
  grep -q '^C|' "$W/c1" \
    || loi "stage $id: không có capability — thêm \"## Capabilities\" với ít nhất một \"### CAP-$id-NN — <tên>\"."
  while IFS= read -r l; do
    case "$l" in
      E\|*) loi "${l#E|}" ;;
      C\|*) echo "$id|${l#C|}" >> "$W/cap" ;;
    esac
  done < "$W/c1"
done
stage_co() { awk -F'|' -v s="$1" '$2 == s' "$W/stages" | grep -q .; }
stage_so() { awk -F'|' -v s="$1" '$2 == s { print $1 }' "$W/stages"; }
# cap_co <CAP-id> -> 0 nếu capability có trong sdlc/stages/; cap_stage <CAP-id> -> stage của nó
cap_co() { awk -F'|' -v c="$1" '$2 == c' "$W/cap" | grep -q .; }
cap_stage() { awk -F'|' -v c="$1" '$2 == c { print $1; exit }' "$W/cap"; }

# ---- loại artifact profile thêm (adds_provides của sdlc/profiles/*.md): phase được map chúng ra file
: > "$W/padd"
for f in "$E"/sdlc/profiles/*.md; do
  [ -f "$f" ] || continue
  fm_list "$f" adds_provides | awk '/: / { s = $0; sub(/: .*/, "", s); t = $0; sub(/^[^:]*: /, "", t); print s "|" t }' >> "$W/padd"
done

# ---- khối sdlc: của workflow.yaml
wf_sdlc "$E/workflow.yaml" > "$W/khai"
while IFS='|' read -r s st note; do
  [ -n "$s" ] || continue
  if ! stage_co "$s"; then loi "khối sdlc: khai stage \"$s\" không có trong sdlc/stages/."; continue; fi
  [ -z "$st" ] \
    || loi "khối sdlc: stage $s còn khoá status — xoá dòng status; trạng thái do máy suy ra từ capabilities: của phase."
done < "$W/khai"
# co_note <stage> -> 0 nếu khối sdlc: có note cho stage đó
co_note() { awk -F'|' -v s="$1" '$1 == s && $3 != "" { co = 1 } END { exit !co }' "$W/khai"; }

# ---- phase: implements + provides, theo thứ tự trong workflow.yaml
: > "$W/phases"; : > "$W/pprov"; : > "$W/nhan"; truoc=""; truoc_so=0
wf_phases "$E/workflow.yaml" > "$W/wf"
while IFS='|' read -r pid pfile preq _when; do
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
  echo "$pid|$s|${em:+1}|${eh:+1}|$preq" >> "$W/phases"
  fm_list "$src" outputs | sed 's/ (.*$//' > "$W/out"
  fm_list "$src" provides > "$W/pp"
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    case "$m" in
      *": "*) t=${m%%: *}; fo=${m#*: } ;;
      *) loi "phase $pid: provides \"$m\" — cần dạng <loại>: <file>."; continue ;;
    esac
    co "$W/out" "$fo" || loi "phase $pid: provides \"$m\" — $fo không nằm trong outputs."
    co "$W/prov" "$s|$t" || co "$W/padd" "$s|$t" \
      || loi "phase $pid: provides \"$t\" — stage $s không khai loại đó, không profile nào thêm."
    echo "$s|$t" >> "$W/pprov"
  done < "$W/pp"
  for c in $(fm_list "$src" capabilities); do
    if ! cap_co "$c"; then
      loi "phase $pid: capabilities \"$c\" — không có capability đó; sửa id hoặc thêm vào sdlc/stages/."; continue
    fi
    cs=$(cap_stage "$c")
    if [ "$cs" != "$s" ]; then
      loi "phase $pid: capabilities \"$c\" thuộc stage $cs, phase implements $s — chuyển id sang phase của stage $cs."; continue
    fi
    echo "$pid|$s|$c" >> "$W/nhan"
  done
  awk -F'|' -v p="$pid" '$1 == p' "$W/nhan" | grep -q . \
    || loi "phase $pid: implements $s nhưng không nhận capability nào — thêm id vào capabilities: (xem sdlc/stages/)."
done < "$W/wf"

# trang_thai <stage> -> implemented | partial | gap, suy ra: capability của stage được phase nhận hết / một phần / không
trang_thai() {
  awk -F'|' -v s="$1" 'FILENAME == ARGV[1] { if ($1 == s) n++; next }
    $2 == s && !($3 in da) { da[$3] = 1; m++ }
    END { print (m + 0 == 0) ? "gap" : (m == n) ? "implemented" : "partial" }' "$W/cap" "$W/nhan"
}

# ---- stage ↔ phase
echo "Stage → phase (trạng thái suy ra từ capabilities: của phase):"
: > "$W/thieu"
while IFS='|' read -r _so s ex _sk; do
  st=$(trang_thai "$s")
  ph=$(awk -F'|' -v s="$s" '$2 == s { printf "%s%s", (n++ ? ", " : ""), $1 }' "$W/phases")
  printf '  %-10s %-12s %s\n' "$s" "$st" "${ph:-—}"
  if [ "$st" = implemented ]; then
    ! co_note "$s" || loi "stage $s: suy ra implemented nhưng khối sdlc: còn note — xoá mục stage $s khỏi khối sdlc:."
  else
    co_note "$s" || loi "stage $s: suy ra $st nhưng khối sdlc: không có note — thêm note nói phần thiếu và lý do."
    echo "$s|$st" >> "$W/thieu"
  fi
  [ "$st" != gap ] || continue
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
if [ -s "$W/thieu" ]; then
  echo "Capability còn thiếu (roadmap — mô tả ở sdlc/stages/):"
  while IFS='|' read -r s st; do
    echo "  $s ($st): $(awk -F'|' -v s="$s" '$1 == s { print $3; exit }' "$W/khai")"
    awk -F'|' -v s="$s" 'FILENAME == ARGV[1] { if ($2 == s) da[$3] = 1; next }
      $1 == s && !($2 in da) { printf "    %s  %-7s  %s\n", $2, $3, $4 }' "$W/nhan" "$W/cap"
  done < "$W/thieu"
fi

# ---- profile theo job type (sdlc/profiles/<job-type>.md)
# Danh sách job type: LOAI_HOP_LE, nguồn check-intake.sh kiểm "Type" — không giữ bản thứ hai.
LOAI=$(sed -n 's/^LOAI_HOP_LE="\(.*\)"[[:space:]]*$/\1/p' "$E/tools/lib/cross-check.sh" 2>/dev/null | head -1)
[ -n "$LOAI" ] || loi "không đọc được danh sách job type (LOAI_HOP_LE trong tools/lib/cross-check.sh) — nguồn check-intake.sh kiểm Type."
for t in $LOAI; do
  [ -f "$E/sdlc/profiles/$t.md" ] || loi "job type $t: thiếu sdlc/profiles/$t.md."
done
grep -q '^kc_bo_design()' "$E/tools/lib/cross-check.sh" 2>/dev/null \
  || loi "không thấy kc_bo_design trong tools/lib/cross-check.sh — không biết engine bỏ design với job type nào."
# bo_design <job type> <Design:> -> 0 nếu engine không chạy phase design với việc đó (hỏi thẳng engine)
bo_design() {
  mkdir -p "$W/thu"
  printf -- '- **Type:** %s\n' "$1" > "$W/thu/intake.md"
  printf -- '- **Design:** %s\n' "$2" > "$W/thu/spec.md"
  ( AW_CONFIG="$W"; . "$E/tools/lib/md.sh"; . "$E/tools/lib/cross-check.sh"; kc_bo_design "$W/thu" ) > /dev/null 2>&1
}
# kieu <stage> -> tuy | bo | rỗng (luôn chạy) theo profile đang xét ($PK: " <stage>=<kiểu> …")
kieu() { case "$PK" in *" $1=tuy "*) echo tuy ;; *" $1=bo "*) echo bo ;; esac; }
# la_gap <stage> -> 0 nếu stage suy ra gap (không phase nào implement nó)
GAP=" $(awk -F"|" '$2 == "gap" { printf "%s ", $1 }' "$W/thieu")"
la_gap() { case "$GAP" in *" $1 "*) return 0 ;; esac; return 1; }
# luon_co <stage> <loại> -> 0 nếu một stage đứng trước, luôn chạy với profile đang xét, provides
# loại đó ($W/pq: provides của stage + adds_provides của profile; $W/luon: "số|stage" luôn chạy)
luon_co() {
  awk -F'|' -v n="$(stage_so "$1")" -v t="$2" 'FILENAME == ARGV[1] { so[$2] = $1; next }
    $2 == t && ($1 in so) && so[$1] + 0 < n + 0 { co = 1; exit } END { exit !co }' "$W/luon" "$W/pq"
}
: > "$W/mtran"; : > "$W/vang"
for f in "$E"/sdlc/profiles/*.md; do
  [ -f "$f" ] || continue
  ten=${f##*/}; ten=${ten%.md}
  id=$(fm_scalar "$f" id)
  if [ "$id" != "$ten" ]; then
    loi "sdlc/profiles/${f##*/}: id \"$id\" lệch tên file (cần \"$ten\")."; id=$ten
  fi
  if [ -n "$LOAI" ]; then
    case " $LOAI " in
      *" $id "*) ;;
      *) loi "profile $id: không phải job type engine hỗ trợ (LOAI_HOP_LE: $LOAI)."; continue ;;
    esac
  fi
  [ -n "$(fm_scalar "$f" purpose)" ] || loi "profile $id: thiếu purpose."
  # stage bỏ được / luôn bỏ: phải có, được phép bỏ, không là gap
  PK=" "
  for k in skippable skipped; do
    if [ "$k" = skippable ]; then kk=tuy; else kk=bo; fi
    for s in $(fm_list "$f" "$k"); do
      if ! stage_co "$s"; then loi "profile $id: $k \"$s\" — không có stage đó."; continue; fi
      if [ -n "$(kieu "$s")" ]; then loi "profile $id: stage $s vừa skippable vừa skipped."; continue; fi
      awk -F'|' -v s="$s" '$2 == s && $4 == "false"' "$W/stages" | grep -q . \
        && loi "profile $id: stage $s không được bỏ (skippable: false trong sdlc/stages/)."
      ! la_gap "$s" \
        || loi "profile $id: stage $s là gap — engine không chạy nó với job type nào."
      PK="$PK$s=$kk "
    done
  done
  # khớp hành vi engine: phase required: false ⇒ skippable; design ⇔ kc_bo_design; còn lại luôn chạy
  hang=""; : > "$W/luon"
  while IFS='|' read -r _so s _ex _sk; do
    k=$(kieu "$s")
    case "$k" in tuy) kn=skippable; o="tuỳ" ;; bo) kn=skipped; o="bỏ" ;; *) kn=""; o="chạy" ;; esac
    if la_gap "$s"; then hang="$hang|gap"; continue; fi
    hang="$hang|$o"
    if [ -z "$k" ]; then echo "$_so|$s" >> "$W/luon"; fi
    awk -F'|' -v s="$s" '$2 == s { print $1 "|" $5 }' "$W/phases" > "$W/sph"
    [ -s "$W/sph" ] || continue
    ph=$(awk -F'|' '{ printf "%s%s", (n++ ? ", " : ""), $1 }' "$W/sph")
    if ! awk -F'|' '$2 != "false"' "$W/sph" | grep -q .; then
      case "$k" in
        bo) loi "profile $id: stage $s khai skipped nhưng phase $ph vẫn chạy được (required: false) — khai skippable." ;;
        "") loi "profile $id: stage $s có thể không chạy (phase $ph required: false) nhưng profile không khai skippable." ;;
      esac
    elif [ "$s" = design ]; then
      if bo_design "$id" required; then can=bo
      elif bo_design "$id" skip; then can=tuy
      else can=""; fi
      case "$can|$k" in
        "|tuy"|"|bo") loi "profile $id: khai design $kn nhưng engine luôn chạy design với $id." ;;
        "tuy|") loi "profile $id: engine bỏ được design với $id (Design: skip) nhưng profile không khai skippable." ;;
        "tuy|bo") loi "profile $id: engine chỉ bỏ design với $id khi spec khai Design: skip nhưng profile khai skipped." ;;
        "bo|tuy") loi "profile $id: engine luôn bỏ design với $id nhưng profile khai skippable." ;;
        "bo|") loi "profile $id: engine luôn bỏ design với $id nhưng profile không khai skipped." ;;
      esac
    elif [ -n "$k" ]; then
      loi "profile $id: khai $s $kn nhưng engine luôn chạy $s (phase $ph required: true)."
    fi
  done < "$W/stages"
  echo "$id$hang" >> "$W/mtran"
  # loại artifact thêm: do stage luôn chạy cung cấp, phase của stage đó map ra file
  : > "$W/pt"
  fm_list "$f" adds_provides > "$W/l"
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    case "$m" in
      *": "*) s=${m%%: *}; t=${m#*: } ;;
      *) loi "profile $id: adds_provides \"$m\" — cần dạng <stage>: <loại>."; continue ;;
    esac
    if ! stage_co "$s"; then loi "profile $id: adds_provides \"$m\" — không có stage $s."; continue; fi
    case "$(kieu "$s")" in
      tuy) loi "profile $id: adds_provides \"$m\" — stage $s có thể không chạy với $id." ;;
      bo) loi "profile $id: adds_provides \"$m\" — stage $s không chạy với $id." ;;
      *) echo "$s|$t" >> "$W/pt" ;;
    esac
    co "$W/pprov" "$s|$t" || loi "profile $id: adds_provides \"$m\" — không phase nào của stage $s map loại đó ra file."
  done < "$W/l"
  cat "$W/prov" "$W/pt" > "$W/pq"
  fm_list "$f" adds_requires > "$W/l"
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    case "$m" in
      *": "*) s=${m%%: *}; t=${m#*: } ;;
      *) loi "profile $id: adds_requires \"$m\" — cần dạng <stage>: <loại>."; continue ;;
    esac
    if ! stage_co "$s"; then loi "profile $id: adds_requires \"$m\" — không có stage $s."; continue; fi
    if [ "$(kieu "$s")" = bo ]; then loi "profile $id: adds_requires \"$m\" — stage $s không chạy với $id."; continue; fi
    luon_co "$s" "$t" || loi "profile $id: adds_requires \"$m\" — không stage nào trước $s luôn chạy và provides loại đó."
  done < "$W/l"
  # requires của stage còn chạy mà mọi stage cung cấp đều bỏ được / bị bỏ: có thể vắng (khai qua skippable / skipped)
  vang=""
  for sf in "$E"/sdlc/stages/[0-9]*.md; do
    [ -f "$sf" ] || continue
    s=${sf##*/}; s=${s%.md}; s=${s#*-}
    [ "$(kieu "$s")" != bo ] && ! la_gap "$s" || continue
    for t in $(fm_list "$sf" requires); do
      luon_co "$s" "$t" && continue
      case " $vang " in *" $t "*) ;; *) vang="${vang:+$vang }$t" ;; esac
    done
  done
  if [ -n "$vang" ]; then echo "  $id: có thể vắng: $(echo "$vang" | sed 's/ /, /g')" >> "$W/vang"; fi
  for inv in $(fm_list "$f" adds_invariants); do
    awk -F'|' -v i="$inv" '$1 == i && $2 == "id"' "$W/inv" | grep -q . \
      || loi "profile $id: invariant $inv không có trong sdlc/invariants.md."
  done
done
if [ -s "$W/mtran" ]; then
  echo "Job type × stage (chạy · tuỳ = có thể bỏ · bỏ · gap = engine không làm):"
  # printf đệm theo byte: ô có dấu tự đệm theo số ký tự nhìn thấy
  awk -F'|' 'function o(s,  w) { w = (s == "chạy") ? 4 : (s == "tuỳ") ? 3 : (s == "bỏ") ? 2 : length(s)
                                 return " " s sprintf("%" (10 - w) "s", "") }
    FILENAME == ARGV[1] { h = h o($2); next }
    !hd { printf "  %-10s%s\n", "", h; hd = 1 }
    { r = ""; for (i = 2; i <= NF; i++) r = r o($i); printf "  %-10s%s\n", $1, r }' \
    "$W/stages" "$W/mtran" | sed 's/ *$//'
  cat "$W/vang"
fi

# ---- utility command không ánh xạ vào stage
wf_commands "$E/workflow.yaml" > "$W/cmd"
while IFS='|' read -r cid cfile; do
  [ -n "$cid" ] && [ -f "$E/$cfile" ] || continue
  [ -z "$(fm_scalar "$E/$cfile" implements)" ] \
    || loi "utility command $cid: khai implements — utility command không ánh xạ vào stage SDLC."
  [ -z "$(fm_list "$E/$cfile" capabilities)" ] \
    || loi "utility command $cid: khai capabilities — xoá khoá; utility command không ánh xạ vào stage SDLC."
done < "$W/cmd"

[ "$n_loi" = 0 ] || exit 1
echo "Engine tuân thủ interface SDLC."
exit 0
