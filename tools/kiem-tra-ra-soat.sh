#!/usr/bin/env sh
# Kiem tra dieu kien ra cua phase 05-review — CONG CHAN CUOI.
#
#   aw check review <thu-muc-feature>
#
# Chan:
#   1. Moi ma YC trong spec.md deu co ket luan hop le trong review.md.
#   2. Yeu cau gan [OPEN-QUESTION] khong duoc ket luan "pass".
#   3. Dau vao khong qua kiem-tra-ke-hoach.sh (keo theo design va spec).
#   4. ket-qua-kiem-thu.md thieu hoac ma thoat khac 0; ket-qua-bao-mat.md thieu
#      hoac khong XANH; mot trong hai file khong ghi Tree hoac Tree khac noi dung
#      code hien tai (code doi sau lan chay — bang chung het gia tri).
#   5. Moi CANH BAO don tu cac phase truoc con ton tai: YC chua co test,
#      diff ngoai pham vi, artifact loi thoi, loai viec lech branch, test cu
#      bi sua chua khai, diem mu muc "review-blocking" chua tra loi. Giua flow
#      chung chi canh bao de flow khong tac; o day
#      thi khong con cho nao phia sau de bat lai.
#   6. Luat theo loai viec (intake.md) — nhu implement; bugfix con phai co
#      dong "Repro test fails because: ..." do nguoi ra soat viet.
#   7. Quy tac rieng cua repo (moi khoa quy_tac_* trong conventions.md): file
#      khai khong co / chua commit / khoa go nham; review.md thieu muc
#      "## Repo rules" hoac thieu ket luan hop le cho mot file.
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
. "$HERE/lib/bang-lenh.sh"
. "$HERE/lib/kiem-cheo.sh"

DIR="${1:-.}"
SPEC="$DIR/spec.md"
REVIEW="$DIR/review.md"
KQ="$DIR/ket-qua-kiem-thu.md"
KQBM="$DIR/ket-qua-bao-mat.md"

[ -f "$SPEC" ]   || { echo "LỖI: không tìm thấy $SPEC" >&2; exit 2; }
[ -f "$REVIEW" ] || { echo "LỖI: không tìm thấy $REVIEW" >&2; exit 2; }

n_truoc=0
loi_truoc() { n_truoc=$((n_truoc + 1)); echo "  [LỖI] $1"; }

if ! sh "$HERE/kiem-tra-ke-hoach.sh" "$DIR" >/dev/null 2>&1; then
  loi_truoc "Đầu vào chưa đạt: plan.md/tdd.md/spec.md không qua aw check plan — chạy nó để xem chi tiết."
fi

if [ ! -f "$KQ" ]; then
  loi_truoc "Không có ket-qua-kiem-thu.md — /aw-implement chưa chạy aw check implement."
elif ! grep -q 'Mã thoát: `0`' "$KQ"; then
  loi_truoc "ket-qua-kiem-thu.md ghi mã thoát khác 0 — test chưa xanh."
fi
if [ ! -f "$KQBM" ]; then
  loi_truoc "Không có ket-qua-bao-mat.md — chưa quét bảo mật (aw check implement, hoặc aw check security)."
elif ! grep -q '^- Kết quả: \*\*XANH\*\*' "$KQBM"; then
  loi_truoc "ket-qua-bao-mat.md không XANH — còn lệnh quét bảo mật đỏ; CI sẽ chặn đúng chỗ này."
fi
# Độ mới: bằng chứng phải chạy trên đúng nội dung code đang review.
moi=$( { kc_ket_qua_cu "$DIR" "$KQ" "aw check implement $DIR"; kc_ket_qua_cu "$DIR" "$KQBM" "aw check security $DIR (hoặc aw check implement)"; } )
while IFS= read -r l; do [ -n "$l" ] && loi_truoc "$l"; done <<MOI
$moi
MOI

cb=$( { kc_chan_theo_loai "$DIR"; kc_test_yc "$DIR"; kc_pham_vi "$DIR"; kc_loi_thoi "$DIR"; kc_canh_bao_theo_loai "$DIR"; kc_diem_mu_mo "$DIR" "blocking" "review-blocking"; } )

