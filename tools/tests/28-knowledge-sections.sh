#!/usr/bin/env sh
# aw knowledge show + kt_muc / kt_khoi / kt_phan_con: đọc kiến thức bền theo mục.
# Chạy riêng: sh tools/tests/28-knowledge-sections.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
KT="$T/knowledge.sh"

# ks_fixture — repo fixture + tài liệu module có mục khai Scope + file luật hai luật.
ks_fixture() {
  tao_fixture
  mkdir -p "$R/docs/product/rules"
  cat > "$R/src/ARCHITECTURE.md" <<'EOA'
# Kiến trúc src

## Tổng quan
Mô tả chung.

## Thanh toán 
- Scope: `src/pay/*`

Luồng thanh toán.

## Mục #2
- Scope: `src/b/*` `src/c/*`

Chi tiết mục hai.
EOA
  cat > "$R/docs/product/rules/billing.md" <<'EOB'
# Luật billing

### BR-BILLING-001: một
- Rule: luật một
- Scope: `src/*`
- Status: active

### BR-BILLING-002: hai
- Rule: luật hai
- Scope: `src/*`
- Status: active
EOB
}
# ks_chay <lệnh show…> — chạy show ở fixture, stdout.
ks_show() { sh "$KT" show "$@" 2>/dev/null; }
# ks_muc <file> — chạy kt_muc.
ks_muc() { ( . "$T/lib/knowledge.sh"; kt_muc "$1" ); }

nhom "knowledge show: kt_muc"
ks_fixture
A="$R/src/ARCHITECTURE.md"
TAB=$(printf '\t')
dung "kt_muc: đúng 2 dòng, neo + dải dòng + glob (mục cuối tới hết file)" \
  bang "$(ks_muc "$A")" "Thanh toán${TAB}6${TAB}10${TAB}src/pay/*
Mục #2${TAB}11${TAB}14${TAB}src/b/* src/c/*"
sed 's/$/\r/' "$A" > "$TMP/crlf.md"
dung "kt_muc: bản CRLF cùng output" bang "$(ks_muc "$TMP/crlf.md")" "$(ks_muc "$A")"
dung "kt_muc: đọc stdin khi file là -" bang "$(ks_muc - < "$A")" "$(ks_muc "$A")"

nhom "knowledge show: refs"
dung "show '#Thanh toán': heading + Scope, không có Mục #2" sh -c "
  o=\$(sh '$KT' show 'src/ARCHITECTURE.md#Thanh toán' 2>/dev/null)
  printf '%s\n' \"\$o\" | grep -qx '==> src/ARCHITECTURE.md#Thanh toán <==' &&
  printf '%s\n' \"\$o\" | grep -q '^## Thanh toán' &&
  printf '%s\n' \"\$o\" | grep -q '^- Scope: .src/pay/\*.' &&
  ! printf '%s\n' \"\$o\" | grep -q 'Mục #2'"
dung "show '#Mục #2': thấy khối" sh -c "sh '$KT' show 'src/ARCHITECTURE.md#Mục #2' 2>/dev/null | grep -q '^## Mục #2'"
dung "show <file>: phần còn lại (có Tổng quan, không có Thanh toán)" sh -c "
  o=\$(sh '$KT' show src/ARCHITECTURE.md 2>/dev/null)
  printf '%s\n' \"\$o\" | grep -q '^## Tổng quan' && ! printf '%s\n' \"\$o\" | grep -q 'Thanh toán'"
dung "show luật BR-BILLING-002: có 002, không có 001" sh -c "
  o=\$(sh '$KT' show 'docs/product/rules/billing.md#BR-BILLING-002' 2>/dev/null)
  printf '%s\n' \"\$o\" | grep -q 'BR-BILLING-002' && ! printf '%s\n' \"\$o\" | grep -q 'BR-BILLING-001'"
