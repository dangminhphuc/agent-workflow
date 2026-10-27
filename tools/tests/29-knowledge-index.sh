#!/usr/bin/env sh
# aw knowledge index: chỉ mục kiến thức chung máy dựng lại (SP28, Task 1).
# Chạy riêng: sh tools/tests/29-knowledge-index.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
KT="$T/knowledge.sh"

# Lib của kt_chi_muc_* (cùng bộ knowledge.sh nạp)
. "$T/lib/md.sh"
. "$T/lib/sha256.sh"
. "$T/lib/approval-tick.sh"
. "$T/lib/adr.sh"
. "$T/lib/quote.sh"
. "$T/lib/rule.sh"
. "$T/lib/knowledge.sh"

CM_INTRO='# Knowledge index

> Bảng dưới do `aw knowledge index` dựng lại từ ADR, luật BR- và tài liệu module — sửa tài liệu, đừng sửa bảng tay.

'
CM_TABLE='| Ref | Kind | Scope | Status | Summary |
|---|---|---|---|---|
| docs/adr/0001-quyet-a-dec-001.md | adr | src/* | accepted | Quyết a |
| src/ARCHITECTURE.md#Mục #2 | module | src/b/* | active | trả tiền qua vnpay |
| src/ARCHITECTURE.md#Thanh toán | module | src/pay/* | active | Thanh toán |
| docs/product/rules/billing.md#BR-BILLING-001 | rule | src/* | active | màn hình y phải hiện a |
| docs/product/rules/billing.md#BR-BILLING-002 | rule | src/pay/* | superseded by BR-BILLING-001 | mở a ; b khi không ra gì |'

# cm_fixture — gọi sau tao_fixture: đặt kiến thức bền lên main, merge vào nhánh việc.
# Đặt CONV (conventions.md của bản clone) và CM_FILE (file chỉ mục mặc định) theo repo hiện tại.
cm_fixture() {
  CONV="$R/.git/agent-workflow/conventions.md"
  CM_FILE="$R/docs/knowledge-index.md"
  g checkout -q main
  mkdir -p "$R/docs/adr" "$R/docs/product/rules"
  cat > "$R/docs/adr/0001-quyet-a-dec-001.md" <<'EOA'
# ADR-0001: Quyết a

- Status: accepted
- Scope: `src/*`

## Decision

Lưu ở file.
EOA
  cat > "$R/docs/product/rules/billing.md" <<'EOB'
# Luật billing

### BR-BILLING-001: mở a
- Rule: màn hình y phải hiện a. Phần sau nhìn từ chỗ khác.
- Scope: `src/*`
- Source: `[JIRA]` ABC-1 (version: updated 2026-10-01)
- Status: active
- Acceptance:
  - mở y thấy a

### BR-BILLING-002: cũ
- Rule: mở a | b khi không ra gì.
- Scope: `src/pay/*`
- Source: `[JIRA]` ABC-1 (version: updated 2026-10-01)
- Status: superseded by BR-BILLING-001
- Acceptance:
  - mở y thấy a | b khi không ra gì
EOB
  cat > "$R/src/ARCHITECTURE.md" <<'EOC'
# Kiến trúc src

## Thanh toán 
- Scope: `src/pay/*`

Luồng thanh toán.

## Mục #2
- Scope: `src/b/*`
- Summary: trả tiền qua vnpay
Chi tiết.
EOC
  g add docs src; g commit -q -m "kien thuc"
  g checkout -q -; g merge -q main
}

CF_FILE() { printf '%s/docs/knowledge-index.md\n' "$R"; }

nhom "kt_chi_muc_khoa: đọc khoá knowledge_index"
tao_fixture
CONV="$R/.git/agent-workflow/conventions.md"
dung "khoá mẫu có sẵn → giá trị mặc định" bang "$(kt_chi_muc_khoa "$CONV")" "docs/knowledge-index.md|0"
thay "$CONV" 'knowledge_index: docs/knowledge-index.md' 'knowledge_index: docs/trang-tri.md'
dung "khoá khai giá trị → dùng giá trị" bang "$(kt_chi_muc_khoa "$CONV")" "docs/trang-tri.md|0"
thay "$CONV" 'knowledge_index: docs/trang-tri.md' 'knowledge_index:'
dung "khoá khai trống → tắt" bang "$(kt_chi_muc_khoa "$CONV")" "|1"

nhom "aw knowledge index: lần đầu, bất biến, giữ phần người viết"
tao_fixture; cm_fixture
sh "$KT" index 2>/dev/null > "$TMP/cm.out"
dung "index: khoá không khai → tạo ở đường mặc định" bang "$(cat "$TMP/cm.out")" "docs/knowledge-index.md"
dung "index: file đã có" test -f "$CM_FILE"
dung "index: nội dung = phần mở đầu + bảng đúng hàng" bang "$(cat "$CM_FILE")" "$CM_INTRO$CM_TABLE"
dung "index: Ref giữ nguyên văn heading có tiếng Việt" sh -c "grep -q 'md#Thanh toán |' '$CM_FILE'"
_CMTRC=
cm_lan2() {
  cat "$CM_FILE" > "$TMP/cm-lan1.md"
  sh "$KT" index >/dev/null 2>&1
  cmp -s "$CM_FILE" "$TMP/cm-lan1.md"
}
dung "index: dựng lại hai lần → bất biến" cm_lan2
thay "$CM_FILE" '# Knowledge index' '# Knowledge index

Ghi chú của team'
sh "$KT" index >/dev/null 2>&1
dung "index: giữ phần người viết phía trên bảng" grep -q 'Ghi chú của team' "$CM_FILE"
dung "index: bảng không đổi sau khi dựng lại với phần người viết" bang "$(sed -n '/^| Ref |/,$p' "$CM_FILE")" "$CM_TABLE"
dung "kt_chi_muc_du == bảng trong file" bang "$(kt_chi_muc_du "$R" "$CONV")" "$CM_TABLE"
cat "$CM_FILE" > "$TMP/cm-sau-ghi-chu.md"
dung "kt_chi_muc_lai == aw knowledge index (cùng trạng thái, người viết đã sửa)" sh -c "sh '$KT' index >/dev/null 2>&1 && cmp -s '$CM_FILE' '$TMP/cm-sau-ghi-chu.md'"

nhom "aw knowledge index: khoá tắt"
tao_fixture; cm_fixture
thay "$CONV" 'knowledge_index: docs/knowledge-index.md' 'knowledge_index:'
ky_vong_ly_do 2 "index: khoá khai trống → SAI THAM SỐ" "index: khoá tắt → báo lý do" "SAI THAM SỐ" sh "$KT" index
dung "index: khoá tắt → không tạo file" sh -c "! test -f '$CM_FILE'"

nhom "aw knowledge index: khoá trỏ đường dẫn khác"
tao_fixture; cm_fixture
thay "$CONV" 'knowledge_index: docs/knowledge-index.md' 'knowledge_index: docs/trang-tri.md'
sh "$KT" index 2>/dev/null > "$TMP/cm.out"
dung "index: in đường dẫn theo khoá" bang "$(cat "$TMP/cm.out")" "docs/trang-tri.md"
dung "index: file được tạo theo khoá" test -f "$R/docs/trang-tri.md"
dung "index: nội dung ở đường khác = phần mở đầu + bảng" bang "$(cat "$R/docs/trang-tri.md")" "$CM_INTRO$CM_TABLE"
dung "index: không tạo file đường mặc định" sh -c "! test -f '$CM_FILE'"

nhom "knowledge design/implement: chỉ mục chung thay chỉ mục ADR"
tao_fixture; cm_fixture
thay "$F/tdd.md" 'Module src/a.' 'Module `src/a.txt`.'
sh "$KT" index 2>/dev/null > /dev/null
g checkout -q main
sh "$KT" index 2>/dev/null > /dev/null
g add docs; g commit -q -m chi-muc
g checkout -q -; g merge -q main
dung "design: index file có trong git → in chỉ mục chung, không in README ADR" \
  sh -c "sh '$KT' design '$F' 2>/dev/null | grep -qx 'docs/knowledge-index.md'"
dung "design: không in chỉ mục ADR nữa" sh -c "! sh '$KT' design '$F' 2>/dev/null | grep -qx 'docs/adr/README.md'"
dung "design: vẫn in ADR ref" sh -c "sh '$KT' design '$F' 2>/dev/null | grep -qx 'docs/adr/0001-quyet-a-dec-001.md'"
tao_fixture chore; cm_fixture
sh "$KT" index 2>/dev/null > /dev/null
g checkout -q main
sh "$KT" index 2>/dev/null > /dev/null
g add docs; g commit -q -m chi-muc
g checkout -q -; g merge -q main
dung "implement: Design skip → in chỉ mục chung" sh -c "sh '$KT' implement '$F' 2>/dev/null | grep -qx 'docs/knowledge-index.md'"
tao_fixture feature; cm_fixture
sh "$KT" index >/dev/null 2>&1
dung "implement: file chỉ mục có trên cây mà chưa commit → không in chỉ mục chung" \
  sh -c "! sh '$KT' implement '$F' 2>/dev/null | grep -qx 'docs/knowledge-index.md'"
dung "phase 01-spec đọc chỉ mục chung" sh -c "grep -q 'knowledge-index' '$ROOT'/workflow/phases/01-spec.md"
dung "phase 02-design đọc chỉ mục chung" sh -c "grep -q 'knowledge-index' '$ROOT'/workflow/phases/02-design.md"

# cm_dien_chimuc — index đã có trong git trên main, merge vào nhánh việc.
cm_dien_chimuc() {
  sh "$KT" index >/dev/null 2>&1
  g checkout -q main
  sh "$KT" index >/dev/null 2>&1
  g add docs; g commit -q -m chi-muc
  g checkout -q -; g merge -q main
}

nhom "aw knowledge check: chạy một mình"
tao_fixture; cm_fixture
ky_vong 0 "check: chưa có file chỉ mục → ĐẠT" sh "$KT" check
sh "$KT" index >/dev/null 2>&1
g add docs; g commit -q -m chi-muc
ky_vong 0 "check: bảng đúng → ĐẠT" sh "$KT" check
thay "$CM_FILE" 'trả tiền qua vnpay' 'trả tiền qua momo'
ky_vong_ly_do 1 "check: sửa tay một hàng → KHÔNG ĐẠT" "check: nêu chạy index để dựng lại" "lệch dựng lại" sh "$KT" check
ky_vong 0 "check: dựng lại xong kiểm lại → ĐẠT" sh -c "sh '$KT' index >/dev/null 2>&1 && sh '$KT' check"
rm "$CM_FILE"
ky_vong 0 "check: file thiếu, chạy một mình → ĐẠT (repo chưa tham gia)" sh "$KT" check

nhom "aw knowledge check: gate theo diff"
tao_fixture
_dgc=$(git -C "$R" rev-parse --short main)
cm_fixture
# commit một bảng hỏng trên main, merge vào nhánh; diff không tính nó → gate đóng, bảng hỏng bị bỏ qua
g checkout -q main
sh "$KT" index >/dev/null 2>&1
thay "$CM_FILE" 'trả tiền qua vnpay' 'trả tiền qua momo'
g add docs; g commit -q -m chi-muc
g checkout -q -; g merge -q main
thay "$F/intake.md" "@ \`$_dgc\`" "@ \`$(git -C "$R" rev-parse --short main)\`"
ky_vong 0 "check <feature>: diff không đụng kiến thức → ĐẠT dù bảng hỏng sẵn trên Base" sh "$KT" check "$F"
printf 'lỗi hổ l\n' >> "$R/docs/product/rules/billing.md"
ky_vong 1 "check <feature>: diff đụng file luật → KHÔNG ĐẠT khi bảng hỏng" sh "$KT" check "$F"
rm "$CM_FILE"
ky_vong_ly_do 1 "check <feature>: file chỉ mục bị xoá khi diff đụng → KHÔNG ĐẠT" "check <feature>: nêu chạy index để dựng lại" "thiếu file chỉ mục" sh "$KT" check "$F"

nhom "aw check implement / check review qua chỉ mục"
tao_fixture; cm_fixture
cm_dien_chimuc
thay "$F/tdd.md" 'Module src/a.' 'Module `src/a.txt`.'
toc_f tdd.md
viet_plan
ghi_based_on
ky_vong 0 "check implement: bảng đúng → ĐẠT" sh "$T/check-implement.sh" "$F"
thay "$CM_FILE" 'trả tiền qua vnpay' 'trả tiền qua momo'
ky_vong_ly_do 1 "check implement: bảng tay sửa lệch → KHÔNG ĐẠT" "check implement: nêu lỗi chỉ mục" "lệch dựng lại" sh "$T/check-implement.sh" "$F"
thay "$CM_FILE" 'trả tiền qua momo' 'trả tiền qua vnpay'
rm "$CM_FILE"
ky_vong 1 "check implement: file chỉ mục bị xoá → KHÔNG ĐẠT" sh "$T/check-implement.sh" "$F"
cm_dien_chimuc
ky_vong 0 "check implement: bảng đúng lại sau khi dựng → ĐẠT" sh "$T/check-implement.sh" "$F"
viet_review
printf '\n## Durable knowledge\n\n| File | Verdict | Reason |\n|---|---|---|\n| `docs/adr/0001-quyet-a-dec-001.md` | updated | |\n| `src/ARCHITECTURE.md` | updated | |\n| `src/ARCHITECTURE.md#Thanh toán` | updated | |\n| `src/ARCHITECTURE.md#Mục #2` | updated | |\n| `docs/product/rules/billing.md#BR-BILLING-001` | updated | |\n' >> "$F/review.md"
toc_f review.md; ghi_tree_review
ky_vong 0 "check review: mỗi ref có verdict + chỉ mục đúng → ĐẠT" sh "$T/check-review.sh" "$F"
thay "$CM_FILE" 'trả tiền qua vnpay' 'trả tiền qua momo'
ky_vong_ly_do 1 "check review: bảng tay sửa lệch → KHÔNG ĐẠT" "check review: nêu lỗi chỉ mục" "lệch dựng lại" sh "$T/check-review.sh" "$F"

nhom "aw adr promote / aw rule promote: dựng lại chỉ mục"
tao_fixture; cm_fixture
cm_dien_chimuc
AD="$T/adr.sh"; RU="$T/rule.sh"
sua_d() { thay "$F/tdd.md" "$1" "$2"; duyet_lai "$F/tdd.md"; ghi_based_on 2>/dev/null; }
sua_d '- Choice: file' '- Choice: file
- Promote: adr
- Scope: `src/*`'
ky_vong 0 "promote DEC-001: ĐÃ NÂNG" sh "$AD" promote "$F" DEC-001
dung "promote DEC-001: chỉ mục có hàng ADR mới với Status, Scope, Summary" \
  sh -c "grep -qxF '| docs/adr/0002-feat_x-dec-001.md | adr | src/* | accepted | lưu ở đâu |' '$CM_FILE'"
ky_vong 0 "promote DEC-001: bảng khớp dựng lại ngay" sh "$KT" check
sua_spec() { thay "$F/spec.md" "$1" "$2"; toc_f spec.md; duyet_lai "$F/spec.md"; ghi_based_on 2>/dev/null; }
sua_spec '## Requirements' '## Sources

| # | Type | Identifier | Version | Read on |
|---|---|---|---|---|
| 1 | Jira | ABC-1 | updated 2026-10-01 | 2026-10-02 |

## Requirements'
sua_spec '- Priority: `must`' '- Priority: `must`
- Description: luôn mở được y
- Promote: BR-BILLING-111'
ky_vong 0 "promote REQ-001: ĐÃ NÂNG" sh "$RU" promote "$F" REQ-001
dung "promote REQ-001: chỉ mục có hàng rule mới" \
  sh -c "grep -q 'docs/product/rules/billing.md#BR-BILLING-111 | rule' '$CM_FILE'"
ky_vong 0 "promote REQ-001: bảng khớp dựng lại ngay" sh "$KT" check

nhom "promote: repo chưa có chỉ mục → không tạo file"
tao_fixture
AD="$T/adr.sh"
sua_d2() { thay "$F/tdd.md" "$1" "$2"; duyet_lai "$F/tdd.md"; ghi_based_on 2>/dev/null; }
sua_d2 '- Choice: file' '- Choice: file
- Promote: adr
- Scope: `src/*`'
ky_vong 0 "promote DEC-001 (không có chỉ mục): ĐÃ NÂNG" sh "$AD" promote "$F" DEC-001
dung "promote: không tạo file chỉ mục chung" sh -c "! test -f '$R/docs/knowledge-index.md'"
dung "promote: vẫn có README ADR" test -f "$R/docs/adr/README.md"

nhom "aw conventions check: khoá knowledge_index"
tao_fixture
CO="$T/check-conventions.sh"
CONV="$R/.git/agent-workflow/conventions.md"
ky_vong 0 "conventions: mẫu có knowledge_index đúng dạng → ĐẠT" sh "$CO"
thay "$CONV" 'knowledge_index: docs/knowledge-index.md' 'knowledge_index: docs/knowledge-index'
ky_vong_ly_do 1 "conventions: knowledge_index không kết thúc .md → KHÔNG ĐẠT" "conventions: nêu dạng đúng" "không kết thúc .md" sh "$CO"
thay "$CONV" 'knowledge_index: docs/knowledge-index' 'knowledge_index: /docs/x.md'
ky_vong 1 "conventions: knowledge_index tuyệt đối → KHÔNG ĐẠT" sh "$CO"
thay "$CONV" 'knowledge_index: /docs/x.md' 'knowledge_index:'
ky_vong 0 "conventions: knowledge_index khai trống (tắt) → ĐẠT" sh "$CO"

ket_thuc
