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
dung "--version 9.9.9: không còn dòng checker plan" sh -c "! sh '$NK' report --version 9.9.9 '$TMP/moi.tsv' | grep -q '^  plan '"
dung "--version đúng: còn dòng checker plan" sh -c "sh '$NK' report --version '$V' '$TMP/moi.tsv' | grep -q '^  plan '"
dung "--version ? lọc dòng cũ (không version)" bang "$(sh "$NK" report --version '?' "$TMP/cu.tsv" | awk '$1 == "plan" { print $2; exit }')" "$n_moi"
dung "--version ? bỏ dòng có version thật (moi.tsv)" sh -c "! sh '$NK' report --version '?' '$TMP/moi.tsv' | grep -q '^  plan '"
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

# ---------------------------------------------------------------- aw journal retro (Task 4)
nhom "SP9b: aw journal retro"
RJ="$JD/jobs.tsv"
printf 'x\n' > "$WT/zz.txt"; git -C "$WT" add zz.txt; git -C "$WT" commit -qm "việc z"
thay "$F/plan.md" '`REQ-002`' '`REQ-999`'
sh "$AWE" check plan "$F" >/dev/null 2>&1
thay "$F/plan.md" '`REQ-999`' '`REQ-002`'
rm -f "$RJ"
ky_vong 0 "retro không cờ → XONG" env AW_REPO="$WT" sh "$NK" retro "$F"
dung "…in lần bị chặn đánh số #1" sh -c "env AW_REPO='$WT' sh '$NK' retro '$F' | grep -q '#1'"
dung "…không ghi jobs.tsv" bang "$(test -f "$RJ" && echo co || echo khong)" khong
ky_vong 0 "retro --bo-qua" env AW_REPO="$WT" sh "$NK" retro "$F" --bo-qua
dung "…jobs.tsv đúng một dòng" bang "$(wc -l < "$RJ" | tr -d ' ')" 1
dung "…nhầm, phút, vướng, gây bởi, lọt lớp = -" sh -c "awk -F'\t' '\$11 == \"-\" && \$12 == \"-\" && \$13 == \"-\" && \$14 == \"-\" && \$15 == \"-\"' '$RJ' | grep -q ."
dung "…phần máy: file = 1, dòng = 1 (commit trong worktree)" sh -c "awk -F'\t' '\$6 == 1 && \$7 == 1' '$RJ' | grep -q ."
dung "…cột version là cột cuối" sh -c "awk -F'\t' -v v='$V' '\$NF == v' '$RJ' | grep -q ."
ky_vong 0 "retro --nham 1 --phut 40" env AW_REPO="$WT" sh "$NK" retro "$F" --nham 1 --phut 40
ky_vong 0 "retro --nham 1 --phut 55 (chạy lại)" env AW_REPO="$WT" sh "$NK" retro "$F" --nham 1 --phut 55
dung "…chạy lại thay dòng, không nhân đôi" bang "$(wc -l < "$RJ" | tr -d ' ')" 1
dung "…phút = 55, nhầm = 1" sh -c "awk -F'\t' '\$11 == 1 && \$12 == 55' '$RJ' | grep -q ."
ky_vong 2 "--nham 9 (không có lần chặn số 9) → SAI THAM SỐ" env AW_REPO="$WT" sh "$NK" retro "$F" --nham 9 --phut 1
ky_vong 2 "--phut abc → SAI THAM SỐ" env AW_REPO="$WT" sh "$NK" retro "$F" --phut abc
ky_vong 2 "--lop mood → SAI THAM SỐ" env AW_REPO="$WT" sh "$NK" retro "$F" --gay-boi ABC-1 --lop mood
ky_vong 2 "--gay-boi với việc không phải bugfix → SAI THAM SỐ" env AW_REPO="$WT" sh "$NK" retro "$F" --gay-boi ABC-1 --lop task
ky_vong 2 "--bo-qua cùng --phut → SAI THAM SỐ" env AW_REPO="$WT" sh "$NK" retro "$F" --bo-qua --phut 3
ky_vong 2 "thư mục không có intake.md → SAI THAM SỐ" env AW_REPO="$WT" sh "$NK" retro "$TMP/khong-co"
ky_vong 6 "retro ở checkout chính → thoát 6" env AW_REPO="$R" sh "$NK" retro "$F" --bo-qua
dung "…checkout chính không ghi" bang "$(wc -l < "$RJ" | tr -d ' ')" 1
dung "…lệnh sai không ghi đè dòng đã có" awk -F'\t' '$12 == 55' "$RJ"

