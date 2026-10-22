#!/usr/bin/env sh
# Interface SDLC: file stage, capability, invariant (tools/check-sdlc.sh).
# Chạy riêng: sh tools/tests/22-sdlc-stage-files.sh (AW_TEST_VERBOSE=1 in từng ca).

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

nhom "check-sdlc.sh: bản chép engine chưa sửa"
moi
ky_vong 0 "bản chép chưa sửa → ĐẠT" sh "$SC" "$E"

# ---------------------------------------------------------------- điều kiện ra của stage
nhom "check-sdlc.sh: exit của stage ↔ exit_machine / exit_human của phase"
moi; thay "$E/sdlc/stages/04-implement.md" 'exit: machine' 'exit: both'
vi_pham "exit both mà không phase nào có exit_human → chặn" "stage implement: exit both nhưng không phase nào có exit_human"
moi; awk '/^exit_machine:/ { print "exit_machine: []"; bo = 1; next } bo && /^  - / { next } { bo = 0; print }' \
  "$E/workflow/phases/00-intake.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/00-intake.md"
vi_pham "exit both mà không phase nào có exit_machine → chặn" "stage plan: exit both nhưng không phase nào có exit_machine"
moi; thay "$E/sdlc/stages/04-implement.md" 'exit: machine' 'exit: auto'
vi_pham "exit lạ → chặn" "stage implement: exit \"auto\" — chỉ nhận machine | human | both"

# ---------------------------------------------------------------- file stage
nhom "check-sdlc.sh: file stage"
moi; thay "$E/sdlc/stages/01-require.md" '  - work-item' '  - design'
vi_pham "requires không do stage trước cung cấp → chặn" "stage require: requires \"design\" — không stage nào trước nó provides"
moi; awk '!/^  - task-plan$/' "$E/sdlc/stages/03-breakdown.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/03-breakdown.md"
vi_pham "implement cần kế hoạch task mà không stage trước nào cung cấp → chặn" "stage implement: requires \"task-plan\" — không stage nào trước nó provides"
moi; thay "$E/sdlc/stages/01-require.md" 'id: require' 'id: requirement'
vi_pham "id lệch tên file → chặn" "sdlc/stages/01-require.md: id \"requirement\" lệch tên file"
moi; thay "$E/sdlc/stages/00-plan.md" 'purpose: ' 'purpose_x: '
vi_pham "thiếu purpose → chặn" "stage plan: thiếu purpose"

