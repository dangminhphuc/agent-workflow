#!/usr/bin/env sh
# Kiểm tra điều kiện ra của phase 03-plan.
#
#   aw check plan <thư-mục-feature>
#
# Chặn:
#   - Đầu vào: tdd.md không qua kiem-tra-thiet-ke.sh (entry check = checker phase trước).
#   - Đầu vào (chore): spec chưa duyệt, còn điểm mù "Mức chặn: chặn" chưa trả lời.
#   - Đầu vào: còn D-xx chưa được người tick duyệt (hoặc đổi sau khi tick). plan và implement không có người —
#     chúng chỉ được thực thi những gì người đã duyệt.
#   - Kiểm HAI CHIỀU phủ YC:
#       xuôi  — mọi task trỏ về mã YC có thật trong spec.md   (bắt task thừa)
#       ngược — mọi mã YC được task phủ, hoặc nằm ở "Hoãn lại" (bắt yêu cầu sót)
#   - Task thiếu "Cách kiểm chứng", "File dự kiến"; "Dựa trên: D-xx" trỏ về D không có.
#   - File khai ở quy_tac_plan (conventions.md) không có hoặc chưa commit.
# Cảnh báo: artifact lỗi thời; YC "Ưu tiên: bắt buộc" nằm ở "Hoãn lại".
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai kiem-tra-ke-hoach.sh \
  "0=ĐẠT — được sang phase sau" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/bang-lenh.sh"
. "$HERE/lib/kiem-cheo.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/duyet.sh"

DIR="${1:-.}"
SPEC="$DIR/spec.md"
TDD="$DIR/tdd.md"
PLAN="$DIR/plan.md"

LOAI=$(kc_loai "$DIR")
n_loi=0

# chore không có design: entry check lùi về checker của spec, và không có tdd.md
# (task nào ghi "Dựa trên: D-xx" sẽ bị chặn vì không có D nào).
if [ "$LOAI" = "chore" ]; then
  for f in "$SPEC" "$PLAN"; do
    [ -f "$f" ] || { echo "LỖI: không tìm thấy $f" >&2; exit 2; }
  done
  TDD=/dev/null
  if ! sh "$HERE/kiem-tra-truy-vet.sh" "$DIR" >/dev/null 2>&1; then
    n_loi=1
    echo "  [LỖI] Đầu vào chưa đạt: spec.md không qua aw check spec — chạy nó để xem chi tiết."
  fi
  # Với feature/bugfix/... cổng duyệt spec nằm ở design; chore bỏ design nên nằm ở đây.
  cd_duyet=$(kc_spec_chua_duyet "$DIR")
  if [ -n "$cd_duyet" ]; then
    n_loi=$((n_loi + 1))
    echo "  [LỖI] Đầu vào chưa đạt: $cd_duyet"
  fi
  # Điểm mù mức "chặn" chặn phase ngay sau spec — với chore là phase này.
  dm=$(kc_diem_mu_mo "$DIR" "chặn")
  if [ -n "$dm" ]; then
    while IFS= read -r l; do
      [ -n "$l" ] || continue
      n_loi=$((n_loi + 1)); echo "  [LỖI] $l"
    done <<EOF
$dm
EOF
  fi
else
  for f in "$SPEC" "$TDD" "$PLAN"; do
    [ -f "$f" ] || { echo "LỖI: không tìm thấy $f" >&2; exit 2; }
  done
  if ! sh "$HERE/kiem-tra-thiet-ke.sh" "$DIR" >/dev/null 2>&1; then
    n_loi=1
    echo "  [LỖI] Đầu vào chưa đạt: tdd.md không qua aw check design — chạy nó để xem chi tiết."
  fi
fi

qtl=$(kc_quy_tac_loi "$DIR" plan)
while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [LỖI] $l"; }; done <<EOF
$qtl
EOF

# Trạng thái duyệt từng D-xx — thư viện chung (tick + dấu duyệt khớp nội dung).
DTT=""
if [ "$TDD" != /dev/null ]; then
  dy_dong_dau "$TDD" tdd >/dev/null
  DTT=$(dy_trang_thai "$TDD" tdd | awk -F'|' '$1 == "S" { printf "%s=%s;", $2, $3 }')
fi

