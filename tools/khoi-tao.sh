#!/usr/bin/env sh
# Engine của `aw init` / `aw upgrade`. Wrapper đã chọn version, tải engine và
# ghi version/checksums; script này lo phần còn lại — KHÔNG commit gì vào repo đích:
#
#   $AW_CONFIG/conventions.md   quy ước của repo — NGƯỜI viết, không bao giờ ghi đè
#   $AW_CONFIG/config.sh        lệnh kiểm thử, adapter… — NGƯỜI sửa, không ghi đè
#   .git/info/exclude           /.agent-workflow/ + đường dẫn adapter sinh ra
#   <AW_REPO>/.claude/…         adapter sinh lệnh cho agent (bị exclude)
#
#   aw-engine init [--adapter <id>] [--test-cmd "<lệnh>"] [--force]
#
# Chạy lại an toàn: file đã có thì giữ, exclude thiếu dòng nào thêm dòng đó,
# adapter sinh lại theo engine đang chạy.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ENG="${AW_ENGINE:-$(CDPATH= cd -- "$HERE/.." && pwd)}"
. "$HERE/lib/ket-qua.sh"
kq_khai init \
  "0=ĐÃ INIT — làm theo các bước tiếp theo phía trên" \
  "2=SAI THAM SỐ" \
  "3=CÓ FILE VIẾT TAY — không ghi đè; dời file đó đi hoặc dùng --force" \
  "4=ĐỊNH NGHĨA QUY TRÌNH LỖI — sửa workflow/ trong repo agent-workflow" \
  "9=KHÔNG HỢP LỆ — thiếu AW_REPO/AW_CONFIG, gọi qua aw"
. "$HERE/lib/worktree.sh"

[ -n "${AW_REPO:-}" ] && [ -n "${AW_CONFIG:-}" ] || { echo "LỖI: thiếu AW_REPO hoặc AW_CONFIG." >&2; exit 9; }

ADAPTER=""; LENH=""; FORCE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --adapter)  [ -n "${2:-}" ] || { echo "LỖI: --adapter cần id." >&2; exit 2; }; ADAPTER=$2; shift 2 ;;
    --test-cmd) [ $# -ge 2 ] || { echo "LỖI: --test-cmd cần lệnh." >&2; exit 2; }; LENH=$2; shift 2 ;;
    --force)    FORCE=--force; shift ;;
    *) echo "LỖI: tham số lạ \"$1\"." >&2; exit 2 ;;
  esac
done

mkdir -p "$AW_CONFIG" || exit 9
CONV="$AW_CONFIG/conventions.md"; CH="$AW_CONFIG/config.sh"

# ---- conventions.md — của NGƯỜI ----
if [ -f "$CONV" ]; then echo "  keep    conventions.md (của bạn, không bao giờ ghi đè)"
else cp "$ENG/workflow/templates/conventions.md" "$CONV"; echo "  create  conventions.md từ mẫu — hãy sửa cho đúng repo của bạn"; fi

# ---- config.sh — của NGƯỜI ----
if [ -f "$CH" ]; then
  echo "  keep    config.sh (đã có, không ghi đè)"
  CO_AD=$(. "$CH" >/dev/null 2>&1; printf '%s' "${ADAPTER:-}")
  if [ -n "$ADAPTER" ] && [ -n "$CO_AD" ] && [ "$ADAPTER" != "$CO_AD" ]; then
    echo "LỖI: config.sh đang khai ADAPTER=\"$CO_AD\" — muốn đổi sang \"$ADAPTER\" thì sửa config.sh." >&2; exit 2
  fi
  ADAPTER=${ADAPTER:-$CO_AD}
else
  ADAPTER=${ADAPTER:-claude-code}
  awk -v ad="$ADAPTER" -v l="$LENH" '
    /^ADAPTER=/       { print "ADAPTER=\"" ad "\""; next }
    /^LENH_KIEM_THU=/ { print "LENH_KIEM_THU=\"" l "\""; next }
    { print }' "$ENG/workflow/templates/config.sh" > "$CH"
  echo "  write   config.sh"
fi
ADAPTER=${ADAPTER:-claude-code}
[ -f "$ENG/adapters/$ADAPTER/build.sh" ] || {
  echo "LỖI: không có adapter \"$ADAPTER\" (có: $(ls "$ENG/adapters" | grep -v '^lib$' | tr '\n' ' '))." >&2; exit 2; }

# ---- .git/info/exclude — file sinh ra không bao giờ lọt vào commit ----
GC=$(wt_tuyet_doi "$AW_REPO" "$(git -C "$AW_REPO" rev-parse --git-common-dir)")
EX="$GC/info/exclude"; mkdir -p "$GC/info"
them=""
for p in /.agent-workflow/ $(grep -v '^#' "$ENG/adapters/$ADAPTER/exclude" 2>/dev/null); do
  grep -qxF "$p" "$EX" 2>/dev/null && continue
  grep -qxF '# agent-workflow — aw init: file sinh ra / cục bộ, không commit' "$EX" 2>/dev/null ||
    printf '\n# agent-workflow — aw init: file sinh ra / cục bộ, không commit\n' >> "$EX"
  printf '%s\n' "$p" >> "$EX"; them="$them $p"
done
if [ -n "$them" ]; then echo "  write   .git/info/exclude (+$them)"; else echo "  keep    .git/info/exclude"; fi

# ---- adapter ----
echo ""
sh "$ENG/tools/sinh-adapter.sh" "$ADAPTER" "$AW_REPO" $FORCE || exit $?

echo ""
echo "Xong. Không có file nào cần commit. Bước tiếp theo:"
n=1
if ! grep -q 'LENH_KIEM_THU="[^"]' "$CH" 2>/dev/null; then
  echo "  $n. Khai lệnh kiểm thử trong $CH (chưa khai thì /implement không đạt)"; n=$((n + 1))
fi
echo "  $n. Sửa $CONV: mẫu tên branch, nhánh gốc, vị trí worktree, mẫu file test…"; n=$((n + 1))
echo "  $n. Mở agent ở checkout chính, chạy /intake — nó đề xuất worktree cho việc"
