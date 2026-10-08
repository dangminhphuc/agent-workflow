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

# fm_list <file> <khoá> -> in từng mục một dòng
fm_list() {
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR==1 && $0=="---" { fm=1; next }
    fm==1 && $0=="---" { exit }
    fm!=1 { next }
    inlist==1 {
      if ($0 ~ /^[ \t]+-[ \t]+/) { v=$0; sub(/^[ \t]+-[ \t]+/, "", v); print v; next }
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

# ---- conventions.md hiệu lực ----
# Quy ước của repo đích nằm trong git (QU_DUONG_DAN); bản của bản clone
# ($AW_CONFIG/conventions.md) chỉ được ghi đè các khoá QU_KHOA_MAY. Repo chưa
# commit file thì bản clone là toàn bộ quy ước (như trước). Lý do: docs/kien-truc.md.
QU_DUONG_DAN="docs/agent-workflow/conventions.md"
QU_KHOA_MAY="worktree_dir"

# qu_goc <repo> -> gốc của checkout chính
qu_goc() {
  _qc=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
  case "$_qc" in /*) ;; *) _qc="$1/$_qc" ;; esac
  dirname "$(CDPATH= cd -- "$_qc" 2>/dev/null && pwd -P)"
}

# qu_diem_re <repo> -> commit rẽ khỏi base của việc đang làm trong worktree <repo>
# (dòng Base: của intake.md). Ở checkout chính, hoặc chưa có intake.md / Base,
# thì không in gì.
qu_diem_re() {
  _qg=$(qu_goc "$1") || return 0
  _qt=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 0
  [ "$(CDPATH= cd -- "$_qt" && pwd -P)" != "$_qg" ] || return 0
  _qb=$(git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null)
  _qf="$_qt/.agent-workflow/$(printf '%s' "$_qb" | tr '/' '_')"
  if [ ! -f "$_qf/intake.md" ]; then
    # Branch không theo branch_patterns: thư mục việc mang tên người đặt —
    # worktree chỉ có một việc thì lấy việc đó.
    set -- "$1" "$_qt"/.agent-workflow/*/intake.md
    [ $# -eq 2 ] && [ -f "$2" ] || return 0
    _qf=$(dirname "$2")
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
  _qk=$(printf '%s' "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$1")" | cksum | awk '{ print $1 }')
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
      QU_CHINH="$_qg/$QU_DUONG_DAN"; QU_NGUON="$QU_CHINH (checkout chính)"
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
