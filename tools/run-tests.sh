#!/usr/bin/env sh
# Test hoi quy cho cac cong chan va cho adapter.
#
#   sh tools/run-tests.sh
#
# Repo nay ban cac cong chan; neu chinh cong chan hong ma khong ai biet thi
# ca quy trinh tro thanh trang tri. Moi ca kiem CA HAI CHIEU: chan dung luc
# va cho qua dung luc. Mot checker luon tra 0 con te hon khong co checker.

set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP="${TMPDIR:-/tmp}/aw-run-tests.$$"
mkdir -p "$TMP"
. "$ROOT/tools/lib/result.sh"
kq_khai run-tests.sh "0=MỌI CA ĐẠT" "1=CÓ CA HỎNG — xem các dòng FAIL phía trên"
kq_don 'rm -rf "$TMP"'
T="$ROOT/tools"

n_ok=0
n_fail=0

# ky_vong <ma-mong-doi> <ten-ca> <lenh...>
ky_vong() {
  _mong="$1"; _ten="$2"; shift 2
  "$@" >/dev/null 2>&1
  _got=$?
  if [ "$_got" = "$_mong" ]; then
    n_ok=$((n_ok + 1))
    printf '  ok    %s\n' "$_ten"
  else
    n_fail=$((n_fail + 1))
    printf '  FAIL  %s — mã thoát %s, mong đợi %s\n' "$_ten" "$_got" "$_mong"
  fi
}

# dung <ten-ca> <lenh...> — lenh la mot phep thu tra 0/1
dung() {
  _ten="$1"; shift
  if "$@" >/dev/null 2>&1; then
    n_ok=$((n_ok + 1)); printf '  ok    %s\n' "$_ten"
  else
    n_fail=$((n_fail + 1)); printf '  FAIL  %s\n' "$_ten"
  fi
}

# bang <a> <b> — so chuỗi, dùng với dung
bang() { test "$1" = "$2"; }

# thay <file> <tu> <thanh> — thay chuoi co dinh, khong dung regex
thay() {
  # Tìm tiếp trên phần CHƯA xét, để chuỗi thay chứa chuỗi tìm không lặp vô hạn.
  # Chuỗi tìm nhiều dòng: đọc cả file thành một bản ghi.
  awk -v a="$2" -v b="$3" 'BEGIN { RS = "\001" } {
    s = $0; o = ""
    while ((i = index(s, a)) > 0) { o = o substr(s, 1, i-1) b; s = substr(s, i+length(a)) }
    printf "%s", o s
  }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# duyet_lai <file> — người duyệt lại: xoá dấu duyệt, giữ tick
duyet_lai() { sed 's/ *<!-- approval-hash: [0-9a-f]* -->//' "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }

g() { git -C "$R" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }

# ------------------------------------------------------------------ fixture
# Mot repo git day du, mot feature di het cac phase va DAT moi cong chan.
# Moi ca kiem lam hong dung mot cho roi ky vong checker bat duoc.
#
# LOAI quyet dinh luat theo loai viec; tao_fixture <loai> <branch> dung lai
# R, F, LOAI cho tung loai. Test "bao ve" test/a.test.js co san tren main.
LOAI=feature
R="$TMP/repo"
# Lệnh quét bảo mật giả: đủ ba nhóm, luôn xanh. Ca kiểm bảo mật tự đổi.
BM_XANH='SECURITY_CMDS="
secret: echo secret-sach
sast: echo sast-sach
sca: echo sca-sach
"'

F="$R/.agent-workflow/feat_x"

viet_intake() {
  cat > "$F/intake.md" <<EOF
# Intake — x

- **Type:** \`$LOAI\`   <!-- người xác nhận -->
- **Base:** \`main\` @ \`$(git -C "$R" rev-parse --short main 2>/dev/null)\`
- **Engine:** $(cat "$ROOT/VERSION")
- **Goal:** làm x

## Input

- \`[JIRA]\` ABC-1
- \`[HUMAN]\`
  > cần làm x cho màn hình y
EOF
}

viet_spec() {
  cat > "$F/spec.md" <<'EOF'
# Spec — x

- **Risk:** `normal`
- [x] **Approved by human** — đã đọc

## Requirements

### YC-001 — a
- Source: `[JIRA]` ABC-1
- Priority: `must`
- Acceptance criteria:
  - [ ] mở y thấy a

### YC-002 — b
- Source: `[OPEN-QUESTION]` → open-questions.md § YC-002
- Assumption: y
- Priority: `should`
- Acceptance criteria:
  - [ ] mở y thấy b
EOF
  case "$LOAI" in
    refactor|perf)
      thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[JIRA]` ABC-1
- Type: `preserve`
- Protected by: `test/a.test.js`' ;;
  esac
  case "$LOAI" in
    refactor) printf -- '- Type: `structural`\n' >> "$F/spec.md" ;;
    perf)     printf -- '- Type: `performance`\n- Target: dưới 10 ms\n' >> "$F/spec.md" ;;
  esac
  if [ "$LOAI" = "bugfix" ]; then
    printf '\n## Reproduction\n\n- Steps to reproduce: mở a\n- Actual behavior: ra goc\n- Expected behavior: ra moi\n' >> "$F/spec.md"
  fi
  cat >> "$F/spec.md" <<'EOF'

## Constraints & dependencies

Không có ràng buộc hay phụ thuộc ngoài.

## Out of scope

- màn hình z — lý do: đợt sau

## Source conflicts

| Source A says | Source B says | Resolution |
|---|---|---|
| | | |

Không phát hiện mâu thuẫn.
EOF
  cat > "$F/open-questions.md" <<'EOF'
# Điểm mù

## YC-002 — b
- **Assumption:** y
- **Blocking:** `non-blocking`   <!-- blocking | review-blocking | non-blocking -->
- **Status:** `open`   <!-- open | answered -->
EOF
}

viet_tdd() {
  [ "$LOAI" = "chore" ] && { rm -f "$F/tdd.md" "$F/design-findings.md"; return 0; }
  cat > "$F/tdd.md" <<'EOF'
---
based_on: []
---

# Technical Design — x

## Existing code
Module src/a.

## Decisions (D-xx)

### D-01 — lưu ở đâu
- Author: `agent`
- Choice: file
- [x] **Approved by human**

## Data model
Based on: D-01
Một file văn bản.

## Contract / API
Not applicable: không có API công khai.

## Flow
Đọc rồi ghi.

## Non-functional
Not applicable: thay đổi nội bộ nhỏ.

## Test strategy
Unit test.

## YC mapping

| YC | Mục |
|---|---|
| YC-001 | § Data model |
| YC-002 | § Flow |
EOF
  cat > "$F/design-findings.md" <<'EOF'
# Phát hiện

No blocking findings.
EOF
}

viet_plan() {
  cat > "$F/plan.md" <<'EOF'
# Plan — x

## Tasks

### T-01 — a
- Covers: `YC-001`
- Based on: `D-01`
- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[x]`

### T-02 — b
- Covers: `YC-002`
- Expected files: `src/b.txt`
- Verify: `test -f src/a.txt` → có file
- Status: `[x]`

## Deferred

| ID | Reason |
|---|---|

## Manual verification

| ID | Why not automated |
|---|---|

## Modified existing tests

| Test file | Reason |
|---|---|

## Dependency upgrades

| Library | Old → new | Level |
|---|---|---|

## Unplanned

| Task | What came up | Extra files | Resolution |
|---|---|---|---|
EOF
  if [ "$LOAI" = "chore" ]; then
    thay "$F/plan.md" '- Based on: `D-01`
' ''
    thay "$F/plan.md" '`src/*` `test/*`' '`docs/*`'
  fi
}

viet_review() {
  printf '| ID | Verdict |\n|---|---|\n| YC-001 | pass |\n| YC-002 | pending |\n' > "$F/review.md"
  [ "$LOAI" = "bugfix" ] && printf '\n- Repro test fails because: grep không thấy "moi" trong src/a.txt\n' >> "$F/review.md"
  viet_lens4
  printf '\n## Lens 3 — Quality\n\n- None\n\n## Conclusion\n\n- Blocker findings: 0\n- Mergeable: yes\n' >> "$F/review.md"
  ghi_tree_review
  return 0
}

# van_tay — dấu vân tay code hiện tại (như checker tính)
van_tay() { sh -c ". '$T/lib/md.sh'; . '$T/lib/cross-check.sh'; kc_van_tay '$F'"; }

# ghi_tree_review — ghi / cập nhật dòng "Reviewed tree" theo code hiện tại
# (người rà soát rà lại sau khi code đổi)
ghi_tree_review() {
  grep -v '^- Reviewed tree:' "$F/review.md" > "$F/review.md.tmp"
  { printf -- '- Reviewed tree: `%s`\n\n' "$(van_tay)"; cat "$F/review.md.tmp"; } > "$F/review.md"
  rm -f "$F/review.md.tmp"
}

# viet_lens4 — bảng Lens 4 đủ bảy hạng mục, kết luận hợp lệ
viet_lens4() {
  cat >> "$F/review.md" <<'EOF'

## Lens 4 — Security

| Item | Verdict | Location / reason |
|---|---|---|
| Input validation / injection | not applicable | diff không nhận input từ ngoài |
| Authn / authz | pass | màn hình y dùng quyền có sẵn, khớp YC-001 |
| Sensitive data / PII in logs | not applicable | không log, không dữ liệu cá nhân |
| Secrets / config | pass | |
| Crypto | not applicable | không dùng crypto |
| SSRF / path traversal / deserialization | not applicable | không có URL, đường dẫn hay deserialize |
| `New dependencies` | not applicable | không thêm dependency |
EOF
}

ghi_based_on() {
  sh "$T/based-on.sh" "$F" spec.md intake.md >/dev/null
  if [ "$LOAI" = "chore" ]; then
    sh "$T/based-on.sh" "$F" plan.md spec.md >/dev/null
  else
    sh "$T/based-on.sh" "$F" tdd.md spec.md open-questions.md >/dev/null
    sh "$T/based-on.sh" "$F" plan.md spec.md tdd.md >/dev/null
  fi
}

# ghi_bang_chung_task — task xong bằng máy: aw task done ghi task-results.md
ghi_bang_chung_task() {
  for _t in T-01 T-02; do sh "$T/task.sh" done "$F" "$_t" >/dev/null 2>&1; done
}

# tao_fixture [loai] [branch]
tao_fixture() {
  LOAI="${1:-feature}"; _br="${2:-feat_x}"
  R="$TMP/repo-$LOAI"; F="$R/.agent-workflow/$_br"
  rm -rf "$R"
  mkdir -p "$F" "$R/src" "$R/test" "$R/docs"
  g init -q
  g checkout -q -b main
  # Cấu hình theo bản clone, không commit — wrapper aw truyền qua AW_REPO/AW_CONFIG.
  CFG="$R/.git/agent-workflow"; mkdir -p "$CFG"
  export AW_REPO="$R" AW_CONFIG="$CFG"
  cp "$ROOT/workflow/templates/conventions.md" "$CFG/conventions.md"
  {
    printf 'TEST_CMD="grep -q moi %s/src/a.txt"\n' "$R"
    printf 'PERF_CMD="echo KET_QUA: 5 ms"\n'
    printf '%s\n' "$BM_XANH"
  } > "$CFG/config.sh"
  printf 'goc\n' > "$R/src/a.txt"
  printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"
  # Quy tắc riêng của repo (rules_*): file phải đã commit vào base.
  printf '# quy tắc a\n' > "$R/docs/quy-tac.md"; printf '# quy tắc b\n' > "$R/docs/quy-tac-2.md"
  # Skill của team đã commit sẵn trong base (uses_*): có trong cây, không nằm trong diff của việc.
  mkdir -p "$R/.claude/skills/go-senior"; printf -- '---\nname: go-senior\ndescription: x\n---\nthân\n' > "$R/.claude/skills/go-senior/SKILL.md"
  g add src test docs .claude; g commit -q -m goc
  g checkout -q -b "$_br"
  viet_intake; viet_spec; viet_tdd; viet_plan; viet_review
  ghi_based_on
  case "$LOAI" in
    bugfix)
      printf '// covers: YC-001\n' > "$R/test/b.test.js"
      sh "$T/check-repro.sh" "$F" >/dev/null 2>&1 ;;
    perf)
      sh "$T/check-perf.sh" "$F" --before >/dev/null 2>&1 ;;
  esac
  if [ "$LOAI" = "chore" ]; then
    printf 'TEST_CMD="true"\n%s\n' "$BM_XANH" > "$CFG/config.sh"
    printf 'huong dan\n' > "$R/docs/huong-dan.md"
  else
    printf 'moi\n' > "$R/src/a.txt"
  fi
  [ "$LOAI" = "perf" ] && sh "$T/check-perf.sh" "$F" --after >/dev/null 2>&1
  ghi_bang_chung_task
  sh "$T/check-implement.sh" "$F" >/dev/null 2>&1
  ghi_tree_review   # rà soát diễn ra sau implement
}

# ---------------------------------------------------------------- fixture goc
echo ""
echo "fixture"
tao_fixture
for c in spec design plan implement review; do
  ky_vong 0 "feature đầy đủ qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done

# ---------------------------------------------------------------- aw-engine
echo ""
echo "bin/aw-engine"
AWE="$ROOT/bin/aw-engine"
dung "version in đúng VERSION" bang "$(sh "$AWE" version)" "$(cat "$ROOT/VERSION")"
for c in intake spec design plan implement review; do
  ky_vong 0 "aw-engine check $c → đúng checker, giữ mã thoát" sh "$AWE" check "$c" "$F"
done
dung "mọi tên trong bảng checker trỏ tới script có thật" sh -c ". '$T/lib/commands.sh'; for c in \$BL_CHECKERS; do [ -f '$T/'\$(bl_checker \$c) ] || exit 1; done"
dung "check giữ khối Kết quả của checker" sh -c "sh '$AWE' check plan '$F' 2>&1 | grep -q 'Kết quả: check-plan.sh'"
ky_vong 2 "check tên lạ → SAI THAM SỐ" sh "$AWE" check khong-co "$F"
ky_vong 2 "check thiếu thư mục → SAI THAM SỐ" sh "$AWE" check spec
ky_vong 9 "thiếu AW_CONFIG → KHÔNG HỢP LỆ (không đoán đường dẫn)" env -u AW_CONFIG sh "$AWE" check spec "$F"
ky_vong 9 "wrapper khác giao thức → KHÔNG HỢP LỆ" env AW_PROTOCOL=999 sh "$AWE" check spec "$F"
ky_vong 2 "lệnh lạ → SAI THAM SỐ" sh "$AWE" lam-gi-do
ky_vong 0 "aw-engine guard pre → guard.sh" sh "$AWE" guard pre
ky_vong 0 "aw-engine approval → approval.sh" sh "$AWE" approval design "$F"
ky_vong 3 "aw-engine guard sai pha → SAI THAM SỐ của guard.sh" sh "$AWE" guard khac
ky_vong 2 "adapter không có → SAI THAM SỐ" sh "$AWE" adapter build khong-co --out "$TMP/o-x"

# Ghim version theo việc: dòng Engine trong intake.md
cp "$F/intake.md" "$TMP/intake.bak"
sed '/\*\*Engine:\*\*/d' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "intake thiếu dòng Engine → KHÔNG ĐẠT" sh "$T/check-intake.sh" "$F"
ky_vong 9 "…aw-engine check spec từ chối chấm (không biết engine nào)" sh "$AWE" check spec "$F"
ky_vong 1 "…aw-engine check intake vẫn chạy để liệt kê lỗi" sh "$AWE" check intake "$F"
sed 's/\*\*Engine:\*\* .*/**Engine:** 2026.10.06/' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "Engine sai dạng YYYY.M.N (có số 0 đứng đầu) → KHÔNG ĐẠT" sh "$T/check-intake.sh" "$F"
sed 's/\*\*Engine:\*\* .*/**Engine:** 2000.1.1/' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "Engine lệch engine đang chạy → KHÔNG ĐẠT" sh "$T/check-intake.sh" "$F"
for c in intake spec repro perf; do
  ky_vong 9 "…aw-engine check $c lệch version → KHÔNG HỢP LỆ" sh "$AWE" check "$c" "$F"
done
cp "$TMP/intake.bak" "$F/intake.md"
ky_vong 0 "Engine khớp → ĐẠT" sh "$T/check-intake.sh" "$F"

# ---------------------------------------------------------------- truy vet
echo ""
echo "check-spec.sh"
CHK="$T/check-spec.sh"

viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Description: không nguồn'
ky_vong 1 "chặn yêu cầu không có nhãn nguồn" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '`[JIRA]`' '`[BRD]`'
ky_vong 1 "chặn nhãn tự chế ngoài 5 nhãn hợp lệ" sh "$CHK" "$F"

viet_spec; printf '# Open questions\n\nNo open questions.\n' > "$F/open-questions.md"
ky_vong 1 "chặn [OPEN-QUESTION] không ghi vào open-questions" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '**Assumption:**' '**Question:**'
ky_vong 1 "chặn mục điểm mù thiếu giả định tạm" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '- **Blocking:** `non-blocking`' ''
ky_vong 1 "chặn mục điểm mù thiếu mức chặn" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '`non-blocking`' '`hơi hơi`'
ky_vong 1 "chặn mức chặn tự chế" sh "$CHK" "$F"

for m in "blocking" "review-blocking" "non-blocking"; do
  viet_spec; thay "$F/open-questions.md" '`non-blocking`' "\`$m\`"
  ky_vong 0 "mức chặn hợp lệ: $m" sh "$CHK" "$F"
done

# Nhãn cũ: chặn kèm hướng dẫn đổi sang Blocking — "cục bộ" có hai đích, người chọn
viet_spec; thay "$F/open-questions.md" '- **Blocking:** `non-blocking`' '- **Mức ảnh hưởng:** `cục bộ`'
ky_vong 1 "chặn nhãn cũ \"Mức ảnh hưởng\"" sh "$CHK" "$F"
dung "…kèm hướng dẫn đổi sang Blocking" sh -c "sh '$CHK' '$F' | grep -q 'đã đổi thành \"Blocking'"
# Việc tạo trước khi đổi sang tiếng Anh: "Mức chặn" tiếng Việt cũng là nhãn cũ
viet_spec; thay "$F/open-questions.md" '- **Blocking:** `non-blocking`' '- **Mức chặn:** `không chặn`'
ky_vong 1 "chặn nhãn cũ \"Mức chặn\"" sh "$CHK" "$F"
dung "…kèm hướng dẫn đổi sang Blocking" sh -c "sh '$CHK' '$F' | grep -q 'YC-002: nhãn cũ.*đã đổi thành \"Blocking'"
viet_spec; thay "$F/open-questions.md" '`non-blocking`' '`toàn bộ thiết kế`'
ky_vong 1 "chặn giá trị cũ \"toàn bộ thiết kế\" dưới nhãn Blocking" sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '`non-blocking`' '`không chặn`'
ky_vong 1 "chặn giá trị tiếng Việt cũ \"không chặn\" dưới nhãn Blocking" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '- **Risk:** `normal`' ''
ky_vong 1 "chặn spec thiếu Mức rủi ro" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '`normal`' '`<high | normal>`'
ky_vong 1 "chặn Mức rủi ro còn chỗ giữ chỗ" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '### YC-002' '### YC-001'
ky_vong 1 "chặn mã YC trùng nhau" sh "$CHK" "$F"

viet_spec; rm -f "$F/open-questions.md"
ky_vong 2 "chặn khi thiếu hẳn open-questions.md" sh "$CHK" "$F"

# "### " không phải YC đóng vùng YC: Nguồn nằm dưới nó không thuộc YC phía trên
viet_spec; thay "$F/spec.md" '### YC-001 — a
- Source: `[JIRA]` ABC-1' '### YC-001 — a
- Description: a

### Ghi chú
- Source: `[JIRA]` ABC-1'
ky_vong 1 "chặn YC không có Nguồn dù \"### phụ\" bên dưới có Nguồn" sh "$CHK" "$F"
dung "…đúng lý do: YC-001 thiếu Nguồn" sh -c "sh '$CHK' '$F' | grep -q 'YC-001: thiếu dòng'"
viet_spec; thay "$F/spec.md" '### YC-002' '### Ghi chú
- Source: `[JIRA]` ABC-9

### YC-002'
ky_vong 0 "Nguồn dưới \"### phụ\" không bị cộng vào YC phía trên" sh "$CHK" "$F"

# open-questions.md 0 byte = đã rà, không có điểm mù (không được làm lệch thứ tự file)
viet_spec; thay "$F/spec.md" '`[OPEN-QUESTION]` → open-questions.md § YC-002
- Assumption: y' '`[JIRA]` ABC-1'
: > "$F/open-questions.md"
ky_vong 0 "open-questions.md 0 byte thì cho qua" sh "$CHK" "$F"

# Ô duyệt spec: chỉ người tick; spec vẫn qua checker khi chưa tick
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 0 "spec chưa tick vẫn qua checker của spec" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' ''
ky_vong 1 "chặn spec thiếu ô duyệt" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [x] Approved by human'
ky_vong 1 "chặn ô duyệt spec sai dạng" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- **Status:** `approved`'
ky_vong 1 "chặn dạng cũ \"Status:\"" sh "$CHK" "$F"
dung "…đúng lý do: dạng cũ" sh -c "sh '$CHK' '$F' | grep -q 'dạng cũ'"
viet_spec; printf '\n- [x] **Approved by human** — đã đọc\n' >> "$F/spec.md"
ky_vong 1 "chặn ô duyệt spec nằm ngoài phần đầu file" sh "$CHK" "$F"
viet_spec; printf '\n```\n- [x] **Approved by human** — đã đọc\n```\n<!--\n- [x] **Approved by human** — đã đọc\n-->\n' >> "$F/spec.md"
ky_vong 0 "ô duyệt trong khối code / chú thích không được tính" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc
- [x] **Approved by human** — đã đọc'
ky_vong 1 "chặn ô duyệt spec bị lặp" sh "$CHK" "$F"

# Dấu duyệt: tick lần đầu thì máy ghi hash; nội dung đổi sau đó thì chặn
viet_spec
ky_vong 0 "spec đã tick qua checker" sh "$CHK" "$F"
dung "…và máy ghi dấu duyệt" grep -q 'approval-hash: [0-9a-f]\{16\}' "$F/spec.md"
H1=$(grep -o 'approval-hash: [0-9a-f]*' "$F/spec.md")
sh "$CHK" "$F" >/dev/null 2>&1
dung "…chạy lại không ghi dấu mới" bang "$H1" "$(grep -o 'approval-hash: [0-9a-f]*' "$F/spec.md")"
thay "$F/spec.md" '## Constraints & dependencies' '<!-- ghi chú khác -->
## Constraints & dependencies'
printf '\n\n' >> "$F/spec.md"
ky_vong 0 "đổi chú thích / dòng trống không làm mất duyệt" sh "$CHK" "$F"
thay "$F/spec.md" 'mở y thấy a' 'mở y thấy a và c'
ky_vong 1 "chặn spec đổi nội dung sau khi người duyệt" sh "$CHK" "$F"
dung "…đúng lý do: đổi sau khi người duyệt" sh -c "sh '$CHK' '$F' | grep -q 'đã đổi sau khi người duyệt'"
ky_vong 1 "…design cũng chặn spec đổi sau duyệt" sh "$T/check-design.sh" "$F"
duyet_lai "$F/spec.md"
ky_vong 0 "người xoá dấu duyệt (giữ tick) thì duyệt lại bản mới" sh "$CHK" "$F"
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
sh "$CHK" "$F" >/dev/null 2>&1
dung "bỏ tick thì máy xoá dấu duyệt thừa" sh -c "! grep -q 'approval-hash' '$F/spec.md'"
viet_spec

# open-questions.md <-> spec.md phải khớp trạng thái
viet_spec; printf '\n## YC-099 — mồ côi\n- **Assumption:** z\n- **Blocking:** `non-blocking`\n- **Status:** `open`\n' >> "$F/open-questions.md"
ky_vong 1 "chặn mục open-questions trỏ về YC không có trong spec" sh "$CHK" "$F"
dung "…đúng lý do: mục mồ côi YC-099" sh -c "sh '$CHK' '$F' | grep -q 'spec.md không có YC-099'"
viet_spec; thay "$F/open-questions.md" '`open`' '`xong`'
ky_vong 1 "chặn Trạng thái điểm mù tự chế" sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** qua email\n' >> "$F/open-questions.md"
ky_vong 1 "chặn điểm mù đã trả lời mà spec vẫn gắn [OPEN-QUESTION]" sh "$CHK" "$F"
thay "$F/spec.md" '`[OPEN-QUESTION]` → open-questions.md § YC-002' '`[FILE]` open-questions.md § YC-002'
ky_vong 1 "spec đã duyệt mà bị sửa (vd /aw-clarify đổi nhãn) thì phải duyệt lại" sh "$CHK" "$F"
duyet_lai "$F/spec.md"
ky_vong 0 "đã trả lời + spec đổi nhãn nguồn + người duyệt lại thì cho qua" sh "$CHK" "$F"
thay "$F/open-questions.md" '- **Answer:** qua email' '- **Answer:** <người trả lời ghi vào đây>'
ky_vong 1 "chặn đã trả lời mà Trả lời còn trống/chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '`[OPEN-QUESTION]` → open-questions.md § YC-002' '`[JIRA]` ABC-2'
ky_vong 1 "chặn spec đã có nguồn mà điểm mù vẫn mở" sh "$CHK" "$F"
viet_spec

# Tiêu chí chấp nhận, Ưu tiên
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' ''
ky_vong 1 "chặn YC không có tiêu chí chấp nhận" sh "$CHK" "$F"
dung "…đúng lý do: YC-001 thiếu tiêu chí" sh -c "sh '$CHK' '$F' | grep -q 'YC-001: thiếu tiêu chí chấp nhận'"
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [ ] <quan sát được từ bên ngoài>'
ky_vong 1 "chặn tiêu chí chấp nhận còn chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [x] mở y thấy a'
ky_vong 0 "tiêu chí đã tick [x] vẫn tính" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Priority: `must`' ''
ky_vong 1 "chặn YC thiếu Ưu tiên" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '`must`' '`high`'
ky_vong 1 "chặn Ưu tiên tự chế" sh "$CHK" "$F"

# Các mục bắt buộc ngoài YC
viet_spec; thay "$F/spec.md" '## Out of scope' '## Ghi chú'
ky_vong 1 "chặn spec thiếu mục Ngoài phạm vi" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- màn hình z — lý do: đợt sau' '- <...> — lý do: <...>'
ky_vong 1 "chặn Ngoài phạm vi chỉ có chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- màn hình z — lý do: đợt sau' 'Không có.'
ky_vong 0 "Ngoài phạm vi ghi \"Không có.\" thì cho qua" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Constraints & dependencies' '## Khác'
ky_vong 1 "chặn spec thiếu mục Ràng buộc & phụ thuộc" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" 'Không có ràng buộc hay phụ thuộc ngoài.' '<!-- chưa rà -->'
ky_vong 1 "chặn Ràng buộc rỗng (chỉ có comment)" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Source conflicts' '## Khác'
ky_vong 1 "chặn spec thiếu mục Mâu thuẫn giữa các nguồn" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" 'Không phát hiện mâu thuẫn.' '<Không có thì ghi "Không phát hiện mâu thuẫn.">'
ky_vong 1 "chặn bảng mâu thuẫn rỗng, chỉ có chỗ giữ chỗ" sh "$CHK" "$F"

# Mâu thuẫn: agent không tự phân xử
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | chọn 30 ngày cho an toàn |'
ky_vong 1 "chặn mâu thuẫn do agent tự phân xử" sh "$CHK" "$F"
dung "…đúng lý do: cột Xử lý" sh -c "sh '$CHK' '$F' | grep -q 'Agent không tự phân xử'"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | open-questions.md § YC-002 |'
ky_vong 0 "mâu thuẫn trỏ tới điểm mù có thật thì cho qua" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | open-questions.md § YC-099 |'
ky_vong 1 "chặn mâu thuẫn trỏ tới điểm mù không có" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | `[JIRA]` ABC-1 comment PO chốt 60 |'
ky_vong 0 "mâu thuẫn trỏ tới nguồn đã chốt thì cho qua" sh "$CHK" "$F"

# Comment HTML nhiều dòng trong mẫu không phải nội dung
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '<!--
  - [ ] mở y thấy a
-->'
ky_vong 1 "tiêu chí nằm trong comment không được tính" sh "$CHK" "$F"
cp "$ROOT/workflow/templates/spec.md" "$F/spec.md"
ky_vong 1 "mẫu spec chưa điền thì không qua" sh "$CHK" "$F"
viet_spec

# ---------------------------------------------------------------- thiet ke
echo ""
echo "check-design.sh"
CHK="$T/check-design.sh"

viet_spec; viet_tdd
rm -f "$F/design-findings.md"
ky_vong 1 "chặn khi checker LLM chưa chạy (không có file phát hiện ≠ đạt)" sh "$CHK" "$F"

printf '### PH-01 — x\n- Severity: `block`\n- Resolution: `open`   <!-- open | fixed -->\n' > "$F/design-findings.md"
ky_vong 1 "chặn phát hiện block chưa xử lý" sh "$CHK" "$F"

printf '### PH-01 — x\n- Severity: `block`\n- Resolution: `rejected:`\n' > "$F/design-findings.md"
ky_vong 1 "chặn bác bỏ phát hiện mà không có lý do" sh "$CHK" "$F"

printf '### PH-01 — x\n- Severity: `block`\n- Resolution: rejected: D-01 đã nói rõ\n### PH-02 — y\n- Severity: `warn`\n- Resolution: open\n' > "$F/design-findings.md"
ky_vong 0 "bác bỏ có lý do + cảnh báo chưa xử lý thì cho qua" sh "$CHK" "$F"

# Việc tạo trước khi đổi sang tiếng Anh: trường cũ (Mức / Xử lý) vẫn đọc được
printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: `chưa`   <!-- chưa | đã sửa -->\n' > "$F/design-findings.md"
ky_vong 1 "trường cũ: phát hiện Chặn chưa xử lý vẫn bị chặn" sh "$CHK" "$F"
printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: bác bỏ: D-01 đã nói rõ\n### PH-02 — y\n- Mức: `Cảnh báo`\n- Xử lý: chưa\n' > "$F/design-findings.md"
ky_vong 0 "trường cũ: bác bỏ có lý do + cảnh báo thì cho qua" sh "$CHK" "$F"
printf '### PH-01 — x\n- Severity: `block`\n- Resolution: fixed\n- Problem: Location và Resolution: chưa rõ\n' > "$F/design-findings.md"
ky_vong 0 "tên trường chỉ khớp ở đầu dòng, không khớp trong nội dung" sh "$CHK" "$F"

viet_tdd; thay "$F/open-questions.md" '`non-blocking`' '`review-blocking`'
ky_vong 0 "điểm mù \"chặn review\" còn mở không chặn design" sh "$CHK" "$F"
viet_spec; viet_tdd; thay "$F/open-questions.md" '`non-blocking`' '`blocking`'
ky_vong 1 "chặn điểm mù \"chặn\" còn mở" sh "$CHK" "$F"
dung "…đúng lý do: YC-002 mức chặn" sh -c "sh '$CHK' '$F' | grep -q 'YC-002: điểm mù mức \"blocking\"'"
thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** qua email\n' >> "$F/open-questions.md"
thay "$F/spec.md" '`[OPEN-QUESTION]` → open-questions.md § YC-002' '`[FILE]` open-questions.md § YC-002'
duyet_lai "$F/spec.md"
ky_vong 0 "đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 1 "chặn vào design khi người chưa duyệt spec" sh "$CHK" "$F"
dung "…đúng lý do: spec chưa được người duyệt" sh -c "sh '$CHK' '$F' | grep -q 'chưa được người duyệt'"
viet_spec

viet_tdd; thay "$F/spec.md" '`[OPEN-QUESTION]` → open-questions.md § YC-002
- Assumption: y' '`[JIRA]` ABC-1'
: > "$F/open-questions.md"
ky_vong 0 "open-questions.md 0 byte không làm design đọc lệch file" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' ''
ky_vong 1 "chặn khi đầu vào spec không qua checker của spec" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/tdd.md" '## Test strategy' '## Kiểm thử'
ky_vong 1 "chặn tdd thiếu mục bắt buộc" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Unit test.' ''
ky_vong 1 "chặn mục bỏ trống không ghi Không áp dụng" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Not applicable: không có API công khai.' 'Not applicable:'
ky_vong 1 "chặn Không áp dụng mà không có lý do" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '| YC-002 | § Flow |' ''
ky_vong 1 "chặn YC chưa được ánh xạ" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Based on: D-01' 'Based on: D-09'
ky_vong 1 "chặn Dựa trên trỏ về D không tồn tại" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' ''
ky_vong 1 "chặn D-xx thiếu ô duyệt" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- Status: `approved`'
ky_vong 1 "chặn D-xx dạng cũ \"Status:\"" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- [x] **Approved by human**
- [x] **Approved by human**'
ky_vong 1 "chặn D-xx có hai ô duyệt" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '## Contract / API' '- [x] **Approved by human**

## Contract / API'
ky_vong 1 "chặn ô duyệt nằm ngoài mục D-xx" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**
- Reopen reason: đổi sang DB'
ky_vong 0 "D mở lại (bỏ tick + lý do) thì thiết kế vẫn hợp lệ" sh "$CHK" "$F"
dung "…và hiện là mở lại" sh -c "sh '$CHK' '$F' | grep -q 'D-01  *reopened'"

viet_tdd
ky_vong 0 "D đã tick qua checker design" sh "$CHK" "$F"
thay "$F/tdd.md" '- Choice: file' '- Choice: file
- Critique (agent): nên cân nhắc DB
  vì dữ liệu sẽ lớn'
ky_vong 0 "agent thêm phản biện không làm mất duyệt D" sh "$CHK" "$F"
thay "$F/tdd.md" '- Choice: file' '- Choice: DB'
ky_vong 1 "chặn D đổi nội dung sau khi người duyệt" sh "$CHK" "$F"
duyet_lai "$F/tdd.md"
ky_vong 0 "người xoá dấu duyệt D thì duyệt lại bản mới" sh "$CHK" "$F"

viet_tdd; thay "$F/spec.md" '`normal`' '`high`'; duyet_lai "$F/spec.md"
ky_vong 1 "Mode 2: chặn rủi ro cao mà không có D do người viết" sh "$CHK" "$F"
thay "$F/tdd.md" '`agent`' '`human`'; duyet_lai "$F/tdd.md"
ky_vong 0 "Mode 2: có D Author: human thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/tdd.md" '## Decisions (D-xx)' '## Decisions (D-xx)
Không có quyết định cần duyệt.
## Bỏ'
thay "$F/tdd.md" 'Based on: D-01' ''
ky_vong 0 "mục Quyết định được phép rỗng" sh "$CHK" "$F"
viet_tdd

# ---------------------------------------------------------------- ke hoach
echo ""
echo "check-plan.sh"
CHK="$T/check-plan.sh"
ghi_based_on

thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
ky_vong 1 "chặn khi còn D-xx chưa được người duyệt" sh "$CHK" "$F"
viet_tdd; ghi_based_on

rm -f "$F/design-findings.md"
ky_vong 1 "chặn khi tdd.md không qua checker của design" sh "$CHK" "$F"
viet_tdd; ghi_based_on

viet_plan; thay "$F/plan.md" '- Covers: `YC-002`' '- Covers: `YC-001`'
ky_vong 1 "chặn YÊU CẦU BỊ BỎ SÓT (chiều ngược)" sh "$CHK" "$F"
thay "$F/plan.md" '|---|---|
' '|---|---|
| YC-002 | chờ BA |
'
ky_vong 0 "hoãn lại có lý do thì cho qua" sh "$CHK" "$F"
dung "…không cảnh báo khi hoãn YC nên có" sh -c "! sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*YC-002: Priority must'"
thay "$F/plan.md" '| YC-002 | chờ BA |' '| YC-002 | chờ BA |
| YC-001 | để sau |'
ky_vong 0 "hoãn YC bắt buộc không chặn" sh "$CHK" "$F"
dung "…nhưng cảnh báo giao thiếu" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*YC-001: Priority must'"
thay "$F/plan.md" '
| YC-001 | để sau |' ''
thay "$F/plan.md" '| YC-002 | chờ BA |' '| YC-002 | |'
ky_vong 1 "chặn hoãn lại bỏ trống lý do" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '`YC-002`' '`YC-999`'
ky_vong 1 "chặn task trỏ về mã YC không tồn tại (chiều xuôi)" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Based on: `D-01`' '- Based on: `D-07`'
ky_vong 1 "chặn task Dựa trên D không có trong tdd.md" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Expected files: `src/b.txt`' ''
ky_vong 1 "chặn task thiếu File dự kiến" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Verify: `test -f src/a.txt` → có file
- Status: `[x]`

## Deferred' '- Verify: <lệnh cụ thể>
- Status: `[x]`

## Deferred'
ky_vong 1 "chặn chỗ giữ chỗ chưa điền" sh "$CHK" "$F"
viet_plan; ghi_based_on

# ---------------------------------------------------------------- hien thuc
echo ""
echo "check-implement.sh"
CHK="$T/check-implement.sh"
CH="$CFG/config.sh"

printf 'TEST_CMD=""\n' > "$CH"
ky_vong 1 "chưa khai TEST_CMD là KHÔNG ĐẠT, không phải bỏ qua" sh "$CHK" "$F"

printf 'TEST_CMD="false"\n%s\n' "$BM_XANH" > "$CH"
ky_vong 1 "chặn khi test đỏ" sh "$CHK" "$F"

printf 'TEST_CMD="true"\n%s\n' "$BM_XANH" > "$CH"
thay "$F/plan.md" '- Status: `[x]`

## Deferred' '- Status: `[~]`

## Deferred'
ky_vong 1 "chặn khi còn task đang làm dở" sh "$CHK" "$F"
viet_plan; ghi_based_on

printf 'TEST_CMD="echo DAU-VET-DUY-NHAT-12345"\n%s\n' "$BM_XANH" > "$CH"
sh "$CHK" "$F" >/dev/null 2>&1
dung "ghi output THẬT vào test-results.md" grep -q 'DAU-VET-DUY-NHAT-12345' "$F/test-results.md"
printf 'TEST_CMD="true"\n%s\n' "$BM_XANH" > "$CH"

printf 'x\n' > "$R/README.md"
ky_vong 0 "file ngoài phạm vi chỉ CẢNH BÁO, không chặn implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo phạm vi" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*README.md'"
rm -f "$R/README.md"

thay "$F/open-questions.md" '`non-blocking`' '`review-blocking`'; ghi_based_on
ky_vong 0 "điểm mù \"chặn review\" còn mở chỉ CẢNH BÁO ở implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo điểm mù" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*YC-002: điểm mù mức \"review-blocking\"'"
viet_spec; ghi_based_on

# ---------------------------------------------------------------- bao mat (aw check security)
echo ""
echo "check-security.sh (aw check security)"
BMC="$T/check-security.sh"
cp "$CH" "$TMP/ch.bak"
ky_vong 0 "đủ ba nhóm, mọi lệnh xanh → ĐẠT" sh "$BMC" "$F"

printf 'TEST_CMD="true"\n' > "$CH"
ky_vong 1 "chưa khai SECURITY_CMDS là KHÔNG ĐẠT, không phải bỏ qua" sh "$BMC" "$F"
ky_vong 1 "…và implement cũng KHÔNG ĐẠT" sh "$CHK" "$F"
printf 'TEST_CMD="true"\nSECURITY_CMDS="\n# sca: trivy fs .\n"\n' > "$CH"
ky_vong 1 "chỉ có dòng comment = chưa khai → KHÔNG ĐẠT" sh "$BMC" "$F"

printf 'TEST_CMD="true"\nSECURITY_CMDS="\nsecret: true\nsast: echo LO-HONG-SQLI; exit 1\nsca: true\n"\n' > "$CH"
ky_vong 1 "một lệnh quét đỏ → KHÔNG ĐẠT" sh "$BMC" "$F"
dung "…ghi ĐỎ và output thật vào security-results.md" sh -c "grep -q '^- Kết quả: \*\*ĐỎ\*\*' '$F/security-results.md' && grep -q 'LO-HONG-SQLI' '$F/security-results.md' && grep -q 'Mã thoát: \`1\`' '$F/security-results.md'"
ky_vong 1 "…implement chặn khi quét bảo mật đỏ dù test xanh" sh "$CHK" "$F"

printf 'TEST_CMD="true"\nSECURITY_CMDS="\ntrivy fs .\n"\n' > "$CH"
ky_vong 1 "dòng thiếu \"<nhóm>:\" → KHÔNG ĐẠT" sh "$BMC" "$F"
printf 'TEST_CMD="true"\nSECURITY_CMDS="\ndast: true\n"\n' > "$CH"
ky_vong 1 "nhóm lạ → KHÔNG ĐẠT" sh "$BMC" "$F"
dung "…đúng lý do: liệt kê nhóm hợp lệ" sh -c "sh '$BMC' '$F' | grep -q 'secret, sast, sca, other'"

printf 'TEST_CMD="true"\nSECURITY_CMDS="secret: true"\n' > "$CH"
ky_vong 0 "thiếu nhóm sast/sca chỉ CẢNH BÁO (người xác nhận có chủ ý)" sh "$BMC" "$F"
dung "…có in cảnh báo thiếu nhóm sca" sh -c "sh '$BMC' '$F' | grep -q 'CẢNH BÁO.*nhóm \"sca\"'"

printf 'TEST_CMD="true"\nSECURITY_CMDS="sca: pwd"\n' > "$CH"
sh "$BMC" "$F" >/dev/null 2>&1
dung "lệnh quét chạy ở gốc repo (như CI)" grep -qx "$(git -C "$R" rev-parse --show-toplevel)" "$F/security-results.md"

# config.sh của bản clone dùng chung mọi version engine: tên khoá cũ (trước 2026.10.21) vẫn đọc được.
printf 'LENH_KIEM_THU="true"\nLENH_KIEM_TRA_BAO_MAT="secret: true\nsast: true\nsca: true"\nSO_LAN_DO_TOI_DA="5"\n' > "$CH"
ky_vong 0 "config.sh tên khoá cũ: quét bảo mật đọc LENH_KIEM_TRA_BAO_MAT" sh "$BMC" "$F"
ky_vong 0 "…implement đọc LENH_KIEM_THU" sh "$CHK" "$F"
dung "…aw ready nêu tên khoá cũ cần đổi" sh -c "sh '$T/ready.sh' '$F' --no-test 2>/dev/null | grep -q 'LENH_KIEM_THU → TEST_CMD'"
printf 'TEST_CMD="true"\nLENH_KIEM_THU="false"\nSECURITY_CMDS="secret: true\nsast: true\nsca: true"\n' > "$CH"
ky_vong 0 "…khai cả tên mới lẫn cũ thì tên mới thắng" sh "$CHK" "$F"
cp "$TMP/ch.bak" "$CH"
sh "$CHK" "$F" >/dev/null 2>&1

# ---------------------------------------------------------------- ra soat
echo ""
echo "check-review.sh"
CHK="$T/check-review.sh"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

ky_vong 0 "rà soát đủ và đúng thì cho qua" sh "$CHK" "$F"

# Điểm mù: "không chặn" còn mở thì giao được (YC chờ xác nhận); "chặn review" thì không
thay "$F/open-questions.md" '`non-blocking`' '`review-blocking`'; ghi_based_on
ky_vong 1 "CỔNG CUỐI: chặn điểm mù \"chặn review\" còn mở" sh "$CHK" "$F"
dung "…đúng lý do: điểm mù YC-002" sh -c "sh '$CHK' '$F' | grep -q 'YC-002: điểm mù mức \"review-blocking\"'"
thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** "đúng như giả định" — PO, 2026-10-04\n' >> "$F/open-questions.md"
thay "$F/spec.md" '`[OPEN-QUESTION]` → open-questions.md § YC-002' '`[FILE]` open-questions.md § YC-002'
duyet_lai "$F/spec.md"; ghi_based_on
ky_vong 0 "điểm mù \"chặn review\" đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec; ghi_based_on

printf '| ID | Verdict |\n|---|---|\n| YC-001 | pass |\n' > "$F/review.md"
ky_vong 1 "chặn khi bỏ sót một yêu cầu" sh "$CHK" "$F"

printf '| ID | Verdict |\n|---|---|\n| YC-001 | pass |\n| YC-002 | pass |\n' > "$F/review.md"
ky_vong 1 "chặn kết luận 'đạt' cho yêu cầu đứng trên giả định tạm" sh "$CHK" "$F"

printf '| ID | Verdict |\n|---|---|\n| YC-001 | ổn |\n| YC-002 | pending |\n' > "$F/review.md"
ky_vong 1 "chặn kết luận tự chế ngoài 4 giá trị hợp lệ" sh "$CHK" "$F"
viet_review

# ---- Lens 4 — Security
printf '| ID | Verdict |\n|---|---|\n| YC-001 | pass |\n| YC-002 | pending |\n' > "$F/review.md"
ky_vong 1 "chặn khi thiếu mục Lens 4 — Security" sh "$CHK" "$F"
dung "…đúng lý do: thiếu mục Lens 4" sh -c "sh '$CHK' '$F' | grep -q 'thiếu mục \"## Lens 4 — Security\"'"
viet_review; thay "$F/review.md" '| Crypto | not applicable | không dùng crypto |
' ''
ky_vong 1 "chặn khi thiếu một hạng mục bảo mật" sh "$CHK" "$F"
dung "…đúng lý do: hạng mục Crypto" sh -c "sh '$CHK' '$F' | grep -q 'Lens 4 \"Crypto\": không có dòng kết luận'"
viet_review; thay "$F/review.md" '| Crypto | not applicable |' '| Cryptography | not applicable |'
ky_vong 1 "chặn khi đổi tên hạng mục (tên cố định)" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Secrets / config | pass |' '| Secrets / config | ổn |'
ky_vong 1 "chặn verdict ngoài pass / finding / not applicable" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Crypto | not applicable | không dùng crypto |' '| Crypto | not applicable | |'
ky_vong 1 "chặn not applicable không có lý do" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Crypto | not applicable | không dùng crypto |' '| Crypto | not applicable | <...> |'
ky_vong 1 "chặn lý do còn chữ giữ chỗ của mẫu" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Secrets / config | pass | |' '| Secrets / config | finding | |'
ky_vong 1 "chặn finding không có vị trí" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Secrets / config | pass | |' '| Secrets / config | finding | `src/a.txt:1` token cứng |'
ky_vong 1 "chặn finding bảo mật mà Lens 3 không có finding nào" sh "$CHK" "$F"
dung "…đúng lý do: thiếu finding ở Lens 3" sh -c "sh '$CHK' '$F' | grep -q 'Lens 3 không có finding nào'"
thay "$F/review.md" '- None' '### [Should fix] token cứng
- Category: hardcoded-secret
- Location: `src/a.txt:1`
- Problem: token trong code'
ky_vong 0 "finding bảo mật có mục ở Lens 3 thì cho qua" sh "$CHK" "$F"
viet_review; cp "$ROOT/workflow/templates/review.md" "$TMP/review-mau.md"
awk '/^## Lens 4/ { p = 1 } /^## Conclusion/ { p = 0 } p' "$TMP/review-mau.md" > "$TMP/lens4-mau.md"
printf '| ID | Verdict |\n|---|---|\n| YC-001 | pass |\n| YC-002 | pending |\n\n' > "$F/review.md"; cat "$TMP/lens4-mau.md" >> "$F/review.md"
ky_vong 1 "chặn bảng Lens 4 chép nguyên mẫu chưa điền" sh "$CHK" "$F"
# ---- Lens 3 — Quality, Conclusion, Reviewed tree
viet_review; thay "$F/review.md" '- None
' ''
ky_vong 1 "chặn Lens 3 không finding mà không ghi \"- None\"" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'không ghi \"- None\"'"
viet_review; thay "$F/review.md" '## Lens 3 — Quality' '## Ghi chú'
ky_vong 1 "chặn khi thiếu mục Lens 3 — Quality" sh "$CHK" "$F"
L3_SF='### [Should fix] trùng hàm
- Category: duplicate-code
- Location: `src/a.txt:1`
- Problem: có sẵn hàm tương tự'
viet_review; thay "$F/review.md" '- None' "$L3_SF"
ky_vong 0 "Lens 3 có finding đủ Location file:dòng thì cho qua" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' "- None
$L3_SF"
ky_vong 1 "chặn Lens 3 vừa \"- None\" vừa có finding" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Should fix] trùng hàm
- Category: duplicate-code
- Problem: có sẵn hàm tương tự'
ky_vong 1 "chặn [Should fix] thiếu Location" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Should fix] trùng hàm
- Category: duplicate-code
- Location: `file:dòng`'
ky_vong 1 "chặn Location giữ chỗ của mẫu (không phải file:dòng)" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Should fix] <tiêu đề>
- Location: `src/a.txt:1`'
ky_vong 1 "chặn tiêu đề finding giữ chỗ của mẫu" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Nit] đặt tên'
ky_vong 0 "[Nit] không bắt Location" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Should fix] trùng hàm
- Location: `src/a.txt:1`'
ky_vong 1 "chặn [Should fix] thiếu Category" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'thiếu dòng \"- Category: <loại>\"'"
viet_review; thay "$F/review.md" '- None' "$(printf '%s\n' "$L3_SF" | sed 's/duplicate-code/Trùng Code/')"
ky_vong 1 "chặn Category không phải kebab-case" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Nit] đặt tên
- Category: Tên Tuỳ Ý'
ky_vong 0 "[Nit] không bắt Category" sh "$CHK" "$F"
L3_B='### [Blocker] mất dữ liệu
- Category: data-loss
- Location: `src/a.txt:1`
- Problem: ghi đè'
viet_review; thay "$F/review.md" '- None' "$L3_B"; thay "$F/review.md" '- Blocker findings: 0' '- Blocker findings: 1'
ky_vong 1 "chặn [Blocker] thiếu Failure scenario" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'thiếu \"- Failure scenario:\"'"
viet_review; thay "$F/review.md" '- None' "$L3_B
- Failure scenario: <đầu vào cụ thể → kết quả sai>"; thay "$F/review.md" '- Blocker findings: 0' '- Blocker findings: 1'
ky_vong 1 "chặn Failure scenario giữ chỗ của mẫu" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' "$L3_B
- Failure scenario: lưu hai lần → bản ghi đầu mất"; thay "$F/review.md" '- Blocker findings: 0' '- Blocker findings: 1'
ky_vong 0 "[Blocker] đủ trường, Conclusion khớp số → review đạt (ship mới chặn)" sh "$CHK" "$F"
thay "$F/review.md" '- Blocker findings: 1' '- Blocker findings: 0'
ky_vong 1 "chặn Conclusion ghi số Blocker lệch số mục" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'Blocker findings: 0 nhưng Lens 3 có 1'"
viet_review; thay "$F/review.md" '- Blocker findings: 0' '- Blocker findings: <n>'
ky_vong 1 "chặn Conclusion còn giữ chỗ <n>" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- Blocker findings: 0
' ''
ky_vong 1 "chặn Conclusion thiếu dòng Blocker findings" sh "$CHK" "$F"
viet_review; grep -v '^- Reviewed tree:' "$F/review.md" > "$TMP/rv" && cp "$TMP/rv" "$F/review.md"
ky_vong 1 "chặn review.md thiếu Reviewed tree" sh "$CHK" "$F"
dung "…lời nhắc có giá trị hiện tại" sh -c "sh '$CHK' '$F' | grep -q 'hiện tại: [0-9a-f]\{40\}'"
viet_review; thay "$F/review.md" "- Reviewed tree: \`$(van_tay)\`" '- Reviewed tree: `0000000000000000000000000000000000000000`'
ky_vong 1 "chặn Reviewed tree khác code hiện tại" sh "$CHK" "$F"
viet_review

