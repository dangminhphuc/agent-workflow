#!/usr/bin/env sh
# Kiểm chéo giữa phase — dùng chung cho implement (cảnh báo) và review (chặn).
#
# Mỗi hàm in phát hiện, MỘT DÒNG MỘT PHÁT HIỆN, ra stdout. Không in gì = sạch.
# Hàm không tự quyết chặn hay cảnh báo: script gọi nó quyết định. Nhờ vậy cùng
# một logic cho ra "cảnh báo" ở giữa flow và "chặn" ở review — hai nơi không
# thể lệch nhau về việc thế nào là vi phạm.
#
# Yêu cầu: đã source tools/lib/md.sh (và tools/lib/bang-lenh.sh nếu dùng kc_quy_tac_*).
#
# Thư mục feature có dạng <repo>/.agent-workflow/<tên-branch>. conventions.md và
# config.sh nằm trong $AW_CONFIG (cấu hình của bản clone, wrapper aw truyền vào).
if [ -z "${AW_CONFIG:-}" ]; then
  echo "LỖI: thiếu AW_CONFIG — chạy qua wrapper aw (vd: aw check spec <thư-mục-feature>)." >&2
  exit 9
fi

# kc_conventions <thư-mục-feature> -> đường dẫn conventions.md
kc_conventions() {
  printf '%s/conventions.md\n' "$AW_CONFIG"
}

# kc_cau_hinh <thư-mục-feature> -> đường dẫn config.sh (LENH_KIEM_THU…)
kc_cau_hinh() {
  printf '%s/config.sh\n' "$AW_CONFIG"
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
    # Theo tên file: khi chưa test nào gắn tag, file đầu 0 byte — đếm FNR==1 sẽ
    # đọc spec.md như file test và kiểm chéo im lặng đúng lúc tệ nhất.
    FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : (FILENAME == ARGV[2]) ? 2 : 3; sect="" }
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
# File thay đổi so với base của việc mà không nằm trong "File dự kiến" hay
# "Phát sinh" của plan.md, và không thuộc danh sách bỏ qua.
kc_pham_vi() {
  _d="$1"; _conv=$(kc_conventions "$_d")
  [ -f "$_d/plan.md" ] || return 0
  _top=$(git -C "$_d" rev-parse --show-toplevel 2>/dev/null) || {
    echo "Không kiểm được phạm vi diff: thư mục không nằm trong git repo"; return 0; }
  _mb=$(kc_mb "$_d") || {
    echo "Không kiểm được phạm vi diff: không tìm thấy base \"$(kc_base "$_d")\" (dòng Base: trong intake.md, hoặc nhanh_goc trong conventions.md)"; return 0; }
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
# Loại việc có MỘT nguồn sự thật: dòng "- **Type:**" trong intake.md.

LOAI_HOP_LE="feature bugfix refactor perf chore"

# kc_mau_jira <conventions.md> -> regex (ERE, không dùng {n}: mawk không hỗ trợ)
# của mã issue Jira. Repo cài từ trước chưa có khoá này -> mặc định.
kc_mau_jira() {
  _mj=$(conv_get "$1" mau_jira)
  printf '%s\n' "${_mj:-[A-Z][A-Z0-9]*-[0-9]+}"
}

# kc_loai <thư-mục-feature> -> loại việc (rỗng nếu chưa có)
kc_loai() {
  [ -f "$1/intake.md" ] || return 0
  awk '
    { sub(/\r$/, "") }
    /^[ \t]*-[ \t]+\*\*Type:\*\*/ {
      s = $0; sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s)
      gsub(/^[ \t]+|[ \t]+$/, "", s); print s; exit
    }
  ' "$1/intake.md"
}

# kc_spec_chua_duyet <thư-mục-feature> -> in lý do nếu spec.md chưa được NGƯỜI duyệt
# ("Status: approved" trong spec.md). Dùng làm cổng vào phase ngay sau spec.
kc_spec_chua_duyet() {
  [ -f "$1/spec.md" ] || return 0
  _tt=$(awk '
    { sub(/\r$/, "") }
    /^[ \t]*-[ \t]*\**Status\**:/ {
      s = $0; sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s)
      gsub(/^[ \t]+|[ \t]+$/, "", s); print s; exit
    }
  ' "$1/spec.md")
  [ "$_tt" = "approved" ] || echo "spec.md chưa được người duyệt (Status: ${_tt:-?}). Người đọc spec rồi tự đổi sang \"đã duyệt\"."
}

