#!/usr/bin/env sh
# ADR — quyết định D-xx đã duyệt được nâng thành kiến thức bền trong repo đích.
#
# Người quyết nâng D nào ngay trong D đó (dấu duyệt phủ các trường này):
#   - Promote: adr            nâng thành ADR khi hiện thực
#   - Scope: `<glob>`         phần code ADR ràng buộc (bắt buộc khi Promote: adr)
#   - Supersedes: ADR-NNNN    D này thay một ADR accepted
# `aw adr promote` chỉ CHÉP nội dung D (không thêm), cộng nguồn của các YC mà task
# "Based on: D-NN" phủ — truy được về spec, không phải lời agent.
#
# Thư mục: khoá knowledge_adr_dir (mặc định docs/adr). File NNNN-<việc>-d-NN.md,
# chỉ mục README.md (bảng dựng lại từ các file). Định dạng mỗi file:
#   # ADR-NNNN: <tiêu đề D>
#   - Status: accepted | superseded by NNNN
#   - Date: YYYY-MM-DD
#   - Scope: `<glob>`
#   - Supersedes: ADR-NNNN          (nếu có)
#   - Origin: `<việc>` § D-NN
#   ## Decision      — nội dung D (trừ heading, ô duyệt, Promote/Scope/Supersedes)
#   ## Sources       — "- YC-NNN (`<việc>`): <Source của YC trong spec>"
#
# Cần nạp trước: tools/lib/md.sh, tools/lib/sha256.sh, tools/lib/approval-tick.sh

ADR_MAC_DINH="docs/adr"

# adr_thu_muc <conventions.md> -> thư mục ADR (tương đối với gốc repo)
adr_thu_muc() {
  _ad=$(conv_get "$1" knowledge_adr_dir); _ad=${_ad%/}
  printf '%s\n' "${_ad:-$ADR_MAC_DINH}"
}

# d_truong <tdd.md> <D-NN> <Trường> -> giá trị (bỏ backtick, **, khoảng trắng hai đầu)
d_truong() {
  dy_noi_dung "$1" tdd "$2" | awk -v k="$3" '
    {
      s = $0; sub(/^[-*][ \t]*/, "", s); gsub(/\*\*/, "", s)
      if (index(s, k ":") != 1) next
      v = substr(s, length(k) + 2); gsub(/`/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v)
      print v; exit
    }'
}

# d_tieu_de <tdd.md> <D-NN> -> tiêu đề sau "### D-NN —"
d_tieu_de() {
  dy_noi_dung "$1" tdd "$2" | awk 'NR == 1 {
    sub(/^###[ \t]+D-[0-9]+[ \t]*/, ""); sub(/^(—|–|-|:)[ \t]*/, ""); print; exit }'
}

# d_nang_ds <tdd.md> -> các D khai "Promote: adr", mỗi dòng một
d_nang_ds() {
  [ -f "$1" ] || return 0
  dy_quet "$1" tdd | awk -F'|' '$1 == "O" || $1 == "T" { print $2 }' | while IFS= read -r _d; do
    [ "$(d_truong "$1" "$_d" Promote)" = adr ] && printf '%s\n' "$_d"
  done
}

# adr_truong <file ADR> <Trường> -> giá trị dòng "- Trường:" ở phần đầu (trước "## ")
adr_truong() {
  awk -v k="$2" '
    { sub(/\r$/, "") }
    /^## / { exit }
    {
      s = $0; sub(/^[-*][ \t]*/, "", s)
      if (index(s, k ":") != 1) next
      v = substr(s, length(k) + 2); gsub(/`/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v)
      print v; exit
    }' "$1"
}

# adr_ds <thư-mục ADR tuyệt đối> -> file ADR (NNNN-*.md), theo số
adr_ds() {
  for _af in "$1"/[0-9][0-9][0-9][0-9]-*.md; do [ -f "$_af" ] && printf '%s\n' "$_af"; done
}

# adr_cua_d <thư-mục ADR> <việc> <D-NN> -> file ADR có Origin đúng việc + D
adr_cua_d() {
  adr_ds "$1" | while IFS= read -r _af; do
    [ "$(adr_truong "$_af" Origin)" = "$2 § $3" ] && { printf '%s\n' "$_af"; break; }
  done
}

# adr_so_moi <thư-mục ADR> -> số kế tiếp, 4 chữ số
adr_so_moi() {
  adr_ds "$1" | awk -F/ '{ n = substr($NF, 1, 4) + 0; if (n > m) m = n } END { printf "%04d\n", m + 1 }'
}

