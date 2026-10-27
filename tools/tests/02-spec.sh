#!/usr/bin/env sh
# check-spec.
# Chạy riêng: sh tools/tests/02-spec.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
tao_fixture

# ---------------------------------------------------------------- truy vet
nhom "check-spec.sh"
CHK="$T/check-spec.sh"

# Checker LLM của spec: thiếu file, block còn mở, rejected không lý do → chặn; đã xử lý → ĐẠT
viet_spec; rm -f "$F/spec-findings.md"
ky_vong_ly_do 1 "chặn khi checker LLM của spec chưa chạy" "…đúng lý do" 'Chưa có spec-findings.md' sh "$CHK" "$F"
printf '### FND-001 — x\n- Severity: `block`\n- Resolution: `open`\n' > "$F/spec-findings.md"
ky_vong_ly_do 1 "chặn phát hiện block của spec chưa xử lý" "…đúng lý do" 'FND-001: phát hiện Severity block chưa xử lý' sh "$CHK" "$F"
printf '### FND-001 — x\n- Severity: `block`\n- Resolution: `rejected:`\n' > "$F/spec-findings.md"
ky_vong_ly_do 1 "chặn bác bỏ phát hiện spec mà không có lý do" "…đúng lý do" 'FND-001: Severity block bị rejected mà không có lý do' sh "$CHK" "$F"
printf '### FND-001 — x\n- Severity: `block`\n- Resolution: fixed\n### FND-002 — y\n- Severity: `warn`\n- Resolution: open\n' > "$F/spec-findings.md"
toc_f spec-findings.md
ky_vong 0 "spec: block đã fixed + cảnh báo chưa xử lý thì cho qua" sh "$CHK" "$F"
printf '### FND-001 — x\n- Severity: `block`\n- Resolution: rejected: câu trích không nói điều này\n' > "$F/spec-findings.md"
toc_f spec-findings.md
ky_vong 0 "spec: bác bỏ block có lý do thì cho qua" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Description: không nguồn'
ky_vong 1 "chặn yêu cầu không có nhãn nguồn" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '`[JIRA]`' '`[BRD]`'
ky_vong 1 "chặn nhãn tự chế ngoài 5 nhãn hợp lệ" sh "$CHK" "$F"

viet_spec; printf '# Open questions\n\nNo open questions.\n' > "$F/open-questions.md"
ky_vong 1 "chặn [OPEN-QUESTION] không ghi vào open-questions" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '**Assumption:**' '**Question:**'
ky_vong 1 "chặn mục điểm mù thiếu giả định tạm" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '- **Blocking:** `non-blocking`' ''
ky_vong 1 "chặn mục điểm mù thiếu mức chặn" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '`non-blocking`' '`hơi hơi`'
ky_vong 1 "chặn mức chặn tự chế" sh "$CHK" "$F"

for m in "blocking" "review-blocking" "non-blocking"; do
  viet_spec; thay "$F/open-questions.md" '`non-blocking`' "\`$m\`"
  ky_vong 0 "mức chặn hợp lệ: $m" sh "$CHK" "$F"
done

# Nhãn cũ: chặn kèm hướng dẫn đổi sang Blocking — "cục bộ" có hai đích, người chọn
viet_spec; thay "$F/open-questions.md" '- **Blocking:** `non-blocking`' '- **Mức ảnh hưởng:** `cục bộ`'
ky_vong 1 "chặn nhãn cũ \"Mức ảnh hưởng\"" sh "$CHK" "$F"
dung "…kèm hướng dẫn đổi sang Blocking" sh -c "sh '$CHK' '$F' | grep -q 'đã đổi thành \"Blocking'"
# Việc tạo trước khi đổi sang tiếng Anh: "Mức chặn" tiếng Việt cũng là nhãn cũ
viet_spec; thay "$F/open-questions.md" '- **Blocking:** `non-blocking`' '- **Mức chặn:** `không chặn`'
ky_vong 1 "chặn nhãn cũ \"Mức chặn\"" sh "$CHK" "$F"
dung "…kèm hướng dẫn đổi sang Blocking" sh -c "sh '$CHK' '$F' | grep -q 'Q-001: nhãn cũ.*đã đổi thành \"Blocking'"
viet_spec; thay "$F/open-questions.md" '`non-blocking`' '`toàn bộ thiết kế`'
ky_vong 1 "chặn giá trị cũ \"toàn bộ thiết kế\" dưới nhãn Blocking" sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '`non-blocking`' '`không chặn`'
ky_vong 1 "chặn giá trị tiếng Việt cũ \"không chặn\" dưới nhãn Blocking" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '- **Risk:** `normal`' ''
ky_vong 1 "chặn spec thiếu Mức rủi ro" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '`normal`' '`<high | normal>`'
ky_vong 1 "chặn Mức rủi ro còn chỗ giữ chỗ" sh "$CHK" "$F"

