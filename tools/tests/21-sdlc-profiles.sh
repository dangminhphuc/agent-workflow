#!/usr/bin/env sh
# Interface SDLC: profile theo job type (sdlc/profiles/, tools/check-sdlc.sh).
# Chạy riêng: sh tools/tests/21-sdlc-profiles.sh (AW_TEST_VERBOSE=1 in từng ca).

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

# ---------------------------------------------------------------- profile theo job type
nhom "check-sdlc.sh: profile — một profile cho mỗi job type"
ky_vong 0 "engine của repo này (profile khớp engine) → PASS" sh "$SC" "$ROOT"
moi
ky_vong 0 "bản chép chưa sửa → PASS" sh "$SC" "$E"
dung "engine hiện tại: in ma trận job type × stage" sh -c "sh '$SC' '$ROOT' 2>/dev/null | grep -Eq '^  chore +chạy +chạy +bỏ +chạy +chạy +chạy +tuỳ +gap'"
dung "…và loại có thể vắng theo profile" sh -c "sh '$SC' '$ROOT' 2>/dev/null | grep -q 'bugfix: có thể vắng: design'"
moi; rm -f "$E/sdlc/profiles/chore.md"
vi_pham "job type không có profile → chặn" "job type chore: thiếu sdlc/profiles/chore.md"
moi; sed 's/^id: feature$/id: hotfix/' "$E/sdlc/profiles/feature.md" > "$E/sdlc/profiles/hotfix.md"
vi_pham "profile cho thứ không phải job type → chặn" "profile hotfix: không phải job type engine hỗ trợ"
moi; thay "$E/tools/lib/cross-check.sh" 'LOAI_HOP_LE="feature bugfix refactor perf chore"' 'LOAI_HOP_LE="feature bugfix refactor perf chore spike"'
vi_pham "job type mới trong engine mà chưa có profile → chặn (đọc từ nguồn checker intake dùng)" "job type spike: thiếu sdlc/profiles/spike.md"
moi; thay "$E/tools/lib/cross-check.sh" 'LOAI_HOP_LE=' 'LOAI_KHAC='
vi_pham "không đọc được danh sách job type → chặn" "không đọc được danh sách job type (LOAI_HOP_LE trong tools/lib/cross-check.sh)"
moi; thay "$E/sdlc/profiles/bugfix.md" 'id: bugfix' 'id: bug'
vi_pham "id profile lệch tên file → chặn" "sdlc/profiles/bugfix.md: id \"bug\" lệch tên file"

nhom "check-sdlc.sh: profile — stage bỏ được khớp interface và engine"
moi; thay "$E/sdlc/profiles/feature.md" '  - deploy' '  - deploy
  - release'
vi_pham "skippable nêu stage không có → chặn" "profile feature: skippable \"release\" — không có stage đó"
moi; thay "$E/sdlc/profiles/feature.md" '  - deploy' '  - deploy
  - implement'
vi_pham "bỏ stage có skippable: false → chặn" "profile feature: stage implement không được bỏ (skippable: false trong sdlc/stages/)"
moi; thay "$E/sdlc/profiles/chore.md" '  - deploy' '  - deploy
  - design'
vi_pham "stage vừa skippable vừa skipped → chặn" "profile chore: stage design vừa skippable vừa skipped"
moi; thay "$E/sdlc/profiles/feature.md" '  - deploy' '  - deploy
  - operate'
vi_pham "khai stage gap trong profile → chặn" "profile feature: stage operate là gap — engine không chạy nó với job type nào"
moi; thay "$E/sdlc/profiles/feature.md" '  - deploy' '  - deploy
  - design'
vi_pham "design skippable mà engine luôn chạy design → chặn" "profile feature: khai design skippable nhưng engine luôn chạy design với feature"
moi; thay "$E/sdlc/profiles/bugfix.md" '  - design
' ''
vi_pham "engine cho Design: skip mà profile không khai → chặn" "profile bugfix: engine bỏ được design với bugfix (Design: skip) nhưng profile không khai skippable"
moi; thay "$E/sdlc/profiles/chore.md" 'skipped:
  - design' 'skipped: []'
thay "$E/sdlc/profiles/chore.md" '  - deploy' '  - deploy
  - design'
vi_pham "engine luôn bỏ design mà profile khai skippable → chặn" "profile chore: engine luôn bỏ design với chore nhưng profile khai skippable"
moi; thay "$E/tools/lib/cross-check.sh" '    bugfix|refactor) [ "$(kc_design "$1")" = skip ] ;;' '    bugfix|refactor|perf) [ "$(kc_design "$1")" = skip ] ;;'
vi_pham "đọc hành vi thật của engine: perf được Design: skip → profile perf lệch → chặn" "profile perf: engine bỏ được design với perf (Design: skip) nhưng profile không khai skippable"
moi; thay "$E/sdlc/profiles/feature.md" 'skippable:
  - deploy' 'skippable: []'
