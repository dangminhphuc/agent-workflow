#!/usr/bin/env sh
# Kiểm tra điều kiện ra của phase 01-spec — xem workflow/rules/truy-vet-nguon.md
#
#   aw check spec <thư-mục-feature>
#
# Chặn thêm: file khai ở rules_spec (conventions.md) không có hoặc chưa commit.
#            YC "Promote:" sai dạng ID, nguồn [INFERRED]/[OPEN-QUESTION], hay ID đã có ở việc khác.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/md.sh"
. "$HERE/lib/bang-lenh.sh"
. "$HERE/lib/kiem-cheo.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/duyet.sh"
. "$HERE/lib/adr.sh"
. "$HERE/lib/luat.sh"
. "$HERE/lib/ket-qua.sh"
kq_khai kiem-tra-truy-vet.sh \
  "0=ĐẠT — được sang phase sau" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"

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

# Entry check: input của spec là intake.md — phải qua checker của phase 00.
n_truoc=0
if ! sh "$HERE/kiem-tra-tiep-nhan.sh" "$DIR" >/dev/null 2>&1; then
  n_truoc=1
  echo "  [LỖI] Đầu vào chưa đạt: intake.md không qua aw check intake — chạy nó để xem chi tiết."
fi
qtl=$(kc_quy_tac_loi "$DIR" spec)
while IFS= read -r l; do [ -n "$l" ] && { n_truoc=$((n_truoc + 1)); echo "  [LỖI] $l"; }; done <<EOF
$qtl
EOF
# Ô duyệt spec: dạng, vị trí, và nội dung có đổi sau khi người tick không.
kld=$(kc_loi_duyet "$SPEC" spec)
while IFS= read -r l; do [ -n "$l" ] && { n_truoc=$((n_truoc + 1)); echo "  [LỖI] $l"; }; done <<EOF
$kld
EOF
# YC người chọn nâng thành luật bền (Promote: BR-…) — tools/lib/luat.sh.
lsl=$(luat_loi_spec "$DIR")
while IFS= read -r l; do [ -n "$l" ] && { n_truoc=$((n_truoc + 1)); echo "  [LỖI] $l"; }; done <<EOF
$lsl
EOF
TT_SPEC=$(dy_trang_thai "$SPEC" spec | awk -F'|' '$1 == "S" { print $3; exit }')
LOAI=$(kc_loai "$DIR")
BV="${TMPDIR:-/tmp}/tv-bv.$$"
: > "$BV"

