#!/usr/bin/env sh
# check-design, check-plan.
# Chạy riêng: sh tools/tests/02-design-plan.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
tao_fixture

# ---------------------------------------------------------------- thiet ke
nhom "check-design.sh"
CHK="$T/check-design.sh"

viet_spec; viet_tdd
rm -f "$F/design-findings.md"
ky_vong 1 "chặn khi checker LLM chưa chạy (không có file phát hiện ≠ đạt)" sh "$CHK" "$F"

printf '### FND-001 — x\n- Severity: `block`\n- Resolution: `open`   <!-- open | fixed -->\n' > "$F/design-findings.md"
ky_vong 1 "chặn phát hiện block chưa xử lý" sh "$CHK" "$F"

printf '### FND-001 — x\n- Severity: `block`\n- Resolution: `rejected:`\n' > "$F/design-findings.md"
ky_vong 1 "chặn bác bỏ phát hiện mà không có lý do" sh "$CHK" "$F"

printf '### FND-001 — x\n- Severity: `block`\n- Resolution: rejected: DEC-001 đã nói rõ\n### FND-002 — y\n- Severity: `warn`\n- Resolution: open\n' > "$F/design-findings.md"
toc_f design-findings.md
ky_vong 0 "bác bỏ có lý do + cảnh báo chưa xử lý thì cho qua" sh "$CHK" "$F"

# Việc tạo trước khi đổi sang tiếng Anh: trường cũ (Mức / Xử lý) vẫn đọc được
printf '### FND-001 — x\n- Mức: `Chặn`\n- Xử lý: `chưa`   <!-- chưa | đã sửa -->\n' > "$F/design-findings.md"
ky_vong 1 "trường cũ: phát hiện Chặn chưa xử lý vẫn bị chặn" sh "$CHK" "$F"
printf '### FND-001 — x\n- Mức: `Chặn`\n- Xử lý: bác bỏ: DEC-001 đã nói rõ\n### FND-002 — y\n- Mức: `Cảnh báo`\n- Xử lý: chưa\n' > "$F/design-findings.md"
toc_f design-findings.md
ky_vong 0 "trường cũ: bác bỏ có lý do + cảnh báo thì cho qua" sh "$CHK" "$F"
printf '### FND-001 — x\n- Severity: `block`\n- Resolution: fixed\n- Problem: Location và Resolution: chưa rõ\n' > "$F/design-findings.md"
toc_f design-findings.md
ky_vong 0 "tên trường chỉ khớp ở đầu dòng, không khớp trong nội dung" sh "$CHK" "$F"
printf '### FND-01 — x\n- Severity: `warn`\n- Resolution: open\n' > "$F/design-findings.md"
ky_vong_ly_do 1 "chặn mã FND sai dạng" "…đúng lý do" 'FND-01 sai dạng' sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" "### DEC-001" "### DEC-1"; duyet_lai "$F/tdd.md"
ky_vong_ly_do 1 "chặn mã DEC sai dạng" "…đúng lý do" 'DEC-1 sai dạng' sh "$CHK" "$F"

