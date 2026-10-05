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
. "$ROOT/tools/lib/ket-qua.sh"
kq_khai chay-thu.sh "0=MỌI CA ĐẠT" "1=CÓ CA HỎNG — xem các dòng FAIL phía trên"
kq_don 'rm -rf "$TMP"'
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

# bang <a> <b> — so chuỗi, dùng với dung
bang() { test "$1" = "$2"; }

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
# Mot repo git day du, mot feature di het cac phase va DAT moi cong chan.
# Moi ca kiem lam hong dung mot cho roi ky vong checker bat duoc.
#
# LOAI quyet dinh luat theo loai viec; tao_fixture <loai> <branch> dung lai
# R, F, LOAI cho tung loai. Test "bao ve" test/a.test.js co san tren main.
LOAI=feature
R="$TMP/repo"
F="$R/.agent-workflow/feat_x"

viet_intake() {
  cat > "$F/intake.md" <<EOF
# Tiếp nhận — x

- **Loại việc:** \`$LOAI\`   <!-- người xác nhận -->
- **Base:** \`main\` @ \`$(git -C "$R" rev-parse --short main 2>/dev/null)\`
- **Mục tiêu:** làm x

## Input

- \`[JIRA]\` ABC-1
- \`[NGƯỜI-DÙNG]\`
  > cần làm x cho màn hình y
EOF
}

viet_spec() {
  cat > "$F/spec.md" <<'EOF'
# Đặc tả — x

- **Mức rủi ro:** `thường`
- **Trạng thái spec:** `đã duyệt`

## Yêu cầu

### YC-001 — a
- Nguồn: `[JIRA]` ABC-1
- Ưu tiên: `bắt buộc`
- Tiêu chí chấp nhận:
  - [ ] mở y thấy a

### YC-002 — b
- Nguồn: `[CẦN-HỎI]` → open-questions.md § YC-002
- Giả định tạm: y
- Ưu tiên: `nên có`
- Tiêu chí chấp nhận:
  - [ ] mở y thấy b
EOF
  case "$LOAI" in
    refactor|perf)
      thay "$F/spec.md" '- Nguồn: `[JIRA]` ABC-1' '- Nguồn: `[JIRA]` ABC-1
- Loại YC: `giữ nguyên`
- Được bảo vệ bởi: `test/a.test.js`' ;;
  esac
  case "$LOAI" in
    refactor) printf -- '- Loại YC: `cấu trúc`\n' >> "$F/spec.md" ;;
    perf)     printf -- '- Loại YC: `hiệu năng`\n- Mục tiêu: dưới 10 ms\n' >> "$F/spec.md" ;;
  esac
  if [ "$LOAI" = "bugfix" ]; then
    printf '\n## Tái hiện lỗi\n\n- Cách tái hiện: mở a\n- Hành vi sai: ra goc\n- Hành vi đúng: ra moi\n' >> "$F/spec.md"
  fi
  cat >> "$F/spec.md" <<'EOF'

## Ràng buộc & phụ thuộc

Không có ràng buộc hay phụ thuộc ngoài.

## Ngoài phạm vi

- màn hình z — lý do: đợt sau

## Mâu thuẫn giữa các nguồn

| Nguồn A nói | Nguồn B nói | Xử lý |
|---|---|---|
| | | |

Không phát hiện mâu thuẫn.
EOF
  cat > "$F/open-questions.md" <<'EOF'
# Điểm mù

## YC-002 — b
- **Giả định tạm đang dùng:** y
- **Mức chặn:** `không chặn`   <!-- chặn | chặn review | không chặn -->
- **Trạng thái:** `mở`   <!-- mở | đã trả lời -->
EOF
}

viet_tdd() {
  [ "$LOAI" = "chore" ] && { rm -f "$F/tdd.md" "$F/phat-hien-thiet-ke.md"; return 0; }
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

## Test cũ bị sửa

| File test | Lý do sửa |
|---|---|

## Nâng dependency

| Thư viện | Cũ → mới | Mức |
|---|---|---|

## Phát sinh

| Task | Phát sinh gì | File | Xử lý |
|---|---|---|---|
EOF
  if [ "$LOAI" = "chore" ]; then
    thay "$F/plan.md" '- Dựa trên: `D-01`
' ''
    thay "$F/plan.md" '`src/*` `test/*`' '`docs/*`'
  fi
}

viet_review() {
  printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | đạt |\n| YC-002 | chờ xác nhận |\n' > "$F/review.md"
  [ "$LOAI" = "bugfix" ] && printf '\n- Test tái hiện đỏ vì: grep không thấy "moi" trong src/a.txt\n' >> "$F/review.md"
  return 0
}

ghi_based_on() {
  sh "$T/cap-nhat-based-on.sh" "$F" spec.md intake.md >/dev/null
  if [ "$LOAI" = "chore" ]; then
    sh "$T/cap-nhat-based-on.sh" "$F" plan.md spec.md >/dev/null
  else
    sh "$T/cap-nhat-based-on.sh" "$F" tdd.md spec.md open-questions.md >/dev/null
    sh "$T/cap-nhat-based-on.sh" "$F" plan.md spec.md tdd.md >/dev/null
  fi
}

# tao_fixture [loai] [branch]
tao_fixture() {
  LOAI="${1:-feature}"; _br="${2:-feat_x}"
  R="$TMP/repo-$LOAI"; F="$R/.agent-workflow/$_br"
  rm -rf "$R"
  mkdir -p "$F" "$R/.agent-workflow/.quy-trinh" "$R/src" "$R/test" "$R/docs"
  g init -q
  g checkout -q -b main
  cp "$ROOT/workflow/templates/conventions.md" "$R/.agent-workflow/conventions.md"
  {
    printf 'LENH_KIEM_THU="grep -q moi %s/src/a.txt"\n' "$R"
    printf 'LENH_DO_HIEU_NANG="echo KET_QUA: 5 ms"\n'
  } > "$R/.agent-workflow/.quy-trinh/cau-hinh.sh"
  printf 'goc\n' > "$R/src/a.txt"
  printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"
  g add src test; g commit -q -m goc
  g checkout -q -b "$_br"
  viet_intake; viet_spec; viet_tdd; viet_plan; viet_review
  ghi_based_on
  case "$LOAI" in
    bugfix)
      printf '// covers: YC-001\n' > "$R/test/b.test.js"
      sh "$T/kiem-tra-tai-hien.sh" "$F" >/dev/null 2>&1 ;;
    perf)
      sh "$T/kiem-tra-hieu-nang.sh" "$F" --truoc >/dev/null 2>&1 ;;
  esac
  if [ "$LOAI" = "chore" ]; then
    printf 'LENH_KIEM_THU="true"\n' > "$R/.agent-workflow/.quy-trinh/cau-hinh.sh"
    printf 'huong dan\n' > "$R/docs/huong-dan.md"
  else
    printf 'moi\n' > "$R/src/a.txt"
  fi
  [ "$LOAI" = "perf" ] && sh "$T/kiem-tra-hieu-nang.sh" "$F" --sau >/dev/null 2>&1
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

viet_spec; thay "$F/open-questions.md" '- **Mức chặn:** `không chặn`' ''
ky_vong 1 "chặn mục điểm mù thiếu mức chặn" sh "$CHK" "$F"

viet_spec; thay "$F/open-questions.md" '`không chặn`' '`hơi hơi`'
ky_vong 1 "chặn mức chặn tự chế" sh "$CHK" "$F"

for m in "chặn" "chặn review" "không chặn"; do
  viet_spec; thay "$F/open-questions.md" '`không chặn`' "\`$m\`"
  ky_vong 0 "mức chặn hợp lệ: $m" sh "$CHK" "$F"
done

# Nhãn cũ (trước khi có 3 mức): chặn kèm hướng dẫn đổi — "cục bộ" có hai đích, người chọn
viet_spec; thay "$F/open-questions.md" '- **Mức chặn:** `không chặn`' '- **Mức ảnh hưởng:** `cục bộ`'
ky_vong 1 "chặn nhãn cũ \"Mức ảnh hưởng\"" sh "$CHK" "$F"
dung "…kèm hướng dẫn đổi sang Mức chặn" sh -c "sh '$CHK' '$F' | grep -q 'đã đổi thành \"Mức chặn'"
viet_spec; thay "$F/open-questions.md" '`không chặn`' '`toàn bộ thiết kế`'
ky_vong 1 "chặn giá trị cũ \"toàn bộ thiết kế\" dưới nhãn Mức chặn" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '- **Mức rủi ro:** `thường`' ''
ky_vong 1 "chặn spec thiếu Mức rủi ro" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '`thường`' '`<cao | thường>`'
ky_vong 1 "chặn Mức rủi ro còn chỗ giữ chỗ" sh "$CHK" "$F"

viet_spec; thay "$F/spec.md" '### YC-002' '### YC-001'
ky_vong 1 "chặn mã YC trùng nhau" sh "$CHK" "$F"

viet_spec; rm -f "$F/open-questions.md"
ky_vong 2 "chặn khi thiếu hẳn open-questions.md" sh "$CHK" "$F"

# "### " không phải YC đóng vùng YC: Nguồn nằm dưới nó không thuộc YC phía trên
viet_spec; thay "$F/spec.md" '### YC-001 — a
- Nguồn: `[JIRA]` ABC-1' '### YC-001 — a
- Mô tả: a

### Ghi chú
- Nguồn: `[JIRA]` ABC-1'
ky_vong 1 "chặn YC không có Nguồn dù \"### phụ\" bên dưới có Nguồn" sh "$CHK" "$F"
dung "…đúng lý do: YC-001 thiếu Nguồn" sh -c "sh '$CHK' '$F' | grep -q 'YC-001: thiếu dòng'"
viet_spec; thay "$F/spec.md" '### YC-002' '### Ghi chú
- Nguồn: `[JIRA]` ABC-9

### YC-002'
ky_vong 0 "Nguồn dưới \"### phụ\" không bị cộng vào YC phía trên" sh "$CHK" "$F"

# open-questions.md 0 byte = đã rà, không có điểm mù (không được làm lệch thứ tự file)
viet_spec; thay "$F/spec.md" '`[CẦN-HỎI]` → open-questions.md § YC-002
- Giả định tạm: y' '`[JIRA]` ABC-1'
: > "$F/open-questions.md"
ky_vong 0 "open-questions.md 0 byte thì cho qua" sh "$CHK" "$F"

# Trạng thái spec: chỉ người đổi sang "đã duyệt"; spec vẫn qua checker khi còn "đề xuất"
viet_spec; thay "$F/spec.md" '`đã duyệt`' '`đề xuất`'
ky_vong 0 "spec \"đề xuất\" vẫn qua checker của spec" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- **Trạng thái spec:** `đã duyệt`' ''
ky_vong 1 "chặn spec thiếu Trạng thái spec" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '`đã duyệt`' '`ok`'
ky_vong 1 "chặn Trạng thái spec tự chế" sh "$CHK" "$F"

# open-questions.md <-> spec.md phải khớp trạng thái
viet_spec; printf '\n## YC-099 — mồ côi\n- **Giả định tạm đang dùng:** z\n- **Mức chặn:** `không chặn`\n- **Trạng thái:** `mở`\n' >> "$F/open-questions.md"
ky_vong 1 "chặn mục open-questions trỏ về YC không có trong spec" sh "$CHK" "$F"
dung "…đúng lý do: mục mồ côi YC-099" sh -c "sh '$CHK' '$F' | grep -q 'spec.md không có YC-099'"
viet_spec; thay "$F/open-questions.md" '`mở`' '`xong`'
ky_vong 1 "chặn Trạng thái điểm mù tự chế" sh "$CHK" "$F"
viet_spec; thay "$F/open-questions.md" '`mở`' '`đã trả lời`'
printf -- '- **Trả lời:** qua email\n' >> "$F/open-questions.md"
ky_vong 1 "chặn điểm mù đã trả lời mà spec vẫn gắn [CẦN-HỎI]" sh "$CHK" "$F"
thay "$F/spec.md" '`[CẦN-HỎI]` → open-questions.md § YC-002' '`[FILE]` open-questions.md § YC-002'
ky_vong 0 "đã trả lời + spec đổi nhãn nguồn thì cho qua" sh "$CHK" "$F"
thay "$F/open-questions.md" '- **Trả lời:** qua email' '- **Trả lời:** <người trả lời ghi vào đây>'
ky_vong 1 "chặn đã trả lời mà Trả lời còn trống/chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '`[CẦN-HỎI]` → open-questions.md § YC-002' '`[JIRA]` ABC-2'
ky_vong 1 "chặn spec đã có nguồn mà điểm mù vẫn mở" sh "$CHK" "$F"
viet_spec

# Tiêu chí chấp nhận, Ưu tiên
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' ''
ky_vong 1 "chặn YC không có tiêu chí chấp nhận" sh "$CHK" "$F"
dung "…đúng lý do: YC-001 thiếu tiêu chí" sh -c "sh '$CHK' '$F' | grep -q 'YC-001: thiếu tiêu chí chấp nhận'"
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [ ] <quan sát được từ bên ngoài>'
ky_vong 1 "chặn tiêu chí chấp nhận còn chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '  - [ ] mở y thấy a' '  - [x] mở y thấy a'
ky_vong 0 "tiêu chí đã tick [x] vẫn tính" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- Ưu tiên: `bắt buộc`' ''
ky_vong 1 "chặn YC thiếu Ưu tiên" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '`bắt buộc`' '`cao`'
ky_vong 1 "chặn Ưu tiên tự chế" sh "$CHK" "$F"

# Các mục bắt buộc ngoài YC
viet_spec; thay "$F/spec.md" '## Ngoài phạm vi' '## Ghi chú'
ky_vong 1 "chặn spec thiếu mục Ngoài phạm vi" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- màn hình z — lý do: đợt sau' '- <...> — lý do: <...>'
ky_vong 1 "chặn Ngoài phạm vi chỉ có chỗ giữ chỗ" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '- màn hình z — lý do: đợt sau' 'Không có.'
ky_vong 0 "Ngoài phạm vi ghi \"Không có.\" thì cho qua" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Ràng buộc & phụ thuộc' '## Khác'
ky_vong 1 "chặn spec thiếu mục Ràng buộc & phụ thuộc" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" 'Không có ràng buộc hay phụ thuộc ngoài.' '<!-- chưa rà -->'
ky_vong 1 "chặn Ràng buộc rỗng (chỉ có comment)" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '## Mâu thuẫn giữa các nguồn' '## Khác'
ky_vong 1 "chặn spec thiếu mục Mâu thuẫn giữa các nguồn" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" 'Không phát hiện mâu thuẫn.' '<Không có thì ghi "Không phát hiện mâu thuẫn.">'
ky_vong 1 "chặn bảng mâu thuẫn rỗng, chỉ có chỗ giữ chỗ" sh "$CHK" "$F"

# Mâu thuẫn: agent không tự phân xử
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | chọn 30 ngày cho an toàn |'
ky_vong 1 "chặn mâu thuẫn do agent tự phân xử" sh "$CHK" "$F"
dung "…đúng lý do: cột Xử lý" sh -c "sh '$CHK' '$F' | grep -q 'Agent không tự phân xử'"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | open-questions.md § YC-002 |'
ky_vong 0 "mâu thuẫn trỏ tới điểm mù có thật thì cho qua" sh "$CHK" "$F"
viet_spec; thay "$F/spec.md" '| | | |' '| BRD: 30 ngày | ABC-1: 60 ngày | open-questions.md § YC-099 |'
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

viet_tdd; thay "$F/open-questions.md" '`không chặn`' '`chặn review`'
ky_vong 0 "điểm mù \"chặn review\" còn mở không chặn design" sh "$CHK" "$F"
viet_spec; viet_tdd; thay "$F/open-questions.md" '`không chặn`' '`chặn`'
ky_vong 1 "chặn điểm mù \"chặn\" còn mở" sh "$CHK" "$F"
dung "…đúng lý do: YC-002 mức chặn" sh -c "sh '$CHK' '$F' | grep -q 'YC-002: điểm mù mức \"chặn\"'"
thay "$F/open-questions.md" '`mở`' '`đã trả lời`'
printf -- '- **Trả lời:** qua email\n' >> "$F/open-questions.md"
thay "$F/spec.md" '`[CẦN-HỎI]` → open-questions.md § YC-002' '`[FILE]` open-questions.md § YC-002'
ky_vong 0 "đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec

viet_tdd; thay "$F/spec.md" '`đã duyệt`' '`đề xuất`'
ky_vong 1 "chặn vào design khi người chưa duyệt spec" sh "$CHK" "$F"
dung "…đúng lý do: spec chưa được người duyệt" sh -c "sh '$CHK' '$F' | grep -q 'chưa được người duyệt'"
viet_spec

viet_tdd; thay "$F/spec.md" '`[CẦN-HỎI]` → open-questions.md § YC-002
- Giả định tạm: y' '`[JIRA]` ABC-1'
: > "$F/open-questions.md"
ky_vong 0 "open-questions.md 0 byte không làm design đọc lệch file" sh "$CHK" "$F"
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
dung "…không cảnh báo khi hoãn YC nên có" sh -c "! sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*YC-002: Ưu tiên bắt buộc'"
thay "$F/plan.md" '| YC-002 | chờ BA |' '| YC-002 | chờ BA |
| YC-001 | để sau |'
ky_vong 0 "hoãn YC bắt buộc không chặn" sh "$CHK" "$F"
dung "…nhưng cảnh báo giao thiếu" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*YC-001: Ưu tiên bắt buộc'"
thay "$F/plan.md" '
| YC-001 | để sau |' ''
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

thay "$F/open-questions.md" '`không chặn`' '`chặn review`'; ghi_based_on
ky_vong 0 "điểm mù \"chặn review\" còn mở chỉ CẢNH BÁO ở implement" sh "$CHK" "$F"
dung "…nhưng có in cảnh báo điểm mù" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*YC-002: điểm mù mức \"chặn review\"'"
viet_spec; ghi_based_on

# ---------------------------------------------------------------- ra soat
echo ""
echo "kiem-tra-ra-soat.sh"
CHK="$T/kiem-tra-ra-soat.sh"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

ky_vong 0 "rà soát đủ và đúng thì cho qua" sh "$CHK" "$F"

# Điểm mù: "không chặn" còn mở thì giao được (YC chờ xác nhận); "chặn review" thì không
thay "$F/open-questions.md" '`không chặn`' '`chặn review`'; ghi_based_on
ky_vong 1 "CỔNG CUỐI: chặn điểm mù \"chặn review\" còn mở" sh "$CHK" "$F"
dung "…đúng lý do: điểm mù YC-002" sh -c "sh '$CHK' '$F' | grep -q 'YC-002: điểm mù mức \"chặn review\"'"
thay "$F/open-questions.md" '`mở`' '`đã trả lời`'
printf -- '- **Trả lời:** "đúng như giả định" — PO, 2026-10-04\n' >> "$F/open-questions.md"
thay "$F/spec.md" '`[CẦN-HỎI]` → open-questions.md § YC-002' '`[FILE]` open-questions.md § YC-002'
ghi_based_on
ky_vong 0 "điểm mù \"chặn review\" đã trả lời thì cho qua" sh "$CHK" "$F"
viet_spec; ghi_based_on

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

# Không test nào gắn tag: danh sách dòng tag rỗng không được làm kiểm chéo câm
printf '// chua gan tag\n' > "$R/test/a.test.js"
ky_vong 1 "CỔNG CUỐI: chặn khi CHƯA test nào gắn tag covers" sh "$CHK" "$F"
dung "…đúng lý do: YC chưa có test" sh -c "sh '$CHK' '$F' | grep -q 'YC-002: chưa có test'"
dung "…và implement có in cảnh báo YC chưa có test" sh -c "sh '$T/kiem-tra-hien-thuc.sh' '$F' | grep -q 'CẢNH BÁO.*YC-001'"
printf '// covers: YC-001, YC-002\n' > "$R/test/a.test.js"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

printf '\n<!-- sửa sau khi đã viết spec -->\n' >> "$F/intake.md"
ky_vong 1 "CỔNG CUỐI: chặn spec lỗi thời khi intake.md đổi" sh "$CHK" "$F"
dung "…đúng lý do: spec.md lỗi thời theo intake.md" sh -c "sh '$CHK' '$F' | grep -q 'spec.md: lỗi thời — intake.md'"
viet_intake

printf '\n<!-- sửa sau khi đã có tdd -->\n' >> "$F/spec.md"
ky_vong 1 "CỔNG CUỐI: chặn artifact lỗi thời" sh "$CHK" "$F"
ky_vong 0 "…mà kế hoạch chỉ cảnh báo, không chặn" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_spec; ghi_based_on

rm -f "$F/ket-qua-kiem-thu.md"
ky_vong 1 "chặn khi chưa có ket-qua-kiem-thu.md" sh "$CHK" "$F"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

# ---------------------------------------------------------------- liet ke cau hoi
echo ""
echo "liet-ke-cau-hoi.sh (/open-questions)"
CHK="$T/liet-ke-cau-hoi.sh"
LQ="$TMP/lq"; rm -rf "$LQ"; mkdir -p "$LQ"
cat > "$LQ/spec.md" <<'EOF'
### YC-001 — a
- Ưu tiên: `nên có`
### YC-002 — b
- Ưu tiên: `bắt buộc`
### YC-003 — c
- Ưu tiên: `bắt buộc`
### YC-004 — d
- Ưu tiên: `nên có`
### YC-005 — e
- Ưu tiên: `bắt buộc`
### YC-006 — f
- Ưu tiên: `bắt buộc`
EOF
# Thứ tự trong file cố tình ngược với thứ tự phải giải quyết.
cat > "$LQ/open-questions.md" <<'EOF'
# Điểm mù

## YC-001 — không chặn
- **Chỗ chưa rõ:** hỏi 1
- **Mức chặn:** `không chặn`
- **Trạng thái:** `mở`

## YC-002 — chặn review, bắt buộc, không task
- **Mức chặn:** `chặn review`
- **Trạng thái:** `mở`

## YC-003 — chặn review, bắt buộc, 2 task
- **Mức chặn:** `chặn review`
- **Trạng thái:** `mở`

## YC-004 — chặn, nên có
- **Mức chặn:** `chặn`
- **Trạng thái:** `mở`

## YC-005 — chặn, bắt buộc
- **Hỏi ai:** PO
- **Mức chặn:** `chặn`
- **Trạng thái:** `mở`

## YC-006 — đã trả lời
- **Mức chặn:** `chặn`
- **Trạng thái:** `đã trả lời`
- **Trả lời:** có
EOF
thu_tu() { sh "$CHK" "$LQ" 2>/dev/null | sed -n 's/^  [0-9][0-9]*\. \(YC-[0-9]*\).*/\1/p' | tr '\n' ' '; }
ky_vong 1 "còn điểm mù \"chặn\" mở → ĐANG CHẶN" sh "$CHK" "$LQ"
dung "xếp: chặn → chặn review → không chặn; bắt buộc trước nên có" bang "$(thu_tu)" "YC-005 YC-004 YC-002 YC-003 YC-001 "
printf '### T-01\n- Đứng trên giả định tạm: **có** — `open-questions.md` § YC-003\n### T-02\n- Đứng trên giả định tạm: **có** — § YC-003\n' > "$LQ/plan.md"
dung "cùng mức + cùng ưu tiên: nhiều task đứng trên giả định hơn thì trước" bang "$(thu_tu)" "YC-005 YC-004 YC-003 YC-002 YC-001 "
dung "…in tên task đứng trên giả định" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'Task đứng trên giả định: 2 (T-01 T-02)'"
dung "mục đã trả lời không được liệt kê" sh -c "! sh '$CHK' '$LQ' 2>/dev/null | grep -q 'YC-006'"
dung "mục chặn đánh dấu ĐANG CHẶN phase kế tiếp" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -q 'YC-005.*ĐANG CHẶN /implement'"
dung "khối Kết quả: [x] CÓ ĐIỂM MÙ ĐANG CHẶN" sh -c "sh '$CHK' '$LQ' 2>&1 | grep -q '\[x\] CÓ ĐIỂM MÙ ĐANG CHẶN'"
thay "$LQ/open-questions.md" '`chặn`
- **Trạng thái:** `mở`' '`không chặn`
- **Trạng thái:** `mở`'
ky_vong 3 "chỉ còn chặn review (chưa tới review) + không chặn → chưa chặn" sh "$CHK" "$LQ"
: > "$LQ/ket-qua-kiem-thu.md"
ky_vong 1 "…tới review thì chặn review thành ĐANG CHẶN" sh "$CHK" "$LQ"
rm -f "$LQ/ket-qua-kiem-thu.md"
thay "$LQ/open-questions.md" '`chặn review`' '`toàn bộ thiết kế`'
ky_vong 1 "mức thiếu/sai (nhãn cũ) → CHƯA PHÂN MỨC, đang chặn spec" sh "$CHK" "$LQ"
dung "…xếp lên đầu" sh -c "sh '$CHK' '$LQ' 2>/dev/null | grep -A1 '^\[CHƯA PHÂN MỨC\]' | grep -q '1\. YC-00'"
printf '# Điểm mù\n\nKhông có điểm mù.\n' > "$LQ/open-questions.md"
ky_vong 0 "không còn điểm mù mở" sh "$CHK" "$LQ"
: > "$LQ/open-questions.md"
ky_vong 0 "open-questions.md 0 byte không làm đọc lệch file" sh "$CHK" "$LQ"
rm -f "$LQ/open-questions.md"
ky_vong 2 "thiếu open-questions.md → THIẾU ĐẦU VÀO" sh "$CHK" "$LQ"
tao_fixture
ky_vong 3 "fixture: chỉ có điểm mù không chặn" sh "$CHK" "$F"

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
for f in commands/intake.md commands/spec.md commands/design.md commands/plan.md commands/implement.md commands/review.md \
         commands/import.md commands/open-questions.md agents/ra-soat-doc-lap.md agents/soat-thiet-ke.md skills/quy-trinh-agent/SKILL.md; do
  [ -f "$O/.claude/$f" ] || { du=0; echo "        thiếu .claude/$f"; }
done
[ -f "$O/.claude/commands/ship.md" ] && du=0
dung "sinh đúng bộ file, bỏ qua phase chưa hiện thực" test "$du" = 1
dung "command có bước xác định feature" grep -q 'xac-dinh-feature.sh \$ARGUMENTS' "$O/.claude/commands/design.md"
dung "command design gọi checker LLM" grep -q 'soat-thiet-ke' "$O/.claude/commands/design.md"
dung "lệnh /open-questions có bước xác định feature + chạy liet-ke-cau-hoi.sh" sh -c \
  "grep -q 'xac-dinh-feature.sh \$ARGUMENTS' '$O/.claude/commands/open-questions.md' && grep -q 'liet-ke-cau-hoi.sh' '$O/.claude/commands/open-questions.md'"
dung "lệnh /import giữ argument-hint riêng" grep -q 'argument-hint: <file-nguồn>' "$O/.claude/commands/import.md"
dung "skill liệt kê lệnh tiện ích" grep -q '/open-questions' "$O/.claude/skills/quy-trinh-agent/SKILL.md"

printf '# tôi tự viết\n' > "$O/.claude/commands/spec.md"
ky_vong 3 "từ chối ghi đè file người viết tay" sh "$BUILD" --out "$O"
dung "nội dung người viết còn nguyên" sh -c "head -1 '$O/.claude/commands/spec.md' | grep -q 'tôi tự viết'"
ky_vong 0 "--force thì cho phép ghi đè" sh "$BUILD" --out "$O" --force

# lenh do lan cai truoc sinh ra ma nay khong con (vd /ideation -> /intake)
printf -- '---\n---\n> **File này được SINH TỰ ĐỘNG** từ `workflow/phases/00-ideation.md`\n' > "$O/.claude/commands/ideation.md"
printf '# lệnh tôi tự viết\n' > "$O/.claude/commands/cua-toi.md"
sh "$BUILD" --out "$O" >/dev/null 2>&1
dung "cài lại xoá lệnh sinh tự động không còn trong manifest" test ! -f "$O/.claude/commands/ideation.md"
dung "…nhưng giữ lệnh người viết tay" test -f "$O/.claude/commands/cua-toi.md"

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

tao_fake
thay "$FAKE/workflow/phases/00-intake.md" 'arguments: input' 'arguments: gi-cung-duoc'
ky_vong 4 "từ chối build khi arguments không phải \"input\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out5"

tao_fake
rm -f "$FAKE/workflow/open-questions.md"
ky_vong 4 "từ chối build khi mục commands: trỏ tới file không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out6"

tao_fake
thay "$FAKE/workflow/import.md" 'arguments: mixed' 'arguments: input'
ky_vong 4 "từ chối build khi lệnh tiện ích khai arguments khác \"mixed\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out7"

# ---------------------------------------------------------------- cai dat
echo ""
echo "tools/cai-dat.sh"
R4="$TMP/repo4"; mkdir -p "$R4"
git -C "$R4" init -q
git -C "$R4" checkout -q -b main
ky_vong 0 "cài vào repo đích thành công" sh "$T/cai-dat.sh" "$R4" --lenh-kiem-thu "true"
QT4="$R4/.agent-workflow/.quy-trinh"
dung "chép bộ cài, checker LLM, công cụ và ghi cấu hình" sh -c \
  "[ -f '$QT4/tools/kiem-tra-thiet-ke.sh' ] && [ -f '$QT4/tools/lib/kiem-cheo.sh' ] && [ -f '$QT4/checkers/thiet-ke.md' ] && [ -f '$QT4/tools/xac-dinh-feature.sh' ] && [ -f '$QT4/tools/liet-ke-cau-hoi.sh' ] && grep -q 'LENH_KIEM_THU=\"true\"' '$QT4/cau-hinh.sh'"
dung "tạo conventions.md từ mẫu" grep -q '^mau_branch:' "$R4/.agent-workflow/conventions.md"

printf 'LENH_KIEM_THU="npm test"\n' > "$QT4/cau-hinh.sh"
printf '# của tôi\n```conventions\nmau_branch: job-*\n```\n' > "$R4/.agent-workflow/conventions.md"
sh "$T/cai-dat.sh" "$R4" >/dev/null 2>&1
dung "cài lại KHÔNG ghi đè cấu hình người sửa" grep -q 'npm test' "$QT4/cau-hinh.sh"
sh "$T/cai-dat.sh" "$R4" --force >/dev/null 2>&1
dung "KHÔNG ghi đè conventions.md, kể cả --force" grep -q 'của tôi' "$R4/.agent-workflow/conventions.md"

ky_vong 2 "từ chối cài vào chính repo agent-workflow" sh "$T/cai-dat.sh" "$ROOT"
ky_vong 2 "từ chối cài vào thư mục con của repo agent-workflow" sh "$T/cai-dat.sh" "$ROOT/adapters"
ky_vong 2 "build.sh từ chối --out nằm trong repo agent-workflow" sh "$BUILD" --out "$ROOT/adapters"

# ---------------------------------------------------------------- dong bo
echo ""
echo "tools/dong-bo.sh"
# Nguon: ban chep repo nay (ca thay doi chua commit) thanh mot repo git rieng.
SRC="$TMP/nguon"; mkdir -p "$SRC"
(cd "$ROOT" && tar cf - --exclude=.git .) | (cd "$SRC" && tar xf -)
gs() { git -C "$SRC" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
gs init -q; gs checkout -q -b main; gs add -A; gs commit -q -m v1
R6="$TMP/repo6"; mkdir -p "$R6"
git -C "$R6" init -q; git -C "$R6" checkout -q -b main
sh "$SRC/tools/cai-dat.sh" "$R6" --lenh-kiem-thu true >/dev/null 2>&1
QT6="$R6/.agent-workflow/.quy-trinh"; DB="$QT6/tools/dong-bo.sh"
dung "cài ghi nguon.txt: nguồn, nhánh, commit" sh -c \
  "grep -qx 'url=$SRC' '$QT6/nguon.txt' && grep -qx 'nhanh=main' '$QT6/nguon.txt' && grep -qx \"commit=\$(git -C '$SRC' rev-parse HEAD)\" '$QT6/nguon.txt'"
mkdir -p "$TMP/repo6b"; git -C "$TMP/repo6b" init -q
sh "$SRC/tools/cai-dat.sh" "$TMP/repo6b" --nguon 'https://u:bi-mat@example.com/x.git' >/dev/null 2>&1
dung "nguon.txt bỏ user:token trong URL" sh -c \
  "grep -qx 'url=https://example.com/x.git' '$TMP/repo6b/.agent-workflow/.quy-trinh/nguon.txt'"
g6() { git -C "$R6" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
g6 add -A; g6 commit -q -m cai

ky_vong 0 "--kiem-tra: đã mới nhất → 0" sh "$DB" --kiem-tra
printf '# luật mới\n' > "$SRC/workflow/rules/luat-moi.md"; gs add -A; gs commit -q -m v2
ky_vong 1 "--kiem-tra: nguồn có commit mới → 1" sh "$DB" --kiem-tra
dung "--kiem-tra không đổi gì trong repo đích" sh -c "[ -z \"\$(git -C '$R6' status --porcelain)\" ]"

printf 'x\n' >> "$QT6/rules/nguyen-tac-chung.md"
ky_vong 7 "chặn khi bộ cài có thay đổi chưa commit" sh "$DB"
git -C "$R6" checkout -q -- .
W9="$TMP/repo6.wt/feat_x"; git -C "$R6" worktree add -q -b feat_x "$W9" main
ky_vong 7 "chặn khi chạy trong worktree" sh "$W9/.agent-workflow/.quy-trinh/tools/dong-bo.sh"

printf 'LENH_KIEM_THU="make test"\n' > "$QT6/cau-hinh.sh"; g6 commit -q -am cau-hinh
ky_vong 0 "đồng bộ thành công" sh "$DB"
dung "kéo về file mới của nguồn" test -f "$QT6/rules/luat-moi.md"
dung "nguon.txt ghi commit mới, giữ url" sh -c \
  "grep -qx \"commit=\$(git -C '$SRC' rev-parse HEAD)\" '$QT6/nguon.txt' && grep -qx 'url=$SRC' '$QT6/nguon.txt'"
dung "giữ cau-hinh.sh của người" grep -q 'make test' "$QT6/cau-hinh.sh"
g6 add -A; g6 commit -q -m dong-bo
ky_vong 0 "chạy lại khi đã mới nhất → 0" sh "$DB"
dung "…và không đổi gì" sh -c "[ -z \"\$(git -C '$R6' status --porcelain)\" ]"

gs rm -q workflow/rules/luat-moi.md; gs commit -q -m v3
sh "$DB" >/dev/null 2>&1
dung "xoá file mà nguồn đã bỏ" test ! -e "$QT6/rules/luat-moi.md"
ky_vong 2 "thiếu nguon.txt và không có --nguon → 2" sh -c "rm -f '$QT6/nguon.txt' && sh '$DB'"

# ---------------------------------------------------------------- xac dinh feature
echo ""
echo "xac-dinh-feature.sh"
g4() { git -C "$R4" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
g4 commit -q --allow-empty -m truoc-cai
g4 tag truoc-cai
XD="$QT4/tools/xac-dinh-feature.sh"
ky_vong 6 "checkout chính → ĐANG Ở CHECKOUT CHÍNH (worktree bắt buộc)" sh "$XD"
ky_vong 6 "…kể cả khi có tham số" sh "$XD" feat_abc
dung "…và in danh sách việc cần làm: mở worktree / chạy /intake" sh -c "sh '$XD' 2>&1 | grep -q 'CHECKOUT CHÍNH'"

# worktree chỉ có file đã commit: commit bộ cài trước
g4 add -A; g4 commit -q -m bo-cai
W4="$TMP/repo4.wt/khong-khop"
g4 worktree add -q -b khong-khop "$W4" main
XDW="$W4/.agent-workflow/.quy-trinh/tools/xac-dinh-feature.sh"
ky_vong 3 "trong worktree, branch không khớp, không tham số → CẦN HỎI NGƯỜI" sh "$XDW"
dung "branch không khớp → lấy tham số" test "$(sh "$XDW" feat_abc 2>/dev/null)" = ".agent-workflow/feat_abc"
ky_vong 2 "từ chối tên feature có ../" sh "$XDW" "../x"
git -C "$W4" checkout -q -b job-them-todo
dung "branch khớp quy ước → tên branch đầy đủ" test "$(sh "$XDW" 2>/dev/null)" = ".agent-workflow/job-them-todo"
dung "branch khớp thì thắng tham số" test "$(sh "$XDW" khac 2>/dev/null)" = ".agent-workflow/job-them-todo"
dung "in 'Đang làm với:'" sh -c "sh '$XDW' 2>&1 >/dev/null | grep -q 'Đang làm với: .agent-workflow/job-them-todo'"
g4 worktree remove --force "$W4"

# ---------------------------------------------------------------- tao worktree (/intake)
echo ""
echo "tao-worktree.sh"
TW="$QT4/tools/tao-worktree.sh"
cp "$ROOT/workflow/templates/conventions.md" "$R4/.agent-workflow/conventions.md"
thay "$R4/.agent-workflow/conventions.md" 'mau_nhanh_phat_hanh:' 'mau_nhanh_phat_hanh: release/*'
g4 add -A; g4 commit -q -m conventions
g4 branch release/1.2
DX=$(sh "$TW" bugfix phi-hoan-tien 2>/dev/null)
dung "đề xuất tên theo tiền tố của loại việc" sh -c "printf '%s' \"\$1\" | grep -q 'Tên        fix_phi-hoan-tien'" _ "$DX"
dung "…đường dẫn theo thu_muc_worktree (ngoài repo)" sh -c "printf '%s' \"\$1\" | grep -qF '$TMP/repo4.wt/fix_phi-hoan-tien'" _ "$DX"
dung "…liệt kê nhánh phát hành làm ứng viên base" sh -c "printf '%s' \"\$1\" | grep -q 'release/1.2'" _ "$DX"
dung "…gợi ý ★ nhanh_goc khi không có remote" sh -c "printf '%s' \"\$1\" | grep -q '★ \[1\] main'" _ "$DX"
dung "…chỉ đề xuất: chưa tạo branch, chưa tạo worktree" sh -c "! git -C '$R4' rev-parse --verify --quiet refs/heads/fix_phi-hoan-tien && [ ! -e '$TMP/repo4.wt/fix_phi-hoan-tien' ]"
ky_vong 2 "từ chối loại việc không có tiền tố" sh "$TW" utils x
ky_vong 2 "từ chối mô tả không phải chữ thường ASCII" sh "$TW" bugfix "Phi Hoan"
ky_vong 2 "--tao thiếu --goc → từ chối (agent không tự chọn base)" sh "$TW" bugfix phi-hoan-tien --tao
ky_vong 2 "từ chối base chưa có bộ cài" sh "$TW" bugfix phi-hoan-tien --tao --goc truoc-cai
ky_vong 2 "từ chối ref không tồn tại" sh "$TW" bugfix phi-hoan-tien --tao --goc khong-co
AW_THU_MUC_WORKTREE='.worktrees/{ten}' ky_vong 2 "từ chối worktree nằm trong repo" sh "$TW" bugfix phi-hoan-tien
dung "AW_THU_MUC_WORKTREE ghi đè vị trí theo máy" sh -c "AW_THU_MUC_WORKTREE='$TMP/rieng/{repo}/{ten}' sh '$TW' bugfix phi-hoan-tien 2>/dev/null | grep -qF '$TMP/rieng/repo4/fix_phi-hoan-tien'"

ky_vong 0 "--tao --goc <ref người chọn> thì tạo worktree" sh "$TW" bugfix phi-hoan-tien --tao --goc main
W5="$TMP/repo4.wt/fix_phi-hoan-tien"
dung "…worktree ở đúng chỗ, đúng branch" test "$(git -C "$W5" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "fix_phi-hoan-tien"
dung "…branch không có upstream (git push trơn không đẩy lên nhánh gốc)" sh -c "! git -C '$W5' rev-parse --abbrev-ref '@{upstream}' 2>/dev/null"
dung "…checkout chính vẫn đứng ở main" test "$(git -C "$R4" rev-parse --abbrev-ref HEAD)" = "main"
dung "…in dòng Base để chép vào intake.md" sh -c "sh '$TW' chore in-base --tao --goc main 2>&1 >/dev/null | grep -q '\*\*Base:\*\* \`main\` @ \`'"
dung "…và xac-dinh-feature trong worktree suy được feature" test "$(sh "$W5/.agent-workflow/.quy-trinh/tools/xac-dinh-feature.sh" 2>/dev/null)" = ".agent-workflow/fix_phi-hoan-tien"
ky_vong 5 "chạy lại cho việc đã có worktree → ĐÃ CÓ WORKTREE, không tạo gì" sh "$TW" bugfix phi-hoan-tien
dung "…stdout là đường dẫn worktree đã có" test "$(sh "$TW" bugfix phi-hoan-tien 2>/dev/null)" = "$W5"

# remote: main local chậm hơn origin/main -> ★ origin/main
RM="$TMP/remote4.git"; git init -q --bare "$RM"
g4 remote add origin "$RM"; g4 push -q origin main
KH="$TMP/khac4"; git clone -q -b main "$RM" "$KH" 2>/dev/null
git -C "$KH" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "cua dong nghiep" && git -C "$KH" push -q origin HEAD:main 2>/dev/null
g4 fetch -q origin
DX=$(sh "$TW" feature co-remote 2>/dev/null)
dung "main chậm origin/main → ★ gợi ý origin/main" sh -c "printf '%s' \"\$1\" | grep -q '★ \[2\] origin/main'" _ "$DX"
dung "…và ghi rõ main chậm bao nhiêu commit" sh -c "printf '%s' \"\$1\" | grep -q 'chậm 1 commit so với origin/main'" _ "$DX"
g4 commit -q --allow-empty -m "local chua push"
dung "main và origin/main phân kỳ → không gợi ý ★" sh -c "sh '$TW' feature co-remote 2>/dev/null | grep -q 'PHÂN KỲ' && ! sh '$TW' feature co-remote 2>/dev/null | grep -q '★ \['"
g4 reset -q --hard HEAD~1

# ---------------------------------------------------------------- don worktree
echo ""
echo "don-worktree.sh"
DW="$QT4/tools/don-worktree.sh"
ky_vong 0 "không --xoa: chỉ in trạng thái" sh "$DW" fix_phi-hoan-tien
dung "…worktree còn nguyên" test -d "$W5"
printf 'nhap\n' > "$W5/nhap.txt"
ky_vong 7 "còn file chưa track → chặn --xoa" sh "$DW" fix_phi-hoan-tien --xoa
dung "…worktree còn nguyên" test -f "$W5/nhap.txt"
rm -f "$W5/nhap.txt"
ky_vong 7 "đứng trong chính worktree cần dọn → chặn" sh -c "cd '$W5' && sh '$DW' fix_phi-hoan-tien --xoa"
ky_vong 2 "--ca-branch không kèm --xoa → sai tham số" sh "$DW" fix_phi-hoan-tien --ca-branch
ky_vong 2 "branch không có worktree → sai tham số" sh "$DW" release/1.2
git -C "$W5" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "sua phi"
ky_vong 7 "chưa merge: gỡ worktree nhưng git từ chối xoá branch" sh "$DW" fix_phi-hoan-tien --xoa --ca-branch
dung "…worktree đã gỡ, branch còn nguyên (không mất commit)" sh -c "[ ! -e '$W5' ] && git -C '$R4' rev-parse --verify --quiet refs/heads/fix_phi-hoan-tien"
W6="$TMP/repo4.wt/chore_in-base"
ky_vong 0 "đã merge: --xoa --ca-branch gỡ worktree và xoá branch" sh "$DW" chore_in-base --xoa --ca-branch
dung "…cả worktree lẫn branch đều không còn" sh -c "[ ! -e '$W6' ] && ! git -C '$R4' rev-parse --verify --quiet refs/heads/chore_in-base"

IN="$R4/.claude/commands/intake.md"
dung "/intake: tham số là input, không truyền vào xac-dinh-feature" sh -c "grep -q 'argument-hint: \[mã-issue' '$IN' && ! grep -q 'xac-dinh-feature.sh \$ARGUMENTS' '$IN'"
dung "/intake: đang ở checkout chính thì dẫn tới tao-worktree.sh" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*tao-worktree.sh' "$IN"
dung "lệnh khác: ĐANG Ở CHECKOUT CHÍNH thì dừng lại" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*dừng lại' "$R4/.claude/commands/spec.md"
dung "lệnh khác vẫn nhận tên feature qua tham số" grep -q 'xac-dinh-feature.sh \$ARGUMENTS' "$R4/.claude/commands/spec.md"
dung "/intake: tham số đi qua phan-loai-input.sh bằng heredoc nguyên văn" sh -c "grep -q 'phan-loai-input.sh .*- <<' '$IN' && grep -qx '\$ARGUMENTS' '$IN'"

# ---------------------------------------------------------------- phan loai input (/intake)
echo ""
echo "phan-loai-input.sh"
PL="$QT4/tools/phan-loai-input.sh"
mkdir -p "$R4/docs"; printf 'x\n' > "$R4/docs/a.md"
# ra <tham-số...> -> stdout của script (bỏ stderr); ma <tham-số...> -> mã thoát
ra() { sh "$PL" "$@" 2>/dev/null; }
loi() { sh "$PL" "$@" 2>&1 >/dev/null; }
BT='`'

ky_vong 0 "mã Jira + file có thật → nguồn" sh "$PL" "ABC-123 docs/a.md"
dung "…đúng nhãn [JIRA] và [FILE]" bang "$(ra 'ABC-123 docs/a.md')" "- ${BT}[JIRA]${BT} ABC-123
- ${BT}[FILE]${BT} docs/a.md"
dung "URL …/browse/<mã> → [JIRA] với mã tách ra" bang "$(ra 'https://x.atlassian.net/browse/ABC-9')" "- ${BT}[JIRA]${BT} ABC-9 — https://x.atlassian.net/browse/ABC-9"
dung "chưa khai mien_confluence: URL khác → [CONFLUENCE]" bang "$(ra 'https://wiki.co/p/1')" "- ${BT}[CONFLUENCE]${BT} https://wiki.co/p/1"
dung "…kèm cảnh báo chưa khai mien_confluence" sh -c "sh '$PL' 'https://wiki.co/p/1' 2>&1 >/dev/null | grep -q mien_confluence"
dung "bỏ dấu câu / ngoặc bọc ngoài: (ABC-1), \`docs/a.md\`" bang "$(ra '(ABC-1), `docs/a.md`.')" "- ${BT}[JIRA]${BT} ABC-1
- ${BT}[FILE]${BT} docs/a.md"
dung "cùng một nguồn gõ nhiều cách → một dòng" bang "$(ra 'ABC-1 ABC-1 https://x.atlassian.net/browse/ABC-1' | wc -l | tr -d ' ')" 1
ky_vong 1 "đường dẫn không tồn tại → ĐƯỜNG DẪN KHÔNG TỒN TẠI (không tự đoán)" sh "$PL" "ABC-1 docs/khong-co.md"
dung "…và không in dòng input nào" test -z "$(ra 'ABC-1 docs/khong-co.md')"
ky_vong 3 "không có tham số → KHÔNG CÓ THAM SỐ (hỏi người dùng)" sh "$PL" ""
ky_vong 3 "tham số chỉ có khoảng trắng / dòng trống → KHÔNG CÓ THAM SỐ" sh "$PL" "
  "
ky_vong 4 "câu chữ tự do → LỜI NGƯỜI DÙNG" sh "$PL" "sửa phí hoàn tiền bị âm ABC-123"
dung "…cả chuỗi là MỘT mục [NGƯỜI-DÙNG] nguyên văn" bang "$(ra 'sửa phí hoàn tiền bị âm ABC-123')" "- ${BT}[NGƯỜI-DÙNG]${BT}
  > sửa phí hoàn tiền bị âm ABC-123"
dung "…mã Jira trong câu chỉ là ĐỀ XUẤT (stderr)" sh -c "sh '$PL' 'sửa phí hoàn tiền bị âm ABC-123' 2>&1 >/dev/null | grep -A3 'Đề xuất tách thêm' | grep -q 'ABC-123'"
ky_vong 4 "đường dẫn không có file nằm trong câu chữ thì không chặn" sh "$PL" "sửa lỗi trong src/khong-co.js"

cp "$R4/.agent-workflow/conventions.md" "$TMP/conv.bak"
sed 's#^mien_confluence:.*#mien_confluence: *.atlassian.net/wiki#' "$TMP/conv.bak" > "$R4/.agent-workflow/conventions.md"
dung "khai mien_confluence: URL khớp → [CONFLUENCE]" bang "$(ra 'https://x.atlassian.net/wiki/spaces/A/pages/1')" "- ${BT}[CONFLUENCE]${BT} https://x.atlassian.net/wiki/spaces/A/pages/1"
ky_vong 4 "khai mien_confluence: URL lạ → lời người dùng" sh "$PL" "https://github.com/a/b"
ky_vong 4 "khai mien_confluence: miền giả mạo x.atlassian.net.evil.com → không nhận" sh "$PL" "https://x.atlassian.net.evil.com/wiki/p/1"
dung "khai mien_confluence: URL có query vẫn khớp" bang "$(ra 'https://x.atlassian.net/wiki?p=1')" "- ${BT}[CONFLUENCE]${BT} https://x.atlassian.net/wiki?p=1"
printf '%s\n' '```conventions' 'mau_branch: feat_*' '```' > "$R4/.agent-workflow/conventions.md"
ky_vong 0 "conventions.md cũ chưa có mau_jira → dùng mặc định" sh "$PL" "ABC-1"
cp "$TMP/conv.bak" "$R4/.agent-workflow/conventions.md"

# nguyen van qua stdin: dau nhay, $, backtick, nhieu dong khong bi shell dien giai
sh "$PL" - > "$TMP/nv.out" 2>/dev/null <<'HET_INPUT'

Sửa "phí" khi $amount < 0 — xem `x`
dòng hai
HET_INPUT
dung "stdin: nguyên văn giữ dấu nháy, \$, backtick, nhiều dòng" bang "$(cat "$TMP/nv.out")" "- ${BT}[NGƯỜI-DÙNG]${BT}
  > Sửa \"phí\" khi \$amount < 0 — xem ${BT}x${BT}
  > dòng hai"

# --tru: chay lai /intake = gop them
cat > "$TMP/intake-cu.md" <<'HET'
- **Loại việc:** `feature`
- **Mục tiêu:** x

## Input

- `[JIRA]` [ABC-123](https://x.atlassian.net/browse/ABC-123)
- `[FILE]` ./docs/a.md
- `[NGƯỜI-DÙNG]`
  > sửa phí   hoàn tiền
  > bị âm
HET
dung "--tru: bỏ input đã có, chỉ in input mới" bang "$(ra --tru "$TMP/intake-cu.md" 'ABC-123 docs/a.md ABC-7')" "- ${BT}[JIRA]${BT} ABC-7"
ky_vong 0 "--tru: không có gì mới vẫn là NGUỒN" sh "$PL" --tru "$TMP/intake-cu.md" "https://x.atlassian.net/browse/ABC-123"
dung "…URL …/browse/ABC-123 trùng với ABC-123 đã có → stdout rỗng" test -z "$(ra --tru "$TMP/intake-cu.md" 'https://x.atlassian.net/browse/ABC-123')"
dung "--tru: lời người dùng đã có (khác khoảng trắng / xuống dòng) → bỏ" test -z "$(ra --tru "$TMP/intake-cu.md" 'sửa phí hoàn tiền bị âm')"
dung "--tru: lời người dùng mới thì vẫn in" bang "$(ra --tru "$TMP/intake-cu.md" 'thêm xuất CSV' | tail -1)" "  > thêm xuất CSV"
ky_vong 2 "--tru trỏ tới file không có → SAI CÁCH GỌI" sh "$PL" --tru "$TMP/khong-co.md" "ABC-1"


# ---------------------------------------------------------------- muc dich (00)
echo ""
echo "kiem-tra-tiep-nhan.sh"
CHK="$T/kiem-tra-tiep-nhan.sh"
tao_fixture feature feat_x

ky_vong 0 "tiếp nhận hợp lệ thì cho qua" sh "$CHK" "$F"

thay "$F/intake.md" '`feature`' '`utils`'
ky_vong 1 "chặn loại việc ngoài 5 loại" sh "$CHK" "$F"
ky_vong 1 "spec chặn khi intake.md không đạt (entry check)" sh "$T/kiem-tra-truy-vet.sh" "$F"
viet_intake

thay "$F/intake.md" '- **Mục tiêu:** làm x' '- **Mục tiêu:** <một câu>'
ky_vong 1 "chặn mục tiêu còn chỗ giữ chỗ" sh "$CHK" "$F"
viet_intake

thay "$F/intake.md" '- `[JIRA]` ABC-1
- `[NGƯỜI-DÙNG]`
  > cần làm x cho màn hình y
' ''
ky_vong 1 "chặn khi không có input nào" sh "$CHK" "$F"
viet_intake

thay "$F/intake.md" '`[JIRA]` ABC-1' '`[SUY-RA]` chắc người dùng muốn x'
ky_vong 1 "chặn [SUY-RA] trong input" sh "$CHK" "$F"
viet_intake

thay "$F/intake.md" '  > cần làm x cho màn hình y' ''
ky_vong 1 "chặn [NGƯỜI-DÙNG] không kèm nguyên văn" sh "$CHK" "$F"
viet_intake

rm -f "$F/intake.md"
ky_vong 2 "chặn khi chưa có intake.md" sh "$CHK" "$F"
viet_intake

# mau chua sua: dong input vi du khong duoc thanh mot nguon gia
cp "$ROOT/workflow/templates/intake.md" "$F/intake.md"
thay "$F/intake.md" '`<feature | bugfix | refactor | perf | chore>`' '`feature`'
thay "$F/intake.md" '<một câu>' 'làm x'
thay "$F/intake.md" '  > <chép nguyên văn lời người dùng>' '  > cần làm x'
ky_vong 1 "chặn dòng input mẫu chưa sửa (nguồn giả)" sh "$CHK" "$F"
dung "…đúng lý do: chỗ giữ chỗ" sh -c "sh '$CHK' '$F' | grep -q 'chỗ giữ chỗ'"
viet_intake

thay "$F/intake.md" '`[JIRA]` ABC-1' '`[JIRA]` abc'
ky_vong 1 "chặn [JIRA] không có mã khớp mau_jira" sh "$CHK" "$F"
viet_intake
thay "$F/intake.md" '`[JIRA]` ABC-1' '`[JIRA]` [ABC-1](https://x.atlassian.net/browse/ABC-1)'
ky_vong 0 "[JIRA] dạng link markdown có mã thì cho qua" sh "$CHK" "$F"
viet_intake

# spec ghi based_on intake.md: gop them input -> spec loi thoi, review chan
sh "$T/cap-nhat-based-on.sh" "$F" spec.md intake.md >/dev/null
ky_vong 0 "spec ghi based_on intake.md vẫn qua kiem-tra-truy-vet" sh "$T/kiem-tra-truy-vet.sh" "$F"
printf -- '- `[JIRA]` ABC-2\n' >> "$F/intake.md"
ky_vong 1 "gộp thêm input sau khi có spec → review chặn (spec lỗi thời)" sh "$T/kiem-tra-ra-soat.sh" "$F"
dung "…đúng lý do: spec.md lỗi thời vì intake.md" sh -c "sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'spec.md: lỗi thời — intake.md'"
viet_intake; viet_spec

thay "$F/intake.md" '`feature`' '`chore`'
ky_vong 0 "loại lệch tiền tố branch chỉ CẢNH BÁO ở /intake" sh "$CHK" "$F"
dung "…và có in cảnh báo lệch tiền tố" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*feat_'"
viet_intake

# Base: dong do tao-worktree.sh in ra, checker phia sau so diff voi no
SHA_MAIN=$(git -C "$R" rev-parse --short main)
thay "$F/intake.md" "- **Base:** \`main\` @ \`$SHA_MAIN\`
" ''
ky_vong 1 "chặn khi thiếu dòng Base" sh "$CHK" "$F"
dung "…đúng lý do: thiếu Base" sh -c "sh '$CHK' '$F' | grep -q 'Thiếu dòng .*Base'"
viet_intake
thay "$F/intake.md" "@ \`$SHA_MAIN\`" '@ `khongphaisha`'
ky_vong 1 "chặn Base có sha không phải commit" sh "$CHK" "$F"
viet_intake
g checkout -q -b nhanh-khac main; g commit -q --allow-empty -m khac; SHA_KHAC=$(git -C "$R" rev-parse --short HEAD); g checkout -q feat_x
thay "$F/intake.md" "@ \`$SHA_MAIN\`" "@ \`$SHA_KHAC\`"
ky_vong 1 "chặn Base có sha không phải tổ tiên của HEAD" sh "$CHK" "$F"
viet_intake
thay "$F/intake.md" "\`main\` @" '`da-xoa` @'
ky_vong 0 "ref của Base không còn nhưng sha đúng → chỉ cảnh báo" sh "$CHK" "$F"
dung "…và có in cảnh báo ref không còn" sh -c "sh '$CHK' '$F' | grep -q 'CẢNH BÁO.*da-xoa.*không còn'"
viet_intake

# Base khac nhanh goc: so voi main thi commit cua nguoi khac bi tinh cho viec nay
g checkout -q -b moi-hon main
printf 'x\n' > "$R/docs/cua-nguoi-khac.txt"; g add docs/cua-nguoi-khac.txt; g commit -q -m "cua nguoi khac"
g checkout -q feat_x; g merge -q --no-edit moi-hon
ky_vong 1 "base ghi main mà branch tạo từ bản mới hơn → review thấy file của người khác" sh "$T/kiem-tra-ra-soat.sh" "$F"
dung "…đúng lý do: file của người khác bị tính ngoài phạm vi" sh -c "sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'docs/cua-nguoi-khac.txt: thay đổi ngoài phạm vi'"
SHA_MH=$(git -C "$R" rev-parse --short moi-hon)
thay "$F/intake.md" "\`main\` @ \`$SHA_MAIN\`" "\`moi-hon\` @ \`$SHA_MH\`"
ghi_based_on
ky_vong 0 "ghi đúng base → diff chỉ còn việc của mình, review cho qua" sh "$T/kiem-tra-ra-soat.sh" "$F"
dung "…nhưng base lạ (xếp chồng) thì review CẢNH BÁO" sh -c "sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'CẢNH BÁO.*Base \"moi-hon\"'"
thay "$R/.agent-workflow/conventions.md" 'mau_nhanh_phat_hanh:' 'mau_nhanh_phat_hanh: moi-*'
dung "base khớp mau_nhanh_phat_hanh → không cảnh báo" sh -c "! sh '$T/kiem-tra-ra-soat.sh' '$F' | grep -q 'CẢNH BÁO.*Base'"
thay "$R/.agent-workflow/conventions.md" 'mau_nhanh_phat_hanh: moi-*' 'mau_nhanh_phat_hanh:'

# ---------------------------------------------------------------- bugfix
echo ""
echo "loại việc: bugfix"
tao_fixture bugfix fix_y
for c in tiep-nhan truy-vet thiet-ke ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "bugfix đầy đủ qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done
dung "tai-hien.md ghi output THẬT, mã thoát khác 0" sh -c "grep -q 'Mã thoát: \`1\`' '$F/tai-hien.md'"

ky_vong 1 "kiem-tra-tai-hien từ chối khi đã sửa code production" sh "$T/kiem-tra-tai-hien.sh" "$F"
dung "…và giữ nguyên tai-hien.md cũ" grep -q 'Mã thoát: `1`' "$F/tai-hien.md"

thay "$F/spec.md" '- Hành vi đúng: ra moi' ''
ky_vong 1 "spec bugfix chặn khi thiếu Hành vi đúng" sh "$T/kiem-tra-truy-vet.sh" "$F"
viet_spec; ghi_based_on

mv "$F/tai-hien.md" "$F/tai-hien.bak"
ky_vong 1 "implement chặn bugfix không có tai-hien.md" sh "$T/kiem-tra-hien-thuc.sh" "$F"
ky_vong 1 "review chặn bugfix không có tai-hien.md" sh "$T/kiem-tra-ra-soat.sh" "$F"
mv "$F/tai-hien.bak" "$F/tai-hien.md"
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

viet_review; thay "$F/review.md" '- Test tái hiện đỏ vì: grep không thấy "moi" trong src/a.txt' '- Test tái hiện đỏ vì: <trích>'
ky_vong 1 "review chặn bugfix thiếu \"Test tái hiện đỏ vì\"" sh "$T/kiem-tra-ra-soat.sh" "$F"
viet_review

# test xanh tren code chua sua -> khong tai hien duoc
g stash -q
printf 'LENH_KIEM_THU="true"\n' > "$R/.agent-workflow/.quy-trinh/cau-hinh.sh"
ky_vong 1 "kiem-tra-tai-hien chặn khi test XANH trên code chưa sửa" sh "$T/kiem-tra-tai-hien.sh" "$F"
dung "…đúng lý do: test xanh, không phải vì đã sửa code" sh -c "sh '$T/kiem-tra-tai-hien.sh' '$F' | grep -q 'XANH'"

# ---------------------------------------------------------------- refactor
echo ""
echo "loại việc: refactor"
tao_fixture refactor refactor_z
for c in truy-vet thiet-ke ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "refactor đầy đủ qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done

thay "$F/spec.md" '- Loại YC: `cấu trúc`' ''
ky_vong 1 "spec refactor chặn YC không có Loại YC (hành vi mới)" sh "$T/kiem-tra-truy-vet.sh" "$F"
viet_spec

thay "$F/spec.md" '`test/a.test.js`' '`test/moi.test.js`'
printf '// covers: YC-001\n' > "$R/test/moi.test.js"
ky_vong 1 "spec refactor chặn test bảo vệ không có sẵn trên nhánh gốc" sh "$T/kiem-tra-truy-vet.sh" "$F"
rm -f "$R/test/moi.test.js"; viet_spec; ghi_based_on

printf '// covers: YC-001, YC-002\n// doi import\n' > "$R/test/a.test.js"
ky_vong 0 "sửa test cũ chưa khai chỉ CẢNH BÁO ở implement" sh "$T/kiem-tra-hien-thuc.sh" "$F"
ky_vong 1 "…nhưng review chặn" sh "$T/kiem-tra-ra-soat.sh" "$F"
thay "$F/plan.md" '| File test | Lý do sửa |
|---|---|
' '| File test | Lý do sửa |
|---|---|
| `test/a.test.js` | đổi import do dời module |
'
ky_vong 0 "khai ở \"Test cũ bị sửa\" thì review cho qua" sh "$T/kiem-tra-ra-soat.sh" "$F"
g checkout -q -- test/a.test.js; viet_plan; ghi_based_on

rm -f "$R/test/a.test.js"
ky_vong 1 "implement chặn refactor XOÁ test cũ" sh "$T/kiem-tra-hien-thuc.sh" "$F"
g checkout -q -- test/a.test.js
sh "$T/kiem-tra-hien-thuc.sh" "$F" >/dev/null 2>&1

# ---------------------------------------------------------------- perf
echo ""
echo "loại việc: perf"
tao_fixture perf perf_w
for c in truy-vet thiet-ke ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "perf đầy đủ qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done
# Mỗi mục "## Trước" / "## Sau" phải có dòng KET_QUA (dòng này còn lặp lại
# trong khối output thật, nên đếm theo mục chứ không đếm dòng).
dung "do-hieu-nang.md có số đo trước và sau" sh -c "[ \"\$(awk '/^## /{m=\$2} /^KET_QUA:/ && m!=\"\" && !(m in c) {c[m]=1; n++} END{print n+0}' '$F/do-hieu-nang.md')\" = 2 ]"
ky_vong 1 "đo \"trước\" bị từ chối khi đã sửa code production" sh "$T/kiem-tra-hieu-nang.sh" "$F" --truoc

thay "$F/spec.md" '- Mục tiêu: dưới 10 ms' '- Mục tiêu: nhanh hơn'
ky_vong 1 "spec perf chặn YC hiệu năng không có số liệu" sh "$T/kiem-tra-truy-vet.sh" "$F"
viet_spec; ghi_based_on

mv "$F/do-hieu-nang.md" "$F/do-hieu-nang.bak"
ky_vong 1 "implement chặn perf không có số đo" sh "$T/kiem-tra-hien-thuc.sh" "$F"
ky_vong 1 "đo \"sau\" bị từ chối khi chưa có số đo trước" sh "$T/kiem-tra-hieu-nang.sh" "$F" --sau
mv "$F/do-hieu-nang.bak" "$F/do-hieu-nang.md"

# ---------------------------------------------------------------- chore
echo ""
echo "loại việc: chore"
tao_fixture chore chore_v
for c in truy-vet ke-hoach hien-thuc ra-soat; do
  ky_vong 0 "chore đầy đủ (không có tdd.md) qua kiem-tra-$c.sh" sh "$T/kiem-tra-$c.sh" "$F"
done
ky_vong 1 "chore chạy design thì bị chặn" sh "$T/kiem-tra-thiet-ke.sh" "$F"

thay "$F/spec.md" '`đã duyệt`' '`đề xuất`'
ky_vong 1 "chore: plan chặn khi người chưa duyệt spec" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_spec; ghi_based_on

thay "$F/open-questions.md" '`không chặn`' '`chặn`'
ky_vong 1 "chore: điểm mù \"chặn\" còn mở thì plan chặn (chore không có design)" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_spec; ghi_based_on

printf 'moi\n' > "$R/src/a.txt"
ky_vong 1 "chore đụng code production thì chặn" sh "$T/kiem-tra-hien-thuc.sh" "$F"
g checkout -q -- src/a.txt

printf '{"dependencies":{"lodash":"4.17.21"}}\n' > "$R/package.json"
ky_vong 1 "chore nâng dependency không khai thì chặn" sh "$T/kiem-tra-hien-thuc.sh" "$F"
thay "$F/plan.md" '| Thư viện | Cũ → mới | Mức |
|---|---|---|
' '| Thư viện | Cũ → mới | Mức |
|---|---|---|
| lodash | 4.17.20 → 4.17.21 | vá |
'
ky_vong 0 "khai nâng bản vá thì cho qua" sh "$T/kiem-tra-hien-thuc.sh" "$F"
thay "$F/plan.md" '| vá |' '| major |'
ky_vong 1 "nâng major không được là chore" sh "$T/kiem-tra-hien-thuc.sh" "$F"
rm -f "$R/package.json"; viet_plan; ghi_based_on

thay "$F/plan.md" '- File dự kiến: `docs/*`' '- Dựa trên: `D-01`
- File dự kiến: `docs/*`'
ky_vong 1 "chore: task Dựa trên D-xx bị chặn (không có tdd.md)" sh "$T/kiem-tra-ke-hoach.sh" "$F"
viet_plan; ghi_based_on

# ---------------------------------------------------------------- doi ten feature
echo ""
echo "doi-ten-feature.sh"
R5="$TMP/repo5"; mkdir -p "$R5"
git -C "$R5" init -q; git -C "$R5" checkout -q -b main
sh "$T/cai-dat.sh" "$R5" --lenh-kiem-thu true >/dev/null 2>&1
git -C "$R5" add -A; git -C "$R5" -c user.name=t -c user.email=t@t commit -q -m goc
ky_vong 2 "từ chối chạy ở checkout chính" sh "$R5/.agent-workflow/.quy-trinh/tools/doi-ten-feature.sh" feat_x
W7="$TMP/repo5.wt/fix_sai-loai"
git -C "$R5" worktree add -q -b fix_sai-loai "$W7" main
mkdir -p "$W7/.agent-workflow/fix_sai-loai"; printf 'x\n' > "$W7/.agent-workflow/fix_sai-loai/intake.md"
mkdir -p "$TMP/repo5.wt/feat_khac"
ky_vong 2 "từ chối khi thư mục worktree đích đã tồn tại" sh "$W7/.agent-workflow/.quy-trinh/tools/doi-ten-feature.sh" feat_khac
dung "…và không đổi gì" sh -c "[ -d '$W7' ] && git -C '$R5' rev-parse --verify --quiet refs/heads/fix_sai-loai"
ky_vong 0 "đổi tên thành công (chạy trong worktree)" sh "$W7/.agent-workflow/.quy-trinh/tools/doi-ten-feature.sh" feat_dung-loai
W8="$TMP/repo5.wt/feat_dung-loai"
dung "branch đã đổi tên" sh -c "git -C '$R5' rev-parse --verify --quiet refs/heads/feat_dung-loai && ! git -C '$R5' rev-parse --verify --quiet refs/heads/fix_sai-loai"
dung "worktree dời sang tên mới, cùng thư mục cha" sh -c "[ ! -e '$W7' ] && [ \"\$(git -C '$W8' rev-parse --abbrev-ref HEAD)\" = feat_dung-loai ]"
dung "thư mục artifact dời theo" sh -c "[ -f '$W8/.agent-workflow/feat_dung-loai/intake.md' ] && [ ! -d '$W8/.agent-workflow/fix_sai-loai' ]"

# ---------------------------------------------------------------- khoi "Ket qua"
# Nguoi va agent doc NHAN, khong doc ma so: moi script in khoi nay ra stderr.
echo ""
echo "lib/ket-qua.sh"
KQT="$TMP/kq-thu.sh"
cat > "$KQT" <<EOF
. "$T/lib/ket-qua.sh"
kq_khai thu.sh "0=ĐẠT" "1=KHÔNG ĐẠT" "2=THIẾU ĐẦU VÀO"
kq_don 'echo don >&2'
echo du-lieu
exit "\$1"
EOF
ky_vong 1 "mã thoát giữ nguyên sau khi in khối" sh "$KQT" 1
dung "đánh dấu đúng nhãn của lần chạy" sh -c "sh '$KQT' 1 2>&1 >/dev/null | grep -qx '  \[x\] KHÔNG ĐẠT'"
dung "…các nhãn còn lại để trống" sh -c "o=\$(sh '$KQT' 1 2>&1 >/dev/null); printf '%s\n' \"\$o\" | grep -qx '  \[ \] ĐẠT' && printf '%s\n' \"\$o\" | grep -qx '  \[ \] THIẾU ĐẦU VÀO'"
dung "mã ngoài danh sách → LỖI NGOÀI DỰ KIẾN" sh -c "sh '$KQT' 9 2>&1 >/dev/null | grep -q '\[x\] LỖI NGOÀI DỰ KIẾN'"
dung "khối ra stderr, stdout giữ nguyên dữ liệu" bang "$(sh "$KQT" 0 2>/dev/null)" "du-lieu"
dung "việc dọn dẹp (kq_don) vẫn chạy" sh -c "sh '$KQT' 0 2>&1 >/dev/null | grep -qx don"
dung "checker thiếu file → [x] THIẾU ĐẦU VÀO" sh -c "sh '$T/kiem-tra-ke-hoach.sh' '$TMP/khong-co' 2>&1 | grep -q '\[x\] THIẾU ĐẦU VÀO'"
dung "xac-dinh-feature ở checkout chính → [x] ĐANG Ở CHECKOUT CHÍNH" sh -c "sh '$XD' 2>&1 | grep -q '\[x\] ĐANG Ở CHECKOUT CHÍNH'"
dung "…stdout không lẫn khối Kết quả" sh -c "! sh '$XD' 2>/dev/null | grep -q 'Kết quả'"

# ---------------------------------------------------------------- dong goi (phat hanh)
echo ""
echo "tools/dong-goi.sh"
# tao_nguon <thư-mục> <X.Y.Z> — chép repo này (cả thay đổi chưa commit) thành một
# repo git riêng mang version <X.Y.Z>. Dùng làm "bản phát hành" giả.
tao_nguon() {
  rm -rf "$1"; mkdir -p "$1"
  (cd "$ROOT" && tar cf - --exclude=.git .) | (cd "$1" && tar xf -)
  printf '%s\n' "$2" > "$1/VERSION"
  [ -f "$1/bin/aw" ] && thay "$1/bin/aw" "AW_WRAPPER_VERSION=\"$(cat "$ROOT/VERSION")\"" "AW_WRAPPER_VERSION=\"$2\""
  git -C "$1" init -q; git -C "$1" checkout -q -b main
  git -C "$1" add -A; git -C "$1" -c user.name=t -c user.email=t@t commit -q -m "v$2"
}
NG="$TMP/nguon-goi"; tao_nguon "$NG" 9.9.1
ky_vong 0 "đóng gói bản đúng" sh "$NG/tools/dong-goi.sh" "$TMP/goi1"
dung "ra tarball đúng tên + SHA256SUMS khớp" sh -c "cd '$TMP/goi1' && [ -f agent-workflow-9.9.1.tar.gz ] && sha256sum -c SHA256SUMS >/dev/null 2>&1"
dung "tarball có thư mục gốc agent-workflow-9.9.1/ và VERSION" sh -c "gzip -dc '$TMP/goi1/agent-workflow-9.9.1.tar.gz' | tar tf - | grep -qx 'agent-workflow-9.9.1/VERSION'"
sh "$NG/tools/dong-goi.sh" "$TMP/goi2" >/dev/null 2>&1
dung "đóng gói lại cùng commit → cùng checksum" cmp -s "$TMP/goi1/SHA256SUMS" "$TMP/goi2/SHA256SUMS"
printf 'chua commit\n' > "$NG/chua-commit.txt"
sh "$NG/tools/dong-goi.sh" "$TMP/goi3" >/dev/null 2>&1
dung "file chưa commit không lọt vào gói" sh -c "! gzip -dc '$TMP/goi3/agent-workflow-9.9.1.tar.gz' | tar tf - | grep -q chua-commit"
printf 'v2\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam sai
ky_vong 4 "VERSION sai dạng X.Y.Z → VERSION LỖI" sh "$NG/tools/dong-goi.sh" "$TMP/goi4"
ky_vong 2 "ref không tồn tại → sai tham số" sh "$NG/tools/dong-goi.sh" "$TMP/goi5" khong-co
dung "VERSION của repo là X.Y.Z" sh -c "grep -Eqx '[0-9]+\.[0-9]+\.[0-9]+' '$ROOT/VERSION'"
dung "CHANGELOG.md có mục cho VERSION" grep -qF "## [$(cat "$ROOT/VERSION")]" "$ROOT/CHANGELOG.md"

# ---------------------------------------------------------------- tong ket
echo ""
echo "─────────────────────────────────────────"
printf 'Tổng: %d ca — %d đạt, %d hỏng\n' "$((n_ok + n_fail))" "$n_ok" "$n_fail"
[ "$n_fail" -gt 0 ] && exit 1
exit 0
