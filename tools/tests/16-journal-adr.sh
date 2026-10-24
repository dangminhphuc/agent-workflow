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
thay "$F/plan.md" '`REQ-002`' '`REQ-999`'
ky_vong 1 "check KHÔNG ĐẠT giữ mã thoát qua nhật ký" sh "$AWE" check plan "$F"
dung "…ghi vi phạm đầu tiên" sh -c "awk -F'\t' '\$3 == \"plan\" && \$4 == 1 && \$5 != \"\"' '$JD/checks.tsv' | grep -q REQ-999"
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
dung "…tiêu đề trong nhật ký bỏ mã RVW (mã chỉ có nghĩa trong một việc)" sh -c "awk -F'\t' '\$4 == \"duplicate-code\" { print \$5 }' '$JD/findings.tsv' | grep -qx 'trùng hàm'"
sh "$T/check-review.sh" "$F" >/dev/null 2>&1
dung "review chạy lại không nhân đôi" bang "$(awk -F'\t' '$4 == "duplicate-code"' "$JD/findings.tsv" | wc -l | tr -d ' ')" "1"
F2="$R/.agent-workflow/feat_y"; cp -R "$F" "$F2"
dung "loại lặp ở việc thứ hai → GỢI Ý nâng thành luật" sh -c "sh '$T/check-review.sh' '$F2' | grep -q 'GỢI Ý.*duplicate-code.*2 việc'"
dung "report đánh dấu loại lặp lại" sh -c "sh '$NK' 2>/dev/null | grep -q 'duplicate-code.*lặp lại'"
# Nguồn phases/turns: export mang theo, report có mục thời gian và token theo phase
dung "report chưa có turns → mục thời gian ghi chưa có dữ liệu" sh -c "sh '$NK' report | awk '/^Thời gian và token theo phase/ { m = 1; next } m { print; exit }' | grep -q 'chưa có dữ liệu'"
TS=$(printf '\t')
printf '2026-10-01T10:00:00Z\tw1\tf1\tplan\n2026-10-01T11:00:00Z\tw2\tf2\tplan\n' > "$JD/phases.tsv"
{ printf '2026-10-01T10:00:00Z\t2026-10-01T10:01:40Z\tw1\tf1\tplan\ts1\tmain\t100\t10\t20\t1\t1\n'
  printf '2026-10-01T10:05:00Z\t2026-10-01T10:05:50Z\tw1\tf1\tplan\ts1\tmain\t50\t10\t20\t1\t1\n'
  printf '2026-10-01T10:06:00Z\t2026-10-01T10:06:00Z\tw1\tf1\tplan\ts1\tsubagent\t0\t5\t5\t\t\n'
  printf '2026-10-01T11:00:00Z\t2026-10-01T11:05:00Z\tw2\tf2\tplan\ts2\tmain\t300\t100\t200\t0\t0\n'
  printf '2026-10-01T12:00:00Z\t2026-10-01T12:00:10Z\tw2\tf2\tbuild\ts2\tmain\t10\t1\t2\t0\t0\n'; } > "$JD/turns.tsv"
