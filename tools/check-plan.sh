#!/usr/bin/env sh
# Kiểm tra điều kiện ra của phase 03-plan.
#
#   aw check plan <thư-mục-feature>
#
# Chặn:
#   - Đầu vào: tdd.md không qua check-design.sh (entry check = checker phase trước).
#   - Đầu vào (không có design: chore, hoặc spec "Design: skip"): spec không qua check-spec.sh,
#     spec chưa duyệt, còn điểm mù "Blocking: blocking" chưa trả lời.
#   - Đầu vào: còn DEC-xxx chưa được người tick duyệt (hoặc đổi sau khi tick). plan và implement không có người —
#     chúng chỉ được thực thi những gì người đã duyệt.
#   - Kiểm HAI CHIỀU phủ REQ:
#       xuôi  — mọi task trỏ về mã REQ có thật trong spec.md   (bắt task thừa)
#       ngược — mọi mã REQ được task phủ, hoặc nằm ở "Deferred" (bắt yêu cầu sót)
#   - Task thiếu "Verify", "Expected files"; "Based on: DEC-xxx" trỏ về DEC không có.
#   - File khai ở rules_plan (conventions.md) không có hoặc chưa commit.
#   - DEC-xxx "Promote: adr" không có task "Based on" nó mà "Expected files" gồm thư mục ADR.
#   - REQ "Promote: BR-…" không có task phủ nó mà "Expected files" gồm file luật đích.
# Cảnh báo: artifact lỗi thời; REQ "Priority: must" nằm ở "Deferred".
#
# Result: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai check-plan.sh \
  "0=PASS — được sang phase sau" \
  "1=FAIL — có vi phạm, sửa trong phase này" \
  "2=NO INPUT — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/commands.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/approval-tick.sh"
. "$HERE/lib/adr.sh"
. "$HERE/lib/quote.sh"
. "$HERE/lib/rule.sh"
. "$HERE/lib/toc.sh"

DIR="${1:-.}"
nho_san "$DIR"  # nhớ rev-parse + quy ước hiệu lực ở shell chính (tốc độ)
SPEC="$DIR/spec.md"
TDD="$DIR/tdd.md"
PLAN="$DIR/plan.md"

n_loi=0

# Không có design (chore, hoặc bugfix/refactor "Design: skip" — kc_bo_design): entry check
# lùi về checker của spec, và không có tdd.md
# (task nào ghi "Based on: DEC-xxx" sẽ bị chặn vì không có DEC nào).
if kc_bo_design "$DIR"; then
  for f in "$SPEC" "$PLAN"; do
    [ -f "$f" ] || { echo "LỖI: không tìm thấy $f" >&2; exit 2; }
  done
  TDD=/dev/null
  # Chạy lại spec ở chế độ entry: câu trích [FILE] lệch nguồn (nguồn đổi sau spec) chỉ cảnh báo.
  ra_spec=$(sh "$HERE/check-spec.sh" "$DIR" --entry 2>/dev/null)
  ma_spec=$?
# giữ: INV-006
  printf '%s\n' "$ra_spec" | grep -F '[WARN]'
# giữ: INV-005
  if [ "$ma_spec" -ne 0 ]; then
    n_loi=1
    echo "  [ERROR] Đầu vào chưa đạt: spec.md không qua aw check spec — chạy nó để xem chi tiết."
  fi
  # Việc có design thì cổng duyệt spec nằm ở design; bỏ design thì nằm ở đây.
  cd_duyet=$(kc_spec_chua_duyet "$DIR")
  if [ -n "$cd_duyet" ]; then
    n_loi=$((n_loi + 1))
    # giữ: CAP-require-03, INV-005
    echo "  [ERROR] Đầu vào chưa đạt: $cd_duyet"
  fi
  # Điểm mù mức "blocking" chặn phase ngay sau spec — khi bỏ design là phase này.
  dm=$(kc_diem_mu_mo "$DIR" "blocking")
  if [ -n "$dm" ]; then
    # giữ: CAP-require-02
    while IFS= read -r l; do
      [ -n "$l" ] || continue
      n_loi=$((n_loi + 1)); echo "  [ERROR] $l"
    done <<EOF
$dm
EOF
  fi
