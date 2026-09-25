#!/usr/bin/env sh
# Cai quy trinh vao mot repo khac.
#
#   sh tools/cai-dat.sh <thu-muc-repo-dich> [tuy chon]
#
# Tuy chon:
#   --adapter <id>        mac dinh: claude-code
#   --lenh-kiem-thu <s>   vi du: "npm test" — dung cho dieu kien ra phase 03
#   --force               cho phep ghi de file nguoi viet tay
#
# Cai vao repo dich:
#   .agent-workflow/.quy-trinh/{rules,templates,tools}   bo cai
#   .agent-workflow/                                     noi chua artifact
#   .claude/**                                           do adapter sinh ra

set -e
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

DICH=""
ADAPTER="claude-code"
LENH=""
FORCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --adapter)       ADAPTER="$2"; shift 2 ;;
    --lenh-kiem-thu) LENH="$2";    shift 2 ;;
    --force)         FORCE="--force"; shift ;;
    -*) echo "Tham số lạ: $1" >&2; exit 2 ;;
    *)  DICH="$1"; shift ;;
  esac
done

if [ -z "$DICH" ]; then
  echo "Dùng: sh tools/cai-dat.sh <thư-mục-repo-đích> [--adapter claude-code] [--lenh-kiem-thu \"npm test\"]" >&2
  exit 2
fi
[ -d "$DICH" ] || { echo "LỖI: không tìm thấy thư mục $DICH" >&2; exit 2; }

DICH=$(CDPATH= cd -- "$DICH" && pwd)
if [ "$DICH" = "$ROOT" ]; then
  echo "LỖI: không cài quy trình vào chính repo agent-workflow." >&2
  echo "      Repo này là nguồn; repo đích mới là nơi tiêu thụ." >&2
  exit 2
fi

MANIFEST="$ROOT/workflow.yaml"
ART=$(awk '/^artifact_dir:/ { sub(/^artifact_dir:[ \t]*/, ""); print; exit }' "$MANIFEST")
QT="$DICH/$ART/.quy-trinh"

ad_dir="$ROOT/adapters/$ADAPTER"
if [ ! -f "$ad_dir/build.sh" ]; then
  echo "LỖI: adapter \"$ADAPTER\" chưa có (không thấy $ad_dir/build.sh)." >&2
  echo "      Adapter đang dùng được: $(ls "$ROOT/adapters" 2>/dev/null | tr '\n' ' ')" >&2
  exit 2
fi

echo "Cài quy trình vào: $DICH"
echo "Adapter:           $ADAPTER"
echo ""

# ---- 1. Bo cai (luat, mau, cong cu) ----
mkdir -p "$QT/rules" "$QT/templates" "$QT/tools/lib"
cp "$ROOT"/workflow/rules/*.md      "$QT/rules/"
cp "$ROOT"/workflow/templates/*.md  "$QT/templates/"
cp "$ROOT"/tools/kiem-tra-*.sh      "$QT/tools/"
cp "$ROOT"/tools/lib/md.sh          "$QT/tools/lib/"
chmod +x "$QT"/tools/*.sh 2>/dev/null || true
echo "  chép    $ART/.quy-trinh/{rules,templates,tools}"

# ---- 2. Cau hinh rieng cua repo dich ----
CH="$QT/cau-hinh.sh"
if [ -f "$CH" ] && [ -z "$FORCE" ]; then
  echo "  giữ     $ART/.quy-trinh/cau-hinh.sh (đã có, không ghi đè)"
else
  {
    echo "# Cấu hình của repo này cho quy trình agent-workflow."
    echo "# File này do NGƯỜI sửa, adapter không ghi đè khi cài lại."
    echo ""
    echo "# Lệnh kiểm thử — điều kiện ra của phase 03-implement."
    echo "# Bỏ trống thì phase 03 sẽ KHÔNG ĐẠT, không phải \"bỏ qua\"."
    if [ -n "$LENH" ]; then
      echo "LENH_KIEM_THU=\"$LENH\""
    else
      echo "LENH_KIEM_THU=\"\""
    fi
  } > "$CH"
  echo "  ghi     $ART/.quy-trinh/cau-hinh.sh"
fi

# ---- 3. Noi chua artifact ----
ARTDIR="$DICH/$ART"
if [ ! -f "$ARTDIR/README.md" ]; then
  {
    echo "# Artifact bàn giao của quy trình"
    echo ""
    echo "Thư mục này chứa các file do từng phase ghi ra. Chúng là **bàn giao"
    echo "giữa các phase**, không phải ghi chú tạm — nên commit vào git."
    echo ""
    echo "| File | Do phase nào ghi |"
    echo "|---|---|"
    echo "| \`brief.md\` | \`/ideation\` (tuỳ chọn) |"
    echo "| \`spec.md\`, \`open-questions.md\` | \`/spec\` |"
    echo "| \`plan.md\` | \`/plan\`, cập nhật bởi \`/implement\` |"
    echo "| \`ket-qua-kiem-thu.md\` | công cụ kiểm tra tự ghi |"
    echo "| \`review.md\` | \`/review\` |"
    echo ""
    echo "Bộ cài của quy trình nằm trong \`.quy-trinh/\` — đó là file sinh ra,"
    echo "cài lại sẽ ghi đè. Chỉ \`.quy-trinh/cau-hinh.sh\` là do người sửa."
  } > "$ARTDIR/README.md"
  echo "  ghi     $ART/README.md"
fi

# ---- 4. Chay adapter ----
echo ""
sh "$ad_dir/build.sh" --out "$DICH" $FORCE

# ---- 5. Huong dan tiep theo ----
echo ""
echo "Xong. Bước tiếp theo:"
echo ""
if [ -z "$LENH" ] && ! grep -q 'LENH_KIEM_THU="[^"]' "$CH" 2>/dev/null; then
  echo "  1. Khai báo lệnh kiểm thử trong $ART/.quy-trinh/cau-hinh.sh"
  echo "     (chưa khai thì phase /implement sẽ không đạt điều kiện ra)"
  echo "  2. Mở Claude Code trong repo đích, chạy /spec"
else
  echo "  1. Mở Claude Code trong repo đích, chạy /spec"
fi
echo ""
echo "  Chuỗi phase: /spec → /plan → /implement → /review"
