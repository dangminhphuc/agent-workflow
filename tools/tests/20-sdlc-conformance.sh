#!/usr/bin/env sh
# Interface SDLC: engine khai tuân thủ sdlc/ (tools/check-sdlc.sh).
# Chạy riêng: sh tools/tests/20-sdlc-conformance.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
SC="$T/check-sdlc.sh"

# Bản chép engine: chỉ phần checker đọc (manifest, phase, utility command, interface) + tools/
# (invariant trỏ tới checker/test có thật). Mỗi ca chép lại từ $EB rồi làm hỏng đúng một chỗ.
EB="$TMP/engine-goc"; E="$TMP/engine"
mkdir -p "$EB"
cp "$ROOT/workflow.yaml" "$EB/"; cp -R "$ROOT/workflow" "$ROOT/sdlc" "$ROOT/tools" "$EB/"
moi() { rm -rf "$E"; cp -R "$EB" "$E"; }

# vi_pham <tên-ca> <lý-do> — checker trên $E: KHÔNG ĐẠT và in đúng lý do (một lần chạy)
vi_pham() {
  sh "$SC" "$E" > "$TMP/ra" 2>&1; _m=$?
  if [ "$_m" = 1 ] && grep -qF -- "$2" "$TMP/ra"; then
    ca_dat "$1"
  else
    ca_hong "$1 — mã thoát $_m, mong đợi 1 kèm \"$2\""
  fi
}

# ---------------------------------------------------------------- engine hiện tại
nhom "check-sdlc.sh: engine hiện tại tuân thủ"
ky_vong 0 "engine của repo này → ĐẠT" sh "$SC" "$ROOT"
ky_vong 0 "không tham số → kiểm engine chứa script → ĐẠT" sh "$SC"
moi
ky_vong 0 "bản chép chưa sửa → ĐẠT" sh "$SC" "$E"
dung "…in ánh xạ stage → phase" sh -c "sh '$SC' '$E' 2>/dev/null | grep -q 'implement.*implemented.*plan, implement'"
ky_vong 2 "thư mục không phải engine → SAI THAM SỐ" sh "$SC" "$TMP/khong-co"
ky_vong 2 "thừa tham số → SAI THAM SỐ" sh "$SC" "$E" "$E"
dung "…bảng ánh xạ in trạng thái suy ra" sh -c "sh '$SC' '$ROOT' 2>/dev/null | grep -Eq '^  verify +partial +review'"
dung "…in bảng roadmap capability còn thiếu" sh -c "sh '$SC' '$ROOT' 2>/dev/null | grep -Eq '^    CAP-deploy-02 +machine +'"
dung "…roadmap không liệt kê capability đã nhận" sh -c "! sh '$SC' '$ROOT' 2>/dev/null | grep -q '^    CAP-deploy-01 '"
dung "check-sdlc không đăng ký trong aw check (chỉ dùng cho repo engine)" sh -c ". '$T/lib/commands.sh'; ! bl_checker sdlc"

# ---------------------------------------------------------------- trạng thái stage
nhom "check-sdlc.sh: trạng thái stage (khối sdlc: của workflow.yaml)"
moi; thay "$E/workflow.yaml" '  - stage: deploy
    note:' '  - stage: deploy
    status: partial
    note:'
vi_pham "khối sdlc: còn khoá status → chặn" "khối sdlc: stage deploy còn khoá status — xoá dòng status"
moi; awk '!/note: Dừng ở MR\/PR/' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
vi_pham "suy ra partial mà thiếu note → chặn" "stage deploy: suy ra partial nhưng khối sdlc: không có note"
moi; awk '!/note: CI\/CD/' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
vi_pham "suy ra gap mà thiếu note → chặn" "stage operate: suy ra gap nhưng khối sdlc: không có note"
moi; thay "$E/workflow/phases/06-ship.md" '  - CAP-deploy-01' '  - CAP-deploy-01
  - CAP-deploy-02
  - CAP-deploy-03'
vi_pham "nhận đủ capability mà còn note → chặn" "stage deploy: suy ra implemented nhưng khối sdlc: còn note"
# chiều ngược: nhận đủ + xoá mục khối sdlc: → ĐẠT, stage thành implemented
awk '/^  - stage: deploy$/ { bo = 1; next } bo && /^    / { next } { bo = 0; print }' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
ky_vong 0 "nhận đủ capability + xoá note → ĐẠT" sh "$SC" "$E"
dung "…stage deploy thành implemented" sh -c "sh '$SC' '$E' 2>/dev/null | grep -Eq '^  deploy +implemented +ship'"
moi; awk '/^capabilities:$/ { print "capabilities: []"; next } !/^  - CAP-/' "$E/workflow/phases/06-ship.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/06-ship.md"
vi_pham "phase implements mà không nhận capability nào → chặn" "phase ship: implements deploy nhưng không nhận capability nào"
moi; thay "$E/workflow.yaml" '  - stage: operate' '  - stage: monitor'
vi_pham "khối sdlc: khai stage không có → chặn" "khối sdlc: khai stage \"monitor\" không có trong sdlc/stages/"