kc_top() { git -C "$1" rev-parse --show-toplevel 2>/dev/null; }

# kc_engine_dong <thư-mục-feature> -> version ghi ở dòng "Engine:" của intake.md
# (bỏ backtick, comment; không có dòng thì không in gì). Mọi `aw check` của việc
# chạy đúng version này — xem bin/aw.
kc_engine_dong() {
  [ -f "$1/intake.md" ] || return 0
  awk '
    { sub(/\r$/, "") }
    /^[ \t]*-[ \t]*\*\*Engine:\*\*/ || /^[ \t]*-?[ \t]*Engine:/ {
      s = $0; sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*` \t]/, "", s); print s; exit
    }
  ' "$1/intake.md"
}

# kc_base_dong <thư-mục-feature> -> "<ref> <sha>" từ dòng "Base:" của intake.md
# (thiếu phần nào thì phần đó rỗng; không có dòng Base thì không in gì).
kc_base_dong() {
  [ -f "$1/intake.md" ] || return 0
  awk '
    { sub(/\r$/, "") }
    /^[ \t]*-[ \t]*\*\*Base:\*\*/ || /^[ \t]*-?[ \t]*Base:/ {
      s = $0; sub(/^[^:]*:/, "", s); r = ""; h = ""
      if (match(s, /`[^`]+`/)) { r = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) }
      if (match(s, /`[^`]+`/)) { h = substr(s, RSTART + 1, RLENGTH - 2) }
      print r " " h; exit
    }
  ' "$1/intake.md"
}

# kc_base <thư-mục-feature> -> ref để so diff: base NGƯỜI chọn lúc tạo worktree
# (dòng "Base:" của intake.md). Ref không còn (vd branch cha đã xoá) thì dùng sha
# ghi kèm. intake.md cũ chưa có dòng Base thì quay về nhanh_goc.
# So với nhanh_goc khi base là origin/main hay release/* sẽ quy commit không
# thuộc việc này cho việc này — phạm vi diff sai, review đọc code không phải của mình.
kc_base() {
  set -- "$1" $(kc_base_dong "$1")
  if [ -n "${2:-}" ] && git -C "$1" rev-parse --verify --quiet "$2^{commit}" >/dev/null; then echo "$2"; return 0; fi
  if [ -n "${3:-}" ] && git -C "$1" rev-parse --verify --quiet "$3^{commit}" >/dev/null; then echo "$3"; return 0; fi
  _g=$(conv_get "$(kc_conventions "$1")" nhanh_goc); echo "${_g:-main}"
}

# kc_mb <thư-mục-feature> -> merge-base của HEAD với base của việc
kc_mb() {
  git -C "$1" merge-base "$(kc_base "$1")" HEAD 2>/dev/null
}

# kc_base_la <thư-mục-feature> -> in cảnh báo nếu base không phải nhánh gốc
# (local hay origin/) hoặc nhánh phát hành. Vd xếp chồng lên branch việc khác:
# review dựa trên code chưa được review. Chỉ cảnh báo — người xác nhận có chủ ý.
kc_base_la() {
  set -- "$1" $(kc_base_dong "$1")
  [ -n "${2:-}" ] || return 0
  _conv=$(kc_conventions "$1")
  _g=$(conv_get "$_conv" nhanh_goc); _g=${_g:-main}
  _b=${2#origin/}
  [ "$_b" = "$_g" ] && return 0
  set -f
  for _m in $(conv_get "$_conv" mau_nhanh_phat_hanh); do
    case "$_b" in $_m) set +f; return 0 ;; esac
  done
  set +f
  echo "Base \"$2\" không phải nhánh gốc ($_g) hay nhánh phát hành (mau_nhanh_phat_hanh). Nếu là branch việc khác (xếp chồng): việc này dựa trên code chưa được review — người xác nhận đây là chủ ý"
}

# kc_doi <thư-mục-feature> -> file thay đổi so với merge-base (kể cả chưa commit,
# chưa track), mỗi dòng "S<TAB>đường-dẫn[<TAB>đường-dẫn-mới]", S ∈ A M D R.
# Bỏ qua thư mục artifact. Mã 1 nếu không xác định được base.
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
      "$_tt"*) [ "$_lt" = "$_l" ] || echo "intake.md ghi loại \"$_l\" nhưng branch \"$_b\" mang tiền tố \"$_tt\" (= $_lt). Sửa loại, hoặc đổi tên branch bằng aw rename <tên-mới>"
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
  if [ ! -f "$_t" ]; then echo "Chưa có tai-hien.md — chạy aw check repro <thư-mục-feature> TRƯỚC khi sửa code"; return 0; fi
  grep -q 'Mã thoát: `0`' "$_t" && echo "tai-hien.md ghi test XANH trên code chưa sửa — test không tái hiện được lỗi"
  grep -q 'Mã thoát: `' "$_t" || echo "tai-hien.md không phải do kiem-tra-tai-hien.sh ghi (thiếu dòng mã thoát)"
}

