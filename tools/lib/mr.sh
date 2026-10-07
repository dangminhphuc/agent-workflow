#!/usr/bin/env sh
# MR (GitLab) / PR (GitHub) của một việc — dùng chung cho aw ship create|status|sweep.
#
# Engine không tự gọi API: nó gọi CLI chính chủ của nền tảng (gh, glab) mà người
# đã đăng nhập sẵn. Không có CLI thì người tạo MR bằng tay rồi ghi lại bằng
# `aw ship create … --url <link>`; trạng thái khi đó suy từ git (chỉ nhận ra
# merge thường, không nhận ra squash/rebase).
#
# Trạng thái MR của việc nằm ở <thư-mục-feature>/ship.md — máy ghi, người đọc:
#
#   - **Platform:** github
#   - **Branch:** feat_x
#
#   | Target | State | Head | URL |
#   |---|---|---|---|
#   | develop | open | <sha đầy đủ> | https://… |
#
# State: open | merged | closed | unknown. Head: sha đầu branch mà MR đang trỏ
# (nền tảng báo); lúc dọn, branch local chỉ được xoá cứng khi trùng sha này.

# mr_nen_tang <repo> <conventions.md> -> github | gitlab | rỗng
# Khoá nen_tang_mr thắng; bỏ trống thì đoán từ URL của origin.
mr_nen_tang() {
  _mn=$(conv_get "$2" nen_tang_mr)
  case "$_mn" in github|gitlab) echo "$_mn"; return 0 ;; esac
  _mu=$(git -C "$1" remote get-url origin 2>/dev/null)
  case "$_mu" in
    *github.com[:/]*) echo github ;;
    *gitlab*)         echo gitlab ;;
  esac
}

# mr_cli <nền-tảng> -> tên CLI (mã 1 nếu máy không có)
mr_cli() {
  case "$1" in github) _mc=gh ;; gitlab) _mc=glab ;; *) return 1 ;; esac
  command -v "$_mc" >/dev/null 2>&1 || return 1
  echo "$_mc"
}

# mr_web <repo> -> https://host/nhóm/repo từ URL của origin (rỗng nếu không suy được)
mr_web() {
  git -C "$1" remote get-url origin 2>/dev/null | awk '{
    u = $0; sub(/\.git$/, "", u)
    if (u ~ /^git@[^:]+:/)      { sub(/^git@/, "", u); sub(/:/, "/", u) }
    else if (u ~ /^ssh:\/\//)  { sub(/^ssh:\/\/([^@\/]*@)?/, "", u); sub(/:[0-9]+\//, "/", u) }
    else if (u ~ /^https?:\/\//) { sub(/^https?:\/\/([^@\/]*@)?/, "", u) }
    else exit
    print "https://" u
  }'
}

# mr_link_tay <repo> <nền-tảng> <branch> <đích> -> link mở trang tạo MR bằng tay
mr_link_tay() {
  _mw=$(mr_web "$1"); [ -n "$_mw" ] || return 0
  case "$2" in
    github) echo "$_mw/compare/$4...$3?expand=1" ;;
    gitlab) echo "$_mw/-/merge_requests/new?merge_request%5Bsource_branch%5D=$3&merge_request%5Btarget_branch%5D=$4" ;;
  esac
}

# _mr_url <chuỗi> -> URL MR/PR đầu tiên trong chuỗi
_mr_url() { grep -oE 'https?://[^ "]+/(pull/[0-9]+|merge_requests/[0-9]+)' | head -1; }

# mr_tim <repo> <nền-tảng> <branch> <đích> -> URL MR đang MỞ từ branch vào đích (rỗng nếu không có)
mr_tim() {
  _mc=$(mr_cli "$2") || return 0
  case "$2" in
    github) (cd "$1" && gh pr list --head "$3" --base "$4" --state open --json url --jq '.[0].url // empty' 2>/dev/null) | _mr_url ;;
    gitlab) (cd "$1" && glab mr list --source-branch "$3" --target-branch "$4" -F json 2>/dev/null) | grep -o '"web_url":"[^"]*"' | head -1 | sed 's/.*:"//; s/"$//' ;;
  esac
}

# mr_tao <repo> <nền-tảng> <branch> <đích> <tiêu-đề> <file-mô-tả> <draft:1|rỗng> -> URL
mr_tao() {
  _mc=$(mr_cli "$2") || return 1
  case "$2" in
    github)
      _mo=$( (cd "$1" && gh pr create --head "$3" --base "$4" --title "$5" --body-file "$6" ${7:+--draft}) 2>&1) ;;
    gitlab)
      _mo=$( (cd "$1" && glab mr create --source-branch "$3" --target-branch "$4" --title "$5" --description "$(cat "$6")" --remove-source-branch --yes ${7:+--draft}) 2>&1) ;;
  esac
  _mx=$(printf '%s\n' "$_mo" | _mr_url)
  if [ -z "$_mx" ]; then printf '%s\n' "$_mo" | sed 's/^/    /' >&2; return 1; fi
  echo "$_mx"
}