else
  for f in "$SPEC" "$TDD" "$PLAN"; do
    [ -f "$f" ] || { echo "LỖI: không tìm thấy $f" >&2; exit 2; }
  done
  # giữ: INV-005
  if ! sh "$HERE/check-design.sh" "$DIR" >/dev/null 2>&1; then
    n_loi=1
    echo "  [ERROR] Đầu vào chưa đạt: tdd.md không qua aw check design — chạy nó để xem chi tiết."
  fi
fi

# REQ người chọn nâng thành luật phải có task ghi file luật (tools/lib/rule.sh).
llk=$(luat_loi_ke_hoach "$DIR")
while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [ERROR] $l"; }; done <<EOF
$llk
EOF
# Mục lục và link tới mục (tools/lib/toc.sh).
# giữ: INV-012
tl=$(toc_loi "$DIR" plan.md)
while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [ERROR] $l"; }; done <<EOF
$tl
EOF
qtl=$(kc_quy_tac_loi "$DIR" plan)
while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [ERROR] $l"; }; done <<EOF
$qtl
EOF
fmh=$(kc_fm_hong "$DIR")
# giữ: INV-006
while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [ERROR] $l"; }; done <<EOF
$fmh
EOF

# Trạng thái duyệt từng DEC-xxx — thư viện chung (tick + dấu duyệt khớp nội dung).
DTT=""
if [ "$TDD" != /dev/null ]; then
  dy_dong_dau "$TDD" tdd >/dev/null
  DTT=$(dy_trang_thai "$TDD" tdd | awk -F'|' '$1 == "S" { printf "%s=%s;", $2, $3 }')
  # DEC người quyết nâng thành ADR phải có task nâng (tools/lib/adr.sh).
  # giữ: CAP-breakdown-02
  alk=$(adr_loi_ke_hoach "$DIR")
  while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [ERROR] $l"; }; done <<EOF
$alk
EOF
fi

