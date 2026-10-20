#!/usr/bin/env sh
# Hook PreToolUse (Claude Code) của repo engine: mọi thay đổi đi qua worktree từ origin/main + PR.
# Chặn (mã 2) khi agent:
#   - Edit/Write/NotebookEdit một file nằm trong checkout đang ở nhánh main của repo này;
#   - chạy git commit/merge/rebase/cherry-pick/revert/am/push trong checkout đó (theo cwd, `cd X`,
#     `git -C X`), hoặc push thẳng vào main từ bất cứ đâu.
# Repo khác, worktree nhánh khác, file ngoài git: cho qua. Lệnh shell tự ghi file (sed -i, >) không
# bắt được — luật chữ trong AGENTS.md vẫn là chính. Test: tools/tests/19-block-main-hook.sh.

VAO=$(cat)

# lay <khoá> — giá trị chuỗi đầu tiên của khoá trong JSON đầu vào (một dòng, chưa bỏ escape)
lay() {
  printf '%s' "$VAO" | sed -n -E 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | head -n 1
}

# chung_repo <thư-mục> — git common dir (tuyệt đối) của repo chứa thư mục; rỗng nếu ngoài git
chung_repo() {
  _c=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 0
  case "$_c" in /*) ;; *) _c="$1/$_c" ;; esac
  (CDPATH= cd -- "$_c" 2>/dev/null && pwd -P)
}

DU_AN=$(chung_repo "${CLAUDE_PROJECT_DIR:-.}")
[ -n "$DU_AN" ] || exit 0

# tren_main <đường-dẫn> — 0 nếu đường dẫn nằm trong checkout nhánh main của repo này
tren_main() {
  _d=$1
  while [ ! -d "$_d" ]; do _d=$(dirname -- "$_d"); done
  [ "$(chung_repo "$_d")" = "$DU_AN" ] || return 1
  [ "$(git -C "$_d" symbolic-ref --short -q HEAD)" = main ]
}

chan() {
  printf '%s\n' "BLOCKED: $1 on branch main of this repo. Every change goes through a worktree: git fetch origin && git worktree add <path> -b <branch> origin/main, work there, open a PR into main. The human merges." >&2
  exit 2
}

case "$(lay tool_name)" in
  Edit|Write|NotebookEdit|MultiEdit)
    F=$(lay file_path); [ -n "$F" ] || F=$(lay notebook_path)
    [ -n "$F" ] || exit 0
    case "$F" in /*) ;; *) F="$(lay cwd)/$F" ;; esac
    if tren_main "$F"; then chan "editing $F"; fi
    exit 0 ;;
  Bash) ;;
  *) exit 0 ;;
esac

LENH=$(lay command | sed 's/\\n/;/g; s/\\"/"/g; s/\\\\/\\/g')
DIR=$(lay cwd); [ -n "$DIR" ] || DIR=$(pwd)

# Tách lệnh thành từng đoạn theo && || ; | rồi xét lần lượt, nhớ thư mục sau mỗi `cd`.
set -f
printf '%s\n' "$LENH" | awk '{ gsub(/&&|\|\||[;|]/, "\n"); print }' |
while IFS= read -r DOAN; do
  set -- $DOAN
  # bỏ gán biến môi trường đứng đầu (GIT_X=1 git …)
  while [ $# -gt 0 ]; do case "$1" in *=*) shift ;; *) break ;; esac; done
  [ $# -gt 0 ] || continue
  case "$1" in
    cd)
      if [ $# -ge 2 ]; then
        case "$2" in /*) DIR=$2 ;; *) DIR="$DIR/$2" ;; esac
      fi
      continue ;;
    git) shift ;;
    *) continue ;;
  esac
  G=$DIR
  while [ $# -gt 0 ]; do
    case "$1" in
      -C) case "$2" in /*) G=$2 ;; *) G="$G/$2" ;; esac; shift 2 ;;
      -c) shift 2 ;;
      -*) shift ;;
      *) break ;;
    esac
  done
  [ $# -gt 0 ] || continue
  LENH_CON=$1; shift
  case "$LENH_CON" in
    commit|merge|rebase|cherry-pick|revert|am|push)
      if tren_main "$G"; then chan "git $LENH_CON"; fi ;;
  esac
  if [ "$LENH_CON" = push ]; then
    for a in "$@"; do
      case "$a" in
        main|*:main|refs/heads/main|*:refs/heads/main)
          chan "git push $a" ;;
      esac
    done
  fi
done
exit $?
