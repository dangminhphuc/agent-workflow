#!/usr/bin/env sh
# check-ship, rules_*, uses_*, pending, based-on.
# Chạy riêng: sh tools/tests/07-ship-rules-uses.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
fixture_sau_bao_mat

# ---------------------------------------------------------------- check-ship (aw check ship)
nhom "check-ship.sh (aw check ship)"
SHC="$T/check-ship.sh"
ky_vong 2 "chưa có merge-request.md → THIẾU ĐẦU VÀO" sh "$SHC" "$F"
viet_mr
ky_vong 0 "mô tả MR đủ mục, review đạt → ĐẠT" sh "$SHC" "$F"
thay "$F/merge-request.md" '# ABC-1: hiện a và b trên màn hình y' '# <JIRA-KEY>: <verb> <what> <where>'
ky_vong 1 "tiêu đề còn chữ giữ chỗ → chặn" sh "$SHC" "$F"
viet_mr; thay "$F/merge-request.md" '## Out of Scope

None

' ''
ky_vong 1 "xoá mất một mục của mẫu → chặn (không áp dụng thì ghi None)" sh "$SHC" "$F"
dung "…đúng lý do" sh -c "sh '$SHC' '$F' | grep -q 'Thiếu mục \"## Out of Scope\"'"
viet_mr; thay "$F/merge-request.md" '- **Added:** test/a.test.js — có a và b
- **Commands:** `npm test` → xanh' '<!-- chưa viết -->'
ky_vong 1 "Testing chỉ có comment → chặn (mục bắt buộc trống)" sh "$SHC" "$F"
viet_mr; thay "$F/merge-request.md" '- **Added:** test/a.test.js — có a và b' '- **Added:** <test> — <chứng minh gì>'
ky_vong 1 "còn chữ giữ chỗ của mẫu ngoài comment → chặn" sh "$SHC" "$F"
viet_mr; thay "$F/merge-request.md" '# ABC-1: hiện a và b trên màn hình y' '# hiện a và b trên màn hình y'
ky_vong 0 "tiêu đề thiếu mã Jira của intake → chỉ cảnh báo" sh "$SHC" "$F"
dung "…có cảnh báo" sh -c "sh '$SHC' '$F' | grep -q 'CẢNH BÁO.*ABC-1'"
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
them_muc_qt() { printf '\n## Repo rules\n\n| File | Verdict | Location / reason |\n|---|---|---|\n%s\n' "$1" >> "$F/review.md"; toc_f review.md; }

ky_vong 0 "không khai gì → aw rules ĐÃ LIỆT KÊ" sh "$QT" implement
dung "…stdout rỗng" bang "$(sh "$QT" implement 2>/dev/null)" ""
ky_vong 2 "aw rules thiếu phase → SAI THAM SỐ" sh "$QT"
ky_vong 2 "aw rules phase không có quy tắc (intake) → SAI THAM SỐ" sh "$QT" intake
ky_vong 0 "aw-engine rules → đúng script" sh "$AWE" rules implement

khai_qt implement 'docs/quy-tac.md'
dung "khai implement → aw rules implement in đúng file" bang "$(sh "$QT" implement 2>/dev/null)" "docs/quy-tac.md"
dung "…phase khác không thấy" bang "$(sh "$QT" spec 2>/dev/null)" ""
khai_qt spec 'docs/quy-tac-2.md docs/quy-tac.md'
thay "$CONV" 'rules_implement:' 'rules_implement: docs/quy-tac.md'
dung "review = hợp mọi khoá, bỏ trùng, giữ thứ tự" bang "$(sh "$QT" review 2>/dev/null | tr '\n' ' ')" "docs/quy-tac-2.md docs/quy-tac.md "

for p in spec:spec design:design plan:plan implement:implement; do
  khai_qt "${p%%:*}" 'docs/khong-co.md'
  ky_vong 1 "${p%%:*}: file quy tắc không có → aw check ${p%%:*} chặn" sh "$T/check-${p#*:}.sh" "$F"
