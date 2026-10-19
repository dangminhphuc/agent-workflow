#!/usr/bin/env sh
# aw ship, aw ready.
# Chạy riêng: sh tools/tests/14-ship-ready.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"
SHC="$T/check-ship.sh"

# ---------------------------------------------------------------- aw ship (ship.sh, ship-sweep.sh)
# Việc đã qua review nằm trong worktree; origin là repo bare; gh là bản giả
# (ghi lại tham số, trạng thái PR đọc từ $FG/state).
nhom "aw ship targets|create|status|sweep (ship.sh, ship-sweep.sh)"
tao_fixture 2>/dev/null
viet_mr
printf '/.agent-workflow/\n' >> "$R/.git/info/exclude"
g add -A; g commit -q -m "lam x"
# Dấu vân tay theo NỘI DUNG: commit đúng code đã review không làm kết quả lỗi thời.
ky_vong 0 "fixture: code đã commit, aw check ship đạt" sh "$SHC" "$F"
WS="$TMP/ship-wt"; FS="$WS/.agent-workflow/feat_x"
g checkout -q main
g worktree add -q "$WS" feat_x
mv "$R/.agent-workflow" "$WS/"
export AW_REPO="$WS"
RMS="$TMP/ship-remote.git"; git init -q --bare "$RMS"
g remote add origin "$RMS"; g push -q origin main; g push -q origin main:develop
# uat: gốc khác, không có commit "goc" của main → MR vào uat kéo theo commit ngoài việc
UATC=$(git -C "$R" -c user.name=t -c user.email=t@t commit-tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904 -m uat)
g push -q origin "$UATC:refs/heads/uat"
thay "$CFG/conventions.md" 'mr_target_branches:' 'mr_target_branches: develop uat main'
thay "$CFG/conventions.md" 'mr_platform:' 'mr_platform: github'

FB="$TMP/fakebin"; FG="$TMP/fakegh"; mkdir -p "$FB" "$FG"
cat > "$FB/gh" <<'EOF'
#!/bin/sh
case "$1 $2" in
  "pr create")
    printf 'OPEN\n' > "$FG/state"; git rev-parse HEAD > "$FG/head"; printf '%s\n' "$*" >> "$FG/args"
    while [ $# -gt 0 ]; do [ "$1" = --body-file ] && cp "$2" "$FG/body"; shift; done
    echo "https://github.com/o/r/pull/7" ;;
  "pr list") [ "$(cat "$FG/state" 2>/dev/null)" = OPEN ] && echo "https://github.com/o/r/pull/7"; exit 0 ;;
  "pr view") [ "$(cat "$FG/state")" = ERR ] && exit 1; echo "$(cat "$FG/state") $(cat "$FG/head")" ;;
  "auth status") exit 0 ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$FB/gh"
sg() { PATH="$FB:$PATH" FG="$FG" sh "$T/ship.sh" "$@"; }
sw() { (cd "$R" && AW_REPO="$R" PATH="$FB:$PATH" FG="$FG" sh "$T/ship-sweep.sh" "$@"); }