# ---------------------------------------------------------------- phase ↔ stage
nhom "check-sdlc.sh: phase khai implements / provides"
moi; awk '!/^implements:/' "$E/workflow/phases/05-review.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/05-review.md"
vi_pham "phase thiếu implements → chặn" "phase review: thiếu implements"
moi; thay "$E/workflow/phases/05-review.md" 'implements: verify' 'implements: test'
vi_pham "phase implements stage không có → chặn" "phase review: implements \"test\" — không có stage đó"
moi; awk '!/^  - requirements: spec.md$/' "$E/workflow/phases/01-spec.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/01-spec.md"
vi_pham "provides của phase không phủ provides của stage → chặn" "stage require: không phase nào provides \"requirements\""
moi; thay "$E/workflow/phases/01-spec.md" '  - requirements: spec.md' '  - requirements: spec.md
  - backlog: spec.md'
vi_pham "phase map loại stage không khai → chặn" "phase spec: provides \"backlog\" — stage require không khai loại đó"
moi; thay "$E/workflow/phases/01-spec.md" '  - requirements: spec.md' '  - requirements: brd.md'
vi_pham "file của provides không nằm trong outputs → chặn" "phase spec: provides \"requirements: brd.md\" — brd.md không nằm trong outputs"
moi; thay "$E/workflow/phases/01-spec.md" '  - requirements: spec.md' '  - requirements spec.md'
vi_pham "provides sai dạng → chặn" "phase spec: provides \"requirements spec.md\" — cần dạng <loại>: <file>"
# Đổi chỗ hai mục intake và spec trong phases: (id và file đi cùng nhau)
moi; thay "$E/workflow.yaml" '  - id: intake
    file: workflow/phases/00-intake.md' 'TAM'
thay "$E/workflow.yaml" '  - id: spec
    file: workflow/phases/01-spec.md' '  - id: intake
    file: workflow/phases/00-intake.md'
thay "$E/workflow.yaml" 'TAM' '  - id: spec
    file: workflow/phases/01-spec.md'
vi_pham "thứ tự phase lệch thứ tự stage → chặn" "phase intake (stage plan) đứng sau phase spec (stage require)"
moi; thay "$E/workflow/clarify.md" 'id: clarify' 'id: clarify
implements: require'
vi_pham "utility command khai implements → chặn" "utility command clarify: khai implements"
moi; thay "$E/workflow/phases/06-ship.md" '  - CAP-deploy-01' '  - CAP-deploy-09'
vi_pham "phase nhận capability không tồn tại → chặn" "phase ship: capabilities \"CAP-deploy-09\" — không có capability đó"
moi; thay "$E/workflow/phases/06-ship.md" '  - CAP-deploy-01' '  - CAP-deploy-01
  - CAP-verify-03'
vi_pham "phase nhận capability của stage khác → chặn" "phase ship: capabilities \"CAP-verify-03\" thuộc stage verify, phase implements deploy"
moi; thay "$E/workflow/phases/04-implement.md" 'capabilities:' 'capabilities:
  - CAP-implement-01'
ky_vong 0 "hai phase cùng nhận một capability → ĐẠT" sh "$SC" "$E"
moi; thay "$E/workflow/clarify.md" 'id: clarify' 'id: clarify
capabilities:
  - CAP-require-01'
vi_pham "utility command khai capabilities → chặn" "utility command clarify: khai capabilities"

# ---------------------------------------------------------------- điều kiện ra của stage
nhom "check-sdlc.sh: exit của stage ↔ exit_machine / exit_human của phase"
moi; thay "$E/sdlc/stages/03-implement.md" 'exit: machine' 'exit: both'
vi_pham "exit both mà không phase nào có exit_human → chặn" "stage implement: exit both nhưng không phase nào có exit_human"
moi; awk '/^exit_machine:/ { print "exit_machine: []"; bo = 1; next } bo && /^  - / { next } { bo = 0; print }' \
  "$E/workflow/phases/00-intake.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/00-intake.md"
vi_pham "exit both mà không phase nào có exit_machine → chặn" "stage plan: exit both nhưng không phase nào có exit_machine"
moi; thay "$E/sdlc/stages/03-implement.md" 'exit: machine' 'exit: auto'
vi_pham "exit lạ → chặn" "stage implement: exit \"auto\" — chỉ nhận machine | human | both"

# ---------------------------------------------------------------- file stage
nhom "check-sdlc.sh: file stage"
moi; thay "$E/sdlc/stages/01-require.md" '  - work-item' '  - design'
vi_pham "requires không do stage trước cung cấp → chặn" "stage require: requires \"design\" — không stage nào trước nó provides"
moi; thay "$E/sdlc/stages/01-require.md" 'id: require' 'id: requirement'
vi_pham "id lệch tên file → chặn" "sdlc/stages/01-require.md: id \"requirement\" lệch tên file"
moi; thay "$E/sdlc/stages/00-plan.md" 'purpose: ' 'purpose_x: '
vi_pham "thiếu purpose → chặn" "stage plan: thiếu purpose"

