#!/usr/bin/env sh
# Sinh adapter vào một worktree (hoặc checkout chính). Dùng bởi aw adapter build,
# aw init và aw worktree new --create.
#
#   sh tools/sinh-adapter.sh <agent>[,<agent>…] <thư-mục-đích> [--force]
#   (danh sách cũng được cách nhau dấu cách, đặt trong nháy: "claude-code cursor")
#
# Hai bước, cả hai chỉ ghi vào đường dẫn đã exclude (aw init):
#   1. <đích>/.agent-workflow/.engine/  rules, templates, checkers của engine đang
#      chạy + VERSION; conventions.md là liên kết tới $AW_CONFIG/conventions.md.
#      Mọi agent đọc được file — phần này không thuộc adapter nào, chép MỘT lần.
#   2. adapters/<agent>/build.sh --out <đích> cho TỪNG adapter — lớp mỏng native
#      của agent. Một adapter hỏng không chặn adapter khác; mã thoát là mã của
#      adapter hỏng đầu tiên.
#
# Sau mỗi adapter build thành công: dòng "<agent> <version>" trong
# <đích>/.agent-workflow/.adapters — aw doctor đối chiếu với ADAPTER trong config.sh
# để thấy worktree thiếu bộ lệnh của một agent, hay bộ lệnh cũ hơn engine.

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ENG="${AW_ENGINE:-$(CDPATH= cd -- "$HERE/.." && pwd)}"
. "$HERE/lib/adapter.sh"

AG=$(al_chuan "${1:-}"); OUT="${2:-}"; FORCE="${3:-}"
[ -n "$AG" ] && [ -n "$OUT" ] || { echo "Dùng: sh tools/sinh-adapter.sh <agent>[,<agent>…] <thư-mục-đích> [--force]" >&2; exit 2; }
al_kiem "$ENG" "$AG" || exit 2
[ -d "$OUT" ] || { echo "LỖI: không có thư mục $OUT" >&2; exit 2; }
case "$(CDPATH= cd -- "$OUT" && pwd)/" in
  "$ENG"/*) echo "LỖI: thư mục đích nằm trong engine ($OUT)." >&2; exit 2 ;;
esac

V=$(tr -d ' \r\n' < "$ENG/VERSION")
D="$OUT/.agent-workflow/.engine"
rm -rf "$D"; mkdir -p "$D" || exit 2
cp -R "$ENG/workflow/rules" "$ENG/workflow/templates" "$ENG/workflow/checkers" "$D/" || exit 2
cp "$ENG/VERSION" "$D/VERSION"
if [ -n "${AW_CONFIG:-}" ]; then
  ln -s "$AW_CONFIG/conventions.md" "$D/conventions.md" 2>/dev/null || cp "$AW_CONFIG/conventions.md" "$D/conventions.md" 2>/dev/null
fi
echo "  copy    .agent-workflow/.engine/{rules,templates,checkers} (engine $V)"

DAU="$OUT/.agent-workflow/.adapters"
ma=0
for a in $AG; do
  echo ""
  echo "Adapter $a:"
  sh "$ENG/adapters/$a/build.sh" --out "$OUT" $FORCE
  rc=$?
  if [ "$rc" = 0 ]; then
    { [ -f "$DAU" ] && awk -v a="$a" '$1 != a' "$DAU"; printf '%s %s\n' "$a" "$V"; } > "$DAU.tmp" && mv "$DAU.tmp" "$DAU"
  elif [ "$ma" = 0 ]; then
    ma=$rc
  fi
done
exit "$ma"