awk -v loi_truoc="$n_loi" -v dtt="$DTT" '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }
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
    if ($0 ~ /^###[ \t]+YC-[0-9]+/) {
      match($0, /YC-[0-9]+/); c = substr($0, RSTART, RLENGTH)
      co_yc[c] = 1; dsach_yc[++n_yc] = c
    } else if ($0 ~ /^##/) c = ""
    if (c != "" && $0 ~ /^[ \t]*-[ \t]*\*{0,2}Ưu tiên[^:]*:/) uu_tien[c] = gia_tri($0)
    next
  }

  # ---- File 2: tdd.md — thu mọi D-xx và trạng thái ----
  idx==2 {
    if ($0 ~ /^###[ \t]+D-[0-9]+/) { match($0, /D-[0-9]+/); d = substr($0, RSTART, RLENGTH); co_d[d] = 1; ds_d[++n_d] = d; next }
    if ($0 ~ /^##?[ \t]/) d = ""
    next
  }

  # ---- File 3: plan.md ----
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
    thu_ma($0, "YC-[0-9]+")
    if (n_tim == 0) {
      loi(cur ": dòng \"Phủ:\" không trỏ về mã YC nào")
    } else {
      for (i = 1; i <= n_tim; i++) {
        c = ma_tim[i]
        if (!(c in co_yc)) loi(cur ": trỏ về " c " nhưng spec.md không có mã này")
        else               duoc_phu[c] = duoc_phu[c] " " cur
      }
      co_phu[cur] = 1
    }
    next
  }

  cur != "" && $0 ~ /Dựa trên:/ {
    thu_ma($0, "D-[0-9]+")
    for (i = 1; i <= n_tim; i++) {
      d = ma_tim[i]
      if (!(d in co_d)) loi(cur ": \"Dựa trên: " d "\" nhưng tdd.md không có " d)
      else dua_tren[d] = dua_tren[d] " " cur
    }
    next
  }

  cur != "" && $0 ~ /File dự kiến:/ {
    v = $0; sub(/^.*File dự kiến:[ \t]*/, "", v); v = trim(v)
    co_fdk_dong[cur] = 1
    if (v == "" || v ~ /<[^>]*>/) loi(cur ": \"File dự kiến\" trống hoặc còn chỗ giữ chỗ — implement dùng nó để kiểm phạm vi diff")
    next
  }

  cur != "" && $0 ~ /Cách kiểm chứng:/ {
    v = $0; sub(/^.*Cách kiểm chứng:[ \t]*/, "", v); v = trim(v)
    co_kc_dong[cur] = 1
    if (v == "")            loi(cur ": \"Cách kiểm chứng\" để trống")
    else if (v ~ /<[^>]*>/) loi(cur ": \"Cách kiểm chứng\" còn chỗ giữ chỗ chưa điền — " v)
    next
  }

  END {
    if (n_yc == 0)   loi("spec.md không có mã YC nào")
    if (n_task == 0) loi("plan.md không có task nào (không thấy heading \"### T-NN\")")

    # D-xx phải được người duyệt trước khi lập kế hoạch
    for (i = 1; i <= n_d; i++) {
      d = ds_d[i]
      if (d_tt[d] != "đã duyệt")
        loi(d ": chưa được người duyệt (" (d_tt[d] == "" ? "không đọc được ô duyệt" : d_tt[d]) ")" \
            (d in dua_tren ? " — task bị ảnh hưởng:" dua_tren[d] " (đặt lại `[ ]`)" : ""))
    }

    for (i = 1; i <= n_task; i++) {
      t = dsach_task[i]
      if (!(t in co_phu))      loi(t ": thiếu dòng \"Phủ:\" — task không ánh xạ được về yêu cầu nào")
      if (!(t in co_kc_dong))  loi(t ": thiếu dòng \"Cách kiểm chứng:\"")
      if (!(t in co_fdk_dong)) loi(t ": thiếu dòng \"File dự kiến:\"")
    }

    for (i = 1; i <= n_yc; i++) {
      c = dsach_yc[i]
      if (!(c in duoc_phu) && !(c in co_mat_hoan))
        loi(c ": không task nào phủ, cũng không nằm ở mục \"Hoãn lại\"")
    }

    print ""
    printf "Tổng: %d yêu cầu, %d task, %d quyết định\n", n_yc, n_task, n_d
    for (i = 1; i <= n_yc; i++) {
      c = dsach_yc[i]
      if (c in duoc_phu)   printf "  %s ←%s\n", c, duoc_phu[c]
      else if (c in hoan)  printf "  %s ← (hoãn lại)\n", c
      else                 printf "  %s ← KHÔNG PHỦ\n", c
    }
    # Hoãn YC "bắt buộc" không sai cú pháp, nhưng nghĩa là giao thiếu: người phải thấy.
    for (i = 1; i <= n_yc; i++) {
      c = dsach_yc[i]
      if ((c in hoan) && uu_tien[c] != "nên có")
        print "  [CẢNH BÁO] " c ": Ưu tiên bắt buộc nhưng nằm ở \"Hoãn lại\" — người duyệt plan phải đồng ý giao thiếu."
    }
    print ""
    if (n_loi > 0) { print "KHÔNG ĐẠT — " n_loi " vi phạm."; exit 1 }
    print "ĐẠT — kế hoạch phủ đúng đặc tả theo cả hai chiều, mọi quyết định đã duyệt."
  }
' "$SPEC" "$TDD" "$PLAN"
ma=$?

cb=$(kc_loi_thoi "$DIR")
if [ -n "$cb" ]; then
  echo ""
  echo "$cb" | while IFS= read -r l; do echo "  [CẢNH BÁO] $l"; done
  echo "  (cảnh báo không chặn ở đây; review sẽ chặn nếu còn)"
fi
exit $ma
