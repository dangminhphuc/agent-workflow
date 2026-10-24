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
dung "…token = tổng fixture (message.id lặp: lấy max mỗi ô, tính một lần)" bang "$(cot 1 9-12)" "4|315|8120|120"
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
dung "…ts_begin rỗng, token vẫn có" bang "$(cot 4 1,9-12)" "|4|315|8120|120"

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


# ---------------------------------------------------------------- td_tinh + aw status
nhom "td_tinh, td_su_kien, aw status (tiến độ từng phase)"
# Mỗi ca một AW_CONFIG riêng (journal riêng), thư mục việc riêng; giờ cố định.
# tdl <cfg> <lệnh…> — chạy hàm thư viện như status.sh (md.sh, cross-check.sh, progress.sh)
tdl() { _c=$1; shift; (AW_CONFIG=$_c AW_JOURNAL_MACHINE=may-a HERE="$T"; export AW_CONFIG AW_JOURNAL_MACHINE
  . "$T/lib/md.sh"; . "$T/lib/cross-check.sh"; . "$T/lib/progress.sh"; "$@"); }
# tst <cfg> <tham-số…> — aw-engine status với AW_REPO/AW_CONFIG của ca
tst() { _c=$1; shift; AW_REPO="$TMP" AW_CONFIG=$_c AW_JOURNAL_MACHINE=may-a sh "$AWE" status "$@"; }
# viec_moi <cfg> <tên> <loại> — tạo thư mục việc có intake.md, in đường dẫn
viec_moi() { mkdir -p "$1/journal" "$1/v/$2"
  printf -- '- **Type:** %s\n- **Engine:** %s\n' "$3" "$VDEV" > "$1/v/$2/intake.md"; printf '%s\n' "$1/v/$2"; }
tsv() { printf '%s\n' "$@" | tr '|' '\t'; }

C1="$TMP/td1"; D1=$(viec_moi "$C1" feat_p chore)
tsv '2026-10-23T07:00:00Z|wt|feat_p|intake' '2026-10-23T07:30:00Z|wt|feat_p|spec' \
    '2026-10-23T08:05:00Z|wt2|khac|spec' '2026-10-23T09:40:00Z|wt|feat_p|plan' > "$C1/journal/phases.tsv"
tsv '2026-10-23T07:25:00Z|feat_p|intake|0|' '2026-10-23T08:00:00Z|feat_p|spec|1|thiếu REQ' \
    '2026-10-23T08:10:00Z|khac|spec|1|x' '2026-10-23T08:30:00Z|feat_p|spec|1|y' \
    '2026-10-23T09:35:00Z|feat_p|spec|0|' > "$C1/journal/checks.tsv"
tsv '2026-10-23T07:01:00Z|2026-10-23T07:07:00Z|wt|feat_p|intake|s1|main|360|80000|5000|300000|40000' \
    '2026-10-23T07:31:00Z|2026-10-23T07:49:00Z|wt|feat_p|spec|s1|main|1080|200000|20000|1000000|80000' \
    '2026-10-23T09:00:00Z|2026-10-23T09:00:00Z|wt|feat_p|spec|s1|subagent|0|40000|1000|200000|10000' \
    '2026-10-23T08:11:00Z|2026-10-23T08:12:00Z|wt2|khac|spec|s2|main|60|9|9|9|9' \
    '2026-10-23T09:41:00Z|2026-10-23T09:50:00Z|wt|feat_p|plan|s1|main|540|120000|9000|600000|30000' > "$C1/journal/turns.tsv"
