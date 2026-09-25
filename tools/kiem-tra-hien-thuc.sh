#!/usr/bin/env sh
# Kiem tra dieu kien ra cua phase 03-implement.
#
#   sh tools/kiem-tra-hien-thuc.sh <thu-muc-artifact>
#
# Diem quan trong: script NAY TU CHAY lenh kiem thu va TU GHI output vao
# ket-qua-kiem-thu.md. Agent khong co co hoi viet lai ket qua bang loi hay
# bia mot dong "tat ca test da xanh". Do la ly do phase 03 khong de agent
# tu dan output.
#
# Ma thoat: 0 = dat, 1 = co vi pham, 2 = thieu file/cau hinh.

DIR="${1:-.agent-workflow}"
PLAN="$DIR/plan.md"
KQ="$DIR/ket-qua-kiem-thu.md"
CAUHINH="$DIR/.quy-trinh/cau-hinh.sh"

[ -f "$PLAN" ] || { echo "LỖI: không tìm thấy $PLAN" >&2; exit 2; }

LENH_KIEM_THU=""
[ -f "$CAUHINH" ] && . "$CAUHINH"

n_loi=0
loi() { n_loi=$((n_loi + 1)); echo "  [LỖI] $1"; }

# ---- 1. Phai khai bao lenh kiem thu ----
if [ -z "$LENH_KIEM_THU" ]; then
  echo ""
  loi "Chưa khai báo LENH_KIEM_THU trong $CAUHINH"
  echo ""
  echo "  Không khai báo thì điều kiện ra này là KHÔNG ĐẠT, không phải \"bỏ qua\"."
  echo "  Im lặng bỏ qua sẽ làm ràng buộc \"test xanh mới là xong\" mất tác dụng ở"
  echo "  đúng những repo cần nó nhất."
  echo ""
  echo "KHÔNG ĐẠT."
  exit 1
fi

# ---- 2. Khong con task dang lam do ----
dang_do=$(awk '
  { sub(/\r$/, "") }
  /^###[ \t]+T-/ { match($0, /T-[0-9]+/); cur = substr($0, RSTART, RLENGTH) }
  cur != "" && /Trạng thái:/ && /\[~\]/ { print cur }
' "$PLAN")

if [ -n "$dang_do" ]; then
  for t in $dang_do; do
    loi "$t còn ở trạng thái đang làm dở \`[~]\`"
  done
fi

# ---- 3. Chay that lenh kiem thu ----
echo ""
echo "Chạy lệnh kiểm thử: $LENH_KIEM_THU"
echo "────────────────────────────────────────────────────"
TMP="${TMPDIR:-/tmp}/kqkt.$$"
sh -c "$LENH_KIEM_THU" > "$TMP" 2>&1
ma_thoat=$?
cat "$TMP"
echo "────────────────────────────────────────────────────"
echo "Mã thoát: $ma_thoat"

# ---- 4. Ghi output THAT vao artifact ----
{
  echo "# Kết quả kiểm thử"
  echo ""
  echo "> File này do \`tools/kiem-tra-hien-thuc.sh\` ghi tự động."
  echo "> Đây là output thật của lệnh, không phải mô tả lại bằng lời."
  echo ""
  echo "- Lệnh: \`$LENH_KIEM_THU\`"
  echo "- Mã thoát: \`$ma_thoat\`"
  echo ""
  echo '```'
  cat "$TMP"
  echo '```'
} > "$KQ"
rm -f "$TMP"
echo ""
echo "Đã ghi output thật vào $KQ"

[ "$ma_thoat" -ne 0 ] && loi "Lệnh kiểm thử trả về mã $ma_thoat — chưa xanh thì chưa xong"

echo ""
if [ "$n_loi" -gt 0 ]; then
  echo "KHÔNG ĐẠT — $n_loi vi phạm."
  exit 1
fi
echo "ĐẠT — test xanh, không còn task dở."
