# Helper + fixture dùng chung cho mọi phần test (tools/tests/NN-<tên>.sh).
# Mỗi phần là một tiến trình riêng: fixture, thư mục tạm, bộ đếm riêng —
# nên tools/run-tests.sh chạy các phần song song.
#
#   . "$(dirname -- "$0")/lib.sh"
#   tao_fixture          # nếu phần cần repo fixture
#   nhom "…"; ky_vong …; dung …
#   ket_thuc             # in "Tổng: …" (run-tests.sh đọc dòng này), thoát 0/1

set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PHAN=$(basename -- "$0" .sh)
TMP="${TMPDIR:-/tmp}/aw-run-tests.$PHAN.$$"
mkdir -p "$TMP"
. "$ROOT/tools/lib/result.sh"
kq_khai "tests/$PHAN.sh" "0=MỌI CA ĐẠT" "1=CÓ CA HỎNG — xem các dòng FAIL phía trên"
kq_don 'rm -rf "$TMP"'
T="$ROOT/tools"
AWE="$ROOT/bin/aw-engine"
# Phần không dựng fixture bắt đầu như sau một nhóm đã dọn biến (unset): không mang theo
# AW_REPO/AW_CONFIG của shell gọi test.
unset AW_REPO AW_CONFIG

n_ok=0
n_fail=0
CHI_TIET="${AW_TEST_VERBOSE:-}"
_nhom=""

# nhom <tieu-de> — mo mot nhom ca. Che do gon: chi in tieu de khi nhom co ca hong.
nhom() {
  if [ -n "$CHI_TIET" ]; then printf '\n%s\n' "$1"; _nhom=""; else _nhom=$1; fi
}

# ca_dat <ten-ca>, ca_hong <dong-bao-loi>
ca_dat() {
  n_ok=$((n_ok + 1))
  if [ -n "$CHI_TIET" ]; then printf '  ok    %s\n' "$1"; fi
}
ca_hong() {
  n_fail=$((n_fail + 1))
  if [ -n "$_nhom" ]; then printf '\n%s\n' "$_nhom"; _nhom=""; fi
  printf '  FAIL  %s\n' "$1"
}

# ky_vong <ma-mong-doi> <ten-ca> <lenh...>
ky_vong() {
  _mong="$1"; _ten="$2"; shift 2
  "$@" >/dev/null 2>&1
  _got=$?
  if [ "$_got" = "$_mong" ]; then
    ca_dat "$_ten"
  else
    ca_hong "$_ten — mã thoát $_got, mong đợi $_mong"
  fi
}

# dung <ten-ca> <lenh...> — lenh la mot phep thu tra 0/1
dung() {
  _ten="$1"; shift
  if "$@" >/dev/null 2>&1; then ca_dat "$_ten"; else ca_hong "$_ten"; fi
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

# toc_f <artifact>... — máy sinh mục lục "## Contents" + mở rộng anchor (aw toc), như agent làm
toc_f() { sh "$T/toc.sh" "$F" "$@" >/dev/null 2>&1; return 0; }

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
  toc_f intake.md
}

viet_spec() {
  cat > "$F/spec.md" <<'EOF'
# Spec — x

- **Risk:** `normal`
- [x] **Approved by human** — đã đọc

## Requirements

### REQ-001 — a
- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a
- Priority: `must`
- Acceptance criteria:
  - [ ] mở y thấy a

### REQ-002 — b
- Source: `[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)
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
# Open questions

## Questions

### REQ-002 — b
- **Assumption:** y
- **Blocking:** `non-blocking`   <!-- blocking | review-blocking | non-blocking -->
- **Status:** `open`   <!-- open | answered -->
EOF
  toc_f spec.md open-questions.md
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

## Target structure
Not applicable: không đổi cấu trúc module.

## Decisions (DEC-xxx)

### DEC-001 — lưu ở đâu
- Author: `agent`
- Choice: file
- [x] **Approved by human**

## Data model
Based on: DEC-001
Một file văn bản.

## Contract / API
Not applicable: không có API công khai.

## Flow
Đọc rồi ghi.

## Non-functional
Not applicable: thay đổi nội bộ nhỏ.

## Rollout & rollback
Triển khai một lần, quay lui bằng revert commit.

## Test strategy
Unit test.

## REQ mapping

| REQ | Mục |
|---|---|
| REQ-001 | § Data model |
| REQ-002 | § Flow |
EOF
  cat > "$F/design-findings.md" <<'EOF'
# Phát hiện

No blocking findings.
EOF
  toc_f tdd.md
}

viet_plan() {
  cat > "$F/plan.md" <<'EOF'
# Plan — x

## Tasks

### TSK-001 — a
- Covers: `REQ-001`
- Based on: `DEC-001`
- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[x]`

### TSK-002 — b
- Covers: `REQ-002`
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
    thay "$F/plan.md" '- Based on: `DEC-001`
' ''
    thay "$F/plan.md" '`src/*` `test/*`' '`docs/*`'
  fi
  toc_f plan.md
}