sh "$NK" report > "$TMP/nk-tr"
dung "report trực tiếp: phase plan 2 việc, active tổng 8m, trung vị 4m, token 125/245" sh -c "awk '/^Thời gian và token theo phase/ { m = 1; next } m' '$TMP/nk-tr' | grep -E '^ +plan +2 việc.*8m.*4m.*125.*245'"
dung "…phase build 1 việc" sh -c "awk '/^Thời gian và token theo phase/ { m = 1; next } m' '$TMP/nk-tr' | grep -E '^ +build +1 việc.*10s'"
# Wall mỗi việc: từ mốc bắt đầu tới mốc kế tiếp của cùng việc, hoặc tới sự kiện cuối của việc.
# f1: 10:00 → 10:06:00 (lượt cuối) = 6m; f2: 11:00 → 12:00:10 = 1h → tổng 1h6m, trung vị 33m.
dung "…phase plan có Wall: tổng 1h6m, trung vị 33m" sh -c "awk '/^Thời gian và token theo phase/ { m = 1; next } m' '$TMP/nk-tr' | grep -E '^ +plan +2 việc.*wall tổng 1h6m, trung vị 33m'"
dung "…phase build không có mốc bắt đầu → Wall —" sh -c "awk '/^Thời gian và token theo phase/ { m = 1; next } m' '$TMP/nk-tr' | grep -E '^ +build .*wall tổng —, trung vị —'"
mv "$JD/turns.tsv" "$TMP/nk-turns.bak"; cp "$JD/checks.tsv" "$TMP/nk-checks.bak"
printf '2026-10-01T10:30:00Z\tf1\tplan\t0\t\n2026-10-01T11:20:00Z\tf2\tplan\t1\tx\n' >> "$JD/checks.tsv"
sh "$NK" report > "$TMP/nk-tw"
dung "có phases, không turns → vẫn có Wall (không ghi chưa có dữ liệu)" sh -c "awk '/^Thời gian và token theo phase/ { m = 1; next } m' '$TMP/nk-tw' | grep -E '^ +plan +2 việc.*wall tổng 50m, trung vị 25m' && ! grep -q 'chưa có dữ liệu' '$TMP/nk-tw'"
mv "$TMP/nk-turns.bak" "$JD/turns.tsv"; mv "$TMP/nk-checks.bak" "$JD/checks.tsv"
ky_vong 0 "export có phases/turns" env AW_JOURNAL_MACHINE=may-a sh "$NK" export "$TMP/nk-a.tsv"
dung "…dòng phases, máy" sh -c "grep -c '^phases	may-a	' '$TMP/nk-a.tsv' | grep -qx 2"
dung "…dòng turns, máy" sh -c "grep -c '^turns	may-a	' '$TMP/nk-a.tsv' | grep -qx 5"
dung "report từ file export cùng mục, cùng số" sh -c "sh '$NK' report '$TMP/nk-a.tsv' | awk '/^Thời gian và token theo phase/ { m = 1; next } m' > '$TMP/nk-t2'; awk '/^Thời gian và token theo phase/ { m = 1; next } m' '$TMP/nk-tr' | diff - '$TMP/nk-t2' >&2"
sed 's/	may-a	/	may-b	/' "$TMP/nk-a.tsv" > "$TMP/nk-b2.tsv"
dung "hai máy: việc và token cộng dồn (trùng tên worktree vẫn là hai việc)" sh -c "sh '$NK' report '$TMP/nk-a.tsv' '$TMP/nk-b2.tsv' | grep -E '^ +plan +4 việc.*15m.*4m.*250.*490'"
grep -v '^phases	\|^turns	' "$TMP/nk-a.tsv" > "$TMP/nk-cu.tsv"
dung "file export cũ (không phases/turns) → report chạy, mục ghi chưa có dữ liệu" sh -c "sh '$NK' report '$TMP/nk-cu.tsv' | awk '/^Thời gian và token theo phase/ { m = 1; next } m { print; exit }' | grep -q 'chưa có dữ liệu'"
rm -f "$JD/phases.tsv" "$JD/turns.tsv"
# Gom nhật ký từ nhiều máy: export ra một TSV (nguồn, máy, cột gốc), report đọc lại được nhiều file
ky_vong 0 "journal export <file>" env AW_JOURNAL_MACHINE=may-a sh "$NK" export "$TMP/nk-a.tsv"
dung "…mỗi dòng: nguồn, máy, rồi cột gốc" sh -c "awk -F'\t' '\$1 == \"findings\" && \$2 == \"may-a\"' '$TMP/nk-a.tsv' | grep -q ."
dung "report từ file export trùng report trực tiếp (trừ dòng đầu)" sh -c "sh '$NK' report | tail -n +2 > '$TMP/nk-r1'; sh '$NK' report '$TMP/nk-a.tsv' | tail -n +2 > '$TMP/nk-r2'; diff '$TMP/nk-r1' '$TMP/nk-r2' >&2"
sed 's/	may-a	/	may-b	/' "$TMP/nk-a.tsv" > "$TMP/nk-b.tsv"
n1=$(sh "$NK" report "$TMP/nk-a.tsv" | awk '$1 == "plan" { print $2; exit }')
[ -n "$n1" ] || ca_hong "nhật ký fixture không có lần chạy check plan — ca cộng dồn không kiểm được gì"
dung "hai máy: số lần chạy cộng dồn" bang "$(sh "$NK" report "$TMP/nk-a.tsv" "$TMP/nk-b.tsv" | awk '$1 == "plan" { print $2; exit }')" "$((n1 * 2))"
dung "report cùng một file export hai lần → đếm một lần" bang "$(sh "$NK" report "$TMP/nk-a.tsv" "$TMP/nk-a.tsv" | awk '$1 == "plan" { print $2; exit }')" "$n1"
printf 'rác\n' >> "$TMP/nk-b.tsv"
dung "dòng sai dạng → bỏ qua, báo số dòng bỏ" sh -c "sh '$NK' report '$TMP/nk-a.tsv' '$TMP/nk-b.tsv' | grep -q 'bỏ 1 dòng sai dạng'"
ky_vong 2 "export thiếu file đích → SAI THAM SỐ" sh "$NK" export
ky_vong 2 "report từ file không có → SAI THAM SỐ" sh "$NK" report "$TMP/khong-co.tsv"
rm -rf "$F2"; viet_review
sh "$T/check-review.sh" "$F" >/dev/null 2>&1
dung "review chạy lại hết finding → xoá finding cũ của việc" sh -c "! awk -F'\t' '\$2 == \"feat_x\"' '$JD/findings.tsv' | grep -q ."
dung "…không sót file tạm findings.tsv.<pid>" sh -c "! ls '$JD' | grep -q '^findings.tsv[.]'"
rm -rf "$JD"
sh "$T/check-review.sh" "$F" >/dev/null 2>&1
dung "chưa có findings.tsv, review không finding → không sót file tạm" sh -c "! ls '$JD' | grep -q '^findings.tsv[.]'"

