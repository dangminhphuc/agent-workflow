#!/usr/bin/env sh
# Luật nghiệp vụ bền (BR-) — YC đã duyệt được nâng thành luật trong repo đích.
#
# Người quyết nâng YC nào ngay trong YC (dấu duyệt spec phủ trường này):
#   - Promote: BR-<MIỀN>-NNN
# `aw rule promote` chỉ CHÉP: tiêu đề, Description, tiêu chí chấp nhận của YC; nguồn
# lấy từ Source của YC + phiên bản trong bảng Sources; phạm vi = Expected files của
# task phủ YC (trừ file test, thư mục ADR, thư mục luật). Không chép toàn văn PRD.
#
# Khối luật (heading, tên trường tiếng Anh — checker đọc; nội dung tiếng Việt):
#   ### BR-BILLING-003: <tên>
#   - Rule: <must / must not, kiểm được>
#   - Scope: `<glob>` …
#   - Source: `[CONFLUENCE|JIRA|FILE|HUMAN]` <định danh> (version: <phiên bản>)
#   - Quote: "<nguyên văn>"                  (chỉ [HUMAN])
#   - Status: active | superseded by BR-…
#   - Acceptance:
#     - <ví dụ kiểm được>
#   - Origin: `<việc>` § YC-NNN
# Khối nằm trong file ở knowledge_rules_dir (mặc định docs/product/rules/<miền>.md),
# hoặc trong tài liệu module (knowledge_files) — người dời khối được, checker tìm theo ID.
#
# Cần nạp trước: tools/lib/md.sh, tools/lib/sha256.sh, tools/lib/approval-tick.sh, tools/lib/adr.sh

LUAT_MAC_DINH="docs/product/rules"
LUAT_RE_ID='BR-[A-Z][A-Z0-9]*-[0-9]+'

# luat_thu_muc <conventions.md> -> thư mục luật (tương đối với gốc repo)
luat_thu_muc() {
  _lt=$(conv_get "$1" knowledge_rules_dir); _lt=${_lt%/}
  printf '%s\n' "${_lt:-$LUAT_MAC_DINH}"
}

# luat_dich <ID> <conventions.md> -> file đích mặc định: <thư mục luật>/<miền>.md
luat_dich() {
  printf '%s/%s.md\n' "$(luat_thu_muc "$2")" "$(printf '%s' "$1" | awk -F- '{ print tolower($2) }')"
}

# luat_tep <gốc repo> <conventions.md> -> file (tương đối) có khối "### BR-…", kể cả chưa commit
luat_tep() {
  _ltd=$(luat_thu_muc "$2"); _lkf=$(conv_get "$2" knowledge_files); _lkf=${_lkf:-*/ARCHITECTURE.md}
  git -C "$1" ls-files --cached --others --exclude-standard 2>/dev/null | while IFS= read -r _lf; do
    case "$_lf" in .agent-workflow/*) continue ;; esac
    _lok=""
    case "$_lf" in "$_ltd"/*.md) _lok=1 ;; esac
    if [ -z "$_lok" ]; then
      set -f
      # shellcheck disable=SC2086
      khop_glob "$_lf" $_lkf && _lok=1
      set +f
    fi
    [ -n "$_lok" ] && [ -f "$1/$_lf" ] && grep -q '^### BR-' "$1/$_lf" && printf '%s\n' "$_lf"
  done
}

# luat_ds <gốc repo> <conventions.md> -> "<file>|<ID>|<Status>|<Scope>" cho mọi khối luật
luat_ds() {
  luat_tep "$1" "$2" | while IFS= read -r _lf; do
    awk -v f="$_lf" '
      function xong() { if (id != "") print f "|" id "|" st "|" sc; id = "" }
      { sub(/\r$/, "") }
      /^###[ \t]+BR-/ { xong(); s = $0; sub(/^###[ \t]+/, "", s); sub(/[: \t].*$/, "", s); id = s; st = ""; sc = ""; next }
      /^##/ { xong(); next }
      id != "" && /^[-*][ \t]*Status:/ { v = $0; sub(/^[^:]*:[ \t]*/, "", v); gsub(/`/, "", v); st = v }
      id != "" && /^[-*][ \t]*Scope:/  { v = $0; sub(/^[^:]*:[ \t]*/, "", v); gsub(/`/, "", v); sc = v }
      END { xong() }
    ' "$1/$_lf"
  done
}

