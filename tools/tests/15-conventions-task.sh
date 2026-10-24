#!/usr/bin/env sh
# check-conventions, quy ước đã commit, aw task, trạng thái sạch.
# Chạy riêng: sh tools/tests/15-conventions-task.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
tao_fixture
SS="$T/ready.sh"
CH="$CFG/config.sh"; cp "$CH" "$TMP/ch-ss.bak"

# ---------------------------------------------------------------- aw conventions check (check-conventions.sh)
nhom "check-conventions.sh (aw conventions check)"
QU="$T/check-conventions.sh"; CV="$CFG/conventions.md"; cp "$CV" "$TMP/conv-qu.bak"
qu_ra() { sh "$QU" 2>/dev/null; }
ky_vong 0 "mẫu của engine trên fixture → HỢP LỆ" sh "$QU"
dung "…cảnh báo placeholder còn trong Team conventions" sh -c "sh '$QU' 2>/dev/null | grep -q 'còn placeholder'"
ky_vong 2 "thừa tham số → SAI THAM SỐ" sh "$QU" x
ky_vong 0 "aw-engine conventions check" sh "$ROOT/bin/aw-engine" conventions check
ky_vong 2 "aw-engine conventions <lạ> → SAI THAM SỐ" sh "$ROOT/bin/aw-engine" conventions lam-gi
# cắt dòng dài theo byte không được để nửa ký tự UTF-8 (LC_ALL=C): chữ có dấu nằm đúng điểm cắt 60 / 50
cp "$TMP/conv-qu.bak" "$CV"
tc_pad=$(printf 'a%.0s' $(seq 1 57))
printf '\n<ví dụ %s ếếếế>\n' "$tc_pad" > "$TMP/tc-ph"
printf '%s\n' "<${tc_pad}ếếếế>" >> "$CV"
dung "placeholder cắt giữa chữ có dấu → dòng cảnh báo vẫn là UTF-8 hợp lệ" sh -c "sh '$QU' 2>/dev/null | grep 'còn placeholder — <a' | iconv -f UTF-8 -t UTF-8 >/dev/null"
cp "$TMP/conv-qu.bak" "$CV"
thay "$CV" 'covers_tag: ' "  $(printf 'a%.0s' $(seq 1 49))ếếếế covers_tag: "
dung "dòng khối conventions sai dạng cắt giữa chữ có dấu → vẫn UTF-8 hợp lệ" sh -c "sh '$QU' 2>/dev/null | grep 'không phải' | iconv -f UTF-8 -t UTF-8 >/dev/null"
dung "…và vẫn có dấu … cuối" sh -c "sh '$QU' 2>/dev/null | grep 'không phải' | grep -q '…\$'"
cp "$TMP/conv-qu.bak" "$CV"
# qu_loi <tên ca> <tìm> <thay> <chuỗi phải có trong output>
qu_loi() {
  cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" "$2" "$3"
  ky_vong 1 "$1 → KHÔNG HỢP LỆ" sh "$QU"
  dung "…nêu: $4" sh -c "sh '$QU' 2>/dev/null | grep -qF -- \"\$1\"" _ "$4"
}
qu_loi "khoá gõ sai" 'test_files: ' 'test_file: ' 'khoá lạ "test_file"'
qu_loi "khoá tên cũ (tiếng Việt)" 'base_branch: main' 'base_branch: main
nhanh_goc: main' 'khoá lạ "nhanh_goc"'
qu_loi "khoá khai hai lần" 'base_branch: main' 'base_branch: main
base_branch: develop' 'khai lần hai'
qu_loi "dòng thụt lề" 'covers_tag: ' '  covers_tag: ' 'không phải "khoá: giá trị"'
qu_loi "rules_ phase lạ" 'rules_spec:' 'rules_spek:' 'khoá lạ "rules_spek"'
qu_loi "uses_ phase lạ" 'uses_spec:' 'uses_spek:' 'khoá lạ "uses_spek"'
qu_loi "uses_ khai skill không có" 'uses_implement:' 'uses_implement: skill:khong-co' 'uses "skill:khong-co"'
qu_loi "khoá bắt buộc trống" 'branch_patterns: feat_* fix_* refactor_* perf_* chore_*' 'branch_patterns:' 'branch_patterns trống'
qu_loi "mr_platform sai" 'mr_platform:' 'mr_platform: bitbucket' 'chỉ nhận github hoặc gitlab'
qu_loi "type_by_prefix loại sai" 'perf_=perf' 'perf_=toc-do' 'loại "toc-do" không hợp lệ'
qu_loi "type_by_prefix lệch branch_patterns" 'perf_=perf' 'hieu-nang/=perf' 'không khớp branch_patterns'
qu_loi "regex dùng {n}" 'jira_key_regex: [A-Z][A-Z0-9]*-[0-9]+' 'jira_key_regex: [A-Z]{2}-[0-9]+' 'không dùng {n}'
qu_loi "regex không biên dịch" 'skipped_test_regex:' 'skipped_test_regex: (abc' 'không biên dịch được'
qu_loi "worktree_dir trong repo" 'worktree_dir: ../{repo}.wt/{ten}' 'worktree_dir: wt/{ten}' 'nằm TRONG repo'
qu_loi "worktree_dir thiếu {ten}" 'worktree_dir: ../{repo}.wt/{ten}' 'worktree_dir: ../{repo}.wt' 'thiếu {ten}'
qu_loi "knowledge_adr_dir ngoài repo" 'knowledge_adr_dir: docs/adr' 'knowledge_adr_dir: ../adr' 'phải là đường dẫn tương đối'
qu_loi "knowledge_adr_dir trong .agent-workflow" 'knowledge_adr_dir: docs/adr' 'knowledge_adr_dir: .agent-workflow/adr' 'bị exclude'
qu_loi "knowledge_adr_dir trong docs/sdlc" 'knowledge_adr_dir: docs/adr' 'knowledge_adr_dir: docs/sdlc/adr' 'gỡ khỏi branch trước MR'
qu_loi "knowledge_rules_dir ngoài repo" 'knowledge_rules_dir: docs/product/rules' 'knowledge_rules_dir: /tmp/rules' 'phải là đường dẫn tương đối'
qu_loi "base_branch không có" 'base_branch: main' 'base_branch: khong-co' 'không có trong repo'
qu_loi "scope_glob_max_files không phải số" 'scope_glob_max_files: 30' 'scope_glob_max_files: nhieu' 'scope_glob_max_files "nhieu" — số nguyên ≥ 0'
qu_loi "khối chưa đóng" 'uses_review:
```' 'uses_review:' 'chưa đóng'
cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" 'sensitive_code:
' ''
ky_vong 0 "thiếu khoá có trong mẫu → vẫn HỢP LỆ" sh "$QU"
dung "…cảnh báo thiếu khoá sensitive_code" sh -c "sh '$QU' 2>/dev/null | grep -q '! thiếu khoá sensitive_code'"
cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" 'production_code: src/*' 'production_code: app/*'
dung "production_code không khớp file nào → cảnh báo" sh -c "sh '$QU' 2>/dev/null | grep -q 'production_code \"app/\*\" không khớp file nào'"
cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" 'production_code: src/*' 'production_code: src/* test/*'
dung "file khớp cả test_files lẫn production_code → cảnh báo" sh -c "sh '$QU' 2>/dev/null | grep -q 'khớp cả test_files lẫn production_code'"
cp "$TMP/conv-qu.bak" "$CV"; thay "$CV" 'mr_platform:' 'mr_platform: bitbucket'
ky_vong 1 "aw ready: conventions.md sai → CHƯA SẴN SÀNG" sh "$SS" "$F" --no-test
dung "…nêu lỗi của aw conventions check" sh -c "sh '$SS' '$F' --no-test 2>/dev/null | grep -q 'conventions.md: mr_platform'"
cp "$TMP/conv-qu.bak" "$CV"

# ---------------------------------------------------------------- quy ước đã commit (qu_hieu_luc)
nhom "conventions.md trong repo đích + bản clone chỉ ghi đè khoá máy"
dung "repo chỉ có quy ước ở bản clone → vẫn HỢP LỆ, cảnh báo chưa commit vào repo" sh -c "sh '$QU' 2>/dev/null | grep -q '! quy ước chưa commit vào repo'"
RQ="$TMP/repo-qu"; CQ="$RQ/.git/agent-workflow"; DQ="docs/agent-workflow/conventions.md"
gq() { git -C "$RQ" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
mkdir -p "$RQ/src" "$RQ/test"; gq init -q; gq checkout -q -b main; mkdir -p "$CQ"
printf 'goc\n' > "$RQ/src/a.txt"; printf 'x\n' > "$RQ/test/a.test.js"
gq add -A; gq commit -q -m "chua co quy uoc"; GOCQ0=$(git -C "$RQ" rev-parse main)
mkdir -p "$RQ/docs/agent-workflow"; cp "$ROOT/workflow/templates/conventions.md" "$RQ/$DQ"
thay "$RQ/$DQ" 'sensitive_code:' 'sensitive_code: src/auth/*'
gq add -A; gq commit -q -m "quy uoc"
# hl <thư-mục> <khoá> -> giá trị trong conventions.md hiệu lực của thư mục đó
hl() { (AW_REPO="$1"; AW_CONFIG="$CQ"; export AW_REPO AW_CONFIG; . "$T/lib/md.sh"; conv_get "$(qu_hieu_luc "$1")" "$2"); }
quq() { (cd "$1" && AW_REPO="$1" AW_CONFIG="$CQ" sh "$QU" 2>&1); }
dung "đọc quy ước đã commit, không cần bản clone" bang "$(hl "$RQ" sensitive_code)" "src/auth/*"
ky_vong 0 "…aw conventions check → HỢP LỆ" quq "$RQ"
dung "…không còn cảnh báo chưa commit" sh -c "! (cd '$RQ' && AW_REPO='$RQ' AW_CONFIG='$CQ' sh '$QU' 2>/dev/null | grep -q 'chưa commit vào repo')"
printf '```conventions\nworktree_dir: ../wt-rieng/{ten}\n```\n' > "$CQ/conventions.md"
dung "bản clone ghi đè worktree_dir" bang "$(hl "$RQ" worktree_dir)" "../wt-rieng/{ten}"
dung "…khoá khác vẫn lấy từ repo" bang "$(hl "$RQ" sensitive_code)" "src/auth/*"
ky_vong 0 "…aw conventions check → HỢP LỆ" quq "$RQ"
printf '```conventions\nworktree_dir: ../wt-rieng/{ten}\nsensitive_code:\n```\n' > "$CQ/conventions.md"
ky_vong 1 "bản clone khai khoá ngoài khoá máy → KHÔNG HỢP LỆ" quq "$RQ"
dung "…nêu khoá đó chỉ được khai trong file đã commit" sh -c "(cd '$RQ' && AW_REPO='$RQ' AW_CONFIG='$CQ' sh '$QU' 2>/dev/null) | grep -qF 'khoá \"sensitive_code\" chỉ được khai trong $DQ'"
dung "…và không có hiệu lực: sensitive_code vẫn theo repo" bang "$(hl "$RQ" sensitive_code)" "src/auth/*"
rm -f "$CQ/conventions.md"
# worktree: luật của việc = quy ước tại điểm rẽ khỏi base ghi trong intake.md
WQ="$TMP/repo-qu.wt/feat_q"; gq worktree add -q -b feat_q "$WQ" main
mkdir -p "$WQ/.agent-workflow/feat_q"
printf -- '- **Base:** `main` `%s`\n' "$(git -C "$RQ" rev-parse main)" > "$WQ/.agent-workflow/feat_q/intake.md"
thay "$WQ/$DQ" 'sensitive_code: src/auth/*' 'sensitive_code:'
git -C "$WQ" -c user.name=t -c user.email=t@t commit -qam "noi luat" >/dev/null 2>&1
dung "worktree: việc sửa quy ước (kể cả commit) không đổi luật của chính nó" bang "$(hl "$WQ" sensitive_code)" "src/auth/*"
thay "$RQ/$DQ" 'sensitive_code: src/auth/*' 'sensitive_code: src/pay/*'
dung "…sửa ở checkout chính cũng không đổi luật của việc đang làm" bang "$(hl "$WQ" sensitive_code)" "src/auth/*"
dung "checkout chính đọc cây làm việc của nó" bang "$(hl "$RQ" sensitive_code)" "src/pay/*"
WQ2="$TMP/repo-qu.wt/feat_cu"; gq worktree add -q -b feat_cu "$WQ2" "$GOCQ0"
mkdir -p "$WQ2/.agent-workflow/feat_cu"
printf -- '- **Base:** `main` `%s`\n' "$GOCQ0" > "$WQ2/.agent-workflow/feat_cu/intake.md"
dung "việc rẽ từ base chưa có quy ước → đọc bản ở checkout chính" bang "$(hl "$WQ2" sensitive_code)" "src/pay/*"
rm -f "$WQ2/.agent-workflow/feat_cu/intake.md"
dung "worktree chưa có intake.md → đọc bản ở checkout chính" bang "$(hl "$WQ2" sensitive_code)" "src/pay/*"
ky_vong 0 "aw adapter build trong worktree" sh -c "AW_REPO='$WQ' AW_CONFIG='$CQ' sh '$T/adapter-build.sh' claude-code '$WQ'"
dung "….engine/conventions.md là quy ước hiệu lực của việc" grep -q '^sensitive_code: src/auth/\*' "$WQ/.agent-workflow/.engine/conventions.md"
cp "$RQ/$DQ" "$TMP/qu-repo.bak"
ky_vong 0 "aw init ở repo đã có quy ước" sh -c "AW_REPO='$RQ' AW_CONFIG='$CQ' AW_ENGINE='$ROOT' sh '$ROOT/bin/aw-engine' init --test-cmd true"
dung "…không tạo bản clone, không đụng file của repo" sh -c "[ ! -f '$CQ/conventions.md' ] && cmp -s '$TMP/qu-repo.bak' '$RQ/$DQ'"
# mẫu cho repo đích: AGENTS.md (điểm vào), Makefile (lệnh kiểm trong git)
MAUD="$ROOT/workflow/templates/target-repo"
dung "aw init nhắc tạo AGENTS.md khi repo chưa có" sh -c "AW_REPO='$RQ' AW_CONFIG='$CQ' AW_ENGINE='$ROOT' sh '$ROOT/bin/aw-engine' init 2>&1 | grep -q 'Repo chưa có AGENTS.md'"
printf '# AGENTS.md\n' > "$RQ/AGENTS.md"
dung "…không nhắc khi đã có" sh -c "! (AW_REPO='$RQ' AW_CONFIG='$CQ' AW_ENGINE='$ROOT' sh '$ROOT/bin/aw-engine' init 2>&1 | grep -q 'Repo chưa có AGENTS.md')"
rm -f "$RQ/AGENTS.md"
dung "mẫu AGENTS.md, Makefile có trong .agent-workflow/.engine/templates/target-repo/" sh -c "[ -f '$WQ/.agent-workflow/.engine/templates/target-repo/AGENTS.md' ] && [ -f '$WQ/.agent-workflow/.engine/templates/target-repo/Makefile' ]"
dung "mẫu AGENTS.md (bỏ chú thích) ≤ 100 dòng, có đủ mục cho phiên mới" sh -c "n=\$(sed '/^<!--/,/^-->/d' '$MAUD/AGENTS.md' | wc -l) && [ \$n -le 100 ] && for h in Map Commands Rules Decisions Status; do grep -q \"^## \$h\$\" '$MAUD/AGENTS.md' || exit 1; done"
if command -v make >/dev/null 2>&1; then
  mkdir -p "$TMP/mk"; cp "$MAUD/Makefile" "$TMP/mk/"
  ky_vong 2 "mẫu Makefile: target chưa khai → thất bại, không bao giờ xanh" make -s -C "$TMP/mk" test
  ky_vong 2 "…make security cũng thất bại khi nhóm nào chưa khai" make -s -C "$TMP/mk" security
fi
RQC="$TMP/repo-qu-cu"; mkdir -p "$RQC"; git -C "$RQC" init -q; mkdir -p "$RQC/.git/agent-workflow"
printf '# của tôi\n' > "$RQC/.git/agent-workflow/conventions.md"
ky_vong 0 "aw init ở repo chỉ có quy ước trong bản clone (init bằng engine cũ)" sh -c "AW_REPO='$RQC' AW_CONFIG='$RQC/.git/agent-workflow' AW_ENGINE='$ROOT' sh '$ROOT/bin/aw-engine' init --test-cmd true"
dung "…giữ nguyên bản clone, không tạo file trong repo" sh -c "grep -q 'của tôi' '$RQC/.git/agent-workflow/conventions.md' && [ ! -e '$RQC/$DQ' ]"
# tk_plan_t2 <dòng Verify + Status> — plan gốc, thay riêng hai dòng cuối của TSK-002
tk_plan_t2() { viet_plan; ghi_based_on; thay "$F/plan.md" '- Verify: `test -f src/a.txt` → có file
- Status: `[x]`

## Deferred' "$1

## Deferred"; }
tk_plan_t2 '- Verify: `test -f src/a.txt` → có file
- Status: `[ ]`'
dung "tiến độ: bước tiếp chỉ đúng task kế" sh -c "sh '$SS' '$F' 2>/dev/null | grep -q 'Bước tiếp: /aw-implement — task tiếp: TSK-002'"

# ---------------------------------------------------------------- aw task (task.sh)
nhom "task.sh (aw task)"
TK="$T/task.sh"; HT="$T/check-implement.sh"
dung "next → TSK-002 (stdout)" bang "$(sh "$TK" next "$F" 2>/dev/null)" "TSK-002"
ky_vong_ly_do 1 "implement chặn task chưa làm [ ]" "…đúng lý do" 'TSK-002 chưa làm' sh "$HT" "$F"
ky_vong 1 "done khi chưa start → TỪ CHỐI" sh "$TK" done "$F" TSK-002
ky_vong 0 "start TSK-002 → [~]" sh "$TK" start "$F" TSK-002
dung "…plan.md ghi [~]" grep -q '^- Status: `\[~\]`' "$F/plan.md"
ky_vong 0 "start lại task đang [~] → không lỗi" sh "$TK" start "$F" TSK-002
ky_vong 1 "start task đã [x] → TỪ CHỐI" sh "$TK" start "$F" TSK-001
thay "$F/plan.md" '- Based on: `DEC-001`
- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[x]`' '- Based on: `DEC-001`
- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[ ]`'
ky_vong 1 "WIP=1: start task khác khi TSK-002 đang [~] → TỪ CHỐI" sh "$TK" start "$F" TSK-001
dung "next ưu tiên task đang [~]" bang "$(sh "$TK" next "$F" 2>/dev/null)" "TSK-002"
ky_vong 1 "implement chặn task [~]" sh "$HT" "$F"
ky_vong 0 "done TSK-002, Verify xanh → [x]" sh "$TK" done "$F" TSK-002
dung "…ghi bằng chứng xanh vào task-results.md" sh -c "grep -q '^## TSK-002' '$F/task-results.md' && awk '/^## TSK-002/{p=1} p && /Mã thoát/{print; exit}' '$F/task-results.md' | grep -q '\`0\`'"
ky_vong 0 "start TSK-001 sau khi TSK-002 xong" sh "$TK" start "$F" TSK-001
ky_vong 0 "done TSK-001" sh "$TK" done "$F" TSK-001
ky_vong 4 "mọi task [x] → next HẾT TASK" sh "$TK" next "$F"
ky_vong 0 "implement ĐẠT khi mọi task xong bằng máy" sh "$HT" "$F"

viet_plan; ghi_based_on
mv "$F/task-results.md" "$TMP/kqt.bak"
ky_vong_ly_do 1 "implement chặn [x] tự đánh, không có bằng chứng" "…đúng lý do, chỉ lệnh sửa" 'không có bằng chứng.*aw task done' sh "$HT" "$F"
sh "$T/check-implement.sh" "$F" >/dev/null 2>&1; ghi_tree_review
ky_vong 1 "review cũng chặn [x] không có bằng chứng" sh "$T/check-review.sh" "$F"
mv "$TMP/kqt.bak" "$F/task-results.md"
thay "$F/plan.md" '- Expected files: `src/b.txt`
- Verify: `test -f src/a.txt`' '- Expected files: `src/b.txt`
- Verify: `test -d src`'
ky_vong_ly_do 1 "implement chặn khi Verify đổi sau khi task xong" "…đúng lý do" 'TSK-002: lệnh Verify trong plan.md đã đổi' sh "$HT" "$F"

# Đỏ liên tiếp → DỪNG (điều kiện dừng của vòng lặp)
viet_plan; ghi_based_on
tk_plan_t2 '- Verify: `echo VERIFY-DO; false` → xanh
- Status: `[ ]`'
sh "$TK" start "$F" TSK-002 >/dev/null 2>&1
ky_vong 1 "done, Verify đỏ → giữ [~]" sh "$TK" done "$F" TSK-002
dung "…ghi output đỏ thật" grep -q 'VERIFY-DO' "$F/task-results.md"
dung "…đỏ liên tiếp: 1" bang "$(sh -c ". '$T/lib/task.sh'; tk_bc '$F/task-results.md' TSK-002 'Đỏ liên tiếp'")" "1"
ky_vong 1 "đỏ lần 2" sh "$TK" done "$F" TSK-002
ky_vong 6 "đỏ lần 3 = MAX_RED_RUNS mặc định → DỪNG" sh "$TK" done "$F" TSK-002
ky_vong 6 "next cũng DỪNG ở task đó" sh "$TK" next "$F"
# Bộ đếm đỏ liên tiếp không về 0 chỉ vì start lại (sửa tay Status [ ] rồi start không né được DỪNG)
thay "$F/plan.md" '- Verify: `echo VERIFY-DO; false` → xanh
- Status: `[~]`' '- Verify: `echo VERIFY-DO; false` → xanh
- Status: `[ ]`'
sh "$TK" start "$F" TSK-002 >/dev/null 2>&1
dung "start lại sau DỪNG giữ bộ đếm đỏ liên tiếp" bang "$(sh -c ". '$T/lib/task.sh'; tk_bc '$F/task-results.md' TSK-002 'Đỏ liên tiếp'")" "3"
ky_vong 6 "…done đỏ lần nữa vẫn DỪNG" sh "$TK" done "$F" TSK-002
printf 'MAX_RED_RUNS=5\n' >> "$CFG/config.sh"
ky_vong 0 "MAX_RED_RUNS=5 → next còn cho làm" sh "$TK" next "$F"
cp "$TMP/ch-ss.bak" "$CFG/config.sh"
tk_plan_t2 '- Verify: `test -f src/a.txt` → xanh
- Status: `[~]`'
ky_vong 0 "sửa xong, Verify xanh → [x]" sh "$TK" done "$F" TSK-002
dung "…xanh thì đỏ liên tiếp về 0" bang "$(sh -c ". '$T/lib/task.sh'; tk_bc '$F/task-results.md' TSK-002 'Đỏ liên tiếp'")" "0"
dung "TASK_FULL_TEST tắt: done không chạy TEST_CMD" sh -c "! grep -q 'Toàn bộ test' '$F/task-results.md'"

# TASK_FULL_TEST=1: Verify xanh thì chạy thêm TEST_CMD
printf 'TASK_FULL_TEST=1\nTEST_CMD="echo TOAN-BO-DO; false"\n' >> "$CFG/config.sh"
ky_vong 1 "TASK_FULL_TEST=1: Verify xanh, toàn bộ test đỏ → ĐỎ" sh "$TK" done "$F" TSK-002
dung "…về [~]" grep -q '^- Status: `\[~\]`' "$F/plan.md"
dung "…ghi output toàn bộ test" grep -q 'TOAN-BO-DO' "$F/task-results.md"
dung "…ghi dòng Toàn bộ test ĐỎ, tính đỏ liên tiếp" sh -c "grep -q 'Toàn bộ test:.*ĐỎ' '$F/task-results.md' && sh -c \". '$T/lib/task.sh'; tk_bc '$F/task-results.md' TSK-002 'Đỏ liên tiếp'\" | grep -qx 1"
cp "$TMP/ch-ss.bak" "$CFG/config.sh"
printf 'TASK_FULL_TEST=1\nTEST_CMD="true"\n' >> "$CFG/config.sh"
ky_vong 0 "TASK_FULL_TEST=1: Verify và toàn bộ test xanh → [x]" sh "$TK" done "$F" TSK-002
dung "…ghi dòng Toàn bộ test XANH" grep -q 'Toàn bộ test:.*XANH' "$F/task-results.md"
cp "$TMP/ch-ss.bak" "$CFG/config.sh"

# Kiểm chứng thủ công
tk_plan_t2 '- Verify: mở màn hình y thấy b
- Status: `[~]`'
ky_vong 1 "Verify không có lệnh, không --manual → TỪ CHỐI" sh "$TK" done "$F" TSK-002
ky_vong 1 "--manual bằng chứng giữ chỗ → TỪ CHỐI" sh "$TK" done "$F" TSK-002 --manual "<bằng chứng>"
ky_vong 0 "--manual có bằng chứng → [x]" sh "$TK" done "$F" TSK-002 --manual "mở y, thấy b ở góc phải"
dung "implement ĐẠT kèm lưu ý task thủ công" sh -c "sh '$HT' '$F' | grep -q 'LƯU Ý.*thủ công: TSK-002'"
tk_plan_t2 '- Verify: `true` → xanh
- Status: `[~]`'
ky_vong 1 "--manual khi Verify có lệnh → TỪ CHỐI" sh "$TK" done "$F" TSK-002 --manual "đã xem"

# Phạm vi theo task: start ghi commit lúc bắt đầu; done cảnh báo file ngoài Expected files của CHÍNH task
viet_plan; ghi_based_on; rm -f "$F/task-results.md"
tk_plan_t2 '- Verify: `true` → xanh
- Status: `[ ]`'
ky_vong 0 "start ghi Started at" sh "$TK" start "$F" TSK-002
dung "…task-results.md có Started at = HEAD" bang "$(sh -c ". '$T/lib/task.sh'; tk_bc '$F/task-results.md' TSK-002 'Started at'")" "$(git -C "$R" rev-parse HEAD)"
printf 'x\n' > "$R/src/khac-pv.txt"
ky_vong 0 "done: file ngoài phần của task (thuộc task khác) → vẫn XONG" sh "$TK" done "$F" TSK-002
dung "…in CẢNH BÁO phạm vi task" sh -c "sh '$TK' done '$F' TSK-002 | grep -q 'CẢNH BÁO: TSK-002 đổi \`src/khac-pv.txt\` — ngoài Expected files của TSK-002'"
dung "…ghi Scope warning vào task-results.md" grep -q '^- Scope warning: `src/khac-pv.txt`' "$F/task-results.md"
dung "…giữ Started at sau khi done ghi lại mục" sh -c ". '$T/lib/task.sh'; [ -n \"\$(tk_bc '$F/task-results.md' TSK-002 'Started at')\" ]"
thay "$F/plan.md" '|---|---|---|---|' '|---|---|---|---|
| TSK-001 | lạc | `src/khac-pv.txt` | giữ |'
dung "Unplanned của task KHÁC không miễn → vẫn cảnh báo" sh -c "sh '$TK' done '$F' TSK-002 | grep -q 'CẢNH BÁO: TSK-002 đổi'"
thay "$F/plan.md" '| TSK-001 | lạc |' '| TSK-002 | lạc |'
dung "file khai ở Unplanned đúng task → hết cảnh báo cho file đó" sh -c "! sh '$TK' done '$F' TSK-002 | grep -q 'CẢNH BÁO: TSK-002 đổi \`src/khac-pv.txt\`'"
dung "…và không còn Scope warning cho file đó" sh -c "! grep -q 'Scope warning: .src/khac-pv.txt' '$F/task-results.md'"
# Chạy lại done trên task [x] (làm mới bằng chứng) không được gán file của task SAU cho task này
printf 'x\n' > "$R/src/sau-x.txt"
dung "chạy lại done trên task [x] → không cảnh báo file của task sau" sh -c "! sh '$TK' done '$F' TSK-002 | grep -q 'src/sau-x.txt'"
dung "…và không ghi Scope warning mới cho file đó" sh -c "! grep -q 'Scope warning: .src/sau-x.txt' '$F/task-results.md'"
rm -f "$R/src/sau-x.txt"
# Unplanned: chỉ cột "Extra files" là mẫu được phép — backtick ở cột "What came up" không miễn
printf 'x\n' > "$R/src/cot-pv.txt"
thay "$F/plan.md" '|---|---|---|---|' '|---|---|---|---|
| TSK-002 | lỡ sửa `src/cot-pv.txt` | | giữ |'
awk '/^### TSK-002/ { t = 1 } t && /^- Status:/ { $0 = "- Status: `[ ]`"; t = 0 } { print }' "$F/plan.md" > "$TMP/p" && mv "$TMP/p" "$F/plan.md"
sh "$TK" start "$F" TSK-002 >/dev/null 2>&1
dung "Unplanned: backtick ở cột What came up không miễn file" sh -c "sh '$TK' done '$F' TSK-002 | grep -q 'CẢNH BÁO: TSK-002 đổi \`src/cot-pv.txt\`'"
rm -f "$R/src/cot-pv.txt"
rm -f "$R/src/khac-pv.txt"
awk '!/^- Started at:/' "$F/task-results.md" > "$TMP/kq" && mv "$TMP/kq" "$F/task-results.md"
printf 'x\n' > "$R/src/khac-pv.txt"
dung "task không có Started at (bắt đầu ở bản cũ) → không kiểm phạm vi" sh -c "! sh '$TK' done '$F' TSK-002 | grep -q 'CẢNH BÁO'"
rm -f "$R/src/khac-pv.txt"

# Phụ thuộc
viet_plan; ghi_based_on
thay "$F/plan.md" '- Status: `[x]`' '- Status: `[ ]`'
thay "$F/plan.md" '- Status: `[x]`' '- Status: `[ ]`'
thay "$F/plan.md" '- Covers: `REQ-002`' '- Covers: `REQ-002`
- Depends on: TSK-001'
ky_vong 1 "start task phụ thuộc chưa [x] → TỪ CHỐI" sh "$TK" start "$F" TSK-002
dung "next chọn TSK-001 trước" bang "$(sh "$TK" next "$F" 2>/dev/null)" "TSK-001"
thay "$F/plan.md" '- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[ ]`' '- Expected files: `src/*` `test/*`
- Verify: `test -f src/a.txt` → có file
- Status: `[~]`'
ky_vong 2 "task không có trong plan.md: sai mã → SAI THAM SỐ" sh "$TK" start "$F" X-1
ky_vong 1 "task không có trong plan.md → TỪ CHỐI" sh "$TK" start "$F" TSK-009

