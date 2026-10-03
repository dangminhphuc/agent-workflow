#!/usr/bin/env sh
# Kiểm tra điều kiện ra của phase 01-spec — xem workflow/rules/truy-vet-nguon.md
#
#   sh tools/kiem-tra-truy-vet.sh <thư-mục-feature>
#
# Mã thoát: 0 = đạt, 1 = có vi phạm, 2 = thiếu file đầu vào.

DIR="${1:-.}"
SPEC="$DIR/spec.md"
OQ="$DIR/open-questions.md"

if [ ! -f "$SPEC" ]; then
  echo "LỖI: không tìm thấy $SPEC" >&2
  exit 2
fi
if [ ! -f "$OQ" ]; then
  echo "LỖI: không tìm thấy $OQ" >&2
  echo "      File này bắt buộc tồn tại kể cả khi rỗng." >&2
  echo "      Rỗng = đã rà và không thấy gì. Thiếu = chưa rà." >&2
  exit 2
fi

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

# Entry check: input của spec là intake.md — phải qua checker của phase 00.
n_truoc=0
if ! sh "$HERE/kiem-tra-tiep-nhan.sh" "$DIR" >/dev/null 2>&1; then
  n_truoc=1
  echo "  [LỖI] Đầu vào chưa đạt: intake.md không qua kiem-tra-tiep-nhan.sh — chạy nó để xem chi tiết."
fi
LOAI=$(kc_loai "$DIR")
BV="${TMPDIR:-/tmp}/tv-bv.$$"
: > "$BV"

