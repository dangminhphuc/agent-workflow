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
#     "- Judged by:", Judged by không phải machine | agent | human; thiếu "- Artifact:" hoặc Artifact
#     không có trong provides của stage, hoặc khai nhiều dòng; loại trong provides không capability nào
#     khai Artifact (stage thiếu provides: chỉ báo thiếu provides).
#   - Invariant: thiếu "Enforced by:" (tools/check-*.sh, tools/lib/*.sh) hoặc "Tested by:"
#     (tools/tests/*.sh), hoặc trỏ tới file không có; không nêu ca test nào; ca test nêu tên ("…" sau
#     file) không có trong file. "Rule:" (capability, invariant) có backtick hoặc mã REQ-/DEC-/… .
#   - Tập con YAML (yaml_kiem): workflow.yaml, phase, utility command, file stage, profile.
#   - Khối sdlc: của workflow.yaml: stage không có, còn khoá status (trạng thái do máy suy ra).
#   - Phase: thiếu implements hoặc implements stage không có; provides sai dạng, file không nằm
#     trong outputs, loại mà stage không khai và không profile nào thêm; thứ tự phase lệch thứ tự stage;
#     capabilities: id không có, thuộc stage khác stage phase implements, hoặc không nhận cái nào.
#   - Stage: trạng thái suy ra từ capability được phase nhận (hết = implemented, một phần = partial,
#     không = gap); partial / gap thiếu note, implemented còn note; provides của các phase không phủ
#     provides của stage; exit human | both mà không phase nào có exit_human, machine | both mà không
#     phase nào có exit_machine.
#   - Utility command khai implements hoặc capabilities (utility command không ánh xạ vào stage).
#   - out_of_scope: (workflow.yaml) id không có, đã được phase nhận, thiếu lý do, khai hai lần.
#   - "# giữ: CAP-…/INV-…" (tools/check-*.sh, tools/lib/*.sh, tools/task.sh) trỏ id không có; capability
#     Judged by machine được phase nhận mà không luật nào khai "# giữ:" nó.
#   - Luật chưa phân loại: số chỗ loi / loi_truoc / [CẢNH BÁO] chưa "# giữ:" phủ của mỗi tools/check-*.sh
#     (trừ check-sdlc, check-release) và tools/task.sh phải bằng số trong tools/unclassified-rules.txt.
#     --dem-luat: in danh sách đó (không kiểm gì khác).
#     --suy <file>…: in CAP/INV mà các dòng "# giữ:" trong những file đó khai (id từ diff),
#     một id một dòng. Id không có → KHÔNG ĐẠT. Không tự gắn id.
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

DEM=""; SUY=""
case "${1:-}" in
  --dem-luat) DEM=1; shift ;;
  --suy) SUY=1; shift ;;
esac
if [ "$SUY" = 1 ]; then
  trap - EXIT
  [ $# -ge 1 ] || { echo "Dùng: sh tools/check-sdlc.sh --suy <file>..." >&2; exit 2; }
  for _s in "$@"; do
    [ -f "$_s" ] || { echo "LỖI: không có file $_s" >&2; exit 2; }
  done
  _co=$(awk '
    FILENAME ~ /\/invariants\.md$/ && /^###[ \t]+INV-[0-9]+/ {
      match($0, /INV-[0-9]+/); print substr($0, RSTART, RLENGTH); next
    }
    /^###[ \t]+CAP-/ { match($0, /CAP-[a-z0-9-]+/); print substr($0, RSTART, RLENGTH) }
  ' "$ROOT"/sdlc/stages/*.md "$ROOT"/sdlc/invariants.md | tr '\n' ' ')
  _co=" $_co "
  _ids=$(awk '
    /^[ \t]*# giữ:/ {
      s = $0; sub(/^[ \t]*# giữ:[ \t]*/, "", s)
      n = split(s, a, /[, \t]+/)
      for (i = 1; i <= n; i++) if (a[i] != "") print a[i]
    }
  ' "$@" | sort -u)
  _sai="${TMPDIR:-/tmp}/aw-suy.$$"
  rm -f "$_sai"
  if [ -n "$_ids" ]; then
    printf '%s\n' "$_ids" | while IFS= read -r _id; do
      case "$_co" in
        *" $_id "*) printf '%s\n' "$_id" ;;
        *) echo "LỖI: # giữ: $_id không có capability/invariant đó." >&2; echo x >> "$_sai" ;;
      esac
    done
  fi
  if [ -s "$_sai" ]; then rm -f "$_sai"; exit 1; fi
  rm -f "$_sai"
  exit 0
