#!/usr/bin/env sh
# package, prepare/check-release, wrapper bin/aw, thuật ngữ.
# Chạy riêng: sh tools/tests/13-release-wrapper.sh (AW_TEST_VERBOSE=1 in từng ca).

. "$(dirname -- "$0")/lib.sh"

# ---------------------------------------------------------------- dong goi (phat hanh)
nhom "tools/package.sh"
# tao_nguon <thư-mục> <YYYY.M.N> — chép repo này (cả thay đổi chưa commit) thành một
# repo git riêng mang version <YYYY.M.N>. Dùng làm "bản phát hành" giả.
tao_nguon() {
  rm -rf "$1"; mkdir -p "$1"
  (cd "$ROOT" && tar cf - --exclude=.git .) | (cd "$1" && tar xf -)
  printf '%s\n' "$2" > "$1/VERSION"
  [ -f "$1/bin/aw" ] && thay "$1/bin/aw" "AW_WRAPPER_VERSION=\"$(cat "$ROOT/VERSION")\"" "AW_WRAPPER_VERSION=\"$2\""
  git -C "$1" init -q; git -C "$1" checkout -q -b main
  git -C "$1" add -A; git -C "$1" -c user.name=t -c user.email=t@t commit -q -m "v$2"
}
NG="$TMP/nguon-goi"; tao_nguon "$NG" 2099.9.1
ky_vong 0 "đóng gói bản đúng" sh "$NG/tools/package.sh" "$TMP/goi1"
dung "ra tarball đúng tên + SHA256SUMS khớp" sh -c "cd '$TMP/goi1' && [ -f agent-workflow-2099.9.1.tar.gz ] && sha256sum -c SHA256SUMS >/dev/null 2>&1"
dung "tarball có thư mục gốc agent-workflow-2099.9.1/ và VERSION" sh -c "gzip -dc '$TMP/goi1/agent-workflow-2099.9.1.tar.gz' | tar tf - | grep -qx 'agent-workflow-2099.9.1/VERSION'"
sh "$NG/tools/package.sh" "$TMP/goi2" >/dev/null 2>&1
dung "đóng gói lại cùng commit → cùng checksum" cmp -s "$TMP/goi1/SHA256SUMS" "$TMP/goi2/SHA256SUMS"
printf 'chua commit\n' > "$NG/chua-commit.txt"
sh "$NG/tools/package.sh" "$TMP/goi3" >/dev/null 2>&1
dung "file chưa commit không lọt vào gói" sh -c "! gzip -dc '$TMP/goi3/agent-workflow-2099.9.1.tar.gz' | tar tf - | grep -q chua-commit"
printf 'v2\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam sai
ky_vong 4 "VERSION sai dạng YYYY.M.N → VERSION LỖI" sh "$NG/tools/package.sh" "$TMP/goi4"
printf '2.0.0\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam semver
ky_vong 4 "VERSION kiểu X.Y.Z (semver) → VERSION LỖI" sh "$NG/tools/package.sh" "$TMP/goi4b"
printf '2026.13.1\n' > "$NG/VERSION"; git -C "$NG" -c user.name=t -c user.email=t@t commit -qam thang13
ky_vong 4 "VERSION tháng 13 → VERSION LỖI" sh "$NG/tools/package.sh" "$TMP/goi4c"
dung "luật version YYYY.M.N: nhận 2026.10.6, 2026.1.6, 2026.12.31, 2026.10.32, 2026.10.100; từ chối 2026.10.06, 2026.01.6, 2026.0.10, 2026.10.0, 2026.10.6.1, 2026.10.1a, v2026.10.6" sh -c ". '$T/lib/version.sh'; ver_hop_le 2026.10.6 && ver_hop_le 2026.1.6 && ver_hop_le 2026.12.31 && ver_hop_le 2026.10.32 && ver_hop_le 2026.10.100 && ! ver_hop_le 2026.10.06 && ! ver_hop_le 2026.01.6 && ! ver_hop_le 2026.0.10 && ! ver_hop_le 2026.10.0 && ! ver_hop_le 2026.10.6.1 && ! ver_hop_le 2026.10.1a && ! ver_hop_le v2026.10.6"
dung "wrapper bin/aw dùng cùng luật version với engine" sh -c "eval \"\$(sed -n '/^version_hop_le() {/,/^}/p' '$ROOT/bin/aw')\"; for v in 2026.10.32 2026.10.100 2026.1.1; do version_hop_le \$v || exit 1; done; for v in 2026.10.0 2026.10.08 2026.10.6.1; do version_hop_le \$v && exit 1; done; exit 0"
ky_vong 2 "ref không tồn tại → sai tham số" sh "$NG/tools/package.sh" "$TMP/goi5" khong-co
dung "VERSION của repo đúng dạng YYYY.M.N" sh -c ". '$T/lib/version.sh'; ver_hop_le \"\$(cat '$ROOT/VERSION')\""
dung "workflow release gắn file vào release đã có (tạo tag trên giao diện GitHub)" sh -c "grep -q 'gh release upload \"\$TAG\" dist/\* --clobber' '$ROOT/.github/workflows/release.yml' && grep -q 'gh release create \"\$TAG\"' '$ROOT/.github/workflows/release.yml'"
dung "workflow release chạy khi merge vào main, bỏ qua khi tag đã có" sh -c "grep -q 'branches: \[main\]' '$ROOT/.github/workflows/release.yml' && grep -q 'ls-remote --exit-code --tags origin' '$ROOT/.github/workflows/release.yml'"
dung "workflow kiem-tra của PR chạy kiểm version + test" sh -c "grep -q 'check-release.sh \"origin/\$BASE\"' '$ROOT/.github/workflows/kiem-tra.yml' && grep -q 'run-tests.sh' '$ROOT/.github/workflows/kiem-tra.yml'"
dung "workflow release bắt tag dạng YYYY.M.N, không có v" grep -qF "tags: ['[0-9][0-9][0-9][0-9].[0-9]+.[0-9]+']" "$ROOT/.github/workflows/release.yml"
dung "CHANGELOG.md có mục cho VERSION" grep -qF "## [$(cat "$ROOT/VERSION")]" "$ROOT/CHANGELOG.md"

