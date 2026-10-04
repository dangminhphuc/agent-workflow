#!/usr/bin/env sh
# Đề xuất / tạo worktree cho một việc — dùng ở /intake. Worktree là BẮT BUỘC:
# checkout chính chỉ đứng ở nhánh gốc, mỗi việc một worktree, một phiên agent.
#
#   sh .agent-workflow/.quy-trinh/tools/tao-worktree.sh <loại-việc> <mô-tả>                  # chỉ in đề xuất
#   sh .agent-workflow/.quy-trinh/tools/tao-worktree.sh <loại-việc> <mô-tả> --tao --goc <ref> # tạo (sau khi NGƯỜI chọn)
#
# Agent KHÔNG chọn base. Script liệt kê ứng viên kèm dữ kiện (commit, chậm/nhanh
# so với remote, có bộ cài chưa) và gợi ý ★ theo MỘT luật máy: giữa nhanh_goc và
# origin/nhanh_goc, bản nào chứa bản kia thì gợi ý bản đó; phân kỳ thì không gợi ý.
# NGƯỜI chọn, agent chạy lại với --goc <ref>. Script không tự fetch.
#
# Tên: tiền tố theo loai_theo_tien_to + <mô-tả>. Branch, thư mục worktree và thư
# mục artifact dùng CÙNG một tên. Vị trí: thu_muc_worktree trong conventions.md
# (mặc định ../{repo}.wt/{ten}); biến môi trường AW_THU_MUC_WORKTREE ghi đè theo máy.
#
# Branch mới tạo --no-track: tạo từ origin/main mà để git tự đặt upstream thì
# "git push" trơn trong worktree sẽ đẩy thẳng lên main.
#
# Stdout: đề xuất (không --tao) hoặc đường dẫn worktree (--tao).
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai tao-worktree.sh \
  "0=XONG — đã in đề xuất, hoặc đã tạo worktree" \
  "2=KHÔNG HỢP LỆ — tham số hoặc trạng thái, lý do in phía trên" \
  "5=ĐÃ CÓ WORKTREE — stdout là đường dẫn, mở phiên ở đó"
. "$HERE/lib/md.sh"
. "$HERE/lib/worktree.sh"

# Script nằm ở <repo>/<artifact_dir>/.quy-trinh/tools/
ART_ABS=$(CDPATH= cd -- "$HERE/../.." && pwd)
ART=$(basename "$ART_ABS")
CONV="$ART_ABS/conventions.md"
CH="$ART_ABS/.quy-trinh/cau-hinh.sh"

LOAI="${1:-}"; MOTA="${2:-}"
[ $# -ge 2 ] && shift 2 || shift $#
TAO=""; GOC=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tao) TAO=1 ;;
    --goc) [ $# -ge 2 ] || { echo "LỖI: --goc cần một ref." >&2; exit 2; }; GOC="$2"; shift ;;
    *) echo "LỖI: tham số lạ \"$1\" (chỉ nhận --tao, --goc <ref>)" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$LOAI" ] && [ -n "$MOTA" ] || { echo "Dùng: sh tao-worktree.sh <loại-việc> <mô-tả> [--tao --goc <ref>]" >&2; exit 2; }
case "$MOTA" in
  *[!a-z0-9-]*|-*|*-) echo "LỖI: mô tả \"$MOTA\" phải là chữ thường ASCII, số và \"-\", không bắt đầu/kết thúc bằng \"-\" (vd phi-hoan-tien)." >&2; exit 2 ;;
esac
[ -z "$GOC" ] || [ -n "$TAO" ] || { echo "LỖI: --goc chỉ dùng cùng --tao." >&2; exit 2; }

tien_to=""
for _cap in $(conv_get "$CONV" loai_theo_tien_to); do
  [ "${_cap#*=}" = "$LOAI" ] && { tien_to=${_cap%%=*}; break; }
done
if [ -z "$tien_to" ]; then
  echo "LỖI: loại việc \"$LOAI\" không có tiền tố trong loai_theo_tien_to ($CONV)." >&2
  echo "      Loại hợp lệ: feature | bugfix | refactor | perf | chore." >&2
  exit 2
fi

TEN="$tien_to$MOTA"
TEN_TM=$(printf '%s' "$TEN" | tr '/' '_')
git -C "$ART_ABS" check-ref-format --branch "$TEN" >/dev/null 2>&1 || { echo "LỖI: \"$TEN\" không phải tên branch hợp lệ." >&2; exit 2; }

