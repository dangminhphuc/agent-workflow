#!/usr/bin/env sh
# Ghi dong based_on (hash ca file dau vao) vao frontmatter cua mot artifact.
#
#   aw based-on <thu-muc-feature> <artifact> <dau-vao>...
#   vd: aw based-on .agent-workflow/feat_x tdd.md spec.md open-questions.md
#
# Hash do MAY tinh, khong de agent tu ghi — agent chep sai mot ky tu la
# artifact bi bao loi thoi (hoac te hon, khong bao khi da loi thoi).
# Chay lai la ghi de khoi based_on cu; cac khoa frontmatter khac giu nguyen.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai based-on.sh \
  "0=ĐÃ GHI" \
  "2=SAI THAM SỐ HOẶC THIẾU FILE"
. "$HERE/lib/md.sh"

[ $# -ge 3 ] || { echo "Dùng: aw based-on <thư-mục-feature> <artifact> <đầu-vào>..." >&2; exit 2; }
DIR="$1"; ART="$2"; shift 2
[ -f "$DIR/$ART" ] || { echo "LỖI: không tìm thấy $DIR/$ART" >&2; exit 2; }

BO=""
for _in in "$@"; do
  [ -f "$DIR/$_in" ] || { echo "LỖI: không tìm thấy đầu vào $DIR/$_in" >&2; exit 2; }
  # "\n" dạng chữ: awk -v tự dịch escape; xuống dòng thật trong -v thì một số awk từ chối.
  BO="${BO}  - $_in@$(file_hash "$DIR/$_in")\\n"
done

TMP="$DIR/.$ART.tmp"
awk -v bo="$BO" '
  { sub(/\r$/, "") }
  NR==1 && $0=="---" { fm=1; print; printf "based_on:\n%s", bo; next }
  NR==1              { printf "---\nbased_on:\n%s---\n\n", bo; print; next }
  fm==1 && $0=="---" { fm=2; print; next }
  fm==1 && /^based_on:/          { bo_cu=1; next }
  fm==1 && bo_cu && /^[ \t]+-/   { next }
  fm==1                          { bo_cu=0; print; next }
  { print }
' "$DIR/$ART" > "$TMP" && mv "$TMP" "$DIR/$ART"
echo "Đã ghi based_on vào $DIR/$ART:"
printf '%b' "$BO"
