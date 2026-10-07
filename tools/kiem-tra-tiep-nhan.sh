#!/usr/bin/env sh
# Kiểm tra điều kiện ra của phase 00-intake.
#
#   aw check intake <thư-mục-feature>
#
# Chặn:
#   - intake.md thiếu, hoặc "Type" (loại việc) không thuộc feature|bugfix|refactor|perf|chore.
#   - "Goal" (mục tiêu) trống hoặc còn chỗ giữ chỗ.
#   - Mục "Input" không có nguồn nào, nhãn không hợp lệ, hay có [INFERRED].
#     Input chỉ nhận tài liệu có định danh hoặc lời người dùng CHÉP NGUYÊN VĂN —
#     suy đoán của agent mà vào đây thì mọi phase sau sẽ truy về nó như có nguồn.
#   - [HUMAN] không kèm nguyên văn.
#   - [JIRA] mà định danh không có mã khớp jira_key_regex (conventions.md).
#   - Thiếu dòng "Base:" dạng `<ref>` @ `<sha>` (tao-worktree.sh in ra), hoặc sha
#     không phải tổ tiên của HEAD. Checker phía sau so diff với base này — base
#     sai thì phạm vi diff, test bảo vệ, tái hiện lỗi đều kiểm trên nền sai.
# Cảnh báo (review chặn): loại việc lệch tiền tố branch.
# Cảnh báo (không chặn): ref của Base không còn — checker dùng sha thay.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai kiem-tra-tiep-nhan.sh \
  "0=ĐẠT — được sang phase sau" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"
. "$HERE/lib/version.sh"

DIR="${1:-.}"
MD="$DIR/intake.md"
[ -f "$MD" ] || { echo "LỖI: không tìm thấy $MD — chạy /aw-intake trước" >&2; exit 2; }

MJ=$(kc_mau_jira "$(kc_conventions "$DIR")")

# ---- Base: base NGƯỜI chọn lúc tạo worktree (kiểm trước, đếm vào tổng vi phạm) ----
n_base=0
set -- $(kc_base_dong "$DIR")
b_ref="${1:-}"; b_sha="${2:-}"
if [ -z "$b_ref" ] || [ -z "$b_sha" ]; then
  echo "  [LỖI] Thiếu dòng \"- **Base:** \`<ref>\` @ \`<sha>\`\" — chép đúng dòng aw worktree new in ra khi tạo worktree"
  n_base=1
elif ! git -C "$DIR" rev-parse --verify --quiet "$b_sha^{commit}" >/dev/null; then
  echo "  [LỖI] Base: sha \"$b_sha\" không phải commit trong repo"
  n_base=1
elif ! git -C "$DIR" merge-base --is-ancestor "$b_sha" HEAD 2>/dev/null; then
  echo "  [LỖI] Base: \"$b_sha\" không phải tổ tiên của HEAD — branch này không tạo từ base đã ghi"
  n_base=1
elif ! git -C "$DIR" rev-parse --verify --quiet "$b_ref^{commit}" >/dev/null; then
  echo "  [CẢNH BÁO] Base: ref \"$b_ref\" không còn — checker so diff với sha $b_sha"
fi

# ---- Engine: version engine ghim cho việc này (aw check chạy đúng version đó) ----
e_ver=$(kc_engine_dong "$DIR")
e_dang=$(tr -d ' \r\n' < "$HERE/../VERSION" 2>/dev/null)
if [ -z "$e_ver" ]; then
  echo "  [LỖI] Thiếu dòng \"- **Engine:** YYYY.M.N\" — chép đúng dòng aw worktree in ra khi tạo worktree"
  n_base=$((n_base + 1))
elif ! ver_hop_le "$e_ver"; then
  echo "  [LỖI] Engine: \"$e_ver\" không phải YYYY.M.N"
  n_base=$((n_base + 1))
