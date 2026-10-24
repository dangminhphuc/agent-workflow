#!/usr/bin/env sh
# aw journal (SP9b): cột version, mốc phase, retro, report mới.
# Chạy riêng: sh tools/tests/27-journal-retro.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
tao_fixture

# ---------------------------------------------------------------- cột version (Task 1)
nhom "SP9b: mọi nguồn ghi nhật ký có cột version cuối"
NK="$T/journal.sh"; JD="$CFG/journal"
V=$(tr -d ' \r\n' < "$ROOT/VERSION")
rm -rf "$JD"
ky_vong 0 "aw-engine check plan ĐẠT" sh "$AWE" check plan "$F"
dung "checks.tsv: mỗi dòng 6 cột" sh -c "awk -F'\t' 'NF != 6 { bad = 1 } END { exit bad }' '$JD/checks.tsv'"
dung "checks.tsv: cột cuối = version engine" sh -c "awk -F'\t' -v v='$V' '\$NF != v { bad = 1 } END { exit bad }' '$JD/checks.tsv'"
ky_vong 0 "journal add env" sh "$NK" add env "thiếu node_modules trong worktree mới"
dung "failures.tsv: cột cuối = version engine" sh -c "awk -F'\t' -v v='$V' '\$NF == v' '$JD/failures.tsv' | grep -q ."
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
OUT_AP=$(sh "$T/approvals.sh" 2>/dev/null)
H_AP=$(printf '%s\n' "$OUT_AP" | sed -n "s|.*duyệt: aw approvals tick $F spec ||p")
ky_vong 0 "aw approvals tick spec" sh "$T/approvals.sh" tick "$F" spec "$H_AP"
dung "approvals.tsv: cột cuối = version engine" sh -c "awk -F'\t' -v v='$V' '\$NF == v' '$JD/approvals.tsv' | grep -q ."
ket_thuc