# high_risk_keywords: Risk normal mà spec chứa từ khoá → chỉ cảnh báo (từ khoá hay báo nhầm)
viet_spec; thay "$CFG/conventions.md" 'high_risk_keywords:' 'high_risk_keywords: thanh toán, Migration'
thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [ ] mở y thấy a sau migration dữ liệu'
OUT=$(sh "$CHK" "$F"); MA=$?
dung "Risk normal chứa từ khoá rủi ro → vẫn cho qua" bang "$MA" 0
dung "…nhưng cảnh báo, nêu từ khoá (không phân biệt hoa thường)" sh -c "printf '%s' \"\$1\" | grep -qF '[WARN] \"Risk: normal\" nhưng spec có từ khoá rủi ro cao (high_risk_keywords): Migration'" _ "$OUT"
thay "$F/spec.md" '- **Risk:** `normal`' '- **Risk:** `high`'
dung "Risk high → không cảnh báo từ khoá" sh -c "! sh '$CHK' '$F' | grep -qF 'high_risk_keywords'"
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [ ] mở y thấy a <!-- thanh toán -->'
dung "từ khoá chỉ nằm trong comment → không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -qF 'high_risk_keywords'"
thay "$CFG/conventions.md" 'high_risk_keywords: thanh toán, Migration' 'high_risk_keywords:'
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [ ] mở y thấy a khi thanh toán'
dung "high_risk_keywords trống → không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -qF 'high_risk_keywords'"

viet_spec; thay "$F/spec.md" '### REQ-002' '### REQ-001'
ky_vong 1 "chặn mã REQ trùng nhau" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" "### REQ-002" "### REQ-2"
ky_vong_ly_do 1 "chặn mã REQ sai dạng (không đủ 3 chữ số)" "…đúng lý do" 'REQ-2 sai dạng' sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" "### Q-001" "### Q-0001"
ky_vong_ly_do 1 "chặn mã câu hỏi sai dạng trong open-questions.md" "…đúng lý do" 'Q-0001 sai dạng' sh "$CHK" "$F"

# Mã luôn ở "###" dưới một "##" của nhóm — dạng cũ "## REQ-NNN" trong open-questions.md bị chặn
viet_spec; thay "$F/open-questions.md" "### Q-001" "## Q-001"; toc_f open-questions.md
ky_vong_ly_do 1 "chặn mục open question ở cấp cũ \"## Q-NNN\"" "…đúng lý do, chỉ cách đổi" 'open-questions.md: "## Q-001" là cấp heading cũ — đổi thành "### Q-001" dưới "## Questions"' sh "$CHK" "$F"

# refactor-requests.md (/aw-refactor): "### RFR-NNN", đúng 3 chữ số, không trùng
viet_spec
rfr() { printf '# Refactor requests — feat_x\n\n## Requests\n\n%s\n- **Summary:** gộp hàm\n- **Status:** `open`\n' "$1" > "$F/refactor-requests.md"; }
rfr '### RFR-001 — gộp hàm'
ky_vong 0 "refactor-requests.md \"### RFR-001\" → cho qua" sh "$CHK" "$F"
rfr '## RFR-001 — gộp hàm'
ky_vong_ly_do 1 "chặn RFR ở cấp cũ \"## RFR-NNN\"" "…đúng lý do" 'refactor-requests.md: "## RFR-001" là cấp heading cũ — đổi thành "### RFR-001" dưới "## Requests"' sh "$CHK" "$F"
rfr '### RFR-01 — gộp hàm'
ky_vong_ly_do 1 "chặn mã RFR sai dạng" "…đúng lý do" 'Mã RFR-01 sai dạng trong refactor-requests.md: phải đúng 3 chữ số (RFR-001)' sh "$CHK" "$F"
rfr '### RFR-001 — a
### RFR-001 — b'
ky_vong_ly_do 1 "chặn mã RFR trùng" "…đúng lý do" 'Mã RFR-001 xuất hiện nhiều lần trong refactor-requests.md' sh "$CHK" "$F"
rm -f "$F/refactor-requests.md"

viet_spec; rm -f "$F/open-questions.md"
ky_vong 2 "chặn khi thiếu hẳn open-questions.md" sh "$CHK" "$F"