done
dung "…đúng lý do" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'quy tắc repo \"docs/khong-co.md\": không có file'"
ky_vong 1 "…aw rules implement ra KHAI SAI" sh "$QT" implement
ky_vong 0 "…phase không khai thì không bị ảnh hưởng" sh "$T/check-spec.sh" "$F"
ky_vong 1 "…review chặn (cổng cuối kiểm mọi khoá)" sh "$T/check-review.sh" "$F"

printf 'x\n' > "$R/docs/chua-commit.md"
khai_qt implement 'docs/chua-commit.md'
ky_vong 1 "file quy tắc chưa commit → chặn" sh "$QT" implement
dung "…đúng lý do: chưa commit" sh -c "sh '$QT' implement 2>&1 | grep -q 'chưa commit'"
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
ky_vong 1 "khoá gõ nhầm (rules_implment) → aw rules chặn" sh "$QT" implement
dung "…đúng lý do" sh -c "sh '$QT' implement 2>&1 | grep -q 'rules_implment.*không ứng với phase'"
ky_vong 1 "…review chặn" sh "$T/check-review.sh" "$F"

# Review: mỗi file quy tắc một kết luận
khai_qt implement 'docs/quy-tac.md'
viet_review
ky_vong 1 "review.md thiếu mục Quy tắc repo → chặn" sh "$T/check-review.sh" "$F"
dung "…đúng lý do" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'thiếu mục \"## Repo rules\"'"
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
ky_vong 1 "review thiếu dòng cho quy tắc của phase khác (spec) → chặn" sh "$T/check-review.sh" "$F"
dung "…đúng lý do" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'docs/quy-tac-2.md\": không có verdict'"
cp "$TMP/conv-qt.bak" "$CONV"; viet_review
ky_vong 0 "bỏ hết khoá → review như cũ" sh "$T/check-review.sh" "$F"

# ---------------------------------------------------------------- skill / subagent cua repo
nhom "skill / subagent của repo (uses_*, aw uses)"
US="$T/uses.sh"
# khai_us <phase> <giá trị> — khai lại từ đầu một khoá uses_<phase>
khai_us() { cp "$TMP/conv-qt.bak" "$CONV"; thay "$CONV" "uses_$1:" "uses_$1: $2"; }
# skill_moi <tên> [dòng frontmatter thêm] — skill trong .claude/ (fixture exclude /.claude/ → add -f)
skill_moi() {
  mkdir -p "$R/.claude/skills/$1"
  printf -- '---\nname: %s\ndescription: x\n%s---\nthân\n' "$1" "${2:+$2
}" > "$R/.claude/skills/$1/SKILL.md"
  g add -f ".claude/skills/$1/SKILL.md"
}

ky_vong 0 "không khai gì → aw uses ĐÃ LIỆT KÊ" sh "$US" implement
dung "…stdout rỗng" bang "$(sh "$US" implement 2>/dev/null)" ""
ky_vong 2 "aw uses thiếu phase → SAI THAM SỐ" sh "$US"
ky_vong 2 "aw uses phase không có (intake) → SAI THAM SỐ" sh "$US" intake
ky_vong 0 "aw-engine uses → đúng script" sh "$AWE" uses implement

# go-senior đã commit trong base (tao_fixture).
mkdir -p "$R/.cursor/agents"; printf -- '---\nname: db-migrator\ndescription: x\n---\nx\n' > "$R/.cursor/agents/db-migrator.md"
g add -f .cursor/agents/db-migrator.md
khai_us implement 'skill:go-senior agent:db-migrator skill:go-senior'
ky_vong 0 "skill + subagent đã commit → ĐÃ LIỆT KÊ" sh "$US" implement
dung "…in <mục> <file>, bỏ trùng; subagent tìm cả .cursor/" bang "$(sh "$US" implement 2>/dev/null | tr '\n' '|')" \
  "skill:go-senior .claude/skills/go-senior/SKILL.md|agent:db-migrator .cursor/agents/db-migrator.md|"