tdl "$C1" td_tinh "$D1" > "$TMP/td1.out" 2>&1
# pdong <file> <phase> — dòng P của phase, tab → |
pdong() { awk -F'\t' -v p="$2" '$1 == "P" && $2 == p' "$1" | tr '\t' '|'; }
dung "intake done: active 360, wall 1800, 1 lượt, 0 chặn, token" bang "$(pdong "$TMP/td1.out" intake)" "P|intake|done|360|1800|1|0|80000|5000|300000|40000"
dung "spec done: wall = plan_start − spec_start, 2 chặn, token cộng subagent" bang "$(pdong "$TMP/td1.out" spec)" "P|spec|done|1080|7800|1|2|240000|21000|1200000|90000"
dung "design skipped (chore), mọi ô rỗng" bang "$(pdong "$TMP/td1.out" design)" "P|design|skipped||||||||"
dung "plan active: wall tới sự kiện cuối" bang "$(pdong "$TMP/td1.out" plan)" "P|plan|active|540|600|1|0|120000|9000|600000|30000"
dung "implement pending" bang "$(pdong "$TMP/td1.out" implement)" "P|implement|pending||||||||"
dung "dòng P theo thứ tự workflow.yaml" bang "$(awk -F'\t' '$1 == "P" { printf "%s ", $2 }' "$TMP/td1.out")" "intake spec design plan implement review ship "
dung "2 dòng B spec (epoch check chặn)" bang "$(awk -F'\t' '$1 == "B"' "$TMP/td1.out" | tr '\t' '|' | tr '\n' ' ')" "B|spec|1792742400 B|spec|1792744200 "
dung "dòng R mỗi lần chạy" bang "$(awk -F'\t' '$1 == "R"' "$TMP/td1.out" | tr '\t' '|' | tr '\n' ' ')" "R|intake|1792738800|1792740600|done R|spec|1792740600|1792748400|done R|plan|1792748400|1792749000|active "
dung "dòng M: phase hiện tại, sự kiện cuối, máy, có mốc, có lượt" bang "$(awk -F'\t' '$1 == "M"' "$TMP/td1.out" | tr '\t' '|')" "M|plan|2026-10-23T09:50:00Z|may-a|1|1"
tst "$C1" "$D1" > "$TMP/st1.out" 2>&1; _ma=$?
dung "aw status → mã 0" bang "$_ma" 0
dung "…in ĐẠT, đang làm, bỏ qua, chưa" sh -c "grep -q 'ĐẠT' '$TMP/st1.out' && grep -q 'đang làm' '$TMP/st1.out' && grep -q 'bỏ qua' '$TMP/st1.out' && grep -q 'chưa' '$TMP/st1.out'"
dung "…Phase hiện tại: plan" grep -q 'Phase hiện tại: plan' "$TMP/st1.out"
dung "…số đã định dạng (2h10m, 1.2M, 80k)" sh -c "grep -q '2h10m' '$TMP/st1.out' && grep -q '1.2M' '$TMP/st1.out' && grep -q '80k' '$TMP/st1.out'"
dung "…nhãn XONG" grep -q '\[x\] XONG' "$TMP/st1.out"
dung "…không nhắc cài hook" sh -c "! grep -q 'Chưa ghi được lượt nào' '$TMP/st1.out'"
ky_vong 2 "aw status cờ lạ → SAI THAM SỐ" tst "$C1" "$D1" --la
ky_vong 2 "aw status thiếu thư mục → SAI THAM SỐ" tst "$C1"
ky_vong 2 "aw status thư mục không có → SAI THAM SỐ" tst "$C1" "$TMP/khong-co"

C2="$TMP/td2"; D2=$(viec_moi "$C2" feat_q feature)
tdl "$C2" td_tinh "$D2" > "$TMP/td2.out" 2>&1
dung "không journal: mọi phase pending, ô rỗng" bang "$(awk -F'\t' '$1 == "P" { print $3 "|" $4 $5 $6 $7 $8 $9 $10 $11 }' "$TMP/td2.out" | sort -u)" "pending|"
dung "…M rỗng, không mốc, không lượt" bang "$(awk -F'\t' '$1 == "M"' "$TMP/td2.out" | tr '\t' '|')" "M||||0|0"
tst "$C2" "$D2" > "$TMP/st2.out" 2>&1; _ma=$?
dung "…aw status mã 0, ô —" sh -c "test $_ma = 0 && grep -q '—' '$TMP/st2.out'"
dung "…không nhắc cài hook" sh -c "! grep -q 'Chưa ghi được lượt nào' '$TMP/st2.out'"

