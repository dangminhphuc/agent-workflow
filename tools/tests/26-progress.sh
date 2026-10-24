#!/usr/bin/env sh
# Tiến độ phase (SP20): mốc bắt đầu phase (aw feature --phase).
# Chạy riêng: sh tools/tests/26-progress.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

# ---------------------------------------------------------------- aw feature --phase
nhom "aw feature --phase (mốc bắt đầu phase)"
AWHD="$TMP/awhome-dev"; VDEV=$(cat "$ROOT/VERSION")
# awd <thư-mục> <tham-số...> — chạy aw đứng tại <thư-mục>
awd() { _awd=$1; shift; (cd "$_awd" && AW_HOME="$AWHD" AW_ENGINE_DIR="$ROOT" sh "$ROOT/bin/aw" "$@"); }
R26="$TMP/repo26"; mkdir -p "$R26"
git -C "$R26" init -q; git -C "$R26" checkout -q -b main
g26() { git -C "$R26" -c user.name=t -c user.email=t@t "$@" >/dev/null 2>&1; }
g26 commit -q --allow-empty -m goc
awd "$R26" init --version "$VDEV" --test-cmd true >/dev/null 2>&1
PT="$R26/.git/agent-workflow/journal/phases.tsv"
W26="$TMP/repo26.wt/feat_x"
g26 worktree add -q -b feat_x "$W26" main
# so_dong — số dòng phases.tsv (0 nếu chưa có file)
so_dong() { if [ -f "$PT" ]; then wc -l < "$PT" | tr -d ' '; else echo 0; fi; }

ky_vong 0 "feature --phase spec trong worktree → ĐÃ XÁC ĐỊNH" awd "$W26" feature --phase spec
dung "…ghi đúng 1 dòng phases.tsv" test "$(so_dong)" = 1
dung "…cột 3 = tên việc, cột 4 = phase" test "$(awk -F'\t' '{ print $3 "|" $4 }' "$PT")" = "feat_x|spec"
dung "…cột 1 là giờ UTC ISO" sh -c "cut -f1 '$PT' | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\$'"
dung "…stdout vẫn chỉ là thư mục feature" test "$(awd "$W26" feature --phase spec 2>/dev/null)" = "docs/sdlc/feat_x"

mkdir -p "$(dirname "$PT")"; : > "$PT"
ky_vong 2 "--phase khong-co → TÊN KHÔNG HỢP LỆ" awd "$W26" feature --phase khong-co
dung "…không thêm dòng" test "$(so_dong)" = 0
ky_vong 2 "--phase thiếu giá trị → mã 2" awd "$W26" feature --phase
ky_vong 6 "checkout chính --phase spec → ĐANG Ở CHECKOUT CHÍNH" awd "$R26" feature --phase spec
dung "…không thêm dòng" test "$(so_dong)" = 0
ky_vong 0 "không --phase → ĐÃ XÁC ĐỊNH" awd "$W26" feature
dung "…không thêm dòng" test "$(so_dong)" = 0
ky_vong 0 "AW_JOURNAL=0 … --phase spec → ĐÃ XÁC ĐỊNH" env AW_JOURNAL=0 AW_HOME="$AWHD" AW_ENGINE_DIR="$ROOT" sh -c "cd '$W26' && sh '$ROOT/bin/aw' feature --phase spec"
dung "…không thêm dòng" test "$(so_dong)" = 0

W26b="$TMP/repo26.wt/khong-khop"
g26 worktree add -q -b khong-khop "$W26b" main
dung "tham số trước cờ: feature feat_y --phase plan nhận feat_y" test "$(awd "$W26b" feature feat_y --phase plan 2>/dev/null)" = "docs/sdlc/feat_y"
dung "…và ghi phase plan cho feat_y" test "$(awk -F'\t' '{ print $3 "|" $4 }' "$PT")" = "feat_y|plan"
dung "cờ trước tham số: feature --phase plan feat_z nhận feat_z" test "$(awd "$W26b" feature --phase plan feat_z 2>/dev/null)" = "docs/sdlc/feat_z"

ket_thuc
