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
ky_vong 1 "chặn điểm mù \"chặn\" còn mở" sh "$CHK" "$F"
dung "…đúng lý do: REQ-002 mức chặn" sh -c "sh '$CHK' '$F' | grep -q 'REQ-002: open question mức \"blocking\"'"
thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** qua email\n' >> "$F/open-questions.md"
thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)' '`[FILE]` [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Quote: > qua email'
duyet_lai "$F/spec.md"
ky_vong 0 "đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong_ly_do 1 "chặn vào design khi người chưa duyệt spec" "…đúng lý do: spec chưa được người duyệt" 'chưa được người duyệt' sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Assumption: y' '`[JIRA]` ABC-1
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
dung "…nhưng cảnh báo câu trích lệch" sh -c "sh '$CHK' '$F' | grep -qF '[CẢNH BÁO] REQ-001: câu trích không có trong docs/brd.md'"
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
dung "…không cảnh báo khi hoãn REQ nên có" sh -c "! sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*REQ-002: Priority must'"
thay "$F/plan.md" '| REQ-002 | chờ BA |' '| REQ-002 | chờ BA |
| REQ-001 | để sau |'
ky_vong 0 "hoãn REQ bắt buộc không chặn" sh "$CHK" "$F"
dung "…nhưng cảnh báo giao thiếu" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*REQ-001: Priority must'"
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
ky_vong 0 "glob khớp nhiều file hơn ngưỡng → vẫn ĐẠT" sh "$CHK" "$F"
dung "…kèm CẢNH BÁO nêu task, mẫu, số file" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*TSK-001: \`\*\` khớp [0-9]* file trên base — thu hẹp mẫu (ngưỡng scope_glob_max_files: 1)'"
thay "$CFG/conventions.md" 'scope_glob_max_files: 1' 'scope_glob_max_files: 0'
dung "scope_glob_max_files: 0 → tắt cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'thu hẹp mẫu'"
thay "$CFG/conventions.md" 'scope_glob_max_files: 0' 'scope_glob_max_files: 1'
thay "$F/plan.md" '- Expected files: `*`' '- Expected files: `moi/*`'
dung "glob khớp 0 file (task tạo file mới) → không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'thu hẹp mẫu'"
cp "$TMP/conv-glob.bak" "$CFG/conventions.md"
viet_plan; ghi_based_on
dung "mẫu hẹp, ngưỡng mặc định → không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'thu hẹp mẫu'"

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
ky_vong 0 "task chỉ có Fixes: RVW có trong review.md → ĐẠT" sh "$CHK" "$F"
viet_plan; ghi_based_on; them_task_sua '- Fixes: `RVW-009`' '[ ]'
ky_vong 1 "Fixes: RVW không có trong review.md → chặn" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'TSK-003: \"Fixes: RVW-009\" nhưng review.md không có finding mã đó'"
viet_plan; ghi_based_on; them_task_sua '- Fixes: `RVW-009`' '[x]'
dung "Fixes trên task [x] (review đã ghi lại) → không kiểm mã" sh -c "! sh '$CHK' '$F' | grep -q 'RVW-009'"
viet_plan; ghi_based_on; them_task_sua '- Depends on: none' '[ ]'
ky_vong 1 "task không Covers, không Fixes → chặn" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'TSK-003: thiếu \"Covers:\" hoặc \"Fixes:\" — task phải phủ một REQ hoặc sửa một finding review'"
viet_plan; ghi_based_on; them_task_sua '- Fixes: https://gitlab.vd/nhom/repo/-/merge_requests/1#note_2' '[ ]'
ky_vong 0 "Fixes: URL bình luận MR → ĐẠT" sh "$CHK" "$F"
viet_plan; ghi_based_on; them_task_sua '- Fixes: abc' '[ ]'
ky_vong 1 "Fixes: giá trị lạ → chặn" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'TSK-003: \"Fixes:\" \"abc\" — chỉ nhận RVW-NNN hoặc URL bình luận MR'"
# Trọn vòng: review có RVW-001 → plan bổ sung task Fixes → aw task next trả task mới → review chặn tới khi xong
viet_review; thay "$F/review.md" '- None' "$L3_SF"; toc_f review.md
viet_plan; ghi_based_on; them_task_sua '- Fixes: `RVW-001`' '[ ]'
ky_vong 0 "trọn vòng: plan bổ sung ĐẠT" sh "$CHK" "$F"
dung "…aw task next trả task sửa mới" bang "$(sh "$T/task.sh" next "$F" 2>/dev/null)" "TSK-003"
ghi_tree_review
ky_vong 1 "…review chặn khi task sửa chưa xong" sh "$T/check-review.sh" "$F"
dung "…đúng lý do" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'TSK-003 chưa làm'"
viet_plan; ghi_based_on; viet_review

ket_thuc