fi
[ $# -le 1 ] || { echo "Dùng: sh tools/check-sdlc.sh [--dem-luat] [<engine-root>]" >&2; exit 2; }
E="${1:-$ROOT}"
if [ ! -f "$E/workflow.yaml" ] || [ ! -d "$E/sdlc/stages" ]; then
  echo "LỖI: \"$E\" thiếu workflow.yaml hoặc sdlc/stages/." >&2; exit 2
fi

# ---- luật checker chưa phân loại (bước A, đợt 2). Chỗ luật: dòng gọi loi / loi_truoc hoặc in [CẢNH BÁO]
# trong tools/check-*.sh (trừ check-sdlc.sh, check-release.sh — kiểm chính engine) và tools/task.sh.
# Một dòng "# giữ: …" phủ các chỗ luật sau nó tới dòng trống kế tiếp. Hàm thư viện (tools/lib/): đợt 3.
DS_LUAT="tools/unclassified-rules.txt"
tep_luat() { for _tl in "$E"/tools/check-*.sh "$E"/tools/task.sh; do
  case "${_tl##*/}" in check-sdlc.sh|check-release.sh) continue ;; esac
  [ -f "$_tl" ] && printf '%s\n' "${_tl#"$E"/}"; done; }
# dem_luat <file> -> số chỗ luật (loi/loi_truoc/canh_bao, dòng in [LỖI]/[CẢNH BÁO], TỪ CHỐI:/DỪNG:/CẢNH BÁO:)
# chưa được "# giữ:" phủ. Một "# giữ:" phủ đúng một chỗ luật đầu tiên bên dưới, trước dòng trống kế tiếp.
dem_luat() {
  awk '{ sub(/\r$/, "") }
    /^[ \t]*$/ { phu = 0; next }
    /^[ \t]*# giữ:/ { phu = 1; next }
    /^[ \t]*#/ { next }
    /^[ \t]*(function[ \t]+)?(loi|loi_truoc|canh_bao)[ \t]*\(/ && /\{/ && !/(loi|loi_truoc|canh_bao)[ \t]*\([^)]*"/ { next }
    /BEGIN[ \t]*\{[ \t]*n_loi[ \t]*=[ \t]*loi_truoc/ { next }
    $0 ~ /(^|[^A-Za-z0-9_])(loi|loi_truoc|canh_bao)[ (]/ || index($0, "[LỖI]") || index($0, "[CẢNH BÁO]") ||
    /(TỪ CHỐI|DỪNG|CẢNH BÁO):/ { if (phu) phu = 0; else n++ }
    END { print n + 0 }' "$1"
}
if [ -n "$DEM" ]; then
  # chỉ in danh sách (dùng để tạo / cập nhật tools/unclassified-rules.txt) — không in khối Kết quả
  trap - EXIT
  tep_luat | while IFS= read -r _f; do _n=$(dem_luat "$E/$_f"); if [ "$_n" -gt 0 ]; then printf '%s %s\n' "$_f" "$_n"; fi; done
  exit 0
fi
W="${TMPDIR:-/tmp}/aw-check-sdlc.$$"
mkdir -p "$W"
kq_don 'rm -rf "$W"'

n_loi=0
loi() { echo "  [LỖI] $*"; n_loi=$((n_loi + 1)); }
# co <file> <dòng> -> 0 nếu file có đúng dòng đó
co() { [ -f "$1" ] && grep -qxF -- "$2" "$1"; }

# ---- tập con YAML: dòng ngoài tập con fm_* / wf_* đọc được thì báo ngay, không để trả rỗng
yaml_bao() { # <đường-dẫn tương đối trong engine> fm|wf
  yaml_kiem "$E/$1" "$2" | while IFS= read -r l; do echo "$1: $l"; done
}
{
  yaml_bao workflow.yaml wf
  for f in "$E"/workflow/phases/*.md "$E"/workflow/*.md "$E"/sdlc/stages/*.md "$E"/sdlc/profiles/*.md; do
    [ -f "$f" ] && yaml_bao "${f#"$E"/}" fm
  done
} > "$W/yaml"
while IFS= read -r l; do loi "$l"; done < "$W/yaml"

# ---- invariant: "### INV-NNN — …" + "- Enforced by:" / "- Tested by:" với đường dẫn trong `…`
INV="$E/sdlc/invariants.md"
: > "$W/inv"
if [ -f "$INV" ]; then
  awk '
    { sub(/\r$/, "") }
    /^### INV-[0-9]+/ { match($0, /INV-[0-9]+/); cur = substr($0, RSTART, RLENGTH); print cur "|id|"; next }
    /^#/ { cur = ""; next }
    # Rule: trừu tượng — cú pháp engine (backtick, mã REQ-/DEC-…) thuộc "- Engine:"
    cur != "" && /^- Rule:/ { r = $0; sub(/^- Rule:[ \t]*/, "", r); f = ""
      if (index(r, "`")) f = "`"; else if (match(r, /(REQ|DEC|TSK|RVW|FND|RFR|BR)-/)) f = substr(r, RSTART, RLENGTH)
      if (f != "") print cur "|rule|" f; next }
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
# id invariant tra ở shell (gọi nhiều lần — mỗi lần một awk thì chậm)
INV_IDS=" $(awk -F'|' '$2 == "id" { printf "%s ", $1 }' "$W/inv")"
inv_co() { case "$INV_IDS" in *" $1 "*) return 0 ;; esac; return 1; }
for inv in $(awk -F'|' '$2 == "id" { print $1 }' "$W/inv"); do
  awk -F'|' -v i="$inv" '$1 == i && $2 == "enf" && $3 != ""' "$W/inv" | grep -q . \
    || loi "$inv: thiếu \"Enforced by:\" trỏ tới checker (tools/check-*.sh, tools/lib/*.sh)."
  awk -F'|' -v i="$inv" '$1 == i && $2 == "test" && $3 != ""' "$W/inv" | grep -q . \
    || loi "$inv: thiếu \"Tested by:\" trỏ tới test (tools/tests/*.sh)."
  awk -F'|' -v i="$inv" '$1 == i && $2 == "case"' "$W/inv" | grep -q . \
    || loi "$inv: \"Tested by:\" không nêu ca test nào — thêm tên ca (trong \"…\") sau đường dẫn file."
  awk -F'|' -v i="$inv" '$1 == i && $2 == "rule" { print $3 }' "$W/inv" | while IFS= read -r f; do
    echo "$inv: \"Rule:\" chứa cú pháp engine ($f) — viết trừu tượng, chuyển cú pháp sang \"- Engine:\"."
  done > "$W/inv2"
  while IFS= read -r l; do loi "$l"; done < "$W/inv2"
  awk -F'|' -v i="$inv" '$1 == i && ($2 == "enf" || $2 == "test") && $3 != "" { print $2 "|" $3 }' "$W/inv" > "$W/inv1"
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
: > "$W/stages"; : > "$W/prov"; : > "$W/cap"; : > "$W/capart"; : > "$W/sreq"; i=0
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
    echo "$id|$t" >> "$W/sreq"
    awk -F'|' -v t="$t" '$2 == t' "$W/prov" | grep -q . \
      || loi "stage $id: requires \"$t\" — không stage nào trước nó provides."
  done < "$W/r"
  fm_list "$f" provides > "$W/p"
  [ -s "$W/p" ] || loi "stage $id: thiếu provides."
  while IFS= read -r t; do if [ -n "$t" ]; then echo "$id|$t" >> "$W/prov"; fi; done < "$W/p"
  for inv in $(fm_list "$f" invariants); do
    inv_co "$inv" \
      || loi "stage $id: invariant $inv không có trong sdlc/invariants.md."
  done
  sk=$(fm_scalar "$f" skippable)
  case "$sk" in
    ""|true) sk=true ;;
    false) ;;
    *) loi "stage $id: skippable \"$sk\" — chỉ nhận true | false."; sk=true ;;
  esac
  echo "$i|$id|$ex|$sk" >> "$W/stages"
  # capability: "### CAP-<stage>-NN — <tên>" + "- Rule:" + "- Judged by:" + "- Artifact:", khối hết ở heading kế tiếp
  md_body "$f" | awk -v s="$id" -v pv="$(awk 'NF' "$W/p" | tr '\n' ',')" '
    BEGIN {
      n = split(pv, a, ",")
      for (k = 1; k <= n; k++) if (a[k] != "") { prov[a[k]] = 1; ds = ds (ds == "" ? "" : ", ") a[k] }
    }
    function dong(   m, k, t, x, co) {
      if (cur == "") return
      if (!rule) print "E|" cur ": thiếu \"- Rule:\" — thêm một câu nói điều phải đúng."
      if (!coj) print "E|" cur ": thiếu \"- Judged by:\" — thêm machine | agent | human."
      else if (jd != "machine" && jd != "agent" && jd != "human")
        print "E|" cur ": Judged by \"" jd "\" — chỉ nhận machine | agent | human."
      # Artifact: một hoặc nhiều loại, cách nhau dấu phẩy, phải nằm trong provides của stage.
      # Stage thiếu provides đã bị báo riêng — không thêm một lỗi cho mỗi capability.
      if (ds == "") { print "C|" cur "|" jd "|" ten; cur = ""; return }
      if (na > 1) print "E|" cur ": khai \"- Artifact:\" nhiều dòng — gộp vào một dòng, cách nhau dấu phẩy."
      co = 0; m = split(av, x, ",")
      for (k = 1; k <= m; k++) {
        t = x[k]; gsub(/^[ \t]+|[ \t]+$/, "", t)
        if (t == "") continue
        co = 1
        if (t in prov) print "A|" t
        else print "E|" cur ": Artifact \"" t "\" không có trong provides của stage " s " (" ds ") — sửa tên loại, hoặc chuyển capability sang stage provides loại đó."
      }
      if (!co) print "E|" cur ": thiếu \"- Artifact:\" — thêm loại artifact capability này bảo đảm, lấy trong provides của stage " s ": " ds "."
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
      da_co[c] = 1; cur = c; ten = $0; sub(/^### [^ ]+ — /, "", ten); rule = 0; coj = 0; jd = ""; av = ""; na = 0; next
    }
    cur != "" && /^- Rule:/ { rule = 1; r = $0; sub(/^- Rule:[ \t]*/, "", r); f = ""
      if (index(r, "`")) f = "`"; else if (match(r, /(REQ|DEC|TSK|RVW|FND|RFR|BR)-/)) f = substr(r, RSTART, RLENGTH)
      if (f != "") print "E|" cur ": \"Rule:\" chứa cú pháp engine (" f ") — viết trừu tượng, chuyển cú pháp sang \"- Engine:\"." }
    cur != "" && /^- Judged by:/ { coj = 1; jd = $0; sub(/^- Judged by:[ \t]*/, "", jd); sub(/[ \t]+$/, "", jd) }
    cur != "" && /^- Artifact:/ { na++; av = $0; sub(/^- Artifact:/, "", av) }
    END { dong() }
  ' > "$W/c1"
  grep -q '^C|' "$W/c1" \
    || loi "stage $id: không có capability — thêm \"## Capabilities\" với ít nhất một \"### CAP-$id-NN — <tên>\"."
  while IFS= read -r l; do
    case "$l" in
      E\|*) loi "${l#E|}" ;;
      C\|*) echo "$id|${l#C|}" >> "$W/cap" ;;
      A\|*) echo "$id|${l#A|}" >> "$W/capart" ;;
    esac
  done < "$W/c1"
