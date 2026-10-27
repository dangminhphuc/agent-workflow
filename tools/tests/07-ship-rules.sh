#!/usr/bin/env sh
# check-ship, rules_*.
# Chạy riêng: sh tools/tests/07-ship-rules.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
fixture_sau_bao_mat

# ---------------------------------------------------------------- check-ship (aw check ship)
nhom "check-ship.sh (aw check ship)"
SHC="$T/check-ship.sh"
ky_vong 2 "chưa có merge-request.md → NO INPUT" sh "$SHC" "$F"
viet_mr
ky_vong 0 "mô tả MR đủ mục, review đạt → PASS" sh "$SHC" "$F"
thay "$F/merge-request.md" '# ABC-1: hiện a và b trên màn hình y' '# <JIRA-KEY>: <verb> <what> <where>'
ky_vong 1 "tiêu đề còn chữ giữ chỗ → chặn" sh "$SHC" "$F"
viet_mr; thay "$F/merge-request.md" '## Out of Scope

None

' ''
ky_vong_ly_do 1 "xoá mất một mục của mẫu → chặn (không áp dụng thì ghi None)" "…đúng lý do" 'Thiếu mục "## Out of Scope"' sh "$SHC" "$F"
viet_mr; thay "$F/merge-request.md" '- **Added:** test/a.test.js — có a và b
- **Commands:** `npm test` → xanh' '<!-- chưa viết -->'
ky_vong 1 "Testing chỉ có comment → chặn (mục bắt buộc trống)" sh "$SHC" "$F"
viet_mr; thay "$F/merge-request.md" '- **Added:** test/a.test.js — có a và b' '- **Added:** <test> — <chứng minh gì>'
ky_vong 1 "còn chữ giữ chỗ của mẫu ngoài comment → chặn" sh "$SHC" "$F"
viet_mr; thay "$F/merge-request.md" '# ABC-1: hiện a và b trên màn hình y' '# hiện a và b trên màn hình y'
ky_vong 0 "tiêu đề thiếu mã Jira của intake → chỉ cảnh báo" sh "$SHC" "$F"
dung "…có cảnh báo" sh -c "sh '$SHC' '$F' | grep -q 'WARN.*ABC-1'"
viet_mr
printf '\n## Lens 3 — Quality\n\n### [Blocker] tràn bộ nhớ\n' >> "$F/review.md"
ky_vong 1 "review.md còn [Blocker] → chặn" sh "$SHC" "$F"
viet_review
printf '| ID | Verdict |\n|---|---|\n| REQ-001 | pass |\n' > "$F/review.md"
ky_vong 1 "aw check review không đạt → chặn" sh "$SHC" "$F"
viet_review
ky_vong 0 "aw-engine check ship → đúng checker" sh "$AWE" check ship "$F"

# ---------------------------------------------------------------- quy tac repo
nhom "quy tắc riêng của repo (rules_*, aw rules)"
QT="$T/rules.sh"
CONV="$CFG/conventions.md"
cp "$CONV" "$TMP/conv-qt.bak"
# khai_qt <phase> <giá trị> — khai lại từ đầu một khoá rules_<phase>
khai_qt() { cp "$TMP/conv-qt.bak" "$CONV"; thay "$CONV" "rules_$1:" "rules_$1: $2"; }

ky_vong 0 "không khai gì → aw rules LISTED" sh "$QT" implement
dung "…stdout rỗng" bang "$(sh "$QT" implement 2>/dev/null)" ""
ky_vong 2 "aw rules thiếu phase → BAD ARGS" sh "$QT"
ky_vong 2 "aw rules phase không có quy tắc (intake) → BAD ARGS" sh "$QT" intake
ky_vong 0 "aw-engine rules → đúng script" sh "$AWE" rules implement

khai_qt implement 'docs/quy-tac.md'
dung "khai implement → aw rules implement in đúng file" bang "$(sh "$QT" implement 2>/dev/null)" "docs/quy-tac.md"
dung "…phase khác không thấy" bang "$(sh "$QT" spec 2>/dev/null)" ""
khai_qt spec 'docs/quy-tac-2.md docs/quy-tac.md'
thay "$CONV" 'rules_implement:' 'rules_implement: docs/quy-tac.md'
dung "review = hợp mọi khoá, bỏ trùng, giữ thứ tự" bang "$(sh "$QT" review 2>/dev/null | tr '\n' ' ')" "docs/quy-tac-2.md docs/quy-tac.md "

