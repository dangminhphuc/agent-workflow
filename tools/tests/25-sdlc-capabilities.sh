#!/usr/bin/env sh
# Interface SDLC: capability trong file stage — heading, Rule, Judged by, Artifact (tools/check-sdlc.sh).
# Chạy riêng: sh tools/tests/25-sdlc-capabilities.sh (AW_TEST_VERBOSE=1 in từng ca). Tách khỏi 22-sdlc-stage-files (chậm).

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

# --suy: id mà diff đã gắn, không tự gắn
nhom "--suy"
printf '# giữ: CAP-require-01, INV-007\n# giữ: CAP-require-01\n' > "$TMP/suy-a.sh"
printf 'CAP-require-01\nINV-007\n' > "$TMP/suy-mong"
ky_vong 0 "--suy in từng id một lần" sh -c "sh '$SC' --suy '$TMP/suy-a.sh' | cmp -s - '$TMP/suy-mong'"
printf '# giữ: CAP-khong-co\n' > "$TMP/suy-b.sh"
ky_vong 1 "--suy id không có → KHÔNG ĐẠT" sh "$SC" --suy "$TMP/suy-b.sh"
ky_vong 2 "--suy thiếu file → SAI THAM SỐ" sh "$SC" --suy
ky_vong 0 "--suy file không có # giữ thì in rỗng" sh -c "printf 'echo x\n' > '$TMP/suy-c.sh'; sh '$SC' --suy '$TMP/suy-c.sh' | cmp -s - /dev/null"

ket_thuc
