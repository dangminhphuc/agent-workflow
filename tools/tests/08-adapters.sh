#!/usr/bin/env sh
# Adapter: claude-code, cursor, chuẩn định dạng, đối chiếu, exclude.
# Chạy riêng: sh tools/tests/08-adapters.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

# ---------------------------------------------------------------- adapter
unset AW_REPO AW_CONFIG   # các mục dưới dùng bộ cài 1.x (install.sh) cho tới khi chuyển sang aw
nhom "adapters/claude-code/build.sh"
BUILD="$ROOT/adapters/claude-code/build.sh"

O="$TMP/out1"; mkdir -p "$O"
ky_vong 0 "build bản đúng thành công" sh "$BUILD" --out "$O"

du=1
for f in commands/aw-intake.md commands/aw-spec.md commands/aw-design.md commands/aw-plan.md commands/aw-implement.md commands/aw-review.md \
         commands/aw-ship.md commands/aw-import.md commands/aw-clarify.md commands/aw-bootstrap.md commands/aw-refactor.md commands/aw-approvals.md agents/independent-reviewer.md agents/design-checker.md agents/spec-checker.md skills/agent-workflow/SKILL.md; do
  [ -f "$O/.claude/$f" ] || { du=0; echo "        thiếu .claude/$f"; }
done
dung "sinh đúng bộ file" test "$du" = 1
dung "/aw-ship: điều kiện ra máy là aw check ship" grep -q '`aw check ship <dir>`' "$O/.claude/commands/aw-ship.md"
dung "/aw-ship: ở checkout chính thì làm mục \"Ở checkout chính\", không dừng" sh -c \
  "grep -q 'ĐANG Ở CHECKOUT CHÍNH.*\"On the main checkout\"' '$O/.claude/commands/aw-ship.md' && ! grep -q 'ĐANG Ở CHECKOUT CHÍNH.*stop' '$O/.claude/commands/aw-ship.md'"
dung "…lệnh khác vẫn dừng lại ở checkout chính" grep -q 'ĐANG Ở CHECKOUT CHÍNH.*stop' "$O/.claude/commands/aw-review.md"
dung "/aw-ship: không bắt buộc, có mẫu merge-request.md" sh -c \
  "grep -q 'Required:\*\* no' '$O/.claude/commands/aw-ship.md' && grep -q 'templates/merge-request.md' '$O/.claude/commands/aw-ship.md'"
dung "skill liệt kê /aw-ship" grep -q '| `/aw-ship` |' "$O/.claude/skills/agent-workflow/SKILL.md"
dung "command có bước xác định feature bằng aw feature" grep -q 'aw feature \$ARGUMENTS' "$O/.claude/commands/aw-design.md"
dung "điều kiện ra máy là aw check <tên>" grep -q '`aw check design <dir>`' "$O/.claude/commands/aw-design.md"
dung "không còn gọi script theo đường dẫn bộ cài cũ" sh -c "! grep -rq '\.quy-trinh\|sh tools/\|\.sh ' '$O/.claude'"
dung "command design gọi checker LLM" grep -q 'design-checker' "$O/.claude/commands/aw-design.md"
dung "command spec gọi checker LLM" grep -q 'spec-checker' "$O/.claude/commands/aw-spec.md"
dung "lệnh /aw-clarify có bước xác định feature + chạy aw pending" sh -c \
  "grep -q 'aw feature <feature-name if the user gave one>' '$O/.claude/commands/aw-clarify.md' && grep -q 'aw pending' '$O/.claude/commands/aw-clarify.md'"
dung "lệnh /aw-clarify hỏi bằng AskUserQuestion, có Chat about this" sh -c \
  "grep -q 'AskUserQuestion' '$O/.claude/commands/aw-clarify.md' && grep -q 'Chat about this' '$O/.claude/commands/aw-clarify.md'"
dung "…lựa chọn là phương án đã phân tích, (Đề xuất) đứng đầu nhãn" sh -c \
  "grep -q 'Think before asking' '$O/.claude/commands/aw-clarify.md' && grep -q 'starts with.*(Đề xuất)' '$O/.claude/commands/aw-clarify.md'"
dung "…không chiếm chỗ options bằng lối Chat/tự nhập có sẵn của tool" grep -q 'Chat about this' "$O/.claude/commands/aw-clarify.md"
dung "…chữ tự nhập là câu hỏi ngược thì xử lý như Chat, không ghi thành Answer" grep -qF '**Typed text is a question, not an answer**' "$O/.claude/commands/aw-clarify.md"
dung "lệnh /aw-clarify dẫn phân xử phát hiện checker LLM" grep -q 'design-findings.md' "$O/.claude/commands/aw-clarify.md"
dung "…lệnh không khai choice_ui thì không có" sh -c "! grep -q 'Asking choice questions' '$O/.claude/commands/aw-import.md'"
dung "/aw-intake hỏi lựa chọn bằng AskUserQuestion: loại việc, tên, base, nguyên văn [HUMAN]" sh -c \
  "grep -q '## Asking choice questions in Claude Code' '$O/.claude/commands/aw-intake.md' && grep -q '## Confirmation turn' '$O/.claude/commands/aw-intake.md' && grep -q 'each candidate base' '$O/.claude/commands/aw-intake.md' && grep -q 'Đúng nguyên văn' '$O/.claude/commands/aw-intake.md'"
dung "…Input không có lựa chọn \"cần sửa\": chữ tự nhập là bản sửa" grep -qF 'free-text answer **is** the fix' "$O/.claude/commands/aw-intake.md"
dung "/aw-design có cổng duyệt: aw approval design + hộp xác nhận AskUserQuestion" sh -c \
  "grep -q 'Step 1 — Approval gate' '$O/.claude/commands/aw-design.md' && grep -q 'aw approval design' '$O/.claude/commands/aw-design.md' && grep -q 'AskUserQuestion' '$O/.claude/commands/aw-design.md'"
dung "…ba lựa chọn cố định, có preview, từ chối duyệt hộ" sh -c \
  "grep -q 'Tôi đã duyệt xong — kiểm lại' '$O/.claude/commands/aw-design.md' && grep -q 'Giải thích từng điểm cần duyệt' '$O/.claude/commands/aw-design.md' && grep -q 'Dừng — tôi duyệt sau' '$O/.claude/commands/aw-design.md' && grep -q 'preview' '$O/.claude/commands/aw-design.md' && grep -q 'duyệt hộ' '$O/.claude/commands/aw-design.md'"
