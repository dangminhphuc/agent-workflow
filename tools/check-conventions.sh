#!/usr/bin/env sh
# Kiểm conventions.md sau khi NGƯỜI sửa — script đọc nó đúng như người nghĩ, và
# phần văn xuôi còn đủ khung cho agent. Kiểm bản hiệu lực (qu_hieu_luc, md.sh):
# file đã commit trong repo đích (QU_DUONG_DAN) + bản của bản clone chỉ ghi đè
# khoá máy (QU_KHOA_MAY); repo chưa commit file thì bản clone là toàn bộ quy ước.
#
#   aw conventions check
#
# Lỗi (✗) — script sẽ đọc sai hoặc bỏ qua ngầm:
#   - không có file; không có / thừa / chưa đóng khối ```conventions
#   - bản của bản clone khai khoá ngoài QU_KHOA_MAY khi repo đã có file đã commit
#   - dòng trong khối không phải "khoá: giá trị", "#…" hay dòng trống (vd thụt lề)
#   - khoá lạ (gõ sai) — script bỏ qua khoá lạ, luật tương ứng tắt mà không ai biết
#   - khoá khai hai lần — dòng sau bị bỏ qua
#   - khoá bắt buộc trống: base_branch branch_patterns type_by_prefix test_files
#   - giá trị sai dạng: mr_platform, type_by_prefix (cặp, loại, khớp branch_patterns),
#     regex không biên dịch được hoặc dùng {n}, worktree_dir thiếu {ten} / nằm trong repo
#   - knowledge_adr_dir, knowledge_rules_dir tuyệt đối, có "..", hay nằm trong .agent-workflow/
#   - base_branch không có (local lẫn origin); file khai ở rules_* hay mục uses_* không dùng được
#
# Cảnh báo (!) — chạy được nhưng nhiều khả năng chưa đúng ý:
#   - quy ước chưa commit vào repo đích (chỉ ở bản clone) — gợi ý cách chuyển
#   - khoá có trong mẫu của engine mà file thiếu (init từ engine cũ) — luật đang tắt
#   - production_code / test_files / sensitive_code không khớp file nào trong repo
#   - file khớp cả test_files lẫn production_code
#   - phần Team conventions còn placeholder, hoặc thiếu mục "### Merge request"
#
# Không kiểm được: giá trị có đúng Ý ĐỊNH của team không, văn xuôi có rõ không.
# Chỉ đọc, không sửa gì.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai check-conventions.sh \
  "0=HỢP LỆ — đọc các dòng ! (nếu có) xem có đúng ý không" \
  "1=KHÔNG HỢP LỆ — sửa các dòng ✗ trong conventions.md" \
  "2=SAI THAM SỐ"
. "$HERE/lib/md.sh"
. "$HERE/lib/commands.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/worktree.sh"
. "$HERE/lib/env.sh"
mt_dat