# ---- Code nhạy cảm (sensitive_code) → cần người rà bảo mật
viet_review
ky_vong 0 "không khai sensitive_code → không đòi Security reviewer" sh "$CHK" "$F"
cp "$CFG/conventions.md" "$TMP/conv-nc.bak"
thay "$CFG/conventions.md" 'sensitive_code:' 'sensitive_code: src/*'
ky_vong 1 "diff đụng code nhạy cảm mà thiếu Security reviewer → chặn" sh "$CHK" "$F"
dung "…đúng lý do, nêu file nhạy cảm" sh -c "sh '$CHK' '$F' | grep -q 'code nhạy cảm (sensitive_code: src/a.txt)'"
dung "…implement chỉ LƯU Ý, không chặn" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'LƯU Ý.*src/a.txt' && sh '$T/check-implement.sh' '$F' >/dev/null 2>&1"
printf -- '- Security reviewer: <tên người>\n' >> "$F/review.md"
ky_vong 1 "chặn Security reviewer còn giữ chỗ" sh "$CHK" "$F"
viet_review; printf -- '- Security reviewer: Claude\n' >> "$F/review.md"
ky_vong 1 "chặn Security reviewer là tên agent" sh "$CHK" "$F"
viet_review; printf -- '- **Security reviewer:** Nguyễn Văn A — 2026-10-07\n' >> "$F/review.md"
ky_vong 0 "Security reviewer là người → cho qua" sh "$CHK" "$F"
thay "$CFG/conventions.md" 'sensitive_code: src/*' 'sensitive_code: src/auth/*'
viet_review
ky_vong 0 "diff không đụng mẫu nhạy cảm → không đòi" sh "$CHK" "$F"
cp "$TMP/conv-nc.bak" "$CFG/conventions.md"

# Bảng khác nhắc mã YC ở cột lý do không được ghi đè kết luận của Lens 1
viet_review; thay "$F/review.md" '| Authn / authz | pass | màn hình y dùng quyền có sẵn, khớp YC-001 |' '| Authn / authz | pass | khớp YC-002 |'
ky_vong 0 "dòng Lens 4 nhắc YC-002 không ghi đè kết luận pending của Lens 1" sh "$CHK" "$F"
viet_review

printf 'x\n' > "$R/README.md"
ky_vong 1 "CỔNG CUỐI: chặn file ngoài phạm vi" sh "$CHK" "$F"
dung "…và chặn kết quả kiểm thử/quét lỗi thời (code đổi sau lần chạy)" sh -c "sh '$CHK' '$F' | grep -q 'test-results.md lỗi thời'"
thay "$F/plan.md" '|---|---|---|---|
' '|---|---|---|---|
| T-01 | cần README | `README.md` | đã ghi |
'
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1
ky_vong 1 "chạy lại implement mà chưa rà lại → chặn Reviewed tree cũ" sh "$CHK" "$F"
dung "…đúng lý do: code đổi sau khi rà soát" sh -c "sh '$CHK' '$F' | grep -q 'code đổi sau khi rà soát'"
ghi_tree_review
ky_vong 0 "ghi file vào Phát sinh (chạy lại implement, rà lại) thì cho qua" sh "$CHK" "$F"
rm -f "$R/README.md"; viet_plan; ghi_based_on
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review

printf '// covers: YC-001\n' > "$R/test/a.test.js"
ky_vong 1 "CỔNG CUỐI: chặn YC chưa có test gắn tag" sh "$CHK" "$F"
thay "$F/plan.md" '| ID | Why not automated |
|---|---|
' '| ID | Why not automated |
|---|---|
| YC-002 | cần kiểm bằng mắt trên UI |
'
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review
ky_vong 0 "ghi Kiểm chứng thủ công có lý do thì cho qua" sh "$CHK" "$F"
printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"; viet_plan; ghi_based_on
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review

# Không test nào gắn tag: danh sách dòng tag rỗng không được làm kiểm chéo câm
printf '// chua gan tag\n' > "$R/test/a.test.js"
ky_vong 1 "CỔNG CUỐI: chặn khi CHƯA test nào gắn tag covers" sh "$CHK" "$F"
dung "…đúng lý do: YC chưa có test" sh -c "sh '$CHK' '$F' | grep -q 'YC-002: chưa có test'"
dung "…và implement có in cảnh báo YC chưa có test" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'CẢNH BÁO.*YC-001'"
printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

printf '\n<!-- sửa sau khi đã viết spec -->\n' >> "$F/intake.md"
ky_vong 1 "CỔNG CUỐI: chặn spec lỗi thời khi intake.md đổi" sh "$CHK" "$F"
dung "…đúng lý do: spec.md lỗi thời theo intake.md" sh -c "sh '$CHK' '$F' | grep -q 'spec.md: lỗi thời — intake.md'"
viet_intake

printf '\n<!-- sửa sau khi đã có tdd -->\n' >> "$F/spec.md"
ky_vong 1 "CỔNG CUỐI: chặn artifact lỗi thời" sh "$CHK" "$F"
ky_vong 0 "…mà kế hoạch chỉ cảnh báo, không chặn" sh "$T/check-plan.sh" "$F"
viet_spec; ghi_based_on

rm -f "$F/test-results.md"
ky_vong 1 "chặn khi chưa có test-results.md" sh "$CHK" "$F"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

# ---- Độ mới của bằng chứng máy ghi + quét bảo mật (cổng cuối)
dung "test-results.md ghi HEAD, Tree, thời điểm" sh -c "grep -q '^- HEAD: \`[0-9a-f]\{40\}\`' '$F/test-results.md' && grep -q '^- Tree: \`[0-9a-f]\{40\}\`' '$F/test-results.md' && grep -q '^- Thời điểm: ' '$F/test-results.md'"
dung "security-results.md ghi HEAD, Tree, output thật từng nhóm" sh -c "grep -q '^- Tree: \`[0-9a-f]\{40\}\`' '$F/security-results.md' && grep -q '^## sca — ' '$F/security-results.md' && grep -q 'sca-sach' '$F/security-results.md'"

printf 'sua sau review\n' > "$R/src/a.txt"; printf 'moi\n' >> "$R/src/a.txt"
ky_vong 1 "CỔNG CUỐI: chặn khi code đổi (chưa commit) sau lần chạy test/quét" sh "$CHK" "$F"
dung "…đúng lý do: cả hai file kết quả lỗi thời" sh -c "out=\$(sh '$CHK' '$F'); echo \"\$out\" | grep -q 'test-results.md lỗi thời' && echo \"\$out\" | grep -q 'security-results.md lỗi thời'"
printf 'moi\n' > "$R/src/a.txt"
ky_vong 0 "…hoàn tác về đúng nội dung đã chạy thì hết lỗi thời" sh "$CHK" "$F"

cp "$F/test-results.md" "$TMP/kqkt.bak"
grep -v '^- Tree:' "$TMP/kqkt.bak" > "$F/test-results.md"
ky_vong 1 "chặn test-results.md không ghi Tree (engine cũ / viết tay)" sh "$CHK" "$F"
cp "$TMP/kqkt.bak" "$F/test-results.md"

rm -f "$F/security-results.md"
ky_vong 1 "chặn khi chưa có security-results.md" sh "$CHK" "$F"
sh "$T/check-security.sh" "$F" >/dev/null 2>&1
ky_vong 0 "aw check security ghi lại security-results.md thì cho qua" sh "$CHK" "$F"
thay "$F/security-results.md" '- Kết quả: **XANH**' '- Kết quả: **ĐỎ**'
ky_vong 1 "chặn security-results.md không XANH" sh "$CHK" "$F"
sh "$T/check-security.sh" "$F" >/dev/null 2>&1

# ---------------------------------------------------------------- check-ship (aw check ship)
echo ""
echo "check-ship.sh (aw check ship)"
SHC="$T/check-ship.sh"
# viet_mr — mô tả MR điền đủ theo mẫu (comment của mẫu giữ nguyên: là lời dặn, không tính)
viet_mr() {
  cat > "$F/merge-request.md" <<'EOF'
# ABC-1: hiện a và b trên màn hình y

<!-- lời dặn của mẫu: <…> <test> -->

## Problem

- **Current:** màn hình y không có a
- **Expected:** có a và b
- **Root cause:** chưa làm

## Changes

- Màn hình y hiện a và b
- **Breaking change:** None
- **Edge cases:** None

## External Impact

None

## Out of Scope

None

## Deployment

- **Dependencies:** None
- **Order:** không có ràng buộc
- **Migration / Config:** None
- **Rollback:** revert MR là đủ

## Testing

- **Added:** test/a.test.js — có a và b
- **Commands:** `npm test` → xanh

## Open Questions

None

Refs: ABC-1
EOF
}
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
printf '| ID | Verdict |\n|---|---|\n| YC-001 | pass |\n' > "$F/review.md"
ky_vong 1 "aw check review không đạt → chặn" sh "$SHC" "$F"
viet_review
ky_vong 0 "aw-engine check ship → đúng checker" sh "$AWE" check ship "$F"

# ---------------------------------------------------------------- quy tac repo
echo ""
echo "quy tắc riêng của repo (rules_*, aw rules)"
QT="$T/rules.sh"
CONV="$CFG/conventions.md"
cp "$CONV" "$TMP/conv-qt.bak"
# khai_qt <phase> <giá trị> — khai lại từ đầu một khoá rules_<phase>
khai_qt() { cp "$TMP/conv-qt.bak" "$CONV"; thay "$CONV" "rules_$1:" "rules_$1: $2"; }
them_muc_qt() { printf '\n## Repo rules\n\n| File | Verdict | Location / reason |\n|---|---|---|\n%s\n' "$1" >> "$F/review.md"; }

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
echo ""
echo "skill / subagent của repo (uses_*, aw uses)"
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
echo ""
echo "pending.sh (/aw-clarify)"
CHK="$T/pending.sh"
LQ="$TMP/lq"; rm -rf "$LQ"; mkdir -p "$LQ"
cat > "$LQ/spec.md" <<'EOF'
### YC-001 — a
- Priority: `should`
### YC-002 — b
- Priority: `must`
### YC-003 — c
- Priority: `must`
### YC-004 — d
- Priority: `should`
### YC-005 — e
- Priority: `must`
### YC-006 — f
- Priority: `must`
EOF
# Thứ tự trong file cố tình ngược với thứ tự phải giải quyết.
cat > "$LQ/open-questions.md" <<'EOF'
# Điểm mù

## YC-001 — không chặn
- **Question:** hỏi 1
- **Blocking:** `non-blocking`
- **Status:** `open`

## YC-002 — chặn review, bắt buộc, không task
- **Blocking:** `review-blocking`
- **Status:** `open`

## YC-003 — chặn review, bắt buộc, 2 task
- **Blocking:** `review-blocking`
- **Status:** `open`

## YC-004 — chặn, nên có
- **Blocking:** `blocking`
- **Status:** `open`

## YC-005 — chặn, bắt buộc
- **Ask:** PO
- **Blocking:** `blocking`
- **Status:** `open`

## YC-006 — đã trả lời
- **Blocking:** `blocking`
- **Status:** `answered`
- **Answer:** có
EOF
thu_tu() { sh "$CHK" "$LQ" 2>/dev/null | sed -n 's/^  [0-9][0-9]*\. \(YC-[0-9]*\).*/\1/p' | tr '\n' ' '; }
ky_vong 1 "còn điểm mù \"chặn\" mở → ĐANG CHẶN" sh "$CHK" "$LQ"
dung "xếp: chặn → chặn review → không chặn; bắt buộc trước nên có" bang "$(thu_tu)" "YC-005 YC-004 YC-002 YC-003 YC-001 "
printf '### T-01\n- On assumption: **yes** — `open-questions.md` § YC-003\n### T-02\n- On assumption: **yes** — § YC-003\n' > "$LQ/plan.md"
dung "cùng mức + cùng ưu tiên: nhiều task đứng trên giả định hơn thì trước" bang "$(thu_tu)" "YC-005 YC-004 YC-003 YC-002 YC-001 "
dung "…in tên task đứng trên giả định" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'Task on assumption: 2 (T-01 T-02)'"
dung "mục đã trả lời không được liệt kê" sh -c "! sh '$CHK' '$LQ' 2>/dev/null | grep -q 'YC-006'"
dung "mục chặn đánh dấu ĐANG CHẶN phase kế tiếp" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'YC-005.*ĐANG CHẶN /aw-implement'"
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
dung "…xếp lên đầu" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -A1 '^\[CHƯA PHÂN MỨC\]' | grep -q '1\. YC-00'"
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
# Điểm mù

## YC-001 — không chặn
- **Blocking:** `non-blocking`
- **Status:** `open`

## YC-002 — chặn review
- **Blocking:** `review-blocking`
- **Status:** `open`

## YC-005 — chặn
- **Blocking:** `blocking`
- **Status:** `open`
EOF
: > "$LQ/tdd.md"; rm -f "$LQ/plan.md"
cat > "$LQ/design-findings.md" <<'EOF'
# Phát hiện

### PH-01 — cảnh báo
- Severity: `warn`
- Location: `tdd.md` § Flow
- Problem: mơ hồ
- Resolution: `open`

### PH-02 — chặn chưa xử lý
- Severity: `block`   <!-- block | warn -->
- Category: `hidden-decision`
- Location: `tdd.md` § Contract
- Problem: chọn gRPC mà không nêu D
- Resolution: `open`   <!-- open | fixed | rejected: <lý do> -->

### PH-03 — đã sửa
- Severity: `block`
- Resolution: `fixed`

### PH-04 — bác bỏ không lý do
- Severity: `block`
- Resolution: `rejected:`

### PH-05 — bác bỏ có lý do
- Severity: `block`
- Resolution: `rejected: D-02 đã chốt — PO, 2026-10-06`
EOF
thu_tu_all() { sh "$CHK" "$LQ" 2>/dev/null | sed -n 's/^  [0-9][0-9]*\. \([A-Z]*-[0-9]*\).*/\1/p' | tr '\n' ' '; }
ky_vong 1 "phát hiện Chặn chưa xử lý → ĐANG CHẶN" sh "$CHK" "$LQ"
dung "xếp: điểm mù chặn → phát hiện Chặn → chặn review → phát hiện Cảnh báo → không chặn" \
  bang "$(thu_tu_all)" "YC-005 PH-02 PH-04 YC-002 PH-01 YC-001 "
dung "…phát hiện Chặn đánh dấu ĐANG CHẶN /aw-plan" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'PH-02.*ĐANG CHẶN /aw-plan'"
dung "…in vị trí + vấn đề của phát hiện" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'Problem: chọn gRPC mà không nêu D'"
dung "phát hiện đã đóng chỉ nằm ở [ĐÃ XỬ LÝ], không đánh số" sh -c \
  "o=\$(sh '$CHK' '$LQ' 2>/dev/null); echo \"\$o\" | grep -q '^  - PH-03' && echo \"\$o\" | grep -q '^  - PH-05' && ! echo \"\$o\" | grep -q '^  [0-9]*\. PH-0[35]'"
thay "$LQ/open-questions.md" '`blocking`
- **Status:** `open`' '`non-blocking`
- **Status:** `open`'
thay "$LQ/design-findings.md" '`open`   <!-- open' '`fixed`   <!-- open'
thay "$LQ/design-findings.md" '`rejected:`' '`rejected: trùng PH-02`'
ky_vong 3 "chỉ còn phát hiện Cảnh báo + điểm mù chưa chặn → chưa chặn" sh "$CHK" "$LQ"
printf '# Open questions\n\nNo open questions.\n' > "$LQ/open-questions.md"
printf '# Phát hiện\n\nNo blocking findings.\n' > "$LQ/design-findings.md"
ky_vong 0 "file phát hiện rỗng + không điểm mù → không còn việc" sh "$CHK" "$LQ"
printf '### PH-01 — x\n- Severity: `block`\n- Resolution: `open`\n' > "$LQ/plan-findings.md"
ky_vong 1 "checker mới (<id>-findings.md) tự được gom" sh "$CHK" "$LQ"
rm -f "$LQ/plan-findings.md" "$LQ/design-findings.md" "$LQ/tdd.md"

# ---------------------------------------------------------------- based_on
echo ""
echo "based-on.sh"
printf -- '---\nkhac: giu\nbased_on:\n  - spec.md@1\n---\n\n# x\n' > "$F/thu.md"
sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null
sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null
dung "giữ khoá frontmatter khác" grep -q '^khac: giu' "$F/thu.md"
dung "chạy lại không nhân đôi based_on" test "$(grep -c 'spec.md@' "$F/thu.md")" = 1
dung "hash ghi ra khớp file (bỏ dấu duyệt)" grep -q "spec.md@$(tr -d '\r' < "$F/spec.md" | sed 's/ *<!-- approval-hash: [0-9a-f]* -->//' | cksum | awk '{print $1}')" "$F/thu.md"
duyet_lai "$F/spec.md"; sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null
H_TRUOC=$(grep 'spec.md@' "$F/thu.md")
sh "$T/check-spec.sh" "$F" >/dev/null 2>&1
dung "…(spec giờ có dấu duyệt)" grep -q 'approval-hash:' "$F/spec.md"
sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null
dung "máy ghi lại dấu duyệt không làm đổi hash based_on" bang "$H_TRUOC" "$(grep 'spec.md@' "$F/thu.md")"
printf '# không frontmatter\n' > "$F/thu.md"
sh "$T/based-on.sh" "$F" thu.md spec.md >/dev/null
dung "thêm frontmatter khi file chưa có" sh -c "head -1 '$F/thu.md' | grep -q '^---\$'"
rm -f "$F/thu.md"

