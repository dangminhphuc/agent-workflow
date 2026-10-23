#!/usr/bin/env sh
# File phát hiện của checker LLM (<checker>-findings.md) — một nguồn duy nhất cho
# cách đọc trường của mỗi "### FND-NNN" (check-design, approval, pending).
#
#   - Severity: `block | warn`
#   - Category: `<kebab-case>`
#   - Location: `tdd.md` § <mục>
#   - Problem: <...>
#   - Resolution: `open | fixed | rejected: <lý do>`
#
# Việc tạo trước 2026.10.23 dùng trường tiếng Việt (Mức: Chặn | Cảnh báo, Loại,
# Vị trí, Vấn đề, Xử lý: chưa | đã sửa | bác bỏ: <lý do>) — vẫn đọc được, quy
# về giá trị mới để phần còn lại của checker chỉ biết một bộ giá trị.
#
#   ph_loi_chan <file>   mỗi lỗi block một dòng (thiếu file, chưa xong, rejected không lý do)
#   ph_cho_phan_xu <file>  một dòng "Lưu ý:" nếu còn finding chưa phân xử, hoặc file thiếu

# Phần awk dùng chung — nối vào trước chương trình awk: awk "$PH_AWK"'…'
#   ph_truong(s)  tên trường chuẩn của dòng "- <trường>: …" trong một FND, hoặc ""
#   ph_chuan_muc(v) block | warn | <giá trị lạ giữ nguyên>
#   ph_chuan_xl(v)  open | fixed | rejected: <lý do> | <giá trị lạ giữ nguyên>
#   ph_xong(v)    1 nếu đã đóng: fixed, hoặc rejected có lý do thật
#   ph_bac_khong_ly_do(v)  1 nếu rejected mà lý do trống / còn chỗ giữ chỗ
PH_AWK='
  function ph_truong(s) {
    if (s !~ /^[ \t]*[-*][ \t]*/) return ""
    sub(/^[ \t]*[-*][ \t]*[*]*/, "", s)
    if (s ~ /^(Severity|Mức)[*]*[ \t]*:/)     return "muc"
    if (s ~ /^(Category|Loại)[*]*[ \t]*:/)    return "loai"
    if (s ~ /^(Location|Vị trí)[*]*[ \t]*:/)  return "vt"
    if (s ~ /^(Problem|Vấn đề)[*]*[ \t]*:/)   return "vd"
    if (s ~ /^(Resolution|Xử lý)[*]*[ \t]*:/) return "xl"
    return ""
  }
  function ph_chuan_muc(v) { return v == "Chặn" ? "block" : v == "Cảnh báo" ? "warn" : v }
  function ph_chuan_xl(v) {
    if (v == "chưa") return "open"
    if (v == "đã sửa") return "fixed"
    if (v ~ /^bác bỏ/) sub(/^bác bỏ/, "rejected", v)
    return v
  }
  function ph_ly_do(v) { sub(/^rejected[ \t]*[—:-]?[ \t]*/, "", v); return v }
  function ph_bac_khong_ly_do(v,   r) { if (v !~ /^rejected/) return 0; r = ph_ly_do(v); return r == "" || r ~ /^<.*>$/ }
  function ph_xong(v) { return v == "fixed" || (v ~ /^rejected/ && !ph_bac_khong_ly_do(v)) }
'

# awk đọc một file phát hiện: cur/muc/xl của từng ### FND-, rồi gọi xong() ở END.
PH_QUET='
  function ph_gia_tri(s) {
    sub(/^[^:]*:[ \t]*/, "", s)
    gsub(/`/, "", s)
    sub(/[ \t]*<!--.*/, "", s)
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    return s
  }
  { sub(/\r$/, "") }
  /^###[ \t]+FND-[0-9]+/ {
    if (cur != "") xong()
    match($0, /FND-[0-9]+/)
    cur = substr($0, RSTART, RLENGTH); muc = ""; xl = ""
    next
  }
  /^##[ \t]/ { if (cur != "") xong(); cur = ""; next }
  cur != "" && ph_truong($0) == "muc" { muc = ph_chuan_muc(ph_gia_tri($0)); next }
  cur != "" && ph_truong($0) == "xl"  { xl = ph_chuan_xl(ph_gia_tri($0)); next }
'

# ph_loi_chan <file> -> mỗi lỗi một dòng, không tiền tố. Thiếu file cũng là một dòng.
ph_loi_chan() {
  if [ ! -f "$1" ]; then
    echo "Chưa có ${1##*/} — LLM checker chưa chạy. Không có file phát hiện là KHÔNG ĐẠT, không phải \"không có gì để báo\"."
    return 0
  fi
  awk "$PH_AWK$PH_QUET"'
    function xong() {
      if (muc != "block") return
      if (ph_xong(xl)) return
      if (ph_bac_khong_ly_do(xl)) { print cur ": Severity block bị rejected mà không có lý do"; return }
      print cur ": phát hiện Severity block chưa xử lý (Resolution: " (xl == "" ? "trống" : xl) ")"
    }
    END { if (cur != "") xong() }
  ' "$1"
}

# ph_cho_phan_xu <file> -> một dòng "Lưu ý:" khi file thiếu hoặc còn finding chưa xong.
ph_cho_phan_xu() {
  if [ ! -f "$1" ]; then
    echo "Lưu ý:       chưa có ${1##*/} — LLM checker chưa chạy"
    return 0
  fi
  awk "$PH_AWK$PH_QUET"'
    function xong() {
      if (ph_xong(xl)) return
      c++; if (muc == "block") cc++
    }
    END {
      if (cur != "") xong()
      if (c) print "Lưu ý:       còn " c " finding của LLM checker chưa phân xử (block: " cc ") — chạy /aw-clarify"
    }
  ' "$1"
}
