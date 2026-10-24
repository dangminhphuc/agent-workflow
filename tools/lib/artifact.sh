#!/usr/bin/env sh
# Artifact của việc trong git: commit vào branch của việc trong lúc làm, gỡ khỏi
# branch trước khi tạo MR — không bao giờ vào nhánh đích (develop/uat/main…).
#
#   ar_commit   aw check <tên> ĐẠT, aw approvals tick, aw rename gọi: commit CHỈ
#               thư mục việc (git add -f — TM_VIEC bị exclude để git add -A của
#               người/agent không kéo artifact vào commit code).
#   ar_go       aw ship create gọi trước khi push: git rm --cached cả thư mục việc
#               + commit; file vẫn ở máy (bị exclude), đánh dấu AR_CHI_MAY để từ
#               đó không commit lại (commit lại = artifact quay về MR).
#
# Chỉ áp dụng cho thư mục việc kiểu mới (<gốc worktree>/TM_VIEC/<tên>); việc bắt
# đầu bằng engine cũ (TM_CU) giữ như cũ: chỉ ở máy.
# Commit dùng --no-verify: hook của repo đích viết cho code (lint-staged có thể
# định dạng lại artifact làm mất dấu duyệt; commit-msg có thể chặn). Lý do:
# docs/kien-truc.md § Artifact theo feature.
#
# Cần nạp trước: tools/lib/md.sh, tools/lib/adapter.sh

AR_CHI_MAY=".local-only"

# ar_goc <thư-mục-việc> -> gốc worktree (đường dẫn thật) nếu thư mục là
# <gốc>/TM_VIEC/<tên>; mã 1 nếu không phải (việc kiểu cũ, ngoài git…)
ar_goc() {
  [ -d "$1" ] || return 1
  _ag=$(git_top "$1") || return 1
  _ag=$(CDPATH= cd -- "$_ag" && pwd -P) || return 1
  _ad=$(CDPATH= cd -- "$1" && pwd -P) || return 1
  [ "$(dirname "$_ad")" = "$_ag/$TM_VIEC" ] || return 1
  printf '%s\n' "$_ag"
}

# ar_commit <thư-mục-việc> <message> [đường-dẫn-thêm (tương đối gốc)...]
# Không có gì đổi, chỉ progress.md đổi, việc kiểu cũ, hay đã gỡ trước MR: không làm gì (mã 0).
# Mã 1: git từ chối — thông báo của git ở stderr.
ar_commit() {
  _ag=$(ar_goc "$1") || return 0
  [ -f "$1/$AR_CHI_MAY" ] && return 0
  # Checkout chính đứng trên nhánh gốc: commit ở đó là đưa artifact vào nhánh đích.
  if [ "$(git -C "$_ag" rev-parse --git-dir 2>/dev/null)" = "$(git_common "$_ag")" ]; then
    echo "Artifact: $1 nằm ở checkout chính — không commit (artifact chỉ commit trong worktree của việc)." >&2
    return 0
  fi
  _am=$2; _ar="$TM_VIEC/$(basename "$1")"; shift 2
  al_ghi_exclude "" "" "$_ag" >/dev/null
  git -C "$_ag" add -f -A -- "$_ar" "$@" || return 1
  git -C "$_ag" diff --cached --quiet -- "$_ar" "$@" && return 0
  # Chỉ progress.md đổi (aw check lại, mỗi lần thêm một sự kiện): không commit riêng — tránh commit
  # nhiễu; file vẫn ở đĩa và đi cùng commit artifact thật kế tiếp. Bỏ stage để commit code không cuốn theo.
  if [ "$(git -C "$_ag" -c core.quotepath=off diff --cached --name-only -- "$_ar" "$@")" = "$_ar/progress.md" ]; then
    git -C "$_ag" reset -q -- "$_ar/progress.md" >/dev/null 2>&1
    return 0
  fi
  # Chỉ các đường dẫn này: phần người đã stage cho commit code không bị cuốn theo.
  git -C "$_ag" commit -q --no-verify -m "$_am" -- "$_ar" "$@" || return 1
  AR_DA_COMMIT=1
}

# ar_go <thư-mục-việc> -> gỡ thư mục việc khỏi branch (commit), giữ file ở máy.
# Mã 1: git từ chối.
ar_go() {
  _ag=$(ar_goc "$1") || return 0
  _ar="$TM_VIEC/$(basename "$1")"
  al_ghi_exclude "" "" "$_ag" >/dev/null
  printf '%s\n' "Artifact đã gỡ khỏi branch trước MR (aw ship create) — từ đây chỉ ở máy, aw check không commit lại." > "$1/$AR_CHI_MAY"
  [ -n "$(git -C "$_ag" ls-files -- "$_ar")" ] || return 0
  git -C "$_ag" rm -r -q --cached -- "$_ar" >/dev/null || return 1
  # Không kèm pathspec: "commit -- <đường dẫn>" lấy lại bản trên đĩa, tức thêm ngược file vừa gỡ.
  # Index chỉ có thay đổi này — aw ship create đã chặn khi còn thay đổi khác chưa commit.
  git -C "$_ag" commit -q --no-verify -m "chore(sdlc): remove $(basename "$1") artifacts before MR" || return 1
  AR_DA_COMMIT=1
}

# ar_trong_diff <gốc worktree> <ref đích> -> in file thuộc TM_VIEC mà MR vào <ref>
# sẽ mang theo (vd thư mục việc khác của branch xếp chồng); rỗng = sạch.
ar_trong_diff() {
  git -C "$1" -c core.quotepath=off diff --name-only "$2...HEAD" -- "$TM_VIEC" 2>/dev/null
}