done
# mỗi loại provides của stage có ít nhất một capability khai Artifact loại đó (adds_provides của profile: không)
while IFS='|' read -r s t; do
  [ -n "$t" ] || continue
  grep -qxF "$s|$t" "$W/capart" \
    || loi "stage $s: provides \"$t\" — không capability nào khai \"Artifact: $t\"; thêm hoặc gắn một capability."
done < "$W/prov"
SO_STAGE=" $(awk -F'|' '{ printf "%s=%s ", $2, $1 }' "$W/stages")"  # stage_so tra ở shell chính, không awk mỗi lần
stage_co() { case "$SO_STAGE" in *" $1="*) return 0 ;; esac; return 1; }
# stage_so <stage> -> số thứ tự; tra chuỗi trong shell (gọi ~100 lần — mỗi lần một awk thì chậm)
stage_so() {
  [ -n "${SO_STAGE:-}" ] || SO_STAGE=" $(awk -F'|' '{ printf "%s=%s ", $2, $1 }' "$W/stages")"  # dự phòng; thường đã tính sẵn ở shell chính
  case "$SO_STAGE" in *" $1="*) _so=${SO_STAGE#*" $1="}; printf '%s\n' "${_so%% *}" ;; esac
}
# cap_co <CAP-id> -> 0 nếu capability có trong sdlc/stages/; cap_stage <CAP-id> -> stage của nó.
# Tra chuỗi tính một lần ($W/cap đã đủ): " id ", ";id=stage;".
CAP_IDS=" $(awk -F'|' '{ printf "%s ", $2 }' "$W/cap")"
CAP_ST="$(awk -F'|' '{ printf ";%s=%s", $2, $1 }' "$W/cap");"
cap_co() { case "$CAP_IDS" in *" $1 "*) return 0 ;; esac; return 1; }
cap_stage() {
  case "$CAP_ST" in *";$1="*) _cs=${CAP_ST#*";$1="}; printf '%s\n' "${_cs%%;*}" ;; esac
}