ky_vong 2 "create thiếu --target → SAI THAM SỐ (người chọn đích)" sg create "$FS"
TG=$(sg targets "$FS" 2>/dev/null)
ky_vong 0 "targets liệt kê nhánh đích" sg targets "$FS"
dung "…theo thứ tự mr_target_branches" bang "$(printf '%s\n' "$TG" | sed 's/^ *\[[0-9]*\] \([^ ]*\).*/\1/' | tr '\n' ' ')" "develop uat main "
dung "…đánh dấu base của việc" sh -c "printf '%s\n' \"\$1\" | grep -q '\[3\] main  ← base của việc'" _ "$TG"
dung "…cảnh báo nhánh sẽ kéo theo commit ngoài việc" sh -c "printf '%s\n' \"\$1\" | grep -q '\[2\] uat  ⚠ kéo theo 1 commit ngoài việc'" _ "$TG"
ky_vong 2 "đích ngoài mr_target_branches → từ chối" sg create "$FS" --target khac
printf 'nhap\n' > "$WS/nhap.txt"
ky_vong 1 "worktree còn file chưa commit → CHƯA ĐỦ ĐIỀU KIỆN" sg create "$FS" --target develop
rm -f "$WS/nhap.txt"
ky_vong 4 "MR vào uat kéo theo commit ngoài việc → người quyết" sg create "$FS" --target uat
dung "…không push, không tạo MR" sh -c "[ ! -f '$FG/args' ] && [ -z \"\$(git -C '$RMS' branch --list feat_x)\" ]"
thay "$CFG/conventions.md" 'mr_platform: github' 'mr_platform: gitlab'
# Không có glab (PATH chỉ có gh giả): server không hỗ trợ push options → push thường + link điền sẵn
sl() { PATH="$FB:/usr/bin:/bin" FG="$FG" sh "$T/ship.sh" "$@"; }
SLO=$(sl create "$FS" --target develop 2>&1)
ky_vong 8 "GitLab, không có glab, server không nhận push options → KHÔNG TẠO ĐƯỢC MR" sl create "$FS" --target develop
dung "…vẫn push được branch (push thường)" test "$(git -C "$RMS" rev-parse feat_x 2>/dev/null)" = "$(git -C "$WS" rev-parse HEAD)"
dung "…chỉ cách ghi lại bằng --url" sh -c "printf '%s\n' \"\$1\" | grep -q 'aw ship create .* --target develop --url'" _ "$SLO"
dung "…mô tả để sẵn ở mr-description.md cho người dán (đã bỏ comment)" sh -c "grep -q '^## Problem' '$FS/mr-description.md' && ! grep -q '<!--' '$FS/mr-description.md'"
# link điền sẵn: gọi thẳng hàm (origin https giả — không cần mạng)
LK="$TMP/link-repo"; git init -q "$LK"; git -C "$LK" remote add origin "git@gitlab.example:g/r.git"
printf '## Problem\n\nmột dòng\n' > "$TMP/mo-ta.md"
LKO=$(sh -c ". '$T/lib/md.sh'; . '$T/lib/mr.sh'; mr_link_tay '$LK' gitlab feat_x develop 'ABC-1: hiện a' '$TMP/mo-ta.md'")
dung "link tạo tay GitLab điền sẵn nguồn, đích, tiêu đề, mô tả (mã hoá URL, UTF-8)" bang "$LKO" \
  "https://gitlab.example/g/r/-/merge_requests/new?merge_request%5Bsource_branch%5D=feat_x&merge_request%5Btarget_branch%5D=develop&merge_request%5Btitle%5D=ABC-1%3A%20hi%E1%BB%87n%20a&merge_request%5Bdescription%5D=%23%23%20Problem%0A%0Am%E1%BB%99t%20d%C3%B2ng%0A"
LKO=$(sh -c ". '$T/lib/md.sh'; . '$T/lib/mr.sh'; mr_link_tay '$LK' github feat_x develop 'T' '$TMP/mo-ta.md'")
dung "link tạo tay GitHub: compare + title + body" bang "$LKO" "https://gitlab.example/g/r/compare/develop...feat_x?expand=1&title=T&body=%23%23%20Problem%0A%0Am%E1%BB%99t%20d%C3%B2ng%0A"

FB2="$TMP/fakebin-chua-dang-nhap"; mkdir -p "$FB2"; printf '#!/bin/sh\nexit 1\n' > "$FB2/gh"; chmod +x "$FB2/gh"
dung "gh đã cài mà chưa đăng nhập → không dùng, nói cách đăng nhập" sh -c \
  "PATH='$FB2:/usr/bin:/bin'; . '$T/lib/md.sh'; . '$T/lib/mr.sh'; ! mr_cli github '$LK' >/dev/null && printf '%s' \"\$MR_CLI_LY_DO\" | grep -q 'gh chưa đăng nhập vào gitlab.example (gh auth login --hostname gitlab.example)'"

# Server GitLab (giả): nhận push options, in link MR như GitLab
git -C "$RMS" config receive.advertisePushOptions true
cat > "$RMS/hooks/post-receive" <<'EOF'
#!/bin/sh
i=0
while [ $i -lt "${GIT_PUSH_OPTION_COUNT:-0}" ]; do
  eval "v=\$GIT_PUSH_OPTION_$i"; printf '%s\n' "$v" >> "FGDIR/push-options"; i=$((i + 1))