dung "/aw-plan có cổng duyệt aw approval plan" grep -q 'aw approval plan' "$O/.claude/commands/aw-plan.md"
dung "…phase không khai approval_gate thì không có" sh -c "! grep -q 'Approval gate' '$O/.claude/commands/aw-implement.md' && ! grep -q 'Approval gate' '$O/.claude/commands/aw-spec.md'"
mkdir -p "$O/.claude/skills/quy-trinh-agent"
printf -- '---\nname: quy-trinh-agent\n---\n> **File này được SINH TỰ ĐỘNG** — bản trước 2026.10.21\n' > "$O/.claude/skills/quy-trinh-agent/SKILL.md"
sh "$BUILD" --out "$O" >/dev/null 2>&1
dung "build lại dọn skill cũ quy-trinh-agent (đã đổi tên thành agent-workflow)" sh -c "[ ! -e '$O/.claude/skills/quy-trinh-agent' ] && [ -f '$O/.claude/skills/agent-workflow/SKILL.md' ]"
dung "subagent checker LLM tên <id>-checker" test -f "$O/.claude/agents/design-checker.md"
EX9="$TMP/ex9"; mkdir -p "$EX9"; git -C "$EX9" init -q
printf '/.cursor/commands/\n/.cursor/skills/quy-trinh-agent/\n' > "$EX9/.git/info/exclude"
sh "$T/adapter-build.sh" cursor "$EX9" >/dev/null 2>&1
dung "aw adapter build thêm exclude còn thiếu cho bản clone init từ trước (skill đổi tên)" sh -c "grep -qx '/.cursor/skills/agent-workflow/' '$EX9/.git/info/exclude' && grep -qx '/.agent-workflow/' '$EX9/.git/info/exclude' && [ \"\$(grep -cx '/.cursor/commands/' '$EX9/.git/info/exclude')\" = 1 ]"
dung "…file sinh ra không lọt vào git status" sh -c "[ -z \"\$(git -C '$EX9' status --porcelain)\" ]"
dung "lệnh /aw-import giữ argument-hint riêng" grep -q 'argument-hint: "<file-nguồn>' "$O/.claude/commands/aw-import.md"
dung "mọi lệnh /aw-* chỉ chạy khi người gõ (disable-model-invocation: true trong frontmatter)" sh -c \
  "for f in '$O'/.claude/commands/aw-*.md; do awk 'NR > 1 && /^---\$/ { exit } /^disable-model-invocation: true\$/ { ok = 1 } END { exit !ok }' \"\$f\" || exit 1; done"
dung "skill agent-workflow chỉ chạy khi người gõ" sh -c "sed -n 4p '$O/.claude/skills/agent-workflow/SKILL.md' | grep -qx 'disable-model-invocation: true'"
dung "skill liệt kê lệnh tiện ích" grep -q '/aw-clarify' "$O/.claude/skills/agent-workflow/SKILL.md"
dung "/aw-bootstrap: ở checkout chính làm mục \"On the main checkout\" (đề xuất worktree), không dừng" sh -c \
  "grep -q 'ĐANG Ở CHECKOUT CHÍNH.*\"On the main checkout\"' '$O/.claude/commands/aw-bootstrap.md' && grep -q 'aw worktree new chore' '$O/.claude/commands/aw-bootstrap.md'"
dung "…dùng mẫu target-repo, không tự tạo luật BR-, có bài kiểm tra phiên mới" sh -c \
  "grep -q 'templates/target-repo/AGENTS.md' '$O/.claude/commands/aw-bootstrap.md' && grep -q 'Writing \`BR-\` blocks' '$O/.claude/commands/aw-bootstrap.md' && grep -q 'Fresh-session test' '$O/.claude/commands/aw-bootstrap.md'"
dung "skill liệt kê /aw-bootstrap" grep -q '/aw-bootstrap' "$O/.claude/skills/agent-workflow/SKILL.md"
dung "/aw-refactor: review + phản biện rồi chỉ ghi refactor-requests.md; chỉ lệnh intake tiếp theo" sh -c \
  "grep -q 'refactor-requests.md' '$O/.claude/commands/aw-refactor.md' && grep -q 'Việc refactor riêng' '$O/.claude/commands/aw-refactor.md' && grep -q 'Debate once' '$O/.claude/commands/aw-refactor.md' && grep -q 'Chọn đường đi cho N RFR đang chờ' '$O/.claude/commands/aw-refactor.md' && ! grep -q 'moved:' '$O/.claude/commands/aw-refactor.md' && grep -q 'aw-intake <dir>/refactor-requests.md' '$O/.claude/commands/aw-refactor.md' && grep -q 'AskUserQuestion' '$O/.claude/commands/aw-refactor.md' && grep -q 'ĐANG Ở CHECKOUT CHÍNH.*stop' '$O/.claude/commands/aw-refactor.md'"
dung "skill liệt kê /aw-refactor" grep -q '/aw-refactor' "$O/.claude/skills/agent-workflow/SKILL.md"
dung "/aw-approvals: không chạy aw feature, liệt kê rồi chỉ tick mục người chọn Duyệt" sh -c \
  "! grep -q 'Run .aw feature' '$O/.claude/commands/aw-approvals.md' && grep -q 'Needs no feature dir' '$O/.claude/commands/aw-approvals.md' && grep -q 'aw approvals --global' '$O/.claude/commands/aw-approvals.md' && grep -q 'aw approvals tick <dir> <key> <hash>' '$O/.claude/commands/aw-approvals.md' && grep -q 'never .approve all' '$O/.claude/commands/aw-approvals.md' && grep -q 'AskUserQuestion' '$O/.claude/commands/aw-approvals.md'"
dung "luật chung: ngoại lệ duy nhất là aw approvals tick trong /aw-approvals" grep -q 'Only `/aw-approvals` runs `aw approvals tick`' "$O/.claude/skills/agent-workflow/SKILL.md"
dung "phase có quy tắc repo: lệnh gọi aw rules <phase> (review: subagent đọc)" sh -c \
  "for p in spec design plan implement; do grep -q \"aw rules \$p\" '$O/.claude/commands/aw-'\$p.md || exit 1; done"
dung "phase implement đọc kiến thức bền: lệnh gọi aw knowledge implement; subagent rà soát gọi aw knowledge review" sh -c \
  "grep -q 'aw knowledge implement' '$O/.claude/commands/aw-implement.md' && grep -q 'aw knowledge review' '$O/.claude/agents/independent-reviewer.md'"
dung "/aw-review chỉ bàn giao cho subagent, không nạp mô tả phase" sh -c \
  "grep -q 'What this session does' '$O/.claude/commands/aw-review.md' && ! grep -q 'Four lenses' '$O/.claude/commands/aw-review.md' && grep -q 'Four lenses' '$O/.claude/agents/independent-reviewer.md'"
dung "mọi lệnh phase có hợp đồng đầy đủ (không bị set -e cắt giữa chừng)" sh -c \
  "for f in '$O'/.claude/commands/aw-*.md; do tail -1 \"\$f\" | grep -q . || exit 1; grep -q '^## Phase contract\|^## Step 0' \"\$f\" || exit 1; done; grep -q 'Exit — MACHINE' '$O/.claude/commands/aw-implement.md'"
