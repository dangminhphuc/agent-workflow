# Mảnh changelog: mỗi PR ghi một file changes/<tên-nhánh>.md thay vì sửa CHANGELOG.md, để hai PR
# không sửa cùng một chỗ (nguồn conflict chính khi merge). tools/prepare-release.sh gom các mảnh vào
# "## [<version>]" rồi xoá. Mảnh chỉ gồm các mục "### <tên mục>" + nội dung; changes/README.md
# không phải mảnh.

# cl_manh <root>: đường dẫn từng mảnh, mỗi dòng một file, theo thứ tự tên.
cl_manh() {
  for _cl_f in "$1"/changes/*.md; do
    [ -f "$_cl_f" ] || continue
    [ "${_cl_f##*/}" = README.md ] && continue
    printf '%s\n' "$_cl_f"
  done
}

# cl_kiem_manh <file>...: in mỗi lỗi một dòng "<tên file>: …"; không lỗi thì không in gì.
cl_kiem_manh() {
  awk '
    { sub(/\r$/, ""); f = FILENAME; sub(/.*\//, "", f) }
    /^##?[ \t]/ {
      loi[++n] = f ": dòng " FNR ": heading \"#\"/\"##\" phá cấu trúc CHANGELOG.md — chỉ dùng \"### <mục>\""
      next
    }
    /^###[ \t]/ { muc[FILENAME] = $0; co_muc[FILENAME] = 1; trong[FILENAME, $0] = 1; next }
    NF == 0 { next }
    !(FILENAME in muc) {
      if (!(FILENAME in bao_ngoai)) {
        loi[++n] = f ": dòng " FNR ": nội dung nằm ngoài mục — mở đầu bằng \"### Thêm\" (hoặc Thay đổi, Sửa, Bỏ, Nội bộ)"
        bao_ngoai[FILENAME] = 1
      }
      next
    }
    { delete trong[FILENAME, muc[FILENAME]]; co_nd[FILENAME] = 1 }
    END {
      for (i = 1; i < ARGC; i++) {
        a = ARGV[i]; f = a; sub(/.*\//, "", f)
        if (!(a in co_nd) && !(a in bao_ngoai)) loi[++n] = f ": mảnh trống — cần ít nhất một mục \"### …\" có nội dung"
      }
      for (k in trong) {
        split(k, p, SUBSEP); f = p[1]; sub(/.*\//, "", f)
        loi[++n] = f ": mục \"" p[2] "\" trống"
      }
      for (i = 1; i <= n; i++) print loi[i]
    }' "$@"
}

# cl_gom <file>...: gộp nội dung theo mục "### …", mỗi tên mục một lần. Thứ tự: dòng không thuộc
# mục nào (chỉ có ở phần "[Chưa phát hành]" cũ), Thêm, Thay đổi, Sửa, Bỏ, các mục khác theo lần gặp
# đầu, Nội bộ. Trong một mục, nội dung giữ thứ tự file rồi thứ tự dòng.
cl_gom() {
  awk '
    function them(s) { if (!(s in co)) { co[s] = 1; if (s != "" && s !~ /^(Thêm|Thay đổi|Sửa|Bỏ|Nội bộ)$/) khac[++nk] = s } }
    function ra(s) {
      if (!(s in nd)) return
      if (da_in) print ""
      if (s != "") print "### " s
      printf "%s", nd[s]; da_in = 1
    }
    FILENAME != tep { tep = FILENAME; s = ""; trong = 0 }
    { sub(/\r$/, "") }
    /^###[ \t]/ { s = $0; sub(/^###[ \t]+/, "", s); sub(/[ \t]+$/, "", s); trong = 0; next }
    NF == 0 { trong = 1; next }
    {
      them(s)
      if (trong && (s in nd) && cuoi[s] == tep) nd[s] = nd[s] "\n"
      nd[s] = nd[s] $0 "\n"; cuoi[s] = tep; trong = 0
    }
    END {
      ra(""); ra("Thêm"); ra("Thay đổi"); ra("Sửa"); ra("Bỏ")
      for (i = 1; i <= nk; i++) ra(khac[i])
      ra("Nội bộ")
    }' "$@"
}