dung "…phase khác không thấy" bang "$(sh "$US" spec 2>/dev/null)" ""
dung "…aw uses review chỉ in uses_review" bang "$(sh "$US" review 2>/dev/null)" ""
dung "…aw rules review thêm file định nghĩa của mọi uses_*" bang "$(sh "$QT" review 2>/dev/null | tr '\n' ' ')" \
  ".claude/skills/go-senior/SKILL.md .cursor/agents/db-migrator.md "
dung "…aw rules implement thì không (chỉ rules_implement)" bang "$(sh "$QT" implement 2>/dev/null)" ""
ky_vong 0 "…aw check implement cho qua" sh "$T/check-implement.sh" "$F"
mkdir -p "$R/.claude/agents"; printf -- '---\nname: db-migrator\ndescription: x\n---\nx\n' > "$R/.claude/agents/db-migrator.md"
g add -f .claude/agents/db-migrator.md
dung "…có cả hai bản thì .claude/ trước" sh -c "sh '$US' implement 2>/dev/null | grep -qx 'agent:db-migrator .claude/agents/db-migrator.md'"

khai_us implement 'skill:khong-co'
for p in spec design plan implement; do
  khai_us "$p" 'skill:khong-co'
  ky_vong 1 "$p: skill khai mà không có trong repo → aw check $p chặn" sh "$T/check-$p.sh" "$F"
done
dung "…đúng lý do" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'uses \"skill:khong-co\": không có .claude/skills/khong-co/SKILL.md'"
ky_vong 1 "…aw uses implement ra KHAI SAI" sh "$US" implement
ky_vong 0 "…phase không khai thì không bị ảnh hưởng" sh "$T/check-spec.sh" "$F"
ky_vong 1 "…review chặn (cổng cuối kiểm mọi khoá)" sh "$T/check-review.sh" "$F"
khai_us implement 'agent:khong-co'
dung "subagent không có → đúng lý do" sh -c "sh '$US' implement 2>&1 | grep -q 'không có .claude/agents/khong-co.md'"

mkdir -p "$R/.claude/skills/chua-commit"; printf -- '---\nname: chua-commit\ndescription: x\n---\n' > "$R/.claude/skills/chua-commit/SKILL.md"
khai_us implement 'skill:chua-commit'
ky_vong 1 "skill chưa commit (bị exclude) → chặn" sh "$US" implement
dung "…chỉ rõ git đang bỏ qua + git add -f" sh -c "sh '$US' implement 2>&1 | grep -q 'uses \"skill:chua-commit\".*git đang bỏ qua.*git add -f'"
rm -rf "$R/.claude/skills/chua-commit"

skill_moi chi-nguoi 'disable-model-invocation: true'
khai_us implement 'skill:chi-nguoi'
ky_vong 1 "skill disable-model-invocation: true → chặn (agent không gọi được)" sh "$US" implement
dung "…đúng lý do" sh -c "sh '$US' implement 2>&1 | grep -q 'disable-model-invocation: true — agent không gọi được'"
skill_moi chi-nguoi 'disable-model-invocation: false'
ky_vong 0 "…false thì cho qua" sh "$US" implement
printf -- '---\nname: chi-nguoi\ndescription: x\n---\ndisable-model-invocation: true\n' > "$R/.claude/skills/chi-nguoi/SKILL.md"
ky_vong 0 "…chữ đó nằm trong thân (không phải frontmatter) thì cho qua" sh "$US" implement

for v in 'skill:plugin-x:go' 'skill:Go_Senior' 'go-senior' 'mcp:atlassian' 'skill:'; do
  khai_us implement "$v"
  ky_vong 1 "mục sai dạng ($v) → chặn" sh "$US" implement
done
khai_us implement 'skill:plugin-x:go'
dung "…tên plugin: bảo chép vào repo" sh -c "sh '$US' implement 2>&1 | grep -q 'của plugin.*chép nó vào .claude/skills/'"

