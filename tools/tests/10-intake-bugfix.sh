#!/usr/bin/env sh
# check-intake, loại việc bugfix.
# Chạy riêng: sh tools/tests/10-intake-bugfix.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

# ---------------------------------------------------------------- muc dich (00)
nhom "check-intake.sh"
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
ky_vong_ly_do 1 "chặn dòng input mẫu chưa sửa (nguồn giả)" "…đúng lý do: chỗ giữ chỗ" 'chỗ giữ chỗ' sh "$CHK" "$F"
viet_intake

thay "$F/intake.md" '`[JIRA]` ABC-1' '`[JIRA]` abc'
ky_vong 1 "chặn [JIRA] không có mã khớp jira_key_regex" sh "$CHK" "$F"
viet_intake
thay "$F/intake.md" '`[JIRA]` ABC-1' '`[JIRA]` [ABC-1](https://x.atlassian.net/browse/ABC-1)'
ky_vong 0 "[JIRA] dạng link markdown có mã thì cho qua" sh "$CHK" "$F"
viet_intake

# spec ghi based_on intake.md: gop them input -> spec loi thoi, review chan
sh "$T/based-on.sh" "$F" spec.md intake.md >/dev/null 2>&1
ky_vong 0 "spec ghi based_on intake.md vẫn qua check-spec" sh "$T/check-spec.sh" "$F"
printf -- '- `[JIRA]` ABC-2\n' >> "$F/intake.md"
ky_vong_ly_do 1 "gộp thêm input sau khi có spec → review chặn (spec lỗi thời)" "…đúng lý do: spec.md lỗi thời vì intake.md" 'spec.md: stale — intake.md' sh "$T/check-review.sh" "$F"
viet_intake; viet_spec

thay "$F/intake.md" '`feature`' '`chore`'
ky_vong 0 "loại lệch tiền tố branch chỉ CẢNH BÁO ở /aw-intake" sh "$CHK" "$F"
dung "…và có in cảnh báo lệch tiền tố" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*feat_'"
viet_intake

# Base: dong do worktree-new.sh in ra, checker phia sau so diff voi no
SHA_MAIN=$(git -C "$R" rev-parse --short main)
thay "$F/intake.md" "- **Base:** \`main\` @ \`$SHA_MAIN\`
" ''
ky_vong_ly_do 1 "chặn khi thiếu dòng Base" "…đúng lý do: thiếu Base" 'Thiếu dòng .*Base' sh "$CHK" "$F"
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
ky_vong_ly_do 1 "base ghi main mà branch tạo từ bản mới hơn → review thấy file của người khác" "…đúng lý do: file của người khác bị tính ngoài phạm vi" 'docs/cua-nguoi-khac.txt: thay đổi ngoài phạm vi' sh "$T/check-review.sh" "$F"
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
nhom "loại việc: bugfix"
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

cp "$F/repro.md" "$TMP/repro.bak"
sed 's/^- Lệnh: .*/- Lệnh: `echo khac`/' "$F/repro.md" > "$TMP/repro.doi" && mv "$TMP/repro.doi" "$F/repro.md"
dung "implement: lệnh tái hiện khác lệnh đang xanh thì chỉ cảnh báo" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'lệnh tái hiện trong repro.md khác lệnh đang xanh'"
ky_vong 0 "…implement vẫn ĐẠT" sh "$T/check-implement.sh" "$F"
ky_vong_ly_do 1 "review chặn khi lệnh xanh không phải lệnh đã đỏ" "…đúng lý do" 'lệnh tái hiện trong repro.md khác lệnh đang xanh' sh "$T/check-review.sh" "$F"
mv "$TMP/repro.bak" "$F/repro.md"

# test xanh tren code chua sua -> khong tai hien duoc
g stash -q
printf 'TEST_CMD="true"\n%s\n' "$BM_XANH" > "$CFG/config.sh"
ky_vong_ly_do 1 "check-repro chặn khi test XANH trên code chưa sửa" "…đúng lý do: test xanh, không phải vì đã sửa code" 'XANH' sh "$T/check-repro.sh" "$F"

ket_thuc
