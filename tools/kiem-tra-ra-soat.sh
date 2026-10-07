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
#   5b. Task chua xong bang may: con [~] / [ ], task [x] khong co bang chung xanh
#      trong ket-qua-task.md (aw task done); file con dau xung dot merge; test
#      moi bi tat / chay rieng (mau_bo_qua_test) ma khong khai o "Unplanned".
#   6. Luat theo loai viec (intake.md) — nhu implement; bugfix con phai co
#      dong "Repro test fails because: ..." do nguoi ra soat viet.
#   7. Quy tac rieng cua repo (moi khoa quy_tac_* trong conventions.md): file
#      khai khong co / chua commit / khoa go nham; review.md thieu muc
#      "## Repo rules" hoac thieu ket luan hop le cho mot file.
#   8. Lens 4 — Security: thieu muc; thieu hang muc nao trong bay hang muc co
#      dinh; verdict ngoai pass / finding / not applicable; finding hoac
#      not applicable khong co vi tri / ly do; co finding ma Lens 3 khong co
#      finding nao.
#   9. Lens 3 — Quality: thieu muc; khong co finding nao ma cung khong ghi
#      "- None" (hoac ghi "- None" ma van co finding); tieu de / gia tri con
#      chu giu cho; [Blocker] / [Should fix] thieu "Location:" dang file:dong;
#      [Blocker] thieu "Failure scenario:"; [Blocker] / [Should fix] thieu
#      "Category:" dang kebab-case (aw journal dem loai lap lai giua cac viec).
#  10. Conclusion: "Blocker findings: <n>" thieu hoac khac so muc [Blocker].
#  11. "Reviewed tree:" thieu hoac khac dau van tay code hien tai — code doi
#      sau khi ra soat thi ket luan khong con noi ve code nay.
#  12. Diff dung code nhay cam (mau_code_nhay_cam trong conventions.md) ma
#      review.md thieu "- Security reviewer: <ten nguoi>" (trong, giu cho, hay
#      ghi ten agent).
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
. "$HERE/lib/task.sh"

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

cb=$( { kc_chan_theo_loai "$DIR"; tk_dang_do "$DIR"; tk_chua_xong "$DIR"; tk_thieu_bang_chung "$DIR"; kc_dau_xung_dot "$DIR"; kc_test_bo_qua "$DIR"; kc_test_yc "$DIR"; kc_pham_vi "$DIR"; kc_loi_thoi "$DIR"; kc_canh_bao_theo_loai "$DIR"; kc_diem_mu_mo "$DIR" "blocking" "review-blocking"; } )

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

# Lens 4 — Security: bảng hạng mục cố định — mỗi hạng mục một dòng kết luận.
# Thiếu dòng = người rà soát chưa xét hạng mục đó (không có "mặc định là ổn").
MUC_BAO_MAT="Input validation / injection
Authn / authz
Sensitive data / PII in logs
Secrets / config
Crypto
SSRF / path traversal / deserialization
New dependencies"
bang_bm=$(awk '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  { sub(/\r$/, "") }
  /^##[ \t]+Lens 4/ { trong = 1; co = 1; next }
  /^##[ \t]/ { trong = 0 }
  trong && /^[ \t]*\|/ {
    n = split($0, c, "|"); f = trim(c[2]); gsub(/[`*]/, "", f)
    if (f == "" || f ~ /^:?-+:?$/ || f == "Item") next
    v = trim(c[3]); gsub(/`/, "", v)
    print f "\t" v "\t" (n >= 5 ? trim(c[4]) : "")
  }
  END { if (!co) print "\tKHÔNG CÓ MỤC" }
' "$REVIEW")
if printf '%s\n' "$bang_bm" | grep -q "	KHÔNG CÓ MỤC"; then
  loi_truoc "review.md thiếu mục \"## Lens 4 — Security\" — bảng bảy hạng mục bảo mật, mỗi hạng mục một dòng kết luận (templates/review.md)"
else
  co_finding=0
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    dong=$(printf '%s\n' "$bang_bm" | awk -F '	' -v m="$m" '$1 == m { print; exit }')
    kl=$(printf '%s' "$dong" | cut -f2); gc=$(printf '%s' "$dong" | cut -f3)
    case "$kl" in
      "") loi_truoc "Lens 4 \"$m\": không có dòng kết luận — mỗi hạng mục bảo mật phải được xét" ;;
      "pass") ;;
      "finding"|"not applicable")
        [ "$kl" = finding ] && co_finding=1
        case "$gc" in ""|"<"*">") loi_truoc "Lens 4 \"$m\": verdict \"$kl\" mà thiếu vị trí / lý do" ;; esac ;;
      *) loi_truoc "Lens 4 \"$m\": verdict \"$kl\" không hợp lệ. Chỉ chấp nhận: pass / finding / not applicable" ;;
    esac
  done <<BM