cp "$TMP/conv-qt.bak" "$CONV"
thay "$CONV" 'uses_review:' 'uses_review:
uses_implment: skill:go-senior'
ky_vong 1 "khoá gõ nhầm (uses_implment) → aw uses chặn" sh "$US" implement
dung "…đúng lý do" sh -c "sh '$US' implement 2>&1 | grep -q 'uses_implment.*không ứng với phase.*uses_implement'"
ky_vong 1 "…aw rules cũng chặn (cùng conventions.md)" sh "$QT" implement

# Gỡ file thêm trong khối này khỏi index: chúng lọt vào diff của việc, review sẽ chặn vì lý do khác.
g rm -rqf --cached .claude/agents .claude/skills/chi-nguoi .cursor; rm -rf "$R/.claude/agents" "$R/.claude/skills/chi-nguoi" "$R/.cursor"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1   # làm mới test-results.md theo cây đã dọn

# Review: mỗi skill / subagent đã khai một kết luận, như file quy tắc
khai_us implement 'skill:go-senior'
viet_review
ky_vong 1 "review.md thiếu kết luận cho skill đã khai → chặn" sh "$T/check-review.sh" "$F"
dung "…đúng lý do" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'thiếu mục \"## Repo rules\"'"
viet_review; them_muc_qt '| `.claude/skills/go-senior/SKILL.md` | pass | |'
ky_vong 0 "có kết luận cho SKILL.md → cho qua" sh "$T/check-review.sh" "$F"
khai_us review 'skill:go-senior'
dung "uses_review → aw uses review in skill đó" sh -c "sh '$US' review 2>/dev/null | grep -qx 'skill:go-senior .claude/skills/go-senior/SKILL.md'"

cp "$TMP/conv-qt.bak" "$CONV"; viet_review
ky_vong 0 "bỏ hết khoá uses_* → review như cũ" sh "$T/check-review.sh" "$F"

# ---------------------------------------------------------------- liet ke cau hoi
nhom "pending.sh (/aw-clarify)"
CHK="$T/pending.sh"
LQ="$TMP/lq"; rm -rf "$LQ"; mkdir -p "$LQ"
cat > "$LQ/spec.md" <<'EOF'
### REQ-001 — a
- Priority: `should`
### REQ-002 — b
- Priority: `must`
### REQ-003 — c
- Priority: `must`
### REQ-004 — d
- Priority: `should`
### REQ-005 — e
- Priority: `must`
### REQ-006 — f
- Priority: `must`
EOF
# Thứ tự trong file cố tình ngược với thứ tự phải giải quyết.
cat > "$LQ/open-questions.md" <<'EOF'
# Open questions

### REQ-001 — không chặn
- **Question:** hỏi 1
- **Blocking:** `non-blocking`
- **Status:** `open`

### REQ-002 — chặn review, bắt buộc, không task
- **Blocking:** `review-blocking`
- **Status:** `open`

### REQ-003 — chặn review, bắt buộc, 2 task
- **Blocking:** `review-blocking`
- **Status:** `open`

### REQ-004 — chặn, nên có
- **Blocking:** `blocking`
- **Status:** `open`

### REQ-005 — chặn, bắt buộc
- **Ask:** PO
- **Blocking:** `blocking`
- **Status:** `open`

