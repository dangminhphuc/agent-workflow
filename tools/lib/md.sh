#!/usr/bin/env sh
# Thư viện đọc frontmatter và thân markdown.
#
# Chỉ hỗ trợ TẬP CON YAML sau — cố tình giữ hẹp để không phải phụ thuộc runtime:
#   khoa: gia tri
#   khoa:
#     - muc
#     - muc
#   khoa: []
# KHÔNG hỗ trợ: map lồng nhau, khối nhiều dòng (| >), flow không rỗng,
# chú thích cuối dòng, anchor/alias.
# Manifest và frontmatter trong repo này được viết bám đúng tập con đó.

# fm_scalar <file> <khoá> -> in giá trị (rỗng nếu không có)
fm_scalar() {
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR==1 && $0=="---" { fm=1; next }
    fm==1 && $0=="---" { exit }
    fm!=1 { next }
    $0 ~ "^" key ":" {
      v=$0; sub(/^[^:]*:[ \t]*/, "", v)
      gsub(/^[ \t]+|[ \t]+$/, "", v)
      if (v=="[]" || v=="{}") v=""
      print v; exit
    }
  ' "$1"
}

# yaml_kiem <file> fm|wf -> "dòng N: <lý do>" cho mỗi dòng ngoài tập con YAML mà fm_* / wf_* đọc
# được (đọc sai thì trả rỗng — lỗi lộ muộn). fm: frontmatter giữa hai dòng "---" (k: v, k:, k: [],
# "  - mục"); wf: cả file workflow.yaml, thêm danh sách map một cấp ("  - k: v" rồi "    k: v").
# Dòng trống và chú thích (# ở bất kỳ mức thụt nào) luôn được phép. Giá trị [...] khác [] bị chặn (fm_list đọc
# thành rỗng), trừ argument_hint — chuỗi gợi ý tham số như [--global], đọc bằng fm_scalar.
yaml_kiem() {
  awk -v mode="$2" '
    { sub(/\r$/, "") }
    mode == "fm" && NR == 1 { if ($0 == "---") { fm = 1; next } else exit }
    mode == "fm" && $0 == "---" { exit }
    mode == "fm" && fm != 1 { next }
    /^[ \t]*$/ || /^[ \t]*#/ { next }
    /^[ \t]*\t/ { print "dòng " NR ": thụt lề bằng tab — dùng dấu cách"; next }
    {
      v = $0; sub(/^[ ]*(- )?[A-Za-z_][A-Za-z0-9_]*:/, "", v); sub(/^ /, "", v)
      co_khoa = ($0 ~ /^[ ]*(- )?[A-Za-z_][A-Za-z0-9_]*:/)
      k = $0; sub(/^[ ]*(- )?/, "", k); sub(/:.*/, "", k)
    }
    co_khoa && (v ~ /^[|>][-+]?$/) { print "dòng " NR ": giá trị khối | / > không được hỗ trợ — viết một dòng"; next }
    co_khoa && (v ~ /^[{]/ || (v ~ /^[[].*[]]$/ && v != "[]" && k != "argument_hint")) { print "dòng " NR ": dạng {…} hoặc danh sách [a, b] không được hỗ trợ — viết từng mục \"  - mục\" (rỗng: [])"; next }
    /^[A-Za-z_][A-Za-z0-9_]*:([ ].*)?$/ { next }
    /^  - ./ && mode == "fm" { next }
    mode == "wf" && (/^  - [A-Za-z_][A-Za-z0-9_]*: ./ || /^  - ./ || /^    [A-Za-z_][A-Za-z0-9_]*:([ ].*)?$/) { next }
    /^[ ]*(- )?[A-Za-z_][A-Za-z0-9_]*:[^ ]/ { print "dòng " NR ": thiếu dấu cách sau \":\""; next }
    /^   / || (mode == "fm" && /^  [^-]/) { print "dòng " NR ": thụt sâu hơn tập con cho phép"; next }
    { print "dòng " NR ": dòng không thuộc tập con YAML (k: v, k:, k: [], \"  - mục\")" }
  ' "$1"
}

# fm_list <file> <khoá> -> in từng mục một dòng
fm_list() {
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR==1 && $0=="---" { fm=1; next }
    fm==1 && $0=="---" { exit }
    fm!=1 { next }
    inlist==1 {
      if ($0 ~ /^[ \t]+-[ \t]+/) { v=$0; sub(/^[ \t]+-[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v; next }
      inlist=0
    }
    $0 ~ "^" key ":[ \t]*$" { inlist=1; next }
  ' "$1"
}

# md_body <file> -> in phần markdown sau frontmatter
md_body() {
  awk '
    { sub(/\r$/, "") }
    NR==1 && $0=="---" { fm=1; next }
    fm==1 && $0=="---" { fm=2; next }
    fm==1 { next }
    { print }
  ' "$1"
}

# wf_phases <workflow.yaml> -> in "id|file|required|when" cho từng phase
wf_phases() {
  awk '
    { sub(/\r$/, "") }
    /^[ \t]*#/ { next }
    /^phases:[ \t]*$/ { inp=1; next }
    inp==1 && /^[A-Za-z]/ {
      if (id != "") { print id "|" file "|" req "|" when; id="" }
      inp=0; next
    }
    inp==1 && /^[ \t]*-[ \t]+id:[ \t]*/ {
      if (id != "") print id "|" file "|" req "|" when
      id=$0; sub(/^[ \t]*-[ \t]+id:[ \t]*/, "", id)
      file=""; req=""; when=""; next
    }
    inp==1 && /^[ \t]+file:[ \t]*/  { file=$0; sub(/^[ \t]+file:[ \t]*/,  "", file); next }
    inp==1 && /^[ \t]+required:[ \t]*/ { req=$0; sub(/^[ \t]+required:[ \t]*/, "", req); next }
    inp==1 && /^[ \t]+when:[ \t]*/  { when=$0; sub(/^[ \t]+when:[ \t]*/,  "", when); next }
    END { if (inp==1 && id != "") print id "|" file "|" req "|" when }
  ' "$1"
}

# wf_commands <workflow.yaml> -> in "id|file" cho từng lệnh tiện ích (khoá commands:)
wf_commands() {
  awk '
    { sub(/\r$/, "") }
    /^[ \t]*#/ { next }
    /^commands:[ \t]*$/ { inc=1; next }
    inc==1 && /^[A-Za-z]/ { inc=0; next }
    inc==1 && /^[ \t]*-[ \t]+id:[ \t]*/ {
      if (id != "") print id "|" file
      id=$0; sub(/^[ \t]*-[ \t]+id:[ \t]*/, "", id); file=""; next
    }
    inc==1 && /^[ \t]+file:[ \t]*/ { file=$0; sub(/^[ \t]+file:[ \t]*/, "", file); next }
    END { if (id != "") print id "|" file }
  ' "$1"
}

# wf_sdlc <workflow.yaml> -> in "stage|status|note" cho từng stage khai trong khối sdlc:
# (stage partial / gap của interface SDLC — tools/check-sdlc.sh)
wf_sdlc() {
  awk '
    { sub(/\r$/, "") }
    /^[ \t]*#/ { next }
    /^sdlc:[ \t]*$/ { ins=1; next }
    ins==1 && /^[A-Za-z]/ { ins=0; next }
    ins==1 && /^[ \t]*-[ \t]+stage:[ \t]*/ {
      if (st != "") print st "|" stt "|" note
      st=$0; sub(/^[ \t]*-[ \t]+stage:[ \t]*/, "", st); stt=""; note=""; next
    }
    ins==1 && /^[ \t]+status:[ \t]*/ { stt=$0; sub(/^[ \t]+status:[ \t]*/, "", stt); next }
    ins==1 && /^[ \t]+note:[ \t]*/   { note=$0; sub(/^[ \t]+note:[ \t]*/, "", note); next }
    END { if (st != "") print st "|" stt "|" note }
  ' "$1"
}

# conv_get <conventions.md> <khoá> -> giá trị trong khối ```conventions
# Khối máy đọc của conventions.md: mỗi dòng "khoá: giá trị", danh sách cách
# nhau bằng dấu cách. File không tồn tại hoặc thiếu khoá -> in rỗng.
conv_get() {
  [ -f "$1" ] || return 0
  awk -v key="$2" '
    { sub(/\r$/, "") }
    /^```conventions[ \t]*$/ { inb=1; next }
    inb==1 && /^```/ { exit }
    inb==1 && $0 ~ "^" key ":" {
      v=$0; sub(/^[^:]*:[ \t]*/, "", v); gsub(/[ \t]+$/, "", v)
      print v; exit
    }
  ' "$1"
}

# file_hash <file> -> hash cả file (cksum, bỏ \r để CRLF/LF cho cùng kết quả).
# Bỏ dấu duyệt máy ghi (tools/lib/approval-tick.sh): ghi dấu không đổi nội dung, không
# được làm artifact phía sau thành lỗi thời.
file_hash() {
  tr -d '\r' < "$1" | sed 's/ *<!-- approval-hash: [0-9a-f]* -->//' | cksum | awk '{ print $1 }'
}

# MAU_ERE_AWK — hàm awk mau_ere(<mẫu>, <moi>) -> ERE khớp cả chuỗi. moi=0: nghĩa của khop_glob
# (* và ? khớp cả "/"); moi=1: ** khớp cả "/", * và ? không. Ký tự khác khớp nguyên văn.
# Ghép vào chương trình awk: awk "$MAU_ERE_AWK"' …dùng mau_ere(…)… '.
# shellcheck disable=SC2016
MAU_ERE_AWK='
function mau_ere(p, moi,   r, i, ch, n, k, lop) {
  r = ""; n = length(p)
  for (i = 1; i <= n; i++) {
    ch = substr(p, i, 1)
    if (ch == "*") {
      if (moi && substr(p, i + 1, 1) == "*") { r = r ".*"; i++ }
      else r = r (moi ? "[^/]*" : ".*")
    } else if (ch == "?") r = r (moi ? "[^/]" : ".")
    else if (ch == "[" && (k = dong_lop(p, i)) > 0) {
      # lớp ký tự như case của shell: [abc], [!a] (phủ định), [[:alpha:]]; "]" ngay sau "[" hoặc
      # "[!" là ký tự thường; lớp chưa đóng hoặc chứa "[" lạ -> "[" nguyên văn (dong_lop)
      lop = substr(p, i + 1, k - i - 1); i = k
      if (substr(lop, 1, 1) == "!") lop = "^" substr(lop, 2)
      gsub(/\\/, "\\\\", lop)
      r = r "[" lop "]"
    }
    else if (index("\\.^$+(){}[]|", ch)) r = r "\\" ch
    else r = r ch
  }
  return "^" r "$"
}
# dong_lop(p, i) -> vị trí "]" đóng lớp mở ở p[i] ("["), 0 nếu lớp không hợp lệ
function dong_lop(p, i,   j, n, e) {
  n = length(p); j = i + 1
  if (substr(p, j, 1) == "!") j++
  if (substr(p, j, 1) == "]") j++
  for (; j <= n; j++) {
    if (substr(p, j, 2) == "[:") {
      if (!(e = index(substr(p, j + 2), ":]"))) return 0
      j += e + 2
    } else if (substr(p, j, 1) == "]") return j
    else if (substr(p, j, 1) == "[") return 0
  }
  return 0
}'

# khop_duong <đường-dẫn> <mẫu...> -> 0 nếu khớp một mẫu theo nghĩa MỚI của glob trong plan.md:
# ** khớp cả "/", * và ? không. Bản này mới chỉ dùng để cảnh báo chuyển tiếp (kc_glob_chuyen_tiep);
# việc khớp phạm vi vẫn theo khop_glob — đổi ở bản sau (roadmap SP18, docs/superpowers/).
khop_duong() {
  _kd_s="$1"; shift
  [ $# -gt 0 ] || return 1
  printf '%s\n' "$@" | awk -v s="$_kd_s" "$MAU_ERE_AWK"'
    $0 != "" && s ~ mau_ere($0, 1) { kq = 1; exit }
    END { exit !kq }'
}

# khop_glob <chuỗi> <mẫu...> -> 0 nếu khớp một mẫu. Trong mẫu, * khớp cả "/".
khop_glob() {
  # Tên biến riêng: sh không có biến cục bộ, dùng _s/_p ở đây sẽ ghi đè biến
  # cùng tên của hàm gọi (đã từng làm kc_test_cu_sua báo sai tên file).
  __kg_s="$1"; shift
  for __kg_p in "$@"; do
    # shellcheck disable=SC2254
    case "$__kg_s" in $__kg_p) return 0 ;; esac
  done
  return 1
}

# intake_base_dong <thư-mục-feature> -> "<ref> <sha>" từ dòng "Base:" của intake.md
# (thiếu phần nào thì phần đó rỗng; không có dòng Base thì không in gì).
intake_base_dong() {
  [ -f "$1/intake.md" ] || return 0
  awk '
    { sub(/\r$/, "") }
    /^[ \t]*-[ \t]*\*\*Base:\*\*/ || /^[ \t]*-?[ \t]*Base:/ {
      s = $0; sub(/^[^:]*:/, "", s); r = ""; h = ""
      if (match(s, /`[^`]+`/)) { r = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) }
      if (match(s, /`[^`]+`/)) { h = substr(s, RSTART + 1, RLENGTH - 2) }
      print r " " h; exit
    }
  ' "$1/intake.md"
}

# ---- thư mục việc ----
# Artifact của việc: <worktree>/TM_VIEC/<tên-branch>/ — commit vào branch khi
# aw check ĐẠT, gỡ khỏi branch trước khi tạo MR (tools/lib/artifact.sh).
# TM_CU: thư mục cục bộ (bị exclude) — .engine/, .adapters, .guard-pre của engine,
# và thư mục việc tạo bằng engine cũ (vẫn đọc được, không commit).
# Lý do: docs/kien-truc.md § Artifact theo feature.
TM_VIEC="docs/sdlc"
TM_CU=".agent-workflow"

# tm_viec <gốc worktree> <tên-thư-mục> -> đường dẫn tương đối của thư mục việc:
# TM_VIEC/<tên>, trừ khi chỉ có bản ở TM_CU (việc bắt đầu bằng engine cũ).
tm_viec() {
  if [ ! -d "$1/$TM_VIEC/$2" ] && [ -d "$1/$TM_CU/$2" ]; then printf '%s/%s\n' "$TM_CU" "$2"
  else printf '%s/%s\n' "$TM_VIEC" "$2"; fi
}

# tm_bo <đường-dẫn tương đối> -> 0 nếu nằm trong thư mục việc (mới hoặc cũ):
# diff, dấu vân tay, quét tài liệu bỏ qua chúng.
tm_bo() {
  case "$1" in "$TM_VIEC"/*|"$TM_CU"/*) return 0 ;; esac
  return 1
}

# ---- git rev-parse có nhớ ----
# Một lần aw check gọi rev-parse cho cùng vài thư mục hàng trăm lần. Nhớ theo thư mục hỏi trong biến
# shell: subshell $(…) kế thừa biến, nên nhớ ở shell chính (nho_san) là mọi lời gọi sau dùng lại.
# Khoá là chính thư mục hỏi — không bao giờ trả kết quả của thư mục / repo khác.
# git_top <dir> -> gốc worktree; git_common <dir> -> thư mục git chung (như git in ra). Lỗi: mã 1.
git_top() {
  case "${_GT_NHO:-}" in *"<$1>="*) _gt=${_GT_NHO#*"<$1>="}; printf '%s\n' "${_gt%%>*}"; return 0 ;; esac
  _gt=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 1
  _GT_NHO="${_GT_NHO:-}<$1>=$_gt>"; printf '%s\n' "$_gt"
}
git_common() {
  case "${_GC_NHO:-}" in *"<$1>="*) _gcm=${_GC_NHO#*"<$1>="}; printf '%s\n' "${_gcm%%>*}"; return 0 ;; esac
  _gcm=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
  _GC_NHO="${_GC_NHO:-}<$1>=$_gcm>"; printf '%s\n' "$_gcm"
}

# ---- conventions.md hiệu lực ----
# Quy ước của repo đích nằm trong git (QU_DUONG_DAN); bản của bản clone
# ($AW_CONFIG/conventions.md) chỉ được ghi đè các khoá QU_KHOA_MAY. Repo chưa
# commit file thì bản clone là toàn bộ quy ước (như trước). Lý do: docs/kien-truc.md.
QU_DUONG_DAN="docs/agent-workflow/conventions.md"
QU_KHOA_MAY="worktree_dir"

# qu_goc <repo> -> gốc của checkout chính
qu_goc() {
  _qc=$(git_common "$1") || return 1
  case "$_qc" in /*) ;; *) _qc="$1/$_qc" ;; esac
  dirname "$(CDPATH= cd -- "$_qc" 2>/dev/null && pwd -P)"
}

# qu_diem_re <repo> -> commit rẽ khỏi base của việc đang làm trong worktree <repo>
# (dòng Base: của intake.md). Ở checkout chính, hoặc chưa có intake.md / Base,
# thì không in gì.
qu_diem_re() {
  _qg=$(qu_goc "$1") || return 0
  _qt=$(git_top "$1") || return 0
  [ "$(CDPATH= cd -- "$_qt" && pwd -P)" != "$_qg" ] || return 0
  _qb=$(git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null)
  _qf="$_qt/$(tm_viec "$_qt" "$(printf '%s' "$_qb" | tr '/' '_')")"
  if [ ! -f "$_qf/intake.md" ]; then
    # Branch không theo branch_patterns: thư mục việc mang tên người đặt —
    # worktree chỉ có một việc thì lấy việc đó.
    _qn=0; _qy=""
    for _qx in "$_qt/$TM_VIEC"/*/intake.md "$_qt/$TM_CU"/*/intake.md; do
      [ -f "$_qx" ] || continue
      _qn=$((_qn + 1)); _qy=$_qx
    done
    [ "$_qn" -eq 1 ] || return 0
    _qf=$(dirname "$_qy")
  fi
  set -- "$1" $(intake_base_dong "$_qf")
  for _qr in "${2:-}" "${3:-}"; do
    [ -n "$_qr" ] || continue
    git -C "$1" rev-parse --verify --quiet "$_qr^{commit}" >/dev/null || continue
    git -C "$1" merge-base "$_qr" HEAD 2>/dev/null && return 0
  done
  return 0
}

# qu_tam <thư-mục> -> tên file tạm riêng (pipeline gọi song song thì $$ trùng nhau)
qu_tam() { mktemp "$1/tam.XXXXXX" 2>/dev/null || { printf '%s/tam.%s.%s\n' "$1" "$$" "$(awk 'BEGIN { srand(); print int(rand() * 1000000) }')"; }; }

# qu_hieu_luc <repo> -> in đường dẫn conventions.md hiệu lực; đặt QU_HL, QU_CHINH
# (file đọc chính), QU_MAY (bản clone dùng để ghi đè, rỗng nếu không), QU_NGUON.
#   1. Trong worktree: QU_DUONG_DAN tại điểm rẽ khỏi base của việc — luật của
#      việc cố định như version engine; việc sửa file này không đổi luật của chính nó.
#   2. Ngược lại (checkout chính, hoặc base chưa có file): cây làm việc của checkout chính.
#   3. Không có cả hai: $AW_CONFIG/conventions.md là toàn bộ quy ước.
# Bản hiệu lực ghi ở $AW_CONFIG/quy-uoc-hieu-luc/ (ngoài cây làm việc).
qu_hieu_luc() {
  if [ "${_QU_REPO:-}" = "$1" ] && [ -n "${QU_HL:-}" ]; then printf '%s\n' "$QU_HL"; return 0; fi
  _QU_REPO=$1; QU_MAY=""; QU_CHINH=""; QU_NGUON=""
  _qm="$AW_CONFIG/conventions.md"; _qd="$AW_CONFIG/quy-uoc-hieu-luc"
  # Khoá theo gốc worktree git in ra: AW_REPO và --out có thể khác nhau qua symlink.
  _qk=$(printf '%s' "$(git_top "$1" || printf '%s' "$1")" | cksum | awk '{ print $1 }')
  _qe=$(qu_diem_re "$1")
  if [ -n "$_qe" ] && git -C "$1" cat-file -e "$_qe:$QU_DUONG_DAN" 2>/dev/null &&
     mkdir -p "$_qd" 2>/dev/null && _qtmp=$(qu_tam "$_qd") &&
     git -C "$1" show "$_qe:$QU_DUONG_DAN" > "$_qtmp" 2>/dev/null &&
     mv "$_qtmp" "$_qd/$_qk.goc.md"; then
    QU_CHINH="$_qd/$_qk.goc.md"
    QU_NGUON="$QU_DUONG_DAN tại điểm rẽ khỏi base ($(printf '%s' "$_qe" | cut -c1-12))"
  else
    _qg=$(qu_goc "$1")
    if [ -n "$_qg" ] && [ -f "$_qg/$QU_DUONG_DAN" ]; then
      QU_CHINH="$_qg/$QU_DUONG_DAN"; QU_NGUON="$QU_CHINH (main checkout)"
    fi
  fi
  if [ -z "$QU_CHINH" ]; then
    QU_CHINH=$_qm; QU_NGUON="$_qm (chỉ ở bản clone, chưa commit)"
  elif [ -f "$_qm" ]; then QU_MAY=$_qm; fi
  # Không có file nào: trả đường dẫn bản clone (không tồn tại) — người gọi báo thiếu.
  if [ ! -f "$QU_CHINH" ]; then QU_HL=$QU_CHINH; printf '%s\n' "$QU_HL"; return 0; fi
  if ! mkdir -p "$_qd" 2>/dev/null || ! _qtmp=$(qu_tam "$_qd"); then QU_HL=$QU_CHINH; printf '%s\n' "$QU_HL"; return 0; fi
  if [ -n "$QU_MAY" ]; then
    awk -v cho=" $QU_KHOA_MAY " '
      { sub(/\r$/, "") }
      FILENAME == ARGV[1] {
        if (/^```conventions[ \t]*$/) { inm = 1; next }
        if (inm == 1 && /^```/) { inm = 2; next }
        if (inm == 1 && /^[a-z][a-z0-9_]*:/) {
          k = $0; sub(/:.*/, "", k)
          if (index(cho, " " k " ") > 0 && !(k in gd)) { gd[k] = $0; thu[++n] = k }
        }
        next
      }
      /^```conventions[ \t]*$/ && !xong { inb = 1; print; next }
      inb == 1 && /^```/ {
        for (i = 1; i <= n; i++) if (!(thu[i] in da)) print gd[thu[i]]
        inb = 0; xong = 1; print; next
      }
      inb == 1 && /^[a-z][a-z0-9_]*:/ {
        k = $0; sub(/:.*/, "", k)
        if ((k in gd) && !(k in da)) { print gd[k]; da[k] = 1; next }
      }
      { print }
    ' "$QU_MAY" "$QU_CHINH" > "$_qtmp"
  else
    tr -d '\r' < "$QU_CHINH" > "$_qtmp"
  fi
  mv "$_qtmp" "$_qd/$_qk.md"
  QU_HL="$_qd/$_qk.md"; printf '%s\n' "$QU_HL"
}

# nho_san <thư-mục-feature> — gọi ở shell chính của script, trước các lời gọi $(…): nhớ gốc repo, thư mục
# git chung và conventions.md hiệu lực (qu_hieu_luc) để mọi subshell dùng lại thay vì gọi git lại.
nho_san() {
  git_top "$1" >/dev/null 2>&1 || return 0
  git_common "$1" >/dev/null 2>&1
  _ns_top=$(git_top "$1")
  git_top "$_ns_top" >/dev/null 2>&1; git_common "$_ns_top" >/dev/null 2>&1
  if [ -n "${AW_CONFIG:-}" ] && command -v qu_hieu_luc >/dev/null 2>&1; then
    qu_hieu_luc "${AW_REPO:-$_ns_top}" >/dev/null 2>&1 || :
  fi
}