# adr_nguon <thư-mục-feature> <D-NN> -> "- YC-NNN (`<việc>`): <Source>" cho mỗi YC
# mà task "Based on: D-NN" phủ (plan.md → spec.md). Không có thì một dòng "- None".
adr_nguon() {
  _av=$(basename "$1")
  awk -v d="$2" -v viec="$_av" '
    function ma(s, re, mang,   n) { n = 0; while (match(s, re)) { mang[++n] = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } return n }
    { sub(/\r$/, "") }
    FILENAME == ARGV[1] {
      if (/^###[ \t]+T-[0-9]+/) { if (dua) for (i = 1; i <= nc; i++) if (!(c[i] in co)) { co[c[i]] = 1; thu[++n] = c[i] } ; dua = 0; nc = 0; next }
      if (/^##[ \t]/) { if (dua) for (i = 1; i <= nc; i++) if (!(c[i] in co)) { co[c[i]] = 1; thu[++n] = c[i] } ; dua = 0; nc = 0; next }
      if (/^[ \t]*-[ \t]*\**Covers\**:/) nc = ma($0, "YC-[0-9]+", c)
      if (/^[ \t]*-[ \t]*\**Based on\**:/) { k = ma($0, "D-[0-9]+", b); for (i = 1; i <= k; i++) if (b[i] == d) dua = 1 }
      next
    }
    /^###[ \t]+YC-[0-9]+/ { match($0, /YC-[0-9]+/); yc = substr($0, RSTART, RLENGTH); next }
    /^##[ \t]/ { yc = ""; next }
    yc != "" && /^[ \t]*-[ \t]*\**Source\**:/ && !(yc in nguon) { s = $0; sub(/^[^:]*:[ \t]*/, "", s); nguon[yc] = s }
    END {
      if (dua) for (i = 1; i <= nc; i++) if (!(c[i] in co)) { co[c[i]] = 1; thu[++n] = c[i] }
      if (n == 0) { print "- None"; exit }
      for (i = 1; i <= n; i++) print "- " thu[i] " (`" viec "`): " (thu[i] in nguon ? nguon[thu[i]] : "(spec.md không có Source)")
    }
  ' "$1/plan.md" "$1/spec.md"
}

# adr_noi_dung <thư-mục-feature> <D-NN> <số NNNN> <ngày> -> nội dung file ADR
adr_noi_dung() {
  _at="$1/tdd.md"; _av=$(basename "$1")
  _ass=$(d_truong "$_at" "$2" Supersedes)
  printf '# ADR-%s: %s\n\n' "$3" "$(d_tieu_de "$_at" "$2")"
  printf -- '- Status: accepted\n- Date: %s\n- Scope: `%s`\n' "$4" "$(d_truong "$_at" "$2" Scope)"
  case "$_ass" in ""|none|None|no) ;; *) printf -- '- Supersedes: %s\n' "$_ass" ;; esac
  printf -- '- Origin: `%s` § %s\n\n## Decision\n\n' "$_av" "$2"
  dy_noi_dung "$_at" tdd "$2" | awk 'NR == 1 { next }
    { s = $0; sub(/^[-*][ \t]*/, "", s); gsub(/\*\*/, "", s) }
    s ~ /^(Promote|Scope|Supersedes):/ { next }
    { print }'
  printf '\n## Sources\n\n'
  adr_nguon "$1" "$2"
}

# adr_so_sanh <file ADR> -> nội dung bỏ Date, Status (đổi được sau khi nâng)
adr_so_sanh() { tr -d '\r' < "$1" | grep -v -e '^- Date:' -e '^- Status:'; }

# adr_lam_chi_muc <thư-mục ADR tuyệt đối> -> dựng lại bảng trong README.md. Giữ phần
# người viết phía trên bảng; README chưa có thì tạo.
adr_lam_chi_muc() {
  _ar="$1/README.md"
  {
    if [ -f "$_ar" ]; then
      awk '{ sub(/\r$/, "") } /^\| ADR \|/ { exit } { print }' "$_ar"
    else
      printf '# Architecture Decision Records\n\n> Bảng dưới do `aw adr promote` dựng lại từ các file ADR — sửa file ADR, không sửa bảng.\n> ADR không bị xoá: quyết định bị thay thì `Status: superseded by NNNN`.\n\n'
    fi
    printf '| ADR | Title | Status | Scope |\n|---|---|---|---|\n'
    adr_ds "$1" | while IFS= read -r _af; do
      _ab=$(basename "$_af")
      printf '| [%s](%s) | %s | %s | `%s` |\n' "$(printf '%s' "$_ab" | cut -c1-4)" "$_ab" \
        "$(awk 'NR == 1 { sub(/\r$/, ""); sub(/^# ADR-[0-9]+:[ \t]*/, ""); print; exit }' "$_af")" \
        "$(adr_truong "$_af" Status)" "$(adr_truong "$_af" Scope)"
    done
  } > "$_ar.tam.$$" && mv "$_ar.tam.$$" "$_ar"
}

