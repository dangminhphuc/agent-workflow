#!/usr/bin/env sh
# Interface SDLC: cú pháp và chú thích — tập con YAML, Rule: trừu tượng, Tested by: nêu ca, "# giữ:" (tools/check-sdlc.sh).
# Chạy riêng: sh tools/tests/23-sdlc-syntax.sh (AW_TEST_VERBOSE=1 in từng ca). Tách khỏi 22-sdlc-stage-files (chậm).

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


nhom "check-sdlc.sh: Rule: trừu tượng, Tested by: nêu ca"
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


# Capability machine có phase nhận phải có luật checker khai "# giữ: CAP-…" (bước A, đợt 1)
nhom "check-sdlc.sh: luật checker khai capability / invariant nó giữ (# giữ:)"
moi; printf '# giữ: CAP-plan-99\n' >> "$E/tools/check-plan.sh"
vi_pham "# giữ: trỏ id không có → chặn" "tools/check-plan.sh: \"# giữ: CAP-plan-99\" — không có capability / invariant đó"
moi; printf '# giữ: INV-099\n' >> "$E/tools/check-plan.sh"
vi_pham "# giữ: trỏ invariant không có → chặn" "tools/check-plan.sh: \"# giữ: INV-099\" — không có capability / invariant đó"
moi; for f in "$E"/tools/*.sh "$E"/tools/lib/*.sh; do sed 's/CAP-plan-01//g' "$f" > "$f.x" && mv "$f.x" "$f"; done
vi_pham "capability machine được nhận mà không luật nào khai → chặn" "CAP-plan-01: Judged by machine, phase intake nhận, nhưng không luật checker nào khai \"# giữ: CAP-plan-01\""
moi; for f in "$E"/tools/*.sh "$E"/tools/lib/*.sh; do sed 's/CAP-deploy-01//g' "$f" > "$f.x" && mv "$f.x" "$f"; done
ky_vong 0 "capability human (CAP-deploy-01) không cần # giữ: → ĐẠT" sh "$SC" "$E"

ket_thuc