# kc_hieu_nang <thư-mục-feature> — perf: phải có số đo trước và sau do máy ghi
kc_hieu_nang() {
  _t="$1/do-hieu-nang.md"
  if [ ! -f "$_t" ]; then echo "Chưa có do-hieu-nang.md — chạy aw check perf <thư-mục-feature> --before (trước khi sửa) và --after"; return 0; fi
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

# ------------------------------------------------------------------ điểm mù
# Ba mức chặn của một điểm mù ([OPEN-QUESTION]) — người duyệt nhãn ở gate spec:
#   chặn         sai thì cả thiết kế đổi hướng   → chặn phase ngay sau spec (design; chore: plan)
#   chặn review  sai thì làm lại một phần code   → flow đi tiếp trên giả định tạm; review chặn
#   không chặn   sai thì sửa nhỏ                 → giao được; review ghi YC đó "chờ xác nhận"

MUC_CHAN_HOP_LE="chặn|chặn review|không chặn"

# kc_diem_mu <thư-mục-feature> -> mỗi mục trong open-questions.md một dòng
# "<mã>|<mức chặn>|<trạng thái>". Thiếu dòng Mức chặn thì mức rỗng.
kc_diem_mu() {
  [ -s "$1/open-questions.md" ] || return 0
  awk '
    function gia_tri(s) { sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    { sub(/\r$/, "") }
    /^##[ \t]+YC-[0-9]+/ { if (q != "") print q "|" m "|" t; match($0, /YC-[0-9]+/); q = substr($0, RSTART, RLENGTH); m = ""; t = "mở"; next }
    /^##?[ \t]/ { if (q != "") print q "|" m "|" t; q = ""; next }
    q != "" && /^[ \t]*-[ \t]*[*]*Mức chặn[^:]*:/  { m = gia_tri($0) }
    q != "" && /^[ \t]*-[ \t]*[*]*Trạng thái[^:]*:/ { t = gia_tri($0) }
    END { if (q != "") print q "|" m "|" t }
  ' "$1/open-questions.md"
}

# kc_diem_mu_mo <thư-mục-feature> <mức...> -> điểm mù CÒN MỞ thuộc các mức đã cho.
# Gọi với "chặn" làm cổng vào design (chore: plan); với "chặn" + "chặn review"
# ở implement (cảnh báo) và review (chặn).
kc_diem_mu_mo() {
  _dm_d="$1"; shift
  kc_diem_mu "$_dm_d" | while IFS='|' read -r _q _m _t; do
    [ "$_t" = "đã trả lời" ] && continue
    for _w in "$@"; do
      [ "$_m" = "$_w" ] || continue
      case "$_m" in
        chặn) echo "$_q: điểm mù mức \"chặn\" chưa trả lời — sai giả định thì cả thiết kế đổi hướng. Giải quyết trước (lệnh clarify dẫn dắt việc này)" ;;
        *)    echo "$_q: điểm mù mức \"$_m\" chưa trả lời — review chặn tới khi có câu trả lời (lệnh clarify dẫn dắt việc này)" ;;
      esac
    done
  done
}

