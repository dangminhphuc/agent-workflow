# Nhật ký harness (tools/journal.sh) ghi version engine ở cột cuối mỗi dòng — tools/tests/27-journal-retro.sh.
# jv_version <thư-mục-tools> -> in VERSION của engine chứa thư mục đó; "?" nếu không đọc được.
# Không đọc từ biến môi trường: cùng một engine thì cùng một số, dù gọi từ đâu.
jv_version() {
  _jv=$(tr -d ' \r\n' < "$1/../VERSION" 2>/dev/null)
  printf '%s\n' "${_jv:-?}"
}

# bay <chuỗi> -> một dòng, không tab (ô của TSV nhật ký).
bay() {
  printf '%s' "$1" | tr '\t\r\n' '   ' | sed 's/  */ /g; s/^ //; s/ $//'
}