vi_pham "phase required: false mà profile không khai skippable → chặn" "profile feature: stage deploy có thể không chạy (phase ship required: false) nhưng profile không khai skippable"
moi; thay "$E/sdlc/profiles/feature.md" 'skippable:
  - deploy
skipped: []' 'skippable: []
skipped:
  - deploy'
vi_pham "stage có phase required: false khai skipped → chặn" "profile feature: stage deploy khai skipped nhưng phase ship vẫn chạy được (required: false)"
moi; thay "$E/workflow.yaml" '    required: false
    when:' '    required: true
    when:'
vi_pham "skippable mà phase required: true → chặn" "profile feature: khai deploy skippable nhưng engine luôn chạy deploy (phase ship required: true)"

nhom "check-sdlc.sh: profile — artifact và invariant thêm theo job type"
moi; thay "$E/sdlc/profiles/bugfix.md" '  - implement: reproduction-evidence' '  - implement reproduction-evidence'
vi_pham "adds_provides sai dạng → chặn" "profile bugfix: adds_provides \"implement reproduction-evidence\" — cần dạng <stage>: <loại>"
moi; thay "$E/sdlc/profiles/bugfix.md" '  - implement: reproduction-evidence' '  - build: reproduction-evidence'
vi_pham "adds_provides nêu stage không có → chặn" "profile bugfix: adds_provides \"build: reproduction-evidence\" — không có stage build"
moi; awk '!/^  - reproduction-evidence: repro.md$/' "$E/workflow/phases/04-implement.md" > "$E/p" && mv "$E/p" "$E/workflow/phases/04-implement.md"
vi_pham "adds_provides không phase nào map ra file → chặn" "profile bugfix: adds_provides \"implement: reproduction-evidence\" — không phase nào của stage implement map loại đó ra file"
moi; thay "$E/sdlc/profiles/bugfix.md" '  - implement: reproduction-evidence' '  - design: reproduction-evidence'
vi_pham "adds_provides ở stage có thể không chạy → chặn" "profile bugfix: adds_provides \"design: reproduction-evidence\" — stage design có thể không chạy với bugfix"
moi; thay "$E/sdlc/profiles/perf.md" '  - implement: performance-evidence' '  - implement: benchmark'
vi_pham "phase map loại không stage hay profile nào khai → chặn" "phase implement: provides \"performance-evidence\" — stage implement không khai loại đó, không profile nào thêm"
moi; thay "$E/sdlc/profiles/bugfix.md" '  - verify: reproduction-evidence' '  - verify: performance-evidence'
vi_pham "adds_requires không stage trước luôn chạy cung cấp → chặn" "profile bugfix: adds_requires \"verify: performance-evidence\" — không stage nào trước verify luôn chạy và provides loại đó"
moi; thay "$E/sdlc/profiles/bugfix.md" '  - verify: reproduction-evidence' '  - plan: reproduction-evidence'
vi_pham "adds_requires mà stage cung cấp đứng sau → chặn" "profile bugfix: adds_requires \"plan: reproduction-evidence\" — không stage nào trước plan luôn chạy và provides loại đó"
moi; thay "$E/sdlc/profiles/chore.md" 'adds_requires: []' 'adds_requires:
  - design: change'
vi_pham "adds_requires ở stage bị bỏ → chặn" "profile chore: adds_requires \"design: change\" — stage design không chạy với chore"
moi; thay "$E/sdlc/profiles/bugfix.md" '  - INV-007' '  - INV-099'
vi_pham "adds_invariants không có trong invariants.md → chặn" "profile bugfix: invariant INV-099 không có trong sdlc/invariants.md"

moi; thay "$E/sdlc/profiles/perf.md" 'purpose: ' 'purpose_x: '
vi_pham "profile thiếu purpose → chặn" "profile perf: thiếu purpose"
moi; thay "$E/sdlc/profiles/refactor.md" 'skippable:
  - design
  - deploy
skipped: []' 'skippable:
  - deploy
skipped:
  - design'
vi_pham "engine chỉ bỏ design khi Design: skip mà profile khai skipped → chặn" "profile refactor: engine chỉ bỏ design với refactor khi spec khai Design: skip nhưng profile khai skipped"
moi; thay "$E/tools/lib/cross-check.sh" 'kc_bo_design() {' 'kc_khong_design() {'
vi_pham "không thấy hàm engine dùng để bỏ design → chặn" "không thấy kc_bo_design trong tools/lib/cross-check.sh"

ket_thuc
