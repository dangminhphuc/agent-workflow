#!/usr/bin/env sh
# Liệt kê điểm mù (open-questions.md) theo thứ tự PHẢI GIẢI QUYẾT TRƯỚC — để không
# phase nào bị chặn. Lệnh open-questions đọc output này rồi dẫn người đi từng mục.
#
#   sh tools/liet-ke-cau-hoi.sh <thư-mục-feature>
#
# Thứ tự:
#   1. Mức chặn: thiếu/sai nhãn (checker spec đang chặn) → chặn → chặn review → không chặn
#   2. Cùng mức: mục "đã trả lời" chờ người duyệt trước (gỡ chặn rẻ nhất), rồi
#      YC "Ưu tiên: bắt buộc" trước "nên có"
#   3. Nhiều task trong plan.md đứng trên giả định tạm hơn thì trước
#   4. Thứ tự trong file
# Chỉ "đã duyệt" (người tự sửa tay) mới xong: mục đó chỉ được đếm, không liệt kê.
#
# Chỉ đọc, không sửa file nào. Không chấm đạt/không đạt: nhãn kết quả cho biết
# có điểm mù nào đang chặn phase kế tiếp hay không.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai liet-ke-cau-hoi.sh \
  "0=KHÔNG CÒN ĐIỂM MÙ CHƯA DUYỆT" \
  "1=CÓ ĐIỂM MÙ ĐANG CHẶN — giải quyết theo thứ tự trên trước khi chạy phase kế tiếp" \
  "3=CÒN ĐIỂM MÙ CHƯA DUYỆT, CHƯA CHẶN phase kế tiếp" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần đọc"
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

DIR="${1:-.}"
SPEC="$DIR/spec.md"
OQ="$DIR/open-questions.md"
PLAN="$DIR/plan.md"

[ -f "$SPEC" ] || { echo "LỖI: không tìm thấy $SPEC — chạy /spec trước" >&2; exit 2; }
[ -f "$OQ" ]   || { echo "LỖI: không tìm thấy $OQ — /spec chưa rà điểm mù" >&2; exit 2; }

LOAI=$(kc_loai "$DIR")

# Phase kế tiếp, suy từ artifact đã có. Điểm mù mức "chặn" chặn phase ngay sau
# spec, và vì mỗi checker chạy lại checker phase trước, nó chặn mọi phase sau đó.
if [ -f "$DIR/review.md" ] || [ -f "$DIR/ket-qua-kiem-thu.md" ]; then KE=review
elif [ -f "$PLAN" ]; then KE=implement
elif [ "$LOAI" = "chore" ]; then KE=plan
elif [ -f "$DIR/tdd.md" ]; then KE=plan
else KE=design
fi
if [ "$LOAI" = "chore" ]; then CHAN_SAU_SPEC=plan; else CHAN_SAU_SPEC=design; fi

PL="$PLAN"; [ -f "$PL" ] || PL=/dev/null