awk -v loi_truoc="$n_truoc" -v loai="$LOAI" -v ds_bv="$BV" -v tt_spec="${TT_SPEC:-?}" '
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
      co_muc[cur_oq] = 1; ds_oq[++n_oq] = cur_oq; tt_oq[cur_oq] = "open"
    }
    if (cur_oq != "" && $0 ~ /^[ \t]*-[ \t]*\**Assumption\**:/) co_gia_dinh[cur_oq] = 1
    if (cur_oq != "" && $0 ~ /^[ \t]*-[ \t]*\**Blocking\**:/) muc_ch[cur_oq] = gia_tri($0)
    if (cur_oq != "" && $0 ~ /^[ \t]*-[ \t]*[*]*(Mức chặn|Mức ảnh hưởng)[^:]*:/) muc_cu[cur_oq] = gia_tri($0)
    if (cur_oq != "" && $0 ~ /^[ \t]*-[ \t]*\**Status\**:/) tt_oq[cur_oq] = gia_tri($0)
    if (cur_oq != "" && $0 ~ /^[ \t]*-[ \t]*\**Answer\**:/) { v = gia_tri($0); if (v != "" && v !~ /^<.*>$/) tra_loi[cur_oq] = 1 }
    next
  }

  # ---- File 2: spec.md ----
  # Comment HTML nhiều dòng trong mẫu (khối refactor/perf, bugfix, Glossary) không phải
  # nội dung: không bỏ qua thì "## Reproduction" hay "Target:" trong comment được tính.
  trong_cmt { if ($0 ~ /-->/) trong_cmt = 0; next }
  $0 ~ /^[ \t]*<!--/ && $0 !~ /-->/ { trong_cmt = 1; next }
  $0 ~ /^[ \t]*<!--.*-->[ \t]*$/ { next }

  rui_ro == "" && $0 ~ /^[ \t]*-[ \t]*\**Risk\**:/ { rui_ro = gia_tri($0); co_rui_ro = 1 }

  $0 ~ /^###[ \t]+YC-[0-9]+/ {
    match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
    if (cur in da_gap) loi("Mã " cur " xuất hiện nhiều lần trong spec.md")
    da_gap[cur] = 1
    thu_tu[++n] = cur
    so_nguon[cur] = 0
    next
  }
  # Heading "###" khác (vd "### Ghi chú") cũng đóng vùng YC — nếu không, dòng Source
  # nằm dưới nó bị tính cho YC phía trên. "####" trở xuống vẫn thuộc YC.
  $0 ~ /^###[ \t]/ { cur = ""; next }
  # Heading cấp 2 kết thúc vùng yêu cầu (ví dụ "## Out of scope")
  $0 ~ /^##[ \t]/ {
    cur = ""; sec = ""
    if ($0 ~ /^##[ \t]+Reproduction/)      { sec = "th";  co_th = 1 }
    if ($0 ~ /^##[ \t]+Out of scope/)      { sec = "npv"; co_npv = 1 }
    if ($0 ~ /^##[ \t]+Constraints/)       { sec = "rb";  co_rb = 1 }
    if ($0 ~ /^##[ \t]+Source conflicts/)  { sec = "mt";  co_mt_muc = 1 }
    next
  }

  # "Out of scope", "Constraints": phải có nội dung thật — dòng chữ không phải chỗ giữ chỗ
  # "<...>". Không có gì thì ghi thẳng "Không có …" — rỗng và chưa rà là hai chuyện khác nhau.
  (sec == "npv" || sec == "rb") && $0 !~ /^[ \t]*$/ {
    v = $0; sub(/^[ \t]*[-*][ \t]*/, "", v)
    if (v !~ /^</) noi_dung[sec] = 1
  }

  # "Source conflicts": mỗi dòng bảng phải được xử lý bằng điểm mù hoặc nguồn đã chốt.
  sec == "mt" && /Không phát hiện mâu thuẫn/ && $0 !~ /^[ \t]*</ { mt_khong = 1 }
  sec == "mt" && $0 ~ /^[ \t]*\|/ {
    if ($0 ~ /^[ \t]*\|[- :|]+$/) next                     # dòng kẻ
    n_o = split($0, o, "|")
    a = o[2]; b = o[3]; x = o[4]
    gsub(/^[ \t]+|[ \t]+$/, "", a); gsub(/^[ \t]+|[ \t]+$/, "", b); gsub(/^[ \t]+|[ \t]+$/, "", x)
    if (a == "Source A says") next                           # dòng tiêu đề
    if (a == "" && b == "" && x == "") next                 # dòng mẫu trống
    n_mt++
    ten = (a == "" ? "dòng " n_mt : "\"" a "\"")
    if (match(x, /YC-[0-9]+/)) {
      q = substr(x, RSTART, RLENGTH)
      if (!(q in co_muc)) loi("Mâu thuẫn " ten ": trỏ tới " q " nhưng open-questions.md không có mục \"## " q "\"")
    } else if (x !~ /\[(CONFLUENCE|JIRA|FILE)\]/) {
      loi("Mâu thuẫn " ten ": cột \"Resolution\" phải trỏ tới điểm mù (open-questions.md § YC-NNN) hoặc nguồn đã chốt " \
          "([CONFLUENCE] [JIRA] [FILE]). Agent không tự phân xử mâu thuẫn nghiệp vụ.")
    }
    next
  }

  # bugfix: mục "## Reproduction"
  sec == "th" && /^[ \t]*-[ \t]*\**Steps to reproduce\**:/ { v = gia_tri($0); if (v != "" && v !~ /^<.*>$/) th["cach"] = 1 }
  sec == "th" && /^[ \t]*-[ \t]*\**Actual behavior\**:/   { v = gia_tri($0); if (v != "" && v !~ /^<.*>$/) th["sai"] = 1 }
  sec == "th" && /^[ \t]*-[ \t]*\**Expected behavior\**:/ { v = gia_tri($0); if (v != "" && v !~ /^<.*>$/) th["dung"] = 1 }

  # refactor/perf: loại YC, test bảo vệ, mục tiêu hiệu năng
  cur != "" && /^[ \t]*-[ \t]*\**Type\**:/ { loai_yc[cur] = gia_tri($0) }
  cur != "" && /^[ \t]*-[ \t]*\**Protected by\**:/ {
    s = $0; sub(/^[^:]*:/, "", s)
    while (match(s, /`[^`]+`/)) { bv[cur]++; print cur "\t" substr(s, RSTART+1, RLENGTH-2) > ds_bv; s = substr(s, RSTART+RLENGTH) }
  }
  cur != "" && /^[ \t]*-[ \t]*\**Priority\**:/ { uu_tien[cur] = gia_tri($0) }
  # Tiêu chí chấp nhận: checkbox "- [ ] …" có nội dung thật, không phải "<...>".
  cur != "" && /^[ \t]*-[ \t]*\[[ xX]\][ \t]*/ {
    v = $0; sub(/^[ \t]*-[ \t]*\[[ xX]\][ \t]*/, "", v)
    if (v != "" && v !~ /^<.*>$/) so_tc[cur]++
  }
  cur != "" && /^[ \t]*-[ \t]*\**Target\**:/ { v = gia_tri($0); if (v ~ /[0-9]/) co_mt[cur] = 1 }

  cur != "" && $0 ~ /^[ \t]*-[ \t]*\**Source\**:/ {
    so_nguon[cur]++
    dong = $0
    sub(/^[^:]*:[ \t]*/, "", dong)
    if (match(dong, /\[[^]]+\]/)) {
      nhan[cur] = substr(dong, RSTART + 1, RLENGTH - 2)
    } else {
      nhan[cur] = ""
    }
  }

  END {
    hop_le["CONFLUENCE"]=1; hop_le["JIRA"]=1; hop_le["FILE"]=1
    hop_le["INFERRED"]=1;   hop_le["OPEN-QUESTION"]=1
    mc_hop_le["blocking"]=1; mc_hop_le["review-blocking"]=1; mc_hop_le["non-blocking"]=1

    if (!co_rui_ro)
      loi("spec.md thiếu dòng \"Risk:\" (high | normal). `design` cần nó để biết có phải chạy Mode 2.")
    else if (rui_ro != "high" && rui_ro != "normal")
      loi("\"Risk: " rui_ro "\" không hợp lệ. Chỉ chấp nhận: high | normal")

    if (n == 0) loi("spec.md không có yêu cầu nào (không thấy heading \"### YC-NNN\")")

    # Các mục bắt buộc ngoài YC — thiếu mục thì không phân biệt được "không có" với "chưa rà".
    if (!co_npv)         loi("spec.md thiếu mục \"## Out of scope\"")
    else if (!("npv" in noi_dung))
      loi("\"## Out of scope\" rỗng hoặc còn chỗ giữ chỗ. Không có gì thì ghi \"Không có.\"")
    if (!co_rb)          loi("spec.md thiếu mục \"## Constraints & dependencies\"")
    else if (!("rb" in noi_dung))
      loi("\"## Constraints & dependencies\" rỗng hoặc còn chỗ giữ chỗ. Không có thì ghi \"Không có ràng buộc hay phụ thuộc ngoài.\"")
    if (!co_mt_muc)      loi("spec.md thiếu mục \"## Source conflicts\"")
    else if (n_mt == 0 && !mt_khong)
      loi("\"## Source conflicts\" không có dòng nào. Không có thì ghi \"Không phát hiện mâu thuẫn.\"")

    for (i = 1; i <= n; i++) {
      c = thu_tu[i]
      if (so_nguon[c] == 0) {
        loi(c ": thiếu dòng \"Source:\". Yêu cầu không có nhãn = fail.")
        continue
      }
      if (so_nguon[c] > 1) {
        loi(c ": có " so_nguon[c] " dòng \"Source:\", phải đúng một.")
        continue
      }
      if (!(c in so_tc))
        loi(c ": thiếu tiêu chí chấp nhận (dòng \"- [ ] …\" quan sát được từ bên ngoài). Không có thì review không kết luận được.")
      if (!(c in uu_tien))
        loi(c ": thiếu dòng \"Priority:\" (must | should). Nguồn không nói thì ghi must.")
      else if (uu_tien[c] != "must" && uu_tien[c] != "should")
        loi(c ": \"Priority: " uu_tien[c] "\" không hợp lệ. Chỉ chấp nhận: must | should")
      t = nhan[c]
      if (t == "") {
        loi(c ": dòng \"Source:\" không có nhãn trong ngoặc vuông.")
        continue
      }
      if (!(t in hop_le)) {
        loi(c ": nhãn [" t "] không hợp lệ. Chỉ chấp nhận: " \
            "[CONFLUENCE] [JIRA] [FILE] [INFERRED] [OPEN-QUESTION]")
        continue
      }
      if (t == "OPEN-QUESTION") {
        if (!(c in co_muc))
          loi(c ": gắn [OPEN-QUESTION] nhưng open-questions.md không có mục \"## " c "\". " \
              "Gắn nhãn mà không hỏi ai thì nhãn vô nghĩa.")
        else if (!(c in co_gia_dinh))
          loi(c ": mục trong open-questions.md thiếu dòng \"Assumption:\". " \
              "Không có giả định tạm thì phase sau không đi tiếp được.")
        else if (!(c in muc_ch) && (c in muc_cu))
          loi(c ": nhãn cũ (\"Mức chặn\" / \"Mức ảnh hưởng\") đã đổi thành \"Blocking: blocking | review-blocking | non-blocking\". " \
              "chặn / toàn bộ thiết kế → blocking; chặn review → review-blocking; không chặn → non-blocking; cục bộ → NGƯỜI chọn.")
        else if (!(c in muc_ch))
          loi(c ": mục trong open-questions.md thiếu dòng \"Blocking:\" " \
              "(blocking | review-blocking | non-blocking).")
        else if (!(muc_ch[c] in mc_hop_le))
          loi(c ": \"Blocking: " muc_ch[c] "\" không hợp lệ. Chỉ chấp nhận: blocking | review-blocking | non-blocking")
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
      if (s != "open" && s != "answered") {
        loi(q ": \"Status: " s "\" trong open-questions.md không hợp lệ. Chỉ chấp nhận: open | answered")
        continue
      }
      if (s == "answered" && !(q in tra_loi))
        loi(q ": điểm mù ghi \"answered\" nhưng dòng \"Answer:\" còn trống.")
      else if (s == "answered" && nhan[q] == "OPEN-QUESTION")
        loi(q ": điểm mù đã trả lời nhưng spec.md vẫn gắn [OPEN-QUESTION]. Đổi nhãn nguồn sang nơi chứa câu trả lời " \
            "(vd `[FILE]` open-questions.md § " q ").")
      else if (s == "open" && so_nguon[q] == 1 && nhan[q] != "OPEN-QUESTION")
        loi(q ": spec.md đã gắn nguồn [" nhan[q] "] nhưng điểm mù trong open-questions.md vẫn \"open\". " \
            "Hoặc ghi câu trả lời và đổi sang \"answered\", hoặc trả nhãn về [OPEN-QUESTION].")
    }

    # ---- luật theo loại việc ----
    if (loai == "bugfix") {
      if (!co_th) loi("bugfix: spec thiếu mục \"## Reproduction\" (Steps to reproduce, Actual behavior, Expected behavior)")
      else {
        if (!("cach" in th)) loi("bugfix: \"Reproduction\" thiếu \"Steps to reproduce:\"")
        if (!("sai" in th))  loi("bugfix: \"Reproduction\" thiếu \"Actual behavior:\"")
        if (!("dung" in th)) loi("bugfix: \"Reproduction\" thiếu \"Expected behavior:\"")
      }
    }
    if (loai == "refactor" || loai == "perf") {
      hl_yc["preserve"] = 1; hl_yc["structural"] = 1; ds = "preserve | structural"
      if (loai == "perf") { hl_yc["performance"] = 1; ds = ds " | performance" }
      for (i = 1; i <= n; i++) {
        c = thu_tu[i]; lt = loai_yc[c]
        if (lt == "")              { loi(c ": " loai " — thiếu \"Type:\" (" ds "). Không được có YC hành vi mới."); continue }
        if (!(lt in hl_yc))        { loi(c ": \"Type: " lt "\" không hợp lệ cho " loai " (" ds ")"); continue }
        if (lt == "preserve" && !(c in bv)) loi(c ": YC preserve phải có \"Protected by: `<file test>`\" — test có sẵn trên base của việc")
        if (lt == "performance" && !(c in co_mt)) loi(c ": YC performance phải có \"Target:\" kèm số liệu")
        if (lt == "performance") n_hn++
      }
      if (loai == "perf" && n_hn == 0) loi("perf: cần ít nhất một YC \"Type: performance\"")
    }

    print ""
    print "Tổng: " n " yêu cầu — Loại việc: " (loai == "" ? "?" : loai) " — Risk: " (co_rui_ro ? rui_ro : "?") \
          " — Duyệt: " tt_spec
    for (t in dem_nhan) printf "  [%s] %d\n", t, dem_nhan[t]
    if (n_loi > 0) exit 1
  }
' "$OQ" "$SPEC"
ma=$?

# Test bảo vệ YC preserve phải CÓ SẴN trên base của việc (điểm rẽ nhánh): test thêm trong chính việc
# refactor không chứng minh được hành vi cũ.
n_bv=0
if [ -s "$BV" ]; then
  MB=$(kc_mb "$DIR")
  while IFS="$(printf '\t')" read -r yc f; do
    if [ -z "$MB" ]; then
      echo "  [LỖI] $yc: không xác định được base để kiểm \"$f\" (dòng Base: trong intake.md, hoặc base_branch trong conventions.md)"; n_bv=$((n_bv + 1))
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