# ---------------------------------------------------------------- ADR (aw adr, aw knowledge)
nhom "ADR: DEC-xxx đã duyệt nâng thành kiến thức bền"
tao_fixture
AD="$T/adr.sh"; KT="$T/knowledge.sh"; TK="$T/check-design.sh"; PK="$T/check-plan.sh"
A1="$R/docs/adr/0001-feat_x-dec-001.md"
# sua_d <tìm> <thay> — sửa DEC trong tdd.md, người duyệt lại bản mới (giữ tick, bỏ dấu cũ)
sua_d() { thay "$F/tdd.md" "$1" "$2"; duyet_lai "$F/tdd.md"; ghi_based_on 2>/dev/null; }
sua_d '- Choice: file' '- Choice: file
- Promote: adr'
ky_vong 1 "design: Promote: adr thiếu Scope → KHÔNG ĐẠT" sh "$TK" "$F"
dung "…nêu thiếu Scope" sh -c "sh '$TK' '$F' | grep -q 'DEC-001: \"Promote: adr\" cần'"
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
ky_vong 1 "plan: DEC Promote: adr chưa có task nâng ADR → KHÔNG ĐẠT" sh "$PK" "$F"
dung "…nêu thiếu task" sh -c "sh '$PK' '$F' | grep -q 'DEC-001 khai Promote: adr nhưng không task nào'"
thay "$F/plan.md" '- Expected files: `src/*` `test/*`' '- Expected files: `src/*` `test/*` `docs/adr/*`'; ghi_based_on 2>/dev/null
ky_vong 0 "…task Based on DEC-001 có docs/adr/* → ĐẠT" sh "$PK" "$F"
ky_vong 2 "promote DEC không có → SAI THAM SỐ" sh "$AD" promote "$F" DEC-009
thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
ky_vong 1 "promote DEC chưa duyệt → TỪ CHỐI" sh "$AD" promote "$F" DEC-001
dung "…không ghi gì" test ! -e "$R/docs/adr"
thay "$F/tdd.md" '- [ ] **Approved by human**' '- [x] **Approved by human**'
ky_vong 0 "promote DEC-001 đã duyệt, Promote: adr → ĐÃ NÂNG" sh "$AD" promote "$F" DEC-001
dung "…ADR chép nội dung DEC, Origin, Scope" sh -c "grep -qx '# ADR-0001: lưu ở đâu' '$A1' && grep -qF -- '- Origin: \`feat_x\` § DEC-001' '$A1' && grep -qF -- '- Scope: \`src/*\`' '$A1' && grep -qF -- '- Choice: file' '$A1' && ! grep -q 'Promote' '$A1'"
dung "…nguồn = Source của REQ mà task Based on DEC-001 phủ" grep -qF -- '- REQ-001 (`feat_x`): `[JIRA]` ABC-1' "$A1"
dung "…chỉ mục có dòng của ADR" grep -qF '| [0001](0001-feat_x-dec-001.md) | lưu ở đâu | accepted | `src/*` |' "$R/docs/adr/README.md"
ky_vong 0 "promote lại → vẫn ĐÃ NÂNG" sh "$AD" promote "$F" DEC-001
dung "…giữ số cũ, không nhân đôi" bang "$(ls "$R/docs/adr" | tr '\n' ' ')" "0001-feat_x-dec-001.md README.md "
ky_vong 0 "aw adr check → HỢP LỆ" sh "$AD" check
ky_vong 2 "aw adr lạ → SAI THAM SỐ" sh "$AD" lam-gi
ky_vong 0 "implement: ADR khớp DEC đã duyệt → ĐẠT" sh "$T/check-implement.sh" "$F"
thay "$A1" '- Choice: file' '- Choice: db'
ky_vong 1 "implement: ADR sửa tay lệch DEC → KHÔNG ĐẠT" sh "$T/check-implement.sh" "$F"
dung "…nêu lệch DEC-001" sh -c "sh '$T/check-implement.sh' '$F' 2>/dev/null | grep -q 'ADR: 0001-feat_x-dec-001.md: lệch DEC-001'"
rm -f "$A1"
ky_vong 1 "implement: DEC Promote: adr chưa có ADR → KHÔNG ĐẠT" sh "$T/check-implement.sh" "$F"
ky_vong 1 "review: DEC Promote: adr chưa có ADR → KHÔNG ĐẠT" sh "$T/check-review.sh" "$F"
dung "…nêu lý do" sh -c "sh '$T/check-review.sh' '$F' 2>/dev/null | grep -q 'ADR: DEC-001 khai Promote: adr nhưng chưa có ADR'"
sh "$AD" promote "$F" DEC-001 >/dev/null 2>&1
cp "$A1" "$R/docs/adr/0001-ban-sao.md"
ky_vong 1 "adr check: trùng số → KHÔNG HỢP LỆ" sh "$AD" check
rm -f "$R/docs/adr/0001-ban-sao.md"
thay "$R/docs/adr/README.md" '| [0001](0001-feat_x-dec-001.md)' '| [0009](0009-khac.md)'
ky_vong 1 "adr check: chỉ mục thiếu ADR → KHÔNG HỢP LỆ" sh "$AD" check
thay "$R/docs/adr/README.md" '| [0009](0009-khac.md)' '| [0001](0001-feat_x-dec-001.md)'
thay "$A1" '- Status: accepted' '- Status: superseded by 0007'
ky_vong 1 "adr check: superseded by ADR không có → KHÔNG HỢP LỆ" sh "$AD" check
thay "$A1" '- Status: superseded by 0007' '- Status: accepted'
# DEC mới thay ADR cũ: người ghi Supersedes trong DEC, máy đổi trạng thái ADR cũ
thay "$F/tdd.md" '## Data model' '### DEC-002 — đổi chỗ lưu
- Author: `agent`
- Choice: db
- Promote: adr
- Scope: `src/*`
- Supersedes: ADR-0001
- [x] **Approved by human**