awk -v ke="$KE" -v csp="$CHAN_SAU_SPEC" '
  function gia_tri(s) { sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function co_nd(v) { return (v != "" && v !~ /^<.*>$/) }
  { sub(/\r$/, "") }
  # Theo tên file, không đếm FNR==1: file 0 byte không có dòng nào nên sẽ làm lệch thứ tự.
  FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : (FILENAME == ARGV[2]) ? 2 : 3; cur = "" }

  # ---- File 1: open-questions.md ----
  idx==1 && /^##[ \t]+YC-[0-9]+/ {
    match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
    ds[++n] = cur; tt[cur] = "mở"; muc[cur] = ""
    t = $0; sub(/^##[ \t]+YC-[0-9]+[ \t]*[—:-]*[ \t]*/, "", t); ten[cur] = t
    next
  }
  idx==1 && /^##?[ \t]/ { cur = ""; next }
  idx==1 && cur != "" && /^[ \t]*-/ {
    if ($0 ~ /Mức chặn[^:]*:/)               muc[cur] = gia_tri($0)
    else if ($0 ~ /Trạng thái[^:]*:/)        tt[cur]  = gia_tri($0)
    else if ($0 ~ /Chỗ chưa rõ[^:]*:/)       hoi[cur] = gia_tri($0)
    else if ($0 ~ /Hỏi ai[^:]*:/)            ai[cur]  = gia_tri($0)
    else if ($0 ~ /Giả định tạm[^:]*:/)      gd[cur]  = gia_tri($0)
    else if ($0 ~ /Nếu giả định sai[^:]*:/)  sai[cur] = gia_tri($0)
    else if ($0 ~ /Trả lời[^:]*:/)           tl[cur]  = gia_tri($0)
    next
  }
  idx==1 { next }

  # ---- File 2: spec.md — Ưu tiên của YC ----
  idx==2 && /^###[ \t]+YC-[0-9]+/ { match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH); next }
  idx==2 && /^###?[ \t]/ { cur = ""; next }
  idx==2 && cur != "" && /^[ \t]*-[ \t]*[*]*Ưu tiên[^:]*:/ { ut[cur] = gia_tri($0); next }
  idx==2 { next }

  # ---- File 3: plan.md — task đứng trên giả định tạm ----
  idx==3 && /^###[ \t]+T-[0-9]+/ { match($0, /T-[0-9]+/); cur = substr($0, RSTART, RLENGTH); next }
  idx==3 && cur != "" && /Đứng trên giả định tạm/ {
    s = $0; while (match(s, /YC-[0-9]+/)) { q = substr(s, RSTART, RLENGTH); so_task[q]++; task[q] = task[q] " " cur; s = substr(s, RSTART + RLENGTH) }
  }

  END {
    nhom[0] = "CHƯA PHÂN MỨC"; nhom[1] = "CHẶN"; nhom[2] = "CHẶN REVIEW"; nhom[3] = "KHÔNG CHẶN"
    chan[0] = "spec"; chan[1] = csp; chan[2] = "review"; chan[3] = ""
    mo_ta[0] = "thiếu hoặc sai \"Mức chặn\" — checker của spec chặn; NGƯỜI gán: chặn | chặn review | không chặn"
    mo_ta[1] = "sai giả định thì cả thiết kế đổi hướng — chặn /" csp
    mo_ta[2] = "flow đi tiếp trên giả định tạm; /review chặn tới khi người duyệt"
    mo_ta[3] = "giao được trên giả định tạm; review ghi YC đó \"chờ xác nhận\""
    # Phase nào chặn "ngay": phase kế tiếp, hoặc mọi phase sau khi đã qua phase bị chặn
    # (checker mỗi phase chạy lại checker phase trước).
    thu["spec"] = 1; thu["design"] = 2; thu["plan"] = 3; thu["implement"] = 4; thu["review"] = 5

    for (i = 1; i <= n; i++) {
      q = ds[i]
      if (tt[q] == "đã duyệt") { n_xong++; continue }
      cho = (tt[q] == "đã trả lời") ? 0 : 1
      if (!cho) n_cho++
      m = muc[q]
      g = (m == "chặn") ? 1 : (m == "chặn review") ? 2 : (m == "không chặn") ? 3 : 0
      # Khoá sắp xếp: mức, ưu tiên YC (bắt buộc trước), số task (nhiều trước), thứ tự trong file.
      k = sprintf("%d %d %d %04d %04d", g, cho, (ut[q] == "nên có") ? 1 : 0, 9999 - so_task[q], i)
      khoa[++n_mo] = k; ma_k[k] = q; nh[q] = g
      dem[g]++
      if (g == 0 || (g == 1 && thu[ke] >= thu[csp]) || (g == 2 && ke == "review")) { dang_chan[q] = 1; n_chan++ }
    }

    # sắp xếp chèn — vài chục mục, không cần hơn
    for (i = 2; i <= n_mo; i++) { k = khoa[i]; j = i - 1; while (j >= 1 && khoa[j] > k) { khoa[j+1] = khoa[j]; j-- } khoa[j+1] = k }

    printf "Điểm mù: %d chưa xong (%d chờ người duyệt), %d đã duyệt — phase kế tiếp: /%s\n", n_mo, n_cho, n_xong, ke
    if (n_mo == 0) { print ""; print "Không còn điểm mù nào chưa duyệt."; exit 0 }
    printf "  chặn: %d · chặn review: %d · không chặn: %d", dem[1] + 0, dem[2] + 0, dem[3] + 0
    if (dem[0]) printf " · chưa phân mức: %d", dem[0]
    printf "\n"

    g_truoc = -1
    for (i = 1; i <= n_mo; i++) {
      q = ma_k[khoa[i]]; g = nh[q]
      if (g != g_truoc) {
        print ""
        printf "[%s] %s\n", nhom[g], mo_ta[g]
        g_truoc = g
      }
      printf "  %d. %s%s%s\n", i, q, (ten[q] != "" ? " — " ten[q] : ""), (q in dang_chan ? "   ← ĐANG CHẶN /" (g == 0 ? "spec" : ke) : "")
      printf "     Hỏi ai: %s · Ưu tiên YC: %s · Task đứng trên giả định: %d%s\n", \
        (co_nd(ai[q]) ? ai[q] : "?"), (co_nd(ut[q]) ? ut[q] : "?"), so_task[q], (so_task[q] ? " (" substr(task[q], 2) ")" : "")
      printf "     Chỗ chưa rõ: %s\n", (co_nd(hoi[q]) ? hoi[q] : "<chưa ghi>")
      printf "     Giả định tạm: %s\n", (co_nd(gd[q]) ? gd[q] : "<chưa ghi>")
      printf "     Nếu sai phải làm lại: %s\n", (co_nd(sai[q]) ? sai[q] : "<chưa ghi>")
      if (tt[q] == "đã trả lời")
        printf "     ĐÃ TRẢ LỜI, CHỜ NGƯỜI DUYỆT: %s\n     → người tự sửa tay Trạng thái sang \"đã duyệt\" trong open-questions.md\n", (co_nd(tl[q]) ? tl[q] : "<trống>")
    }
    print ""
    if (n_chan) { printf "%d điểm mù đang chặn — giải quyết từ mục 1.\n", n_chan; exit 1 }
    print "Không điểm mù nào chặn phase kế tiếp. Vẫn nên giải quyết từ mục 1 trước khi tới phase bị chặn."
    exit 3
  }
' "$OQ" "$SPEC" "$PL"
