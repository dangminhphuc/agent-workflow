#!/usr/bin/env sh
# Tạo và theo dõi MR/PR của việc đang làm. Chạy TRONG worktree của việc.
#
#   aw ship targets <thư-mục-feature>
#       liệt kê nhánh đích được phép (khoá mr_target_branches) để NGƯỜI chọn
#   aw ship create <thư-mục-feature> --target <nhánh> [--draft] [--allow-extra-commits] [--url <link>]
#       push branch, tạo MR, ghi <thư-mục-feature>/ship.md
#   aw ship status <thư-mục-feature>
#       hỏi nền tảng trạng thái từng MR trong ship.md, ghi lại
#
# create chặn khi:
#   - aw check ship chưa ĐẠT, hoặc worktree còn thay đổi chưa commit;
#   - nhánh đích không khớp mr_target_branches (bỏ trống = base_branch) hay không có trên origin;
#   - MR sẽ kéo theo commit KHÔNG thuộc việc (có trong đích? không; có trong base
#     của việc? có) — vd việc dựa trên develop mà gửi vào main. Người quyết:
#     đổi đích, tách branch, hoặc chấp nhận bằng --allow-extra-commits.
#   - đã có MR đang mở vào đúng đích đó: chỉ push commit mới, không tạo thêm, in URL.
# Cách tạo MR (xem tools/lib/mr.sh): gh/glab đã đăng nhập → GitLab: git push
# options (không cần token, chỉ gửi tiêu đề; mô tả để ở mo-ta-mr.md cho người dán)
# → link tạo tay điền sẵn; người tạo xong thì ghi lại bằng --url.
# Engine không merge, không duyệt MR.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SUB="${1:-}"; [ $# -gt 0 ] && shift
. "$HERE/lib/ket-qua.sh"
case "$SUB" in
  targets)
    kq_khai "aw ship targets" \
      "0=ĐÃ LIỆT KÊ — stdout là các nhánh đích; NGƯỜI chọn một" \
      "2=SAI THAM SỐ" \
      "3=KHÔNG CÓ NHÁNH ĐÍCH — không nhánh nào trên origin khớp mr_target_branches" ;;
  create)
    kq_khai "aw ship create" \
      "0=ĐÃ TẠO MR — stdout là URL" \
      "1=CHƯA ĐỦ ĐIỀU KIỆN — lý do phía trên" \
      "2=SAI THAM SỐ" \
      "4=KÉO THEO COMMIT NGOÀI VIỆC — người quyết, xem danh sách phía trên" \
      "5=ĐÃ CÓ MR ĐANG MỞ — đã push commit mới, không tạo MR thêm; stdout là URL" \
      "8=KHÔNG TẠO ĐƯỢC MR — đã in link tạo tay điền sẵn; tạo xong ghi lại bằng --url" ;;
  status)
    kq_khai "aw ship status" \
      "0=ĐÃ MERGE HẾT — dọn từ checkout chính: aw ship sweep" \
      "2=SAI THAM SỐ — hoặc việc chưa có MR (ship.md)" \
      "3=CÒN MR ĐANG MỞ — chờ review/merge" \
      "4=CÓ MR BỊ ĐÓNG KHÔNG MERGE — người quyết" \
      "6=CHƯA RÕ — gh/glab hỏi lỗi, và git không thấy MR đã merge" ;;
  *) kq_khai "aw ship" "2=SAI THAM SỐ"
     echo "Dùng: aw ship targets|create|status <thư-mục-feature> … | aw ship sweep [<branch>] [--apply]" >&2; exit 2 ;;
esac
. "$HERE/lib/md.sh"
. "$HERE/lib/worktree.sh"
. "$HERE/lib/kiem-cheo.sh"
. "$HERE/lib/mr.sh"
. "$HERE/lib/moi-truong.sh"
mt_dat "$HERE"
CONV="$MT_CONV"; R="$MT_REPO"

