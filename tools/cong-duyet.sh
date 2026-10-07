#!/usr/bin/env sh
# Cổng duyệt khi vào phase — in cho NGƯỜI biết còn gì chờ mình duyệt, bằng lời
# dễ đọc, dựng từ file (không để agent tự diễn giải).
#
#   aw approval design <thư-mục-feature>   vào /design: spec đã được duyệt chưa
#   aw approval plan   <thư-mục-feature>   vào /plan: mọi D-xx đã được duyệt chưa
#                                          (chore không có design: hỏi spec)
#
# Lệnh này KHÔNG duyệt gì. Agent in nguyên văn stdout cho người rồi hỏi bằng hộp
# xác nhận (xem bước "Cổng duyệt" trong lệnh phase); người tự tick trong file.
# Ghi dấu duyệt cho ô người vừa tick, như aw check.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai cong-duyet.sh \
  "0=ĐÃ DUYỆT — đi tiếp phase" \
  "1=CHƯA DUYỆT — in nguyên văn phần trên cho người rồi hỏi bằng hộp xác nhận; không tick hộ" \
  "2=SAI THAM SỐ HOẶC THIẾU FILE"
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/duyet.sh"

PHASE="${1:-}"; DIR="${2:-}"
case "$PHASE" in design|plan) ;; *) echo "Dùng: aw approval design|plan <thư-mục-feature>" >&2; exit 2 ;; esac
[ -n "$DIR" ] && [ -d "$DIR" ] || { echo "LỖI: không có thư mục feature \"$DIR\"" >&2; exit 2; }
DIR=$(CDPATH= cd -- "$DIR" && pwd)
VIEC=$(basename "$DIR")
LOAI=$(kc_loai "$DIR")
REPO=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
tuong_doi() { if [ -n "$REPO" ]; then printf '%s' "${1#"$REPO"/}"; else printf '%s' "$1"; fi; }

if [ "$PHASE" = design ] && [ "$LOAI" = chore ]; then
  echo "LỖI: loại việc chore không có phase design — đi thẳng /plan." >&2; exit 2
fi
if [ "$PHASE" = plan ] && [ "$LOAI" != chore ]; then CONG=tdd; else CONG=spec; fi

