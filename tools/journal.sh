#!/usr/bin/env sh
# Nhật ký của harness — biết harness hỏng ở đâu để đầu tư đúng chỗ.
#
#   aw journal [report]                         tổng hợp
#   aw journal add <layer> "<mô tả>" [--feature <thư-mục-feature>]
#
# Bốn nguồn, lưu ở $AW_CONFIG/journal/ (dùng chung mọi worktree của bản clone,
# không commit):
#   checks.tsv    mỗi lần `aw check` chạy — engine tự ghi (AW_JOURNAL=0 để tắt)
#   failures.tsv  thất bại người/agent ghi tay, gắn một lớp:
#                   task      việc không được định nghĩa rõ (spec, plan thiếu)
#                   context   agent thiếu ngữ cảnh (quy tắc, tài liệu không có trong repo)
#                   env       môi trường sai (dependency, lệnh test, cấu hình)
#                   verify    thiếu kiểm chứng (test không bắt được lỗi, checker lọt)
#                   state     mất trạng thái giữa phiên (bàn giao thiếu)
#                   model     giới hạn thật của model — chỉ ghi sau khi đã loại bốn lớp trên
#   approvals.tsv mỗi lần `aw approvals tick` ghi tick hộ người (/aw-approvals) — tick tay không có dòng
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
. "$HERE/lib/journal-version.sh"

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
  _phase)
    # Mốc bắt đầu phase (aw rules): việc suy như aw feature; ngoài việc thì không ghi. Không bao giờ làm hỏng lệnh rules.
    [ $# -eq 2 ] || exit 0
    mkdir -p "$JD" 2>/dev/null || exit 0
    dir=$(sh "$HERE/feature.sh" 2>/dev/null) || exit 0
    printf '%s\t%s\t%s\t%s\n' "$(gio)" "$(basename "$dir")" "$2" "$(jv_version "$HERE")" >> "$JD/phases.tsv" 2>/dev/null
    exit 0 ;;
  _check)
    # Không bao giờ làm hỏng lệnh check: mọi lỗi ở đây im lặng.
    [ $# -eq 5 ] || exit 0
    mkdir -p "$JD" 2>/dev/null || exit 0
    dau=$(grep -m1 -E '^[ \t]*\[LỖI\]' "$5" 2>/dev/null | sed 's/^[ \t]*\[LỖI\][ \t]*//')
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(gio)" "$(viec "$3")" "$2" "$4" "$(bay "$dau")" "$(jv_version "$HERE")" >> "$JD/checks.tsv" 2>/dev/null
    exit 0 ;;
  _findings)
    [ $# -eq 3 ] || exit 0
    mkdir -p "$JD" 2>/dev/null || exit 0
    v=$(viec "$2")
    moi=$(awk -v v="$v" -v t="$(gio)" -v j="$(jv_version "$HERE")" '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      function xuat() { if (muc != "") print t "\t" v "\t" muc "\t" (cat == "" ? "-" : cat) "\t" ten "\t" j; muc = "" }
      { sub(/\r$/, "") }
      /<!--/ && !/-->/ { cm = 1 }
      cm { if (/-->/) cm = 0; next }
      /^##[ \t]+Lens 3/ { trong = 1; next }
      /^##[ \t]/ && !/^###/ { if (trong) xuat(); trong = 0; next }
      trong && /^###[ \t]/ {
        xuat()
        if (match($0, /\[(Blocker|Should fix)\]/)) {
          muc = substr($0, RSTART + 1, RLENGTH - 2); ten = trim(substr($0, RSTART + RLENGTH)); gsub(/\t/, " ", ten); cat = ""
          if (match(ten, /^RVW-[0-9]+/)) { ten = trim(substr(ten, RLENGTH + 1)); sub(/^—[ \t]*/, "", ten) }  # mã chỉ có nghĩa trong một việc
        }
        next
      }
      trong && muc != "" && /^[ \t]*-[ \t]*\**Category\**:/ { s = $0; sub(/^[^:]*:/, "", s); gsub(/[`*]/, "", s); cat = trim(s) }
      END { if (trong) xuat() }
    ' "$3")
    # Ghi lại phần của việc này (review chạy lại thì thay, không nhân đôi).
    # Khối phải trả 0 khi không có finding mới, nếu không mv bị bỏ qua (dùng if, không dùng &&).
    { if [ -f "$JD/findings.tsv" ]; then awk -F'\t' -v v="$v" '$2 != v' "$JD/findings.tsv"; fi
      if [ -n "$moi" ]; then printf '%s\n' "$moi"; fi; } > "$JD/findings.tsv.$$" 2>/dev/null &&
      mv "$JD/findings.tsv.$$" "$JD/findings.tsv" 2>/dev/null || rm -f "$JD/findings.tsv.$$"
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
  printf '%s\t%s\t%s\t%s\t%s\n' "$(gio)" "${ft:--}" "$lop" "$(bay "$mota")" "$(jv_version "$HERE")" >> "$JD/failures.tsv"
  echo "Đã ghi vào $JD/failures.tsv: [$lop] $(bay "$mota")"
  exit 0
fi

# ---------------------------------------------------------------- export
# Một TSV gồm mọi dòng của bốn nguồn, thêm hai cột đầu: nguồn, máy — gom nhật ký nhiều máy để
# `aw journal report <file…>` tổng hợp (nhật ký nằm ở bản clone từng máy, không commit).
if [ "${1:-}" = export ]; then
  [ $# -eq 2 ] && [ -n "$2" ] || { echo "Dùng: aw journal export <file>" >&2; exit 2; }
  [ -d "$(dirname -- "$2")" ] || { echo "LỖI: thư mục của \"$2\" không có." >&2; exit 2; }
  may=$(bay "${AW_JOURNAL_MACHINE:-$(uname -n 2>/dev/null || echo may)}")
  {
    for s in checks failures approvals findings phases jobs; do
      if [ -f "$JD/$s.tsv" ]; then awk -v s="$s" -v m="$may" '{ print s "\t" m "\t" $0 }' "$JD/$s.tsv"; fi
    done
  } > "$2" || exit 2
  echo "Đã xuất $(wc -l < "$2" | tr -d ' ') dòng nhật ký (máy $may) vào $2"
  exit 0
fi

# ---------------------------------------------------------------- report
case "${1:-report}" in report) ;; *) echo "Dùng: aw journal [report [<file export>…]] | aw journal add <layer> \"<mô tả>\" | aw journal export <file>" >&2; exit 2 ;; esac
[ $# -gt 0 ] && shift

# --version <v>: chỉ tính dòng có version đó (? = engine không đọc được version).
RV=""
if [ "${1:-}" = --version ]; then
  [ -n "${2:-}" ] || { echo "LỖI: --version cần một version (vd 2026.10.31, hoặc ?)." >&2; exit 2; }
  RV=$2; shift 2
fi

NGUON=$JD; bo=0
if [ $# -gt 0 ] || [ -n "$RV" ]; then
  TD=$(mktemp -d "${TMPDIR:-/tmp}/aw-journal.XXXXXX" 2>/dev/null) || { TD="${TMPDIR:-/tmp}/aw-journal.$$"; mkdir "$TD" || exit 2; }
  kq_don 'rm -rf "$TD"'
  if [ $# -eq 0 ]; then
    # Không có file: nhật ký máy này đi qua đúng đường export, rồi đọc như file export.
    sh "$0" export "$TD/may.tsv" >/dev/null || exit 2
    set -- "$TD/may.tsv"
    NGUON="nhật ký máy này"
  else
    # Report trên file export: tách lại thành các nguồn trong thư mục tạm rồi tổng hợp như thường.
    for f in "$@"; do [ -f "$f" ] || { echo "LỖI: không có file \"$f\"." >&2; exit 2; }; done
    # Bỏ file trùng đường dẫn (truyền hai lần thì đếm một lần).
    da="|"; n=$#
    while [ "$n" -gt 0 ]; do
      f=$1; shift; n=$((n - 1))
      case "$da" in *"|$f|"*) ;; *) da="$da$f|"; set -- "$@" "$f" ;; esac
    done
    NGUON="gộp $# file export"
  fi
  JD="$TD/nhat-ky"; mkdir "$JD"
  # Dòng đủ cột (có version cuối) giữ nguyên; dòng cũ thiếu version thì thêm "?" — đều qua được lọc --version.
  bo=$(awk -F'\t' -v d="$JD" -v rv="$RV" '
    BEGIN { cot["checks"] = 6; cot["failures"] = 5; cot["approvals"] = 6; cot["findings"] = 6; cot["phases"] = 4; cot["jobs"] = 16 }
    ($1 in cot) && NF == cot[$1] + 2 { if (rv == "" || $NF == rv) { s = $1; sub(/^[^\t]*\t[^\t]*\t/, ""); print > (d "/" s ".tsv") }; next }
    ($1 in cot) && NF == cot[$1] + 1 { if (rv == "" || rv == "?") { s = $1; sub(/^[^\t]*\t[^\t]*\t/, ""); print ($0 "\t?") > (d "/" s ".tsv") }; next }
    { bo++ }
    END { print bo + 0 }' "$@")
fi

echo "harness journal — $NGUON"
if [ "$bo" -gt 0 ]; then echo "  (bỏ $bo dòng sai dạng)"; fi

echo ""
echo "Checker (aw check)"
if [ -s "$JD/checks.tsv" ]; then
  awk -F'\t' '
    { n[$3]++; if ($4 != 0) f[$3]++ }
    END { for (c in n) printf "  %-10s %4d lần chạy, %4d lần không đạt\n", c, n[c], f[c] + 0 }
  ' "$JD/checks.tsv" | sort
  top=$(awk -F'\t' '$4 != 0 && $5 != "" {
      s = $5; gsub(/REQ-[0-9]+/, "REQ-*", s); gsub(/TSK-[0-9]+/, "TSK-*", s); print $3 "\t" s }' "$JD/checks.tsv" |
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