[ $# -eq 0 ] || { echo "Dùng: aw conventions check" >&2; exit 2; }

ENG="${AW_ENGINE:-$(CDPATH= cd -- "$HERE/.." && pwd)}"
MAU="$ENG/workflow/templates/conventions.md"
CONV="$MT_CONV"

n_x=0; n_c=0
loi()      { echo "  ✗ $1"; n_x=$((n_x + 1)); }
canh_bao() { echo "  ! $1"; n_c=$((n_c + 1)); }

CHINH_F=$QU_CHINH
echo "Kiểm $QU_NGUON"
[ -z "$QU_MAY" ] || echo "  bản clone ghi đè: $QU_MAY (chỉ khoá: $QU_KHOA_MAY)"
[ -f "$CHINH_F" ] || { loi "không có file — tạo $QU_DUONG_DAN trong repo (aw init tạo từ mẫu) rồi commit"; exit 1; }

# Khoá máy biết: khoá trong mẫu của engine, cộng rules_<phase>, uses_<phase> của mọi phase.
khoa_mau() {
  awk '
    { sub(/\r$/, "") }
    /^```conventions[ \t]*$/ { inb = 1; next }
    inb == 1 && /^```/ { exit }
    inb == 1 && /^[a-z][a-z0-9_]*:/ { k = $0; sub(/:.*/, "", k); print k }
  ' "$1"
}
BIET=" $(khoa_mau "$MAU" | tr '\n' ' ')$(printf 'rules_%s ' $BL_QUY_TAC)$(printf 'uses_%s ' $BL_QUY_TAC)"

# ---- cấu trúc: khối, từng dòng, khoá lạ, khoá trùng ----
CT=$(awk -v biet="$BIET" '
  { sub(/\r$/, "") }
  /^```conventions[ \t]*$/ {
    n_khoi++
    if (n_khoi > 1) print "dòng " NR ": khối ```conventions thứ hai — script chỉ đọc khối đầu, gộp vào một khối"
    inb = 1; next
  }
  inb == 1 && /^```/ { inb = 0; dong = 1; next }
  inb != 1 { next }
  /^[ \t]*$/ || /^#/ { next }
  /^[a-z][a-z0-9_]*:/ {
    k = $0; sub(/:.*/, "", k)
    if (index(biet, " " k " ") == 0) print "dòng " NR ": khoá lạ \"" k "\" — script bỏ qua; xem tên đúng trong conventions-reference.md"
    else if (k in da) print "dòng " NR ": khoá \"" k "\" khai lần hai (lần đầu ở dòng " da[k] ") — script chỉ đọc lần đầu"
    else da[k] = NR
    next
  }
  { s = $0; if (length(s) > 50) s = substr(s, 1, 50) "…"
    print "dòng " NR ": không phải \"khoá: giá trị\" (khoá viết sát đầu dòng, chữ thường) — script bỏ qua: " s }
  END {
    if (n_khoi == 0) print "không có khối ```conventions — script không đọc được khoá nào"
    else if (inb == 1 && !dong) print "khối ```conventions chưa đóng bằng dòng ```"
  }
' "$CHINH_F")
echo "Cấu trúc"
if [ -n "$CT" ]; then
  printf '%s\n' "$CT" | while IFS= read -r l; do echo "  ✗ $l"; done
  n_x=$((n_x + $(printf '%s\n' "$CT" | grep -c .)))
else
  echo "  ✓ khối \`\`\`conventions đọc được, không có khoá lạ hay trùng"
fi

# Bản clone khi repo đã có file đã commit: chỉ khoá máy, mọi khoá khác phải qua PR.
if [ -n "$QU_MAY" ]; then
  KM=$(awk -v cho=" $QU_KHOA_MAY " -v dd="$QU_DUONG_DAN" '
    { sub(/\r$/, "") }
    /^```conventions[ \t]*$/ { inb = 1; next }
    inb == 1 && /^```/ { inb = 0; next }
    inb != 1 || /^[ \t]*$/ || /^#/ { next }
    /^[a-z][a-z0-9_]*:/ {
      k = $0; sub(/:.*/, "", k)
      if (index(cho, " " k " ") == 0) print "bản clone dòng " NR ": khoá \"" k "\" chỉ được khai trong " dd " (đã commit) — xoá khỏi bản clone"
      next
    }
    { print "bản clone dòng " NR ": không phải \"khoá: giá trị\" — script bỏ qua" }
  ' "$QU_MAY")
  if [ -n "$KM" ]; then
    printf '%s\n' "$KM" | while IFS= read -r l; do echo "  ✗ $l"; done
    n_x=$((n_x + $(printf '%s\n' "$KM" | grep -c .)))
  else
    echo "  ✓ bản clone chỉ ghi đè khoá máy"
  fi
fi

co_khoa() { # <khoá> -> 0 nếu file có dòng khai khoá này (kể cả để trống)
  awk -v k="$1" '
    { sub(/\r$/, "") }
    /^```conventions[ \t]*$/ { inb = 1; next }
    inb == 1 && /^```/ { exit }
    inb == 1 && index($0, k ":") == 1 { f = 1; exit }
    END { exit !f }
  ' "$CONV"
}
gt() { conv_get "$CONV" "$1"; }

# ---- giá trị ----
echo "Giá trị"
n_truoc=$n_x
for k in base_branch branch_patterns type_by_prefix test_files; do
  [ -n "$(gt $k)" ] || loi "$k trống — bắt buộc"
done

case "$(gt mr_platform)" in
  ""|github|gitlab) ;;
  *) loi "mr_platform \"$(gt mr_platform)\" — chỉ nhận github hoặc gitlab (trống = đoán từ origin)" ;;