dung "…intake thì không" sh -c "! grep -q 'aw rules' '$O/.claude/commands/aw-intake.md'"
dung "mọi lệnh phase kết thúc bằng Kết quả · Cần bạn" sh -c \
  "for p in intake spec design plan implement review ship; do grep -q 'Cần bạn:' '$O/.claude/commands/aw-'\$p.md || exit 1; done"
dung "…lệnh tiếp theo theo thứ tự manifest (implement → review, spec có nhánh không design)" sh -c \
  "grep -q 'Tiếp theo: /aw-review' '$O/.claude/commands/aw-implement.md' && grep -q 'Tiếp theo: /aw-design.*chore or .*Design: skip.*/aw-plan' '$O/.claude/commands/aw-spec.md' && grep -q 'Tiếp theo: /aw-ship.*(optional)' '$O/.claude/commands/aw-review.md'"
dung "…phase cuối không có lệnh tiếp theo" sh -c "! grep -q 'Tiếp theo:' '$O/.claude/commands/aw-ship.md'"
dung "…subagent rà soát đọc aw rules review" grep -q 'aw rules review' "$O/.claude/agents/independent-reviewer.md"
dung "…checker LLM soát thiết kế đọc aw rules design" grep -q 'aw rules design' "$O/.claude/agents/design-checker.md"
dung "…checker LLM soát spec đọc aw rules spec" grep -q 'aw rules spec' "$O/.claude/agents/spec-checker.md"
dung "phase có quy tắc repo: lệnh gọi aw uses <phase>, subagent rà soát gọi aw uses review; intake thì không" sh -c \
  "for p in spec design plan implement; do grep -q \"aw uses \$p\" '$O/.claude/commands/aw-'\$p.md || exit 1; done; grep -q 'aw uses review' '$O/.claude/agents/independent-reviewer.md' && ! grep -q 'aw uses' '$O/.claude/commands/aw-intake.md'"
dung "…Claude Code gọi skill qua Skill tool, không đọc file; subagent qua subagent_type" sh -c \
  "grep -q 'invoke it with the \*\*Skill tool\*\*' '$O/.claude/commands/aw-implement.md' && grep -q 'Skill(<name>)' '$O/.claude/commands/aw-implement.md' && grep -q 'subagent_type: <name>' '$O/.claude/commands/aw-implement.md'"
dung "…lời dặn không chứa thứ Claude Code tự xử lý trong file lệnh (dòng chèn shell)" sh -c "! grep -q '!\`' '$O'/.claude/commands/aw-*.md '$O'/.claude/agents/*.md"

printf '# tôi tự viết\n' > "$O/.claude/commands/aw-spec.md"
ky_vong 3 "từ chối ghi đè file người viết tay" sh "$BUILD" --out "$O"
dung "nội dung người viết còn nguyên" sh -c "head -1 '$O/.claude/commands/aw-spec.md' | grep -q 'tôi tự viết'"
ky_vong 0 "--force thì cho phép ghi đè" sh "$BUILD" --out "$O" --force

# lenh do lan cai truoc sinh ra ma nay khong con (vd /ideation -> /aw-intake)
printf -- '---\n---\n> **File này được SINH TỰ ĐỘNG** từ `workflow/phases/00-ideation.md`\n' > "$O/.claude/commands/ideation.md"
printf '# lệnh tôi tự viết\n' > "$O/.claude/commands/cua-toi.md"
sh "$BUILD" --out "$O" >/dev/null 2>&1
dung "cài lại xoá lệnh sinh tự động không còn trong manifest" test ! -f "$O/.claude/commands/ideation.md"
dung "…nhưng giữ lệnh người viết tay" test -f "$O/.claude/commands/cua-toi.md"

