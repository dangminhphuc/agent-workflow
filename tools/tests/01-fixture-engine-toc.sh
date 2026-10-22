#!/usr/bin/env sh
# Fixture gốc, aw-engine, aw toc.
# Chạy riêng: sh tools/tests/01-fixture-engine-toc.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

# ---------------------------------------------------------------- fixture goc
nhom "fixture"
tao_fixture
for c in spec design plan implement review; do
  ky_vong 0 "feature đầy đủ qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done

# ---------------------------------------------------------------- aw-engine
nhom "bin/aw-engine"
dung "version in đúng VERSION" bang "$(sh "$AWE" version)" "$(cat "$ROOT/VERSION")"
for c in intake spec design plan implement review; do
  ky_vong 0 "aw-engine check $c → đúng checker, giữ mã thoát" sh "$AWE" check "$c" "$F"
done
dung "mọi tên trong bảng checker trỏ tới script có thật" sh -c ". '$T/lib/commands.sh'; for c in \$BL_CHECKERS; do [ -f '$T/'\$(bl_checker \$c) ] || exit 1; done"
dung "check giữ khối Kết quả của checker" sh -c "sh '$AWE' check plan '$F' 2>&1 | grep -q 'Kết quả: check-plan.sh'"
ky_vong 2 "check tên lạ → SAI THAM SỐ" sh "$AWE" check khong-co "$F"
ky_vong 2 "check thiếu thư mục → SAI THAM SỐ" sh "$AWE" check spec
ky_vong 9 "thiếu AW_CONFIG → KHÔNG HỢP LỆ (không đoán đường dẫn)" env -u AW_CONFIG sh "$AWE" check spec "$F"
ky_vong 9 "wrapper khác giao thức → KHÔNG HỢP LỆ" env AW_PROTOCOL=999 sh "$AWE" check spec "$F"
ky_vong 2 "lệnh lạ → SAI THAM SỐ" sh "$AWE" lam-gi-do
ky_vong 0 "aw-engine guard pre → guard.sh" sh "$AWE" guard pre
ky_vong 0 "aw-engine approval → approval.sh" sh "$AWE" approval design "$F"
ky_vong 3 "aw-engine guard sai pha → SAI THAM SỐ của guard.sh" sh "$AWE" guard khac
ky_vong 2 "adapter không có → SAI THAM SỐ" sh "$AWE" adapter build khong-co --out "$TMP/o-x"

# Ghim version theo việc: dòng Engine trong intake.md
cp "$F/intake.md" "$TMP/intake.bak"
sed '/\*\*Engine:\*\*/d' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "intake thiếu dòng Engine → KHÔNG ĐẠT" sh "$T/check-intake.sh" "$F"
ky_vong 9 "…aw-engine check spec từ chối chấm (không biết engine nào)" sh "$AWE" check spec "$F"
ky_vong 1 "…aw-engine check intake vẫn chạy để liệt kê lỗi" sh "$AWE" check intake "$F"
sed 's/\*\*Engine:\*\* .*/**Engine:** 2026.10.06/' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "Engine sai dạng YYYY.M.N (có số 0 đứng đầu) → KHÔNG ĐẠT" sh "$T/check-intake.sh" "$F"
sed 's/\*\*Engine:\*\* .*/**Engine:** 2000.1.1/' "$TMP/intake.bak" > "$F/intake.md"
ky_vong 1 "Engine lệch engine đang chạy → KHÔNG ĐẠT" sh "$T/check-intake.sh" "$F"
for c in intake spec repro perf; do
  ky_vong 9 "…aw-engine check $c lệch version → KHÔNG HỢP LỆ" sh "$AWE" check "$c" "$F"
done
cp "$TMP/intake.bak" "$F/intake.md"
ky_vong 0 "Engine khớp → ĐẠT" sh "$T/check-intake.sh" "$F"


