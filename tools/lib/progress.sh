#!/usr/bin/env sh
# Tiến độ của một việc (SP20): sự kiện chuẩn hoá từ journal + khối aw-progress v1, số liệu từng phase.
#
#   . "$HERE/lib/progress.sh"       nạp không in gì, không cần thư viện khác
#
#   bay <chuỗi>            -> một dòng, không tab
#   may_nay                -> tên máy (AW_JOURNAL_MACHINE hoặc uname -n), qua bay
#   td_su_kien <dir>       -> sự kiện chuẩn hoá của việc (basename <dir>); khối sai dạng: TD_CANH_BAO=1
#   td_tinh <dir>          -> dòng P/R/B/M (cần nạp trước md.sh, cross-check.sh; HERE = tools/)
#   td_tg <giây>           -> 2h10m | 25m | 40s | — (rỗng)
#   td_tk <số>             -> 999 | 82k | 1.2M | — (rỗng)
#   td_md_bang <dir>       -> bảng Markdown (header, dòng phase, **Total**); rỗng nếu không có dữ liệu
#   td_md_file <dir>       -> nội dung progress.md (bảng, Gantt, pie, khối aw-progress v1)
#   (td_md_*: cần như td_tinh; khối sai dạng: TD_CANH_BAO=1)
#
# Sự kiện (tab giữa cột; cũng là dòng trong khối "<!-- aw-progress v1" … "-->" của progress.md):
#   phases  <máy>  <ts>  <phase>
#   turns   <máy>  <ts_begin>  <ts_end>  <phase>  <kind>  <seconds>  <in>  <out>  <cache_read>  <cache_write>
#   checks  <máy>  <ts>  <checker>  <exit>
# Dòng td_tinh (tab giữa cột; ô không có dữ liệu = rỗng):
#   P  <phase>  <done|active|skipped|pending>  <active_s>  <wall_s>  <turns>  <blocked>  <in>  <out>  <cache_read>  <cache_write>
#   R  <phase>  <start_epoch>  <end_epoch>  <done|active>      mỗi lần chạy, theo phase rồi theo giờ
#   B  <phase>  <epoch>                                         mỗi check chặn trong một lần chạy của phase
#   M  <current_phase>  <last_event_iso>  <máy,máy…>  <has_starts 0|1>  <has_main_turns 0|1>
# Thứ tự: mọi P (theo phases: của workflow.yaml), rồi R, rồi B, rồi M.

bay() { # <chuỗi> -> một dòng, không tab
  printf '%s' "$1" | tr '\t\r\n' '   ' | sed 's/  */ /g; s/^ //; s/ $//'
}
may_nay() { bay "${AW_JOURNAL_MACHINE:-$(uname -n 2>/dev/null || echo may)}"; }

# Hàm awk định dạng — dùng chung cho td_tg, td_tk và bảng của status.sh.
TD_AWK_DD='
function td_tg(s,  m, h) {
  if (s !~ /^[0-9]+$/) return "—"
  s += 0; if (s < 60) return s "s"
  m = int((s + 30) / 60); if (m < 60) return m "m"
  h = int(m / 60); m = m % 60
  return h "h" (m > 0 ? m "m" : "")
}
function td_tk(n,  k) {
  if (n !~ /^[0-9]+$/) return "—"
  n += 0; if (n < 1000) return n ""
  k = int(n / 1000 + 0.5); if (k < 1000) return k "k"
  return sprintf("%.1fM", n / 1000000)
}'

td_tg() { awk -v v="$1" "$TD_AWK_DD"' BEGIN { print td_tg(v) }'; }
td_tk() { awk -v v="$1" "$TD_AWK_DD"' BEGIN { print td_tk(v) }'; }

