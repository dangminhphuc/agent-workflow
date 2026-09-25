#!/usr/bin/env sh
# Kiểm tra luật truy vết nguồn — xem workflow/rules/truy-vet-nguon.md
#
#   sh tools/kiem-tra-truy-vet.sh <thư-mục-artifact>
#
# Mã thoát: 0 = đạt, 1 = có vi phạm, 2 = thiếu file đầu vào.

DIR="${1:-.agent-workflow}"
SPEC="$DIR/spec.md"
OQ="$DIR/open-questions.md"

if [ ! -f "$SPEC" ]; then
  echo "LỖI: không tìm thấy $SPEC" >&2
  exit 2
fi
if [ ! -f "$OQ" ]; then
  echo "LỖI: không tìm thấy $OQ" >&2
  echo "      File này bắt buộc tồn tại kể cả khi rỗng." >&2
  echo "      Rỗng = đã rà và không thấy gì. Thiếu = chưa rà." >&2
  exit 2
fi

awk '
  function loi(msg) { n_loi++; print "  [LỖI] " msg }

  { sub(/\r$/, "") }

  FNR==1 { idx++ }

  # ---- File 1: open-questions.md ----
  idx==1 {
    if ($0 ~ /^##[ \t]+YC-[0-9]+/) {
      match($0, /YC-[0-9]+/); cur_oq = substr($0, RSTART, RLENGTH)
      co_muc[cur_oq] = 1
    }
    if (cur_oq != "" && $0 ~ /Giả định tạm/) co_gia_dinh[cur_oq] = 1
    next
  }

  # ---- File 2: spec.md ----
  $0 ~ /^###[ \t]+YC-[0-9]+/ {
    match($0, /YC-[0-9]+/); cur = substr($0, RSTART, RLENGTH)
    if (cur in da_gap) loi("Mã " cur " xuất hiện nhiều lần trong spec.md")
    da_gap[cur] = 1
    thu_tu[++n] = cur
    so_nguon[cur] = 0
    next
  }
  # Heading cấp 2 kết thúc vùng yêu cầu (ví dụ "## Ngoài phạm vi")
  $0 ~ /^##[ \t]/ { cur = "" ; next }

  cur != "" && $0 ~ /^[ \t]*-[ \t]*\*{0,2}Nguồn/ {
    so_nguon[cur]++
    dong = $0
    sub(/^.*Nguồn[^:]*:[ \t]*/, "", dong)
    if (match(dong, /\[[^]]+\]/)) {
      nhan[cur] = substr(dong, RSTART + 1, RLENGTH - 2)
    } else {
      nhan[cur] = ""
    }
  }

  END {
    hop_le["CONFLUENCE"]=1; hop_le["JIRA"]=1; hop_le["FILE"]=1
    hop_le["SUY-RA"]=1;     hop_le["CẦN-HỎI"]=1

    if (n == 0) loi("spec.md không có yêu cầu nào (không thấy heading \"### YC-NNN\")")

    for (i = 1; i <= n; i++) {
      c = thu_tu[i]
      if (so_nguon[c] == 0) {
        loi(c ": thiếu dòng \"Nguồn:\". Yêu cầu không có nhãn = fail.")
        continue
      }
      if (so_nguon[c] > 1) {
        loi(c ": có " so_nguon[c] " dòng \"Nguồn:\", phải đúng một.")
        continue
      }
      t = nhan[c]
      if (t == "") {
        loi(c ": dòng \"Nguồn:\" không có nhãn trong ngoặc vuông.")
        continue
      }
      if (!(t in hop_le)) {
        loi(c ": nhãn [" t "] không hợp lệ. Chỉ chấp nhận: " \
            "[CONFLUENCE] [JIRA] [FILE] [SUY-RA] [CẦN-HỎI]")
        continue
      }
      if (t == "CẦN-HỎI") {
        if (!(c in co_muc))
          loi(c ": gắn [CẦN-HỎI] nhưng open-questions.md không có mục \"## " c "\". " \
              "Gắn nhãn mà không hỏi ai thì nhãn vô nghĩa.")
        else if (!(c in co_gia_dinh))
          loi(c ": mục trong open-questions.md thiếu dòng \"Giả định tạm\". " \
              "Không có giả định tạm thì phase sau không đi tiếp được.")
      }
      dem_nhan[t]++
    }

    print ""
    print "Tổng: " n " yêu cầu"
    for (t in dem_nhan) printf "  [%s] %d\n", t, dem_nhan[t]
    print ""
    if (n_loi > 0) { print "KHÔNG ĐẠT — " n_loi " vi phạm."; exit 1 }
    print "ĐẠT — mọi yêu cầu đều truy được về nguồn."
  }
' "$OQ" "$SPEC"
