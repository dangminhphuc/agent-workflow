#!/usr/bin/env sh
# Nhật ký của harness — biết harness hỏng ở đâu để đầu tư đúng chỗ.
#
#   aw journal [report]                         tổng hợp
#   aw journal add <layer> "<mô tả>" [--feature <thư-mục-feature>]
#
# Ba nguồn, lưu ở $AW_CONFIG/journal/ (dùng chung mọi worktree của bản clone,
# không commit):
#   checks.tsv    mỗi lần `aw check` chạy — engine tự ghi (AW_JOURNAL=0 để tắt)
#   failures.tsv  thất bại người/agent ghi tay, gắn một lớp:
#                   task      việc không được định nghĩa rõ (spec, plan thiếu)
#                   context   agent thiếu ngữ cảnh (quy tắc, tài liệu không có trong repo)
#                   env       môi trường sai (dependency, lệnh test, cấu hình)
#                   verify    thiếu kiểm chứng (test không bắt được lỗi, checker lọt)
#                   state     mất trạng thái giữa phiên (bàn giao thiếu)
#                   model     giới hạn thật của model — chỉ ghi sau khi đã loại bốn lớp trên
#   findings.tsv  finding [Blocker]/[Should fix] của review.md — `aw check review`
#                 ghi khi ĐẠT, theo "Category". Loại nào lặp ở nhiều việc là ứng
#                 viên để nâng thành luật máy kiểm (TEST_CMD, quy tắc repo).
#
# Nội bộ (engine / checker gọi, không dành cho người):
#   journal.sh _check <checker> <thư-mục-feature> <mã-thoát> <file-output>
#   journal.sh _findings <thư-mục-feature> <review.md>
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"

LOP_HOP_LE="task context env verify state model"
# Một loại finding lặp ở ít nhất chừng này việc khác nhau thì gợi ý nâng thành luật.
NGUONG_LAP=2

[ -n "${AW_CONFIG:-}" ] || { echo "LỖI: thiếu AW_CONFIG — gọi qua aw." >&2; exit 9; }
JD="$AW_CONFIG/journal"
TAB=$(printf '\t')

bay() { # <chuỗi> -> một dòng, không tab
  printf '%s' "$1" | tr '\t\r\n' '   ' | sed 's/  */ /g; s/^ //; s/ $//'
}
gio() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
viec() { basename "$(CDPATH= cd -- "$1" 2>/dev/null && pwd || echo "$1")"; }

