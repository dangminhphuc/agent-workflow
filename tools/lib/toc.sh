#!/usr/bin/env sh
# Mục lục (## Contents) và link giữa các artifact — một nguồn cho `aw toc` (ghi)
# và checker (chặn). Luật cho agent: workflow/rules/general.md §6.
#
#   - Artifact agent viết (TOC_ART) có heading ## / ### thì có mục "## Contents"
#     đứng trước heading ## / ### đầu tiên, liệt kê ĐÚNG mọi heading ## / ### theo
#     thứ tự, mỗi mục là link tới anchor của heading đó.
#   - Link tới một artifact trong TOC_ART phải có "#anchor" trỏ tới mục có thật
#     trong file đó; link "#anchor" trỏ tới mục có thật trong chính file.
#   - Tham chiếu "<artifact>.md § <mục>" phải là link, không là chữ trơn.
#
# Anchor tính như GitHub / VS Code (github-slugger): bỏ thẻ HTML và phần "(url)"
# của link, chữ thường (ASCII + chữ Việt), bỏ dấu câu (trừ "-" "_"), mỗi dấu cách
# thành "-", trùng thì thêm "-1", "-2"… Vd "### YC-001 — Đăng nhập" → yc-001--đăng-nhập.
# Heading trong khối code, HTML comment, frontmatter không tính.
#
# Yêu cầu: không. Không đọc AW_REPO/AW_CONFIG — chỉ làm việc trên thư mục feature.

TOC_ART="intake.md spec.md open-questions.md tdd.md design-findings.md plan.md review.md merge-request.md"