viet_review() {
  printf '| ID | Verdict |\n|---|---|\n| REQ-001 | pass |\n| REQ-002 | pending |\n' > "$F/review.md"
  [ "$LOAI" = "bugfix" ] && printf '\n- Repro test fails because: grep không thấy "moi" trong src/a.txt\n' >> "$F/review.md"
  viet_lens4
  printf '\n## Lens 3 — Quality\n\n- None\n\n## Conclusion\n\n- Blocker findings: 0\n- Mergeable: yes\n' >> "$F/review.md"
  toc_f review.md
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
| Authn / authz | pass | màn hình y dùng quyền có sẵn, khớp REQ-001 |
| Sensitive data / PII in logs | not applicable | không log, không dữ liệu cá nhân |
| Secrets / config | pass | |
| Crypto | not applicable | không dùng crypto |
| SSRF / path traversal / deserialization | not applicable | không có URL, đường dẫn hay deserialize |
| `New dependencies` | not applicable | không thêm dependency |
EOF
}

ghi_based_on() {
  sh "$T/based-on.sh" "$F" spec.md intake.md >/dev/null 2>&1
  if [ "$LOAI" = "chore" ]; then
    sh "$T/based-on.sh" "$F" plan.md spec.md >/dev/null 2>&1
  else
    sh "$T/based-on.sh" "$F" tdd.md spec.md open-questions.md >/dev/null 2>&1
    sh "$T/based-on.sh" "$F" plan.md spec.md tdd.md >/dev/null 2>&1
  fi
}

# ghi_bang_chung_task — task xong bằng máy: aw task done ghi task-results.md
ghi_bang_chung_task() {
  for _t in TSK-001 TSK-002; do sh "$T/task.sh" done "$F" "$_t" >/dev/null 2>&1; done
}

# tao_fixture [loai] [branch] — thư mục việc ở $FX_TM (mặc định .agent-workflow: việc kiểu cũ,
# chỉ ở máy; docs/sdlc: kiểu mới, commit vào branch — nhóm "artifact trong git")
tao_fixture() {
  LOAI="${1:-feature}"; _br="${2:-feat_x}"
  R="${FX_R:-$TMP/repo-$LOAI}"; F="$R/${FX_TM:-.agent-workflow}/$_br"
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
  printf '// covers: REQ-001, REQ-002\n' > "$R/test/a.test.js"
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
      printf '// covers: REQ-001\n' > "$R/test/b.test.js"
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

# build_doi_chieu_that — build thật (không AW_COMPARE) mọi adapter vào $DT/<adapter>/:
# bản đối chiếu cho các ca so output của aw init / worktree với build riêng.
build_doi_chieu_that() {
  DT="$TMP/doi-chieu-that"; mkdir -p "$DT"
  for b in "$ROOT"/adapters/*/build.sh; do
    a=$(basename "$(dirname "$b")"); mkdir -p "$DT/$a"; sh "$b" --out "$DT/$a" >/dev/null 2>&1
  done
}

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
  toc_f merge-request.md
}

# L3_SF — một finding [Should fix] hợp lệ của Lens 3
L3_SF='### [Should fix] trùng hàm
- Category: duplicate-code
- Location: `src/a.txt:1`
- Problem: có sẵn hàm tương tự'

# fixture_sau_bao_mat — fixture như lúc nhóm check-security xong: TEST_CMD="true" + lệnh
# quét xanh, implement chạy lại theo cấu hình đó. Các phần rà soát / check-ship bắt đầu từ đây.
fixture_sau_bao_mat() {
  tao_fixture
  printf 'TEST_CMD="true"\n%s\n' "$BM_XANH" > "$CFG/config.sh"
  sh "$T/check-implement.sh" "$F" >/dev/null 2>&1
}

# ket_thuc — tổng của phần; tools/run-tests.sh cộng các dòng "Tổng:" lại
ket_thuc() {
  echo ""
  printf 'Tổng: %d ca — %d đạt, %d hỏng\n' "$((n_ok + n_fail))" "$n_ok" "$n_fail"
  [ "$n_fail" -gt 0 ] && exit 1
  exit 0
}
