#!/usr/bin/env sh
# aw feature, worktree new/status/remove, nhiều adapter, input, rename, init --from-legacy, lib/result.sh.
# Chạy riêng: sh tools/tests/09-worktree-input.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
build_doi_chieu_that

# ---------------------------------------------------------------- xac dinh feature
# Từ đây: repo đích init bằng wrapper aw, engine là chính repo này (AW_ENGINE_DIR).
nhom "aw feature (feature.sh)"
unset AW_REPO AW_CONFIG
AWHD="$TMP/awhome-dev"; VDEV=$(cat "$ROOT/VERSION")
# awd <thư-mục> <tham-số...> — chạy aw đứng tại <thư-mục>
awd() { _awd=$1; shift; (cd "$_awd" && AW_HOME="$AWHD" AW_ENGINE_DIR="$ROOT" sh "$ROOT/bin/aw" "$@"); }
R9="$TMP/repo9"; mkdir -p "$R9"
git -C "$R9" init -q; git -C "$R9" checkout -q -b main
g9() { git -C "$R9" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
g9 commit -q --allow-empty -m goc
g9 tag khong-co-gi    # base không có gì của quy trình
awd "$R9" init --version "$VDEV" --test-cmd true >/dev/null 2>&1
# Repo mới: aw init tạo quy ước trong repo (chưa commit) — aw đọc bản ở checkout chính.
CV9="$R9/docs/agent-workflow/conventions.md"
ky_vong 6 "checkout chính → ĐANG Ở CHECKOUT CHÍNH (worktree bắt buộc)" awd "$R9" feature
ky_vong 6 "…kể cả khi có tham số" awd "$R9" feature feat_abc
dung "…và in danh sách việc cần làm: mở worktree / chạy /aw-intake" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature 2>&1 | grep -q 'CHECKOUT CHÍNH'"

W4="$TMP/repo9.wt/khong-khop"
g9 worktree add -q -b khong-khop "$W4" main
ky_vong 3 "trong worktree, branch không khớp, không tham số → CẦN HỎI NGƯỜI" awd "$W4" feature
dung "branch không khớp → lấy tham số" test "$(awd "$W4" feature feat_abc 2>/dev/null)" = "docs/sdlc/feat_abc"
ky_vong 2 "từ chối tên feature có ../" awd "$W4" feature "../x"
ky_vong 2 "chữ giữ chỗ <tham-số> của lệnh Cursor chưa thay → TÊN KHÔNG HỢP LỆ" awd "$W4" feature "<tham-số>"
ky_vong 2 "chữ giữ chỗ \$ARGUMENTS chưa thay → TÊN KHÔNG HỢP LỆ" awd "$W4" feature '$ARGUMENTS'
dung "…không tạo thư mục việc nào" test ! -e "$W4/.agent-workflow/<tham-số>"
dung "…stderr bảo agent chép nguyên văn phần người gõ" sh -c "cd '$W4' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature '<tham-số>' 2>&1 | grep -q 'chữ giữ chỗ'"
git -C "$W4" checkout -q -b feat_them-todo
dung "branch khớp quy ước → tên branch đầy đủ" test "$(awd "$W4" feature 2>/dev/null)" = "docs/sdlc/feat_them-todo"
dung "branch khớp thì thắng tham số" test "$(awd "$W4" feature khac 2>/dev/null)" = "docs/sdlc/feat_them-todo"
dung "in 'Đang làm với:'" sh -c "cd '$W4' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature 2>&1 >/dev/null | grep -q 'Đang làm với: docs/sdlc/feat_them-todo'"
mkdir -p "$W4/.agent-workflow/feat_them-todo"
dung "việc tạo bằng engine cũ (chỉ có .agent-workflow/<tên>/) → in đường dẫn cũ" test "$(awd "$W4" feature 2>/dev/null)" = ".agent-workflow/feat_them-todo"
dung "…và nói artifact chỉ ở máy" sh -c "cd '$W4' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature 2>&1 >/dev/null | grep -q 'engine cũ — artifact chỉ ở máy'"
mkdir -p "$W4/docs/sdlc/feat_them-todo"
dung "…có cả hai thì dùng chỗ mới" test "$(awd "$W4" feature 2>/dev/null)" = "docs/sdlc/feat_them-todo"
g9 worktree remove --force "$W4"

# ---------------------------------------------------------------- tao worktree (/aw-intake)
nhom "aw worktree new (worktree-new.sh)"
thay "$CV9" 'release_branches:' 'release_branches: release/*'
g9 branch release/1.2
DX=$(awd "$R9" worktree new bugfix phi-hoan-tien 2>/dev/null)
dung "đề xuất tên theo tiền tố của loại việc" sh -c "printf '%s' \"\$1\" | grep -q 'Tên        fix_phi-hoan-tien'" _ "$DX"
dung "…đường dẫn theo worktree_dir (ngoài repo)" sh -c "printf '%s' \"\$1\" | grep -qF '$TMP/repo9.wt/fix_phi-hoan-tien'" _ "$DX"
dung "…liệt kê nhánh phát hành làm ứng viên base" sh -c "printf '%s' \"\$1\" | grep -q 'release/1.2'" _ "$DX"
dung "…gợi ý ★ base_branch khi không có remote" sh -c "printf '%s' \"\$1\" | grep -q '★ \[1\] main'" _ "$DX"
dung "…không còn đòi base có bộ cài" sh -c "! printf '%s' \"\$1\" | grep -q 'bộ cài'" _ "$DX"
dung "…lệnh tạo in bằng aw, cờ tiếng Anh" sh -c "printf '%s' \"\$1\" | grep -q 'aw worktree new bugfix phi-hoan-tien --create --base <ref>'" _ "$DX"
dung "…chỉ đề xuất: chưa tạo branch, chưa tạo worktree" sh -c "! git -C '$R9' rev-parse --verify --quiet refs/heads/fix_phi-hoan-tien && [ ! -e '$TMP/repo9.wt/fix_phi-hoan-tien' ]"
ky_vong 2 "từ chối loại việc không có tiền tố" awd "$R9" worktree new utils x
ky_vong 2 "từ chối mô tả không phải chữ thường ASCII" awd "$R9" worktree new bugfix "Phi Hoan"
ky_vong 2 "--create thiếu --base → từ chối (agent không tự chọn base)" awd "$R9" worktree new bugfix phi-hoan-tien --create
ky_vong 2 "--base không kèm --create → từ chối" awd "$R9" worktree new bugfix phi-hoan-tien --base main
ky_vong 2 "từ chối ref không tồn tại" awd "$R9" worktree new bugfix phi-hoan-tien --create --base khong-co
# Gán rồi unset, không "X=… ky_vong": bash 3.2 (sh của macOS) giữ biến gán trước lời gọi hàm.
AW_WORKTREE_DIR='.worktrees/{ten}'; export AW_WORKTREE_DIR
ky_vong 2 "từ chối worktree nằm trong repo" awd "$R9" worktree new bugfix phi-hoan-tien
unset AW_WORKTREE_DIR
dung "AW_WORKTREE_DIR ghi đè vị trí theo máy" sh -c "cd '$R9' && AW_WORKTREE_DIR='$TMP/rieng/{repo}/{ten}' AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new bugfix phi-hoan-tien 2>/dev/null | grep -qF '$TMP/rieng/repo9/fix_phi-hoan-tien'"

GOC9=$(git -C "$R9" rev-parse main)
ky_vong 0 "base không có gì của quy trình vẫn tạo được worktree" awd "$R9" worktree new chore khong-bo-cai --create --base khong-co-gi
W0="$TMP/repo9.wt/chore_khong-bo-cai"
dung "…worktree mới có adapter sinh sẵn" test -f "$W0/.claude/commands/aw-spec.md"
dung "…file adapter bị exclude: worktree sạch" sh -c "[ -z \"\$(git -C '$W0' status --porcelain)\" ]"
dung "…artifact viết vào cũng bị exclude" sh -c "mkdir -p '$W0/.agent-workflow/chore_khong-bo-cai' && printf x > '$W0/.agent-workflow/chore_khong-bo-cai/intake.md' && [ -z \"\$(git -C '$W0' status --porcelain)\" ]"
dung "…docs/sdlc/ (artifact kiểu mới) cũng bị exclude: chỉ vào git khi aw check commit" sh -c "mkdir -p '$W0/docs/sdlc/chore_khong-bo-cai' && printf x > '$W0/docs/sdlc/chore_khong-bo-cai/intake.md' && [ -z \"\$(git -C '$W0' status --porcelain)\" ] && grep -qx '/docs/sdlc/' '$R9/.git/info/exclude'"
dung "…không có commit nào vào base; checkout chính chỉ còn quy ước chờ commit" sh -c "[ \"\$(git -C '$R9' rev-parse main)\" = '$GOC9' ] && [ \"\$(git -C '$R9' status --porcelain --untracked-files=all)\" = '?? docs/agent-workflow/conventions.md' ]"
ky_vong 0 "--create --base <ref người chọn> thì tạo worktree" awd "$R9" worktree new bugfix phi-hoan-tien --create --base main
W5="$TMP/repo9.wt/fix_phi-hoan-tien"
dung "…worktree ở đúng chỗ, đúng branch" test "$(git -C "$W5" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "fix_phi-hoan-tien"
dung "…branch không có upstream (git push trơn không đẩy lên nhánh gốc)" sh -c "! git -C '$W5' rev-parse --abbrev-ref '@{upstream}' 2>/dev/null"
dung "…checkout chính vẫn đứng ở main" test "$(git -C "$R9" rev-parse --abbrev-ref HEAD)" = "main"
dung "…in dòng Base và Engine để chép vào intake.md" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new chore in-base --create --base main 2>&1 >/dev/null | grep -q '\*\*Base:\*\* \`main\` @ \`' && git -C '$R9' worktree list | grep -q chore_in-base"
dung "…dòng Engine đúng version engine" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new chore in-engine --create --base main 2>&1 >/dev/null | grep -qx '  - \*\*Engine:\*\* $VDEV'"
dung "…stdout chỉ là đường dẫn worktree" bang "$(awd "$R9" worktree new chore in-stdout --create --base main 2>/dev/null)" "$TMP/repo9.wt/chore_in-stdout"
dung "…và aw feature trong worktree suy được feature" test "$(awd "$W5" feature 2>/dev/null)" = "docs/sdlc/fix_phi-hoan-tien"
ky_vong 5 "chạy lại cho việc đã có worktree → ĐÃ CÓ WORKTREE, không tạo gì" awd "$R9" worktree new bugfix phi-hoan-tien
dung "…stdout là đường dẫn worktree đã có" test "$(awd "$R9" worktree new bugfix phi-hoan-tien 2>/dev/null)" = "$W5"

# remote: main local chậm hơn origin/main -> ★ origin/main
RM="$TMP/remote9.git"; git init -q --bare "$RM"
g9 remote add origin "$RM"; g9 push -q origin main
KH="$TMP/khac9"; git clone -q -b main "$RM" "$KH" 2>/dev/null
git -C "$KH" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "cua dong nghiep" && git -C "$KH" push -q origin HEAD:main 2>/dev/null
g9 fetch -q origin
DX=$(awd "$R9" worktree new feature co-remote 2>/dev/null)
dung "main chậm origin/main → ★ gợi ý origin/main" sh -c "printf '%s' \"\$1\" | grep -q '★ \[2\] origin/main'" _ "$DX"
dung "…và ghi rõ main chậm bao nhiêu commit" sh -c "printf '%s' \"\$1\" | grep -q 'chậm 1 commit so với origin/main'" _ "$DX"
g9 commit -q --allow-empty -m "local chua push"
DX=$(awd "$R9" worktree new feature co-remote 2>/dev/null)
dung "main và origin/main phân kỳ → không gợi ý ★" sh -c "printf '%s' \"\$1\" | grep -q 'PHÂN KỲ' && ! printf '%s' \"\$1\" | grep -q '★ \['" _ "$DX"
g9 reset -q --hard HEAD~1

# ---------------------------------------------------------------- nhiều adapter
# Team dùng cả Claude Code lẫn Cursor: ADAPTER="claude-code cursor" trong config.sh.
nhom "nhiều adapter (ADAPTER=\"claude-code cursor\")"
R10="$TMP/repo10"; mkdir -p "$R10"
git -C "$R10" init -q; git -C "$R10" checkout -q -b main
git -C "$R10" -c user.name=t -c user.email=t@t commit -q --allow-empty -m goc
GOC10=$(git -C "$R10" rev-parse HEAD); C10="$R10/.git/agent-workflow"
ky_vong 2 "init --adapter có id không tồn tại → SAI THAM SỐ" awd "$R10" init --version "$VDEV" --adapter claude-code,khong-co
dung "…không ghi config.sh, không sinh gì" sh -c "[ ! -e '$C10/config.sh' ] && [ ! -e '$R10/.claude' ] && [ ! -e '$R10/.cursor' ]"
ky_vong 2 "init --adapter rỗng → SAI THAM SỐ" awd "$R10" init --version "$VDEV" --adapter ","
ky_vong 0 "aw init --adapter claude-code,cursor" awd "$R10" init --version "$VDEV" --test-cmd true --adapter claude-code,cursor
dung "…config.sh ghi ADAPTER=\"claude-code cursor\"" grep -qx 'ADAPTER="claude-code cursor"' "$C10/config.sh"
dung "…exclude có đường dẫn của MỌI adapter" sh -c \
  "for p in /.agent-workflow/ /.claude/commands/aw-*.md /.claude/agents/independent-reviewer.md /.claude/skills/agent-workflow/ /.cursor/commands/aw-*.md /.cursor/agents/spec-checker.md /.cursor/skills/agent-workflow/; do grep -qxF \"\$p\" '$R10/.git/info/exclude' || exit 1; done"
dung "…sinh cả hai bộ ở checkout chính" sh -c "[ -f '$R10/.claude/commands/aw-intake.md' ] && [ -f '$R10/.cursor/commands/aw-intake.md' ] && [ -f '$R10/.cursor/agents/independent-reviewer.md' ]"
dung "…cả hai bộ giống hệt build riêng (không ảnh hưởng nhau)" sh -c "diff -r '$R10/.claude' '$TMP/doi-chieu-that/claude-code/.claude' && diff -r '$R10/.cursor' '$TMP/doi-chieu-that/cursor/.cursor'"
dung "…dấu build ghi cả hai, đúng version" bang "$(cat "$R10/.agent-workflow/.adapters")" "claude-code $VDEV
cursor $VDEV"
dung "…không commit gì; cây chỉ còn quy ước chờ commit" sh -c "[ \"\$(git -C '$R10' rev-parse HEAD)\" = '$GOC10' ] && [ \"\$(git -C '$R10' status --porcelain --untracked-files=all)\" = '?? docs/agent-workflow/conventions.md' ]"
ky_vong 0 "init lại: cùng tập adapter, khác thứ tự/cách viết → không coi là đổi" awd "$R10" init --adapter "cursor claude-code"
dung "…không nhân đôi dòng exclude" bang "$(grep -cxF "/.cursor/agents/spec-checker.md" "$R10/.git/info/exclude")" 1
ky_vong 2 "init --adapter khác tập trong config.sh → SAI THAM SỐ (sửa config.sh)" awd "$R10" init --adapter cursor
dung "…config.sh giữ nguyên" grep -qx 'ADAPTER="claude-code cursor"' "$C10/config.sh"
ky_vong 0 "aw doctor: mọi mục ✓ với hai adapter" awd "$R10" doctor
dung "…doctor không cảnh báo dòng exclude cũ khi chỉ có mẫu hẹp" sh -c "cd '$R10' && ! AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor 2>/dev/null | grep -q dòng cũ"
printf '/.claude/\n' >> "$R10/.git/info/exclude"
ky_vong 0 "doctor: dòng /.claude/ cũ trong exclude → chỉ cảnh báo, không ✗" awd "$R10" doctor
dung "…cảnh báo nêu dòng cũ và cách xoá" sh -c "cd '$R10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor 2>/dev/null | grep -q '! info/exclude còn dòng cũ /.claude/ .*Xoá dòng đó'"
ky_vong 0 "init lại không tự sửa exclude của người dùng" awd "$R10" init
grep -vxF /.claude/ "$R10/.git/info/exclude" > "$R10/.git/exclude.tmp"; mv "$R10/.git/exclude.tmp" "$R10/.git/info/exclude"
dung "…liệt kê từng adapter của worktree" sh -c "cd '$R10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor 2>/dev/null | grep -q '✓ cursor (engine $VDEV)'"

W10=$(awd "$R10" worktree new feature hai-agent --create --base main 2>/dev/null)
dung "worktree mới có cả .claude/ và .cursor/" sh -c "[ -n '$W10' ] && [ -f '$W10/.claude/commands/aw-spec.md' ] && [ -f '$W10/.cursor/commands/aw-spec.md' ]"
dung "…giống hệt build riêng" sh -c "diff -r '$W10/.claude' '$TMP/doi-chieu-that/claude-code/.claude' && diff -r '$W10/.cursor' '$TMP/doi-chieu-that/cursor/.cursor'"
dung "…worktree sạch (mọi file sinh ra bị exclude)" sh -c "[ -z \"\$(git -C '$W10' status --porcelain --untracked-files=all)\" ]"
dung "…dấu build của worktree có cả hai" sh -c "grep -q '^claude-code ' '$W10/.agent-workflow/.adapters' && grep -q '^cursor ' '$W10/.agent-workflow/.adapters'"
dung "…aw feature trong worktree suy được feature (cả hai agent dùng chung)" test "$(awd "$W10" feature 2>/dev/null)" = "docs/sdlc/feat_hai-agent"

# doctor thấy worktree thiếu bộ lệnh của một agent
awk '$1 != "cursor"' "$W10/.agent-workflow/.adapters" > "$TMP/dau.tmp" && mv "$TMP/dau.tmp" "$W10/.agent-workflow/.adapters"
ky_vong 1 "doctor: worktree chưa sinh adapter cursor → ✗" awd "$W10" doctor
dung "…chỉ đúng adapter thiếu và lệnh sửa" sh -c "cd '$W10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor 2>/dev/null | grep -q '✗ cursor chưa được sinh — chạy: aw adapter build'"
ky_vong 0 "aw adapter build cursor (một adapter)" awd "$W10" adapter build cursor
dung "…dấu build giữ dòng claude-code, thêm lại cursor (đúng hai dòng)" sh -c \
  "[ \"\$(wc -l < '$W10/.agent-workflow/.adapters' | tr -d ' ')\" = 2 ] && grep -q '^claude-code ' '$W10/.agent-workflow/.adapters' && grep -q '^cursor ' '$W10/.agent-workflow/.adapters'"
ky_vong 0 "doctor lại ✓" awd "$W10" doctor
sed 's/^claude-code .*/claude-code 2000.1.1/' "$W10/.agent-workflow/.adapters" > "$TMP/dau.tmp" && mv "$TMP/dau.tmp" "$W10/.agent-workflow/.adapters"
ky_vong 0 "doctor: bộ lệnh sinh từ engine khác chỉ là thông tin (việc có thể ghim engine cũ)" awd "$W10" doctor
dung "…nói rõ version của bộ lệnh và của bản clone" sh -c "cd '$W10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor 2>/dev/null | grep -q 'claude-code sinh từ engine 2000.1.1, bản clone dùng $VDEV'"
rm -rf "$W10/.cursor" "$W10/.claude"
ky_vong 0 "aw adapter build (không id) → mọi adapter trong config.sh" awd "$W10" adapter build
dung "…sinh lại cả hai, dấu build đúng version" sh -c "[ -f '$W10/.claude/commands/aw-plan.md' ] && [ -f '$W10/.cursor/commands/aw-plan.md' ] && [ \"\$(cat '$W10/.agent-workflow/.adapters')\" = 'claude-code $VDEV
cursor $VDEV' ]"
rm -rf "$W10/.cursor"
ky_vong 2 "aw adapter build claude-code,khong-co → SAI THAM SỐ" awd "$W10" adapter build claude-code,khong-co
dung "…không sinh adapter nào" test ! -e "$W10/.cursor"
awd "$W10" adapter build >/dev/null 2>&1
rm -f "$W10/.agent-workflow/.adapters"
ky_vong 0 "doctor: worktree tạo bằng engine cũ (chưa có dấu build) → chỉ nhắc, không ✗" awd "$W10" doctor
awd "$W10" adapter build >/dev/null 2>&1

# config.sh do NGƯỜI sửa: dấu phẩy, id sai, bỏ trống
cp "$C10/config.sh" "$TMP/config10.bak"
sed 's/^ADAPTER=.*/ADAPTER="cursor,claude-code"/' "$TMP/config10.bak" > "$C10/config.sh"
W11=$(awd "$R10" worktree new chore dau-phay --create --base main 2>/dev/null)
dung "ADAPTER viết bằng dấu phẩy → worktree có cả hai bộ" sh -c "[ -f '$W11/.claude/commands/aw-spec.md' ] && [ -f '$W11/.cursor/commands/aw-spec.md' ]"
sed 's/^ADAPTER=.*/ADAPTER=""/' "$TMP/config10.bak" > "$C10/config.sh"
W12=$(awd "$R10" worktree new chore bo-trong --create --base main 2>/dev/null)
dung "ADAPTER bỏ trống → chỉ claude-code (như trước khi có nhiều adapter)" sh -c "[ -f '$W12/.claude/commands/aw-spec.md' ] && [ ! -e '$W12/.cursor' ]"
sed 's/^ADAPTER=.*/ADAPTER="claude-code khong-co"/' "$TMP/config10.bak" > "$C10/config.sh"
ky_vong 0 "ADAPTER có id sai → worktree vẫn tạo được" awd "$R10" worktree new chore id-sai --create --base main
dung "…nhưng cảnh báo rõ, không sinh nửa vời" sh -c "cd '$R10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree new chore id-sai-2 --create --base main 2>&1 >/dev/null | grep -q 'CẢNH BÁO: ADAPTER=\"claude-code khong-co\"' && [ ! -e '$TMP/repo10.wt/chore_id-sai-2/.claude' ]"
ky_vong 1 "doctor: ADAPTER khai id engine không có → ✗" awd "$R10" doctor
cp "$TMP/config10.bak" "$C10/config.sh"
dung "…sửa lại thì doctor ✓" sh -c "cd '$R10' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' doctor >/dev/null 2>&1"

# ---------------------------------------------------------------- don worktree
nhom "aw worktree status|remove (worktree-cleanup.sh)"
ky_vong 0 "status: chỉ in trạng thái" awd "$R9" worktree status fix_phi-hoan-tien
dung "…worktree còn nguyên" test -d "$W5"
printf 'nhap\n' > "$W5/nhap.txt"
ky_vong 7 "còn file chưa track → chặn remove" awd "$R9" worktree remove fix_phi-hoan-tien
dung "…worktree còn nguyên" test -f "$W5/nhap.txt"
rm -f "$W5/nhap.txt"
ky_vong 7 "đứng trong chính worktree cần dọn → chặn" awd "$W5" worktree remove fix_phi-hoan-tien
ky_vong 2 "--delete-branch với status → sai tham số" awd "$R9" worktree status fix_phi-hoan-tien --delete-branch
ky_vong 2 "branch không có worktree → sai tham số" awd "$R9" worktree status release/1.2
mkdir -p "$W5/.agent-workflow/fix_phi-hoan-tien"; printf 'artifact\n' > "$W5/.agent-workflow/fix_phi-hoan-tien/spec.md"
mkdir -p "$W5/docs/sdlc/fix_phi-hoan-tien"; printf 'da ship\n' > "$W5/docs/sdlc/fix_phi-hoan-tien/ship.md"
dung "status báo sẽ chép artifact vào archive" sh -c "cd '$R9' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' worktree status fix_phi-hoan-tien 2>/dev/null | grep -q 'archive/fix_phi-hoan-tien'"
git -C "$W5" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "sua phi"
ky_vong 7 "chưa merge: gỡ worktree nhưng git từ chối xoá branch" awd "$R9" worktree remove fix_phi-hoan-tien --delete-branch
dung "…worktree đã gỡ, branch còn nguyên (không mất commit)" sh -c "[ ! -e '$W5' ] && git -C '$R9' rev-parse --verify --quiet refs/heads/fix_phi-hoan-tien"
dung "…artifact (bị exclude) được chép vào .git/agent-workflow/archive/ trước khi gỡ" grep -qx artifact "$R9/.git/agent-workflow/archive/fix_phi-hoan-tien/fix_phi-hoan-tien/spec.md"
dung "…cả artifact kiểu mới (docs/sdlc/, đã gỡ khỏi branch) cùng chỗ" grep -qx 'da ship' "$R9/.git/agent-workflow/archive/fix_phi-hoan-tien/fix_phi-hoan-tien/ship.md"
W6="$TMP/repo9.wt/chore_in-base"
ky_vong 0 "đã merge: remove --delete-branch gỡ worktree và xoá branch" awd "$R9" worktree remove chore_in-base --delete-branch
dung "…cả worktree lẫn branch đều không còn" sh -c "[ ! -e '$W6' ] && ! git -C '$R9' rev-parse --verify --quiet refs/heads/chore_in-base"

IN="$R9/.claude/commands/aw-intake.md"
dung "/aw-intake: tham số là input, không truyền vào aw feature" sh -c "grep -q 'argument-hint: \"\\[mã-issue' '$IN' && ! grep -q 'aw feature \$ARGUMENTS' '$IN'"
dung "/aw-intake: đang ở checkout chính thì dẫn tới aw worktree new" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*aw worktree new' "$IN"
dung "lệnh khác: ĐANG Ở CHECKOUT CHÍNH thì dừng lại" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*stop' "$R9/.claude/commands/aw-spec.md"
dung "lệnh khác vẫn nhận tên feature qua tham số" grep -q 'aw feature \$ARGUMENTS' "$R9/.claude/commands/aw-spec.md"
dung "/aw-intake: tham số đi qua aw input bằng heredoc nguyên văn" sh -c "grep -q 'aw input .*- <<' '$IN' && grep -qx '\$ARGUMENTS' '$IN'"
dung "aw init chép rules/templates/checkers của engine vào .agent-workflow/.engine/ (bị exclude)" sh -c "[ -f '$R9/.agent-workflow/.engine/templates/spec.md' ] && [ -f '$R9/.agent-workflow/.engine/rules/general.md' ] && grep -qx '$VDEV' '$R9/.agent-workflow/.engine/VERSION'"
dung "…conventions.md trong đó trỏ tới cấu hình của bản clone" sh -c "grep -q '^branch_patterns:' '$R9/.agent-workflow/.engine/conventions.md'"
dung "mọi đường dẫn .agent-workflow/.engine/… mà lệnh sinh ra nhắc tới đều có thật" sh -c "cd '$R9' && for p in \$(grep -rhoE '\.agent-workflow/\.engine/[A-Za-z0-9_./-]+\.md' .claude | sort -u); do [ -e \"\$p\" ] || { echo \$p; exit 1; }; done"

# ---------------------------------------------------------------- phan loai input (/aw-intake)
nhom "aw input (input.sh)"
mkdir -p "$R9/docs"; printf 'x\n' > "$R9/docs/a.md"
# ra <tham-số...> -> stdout; loi <tham-số...> -> stderr
ra() { awd "$R9" input "$@" 2>/dev/null; }
loi() { awd "$R9" input "$@" 2>&1 >/dev/null; }
pl() { awd "$R9" input "$@"; }
BT='`'

ky_vong 0 "mã Jira + file có thật → nguồn" pl "ABC-123 docs/a.md"
dung "…đúng nhãn [JIRA] và [FILE]" bang "$(ra 'ABC-123 docs/a.md')" "- ${BT}[JIRA]${BT} ABC-123
- ${BT}[FILE]${BT} docs/a.md"
dung "URL …/browse/<mã> → [JIRA] với mã tách ra" bang "$(ra 'https://x.atlassian.net/browse/ABC-9')" "- ${BT}[JIRA]${BT} ABC-9 — https://x.atlassian.net/browse/ABC-9"
dung "chưa khai confluence_domains: URL khác → [CONFLUENCE]" bang "$(ra 'https://wiki.co/p/1')" "- ${BT}[CONFLUENCE]${BT} https://wiki.co/p/1"
dung "…kèm cảnh báo chưa khai confluence_domains" sh -c "printf '%s' \"\$1\" | grep -q confluence_domains" _ "$(loi 'https://wiki.co/p/1')"
dung "bỏ dấu câu / ngoặc bọc ngoài: (ABC-1), \`docs/a.md\`" bang "$(ra '(ABC-1), `docs/a.md`.')" "- ${BT}[JIRA]${BT} ABC-1
- ${BT}[FILE]${BT} docs/a.md"
dung "cùng một nguồn gõ nhiều cách → một dòng" bang "$(ra 'ABC-1 ABC-1 https://x.atlassian.net/browse/ABC-1' | wc -l | tr -d ' ')" 1
ky_vong 1 "đường dẫn không tồn tại → ĐƯỜNG DẪN KHÔNG TỒN TẠI (không tự đoán)" pl "ABC-1 docs/khong-co.md"
dung "…và không in dòng input nào" test -z "$(ra 'ABC-1 docs/khong-co.md')"
ky_vong 3 "không có tham số → KHÔNG CÓ THAM SỐ (hỏi người dùng)" pl ""
ky_vong 3 "tham số chỉ có khoảng trắng / dòng trống → KHÔNG CÓ THAM SỐ" pl "
  "
ky_vong 4 "câu chữ tự do → LỜI NGƯỜI DÙNG" pl "sửa phí hoàn tiền bị âm ABC-123"
ky_vong 2 "chữ giữ chỗ <tham-số> còn nguyên → SAI CÁCH GỌI (không thành mục [HUMAN])" pl "<tham-số>"
ky_vong 2 "chữ giữ chỗ \$ARGUMENTS còn nguyên → SAI CÁCH GỌI" pl '$ARGUMENTS'
ky_vong 2 "…kể cả có khoảng trắng / dòng trống bao quanh" pl "
  <tham-số>
"
dung "…và không in dòng input nào" test -z "$(ra '<tham-số>')"
ky_vong 4 "câu thật có nhắc chữ <tham-số> vẫn là LỜI NGƯỜI DÙNG" pl "sửa lỗi hiển thị <tham-số> trong trang"
# Chạy NGUYÊN VĂN khối aw input do adapter sinh ra, như agent quên thay tham số
for ad in claude-code cursor; do
  case $ad in claude-code) f="$TMP/doi-chieu-that/claude-code/.claude/commands/aw-intake.md" ;; *) f="$TMP/doi-chieu-that/cursor/.cursor/commands/aw-intake.md" ;; esac
  awk '/^```sh$/ { k = 1; next } k && /^```$/ { exit } k' "$f" | sed 's/^aw input \[--skip [^]]*\] /aw input /' > "$TMP/khoi-input-$ad.sh"
  dung "$ad: khối aw input trong /aw-intake là lệnh chạy được (có heredoc HET_INPUT)" sh -c "grep -q '^aw input - <<.HET_INPUT.\$' '$TMP/khoi-input-$ad.sh' && tail -1 '$TMP/khoi-input-$ad.sh' | grep -qx HET_INPUT"
  ky_vong 2 "$ad: chạy khối đó khi chưa thay tham số → engine chặn (SAI CÁCH GỌI)" sh -c "cd '$R9' && aw() { AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' \"\$@\"; } && . '$TMP/khoi-input-$ad.sh'"
  sed 's/^<tham-số>$/ABC-123/; s/^\$ARGUMENTS$/ABC-123/' "$TMP/khoi-input-$ad.sh" > "$TMP/khoi-input-$ad-thay.sh"
  dung "$ad: …thay đúng tham số thì ra nhãn [JIRA]" sh -c "cd '$R9' && aw() { AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' \"\$@\"; } && . '$TMP/khoi-input-$ad-thay.sh' 2>/dev/null | grep -q 'JIRA.* ABC-123'"
