#!/usr/bin/env sh
# check-review: Lens 3, Conclusion, Reviewed tree, code nhạy cảm.
# Chạy riêng: sh tools/tests/05-review-quality.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
fixture_sau_bao_mat
nhom "check-review.sh"
CHK="$T/check-review.sh"

# ---- Lens 3 — Quality, Conclusion, Reviewed tree
viet_review; thay "$F/review.md" '- None
' ''
ky_vong_ly_do 1 "chặn Lens 3 không finding mà không ghi \"- None\"" "…đúng lý do" 'không ghi "- None"' sh "$CHK" "$F"
viet_review; thay "$F/review.md" '## Lens 3 — Quality' '## Ghi chú'
ky_vong 1 "chặn khi thiếu mục Lens 3 — Quality" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' "$L3_SF"
toc_f review.md
ky_vong 0 "Lens 3 có finding đủ Location file:dòng thì cho qua" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' "- None
$L3_SF"
ky_vong 1 "chặn Lens 3 vừa \"- None\" vừa có finding" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Should fix] RVW-001 — trùng hàm
- Category: duplicate-code
- Problem: có sẵn hàm tương tự'
ky_vong 1 "chặn [Should fix] thiếu Location" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Should fix] RVW-001 — trùng hàm
- Category: duplicate-code
- Location: `file:dòng`'
ky_vong 1 "chặn Location giữ chỗ của mẫu (không phải file:dòng)" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Should fix] RVW-001 — <tiêu đề>
- Location: `src/a.txt:1`'
ky_vong 1 "chặn tiêu đề finding giữ chỗ của mẫu" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Nit] đặt tên'
toc_f review.md
ky_vong 0 "[Nit] không bắt Location" sh "$CHK" "$F"
# Mã finding: [Blocker] / [Should fix] mang RVW-NNN để task sửa (Fixes:) trỏ về được; [Nit] không bắt
viet_review; thay "$F/review.md" '- None' "$(printf '%s\n' "$L3_SF" | sed 's/RVW-001 — //')"
toc_f review.md
ky_vong_ly_do 1 "chặn [Should fix] thiếu mã RVW" "…đúng lý do" 'Lens 3 \[Should fix\] "trùng hàm": thiếu mã — tiêu đề dạng "### \[mức\] RVW-NNN — <tiêu đề>"' sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' "$L3_SF

$L3_SF"
toc_f review.md
ky_vong_ly_do 1 "chặn hai finding cùng mã" "…đúng lý do" 'Lens 3: RVW-001 trùng — mỗi finding một mã' sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Should fix] RVW-001 — trùng hàm
- Location: `src/a.txt:1`'
ky_vong_ly_do 1 "chặn [Should fix] thiếu Category" "…đúng lý do" 'thiếu dòng "- Category: <loại>"' sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' "$(printf '%s\n' "$L3_SF" | sed 's/duplicate-code/Trùng Code/')"
ky_vong 1 "chặn Category không phải kebab-case" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' '### [Nit] đặt tên
- Category: Tên Tuỳ Ý'
toc_f review.md
ky_vong 0 "[Nit] không bắt Category" sh "$CHK" "$F"
L3_B='### [Blocker] RVW-001 — mất dữ liệu
- Category: data-loss
- Location: `src/a.txt:1`
- Problem: ghi đè'
viet_review; thay "$F/review.md" '- None' "$L3_B"; thay "$F/review.md" '- Blocker findings: 0' '- Blocker findings: 1'
ky_vong_ly_do 1 "chặn [Blocker] thiếu Failure scenario" "…đúng lý do" 'thiếu "- Failure scenario:"' sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' "$L3_B
- Failure scenario: <đầu vào cụ thể → kết quả sai>"; thay "$F/review.md" '- Blocker findings: 0' '- Blocker findings: 1'
ky_vong 1 "chặn Failure scenario giữ chỗ của mẫu" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '- None' "$L3_B
- Failure scenario: lưu hai lần → bản ghi đầu mất"; thay "$F/review.md" '- Blocker findings: 0' '- Blocker findings: 1'
toc_f review.md
ky_vong 0 "[Blocker] đủ trường, Conclusion khớp số → review đạt (ship mới chặn)" sh "$CHK" "$F"
thay "$F/review.md" '- Blocker findings: 1' '- Blocker findings: 0'
ky_vong_ly_do 1 "chặn Conclusion ghi số Blocker lệch số mục" "…đúng lý do" 'Blocker findings: 0 nhưng Lens 3 có 1' sh "$CHK" "$F"
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
ky_vong_ly_do 1 "diff đụng code nhạy cảm mà thiếu Security reviewer → chặn" "…đúng lý do, nêu file nhạy cảm" 'code nhạy cảm (sensitive_code: src/a.txt)' sh "$CHK" "$F"
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

# Bảng khác nhắc mã REQ ở cột lý do không được ghi đè kết luận của Lens 1
viet_review; thay "$F/review.md" '| Authn / authz | pass | màn hình y dùng quyền có sẵn, khớp REQ-001 |' '| Authn / authz | pass | khớp REQ-002 |'
ky_vong 0 "dòng Lens 4 nhắc REQ-002 không ghi đè kết luận pending của Lens 1" sh "$CHK" "$F"

# Cảnh báo phạm vi theo task (task-results.md "Scope warning") phải được giải trình ở Lens 2
viet_review
cp "$F/task-results.md" "$TMP/kq-pv.bak"
awk '{ print } /^## TSK-002/ { print ""; print "- Scope warning: `src/a.txt`" }' "$TMP/kq-pv.bak" > "$F/task-results.md"
ky_vong_ly_do 1 "task có Scope warning mà Lens 2 không giải trình → chặn" "…đúng lý do" 'Lens 2: TSK-002 có cảnh báo phạm vi trong task-results.md — giải trình ở "Task scope warnings"' sh "$CHK" "$F"
printf '\n## Lens 2 — Design and scope\n\n- Task scope warnings: TSK-002 sửa src/a.txt của TSK-001 vì bug phát hiện khi làm, đã khai Unplanned\n' >> "$F/review.md"; toc_f review.md; ghi_tree_review
ky_vong 0 "Lens 2 nhắc tên task trong Task scope warnings → ĐẠT" sh "$CHK" "$F"
cp "$TMP/kq-pv.bak" "$TMP/kq-pv2.bak"
awk '{ print } /^## TSK-002/ { print ""; print "- Scope warning: `src/a.txt`" }' "$TMP/kq-pv2.bak" > "$F/task-results.md"
thay "$F/review.md" '- Task scope warnings: TSK-002 sửa' '- Task scope warnings: TSK-0021 sửa'; ghi_tree_review
ky_vong 1 "Task scope warnings nhắc TSK-0021 không tính là nhắc TSK-002 → chặn" sh "$CHK" "$F"
cp "$TMP/kq-pv.bak" "$F/task-results.md"; viet_review
ket_thuc