$MUC_BAO_MAT
BM
  if [ "$co_finding" = 1 ]; then
    nf=$(awk '{ sub(/\r$/, "") } /^###[ \t]+\[(Blocker|Should fix|Nit)\]/ && !/<tiêu đề>/' "$REVIEW" | wc -l | tr -d ' ')
    [ "$nf" -gt 0 ] || loi_truoc "Lens 4 có \"finding\" nhưng Lens 3 không có finding nào — mỗi finding bảo mật phải thành một mục [Blocker] / [Should fix] / [Nit] ở Lens 3"
  fi
fi

# Lens 3 — Quality và Conclusion: finding phải đủ để người khác kiểm lại, và
# số Blocker ở kết luận phải khớp số mục — không thì aw check ship đếm một
# đằng, người đọc kết luận một nẻo.
l3=$(awk '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function gt(s) { sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); return trim(s) }
  function giu_cho(s) { return s == "" || s ~ /^`?<[^>]*>`?$/ }
  function dong_muc() {
    if (muc == "") return
    if (giu_cho(ten)) print "Lens 3: finding [" muc "] còn tiêu đề giữ chỗ của mẫu \"<tiêu đề>\""
    if (muc == "Blocker" || muc == "Should fix") {
      if (!co_loc) print "Lens 3 [" muc "] \"" ten "\": thiếu dòng \"- Location: `file:dòng`\""
      else if (loc !~ /[^ `:]+:[0-9]+/) print "Lens 3 [" muc "] \"" ten "\": Location \"" loc "\" không có dạng file:dòng (số dòng thật)"
    }
    if (muc == "Blocker" && giu_cho(kb))
      print "Lens 3 [Blocker] \"" ten "\": thiếu \"- Failure scenario:\" — đầu vào cụ thể → kết quả sai"
    if ((muc == "Blocker" || muc == "Should fix") && cat !~ /^[a-z0-9]+(-[a-z0-9]+)*$/)
      print "Lens 3 [" muc "] \"" ten "\": " (cat == "" ? "thiếu dòng \"- Category: <loại>\"" : "Category \"" cat "\" không phải kebab-case") " — loại lỗi ngắn, chữ thường, vd missing-null-check, sql-injection; dùng lại tên đã có (aw journal) để đếm được lặp lại"
    muc = ""
  }
  { sub(/\r$/, "") }
  /<!--/ && !/-->/ { cm = 1 }
  cm { if (/-->/) cm = 0; next }
  /^##[ \t]+Lens 3/ { trong = 1; co_l3 = 1; next }
  /^##[ \t]/ {
    if (trong) dong_muc()
    trong = 0
    if ($0 ~ /^##[ \t]+Conclusion/) kl = 1; else kl = 0
    next
  }
  trong && /^###[ \t]/ {
    dong_muc()
    if (match($0, /\[(Blocker|Should fix|Nit)\]/)) {
      muc = substr($0, RSTART + 1, RLENGTH - 2); ten = trim(substr($0, RSTART + RLENGTH))
      co_loc = 0; loc = ""; kb = ""; cat = ""; n_f++; if (muc == "Blocker") n_b++
    } else print "Lens 3: tiêu đề \"" $0 "\" không có mức [Blocker] / [Should fix] / [Nit]"
    next
  }
  trong && /^[ \t]*-[ \t]*None[ \t]*$/ { none = 1; next }
  trong && muc != "" && /^[ \t]*-[ \t]*\**Location\**:/ { co_loc = 1; loc = gt($0); next }
  trong && muc != "" && /^[ \t]*-[ \t]*\**Failure scenario\**:/ { kb = gt($0); next }
  trong && muc != "" && /^[ \t]*-[ \t]*\**Category\**:/ { cat = gt($0); gsub(/`/, "", cat); next }
  kl && /^[ \t]*-[ \t]*\**Blocker findings\**:/ { co_kl = 1; kl_b = gt($0) }
  END {
    if (trong) dong_muc()
    if (!co_l3) { print "review.md thiếu mục \"## Lens 3 — Quality\" — có finding thì ghi, không có thì ghi đúng một dòng \"- None\""; exit }
    if (n_f == 0 && !none) print "Lens 3 không có finding nào mà cũng không ghi \"- None\" — không phân biệt được \"không thấy lỗi\" với \"chưa rà\""
    if (n_f > 0 && none) print "Lens 3 vừa ghi \"- None\" vừa có " n_f " finding — bỏ một trong hai"
    if (!co_kl) print "Conclusion thiếu dòng \"- Blocker findings: <n>\""
    else if (kl_b !~ /^[0-9]+$/) print "Conclusion: \"Blocker findings: " kl_b "\" không phải số"
    else if (kl_b + 0 != n_b + 0) print "Conclusion ghi Blocker findings: " kl_b " nhưng Lens 3 có " (n_b + 0) " mục [Blocker]"
  }
' "$REVIEW")
while IFS= read -r l; do [ -n "$l" ] && loi_truoc "$l"; done <<L3
$l3
L3

# Reviewed tree: kết luận rà soát chỉ đúng cho đúng code đã rà.
rt=$(awk '{ sub(/\r$/, "") } /^[ \t]*-[ \t]*\**Reviewed tree\**:/ { s = $0; sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[` \t]/, "", s); print s; exit }' "$REVIEW")
vt=$(kc_van_tay "$DIR")
case "$rt" in
  "") loi_truoc "review.md thiếu dòng \"- Reviewed tree: \`<sha>\`\" — chép dòng Tree của ket-qua-kiem-thu.md${vt:+ (hiện tại: $vt)}" ;;
  "<"*">") loi_truoc "review.md: \"Reviewed tree\" còn chữ giữ chỗ — chép dòng Tree của ket-qua-kiem-thu.md${vt:+ (hiện tại: $vt)}" ;;
  *)
    if [ -z "$vt" ]; then loi_truoc "Không tính được dấu vân tay code hiện tại (git) — không xác nhận được review còn đúng"
    elif [ "$rt" != "$vt" ]; then loi_truoc "review.md đã rà Tree $rt nhưng code hiện tại là $vt — code đổi sau khi rà soát; chạy lại aw check implement rồi /aw-review"
    fi ;;