C3="$TMP/td3"; D3=$(viec_moi "$C3" feat_c feature)
tsv '2026-10-01T07:25:00Z|feat_c|intake|0|' '2026-10-01T08:00:00Z|feat_c|spec|1|x' > "$C3/journal/checks.tsv"
tdl "$C3" td_tinh "$D3" > "$TMP/td3.out" 2>&1
dung "việc cũ (chỉ checks.tsv): intake done, wall rỗng" bang "$(pdong "$TMP/td3.out" intake)" "P|intake|done||||||||"
dung "…spec pending (chỉ có check chặn)" bang "$(pdong "$TMP/td3.out" spec | cut -d'|' -f3)" "pending"
tst "$C3" "$D3" > "$TMP/st3.out" 2>&1
dung "…aw status không nhắc cài hook" sh -c "! grep -q 'Chưa ghi được lượt nào' '$TMP/st3.out'"

C4="$TMP/td4"; D4=$(viec_moi "$C4" feat_h feature)
tsv '2026-10-23T07:00:00Z|wt|feat_h|intake' > "$C4/journal/phases.tsv"
tst "$C4" "$D4" > "$TMP/st4.out" 2>&1
dung "có mốc, không lượt main → dòng · Chưa ghi được lượt nào" grep -q '^· Chưa ghi được lượt nào' "$TMP/st4.out"
tsv '2026-10-23T07:01:00Z|2026-10-23T07:02:00Z|wt|feat_h|intake|s1|subagent|0||||' > "$C4/journal/turns.tsv"
tst "$C4" "$D4" > "$TMP/st4.out" 2>&1
dung "…lượt subagent không tính là lượt main → vẫn nhắc" grep -q 'Chưa ghi được lượt nào' "$TMP/st4.out"
tsv '2026-10-23T07:03:00Z|2026-10-23T07:04:00Z|wt|feat_h|intake|s1|main|60||||' >> "$C4/journal/turns.tsv"
tst "$C4" "$D4" > "$TMP/st4.out" 2>&1
dung "có 1 lượt main, token rỗng → không nhắc" sh -c "! grep -q 'Chưa ghi được lượt nào' '$TMP/st4.out'"
dung "…token rỗng → ô rỗng, lượt 1" bang "$(tdl "$C4" td_tinh "$D4" | awk -F'\t' '$1 == "P" && $2 == "intake"' | tr '\t' '|')" "P|intake|active|60|240|1|0||||"

C5="$TMP/td5"; D5=$(viec_moi "$C5" feat_m feature)
tsv '2026-10-23T07:00:00Z|wt|feat_m|intake' > "$C5/journal/phases.tsv"
{ echo '# Progress'; echo '<!-- aw-progress v1'
  tsv 'phases|may-b|2026-10-22T06:00:00Z|intake' \
      'turns|may-b|2026-10-22T06:01:00Z|2026-10-22T06:05:00Z|intake|main|240|10|2|3|4' \
      'checks|may-b|2026-10-22T06:10:00Z|intake|1' \
      'phases|may-a|2026-10-01T00:00:00Z|ship'
  echo '-->'; } > "$D5/progress.md"
tdl "$C5" td_su_kien "$D5" > "$TMP/sk5.out" 2>&1
dung "td_su_kien: sự kiện máy này từ journal" grep -qx "$(tsv 'phases|may-a|2026-10-23T07:00:00Z|intake')" "$TMP/sk5.out"
dung "…dòng máy khác từ khối aw-progress" bang "$(grep -c 'may-b' "$TMP/sk5.out")" 3
dung "…bỏ dòng của máy này trong khối" sh -c "! grep -q 'ship' '$TMP/sk5.out'"
dung "…lượt main chỉ ở máy khác → có lượt" bang "$(tdl "$C5" td_tinh "$D5" | awk -F'\t' '$1 == "M"' | tr '\t' '|')" "M|intake|2026-10-23T07:00:00Z|may-a,may-b|1|1"
tst "$C5" "$D5" > "$TMP/st5.out" 2>&1
dung "…aw status không nhắc cài hook" sh -c "! grep -q 'Chưa ghi được lượt nào' '$TMP/st5.out'"
{ echo '<!-- aw-progress v1'; tsv 'phases|may-b|2026-10-22T06:00:00Z|intake' 'turns|may-b|thiếu-cột'; echo '-->'; } > "$D5/progress.md"
tdcb() { td_su_kien "$1" > "$TMP/sk5b.out"; echo "$TD_CANH_BAO"; }
dung "khối sai dạng → TD_CANH_BAO=1" bang "$(tdl "$C5" tdcb "$D5" 2>/dev/null)" 1
dung "…bỏ cả khối (không dòng may-b)" sh -c "! grep -q 'may-b' '$TMP/sk5b.out'"
dung "…vẫn có sự kiện journal máy này" grep -q 'may-a' "$TMP/sk5b.out"
tst "$C5" "$D5" > "$TMP/st5.out" 2>&1; _ma=$?
dung "…aw status cảnh báo, vẫn XONG" sh -c "test $_ma = 0 && grep -q 'CẢNH BÁO' '$TMP/st5.out'"

