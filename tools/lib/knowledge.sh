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
# Cần nạp trước: tools/lib/md.sh, cross-check.sh, sha256.sh, approval-tick.sh, adr.sh, rule.sh

# kt_muc <file|-> -> mỗi mục "##" khai Scope một dòng: "<neo>\t<dòng đầu>\t<dòng cuối>\t<glob…>".
# Neo = heading đã bỏ "## " và khoảng trắng hai đầu. Scope = dòng không trống đầu tiên dưới heading.
# Mục kéo tới heading "#"/"##" kế tiếp, hoặc hết file. "-" đọc stdin.
kt_muc() {
  awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function xong(c) { if (neo != "" && co) print neo "\t" dau "\t" c "\t" glob; neo = ""; co = 0 }
    { sub(/\r$/, "") }
    /^#[ \t]/ || /^##[ \t]/ {
      xong(NR - 1)
      if ($0 ~ /^##[ \t]/) { neo = trim(substr($0, 3)); dau = NR; cho = 1; glob = ""; co = 0 }
      next
    }
    neo != "" && cho && $0 !~ /^[ \t]*$/ {
      cho = 0
      if ($0 ~ /^[ \t]*-[ \t]*Scope:/) { g = $0; sub(/^[ \t]*-[ \t]*Scope:/, "", g); gsub(/`/, "", g); glob = trim(g); gsub(/[ \t]+/, " ", glob); co = 1 }
    }
    END { xong(NR) }
  ' "$1"
}

# kt_khoi <file|-> <neo> -> in khối; mã 1 khi không có. Neo "BR-…": heading "### BR-…:" tới heading "#"…"###"
# kế tiếp; neo khác: heading "##" khớp nguyên văn (đã trim), mục trùng lấy mục đầu, tới heading "#"/"##" kế tiếp.
kt_khoi() {
  KT_NEO="$2" awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    BEGIN { neo = ENVIRON["KT_NEO"]; luat = (neo ~ /^BR-/) }
    { sub(/\r$/, "") }
    trong && (/^#[ \t]/ || /^##[ \t]/ || (luat && /^###[ \t]/)) { exit }
    !trong && !da {
      if (luat ? index($0, "### " neo ":") == 1 : ($0 ~ /^##[ \t]/ && trim(substr($0, 3)) == neo)) { trong = 1; da = 1 }
    }
    trong { print; n++ }
    END { exit (n > 0 ? 0 : 1) }
  ' "$1"
}

# kt_phan_con <file|-> -> in file trừ các khối mà kt_muc liệt kê (giữ nguyên từng byte phần còn lại).
kt_phan_con() {
  awk '
    function xa() { if (!co) for (i = 1; i <= m; i++) print buf[i]; m = 0; co = 0 }
    { raw = $0; sub(/\r$/, "") }
    /^#[ \t]/ || /^##[ \t]/ {
      xa(); trongmuc = ($0 ~ /^##[ \t]/); cho = trongmuc
      buf[++m] = raw; next
    }
    {
      if (trongmuc && cho && $0 !~ /^[ \t]*$/) { cho = 0; if ($0 ~ /^[ \t]*-[ \t]*Scope:/) co = 1 }
      buf[++m] = raw
    }
    END { xa() }
  ' "$1"
}

# kt_lay <gốc repo> <conventions.md> -> kiến thức bền liên quan tới các đường dẫn ở stdin
# (mỗi dòng một, tương đối với gốc repo, có thể chưa tồn tại): ADR accepted có Scope khớp,
# file có luật active khớp, tài liệu module (knowledge_files) có thư mục là cha của đường dẫn.
# Đường dẫn là thư mục có thật → khớp thêm "<p>/x". In ref: "<file>" (ADR, tài liệu module có đường dẫn
# trong thư mục), "<file>#<neo>" (mục khai Scope khớp), "<file>#<BR-ID>" (luật active khớp). Mỗi ref một lần.
kt_lay() {
  _kldd=$(cat)
  [ -n "$_kldd" ] || return 0
  _kltm=$(adr_thu_muc "$2")
  {
    adr_ds "$1/$_kltm" | while IFS= read -r _klf; do
      [ "$(adr_truong "$_klf" Status)" = accepted ] || continue
      _klsc=$(adr_truong "$_klf" Scope); [ -n "$_klsc" ] || continue
      printf '%s\n' "$_kldd" | while IFS= read -r _klp; do
        [ -n "$_klp" ] || continue
        set -f
        # shellcheck disable=SC2086
        if khop_glob "$_klp" $_klsc || { [ -d "$1/$_klp" ] && khop_glob "$_klp/x" $_klsc; }; then set +f; printf '%s\n' "${_klf#"$1"/}"; break; fi
        set +f
      done
    done

    luat_ds "$1" "$2" | while IFS='|' read -r _klf _klid _klst _klsc; do
      [ "$_klst" = active ] && [ -n "$_klsc" ] || continue
      printf '%s\n' "$_kldd" | while IFS= read -r _klp; do
        [ -n "$_klp" ] || continue
        set -f
        # shellcheck disable=SC2086
        if khop_glob "$_klp" $_klsc || { [ -d "$1/$_klp" ] && khop_glob "$_klp/x" $_klsc; }; then set +f; printf '%s#%s\n' "$_klf" "$_klid"; break; fi
        set +f
      done
    done

    _klkf=$(conv_get "$2" knowledge_files); _klkf=${_klkf:-*/ARCHITECTURE.md}
    git -C "$1" ls-files 2>/dev/null | while IFS= read -r _klf; do
      tm_bo "$_klf" && continue
      set -f
      # shellcheck disable=SC2086
      khop_glob "$_klf" $_klkf || { set +f; continue; }
      set +f
      kt_muc "$1/$_klf" | while IFS='	' read -r _klneo _kla _klb _klg; do
        printf '%s\n' "$_kldd" | while IFS= read -r _klp; do
          [ -n "$_klp" ] || continue
          set -f
          # shellcheck disable=SC2086
          if khop_glob "$_klp" $_klg || { [ -d "$1/$_klp" ] && khop_glob "$_klp/x" $_klg; }; then set +f; printf '%s#%s\n' "$_klf" "$_klneo"; break; fi
          set +f
        done
      done
      _kld=$(dirname "$_klf")
      printf '%s\n' "$_kldd" | while IFS= read -r _klp; do
        case "$_klp/" in "$_kld"/*) printf '%s\n' "$_klf"; break ;; esac
      done
    done
  } | awk '!t[$0]++'
}

# kt_duong_plan <thư-mục-feature> <conventions.md> -> đường dẫn suy từ "Expected files:" của plan.md (khử trùng, sắp xếp).
# Token không glob → chính nó. Token có glob → file trên commit Base khớp mau_ere(token, 0) VÀ tiền tố
# thư mục trước ký tự glob đầu (bỏ "/" cuối; rỗng thì bỏ). Thiếu sha Base → kc_mb; không có commit →
# chỉ tiền tố (thư mục mới chưa có trên base vẫn khớp). Bỏ file test, thư mục ADR / luật, thư mục việc.
kt_duong_plan() {
  [ -f "$1/plan.md" ] || return 0
  _kpsha=$(intake_base_dong "$1" | awk '{ print $2 }')
  [ -n "$_kpsha" ] || _kpsha=$(kc_mb "$1" 2>/dev/null)
  _kptop=$(git_top "$1" 2>/dev/null)
  if [ -n "$_kpsha" ] && [ -n "$_kptop" ] && git -C "$_kptop" cat-file -e "$_kpsha^{commit}" 2>/dev/null; then
    _kpcay=$(git -C "$_kptop" -c core.quotepath=off ls-tree -r --name-only "$_kpsha")
  else _kpcay=""; fi
  _kpadr=$(adr_thu_muc "$2"); _kplt=$(luat_thu_muc "$2"); _kptf=$(conv_get "$2" test_files)
  # chỉ token "Expected files" dưới heading task (kc_token_plan: loại E, task khác rỗng), bỏ cột loại + task
  { printf '%s\n' "$_kpcay"; printf '\001\n'; kc_token_plan "$1/plan.md" | awk -F '\t' '$1 == "E" && $2 != ""' | cut -f3-; } \
    | awk "$MAU_ERE_AWK"'
    function tien_to(m,   i, c) {
      i = match(m, /[*?[]/); if (i == 0) return m
      c = substr(m, 1, i - 1); if (c !~ /\//) return ""
      sub(/\/[^\/]*$/, "", c); return c
    }
    !pl && $0 == "\001" { pl = 1; next }
    !pl { if ($0 != "") cay[++nc] = $0; next }
    {
      m = $0
      if (m !~ /[*?[]/) { print m; next }
      pre = tien_to(m); if (pre != "") print pre
      re = mau_ere(m, 0)
      for (i = 1; i <= nc; i++) if (cay[i] ~ re && (pre == "" || index(cay[i], pre "/") == 1)) print cay[i]
    }' | sort -u | while IFS= read -r _kpp; do
      [ -n "$_kpp" ] || continue
      _kpp=${_kpp#./}; _kpp=${_kpp%/}
      tm_bo "$_kpp" && continue
      case "$_kpp/" in "$_kpadr"/*|"$_kplt"/*) continue ;; esac
      if [ -n "$_kptf" ]; then
        set -f
        # shellcheck disable=SC2086
        if khop_glob "$_kpp" $_kptf || khop_glob "$_kpp/x" $_kptf; then set +f; continue; fi
        set +f
      fi
      printf '%s\n' "$_kpp"
    done
}

# kt_tai_lieu <gốc repo> <conventions.md> -> "<ref>|<glob phạm vi…>": tài liệu module (mục khai Scope →
# "<file>#<neo>|<glob mục>" mỗi mục, cộng "<file>|<thư mục>/*"), ADR "<file>|<Scope>", luật "<file>#<BR-ID>|<Scope>".
kt_tai_lieu() {
  _kkf=$(conv_get "$2" knowledge_files); _kkf=${_kkf:-*/ARCHITECTURE.md}
  git -C "$1" ls-files --cached --others --exclude-standard 2>/dev/null | while IFS= read -r _kf; do
    tm_bo "$_kf" && continue
    set -f
    # shellcheck disable=SC2086
    if khop_glob "$_kf" $_kkf; then
      set +f
      kt_muc "$1/$_kf" | while IFS='	' read -r _kneo _kda _kcu _kg; do printf '%s#%s|%s\n' "$_kf" "$_kneo" "$_kg"; done
      printf '%s|%s/*\n' "$_kf" "$(dirname "$_kf")"
    else set +f; fi
  done
  _ktm=$(adr_thu_muc "$2")
  adr_ds "$1/$_ktm" | while IFS= read -r _kf; do
    [ "$(adr_truong "$_kf" Status)" = accepted ] || continue
    _ksc=$(adr_truong "$_kf" Scope); [ -n "$_ksc" ] && printf '%s|%s\n' "${_kf#"$1"/}" "$_ksc"
  done
  luat_ds "$1" "$2" | awk -F'|' '$3 == "active" && $4 != "" { print $1 "#" $2 "|" $4 }'
}

# kt_dong_doi <thư-mục-feature> <file> -> số dòng (trên cây làm việc) mà diff so với merge-base thêm/sửa,
# từ "git diff -U0"; hunk chỉ xoá ghi số dòng kề sau chỗ xoá.
kt_dong_doi() {
  _kdt=$(kc_top "$1") || return 0
  _kdm=$(kc_mb "$1") || return 0
  git -C "$_kdt" -c core.quotepath=off diff -U0 "$_kdm" -- "$2" 2>/dev/null | awk '
    /^@@/ {
      s = $3; sub(/^\+/, "", s); n = split(s, a, ","); c = a[1] + 0; d = (n > 1 ? a[2] + 0 : 1)
      if (d == 0) print c + 1; else for (i = c; i < c + d; i++) print i
    }'
}

# kt_dai <file|-> <neo> -> "<dòng đầu> <dòng cuối>" của khối (như kt_khoi); không có thì không in gì.
kt_dai() {
  KT_NEO="$2" awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    BEGIN { neo = ENVIRON["KT_NEO"]; luat = (neo ~ /^BR-/) }
    { sub(/\r$/, "") }
    trong && (/^#[ \t]/ || /^##[ \t]/ || (luat && /^###[ \t]/)) { cuoi = NR - 1; trong = 0 }
    !trong && !da {
      if (luat ? index($0, "### " neo ":") == 1 : ($0 ~ /^##[ \t]/ && trim(substr($0, 3)) == neo)) { trong = 1; da = 1; dau = NR }
    }
    END { if (da) print dau " " (trong ? NR : cuoi) }
  ' "$1"
}

# kt_tai_lieu_base <gốc repo> <conventions.md> <sha> -> "<ref>|<glob>" của các mục khai Scope (tài liệu module)
# và luật active trên commit <sha> — để mục / luật bị đổi tên hay xoá trong diff vẫn cần verdict.
kt_tai_lieu_base() {
  _kbkf=$(conv_get "$2" knowledge_files); _kbkf=${_kbkf:-*/ARCHITECTURE.md}; _kblt=$(luat_thu_muc "$2")
  git -C "$1" -c core.quotepath=off ls-tree -r --name-only "$3" 2>/dev/null | while IFS= read -r _kbf; do
    tm_bo "$_kbf" && continue
    _kbm=""; _kbl=""
    set -f
    # shellcheck disable=SC2086
    khop_glob "$_kbf" $_kbkf && _kbm=1
    set +f
    case "$_kbf" in "$_kblt"/*.md) _kbl=1 ;; esac
    [ -n "$_kbm$_kbl" ] || continue
    if [ -n "$_kbm" ]; then
      git -C "$1" show "$3:$_kbf" | kt_muc - | while IFS='	' read -r _kbn _kba _kbb _kbg; do printf '%s#%s|%s\n' "$_kbf" "$_kbn" "$_kbg"; done
    fi
    git -C "$1" show "$3:$_kbf" | awk -v f="$_kbf" '
      function xong() { if (id != "" && st == "active" && sc != "") print f "#" id "|" sc; id = "" }
      { sub(/\r$/, "") }
      /^###[ \t]+BR-/ { xong(); s = $0; sub(/^###[ \t]+/, "", s); sub(/[: \t].*$/, "", s); id = s; st = ""; sc = ""; next }
      /^##/ { xong(); next }
      id != "" && /^[-*][ \t]*Status:/ { v = $0; sub(/^[^:]*:[ \t]*/, "", v); gsub(/`/, "", v); st = v }
      id != "" && /^[-*][ \t]*Scope:/  { v = $0; sub(/^[^:]*:[ \t]*/, "", v); gsub(/`/, "", v); sc = v }
      END { xong() }'
  done
}

# kt_anh_huong <thư-mục-feature> -> "<ref>|<0|1>|<file đổi trong phạm vi>". Tập ref = ref trên cây làm việc
# hợp ref trên merge-base. Cột 2: ref "<file>" → 1 khi file đổi; ref "<file>#<neo>" → 1 khi khối có ở cả
# hai bên và diff đổi dòng trong khối (kt_dong_doi), hoặc neo chỉ có ở một bên (đổi tên / thêm / xoá).
kt_anh_huong() {
  _kr=$(kc_top "$1") || return 0
  _kc=$(qu_hieu_luc "${AW_REPO:-$_kr}")
  _kdoi=$(kc_doi "$1" 2>/dev/null | awk -F'\t' '{ print (NF > 2 ? $3 : $2) }') || return 0
  [ -n "$_kdoi" ] || return 0
  _kmb=$(kc_mb "$1" 2>/dev/null)
  _kad=$(adr_thu_muc "$_kc"); _kld=$(luat_thu_muc "$_kc")
  _kds=$({ kt_tai_lieu "$_kr" "$_kc"; [ -n "$_kmb" ] && kt_tai_lieu_base "$_kr" "$_kc" "$_kmb"; } | awk -F'|' '!t[$1]++')
  [ -n "$_kds" ] || return 0
  printf '%s\n' "$_kds" | while IFS='|' read -r _kf _ksc; do
    [ -n "$_kf" ] || continue
    _kvd=$(printf '%s\n' "$_kdoi" | while IFS= read -r _kp; do
      # "(" mở đầu pattern: bash 3.2 (sh của macOS) đọc ")" của pattern trong $(…) là dấu đóng $(.
      case "$_kp" in ("$_kad"/*|"$_kld"/*) continue ;; esac
      printf '%s\n' "$_kds" | awk -F'|' -v p="$_kp" '{ x = $1; sub(/#.*/, "", x) } x == p { f = 1 } END { exit !f }' && continue
      set -f
      # shellcheck disable=SC2086
      if khop_glob "$_kp" $_ksc; then set +f; printf '%s\n' "$_kp"; break; fi
      set +f
    done)
    [ -n "$_kvd" ] || continue
    _kff=${_kf%%#*}; _kd=0
    case "$_kf" in
      (*"#"*)
        _kneo=${_kf#*#}
        _kdw=""; [ -f "$_kr/$_kff" ] && _kdw=$(kt_dai "$_kr/$_kff" "$_kneo")
        _kdb=""; [ -n "$_kmb" ] && _kdb=$(git -C "$_kr" show "$_kmb:$_kff" 2>/dev/null | kt_dai - "$_kneo")
        if [ -z "$_kdw" ] || [ -z "$_kdb" ]; then _kd=1
        else
          _ka=${_kdw% *}; _kb=${_kdw#* }
          kt_dong_doi "$1" "$_kff" | awk -v a="$_ka" -v b="$_kb" '$1 >= a + 0 && $1 <= b + 0 { f = 1 } END { exit !f }' && _kd=1
        fi ;;
      (*) printf '%s\n' "$_kdoi" | grep -qxF "$_kff" && _kd=1 ;;
    esac
    printf '%s|%s|%s\n' "$_kf" "$_kd" "$_kvd"
  done
}

# kt_canh_bao <thư-mục-feature> -> cảnh báo (implement): ref bị ảnh hưởng mà không đổi
kt_canh_bao() {
  kt_anh_huong "$1" | while IFS='|' read -r _kf _kd _kvd; do
    [ "$_kd" = 0 ] || continue
    case "$_kf" in
      (*"#"*) echo "durable knowledge có thể stale: diff đụng $_kvd (phạm vi của $_kf) mà khối $_kf không đổi — cập nhật nó, hoặc review ghi verdict ở \"## Durable knowledge\"" ;;
      (*) echo "durable knowledge có thể stale: diff đụng $_kvd (phạm vi của $_kf) mà $_kf không đổi — cập nhật nó, hoặc review ghi verdict ở \"## Durable knowledge\"" ;;
    esac
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
    _kdong=$(printf '%s\n' "$_kbang" | KT_REF="$_kf" awk -F '	' '$1 == ENVIRON["KT_REF"] { print; exit }')
    _kkl=$(printf '%s' "$_kdong" | cut -f2); _kly=$(printf '%s' "$_kdong" | cut -f3)
    case "$_kkl" in
      "") echo "durable knowledge \"$_kf\": không có verdict trong \"## Durable knowledge\" (diff đụng $_kvd)" ;;
      pass) ;;
      updated) [ "$_kd" = 1 ] || case "$_kf" in (*"#"*) echo "durable knowledge \"$_kf\": verdict \"updated\" nhưng diff không đổi dòng nào trong khối này" ;; (*) echo "durable knowledge \"$_kf\": verdict \"updated\" nhưng diff không đổi file này" ;; esac ;;
      "not applicable") case "$_kly" in ""|"<"*">") echo "durable knowledge \"$_kf\": verdict \"not applicable\" mà thiếu lý do" ;; esac ;;
      *) echo "durable knowledge \"$_kf\": verdict \"$_kkl\" không hợp lệ. Chỉ chấp nhận: pass / updated / not applicable" ;;
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
