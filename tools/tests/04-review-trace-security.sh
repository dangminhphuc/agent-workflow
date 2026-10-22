#!/usr/bin/env sh
# check-review: cổng cuối, Lens 1 (truy vết), Lens 4 (bảo mật).
# Chạy riêng: sh tools/tests/04-review-trace-security.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
fixture_sau_bao_mat

# ---------------------------------------------------------------- ra soat
nhom "check-review.sh"
CHK="$T/check-review.sh"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

ky_vong 0 "rà soát đủ và đúng thì cho qua" sh "$CHK" "$F"

# Từ dịch (cột Not của workflow/rules/terms.md): file của phase trước chỉ cảnh báo — review không
# được sửa nó; review.md do chính review viết thì chặn.
printf 'Ghi chú: spec bị lỗi thời.\n' > "$F/ghi-chu.md"
ky_vong 0 "từ dịch trong artifact của phase trước chỉ CẢNH BÁO ở review" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo nêu file, dòng, từ" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*ghi-chu.md dòng 1: \"lỗi thời\" là từ dịch — viết \`stale\`'"
printf '> PO: spec bị lỗi thời\n' > "$F/ghi-chu.md"
dung "…dòng trích lời người (>) thì không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'là từ dịch'"
printf 'Code:\n```\nlỗi thời\n```\nSau rào.\n' > "$F/ghi-chu.md"
dung "…trong fenced code block thì không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'là từ dịch'"
printf '```\nx\n```\nspec bị lỗi thời\n' > "$F/ghi-chu.md"
dung "…sau khi đóng rào thì lại bắt (dòng 4)" sh -c "sh '$CHK' '$F' | grep -q 'ghi-chu.md dòng 4: \"lỗi thời\"'"
rm -f "$F/ghi-chu.md"
printf 'Người viết: còn điểm mù\n' > "$F/refactor-requests.md"
dung "…refactor-requests.md (nguyên văn lời người) thì không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'là từ dịch'"
rm -f "$F/refactor-requests.md"
cp "$F/review.md" "$F/review.md.bak"
printf '\nGhi chú: tdd.md còn ô duyệt.\n' >> "$F/review.md"
ky_vong_ly_do 1 "CỔNG CUỐI: chặn từ dịch trong review.md (file review tự viết)" "…đúng lý do" 'LỖI.*review.md dòng [0-9]*: "ô duyệt" là từ dịch — viết `approval checkbox`' sh "$CHK" "$F"
cp "$F/review.md.bak" "$F/review.md"
printf '\nGhi chú: tdd.md dòng 15 viết "ô duyệt", “điểm mù” và `lỗi thời` là từ dịch.\n' >> "$F/review.md"
ky_vong 0 "review.md trích từ dịch trong \"…\", “…”, \`…\` thì cho qua" sh "$CHK" "$F"
dung "…và không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -q 'là từ dịch'"
mv "$F/review.md.bak" "$F/review.md"

# Điểm mù: "không chặn" còn mở thì giao được (REQ chờ xác nhận); "chặn review" thì không
thay "$F/open-questions.md" '`non-blocking`' '`review-blocking`'; ghi_based_on
ky_vong_ly_do 1 "CỔNG CUỐI: chặn điểm mù \"chặn review\" còn mở" "…đúng lý do: điểm mù REQ-002" 'REQ-002: open question mức "review-blocking"' sh "$CHK" "$F"
thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** "đúng như giả định" — PO, 2026-10-04\n' >> "$F/open-questions.md"
thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)' '`[FILE]` [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Quote: > "đúng như giả định" — PO, 2026-10-04'
duyet_lai "$F/spec.md"; ghi_based_on
ky_vong 0 "điểm mù \"chặn review\" đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec; ghi_based_on

printf '| ID | Verdict |\n|---|---|\n| REQ-001 | pass |\n' > "$F/review.md"
ky_vong 1 "chặn khi bỏ sót một yêu cầu" sh "$CHK" "$F"

printf '| ID | Verdict |\n|---|---|\n| REQ-001 | pass |\n| REQ-002 | pass |\n' > "$F/review.md"
ky_vong 1 "chặn kết luận 'đạt' cho yêu cầu đứng trên giả định tạm" sh "$CHK" "$F"

printf '| ID | Verdict |\n|---|---|\n| REQ-001 | ổn |\n| REQ-002 | pending |\n' > "$F/review.md"
ky_vong 1 "chặn kết luận tự chế ngoài 4 giá trị hợp lệ" sh "$CHK" "$F"
viet_review

# ---- Lens 4 — Security
printf '| ID | Verdict |\n|---|---|\n| REQ-001 | pass |\n| REQ-002 | pending |\n' > "$F/review.md"
ky_vong_ly_do 1 "chặn khi thiếu mục Lens 4 — Security" "…đúng lý do: thiếu mục Lens 4" 'thiếu mục "## Lens 4 — Security"' sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Crypto | not applicable | không dùng crypto |
' ''
ky_vong_ly_do 1 "chặn khi thiếu một hạng mục bảo mật" "…đúng lý do: hạng mục Crypto" 'Lens 4 "Crypto": không có dòng kết luận' sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Crypto | not applicable |' '| Cryptography | not applicable |'
ky_vong 1 "chặn khi đổi tên hạng mục (tên cố định)" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Secrets / config | pass |' '| Secrets / config | ổn |'
ky_vong 1 "chặn verdict ngoài pass / finding / not applicable" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Crypto | not applicable | không dùng crypto |' '| Crypto | not applicable | |'
ky_vong 1 "chặn not applicable không có lý do" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Crypto | not applicable | không dùng crypto |' '| Crypto | not applicable | <...> |'
ky_vong 1 "chặn lý do còn chữ giữ chỗ của mẫu" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Secrets / config | pass | |' '| Secrets / config | finding | |'
ky_vong 1 "chặn finding không có vị trí" sh "$CHK" "$F"
viet_review; thay "$F/review.md" '| Secrets / config | pass | |' '| Secrets / config | finding | `src/a.txt:1` token cứng |'
ky_vong_ly_do 1 "chặn finding bảo mật mà Lens 3 không có finding nào" "…đúng lý do: thiếu finding ở Lens 3" 'Lens 3 không có finding nào' sh "$CHK" "$F"
thay "$F/review.md" '- None' '### [Should fix] RVW-001 — token cứng
- Category: hardcoded-secret
- Location: `src/a.txt:1`
- Problem: token trong code'
toc_f review.md
ky_vong 0 "finding bảo mật có mục ở Lens 3 thì cho qua" sh "$CHK" "$F"
viet_review; cp "$ROOT/workflow/templates/review.md" "$TMP/review-mau.md"
awk '/^## Lens 4/ { p = 1 } /^## Conclusion/ { p = 0 } p' "$TMP/review-mau.md" > "$TMP/lens4-mau.md"
printf '| ID | Verdict |\n|---|---|\n| REQ-001 | pass |\n| REQ-002 | pending |\n\n' > "$F/review.md"; cat "$TMP/lens4-mau.md" >> "$F/review.md"
ky_vong 1 "chặn bảng Lens 4 chép nguyên mẫu chưa điền" sh "$CHK" "$F"
ket_thuc
