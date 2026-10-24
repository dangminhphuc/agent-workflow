#!/usr/bin/env sh
# Chạy được trên macOS (bash 3.2 làm sh, BSD awk/sed) mà CI Ubuntu (dash, mawk) không bắt.
# Job kiem-tra-macos của CI chạy cả bộ test; phần này giữ những lỗi đã gặp ngay trên Ubuntu.
# Chạy riêng: sh tools/tests/26-posix-macos.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

nhom "case trong \$(…): pattern mở bằng \"(\" (bash 3.2)"
# bash 3.2 đọc ")" của pattern case nằm trong $( … ) là dấu đóng $( → lỗi cú pháp "near ;;".
# Dạng "(pattern)" là POSIX, dash/bash nào cũng đọc đúng. Bộ dò: đếm độ sâu $( theo ký tự,
# bỏ qua chuỗi trong nháy và chú thích; case ở độ sâu > 0 mà có pattern không mở bằng "(" → in.
cat > "$TMP/do-case.awk" <<'EOF'
FNR == 1 { d = 0; q = ""; incase = 0 }
{
  line = $0; n = length(line); i = 1
  while (i <= n) {
    c = substr(line, i, 1)
    if (q == "'") { if (c == "'") q = ""; i++; continue }
    if (c == "\\") { i += 2; continue }
    if (q == "\"") {
      if (c == "\"") { q = ""; i++; continue }
      if (c == "$" && substr(line, i + 1, 1) == "(") { d++; i += 2; continue }
      if (c == ")" && d > 0 && !incase) d--
      i++; continue
    }
    if (c == "#" && (i == 1 || substr(line, i - 1, 1) ~ /[ \t;]/)) break
    if (c == "'" || c == "\"") { q = c; i++; continue }
    if (c == "$" && substr(line, i + 1, 1) == "(") { d++; i += 2; continue }
    if (substr(line, i) ~ /^case[ \t]/ && (i == 1 || substr(line, i - 1, 1) ~ /[ \t;(|&]/)) {
      if (d > 0 && !incase) { incase = 1; dong = FNR; sai = 0; sau_in = 0 }
      i += 4; continue
    }
    if (incase && substr(line, i) ~ /^esac/) { if (sai) print FILENAME ":" dong; incase = 0; i += 4; continue }
    if (incase && !sau_in && substr(line, i) ~ /^in([ \t]|$)/) { sau_in = 1; cho = 1; i += 2; continue }
    if (incase && sau_in && cho && c !~ /[ \t]/) { if (c != "(") sai = 1; cho = 0 }
    if (incase && c == ";" && substr(line, i + 1, 1) == ";") { cho = 1; i += 2; continue }
    if (!incase && c == ")" && d > 0) d--
    i++
  }
}
EOF
cat > "$TMP/sai.sh" <<'EOF'
x=$(printf 'a\n' | while read -r l; do
  case "$l" in a) echo a ;; esac
done)
EOF
cat > "$TMP/dung.sh" <<'EOF'
x=$(printf 'a\n' | while read -r l; do
  case "$l" in (a) echo a ;; esac
done)
case "$x" in a) echo ngoai ;; esac
y=$(printf '%s' "case in )")
EOF
dung "bộ dò bắt case không có \"(\" trong \$(…)" bang "$(awk -f "$TMP/do-case.awk" "$TMP/sai.sh")" "$TMP/sai.sh:2"
dung "…không báo case có \"(\", case ngoài \$(…), chữ case trong chuỗi" bang "$(awk -f "$TMP/do-case.awk" "$TMP/dung.sh")" ""
# shellcheck disable=SC2046
dung "mã engine không có case thiếu \"(\" trong \$(…)" bang \
  "$(cd "$ROOT" && awk -f "$TMP/do-case.awk" tools/*.sh tools/lib/*.sh bin/aw bin/aw-engine adapters/lib/*.sh adapters/*/build.sh)" ""

ket_thuc