done
dung "…cả chuỗi là MỘT mục [HUMAN] nguyên văn" bang "$(ra 'sửa phí hoàn tiền bị âm ABC-123')" "- ${BT}[HUMAN]${BT}
  > sửa phí hoàn tiền bị âm ABC-123"
dung "…mã Jira trong câu chỉ là ĐỀ XUẤT (stderr)" sh -c "printf '%s\n' \"\$1\" | grep -A3 'Đề xuất tách thêm' | grep -q 'ABC-123'" _ "$(loi 'sửa phí hoàn tiền bị âm ABC-123')"
ky_vong 4 "đường dẫn không có file nằm trong câu chữ thì không chặn" pl "sửa lỗi trong src/khong-co.js"

cp "$CV9" "$TMP/conv.bak"
sed 's#^confluence_domains:.*#confluence_domains: *.atlassian.net/wiki#' "$TMP/conv.bak" > "$CV9"
dung "khai confluence_domains: URL khớp → [CONFLUENCE]" bang "$(ra 'https://x.atlassian.net/wiki/spaces/A/pages/1')" "- ${BT}[CONFLUENCE]${BT} https://x.atlassian.net/wiki/spaces/A/pages/1"
ky_vong 4 "khai confluence_domains: URL lạ → lời người dùng" pl "https://github.com/a/b"
ky_vong 4 "khai confluence_domains: miền giả mạo x.atlassian.net.evil.com → không nhận" pl "https://x.atlassian.net.evil.com/wiki/p/1"
dung "khai confluence_domains: URL có query vẫn khớp" bang "$(ra 'https://x.atlassian.net/wiki?p=1')" "- ${BT}[CONFLUENCE]${BT} https://x.atlassian.net/wiki?p=1"
printf '%s\n' '```conventions' 'branch_patterns: feat_*' '```' > "$CV9"
ky_vong 0 "conventions.md cũ chưa có jira_key_regex → dùng mặc định" pl "ABC-1"
cp "$TMP/conv.bak" "$CV9"

