#!/usr/bin/env sh
# check-spec, check-design, check-plan.
# Chạy riêng: sh tools/tests/02-spec-design-plan.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
tao_fixture

# ---------------------------------------------------------------- truy vet
nhom "check-spec.sh"
CHK="$T/check-spec.sh"

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
dung "…kèm hướng dẫn đổi sang Blocking" sh -c "sh '$CHK' '$F' | grep -q 'REQ-002: nhãn cũ.*đã đổi thành \"Blocking'"
viet_spec; thay "$F/open-questions.md" '`non-blocking`' '`toàn bộ thiết kế`'
ky_vong 1 "chặn giá trị cũ \"toàn bộ thiết kế\" dưới nhãn Blocking" sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '`non-blocking`' '`không chặn`'
ky_vong 1 "chặn giá trị tiếng Việt cũ \"không chặn\" dưới nhãn Blocking" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '- **Risk:** `normal`' ''
ky_vong 1 "chặn spec thiếu Mức rủi ro" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '`normal`' '`<high | normal>`'
ky_vong 1 "chặn Mức rủi ro còn chỗ giữ chỗ" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '### REQ-002' '### REQ-001'
ky_vong 1 "chặn mã REQ trùng nhau" sh "$CHK" "$F"

viet_spec; rm -f "$F/open-questions.md"
ky_vong 2 "chặn khi thiếu hẳn open-questions.md" sh "$CHK" "$F"

# "### " không phải REQ đóng vùng REQ: Nguồn nằm dưới nó không thuộc REQ phía trên
viet_spec; thay "$F/spec.md" '### REQ-001 — a
- Source: `[JIRA]` ABC-1' '### REQ-001 — a
- Description: a

### Ghi chú
- Source: `[JIRA]` ABC-1'
ky_vong 1 "chặn REQ không có Nguồn dù \"### phụ\" bên dưới có Nguồn" sh "$CHK" "$F"
dung "…đúng lý do: REQ-001 thiếu Nguồn" sh -c "sh '$CHK' '$F' | grep -q 'REQ-001: thiếu dòng'"
viet_spec; thay "$F/spec.md" '### REQ-002' '### Ghi chú
- Source: `[JIRA]` ABC-9

### REQ-002'
toc_f spec.md
ky_vong 0 "Nguồn dưới \"### phụ\" không bị cộng vào REQ phía trên" sh "$CHK" "$F"

# open-questions.md 0 byte = đã rà, không có điểm mù (không được làm lệch thứ tự file)
viet_spec; thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Assumption: y' '`[JIRA]` ABC-1
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
ky_vong 1 "chặn dạng cũ \"Status:\"" sh "$CHK" "$F"
dung "…đúng lý do: dạng cũ" sh -c "sh '$CHK' '$F' | grep -q 'dạng cũ'"
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
ky_vong 1 "chặn spec đổi nội dung sau khi người duyệt" sh "$CHK" "$F"
dung "…đúng lý do: đổi sau khi người duyệt" sh -c "sh '$CHK' '$F' | grep -q 'đã đổi sau khi người duyệt'"
ky_vong 1 "…design cũng chặn spec đổi sau duyệt" sh "$T/check-design.sh" "$F"
duyet_lai "$F/spec.md"
ky_vong 0 "người xoá dấu duyệt (giữ tick) thì duyệt lại bản mới" sh "$CHK" "$F"
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
sh "$CHK" "$F" >/dev/null 2>&1
dung "bỏ tick thì máy xoá dấu duyệt thừa" sh -c "! grep -q 'approval-hash' '$F/spec.md'"
viet_spec

