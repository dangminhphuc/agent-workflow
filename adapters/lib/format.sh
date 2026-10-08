#!/usr/bin/env sh
# Kiểm file adapter sinh ra đúng chuẩn của agent đọc nó — chạy trong ghi_file
# (adapters/lib/common.sh) TRƯỚC khi file vào chỗ. Sai chuẩn thì agent bỏ qua file
# hoặc hiểu sai (frontmatter YAML hỏng, name không khớp tên file…) mà không báo
# ai: lệnh biến mất khỏi menu, subagent không gọi được. Build phải chặn ở đây.
#
# Chuẩn riêng của agent nằm trong build.sh của adapter (chữ riêng chỉ ở adapter):
#
#   AD_LENH_FM="co"|"khong"   file lệnh bắt buộc / cấm frontmatter
#   AD_LENH_KHOA="…"          khoá frontmatter được phép trong file lệnh
#   AD_AGENT_KHOA="…"         khoá được phép trong subagent
#   AD_SKILL_KHOA="…"         khoá được phép trong SKILL.md
#
# Luật chung (Claude Code và Cursor đều theo; skill theo chuẩn Agent Skills):
#   - frontmatter: dòng 1 là ---, có --- đóng, mỗi dòng "khoá: giá trị", không tab,
#     không khoá trùng, khoá nằm trong danh sách được phép; giá trị YAML hợp lệ
#     (bắt đầu bằng [ { * & ! | > % @ ` ' " hoặc chứa ": " / " #" thì phải nằm
#     trong nháy, và nháy phải đóng đúng)
#   - lệnh có frontmatter: description không rỗng
#   - subagent, skill: name + description không rỗng; name = tên file (subagent)
#     / tên thư mục (skill), chữ thường a-z 0-9 nối bằng "-", ≤ 64 ký tự
#   - skill: description ≤ 1024 ký tự, name/description không có < >
#   - tên file lệnh cũng theo dạng tên trên (là tên người gõ sau "/")
#   - thân (sau frontmatter) không rỗng

# dd_kiem <file-cần-kiểm> <đường-dẫn-đích> — 0 nếu đúng chuẩn; không thì in từng
# lỗi ra stderr, trả 1. <đường-dẫn-đích> quyết định loại file và tên phải khớp.
dd_kiem() {
  _dd_rel=${2#"$OUT/$AD_GOC/"}
  case "$_dd_rel" in
    commands/*/*) _dd_loai="" ;;
    commands/*.md) _dd_loai=lenh; _dd_ten=$(basename "$_dd_rel" .md); _dd_fm=$AD_LENH_FM; _dd_khoa=$AD_LENH_KHOA ;;
    agents/*/*) _dd_loai="" ;;
    agents/*.md) _dd_loai=agent; _dd_ten=$(basename "$_dd_rel" .md); _dd_fm=co; _dd_khoa=$AD_AGENT_KHOA ;;
    skills/*/SKILL.md) _dd_loai=skill; _dd_ten=$(basename "$(dirname "$_dd_rel")"); _dd_fm=co; _dd_khoa=$AD_SKILL_KHOA ;;
    *) _dd_loai="" ;;
  esac
  if [ -z "$_dd_loai" ]; then
    echo "LỖI [$AD_TEN]: $AD_GOC/$_dd_rel — đường dẫn $AD_TEN không đọc (chỉ commands/<tên>.md, agents/<tên>.md, skills/<tên>/SKILL.md)." >&2
    return 1
  fi
  LC_ALL=C awk -v f="$AD_GOC/$_dd_rel" -v ag="$AD_TEN" -v loai="$_dd_loai" -v ten="$_dd_ten" \
      -v fm="$_dd_fm" -v khoa="$_dd_khoa" '
    function loi(m) { printf "LỖI [%s]: %s — %s\n", ag, f, m > "/dev/stderr"; sai = 1 }
    # số ký tự UTF-8: bỏ byte nối tiếp 10xxxxxx
    function nkt(s) { gsub(/[\200-\277]/, "", s); return length(s) }
    function ten_hop_le(s) { return s ~ /^[a-z0-9]+(-[a-z0-9]+)*$/ && length(s) <= 64 }
    BEGIN {
      n = split(khoa, k, " "); for (i = 1; i <= n; i++) duoc[k[i]] = 1
      vung = "than"; sai = 0; nthan = 0
    }
    { sub(/\r$/, "") }
    NR == 1 {
      if (fm == "co") {
        if ($0 != "---") { loi("thiếu frontmatter: dòng 1 phải là ---"); dung = 1; exit }
        vung = "fm"; next
      }
      if ($0 == "---") loi(ag " không đọc frontmatter ở file lệnh — dòng 1 không được là ---")
    }
    vung == "fm" && $0 == "---" { vung = "than"; dong = 1; next }
    vung == "fm" {
      if ($0 ~ /\t/) loi("frontmatter có tab (YAML không nhận): " $0)
      if ($0 !~ /^[a-z][a-zA-Z0-9_-]*:( |$)/) { loi("dòng frontmatter không phải \"khoá: giá trị\": " $0); next }
      kk = $0; sub(/:.*/, "", kk)
      v = substr($0, length(kk) + 2); sub(/^ +/, "", v); sub(/ +$/, "", v)
      if (kk in gt) loi("khoá trùng: " kk)
      if (!(kk in duoc)) loi("khoá \"" kk "\" không thuộc chuẩn " ag " (được: " khoa ")")
      if (v ~ /^"/) {
        if (v !~ /^"([^"\\]|\\.)*"$/) loi("giá trị " kk " mở nháy kép nhưng không đóng đúng: " v)
        v = substr(v, 2, length(v) - 2); gsub(/\\./, "x", v)
      } else if (v ~ /^\047/) {
        if (v !~ /^\047([^\047]|\047\047)*\047$/) loi("giá trị " kk " mở nháy đơn nhưng không đóng đúng: " v)
        v = substr(v, 2, length(v) - 2)
      } else if (v ~ /^[][{}*&!|>%@`]/ || v ~ /^[-?] / || v ~ /: / || v ~ / #/ || v ~ /:$/) {
        loi("giá trị " kk " phải đặt trong nháy (YAML hiểu sai): " v)
      }
      gt[kk] = v; next
    }
    vung == "than" && $0 ~ /[^ ]/ { nthan++ }
    END {
      if (dung) exit 1
      if (vung == "fm") loi("frontmatter không có dòng --- đóng")
      if (nthan == 0) loi("thân file rỗng")
      if (!ten_hop_le(ten)) loi("tên \"" ten "\" không hợp lệ (a-z 0-9 nối bằng -, ≤ 64 ký tự)")
      if (fm == "co" && (!("description" in gt) || gt["description"] == "")) loi("thiếu description")
      if (loai == "agent" || loai == "skill") {
        if (!("name" in gt) || gt["name"] == "") loi("thiếu name")
        else if (gt["name"] != ten) loi("name \"" gt["name"] "\" khác tên " (loai == "skill" ? "thư mục" : "file") " \"" ten "\"")
      }
      if (loai == "skill") {
        if (nkt(gt["description"]) > 1024) loi("description dài " nkt(gt["description"]) " ký tự (tối đa 1024)")
        if (gt["name"] gt["description"] ~ /[<>]/) loi("name/description có < > (chuẩn skill không nhận thẻ XML)")
      }
      exit sai
    }' "$1"
}