done
echo "View merge request for feat_x:"
echo "  https://gitlab.example/g/r/-/merge_requests/12"
EOF
sed -i.bak "s#FGDIR#$FG#" "$RMS/hooks/post-receive" && rm -f "$RMS/hooks/post-receive.bak"
chmod +x "$RMS/hooks/post-receive"
git -C "$WS" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "them commit cho push"
URLG=$(sl create "$FS" --target develop 2>/dev/null)
dung "GitLab, không có glab → tạo MR bằng git push options, stdout là URL" bang "$URLG" "https://gitlab.example/g/r/-/merge_requests/12"
dung "…push options: create, target, title, xoá source branch" sh -c \
  "grep -qx merge_request.create '$FG/push-options' && grep -qx merge_request.target=develop '$FG/push-options' && grep -qx 'merge_request.title=ABC-1: hiện a và b trên màn hình y' '$FG/push-options' && grep -qx merge_request.remove_source_branch '$FG/push-options'"
dung "…ship.md ghi MR (gitlab, open)" grep -q '| develop | open | .* | https://gitlab.example/g/r/-/merge_requests/12 |' "$FS/ship.md"
ky_vong 3 "status không có glab, git chưa thấy merge → giữ open (CÒN MR ĐANG MỞ)" sl status "$FS"
# squash merge trên server: một commit mang đúng toàn bộ thay đổi của branch
SQ="$TMP/squash-clone"; git clone -q -b develop "$RMS" "$SQ" 2>/dev/null
git -C "$SQ" fetch -q origin feat_x && git -C "$SQ" -c user.name=t -c user.email=t@t merge -q --squash origin/feat_x >/dev/null 2>&1 &&
  git -C "$SQ" -c user.name=t -c user.email=t@t commit -q -m "ABC-1 (squash)" && git -C "$SQ" push -q origin develop 2>/dev/null
dung "…squash merge: đầu branch KHÔNG nằm trong develop" sh -c "git -C '$WS' fetch -q origin && ! git -C '$WS' merge-base --is-ancestor HEAD origin/develop"
ky_vong 0 "status không có glab: nhận ra squash merge bằng patch-id → ĐÃ MERGE HẾT" sl status "$FS"
# dọn cho phần GitHub phía sau: develop về main, bỏ server giả, bỏ MR GitLab
rm -f "$RMS/hooks/post-receive" "$FS/ship.md" "$FS/mr-description.md"; git -C "$RMS" config --unset receive.advertisePushOptions
git -C "$RMS" update-ref refs/heads/develop "$(git -C "$R" rev-parse main)"
git -C "$WS" reset -q --hard HEAD~1; git -C "$WS" push -q -f origin feat_x 2>/dev/null
thay "$CFG/conventions.md" 'mr_platform: gitlab' 'mr_platform: github'

URLS=$(sg create "$FS" --target develop 2>/dev/null)
dung "create develop → ĐÃ TẠO MR, stdout là URL" bang "$URLS" "https://github.com/o/r/pull/7"
dung "…gh nhận đúng nguồn/đích và tiêu đề" sh -c "grep -q -- '--head feat_x --base develop --title ABC-1: hiện a và b trên màn hình y' '$FG/args'"
dung "…mô tả gửi đi bỏ dòng tiêu đề và comment của mẫu" sh -c "grep -q '^## Problem' '$FG/body' && ! grep -q '<!--' '$FG/body' && ! grep -q '^# ABC-1' '$FG/body'"
dung "…branch đã lên origin" test "$(git -C "$RMS" rev-parse feat_x 2>/dev/null)" = "$(git -C "$WS" rev-parse HEAD)"
dung "…ship.md ghi MR: đích, open, sha đầu branch, URL" grep -qxF "| develop | open | $(git -C "$WS" rev-parse HEAD) | https://github.com/o/r/pull/7 |" "$FS/ship.md"
ky_vong 5 "create lại cùng đích → ĐÃ CÓ MR ĐANG MỞ, không tạo thêm" sg create "$FS" --target develop
dung "…gh pr create chỉ được gọi một lần" test "$(wc -l < "$FG/args" | tr -d ' ')" = 1

