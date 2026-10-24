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


# ---------------------------------------------------------------- aw journal _turn
nhom "aw journal _turn (lượt và token)"
TT="$R26/.git/agent-workflow/journal/turns.tsv"
TR="$TMP/transcript.jsonl"; cp "$ROOT/tools/tests/fixtures/transcript-claude.jsonl" "$TR"
awd "$W26" feature --phase plan >/dev/null 2>&1
# hook <begin|end|sub> <file-payload> — chạy hook như Claude Code (stdin = payload)
hook() { _h=$1; _p=$2; awd "$W26" journal _turn "$_h" < "$_p"; }
# payload <file> <session> <transcript> [<agent transcript>] [<cwd>]
payload() {
  printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s","hook_event_name":"Stop"%s}\n' \
    "$2" "$3" "${5:-$W26}" "${4:+,\"agent_transcript_path\":\"$4\"}" > "$1"
}
tdong() { if [ -f "$TT" ]; then wc -l < "$TT" | tr -d ' '; else echo 0; fi; }
# cot <dòng> <cột…> — ô của turns.tsv, nối bằng |
cot() { sed -n "${1}p" "$TT" | cut -f"$2" | tr '\t' '|'; }
P1="$TMP/p1.json"; payload "$P1" s1 "$TR"
dung "begin: stdout rỗng" bang "$(hook begin "$P1")" ""
ky_vong 0 "begin: mã 0" hook begin "$P1"
dung "end: stdout rỗng" bang "$(hook end "$P1")" ""
dung "begin+end → 1 dòng" bang "$(tdong)" 1
dung "…feature=feat_x, phase=plan, kind=main" bang "$(cot 1 4,5,7)" "feat_x|plan|main"
dung "…token = tổng fixture (message.id trùng tính một lần)" bang "$(cot 1 9-12)" "4|255|8120|120"
dung "…seconds là số ≥ 0" sh -c "sed -n 1p '$TT' | cut -f8 | grep -Eq '^[0-9]+\$'"
dung "…ts_begin, ts_end là giờ UTC ISO" sh -c "sed -n 1p '$TT' | cut -f1,2 | tr '\t' '\n' | grep -Ec '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\$' | grep -qx 2"

printf '%s\n' '{"type":"assistant","message":{"id":"msg_01CCC","role":"assistant","usage":{"input_tokens":2,"cache_creation_input_tokens":10,"cache_read_input_tokens":300,"output_tokens":7}}}' >> "$TR"
hook begin "$P1" >/dev/null; hook end "$P1" >/dev/null
dung "lượt 2 → dòng thứ hai chỉ có token dòng mới" bang "$(cot 2 9-12)" "2|7|300|10"

printf '%s\n' '{"type":"assistant","message":{"id":"msg_01DDD","role":"assistant","usage":{"input_tokens":1,"output_tokens":1}}}' > "$TR"
hook begin "$P1" >/dev/null; hook end "$P1" >/dev/null
dung "transcript ngắn hơn offset → đọc lại từ đầu" bang "$(cot 3 9-12)" "1|1|0|0"

P2="$TMP/p2.json"; payload "$P2" s2 "$ROOT/tools/tests/fixtures/transcript-claude.jsonl"
hook end "$P2" >/dev/null
dung "end không có begin → seconds rỗng" bang "$(cot 4 8)" ""
dung "…ts_begin rỗng, token vẫn có" bang "$(cot 4 1,9-12)" "|4|255|8120|120"

SUBT="$TMP/sub.jsonl"; printf '%s\n' '{"type":"assistant","message":{"id":"msg_01SUB","role":"assistant","usage":{"input_tokens":5,"cache_creation_input_tokens":6,"cache_read_input_tokens":7,"output_tokens":8}}}' > "$SUBT"
P3="$TMP/p3.json"; payload "$P3" s1 "$TR" "$SUBT"
dung "sub: stdout rỗng" bang "$(hook sub "$P3")" ""
dung "sub → kind=subagent, seconds=0, token của agent" bang "$(cot 5 7-12)" "subagent|0|5|8|7|6"

N=$(tdong)
P4="$TMP/p4.json"; printf '{"session_id":"s9","cwd":"%s","hook_event_name":"Stop"}\n' "$W26" > "$P4"
printf 'không phải json {{{' > "$TMP/p5.json"
payload "$TMP/p6.json" s6 "$TMP/khong-co.jsonl"
for _m in begin end sub; do
  ky_vong 0 "không transcript_path ($_m) → mã 0" hook "$_m" "$P4"
  dung "…stdout rỗng" bang "$(hook "$_m" "$P4")" ""
  ky_vong 0 "JSON hỏng ($_m) → mã 0" hook "$_m" "$TMP/p5.json"
  dung "…stdout rỗng" bang "$(hook "$_m" "$TMP/p5.json")" ""
  ky_vong 0 "transcript không tồn tại ($_m) → mã 0" hook "$_m" "$TMP/p6.json"
  dung "…stdout rỗng" bang "$(hook "$_m" "$TMP/p6.json")" ""
done
dung "…không thêm dòng nào" bang "$(tdong)" "$N"

mkdir -p "$TMP/ngoai"; git -C "$TMP/ngoai" init -q
TR7="$TMP/t7.jsonl"; cp "$ROOT/tools/tests/fixtures/transcript-claude.jsonl" "$TR7"
payload "$TMP/p7.json" s7 "$TR7" "" "$TMP/ngoai"
hook end "$TMP/p7.json" >/dev/null
dung "cwd chưa có phases.tsv → feature và phase = -" bang "$(cot $((N + 1)) 4,5)" "-|-"

N=$(tdong)
payload "$TMP/p8.json" s8 "$TR7"
ky_vong 0 "AW_JOURNAL=0 → mã 0" env AW_JOURNAL=0 AW_HOME="$AWHD" AW_ENGINE_DIR="$ROOT" sh -c "cd '$W26' && sh '$ROOT/bin/aw' journal _turn end < '$TMP/p8.json'"
dung "…không ghi" bang "$(tdong)" "$N"

ket_thuc