## Data model'
ky_vong 0 "promote DEC-002 (Supersedes: ADR-0001) → ĐÃ NÂNG" sh "$AD" promote "$F" DEC-002
dung "…ADR cũ thành superseded by 0002, chỉ mục cập nhật" sh -c "grep -qx -- '- Status: superseded by 0002' '$A1' && grep -qF '| superseded by 0002 |' '$R/docs/adr/README.md' && grep -qF -- '- Supersedes: ADR-0001' '$R/docs/adr/0002-feat_x-dec-002.md'"
ky_vong 0 "…aw adr check HỢP LỆ" sh "$AD" check
toc_f tdd.md
ky_vong 0 "design vẫn ĐẠT khi ADR cũ đã bị chính việc này thay" sh "$TK" "$F"
# aw knowledge design: chỉ mục, ADR accepted đúng phạm vi, tài liệu module cha
mkdir -p "$R/lib"; printf '# src\n' > "$R/src/ARCHITECTURE.md"; printf '# lib\n' > "$R/lib/ARCHITECTURE.md"
g add src/ARCHITECTURE.md lib/ARCHITECTURE.md; g commit -q -m "tai lieu module"
dung "knowledge design: chưa có đường dẫn trong Existing code → chỉ in chỉ mục ADR" bang "$(sh "$KT" design "$F" 2>/dev/null)" "docs/adr/README.md"
thay "$F/tdd.md" 'Module src/a.' 'Module `src/a.txt`.'
dung "…có đường dẫn → thêm ADR accepted khớp Scope, tài liệu module cha; bỏ ADR đã bị thay, module khác" bang "$(sh "$KT" design "$F" 2>/dev/null | tr '\n' ' ')" "docs/adr/README.md docs/adr/0002-feat_x-dec-002.md src/ARCHITECTURE.md "
ky_vong 2 "knowledge phase chưa hỗ trợ → SAI THAM SỐ" sh "$KT" plan "$F"
tao_fixture

ket_thuc
