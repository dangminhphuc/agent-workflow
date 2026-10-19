#!/usr/bin/env sh
# Loại việc perf, guard, approval(s), loại việc chore.
# Chạy riêng: sh tools/tests/12-perf-guard-chore.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

# ---------------------------------------------------------------- perf
nhom "loại việc: perf"
tao_fixture perf perf_w
for c in spec design plan implement review; do
  ky_vong 0 "perf đầy đủ qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done
# Mỗi mục "## Trước" / "## Sau" phải có dòng RESULT. Fixture in tên cũ "KET_QUA:" —
# máy vẫn nhận và ghi lại dạng RESULT: (khối output thật vẫn giữ nguyên KET_QUA).
dung "perf.md có số đo trước và sau (lệnh đo in KET_QUA: cũ vẫn nhận)" sh -c "[ \"\$(awk '/^## /{m=\$2} /^RESULT:/ && m!=\"\" && !(m in c) {c[m]=1; n++} END{print n+0}' '$F/perf.md')\" = 2 ]"
ky_vong 1 "đo \"trước\" bị từ chối khi đã sửa code production" sh "$T/check-perf.sh" "$F" --before

thay "$F/spec.md" '- Target: dưới 10 ms' '- Target: nhanh hơn'
ky_vong 1 "spec perf chặn REQ hiệu năng không có số liệu" sh "$T/check-spec.sh" "$F"
viet_spec; ghi_based_on

mv "$F/perf.md" "$F/perf.bak"
ky_vong 1 "implement chặn perf không có số đo" sh "$T/check-implement.sh" "$F"
ky_vong 1 "đo \"sau\" bị từ chối khi chưa có số đo trước" sh "$T/check-perf.sh" "$F" --after
mv "$F/perf.bak" "$F/perf.md"

# ---------------------------------------------------------------- gác ô duyệt (hook)
nhom "guard.sh (aw guard)"
GAC="$T/guard.sh"
co_tick() { grep -q '^- \[x\] \*\*Approved by human' "$F/spec.md"; }
d_tick() { grep -q '^- \[x\] \*\*Approved by human' "$F/tdd.md"; }
viet_spec; viet_tdd
ky_vong 3 "guard sai tham số → SAI THAM SỐ" sh "$GAC" khac

# Người tick (giữa hai lệnh của agent): pre ghi dấu, post để yên
ky_vong 0 "pre luôn cho qua" sh "$GAC" pre
dung "…và ghi dấu duyệt cho ô người đã tick" grep -q 'approval-hash:' "$F/spec.md"
ky_vong 0 "post không đổi gì thì cho qua" sh "$GAC" post
dung "…tick của người còn nguyên" co_tick

# Agent tick trong lúc lệnh chạy: post bỏ tick, báo agent (mã 2)
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'; sh "$GAC" pre >/dev/null 2>&1
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 2 "post chặn agent tick ô duyệt spec" sh "$GAC" post
dung "…và đã bỏ tick" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/spec.md'"
sh "$GAC" pre >/dev/null 2>&1
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
dung "…stderr nói rõ cho agent: không tick lại" sh -c "sh '$GAC' post 2>&1 | grep -q 'Agent KHÔNG tick lại'"

# Agent tick DEC-xxx (kể cả viết cả file mới có sẵn [x])
viet_tdd; thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'; sh "$GAC" pre >/dev/null 2>&1
thay "$F/tdd.md" '- [ ] **Approved by human**' '- [x] **Approved by human**'
ky_vong 2 "post chặn agent tick ô duyệt DEC-xxx" sh "$GAC" post
dung "…và đã bỏ tick D" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/tdd.md'"
sh "$GAC" pre >/dev/null 2>&1; viet_tdd
ky_vong 2 "post chặn agent ghi đè cả tdd.md với ô đã tick" sh "$GAC" post

# Agent sửa nội dung đã duyệt mà quên bỏ tick: post bỏ tick
viet_spec; sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
sh "$GAC" pre >/dev/null 2>&1
thay "$F/spec.md" 'mở y thấy a' 'mở y thấy a và c'
ky_vong 2 "post bỏ tick spec bị sửa sau khi duyệt" sh "$GAC" post
dung "…spec giờ chưa tick" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/spec.md'"

