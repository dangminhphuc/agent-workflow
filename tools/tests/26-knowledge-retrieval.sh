#!/usr/bin/env sh
# aw knowledge: lấy kiến thức bền theo đường dẫn (kt_lay).
# Chạy riêng: sh tools/tests/26-knowledge-retrieval.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
KT="$T/knowledge.sh"

# kt_fixture — gọi sau bất kỳ tao_fixture nào: đặt kiến thức bền lên main (nằm trên Base:), rồi
# đưa vào nhánh việc. ADR 0001 accepted src/*, 0002 superseded, 0003 accepted lib/*; tài liệu module
# src/ + lib/; một luật BR-BILLING-001 active src/*.
kt_fixture() {
  g checkout -q main
  mkdir -p "$R/docs/adr" "$R/docs/product/rules" "$R/lib"
  for _n in 1:accepted:src 2:superseded\ by\ 0001:src 3:accepted:lib; do
    _i=${_n%%:*}; _r=${_n#*:}; _st=${_r%:*}; _sc=${_r##*:}
    printf '# ADR-000%s: a\n\n- Status: %s\n- Scope: `%s/*`\n' "$_i" "$_st" "$_sc" > "$R/docs/adr/000$_i-x-dec-00$_i.md"
  done
  . "$T/lib/adr.sh"; adr_lam_chi_muc "$R/docs/adr"
  printf '# src\n' > "$R/src/ARCHITECTURE.md"; printf '# lib\n' > "$R/lib/ARCHITECTURE.md"
  cat > "$R/docs/product/rules/billing.md" <<'EOB'
# Luật billing

### BR-BILLING-001: x
- Rule: luôn mở được x
- Scope: `src/*`
- Source: `[JIRA]` ABC-1 (version: updated 2026-10-01)
- Status: active
- Acceptance:
  - mở x thấy a
- Origin: `feat_x` § REQ-001
EOB
  g add docs src lib; g commit -q -m "kien thuc ben"
  g checkout -q -; g merge -q main
  viet_intake
}

nhom "knowledge design: hồi quy sau khi tách kt_lay"
tao_fixture
kt_fixture
thay "$F/tdd.md" 'Module src/a.' 'Module `src/a.txt`.'
dung "design: output không đổi (hồi quy)" bang "$(sh "$KT" design "$F" 2>/dev/null | tr '\n' ' ')" \
  "docs/adr/README.md docs/adr/0001-x-dec-001.md docs/product/rules/billing.md#BR-BILLING-001 src/ARCHITECTURE.md "


nhom "knowledge implement: kiến thức bền theo Expected files"
tao_fixture
kt_fixture
dung "implement: Expected files src/* → ADR Scope src/*, luật, ARCHITECTURE cha; không ADR superseded/lib" \
  bang "$(sh "$KT" implement "$F" 2>/dev/null | tr '\n' ' ')" \
  "docs/adr/0001-x-dec-001.md docs/product/rules/billing.md#BR-BILLING-001 src/ARCHITECTURE.md "
dung "implement: feature (có design) → không in chỉ mục ADR" sh -c "! sh '$KT' implement '$F' 2>/dev/null | grep -qx 'docs/adr/README.md'"
thay "$F/plan.md" '`src/*` `test/*`' '`src/moi/**` `test/*`'
dung "implement: thư mục mới chưa có trên base → vẫn khớp qua tiền tố" sh -c "sh '$KT' implement '$F' 2>/dev/null | grep -qx 'src/ARCHITECTURE.md'"
thay "$F/plan.md" '`src/moi/**` `test/*`' '`test/*` `docs/adr/*`'
thay "$F/plan.md" '`src/b.txt`' '`test/b.test.js`'
dung "implement: chỉ file test và thư mục ADR → không in gì" bang "$(sh "$KT" implement "$F" 2>/dev/null)" ""
thay "$F/plan.md" '`test/*` `docs/adr/*`' '`src/*` `test/*`'
thay "$F/plan.md" '`test/b.test.js`' '`src/b.txt`'
thay "$F/intake.md" "@ \`$(git -C "$R" rev-parse --short main)\`" ''
dung "implement: Base thiếu sha → vẫn in src/ARCHITECTURE.md" sh -c "sh '$KT' implement '$F' 2>/dev/null | grep -qx 'src/ARCHITECTURE.md'"
rm -f "$F/plan.md"
ky_vong 0 "implement: không có plan.md → LISTED" sh "$KT" implement "$F"
dung "implement: không có plan.md → không in gì" bang "$(sh "$KT" implement "$F" 2>/dev/null)" ""

nhom "knowledge implement: chore bỏ design thì in chỉ mục ADR trước"
tao_fixture chore chore_v
kt_fixture
dung "implement chore: dòng đầu là chỉ mục ADR" bang "$(sh "$KT" implement "$F" 2>/dev/null | head -1)" "docs/adr/README.md"

nhom "knowledge implement: mở rộng glob qua cây Base (ls-tree) và Base hỏng"
tao_fixture
kt_fixture
printf '# ADR-0004: a\n\n- Status: accepted\n- Scope: `src/a.txt`\n' > "$R/docs/adr/0004-x-dec-004.md"
thay "$F/plan.md" '`src/*` `test/*`' '`src/a*.txt` `test/*`'
dung "implement: glob khớp file có trên Base (ls-tree) → in ADR Scope một file" sh -c "sh '$KT' implement '$F' 2>/dev/null | grep -qx 'docs/adr/0004-x-dec-004.md'"
thay "$F/plan.md" '`src/a*.txt`' '`src/zz*.txt`'
dung "implement: glob không khớp file nào trên Base → tiền tố src không khớp ADR Scope một file" sh -c "! sh '$KT' implement '$F' 2>/dev/null | grep -qx 'docs/adr/0004-x-dec-004.md'"
thay "$F/plan.md" '`src/zz*.txt`' '`src/*` `test/*`'
thay "$F/intake.md" "@ \`$(git -C "$R" rev-parse --short main)\`" '@ `deadbeefdeadbeef`'
ky_vong 0 "implement: Base ghi sha không có trong repo → LISTED" sh "$KT" implement "$F"
dung "implement: Base ghi sha không có trong repo → dùng tiền tố, vẫn in src/ARCHITECTURE.md" sh -c "sh '$KT' implement '$F' 2>/dev/null | grep -qx 'src/ARCHITECTURE.md'"



nhom "knowledge implement: tài liệu module lồng và đường dẫn có dấu"
tao_fixture
kt_fixture
g checkout -q main
mkdir -p "$R/src/billing" "$R/src/thanh-toán"
printf '# billing\n' > "$R/src/billing/ARCHITECTURE.md"; echo x > "$R/src/billing/a.txt"
printf '# ADR-0005: a\n\n- Status: accepted\n- Scope: `src/thanh-toán/*`\n' > "$R/docs/adr/0005-x-dec-005.md"
echo y > "$R/src/thanh-toán/a.txt"
g add src docs; g commit -q -m "module long + duong dan co dau"
g checkout -q -; g merge -q main
thay "$F/plan.md" '`src/*` `test/*`' '`src/billing/**` `test/*`'
viet_intake
dung "implement: ARCHITECTURE.md lồng src/billing/ + token src/billing/** → in" sh -c "sh '$KT' implement '$F' 2>/dev/null | grep -qx 'src/billing/ARCHITECTURE.md'"
thay "$F/plan.md" '`src/billing/**`' '`src/th*/*.txt`'
dung "implement: đường dẫn có dấu (src/thanh-toán) khớp glob trên cây Base → in ADR" sh -c "sh '$KT' implement '$F' 2>/dev/null | grep -qx 'docs/adr/0005-x-dec-005.md'"

nhom "knowledge review: tài liệu mà diff đụng phạm vi"
tao_fixture
kt_fixture
dung "review: chưa có diff → không in gì" bang "$(sh "$KT" review "$F" 2>/dev/null)" ""
ky_vong 0 "review: chưa có diff → LISTED" sh "$KT" review "$F"
echo moi-review > "$R/src/a.txt"
dung "review: diff đụng src/ → đúng tập kt_anh_huong" \
  bang "$(sh "$KT" review "$F" 2>/dev/null | sort | tr '\n' ' ')" \
  "docs/adr/0001-x-dec-001.md docs/product/rules/billing.md#BR-BILLING-001 src/ARCHITECTURE.md "
mkdir -p "$R/lib"; echo x > "$R/lib/b.txt"
dung "review: diff đụng lib/ → thêm lib/ARCHITECTURE.md" sh -c "sh '$KT' review '$F' 2>/dev/null | grep -qx 'lib/ARCHITECTURE.md'"
dung "review: diff đụng lib/ → thêm ADR 0003" sh -c "sh '$KT' review '$F' 2>/dev/null | grep -qx 'docs/adr/0003-x-dec-003.md'"
dung "review: không trùng dòng" bang "$(sh "$KT" review "$F" 2>/dev/null | sort | uniq -d)" ""

ket_thuc
