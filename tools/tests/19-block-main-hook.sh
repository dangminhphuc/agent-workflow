#!/usr/bin/env sh
# .claude/hooks/block-main.sh: hook PreToolUse của repo engine — chặn agent sửa file, commit,
# push trên nhánh main của chính repo này; worktree nhánh khác và repo khác cho qua.
# Chạy riêng: sh tools/tests/19-block-main-hook.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

H="$ROOT/.claude/hooks/block-main.sh"
M="$TMP/repo-main"
W="$TMP/repo-wt"
KHAC="$TMP/repo-khac"
for d in "$M" "$KHAC"; do
  git -c init.defaultBranch=main init -q "$d"
  git -C "$d" commit -q --allow-empty -m init
done
git -C "$M" worktree add -q -b feat/x "$W"

# hook <json> [project-dir] — chạy hook như Claude Code: JSON qua stdin
hook() { printf '%s' "$1" | CLAUDE_PROJECT_DIR="${2:-$M}" sh "$H"; }
sua() { hook "{\"tool_name\":\"$1\",\"tool_input\":{\"file_path\":\"$2\",\"content\":\"x\"},\"cwd\":\"$M\"}"; }
lenh() { hook "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$2\",\"description\":\"d\"},\"cwd\":\"$1\"}"; }

nhom "Hook chặn sửa trên main: Edit/Write/NotebookEdit"
ky_vong 2 "Edit file trong checkout main → chặn" sua Edit "$M/AGENTS.md"
ky_vong 2 "Write file mới trong thư mục chưa có của checkout main → chặn" sua Write "$M/a/b/moi.md"
hook "{\"tool_name\":\"NotebookEdit\",\"tool_input\":{\"notebook_path\":\"$M/n.ipynb\"},\"cwd\":\"$M\"}" >/dev/null 2>&1
dung "NotebookEdit trong checkout main → chặn" bang $? 2
ky_vong 0 "Write trong worktree nhánh khác → cho qua" sua Write "$W/AGENTS.md"
ky_vong 0 "Write ngoài git (scratchpad, memory) → cho qua" sua Write "$TMP/ngoai/x.md"
ky_vong 0 "Write trong repo khác đang ở main → cho qua" sua Write "$KHAC/x.md"
ky_vong 0 "session mở trong worktree, Write trong worktree đó → cho qua" \
  hook "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$W/x.md\"},\"cwd\":\"$W\"}" "$W"
ky_vong 2 "session mở trong worktree, Edit vào checkout main → chặn" \
  hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$M/x.md\"},\"cwd\":\"$W\"}" "$W"
sua Edit "$M/AGENTS.md" > /dev/null 2> "$TMP/thongbao"
dung "thông báo chặn chỉ cách làm đúng: worktree từ origin/main" grep -q 'origin/main' "$TMP/thongbao"

nhom "Hook chặn commit/push trên main: Bash"
ky_vong 2 "git commit, cwd là checkout main → chặn" lenh "$M" "git commit -m x"
ky_vong 2 "cd vào checkout main rồi commit → chặn" lenh "$W" "cd $M && git add -A && git commit -m x"
ky_vong 2 "git -C checkout-main commit → chặn" lenh "$W" "git -C $M commit -m x"
ky_vong 2 "git push từ checkout main → chặn" lenh "$M" "git push origin HEAD"
ky_vong 2 "push vào main từ worktree (HEAD:main) → chặn" lenh "$W" "git push origin HEAD:main"
ky_vong 2 "push nhánh main từ worktree → chặn" lenh "$W" "git push origin main"
ky_vong 2 "git merge trên checkout main → chặn" lenh "$M" "git merge feat/x"
ky_vong 0 "git commit trong worktree nhánh khác → cho qua" lenh "$W" "git commit -m x"
ky_vong 0 "git -C worktree commit, cwd là main → cho qua" lenh "$M" "git -C $W commit -m x"
ky_vong 0 "push nhánh việc → cho qua" lenh "$W" "git push -u origin feat/x"
ky_vong 0 "push nhánh có chữ main trong tên → cho qua" lenh "$W" "git push -u origin chore/main-guard"
ky_vong 0 "lệnh đọc trên main (status, log, fetch, pull, worktree add) → cho qua" \
  lenh "$M" "git status && git log -1 && git fetch && git pull && git worktree add ../y -b y origin/main"
ky_vong 0 "commit trong repo khác đang ở main → cho qua" lenh "$KHAC" "git commit -m x"
ky_vong 0 "tool khác (Read) → cho qua" \
  hook "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$M/AGENTS.md\"},\"cwd\":\"$M\"}"

ket_thuc