# ---------------------------------------------------------------- chuẩn bị + kiểm phát hành
nhom "tools/prepare-release.sh + tools/check-release.sh"
git_t() { _gt_d=$1; shift; git -C "$_gt_d" -c user.name=t -c user.email=t@t "$@"; }
PH="$TMP/ph"; PHO="$TMP/ph-origin.git"
tao_nguon "$PH" 2099.9.1
rm -rf "$PHO"; git init -q --bare "$PHO"; git -C "$PH" remote add origin "$PHO"
git -C "$PH" push -q origin main 2>/dev/null
git -C "$PH" tag 2099.9.1; git -C "$PH" push -q origin 2099.9.1 2>/dev/null
for m in "$PH"/changes/*.md; do [ "${m##*/}" = README.md ] || rm -f "$m"; done   # mảnh của chính repo
ph_cl() { printf '# Changelog\n\n## [Chưa phát hành]\n\n- thay đổi mới\n\n## [2099.9.1]\n\n- cũ\n' > "$PH/CHANGELOG.md"; }
ph_cl; git_t "$PH" commit -qam cl
ky_vong 0 "kiểm phát hành: VERSION không đổi so với base → đạt" sh "$PH/tools/check-release.sh" main
ky_vong 4 "chuẩn bị: version truyền tay trùng tag đã có → VERSION LỖI" sh "$PH/tools/prepare-release.sh" 2099.9.1
ky_vong 4 "chuẩn bị: version sai dạng (số 0 đứng đầu) → VERSION LỖI" sh "$PH/tools/prepare-release.sh" 2099.09.2
ky_vong 0 "chuẩn bị: version truyền tay" sh "$PH/tools/prepare-release.sh" 2099.9.2
dung "…ghi VERSION, bin/aw, CHANGELOG cùng một version" sh -c "grep -qx 2099.9.2 '$PH/VERSION' && grep -q '^AW_WRAPPER_VERSION=\"2099.9.2\"' '$PH/bin/aw' && grep -qx '## \[2099.9.2\]' '$PH/CHANGELOG.md' && ! grep -q 'Chưa phát hành' '$PH/CHANGELOG.md'"
dung "…link tải wrapper trong README và huong-dan trỏ version mới" sh -c "grep -q releases/download/2099.9.2/aw '$PH/README.md' && grep -q releases/download/2099.9.2/aw '$PH/docs/huong-dan.md'"
git -C "$PH" checkout -q -b pr; git_t "$PH" commit -qam "phát hành 2099.9.2"
ky_vong 0 "kiểm phát hành: PR đổi VERSION, tag chưa có → đạt" sh "$PH/tools/check-release.sh" main
git -C "$PH" tag 2099.9.2 main; git -C "$PH" push -q origin 2099.9.2 2>/dev/null
ky_vong 1 "kiểm phát hành: PR khác đã lấy số này (tag có rồi) → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh" main
thay "$PH/bin/aw" 'AW_WRAPPER_VERSION="2099.9.2"' 'AW_WRAPPER_VERSION="2099.9.1"'
ky_vong 1 "kiểm phát hành: bin/aw lệch VERSION → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh"
git -C "$PH" checkout -q -- bin/aw
thay "$PH/CHANGELOG.md" '## [2099.9.2]' '## [Chưa phát hành]'
ky_vong 1 "kiểm phát hành: CHANGELOG thiếu mục cho VERSION → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh"
git -C "$PH" checkout -q -- .; git -C "$PH" checkout -q main; git -C "$PH" branch -qD pr
ph_cl; git_t "$PH" commit -qam cl2 >/dev/null
THANG_NAY="$(date +%Y).$(date +%m | sed 's/^0//')"
git -C "$PH" tag "$THANG_NAY.1"; git -C "$PH" tag "$THANG_NAY.3"; git -C "$PH" push -q origin --tags 2>/dev/null
ky_vong 0 "chuẩn bị: tự tính version" sh "$PH/tools/prepare-release.sh"
dung "…= tháng này, số lớn nhất ở remote + 1" grep -qx "$THANG_NAY.4" "$PH/VERSION"
git -C "$PH" checkout -q -- .
git -C "$PH" tag "$THANG_NAY.9"
ky_vong 0 "chuẩn bị: tag chỉ có ở máy, chưa lên remote → không tính" sh "$PH/tools/prepare-release.sh"
dung "…vẫn là số kế tiếp ở remote" grep -qx "$THANG_NAY.4" "$PH/VERSION"
git -C "$PH" checkout -q -- .
printf '# Changelog\n\n## [2099.9.1]\n\n- cũ\n' > "$PH/CHANGELOG.md"
ky_vong 3 "chuẩn bị: CHANGELOG không có [Chưa phát hành] → KHÔNG CÓ GÌ ĐỂ PHÁT HÀNH" sh "$PH/tools/prepare-release.sh"
dung "…không đổi file nào" sh -c "grep -qx 2099.9.1 '$PH/VERSION'"