# ---------------------------------------------------------------- adapter
unset AW_REPO AW_CONFIG   # các mục dưới dùng bộ cài 1.x (install.sh) cho tới khi chuyển sang aw
echo ""
echo "adapters/claude-code/build.sh"
BUILD="$ROOT/adapters/claude-code/build.sh"

O="$TMP/out1"; mkdir -p "$O"
ky_vong 0 "build bản đúng thành công" sh "$BUILD" --out "$O"

du=1
for f in commands/aw-intake.md commands/aw-spec.md commands/aw-design.md commands/aw-plan.md commands/aw-implement.md commands/aw-review.md \
         commands/aw-ship.md commands/aw-import.md commands/aw-clarify.md commands/aw-bootstrap.md agents/independent-reviewer.md agents/design-checker.md skills/agent-workflow/SKILL.md; do
  [ -f "$O/.claude/$f" ] || { du=0; echo "        thiếu .claude/$f"; }
done
dung "sinh đúng bộ file" test "$du" = 1
dung "/aw-ship: điều kiện ra máy là aw check ship" grep -q '`aw check ship <dir>`' "$O/.claude/commands/aw-ship.md"
dung "/aw-ship: ở checkout chính thì làm mục \"Ở checkout chính\", không dừng" sh -c \
  "grep -q 'ĐANG Ở CHECKOUT CHÍNH.*\"On the main checkout\"' '$O/.claude/commands/aw-ship.md' && ! grep -q 'ĐANG Ở CHECKOUT CHÍNH.*stop' '$O/.claude/commands/aw-ship.md'"
dung "…lệnh khác vẫn dừng lại ở checkout chính" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*stop' "$O/.claude/commands/aw-review.md"
dung "/aw-ship: không bắt buộc, có mẫu merge-request.md" sh -c \
  "grep -q 'Required:\*\* no' '$O/.claude/commands/aw-ship.md' && grep -q 'templates/merge-request.md' '$O/.claude/commands/aw-ship.md'"
dung "skill liệt kê /aw-ship" grep -q '| `/aw-ship` |' "$O/.claude/skills/agent-workflow/SKILL.md"
dung "command có bước xác định feature bằng aw feature" grep -q 'aw feature \$ARGUMENTS' "$O/.claude/commands/aw-design.md"
dung "điều kiện ra máy là aw check <tên>" grep -q '`aw check design <dir>`' "$O/.claude/commands/aw-design.md"
dung "không còn gọi script theo đường dẫn bộ cài cũ" sh -c "! grep -rq '\.quy-trinh\|sh tools/\|\.sh ' '$O/.claude'"
dung "command design gọi checker LLM" grep -q 'design-checker' "$O/.claude/commands/aw-design.md"
dung "lệnh /aw-clarify có bước xác định feature + chạy aw pending" sh -c \
  "grep -q 'aw feature \$ARGUMENTS' '$O/.claude/commands/aw-clarify.md' && grep -q 'aw pending' '$O/.claude/commands/aw-clarify.md'"
dung "lệnh /aw-clarify hỏi bằng AskUserQuestion, có Chat about this" sh -c \
  "grep -q 'AskUserQuestion' '$O/.claude/commands/aw-clarify.md' && grep -q 'Chat about this' '$O/.claude/commands/aw-clarify.md'"
dung "…lựa chọn là phương án đã phân tích, (Đề xuất) đứng đầu nhãn" sh -c \
  "grep -q 'Think before asking' '$O/.claude/commands/aw-clarify.md' && grep -q 'starts with.*(Đề xuất)' '$O/.claude/commands/aw-clarify.md'"
dung "…không chiếm chỗ options bằng lối Chat/tự nhập có sẵn của tool" grep -q 'Chat about this' "$O/.claude/commands/aw-clarify.md"
dung "lệnh /aw-clarify dẫn phân xử phát hiện checker LLM" grep -q 'design-findings.md' "$O/.claude/commands/aw-clarify.md"
dung "…lệnh không khai choice_ui thì không có" sh -c "! grep -q 'Asking choice questions' '$O/.claude/commands/aw-import.md'"
dung "/aw-design có cổng duyệt: aw approval design + hộp xác nhận AskUserQuestion" sh -c \
  "grep -q 'Step 1 — Approval gate' '$O/.claude/commands/aw-design.md' && grep -q 'aw approval design' '$O/.claude/commands/aw-design.md' && grep -q 'AskUserQuestion' '$O/.claude/commands/aw-design.md'"
dung "…ba lựa chọn cố định, có preview, từ chối duyệt hộ" sh -c \
  "grep -q 'Tôi đã duyệt xong — kiểm lại' '$O/.claude/commands/aw-design.md' && grep -q 'Giải thích từng điểm cần duyệt' '$O/.claude/commands/aw-design.md' && grep -q 'Dừng — tôi duyệt sau' '$O/.claude/commands/aw-design.md' && grep -q 'preview' '$O/.claude/commands/aw-design.md' && grep -q 'duyệt hộ' '$O/.claude/commands/aw-design.md'"
dung "/aw-plan có cổng duyệt aw approval plan" grep -q 'aw approval plan' "$O/.claude/commands/aw-plan.md"
dung "…phase không khai approval_gate thì không có" sh -c "! grep -q 'Approval gate' '$O/.claude/commands/aw-implement.md' && ! grep -q 'Approval gate' '$O/.claude/commands/aw-spec.md'"
mkdir -p "$O/.claude/skills/quy-trinh-agent"
printf -- '---\nname: quy-trinh-agent\n---\n> **File này được SINH TỰ ĐỘNG** — bản trước 2026.10.21\n' > "$O/.claude/skills/quy-trinh-agent/SKILL.md"
sh "$BUILD" --out "$O" >/dev/null 2>&1
dung "build lại dọn skill cũ quy-trinh-agent (đã đổi tên thành agent-workflow)" sh -c "[ ! -e '$O/.claude/skills/quy-trinh-agent' ] && [ -f '$O/.claude/skills/agent-workflow/SKILL.md' ]"
dung "subagent checker LLM tên <id>-checker" test -f "$O/.claude/agents/design-checker.md"
EX9="$TMP/ex9"; mkdir -p "$EX9"; git -C "$EX9" init -q
printf '/.cursor/commands/\n/.cursor/skills/quy-trinh-agent/\n' > "$EX9/.git/info/exclude"
sh "$T/adapter-build.sh" cursor "$EX9" >/dev/null 2>&1
dung "aw adapter build thêm exclude còn thiếu cho bản clone init từ trước (skill đổi tên)" sh -c "grep -qx '/.cursor/skills/agent-workflow/' '$EX9/.git/info/exclude' && grep -qx '/.agent-workflow/' '$EX9/.git/info/exclude' && [ \"\$(grep -cx '/.cursor/commands/' '$EX9/.git/info/exclude')\" = 1 ]"
dung "…file sinh ra không lọt vào git status" sh -c "[ -z \"\$(git -C '$EX9' status --porcelain)\" ]"
dung "lệnh /aw-import giữ argument-hint riêng" grep -q 'argument-hint: "<file-nguồn>' "$O/.claude/commands/aw-import.md"
dung "mọi lệnh /aw-* chỉ chạy khi người gõ (disable-model-invocation: true trong frontmatter)" sh -c \
  "for f in '$O'/.claude/commands/aw-*.md; do awk 'NR > 1 && /^---\$/ { exit } /^disable-model-invocation: true\$/ { ok = 1 } END { exit !ok }' \"\$f\" || exit 1; done"
dung "skill agent-workflow chỉ chạy khi người gõ" sh -c "sed -n 4p '$O/.claude/skills/agent-workflow/SKILL.md' | grep -qx 'disable-model-invocation: true'"
dung "skill liệt kê lệnh tiện ích" grep -q '/aw-clarify' "$O/.claude/skills/agent-workflow/SKILL.md"
dung "/aw-bootstrap: ở checkout chính làm mục \"On the main checkout\" (đề xuất worktree), không dừng" sh -c \
  "grep -q 'ĐANG Ở CHECKOUT CHÍNH.*\"On the main checkout\"' '$O/.claude/commands/aw-bootstrap.md' && grep -q 'aw worktree new chore' '$O/.claude/commands/aw-bootstrap.md'"
dung "…dùng mẫu target-repo, không tự tạo luật BR-, có bài kiểm tra phiên mới" sh -c \
  "grep -q 'templates/target-repo/AGENTS.md' '$O/.claude/commands/aw-bootstrap.md' && grep -q 'Writing \`BR-\` blocks' '$O/.claude/commands/aw-bootstrap.md' && grep -q 'Fresh-session test' '$O/.claude/commands/aw-bootstrap.md'"
dung "skill liệt kê /aw-bootstrap" grep -q '/aw-bootstrap' "$O/.claude/skills/agent-workflow/SKILL.md"
dung "phase có quy tắc repo: lệnh gọi aw rules <phase> (review: subagent đọc)" sh -c \
  "for p in spec design plan implement; do grep -q \"aw rules \$p\" '$O/.claude/commands/aw-'\$p.md || exit 1; done"
dung "/aw-review chỉ bàn giao cho subagent, không nạp mô tả phase" sh -c \
  "grep -q 'What this session does' '$O/.claude/commands/aw-review.md' && ! grep -q 'Four lenses' '$O/.claude/commands/aw-review.md' && grep -q 'Four lenses' '$O/.claude/agents/independent-reviewer.md'"
dung "mọi lệnh phase có hợp đồng đầy đủ (không bị set -e cắt giữa chừng)" sh -c \
  "for f in '$O'/.claude/commands/aw-*.md; do tail -1 \"\$f\" | grep -q . || exit 1; grep -q '^## Phase contract\|^## Step 0' \"\$f\" || exit 1; done; grep -q 'Exit — MACHINE' '$O/.claude/commands/aw-implement.md'"
dung "…intake thì không" sh -c "! grep -q 'aw rules' '$O/.claude/commands/aw-intake.md'"
dung "mọi lệnh phase kết thúc bằng Kết quả · Cần bạn" sh -c \
  "for p in intake spec design plan implement review ship; do grep -q 'Cần bạn:' '$O/.claude/commands/aw-'\$p.md || exit 1; done"
dung "…lệnh tiếp theo theo thứ tự manifest (implement → review, spec có nhánh chore)" sh -c \
  "grep -q 'Tiếp theo: /aw-review' '$O/.claude/commands/aw-implement.md' && grep -q 'Tiếp theo: /aw-design.*chore: .*/aw-plan' '$O/.claude/commands/aw-spec.md' && grep -q 'Tiếp theo: /aw-ship.*(optional)' '$O/.claude/commands/aw-review.md'"
dung "…phase cuối không có lệnh tiếp theo" sh -c "! grep -q 'Tiếp theo:' '$O/.claude/commands/aw-ship.md'"
dung "…subagent rà soát đọc aw rules review" grep -q 'aw rules review' "$O/.claude/agents/independent-reviewer.md"
dung "…checker LLM soát thiết kế đọc aw rules design" grep -q 'aw rules design' "$O/.claude/agents/design-checker.md"
dung "phase có quy tắc repo: lệnh gọi aw uses <phase>, subagent rà soát gọi aw uses review; intake thì không" sh -c \
  "for p in spec design plan implement; do grep -q \"aw uses \$p\" '$O/.claude/commands/aw-'\$p.md || exit 1; done; grep -q 'aw uses review' '$O/.claude/agents/independent-reviewer.md' && ! grep -q 'aw uses' '$O/.claude/commands/aw-intake.md'"
dung "…Claude Code gọi skill qua Skill tool, không đọc file; subagent qua subagent_type" sh -c \
  "grep -q 'invoke it with the \*\*Skill tool\*\*' '$O/.claude/commands/aw-implement.md' && grep -q 'Skill(<name>)' '$O/.claude/commands/aw-implement.md' && grep -q 'subagent_type: <name>' '$O/.claude/commands/aw-implement.md'"
dung "…lời dặn không chứa thứ Claude Code tự xử lý trong file lệnh (dòng chèn shell)" sh -c "! grep -q '!\`' '$O'/.claude/commands/aw-*.md '$O'/.claude/agents/*.md"

printf '# tôi tự viết\n' > "$O/.claude/commands/aw-spec.md"
ky_vong 3 "từ chối ghi đè file người viết tay" sh "$BUILD" --out "$O"
dung "nội dung người viết còn nguyên" sh -c "head -1 '$O/.claude/commands/aw-spec.md' | grep -q 'tôi tự viết'"
ky_vong 0 "--force thì cho phép ghi đè" sh "$BUILD" --out "$O" --force

# lenh do lan cai truoc sinh ra ma nay khong con (vd /ideation -> /aw-intake)
printf -- '---\n---\n> **File này được SINH TỰ ĐỘNG** từ `workflow/phases/00-ideation.md`\n' > "$O/.claude/commands/ideation.md"
printf '# lệnh tôi tự viết\n' > "$O/.claude/commands/cua-toi.md"
sh "$BUILD" --out "$O" >/dev/null 2>&1
dung "cài lại xoá lệnh sinh tự động không còn trong manifest" test ! -f "$O/.claude/commands/ideation.md"
dung "…nhưng giữ lệnh người viết tay" test -f "$O/.claude/commands/cua-toi.md"