# ------------------------------------------------------------------ quy tắc riêng của repo
# Khoá quy_tac_<phase> trong conventions.md: danh sách file (tương đối với gốc
# repo, cách nhau bằng dấu cách) mà phase đó phải đọc và tuân theo — hướng dẫn
# viết code, skill của agent, chuẩn kiến trúc… Phase có khoá: BL_QUY_TAC
# (tools/lib/bang-lenh.sh — người gọi source trước).
#
# Nội dung quy tắc do agent đọc; máy chỉ kiểm phần chính xác: file khai có thật,
# đã commit (worktree mới chỉ có file đã commit), và review có kết luận cho từng file.

# kc_quy_tac <thư-mục-feature> <phase> -> mỗi dòng một file, bỏ trùng, giữ thứ tự.
# review = hợp MỌI khoá quy_tac_*: cổng cuối đối chiếu diff với mọi quy tắc.
kc_quy_tac() {
  awk -v ph="$2" '
    { sub(/\r$/, "") }
    /^```conventions[ \t]*$/ { inb = 1; next }
    inb == 1 && /^```/ { exit }
    inb == 1 && /^quy_tac_[a-z]+:/ {
      k = $0; sub(/:.*/, "", k); sub(/^quy_tac_/, "", k)
      if (ph != "review" && k != ph) next
      v = $0; sub(/^[^:]*:/, "", v)
      n = split(v, ds, /[ \t]+/)
      for (i = 1; i <= n; i++) if (ds[i] != "" && !(ds[i] in da)) { da[ds[i]] = 1; print ds[i] }
    }
  ' "$(kc_conventions "$1")" 2>/dev/null
}

# kc_quy_tac_khoa_la <thư-mục-feature> -> khoá quy_tac_<x> mà <x> không phải phase
# có quy tắc (gõ nhầm thì phase không bao giờ đọc file đó).
kc_quy_tac_khoa_la() {
  awk '
    { sub(/\r$/, "") }
    /^```conventions[ \t]*$/ { inb = 1; next }
    inb == 1 && /^```/ { exit }
    inb == 1 && /^quy_tac_[^:]*:/ { k = $0; sub(/:.*/, "", k); print k }
  ' "$(kc_conventions "$1")" 2>/dev/null | while IFS= read -r _k; do
    case " $BL_QUY_TAC " in
      *" ${_k#quy_tac_} "*) ;;
      *) echo "conventions.md: khoá \"$_k\" không ứng với phase nào (có: $(printf 'quy_tac_%s ' $BL_QUY_TAC | sed 's/ $//'))" ;;
    esac
  done
}

# kc_quy_tac_loi <thư-mục-feature> <phase> -> file quy tắc khai mà không dùng được.
kc_quy_tac_loi() {
  _top=$(kc_top "$1")
  kc_quy_tac "$1" "$2" | while IFS= read -r _f; do
    case "$_f" in
      /*|..|../*|*/..|*/../*)
        echo "quy tắc repo \"$_f\": phải là đường dẫn tương đối, nằm trong repo — sửa khoá quy_tac_* trong conventions.md"
        continue ;;
    esac
    if [ ! -f "$_top/$_f" ]; then
      echo "quy tắc repo \"$_f\": không có file này trong repo — sửa khoá quy_tac_* trong conventions.md"
    elif git -C "$_top" ls-files --error-unmatch -- "$_f" >/dev/null 2>&1; then
      :
    elif git -C "$_top" check-ignore -q -- "$_f" 2>/dev/null; then
      # vd /.claude/ — aw init exclude cả thư mục file adapter sinh ra
      echo "quy tắc repo \"$_f\": git đang bỏ qua file này ($(git -C "$_top" check-ignore -v -- "$_f" 2>/dev/null | cut -f1)) — commit bằng git add -f vào base, hoặc đặt nó ở thư mục khác"
    else
      echo "quy tắc repo \"$_f\": chưa commit — worktree khác và người rà soát không có file này; commit nó vào base"
    fi
  done
}
