#!/usr/bin/env sh
# Liệt kê việc đang CHỜ NGƯỜI quyết, theo thứ tự PHẢI GIẢI QUYẾT TRƯỚC — để không
# phase nào bị chặn. Lệnh clarify đọc output này rồi dẫn người đi từng mục.
#
#   aw pending <thư-mục-feature>
#
# Nguồn (mỗi nguồn giữ file riêng — không gộp, xem docs/kien-truc.md):
#   - open-questions.md    điểm mù còn `open`              → người TRẢ LỜI
#   - *-findings.md       phát hiện checker LLM `chưa`  → người PHÂN XỬ
#                          (hiện có design-findings.md; checker mới chỉ cần
#                          ghi đúng mẫu là tự được gom)
#
# Thứ tự nhóm (nhóm chặn phase sớm hơn đứng trước):
#   1. Điểm mù thiếu/sai "Blocking" (checker spec đang chặn)
#   2. Điểm mù `blocking`             — chặn /aw-design (chore: /aw-plan)
#   3. Phát hiện mức `Chặn`         — chặn checker của phase ghi ra nó (thiết kế: /aw-plan)
#   4. Điểm mù `review-blocking`      — chặn /aw-review
#   5. Phát hiện mức `Cảnh báo`     — không chặn
#   6. Điểm mù `non-blocking`       — không chặn
# Trong nhóm điểm mù: YC "must" trước "should", rồi nhiều task trong plan.md
# đứng trên giả định tạm hơn thì trước, rồi thứ tự trong file. Trong nhóm phát
# hiện: thứ tự trong file.
# Mục đã xong (điểm mù `answered`, phát hiện `đã sửa` / `bác bỏ: <lý do>`) chỉ
# được đếm; phát hiện đã xong được liệt kê một dòng để người thấy agent đã tự
# xử lý gì.
#
# Chỉ đọc, không sửa file nào. Không chấm đạt/không đạt: nhãn kết quả cho biết
# có việc nào đang chặn phase kế tiếp hay không.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai pending.sh \
  "0=KHÔNG CÒN VIỆC CHỜ NGƯỜI" \
  "1=CÓ VIỆC ĐANG CHẶN — giải quyết theo thứ tự trên trước khi chạy phase kế tiếp" \
  "3=CÒN VIỆC CHỜ NGƯỜI, CHƯA CHẶN phase kế tiếp" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần đọc"
. "$HERE/lib/md.sh"
. "$HERE/lib/cross-check.sh"

DIR="${1:-.}"
SPEC="$DIR/spec.md"
OQ="$DIR/open-questions.md"
PLAN="$DIR/plan.md"

[ -f "$SPEC" ] || { echo "LỖI: không tìm thấy $SPEC — chạy /aw-spec trước" >&2; exit 2; }
[ -f "$OQ" ]   || { echo "LỖI: không tìm thấy $OQ — /aw-spec chưa rà điểm mù" >&2; exit 2; }

LOAI=$(kc_loai "$DIR")

# Phase kế tiếp, suy từ artifact đã có. Điểm mù mức "blocking" chặn phase ngay sau
# spec, và vì mỗi checker chạy lại checker phase trước, nó chặn mọi phase sau đó.
if [ -f "$DIR/review.md" ] || [ -f "$DIR/test-results.md" ]; then KE=review
elif [ -f "$PLAN" ]; then KE=implement
elif [ "$LOAI" = "chore" ]; then KE=plan
elif [ -f "$DIR/tdd.md" ]; then KE=plan
else KE=design
fi
if [ "$LOAI" = "chore" ]; then CHAN_SAU_SPEC=plan; else CHAN_SAU_SPEC=design; fi

PL="$PLAN"; [ -f "$PL" ] || PL=/dev/null

