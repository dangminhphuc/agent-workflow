#!/usr/bin/env sh
# Phân loại tham số của /intake thành các dòng của mục "## Input" trong intake.md.
#
#   sh .agent-workflow/.quy-trinh/tools/phan-loai-input.sh [--tru <intake.md>] <tham-số>
#   sh .agent-workflow/.quy-trinh/tools/phan-loai-input.sh [--tru <intake.md>] - <<'HET_INPUT'
#   <tham-số, nguyên văn>
#   HET_INPUT
#
# Nhãn do MÁY gán theo luật cố định, không để agent đoán: agent đoán sai nhãn thì
# spec đi đọc sai chỗ, mà checker chỉ kiểm được cú pháp nhãn.
#
# Luật, cho từng token (tách theo khoảng trắng):
#   - khớp mau_jira                         -> [JIRA]
#   - URL có /browse/<mã khớp mau_jira>      -> [JIRA] <mã> — <URL>
#   - URL khớp mien_confluence               -> [CONFLUENCE]
#     (chưa khai mien_confluence: mọi URL còn lại -> [CONFLUENCE], kèm cảnh báo)
#   - file có thật trong repo                -> [FILE]
#   - trông như đường dẫn mà không có file   -> lỗi (mã 1), không tự đoán
#   - còn lại                                -> không nhận ra
# Có token KHÔNG NHẬN RA thì CẢ CHUỖI là lời người dùng: một mục [NGƯỜI-DÙNG]
# chép nguyên văn. Tách từng token sẽ biến một câu thành vài "input" rác và làm
# mất câu gốc. Nguồn nhận ra được trong câu chỉ là ĐỀ XUẤT (in ra stderr).
#
# --tru <intake.md>: bỏ các input đã có trong file đó (chạy lại /intake = gộp thêm).
# So theo định danh đã chuẩn hoá: ABC-1 và .../browse/ABC-1 là một nguồn.
#
# Stdout: đúng các dòng ghi vào "## Input" (rỗng = không có input mới).
# Stderr: giải thích, cảnh báo, đề xuất tách thêm.
# Mã thoát: 0 = các token đều là nguồn; 1 = có đường dẫn không tồn tại;
#           2 = sai cách gọi; 3 = không có tham số (hỏi người dùng);
#           4 = lời người dùng (stdout là mục [NGƯỜI-DÙNG] nguyên văn).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

# Script nằm ở <repo>/<artifact_dir>/.quy-trinh/tools/
ART_ABS=$(CDPATH= cd -- "$HERE/../.." && pwd)
CONV="$ART_ABS/conventions.md"
TOP=$(git -C "$ART_ABS" rev-parse --show-toplevel 2>/dev/null) || TOP=$(dirname "$ART_ABS")

TRU=""
if [ "${1:-}" = "--tru" ]; then
  [ -n "${2:-}" ] || { echo "LỖI: --tru cần đường dẫn intake.md" >&2; exit 2; }
  TRU="$2"; shift 2
  [ -f "$TRU" ] || { echo "LỖI: không tìm thấy $TRU" >&2; exit 2; }
