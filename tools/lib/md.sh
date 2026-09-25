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