dung "td_tg 7800 = 2h10m" bang "$(tdl "$C5" td_tg 7800)" "2h10m"
dung "td_tg 1500 = 25m" bang "$(tdl "$C5" td_tg 1500)" "25m"
dung "td_tg 40 = 40s" bang "$(tdl "$C5" td_tg 40)" "40s"
dung "td_tg 7200 = 2h" bang "$(tdl "$C5" td_tg 7200)" "2h"
dung "td_tg rỗng = —" bang "$(tdl "$C5" td_tg '')" "—"
dung "td_tk 1234567 = 1.2M" bang "$(tdl "$C5" td_tk 1234567)" "1.2M"
dung "td_tk 82400 = 82k" bang "$(tdl "$C5" td_tk 82400)" "82k"
dung "td_tk 999 = 999" bang "$(tdl "$C5" td_tk 999)" "999"
dung "td_tk rỗng = —" bang "$(tdl "$C5" td_tk '')" "—"
dung "may_nay = AW_JOURNAL_MACHINE qua bay" bang "$(tdl "$C5" may_nay)" "may-a"
dung "progress.sh nạp không cần md.sh, không in gì" bang "$(sh -c '. "$1/lib/progress.sh"' x "$T" 2>&1)" ""

mkdir -p "$W26/docs/sdlc/feat_x"
ky_vong 0 "aw status qua wrapper → XONG" awd "$W26" status docs/sdlc/feat_x
dung "…in Phase hiện tại: plan (từ aw feature --phase plan ở trên)" sh -c "cd '$W26' && AW_HOME='$AWHD' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' status docs/sdlc/feat_x 2>&1 | grep -q 'Phase hiện tại: plan'"


# ---------------------------------------------------------------- progress.md
nhom "progress.md (aw status --write, --table) và aw check ĐẠT"
# Cùng dữ liệu C1/D1 ở trên. PM = progress.md của ca.
PM1="$D1/progress.md"
ky_vong 0 "--write → XONG" tst "$C1" "$D1" --write
dung "…dòng tiêu đề # Progress — feat_p" grep -qxF '# Progress — feat_p' "$PM1"
dung "…- Current phase: **plan**" grep -qxF -- '- Current phase: **plan**' "$PM1"
dung "…- Updated = giờ sự kiện cuối" grep -qxF -- '- Updated: 2026-10-23 09:50 UTC' "$PM1"
dung "…- Machines: may-a" grep -qxF -- '- Machines: may-a' "$PM1"
dung "…header bảng tiếng Anh" grep -qxF '| Phase | Status | Active | Wall | Turns | Blocked checks | Tokens in | Tokens out | Cache read | Cache write |' "$PM1"
dung "…| spec | ✓ done | đủ số" grep -qxF '| spec | ✓ done | 18m | 2h10m | 1 | 2 | 240k | 21k | 1.2M | 90k |' "$PM1"
dung "…| design | — skipped | ô trống" grep -qxF '| design | — skipped | | | | | | | | |' "$PM1"
dung "…| plan | ▶ active |" grep -q '^| plan | ▶ active |' "$PM1"
dung "…| implement | · pending |" grep -q '^| implement | · pending |' "$PM1"
dung "…| **Total** | cộng mọi phase" grep -qxF '| **Total** | | 33m | 2h50m | 3 | 2 | 440k | 35k | 2.1M | 160k |' "$PM1"
dung "…2 khối mermaid" bang "$(grep -c '^```mermaid$' "$PM1")" 2
dung "…gantt, dateFormat X" sh -c "grep -qx 'gantt' '$PM1' && grep -qx '  dateFormat X' '$PM1'"
dung "…thanh spec :done (epoch đầu, cuối)" grep -qxF '  spec :done, 1792740600, 1792748400' "$PM1"
dung "…thanh plan :active" grep -qxF '  plan :active, 1792748400, 1792749000' "$PM1"
dung "…đúng 2 milestone crit" bang "$(grep -c ':milestone, crit,' "$PM1")" 2
dung "…milestone nằm trong section spec" bang "$(awk '/^  section /{ s = $2 } /:milestone, crit,/{ print s }' "$PM1" | sort -u)" spec
dung "…không section cho phase không chạy" sh -c "! grep -q 'section design' '$PM1'"
dung "…pie có 3 lát (intake, spec, plan)" bang "$(grep -c '^  "[a-z]*" : ' "$PM1")" 3
dung "…lát intake = (in+out)/1000" grep -qxF '  "intake" : 85.0' "$PM1"
dung "…khối aw-progress v1 có sự kiện máy này" sh -c "awk '/^<!-- aw-progress v1\$/{t=1;next} /^-->\$/{t=0} t' '$PM1' | grep -q \"^phases	may-a	\""
dung "…khối kết thúc bằng -->" bang "$(tail -n 1 "$PM1")" "-->"
dung "…không nhắc cài hook" sh -c "! grep -q 'Chưa ghi được lượt nào' '$PM1'"
cp "$PM1" "$TMP/pm1.lan1"
tst "$C1" "$D1" --write >/dev/null 2>&1
dung "--write lần hai → giống hệt từng byte" cmp -s "$PM1" "$TMP/pm1.lan1"

