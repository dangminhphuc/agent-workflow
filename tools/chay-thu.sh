#!/usr/bin/env sh
# Test hoi quy cho cac cong chan va cho adapter.
#
#   sh tools/chay-thu.sh
#
# Repo nay ban cac cong chan; neu chinh cong chan hong ma khong ai biet thi
# ca quy trinh tro thanh trang tri. Moi ca kiem CA HAI CHIEU: chan dung luc
# va cho qua dung luc. Mot checker luon tra 0 con te hon khong co checker.

set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP="${TMPDIR:-/tmp}/aw-chay-thu.$$"
mkdir -p "$TMP"
. "$ROOT/tools/lib/ket-qua.sh"
kq_khai chay-thu.sh "0=MỌI CA ĐẠT" "1=CÓ CA HỎNG — xem các dòng FAIL phía trên"
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
  [ "$LOAI" = "chore" ] && { rm -f "$F/tdd.md" "$F/phat-hien-thiet-ke.md"; return 0; }
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
  cat > "$F/phat-hien-thiet-ke.md" <<'EOF'
# Phát hiện

Không có phát hiện mức Chặn.
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
- Verify: `npm test` → xanh
- Status: `[x]`

### T-02 — b
- Covers: `YC-002`
- Expected files: `src/b.txt`
- Verify: `npm test` → xanh
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
  return 0
}

ghi_based_on() {
  sh "$T/cap-nhat-based-on.sh" "$F" spec.md intake.md >/dev/null
  if [ "$LOAI" = "chore" ]; then
    sh "$T/cap-nhat-based-on.sh" "$F" plan.md spec.md >/dev/null
  else
    sh "$T/cap-nhat-based-on.sh" "$F" tdd.md spec.md open-questions.md >/dev/null
    sh "$T/cap-nhat-based-on.sh" "$F" plan.md spec.md tdd.md >/dev/null
  fi
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
    printf 'LENH_KIEM_THU="grep -q moi %s/src/a.txt"\n' "$R"
    printf 'LENH_DO_HIEU_NANG="echo KET_QUA: 5 ms"\n'
  } > "$CFG/config.sh"
  printf 'goc\n' > "$R/src/a.txt"
  printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"
  # Quy tắc riêng của repo (quy_tac_*): file phải đã commit vào base.
  printf '# quy tắc a\n' > "$R/docs/quy-tac.md"; printf '# quy tắc b\n' > "$R/docs/quy-tac-2.md"
  g add src test docs; g commit -q -m goc
  g checkout -q -b "$_br"
  viet_intake; viet_spec; viet_tdd; viet_plan; viet_review
  ghi_based_on
  case "$LOAI" in
    bugfix)
      printf '// covers: YC-001\n' > "$R/test/b.test.js"
      sh "$T/kiem-tra-tai-hien.sh" "$F" >/dev/null 2>&1 ;;
    perf)
      sh "$T/kiem-tra-hieu-nang.sh" "$F" --before >/dev/null 2>&1 ;;
  esac
  if [ "$LOAI" = "chore" ]; then
    printf 'LENH_KIEM_THU="true"\n' > "$CFG/config.sh"
    printf 'huong dan\n' > "$R/docs/huong-dan.md"
  else
    printf 'moi\n' > "$R/src/a.txt"
  fi
  [ "$LOAI" = "perf" ] && sh "$T/kiem-tra-hieu-nang.sh" "$F" --after >/dev/null 2>&1
  sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1
}

# ---------------------------------------------------------------- fixture goc
echo ""
echo "fixture"
tao_fixture
for c in truy-vet thiet-ke ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "feature đầy đủ qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done

# ---------------------------------------------------------------- aw-engine
echo ""
echo "bin/aw-engine"
AWE="$ROOT/bin/aw-engine"
dung "version in đúng VERSION" bang "$(sh "$AWE" version)" "$(cat "$ROOT/VERSION")"
for c in intake spec design plan implement review; do
  ky_vong 0 "aw-engine check $c → đúng checker, giữ mã thoát" sh "$AWE" check "$c" "$F"
done
dung "mọi tên trong bảng checker trỏ tới script có thật" sh -c ". '$T/lib/bang-lenh.sh'; for c in \$BL_CHECKERS; do [ -f '$T/'\$(bl_checker \$c) ] || exit 1; done"
dung "check giữ khối Kết quả của checker" sh -c "sh '$AWE' check plan '$F' 2>&1 | grep -q 'Kết quả: kiem-tra-ke-hoach.sh'"
ky_vong 2 "check tên lạ → SAI THAM SỐ" sh "$AWE" check khong-co "$F"
ky_vong 2 "check thiếu thư mục → SAI THAM SỐ" sh "$AWE" check spec
ky_vong 9 "thiếu AW_CONFIG → KHÔNG HỢP LỆ (không đoán đường dẫn)" env -u AW_CONFIG sh "$AWE" check spec "$F"
ky_vong 9 "wrapper khác giao thức → KHÔNG HỢP LỆ" env AW_PROTOCOL=999 sh "$AWE" check spec "$F"
ky_vong 2 "lệnh lạ → SAI THAM SỐ" sh "$AWE" lam-gi-do
ky_vong 0 "aw-engine guard pre → gac-duyet.sh" sh "$AWE" guard pre
ky_vong 0 "aw-engine approval → cong-duyet.sh" sh "$AWE" approval design "$F"
ky_vong 3 "aw-engine guard sai pha → SAI THAM SỐ của gac-duyet.sh" sh "$AWE" guard khac
ky_vong 2 "adapter không có → SAI THAM SỐ" sh "$AWE" adapter build khong-co --out "$TMP/o-x"

# Ghim version theo việc: dòng Engine trong intake.md
cp "$F/intake.md" "$TMP/intake.bak"
sed '/\*\*Engine:\*\*/d' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "intake thiếu dòng Engine → KHÔNG ĐẠT" sh "$T/kiem-tra-tiep-nhan.sh" "$F"
ky_vong 9 "…aw-engine check spec từ chối chấm (không biết engine nào)" sh "$AWE" check spec "$F"
ky_vong 1 "…aw-engine check intake vẫn chạy để liệt kê lỗi" sh "$AWE" check intake "$F"
sed 's/\*\*Engine:\*\* .*/**Engine:** 2026.10.06/' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "Engine sai dạng YYYY.M.N (có số 0 đứng đầu) → KHÔNG ĐẠT" sh "$T/kiem-tra-tiep-nhan.sh" "$F"
sed 's/\*\*Engine:\*\* .*/**Engine:** 2000.1.1/' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "Engine lệch engine đang chạy → KHÔNG ĐẠT" sh "$T/kiem-tra-tiep-nhan.sh" "$F"
for c in intake spec repro perf; do
  ky_vong 9 "…aw-engine check $c lệch version → KHÔNG HỢP LỆ" sh "$AWE" check "$c" "$F"
done
cp "$TMP/intake.bak" "$F/intake.md"
ky_vong 0 "Engine khớp → ĐẠT" sh "$T/kiem-tra-tiep-nhan.sh" "$F"

# ---------------------------------------------------------------- truy vet
echo ""
echo "kiem-tra-truy-vet.sh"
CHK="$T/kiem-tra-truy-vet.sh"

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
ky_vong 1 "…design cũng chặn spec đổi sau duyệt" sh "$T/kiem-tra-thiet-ke.sh" "$F"
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
ky_vong 1 "spec đã duyệt mà bị sửa (vd /clarify đổi nhãn) thì phải duyệt lại" sh "$CHK" "$F"
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
echo "kiem-tra-thiet-ke.sh"
CHK="$T/kiem-tra-thiet-ke.sh"

viet_spec; viet_tdd
rm -f "$F/phat-hien-thiet-ke.md"
ky_vong 1 "chặn khi checker LLM chưa chạy (không có file phát hiện ≠ đạt)" sh "$CHK" "$F"

printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: `chưa`   <!-- chưa | đã sửa -->\n' > "$F/phat-hien-thiet-ke.md"
ky_vong 1 "chặn phát hiện mức Chặn chưa xử lý" sh "$CHK" "$F"

printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: `bác bỏ:`\n' > "$F/phat-hien-thiet-ke.md"
ky_vong 1 "chặn bác bỏ phát hiện mà không có lý do" sh "$CHK" "$F"

printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: bác bỏ: D-01 đã nói rõ\n### PH-02 — y\n- Mức: `Cảnh báo`\n- Xử lý: chưa\n' > "$F/phat-hien-thiet-ke.md"
ky_vong 0 "bác bỏ có lý do + cảnh báo chưa xử lý thì cho qua" sh "$CHK" "$F"

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
echo "kiem-tra-ke-hoach.sh"
CHK="$T/kiem-tra-ke-hoach.sh"
ghi_based_on

thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
ky_vong 1 "chặn khi còn D-xx chưa được người duyệt" sh "$CHK" "$F"
viet_tdd; ghi_based_on

rm -f "$F/phat-hien-thiet-ke.md"
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

viet_plan; thay "$F/plan.md" '- Verify: `npm test` → xanh
- Status: `[x]`

## Deferred' '- Verify: <lệnh cụ thể>
- Status: `[x]`

## Deferred'
ky_vong 1 "chặn chỗ giữ chỗ chưa điền" sh "$CHK" "$F"
viet_plan; ghi_based_on

# ---------------------------------------------------------------- hien thuc
echo ""
echo "kiem-tra-hien-thuc.sh"
CHK="$T/kiem-tra-hien-thuc.sh"
CH="$CFG/config.sh"

printf 'LENH_KIEM_THU=""\n' > "$CH"
ky_vong 1 "chưa khai LENH_KIEM_THU là KHÔNG ĐẠT, không phải bỏ qua" sh "$CHK" "$F"

printf 'LENH_KIEM_THU="false"\n' > "$CH"
ky_vong 1 "chặn khi test đỏ" sh "$CHK" "$F"

printf 'LENH_KIEM_THU="true"\n' > "$CH"
thay "$F/plan.md" '- Status: `[x]`

## Deferred' '- Status: `[~]`

## Deferred'
ky_vong 1 "chặn khi còn task đang làm dở" sh "$CHK" "$F"
viet_plan; ghi_based_on