FAKE="$TMP/fake"
tao_fake() {
  rm -rf "$FAKE"; mkdir -p "$FAKE/tools"
  cp -r "$ROOT/workflow" "$FAKE/"
  cp "$ROOT/workflow.yaml" "$FAKE/"
  cp -r "$ROOT/tools/lib" "$FAKE/tools/"
  cp "$ROOT"/tools/*.sh "$FAKE/tools/"
  cp "$ROOT/VERSION" "$FAKE/"
  cp -r "$ROOT/adapters" "$FAKE/"
}

tao_fake
thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - kế hoạch trông có vẻ hợp lý'
O2="$TMP/out2"; mkdir -p "$O2"
ky_vong 4 "từ chối build khi exit_machine không phải lệnh chạy được" sh "$FAKE/adapters/claude-code/build.sh" --out "$O2"
dung "không để lại file viết dở khi build hỏng" sh -c "[ ! -f '$O2/.claude/commands/aw-plan.md' ] && [ -z \"\$(find '$O2' -name '*.tmp')\" ]"

tao_fake
thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - aw check khong-ton-tai'
ky_vong 4 "từ chối build khi aw check trỏ tới checker không có" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out3"

tao_fake
rm -f "$FAKE/workflow/checkers/design.md"
ky_vong 4 "từ chối build khi llm_checker trỏ tới file không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out4"

tao_fake
thay "$FAKE/workflow/phases/00-intake.md" 'arguments: input' 'arguments: gi-cung-duoc'
ky_vong 4 "từ chối build khi arguments không phải \"input\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out5"

tao_fake
thay "$FAKE/workflow/phases/06-ship.md" 'runs_on_main_checkout: true' 'runs_on_main_checkout: co'
ky_vong 4 "từ chối build khi runs_on_main_checkout khác \"true\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out5b"

tao_fake
thay "$FAKE/workflow/phases/06-ship.md" 'required: false' 'required: false
status: chưa hiện thực'
ky_vong 0 "phase status: chưa hiện thực → build vẫn đạt" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out5c"
dung "…nhưng không sinh lệnh cho nó" test ! -e "$TMP/out5c/.claude/commands/aw-ship.md"

tao_fake
rm -f "$FAKE/workflow/clarify.md"
ky_vong 4 "từ chối build khi mục commands: trỏ tới file không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out6"

tao_fake
thay "$FAKE/workflow/clarify.md" 'choice_ui: true' 'choice_ui: co'
ky_vong 4 "từ chối build khi choice_ui khác \"true\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out8"

tao_fake
thay "$FAKE/workflow/phases/02-design.md" 'approval_gate: true' 'approval_gate: co'
ky_vong 4 "từ chối build khi approval_gate khác \"true\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out10"

tao_fake
thay "$FAKE/workflow/checkers/design.md" 'repo_rules: design' 'repo_rules: intake'
ky_vong 4 "từ chối build khi checker LLM khai repo_rules không phải phase có quy tắc" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out9"

tao_fake
thay "$FAKE/workflow/import.md" 'arguments: mixed' 'arguments: input'
ky_vong 4 "từ chối build khi lệnh tiện ích khai arguments khác \"mixed\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out7"

tao_fake
thay "$FAKE/workflow/bootstrap.md" 'runs_on_main_checkout: true' 'runs_on_main_checkout: co'
ky_vong 4 "từ chối build khi lệnh tiện ích khai runs_on_main_checkout khác \"true\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out7b"

# ---------------------------------------------------------------- adapter cursor
echo ""
echo "adapters/cursor/build.sh"
CB="$ROOT/adapters/cursor/build.sh"
O3="$TMP/cur1"; mkdir -p "$O3"
ky_vong 0 "build bản đúng thành công" sh "$CB" --out "$O3"

# ds_tuong_doi <thư-mục> -> đường dẫn tương đối của mọi file, đã sắp
ds_tuong_doi() { (cd "$1" && find . -type f | sed 's|^\./||' | LC_ALL=C sort); }
dung "cùng bộ file với Claude Code (commands/, agents/, skills/) — trùng tên để che bản .claude/" \
  bang "$(ds_tuong_doi "$O3/.cursor")" "$(ds_tuong_doi "$TMP/out1/.claude" | grep -v '^commands/cua-toi.md$')"
dung "…chỉ ghi vào .cursor/" bang "$(ls -A "$O3")" ".cursor"
dung "…có /aw-ship" test -f "$O3/.cursor/commands/aw-ship.md"
dung "không còn \$ARGUMENTS (Cursor không thay biến)" sh -c "! grep -rqF '\$ARGUMENTS' '$O3/.cursor'"
dung "không gọi tool riêng của Claude Code (AskUserQuestion, multiSelect, trường preview/questions)" \
  sh -c "! grep -rqE 'AskUserQuestion|multiSelect|\`preview\`:|\`questions\`' '$O3/.cursor'"
dung "mọi file mang dấu SINH TỰ ĐỘNG + version engine + 'Dành cho Cursor'" sh -c \
  "for f in \$(find '$O3/.cursor' -type f); do grep -q 'SINH TỰ ĐỘNG' \"\$f\" && grep -q \"engine agent-workflow $(cat "$ROOT/VERSION")\" \"\$f\" && grep -q 'Dành cho Cursor' \"\$f\" || exit 1; done"
dung "lệnh là markdown thường: dòng đầu '# /<id> — …', không frontmatter" sh -c \
  "for f in '$O3'/.cursor/commands/*.md; do id=\$(basename \"\$f\" .md); head -1 \"\$f\" | grep -q \"^# /\$id — \" || exit 1; done"
dung "mọi lệnh có mục tham số của Cursor (<tham-số> chép nguyên văn)" sh -c \
  "for f in '$O3'/.cursor/commands/*.md; do grep -q '## Command arguments in Cursor' \"\$f\" && grep -q 'copied verbatim' \"\$f\" || exit 1; done"
dung "/aw-design xác định feature bằng aw feature <tham-số>" grep -qF 'aw feature <tham-số>' "$O3/.cursor/commands/aw-design.md"
dung "/aw-intake: aw feature không tham số, input đi qua heredoc với <tham-số>" sh -c \
  "grep -q 'Run \`aw feature\` — \*\*without\*\* the command arguments' '$O3/.cursor/commands/aw-intake.md' && awk '/<<.HET_INPUT.\$/ { getline; print; exit }' '$O3/.cursor/commands/aw-intake.md' | grep -qx '<tham-số>'"
dung "điều kiện ra máy là aw check <tên>" grep -q '`aw check design <dir>`' "$O3/.cursor/commands/aw-design.md"
dung "/aw-design gọi subagent checker LLM design-checker" grep -q 'subagent `design-checker`' "$O3/.cursor/commands/aw-design.md"
dung "/aw-review bắt buộc subagent independent-reviewer" grep -q 'subagent `independent-reviewer`' "$O3/.cursor/commands/aw-review.md"
dung "subagent: frontmatter name trùng tên file (Cursor nạp .cursor/agents/)" sh -c \
  "for f in '$O3'/.cursor/agents/*.md; do head -1 \"\$f\" | grep -qx -- '---' && sed -n 2p \"\$f\" | grep -qx \"name: \$(basename \"\$f\" .md)\" || exit 1; done"
dung "skill: frontmatter name agent-workflow + description" sh -c \
  "sed -n 2p '$O3/.cursor/skills/agent-workflow/SKILL.md' | grep -qx 'name: agent-workflow' && sed -n 3p '$O3/.cursor/skills/agent-workflow/SKILL.md' | grep -q '^description: ' && sed -n 4p '$O3/.cursor/skills/agent-workflow/SKILL.md' | grep -qx 'disable-model-invocation: true'"
dung "subagent dặn chỉ gọi khi lệnh /aw-* yêu cầu" sh -c \
  "for f in '$O3'/.cursor/agents/*.md; do sed -n 3p \"\$f\" | grep -q 'Only call when an /aw-\* command instructs it' || exit 1; done"
dung "/aw-clarify hỏi lựa chọn kiểu Cursor: tool nếu có, không thì đánh số" sh -c \
  "grep -q '## Asking choice questions in Cursor' '$O3/.cursor/commands/aw-clarify.md' && grep -q 'AskQuestion' '$O3/.cursor/commands/aw-clarify.md' && grep -q 'numbered' '$O3/.cursor/commands/aw-clarify.md'"
dung "…luôn có lối tự nhập và Chat about this (tool không chắc tự thêm)" sh -c \
  "grep -q 'Hoặc gõ câu trả lời khác / hỏi lại để trao đổi về câu này' '$O3/.cursor/commands/aw-clarify.md' && grep -q 'Chat about this' '$O3/.cursor/commands/aw-clarify.md'"
dung "…(Đề xuất) đứng đầu nhãn, phân tích trước khi hỏi" sh -c \
  "grep -q 'starts with.*(Đề xuất)' '$O3/.cursor/commands/aw-clarify.md' && grep -q 'Think before asking' '$O3/.cursor/commands/aw-clarify.md'"
dung "…lệnh không khai choice_ui thì không có" sh -c "! grep -q 'Asking choice questions' '$O3/.cursor/commands/aw-import.md' && ! grep -q 'Asking choice questions' '$TMP/out1/.claude/commands/aw-import.md'"
dung "/aw-design, /aw-plan có cổng duyệt aw approval + hộp xác nhận Cursor" sh -c \
  "grep -q 'aw approval design' '$O3/.cursor/commands/aw-design.md' && grep -q 'aw approval plan' '$O3/.cursor/commands/aw-plan.md' && grep -q '### Confirmation box in Cursor' '$O3/.cursor/commands/aw-plan.md'"
dung "…phase không khai approval_gate thì không có" sh -c \
  "for p in intake spec implement review; do ! grep -q 'Approval gate' '$O3/.cursor/commands/aw-'\$p.md || exit 1; done"
dung "phase có quy tắc repo: lệnh gọi aw rules <phase>; intake thì không" sh -c \
  "for p in spec design plan implement; do grep -q \"aw rules \$p\" '$O3/.cursor/commands/aw-'\$p.md || exit 1; done; ! grep -q 'aw rules' '$O3/.cursor/commands/aw-intake.md'"
dung "phase có quy tắc repo: lệnh gọi aw uses <phase>; Cursor đọc file khi không có tool gọi skill" sh -c \
  "for p in spec design plan implement; do grep -q \"aw uses \$p\" '$O3/.cursor/commands/aw-'\$p.md || exit 1; done; grep -q 'read the printed file' '$O3/.cursor/commands/aw-implement.md' && ! grep -q 'Skill tool' '$O3/.cursor/commands/aw-implement.md'"
dung "skill liệt kê phase và lệnh tiện ích" sh -c \
  "grep -q '| \`/aw-design\` |' '$O3/.cursor/skills/agent-workflow/SKILL.md' && grep -q '/aw-clarify' '$O3/.cursor/skills/agent-workflow/SKILL.md'"

printf '# tôi tự viết\n' > "$O3/.cursor/commands/aw-spec.md"
ky_vong 3 "từ chối ghi đè file người viết tay" sh "$CB" --out "$O3"
dung "…nội dung người viết còn nguyên" sh -c "head -1 '$O3/.cursor/commands/aw-spec.md' | grep -q 'tôi tự viết'"
ky_vong 0 "--force thì cho phép ghi đè" sh "$CB" --out "$O3" --force
printf -- '> **File này được SINH TỰ ĐỘNG** từ `workflow/phases/00-ideation.md`\n' > "$O3/.cursor/commands/ideation.md"
printf -- '> **File này được SINH TỰ ĐỘNG** — agent cũ\n' > "$O3/.cursor/agents/cu.md"
printf '# lệnh tôi tự viết\n' > "$O3/.cursor/commands/cua-toi.md"
sh "$CB" --out "$O3" >/dev/null 2>&1
dung "build lại xoá lệnh/subagent sinh tự động không còn trong manifest" sh -c "[ ! -e '$O3/.cursor/commands/ideation.md' ] && [ ! -e '$O3/.cursor/agents/cu.md' ]"
dung "…nhưng giữ lệnh người viết tay" test -f "$O3/.cursor/commands/cua-toi.md"
ky_vong 2 "từ chối --out nằm trong repo agent-workflow" sh "$CB" --out "$ROOT/adapters"
ky_vong 2 "thiếu --out → SAI THAM SỐ" sh "$CB"
ky_vong 2 "tham số lạ → SAI THAM SỐ" sh "$CB" --out "$O3" --khac

# File .cursor/ git đang theo dõi (team commit lệnh trùng tên): bỏ qua, không đụng
RT="$TMP/cur-team"; mkdir -p "$RT/.cursor/commands"; git -C "$RT" init -q
printf '# lệnh spec của team\n' > "$RT/.cursor/commands/aw-spec.md"
git -C "$RT" add -A; git -C "$RT" -c user.name=t -c user.email=t@t commit -q -m team
ky_vong 0 "file git đang theo dõi → bỏ qua, build vẫn đạt" sh "$CB" --out "$RT"
dung "…nội dung của team giữ nguyên, cây sạch" sh -c "grep -q 'của team' '$RT/.cursor/commands/aw-spec.md' && [ -z \"\$(git -C '$RT' status --porcelain -- .cursor/commands/aw-spec.md)\" ]"

# Định nghĩa quy trình lỗi: MỌI adapter phải từ chối, không để lại file viết dở
for ad in claude-code cursor; do
  tao_fake
  thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - kế hoạch trông có vẻ hợp lý'
  ky_vong 4 "$ad: từ chối build khi exit_machine không phải lệnh chạy được" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-1"
  dung "$ad: …không để lại file viết dở" sh -c "[ -z \"\$(find '$TMP/f-$ad-1' -name '*.tmp' 2>/dev/null)\" ] && [ ! -e '$TMP/f-$ad-1/.claude/commands/aw-plan.md' ] && [ ! -e '$TMP/f-$ad-1/.cursor/commands/aw-plan.md' ]"
  tao_fake
  thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - aw check khong-ton-tai'
  ky_vong 4 "$ad: từ chối build khi aw check trỏ tới checker không có" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-2"
  tao_fake; rm -f "$FAKE/workflow/checkers/design.md"
  ky_vong 4 "$ad: từ chối build khi llm_checker trỏ tới file không tồn tại" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-3"
  tao_fake; thay "$FAKE/workflow/phases/02-design.md" 'approval_gate: true' 'approval_gate: co'
  ky_vong 4 "$ad: từ chối build khi approval_gate khác \"true\"" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-4"
  tao_fake; thay "$FAKE/workflow/clarify.md" 'choice_ui: true' 'choice_ui: co'
  ky_vong 4 "$ad: từ chối build khi choice_ui khác \"true\"" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-5"
  tao_fake; thay "$FAKE/workflow/phases/00-intake.md" 'arguments: input' 'arguments: gi-cung-duoc'
  ky_vong 4 "$ad: từ chối build khi arguments không phải \"input\"" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-6"
done

# Adapter thiếu hook → ĐỊNH NGHĨA QUY TRÌNH LỖI, không sinh gì
tao_fake
mkdir -p "$FAKE/adapters/thieu-hook"
sed '/^ad_hoi_cong_duyet() {/,/^}/d' "$CB" > "$FAKE/adapters/thieu-hook/build.sh"
ky_vong 4 "adapter thiếu hook (ad_hoi_cong_duyet) → từ chối build" sh "$FAKE/adapters/thieu-hook/build.sh" --out "$TMP/f-thieu"
dung "…không sinh file nào" sh -c "[ -z \"\$(find '$TMP/f-thieu' -type f 2>/dev/null)\" ]"

# ---------------------------------------------------------------- chuẩn định dạng của agent
# adapters/lib/format.sh: mọi file sinh ra phải đúng chuẩn agent đọc (frontmatter
# YAML, khoá được phép, name = tên file/thư mục…) — sai thì SAI CHUẨN, file không vào chỗ.
echo ""
echo "chuẩn định dạng của agent (adapters/lib/format.sh)"
# ad_gia <adapter> <tên-bản-sao> <đoạn-shell> — bản sao adapter, chèn đoạn ngay trước ad_sinh
ad_gia() {
  mkdir -p "$FAKE/adapters/$2"
  awk -v d="$3" '$0 == "ad_sinh \"$@\"" { print d } { print }' "$FAKE/adapters/$1/build.sh" > "$FAKE/adapters/$2/build.sh"
}
# dd_tho <adapter> <file> — chạy riêng dd_kiem lên một file như thể nó nằm ở <file> trong .<goc>/
dd_tho() {
  sh -c ". '$FAKE/adapters/lib/format.sh'; OUT=/o; AD_TEN=x; $(grep -E '^AD_(GOC|LENH_FM|LENH_KHOA|AGENT_KHOA|SKILL_KHOA)=' "$ROOT/adapters/$1/build.sh" | tr '\n' ';') dd_kiem '$TMP/dd.md' \"/o/\$AD_GOC/$2\""
}
tao_fake
for ad in claude-code cursor; do
  goc=$(sed -n 's/^AD_GOC=//p' "$ROOT/adapters/$ad/build.sh")
  ky_vong 0 "$ad: bản đúng qua kiểm chuẩn" sh "$ROOT/adapters/$ad/build.sh" --out "$TMP/dd-$ad-0"
  ad_gia "$ad" "$ad-ten" "ad_dau_agent() { printf -- '---\\\\nname: Sai_Ten\\\\ndescription: x\\\\n---\\\\n\\\\n'; }"
  ky_vong 5 "$ad: subagent name không đúng dạng → SAI CHUẨN" sh "$FAKE/adapters/$ad-ten/build.sh" --out "$TMP/dd-$ad-1"
  dung "$ad: …file sai không vào chỗ, không để lại .tmp" sh -c "[ ! -e '$TMP/dd-$ad-1/$goc/agents/independent-reviewer.md' ] && [ -z \"\$(find '$TMP/dd-$ad-1' -name '*.tmp')\" ]"
  ad_gia "$ad" "$ad-khac" "ad_dau_agent() { printf -- '---\\\\nname: %s-cu\\\\ndescription: %s\\\\n---\\\\n\\\\n' \"\$1\" \"\$2\"; }"
  ky_vong 5 "$ad: subagent name khác tên file → SAI CHUẨN" sh "$FAKE/adapters/$ad-khac/build.sh" --out "$TMP/dd-$ad-2"
  ad_gia "$ad" "$ad-khoa" "ad_dau_agent() { printf -- '---\\\\nname: %s\\\\ndescription: %s\\\\nkhoa-la: 1\\\\n---\\\\n\\\\n' \"\$1\" \"\$2\"; }"
  ky_vong 5 "$ad: subagent có khoá ngoài chuẩn → SAI CHUẨN" sh "$FAKE/adapters/$ad-khoa/build.sh" --out "$TMP/dd-$ad-3"
  ad_gia "$ad" "$ad-dai" "ad_dau_skill() { printf -- '---\\\\nname: %s\\\\ndescription: %s\\\\n---\\\\n\\\\n' \"\$1\" \"\$(printf '%01100d' 0)\"; }"
  ky_vong 5 "$ad: skill description > 1024 ký tự → SAI CHUẨN" sh "$FAKE/adapters/$ad-dai/build.sh" --out "$TMP/dd-$ad-4"
  dung "$ad: …skill không vào chỗ" test ! -e "$TMP/dd-$ad-4/$goc/skills/agent-workflow/SKILL.md"
  ad_gia "$ad" "$ad-fm" "AD_LENH_FM=gi-do"
  ky_vong 4 "$ad: AD_LENH_FM khác co|khong → ĐỊNH NGHĨA QUY TRÌNH LỖI" sh "$FAKE/adapters/$ad-fm/build.sh" --out "$TMP/dd-$ad-5"
  ad_gia "$ad" "$ad-thieu" "AD_AGENT_KHOA="
  ky_vong 4 "$ad: thiếu AD_AGENT_KHOA → ĐỊNH NGHĨA QUY TRÌNH LỖI" sh "$FAKE/adapters/$ad-thieu/build.sh" --out "$TMP/dd-$ad-6"
done
# Claude Code: frontmatter lệnh phải là YAML hợp lệ
ad_gia claude-code cc-hint "ad_dau_lenh() { printf -- '---\\\\ndescription: \"%s\"\\\\nargument-hint: %s\\\\n---\\\\n\\\\n' \"\$3\" \"\$4\"; }"
ky_vong 5 "claude-code: argument-hint mở bằng [ không nháy (YAML hiểu thành danh sách) → SAI CHUẨN" sh "$FAKE/adapters/cc-hint/build.sh" --out "$TMP/dd-cc-1"
ad_gia claude-code cc-mota "ad_dau_lenh() { printf -- '---\\\\ndescription: %s\\\\nargument-hint: \"%s\"\\\\n---\\\\n\\\\n' \"\$3\" \"\$4\"; }"
ky_vong 5 "claude-code: description có ': ' không nháy → SAI CHUẨN" sh "$FAKE/adapters/cc-mota/build.sh" --out "$TMP/dd-cc-2"
ad_gia claude-code cc-dong "ad_dau_lenh() { printf -- '---\\\\ndescription: \"%s\"\\\\n\\\\n' \"\$3\"; }"
ky_vong 5 "claude-code: frontmatter không có --- đóng → SAI CHUẨN" sh "$FAKE/adapters/cc-dong/build.sh" --out "$TMP/dd-cc-3"
ad_gia claude-code cc-khong "ad_dau_lenh() { printf '# /%s\\\\n\\\\n' \"\$1\"; }"
ky_vong 5 "claude-code: lệnh thiếu frontmatter description → SAI CHUẨN" sh "$FAKE/adapters/cc-khong/build.sh" --out "$TMP/dd-cc-4"
# Cursor: lệnh là markdown thường
ad_gia cursor cu-fm "ad_dau_lenh() { printf -- '---\\\\ndescription: x\\\\n---\\\\n\\\\n'; }"
ky_vong 5 "cursor: lệnh có frontmatter → SAI CHUẨN" sh "$FAKE/adapters/cu-fm/build.sh" --out "$TMP/dd-cu-1"
# dd_kiem trực tiếp: các trường hợp biên của YAML
printf -- '---\nname: a\ndescription: "mở nháy\n---\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: nháy kép không đóng → sai" dd_tho cursor agents/a.md
printf -- '---\nname: a\ndescription: "có \\"nháy\\" và : bên trong"\n---\nthân\n' > "$TMP/dd.md"
ky_vong 0 "dd_kiem: nháy kép có \\\" và ': ' bên trong → đúng" dd_tho cursor agents/a.md
printf -- "---\nname: a\ndescription: 'it''s ok: yes'\n---\nthân\n" > "$TMP/dd.md"
ky_vong 0 "dd_kiem: nháy đơn có '' → đúng" dd_tho cursor agents/a.md
printf -- '---\nname: a\nname: a\ndescription: x\n---\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: khoá trùng → sai" dd_tho cursor agents/a.md
printf -- '---\nname: a\ndescription:\tx\n---\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: tab trong frontmatter → sai" dd_tho cursor agents/a.md
printf -- '---\nname: a\ndescription: x\n---\n\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: thân rỗng → sai" dd_tho cursor agents/a.md
printf -- '---\nname: s\ndescription: dùng <thẻ>\n---\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: skill description có < > → sai" dd_tho claude-code skills/s/SKILL.md
printf -- '---\nname: s\ndescription: %s\n---\nthân\n' "$(awk 'BEGIN { for (i = 0; i < 1024; i++) printf "ư" }')" > "$TMP/dd.md"
ky_vong 0 "dd_kiem: skill description đúng 1024 ký tự (chữ có dấu tính 1) → đúng" dd_tho claude-code skills/s/SKILL.md
printf '# /Aw_Sai\n\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: tên file lệnh không đúng dạng → sai" dd_tho cursor commands/Aw_Sai.md
printf '# x\n\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: đường dẫn agent không đọc → sai" dd_tho cursor rules/x.md

# ---------------------------------------------------------------- đối chiếu mọi adapter
# Mọi adapter dùng chung adapters/lib/common.sh. AW_COMPARE=1: hook in tên của nó
# thay cho nội dung — phần còn lại (hợp đồng phase, Bước 0, cổng duyệt, quy tắc
# repo, thân phase…) phải GIỐNG HỆT nhau từng byte. Ai sửa hợp đồng cho một agent
# mà quên agent kia, hay viết chữ riêng của agent ngoài hook, là hỏng ở đây.
echo ""
echo "đối chiếu mọi adapter (một hợp đồng phase cho mọi agent)"
DC="$TMP/doi-chieu"; mkdir -p "$DC"
n_ad=0; dc_build=1; dc_goc=1
for b in "$ROOT"/adapters/*/build.sh; do
  a=$(basename "$(dirname "$b")"); n_ad=$((n_ad + 1)); mkdir -p "$DC/$a"
  AW_COMPARE=1 sh "$b" --out "$DC/$a" >/dev/null 2>&1 || { dc_build=0; echo "        $a: build hỏng"; }
  g=$(ls -A "$DC/$a")
  if [ "$(printf '%s\n' "$g" | wc -l | tr -d ' ')" = 1 ] && [ -n "$g" ]; then mv "$DC/$a/$g" "$DC/$a/goc"
  else dc_goc=0; echo "        $a: không ghi vào đúng một thư mục gốc: $g"; fi
done
dung "có ít nhất hai adapter để đối chiếu" test "$n_ad" -ge 2
dung "mọi adapter build được ở chế độ đối chiếu" test "$dc_build" = 1
dung "mỗi adapter chỉ ghi vào một thư mục gốc của nó (.claude/, .cursor/…)" test "$dc_goc" = 1
dc_khac=0; dau=""
for d in "$DC"/*/; do
  [ -d "$d/goc" ] || continue
  if [ -z "$dau" ]; then dau=$d; continue; fi
  if ! diff -r "$dau/goc" "$d/goc" >/dev/null 2>&1; then
    dc_khac=1; echo "        khác: $(basename "$dau") ↔ $(basename "$d")"
    diff -r "$dau/goc" "$d/goc" 2>&1 | head -8 | sed 's/^/          /'
  fi
done
dung "ngoài hook, output của mọi adapter giống hệt nhau từng byte" test "$dc_khac" = 0
dung "…phép đối chiếu không rỗng: hook thật sự được gọi (cổng duyệt, hỏi lựa chọn, tham số)" sh -c \
  "grep -q '<<ad_hoi_cong_duyet design>>' '$dau/goc/commands/aw-design.md' && grep -q '<<ad_hoi_lua_chon>>' '$dau/goc/commands/aw-clarify.md' && grep -q 'aw feature <<ad_tham_so>>' '$dau/goc/commands/aw-spec.md' && grep -q '<<ad_danh_cho>>' '$dau/goc/agents/independent-reviewer.md'"
dung "…và phần dùng chung không chứa chữ riêng của agent nào" sh -c \
  "! grep -rqE 'AskUserQuestion|AskQuestion|\\\$ARGUMENTS|<tham-số>|\\.claude/|\\.cursor/' '$dau/goc'"

# Ở chế độ thường: chữ riêng của agent ĐÚNG agent, và các hằng của cổng duyệt
# (câu hỏi, ba nhãn) giống hệt nhau giữa các adapter.
DT="$TMP/doi-chieu-that"; mkdir -p "$DT"
for b in "$ROOT"/adapters/*/build.sh; do
  a=$(basename "$(dirname "$b")"); mkdir -p "$DT/$a"; sh "$b" --out "$DT/$a" >/dev/null 2>&1
done
# cau_hoi <file> -> các chuỗi trong backtick kết thúc bằng "bạn muốn làm gì?", đã sắp
cau_hoi() { grep -o '`[^`]*bạn muốn làm gì?`' "$1" | LC_ALL=C sort -u; }
nhan_cd() { grep -oE '`(Tôi đã duyệt xong — kiểm lại|Giải thích từng điểm cần duyệt|Dừng — tôi duyệt sau)`' "$1" | tr '\n' '|'; }
cd_khac=0
for p in design plan; do
  q0=$(cau_hoi "$DT/claude-code/.claude/commands/aw-$p.md"); n0=$(nhan_cd "$DT/claude-code/.claude/commands/aw-$p.md")
  [ -n "$q0" ] && [ "$n0" = '`Tôi đã duyệt xong — kiểm lại`|`Giải thích từng điểm cần duyệt`|`Dừng — tôi duyệt sau`|' ] || { cd_khac=1; echo "        claude-code /$p: thiếu câu hỏi hay nhãn"; }
  for d in "$DT"/*/; do
    f=$(find "$d" -path "*/commands/aw-$p.md" | head -1)
    [ "$(cau_hoi "$f")" = "$q0" ] || { cd_khac=1; echo "        $(basename "$d") /$p: câu hỏi cổng duyệt khác"; }
    [ "$(nhan_cd "$f")" = "$n0" ] || { cd_khac=1; echo "        $(basename "$d") /$p: ba nhãn / thứ tự khác"; }
  done
done
dung "cổng duyệt: cùng câu hỏi, cùng ba nhãn đúng thứ tự ở mọi adapter" test "$cd_khac" = 0
dung "mọi file .claude/ ghi 'Dành cho Claude Code' và chỉ đường sang .cursor/ (Cursor nạp .claude/)" sh -c \
  "for f in \$(find '$DT/claude-code/.claude' -type f); do grep -q 'Dành cho Claude Code' \"\$f\" && grep -q 'AskUserQuestion' \"\$f\" && grep -qF '.cursor/' \"\$f\" || exit 1; done"
dung "mọi subagent trùng tên giữa các adapter (bản .cursor/ che bản .claude/)" \
  bang "$(ls "$DT/cursor/.cursor/agents")" "$(ls "$DT/claude-code/.claude/agents")"

# Hai adapter cùng một worktree: không đè, không dọn file của nhau
echo ""
echo "hai adapter cùng một thư mục"
B2="$TMP/ca-hai"; mkdir -p "$B2"
ky_vong 0 "build claude-code rồi cursor vào cùng thư mục" sh -c "sh '$ROOT/adapters/claude-code/build.sh' --out '$B2' && sh '$CB' --out '$B2'"
dung "….claude/ giống hệt khi build riêng" diff -r "$B2/.claude" "$DT/claude-code/.claude"
dung "….cursor/ giống hệt khi build riêng" diff -r "$B2/.cursor" "$DT/cursor/.cursor"
printf -- '> **File này được SINH TỰ ĐỘNG** — lệnh cũ\n' > "$B2/.claude/commands/cu-claude.md"
printf -- '> **File này được SINH TỰ ĐỘNG** — lệnh cũ\n' > "$B2/.cursor/commands/cu-cursor.md"
sh "$CB" --out "$B2" >/dev/null 2>&1
dung "build cursor chỉ dọn file cũ của .cursor/, không đụng .claude/" sh -c "[ ! -e '$B2/.cursor/commands/cu-cursor.md' ] && [ -f '$B2/.claude/commands/cu-claude.md' ]"
sh "$ROOT/adapters/claude-code/build.sh" --out "$B2" >/dev/null 2>&1
dung "…build claude-code dọn của .claude/, .cursor/ vẫn nguyên" sh -c "[ ! -e '$B2/.claude/commands/cu-claude.md' ] && diff -r '$B2/.cursor' '$DT/cursor/.cursor'"
mkdir -p "$TMP/ca-hai-2" "$TMP/ca-hai-3"
ky_vong 0 "tools/adapter-build.sh nhận danh sách claude-code,cursor" sh "$T/adapter-build.sh" claude-code,cursor "$TMP/ca-hai-2"
dung "…ghi dấu build cho từng adapter" bang "$(cat "$TMP/ca-hai-2/.agent-workflow/.adapters" 2>/dev/null)" "claude-code $(cat "$ROOT/VERSION")
cursor $(cat "$ROOT/VERSION")"
dung "…cả hai bộ giống hệt khi build riêng" sh -c "diff -r '$TMP/ca-hai-2/.claude' '$DT/claude-code/.claude' && diff -r '$TMP/ca-hai-2/.cursor' '$DT/cursor/.cursor'"
ky_vong 2 "tools/adapter-build.sh: một id không có → SAI THAM SỐ, không sinh gì" sh "$T/adapter-build.sh" "claude-code khong-co" "$TMP/ca-hai-3"
dung "…không sinh adapter nào" sh -c "[ ! -e '$TMP/ca-hai-3/.claude' ] && [ ! -e '$TMP/ca-hai-3/.agent-workflow' ]"
mkdir -p "$TMP/ca-hai-4/.cursor/commands"; printf '# tự viết\n' > "$TMP/ca-hai-4/.cursor/commands/aw-spec.md"
ky_vong 3 "một adapter hỏng (file viết tay) → mã của adapter đó" sh "$T/adapter-build.sh" claude-code,cursor "$TMP/ca-hai-4"
dung "…adapter kia vẫn sinh đủ, dấu build chỉ ghi adapter đạt" sh -c \
  "diff -r '$TMP/ca-hai-4/.claude' '$DT/claude-code/.claude' && grep -q '^claude-code ' '$TMP/ca-hai-4/.agent-workflow/.adapters' && ! grep -q '^cursor ' '$TMP/ca-hai-4/.agent-workflow/.adapters'"

# exclude của từng adapter phủ đúng file nó sinh — và không giấu file của team
echo ""
echo "exclude của adapter"
for b in "$ROOT"/adapters/*/build.sh; do
  a=$(basename "$(dirname "$b")"); RX="$TMP/ex-$a"; mkdir -p "$RX"; git -C "$RX" init -q
  grep -v '^#' "$ROOT/adapters/$a/exclude" >> "$RX/.git/info/exclude"
  sh "$b" --out "$RX" >/dev/null 2>&1
  dung "$a: mọi file sinh ra bị exclude (git status sạch)" sh -c "[ -n \"\$(find '$RX' -path '$RX/.git' -prune -o -type f -print)\" ] && [ -z \"\$(git -C '$RX' status --porcelain --untracked-files=all)\" ]"
done
mkdir -p "$TMP/ex-cursor/.cursor/rules"; printf 'x\n' > "$TMP/ex-cursor/.cursor/rules/team.mdc"; printf '{}\n' > "$TMP/ex-cursor/.cursor/hooks.json"
mkdir -p "$TMP/ex-cursor/.cursor/skills/cua-team"; printf 'x\n' > "$TMP/ex-cursor/.cursor/skills/cua-team/SKILL.md"
dung "cursor: không giấu file team commit (.cursor/rules, hooks.json, skill khác)" bang \
  "$(git -C "$TMP/ex-cursor" status --porcelain --untracked-files=all | LC_ALL=C sort | tr '\n' '|')" \
  "?? .cursor/hooks.json|?? .cursor/rules/team.mdc|?? .cursor/skills/cua-team/SKILL.md|"

# ---------------------------------------------------------------- khong cai vao engine
echo ""
echo "không cài vào chính engine"
ky_vong 2 "aw-engine init từ chối repo đích là chính engine" env AW_REPO="$ROOT" AW_CONFIG="$TMP/cfg-engine" sh "$ROOT/bin/aw-engine" init
dung "…và không ghi gì" test ! -e "$TMP/cfg-engine/conventions.md"
ky_vong 2 "aw-engine init từ chối thư mục con của engine" env AW_REPO="$ROOT/adapters" AW_CONFIG="$TMP/cfg-engine" sh "$ROOT/bin/aw-engine" init
ky_vong 2 "build.sh từ chối --out nằm trong repo agent-workflow" sh "$BUILD" --out "$ROOT/adapters"
ky_vong 2 "aw adapter build từ chối --out nằm trong engine" sh "$ROOT/bin/aw-engine" adapter build claude-code --out "$ROOT/adapters"

# ---------------------------------------------------------------- xac dinh feature
# Từ đây: repo đích init bằng wrapper aw, engine là chính repo này (AW_ENGINE_DIR).
echo ""
echo "aw feature (feature.sh)"
unset AW_REPO AW_CONFIG
AWHD="$TMP/awhome-dev"; VDEV=$(cat "$ROOT/VERSION")
# awd <thư-mục> <tham-số...> — chạy aw đứng tại <thư-mục>
awd() { _awd=$1; shift; (cd "$_awd" && AW_HOME="$AWHD" AW_ENGINE_DIR="$ROOT" sh "$ROOT/bin/aw" "$@"); }
R9="$TMP/repo9"; mkdir -p "$R9"
git -C "$R9" init -q; git -C "$R9" checkout -q -b main
g9() { git -C "$R9" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
g9 commit -q --allow-empty -m goc
g9 tag khong-co-gi    # base không có gì của quy trình
awd "$R9" init --version "$VDEV" --test-cmd true >/dev/null 2>&1
# Repo mới: aw init tạo quy ước trong repo (chưa commit) — aw đọc bản ở checkout chính.
CV9="$R9/docs/agent-workflow/conventions.md"
ky_vong 6 "checkout chính → ĐANG Ở CHECKOUT CHÍNH (worktree bắt buộc)" awd "$R9" feature
ky_vong 6 "…kể cả khi có tham số" awd "$R9" feature feat_abc
dung "…và in danh sách việc cần làm: mở worktree / chạy /aw-intake" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature 2>&1 | grep -q 'CHECKOUT CHÍNH'"

W4="$TMP/repo9.wt/khong-khop"
g9 worktree add -q -b khong-khop "$W4" main
ky_vong 3 "trong worktree, branch không khớp, không tham số → CẦN HỎI NGƯỜI" awd "$W4" feature
dung "branch không khớp → lấy tham số" test "$(awd "$W4" feature feat_abc 2>/dev/null)" = ".agent-workflow/feat_abc"
ky_vong 2 "từ chối tên feature có ../" awd "$W4" feature "../x"
ky_vong 2 "chữ giữ chỗ <tham-số> của lệnh Cursor chưa thay → TÊN KHÔNG HỢP LỆ" awd "$W4" feature "<tham-số>"
ky_vong 2 "chữ giữ chỗ \$ARGUMENTS chưa thay → TÊN KHÔNG HỢP LỆ" awd "$W4" feature '$ARGUMENTS'
dung "…không tạo thư mục việc nào" test ! -e "$W4/.agent-workflow/<tham-số>"
dung "…stderr bảo agent chép nguyên văn phần người gõ" sh -c "cd '$W4' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature '<tham-số>' 2>&1 | grep -q 'chữ giữ chỗ'"
git -C "$W4" checkout -q -b feat_them-todo
dung "branch khớp quy ước → tên branch đầy đủ" test "$(awd "$W4" feature 2>/dev/null)" = ".agent-workflow/feat_them-todo"
dung "branch khớp thì thắng tham số" test "$(awd "$W4" feature khac 2>/dev/null)" = ".agent-workflow/feat_them-todo"
dung "in 'Đang làm với:'" sh -c "cd '$W4' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature 2>&1 >/dev/null | grep -q 'Đang làm với: .agent-workflow/feat_them-todo'"
g9 worktree remove --force "$W4"

# ---------------------------------------------------------------- tao worktree (/aw-intake)
echo ""
echo "aw worktree new (worktree-new.sh)"
thay "$CV9" 'release_branches:' 'release_branches: release/*'
g9 branch release/1.2
DX=$(awd "$R9" worktree new bugfix phi-hoan-tien 2>/dev/null)
dung "đề xuất tên theo tiền tố của loại việc" sh -c "printf '%s' \"\$1\" | grep -q 'Tên        fix_phi-hoan-tien'" _ "$DX"
dung "…đường dẫn theo worktree_dir (ngoài repo)" sh -c "printf '%s' \"\$1\" | grep -qF '$TMP/repo9.wt/fix_phi-hoan-tien'" _ "$DX"
dung "…liệt kê nhánh phát hành làm ứng viên base" sh -c "printf '%s' \"\$1\" | grep -q 'release/1.2'" _ "$DX"
dung "…gợi ý ★ base_branch khi không có remote" sh -c "printf '%s' \"\$1\" | grep -q '★ \[1\] main'" _ "$DX"
dung "…không còn đòi base có bộ cài" sh -c "! printf '%s' \"\$1\" | grep -q 'bộ cài'" _ "$DX"
dung "…lệnh tạo in bằng aw, cờ tiếng Anh" sh -c "printf '%s' \"\$1\" | grep -q 'aw worktree new bugfix phi-hoan-tien --create --base <ref>'" _ "$DX"
dung "…chỉ đề xuất: chưa tạo branch, chưa tạo worktree" sh -c "! git -C '$R9' rev-parse --verify --quiet refs/heads/fix_phi-hoan-tien && [ ! -e '$TMP/repo9.wt/fix_phi-hoan-tien' ]"
ky_vong 2 "từ chối loại việc không có tiền tố" awd "$R9" worktree new utils x
ky_vong 2 "từ chối mô tả không phải chữ thường ASCII" awd "$R9" worktree new bugfix "Phi Hoan"
ky_vong 2 "--create thiếu --base → từ chối (agent không tự chọn base)" awd "$R9" worktree new bugfix phi-hoan-tien --create
ky_vong 2 "--base không kèm --create → từ chối" awd "$R9" worktree new bugfix phi-hoan-tien --base main
ky_vong 2 "từ chối ref không tồn tại" awd "$R9" worktree new bugfix phi-hoan-tien --create --base khong-co
AW_WORKTREE_DIR='.worktrees/{ten}' ky_vong 2 "từ chối worktree nằm trong repo" awd "$R9" worktree new bugfix phi-hoan-tien
dung "AW_WORKTREE_DIR ghi đè vị trí theo máy" sh -c "cd '$R9' && AW_WORKTREE_DIR='$TMP/rieng/{repo}/{ten}' AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new bugfix phi-hoan-tien 2>/dev/null | grep -qF '$TMP/rieng/repo9/fix_phi-hoan-tien'"

GOC9=$(git -C "$R9" rev-parse main)
ky_vong 0 "base không có gì của quy trình vẫn tạo được worktree" awd "$R9" worktree new chore khong-bo-cai --create --base khong-co-gi
W0="$TMP/repo9.wt/chore_khong-bo-cai"
dung "…worktree mới có adapter sinh sẵn" test -f "$W0/.claude/commands/aw-spec.md"
dung "…file adapter bị exclude: worktree sạch" sh -c "[ -z \"\$(git -C '$W0' status --porcelain)\" ]"
dung "…artifact viết vào cũng bị exclude" sh -c "mkdir -p '$W0/.agent-workflow/chore_khong-bo-cai' && printf x > '$W0/.agent-workflow/chore_khong-bo-cai/intake.md' && [ -z \"\$(git -C '$W0' status --porcelain)\" ]"
dung "…không có commit nào vào base; checkout chính chỉ còn quy ước chờ commit" sh -c "[ \"\$(git -C '$R9' rev-parse main)\" = '$GOC9' ] && [ \"\$(git -C '$R9' status --porcelain --untracked-files=all)\" = '?? docs/agent-workflow/conventions.md' ]"
ky_vong 0 "--create --base <ref người chọn> thì tạo worktree" awd "$R9" worktree new bugfix phi-hoan-tien --create --base main
W5="$TMP/repo9.wt/fix_phi-hoan-tien"
dung "…worktree ở đúng chỗ, đúng branch" test "$(git -C "$W5" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "fix_phi-hoan-tien"
dung "…branch không có upstream (git push trơn không đẩy lên nhánh gốc)" sh -c "! git -C '$W5' rev-parse --abbrev-ref '@{upstream}' 2>/dev/null"
dung "…checkout chính vẫn đứng ở main" test "$(git -C "$R9" rev-parse --abbrev-ref HEAD)" = "main"
dung "…in dòng Base và Engine để chép vào intake.md" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new chore in-base --create --base main 2>&1 >/dev/null | grep -q '\*\*Base:\*\* \`main\` @ \`' && git -C '$R9' worktree list | grep -q chore_in-base"
dung "…dòng Engine đúng version engine" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new chore in-engine --create --base main 2>&1 >/dev/null | grep -qx '  - \*\*Engine:\*\* $VDEV'"
dung "…stdout chỉ là đường dẫn worktree" bang "$(awd "$R9" worktree new chore in-stdout --create --base main 2>/dev/null)" "$TMP/repo9.wt/chore_in-stdout"
dung "…và aw feature trong worktree suy được feature" test "$(awd "$W5" feature 2>/dev/null)" = ".agent-workflow/fix_phi-hoan-tien"
ky_vong 5 "chạy lại cho việc đã có worktree → ĐÃ CÓ WORKTREE, không tạo gì" awd "$R9" worktree new bugfix phi-hoan-tien
dung "…stdout là đường dẫn worktree đã có" test "$(awd "$R9" worktree new bugfix phi-hoan-tien 2>/dev/null)" = "$W5"

# remote: main local chậm hơn origin/main -> ★ origin/main
RM="$TMP/remote9.git"; git init -q --bare "$RM"
g9 remote add origin "$RM"; g9 push -q origin main
KH="$TMP/khac9"; git clone -q -b main "$RM" "$KH" 2>/dev/null
git -C "$KH" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "cua dong nghiep" && git -C "$KH" push -q origin HEAD:main 2>/dev/null
g9 fetch -q origin
DX=$(awd "$R9" worktree new feature co-remote 2>/dev/null)
dung "main chậm origin/main → ★ gợi ý origin/main" sh -c "printf '%s' \"\$1\" | grep -q '★ \[2\] origin/main'" _ "$DX"
dung "…và ghi rõ main chậm bao nhiêu commit" sh -c "printf '%s' \"\$1\" | grep -q 'chậm 1 commit so với origin/main'" _ "$DX"
g9 commit -q --allow-empty -m "local chua push"
DX=$(awd "$R9" worktree new feature co-remote 2>/dev/null)
dung "main và origin/main phân kỳ → không gợi ý ★" sh -c "printf '%s' \"\$1\" | grep -q 'PHÂN KỲ' && ! printf '%s' \"\$1\" | grep -q '★ \['" _ "$DX"
g9 reset -q --hard HEAD~1

# ---------------------------------------------------------------- nhiều adapter
# Team dùng cả Claude Code lẫn Cursor: ADAPTER="claude-code cursor" trong config.sh.
echo ""
echo "nhiều adapter (ADAPTER=\"claude-code cursor\")"
R10="$TMP/repo10"; mkdir -p "$R10"
git -C "$R10" init -q; git -C "$R10" checkout -q -b main
git -C "$R10" -c user.name=t -c user.email=t@t commit -q --allow-empty -m goc
GOC10=$(git -C "$R10" rev-parse HEAD); C10="$R10/.git/agent-workflow"
ky_vong 2 "init --adapter có id không tồn tại → SAI THAM SỐ" awd "$R10" init --version "$VDEV" --adapter claude-code,khong-co
dung "…không ghi config.sh, không sinh gì" sh -c "[ ! -e '$C10/config.sh' ] && [ ! -e '$R10/.claude' ] && [ ! -e '$R10/.cursor' ]"
ky_vong 2 "init --adapter rỗng → SAI THAM SỐ" awd "$R10" init --version "$VDEV" --adapter ","
ky_vong 0 "aw init --adapter claude-code,cursor" awd "$R10" init --version "$VDEV" --test-cmd true --adapter claude-code,cursor
dung "…config.sh ghi ADAPTER=\"claude-code cursor\"" grep -qx 'ADAPTER="claude-code cursor"' "$C10/config.sh"
dung "…exclude có đường dẫn của MỌI adapter" sh -c \
  "for p in /.agent-workflow/ /.claude/ /.cursor/commands/ /.cursor/agents/ /.cursor/skills/agent-workflow/; do grep -qxF \"\$p\" '$R10/.git/info/exclude' || exit 1; done"
dung "…sinh cả hai bộ ở checkout chính" sh -c "[ -f '$R10/.claude/commands/aw-intake.md' ] && [ -f '$R10/.cursor/commands/aw-intake.md' ] && [ -f '$R10/.cursor/agents/independent-reviewer.md' ]"
dung "…cả hai bộ giống hệt build riêng (không ảnh hưởng nhau)" sh -c "diff -r '$R10/.claude' '$TMP/doi-chieu-that/claude-code/.claude' && diff -r '$R10/.cursor' '$TMP/doi-chieu-that/cursor/.cursor'"
dung "…dấu build ghi cả hai, đúng version" bang "$(cat "$R10/.agent-workflow/.adapters")" "claude-code $VDEV
cursor $VDEV"
dung "…không commit gì; cây chỉ còn quy ước chờ commit" sh -c "[ \"\$(git -C '$R10' rev-parse HEAD)\" = '$GOC10' ] && [ \"\$(git -C '$R10' status --porcelain --untracked-files=all)\" = '?? docs/agent-workflow/conventions.md' ]"
ky_vong 0 "init lại: cùng tập adapter, khác thứ tự/cách viết → không coi là đổi" awd "$R10" init --adapter "cursor claude-code"
dung "…không nhân đôi dòng exclude" bang "$(grep -cxF '/.cursor/agents/' "$R10/.git/info/exclude")" 1
ky_vong 2 "init --adapter khác tập trong config.sh → SAI THAM SỐ (sửa config.sh)" awd "$R10" init --adapter cursor
dung "…config.sh giữ nguyên" grep -qx 'ADAPTER="claude-code cursor"' "$C10/config.sh"
ky_vong 0 "aw doctor: mọi mục ✓ với hai adapter" awd "$R10" doctor
dung "…liệt kê từng adapter của worktree" sh -c "cd '$R10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor 2>/dev/null | grep -q '✓ cursor (engine $VDEV)'"

W10=$(awd "$R10" worktree new feature hai-agent --create --base main 2>/dev/null)
dung "worktree mới có cả .claude/ và .cursor/" sh -c "[ -n '$W10' ] && [ -f '$W10/.claude/commands/aw-spec.md' ] && [ -f '$W10/.cursor/commands/aw-spec.md' ]"
dung "…giống hệt build riêng" sh -c "diff -r '$W10/.claude' '$TMP/doi-chieu-that/claude-code/.claude' && diff -r '$W10/.cursor' '$TMP/doi-chieu-that/cursor/.cursor'"
dung "…worktree sạch (mọi file sinh ra bị exclude)" sh -c "[ -z \"\$(git -C '$W10' status --porcelain --untracked-files=all)\" ]"
dung "…dấu build của worktree có cả hai" sh -c "grep -q '^claude-code ' '$W10/.agent-workflow/.adapters' && grep -q '^cursor ' '$W10/.agent-workflow/.adapters'"
dung "…aw feature trong worktree suy được feature (cả hai agent dùng chung)" test "$(awd "$W10" feature 2>/dev/null)" = ".agent-workflow/feat_hai-agent"

# doctor thấy worktree thiếu bộ lệnh của một agent
awk '$1 != "cursor"' "$W10/.agent-workflow/.adapters" > "$TMP/dau.tmp" && mv "$TMP/dau.tmp" "$W10/.agent-workflow/.adapters"
ky_vong 1 "doctor: worktree chưa sinh adapter cursor → ✗" awd "$W10" doctor
dung "…chỉ đúng adapter thiếu và lệnh sửa" sh -c "cd '$W10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor 2>/dev/null | grep -q '✗ cursor chưa được sinh — chạy: aw adapter build'"
ky_vong 0 "aw adapter build cursor (một adapter)" awd "$W10" adapter build cursor
dung "…dấu build giữ dòng claude-code, thêm lại cursor (đúng hai dòng)" sh -c \
  "[ \"\$(wc -l < '$W10/.agent-workflow/.adapters' | tr -d ' ')\" = 2 ] && grep -q '^claude-code ' '$W10/.agent-workflow/.adapters' && grep -q '^cursor ' '$W10/.agent-workflow/.adapters'"
ky_vong 0 "doctor lại ✓" awd "$W10" doctor
sed 's/^claude-code .*/claude-code 2000.1.1/' "$W10/.agent-workflow/.adapters" > "$TMP/dau.tmp" && mv "$TMP/dau.tmp" "$W10/.agent-workflow/.adapters"
ky_vong 0 "doctor: bộ lệnh sinh từ engine khác chỉ là thông tin (việc có thể ghim engine cũ)" awd "$W10" doctor
dung "…nói rõ version của bộ lệnh và của bản clone" sh -c "cd '$W10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor 2>/dev/null | grep -q 'claude-code sinh từ engine 2000.1.1, bản clone dùng $VDEV'"
rm -rf "$W10/.cursor" "$W10/.claude"
ky_vong 0 "aw adapter build (không id) → mọi adapter trong config.sh" awd "$W10" adapter build
dung "…sinh lại cả hai, dấu build đúng version" sh -c "[ -f '$W10/.claude/commands/aw-plan.md' ] && [ -f '$W10/.cursor/commands/aw-plan.md' ] && [ \"\$(cat '$W10/.agent-workflow/.adapters')\" = 'claude-code $VDEV
cursor $VDEV' ]"
rm -rf "$W10/.cursor"
ky_vong 2 "aw adapter build claude-code,khong-co → SAI THAM SỐ" awd "$W10" adapter build claude-code,khong-co
dung "…không sinh adapter nào" test ! -e "$W10/.cursor"
awd "$W10" adapter build >/dev/null 2>&1
rm -f "$W10/.agent-workflow/.adapters"
ky_vong 0 "doctor: worktree tạo bằng engine cũ (chưa có dấu build) → chỉ nhắc, không ✗" awd "$W10" doctor
awd "$W10" adapter build >/dev/null 2>&1

# config.sh do NGƯỜI sửa: dấu phẩy, id sai, bỏ trống
cp "$C10/config.sh" "$TMP/config10.bak"
sed 's/^ADAPTER=.*/ADAPTER="cursor,claude-code"/' "$TMP/config10.bak" > "$C10/config.sh"
W11=$(awd "$R10" worktree new chore dau-phay --create --base main 2>/dev/null)
dung "ADAPTER viết bằng dấu phẩy → worktree có cả hai bộ" sh -c "[ -f '$W11/.claude/commands/aw-spec.md' ] && [ -f '$W11/.cursor/commands/aw-spec.md' ]"
sed 's/^ADAPTER=.*/ADAPTER=""/' "$TMP/config10.bak" > "$C10/config.sh"
W12=$(awd "$R10" worktree new chore bo-trong --create --base main 2>/dev/null)
dung "ADAPTER bỏ trống → chỉ claude-code (như trước khi có nhiều adapter)" sh -c "[ -f '$W12/.claude/commands/aw-spec.md' ] && [ ! -e '$W12/.cursor' ]"
sed 's/^ADAPTER=.*/ADAPTER="claude-code khong-co"/' "$TMP/config10.bak" > "$C10/config.sh"
ky_vong 0 "ADAPTER có id sai → worktree vẫn tạo được" awd "$R10" worktree new chore id-sai --create --base main
dung "…nhưng cảnh báo rõ, không sinh nửa vời" sh -c "cd '$R10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new chore id-sai-2 --create --base main 2>&1 >/dev/null | grep -q 'CẢNH BÁO: ADAPTER=\"claude-code khong-co\"' && [ ! -e '$TMP/repo10.wt/chore_id-sai-2/.claude' ]"
ky_vong 1 "doctor: ADAPTER khai id engine không có → ✗" awd "$R10" doctor
cp "$TMP/config10.bak" "$C10/config.sh"
dung "…sửa lại thì doctor ✓" sh -c "cd '$R10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor >/dev/null 2>&1"

# ---------------------------------------------------------------- don worktree
echo ""
echo "aw worktree status|remove (worktree-cleanup.sh)"
ky_vong 0 "status: chỉ in trạng thái" awd "$R9" worktree status fix_phi-hoan-tien
dung "…worktree còn nguyên" test -d "$W5"
printf 'nhap\n' > "$W5/nhap.txt"
ky_vong 7 "còn file chưa track → chặn remove" awd "$R9" worktree remove fix_phi-hoan-tien
dung "…worktree còn nguyên" test -f "$W5/nhap.txt"
rm -f "$W5/nhap.txt"
ky_vong 7 "đứng trong chính worktree cần dọn → chặn" awd "$W5" worktree remove fix_phi-hoan-tien
ky_vong 2 "--delete-branch với status → sai tham số" awd "$R9" worktree status fix_phi-hoan-tien --delete-branch
ky_vong 2 "branch không có worktree → sai tham số" awd "$R9" worktree status release/1.2
mkdir -p "$W5/.agent-workflow/fix_phi-hoan-tien"; printf 'artifact\n' > "$W5/.agent-workflow/fix_phi-hoan-tien/spec.md"
dung "status báo sẽ chép artifact vào archive" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree status fix_phi-hoan-tien 2>/dev/null | grep -q 'archive/fix_phi-hoan-tien'"
git -C "$W5" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "sua phi"
ky_vong 7 "chưa merge: gỡ worktree nhưng git từ chối xoá branch" awd "$R9" worktree remove fix_phi-hoan-tien --delete-branch
dung "…worktree đã gỡ, branch còn nguyên (không mất commit)" sh -c "[ ! -e '$W5' ] && git -C '$R9' rev-parse --verify --quiet refs/heads/fix_phi-hoan-tien"
dung "…artifact (bị exclude) được chép vào .git/agent-workflow/archive/ trước khi gỡ" grep -qx artifact "$R9/.git/agent-workflow/archive/fix_phi-hoan-tien/fix_phi-hoan-tien/spec.md"
W6="$TMP/repo9.wt/chore_in-base"
ky_vong 0 "đã merge: remove --delete-branch gỡ worktree và xoá branch" awd "$R9" worktree remove chore_in-base --delete-branch
dung "…cả worktree lẫn branch đều không còn" sh -c "[ ! -e '$W6' ] && ! git -C '$R9' rev-parse --verify --quiet refs/heads/chore_in-base"

IN="$R9/.claude/commands/aw-intake.md"
dung "/aw-intake: tham số là input, không truyền vào aw feature" sh -c "grep -q 'argument-hint: \"\\[mã-issue' '$IN' && ! grep -q 'aw feature \$ARGUMENTS' '$IN'"
dung "/aw-intake: đang ở checkout chính thì dẫn tới aw worktree new" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*aw worktree new' "$IN"
dung "lệnh khác: ĐANG Ở CHECKOUT CHÍNH thì dừng lại" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*stop' "$R9/.claude/commands/aw-spec.md"
dung "lệnh khác vẫn nhận tên feature qua tham số" grep -q 'aw feature \$ARGUMENTS' "$R9/.claude/commands/aw-spec.md"
dung "/aw-intake: tham số đi qua aw input bằng heredoc nguyên văn" sh -c "grep -q 'aw input .*- <<' '$IN' && grep -qx '\$ARGUMENTS' '$IN'"
dung "aw init chép rules/templates/checkers của engine vào .agent-workflow/.engine/ (bị exclude)" sh -c "[ -f '$R9/.agent-workflow/.engine/templates/spec.md' ] && [ -f '$R9/.agent-workflow/.engine/rules/general.md' ] && grep -qx '$VDEV' '$R9/.agent-workflow/.engine/VERSION'"
dung "…conventions.md trong đó trỏ tới cấu hình của bản clone" sh -c "grep -q '^branch_patterns:' '$R9/.agent-workflow/.engine/conventions.md'"
dung "mọi đường dẫn .agent-workflow/.engine/… mà lệnh sinh ra nhắc tới đều có thật" sh -c "cd '$R9' && for p in \$(grep -rhoE '\.agent-workflow/\.engine/[A-Za-z0-9_./-]+\.md' .claude | sort -u); do [ -e \"\$p\" ] || { echo \$p; exit 1; }; done"

# ---------------------------------------------------------------- phan loai input (/aw-intake)
echo ""
echo "aw input (input.sh)"
mkdir -p "$R9/docs"; printf 'x\n' > "$R9/docs/a.md"
# ra <tham-số...> -> stdout; loi <tham-số...> -> stderr
ra() { awd "$R9" input "$@" 2>/dev/null; }
loi() { awd "$R9" input "$@" 2>&1 >/dev/null; }
pl() { awd "$R9" input "$@"; }
BT='`'

ky_vong 0 "mã Jira + file có thật → nguồn" pl "ABC-123 docs/a.md"
dung "…đúng nhãn [JIRA] và [FILE]" bang "$(ra 'ABC-123 docs/a.md')" "- ${BT}[JIRA]${BT} ABC-123
- ${BT}[FILE]${BT} docs/a.md"
dung "URL …/browse/<mã> → [JIRA] với mã tách ra" bang "$(ra 'https://x.atlassian.net/browse/ABC-9')" "- ${BT}[JIRA]${BT} ABC-9 — https://x.atlassian.net/browse/ABC-9"
dung "chưa khai confluence_domains: URL khác → [CONFLUENCE]" bang "$(ra 'https://wiki.co/p/1')" "- ${BT}[CONFLUENCE]${BT} https://wiki.co/p/1"
dung "…kèm cảnh báo chưa khai confluence_domains" sh -c "printf '%s' \"\$1\" | grep -q confluence_domains" _ "$(loi 'https://wiki.co/p/1')"
dung "bỏ dấu câu / ngoặc bọc ngoài: (ABC-1), \`docs/a.md\`" bang "$(ra '(ABC-1), `docs/a.md`.')" "- ${BT}[JIRA]${BT} ABC-1
- ${BT}[FILE]${BT} docs/a.md"
dung "cùng một nguồn gõ nhiều cách → một dòng" bang "$(ra 'ABC-1 ABC-1 https://x.atlassian.net/browse/ABC-1' | wc -l | tr -d ' ')" 1
ky_vong 1 "đường dẫn không tồn tại → ĐƯỜNG DẪN KHÔNG TỒN TẠI (không tự đoán)" pl "ABC-1 docs/khong-co.md"
dung "…và không in dòng input nào" test -z "$(ra 'ABC-1 docs/khong-co.md')"
ky_vong 3 "không có tham số → KHÔNG CÓ THAM SỐ (hỏi người dùng)" pl ""
ky_vong 3 "tham số chỉ có khoảng trắng / dòng trống → KHÔNG CÓ THAM SỐ" pl "
  "
ky_vong 4 "câu chữ tự do → LỜI NGƯỜI DÙNG" pl "sửa phí hoàn tiền bị âm ABC-123"
ky_vong 2 "chữ giữ chỗ <tham-số> còn nguyên → SAI CÁCH GỌI (không thành mục [HUMAN])" pl "<tham-số>"
ky_vong 2 "chữ giữ chỗ \$ARGUMENTS còn nguyên → SAI CÁCH GỌI" pl '$ARGUMENTS'
ky_vong 2 "…kể cả có khoảng trắng / dòng trống bao quanh" pl "
  <tham-số>
"
dung "…và không in dòng input nào" test -z "$(ra '<tham-số>')"
ky_vong 4 "câu thật có nhắc chữ <tham-số> vẫn là LỜI NGƯỜI DÙNG" pl "sửa lỗi hiển thị <tham-số> trong trang"
# Chạy NGUYÊN VĂN khối aw input do adapter sinh ra, như agent quên thay tham số
for ad in claude-code cursor; do
  case $ad in claude-code) f="$TMP/doi-chieu-that/claude-code/.claude/commands/aw-intake.md" ;; *) f="$TMP/doi-chieu-that/cursor/.cursor/commands/aw-intake.md" ;; esac
  awk '/^```sh$/ { k = 1; next } k && /^```$/ { exit } k' "$f" | sed 's/^aw input \[--skip [^]]*\] /aw input /' > "$TMP/khoi-input-$ad.sh"
  dung "$ad: khối aw input trong /aw-intake là lệnh chạy được (có heredoc HET_INPUT)" sh -c "grep -q '^aw input - <<.HET_INPUT.\$' '$TMP/khoi-input-$ad.sh' && tail -1 '$TMP/khoi-input-$ad.sh' | grep -qx HET_INPUT"
  ky_vong 2 "$ad: chạy khối đó khi chưa thay tham số → engine chặn (SAI CÁCH GỌI)" sh -c "cd '$R9' && aw() { AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' \"\$@\"; } && . '$TMP/khoi-input-$ad.sh'"
  sed 's/^<tham-số>$/ABC-123/; s/^\$ARGUMENTS$/ABC-123/' "$TMP/khoi-input-$ad.sh" > "$TMP/khoi-input-$ad-thay.sh"
  dung "$ad: …thay đúng tham số thì ra nhãn [JIRA]" sh -c "cd '$R9' && aw() { AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' \"\$@\"; } && . '$TMP/khoi-input-$ad-thay.sh' 2>/dev/null | grep -q 'JIRA.* ABC-123'"
