#!/usr/bin/env sh
# Liệt kê kiến thức bền của repo đích mà một phase phải đọc.
#
#   aw knowledge spec|design|implement|review <thư-mục-feature>
#   aw knowledge show <ref>…     (ref = <file> hoặc <file>#<neo>; chạy ở gốc repo)
#   aw knowledge index           dựng lại file chỉ mục kiến thức chung (khoá knowledge_index)
#
# Mọi dòng in ra là ref: <file> hoặc <file>#<neo> (mục "##" khai Scope, hoặc ID luật BR-…).
# spec: mọi luật nghiệp vụ active (BR-), mỗi luật một ref — spec đối chiếu yêu cầu mới với luật
#   đang có; chưa có đường dẫn code để lọc nên in hết.
# design — in (mỗi dòng một đường dẫn tương đối với gốc repo):
#   - chỉ mục kiến thức chung (khoá knowledge_index, mặc định docs/knowledge-index.md, file đã
#     commit) — luôn, để thấy quyết định và luật đã có trước khi khảo sát code; chỉ mục chung
#     không có → chỉ mục ADR (<knowledge_adr_dir>/README.md);
#   - khi tdd.md đã có "## Existing code": ADR accepted có Scope khớp đường dẫn ghi ở
#     đó, và file khớp knowledge_files (mặc định */ARCHITECTURE.md) nằm ở thư mục cha
#     của đường dẫn đó — phạm vi của tài liệu module là thư mục chứa nó.
#   - file có luật active mà Scope khớp đường dẫn đó.
# implement — đường dẫn suy từ "Expected files:" của plan.md (file có thật trên commit Base khớp
#   mẫu + tiền tố thư mục của mẫu, nên thư mục mới vẫn khớp; bỏ file test, thư mục ADR / luật):
#   ADR accepted, file luật, tài liệu module liên quan như design. Chỉ mục chung (file đã commit)
#   thay chỉ mục ADR. Việc có design thì bỏ chỉ mục (design đã đọc); việc bỏ design (chore, skip)
#   thì in chỉ mục trước. Không có plan.md hay không có Expected files → chỉ chỉ mục (nếu có).
# review — tài liệu mà diff của việc đụng phạm vi (cột 1 của kt_anh_huong, đã khử trùng); chưa có diff
#   → không in gì.
# show — in từng ref, mỗi khối mở bằng dòng "==> <ref> <==". <file>#<neo>: một mục "##" của tài liệu
#   module (neo = heading) hoặc một luật (neo = ID BR-…). <file> của tài liệu có mục khai Scope: phần
#   ngoài các mục đó. Ref sai → SAI THAM SỐ, chưa in gì.
# index — dựng lại file chỉ mục kiến thức chung (khoá knowledge_index, mặc định
#   docs/knowledge-index.md; khoá khai trống = tắt) từ ADR, luật BR- và mục khai Scope của tài liệu
#   module: bảng "| Ref | Kind | Scope | Status | Summary |" do máy dựng, phần người viết phía trên
#   bảng giữ nguyên. In ra đường dẫn file đã dựng. Khoá tắt → SAI THAM SỐ.
# check [<thư-mục-feature>] — chỉ mục khớp dựng lại: bảng lệch → dòng lỗi, KHÔNG ĐẠT. Có thư mục:
#   chỉ kiểm khi diff đụng file chỉ mục hay tài liệu kiến thức; không đụng → ĐẠT. Khoá tắt hay file
#   chưa có → không kiểm.
# Đọc lúc chạy, không chép vào lệnh lúc build. Stdout là DỮ LIỆU; không in gì = không có.
#
# Result: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai knowledge.sh \
  "0=DONE — stdout là dữ liệu: ref đọc tiếp bằng aw knowledge show; aw knowledge index in đường dẫn file đã dựng; check ĐẠT" \
  "1=FAIL — aw knowledge check thấy chỉ mục lệch dựng lại: chạy aw knowledge index" \
  "2=BAD ARGS"
. "$HERE/lib/md.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/approval-tick.sh"
. "$HERE/lib/adr.sh"
. "$HERE/lib/quote.sh"
. "$HERE/lib/rule.sh"
. "$HERE/lib/cross-check.sh"
. "$HERE/lib/knowledge.sh"
. "$HERE/lib/env.sh"
mt_dat