# ---------------------------------------------------------------- capability trong file stage
nhom "check-sdlc.sh: capability trong file stage"
moi; awk '/^## Capabilities/ { exit } { print }' "$E/sdlc/stages/07-operate.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/07-operate.md"
vi_pham "stage không có capability → chặn" "stage operate: không có capability"
moi; thay "$E/sdlc/stages/06-deploy.md" '### CAP-deploy-01 — ' '### CAP-deploy-01 - '
vi_pham "heading capability gõ - thay vì — → chặn" "stage deploy: heading capability \"### CAP-deploy-01 - "
moi; thay "$E/sdlc/stages/06-deploy.md" '### CAP-deploy-01 — ' '### CAP-verify-01 — '
vi_pham "id capability mang stage khác → chặn" "stage deploy: heading capability \"### CAP-verify-01"
moi; thay "$E/sdlc/stages/06-deploy.md" '### CAP-deploy-02 — ' '### CAP-deploy-01 — '
vi_pham "id capability trùng → chặn" "stage deploy: CAP-deploy-01 trùng"
moi; awk '!(/^- Rule:/ && ++n == 1)' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "capability thiếu Rule → chặn" "CAP-deploy-01: thiếu \"- Rule:\""
moi; awk '!(/^- Judged by:/ && ++n == 1)' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "capability thiếu Judged by → chặn" "CAP-deploy-01: thiếu \"- Judged by:\""
moi; thay "$E/sdlc/stages/06-deploy.md" '- Judged by: human' '- Judged by: robot'
vi_pham "Judged by lạ → chặn" "Judged by \"robot\" — chỉ nhận machine | agent | human"
# capability CUỐI file mất Rule; Rule lạc dưới heading sau nó không được tính cho nó
moi; awk '!(/^- Rule:/ && ++n == 3)' "$E/sdlc/stages/06-deploy.md" > "$E/s" && printf '\n## Notes\n\n- Rule: lạc chỗ\n' >> "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "Rule nằm dưới heading khác không tính → chặn" "CAP-deploy-03: thiếu \"- Rule:\""
moi; thay "$E/sdlc/stages/06-deploy.md" '### CAP-deploy-03 — ' '#### CAP-deploy-03 — '
vi_pham "capability với heading #### → chặn, không lờ đi" "stage deploy: heading capability \"#### CAP-deploy-03"
moi; thay "$E/sdlc/stages/06-deploy.md" '### CAP-deploy-03 — ' '### Cap-deploy-03 — '
vi_pham "capability viết thường Cap- → chặn, không lờ đi" "stage deploy: heading capability \"### Cap-deploy-03"
moi; thay "$E/sdlc/stages/06-deploy.md" '### CAP-deploy-03 — ' '### Rollback — '
vi_pham "heading lạ trong ## Capabilities → chặn" "stage deploy: heading capability \"### Rollback"
# Artifact: loại capability bảo đảm, phải nằm trong provides của stage; mỗi provides có capability trỏ tới.
# 06-deploy.md có ba dòng "- Artifact: delivery" nên sửa theo thứ tự (++n), không dùng thay.
moi; awk '!(/^- Artifact:/ && ++n == 1)' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "capability thiếu Artifact → chặn" "CAP-deploy-01: thiếu \"- Artifact:\" — thêm loại artifact capability này bảo đảm, lấy trong provides của stage deploy: delivery."
moi; awk '{ if (/^- Artifact:/ && ++n == 1) print "- Artifact:"; else print }' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "Artifact rỗng → chặn" "CAP-deploy-01: thiếu \"- Artifact:\""
moi; awk '{ if (/^- Artifact:/ && ++n == 1) print "- Artifact: deliveryx"; else print }' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "Artifact không có trong provides → chặn" "CAP-deploy-01: Artifact \"deliveryx\" không có trong provides của stage deploy (delivery)"
moi; thay "$E/sdlc/stages/04-implement.md" '- Artifact: task-evidence' '- Artifact: change'
vi_pham "provides không capability nào trỏ tới → chặn" "stage implement: provides \"task-evidence\" — không capability nào khai \"Artifact: task-evidence\""
moi; awk '!(/^- Artifact:/ && ++n == 3)' "$E/sdlc/stages/06-deploy.md" > "$E/s" && printf '\n## Notes\n\n- Artifact: delivery\n' >> "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "Artifact nằm dưới heading khác không tính → chặn" "CAP-deploy-03: thiếu \"- Artifact:\""
moi; thay "$E/sdlc/stages/01-require.md" '- Artifact: open-questions' '- Artifact:  requirements ,open-questions '
ky_vong 0 "Artifact nhiều giá trị, có khoảng trắng → ĐẠT" sh "$SC" "$E"
# dòng Artifact thứ hai không được âm thầm đè dòng đầu (giá trị gõ sai sẽ bị giấu)
moi; awk '{ print } /^- Artifact:/ && ++n == 1 { print "- Artifact: bogus" }' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "capability khai Artifact hai dòng → chặn" "CAP-deploy-01: khai \"- Artifact:\" nhiều dòng — gộp vào một dòng, cách nhau dấu phẩy."
moi; thay "$E/sdlc/stages/06-deploy.md" '  - delivery' '  - delivery  '
ky_vong 0 "mục provides có khoảng trắng cuối dòng → vẫn ĐẠT" sh "$SC" "$E"
# stage thiếu provides: chỉ báo "thiếu provides", không thêm một lỗi Artifact cho mỗi capability
moi; thay "$E/sdlc/stages/07-operate.md" 'provides:
  - operational-feedback' 'provides: []'
vi_pham "stage thiếu provides → chặn" "stage operate: thiếu provides"
dung "…không kèm lỗi Artifact cho từng capability" sh -c "! grep -q 'provides của stage operate' '$TMP/ra'"
moi; sed 's/$/\r/' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
ky_vong 0 "file stage CRLF → vẫn ĐẠT" sh "$SC" "$E"