esac

# Code nhạy cảm: một NGƯỜI rà bảo mật phải đọc Lens 4 và diff. Máy không biết ai
# viết dòng tên (như mọi ô của người) — chỉ chặn khi thiếu, và khi rõ là agent.
nc=$(kc_nhay_cam "$DIR")
if [ -n "$nc" ]; then
  srv=$(awk '{ sub(/\r$/, "") } /^[ \t]*-[ \t]*\**Security reviewer\**:/ { s = $0; sub(/^[^:]*:/, "", s); gsub(/<!--.*-->/, "", s); gsub(/[`*]/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", s); print s; exit }' "$REVIEW")
  ds_nc=$(printf '%s\n' "$nc" | head -5 | tr '\n' ' ' | sed 's/ $//')
  [ "$(printf '%s\n' "$nc" | wc -l | tr -d ' ')" -gt 5 ] && ds_nc="$ds_nc …"
  case "$(printf '%s' "$srv" | tr 'A-Z' 'a-z')" in
    "") loi_truoc "Diff đụng code nhạy cảm (mau_code_nhay_cam: $ds_nc) — review.md cần dòng \"- Security reviewer: <tên người>\": một NGƯỜI rà bảo mật đọc Lens 4 và diff rồi tự ghi tên" ;;
    "<"*">") loi_truoc "Diff đụng code nhạy cảm ($ds_nc) — \"Security reviewer\" còn chữ giữ chỗ; người rà bảo mật tự ghi tên" ;;
    claude|claude\ code|agent|ai|assistant|subagent|cursor|copilot|codex|none|n/a|-)
      loi_truoc "Diff đụng code nhạy cảm ($ds_nc) — \"Security reviewer: $srv\" không phải một người. Agent không tự xác nhận thay người rà bảo mật" ;;
  esac
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
  # Chi dong co O DAU la ma YC: bang khac (Lens 4, Repo rules) hay nhac YC trong
  # cot ly do, khong duoc ghi de ket luan cua Lens 1.
  $0 ~ /^[ \t]*\|/ {
    split($0, f, "|"); c = trim(f[2]); gsub(/[`*]/, "", c)
    if (c !~ /^YC-[0-9]+$/) next
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
ma=$?
# Đạt: ghi finding theo Category vào nhật ký harness; loại lặp ở nhiều việc thì gợi ý.
[ "$ma" -eq 0 ] && sh "$HERE/nhat-ky.sh" _findings "$DIR" "$REVIEW" 2>/dev/null
exit "$ma"
