#!/usr/bin/env sh
# Kiểm chéo giữa phase — dùng chung cho implement (cảnh báo) và review (chặn).
#
# Mỗi hàm in phát hiện, MỘT DÒNG MỘT PHÁT HIỆN, ra stdout. Không in gì = sạch.
# Hàm không tự quyết chặn hay cảnh báo: script gọi nó quyết định. Nhờ vậy cùng
# một logic cho ra "cảnh báo" ở giữa flow và "chặn" ở review — hai nơi không
# thể lệch nhau về việc thế nào là vi phạm.
#
# Yêu cầu: đã source tools/lib/md.sh.
#
# Thư mục feature có dạng <repo>/.agent-workflow/<tên-branch>; conventions.md
# nằm ở thư mục cha của nó.

# kc_conventions <thư-mục-feature> -> đường dẫn conventions.md
kc_conventions() {
  printf '%s/../conventions.md\n' "$1"
}

# kc_loi_thoi <thư-mục-feature>
# Artifact nào có based_on mà hash đầu vào đã đổi -> lỗi thời.
kc_loi_thoi() {
  for _a in "$1"/*.md; do
    [ -f "$_a" ] || continue
    _an=$(basename "$_a")
    fm_list "$_a" based_on | while IFS= read -r _b; do
      [ -n "$_b" ] || continue
      _in=${_b%@*}; _cu=${_b##*@}
      if [ ! -f "$1/$_in" ]; then
        echo "$_an: dựa trên $_in nhưng file này không còn"
        continue
      fi
      _moi=$(file_hash "$1/$_in")
      [ "$_cu" = "$_moi" ] || echo "$_an: lỗi thời — $_in đã đổi sau khi $_an được viết (chạy lại phase sinh ra $_an)"
    done
  done
}

# kc_test_yc <thư-mục-feature>
# YC nào chưa có test gắn tag, chưa ghi "Kiểm chứng thủ công", chưa hoãn lại.
kc_test_yc() {
  _d="$1"; _conv=$(kc_conventions "$_d")
  [ -f "$_d/spec.md" ] || return 0
  _top=$(git -C "$_d" rev-parse --show-toplevel 2>/dev/null) || {
    echo "Không kiểm được test ↔ YC: thư mục không nằm trong git repo"; return 0; }
  _mau=$(conv_get "$_conv" mau_file_test)
  _tag=$(conv_get "$_conv" the_covers); [ -n "$_tag" ] || _tag="covers:"
  if [ -z "$_mau" ]; then
    echo "Không kiểm được test ↔ YC: conventions.md chưa khai mau_file_test"; return 0
  fi

  _ds="${TMPDIR:-/tmp}/kc-test.$$"
  : > "$_ds"
  set -f
  git -C "$_top" ls-files --cached --others --exclude-standard | while IFS= read -r _f; do
    # shellcheck disable=SC2086
    khop_glob "$_f" $_mau && printf '%s\n' "$_f"
  done > "$_ds.files"
  set +f
  while IFS= read -r _f; do
    [ -f "$_top/$_f" ] && grep -F "$_tag" "$_top/$_f" 2>/dev/null
  done < "$_ds.files" > "$_ds"

  awk -v tag="$_tag" '
    { sub(/\r$/, "") }
    FNR==1 { idx++; sect="" }
    idx==1 {                                   # dòng chứa tag trong file test
      s=$0; i=index(s, tag); if (i==0) next
      s=substr(s, i + length(tag))
      while (match(s, /YC-[0-9]+/)) { co_test[substr(s, RSTART, RLENGTH)]=1; s=substr(s, RSTART+RLENGTH) }
      next
    }
    idx==2 && /^###[ \t]+YC-[0-9]+/ { match($0, /YC-[0-9]+/); ds[++n]=substr($0, RSTART, RLENGTH); next }
    idx==3 && /^##[ \t]+Kiểm chứng thủ công/ { sect="tc"; next }
    idx==3 && /^##[ \t]+Hoãn lại/            { sect="hl"; next }
    idx==3 && /^##[ \t]/                     { sect=""; next }
    idx==3 && sect!="" && /^[ \t]*\|/ && /YC-[0-9]+/ {
      split($0, f, "|"); ly=f[3]; gsub(/^[ \t]+|[ \t]+$/, "", ly)
      match($0, /YC-[0-9]+/); c=substr($0, RSTART, RLENGTH)
      if (ly != "" && ly !~ /^<.*>$/) ngoai_le[c]=sect
    }
    END {
      for (i=1; i<=n; i++) {
        c=ds[i]
        if (!(c in co_test) && !(c in ngoai_le))
          print c ": chưa có test gắn \"" tag " " c "\", cũng không ghi ở \"Kiểm chứng thủ công\" của plan.md"
      }
    }
  ' "$_ds" "$_d/spec.md" "$_d/plan.md" 2>/dev/null
  rm -f "$_ds" "$_ds.files"
}

# kc_pham_vi <thư-mục-feature>
# File thay đổi so với nhánh gốc mà không nằm trong "File dự kiến" hay
# "Phát sinh" của plan.md, và không thuộc danh sách bỏ qua.
kc_pham_vi() {
  _d="$1"; _conv=$(kc_conventions "$_d")
  [ -f "$_d/plan.md" ] || return 0
  _top=$(git -C "$_d" rev-parse --show-toplevel 2>/dev/null) || {
    echo "Không kiểm được phạm vi diff: thư mục không nằm trong git repo"; return 0; }
  _goc=$(conv_get "$_conv" nhanh_goc); [ -n "$_goc" ] || _goc="main"
  _mb=$(git -C "$_top" merge-base "$_goc" HEAD 2>/dev/null) || {
    echo "Không kiểm được phạm vi diff: không tìm thấy nhánh gốc \"$_goc\" (khai nhanh_goc trong conventions.md)"; return 0; }
  _bo=$(conv_get "$_conv" bo_qua)

  # Mẫu được phép: token trong backtick ở dòng "File dự kiến:" và mục "Phát sinh".
  _cho=$(awk '
    { sub(/\r$/, "") }
    /^##[ \t]+Phát sinh/ { ps=1; next }
    /^##[ \t]/           { ps=0 }
    ps==1 || /File dự kiến:/ {
      s=$0
      while (match(s, /`[^`]+`/)) { print substr(s, RSTART+1, RLENGTH-2); s=substr(s, RSTART+RLENGTH) }
    }
  ' "$_d/plan.md")

  set -f
  { git -C "$_top" diff --name-only "$_mb"; git -C "$_top" ls-files --others --exclude-standard; } \
    | sort -u | while IFS= read -r _f; do
      [ -n "$_f" ] || continue
      case "$_f" in .agent-workflow/*) continue ;; esac
      # shellcheck disable=SC2086
      khop_glob "$_f" $_bo && continue
      # shellcheck disable=SC2086
      khop_glob "$_f" $_cho && continue
      echo "$_f: thay đổi ngoài phạm vi — không có trong \"File dự kiến\" hay \"Phát sinh\" của plan.md"
    done
  set +f
}