fi
[ $# -le 1 ] || { echo "LỖI: truyền cả tham số thành MỘT đối số (đặt trong nháy), hoặc dùng \"-\" và đọc từ stdin." >&2; exit 2; }

if [ "${1:-}" = "-" ]; then VAN=$(cat); else VAN="${1:-}"; fi
# Bỏ dòng trống đầu/cuối (heredoc), giữ nguyên phần giữa.
VAN=$(printf '%s\n' "$VAN" | awk 'NF { if (!bd) bd = NR; kt = NR } { d[NR] = $0 } END { for (i = bd; i && i <= kt; i++) print d[i] }')
if [ -z "$(printf '%s' "$VAN" | tr -d ' \t\n\r')" ]; then
  echo "Không có tham số — hỏi người dùng input, rồi chạy lại với câu trả lời." >&2
  exit 3
fi

MJ=$(kc_mau_jira "$CONV")
MC=$(conv_get "$CONV" mien_confluence)
TMPD=$(mktemp -d 2>/dev/null) || { TMPD="${TMPDIR:-/tmp}/pli.$$"; mkdir -p "$TMPD"; }
trap 'rm -rf "$TMPD"' EXIT
: > "$TMPD/nguon"; : > "$TMPD/thieu"; : > "$TMPD/da-co"; : > "$TMPD/khoa"

la_jira() { printf '%s\n' "$1" | awk -v re="$MJ" '{ exit !($0 ~ ("^(" re ")$")) }'; }

# ma_browse <url> -> mã issue sau "/browse/" (rỗng nếu không có)
ma_browse() {
  printf '%s\n' "$1" | awk '{ i = index($0, "/browse/"); if (!i) exit; s = substr($0, i + 8); sub(/[\/?#].*$/, "", s); print s }'
}

giong_duong_dan() {
  case "$1" in
    */*|*.md|*.txt|*.pdf|*.doc|*.docx|*.log|*.json|*.yaml|*.yml|*.csv) return 0 ;;
  esac
  return 1
}

# Chuẩn hoá lời người dùng để so trùng: gộp khoảng trắng.
chuan_hoa() { printf '%s\n' "$1" | awk '{ $1 = $1; if (NF) { o = o (o == "" ? "" : " ") $0 } } END { print o }'; }

# ---- 1. Input đã có (--tru): khoá "NHÃN<TAB>định-danh" mỗi dòng ----
if [ -n "$TRU" ]; then
  awk -v re="$MJ" '
    function in_nv() { if (nv != "") print "NGƯỜI-DÙNG\t" nv; nv = ""; cho = 0 }
    { sub(/\r$/, "") }
    /^##[ \t]/ { if (vao) in_nv(); vao = ($0 ~ /^##[ \t]+Input/); next }
    !vao { next }
    /^[ \t]*-[ \t]/ {
      in_nv()
      if (!match($0, /\[[^]]+\]/)) next
      t = substr($0, RSTART + 1, RLENGTH - 2); r = substr($0, RSTART + RLENGTH)
      gsub(/<!--.*-->/, "", r); gsub(/`/, " ", r)
      if (t == "JIRA") {
        if (match(r, "(^|[^A-Za-z0-9])(" re ")([^A-Za-z0-9]|$)")) {
          s = substr(r, RSTART, RLENGTH); gsub(/^[^A-Za-z0-9]+|[^A-Za-z0-9]+$/, "", s); print "JIRA\t" s
        }
      } else if (t == "CONFLUENCE") {
        if (match(r, /https?:\/\/[^ \t)>]+/)) { s = substr(r, RSTART, RLENGTH); sub(/\/+$/, "", s); print "CONFLUENCE\t" s }
      } else if (t == "FILE") {
        n = split(r, a, /[ \t]+/); for (i = 1; i <= n; i++) if (a[i] != "") { s = a[i]; sub(/^\.\//, "", s); print "FILE\t" s; break }
      } else if (t == "NGƯỜI-DÙNG") {
        cho = 1; gsub(/^[ \t]+|[ \t]+$/, "", r); if (r != "") nv = r
      }
      next
    }
    cho && /^[ \t]*>/ { s = $0; sub(/^[ \t]*>[ \t]*/, "", s); if (s != "") nv = nv (nv == "" ? "" : " ") s; next }
    END { if (vao) in_nv() }
  ' "$TRU" | awk -F'\t' 'BEGIN { OFS = "\t" }
    $1 == "NGƯỜI-DÙNG" { v = $2; gsub(/[ \t]+/, " ", v); gsub(/^ | $/, "", v); $2 = v }
    { print }' > "$TMPD/da-co"
fi

