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

# JU_EPOCH: hàm awk epoch(s) — giây từ mốc ISO "YYYY-MM-DDTHH:MM:SSZ" (UTC). Ghép vào đầu chương trình awk
# (awk "$JU_EPOCH BEGIN { … }"), không truyền qua -v: dùng chung cho report và retro.
JU_EPOCH='
function epoch(s,   y, mo, d, h, mi, se, dm, days) {
  y = substr(s, 1, 4) + 0; mo = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
  h = substr(s, 12, 2) + 0; mi = substr(s, 15, 2) + 0; se = substr(s, 18, 2) + 0
  split("0 31 59 90 120 151 181 212 243 273 304 334", dm, " ")
  days = 365 * (y - 1970) + int((y - 1969) / 4) - int((y - 1901) / 100) + int((y - 1601) / 400) + dm[mo] + (d - 1)
  if (mo > 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)) days++
  return days * 86400 + h * 3600 + mi * 60 + se
}'

# ju_trung_vi: đọc "nhóm<TAB>số" đã sắp theo nhóm rồi theo số (sort -t tab -k1,1 -k2,2n); in "nhóm<TAB>n<TAB>trung vị".
ju_trung_vi() {
  awk -F'\t' '
    function xuat() { if (nhom != "") { m = (n % 2) ? v[(n + 1) / 2] : (v[n / 2] + v[n / 2 + 1]) / 2; printf "%s\t%d\t%s\n", nhom, n, (m == int(m) ? sprintf("%d", m) : sprintf("%.1f", m)) } }
    $1 != nhom { xuat(); nhom = $1; n = 0 }
    { n++; v[n] = $2 + 0 }
    END { xuat() }'
}