viet_tdd; thay "$F/open-questions.md" '`non-blocking`' '`review-blocking`'
ky_vong 0 "điểm mù \"chặn review\" còn mở không chặn design" sh "$CHK" "$F"
viet_spec; viet_tdd; thay "$F/open-questions.md" '`non-blocking`' '`blocking`'
ky_vong_ly_do 1 "chặn điểm mù \"chặn\" còn mở" "…đúng lý do: Q-001 (REQ-002) mức chặn" 'Q-001 (REQ-002): open question mức "blocking"' sh "$CHK" "$F"
thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** qua email\n' >> "$F/open-questions.md"
thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)' '`[FILE]` [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)
- Quote: > qua email'
duyet_lai "$F/spec.md"
ky_vong 0 "đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong_ly_do 1 "chặn vào design khi người chưa duyệt spec" "…đúng lý do: spec chưa được người duyệt" 'chưa được người duyệt' sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)' '`[JIRA]` ABC-1
- Quote: > khách mở y thấy b'
: > "$F/open-questions.md"
ky_vong 0 "open-questions.md 0 byte không làm design đọc lệch file" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' ''
ky_vong 1 "chặn khi đầu vào spec không qua checker của spec" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/tdd.md" '## Test strategy' '## Kiểm thử'
ky_vong 1 "chặn tdd thiếu mục bắt buộc" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" "## Target structure" "## Cấu trúc"
ky_vong 1 "chặn tdd thiếu mục Target structure" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" "Triển khai một lần, quay lui bằng revert commit." ""
ky_vong 1 "chặn mục Rollout & rollback bỏ trống" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" "Triển khai một lần, quay lui bằng revert commit." "Not applicable: chỉ đổi code nội bộ."
ky_vong 0 "Rollout & rollback ghi Not applicable có lý do thì cho qua" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Unit test.' ''
ky_vong 1 "chặn mục bỏ trống không ghi Không áp dụng" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Not applicable: không có API công khai.' 'Not applicable:'
ky_vong 1 "chặn Không áp dụng mà không có lý do" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '| REQ-002 | § Flow |' ''
ky_vong 1 "chặn REQ chưa được ánh xạ" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Based on: DEC-001' 'Based on: DEC-009'
ky_vong 1 "chặn Dựa trên trỏ về DEC không tồn tại" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' ''
ky_vong 1 "chặn DEC-xxx thiếu ô duyệt" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- Status: `approved`'
ky_vong 1 "chặn DEC-xxx dạng cũ \"Status:\"" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- [x] **Approved by human**
- [x] **Approved by human**'
ky_vong 1 "chặn DEC-xxx có hai ô duyệt" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '## Contract / API' '- [x] **Approved by human**

## Contract / API'
ky_vong 1 "chặn ô duyệt nằm ngoài mục DEC-xxx" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**
- Reopen reason: đổi sang DB'
ky_vong 0 "DEC mở lại (bỏ tick + lý do) thì thiết kế vẫn hợp lệ" sh "$CHK" "$F"
dung "…và hiện là mở lại" sh -c "sh '$CHK' '$F' | grep -q 'DEC-001  *reopened'"

viet_tdd
ky_vong 0 "DEC đã tick qua checker design" sh "$CHK" "$F"
thay "$F/tdd.md" '- Choice: file' '- Choice: file
- Critique (agent): nên cân nhắc DB
  vì dữ liệu sẽ lớn'
ky_vong 0 "agent thêm phản biện không làm mất duyệt D" sh "$CHK" "$F"
thay "$F/tdd.md" '- Choice: file' '- Choice: DB'
ky_vong 1 "chặn DEC đổi nội dung sau khi người duyệt" sh "$CHK" "$F"
duyet_lai "$F/tdd.md"
ky_vong 0 "người xoá dấu duyệt DEC thì duyệt lại bản mới" sh "$CHK" "$F"

viet_tdd; thay "$F/spec.md" '`normal`' '`high`'; duyet_lai "$F/spec.md"
ky_vong 1 "Mode 2: chặn rủi ro cao mà không có DEC do người viết" sh "$CHK" "$F"
thay "$F/tdd.md" '`agent`' '`human`'; duyet_lai "$F/tdd.md"
ky_vong 0 "Mode 2: có DEC Author: human thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/tdd.md" '## Decisions (DEC-xxx)' '## Decisions (DEC-xxx)
Không có quyết định cần duyệt.
## Bỏ'
thay "$F/tdd.md" 'Based on: DEC-001' ''
toc_f tdd.md
ky_vong 0 "mục Quyết định được phép rỗng" sh "$CHK" "$F"
viet_tdd