# Mảnh changelog changes/*.md: gom vào [<version>] theo mục, xoá mảnh; sai dạng thì chặn.
manh() { printf "$2" > "$PH/changes/$1.md"; }
muc_v() { awk -v v="$1" 'index($0, "## [" v "]") == 1 { on = 1 } on && /^## \[/ && index($0, "## [" v "]") != 1 { exit } on' "$PH/CHANGELOG.md"; }
manh a '### Sửa\n- sửa A\n'
manh b '### Nội bộ\n- nội bộ B\n\n### Thêm\n- thêm B\n'
ky_vong 0 "kiểm phát hành: mảnh đúng dạng → đạt" sh "$PH/tools/check-release.sh"
ky_vong 0 "chuẩn bị: chỉ có mảnh, CHANGELOG không có [Chưa phát hành] → gom mảnh" sh "$PH/tools/prepare-release.sh" 2099.9.5
printf '## [2099.9.5]\n\n### Thêm\n- thêm B\n\n### Sửa\n- sửa A\n\n### Nội bộ\n- nội bộ B\n\n' > "$TMP/cl-mong"
muc_v 2099.9.5 > "$TMP/cl-co"
dung "…mục mới đứng trước bản cũ, gộp theo mục: Thêm, Sửa, Nội bộ" sh -c "cmp -s '$TMP/cl-co' '$TMP/cl-mong' && grep -q '^## \[2099.9.1\]' '$PH/CHANGELOG.md'"
dung "…xoá các mảnh, giữ changes/README.md" sh -c "[ ! -e '$PH/changes/a.md' ] && [ ! -e '$PH/changes/b.md' ] && [ -f '$PH/changes/README.md' ]"
git -C "$PH" checkout -q -- .
manh c '### Thêm\n- thêm C\n'
ky_vong 0 "chuẩn bị: [Chưa phát hành] còn nội dung (PR cũ) + mảnh → gom cả hai" sh "$PH/tools/prepare-release.sh" 2099.9.5
muc_v 2099.9.5 | tr '\n' '|' > "$TMP/cl-co"
dung "…nội dung cũ trước, rồi mục của mảnh; không còn [Chưa phát hành]" sh -c "grep -qxF '## [2099.9.5]||- thay đổi mới||### Thêm|- thêm C||' '$TMP/cl-co' && ! grep -q 'Chưa phát hành' '$PH/CHANGELOG.md'"
git -C "$PH" checkout -q -- .
manh x 'chữ ngoài mục\n### Thêm\n- x\n'
ky_vong 5 "chuẩn bị: mảnh có chữ trước mục đầu tiên → MẢNH CHANGELOG LỖI" sh "$PH/tools/prepare-release.sh" 2099.9.5
dung "…không đổi file nào, mảnh còn nguyên" sh -c "grep -qx 2099.9.1 '$PH/VERSION' && [ -f '$PH/changes/x.md' ] && grep -q 'Chưa phát hành' '$PH/CHANGELOG.md'"
ky_vong 1 "kiểm phát hành (PR): mảnh sai dạng → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh" main
dung "…đúng lý do" sh -c "sh '$PH/tools/check-release.sh' | grep -qF 'changes/x.md: dòng 1: nội dung nằm ngoài mục'"
manh x '### Thêm\n- x\n## [2099.9.9]\n'
ky_vong 1 "kiểm phát hành: mảnh có heading ## → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh"
manh x '### Thêm\n\n### Sửa\n- x\n'
ky_vong 1 "kiểm phát hành: mảnh có mục trống → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh"
: > "$PH/changes/x.md"
ky_vong 1 "kiểm phát hành: mảnh trống → KHÔNG ĐẠT" sh "$PH/tools/check-release.sh"
rm -f "$PH/changes/x.md"