# File phát hiện của checker LLM. Thứ tự glob là thứ tự chữ cái — ổn định.
set -- "$OQ" "$SPEC" "$PL"
for _ph in "$DIR"/*-findings.md; do [ -f "$_ph" ] && set -- "$@" "$_ph"; done

awk -v ke="$KE" -v csp="$CHAN_SAU_SPEC" '
  function gia_tri(s) { sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function co_nd(v) { return (v != "" && v !~ /^<.*>$/) }
  function ten_file(p) { sub(/^.*\//, "", p); return p }
  { sub(/\r$/, "") }
  # Theo tên file, không đếm FNR==1: file 0 byte không có dòng nào nên sẽ làm lệch thứ tự.
  FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : (FILENAME == ARGV[2]) ? 2 : (FILENAME == ARGV[3]) ? 3 : 4; cur = ""; nguon = ten_file(FILENAME) }

  # ---- File 1: open-questions.md ----
  idx==1 && /^##[ \t]+YC-[0-9]+/ {
    match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
    ds[++n] = cur; tt[cur] = "open"; muc[cur] = ""
    t = $0; sub(/^##[ \t]+YC-[0-9]+[ \t]*[—:-]*[ \t]*/, "", t); ten[cur] = t
    next
  }
  idx==1 && /^##?[ \t]/ { cur = ""; next }
  idx==1 && cur != "" && /^[ \t]*-/ {
    if ($0 ~ /^[ \t]*-[ \t]*\**Blocking\**:/)            muc[cur] = gia_tri($0)
    else if ($0 ~ /^[ \t]*-[ \t]*\**Status\**:/)         tt[cur]  = gia_tri($0)
    else if ($0 ~ /^[ \t]*-[ \t]*\**Question\**:/)       hoi[cur] = gia_tri($0)
    else if ($0 ~ /^[ \t]*-[ \t]*\**Ask\**:/)            ai[cur]  = gia_tri($0)
    else if ($0 ~ /^[ \t]*-[ \t]*\**Assumption\**:/)     gd[cur]  = gia_tri($0)
    else if ($0 ~ /^[ \t]*-[ \t]*\**If wrong, redo\**:/) sai[cur] = gia_tri($0)
    next
  }
  idx==1 { next }

  # ---- File 2: spec.md — Priority của YC ----
  idx==2 && /^###[ \t]+YC-[0-9]+/ { match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH); next }
  idx==2 && /^###?[ \t]/ { cur = ""; next }
  idx==2 && cur != "" && /^[ \t]*-[ \t]*\**Priority\**:/ { ut[cur] = gia_tri($0); next }
  idx==2 { next }

  # ---- File 3: plan.md — task đứng trên giả định tạm ----
  idx==3 && /^###[ \t]+T-[0-9]+/ { match($0, /T-[0-9]+/); cur = substr($0, RSTART, RLENGTH); next }
  idx==3 && cur != "" && /^[ \t]*-[ \t]*\**On assumption\**:/ {
    s = $0; while (match(s, /YC-[0-9]+/)) { q = substr(s, RSTART, RLENGTH); so_task[q]++; task[q] = task[q] " " cur; s = substr(s, RSTART + RLENGTH) }
  }
  idx==3 { next }

  # ---- File 4+: *-findings.md — khoá theo "file:PH-NN" (hai checker có thể trùng số) ----
  idx==4 && /^###[ \t]+PH-[0-9]+/ {
    match($0, /PH-[0-9]+/); cur = nguon ":" substr($0, RSTART, RLENGTH)
    ds_ph[++n_ph] = cur; ph_ma[cur] = substr($0, RSTART, RLENGTH); ph_nguon[cur] = nguon
    t = $0; sub(/^###[ \t]+PH-[0-9]+[ \t]*[—:-]*[ \t]*/, "", t); ph_ten[cur] = t
    next
  }
  idx==4 && /^##?#?[ \t]/ { cur = ""; next }
  idx==4 && cur != "" && /^[ \t]*-/ {
    if ($0 ~ /Mức[^:]*:/)          ph_muc[cur] = gia_tri($0)
    else if ($0 ~ /Loại[^:]*:/)    ph_loai[cur] = gia_tri($0)
    else if ($0 ~ /Vị trí[^:]*:/)  ph_vt[cur] = gia_tri($0)
    else if ($0 ~ /Vấn đề[^:]*:/)  ph_vd[cur] = gia_tri($0)
    else if ($0 ~ /Xử lý[^:]*:/)   ph_xl[cur] = gia_tri($0)
    next
  }

  END {
    nhom[0] = "CHƯA PHÂN MỨC"; nhom[1] = "BLOCKING"; nhom[2] = "PHÁT HIỆN — CHẶN"
    nhom[3] = "REVIEW-BLOCKING"; nhom[4] = "PHÁT HIỆN — CẢNH BÁO"; nhom[5] = "NON-BLOCKING"
    mo_ta[0] = "điểm mù thiếu hoặc sai \"Blocking\" — checker của spec chặn; NGƯỜI gán: blocking | review-blocking | non-blocking"
    mo_ta[1] = "điểm mù: sai giả định thì cả thiết kế đổi hướng — chặn /" csp
    mo_ta[2] = "phát hiện của checker LLM, NGƯỜI phân xử: đồng ý (sửa → đã sửa) hoặc bác bỏ kèm lý do"
    mo_ta[3] = "điểm mù: flow đi tiếp trên giả định tạm; /aw-review chặn tới khi có câu trả lời"
    mo_ta[4] = "phát hiện của checker LLM, không chặn — vẫn nên phân xử trước khi phase sau dựa vào"
    mo_ta[5] = "điểm mù: giao được trên giả định tạm; review ghi YC đó \"pending\""
    # Phase nào chặn "ngay": phase kế tiếp, hoặc mọi phase sau khi đã qua phase bị chặn
    # (checker mỗi phase chạy lại checker phase trước).
    thu["spec"] = 1; thu["design"] = 2; thu["plan"] = 3; thu["implement"] = 4; thu["review"] = 5
    # File phát hiện → phase mà phát hiện Chặn của nó chặn. Checker mới: thêm một dòng.
    ph_chan["design-findings.md"] = "plan"

    for (i = 1; i <= n; i++) {
      q = ds[i]
      if (tt[q] == "answered") { n_xong++; continue }
      m = muc[q]
      g = (m == "blocking") ? 1 : (m == "review-blocking") ? 3 : (m == "non-blocking") ? 5 : 0
      # Khoá sắp xếp: nhóm, ưu tiên YC (must trước), số task (nhiều trước), thứ tự trong file.
      k = sprintf("%d %d %04d %04d", g, (ut[q] == "should") ? 1 : 0, 9999 - so_task[q], i)
      khoa[++n_mo] = k; ma_k[k] = q; nh[q] = g; n_dm++
      dem[g]++
      if (g == 0)                                   { dang_chan[q] = "spec"; n_chan++ }
      else if (g == 1 && thu[ke] >= thu[csp])       { dang_chan[q] = ke;     n_chan++ }
      else if (g == 3 && ke == "review")            { dang_chan[q] = ke;     n_chan++ }
    }

    for (i = 1; i <= n_ph; i++) {
      p = ds_ph[i]; x = ph_xl[p]
      r = x; sub(/^bác bỏ[ \t]*[—:-]?[ \t]*/, "", r)
      if (x == "đã sửa" || (x ~ /^bác bỏ/ && co_nd(r))) { ph_xong[++n_ph_xong] = p; continue }
      g = (ph_muc[p] == "Chặn") ? 2 : 4
      k = sprintf("%d 0 0000 %04d", g, i)
      khoa[++n_mo] = k; ma_k[k] = p; nh[p] = g; n_phmo++
      dem[g]++
      if (g == 2) {
        c = (ph_nguon[p] in ph_chan) ? ph_chan[ph_nguon[p]] : ""
        if (c == "")                      { dang_chan[p] = "?"; n_chan++ }
        else if (thu[ke] >= thu[c])       { dang_chan[p] = ke;  n_chan++ }
      }
    }

    # sắp xếp chèn — vài chục mục, không cần hơn
    for (i = 2; i <= n_mo; i++) { k = khoa[i]; j = i - 1; while (j >= 1 && khoa[j] > k) { khoa[j+1] = khoa[j]; j-- } khoa[j+1] = k }

    printf "Việc chờ người: %d — phase kế tiếp: /%s\n", n_mo, ke
    printf "  Điểm mù: %d open, %d answered · Phát hiện LLM: %d chờ phân xử, %d đã xử lý\n", n_dm, n_xong, n_phmo, n_ph_xong
    if (n_mo) {
      printf "  blocking: %d · phát hiện Chặn: %d · review-blocking: %d · phát hiện Cảnh báo: %d · non-blocking: %d", \
        dem[1] + 0, dem[2] + 0, dem[3] + 0, dem[4] + 0, dem[5] + 0
      if (dem[0]) printf " · chưa phân mức: %d", dem[0]
      printf "\n"
    }

    g_truoc = -1
    for (i = 1; i <= n_mo; i++) {
      q = ma_k[khoa[i]]; g = nh[q]
      if (g != g_truoc) {
        print ""
        printf "[%s] %s\n", nhom[g], mo_ta[g]
        g_truoc = g
      }
      dc = (q in dang_chan) ? (dang_chan[q] == "?" ? "   ← ĐANG CHẶN" : "   ← ĐANG CHẶN /aw-" dang_chan[q]) : ""
      if (g == 2 || g == 4) {
        printf "  %d. %s%s%s\n", i, ph_ma[q], (ph_ten[q] != "" ? " — " ph_ten[q] : ""), dc
        printf "     Nguồn: %s · Loại: %s · Vị trí: %s\n", ph_nguon[q], \
          (co_nd(ph_loai[q]) ? ph_loai[q] : "?"), (co_nd(ph_vt[q]) ? ph_vt[q] : "?")
        printf "     Vấn đề: %s\n", (co_nd(ph_vd[q]) ? ph_vd[q] : "<chưa ghi>")
        printf "     Xử lý hiện tại: %s\n", (ph_xl[q] == "" ? "<trống>" : ph_xl[q])
        continue
      }
      printf "  %d. %s%s%s\n", i, q, (ten[q] != "" ? " — " ten[q] : ""), dc
      printf "     Ask: %s · Priority: %s · Task on assumption: %d%s\n", \
        (co_nd(ai[q]) ? ai[q] : "?"), (co_nd(ut[q]) ? ut[q] : "?"), so_task[q], (so_task[q] ? " (" substr(task[q], 2) ")" : "")
      printf "     Question: %s\n", (co_nd(hoi[q]) ? hoi[q] : "<chưa ghi>")
      printf "     Assumption: %s\n", (co_nd(gd[q]) ? gd[q] : "<chưa ghi>")
      printf "     If wrong, redo: %s\n", (co_nd(sai[q]) ? sai[q] : "<chưa ghi>")
    }

    if (n_ph_xong) {
      print ""
      print "[ĐÃ XỬ LÝ] phát hiện đã đóng — người chưa chắc đã xem; nêu trong tổng kết"
      for (i = 1; i <= n_ph_xong; i++) { p = ph_xong[i]; printf "  - %s (%s) — %s: %s\n", ph_ma[p], ph_nguon[p], ph_ten[p], ph_xl[p] }
    }

    print ""
    if (n_mo == 0) { print "Không còn việc chờ người."; exit 0 }
    if (n_chan) { printf "%d mục đang chặn — giải quyết từ mục 1.\n", n_chan; exit 1 }
    print "Không mục nào chặn phase kế tiếp. Vẫn nên giải quyết từ mục 1 trước khi tới phase bị chặn."
    exit 3
  }
' "$@"