elif [ -n "$e_dang" ] && [ "$e_ver" != "$e_dang" ]; then
  echo "  [LỖI] Engine: việc ghim $e_ver nhưng checker đang chạy là $e_dang — chạy qua aw check, không gọi engine khác"
  n_base=$((n_base + 1))
fi

awk -v loai_hl="$LOAI_HOP_LE" -v mj="$MJ" -v n_base="$n_base" '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }
  function gia_tri(s) {
    sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s
  }
  function dong_cho() {
    if (cho_nv) loi("Input #" n_in ": [HUMAN] không kèm lời người dùng chép nguyên văn")
    cho_nv = 0
  }
  BEGIN { n_loi = n_base; n = split(loai_hl, a, " "); for (i = 1; i <= n; i++) hl[a[i]] = 1
          nhan["CONFLUENCE"]=1; nhan["JIRA"]=1; nhan["FILE"]=1; nhan["HUMAN"]=1 }
  { sub(/\r$/, "") }

  !co_loai && /^[ \t]*-[ \t]+\*\*Type:\*\*/ { co_loai = 1; loai = gia_tri($0) }
  !co_mt   && /^[ \t]*-[ \t]+\*\*Goal:\*\*/ { co_mt = 1; mt = gia_tri($0) }

  /^##[ \t]/ { if (vao) dong_cho(); vao = ($0 ~ /^##[ \t]+Input/); next }
  !vao { next }

  /^[ \t]*-[ \t]/ {
    dong_cho()
    if (!match($0, /\[[^]]+\]/)) { loi("Input: dòng không có nhãn nguồn — " $0); next }
    t = substr($0, RSTART + 1, RLENGTH - 2); rest = substr($0, RSTART + RLENGTH)
    n_in++
    if (t == "INFERRED") { loi("Input #" n_in ": [INFERRED] không được là input — input chỉ là tài liệu hoặc lời người dùng nguyên văn"); next }
    if (!(t in nhan))  { loi("Input #" n_in ": nhãn [" t "] không hợp lệ (CONFLUENCE | JIRA | FILE | HUMAN)"); next }
    gsub(/<!--.*-->/, "", rest); gsub(/^[`* \t]+|[ \t]+$/, "", rest)
    if (t == "HUMAN" && (rest == "" || rest ~ /^<.*>$/)) cho_nv = 1
    else if (t != "HUMAN" && rest == "") loi("Input #" n_in ": [" t "] thiếu định danh (URL, mã issue, đường dẫn)")
    # Chỗ giữ chỗ còn sót (vd dòng mẫu chưa sửa) — nếu lọt, spec sẽ truy về một nguồn không có thật
    else if (t != "HUMAN" && (rest ~ /<[^>]*>/ || rest ~ /\((URL|https?:\/\/…)\)/)) loi("Input #" n_in ": [" t "] còn chỗ giữ chỗ chưa điền — " rest)
    else if (t == "JIRA" && rest !~ ("(^|[^A-Za-z0-9])(" mj ")([^A-Za-z0-9]|$)")) loi("Input #" n_in ": [JIRA] không có mã issue khớp jira_key_regex (" mj ") — " rest)
    dem[t]++
    next
  }
  /^[ \t]*>/ {
    if ($0 ~ /INFERRED/) loi("Input: có [INFERRED] trong phần nguyên văn")
    s = $0; sub(/^[ \t]*>[ \t]*/, "", s)
    if (s != "" && s !~ /^<.*>$/) cho_nv = 0
    next
  }

  END {
    if (vao) dong_cho()
    if (!co_loai)            loi("Thiếu dòng \"- **Type:**\" (feature | bugfix | refactor | perf | chore)")
    else if (!(loai in hl))  loi("\"Type: " loai "\" không hợp lệ. Chỉ chấp nhận: feature | bugfix | refactor | perf | chore")
    if (!co_mt || mt == "" || mt ~ /^<.*>$/) loi("Thiếu \"- **Goal:**\" (mục tiêu một câu)")
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