# "### " không phải REQ đóng vùng REQ: Nguồn nằm dưới nó không thuộc REQ phía trên
viet_spec; thay "$F/spec.md" '### REQ-001 — a
- Source: `[JIRA]` ABC-1' '### REQ-001 — a
- Description: a

### Ghi chú
- Source: `[JIRA]` ABC-1'
ky_vong_ly_do 1 "chặn REQ không có Nguồn dù \"### phụ\" bên dưới có Nguồn" "…đúng lý do: REQ-001 thiếu Nguồn" 'REQ-001: thiếu dòng' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '### REQ-002' '### Ghi chú
- Source: `[JIRA]` ABC-9

### REQ-002'
toc_f spec.md
ky_vong 0 "Nguồn dưới \"### phụ\" không bị cộng vào REQ phía trên" sh "$CHK" "$F"

# open-questions.md 0 byte = đã rà, không có điểm mù (không được làm lệch thứ tự file)
viet_spec; thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)' '`[JIRA]` ABC-1
- Quote: > khách mở y thấy b'
: > "$F/open-questions.md"
ky_vong 0 "open-questions.md 0 byte thì cho qua" sh "$CHK" "$F"

# Ô duyệt spec: chỉ người tick; spec vẫn qua checker khi chưa tick
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 0 "spec chưa tick vẫn qua checker của spec" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' ''
ky_vong 1 "chặn spec thiếu ô duyệt" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [x] Approved by human'
ky_vong 1 "chặn ô duyệt spec sai dạng" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- **Status:** `approved`'
ky_vong_ly_do 1 "chặn dạng cũ \"Status:\"" "…đúng lý do: dạng cũ" 'dạng cũ' sh "$CHK" "$F"
viet_spec; printf '\n- [x] **Approved by human** — đã đọc\n' >> "$F/spec.md"
ky_vong 1 "chặn ô duyệt spec nằm ngoài phần đầu file" sh "$CHK" "$F"
viet_spec; printf '\n```\n- [x] **Approved by human** — đã đọc\n```\n<!--\n- [x] **Approved by human** — đã đọc\n-->\n' >> "$F/spec.md"
ky_vong 0 "ô duyệt trong khối code / chú thích không được tính" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc
- [x] **Approved by human** — đã đọc'
ky_vong 1 "chặn ô duyệt spec bị lặp" sh "$CHK" "$F"

# Dấu duyệt: tick lần đầu thì máy ghi hash; nội dung đổi sau đó thì chặn
viet_spec
ky_vong 0 "spec đã tick qua checker" sh "$CHK" "$F"
dung "…và máy ghi dấu duyệt" grep -q 'approval-hash: [0-9a-f]\{16\}' "$F/spec.md"
H1=$(grep -o 'approval-hash: [0-9a-f]*' "$F/spec.md")
sh "$CHK" "$F" >/dev/null 2>&1
dung "…chạy lại không ghi dấu mới" bang "$H1" "$(grep -o 'approval-hash: [0-9a-f]*' "$F/spec.md")"
thay "$F/spec.md" '## Constraints & dependencies' '<!-- ghi chú khác -->
## Constraints & dependencies'
printf '\n\n' >> "$F/spec.md"
ky_vong 0 "đổi chú thích / dòng trống không làm mất duyệt" sh "$CHK" "$F"
thay "$F/spec.md" 'mở y thấy a' 'mở y thấy a và c'
ky_vong_ly_do 1 "chặn spec đổi nội dung sau khi người duyệt" "…đúng lý do: đổi sau khi người duyệt" 'đã đổi sau khi người duyệt' sh "$CHK" "$F"
ky_vong 1 "…design cũng chặn spec đổi sau duyệt" sh "$T/check-design.sh" "$F"
duyet_lai "$F/spec.md"
ky_vong 0 "người xoá dấu duyệt (giữ tick) thì duyệt lại bản mới" sh "$CHK" "$F"
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
sh "$CHK" "$F" >/dev/null 2>&1
dung "bỏ tick thì máy xoá dấu duyệt thừa" sh -c "! grep -q 'approval-hash' '$F/spec.md'"
viet_spec