# luat_khoi <file> <ID> -> các dòng của khối "### ID…" (tới heading kế tiếp)
luat_khoi() {
  awk -v id="$2" '
    { sub(/\r$/, "") }
    /^##/ { if (trong) exit; s = $0; sub(/^###[ \t]+/, "", s); sub(/[: \t].*$/, "", s); if ($0 ~ /^###[ \t]/ && s == id) trong = 1 }
    trong { print }
  ' "$1" | awk '{ l[NR] = $0 } END { n = NR; while (n > 0 && l[n] ~ /^[ \t]*$/) n--; for (i = 1; i <= n; i++) print l[i] }'
}

# yc_noi_dung <spec.md> <YC-NNN> -> dòng của mục YC, đã bỏ chú thích HTML
yc_noi_dung() {
  awk -v yc="$2" '
    { sub(/\r$/, "") }
    trong_cmt { if (index($0, "-->")) { trong_cmt = 0; sub(/^.*-->/, "") } else next }
    { while ((i = index($0, "<!--")) > 0) { j = index(substr($0, i), "-->"); if (j == 0) { $0 = substr($0, 1, i - 1); trong_cmt = 1; break } $0 = substr($0, 1, i - 1) substr($0, i + j + 2) } }
    /^##/ { if (trong) exit; if ($0 ~ /^###[ \t]+YC-[0-9]+/) { match($0, /YC-[0-9]+/); if (substr($0, RSTART, RLENGTH) == yc) trong = 1 } }
    trong { print }
  ' "$1"
}

# yc_truong <spec.md> <YC-NNN> <Trường> -> giá trị (bỏ backtick, **)
yc_truong() {
  yc_noi_dung "$1" "$2" | awk -v k="$3" '
    { s = $0; sub(/^[-*][ \t]*/, "", s); gsub(/\*\*/, "", s)
      if (index(s, k ":") != 1) next
      v = substr(s, length(k) + 2); gsub(/^[ \t]+|[ \t]+$/, "", v); print v; exit }'
}

# luat_nang_ds <spec.md> -> "<YC>|<ID>" cho YC có "Promote:"
luat_nang_ds() {
  [ -f "$1" ] || return 0
  awk '{ sub(/\r$/, "") } /^###[ \t]+YC-[0-9]+/ { match($0, /YC-[0-9]+/); print substr($0, RSTART, RLENGTH) }' "$1" |
  while IFS= read -r _ly; do
    _lp=$(yc_truong "$1" "$_ly" Promote | tr -d '`')
    [ -n "$_lp" ] && printf '%s|%s\n' "$_ly" "$_lp"
  done
}

