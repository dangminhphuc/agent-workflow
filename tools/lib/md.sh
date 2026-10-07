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
# Bỏ dấu duyệt máy ghi (tools/lib/duyet.sh): ghi dấu không đổi nội dung, không
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