# Được phép: agent bỏ tick; agent thêm phản biện dưới DEC đã duyệt
viet_spec; sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
sh "$GAC" pre >/dev/null 2>&1; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 0 "agent bỏ tick thì cho qua" sh "$GAC" post
dung "…và dấu duyệt thừa bị xoá" sh -c "! grep -q 'dấu duyệt' '$F/spec.md'"
viet_tdd; sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
sh "$GAC" pre >/dev/null 2>&1
thay "$F/tdd.md" '- Choice: file' '- Choice: file
- Critique (agent): cân nhắc DB'
ky_vong 0 "agent thêm phản biện dưới DEC đã duyệt thì cho qua" sh "$GAC" post
dung "…D vẫn tick" d_tick

# Không có mốc của pre (pre không chạy): post không bỏ tick của ai
viet_spec; rm -f "$R/.agent-workflow/.guard-pre"
ky_vong 0 "post không thấy pre thì không coi tick chưa dấu là của agent" sh "$GAC" post
dung "…tick còn nguyên" co_tick

# Việc mới dùng engine cũ (dạng "Status:") — hook không đụng tới
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- **Status:** `approved`'
sh "$GAC" pre >/dev/null 2>&1
ky_vong 0 "spec dạng cũ: hook không chặn" sh "$GAC" post

# Cursor nạp hook của .claude/settings.json (tương thích, bật sẵn) VÀ của
# .cursor/hooks.json: một lệnh của agent có thể chạy aw guard hai lần. Phải vô hại.
viet_spec; sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" pre >/dev/null 2>&1
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 2 "hook chạy hai lần (pre pre · agent tick · post post): post đầu chặn" sh "$GAC" post
ky_vong 0 "…post thứ hai không báo thêm" sh "$GAC" post
dung "…tick của agent đã bị bỏ, không hồi lại" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/spec.md'"
viet_spec
sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" pre >/dev/null 2>&1
ky_vong 0 "người tick giữa hai lượt, hook chạy hai lần: post đầu cho qua" sh "$GAC" post
ky_vong 0 "…post thứ hai cũng cho qua" sh "$GAC" post
dung "…tick của người còn nguyên" co_tick
sh "$GAC" pre >/dev/null 2>&1; thay "$F/spec.md" 'mở y thấy a' 'mở y thấy a và c'; sh "$GAC" pre >/dev/null 2>&1
ky_vong 2 "nội dung đổi sau duyệt, hook hai lần: vẫn bỏ tick" sh "$GAC" post
dung "…spec giờ chưa tick" sh -c "! grep -q '^- \[x\] \*\*Approved by human' '$F/spec.md'"
# post dùng hết mốc của pre: một post lẻ về sau (agent bắn hook không đều — Cursor
# có tool bỏ qua pre) không được coi tick của người là của agent.
viet_spec; thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
sh "$GAC" pre >/dev/null 2>&1; sh "$GAC" post >/dev/null 2>&1
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 0 "post lẻ sau một cặp pre/post đã xong: tick của người không bị bỏ" sh "$GAC" post
dung "…tick của người còn nguyên" co_tick
rm -f "$R/.agent-workflow/.guard-pre"
viet_spec; viet_tdd; ghi_based_on

# ---------------------------------------------------------------- cổng duyệt
nhom "approval.sh (aw approval)"
CD="$T/approval.sh"
viet_spec; viet_tdd
ky_vong 2 "approval sai phase → SAI THAM SỐ" sh "$CD" review "$F"
ky_vong 2 "approval thiếu thư mục → SAI THAM SỐ" sh "$CD" design "$TMP/khong-co"
ky_vong 0 "spec đã tick → ĐÃ DUYỆT" sh "$CD" design "$F"
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
thay "$F/spec.md" '### REQ-002 — b' '### REQ-003 — log khi từ chối
- Source: `[INFERRED]` từ REQ-001
- Priority: `must`
- Acceptance criteria:
  - [ ] có log

