#!/usr/bin/env sh
# Test hoi quy cho cac cong chan va cho adapter.
#
#   sh tools/chay-thu.sh
#
# Repo nay ban cac cong chan; neu chinh cong chan hong ma khong ai biet thi
# ca quy trinh tro thanh trang tri. Moi ca kiem CA HAI CHIEU: chan dung luc
# va cho qua dung luc. Mot checker luon tra 0 con te hon khong co checker.

set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP="${TMPDIR:-/tmp}/aw-chay-thu.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT
T="$ROOT/tools"

n_ok=0
n_fail=0

# ky_vong <ma-mong-doi> <ten-ca> <lenh...>
ky_vong() {
  _mong="$1"; _ten="$2"; shift 2
  "$@" >/dev/null 2>&1
  _got=$?
  if [ "$_got" = "$_mong" ]; then
    n_ok=$((n_ok + 1))
    printf '  ok    %s\n' "$_ten"
  else
    n_fail=$((n_fail + 1))
    printf '  FAIL  %s — mã thoát %s, mong đợi %s\n' "$_ten" "$_got" "$_mong"
  fi
}

# dung <ten-ca> <lenh...> — lenh la mot phep thu tra 0/1
dung() {
  _ten="$1"; shift
  if "$@" >/dev/null 2>&1; then
    n_ok=$((n_ok + 1)); printf '  ok    %s\n' "$_ten"
  else
    n_fail=$((n_fail + 1)); printf '  FAIL  %s\n' "$_ten"
  fi
}

# thay <file> <tu> <thanh> — thay chuoi co dinh, khong dung regex
thay() {
  # Tìm tiếp trên phần CHƯA xét, để chuỗi thay chứa chuỗi tìm không lặp vô hạn.
  # Chuỗi tìm nhiều dòng: đọc cả file thành một bản ghi.
  awk -v a="$2" -v b="$3" 'BEGIN { RS = "\001" } {
    s = $0; o = ""
    while ((i = index(s, a)) > 0) { o = o substr(s, 1, i-1) b; s = substr(s, i+length(a)) }
    printf "%s", o s
  }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

g() { git -C "$R" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }

# ------------------------------------------------------------------ fixture
# Mot repo git day du, feature feat_x di het cac phase va DAT moi cong chan.
# Moi ca kiem lam hong dung mot cho roi ky vong checker bat duoc.
R="$TMP/repo"
F="$R/.agent-workflow/feat_x"

viet_spec() {
  cat > "$F/spec.md" <<'EOF'
# Đặc tả — x

- **Mức rủi ro:** `thường`

## Yêu cầu

### YC-001 — a
- Nguồn: `[JIRA]` ABC-1

### YC-002 — b
- Nguồn: `[CẦN-HỎI]` → open-questions.md § YC-002
- Giả định tạm: y

## Ngoài phạm vi
EOF
  cat > "$F/open-questions.md" <<'EOF'
# Điểm mù

## YC-002 — b
- **Giả định tạm đang dùng:** y
- **Mức ảnh hưởng:** `cục bộ`   <!-- toàn bộ thiết kế | cục bộ -->
- **Trạng thái:** `mở`   <!-- mở | đã trả lời -->
EOF
}

viet_tdd() {
  cat > "$F/tdd.md" <<'EOF'
---
based_on: []
---

# Thiết kế — x

## Bối cảnh code hiện có
Module src/a.

## Quyết định (D-xx)

### D-01 — lưu ở đâu
- tac_gia: `agent`
- Trạng thái: `đã duyệt`   <!-- đề xuất | đã duyệt | mở lại -->
- Chọn: file

## Mô hình dữ liệu
Dựa trên: D-01
Một file văn bản.

## Contract / API
Không áp dụng: không có API công khai.

## Flow
Đọc rồi ghi.

## Phi chức năng
Không áp dụng: thay đổi nội bộ nhỏ.

## Chiến lược test
Unit test.

## Ánh xạ YC

| YC | Mục |
|---|---|
| YC-001 | § Mô hình dữ liệu |
| YC-002 | § Flow |
EOF
  cat > "$F/phat-hien-thiet-ke.md" <<'EOF'
# Phát hiện

Không có phát hiện mức Chặn.
EOF
}

