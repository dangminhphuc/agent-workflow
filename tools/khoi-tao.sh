#!/usr/bin/env sh
# Engine của `aw init` / `aw upgrade`. Wrapper đã chọn version, tải engine và
# ghi version/checksums; script này lo phần còn lại — KHÔNG commit gì vào repo đích:
#
#   $AW_CONFIG/conventions.md   quy ước của repo — NGƯỜI viết, không bao giờ ghi đè
#   $AW_CONFIG/config.sh        lệnh kiểm thử, adapter… — NGƯỜI sửa, không ghi đè
#   .git/info/exclude           /.agent-workflow/ + đường dẫn adapter sinh ra
#   <AW_REPO>/.claude/…         adapter sinh lệnh cho agent (bị exclude)
#
#   aw-engine init [--adapter <id>] [--test-cmd "<lệnh>"] [--force] [--from-legacy]
#
# --from-legacy: repo đã cài bộ cài cũ (.agent-workflow/.quy-trinh/ commit trong base).
# Đọc .agent-workflow/conventions.md và .quy-trinh/cau-hinh.sh có sẵn, chuyển vào
# $AW_CONFIG. KHÔNG xoá, KHÔNG commit gì — chỉ in hướng dẫn để người tự dọn
# (bằng một PR bình thường, qua review, vì base là protected branch).
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

ADAPTER=""; LENH=""; FORCE=""; CU=""
while [ $# -gt 0 ]; do
  case "$1" in
    --adapter)  [ -n "${2:-}" ] || { echo "LỖI: --adapter cần id." >&2; exit 2; }; ADAPTER=$2; shift 2 ;;
    --test-cmd) [ $# -ge 2 ] || { echo "LỖI: --test-cmd cần lệnh." >&2; exit 2; }; LENH=$2; shift 2 ;;
    --force)    FORCE=--force; shift ;;
    --from-legacy) CU=1; shift ;;
    *) echo "LỖI: tham số lạ \"$1\"." >&2; exit 2 ;;
  esac
done

case "$(CDPATH= cd -- "$AW_REPO" && pwd)/" in
  "$ENG"/*) echo "LỖI: không init trong chính engine agent-workflow ($AW_REPO) — repo đích mới là nơi dùng." >&2; exit 2 ;;
esac

mkdir -p "$AW_CONFIG" || exit 9
CONV="$AW_CONFIG/conventions.md"; CH="$AW_CONFIG/config.sh"

# ---- bộ cài cũ: chỉ ĐỌC ----
CU_ART="$AW_REPO/.agent-workflow"; CU_CONV="$CU_ART/conventions.md"; CU_CH="$CU_ART/.quy-trinh/cau-hinh.sh"
if [ -n "$CU" ]; then
  [ -f "$CU_CONV" ] || [ -f "$CU_CH" ] || {
    echo "LỖI: --from-legacy nhưng không thấy bộ cài cũ (.agent-workflow/conventions.md, .agent-workflow/.quy-trinh/cau-hinh.sh)." >&2; exit 2; }
  if [ -f "$CU_CONV" ] && [ ! -f "$CONV" ]; then
    cp "$CU_CONV" "$CONV"; echo "  copy    conventions.md ← .agent-workflow/conventions.md"
  fi
  if [ -f "$CU_CH" ] && [ ! -f "$CH" ]; then
    [ -n "$ADAPTER" ] || ADAPTER=$(awk -F= '$1 == "adapter" { print $2; exit }' "$CU_ART/.quy-trinh/nguon.txt" 2>/dev/null)
    ADAPTER=${ADAPTER:-claude-code}
    # Lấy giá trị từ file cũ (chạy trong subshell), điền vào mẫu mới.
    gt() { (LENH_KIEM_THU=""; LENH_DO_HIEU_NANG=""; LENH_CHUAN_BI_WT=""; . "$CU_CH" >/dev/null 2>&1; eval "printf '%s' \"\${$1:-}\"") | sed 's/[\\"]/\\&/g'; }
    awk -v ad="$ADAPTER" -v kt="$(gt LENH_KIEM_THU)" -v hn="$(gt LENH_DO_HIEU_NANG)" -v wt="$(gt LENH_CHUAN_BI_WT)" '
      /^ADAPTER=/           { print "ADAPTER=\"" ad "\""; next }
      /^LENH_KIEM_THU=/     { print "LENH_KIEM_THU=\"" kt "\""; next }
      /^LENH_DO_HIEU_NANG=/ { print "LENH_DO_HIEU_NANG=\"" hn "\""; next }
      /^LENH_CHUAN_BI_WT=/  { print "LENH_CHUAN_BI_WT=\"" wt "\""; next }
      { print }' "$ENG/workflow/templates/config.sh" > "$CH"
    echo "  copy    config.sh ← .agent-workflow/.quy-trinh/cau-hinh.sh"
  fi
fi

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

if [ -n "$CU" ]; then
  # Đường dẫn bộ cài cũ git còn theo dõi. File .claude/ chỉ tính file sinh tự động.
  ds=$(git -C "$AW_REPO" ls-files -- .agent-workflow/.quy-trinh .agent-workflow/conventions.md .agent-workflow/README.md 2>/dev/null |
       awk -F/ '{ print ($2 == ".quy-trinh" ? $1 "/" $2 "/" : $0) }' | sort -u)
  cl=$(git -C "$AW_REPO" ls-files -- .claude 2>/dev/null | while IFS= read -r f; do
         grep -q 'SINH TỰ ĐỘNG' "$AW_REPO/$f" 2>/dev/null && printf '%s\n' "$f"; done)
  echo ""
  echo "Bộ cài cũ vẫn còn trong base — aw KHÔNG xoá, KHÔNG commit gì."
  if [ -n "$ds$cl" ]; then
    echo "Khi tiện, NGƯỜI dọn bằng một PR bình thường (qua review) vào nhánh gốc:"
    echo ""
    echo "  git switch -c chore_bo-bo-cai-cu <nhánh-gốc>"
    printf '%s\n%s\n' "$ds" "$cl" | awk 'NF { printf "  git rm -r -q -- %s\n", $0 }'
    echo "  git commit -m \"Bỏ bộ cài agent-workflow cũ — đã chuyển sang aw\""
    echo ""
    echo "Thư mục artifact của việc cũ (.agent-workflow/<tên-branch>/) giữ hay bỏ là quyền của team."
    echo "Trước khi PR đó vào base: file .claude/ cũ được git theo dõi nên adapter BỎ QUA (skip),"
    echo "worktree tạo từ base cũ vẫn thấy lệnh cũ."
  fi
fi

echo ""
echo "Xong. Không có file nào cần commit. Bước tiếp theo:"
n=1
if ! grep -q 'LENH_KIEM_THU="[^"]' "$CH" 2>/dev/null; then
  echo "  $n. Khai lệnh kiểm thử trong $CH (chưa khai thì /implement không đạt)"; n=$((n + 1))
fi
echo "  $n. Sửa $CONV: mẫu tên branch, nhánh gốc, vị trí worktree, mẫu file test…"; n=$((n + 1))
echo "  $n. Mở agent ở checkout chính, chạy /intake — nó đề xuất worktree cho việc"