# ---- loại artifact profile thêm (adds_provides của sdlc/profiles/*.md): phase được map chúng ra file
: > "$W/padd"
for f in "$E"/sdlc/profiles/*.md; do
  [ -f "$f" ] || continue
  fm_list "$f" adds_provides | awk '/: / { s = $0; sub(/: .*/, "", s); t = $0; sub(/^[^:]*: /, "", t); print s "|" t }' >> "$W/padd"
done

# ---- khối sdlc: của workflow.yaml
wf_sdlc "$E/workflow.yaml" > "$W/khai"
# stage còn dòng status (kể cả không giá trị — wf_sdlc không phân biệt được với không có dòng)
awk '{ sub(/\r$/, "") } /^[ \t]*#/ { next } /^sdlc:[ \t]*$/ { ins = 1; next } ins && /^[A-Za-z]/ { ins = 0 }
  ins && /^[ \t]*-[ \t]+stage:/ { s = $0; sub(/^[ \t]*-[ \t]+stage:[ \t]*/, "", s) }
  ins && /^[ \t]+status:/ { print s }' "$E/workflow.yaml" > "$W/con-status"
while IFS='|' read -r s _st _note; do
  [ -n "$s" ] || continue
  if ! stage_co "$s"; then loi "khối sdlc: khai stage \"$s\" không có trong sdlc/stages/."; continue; fi
  ! co "$W/con-status" "$s" \
    || loi "khối sdlc: stage $s còn khoá status — xoá dòng status; trạng thái do máy suy ra từ capabilities: của phase."
