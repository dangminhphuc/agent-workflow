#!/usr/bin/env sh
# Kiểm tra điều kiện ra của phase 02-design.
#
#   sh tools/kiem-tra-thiet-ke.sh <thư-mục-feature>
#
# Chặn:
#   1. Đầu vào: spec chưa qua checker của spec (entry check = checker phase trước).
#   2. Đầu vào: còn [CẦN-HỎI] "toàn bộ thiết kế" chưa được trả lời.
#   3. tdd.md thiếu mục bắt buộc, hoặc mục bỏ trống mà không ghi "Không áp dụng: <lý do>".
#   4. D-xx thiếu/ sai "Trạng thái" hoặc "tac_gia"; "mở lại" không có lý do; mã trùng.
#   5. "Dựa trên: D-xx" trỏ về D không tồn tại.
#   6. Mục "Ánh xạ YC" bỏ sót YC của spec, hoặc trỏ về YC không có.
#   7. Mode 2: spec "Mức rủi ro: cao" mà không có D-xx nào do người viết.
#   8. Checker LLM: chưa có phat-hien-thiet-ke.md, hoặc còn phát hiện mức Chặn chưa xử lý.
# Cảnh báo (không chặn): artifact lỗi thời.
#
# Checker LLM chỉ được CHẶN, không được DUYỆT: không có file phát hiện là
# KHÔNG ĐẠT, không phải "không có gì để báo".
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai kiem-tra-thiet-ke.sh \
  "0=ĐẠT — được sang phase sau" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

DIR="${1:-.}"
SPEC="$DIR/spec.md"
OQ="$DIR/open-questions.md"
TDD="$DIR/tdd.md"
PH="$DIR/phat-hien-thiet-ke.md"

if [ "$(kc_loai "$DIR")" = "chore" ]; then
  echo "  [LỖI] Loại việc là chore — chore KHÔNG có phase design. Đi thẳng /plan."
  echo ""
  echo "KHÔNG ĐẠT."
  exit 1
fi

for f in "$SPEC" "$OQ" "$TDD"; do
  [ -f "$f" ] || { echo "LỖI: không tìm thấy $f" >&2; exit 2; }
done

n_loi=0
if ! sh "$HERE/kiem-tra-truy-vet.sh" "$DIR" >/dev/null 2>&1; then
  n_loi=1
  echo "  [LỖI] Đầu vào chưa đạt: spec.md/open-questions.md không qua kiem-tra-truy-vet.sh — chạy nó để xem chi tiết."
fi
cd_duyet=$(kc_spec_chua_duyet "$DIR")
if [ -n "$cd_duyet" ]; then
  n_loi=$((n_loi + 1))
  echo "  [LỖI] Đầu vào chưa đạt: $cd_duyet"
fi

PHF="$PH"; PH_THIEU=0
[ -f "$PH" ] || { PH_THIEU=1; PHF=/dev/null; }