esac

BP=$(gt branch_patterns)
for cap in $(gt type_by_prefix); do
  tt=${cap%%=*}; lt=${cap#*=}
  case "$cap" in *=*) ;; *) loi "type_by_prefix: \"$cap\" không có dạng tiền-tố=loại"; continue ;; esac
  [ -n "$tt" ] || { loi "type_by_prefix: \"$cap\" thiếu tiền tố"; continue; }
  case " $LOAI_HOP_LE " in
    *" $lt "*) ;;
    *) loi "type_by_prefix: loại \"$lt\" không hợp lệ (có: $LOAI_HOP_LE)"; continue ;;
  esac
  if [ -n "$BP" ]; then
    set -f
    # shellcheck disable=SC2086
    khop_glob "${tt}vi-du" $BP || loi "type_by_prefix: branch \"${tt}<mô-tả>\" không khớp branch_patterns — aw feature sẽ không nhận ra việc loại $lt"
    set +f
  fi
done

re_dung() { # <khoá> <cách dùng: awk|grep>
  _re=$(gt "$1"); [ -n "$_re" ] || return 0
  case "$_re" in *'{'[0-9]*) loi "$1: không dùng {n} (mawk không hỗ trợ) — viết lặp ra, vd [0-9][0-9]*" ; return 0 ;; esac
  if [ "$2" = awk ]; then
    awk -v r="$_re" 'BEGIN { if ("x" ~ r) {} }' >/dev/null 2>&1
  else
    printf 'x\n' | grep -E "$_re" >/dev/null 2>&1; [ $? -le 1 ]
  fi || loi "$1: regex \"$_re\" không biên dịch được"
}
re_dung jira_key_regex awk
re_dung skipped_test_regex grep

