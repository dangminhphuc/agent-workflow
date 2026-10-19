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