done < "$W/khai"
# note_cua <stage> -> note của stage trong khối sdlc: (nguyên văn, kể cả dấu |)
note_cua() { awk -v s="$1" 'index($0, s "|") == 1 { sub(/^[^|]*\|[^|]*\|/, ""); print; exit }' "$W/khai"; }
# co_note <stage> -> 0 nếu khối sdlc: có note cho stage đó
co_note() { [ -n "$(note_cua "$1")" ]; }

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
# Phase theo stage, tính một lần: ";stage=pid1, pid2;" (thứ tự workflow.yaml) và ";stage;" nếu có phase required khác false.
PH_DS=$(awk -F'|' '{ if ($2 in ten) ten[$2] = ten[$2] ", " $1; else ten[$2] = $1 }
  END { printf ";"; for (s in ten) printf "%s=%s;", s, ten[s] }' "$W/phases")
PH_CHAY=$(awk -F'|' '$5 != "false" { c[$2] = 1 } END { printf ";"; for (s in c) printf "%s;", s }' "$W/phases")
# ph_ten <stage> -> "pid1, pid2"; rỗng nếu stage không có phase. ph_chay -> 0 nếu có phase required khác false.
ph_ten() { case "$PH_DS" in *";$1="*) _pt=${PH_DS#*";$1="}; printf '%s\n' "${_pt%%;*}" ;; esac; }
ph_chay() { case "$PH_CHAY" in *";$1;"*) return 0 ;; esac; return 1; }

# ---- out_of_scope: capability engine quyết không làm (khoá cấp cao của workflow.yaml, "- CAP-id: lý do").
# Không đổi trạng thái stage — chỉ tách khỏi roadmap những việc sẽ không bao giờ làm.
awk '{ sub(/\r$/, "") } /^[ \t]*#/ { next } /^out_of_scope:[ \t]*$/ { o = 1; next } o && /^[A-Za-z]/ { o = 0 }
  o && /^  - / { s = $0; sub(/^  - /, "", s); c = s; sub(/:.*$/, "", c); ly = ""
    if (index(s, ":")) { ly = s; sub(/^[^:]*:[ \t]*/, "", ly); sub(/[ \t]+$/, "", ly) }
    print c "|" ly }' "$E/workflow.yaml" > "$W/oos"
: > "$W/oos-da"; : > "$W/oos-ok"
while IFS='|' read -r c ly; do
  [ -n "$c" ] || continue
  if co "$W/oos-da" "$c"; then loi "out_of_scope: $c khai hai lần."; continue; fi
  echo "$c" >> "$W/oos-da"
  cap_co "$c" || { loi "out_of_scope: $c không có trong sdlc/stages/."; continue; }
  ph=$(awk -F'|' -v c="$c" '$3 == c { print $1; exit }' "$W/nhan")
  [ -z "$ph" ] || { loi "out_of_scope: $c vừa out-of-scope vừa được phase $ph nhận — chọn một."; continue; }
  [ -n "$ly" ] || { loi "out_of_scope: $c thiếu lý do — ghi vì sao engine không làm."; continue; }
  echo "$c|$ly" >> "$W/oos-ok"
done < "$W/oos"

# ---- luật checker khai capability / invariant nó giữ: chú thích "# giữ: CAP-…[, INV-…]" ngay trên khối
# chặn / cảnh báo, trong tools/check-*.sh, tools/lib/*.sh, tools/task.sh (bước A, đợt 1: chỉ chiều ngược —
# capability machine được nhận phải có luật khai nó; luật chưa khai id thì chưa chặn).
: > "$W/giu"
for f in "$E"/tools/check-*.sh "$E"/tools/lib/*.sh "$E"/tools/task.sh; do
  [ -f "$f" ] || continue
  awk -v f="${f#"$E"/}" '{ sub(/\r$/, "") }
    /^[ \t]*# giữ:/ { s = $0; while (match(s, /CAP-[a-z]+-[0-9][0-9]|INV-[0-9]+/)) { print f "|" substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } }' "$f" >> "$W/giu"
done
while IFS='|' read -r f id; do
  case "$id" in
    CAP-*) cap_co "$id" ;;
    *) inv_co "$id" ;;
  esac || loi "$f: \"# giữ: $id\" — không có capability / invariant đó (sdlc/stages/, sdlc/invariants.md)."
done < "$W/giu"
awk -F'|' '$3 == "machine" { print $2 }' "$W/cap" > "$W/may"
while IFS= read -r c; do
  ph=$(awk -F'|' -v c="$c" '$3 == c { print $1; exit }' "$W/nhan"); [ -n "$ph" ] || continue
  awk -F'|' -v c="$c" '$2 == c' "$W/giu" | grep -q . ||
    loi "$c: Judged by machine, phase $ph nhận, nhưng không luật checker nào khai \"# giữ: $c\" — thêm chú thích ngay trên khối chặn / cảnh báo giữ nó."
done < "$W/may"

# ---- luật chưa phân loại: số chỗ luật chưa "# giữ:" của mỗi file phải đúng bằng số trong $DS_LUAT —
# nhiều hơn = luật mới không gắn id; ít hơn = đã gắn thêm mà chưa hạ danh sách (danh sách chỉ được giảm).
: > "$W/dsl"
tep_luat > "$W/tepl"
if [ -f "$E/$DS_LUAT" ]; then
  while IFS= read -r l; do
    l=$(printf '%s' "$l" | tr -d '\r')
    case "$l" in ""|"#"*) continue ;; esac
    set -f; set -- $l; set +f
    f=$1; so=$2; [ $# -eq 2 ] || so=""
    case "$so" in ""|*[!0-9]*) loi "$DS_LUAT: dòng \"$l\" sai dạng — cần \"<file> <số>\"."; continue ;; esac
    [ -f "$E/$f" ] || { loi "$DS_LUAT: $f không có."; continue; }
    grep -qxF "$f" "$W/tepl" || { loi "$DS_LUAT: $f không phải file được đếm (tools/check-*.sh trừ check-sdlc/check-release, tools/task.sh)."; continue; }
    awk -v f="$f" '$1 == f { c = 1 } END { exit !c }' "$W/dsl" && { loi "$DS_LUAT: $f lặp — mỗi file một dòng."; continue; }
    echo "$f $so" >> "$W/dsl"
  done < "$E/$DS_LUAT"
fi
while IFS= read -r f; do
  n=$(dem_luat "$E/$f")
  m=$(awk -v f="$f" '$1 == f { print $2; exit }' "$W/dsl"); m=${m:-0}
  if [ "$n" -gt "$m" ]; then
    loi "$f: $n luật chưa gắn \"# giữ:\" (cho phép $m trong $DS_LUAT) — gắn CAP-…/INV-… cho luật mới; không id nào hợp thì thêm capability / invariant."
  elif [ "$n" -lt "$m" ]; then
    loi "$DS_LUAT: $f cho phép $m nhưng chỉ còn $n luật chưa gắn — hạ xuống $n (chạy sh tools/check-sdlc.sh --dem-luat)."
  fi
done < "$W/tepl"

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
  ph=$(ph_ten "$s")
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
  # capability chưa phase nào nhận, tách: còn trên roadmap | out-of-scope (kèm lý do)
  : > "$W/khong"
  echo "Capability còn thiếu (roadmap — mô tả ở sdlc/stages/):"
  while IFS='|' read -r s st; do
    awk -F'|' -v s="$s" 'FILENAME == ARGV[1] { if ($2 == s) da[$3] = 1; next }
      FILENAME == ARGV[2] { oos[$1] = $2; next }
      $1 == s && !($2 in da) { if ($2 in oos) print "K|" $2 "|" $3 "|" oos[$2]; else print "R|" $2 "|" $3 "|" $4 }' \
      "$W/nhan" "$W/oos-ok" "$W/cap" > "$W/ts"
    if grep -q '^R|' "$W/ts"; then
      echo "  $s ($st): $(note_cua "$s")"
      awk -F'|' '$1 == "R" { printf "    %s  %-7s  %s\n", $2, $3, $4 }' "$W/ts"
      in_note=1
    else in_note=0; fi
    if grep -q '^K|' "$W/ts"; then
      if [ "$in_note" = 1 ]; then echo "  $s ($st)" >> "$W/khong"; else echo "  $s ($st): $(note_cua "$s")" >> "$W/khong"; fi
      awk -F'|' '$1 == "K" { printf "    %s  %-7s  %s\n", $2, $3, $4 }' "$W/ts" >> "$W/khong"
    fi
  done < "$W/thieu"
  if [ -s "$W/khong" ]; then
    echo "Không làm (out-of-scope — lý do trong workflow.yaml):"
    cat "$W/khong"
  fi
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
# stage skippable: false — tra một lần, không awk mỗi stage của mỗi profile
SK_FALSE=" $(awk -F'|' '$4 == "false" { printf "%s ", $2 }' "$W/stages")"
# luon_co <stage> <loại> -> 0 nếu một stage đứng trước, luôn chạy với profile đang xét, provides
# loại đó ($W/pq: provides của stage + adds_provides của profile; $W/luon: "số|stage" luôn chạy)
luon_co() {
  case "$LUON_MIN" in
    *" $2="*) _lm=${LUON_MIN#*" $2="}; _lm=${_lm%% *}; [ "$_lm" -lt "$(stage_so "$1")" ] ;;
    *) return 1 ;;
  esac
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
      case "$SK_FALSE" in *" $s "*) loi "profile $id: stage $s không được bỏ (skippable: false trong sdlc/stages/)." ;; esac
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
    ph=$(ph_ten "$s")
    [ -n "$ph" ] || continue
    if ! ph_chay "$s"; then
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
  # luon_co tra chuỗi: mỗi loại → thứ tự nhỏ nhất của stage luôn chạy (với profile này) cung cấp nó; tính một lần
  LUON_MIN=" $(awk -F'|' 'FILENAME == ARGV[1] { so[$2] = $1; next } ($1 in so) { if (!($2 in m) || so[$1] + 0 < m[$2]) m[$2] = so[$1] + 0 } END { for (t in m) printf "%s=%s ", t, m[t] }' "$W/luon" "$W/pq")"
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
  while IFS='|' read -r s t; do
    [ -n "$s" ] || continue
    [ "$(kieu "$s")" != bo ] && ! la_gap "$s" || continue
    luon_co "$s" "$t" && continue
    case " $vang " in *" $t "*) ;; *) vang="${vang:+$vang }$t" ;; esac
  done < "$W/sreq"
  if [ -n "$vang" ]; then echo "  $id: có thể vắng: $(echo "$vang" | sed 's/ /, /g')" >> "$W/vang"; fi
  for inv in $(fm_list "$f" adds_invariants); do
    inv_co "$inv" \
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
