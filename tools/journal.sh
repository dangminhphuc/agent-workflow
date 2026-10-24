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
#   journal.sh _phase <thư-mục-worktree> <feature> <phase>   (aw feature --phase; ghi phases.tsv)
#   journal.sh _turn <begin|end|sub>   (hook Claude Code, payload JSON ở stdin; ghi turns.tsv)
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

. "$HERE/lib/progress.sh"   # bay, may_nay
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
  _phase)
    # Mốc bắt đầu phase. Im lặng, luôn thoát 0.
    [ $# -eq 4 ] || exit 0
    [ "${AW_JOURNAL:-1}" != 0 ] || exit 0
    mkdir -p "$JD" 2>/dev/null || exit 0
    printf '%s\t%s\t%s\t%s\n' "$(gio)" "$(viec "$2")" "$(bay "$3")" "$(bay "$4")" >> "$JD/phases.tsv" 2>/dev/null
    exit 0 ;;
  _turn)
    # Lượt và token từ hook Claude Code (UserPromptSubmit/Stop/SubagentStop; payload JSON ở stdin).
    # Không in gì ra stdout, luôn thoát 0, mọi lỗi im lặng.
    {
      [ "${AW_JOURNAL:-1}" != 0 ] || exit 0
      loai="${2:-}"
      case "$loai" in begin|end|sub) ;; *) exit 0 ;; esac
      pl=$(cat)
      trich() { printf '%s' "$pl" | sed -n 's/.*"'"$1"'"[ ]*:[ ]*"\([^"]*\)".*/\1/p' | head -n 1; }
      sess=$(trich session_id | tr -c 'A-Za-z0-9_\n-' '_')
      cwd=$(trich cwd)
      tr_path=$(trich transcript_path)
      [ -n "$sess" ] && [ -n "$tr_path" ] || exit 0
      if [ "$loai" = sub ]; then
        tr_path=$(trich agent_transcript_path)
        [ -n "$tr_path" ] || exit 0
      fi
      [ -f "$tr_path" ] || exit 0
      mkdir -p "$JD/.turn" || exit 0
      st="$JD/.turn/$sess"
      b_iso=""; b_epoch=""; off=0
      if [ -f "$st" ]; then
        # cut, không read: tab là IFS-space, hai ô rỗng đầu dòng sẽ bị gộp mất.
        b_iso=$(head -n 1 "$st" | cut -f1); b_epoch=$(head -n 1 "$st" | cut -f2); off=$(head -n 1 "$st" | cut -f3)
      fi
      case "$off" in ''|*[!0-9]*) off=0 ;; esac
      now=$(date -u +%s)
      if [ "$loai" = begin ]; then
        printf '%s\t%s\t%s\n' "$(gio)" "$now" "$off" > "$st"
        exit 0
      fi
      if [ "$loai" = sub ]; then off=0; b_iso=""; b_epoch=""; fi
      size=$(wc -c < "$tr_path" | tr -d ' ')
      [ "$size" -ge "$off" ] || off=0
      tokens=$(tail -c +$((off + 1)) "$tr_path" | awk '
        function trich(re) { if (match($0, re)) return substr($0, RSTART, RLENGTH); return "" }
        function so(k,   t) { t = trich("\"" k "\"[ ]*:[ ]*[0-9]+"); if (t == "") return 0; sub(/^[^:]*:[ ]*/, "", t); return t + 0 }
        /"type"[ ]*:[ ]*"assistant"/ {
          id = trich("\"id\"[ ]*:[ ]*\"msg_[^\"]*\"")
          if (id != "" && (id in thay)) next
          thay[id] = 1
          vao += so("input_tokens"); ra += so("output_tokens")
          cd += so("cache_read_input_tokens"); cg += so("cache_creation_input_tokens"); co = 1
        }
        END { if (co) print vao "\t" ra "\t" cd "\t" cg; else print "\t\t\t" }')
      wt=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)
      w=-; ft=-; ph=-
      if [ -n "$wt" ]; then
        w=$(viec "$wt")
        if [ -f "$JD/phases.tsv" ]; then
          dong=$(awk -F'\t' -v w="$w" '$2 == w { d = $0 } END { print d }' "$JD/phases.tsv")
          if [ -n "$dong" ]; then
            ft=$(printf '%s' "$dong" | cut -f3); ph=$(printf '%s' "$dong" | cut -f4)
          fi
        fi
      fi
      if [ "$loai" = sub ]; then
        kind=subagent; giay=0; t0=$(gio)
      else
        kind=main; giay=""; t0="$b_iso"
        if [ -n "$b_epoch" ] && [ "$now" -ge "$b_epoch" ] 2>/dev/null; then giay=$((now - b_epoch)); fi
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$t0" "$(gio)" "$w" "${ft:--}" "${ph:--}" "$sess" "$kind" "$giay" "$tokens" >> "$JD/turns.tsv"
      if [ "$loai" = end ]; then printf '\t\t%s\n' "$size" > "$st"; fi
    } >/dev/null 2>&1
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
  printf '%s\t%s\t%s\t%s\n' "$(gio)" "${ft:--}" "$lop" "$(bay "$mota")" >> "$JD/failures.tsv"
  echo "Đã ghi vào $JD/failures.tsv: [$lop] $(bay "$mota")"
  exit 0