# open-questions.md <-> spec.md phải khớp trạng thái
viet_spec; printf '\n### REQ-099 — mồ côi\n- **Assumption:** z\n- **Blocking:** `non-blocking`\n- **Status:** `open`\n' >> "$F/open-questions.md"
ky_vong_ly_do 1 "chặn mục open-questions trỏ về REQ không có trong spec" "…đúng lý do: mục mồ côi REQ-099" 'spec.md không có REQ-099' sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '`open`' '`xong`'
ky_vong 1 "chặn Trạng thái điểm mù tự chế" sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** qua email\n' >> "$F/open-questions.md"
ky_vong 1 "chặn điểm mù đã trả lời mà spec vẫn gắn [OPEN-QUESTION]" sh "$CHK" "$F"
thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)' '`[FILE]` [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)
- Quote: > qua email'
ky_vong 1 "spec đã duyệt mà bị sửa (vd /aw-clarify đổi nhãn) thì phải duyệt lại" sh "$CHK" "$F"
duyet_lai "$F/spec.md"
ky_vong 0 "đã trả lời + spec đổi nhãn nguồn + người duyệt lại thì cho qua" sh "$CHK" "$F"
thay "$F/open-questions.md" '- **Answer:** qua email' '- **Answer:** <người trả lời ghi vào đây>'
ky_vong 1 "chặn đã trả lời mà Trả lời còn trống/chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)' '`[JIRA]` ABC-2'
ky_vong 1 "chặn spec đã có nguồn mà điểm mù vẫn mở" sh "$CHK" "$F"
# Người đổi REQ đã có nguồn (/aw-clarify REQ-NNN): ghi thành điểm mù đã trả lời
viet_spec; sh "$CHK" "$F" >/dev/null 2>&1   # máy ghi dấu duyệt cho bản người đã tick
printf '\n### REQ-001 — a\n- **Assumption:** cách đọc cũ\n- **Status:** `answered`\n- **Superseded answer:** "bản cũ" — PO, 2026-10-01\n- **Answer:** "a tối đa 30 ngày" — PO, 2026-10-09 (đã xác nhận sửa REQ-001)\n' >> "$F/open-questions.md"
toc_f open-questions.md
thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[FILE]` [open-questions.md § REQ-001](open-questions.md#req-001--a)
- Quote:
  > "a tối đa 30 ngày" — PO, 2026-10-09'
ky_vong 1 "đổi REQ sau khi spec đã duyệt → phải duyệt lại" sh "$CHK" "$F"
duyet_lai "$F/spec.md"
ky_vong 0 "đổi REQ: mục answered (kể cả Superseded answer) + nhãn [FILE] + duyệt lại → cho qua" sh "$CHK" "$F"
thay "$F/open-questions.md" '- **Answer:** "a tối đa 30 ngày" — PO, 2026-10-09 (đã xác nhận sửa REQ-001)' ''
ky_vong 1 "…Superseded answer không thay được Answer" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` [open-questions.md § REQ-001](open-questions.md#req-001--a)'
ky_vong_ly_do 1 "chặn nhãn [FILE] trỏ vào open-questions.md § REQ-001 mà mục đó không có" "…đúng lý do" 'REQ-001: nguồn trỏ tới open-questions.md § REQ-001 nhưng không có mục' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)'
ky_vong 1 "chặn nhãn trỏ vào điểm mù của REQ khác còn open" sh "$CHK" "$F"
printf '# A\n\n## Tổng quan\n\nkhách mở y thấy a\n' > "$R/docs/a.md"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` docs/a.md § Tổng quan'
duyet_lai "$F/spec.md"
ky_vong 0 "nhãn [FILE] trỏ file khác → không bị luật này chặn" sh "$CHK" "$F"
viet_spec
rm -f "$R/docs/a.md"


# Câu trích nguyên văn (Quote): nguồn có câu gốc thì phải trích; [FILE] thì máy kiểm câu có thật trong file
viet_spec; thay "$F/spec.md" '- Quote:
  > khách mở y thấy a
' ''
ky_vong_ly_do 1 "chặn REQ nguồn [JIRA] thiếu Quote" "…đúng lý do" 'REQ-001: nguồn \[JIRA\] thiếu câu trích' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '  > khách mở y thấy a' '  > <chép nguyên văn câu nguồn>'
ky_vong 1 "chặn Quote còn chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Quote:
  > khách mở y thấy a' '- Quote: > khách mở y thấy a'
ky_vong 0 "Quote một dòng (\"- Quote: > …\") cũng được" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[INFERRED]` index cho REQ-002'
ky_vong 0 "[INFERRED] không cần Quote" sh "$CHK" "$F"

