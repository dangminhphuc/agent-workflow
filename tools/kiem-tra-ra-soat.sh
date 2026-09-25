#!/usr/bin/env sh
# Kiem tra dieu kien ra cua phase 04-review.
#
#   sh tools/kiem-tra-ra-soat.sh <thu-muc-artifact>
#
# Kiem hai dieu:
#   1. Moi ma YC trong spec.md deu co ket luan trong review.md.
#      Chan kieu "nhin qua thay on" — bo sot mot yeu cau la khong dat.
#   2. Yeu cau gan [CAN-HOI] khong duoc ket luan "dat".
#      Gia dinh tam chua ai xac nhan thi chua the ket luan la dung.
#
# Ma thoat: 0 = dat, 1 = co vi pham, 2 = thieu file dau vao.

DIR="${1:-.agent-workflow}"
SPEC="$DIR/spec.md"
REVIEW="$DIR/review.md"

[ -f "$SPEC" ]   || { echo "LỖI: không tìm thấy $SPEC" >&2; exit 2; }
[ -f "$REVIEW" ] || { echo "LỖI: không tìm thấy $REVIEW" >&2; exit 2; }

awk '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

  { sub(/\r$/, "") }
  FNR==1 { idx++ }

  # ---- File 1: spec.md ----
  idx==1 {
    if ($0 ~ /^###[ \t]+YC-[0-9]+/) {
      match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
      co_yc[cur] = 1; dsach[++n_yc] = cur
      next
    }
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
