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

# ---------------------------------------------------------------- truy vet
echo ""
echo "kiem-tra-truy-vet.sh"
D="$TMP/tv"; mkdir -p "$D"
CHK="$ROOT/tools/kiem-tra-truy-vet.sh"

hop_le_spec() {
  printf '## Yêu cầu\n\n### YC-001 — a\n\n- Nguồn: `[JIRA]` ABC-1\n\n## Ngoài phạm vi\n' > "$D/spec.md"
  printf '# Điểm mù\n\nKhông có điểm mù.\n' > "$D/open-questions.md"
}

hop_le_spec
ky_vong 0 "spec hợp lệ thì cho qua" sh "$CHK" "$D"

hop_le_spec
printf '## Yêu cầu\n\n### YC-001 — a\n\n- Mô tả: không nguồn\n\n## Ngoài phạm vi\n' > "$D/spec.md"
ky_vong 1 "chặn yêu cầu không có nhãn nguồn" sh "$CHK" "$D"

hop_le_spec
printf '## Yêu cầu\n\n### YC-001 — a\n\n- Nguồn: `[BRD]` x\n\n## Ngoài phạm vi\n' > "$D/spec.md"
ky_vong 1 "chặn nhãn tự chế ngoài 5 nhãn hợp lệ" sh "$CHK" "$D"

hop_le_spec
printf '## Yêu cầu\n\n### YC-001 — a\n\n- Nguồn: `[CẦN-HỎI]` x\n\n## Ngoài phạm vi\n' > "$D/spec.md"
ky_vong 1 "chặn [CẦN-HỎI] không ghi vào open-questions" sh "$CHK" "$D"

printf '# Điểm mù\n\n## YC-001 — a\n\n- Chỗ chưa rõ: x\n' > "$D/open-questions.md"
ky_vong 1 "chặn mục điểm mù thiếu giả định tạm" sh "$CHK" "$D"

printf '# Điểm mù\n\n## YC-001 — a\n\n- Giả định tạm đang dùng: y\n' > "$D/open-questions.md"
ky_vong 0 "có giả định tạm thì cho qua" sh "$CHK" "$D"

hop_le_spec
printf '## Yêu cầu\n\n### YC-001 — a\n\n- Nguồn: `[JIRA]` A\n\n### YC-001 — b\n\n- Nguồn: `[JIRA]` B\n\n## Ngoài phạm vi\n' > "$D/spec.md"
ky_vong 1 "chặn mã YC trùng nhau" sh "$CHK" "$D"

hop_le_spec
rm -f "$D/open-questions.md"
ky_vong 2 "chặn khi thiếu hẳn open-questions.md" sh "$CHK" "$D"

# ---------------------------------------------------------------- ke hoach
echo ""
echo "kiem-tra-ke-hoach.sh"
D="$TMP/kh"; mkdir -p "$D"
CHK="$ROOT/tools/kiem-tra-ke-hoach.sh"

printf '### YC-001 — a\n- Nguồn: `[JIRA]` A\n### YC-002 — b\n- Nguồn: `[JIRA]` B\n' > "$D/spec.md"

day_du() {
  printf '## Task\n### T-01 — x\n- Phủ: `YC-001`\n- Cách kiểm chứng: `npm test` → xanh\n### T-02 — y\n- Phủ: `YC-002`\n- Cách kiểm chứng: `npm test` → xanh\n## Rủi ro\n' > "$D/plan.md"
}

day_du
ky_vong 0 "kế hoạch phủ đủ thì cho qua" sh "$CHK" "$D"

printf '## Task\n### T-01 — x\n- Phủ: `YC-001`\n- Cách kiểm chứng: `npm test` → xanh\n## Rủi ro\n' > "$D/plan.md"
ky_vong 1 "chặn YÊU CẦU BỊ BỎ SÓT (chiều ngược)" sh "$CHK" "$D"

printf '## Task\n### T-01 — x\n- Phủ: `YC-001`\n- Cách kiểm chứng: `npm test` → xanh\n## Hoãn lại\n| Mã | Lý do hoãn |\n|---|---|\n| YC-002 | chờ BA |\n' > "$D/plan.md"
ky_vong 0 "hoãn lại có lý do thì cho qua" sh "$CHK" "$D"

printf '## Task\n### T-01 — x\n- Phủ: `YC-001`\n- Cách kiểm chứng: `npm test` → xanh\n## Hoãn lại\n| Mã | Lý do hoãn |\n|---|---|\n| YC-002 | |\n' > "$D/plan.md"
ky_vong 1 "chặn hoãn lại bỏ trống lý do" sh "$CHK" "$D"