printf 'LENH_KIEM_THU="echo DAU-VET-DUY-NHAT-12345"\n' > "$CH"
sh "$CHK" "$F" >/dev/null 2>&1
dung "ghi output THẬT vào ket-qua-kiem-thu.md" grep -q 'DAU-VET-DUY-NHAT-12345' "$F/ket-qua-kiem-thu.md"
printf 'LENH_KIEM_THU="true"\n' > "$CH"

printf 'x\n' > "$R/README.md"
ky_vong 0 "file ngoài phạm vi chỉ CẢNH BÁO, không chặn implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo phạm vi" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*README.md'"
rm -f "$R/README.md"

thay "$F/open-questions.md" '`non-blocking`' '`review-blocking`'; ghi_based_on
ky_vong 0 "điểm mù \"chặn review\" còn mở chỉ CẢNH BÁO ở implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo điểm mù" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*YC-002: điểm mù mức \"review-blocking\"'"
viet_spec; ghi_based_on

# ---------------------------------------------------------------- ra soat
echo ""
echo "kiem-tra-ra-soat.sh"
CHK="$T/kiem-tra-ra-soat.sh"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

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

printf 'x\n' > "$R/README.md"
ky_vong 1 "CỔNG CUỐI: chặn file ngoài phạm vi" sh "$CHK" "$F"
thay "$F/plan.md" '|---|---|---|---|
' '|---|---|---|---|
| T-01 | cần README | `README.md` | đã ghi |
'
ky_vong 0 "ghi file vào Phát sinh thì cho qua" sh "$CHK" "$F"
rm -f "$R/README.md"; viet_plan; ghi_based_on

printf '// covers: YC-001\n' > "$R/test/a.test.js"
ky_vong 1 "CỔNG CUỐI: chặn YC chưa có test gắn tag" sh "$CHK" "$F"
thay "$F/plan.md" '| ID | Why not automated |
|---|---|
' '| ID | Why not automated |
|---|---|
| YC-002 | cần kiểm bằng mắt trên UI |
'
ky_vong 0 "ghi Kiểm chứng thủ công có lý do thì cho qua" sh "$CHK" "$F"
printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"; viet_plan; ghi_based_on

# Không test nào gắn tag: danh sách dòng tag rỗng không được làm kiểm chéo câm
printf '// chua gan tag\n' > "$R/test/a.test.js"
ky_vong 1 "CỔNG CUỐI: chặn khi CHƯA test nào gắn tag covers" sh "$CHK" "$F"
dung "…đúng lý do: YC chưa có test" sh -c "sh '$CHK' '$F' | grep -q 'YC-002: chưa có test'"
dung "…và implement có in cảnh báo YC chưa có test" sh -c "sh '$T/kiem-tra-hien-thuc.sh' '$F' | grep -q 'CẢNH BÁO.*YC-001'"
printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

printf '\n<!-- sửa sau khi đã viết spec -->\n' >> "$F/intake.md"
ky_vong 1 "CỔNG CUỐI: chặn spec lỗi thời khi intake.md đổi" sh "$CHK" "$F"
dung "…đúng lý do: spec.md lỗi thời theo intake.md" sh -c "sh '$CHK' '$F' | grep -q 'spec.md: lỗi thời — intake.md'"
viet_intake

printf '\n<!-- sửa sau khi đã có tdd -->\n' >> "$F/spec.md"
ky_vong 1 "CỔNG CUỐI: chặn artifact lỗi thời" sh "$CHK" "$F"
ky_vong 0 "…mà kế hoạch chỉ cảnh báo, không chặn" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_spec; ghi_based_on

rm -f "$F/ket-qua-kiem-thu.md"
ky_vong 1 "chặn khi chưa có ket-qua-kiem-thu.md" sh "$CHK" "$F"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

# ---------------------------------------------------------------- quy tac repo
echo ""
echo "quy tắc riêng của repo (quy_tac_*, aw rules)"
QT="$T/quy-tac-repo.sh"
CONV="$CFG/conventions.md"
cp "$CONV" "$TMP/conv-qt.bak"
# khai_qt <phase> <giá trị> — khai lại từ đầu một khoá quy_tac_<phase>
khai_qt() { cp "$TMP/conv-qt.bak" "$CONV"; thay "$CONV" "quy_tac_$1:" "quy_tac_$1: $2"; }
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
thay "$CONV" 'quy_tac_implement:' 'quy_tac_implement: docs/quy-tac.md'
dung "review = hợp mọi khoá, bỏ trùng, giữ thứ tự" bang "$(sh "$QT" review 2>/dev/null | tr '\n' ' ')" "docs/quy-tac-2.md docs/quy-tac.md "

for p in spec:truy-vet design:thiet-ke plan:ke-hoach implement:hien-thuc; do
  khai_qt "${p%%:*}" 'docs/khong-co.md'
  ky_vong 1 "${p%%:*}: file quy tắc không có → aw check ${p%%:*} chặn" sh "$T/kiem-tra-${p#*:}.sh" "$F"
done
dung "…đúng lý do" sh -c "sh '$T/kiem-tra-hien-thuc.sh' '$F' | grep -q 'quy tắc repo \"docs/khong-co.md\": không có file'"
ky_vong 1 "…aw rules implement ra KHAI SAI" sh "$QT" implement
ky_vong 0 "…phase không khai thì không bị ảnh hưởng" sh "$T/kiem-tra-truy-vet.sh" "$F"
ky_vong 1 "…review chặn (cổng cuối kiểm mọi khoá)" sh "$T/kiem-tra-ra-soat.sh" "$F"

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
git -C "$R" rm -q --cached .claude/skills/x/SKILL.md >/dev/null 2>&1; rm -rf "$R/.claude"

for v in /etc/hosts ../x docs/../../x; do
  khai_qt implement "$v"
  ky_vong 1 "đường dẫn ra ngoài repo ($v) → chặn" sh "$QT" implement
done

cp "$TMP/conv-qt.bak" "$CONV"
thay "$CONV" 'quy_tac_review:' 'quy_tac_review:
quy_tac_implment: docs/quy-tac.md'
ky_vong 1 "khoá gõ nhầm (quy_tac_implment) → aw rules chặn" sh "$QT" implement
dung "…đúng lý do" sh -c "sh '$QT' implement 2>&1 | grep -q 'quy_tac_implment.*không ứng với phase'"
ky_vong 1 "…review chặn" sh "$T/kiem-tra-ra-soat.sh" "$F"

# Review: mỗi file quy tắc một kết luận
khai_qt implement 'docs/quy-tac.md'
viet_review
ky_vong 1 "review.md thiếu mục Quy tắc repo → chặn" sh "$T/kiem-tra-ra-soat.sh" "$F"
dung "…đúng lý do" sh -c "sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'thiếu mục \"## Repo rules\"'"
viet_review; them_muc_qt '| `docs/quy-tac.md` | pass | |'
ky_vong 0 "có kết luận đạt → cho qua" sh "$T/kiem-tra-ra-soat.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | ổn | |'
ky_vong 1 "kết luận tự chế → chặn" sh "$T/kiem-tra-ra-soat.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | violation | |'
ky_vong 1 "vi phạm không kèm vị trí → chặn" sh "$T/kiem-tra-ra-soat.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | violation | `src/a.txt:1` |'
ky_vong 0 "vi phạm có vị trí → cho qua (người phán finding)" sh "$T/kiem-tra-ra-soat.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | not applicable | <lý do> |'
ky_vong 1 "không áp dụng còn chỗ giữ chỗ → chặn" sh "$T/kiem-tra-ra-soat.sh" "$F"
viet_review; them_muc_qt '| `docs/quy-tac.md` | not applicable | không đụng API |'
ky_vong 0 "không áp dụng có lý do → cho qua" sh "$T/kiem-tra-ra-soat.sh" "$F"
khai_qt spec 'docs/quy-tac-2.md'
thay "$CONV" 'quy_tac_implement:' 'quy_tac_implement: docs/quy-tac.md'
ky_vong 1 "review thiếu dòng cho quy tắc của phase khác (spec) → chặn" sh "$T/kiem-tra-ra-soat.sh" "$F"
dung "…đúng lý do" sh -c "sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'docs/quy-tac-2.md\": không có verdict'"
cp "$TMP/conv-qt.bak" "$CONV"; viet_review
ky_vong 0 "bỏ hết khoá → review như cũ" sh "$T/kiem-tra-ra-soat.sh" "$F"

# ---------------------------------------------------------------- liet ke cau hoi
echo ""
echo "liet-ke-viec-cho.sh (/clarify)"
CHK="$T/liet-ke-viec-cho.sh"
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
dung "mục chặn đánh dấu ĐANG CHẶN phase kế tiếp" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'YC-005.*ĐANG CHẶN /implement'"
dung "khối Kết quả: [x] CÓ VIỆC ĐANG CHẶN" sh -c "sh '$CHK' '$LQ' 2>&1 | grep -q '\[x\] CÓ VIỆC ĐANG CHẶN'"
thay "$LQ/open-questions.md" '`blocking`
- **Status:** `open`' '`non-blocking`
- **Status:** `open`'
ky_vong 3 "chỉ còn chặn review (chưa tới review) + không chặn → chưa chặn" sh "$CHK" "$LQ"
: > "$LQ/ket-qua-kiem-thu.md"
ky_vong 1 "…tới review thì chặn review thành ĐANG CHẶN" sh "$CHK" "$LQ"
rm -f "$LQ/ket-qua-kiem-thu.md"
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
cat > "$LQ/phat-hien-thiet-ke.md" <<'EOF'
# Phát hiện

### PH-01 — cảnh báo
- Mức: `Cảnh báo`
- Vị trí: `tdd.md` § Flow
- Vấn đề: mơ hồ
- Xử lý: `chưa`

### PH-02 — chặn chưa xử lý
- Mức: `Chặn`   <!-- Chặn | Cảnh báo -->
- Loại: `quyết định ngầm`
- Vị trí: `tdd.md` § Contract
- Vấn đề: chọn gRPC mà không nêu D
- Xử lý: `chưa`   <!-- chưa | đã sửa | bác bỏ: <lý do> -->

### PH-03 — đã sửa
- Mức: `Chặn`
- Xử lý: `đã sửa`

### PH-04 — bác bỏ không lý do
- Mức: `Chặn`
- Xử lý: `bác bỏ:`

