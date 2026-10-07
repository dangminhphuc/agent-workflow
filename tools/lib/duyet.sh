#!/usr/bin/env sh
# Ô duyệt của người — một nguồn duy nhất cho mọi checker và hook `aw guard`.
#
# spec.md: đúng một dòng ở phần đầu file (trước heading "##" đầu tiên):
#   - [ ] **Approved by human** — …
# tdd.md: mỗi "### D-NN" có đúng một dòng trong mục của nó:
#   - [ ] **Approved by human**
#
# Chỉ NGƯỜI tick [x]. Lần đầu thấy tick, máy ghi dấu duyệt — hash nội dung lúc
# đó — vào cuối dòng:  <!-- approval-hash: <16 hex> -->
# Nội dung đổi sau đó mà tick vẫn còn thì trạng thái là "changed-after-approval": bản
# người đã duyệt không còn là bản này. Duyệt lại = người xoá dấu duyệt (giữ tick).
#
# Hash bỏ qua: dòng trống, chú thích HTML, chính dòng ô duyệt; với D-xx bỏ cả
# mục "Critique (agent):" — agent được phản biện mà không làm mất duyệt.
#
# Dòng ô duyệt trong chú thích HTML hay khối ``` không được tính. Dòng có nhãn
# ô duyệt mà sai dạng, sai chỗ, hay lặp lại là lỗi — không đoán.
#
# Cần nạp trước: tools/lib/sha256.sh

DY_NHAN_SPEC="Approved by human"
DY_NHAN_D="Approved by human"