awk -v loi_truoc="$n_loi" -v ph_thieu="$PH_THIEU" '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }
  function gia_tri(s) {
    sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s
  }
  function dong_noi_dung(s) {   # dòng có nội dung thật, không phải chỗ giữ chỗ / chú thích
    if (s ~ /^[ \t]*$/) return 0
    if (s ~ /^[ \t]*<!--.*-->[ \t]*$/) return 0
    if (s ~ /^[ \t]*>/) return 0
    t = s; gsub(/[ \t|:-]/, "", t); if (t == "") return 0          # dòng kẻ bảng rỗng
    if (s ~ /^[ \t]*[-|]?[ \t]*<[^>]*>[ \t|]*$/) return 0
    return 1
  }

  BEGIN {
    n_loi = loi_truoc
    muc[1] = "Bối cảnh code hiện có"; muc[2] = "Quyết định"; muc[3] = "Mô hình dữ liệu"
    muc[4] = "Contract"; muc[5] = "Flow"; muc[6] = "Phi chức năng"
    muc[7] = "Chiến lược test"; muc[8] = "Ánh xạ YC"; n_muc = 8
  }

  { sub(/\r$/, "") }
  # Theo tên file: open-questions.md 0 byte (không có điểm mù) không được làm lệch thứ tự.
  FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : (FILENAME == ARGV[2]) ? 2 : (FILENAME == ARGV[3]) ? 3 : 4
           sect = ""; cur = ""; fm = 0 }

  # ---- File 1: spec.md ----
  idx==1 {
    if ($0 ~ /Mức rủi ro[^:]*:/ && rui_ro == "") rui_ro = gia_tri($0)
    if ($0 ~ /^###[ \t]+YC-[0-9]+/) { match($0, /YC-[0-9]+/); c = substr($0, RSTART, RLENGTH); co_yc[c] = 1; ds_yc[++n_yc] = c }
    next
  }

  # ---- File 2: open-questions.md ----
  idx==2 {
    if ($0 ~ /^##[ \t]+YC-[0-9]+/) { match($0, /YC-[0-9]+/); oq = substr($0, RSTART, RLENGTH); ds_oq[++n_oq] = oq; tt[oq] = "mở" }
    if (oq != "" && $0 ~ /Mức ảnh hưởng[^:]*:/) ah[oq] = gia_tri($0)
    if (oq != "" && $0 ~ /Trạng thái[^:]*:/)    tt[oq] = gia_tri($0)
    next
  }

  # ---- File 3: tdd.md ----
  idx==3 {
    if (FNR == 1 && $0 == "---") { fm = 1; next }
    if (fm == 1) { if ($0 == "---") fm = 2; next }

    if ($0 ~ /^##[ \t]/ && $0 !~ /^###/) {
      sect = ""; cur = ""
      for (i = 1; i <= n_muc; i++) if (index($0, muc[i]) > 0) { sect = muc[i]; co_sect[sect] = 1 }
      next
    }
    if (sect == "") next

    if (sect == "Quyết định" && $0 ~ /^###[ \t]+D-[0-9]+/) {
      match($0, /D-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
      if (cur in co_d) loi("Mã quyết định " cur " bị trùng")
      co_d[cur] = 1; ds_d[++n_d] = cur
      co_nd[sect] = 1
      next
    }
    if (sect == "Quyết định" && cur != "") {
      if ($0 ~ /Trạng thái[^:]*:/) d_tt[cur] = gia_tri($0)
      if ($0 ~ /tac_gia[^:]*:/)    d_tg[cur] = gia_tri($0)
      if ($0 ~ /Lý do mở lại[^:]*:/ && gia_tri($0) != "" && gia_tri($0) !~ /^<.*>$/) d_ly_do[cur] = 1
    }

    if (dong_noi_dung($0)) {
      co_nd[sect] = 1
      if ($0 ~ /Không áp dụng/) {
        v = $0; sub(/^.*Không áp dụng[^:]*:?/, "", v); gsub(/[*`]/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v)
        if (v == "" || v ~ /^<.*>$/) loi("tdd.md § " sect ": ghi \"Không áp dụng\" nhưng không có lý do")
      }
    }

    # Dòng "Dựa trên" có thể liệt kê nhiều D: D-01, D-02
    if ($0 ~ /Dựa trên/) { s = $0; while (match(s, /D-[0-9]+/)) { tham_chieu[substr(s, RSTART, RLENGTH)] = 1; s = substr(s, RSTART + RLENGTH) } }

    if (sect == "Ánh xạ YC" && $0 ~ /^[ \t]*\|/) {
      s = $0; while (match(s, /YC-[0-9]+/)) { anh_xa[substr(s, RSTART, RLENGTH)] = 1; s = substr(s, RSTART + RLENGTH) }
    }
    next
  }

  # ---- File 4: phat-hien-thiet-ke.md (có thể là /dev/null) ----
  idx==4 {
    if ($0 ~ /^###[ \t]+PH-[0-9]+/) { match($0, /PH-[0-9]+/); ph = substr($0, RSTART, RLENGTH); ds_ph[++n_ph] = ph; ph_muc[ph] = ""; ph_xl[ph] = "" }
    if (ph != "" && $0 ~ /Mức[^:]*:/ && $0 !~ /Mức ảnh hưởng/) ph_muc[ph] = gia_tri($0)
    if (ph != "" && $0 ~ /Xử lý[^:]*:/) ph_xl[ph] = gia_tri($0)
    next
  }

  END {
    # 2. điểm mù chặn thiết kế
    for (i = 1; i <= n_oq; i++) {
      q = ds_oq[i]
      if (ah[q] == "toàn bộ thiết kế" && tt[q] != "đã trả lời")
        loi(q ": [CẦN-HỎI] ảnh hưởng toàn bộ thiết kế nhưng chưa được trả lời " \
            "(open-questions.md, Trạng thái: " tt[q] "). Phải trả lời trước khi vào design.")
    }

    # 3. mục bắt buộc
    for (i = 1; i <= n_muc; i++) {
      m = muc[i]
      if (!(m in co_sect)) { loi("tdd.md thiếu mục \"## " m "\""); continue }
      if (m == "Quyết định") continue           # mục D-xx được phép rỗng
      if (!(m in co_nd)) loi("tdd.md § " m ": để trống. Không áp dụng thì ghi \"Không áp dụng: <lý do>\".")
    }

    # 4. D-xx
    tt_hl["đề xuất"] = 1; tt_hl["đã duyệt"] = 1; tt_hl["mở lại"] = 1
    for (i = 1; i <= n_d; i++) {
      d = ds_d[i]
      if (!(d in d_tt))            loi(d ": thiếu dòng \"Trạng thái:\" (đề xuất | đã duyệt | mở lại)")
      else if (!(d_tt[d] in tt_hl)) loi(d ": \"Trạng thái: " d_tt[d] "\" không hợp lệ. Chỉ chấp nhận: đề xuất | đã duyệt | mở lại")
      else if (d_tt[d] == "mở lại" && !(d in d_ly_do)) loi(d ": đang \"mở lại\" nhưng thiếu dòng \"Lý do mở lại:\"")
      if (!(d in d_tg))                               loi(d ": thiếu dòng \"tac_gia:\" (nguoi | agent)")
      else if (d_tg[d] != "nguoi" && d_tg[d] != "agent") loi(d ": \"tac_gia: " d_tg[d] "\" không hợp lệ. Chỉ chấp nhận: nguoi | agent")
      if (d_tg[d] == "nguoi") co_nguoi = 1
    }

    # 5. tham chiếu D
    for (d in tham_chieu) if (!(d in co_d)) loi("tdd.md ghi \"Dựa trên: " d "\" nhưng mục Quyết định không có " d)

    # 6. ánh xạ YC hai chiều
    for (i = 1; i <= n_yc; i++) if (!(ds_yc[i] in anh_xa)) loi(ds_yc[i] ": chưa được ánh xạ tới mục nào trong \"Ánh xạ YC\"")
    for (c in anh_xa) if (!(c in co_yc)) loi("\"Ánh xạ YC\" trỏ về " c " nhưng spec.md không có mã này")

    # 7. Mode 2 — chống neo
    if (rui_ro == "cao" && !co_nguoi)
      loi("spec.md có \"Mức rủi ro: cao\" nhưng không D-xx nào có \"tac_gia: nguoi\". " \
          "Người phải phác quyết định trước (Mode 2); agent chỉ phản biện.")

    # 8. checker LLM
    if (ph_thieu == 1) {
      loi("Chưa có phat-hien-thiet-ke.md — checker LLM chưa chạy. Không có file phát hiện là KHÔNG ĐẠT, không phải \"không có gì để báo\".")
    } else {
      for (i = 1; i <= n_ph; i++) {
        p = ds_ph[i]
        if (ph_muc[p] != "Chặn") continue
        x = ph_xl[p]
        if (x == "đã sửa") continue
        if (x ~ /^bác bỏ/) { r = x; sub(/^bác bỏ[ \t]*[—:-]?[ \t]*/, "", r); if (r != "" && r !~ /^<.*>$/) continue
          loi(p ": bác bỏ phát hiện mức Chặn mà không có lý do"); continue }
        loi(p ": phát hiện mức Chặn chưa xử lý (Xử lý: " (x == "" ? "trống" : x) ")")
      }
    }

    print ""
    printf "Tổng: %d YC, %d quyết định D-xx, %d phát hiện LLM — Mức rủi ro: %s\n", n_yc, n_d, n_ph, (rui_ro == "" ? "?" : rui_ro)
    for (i = 1; i <= n_d; i++) printf "  %-6s %s (tac_gia: %s)\n", ds_d[i], d_tt[ds_d[i]], d_tg[ds_d[i]]
    print ""
    if (n_loi > 0) { print "KHÔNG ĐẠT — " n_loi " vi phạm."; exit 1 }
    print "ĐẠT — tdd.md đủ mục, quyết định hợp lệ, không còn phát hiện Chặn."
    print "Bước tiếp: NGƯỜI duyệt từng D-xx (đổi Trạng thái sang \"đã duyệt\"). /plan sẽ chặn nếu còn D chưa duyệt."
  }
' "$SPEC" "$OQ" "$TDD" "$PHF"
ma=$?

cb=$(kc_loi_thoi "$DIR")
if [ -n "$cb" ]; then
  echo ""
  echo "$cb" | while IFS= read -r l; do echo "  [CẢNH BÁO] $l"; done
  echo "  (cảnh báo không chặn ở đây; review sẽ chặn nếu còn)"
fi
exit $ma
