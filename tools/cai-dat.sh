#!/usr/bin/env sh
# Cai quy trinh vao mot repo khac.
#
#   sh tools/cai-dat.sh <thu-muc-repo-dich> [tuy chon]
#
# Tuy chon:
#   --adapter <id>        mac dinh: claude-code
#   --lenh-kiem-thu <s>   vi du: "npm test" — dung cho dieu kien ra phase 04-implement
#   --force               cho phep ghi de file nguoi viet tay
#   --nguon <url|thu-muc> repo nguon ghi vao nguon.txt (mac dinh: origin cua repo nay)
#   --nhanh <ten>         nhanh nguon de dong-bo.sh theo doi (mac dinh: nhanh hien tai)
#
# Cai vao repo dich:
#   .agent-workflow/.quy-trinh/{rules,templates,checkers,tools}   bo cai (cai lai se ghi de)
#   .agent-workflow/.quy-trinh/nguon.txt   cai tu dau, commit nao — dong-bo.sh doc de cap nhat
#   .agent-workflow/conventions.md    quy uoc cua repo — NGUOI viet, khong bao gio ghi de
#   .agent-workflow/<ten-branch>/     artifact cua tung feature
#   .claude/**                                           do adapter sinh ra

set -e
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tools/lib/ket-qua.sh"
# 3 và 4 đến từ adapter (build.sh) — cùng nghĩa.
kq_khai cai-dat.sh \
  "0=ĐÃ CÀI — làm theo các bước tiếp theo phía trên" \
  "2=SAI THAM SỐ HOẶC THƯ MỤC ĐÍCH KHÔNG HỢP LỆ" \
  "3=CÓ FILE VIẾT TAY — không ghi đè; dời file đó đi hoặc dùng --force" \
  "4=ĐỊNH NGHĨA QUY TRÌNH LỖI — sửa workflow/ trong repo agent-workflow"