### PH-05 — bác bỏ có lý do
- Mức: `Chặn`
- Xử lý: `bác bỏ: D-02 đã chốt — PO, 2026-10-06`
EOF
thu_tu_all() { sh "$CHK" "$LQ" 2>/dev/null | sed -n 's/^  [0-9][0-9]*\. \([A-Z]*-[0-9]*\).*/\1/p' | tr '\n' ' '; }
ky_vong 1 "phát hiện Chặn chưa xử lý → ĐANG CHẶN" sh "$CHK" "$LQ"
dung "xếp: điểm mù chặn → phát hiện Chặn → chặn review → phát hiện Cảnh báo → không chặn" \
  bang "$(thu_tu_all)" "YC-005 PH-02 PH-04 YC-002 PH-01 YC-001 "
dung "…phát hiện Chặn đánh dấu ĐANG CHẶN /plan" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'PH-02.*ĐANG CHẶN /plan'"
dung "…in vị trí + vấn đề của phát hiện" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'Vấn đề: chọn gRPC mà không nêu D'"
dung "phát hiện đã đóng chỉ nằm ở [ĐÃ XỬ LÝ], không đánh số" sh -c \
  "o=\$(sh '$CHK' '$LQ' 2>/dev/null); echo \"\$o\" | grep -q '^  - PH-03' && echo \"\$o\" | grep -q '^  - PH-05' && ! echo \"\$o\" | grep -q '^  [0-9]*\. PH-0[35]'"
thay "$LQ/open-questions.md" '`blocking`
- **Status:** `open`' '`non-blocking`
- **Status:** `open`'
thay "$LQ/phat-hien-thiet-ke.md" '`chưa`   <!-- chưa' '`đã sửa`   <!-- chưa'
thay "$LQ/phat-hien-thiet-ke.md" '`bác bỏ:`' '`bác bỏ: trùng PH-02`'
ky_vong 3 "chỉ còn phát hiện Cảnh báo + điểm mù chưa chặn → chưa chặn" sh "$CHK" "$LQ"
printf '# Open questions\n\nNo open questions.\n' > "$LQ/open-questions.md"
printf '# Phát hiện\n\nKhông có phát hiện mức Chặn.\n' > "$LQ/phat-hien-thiet-ke.md"
ky_vong 0 "file phát hiện rỗng + không điểm mù → không còn việc" sh "$CHK" "$LQ"
printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: `chưa`\n' > "$LQ/phat-hien-ke-hoach.md"
ky_vong 1 "checker mới (phat-hien-<id>.md) tự được gom" sh "$CHK" "$LQ"
rm -f "$LQ/phat-hien-ke-hoach.md" "$LQ/phat-hien-thiet-ke.md" "$LQ/tdd.md"

# ---------------------------------------------------------------- based_on
echo ""
echo "cap-nhat-based-on.sh"
printf -- '---\nkhac: giu\nbased_on:\n  - spec.md@1\n---\n\n# x\n' > "$F/thu.md"
sh "$T/cap-nhat-based-on.sh" "$F" thu.md spec.md >/dev/null
sh "$T/cap-nhat-based-on.sh" "$F" thu.md spec.md >/dev/null
dung "giữ khoá frontmatter khác" grep -q '^khac: giu' "$F/thu.md"
dung "chạy lại không nhân đôi based_on" test "$(grep -c 'spec.md@' "$F/thu.md")" = 1
dung "hash ghi ra khớp file (bỏ dấu duyệt)" grep -q "spec.md@$(tr -d '\r' < "$F/spec.md" | sed 's/ *<!-- approval-hash: [0-9a-f]* -->//' | cksum | awk '{print $1}')" "$F/thu.md"
duyet_lai "$F/spec.md"; sh "$T/cap-nhat-based-on.sh" "$F" thu.md spec.md >/dev/null
H_TRUOC=$(grep 'spec.md@' "$F/thu.md")
sh "$T/kiem-tra-truy-vet.sh" "$F" >/dev/null 2>&1
dung "…(spec giờ có dấu duyệt)" grep -q 'approval-hash:' "$F/spec.md"
sh "$T/cap-nhat-based-on.sh" "$F" thu.md spec.md >/dev/null
dung "máy ghi lại dấu duyệt không làm đổi hash based_on" bang "$H_TRUOC" "$(grep 'spec.md@' "$F/thu.md")"
printf '# không frontmatter\n' > "$F/thu.md"
sh "$T/cap-nhat-based-on.sh" "$F" thu.md spec.md >/dev/null
dung "thêm frontmatter khi file chưa có" sh -c "head -1 '$F/thu.md' | grep -q '^---\$'"
rm -f "$F/thu.md"

# ---------------------------------------------------------------- adapter
unset AW_REPO AW_CONFIG   # các mục dưới dùng bộ cài 1.x (cai-dat.sh) cho tới khi chuyển sang aw
echo ""
echo "adapters/claude-code/build.sh"
BUILD="$ROOT/adapters/claude-code/build.sh"

O="$TMP/out1"; mkdir -p "$O"
ky_vong 0 "build bản đúng thành công" sh "$BUILD" --out "$O"

du=1
for f in commands/intake.md commands/spec.md commands/design.md commands/plan.md commands/implement.md commands/review.md \
         commands/import.md commands/clarify.md agents/ra-soat-doc-lap.md agents/soat-thiet-ke.md skills/quy-trinh-agent/SKILL.md; do
  [ -f "$O/.claude/$f" ] || { du=0; echo "        thiếu .claude/$f"; }
done
[ -f "$O/.claude/commands/ship.md" ] && du=0
dung "sinh đúng bộ file, bỏ qua phase chưa hiện thực" test "$du" = 1
dung "command có bước xác định feature bằng aw feature" grep -q 'aw feature \$ARGUMENTS' "$O/.claude/commands/design.md"
dung "điều kiện ra máy là aw check <tên>" grep -q '`aw check design <thư-mục-feature>`' "$O/.claude/commands/design.md"
dung "không còn gọi script theo đường dẫn bộ cài cũ" sh -c "! grep -rq '\.quy-trinh\|sh tools/\|\.sh ' '$O/.claude'"
dung "command design gọi checker LLM" grep -q 'soat-thiet-ke' "$O/.claude/commands/design.md"
dung "lệnh /clarify có bước xác định feature + chạy aw pending" sh -c \
  "grep -q 'aw feature \$ARGUMENTS' '$O/.claude/commands/clarify.md' && grep -q 'aw pending' '$O/.claude/commands/clarify.md'"
dung "lệnh /clarify hỏi bằng AskUserQuestion, có Chat về câu này" sh -c \
  "grep -q 'AskUserQuestion' '$O/.claude/commands/clarify.md' && grep -q 'Chat về câu này' '$O/.claude/commands/clarify.md'"
dung "…lựa chọn là phương án đã phân tích, (Đề xuất) đứng đầu nhãn" sh -c \
  "grep -q 'Nghĩ kỹ trước khi hỏi' '$O/.claude/commands/clarify.md' && grep -q 'bắt đầu bằng.*(Đề xuất)' '$O/.claude/commands/clarify.md'"
dung "…không chiếm chỗ options bằng lối Chat/tự nhập có sẵn của tool" grep -q 'Chat about this' "$O/.claude/commands/clarify.md"
dung "lệnh /clarify dẫn phân xử phát hiện checker LLM" grep -q 'phat-hien-thiet-ke.md' "$O/.claude/commands/clarify.md"
dung "…lệnh không khai choice_ui thì không có" sh -c "! grep -q 'AskUserQuestion' '$O/.claude/commands/import.md'"
dung "/design có cổng duyệt: aw approval design + hộp xác nhận AskUserQuestion" sh -c \
  "grep -q 'Bước 1 — Cổng duyệt' '$O/.claude/commands/design.md' && grep -q 'aw approval design' '$O/.claude/commands/design.md' && grep -q 'AskUserQuestion' '$O/.claude/commands/design.md'"
dung "…ba lựa chọn cố định, có preview, từ chối duyệt hộ" sh -c \
  "grep -q 'Tôi đã duyệt xong — kiểm lại' '$O/.claude/commands/design.md' && grep -q 'Giải thích từng điểm cần duyệt' '$O/.claude/commands/design.md' && grep -q 'Dừng — tôi duyệt sau' '$O/.claude/commands/design.md' && grep -q 'preview' '$O/.claude/commands/design.md' && grep -q 'duyệt hộ' '$O/.claude/commands/design.md'"
dung "/plan có cổng duyệt aw approval plan" grep -q 'aw approval plan' "$O/.claude/commands/plan.md"
dung "…phase không khai approval_gate thì không có" sh -c "! grep -q 'Cổng duyệt' '$O/.claude/commands/implement.md' && ! grep -q 'Cổng duyệt' '$O/.claude/commands/spec.md'"
dung "lệnh /import giữ argument-hint riêng" grep -q 'argument-hint: <file-nguồn>' "$O/.claude/commands/import.md"
dung "skill liệt kê lệnh tiện ích" grep -q '/clarify' "$O/.claude/skills/quy-trinh-agent/SKILL.md"
dung "phase có quy tắc repo: lệnh gọi aw rules <phase>" sh -c \
  "for p in spec design plan implement review; do grep -q \"aw rules \$p\" '$O/.claude/commands/'\$p.md || exit 1; done"
dung "…intake thì không" sh -c "! grep -q 'aw rules' '$O/.claude/commands/intake.md'"
dung "…subagent rà soát đọc aw rules review" grep -q 'aw rules review' "$O/.claude/agents/ra-soat-doc-lap.md"
dung "…checker LLM soát thiết kế đọc aw rules design" grep -q 'aw rules design' "$O/.claude/agents/soat-thiet-ke.md"

printf '# tôi tự viết\n' > "$O/.claude/commands/spec.md"
ky_vong 3 "từ chối ghi đè file người viết tay" sh "$BUILD" --out "$O"
dung "nội dung người viết còn nguyên" sh -c "head -1 '$O/.claude/commands/spec.md' | grep -q 'tôi tự viết'"
ky_vong 0 "--force thì cho phép ghi đè" sh "$BUILD" --out "$O" --force

