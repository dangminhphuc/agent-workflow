#!/usr/bin/env sh
# Worktree là BẮT BUỘC: checkout chính chỉ đứng ở nhánh gốc và chỉ chạy /aw-intake;
# mỗi việc làm trong một worktree riêng, một phiên agent riêng.
#
# Không dùng "rev-parse --path-format=absolute" (cần git ≥ 2.31): tự đổi sang
# đường dẫn tuyệt đối để chạy được trên git cũ.

# wt_tuyet_doi <thư-mục> <đường-dẫn-git-in-ra> -> đường dẫn tuyệt đối
wt_tuyet_doi() {
  case "$2" in
    /*) (CDPATH= cd -- "$2" 2>/dev/null && pwd) ;;
    *)  (CDPATH= cd -- "$1" 2>/dev/null && CDPATH= cd -- "$2" 2>/dev/null && pwd) ;;
  esac
}

# wt_la_chinh <thư-mục> -> 0 nếu thư mục nằm trong checkout CHÍNH (không phải worktree con)
wt_la_chinh() {
  _wd=$(git -C "$1" rev-parse --git-dir 2>/dev/null) || return 1
  _wc=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
  [ "$(wt_tuyet_doi "$1" "$_wd")" = "$(wt_tuyet_doi "$1" "$_wc")" ]
}

# wt_chinh <thư-mục> -> gốc của checkout chính (dùng cho {repo}, và để chạy lệnh dọn)
wt_chinh() {
  _wc=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
  dirname "$(wt_tuyet_doi "$1" "$_wc")"
}

# wt_cua_branch <thư-mục> <branch> -> đường dẫn worktree đang check out branch đó (rỗng nếu không có)
wt_cua_branch() {
  git -C "$1" worktree list --porcelain 2>/dev/null |
    awk -v b="refs/heads/$2" '/^worktree /{ p = substr($0, 10) } $0 == "branch " b { print p; exit }'
}

# wt_chuan_hoa <đường-dẫn-tuyệt-đối> -> bỏ "." và ".." (thư mục có thể chưa tồn tại)
wt_chuan_hoa() {
  printf '%s\n' "$1" | awk '{
    n = split($0, a, "/"); k = 0
    for (i = 1; i <= n; i++) {
      if (a[i] == "" || a[i] == ".") continue
      if (a[i] == "..") { if (k > 0) k--; continue }
      o[++k] = a[i]
    }
    s = ""; for (i = 1; i <= k; i++) s = s "/" o[i]
    print (s == "" ? "/" : s)
  }'
}