# bugfix: người rà soát phải nói rõ test tái hiện đỏ vì đâu — máy chỉ biết nó đã đỏ.
if [ "$(kc_loai "$DIR")" = "bugfix" ]; then
  v=$(awk '{ sub(/\r$/, "") } /^[ \t]*-[ \t]*\**Repro test fails because\**:/ { s = $0; sub(/^[^:]*:/, "", s); gsub(/[*`]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); print s; exit }' "$REVIEW")
  case "$v" in ""|"<"*">") loi_truoc "bugfix: review.md thiếu \"Repro test fails because: <trích output tai-hien.md>\"" ;; esac
fi
if [ -n "$cb" ]; then
  # vòng lặp ở shell chính (không pipe) để đếm được
  while IFS= read -r l; do
    [ -n "$l" ] && loi_truoc "Cảnh báo chưa xử lý — $l"
  done <<CB
$cb
CB
fi

# Quy tắc riêng của repo (mọi khoá quy_tac_*): file khai phải dùng được, và
# review.md có kết luận cho TỪNG file — thiếu là người rà soát chưa đối chiếu.
qtl=$( { kc_quy_tac_khoa_la "$DIR"; kc_quy_tac_loi "$DIR" review; } )
while IFS= read -r l; do [ -n "$l" ] && loi_truoc "$l"; done <<QT
$qtl
QT
qt=$(kc_quy_tac "$DIR" review)
if [ -n "$qt" ]; then
  # Mục "## Repo rules": mỗi dòng bảng -> "<file>\t<kết luận>\t<bằng chứng / lý do>"
  bang_qt=$(awk '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    { sub(/\r$/, "") }
    /^##[ \t]+Repo rules/ { trong = 1; co = 1; next }
    /^##[ \t]/ { trong = 0 }
    trong && /^[ \t]*\|/ {
      n = split($0, c, "|"); f = trim(c[2]); gsub(/`/, "", f)
      if (f == "" || f ~ /^:?-+:?$/ || f == "File") next
      print f "\t" trim(c[3]) "\t" (n >= 5 ? trim(c[4]) : "")
    }
    END { if (!co) print "\tKHÔNG CÓ MỤC" }
  ' "$REVIEW")
  if printf '%s\n' "$bang_qt" | grep -q "	KHÔNG CÓ MỤC"; then
    loi_truoc "review.md thiếu mục \"## Repo rules\" — repo khai $(printf '%s\n' "$qt" | wc -l | tr -d ' ') file quy tắc (aw rules review); mỗi file một dòng kết luận"
  else
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      dong=$(printf '%s\n' "$bang_qt" | awk -F '	' -v f="$f" '$1 == f { print; exit }')
      kl=$(printf '%s' "$dong" | cut -f2); gc=$(printf '%s' "$dong" | cut -f3)
      case "$kl" in
        "") loi_truoc "quy tắc repo \"$f\": không có verdict trong mục \"Repo rules\" của review.md" ;;
        "pass") ;;
        "violation"|"not applicable")
          case "$gc" in ""|"<"*">") loi_truoc "quy tắc repo \"$f\": verdict \"$kl\" mà thiếu vị trí / lý do" ;; esac ;;
        *) loi_truoc "quy tắc repo \"$f\": verdict \"$kl\" không hợp lệ. Chỉ chấp nhận: pass / violation / not applicable" ;;
      esac
    done <<QT
$qt
QT
  fi
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
    if (cur != "" && $0 ~ /^[ \t]*-[ \t]*\**Source\**:/ && $0 ~ /OPEN-QUESTION/) can_hoi[cur] = 1
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
    hop_le["pass"] = 1
    hop_le["partial"] = 1
    hop_le["fail"] = 1
    hop_le["pending"] = 1

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
            "pass / partial / fail / pending")
        continue
      }
      if ((c in can_hoi) && kl == "pass") {
        loi(c ": gắn [OPEN-QUESTION] trong spec nhưng verdict \"pass\". " \
            "Giả định tạm chưa ai xác nhận thì phải là \"pending\".")
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