# adr_loi_hinh_thuc <thư-mục ADR tuyệt đối> -> lỗi hình thức, mỗi dòng một
adr_loi_hinh_thuc() {
  [ -d "$1" ] || return 0
  for _af in "$1"/*.md; do
    [ -f "$_af" ] || continue
    case "$(basename "$_af")" in
      README.md|[0-9][0-9][0-9][0-9]-*.md) ;;
      *) echo "$(basename "$_af"): tên không đúng dạng NNNN-<tên>.md" ;;
    esac
  done
  adr_ds "$1" | awk -F/ '{ n = substr($NF, 1, 4); if (n in da) print $NF ": trùng số với " da[n]; else da[n] = $NF }'
  _aD0=$1
  adr_ds "$_aD0" | while IFS= read -r _af; do
    _ab=$(basename "$_af"); _an=$(printf '%s' "$_ab" | cut -c1-4)
    _ah=$(awk 'NR == 1 { sub(/\r$/, ""); print; exit }' "$_af")
    case "$_ah" in "# ADR-$_an: "?*) ;; *) echo "$_ab: dòng đầu phải là \"# ADR-$_an: <tiêu đề>\"" ;; esac
    _as=$(adr_truong "$_af" Status)
    case "$_as" in
      accepted) ;;
      "superseded by "[0-9][0-9][0-9][0-9])
        set -- "$_aD0"/"${_as#superseded by }"-*.md
        [ -f "$1" ] || echo "$_ab: \"$_as\" nhưng không có ADR ${_as#superseded by }" ;;
      *) echo "$_ab: Status \"$_as\" — chỉ nhận accepted | superseded by NNNN" ;;
    esac
    [ -n "$(adr_truong "$_af" Scope)" ] || echo "$_ab: thiếu \"- Scope:\""
    grep -q '^## Decision' "$_af" || echo "$_ab: thiếu mục \"## Decision\""
  done
  if [ -n "$(adr_ds "$1")" ]; then
    if [ ! -f "$1/README.md" ]; then echo "README.md: thiếu chỉ mục — chạy aw adr promote, hoặc dựng lại bảng"
    else
      adr_ds "$1" | while IFS= read -r _af; do
        _ab=$(basename "$_af")
        grep -q "^| \[$(printf '%s' "$_ab" | cut -c1-4)\]($_ab) | .* | $(adr_truong "$_af" Status) |" "$1/README.md" ||
          echo "README.md: chỉ mục thiếu hoặc lệch trạng thái của $_ab"
      done
    fi
  fi
}

# adr_loi_viec <thư-mục-feature> -> lỗi của việc: D "Promote: adr" chưa có ADR, ADR
# lệch D đã duyệt (sửa tay, hoặc D đổi sau khi nâng), cộng lỗi hình thức thư mục ADR.
adr_loi_viec() {
  _aT="$1/tdd.md"; [ -f "$_aT" ] || return 0
  _arp=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 0
  _aD="$_arp/$(adr_thu_muc "$(qu_hieu_luc "${AW_REPO:-$_arp}")")"
  _av=$(basename "$1")
  d_nang_ds "$_aT" | while IFS= read -r _d; do
    _af=$(adr_cua_d "$_aD" "$_av" "$_d")
    if [ -z "$_af" ]; then echo "$_d khai Promote: adr nhưng chưa có ADR — chạy: aw adr promote $1 $_d"; continue; fi
    _an=$(basename "$_af" | cut -c1-4)
    _ass="${TMPDIR:-/tmp}/aw-adr.$$"
    adr_so_sanh "$_af" > "$_ass"
    if ! adr_noi_dung "$1" "$_d" "$_an" - | grep -v -e '^- Date:' -e '^- Status:' | cmp -s - "$_ass"; then
      echo "$(basename "$_af"): lệch $_d đã duyệt — không sửa ADR bằng tay; chạy lại: aw adr promote $1 $_d"
    fi
    rm -f "$_ass"
  done
  # Hình thức thư mục ADR chỉ là việc của việc có nâng ADR: thư mục hỏng sẵn trên base
  # không được chặn mọi việc khác (aw adr check báo riêng).
  [ -z "$(d_nang_ds "$_aT")" ] || adr_loi_hinh_thuc "$_aD"
}

# adr_loi_truong <thư-mục-feature> -> lỗi các trường Promote / Scope / Supersedes
# của D-xx trong tdd.md (checker design chặn; plan, review chạy lại qua entry check).
adr_loi_truong() {
  _aT="$1/tdd.md"; [ -f "$_aT" ] || return 0
  _arp=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || _arp=${AW_REPO:-.}
  _aD="$_arp/$(adr_thu_muc "$(qu_hieu_luc "${AW_REPO:-$_arp}")")"
  _av=$(basename "$1")
  dy_quet "$_aT" tdd | awk -F'|' '$1 == "O" || $1 == "T" { print $2 }' | while IFS= read -r _d; do
    _ap=$(d_truong "$_aT" "$_d" Promote)
    case "$_ap" in
      ""|no) ;;
      adr)
        case "$(d_truong "$_aT" "$_d" Scope)" in
          ""|"<"*) echo "$_d: \"Promote: adr\" cần \"- Scope: \`<glob>\`\" — phần code ADR ràng buộc" ;;
        esac ;;
      *) echo "$_d: \"Promote: $_ap\" — chỉ nhận adr | no" ;;
    esac
    _as=$(d_truong "$_aT" "$_d" Supersedes)
    case "$_as" in
      ""|none|None|no) ;;
      ADR-[0-9][0-9][0-9][0-9])
        [ "$_ap" = adr ] || echo "$_d: thay $_as thì phải nâng thành ADR mới (\"Promote: adr\") — nếu không, ADR cũ vẫn accepted mà code đã khác"
        set -- "$_aD/${_as#ADR-}"-*.md
        if [ ! -f "$1" ]; then echo "$_d: \"Supersedes: $_as\" nhưng không có ADR ${_as#ADR-} trong $(adr_thu_muc "$(qu_hieu_luc "${AW_REPO:-$_arp}")")/"
        else
          _ast=$(adr_truong "$1" Status); _amoi=$(adr_cua_d "$_aD" "$_av" "$_d")
          case "$_ast" in
            accepted) ;;
            "superseded by "*) [ -n "$_amoi" ] && [ "${_ast#superseded by }" = "$(basename "$_amoi" | cut -c1-4)" ] ||
              echo "$_d: $_as đã \"$_ast\" — chỉ thay được ADR accepted" ;;
          esac
        fi ;;
      *) echo "$_d: \"Supersedes: $_as\" — dạng ADR-NNNN" ;;
    esac
  done
}

# adr_loi_ke_hoach <thư-mục-feature> -> D "Promote: adr" không có task "Based on: D-NN"
# mà "Expected files" gồm thư mục ADR — implement sẽ không có chỗ nâng, diff lệch phạm vi.
adr_loi_ke_hoach() {
  [ -f "$1/tdd.md" ] && [ -f "$1/plan.md" ] || return 0
  _aN=$(d_nang_ds "$1/tdd.md"); [ -n "$_aN" ] || return 0
  _arp=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || _arp=${AW_REPO:-.}
  _atm=$(adr_thu_muc "$(qu_hieu_luc "${AW_REPO:-$_arp}")")
  printf '%s\n' "$_aN" | while IFS= read -r _d; do
    awk -v d="$_d" -v tm="$_atm/" '
      function xong() { if (dua && adr) co = 1; dua = 0; adr = 0 }
      { sub(/\r$/, "") }
      /^###?[ \t]/ { xong(); next }
      /^[ \t]*-[ \t]*\**Based on\**:/ { s = $0; while (match(s, /D-[0-9]+/)) { if (substr(s, RSTART, RLENGTH) == d) dua = 1; s = substr(s, RSTART + RLENGTH) } }
      /^[ \t]*-[ \t]*\**Expected files\**:/ { s = $0; while (match(s, /`[^`]+`/)) { if (index(substr(s, RSTART + 1, RLENGTH - 2), tm) == 1) adr = 1; s = substr(s, RSTART + RLENGTH) } }
      END { xong(); exit !co }
    ' "$1/plan.md" ||
      echo "$_d khai Promote: adr nhưng không task nào \"Based on: $_d\" có \"Expected files\" gồm \`$_atm/*\` — thêm task nâng ADR (aw adr promote)"
  done
}
