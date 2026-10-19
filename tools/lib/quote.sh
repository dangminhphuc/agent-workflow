#!/usr/bin/env sh
# Câu trích nguyên văn của YC ("- Quote:" + các dòng "> …" trong spec.md) — một nguồn cho
# checker spec (chặn) và rule promote (đường dẫn nguồn [FILE]).
#
#   - Mỗi dòng "> …" là một câu trích, so riêng.
#   - So khớp: chuỗi con sau khi chuẩn hoá cả hai phía — bỏ dấu ">" đầu dòng, gộp mọi
#     khoảng trắng / xuống dòng thành một dấu cách. Ngoài ra phải đúng từng ký tự
#     (markdown, dấu nháy cong, ngoặc kép tự thêm đều tính).
#
# Yêu cầu: không. Không đọc AW_REPO/AW_CONFIG.

# tq_duong_dan <phần Source sau nhãn> -> đường dẫn file nguồn [FILE]:
# chữ đầu, hoặc đích của link "[x.md § Mục](x.md#anchor)" (bỏ anchor).
tq_duong_dan() {
  printf '%s\n' "$1" | tr -d '`' | awk '
    { sub(/^[ \t]+/, "") }
    /^\[[^]]*\]\(/ { s = $0; sub(/^\[[^]]*\]\(/, "", s); sub(/[#)].*$/, "", s); print s; exit }
    { print $1; exit }'
}

# tq_khop <file> <câu trích> -> mã 0 nếu câu có trong file (đã chuẩn hoá), 1 nếu không
tq_khop() {
  # Câu đi qua ENVIRON, không qua -v: -v diễn giải "\t", "\n" trong câu.
  TQ_CAU=$2 awk '
    function chuan(s) { gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
    { sub(/\r$/, ""); s = $0; sub(/^[ \t]*(>[ \t]*)*/, "", s); o = o " " s }
    END { q = chuan(ENVIRON["TQ_CAU"]); if (q == "") exit 1; exit (index(chuan(o), q) > 0) ? 0 : 1 }
  ' "$1"
}
