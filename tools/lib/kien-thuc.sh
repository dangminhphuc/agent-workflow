#!/usr/bin/env sh
# Kiểm chéo kiến thức bền ↔ diff: code trong phạm vi một tài liệu đổi mà tài liệu
# không đổi thì tài liệu có thể đã lỗi thời. Hay báo nhầm (sửa nhỏ không đổi luật),
# nên theo quy ước: implement CẢNH BÁO, review đòi verdict cho từng tài liệu bị ảnh
# hưởng ở mục "## Durable knowledge" — máy chỉ kiểm verdict có và hợp lệ.
#
# Tài liệu và phạm vi:
#   - tài liệu module (knowledge_files, mặc định */ARCHITECTURE.md): thư mục chứa nó;
#   - ADR accepted (knowledge_adr_dir): dòng "- Scope:";
#   - file luật (BR- active): hợp các "- Scope:" của luật active trong file.
# Diff không tính chính các tài liệu, thư mục ADR, thư mục luật.
#
# Cần nạp trước: tools/lib/md.sh, kiem-cheo.sh, sha256.sh, duyet.sh, adr.sh, luat.sh

# kt_tai_lieu <gốc repo> <conventions.md> -> "<file>|<glob phạm vi…>" mỗi tài liệu
kt_tai_lieu() {
  _kkf=$(conv_get "$2" knowledge_files); _kkf=${_kkf:-*/ARCHITECTURE.md}
  git -C "$1" ls-files --cached --others --exclude-standard 2>/dev/null | while IFS= read -r _kf; do
    case "$_kf" in .agent-workflow/*) continue ;; esac
    set -f
    # shellcheck disable=SC2086
    if khop_glob "$_kf" $_kkf; then set +f; printf '%s|%s/*\n' "$_kf" "$(dirname "$_kf")"; else set +f; fi
  done
  _ktm=$(adr_thu_muc "$2")
  adr_ds "$1/$_ktm" | while IFS= read -r _kf; do
    [ "$(adr_truong "$_kf" Status)" = accepted ] || continue
    _ksc=$(adr_truong "$_kf" Scope); [ -n "$_ksc" ] && printf '%s|%s\n' "${_kf#"$1"/}" "$_ksc"
  done
  luat_ds "$1" "$2" | awk -F'|' '$3 == "active" && $4 != "" { if (!($1 in s)) thu[++n] = $1; s[$1] = s[$1] " " $4 }
    END { for (i = 1; i <= n; i++) { v = s[thu[i]]; sub(/^ /, "", v); print thu[i] "|" v } }'
}

# kt_anh_huong <thư-mục-feature> -> "<tài liệu>|<1 nếu tài liệu đổi trong diff, 0 nếu không>|<file đổi trong phạm vi>"
kt_anh_huong() {
  _kr=$(kc_top "$1") || return 0
  _kc=$(qu_hieu_luc "${AW_REPO:-$_kr}")
  _kdoi=$(kc_doi "$1" 2>/dev/null | awk -F'\t' '{ print (NF > 2 ? $3 : $2) }') || return 0
  [ -n "$_kdoi" ] || return 0
  _kad=$(adr_thu_muc "$_kc"); _kld=$(luat_thu_muc "$_kc")
  _kds=$(kt_tai_lieu "$_kr" "$_kc")
  [ -n "$_kds" ] || return 0
  printf '%s\n' "$_kds" | while IFS='|' read -r _kf _ksc; do
    [ -n "$_kf" ] || continue
    _kvd=$(printf '%s\n' "$_kdoi" | while IFS= read -r _kp; do
      case "$_kp" in "$_kad"/*|"$_kld"/*) continue ;; esac
      printf '%s\n' "$_kds" | awk -F'|' -v p="$_kp" '$1 == p { f = 1 } END { exit !f }' && continue
      set -f
      # shellcheck disable=SC2086
      if khop_glob "$_kp" $_ksc; then set +f; printf '%s\n' "$_kp"; break; fi
      set +f
    done)
    [ -n "$_kvd" ] || continue
    if printf '%s\n' "$_kdoi" | grep -qxF "$_kf"; then printf '%s|1|%s\n' "$_kf" "$_kvd"
    else printf '%s|0|%s\n' "$_kf" "$_kvd"; fi
  done
}

# kt_canh_bao <thư-mục-feature> -> cảnh báo (implement): tài liệu bị ảnh hưởng mà không đổi
kt_canh_bao() {
  kt_anh_huong "$1" | while IFS='|' read -r _kf _kd _kvd; do
    [ "$_kd" = 0 ] && echo "kiến thức bền có thể lỗi thời: diff đụng $_kvd (phạm vi của $_kf) mà $_kf không đổi — cập nhật nó, hoặc review ghi verdict ở \"## Durable knowledge\""
  done
}

# kt_loi_review <thư-mục-feature> <review.md> -> lỗi: tài liệu bị ảnh hưởng thiếu verdict hợp lệ
# Verdict: pass (đã đọc, vẫn đúng) | updated (đã sửa trong diff) | not applicable (+ lý do).
kt_loi_review() {
  _kah=$(kt_anh_huong "$1"); [ -n "$_kah" ] || return 0
  _kbang=$(awk '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    { sub(/\r$/, "") }
    /^##[ \t]+Durable knowledge/ { trong = 1; co = 1; next }
    /^##[ \t]/ { trong = 0 }
    trong && /^[ \t]*\|/ {
      n = split($0, c, "|"); f = trim(c[2]); gsub(/`/, "", f)
      if (f == "" || f ~ /^:?-+:?$/ || f == "File") next
      print f "\t" trim(c[3]) "\t" (n >= 5 ? trim(c[4]) : "")
    }
    END { if (!co) print "\tKHÔNG CÓ MỤC" }
  ' "$2")
  if printf '%s\n' "$_kbang" | grep -q "	KHÔNG CÓ MỤC"; then
    echo "review.md thiếu mục \"## Durable knowledge\" — diff đụng phạm vi của: $(printf '%s\n' "$_kah" | cut -d'|' -f1 | tr '\n' ' ')— mỗi tài liệu một dòng verdict"
    return 0
  fi
  printf '%s\n' "$_kah" | while IFS='|' read -r _kf _kd _kvd; do
    _kdong=$(printf '%s\n' "$_kbang" | awk -F '	' -v f="$_kf" '$1 == f { print; exit }')
    _kkl=$(printf '%s' "$_kdong" | cut -f2); _kly=$(printf '%s' "$_kdong" | cut -f3)
    case "$_kkl" in
      "") echo "kiến thức bền \"$_kf\": không có verdict trong \"## Durable knowledge\" (diff đụng $_kvd)" ;;
      pass) ;;
      updated) [ "$_kd" = 1 ] || echo "kiến thức bền \"$_kf\": verdict \"updated\" nhưng diff không đổi file này" ;;
      "not applicable") case "$_kly" in ""|"<"*">") echo "kiến thức bền \"$_kf\": verdict \"not applicable\" mà thiếu lý do" ;; esac ;;
      *) echo "kiến thức bền \"$_kf\": verdict \"$_kkl\" không hợp lệ. Chỉ chấp nhận: pass / updated / not applicable" ;;
    esac
  done
}

# kt_luat_chua_test <thư-mục-feature> -> cảnh báo (implement): luật active có Scope bị diff
# đụng mà chưa test nào gắn tag covers ID đó
kt_luat_chua_test() {
  _kr=$(kc_top "$1") || return 0
  _kc=$(qu_hieu_luc "${AW_REPO:-$_kr}")
  _kdoi=$(kc_doi "$1" 2>/dev/null | awk -F'\t' '{ print (NF > 2 ? $3 : $2) }') || return 0
  [ -n "$_kdoi" ] || return 0
  _kphu=$(luat_duoc_phu "$_kr" "$_kc")
  luat_ds "$_kr" "$_kc" | while IFS='|' read -r _kf _kid _kst _ksc; do
    [ "$_kst" = active ] && [ -n "$_ksc" ] || continue
    printf '%s\n' "$_kphu" | grep -qxF "$_kid" && continue
    printf '%s\n' "$_kdoi" | while IFS= read -r _kp; do
      set -f
      # shellcheck disable=SC2086
      if khop_glob "$_kp" $_ksc; then set +f; echo "$_kid ($_kf): diff đụng $_kp trong phạm vi luật mà chưa test nào gắn tag covers $_kid"; break; fi
      set +f
    done
  done
}