# Phần awk dùng chung: bỏ \r, frontmatter, chú thích, khối ```; nhận dạng ô duyệt.
# Đặt biến cho mỗi dòng: bo (1 = không phải nội dung), od (1 = dòng ô duyệt hợp lệ),
# tick, dau (dấu duyệt), nhan (1 = dòng có nhãn ô duyệt, kể cả sai dạng).
_DY_AWK_CHUNG='
  function bo_cmt(t,   i, j, r) {   # bỏ mọi "<!-- … -->"; còn mở thì bật trong_cmt
    r = ""
    while ((i = index(t, "<!--")) > 0) {
      r = r substr(t, 1, i - 1); t = substr(t, i + 4)
      if ((j = index(t, "-->")) == 0) { trong_cmt = 1; return r }
      t = substr(t, j + 3)
    }
    return r t
  }
  function dy_dong(s,   t) {
    bo = 0; od = 0; tick = 0; dau = ""; nhan = 0
    if (NR == 1 && s == "---") { fm = 1; bo = 1; return }
    if (fm == 1) { if (s == "---") fm = 2; bo = 1; return }
    if (trong_cmt) { if (s ~ /-->/) trong_cmt = 0; bo = 1; return }
    if (s ~ /^[ \t]*```/) { trong_rao = !trong_rao; bo = 1; return }
    if (trong_rao) return
    sach = t = bo_cmt(s)
    if (index(t, nhan_dy) > 0) nhan = 1
    if (t ~ /^[-*] \[[ xX]\] \*\*/ && index(t, "**" nhan_dy "**") == 7) {
      od = 1; tick = (substr(t, 4, 1) != " ")
      if (match(s, /<!-- approval-hash: [0-9a-f]+ -->/)) {
        dau = substr(s, RSTART, RLENGTH); sub(/^<!-- approval-hash: /, "", dau); sub(/ -->$/, "", dau)
      }
    }
  }
'

# dy_quet <file> <spec|tdd> -> bản ghi, mỗi dòng một:
#   O|<khoá>|<tick 0/1>|<dấu duyệt>|<số dòng>|<mở lại 0/1>   một ô duyệt
#   T|<khoá>                                              D-xx không có ô duyệt
#   L|<thông báo>                                         lỗi vị trí/dạng
dy_quet() {
  if [ "$2" = spec ]; then _dy_n=$DY_NHAN_SPEC; else _dy_n=$DY_NHAN_D; fi
  awk -v loai="$2" -v nhan_dy="$_dy_n" "$_DY_AWK_CHUNG"'
    function co_nd(v) { return (v != "" && v !~ /^<.*>$/) }
    { sub(/\r$/, ""); dy_dong($0) }
    bo { next }
    # Dạng cũ (trước ô duyệt): báo rõ để người đổi, không đọc lẫn hai dạng.
    loai == "spec" && !dau_file && (sach ~ /^[-*][ \t]*\*\*Status:\*\*/ || sach ~ /Trạng thái spec[^:]*:/) {
      print "L|spec.md dòng " NR ": dạng cũ \"Status:\" — thay bằng ô duyệt \"- [ ] **" nhan_dy "**\" (xem templates/spec.md)"; next
    }
    loai == "spec" {
      if (sach ~ /^##[ \t]/) dau_file = 1
      if (od) {
        if (dau_file) { print "L|spec.md dòng " NR ": ô duyệt spec phải nằm ở phần đầu file, trước heading \"##\" đầu tiên"; next }
        if (n_od++) { print "L|spec.md dòng " NR ": ô duyệt spec bị lặp — chỉ được có một"; next }
        print "O|spec|" tick "|" dau "|" NR "|0"; next
      }
      if (nhan) print "L|spec.md dòng " NR ": dòng có \"" nhan_dy "\" nhưng sai dạng — phải là \"- [ ] **" nhan_dy "**\" ở đầu dòng"
      next
    }
    # ---- tdd.md ----
    function dong_d() {
      if (d == "") return
      if (!(d in co_od)) print "T|" d
      else print "O|" d "|" d_tick[d] "|" d_dau[d] "|" d_nr[d] "|" ((!d_tick[d] && (d in ly_do)) ? 1 : 0)
      d = ""
    }
    sach ~ /^###[ \t]+D-[0-9]+/ {
      dong_d(); match(sach, /D-[0-9]+/); d = substr(sach, RSTART, RLENGTH)
      if (d in da_gap) d = ""; else da_gap[d] = 1   # mã lặp: checker design báo
      next
    }
    sach ~ /^##?#?[ \t]/ { dong_d(); next }
    od {
      if (d == "") { print "L|tdd.md dòng " NR ": ô duyệt nằm ngoài mục \"### D-NN\""; next }
      if (d in co_od) { print "L|tdd.md dòng " NR ": " d " có nhiều ô duyệt — chỉ được có một"; next }
      co_od[d] = 1; d_tick[d] = tick; d_dau[d] = dau; d_nr[d] = NR; next
    }
    nhan { print "L|tdd.md dòng " NR ": dòng có \"" nhan_dy "\" nhưng sai dạng — phải là \"- [ ] **" nhan_dy "**\" ở đầu dòng"; next }
    d != "" && sach ~ /^[ \t]*-[ \t]*(Status|Trạng thái)[^:]*:/ {
      print "L|tdd.md dòng " NR ": " d " dùng dạng cũ \"Status:\" — thay bằng ô duyệt \"- [ ] **" nhan_dy "**\" (xem templates/tdd.md)"; next
    }
    d != "" && sach ~ /Reopen reason[^:]*:/ { v = sach; sub(/^[^:]*:/, "", v); gsub(/[*`]/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v); if (co_nd(v)) ly_do[d] = 1 }
    END {
      dong_d()
      if (loai == "spec" && !n_od) print "L|spec.md thiếu ô duyệt \"- [ ] **" nhan_dy "**\" ở phần đầu file (xem templates/spec.md)"
    }
  ' "$1"
}

