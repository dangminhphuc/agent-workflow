#!/usr/bin/env sh
# Kiểm tra điều kiện ra của phase 02-design.
#
#   aw check design <thư-mục-feature>
#
# Chặn:
#   1. Đầu vào: spec chưa qua checker của spec (entry check = checker phase trước).
#   2. Đầu vào: còn điểm mù "Blocking: blocking" chưa được trả lời.
#   3. tdd.md thiếu mục bắt buộc, hoặc mục bỏ trống mà không ghi "Not applicable: <lý do>".
#   4. D-xx thiếu/ sai ô duyệt (tools/lib/approval-tick.sh) hoặc "Author"; mã trùng; D đã
#      tick mà nội dung đổi sau đó (dấu duyệt không khớp).
#   5. "Based on: D-xx" trỏ về D không tồn tại.
#   6. Mục "YC mapping" bỏ sót YC của spec, hoặc trỏ về YC không có.
#   7. Mode 2: spec "Risk: high" mà không có D-xx nào do người viết.
#   8. Checker LLM: chưa có design-findings.md, hoặc còn phát hiện mức Chặn chưa xử lý.
#   9. File khai ở rules_design (conventions.md) không có hoặc chưa commit.
#  10. D-xx: "Promote:" khác adr | no; Promote: adr thiếu Scope; Supersedes sai dạng, trỏ về
#      ADR không có hoặc không còn accepted, hay thay ADR mà không nâng ADR mới.
# Cảnh báo (không chặn): artifact lỗi thời.
#
# Checker LLM chỉ được CHẶN, không được DUYỆT: không có file phát hiện là
# KHÔNG ĐẠT, không phải "không có gì để báo".
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai check-design.sh \
  "0=ĐẠT — được sang phase sau" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/commands.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/approval-tick.sh"
. "$HERE/lib/adr.sh"

DIR="${1:-.}"
SPEC="$DIR/spec.md"
OQ="$DIR/open-questions.md"
TDD="$DIR/tdd.md"
PH="$DIR/design-findings.md"

if [ "$(kc_loai "$DIR")" = "chore" ]; then
  echo "  [LỖI] Loại việc là chore — chore KHÔNG có phase design. Đi thẳng /aw-plan."
  echo ""
  echo "KHÔNG ĐẠT."
  exit 1
fi

for f in "$SPEC" "$OQ" "$TDD"; do
  [ -f "$f" ] || { echo "LỖI: không tìm thấy $f" >&2; exit 2; }
done

n_loi=0
if ! sh "$HERE/check-spec.sh" "$DIR" >/dev/null 2>&1; then
  n_loi=1
  echo "  [LỖI] Đầu vào chưa đạt: spec.md/open-questions.md không qua aw check spec — chạy nó để xem chi tiết."
fi
cd_duyet=$(kc_spec_chua_duyet "$DIR")
if [ -n "$cd_duyet" ]; then
  n_loi=$((n_loi + 1))
  echo "  [LỖI] Đầu vào chưa đạt: $cd_duyet"
fi
# Điểm mù mức "blocking": thiết kế trên một giả định sẽ lật cả hướng đi là phí công.
dm=$(kc_diem_mu_mo "$DIR" "blocking")
if [ -n "$dm" ]; then
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    n_loi=$((n_loi + 1)); echo "  [LỖI] $l"
  done <<EOF
$dm
EOF
fi
qtl=$(kc_quy_tac_loi "$DIR" design)
while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [LỖI] $l"; }; done <<EOF
$qtl
EOF

# Ô duyệt từng D-xx — trạng thái lấy từ thư viện chung, không tự đọc lại.
kld=$(kc_loi_duyet "$TDD" tdd)
while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [LỖI] $l"; }; done <<EOF
$kld
EOF
# Trường người quyết trong D: Promote / Scope / Supersedes (ADR — tools/lib/adr.sh).
alt=$(adr_loi_truong "$DIR")
while IFS= read -r l; do [ -n "$l" ] && { n_loi=$((n_loi + 1)); echo "  [LỖI] $l"; }; done <<EOF
$alt
EOF
DTT=$(dy_trang_thai "$TDD" tdd | awk -F'|' '$1 == "S" { printf "%s=%s;", $2, $3 }')