# ---------------------------------------------------------------- mục lục, link tới mục
nhom "aw toc / tools/lib/toc.sh"
TOC="$T/toc.sh"; CHK="$T/check-spec.sh"
viet_spec
dung "fixture: spec có ## Contents, REQ lồng dưới Requirements" sh -c "grep -qxF -- '- [Requirements](#requirements)' '$F/spec.md' && grep -qxF -- '  - [REQ-001 — a](#req-001--a)' '$F/spec.md'"
dung "aw toc mở rộng anchor rút gọn trong link — chỉ khi khớp đúng một mục" grep -qF '(open-questions.md#req-002--b)' "$F/spec.md"
ky_vong 0 "spec có mục lục, link đúng → ĐẠT" sh "$CHK" "$F"
cksum "$F/spec.md" "$F/open-questions.md" > "$TMP/toc.ck"
ky_vong 0 "aw toc chạy lại trên artifact đã khớp → ĐÃ KHỚP" sh "$TOC" "$F"
dung "…không ghi lại file (artifact phía sau không lỗi thời)" sh -c "cksum '$F/spec.md' '$F/open-questions.md' | cmp -s - '$TMP/toc.ck'"
awk '/^## Contents$/ { bo = 1; next } bo && /^## / { bo = 0 } !bo' "$F/spec.md" > "$TMP/s.md" && mv "$TMP/s.md" "$F/spec.md"
ky_vong 1 "chặn artifact có heading mà thiếu ## Contents" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'spec.md: thiếu mục \"## Contents\"'"
toc_f spec.md
ky_vong 0 "aw toc thêm lại mục lục → ĐẠT" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Out of scope' '## Out of scope now'
ky_vong 1 "chặn mục lục lệch heading (đổi tên heading)" sh "$CHK" "$F"
dung "…đúng lý do: thiếu mục mới, thừa link cũ" sh -c "sh '$CHK' '$F' | grep -q 'Contents\" thiếu mục \"Out of scope now\"' && sh '$CHK' '$F' | grep -q 'link \"#out-of-scope\" không ứng'"
viet_spec; thay "$F/spec.md" '## Out of scope' '## Out of scope now'; toc_f spec.md
ky_vong 0 "…aw toc sinh lại mục lục → ĐẠT" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Constraints & dependencies' '## Out of scope

- trùng tên