# ---------------------------------------------------------------- sửa sau review cuối nhánh (SP9b)
nhom "SP9b: sửa sau review — --nham chuẩn hoá, --nham quá lớn, trung vị lớn"
TAB=$(printf '\t')
tsv() { _o=""; for _a in "$@"; do _o="$_o$_a$TAB"; done; _o=${_o%"$TAB"}; printf '%s\n' "$_o"; }
ky_vong 0 "retro --nham 01 (số có số 0 đầu)" env AW_REPO="$WT" sh "$NK" retro "$F" --nham 01 --phut 1
dung "…lưu thành số 1, không giữ 01" sh -c "awk -F'\t' '\$11 == \"1\"' '$RJ' | grep -q ."
ky_vong 2 "--nham số quá lớn → SAI THAM SỐ" env AW_REPO="$WT" sh "$NK" retro "$F" --nham 99999999999999999999 --phut 1
rm -rf "$JD"; mkdir -p "$JD"
{ tsv 2026-01-01T00:00:00Z feat_big spec 1 "x" "$V"; } > "$JD/checks.tsv"
{ tsv 2026-01-01T00:00:00Z feat_big spec "$V"; } > "$JD/phases.tsv"
{ tsv 2026-01-18T00:00:00Z feat_big feature spec ran 1 1 - 0 1468800 - - - - - "$V"; } > "$JD/jobs.tsv"
dung "trung vị lớn (17 ngày) in đủ chữ số, không ký hiệu khoa học" sh -c "sh '$NK' report | grep -q '^  spec .*trung vị 1468800 giây'"


# ---------------------------------------------------------------- report: mục mới (Task 5)
nhom "SP9b: report — độ chính xác checker, thời gian phase, việc theo loại, lỗi lọt"
TAB=$(printf '\t')
tsv() { _o=""; for _a in "$@"; do _o="$_o$_a$TAB"; done; _o=${_o%"$TAB"}; printf '%s\n' "$_o"; }
rm -rf "$JD"; mkdir -p "$JD"
{ tsv 2026-10-24T10:00:00Z feat_a plan 1 "REQ-9 x" "$V"
  tsv 2026-10-24T10:00:30Z feat_a plan 1 "x" "$V"
  tsv 2026-10-24T10:00:40Z feat_a spec 0 "" "$V"
  tsv 2026-10-24T10:00:50Z feat_b spec 1 "y" "$V"
  tsv 2026-10-24T10:01:00Z feat_b plan 1 "z" "$V"
  tsv 2026-10-24T10:02:00Z feat_c spec 1 "w" "$V"
} > "$JD/checks.tsv"
{ tsv 2026-10-24T10:03:00Z feat_a feature "spec,plan" ran 10 100 "plan:2" 0 180 1 30 - - - "$V"
  tsv 2026-10-24T10:08:20Z feat_b bugfix spec skipped 2 20 "spec:1" 0 500 - 15 - feat_a verify "$V"
} > "$JD/jobs.tsv"
{ tsv 2026-10-24T10:00:00Z feat_a spec "$V"
  tsv 2026-10-24T10:01:00Z feat_a plan "$V"
  tsv 2026-10-24T10:00:00Z feat_b spec "$V"
} > "$JD/phases.tsv"
OUT_RP=$(sh "$NK" report)
dung "checker: plan 3 lần chặn, đúng 66% (1 nhầm)" sh -c "printf '%s\n' \"\$1\" | grep -q '^  plan .*66%'" _ "$OUT_RP"
dung "checker: spec đúng 100%" sh -c "printf '%s\n' \"\$1\" | grep -q '^  spec .*100%'" _ "$OUT_RP"
dung "checker: lần chặn chưa retro được báo là bị loại" sh -c "printf '%s\n' \"\$1\" | grep -q 'chưa có phần người'" _ "$OUT_RP"
dung "phase: spec trung vị 280 giây (60 và 500)" sh -c "printf '%s\n' \"\$1\" | grep -q '^  spec .*trung vị 280 giây'" _ "$OUT_RP"
dung "phase: plan trung vị 120 giây (tới lúc retro)" sh -c "printf '%s\n' \"\$1\" | grep -q '^  plan .*trung vị 120 giây'" _ "$OUT_RP"
dung "việc: feature 1 việc" sh -c "printf '%s\n' \"\$1\" | grep -q '^  feature .*1 việc'" _ "$OUT_RP"
dung "việc: bugfix 1 việc, 1 bỏ design" sh -c "printf '%s\n' \"\$1\" | grep -q '^  bugfix .*1 bỏ design'" _ "$OUT_RP"
dung "việc: file trung vị của feature = 10" sh -c "printf '%s\n' \"\$1\" | grep -q '^  feature .*file trung vị 10'" _ "$OUT_RP"
dung "lỗi lọt: verify 1 việc" sh -c "printf '%s\n' \"\$1\" | grep -q '^  verify .*1 việc'" _ "$OUT_RP"
dung "--version 9.9.9 (nhật ký máy này): không còn dòng checker plan" sh -c "! sh '$NK' report --version 9.9.9 | grep -q '^  plan '"
rm -rf "$JD"
ky_vong 0 "report khi chưa có nhật ký mục mới → vẫn thoát 0" sh "$NK" report
dung "…các mục mới in (chưa có …), tối thiểu 4 chỗ" sh -c "sh '$NK' report | awk '/chưa có/ { n++ } END { exit !(n >= 4) }'"
ket_thuc
