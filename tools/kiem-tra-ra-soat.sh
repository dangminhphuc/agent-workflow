#!/usr/bin/env sh
# Kiem tra dieu kien ra cua phase 05-review — CONG CHAN CUOI.
#
#   aw check review <thu-muc-feature>
#
# Chan:
#   1. Moi ma YC trong spec.md deu co ket luan hop le trong review.md.
#   2. Yeu cau gan [CAN-HOI] khong duoc ket luan "dat".
#   3. Dau vao khong qua kiem-tra-ke-hoach.sh (keo theo design va spec).
#   4. ket-qua-kiem-thu.md thieu hoac ma thoat khac 0.
#   5. Moi CANH BAO don tu cac phase truoc con ton tai: YC chua co test,
#      diff ngoai pham vi, artifact loi thoi, loai viec lech branch, test cu
#      bi sua chua khai, diem mu muc "chan review" chua tra loi. Giua flow
#      chung chi canh bao de flow khong tac; o day
#      thi khong con cho nao phia sau de bat lai.
#   6. Luat theo loai viec (intake.md) — nhu implement; bugfix con phai co
#      dong "Test tai hien do vi: ..." do nguoi ra soat viet.
# Canh bao (khong chan): base trong intake.md khong phai nhanh goc / nhanh phat
# hanh (vd xep chong len branch viec khac) — nguoi xac nhan co chu y.
#
# Kết quả: nhãn in cuối output — xem kq_khai bên dưới (mã thoát chỉ là chi tiết của máy).

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib/ket-qua.sh"
kq_khai kiem-tra-ra-soat.sh \
  "0=ĐẠT — được sang phase sau" \
  "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
  "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
. "$HERE/lib/md.sh"
. "$HERE/lib/kiem-cheo.sh"

DIR="${1:-.}"
SPEC="$DIR/spec.md"
REVIEW="$DIR/review.md"
KQ="$DIR/ket-qua-kiem-thu.md"

[ -f "$SPEC" ]   || { echo "LỖI: không tìm thấy $SPEC" >&2; exit 2; }
[ -f "$REVIEW" ] || { echo "LỖI: không tìm thấy $REVIEW" >&2; exit 2; }

n_truoc=0
loi_truoc() { n_truoc=$((n_truoc + 1)); echo "  [LỖI] $1"; }

if ! sh "$HERE/kiem-tra-ke-hoach.sh" "$DIR" >/dev/null 2>&1; then
  loi_truoc "Đầu vào chưa đạt: plan.md/tdd.md/spec.md không qua aw check plan — chạy nó để xem chi tiết."
fi

if [ ! -f "$KQ" ]; then
  loi_truoc "Không có ket-qua-kiem-thu.md — /implement chưa chạy aw check implement."
elif ! grep -q 'Mã thoát: `0`' "$KQ"; then
  loi_truoc "ket-qua-kiem-thu.md ghi mã thoát khác 0 — test chưa xanh."
fi

cb=$( { kc_chan_theo_loai "$DIR"; kc_test_yc "$DIR"; kc_pham_vi "$DIR"; kc_loi_thoi "$DIR"; kc_canh_bao_theo_loai "$DIR"; kc_diem_mu_mo "$DIR" "chặn" "chặn review"; } )

# bugfix: người rà soát phải nói rõ test tái hiện đỏ vì đâu — máy chỉ biết nó đã đỏ.
if [ "$(kc_loai "$DIR")" = "bugfix" ]; then
  v=$(awk '{ sub(/\r$/, "") } /Test tái hiện đỏ vì[^:]*:/ { s = $0; sub(/^[^:]*:/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); print s; exit }' "$REVIEW")
  case "$v" in ""|"<"*">") loi_truoc "bugfix: review.md thiếu \"Test tái hiện đỏ vì: <trích output tai-hien.md>\"" ;; esac
fi
if [ -n "$cb" ]; then
  # vòng lặp ở shell chính (không pipe) để đếm được
  while IFS= read -r l; do
    [ -n "$l" ] && loi_truoc "Cảnh báo chưa xử lý — $l"
  done <<CB
$cb
CB
fi

# Base lạ (vd xếp chồng lên branch việc khác): chỉ cảnh báo — người xác nhận có chủ ý.
cb_base=$(kc_base_la "$DIR")
[ -z "$cb_base" ] || echo "  [CẢNH BÁO] $cb_base"

awk -v loi_truoc="$n_truoc" '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }
  BEGIN { n_loi = loi_truoc }
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

  { sub(/\r$/, "") }
  FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : 2 }

  # ---- File 1: spec.md ----
  idx==1 {
    if ($0 ~ /^###[ \t]+YC-[0-9]+/) {
      match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
      co_yc[cur] = 1; dsach[++n_yc] = cur
      next
    }
    if ($0 ~ /^##[#]?[ \t]/) { cur = ""; next }   # cùng ranh giới vùng YC với kiem-tra-truy-vet.sh
    if (cur != "" && $0 ~ /Nguồn/ && $0 ~ /CẦN-HỎI/) can_hoi[cur] = 1
    next
  }

  # ---- File 2: review.md — bang cua Lang kinh 1 ----
  $0 ~ /^[ \t]*\|/ && $0 ~ /YC-[0-9]+/ {
    match($0, /YC-[0-9]+/); c = substr($0, RSTART, RLENGTH)
    split($0, f, "|")
    kl = trim(f[3])
    if (kl != "") ket_luan[c] = kl
  }

  END {
    hop_le["đạt"] = 1
    hop_le["đạt một phần"] = 1
    hop_le["chưa đạt"] = 1
    hop_le["chờ xác nhận"] = 1

    if (n_yc == 0) loi("spec.md không có mã YC nào")

    for (i = 1; i <= n_yc; i++) {
      c = dsach[i]
      if (!(c in ket_luan)) {
        loi(c ": không có kết luận nào trong review.md. Bỏ sót một yêu cầu " \
            "nghĩa là phase rà soát chưa chạy xong.")
        continue
      }
      kl = ket_luan[c]
      if (!(kl in hop_le)) {
        loi(c ": kết luận \"" kl "\" không hợp lệ. Chỉ chấp nhận: " \
            "đạt / đạt một phần / chưa đạt / chờ xác nhận")
        continue
      }
      if ((c in can_hoi) && kl == "đạt") {
        loi(c ": gắn [CẦN-HỎI] trong spec nhưng kết luận \"đạt\". " \
            "Giả định tạm chưa ai xác nhận thì phải là \"chờ xác nhận\".")
        continue
      }
      dem[kl]++
    }

    print ""
    printf "Tổng: %d yêu cầu\n", n_yc
    for (i = 1; i <= n_yc; i++) {
      c = dsach[i]
      printf "  %-8s %s%s\n", c, (c in ket_luan ? ket_luan[c] : "KHÔNG CÓ KẾT LUẬN"), \
             ((c in can_hoi) ? "   (đứng trên giả định tạm)" : "")
    }
    print ""
    if (n_loi > 0) { print "KHÔNG ĐẠT — " n_loi " vi phạm."; exit 1 }
    print "ĐẠT — mọi yêu cầu đều có kết luận rà soát."
  }
' "$SPEC" "$REVIEW"
