#!/usr/bin/env sh
# Liệt kê kiến thức bền của repo đích mà một phase phải đọc.
#
#   aw knowledge spec|design <thư-mục-feature>
#
# spec: mọi file có luật nghiệp vụ active (BR-) — spec đối chiếu yêu cầu mới với luật
#   đang có; chưa có đường dẫn code để lọc nên in hết.
# design — in (mỗi dòng một đường dẫn tương đối với gốc repo):
#   - chỉ mục ADR (<knowledge_adr_dir>/README.md) — luôn, để thấy quyết định đã có
#     trước khi khảo sát code;
#   - khi tdd.md đã có "## Existing code": ADR accepted có Scope khớp đường dẫn ghi ở
#     đó, và file khớp knowledge_files (mặc định */ARCHITECTURE.md) nằm ở thư mục cha
#     của đường dẫn đó — phạm vi của tài liệu module là thư mục chứa nó.
#   - file có luật active mà Scope khớp đường dẫn đó.
# Đọc lúc chạy, không chép vào lệnh lúc build. Stdout là DỮ LIỆU; không in gì = không có.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai knowledge.sh \
  "0=ĐÃ LIỆT KÊ — đọc từng file in ra (không in gì = repo chưa có kiến thức bền liên quan)" \
  "2=SAI THAM SỐ"
. "$HERE/lib/md.sh"
. "$HERE/lib/sha256.sh"
. "$HERE/lib/approval-tick.sh"
. "$HERE/lib/adr.sh"
. "$HERE/lib/rule.sh"
. "$HERE/lib/env.sh"
mt_dat

BL_KIEN_THUC="spec design"
PH="${1:-}"; DIR="${2:-}"
case " $BL_KIEN_THUC " in *" $PH "*) [ -n "$PH" ] && [ -n "$DIR" ] ;; *) false ;; esac ||
  { echo "Dùng: aw knowledge <phase> <thư-mục-feature>   (phase: $BL_KIEN_THUC)" >&2; exit 2; }
[ -d "$DIR" ] || { echo "LỖI: không có thư mục $DIR" >&2; exit 2; }

R=$MT_REPO
if [ "$PH" = spec ]; then
  luat_ds "$R" "$MT_CONV" | awk -F'|' '$3 == "active" && !t[$1]++ { print $1 }'
  exit 0
fi
TM=$(adr_thu_muc "$MT_CONV")
[ -f "$R/$TM/README.md" ] && printf '%s\n' "$TM/README.md"

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

# Một file có thể khớp nhiều cách (tài liệu module chứa luật) — in một lần.
{
  # ADR accepted có Scope khớp (thư mục: khớp một file giả bên trong nó).
  adr_ds "$R/$TM" | while IFS= read -r f; do
    [ "$(adr_truong "$f" Status)" = accepted ] || continue
    sc=$(adr_truong "$f" Scope); [ -n "$sc" ] || continue
    printf '%s\n' "$DD" | while IFS= read -r p; do
      set -f
      # shellcheck disable=SC2086
      if khop_glob "$p" $sc || { [ -d "$R/$p" ] && khop_glob "$p/x" $sc; }; then set +f; printf '%s\n' "${f#"$R"/}"; break; fi
      set +f
    done
  done

  # Luật nghiệp vụ active có Scope khớp.
  printf '%s\n' "$DD" | luat_lien_quan "$R" "$MT_CONV"

  # Tài liệu module: file đã commit khớp knowledge_files, thư mục chứa nó là cha của đường dẫn.
  KF=$(conv_get "$MT_CONV" knowledge_files); KF=${KF:-*/ARCHITECTURE.md}
  git -C "$R" ls-files 2>/dev/null | while IFS= read -r f; do
    set -f
    # shellcheck disable=SC2086
    khop_glob "$f" $KF || { set +f; continue; }
    set +f
    d=$(dirname "$f")
    printf '%s\n' "$DD" | while IFS= read -r p; do
      case "$p/" in "$d"/*) printf '%s\n' "$f"; break ;; esac
    done
  done
} | awk '!t[$0]++'
exit 0