# Máy khác: thêm một lượt của may-khac vào khối, sinh lại.
C7="$TMP/td7"; mkdir -p "$C7/journal" "$C7/v"; cp -R "$C1/journal" "$C7/"; cp -R "$D1" "$C7/v/"; D7="$C7/v/feat_p"
awk -v d="$(tsv 'turns|may-khac|2026-10-23T09:42:00Z|2026-10-23T09:43:00Z|plan|subagent|0|1000|0|0|0')" \
  '{ print } $0 == "<!-- aw-progress v1" { print d }' "$PM1" > "$D7/progress.md"
tst "$C7" "$D7" --write >/dev/null 2>&1
dung "khối có dòng may-khac → --write giữ dòng đó" grep -q "^turns	may-khac	" "$D7/progress.md"
dung "…Total Tokens in tăng 1000 (441k)" bang "$(grep '^| \*\*Total\*\*' "$D7/progress.md" | cut -d'|' -f8)" " 441k "
dung "…Machines: may-a, may-khac" grep -qxF -- '- Machines: may-a, may-khac' "$D7/progress.md"
: > "$C7/journal/phases.tsv"; : > "$C7/journal/turns.tsv"; : > "$C7/journal/checks.tsv"
tst "$C7" "$D7" --write >/dev/null 2>&1
dung "máy này rỗng journal → dòng may-khac vẫn còn" grep -q "^turns	may-khac	" "$D7/progress.md"
dung "…dòng máy này trong khối bỏ (lấy lại từ journal rỗng)" sh -c "! grep -q '	may-a	' '$D7/progress.md'"
dung "…Total Tokens in = 1k" bang "$(grep '^| \*\*Total\*\*' "$D7/progress.md" | cut -d'|' -f8)" " 1k "

# Khối sai dạng: cảnh báo, sinh lại chỉ từ journal máy này.
C8="$TMP/td8"; mkdir -p "$C8/v"; cp -R "$C1/journal" "$C8/"; cp -R "$D1" "$C8/v/"; D8="$C8/v/feat_p"
awk -v d="$(tsv 'turns|may-khac|thiếu-cột')" -v e="$(tsv 'phases|may-khac|2026-10-22T06:00:00Z|intake')" \
  '{ print } $0 == "<!-- aw-progress v1" { print e; print d }' "$PM1" > "$D8/progress.md"
tst "$C8" "$D8" --write > "$TMP/st8.out" 2>&1; _ma=$?
dung "khối sai dạng → --write cảnh báo, vẫn XONG" sh -c "test $_ma = 0 && grep -q 'CẢNH BÁO' '$TMP/st8.out'"
dung "…file sinh lại chỉ từ journal máy này" cmp -s "$D8/progress.md" "$PM1"