viet_plan() {
  cat > "$F/plan.md" <<'EOF'
# Kế hoạch — x

## Task

### T-01 — a
- Phủ: `YC-001`
- Dựa trên: `D-01`
- File dự kiến: `src/*` `test/*`
- Cách kiểm chứng: `npm test` → xanh
- Trạng thái: `[x]`

### T-02 — b
- Phủ: `YC-002`
- File dự kiến: `src/b.txt`
- Cách kiểm chứng: `npm test` → xanh
- Trạng thái: `[x]`

## Hoãn lại

| Mã | Lý do hoãn |
|---|---|

## Kiểm chứng thủ công

| Mã | Lý do |
|---|---|

## Phát sinh

| Task | Phát sinh gì | File | Xử lý |
|---|---|---|---|
EOF
}

viet_review() {
  printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | đạt |\n| YC-002 | chờ xác nhận |\n' > "$F/review.md"
}

ghi_based_on() {
  sh "$T/cap-nhat-based-on.sh" "$F" tdd.md spec.md open-questions.md >/dev/null
  sh "$T/cap-nhat-based-on.sh" "$F" plan.md spec.md tdd.md >/dev/null
}

tao_fixture() {
  rm -rf "$R"
  mkdir -p "$F" "$R/.agent-workflow/.quy-trinh" "$R/src" "$R/test"
  g init -q
  g checkout -q -b main
  cp "$ROOT/workflow/templates/conventions.md" "$R/.agent-workflow/conventions.md"
  printf 'LENH_KIEM_THU="true"\n' > "$R/.agent-workflow/.quy-trinh/cau-hinh.sh"
  printf 'goc\n' > "$R/src/a.txt"
  g add -A; g commit -q -m goc
  g checkout -q -b feat_x
  viet_spec; viet_tdd; viet_plan; viet_review
  ghi_based_on
  printf 'moi\n' > "$R/src/a.txt"
  printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"
  sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1
}

# ---------------------------------------------------------------- fixture goc
echo ""
echo "fixture"
tao_fixture
for c in truy-vet thiet-ke ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "feature đầy đủ qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done

# ---------------------------------------------------------------- truy vet
echo ""
echo "kiem-tra-truy-vet.sh"
CHK="$T/kiem-tra-truy-vet.sh"

viet_spec; thay "$F/spec.md" '- Nguồn: `[JIRA]` ABC-1' '- Mô tả: không nguồn'
ky_vong 1 "chặn yêu cầu không có nhãn nguồn" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '`[JIRA]`' '`[BRD]`'
ky_vong 1 "chặn nhãn tự chế ngoài 5 nhãn hợp lệ" sh "$CHK" "$F"

viet_spec; printf '# Điểm mù\n\nKhông có điểm mù.\n' > "$F/open-questions.md"
ky_vong 1 "chặn [CẦN-HỎI] không ghi vào open-questions" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" 'Giả định tạm đang dùng' 'Chỗ chưa rõ'
ky_vong 1 "chặn mục điểm mù thiếu giả định tạm" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '- **Mức ảnh hưởng:** `cục bộ`' ''
ky_vong 1 "chặn mục điểm mù thiếu mức ảnh hưởng" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '`cục bộ`' '`hơi hơi`'
ky_vong 1 "chặn mức ảnh hưởng tự chế" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '- **Mức rủi ro:** `thường`' ''
ky_vong 1 "chặn spec thiếu Mức rủi ro" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '`thường`' '`<cao | thường>`'
ky_vong 1 "chặn Mức rủi ro còn chỗ giữ chỗ" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '### YC-002' '### YC-001'
ky_vong 1 "chặn mã YC trùng nhau" sh "$CHK" "$F"

viet_spec; rm -f "$F/open-questions.md"
ky_vong 2 "chặn khi thiếu hẳn open-questions.md" sh "$CHK" "$F"
viet_spec

# ---------------------------------------------------------------- thiet ke
echo ""
echo "kiem-tra-thiet-ke.sh"
CHK="$T/kiem-tra-thiet-ke.sh"

viet_spec; viet_tdd
rm -f "$F/phat-hien-thiet-ke.md"
ky_vong 1 "chặn khi checker LLM chưa chạy (không có file phát hiện ≠ đạt)" sh "$CHK" "$F"

printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: `chưa`   <!-- chưa | đã sửa -->\n' > "$F/phat-hien-thiet-ke.md"
ky_vong 1 "chặn phát hiện mức Chặn chưa xử lý" sh "$CHK" "$F"

printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: `bác bỏ:`\n' > "$F/phat-hien-thiet-ke.md"
ky_vong 1 "chặn bác bỏ phát hiện mà không có lý do" sh "$CHK" "$F"

printf '### PH-01 — x\n- Mức: `Chặn`\n- Xử lý: bác bỏ: D-01 đã nói rõ\n### PH-02 — y\n- Mức: `Cảnh báo`\n- Xử lý: chưa\n' > "$F/phat-hien-thiet-ke.md"
ky_vong 0 "bác bỏ có lý do + cảnh báo chưa xử lý thì cho qua" sh "$CHK" "$F"

viet_tdd; thay "$F/open-questions.md" '`cục bộ`' '`toàn bộ thiết kế`'
ky_vong 1 "chặn [CẦN-HỎI] ảnh hưởng toàn bộ thiết kế còn mở" sh "$CHK" "$F"
thay "$F/open-questions.md" '`mở`' '`đã trả lời`'
ky_vong 0 "đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '- Nguồn: `[JIRA]` ABC-1' ''
ky_vong 1 "chặn khi đầu vào spec không qua checker của spec" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/tdd.md" '## Chiến lược test' '## Kiểm thử'
ky_vong 1 "chặn tdd thiếu mục bắt buộc" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Unit test.' ''
ky_vong 1 "chặn mục bỏ trống không ghi Không áp dụng" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Không áp dụng: không có API công khai.' 'Không áp dụng:'
ky_vong 1 "chặn Không áp dụng mà không có lý do" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '| YC-002 | § Flow |' ''
ky_vong 1 "chặn YC chưa được ánh xạ" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" 'Dựa trên: D-01' 'Dựa trên: D-09'
ky_vong 1 "chặn Dựa trên trỏ về D không tồn tại" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '`đã duyệt`' '`ổn rồi`'
ky_vong 1 "chặn trạng thái D-xx tự chế" sh "$CHK" "$F"

viet_tdd; thay "$F/tdd.md" '`đã duyệt`' '`mở lại`'
ky_vong 1 "chặn D mở lại mà không có lý do" sh "$CHK" "$F"
thay "$F/tdd.md" '- Chọn: file' '- Chọn: file
- Lý do mở lại: đổi sang DB'
ky_vong 0 "D mở lại có lý do thì thiết kế vẫn hợp lệ" sh "$CHK" "$F"

viet_tdd; thay "$F/spec.md" '`thường`' '`cao`'
ky_vong 1 "Mode 2: chặn rủi ro cao mà không có D do người viết" sh "$CHK" "$F"
thay "$F/tdd.md" '`agent`' '`nguoi`'
ky_vong 0 "Mode 2: có D tac_gia: nguoi thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/tdd.md" '## Quyết định (D-xx)' '## Quyết định (D-xx)
Không có quyết định cần duyệt.
## Bỏ'
thay "$F/tdd.md" 'Dựa trên: D-01' ''
ky_vong 0 "mục Quyết định được phép rỗng" sh "$CHK" "$F"
viet_tdd

# ---------------------------------------------------------------- ke hoach
echo ""
echo "kiem-tra-ke-hoach.sh"
CHK="$T/kiem-tra-ke-hoach.sh"
ghi_based_on

thay "$F/tdd.md" '`đã duyệt`' '`đề xuất`'
ky_vong 1 "chặn khi còn D-xx chưa được người duyệt" sh "$CHK" "$F"
viet_tdd; ghi_based_on

rm -f "$F/phat-hien-thiet-ke.md"
ky_vong 1 "chặn khi tdd.md không qua checker của design" sh "$CHK" "$F"
viet_tdd; ghi_based_on

