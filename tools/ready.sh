#!/usr/bin/env sh
# Kiểm worktree đã sẵn sàng làm việc chưa — chạy ở đầu phiên mới.
#
#   aw ready <thư-mục-feature> [--no-test]
#
# Bốn câu hỏi, mỗi câu một nhóm dòng ✓ / ✗ / ·:
#   1. Cấu hình — conventions.md hợp lệ (aw conventions check: khoá, giá trị,
#      file quy tắc repo rules_*), config.sh có.
#   2. Test được — TEST_CMD đã khai và XANH trên code hiện tại. Base đỏ thì
#      mọi task sau không phân biệt được lỗi mình gây ra với lỗi có sẵn.
#      --no-test: không chạy (vd lệnh test rất lâu), chỉ kiểm đã khai.
#   3. Quét bảo mật — SECURITY_CMDS đã khai, đúng dạng (không chạy).
#   4. Tiến độ — artifact nào đã có, bước tiếp theo là gì, task nào làm tiếp.
#
# Không sửa gì. aw doctor kiểm phần cài đặt (wrapper, engine, exclude); lệnh này
# kiểm phần repo đích có chạy được quy trình hay không.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
. "$HERE/lib/config.sh"
kq_khai ready.sh \
  "0=SẴN SÀNG — làm theo dòng \"Bước tiếp\"" \
  "1=CHƯA SẴN SÀNG — sửa các dòng ✗ trước khi làm tiếp" \
  "2=SAI THAM SỐ"
. "$HERE/lib/md.sh"
. "$HERE/lib/commands.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/task.sh"

DIR=""; CHAY_TEST=1
while [ $# -gt 0 ]; do
  case "$1" in
    --no-test) CHAY_TEST=""; shift ;;
    -*) echo "LỖI: tham số lạ \"$1\"." >&2; exit 2 ;;
    *) [ -z "$DIR" ] || { echo "LỖI: thừa tham số \"$1\"." >&2; exit 2; }; DIR=$1; shift ;;
  esac
done
[ -n "$DIR" ] || { echo "Dùng: aw ready <thư-mục-feature> [--no-test]" >&2; exit 2; }

n_x=0
co()    { echo "  ✓ $1"; }
khong() { echo "  ✗ $1"; n_x=$((n_x + 1)); }
tin()   { echo "  · $1"; }

CONV=$(kc_conventions "$DIR"); CH=$(kc_cau_hinh "$DIR")
GOC="${AW_REPO:-$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)}"

# ---- 1. Cấu hình ----
echo "Cấu hình"
if [ -f "$CONV" ]; then
  # Một chỗ kiểm duy nhất: aw conventions check (khoá, giá trị, quy tắc repo).
  qu=$(sh "$HERE/check-conventions.sh" 2>/dev/null)
  if [ $? = 0 ]; then
    co "conventions.md hợp lệ (aw conventions check)"
  else
    printf '%s\n' "$qu" | grep '^  ✗ ' | while IFS= read -r l; do echo "  ✗ conventions.md: ${l#  ✗ }"; done
    c=$(printf '%s\n' "$qu" | grep -c '^  ✗ ')
    [ "$c" -gt 0 ] || khong "conventions.md: aw conventions check không chạy được — chạy tay để xem lỗi"
    n_x=$((n_x + c))
  fi
else
  khong "không có $CONV — chạy: aw init"
fi

TEST_CMD=""; SECURITY_CMDS=""; WORKTREE_SETUP_CMD=""
if [ -f "$CH" ]; then
  # shellcheck disable=SC1090
  ch_nap "$CH"
  ch_khoa_cu "$CH" | while IFS= read -r _k; do tin "config.sh còn tên khoá cũ $_k — vẫn đọc được; đổi tên khi không còn việc nào ghim engine trước 2026.10.21"; done
else
  khong "không có $CH — chạy: aw init"
fi