# luat_nguon <thư-mục-feature> <YC> -> dòng "S|<Source>", tuỳ chọn "Q|<Quote>", hoặc "L|<lỗi>"
luat_nguon() {
  _lS="$1/spec.md"; _lv=$(basename "$1")
  _lsrc=$(yc_truong "$_lS" "$2" Source)
  _lnh=$(printf '%s' "$_lsrc" | sed -n 's/^`*\[\([A-Z-]*\)\]`*.*/\1/p')
  _lcon=$(printf '%s' "$_lsrc" | sed 's/^`*\[[A-Z-]*\]`*[ \t]*//')
  case "$_lnh" in
    JIRA|CONFLUENCE)
      _lkey=$(printf '%s\n' "$_lcon" | awk '{ if (match($0, /https?:\/\/[^) ]+/)) print substr($0, RSTART, RLENGTH); else if (match($0, /[A-Z][A-Z0-9]*-[0-9]+/)) print substr($0, RSTART, RLENGTH) }')
      _lpb=$(awk -v k="$_lkey" '
        { sub(/\r$/, "") }
        /^##[ \t]+Sources/ { t = 1; next } /^##/ { t = 0 }
        t && /^\|/ && k != "" && index($0, k) { n = split($0, c, "|"); v = c[5]; gsub(/^[ \t]+|[ \t]+$/, "", v); if (v != "" && v !~ /^</) { print v; exit } }
      ' "$_lS")
      if [ -z "$_lpb" ]; then echo "L|$2: nguồn [$_lnh] không có phiên bản trong bảng \"## Sources\" của spec.md (dòng có \"$_lkey\")"; return; fi
      echo "S|\`[$_lnh]\` $_lcon (version: $_lpb)" ;;
    FILE)
      _lp=$(printf '%s' "$_lcon" | tr -d '`' | awk '{ print $1 }')
      case "$_lp" in
        intake.md|open-questions.md)
          _lh=$(dy_quet "$_lS" spec | awk -F'|' '$1 == "O" { print $4; exit }')
          if [ "$_lp" = open-questions.md ]; then
            _lq=$(awk -v yc="$2" '
              { sub(/\r$/, "") } /^##[ \t]/ { t = (index($0, yc) > 0); next }
              t && /Answer[^:]*:/ { s = $0; sub(/^[^:]*:/, "", s); gsub(/\*\*/, "", s); gsub(/<!--.*-->/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); print s; exit }' "$1/open-questions.md")
          else
            _lq=$(awk '{ sub(/\r$/, "") } /^##[ \t]+Input/ { t = 1; next } /^##/ { t = 0 } t && /\[HUMAN\]/ { h = 1; next } t && h && /^[ \t]*>/ { s = $0; sub(/^[ \t]*>[ \t]*/, "", s); gsub(/<!--.*-->/, "", s); sub(/[ \t]+$/, "", s); o = o (o == "" ? "" : " ") s; next } t && h && /^[ \t]*-/ { h = 0 } END { print o }' "$1/intake.md")
          fi
          [ -n "$_lq" ] || { echo "L|$2: nguồn là lời người ($_lp) nhưng không tìm thấy câu nguyên văn để chép vào Quote"; return; }
          _lpb=$(printf '%s\n' "$_lq" | awk 'match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) { print substr($0, RSTART, RLENGTH) }')
          [ -n "$_lpb" ] || _lpb="spec \`$_lv\` duyệt ${_lh:-?}"
          echo "S|\`[HUMAN]\` $_lp (\`$_lv\`) (version: $_lpb)"
          echo "Q|\"$_lq\"" ;;
        *)
          _lgr=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)
          _lpb=$(git -C "$_lgr" log -1 --format=%h -- "$_lp" 2>/dev/null)
          [ -n "$_lpb" ] || { echo "L|$2: nguồn [FILE] $_lp chưa commit trong repo — không có phiên bản"; return; }
          echo "S|\`[FILE]\` $_lcon (version: $_lpb)" ;;
      esac ;;
    *) echo "L|$2: nguồn [${_lnh:-?}] không nâng được thành luật — chỉ [JIRA] [CONFLUENCE] [FILE] (kể cả lời người đã ghi trong intake.md / open-questions.md)" ;;
  esac
}