### REQ-006 — đã trả lời
- **Blocking:** `blocking`
- **Status:** `answered`
- **Answer:** có
EOF
thu_tu() { sh "$CHK" "$LQ" 2>/dev/null | sed -n 's/^  [0-9][0-9]*\. \(REQ-[0-9]*\).*/\1/p' | tr '\n' ' '; }
ky_vong 1 "còn điểm mù \"chặn\" mở → ĐANG CHẶN" sh "$CHK" "$LQ"
dung "xếp: chặn → chặn review → không chặn; bắt buộc trước nên có" bang "$(thu_tu)" "REQ-005 REQ-004 REQ-002 REQ-003 REQ-001 "
printf '### TSK-001\n- On assumption: **yes** — `open-questions.md` § REQ-003\n### TSK-002\n- On assumption: **yes** — § REQ-003\n' > "$LQ/plan.md"
dung "cùng mức + cùng ưu tiên: nhiều task đứng trên giả định hơn thì trước" bang "$(thu_tu)" "REQ-005 REQ-004 REQ-003 REQ-002 REQ-001 "
dung "…in tên task đứng trên giả định" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'Task on assumption: 2 (TSK-001 TSK-002)'"
dung "mục đã trả lời không được liệt kê" sh -c "! sh '$CHK' '$LQ' 2>/dev/null | grep -q 'REQ-006'"
dung "mục chặn đánh dấu ĐANG CHẶN phase kế tiếp" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'REQ-005.*ĐANG CHẶN /aw-implement'"
dung "khối Kết quả: [x] CÓ VIỆC ĐANG CHẶN" sh -c "sh '$CHK' '$LQ' 2>&1 | grep -q '\[x\] CÓ VIỆC ĐANG CHẶN'"
thay "$LQ/open-questions.md" '`blocking`
- **Status:** `open`' '`non-blocking`
- **Status:** `open`'
ky_vong 3 "chỉ còn chặn review (chưa tới review) + không chặn → chưa chặn" sh "$CHK" "$LQ"
: > "$LQ/test-results.md"
ky_vong 1 "…tới review thì chặn review thành ĐANG CHẶN" sh "$CHK" "$LQ"
rm -f "$LQ/test-results.md"
thay "$LQ/open-questions.md" '`review-blocking`' '`toàn bộ thiết kế`'
ky_vong 1 "mức thiếu/sai (nhãn cũ) → CHƯA PHÂN MỨC, đang chặn spec" sh "$CHK" "$LQ"
dung "…xếp lên đầu" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -A1 '^\[CHƯA PHÂN MỨC\]' | grep -q '1\. REQ-00'"
printf '# Open questions\n\nNo open questions.\n' > "$LQ/open-questions.md"
ky_vong 0 "không còn điểm mù mở, không có phát hiện" sh "$CHK" "$LQ"
: > "$LQ/open-questions.md"
ky_vong 0 "open-questions.md 0 byte không làm đọc lệch file" sh "$CHK" "$LQ"
rm -f "$LQ/open-questions.md"
ky_vong 2 "thiếu open-questions.md → THIẾU ĐẦU VÀO" sh "$CHK" "$LQ"
tao_fixture
ky_vong 3 "fixture: chỉ có điểm mù không chặn" sh "$CHK" "$F"

# Phát hiện checker LLM chen vào hàng đợi theo phase bị chặn.
cat > "$LQ/open-questions.md" <<'EOF'
# Open questions

### REQ-001 — không chặn
- **Blocking:** `non-blocking`
- **Status:** `open`

### REQ-002 — chặn review
- **Blocking:** `review-blocking`
- **Status:** `open`

### REQ-005 — chặn
- **Blocking:** `blocking`
- **Status:** `open`
EOF
: > "$LQ/tdd.md"; rm -f "$LQ/plan.md"
cat > "$LQ/design-findings.md" <<'EOF'
# Phát hiện

### FND-001 — cảnh báo
- Severity: `warn`
- Location: `tdd.md` § Flow
- Problem: mơ hồ
- Resolution: `open`

### FND-002 — chặn chưa xử lý
- Severity: `block`   <!-- block | warn -->
- Category: `hidden-decision`
- Location: `tdd.md` § Contract
- Problem: chọn gRPC mà không nêu DEC
- Resolution: `open`   <!-- open | fixed | rejected: <lý do> -->

### FND-003 — đã sửa
- Severity: `block`
- Resolution: `fixed`

### FND-004 — bác bỏ không lý do
- Severity: `block`
- Resolution: `rejected:`