viet_plan; thay "$F/plan.md" '- Phủ: `YC-002`' '- Phủ: `YC-001`'
ky_vong 1 "chặn YÊU CẦU BỊ BỎ SÓT (chiều ngược)" sh "$CHK" "$F"
thay "$F/plan.md" '|---|---|
' '|---|---|
| YC-002 | chờ BA |
'
ky_vong 0 "hoãn lại có lý do thì cho qua" sh "$CHK" "$F"
thay "$F/plan.md" '| YC-002 | chờ BA |' '| YC-002 | |'
ky_vong 1 "chặn hoãn lại bỏ trống lý do" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '`YC-002`' '`YC-999`'
ky_vong 1 "chặn task trỏ về mã YC không tồn tại (chiều xuôi)" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Dựa trên: `D-01`' '- Dựa trên: `D-07`'
ky_vong 1 "chặn task Dựa trên D không có trong tdd.md" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- File dự kiến: `src/b.txt`' ''
ky_vong 1 "chặn task thiếu File dự kiến" sh "$CHK" "$F"

viet_plan; thay "$F/plan.md" '- Cách kiểm chứng: `npm test` → xanh
- Trạng thái: `[x]`

## Hoãn' '- Cách kiểm chứng: <lệnh cụ thể>
- Trạng thái: `[x]`

## Hoãn'
ky_vong 1 "chặn chỗ giữ chỗ chưa điền" sh "$CHK" "$F"
viet_plan; ghi_based_on

# ---------------------------------------------------------------- hien thuc
echo ""
echo "kiem-tra-hien-thuc.sh"
CHK="$T/kiem-tra-hien-thuc.sh"
CH="$R/.agent-workflow/.quy-trinh/cau-hinh.sh"

printf 'LENH_KIEM_THU=""\n' > "$CH"
ky_vong 1 "chưa khai LENH_KIEM_THU là KHÔNG ĐẠT, không phải bỏ qua" sh "$CHK" "$F"

printf 'LENH_KIEM_THU="false"\n' > "$CH"
ky_vong 1 "chặn khi test đỏ" sh "$CHK" "$F"

printf 'LENH_KIEM_THU="true"\n' > "$CH"
thay "$F/plan.md" '- Trạng thái: `[x]`

## Hoãn' '- Trạng thái: `[~]`

## Hoãn'
ky_vong 1 "chặn khi còn task đang làm dở" sh "$CHK" "$F"
viet_plan; ghi_based_on

printf 'LENH_KIEM_THU="echo DAU-VET-DUY-NHAT-12345"\n' > "$CH"
sh "$CHK" "$F" >/dev/null 2>&1
dung "ghi output THẬT vào ket-qua-kiem-thu.md" grep -q 'DAU-VET-DUY-NHAT-12345' "$F/ket-qua-kiem-thu.md"
printf 'LENH_KIEM_THU="true"\n' > "$CH"

printf 'x\n' > "$R/README.md"
ky_vong 0 "file ngoài phạm vi chỉ CẢNH BÁO, không chặn implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo phạm vi" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*README.md'"
rm -f "$R/README.md"

# ---------------------------------------------------------------- ra soat
echo ""
echo "kiem-tra-ra-soat.sh"
CHK="$T/kiem-tra-ra-soat.sh"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

ky_vong 0 "rà soát đủ và đúng thì cho qua" sh "$CHK" "$F"

printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | đạt |\n' > "$F/review.md"
ky_vong 1 "chặn khi bỏ sót một yêu cầu" sh "$CHK" "$F"

printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | đạt |\n| YC-002 | đạt |\n' > "$F/review.md"
ky_vong 1 "chặn kết luận 'đạt' cho yêu cầu đứng trên giả định tạm" sh "$CHK" "$F"

printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | ổn |\n| YC-002 | chờ xác nhận |\n' > "$F/review.md"
ky_vong 1 "chặn kết luận tự chế ngoài 4 giá trị hợp lệ" sh "$CHK" "$F"
viet_review

printf 'x\n' > "$R/README.md"
ky_vong 1 "CỔNG CUỐI: chặn file ngoài phạm vi" sh "$CHK" "$F"
thay "$F/plan.md" '|---|---|---|---|
' '|---|---|---|---|
| T-01 | cần README | `README.md` | đã ghi |
'
ky_vong 0 "ghi file vào Phát sinh thì cho qua" sh "$CHK" "$F"
rm -f "$R/README.md"; viet_plan; ghi_based_on