PHF="$PH"; PH_THIEU=0
[ -f "$PH" ] || { PH_THIEU=1; PHF=/dev/null; }

awk -v loi_truoc="$n_loi" -v ph_thieu="$PH_THIEU" -v dtt="$DTT" '
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
    n_kv = split(dtt, kv, ";"); for (i = 1; i <= n_kv; i++) if (kv[i] != "") { split(kv[i], kv2, "="); d_tt[kv2[1]] = kv2[2] }
    muc[1] = "Existing code"; muc[2] = "Decisions"; muc[3] = "Data model"
    muc[4] = "Contract"; muc[5] = "Flow"; muc[6] = "Non-functional"
    muc[7] = "Test strategy"; muc[8] = "YC mapping"; n_muc = 8
  }

  { sub(/\r$/, "") }
  # Theo tên file, không đếm FNR==1: file 0 byte không có dòng nào nên sẽ làm lệch thứ tự.
  FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : (FILENAME == ARGV[2]) ? 2 : 3
           sect = ""; cur = ""; fm = 0 }

  # ---- File 1: spec.md ----
  idx==1 {
    if ($0 ~ /^[ \t]*-[ \t]*\**Risk\**:/ && rui_ro == "") rui_ro = gia_tri($0)
    if ($0 ~ /^###[ \t]+YC-[0-9]+/) { match($0, /YC-[0-9]+/); c = substr($0, RSTART, RLENGTH); co_yc[c] = 1; ds_yc[++n_yc] = c }
    next
  }

  # ---- File 2: tdd.md ----
  idx==2 {
    if (FNR == 1 && $0 == "---") { fm = 1; next }
    if (fm == 1) { if ($0 == "---") fm = 2; next }

    if ($0 ~ /^##[ \t]/ && $0 !~ /^###/) {
      sect = ""; cur = ""
      for (i = 1; i <= n_muc; i++) if (index($0, muc[i]) > 0) { sect = muc[i]; co_sect[sect] = 1 }
      next
    }
    if (sect == "") next

    if (sect == "Decisions" && $0 ~ /^###[ \t]+D-[0-9]+/) {
      match($0, /D-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
      if (cur in co_d) loi("Mã quyết định " cur " bị trùng")
      co_d[cur] = 1; ds_d[++n_d] = cur
      co_nd[sect] = 1
      next
    }
    if (sect == "Decisions" && cur != "") {
      if ($0 ~ /^[ \t]*-[ \t]*\**Author\**:/) d_tg[cur] = gia_tri($0)
    }

    if (dong_noi_dung($0)) {
      co_nd[sect] = 1
      if ($0 ~ /Not applicable/) {
        v = $0; sub(/^.*Not applicable[^:]*:?/, "", v); gsub(/[*`]/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v)
        if (v == "" || v ~ /^<.*>$/) loi("tdd.md § " sect ": ghi \"Not applicable\" nhưng không có lý do")
      }
    }

    # Dòng "Based on" có thể liệt kê nhiều D: D-01, D-02
    if ($0 ~ /Based on/) { s = $0; while (match(s, /D-[0-9]+/)) { tham_chieu[substr(s, RSTART, RLENGTH)] = 1; s = substr(s, RSTART + RLENGTH) } }

    if (sect == "YC mapping" && $0 ~ /^[ \t]*\|/) {
      s = $0; while (match(s, /YC-[0-9]+/)) { anh_xa[substr(s, RSTART, RLENGTH)] = 1; s = substr(s, RSTART + RLENGTH) }
    }
    next
  }

  # ---- File 3: design-findings.md (có thể là /dev/null) ----
  idx==3 {
    if ($0 ~ /^###[ \t]+PH-[0-9]+/) { match($0, /PH-[0-9]+/); ph = substr($0, RSTART, RLENGTH); ds_ph[++n_ph] = ph; ph_muc[ph] = ""; ph_xl[ph] = "" }
    if (ph != "" && $0 ~ /Mức[^:]*:/) ph_muc[ph] = gia_tri($0)
    if (ph != "" && $0 ~ /Xử lý[^:]*:/) ph_xl[ph] = gia_tri($0)
    next
  }

  END {
    # 3. mục bắt buộc
    for (i = 1; i <= n_muc; i++) {
      m = muc[i]
      if (!(m in co_sect)) { loi("tdd.md thiếu mục \"## " m "\""); continue }
      if (m == "Decisions") continue           # mục D-xx được phép rỗng
      if (!(m in co_nd)) loi("tdd.md § " m ": để trống. Không áp dụng thì ghi \"Not applicable: <lý do>\".")
    }

    # 4. D-xx
    # Ô duyệt (thiếu, sai dạng, đổi sau duyệt) đã báo ở trên — thư viện approval-tick.sh.
    for (i = 1; i <= n_d; i++) {
      d = ds_d[i]
      if (!(d in d_tg))                               loi(d ": thiếu dòng \"Author:\" (human | agent)")
      else if (d_tg[d] != "human" && d_tg[d] != "agent") loi(d ": \"Author: " d_tg[d] "\" không hợp lệ. Chỉ chấp nhận: human | agent")
      if (d_tg[d] == "human") co_nguoi = 1
    }

    # 5. tham chiếu D
    for (d in tham_chieu) if (!(d in co_d)) loi("tdd.md ghi \"Based on: " d "\" nhưng mục Decisions không có " d)

    # 6. ánh xạ YC hai chiều
    for (i = 1; i <= n_yc; i++) if (!(ds_yc[i] in anh_xa)) loi(ds_yc[i] ": chưa được ánh xạ tới mục nào trong \"YC mapping\"")
    for (c in anh_xa) if (!(c in co_yc)) loi("\"YC mapping\" trỏ về " c " nhưng spec.md không có mã này")

    # 7. Mode 2 — chống neo
    if (rui_ro == "high" && !co_nguoi)
      loi("spec.md có \"Risk: high\" nhưng không D-xx nào có \"Author: human\". " \
          "Người phải phác quyết định trước (Mode 2); agent chỉ phản biện.")

    # 8. checker LLM
    if (ph_thieu == 1) {
      loi("Chưa có design-findings.md — checker LLM chưa chạy. Không có file phát hiện là KHÔNG ĐẠT, không phải \"không có gì để báo\".")
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
    printf "Tổng: %d YC, %d quyết định D-xx, %d phát hiện LLM — Risk: %s\n", n_yc, n_d, n_ph, (rui_ro == "" ? "?" : rui_ro)
    for (i = 1; i <= n_d; i++) printf "  %-6s %s (Author: %s)\n", ds_d[i], d_tt[ds_d[i]], d_tg[ds_d[i]]
    print ""
    if (n_loi > 0) { print "KHÔNG ĐẠT — " n_loi " vi phạm."; exit 1 }
    print "ĐẠT — tdd.md đủ mục, quyết định hợp lệ, không còn phát hiện Chặn."
    print "Bước tiếp: NGƯỜI duyệt từng D-xx (tick ô \"Approved by human\"). /aw-plan sẽ chặn nếu còn D chưa duyệt."
  }
' "$SPEC" "$TDD" "$PHF"
ma=$?

cb=$(kc_loi_thoi "$DIR")
if [ -n "$cb" ]; then
  echo ""
  echo "$cb" | while IFS= read -r l; do echo "  [CẢNH BÁO] $l"; done
  echo "  (cảnh báo không chặn ở đây; review sẽ chặn nếu còn)"
fi
exit $ma