# [INFERRED] phải ghi lý do; [JIRA] phải có mã issue; nguồn ngoài "## Input" của intake → cảnh báo
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[INFERRED]`'
ky_vong_ly_do 1 "chặn [INFERRED] không ghi lý do" "…đúng lý do" 'REQ-001: nguồn \[INFERRED\] không ghi lý do' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[INFERRED]` <lý do + REQ phục vụ>'
ky_vong 1 "chặn [INFERRED] lý do còn chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[JIRA]` https://jira.x/browse'
ky_vong_ly_do 1 "chặn [JIRA] không có mã issue" "…đúng lý do" 'REQ-001: nguồn \[JIRA\] không có mã issue khớp jira_key_regex' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[JIRA]` [ABC-1](https://jira.x/browse/ABC-1)'
ky_vong 0 "[JIRA] mã trong link → cho qua" sh "$CHK" "$F"
dung "…mã có trong Input → không cảnh báo nguồn ngoài intake" sh -c "! sh '$CHK' '$F' | grep -qF 'không có trong \"## Input\"'"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[JIRA]` ABC-9'
OUT=$(sh "$CHK" "$F"); MA=$?
dung "[JIRA] mã không có trong Input của intake → vẫn cho qua" bang "$MA" 0
dung "…nhưng cảnh báo, nêu mã" sh -c "printf '%s' \"\$1\" | grep -qF '[WARN] REQ-001: nguồn ABC-9 không có trong \"## Input\" của intake.md'" _ "$OUT"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[JIRA]` ABC-10'
dung "[JIRA] ABC-10 không khớp nhầm ABC-1 trong Input" sh -c "sh '$CHK' '$F' | grep -qF 'nguồn ABC-10 không có trong'"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[CONFLUENCE]` [Trang](https://wiki.x/p/1#muc) § Mục'
dung "[CONFLUENCE] URL không có trong Input → cảnh báo" sh -c "sh '$CHK' '$F' | grep -qF 'nguồn https://wiki.x/p/1 không có trong'"
thay "$F/intake.md" '- `[JIRA]` ABC-1' '- `[JIRA]` ABC-1
- `[CONFLUENCE]` https://wiki.x/p/1'
dung "…URL có trong Input (bỏ anchor) → không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -qF 'không có trong \"## Input\"'"
viet_intake
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)'
dung "[FILE] trỏ open-questions.md của việc → không cảnh báo nguồn ngoài intake" sh -c "! sh '$CHK' '$F' | grep -qF 'không có trong \"## Input\"'"
viet_intake; viet_spec
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[ISSUE]` [#12](https://gitlab.com/g/r/-/work_items/3#note_2)'
viet_intake; thay "$F/intake.md" '- `[JIRA]` ABC-1' '- `[ISSUE]` https://gitlab.com/g/r/-/work_items/3'
ky_vong 0 "[ISSUE] work item GitLab + Quote → cho qua" sh "$CHK" "$F"
viet_intake; viet_spec

# [ISSUE]: issue / PR / MR GitHub, GitLab — cần URL đúng dạng và Quote; so Input theo URL bỏ #comment
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[ISSUE]` [#12](https://github.com/o/r/issues/12#issuecomment-5)'
thay "$F/intake.md" '- `[JIRA]` ABC-1' '- `[JIRA]` ABC-1
- `[ISSUE]` https://github.com/o/r/issues/12'
ky_vong 0 "[ISSUE] URL issue + Quote → cho qua" sh "$CHK" "$F"
dung "…URL có trong Input (bỏ #comment) → không cảnh báo" sh -c "! sh '$CHK' '$F' | grep -qF 'không có trong \"## Input\"'"
viet_intake
dung "[ISSUE] URL không có trong Input → cảnh báo" sh -c "sh '$CHK' '$F' | grep -qF 'nguồn https://github.com/o/r/issues/12 không có trong'"
dung "[ISSUE] .../issues/1 không khớp nhầm .../issues/12 trong Input" sh -c "sed 's#issues/12#issues/1#' '$F/spec.md' > '$F/s1' && mv '$F/s1' '$F/spec.md' && printf '%s\n' '## Input' '- \`[ISSUE]\` https://github.com/o/r/issues/12' >> '$F/intake.md' && sh '$CHK' '$F' | grep -qF 'nguồn https://github.com/o/r/issues/1 không có trong'"
viet_intake
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[ISSUE]` https://github.com/o/r'
ky_vong_ly_do 1 "chặn [ISSUE] không có URL issue / PR / MR" "…đúng lý do" 'REQ-001: nguồn \[ISSUE\] không có URL issue' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[ISSUE]` https://gitlab.com/g/r/-/issues/3'
ky_vong_ly_do 1 "chặn [ISSUE] thiếu câu trích" "…đúng lý do" 'REQ-001: nguồn \[ISSUE\] thiếu câu trích' sh "$CHK" "$F"
viet_spec
viet_spec
printf '# BRD\n\n## Hoàn tiền\n\nKhách được hoàn tiền trong vòng\n30 ngày   kể từ ngày thanh toán.\n> Phí: 1.5%% * số tiền (C:\\tmp\\n) [tối đa].\n' > "$R/docs/brd.md"
quote_file() {
  viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` docs/brd.md § Hoàn tiền'
  thay "$F/spec.md" '  > khách mở y thấy a' "$1"
}
quote_file '  > Khách được hoàn tiền trong vòng 30 ngày kể từ ngày thanh toán.'
ky_vong 0 "[FILE]: câu trích có trong file (khoảng trắng, xuống dòng không tính) → cho qua" sh "$CHK" "$F"
quote_file '  > QUOTE_DAC_BIET'
Q='  > Phí: 1.5% * số tiền (C:\tmp\n) [tối đa].' awk '{ if ($0 == "  > QUOTE_DAC_BIET") print ENVIRON["Q"]; else print }' "$F/spec.md" > "$F/spec.md.tmp" && mv "$F/spec.md.tmp" "$F/spec.md"
ky_vong 0 "[FILE]: ký tự đặc biệt (\\ * [ %) so đúng từng chữ" sh "$CHK" "$F"
quote_file '  > Khách được hoàn tiền trong vòng 30 ngày kể từ ngày thanh toán.
  > Khách được hoàn tiền trong vòng 60 ngày.'
ky_vong 1 "[FILE]: một câu trích không có trong file → chặn" sh "$CHK" "$F"
dung "…nêu đúng câu và file" sh -c "sh '$CHK' '$F' | grep -qF 'REQ-001: câu trích không có trong docs/brd.md: \"Khách được hoàn tiền trong vòng 60 ngày.\"'"
dung "…câu đúng thì không bị nêu" sh -c "! sh '$CHK' '$F' | grep -qF '30 ngày kể từ'"
quote_file '  > "Khách được hoàn tiền trong vòng 30 ngày kể từ ngày thanh toán."'
ky_vong 1 "[FILE]: tự thêm ngoặc kép → không còn nguyên văn, chặn" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` docs/khong-co.md § X'
ky_vong_ly_do 1 "[FILE]: file nguồn không có → chặn" "…đúng lý do" 'REQ-001: không tìm thấy file nguồn docs/khong-co.md' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` [intake.md § Input](intake.md#input)'
thay "$F/spec.md" '  > khách mở y thấy a' '  > cần làm x cho màn hình y'
ky_vong 0 "[FILE] lời người trong intake.md: câu trích có trong intake → cho qua" sh "$CHK" "$F"
thay "$F/spec.md" '  > cần làm x cho màn hình y' '  > cần làm x cho màn hình z'; duyet_lai "$F/spec.md"
ky_vong 1 "…sai một chữ → chặn" sh "$CHK" "$F"
# Phase sau chạy lại spec (--entry): nguồn đổi sau khi viết spec chỉ cảnh báo
ky_vong 0 "--entry: câu trích lệch chỉ cảnh báo, không chặn" sh "$CHK" "$F" --entry
dung "…có dòng cảnh báo" sh -c "sh '$CHK' '$F' --entry | grep -qF '[WARN] REQ-001: câu trích không có trong intake.md'"
thay "$F/spec.md" '- Quote:
  > cần làm x cho màn hình z
' ''; duyet_lai "$F/spec.md"
ky_vong 1 "--entry: thiếu Quote vẫn chặn (lỗi của spec, không phải nguồn đổi)" sh "$CHK" "$F" --entry
viet_spec

# Tiêu chí chấp nhận, Ưu tiên
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' ''
ky_vong_ly_do 1 "chặn REQ không có tiêu chí chấp nhận" "…đúng lý do: REQ-001 thiếu tiêu chí" 'REQ-001: thiếu tiêu chí chấp nhận' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [ ] <quan sát được từ bên ngoài>'
ky_vong 1 "chặn tiêu chí chấp nhận còn chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [x] mở y thấy a'
ky_vong 0 "tiêu chí đã tick [x] vẫn tính" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Priority: `must`' ''
ky_vong 1 "chặn REQ thiếu Ưu tiên" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '`must`' '`high`'
ky_vong 1 "chặn Ưu tiên tự chế" sh "$CHK" "$F"

# Các mục bắt buộc ngoài REQ
viet_spec; thay "$F/spec.md" '## Out of scope' '## Ghi chú'
ky_vong 1 "chặn spec thiếu mục Ngoài phạm vi" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- màn hình z — lý do: đợt sau' '- <...> — lý do: <...>'
ky_vong 1 "chặn Ngoài phạm vi chỉ có chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- màn hình z — lý do: đợt sau' 'Không có.'
ky_vong 0 "Ngoài phạm vi ghi \"Không có.\" thì cho qua" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Constraints & dependencies' '## Khác'
ky_vong 1 "chặn spec thiếu mục Ràng buộc & phụ thuộc" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" 'Không có ràng buộc hay phụ thuộc ngoài.' '<!-- chưa rà -->'
ky_vong 1 "chặn Ràng buộc rỗng (chỉ có comment)" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Source conflicts' '## Khác'
ky_vong 1 "chặn spec thiếu mục Mâu thuẫn giữa các nguồn" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" 'Không phát hiện mâu thuẫn.' '<Không có thì ghi "Không phát hiện mâu thuẫn.">'
ky_vong 1 "chặn bảng mâu thuẫn rỗng, chỉ có chỗ giữ chỗ" sh "$CHK" "$F"

# Mâu thuẫn: agent không tự phân xử
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | chọn 30 ngày cho an toàn |'
ky_vong_ly_do 1 "chặn mâu thuẫn do agent tự phân xử" "…đúng lý do: cột Xử lý" 'Agent không tự phân xử' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b) |'
ky_vong 0 "mâu thuẫn trỏ tới điểm mù có thật thì cho qua" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | [open-questions.md § REQ-099](open-questions.md#req-099) |'
ky_vong 1 "chặn mâu thuẫn trỏ tới điểm mù không có" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | `[JIRA]` ABC-1 comment PO chốt 60 |'
ky_vong 0 "mâu thuẫn trỏ tới nguồn đã chốt thì cho qua" sh "$CHK" "$F"

# Comment HTML nhiều dòng trong mẫu không phải nội dung
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '<!--
  - [ ] mở y thấy a
-->'
ky_vong 1 "tiêu chí nằm trong comment không được tính" sh "$CHK" "$F"
cp "$ROOT/workflow/templates/spec.md" "$F/spec.md"
ky_vong 1 "mẫu spec chưa điền thì không qua" sh "$CHK" "$F"
viet_spec


# Câu hỏi có mã riêng Q-NNN: quan hệ câu hỏi ↔ REQ chỉ khai ở dòng Source của REQ, máy suy ngược
LINK_Q1='[open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)'
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' "- Source: \`[OPEN-QUESTION]\` → $LINK_Q1"
ky_vong 0 "một câu hỏi Q-001 phủ hai REQ → cho qua" sh "$CHK" "$F"
dung "…REQ không có dòng Assumption (giả định chỉ ở câu hỏi)" sh -c "! grep -q 'Assumption' '$F/spec.md'"
thay "$F/open-questions.md" '`open`' '`answered`'; printf -- '- **Answer:** "qua email" — PO, 2026-10-24\n' >> "$F/open-questions.md"
thay "$F/spec.md" "\`[OPEN-QUESTION]\` → $LINK_Q1
- Priority: \`should\`" "\`[FILE]\` $LINK_Q1
- Quote:
  > \"qua email\" — PO, 2026-10-24
- Priority: \`should\`"
ky_vong_ly_do 1 "trả lời câu hỏi nhưng một REQ trỏ tới vẫn [OPEN-QUESTION] → chặn" "…đúng lý do, nêu đúng REQ" 'Q-001: open question đã trả lời nhưng REQ-001 vẫn gắn \[OPEN-QUESTION\]' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" "(open-questions.md#q-001--hỏi-b)" "(open-questions.md#q-001--hỏi-b) [open-questions.md § Q-009](open-questions.md#q-001--hỏi-b)"
ky_vong 0 "…mã câu hỏi lấy theo link đầu tiên của dòng Source" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '§ Q-001](open-questions.md#q-001--hỏi-b)' '§ Q-009](open-questions.md#q-001--hỏi-b)'
ky_vong_ly_do 1 "REQ [OPEN-QUESTION] trỏ tới Q-009 không có → chặn" "…đúng lý do" 'REQ-002: nguồn trỏ tới open-questions.md § Q-009 nhưng không có mục' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" "\`[OPEN-QUESTION]\` → $LINK_Q1" '`[OPEN-QUESTION]`'; printf '\n### Q-002 — khác\n- **Status:** `answered`\n- **Answer:** x\n' >> "$F/open-questions.md"
ky_vong_ly_do 1 "REQ [OPEN-QUESTION] không trỏ tới câu hỏi nào → chặn" "…đúng lý do" 'REQ-002: gắn \[OPEN-QUESTION\] nhưng không trỏ tới câu hỏi nào' sh "$CHK" "$F"
viet_spec; printf '\n### Q-002 — hỏi thừa\n- **Assumption:** z\n- **Blocking:** `non-blocking`\n- **Status:** `open`\n' >> "$F/open-questions.md"; toc_f open-questions.md
ky_vong_ly_do 1 "câu hỏi còn open mà không REQ nào trỏ tới → chặn" "…đúng lý do" 'Q-002 còn "open" nhưng không REQ nào trong spec.md trỏ tới' sh "$CHK" "$F"
thay "$F/open-questions.md" '- **Status:** `open`
' '- **Status:** `open`
' ; thay "$F/open-questions.md" '- **Assumption:** z
- **Blocking:** `non-blocking`
- **Status:** `open`' '- **Status:** `answered`
- **Answer:** "nguồn khác" — PO, 2026-10-24'
ky_vong 0 "…đã answered mà không REQ nào trỏ tới (câu trả lời chỉ sang nguồn khác) → cho qua" sh "$CHK" "$F"
viet_spec; printf '\n### Q-001 — hỏi b lần hai\n- **Status:** `answered`\n- **Answer:** x\n' >> "$F/open-questions.md"
ky_vong_ly_do 1 "mã câu hỏi trùng → chặn" "…đúng lý do" 'Mã Q-001 xuất hiện nhiều lần trong open-questions.md' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' "- Source: \`[FILE]\` $LINK_Q1"
ky_vong_ly_do 1 "REQ [FILE] trỏ tới câu trả lời mà câu hỏi còn open → chặn" "…đúng lý do" 'Q-001: REQ-001 đã gắn nguồn \[FILE\] trỏ tới câu trả lời nhưng open question vẫn "open"' sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b) |'
ky_vong 0 "mâu thuẫn trỏ tới câu hỏi Q-001 có thật → cho qua" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | [open-questions.md § Q-099](open-questions.md#q-099) |'
ky_vong_ly_do 1 "mâu thuẫn trỏ tới Q-099 không có → chặn" "…đúng lý do" 'trỏ tới Q-099 nhưng open-questions.md không có mục' sh "$CHK" "$F"
# Đổi REQ đã có nguồn (/aw-clarify REQ-NNN): một Q- answered tối giản, chỉ Question + Answer
viet_spec; printf '\n### Q-002 — REQ-001 nên hiểu thế nào\n- **Question:** REQ-001 nên hiểu là 30 ngày hay 60 ngày?\n- **Status:** `answered`\n- **Answer:** "a tối đa 30 ngày" — PO, 2026-10-24 (đã xác nhận sửa REQ-001)\n' >> "$F/open-questions.md"; toc_f open-questions.md
thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[FILE]` [open-questions.md § Q-002](open-questions.md#q-002)
- Quote:
  > "a tối đa 30 ngày" — PO, 2026-10-24'; toc_f spec.md
ky_vong 0 "đổi REQ: Q-002 answered chỉ có Question + Answer → cho qua" sh "$CHK" "$F"
# Dạng cũ "### REQ-NNN": vẫn đọc được, một dòng cảnh báo; trộn với Q-NNN được
viet_spec; thay "$F/open-questions.md" '### Q-001 — hỏi b' '### REQ-002 — b'; thay "$F/spec.md" '§ Q-001](open-questions.md#q-001--hỏi-b)' '§ REQ-002](open-questions.md#req-002--b)'; toc_f spec.md open-questions.md
ky_vong 0 "dạng cũ \"### REQ-NNN\" → vẫn cho qua" sh "$CHK" "$F"
dung "…kèm một dòng cảnh báo dạng cũ" sh -c "[ \"\$(sh '$CHK' '$F' | grep -c 'dạng cũ \"### REQ-NNN\"')\" = 1 ]"
thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[OPEN-QUESTION]` → [open-questions.md § Q-001](open-questions.md#q-001)'
printf '\n### Q-001 — hỏi a\n- **Assumption:** x\n- **Blocking:** `non-blocking`\n- **Status:** `open`\n' >> "$F/open-questions.md"; toc_f spec.md open-questions.md; duyet_lai "$F/spec.md"
ky_vong 0 "trộn dạng cũ REQ-002 và Q-001 trong một file → cho qua" sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '### Q-001 — hỏi b' '### REQ-002 — b'; thay "$F/spec.md" "\`[OPEN-QUESTION]\` → $LINK_Q1" '`[OPEN-QUESTION]`'; toc_f spec.md open-questions.md
ky_vong 0 "dạng cũ: REQ [OPEN-QUESTION] không link → câu hỏi cùng mã REQ" sh "$CHK" "$F"
viet_spec
dung "…fixture Q-001 không in cảnh báo dạng cũ" sh -c "! sh '$CHK' '$F' | grep -q 'dạng cũ'"

ket_thuc