dung "show file không có mục khai: in nguyên file" sh -c "
  [ \"\$(sh '$KT' show docs/product/rules/billing.md 2>/dev/null | tail -n +2)\" = \"\$(cat '$R/docs/product/rules/billing.md')\" ]"
ky_vong 2 "show: neo không có → SAI THAM SỐ" sh "$KT" show 'src/ARCHITECTURE.md#Không có'
ky_vong 2 "show: file không có → SAI THAM SỐ" sh "$KT" show nope.md
ky_vong 2 "show: không tham số → SAI THAM SỐ" sh "$KT" show
dung "show: một ref sai → không in phần nào" bang "$(sh "$KT" show src/ARCHITECTURE.md 'src/ARCHITECTURE.md#x' 2>/dev/null)" ""

nhom "knowledge show: hai mục cùng heading"
ks_fixture
printf '\n## Thanh toán\n- Scope: `src/dup/*`\nbản hai\n' >> "$R/src/ARCHITECTURE.md"
dung "show: lấy mục đầu" sh -c "o=\$(sh '$KT' show 'src/ARCHITECTURE.md#Thanh toán' 2>/dev/null); printf '%s\n' \"\$o\" | grep -q 'src/pay' && ! printf '%s\n' \"\$o\" | grep -q 'bản hai'"

nhom "knowledge: phát ref (design / spec)"
ks_fixture
printf '\n### BR-BILLING-003: ba\n- Rule: cũ\n- Scope: `src/*`\n- Status: deprecated\n' >> "$R/docs/product/rules/billing.md"
mkdir -p "$R/src/pay" "$R/src/b"; echo x > "$R/src/pay/x.txt"; echo x > "$R/src/b/y.txt"
g add -A; g commit -q -m "kien thuc ben"
ks_design() { thay "$F/tdd.md" 'Module src/a.' "Module \`$1\`."; sh "$KT" design "$F" 2>/dev/null; thay "$F/tdd.md" "Module \`$1\`." 'Module src/a.'; }
O=$(ks_design src/pay/x.txt)
dung "design src/pay/x.txt: ref mục Thanh toán + file + luật 001/002" bang "$(printf '%s\n' "$O" | sort | tr '\n' ' ')" \
  "docs/product/rules/billing.md#BR-BILLING-001 docs/product/rules/billing.md#BR-BILLING-002 src/ARCHITECTURE.md src/ARCHITECTURE.md#Thanh toán "
dung "design: luật deprecated không in" sh -c "! printf '%s\n' '$O' | grep -q BR-BILLING-003"
dung "design: mỗi ref một lần" bang "$(printf '%s\n' "$O" | sort | uniq -d)" ""
O=$(ks_design src/b/y.txt)
dung "design src/b/y.txt: có #Mục #2, không #Thanh toán" sh -c "printf '%s\n' '$O' | grep -qx 'src/ARCHITECTURE.md#Mục #2' && ! printf '%s\n' '$O' | grep -q 'Thanh toán'"
dung "spec: ref từng luật active, không dòng file trần, không deprecated" \
  bang "$(sh "$KT" spec "$F" 2>/dev/null | tr '\n' ' ')" "docs/product/rules/billing.md#BR-BILLING-001 docs/product/rules/billing.md#BR-BILLING-002 "

nhom "knowledge: tài liệu không khai mục → như cũ"
ks_fixture
printf '# Kiến trúc src\n\nKhông có mục khai Scope.\n' > "$R/src/ARCHITECTURE.md"
g add -A; g commit -q -m "kien thuc ben"
mkdir -p "$R/src/pay"; echo x > "$R/src/pay/x.txt"; g add -A; g commit -q -m x
thay "$F/tdd.md" 'Module src/a.' 'Module `src/pay/x.txt`.'
dung "design: tài liệu không khai mục → chỉ src/ARCHITECTURE.md trần (byte như trước)" \
  bang "$(sh "$KT" design "$F" 2>/dev/null | grep -v billing | tr '\n' ' ')" "src/ARCHITECTURE.md "

nhom "knowledge: phase sinh ra dùng aw knowledge show"
dung "workflow/phases: spec, design, implement, review nhắc aw knowledge show" sh -c "
  for p in 01-spec 02-design 04-implement 05-review; do grep -q 'aw knowledge show' \"$T/../workflow/phases/\$p.md\" || exit 1; done"

ket_thuc