# ---------------------------------------------------------------- wrapper aw
nhom "bin/aw (wrapper)"
unset AW_REPO AW_CONFIG
AWH="$TMP/awhome"; MIR="$TMP/mirror"
# Mirror giả (file://): mỗi version là một bản phát hành đóng gói từ repo này.
for v in 2099.1.1 2099.1.2; do
  tao_nguon "$TMP/nguon-$v" "$v"
  sh "$TMP/nguon-$v/tools/package.sh" "$MIR/$v" >/dev/null 2>&1
done
tao_nguon "$TMP/nguon-2099.1.4" 2099.1.4
sh "$TMP/nguon-2099.1.4/tools/package.sh" "$MIR/2099.1.4" >/dev/null 2>&1
printf '%s  agent-workflow-2099.1.4.tar.gz\n' "$(printf 0 | awk '{ for (i = 0; i < 64; i++) printf "0" }')" > "$MIR/2099.1.4/SHA256SUMS"

R7="$TMP/repo7"; mkdir -p "$R7"
git -C "$R7" init -q; git -C "$R7" checkout -q -b main
git -C "$R7" -c user.name=t -c user.email=t@t commit -q --allow-empty -m goc
GOC7=$(git -C "$R7" rev-parse HEAD)
# aw7 <args> — chạy aw trong repo7 với HOME/mirror riêng của test
aw7() { (cd "$R7" && AW_HOME="$AWH" AW_MIRROR="file://$MIR" sh "$ROOT/bin/aw" "$@"); }
C7="$R7/.git/agent-workflow"

