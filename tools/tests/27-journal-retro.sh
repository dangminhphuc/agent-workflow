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

# ---------------------------------------------------------------- export/report: cũ lẫn mới, --version (Task 2)
nhom "SP9b: export và report đọc cả export cũ lẫn mới, có --version"
ky_vong 0 "export mới (máy may-a)" env AW_JOURNAL_MACHINE=may-a sh "$NK" export "$TMP/moi.tsv"
awk -F'\t' 'BEGIN { OFS = "\t" } { NF = NF - 1; print }' "$TMP/moi.tsv" > "$TMP/cu.tsv"
n_moi=$(sh "$NK" report "$TMP/moi.tsv" | awk '$1 == "plan" { print $2; exit }')
[ -n "$n_moi" ] || ca_hong "fixture không có lần chạy check plan — ca export/report không kiểm được gì"
dung "export cũ (không cột version) đọc được: đếm đúng" bang "$(sh "$NK" report "$TMP/cu.tsv" | awk '$1 == "plan" { print $2; exit }')" "$n_moi"
dung "export cũ + mới trong một report: cộng dồn, không dòng nào bị bỏ" sh -c "! sh '$NK' report '$TMP/moi.tsv' '$TMP/cu.tsv' | grep -q 'bỏ'"
dung "…cộng dồn đúng" bang "$(sh "$NK" report "$TMP/moi.tsv" "$TMP/cu.tsv" | awk '$1 == "plan" { print $2; exit }')" "$((n_moi * 2))"
dung "--version = version engine: đếm đủ" bang "$(sh "$NK" report --version "$V" "$TMP/moi.tsv" | awk '$1 == "plan" { print $2; exit }')" "$n_moi"
dung "--version khác: không còn lần chạy nào" sh -c "sh '$NK' report --version 9.9.9 '$TMP/moi.tsv' | grep -q 'chưa có'"
dung "--version ? lọc dòng cũ (không version)" bang "$(sh "$NK" report --version '?' "$TMP/cu.tsv" | awk '$1 == "plan" { print $2; exit }')" "$n_moi"
dung "--version ? bỏ dòng có version thật" sh -c "sh '$NK' report --version '?' '$TMP/moi.tsv' | grep -q 'chưa có'"
dung "--version không đi kèm giá trị → SAI THAM SỐ" sh -c "! sh '$NK' report --version >/dev/null 2>&1"
dung "--version không có file: lọc nhật ký của máy này" bang "$(sh "$NK" report --version "$V" | awk '$1 == "plan" { print $2; exit }')" "$(sh "$NK" report | awk '$1 == "plan" { print $2; exit }')"
printf '2026-10-24T01:00:00Z\tfeat_x\tspec\t%s\n' "$V" > "$CFG/journal/phases.tsv"
ky_vong 0 "export có nguồn phases" env AW_JOURNAL_MACHINE=may-a sh "$NK" export "$TMP/pha.tsv"
dung "…dòng phases có tên nguồn và máy" sh -c "awk -F'\t' '\$1 == \"phases\" && \$2 == \"may-a\"' '$TMP/pha.tsv' | grep -q ."

# ---------------------------------------------------------------- mốc phase (Task 3)
nhom "SP9b: aw rules ghi mốc phase vào phases.tsv (trong worktree của việc)"
PH="$JD/phases.tsv"
WT="$TMP/wt-feat-z"
g worktree add -q -b feat_z "$WT" main
rm -f "$PH"
env AW_REPO="$WT" sh "$AWE" rules spec > "$TMP/rules-aw.txt"; ma_aw=$?
sh "$T/rules.sh" spec > "$TMP/rules-goc.txt"; ma_goc=$?
dung "aw rules spec trong worktree việc thoát 0" bang "$ma_aw" 0
dung "…stdout giống hệt rules.sh gọi trực tiếp" cmp -s "$TMP/rules-aw.txt" "$TMP/rules-goc.txt"
dung "…mã thoát giống hệt rules.sh gọi trực tiếp" bang "$ma_aw" "$ma_goc"
dung "phases.tsv: đúng một dòng cho spec" sh -c "awk -F'\t' '\$3 == \"spec\"' '$PH' | wc -l | grep -q '^ *1\$'"
dung "…cột việc = tên thư mục việc" sh -c "awk -F'\t' '\$2 == \"feat_z\"' '$PH' | grep -q ."
dung "…cột version = VERSION engine" sh -c "awk -F'\t' -v v='$V' '\$4 == v' '$PH' | grep -q ."
n1=$(wc -l < "$PH" | tr -d ' ')
ky_vong 2 "aw rules phase lạ → SAI THAM SỐ, không ghi" env AW_REPO="$WT" sh "$AWE" rules khong-co
dung "…không thêm dòng" bang "$(wc -l < "$PH" | tr -d ' ')" "$n1"
AW_JOURNAL=0 env AW_REPO="$WT" sh "$AWE" rules implement >/dev/null 2>&1
dung "AW_JOURNAL=0 → không ghi phases.tsv" bang "$(wc -l < "$PH" | tr -d ' ')" "$n1"
ky_vong 0 "aw rules ở checkout chính vẫn thoát 0" sh "$AWE" rules spec
dung "…checkout chính không ghi phases.tsv" bang "$(wc -l < "$PH" | tr -d ' ')" "$n1"
ket_thuc
