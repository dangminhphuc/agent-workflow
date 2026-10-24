#!/usr/bin/env sh
# Tiến độ của một việc: từng phase — trạng thái, thời gian tương tác, thời gian đồng hồ, lượt,
# check chặn, token. Suy từ journal (phases.tsv, turns.tsv, checks.tsv), không do agent tự khai.
#
#   aw status <thư-mục-feature>            in bảng ra terminal
#   aw status <thư-mục-feature> --write    ghi <thư-mục-feature>/progress.md (aw check ĐẠT gọi)
#   aw status <thư-mục-feature> --table    chỉ in bảng Markdown (rỗng nếu chưa có dữ liệu)
#
# Số liệu: tools/lib/progress.sh (td_tinh, td_md_bang, td_md_file). Chỉ --write sửa file.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai status.sh \
  "0=XONG — đã in tiến độ (--write: đã ghi progress.md)" \
  "1=KHÔNG GHI ĐƯỢC — không ghi được progress.md, xem thông báo phía trên" \
  "2=SAI THAM SỐ — xem thông báo phía trên"

DUNG="Dùng: aw status <thư-mục-feature> [--write | --table]"
D=""; CHE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --write|--table)
      if [ -n "$CHE" ]; then echo "LỖI: chỉ dùng một trong --write, --table. $DUNG" >&2; exit 2; fi
      CHE=${1#--}; shift ;;
    -*) echo "LỖI: cờ lạ \"$1\". $DUNG" >&2; exit 2 ;;
    *) if [ -n "$D" ]; then echo "LỖI: chỉ nhận một thư mục feature. $DUNG" >&2; exit 2; fi
       D=$1; shift ;;
  esac
done
[ -n "$D" ] || { echo "$DUNG" >&2; exit 2; }
[ -d "$D" ] || { echo "LỖI: không có thư mục \"$D\"." >&2; exit 2; }

. "$HERE/lib/md.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/progress.sh"

TM=$(mktemp "${TMPDIR:-/tmp}/aw-status.XXXXXX" 2>/dev/null) || { TM="${TMPDIR:-/tmp}/aw-status.$$"; : > "$TM" || exit 2; }
kq_don 'rm -f "$TM"'
canh_bao() {
  if [ "$TD_CANH_BAO" = 1 ]; then
    echo "CẢNH BÁO: khối aw-progress v1 trong $D/progress.md sai dạng — bỏ qua, chỉ tính journal máy này." >&2
  fi
}
case "$CHE" in
  table) td_md_bang "$D"; canh_bao; exit 0 ;;
  write)
    # Dựng hết trước rồi mới ghi: khối của máy khác đọc từ chính progress.md cũ.
    td_md_file "$D" > "$TM"; canh_bao
    if ! cat "$TM" > "$D/progress.md"; then echo "LỖI: không ghi được $D/progress.md." >&2; exit 1; fi
    echo "Đã ghi $D/progress.md"
    exit 0 ;;
esac
td_tinh "$D" > "$TM"
canh_bao

# LC_ALL=C: độ rộng ô = số byte trừ byte nối UTF-8 (mawk đếm byte).
LC_ALL=C awk -F'\t' -v viec="$(basename "$(CDPATH= cd -- "$D" && pwd)")" "$TD_AWK_DD"'
  function rong(s) { gsub(/[\200-\277]/, "", s); return length(s) }
  function o(r, c, v) { bang[r, c] = v; if (rong(v) > w[c]) w[c] = rong(v) }
  function tong(c, v) { if (v != "") { tg[c] += v; co[c] = 1 } }
  BEGIN {
    nhan["done"] = "ĐẠT"; nhan["active"] = "đang làm"; nhan["skipped"] = "bỏ qua"; nhan["pending"] = "chưa"
    split("Phase|Trạng thái|Tương tác|Đồng hồ|Lượt|Chặn|Token vào|Token ra|Cache đọc|Cache ghi", h, "|")
    for (c = 1; c <= 10; c++) o(0, c, h[c])
  }
  $1 == "P" {
    r++; o(r, 1, $2); o(r, 2, nhan[$3])
    for (c = 3; c <= 10; c++) {
      v = $(c + 1); tong(c, v)
      if (v == "") o(r, c, "—"); else if (c == 3 || c == 4) o(r, c, td_tg(v)); else if (c == 5 || c == 6) o(r, c, v); else o(r, c, td_tk(v))
    }
  }
  $1 == "M" { hien = $2; cuoi = $3; may = $4; moc = $5; luot = $6 }
  END {
    r++; o(r, 1, "Tổng"); o(r, 2, "")
    for (c = 3; c <= 10; c++) {
      if (!co[c]) o(r, c, "—"); else if (c == 3 || c == 4) o(r, c, td_tg(tg[c])); else if (c == 5 || c == 6) o(r, c, tg[c]); else o(r, c, td_tk(tg[c]))
    }
    print "Tiến độ — " viec
    print "Phase hiện tại: " (hien != "" ? hien : "—")
    print "Cập nhật: " (cuoi != "" ? substr(cuoi, 1, 10) " " substr(cuoi, 12, 5) " UTC" : "—") " (giờ sự kiện cuối)"
    print "Máy: " (may != "" ? may : "—")
    print ""
    for (i = 0; i <= r; i++) {
      s = "  "
      for (c = 1; c <= 10; c++) {
        v = bang[i, c]; pad = w[c] - rong(v); t = ""
        while (pad-- > 0) t = t " "
        s = s ((c <= 2) ? v t : t v) (c < 10 ? "  " : "")
      }
      print s
    }
    print ""
    print "Tương tác = tổng thời gian các lượt (prompt → agent dừng). Đồng hồ = từ lúc bắt đầu phase tới khi phase kế tiếp bắt đầu (phase đang làm: tới sự kiện cuối)."
    if (moc == 1 && luot == 0)
      print "· Chưa ghi được lượt nào — chỉ có thời gian đồng hồ. Trên Claude Code, cài hook theo adapters/claude-code/README.md § Hook."
  }
' "$TM"
exit 0