DIR="${1:-}"; [ $# -gt 0 ] && shift
[ -n "$DIR" ] && [ -d "$DIR" ] || { echo "LỖI: cần thư mục feature (aw feature in ra), vd .agent-workflow/feat_x" >&2; exit 2; }
SHIP="$DIR/ship.md"
FT=$(basename "$DIR")

if wt_la_chinh "$R"; then
  echo "LỖI: đang ở checkout chính — aw ship $SUB chạy trong worktree của việc. Dọn việc đã merge: aw ship sweep" >&2
  exit 2
fi

# Nhánh đích được phép: mẫu glob trong mr_target_branches, theo thứ tự khai; bỏ trống = base_branch.
mau_dich() {
  _md=$(conv_get "$CONV" mr_target_branches)
  [ -n "$_md" ] || { _md=$(conv_get "$CONV" base_branch); _md=${_md:-main}; }
  printf '%s\n' "$_md"
}
lay_origin() { git -C "$R" fetch -q --prune origin 2>/dev/null || echo "  (không fetch được origin — dùng thông tin đã có)" >&2; }

# ds_dich -> mỗi dòng một nhánh đích có trên origin, theo thứ tự mẫu, không trùng
ds_dich() {
  set -f
  for _p in $(mau_dich); do
    git -C "$R" for-each-ref --format='%(refname:strip=3)' refs/remotes/origin/ | while IFS= read -r _b; do
      [ "$_b" = HEAD ] && continue
      # shellcheck disable=SC2254
      case "$_b" in $_p) echo "$_b" ;; esac
    done | LC_ALL=C sort
  done | awk '!t[$0]++'
  set +f
}

# base của việc (dòng Base: trong intake.md), bỏ tiền tố origin/
base_viec() { kc_base "$DIR" 2>/dev/null; }

# ngoai_viec <đích> -> số commit MR vào <đích> kéo theo mà không thuộc việc
ngoai_viec() {
  _nb=$(base_viec)
  _tong=$(git -C "$R" rev-list --count HEAD "^refs/remotes/origin/$1" 2>/dev/null || echo 0)
  if [ -n "$_nb" ] && git -C "$R" rev-parse --verify --quiet "$_nb^{commit}" >/dev/null; then
    _cua=$(git -C "$R" rev-list --count HEAD "^refs/remotes/origin/$1" "^$_nb" 2>/dev/null || echo 0)
  else
    _cua=$_tong
  fi
  echo $((_tong - _cua))
}