ky_vong 3 "status: PR mở → CÒN MR ĐANG MỞ" sg status "$FS"
printf 'ERR\n' > "$FG/state"
ky_vong 6 "status: không hỏi được nền tảng, git không thấy merge → CHƯA RÕ" sg status "$FS"
printf 'CLOSED\n' > "$FG/state"
ky_vong 4 "status: PR bị đóng → người quyết" sg status "$FS"
printf 'MERGED\n' > "$FG/state"
ky_vong 0 "status: PR đóng rồi mở lại và merge → ĐÃ MERGE HẾT (closed không phải trạng thái cuối)" sg status "$FS"
dung "…ship.md ghi merged" grep -q '| develop | merged |' "$FS/ship.md"

ky_vong 2 "sweep trong worktree → từ chối (chạy từ checkout chính)" sh -c "cd '$WS' && PATH='$FB:$PATH' FG='$FG' sh '$T/ship-sweep.sh'"
git -C "$WS" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "sau khi merge"
ky_vong 7 "sweep: branch local có commit chưa vào MR đã merge → chặn" sw --apply
dung "…worktree còn nguyên" test -d "$WS"
git -C "$WS" reset -q --hard HEAD~1
SWO=$(sw 2>/dev/null)
ky_vong 0 "sweep không --apply → chỉ in" sw
dung "…báo việc dọn được, kể cả xoá origin/feat_x" sh -c "printf '%s\n' \"\$1\" | grep -q 'dọn được: .*xoá origin/feat_x'" _ "$SWO"
dung "…không đụng gì" sh -c "[ -d '$WS' ] && git -C '$R' rev-parse --verify --quiet refs/heads/feat_x"
ky_vong 0 "sweep --apply → dọn" sw --apply
dung "…worktree đã gỡ" test ! -e "$WS"
dung "…branch local đã xoá" sh -c "! git -C '$R' rev-parse --verify --quiet refs/heads/feat_x"
dung "…origin/feat_x đã xoá" sh -c "[ -z \"\$(git -C '$RMS' branch --list feat_x)\" ]"
dung "…artifact, kể cả ship.md, chép vào archive" test -f "$CFG/archive/feat_x/feat_x/ship.md"
ky_vong 0 "sweep lần nữa: không còn gì để dọn" sw
export AW_REPO="$R"

# ---------------------------------------------------------------- artifact trong git (docs/sdlc)
# Thư mục việc kiểu mới: aw check ĐẠT thì commit vào branch (chỉ trong worktree của việc),
# aw ship create gỡ khỏi branch trước MR — không bao giờ vào nhánh đích. Fixture riêng,
# dời sang worktree; xong trả lại R, F, CFG.
nhom "artifact trong git: docs/sdlc/<branch>/ (tools/lib/artifact.sh)"
L_R=${R:-}; L_F=${F:-}; L_CFG=${CFG:-}; L_LOAI=${LOAI:-}
FX_R="$TMP/repo-sdlc"; FX_TM=docs/sdlc
tao_fixture 2>/dev/null
FX_R=""; FX_TM=""
RC=$R; g add src/a.txt; g commit -q -m "lam x"; g checkout -q main
WS2="$TMP/sdlc-wt"; g worktree add -q "$WS2" feat_x
mkdir -p "$WS2/docs"; mv "$RC/docs/sdlc" "$WS2/docs/"
R=$WS2; F="$WS2/docs/sdlc/feat_x"; export AW_REPO="$WS2"
thay "$CFG/config.sh" "$RC/src/a.txt" "$WS2/src/a.txt"   # TEST_CMD của fixture đọc code trong worktree
vt() { sh -c ". '$T/lib/md.sh'; . '$T/lib/cross-check.sh'; kc_van_tay '$F'"; }
dau() { git -C "$R" rev-parse HEAD; }
for c in spec design plan implement review; do
  ky_vong 0 "docs/sdlc chưa track, chưa exclude: check-$c.sh vẫn ĐẠT (thư mục việc không tính vào diff)" sh "$T/check-$c.sh" "$F"
