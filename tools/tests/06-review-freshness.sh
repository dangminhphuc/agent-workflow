#!/usr/bin/env sh
# check-review: phạm vi diff, độ mới của bằng chứng máy ghi.
# Chạy riêng: sh tools/tests/06-review-freshness.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
fixture_sau_bao_mat
nhom "check-review.sh"
CHK="$T/check-review.sh"

viet_review

printf 'x\n' > "$R/README.md"
ky_vong 1 "CỔNG CUỐI: chặn file ngoài phạm vi" sh "$CHK" "$F"
dung "…và chặn kết quả kiểm thử/quét lỗi thời (code đổi sau lần chạy)" sh -c "sh '$CHK' '$F' | grep -q 'test-results.md stale'"
thay "$F/plan.md" '|---|---|---|---|
' '|---|---|---|---|
| TSK-001 | cần README | `README.md` | đã ghi |
'
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1
ky_vong_ly_do 1 "chạy lại implement mà chưa rà lại → chặn Reviewed tree cũ" "…đúng lý do: code đổi sau khi rà soát" 'code đổi sau khi rà soát' sh "$CHK" "$F"
ghi_tree_review
ky_vong 0 "ghi file vào Phát sinh (chạy lại implement, rà lại) thì cho qua" sh "$CHK" "$F"
rm -f "$R/README.md"; viet_plan; ghi_based_on
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review

printf '// covers: REQ-001\n' > "$R/test/a.test.js"
ky_vong 1 "CỔNG CUỐI: chặn REQ chưa có test gắn tag" sh "$CHK" "$F"
thay "$F/plan.md" '| ID | Why not automated |
|---|---|
' '| ID | Why not automated |
|---|---|
| REQ-002 | cần kiểm bằng mắt trên UI |
'
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review
ky_vong 0 "ghi Kiểm chứng thủ công có lý do thì cho qua" sh "$CHK" "$F"
printf '// covers: REQ-001, REQ-002\n' > "$R/test/a.test.js"; viet_plan; ghi_based_on
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review

# Không test nào gắn tag: danh sách dòng tag rỗng không được làm kiểm chéo câm
printf '// chua gan tag\n' > "$R/test/a.test.js"
ky_vong_ly_do 1 "CỔNG CUỐI: chặn khi CHƯA test nào gắn tag covers" "…đúng lý do: REQ chưa có test" 'REQ-002: chưa có test' sh "$CHK" "$F"
dung "…và implement có in cảnh báo REQ chưa có test" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'CẢNH BÁO.*REQ-001'"
printf '// covers: REQ-001, REQ-002\n' > "$R/test/a.test.js"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

printf '\n<!-- sửa sau khi đã viết spec -->\n' >> "$F/intake.md"
ky_vong_ly_do 1 "CỔNG CUỐI: chặn spec lỗi thời khi intake.md đổi" "…đúng lý do: spec.md lỗi thời theo intake.md" 'spec.md: stale — intake.md' sh "$CHK" "$F"
viet_intake

printf '\n<!-- sửa sau khi đã có tdd -->\n' >> "$F/spec.md"
ky_vong 1 "CỔNG CUỐI: chặn artifact lỗi thời" sh "$CHK" "$F"
ky_vong 0 "…mà kế hoạch chỉ cảnh báo, không chặn" sh "$T/check-plan.sh" "$F"
viet_spec; ghi_based_on

rm -f "$F/test-results.md"
ky_vong 1 "chặn khi chưa có test-results.md" sh "$CHK" "$F"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

# ---- Độ mới của bằng chứng máy ghi + quét bảo mật (cổng cuối)
dung "test-results.md ghi HEAD, Tree, thời điểm" sh -c "grep -q '^- HEAD: \`[0-9a-f]\{40\}\`' '$F/test-results.md' && grep -q '^- Tree: \`[0-9a-f]\{40\}\`' '$F/test-results.md' && grep -q '^- Thời điểm: ' '$F/test-results.md'"
dung "security-results.md ghi HEAD, Tree, output thật từng nhóm" sh -c "grep -q '^- Tree: \`[0-9a-f]\{40\}\`' '$F/security-results.md' && grep -q '^## sca — ' '$F/security-results.md' && grep -q 'sca-sach' '$F/security-results.md'"

printf 'sua sau review\n' > "$R/src/a.txt"; printf 'moi\n' >> "$R/src/a.txt"
ky_vong_hai_ly_do 1 "CỔNG CUỐI: chặn khi code đổi (chưa commit) sau lần chạy test/quét" \
  "…đúng lý do: cả hai file kết quả lỗi thời" 'test-results.md stale' 'security-results.md stale' sh "$CHK" "$F"
printf 'moi\n' > "$R/src/a.txt"
ky_vong 0 "…hoàn tác về đúng nội dung đã chạy thì hết lỗi thời" sh "$CHK" "$F"

cp "$F/test-results.md" "$TMP/kqkt.bak"
grep -v '^- Tree:' "$TMP/kqkt.bak" > "$F/test-results.md"
ky_vong 1 "chặn test-results.md không ghi Tree (engine cũ / viết tay)" sh "$CHK" "$F"
cp "$TMP/kqkt.bak" "$F/test-results.md"

rm -f "$F/security-results.md"
ky_vong 1 "chặn khi chưa có security-results.md" sh "$CHK" "$F"
sh "$T/check-security.sh" "$F" >/dev/null 2>&1
ky_vong 0 "aw check security ghi lại security-results.md thì cho qua" sh "$CHK" "$F"
thay "$F/security-results.md" '- Kết quả: **XANH**' '- Kết quả: **ĐỎ**'
ky_vong 1 "chặn security-results.md không XANH" sh "$CHK" "$F"
sh "$T/check-security.sh" "$F" >/dev/null 2>&1

ket_thuc
