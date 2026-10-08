#!/usr/bin/env sh
# Kiem tra dieu kien ra cua phase 04-implement.
#
#   aw check implement <thu-muc-feature>
#
# Diem quan trong: script NAY TU CHAY lenh kiem thu va TU GHI output vao
# test-results.md. Agent khong co co hoi viet lai ket qua bang loi hay
# bia mot dong "tat ca test da xanh".
#
# Cung chay lenh quet bao mat (check-security.sh -> security-results.md). Ca hai
# file ket qua ghi dau van tay code (Tree) de review biet code co doi sau do khong.
#
# Chan:  dau vao khong qua check-plan.sh, chua khai lenh kiem thu,
#        test do, chua khai / khai sai SECURITY_CMDS hoac lenh quet do,
#        con task dang lam do [~] hoac chua lam [ ]; task [x] khong co bang
#        chung xanh trong task-results.md (aw task done) khop lenh Verify; file
#        con dau xung dot merge; file khai o rules_implement
#        (conventions.md) khong co hoac chua commit.
#        Theo loai viec (intake.md): bugfix thieu repro.md do; refactor/perf
#        xoa test cu; perf thieu so do truoc/sau; chore dung code production,
#        nang dependency khong khai, hoac dung file dependency ma SCA chua xanh.
#        ADR: D "Promote: adr" chua nang (aw adr promote), ADR lech D da duyet,
#        thu muc ADR sai hinh thuc (aw adr check).
#        Luat: YC "Promote: BR-…" chua nang (aw rule promote) hoac khoi luat lech YC da duyet.
# Canh bao (review se chan): YC chua co test, diff ngoai pham vi, artifact loi thoi,
#        test moi bi tat / chay rieng (.only, .skip… — skipped_test_regex),
#        loai viec lech tien to branch, refactor/perf sua test cu chua khai,
#        diem mu muc "chan review" chua tra loi; kien thuc ben co the loi thoi (diff dung
#        pham vi tai lieu module / ADR / luat ma tai lieu khong doi); luat active trong
#        pham vi diff chua co test covers.
# Luu y (khong chan): diff dung sensitive_code — review se can nguoi ra bao mat;
#        task kiem chung thu cong (aw task done --manual).
#
# Cau hinh: $AW_CONFIG/config.sh (xem lib/env.sh)
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
. "$HERE/lib/config.sh"
kq_khai check-implement.sh \
  "0=ĐẠT — được sang phase sau" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/commands.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/task.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/approval-tick.sh"
. "$HERE/lib/adr.sh"
. "$HERE/lib/rule.sh"
. "$HERE/lib/knowledge.sh"

DIR="${1:-.}"
PLAN="$DIR/plan.md"
KQ="$DIR/test-results.md"
CAUHINH=$(kc_cau_hinh "$DIR")

[ -f "$PLAN" ] || { echo "LỖI: không tìm thấy $PLAN" >&2; exit 2; }

TEST_CMD=""
# shellcheck disable=SC1090
ch_nap "$CAUHINH"

n_loi=0
loi() { n_loi=$((n_loi + 1)); echo "  [LỖI] $1"; }

# ---- 0. Dau vao ----
if ! sh "$HERE/check-plan.sh" "$DIR" >/dev/null 2>&1; then
  loi "Đầu vào chưa đạt: plan.md không qua aw check plan — chạy nó để xem chi tiết."
fi
qtl=$(kc_quy_tac_loi "$DIR" implement)
while IFS= read -r l; do [ -n "$l" ] && loi "$l"; done <<EOF
$qtl
EOF

# ---- 1. Phai khai bao lenh kiem thu ----
if [ -z "$TEST_CMD" ]; then
  echo ""
  loi "Chưa khai báo TEST_CMD trong $CAUHINH"
  echo ""
  echo "  Không khai báo thì điều kiện ra này là KHÔNG ĐẠT, không phải \"bỏ qua\"."
  echo "  Im lặng bỏ qua sẽ làm ràng buộc \"test xanh mới là xong\" mất tác dụng ở"
  echo "  đúng những repo cần nó nhất."
  echo ""
  echo "KHÔNG ĐẠT."
  exit 1
fi

# ---- 2. Moi task da xong, va xong bang may (aw task done) ----
tt=$( { tk_dang_do "$DIR"; tk_chua_xong "$DIR"; tk_thieu_bang_chung "$DIR"; } )
while IFS= read -r l; do [ -n "$l" ] && loi "$l"; done <<EOF
$tt
EOF