done
VT0=$(vt)
printf 'nhap\n' > "$R/src/nhap.txt"; g add src/nhap.txt
OUTC=$(sh "$AWE" check spec "$F" 2>&1); MAC=$?
dung "aw check spec ĐẠT → giữ mã thoát" bang "$MAC" 0
dung "…commit thư mục việc vào branch" bang "$(git -C "$R" log -1 --format=%s)" "chore(sdlc): feat_x spec"
dung "…commit chỉ có file trong docs/sdlc/feat_x/" sh -c "git -C '$R' show --name-only --format= HEAD | grep -qx docs/sdlc/feat_x/spec.md && ! git -C '$R' show --name-only --format= HEAD | grep -v '^docs/sdlc/feat_x/' | grep -q ."
dung "…code người đã stage không bị cuốn theo, vẫn staged" sh -c "git -C '$R' diff --cached --name-only | grep -qx src/nhap.txt"
dung "…thêm /docs/sdlc/ vào .git/info/exclude" grep -qx '/docs/sdlc/' "$RC/.git/info/exclude"
dung "…báo đã commit" sh -c "printf '%s' \"\$1\" | grep -q 'Artifact: đã commit docs/sdlc/feat_x/'" _ "$OUTC"
g reset -q; rm -f "$R/src/nhap.txt"
H1=$(dau)
ky_vong 0 "check lại khi artifact không đổi → ĐẠT" sh "$AWE" check spec "$F"
dung "…không tạo commit rỗng" bang "$(dau)" "$H1"
dung "commit artifact không đổi dấu vân tay code (Tree)" bang "$(vt)" "$VT0"
dung "…commit cả thư mục việc, không chỉ file của phase" sh -c "git -C '$R' ls-files --error-unmatch docs/sdlc/feat_x/review.md docs/sdlc/feat_x/test-results.md"
printf '\n<!-- ghi chú của người rà soát -->\n' >> "$F/review.md"
ky_vong 0 "…aw check review vẫn ĐẠT (kết quả máy không lỗi thời)" env AW_JOURNAL=0 sh "$AWE" check review "$F"
dung "…AW_JOURNAL=0 cũng commit; mọi artifact đã vào git" sh -c "[ \"\$(git -C '$R' log -1 --format=%s)\" = 'chore(sdlc): feat_x review' ] && [ -z \"\$(git -C '$R' status --porcelain --ignored -- docs/sdlc)\" ]"
cp "$F/spec.md" "$TMP/spec-sdlc.bak"
thay "$F/spec.md" '### REQ-002' '### REQ-001'
H2=$(dau)
ky_vong 1 "aw check spec KHÔNG ĐẠT → giữ mã thoát" sh "$AWE" check spec "$F"
dung "…không commit gì" bang "$(dau)" "$H2"
cp "$TMP/spec-sdlc.bak" "$F/spec.md"
printf 'nhap\n' > "$F/nhap.md"
dung "git add -A của người/agent không kéo file artifact mới vào commit code" sh -c "git -C '$R' add -A && ! git -C '$R' diff --cached --name-only | grep -q '^docs/sdlc/'"
g reset -q; rm -f "$F/nhap.md"
# Ô duyệt: aw approvals tick commit ngay
thay "$F/spec.md" '- [x] **Approved by human** — đã đọc' '- [ ] **Approved by human** — đã đọc'
duyet_lai "$F/spec.md"
g add -f docs/sdlc/feat_x/spec.md; g commit -q -m "bo tick"
H_S=$(sh "$T/approvals.sh" 2>/dev/null | sed -n "s|.*duyệt: aw approvals tick $F spec ||p")
dung "aw approvals liệt kê ô chờ duyệt của việc trong docs/sdlc/" test -n "$H_S"
ky_vong 0 "aw approvals tick → ĐÃ DUYỆT" sh "$T/approvals.sh" tick "$F" spec "$H_S"
dung "…commit ô duyệt vào branch" bang "$(git -C "$R" log -1 --format=%s)" "chore(sdlc): feat_x approve spec"
sh "$T/guard.sh" pre >/dev/null 2>&1
dung "aw guard: mốc pre ở .agent-workflow/ (cục bộ), không lẫn vào thư mục việc" sh -c "[ -f '$R/.agent-workflow/.guard-pre' ] && [ ! -e '$R/docs/sdlc/.guard-pre' ]"
sh "$T/guard.sh" post >/dev/null 2>&1
# Việc kiểu cũ (.agent-workflow/<tên>/) giữ như trước: chỉ ở máy
mkdir -p "$R/.agent-workflow"; cp -R "$F" "$R/.agent-workflow/feat_cu"
H3=$(dau)
ky_vong 0 "việc kiểu cũ: aw check spec ĐẠT" sh "$AWE" check spec "$R/.agent-workflow/feat_cu"
dung "…không commit (artifact kiểu cũ chỉ ở máy)" bang "$(dau)" "$H3"
rm -rf "$R/.agent-workflow/feat_cu"
# Thư mục việc nằm ở checkout chính (nhánh gốc): không commit
mkdir -p "$RC/docs/sdlc"; cp -R "$F" "$RC/docs/sdlc/feat_x"
HM=$(git -C "$RC" rev-parse HEAD)
OUTM=$(sh "$AWE" check spec "$RC/docs/sdlc/feat_x" 2>&1); MAM=$?
dung "thư mục việc ở checkout chính: aw check spec vẫn ĐẠT" bang "$MAM" 0
dung "…không commit vào nhánh gốc, có báo" sh -c "[ \"\$(git -C '$RC' rev-parse HEAD)\" = '$HM' ] && printf '%s' \"\$1\" | grep -q 'checkout chính — không commit'" _ "$OUTM"
rm -rf "$RC/docs/sdlc"