# Nguồn [FILE] đổi sau khi viết spec: design chạy lại spec, chỉ cảnh báo
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` docs/brd.md § Hoàn tiền'
thay "$F/spec.md" '  > khách mở y thấy a' '  > Khách được hoàn tiền trong vòng 30 ngày.'
printf 'Khách được hoàn tiền trong vòng 30 ngày.\n' > "$R/docs/brd.md"
duyet_lai "$F/spec.md"
ky_vong 0 "câu trích [FILE] khớp → design qua" sh "$CHK" "$F"
printf 'Khách được hoàn tiền trong vòng 60 ngày.\n' > "$R/docs/brd.md"
ky_vong 0 "nguồn đổi sau spec → design không chặn" sh "$CHK" "$F"
dung "…nhưng cảnh báo câu trích lệch" sh -c "sh '$CHK' '$F' | grep -qF '[WARN] REQ-001: câu trích không có trong docs/brd.md'"
ky_vong 1 "…còn aw check spec thì chặn" sh "$T/check-spec.sh" "$F"
rm -f "$R/docs/brd.md"
viet_spec

# ---------------------------------------------------------------- ke hoach
nhom "check-plan.sh"
CHK="$T/check-plan.sh"
ghi_based_on

thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
ky_vong 1 "chặn khi còn DEC-xxx chưa được người duyệt" sh "$CHK" "$F"
viet_tdd; ghi_based_on

rm -f "$F/design-findings.md"
ky_vong 1 "chặn khi tdd.md không qua checker của design" sh "$CHK" "$F"
viet_tdd; ghi_based_on

viet_plan; thay "$F/plan.md" '### TSK-001' '### TSK-0001'
ky_vong_ly_do 1 "chặn mã TSK sai dạng" "…đúng lý do" 'TSK-0001 sai dạng' sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Covers: `REQ-002`' '- Covers: `REQ-001`'
ky_vong 1 "chặn YÊU CẦU BỊ BỎ SÓT (chiều ngược)" sh "$CHK" "$F"
thay "$F/plan.md" '|---|---|
' '|---|---|
| REQ-002 | chờ BA |
'
ky_vong 0 "hoãn lại có lý do thì cho qua" sh "$CHK" "$F"
dung "…không cảnh báo khi hoãn REQ nên có" sh -c "! sh '$CHK' '$F' | grep -q 'WARN.*REQ-002: Priority must'"
thay "$F/plan.md" '| REQ-002 | chờ BA |' '| REQ-002 | chờ BA |
| REQ-001 | để sau |'
ky_vong 0 "hoãn REQ bắt buộc không chặn" sh "$CHK" "$F"
dung "…nhưng cảnh báo giao thiếu" sh -c "sh '$CHK' '$F' | grep -q 'WARN.*REQ-001: Priority must'"
thay "$F/plan.md" '
| REQ-001 | để sau |' ''
thay "$F/plan.md" '| REQ-002 | chờ BA |' '| REQ-002 | |'
ky_vong 1 "chặn hoãn lại bỏ trống lý do" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '`REQ-002`' '`REQ-999`'
ky_vong 1 "chặn task trỏ về mã REQ không tồn tại (chiều xuôi)" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Based on: `DEC-001`' '- Based on: `DEC-007`'
ky_vong 1 "chặn task Dựa trên DEC không có trong tdd.md" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Expected files: `src/b.txt`' ''
ky_vong 1 "chặn task thiếu File dự kiến" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Verify: `test -f src/a.txt` → có file
- Status: `[x]`

## Deferred' '- Verify: <lệnh cụ thể>
- Status: `[x]`

## Deferred'
ky_vong 1 "chặn chỗ giữ chỗ chưa điền" sh "$CHK" "$F"
viet_plan; ghi_based_on

# Glob rộng ở Expected files: đếm file đã track trên commit Base khớp mẫu; vượt scope_glob_max_files → cảnh báo
cp "$CFG/conventions.md" "$TMP/conv-glob.bak"
thay "$CFG/conventions.md" 'scope_glob_max_files: 30' 'scope_glob_max_files: 1'
thay "$F/plan.md" '- Expected files: `src/*` `test/*`' '- Expected files: `*`'
ky_vong 0 "glob khớp nhiều file hơn ngưỡng → vẫn PASS" sh "$CHK" "$F"
dung "…kèm WARN nêu task, mẫu, số file" sh -c "sh '$CHK' '$F' | grep -q 'WARN.*TSK-001: \`\*\` khớp [0-9]* file trên base — thu hẹp mẫu (ngưỡng scope_glob_max_files: 1)'"
thay "$CFG/conventions.md" 'scope_glob_max_files: 1' 'scope_glob_max_files: 0'
dung "scope_glob_max_files: 0 → tắt cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'thu hẹp mẫu'"
thay "$CFG/conventions.md" 'scope_glob_max_files: 0' 'scope_glob_max_files: 1'
thay "$F/plan.md" '- Expected files: `*`' '- Expected files: `moi/*`'
dung "glob khớp 0 file (task tạo file mới) → không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'thu hẹp mẫu'"
cp "$TMP/conv-glob.bak" "$CFG/conventions.md"
viet_plan; ghi_based_on
dung "mẫu hẹp, ngưỡng mặc định → không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'thu hẹp mẫu'"
# Base: chỉ có ref (thiếu sha) → vẫn đếm glob rộng trên merge-base
cp "$CFG/conventions.md" "$TMP/conv-glob2.bak"; cp "$F/intake.md" "$TMP/intake-glob.bak"
thay "$CFG/conventions.md" 'scope_glob_max_files: 30' 'scope_glob_max_files: 1'
sed 's/^\(- \*\*Base:\*\* `main`\).*/\1/' "$TMP/intake-glob.bak" > "$F/intake.md"
thay "$F/plan.md" '- Expected files: `src/*` `test/*`' '- Expected files: `*`'
dung "Base thiếu sha → vẫn cảnh báo glob rộng" sh -c "sh '$CHK' '$F' | grep -q 'thu hẹp mẫu'"
cp "$TMP/conv-glob2.bak" "$CFG/conventions.md"; cp "$TMP/intake-glob.bak" "$F/intake.md"; viet_plan; ghi_based_on

