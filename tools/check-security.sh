#!/usr/bin/env sh
# Chay cac lenh quet bao mat cua repo va ghi security-results.md.
#
#   aw check security <thu-muc-feature>
#
# Giong test-results.md: script NAY TU CHAY lenh va TU GHI output that,
# kem dau van tay code (HEAD, Tree) va thoi diem — agent khong viet lai ket qua
# bang loi. aw check implement goi script nay; review chi kiem lai do moi theo Tree.
#
# Chan:  chua khai SECURITY_CMDS (khong khai = KHONG DAT, khong phai
#        "bo qua"); dong khai sai dang "<nhom>: <lenh>" hoac nhom la (nhom hop
#        le: secret sast sca other); bat ky lenh nao tra ma khac 0.
# Canh bao: thieu nhom secret / sast / sca — CI thuong chay du ba nhom; thieu
#        nhom nao thi loi do chi lo ra o pipeline. Nguoi xac nhan co chu y.
#
# Cau hinh: $AW_CONFIG/config.sh (xem lib/env.sh)
# Result: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
. "$HERE/lib/config.sh"
kq_khai check-security.sh \
  "0=PASS — mọi lệnh quét bảo mật xanh" \
  "1=FAIL — chưa khai lệnh, khai sai, hoặc có lệnh quét đỏ" \
  "2=NO INPUT — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/cross-check.sh"

DIR="${1:-.}"
nho_san "$DIR"  # nhớ rev-parse + quy ước hiệu lực ở shell chính (tốc độ)
KQ="$DIR/security-results.md"
CAUHINH=$(kc_cau_hinh "$DIR")

[ -d "$DIR" ] || { echo "LỖI: không có thư mục $DIR" >&2; exit 2; }
TOP=$(kc_top "$DIR") || { echo "LỖI: $DIR không nằm trong git repo" >&2; exit 2; }

SECURITY_CMDS=""
# shellcheck disable=SC1090
ch_nap "$CAUHINH"

n_loi=0
loi() { n_loi=$((n_loi + 1)); echo "  [ERROR] $1"; }

ds=$(kc_bm_dong "$SECURITY_CMDS")
if [ -z "$ds" ]; then
  # giữ: CAP-implement-03
  loi "Chưa khai báo SECURITY_CMDS trong $CAUHINH"
  echo ""
  echo "  Khai ĐÚNG lệnh, config và ngưỡng mà pipeline CI/CD chạy (secret scan, SAST, SCA),"
  echo "  mỗi dòng \"<nhóm>: <lệnh>\" — xem chú thích trong config.sh."
  echo "  Không khai thì điều kiện này là FAIL, không phải \"bỏ qua\": bỏ qua thì"
  echo "  lỗi bảo mật chỉ lộ ra khi pipeline chặn release."
  echo ""
  echo "FAIL."
  exit 1
fi

sai=$(printf '%s\n' "$ds" | awk -F '\t' '$1 == "!" { print $2 }')
if [ -n "$sai" ]; then
  while IFS= read -r l; do
    # giữ: CAP-implement-03
    loi "SECURITY_CMDS: dòng \"$l\" sai dạng — cần \"<nhóm>: <lệnh>\", nhóm ∈ {$(echo "$NHOM_BAO_MAT" | sed 's/ /, /g')}"
  done <<EOF
$sai
EOF
  echo ""
  echo "FAIL — $n_loi vi phạm."
  exit 1
fi

for g in secret sast sca; do
  # giữ: CAP-implement-03
  printf '%s\n' "$ds" | awk -F '\t' -v g="$g" '$1 == g { f = 1 } END { exit !f }' ||
    echo "  [WARN] Không có lệnh nhóm \"$g\" — CI có chạy thì khai vào đây, không thì lỗi chỉ lộ ra ở pipeline"
done

# Chạy từng lệnh ở gốc repo (CI cũng chạy ở gốc), ghi output thật.
TMP="${TMPDIR:-/tmp}/kqbm.$$"
kq_don 'rm -f "$TMP" "$TMP.than"'
: > "$TMP.than"
n_do=0
tab=$(printf '\t')
while IFS="$tab" read -r g l; do
  [ -n "$g" ] || continue
  echo ""
  echo "Chạy [$g]: $l"
  echo "────────────────────────────────────────────────────"
  (cd "$TOP" && sh -c "$l") > "$TMP" 2>&1
  m=$?
  cat "$TMP"
  echo "────────────────────────────────────────────────────"
  # giữ: CAP-implement-03
  if [ "$m" -eq 0 ]; then echo "[$g] GREEN"; else echo "[$g] RED (mã $m)"; n_do=$((n_do + 1)); loi "[$g] \`$l\` trả về mã $m"; fi
  {
    echo ""
    echo "## $g — \`$l\`"
    echo ""
    echo "- Mã thoát: \`$m\`"
    echo ""
    echo '```'
    cat "$TMP"
    echo '```'
  } >> "$TMP.than"
done <<EOF
$ds
EOF

if [ "$n_do" -eq 0 ]; then nhan="GREEN"; else nhan="RED"; fi
{
  echo "# Security scan"
  echo ""
  echo "> File này do \`check-security.sh\` ghi tự động."
  echo "> Đây là output thật của lệnh, không phải mô tả lại bằng lời."
  echo ""
  echo "- Result: **$nhan**"
  kc_dong_moi "$DIR"
  cat "$TMP.than"
} > "$KQ"
echo ""
echo "Đã ghi output thật vào $KQ"

echo ""
if [ "$n_loi" -gt 0 ]; then
  echo "FAIL — $n_loi lệnh quét đỏ."
  exit 1
fi
echo "PASS — mọi lệnh quét bảo mật xanh."
