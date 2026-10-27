#!/usr/bin/env sh
# Test hoi quy cho cac cong chan va cho adapter.
#
#   sh tools/run-tests.sh                     # gọn: chỉ in ca hỏng (kèm nhóm) + tổng
#   AW_TEST_VERBOSE=1 sh tools/run-tests.sh   # in từng ca
#   sh tools/run-tests.sh review ship         # chỉ các phần có tên chứa "review" hoặc "ship"
#   AW_TEST_JOBS=1 sh tools/run-tests.sh      # số phần chạy cùng lúc (mặc định: số CPU)
#   AW_TEST_SLOW_MIN=10 sh tools/run-tests.sh # ngưỡng giây để cảnh báo phần chậm (mặc định 30)
#   AW_TEST_DIR=<thư-mục>                     # thư mục chứa các phần (mặc định tools/tests; dùng cho test của chính file này)
#
# Repo nay ban cac cong chan; neu chinh cong chan hong ma khong ai biet thi
# ca quy trinh tro thanh trang tri. Moi ca kiem CA HAI CHIEU: chan dung luc
# va cho qua dung luc. Mot checker luon tra 0 con te hon khong co checker.
#
# Ca kiểm nằm trong tools/tests/NN-<tên>.sh, helper + fixture trong tools/tests/lib.sh.
# Mỗi phần tự dựng fixture, có thư mục tạm riêng, nên các phần chạy song song;
# script này chỉ chia phần cho các luồng rồi cộng dòng "Tổng:" của từng phần.
# Phần dừng giữa chừng (không in "Tổng:") tính là hỏng.

set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP="${TMPDIR:-/tmp}/aw-run-tests.$$"
mkdir -p "$TMP"
. "$ROOT/tools/lib/result.sh"
kq_khai run-tests.sh \
  "0=ALL PASS" \
  "1=FAILED CASES — xem các dòng FAIL phía trên" \
  "2=BAD ARGS — không phần test nào khớp tên đã cho"
kq_don 'rm -rf "$TMP"'
TD="${AW_TEST_DIR:-$ROOT/tools/tests}"

DS=""
for f in "$TD"/[0-9]*.sh; do
  [ -f "$f" ] || continue
  p=$(basename "$f" .sh)
  if [ $# -gt 0 ]; then
    chon=""
    for a in "$@"; do case "$p" in *"$a"*) chon=1 ;; esac; done
    [ -n "$chon" ] || continue
  fi
  DS="$DS $p"
done
if [ -z "$DS" ]; then
  echo "Không phần nào khớp: $*. Các phần: $(ls "$TD" | sed -n 's/^\([0-9].*\)\.sh$/\1/p' | tr '\n' ' ')" >&2
  exit 2
fi

LUONG=${AW_TEST_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}
case "$LUONG" in ''|*[!0-9]*|0) LUONG=2 ;; esac

# lam — một luồng: lần lượt giành phần chưa ai lấy (mkdir là thao tác nguyên tử) rồi chạy
lam() {
  for p in $DS; do
    mkdir "$TMP/lay.$p" 2>/dev/null || continue
    bd=$(date +%s 2>/dev/null)
    sh "$TD/$p.sh" > "$TMP/$p.log" 2>&1
    echo "$?" > "$TMP/$p.ma"
    kt=$(date +%s 2>/dev/null)
    # date không có %s (hiếm) → bỏ đo thời gian, không ảnh hưởng kết quả
    case "$bd$kt" in ''|*[!0-9]*) ;; *) echo "$((kt - bd))" > "$TMP/$p.giay" ;; esac
  done
}
i=0
while [ "$i" -lt "$LUONG" ]; do lam & i=$((i + 1)); done
wait

n_ok=0; n_fail=0; n_phan=0
for p in $DS; do
  n_phan=$((n_phan + 1))
  log="$TMP/$p.log"; ma=$(cat "$TMP/$p.ma" 2>/dev/null)
  tong=$(sed -n 's/^Tổng: [0-9]* ca — \([0-9]*\) đạt, \([0-9]*\) hỏng$/\1 \2/p' "$log" 2>/dev/null | tail -1)
  # Output của phần, trừ dòng Tổng và khối Result sau nó; bỏ dòng trống ở cuối.
  ra=$(awk '/^Tổng: [0-9]+ ca — / { exit } { print }' "$log" 2>/dev/null)
  if [ -n "${AW_TEST_VERBOSE:-}" ]; then printf '\n[tests/%s.sh]\n' "$p"; fi
  if [ -n "$ra" ]; then printf '%s\n' "$ra"; fi
  dat=${tong% *}; hong=${tong#* }
  if [ -z "$tong" ] || { [ "$ma" != 0 ] && [ "$ma" != 1 ]; } || { [ "$ma" = 0 ] && [ "$hong" != 0 ]; } || { [ "$ma" = 1 ] && [ "$hong" = 0 ]; }; then
    n_fail=$((n_fail + 1))
    printf '  FAIL  tests/%s.sh dừng giữa chừng (mã thoát %s) — xem output phía trên\n' "$p" "${ma:-?}"
    continue
  fi
  n_ok=$((n_ok + dat)); n_fail=$((n_fail + hong))
  if [ "$hong" != 0 ]; then printf '  → chạy lại riêng phần này: sh tools/tests/%s.sh\n' "$p"; fi
done

# Thời gian từng phần. Các phần chạy song song nên phần chậm hơn hẳn các phần khác kéo dài cả
# bộ test: cảnh báo để tách (AGENTS.md § Verify). Chỉ cảnh báo, không đổi kết quả.
CHAM_MIN=${AW_TEST_SLOW_MIN:-30}
case "$CHAM_MIN" in ''|*[!0-9]*) CHAM_MIN=30 ;; esac
for p in $DS; do
  if [ -f "$TMP/$p.giay" ]; then printf '%s %s\n' "$(cat "$TMP/$p.giay")" "$p"; fi
done | sort -n -r > "$TMP/giay"
if [ -s "$TMP/giay" ]; then
  echo ""
  awk -v min="$CHAM_MIN" '
    { g[NR] = $1; t[NR] = $2; s += $1 }
    END {
      d = "Thời gian từng phần (giây, chậm nhất trước):"
      for (i = 1; i <= NR; i++) d = d (i == 1 ? " " : " · ") t[i] " " g[i]
      print d
      if (NR < 2) exit
      for (i = 1; i <= NR; i++) {
        tb = (s - g[i]) / (NR - 1)
        if (g[i] >= min && g[i] > 2 * tb)
          printf "  WARN  %s chạy %ds, gấp hơn 2 lần trung bình các phần còn lại (%.0fs) — nên tách (AGENTS.md § Verify)\n", t[i], g[i], tb
      }
    }' "$TMP/giay"
fi

echo ""
echo "─────────────────────────────────────────"
printf 'Tổng: %d ca — %d đạt, %d hỏng (%d phần, %d luồng)\n' "$((n_ok + n_fail))" "$n_ok" "$n_fail" "$n_phan" "$LUONG"
[ "$n_fail" -gt 0 ] && exit 1
exit 0
