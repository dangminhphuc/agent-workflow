#!/usr/bin/env sh
# check-implement, check-security.
# Chạy riêng: sh tools/tests/03-implement-security.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
tao_fixture

# ---------------------------------------------------------------- hien thuc
nhom "check-implement.sh"
CHK="$T/check-implement.sh"
CH="$CFG/config.sh"

printf 'TEST_CMD=""\n' > "$CH"
ky_vong 1 "chưa khai TEST_CMD là KHÔNG ĐẠT, không phải bỏ qua" sh "$CHK" "$F"

printf 'TEST_CMD="false"\n%s\n' "$BM_XANH" > "$CH"
ky_vong 1 "chặn khi test đỏ" sh "$CHK" "$F"

printf 'TEST_CMD="true"\n%s\n' "$BM_XANH" > "$CH"
thay "$F/plan.md" '- Status: `[x]`

## Deferred' '- Status: `[~]`

## Deferred'
ky_vong 1 "chặn khi còn task đang làm dở" sh "$CHK" "$F"
viet_plan; ghi_based_on

printf 'TEST_CMD="echo DAU-VET-DUY-NHAT-12345"\n%s\n' "$BM_XANH" > "$CH"
sh "$CHK" "$F" >/dev/null 2>&1
dung "ghi output THẬT vào test-results.md" grep -q 'DAU-VET-DUY-NHAT-12345' "$F/test-results.md"
printf 'TEST_CMD="true"\n%s\n' "$BM_XANH" > "$CH"

printf 'x\n' > "$R/README.md"
ky_vong 0 "file ngoài phạm vi chỉ CẢNH BÁO, không chặn implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo phạm vi" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*README.md'"
rm -f "$R/README.md"

thay "$F/open-questions.md" '`non-blocking`' '`review-blocking`'; ghi_based_on
ky_vong 0 "điểm mù \"chặn review\" còn mở chỉ CẢNH BÁO ở implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo điểm mù" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*REQ-002: open question mức \"review-blocking\"'"
viet_spec; ghi_based_on

printf 'Ghi chú: REQ-002 còn một Điểm mù.\n' > "$F/ghi-chu.md"
ky_vong 0 "từ dịch trong artifact chỉ CẢNH BÁO ở implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo từ dịch (không phân biệt hoa thường)" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*ghi-chu.md dòng 1: \"điểm mù\" là từ dịch — viết \`open question\`'"
rm -f "$F/ghi-chu.md"
dung "…không có từ dịch thì không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'là từ dịch'"

# ---------------------------------------------------------------- bao mat (aw check security)
nhom "check-security.sh (aw check security)"
BMC="$T/check-security.sh"
cp "$CH" "$TMP/ch.bak"
ky_vong 0 "đủ ba nhóm, mọi lệnh xanh → ĐẠT" sh "$BMC" "$F"

printf 'TEST_CMD="true"\n' > "$CH"
ky_vong 1 "chưa khai SECURITY_CMDS là KHÔNG ĐẠT, không phải bỏ qua" sh "$BMC" "$F"
ky_vong 1 "…và implement cũng KHÔNG ĐẠT" sh "$CHK" "$F"
printf 'TEST_CMD="true"\nSECURITY_CMDS="\n# sca: trivy fs .\n"\n' > "$CH"
ky_vong 1 "chỉ có dòng comment = chưa khai → KHÔNG ĐẠT" sh "$BMC" "$F"

printf 'TEST_CMD="true"\nSECURITY_CMDS="\nsecret: true\nsast: echo LO-HONG-SQLI; exit 1\nsca: true\n"\n' > "$CH"
ky_vong 1 "một lệnh quét đỏ → KHÔNG ĐẠT" sh "$BMC" "$F"
dung "…ghi ĐỎ và output thật vào security-results.md" sh -c "grep -q '^- Kết quả: \*\*ĐỎ\*\*' '$F/security-results.md' && grep -q 'LO-HONG-SQLI' '$F/security-results.md' && grep -q 'Mã thoát: \`1\`' '$F/security-results.md'"
ky_vong 1 "…implement chặn khi quét bảo mật đỏ dù test xanh" sh "$CHK" "$F"

printf 'TEST_CMD="true"\nSECURITY_CMDS="\ntrivy fs .\n"\n' > "$CH"
ky_vong 1 "dòng thiếu \"<nhóm>:\" → KHÔNG ĐẠT" sh "$BMC" "$F"
printf 'TEST_CMD="true"\nSECURITY_CMDS="\ndast: true\n"\n' > "$CH"
ky_vong 1 "nhóm lạ → KHÔNG ĐẠT" sh "$BMC" "$F"
dung "…đúng lý do: liệt kê nhóm hợp lệ" sh -c "sh '$BMC' '$F' | grep -q 'secret, sast, sca, other'"

printf 'TEST_CMD="true"\nSECURITY_CMDS="secret: true"\n' > "$CH"
ky_vong 0 "thiếu nhóm sast/sca chỉ CẢNH BÁO (người xác nhận có chủ ý)" sh "$BMC" "$F"
dung "…có in cảnh báo thiếu nhóm sca" sh -c "sh '$BMC' '$F' | grep -q 'CẢNH BÁO.*nhóm \"sca\"'"

printf 'TEST_CMD="true"\nSECURITY_CMDS="sca: pwd"\n' > "$CH"
sh "$BMC" "$F" >/dev/null 2>&1
dung "lệnh quét chạy ở gốc repo (như CI)" grep -qx "$(git -C "$R" rev-parse --show-toplevel)" "$F/security-results.md"

# config.sh của bản clone dùng chung mọi version engine: tên khoá cũ (trước 2026.10.21) vẫn đọc được.
printf 'LENH_KIEM_THU="true"\nLENH_KIEM_TRA_BAO_MAT="secret: true\nsast: true\nsca: true"\nSO_LAN_DO_TOI_DA="5"\n' > "$CH"
ky_vong 0 "config.sh tên khoá cũ: quét bảo mật đọc LENH_KIEM_TRA_BAO_MAT" sh "$BMC" "$F"
ky_vong 0 "…implement đọc LENH_KIEM_THU" sh "$CHK" "$F"
dung "…aw ready nêu tên khoá cũ cần đổi" sh -c "sh '$T/ready.sh' '$F' --no-test 2>/dev/null | grep -q 'LENH_KIEM_THU → TEST_CMD'"
printf 'TEST_CMD="true"\nLENH_KIEM_THU="false"\nSECURITY_CMDS="secret: true\nsast: true\nsca: true"\n' > "$CH"
ky_vong 0 "…khai cả tên mới lẫn cũ thì tên mới thắng" sh "$CHK" "$F"
cp "$TMP/ch.bak" "$CH"
sh "$CHK" "$F" >/dev/null 2>&1

ket_thuc