# ---- 3. Chay that lenh kiem thu ----
echo ""
echo "Chạy lệnh kiểm thử: $TEST_CMD"
echo "────────────────────────────────────────────────────"
TMP="${TMPDIR:-/tmp}/kqkt.$$"
sh -c "$TEST_CMD" > "$TMP" 2>&1
ma_thoat=$?
if [ "$ma_thoat" -eq 0 ]; then nhan_kt="XANH"; else nhan_kt="ĐỎ"; fi
cat "$TMP"
echo "────────────────────────────────────────────────────"
echo "Lệnh kiểm thử: $nhan_kt"

# ---- 4. Ghi output THAT vao artifact ----
{
  echo "# Kết quả kiểm thử"
  echo ""
  echo "> File này do \`check-implement.sh\` ghi tự động."
  echo "> Đây là output thật của lệnh, không phải mô tả lại bằng lời."
  echo ""
  echo "- Lệnh: \`$TEST_CMD\`"
  echo "- Kết quả: **$nhan_kt**"
  echo "- Mã thoát: \`$ma_thoat\` (bằng chứng thô của lệnh)"
  kc_dong_moi "$DIR"
  echo ""
  echo '```'
  cat "$TMP"
  echo '```'
} > "$KQ"
rm -f "$TMP"
echo ""
echo "Đã ghi output thật vào $KQ"

[ "$ma_thoat" -ne 0 ] && loi "Lệnh kiểm thử trả về mã $ma_thoat — chưa xanh thì chưa xong"

# ---- 4b. Quet bao mat — cung lenh, cung nguong voi CI ----
# Chay o day (khong o review): sua loi bao mat la viec cua implement; review
# chi kiem lai ket qua con moi theo Tree.
sh "$HERE/check-security.sh" "$DIR" 2>/dev/null
case $? in
  0) ;;
  1) loi "Quét bảo mật chưa đạt — xem output phía trên, security-results.md" ;;
  *) loi "Không chạy được quét bảo mật (aw check security $DIR để xem lý do)" ;;
esac

# ---- 4c. Trang thai sach — chinh xac nen CHAN ----
xd=$(kc_dau_xung_dot "$DIR")
while IFS= read -r l; do [ -n "$l" ] && loi "$l"; done <<EOF
$xd
EOF

# ---- 4d. ADR — D "Promote: adr" da nang dung noi dung D da duyet (chinh xac nen CHAN) ----
adl=$(adr_loi_viec "$DIR")
while IFS= read -r l; do [ -n "$l" ] && loi "ADR: $l"; done <<EOF
$adl
EOF
lvl=$(luat_loi_viec "$DIR")
while IFS= read -r l; do [ -n "$l" ] && loi "Luật: $l"; done <<EOF
$lvl
EOF

# ---- 5a. Luat theo loai viec — chinh xac nen CHAN ----
chan=$(kc_chan_theo_loai "$DIR")
if [ -n "$chan" ]; then
  echo ""
  while IFS= read -r l; do [ -n "$l" ] && loi "[$(kc_loai "$DIR")] $l"; done <<EOF
$chan
EOF
fi

# ---- 5b. Kiem cheo — chi canh bao ----
cb=$( { kc_test_yc "$DIR"; kc_pham_vi "$DIR"; kc_loi_thoi "$DIR"; kc_canh_bao_theo_loai "$DIR"; kc_diem_mu_mo "$DIR" "blocking" "review-blocking"; kc_test_bo_qua "$DIR"; kt_canh_bao "$DIR"; kt_luat_chua_test "$DIR"; } )
n_cb=0
if [ -n "$cb" ]; then
  echo ""
  n_cb=$(printf '%s\n' "$cb" | wc -l | tr -d ' ')
  printf '%s\n' "$cb" | while IFS= read -r l; do echo "  [CẢNH BÁO] $l"; done
  echo "  Cảnh báo không chặn implement, nhưng /aw-review sẽ CHẶN nếu còn."
  echo "  Mỗi cảnh báo đã ghi cách sửa — sửa luôn, đừng để tới review."
fi

# Code nhạy cảm: không phải vi phạm — báo sớm để kịp hẹn người rà bảo mật.
nc=$(kc_nhay_cam "$DIR")
if [ -n "$nc" ]; then
  echo ""
  echo "  [LƯU Ý] Diff đụng code nhạy cảm (sensitive_code): $(printf '%s\n' "$nc" | head -5 | tr '\n' ' ')"
  echo "  /aw-review sẽ cần một NGƯỜI rà bảo mật ghi tên vào \"Security reviewer\" của review.md."
fi

tc=$(tk_ds "$PLAN" | while IFS='|' read -r t s_ d v; do
  [ "$s_" = x ] && [ "$(tk_bc "$DIR/task-results.md" "$t" "Kiểm chứng")" = "thủ công" ] && printf '%s ' "$t"
done)
if [ -n "$tc" ]; then
  echo ""
  echo "  [LƯU Ý] Task kiểm chứng thủ công: $tc— người rà soát đọc bằng chứng trong task-results.md."
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
