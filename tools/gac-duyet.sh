#!/usr/bin/env sh
# Gác ô duyệt — hook của agent (Claude Code: PreToolUse / PostToolUse) để agent
# không tick được ô "Approved by human" trong spec.md / tdd.md.
#
#   aw guard pre    trước mỗi lệnh ghi của agent: ghi dấu duyệt cho ô người vừa
#                   tick (chốt nội dung người đã thấy), đặt mốc "pre đã chạy"
#   aw guard post   sau lệnh đó: ô nào được tick mà chưa có dấu duyệt — tức tick
#                   trong lúc lệnh của agent chạy — thì bỏ tick; ô có dấu duyệt
#                   mà nội dung đã đổi cũng bỏ tick. Có bỏ tick thì báo agent.
#
# Cấu hình hook: adapters/claude-code/README.md mục "Hook gác ô duyệt". pre và
# post phải cùng matcher: post chỉ coi tick chưa dấu là của agent khi thấy mốc
# của pre — pre không chạy thì post không bỏ tick của ai.
#
# Giới hạn: agent cố tình tự tính hash rồi ghi dấu giả thì hook không phân biệt
# được; người tick đúng lúc một lệnh dài của agent đang chạy sẽ bị bỏ tick (tick lại).
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).
# Mã 2 là mã "chặn" của hook Claude Code: stderr được đưa lại cho agent đọc.

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai gac-duyet.sh \
  "0=KHÔNG CÓ GÌ PHẢI CHẶN" \
  "2=ĐÃ BỎ TICK — chỉ người được tick ô duyệt; xem thông báo phía trên" \
  "3=SAI THAM SỐ"
. "$HERE/lib/moi-truong.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/duyet.sh"
mt_dat

PHA="${1:-}"
case "$PHA" in pre|post) ;; *) echo "Dùng: aw guard pre|post" >&2; exit 3 ;; esac
[ -d "$MT_ART" ] || exit 0
MOC="$MT_ART/.gac-duyet-pre"

# cac_file -> mọi spec.md / tdd.md của các việc trong worktree này
cac_file() {
  for _d in "$MT_ART"/*/; do
    for _f in spec.md tdd.md; do [ -f "$_d$_f" ] && printf '%s\n' "$_d$_f"; done
  done
}

if [ "$PHA" = pre ]; then
  cac_file | while IFS= read -r f; do
    dy_dong_dau "$f" "$(basename "$f" .md)" >/dev/null 2>&1
  done
  : > "$MOC" 2>/dev/null
  exit 0
fi

# ---- post ----
CO_PRE=0; [ -f "$MOC" ] && { CO_PRE=1; rm -f "$MOC"; }
BAO="${TMPDIR:-/tmp}/aw-gac.$$"; : > "$BAO"
kq_don 'rm -f "$BAO"'

cac_file | while IFS= read -r f; do
  loai=$(basename "$f" .md); ds=""
  tuong_doi=${f#"$MT_REPO"/}
  dy_quet "$f" "$loai" | {
    while IFS='|' read -r k khoa tick dau nr _ml; do
      [ "$k" = O ] && [ "$tick" = 1 ] || continue
      if [ -z "$dau" ]; then
        [ "$CO_PRE" = 1 ] || continue
        ly_do="được tick trong lúc lệnh của agent chạy"
      elif [ "$dau" != "$(dy_hash "$f" "$loai" "$khoa")" ]; then
        ly_do="nội dung đổi sau khi người duyệt"
      else continue; fi
      ds="$ds $nr"
      printf '  %s dòng %s (%s): %s\n' "$tuong_doi" "$nr" "$khoa" "$ly_do" >> "$BAO"
    done
    # shellcheck disable=SC2086
    [ -n "$ds" ] && dy_bo_tick "$f" $ds
    dy_dong_dau "$f" "$loai" >/dev/null
  }
done

[ -s "$BAO" ] || exit 0
{
  echo "ĐÃ BỎ TICK ô duyệt — chỉ người được tick, và tick chỉ còn giá trị khi nội dung chưa đổi:"
  cat "$BAO"
  echo "Agent KHÔNG tick lại. Báo người: mở file, đọc lại phần đó rồi tự tick."
  echo "(Người vừa tick đúng lúc lệnh đang chạy thì chỉ cần tick lại.)"
} >&2
exit 2