# ---- 2. Phân loại từng token ----
# Mỗi nguồn: "NHÃN<TAB>khoá<TAB>dòng-ra" vào $TMPD/nguon.
n_khong=0; canh_bao_conf=0
set -f
for tk in $VAN; do
  set +f
  # Bỏ dấu câu / nháy / ngoặc bọc ngoài: "(ABC-1)," hay `docs/a.md` vẫn là nguồn.
  t=$(printf '%s' "$tk" | sed 's/^[`"'"'"'(<]*//; s/[`"'"'"')>,;.:]*$//')
  [ -n "$t" ] || { set -f; continue; }
  case "$t" in
    http://*|https://*)
      ma=$(ma_browse "$t")
      if [ -n "$ma" ] && la_jira "$ma"; then
        printf 'JIRA\t%s\t- `[JIRA]` %s — %s\n' "$ma" "$ma" "$t" >> "$TMPD/nguon"
      else
        u=$(printf '%s' "$t" | sed 's#/*$##'); con=${u#*://}; khop=0
        if [ -z "$MC" ]; then
          khop=1; canh_bao_conf=1
        else
          # Bỏ query/fragment trước khi so: mẫu "$p?*" từng khớp cả wiki.cty.vn.evil.com
          # (? của glob là một ký tự bất kỳ). set -f: mẫu có * không được nở thành tên file.
          con=${con%%[?#]*}
          set -f
          for p in $MC; do khop_glob "$con" "$p" "$p/*" && { khop=1; break; }; done
          set +f
        fi
        if [ "$khop" = 1 ]; then
          printf 'CONFLUENCE\t%s\t- `[CONFLUENCE]` %s\n' "$u" "$t" >> "$TMPD/nguon"
        else
          n_khong=$((n_khong + 1))
        fi
      fi ;;
    *)
      if la_jira "$t"; then
        printf 'JIRA\t%s\t- `[JIRA]` %s\n' "$t" "$t" >> "$TMPD/nguon"
      else
        p=${t#./}
        case "$p" in "$TOP"/*) p=${p#"$TOP"/} ;; esac
        if [ -f "$TOP/$p" ]; then
          printf 'FILE\t%s\t- `[FILE]` %s\n' "$p" "$p" >> "$TMPD/nguon"
        elif giong_duong_dan "$t"; then
          if [ -d "$TOP/$p" ]; then printf '%s (là thư mục, cần trỏ tới file)\n' "$t" >> "$TMPD/thieu"
          else printf '%s\n' "$t" >> "$TMPD/thieu"; fi
        else
          n_khong=$((n_khong + 1))
        fi
      fi ;;
  esac
  set -f
done
set +f

# in_nguon <file-nguồn> -> in dòng ra của nguồn chưa có (trong --tru hay trong lần gọi này)
in_nguon() {
  while IFS="$(printf '\t')" read -r nh kh dong; do
    k="$nh	$kh"
    grep -qxF "$k" "$TMPD/da-co" && { echo "  (đã có trong intake.md, bỏ qua: $nh $kh)" >&2; continue; }
    grep -qxF "$k" "$TMPD/khoa" && continue
    printf '%s\n' "$k" >> "$TMPD/khoa"
    printf '%s\n' "$dong"
  done < "$1"
}

# ---- 3. Lời người dùng: cả chuỗi là một mục [NGƯỜI-DÙNG] nguyên văn ----
# Token không nhận ra, hoặc đường dẫn không có file nằm lẫn trong câu chữ -> không
# chặn: đó là lời người dùng, không phải một nguồn gõ sai.
if [ "$n_khong" -gt 0 ]; then
  if grep -qxF "NGƯỜI-DÙNG	$(chuan_hoa "$VAN")" "$TMPD/da-co"; then
    echo "  (lời người dùng này đã có trong intake.md, bỏ qua)" >&2
  else
    printf -- '- `[NGƯỜI-DÙNG]`\n'
    printf '%s\n' "$VAN" | sed 's/^/  > /; s/[ \t]*$//'
  fi
  de_xuat=$(in_nguon "$TMPD/nguon" 2>/dev/null)
  echo "Tham số là lời người dùng — ghi nguyên văn, không tóm tắt, không sửa chính tả." >&2
  if [ -n "$de_xuat" ]; then
    echo "" >&2
    echo "Đề xuất tách thêm — CHỈ ghi vào \"## Input\" khi người xác nhận:" >&2
    printf '%s\n' "$de_xuat" >&2
  fi
  exit 4
fi

if [ -s "$TMPD/thieu" ]; then
  echo "LỖI: đường dẫn không tồn tại trong repo ($TOP):" >&2
  sed 's/^/  - /' "$TMPD/thieu" >&2
  echo "Hỏi lại người dùng đường dẫn đúng — không tự đoán." >&2
  exit 1
fi

ra=$(in_nguon "$TMPD/nguon")
[ -n "$ra" ] && printf '%s\n' "$ra"
[ "$canh_bao_conf" = 1 ] && echo "CẢNH BÁO: conventions.md chưa khai mien_confluence — mọi URL không phải Jira được coi là [CONFLUENCE]. Người kiểm lại." >&2
[ -z "$ra" ] && echo "Không có input mới." >&2
exit 0
