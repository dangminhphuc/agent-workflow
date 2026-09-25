#!/usr/bin/env sh
# Kiểm tra kế hoạch phủ đúng đặc tả — điều kiện ra của phase 02-plan.
#
#   sh tools/kiem-tra-ke-hoach.sh <thư-mục-artifact>
#
# Kiểm HAI CHIỀU:
#   xuôi   — mọi task trỏ về mã YC có thật trong spec.md   (bắt task thừa)
#   ngược  — mọi mã YC được task phủ, hoặc nằm ở "Hoãn lại" (bắt yêu cầu sót)
# Kiểm một chiều chỉ bắt được lỗi thừa; lỗi sót mới là lỗi đắt.
#
# Mã thoát: 0 = đạt, 1 = có vi phạm, 2 = thiếu file đầu vào.

DIR="${1:-.agent-workflow}"
SPEC="$DIR/spec.md"
PLAN="$DIR/plan.md"

[ -f "$SPEC" ] || { echo "LỖI: không tìm thấy $SPEC" >&2; exit 2; }
[ -f "$PLAN" ] || { echo "LỖI: không tìm thấy $PLAN" >&2; exit 2; }

awk '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function thu_ma(dong, _tmp, _c, _dem) {
    _dem = 0; _tmp = dong
    while (match(_tmp, /YC-[0-9]+/)) {
      _c = substr(_tmp, RSTART, RLENGTH)
      ma_tim[++n_tim] = _c; _dem++
      _tmp = substr(_tmp, RSTART + RLENGTH)
    }
    return _dem
  }

  { sub(/\r$/, "") }
  FNR==1 { idx++; sect=""; cur="" }

  # ---- File 1: spec.md — thu mọi mã yêu cầu ----
  idx==1 {
    if ($0 ~ /^###[ \t]+YC-[0-9]+/) {
      match($0, /YC-[0-9]+/); c = substr($0, RSTART, RLENGTH)
      co_yc[c] = 1; dsach_yc[++n_yc] = c
    }
    next
  }

  # ---- File 2: plan.md ----
  $0 ~ /^##[ \t]+Hoãn lại/ { sect = "hoan"; cur = ""; next }
  $0 ~ /^##[ \t]/          { sect = "";     cur = ""; next }

  $0 ~ /^###[ \t]+T-/ {
    match($0, /T-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
    if (cur in co_task) loi("Mã task " cur " bị trùng")
    co_task[cur] = 1; dsach_task[++n_task] = cur
    next
  }

  sect == "hoan" && $0 ~ /YC-[0-9]+/ && $0 ~ /^[ \t]*\|/ {
    split($0, f, "|")
    match($0, /YC-[0-9]+/); c = substr($0, RSTART, RLENGTH)
    co_mat_hoan[c] = 1
    ly_do = trim(f[3])
    if (ly_do == "" || ly_do ~ /^<.*>$/)
      loi(c ": nằm ở \"Hoãn lại\" nhưng không ghi lý do")
    else
      hoan[c] = 1
    next
  }

  cur != "" && $0 ~ /Phủ:/ {
    n_tim = 0; delete ma_tim
    thu_ma($0)
    if (n_tim == 0) {
      loi(cur ": dòng \"Phủ:\" không trỏ về mã YC nào")
    } else {
      for (i = 1; i <= n_tim; i++) {
        c = ma_tim[i]
        if (!(c in co_yc))
          loi(cur ": trỏ về " c " nhưng spec.md không có mã này")
        else
          duoc_phu[c] = duoc_phu[c] " " cur
      }
      co_phu[cur] = 1
    }
    next
  }

  cur != "" && $0 ~ /Cách kiểm chứng:/ {
    v = $0; sub(/^.*Cách kiểm chứng:[ \t]*/, "", v); v = trim(v)
    co_kc_dong[cur] = 1
    if (v == "")            loi(cur ": \"Cách kiểm chứng\" để trống")
    else if (v ~ /<[^>]*>/) loi(cur ": \"Cách kiểm chứng\" còn chỗ giữ chỗ chưa điền — " v)
    else                    co_kc[cur] = 1
    next
  }

  END {
    if (n_yc == 0)   loi("spec.md không có mã YC nào")
    if (n_task == 0) loi("plan.md không có task nào (không thấy heading \"### T-NN\")")

    # chiều xuôi: task thiếu thông tin bắt buộc
    for (i = 1; i <= n_task; i++) {
      t = dsach_task[i]
      if (!(t in co_phu)) loi(t ": thiếu dòng \"Phủ:\" — task không ánh xạ được về yêu cầu nào")
      if (!(t in co_kc) && !(t in co_kc_dong)) loi(t ": thiếu dòng \"Cách kiểm chứng:\"")
    }

    # chiều ngược: yêu cầu bị bỏ sót
    for (i = 1; i <= n_yc; i++) {
      c = dsach_yc[i]
      if (!(c in duoc_phu) && !(c in hoan) && !(c in co_mat_hoan))
        loi(c ": không task nào phủ, cũng không nằm ở mục \"Hoãn lại\"")
    }

    print ""
    printf "Tổng: %d yêu cầu, %d task\n", n_yc, n_task
    for (i = 1; i <= n_yc; i++) {
      c = dsach_yc[i]
      if (c in duoc_phu)   printf "  %s ←%s\n", c, duoc_phu[c]
      else if (c in hoan)  printf "  %s ← (hoãn lại)\n", c
      else                 printf "  %s ← KHÔNG PHỦ\n", c
    }
    print ""
    if (n_loi > 0) { print "KHÔNG ĐẠT — " n_loi " vi phạm."; exit 1 }
    print "ĐẠT — kế hoạch phủ đúng đặc tả theo cả hai chiều."
  }
' "$SPEC" "$PLAN"