ky_vong 9 "ngoài git repo → KHÔNG HỢP LỆ" sh -c "cd '$TMP' && AW_HOME='$AWH' sh '$ROOT/bin/aw' check spec x"
ky_vong 9 "chưa init → KHÔNG HỢP LỆ" aw7 check spec .agent-workflow/x
ky_vong 2 "init --version sai dạng → SAI THAM SỐ" aw7 init --version 2099.01.01
ky_vong 0 "aw init --version 2099.1.1 (cache thiếu → tải từ mirror)" aw7 init --version 2099.1.1 --test-cmd true
dung "…ghi version, checksums, config.sh vào .git/agent-workflow/; quy ước tạo trong repo" sh -c \
  "grep -qx 2099.1.1 '$C7/version' && grep -q ' agent-workflow-2099.1.1.tar.gz' '$C7/checksums' && [ -f '$R7/docs/agent-workflow/conventions.md' ] && [ ! -f '$C7/conventions.md' ] && grep -q 'TEST_CMD=\"true\"' '$C7/config.sh'"
dung "…engine vào cache theo version, có dấu sha256" sh -c "[ -f '$AWH/engine/2099.1.1/bin/aw-engine' ] && [ -s '$AWH/engine/2099.1.1/.aw-sha256' ]"
dung "…sha ghim khớp SHA256SUMS của bản phát hành" sh -c "grep -qF \"\$(awk '\$2 == \"agent-workflow-2099.1.1.tar.gz\" { print \$1 }' '$MIR/2099.1.1/SHA256SUMS')\" '$C7/checksums'"
dung "…exclude /.agent-workflow/ và /.claude/" sh -c "grep -qx '/.agent-workflow/' '$R7/.git/info/exclude' && grep -qx '/.claude/' '$R7/.git/info/exclude'"
dung "…sinh adapter ở checkout chính" test -f "$R7/.claude/commands/aw-intake.md"
dung "…không có commit nào vào base" bang "$(git -C "$R7" rev-parse HEAD)" "$GOC7"
dung "…file sinh ra không lọt vào git status — chỉ còn quy ước chờ commit" sh -c "[ \"\$(git -C '$R7' status --porcelain --untracked-files=all)\" = '?? docs/agent-workflow/conventions.md' ]"
ky_vong 0 "aw guard pre → chuyển sang engine của bản clone (chưa có việc nào: không làm gì)" aw7 guard pre
ky_vong 0 "aw guard post → như trên" aw7 guard post
ky_vong 2 "aw approval → chuyển sang engine (thư mục không có → SAI THAM SỐ)" aw7 approval design "$TMP/khong-co"
aw7 init >/dev/null 2>&1
dung "init lại: không nhân đôi dòng exclude" bang "$(grep -cx '/.claude/' "$R7/.git/info/exclude")" 1
ky_vong 2 "init lại với version khác → SAI THAM SỐ (dùng aw upgrade)" aw7 init --version 2099.1.2
dung "aw version in engine đang dùng" sh -c "cd '$R7' && AW_HOME='$AWH' sh '$ROOT/bin/aw' version 2>/dev/null | grep -q 'engine       2099.1.1'"
ky_vong 0 "aw doctor: mọi mục ✓" aw7 doctor

ky_vong 6 "cache có version → chạy không cần mạng (aw feature)" sh -c "cd '$R7' && AW_HOME='$AWH' AW_MIRROR='file://$TMP/khong-co' sh '$ROOT/bin/aw' feature"
ky_vong 9 "version không có trong cache và không tải được → KHÔNG HỢP LỆ" aw7 upgrade 2099.1.3
dung "…version giữ nguyên" grep -qx 2099.1.1 "$C7/version"
ky_vong 9 "checksum sai → KHÔNG HỢP LỆ" aw7 upgrade 2099.1.4
dung "…không cài vào cache, version giữ nguyên" sh -c "[ ! -e '$AWH/engine/2099.1.4' ] && grep -qx 2099.1.1 '$C7/version'"

