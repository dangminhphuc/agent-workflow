#!/usr/bin/env sh
# Sinh adapter vào một worktree (hoặc checkout chính). Dùng bởi aw adapter build,
# aw init và aw worktree new --create.
#
#   sh tools/sinh-adapter.sh <agent> <thư-mục-đích> [--force]
#
# Hai bước, cả hai chỉ ghi vào đường dẫn đã exclude (aw init):
#   1. <đích>/.agent-workflow/.engine/  rules, templates, checkers của engine đang
#      chạy + VERSION; conventions.md là liên kết tới $AW_CONFIG/conventions.md.
#      Mọi agent đọc được file — phần này không thuộc adapter nào.
#   2. adapters/<agent>/build.sh --out <đích> — lớp mỏng native của agent.

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ENG="${AW_ENGINE:-$(CDPATH= cd -- "$HERE/.." && pwd)}"

AG="${1:-}"; OUT="${2:-}"; FORCE="${3:-}"
[ -n "$AG" ] && [ -n "$OUT" ] || { echo "Dùng: sh tools/sinh-adapter.sh <agent> <thư-mục-đích> [--force]" >&2; exit 2; }
[ -f "$ENG/adapters/$AG/build.sh" ] || { echo "LỖI: không có adapter \"$AG\"." >&2; exit 2; }
[ -d "$OUT" ] || { echo "LỖI: không có thư mục $OUT" >&2; exit 2; }
case "$(CDPATH= cd -- "$OUT" && pwd)/" in
  "$ENG"/*) echo "LỖI: thư mục đích nằm trong engine ($OUT)." >&2; exit 2 ;;
esac

D="$OUT/.agent-workflow/.engine"
rm -rf "$D"; mkdir -p "$D" || exit 2
cp -R "$ENG/workflow/rules" "$ENG/workflow/templates" "$ENG/workflow/checkers" "$D/" || exit 2
cp "$ENG/VERSION" "$D/VERSION"
if [ -n "${AW_CONFIG:-}" ]; then
  ln -s "$AW_CONFIG/conventions.md" "$D/conventions.md" 2>/dev/null || cp "$AW_CONFIG/conventions.md" "$D/conventions.md" 2>/dev/null
fi
echo "  copy    .agent-workflow/.engine/{rules,templates,checkers} (engine $(cat "$ENG/VERSION"))"
exec sh "$ENG/adapters/$AG/build.sh" --out "$OUT" $FORCE