printf '// covers: YC-001\n' > "$R/test/a.test.js"
ky_vong 1 "CỔNG CUỐI: chặn YC chưa có test gắn tag" sh "$CHK" "$F"
thay "$F/plan.md" '| Mã | Lý do |
|---|---|
' '| Mã | Lý do |
|---|---|
| YC-002 | cần kiểm bằng mắt trên UI |
'
ky_vong 0 "ghi Kiểm chứng thủ công có lý do thì cho qua" sh "$CHK" "$F"
printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"; viet_plan; ghi_based_on

printf '\n<!-- sửa sau khi đã có tdd -->\n' >> "$F/spec.md"
ky_vong 1 "CỔNG CUỐI: chặn artifact lỗi thời" sh "$CHK" "$F"
ky_vong 0 "…mà kế hoạch chỉ cảnh báo, không chặn" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_spec; ghi_based_on

rm -f "$F/ket-qua-kiem-thu.md"
ky_vong 1 "chặn khi chưa có ket-qua-kiem-thu.md" sh "$CHK" "$F"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

# ---------------------------------------------------------------- based_on
echo ""
echo "cap-nhat-based-on.sh"
printf -- '---\nkhac: giu\nbased_on:\n  - spec.md@1\n---\n\n# x\n' > "$F/thu.md"
sh "$T/cap-nhat-based-on.sh" "$F" thu.md spec.md >/dev/null
sh "$T/cap-nhat-based-on.sh" "$F" thu.md spec.md >/dev/null
dung "giữ khoá frontmatter khác" grep -q '^khac: giu' "$F/thu.md"
dung "chạy lại không nhân đôi based_on" test "$(grep -c 'spec.md@' "$F/thu.md")" = 1
dung "hash ghi ra khớp file" grep -q "spec.md@$(tr -d '\r' < "$F/spec.md" | cksum | awk '{print $1}')" "$F/thu.md"
printf '# không frontmatter\n' > "$F/thu.md"
sh "$T/cap-nhat-based-on.sh" "$F" thu.md spec.md >/dev/null
dung "thêm frontmatter khi file chưa có" sh -c "head -1 '$F/thu.md' | grep -q '^---\$'"
rm -f "$F/thu.md"

# ---------------------------------------------------------------- adapter
echo ""
echo "adapters/claude-code/build.sh"
BUILD="$ROOT/adapters/claude-code/build.sh"

O="$TMP/out1"; mkdir -p "$O"
ky_vong 0 "build bản đúng thành công" sh "$BUILD" --out "$O"

du=1
for f in commands/spec.md commands/design.md commands/plan.md commands/implement.md commands/review.md \
         commands/import.md agents/ra-soat-doc-lap.md agents/soat-thiet-ke.md skills/quy-trinh-agent/SKILL.md; do
  [ -f "$O/.claude/$f" ] || { du=0; echo "        thiếu .claude/$f"; }
done
[ -f "$O/.claude/commands/ship.md" ] && du=0
dung "sinh đúng bộ file, bỏ qua phase chưa hiện thực" test "$du" = 1
dung "command có bước xác định feature" grep -q 'xac-dinh-feature.sh \$ARGUMENTS' "$O/.claude/commands/design.md"
dung "command design gọi checker LLM" grep -q 'soat-thiet-ke' "$O/.claude/commands/design.md"

printf '# tôi tự viết\n' > "$O/.claude/commands/spec.md"
ky_vong 3 "từ chối ghi đè file người viết tay" sh "$BUILD" --out "$O"
dung "nội dung người viết còn nguyên" sh -c "head -1 '$O/.claude/commands/spec.md' | grep -q 'tôi tự viết'"
ky_vong 0 "--force thì cho phép ghi đè" sh "$BUILD" --out "$O" --force

