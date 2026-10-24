#!/usr/bin/env sh
# Liệt kê kiến thức bền của repo đích mà một phase phải đọc.
#
#   aw knowledge spec|design|implement <thư-mục-feature>
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
# implement — đường dẫn suy từ "Expected files:" của plan.md (file có thật trên commit Base khớp
#   mẫu + tiền tố thư mục của mẫu, nên thư mục mới vẫn khớp; bỏ file test, thư mục ADR / luật):
#   ADR accepted, file luật, tài liệu module liên quan như design. Việc có design thì bỏ chỉ mục
#   ADR (design đã đọc); việc bỏ design (chore, skip) thì in chỉ mục ADR trước. Không có plan.md
#   hay không có Expected files → chỉ chỉ mục (nếu có).
# Đọc lúc chạy, không chép vào lệnh lúc build. Stdout là DỮ LIỆU; không in gì = không có.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/result.sh"
kq_khai knowledge.sh \
  "0=ĐÃ LIỆT KÊ — đọc từng file in ra (không in gì = repo chưa có durable knowledge liên quan)" \
  "2=SAI THAM SỐ"
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

BL_KIEN_THUC="spec design implement"
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
if [ "$PH" = implement ]; then
  if kc_bo_design "$DIR" && [ -f "$R/$TM/README.md" ]; then printf '%s\n' "$TM/README.md"; fi
  kt_duong_plan "$DIR" | kt_lay "$R" "$MT_CONV"
  exit 0
fi
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

printf '%s\n' "$DD" | kt_lay "$R" "$MT_CONV"
exit 0