# Mã finding của review.md hiện tại — task "Fixes: RVW-NNN" (plan bổ sung sau review) phải trỏ về một mã có thật.
RVW=""
[ -f "$DIR/review.md" ] && RVW=$(awk '{ sub(/\r$/, "") } /^##[ \t]+Lens 3/ { l3 = 1; next } /^##[ \t]/ && !/^###/ { l3 = 0 }
  l3 && /^###[ \t]/ && match($0, /\[(Blocker|Should fix|Nit)\][ \t]*RVW-[0-9]+/) { s = substr($0, RSTART, RLENGTH); match(s, /RVW-[0-9]+/); printf " %s", substr(s, RSTART, RLENGTH) }' "$DIR/review.md")

awk -v loi_truoc="$n_loi" -v dtt="$DTT" -v rvw="$RVW " '
  function loi(msg) { n_loi++; print "  [ERROR] " msg }
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function gia_tri(s) { sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); return trim(s) }
  function thu_ma(dong, re, _tmp) {
    n_tim = 0; _tmp = dong
    while (match(_tmp, re)) { ma_tim[++n_tim] = substr(_tmp, RSTART, RLENGTH); _tmp = substr(_tmp, RSTART + RLENGTH) }
    return n_tim
  }

  BEGIN {
    n_loi = loi_truoc
    n_kv = split(dtt, kv, ";"); for (i = 1; i <= n_kv; i++) if (kv[i] != "") { split(kv[i], kv2, "="); d_tt[kv2[1]] = kv2[2] }
  }
  { sub(/\r$/, "") }
  FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : (FILENAME == ARGV[2]) ? 2 : 3; sect=""; cur="" }

  # ---- File 1: spec.md — thu mọi mã yêu cầu ----
  idx==1 {
    if ($0 ~ /^###[ \t]+REQ-[0-9]+/) {
      match($0, /REQ-[0-9]+/); c = substr($0, RSTART, RLENGTH)
      co_yc[c] = 1; dsach_yc[++n_yc] = c
    } else if ($0 ~ /^##/) c = ""
    if (c != "" && $0 ~ /^[ \t]*-[ \t]*\**Priority\**:/) uu_tien[c] = gia_tri($0)
    next
  }

  # ---- File 2: tdd.md — thu mọi DEC-xxx và trạng thái ----
  idx==2 {
    if ($0 ~ /^###[ \t]+DEC-[0-9]+/) { match($0, /DEC-[0-9]+/); d = substr($0, RSTART, RLENGTH); co_d[d] = 1; ds_d[++n_d] = d; next }
    if ($0 ~ /^##?[ \t]/) d = ""
    next
  }

  # ---- File 3: plan.md ----
  $0 ~ /^##[ \t]+Deferred/ { sect = "hoan"; cur = ""; next }
  $0 ~ /^##[ \t]/          { sect = "";     cur = ""; next }

  $0 ~ /^###[ \t]+TSK-/ {
    match($0, /TSK-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
    # giữ: CAP-breakdown-01
    if (cur in co_task) loi("Mã task " cur " bị trùng")
    # giữ: CAP-breakdown-01
    if (cur !~ /^TSK-[0-9][0-9][0-9]$/) loi("Mã " cur " sai dạng trong plan.md: phải đúng 3 chữ số (TSK-001)")
    co_task[cur] = 1; dsach_task[++n_task] = cur
    next
  }

  sect == "hoan" && $0 ~ /REQ-[0-9]+/ && $0 ~ /^[ \t]*\|/ {
    split($0, f, "|")
    match($0, /REQ-[0-9]+/); c = substr($0, RSTART, RLENGTH)
    co_mat_hoan[c] = 1
    ly_do = trim(f[3])
    # giữ: CAP-breakdown-01, INV-001
    if (ly_do == "" || ly_do ~ /^<.*>$/)
      loi(c ": nằm ở \"Deferred\" nhưng không ghi lý do")
    else
      hoan[c] = 1
    next
  }

  cur != "" && $0 ~ /^[ \t]*-[ \t]*\**Covers\**:/ {
    thu_ma($0, "REQ-[0-9]+")
    if (n_tim == 0) {
      # giữ: CAP-breakdown-01, INV-001
      loi(cur ": dòng \"Covers:\" không trỏ về mã REQ nào")
    } else {
      for (i = 1; i <= n_tim; i++) {
        c = ma_tim[i]
        # giữ: CAP-breakdown-01, INV-001
        if (!(c in co_yc)) loi(cur ": trỏ về " c " nhưng spec.md không có mã này")
        else               duoc_phu[c] = duoc_phu[c] " " cur
      }
      co_phu[cur] = 1
    }
    next
  }

  # Plan bổ sung sau review: task sửa finding thay "Covers" bằng "Fixes: RVW-NNN" hoặc URL bình luận MR.
  cur != "" && $0 ~ /^[ \t]*-[ \t]*\**Fixes\**:/ {
    v = $0; sub(/^[^:]*:/, "", v); gsub(/[`,*]/, " ", v); n = split(v, gt_fx, /[ \t]+/)
    for (i = 1; i <= n; i++) {
      x = gt_fx[i]; if (x == "") continue
      if (x ~ /^RVW-[0-9]+$/) { fx[cur] = fx[cur] " " x; co_sua[cur] = 1 }
      else if (x ~ /^https?:\/\/./) co_sua[cur] = 1
      # giữ: INV-001
      else loi(cur ": \"Fixes:\" \"" x "\" — chỉ nhận RVW-NNN hoặc URL bình luận MR (http(s)://…)")
    }
    next
  }
  cur != "" && $0 ~ /^[ \t]*-[ \t]*\**Status\**:/ { if ($0 ~ /\[x\]/) xong[cur] = 1 }

  cur != "" && $0 ~ /^[ \t]*-[ \t]*\**Based on\**:/ {
    thu_ma($0, "DEC-[0-9]+")
    for (i = 1; i <= n_tim; i++) {
      d = ma_tim[i]
      # giữ: INV-002
      if (!(d in co_d)) loi(cur ": \"Based on: " d "\" nhưng tdd.md không có " d)
      else dua_tren[d] = dua_tren[d] " " cur
    }
    next
  }

  cur != "" && $0 ~ /^[ \t]*-[ \t]*\**Expected files\**:/ {
    v = $0; sub(/^[^:]*:[ \t]*/, "", v); v = trim(v)
    co_fdk_dong[cur] = 1
    # giữ: CAP-breakdown-02
    if (v == "" || v ~ /<[^>]*>/) loi(cur ": \"Expected files\" trống hoặc còn chỗ giữ chỗ — implement dùng nó để kiểm phạm vi diff")
    next
  }

  cur != "" && $0 ~ /^[ \t]*-[ \t]*\**Verify\**:/ {
    v = $0; sub(/^[^:]*:[ \t]*/, "", v); v = trim(v)
    co_kc_dong[cur] = 1
    # giữ: CAP-breakdown-02
    if (v == "")            loi(cur ": \"Verify\" để trống")
    # giữ: CAP-breakdown-02
    else if (v ~ /<[^>]*>/) loi(cur ": \"Verify\" còn chỗ giữ chỗ chưa điền — " v)
    next
  }

  END {
    # giữ: CAP-require-01
    if (n_yc == 0)   loi("spec.md không có mã REQ nào")
    # giữ: CAP-breakdown-01
    if (n_task == 0) loi("plan.md không có task nào (không thấy heading \"### TSK-NNN\")")

    # DEC-xxx phải được người duyệt trước khi lập kế hoạch
    for (i = 1; i <= n_d; i++) {
      d = ds_d[i]
      # giữ: CAP-design-03, INV-005
      if (d_tt[d] != "approved")
        loi(d ": chưa được người duyệt (" (d_tt[d] == "" ? "không đọc được approval checkbox" : d_tt[d]) ")" \
            (d in dua_tren ? " — task bị ảnh hưởng:" dua_tren[d] " (đặt lại `[ ]`)" : ""))
    }

    for (i = 1; i <= n_task; i++) {
      t = dsach_task[i]
      # giữ: CAP-breakdown-01, INV-001
      if (!(t in co_phu) && !(t in co_sua)) loi(t ": thiếu \"Covers:\" hoặc \"Fixes:\" — task phải phủ một REQ hoặc sửa một finding review")
      # Fixes trên task chưa xong phải trỏ về finding của review.md hiện tại (task [x]: review đã ghi lại, lịch sử ở git)
      # giữ: CAP-breakdown-01, INV-001
      if (!(t in xong)) { n_fx = split(fx[t], ds_fx, " "); for (j = 1; j <= n_fx; j++) if (ds_fx[j] != "" && index(rvw, " " ds_fx[j] " ") == 0) loi(t ": \"Fixes: " ds_fx[j] "\" nhưng review.md không có finding mã đó") }
      # giữ: CAP-breakdown-02
      if (!(t in co_kc_dong))  loi(t ": thiếu dòng \"Verify:\"")
      # giữ: CAP-breakdown-02
      if (!(t in co_fdk_dong)) loi(t ": thiếu dòng \"Expected files:\"")
    }

    for (i = 1; i <= n_yc; i++) {
      c = dsach_yc[i]
      # giữ: CAP-breakdown-01, INV-001
      if (!(c in duoc_phu) && !(c in co_mat_hoan))
        loi(c ": không task nào phủ, cũng không nằm ở mục \"Deferred\"")
    }

    print ""
    printf "Tổng: %d yêu cầu, %d task, %d quyết định\n", n_yc, n_task, n_d
    for (i = 1; i <= n_yc; i++) {
      c = dsach_yc[i]
      if (c in duoc_phu)   printf "  %s ←%s\n", c, duoc_phu[c]
      else if (c in hoan)  printf "  %s ← (hoãn lại)\n", c
      else                 printf "  %s ← KHÔNG PHỦ\n", c
    }
    # Hoãn REQ "must" không sai cú pháp, nhưng nghĩa là giao thiếu: người phải thấy.
    # giữ: CAP-breakdown-01, INV-001
    for (i = 1; i <= n_yc; i++) {
      c = dsach_yc[i]
      if ((c in hoan) && uu_tien[c] != "should")
        print "  [WARN] " c ": Priority must nhưng nằm ở \"Deferred\" — người duyệt plan phải đồng ý giao thiếu."
    }
    print ""
    if (n_loi > 0) { print "FAIL — " n_loi " vi phạm."; exit 1 }
    print "PASS — kế hoạch phủ đúng đặc tả theo cả hai chiều, mọi quyết định đã duyệt."
  }
' "$SPEC" "$TDD" "$PLAN"
ma=$?

cb=$( { kc_loi_thoi "$DIR"; kc_based_on_thieu "$DIR"; kc_glob_rong "$DIR"; } )
# giữ: INV-006
if [ -n "$cb" ]; then
  echo ""
  echo "$cb" | while IFS= read -r l; do echo "  [WARN] $l"; done
  echo "  (cảnh báo không chặn ở đây; review sẽ chặn nếu còn)"
fi
exit $ma