# ---- 2. Test được ----
echo "Test được"
[ -n "$WORKTREE_SETUP_CMD" ] && tin "worktree mới cần chuẩn bị trước (không tự chạy): $WORKTREE_SETUP_CMD"
if [ -z "$TEST_CMD" ]; then
  khong "TEST_CMD chưa khai trong $CH — /aw-implement sẽ KHÔNG ĐẠT"
elif [ -z "$CHAY_TEST" ]; then
  tin "TEST_CMD đã khai, không chạy (--no-test): $TEST_CMD"
else
  TMP="${TMPDIR:-/tmp}/aw-ready.$$"
  kq_don 'rm -f "$TMP"'
  (cd "$GOC" && sh -c "$TEST_CMD") > "$TMP" 2>&1
  ma=$?
  if [ "$ma" -eq 0 ]; then
    co "TEST_CMD XANH trên code hiện tại: $TEST_CMD"
  else
    khong "TEST_CMD ĐỎ (mã $ma) trên code hiện tại — chưa bắt đầu sửa gì mà đã đỏ: thiếu chuẩn bị môi trường (WORKTREE_SETUP_CMD) hoặc base đang hỏng. Báo người; không sửa/tắt test có sẵn"
    echo "    ── 20 dòng cuối ──"
    tail -n 20 "$TMP" | sed 's/^/    /'
  fi
fi

# ---- 3. Quét bảo mật ----
echo "Quét bảo mật"
if [ -z "$(kc_bm_dong "$SECURITY_CMDS")" ]; then
  khong "SECURITY_CMDS chưa khai trong $CH — /aw-implement sẽ KHÔNG ĐẠT"
else
  sai=$(kc_bm_dong "$SECURITY_CMDS" | awk -F'\t' '$1 == "!" { print $2 }')
  if [ -n "$sai" ]; then
    printf '%s\n' "$sai" | while IFS= read -r l; do echo "  ✗ dòng sai dạng \"<nhóm>: <lệnh>\": $l"; done
    n_x=$((n_x + $(printf '%s\n' "$sai" | grep -c .)))
  else
    co "SECURITY_CMDS: $(kc_bm_dong "$SECURITY_CMDS" | cut -f1 | sort -u | tr '\n' ' ' | sed 's/ $//')"
  fi
fi

# ---- 4. Tiến độ ----
echo "Tiến độ ($DIR)"
co_f() { [ -f "$DIR/$1" ]; }
loai=$(kc_loai "$DIR")
for f in intake.md spec.md open-questions.md tdd.md plan.md task-results.md test-results.md security-results.md review.md; do
  co_f "$f" && tin "có $f"
done
if ! co_f intake.md; then buoc="/aw-intake — chưa có intake.md"
elif ! co_f spec.md; then buoc="/aw-spec"
elif [ "$loai" != chore ] && ! co_f tdd.md; then buoc="/aw-design"
elif ! co_f plan.md; then buoc="/aw-plan"
else
  ds=$(tk_ds "$DIR/plan.md")
  con=$(printf '%s\n' "$ds" | awk -F'|' 'NF && $2 != "x"' | wc -l | tr -d ' ')
  tong=$(printf '%s\n' "$ds" | grep -c .)
  if [ "$con" -gt 0 ]; then
    tiep=$(tk_tiep "$DIR/plan.md")
    tin "task: $((tong - con))/$tong xong"
    if [ -n "$tiep" ]; then buoc="/aw-implement — task tiếp: $tiep (aw task next $DIR)"
    else buoc="/aw-implement — còn task chưa xong nhưng đều chờ phụ thuộc; xem \"Depends on\" trong plan.md"; fi
  elif ! co_f review.md; then buoc="aw check implement, rồi /aw-review"
  else buoc="/aw-review (đã có review.md — chạy lại nếu code đổi) hoặc /aw-ship"
  fi
fi
echo ""
echo "Bước tiếp: $buoc"

echo ""
if [ "$n_x" -gt 0 ]; then
  echo "CHƯA SẴN SÀNG — $n_x mục ✗."
  exit 1
fi
echo "SẴN SÀNG."
