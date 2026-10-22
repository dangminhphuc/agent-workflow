#!/usr/bin/env sh
# Design: skip, loại việc refactor.
# Chạy riêng: sh tools/tests/11-design-skip-refactor.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

# ---------------------------------------------------------------- bỏ design (Design: skip)
nhom "bỏ design: bugfix/refactor nhỏ khai \"Design: skip\""
# bo_design — spec khai skip (người duyệt lại), không có tdd.md, plan không có DEC-xxx
bo_design() {
  thay "$F/spec.md" '- **Risk:** `normal`' '- **Risk:** `normal`
- **Design:** `skip`'
  duyet_lai "$F/spec.md"
  rm -f "$F/tdd.md" "$F/design-findings.md"
  thay "$F/plan.md" '- Based on: `DEC-001`
' ''
  sh "$T/based-on.sh" "$F" spec.md intake.md >/dev/null 2>&1
  sh "$T/based-on.sh" "$F" plan.md spec.md >/dev/null 2>&1
}
tao_fixture bugfix fix_nho
bo_design
for c in spec plan implement review; do
  ky_vong 0 "bugfix Design: skip (không có tdd.md) qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done
ky_vong 1 "bugfix Design: skip chạy design thì bị chặn" sh "$T/check-design.sh" "$F"
# Không có design: plan là phase chạy lại spec — câu trích lệch chỉ cảnh báo
thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[FILE]` docs/brd.md § Hoàn tiền
- Quote:
  > Khách được hoàn tiền trong vòng 30 ngày.'
duyet_lai "$F/spec.md"; printf 'Khách được hoàn tiền trong vòng 60 ngày.\n' > "$R/docs/brd.md"
ky_vong 0 "Design: skip: nguồn đổi sau spec → plan không chặn" sh "$T/check-plan.sh" "$F"
dung "…nhưng cảnh báo câu trích lệch" sh -c "sh '$T/check-plan.sh' '$F' | grep -qF '[CẢNH BÁO] REQ-001: câu trích không có trong docs/brd.md'"
thay "$F/spec.md" '- Source: `[FILE]` docs/brd.md § Hoàn tiền
- Quote:
  > Khách được hoàn tiền trong vòng 30 ngày.' '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a'
duyet_lai "$F/spec.md"; rm -f "$R/docs/brd.md"
ky_vong_ly_do 1 "Design: skip: check-design chặn" "…đúng lý do: spec khai Design: skip" 'Design: skip' sh "$T/check-design.sh" "$F"
ky_vong 2 "Design: skip: aw approval design → SAI THAM SỐ" sh "$T/approval.sh" design "$F"
ky_vong 0 "Design: skip: aw approval plan hỏi duyệt SPEC, spec đã duyệt → ĐÃ DUYỆT" sh "$T/approval.sh" plan "$F"
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 1 "Design: skip: plan chặn khi người chưa duyệt spec" sh "$T/check-plan.sh" "$F"
dung "…aw approval plan nêu Design: skip là điểm cần đọc kỹ" sh -c "sh '$T/approval.sh' plan '$F' 2>/dev/null | grep -q 'Design: skip — bỏ phase design'"
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
thay "$F/open-questions.md" '`non-blocking`' '`blocking`'
ky_vong 1 "Design: skip: điểm mù \"blocking\" còn mở thì plan chặn" sh "$T/check-plan.sh" "$F"
dung "…aw pending tính cổng chặn là plan, không phải design" sh -c "sh '$T/pending.sh' '$F' 2>/dev/null | grep -q 'đổi hướng — chặn /plan'"
thay "$F/open-questions.md" '`blocking`' '`non-blocking`'
thay "$F/spec.md" '- **Risk:** `normal`' '- **Risk:** `high`'; duyet_lai "$F/spec.md"
ky_vong 1 "Design: skip với Risk: high → spec chặn" sh "$T/check-spec.sh" "$F"
ky_vong 1 "…và plan chặn theo (entry check chạy lại spec)" sh "$T/check-plan.sh" "$F"
thay "$F/spec.md" '- **Risk:** `high`' '- **Risk:** `normal`'; duyet_lai "$F/spec.md"
thay "$F/plan.md" '- Expected files: `src/b.txt`' '- Based on: `DEC-001`
- Expected files: `src/b.txt`'
ky_vong 1 "Design: skip: task Dựa trên DEC-xxx bị chặn (không có tdd.md)" sh "$T/check-plan.sh" "$F"
thay "$F/plan.md" '- Based on: `DEC-001`
' ''
thay "$F/spec.md" '- **Design:** `skip`' '- **Design:** `bỏ`'; duyet_lai "$F/spec.md"
ky_vong 1 "spec chặn Design khác required | skip" sh "$T/check-spec.sh" "$F"
thay "$F/spec.md" '- **Design:** `bỏ`' '- **Design:** `required`'; duyet_lai "$F/spec.md"
ky_vong 0 "bugfix Design: required → spec qua" sh "$T/check-spec.sh" "$F"
ky_vong 2 "…nhưng plan đòi tdd.md (phải qua design) → THIẾU ĐẦU VÀO" sh "$T/check-plan.sh" "$F"

tao_fixture refactor refactor_nho
bo_design
for c in spec plan; do
  ky_vong 0 "refactor Design: skip (không có tdd.md) qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done
ky_vong 1 "refactor Design: skip chạy design thì bị chặn" sh "$T/check-design.sh" "$F"

tao_fixture perf perf_nho
bo_design
ky_vong 1 "perf không được Design: skip" sh "$T/check-spec.sh" "$F"
ky_vong 2 "…check-plan vẫn đòi tdd.md → THIẾU ĐẦU VÀO" sh "$T/check-plan.sh" "$F"

tao_fixture feature feat_nho
bo_design
ky_vong_ly_do 1 "feature không được Design: skip" "…đúng lý do" 'chỉ dành cho bugfix/refactor' sh "$T/check-spec.sh" "$F"

tao_fixture chore chore_nho
thay "$F/spec.md" '- **Risk:** `normal`' '- **Risk:** `normal`
- **Design:** `required`'; duyet_lai "$F/spec.md"
ky_vong 1 "chore ghi Design: required → spec chặn" sh "$T/check-spec.sh" "$F"
thay "$F/spec.md" '- **Design:** `required`' '- **Design:** `skip`'; duyet_lai "$F/spec.md"
ky_vong 0 "chore ghi Design: skip → spec qua" sh "$T/check-spec.sh" "$F"

# ---------------------------------------------------------------- refactor
nhom "loại việc: refactor"
tao_fixture refactor refactor_z
for c in spec design plan implement review; do
  ky_vong 0 "refactor đầy đủ qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done

thay "$F/spec.md" '- Type: `structural`' ''
ky_vong 1 "spec refactor chặn REQ không có Loại REQ (hành vi mới)" sh "$T/check-spec.sh" "$F"
viet_spec

thay "$F/spec.md" '`test/a.test.js`' '`test/moi.test.js`'
printf '// covers: REQ-001\n' > "$R/test/moi.test.js"
ky_vong 1 "spec refactor chặn test bảo vệ không có sẵn trên nhánh gốc" sh "$T/check-spec.sh" "$F"
rm -f "$R/test/moi.test.js"; viet_spec; ghi_based_on

printf '// covers: REQ-001, REQ-002\n// doi import\n' > "$R/test/a.test.js"
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

ket_thuc