FAKE="$TMP/fake"
tao_fake() {
  rm -rf "$FAKE"; mkdir -p "$FAKE/tools"
  cp -r "$ROOT/workflow" "$FAKE/"
  cp "$ROOT/workflow.yaml" "$FAKE/"
  cp -r "$ROOT/tools/lib" "$FAKE/tools/"
  cp "$ROOT"/tools/*.sh "$FAKE/tools/"
  cp "$ROOT/VERSION" "$FAKE/"
  cp -r "$ROOT/adapters" "$FAKE/"
}

tao_fake
thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - kế hoạch trông có vẻ hợp lý'
O2="$TMP/out2"; mkdir -p "$O2"
ky_vong 4 "từ chối build khi exit_machine không phải lệnh chạy được" sh "$FAKE/adapters/claude-code/build.sh" --out "$O2"
dung "không để lại file viết dở khi build hỏng" sh -c "[ ! -f '$O2/.claude/commands/aw-plan.md' ] && [ -z \"\$(find '$O2' -name '*.tmp')\" ]"

tao_fake
thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - aw check khong-ton-tai'
ky_vong 4 "từ chối build khi aw check trỏ tới checker không có" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out3"

tao_fake
rm -f "$FAKE/workflow/checkers/design.md"
ky_vong 4 "từ chối build khi llm_checker trỏ tới file không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out4"

tao_fake
thay "$FAKE/workflow/phases/00-intake.md" 'arguments: input' 'arguments: gi-cung-duoc'
ky_vong 4 "từ chối build khi arguments không phải \"input\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out5"

tao_fake
thay "$FAKE/workflow/phases/06-ship.md" 'runs_on_main_checkout: true' 'runs_on_main_checkout: co'
ky_vong 4 "từ chối build khi runs_on_main_checkout khác \"true\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out5b"

tao_fake
thay "$FAKE/workflow/phases/06-ship.md" 'required: false' 'required: false
status: chưa hiện thực'
ky_vong 0 "phase status: chưa hiện thực → build vẫn đạt" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out5c"
dung "…nhưng không sinh lệnh cho nó" test ! -e "$TMP/out5c/.claude/commands/aw-ship.md"

tao_fake
rm -f "$FAKE/workflow/clarify.md"
ky_vong 4 "từ chối build khi mục commands: trỏ tới file không tồn tại" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out6"

tao_fake
thay "$FAKE/workflow/clarify.md" 'choice_ui: true' 'choice_ui: co'
ky_vong 4 "từ chối build khi choice_ui khác \"true\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out8"

tao_fake
thay "$FAKE/workflow/phases/02-design.md" 'approval_gate: true' 'approval_gate: co'
ky_vong 4 "từ chối build khi approval_gate khác \"true\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out10"

tao_fake
thay "$FAKE/workflow/checkers/design.md" 'repo_rules: design' 'repo_rules: intake'
ky_vong 4 "từ chối build khi checker LLM khai repo_rules không phải phase có quy tắc" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out9"

tao_fake
thay "$FAKE/workflow/import.md" 'arguments: mixed' 'arguments: input'
ky_vong 4 "từ chối build khi lệnh tiện ích khai arguments khác \"mixed\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out7"

tao_fake
thay "$FAKE/workflow/bootstrap.md" 'runs_on_main_checkout: true' 'runs_on_main_checkout: co'
ky_vong 4 "từ chối build khi lệnh tiện ích khai runs_on_main_checkout khác \"true\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out7b"

tao_fake
thay "$FAKE/workflow/approvals.md" 'feature_dir: none' 'feature_dir: co'
ky_vong 4 "từ chối build khi lệnh tiện ích khai feature_dir khác \"none\"" sh "$FAKE/adapters/claude-code/build.sh" --out "$TMP/out7c"

# ---------------------------------------------------------------- adapter cursor
nhom "adapters/cursor/build.sh"
CB="$ROOT/adapters/cursor/build.sh"
O3="$TMP/cur1"; mkdir -p "$O3"
ky_vong 0 "build bản đúng thành công" sh "$CB" --out "$O3"

# ds_tuong_doi <thư-mục> -> đường dẫn tương đối của mọi file, đã sắp
ds_tuong_doi() { (cd "$1" && find . -type f | sed 's|^\./||' | LC_ALL=C sort); }
dung "cùng bộ file với Claude Code (commands/, agents/, skills/) — trùng tên để che bản .claude/" \
  bang "$(ds_tuong_doi "$O3/.cursor")" "$(ds_tuong_doi "$TMP/out1/.claude" | grep -v '^commands/cua-toi.md$')"
dung "…chỉ ghi vào .cursor/" bang "$(ls -A "$O3")" ".cursor"
dung "…có /aw-ship" test -f "$O3/.cursor/commands/aw-ship.md"
dung "không còn \$ARGUMENTS (Cursor không thay biến)" sh -c "! grep -rqF '\$ARGUMENTS' '$O3/.cursor'"
dung "không gọi tool riêng của Claude Code (AskUserQuestion, multiSelect, trường preview/questions)" \
  sh -c "! grep -rqE 'AskUserQuestion|multiSelect|\`preview\`:|\`questions\`' '$O3/.cursor'"
dung "mọi file mang dấu SINH TỰ ĐỘNG + version engine + 'Dành cho Cursor'" sh -c \
  "for f in \$(find '$O3/.cursor' -type f); do grep -q 'SINH TỰ ĐỘNG' \"\$f\" && grep -q \"engine agent-workflow $(cat "$ROOT/VERSION")\" \"\$f\" && grep -q 'Dành cho Cursor' \"\$f\" || exit 1; done"
dung "lệnh là markdown thường: dòng đầu '# /<id> — …', không frontmatter" sh -c \
  "for f in '$O3'/.cursor/commands/*.md; do id=\$(basename \"\$f\" .md); head -1 \"\$f\" | grep -q \"^# /\$id — \" || exit 1; done"
dung "mọi lệnh có mục tham số của Cursor (<tham-số> chép nguyên văn)" sh -c \
  "for f in '$O3'/.cursor/commands/*.md; do grep -q '## Command arguments in Cursor' \"\$f\" && grep -q 'copied verbatim' \"\$f\" || exit 1; done"
dung "/aw-design xác định feature bằng aw feature <tham-số>" grep -qF 'aw feature <tham-số>' "$O3/.cursor/commands/aw-design.md"
dung "/aw-intake: aw feature không tham số, input đi qua heredoc với <tham-số>" sh -c \
  "grep -q 'Run \`aw feature\` — \*\*without\*\* the command arguments' '$O3/.cursor/commands/aw-intake.md' && awk '/<<.HET_INPUT.\$/ { getline; print; exit }' '$O3/.cursor/commands/aw-intake.md' | grep -qx '<tham-số>'"
dung "điều kiện ra máy là aw check <tên>" grep -q '`aw check design <dir>`' "$O3/.cursor/commands/aw-design.md"
dung "/aw-design gọi subagent checker LLM design-checker" grep -q 'subagent `design-checker`' "$O3/.cursor/commands/aw-design.md"
dung "/aw-spec gọi subagent checker LLM spec-checker" grep -q 'subagent `spec-checker`' "$O3/.cursor/commands/aw-spec.md"
dung "/aw-review bắt buộc subagent independent-reviewer" grep -q 'subagent `independent-reviewer`' "$O3/.cursor/commands/aw-review.md"
dung "subagent: frontmatter name trùng tên file (Cursor nạp .cursor/agents/)" sh -c \
  "for f in '$O3'/.cursor/agents/*.md; do head -1 \"\$f\" | grep -qx -- '---' && sed -n 2p \"\$f\" | grep -qx \"name: \$(basename \"\$f\" .md)\" || exit 1; done"
dung "skill: frontmatter name agent-workflow + description" sh -c \
  "sed -n 2p '$O3/.cursor/skills/agent-workflow/SKILL.md' | grep -qx 'name: agent-workflow' && sed -n 3p '$O3/.cursor/skills/agent-workflow/SKILL.md' | grep -q '^description: ' && sed -n 4p '$O3/.cursor/skills/agent-workflow/SKILL.md' | grep -qx 'disable-model-invocation: true'"
dung "subagent dặn chỉ gọi khi lệnh /aw-* yêu cầu" sh -c \
  "for f in '$O3'/.cursor/agents/*.md; do sed -n 3p \"\$f\" | grep -q 'Only call when an /aw-\* command instructs it' || exit 1; done"
dung "/aw-clarify hỏi lựa chọn kiểu Cursor: tool nếu có, không thì đánh số" sh -c \
  "grep -q '## Asking choice questions in Cursor' '$O3/.cursor/commands/aw-clarify.md' && grep -q 'AskQuestion' '$O3/.cursor/commands/aw-clarify.md' && grep -q 'numbered' '$O3/.cursor/commands/aw-clarify.md'"
dung "…luôn có lối tự nhập và Chat about this (tool không chắc tự thêm)" sh -c \
  "grep -q 'Hoặc gõ câu trả lời khác / hỏi lại để trao đổi về câu này' '$O3/.cursor/commands/aw-clarify.md' && grep -q 'Chat about this' '$O3/.cursor/commands/aw-clarify.md'"
dung "…(Đề xuất) đứng đầu nhãn, phân tích trước khi hỏi" sh -c \
  "grep -q 'starts with.*(Đề xuất)' '$O3/.cursor/commands/aw-clarify.md' && grep -q 'Think before asking' '$O3/.cursor/commands/aw-clarify.md'"
dung "…chữ tự nhập là câu hỏi ngược thì xử lý như Chat (Cursor)" grep -qF '**Typed text is a question, not an answer**' "$O3/.cursor/commands/aw-clarify.md"
dung "…lệnh không khai choice_ui thì không có" sh -c "! grep -q 'Asking choice questions' '$O3/.cursor/commands/aw-import.md' && ! grep -q 'Asking choice questions' '$TMP/out1/.claude/commands/aw-import.md'"
dung "/aw-design, /aw-plan có cổng duyệt aw approval + hộp xác nhận Cursor" sh -c \
  "grep -q 'aw approval design' '$O3/.cursor/commands/aw-design.md' && grep -q 'aw approval plan' '$O3/.cursor/commands/aw-plan.md' && grep -q '### Confirmation box in Cursor' '$O3/.cursor/commands/aw-plan.md'"
dung "…phase không khai approval_gate thì không có" sh -c \
  "for p in intake spec implement review; do ! grep -q 'Approval gate' '$O3/.cursor/commands/aw-'\$p.md || exit 1; done"
dung "/aw-intake hỏi lựa chọn kiểu Cursor, phase khác thì không" sh -c \
  "grep -q '## Asking choice questions in Cursor' '$O3/.cursor/commands/aw-intake.md' && for p in spec design plan implement; do ! grep -q 'Asking choice questions' '$O3/.cursor/commands/aw-'\$p.md || exit 1; done"
dung "phase có quy tắc repo: lệnh gọi aw rules <phase>; intake thì không" sh -c \
  "for p in spec design plan implement; do grep -q \"aw rules \$p\" '$O3/.cursor/commands/aw-'\$p.md || exit 1; done; ! grep -q 'aw rules' '$O3/.cursor/commands/aw-intake.md'"
dung "phase có quy tắc repo: lệnh gọi aw uses <phase>; Cursor đọc file khi không có tool gọi skill" sh -c \
  "for p in spec design plan implement; do grep -q \"aw uses \$p\" '$O3/.cursor/commands/aw-'\$p.md || exit 1; done; grep -q 'read the printed file' '$O3/.cursor/commands/aw-implement.md' && ! grep -q 'Skill tool' '$O3/.cursor/commands/aw-implement.md'"
dung "skill liệt kê phase và lệnh tiện ích" sh -c \
  "grep -q '| \`/aw-design\` |' '$O3/.cursor/skills/agent-workflow/SKILL.md' && grep -q '/aw-clarify' '$O3/.cursor/skills/agent-workflow/SKILL.md'"

printf '# tôi tự viết\n' > "$O3/.cursor/commands/aw-spec.md"
ky_vong 3 "từ chối ghi đè file người viết tay" sh "$CB" --out "$O3"
dung "…nội dung người viết còn nguyên" sh -c "head -1 '$O3/.cursor/commands/aw-spec.md' | grep -q 'tôi tự viết'"
ky_vong 0 "--force thì cho phép ghi đè" sh "$CB" --out "$O3" --force
printf -- '> **File này được SINH TỰ ĐỘNG** từ `workflow/phases/00-ideation.md`\n' > "$O3/.cursor/commands/ideation.md"
printf -- '> **File này được SINH TỰ ĐỘNG** — agent cũ\n' > "$O3/.cursor/agents/cu.md"
printf '# lệnh tôi tự viết\n' > "$O3/.cursor/commands/cua-toi.md"
sh "$CB" --out "$O3" >/dev/null 2>&1
dung "build lại xoá lệnh/subagent sinh tự động không còn trong manifest" sh -c "[ ! -e '$O3/.cursor/commands/ideation.md' ] && [ ! -e '$O3/.cursor/agents/cu.md' ]"
dung "…nhưng giữ lệnh người viết tay" test -f "$O3/.cursor/commands/cua-toi.md"
ky_vong 2 "từ chối --out nằm trong repo agent-workflow" sh "$CB" --out "$ROOT/adapters"
ky_vong 2 "thiếu --out → SAI THAM SỐ" sh "$CB"
ky_vong 2 "tham số lạ → SAI THAM SỐ" sh "$CB" --out "$O3" --khac

# File .cursor/ git đang theo dõi (team commit lệnh trùng tên): bỏ qua, không đụng
RT="$TMP/cur-team"; mkdir -p "$RT/.cursor/commands"; git -C "$RT" init -q
printf '# lệnh spec của team\n' > "$RT/.cursor/commands/aw-spec.md"
git -C "$RT" add -A; git -C "$RT" -c user.name=t -c user.email=t@t commit -q -m team
ky_vong 0 "file git đang theo dõi → bỏ qua, build vẫn đạt" sh "$CB" --out "$RT"
dung "…nội dung của team giữ nguyên, cây sạch" sh -c "grep -q 'của team' '$RT/.cursor/commands/aw-spec.md' && [ -z \"\$(git -C '$RT' status --porcelain -- .cursor/commands/aw-spec.md)\" ]"

# Định nghĩa quy trình lỗi: MỌI adapter phải từ chối, không để lại file viết dở
for ad in claude-code cursor; do
  tao_fake
  thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - kế hoạch trông có vẻ hợp lý'
  ky_vong 4 "$ad: từ chối build khi exit_machine không phải lệnh chạy được" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-1"
  dung "$ad: …không để lại file viết dở" sh -c "[ -z \"\$(find '$TMP/f-$ad-1' -name '*.tmp' 2>/dev/null)\" ] && [ ! -e '$TMP/f-$ad-1/.claude/commands/aw-plan.md' ] && [ ! -e '$TMP/f-$ad-1/.cursor/commands/aw-plan.md' ]"
  tao_fake
  thay "$FAKE/workflow/phases/03-plan.md" '  - aw check plan' '  - aw check khong-ton-tai'
  ky_vong 4 "$ad: từ chối build khi aw check trỏ tới checker không có" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-2"
  tao_fake; rm -f "$FAKE/workflow/checkers/design.md"
  ky_vong 4 "$ad: từ chối build khi llm_checker trỏ tới file không tồn tại" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-3"
  tao_fake; thay "$FAKE/workflow/phases/02-design.md" 'approval_gate: true' 'approval_gate: co'
  ky_vong 4 "$ad: từ chối build khi approval_gate khác \"true\"" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-4"
  tao_fake; thay "$FAKE/workflow/clarify.md" 'choice_ui: true' 'choice_ui: co'
  ky_vong 4 "$ad: từ chối build khi choice_ui khác \"true\"" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-5"
  tao_fake; thay "$FAKE/workflow/phases/00-intake.md" 'choice_ui: true' 'choice_ui: co'
  ky_vong 4 "$ad: từ chối build khi phase khai choice_ui khác \"true\"" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-5b"
  tao_fake; thay "$FAKE/workflow/phases/00-intake.md" 'arguments: input' 'arguments: gi-cung-duoc'
  ky_vong 4 "$ad: từ chối build khi arguments không phải \"input\"" sh "$FAKE/adapters/$ad/build.sh" --out "$TMP/f-$ad-6"
done

# Adapter thiếu hook → ĐỊNH NGHĨA QUY TRÌNH LỖI, không sinh gì
tao_fake
mkdir -p "$FAKE/adapters/thieu-hook"
sed '/^ad_hoi_cong_duyet() {/,/^}/d' "$CB" > "$FAKE/adapters/thieu-hook/build.sh"
ky_vong 4 "adapter thiếu hook (ad_hoi_cong_duyet) → từ chối build" sh "$FAKE/adapters/thieu-hook/build.sh" --out "$TMP/f-thieu"
dung "…không sinh file nào" sh -c "[ -z \"\$(find '$TMP/f-thieu' -type f 2>/dev/null)\" ]"

# ---------------------------------------------------------------- chuẩn định dạng của agent
# adapters/lib/format.sh: mọi file sinh ra phải đúng chuẩn agent đọc (frontmatter
# YAML, khoá được phép, name = tên file/thư mục…) — sai thì SAI CHUẨN, file không vào chỗ.
nhom "chuẩn định dạng của agent (adapters/lib/format.sh)"
# ad_gia <adapter> <tên-bản-sao> <đoạn-shell> — bản sao adapter, chèn đoạn ngay trước ad_sinh
ad_gia() {
  mkdir -p "$FAKE/adapters/$2"
  awk -v d="$3" '$0 == "ad_sinh \"$@\"" { print d } { print }' "$FAKE/adapters/$1/build.sh" > "$FAKE/adapters/$2/build.sh"
}
# dd_tho <adapter> <file> — chạy riêng dd_kiem lên một file như thể nó nằm ở <file> trong .<goc>/
dd_tho() {
  sh -c ". '$FAKE/adapters/lib/format.sh'; OUT=/o; AD_TEN=x; $(grep -E '^AD_(GOC|LENH_FM|LENH_KHOA|AGENT_KHOA|SKILL_KHOA)=' "$ROOT/adapters/$1/build.sh" | tr '\n' ';') dd_kiem '$TMP/dd.md' \"/o/\$AD_GOC/$2\""
}
tao_fake
for ad in claude-code cursor; do
  goc=$(sed -n 's/^AD_GOC=//p' "$ROOT/adapters/$ad/build.sh")
  ky_vong 0 "$ad: bản đúng qua kiểm chuẩn" sh "$ROOT/adapters/$ad/build.sh" --out "$TMP/dd-$ad-0"
  ad_gia "$ad" "$ad-ten" "ad_dau_agent() { printf -- '---\\\\nname: Sai_Ten\\\\ndescription: x\\\\n---\\\\n\\\\n'; }"
  ky_vong 5 "$ad: subagent name không đúng dạng → SAI CHUẨN" sh "$FAKE/adapters/$ad-ten/build.sh" --out "$TMP/dd-$ad-1"
  dung "$ad: …file sai không vào chỗ, không để lại .tmp" sh -c "[ ! -e '$TMP/dd-$ad-1/$goc/agents/independent-reviewer.md' ] && [ -z \"\$(find '$TMP/dd-$ad-1' -name '*.tmp')\" ]"
  ad_gia "$ad" "$ad-khac" "ad_dau_agent() { printf -- '---\\\\nname: %s-cu\\\\ndescription: %s\\\\n---\\\\n\\\\n' \"\$1\" \"\$2\"; }"
  ky_vong 5 "$ad: subagent name khác tên file → SAI CHUẨN" sh "$FAKE/adapters/$ad-khac/build.sh" --out "$TMP/dd-$ad-2"
  ad_gia "$ad" "$ad-khoa" "ad_dau_agent() { printf -- '---\\\\nname: %s\\\\ndescription: %s\\\\nkhoa-la: 1\\\\n---\\\\n\\\\n' \"\$1\" \"\$2\"; }"
  ky_vong 5 "$ad: subagent có khoá ngoài chuẩn → SAI CHUẨN" sh "$FAKE/adapters/$ad-khoa/build.sh" --out "$TMP/dd-$ad-3"
  ad_gia "$ad" "$ad-dai" "ad_dau_skill() { printf -- '---\\\\nname: %s\\\\ndescription: %s\\\\n---\\\\n\\\\n' \"\$1\" \"\$(printf '%01100d' 0)\"; }"
  ky_vong 5 "$ad: skill description > 1024 ký tự → SAI CHUẨN" sh "$FAKE/adapters/$ad-dai/build.sh" --out "$TMP/dd-$ad-4"
  dung "$ad: …skill không vào chỗ" test ! -e "$TMP/dd-$ad-4/$goc/skills/agent-workflow/SKILL.md"
  ad_gia "$ad" "$ad-fm" "AD_LENH_FM=gi-do"
  ky_vong 4 "$ad: AD_LENH_FM khác co|khong → ĐỊNH NGHĨA QUY TRÌNH LỖI" sh "$FAKE/adapters/$ad-fm/build.sh" --out "$TMP/dd-$ad-5"
  ad_gia "$ad" "$ad-thieu" "AD_AGENT_KHOA="
  ky_vong 4 "$ad: thiếu AD_AGENT_KHOA → ĐỊNH NGHĨA QUY TRÌNH LỖI" sh "$FAKE/adapters/$ad-thieu/build.sh" --out "$TMP/dd-$ad-6"
done
# Claude Code: frontmatter lệnh phải là YAML hợp lệ
ad_gia claude-code cc-hint "ad_dau_lenh() { printf -- '---\\\\ndescription: \"%s\"\\\\nargument-hint: %s\\\\n---\\\\n\\\\n' \"\$3\" \"\$4\"; }"
ky_vong 5 "claude-code: argument-hint mở bằng [ không nháy (YAML hiểu thành danh sách) → SAI CHUẨN" sh "$FAKE/adapters/cc-hint/build.sh" --out "$TMP/dd-cc-1"
ad_gia claude-code cc-mota "ad_dau_lenh() { printf -- '---\\\\ndescription: %s\\\\nargument-hint: \"%s\"\\\\n---\\\\n\\\\n' \"\$3\" \"\$4\"; }"
ky_vong 5 "claude-code: description có ': ' không nháy → SAI CHUẨN" sh "$FAKE/adapters/cc-mota/build.sh" --out "$TMP/dd-cc-2"
ad_gia claude-code cc-dong "ad_dau_lenh() { printf -- '---\\\\ndescription: \"%s\"\\\\n\\\\n' \"\$3\"; }"
ky_vong 5 "claude-code: frontmatter không có --- đóng → SAI CHUẨN" sh "$FAKE/adapters/cc-dong/build.sh" --out "$TMP/dd-cc-3"
ad_gia claude-code cc-khong "ad_dau_lenh() { printf '# /%s\\\\n\\\\n' \"\$1\"; }"
ky_vong 5 "claude-code: lệnh thiếu frontmatter description → SAI CHUẨN" sh "$FAKE/adapters/cc-khong/build.sh" --out "$TMP/dd-cc-4"
# Cursor: lệnh là markdown thường
ad_gia cursor cu-fm "ad_dau_lenh() { printf -- '---\\\\ndescription: x\\\\n---\\\\n\\\\n'; }"
ky_vong 5 "cursor: lệnh có frontmatter → SAI CHUẨN" sh "$FAKE/adapters/cu-fm/build.sh" --out "$TMP/dd-cu-1"
# dd_kiem trực tiếp: các trường hợp biên của YAML
printf -- '---\nname: a\ndescription: "mở nháy\n---\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: nháy kép không đóng → sai" dd_tho cursor agents/a.md
printf -- '---\nname: a\ndescription: "có \\"nháy\\" và : bên trong"\n---\nthân\n' > "$TMP/dd.md"
ky_vong 0 "dd_kiem: nháy kép có \\\" và ': ' bên trong → đúng" dd_tho cursor agents/a.md
printf -- "---\nname: a\ndescription: 'it''s ok: yes'\n---\nthân\n" > "$TMP/dd.md"
ky_vong 0 "dd_kiem: nháy đơn có '' → đúng" dd_tho cursor agents/a.md
printf -- '---\nname: a\nname: a\ndescription: x\n---\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: khoá trùng → sai" dd_tho cursor agents/a.md
printf -- '---\nname: a\ndescription:\tx\n---\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: tab trong frontmatter → sai" dd_tho cursor agents/a.md
printf -- '---\nname: a\ndescription: x\n---\n\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: thân rỗng → sai" dd_tho cursor agents/a.md
printf -- '---\nname: s\ndescription: dùng <thẻ>\n---\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: skill description có < > → sai" dd_tho claude-code skills/s/SKILL.md
printf -- '---\nname: s\ndescription: %s\n---\nthân\n' "$(awk 'BEGIN { for (i = 0; i < 1024; i++) printf "ư" }')" > "$TMP/dd.md"
ky_vong 0 "dd_kiem: skill description đúng 1024 ký tự (chữ có dấu tính 1) → đúng" dd_tho claude-code skills/s/SKILL.md
printf '# /Aw_Sai\n\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: tên file lệnh không đúng dạng → sai" dd_tho cursor commands/Aw_Sai.md
printf '# x\n\nthân\n' > "$TMP/dd.md"
ky_vong 1 "dd_kiem: đường dẫn agent không đọc → sai" dd_tho cursor rules/x.md

# ---------------------------------------------------------------- đối chiếu mọi adapter
# Mọi adapter dùng chung adapters/lib/common.sh. AW_COMPARE=1: hook in tên của nó
# thay cho nội dung — phần còn lại (hợp đồng phase, Bước 0, cổng duyệt, quy tắc
# repo, thân phase…) phải GIỐNG HỆT nhau từng byte. Ai sửa hợp đồng cho một agent
# mà quên agent kia, hay viết chữ riêng của agent ngoài hook, là hỏng ở đây.
nhom "đối chiếu mọi adapter (một hợp đồng phase cho mọi agent)"
DC="$TMP/doi-chieu"; mkdir -p "$DC"
n_ad=0; dc_build=1; dc_goc=1
for b in "$ROOT"/adapters/*/build.sh; do
  a=$(basename "$(dirname "$b")"); n_ad=$((n_ad + 1)); mkdir -p "$DC/$a"
  AW_COMPARE=1 sh "$b" --out "$DC/$a" >/dev/null 2>&1 || { dc_build=0; echo "        $a: build hỏng"; }
  g=$(ls -A "$DC/$a")
  if [ "$(printf '%s\n' "$g" | wc -l | tr -d ' ')" = 1 ] && [ -n "$g" ]; then mv "$DC/$a/$g" "$DC/$a/goc"
  else dc_goc=0; echo "        $a: không ghi vào đúng một thư mục gốc: $g"; fi
done
dung "có ít nhất hai adapter để đối chiếu" test "$n_ad" -ge 2
dung "mọi adapter build được ở chế độ đối chiếu" test "$dc_build" = 1
dung "mỗi adapter chỉ ghi vào một thư mục gốc của nó (.claude/, .cursor/…)" test "$dc_goc" = 1
dc_khac=0; dau=""
for d in "$DC"/*/; do
  [ -d "$d/goc" ] || continue
  if [ -z "$dau" ]; then dau=$d; continue; fi
  if ! diff -r "$dau/goc" "$d/goc" >/dev/null 2>&1; then
    dc_khac=1; echo "        khác: $(basename "$dau") ↔ $(basename "$d")"
    diff -r "$dau/goc" "$d/goc" 2>&1 | head -8 | sed 's/^/          /'
  fi
done
dung "ngoài hook, output của mọi adapter giống hệt nhau từng byte" test "$dc_khac" = 0
dung "…phép đối chiếu không rỗng: hook thật sự được gọi (cổng duyệt, hỏi lựa chọn, tham số)" sh -c \
  "grep -q '<<ad_hoi_cong_duyet design>>' '$dau/goc/commands/aw-design.md' && grep -q '<<ad_hoi_lua_chon>>' '$dau/goc/commands/aw-clarify.md' && grep -q 'aw feature <<ad_tham_so>>' '$dau/goc/commands/aw-spec.md' && grep -q '<<ad_danh_cho>>' '$dau/goc/agents/independent-reviewer.md'"
dung "…và phần dùng chung không chứa chữ riêng của agent nào" sh -c \
  "! grep -rqE 'AskUserQuestion|AskQuestion|\\\$ARGUMENTS|<tham-số>|\\.claude/|\\.cursor/' '$dau/goc'"

# Ở chế độ thường: chữ riêng của agent ĐÚNG agent, và các hằng của cổng duyệt
# (câu hỏi, ba nhãn) giống hệt nhau giữa các adapter.
build_doi_chieu_that
# cau_hoi <file> -> các chuỗi trong backtick kết thúc bằng "bạn muốn làm gì?", đã sắp
cau_hoi() { grep -o '`[^`]*bạn muốn làm gì?`' "$1" | LC_ALL=C sort -u; }
nhan_cd() { grep -oE '`(Tôi đã duyệt xong — kiểm lại|Giải thích từng điểm cần duyệt|Dừng — tôi duyệt sau)`' "$1" | tr '\n' '|'; }
cd_khac=0
for p in design plan; do
  q0=$(cau_hoi "$DT/claude-code/.claude/commands/aw-$p.md"); n0=$(nhan_cd "$DT/claude-code/.claude/commands/aw-$p.md")
  [ -n "$q0" ] && [ "$n0" = '`Tôi đã duyệt xong — kiểm lại`|`Giải thích từng điểm cần duyệt`|`Dừng — tôi duyệt sau`|' ] || { cd_khac=1; echo "        claude-code /$p: thiếu câu hỏi hay nhãn"; }
  for d in "$DT"/*/; do
    f=$(find "$d" -path "*/commands/aw-$p.md" | head -1)
    [ "$(cau_hoi "$f")" = "$q0" ] || { cd_khac=1; echo "        $(basename "$d") /$p: câu hỏi cổng duyệt khác"; }
    [ "$(nhan_cd "$f")" = "$n0" ] || { cd_khac=1; echo "        $(basename "$d") /$p: ba nhãn / thứ tự khác"; }
  done
done
dung "cổng duyệt: cùng câu hỏi, cùng ba nhãn đúng thứ tự ở mọi adapter" test "$cd_khac" = 0
dung "mọi file .claude/ ghi 'Dành cho Claude Code' và chỉ đường sang .cursor/ (Cursor nạp .claude/)" sh -c \
  "for f in \$(find '$DT/claude-code/.claude' -type f); do grep -q 'Dành cho Claude Code' \"\$f\" && grep -q 'AskUserQuestion' \"\$f\" && grep -qF '.cursor/' \"\$f\" || exit 1; done"
dung "mọi subagent trùng tên giữa các adapter (bản .cursor/ che bản .claude/)" \
  bang "$(ls "$DT/cursor/.cursor/agents")" "$(ls "$DT/claude-code/.claude/agents")"

# Hai adapter cùng một worktree: không đè, không dọn file của nhau
nhom "hai adapter cùng một thư mục"
B2="$TMP/ca-hai"; mkdir -p "$B2"
ky_vong 0 "build claude-code rồi cursor vào cùng thư mục" sh -c "sh '$ROOT/adapters/claude-code/build.sh' --out '$B2' && sh '$CB' --out '$B2'"
dung "….claude/ giống hệt khi build riêng" diff -r "$B2/.claude" "$DT/claude-code/.claude"
dung "….cursor/ giống hệt khi build riêng" diff -r "$B2/.cursor" "$DT/cursor/.cursor"
printf -- '> **File này được SINH TỰ ĐỘNG** — lệnh cũ\n' > "$B2/.claude/commands/cu-claude.md"
printf -- '> **File này được SINH TỰ ĐỘNG** — lệnh cũ\n' > "$B2/.cursor/commands/cu-cursor.md"
sh "$CB" --out "$B2" >/dev/null 2>&1
dung "build cursor chỉ dọn file cũ của .cursor/, không đụng .claude/" sh -c "[ ! -e '$B2/.cursor/commands/cu-cursor.md' ] && [ -f '$B2/.claude/commands/cu-claude.md' ]"
sh "$ROOT/adapters/claude-code/build.sh" --out "$B2" >/dev/null 2>&1
dung "…build claude-code dọn của .claude/, .cursor/ vẫn nguyên" sh -c "[ ! -e '$B2/.claude/commands/cu-claude.md' ] && diff -r '$B2/.cursor' '$DT/cursor/.cursor'"
mkdir -p "$TMP/ca-hai-2" "$TMP/ca-hai-3"
ky_vong 0 "tools/adapter-build.sh nhận danh sách claude-code,cursor" sh "$T/adapter-build.sh" claude-code,cursor "$TMP/ca-hai-2"
dung "…ghi dấu build cho từng adapter" bang "$(cat "$TMP/ca-hai-2/.agent-workflow/.adapters" 2>/dev/null)" "claude-code $(cat "$ROOT/VERSION")
cursor $(cat "$ROOT/VERSION")"
dung "…cả hai bộ giống hệt khi build riêng" sh -c "diff -r '$TMP/ca-hai-2/.claude' '$DT/claude-code/.claude' && diff -r '$TMP/ca-hai-2/.cursor' '$DT/cursor/.cursor'"
ky_vong 2 "tools/adapter-build.sh: một id không có → SAI THAM SỐ, không sinh gì" sh "$T/adapter-build.sh" "claude-code khong-co" "$TMP/ca-hai-3"
dung "…không sinh adapter nào" sh -c "[ ! -e '$TMP/ca-hai-3/.claude' ] && [ ! -e '$TMP/ca-hai-3/.agent-workflow' ]"
mkdir -p "$TMP/ca-hai-4/.cursor/commands"; printf '# tự viết\n' > "$TMP/ca-hai-4/.cursor/commands/aw-spec.md"
ky_vong 3 "một adapter hỏng (file viết tay) → mã của adapter đó" sh "$T/adapter-build.sh" claude-code,cursor "$TMP/ca-hai-4"
dung "…adapter kia vẫn sinh đủ, dấu build chỉ ghi adapter đạt" sh -c \
  "diff -r '$TMP/ca-hai-4/.claude' '$DT/claude-code/.claude' && grep -q '^claude-code ' '$TMP/ca-hai-4/.agent-workflow/.adapters' && ! grep -q '^cursor ' '$TMP/ca-hai-4/.agent-workflow/.adapters'"

# exclude của từng adapter phủ đúng file nó sinh — và không giấu file của team
nhom "exclude của adapter"
for b in "$ROOT"/adapters/*/build.sh; do
  a=$(basename "$(dirname "$b")"); RX="$TMP/ex-$a"; mkdir -p "$RX"; git -C "$RX" init -q
  grep -v '^#' "$ROOT/adapters/$a/exclude" >> "$RX/.git/info/exclude"
  sh "$b" --out "$RX" >/dev/null 2>&1
  dung "$a: mọi file sinh ra bị exclude (git status sạch)" sh -c "[ -n \"\$(find '$RX' -path '$RX/.git' -prune -o -type f -print)\" ] && [ -z \"\$(git -C '$RX' status --porcelain --untracked-files=all)\" ]"
done
mkdir -p "$TMP/ex-cursor/.cursor/rules"; printf 'x\n' > "$TMP/ex-cursor/.cursor/rules/team.mdc"; printf '{}\n' > "$TMP/ex-cursor/.cursor/hooks.json"
mkdir -p "$TMP/ex-cursor/.cursor/skills/cua-team"; printf 'x\n' > "$TMP/ex-cursor/.cursor/skills/cua-team/SKILL.md"
dung "cursor: không giấu file team commit (.cursor/rules, hooks.json, skill khác)" bang \
  "$(git -C "$TMP/ex-cursor" status --porcelain --untracked-files=all | LC_ALL=C sort | tr '\n' '|')" \
  "?? .cursor/hooks.json|?? .cursor/rules/team.mdc|?? .cursor/skills/cua-team/SKILL.md|"

# ---------------------------------------------------------------- khong cai vao engine
nhom "không cài vào chính engine"
ky_vong 2 "aw-engine init từ chối repo đích là chính engine" env AW_REPO="$ROOT" AW_CONFIG="$TMP/cfg-engine" sh "$ROOT/bin/aw-engine" init
dung "…và không ghi gì" test ! -e "$TMP/cfg-engine/conventions.md"
ky_vong 2 "aw-engine init từ chối thư mục con của engine" env AW_REPO="$ROOT/adapters" AW_CONFIG="$TMP/cfg-engine" sh "$ROOT/bin/aw-engine" init
ky_vong 2 "build.sh từ chối --out nằm trong repo agent-workflow" sh "$BUILD" --out "$ROOT/adapters"
ky_vong 2 "aw adapter build từ chối --out nằm trong engine" sh "$ROOT/bin/aw-engine" adapter build claude-code --out "$ROOT/adapters"

ket_thuc
