#!/usr/bin/env sh
# Đọc / ghi trạng thái task trong plan.md — dùng chung cho aw task, aw ready và
# checker implement. Một nguồn duy nhất cho việc "task nào đang ở đâu".
#
# Task là mục "### TSK-NNN — <tiêu đề>" trong plan.md, các dòng cần đọc:
#   - Depends on: none | TSK-001, TSK-002
#   - Verify: `<lệnh>` → <kết quả mong đợi>
#   - Status: `[ ]` | `[~]` | `[x]`
#
# Trạng thái chỉ được nâng lên [x] bằng `aw task done` — lệnh đó chạy lệnh trong
# "Verify" và ghi bằng chứng vào task-results.md (xem tools/task.sh).

# tk_ds <plan.md> -> mỗi task một dòng "TSK-NNN|<s>|<phụ thuộc cách dấu phẩy>|<lệnh verify>"
# <s>: ' ' chưa làm, '~' đang làm, 'x' xong, '?' không đọc được ô Status.
# Lệnh verify là chuỗi trong cặp backtick ĐẦU TIÊN của dòng Verify (rỗng nếu không có).
tk_ds() {
  [ -f "$1" ] || return 0
  awk '
    function xuat() { if (id != "") print id "|" st "|" dep "|" vf }
    { sub(/\r$/, "") }
    /^##[ \t]/ && !/^###/ { xuat(); id = ""; next }
    /^###[ \t]+TSK-[0-9]+/ {
      xuat(); match($0, /TSK-[0-9]+/); id = substr($0, RSTART, RLENGTH); st = "?"; dep = ""; vf = ""; next
    }
    id != "" && /^[ \t]*-[ \t]*\**Depends on\**:/ {
      s = $0; sub(/^[^:]*:/, "", s); d = ""
      while (match(s, /TSK-[0-9]+/)) { d = d (d == "" ? "" : ",") substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) }
      dep = d; next
    }
    id != "" && /^[ \t]*-[ \t]*\**Verify\**:/ {
      s = $0; sub(/^[^:]*:/, "", s)
      if (match(s, /`[^`]+`/)) vf = substr(s, RSTART + 1, RLENGTH - 2)
      gsub(/\|/, "¦", vf); next
    }
    id != "" && /^[ \t]*-[ \t]*\**Status\**:/ {
      if ($0 ~ /\[x\]/) st = "x"; else if ($0 ~ /\[~\]/) st = "~"; else if ($0 ~ /\[ \]/) st = " "
      next
    }
    END { xuat() }
  ' "$1"
}

# tk_dong <plan.md> <TSK-NNN> -> dòng của task đó trong tk_ds (mã 1 nếu không có)
tk_dong() {
  _tk_d=$(tk_ds "$1" | awk -F'|' -v t="$2" '$1 == t { print; exit }')
  [ -n "$_tk_d" ] || return 1
  printf '%s\n' "$_tk_d"
}

# tk_verify <plan.md> <TSK-NNN> -> lệnh verify của task (rỗng nếu không có)
tk_verify() { tk_dong "$1" "$2" | cut -d'|' -f4- | sed 's/¦/|/g'; }

# tk_tiep <plan.md> -> task phải làm tiếp: task đang [~] nếu có (làm cho xong
# trước — WIP=1); không thì task [ ] đầu tiên có mọi phụ thuộc đã [x].
# Không in gì khi hết việc hoặc mọi task còn lại đều đang chờ phụ thuộc.
tk_tiep() {
  tk_ds "$1" | awk -F'|' '
    { id[++n] = $1; st[$1] = $2; dep[$1] = $3 }
    END {
      for (i = 1; i <= n; i++) if (st[id[i]] == "~") { print id[i]; exit }
      for (i = 1; i <= n; i++) {
        t = id[i]; if (st[t] != " ") continue
        k = split(dep[t], d, ","); ok = 1
        for (j = 1; j <= k; j++) if (d[j] != "" && st[d[j]] != "x") ok = 0
        if (ok) { print t; exit }
      }
    }'
}

# tk_dat <plan.md> <TSK-NNN> <s> -> ghi ô Status của task thành `[<s>]`, giữ phần
# chữ sau ô (vd danh sách file đã đụng). Mã 1 nếu không tìm thấy dòng Status.
tk_dat() {
  _tk_tmp="$1.tk.$$"
  awk -v t="$2" -v s="$3" '
    { sub(/\r$/, "") }
    /^##[ \t]/ { vao = 0 }
    /^###[ \t]+TSK-[0-9]+/ { match($0, /TSK-[0-9]+/); vao = (substr($0, RSTART, RLENGTH) == t) }
    vao && !xong && /^[ \t]*-[ \t]*\**Status\**:/ {
      l = $0
      if (match(l, /`\[[ ~x]\]`/)) l = substr(l, 1, RSTART - 1) "`[" s "]`" substr(l, RSTART + RLENGTH)
      else if (match(l, /\[[ ~x]\]/)) l = substr(l, 1, RSTART - 1) "`[" s "]`" substr(l, RSTART + RLENGTH)
      else { sub(/:.*/, ": `[" s "]`", l) }
      print l; xong = 1; next
    }
    { print }
    END { exit xong ? 0 : 1 }
  ' "$1" > "$_tk_tmp" && mv "$_tk_tmp" "$1" || { rm -f "$_tk_tmp"; return 1; }
}

# ------------------------------------------------------------------ bằng chứng task
# task-results.md: mỗi task một mục "## TSK-NNN", do `aw task done` ghi (không ai sửa tay).
#   - Lệnh: `<lệnh verify lúc chạy>`
#   - Mã thoát: `<n>`
#   - Lần chạy: <n>        (đếm cả lần đỏ — giới hạn vòng lặp đọc số này)
#   - HEAD / Tree / Thời điểm (kc_dong_moi)

# tk_bc <task-results.md> <TSK-NNN> <khoá> -> giá trị dòng "- <khoá>:" trong mục của task
tk_bc() {
  [ -f "$1" ] || return 0
  awk -v t="$2" -v k="$3" '
    { sub(/\r$/, "") }
    /^##[ \t]/ { vao = ($0 ~ ("^##[ \t]+" t "([ \t]|$)")); next }
    vao && index($0, "- " k ":") == 1 {
      s = substr($0, length(k) + 4); gsub(/^[ \t]+|[ \t]+$/, "", s)
      if (s ~ /^`.*`$/) s = substr(s, 2, length(s) - 2)
      print s; exit
    }
  ' "$1"
}

# tk_thieu_bang_chung <thư-mục-feature> -> task [x] mà task-results.md không có
# bằng chứng xanh khớp lệnh Verify hiện tại. Mỗi dòng một phát hiện.
# giữ: CAP-implement-06
tk_thieu_bang_chung() {
  _tk_kq="$1/task-results.md"
  tk_ds "$1/plan.md" | while IFS='|' read -r _t _s _d _v; do
    [ "$_s" = x ] || continue
    _v=$(printf '%s' "$_v" | sed 's/¦/|/g')
    _ma=$(tk_bc "$_tk_kq" "$_t" "Mã thoát")
    _l=$(tk_bc "$_tk_kq" "$_t" "Lệnh")
    if [ -z "$_ma" ]; then
      echo "$_t đánh [x] nhưng không có bằng chứng trong task-results.md — trạng thái chỉ lên [x] bằng: aw task done $1 $_t"
    elif [ "$_ma" != 0 ]; then
      echo "$_t đánh [x] nhưng lần chạy Verify gần nhất RED (mã $_ma) — sửa rồi chạy lại: aw task done $1 $_t"
    elif [ "$_l" != "$_v" ]; then
      echo "$_t: lệnh Verify trong plan.md đã đổi sau khi task xong (đã chạy \`$_l\`) — chạy lại: aw task done $1 $_t"
    fi
  done
}

# tk_chua_xong <thư-mục-feature> -> task chưa làm `[ ]` hoặc ô Status không đọc
# được. Implement xong = MỌI task [x]; task người quyết bỏ thì xoá khỏi plan.md
# (REQ của nó sang "Deferred"), không để [ ] lặng lẽ.
tk_chua_xong() {
  tk_ds "$1/plan.md" | while IFS='|' read -r _t _s _d _v; do
    case "$_s" in
      " ") echo "$_t chưa làm (\`[ ]\`) — làm cho xong; người quyết bỏ thì xoá task khỏi plan.md và ghi REQ của nó vào \"Deferred\"" ;;
      "?") echo "$_t: ô Status không đọc được — phải là \`[ ]\`, \`[~]\` hoặc \`[x]\`" ;;
    esac
  done
}

# tk_dang_do <thư-mục-feature> -> task còn [~]
tk_dang_do() {
  tk_ds "$1/plan.md" | awk -F'|' '$2 == "~" { print $1 " còn ở trạng thái đang làm dở `[~]`" }'
}

# tk_phu <plan.md> <REQ-NNN|DEC-NNN|Q-NNN> -> task chịu ảnh hưởng khi mã đó đổi, mỗi dòng "TSK-NNN|<s>".
# REQ: dòng "Covers" hoặc "On assumption" nhắc mã; DEC: dòng "Based on"; Q (câu hỏi): dòng
# "On assumption". So nguyên mã (REQ-01 không khớp REQ-010; Q-001 không khớp REQ-001).
tk_phu() {
  [ -f "$1" ] || return 0
  awk -v ma="$2" '
    function co_ma(s,   m) {
      while (match(s, /(REQ|DEC|Q)-[0-9]+/)) { m = substr(s, RSTART, RLENGTH); if (m == ma) return 1; s = substr(s, RSTART + RLENGTH) }
      return 0
    }
    function xuat() { if (id != "" && trung) print id "|" st }
    BEGIN { truong = (ma ~ /^REQ-/) ? "(Covers|On assumption)" : (ma ~ /^Q-/) ? "On assumption" : "Based on" }
    { sub(/\r$/, "") }
    /^##[ \t]/ && !/^###/ { xuat(); id = ""; next }
    /^###[ \t]+TSK-[0-9]+/ { xuat(); match($0, /TSK-[0-9]+/); id = substr($0, RSTART, RLENGTH); st = "?"; trung = 0; next }
    id != "" && $0 ~ ("^[ \t]*-[ \t]*[*]*" truong "[*]*:") { s = $0; sub(/^[^:]*:/, "", s); if (co_ma(s)) trung = 1; next }
    id != "" && /^[ \t]*-[ \t]*\**Status\**:/ {
      if ($0 ~ /\[x\]/) st = "x"; else if ($0 ~ /\[~\]/) st = "~"; else if ($0 ~ /\[ \]/) st = " "
      next
    }
    END { xuat() }
  ' "$1"
}

# ------------------------------------------------------------------ phạm vi theo task
# tk_mau_task <plan.md> <TSK-NNN> -> mẫu file được phép cho riêng task: token trong backtick ở
# dòng "Expected files" của task, cộng hàng "Unplanned" có cột Task = task đó.
tk_mau_task() {
  awk -v t="$2" '
    function bt(s) { while (match(s, /`[^`]+`/)) { print substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }
    { sub(/\r$/, "") }
    /^###[ \t]/ { vao = ($0 ~ ("^###[ \t]+" t "([ \t]|$)")); next }
    /^##[ \t]+Unplanned/ { un = 1; vao = 0; next }
    /^##[ \t]/ { un = 0; vao = 0; next }
    vao && /^[ \t]*-[ \t]*\**Expected files\**:/ { bt($0) }
    un && /^\|/ { split($0, c, "|"); x = c[2]; gsub(/[ \t`*]/, "", x); if (x == t) bt(c[4]) }  # chỉ cột "Extra files"
  ' "$1"
}

# tk_pham_vi <thư-mục-feature> <TSK-NNN> <commit lúc start> -> file đổi từ lúc task bắt đầu (đã commit,
# working tree, chưa track) mà không khớp mẫu của riêng task, trừ ignored_files và artifact.
# Mỗi dòng một file. Chỉ để cảnh báo: sửa file của task khác có thể chính đáng (ghi "Unplanned").
# giữ: CAP-implement-05
tk_pham_vi() {
  _pv_top=$(git_top "$1") || return 0
  git -C "$_pv_top" cat-file -e "$3^{commit}" 2>/dev/null || return 0
  _pv_bo=$(conv_get "$(kc_conventions "$1")" ignored_files)
  _pv_cho=$(tk_mau_task "$1/plan.md" "$2")
  set -f
  { git -C "$_pv_top" diff --name-only "$3"; git -C "$_pv_top" ls-files --others --exclude-standard; } \
    | sort -u | while IFS= read -r _pv_f; do
      [ -n "$_pv_f" ] || continue
      tm_bo "$_pv_f" && continue
      # shellcheck disable=SC2086
      khop_glob "$_pv_f" $_pv_bo && continue
      # shellcheck disable=SC2086
      khop_glob "$_pv_f" $_pv_cho && continue
      printf '%s\n' "$_pv_f"
    done
  set +f
}

# tk_pham_vi_chua_giai_trinh <thư-mục-feature> <review.md> -> task có "Scope warning" trong
# task-results.md mà dòng "- Task scope warnings:" của review.md không nhắc tên. Mỗi dòng một task.
tk_pham_vi_chua_giai_trinh() {
  [ -f "$1/task-results.md" ] || return 0
  awk 'FILENAME == ARGV[1] {
         sub(/\r$/, "")
         if ($0 ~ /^##[ \t]/) { t = ""; if (match($0, /TSK-[0-9]+/)) t = substr($0, RSTART, RLENGTH); next }
         if (t != "" && $0 ~ /^- Scope warning:/ && !(t in co)) { co[t] = 1; ds[++n] = t }
         next
       }
       { sub(/\r$/, "") }
       /^[ \t]*-[ \t]*\**Task scope warnings\**:/ { gt = gt " " $0 }
       # mã đủ chữ số: TSK-0021 không tính là nhắc TSK-002
       END { for (i = 1; i <= n; i++) if (gt !~ ("(^|[^0-9A-Za-z-])" ds[i] "([^0-9]|$)")) print ds[i] }' "$1/task-results.md" "$2"
}
