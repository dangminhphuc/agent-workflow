#!/usr/bin/env sh
# MR (GitLab) / PR (GitHub) của một việc — dùng chung cho aw ship create|status|sweep.
#
# Engine không giữ token, không tự gọi API. Ba đường, theo thứ tự:
#   1. CLI chính chủ (gh, glab) mà người đã cài VÀ đăng nhập — gửi được cả mô tả,
#      hỏi được trạng thái MR.
#   2. GitLab không có glab: tạo MR ngay trong `git push` bằng push options
#      (merge_request.create…) — chỉ cần quyền git sẵn có. Push option không chứa
#      được xuống dòng nên chỉ gửi tiêu đề; mô tả người dán vào MR.
#   3. Còn lại (GitHub không có gh, push options bị tắt): link tạo MR điền sẵn
#      nguồn/đích/tiêu đề/mô tả; người tạo xong ghi lại bằng `--url <link>`.
# Không hỏi được nền tảng thì trạng thái suy từ git: merge thường (đầu branch nằm
# trong đích) và squash merge sạch (một commit của đích có cùng patch-id với toàn
# bộ thay đổi của branch). Squash có sửa xung đột, rebase merge: không nhận ra.
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
# Khoá mr_platform thắng; bỏ trống thì đoán từ URL của origin.
mr_nen_tang() {
  _mn=$(conv_get "$2" mr_platform)
  case "$_mn" in github|gitlab) echo "$_mn"; return 0 ;; esac
  _mu=$(git -C "$1" remote get-url origin 2>/dev/null)
  case "$_mu" in
    *github.com[:/]*) echo github ;;
    *gitlab*)         echo gitlab ;;
  esac
}

# mr_host <repo> -> host của origin (rỗng nếu không suy được)
mr_host() { mr_web "$1" | sed 's#^https://##; s#/.*##'; }

# mr_cli <nền-tảng> <repo> -> tên CLI dùng được: đã cài VÀ đã đăng nhập vào host
# của origin; cũng đặt MR_CLI_TEN. Mã 1 nếu không; MR_CLI_LY_DO ghi vì sao (để
# báo người). Cần hai biến đó thì gọi trực tiếp, không qua $(…) (subshell).
mr_cli() {
  MR_CLI_LY_DO=""; MR_CLI_TEN=""
  case "$1" in github) _mc=gh ;; gitlab) _mc=glab ;; *) MR_CLI_LY_DO="chưa biết nền tảng"; return 1 ;; esac
  command -v "$_mc" >/dev/null 2>&1 || { MR_CLI_LY_DO="máy không có $_mc"; return 1; }
  _mhst=$(mr_host "${2:-.}")
  if ! (cd "${2:-.}" && "$_mc" auth status ${_mhst:+--hostname "$_mhst"}) >/dev/null 2>&1; then
    MR_CLI_LY_DO="$_mc chưa đăng nhập${_mhst:+ vào $_mhst} ($_mc auth login${_mhst:+ --hostname $_mhst})"; return 1
  fi
  MR_CLI_TEN=$_mc; echo "$_mc"
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

# _mr_ma_url — stdin -> mã hoá phần trăm (giữ A-Z a-z 0-9 - _ . ~), theo byte (UTF-8 an toàn)
_mr_ma_url() {
  LC_ALL=C od -An -v -tx1 | LC_ALL=C awk '
    BEGIN { for (i = 0; i < 256; i++) { h = sprintf("%02x", i); c = sprintf("%c", i)
              if (c ~ /[A-Za-z0-9_.~-]/) giu[h] = c } }
    { for (i = 1; i <= NF; i++) printf "%s", ($i in giu) ? giu[$i] : "%" toupper($i) }'
}

# mr_link_tay <repo> <nền-tảng> <branch> <đích> [tiêu-đề] [file-mô-tả] -> link mở
# trang tạo MR điền sẵn. Mô tả làm link dài quá (> ~7000 ký tự) thì bỏ, người dán.
mr_link_tay() {
  _mw=$(mr_web "$1"); [ -n "$_mw" ] || return 0
  _mt=""; [ -z "${5:-}" ] || _mt=$(printf '%s' "$5" | _mr_ma_url)
  _mm=""; [ -z "${6:-}" ] || [ ! -f "$6" ] || _mm=$(_mr_ma_url < "$6")
  [ "${#_mm}" -le 6000 ] || _mm=""
  case "$2" in
    github) printf '%s/compare/%s...%s?expand=1%s%s\n' "$_mw" "$4" "$3" "${_mt:+&title=$_mt}" "${_mm:+&body=$_mm}" ;;
    gitlab) printf '%s/-/merge_requests/new?merge_request%%5Bsource_branch%%5D=%s&merge_request%%5Btarget_branch%%5D=%s%s%s\n' \
              "$_mw" "$3" "$4" "${_mt:+&merge_request%5Btitle%5D=$_mt}" "${_mm:+&merge_request%5Bdescription%5D=$_mm}" ;;
  esac
}