printf '## Task\n### T-01 — x\n- Phủ: `YC-999`\n- Cách kiểm chứng: `npm test` → xanh\n## Rủi ro\n' > "$D/plan.md"
ky_vong 1 "chặn task trỏ về mã YC không tồn tại (chiều xuôi)" sh "$CHK" "$D"

day_du
sed -i 's|- Cách kiểm chứng: `npm test` → xanh|- Cách kiểm chứng: <lệnh cụ thể>|' "$D/plan.md"
ky_vong 1 "chặn chỗ giữ chỗ chưa điền" sh "$CHK" "$D"

# ---------------------------------------------------------------- hien thuc
echo ""
echo "kiem-tra-hien-thuc.sh"
D="$TMP/ht"; mkdir -p "$D/.quy-trinh"
CHK="$ROOT/tools/kiem-tra-hien-thuc.sh"

printf '## Task\n### T-01 — x\n- Trạng thái: `[x]`\n' > "$D/plan.md"
printf 'LENH_KIEM_THU=""\n' > "$D/.quy-trinh/cau-hinh.sh"
ky_vong 1 "chưa khai LENH_KIEM_THU là KHÔNG ĐẠT, không phải bỏ qua" sh "$CHK" "$D"

printf 'LENH_KIEM_THU="true"\n' > "$D/.quy-trinh/cau-hinh.sh"
ky_vong 0 "test xanh + task xong thì cho qua" sh "$CHK" "$D"

printf 'LENH_KIEM_THU="false"\n' > "$D/.quy-trinh/cau-hinh.sh"
ky_vong 1 "chặn khi test đỏ" sh "$CHK" "$D"

printf 'LENH_KIEM_THU="true"\n' > "$D/.quy-trinh/cau-hinh.sh"
printf '## Task\n### T-01 — x\n- Trạng thái: `[~]`\n' > "$D/plan.md"
ky_vong 1 "chặn khi còn task đang làm dở" sh "$CHK" "$D"

# output that phai duoc ghi ra, khong phai loi ke lai
printf '## Task\n### T-01 — x\n- Trạng thái: `[x]`\n' > "$D/plan.md"
printf 'LENH_KIEM_THU="echo DAU-VET-DUY-NHAT-12345"\n' > "$D/.quy-trinh/cau-hinh.sh"
sh "$CHK" "$D" >/dev/null 2>&1
if grep -q 'DAU-VET-DUY-NHAT-12345' "$D/ket-qua-kiem-thu.md" 2>/dev/null; then
  n_ok=$((n_ok + 1)); printf '  ok    ghi output THẬT vào ket-qua-kiem-thu.md\n'
else
  n_fail=$((n_fail + 1)); printf '  FAIL  không ghi output thật vào ket-qua-kiem-thu.md\n'
fi

# ---------------------------------------------------------------- ra soat
echo ""
echo "kiem-tra-ra-soat.sh"
D="$TMP/rs"; mkdir -p "$D"
CHK="$ROOT/tools/kiem-tra-ra-soat.sh"

printf '### YC-001 — a\n- Nguồn: `[JIRA]` A\n### YC-002 — b\n- Nguồn: `[CẦN-HỎI]` x\n' > "$D/spec.md"

printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | đạt |\n| YC-002 | chờ xác nhận |\n' > "$D/review.md"
ky_vong 0 "rà soát đủ và đúng thì cho qua" sh "$CHK" "$D"

printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | đạt |\n' > "$D/review.md"
ky_vong 1 "chặn khi bỏ sót một yêu cầu" sh "$CHK" "$D"

printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | đạt |\n| YC-002 | đạt |\n' > "$D/review.md"
ky_vong 1 "chặn kết luận 'đạt' cho yêu cầu đứng trên giả định tạm" sh "$CHK" "$D"

printf '| Mã | Kết luận |\n|---|---|\n| YC-001 | ổn |\n| YC-002 | chờ xác nhận |\n' > "$D/review.md"
ky_vong 1 "chặn kết luận tự chế ngoài 4 giá trị hợp lệ" sh "$CHK" "$D"

# ---------------------------------------------------------------- adapter
echo ""
echo "adapters/claude-code/build.sh"
BUILD="$ROOT/adapters/claude-code/build.sh"

O="$TMP/out1"; mkdir -p "$O"
ky_vong 0 "build bản đúng thành công" sh "$BUILD" --out "$O"

if [ -f "$O/.claude/commands/spec.md" ] && [ -f "$O/.claude/agents/ra-soat-doc-lap.md" ] \
   && [ -f "$O/.claude/skills/quy-trinh-agent/SKILL.md" ] && [ ! -f "$O/.claude/commands/ship.md" ]; then
  n_ok=$((n_ok + 1)); printf '  ok    sinh đúng bộ file, bỏ qua phase chưa hiện thực\n'