### REQ-002 — b'
ky_vong 1 "spec chưa tick → CHƯA DUYỆT" sh "$CD" design "$F"
OUT_CD=$(sh "$CD" design "$F" 2>/dev/null)
dung "…chỉ đúng file và dòng phải tick" sh -c "printf '%s' \"\$1\" | grep -q 'mở .agent-workflow/[^ ]*/spec.md, dòng [0-9]'" _ "$OUT_CD"
dung "…liệt kê REQ [INFERRED] kèm tên" sh -c "printf '%s' \"\$1\" | grep -q 'REQ-003 — log khi từ chối'" _ "$OUT_CD"
dung "…liệt kê Ngoài phạm vi" sh -c "printf '%s' \"\$1\" | grep -q 'màn hình z'" _ "$OUT_CD"
dung "…nói hệ quả của mức rủi ro (Mode 1/2)" sh -c "printf '%s' \"\$1\" | grep -q 'Risk: normal — /aw-design chạy Mode 1'" _ "$OUT_CD"
dung "…đếm điểm mù còn mở theo mức chặn" sh -c "printf '%s' \"\$1\" | grep -q 'Open question còn mở: 1 (blocking: 0 · review-blocking: 0 · non-blocking: 1)'" _ "$OUT_CD"
dung "…không tự tick" sh -c "grep -q '^- \[ \] \*\*Approved by human' '$F/spec.md'"
thay "$F/spec.md" '- [ ] **Approved by human** — đã đọc' '- [x] **Approved by human** — đã đọc'
ky_vong 0 "người tick xong → ĐÃ DUYỆT (kiểm lại)" sh "$CD" design "$F"
thay "$F/spec.md" 'có log' 'có log Warn'
ky_vong 1 "spec đổi sau duyệt → CHƯA DUYỆT" sh "$CD" design "$F"
dung "…nói rõ đã đổi sau khi duyệt và cách duyệt lại" sh -c "sh '$CD' design '$F' 2>/dev/null | grep -q 'ĐÃ ĐỔI SAU KHI DUYỆT' && sh '$CD' design '$F' 2>/dev/null | grep -q 'xoá \"<!-- approval-hash'"
viet_spec; viet_tdd
ky_vong 0 "/aw-plan: mọi DEC đã tick → ĐÃ DUYỆT" sh "$CD" plan "$F"
thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**
- Critique (agent): cân nhắc DB'
ky_vong 1 "/aw-plan: còn DEC chưa tick → CHƯA DUYỆT" sh "$CD" plan "$F"
OUT_CD=$(sh "$CD" plan "$F" 2>/dev/null)
dung "…đếm DEC chưa duyệt" sh -c "printf '%s' \"\$1\" | grep -q 'CÒN 1/1 QUYẾT ĐỊNH CHƯA DUYỆT'" _ "$OUT_CD"
dung "…tên DEC, dòng, tác giả, lựa chọn, có phản biện" sh -c "printf '%s' \"\$1\" | grep -q 'DEC-001 — lưu ở đâu' && printf '%s' \"\$1\" | grep -q 'dòng [0-9]* · chưa tick' && printf '%s' \"\$1\" | grep -q 'tác giả: agent · Choice: file · có 1 phản biện'" _ "$OUT_CD"
viet_spec; viet_tdd; ghi_based_on