# Không token, không lượt main.
C9="$TMP/td9"; D9=$(viec_moi "$C9" feat_n feature)
tsv '2026-10-23T07:00:00Z|wt|feat_n|intake' '2026-10-23T07:20:00Z|wt|feat_n|spec' > "$C9/journal/phases.tsv"
tst "$C9" "$D9" --write >/dev/null 2>&1
dung "không token → không khối pie" sh -c "! grep -q '^pie' '$D9/progress.md'"
dung "…vẫn có gantt" grep -qx 'gantt' "$D9/progress.md"
dung "không lượt main → > Chưa ghi được lượt nào ngay dưới bảng (trước mermaid)" sh -c "awk '/^\\| \\*\\*Total\\*\\*/{ t = NR } /^> Chưa ghi được lượt nào/{ n = NR } /^\`\`\`mermaid/ && !m { m = NR } END { exit !(t && n > t && n < m) }' '$D9/progress.md'"
dung "…nhắc cột Wall và § Hook" sh -c "grep -q 'chỉ có cột Wall' '$D9/progress.md' && grep -qF '\`adapters/claude-code/README.md\` § Hook đo lượt và token' '$D9/progress.md'"
dung "…giữa bảng và lời nhắc chỉ có dòng trống / chú thích" sh -c "awk '/^\\| \\*\\*Total\\*\\*/{ t = 1; next } t && /^> /{ exit 0 } t && !/^\$/ && !/^<!--.*-->\$/{ exit 1 }' '$D9/progress.md'"

# --table
tst "$C1" "$D1" --table > "$TMP/tb1.out" 2>/dev/null; _ma=$?
dung "--table → mã 0, dòng đầu là header bảng" sh -c "test $_ma = 0 && head -n 1 '$TMP/tb1.out' | grep -q '^| Phase | Status |'"
dung "…dòng cuối là **Total**" sh -c "tail -n 1 '$TMP/tb1.out' | grep -q '^| \*\*Total\*\* |'"
dung "…không mermaid, không <!--" sh -c "! grep -q 'mermaid' '$TMP/tb1.out' && ! grep -q '<!--' '$TMP/tb1.out'"
dung "…đúng bảng trong progress.md" sh -c "grep '^|' '$PM1' | cmp -s - '$TMP/tb1.out'"
dung "--table không dữ liệu → stdout rỗng" bang "$(tst "$C2" "$D2" --table 2>/dev/null)" ""
ky_vong 0 "…vẫn XONG" tst "$C2" "$D2" --table
dung "--table việc cũ (chỉ check) → có bảng (intake ✓ done)" sh -c "AW_REPO='$TMP' AW_CONFIG='$C3' AW_JOURNAL_MACHINE=may-a sh '$AWE' status '$D3' --table 2>/dev/null | grep -q '^| intake | ✓ done |'"
ky_vong 2 "--write --table cùng lúc → SAI THAM SỐ" tst "$C1" "$D1" --write --table
tst "$C2" "$D2" --write >/dev/null 2>&1
dung "--write không dữ liệu → - Updated: —, Current phase: —" sh -c "grep -qxF -- '- Updated: —' '$D2/progress.md' && grep -qxF -- '- Current phase: —' '$D2/progress.md'"
dung "…không mermaid" sh -c "! grep -q mermaid '$D2/progress.md'"