# aw ship create: gỡ thư mục việc khỏi branch trước MR
printf 'ghi chú\n' > "$F/ghi-chu.md"
viet_mr
ky_vong 0 "aw check ship ĐẠT (commit merge-request.md)" sh "$AWE" check ship "$F"
dung "…merge-request.md đã vào branch" sh -c "git -C '$R' ls-files --error-unmatch docs/sdlc/feat_x/merge-request.md"
RM2="$TMP/sdlc-remote.git"; git init -q --bare "$RM2"
git -C "$RC" remote add origin "$RM2"; git -C "$RC" push -q origin main >/dev/null 2>&1; git -C "$RC" push -q origin main:develop >/dev/null 2>&1
thay "$CFG/conventions.md" 'mr_target_branches:' 'mr_target_branches: develop'
thay "$CFG/conventions.md" 'mr_platform:' 'mr_platform: github'
rm -f "$FG"/*
printf 'sửa dở\n' >> "$F/ghi-chu.md"
mkdir -p "$R/docs/sdlc/feat_khac"; printf 'x\n' > "$R/docs/sdlc/feat_khac/intake.md"
g add -f docs/sdlc/feat_khac; g commit -q -m "viec khac"
SO2=$(sg create "$F" --target develop 2>&1); MA2=$?
dung "MR còn mang thư mục việc khác trong docs/sdlc/ → CHƯA ĐỦ ĐIỀU KIỆN" bang "$MA2" 1
dung "…nêu file đó" sh -c "printf '%s' \"\$1\" | grep -q 'docs/sdlc/feat_khac/intake.md'" _ "$SO2"
dung "…không push, không tạo MR" sh -c "[ ! -f '$FG/args' ] && [ -z \"\$(git -C '$RM2' branch --list feat_x)\" ]"
dung "…artifact sửa dở của chính việc không tính là thay đổi chưa commit" sh -c "! printf '%s' \"\$1\" | grep -q 'chưa commit'" _ "$SO2"
dung "…thư mục việc của chính việc đã gỡ khỏi branch (một commit)" sh -c "[ \"\$(git -C '$R' log -1 --format=%s)\" = 'chore(sdlc): remove feat_x artifacts before MR' ] && [ -z \"\$(git -C '$R' ls-files -- docs/sdlc/feat_x)\" ]"
dung "…file vẫn ở máy, kể cả bản sửa dở, có dấu .local-only" sh -c "grep -q 'sửa dở' '$F/ghi-chu.md' && [ -f '$F/merge-request.md' ] && [ -f '$F/.local-only' ]"
g rm -r -q --cached docs/sdlc/feat_khac; g commit -q -m "bo viec khac"; rm -rf "$R/docs/sdlc/feat_khac"
URL2=$(sg create "$F" --target develop 2>/dev/null)
dung "hết artifact trong diff → ĐÃ TẠO MR" bang "$URL2" "https://github.com/o/r/pull/7"
dung "…branch trên origin không có docs/sdlc/" sh -c "[ -n \"\$(git -C '$RM2' rev-parse feat_x 2>/dev/null)\" ] && ! git -C '$RM2' ls-tree -r --name-only feat_x | grep -q '^docs/sdlc/'"
dung "…diff của MR vào develop không có docs/sdlc/" sh -c "! git -C '$RM2' diff --name-only develop...feat_x | grep -q '^docs/sdlc/'"
dung "…ship.md ghi ở máy, worktree vẫn sạch" sh -c "[ -f '$F/ship.md' ] && [ -z \"\$(git -C '$R' status --porcelain)\" ]"
H4=$(dau)
ky_vong 0 "sau khi gỡ: aw check ship ĐẠT" sh "$AWE" check ship "$F"
dung "…không commit lại (artifact quay về MR)" bang "$(dau)" "$H4"
ky_vong 5 "create lại (sửa theo review) → ĐÃ CÓ MR ĐANG MỞ" sg create "$F" --target develop
dung "…vẫn không có docs/sdlc/ trên origin" sh -c "! git -C '$RM2' ls-tree -r --name-only feat_x | grep -q '^docs/sdlc/'"

# aw rename: thư mục việc trong git dời theo, commit
WR="$TMP/sdlc-doi"; git -C "$RC" worktree add -q -b feat_doi "$WR" main
mkdir -p "$WR/docs/sdlc/feat_doi"; printf 'x\n' > "$WR/docs/sdlc/feat_doi/intake.md"
(cd "$WR" && git -c user.name=t -c user.email=t@t add -f docs/sdlc/feat_doi && git -c user.name=t -c user.email=t@t commit -q -m "chore(sdlc): feat_doi intake")
ky_vong 0 "aw rename → ĐÃ ĐỔI TÊN" env AW_REPO="$WR" sh "$T/rename-feature.sh" feat_doi-moi
WR2="$TMP/feat_doi-moi"
dung "…commit việc dời: chỗ mới trong git, chỗ cũ không còn" sh -c "[ \"\$(git -C '$WR2' log -1 --format=%s)\" = 'chore(sdlc): rename feat_doi -> feat_doi-moi' ] && git -C '$WR2' ls-files --error-unmatch docs/sdlc/feat_doi-moi/intake.md && [ -z \"\$(git -C '$WR2' ls-files -- docs/sdlc/feat_doi)\" ] && [ -z \"\$(git -C '$WR2' status --porcelain)\" ]"
git -C "$RC" worktree remove --force "$WR2"; git -C "$RC" worktree remove --force "$WS2"

R=$L_R; F=$L_F; CFG=$L_CFG; LOAI=$L_LOAI
export AW_REPO="$R" AW_CONFIG="$CFG"

# ---------------------------------------------------------------- aw ready (ready.sh)
nhom "ready.sh (aw ready)"
tao_fixture
SS="$T/ready.sh"
CH="$CFG/config.sh"; cp "$CH" "$TMP/ch-ss.bak"
ky_vong 0 "fixture đủ cấu hình, test xanh → SẴN SÀNG" sh "$SS" "$F"
dung "…in bước tiếp" sh -c "sh '$SS' '$F' 2>/dev/null | grep -q '^Bước tiếp: '"
ky_vong 2 "thiếu thư mục feature → SAI THAM SỐ" sh "$SS"
printf 'TEST_CMD="echo LOI-CO-SAN; false"\n%s\n' "$BM_XANH" > "$CH"
ky_vong 1 "test ĐỎ trên code hiện tại → CHƯA SẴN SÀNG" sh "$SS" "$F"
dung "…in output thật của lệnh test" sh -c "sh '$SS' '$F' 2>/dev/null | grep -q 'LOI-CO-SAN'"
ky_vong 0 "--no-test: không chạy test, chỉ kiểm đã khai" sh "$SS" "$F" --no-test
printf 'TEST_CMD="true"\n' > "$CH"
ky_vong 1 "chưa khai SECURITY_CMDS → CHƯA SẴN SÀNG" sh "$SS" "$F"
printf 'TEST_CMD=""\n%s\n' "$BM_XANH" > "$CH"
ky_vong 1 "chưa khai TEST_CMD → CHƯA SẴN SÀNG" sh "$SS" "$F" --no-test
cp "$TMP/ch-ss.bak" "$CH"
thay "$CFG/conventions.md" 'test_files: ' 'mau_file_test_cu: '
ky_vong 1 "conventions.md thiếu test_files → CHƯA SẴN SÀNG" sh "$SS" "$F"
thay "$CFG/conventions.md" 'mau_file_test_cu: ' 'test_files: '

ket_thuc
