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
moi; thay "$E/workflow/phases/03-plan.md" 'implements: breakdown' 'implements: [breakdown]'
vi_pham "frontmatter: danh sách một mục [x] → chặn (fm_list đọc thành rỗng)" "workflow/phases/03-plan.md: dòng $(so_dong "$E/workflow/phases/03-plan.md" 'implements: [breakdown]'): dạng {…} hoặc danh sách [a, b] không được hỗ trợ"


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

# Đợt 2: luật mới phải gắn "# giữ:"; luật cũ chưa gắn được đếm trong tools/unclassified-rules.txt, chỉ được giảm
nhom "check-sdlc.sh: luật checker chưa phân loại (tools/unclassified-rules.txt)"
DS="$E/tools/unclassified-rules.txt"
moi; printf '\nloi "luật mới chưa gắn id"\n' >> "$E/tools/check-plan.sh"
vi_pham "luật mới không gắn # giữ: → chặn" "tools/check-plan.sh: "
dung "…nêu số chưa gắn và số cho phép" grep -q 'luật chưa gắn "# giữ:" (cho phép [0-9]* trong tools/unclassified-rules.txt)' "$TMP/ra"
moi; printf '\n# giữ: CAP-breakdown-01\nloi "luật mới đã gắn id"\n' >> "$E/tools/check-plan.sh"
ky_vong 0 "luật mới có # giữ: ngay trên → ĐẠT" sh "$SC" "$E"
moi; awk '/SECURITY_CMDS: dòng/ && !d { print "    # giữ: CAP-implement-03"; d = 1 } { print }' "$E/tools/check-security.sh" > "$E/x" && mv "$E/x" "$E/tools/check-security.sh"
vi_pham "gắn thêm id mà quên hạ số cho phép → chặn" "tools/unclassified-rules.txt: tools/check-security.sh cho phép"
moi; awk '$1 != "tools/check-ship.sh"' "$DS" > "$E/x" && mv "$E/x" "$DS"
vi_pham "file có luật chưa gắn mà không có trong danh sách → chặn" "tools/check-ship.sh: "
moi; printf 'tools/check-khong-co.sh 3\n' >> "$DS"
vi_pham "danh sách trỏ file không có → chặn" "tools/unclassified-rules.txt: tools/check-khong-co.sh không có"
moi; printf 'tools/check-plan.sh nhieu\n' >> "$DS"
vi_pham "dòng danh sách sai dạng → chặn" "tools/unclassified-rules.txt: dòng \"tools/check-plan.sh nhieu\" sai dạng"
moi; printf '\necho "  [LỖI] luật mới dạng echo"\n' >> "$E/tools/check-plan.sh"
vi_pham "luật mới dạng echo \"[LỖI]\" không gắn # giữ: → chặn" "tools/check-plan.sh: "
moi; printf '\ncanh_bao "luật mới dạng canh_bao"\n' >> "$E/tools/check-conventions.sh"
vi_pham "luật mới dạng canh_bao không gắn # giữ: → chặn" "tools/check-conventions.sh: "
moi; printf '\necho "TỪ CHỐI: luật mới của task.sh" >&2; exit 1\n' >> "$E/tools/task.sh"
vi_pham "luật mới của task.sh (TỪ CHỐI:) không gắn # giữ: → chặn" "tools/task.sh: "
moi; printf '\n# giữ: CAP-breakdown-01\nloi "luật một"\nloi "luật hai"\n' >> "$E/tools/check-plan.sh"
vi_pham "một # giữ: chỉ phủ luật ngay dưới nó, không phủ luật thứ hai → chặn" "tools/check-plan.sh: "
moi; printf '\ncanh_bao2() { echo "  [CẢNH BÁO] $1"; }\nfunction loi2(msg) { print "  [LỖI] " msg }\n' >> "$E/tools/check-plan.sh"
vi_pham "định nghĩa hàm in [LỖI]/[CẢNH BÁO] tên lạ vẫn là chỗ luật → chặn" "tools/check-plan.sh: "
moi; printf '\ncanh_bao() { echo "  [CẢNH BÁO] $1"; }\nfunction loi(msg) { n_loi++; print "  [LỖI] " msg }\n  BEGIN { n_loi = loi_truoc }\n' >> "$E/tools/check-plan.sh"
ky_vong 0 "định nghĩa loi/canh_bao và BEGIN { n_loi = loi_truoc } không phải luật → ĐẠT" sh "$SC" "$E"
moi; l=$(grep '^tools/check-plan.sh ' "$DS"); printf '%s\n' "$l" >> "$DS"
vi_pham "danh sách có dòng trùng file → chặn" "tools/unclassified-rules.txt: tools/check-plan.sh lặp"
moi; printf 'tools/check-release.sh 1\n' >> "$DS"
vi_pham "danh sách trỏ file không được đếm → chặn" "tools/unclassified-rules.txt: tools/check-release.sh không phải file được đếm"
moi; awk '$1 == "tools/check-plan.sh" { $0 = $1 "\t " $2 } { print }' "$DS" > "$E/x" && mv "$E/x" "$DS"
ky_vong 0 "dòng danh sách cách bằng tab/nhiều dấu cách vẫn đọc được → ĐẠT" sh "$SC" "$E"
moi
dung "--dem-luat in danh sách đúng dạng, khớp file đang dùng" sh -c "sh '$SC' --dem-luat '$E' | diff - '$DS' >&2"

ket_thuc
