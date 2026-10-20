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
dung "check-sdlc không đăng ký trong aw check (chỉ dùng cho repo engine)" sh -c ". '$T/lib/commands.sh'; ! bl_checker sdlc"

# ---------------------------------------------------------------- trạng thái stage
nhom "check-sdlc.sh: trạng thái stage (khối sdlc: của workflow.yaml)"
moi; thay "$E/workflow.yaml" '  - stage: operate
    status: gap' '  - stage: deploy
    status: partial
    note: x'
vi_pham "stage không phase nào implement, không khai gap → chặn" "stage operate: không phase nào implement và không khai gap"
moi; awk '!/note: Chỉ nhận việc đã có/' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
vi_pham "partial thiếu note → chặn" "stage plan: status partial thiếu note"
moi; awk '!/note: CI\/CD/' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
vi_pham "gap thiếu note → chặn" "stage operate: status gap thiếu note"
moi; thay "$E/workflow.yaml" '  - stage: deploy
    status: partial' '  - stage: deploy
    status: gap'
vi_pham "gap mà có phase implement → chặn" "stage deploy: khai gap nhưng phase ship implement nó"
moi; thay "$E/workflow.yaml" '  - stage: operate
    status: gap' '  - stage: operate
    status: partial'
vi_pham "partial mà không phase nào implement → chặn" "stage operate: khai partial nhưng không phase nào implement"
moi; thay "$E/workflow.yaml" '    status: gap' '    status: done'
vi_pham "status lạ → chặn" "stage operate: status \"done\" — chỉ nhận implemented | partial | gap"
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