CHINH=$(wt_chinh "$MT_REPO" 2>/dev/null) || CHINH=$MT_REPO
TM=$(gt worktree_dir)
if [ -n "$TM" ]; then
  case "$TM" in *'{ten}'*) ;; *) loi "worktree_dir \"$TM\" thiếu {ten} — mọi worktree sẽ trùng một thư mục" ;; esac
  d=$(printf '%s' "$TM" | awk -v r="$(basename "$CHINH")" '{ gsub(/\{repo\}/, r); gsub(/\{ten\}/, "x"); print }')
  case "$d" in /*) ;; *) d="$CHINH/$d" ;; esac
  case "$(wt_chuan_hoa "$d")/" in
    "$CHINH"/*) loi "worktree_dir \"$TM\" nằm TRONG repo — phải ở ngoài, vd ../{repo}.wt/{ten}" ;;
  esac
fi

BB=$(gt base_branch)
if [ -n "$BB" ] && ! git -C "$MT_REPO" rev-parse --verify --quiet "refs/heads/$BB" >/dev/null &&
   ! git -C "$MT_REPO" rev-parse --verify --quiet "refs/remotes/origin/$BB" >/dev/null; then
  loi "base_branch \"$BB\" không có trong repo (cả local lẫn origin)"
fi

for k in knowledge_adr_dir knowledge_rules_dir; do
  AD=$(gt $k)
  case "$AD" in
    "") ;;
    /*|*..*) loi "$k \"$AD\" phải là đường dẫn tương đối trong repo, không có \"..\"" ;;
    .agent-workflow*) loi "$k \"$AD\" nằm trong .agent-workflow/ (bị exclude) — kiến thức bền phải vào git" ;;
  esac
done
qt=$(kc_quy_tac_loi "$MT_REPO" review)
[ -n "$qt" ] && { printf '%s\n' "$qt" | while IFS= read -r l; do echo "  ✗ $l"; done; n_x=$((n_x + $(printf '%s\n' "$qt" | grep -c .))); }
[ "$n_x" = "$n_truoc" ] && echo "  ✓ giá trị đúng dạng"

# ---- cảnh báo ----
echo "Cảnh báo"
if [ "$CHINH_F" = "$AW_CONFIG/conventions.md" ]; then
  canh_bao "quy ước chưa commit vào repo — mỗi bản clone một bản. Chuyển: mkdir -p $(dirname "$QU_DUONG_DAN") && cp $CHINH_F $QU_DUONG_DAN, commit qua PR, rồi chỉ giữ ở bản clone các khoá $QU_KHOA_MAY (hoặc xoá file)"
fi
for k in $(khoa_mau "$MAU"); do
  co_khoa "$k" || canh_bao "thiếu khoá $k (mẫu của engine có) — đang được coi là để trống; thêm từ $MAU"
done

DS=$(git -C "$CHINH" ls-files 2>/dev/null)
khop_ds() { # <khoá> -> các file trong repo khớp khoá
  _m=$(gt "$1"); [ -n "$_m" ] || return 0
  set -f
  printf '%s\n' "$DS" | while IFS= read -r _f; do
    # shellcheck disable=SC2086
    [ -n "$_f" ] && khop_glob "$_f" $_m && printf '%s\n' "$_f"
  done
  set +f
}
if [ -n "$DS" ]; then
  for k in production_code test_files sensitive_code; do
    [ -n "$(gt $k)" ] || continue
    [ -n "$(khop_ds $k | head -1)" ] || canh_bao "$k \"$(gt $k)\" không khớp file nào trong repo — luật dựa vào khoá này không bao giờ chạy"
  done
  CHUNG=$(khop_ds test_files | while IFS= read -r f; do
    set -f
    # shellcheck disable=SC2086
    khop_glob "$f" $(gt production_code) && printf '%s\n' "$f"
    set +f
  done)
  if [ -n "$CHUNG" ]; then
    canh_bao "$(printf '%s\n' "$CHUNG" | grep -c .) file khớp cả test_files lẫn production_code (vd $(printf '%s\n' "$CHUNG" | head -2 | tr '\n' ' ')) — bị tính là code production: chore không sửa được, perf --before từ chối"
  fi
fi

NG=$(awk '
  { sub(/\r$/, "") }
  /^```conventions[ \t]*$/ { inb = 1; next }
  inb == 1 { if (/^```/) inb = 0; next }
  /^###[ \t]+Merge request[ \t]*$/ { mr = 1 }
  /^<[^!]/ || /Chưa định nghĩa/ || /<[0-9]+>/ || /<[^<>|]+\|[^<>]+>/ { print "dòng " NR ": còn placeholder — " substr($0, 1, 60) }
  END { if (!mr) print "thiếu mục \"### Merge request\" — /aw-ship dùng mục này cho tiêu đề, mô tả MR" }
' "$CHINH_F")
[ -n "$NG" ] && { printf '%s\n' "$NG" | while IFS= read -r l; do echo "  ! $l"; done; n_c=$((n_c + $(printf '%s\n' "$NG" | grep -c .))); }
[ "$n_c" = 0 ] && echo "  ✓ không có"

echo ""
echo "$n_x lỗi, $n_c cảnh báo."
[ "$n_x" = 0 ]
