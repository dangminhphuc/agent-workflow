#!/usr/bin/env sh
# Luật nghiệp vụ BR-, kiểm chéo kiến thức bền ↔ diff.
# Chạy riêng: sh tools/tests/17-rule-crosscheck.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
KT="$T/knowledge.sh"

# ---------------------------------------------------------------- luật nghiệp vụ (aw rule)
nhom "Luật nghiệp vụ BR-: REQ đã duyệt nâng thành kiến thức bền"
tao_fixture
LU="$T/rule.sh"; SK="$T/check-spec.sh"; PK="$T/check-plan.sh"
LF="$R/docs/product/rules/billing.md"
# sua_spec <tìm> <thay> — sửa spec, người duyệt lại bản mới
sua_spec() { thay "$F/spec.md" "$1" "$2"; toc_f spec.md; duyet_lai "$F/spec.md"; ghi_based_on 2>/dev/null; }
sua_spec '- Priority: `must`' '- Priority: `must`
- Description: luôn mở được y
- Promote: BR-billing-1'
ky_vong 1 "spec: Promote sai dạng ID → KHÔNG ĐẠT" sh "$SK" "$F"
dung "…nêu dạng đúng" sh -c "sh '$SK' '$F' | grep -q 'dạng BR-<MIỀN>-NNN'"
sua_spec '- Promote: BR-billing-1' '- Promote: BR-BILLING-001'
ky_vong 0 "spec: Promote: BR-BILLING-001 trên REQ nguồn [JIRA] → ĐẠT" sh "$SK" "$F"
sua_spec '- Priority: `should`' '- Priority: `should`
- Promote: BR-BILLING-002'
ky_vong 1 "spec: Promote trên REQ [OPEN-QUESTION] → KHÔNG ĐẠT" sh "$SK" "$F"
sua_spec '- Priority: `should`
- Promote: BR-BILLING-002' '- Priority: `should`'
ky_vong 1 "plan: REQ Promote chưa có task ghi file luật → KHÔNG ĐẠT" sh "$PK" "$F"
dung "…nêu file đích" sh -c "sh '$PK' '$F' | grep -q 'docs/product/rules/billing.md'"
thay "$F/plan.md" '- Expected files: `src/*` `test/*`' '- Expected files: `src/*` `test/*` `docs/product/rules/billing.md`'; ghi_based_on 2>/dev/null
ky_vong 0 "…task phủ REQ-001 có file luật → ĐẠT" sh "$PK" "$F"
ky_vong 1 "promote: nguồn [JIRA] chưa có phiên bản trong ## Sources → TỪ CHỐI" sh "$LU" promote "$F" REQ-001
dung "…không ghi gì" test ! -e "$LF"
sua_spec '## Requirements' '## Sources

| # | Type | Identifier | Version | Read on |
|---|---|---|---|---|
| 1 | Jira | ABC-1 | updated 2026-10-01 | 2026-10-02 |

