#!/usr/bin/env sh
# Interface SDLC: trạng thái stage suy ra, note của khối sdlc:, out_of_scope (tools/check-sdlc.sh).
# Chạy riêng: sh tools/tests/24-sdlc-stage-status.sh (AW_TEST_VERBOSE=1 in từng ca). Tách khỏi 20-sdlc-conformance (chậm).

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
awk '!/^  - CAP-deploy-02:/' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"  # nhận thì không còn out-of-scope
vi_pham "nhận đủ capability mà còn note → chặn" "stage deploy: suy ra implemented nhưng khối sdlc: còn note"
# chiều ngược: nhận đủ + xoá mục khối sdlc: → ĐẠT, stage thành implemented
awk '/^  - stage: deploy$/ { bo = 1; next } bo && /^    / { next } { bo = 0; print }' "$E/workflow.yaml" > "$E/w" && mv "$E/w" "$E/workflow.yaml"
ky_vong 0 "nhận đủ capability + xoá note → ĐẠT" sh "$SC" "$E"
dung "…stage deploy thành implemented" sh -c "sh '$SC' '$E' 2>/dev/null | grep -Eq '^  deploy +implemented +ship'"
moi; awk '/^capabilities:$/ { print "capabilities: []"; next } !/^  - CAP-/' "$E/workflow/phases/06-ship.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/06-ship.md"
vi_pham "phase implements mà không nhận capability nào → chặn" "phase ship: implements deploy nhưng không nhận capability nào"
moi; thay "$E/workflow.yaml" '  - stage: operate' '  - stage: monitor'
vi_pham "khối sdlc: khai stage không có → chặn" "khối sdlc: khai stage \"monitor\" không có trong sdlc/stages/"
# out_of_scope: capability engine quyết không làm, kèm lý do — không đổi trạng thái stage
moi; thay "$E/workflow.yaml" 'out_of_scope:' 'out_of_scope:
  - CAP-verify-99: không có'
vi_pham "out_of_scope: id không có → chặn" "out_of_scope: CAP-verify-99 không có trong sdlc/stages/."
moi; thay "$E/workflow.yaml" 'out_of_scope:' 'out_of_scope:
  - CAP-deploy-01: thử'
vi_pham "out_of_scope: id đã được phase nhận → chặn" "out_of_scope: CAP-deploy-01 vừa out-of-scope vừa được phase ship nhận — chọn một."
moi; thay "$E/workflow.yaml" 'out_of_scope:' 'out_of_scope:
  - CAP-verify-05:'
vi_pham "out_of_scope: thiếu lý do → chặn" "out_of_scope: CAP-verify-05 thiếu lý do — ghi vì sao engine không làm."
moi; thay "$E/workflow.yaml" 'out_of_scope:' 'out_of_scope:
  - CAP-verify-03: lặp'
vi_pham "out_of_scope: id khai hai lần → chặn" "out_of_scope: CAP-verify-03 khai hai lần."


ket_thuc