# luat_pham_vi <thư-mục-feature> <YC> <conventions.md> -> glob phạm vi, cách nhau dấu cách:
# Expected files của task phủ YC, trừ file test, thư mục ADR, thư mục luật.
luat_pham_vi() {
  _ltf=$(conv_get "$3" test_files); _lad=$(adr_thu_muc "$3"); _ltd=$(luat_thu_muc "$3")
  awk -v yc="$2" '
    { sub(/\r$/, "") }
    /^###?[ \t]/ { if (phu) for (i = 1; i <= n; i++) print g[i]; phu = 0; n = 0; next }
    /^[ \t]*-[ \t]*\**Covers\**:/ { s = $0; while (match(s, /YC-[0-9]+/)) { if (substr(s, RSTART, RLENGTH) == yc) phu = 1; s = substr(s, RSTART + RLENGTH) } }
    /^[ \t]*-[ \t]*\**Expected files\**:/ { s = $0; while (match(s, /`[^`]+`/)) { g[++n] = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }
    END { if (phu) for (i = 1; i <= n; i++) print g[i] }
  ' "$1/plan.md" | while IFS= read -r _lg; do
    case "$_lg" in "$_lad"/*|"$_ltd"/*) continue ;; esac
    set -f
    # shellcheck disable=SC2086
    if [ -n "$_ltf" ] && khop_glob "$_lg" $_ltf; then set +f; continue; fi
    set +f
    printf '%s\n' "$_lg"
  done | awk '!t[$0]++ { printf "%s`%s`", (n++ ? " " : ""), $0 } END { if (n) print "" }'
}

# luat_khoi_moi <thư-mục-feature> <YC> <ID> <conventions.md> -> khối luật (hoặc "L|…" ra stdout, mã 1)
luat_khoi_moi() {
  _lS="$1/spec.md"
  _lng=$(luat_nguon "$1" "$2")
  case "$_lng" in L\|*) printf '%s\n' "$_lng"; return 1 ;; esac
  _lsc=$(luat_pham_vi "$1" "$2" "$4")
  [ -n "$_lsc" ] || { echo "L|$2: không có phạm vi — task phủ $2 không có Expected files nào ngoài file test"; return 1; }
  _lrule=$(yc_truong "$_lS" "$2" Description)
  case "$_lrule" in ""|"<"*) echo "L|$2: thiếu \"- Description:\" — nội dung luật chép từ đó"; return 1 ;; esac
  printf '### %s: %s\n' "$3" "$(yc_noi_dung "$_lS" "$2" | awk 'NR == 1 { sub(/^###[ \t]+YC-[0-9]+[ \t]*/, ""); sub(/^(—|–|-|:)[ \t]*/, ""); print; exit }')"
  printf -- '- Rule: %s\n- Scope: %s\n' "$_lrule" "$_lsc"
  printf '%s\n' "$_lng" | awk -F'|' '$1 == "S" { print "- Source: " substr($0, 3) } $1 == "Q" { print "- Quote: " substr($0, 3) }'
  printf -- '- Status: active\n- Acceptance:\n'
  yc_noi_dung "$_lS" "$2" | awk '
    /^[-*][ \t]*\**Acceptance criteria\**:/ { t = 1; next }
    t && /^[ \t]+[-*][ \t]/ { s = $0; sub(/^[ \t]+[-*][ \t]*(\[[ xX]\][ \t]*)?/, "", s); print "  - " s; next }
    t { t = 0 }'
  printf -- '- Origin: `%s` § %s\n' "$(basename "$1")" "$2"
}

# luat_loi_spec <thư-mục-feature> -> lỗi trường "Promote:" của YC (checker spec chặn)
luat_loi_spec() {
  _lS="$1/spec.md"; [ -f "$_lS" ] || return 0
  _lr=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || _lr=${AW_REPO:-.}
  _lc=$(qu_hieu_luc "${AW_REPO:-$_lr}"); _lv=$(basename "$1")
  luat_nang_ds "$_lS" | while IFS='|' read -r _ly _lid; do
    if ! printf '%s\n' "$_lid" | grep -qxE "$LUAT_RE_ID"; then
      echo "$_ly: \"Promote: $_lid\" — dạng BR-<MIỀN>-NNN (chữ hoa, số), vd BR-BILLING-003"; continue
    fi
    case "$(yc_truong "$_lS" "$_ly" Source)" in
      *INFERRED*|*OPEN-QUESTION*) echo "$_ly: nguồn [INFERRED]/[OPEN-QUESTION] không nâng được thành luật — chỉ YC có nguồn bền" ;;
    esac
    luat_ds "$_lr" "$_lc" | awk -F'|' -v id="$_lid" '$2 == id { print $1 }' | while IFS= read -r _lf; do
      _lo=$(luat_khoi "$_lr/$_lf" "$_lid" | sed -n 's/^[-*][ \t]*Origin:[ \t]*//p' | tr -d '`')
      [ "$_lo" = "$_lv § $_ly" ] || echo "$_ly: $_lid đã có trong $_lf (Origin: ${_lo:-?}) — chọn ID khác"
    done
  done
}

# luat_loi_ke_hoach <thư-mục-feature> -> YC "Promote:" không có task phủ nó mà Expected
# files gồm file luật đích (hoặc thư mục luật).
luat_loi_ke_hoach() {
  [ -f "$1/spec.md" ] && [ -f "$1/plan.md" ] || return 0
  _lN=$(luat_nang_ds "$1/spec.md"); [ -n "$_lN" ] || return 0
  _lr=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || _lr=${AW_REPO:-.}
  _lc=$(qu_hieu_luc "${AW_REPO:-$_lr}"); _ltd=$(luat_thu_muc "$_lc")
  printf '%s\n' "$_lN" | while IFS='|' read -r _ly _lid; do
    _ldich=$(luat_dich "$_lid" "$_lc")
    awk -v yc="$_ly" -v tm="$_ltd/" -v dich="$_ldich" '
      function xong() { if (phu && co) ok = 1; phu = 0; co = 0 }
      { sub(/\r$/, "") }
      /^###?[ \t]/ { xong(); next }
      /^[ \t]*-[ \t]*\**Covers\**:/ { s = $0; while (match(s, /YC-[0-9]+/)) { if (substr(s, RSTART, RLENGTH) == yc) phu = 1; s = substr(s, RSTART + RLENGTH) } }
      /^[ \t]*-[ \t]*\**Expected files\**:/ { s = $0; while (match(s, /`[^`]+`/)) { g = substr(s, RSTART + 1, RLENGTH - 2); if (g == dich || index(g, tm) == 1) co = 1; s = substr(s, RSTART + RLENGTH) } }
      END { xong(); exit !ok }
    ' "$1/plan.md" ||
      echo "$_ly khai Promote: $_lid nhưng không task nào phủ $_ly có \"Expected files\" gồm \`$_ldich\` — thêm vào task (aw rule promote ghi file đó)"
  done
}

# luat_loi_viec <thư-mục-feature> -> YC "Promote:" chưa có khối luật, hoặc khối lệch YC đã duyệt
luat_loi_viec() {
  [ -f "$1/spec.md" ] && [ -f "$1/plan.md" ] || return 0
  _lr=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 0
  _lc=$(qu_hieu_luc "${AW_REPO:-$_lr}")
  luat_nang_ds "$1/spec.md" | while IFS='|' read -r _ly _lid; do
    _lf=$(luat_ds "$_lr" "$_lc" | awk -F'|' -v id="$_lid" '$2 == id { print $1; exit }')
    if [ -z "$_lf" ]; then echo "$_ly khai Promote: $_lid nhưng chưa có khối luật — chạy: aw rule promote $1 $_ly"; continue; fi
    _lt="${TMPDIR:-/tmp}/aw-luat.$$"
    luat_khoi_moi "$1" "$_ly" "$_lid" "$_lc" > "$_lt" 2>/dev/null
    if grep -q '^L|' "$_lt"; then sed -n 's/^L|//p' "$_lt"
    elif ! luat_khoi "$_lr/$_lf" "$_lid" | grep -v '^- Status:' | cmp -s - "$(grep -v '^- Status:' "$_lt" > "$_lt.2"; echo "$_lt.2")"; then
      echo "$_lf: $_lid lệch $_ly đã duyệt — không sửa luật bằng tay trong việc này; chạy lại: aw rule promote $1 $_ly"
    fi
    rm -f "$_lt" "$_lt.2"
  done
}

# luat_duoc_phu <gốc repo> <conventions.md> -> ID luật có test gắn tag covers
luat_duoc_phu() {
  _ltf=$(conv_get "$2" test_files); _ltag=$(conv_get "$2" covers_tag); _ltag=${_ltag:-covers:}
  [ -n "$_ltf" ] || return 0
  git -C "$1" ls-files --cached --others --exclude-standard 2>/dev/null | while IFS= read -r _lf; do
    set -f
    # shellcheck disable=SC2086
    khop_glob "$_lf" $_ltf && [ -f "$1/$_lf" ] && grep -F "$_ltag" "$1/$_lf" 2>/dev/null
    set +f
  done | awk -v tag="$_ltag" '{ s = $0; i = index(s, tag); if (!i) next; s = substr(s, i + length(tag))
    while (match(s, /BR-[A-Z][A-Z0-9]*-[0-9]+/)) { print substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } }' | sort -u
}

# luat_loi_hinh_thuc <gốc repo> <conventions.md> -> lỗi hình thức mọi khối luật
luat_loi_hinh_thuc() {
  _lds=$(luat_ds "$1" "$2")
  printf '%s\n' "$_lds" | awk -F'|' 'NF { if ($2 in da) print $1 ": " $2 " trùng ID với " da[$2]; else da[$2] = $1 }'
  printf '%s\n' "$_lds" | while IFS='|' read -r _lf _lid _lst _lsc; do
    [ -n "$_lf" ] || continue
    printf '%s\n' "$_lid" | grep -qxE "$LUAT_RE_ID" || echo "$_lf: \"$_lid\" — ID dạng BR-<MIỀN>-NNN"
    luat_khoi "$1/$_lf" "$_lid" | awk -v f="$_lf" -v id="$_lid" '
      { s = $0; sub(/^[-*][ \t]*/, "", s) }
      NR == 1 { if ($0 !~ /^###[ \t]+BR-[^:]+:[ \t]*[^ \t]/) print f ": " id " — heading phải là \"### " id ": <tên>\""; next }
      /^[-*][ \t]*(Rule|Scope|Source|Status):/ { k = s; sub(/:.*/, "", k); v = s; sub(/^[^:]*:[ \t]*/, "", v); if (v != "" && v !~ /^</) co[k] = 1; if (k == "Source") src = v; next }
      /^[-*][ \t]*Acceptance:/ { acc = 1; next }
      acc && /^[ \t]+[-*][ \t]+[^ \t<]/ { co["Acceptance"] = 1; next }
      { acc = 0 }
      END {
        split("Rule Scope Source Status Acceptance", kk, " ")
        for (i = 1; i <= 5; i++) if (!(kk[i] in co)) print f ": " id " thiếu \"" kk[i] ":\"" (kk[i] == "Acceptance" ? " (ít nhất một dòng \"  - …\")" : "")
        if (src != "" && src !~ /\[(CONFLUENCE|JIRA|FILE|HUMAN)\]/) print f ": " id " — Source phải mang nhãn [CONFLUENCE] [JIRA] [FILE] [HUMAN]"
        if (src != "" && src !~ /\(version: [^)]+\)/) print f ": " id " — Source thiếu \"(version: …)\""
      }'
    case "$_lst" in
      ""|active) ;;
      "superseded by "BR-*)
        printf '%s\n' "$_lds" | awk -F'|' -v t="${_lst#superseded by }" '$2 == t { f = 1 } END { exit !f }' ||
          echo "$_lf: $_lid \"$_lst\" nhưng không có luật ${_lst#superseded by }" ;;
      *) echo "$_lf: $_lid Status \"$_lst\" — chỉ nhận active | superseded by BR-…" ;;
    esac
  done
}

# luat_lien_quan <gốc repo> <conventions.md> <đường dẫn…(stdin)> -> file có luật active khớp
luat_lien_quan() {
  _ldd=$(cat)
  luat_ds "$1" "$2" | while IFS='|' read -r _lf _lid _lst _lsc; do
    [ "$_lst" = active ] || continue
    printf '%s\n' "$_ldd" | while IFS= read -r _lp; do
      [ -n "$_lp" ] || continue
      set -f
      # shellcheck disable=SC2086
      if khop_glob "$_lp" $_lsc || { [ -d "$1/$_lp" ] && khop_glob "$_lp/x" $_lsc; }; then set +f; printf '%s\n' "$_lf"; break; fi
      set +f
    done
  done | awk '!t[$0]++'
}