done
dung "…cả chuỗi là MỘT mục [HUMAN] nguyên văn" bang "$(ra 'sửa phí hoàn tiền bị âm ABC-123')" "- ${BT}[HUMAN]${BT}
  > sửa phí hoàn tiền bị âm ABC-123"
dung "…mã Jira trong câu chỉ là ĐỀ XUẤT (stderr)" sh -c "printf '%s\n' \"\$1\" | grep -A3 'Đề xuất tách thêm' | grep -q 'ABC-123'" _ "$(loi 'sửa phí hoàn tiền bị âm ABC-123')"
ky_vong 4 "đường dẫn không có file nằm trong câu chữ thì không chặn" pl "sửa lỗi trong src/khong-co.js"

cp "$CV9" "$TMP/conv.bak"
sed 's#^confluence_domains:.*#confluence_domains: *.atlassian.net/wiki#' "$TMP/conv.bak" > "$CV9"
dung "khai confluence_domains: URL khớp → [CONFLUENCE]" bang "$(ra 'https://x.atlassian.net/wiki/spaces/A/pages/1')" "- ${BT}[CONFLUENCE]${BT} https://x.atlassian.net/wiki/spaces/A/pages/1"
ky_vong 4 "khai confluence_domains: URL lạ → lời người dùng" pl "https://github.com/a/b"
ky_vong 4 "khai confluence_domains: miền giả mạo x.atlassian.net.evil.com → không nhận" pl "https://x.atlassian.net.evil.com/wiki/p/1"
dung "khai confluence_domains: URL có query vẫn khớp" bang "$(ra 'https://x.atlassian.net/wiki?p=1')" "- ${BT}[CONFLUENCE]${BT} https://x.atlassian.net/wiki?p=1"
printf '%s\n' '```conventions' 'branch_patterns: feat_*' '```' > "$CV9"
ky_vong 0 "conventions.md cũ chưa có jira_key_regex → dùng mặc định" pl "ABC-1"
cp "$TMP/conv.bak" "$CV9"

# nguyen van qua stdin: dau nhay, $, backtick, nhieu dong khong bi shell dien giai
awd "$R9" input - > "$TMP/nv.out" 2>/dev/null <<'HET_INPUT'

Sửa "phí" khi $amount < 0 — xem `x`
dòng hai
HET_INPUT
dung "stdin: nguyên văn giữ dấu nháy, \$, backtick, nhiều dòng" bang "$(cat "$TMP/nv.out")" "- ${BT}[HUMAN]${BT}
  > Sửa \"phí\" khi \$amount < 0 — xem ${BT}x${BT}
  > dòng hai"

# --skip: chay lai /aw-intake = gop them
cat > "$TMP/intake-cu.md" <<'HET'
- **Type:** `feature`
- **Goal:** x

## Input

