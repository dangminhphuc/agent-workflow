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

# ------------------------------------------------------------------ theo loại việc
# Loại việc có MỘT nguồn sự thật: dòng "Loại việc:" trong muc-dich.md.

LOAI_HOP_LE="feature bugfix refactor perf chore"

# kc_loai <thư-mục-feature> -> loại việc (rỗng nếu chưa có)
kc_loai() {
  [ -f "$1/muc-dich.md" ] || return 0
  awk '
    { sub(/\r$/, "") }
    /Loại việc[^:]*:/ {
      s = $0; sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s)
      gsub(/^[ \t]+|[ \t]+$/, "", s); print s; exit
    }
  ' "$1/muc-dich.md"
}

kc_top() { git -C "$1" rev-parse --show-toplevel 2>/dev/null; }

# kc_mb <thư-mục-feature> -> merge-base của HEAD với nhánh gốc
kc_mb() {
  _g=$(conv_get "$(kc_conventions "$1")" nhanh_goc); [ -n "$_g" ] || _g="main"
  git -C "$1" merge-base "$_g" HEAD 2>/dev/null
}

# kc_doi <thư-mục-feature> -> file thay đổi so với merge-base (kể cả chưa commit,
# chưa track), mỗi dòng "S<TAB>đường-dẫn[<TAB>đường-dẫn-mới]", S ∈ A M D R.
# Bỏ qua thư mục artifact. Mã 1 nếu không xác định được nhánh gốc.
kc_doi() {
  _top=$(kc_top "$1") || return 1
  _mb=$(kc_mb "$1") || return 1
  {
    git -C "$_top" -c core.quotepath=off diff --name-status -M "$_mb"
    git -C "$_top" -c core.quotepath=off ls-files --others --exclude-standard | awk '{ print "A\t" $0 }'
  } | awk -F'\t' '
    { s = substr($1, 1, 1); p = $2; q = (NF > 2 ? $3 : "") }
    p ~ /^\.agent-workflow\// && (q == "" || q ~ /^\.agent-workflow\//) { next }
    { print s "\t" p (q != "" ? "\t" q : "") }
  '
}

# kc_khop_khoa <thư-mục-feature> <khoá-conventions> <đường-dẫn> -> 0 nếu khớp
kc_khop_khoa() {
  _m=$(conv_get "$(kc_conventions "$1")" "$2")
  [ -n "$_m" ] || return 1
  set -f
  # shellcheck disable=SC2086
  khop_glob "$3" $_m; _r=$?
  set +f
  return $_r
}

# kc_bang_backtick <file> <tiêu-đề-mục> -> token trong backtick ở các dòng bảng của mục
kc_bang_backtick() {
  [ -f "$1" ] || return 0
  awk -v h="$2" '
    { sub(/\r$/, "") }
    /^##[ \t]/ { vao = (index($0, h) > 0); next }
    vao && /^[ \t]*\|/ { s = $0; while (match(s, /`[^`]+`/)) { print substr(s, RSTART+1, RLENGTH-2); s = substr(s, RSTART+RLENGTH) } }
  ' "$1"
}

# kc_loai_branch <thư-mục-feature>
# Loại việc lệch tiền tố branch (theo loai_theo_tien_to trong conventions.md).
# Không có ngoại lệ: phải sửa loại hoặc đổi tên branch (tools/doi-ten-feature.sh).
kc_loai_branch() {
  _l=$(kc_loai "$1"); [ -n "$_l" ] || return 0
  _b=$(git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null) || return 0
  for _cap in $(conv_get "$(kc_conventions "$1")" loai_theo_tien_to); do
    _tt=${_cap%%=*}; _lt=${_cap#*=}
    case "$_b" in
      "$_tt"*) [ "$_lt" = "$_l" ] || echo "muc-dich.md ghi loại \"$_l\" nhưng branch \"$_b\" mang tiền tố \"$_tt\" (= $_lt). Sửa loại, hoặc đổi tên branch bằng doi-ten-feature.sh"
               return 0 ;;
    esac
  done
}

# kc_test_cu_xoa <thư-mục-feature> — refactor/perf: xoá test cũ = bỏ hành vi -> chặn
kc_test_cu_xoa() {
  kc_doi "$1" | while IFS="$(printf '\t')" read -r _s _p _q; do
    [ "$_s" = "D" ] || continue
    kc_khop_khoa "$1" mau_file_test "$_p" && echo "$_p: test cũ bị xoá — refactor/perf không được xoá test cũ (xoá test = bỏ một hành vi)"
  done
}

# kc_test_cu_sua <thư-mục-feature> — refactor/perf: test cũ bị sửa/đổi tên mà chưa
# khai trong bảng "Test cũ bị sửa" của plan.md
kc_test_cu_sua() {
  _khai=$(kc_bang_backtick "$1/plan.md" "Test cũ bị sửa")
  kc_doi "$1" | while IFS="$(printf '\t')" read -r _s _p _q; do
    case "$_s" in M|R) ;; *) continue ;; esac
    kc_khop_khoa "$1" mau_file_test "$_p" || continue
    printf '%s\n' "$_khai" | grep -qxF "$_p" && continue
    echo "$_p: test cũ bị sửa nhưng chưa khai trong \"Test cũ bị sửa\" của plan.md (kèm lý do)"
  done
}

# kc_chore_production <thư-mục-feature> — chore đụng code production -> chặn
kc_chore_production() {
  kc_doi "$1" | while IFS="$(printf '\t')" read -r _s _p _q; do
    for _f in "$_p" $_q; do
      kc_khop_khoa "$1" mau_code_production "$_f" && echo "$_f: chore không được đụng code production (mau_code_production). Đây là việc loại khác — tách branch"
    done
  done | sort -u
}

# kc_chore_dependency <thư-mục-feature> — chore đụng file dependency mà plan.md thiếu
# bảng "Nâng dependency" hợp lệ; nâng major không được là chore.
kc_chore_dependency() {
  _co=$(kc_doi "$1" | while IFS="$(printf '\t')" read -r _s _p _q; do
    kc_khop_khoa "$1" mau_file_dependency "$_p" && echo "$_p"; done)
  [ -n "$_co" ] || return 0
  awk '
    { sub(/\r$/, "") }
    /^##[ \t]/ { vao = (index($0, "Nâng dependency") > 0); next }
    vao && /^[ \t]*\|/ {
      n = split($0, f, "|"); if (n < 5) next
      ten = f[2]; muc = f[n-1]
      gsub(/[ \t`*]/, "", ten); gsub(/^[ \t`*]+|[ \t`*]+$/, "", muc)
      if (ten == "" || ten ~ /^-+$/ || ten == "Thưviện" || ten ~ /^</) next
      dong++
      if (muc == "major") print ten ": nâng major không được là chore — tách sang branch refactor riêng"
      else if (muc != "vá" && muc != "minor") print ten ": mức \"" muc "\" không hợp lệ trong \"Nâng dependency\" (vá | minor)"
    }
    END { if (dong == 0) print "Diff đụng file dependency nhưng plan.md chưa có bảng \"Nâng dependency\" (thư viện, cũ → mới, mức vá | minor)" }
  ' "$1/plan.md" 2>/dev/null || echo "Diff đụng file dependency nhưng không có plan.md"
}