CHINH=$(wt_chinh "$ART_ABS") || { echo "LỖI: $ART_ABS không nằm trong git repo." >&2; exit 2; }
REPO=$(basename "$CHINH")
GOC_MD=$(conv_get "$CONV" nhanh_goc); GOC_MD=${GOC_MD:-main}
MAU_PH=$(conv_get "$CONV" mau_nhanh_phat_hanh)
MAU_TM=$(conv_get "$CONV" thu_muc_worktree); NGUON_TM="thu_muc_worktree"
[ -n "$MAU_TM" ] || { MAU_TM='../{repo}.wt/{ten}'; NGUON_TM="mặc định"; }
[ -n "${AW_THU_MUC_WORKTREE:-}" ] && { MAU_TM="$AW_THU_MUC_WORKTREE"; NGUON_TM="AW_THU_MUC_WORKTREE — ghi đè theo máy"; }

DUONG=$(printf '%s' "$MAU_TM" | awk -v r="$REPO" -v t="$TEN_TM" '{ gsub(/\{repo\}/, r); gsub(/\{ten\}/, t); print }')
case "$DUONG" in /*) ;; *) DUONG="$CHINH/$DUONG" ;; esac
DUONG=$(wt_chuan_hoa "$DUONG")
case "$DUONG/" in
  "$CHINH"/*) echo "LỖI: \"$DUONG\" nằm TRONG repo — tool quét trùng code và agent đọc nhầm artifact của worktree khác. Sửa thu_muc_worktree." >&2; exit 2 ;;
esac

# ---- branch đã tồn tại? ----
if git -C "$ART_ABS" rev-parse --verify --quiet "refs/heads/$TEN" >/dev/null; then
  wt=$(wt_cua_branch "$ART_ABS" "$TEN")
  if [ -n "$wt" ]; then
    echo "Branch \"$TEN\" đã có worktree: $wt" >&2
    echo "→ Mở phiên agent mới ở đó. Không tạo gì thêm." >&2
    echo "$wt"; exit 5
  fi
  echo "LỖI: branch \"$TEN\" đã có nhưng chưa có worktree. Chọn mô tả khác, hoặc nếu đúng là việc đó, NGƯỜI chạy:" >&2
  echo "  git worktree add \"$DUONG\" $TEN" >&2
  exit 2
fi
[ ! -e "$DUONG" ] || { echo "LỖI: $DUONG đã tồn tại — không ghi đè." >&2; exit 2; }

# base có bộ cài chưa: worktree chỉ có file đã commit — thiếu thì không chạy được checker nào
co_bo_cai() {
  git -C "$ART_ABS" cat-file -e "$1:$ART/conventions.md" 2>/dev/null &&
  git -C "$ART_ABS" cat-file -e "$1:$ART/.quy-trinh/tools" 2>/dev/null
}
co_ref() { git -C "$ART_ABS" rev-parse --verify --quiet "$1^{commit}" >/dev/null; }

# ======================================================================== đề xuất
if [ -z "$TAO" ]; then
  echo "ĐỀ XUẤT WORKTREE — agent chỉ gợi ý, NGƯỜI chọn base"
  echo ""
  echo "  Tên        $TEN   (tiền tố $tien_to ← $LOAI)"
  echo "  Đường dẫn  $DUONG"
  echo "             ($NGUON_TM: $MAU_TM)"
  echo ""
  echo "  Base — chọn một:"

  goi_y=""; phan_ky=""; truoc=0; sau=0
  co_ref "refs/heads/$GOC_MD" && co_l=1 || co_l=""
  co_ref "refs/remotes/origin/$GOC_MD" && co_r=1 || co_r=""
  if [ -n "$co_l" ] && [ -n "$co_r" ]; then
    set -- $(git -C "$ART_ABS" rev-list --left-right --count "$GOC_MD...origin/$GOC_MD")
    truoc=$1; sau=$2
    if [ "$sau" = 0 ]; then goi_y="$GOC_MD"
    elif [ "$truoc" = 0 ]; then goi_y="origin/$GOC_MD"
    else phan_ky=1; fi
  elif [ -n "$co_l" ]; then goi_y="$GOC_MD"
  elif [ -n "$co_r" ]; then goi_y="origin/$GOC_MD"
  fi

  n=0
  in_ung_vien() { # <ref> <ghi-chú...>
    _r=$1; shift; n=$((n + 1))
    _dau="   "; [ "$_r" = "$goi_y" ] && _dau=" ★ "
    printf '  %s[%d] %-18s %s\n' "$_dau" "$n" "$_r" "$(git -C "$ART_ABS" log -1 --format='%h  %cr  "%s"' "$_r")"
    for _g in "$@"; do printf '         %s\n' "$_g"; done
    co_bo_cai "$_r" || printf '         ✗ CHƯA có bộ cài (%s/) — chọn ref này sẽ bị từ chối\n' "$ART"
  }

  if [ -n "$co_l" ]; then
    g="nhanh_goc local"
    [ "$sau" != 0 ] && g="$g — ⚠ chậm $sau commit so với origin/$GOC_MD"
    [ "$truoc" != 0 ] && g="$g — có $truoc commit chưa push"
    in_ung_vien "$GOC_MD" "$g"
  fi
  if [ -n "$co_r" ] && [ "$(git -C "$ART_ABS" rev-parse "origin/$GOC_MD")" != "$(git -C "$ART_ABS" rev-parse "$GOC_MD" 2>/dev/null)" ]; then
    fh="$(wt_tuyet_doi "$ART_ABS" "$(git -C "$ART_ABS" rev-parse --git-common-dir)")/FETCH_HEAD"
    if [ -f "$fh" ]; then lan=$(date -r "$fh" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "?"); else lan="chưa từng fetch"; fi
    in_ung_vien "origin/$GOC_MD" "bản remote tính tới lần fetch cuối: $lan (script không tự fetch)"
  fi
  if [ -n "$MAU_PH" ]; then
    set -f
    # shellcheck disable=SC2086
    ph=$(for _m in $MAU_PH; do git -C "$ART_ABS" for-each-ref --format='%(refname:short)' "refs/heads/$_m"; done | sort -u | tail -3)
    set +f
    for r in $ph; do
      g="khớp mau_nhanh_phat_hanh"; [ "$LOAI" = bugfix ] && g="$g — hợp với bugfix gấp trên bản đã phát hành"
      in_ung_vien "$r" "$g"
    done
  fi
  n=$((n + 1)); printf '     [%d] ref khác — người nhập (branch, tag, commit). Branch việc khác (xếp chồng): review sẽ cảnh báo\n' "$n"
  echo ""
  if [ -n "$goi_y" ]; then echo "  ★ Gợi ý máy: $goi_y — bản mới nhất của $GOC_MD."
  elif [ -n "$phan_ky" ]; then echo "  Không gợi ý: $GOC_MD và origin/$GOC_MD đã PHÂN KỲ — người quyết."
  fi
  echo ""
  echo "  Sau khi NGƯỜI chọn, agent chạy:"
  echo "    sh $ART/.quy-trinh/tools/tao-worktree.sh $LOAI $MOTA --tao --goc <ref>"
  exit 0
fi

# ======================================================================== --tao
[ -n "$GOC" ] || { echo "LỖI: --tao cần --goc <ref> do NGƯỜI chọn — agent không tự điền." >&2; exit 2; }
co_ref "$GOC" || { echo "LỖI: không có ref \"$GOC\"." >&2; exit 2; }
co_bo_cai "$GOC" || { echo "LỖI: \"$GOC\" chưa có bộ cài $ART/ (conventions.md, .quy-trinh/tools) — commit bộ cài vào base trước." >&2; exit 2; }

mkdir -p "$(dirname "$DUONG")" || exit 2
git -C "$ART_ABS" worktree add -q --no-track -b "$TEN" "$DUONG" "$GOC" || { echo "LỖI: git không tạo được worktree." >&2; exit 2; }
sha=$(git -C "$ART_ABS" rev-parse --short=10 "$GOC")

echo "Đã tạo worktree $DUONG (branch $TEN, base $GOC @ $sha)" >&2
echo "" >&2
echo "Ghi vào intake.md, ngay dưới \"Loại việc\":" >&2
echo "  - **Base:** \`$GOC\` @ \`$sha\`" >&2
echo "" >&2
echo "Tiếp theo:" >&2
echo "  1. Ghi intake.md vào $DUONG/$ART/$TEN_TM/ rồi chạy kiem-tra-tiep-nhan.sh trên thư mục đó" >&2
lenh=""; [ -f "$CH" ] && lenh=$(. "$CH" >/dev/null 2>&1; printf '%s' "${LENH_CHUAN_BI_WT:-}")
if [ -n "$lenh" ]; then
  echo "  2. NGƯỜI chuẩn bị môi trường: cd \"$DUONG\" && $lenh" >&2
else
  echo "  2. NGƯỜI chuẩn bị môi trường (cài dependency, .env…) — khai LENH_CHUAN_BI_WT trong cau-hinh.sh để lần sau có lệnh sẵn" >&2
fi
echo "  3. NGƯỜI mở phiên agent MỚI tại $DUONG rồi chạy /spec" >&2
echo "$DUONG"