cp "$C7/checksums" "$TMP/checksums.bak"
sed 's/^[0-9a-f]*  agent-workflow-2099.1.1/1111  agent-workflow-2099.1.1/' "$TMP/checksums.bak" > "$C7/checksums"
ky_vong 9 "cache lệch sha đã ghim → KHÔNG HỢP LỆ" aw7 feature
mv "$AWH/engine/2099.1.1" "$TMP/engine-2099.1.1.bak"
ky_vong 9 "tải lại mà khác sha đã ghim → KHÔNG HỢP LỆ (không tin SHA256SUMS)" aw7 feature
cp "$TMP/checksums.bak" "$C7/checksums"; mv "$TMP/engine-2099.1.1.bak" "$AWH/engine/2099.1.1"

ky_vong 9 "AW_ENGINE_DIR khác version → KHÔNG HỢP LỆ" sh -c "cd '$R7' && AW_HOME='$TMP/awhome-trong' AW_ENGINE_DIR='$ROOT' sh '$ROOT/bin/aw' feature"
ky_vong 6 "AW_ENGINE_DIR đúng version → chạy, không cần cache/mạng" sh -c "cd '$R7' && AW_HOME='$TMP/awhome-trong' AW_MIRROR='file://$TMP/khong-co' AW_ENGINE_DIR='$TMP/nguon-2099.1.1' sh '$ROOT/bin/aw' feature"
dung "…không tạo cache" test ! -e "$TMP/awhome-trong/engine/2099.1.1"

ky_vong 0 "aw upgrade 2099.1.2" aw7 upgrade 2099.1.2
dung "…version mới, ghim thêm sha của 2099.1.2, giữ sha cũ" sh -c "grep -qx 2099.1.2 '$C7/version' && grep -q 'agent-workflow-2099.1.2' '$C7/checksums' && grep -q 'agent-workflow-2099.1.1' '$C7/checksums'"
dung "…vẫn không có commit nào; upgrade không đụng quy ước" sh -c "[ \"\$(git -C '$R7' rev-parse HEAD)\" = '$GOC7' ] && [ \"\$(git -C '$R7' status --porcelain --untracked-files=all)\" = '?? docs/agent-workflow/conventions.md' ]"

# aw self-update: wrapper tự thay bằng bản `aw` của bản phát hành
WB="$TMP/wbin"; mkdir -p "$WB"; cp "$TMP/nguon-2099.1.1/bin/aw" "$WB/aw"
awb() { (cd "$R7" && AW_HOME="$AWH" AW_MIRROR="file://$MIR" sh "$WB/aw" "$@"); }
dung "wrapper cũ hơn engine → aw version nhắc self-update" sh -c "cd '$R7' && AW_HOME='$AWH' sh '$WB/aw' version 2>&1 | grep -q 'wrapper 2099.1.1 cũ hơn engine 2099.1.2.*aw self-update'"
ky_vong 2 "self-update version sai dạng → SAI THAM SỐ" awb self-update 2099.01.2
ky_vong 2 "self-update ngoài repo, không ghi version → SAI THAM SỐ" sh -c "cd '$TMP' && AW_HOME='$AWH' sh '$WB/aw' self-update"
ky_vong 9 "SHA256SUMS không có dòng aw → KHÔNG HỢP LỆ" awb self-update 2099.1.4
cp -R "$MIR/2099.1.2" "$MIR/2099.1.6"; printf '# tráo\n' >> "$MIR/2099.1.6/aw"
ky_vong 9 "aw tải về sai checksum → KHÔNG HỢP LỆ" awb self-update 2099.1.6
dung "…wrapper giữ nguyên, không để lại file tạm" sh -c "grep -q '^AW_WRAPPER_VERSION=\"2099.1.1\"' '$WB/aw' && [ \"\$(ls -A '$WB')\" = aw ]"
ky_vong 0 "aw self-update (không tham số) → lên version engine của repo" awb self-update
dung "…file wrapper giống hệt aw của bản phát hành, vẫn chạy được" sh -c "cmp -s '$WB/aw' '$MIR/2099.1.2/aw' && [ -x '$WB/aw' ] && sh '$WB/aw' version 2>/dev/null | grep -q 'aw (wrapper) 2099.1.2'"
ky_vong 0 "self-update lại cùng version → không làm gì" awb self-update