- `[JIRA]` [ABC-123](https://x.atlassian.net/browse/ABC-123)
- `[FILE]` ./docs/a.md
- `[HUMAN]`
  > sửa phí   hoàn tiền
  > bị âm
HET
dung "--skip: bỏ input đã có, chỉ in input mới" bang "$(ra --skip "$TMP/intake-cu.md" 'ABC-123 docs/a.md ABC-7')" "- ${BT}[JIRA]${BT} ABC-7"
ky_vong 0 "--skip: không có gì mới vẫn là NGUỒN" pl --skip "$TMP/intake-cu.md" "https://x.atlassian.net/browse/ABC-123"
dung "…URL …/browse/ABC-123 trùng với ABC-123 đã có → stdout rỗng" test -z "$(ra --skip "$TMP/intake-cu.md" 'https://x.atlassian.net/browse/ABC-123')"
dung "--skip: lời người dùng đã có (khác khoảng trắng / xuống dòng) → bỏ" test -z "$(ra --skip "$TMP/intake-cu.md" 'sửa phí hoàn tiền bị âm')"
dung "--skip: lời người dùng mới thì vẫn in" bang "$(ra --skip "$TMP/intake-cu.md" 'thêm xuất CSV' | tail -1)" "  > thêm xuất CSV"
ky_vong 2 "--skip trỏ tới file không có → SAI CÁCH GỌI" pl --skip "$TMP/khong-co.md" "ABC-1"

# ---------------------------------------------------------------- muc dich (00)
echo ""
echo "check-intake.sh"
CHK="$T/check-intake.sh"
tao_fixture feature feat_x

ky_vong 0 "tiếp nhận hợp lệ thì cho qua" sh "$CHK" "$F"

thay "$F/intake.md" '`feature`' '`utils`'
ky_vong 1 "chặn loại việc ngoài 5 loại" sh "$CHK" "$F"
ky_vong 1 "spec chặn khi intake.md không đạt (entry check)" sh "$T/check-spec.sh" "$F"
viet_intake

thay "$F/intake.md" '- **Goal:** làm x' '- **Goal:** <một câu>'
ky_vong 1 "chặn mục tiêu còn chỗ giữ chỗ" sh "$CHK" "$F"
viet_intake

thay "$F/intake.md" '- `[JIRA]` ABC-1
- `[HUMAN]`
  > cần làm x cho màn hình y
' ''
ky_vong 1 "chặn khi không có input nào" sh "$CHK" "$F"
viet_intake

thay "$F/intake.md" '`[JIRA]` ABC-1' '`[INFERRED]` chắc người dùng muốn x'
ky_vong 1 "chặn [INFERRED] trong input" sh "$CHK" "$F"
viet_intake

thay "$F/intake.md" '  > cần làm x cho màn hình y' ''
ky_vong 1 "chặn [HUMAN] không kèm nguyên văn" sh "$CHK" "$F"
viet_intake

rm -f "$F/intake.md"
ky_vong 2 "chặn khi chưa có intake.md" sh "$CHK" "$F"
viet_intake

# mau chua sua: dong input vi du khong duoc thanh mot nguon gia
cp "$ROOT/workflow/templates/intake.md" "$F/intake.md"
thay "$F/intake.md" '`<feature | bugfix | refactor | perf | chore>`' '`feature`'
thay "$F/intake.md" '<một câu>' 'làm x'
thay "$F/intake.md" '  > <chép nguyên văn lời người dùng>' '  > cần làm x'
ky_vong 1 "chặn dòng input mẫu chưa sửa (nguồn giả)" sh "$CHK" "$F"
dung "…đúng lý do: chỗ giữ chỗ" sh -c "sh '$CHK' '$F' | grep -q 'chỗ giữ chỗ'"
viet_intake

thay "$F/intake.md" '`[JIRA]` ABC-1' '`[JIRA]` abc'
ky_vong 1 "chặn [JIRA] không có mã khớp jira_key_regex" sh "$CHK" "$F"
viet_intake
thay "$F/intake.md" '`[JIRA]` ABC-1' '`[JIRA]` [ABC-1](https://x.atlassian.net/browse/ABC-1)'
ky_vong 0 "[JIRA] dạng link markdown có mã thì cho qua" sh "$CHK" "$F"
viet_intake

# spec ghi based_on intake.md: gop them input -> spec loi thoi, review chan
sh "$T/based-on.sh" "$F" spec.md intake.md >/dev/null
ky_vong 0 "spec ghi based_on intake.md vẫn qua check-spec" sh "$T/check-spec.sh" "$F"
printf -- '- `[JIRA]` ABC-2\n' >> "$F/intake.md"
ky_vong 1 "gộp thêm input sau khi có spec → review chặn (spec lỗi thời)" sh "$T/check-review.sh" "$F"
dung "…đúng lý do: spec.md lỗi thời vì intake.md" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'spec.md: lỗi thời — intake.md'"
viet_intake; viet_spec

thay "$F/intake.md" '`feature`' '`chore`'
ky_vong 0 "loại lệch tiền tố branch chỉ CẢNH BÁO ở /aw-intake" sh "$CHK" "$F"
dung "…và có in cảnh báo lệch tiền tố" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*feat_'"
viet_intake

# Base: dong do worktree-new.sh in ra, checker phia sau so diff voi no
SHA_MAIN=$(git -C "$R" rev-parse --short main)
thay "$F/intake.md" "- **Base:** \`main\` @ \`$SHA_MAIN\`
" ''
ky_vong 1 "chặn khi thiếu dòng Base" sh "$CHK" "$F"
dung "…đúng lý do: thiếu Base" sh -c "sh '$CHK' '$F' | grep -q 'Thiếu dòng .*Base'"
viet_intake
thay "$F/intake.md" "@ \`$SHA_MAIN\`" '@ `khongphaisha`'
ky_vong 1 "chặn Base có sha không phải commit" sh "$CHK" "$F"
viet_intake
g checkout -q -b nhanh-khac main; g commit -q --allow-empty -m khac; SHA_KHAC=$(git -C "$R" rev-parse --short HEAD); g checkout -q feat_x
thay "$F/intake.md" "@ \`$SHA_MAIN\`" "@ \`$SHA_KHAC\`"
ky_vong 1 "chặn Base có sha không phải tổ tiên của HEAD" sh "$CHK" "$F"
viet_intake
thay "$F/intake.md" "\`main\` @" '`da-xoa` @'
ky_vong 0 "ref của Base không còn nhưng sha đúng → chỉ cảnh báo" sh "$CHK" "$F"
dung "…và có in cảnh báo ref không còn" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*da-xoa.*không còn'"
viet_intake

# Base khac nhanh goc: so voi main thi commit cua nguoi khac bi tinh cho viec nay
g checkout -q -b moi-hon main
printf 'x\n' > "$R/docs/cua-nguoi-khac.txt"; g add docs/cua-nguoi-khac.txt; g commit -q -m "cua nguoi khac"
g checkout -q feat_x; g merge -q --no-edit moi-hon
ky_vong 1 "base ghi main mà branch tạo từ bản mới hơn → review thấy file của người khác" sh "$T/check-review.sh" "$F"
dung "…đúng lý do: file của người khác bị tính ngoài phạm vi" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'docs/cua-nguoi-khac.txt: thay đổi ngoài phạm vi'"
SHA_MH=$(git -C "$R" rev-parse --short moi-hon)
thay "$F/intake.md" "\`main\` @ \`$SHA_MAIN\`" "\`moi-hon\` @ \`$SHA_MH\`"
ghi_based_on
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review
ky_vong 0 "ghi đúng base → diff chỉ còn việc của mình, review cho qua" sh "$T/check-review.sh" "$F"
dung "…nhưng base lạ (xếp chồng) thì review CẢNH BÁO" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'CẢNH BÁO.*Base \"moi-hon\"'"
thay "$CFG/conventions.md" 'release_branches:' 'release_branches: moi-*'
dung "base khớp release_branches → không cảnh báo" sh -c "! sh '$T/check-review.sh' '$F' | grep -q 'CẢNH BÁO.*Base'"
thay "$CFG/conventions.md" 'release_branches: moi-*' 'release_branches:'

# ---------------------------------------------------------------- bugfix
echo ""
echo "loại việc: bugfix"
tao_fixture bugfix fix_y
for c in intake spec design plan implement review; do
  ky_vong 0 "bugfix đầy đủ qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done
dung "repro.md ghi output THẬT, mã thoát khác 0" sh -c "grep -q 'Mã thoát: \`1\`' '$F/repro.md'"

ky_vong 1 "check-repro từ chối khi đã sửa code production" sh "$T/check-repro.sh" "$F"
dung "…và giữ nguyên repro.md cũ" grep -q 'Mã thoát: `1`' "$F/repro.md"

thay "$F/spec.md" '- Expected behavior: ra moi' ''
ky_vong 1 "spec bugfix chặn khi thiếu Hành vi đúng" sh "$T/check-spec.sh" "$F"
viet_spec; ghi_based_on

mv "$F/repro.md" "$F/repro.bak"
ky_vong 1 "implement chặn bugfix không có repro.md" sh "$T/check-implement.sh" "$F"
ky_vong 1 "review chặn bugfix không có repro.md" sh "$T/check-review.sh" "$F"
mv "$F/repro.bak" "$F/repro.md"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

viet_review; thay "$F/review.md" '- Repro test fails because: grep không thấy "moi" trong src/a.txt' '- Repro test fails because: <trích>'
ky_vong 1 "review chặn bugfix thiếu \"Test tái hiện đỏ vì\"" sh "$T/check-review.sh" "$F"
viet_review

# test xanh tren code chua sua -> khong tai hien duoc
g stash -q
printf 'TEST_CMD="true"\n%s\n' "$BM_XANH" > "$CFG/config.sh"
ky_vong 1 "check-repro chặn khi test XANH trên code chưa sửa" sh "$T/check-repro.sh" "$F"
dung "…đúng lý do: test xanh, không phải vì đã sửa code" sh -c "sh '$T/check-repro.sh' '$F' | grep -q 'XANH'"

# ---------------------------------------------------------------- refactor
echo ""
echo "loại việc: refactor"
tao_fixture refactor refactor_z
for c in spec design plan implement review; do
  ky_vong 0 "refactor đầy đủ qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done

thay "$F/spec.md" '- Type: `structural`' ''
ky_vong 1 "spec refactor chặn YC không có Loại YC (hành vi mới)" sh "$T/check-spec.sh" "$F"
viet_spec

thay "$F/spec.md" '`test/a.test.js`' '`test/moi.test.js`'
printf '// covers: YC-001\n' > "$R/test/moi.test.js"
ky_vong 1 "spec refactor chặn test bảo vệ không có sẵn trên nhánh gốc" sh "$T/check-spec.sh" "$F"
rm -f "$R/test/moi.test.js"; viet_spec; ghi_based_on

printf '// covers: YC-001, YC-002\n// doi import\n' > "$R/test/a.test.js"
ky_vong 0 "sửa test cũ chưa khai chỉ CẢNH BÁO ở implement" sh "$T/check-implement.sh" "$F"
ky_vong 1 "…nhưng review chặn" sh "$T/check-review.sh" "$F"
thay "$F/plan.md" '| Test file | Reason |
|---|---|
' '| Test file | Reason |
|---|---|
| `test/a.test.js` | đổi import do dời module |
'
ghi_tree_review
ky_vong 0 "khai ở \"Test cũ bị sửa\" thì review cho qua" sh "$T/check-review.sh" "$F"
g checkout -q -- test/a.test.js; viet_plan; ghi_based_on
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review

rm -f "$R/test/a.test.js"
ky_vong 1 "implement chặn refactor XOÁ test cũ" sh "$T/check-implement.sh" "$F"
g checkout -q -- test/a.test.js
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

# ---------------------------------------------------------------- perf
echo ""
echo "loại việc: perf"
tao_fixture perf perf_w
for c in spec design plan implement review; do
  ky_vong 0 "perf đầy đủ qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done
# Mỗi mục "## Trước" / "## Sau" phải có dòng RESULT. Fixture in tên cũ "KET_QUA:" —
# máy vẫn nhận và ghi lại dạng RESULT: (khối output thật vẫn giữ nguyên KET_QUA).
dung "perf.md có số đo trước và sau (lệnh đo in KET_QUA: cũ vẫn nhận)" sh -c "[ \"\$(awk '/^## /{m=\$2} /^RESULT:/ && m!=\"\" && !(m in c) {c[m]=1; n++} END{print n+0}' '$F/perf.md')\" = 2 ]"
ky_vong 1 "đo \"trước\" bị từ chối khi đã sửa code production" sh "$T/check-perf.sh" "$F" --before

thay "$F/spec.md" '- Target: dưới 10 ms' '- Target: nhanh hơn'
ky_vong 1 "spec perf chặn YC hiệu năng không có số liệu" sh "$T/check-spec.sh" "$F"
viet_spec; ghi_based_on

mv "$F/perf.md" "$F/perf.bak"
ky_vong 1 "implement chặn perf không có số đo" sh "$T/check-implement.sh" "$F"
ky_vong 1 "đo \"sau\" bị từ chối khi chưa có số đo trước" sh "$T/check-perf.sh" "$F" --after
mv "$F/perf.bak" "$F/perf.md"

# ---------------------------------------------------------------- gác ô duyệt (hook)
echo ""
echo "guard.sh (aw guard)"
GAC="$T/guard.sh"
co_tick() { grep -q '^- \[x\] \*\*Approved by human' "$F/spec.md"; }
d_tick() { grep -q '^- \[x\] \*\*Approved by human' "$F/tdd.md"; }
viet_spec; viet_tdd
ky_vong 3 "guard sai tham số → SAI THAM SỐ" sh "$GAC" khac

# Người tick (giữa hai lệnh của agent): pre ghi dấu, post để yên
ky_vong 0 "pre luôn cho qua" sh "$GAC" pre
dung "…và ghi dấu duyệt cho ô người đã tick" grep -q 'approval-hash:' "$F/spec.md"
ky_vong 0 "post không đổi gì thì cho qua" sh "$GAC" post
dung "…tick của người còn nguyên" co_tick

# Agent tick trong lúc lệnh chạy: post bỏ tick, báo agent (mã 2)
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'; sh "$GAC" pre >/dev/null 2>&1
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 2 "post chặn agent tick ô duyệt spec" sh "$GAC" post
dung "…và đã bỏ tick" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/spec.md'"
sh "$GAC" pre >/dev/null 2>&1
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
dung "…stderr nói rõ cho agent: không tick lại" sh -c "sh '$GAC' post 2>&1 | grep -q 'Agent KHÔNG tick lại'"

# Agent tick D-xx (kể cả viết cả file mới có sẵn [x])
viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'; sh "$GAC" pre >/dev/null 2>&1
thay "$F/tdd.md" '- [ ] **Approved by human**' '- [x] **Approved by human**'
ky_vong 2 "post chặn agent tick ô duyệt D-xx" sh "$GAC" post
dung "…và đã bỏ tick D" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/tdd.md'"
sh "$GAC" pre >/dev/null 2>&1; viet_tdd
ky_vong 2 "post chặn agent ghi đè cả tdd.md với ô đã tick" sh "$GAC" post

# Agent sửa nội dung đã duyệt mà quên bỏ tick: post bỏ tick
viet_spec; sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
sh "$GAC" pre >/dev/null 2>&1
thay "$F/spec.md" 'mở y thấy a' 'mở y thấy a và c'
ky_vong 2 "post bỏ tick spec bị sửa sau khi duyệt" sh "$GAC" post
dung "…spec giờ chưa tick" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/spec.md'"

# Được phép: agent bỏ tick; agent thêm phản biện dưới D đã duyệt
viet_spec; sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
sh "$GAC" pre >/dev/null 2>&1; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 0 "agent bỏ tick thì cho qua" sh "$GAC" post
dung "…và dấu duyệt thừa bị xoá" sh -c "! grep -q 'dấu duyệt' '$F/spec.md'"
viet_tdd; sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
sh "$GAC" pre >/dev/null 2>&1
thay "$F/tdd.md" '- Choice: file' '- Choice: file
- Critique (agent): cân nhắc DB'
ky_vong 0 "agent thêm phản biện dưới D đã duyệt thì cho qua" sh "$GAC" post
dung "…D vẫn tick" d_tick

# Không có mốc của pre (pre không chạy): post không bỏ tick của ai
viet_spec; rm -f "$R/.agent-workflow/.guard-pre"
ky_vong 0 "post không thấy pre thì không coi tick chưa dấu là của agent" sh "$GAC" post
dung "…tick còn nguyên" co_tick

# Việc mới dùng engine cũ (dạng "Status:") — hook không đụng tới
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- **Status:** `approved`'
sh "$GAC" pre >/dev/null 2>&1
ky_vong 0 "spec dạng cũ: hook không chặn" sh "$GAC" post

# Cursor nạp hook của .claude/settings.json (tương thích, bật sẵn) VÀ của
# .cursor/hooks.json: một lệnh của agent có thể chạy aw guard hai lần. Phải vô hại.
viet_spec; sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" pre >/dev/null 2>&1
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 2 "hook chạy hai lần (pre pre · agent tick · post post): post đầu chặn" sh "$GAC" post
ky_vong 0 "…post thứ hai không báo thêm" sh "$GAC" post
dung "…tick của agent đã bị bỏ, không hồi lại" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/spec.md'"
viet_spec
sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" pre >/dev/null 2>&1
ky_vong 0 "người tick giữa hai lượt, hook chạy hai lần: post đầu cho qua" sh "$GAC" post
ky_vong 0 "…post thứ hai cũng cho qua" sh "$GAC" post
dung "…tick của người còn nguyên" co_tick
sh "$GAC" pre >/dev/null 2>&1; thay "$F/spec.md" 'mở y thấy a' 'mở y thấy a và c'; sh "$GAC" pre >/dev/null 2>&1
ky_vong 2 "nội dung đổi sau duyệt, hook hai lần: vẫn bỏ tick" sh "$GAC" post
dung "…spec giờ chưa tick" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/spec.md'"
# post dùng hết mốc của pre: một post lẻ về sau (agent bắn hook không đều — Cursor
# có tool bỏ qua pre) không được coi tick của người là của agent.
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 0 "post lẻ sau một cặp pre/post đã xong: tick của người không bị bỏ" sh "$GAC" post
dung "…tick của người còn nguyên" co_tick
rm -f "$R/.agent-workflow/.guard-pre"
viet_spec; viet_tdd; ghi_based_on

# ---------------------------------------------------------------- cổng duyệt
echo ""
echo "approval.sh (aw approval)"
CD="$T/approval.sh"
viet_spec; viet_tdd
ky_vong 2 "approval sai phase → SAI THAM SỐ" sh "$CD" review "$F"
ky_vong 2 "approval thiếu thư mục → SAI THAM SỐ" sh "$CD" design "$TMP/khong-co"
ky_vong 0 "spec đã tick → ĐÃ DUYỆT" sh "$CD" design "$F"
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
thay "$F/spec.md" '### YC-002 — b' '### YC-003 — log khi từ chối
- Source: `[INFERRED]` từ YC-001
- Priority: `must`
- Acceptance criteria:
  - [ ] có log

### YC-002 — b'
ky_vong 1 "spec chưa tick → CHƯA DUYỆT" sh "$CD" design "$F"
OUT_CD=$(sh "$CD" design "$F" 2>/dev/null)
dung "…chỉ đúng file và dòng phải tick" sh -c "printf '%s' \"\$1\" | grep -q 'mở .agent-workflow/[^ ]*/spec.md, dòng [0-9]'" _ "$OUT_CD"
dung "…liệt kê YC [INFERRED] kèm tên" sh -c "printf '%s' \"\$1\" | grep -q 'YC-003 — log khi từ chối'" _ "$OUT_CD"
dung "…liệt kê Ngoài phạm vi" sh -c "printf '%s' \"\$1\" | grep -q 'màn hình z'" _ "$OUT_CD"
dung "…nói hệ quả của mức rủi ro (Mode 1/2)" sh -c "printf '%s' \"\$1\" | grep -q 'Risk: normal — /aw-design chạy Mode 1'" _ "$OUT_CD"
dung "…đếm điểm mù còn mở theo mức chặn" sh -c "printf '%s' \"\$1\" | grep -q 'Điểm mù còn mở: 1 (blocking: 0 · review-blocking: 0 · non-blocking: 1)'" _ "$OUT_CD"
dung "…không tự tick" sh -c "grep -q '^- \[ \] \*\*Approved by human' '$F/spec.md'"
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 0 "người tick xong → ĐÃ DUYỆT (kiểm lại)" sh "$CD" design "$F"
thay "$F/spec.md" 'có log' 'có log Warn'
ky_vong 1 "spec đổi sau duyệt → CHƯA DUYỆT" sh "$CD" design "$F"
dung "…nói rõ đã đổi sau khi duyệt và cách duyệt lại" sh -c "sh '$CD' design '$F' 2>/dev/null | grep -q 'ĐÃ ĐỔI SAU KHI DUYỆT' && sh '$CD' design '$F' 2>/dev/null | grep -q 'xoá \"<!-- approval-hash'"
viet_spec; viet_tdd
ky_vong 0 "/aw-plan: mọi D đã tick → ĐÃ DUYỆT" sh "$CD" plan "$F"
thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**
- Critique (agent): cân nhắc DB'
ky_vong 1 "/aw-plan: còn D chưa tick → CHƯA DUYỆT" sh "$CD" plan "$F"
OUT_CD=$(sh "$CD" plan "$F" 2>/dev/null)
dung "…đếm D chưa duyệt" sh -c "printf '%s' \"\$1\" | grep -q 'CÒN 1/1 QUYẾT ĐỊNH CHƯA DUYỆT'" _ "$OUT_CD"
dung "…tên D, dòng, tác giả, lựa chọn, có phản biện" sh -c "printf '%s' \"\$1\" | grep -q 'D-01 — lưu ở đâu' && printf '%s' \"\$1\" | grep -q 'dòng [0-9]* · chưa tick' && printf '%s' \"\$1\" | grep -q 'tác giả: agent · Choice: file · có 1 phản biện'" _ "$OUT_CD"
viet_spec; viet_tdd; ghi_based_on

# ---------------------------------------------------------------- chore
echo ""
echo "loại việc: chore"
tao_fixture chore chore_v
for c in spec plan implement review; do
  ky_vong 0 "chore đầy đủ (không có tdd.md) qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done
ky_vong 1 "chore chạy design thì bị chặn" sh "$T/check-design.sh" "$F"

thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 1 "chore: aw approval plan hỏi duyệt SPEC (không có tdd.md)" sh "$T/approval.sh" plan "$F"
dung "…đúng cổng spec, không nói Mode" sh -c "sh '$T/approval.sh' plan '$F' 2>/dev/null | grep -q 'vào /aw-plan cần spec' && sh '$T/approval.sh' plan '$F' 2>/dev/null | grep -q 'chore không có design'"
ky_vong 2 "chore: aw approval design → SAI THAM SỐ" sh "$T/approval.sh" design "$F"
ky_vong 1 "chore: plan chặn khi người chưa duyệt spec" sh "$T/check-plan.sh" "$F"
viet_spec; ghi_based_on

thay "$F/open-questions.md" '`non-blocking`' '`blocking`'
ky_vong 1 "chore: điểm mù \"chặn\" còn mở thì plan chặn (chore không có design)" sh "$T/check-plan.sh" "$F"
viet_spec; ghi_based_on

printf 'moi\n' > "$R/src/a.txt"
ky_vong 1 "chore đụng code production thì chặn" sh "$T/check-implement.sh" "$F"
g checkout -q -- src/a.txt

printf '{"dependencies":{"lodash":"4.17.21"}}\n' > "$R/package.json"
ky_vong 1 "chore nâng dependency không khai thì chặn" sh "$T/check-implement.sh" "$F"
thay "$F/plan.md" '| Library | Old → new | Level |
|---|---|---|
' '| Library | Old → new | Level |
|---|---|---|
| lodash | 4.17.20 → 4.17.21 | patch |
'
ky_vong 0 "khai nâng bản vá thì cho qua" sh "$T/check-implement.sh" "$F"
cp "$CFG/config.sh" "$TMP/ch-chore.bak"
printf 'TEST_CMD="true"\nSECURITY_CMDS="secret: true\nsast: true"\n' > "$CFG/config.sh"
ky_vong 1 "chore đụng dependency mà không có lệnh nhóm sca → chặn" sh "$T/check-implement.sh" "$F"
dung "…đúng lý do: thiếu SCA" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'nhóm \"sca\" chạy XANH'"
dung "…review cũng chặn đúng lý do" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'nhóm \"sca\" chạy XANH'"
printf 'TEST_CMD="true"\nSECURITY_CMDS="secret: true\nsast: true\nsca: echo CVE-2099-1; exit 1"\n' > "$CFG/config.sh"
ky_vong 1 "chore đụng dependency mà SCA đỏ (CVE) → chặn" sh "$T/check-implement.sh" "$F"
cp "$TMP/ch-chore.bak" "$CFG/config.sh"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1
thay "$F/plan.md" '| patch |' '| major |'
ky_vong 1 "nâng major không được là chore" sh "$T/check-implement.sh" "$F"
rm -f "$R/package.json"; viet_plan; ghi_based_on
printf 'TEST_CMD="true"\nSECURITY_CMDS="secret: true"\n' > "$CFG/config.sh"
ky_vong 0 "chore KHÔNG đụng dependency thì không đòi SCA" sh "$T/check-implement.sh" "$F"
cp "$TMP/ch-chore.bak" "$CFG/config.sh"; sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

thay "$F/plan.md" '- Expected files: `docs/*`' '- Based on: `D-01`
- Expected files: `docs/*`'
ky_vong 1 "chore: task Dựa trên D-xx bị chặn (không có tdd.md)" sh "$T/check-plan.sh" "$F"
viet_plan; ghi_based_on

# ---------------------------------------------------------------- doi ten feature
echo ""
echo "aw rename (rename-feature.sh)"
unset AW_REPO AW_CONFIG
ky_vong 2 "từ chối chạy ở checkout chính" awd "$R9" rename feat_x
W7="$TMP/repo9.wt/fix_sai-loai"
g9 worktree add -q -b fix_sai-loai "$W7" main
mkdir -p "$W7/.agent-workflow/fix_sai-loai"; printf 'x\n' > "$W7/.agent-workflow/fix_sai-loai/intake.md"
mkdir -p "$TMP/repo9.wt/feat_khac"
ky_vong 2 "từ chối khi thư mục worktree đích đã tồn tại" awd "$W7" rename feat_khac
dung "…và không đổi gì" sh -c "[ -d '$W7' ] && git -C '$R9' rev-parse --verify --quiet refs/heads/fix_sai-loai"
ky_vong 0 "đổi tên thành công (chạy trong worktree)" awd "$W7" rename feat_dung-loai
W8="$TMP/repo9.wt/feat_dung-loai"
dung "branch đã đổi tên" sh -c "git -C '$R9' rev-parse --verify --quiet refs/heads/feat_dung-loai && ! git -C '$R9' rev-parse --verify --quiet refs/heads/fix_sai-loai"
dung "worktree dời sang tên mới, cùng thư mục cha" sh -c "[ ! -e '$W7' ] && [ \"\$(git -C '$W8' rev-parse --abbrev-ref HEAD)\" = feat_dung-loai ]"
dung "thư mục artifact dời theo" sh -c "[ -f '$W8/.agent-workflow/feat_dung-loai/intake.md' ] && [ ! -d '$W8/.agent-workflow/fix_sai-loai' ]"

# ---------------------------------------------------------------- chuyen tu bo cai 1.x
echo ""
echo "aw init --from-legacy (chuyển từ bộ cài 1.x)"
ky_vong 3 "tools/install.sh chỉ in hướng dẫn, không cài gì" sh "$T/install.sh" "$TMP/khong-quan-trong"
dung "…hướng dẫn dùng aw init / aw init --from-legacy" sh -c "sh '$T/install.sh' 2>/dev/null | grep -q 'aw init --from-legacy'"
ky_vong 3 "tools/sync.sh chỉ in hướng dẫn aw upgrade" sh "$T/sync.sh"
dung "…nhắc aw upgrade" sh -c "sh '$T/sync.sh' 2>/dev/null | grep -q 'aw upgrade'"

# Repo đích có bộ cài 1.x đã commit vào base (dựng tay đúng cấu trúc cũ)
RL="$TMP/repo-cu"; mkdir -p "$RL/.agent-workflow/.quy-trinh/tools" "$RL/.claude/commands" "$RL/.agent-workflow/feat_cu"
git -C "$RL" init -q; git -C "$RL" checkout -q -b main
printf '# quy ước cũ của team\n```conventions\nbranch_patterns: feat_* chore_*\ntype_by_prefix: feat_=feature chore_=chore\nbase_branch: main\n```\n' > "$RL/.agent-workflow/conventions.md"
printf 'LENH_KIEM_THU="make test"\nLENH_CHUAN_BI_WT="npm ci"\n' > "$RL/.agent-workflow/.quy-trinh/cau-hinh.sh"
printf 'url=x\nadapter=claude-code\n' > "$RL/.agent-workflow/.quy-trinh/nguon.txt"
printf 'echo cu\n' > "$RL/.agent-workflow/.quy-trinh/tools/feature.sh"
printf -- '---\n---\n> **File này được SINH TỰ ĐỘNG** — bản 1.x\nsh .agent-workflow/.quy-trinh/tools/x.sh\n' > "$RL/.claude/commands/aw-spec.md"
printf '# lệnh team tự viết\n' > "$RL/.claude/commands/cua-team.md"
printf 'x\n' > "$RL/.agent-workflow/feat_cu/intake.md"
git -C "$RL" add -A; git -C "$RL" -c user.name=t -c user.email=t@t commit -q -m "bo cai 1.x"
GOCL=$(git -C "$RL" rev-parse HEAD)
CL="$RL/.git/agent-workflow"

ky_vong 2 "--from-legacy ở repo không có bộ cài cũ → SAI THAM SỐ" sh -c "R=\$(mktemp -d '$TMP/x.XXXX') && git -C \"\$R\" init -q && cd \"\$R\" && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' init --from-legacy --version '$VDEV'"
ky_vong 0 "aw init --from-legacy" awd "$RL" init --from-legacy --version "$VDEV"
dung "…conventions.md cũ chuyển vào .git/agent-workflow/" cmp -s "$RL/.agent-workflow/conventions.md" "$CL/conventions.md"
dung "…lệnh trong cau-hinh.sh cũ chuyển sang config.sh" sh -c "grep -qx 'TEST_CMD=\"make test\"' '$CL/config.sh' && grep -qx 'WORKTREE_SETUP_CMD=\"npm ci\"' '$CL/config.sh' && grep -qx 'ADAPTER=\"claude-code\"' '$CL/config.sh'"
dung "…không xoá gì của bộ cài cũ" sh -c "[ -f '$RL/.agent-workflow/.quy-trinh/cau-hinh.sh' ] && [ -f '$RL/.agent-workflow/conventions.md' ] && [ -f '$RL/.claude/commands/aw-spec.md' ]"
dung "…không commit gì, cây làm việc sạch" sh -c "[ \"\$(git -C '$RL' rev-parse HEAD)\" = '$GOCL' ] && [ -z \"\$(git -C '$RL' status --porcelain)\" ]"
dung "…file .claude/ cũ git đang theo dõi: adapter bỏ qua, nội dung giữ nguyên" grep -q 'bản 1.x' "$RL/.claude/commands/aw-spec.md"
dung "…lệnh người viết tay giữ nguyên" grep -q 'team tự viết' "$RL/.claude/commands/cua-team.md"
dung "…sinh các lệnh mới chưa có" sh -c "[ -f '$RL/.claude/commands/aw-design.md' ] && grep -q 'aw feature' '$RL/.claude/commands/aw-design.md'"
OUTL=$(awd "$RL" init --from-legacy 2>/dev/null)
dung "…in hướng dẫn tự dọn bằng PR: git rm bộ cài cũ" sh -c "printf '%s' \"\$1\" | grep -q 'git rm -r -q -- .agent-workflow/.quy-trinh/' && printf '%s' \"\$1\" | grep -q 'git rm -r -q -- .claude/commands/aw-spec.md'" _ "$OUTL"
dung "…không đề nghị xoá lệnh người viết tay" sh -c "! printf '%s' \"\$1\" | grep -q 'cua-team.md'" _ "$OUTL"
dung "…chạy lại giữ cấu hình đã chuyển" sh -c "grep -qx 'TEST_CMD=\"make test\"' '$CL/config.sh'"
ky_vong 0 "repo cũ: tạo worktree từ base vẫn chứa bộ cài 1.x" awd "$RL" worktree new feature sau-chuyen --create --base main
dung "…worktree sạch, base không đổi" sh -c "[ -z \"\$(git -C '$TMP/repo-cu.wt/feat_sau-chuyen' status --porcelain)\" ] && [ \"\$(git -C '$RL' rev-parse main)\" = '$GOCL' ]"

# Cấu hình của người: init lại không ghi đè (thay cho các ca của install.sh)
printf 'TEST_CMD="npm test"\nADAPTER="claude-code"\n' > "$CL/config.sh"
printf '# của tôi\n```conventions\nbranch_patterns: job-*\n```\n' > "$CL/conventions.md"
awd "$RL" init >/dev/null 2>&1
dung "init lại KHÔNG ghi đè config.sh người sửa" grep -q 'npm test' "$CL/config.sh"
awd "$RL" init --force >/dev/null 2>&1
dung "KHÔNG ghi đè conventions.md, kể cả --force" grep -q 'của tôi' "$CL/conventions.md"
ky_vong 2 "init --adapter khác ADAPTER trong config.sh → SAI THAM SỐ" awd "$RL" init --adapter cursor

# ---------------------------------------------------------------- khoi "Ket qua"
# Nguoi va agent doc NHAN, khong doc ma so: moi script in khoi nay ra stderr.
echo ""
echo "lib/result.sh"
KQT="$TMP/kq-thu.sh"
cat > "$KQT" <<EOF
. "$T/lib/result.sh"
kq_khai thu.sh "0=ĐẠT" "1=KHÔNG ĐẠT" "2=THIẾU ĐẦU VÀO"
kq_don 'echo don >&2'
echo du-lieu
exit "\$1"
EOF
ky_vong 1 "mã thoát giữ nguyên sau khi in khối" sh "$KQT" 1
dung "đánh dấu đúng nhãn của lần chạy" sh -c "sh '$KQT' 1 2>&1 >/dev/null | grep -qx '  \[x\] KHÔNG ĐẠT'"
dung "…các nhãn còn lại để trống" sh -c "o=\$(sh '$KQT' 1 2>&1 >/dev/null); printf '%s\n' \"\$o\" | grep -qx '  \[ \] ĐẠT' && printf '%s\n' \"\$o\" | grep -qx '  \[ \] THIẾU ĐẦU VÀO'"
dung "mã ngoài danh sách → LỖI NGOÀI DỰ KIẾN" sh -c "sh '$KQT' 9 2>&1 >/dev/null | grep -q '\[x\] LỖI NGOÀI DỰ KIẾN'"
dung "khối ra stderr, stdout giữ nguyên dữ liệu" bang "$(sh "$KQT" 0 2>/dev/null)" "du-lieu"
dung "việc dọn dẹp (kq_don) vẫn chạy" sh -c "sh '$KQT' 0 2>&1 >/dev/null | grep -qx don"
dung "checker thiếu file → [x] THIẾU ĐẦU VÀO" sh -c "AW_REPO='$R9' AW_CONFIG='$R9/.git/agent-workflow' sh '$T/check-plan.sh' '$TMP/khong-co' 2>&1 | grep -q '\[x\] THIẾU ĐẦU VÀO'"
dung "checker gọi thẳng, thiếu AW_CONFIG → dừng, không đoán đường dẫn" sh -c "env -u AW_CONFIG sh '$T/check-plan.sh' '$TMP/khong-co' 2>&1 | grep -q 'thiếu AW_CONFIG'"
dung "tool worktree gọi thẳng, thiếu AW_REPO → dừng" sh -c "env -u AW_REPO -u AW_CONFIG sh '$T/feature.sh' 2>&1 | grep -q 'thiếu AW_REPO'"
dung "aw feature ở checkout chính → [x] ĐANG Ở CHECKOUT CHÍNH" sh -c "printf '%s' \"\$1\" | grep -q '\[x\] ĐANG Ở CHECKOUT CHÍNH'" _ "$(awd "$R9" feature 2>&1)"
dung "…stdout không lẫn khối Kết quả" sh -c "! printf '%s' \"\$1\" | grep -q 'Kết quả'" _ "$(awd "$R9" feature 2>/dev/null)"

# ---------------------------------------------------------------- dong goi (phat hanh)
echo ""
echo "tools/package.sh"
# tao_nguon <thư-mục> <YYYY.M.N> — chép repo này (cả thay đổi chưa commit) thành một
# repo git riêng mang version <YYYY.M.N>. Dùng làm "bản phát hành" giả.
tao_nguon() {
  rm -rf "$1"; mkdir -p "$1"
  (cd "$ROOT" && tar cf - --exclude=.git .) | (cd "$1" && tar xf -)
  printf '%s\n' "$2" > "$1/VERSION"
  [ -f "$1/bin/aw" ] && thay "$1/bin/aw" "AW_WRAPPER_VERSION=\"$(cat "$ROOT/VERSION")\"" "AW_WRAPPER_VERSION=\"$2\""
  git -C "$1" init -q; git -C "$1" checkout -q -b main
  git -C "$1" add -A; git -C "$1" -c user.name=t -c user.email=t@t commit -q -m "v$2"
}
NG="$TMP/nguon-goi"; tao_nguon "$NG" 2099.9.1
ky_vong 0 "đóng gói bản đúng" sh "$NG/tools/package.sh" "$TMP/goi1"
dung "ra tarball đúng tên + SHA256SUMS khớp" sh -c "cd '$TMP/goi1' && [ -f agent-workflow-2099.9.1.tar.gz ] && sha256sum -c SHA256SUMS >/dev/null 2>&1"
dung "tarball có thư mục gốc agent-workflow-2099.9.1/ và VERSION" sh -c "gzip -dc '$TMP/goi1/agent-workflow-2099.9.1.tar.gz' | tar tf - | grep -qx 'agent-workflow-2099.9.1/VERSION'"
sh "$NG/tools/package.sh" "$TMP/goi2" >/dev/null 2>&1
dung "đóng gói lại cùng commit → cùng checksum" cmp -s "$TMP/goi1/SHA256SUMS" "$TMP/goi2/SHA256SUMS"
printf 'chua commit\n' > "$NG/chua-commit.txt"
sh "$NG/tools/package.sh" "$TMP/goi3" >/dev/null 2>&1
dung "file chưa commit không lọt vào gói" sh -c "! gzip -dc '$TMP/goi3/agent-workflow-2099.9.1.tar.gz' | tar tf - | grep -q chua-commit"
printf 'v2\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam sai
ky_vong 4 "VERSION sai dạng YYYY.M.N → VERSION LỖI" sh "$NG/tools/package.sh" "$TMP/goi4"
printf '2.0.0\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam semver
ky_vong 4 "VERSION kiểu X.Y.Z (semver) → VERSION LỖI" sh "$NG/tools/package.sh" "$TMP/goi4b"
printf '2026.13.1\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam thang13
ky_vong 4 "VERSION tháng 13 → VERSION LỖI" sh "$NG/tools/package.sh" "$TMP/goi4c"
dung "luật version YYYY.M.N: nhận 2026.10.6, 2026.1.6, 2026.12.31, 2026.10.32, 2026.10.100; từ chối 2026.10.06, 2026.01.6, 2026.0.10, 2026.10.0, 2026.10.6.1, 2026.10.1a, v2026.10.6" sh -c ". '$T/lib/version.sh'; ver_hop_le 2026.10.6 && ver_hop_le 2026.1.6 && ver_hop_le 2026.12.31 && ver_hop_le 2026.10.32 && ver_hop_le 2026.10.100 && ! ver_hop_le 2026.10.06 && ! ver_hop_le 2026.01.6 && ! ver_hop_le 2026.0.10 && ! ver_hop_le 2026.10.0 && ! ver_hop_le 2026.10.6.1 && ! ver_hop_le 2026.10.1a && ! ver_hop_le v2026.10.6"
dung "wrapper bin/aw dùng cùng luật version với engine" sh -c "eval \"\$(sed -n '/^version_hop_le() {/,/^}/p' '$ROOT/bin/aw')\"; for v in 2026.10.32 2026.10.100 2026.1.1; do version_hop_le \$v || exit 1; done; for v in 2026.10.0 2026.10.08 2026.10.6.1; do version_hop_le \$v && exit 1; done; exit 0"
ky_vong 2 "ref không tồn tại → sai tham số" sh "$NG/tools/package.sh" "$TMP/goi5" khong-co
dung "VERSION của repo đúng dạng YYYY.M.N" sh -c ". '$T/lib/version.sh'; ver_hop_le \"\$(cat '$ROOT/VERSION')\""
dung "workflow release gắn file vào release đã có (tạo tag trên giao diện GitHub)" sh -c "grep -q 'gh release upload \"\$TAG\" dist/\* --clobber' '$ROOT/.github/workflows/release.yml' && grep -q 'gh release create \"\$TAG\"' '$ROOT/.github/workflows/release.yml'"
dung "workflow release chạy khi merge vào main, bỏ qua khi tag đã có" sh -c "grep -q 'branches: \[main\]' '$ROOT/.github/workflows/release.yml' && grep -q 'ls-remote --exit-code --tags origin' '$ROOT/.github/workflows/release.yml'"
dung "workflow kiem-tra của PR chạy kiểm version + test" sh -c "grep -q 'check-release.sh \"origin/\$BASE\"' '$ROOT/.github/workflows/kiem-tra.yml' && grep -q 'run-tests.sh' '$ROOT/.github/workflows/kiem-tra.yml'"
dung "workflow release bắt tag dạng YYYY.M.N, không có v" grep -qF "tags: ['[0-9][0-9][0-9][0-9].[0-9]+.[0-9]+']" "$ROOT/.github/workflows/release.yml"
dung "CHANGELOG.md có mục cho VERSION" grep -qF "## [$(cat "$ROOT/VERSION")]" "$ROOT/CHANGELOG.md"

# ---------------------------------------------------------------- chuẩn bị + kiểm phát hành
echo ""
echo "tools/prepare-release.sh + tools/check-release.sh"
git_t() { _gt_d=$1; shift; git -C "$_gt_d" -c user.name=t -c user.email=t@t "$@"; }
PH="$TMP/ph"; PHO="$TMP/ph-origin.git"
tao_nguon "$PH" 2099.9.1
rm -rf "$PHO"; git init -q --bare "$PHO"; git -C "$PH" remote add origin "$PHO"
git -C "$PH" push -q origin main 2>/dev/null
git -C "$PH" tag 2099.9.1; git -C "$PH" push -q origin 2099.9.1 2>/dev/null
ph_cl() { printf '# Changelog\n\n## [Chưa phát hành]\n\n- thay đổi mới\n\n## [2099.9.1]\n\n- cũ\n' > "$PH/CHANGELOG.md"; }
ph_cl; git_t "$PH" commit -qam cl
ky_vong 0 "kiểm phát hành: VERSION không đổi so với base → đạt" sh "$PH/tools/check-release.sh" main
ky_vong 4 "chuẩn bị: version truyền tay trùng tag đã có → VERSION LỖI" sh "$PH/tools/prepare-release.sh" 2099.9.1
ky_vong 4 "chuẩn bị: version sai dạng (số 0 đứng đầu) → VERSION LỖI" sh "$PH/tools/prepare-release.sh" 2099.09.2
ky_vong 0 "chuẩn bị: version truyền tay" sh "$PH/tools/prepare-release.sh" 2099.9.2
dung "…ghi VERSION, bin/aw, CHANGELOG cùng một version" sh -c "grep -qx 2099.9.2 '$PH/VERSION' && grep -q '^AW_WRAPPER_VERSION=\"2099.9.2\"' '$PH/bin/aw' && grep -qx '## \[2099.9.2\]' '$PH/CHANGELOG.md' && ! grep -q 'Chưa phát hành' '$PH/CHANGELOG.md'"
dung "…link tải wrapper trong README trỏ version mới" grep -q 'releases/download/2099.9.2/aw' "$PH/README.md"
git -C "$PH" checkout -q -b pr; git_t "$PH" commit -qam "phát hành 2099.9.2"
ky_vong 0 "kiểm phát hành: PR đổi VERSION, tag chưa có → đạt" sh "$PH/tools/check-release.sh" main
git -C "$PH" tag 2099.9.2 main; git -C "$PH" push -q origin 2099.9.2 2>/dev/null
ky_vong 1 "kiểm phát hành: PR khác đã lấy số này (tag có rồi) → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh" main
thay "$PH/bin/aw" 'AW_WRAPPER_VERSION="2099.9.2"' 'AW_WRAPPER_VERSION="2099.9.1"'
ky_vong 1 "kiểm phát hành: bin/aw lệch VERSION → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh"
git -C "$PH" checkout -q -- bin/aw
thay "$PH/CHANGELOG.md" '## [2099.9.2]' '## [Chưa phát hành]'
ky_vong 1 "kiểm phát hành: CHANGELOG thiếu mục cho VERSION → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh"
git -C "$PH" checkout -q -- .; git -C "$PH" checkout -q main; git -C "$PH" branch -qD pr
ph_cl; git_t "$PH" commit -qam cl2
THANG_NAY="$(date +%Y).$(date +%m | sed 's/^0//')"
git -C "$PH" tag "$THANG_NAY.1"; git -C "$PH" tag "$THANG_NAY.3"; git -C "$PH" push -q origin --tags 2>/dev/null
ky_vong 0 "chuẩn bị: tự tính version" sh "$PH/tools/prepare-release.sh"
dung "…= tháng này, số lớn nhất ở remote + 1" grep -qx "$THANG_NAY.4" "$PH/VERSION"
git -C "$PH" checkout -q -- .
git -C "$PH" tag "$THANG_NAY.9"
ky_vong 0 "chuẩn bị: tag chỉ có ở máy, chưa lên remote → không tính" sh "$PH/tools/prepare-release.sh"
dung "…vẫn là số kế tiếp ở remote" grep -qx "$THANG_NAY.4" "$PH/VERSION"
git -C "$PH" checkout -q -- .
printf '# Changelog\n\n## [2099.9.1]\n\n- cũ\n' > "$PH/CHANGELOG.md"
ky_vong 3 "chuẩn bị: CHANGELOG không có [Chưa phát hành] → KHÔNG CÓ GÌ ĐỂ PHÁT HÀNH" sh "$PH/tools/prepare-release.sh"
dung "…không đổi file nào" sh -c "grep -qx 2099.9.1 '$PH/VERSION'"

# ---------------------------------------------------------------- wrapper aw
echo ""
echo "bin/aw (wrapper)"
unset AW_REPO AW_CONFIG
AWH="$TMP/awhome"; MIR="$TMP/mirror"
# Mirror giả (file://): mỗi version là một bản phát hành đóng gói từ repo này.
for v in 2099.1.1 2099.1.2; do
  tao_nguon "$TMP/nguon-$v" "$v"
  sh "$TMP/nguon-$v/tools/package.sh" "$MIR/$v" >/dev/null 2>&1
done
tao_nguon "$TMP/nguon-2099.1.4" 2099.1.4
sh "$TMP/nguon-2099.1.4/tools/package.sh" "$MIR/2099.1.4" >/dev/null 2>&1
printf '%s  agent-workflow-2099.1.4.tar.gz\n' "$(printf 0 | awk '{ for (i = 0; i < 64; i++) printf "0" }')" > "$MIR/2099.1.4/SHA256SUMS"

R7="$TMP/repo7"; mkdir -p "$R7"
git -C "$R7" init -q; git -C "$R7" checkout -q -b main
git -C "$R7" -c user.name=t -c user.email=t@t commit -q --allow-empty -m goc
GOC7=$(git -C "$R7" rev-parse HEAD)
# aw7 <args> — chạy aw trong repo7 với HOME/mirror riêng của test
aw7() { (cd "$R7" && AW_HOME="$AWH" AW_MIRROR="file://$MIR" sh "$ROOT/bin/aw" "$@"); }
C7="$R7/.git/agent-workflow"

ky_vong 9 "ngoài git repo → KHÔNG HỢP LỆ" sh -c "cd '$TMP' && AW_HOME='$AWH' sh '$ROOT/bin/aw' check spec x"
ky_vong 9 "chưa init → KHÔNG HỢP LỆ" aw7 check spec .agent-workflow/x
ky_vong 2 "init --version sai dạng → SAI THAM SỐ" aw7 init --version 2099.01.01
ky_vong 0 "aw init --version 2099.1.1 (cache thiếu → tải từ mirror)" aw7 init --version 2099.1.1 --test-cmd true
dung "…ghi version, checksums, config.sh vào .git/agent-workflow/; quy ước tạo trong repo" sh -c \
  "grep -qx 2099.1.1 '$C7/version' && grep -q ' agent-workflow-2099.1.1.tar.gz' '$C7/checksums' && [ -f '$R7/docs/agent-workflow/conventions.md' ] && [ ! -f '$C7/conventions.md' ] && grep -q 'TEST_CMD=\"true\"' '$C7/config.sh'"
dung "…engine vào cache theo version, có dấu sha256" sh -c "[ -f '$AWH/engine/2099.1.1/bin/aw-engine' ] && [ -s '$AWH/engine/2099.1.1/.aw-sha256' ]"
dung "…sha ghim khớp SHA256SUMS của bản phát hành" sh -c "grep -qF \"\$(awk '\$2 == \"agent-workflow-2099.1.1.tar.gz\" { print \$1 }' '$MIR/2099.1.1/SHA256SUMS')\" '$C7/checksums'"
dung "…exclude /.agent-workflow/ và /.claude/" sh -c "grep -qx '/.agent-workflow/' '$R7/.git/info/exclude' && grep -qx '/.claude/' '$R7/.git/info/exclude'"
dung "…sinh adapter ở checkout chính" test -f "$R7/.claude/commands/aw-intake.md"
dung "…không có commit nào vào base" bang "$(git -C "$R7" rev-parse HEAD)" "$GOC7"
dung "…file sinh ra không lọt vào git status — chỉ còn quy ước chờ commit" sh -c "[ \"\$(git -C '$R7' status --porcelain --untracked-files=all)\" = '?? docs/agent-workflow/conventions.md' ]"
ky_vong 0 "aw guard pre → chuyển sang engine của bản clone (chưa có việc nào: không làm gì)" aw7 guard pre
ky_vong 0 "aw guard post → như trên" aw7 guard post
ky_vong 2 "aw approval → chuyển sang engine (thư mục không có → SAI THAM SỐ)" aw7 approval design "$TMP/khong-co"
aw7 init >/dev/null 2>&1
dung "init lại: không nhân đôi dòng exclude" bang "$(grep -cx '/.claude/' "$R7/.git/info/exclude")" 1
ky_vong 2 "init lại với version khác → SAI THAM SỐ (dùng aw upgrade)" aw7 init --version 2099.1.2
dung "aw version in engine đang dùng" sh -c "cd '$R7' && AW_HOME='$AWH' sh '$ROOT/bin/aw' version 2>/dev/null | grep -q 'engine       2099.1.1'"
ky_vong 0 "aw doctor: mọi mục ✓" aw7 doctor

ky_vong 6 "cache có version → chạy không cần mạng (aw feature)" sh -c "cd '$R7' && AW_HOME='$AWH' AW_MIRROR='file://$TMP/khong-co' sh '$ROOT/bin/aw' feature"
ky_vong 9 "version không có trong cache và không tải được → KHÔNG HỢP LỆ" aw7 upgrade 2099.1.3
dung "…version giữ nguyên" grep -qx 2099.1.1 "$C7/version"
ky_vong 9 "checksum sai → KHÔNG HỢP LỆ" aw7 upgrade 2099.1.4
dung "…không cài vào cache, version giữ nguyên" sh -c "[ ! -e '$AWH/engine/2099.1.4' ] && grep -qx 2099.1.1 '$C7/version'"

cp "$C7/checksums" "$TMP/checksums.bak"
sed 's/^[0-9a-f]*  agent-workflow-2099.1.1/1111  agent-workflow-2099.1.1/' "$TMP/checksums.bak" > "$C7/checksums"
ky_vong 9 "cache lệch sha đã ghim → KHÔNG HỢP LỆ" aw7 feature
mv "$AWH/engine/2099.1.1" "$TMP/engine-2099.1.1.bak"
ky_vong 9 "tải lại mà khác sha đã ghim → KHÔNG HỢP LỆ (không tin SHA256SUMS)" aw7 feature
cp "$TMP/checksums.bak" "$C7/checksums"; mv "$TMP/engine-2099.1.1.bak" "$AWH/engine/2099.1.1"

ky_vong 9 "AW_ENGINE_DIR khác version → KHÔNG HỢP LỆ" sh -c "cd '$R7' && AW_HOME='$TMP/awhome-trong' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature"
ky_vong 6 "AW_ENGINE_DIR đúng version → chạy, không cần cache/mạng" sh -c "cd '$R7' && AW_HOME='$TMP/awhome-trong' AW_MIRROR='file://$TMP/khong-co' AW_ENGINE_DIR='$TMP/nguon-2099.1.1' sh '$ROOT/bin/aw' feature"
dung "…không tạo cache" test ! -e "$TMP/awhome-trong/engine/2099.1.1"

ky_vong 0 "aw upgrade 2099.1.2" aw7 upgrade 2099.1.2
dung "…version mới, ghim thêm sha của 2099.1.2, giữ sha cũ" sh -c "grep -qx 2099.1.2 '$C7/version' && grep -q 'agent-workflow-2099.1.2' '$C7/checksums' && grep -q 'agent-workflow-2099.1.1' '$C7/checksums'"
dung "…vẫn không có commit nào; upgrade không đụng quy ước" sh -c "[ \"\$(git -C '$R7' rev-parse HEAD)\" = '$GOC7' ] && [ \"\$(git -C '$R7' status --porcelain --untracked-files=all)\" = '?? docs/agent-workflow/conventions.md' ]"

# cấu hình dùng chung của team: một repo riêng chứa version, checksums, conventions.md
TEAM="$TMP/team-cfg"; mkdir -p "$TEAM"; git -C "$TEAM" init -q
cp "$C7/version" "$C7/checksums" "$TEAM/"; printf '# của team\n' > "$TEAM/conventions.md"
git -C "$TEAM" add -A; git -C "$TEAM" -c user.name=t -c user.email=t@t commit -q -m cfg
R8="$TMP/repo8"; git clone -q "$R7" "$R8" 2>/dev/null
ky_vong 0 "aw init --from <repo cấu hình team>" sh -c "cd '$R8' && AW_HOME='$AWH' AW_MIRROR='file://$MIR' sh '$ROOT/bin/aw' init --from '$TEAM'"
dung "…lấy version, checksums, conventions.md của team" sh -c "grep -qx 2099.1.2 '$R8/.git/agent-workflow/version' && grep -q 'của team' '$R8/.git/agent-workflow/conventions.md' && cmp -s '$TEAM/checksums' '$R8/.git/agent-workflow/checksums'"
ky_vong 9 "--from repo không có file version → KHÔNG HỢP LỆ" sh -c "cd '$R8' && AW_HOME='$AWH' sh '$ROOT/bin/aw' init --from '$R7'"
R8B="$TMP/repo8b"; git clone -q "$R7" "$R8B" 2>/dev/null
mkdir -p "$R8B/docs/agent-workflow"; printf '# của repo\n' > "$R8B/docs/agent-workflow/conventions.md"
ky_vong 0 "aw init --from khi repo đã có quy ước trong git" sh -c "cd '$R8B' && AW_HOME='$AWH' AW_MIRROR='file://$MIR' sh '$ROOT/bin/aw' init --from '$TEAM'"
dung "…bỏ qua conventions.md của repo cấu hình (không thành nguồn thứ hai), vẫn lấy version" sh -c "[ ! -f '$R8B/.git/agent-workflow/conventions.md' ] && grep -qx 2099.1.2 '$R8B/.git/agent-workflow/version' && grep -q 'của repo' '$R8B/docs/agent-workflow/conventions.md'"
# aw check chạy đúng version ghi trong intake.md của việc, không theo version của bản clone
mkdir -p "$R7/.agent-workflow/feat_a"
printf -- '- **Type:** `feature`\n- **Engine:** 2099.1.1\n' > "$R7/.agent-workflow/feat_a/intake.md"
ky_vong 1 "intake ghim 2099.1.1, bản clone 2099.1.2 → chấm bằng 2099.1.1 (KHÔNG ĐẠT, không phải KHÔNG HỢP LỆ)" aw7 check intake .agent-workflow/feat_a
printf -- '- **Type:** `feature`\n- **Engine:** 2099.1.3\n' > "$R7/.agent-workflow/feat_a/intake.md"
ky_vong 9 "intake ghim version không có và không tải được → KHÔNG HỢP LỆ" aw7 check intake .agent-workflow/feat_a
dung "…không âm thầm chạy bằng version khác" sh -c "cd '$R7' && AW_HOME='$AWH' AW_MIRROR='file://$MIR' sh '$ROOT/bin/aw' check intake .agent-workflow/feat_a 2>&1 | grep -q 'engine 2099.1.3 không có trong cache'"
printf -- '- **Engine:** v9\n' > "$R7/.agent-workflow/feat_a/intake.md"
ky_vong 9 "intake ghi Engine sai dạng → KHÔNG HỢP LỆ" aw7 check intake .agent-workflow/feat_a
ky_vong 9 "aw pending cũng theo version của việc" aw7 pending .agent-workflow/feat_a
ky_vong 9 "…aw questions (tên cũ) vẫn qua wrapper, theo version của việc" aw7 questions .agent-workflow/feat_a
rm -rf "$R7/.agent-workflow"
dung "wrapper và VERSION cùng version (đóng gói kiểm lại)" bang "$(awk -F'"' '/^AW_WRAPPER_VERSION=/ { print $2 }' "$ROOT/bin/aw")" "$(cat "$ROOT/VERSION")"

# ---------------------------------------------------------------- aw ship (ship.sh, ship-sweep.sh)
# Việc đã qua review nằm trong worktree; origin là repo bare; gh là bản giả
# (ghi lại tham số, trạng thái PR đọc từ $FG/state).
echo ""
echo "aw ship targets|create|status|sweep (ship.sh, ship-sweep.sh)"
tao_fixture 2>/dev/null
viet_mr
printf '/.agent-workflow/\n' >> "$R/.git/info/exclude"
g add -A; g commit -q -m "lam x"
# Dấu vân tay theo NỘI DUNG: commit đúng code đã review không làm kết quả lỗi thời.
ky_vong 0 "fixture: code đã commit, aw check ship đạt" sh "$SHC" "$F"
WS="$TMP/ship-wt"; FS="$WS/.agent-workflow/feat_x"
g checkout -q main
g worktree add -q "$WS" feat_x
mv "$R/.agent-workflow" "$WS/"
export AW_REPO="$WS"
RMS="$TMP/ship-remote.git"; git init -q --bare "$RMS"
g remote add origin "$RMS"; g push -q origin main; g push -q origin main:develop
# uat: gốc khác, không có commit "goc" của main → MR vào uat kéo theo commit ngoài việc
UATC=$(git -C "$R" -c user.name=t -c user.email=t@t commit-tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904 -m uat)
g push -q origin "$UATC:refs/heads/uat"
thay "$CFG/conventions.md" 'mr_target_branches:' 'mr_target_branches: develop uat main'
thay "$CFG/conventions.md" 'mr_platform:' 'mr_platform: github'

FB="$TMP/fakebin"; FG="$TMP/fakegh"; mkdir -p "$FB" "$FG"
cat > "$FB/gh" <<'EOF'
#!/bin/sh
case "$1 $2" in
  "pr create")
    printf 'OPEN\n' > "$FG/state"; git rev-parse HEAD > "$FG/head"; printf '%s\n' "$*" >> "$FG/args"
    while [ $# -gt 0 ]; do [ "$1" = --body-file ] && cp "$2" "$FG/body"; shift; done
    echo "https://github.com/o/r/pull/7" ;;
  "pr list") [ "$(cat "$FG/state" 2>/dev/null)" = OPEN ] && echo "https://github.com/o/r/pull/7"; exit 0 ;;
  "pr view") [ "$(cat "$FG/state")" = ERR ] && exit 1; echo "$(cat "$FG/state") $(cat "$FG/head")" ;;
  "auth status") exit 0 ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$FB/gh"
