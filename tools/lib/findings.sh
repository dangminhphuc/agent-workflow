#!/usr/bin/env sh
# File phát hiện của checker LLM (<checker>-findings.md) — một nguồn duy nhất cho
# cách đọc trường của mỗi "### PH-NN" (check-design, approval, pending).
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

# Phần awk dùng chung — nối vào trước chương trình awk: awk "$PH_AWK"'…'
#   ph_truong(s)  tên trường chuẩn của dòng "- <trường>: …" trong một PH, hoặc ""
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