# lenh do lan cai truoc sinh ra ma nay khong con (vd /ideation -> /intake)
printf -- '---\n---\n> **File này được SINH TỰ ĐỘNG** từ `workflow/phases/00-ideation.md`\n' > "$O/.claude/commands/ideation.md"
printf '# lệnh tôi tự viết\n' > "$O/.claude/commands/cua-toi.md"
sh "$BUILD" --out "$O" >/dev/null 2>&1
dung "cài lại xoá lệnh sinh tự động không còn trong manifest" test ! -f "$O/.claude/commands/ideation.md"
dung "…nhưng giữ lệnh người viết tay" test -f "$O/.claude/commands/cua-toi.md"

FAKE="$TMP/fake"
tao_fake() {
  rm -rf "$FAKE"; mkdir -p "$FAKE/tools" "$FAKE/adapters/claude-code"
  cp -r "$ROOT/workflow" "$FAKE/"
  cp "$ROOT/workflow.yaml" "$FAKE/"
  cp -r "$ROOT/tools/lib" "$FAKE/tools/"
  cp "$ROOT"/tools/*.sh "$FAKE/tools/"
  cp "$ROOT/VERSION" "$FAKE/"
  cp -r "$ROOT/adapters/lib" "$FAKE/adapters/"
  cp "$BUILD" "$FAKE/adapters/claude-code/"
}

tao_fake
thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - kế hoạch trông có vẻ hợp lý'
O2="$TMP/out2"; mkdir -p "$O2"
ky_vong 4 "từ chối build khi exit_machine không phải lệnh chạy được" sh "$FAKE/adapters/claude-code/build.sh" --out "$O2"
dung "không để lại file viết dở khi build hỏng" sh -c "[ ! -f '$O2/.claude/commands/plan.md' ] && [ -z \"\$(find '$O2' -name '*.tmp')\" ]"

tao_fake
thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - aw check khong-ton-tai'
ky_vong 4 "từ chối build khi aw check trỏ tới checker không có" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out3"

tao_fake
rm -f "$FAKE/workflow/checkers/thiet-ke.md"
ky_vong 4 "từ chối build khi llm_checker trỏ tới file không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out4"

tao_fake
thay "$FAKE/workflow/phases/00-intake.md" 'arguments: input' 'arguments: gi-cung-duoc'
ky_vong 4 "từ chối build khi arguments không phải \"input\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out5"

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
thay "$FAKE/workflow/checkers/thiet-ke.md" 'quy_tac: design' 'quy_tac: intake'
ky_vong 4 "từ chối build khi checker LLM khai quy_tac không phải phase có quy tắc" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out9"

tao_fake
thay "$FAKE/workflow/import.md" 'arguments: mixed' 'arguments: input'
ky_vong 4 "từ chối build khi lệnh tiện ích khai arguments khác \"mixed\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out7"

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
echo "aw feature (xac-dinh-feature.sh)"
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
CV9="$R9/.git/agent-workflow/conventions.md"
ky_vong 6 "checkout chính → ĐANG Ở CHECKOUT CHÍNH (worktree bắt buộc)" awd "$R9" feature
ky_vong 6 "…kể cả khi có tham số" awd "$R9" feature feat_abc
dung "…và in danh sách việc cần làm: mở worktree / chạy /intake" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature 2>&1 | grep -q 'CHECKOUT CHÍNH'"

W4="$TMP/repo9.wt/khong-khop"
g9 worktree add -q -b khong-khop "$W4" main
ky_vong 3 "trong worktree, branch không khớp, không tham số → CẦN HỎI NGƯỜI" awd "$W4" feature
dung "branch không khớp → lấy tham số" test "$(awd "$W4" feature feat_abc 2>/dev/null)" = ".agent-workflow/feat_abc"
ky_vong 2 "từ chối tên feature có ../" awd "$W4" feature "../x"
git -C "$W4" checkout -q -b feat_them-todo
dung "branch khớp quy ước → tên branch đầy đủ" test "$(awd "$W4" feature 2>/dev/null)" = ".agent-workflow/feat_them-todo"
dung "branch khớp thì thắng tham số" test "$(awd "$W4" feature khac 2>/dev/null)" = ".agent-workflow/feat_them-todo"
dung "in 'Đang làm với:'" sh -c "cd '$W4' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature 2>&1 >/dev/null | grep -q 'Đang làm với: .agent-workflow/feat_them-todo'"
g9 worktree remove --force "$W4"

# ---------------------------------------------------------------- tao worktree (/intake)
echo ""
echo "aw worktree new (tao-worktree.sh)"
thay "$CV9" 'mau_nhanh_phat_hanh:' 'mau_nhanh_phat_hanh: release/*'
g9 branch release/1.2
DX=$(awd "$R9" worktree new bugfix phi-hoan-tien 2>/dev/null)
dung "đề xuất tên theo tiền tố của loại việc" sh -c "printf '%s' \"\$1\" | grep -q 'Tên        fix_phi-hoan-tien'" _ "$DX"
dung "…đường dẫn theo thu_muc_worktree (ngoài repo)" sh -c "printf '%s' \"\$1\" | grep -qF '$TMP/repo9.wt/fix_phi-hoan-tien'" _ "$DX"
dung "…liệt kê nhánh phát hành làm ứng viên base" sh -c "printf '%s' \"\$1\" | grep -q 'release/1.2'" _ "$DX"
dung "…gợi ý ★ nhanh_goc khi không có remote" sh -c "printf '%s' \"\$1\" | grep -q '★ \[1\] main'" _ "$DX"
dung "…không còn đòi base có bộ cài" sh -c "! printf '%s' \"\$1\" | grep -q 'bộ cài'" _ "$DX"
dung "…lệnh tạo in bằng aw, cờ tiếng Anh" sh -c "printf '%s' \"\$1\" | grep -q 'aw worktree new bugfix phi-hoan-tien --create --base <ref>'" _ "$DX"
dung "…chỉ đề xuất: chưa tạo branch, chưa tạo worktree" sh -c "! git -C '$R9' rev-parse --verify --quiet refs/heads/fix_phi-hoan-tien && [ ! -e '$TMP/repo9.wt/fix_phi-hoan-tien' ]"
ky_vong 2 "từ chối loại việc không có tiền tố" awd "$R9" worktree new utils x
ky_vong 2 "từ chối mô tả không phải chữ thường ASCII" awd "$R9" worktree new bugfix "Phi Hoan"
ky_vong 2 "--create thiếu --base → từ chối (agent không tự chọn base)" awd "$R9" worktree new bugfix phi-hoan-tien --create
ky_vong 2 "--base không kèm --create → từ chối" awd "$R9" worktree new bugfix phi-hoan-tien --base main
ky_vong 2 "từ chối ref không tồn tại" awd "$R9" worktree new bugfix phi-hoan-tien --create --base khong-co
AW_THU_MUC_WORKTREE='.worktrees/{ten}' ky_vong 2 "từ chối worktree nằm trong repo" awd "$R9" worktree new bugfix phi-hoan-tien
dung "AW_THU_MUC_WORKTREE ghi đè vị trí theo máy" sh -c "cd '$R9' && AW_THU_MUC_WORKTREE='$TMP/rieng/{repo}/{ten}' AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new bugfix phi-hoan-tien 2>/dev/null | grep -qF '$TMP/rieng/repo9/fix_phi-hoan-tien'"

GOC9=$(git -C "$R9" rev-parse main)
ky_vong 0 "base không có gì của quy trình vẫn tạo được worktree" awd "$R9" worktree new chore khong-bo-cai --create --base khong-co-gi
W0="$TMP/repo9.wt/chore_khong-bo-cai"
dung "…worktree mới có adapter sinh sẵn" test -f "$W0/.claude/commands/spec.md"
dung "…file adapter bị exclude: worktree sạch" sh -c "[ -z \"\$(git -C '$W0' status --porcelain)\" ]"
dung "…artifact viết vào cũng bị exclude" sh -c "mkdir -p '$W0/.agent-workflow/chore_khong-bo-cai' && printf x > '$W0/.agent-workflow/chore_khong-bo-cai/intake.md' && [ -z \"\$(git -C '$W0' status --porcelain)\" ]"
dung "…không có commit nào vào base, checkout chính sạch" sh -c "[ \"\$(git -C '$R9' rev-parse main)\" = '$GOC9' ] && [ -z \"\$(git -C '$R9' status --porcelain)\" ]"
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

# ---------------------------------------------------------------- don worktree
echo ""
echo "aw worktree status|remove (don-worktree.sh)"
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

IN="$R9/.claude/commands/intake.md"
dung "/intake: tham số là input, không truyền vào aw feature" sh -c "grep -q 'argument-hint: \[mã-issue' '$IN' && ! grep -q 'aw feature \$ARGUMENTS' '$IN'"
dung "/intake: đang ở checkout chính thì dẫn tới aw worktree new" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*aw worktree new' "$IN"
dung "lệnh khác: ĐANG Ở CHECKOUT CHÍNH thì dừng lại" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*dừng lại' "$R9/.claude/commands/spec.md"
dung "lệnh khác vẫn nhận tên feature qua tham số" grep -q 'aw feature \$ARGUMENTS' "$R9/.claude/commands/spec.md"
dung "/intake: tham số đi qua aw input bằng heredoc nguyên văn" sh -c "grep -q 'aw input .*- <<' '$IN' && grep -qx '\$ARGUMENTS' '$IN'"
dung "aw init chép rules/templates/checkers của engine vào .agent-workflow/.engine/ (bị exclude)" sh -c "[ -f '$R9/.agent-workflow/.engine/templates/spec.md' ] && [ -f '$R9/.agent-workflow/.engine/rules/nguyen-tac-chung.md' ] && grep -qx '$VDEV' '$R9/.agent-workflow/.engine/VERSION'"
dung "…conventions.md trong đó trỏ tới cấu hình của bản clone" sh -c "grep -q '^mau_branch:' '$R9/.agent-workflow/.engine/conventions.md'"
dung "mọi đường dẫn .agent-workflow/.engine/… mà lệnh sinh ra nhắc tới đều có thật" sh -c "cd '$R9' && for p in \$(grep -rhoE '\.agent-workflow/\.engine/[A-Za-z0-9_./-]+\.md' .claude | sort -u); do [ -e \"\$p\" ] || { echo \$p; exit 1; }; done"

# ---------------------------------------------------------------- phan loai input (/intake)
echo ""
echo "aw input (phan-loai-input.sh)"
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
dung "chưa khai mien_confluence: URL khác → [CONFLUENCE]" bang "$(ra 'https://wiki.co/p/1')" "- ${BT}[CONFLUENCE]${BT} https://wiki.co/p/1"
dung "…kèm cảnh báo chưa khai mien_confluence" sh -c "printf '%s' \"\$1\" | grep -q mien_confluence" _ "$(loi 'https://wiki.co/p/1')"
dung "bỏ dấu câu / ngoặc bọc ngoài: (ABC-1), \`docs/a.md\`" bang "$(ra '(ABC-1), `docs/a.md`.')" "- ${BT}[JIRA]${BT} ABC-1
- ${BT}[FILE]${BT} docs/a.md"
dung "cùng một nguồn gõ nhiều cách → một dòng" bang "$(ra 'ABC-1 ABC-1 https://x.atlassian.net/browse/ABC-1' | wc -l | tr -d ' ')" 1
ky_vong 1 "đường dẫn không tồn tại → ĐƯỜNG DẪN KHÔNG TỒN TẠI (không tự đoán)" pl "ABC-1 docs/khong-co.md"
dung "…và không in dòng input nào" test -z "$(ra 'ABC-1 docs/khong-co.md')"
ky_vong 3 "không có tham số → KHÔNG CÓ THAM SỐ (hỏi người dùng)" pl ""
ky_vong 3 "tham số chỉ có khoảng trắng / dòng trống → KHÔNG CÓ THAM SỐ" pl "
  "
ky_vong 4 "câu chữ tự do → LỜI NGƯỜI DÙNG" pl "sửa phí hoàn tiền bị âm ABC-123"
dung "…cả chuỗi là MỘT mục [HUMAN] nguyên văn" bang "$(ra 'sửa phí hoàn tiền bị âm ABC-123')" "- ${BT}[HUMAN]${BT}
  > sửa phí hoàn tiền bị âm ABC-123"
dung "…mã Jira trong câu chỉ là ĐỀ XUẤT (stderr)" sh -c "printf '%s\n' \"\$1\" | grep -A3 'Đề xuất tách thêm' | grep -q 'ABC-123'" _ "$(loi 'sửa phí hoàn tiền bị âm ABC-123')"
ky_vong 4 "đường dẫn không có file nằm trong câu chữ thì không chặn" pl "sửa lỗi trong src/khong-co.js"

cp "$CV9" "$TMP/conv.bak"
sed 's#^mien_confluence:.*#mien_confluence: *.atlassian.net/wiki#' "$TMP/conv.bak" > "$CV9"
dung "khai mien_confluence: URL khớp → [CONFLUENCE]" bang "$(ra 'https://x.atlassian.net/wiki/spaces/A/pages/1')" "- ${BT}[CONFLUENCE]${BT} https://x.atlassian.net/wiki/spaces/A/pages/1"
ky_vong 4 "khai mien_confluence: URL lạ → lời người dùng" pl "https://github.com/a/b"
ky_vong 4 "khai mien_confluence: miền giả mạo x.atlassian.net.evil.com → không nhận" pl "https://x.atlassian.net.evil.com/wiki/p/1"
dung "khai mien_confluence: URL có query vẫn khớp" bang "$(ra 'https://x.atlassian.net/wiki?p=1')" "- ${BT}[CONFLUENCE]${BT} https://x.atlassian.net/wiki?p=1"
printf '%s\n' '```conventions' 'mau_branch: feat_*' '```' > "$CV9"
ky_vong 0 "conventions.md cũ chưa có mau_jira → dùng mặc định" pl "ABC-1"
cp "$TMP/conv.bak" "$CV9"

# nguyen van qua stdin: dau nhay, $, backtick, nhieu dong khong bi shell dien giai
awd "$R9" input - > "$TMP/nv.out" 2>/dev/null <<'HET_INPUT'

Sửa "phí" khi $amount < 0 — xem `x`
dòng hai
HET_INPUT
dung "stdin: nguyên văn giữ dấu nháy, \$, backtick, nhiều dòng" bang "$(cat "$TMP/nv.out")" "- ${BT}[HUMAN]${BT}
  > Sửa \"phí\" khi \$amount < 0 — xem ${BT}x${BT}
  > dòng hai"

# --skip: chay lai /intake = gop them
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
echo "kiem-tra-tiep-nhan.sh"
CHK="$T/kiem-tra-tiep-nhan.sh"
tao_fixture feature feat_x

ky_vong 0 "tiếp nhận hợp lệ thì cho qua" sh "$CHK" "$F"

thay "$F/intake.md" '`feature`' '`utils`'
ky_vong 1 "chặn loại việc ngoài 5 loại" sh "$CHK" "$F"
ky_vong 1 "spec chặn khi intake.md không đạt (entry check)" sh "$T/kiem-tra-truy-vet.sh" "$F"
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
ky_vong 1 "chặn [JIRA] không có mã khớp mau_jira" sh "$CHK" "$F"
viet_intake
thay "$F/intake.md" '`[JIRA]` ABC-1' '`[JIRA]` [ABC-1](https://x.atlassian.net/browse/ABC-1)'
ky_vong 0 "[JIRA] dạng link markdown có mã thì cho qua" sh "$CHK" "$F"
viet_intake

# spec ghi based_on intake.md: gop them input -> spec loi thoi, review chan
sh "$T/cap-nhat-based-on.sh" "$F" spec.md intake.md >/dev/null
ky_vong 0 "spec ghi based_on intake.md vẫn qua kiem-tra-truy-vet" sh "$T/kiem-tra-truy-vet.sh" "$F"
printf -- '- `[JIRA]` ABC-2\n' >> "$F/intake.md"
ky_vong 1 "gộp thêm input sau khi có spec → review chặn (spec lỗi thời)" sh "$T/kiem-tra-ra-soat.sh" "$F"
dung "…đúng lý do: spec.md lỗi thời vì intake.md" sh -c "sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'spec.md: lỗi thời — intake.md'"
viet_intake; viet_spec

thay "$F/intake.md" '`feature`' '`chore`'
ky_vong 0 "loại lệch tiền tố branch chỉ CẢNH BÁO ở /intake" sh "$CHK" "$F"
dung "…và có in cảnh báo lệch tiền tố" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*feat_'"
viet_intake

# Base: dong do tao-worktree.sh in ra, checker phia sau so diff voi no
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
ky_vong 1 "base ghi main mà branch tạo từ bản mới hơn → review thấy file của người khác" sh "$T/kiem-tra-ra-soat.sh" "$F"
dung "…đúng lý do: file của người khác bị tính ngoài phạm vi" sh -c "sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'docs/cua-nguoi-khac.txt: thay đổi ngoài phạm vi'"
SHA_MH=$(git -C "$R" rev-parse --short moi-hon)
thay "$F/intake.md" "\`main\` @ \`$SHA_MAIN\`" "\`moi-hon\` @ \`$SHA_MH\`"
ghi_based_on
ky_vong 0 "ghi đúng base → diff chỉ còn việc của mình, review cho qua" sh "$T/kiem-tra-ra-soat.sh" "$F"
dung "…nhưng base lạ (xếp chồng) thì review CẢNH BÁO" sh -c "sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'CẢNH BÁO.*Base \"moi-hon\"'"
thay "$CFG/conventions.md" 'mau_nhanh_phat_hanh:' 'mau_nhanh_phat_hanh: moi-*'
dung "base khớp mau_nhanh_phat_hanh → không cảnh báo" sh -c "! sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'CẢNH BÁO.*Base'"
thay "$CFG/conventions.md" 'mau_nhanh_phat_hanh: moi-*' 'mau_nhanh_phat_hanh:'

# ---------------------------------------------------------------- bugfix
echo ""
echo "loại việc: bugfix"
tao_fixture bugfix fix_y
for c in tiep-nhan truy-vet thiet-ke ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "bugfix đầy đủ qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done
dung "tai-hien.md ghi output THẬT, mã thoát khác 0" sh -c "grep -q 'Mã thoát: \`1\`' '$F/tai-hien.md'"

ky_vong 1 "kiem-tra-tai-hien từ chối khi đã sửa code production" sh "$T/kiem-tra-tai-hien.sh" "$F"
dung "…và giữ nguyên tai-hien.md cũ" grep -q 'Mã thoát: `1`' "$F/tai-hien.md"

thay "$F/spec.md" '- Expected behavior: ra moi' ''
ky_vong 1 "spec bugfix chặn khi thiếu Hành vi đúng" sh "$T/kiem-tra-truy-vet.sh" "$F"
viet_spec; ghi_based_on

mv "$F/tai-hien.md" "$F/tai-hien.bak"
ky_vong 1 "implement chặn bugfix không có tai-hien.md" sh "$T/kiem-tra-hien-thuc.sh" "$F"
ky_vong 1 "review chặn bugfix không có tai-hien.md" sh "$T/kiem-tra-ra-soat.sh" "$F"
mv "$F/tai-hien.bak" "$F/tai-hien.md"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

viet_review; thay "$F/review.md" '- Repro test fails because: grep không thấy "moi" trong src/a.txt' '- Repro test fails because: <trích>'
ky_vong 1 "review chặn bugfix thiếu \"Test tái hiện đỏ vì\"" sh "$T/kiem-tra-ra-soat.sh" "$F"
viet_review

# test xanh tren code chua sua -> khong tai hien duoc
g stash -q
printf 'LENH_KIEM_THU="true"\n' > "$CFG/config.sh"
ky_vong 1 "kiem-tra-tai-hien chặn khi test XANH trên code chưa sửa" sh "$T/kiem-tra-tai-hien.sh" "$F"
dung "…đúng lý do: test xanh, không phải vì đã sửa code" sh -c "sh '$T/kiem-tra-tai-hien.sh' '$F' | grep -q 'XANH'"

# ---------------------------------------------------------------- refactor
echo ""
echo "loại việc: refactor"
tao_fixture refactor refactor_z
for c in truy-vet thiet-ke ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "refactor đầy đủ qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done

thay "$F/spec.md" '- Type: `structural`' ''
ky_vong 1 "spec refactor chặn YC không có Loại YC (hành vi mới)" sh "$T/kiem-tra-truy-vet.sh" "$F"
viet_spec

thay "$F/spec.md" '`test/a.test.js`' '`test/moi.test.js`'
printf '// covers: YC-001\n' > "$R/test/moi.test.js"
ky_vong 1 "spec refactor chặn test bảo vệ không có sẵn trên nhánh gốc" sh "$T/kiem-tra-truy-vet.sh" "$F"
rm -f "$R/test/moi.test.js"; viet_spec; ghi_based_on

printf '// covers: YC-001, YC-002\n// doi import\n' > "$R/test/a.test.js"
ky_vong 0 "sửa test cũ chưa khai chỉ CẢNH BÁO ở implement" sh "$T/kiem-tra-hien-thuc.sh" "$F"
ky_vong 1 "…nhưng review chặn" sh "$T/kiem-tra-ra-soat.sh" "$F"
thay "$F/plan.md" '| Test file | Reason |
|---|---|
' '| Test file | Reason |
|---|---|
| `test/a.test.js` | đổi import do dời module |
'
ky_vong 0 "khai ở \"Test cũ bị sửa\" thì review cho qua" sh "$T/kiem-tra-ra-soat.sh" "$F"
g checkout -q -- test/a.test.js; viet_plan; ghi_based_on

rm -f "$R/test/a.test.js"
ky_vong 1 "implement chặn refactor XOÁ test cũ" sh "$T/kiem-tra-hien-thuc.sh" "$F"
g checkout -q -- test/a.test.js
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

# ---------------------------------------------------------------- perf
echo ""
echo "loại việc: perf"
tao_fixture perf perf_w
for c in truy-vet thiet-ke ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "perf đầy đủ qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done
# Mỗi mục "## Trước" / "## Sau" phải có dòng KET_QUA (dòng này còn lặp lại
# trong khối output thật, nên đếm theo mục chứ không đếm dòng).
dung "do-hieu-nang.md có số đo trước và sau" sh -c "[ \"\$(awk '/^## /{m=\$2} /^KET_QUA:/ && m!=\"\" && !(m in c) {c[m]=1; n++} END{print n+0}' '$F/do-hieu-nang.md')\" = 2 ]"
ky_vong 1 "đo \"trước\" bị từ chối khi đã sửa code production" sh "$T/kiem-tra-hieu-nang.sh" "$F" --before

thay "$F/spec.md" '- Target: dưới 10 ms' '- Target: nhanh hơn'
ky_vong 1 "spec perf chặn YC hiệu năng không có số liệu" sh "$T/kiem-tra-truy-vet.sh" "$F"
viet_spec; ghi_based_on

mv "$F/do-hieu-nang.md" "$F/do-hieu-nang.bak"
ky_vong 1 "implement chặn perf không có số đo" sh "$T/kiem-tra-hien-thuc.sh" "$F"
ky_vong 1 "đo \"sau\" bị từ chối khi chưa có số đo trước" sh "$T/kiem-tra-hieu-nang.sh" "$F" --after
mv "$F/do-hieu-nang.bak" "$F/do-hieu-nang.md"

# ---------------------------------------------------------------- gác ô duyệt (hook)
echo ""
echo "gac-duyet.sh (aw guard)"
GAC="$T/gac-duyet.sh"
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
viet_spec; rm -f "$R/.agent-workflow/.gac-duyet-pre"
ky_vong 0 "post không thấy pre thì không coi tick chưa dấu là của agent" sh "$GAC" post
dung "…tick còn nguyên" co_tick

# Việc mới dùng engine cũ (dạng "Status:") — hook không đụng tới
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- **Status:** `approved`'
sh "$GAC" pre >/dev/null 2>&1
ky_vong 0 "spec dạng cũ: hook không chặn" sh "$GAC" post
viet_spec; viet_tdd; ghi_based_on

# ---------------------------------------------------------------- cổng duyệt
echo ""
echo "cong-duyet.sh (aw approval)"
CD="$T/cong-duyet.sh"
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
dung "…nói hệ quả của mức rủi ro (Mode 1/2)" sh -c "printf '%s' \"\$1\" | grep -q 'Risk: normal — /design chạy Mode 1'" _ "$OUT_CD"
dung "…đếm điểm mù còn mở theo mức chặn" sh -c "printf '%s' \"\$1\" | grep -q 'Điểm mù còn mở: 1 (blocking: 0 · review-blocking: 0 · non-blocking: 1)'" _ "$OUT_CD"
dung "…không tự tick" sh -c "grep -q '^- \[ \] \*\*Approved by human' '$F/spec.md'"
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 0 "người tick xong → ĐÃ DUYỆT (kiểm lại)" sh "$CD" design "$F"
thay "$F/spec.md" 'có log' 'có log Warn'
ky_vong 1 "spec đổi sau duyệt → CHƯA DUYỆT" sh "$CD" design "$F"
dung "…nói rõ đã đổi sau khi duyệt và cách duyệt lại" sh -c "sh '$CD' design '$F' 2>/dev/null | grep -q 'ĐÃ ĐỔI SAU KHI DUYỆT' && sh '$CD' design '$F' 2>/dev/null | grep -q 'xoá \"<!-- approval-hash'"
viet_spec; viet_tdd
ky_vong 0 "/plan: mọi D đã tick → ĐÃ DUYỆT" sh "$CD" plan "$F"
thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**
- Critique (agent): cân nhắc DB'
ky_vong 1 "/plan: còn D chưa tick → CHƯA DUYỆT" sh "$CD" plan "$F"
OUT_CD=$(sh "$CD" plan "$F" 2>/dev/null)
dung "…đếm D chưa duyệt" sh -c "printf '%s' \"\$1\" | grep -q 'CÒN 1/1 QUYẾT ĐỊNH CHƯA DUYỆT'" _ "$OUT_CD"
dung "…tên D, dòng, tác giả, lựa chọn, có phản biện" sh -c "printf '%s' \"\$1\" | grep -q 'D-01 — lưu ở đâu' && printf '%s' \"\$1\" | grep -q 'dòng [0-9]* · chưa tick' && printf '%s' \"\$1\" | grep -q 'tác giả: agent · Choice: file · có 1 phản biện'" _ "$OUT_CD"
viet_spec; viet_tdd; ghi_based_on

# ---------------------------------------------------------------- chore
echo ""
echo "loại việc: chore"
tao_fixture chore chore_v
for c in truy-vet ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "chore đầy đủ (không có tdd.md) qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done
ky_vong 1 "chore chạy design thì bị chặn" sh "$T/kiem-tra-thiet-ke.sh" "$F"

thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 1 "chore: aw approval plan hỏi duyệt SPEC (không có tdd.md)" sh "$T/cong-duyet.sh" plan "$F"
dung "…đúng cổng spec, không nói Mode" sh -c "sh '$T/cong-duyet.sh' plan '$F' 2>/dev/null | grep -q 'vào /plan cần spec' && sh '$T/cong-duyet.sh' plan '$F' 2>/dev/null | grep -q 'chore không có design'"
ky_vong 2 "chore: aw approval design → SAI THAM SỐ" sh "$T/cong-duyet.sh" design "$F"
ky_vong 1 "chore: plan chặn khi người chưa duyệt spec" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_spec; ghi_based_on

thay "$F/open-questions.md" '`non-blocking`' '`blocking`'
ky_vong 1 "chore: điểm mù \"chặn\" còn mở thì plan chặn (chore không có design)" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_spec; ghi_based_on

printf 'moi\n' > "$R/src/a.txt"
ky_vong 1 "chore đụng code production thì chặn" sh "$T/kiem-tra-hien-thuc.sh" "$F"
g checkout -q -- src/a.txt

printf '{"dependencies":{"lodash":"4.17.21"}}\n' > "$R/package.json"
ky_vong 1 "chore nâng dependency không khai thì chặn" sh "$T/kiem-tra-hien-thuc.sh" "$F"
thay "$F/plan.md" '| Library | Old → new | Level |
|---|---|---|
' '| Library | Old → new | Level |
|---|---|---|
| lodash | 4.17.20 → 4.17.21 | patch |
'
ky_vong 0 "khai nâng bản vá thì cho qua" sh "$T/kiem-tra-hien-thuc.sh" "$F"
thay "$F/plan.md" '| patch |' '| major |'
ky_vong 1 "nâng major không được là chore" sh "$T/kiem-tra-hien-thuc.sh" "$F"
rm -f "$R/package.json"; viet_plan; ghi_based_on

thay "$F/plan.md" '- Expected files: `docs/*`' '- Based on: `D-01`
- Expected files: `docs/*`'
ky_vong 1 "chore: task Dựa trên D-xx bị chặn (không có tdd.md)" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_plan; ghi_based_on

# ---------------------------------------------------------------- doi ten feature
echo ""
echo "aw rename (doi-ten-feature.sh)"
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
ky_vong 3 "tools/cai-dat.sh chỉ in hướng dẫn, không cài gì" sh "$T/cai-dat.sh" "$TMP/khong-quan-trong"
dung "…hướng dẫn dùng aw init / aw init --from-legacy" sh -c "sh '$T/cai-dat.sh' 2>/dev/null | grep -q 'aw init --from-legacy'"
ky_vong 3 "tools/dong-bo.sh chỉ in hướng dẫn aw upgrade" sh "$T/dong-bo.sh"
dung "…nhắc aw upgrade" sh -c "sh '$T/dong-bo.sh' 2>/dev/null | grep -q 'aw upgrade'"

# Repo đích có bộ cài 1.x đã commit vào base (dựng tay đúng cấu trúc cũ)
RL="$TMP/repo-cu"; mkdir -p "$RL/.agent-workflow/.quy-trinh/tools" "$RL/.claude/commands" "$RL/.agent-workflow/feat_cu"
git -C "$RL" init -q; git -C "$RL" checkout -q -b main
printf '# quy ước cũ của team\n```conventions\nmau_branch: feat_* chore_*\nloai_theo_tien_to: feat_=feature chore_=chore\nnhanh_goc: main\n```\n' > "$RL/.agent-workflow/conventions.md"
printf 'LENH_KIEM_THU="make test"\nLENH_CHUAN_BI_WT="npm ci"\n' > "$RL/.agent-workflow/.quy-trinh/cau-hinh.sh"
printf 'url=x\nadapter=claude-code\n' > "$RL/.agent-workflow/.quy-trinh/nguon.txt"
printf 'echo cu\n' > "$RL/.agent-workflow/.quy-trinh/tools/xac-dinh-feature.sh"
printf -- '---\n---\n> **File này được SINH TỰ ĐỘNG** — bản 1.x\nsh .agent-workflow/.quy-trinh/tools/x.sh\n' > "$RL/.claude/commands/spec.md"
printf '# lệnh team tự viết\n' > "$RL/.claude/commands/cua-team.md"
printf 'x\n' > "$RL/.agent-workflow/feat_cu/intake.md"
git -C "$RL" add -A; git -C "$RL" -c user.name=t -c user.email=t@t commit -q -m "bo cai 1.x"
GOCL=$(git -C "$RL" rev-parse HEAD)
CL="$RL/.git/agent-workflow"

ky_vong 2 "--from-legacy ở repo không có bộ cài cũ → SAI THAM SỐ" sh -c "R=\$(mktemp -d '$TMP/x.XXXX') && git -C \"\$R\" init -q && cd \"\$R\" && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' init --from-legacy --version '$VDEV'"
ky_vong 0 "aw init --from-legacy" awd "$RL" init --from-legacy --version "$VDEV"
dung "…conventions.md cũ chuyển vào .git/agent-workflow/" cmp -s "$RL/.agent-workflow/conventions.md" "$CL/conventions.md"
dung "…lệnh trong cau-hinh.sh cũ chuyển sang config.sh" sh -c "grep -qx 'LENH_KIEM_THU=\"make test\"' '$CL/config.sh' && grep -qx 'LENH_CHUAN_BI_WT=\"npm ci\"' '$CL/config.sh' && grep -qx 'ADAPTER=\"claude-code\"' '$CL/config.sh'"
dung "…không xoá gì của bộ cài cũ" sh -c "[ -f '$RL/.agent-workflow/.quy-trinh/cau-hinh.sh' ] && [ -f '$RL/.agent-workflow/conventions.md' ] && [ -f '$RL/.claude/commands/spec.md' ]"
dung "…không commit gì, cây làm việc sạch" sh -c "[ \"\$(git -C '$RL' rev-parse HEAD)\" = '$GOCL' ] && [ -z \"\$(git -C '$RL' status --porcelain)\" ]"
dung "…file .claude/ cũ git đang theo dõi: adapter bỏ qua, nội dung giữ nguyên" grep -q 'bản 1.x' "$RL/.claude/commands/spec.md"
dung "…lệnh người viết tay giữ nguyên" grep -q 'team tự viết' "$RL/.claude/commands/cua-team.md"
dung "…sinh các lệnh mới chưa có" sh -c "[ -f '$RL/.claude/commands/design.md' ] && grep -q 'aw feature' '$RL/.claude/commands/design.md'"
OUTL=$(awd "$RL" init --from-legacy 2>/dev/null)
dung "…in hướng dẫn tự dọn bằng PR: git rm bộ cài cũ" sh -c "printf '%s' \"\$1\" | grep -q 'git rm -r -q -- .agent-workflow/.quy-trinh/' && printf '%s' \"\$1\" | grep -q 'git rm -r -q -- .claude/commands/spec.md'" _ "$OUTL"
dung "…không đề nghị xoá lệnh người viết tay" sh -c "! printf '%s' \"\$1\" | grep -q 'cua-team.md'" _ "$OUTL"
dung "…chạy lại giữ cấu hình đã chuyển" sh -c "grep -qx 'LENH_KIEM_THU=\"make test\"' '$CL/config.sh'"
ky_vong 0 "repo cũ: tạo worktree từ base vẫn chứa bộ cài 1.x" awd "$RL" worktree new feature sau-chuyen --create --base main
dung "…worktree sạch, base không đổi" sh -c "[ -z \"\$(git -C '$TMP/repo-cu.wt/feat_sau-chuyen' status --porcelain)\" ] && [ \"\$(git -C '$RL' rev-parse main)\" = '$GOCL' ]"

# Cấu hình của người: init lại không ghi đè (thay cho các ca của cai-dat.sh)
printf 'LENH_KIEM_THU="npm test"\nADAPTER="claude-code"\n' > "$CL/config.sh"
printf '# của tôi\n```conventions\nmau_branch: job-*\n```\n' > "$CL/conventions.md"
awd "$RL" init >/dev/null 2>&1
dung "init lại KHÔNG ghi đè config.sh người sửa" grep -q 'npm test' "$CL/config.sh"
awd "$RL" init --force >/dev/null 2>&1
dung "KHÔNG ghi đè conventions.md, kể cả --force" grep -q 'của tôi' "$CL/conventions.md"
ky_vong 2 "init --adapter khác ADAPTER trong config.sh → SAI THAM SỐ" awd "$RL" init --adapter cursor

# ---------------------------------------------------------------- khoi "Ket qua"
# Nguoi va agent doc NHAN, khong doc ma so: moi script in khoi nay ra stderr.
echo ""
echo "lib/ket-qua.sh"
KQT="$TMP/kq-thu.sh"
cat > "$KQT" <<EOF
. "$T/lib/ket-qua.sh"
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
dung "checker thiếu file → [x] THIẾU ĐẦU VÀO" sh -c "AW_REPO='$R9' AW_CONFIG='$R9/.git/agent-workflow' sh '$T/kiem-tra-ke-hoach.sh' '$TMP/khong-co' 2>&1 | grep -q '\[x\] THIẾU ĐẦU VÀO'"
dung "checker gọi thẳng, thiếu AW_CONFIG → dừng, không đoán đường dẫn" sh -c "env -u AW_CONFIG sh '$T/kiem-tra-ke-hoach.sh' '$TMP/khong-co' 2>&1 | grep -q 'thiếu AW_CONFIG'"
dung "tool worktree gọi thẳng, thiếu AW_REPO → dừng" sh -c "env -u AW_REPO -u AW_CONFIG sh '$T/xac-dinh-feature.sh' 2>&1 | grep -q 'thiếu AW_REPO'"
dung "aw feature ở checkout chính → [x] ĐANG Ở CHECKOUT CHÍNH" sh -c "printf '%s' \"\$1\" | grep -q '\[x\] ĐANG Ở CHECKOUT CHÍNH'" _ "$(awd "$R9" feature 2>&1)"
dung "…stdout không lẫn khối Kết quả" sh -c "! printf '%s' \"\$1\" | grep -q 'Kết quả'" _ "$(awd "$R9" feature 2>/dev/null)"

# ---------------------------------------------------------------- dong goi (phat hanh)
echo ""
echo "tools/dong-goi.sh"
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
ky_vong 0 "đóng gói bản đúng" sh "$NG/tools/dong-goi.sh" "$TMP/goi1"
dung "ra tarball đúng tên + SHA256SUMS khớp" sh -c "cd '$TMP/goi1' && [ -f agent-workflow-2099.9.1.tar.gz ] && sha256sum -c SHA256SUMS >/dev/null 2>&1"
dung "tarball có thư mục gốc agent-workflow-2099.9.1/ và VERSION" sh -c "gzip -dc '$TMP/goi1/agent-workflow-2099.9.1.tar.gz' | tar tf - | grep -qx 'agent-workflow-2099.9.1/VERSION'"
sh "$NG/tools/dong-goi.sh" "$TMP/goi2" >/dev/null 2>&1
dung "đóng gói lại cùng commit → cùng checksum" cmp -s "$TMP/goi1/SHA256SUMS" "$TMP/goi2/SHA256SUMS"
printf 'chua commit\n' > "$NG/chua-commit.txt"
sh "$NG/tools/dong-goi.sh" "$TMP/goi3" >/dev/null 2>&1
dung "file chưa commit không lọt vào gói" sh -c "! gzip -dc '$TMP/goi3/agent-workflow-2099.9.1.tar.gz' | tar tf - | grep -q chua-commit"
printf 'v2\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam sai
ky_vong 4 "VERSION sai dạng YYYY.M.N → VERSION LỖI" sh "$NG/tools/dong-goi.sh" "$TMP/goi4"
printf '2.0.0\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam semver
ky_vong 4 "VERSION kiểu X.Y.Z (semver) → VERSION LỖI" sh "$NG/tools/dong-goi.sh" "$TMP/goi4b"
printf '2026.13.1\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam thang13
ky_vong 4 "VERSION tháng 13 → VERSION LỖI" sh "$NG/tools/dong-goi.sh" "$TMP/goi4c"
dung "luật version YYYY.M.N: nhận 2026.10.6, 2026.1.6, 2026.12.31, 2026.10.32, 2026.10.100; từ chối 2026.10.06, 2026.01.6, 2026.0.10, 2026.10.0, 2026.10.6.1, 2026.10.1a, v2026.10.6" sh -c ". '$T/lib/version.sh'; ver_hop_le 2026.10.6 && ver_hop_le 2026.1.6 && ver_hop_le 2026.12.31 && ver_hop_le 2026.10.32 && ver_hop_le 2026.10.100 && ! ver_hop_le 2026.10.06 && ! ver_hop_le 2026.01.6 && ! ver_hop_le 2026.0.10 && ! ver_hop_le 2026.10.0 && ! ver_hop_le 2026.10.6.1 && ! ver_hop_le 2026.10.1a && ! ver_hop_le v2026.10.6"
dung "wrapper bin/aw dùng cùng luật version với engine" sh -c "eval \"\$(sed -n '/^version_hop_le() {/,/^}/p' '$ROOT/bin/aw')\"; for v in 2026.10.32 2026.10.100 2026.1.1; do version_hop_le \$v || exit 1; done; for v in 2026.10.0 2026.10.08 2026.10.6.1; do version_hop_le \$v && exit 1; done; exit 0"
ky_vong 2 "ref không tồn tại → sai tham số" sh "$NG/tools/dong-goi.sh" "$TMP/goi5" khong-co
dung "VERSION của repo đúng dạng YYYY.M.N" sh -c ". '$T/lib/version.sh'; ver_hop_le \"\$(cat '$ROOT/VERSION')\""
dung "workflow release gắn file vào release đã có (tạo tag trên giao diện GitHub)" sh -c "grep -q 'gh release upload \"\$TAG\" dist/\* --clobber' '$ROOT/.github/workflows/release.yml' && grep -q 'gh release create \"\$TAG\"' '$ROOT/.github/workflows/release.yml'"
dung "workflow release chạy khi merge vào main, bỏ qua khi tag đã có" sh -c "grep -q 'branches: \[main\]' '$ROOT/.github/workflows/release.yml' && grep -q 'ls-remote --exit-code --tags origin' '$ROOT/.github/workflows/release.yml'"
dung "workflow kiem-tra của PR chạy kiểm version + test" sh -c "grep -q 'kiem-tra-phat-hanh.sh \"origin/\$BASE\"' '$ROOT/.github/workflows/kiem-tra.yml' && grep -q 'chay-thu.sh' '$ROOT/.github/workflows/kiem-tra.yml'"
dung "workflow release bắt tag dạng YYYY.M.N, không có v" grep -qF "tags: ['[0-9][0-9][0-9][0-9].[0-9]+.[0-9]+']" "$ROOT/.github/workflows/release.yml"
dung "CHANGELOG.md có mục cho VERSION" grep -qF "## [$(cat "$ROOT/VERSION")]" "$ROOT/CHANGELOG.md"

# ---------------------------------------------------------------- chuẩn bị + kiểm phát hành
echo ""
echo "tools/chuan-bi-phat-hanh.sh + tools/kiem-tra-phat-hanh.sh"
git_t() { _gt_d=$1; shift; git -C "$_gt_d" -c user.name=t -c user.email=t@t "$@"; }
PH="$TMP/ph"; PHO="$TMP/ph-origin.git"
tao_nguon "$PH" 2099.9.1
rm -rf "$PHO"; git init -q --bare "$PHO"; git -C "$PH" remote add origin "$PHO"
git -C "$PH" push -q origin main 2>/dev/null
git -C "$PH" tag 2099.9.1; git -C "$PH" push -q origin 2099.9.1 2>/dev/null
ph_cl() { printf '# Changelog\n\n## [Chưa phát hành]\n\n- thay đổi mới\n\n## [2099.9.1]\n\n- cũ\n' > "$PH/CHANGELOG.md"; }
ph_cl; git_t "$PH" commit -qam cl
ky_vong 0 "kiểm phát hành: VERSION không đổi so với base → đạt" sh "$PH/tools/kiem-tra-phat-hanh.sh" main
ky_vong 4 "chuẩn bị: version truyền tay trùng tag đã có → VERSION LỖI" sh "$PH/tools/chuan-bi-phat-hanh.sh" 2099.9.1
ky_vong 4 "chuẩn bị: version sai dạng (số 0 đứng đầu) → VERSION LỖI" sh "$PH/tools/chuan-bi-phat-hanh.sh" 2099.09.2
ky_vong 0 "chuẩn bị: version truyền tay" sh "$PH/tools/chuan-bi-phat-hanh.sh" 2099.9.2
dung "…ghi VERSION, bin/aw, CHANGELOG cùng một version" sh -c "grep -qx 2099.9.2 '$PH/VERSION' && grep -q '^AW_WRAPPER_VERSION=\"2099.9.2\"' '$PH/bin/aw' && grep -qx '## \[2099.9.2\]' '$PH/CHANGELOG.md' && ! grep -q 'Chưa phát hành' '$PH/CHANGELOG.md'"
dung "…link tải wrapper trong README trỏ version mới" grep -q 'releases/download/2099.9.2/aw' "$PH/README.md"
git -C "$PH" checkout -q -b pr; git_t "$PH" commit -qam "phát hành 2099.9.2"
ky_vong 0 "kiểm phát hành: PR đổi VERSION, tag chưa có → đạt" sh "$PH/tools/kiem-tra-phat-hanh.sh" main
git -C "$PH" tag 2099.9.2 main; git -C "$PH" push -q origin 2099.9.2 2>/dev/null
ky_vong 1 "kiểm phát hành: PR khác đã lấy số này (tag có rồi) → KHÔNG ĐẠT" sh "$PH/tools/kiem-tra-phat-hanh.sh" main
thay "$PH/bin/aw" 'AW_WRAPPER_VERSION="2099.9.2"' 'AW_WRAPPER_VERSION="2099.9.1"'
ky_vong 1 "kiểm phát hành: bin/aw lệch VERSION → KHÔNG ĐẠT" sh "$PH/tools/kiem-tra-phat-hanh.sh"
git -C "$PH" checkout -q -- bin/aw
thay "$PH/CHANGELOG.md" '## [2099.9.2]' '## [Chưa phát hành]'
ky_vong 1 "kiểm phát hành: CHANGELOG thiếu mục cho VERSION → KHÔNG ĐẠT" sh "$PH/tools/kiem-tra-phat-hanh.sh"
git -C "$PH" checkout -q -- .; git -C "$PH" checkout -q main; git -C "$PH" branch -qD pr
ph_cl; git_t "$PH" commit -qam cl2
THANG_NAY="$(date +%Y).$(date +%m | sed 's/^0//')"
git -C "$PH" tag "$THANG_NAY.1"; git -C "$PH" tag "$THANG_NAY.3"; git -C "$PH" push -q origin --tags 2>/dev/null
ky_vong 0 "chuẩn bị: tự tính version" sh "$PH/tools/chuan-bi-phat-hanh.sh"
dung "…= tháng này, số lớn nhất ở remote + 1" grep -qx "$THANG_NAY.4" "$PH/VERSION"
git -C "$PH" checkout -q -- .
git -C "$PH" tag "$THANG_NAY.9"
ky_vong 0 "chuẩn bị: tag chỉ có ở máy, chưa lên remote → không tính" sh "$PH/tools/chuan-bi-phat-hanh.sh"
dung "…vẫn là số kế tiếp ở remote" grep -qx "$THANG_NAY.4" "$PH/VERSION"
git -C "$PH" checkout -q -- .
printf '# Changelog\n\n## [2099.9.1]\n\n- cũ\n' > "$PH/CHANGELOG.md"
ky_vong 3 "chuẩn bị: CHANGELOG không có [Chưa phát hành] → KHÔNG CÓ GÌ ĐỂ PHÁT HÀNH" sh "$PH/tools/chuan-bi-phat-hanh.sh"
dung "…không đổi file nào" sh -c "grep -qx 2099.9.1 '$PH/VERSION'"

# ---------------------------------------------------------------- wrapper aw
echo ""
echo "bin/aw (wrapper)"
unset AW_REPO AW_CONFIG
AWH="$TMP/awhome"; MIR="$TMP/mirror"
# Mirror giả (file://): mỗi version là một bản phát hành đóng gói từ repo này.
for v in 2099.1.1 2099.1.2; do
  tao_nguon "$TMP/nguon-$v" "$v"
  sh "$TMP/nguon-$v/tools/dong-goi.sh" "$MIR/$v" >/dev/null 2>&1
done
tao_nguon "$TMP/nguon-2099.1.4" 2099.1.4
sh "$TMP/nguon-2099.1.4/tools/dong-goi.sh" "$MIR/2099.1.4" >/dev/null 2>&1
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
dung "…ghi version, checksums, conventions.md, config.sh vào .git/agent-workflow/" sh -c \
  "grep -qx 2099.1.1 '$C7/version' && grep -q ' agent-workflow-2099.1.1.tar.gz' '$C7/checksums' && [ -f '$C7/conventions.md' ] && grep -q 'LENH_KIEM_THU=\"true\"' '$C7/config.sh'"
dung "…engine vào cache theo version, có dấu sha256" sh -c "[ -f '$AWH/engine/2099.1.1/bin/aw-engine' ] && [ -s '$AWH/engine/2099.1.1/.aw-sha256' ]"
dung "…sha ghim khớp SHA256SUMS của bản phát hành" sh -c "grep -qF \"\$(awk '\$2 == \"agent-workflow-2099.1.1.tar.gz\" { print \$1 }' '$MIR/2099.1.1/SHA256SUMS')\" '$C7/checksums'"
dung "…exclude /.agent-workflow/ và /.claude/" sh -c "grep -qx '/.agent-workflow/' '$R7/.git/info/exclude' && grep -qx '/.claude/' '$R7/.git/info/exclude'"
dung "…sinh adapter ở checkout chính" test -f "$R7/.claude/commands/intake.md"
dung "…không có commit nào vào base" bang "$(git -C "$R7" rev-parse HEAD)" "$GOC7"
dung "…cây làm việc sạch: file sinh ra không lọt vào git status" sh -c "[ -z \"\$(git -C '$R7' status --porcelain)\" ]"
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
dung "…vẫn không có commit nào, cây sạch" sh -c "[ \"\$(git -C '$R7' rev-parse HEAD)\" = '$GOC7' ] && [ -z \"\$(git -C '$R7' status --porcelain)\" ]"

# cấu hình dùng chung của team: một repo riêng chứa version, checksums, conventions.md
TEAM="$TMP/team-cfg"; mkdir -p "$TEAM"; git -C "$TEAM" init -q
cp "$C7/version" "$C7/checksums" "$TEAM/"; printf '# của team\n' > "$TEAM/conventions.md"
git -C "$TEAM" add -A; git -C "$TEAM" -c user.name=t -c user.email=t@t commit -q -m cfg
R8="$TMP/repo8"; git clone -q "$R7" "$R8" 2>/dev/null
ky_vong 0 "aw init --from <repo cấu hình team>" sh -c "cd '$R8' && AW_HOME='$AWH' AW_MIRROR='file://$MIR' sh '$ROOT/bin/aw' init --from '$TEAM'"
dung "…lấy version, checksums, conventions.md của team" sh -c "grep -qx 2099.1.2 '$R8/.git/agent-workflow/version' && grep -q 'của team' '$R8/.git/agent-workflow/conventions.md' && cmp -s '$TEAM/checksums' '$R8/.git/agent-workflow/checksums'"
ky_vong 9 "--from repo không có file version → KHÔNG HỢP LỆ" sh -c "cd '$R8' && AW_HOME='$AWH' sh '$ROOT/bin/aw' init --from '$R7'"
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

# ---------------------------------------------------------------- tong ket
echo ""
echo "─────────────────────────────────────────"
printf 'Tổng: %d ca — %d đạt, %d hỏng\n' "$((n_ok + n_fail))" "$n_ok" "$n_fail"
[ "$n_fail" -gt 0 ] && exit 1
exit 0
