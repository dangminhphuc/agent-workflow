#!/usr/bin/env sh
# Kiểm tra điều kiện ra của phase 00-intake.
#
#   sh tools/kiem-tra-tiep-nhan.sh <thư-mục-feature>
#
# Chặn:
#   - intake.md thiếu, hoặc "Loại việc" không thuộc feature|bugfix|refactor|perf|chore.
#   - "Mục tiêu" trống hoặc còn chỗ giữ chỗ.
#   - Mục "Input" không có nguồn nào, nhãn không hợp lệ, hay có [SUY-RA].
#     Input chỉ nhận tài liệu có định danh hoặc lời người dùng CHÉP NGUYÊN VĂN —
#     suy đoán của agent mà vào đây thì mọi phase sau sẽ truy về nó như có nguồn.
#   - [NGƯỜI-DÙNG] không kèm nguyên văn.
#   - [JIRA] mà định danh không có mã khớp mau_jira (conventions.md).
# Cảnh báo (review chặn): loại việc lệch tiền tố branch.
#
# Mã thoát: 0 = đạt, 1 = có vi phạm, 2 = thiếu file.

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

DIR="${1:-.}"
MD="$DIR/intake.md"
[ -f "$MD" ] || { echo "LỖI: không tìm thấy $MD — chạy /intake trước" >&2; exit 2; }

MJ=$(kc_mau_jira "$(kc_conventions "$DIR")")

awk -v loai_hl="$LOAI_HOP_LE" -v mj="$MJ" '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }
  function gia_tri(s) {
    sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s
  }
  function dong_cho() {
    if (cho_nv) loi("Input #" n_in ": [NGƯỜI-DÙNG] không kèm lời người dùng chép nguyên văn")
    cho_nv = 0
  }
  BEGIN { n = split(loai_hl, a, " "); for (i = 1; i <= n; i++) hl[a[i]] = 1
          nhan["CONFLUENCE"]=1; nhan["JIRA"]=1; nhan["FILE"]=1; nhan["NGƯỜI-DÙNG"]=1 }
  { sub(/\r$/, "") }

  !co_loai && /Loại việc[^:]*:/ { co_loai = 1; loai = gia_tri($0) }
  !co_mt   && /Mục tiêu[^:]*:/  { co_mt = 1; mt = gia_tri($0) }

  /^##[ \t]/ { if (vao) dong_cho(); vao = ($0 ~ /^##[ \t]+Input/); next }
  !vao { next }

  /^[ \t]*-[ \t]/ {
    dong_cho()
    if (!match($0, /\[[^]]+\]/)) { loi("Input: dòng không có nhãn nguồn — " $0); next }
    t = substr($0, RSTART + 1, RLENGTH - 2); rest = substr($0, RSTART + RLENGTH)
    n_in++
    if (t == "SUY-RA") { loi("Input #" n_in ": [SUY-RA] không được là input — input chỉ là tài liệu hoặc lời người dùng nguyên văn"); next }
    if (!(t in nhan))  { loi("Input #" n_in ": nhãn [" t "] không hợp lệ (CONFLUENCE | JIRA | FILE | NGƯỜI-DÙNG)"); next }
    gsub(/<!--.*-->/, "", rest); gsub(/^[`* \t]+|[ \t]+$/, "", rest)
    if (t == "NGƯỜI-DÙNG" && (rest == "" || rest ~ /^<.*>$/)) cho_nv = 1
    else if (t != "NGƯỜI-DÙNG" && rest == "") loi("Input #" n_in ": [" t "] thiếu định danh (URL, mã issue, đường dẫn)")
    # Chỗ giữ chỗ còn sót (vd dòng mẫu chưa sửa) — nếu lọt, spec sẽ truy về một nguồn không có thật
    else if (t != "NGƯỜI-DÙNG" && (rest ~ /<[^>]*>/ || rest ~ /\((URL|https?:\/\/…)\)/)) loi("Input #" n_in ": [" t "] còn chỗ giữ chỗ chưa điền — " rest)
    else if (t == "JIRA" && rest !~ ("(^|[^A-Za-z0-9])(" mj ")([^A-Za-z0-9]|$)")) loi("Input #" n_in ": [JIRA] không có mã issue khớp mau_jira (" mj ") — " rest)
    dem[t]++
    next
  }
  /^[ \t]*>/ {
    if ($0 ~ /SUY-RA/) loi("Input: có [SUY-RA] trong phần nguyên văn")
    s = $0; sub(/^[ \t]*>[ \t]*/, "", s)
    if (s != "" && s !~ /^<.*>$/) cho_nv = 0
    next
  }

  END {
    if (vao) dong_cho()
    if (!co_loai)            loi("Thiếu dòng \"Loại việc:\" (feature | bugfix | refactor | perf | chore)")
    else if (!(loai in hl))  loi("\"Loại việc: " loai "\" không hợp lệ. Chỉ chấp nhận: feature | bugfix | refactor | perf | chore")
    if (!co_mt || mt == "" || mt ~ /^<.*>$/) loi("Thiếu \"Mục tiêu:\" (một câu)")
    if (n_in == 0) loi("Mục \"## Input\" không có nguồn nào. Không có input thì không có gì để các phase sau truy về.")

    print ""
    printf "Loại việc: %s — %d input\n", (co_loai ? loai : "?"), n_in
    for (t in dem) printf "  [%s] %d\n", t, dem[t]
    print ""
    if (n_loi > 0) { print "KHÔNG ĐẠT — " n_loi " vi phạm."; exit 1 }
    print "ĐẠT — mục đích và input hợp lệ. Bước tiếp: NGƯỜI xác nhận loại việc và input."
  }
' "$MD"
ma=$?

cb=$(kc_loai_branch "$DIR")
if [ -n "$cb" ]; then
  echo ""
  echo "  [CẢNH BÁO] $cb"
  echo "  (cảnh báo không chặn ở đây; review sẽ chặn nếu còn)"
fi
exit $ma