td_su_kien() {
  TD_CANH_BAO=0
  _td_f=$(basename "$(CDPATH= cd -- "$1" 2>/dev/null && pwd || echo "$1")")
  _td_m=$(may_nay | tr -d '<>')
  _td_j="${AW_CONFIG:-}/journal"
  _td_p=/dev/null; _td_t=/dev/null; _td_c=/dev/null
  if [ -f "$_td_j/phases.tsv" ]; then _td_p="$_td_j/phases.tsv"; fi
  if [ -f "$_td_j/turns.tsv" ]; then _td_t="$_td_j/turns.tsv"; fi
  if [ -f "$_td_j/checks.tsv" ]; then _td_c="$_td_j/checks.tsv"; fi
  awk -F'\t' -v OFS='\t' -v f="$_td_f" -v m="$_td_m" -v p="$_td_p" -v t="$_td_t" -v c="$_td_c" '
    { sub(/\r$/, "") }
    FILENAME == p && $3 == f { print "phases", m, $1, $4; next }
    FILENAME == t && $4 == f { print "turns", m, $1, $2, $5, $7, $8, $9, $10, $11, $12; next }
    FILENAME == c && $2 == f { print "checks", m, $1, $3, $4; next }
  ' "$_td_p" "$_td_t" "$_td_c"
  [ -f "$1/progress.md" ] || return 0
  # Khối của máy khác: giữ nguyên dòng; dòng của máy này đã lấy lại từ journal ở trên.
  if _td_k=$(awk -F'\t' -v m="$_td_m" '
      BEGIN { cot["phases"] = 4; cot["turns"] = 11; cot["checks"] = 5 }
      { sub(/\r$/, "") }
      !trong && $0 == "<!-- aw-progress v1" { trong = 1; co = 1; next }
      trong && $0 == "-->" { trong = 0; dong = 1; next }
      !trong { next }
      $0 == "" { next }
      !($1 in cot) || NF != cot[$1] { hong = 1; next }
      $2 != m { kq = kq $0 "\n" }
      END { if (hong || (co && !dong)) exit 1; printf "%s", kq }
    ' "$1/progress.md"); then
    if [ -n "$_td_k" ]; then printf '%s\n' "$_td_k"; fi
  else
    TD_CANH_BAO=1
  fi
}

td_tinh() {
  _td_wy="${AW_ENGINE:-${HERE:-.}/..}/workflow.yaml"
  _td_ds=$(wf_phases "$_td_wy" | cut -d'|' -f1 | tr '\n' ' ')
  _td_bo=0
  if kc_bo_design "$1"; then _td_bo=1; fi
  _td_tm=$(mktemp "${TMPDIR:-/tmp}/aw-td.XXXXXX" 2>/dev/null) || { _td_tm="${TMPDIR:-/tmp}/aw-td.$$"; true > "$_td_tm" 2>/dev/null || return 1; }
  td_su_kien "$1" > "$_td_tm"
  awk -F'\t' -v OFS='\t' -v ds="$_td_ds" -v bo="$_td_bo" '
    function ep(s,  y, m, d) {
      y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
      if (m <= 2) { y--; m += 12 }
      return ((365*y + int(y/4) - int(y/100) + int(y/400) + int((153*(m-3)+2)/5) + d - 719469) * 86400 \
              + substr(s, 12, 2)*3600 + substr(s, 15, 2)*60 + substr(s, 18, 2))
    }
    function iso(s) { return s ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/ }
    function moc(s) { if (iso(s) && s > cuoi) cuoi = s }
    function so(v) { return v ~ /^[0-9]+$/ }
    function cong(mang, k, v) { if (so(v)) mang[k] += v; else if (!(k in mang)) mang[k] = "" }
    { sub(/\r$/, "") }
    { may[$2] = 1 }
    $1 == "phases" && iso($3) { n++; bt[n] = ep($3); bp[n] = $4; moc($3); next }
    $1 == "turns" {
      moc($3); moc($4); ph = $5
      for (i = 8; i <= 11; i++) cong(tk, ph SUBSEP i, $i)
      if ($6 == "main") { luot[ph]++; co_luot = 1; if (so($7)) { gtt[ph] += $7; co_gtt[ph] = 1 } }
      next
    }
    $1 == "checks" && iso($3) { nc++; ct[nc] = ep($3); cp[nc] = $4; cx[nc] = $5; moc($3); next }
    END {
      # Sắp lần bắt đầu theo giờ (ổn định theo thứ tự đọc).
      for (i = 2; i <= n; i++) {
        t = bt[i]; p = bp[i]; j = i - 1
        while (j >= 1 && bt[j] > t) { bt[j+1] = bt[j]; bp[j+1] = bp[j]; j-- }
        bt[j+1] = t; bp[j+1] = p
      }
      ke = (cuoi != "") ? ep(cuoi) : 0
      for (i = 1; i <= n; i++) {
        kt[i] = (i < n) ? bt[i+1] : ke
        if (kt[i] < bt[i]) kt[i] = bt[i]
        chay[bp[i]] = 1; wall[bp[i]] += kt[i] - bt[i]; cuoi_bd[bp[i]] = bt[i]
      }
      hien = (n > 0) ? bp[n] : ""
      np = split(ds, ten, " ")
      for (k = 1; k <= np; k++) {
        p = ten[k]; xong = 0; chan[p] = ""
        for (i = 1; i <= nc; i++) {
          if (cp[i] != p) continue
          if (cx[i] == "0" && (!(p in cuoi_bd) || ct[i] >= cuoi_bd[p])) xong = 1
        }
        if (p in chay) {
          chan[p] = 0
          for (i = 1; i <= nc; i++) {
            if (cp[i] != p || cx[i] == "0") continue
            for (j = 1; j <= n; j++) if (bp[j] == p && ct[i] >= bt[j] && ct[i] <= kt[j]) { chan[p]++; nb++; bep[nb] = p; bet[nb] = ct[i]; break }
          }
        }
        if (p == "design" && bo == 1) tt[p] = "skipped"
        else if (xong) tt[p] = "done"
        else if (p == hien) tt[p] = "active"
        else tt[p] = "pending"
        dong = "P" OFS p OFS tt[p] OFS (co_gtt[p] ? gtt[p] : "") OFS ((p in chay) ? wall[p] : "") \
               OFS (luot[p] > 0 ? luot[p] : "") OFS chan[p]
        for (i = 8; i <= 11; i++) dong = dong OFS ((p SUBSEP i) in tk ? tk[p SUBSEP i] : "")
        print dong
      }
      for (k = 1; k <= np; k++) {
        p = ten[k]
        for (i = 1; i <= n; i++) if (bp[i] == p) print "R", p, bt[i], kt[i], ((i == n && tt[p] == "active") ? "active" : "done")
      }
      for (k = 1; k <= np; k++) for (i = 1; i <= nb; i++) if (bep[i] == ten[k]) print "B", ten[k], bet[i]
      nm = 0; for (x in may) if (x != "") { nm++; dm[nm] = x }
      for (i = 2; i <= nm; i++) { x = dm[i]; j = i - 1; while (j >= 1 && dm[j] > x) { dm[j+1] = dm[j]; j-- }; dm[j+1] = x }
      ms = ""; for (i = 1; i <= nm; i++) ms = ms (i > 1 ? "," : "") dm[i]
      print "M", hien, cuoi, ms, (n > 0 ? 1 : 0), (co_luot ? 1 : 0)
    }
  ' "$_td_tm" || { rm -f "$_td_tm"; return 1; }
  rm -f "$_td_tm"
}

# Chương trình awk dựng Markdown từ dòng td_tinh (ARGV[1]); che=file thêm phần còn lại của progress.md,
# ARGV[2] = sự kiện đã sắp (khối aw-progress v1). Ô không có dữ liệu = trống.
TD_AWK_MD='
function o(c, v) {
  if (v == "") return ""
  if (c == 4 || c == 5) return td_tg(v)
  if (c == 6 || c == 7) return v
  return td_tk(v)
}
function dong(a, b, x,  c, s) {
  s = "| " a " |" (b == "" ? " |" : " " b " |")
  for (c = 4; c <= 11; c++) s = s (x[c] == "" ? " |" : " " x[c] " |")
  return s
}
FILENAME == ARGV[1] && $1 == "P" {
  np++; ph[np] = $2; tt[np] = $3
  if ($3 != "pending" && $3 != "skipped") co_du = 1
  for (c = 4; c <= 11; c++) {
    v[np, c] = $c
    if ($c != "") { co_du = 1; tg[c] += $c; co[c] = 1 }
  }
  if ($8 + $9 > 0) { nk++; kp[nk] = $2; kv[nk] = sprintf("%.1f", ($8 + $9) / 1000) }
  next
}
FILENAME == ARGV[1] && $1 == "R" { nr++; rp[nr] = $2; rb[nr] = $3; re[nr] = $4; rk[nr] = $5; next }
FILENAME == ARGV[1] && $1 == "B" { nb++; bp[nb] = $2; be[nb] = $3; next }
FILENAME == ARGV[1] && $1 == "M" { hien = $2; cuoi = $3; may = $4; moc = $5; luot = $6; next }
FILENAME == ARGV[2] { ns++; sk[ns] = $0; next }
END {
  if (che == "bang" && !co_du) exit
  nhan["done"] = "✓ done"; nhan["active"] = "▶ active"; nhan["skipped"] = "— skipped"; nhan["pending"] = "· pending"
  if (che == "file") {
    gsub(/,/, ", ", may)
    print "# Progress — " viec
    print ""
    print "- Current phase: " (hien != "" ? "**" hien "**" : "—")
    print "- Updated: " (cuoi != "" ? substr(cuoi, 1, 10) " " substr(cuoi, 12, 5) " UTC" : "—")
    print "- Machines: " (may != "" ? may : "—")
    print ""
  }
  print "| Phase | Status | Active | Wall | Turns | Blocked checks | Tokens in | Tokens out | Cache read | Cache write |"
  print "|---|---|---|---|---|---|---|---|---|---|"
  for (i = 1; i <= np; i++) {
    for (c = 4; c <= 11; c++) x[c] = o(c, v[i, c])
    print dong(ph[i], nhan[tt[i]], x)
  }
  for (c = 4; c <= 11; c++) x[c] = co[c] ? o(c, tg[c] "") : ""
  print dong("**Total**", "", x)
  if (che != "file") exit
  print ""
  print "<!-- Active = tổng thời gian các lượt (prompt → agent dừng). Wall = từ lúc bắt đầu phase tới khi phase kế tiếp bắt đầu (phase đang làm: tới sự kiện cuối). -->"
  if (moc == 1 && luot == 0) {
    print ""
    print "> Chưa ghi được lượt nào — chỉ có cột Wall. Trên Claude Code, cài hook theo"
    print "> `adapters/claude-code/README.md` § Hook đo lượt và token."
  }
  if (nr > 0) {
    print ""
    print "```mermaid"
    print "gantt"
    print "  title Timeline"
    print "  dateFormat X"
    print "  axisFormat %d/%m %H:%M"
    for (i = 1; i <= np; i++) {
      p = ph[i]; dau = 1
      for (j = 1; j <= nr; j++) if (rp[j] == p) {
        if (dau) { print "  section " p; dau = 0 }
        print "  " p " :" rk[j] ", " rb[j] ", " re[j]
      }
      if (!dau) for (j = 1; j <= nb; j++) if (bp[j] == p) print "  blocked :milestone, crit, " be[j] ", " be[j]
    }
    print "```"
  }
  if (nk > 0) {
    print ""
    print "```mermaid"
    print "pie title Tokens by phase (k, in + out)"
    for (i = 1; i <= nk; i++) print "  \"" kp[i] "\" : " kv[i]
    print "```"
  }
  print ""
  print "<!-- aw-progress v1"
  for (i = 1; i <= ns; i++) print sk[i]
  print "-->"
}'

# _td_md <che: bang|file> <dir>
_td_md() {
  _td_mm=$(mktemp "${TMPDIR:-/tmp}/aw-tdm.XXXXXX" 2>/dev/null) || { _td_mm="${TMPDIR:-/tmp}/aw-tdm.$$"; true > "$_td_mm" 2>/dev/null || return 1; }
  _td_ms="$_td_mm.sk"
  td_tinh "$2" > "$_td_mm" || { rm -f "$_td_mm"; return 1; }
  _td_cb=$TD_CANH_BAO
  if [ "$1" = file ]; then td_su_kien "$2" | LC_ALL=C sort > "$_td_ms"; else true > "$_td_ms"; fi
  TD_CANH_BAO=$_td_cb
  awk -F'\t' -v che="$1" -v viec="$(basename "$(CDPATH= cd -- "$2" 2>/dev/null && pwd || echo "$2")")" \
    "$TD_AWK_DD$TD_AWK_MD" "$_td_mm" "$_td_ms"
  _td_kq=$?
  rm -f "$_td_mm" "$_td_ms"
  return $_td_kq
}
td_md_bang() { _td_md bang "$1"; }
td_md_file() { _td_md file "$1"; }