BL_KIEN_THUC="spec design implement review"
PH="${1:-}"; DIR="${2:-}"
if [ "$PH" = show ]; then
  shift
  [ $# -gt 0 ] || { echo "Dùng: aw knowledge show <file>[#<neo>]…" >&2; exit 2; }
  for _ref in "$@"; do
    _f=${_ref%%#*}; _neo=""
    case "$_ref" in *"#"*) _neo=${_ref#*#} ;; esac
    if [ -z "$_f" ] || [ ! -f "$MT_REPO/$_f" ] || { case "$_ref" in *"#"*) ! kt_khoi "$MT_REPO/$_f" "$_neo" >/dev/null ;; (*) false ;; esac; }; then
      echo "LỖI: ref không tồn tại: $_ref" >&2; exit 2
    fi
  done
  for _ref in "$@"; do
    _f=${_ref%%#*}
    printf '==> %s <==\n' "$_ref"
    case "$_ref" in
      *"#"*) kt_khoi "$MT_REPO/$_f" "${_ref#*#}" ;;
      (*) if [ -n "$(kt_muc "$MT_REPO/$_f")" ]; then kt_phan_con "$MT_REPO/$_f"; else cat "$MT_REPO/$_f"; fi ;;
    esac
  done
  exit 0
fi
if [ "$PH" = index ]; then
  _cmk=$(kt_chi_muc_khoa "$MT_CONV"); _cmd=${_cmk%|*}; _cmt=${_cmk#*|}
  [ "$_cmt" = "0" ] && [ -n "$_cmd" ] || { echo "LỖI: khoá knowledge_index khai trống — chỉ mục tắt" >&2; exit 2; }
  kt_chi_muc_lai "$MT_REPO" "$MT_CONV" || { echo "LỖI: không dựng lại được chỉ mục" >&2; exit 2; }
  printf '%s\n' "$_cmd"
  exit 0
fi
if [ "$PH" = check ]; then
  # Khoá tắt → không kiểm gì (repo chưa tham gia). Err về KHÔNG ĐẠT khi bảng lệch chế độ dựng lại.
  _kmk=$(kt_chi_muc_khoa "$MT_CONV"); _kmd=${_kmk%|*}; _kmt=${_kmk#*|}
  [ "$_kmt" = "0" ] || exit 0
  if [ -n "$DIR" ] && [ "$DIR" != "" ]; then
    [ -d "$DIR" ] || { echo "LỖI: không có thư mục $DIR" >&2; exit 2; }
  fi
  _kmloi=$(kt_chi_muc_kiem "$MT_REPO" "$MT_CONV" "${DIR:-}")
  if [ -n "$_kmloi" ]; then printf '%s\n' "$_kmloi"; exit 1; fi
  exit 0
fi
case " $BL_KIEN_THUC " in *" $PH "*) [ -n "$PH" ] && [ -n "$DIR" ] ;; *) false ;; esac ||
  { echo "Dùng: aw knowledge <phase> <thư-mục-feature>   (phase: $BL_KIEN_THUC)   |   aw knowledge show <ref>…" >&2; exit 2; }
[ -d "$DIR" ] || { echo "LỖI: không có thư mục $DIR" >&2; exit 2; }

R=$MT_REPO
CM=$(kt_chi_muc_file "$R" "$MT_CONV")
if [ "$PH" = spec ]; then
  luat_ds "$R" "$MT_CONV" | awk -F'|' '$3 == "active" && !t[$1 "#" $2]++ { print $1 "#" $2 }'
  exit 0
fi
if [ "$PH" = review ]; then
  kt_anh_huong "$DIR" | awk -F"|" '$1 != "" && !t[$1]++ { print $1 }'
  exit 0
fi
TM=$(adr_thu_muc "$MT_CONV")
if [ "$PH" = implement ]; then
  if [ -n "$CM" ]; then printf '%s\n' "$CM"
  elif kc_bo_design "$DIR" && [ -f "$R/$TM/README.md" ]; then printf '%s\n' "$TM/README.md"; fi
  kt_duong_plan "$DIR" "$MT_CONV" | kt_lay "$R" "$MT_CONV"
  exit 0
fi
if [ -n "$CM" ]; then printf '%s\n' "$CM"
elif [ -f "$R/$TM/README.md" ]; then printf '%s\n' "$TM/README.md"; fi

# Đường dẫn có thật trong repo, ghi ở mục "## Existing code" của tdd.md.
DD=$( [ -f "$DIR/tdd.md" ] && awk '
  { sub(/\r$/, "") }
  /^##[ \t]+Existing code/ { trong = 1; next }
  /^##[ \t]/ { trong = 0 }
  trong {
    s = $0; gsub(/[`|,;()]/, " ", s)
    n = split(s, a, /[ \t]+/)
    for (i = 1; i <= n; i++) { t = a[i]; sub(/[.:]+$/, "", t); sub(/^\.\//, "", t); if (t ~ /\//) print t }
  }' "$DIR/tdd.md" | while IFS= read -r p; do
    p=${p%/}; [ -e "$R/$p" ] && printf '%s\n' "$p"
  done | sort -u)
[ -n "$DD" ] || exit 0

printf '%s\n' "$DD" | kt_lay "$R" "$MT_CONV"
exit 0
