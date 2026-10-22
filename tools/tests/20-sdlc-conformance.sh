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
dung "…in ánh xạ stage → phase" sh -c "sh '$SC' '$E' 2>/dev/null | grep -Eq '^  implement +partial +implement$' && sh '$SC' '$E' 2>/dev/null | grep -Eq '^  breakdown +implemented +plan$'"
ky_vong 2 "thư mục không phải engine → SAI THAM SỐ" sh "$SC" "$TMP/khong-co"
ky_vong 2 "thừa tham số → SAI THAM SỐ" sh "$SC" "$E" "$E"
dung "…bảng ánh xạ in trạng thái suy ra" sh -c "sh '$SC' '$ROOT' 2>/dev/null | grep -Eq '^  verify +partial +review'"
sh "$SC" "$ROOT" > "$TMP/sdlc-ra" 2>/dev/null
dung "…trạng thái suy ra đúng cả 8 stage" bang "$(awk '/^Stage → phase/ { p = 1; next } /^[^ ]/ { p = 0 } p { printf "%s=%s ", $1, $2 }' "$TMP/sdlc-ra")" \
  "plan=partial require=implemented design=implemented breakdown=implemented implement=partial verify=partial deploy=partial operate=gap "
dung "…roadmap liệt kê đúng các capability chưa phase nào nhận" bang "$(awk '/^    CAP-/ { printf "%s ", $1 }' "$TMP/sdlc-ra")" \
  "CAP-plan-03 CAP-plan-04 CAP-implement-05 CAP-verify-03 CAP-verify-04 CAP-verify-05 CAP-deploy-02 CAP-deploy-03 CAP-operate-01 CAP-operate-02 "
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
moi; thay "$E/workflow.yaml" '  - stage: deploy
    note:' '  - stage: deploy
    status:
    note:'
vi_pham "khối sdlc: khoá status không giá trị → vẫn chặn" "khối sdlc: stage deploy còn khoá status — xoá dòng status"
moi; thay "$E/workflow.yaml" 'note: Dừng ở MR/PR' 'note: A | B — Dừng ở MR/PR'
dung "…note có dấu | → roadmap in nguyên note" sh -c "sh '$SC' '$E' 2>/dev/null | grep -q '^  deploy (partial): A | B — Dừng ở MR/PR'"
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
# implement thành implemented khi phase nhận nốt CAP-implement-05 (sau SP3): note phải bị đòi xoá
moi; thay "$E/workflow/phases/04-implement.md" '  - CAP-implement-06' '  - CAP-implement-06
  - CAP-implement-05'
vi_pham "implement nhận đủ capability mà còn note → chặn" "stage implement: suy ra implemented nhưng khối sdlc: còn note"
awk '/^  - stage: implement$/ { bo = 1; next } bo && /^    / { next } { bo = 0; print }' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
ky_vong 0 "implement nhận đủ + xoá note → ĐẠT" sh "$SC" "$E"
dung "…stage implement thành implemented" sh -c "sh '$SC' '$E' 2>/dev/null | grep -Eq '^  implement +implemented +implement$'"

# ---------------------------------------------------------------- phase ↔ stage
nhom "check-sdlc.sh: phase khai implements / provides"
moi; awk '!/^implements:/' "$E/workflow/phases/05-review.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/05-review.md"
vi_pham "phase thiếu implements → chặn" "phase review: thiếu implements"
moi; thay "$E/workflow/phases/05-review.md" 'implements: verify' 'implements: test'
vi_pham "phase implements stage không có → chặn" "phase review: implements \"test\" — không có stage đó"
moi; awk '!/^  - requirements: spec.md$/' "$E/workflow/phases/01-spec.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/01-spec.md"
vi_pham "provides của phase không phủ provides của stage → chặn" "stage require: không phase nào provides \"requirements\""
moi; awk '!/^  - security-evidence: security-results.md$/' "$E/workflow/phases/04-implement.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/04-implement.md"
vi_pham "bằng chứng quét bảo mật không phase nào map ra file → chặn" "stage implement: không phase nào provides \"security-evidence\""
moi; awk '!/^  - task-evidence: task-results.md$/' "$E/workflow/phases/04-implement.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/04-implement.md"
vi_pham "bằng chứng từng task không phase nào map ra file → chặn" "stage implement: không phase nào provides \"task-evidence\""
moi; awk '!/^  - security-evidence$/' "$E/sdlc/stages/04-implement.md" > "$E/s" && mv "$E/s" "$E/sdlc/stages/04-implement.md"
vi_pham "verify cần bằng chứng quét bảo mật mà không stage trước nào cung cấp → chặn" "stage verify: requires \"security-evidence\" — không stage nào trước nó provides"
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
# Đổi chỗ plan và implement: trước khi tách stage breakdown, hai phase cùng stage nên lọt qua
moi; thay "$E/workflow.yaml" '  - id: plan
    file: workflow/phases/03-plan.md' 'TAM'
thay "$E/workflow.yaml" '  - id: implement
    file: workflow/phases/04-implement.md' '  - id: plan
    file: workflow/phases/03-plan.md'
thay "$E/workflow.yaml" 'TAM' '  - id: implement
    file: workflow/phases/04-implement.md'
vi_pham "đổi chỗ phase plan và implement → chặn" "phase plan (stage breakdown) đứng sau phase implement (stage implement)"
moi; thay "$E/workflow/clarify.md" 'id: clarify' 'id: clarify
implements: require'
vi_pham "utility command khai implements → chặn" "utility command clarify: khai implements"
moi; thay "$E/workflow/phases/06-ship.md" '  - CAP-deploy-01' '  - CAP-deploy-09'
vi_pham "phase nhận capability không tồn tại → chặn" "phase ship: capabilities \"CAP-deploy-09\" — không có capability đó"
moi; thay "$E/workflow/phases/06-ship.md" '  - CAP-deploy-01' '  - CAP-deploy-01
  - CAP-verify-03'
vi_pham "phase nhận capability của stage khác → chặn" "phase ship: capabilities \"CAP-verify-03\" thuộc stage verify, phase implements deploy"
# Thêm phase thứ hai cho stage implement (chép 04-implement, đổi id) — cùng nhận CAP-implement-02
moi; sed 's/^id: implement$/id: implement-extra/' "$E/workflow/phases/04-implement.md" > "$E/workflow/phases/04b-extra.md"
thay "$E/workflow.yaml" '  - id: review
' '  - id: implement-extra
    file: workflow/phases/04b-extra.md
    required: true
  - id: review
'
ky_vong 0 "hai phase cùng nhận một capability → ĐẠT" sh "$SC" "$E"
moi; thay "$E/workflow/clarify.md" 'id: clarify' 'id: clarify
capabilities:
  - CAP-require-01'
vi_pham "utility command khai capabilities → chặn" "utility command clarify: khai capabilities"

ket_thuc