# _mr_url <chuỗi> -> URL MR/PR đầu tiên trong chuỗi
_mr_url() { grep -oE 'https?://[^ "]+/(pull/[0-9]+|merge_requests/[0-9]+)' | head -1; }

# mr_tim <repo> <nền-tảng> <branch> <đích> -> URL MR đang MỞ từ branch vào đích (rỗng nếu không có)
mr_tim() {
  _mc=$(mr_cli "$2" "$1") || return 0
  case "$2" in
    github) (cd "$1" && gh pr list --head "$3" --base "$4" --state open --json url --jq '.[0].url // empty' 2>/dev/null) | _mr_url ;;
    gitlab) (cd "$1" && glab mr list --source-branch "$3" --target-branch "$4" -F json 2>/dev/null) | grep -o '"web_url":"[^"]*"' | head -1 | sed 's/.*:"//; s/"$//' ;;
  esac
}

# mr_tao <repo> <nền-tảng> <branch> <đích> <tiêu-đề> <file-mô-tả> <draft:1|rỗng> -> URL
mr_tao() {
  _mc=$(mr_cli "$2" "$1") || return 1
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

# mr_tao_push <repo> <branch> <đích> <tiêu-đề> <draft:1|rỗng> -> URL MR (GitLab push options)
# Push chính là lần tạo MR. MR đã có thì GitLab in link MR cũ — không tạo trùng.
# Mã 1: push hỏng; mã 2: push xong mà không thấy link MR (không phải GitLab,
# hoặc server tắt push options).
mr_tao_push() {
  case "$4" in *"
"*) return 2 ;; esac
  _mo=$(git -C "$1" push -u origin "$2" -o merge_request.create -o "merge_request.target=$3" \
          -o "merge_request.title=$4" -o merge_request.remove_source_branch ${5:+-o merge_request.draft} 2>&1) ||
    { printf '%s\n' "$_mo" | sed 's/^/    /' >&2; return 1; }
  _mx=$(printf '%s\n' "$_mo" | _mr_url)
  [ -n "$_mx" ] || return 2
  echo "$_mx"
}

# mr_da_squash <repo> <head> <đích> -> 0 nếu trên origin/<đích>, sau điểm rẽ, có một
# commit mang ĐÚNG toàn bộ thay đổi của branch (cùng patch-id) — squash merge sạch.
mr_da_squash() {
  _sb=$(git -C "$1" merge-base "$2" "refs/remotes/origin/$3" 2>/dev/null) || return 1
  _sp=$(git -C "$1" diff "$_sb" "$2" 2>/dev/null | git -C "$1" patch-id --stable 2>/dev/null | cut -d' ' -f1)
  [ -n "$_sp" ] || return 1
  for _sc in $(git -C "$1" rev-list --no-merges --max-count=500 "$_sb..refs/remotes/origin/$3" 2>/dev/null); do
    [ "$(git -C "$1" show "$_sc" 2>/dev/null | git -C "$1" patch-id --stable 2>/dev/null | cut -d' ' -f1)" = "$_sp" ] && return 0
  done
  return 1
}

# mr_xem <repo> <nền-tảng> <url> -> "<state> <head-sha>" (state: open|merged|closed).
# Mã 1: có CLI mà hỏi không được; mã 2: không có CLI dùng được.
mr_xem() {
  _mc=$(mr_cli "$2" "$1") || return 2
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
# Không hỏi được: git thấy đã merge (thường hoặc squash sạch) → merged; không thì
# giữ trạng thái cũ khi không có CLI (MR tạo bằng push options/tay vẫn "open"),
# và unknown khi có CLI mà hỏi lỗi.
sm_cap_nhat() {
  _su_nt=$(sm_gia_tri "$2" Platform); _su_b=$(sm_gia_tri "$2" Branch)
  _su_ft=$(sed -n '1s/^# Ship — //p' "$2")
  _su_moi=$(sm_dong "$2" | while IFS='|' read -r _d _s _h _u; do
    case "$_s" in
      merged) ;;   # MR bị đóng còn mở lại được — hỏi lại
      *)
        _x=$(mr_xem "$1" "$_su_nt" "$_u"); _xm=$?
        if [ "$_xm" = 0 ]; then
          _s=${_x%% *}; _n=${_x#* }; [ -n "$_n" ] && [ "$_n" != "$_x" ] && _h=$_n
        else
          git -C "$1" fetch -q origin "$_d" 2>/dev/null
          if [ -n "$_h" ] && { git -C "$1" merge-base --is-ancestor "$_h" "refs/remotes/origin/$_d" 2>/dev/null ||
                               mr_da_squash "$1" "$_h" "$_d"; }; then _s=merged
          elif [ "$_xm" = 1 ] || [ "$_s" = unknown ]; then _s=unknown
          fi
        fi ;;
    esac
    printf '%s|%s|%s|%s\n' "$_d" "$_s" "$_h" "$_u"
  done)
  printf '%s\n' "$_su_moi" | sm_ghi "$2" "$_su_ft" "$_su_nt" "$_su_b"
}