# ---------------------------------------------------------------- capability trong file stage
nhom "check-sdlc.sh: capability trong file stage"
moi; awk '/^## Capabilities/ { exit } { print }' "$E/sdlc/stages/06-operate.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-operate.md"
vi_pham "stage không có capability → chặn" "stage operate: không có capability"
moi; thay "$E/sdlc/stages/05-deploy.md" '### CAP-deploy-01 — ' '### CAP-deploy-01 - '
vi_pham "heading capability gõ - thay vì — → chặn" "stage deploy: heading capability \"### CAP-deploy-01 - "
moi; thay "$E/sdlc/stages/05-deploy.md" '### CAP-deploy-01 — ' '### CAP-verify-01 — '
vi_pham "id capability mang stage khác → chặn" "stage deploy: heading capability \"### CAP-verify-01"
moi; thay "$E/sdlc/stages/05-deploy.md" '### CAP-deploy-02 — ' '### CAP-deploy-01 — '
vi_pham "id capability trùng → chặn" "stage deploy: CAP-deploy-01 trùng"
moi; awk '!(/^- Rule:/ && ++n == 1)' "$E/sdlc/stages/05-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/05-deploy.md"
vi_pham "capability thiếu Rule → chặn" "CAP-deploy-01: thiếu \"- Rule:\""
moi; awk '!(/^- Judged by:/ && ++n == 1)' "$E/sdlc/stages/05-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/05-deploy.md"
vi_pham "capability thiếu Judged by → chặn" "CAP-deploy-01: thiếu \"- Judged by:\""
moi; thay "$E/sdlc/stages/05-deploy.md" '- Judged by: human' '- Judged by: robot'
vi_pham "Judged by lạ → chặn" "Judged by \"robot\" — chỉ nhận machine | agent | human"
moi; awk '!(/^- Rule:/ && ++n == 1)' "$E/sdlc/stages/05-deploy.md" > "$E/s" && printf '\n## Notes\n\n- Rule: lạc chỗ\n' >> "$E/s" && mv "$E/s" "$E/sdlc/stages/05-deploy.md"
vi_pham "Rule nằm dưới heading khác không tính → chặn" "CAP-deploy-01: thiếu \"- Rule:\""
moi; sed 's/$/\r/' "$E/sdlc/stages/05-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/05-deploy.md"
ky_vong 0 "file stage CRLF → vẫn ĐẠT" sh "$SC" "$E"

# ---------------------------------------------------------------- invariant
nhom "check-sdlc.sh: invariant trỏ tới checker + test có thật"
moi; thay "$E/sdlc/stages/04-verify.md" '  - INV-004' '  - INV-099'
vi_pham "stage khai invariant không có → chặn" "stage verify: invariant INV-099 không có trong sdlc/invariants.md"
moi; awk '/^### INV-001 / { on = 1 } /^### INV-002 / { on = 0 } !(on && /^- Enforced by:/)' "$E/sdlc/invariants.md" > "$E/i" && mv "$E/i" "$E/sdlc/invariants.md"
vi_pham "invariant không trỏ tới checker → chặn" "INV-001: thiếu \"Enforced by:\" trỏ tới checker"
moi; awk '/^### INV-001 / { on = 1 } /^### INV-002 / { on = 0 } !(on && /^- Tested by:/)' "$E/sdlc/invariants.md" > "$E/i" && mv "$E/i" "$E/sdlc/invariants.md"
vi_pham "invariant không trỏ tới test → chặn" "INV-001: thiếu \"Tested by:\" trỏ tới test"
moi; rm -f "$E/tools/check-plan.sh"
vi_pham "invariant trỏ tới checker không có → chặn" "INV-001: \`tools/check-plan.sh\` không tồn tại"
moi; thay "$E/sdlc/invariants.md" '`tools/tests/02-design-plan.sh`' '`tools/check-plan.sh`'
vi_pham "\"Tested by\" trỏ tới thứ không phải test → chặn" "INV-001: \"Tested by:\" \`tools/check-plan.sh\` không phải tools/tests/*.sh"
moi; thay "$E/sdlc/invariants.md" '- Enforced by: `tools/check-plan.sh`' '- Enforced by: `README.md`'
vi_pham "\"Enforced by\" trỏ tới thứ không phải checker → chặn" "INV-001: \"Enforced by:\" \`README.md\` không phải tools/check-*.sh hay tools/lib/*.sh"

moi; thay "$E/sdlc/invariants.md" '"check-repro chặn khi test XANH trên code chưa sửa"' '"check-repro chặn ca không có"'
vi_pham "\"Tested by\" nêu ca test không có trong file → chặn" "INV-007: ca \"check-repro chặn ca không có\" không có trong tools/tests/10-intake-bugfix.sh"
moi; thay "$E/sdlc/stages/00-plan.md" 'skippable: false' 'skippable: maybe'
vi_pham "stage có skippable lạ → chặn" "stage plan: skippable \"maybe\" — chỉ nhận true | false"

ket_thuc