# kc_tai_hien <thư-mục-feature> — bugfix: phải có tai-hien.md do máy ghi, mã thoát ≠ 0
kc_tai_hien() {
  _t="$1/tai-hien.md"
  if [ ! -f "$_t" ]; then echo "Chưa có tai-hien.md — chạy kiem-tra-tai-hien.sh TRƯỚC khi sửa code"; return 0; fi
  grep -q 'Mã thoát: `0`' "$_t" && echo "tai-hien.md ghi test XANH trên code chưa sửa — test không tái hiện được lỗi"
  grep -q 'Mã thoát: `' "$_t" || echo "tai-hien.md không phải do kiem-tra-tai-hien.sh ghi (thiếu dòng mã thoát)"
}

# kc_hieu_nang <thư-mục-feature> — perf: phải có số đo trước và sau do máy ghi
kc_hieu_nang() {
  _t="$1/do-hieu-nang.md"
  if [ ! -f "$_t" ]; then echo "Chưa có do-hieu-nang.md — chạy kiem-tra-hieu-nang.sh --truoc (trước khi sửa) và --sau"; return 0; fi
  awk '
    { sub(/\r$/, "") }
    /^##[ \t]+Trước/ { sec = "truoc"; next }
    /^##[ \t]+Sau/   { sec = "sau"; next }
    /^##[ \t]/       { sec = "" }
    sec != "" && /^KET_QUA:/ { co[sec] = 1 }
    END {
      if (!co["truoc"]) print "do-hieu-nang.md thiếu số đo TRƯỚC khi sửa"
      if (!co["sau"])   print "do-hieu-nang.md thiếu số đo SAU khi sửa"
    }
  ' "$_t"
}

# kc_chan_theo_loai <thư-mục-feature> — luật CHÍNH XÁC theo loại việc: chặn ngay ở
# implement (và review). Mỗi dòng một vi phạm.
kc_chan_theo_loai() {
  case "$(kc_loai "$1")" in
    bugfix)   kc_tai_hien "$1" ;;
    refactor) kc_test_cu_xoa "$1" ;;
    perf)     kc_test_cu_xoa "$1"; kc_hieu_nang "$1" ;;
    chore)    kc_chore_production "$1"; kc_chore_dependency "$1" ;;
  esac
}

# kc_canh_bao_theo_loai <thư-mục-feature> — kiểm chéo theo loại việc: chỉ cảnh báo
# ở giữa flow, review chặn.
kc_canh_bao_theo_loai() {
  kc_loai_branch "$1"
  case "$(kc_loai "$1")" in
    refactor|perf) kc_test_cu_sua "$1" ;;
  esac
}