## Constraints & dependencies'
toc_f spec.md
dung "heading trùng tên → anchor thứ hai có hậu tố -1 (như GitHub)" grep -qxF -- '- [Out of scope](#out-of-scope-1)' "$F/spec.md"
viet_spec; thay "$F/spec.md" '(open-questions.md#req-002--b)' '(open-questions.md#req-009)'
ky_vong 1 "chặn link tới mục không có của artifact khác" sh "$CHK" "$F"
dung "…đúng lý do" sh -c "sh '$CHK' '$F' | grep -q 'link \"open-questions.md#req-009\" không trỏ tới mục nào'"
ky_vong 1 "aw toc báo CÒN LINK SAI khi link không mở rộng được" sh "$TOC" "$F" spec.md
viet_spec; thay "$F/spec.md" '(open-questions.md#req-002--b)' '(open-questions.md)'
ky_vong 1 "chặn link tới artifact mà không trỏ tới mục" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '[open-questions.md § REQ-002](open-questions.md#req-002--b)' '`open-questions.md` § REQ-002'
ky_vong 1 "chặn tham chiếu \"open-questions.md § REQ-002\" chữ trơn" sh "$CHK" "$F"
dung "…gợi ý đúng link đầy đủ" sh -c "sh '$CHK' '$F' | grep -qF 'viết thành [open-questions.md § REQ-002](open-questions.md#req-002--b)'"
viet_spec; thay "$F/spec.md" '[open-questions.md § REQ-002](open-questions.md#req-002--b)' '[open-questions.md § REQ-002](open-questions.md#REQ-002)'; toc_f spec.md
dung "aw toc mở rộng anchor viết hoa / rút gọn" grep -qF '(open-questions.md#req-002--b)' "$F/spec.md"
viet_spec; thay "$F/spec.md" '- Source: `[JIRA]` ABC-1' '- Source: `[FILE]` docs/plan.md § Tổng quan'
thay "$F/spec.md" '- Priority: `must`' '- Priority: `must`
- Note: [y](#khong-co)'
ky_vong 1 "chặn link #anchor không có trong chính file" sh "$CHK" "$F"
dung "…nhưng không bắt file repo trùng tên artifact (docs/plan.md § …)" sh -c "! sh '$CHK' '$F' | grep -q 'plan.md § …'"
viet_spec; thay "$F/spec.md" '### REQ-001 — a' '### REQ-001 — Đăng Nhập (OTP) & “mã”'; toc_f spec.md
dung "anchor tính như GitHub: chữ Việt thường hoá, bỏ dấu câu" grep -qF '(#req-001--đăng-nhập-otp--mã)' "$F/spec.md"
ky_vong 0 "…và checker chấp nhận" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Out of scope' '<!--
## Không tính
-->
```
## cũng không tính
```

## Out of scope'
toc_f spec.md
dung "heading trong HTML comment / khối code không vào mục lục" sh -c "! grep -qF '[Không tính]' '$F/spec.md' && ! grep -qF '[cũng không tính]' '$F/spec.md'"
ky_vong 0 "…và checker không đòi chúng" sh "$CHK" "$F"
printf '# Open questions\n\nNo open questions.\n' > "$TMP/oq.md"
viet_spec; thay "$F/spec.md" '- Source: `[OPEN-QUESTION]` → [open-questions.md § REQ-002](open-questions.md#req-002--b)
- Assumption: y' '- Source: `[JIRA]` ABC-1
- Quote: > khách mở y thấy b'; cp "$TMP/oq.md" "$F/open-questions.md"
ky_vong 0 "artifact không có heading ## / ### thì không cần mục lục" sh "$CHK" "$F"
ky_vong 2 "aw toc: artifact lạ → SAI THAM SỐ" sh "$TOC" "$F" task-results.md
viet_spec
# review chặn link gãy ở artifact phase trước (heading đích đổi sau khi link được viết)
thay "$F/plan.md" '- Covers: `REQ-001`' '- Covers: `REQ-001`
- Design: [tdd.md § Data model](tdd.md#data-model)'
ky_vong 0 "plan có link Design tới mục có thật → ĐẠT" sh "$T/check-plan.sh" "$F"
thay "$F/tdd.md" '## Data model' '## Data'
ky_vong 1 "review chặn link sang mục không còn (heading đích đổi tên)" sh "$T/check-review.sh" "$F"
dung "…đúng lý do" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'plan.md: link \"tdd.md#data-model\" không trỏ tới mục nào'"
tao_fixture

# ---------------------------------------------------------------- glob của plan.md (khop_duong: ** qua /, * không)
nhom "khop_duong: nghĩa mới của glob trong plan.md"
kd() { sh -c ". '$T/lib/md.sh'; set -f; khop_duong \"\$@\"" kd "$@"; }
dung "src/* khớp src/a.ts" kd src/a.ts 'src/*'
dung "src/* KHÔNG khớp src/a/b.ts" sh -c "! sh -c \". '$T/lib/md.sh'; set -f; khop_duong src/a/b.ts 'src/*'\""
dung "src/** khớp src/a/b.ts" kd src/a/b.ts 'src/**'
dung "src/** khớp src/a.ts" kd src/a.ts 'src/**'
dung "**/x.md khớp a/b/x.md" kd a/b/x.md '**/x.md'
dung "? không qua /" sh -c "! sh -c \". '$T/lib/md.sh'; set -f; khop_duong a/b 'a?b'\""
dung "ký tự regex khớp nguyên văn: a.b+(c)[d].txt" kd 'a.b+(c)[d].txt' 'a.b+(c)[d].txt'
dung "…dấu . không khớp ký tự bất kỳ" sh -c "! sh -c \". '$T/lib/md.sh'; set -f; khop_duong axb.txt 'a.b.txt'\""
dung "nhiều mẫu: khớp mẫu thứ hai" kd src/a/b.ts 'docs/*' 'src/**'

# Cảnh báo chuyển tiếp: file khớp mẫu của plan.md chỉ nhờ * vượt thư mục → cảnh báo, không chặn ở đâu
nhom "glob plan.md: cảnh báo chuyển tiếp"
mkdir -p "$R/src/sau"; printf 'x\n' > "$R/src/sau/c.txt"
dung "implement in cảnh báo chuyển tiếp nêu file, mẫu, cách viết mới" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'CẢNH BÁO.*\`src/sau/c.txt\` chỉ khớp \`src/\*\` nhờ \* vượt thư mục — bản sau \* không qua /; viết \`src/\*\*\`'"
thay "$F/plan.md" '`src/*` `test/*`' '`src/**` `test/*`'
dung "viết src/** → hết cảnh báo chuyển tiếp" sh -c "! sh '$T/check-implement.sh' '$F' | grep -q 'nhờ \* vượt thư mục'"
rm -rf "$R/src/sau"; tao_fixture

ket_thuc