DICH=""
ADAPTER="claude-code"
LENH=""
FORCE=""
NGUON=""
NHANH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --adapter)       ADAPTER="$2"; shift 2 ;;
    --lenh-kiem-thu) LENH="$2";    shift 2 ;;
    --force)         FORCE="--force"; shift ;;
    --nguon)         NGUON="$2";   shift 2 ;;
    --nhanh)         NHANH="$2";   shift 2 ;;
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
# Chan ca thu muc CON cua repo nguon (vd adapters/), khong chi chinh no:
# cai vao do se rai .agent-workflow/ va .claude/ lan vao ma nguon.
case "$DICH/" in
  "$ROOT"/*)
    echo "LỖI: không cài quy trình vào repo agent-workflow hay thư mục con của nó." >&2
    echo "      Repo này là nguồn; repo đích mới là nơi tiêu thụ." >&2
    exit 2 ;;
esac

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

# ---- 1. Bo cai (luat, mau, checker LLM, cong cu) ----
# Xoa truoc khi chep: file ma ban moi bo di (doi ten, gop) khong duoc nam lai,
# neu khong agent van goi duoc cong cu cu. Cac thu muc nay hoan toan cua bo cai;
# file NGUOI sua (cau-hinh.sh) nam ngoai chung.
rm -rf "$QT/rules" "$QT/templates" "$QT/checkers" "$QT/tools"
mkdir -p "$QT/rules" "$QT/templates" "$QT/checkers" "$QT/tools/lib"
cp "$ROOT"/workflow/rules/*.md      "$QT/rules/"
cp "$ROOT"/workflow/templates/*.md  "$QT/templates/"
cp "$ROOT"/workflow/checkers/*.md   "$QT/checkers/"
cp "$ROOT"/tools/kiem-tra-*.sh "$ROOT"/tools/xac-dinh-feature.sh "$ROOT"/tools/cap-nhat-based-on.sh \
   "$ROOT"/tools/doi-ten-feature.sh "$ROOT"/tools/tao-worktree.sh "$ROOT"/tools/don-worktree.sh \
   "$ROOT"/tools/phan-loai-input.sh "$ROOT"/tools/dong-bo.sh "$QT/tools/"
cp "$ROOT"/tools/lib/*.sh           "$QT/tools/lib/"
chmod +x "$QT"/tools/*.sh 2>/dev/null || true
echo "  chép    $ART/.quy-trinh/{rules,templates,checkers,tools}"

# ---- 1b. Nguon goc cua bo cai — de dong-bo.sh biet keo ban moi tu dau ----
# Bo phan user:token@ trong URL: file nay duoc commit vao repo dich.
if [ -z "$NGUON" ]; then
  NGUON=$(git -C "$ROOT" remote get-url origin 2>/dev/null) || NGUON="$ROOT"
fi
NGUON=$(printf '%s' "$NGUON" | sed 's#://[^/@]*@#://#')
if [ -z "$NHANH" ]; then
  NHANH=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null) || NHANH=""
  [ "$NHANH" = "HEAD" ] && NHANH=""
fi
COMMIT=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null) || COMMIT=""
SUA=""
[ -n "$COMMIT" ] && [ -n "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ] && SUA=1
{
  echo "# SINH TỰ ĐỘNG bởi tools/cai-dat.sh — nguồn của bộ cài này."
  echo "# tools/dong-bo.sh đọc file này để kéo bản mới. Đổi nguồn: dong-bo.sh --nguon <url>."
  echo "url=$NGUON"
  echo "nhanh=$NHANH"
  echo "commit=$COMMIT"
  echo "co_thay_doi_chua_commit=${SUA:-khong}"
  echo "adapter=$ADAPTER"
} > "$QT/nguon.txt"
echo "  ghi     $ART/.quy-trinh/nguon.txt (nguồn: $NGUON${NHANH:+ @ $NHANH})"

# ---- 2. Cau hinh rieng cua repo dich ----
CH="$QT/cau-hinh.sh"
if [ -f "$CH" ] && [ -z "$FORCE" ]; then
  echo "  giữ     $ART/.quy-trinh/cau-hinh.sh (đã có, không ghi đè)"
else
  {
    echo "# Cấu hình của repo này cho quy trình agent-workflow."
    echo "# File này do NGƯỜI sửa, adapter không ghi đè khi cài lại."
    echo ""
    echo "# Lệnh kiểm thử — điều kiện ra của phase 04-implement."
    echo "# Bỏ trống thì phase implement sẽ KHÔNG ĐẠT, không phải \"bỏ qua\"."
    echo "LENH_KIEM_THU=\"$LENH\""
    echo ""
    echo "# Lệnh đo hiệu năng — chỉ dùng cho loại việc perf. Phải in một dòng"
    echo "# \"KET_QUA: <số> <đơn vị>\", vd: KET_QUA: 138 ms"
    echo "LENH_DO_HIEU_NANG=\"\""
    echo ""
    echo "# Lệnh chuẩn bị worktree mới (cài dependency…) — tao-worktree.sh IN RA cho"
    echo "# người chạy, không tự chạy. Worktree mới chỉ có file đã commit: không có"
    echo "# node_modules, .env… Vd: LENH_CHUAN_BI_WT=\"npm ci\""
    echo "LENH_CHUAN_BI_WT=\"\""
  } > "$CH"
  echo "  ghi     $ART/.quy-trinh/cau-hinh.sh"
fi

# ---- 3. conventions.md — cua NGUOI, khong bao gio ghi de (ke ca --force) ----
ARTDIR="$DICH/$ART"
if [ -f "$ARTDIR/conventions.md" ]; then
  echo "  giữ     $ART/conventions.md (của bạn, không bao giờ ghi đè)"
else
  cp "$ROOT/workflow/templates/conventions.md" "$ARTDIR/conventions.md"
  echo "  tạo     $ART/conventions.md từ mẫu — hãy sửa cho đúng repo của bạn"
fi

# ---- 4. README cua noi chua artifact (sinh tu dong, cai lai se cap nhat) ----
if [ ! -f "$ARTDIR/README.md" ] || grep -q 'SINH TỰ ĐỘNG' "$ARTDIR/README.md"; then
  {
    echo "# Artifact bàn giao của quy trình"
    echo ""
    echo "> File này được SINH TỰ ĐỘNG bởi \`tools/cai-dat.sh\`; cài lại sẽ cập nhật."
    echo ""
    echo "Mỗi feature có một thư mục \`<tên-branch>/\` chứa file do từng phase ghi ra."
    echo "Chúng là **bàn giao giữa các phase**, không phải ghi chú tạm — nên commit vào git."
    echo ""
    echo "| File trong \`<tên-branch>/\` | Do phase nào ghi |"
    echo "|---|---|"
    echo "| \`intake.md\` | \`/intake\` — loại việc + input, điểm xuất phát bắt buộc |"
    echo "| \`spec.md\`, \`open-questions.md\` | \`/spec\` |"
    echo "| \`tdd.md\`, \`phat-hien-thiet-ke.md\` | \`/design\` (phát hiện do checker LLM ghi) |"
    echo "| \`plan.md\` | \`/plan\`, cập nhật bởi \`/implement\` |"
    echo "| \`ket-qua-kiem-thu.md\`, \`tai-hien.md\` (bugfix), \`do-hieu-nang.md\` (perf) | công cụ kiểm tra tự ghi |"
    echo "| \`review.md\` | \`/review\` |"
    echo ""
    echo "- \`conventions.md\` — quy ước của repo, **bạn** viết; bộ cài không bao giờ ghi đè."
    echo "- \`.quy-trinh/\` — bộ cài, cài lại sẽ ghi đè; chỉ \`.quy-trinh/cau-hinh.sh\` là do người sửa."
  } > "$ARTDIR/README.md"
  echo "  ghi     $ART/README.md"
fi

# ---- 5. Chay adapter ----
echo ""
sh "$ad_dir/build.sh" --out "$DICH" $FORCE

# ---- 6. Huong dan tiep theo ----
echo ""
echo "Xong. Bước tiếp theo:"
echo ""
n=1
if [ -z "$LENH" ] && ! grep -q 'LENH_KIEM_THU="[^"]' "$CH" 2>/dev/null; then
  echo "  $n. Khai báo lệnh kiểm thử trong $ART/.quy-trinh/cau-hinh.sh"
  echo "     (chưa khai thì phase /implement sẽ không đạt điều kiện ra)"
  n=$((n + 1))
fi
echo "  $n. Sửa $ART/conventions.md: mẫu tên branch, nhánh gốc, vị trí worktree, mẫu file test, tag covers:"
n=$((n + 1))
echo "  $n. COMMIT bộ cài ($ART/) vào nhánh gốc — worktree chỉ có file đã commit"
n=$((n + 1))
echo "  $n. Mở Claude Code ở checkout chính (đứng ở nhánh gốc), chạy /intake — nó đề xuất worktree cho việc"
echo ""
echo "  Chuỗi phase: /intake → /spec → /design → /plan → /implement → /review"
echo "  Tài liệu làm bằng tool khác: /import <file> <spec.md|tdd.md|plan.md>"
echo "  Cập nhật khi repo agent-workflow có bản mới: sh $ART/.quy-trinh/tools/dong-bo.sh"