# ---------------------------------------------------------------- duyệt tập trung
nhom "approvals.sh (aw approvals, /aw-approvals)"
AP="$T/approvals.sh"
viet_spec; viet_tdd
ky_vong 0 "mọi ô đã tick → KHÔNG CÒN Ô CHỜ DUYỆT" sh "$AP"
ky_vong 2 "tham số lạ → SAI THAM SỐ" sh "$AP" --tat-ca
ky_vong 2 "tick thiếu tham số → SAI THAM SỐ" sh "$AP" tick "$F" spec
ky_vong 2 "tick khoá lạ → SAI THAM SỐ" sh "$AP" tick "$F" REQ-001 0000000000000000
ky_vong 0 "aw-engine approvals → approvals.sh" sh "$AWE" approvals
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 1 "spec chưa tick → CÓ Ô CHỜ DUYỆT" sh "$AP"
OUT_AP=$(sh "$AP" 2>/dev/null)
dung "…link tuyệt đối tới đúng dòng ô duyệt" sh -c "printf '%s' \"\$1\" | grep -q \"^ *$F/spec.md:\$(grep -n 'Approved by human' '$F/spec.md' | cut -d: -f1)\$\"" _ "$OUT_AP"
dung "…in đúng lệnh tick kèm hash" sh -c "printf '%s' \"\$1\" | grep -q 'duyệt: aw approvals tick $F spec [0-9a-f]\{16\}'" _ "$OUT_AP"
dung "…liệt kê không tự tick" sh -c "grep -q '^- \[ \] \*\*Approved by human' '$F/spec.md'"
H_AP=$(printf '%s\n' "$OUT_AP" | sed -n "s|.*duyệt: aw approvals tick $F spec ||p")
ky_vong 1 "tick với hash khác bản hiện tại → KHÔNG TICK" sh "$AP" tick "$F" spec 0000000000000000
dung "…file giữ nguyên chưa tick" sh -c "grep -q '^- \[ \] \*\*Approved by human' '$F/spec.md'"
rm -f "$CFG/journal/approvals.tsv"
ky_vong 0 "tick với hash người vừa thấy → ĐÃ DUYỆT" sh "$AP" tick "$F" spec "$H_AP"
dung "…ô được tick, dấu duyệt = hash đó" grep -q "^- \[x\] \*\*Approved by human.*approval-hash: $H_AP -->" "$F/spec.md"
ky_vong 0 "…cổng duyệt spec thấy ĐÃ DUYỆT" sh "$CD" design "$F"
dung "…ghi nhật ký approvals.tsv" grep -q "spec	$H_AP	aw approvals tick" "$CFG/journal/approvals.tsv"
ky_vong 0 "tick lại mục đã duyệt → không làm gì" sh "$AP" tick "$F" spec "$H_AP"
thay "$F/spec.md" '### REQ-002 — b' '### REQ-002 — bb'
OUT_AP=$(sh "$AP" 2>/dev/null)
dung "spec đổi sau duyệt → liệt kê ĐÃ ĐỔI sau khi duyệt" sh -c "printf '%s' \"\$1\" | grep -q 'ĐÃ ĐỔI sau khi duyệt'" _ "$OUT_AP"
ky_vong 1 "…tick bằng hash cũ → KHÔNG TICK" sh "$AP" tick "$F" spec "$H_AP"
H_AP=$(printf '%s\n' "$OUT_AP" | sed -n "s|.*duyệt: aw approvals tick $F spec ||p")
ky_vong 0 "…tick bằng hash bản mới → ĐÃ DUYỆT lại" sh "$AP" tick "$F" spec "$H_AP"
ky_vong 0 "…cổng duyệt spec thấy ĐÃ DUYỆT" sh "$CD" design "$F"
viet_spec; viet_tdd
thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
OUT_AP=$(sh "$AP" 2>/dev/null)
dung "DEC-xxx chưa tick → liệt kê kèm tên D" sh -c "printf '%s' \"\$1\" | grep -q 'DEC-001 — lưu ở đâu' && printf '%s' \"\$1\" | grep -q '$F/tdd.md:[0-9]'" _ "$OUT_AP"
H_AP=$(printf '%s\n' "$OUT_AP" | sed -n "s|.*duyệt: aw approvals tick $F DEC-001 ||p")
sh "$GAC" pre >/dev/null 2>&1
sh "$AP" tick "$F" DEC-001 "$H_AP" >/dev/null 2>&1
ky_vong 0 "tick qua aw approvals tick → aw guard post không bỏ" sh "$GAC" post
ky_vong 0 "…cổng duyệt plan thấy ĐÃ DUYỆT" sh "$CD" plan "$F"
thay "$F/tdd.md" '- [x] **Approved by human**' '- [ ] **Approved by human**'
sh "$GAC" pre >/dev/null 2>&1
thay "$F/tdd.md" '- [ ] **Approved by human**' '- [x] **Approved by human**'
ky_vong 2 "tick bằng sửa file → aw guard post vẫn bỏ" sh "$GAC" post
viet_spec; viet_tdd
# --global: việc ở worktree khác
g worktree add -q "$TMP/wt-ap" -b feat/ap-khac
mkdir -p "$TMP/wt-ap/.agent-workflow/feat_ap-khac"
sed 's/- \[x\] \*\*Approved by human\*\* — đã đọc/- [ ] **Approved by human** — đã đọc/; s/ *<!-- approval-hash: [0-9a-f]* -->//' "$F/spec.md" > "$TMP/wt-ap/.agent-workflow/feat_ap-khac/spec.md"
ky_vong 0 "worktree khác có ô chờ — mặc định chỉ xét worktree hiện tại" sh "$AP"
ky_vong 1 "--global → thấy ô chờ ở worktree khác" sh "$AP" --global
dung "…kèm tên việc, branch và link vào worktree đó" sh -c "sh '$AP' --global 2>/dev/null | grep -q 'feat_ap-khac · branch feat/ap-khac' && sh '$AP' --global 2>/dev/null | grep -q '$TMP/wt-ap/.agent-workflow/feat_ap-khac/spec.md:[0-9]'"
g worktree remove --force "$TMP/wt-ap"; g branch -D feat/ap-khac
viet_spec; viet_tdd; ghi_based_on

