#!/usr/bin/env sh
# Danh sách adapter của bản clone — một nguồn cho aw init, aw worktree new,
# aw adapter build, aw doctor.
#
# ADAPTER trong config.sh là MỘT HOẶC NHIỀU id, cách nhau dấu cách hoặc dấu phẩy:
#   ADAPTER="claude-code"            chỉ Claude Code
#   ADAPTER="claude-code cursor"     team dùng cả hai — mỗi worktree có cả hai bộ lệnh
# Bỏ trống = claude-code (như trước khi có nhiều adapter).

# al_chuan <chuỗi> -> các id cách nhau một dấu cách, bỏ trùng, giữ thứ tự.
al_chuan() {
  printf '%s\n' "$1" | tr ',\t' '  ' | tr ' ' '\n' |
    awk 'NF && !thay[$0]++ { printf "%s%s", (n++ ? " " : ""), $0 }'
}

# al_doc <config.sh> -> danh sách đã chuẩn hoá (rỗng/không có file → claude-code).
al_doc() {
  _al=""
  [ -f "$1" ] && _al=$(. "$1" >/dev/null 2>&1; printf '%s' "${ADAPTER:-}")
  _al=$(al_chuan "$_al")
  printf '%s' "${_al:-claude-code}"
}

# al_co <engine> -> các adapter engine có, cách nhau dấu cách.
al_co() {
  for _d in "$1"/adapters/*/; do
    [ -f "$_d/build.sh" ] && basename "$_d"
  done | awk '{ printf "%s%s", (n++ ? " " : ""), $0 }'
}

# al_kiem <engine> <danh-sách> -> 0 nếu mọi id có adapter; không thì in lỗi, mã 1.
al_kiem() {
  _ok=0
  for _i in $2; do
    case "$_i" in
      lib|*/*|.*) _ok=1 ;;
      *) [ -f "$1/adapters/$_i/build.sh" ] || _ok=1 ;;
    esac
    [ "$_ok" = 0 ] || { echo "LỖI: không có adapter \"$_i\" (có: $(al_co "$1"))." >&2; return 1; }
  done
  [ -n "$2" ] || { echo "LỖI: danh sách adapter rỗng." >&2; return 1; }
}

# al_cung <a> <b> -> 0 nếu hai danh sách cùng tập id (không kể thứ tự).
al_cung() {
  [ "$(al_chuan "$1" | tr ' ' '\n' | sort)" = "$(al_chuan "$2" | tr ' ' '\n' | sort)" ]
}

# al_exclude <engine> <danh-sách> -> mẫu exclude của mọi adapter, mỗi dòng một mẫu, bỏ trùng.
al_exclude() {
  for _i in $2; do
    [ -f "$1/adapters/$_i/exclude" ] && grep -v '^#' "$1/adapters/$_i/exclude"
  done | awk 'NF && !thay[$0]++'
}

# al_ghi_exclude <engine> <danh-sách> <thư-mục-trong-repo> -> thêm vào .git/info/exclude
# (của git common dir) /.agent-workflow/ và mẫu của mọi adapter còn thiếu; in các mẫu
# vừa thêm, cách nhau dấu cách. Không phải repo git: không làm gì. aw init và
# aw adapter build đều gọi — adapter đổi đường dẫn sinh ra (vd skill đổi tên) thì
# bản clone đã init từ trước vẫn không để lọt file sinh ra vào git status.
al_ghi_exclude() {
  _gc=$(git -C "$3" rev-parse --git-common-dir 2>/dev/null) || return 0
  case "$_gc" in /*) ;; *) _gc="$(CDPATH= cd -- "$3" && pwd)/$_gc" ;; esac
  _ex="$_gc/info/exclude"; mkdir -p "$_gc/info"
  _them=""
  for _p in /.agent-workflow/ $(al_exclude "$1" "$2"); do
    grep -qxF "$_p" "$_ex" 2>/dev/null && continue
    grep -qxF '# agent-workflow — aw init: file sinh ra / cục bộ, không commit' "$_ex" 2>/dev/null ||
      printf '\n# agent-workflow — aw init: file sinh ra / cục bộ, không commit\n' >> "$_ex"
    printf '%s\n' "$_p" >> "$_ex"; _them="$_them $_p"
  done
  printf '%s' "${_them# }"
}