## Requirements'
thay "$F/spec.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
ky_vong 1 "promote: spec chưa duyệt → TỪ CHỐI" sh "$LU" promote "$F" REQ-001
thay "$F/spec.md" '- [ ] **Approved by human**' '- [x] **Approved by human**'
ky_vong 1 "promote: REQ không khai Promote → TỪ CHỐI" sh "$LU" promote "$F" REQ-002
ky_vong 0 "promote REQ-001 → ĐÃ NÂNG" sh "$LU" promote "$F" REQ-001
dung "…khối chép REQ: tên, Rule, Scope (bỏ file test, file luật), Source có phiên bản, tiêu chí, Origin" sh -c "grep -qx '### BR-BILLING-001: a' '$LF' && grep -qxF -- '- Rule: luôn mở được y' '$LF' && grep -qxF -- '- Scope: \`src/*\`' '$LF' && grep -qxF -- '- Source: \`[JIRA]\` ABC-1 (version: updated 2026-10-01)' '$LF' && grep -qxF -- '  - mở y thấy a' '$LF' && grep -qxF -- '- Origin: \`feat_x\` § REQ-001' '$LF' && grep -qxF -- '- Status: active' '$LF'"
ky_vong 0 "promote lại → vẫn ĐÃ NÂNG" sh "$LU" promote "$F" REQ-001
dung "…viết lại tại chỗ, không nhân đôi" bang "$(grep -c '^### BR-BILLING-001' "$LF")" "1"
ky_vong 0 "aw rule check → HỢP LỆ" sh "$LU" check
dung "…cảnh báo luật active chưa có test covers" sh -c "sh '$LU' check 2>/dev/null | grep -q '! BR-BILLING-001'"
printf '// covers: REQ-001, REQ-002, BR-BILLING-001\n' > "$R/test/a.test.js"
dung "…test gắn covers: BR-BILLING-001 → hết cảnh báo" sh -c "! sh '$LU' check 2>/dev/null | grep -q '! BR-BILLING-001'"
ky_vong 0 "implement: khối luật khớp REQ đã duyệt → ĐẠT" sh "$T/check-implement.sh" "$F"
thay "$LF" '- Rule: luôn mở được y' '- Rule: thỉnh thoảng mở được y'
ky_vong 1 "implement: khối luật sửa tay lệch REQ → KHÔNG ĐẠT" sh "$T/check-implement.sh" "$F"
dung "…nêu lệch REQ-001" sh -c "sh '$T/check-implement.sh' '$F' 2>/dev/null | grep -q 'Luật: docs/product/rules/billing.md: BR-BILLING-001 lệch REQ-001'"
rm -f "$LF"
ky_vong 1 "review: REQ Promote chưa có khối luật → KHÔNG ĐẠT" sh "$T/check-review.sh" "$F"
dung "…nêu lý do" sh -c "sh '$T/check-review.sh' '$F' 2>/dev/null | grep -q 'Luật: REQ-001 khai Promote: BR-BILLING-001 nhưng chưa có khối luật'"
sh "$LU" promote "$F" REQ-001 >/dev/null 2>&1
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
sua_spec '- Source: `[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)' '- Source: `[FILE]` [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Description: luôn hiện b
- Promote: BR-BILLING-002'
thay "$F/plan.md" '- Expected files: `src/b.txt`' '- Expected files: `src/b.txt` `docs/product/rules/billing.md`'; ghi_based_on 2>/dev/null
ky_vong 0 "promote REQ-002 nguồn là câu trả lời của người → ĐÃ NÂNG" sh "$LU" promote "$F" REQ-002
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
nhom "Kiểm chéo kiến thức bền ↔ diff: implement cảnh báo, review đòi verdict"
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
kt_ah() { sh -c ". '$T/lib/md.sh'; . '$T/lib/cross-check.sh'; . '$T/lib/sha256.sh'; . '$T/lib/approval-tick.sh'; . '$T/lib/adr.sh'; . '$T/lib/quote.sh'; . '$T/lib/rule.sh'; . '$T/lib/knowledge.sh'; kt_anh_huong '$F'" | cut -d'|' -f1,2 | sort | tr '\n' ' '; }
dung "tài liệu bị diff ảnh hưởng: module cha, ADR và file luật có Scope khớp; bỏ module khác" bang "$(kt_ah)" "docs/adr/0001-cu.md|0 docs/product/rules/kho.md|0 src/ARCHITECTURE.md|0 "
ky_vong 0 "implement: tài liệu có thể lỗi thời → vẫn ĐẠT (chỉ cảnh báo)" sh "$HT" "$F"
dung "…cảnh báo nêu tài liệu và file đổi" sh -c "sh '$HT' '$F' 2>/dev/null | grep -q 'CẢNH BÁO.*diff đụng src/a.txt (phạm vi của src/ARCHITECTURE.md) mà src/ARCHITECTURE.md không đổi'"
dung "…không nêu tài liệu module khác" sh -c "! sh '$HT' '$F' 2>/dev/null | grep -q 'lib/ARCHITECTURE.md'"
dung "…cảnh báo luật active trong phạm vi diff chưa có test covers" sh -c "sh '$HT' '$F' 2>/dev/null | grep -q 'CẢNH BÁO.*BR-KHO-001.*chưa test nào gắn tag covers'"
viet_review
ky_vong 1 "review: thiếu mục Durable knowledge → KHÔNG ĐẠT" sh "$RS" "$F"
dung "…nêu thiếu mục" sh -c "sh '$RS' '$F' 2>/dev/null | grep -q 'thiếu mục \"## Durable knowledge\"'"
# dk_review <bảng> — thêm mục Durable knowledge vào review.md
dk_review() { viet_review; printf '\n## Durable knowledge\n\n| File | Verdict | Reason |\n|---|---|---|\n%s\n' "$1" >> "$F/review.md"; toc_f review.md; ghi_tree_review; }
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

ket_thuc