### FND-005 — bác bỏ có lý do
- Severity: `block`
- Resolution: `rejected: DEC-002 đã chốt — PO, 2026-10-06`
EOF
thu_tu_all() { sh "$CHK" "$LQ" 2>/dev/null | sed -n 's/^  [0-9][0-9]*\. \([A-Z]*-[0-9]*\).*/\1/p' | tr '\n' ' '; }
ky_vong 1 "phát hiện Chặn chưa xử lý → ĐANG CHẶN" sh "$CHK" "$LQ"
dung "xếp: điểm mù chặn → phát hiện Chặn → chặn review → phát hiện Cảnh báo → không chặn" \
  bang "$(thu_tu_all)" "REQ-005 FND-002 FND-004 REQ-002 FND-001 REQ-001 "
dung "…phát hiện Chặn đánh dấu ĐANG CHẶN /aw-plan" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'FND-002.*ĐANG CHẶN /aw-plan'"
dung "…in vị trí + vấn đề của phát hiện" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'Problem: chọn gRPC mà không nêu D'"
dung "phát hiện đã đóng chỉ nằm ở [ĐÃ XỬ LÝ], không đánh số" sh -c \
  "o=\$(sh '$CHK' '$LQ' 2>/dev/null); echo \"\$o\" | grep -q '^  - FND-003' && echo \"\$o\" | grep -q '^  - FND-005' && ! echo \"\$o\" | grep -q '^  [0-9]*\. FND-00[35]'"
thay "$LQ/open-questions.md" '`blocking`
- **Status:** `open`' '`non-blocking`
- **Status:** `open`'
thay "$LQ/design-findings.md" '`open`   <!-- open' '`fixed`   <!-- open'
thay "$LQ/design-findings.md" '`rejected:`' '`rejected: trùng FND-002`'
ky_vong 3 "chỉ còn phát hiện Cảnh báo + điểm mù chưa chặn → chưa chặn" sh "$CHK" "$LQ"
printf '# Open questions\n\nNo open questions.\n' > "$LQ/open-questions.md"
printf '# Phát hiện\n\nNo blocking findings.\n' > "$LQ/design-findings.md"
ky_vong 0 "file phát hiện rỗng + không điểm mù → không còn việc" sh "$CHK" "$LQ"
printf '### FND-001 — x\n- Severity: `block`\n- Resolution: `open`\n' > "$LQ/plan-findings.md"
ky_vong 1 "checker mới (<id>-findings.md) tự được gom" sh "$CHK" "$LQ"
rm -f "$LQ/plan-findings.md" "$LQ/design-findings.md" "$LQ/tdd.md"

# ---------------------------------------------------------------- based_on
nhom "based-on.sh"
printf -- '---\nkhac: giu\nbased_on:\n  - spec.md@1\n---\n\n# x\n' > "$F/thu.md"
sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null 2>&1
sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null 2>&1
dung "giữ khoá frontmatter khác" grep -q '^khac: giu' "$F/thu.md"
dung "chạy lại không nhân đôi based_on" test "$(grep -c 'spec.md@' "$F/thu.md")" = 1
dung "hash ghi ra khớp file (bỏ dấu duyệt)" grep -q "spec.md@$(tr -d '\r' < "$F/spec.md" | sed 's/ *<!-- approval-hash: [0-9a-f]* -->//' | cksum | awk '{print $1}')" "$F/thu.md"
duyet_lai "$F/spec.md"; sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null 2>&1
H_TRUOC=$(grep 'spec.md@' "$F/thu.md")
sh "$T/check-spec.sh" "$F" >/dev/null 2>&1
dung "…(spec giờ có dấu duyệt)" grep -q 'approval-hash:' "$F/spec.md"
sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null 2>&1
dung "máy ghi lại dấu duyệt không làm đổi hash based_on" bang "$H_TRUOC" "$(grep 'spec.md@' "$F/thu.md")"
printf '# không frontmatter\n' > "$F/thu.md"
sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null 2>&1
dung "thêm frontmatter khi file chưa có" sh -c "head -1 '$F/thu.md' | grep -q '^---\$'"
rm -f "$F/thu.md"

ket_thuc