fi

# ---------------------------------------------------------------- export
# Một TSV gồm mọi dòng của sáu nguồn, thêm hai cột đầu: nguồn, máy — gom nhật ký nhiều máy để
# `aw journal report <file…>` tổng hợp (nhật ký nằm ở bản clone từng máy, không commit).
if [ "${1:-}" = export ]; then
  [ $# -eq 2 ] && [ -n "$2" ] || { echo "Dùng: aw journal export <file>" >&2; exit 2; }
  [ -d "$(dirname -- "$2")" ] || { echo "LỖI: thư mục của \"$2\" không có." >&2; exit 2; }
  may=$(may_nay)
  {
    for s in checks failures approvals findings phases turns; do
      if [ -f "$JD/$s.tsv" ]; then awk -v s="$s" -v m="$may" '{ print s "\t" m "\t" $0 }' "$JD/$s.tsv"; fi
    done
  } > "$2" || exit 2
  echo "Đã xuất $(wc -l < "$2" | tr -d ' ') dòng nhật ký (máy $may) vào $2"
  exit 0
fi

# ---------------------------------------------------------------- report
case "${1:-report}" in report) ;; *) echo "Dùng: aw journal [report [<file export>…]] | aw journal add <layer> \"<mô tả>\" | aw journal export <file>" >&2; exit 2 ;; esac
[ $# -gt 0 ] && shift

NGUON=$JD; bo=0
if [ $# -gt 0 ]; then
  # Report trên file export: tách lại thành sáu nguồn trong thư mục tạm rồi tổng hợp như thường.
  for f in "$@"; do [ -f "$f" ] || { echo "LỖI: không có file \"$f\"." >&2; exit 2; }; done
  # Bỏ file trùng đường dẫn (truyền hai lần thì đếm một lần).
  da="|"; n=$#
  while [ "$n" -gt 0 ]; do
    f=$1; shift; n=$((n - 1))
    case "$da" in *"|$f|"*) ;; *) da="$da$f|"; set -- "$@" "$f" ;; esac
  done
  JD=$(mktemp -d "${TMPDIR:-/tmp}/aw-journal.XXXXXX" 2>/dev/null) || { JD="${TMPDIR:-/tmp}/aw-journal.$$"; mkdir "$JD" || exit 2; }
  kq_don 'rm -rf "$JD"'
  bo=$(awk -F'\t' -v d="$JD" '
    BEGIN { cot["checks"] = 5; cot["failures"] = 4; cot["approvals"] = 5; cot["findings"] = 5; cot["phases"] = 4; cot["turns"] = 12 }
    ($1 in cot) && NF == cot[$1] + 2 {
      s = $1; m = $2; sub(/^[^\t]*\t[^\t]*\t/, "")
      # turns: gắn máy vào worktree để hai máy trùng tên worktree vẫn là hai việc
      if (s == "turns") { n = split($0, a, "\t"); a[3] = m "/" a[3]; $0 = a[1]; for (i = 2; i <= n; i++) $0 = $0 "\t" a[i] }
      print > (d "/" s ".tsv"); next }
    { bo++ }
    END { print bo + 0 }' "$@")
  NGUON="gộp $# file export"
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

echo ""
echo "Thời gian và token theo phase"
if [ -s "$JD/turns.tsv" ]; then
  # active mỗi việc = tổng seconds lượt main; trung vị trên các việc; token cộng mọi lượt.
  awk -F'\t' "$TD_AWK_DD"'
    $5 == "-" || $5 == "" { next }
    {
      p = $5; j = $3 "|" $4
      if (!(p in vt)) { vt[p] = 1; ord[++np] = p }
      if (!((p, j) in jv)) { jv[p, j] = 1; nj[p]++; ja[p, nj[p]] = j }
      if ($7 == "main" && $8 ~ /^[0-9]+$/) ac[p, j] += $8
      if ($9 ~ /^[0-9]+$/) vao[p] += $9
      if ($10 ~ /^[0-9]+$/) ra[p] += $10
    }
    END {
      for (i = 1; i <= np; i++) {
        p = ord[i]; n = nj[p]; tong = 0
        for (k = 1; k <= n; k++) { v[k] = ac[p, ja[p, k]] + 0; tong += v[k] }
        for (k = 2; k <= n; k++) { x = v[k]; q = k - 1; while (q >= 1 && v[q] > x) { v[q + 1] = v[q]; q-- } v[q + 1] = x }
        if (n % 2) tv = v[(n + 1) / 2]; else tv = int((v[n / 2] + v[n / 2 + 1]) / 2)
        printf "  %-10s %3d việc, active tổng %s, trung vị %s, token vào %s / ra %s\n", p, n, td_tg(tong), td_tg(tv), td_tk(vao[p] + 0), td_tk(ra[p] + 0)
      }
    }' "$JD/turns.tsv"
else
  echo "  chưa có dữ liệu"
fi
exit 0