# cấu hình dùng chung của team: một repo riêng chứa version, checksums, conventions.md
TEAM="$TMP/team-cfg"; mkdir -p "$TEAM"; git -C "$TEAM" init -q
cp "$C7/version" "$C7/checksums" "$TEAM/"; printf '# của team\n' > "$TEAM/conventions.md"
git -C "$TEAM" add -A; git -C "$TEAM" -c user.name=t -c user.email=t@t commit -q -m cfg
R8="$TMP/repo8"; git clone -q "$R7" "$R8" 2>/dev/null
ky_vong 0 "aw init --from <repo cấu hình team>" sh -c "cd '$R8' && AW_HOME='$AWH' AW_MIRROR='file://$MIR' sh '$ROOT/bin/aw' init --from '$TEAM'"
dung "…lấy version, checksums, conventions.md của team" sh -c "grep -qx 2099.1.2 '$R8/.git/agent-workflow/version' && grep -q 'của team' '$R8/.git/agent-workflow/conventions.md' && cmp -s '$TEAM/checksums' '$R8/.git/agent-workflow/checksums'"
ky_vong 9 "--from repo không có file version → KHÔNG HỢP LỆ" sh -c "cd '$R8' && AW_HOME='$AWH' sh '$ROOT/bin/aw' init --from '$R7'"
R8B="$TMP/repo8b"; git clone -q "$R7" "$R8B" 2>/dev/null
mkdir -p "$R8B/docs/agent-workflow"; printf '# của repo\n' > "$R8B/docs/agent-workflow/conventions.md"
ky_vong 0 "aw init --from khi repo đã có quy ước trong git" sh -c "cd '$R8B' && AW_HOME='$AWH' AW_MIRROR='file://$MIR' sh '$ROOT/bin/aw' init --from '$TEAM'"
dung "…bỏ qua conventions.md của repo cấu hình (không thành nguồn thứ hai), vẫn lấy version" sh -c "[ ! -f '$R8B/.git/agent-workflow/conventions.md' ] && grep -qx 2099.1.2 '$R8B/.git/agent-workflow/version' && grep -q 'của repo' '$R8B/docs/agent-workflow/conventions.md'"
# aw check chạy đúng version ghi trong intake.md của việc, không theo version của bản clone
mkdir -p "$R7/.agent-workflow/feat_a"
printf -- '- **Type:** `feature`\n- **Engine:** 2099.1.1\n' > "$R7/.agent-workflow/feat_a/intake.md"
ky_vong 1 "intake ghim 2099.1.1, bản clone 2099.1.2 → chấm bằng 2099.1.1 (KHÔNG ĐẠT, không phải KHÔNG HỢP LỆ)" aw7 check intake .agent-workflow/feat_a
printf -- '- **Type:** `feature`\n- **Engine:** 2099.1.3\n' > "$R7/.agent-workflow/feat_a/intake.md"
ky_vong 9 "intake ghim version không có và không tải được → KHÔNG HỢP LỆ" aw7 check intake .agent-workflow/feat_a
dung "…không âm thầm chạy bằng version khác" sh -c "cd '$R7' && AW_HOME='$AWH' AW_MIRROR='file://$MIR' sh '$ROOT/bin/aw' check intake .agent-workflow/feat_a 2>&1 | grep -q 'engine 2099.1.3 không có trong cache'"
printf -- '- **Engine:** v9\n' > "$R7/.agent-workflow/feat_a/intake.md"
ky_vong 9 "intake ghi Engine sai dạng → KHÔNG HỢP LỆ" aw7 check intake .agent-workflow/feat_a
ky_vong 9 "aw pending cũng theo version của việc" aw7 pending .agent-workflow/feat_a
ky_vong 9 "…aw questions (tên cũ) vẫn qua wrapper, theo version của việc" aw7 questions .agent-workflow/feat_a
rm -rf "$R7/.agent-workflow"
dung "wrapper và VERSION cùng version (đóng gói kiểm lại)" bang "$(awk -F'"' '/^AW_WRAPPER_VERSION=/ { print $2 }' "$ROOT/bin/aw")" "$(cat "$ROOT/VERSION")"

