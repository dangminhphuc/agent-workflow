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
EOA
  cat > "$R/docs/product/rules/billing.md" <<'EOB'
# Luật billing

### BR-BILLING-001: mở a
- Rule: màn hình y phải hiện a. Phần sau nhìn từ chỗ khác.
- Scope: `src/*`
- Status: active

### BR-BILLING-002: cũ
- Rule: mở a | b khi không ra gì.
- Scope: `src/pay/*`
- Status: superseded by BR-BILLING-001
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
dung "khoá không khai → mặc định" bang "$(kt_chi_muc_khoa "$CONV")" "docs/knowledge-index.md|0"
thay "$CONV" 'uses_review:' 'uses_review:
knowledge_index: docs/trang-tri.md'
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
thay "$CONV" 'uses_review:' 'uses_review:
knowledge_index:'
ky_vong_ly_do 2 "index: khoá khai trống → SAI THAM SỐ" "index: khoá tắt → báo lý do" "SAI THAM SỐ" sh "$KT" index
dung "index: khoá tắt → không tạo file" sh -c "! test -f '$CM_FILE'"

nhom "aw knowledge index: khoá trỏ đường dẫn khác"
tao_fixture; cm_fixture
thay "$CONV" 'uses_review:' 'uses_review:
knowledge_index: docs/trang-tri.md'
sh "$KT" index 2>/dev/null > "$TMP/cm.out"
dung "index: in đường dẫn theo khoá" bang "$(cat "$TMP/cm.out")" "docs/trang-tri.md"
dung "index: file được tạo theo khoá" test -f "$R/docs/trang-tri.md"
dung "index: nội dung ở đường khác = phần mở đầu + bảng" bang "$(cat "$R/docs/trang-tri.md")" "$CM_INTRO$CM_TABLE"
dung "index: không tạo file đường mặc định" sh -c "! test -f '$CM_FILE'"

ket_thuc