sg() { PATH="$FB:$PATH" FG="$FG" sh "$T/ship.sh" "$@"; }
sw() { (cd "$R" && AW_REPO="$R" PATH="$FB:$PATH" FG="$FG" sh "$T/ship-sweep.sh" "$@"); }

ky_vong 2 "create thiếu --target → SAI THAM SỐ (người chọn đích)" sg create "$FS"
TG=$(sg targets "$FS" 2>/dev/null)
ky_vong 0 "targets liệt kê nhánh đích" sg targets "$FS"
dung "…theo thứ tự mr_target_branches" bang "$(printf '%s\n' "$TG" | sed 's/^ *\[[0-9]*\] \([^ ]*\).*/\1/' | tr '\n' ' ')" "develop uat main "
dung "…đánh dấu base của việc" sh -c "printf '%s\n' \"\$1\" | grep -q '\[3\] main  ← base của việc'" _ "$TG"
dung "…cảnh báo nhánh sẽ kéo theo commit ngoài việc" sh -c "printf '%s\n' \"\$1\" | grep -q '\[2\] uat  ⚠ kéo theo 1 commit ngoài việc'" _ "$TG"
ky_vong 2 "đích ngoài mr_target_branches → từ chối" sg create "$FS" --target khac
printf 'nhap\n' > "$WS/nhap.txt"
ky_vong 1 "worktree còn file chưa commit → CHƯA ĐỦ ĐIỀU KIỆN" sg create "$FS" --target develop
rm -f "$WS/nhap.txt"
ky_vong 4 "MR vào uat kéo theo commit ngoài việc → người quyết" sg create "$FS" --target uat
dung "…không push, không tạo MR" sh -c "[ ! -f '$FG/args' ] && [ -z \"\$(git -C '$RMS' branch --list feat_x)\" ]"
thay "$CFG/conventions.md" 'mr_platform: github' 'mr_platform: gitlab'
# Không có glab (PATH chỉ có gh giả): server không hỗ trợ push options → push thường + link điền sẵn
sl() { PATH="$FB:/usr/bin:/bin" FG="$FG" sh "$T/ship.sh" "$@"; }
SLO=$(sl create "$FS" --target develop 2>&1)
ky_vong 8 "GitLab, không có glab, server không nhận push options → KHÔNG TẠO ĐƯỢC MR" sl create "$FS" --target develop
dung "…vẫn push được branch (push thường)" test "$(git -C "$RMS" rev-parse feat_x 2>/dev/null)" = "$(git -C "$WS" rev-parse HEAD)"
dung "…chỉ cách ghi lại bằng --url" sh -c "printf '%s\n' \"\$1\" | grep -q 'aw ship create .* --target develop --url'" _ "$SLO"
dung "…mô tả để sẵn ở mr-description.md cho người dán (đã bỏ comment)" sh -c "grep -q '^## Problem' '$FS/mr-description.md' && ! grep -q '<!--' '$FS/mr-description.md'"
# link điền sẵn: gọi thẳng hàm (origin https giả — không cần mạng)
LK="$TMP/link-repo"; git init -q "$LK"; git -C "$LK" remote add origin "git@gitlab.example:g/r.git"
printf '## Problem\n\nmột dòng\n' > "$TMP/mo-ta.md"
LKO=$(sh -c ". '$T/lib/md.sh'; . '$T/lib/mr.sh'; mr_link_tay '$LK' gitlab feat_x develop 'ABC-1: hiện a' '$TMP/mo-ta.md'")
dung "link tạo tay GitLab điền sẵn nguồn, đích, tiêu đề, mô tả (mã hoá URL, UTF-8)" bang "$LKO" \
  "https://gitlab.example/g/r/-/merge_requests/new?merge_request%5Bsource_branch%5D=feat_x&merge_request%5Btarget_branch%5D=develop&merge_request%5Btitle%5D=ABC-1%3A%20hi%E1%BB%87n%20a&merge_request%5Bdescription%5D=%23%23%20Problem%0A%0Am%E1%BB%99t%20d%C3%B2ng%0A"
LKO=$(sh -c ". '$T/lib/md.sh'; . '$T/lib/mr.sh'; mr_link_tay '$LK' github feat_x develop 'T' '$TMP/mo-ta.md'")
dung "link tạo tay GitHub: compare + title + body" bang "$LKO" "https://gitlab.example/g/r/compare/develop...feat_x?expand=1&title=T&body=%23%23%20Problem%0A%0Am%E1%BB%99t%20d%C3%B2ng%0A"

FB2="$TMP/fakebin-chua-dang-nhap"; mkdir -p "$FB2"; printf '#!/bin/sh\nexit 1\n' > "$FB2/gh"; chmod +x "$FB2/gh"
dung "gh đã cài mà chưa đăng nhập → không dùng, nói cách đăng nhập" sh -c \
  "PATH='$FB2:/usr/bin:/bin'; . '$T/lib/md.sh'; . '$T/lib/mr.sh'; ! mr_cli github '$LK' >/dev/null && printf '%s' \"\$MR_CLI_LY_DO\" | grep -q 'gh chưa đăng nhập vào gitlab.example (gh auth login --hostname gitlab.example)'"

# Server GitLab (giả): nhận push options, in link MR như GitLab
git -C "$RMS" config receive.advertisePushOptions true
cat > "$RMS/hooks/post-receive" <<'EOF'
#!/bin/sh
i=0
while [ $i -lt "${GIT_PUSH_OPTION_COUNT:-0}" ]; do
  eval "v=\$GIT_PUSH_OPTION_$i"; printf '%s\n' "$v" >> "FGDIR/push-options"; i=$((i + 1))
done
echo "View merge request for feat_x:"
echo "  https://gitlab.example/g/r/-/merge_requests/12"
EOF
sed -i.bak "s#FGDIR#$FG#" "$RMS/hooks/post-receive" && rm -f "$RMS/hooks/post-receive.bak"
chmod +x "$RMS/hooks/post-receive"
git -C "$WS" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "them commit cho push"
URLG=$(sl create "$FS" --target develop 2>/dev/null)
dung "GitLab, không có glab → tạo MR bằng git push options, stdout là URL" bang "$URLG" "https://gitlab.example/g/r/-/merge_requests/12"
dung "…push options: create, target, title, xoá source branch" sh -c \
  "grep -qx merge_request.create '$FG/push-options' && grep -qx merge_request.target=develop '$FG/push-options' && grep -qx 'merge_request.title=ABC-1: hiện a và b trên màn hình y' '$FG/push-options' && grep -qx merge_request.remove_source_branch '$FG/push-options'"
dung "…ship.md ghi MR (gitlab, open)" grep -q '| develop | open | .* | https://gitlab.example/g/r/-/merge_requests/12 |' "$FS/ship.md"
ky_vong 3 "status không có glab, git chưa thấy merge → giữ open (CÒN MR ĐANG MỞ)" sl status "$FS"
# squash merge trên server: một commit mang đúng toàn bộ thay đổi của branch
SQ="$TMP/squash-clone"; git clone -q -b develop "$RMS" "$SQ" 2>/dev/null
git -C "$SQ" fetch -q origin feat_x && git -C "$SQ" -c user.name=t -c user.email=t@t merge -q --squash origin/feat_x >/dev/null 2>&1 &&
  git -C "$SQ" -c user.name=t -c user.email=t@t commit -q -m "ABC-1 (squash)" && git -C "$SQ" push -q origin develop 2>/dev/null
dung "…squash merge: đầu branch KHÔNG nằm trong develop" sh -c "git -C '$WS' fetch -q origin && ! git -C '$WS' merge-base --is-ancestor HEAD origin/develop"
ky_vong 0 "status không có glab: nhận ra squash merge bằng patch-id → ĐÃ MERGE HẾT" sl status "$FS"
# dọn cho phần GitHub phía sau: develop về main, bỏ server giả, bỏ MR GitLab
rm -f "$RMS/hooks/post-receive" "$FS/ship.md" "$FS/mr-description.md"; git -C "$RMS" config --unset receive.advertisePushOptions
git -C "$RMS" update-ref refs/heads/develop "$(git -C "$R" rev-parse main)"
git -C "$WS" reset -q --hard HEAD~1; git -C "$WS" push -q -f origin feat_x 2>/dev/null
thay "$CFG/conventions.md" 'mr_platform: gitlab' 'mr_platform: github'

URLS=$(sg create "$FS" --target develop 2>/dev/null)
dung "create develop → ĐÃ TẠO MR, stdout là URL" bang "$URLS" "https://github.com/o/r/pull/7"
dung "…gh nhận đúng nguồn/đích và tiêu đề" sh -c "grep -q -- '--head feat_x --base develop --title ABC-1: hiện a và b trên màn hình y' '$FG/args'"
dung "…mô tả gửi đi bỏ dòng tiêu đề và comment của mẫu" sh -c "grep -q '^## Problem' '$FG/body' && ! grep -q '<!--' '$FG/body' && ! grep -q '^# ABC-1' '$FG/body'"
dung "…branch đã lên origin" test "$(git -C "$RMS" rev-parse feat_x 2>/dev/null)" = "$(git -C "$WS" rev-parse HEAD)"
dung "…ship.md ghi MR: đích, open, sha đầu branch, URL" grep -qxF "| develop | open | $(git -C "$WS" rev-parse HEAD) | https://github.com/o/r/pull/7 |" "$FS/ship.md"
ky_vong 5 "create lại cùng đích → ĐÃ CÓ MR ĐANG MỞ, không tạo thêm" sg create "$FS" --target develop
dung "…gh pr create chỉ được gọi một lần" test "$(wc -l < "$FG/args" | tr -d ' ')" = 1

ky_vong 3 "status: PR mở → CÒN MR ĐANG MỞ" sg status "$FS"
printf 'ERR\n' > "$FG/state"
ky_vong 6 "status: không hỏi được nền tảng, git không thấy merge → CHƯA RÕ" sg status "$FS"
printf 'CLOSED\n' > "$FG/state"
ky_vong 4 "status: PR bị đóng → người quyết" sg status "$FS"
printf 'MERGED\n' > "$FG/state"
ky_vong 0 "status: PR đóng rồi mở lại và merge → ĐÃ MERGE HẾT (closed không phải trạng thái cuối)" sg status "$FS"
dung "…ship.md ghi merged" grep -q '| develop | merged |' "$FS/ship.md"

ky_vong 2 "sweep trong worktree → từ chối (chạy từ checkout chính)" sh -c "cd '$WS' && PATH='$FB:$PATH' FG='$FG' sh '$T/ship-sweep.sh'"
git -C "$WS" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "sau khi merge"
ky_vong 7 "sweep: branch local có commit chưa vào MR đã merge → chặn" sw --apply
dung "…worktree còn nguyên" test -d "$WS"
git -C "$WS" reset -q --hard HEAD~1
SWO=$(sw 2>/dev/null)
ky_vong 0 "sweep không --apply → chỉ in" sw
dung "…báo việc dọn được, kể cả xoá origin/feat_x" sh -c "printf '%s\n' \"\$1\" | grep -q 'dọn được: .*xoá origin/feat_x'" _ "$SWO"
dung "…không đụng gì" sh -c "[ -d '$WS' ] && git -C '$R' rev-parse --verify --quiet refs/heads/feat_x"
ky_vong 0 "sweep --apply → dọn" sw --apply
dung "…worktree đã gỡ" test ! -e "$WS"
dung "…branch local đã xoá" sh -c "! git -C '$R' rev-parse --verify --quiet refs/heads/feat_x"
dung "…origin/feat_x đã xoá" sh -c "[ -z \"\$(git -C '$RMS' branch --list feat_x)\" ]"
dung "…artifact, kể cả ship.md, chép vào archive" test -f "$CFG/archive/feat_x/feat_x/ship.md"
ky_vong 0 "sweep lần nữa: không còn gì để dọn" sw
export AW_REPO="$R"

# ---------------------------------------------------------------- aw ready (ready.sh)
echo ""
echo "ready.sh (aw ready)"
tao_fixture
SS="$T/ready.sh"
CH="$CFG/config.sh"; cp "$CH" "$TMP/ch-ss.bak"
ky_vong 0 "fixture đủ cấu hình, test xanh → SẴN SÀNG" sh "$SS" "$F"
dung "…in bước tiếp" sh -c "sh '$SS' '$F' 2>/dev/null | grep -q '^Bước tiếp: '"
ky_vong 2 "thiếu thư mục feature → SAI THAM SỐ" sh "$SS"
printf 'TEST_CMD="echo LOI-CO-SAN; false"\n%s\n' "$BM_XANH" > "$CH"
ky_vong 1 "test ĐỎ trên code hiện tại → CHƯA SẴN SÀNG" sh "$SS" "$F"
dung "…in output thật của lệnh test" sh -c "sh '$SS' '$F' 2>/dev/null | grep -q 'LOI-CO-SAN'"
ky_vong 0 "--no-test: không chạy test, chỉ kiểm đã khai" sh "$SS" "$F" --no-test
printf 'TEST_CMD="true"\n' > "$CH"
ky_vong 1 "chưa khai SECURITY_CMDS → CHƯA SẴN SÀNG" sh "$SS" "$F"
printf 'TEST_CMD=""\n%s\n' "$BM_XANH" > "$CH"
ky_vong 1 "chưa khai TEST_CMD → CHƯA SẴN SÀNG" sh "$SS" "$F" --no-test
cp "$TMP/ch-ss.bak" "$CH"
thay "$CFG/conventions.md" 'test_files: ' 'mau_file_test_cu: '
ky_vong 1 "conventions.md thiếu test_files → CHƯA SẴN SÀNG" sh "$SS" "$F"
thay "$CFG/conventions.md" 'mau_file_test_cu: ' 'test_files: '