# ---------------------------------------------------------------- wrapper → lệnh mới
nhom "wrapper: ready, task, journal"
ky_vong 0 "aw journal → engine" aw7 journal
ky_vong 2 "aw task sai tham số → engine trả SAI THAM SỐ" aw7 task lam-gi
ky_vong 2 "aw ready thiếu thư mục → engine trả SAI THAM SỐ" aw7 ready
ky_vong 0 "aw adr check → engine (repo chưa có ADR: HỢP LỆ)" aw7 adr check
ky_vong 0 "aw rule check → engine (repo chưa có luật: HỢP LỆ)" aw7 rule check
ky_vong 2 "aw knowledge thiếu tham số → engine trả SAI THAM SỐ" aw7 knowledge

# ---------------------------------------------------------------- thuật ngữ
nhom "thuật ngữ: workflow/rules/terms.md ↔ docs/thuat-ngu.md"
# lech_thuat_ngu <terms.md> <thuat-ngu.md> — thuật ngữ = cột 1 bảng terms.md; bên tài liệu cho
# người = mọi `…` trong ô đầu mỗi dòng bảng. In mỗi thuật ngữ chỉ một bên có; trả 1 nếu lệch.
lech_thuat_ngu() {
  awk -F'|' '
    FILENAME == ARGV[1] && /^\| `/ { t = $2; gsub(/^ *`|` *$/, "", t); a[t] = 1; next }
    FILENAME == ARGV[2] && /^\|/ { s = $2
      while (match(s, /`[^`]+`/)) { b[substr(s, RSTART + 1, RLENGTH - 2)] = 1; s = substr(s, RSTART + RLENGTH) } }
    END { n = 0
      for (t in a) if (!(t in b)) { print "thiếu trong thuat-ngu.md: " t; n++ }
      for (t in b) if (!(t in a)) { print "thiếu trong terms.md: " t; n++ }
      exit n > 0 }' "$1" "$2"
}
TN="$ROOT/workflow/rules/terms.md"; TD="$ROOT/docs/thuat-ngu.md"
dung "terms.md có bảng thuật ngữ" grep -q '^| `' "$TN"
dung "terms.md và thuat-ngu.md cùng một bộ thuật ngữ" lech_thuat_ngu "$TN" "$TD"
grep -v '^| `harness journal`' "$TD" > "$TMP/thuat-ngu-thieu.md"
ky_vong 1 "…thuat-ngu.md thiếu một thuật ngữ → báo" lech_thuat_ngu "$TN" "$TMP/thuat-ngu-thieu.md"
dung "…đúng thuật ngữ thiếu" bang "$(lech_thuat_ngu "$TN" "$TMP/thuat-ngu-thieu.md")" "thiếu trong thuat-ngu.md: harness journal"
grep -v '^| `harness journal`' "$TN" > "$TMP/terms-thieu.md"
ky_vong 1 "…terms.md thiếu một thuật ngữ thuat-ngu.md có → báo" lech_thuat_ngu "$TMP/terms-thieu.md" "$TD"
dung "…đúng thuật ngữ thiếu" bang "$(lech_thuat_ngu "$TMP/terms-thieu.md" "$TD")" "thiếu trong terms.md: harness journal"
# Cột Not phải viết thường: kc_tu_dich so khớp sau khi hạ chữ thường dòng artifact
dung "cột Not của terms.md viết thường" sh -c "! awk -F'|' '/^[|] \`/ { print \$(NF - 1) }' '$TN' | grep -Eq '[A-Z]|Đ|Ô'"
dung "general.md §5 trỏ tới rules/terms.md" grep -q 'rules/terms.md' "$ROOT/workflow/rules/general.md"
dung "workflow.yaml đăng ký terms.md" grep -q '^  - workflow/rules/terms.md$' "$ROOT/workflow.yaml"

ket_thuc