# ---------------------------------------------------------------- invariant
nhom "check-sdlc.sh: invariant trỏ tới checker + test có thật"
moi; thay "$E/sdlc/stages/05-verify.md" '  - INV-004' '  - INV-099'
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
# mọi invariant nêu tên ca test (không chỉ file); Rule: trừu tượng, cú pháp engine ở "- Engine:"
moi; awk '/^### INV-007 / { on = 1 } /^### INV-008 / { on = 0 } { if (on && /^- Tested by:/) sub(/` .*$/, "`"); print }' "$E/sdlc/invariants.md" > "$E/i" && mv "$E/i" "$E/sdlc/invariants.md"
vi_pham "invariant chỉ trỏ file test, không nêu ca → chặn" "INV-007: \"Tested by:\" không nêu ca test nào — thêm tên ca (trong \"…\") sau đường dẫn file."
moi; awk '/^### INV-001 / { on = 1 } /^### INV-002 / { on = 0 } { if (on && /^- Rule:/) $0 = $0 " See `plan.md`."; print }' "$E/sdlc/invariants.md" > "$E/i" && mv "$E/i" "$E/sdlc/invariants.md"
vi_pham "Rule: của invariant có backtick → chặn" "INV-001: \"Rule:\" chứa cú pháp engine"
moi; awk '/^### INV-001 / { on = 1 } /^### INV-002 / { on = 0 } { if (on && /^- Rule:/) $0 = $0 " Like REQ-001."; print }' "$E/sdlc/invariants.md" > "$E/i" && mv "$E/i" "$E/sdlc/invariants.md"
vi_pham "Rule: của invariant có mã REQ- → chặn" "INV-001: \"Rule:\" chứa cú pháp engine (REQ-)"
moi; awk '{ if (/^- Rule:/ && ++n == 1) $0 = $0 " Based on DEC-001."; print }' "$E/sdlc/stages/06-deploy.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/06-deploy.md"
vi_pham "Rule: của capability có mã DEC- → chặn" "CAP-deploy-01: \"Rule:\" chứa cú pháp engine (DEC-)"
moi; awk '/^### INV-001 / { on = 1 } /^### INV-002 / { on = 0 } { print; if (on && /^- Rule:/) print "- Engine: task line `Covers: REQ-NNN`" }' "$E/sdlc/invariants.md" > "$E/i" && mv "$E/i" "$E/sdlc/invariants.md"
ky_vong 0 "\"- Engine:\" được dùng backtick và mã → ĐẠT" sh "$SC" "$E"
moi; thay "$E/sdlc/stages/00-plan.md" 'skippable: false' 'skippable: maybe'
vi_pham "stage có skippable lạ → chặn" "stage plan: skippable \"maybe\" — chỉ nhận true | false"

# ---------------------------------------------------------------- tập con YAML
nhom "check-sdlc.sh: dòng YAML ngoài tập con bị chặn, kèm file + dòng"
# so_dong <file> <dòng nguyên văn> -> số dòng đầu tiên trùng
so_dong() { awk -v d="$2" '$0 == d { print NR; exit }' "$1"; }
moi; thay "$E/sdlc/stages/06-deploy.md" 'exit: both' 'exit:both'
vi_pham "frontmatter stage: thiếu dấu cách sau : → chặn" "sdlc/stages/06-deploy.md: dòng $(so_dong "$E/sdlc/stages/06-deploy.md" 'exit:both'): thiếu dấu cách sau \":\""
moi; thay "$E/workflow/phases/04-implement.md" '  - diff' '	- diff'
vi_pham "frontmatter phase: thụt bằng tab → chặn" "workflow/phases/04-implement.md: dòng $(so_dong "$E/workflow/phases/04-implement.md" '	- diff'): thụt lề bằng tab"
moi; thay "$E/sdlc/profiles/bugfix.md" '  - design' '      - design'
vi_pham "frontmatter profile: thụt sâu → chặn" "sdlc/profiles/bugfix.md: dòng $(so_dong "$E/sdlc/profiles/bugfix.md" '      - design'): thụt sâu hơn tập con cho phép"
moi; thay "$E/workflow.yaml" 'language: vi' 'language: |'
vi_pham "workflow.yaml: giá trị khối | → chặn" "workflow.yaml: dòng $(so_dong "$E/workflow.yaml" 'language: |'): giá trị khối | / > không được hỗ trợ"
moi; thay "$E/workflow.yaml" 'version: 1' 'version: {a: b}'
vi_pham "workflow.yaml: dạng {…} → chặn" "workflow.yaml: dòng $(so_dong "$E/workflow.yaml" 'version: {a: b}'): dạng {…} hoặc danh sách [a, b] không được hỗ trợ"
moi; thay "$E/sdlc/profiles/bugfix.md" 'adds_invariants:
  - INV-007' 'adds_invariants: [INV-007, INV-008]'
vi_pham "frontmatter: danh sách [a, b] → chặn" "sdlc/profiles/bugfix.md: dòng $(so_dong "$E/sdlc/profiles/bugfix.md" 'adds_invariants: [INV-007, INV-008]'): dạng {…} hoặc danh sách [a, b] không được hỗ trợ"
moi; thay "$E/sdlc/stages/00-plan.md" 'exit: both' 'exit: both
lạc dòng'
vi_pham "frontmatter: dòng lạ → chặn" "sdlc/stages/00-plan.md: dòng $(so_dong "$E/sdlc/stages/00-plan.md" 'lạc dòng'): dòng không thuộc tập con YAML"
moi; thay "$E/workflow.yaml" '  - id: cursor' '  # chú thích thụt lề

  - id: cursor'
ky_vong 0 "workflow.yaml: chú thích thụt lề, dòng trống trong danh sách → ĐẠT" sh "$SC" "$E"

ket_thuc