# reopen: người đổi REQ / mở lại DEC → chỉ đúng task bị ảnh hưởng về [ ]
tk_st() { sh -c ". '$T/lib/task.sh'; tk_dong '$F/plan.md' $1" | cut -d'|' -f2; }
viet_plan; ghi_based_on
ky_vong 0 "reopen REQ-002 → XONG" sh "$TK" reopen "$F" REQ-002
dung "…TSK-002 (Covers REQ-002) về [ ]" bang "$(tk_st TSK-002)" " "
dung "…TSK-001 giữ [x]" bang "$(tk_st TSK-001)" "x"
viet_plan
ky_vong 0 "reopen DEC-001 → XONG" sh "$TK" reopen "$F" DEC-001
dung "…TSK-001 (Based on DEC-001) về [ ], TSK-002 giữ [x]" sh -c "[ '$(tk_st TSK-001)' = ' ' ] && [ '$(tk_st TSK-002)' = x ]"
viet_plan
thay "$F/plan.md" '- Covers: `REQ-001`' '- Covers: `REQ-001`
- On assumption: **yes** — [open-questions.md § Q-001](open-questions.md#q-001--hỏi-b)'
thay "$F/plan.md" '- Covers: `REQ-002`
- Expected files: `src/b.txt`
- Verify: `test -f src/a.txt` → có file
- Status: `[x]`' '- Covers: `REQ-002`
- Expected files: `src/b.txt`
- Verify: `test -f src/a.txt` → có file
- Status: `[~]`'
ky_vong 0 "reopen câu hỏi Q-001 theo On assumption" sh "$TK" reopen "$F" Q-001
dung "…TSK-001 (On assumption Q-001) về [ ], TSK-002 giữ [~]" sh -c "[ '$(tk_st TSK-001)' = ' ' ] && [ '$(tk_st TSK-002)' = '~' ]"
ky_vong 0 "reopen REQ, task đang [~]" sh "$TK" reopen "$F" REQ-002
dung "…TSK-002 về [ ]" bang "$(tk_st TSK-002)" " "
viet_plan
thay "$F/plan.md" '- Covers: `REQ-001`' '- Covers: `REQ-001`
- On assumption: **yes** — § REQ-001'
ky_vong 0 "reopen Q-001 không khớp \"REQ-001\" (khớp nguyên mã)" sh "$TK" reopen "$F" Q-001
dung "…TSK-001 giữ [x]" bang "$(tk_st TSK-001)" "x"
viet_plan
ky_vong 0 "reopen mã không task nào phủ (khớp nguyên mã, REQ-00 ≠ REQ-001) → không đổi gì" sh "$TK" reopen "$F" REQ-00
dung "…plan.md giữ nguyên [x]" sh -c "[ '$(tk_st TSK-001)' = x ] && [ '$(tk_st TSK-002)' = x ]"
ky_vong 2 "reopen mã không phải REQ/DEC → SAI THAM SỐ" sh "$TK" reopen "$F" TSK-001
ky_vong 2 "reopen thiếu mã → SAI THAM SỐ" sh "$TK" reopen "$F"
mv "$F/plan.md" "$TMP/plan.bak"
ky_vong 0 "reopen khi chưa có plan.md → không có gì để làm lại" sh "$TK" reopen "$F" REQ-001
mv "$TMP/plan.bak" "$F/plan.md"
viet_plan; ghi_based_on; ghi_bang_chung_task

# ---------------------------------------------------------------- trạng thái sạch
nhom "trạng thái sạch (implement/review)"
sh "$HT" "$F" >/dev/null 2>&1; ghi_tree_review
ky_vong 0 "fixture sạch → review ĐẠT" sh "$T/check-review.sh" "$F"
printf 'moi\n<<<<<<< HEAD\nx\n=======\ny\n>>>>>>> feat\n' > "$R/src/a.txt"
ky_vong 1 "implement chặn dấu xung đột merge" sh "$HT" "$F"
dung "…chỉ đúng file:dòng" sh -c "sh '$HT' '$F' | grep -q 'src/a.txt:2: còn dấu xung đột merge'"
printf 'moi\n' > "$R/src/a.txt"
printf '// covers: REQ-001, REQ-002\nit.only("a", () => {})\n' > "$R/test/a.test.js"
ky_vong 0 "test mới .only chỉ CẢNH BÁO ở implement" sh "$HT" "$F"
dung "…có in cảnh báo" sh -c "sh '$HT' '$F' | grep -q 'CẢNH BÁO.*test/a.test.js: thêm test bị bỏ qua'"
ghi_tree_review
ky_vong 1 "…review CHẶN" sh "$T/check-review.sh" "$F"
thay "$F/plan.md" '| Task | What came up | Extra files | Resolution |
|---|---|---|---|' '| Task | What came up | Extra files | Resolution |
|---|---|---|---|
| TSK-001 | test a chỉ chạy được riêng | `test/a.test.js` | người quyết |'
dung "khai file ở Unplanned → hết cảnh báo" sh -c "! sh '$HT' '$F' | grep -q 'thêm test bị bỏ qua'"
viet_plan; ghi_based_on
g checkout -q main
printf '// covers: REQ-001, REQ-002\nit.skip("cu", () => {})\n' > "$R/test/a.test.js"; g add test; g commit -q -m "test cu"
g checkout -q feat_x; g rebase -q --autostash main
dung "dòng .skip có sẵn trên base không tính (chỉ dòng thêm mới)" sh -c "! sh '$HT' '$F' | grep -q 'thêm test bị bỏ qua'"
thay "$CFG/conventions.md" 'skipped_test_regex:' 'skipped_test_regex: SKIPME'
printf 'SKIPME\n' >> "$R/test/a.test.js"
dung "skipped_test_regex riêng của repo được dùng" sh -c "sh '$HT' '$F' | grep -q 'thêm test bị bỏ qua / chạy riêng (SKIPME)'"
thay "$CFG/conventions.md" 'skipped_test_regex: SKIPME' 'skipped_test_regex:'

ket_thuc