awk -v loi_truoc="$n_truoc" -v loai="$LOAI" -v ds_bv="$BV" '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }
  BEGIN { n_loi = loi_truoc }
  function gia_tri(s) {          # phần sau dấu ":" đầu tiên, bỏ * ` và khoảng trắng
    sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s
  }

  { sub(/\r$/, "") }

  # Theo tên file, không đếm FNR==1: file 0 byte không có dòng nào nên sẽ làm lệch thứ tự.
  FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : 2 }

  # ---- File 1: open-questions.md ----
  idx==1 {
    if ($0 ~ /^##[ \t]+YC-[0-9]+/) {
      match($0, /YC-[0-9]+/); cur_oq = substr($0, RSTART, RLENGTH)
      co_muc[cur_oq] = 1; ds_oq[++n_oq] = cur_oq; tt_oq[cur_oq] = "mở"
    }
    if (cur_oq != "" && $0 ~ /Giả định tạm/) co_gia_dinh[cur_oq] = 1
    if (cur_oq != "" && $0 ~ /Mức ảnh hưởng[^:]*:/) muc_ah[cur_oq] = gia_tri($0)
    if (cur_oq != "" && $0 ~ /Trạng thái[^:]*:/)    tt_oq[cur_oq] = gia_tri($0)
    if (cur_oq != "" && $0 ~ /Trả lời[^:]*:/) { v = gia_tri($0); if (v != "" && v !~ /^<.*>$/) tra_loi[cur_oq] = 1 }
    next
  }

  # ---- File 2: spec.md ----
  rui_ro == "" && $0 ~ /Mức rủi ro[^:]*:/ { rui_ro = gia_tri($0); co_rui_ro = 1 }
  tt_spec == "" && $0 ~ /Trạng thái spec[^:]*:/ { tt_spec = gia_tri($0); co_tt_spec = 1 }

  $0 ~ /^###[ \t]+YC-[0-9]+/ {
    match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
    if (cur in da_gap) loi("Mã " cur " xuất hiện nhiều lần trong spec.md")
    da_gap[cur] = 1
    thu_tu[++n] = cur
    so_nguon[cur] = 0
    next
  }
  # Heading "###" khác (vd "### Ghi chú") cũng đóng vùng YC — nếu không, dòng Nguồn
  # nằm dưới nó bị tính cho YC phía trên. "####" trở xuống vẫn thuộc YC.
  $0 ~ /^###[ \t]/ { cur = ""; next }
  # Heading cấp 2 kết thúc vùng yêu cầu (ví dụ "## Ngoài phạm vi")
  $0 ~ /^##[ \t]/ { cur = ""; sec = ($0 ~ /^##[ \t]+Tái hiện lỗi/) ? "th" : ""; if (sec == "th") co_th = 1; next }

  # bugfix: mục "## Tái hiện lỗi"
  sec == "th" && /Cách tái hiện[^:]*:/ { v = gia_tri($0); if (v != "" && v !~ /^<.*>$/) th["cach"] = 1 }
  sec == "th" && /Hành vi sai[^:]*:/   { v = gia_tri($0); if (v != "" && v !~ /^<.*>$/) th["sai"] = 1 }
  sec == "th" && /Hành vi đúng[^:]*:/  { v = gia_tri($0); if (v != "" && v !~ /^<.*>$/) th["dung"] = 1 }

  # refactor/perf: loại YC, test bảo vệ, mục tiêu hiệu năng
  cur != "" && /Loại YC[^:]*:/ { loai_yc[cur] = gia_tri($0) }
  cur != "" && /Được bảo vệ bởi[^:]*:/ {
    s = $0; sub(/^[^:]*:/, "", s)
    while (match(s, /`[^`]+`/)) { bv[cur]++; print cur "\t" substr(s, RSTART+1, RLENGTH-2) > ds_bv; s = substr(s, RSTART+RLENGTH) }
  }
  cur != "" && /Mục tiêu[^:]*:/ { v = gia_tri($0); if (v ~ /[0-9]/) co_mt[cur] = 1 }

  cur != "" && $0 ~ /^[ \t]*-[ \t]*\*{0,2}Nguồn/ {
    so_nguon[cur]++
    dong = $0
    sub(/^.*Nguồn[^:]*:[ \t]*/, "", dong)
    if (match(dong, /\[[^]]+\]/)) {
      nhan[cur] = substr(dong, RSTART + 1, RLENGTH - 2)
    } else {
      nhan[cur] = ""
    }
  }

  END {
    hop_le["CONFLUENCE"]=1; hop_le["JIRA"]=1; hop_le["FILE"]=1
    hop_le["SUY-RA"]=1;     hop_le["CẦN-HỎI"]=1
    ah_hop_le["toàn bộ thiết kế"]=1; ah_hop_le["cục bộ"]=1

    if (!co_rui_ro)
      loi("spec.md thiếu dòng \"Mức rủi ro:\" (cao | thường). `design` cần nó để biết có phải chạy Mode 2.")
    else if (rui_ro != "cao" && rui_ro != "thường")
      loi("\"Mức rủi ro: " rui_ro "\" không hợp lệ. Chỉ chấp nhận: cao | thường")

    # Người duyệt spec bằng cách đổi dòng này; design (và plan của chore) chặn khi chưa duyệt.
    if (!co_tt_spec)
      loi("spec.md thiếu dòng \"Trạng thái spec:\" (đề xuất | đã duyệt). Agent ghi \"đề xuất\"; chỉ người đổi sang \"đã duyệt\".")
    else if (tt_spec != "đề xuất" && tt_spec != "đã duyệt")
      loi("\"Trạng thái spec: " tt_spec "\" không hợp lệ. Chỉ chấp nhận: đề xuất | đã duyệt")

    if (n == 0) loi("spec.md không có yêu cầu nào (không thấy heading \"### YC-NNN\")")

    for (i = 1; i <= n; i++) {
      c = thu_tu[i]
      if (so_nguon[c] == 0) {
        loi(c ": thiếu dòng \"Nguồn:\". Yêu cầu không có nhãn = fail.")
        continue
      }
      if (so_nguon[c] > 1) {
        loi(c ": có " so_nguon[c] " dòng \"Nguồn:\", phải đúng một.")
        continue
      }
      t = nhan[c]
      if (t == "") {
        loi(c ": dòng \"Nguồn:\" không có nhãn trong ngoặc vuông.")
        continue
      }
      if (!(t in hop_le)) {
        loi(c ": nhãn [" t "] không hợp lệ. Chỉ chấp nhận: " \
            "[CONFLUENCE] [JIRA] [FILE] [SUY-RA] [CẦN-HỎI]")
        continue
      }
      if (t == "CẦN-HỎI") {
        if (!(c in co_muc))
          loi(c ": gắn [CẦN-HỎI] nhưng open-questions.md không có mục \"## " c "\". " \
              "Gắn nhãn mà không hỏi ai thì nhãn vô nghĩa.")
        else if (!(c in co_gia_dinh))
          loi(c ": mục trong open-questions.md thiếu dòng \"Giả định tạm\". " \
              "Không có giả định tạm thì phase sau không đi tiếp được.")
        else if (!(c in muc_ah))
          loi(c ": mục trong open-questions.md thiếu dòng \"Mức ảnh hưởng:\" " \
              "(toàn bộ thiết kế | cục bộ).")
        else if (!(muc_ah[c] in ah_hop_le))
          loi(c ": \"Mức ảnh hưởng: " muc_ah[c] "\" không hợp lệ. Chỉ chấp nhận: toàn bộ thiết kế | cục bộ")
      }
      dem_nhan[t]++
    }

    # ---- open-questions.md phải khớp spec.md ----
    for (i = 1; i <= n_oq; i++) {
      q = ds_oq[i]; s = tt_oq[q]
      if (!(q in da_gap)) {
        loi("open-questions.md có mục \"## " q "\" nhưng spec.md không có " q ". Xoá mục, hoặc sửa mã cho khớp.")
        continue
      }
      if (s != "mở" && s != "đã trả lời") {
        loi(q ": \"Trạng thái: " s "\" trong open-questions.md không hợp lệ. Chỉ chấp nhận: mở | đã trả lời")
        continue
      }
      if (s == "đã trả lời" && !(q in tra_loi))
        loi(q ": điểm mù ghi \"đã trả lời\" nhưng dòng \"Trả lời:\" còn trống.")
      else if (s == "đã trả lời" && nhan[q] == "CẦN-HỎI")
        loi(q ": điểm mù đã trả lời nhưng spec.md vẫn gắn [CẦN-HỎI]. Đổi nhãn nguồn sang nơi chứa câu trả lời " \
            "(vd `[FILE]` open-questions.md § " q ").")
      else if (s == "mở" && so_nguon[q] == 1 && nhan[q] != "CẦN-HỎI")
        loi(q ": spec.md đã gắn nguồn [" nhan[q] "] nhưng điểm mù trong open-questions.md vẫn \"mở\". " \
            "Hoặc ghi câu trả lời và đổi sang \"đã trả lời\", hoặc trả nhãn về [CẦN-HỎI].")
    }

    # ---- luật theo loại việc ----
    if (loai == "bugfix") {
      if (!co_th) loi("bugfix: spec thiếu mục \"## Tái hiện lỗi\" (Cách tái hiện, Hành vi sai, Hành vi đúng)")
      else {
        if (!("cach" in th)) loi("bugfix: \"Tái hiện lỗi\" thiếu \"Cách tái hiện:\"")
        if (!("sai" in th))  loi("bugfix: \"Tái hiện lỗi\" thiếu \"Hành vi sai:\"")
        if (!("dung" in th)) loi("bugfix: \"Tái hiện lỗi\" thiếu \"Hành vi đúng:\"")
      }
    }
    if (loai == "refactor" || loai == "perf") {
      hl_yc["giữ nguyên"] = 1; hl_yc["cấu trúc"] = 1; ds = "giữ nguyên | cấu trúc"
      if (loai == "perf") { hl_yc["hiệu năng"] = 1; ds = ds " | hiệu năng" }
      for (i = 1; i <= n; i++) {
        c = thu_tu[i]; lt = loai_yc[c]
        if (lt == "")              { loi(c ": " loai " — thiếu \"Loại YC:\" (" ds "). Không được có YC hành vi mới."); continue }
        if (!(lt in hl_yc))        { loi(c ": \"Loại YC: " lt "\" không hợp lệ cho " loai " (" ds ")"); continue }
        if (lt == "giữ nguyên" && !(c in bv)) loi(c ": YC giữ nguyên phải có \"Được bảo vệ bởi: `<file test>`\" — test có sẵn trên base của việc")
        if (lt == "hiệu năng" && !(c in co_mt)) loi(c ": YC hiệu năng phải có \"Mục tiêu:\" kèm số liệu")
        if (lt == "hiệu năng") n_hn++
      }
      if (loai == "perf" && n_hn == 0) loi("perf: cần ít nhất một YC \"Loại YC: hiệu năng\"")
    }

    print ""
    print "Tổng: " n " yêu cầu — Loại việc: " (loai == "" ? "?" : loai) " — Mức rủi ro: " (co_rui_ro ? rui_ro : "?") \
          " — Trạng thái spec: " (co_tt_spec ? tt_spec : "?")
    for (t in dem_nhan) printf "  [%s] %d\n", t, dem_nhan[t]
    if (n_loi > 0) exit 1
  }
' "$OQ" "$SPEC"
ma=$?

# Test bảo vệ YC giữ nguyên phải CÓ SẴN trên base của việc (điểm rẽ nhánh): test thêm trong chính việc
# refactor không chứng minh được hành vi cũ.
n_bv=0
if [ -s "$BV" ]; then
  MB=$(kc_mb "$DIR")
  while IFS="$(printf '\t')" read -r yc f; do
    if [ -z "$MB" ]; then
      echo "  [LỖI] $yc: không xác định được base để kiểm \"$f\" (dòng Base: trong intake.md, hoặc nhanh_goc trong conventions.md)"; n_bv=$((n_bv + 1))
    elif ! git -C "$DIR" cat-file -e "$MB:$f" 2>/dev/null; then
      echo "  [LỖI] $yc: \"$f\" không tồn tại trên base của việc — vùng này chưa có test bảo vệ. Viết test thành việc riêng trước, hoặc thu hẹp phạm vi."
      n_bv=$((n_bv + 1))
    fi
  done < "$BV"
fi
rm -f "$BV"

echo ""
if [ "$ma" -ne 0 ] || [ "$n_bv" -gt 0 ]; then
  echo "KHÔNG ĐẠT."
  exit 1
fi
echo "ĐẠT — mọi yêu cầu đều truy được về nguồn."
