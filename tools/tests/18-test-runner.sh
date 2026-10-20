#!/usr/bin/env sh
# tools/run-tests.sh: cộng tổng các phần, thời gian từng phần, cảnh báo phần chậm.
# Chạy riêng: sh tools/tests/18-test-runner.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

nhom "tools/run-tests.sh"
# phan_gia <thư-mục> <tên> <giây-ngủ> — một phần test giả: ngủ rồi in dòng Tổng như ket_thuc
phan_gia() {
  printf 'sleep %s\necho ""\necho "Tổng: 1 ca — 1 đạt, 0 hỏng"\n' "$3" > "$1/$2.sh"
}
# Các phần nhanh đo được ≤ 1 giây, phần chậm ≥ 4 giây: gấp hơn 2 lần trung bình các phần
# còn lại dù đồng hồ làm tròn theo giây.
LECH="$TMP/lech"; mkdir -p "$LECH"
phan_gia "$LECH" 01-nhanh 0; phan_gia "$LECH" 02-nhanh 0; phan_gia "$LECH" 03-cham 4
AW_TEST_DIR="$LECH" AW_TEST_SLOW_MIN=1 sh "$T/run-tests.sh" > "$TMP/lech.out" 2>&1
dung "phần giả đều đạt → MỌI CA ĐẠT, tổng 3 ca" sh -c "grep -q '^Tổng: 3 ca — 3 đạt, 0 hỏng' '$TMP/lech.out' && grep -q '\[x\] MỌI CA ĐẠT' '$TMP/lech.out'"
dung "in thời gian từng phần, chậm nhất trước" sh -c "grep -q '^Thời gian từng phần (giây, chậm nhất trước): 03-cham [0-9]* · ' '$TMP/lech.out'"
dung "phần gấp hơn 2 lần trung bình các phần còn lại → cảnh báo nên tách" grep -q '^  CẢNH BÁO  03-cham chạy [0-9]*s.*nên tách' "$TMP/lech.out"
dung "phần nhanh không bị cảnh báo" sh -c "! grep -q 'CẢNH BÁO  0[12]-nhanh' '$TMP/lech.out'"
dung "cảnh báo không đổi kết quả" grep -q '\[x\] MỌI CA ĐẠT' "$TMP/lech.out"

AW_TEST_DIR="$LECH" sh "$T/run-tests.sh" > "$TMP/san.out" 2>&1
dung "phần chậm dưới ngưỡng tối thiểu (mặc định 30 giây) → không cảnh báo" sh -c "! grep -q 'CẢNH BÁO' '$TMP/san.out'"

DEU="$TMP/deu"; mkdir -p "$DEU"
phan_gia "$DEU" 01-a 2; phan_gia "$DEU" 02-b 2
AW_TEST_DIR="$DEU" AW_TEST_SLOW_MIN=1 sh "$T/run-tests.sh" > "$TMP/deu.out" 2>&1
dung "các phần chạy đều → không cảnh báo" sh -c "! grep -q 'CẢNH BÁO' '$TMP/deu.out'"

AW_TEST_DIR="$LECH" AW_TEST_SLOW_MIN=1 sh "$T/run-tests.sh" cham > "$TMP/mot.out" 2>&1
dung "chạy một phần → không so sánh, không cảnh báo" sh -c "grep -q '^Tổng: 1 ca' '$TMP/mot.out' && ! grep -q 'CẢNH BÁO' '$TMP/mot.out'"

mkdir -p "$TMP/rong"
ky_vong 2 "thư mục không có phần nào → SAI THAM SỐ, không chạy chuỗi glob như một phần" env AW_TEST_DIR="$TMP/rong" sh "$T/run-tests.sh"

ket_thuc