# Phần awk dùng chung — nối vào trước chương trình awk: awk "$TOC_AWK"'…'
#   toc_khoi_tao()     gọi trong BEGIN
#   toc_moi_file()     gọi ở dòng đầu mỗi file (FNR == 1)
#   toc_dong(s)        phân loại dòng: -1 bỏ qua (code/comment/frontmatter),
#                      0 dòng thường, 1..6 heading (toc_chu = chữ heading);
#                      toc_sach = dòng đã bỏ HTML comment
#   toc_slug(s)        anchor của chữ heading (chưa khử trùng)
#   toc_duy_nhat(s)    khử trùng anchor trong file hiện tại
#   toc_thuong(s)      chữ thường ASCII + chữ Việt
TOC_AWK='
  function toc_khoi_tao(   hoa, thuong, i) {
    hoa    = "À Á Ả Ã Ạ Ă Ằ Ắ Ẳ Ẵ Ặ Â Ầ Ấ Ẩ Ẫ Ậ È É Ẻ Ẽ Ẹ Ê Ề Ế Ể Ễ Ệ Ì Í Ỉ Ĩ Ị Ò Ó Ỏ Õ Ọ Ô Ồ Ố Ổ Ỗ Ộ Ơ Ờ Ớ Ở Ỡ Ợ Ù Ú Ủ Ũ Ụ Ư Ừ Ứ Ử Ữ Ự Ỳ Ý Ỷ Ỹ Ỵ Đ"
    thuong = "à á ả ã ạ ă ằ ắ ẳ ẵ ặ â ầ ấ ẩ ẫ ậ è é ẻ ẽ ẹ ê ề ế ể ễ ệ ì í ỉ ĩ ị ò ó ỏ õ ọ ô ồ ố ổ ỗ ộ ơ ờ ớ ở ỡ ợ ù ú ủ ũ ụ ư ừ ứ ử ữ ự ỳ ý ỷ ỹ ỵ đ"
    toc_nhoa = split(hoa, toc_hoa, " "); split(thuong, toc_thg, " ")
    # Dấu câu ngoài ASCII hay gặp trong heading — GitHub bỏ mọi ký tự không phải chữ/số.
    toc_ndau = split("— – → ← ↔ ⇒ “ ” ‘ ’ … § · « » • × ≤ ≥ © ® ™ °", toc_dau, " ")
    toc_p = "!\"#$%&" "\047" "()*+,./:;<=>?@[\\]^`{|}~"
  }
  function toc_moi_file() { toc_st = 0; split("", toc_da) }
  function toc_thuong(s,   i) {
    s = tolower(s)
    for (i = 1; i <= toc_nhoa; i++) gsub(toc_hoa[i], toc_thg[i], s)
    return s
  }
  function toc_slug(s,   i, c, o) {
    gsub(/\]\([^)]*\)/, "", s)
    gsub(/<\/?[A-Za-z][A-Za-z0-9-]*([ \t][^>]*)?>/, "", s)
    s = toc_thuong(s)
    for (i = 1; i <= toc_ndau; i++) gsub(toc_dau[i], "", s)
    o = ""
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c == "\t" || index(toc_p, c)) continue
      o = o (c == " " ? "-" : c)
    }
    return o
  }
  function toc_duy_nhat(s,   g) {
    g = s
    while (s in toc_da) { toc_da[g]++; s = g "-" toc_da[g] }
    toc_da[s] = 0
    return s
  }
  function toc_dong(s,   t, i, r, j, n) {
    toc_chu = ""; toc_sach = ""
    if (FNR == 1 && s == "---") { toc_st = 3; return -1 }
    if (toc_st == 3) { if (s == "---") toc_st = 0; return -1 }
    if (toc_st == 1) { if (s ~ /^[ \t]*(```|~~~)/) toc_st = 0; return -1 }
    if (toc_st == 2) {
      i = index(s, "-->"); if (i == 0) return -1
      toc_st = 0; s = substr(s, i + 3)
    }
    if (s ~ /^[ \t]*(```|~~~)/) { toc_st = 1; return -1 }
    t = s
    while ((i = index(t, "<!--")) > 0) {
      r = substr(t, i + 4); j = index(r, "-->")
      if (j == 0) { t = substr(t, 1, i - 1); toc_st = 2; break }
      t = substr(t, 1, i - 1) substr(r, j + 3)
    }
    toc_sach = t
    if (!match(t, /^#+[ \t]+[^ \t]/)) return 0
    n = 0; while (substr(t, n + 1, 1) == "#") n++
    if (n > 6) return 0
    t = substr(t, n + 1)
    sub(/[ \t]+#+[ \t]*$/, "", t); gsub(/^[ \t]+|[ \t]+$/, "", t)
    toc_chu = t
    return n
  }
'

# toc_chi_muc <thư-mục-feature> -> mỗi heading của mọi artifact (TOC_ART) đang có
# một dòng "file<TAB>cấp<TAB>anchor<TAB>chữ".
toc_chi_muc() {
  __tc_ds=""
  for __tc_a in $TOC_ART; do [ -f "$1/$__tc_a" ] && __tc_ds="$__tc_ds $1/$__tc_a"; done
  [ -n "$__tc_ds" ] || return 0
  # shellcheck disable=SC2086
  awk "$TOC_AWK"'
    BEGIN { toc_khoi_tao() }
    { sub(/\r$/, "") }
    FNR == 1 { toc_moi_file(); f = FILENAME; sub(/^.*\//, "", f) }
    { n = toc_dong($0); if (n > 0) printf "%s\t%d\t%s\t%s\n", f, n, toc_duy_nhat(toc_slug(toc_chu)), toc_chu }
  ' $__tc_ds
}

# toc_loi <thư-mục-feature> <artifact>... -> mỗi vi phạm một dòng "<artifact>: <lý do>".
# Không in gì = sạch. Artifact không có file thì bỏ qua (checker phase tự chặn thiếu file).
toc_loi() {
  __tl_d="$1"; shift
  __tl_cm="${TMPDIR:-/tmp}/aw-toc.$$"
  toc_chi_muc "$__tl_d" > "$__tl_cm"
  for __tl_a in "$@"; do
    [ -f "$__tl_d/$__tl_a" ] || continue
    awk "$TOC_AWK"'
      BEGIN { toc_khoi_tao() }
    NR == 1 { n_art = split(ds_art, art, " "); for (i = 1; i <= n_art; i++) la_art[art[i]] = 1 }
      { sub(/\r$/, "") }
      FILENAME == cm {
        split($0, cot, "\t")
        co[cot[1], cot[3]] = 1; co_file[cot[1]] = 1
        if (cot[1] == ten && (cot[2] == 2 || cot[2] == 3)) {
          if (cot[2] == 2 && cot[4] == "Contents" && !co_ml) { co_ml = 1; next }
          mong[++n_mong] = cot[3]; mong_chu[n_mong] = cot[4]
        }
        ds_slug[cot[1]] = ds_slug[cot[1]] " " cot[3]
        next
      }
      FNR == 1 { toc_moi_file() }
      function loi(m) { print ten ": " m }
      function tim_ma(f, ma,   n, k, a, d) {          # anchor duy nhất bắt đầu bằng mã (vd yc-002)
        n = split(ds_slug[f], a, " "); d = ""
        for (k = 1; k <= n; k++) if (a[k] == ma || index(a[k], ma "-") == 1) { if (d != "") return ""; d = a[k] }
        return d
      }
      {
        n = toc_dong($0)
        if (n < 0) next
        if (n > 0) {
          if (n == 2 && toc_chu == "Contents" && !thay_ml) { thay_ml = 1; trong_ml = 1; if (n_truoc) vi_tri_sai = 1; next }
          trong_ml = 0
          if (n == 2 || n == 3) n_truoc++
          next
        }
        x = toc_sach
        if (trong_ml && match(x, /^[ \t]*[-*][ \t]+\[.*\]\(#[^)]*\)[ \t]*$/)) {
          a = x; sub(/^.*\]\(#/, "", a); sub(/\)[ \t]*$/, "", a); ml[++n_ml] = a
        }
        # Link: ](đích) — link trong mục lục đã kiểm ở END
        y = trong_ml ? "" : x
        while (match(y, /\]\([^)]*\)/)) {
          dich = substr(y, RSTART + 2, RLENGTH - 3); y = substr(y, RSTART + RLENGTH)
          sub(/^[ \t<]+/, "", dich); sub(/[ \t]+".*$/, "", dich); sub(/[> \t]+$/, "", dich)
          if (dich ~ /^[A-Za-z][A-Za-z0-9+.-]*:/) continue
          if (dich ~ /^#/) {
            a = substr(dich, 2)
            if (!((ten, a) in co)) loi("link \"#" a "\" không trỏ tới mục nào trong file — chạy aw toc, hoặc sửa theo heading")
            continue
          }
          f = dich; a = ""
          if (index(f, "#")) { a = substr(f, index(f, "#") + 1); f = substr(f, 1, index(f, "#") - 1) }
          sub(/^\.\//, "", f)
          if (!(f in la_art)) continue
          if (!(f in co_file)) { loi("link tới " f " nhưng thư mục feature chưa có file này"); continue }
          if (a == "") { loi("link tới " f " phải trỏ tới mục, dạng " f "#<anchor> (vd [" f " § YC-001](" f "#yc-001) rồi chạy aw toc)"); continue }
          if (!((f, a) in co)) loi("link \"" f "#" a "\" không trỏ tới mục nào của " f " — chạy aw toc, hoặc sửa theo heading")
        }
        # Tham chiếu chữ trơn "<artifact>.md § <mục>" (ngoài link)
        y = x
        while (match(y, /\[[^[]*\]\([^)]*\)/)) y = substr(y, 1, RSTART - 1) substr(y, RSTART + RLENGTH)
        gsub(/`/, "", y)
        for (i = 1; i <= n_art; i++) {
          f = art[i]; z = y; gap = 0
          while ((k = index(z, f)) > 0) {
            truoc = (k > 1) ? substr(z, k - 1, 1) : ""
            r = substr(z, k + length(f)); z = r
            if (truoc ~ /[A-Za-z0-9_.\/-]/) continue
            sub(/^[ \t]*/, "", r)
            if (index(r, "§") != 1) continue
            sau = substr(r, length("§") + 1); sub(/^[ \t]*/, "", sau); gap = 1; break
          }
          if (!gap) continue
          goi_y = ""
          if (match(sau, /^[A-Z]+-[0-9]+/)) {
            m = substr(sau, RSTART, RLENGTH); a = tim_ma(f, tolower(m))
            if (a != "") goi_y = " — viết thành [" f " § " m "](" f "#" a ")"
          }
          if (goi_y == "") goi_y = " — viết thành [" f " § <mục>](" f "#<anchor>)"
          loi("tham chiếu \"" f " § …\" là chữ trơn, phải là link tới mục" goi_y)
        }
      }
      END {
        if (n_mong == 0) exit
        if (!thay_ml) { loi("thiếu mục \"## Contents\" (mục lục) — chạy aw toc"); exit }
        if (vi_tri_sai) loi("\"## Contents\" phải đứng trước heading ## / ### đầu tiên — chạy aw toc")
        sai = (n_ml != n_mong)
        for (i = 1; i <= n_mong && !sai; i++) if (ml[i] != mong[i]) sai = 1
        if (!sai) exit
        for (i = 1; i <= n_ml; i++) da_ml[ml[i]] = 1
        k = 0
        for (i = 1; i <= n_mong; i++) { la_mong[mong[i]] = 1; if (!(mong[i] in da_ml)) { k++; loi("\"## Contents\" thiếu mục \"" mong_chu[i] "\" (#" mong[i] ") — chạy aw toc") } }
        for (i = 1; i <= n_ml; i++) if (!(ml[i] in la_mong)) { k++; loi("\"## Contents\" có link \"#" ml[i] "\" không ứng với heading ## / ### nào — chạy aw toc") }
        if (!k) loi("\"## Contents\" lệch thứ tự heading hoặc lặp mục — chạy aw toc")
      }
    ' ds_art="$TOC_ART" ten="$__tl_a" cm="$__tl_cm" "$__tl_cm" "$__tl_d/$__tl_a"
  done
  rm -f "$__tl_cm"
}

# toc_ghi <thư-mục-feature> <artifact> -> viết lại mục "## Contents" theo heading và mở
# rộng anchor rút gọn (spec.md#yc-001 → spec.md#yc-001--đăng-nhập) khi chỉ khớp một mục.
# Chỉ ghi khi nội dung đổi; in tên file nếu đã ghi.
toc_ghi() {
  __tg_d="$1"; __tg_a="$2"; __tg_f="$1/$2"
  [ -f "$__tg_f" ] || return 0
  __tg_cm="${TMPDIR:-/tmp}/aw-toc-ghi.$$"
  toc_chi_muc "$__tg_d" > "$__tg_cm"
  awk "$TOC_AWK"'
    BEGIN { toc_khoi_tao() }
    NR == 1 { n_art = split(ds_art, art, " "); for (i = 1; i <= n_art; i++) la_art[art[i]] = 1 }
    { sub(/\r$/, "") }
    FILENAME == cm {
      split($0, cot, "\t")
      co[cot[1], cot[3]] = 1; ds_slug[cot[1]] = ds_slug[cot[1]] " " cot[3]
      if (cot[1] == ten && (cot[2] == 2 || cot[2] == 3)) {
        if (cot[2] == 2 && cot[4] == "Contents" && !co_ml) { co_ml = 1; next }
        n_mong++; cap[n_mong] = cot[2]; slug[n_mong] = cot[3]; chu[n_mong] = cot[4]
        if (min == "" || cot[2] < min) min = cot[2]
      }
      next
    }
    FNR == 1 { toc_moi_file() }
    function ra(s) { print s; trong = (s ~ /^[ \t]*$/) }
    function khoi(   i, l) {
      if (n_mong == 0 || da_in) return
      if (!trong && NR_ra) print ""
      print "## Contents"; print ""
      for (i = 1; i <= n_mong; i++) {
        l = chu[i]; gsub(/\]\([^)]*\)/, "]", l)
        printf "%s- [%s](#%s)\n", (cap[i] > min ? "  " : ""), l, slug[i]
      }
      print ""; trong = 1; da_in = 1
    }
    function mo_rong(f, a,   n, k, s, d, t) {     # anchor đầy đủ, hoặc a nếu không chắc
      if ((f, a) in co) return a
      t = toc_thuong(a); if ((f, t) in co) return t
      n = split(ds_slug[f], s, " "); d = ""
      for (k = 1; k <= n; k++) if (index(s[k], t "-") == 1) { if (d != "") return a; d = s[k] }
      return d == "" ? a : d
    }
    {
      dong = $0
      n = toc_dong(dong)
      # Bỏ mục lục cũ: dòng trống và dòng "- [chữ](#anchor)"; gặp dòng khác là hết mục.
      if (bo_ml) {
        if (n == 0 && (toc_sach ~ /^[ \t]*$/ || toc_sach ~ /^[ \t]*[-*][ \t]+\[.*\]\(#[^)]*\)[ \t]*$/)) next
        bo_ml = 0
      }
      if (n == 2 && toc_chu == "Contents" && !gap_ml) { gap_ml = 1; bo_ml = 1; khoi(); next }
      if (n == 2 || n == 3) khoi()
      if (n == 0) {
        # mở rộng anchor trong link: ](file.md#a) / ](#a)
        x = dong; o = ""
        while (match(x, /\]\([^)#]*#[^)]*\)/)) {
          d = substr(x, RSTART + 2, RLENGTH - 3)
          f = substr(d, 1, index(d, "#") - 1); a = substr(d, index(d, "#") + 1); g = f; sub(/^\.\//, "", g)
          if (g == "") g = ten
          if ((g in la_art) && a !~ /[ \t"]/) d = f "#" mo_rong(g, a)
          o = o substr(x, 1, RSTART + 1) d ")"; x = substr(x, RSTART + RLENGTH)
        }
        dong = o x
      }
      ra(dong); NR_ra++
    }
    END { khoi() }
  ' ds_art="$TOC_ART" ten="$__tg_a" cm="$__tg_cm" "$__tg_cm" "$__tg_f" > "$__tg_f.toc-tmp" || {
    rm -f "$__tg_cm" "$__tg_f.toc-tmp"; echo "LỖI: không viết lại được $__tg_f" >&2; return 1; }
  rm -f "$__tg_cm"
  if cmp -s "$__tg_f" "$__tg_f.toc-tmp"; then
    rm -f "$__tg_f.toc-tmp"
  else
    mv "$__tg_f.toc-tmp" "$__tg_f"; printf '%s\n' "$__tg_a"
  fi
}