# ---------------------------------------------------------------- nội bộ
case "${1:-}" in
  _check)
    # Không bao giờ làm hỏng lệnh check: mọi lỗi ở đây im lặng.
    [ $# -eq 5 ] || exit 0
    mkdir -p "$JD" 2>/dev/null || exit 0
    dau=$(grep -m1 -E '^[ \t]*\[LỖI\]' "$5" 2>/dev/null | sed 's/^[ \t]*\[LỖI\][ \t]*//')
    printf '%s\t%s\t%s\t%s\t%s\n' "$(gio)" "$(viec "$3")" "$2" "$4" "$(bay "$dau")" >> "$JD/checks.tsv" 2>/dev/null
    exit 0 ;;
  _findings)
    [ $# -eq 3 ] || exit 0
    mkdir -p "$JD" 2>/dev/null || exit 0
    v=$(viec "$2")
    moi=$(awk -v v="$v" -v t="$(gio)" '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      function xuat() { if (muc != "") print t "\t" v "\t" muc "\t" (cat == "" ? "-" : cat) "\t" ten; muc = "" }
      { sub(/\r$/, "") }
      /<!--/ && !/-->/ { cm = 1 }
      cm { if (/-->/) cm = 0; next }
      /^##[ \t]+Lens 3/ { trong = 1; next }
      /^##[ \t]/ && !/^###/ { if (trong) xuat(); trong = 0; next }
      trong && /^###[ \t]/ {
        xuat()
        if (match($0, /\[(Blocker|Should fix)\]/)) {
          muc = substr($0, RSTART + 1, RLENGTH - 2); ten = trim(substr($0, RSTART + RLENGTH)); gsub(/\t/, " ", ten); cat = ""
        }
        next
      }
      trong && muc != "" && /^[ \t]*-[ \t]*\**Category\**:/ { s = $0; sub(/^[^:]*:/, "", s); gsub(/[`*]/, "", s); cat = trim(s) }
      END { if (trong) xuat() }
    ' "$3")
    # Ghi lại phần của việc này (review chạy lại thì thay, không nhân đôi).
    { [ -f "$JD/findings.tsv" ] && awk -F'\t' -v v="$v" '$2 != v' "$JD/findings.tsv"
      [ -n "$moi" ] && printf '%s\n' "$moi"; } > "$JD/findings.tsv.$$" 2>/dev/null &&
      mv "$JD/findings.tsv.$$" "$JD/findings.tsv" 2>/dev/null
    # Gợi ý: loại của việc này đã gặp ở >= NGUONG_LAP việc.
    for c in $(printf '%s\n' "$moi" | cut -f4 | grep -v '^-$' | sort -u); do
      n=$(awk -F'\t' -v c="$c" '$4 == c { print $2 }' "$JD/findings.tsv" | sort -u | wc -l | tr -d ' ')
      [ "$n" -ge "$NGUONG_LAP" ] &&
        echo "  [GỢI Ý] Loại finding \"$c\" đã gặp ở $n việc — cân nhắc nâng thành luật máy kiểm (lệnh trong TEST_CMD, quy tắc repo). Xem: aw journal"
    done
    exit 0 ;;
esac

kq_khai journal \
  "0=XONG" \
  "2=SAI THAM SỐ — xem thông báo phía trên"

# ---------------------------------------------------------------- add
if [ "${1:-}" = add ]; then
  shift
  lop="${1:-}"; mota="${2:-}"; [ $# -ge 2 ] && shift 2
  ft=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --feature) [ -n "${2:-}" ] || { echo "LỖI: --feature cần thư mục." >&2; exit 2; }; ft=$(viec "$2"); shift 2 ;;
      *) echo "LỖI: tham số lạ \"$1\"." >&2; exit 2 ;;
    esac
  done
  case " $LOP_HOP_LE " in
    *" $lop "*) [ -n "$lop" ] || lop="?" ;;
    *) lop="?" ;;
  esac
  if [ "$lop" = "?" ]; then
    echo "Dùng: aw journal add <layer> \"<mô tả>\"   layer: $LOP_HOP_LE" >&2; exit 2
  fi
  [ -n "$(bay "$mota")" ] || { echo "LỖI: cần mô tả — agent làm sai gì, ở đâu, harness thiếu gì." >&2; exit 2; }
  [ -n "$ft" ] || ft=$(git -C "${AW_REPO:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/' '_')
  mkdir -p "$JD" || exit 2
  printf '%s\t%s\t%s\t%s\n' "$(gio)" "${ft:--}" "$lop" "$(bay "$mota")" >> "$JD/failures.tsv"
  echo "Đã ghi vào $JD/failures.tsv: [$lop] $(bay "$mota")"
  exit 0
fi

# ---------------------------------------------------------------- report
case "${1:-report}" in report) ;; *) echo "Dùng: aw journal [report] | aw journal add <layer> \"<mô tả>\"" >&2; exit 2 ;; esac

echo "Nhật ký harness — $JD"

echo ""
echo "Checker (aw check)"
if [ -s "$JD/checks.tsv" ]; then
  awk -F'\t' '
    { n[$3]++; if ($4 != 0) f[$3]++ }
    END { for (c in n) printf "  %-10s %4d lần chạy, %4d lần không đạt\n", c, n[c], f[c] + 0 }
  ' "$JD/checks.tsv" | sort
  top=$(awk -F'\t' '$4 != 0 && $5 != "" {
      s = $5; gsub(/YC-[0-9]+/, "YC-*", s); gsub(/T-[0-9]+/, "T-*", s); print $3 "\t" s }' "$JD/checks.tsv" |
    sort | uniq -c | sort -rn | head -5)
  if [ -n "$top" ]; then
    echo "  Vi phạm gặp nhiều nhất (vi phạm đầu tiên của mỗi lần không đạt):"
    printf '%s\n' "$top" | awk '{ n = $1; sub(/^[ \t]*[0-9]+[ \t]+/, ""); split($0, a, "\t"); printf "    %3d× [%s] %s\n", n, a[1], substr(a[2], 1, 110) }'
  fi
else
  echo "  (chưa có — engine ghi mỗi lần aw check chạy)"
fi

echo ""
echo "Thất bại theo lớp (aw journal add)"
if [ -s "$JD/failures.tsv" ]; then
  for l in $LOP_HOP_LE; do
    n=$(awk -F'\t' -v l="$l" '$3 == l' "$JD/failures.tsv" | wc -l | tr -d ' ')
    [ "$n" -gt 0 ] && printf '  %-8s %3d\n' "$l" "$n"
  done
  echo "  Gần nhất:"
  tail -n 5 "$JD/failures.tsv" | awk -F'\t' '{ printf "    %s  %-8s %s — %s\n", substr($1, 1, 10), $3, $2, substr($4, 1, 100) }'
else
  echo "  (chưa có — ghi khi agent làm hỏng: aw journal add <layer> \"<mô tả>\")"
fi

echo ""
echo "Finding của review theo loại (Category)"
if [ -s "$JD/findings.tsv" ]; then
  awk -F'\t' '$4 != "-" { k = $4; if (!((k, $2) in da)) { da[k, $2] = 1; v[k]++ } n[k]++ }
    END { for (k in n) printf "%d\t%d\t%s\n", v[k], n[k], k }' "$JD/findings.tsv" |
    sort -rn | while IFS="$TAB" read -r sv sn c; do
      if [ "$sv" -ge "$NGUONG_LAP" ]; then
        printf '  %-28s %2d việc, %2d finding  ← lặp lại: nâng thành luật máy kiểm\n' "$c" "$sv" "$sn"
      else
        printf '  %-28s %2d việc, %2d finding\n' "$c" "$sv" "$sn"
      fi
    done
  kc=$(awk -F'\t' '$4 == "-"' "$JD/findings.tsv" | wc -l | tr -d ' ')
  [ "$kc" -gt 0 ] && echo "  ($kc finding không có Category)"
else
  echo "  (chưa có — aw check review ghi khi ĐẠT)"
fi
exit 0