# ------------------------------------------------------------------ spec
if [ "$CONG" = spec ]; then
  SPEC="$DIR/spec.md"; OQF="$DIR/open-questions.md"; [ -f "$OQF" ] || OQF=/dev/null
  [ -f "$SPEC" ] || { echo "LỖI: không tìm thấy $SPEC — chạy /spec trước." >&2; exit 2; }
  dy_dong_dau "$SPEC" spec >/dev/null
  TT=$(dy_trang_thai "$SPEC" spec | awk -F'|' '$1 == "S" { print $3; exit }')
  DONG=$(dy_quet "$SPEC" spec | awk -F'|' '$1 == "O" { print $5; exit }')
  LOI=$(dy_trang_thai "$SPEC" spec | awk -F'|' '$1 == "L" { print "            " $2 }')
  F=$(tuong_doi "$SPEC")

  echo "CỔNG DUYỆT — vào /$PHASE cần spec đã được bạn duyệt"
  echo "Việc:        $VIEC"
  case "$TT" in
    "đã duyệt")
      echo "Trạng thái:  ✓ ĐÃ DUYỆT"
      exit 0 ;;
    "đề xuất")
      echo "Trạng thái:  ✗ CHƯA DUYỆT — ô \"$DY_NHAN_SPEC\" chưa tick"
      echo "Cách duyệt:  mở $F, dòng $DONG"
      echo "             đổi   - [ ] **$DY_NHAN_SPEC**"
      echo "             thành - [x] **$DY_NHAN_SPEC**" ;;
    "đổi sau duyệt")
      echo "Trạng thái:  ✗ ĐÃ ĐỔI SAU KHI DUYỆT — bạn đã tick, nhưng nội dung spec đổi sau đó"
      echo "Cách duyệt:  đọc lại $F"
      echo "             đồng ý bản mới → xoá \"<!-- dấu duyệt: … -->\" ở dòng $DONG (giữ [x])"
      echo "             không đồng ý   → bỏ tick, nói agent cần sửa gì"
      echo "             (máy chỉ lưu hash nên không chỉ ra được dòng nào đã đổi)" ;;
    *)
      echo "Trạng thái:  ✗ KHÔNG ĐỌC ĐƯỢC Ô DUYỆT"
      [ -n "$LOI" ] && printf '%s\n' "$LOI"
      echo "Cách duyệt:  sửa ô duyệt theo mẫu templates/spec.md (agent được sửa dạng, không được tick)" ;;
  esac
  echo ""
  awk -v phase="$PHASE" '
    function ra(s) { sub(/^[ \t]*[-*][ \t]*/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    { sub(/\r$/, "") }
    FNR == 1 { idx = (FILENAME == ARGV[1]) ? 1 : 2; sec = ""; cur = ""; cmt = 0 }
    cmt { if ($0 ~ /-->/) cmt = 0; next }
    /^[ \t]*<!--/ && !/-->/ { cmt = 1; next }
    /^[ \t]*<!--.*-->[ \t]*$/ { next }
    idx == 1 && rui_ro == "" && /Mức rủi ro[^:]*:/ { v = $0; sub(/^[^:]*:/, "", v); rui_ro = ra(v); next }
    idx == 1 && /^###[ \t]+YC-[0-9]+/ {
      match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH); ds[++n] = cur
      t = $0; sub(/^###[ \t]+YC-[0-9]+[ \t]*[—:-]*[ \t]*/, "", t); ten[cur] = t; next
    }
    idx == 1 && /^##[ \t]/ { cur = ""; sec = ($0 ~ /Ngoài phạm vi/) ? "npv" : ""; next }
    idx == 1 && /^###[ \t]/ { cur = ""; next }
    idx == 1 && cur != "" && /Nguồn[^:]*:/ && !(cur in nhan) {
      if (match($0, /\[(CONFLUENCE|JIRA|FILE|SUY-RA|CẦN-HỎI)\]/)) { nhan[cur] = substr($0, RSTART + 1, RLENGTH - 2); dem[nhan[cur]]++ }
    }
    idx == 1 && sec == "npv" && $0 !~ /^[ \t]*$/ { v = ra($0); if (v != "" && v !~ /^</) npv[++n_npv] = v }
    idx == 2 && /^##[ \t]+YC-[0-9]+/ { match($0, /YC-[0-9]+/); q = substr($0, RSTART, RLENGTH); oq[++n_oq] = q; tt[q] = "mở"; mc[q] = "?"; next }
    idx == 2 && q != "" && /Mức chặn[^:]*:/ { v = $0; sub(/^[^:]*:/, "", v); mc[q] = ra(v) }
    idx == 2 && q != "" && /Trạng thái[^:]*:/ { v = $0; sub(/^[^:]*:/, "", v); tt[q] = ra(v) }
    END {
      print "Nên đọc kỹ trước khi tick (máy không kiểm thay được):"
      k = 0
      s = ""; for (i = 1; i <= n; i++) if (nhan[ds[i]] == "SUY-RA") s = s "\n       " ds[i] " — " ten[ds[i]]
      printf "  %d. Yêu cầu agent tự suy ra [SUY-RA] — %d mục, nguồn không ghi trực tiếp%s\n", ++k, dem["SUY-RA"] + 0, (s == "" ? "" : ":" s)
      printf "  %d. Ngoài phạm vi — %d mục%s\n", ++k, n_npv, (n_npv ? ":" : "")
      for (i = 1; i <= n_npv && i <= 6; i++) print "       - " npv[i]
      if (n_npv > 6) print "       … và " (n_npv - 6) " mục nữa"
      if (phase == "design") {
        if (rui_ro == "cao") hq = "/design chạy Mode 2: BẠN phác các quyết định D-xx trước, agent viết phần còn lại"
        else if (rui_ro == "thường") hq = "/design chạy Mode 1: agent viết cả tdd.md, bạn duyệt từng D-xx"
        else hq = "chưa có nhãn hợp lệ — aw check spec sẽ chặn"
      } else hq = "chore không có design"
      printf "  %d. Mức rủi ro: %s — %s\n", ++k, (rui_ro == "" ? "?" : rui_ro), hq
      mo = 0; mo_chan = ""
      for (i = 1; i <= n_oq; i++) if (tt[oq[i]] != "đã trả lời") { mo++; dmc[mc[oq[i]]]++; if (mc[oq[i]] == "chặn") mo_chan = mo_chan " " oq[i] }
      if (mo == 0) printf "  %d. Điểm mù còn mở: 0\n", ++k
      else printf "  %d. Điểm mù còn mở: %d (chặn: %d · chặn review: %d · không chặn: %d)%s\n", ++k, mo, dmc["chặn"] + 0, dmc["chặn review"] + 0, dmc["không chặn"] + 0, \
             (mo_chan == "" ? "" : " — mục \"chặn\" phải trả lời qua /clarify trước:" mo_chan)
      print ""
      t = ""
      split("FILE JIRA CONFLUENCE SUY-RA CẦN-HỎI", lb, " ")
      for (i = 1; i <= 5; i++) if (dem[lb[i]]) t = t (t == "" ? "" : " · ") "[" lb[i] "] " dem[lb[i]]
      print "Spec có " n " yêu cầu" (t == "" ? "" : ": " t)
    }
  ' "$SPEC" "$OQF"
  exit 1
fi

# ------------------------------------------------------------------ tdd (D-xx)
TDD="$DIR/tdd.md"; PH="$DIR/phat-hien-thiet-ke.md"
[ -f "$TDD" ] || { echo "LỖI: không tìm thấy $TDD — chạy /design trước." >&2; exit 2; }
dy_dong_dau "$TDD" tdd >/dev/null
DTT=$(dy_trang_thai "$TDD" tdd | awk -F'|' '$1 == "S" { printf "%s=%s;", $2, $3 }')
DNR=$(dy_quet "$TDD" tdd | awk -F'|' '$1 == "O" { printf "%s=%s;", $2, $5 }')
LOI=$(dy_trang_thai "$TDD" tdd | awk -F'|' '$1 == "L" { print "  " $2 }')
F=$(tuong_doi "$TDD")
PHF="$PH"; [ -f "$PH" ] || PHF=/dev/null

awk -v dtt="$DTT" -v dnr="$DNR" -v viec="$VIEC" -v f="$F" -v nhan="$DY_NHAN_D" '
  function ra(s) { sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function nap(s, m,   n, a, i, p) { n = split(s, a, ";"); for (i = 1; i <= n; i++) if (a[i] != "") { split(a[i], p, "="); m[p[1]] = p[2] } }
  BEGIN { nap(dtt, tt); nap(dnr, nr) }
  { sub(/\r$/, "") }
  FNR == 1 { idx = (FILENAME == ARGV[1]) ? 1 : 2; d = ""; ph = "" }
  idx == 1 && /^###[ \t]+D-[0-9]+/ {
    match($0, /D-[0-9]+/); d = substr($0, RSTART, RLENGTH)
    if (d in co) { d = ""; next }
    co[d] = 1; ds[++n] = d; t = $0; sub(/^###[ \t]+D-[0-9]+[ \t]*[—:-]*[ \t]*/, "", t); ten[d] = t; next
  }
  idx == 1 && /^##?#?[ \t]/ { d = ""; next }
  idx == 1 && d != "" && /^[ \t]*[-*][ \t]*tac_gia[^:]*:/ { tg[d] = ra($0) }
  idx == 1 && d != "" && /^[ \t]*[-*][ \t]*Chọn[^:]*:/ { chon[d] = ra($0) }
  idx == 1 && d != "" && /Lý do mở lại[^:]*:/ { ld[d] = ra($0) }
  idx == 1 && d != "" && /^[-*][ \t]*Phản biện \(agent\)/ { pb[d]++ }
  idx == 2 && /^###[ \t]+PH-[0-9]+/ { match($0, /PH-[0-9]+/); ph = substr($0, RSTART, RLENGTH); dsph[++nph] = ph; xl[ph] = ""; next }
  idx == 2 && ph != "" && /Xử lý[^:]*:/ { xl[ph] = ra($0) }
  idx == 2 && ph != "" && /Mức[^:]*:/ && !/Mức chặn/ { muc[ph] = ra($0) }
  END {
    for (i = 1; i <= n; i++) if (tt[ds[i]] != "đã duyệt") cho++
    print "CỔNG DUYỆT — vào /plan cần mọi quyết định D-xx đã được bạn duyệt"
    print "Việc:        " viec
    if (n == 0) { print "Trạng thái:  ✓ KHÔNG CÓ QUYẾT ĐỊNH NÀO CẦN DUYỆT"; exit 0 }
    if (cho == 0) { print "Trạng thái:  ✓ ĐÃ DUYỆT ĐỦ " n "/" n " quyết định"; exit 0 }
    print "Trạng thái:  ✗ CÒN " cho "/" n " QUYẾT ĐỊNH CHƯA DUYỆT"
    print "File:        " f
    print ""
    print "Chưa duyệt:"
    for (i = 1; i <= n; i++) {
      d = ds[i]; s = tt[d]
      if (s == "đã duyệt") continue
      if (s == "đề xuất") lydo = "chưa tick"
      else if (s == "mở lại") lydo = "đang mở lại — lý do: " ld[d]
      else if (s == "đổi sau duyệt") lydo = "ĐÃ ĐỔI sau khi bạn tick — đọc lại; đồng ý thì xoá dấu duyệt (giữ [x])"
      else lydo = "thiếu ô duyệt — agent thêm ô (chưa tick) rồi chạy lại"
      printf "  %s — %s\n", d, ten[d]
      printf "         %s%s\n", (d in nr ? "dòng " nr[d] " · " : ""), lydo
      printf "         tác giả: %s%s%s\n", (tg[d] == "nguoi" ? "bạn (nguoi)" : (tg[d] == "" ? "?" : tg[d])), \
             (chon[d] == "" ? "" : " · Chọn: " chon[d]), (pb[d] ? " · có " pb[d] " phản biện của agent — đọc trước khi tick" : "")
    }
    xong = ""; for (i = 1; i <= n; i++) if (tt[ds[i]] == "đã duyệt") xong = xong (xong == "" ? "" : ", ") ds[i]
    if (xong != "") print "Đã duyệt:    " xong
    print ""
    print "Cách duyệt:  đọc từng D ở trên, đổi \"- [ ] **" nhan "**\" thành \"- [x] **" nhan "**\""
    print "             ở dòng ghi bên cạnh. Không đồng ý thì để trống và nói agent cần sửa gì."
    c = 0; cc = 0; for (i = 1; i <= nph; i++) { x = xl[dsph[i]]; if (x == "" || x == "chưa") { c++; if (muc[dsph[i]] == "Chặn") cc++ } }
    if (c) print "Lưu ý:       còn " c " phát hiện của checker LLM chưa phân xử (mức Chặn: " cc ") — chạy /clarify"
    exit 1
  }
' "$TDD" "$PHF"
[ $? -eq 0 ] && exit 0
[ -n "$LOI" ] && { echo ""; echo "Ô duyệt sai dạng/chỗ (agent sửa dạng, không tick):"; printf '%s\n' "$LOI"; }
exit 1