# ---------------------------------------------------------------- aw conventions check (check-conventions.sh)
echo ""
echo "check-conventions.sh (aw conventions check)"
QU="$T/check-conventions.sh"; CV="$CFG/conventions.md"; cp "$CV" "$TMP/conv-qu.bak"
qu_ra() { sh "$QU" 2>/dev/null; }
ky_vong 0 "mẫu của engine trên fixture → HỢP LỆ" sh "$QU"
dung "…cảnh báo placeholder còn trong Team conventions" sh -c "sh '$QU' 2>/dev/null | grep -q 'còn placeholder'"
ky_vong 2 "thừa tham số → SAI THAM SỐ" sh "$QU" x
ky_vong 0 "aw-engine conventions check" sh "$ROOT/bin/aw-engine" conventions check
ky_vong 2 "aw-engine conventions <lạ> → SAI THAM SỐ" sh "$ROOT/bin/aw-engine" conventions lam-gi
# qu_loi <tên ca> <tìm> <thay> <chuỗi phải có trong output>
qu_loi() {
  cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" "$2" "$3"
  ky_vong 1 "$1 → KHÔNG HỢP LỆ" sh "$QU"
  dung "…nêu: $4" sh -c "sh '$QU' 2>/dev/null | grep -qF -- \"\$1\"" _ "$4"
}
qu_loi "khoá gõ sai" 'test_files: ' 'test_file: ' 'khoá lạ "test_file"'
qu_loi "khoá tên cũ (tiếng Việt)" 'base_branch: main' 'base_branch: main
nhanh_goc: main' 'khoá lạ "nhanh_goc"'
qu_loi "khoá khai hai lần" 'base_branch: main' 'base_branch: main
base_branch: develop' 'khai lần hai'
qu_loi "dòng thụt lề" 'covers_tag: ' '  covers_tag: ' 'không phải "khoá: giá trị"'
qu_loi "rules_ phase lạ" 'rules_spec:' 'rules_spek:' 'khoá lạ "rules_spek"'
qu_loi "uses_ phase lạ" 'uses_spec:' 'uses_spek:' 'khoá lạ "uses_spek"'
qu_loi "uses_ khai skill không có" 'uses_implement:' 'uses_implement: skill:khong-co' 'uses "skill:khong-co"'
qu_loi "khoá bắt buộc trống" 'branch_patterns: feat_* fix_* refactor_* perf_* chore_*' 'branch_patterns:' 'branch_patterns trống'
qu_loi "mr_platform sai" 'mr_platform:' 'mr_platform: bitbucket' 'chỉ nhận github hoặc gitlab'
qu_loi "type_by_prefix loại sai" 'perf_=perf' 'perf_=toc-do' 'loại "toc-do" không hợp lệ'
qu_loi "type_by_prefix lệch branch_patterns" 'perf_=perf' 'hieu-nang/=perf' 'không khớp branch_patterns'
qu_loi "regex dùng {n}" 'jira_key_regex: [A-Z][A-Z0-9]*-[0-9]+' 'jira_key_regex: [A-Z]{2}-[0-9]+' 'không dùng {n}'
qu_loi "regex không biên dịch" 'skipped_test_regex:' 'skipped_test_regex: (abc' 'không biên dịch được'
qu_loi "worktree_dir trong repo" 'worktree_dir: ../{repo}.wt/{ten}' 'worktree_dir: wt/{ten}' 'nằm TRONG repo'
qu_loi "worktree_dir thiếu {ten}" 'worktree_dir: ../{repo}.wt/{ten}' 'worktree_dir: ../{repo}.wt' 'thiếu {ten}'
qu_loi "knowledge_adr_dir ngoài repo" 'knowledge_adr_dir: docs/adr' 'knowledge_adr_dir: ../adr' 'phải là đường dẫn tương đối'
qu_loi "knowledge_adr_dir trong .agent-workflow" 'knowledge_adr_dir: docs/adr' 'knowledge_adr_dir: .agent-workflow/adr' 'bị exclude'
qu_loi "knowledge_rules_dir ngoài repo" 'knowledge_rules_dir: docs/product/rules' 'knowledge_rules_dir: /tmp/rules' 'phải là đường dẫn tương đối'
qu_loi "base_branch không có" 'base_branch: main' 'base_branch: khong-co' 'không có trong repo'
qu_loi "khối chưa đóng" 'uses_review:
```' 'uses_review:' 'chưa đóng'
cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" 'sensitive_code:
' ''
ky_vong 0 "thiếu khoá có trong mẫu → vẫn HỢP LỆ" sh "$QU"
dung "…cảnh báo thiếu khoá sensitive_code" sh -c "sh '$QU' 2>/dev/null | grep -q '! thiếu khoá sensitive_code'"
cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" 'production_code: src/*' 'production_code: app/*'
dung "production_code không khớp file nào → cảnh báo" sh -c "sh '$QU' 2>/dev/null | grep -q 'production_code \"app/\*\" không khớp file nào'"
cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" 'production_code: src/*' 'production_code: src/* test/*'
dung "file khớp cả test_files lẫn production_code → cảnh báo" sh -c "sh '$QU' 2>/dev/null | grep -q 'khớp cả test_files lẫn production_code'"
cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" 'mr_platform:' 'mr_platform: bitbucket'
ky_vong 1 "aw ready: conventions.md sai → CHƯA SẴN SÀNG" sh "$SS" "$F" --no-test
dung "…nêu lỗi của aw conventions check" sh -c "sh '$SS' '$F' --no-test 2>/dev/null | grep -q 'conventions.md: mr_platform'"
cp "$TMP/conv-qu.bak" "$CV"

# ---------------------------------------------------------------- quy ước đã commit (qu_hieu_luc)
echo ""
echo "conventions.md trong repo đích + bản clone chỉ ghi đè khoá máy"
dung "repo chỉ có quy ước ở bản clone → vẫn HỢP LỆ, cảnh báo chưa commit vào repo" sh -c "sh '$QU' 2>/dev/null | grep -q '! quy ước chưa commit vào repo'"
RQ="$TMP/repo-qu"; CQ="$RQ/.git/agent-workflow"; DQ="docs/agent-workflow/conventions.md"
gq() { git -C "$RQ" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
mkdir -p "$RQ/src" "$RQ/test"; gq init -q; gq checkout -q -b main; mkdir -p "$CQ"
printf 'goc\n' > "$RQ/src/a.txt"; printf 'x\n' > "$RQ/test/a.test.js"
gq add -A; gq commit -q -m "chua co quy uoc"; GOCQ0=$(git -C "$RQ" rev-parse main)
mkdir -p "$RQ/docs/agent-workflow"; cp "$ROOT/workflow/templates/conventions.md" "$RQ/$DQ"
thay "$RQ/$DQ" 'sensitive_code:' 'sensitive_code: src/auth/*'
gq add -A; gq commit -q -m "quy uoc"
# hl <thư-mục> <khoá> -> giá trị trong conventions.md hiệu lực của thư mục đó
hl() { (AW_REPO="$1"; AW_CONFIG="$CQ"; export AW_REPO AW_CONFIG; . "$T/lib/md.sh"; conv_get "$(qu_hieu_luc "$1")" "$2"); }
quq() { (cd "$1" && AW_REPO="$1" AW_CONFIG="$CQ" sh "$QU" 2>&1); }
dung "đọc quy ước đã commit, không cần bản clone" bang "$(hl "$RQ" sensitive_code)" "src/auth/*"
ky_vong 0 "…aw conventions check → HỢP LỆ" quq "$RQ"
dung "…không còn cảnh báo chưa commit" sh -c "! (cd '$RQ' && AW_REPO='$RQ' AW_CONFIG='$CQ' sh '$QU' 2>/dev/null | grep -q 'chưa commit vào repo')"
printf '```conventions\nworktree_dir: ../wt-rieng/{ten}\n```\n' > "$CQ/conventions.md"
dung "bản clone ghi đè worktree_dir" bang "$(hl "$RQ" worktree_dir)" "../wt-rieng/{ten}"
dung "…khoá khác vẫn lấy từ repo" bang "$(hl "$RQ" sensitive_code)" "src/auth/*"
ky_vong 0 "…aw conventions check → HỢP LỆ" quq "$RQ"
printf '```conventions\nworktree_dir: ../wt-rieng/{ten}\nsensitive_code:\n```\n' > "$CQ/conventions.md"
ky_vong 1 "bản clone khai khoá ngoài khoá máy → KHÔNG HỢP LỆ" quq "$RQ"
dung "…nêu khoá đó chỉ được khai trong file đã commit" sh -c "(cd '$RQ' && AW_REPO='$RQ' AW_CONFIG='$CQ' sh '$QU' 2>/dev/null) | grep -qF 'khoá \"sensitive_code\" chỉ được khai trong $DQ'"
dung "…và không có hiệu lực: sensitive_code vẫn theo repo" bang "$(hl "$RQ" sensitive_code)" "src/auth/*"
rm -f "$CQ/conventions.md"
# worktree: luật của việc = quy ước tại điểm rẽ khỏi base ghi trong intake.md
WQ="$TMP/repo-qu.wt/feat_q"; gq worktree add -q -b feat_q "$WQ" main
mkdir -p "$WQ/.agent-workflow/feat_q"
printf -- '- **Base:** `main` `%s`\n' "$(git -C "$RQ" rev-parse main)" > "$WQ/.agent-workflow/feat_q/intake.md"
thay "$WQ/$DQ" 'sensitive_code: src/auth/*' 'sensitive_code:'
git -C "$WQ" -c user.name=t -c user.email=t@t commit -qam "noi luat" >/dev/null 2>&1
dung "worktree: việc sửa quy ước (kể cả commit) không đổi luật của chính nó" bang "$(hl "$WQ" sensitive_code)" "src/auth/*"
thay "$RQ/$DQ" 'sensitive_code: src/auth/*' 'sensitive_code: src/pay/*'
dung "…sửa ở checkout chính cũng không đổi luật của việc đang làm" bang "$(hl "$WQ" sensitive_code)" "src/auth/*"
dung "checkout chính đọc cây làm việc của nó" bang "$(hl "$RQ" sensitive_code)" "src/pay/*"
WQ2="$TMP/repo-qu.wt/feat_cu"; gq worktree add -q -b feat_cu "$WQ2" "$GOCQ0"
mkdir -p "$WQ2/.agent-workflow/feat_cu"
printf -- '- **Base:** `main` `%s`\n' "$GOCQ0" > "$WQ2/.agent-workflow/feat_cu/intake.md"
dung "việc rẽ từ base chưa có quy ước → đọc bản ở checkout chính" bang "$(hl "$WQ2" sensitive_code)" "src/pay/*"
rm -f "$WQ2/.agent-workflow/feat_cu/intake.md"
dung "worktree chưa có intake.md → đọc bản ở checkout chính" bang "$(hl "$WQ2" sensitive_code)" "src/pay/*"
ky_vong 0 "aw adapter build trong worktree" sh -c "AW_REPO='$WQ' AW_CONFIG='$CQ' sh '$T/adapter-build.sh' claude-code '$WQ'"
dung "….engine/conventions.md là quy ước hiệu lực của việc" grep -q '^sensitive_code: src/auth/\*' "$WQ/.agent-workflow/.engine/conventions.md"
cp "$RQ/$DQ" "$TMP/qu-repo.bak"
ky_vong 0 "aw init ở repo đã có quy ước" sh -c "AW_REPO='$RQ' AW_CONFIG='$CQ' AW_ENGINE='$ROOT' sh '$ROOT/bin/aw-engine' init --test-cmd true"
dung "…không tạo bản clone, không đụng file của repo" sh -c "[ ! -f '$CQ/conventions.md' ] && cmp -s '$TMP/qu-repo.bak' '$RQ/$DQ'"
# mẫu cho repo đích: AGENTS.md (điểm vào), Makefile (lệnh kiểm trong git)
MAUD="$ROOT/workflow/templates/target-repo"
dung "aw init nhắc tạo AGENTS.md khi repo chưa có" sh -c "AW_REPO='$RQ' AW_CONFIG='$CQ' AW_ENGINE='$ROOT' sh '$ROOT/bin/aw-engine' init 2>&1 | grep -q 'Repo chưa có AGENTS.md'"
printf '# AGENTS.md\n' > "$RQ/AGENTS.md"
dung "…không nhắc khi đã có" sh -c "! (AW_REPO='$RQ' AW_CONFIG='$CQ' AW_ENGINE='$ROOT' sh '$ROOT/bin/aw-engine' init 2>&1 | grep -q 'Repo chưa có AGENTS.md')"
rm -f "$RQ/AGENTS.md"
dung "mẫu AGENTS.md, Makefile có trong .agent-workflow/.engine/templates/target-repo/" sh -c "[ -f '$WQ/.agent-workflow/.engine/templates/target-repo/AGENTS.md' ] && [ -f '$WQ/.agent-workflow/.engine/templates/target-repo/Makefile' ]"
dung "mẫu AGENTS.md (bỏ chú thích) ≤ 100 dòng, có đủ mục cho phiên mới" sh -c "n=\$(sed '/^<!--/,/^-->/d' '$MAUD/AGENTS.md' | wc -l) && [ \$n -le 100 ] && for h in Map Commands Rules Decisions Status; do grep -q \"^## \$h\$\" '$MAUD/AGENTS.md' || exit 1; done"
if command -v make >/dev/null 2>&1; then
  mkdir -p "$TMP/mk"; cp "$MAUD/Makefile" "$TMP/mk/"
  ky_vong 2 "mẫu Makefile: target chưa khai → thất bại, không bao giờ xanh" make -s -C "$TMP/mk" test
  ky_vong 2 "…make security cũng thất bại khi nhóm nào chưa khai" make -s -C "$TMP/mk" security
fi
RQC="$TMP/repo-qu-cu"; mkdir -p "$RQC"; git -C "$RQC" init -q; mkdir -p "$RQC/.git/agent-workflow"
printf '# của tôi\n' > "$RQC/.git/agent-workflow/conventions.md"
ky_vong 0 "aw init ở repo chỉ có quy ước trong bản clone (init bằng engine cũ)" sh -c "AW_REPO='$RQC' AW_CONFIG='$RQC/.git/agent-workflow' AW_ENGINE='$ROOT' sh '$ROOT/bin/aw-engine' init --test-cmd true"
dung "…giữ nguyên bản clone, không tạo file trong repo" sh -c "grep -q 'của tôi' '$RQC/.git/agent-workflow/conventions.md' && [ ! -e '$RQC/$DQ' ]"
# tk_plan_t2 <dòng Verify + Status> — plan gốc, thay riêng hai dòng cuối của T-02
tk_plan_t2() { viet_plan; ghi_based_on; thay "$F/plan.md" '- Verify: `test -f src/a.txt` → có file
- Status: `[x]`

## Deferred' "$1

## Deferred"; }
tk_plan_t2 '- Verify: `test -f src/a.txt` → có file
- Status: `[ ]`'
dung "tiến độ: bước tiếp chỉ đúng task kế" sh -c "sh '$SS' '$F' 2>/dev/null | grep -q 'Bước tiếp: /aw-implement — task tiếp: T-02'"

# ---------------------------------------------------------------- aw task (task.sh)
echo ""
echo "task.sh (aw task)"
TK="$T/task.sh"; HT="$T/check-implement.sh"
dung "next → T-02 (stdout)" bang "$(sh "$TK" next "$F" 2>/dev/null)" "T-02"
ky_vong 1 "implement chặn task chưa làm [ ]" sh "$HT" "$F"
dung "…đúng lý do" sh -c "sh '$HT' '$F' | grep -q 'T-02 chưa làm'"
ky_vong 1 "done khi chưa start → TỪ CHỐI" sh "$TK" done "$F" T-02
ky_vong 0 "start T-02 → [~]" sh "$TK" start "$F" T-02
dung "…plan.md ghi [~]" grep -q '^- Status: `\[~\]`' "$F/plan.md"
ky_vong 0 "start lại task đang [~] → không lỗi" sh "$TK" start "$F" T-02
ky_vong 1 "start task đã [x] → TỪ CHỐI" sh "$TK" start "$F" T-01
thay "$F/plan.md" '- Based on: `D-01`
- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[x]`' '- Based on: `D-01`
- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[ ]`'
ky_vong 1 "WIP=1: start task khác khi T-02 đang [~] → TỪ CHỐI" sh "$TK" start "$F" T-01
dung "next ưu tiên task đang [~]" bang "$(sh "$TK" next "$F" 2>/dev/null)" "T-02"
ky_vong 1 "implement chặn task [~]" sh "$HT" "$F"
ky_vong 0 "done T-02, Verify xanh → [x]" sh "$TK" done "$F" T-02
dung "…ghi bằng chứng xanh vào task-results.md" sh -c "grep -q '^## T-02' '$F/task-results.md' && awk '/^## T-02/{p=1} p && /Mã thoát/{print; exit}' '$F/task-results.md' | grep -q '\`0\`'"
ky_vong 0 "start T-01 sau khi T-02 xong" sh "$TK" start "$F" T-01
ky_vong 0 "done T-01" sh "$TK" done "$F" T-01
ky_vong 4 "mọi task [x] → next HẾT TASK" sh "$TK" next "$F"
ky_vong 0 "implement ĐẠT khi mọi task xong bằng máy" sh "$HT" "$F"

viet_plan; ghi_based_on
mv "$F/task-results.md" "$TMP/kqt.bak"
ky_vong 1 "implement chặn [x] tự đánh, không có bằng chứng" sh "$HT" "$F"
dung "…đúng lý do, chỉ lệnh sửa" sh -c "sh '$HT' '$F' | grep -q 'không có bằng chứng.*aw task done'"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review
ky_vong 1 "review cũng chặn [x] không có bằng chứng" sh "$T/check-review.sh" "$F"
mv "$TMP/kqt.bak" "$F/task-results.md"
thay "$F/plan.md" '- Expected files: `src/b.txt`
- Verify: `test -f src/a.txt`' '- Expected files: `src/b.txt`
- Verify: `test -d src`'
ky_vong 1 "implement chặn khi Verify đổi sau khi task xong" sh "$HT" "$F"
dung "…đúng lý do" sh -c "sh '$HT' '$F' | grep -q 'T-02: lệnh Verify trong plan.md đã đổi'"

# Đỏ liên tiếp → DỪNG (điều kiện dừng của vòng lặp)
viet_plan; ghi_based_on
tk_plan_t2 '- Verify: `echo VERIFY-DO; false` → xanh
- Status: `[ ]`'
sh "$TK" start "$F" T-02 >/dev/null 2>&1
ky_vong 1 "done, Verify đỏ → giữ [~]" sh "$TK" done "$F" T-02
dung "…ghi output đỏ thật" grep -q 'VERIFY-DO' "$F/task-results.md"
dung "…đỏ liên tiếp: 1" bang "$(sh -c ". '$T/lib/task.sh'; tk_bc '$F/task-results.md' T-02 'Đỏ liên tiếp'")" "1"
ky_vong 1 "đỏ lần 2" sh "$TK" done "$F" T-02
ky_vong 6 "đỏ lần 3 = MAX_RED_RUNS mặc định → DỪNG" sh "$TK" done "$F" T-02
ky_vong 6 "next cũng DỪNG ở task đó" sh "$TK" next "$F"
printf 'MAX_RED_RUNS=5\n' >> "$CFG/config.sh"
ky_vong 0 "MAX_RED_RUNS=5 → next còn cho làm" sh "$TK" next "$F"
cp "$TMP/ch-ss.bak" "$CFG/config.sh"
tk_plan_t2 '- Verify: `test -f src/a.txt` → xanh
- Status: `[~]`'
ky_vong 0 "sửa xong, Verify xanh → [x]" sh "$TK" done "$F" T-02
dung "…xanh thì đỏ liên tiếp về 0" bang "$(sh -c ". '$T/lib/task.sh'; tk_bc '$F/task-results.md' T-02 'Đỏ liên tiếp'")" "0"

# Kiểm chứng thủ công
tk_plan_t2 '- Verify: mở màn hình y thấy b
- Status: `[~]`'
ky_vong 1 "Verify không có lệnh, không --manual → TỪ CHỐI" sh "$TK" done "$F" T-02
ky_vong 1 "--manual bằng chứng giữ chỗ → TỪ CHỐI" sh "$TK" done "$F" T-02 --manual "<bằng chứng>"
ky_vong 0 "--manual có bằng chứng → [x]" sh "$TK" done "$F" T-02 --manual "mở y, thấy b ở góc phải"
dung "implement ĐẠT kèm lưu ý task thủ công" sh -c "sh '$HT' '$F' | grep -q 'LƯU Ý.*thủ công: T-02'"
tk_plan_t2 '- Verify: `true` → xanh
- Status: `[~]`'
ky_vong 1 "--manual khi Verify có lệnh → TỪ CHỐI" sh "$TK" done "$F" T-02 --manual "đã xem"

# Phụ thuộc
viet_plan; ghi_based_on
thay "$F/plan.md" '- Status: `[x]`' '- Status: `[ ]`'
thay "$F/plan.md" '- Status: `[x]`' '- Status: `[ ]`'
thay "$F/plan.md" '- Covers: `YC-002`' '- Covers: `YC-002`
- Depends on: T-01'
ky_vong 1 "start task phụ thuộc chưa [x] → TỪ CHỐI" sh "$TK" start "$F" T-02
dung "next chọn T-01 trước" bang "$(sh "$TK" next "$F" 2>/dev/null)" "T-01"
thay "$F/plan.md" '- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[ ]`' '- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[~]`'
ky_vong 2 "task không có trong plan.md: sai mã → SAI THAM SỐ" sh "$TK" start "$F" X-1
ky_vong 1 "task không có trong plan.md → TỪ CHỐI" sh "$TK" start "$F" T-09
viet_plan; ghi_based_on; ghi_bang_chung_task

# ---------------------------------------------------------------- trạng thái sạch
echo ""
echo "trạng thái sạch (implement/review)"
sh "$HT" "$F" >/dev/null 2>&1; ghi_tree_review
ky_vong 0 "fixture sạch → review ĐẠT" sh "$T/check-review.sh" "$F"
printf 'moi\n<<<<<<< HEAD\nx\n=======\ny\n>>>>>>> feat\n' > "$R/src/a.txt"
ky_vong 1 "implement chặn dấu xung đột merge" sh "$HT" "$F"
dung "…chỉ đúng file:dòng" sh -c "sh '$HT' '$F' | grep -q 'src/a.txt:2: còn dấu xung đột merge'"
printf 'moi\n' > "$R/src/a.txt"
printf '// covers: YC-001, YC-002\nit.only("a", () => {})\n' > "$R/test/a.test.js"
ky_vong 0 "test mới .only chỉ CẢNH BÁO ở implement" sh "$HT" "$F"
dung "…có in cảnh báo" sh -c "sh '$HT' '$F' | grep -q 'CẢNH BÁO.*test/a.test.js: thêm test bị bỏ qua'"
ghi_tree_review
ky_vong 1 "…review CHẶN" sh "$T/check-review.sh" "$F"
thay "$F/plan.md" '| Task | What came up | Extra files | Resolution |
|---|---|---|---|' '| Task | What came up | Extra files | Resolution |
|---|---|---|---|
| T-01 | test a chỉ chạy được riêng | `test/a.test.js` | người quyết |'
dung "khai file ở Unplanned → hết cảnh báo" sh -c "! sh '$HT' '$F' | grep -q 'thêm test bị bỏ qua'"
viet_plan; ghi_based_on
g checkout -q main
printf '// covers: YC-001, YC-002\nit.skip("cu", () => {})\n' > "$R/test/a.test.js"; g add test; g commit -q -m "test cu"
g checkout -q feat_x; g rebase -q --autostash main
dung "dòng .skip có sẵn trên base không tính (chỉ dòng thêm mới)" sh -c "! sh '$HT' '$F' | grep -q 'thêm test bị bỏ qua'"
thay "$CFG/conventions.md" 'skipped_test_regex:' 'skipped_test_regex: SKIPME'
printf 'SKIPME\n' >> "$R/test/a.test.js"
dung "skipped_test_regex riêng của repo được dùng" sh -c "sh '$HT' '$F' | grep -q 'thêm test bị bỏ qua / chạy riêng (SKIPME)'"
thay "$CFG/conventions.md" 'skipped_test_regex: SKIPME' 'skipped_test_regex:'

# ---------------------------------------------------------------- nhật ký harness (aw journal)
echo ""
echo "journal.sh (aw journal)"
NK="$T/journal.sh"; JD="$CFG/journal"
tao_fixture
rm -rf "$JD"
ky_vong 0 "aw-engine check vẫn ĐẠT qua nhật ký" sh "$AWE" check plan "$F"
dung "…ghi một dòng checks.tsv" sh -c "awk -F'\t' '\$3 == \"plan\" && \$4 == 0' '$JD/checks.tsv' | grep -q ."
dung "…stdout của checker vẫn chảy ra" sh -c "sh '$AWE' check plan '$F' 2>/dev/null | grep -q 'ĐẠT'"
thay "$F/plan.md" '`YC-002`' '`YC-999`'
ky_vong 1 "check KHÔNG ĐẠT giữ mã thoát qua nhật ký" sh "$AWE" check plan "$F"
dung "…ghi vi phạm đầu tiên" sh -c "awk -F'\t' '\$3 == \"plan\" && \$4 == 1 && \$5 != \"\"' '$JD/checks.tsv' | grep -q YC-999"
viet_plan; ghi_based_on
n0=$(wc -l < "$JD/checks.tsv")
AW_JOURNAL=0 sh "$AWE" check plan "$F" >/dev/null 2>&1
dung "AW_JOURNAL=0 → không ghi" bang "$(wc -l < "$JD/checks.tsv")" "$n0"
ky_vong 0 "journal add env" sh "$NK" add env "thiếu node_modules trong worktree mới"
dung "…ghi failures.tsv đúng lớp" sh -c "awk -F'\t' '\$3 == \"env\"' '$JD/failures.tsv' | grep -q node_modules"
ky_vong 2 "journal add lớp lạ → SAI THAM SỐ" sh "$NK" add mood "buồn"
ky_vong 2 "journal add thiếu mô tả → SAI THAM SỐ" sh "$NK" add env ""
ky_vong 0 "journal report" sh "$NK"
dung "…có ba phần" sh -c "sh '$NK' 2>/dev/null | grep -q 'Thất bại theo lớp' && sh '$NK' 2>/dev/null | grep -q 'Checker (aw check)' && sh '$NK' 2>/dev/null | grep -q 'Finding của review'"
viet_review; thay "$F/review.md" '- None' "$L3_SF"; ghi_tree_review
ky_vong 0 "review ĐẠT ghi finding theo Category" sh "$T/check-review.sh" "$F"
dung "…findings.tsv có duplicate-code" sh -c "awk -F'\t' '\$4 == \"duplicate-code\"' '$JD/findings.tsv' | grep -q ."
sh "$T/check-review.sh" "$F" >/dev/null 2>&1
dung "review chạy lại không nhân đôi" bang "$(awk -F'\t' '$4 == "duplicate-code"' "$JD/findings.tsv" | wc -l | tr -d ' ')" "1"
F2="$R/.agent-workflow/feat_y"; cp -R "$F" "$F2"
dung "loại lặp ở việc thứ hai → GỢI Ý nâng thành luật" sh -c "sh '$T/check-review.sh' '$F2' | grep -q 'GỢI Ý.*duplicate-code.*2 việc'"
dung "report đánh dấu loại lặp lại" sh -c "sh '$NK' 2>/dev/null | grep -q 'duplicate-code.*lặp lại'"
rm -rf "$F2"; viet_review

# ---------------------------------------------------------------- ADR (aw adr, aw knowledge)
echo ""
echo "ADR: D-xx đã duyệt nâng thành kiến thức bền"
tao_fixture
AD="$T/adr.sh"; KT="$T/knowledge.sh"; TK="$T/check-design.sh"; PK="$T/check-plan.sh"
A1="$R/docs/adr/0001-feat_x-d-01.md"
# sua_d <tìm> <thay> — sửa D trong tdd.md, người duyệt lại bản mới (giữ tick, bỏ dấu cũ)
sua_d() { thay "$F/tdd.md" "$1" "$2"; duyet_lai "$F/tdd.md"; ghi_based_on 2>/dev/null; }
sua_d '- Choice: file' '- Choice: file
- Promote: adr'
ky_vong 1 "design: Promote: adr thiếu Scope → KHÔNG ĐẠT" sh "$TK" "$F"
dung "…nêu thiếu Scope" sh -c "sh '$TK' '$F' | grep -q 'D-01: \"Promote: adr\" cần'"
sua_d '- Promote: adr' '- Promote: adr
- Scope: `src/*`'
ky_vong 0 "…có Scope → ĐẠT" sh "$TK" "$F"
sua_d '- Promote: adr' '- Promote: co'
ky_vong 1 "design: Promote giá trị lạ → KHÔNG ĐẠT" sh "$TK" "$F"
sua_d '- Promote: co' '- Promote: adr
- Supersedes: ADR-0009'
ky_vong 1 "design: Supersedes trỏ về ADR không có → KHÔNG ĐẠT" sh "$TK" "$F"
sua_d '- Supersedes: ADR-0009
' ''
ky_vong 1 "plan: D Promote: adr chưa có task nâng ADR → KHÔNG ĐẠT" sh "$PK" "$F"
dung "…nêu thiếu task" sh -c "sh '$PK' '$F' | grep -q 'D-01 khai Promote: adr nhưng không task nào'"
thay "$F/plan.md" '- Expected files: `src/*` `test/*`' '- Expected files: `src/*` `test/*` `docs/adr/*`'; ghi_based_on 2>/dev/null
ky_vong 0 "…task Based on D-01 có docs/adr/* → ĐẠT" sh "$PK" "$F"
ky_vong 2 "promote D không có → SAI THAM SỐ" sh "$AD" promote "$F" D-09
thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
ky_vong 1 "promote D chưa duyệt → TỪ CHỐI" sh "$AD" promote "$F" D-01
dung "…không ghi gì" test ! -e "$R/docs/adr"
thay "$F/tdd.md" '- [ ] **Approved by human**' '- [x] **Approved by human**'
ky_vong 0 "promote D-01 đã duyệt, Promote: adr → ĐÃ NÂNG" sh "$AD" promote "$F" D-01
dung "…ADR chép nội dung D, Origin, Scope" sh -c "grep -qx '# ADR-0001: lưu ở đâu' '$A1' && grep -qF -- '- Origin: \`feat_x\` § D-01' '$A1' && grep -qF -- '- Scope: \`src/*\`' '$A1' && grep -qF -- '- Choice: file' '$A1' && ! grep -q 'Promote' '$A1'"
dung "…nguồn = Source của YC mà task Based on D-01 phủ" grep -qF -- '- YC-001 (`feat_x`): `[JIRA]` ABC-1' "$A1"
dung "…chỉ mục có dòng của ADR" grep -qF '| [0001](0001-feat_x-d-01.md) | lưu ở đâu | accepted | `src/*` |' "$R/docs/adr/README.md"
ky_vong 0 "promote lại → vẫn ĐÃ NÂNG" sh "$AD" promote "$F" D-01
dung "…giữ số cũ, không nhân đôi" bang "$(ls "$R/docs/adr" | tr '\n' ' ')" "0001-feat_x-d-01.md README.md "
ky_vong 0 "aw adr check → HỢP LỆ" sh "$AD" check
ky_vong 2 "aw adr lạ → SAI THAM SỐ" sh "$AD" lam-gi
ky_vong 0 "implement: ADR khớp D đã duyệt → ĐẠT" sh "$T/check-implement.sh" "$F"
thay "$A1" '- Choice: file' '- Choice: db'
ky_vong 1 "implement: ADR sửa tay lệch D → KHÔNG ĐẠT" sh "$T/check-implement.sh" "$F"
dung "…nêu lệch D-01" sh -c "sh '$T/check-implement.sh' '$F' 2>/dev/null | grep -q 'ADR: 0001-feat_x-d-01.md: lệch D-01'"
rm -f "$A1"
ky_vong 1 "implement: D Promote: adr chưa có ADR → KHÔNG ĐẠT" sh "$T/check-implement.sh" "$F"
ky_vong 1 "review: D Promote: adr chưa có ADR → KHÔNG ĐẠT" sh "$T/check-review.sh" "$F"
dung "…nêu lý do" sh -c "sh '$T/check-review.sh' '$F' 2>/dev/null | grep -q 'ADR: D-01 khai Promote: adr nhưng chưa có ADR'"
sh "$AD" promote "$F" D-01 >/dev/null 2>&1
cp "$A1" "$R/docs/adr/0001-ban-sao.md"
ky_vong 1 "adr check: trùng số → KHÔNG HỢP LỆ" sh "$AD" check
rm -f "$R/docs/adr/0001-ban-sao.md"
thay "$R/docs/adr/README.md" '| [0001](0001-feat_x-d-01.md)' '| [0009](0009-khac.md)'
ky_vong 1 "adr check: chỉ mục thiếu ADR → KHÔNG HỢP LỆ" sh "$AD" check
thay "$R/docs/adr/README.md" '| [0009](0009-khac.md)' '| [0001](0001-feat_x-d-01.md)'
thay "$A1" '- Status: accepted' '- Status: superseded by 0007'
ky_vong 1 "adr check: superseded by ADR không có → KHÔNG HỢP LỆ" sh "$AD" check
thay "$A1" '- Status: superseded by 0007' '- Status: accepted'
# D mới thay ADR cũ: người ghi Supersedes trong D, máy đổi trạng thái ADR cũ
thay "$F/tdd.md" '## Data model' '### D-02 — đổi chỗ lưu
- Author: `agent`
- Choice: db
- Promote: adr
- Scope: `src/*`
- Supersedes: ADR-0001
- [x] **Approved by human**

## Data model'
ky_vong 0 "promote D-02 (Supersedes: ADR-0001) → ĐÃ NÂNG" sh "$AD" promote "$F" D-02
dung "…ADR cũ thành superseded by 0002, chỉ mục cập nhật" sh -c "grep -qx -- '- Status: superseded by 0002' '$A1' && grep -qF '| superseded by 0002 |' '$R/docs/adr/README.md' && grep -qF -- '- Supersedes: ADR-0001' '$R/docs/adr/0002-feat_x-d-02.md'"
ky_vong 0 "…aw adr check HỢP LỆ" sh "$AD" check
ky_vong 0 "design vẫn ĐẠT khi ADR cũ đã bị chính việc này thay" sh "$TK" "$F"
# aw knowledge design: chỉ mục, ADR accepted đúng phạm vi, tài liệu module cha
mkdir -p "$R/lib"; printf '# src\n' > "$R/src/ARCHITECTURE.md"; printf '# lib\n' > "$R/lib/ARCHITECTURE.md"
g add src/ARCHITECTURE.md lib/ARCHITECTURE.md; g commit -q -m "tai lieu module"
dung "knowledge design: chưa có đường dẫn trong Existing code → chỉ in chỉ mục ADR" bang "$(sh "$KT" design "$F" 2>/dev/null)" "docs/adr/README.md"
thay "$F/tdd.md" 'Module src/a.' 'Module `src/a.txt`.'
dung "…có đường dẫn → thêm ADR accepted khớp Scope, tài liệu module cha; bỏ ADR đã bị thay, module khác" bang "$(sh "$KT" design "$F" 2>/dev/null | tr '\n' ' ')" "docs/adr/README.md docs/adr/0002-feat_x-d-02.md src/ARCHITECTURE.md "
ky_vong 2 "knowledge phase chưa hỗ trợ → SAI THAM SỐ" sh "$KT" plan "$F"
tao_fixture

# ---------------------------------------------------------------- luật nghiệp vụ (aw rule)
echo ""
echo "Luật nghiệp vụ BR-: YC đã duyệt nâng thành kiến thức bền"
tao_fixture
LU="$T/rule.sh"; SK="$T/check-spec.sh"; PK="$T/check-plan.sh"
LF="$R/docs/product/rules/billing.md"
# sua_spec <tìm> <thay> — sửa spec, người duyệt lại bản mới
sua_spec() { thay "$F/spec.md" "$1" "$2"; duyet_lai "$F/spec.md"; ghi_based_on 2>/dev/null; }
sua_spec '- Priority: `must`' '- Priority: `must`
- Description: luôn mở được y
- Promote: BR-billing-1'
ky_vong 1 "spec: Promote sai dạng ID → KHÔNG ĐẠT" sh "$SK" "$F"
dung "…nêu dạng đúng" sh -c "sh '$SK' '$F' | grep -q 'dạng BR-<MIỀN>-NNN'"
sua_spec '- Promote: BR-billing-1' '- Promote: BR-BILLING-001'
ky_vong 0 "spec: Promote: BR-BILLING-001 trên YC nguồn [JIRA] → ĐẠT" sh "$SK" "$F"
sua_spec '- Priority: `should`' '- Priority: `should`
- Promote: BR-BILLING-002'
ky_vong 1 "spec: Promote trên YC [OPEN-QUESTION] → KHÔNG ĐẠT" sh "$SK" "$F"
sua_spec '- Priority: `should`
- Promote: BR-BILLING-002' '- Priority: `should`'
ky_vong 1 "plan: YC Promote chưa có task ghi file luật → KHÔNG ĐẠT" sh "$PK" "$F"
dung "…nêu file đích" sh -c "sh '$PK' '$F' | grep -q 'docs/product/rules/billing.md'"
thay "$F/plan.md" '- Expected files: `src/*` `test/*`' '- Expected files: `src/*` `test/*` `docs/product/rules/billing.md`'; ghi_based_on 2>/dev/null
ky_vong 0 "…task phủ YC-001 có file luật → ĐẠT" sh "$PK" "$F"
ky_vong 1 "promote: nguồn [JIRA] chưa có phiên bản trong ## Sources → TỪ CHỐI" sh "$LU" promote "$F" YC-001
dung "…không ghi gì" test ! -e "$LF"
sua_spec '## Requirements' '## Sources

| # | Type | Identifier | Version | Read on |
|---|---|---|---|---|
| 1 | Jira | ABC-1 | updated 2026-10-01 | 2026-10-02 |

## Requirements'
thay "$F/spec.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
ky_vong 1 "promote: spec chưa duyệt → TỪ CHỐI" sh "$LU" promote "$F" YC-001
thay "$F/spec.md" '- [ ] **Approved by human**' '- [x] **Approved by human**'
ky_vong 1 "promote: YC không khai Promote → TỪ CHỐI" sh "$LU" promote "$F" YC-002
ky_vong 0 "promote YC-001 → ĐÃ NÂNG" sh "$LU" promote "$F" YC-001
dung "…khối chép YC: tên, Rule, Scope (bỏ file test, file luật), Source có phiên bản, tiêu chí, Origin" sh -c "grep -qx '### BR-BILLING-001: a' '$LF' && grep -qxF -- '- Rule: luôn mở được y' '$LF' && grep -qxF -- '- Scope: \`src/*\`' '$LF' && grep -qxF -- '- Source: \`[JIRA]\` ABC-1 (version: updated 2026-10-01)' '$LF' && grep -qxF -- '  - mở y thấy a' '$LF' && grep -qxF -- '- Origin: \`feat_x\` § YC-001' '$LF' && grep -qxF -- '- Status: active' '$LF'"
ky_vong 0 "promote lại → vẫn ĐÃ NÂNG" sh "$LU" promote "$F" YC-001
dung "…viết lại tại chỗ, không nhân đôi" bang "$(grep -c '^### BR-BILLING-001' "$LF")" "1"
ky_vong 0 "aw rule check → HỢP LỆ" sh "$LU" check
dung "…cảnh báo luật active chưa có test covers" sh -c "sh '$LU' check 2>/dev/null | grep -q '! BR-BILLING-001'"
printf '// covers: YC-001, YC-002, BR-BILLING-001\n' > "$R/test/a.test.js"
dung "…test gắn covers: BR-BILLING-001 → hết cảnh báo" sh -c "! sh '$LU' check 2>/dev/null | grep -q '! BR-BILLING-001'"
ky_vong 0 "implement: khối luật khớp YC đã duyệt → ĐẠT" sh "$T/check-implement.sh" "$F"
thay "$LF" '- Rule: luôn mở được y' '- Rule: thỉnh thoảng mở được y'
ky_vong 1 "implement: khối luật sửa tay lệch YC → KHÔNG ĐẠT" sh "$T/check-implement.sh" "$F"
dung "…nêu lệch YC-001" sh -c "sh '$T/check-implement.sh' '$F' 2>/dev/null | grep -q 'Luật: docs/product/rules/billing.md: BR-BILLING-001 lệch YC-001'"
rm -f "$LF"
ky_vong 1 "review: YC Promote chưa có khối luật → KHÔNG ĐẠT" sh "$T/check-review.sh" "$F"
dung "…nêu lý do" sh -c "sh '$T/check-review.sh' '$F' 2>/dev/null | grep -q 'Luật: YC-001 khai Promote: BR-BILLING-001 nhưng chưa có khối luật'"
sh "$LU" promote "$F" YC-001 >/dev/null 2>&1
luat_khoi_sao() { awk '/^### BR-BILLING-001/ { t = 1 } t' "$LF"; }
printf '# khác\n\n%s\n' "$(luat_khoi_sao)" > "$R/docs/product/rules/khac.md"
ky_vong 1 "rule check: trùng ID ở hai file → KHÔNG HỢP LỆ" sh "$LU" check
rm -f "$R/docs/product/rules/khac.md"
thay "$LF" ' (version: updated 2026-10-01)' ''
ky_vong 1 "rule check: Source thiếu phiên bản → KHÔNG HỢP LỆ" sh "$LU" check
thay "$LF" '- Source: `[JIRA]` ABC-1' '- Source: `[JIRA]` ABC-1 (version: updated 2026-10-01)'
thay "$LF" '- Status: active' '- Status: superseded by BR-KHAC-009'
ky_vong 1 "rule check: superseded by luật không có → KHÔNG HỢP LỆ" sh "$LU" check
thay "$LF" '- Status: superseded by BR-KHAC-009' '- Status: active'
ky_vong 0 "…sửa lại → HỢP LỆ" sh "$LU" check
# Lời người đã ghi (câu trả lời điểm mù): nguồn [HUMAN] + Quote nguyên văn
thay "$F/open-questions.md" '- **Status:** `open`' '- **Status:** `answered`
- **Answer:** PO Lan, 2026-10-05: luôn hiện b'
sua_spec '- Source: `[OPEN-QUESTION]` → open-questions.md § YC-002' '- Source: `[FILE]` open-questions.md § YC-002
- Description: luôn hiện b
- Promote: BR-BILLING-002'
thay "$F/plan.md" '- Expected files: `src/b.txt`' '- Expected files: `src/b.txt` `docs/product/rules/billing.md`'; ghi_based_on 2>/dev/null
ky_vong 0 "promote YC-002 nguồn là câu trả lời của người → ĐÃ NÂNG" sh "$LU" promote "$F" YC-002
dung "…Source [HUMAN] có ngày làm phiên bản, Quote nguyên văn" sh -c "grep -qxF -- '- Source: \`[HUMAN]\` open-questions.md (\`feat_x\`) (version: 2026-10-05)' '$LF' && grep -qxF -- '- Quote: \"PO Lan, 2026-10-05: luôn hiện b\"' '$LF'"
dung "…hai luật cùng một file miền" bang "$(grep -c '^### BR-' "$LF")" "2"
# Việc khác chọn trùng ID → spec chặn
F2="$R/.agent-workflow/feat_y"; cp -R "$F" "$F2"
ky_vong 1 "spec của việc khác dùng ID đã có → KHÔNG ĐẠT" sh "$SK" "$F2"
dung "…nêu ID đã có" sh -c "sh '$SK' '$F2' | grep -q 'BR-BILLING-001 đã có trong docs/product/rules/billing.md'"
rm -rf "$F2"
# aw knowledge: spec in mọi file có luật active; design lọc theo Scope
dung "knowledge spec: in file có luật active" bang "$(sh "$KT" spec "$F" 2>/dev/null)" "docs/product/rules/billing.md"
thay "$F/tdd.md" 'Module src/a.' 'Module `src/a.txt`.'
dung "knowledge design: luật active có Scope khớp Existing code" sh -c "sh '$KT' design '$F' 2>/dev/null | grep -qx 'docs/product/rules/billing.md'"
thay "$F/tdd.md" 'Module `src/a.txt`.' 'Module `test/a.test.js`.'
dung "…Scope không khớp → không in" sh -c "! sh '$KT' design '$F' 2>/dev/null | grep -q 'billing.md'"
tao_fixture

# ---------------------------------------------------------------- kiến thức bền lỗi thời (kiểm chéo)
echo ""
echo "Kiểm chéo kiến thức bền ↔ diff: implement cảnh báo, review đòi verdict"
tao_fixture
HT="$T/check-implement.sh"; RS="$T/check-review.sh"
# Tài liệu nằm ở base: tài liệu module src/ (diff đụng src/a.txt) và lib/ (không đụng),
# ADR accepted phạm vi src/*, luật active phạm vi src/* chưa có test covers.
g checkout -q main
mkdir -p "$R/lib" "$R/docs/adr" "$R/docs/product/rules"
printf '# src\n' > "$R/src/ARCHITECTURE.md"; printf '# lib\n' > "$R/lib/ARCHITECTURE.md"
printf '# ADR-0001: x\n\n- Status: accepted\n- Scope: `src/*`\n\n## Decision\n\n- Choice: x\n' > "$R/docs/adr/0001-cu.md"
printf '# ADR\n\n| ADR | Title | Status | Scope |\n|---|---|---|---|\n| [0001](0001-cu.md) | x | accepted | `src/*` |\n' > "$R/docs/adr/README.md"
printf '# Business rules — kho\n\n### BR-KHO-001: y\n- Rule: y\n- Scope: `src/*`\n- Source: `[JIRA]` ABC-9 (version: v1)\n- Status: active\n- Acceptance:\n  - y\n' > "$R/docs/product/rules/kho.md"
g add src/ARCHITECTURE.md lib/ARCHITECTURE.md docs/adr docs/product; g commit -q -m "kien thuc ben"
g checkout -q feat_x; g merge -q main
kt_ah() { sh -c ". '$T/lib/md.sh'; . '$T/lib/cross-check.sh'; . '$T/lib/sha256.sh'; . '$T/lib/approval-tick.sh'; . '$T/lib/adr.sh'; . '$T/lib/rule.sh'; . '$T/lib/knowledge.sh'; kt_anh_huong '$F'" | cut -d'|' -f1,2 | sort | tr '\n' ' '; }
dung "tài liệu bị diff ảnh hưởng: module cha, ADR và file luật có Scope khớp; bỏ module khác" bang "$(kt_ah)" "docs/adr/0001-cu.md|0 docs/product/rules/kho.md|0 src/ARCHITECTURE.md|0 "
ky_vong 0 "implement: tài liệu có thể lỗi thời → vẫn ĐẠT (chỉ cảnh báo)" sh "$HT" "$F"
dung "…cảnh báo nêu tài liệu và file đổi" sh -c "sh '$HT' '$F' 2>/dev/null | grep -q 'CẢNH BÁO.*diff đụng src/a.txt (phạm vi của src/ARCHITECTURE.md) mà src/ARCHITECTURE.md không đổi'"
dung "…không nêu tài liệu module khác" sh -c "! sh '$HT' '$F' 2>/dev/null | grep -q 'lib/ARCHITECTURE.md'"
dung "…cảnh báo luật active trong phạm vi diff chưa có test covers" sh -c "sh '$HT' '$F' 2>/dev/null | grep -q 'CẢNH BÁO.*BR-KHO-001.*chưa test nào gắn tag covers'"
viet_review
ky_vong 1 "review: thiếu mục Durable knowledge → KHÔNG ĐẠT" sh "$RS" "$F"
dung "…nêu thiếu mục" sh -c "sh '$RS' '$F' 2>/dev/null | grep -q 'thiếu mục \"## Durable knowledge\"'"
# dk_review <bảng> — thêm mục Durable knowledge vào review.md
dk_review() { viet_review; printf '\n## Durable knowledge\n\n| File | Verdict | Reason |\n|---|---|---|\n%s\n' "$1" >> "$F/review.md"; ghi_tree_review; }
DK_DU='| `src/ARCHITECTURE.md` | pass | |
| `docs/adr/0001-cu.md` | pass | |
| `docs/product/rules/kho.md` | not applicable | đổi chữ, không đổi luật kho |'
dk_review "$DK_DU"
ky_vong 0 "review: mỗi tài liệu bị ảnh hưởng có verdict hợp lệ → ĐẠT" sh "$RS" "$F"
dk_review "$(printf '%s\n' "$DK_DU" | grep -v 'docs/adr')"
ky_vong 1 "review: thiếu verdict cho một tài liệu → KHÔNG ĐẠT" sh "$RS" "$F"
dk_review "$(printf '%s\n' "$DK_DU" | sed 's#| `src/ARCHITECTURE.md` | pass | |#| `src/ARCHITECTURE.md` | updated | |#')"
ky_vong 1 "review: updated mà diff không đổi tài liệu → KHÔNG ĐẠT" sh "$RS" "$F"
dk_review "$(printf '%s\n' "$DK_DU" | sed 's#đổi chữ, không đổi luật kho##')"
ky_vong 1 "review: not applicable thiếu lý do → KHÔNG ĐẠT" sh "$RS" "$F"
dk_review "$(printf '%s\n' "$DK_DU" | sed 's#| `docs/adr/0001-cu.md` | pass |#| `docs/adr/0001-cu.md` | ok |#')"
ky_vong 1 "review: verdict lạ → KHÔNG ĐẠT" sh "$RS" "$F"
# Diff sửa luôn tài liệu → implement hết cảnh báo cho nó; review nhận "updated"
printf 'cập nhật\n' >> "$R/src/ARCHITECTURE.md"
dung "…diff sửa tài liệu → implement không còn cảnh báo cho nó" sh -c "! sh '$HT' '$F' 2>/dev/null | grep -q 'mà src/ARCHITECTURE.md không đổi'"
dk_review "$(printf '%s\n' "$DK_DU" | sed 's#| `src/ARCHITECTURE.md` | pass | |#| `src/ARCHITECTURE.md` | updated | |#')"
ky_vong 0 "…review: updated cho tài liệu đã sửa → ĐẠT" sh "$RS" "$F"
tao_fixture

# ---------------------------------------------------------------- wrapper → lệnh mới
echo ""
echo "wrapper: ready, task, journal"
ky_vong 0 "aw journal → engine" aw7 journal
ky_vong 2 "aw task sai tham số → engine trả SAI THAM SỐ" aw7 task lam-gi
ky_vong 2 "aw ready thiếu thư mục → engine trả SAI THAM SỐ" aw7 ready
ky_vong 0 "aw adr check → engine (repo chưa có ADR: HỢP LỆ)" aw7 adr check
ky_vong 0 "aw rule check → engine (repo chưa có luật: HỢP LỆ)" aw7 rule check
ky_vong 2 "aw knowledge thiếu tham số → engine trả SAI THAM SỐ" aw7 knowledge

# ---------------------------------------------------------------- tong ket
echo ""
echo "─────────────────────────────────────────"
printf 'Tổng: %d ca — %d đạt, %d hỏng\n' "$((n_ok + n_fail))" "$n_ok" "$n_fail"
[ "$n_fail" -gt 0 ] && exit 1
exit 0