# nguyen van qua stdin: dau nhay, $, backtick, nhieu dong khong bi shell dien giai
awd "$R9" input - > "$TMP/nv.out" 2>/dev/null <<'HET_INPUT'

Sửa "phí" khi $amount < 0 — xem `x`
dòng hai
HET_INPUT
dung "stdin: nguyên văn giữ dấu nháy, \$, backtick, nhiều dòng" bang "$(cat "$TMP/nv.out")" "- ${BT}[HUMAN]${BT}
  > Sửa \"phí\" khi \$amount < 0 — xem ${BT}x${BT}
  > dòng hai"

# --skip: chay lai /aw-intake = gop them
cat > "$TMP/intake-cu.md" <<'HET'
- **Type:** `feature`
- **Goal:** x

## Input

- `[JIRA]` [ABC-123](https://x.atlassian.net/browse/ABC-123)
- `[FILE]` ./docs/a.md
- `[HUMAN]`
  > sửa phí   hoàn tiền
  > bị âm
HET
dung "--skip: bỏ input đã có, chỉ in input mới" bang "$(ra --skip "$TMP/intake-cu.md" 'ABC-123 docs/a.md ABC-7')" "- ${BT}[JIRA]${BT} ABC-7"
ky_vong 0 "--skip: không có gì mới vẫn là NGUỒN" pl --skip "$TMP/intake-cu.md" "https://x.atlassian.net/browse/ABC-123"
dung "…URL …/browse/ABC-123 trùng với ABC-123 đã có → stdout rỗng" test -z "$(ra --skip "$TMP/intake-cu.md" 'https://x.atlassian.net/browse/ABC-123')"
dung "--skip: lời người dùng đã có (khác khoảng trắng / xuống dòng) → bỏ" test -z "$(ra --skip "$TMP/intake-cu.md" 'sửa phí hoàn tiền bị âm')"
dung "--skip: lời người dùng mới thì vẫn in" bang "$(ra --skip "$TMP/intake-cu.md" 'thêm xuất CSV' | tail -1)" "  > thêm xuất CSV"
ky_vong 2 "--skip trỏ tới file không có → SAI CÁCH GỌI" pl --skip "$TMP/khong-co.md" "ABC-1"

# ---------------------------------------------------------------- doi ten feature
nhom "aw rename (rename-feature.sh)"
unset AW_REPO AW_CONFIG
ky_vong 2 "từ chối chạy ở checkout chính" awd "$R9" rename feat_x
W7="$TMP/repo9.wt/fix_sai-loai"
g9 worktree add -q -b fix_sai-loai "$W7" main
mkdir -p "$W7/.agent-workflow/fix_sai-loai"; printf 'x\n' > "$W7/.agent-workflow/fix_sai-loai/intake.md"
mkdir -p "$TMP/repo9.wt/feat_khac"
ky_vong 2 "từ chối khi thư mục worktree đích đã tồn tại" awd "$W7" rename feat_khac
dung "…và không đổi gì" sh -c "[ -d '$W7' ] && git -C '$R9' rev-parse --verify --quiet refs/heads/fix_sai-loai"
ky_vong 0 "đổi tên thành công (chạy trong worktree)" awd "$W7" rename feat_dung-loai
W8="$TMP/repo9.wt/feat_dung-loai"
dung "branch đã đổi tên" sh -c "git -C '$R9' rev-parse --verify --quiet refs/heads/feat_dung-loai && ! git -C '$R9' rev-parse --verify --quiet refs/heads/fix_sai-loai"
dung "worktree dời sang tên mới, cùng thư mục cha" sh -c "[ ! -e '$W7' ] && [ \"\$(git -C '$W8' rev-parse --abbrev-ref HEAD)\" = feat_dung-loai ]"
dung "thư mục artifact dời theo" sh -c "[ -f '$W8/.agent-workflow/feat_dung-loai/intake.md' ] && [ ! -d '$W8/.agent-workflow/fix_sai-loai' ]"

# ---------------------------------------------------------------- chuyen tu bo cai 1.x
nhom "aw init --from-legacy (chuyển từ bộ cài 1.x)"
ky_vong 3 "tools/install.sh chỉ in hướng dẫn, không cài gì" sh "$T/install.sh" "$TMP/khong-quan-trong"
dung "…hướng dẫn dùng aw init / aw init --from-legacy" sh -c "sh '$T/install.sh' 2>/dev/null | grep -q 'aw init --from-legacy'"
ky_vong 3 "tools/sync.sh chỉ in hướng dẫn aw upgrade" sh "$T/sync.sh"
dung "…nhắc aw upgrade" sh -c "sh '$T/sync.sh' 2>/dev/null | grep -q 'aw upgrade'"

# Repo đích có bộ cài 1.x đã commit vào base (dựng tay đúng cấu trúc cũ)
RL="$TMP/repo-cu"; mkdir -p "$RL/.agent-workflow/.quy-trinh/tools" "$RL/.claude/commands" "$RL/.agent-workflow/feat_cu"
git -C "$RL" init -q; git -C "$RL" checkout -q -b main
printf '# quy ước cũ của team\n```conventions\nbranch_patterns: feat_* chore_*\ntype_by_prefix: feat_=feature chore_=chore\nbase_branch: main\n```\n' > "$RL/.agent-workflow/conventions.md"
printf 'LENH_KIEM_THU="make test"\nLENH_CHUAN_BI_WT="npm ci"\n' > "$RL/.agent-workflow/.quy-trinh/cau-hinh.sh"
printf 'url=x\nadapter=claude-code\n' > "$RL/.agent-workflow/.quy-trinh/nguon.txt"
printf 'echo cu\n' > "$RL/.agent-workflow/.quy-trinh/tools/feature.sh"
printf -- '---\n---\n> **File này được SINH TỰ ĐỘNG** — bản 1.x\nsh .agent-workflow/.quy-trinh/tools/x.sh\n' > "$RL/.claude/commands/aw-spec.md"
printf '# lệnh team tự viết\n' > "$RL/.claude/commands/cua-team.md"
printf 'x\n' > "$RL/.agent-workflow/feat_cu/intake.md"
git -C "$RL" add -A; git -C "$RL" -c user.name=t -c user.email=t@t commit -q -m "bo cai 1.x"
GOCL=$(git -C "$RL" rev-parse HEAD)
CL="$RL/.git/agent-workflow"

ky_vong 2 "--from-legacy ở repo không có bộ cài cũ → SAI THAM SỐ" sh -c "R=\$(mktemp -d '$TMP/x.XXXX') && git -C \"\$R\" init -q && cd \"\$R\" && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' init --from-legacy --version '$VDEV'"
ky_vong 0 "aw init --from-legacy" awd "$RL" init --from-legacy --version "$VDEV"
dung "…conventions.md cũ chuyển vào .git/agent-workflow/" cmp -s "$RL/.agent-workflow/conventions.md" "$CL/conventions.md"
dung "…lệnh trong cau-hinh.sh cũ chuyển sang config.sh" sh -c "grep -qx 'TEST_CMD=\"make test\"' '$CL/config.sh' && grep -qx 'WORKTREE_SETUP_CMD=\"npm ci\"' '$CL/config.sh' && grep -qx 'ADAPTER=\"claude-code\"' '$CL/config.sh'"
dung "…không xoá gì của bộ cài cũ" sh -c "[ -f '$RL/.agent-workflow/.quy-trinh/cau-hinh.sh' ] && [ -f '$RL/.agent-workflow/conventions.md' ] && [ -f '$RL/.claude/commands/aw-spec.md' ]"
dung "…không commit gì, cây làm việc sạch" sh -c "[ \"\$(git -C '$RL' rev-parse HEAD)\" = '$GOCL' ] && [ -z \"\$(git -C '$RL' status --porcelain)\" ]"
dung "…file .claude/ cũ git đang theo dõi: adapter bỏ qua, nội dung giữ nguyên" grep -q 'bản 1.x' "$RL/.claude/commands/aw-spec.md"
dung "…lệnh người viết tay giữ nguyên" grep -q 'team tự viết' "$RL/.claude/commands/cua-team.md"
dung "…sinh các lệnh mới chưa có" sh -c "[ -f '$RL/.claude/commands/aw-design.md' ] && grep -q 'aw feature' '$RL/.claude/commands/aw-design.md'"
OUTL=$(awd "$RL" init --from-legacy 2>/dev/null)
dung "…in hướng dẫn tự dọn bằng PR: git rm bộ cài cũ" sh -c "printf '%s' \"\$1\" | grep -q 'git rm -r -q -- .agent-workflow/.quy-trinh/' && printf '%s' \"\$1\" | grep -q 'git rm -r -q -- .claude/commands/aw-spec.md'" _ "$OUTL"
dung "…không đề nghị xoá lệnh người viết tay" sh -c "! printf '%s' \"\$1\" | grep -q 'cua-team.md'" _ "$OUTL"
dung "…chạy lại giữ cấu hình đã chuyển" sh -c "grep -qx 'TEST_CMD=\"make test\"' '$CL/config.sh'"
ky_vong 0 "repo cũ: tạo worktree từ base vẫn chứa bộ cài 1.x" awd "$RL" worktree new feature sau-chuyen --create --base main
dung "…worktree sạch, base không đổi" sh -c "[ -z \"\$(git -C '$TMP/repo-cu.wt/feat_sau-chuyen' status --porcelain)\" ] && [ \"\$(git -C '$RL' rev-parse main)\" = '$GOCL' ]"

# Cấu hình của người: init lại không ghi đè (thay cho các ca của install.sh)
printf 'TEST_CMD="npm test"\nADAPTER="claude-code"\n' > "$CL/config.sh"
printf '# của tôi\n```conventions\nbranch_patterns: job-*\n```\n' > "$CL/conventions.md"
awd "$RL" init >/dev/null 2>&1
dung "init lại KHÔNG ghi đè config.sh người sửa" grep -q 'npm test' "$CL/config.sh"
awd "$RL" init --force >/dev/null 2>&1
dung "KHÔNG ghi đè conventions.md, kể cả --force" grep -q 'của tôi' "$CL/conventions.md"
ky_vong 2 "init --adapter khác ADAPTER trong config.sh → SAI THAM SỐ" awd "$RL" init --adapter cursor

# ---------------------------------------------------------------- khoi "Ket qua"
# Nguoi va agent doc NHAN, khong doc ma so: moi script in khoi nay ra stderr.
nhom "lib/result.sh"
KQT="$TMP/kq-thu.sh"
cat > "$KQT" <<EOF
. "$T/lib/result.sh"
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
dung "checker thiếu file → [x] THIẾU ĐẦU VÀO" sh -c "AW_REPO='$R9' AW_CONFIG='$R9/.git/agent-workflow' sh '$T/check-plan.sh' '$TMP/khong-co' 2>&1 | grep -q '\[x\] THIẾU ĐẦU VÀO'"
dung "checker gọi thẳng, thiếu AW_CONFIG → dừng, không đoán đường dẫn" sh -c "env -u AW_CONFIG sh '$T/check-plan.sh' '$TMP/khong-co' 2>&1 | grep -q 'thiếu AW_CONFIG'"
dung "tool worktree gọi thẳng, thiếu AW_REPO → dừng" sh -c "env -u AW_REPO -u AW_CONFIG sh '$T/feature.sh' 2>&1 | grep -q 'thiếu AW_REPO'"
dung "aw feature ở checkout chính → [x] ĐANG Ở CHECKOUT CHÍNH" sh -c "printf '%s' \"\$1\" | grep -q '\[x\] ĐANG Ở CHECKOUT CHÍNH'" _ "$(awd "$R9" feature 2>&1)"
dung "…stdout không lẫn khối Kết quả" sh -c "! printf '%s' \"\$1\" | grep -q 'Kết quả'" _ "$(awd "$R9" feature 2>/dev/null)"

ket_thuc