case "$SUB" in
# ------------------------------------------------------------------ targets
targets)
  lay_origin
  ds=$(ds_dich)
  [ -n "$ds" ] || { echo "Không nhánh nào trên origin khớp mr_target_branches: $(mau_dich | tr '\n' ' ')" >&2; exit 3; }
  nb=$(base_viec); nb=${nb#origin/}
  echo "Nhánh đích (khoá mr_target_branches: $(mau_dich | tr '\n' ' ' | sed 's/ $//')) — NGƯỜI chọn:" >&2
  i=0
  printf '%s\n' "$ds" | while IFS= read -r b; do
    i=$((i + 1)); ng=$(ngoai_viec "$b"); gc=""
    [ "$b" = "$nb" ] && gc="  ← base của việc"
    [ "$ng" = 0 ] || gc="$gc  ⚠ kéo theo $ng commit ngoài việc"
    printf '  [%s] %s%s\n' "$i" "$b" "$gc"
  done
  ;;
# ------------------------------------------------------------------ create
create)
  DICH=""; DRAFT=""; THEM=""; URL=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --target) [ -n "${2:-}" ] || { echo "LỖI: --target cần tên nhánh." >&2; exit 2; }; DICH=${2#origin/}; shift 2 ;;
      --url)    [ -n "${2:-}" ] || { echo "LỖI: --url cần link MR." >&2; exit 2; }; URL=$2; shift 2 ;;
      --draft)  DRAFT=1; shift ;;
      --allow-extra-commits) THEM=1; shift ;;
      *) echo "LỖI: tham số lạ \"$1\"." >&2; exit 2 ;;
    esac
  done
  [ -n "$DICH" ] || { echo "LỖI: thiếu --target <nhánh> — NGƯỜI chọn từ: aw ship targets $DIR" >&2; exit 2; }
  B=$(git -C "$R" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "$B" ] && [ "$B" != HEAD ] || { echo "LỖI: HEAD không đứng trên branch nào." >&2; exit 2; }
  [ "$B" != "$DICH" ] || { echo "LỖI: branch của việc trùng nhánh đích \"$DICH\"." >&2; exit 2; }

  lay_origin
  printf '%s\n' "$(ds_dich)" | grep -qxF "$DICH" || {
    echo "LỖI: \"$DICH\" không phải nhánh đích được phép, hoặc không có trên origin." >&2
    echo "  Được phép: $(ds_dich | tr '\n' ' ')(khoá mr_target_branches)" >&2
    exit 2
  }

  chua=0
  if ! sh "$HERE/kiem-tra-gui-mr.sh" "$DIR" >/dev/null 2>&1; then
    echo "  ✗ aw check ship $DIR chưa ĐẠT — chạy nó để xem chi tiết." >&2; chua=1
  fi
  bn=$(git -C "$R" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$bn" != 0 ]; then
    echo "  ✗ Worktree còn $bn thay đổi chưa commit — MR sẽ thiếu chúng:" >&2
    git -C "$R" status --short | head -5 | sed 's/^/      /' >&2; chua=1
  fi
  [ "$chua" = 0 ] || exit 1

  ng=$(ngoai_viec "$DICH")
  if [ "$ng" != 0 ]; then
    echo "MR $B → $DICH kéo theo $ng commit KHÔNG thuộc việc này (có trong base $(base_viec), chưa có trong $DICH):" >&2
    mb=$(git -C "$R" merge-base HEAD "$(base_viec)" 2>/dev/null)
    [ -z "$mb" ] || git -C "$R" log --oneline -n 10 "$mb" "^refs/remotes/origin/$DICH" 2>/dev/null | sed 's/^/    /' >&2
    if [ -z "$THEM" ]; then
      echo "  Người quyết: chọn đích khác, tách branch mới từ $DICH rồi cherry-pick commit của việc," >&2
      echo "  hoặc chấp nhận (vd base có chủ ý chứa các commit đó): thêm --allow-extra-commits." >&2
      exit 4
    fi
    echo "  --allow-extra-commits: người đã chấp nhận." >&2
  fi

  NT=$(mr_nen_tang "$R" "$CONV")
  HEADSHA=$(git -C "$R" rev-parse HEAD)
  # ghi_mr <url> — thêm/thay dòng MR của đích này trong ship.md
  ghi_mr() {
    { sm_dong "$SHIP" | awk -F'|' -v d="$DICH" '$1 != d'; printf '%s|open|%s|%s\n' "$DICH" "$HEADSHA" "$1"; } |
      sm_ghi "$SHIP" "$FT" "$NT" "$B"
  }

  # Đã có MR đang mở vào đích này: chỉ push commit mới (sửa theo review) — MR tự cập nhật.
  cu=$(sm_dong "$SHIP" | awk -F'|' -v d="$DICH" '$1 == d && $2 == "open" { print $4; exit }')
  if [ -n "$cu" ]; then
    git -C "$R" push -q -u origin "$B" || { echo "LỖI: git push origin $B thất bại — xem thông báo của git phía trên." >&2; exit 8; }
    ghi_mr "$cu"
    echo "Đã có MR đang mở vào $DICH — đã push $B, MR tự cập nhật." >&2
    echo "$cu"; exit 5
  fi

  # MR mở từ trước (tạo tay, phiên khác) mà ship.md chưa có: ghi lại, không tạo thêm.
  [ -n "$URL" ] || URL=$(mr_tim "$R" "$NT" "$B" "$DICH")
  if [ -n "$URL" ]; then
    git -C "$R" push -q -u origin "$B" 2>/dev/null || true
    ghi_mr "$URL"
    echo "MR $B → $DICH (đã có): $URL — ghi vào $SHIP" >&2
    echo "$URL"; exit 0
  fi

  TD=$(awk '{ sub(/\r$/, "") } /^# / { sub(/^# /, ""); print; exit }' "$DIR/merge-request.md")
  # Mô tả gửi đi: bỏ dòng tiêu đề và comment HTML (lời dặn của mẫu). Đường không
  # gửi được mô tả thì để file này lại cho người dán.
  MO="$DIR/mo-ta-mr.md"
  awk '{ sub(/\r$/, "") } !dau && /^# / { dau = 1; next } { print }' "$DIR/merge-request.md" |
    awk '{
      s = $0; o = ""
      while (s != "") {
        if (trong) { i = index(s, "-->"); if (!i) { s = ""; break } s = substr(s, i + 3); trong = 0 }
        else { i = index(s, "<!--"); if (!i) { o = o s; s = ""; break } o = o substr(s, 1, i - 1); s = substr(s, i + 4); trong = 1 }
      }
      if (o ~ /^[ \t]*$/ && $0 !~ /^[ \t]*$/) next
      print o
    }' | cat -s | sed '/./,$!d' > "$MO"

  # 1. CLI đã đăng nhập: gửi đủ tiêu đề + mô tả.
  if mr_cli "$NT" "$R" >/dev/null; then
    mc=$MR_CLI_TEN
    git -C "$R" push -q -u origin "$B" || { echo "LỖI: git push origin $B thất bại — xem thông báo của git phía trên." >&2; exit 8; }
    echo "  push    $B → origin/$B" >&2
    URL=$(mr_tao "$R" "$NT" "$B" "$DICH" "$TD" "$MO" "$DRAFT") || {
      echo "LỖI: $mc không tạo được MR — thông báo phía trên. Tạo tay: $(mr_link_tay "$R" "$NT" "$B" "$DICH" "$TD" "$MO")" >&2
      echo "  rồi ghi lại: aw ship create $DIR --target $DICH --url <link MR>" >&2
      exit 8
    }
    rm -f "$MO"
    ghi_mr "$URL"
    echo "MR $B → $DICH: $URL (ghi vào $SHIP)" >&2
    echo "$URL"; exit 0
  fi
  echo "  ($MR_CLI_LY_DO)" >&2

  # 2. GitLab không có glab: tạo MR ngay trong lần push (push options) — chỉ cần quyền git.
  if [ "$NT" = gitlab ]; then
    URL=$(mr_tao_push "$R" "$B" "$DICH" "$TD" "$DRAFT"); km=$?
    if [ "$km" = 1 ]; then
      echo "  push kèm push options bị từ chối — push thường." >&2
      git -C "$R" push -q -u origin "$B" || { echo "LỖI: git push origin $B thất bại — xem thông báo của git phía trên." >&2; exit 8; }
    fi
    if [ "$km" = 0 ]; then
      ghi_mr "$URL"
      echo "MR $B → $DICH: $URL (tạo bằng git push options, ghi vào $SHIP)" >&2
      echo "  Mô tả CHƯA gửi (push option không chứa được xuống dòng): mở MR → Edit, dán nội dung $MO" >&2
      echo "$URL"; exit 0
    fi
    [ "$km" != 2 ] || echo "  push xong nhưng server không tạo MR (push options bị tắt?)." >&2
  else
    git -C "$R" push -q -u origin "$B" || { echo "LỖI: git push origin $B thất bại — xem thông báo của git phía trên." >&2; exit 8; }
    echo "  push    $B → origin/$B" >&2
  fi

  # 3. Link tạo MR điền sẵn — người bấm tạo rồi đưa link MR cho agent ghi lại.
  [ -n "$NT" ] || echo "Không biết nền tảng của origin — khai mr_platform: github|gitlab trong conventions.md." >&2
  lt=$(mr_link_tay "$R" "$NT" "$B" "$DICH" "$TD" "$MO")
  echo "Tạo MR bằng tay${lt:+ (đã điền sẵn đích, tiêu đề, mô tả): $lt}" >&2
  echo "  Tiêu đề: $TD" >&2
  echo "  Mô tả:   $MO (link không chứa thì dán nội dung file này)" >&2
  echo "Tạo xong thì ghi lại: aw ship create $DIR --target $DICH --url <link MR>" >&2
  exit 8
  ;;
# ------------------------------------------------------------------ status
status)
  [ -f "$SHIP" ] || { echo "Việc chưa có MR ($SHIP không có) — tạo bằng: aw ship create $DIR --target <nhánh>" >&2; exit 2; }
  sm_cap_nhat "$R" "$SHIP"
  echo "MR của $(sm_gia_tri "$SHIP" Branch) ($(sm_gia_tri "$SHIP" Platform)):"
  sm_dong "$SHIP" | while IFS='|' read -r d s h u; do printf '  %-8s → %-14s %s\n' "$s" "$d" "$u"; done
  st=$(sm_dong "$SHIP" | cut -d'|' -f2)
  if printf '%s\n' "$st" | grep -qx open; then exit 3; fi
  if printf '%s\n' "$st" | grep -qx closed; then exit 4; fi
  if printf '%s\n' "$st" | grep -qx unknown; then exit 6; fi
  exit 0
  ;;
esac
