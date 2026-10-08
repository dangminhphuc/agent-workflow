#!/usr/bin/env sh
# Kiểm điều kiện ra của phase 06-ship — được tạo MR chưa.
#
#   aw check ship <thư-mục-feature>
#
# Chặn:
#   1. Đầu vào không qua aw check review (cổng chặn cuối).
#   2. review.md còn finding [Blocker] — mức đó nghĩa là "không được merge";
#      sửa là quay lại /aw-implement rồi rà soát lại, không phải mở MR kèm lỗi.
#   3. merge-request.md: thiếu; dòng đầu không phải "# <tiêu đề>"; tiêu đề còn
#      chữ giữ chỗ <…>; xoá mất mục của mẫu (mục không áp dụng ghi "None", mục
#      bị xoá trông như bị quên); Problem / Changes / Testing để trống; còn
#      chữ giữ chỗ "<…>" của mẫu ngoài comment.
# Cảnh báo (không chặn — quy ước tiêu đề là của team, sửa trong conventions.md):
#   tiêu đề dài hơn 72 ký tự; intake.md có mã Jira mà tiêu đề không có.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai check-ship.sh \
  "0=ĐẠT — được tạo MR (aw ship create)" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/cross-check.sh"

DIR="${1:-.}"
MR="$DIR/merge-request.md"
REVIEW="$DIR/review.md"

[ -f "$REVIEW" ] || { echo "LỖI: không tìm thấy $REVIEW — chạy /aw-review trước." >&2; exit 2; }
[ -f "$MR" ]     || { echo "LỖI: không tìm thấy $MR — viết theo mẫu templates/merge-request.md." >&2; exit 2; }

n=0
loi() { n=$((n + 1)); echo "  [LỖI] $1"; }

sh "$HERE/check-review.sh" "$DIR" >/dev/null 2>&1 ||
  loi "Đầu vào chưa đạt: aw check review không ĐẠT — chạy nó để xem chi tiết."

nb=$(awk '{ sub(/\r$/, "") } /^###[ \t]+\[Blocker\]/ && !/<tiêu đề>/' "$REVIEW" | wc -l | tr -d ' ')
[ "$nb" = 0 ] || loi "review.md còn $nb finding [Blocker] — không được merge. Sửa ở /aw-implement rồi chạy lại /aw-review."

# Nội dung đã bỏ comment HTML (kể cả comment nhiều dòng)
than=$(awk '{ sub(/\r$/, "") }
  {
    s = $0; o = ""
    while (s != "") {
      if (trong) { i = index(s, "-->"); if (!i) { s = ""; break } s = substr(s, i + 3); trong = 0 }
      else { i = index(s, "<!--"); if (!i) { o = o s; s = ""; break } o = o substr(s, 1, i - 1); s = substr(s, i + 4); trong = 1 }
    }
    print o
  }' "$MR")

tieu_de=$(printf '%s\n' "$than" | awk 'NF { print; exit }')
case "$tieu_de" in
  "# "*) tieu_de=${tieu_de#\# } ;;
  *) loi "Dòng đầu của merge-request.md phải là \"# <tiêu đề MR>\"."; tieu_de="" ;;
esac
case "$tieu_de" in *"<"*">"*) loi "Tiêu đề còn chữ giữ chỗ: \"$tieu_de\"." ;; esac

for m in Problem Changes "External Impact" "Out of Scope" Deployment Testing "Open Questions"; do
  printf '%s\n' "$than" | grep -q "^## $m[ \t]*\$" ||
    loi "Thiếu mục \"## $m\" — mục không áp dụng thì ghi \"None\", không xoá."
done
for m in Problem Changes Testing; do
  nd=$(printf '%s\n' "$than" | awk -v m="## $m" '
    $0 ~ "^" m "[ \t]*$" { trong = 1; next }
    /^## / { trong = 0 }
    trong && NF { c++ }
    END { print c + 0 }')
  [ "$nd" != 0 ] || loi "Mục \"## $m\" để trống — bắt buộc có nội dung."
done

# Chữ giữ chỗ lấy từ chính mẫu của engine (vd <…>, <test>, <env>): còn nguyên văn là chưa điền.
MAU="$HERE/../workflow/templates/merge-request.md"
gc=$(printf '%s\n' "$than" | awk -v mau="$MAU" '
  BEGIN {
    while ((getline l < mau) > 0) {
      if (l ~ /<!--/) trong = 1
      if (!trong) { s = l; while (match(s, /<[^<>!]+>/)) { g[substr(s, RSTART, RLENGTH)] = 1; s = substr(s, RSTART + RLENGTH) } }
      if (l ~ /-->/) trong = 0
    }
  }
  { for (k in g) if (index($0, k)) { print NR ": " k; break } }' | head -5)
[ -z "$gc" ] || loi "Còn chữ giữ chỗ của mẫu — điền hoặc ghi \"None\": $(printf '%s\n' "$gc" | tr '\n' ';' | sed 's/;$//; s/;/; /g')"

# ---- cảnh báo
if [ -n "$tieu_de" ]; then
  dai=$(printf '%s' "$tieu_de" | wc -m | tr -d ' ')
  [ "$dai" -le 72 ] || echo "  [CẢNH BÁO] Tiêu đề dài $dai ký tự (quy ước mặc định: dưới 72)."
  if [ -f "$DIR/intake.md" ]; then
    mj=$(kc_mau_jira "$(kc_conventions "$DIR")")
    ma=$(awk '/`\[JIRA\]`/' "$DIR/intake.md" | grep -oE "$mj" | sort -u)
    if [ -n "$ma" ]; then
      co=""; for k in $ma; do case "$tieu_de" in *"$k"*) co=1 ;; esac; done
      [ -n "$co" ] || echo "  [CẢNH BÁO] intake.md có mã Jira ($(printf '%s' "$ma" | tr '\n' ' ' | sed 's/ $//')) mà tiêu đề không có."
    fi
  fi
fi

echo ""
if [ "$n" -gt 0 ]; then echo "KHÔNG ĐẠT — $n vi phạm."; exit 1; fi
echo "ĐẠT — tiêu đề: $tieu_de"