# ---------------------------------------------------------------- chore
nhom "loại việc: chore"
tao_fixture chore chore_v
for c in spec plan implement review; do
  ky_vong 0 "chore đầy đủ (không có tdd.md) qua check-$c.sh" sh "$T/check-$c.sh" "$F"
done
ky_vong 1 "chore chạy design thì bị chặn" sh "$T/check-design.sh" "$F"

thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
ky_vong 1 "chore: aw approval plan hỏi duyệt SPEC (không có tdd.md)" sh "$T/approval.sh" plan "$F"
dung "…đúng cổng spec, không nói Mode" sh -c "sh '$T/approval.sh' plan '$F' 2>/dev/null | grep -q 'vào /aw-plan cần spec' && sh '$T/approval.sh' plan '$F' 2>/dev/null | grep -q 'chore không có design'"
ky_vong 2 "chore: aw approval design → SAI THAM SỐ" sh "$T/approval.sh" design "$F"
ky_vong 1 "chore: plan chặn khi người chưa duyệt spec" sh "$T/check-plan.sh" "$F"
viet_spec; ghi_based_on

thay "$F/open-questions.md" '`non-blocking`' '`blocking`'
ky_vong 1 "chore: điểm mù \"chặn\" còn mở thì plan chặn (chore không có design)" sh "$T/check-plan.sh" "$F"
viet_spec; ghi_based_on

printf 'moi\n' > "$R/src/a.txt"
ky_vong 1 "chore đụng code production thì chặn" sh "$T/check-implement.sh" "$F"
g checkout -q -- src/a.txt

printf '{"dependencies":{"lodash":"4.17.21"}}\n' > "$R/package.json"
ky_vong 1 "chore nâng dependency không khai thì chặn" sh "$T/check-implement.sh" "$F"
thay "$F/plan.md" '| Library | Old → new | Level |
|---|---|---|
' '| Library | Old → new | Level |
|---|---|---|
| lodash | 4.17.20 → 4.17.21 | patch |
'
ky_vong 0 "khai nâng bản vá thì cho qua" sh "$T/check-implement.sh" "$F"
cp "$CFG/config.sh" "$TMP/ch-chore.bak"
printf 'TEST_CMD="true"\nSECURITY_CMDS="secret: true\nsast: true"\n' > "$CFG/config.sh"
ky_vong 1 "chore đụng dependency mà không có lệnh nhóm sca → chặn" sh "$T/check-implement.sh" "$F"
dung "…đúng lý do: thiếu SCA" sh -c "sh '$T/check-implement.sh' '$F' | grep -q 'nhóm \"sca\" chạy XANH'"
dung "…review cũng chặn đúng lý do" sh -c "sh '$T/check-review.sh' '$F' | grep -q 'nhóm \"sca\" chạy XANH'"
printf 'TEST_CMD="true"\nSECURITY_CMDS="secret: true\nsast: true\nsca: echo CVE-2099-1; exit 1"\n' > "$CFG/config.sh"
ky_vong 1 "chore đụng dependency mà SCA đỏ (CVE) → chặn" sh "$T/check-implement.sh" "$F"
cp "$TMP/ch-chore.bak" "$CFG/config.sh"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1
thay "$F/plan.md" '| patch |' '| major |'
ky_vong 1 "nâng major không được là chore" sh "$T/check-implement.sh" "$F"
rm -f "$R/package.json"; viet_plan; ghi_based_on
printf 'TEST_CMD="true"\nSECURITY_CMDS="secret: true"\n' > "$CFG/config.sh"
ky_vong 0 "chore KHÔNG đụng dependency thì không đòi SCA" sh "$T/check-implement.sh" "$F"
cp "$TMP/ch-chore.bak" "$CFG/config.sh"; sh "$T/check-implement.sh" "$F" >/dev/null 2>&1

thay "$F/plan.md" '- Expected files: `docs/*`' '- Based on: `DEC-001`
- Expected files: `docs/*`'
ky_vong 1 "chore: task Dựa trên DEC-xxx bị chặn (không có tdd.md)" sh "$T/check-plan.sh" "$F"
viet_plan; ghi_based_on

ket_thuc