# Plan bổ sung sau review: task sửa finding trỏ về mã RVW (hoặc URL bình luận MR) bằng "Fixes:"
# them_task_sua <dòng Fixes / Covers> <Status> — thêm TSK-003 trước "## Deferred"
them_task_sua() { thay "$F/plan.md" '## Deferred' "### TSK-003 — sửa finding review
$1
- Expected files: \`src/a.txt\`
- Verify: \`true\` → xanh
- Status: \`$2\`

## Deferred"; toc_f plan.md; }
viet_review; thay "$F/review.md" '- None' "$L3_SF"; toc_f review.md
viet_plan; ghi_based_on; them_task_sua '- Fixes: `RVW-001`' '[ ]'
ky_vong 0 "task chỉ có Fixes: RVW có trong review.md → PASS" sh "$CHK" "$F"
viet_plan; ghi_based_on; them_task_sua '- Fixes: `RVW-009`' '[ ]'
ky_vong_ly_do 1 "Fixes: RVW không có trong review.md → chặn" "…đúng lý do" 'TSK-003: "Fixes: RVW-009" nhưng review.md không có finding mã đó' sh "$CHK" "$F"
viet_plan; ghi_based_on; them_task_sua '- Fixes: `RVW-009`' '[x]'
dung "Fixes trên task [x] (review đã ghi lại) → không kiểm mã" sh -c "! sh '$CHK' '$F' | grep -q 'RVW-009'"
viet_plan; ghi_based_on; them_task_sua '- Depends on: none' '[ ]'
ky_vong_ly_do 1 "task không Covers, không Fixes → chặn" "…đúng lý do" 'TSK-003: thiếu "Covers:" hoặc "Fixes:" — task phải phủ một REQ hoặc sửa một finding review' sh "$CHK" "$F"
viet_plan; ghi_based_on; them_task_sua '- Fixes: https://gitlab.vd/nhom/repo/-/merge_requests/1#note_2' '[ ]'
ky_vong 0 "Fixes: URL bình luận MR → PASS" sh "$CHK" "$F"
viet_plan; ghi_based_on; them_task_sua '- **Fixes:** `RVW-001`' '[ ]'
ky_vong 0 "Fixes dạng in đậm (- **Fixes:**) → PASS" sh "$CHK" "$F"
viet_plan; ghi_based_on; them_task_sua '- Fixes: abc' '[ ]'
ky_vong_ly_do 1 "Fixes: giá trị lạ → chặn" "…đúng lý do" 'TSK-003: "Fixes:" "abc" — chỉ nhận RVW-NNN hoặc URL bình luận MR' sh "$CHK" "$F"
# Trọn vòng: review có RVW-001 → plan bổ sung task Fixes → aw task next trả task mới → review chặn tới khi xong
viet_review; thay "$F/review.md" '- None' "$L3_SF"; toc_f review.md
viet_plan; ghi_based_on; them_task_sua '- Fixes: `RVW-001`' '[ ]'
ky_vong 0 "trọn vòng: plan bổ sung PASS" sh "$CHK" "$F"
dung "…aw task next trả task sửa mới" bang "$(sh "$T/task.sh" next "$F" 2>/dev/null)" "TSK-003"
ghi_tree_review
ky_vong_ly_do 1 "…review chặn khi task sửa chưa xong" "…đúng lý do" 'TSK-003 chưa làm' sh "$T/check-review.sh" "$F"
# Cùng một cách đọc mã RVW với check-review: [mức] có thể đứng sau chữ khác trong tiêu đề Lens 3
viet_review; thay "$F/review.md" '- None' "$(printf '%s\n' "$L3_SF" | sed 's/^### \[Should fix\]/### 1. [Should fix]/')"; toc_f review.md
viet_plan; ghi_based_on; them_task_sua '- Fixes: `RVW-001`' '[ ]'
ky_vong 0 "Fixes trỏ finding có tiêu đề '### 1. [Should fix] RVW-001 — …' → PASS" sh "$CHK" "$F"
viet_plan; ghi_based_on; viet_review


# ---------------------------------------------------------------- bộ đọc token Expected files
# Ba nơi đọc token backtick của plan.md (kc_pham_vi, kc_glob_rong, kt_duong_plan) dùng chung một
# bộ đọc; ca dưới ghim hành vi riêng của từng nơi trên cùng một plan.
nhom "bộ đọc token Expected files (kc_pham_vi / kc_glob_rong / kt_duong_plan)"
TR="$TMP/tok-repo"; TF="$TR/.agent-workflow/tok"
mkdir -p "$TF" "$TR/src" "$TR/tài-liệu" "$TR/ngoai"
gt() { git -C "$TR" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
gt init -q; gt checkout -q -b main
for _p in src/a.txt src/b.txt tài-liệu/x.txt tài-liệu/y.txt ngoai/z.txt ngoai/w.txt; do printf 'x\n' > "$TR/$_p"; done
gt add src tài-liệu ngoai; gt commit -q -m goc; gt checkout -q -b tok
mkdir -p "$TR/.git/agent-workflow"
sed 's/^scope_glob_max_files: 30/scope_glob_max_files: 1/' "$ROOT/workflow/templates/conventions.md" > "$TR/.git/agent-workflow/conventions.md"
printf -- '- **Base:** `main` @ `%s`\n' "$(git -C "$TR" rev-parse main)" > "$TF/intake.md"
cat > "$TF/plan.md" <<'EOF'
# Plan — tok

## Tasks

- Expected files: `ngoai/*`

### TSK-001 — a
- Expected files: `src/*` `tài-liệu/*`

#### chi tiết
- Expected files: `src/**`

### Ghi chú
- Expected files: `ngoai/**`

## Unplanned

| Task | What came up | Extra files | Resolution |
|---|---|---|---|
| TSK-001 | `bo/qua.txt` | `them/*.txt` | ok |

- `le/x.txt`
EOF
mkdir -p "$TR/them" "$TR/bo" "$TR/le"
for _p in ngoai/n.txt them/a.txt bo/qua.txt le/x.txt khac.txt; do printf 'y\n' > "$TR/$_p"; done
tok_goi() { AW_REPO="$TR" AW_CONFIG="$TR/.git/agent-workflow" sh -c ". '$T/lib/result.sh'; . '$T/lib/md.sh'; . '$T/lib/adr.sh'; . '$T/lib/rule.sh'; . '$T/lib/cross-check.sh'; . '$T/lib/knowledge.sh'; $1" 2>/dev/null | tr '\n' '|'; }
dung "kc_pham_vi: Expected files mọi nơi + Unplanned (cột Extra files, dòng lẻ) là mẫu được phép" \
  bang "$(tok_goi "kc_pham_vi '$TF'" | sed 's/: thay đổi ngoài phạm vi[^|]*//g')" "bo/qua.txt|khac.txt|"
dung "kc_glob_rong: chỉ Expected files dưới heading TSK (#### giữ task); đường dẫn có dấu vẫn đếm" \
  bang "$(tok_goi "kc_glob_rong '$TF'")" "TSK-001: \`src/*\` khớp 2 file trên base — thu hẹp mẫu (ngưỡng scope_glob_max_files: 1)|TSK-001: \`tài-liệu/*\` khớp 2 file trên base — thu hẹp mẫu (ngưỡng scope_glob_max_files: 1)|TSK-001: \`src/**\` khớp 2 file trên base — thu hẹp mẫu (ngưỡng scope_glob_max_files: 1)|"
dung "kt_duong_plan: chỉ Expected files dưới heading TSK, mở rộng glob qua cây Base" \
  bang "$(tok_goi "kt_duong_plan '$TF' '$TR/.git/agent-workflow/conventions.md'")" "src|src/a.txt|src/b.txt|tài-liệu|tài-liệu/x.txt|tài-liệu/y.txt|"

ket_thuc