# aw check ĐẠT → progress.md vào commit artifact.
R=$R26; F="$W26/docs/sdlc/feat_x"; LOAI=chore
viet_intake
ky_vong 0 "aw check intake ĐẠT (worktree) → mã 0" awd "$W26" check intake docs/sdlc/feat_x
dung "…progress.md có trong commit artifact" sh -c "git -C '$W26' show --stat --format= HEAD | grep -q 'docs/sdlc/feat_x/progress.md'"
dung "…progress.md có intake ✓ done" grep -q '^| intake | ✓ done |' "$F/progress.md"
H26=$(git -C "$W26" rev-parse HEAD)
awd "$W26" check intake docs/sdlc/feat_x >/dev/null 2>&1
dung "check lại, artifact không đổi → HEAD không đổi (không commit chỉ progress.md)" bang "$(git -C "$W26" rev-parse HEAD)" "$H26"
dung "…progress.md trên đĩa đã cập nhật (khác bản đã commit)" sh -c "! git -C '$W26' show HEAD:docs/sdlc/feat_x/progress.md | cmp -s - '$F/progress.md'"
dung "…không để progress.md staged" bang "$(git -C "$W26" diff --cached --name-only)" ""
printf '\n<!-- ghi chú -->\n' >> "$F/intake.md"
ky_vong 0 "đổi artifact + check → ĐẠT" awd "$W26" check intake docs/sdlc/feat_x
dung "…một commit mới gồm intake.md và progress.md" sh -c "[ \"\$(git -C '$W26' rev-parse HEAD~1)\" = '$H26' ] && git -C '$W26' show --name-only --format= HEAD | grep -qx docs/sdlc/feat_x/intake.md && git -C '$W26' show --name-only --format= HEAD | grep -qx docs/sdlc/feat_x/progress.md"
dung "…progress.md đã commit = bản trên đĩa" sh -c "git -C '$W26' show HEAD:docs/sdlc/feat_x/progress.md | cmp -s - '$F/progress.md'"
# Khối sai dạng: aw check chuyển CẢNH BÁO của status.sh, không chuyển khối Kết quả của nó.
cp "$F/progress.md" "$TMP/pm26.bak"
awk -v d="$(tsv 'turns|may-khac|thiếu-cột')" '{ print } $0 == "<!-- aw-progress v1" { print d }' "$TMP/pm26.bak" > "$F/progress.md"
awd "$W26" check intake docs/sdlc/feat_x > "$TMP/ck2.out" 2>&1; _ma=$?
dung "khối sai dạng + aw check ĐẠT → mã 0, stderr có CẢNH BÁO … sai dạng" sh -c "test $_ma = 0 && grep -q 'CẢNH BÁO: khối aw-progress v1 .* sai dạng' '$TMP/ck2.out'"
dung "…không lẫn khối Kết quả của status.sh" sh -c "! grep -q 'Kết quả: status.sh' '$TMP/ck2.out'"
# Sinh lỗi (TMPDIR không tồn tại → td_tinh không tạo được file tạm): giữ nguyên file cũ.
cp "$F/progress.md" "$TMP/pm26.truoc"
env AW_REPO="$W26" AW_CONFIG="$R26/.git/agent-workflow" TMPDIR="$TMP/khong-co-tmp" sh "$AWE" status "$F" --write > "$TMP/st26.out" 2>&1; _ma=$?
dung "sinh lỗi → status --write mã 1 (KHÔNG GHI ĐƯỢC)" sh -c "test $_ma = 1 && grep -q '\[x\] KHÔNG GHI ĐƯỢC' '$TMP/st26.out'"
dung "…progress.md cũ giữ nguyên từng byte" cmp -s "$F/progress.md" "$TMP/pm26.truoc"
dung "…không để lại file tạm" sh -c "! ls -A '$F' | grep -q '^\.progress'"
rm -f "$F/progress.md"; mkdir "$F/progress.md"
awd "$W26" check intake docs/sdlc/feat_x > "$TMP/ck.out" 2>&1; _ma=$?
dung "status.sh hỏng (progress.md là thư mục) → check vẫn mã 0" bang "$_ma" 0
dung "…stderr có CẢNH BÁO không sinh được progress.md" grep -q 'CẢNH BÁO: không sinh được .*progress.md' "$TMP/ck.out"
ky_vong 1 "…status.sh --write khi progress.md là thư mục → KHÔNG GHI ĐƯỢC" awd "$W26" status docs/sdlc/feat_x --write
rmdir "$F/progress.md"
ky_vong 0 "AW_JOURNAL=0 aw check intake → mã 0" env AW_JOURNAL=0 AW_HOME="$AWHD" AW_ENGINE_DIR="$ROOT" sh -c "cd '$W26' && sh '$ROOT/bin/aw' check intake docs/sdlc/feat_x"
dung "…không sinh progress.md" test ! -e "$F/progress.md"

ket_thuc