# mr_xem <repo> <nền-tảng> <url> -> "<state> <head-sha>" (state: open|merged|closed); mã 1 nếu không hỏi được
mr_xem() {
  _mc=$(mr_cli "$2") || return 1
  case "$2" in
    github)
      _mo=$( (cd "$1" && gh pr view "$3" --json state,headRefOid --jq '.state + " " + .headRefOid') 2>/dev/null) || return 1
      _ms=$(printf '%s' "$_mo" | awk '{ print tolower($1) }'); _mh=$(printf '%s' "$_mo" | awk '{ print $2 }') ;;
    gitlab)
      _mo=$( (cd "$1" && glab mr view "$3" -F json) 2>/dev/null) || return 1
      _ms=$(printf '%s' "$_mo" | grep -o '"state":"[^"]*"' | head -1 | sed 's/.*:"//; s/"$//')
      _mh=$(printf '%s' "$_mo" | grep -o '"sha":"[0-9a-f]*"' | head -1 | sed 's/.*:"//; s/"$//')
      [ "$_ms" = opened ] && _ms=open ;;
  esac
  case "$_ms" in open|merged|closed) ;; *) return 1 ;; esac
  echo "$_ms $_mh"
}

# ---------------------------------------------------------------- ship.md

# sm_gia_tri <ship.md> <nhãn> -> giá trị dòng "- **<nhãn>:** …"
sm_gia_tri() {
  [ -f "$1" ] || return 0
  awk -v k="$2" '{ sub(/\r$/, "") } index($0, "- **" k ":**") == 1 { s = $0; sub(/^[^:]*:\*\*[ \t]*/, "", s); gsub(/`/, "", s); print s; exit }' "$1"
}

# sm_dong <ship.md> -> mỗi MR một dòng "đích|state|head|url"
sm_dong() {
  [ -f "$1" ] || return 0
  awk -F'|' '{ sub(/\r$/, "") }
    /^\|/ && $2 !~ /^[ \t]*(Target|-+)[ \t]*$/ {
      for (i = 2; i <= 5; i++) { gsub(/^[ \t`]+|[ \t`]+$/, "", $i) }
      if ($2 != "") print $2 "|" $3 "|" $4 "|" $5
    }' "$1"
}

# sm_ghi <ship.md> <feature> <nền-tảng> <branch> — đọc các dòng "đích|state|head|url" từ stdin
sm_ghi() {
  _sm_tmp="$1.tmp"
  {
    printf '# Ship — %s\n\n' "$2"
    printf '> File này do `aw ship` ghi — không sửa tay. Cập nhật trạng thái: `aw ship status`.\n\n'
    printf -- '- **Platform:** %s\n' "${3:-unknown}"
    printf -- '- **Branch:** %s\n\n' "$4"
    printf '| Target | State | Head | URL |\n|---|---|---|---|\n'
    while IFS='|' read -r _d _s _h _u; do
      [ -n "$_d" ] && printf '| %s | %s | %s | %s |\n' "$_d" "$_s" "$_h" "$_u"
    done
  } > "$_sm_tmp" && mv "$_sm_tmp" "$1"
}

# sm_cap_nhat <repo> <ship.md> — hỏi nền tảng trạng thái từng MR chưa merge rồi ghi lại.
# Không có CLI: MR mà head đã nằm trong origin/<đích> thì coi là merged (git thấy).
sm_cap_nhat() {
  _su_nt=$(sm_gia_tri "$2" Platform); _su_b=$(sm_gia_tri "$2" Branch)
  _su_ft=$(sed -n '1s/^# Ship — //p' "$2")
  _su_moi=$(sm_dong "$2" | while IFS='|' read -r _d _s _h _u; do
    case "$_s" in
      merged) ;;   # MR bị đóng còn mở lại được — hỏi lại
      *)
        if _x=$(mr_xem "$1" "$_su_nt" "$_u"); then
          _s=${_x%% *}; _n=${_x#* }; [ -n "$_n" ] && [ "$_n" != "$_x" ] && _h=$_n
        else
          git -C "$1" fetch -q origin "$_d" 2>/dev/null
          if [ -n "$_h" ] && git -C "$1" merge-base --is-ancestor "$_h" "refs/remotes/origin/$_d" 2>/dev/null; then _s=merged; else _s=unknown; fi
        fi ;;
    esac
    printf '%s|%s|%s|%s\n' "$_d" "$_s" "$_h" "$_u"
  done)
  printf '%s\n' "$_su_moi" | sm_ghi "$2" "$_su_ft" "$_su_nt" "$_su_b"
}
