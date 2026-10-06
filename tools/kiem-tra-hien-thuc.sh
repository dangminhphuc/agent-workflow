#!/usr/bin/env sh
# Kiem tra dieu kien ra cua phase 04-implement.
#
#   aw check implement <thu-muc-feature>
#
# Diem quan trong: script NAY TU CHAY lenh kiem thu va TU GHI output vao
# ket-qua-kiem-thu.md. Agent khong co co hoi viet lai ket qua bang loi hay
# bia mot dong "tat ca test da xanh".
#
# Chan:  dau vao khong qua kiem-tra-ke-hoach.sh, chua khai lenh kiem thu,
#        test do, con task dang lam do.
#        Theo loai viec (intake.md): bugfix thieu tai-hien.md do; refactor/perf
#        xoa test cu; perf thieu so do truoc/sau; chore dung code production
#        hoac nang dependency khong khai.
# Canh bao (review se chan): YC chua co test, diff ngoai pham vi, artifact loi thoi,
#        loai viec lech tien to branch, refactor/perf sua test cu chua khai,
#        diem mu muc "chan review" chua tra loi.
#
# Cau hinh: $AW_CONFIG/config.sh (xem lib/moi-truong.sh)
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai kiem-tra-hien-thuc.sh \
  "0=ĐẠT — được sang phase sau" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

DIR="${1:-.}"
PLAN="$DIR/plan.md"
KQ="$DIR/ket-qua-kiem-thu.md"
CAUHINH=$(kc_cau_hinh "$DIR")

[ -f "$PLAN" ] || { echo "LỖI: không tìm thấy $PLAN" >&2; exit 2; }

LENH_KIEM_THU=""
# shellcheck disable=SC1090
[ -f "$CAUHINH" ] && . "$CAUHINH"

n_loi=0
loi() { n_loi=$((n_loi + 1)); echo "  [LỖI] $1"; }

# ---- 0. Dau vao ----
if ! sh "$HERE/kiem-tra-ke-hoach.sh" "$DIR" >/dev/null 2>&1; then
  loi "Đầu vào chưa đạt: plan.md không qua aw check plan — chạy nó để xem chi tiết."
fi

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

for t in $dang_do; do
  loi "$t còn ở trạng thái đang làm dở \`[~]\`"
done

# ---- 3. Chay that lenh kiem thu ----
echo ""
echo "Chạy lệnh kiểm thử: $LENH_KIEM_THU"
echo "────────────────────────────────────────────────────"
TMP="${TMPDIR:-/tmp}/kqkt.$$"
sh -c "$LENH_KIEM_THU" > "$TMP" 2>&1
ma_thoat=$?
if [ "$ma_thoat" -eq 0 ]; then nhan_kt="XANH"; else nhan_kt="ĐỎ"; fi
cat "$TMP"
echo "────────────────────────────────────────────────────"
echo "Lệnh kiểm thử: $nhan_kt"

# ---- 4. Ghi output THAT vao artifact ----
{
  echo "# Kết quả kiểm thử"
  echo ""
  echo "> File này do \`kiem-tra-hien-thuc.sh\` ghi tự động."
  echo "> Đây là output thật của lệnh, không phải mô tả lại bằng lời."
  echo ""
  echo "- Lệnh: \`$LENH_KIEM_THU\`"
  echo "- Kết quả: **$nhan_kt**"
  echo "- Mã thoát: \`$ma_thoat\` (bằng chứng thô của lệnh)"
  echo ""
  echo '```'
  cat "$TMP"
  echo '```'
} > "$KQ"
rm -f "$TMP"
echo ""
echo "Đã ghi output thật vào $KQ"

[ "$ma_thoat" -ne 0 ] && loi "Lệnh kiểm thử trả về mã $ma_thoat — chưa xanh thì chưa xong"

# ---- 5a. Luat theo loai viec — chinh xac nen CHAN ----
chan=$(kc_chan_theo_loai "$DIR")
if [ -n "$chan" ]; then
  echo ""
  while IFS= read -r l; do [ -n "$l" ] && loi "[$(kc_loai "$DIR")] $l"; done <<EOF
$chan
EOF
fi

# ---- 5b. Kiem cheo — chi canh bao ----
cb=$( { kc_test_yc "$DIR"; kc_pham_vi "$DIR"; kc_loi_thoi "$DIR"; kc_canh_bao_theo_loai "$DIR"; kc_diem_mu_mo "$DIR" "chặn" "chặn review"; } )
n_cb=0
if [ -n "$cb" ]; then
  echo ""
  n_cb=$(printf '%s\n' "$cb" | wc -l | tr -d ' ')
  printf '%s\n' "$cb" | while IFS= read -r l; do echo "  [CẢNH BÁO] $l"; done
  echo "  Cảnh báo không chặn implement, nhưng /review sẽ CHẶN nếu còn."
  echo "  Xử lý: thêm test gắn tag, ghi \"Kiểm chứng thủ công\", ghi file vào \"Phát sinh\", chạy lại phase lỗi thời, hoặc trả lời điểm mù."
fi

echo ""
if [ "$n_loi" -gt 0 ]; then
  echo "KHÔNG ĐẠT — $n_loi vi phạm."
  exit 1
fi
if [ "$n_cb" -gt 0 ]; then
  echo "ĐẠT — test xanh, không còn task dở. Còn $n_cb cảnh báo chuyển cho review."
else
  echo "ĐẠT — test xanh, không còn task dở, không có cảnh báo."
fi