# open-questions.md <-> spec.md phải khớp trạng thái
viet_spec; printf '\n## REQ-099 — mồ côi\n- **Assumption:** z\n- **Blocking:** `non-blocking`\n- **Status:** `open`\n' >> "$F/open-questions.md"
ky_vong 1 "chặn mục open-questions trỏ về REQ không có trong spec" sh "$CHK" "$F"
dung "…đúng lý do: mục mồ côi REQ-099" sh -c "sh '$CHK' '$F' | grep -q 'spec.md không có REQ-099'"
viet_spec; thay "$F/open-questions.md" '`open`' '`xong`'
ky_vong 1 "chặn Trạng thái điểm mù tự chế" sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** qua email\n' >> "$F/open-questions.md"
ky_vong 1 "chặn điểm mù đã trả lời mà spec vẫn gắn [OPEN-QUESTION]" sh "$CHK" "$F"
thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)' '`[FILE]` [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Quote: > qua email'
ky_vong 1 "spec đã duyệt mà bị sửa (vd /aw-clarify đổi nhãn) thì phải duyệt lại" sh "$CHK" "$F"
duyet_lai "$F/spec.md"
ky_vong 0 "đã trả lời + spec đổi nhãn nguồn + người duyệt lại thì cho qua" sh "$CHK" "$F"
thay "$F/open-questions.md" '- **Answer:** qua email' '- **Answer:** <người trả lời ghi vào đây>'
ky_vong 1 "chặn đã trả lời mà Trả lời còn trống/chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)' '`[JIRA]` ABC-2'
ky_vong 1 "chặn spec đã có nguồn mà điểm mù vẫn mở" sh "$CHK" "$F"
# Người đổi REQ đã có nguồn (/aw-clarify REQ-NNN): ghi thành điểm mù đã trả lời
viet_spec; sh "$CHK" "$F" >/dev/null 2>&1   # máy ghi dấu duyệt cho bản người đã tick
printf '\n## REQ-001 — a\n- **Assumption:** cách đọc cũ\n- **Status:** `answered`\n- **Superseded answer:** "bản cũ" — PO, 2026-10-01\n- **Answer:** "a tối đa 30 ngày" — PO, 2026-10-09 (đã xác nhận sửa REQ-001)\n' >> "$F/open-questions.md"
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
ky_vong 1 "chặn nhãn [FILE] trỏ vào open-questions.md § REQ-001 mà mục đó không có" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'REQ-001: nguồn trỏ tới open-questions.md § REQ-001 nhưng không có mục'"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` [open-questions.md § REQ-002](open-questions.md#req-002--b)'
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
ky_vong 1 "chặn REQ nguồn [JIRA] thiếu Quote" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -qF 'REQ-001: nguồn [JIRA] thiếu câu trích'"
viet_spec; thay "$F/spec.md" '  > khách mở y thấy a' '  > <chép nguyên văn câu nguồn>'
ky_vong 1 "chặn Quote còn chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Quote:
  > khách mở y thấy a' '- Quote: > khách mở y thấy a'
ky_vong 0 "Quote một dòng (\"- Quote: > …\") cũng được" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1
- Quote:
  > khách mở y thấy a' '- Source: `[INFERRED]` index cho REQ-002'
ky_vong 0 "[INFERRED] không cần Quote" sh "$CHK" "$F"
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
ky_vong 1 "[FILE]: file nguồn không có → chặn" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -qF 'REQ-001: không tìm thấy file nguồn docs/khong-co.md'"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` [intake.md § Input](intake.md#input)'
thay "$F/spec.md" '  > khách mở y thấy a' '  > cần làm x cho màn hình y'
ky_vong 0 "[FILE] lời người trong intake.md: câu trích có trong intake → cho qua" sh "$CHK" "$F"
thay "$F/spec.md" '  > cần làm x cho màn hình y' '  > cần làm x cho màn hình z'; duyet_lai "$F/spec.md"
ky_vong 1 "…sai một chữ → chặn" sh "$CHK" "$F"
# Phase sau chạy lại spec (--entry): nguồn đổi sau khi viết spec chỉ cảnh báo
ky_vong 0 "--entry: câu trích lệch chỉ cảnh báo, không chặn" sh "$CHK" "$F" --entry
dung "…có dòng cảnh báo" sh -c "sh '$CHK' '$F' --entry | grep -qF '[CẢNH BÁO] REQ-001: câu trích không có trong intake.md'"
thay "$F/spec.md" '- Quote:
  > cần làm x cho màn hình z
' ''; duyet_lai "$F/spec.md"
ky_vong 1 "--entry: thiếu Quote vẫn chặn (lỗi của spec, không phải nguồn đổi)" sh "$CHK" "$F" --entry
viet_spec

# Tiêu chí chấp nhận, Ưu tiên
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' ''
ky_vong 1 "chặn REQ không có tiêu chí chấp nhận" sh "$CHK" "$F"
dung "…đúng lý do: REQ-001 thiếu tiêu chí" sh -c "sh '$CHK' '$F' | grep -q 'REQ-001: thiếu tiêu chí chấp nhận'"
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
ky_vong 1 "chặn mâu thuẫn do agent tự phân xử" sh "$CHK" "$F"
dung "…đúng lý do: cột Xử lý" sh -c "sh '$CHK' '$F' | grep -q 'Agent không tự phân xử'"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | [open-questions.md § REQ-002](open-questions.md#req-002--b) |'
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

# ---------------------------------------------------------------- thiet ke
nhom "check-design.sh"
CHK="$T/check-design.sh"

viet_spec; viet_tdd
rm -f "$F/design-findings.md"
ky_vong 1 "chặn khi checker LLM chưa chạy (không có file phát hiện ≠ đạt)" sh "$CHK" "$F"

printf '### FND-001 — x\n- Severity: `block`\n- Resolution: `open`   <!-- open | fixed -->\n' > "$F/design-findings.md"
ky_vong 1 "chặn phát hiện block chưa xử lý" sh "$CHK" "$F"

printf '### FND-001 — x\n- Severity: `block`\n- Resolution: `rejected:`\n' > "$F/design-findings.md"
ky_vong 1 "chặn bác bỏ phát hiện mà không có lý do" sh "$CHK" "$F"

printf '### FND-001 — x\n- Severity: `block`\n- Resolution: rejected: DEC-001 đã nói rõ\n### FND-002 — y\n- Severity: `warn`\n- Resolution: open\n' > "$F/design-findings.md"
toc_f design-findings.md
ky_vong 0 "bác bỏ có lý do + cảnh báo chưa xử lý thì cho qua" sh "$CHK" "$F"

# Việc tạo trước khi đổi sang tiếng Anh: trường cũ (Mức / Xử lý) vẫn đọc được
printf '### FND-001 — x\n- Mức: `Chặn`\n- Xử lý: `chưa`   <!-- chưa | đã sửa -->\n' > "$F/design-findings.md"
ky_vong 1 "trường cũ: phát hiện Chặn chưa xử lý vẫn bị chặn" sh "$CHK" "$F"
printf '### FND-001 — x\n- Mức: `Chặn`\n- Xử lý: bác bỏ: DEC-001 đã nói rõ\n### FND-002 — y\n- Mức: `Cảnh báo`\n- Xử lý: chưa\n' > "$F/design-findings.md"
toc_f design-findings.md
ky_vong 0 "trường cũ: bác bỏ có lý do + cảnh báo thì cho qua" sh "$CHK" "$F"
printf '### FND-001 — x\n- Severity: `block`\n- Resolution: fixed\n- Problem: Location và Resolution: chưa rõ\n' > "$F/design-findings.md"
toc_f design-findings.md
ky_vong 0 "tên trường chỉ khớp ở đầu dòng, không khớp trong nội dung" sh "$CHK" "$F"

viet_tdd; thay "$F/open-questions.md" '`non-blocking`' '`review-blocking`'
ky_vong 0 "điểm mù \"chặn review\" còn mở không chặn design" sh "$CHK" "$F"
viet_spec; viet_tdd; thay "$F/open-questions.md" '`non-blocking`' '`blocking`'
ky_vong 1 "chặn điểm mù \"chặn\" còn mở" sh "$CHK" "$F"
dung "…đúng lý do: REQ-002 mức chặn" sh -c "sh '$CHK' '$F' | grep -q 'REQ-002: open question mức \"blocking\"'"
thay "$F/open-questions.md" '`open`' '`answered`'
printf -- '- **Answer:** qua email\n' >> "$F/open-questions.md"
thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)' '`[FILE]` [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Quote: > qua email'
duyet_lai "$F/spec.md"
ky_vong 0 "đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 1 "chặn vào design khi người chưa duyệt spec" sh "$CHK" "$F"
dung "…đúng lý do: spec chưa được người duyệt" sh -c "sh '$CHK' '$F' | grep -q 'chưa được người duyệt'"
viet_spec

viet_tdd; thay "$F/spec.md" '`[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Assumption: y' '`[JIRA]` ABC-1
- Quote: > khách mở y thấy b'
: > "$F/open-questions.md"
ky_vong 0 "open-questions.md 0 byte không làm design đọc lệch file" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' ''
ky_vong 1 "chặn khi đầu vào spec không qua checker của spec" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/tdd.md" '## Test strategy' '## Kiểm thử'
ky_vong 1 "chặn tdd thiếu mục bắt buộc" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" "## Target structure" "## Cấu trúc"
ky_vong 1 "chặn tdd thiếu mục Target structure" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" "Triển khai một lần, quay lui bằng revert commit." ""
ky_vong 1 "chặn mục Rollout & rollback bỏ trống" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" "Triển khai một lần, quay lui bằng revert commit." "Not applicable: chỉ đổi code nội bộ."
ky_vong 0 "Rollout & rollback ghi Not applicable có lý do thì cho qua" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Unit test.' ''
ky_vong 1 "chặn mục bỏ trống không ghi Không áp dụng" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Not applicable: không có API công khai.' 'Not applicable:'
ky_vong 1 "chặn Không áp dụng mà không có lý do" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '| REQ-002 | § Flow |' ''
ky_vong 1 "chặn REQ chưa được ánh xạ" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Based on: DEC-001' 'Based on: DEC-009'
ky_vong 1 "chặn Dựa trên trỏ về DEC không tồn tại" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' ''
ky_vong 1 "chặn DEC-xxx thiếu ô duyệt" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- Status: `approved`'
ky_vong 1 "chặn DEC-xxx dạng cũ \"Status:\"" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- [x] **Approved by human**
- [x] **Approved by human**'
ky_vong 1 "chặn DEC-xxx có hai ô duyệt" sh "$CHK" "$F"
viet_tdd; thay "$F/tdd.md" '## Contract / API' '- [x] **Approved by human**

## Contract / API'
ky_vong 1 "chặn ô duyệt nằm ngoài mục DEC-xxx" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**
- Reopen reason: đổi sang DB'
ky_vong 0 "DEC mở lại (bỏ tick + lý do) thì thiết kế vẫn hợp lệ" sh "$CHK" "$F"
dung "…và hiện là mở lại" sh -c "sh '$CHK' '$F' | grep -q 'DEC-001  *reopened'"

viet_tdd
ky_vong 0 "DEC đã tick qua checker design" sh "$CHK" "$F"
thay "$F/tdd.md" '- Choice: file' '- Choice: file
- Critique (agent): nên cân nhắc DB
  vì dữ liệu sẽ lớn'
ky_vong 0 "agent thêm phản biện không làm mất duyệt D" sh "$CHK" "$F"
thay "$F/tdd.md" '- Choice: file' '- Choice: DB'
ky_vong 1 "chặn DEC đổi nội dung sau khi người duyệt" sh "$CHK" "$F"
duyet_lai "$F/tdd.md"
ky_vong 0 "người xoá dấu duyệt DEC thì duyệt lại bản mới" sh "$CHK" "$F"

viet_tdd; thay "$F/spec.md" '`normal`' '`high`'; duyet_lai "$F/spec.md"
ky_vong 1 "Mode 2: chặn rủi ro cao mà không có DEC do người viết" sh "$CHK" "$F"
thay "$F/tdd.md" '`agent`' '`human`'; duyet_lai "$F/tdd.md"
ky_vong 0 "Mode 2: có DEC Author: human thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/tdd.md" '## Decisions (DEC-xxx)' '## Decisions (DEC-xxx)
Không có quyết định cần duyệt.
## Bỏ'
thay "$F/tdd.md" 'Based on: DEC-001' ''
toc_f tdd.md
ky_vong 0 "mục Quyết định được phép rỗng" sh "$CHK" "$F"
viet_tdd


# Nguồn [FILE] đổi sau khi viết spec: design chạy lại spec, chỉ cảnh báo
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` docs/brd.md § Hoàn tiền'
thay "$F/spec.md" '  > khách mở y thấy a' '  > Khách được hoàn tiền trong vòng 30 ngày.'
printf 'Khách được hoàn tiền trong vòng 30 ngày.\n' > "$R/docs/brd.md"
duyet_lai "$F/spec.md"
ky_vong 0 "câu trích [FILE] khớp → design qua" sh "$CHK" "$F"
printf 'Khách được hoàn tiền trong vòng 60 ngày.\n' > "$R/docs/brd.md"
ky_vong 0 "nguồn đổi sau spec → design không chặn" sh "$CHK" "$F"
dung "…nhưng cảnh báo câu trích lệch" sh -c "sh '$CHK' '$F' | grep -qF '[CẢNH BÁO] REQ-001: câu trích không có trong docs/brd.md'"
ky_vong 1 "…còn aw check spec thì chặn" sh "$T/check-spec.sh" "$F"
rm -f "$R/docs/brd.md"
viet_spec

# ---------------------------------------------------------------- ke hoach
nhom "check-plan.sh"
CHK="$T/check-plan.sh"
ghi_based_on

thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
ky_vong 1 "chặn khi còn DEC-xxx chưa được người duyệt" sh "$CHK" "$F"
viet_tdd; ghi_based_on

rm -f "$F/design-findings.md"
ky_vong 1 "chặn khi tdd.md không qua checker của design" sh "$CHK" "$F"
viet_tdd; ghi_based_on

viet_plan; thay "$F/plan.md" '- Covers: `REQ-002`' '- Covers: `REQ-001`'
ky_vong 1 "chặn YÊU CẦU BỊ BỎ SÓT (chiều ngược)" sh "$CHK" "$F"
thay "$F/plan.md" '|---|---|
' '|---|---|
| REQ-002 | chờ BA |
'
ky_vong 0 "hoãn lại có lý do thì cho qua" sh "$CHK" "$F"
dung "…không cảnh báo khi hoãn REQ nên có" sh -c "! sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*REQ-002: Priority must'"
thay "$F/plan.md" '| REQ-002 | chờ BA |' '| REQ-002 | chờ BA |
| REQ-001 | để sau |'
ky_vong 0 "hoãn REQ bắt buộc không chặn" sh "$CHK" "$F"
dung "…nhưng cảnh báo giao thiếu" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*REQ-001: Priority must'"
thay "$F/plan.md" '
| REQ-001 | để sau |' ''
thay "$F/plan.md" '| REQ-002 | chờ BA |' '| REQ-002 | |'
ky_vong 1 "chặn hoãn lại bỏ trống lý do" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '`REQ-002`' '`REQ-999`'
ky_vong 1 "chặn task trỏ về mã REQ không tồn tại (chiều xuôi)" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Based on: `DEC-001`' '- Based on: `DEC-007`'
ky_vong 1 "chặn task Dựa trên DEC không có trong tdd.md" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Expected files: `src/b.txt`' ''
ky_vong 1 "chặn task thiếu File dự kiến" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Verify: `test -f src/a.txt` → có file
- Status: `[x]`

## Deferred' '- Verify: <lệnh cụ thể>
- Status: `[x]`

## Deferred'
ky_vong 1 "chặn chỗ giữ chỗ chưa điền" sh "$CHK" "$F"
viet_plan; ghi_based_on

ket_thuc