for p in spec:spec design:design plan:plan; do
  khai_qt "${p%%:*}" 'docs/khong-co.md'
  ky_vong 1 "${p%%:*}: file quy tắc không có → aw check ${p%%:*} chặn" sh "$T/check-${p#*:}.sh" "$F"
done
khai_qt implement 'docs/khong-co.md'
ky_vong_ly_do 1 "implement: file quy tắc không có → aw check implement chặn" "…đúng lý do" 'quy tắc repo "docs/khong-co.md": không có file' sh "$T/check-implement.sh" "$F"
ky_vong 1 "…aw rules implement ra KHAI SAI" sh "$QT" implement
ky_vong 0 "…phase không khai thì không bị ảnh hưởng" sh "$T/check-spec.sh" "$F"
ky_vong 1 "…review chặn (cổng cuối kiểm mọi khoá)" sh "$T/check-review.sh" "$F"

printf 'x\n' > "$R/docs/chua-commit.md"
khai_qt implement 'docs/chua-commit.md'
ky_vong_ly_do 1 "file quy tắc chưa commit → chặn" "…đúng lý do: chưa commit" 'chưa commit' sh "$QT" implement
rm -f "$R/docs/chua-commit.md"

mkdir -p "$R/.claude/skills/x"; printf 'x\n' > "$R/.claude/skills/x/SKILL.md"
printf '/.claude/\n' >> "$R/.git/info/exclude"
khai_qt implement '.claude/skills/x/SKILL.md'
ky_vong 1 "skill trong /.claude/ bị exclude → chặn" sh "$QT" implement
dung "…chỉ rõ git đang bỏ qua + git add -f" sh -c "sh '$QT' implement 2>&1 | grep -q 'git đang bỏ qua.*git add -f'"
git -C "$R" -c user.name=t -c user.email=t@t add -f .claude/skills/x/SKILL.md >/dev/null 2>&1
ky_vong 0 "…đã git add -f thì cho qua" sh "$QT" implement
git -C "$R" rm -q --cached .claude/skills/x/SKILL.md >/dev/null 2>&1; rm -rf "$R/.claude/skills/x"

for v in /etc/hosts ../x docs/../../x; do
  khai_qt implement "$v"
  ky_vong 1 "đường dẫn ra ngoài repo ($v) → chặn" sh "$QT" implement
done

cp "$TMP/conv-qt.bak" "$CONV"
thay "$CONV" 'rules_review:' 'rules_review:
rules_implment: docs/quy-tac.md'
ky_vong_ly_do 1 "khoá gõ nhầm (rules_implment) → aw rules chặn" "…đúng lý do" 'rules_implment.*không ứng với phase' sh "$QT" implement
ky_vong 1 "…review chặn" sh "$T/check-review.sh" "$F"

# Review: mỗi file quy tắc một kết luận
khai_qt implement 'docs/quy-tac.md'
viet_review
ky_vong_ly_do 1 "review.md thiếu mục Quy tắc repo → chặn" "…đúng lý do" 'thiếu mục "## Repo rules"' sh "$T/check-review.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | pass | |'
ky_vong 0 "có kết luận đạt → cho qua" sh "$T/check-review.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | ổn | |'
ky_vong 1 "kết luận tự chế → chặn" sh "$T/check-review.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | violation | |'
ky_vong 1 "vi phạm không kèm vị trí → chặn" sh "$T/check-review.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | violation | `src/a.txt:1` |'
ky_vong 0 "vi phạm có vị trí → cho qua (người phán finding)" sh "$T/check-review.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | not applicable | <lý do> |'
ky_vong 1 "không áp dụng còn chỗ giữ chỗ → chặn" sh "$T/check-review.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | not applicable | không đụng API |'
ky_vong 0 "không áp dụng có lý do → cho qua" sh "$T/check-review.sh" "$F"
khai_qt spec 'docs/quy-tac-2.md'
thay "$CONV" 'rules_implement:' 'rules_implement: docs/quy-tac.md'
ky_vong_ly_do 1 "review thiếu dòng cho quy tắc của phase khác (spec) → chặn" "…đúng lý do" 'docs/quy-tac-2.md": không có verdict' sh "$T/check-review.sh" "$F"
cp "$TMP/conv-qt.bak" "$CONV"; viet_review
ky_vong 0 "bỏ hết khoá → review như cũ" sh "$T/check-review.sh" "$F"

ket_thuc