# dy_noi_dung <file> <spec|tdd> <khoá> -> nội dung đem băm, đã chuẩn hoá
dy_noi_dung() {
  if [ "$2" = spec ]; then _dy_n=$DY_NHAN_SPEC; else _dy_n=$DY_NHAN_D; fi
  awk -v loai="$2" -v khoa="$3" -v nhan_dy="$_dy_n" "$_DY_AWK_CHUNG"'
    { sub(/\r$/, ""); dy_dong($0) }
    bo || od { next }
    loai == "tdd" {
      if (sach ~ /^###[ \t]+D-[0-9]+/) { match(sach, /D-[0-9]+/); trong = (substr(sach, RSTART, RLENGTH) == khoa); pb = 0 }
      else if (sach ~ /^##?#?[ \t]/) trong = 0
      if (!trong) next
      # "- Critique (agent): …" và các dòng thụt vào ngay dưới nó
      if (sach ~ /^[-*][ \t]*Critique \(agent\)/) { pb = 1; next }
      if (pb && sach ~ /^[ \t]+[^ \t]/) next
      pb = 0
    }
    { sub(/[ \t]+$/, "", sach) }
    sach != "" { print sach }
  ' "$1"
}

# dy_hash <file> <spec|tdd> <khoá> -> 16 ký tự hex đầu của sha256 nội dung
dy_hash() {
  dy_noi_dung "$1" "$2" "$3" | sha256_stdin | cut -c1-16
}

# dy_trang_thai <file> <spec|tdd> -> bản ghi:
#   S|<khoá>|<proposed | approved | reopened | changed-after-approval | missing-box>
#   L|<thông báo>
# "approved" gồm cả tick chưa có dấu duyệt (dy_dong_dau sẽ ghi).
dy_trang_thai() {
  dy_quet "$1" "$2" | while IFS='|' read -r _k _a _b _c _e _f; do
    case "$_k" in
      L) printf 'L|%s\n' "$_a" ;;
      T) printf 'S|%s|missing-box\n' "$_a"
         printf 'L|%s: thiếu ô duyệt "- [ ] **%s**"\n' "$_a" "$DY_NHAN_D" ;;
      O)
        if [ "$_b" = 1 ]; then
          if [ -z "$_c" ] || [ "$_c" = "$(dy_hash "$1" "$2" "$_a")" ]; then printf 'S|%s|approved\n' "$_a"
          else printf 'S|%s|changed-after-approval\n' "$_a"; fi
        elif [ "$_f" = 1 ]; then printf 'S|%s|reopened\n' "$_a"
        else printf 'S|%s|proposed\n' "$_a"; fi ;;
    esac
  done
}

# _dy_sua <file> <danh-sách "số_dòng=hành_động"> — hành động: dau:<hex> | bo-dau | bo-tick
# Chỉ đụng đúng các dòng đó; dòng khác giữ nguyên byte (kể cả \r).
_dy_sua() {
  awk -v ds="$2" '
    BEGIN { n = split(ds, a, " "); for (i = 1; i <= n; i++) { split(a[i], p, "="); hd[p[1]] = p[2] } }
    !(FNR in hd) { print; next }
    {
      cr = sub(/\r$/, ""); s = $0
      sub(/ *<!-- approval-hash: [0-9a-f]+ -->/, "", s)
      h = hd[FNR]
      if (h == "bo-tick") s = substr(s, 1, 3) " " substr(s, 5)
      else if (h ~ /^dau:/) s = s " <!-- approval-hash: " substr(h, 5) " -->"
      printf "%s%s\n", s, (cr ? "\r" : "")
    }
  ' "$1" > "$1.dy.$$" && cat "$1.dy.$$" > "$1"
  rm -f "$1.dy.$$"
}

# dy_dong_dau <file> <spec|tdd> -> ghi dấu duyệt cho ô đã tick mà chưa có dấu;
# xoá dấu thừa ở ô chưa tick. In khoá vừa ghi dấu, mỗi dòng một.
dy_dong_dau() {
  [ -f "$1" ] || return 0
  _dy_ds=""
  _dy_ra=$(dy_quet "$1" "$2" | while IFS='|' read -r _k _a _b _c _e _f; do
    [ "$_k" = O ] || continue
    if [ "$_b" = 1 ] && [ -z "$_c" ]; then printf '%s=dau:%s %s\n' "$_e" "$(dy_hash "$1" "$2" "$_a")" "$_a"
    elif [ "$_b" = 0 ] && [ -n "$_c" ]; then printf '%s=bo-dau -\n' "$_e"; fi
  done)
  [ -n "$_dy_ra" ] || return 0
  _dy_ds=$(printf '%s\n' "$_dy_ra" | awk '{ printf "%s ", $1 }')
  _dy_sua "$1" "$_dy_ds"
  printf '%s\n' "$_dy_ra" | awk '$2 != "-" { print $2 }'
}

# dy_bo_tick <file> <số dòng...> -> bỏ tick (và dấu duyệt) ở đúng các dòng đó
dy_bo_tick() {
  _dy_f=$1; shift; _dy_ds=""
  for _dy_l in "$@"; do _dy_ds="$_dy_ds $_dy_l=bo-tick"; done
  [ -n "$_dy_ds" ] && _dy_sua "$_dy_f" "$_dy_ds"
}
