#!/usr/bin/env sh
# aw journal, ADR.
# Chạy riêng: sh tools/tests/16-journal-adr.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
tao_fixture

# ---------------------------------------------------------------- nhật ký harness (aw journal)
nhom "journal.sh (aw journal)"
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
viet_review; thay "$F/review.md" '- None' "$L3_SF"; toc_f review.md; ghi_tree_review
ky_vong 0 "review ĐẠT ghi finding theo Category" sh "$T/check-review.sh" "$F"
dung "…findings.tsv có duplicate-code" sh -c "awk -F'\t' '\$4 == \"duplicate-code\"' '$JD/findings.tsv' | grep -q ."
sh "$T/check-review.sh" "$F" >/dev/null 2>&1
dung "review chạy lại không nhân đôi" bang "$(awk -F'\t' '$4 == "duplicate-code"' "$JD/findings.tsv" | wc -l | tr -d ' ')" "1"
F2="$R/.agent-workflow/feat_y"; cp -R "$F" "$F2"
dung "loại lặp ở việc thứ hai → GỢI Ý nâng thành luật" sh -c "sh '$T/check-review.sh' '$F2' | grep -q 'GỢI Ý.*duplicate-code.*2 việc'"
dung "report đánh dấu loại lặp lại" sh -c "sh '$NK' 2>/dev/null | grep -q 'duplicate-code.*lặp lại'"
rm -rf "$F2"; viet_review

# ---------------------------------------------------------------- ADR (aw adr, aw knowledge)
nhom "ADR: D-xx đã duyệt nâng thành kiến thức bền"
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
toc_f tdd.md
ky_vong 0 "design vẫn ĐẠT khi ADR cũ đã bị chính việc này thay" sh "$TK" "$F"
# aw knowledge design: chỉ mục, ADR accepted đúng phạm vi, tài liệu module cha
mkdir -p "$R/lib"; printf '# src\n' > "$R/src/ARCHITECTURE.md"; printf '# lib\n' > "$R/lib/ARCHITECTURE.md"
g add src/ARCHITECTURE.md lib/ARCHITECTURE.md; g commit -q -m "tai lieu module"
dung "knowledge design: chưa có đường dẫn trong Existing code → chỉ in chỉ mục ADR" bang "$(sh "$KT" design "$F" 2>/dev/null)" "docs/adr/README.md"
thay "$F/tdd.md" 'Module src/a.' 'Module `src/a.txt`.'
dung "…có đường dẫn → thêm ADR accepted khớp Scope, tài liệu module cha; bỏ ADR đã bị thay, module khác" bang "$(sh "$KT" design "$F" 2>/dev/null | tr '\n' ' ')" "docs/adr/README.md docs/adr/0002-feat_x-d-02.md src/ARCHITECTURE.md "
ky_vong 2 "knowledge phase chưa hỗ trợ → SAI THAM SỐ" sh "$KT" plan "$F"
tao_fixture

ket_thuc