else
  n_fail=$((n_fail + 1)); printf '  FAIL  bộ file sinh ra không đúng\n'
fi

# khong ghi de file nguoi viet tay
printf '# tôi tự viết\n' > "$O/.claude/commands/spec.md"
ky_vong 3 "từ chối ghi đè file người viết tay" sh "$BUILD" --out "$O"
if head -1 "$O/.claude/commands/spec.md" | grep -q 'tôi tự viết'; then
  n_ok=$((n_ok + 1)); printf '  ok    nội dung người viết còn nguyên\n'
else
  n_fail=$((n_fail + 1)); printf '  FAIL  nội dung người viết đã bị mất\n'
fi
ky_vong 0 "--force thì cho phép ghi đè" sh "$BUILD" --out "$O" --force

# exit_machine phai la lenh chay duoc
FAKE="$TMP/fake"; mkdir -p "$FAKE/workflow/phases" "$FAKE/tools/lib" "$FAKE/adapters/claude-code" "$FAKE/workflow/templates" "$FAKE/workflow/rules"
cp "$ROOT/workflow.yaml" "$FAKE/"
cp "$ROOT"/workflow/phases/*.md "$FAKE/workflow/phases/"
cp "$ROOT"/workflow/templates/*.md "$FAKE/workflow/templates/"
cp "$ROOT"/tools/lib/md.sh "$FAKE/tools/lib/"
cp "$ROOT"/tools/kiem-tra-*.sh "$FAKE/tools/"
cp "$ROOT"/adapters/claude-code/build.sh "$FAKE/adapters/claude-code/"
sed -i 's|^  - sh tools/kiem-tra-ke-hoach.sh$|  - kế hoạch trông có vẻ hợp lý|' "$FAKE/workflow/phases/02-plan.md"
O2="$TMP/out2"; mkdir -p "$O2"
ky_vong 4 "từ chối build khi exit_machine không phải lệnh chạy được" sh "$FAKE/adapters/claude-code/build.sh" --out "$O2"
if [ ! -f "$O2/.claude/commands/plan.md" ] && [ -z "$(find "$O2" -name '*.tmp' 2>/dev/null)" ]; then
  n_ok=$((n_ok + 1)); printf '  ok    không để lại file viết dở khi build hỏng\n'
else
  n_fail=$((n_fail + 1)); printf '  FAIL  để lại file viết dở hoặc file .tmp\n'
fi

cp "$ROOT/workflow/phases/02-plan.md" "$FAKE/workflow/phases/"
sed -i 's|^  - sh tools/kiem-tra-ke-hoach.sh$|  - sh tools/khong-ton-tai.sh|' "$FAKE/workflow/phases/02-plan.md"
ky_vong 4 "từ chối build khi lệnh trỏ tới script không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out3"

# ---------------------------------------------------------------- cai dat
echo ""
echo "tools/cai-dat.sh"
O4="$TMP/repo4"; mkdir -p "$O4"
ky_vong 0 "cài vào repo đích thành công" sh "$ROOT/tools/cai-dat.sh" "$O4" --lenh-kiem-thu "true"
if [ -f "$O4/.agent-workflow/.quy-trinh/tools/kiem-tra-truy-vet.sh" ] \
   && grep -q 'LENH_KIEM_THU="true"' "$O4/.agent-workflow/.quy-trinh/cau-hinh.sh"; then
  n_ok=$((n_ok + 1)); printf '  ok    chép bộ cài và ghi cấu hình\n'
else
  n_fail=$((n_fail + 1)); printf '  FAIL  bộ cài hoặc cấu hình không đúng\n'
fi

printf 'LENH_KIEM_THU="npm test"\n' > "$O4/.agent-workflow/.quy-trinh/cau-hinh.sh"
sh "$ROOT/tools/cai-dat.sh" "$O4" >/dev/null 2>&1
if grep -q 'npm test' "$O4/.agent-workflow/.quy-trinh/cau-hinh.sh"; then
  n_ok=$((n_ok + 1)); printf '  ok    cài lại KHÔNG ghi đè cấu hình người sửa\n'
else
  n_fail=$((n_fail + 1)); printf '  FAIL  cài lại đã ghi đè cấu hình người sửa\n'
fi

ky_vong 2 "từ chối cài vào chính repo agent-workflow" sh "$ROOT/tools/cai-dat.sh" "$ROOT"

# ---------------------------------------------------------------- tong ket
echo ""
echo "─────────────────────────────────────────"
printf 'Tổng: %d ca — %d đạt, %d hỏng\n' "$((n_ok + n_fail))" "$n_ok" "$n_fail"
[ "$n_fail" -gt 0 ] && exit 1
exit 0