FAKE="$TMP/fake"
tao_fake() {
  rm -rf "$FAKE"; mkdir -p "$FAKE/tools" "$FAKE/adapters/claude-code"
  cp -r "$ROOT/workflow" "$FAKE/"
  cp "$ROOT/workflow.yaml" "$FAKE/"
  cp -r "$ROOT/tools/lib" "$FAKE/tools/"
  cp "$ROOT"/tools/*.sh "$FAKE/tools/"
  cp "$BUILD" "$FAKE/adapters/claude-code/"
}

tao_fake
thay "$FAKE/workflow/phases/03-plan.md" '  - sh tools/kiem-tra-ke-hoach.sh' '  - kế hoạch trông có vẻ hợp lý'
O2="$TMP/out2"; mkdir -p "$O2"
ky_vong 4 "từ chối build khi exit_machine không phải lệnh chạy được" sh "$FAKE/adapters/claude-code/build.sh" --out "$O2"
dung "không để lại file viết dở khi build hỏng" sh -c "[ ! -f '$O2/.claude/commands/plan.md' ] && [ -z \"\$(find '$O2' -name '*.tmp')\" ]"

tao_fake
thay "$FAKE/workflow/phases/03-plan.md" '  - sh tools/kiem-tra-ke-hoach.sh' '  - sh tools/khong-ton-tai.sh'
ky_vong 4 "từ chối build khi lệnh trỏ tới script không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out3"

tao_fake
rm -f "$FAKE/workflow/checkers/thiet-ke.md"
ky_vong 4 "từ chối build khi llm_checker trỏ tới file không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out4"

# ---------------------------------------------------------------- cai dat
echo ""
echo "tools/cai-dat.sh"
R4="$TMP/repo4"; mkdir -p "$R4"
git -C "$R4" init -q
git -C "$R4" checkout -q -b main
ky_vong 0 "cài vào repo đích thành công" sh "$T/cai-dat.sh" "$R4" --lenh-kiem-thu "true"
QT4="$R4/.agent-workflow/.quy-trinh"
dung "chép bộ cài, checker LLM, công cụ và ghi cấu hình" sh -c \
  "[ -f '$QT4/tools/kiem-tra-thiet-ke.sh' ] && [ -f '$QT4/tools/lib/kiem-cheo.sh' ] && [ -f '$QT4/checkers/thiet-ke.md' ] && [ -f '$QT4/tools/xac-dinh-feature.sh' ] && grep -q 'LENH_KIEM_THU=\"true\"' '$QT4/cau-hinh.sh'"
dung "tạo conventions.md từ mẫu" grep -q '^mau_branch:' "$R4/.agent-workflow/conventions.md"

printf 'LENH_KIEM_THU="npm test"\n' > "$QT4/cau-hinh.sh"
printf '# của tôi\n```conventions\nmau_branch: job-*\n```\n' > "$R4/.agent-workflow/conventions.md"
sh "$T/cai-dat.sh" "$R4" >/dev/null 2>&1
dung "cài lại KHÔNG ghi đè cấu hình người sửa" grep -q 'npm test' "$QT4/cau-hinh.sh"
sh "$T/cai-dat.sh" "$R4" --force >/dev/null 2>&1
dung "KHÔNG ghi đè conventions.md, kể cả --force" grep -q 'của tôi' "$R4/.agent-workflow/conventions.md"

ky_vong 2 "từ chối cài vào chính repo agent-workflow" sh "$T/cai-dat.sh" "$ROOT"

# ---------------------------------------------------------------- xac dinh feature
echo ""
echo "xac-dinh-feature.sh"
XD="$QT4/tools/xac-dinh-feature.sh"
git -C "$R4" -c user.name=t -c user.email=t@t commit -q --allow-empty -m goc

ky_vong 3 "branch không khớp, không tham số → mã 3 (phải hỏi)" sh "$XD"
dung "branch không khớp → lấy tham số" test "$(sh "$XD" feat_abc 2>/dev/null)" = ".agent-workflow/feat_abc"
git -C "$R4" checkout -q -b job-them-todo
dung "branch khớp quy ước → tên branch đầy đủ" test "$(sh "$XD" 2>/dev/null)" = ".agent-workflow/job-them-todo"
dung "branch khớp thì thắng tham số" test "$(sh "$XD" khac 2>/dev/null)" = ".agent-workflow/job-them-todo"
dung "in 'Đang làm với:'" sh -c "sh '$XD' 2>&1 >/dev/null | grep -q 'Đang làm với: .agent-workflow/job-them-todo'"
git -C "$R4" checkout -q main
ky_vong 2 "từ chối tên feature có ../" sh "$XD" "../x"

# ---------------------------------------------------------------- tong ket
echo ""
echo "─────────────────────────────────────────"
printf 'Tổng: %d ca — %d đạt, %d hỏng\n' "$((n_ok + n_fail))" "$n_ok" "$n_fail"
[ "$n_fail" -gt 0 ] && exit 1
exit 0
