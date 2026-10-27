# Khối "Kết quả" in cuối mỗi script — người và agent đọc NHÃN, không đọc mã số.
#
#   . "$HERE/lib/result.sh"
#   kq_khai check-plan.sh \
#     "0=ĐẠT — được sang phase sau" \
#     "1=KHÔNG ĐẠT — có vi phạm, sửa trong phase này" \
#     "2=THIẾU ĐẦU VÀO — chưa có file cần kiểm"
#
# Khi script thoát (exit, hoặc chạy hết), stderr có:
#
#   Result: check-plan.sh
#     [ ] ĐẠT — được sang phase sau
#     [x] KHÔNG ĐẠT — có vi phạm, sửa trong phase này
#     [ ] THIẾU ĐẦU VÀO — chưa có file cần kiểm
#
# Mã thoát vẫn giữ nguyên — script gọi lẫn nhau và shell cần nó — nhưng chỉ là
# chi tiết của máy. Tài liệu và prompt nói theo nhãn.
#
# In ra stderr: stdout của vài script là dữ liệu (đường dẫn, dòng input) mà
# người gọi đọc lại, không được lẫn khối này vào.
#
# kq_don <lệnh>: việc dọn dẹp chạy trước khi in (thay cho trap EXIT riêng —
# một script chỉ có một trap EXIT).

# Engine viết theo ngữ nghĩa byte của mawk: length/substr/index đếm byte, tolower chỉ đổi ASCII.
# awk khác ở locale UTF-8 đếm theo ký tự (gawk) hoặc lỗi "towc: multibyte conversion failure" khi
# substr cắt giữa ký tự (awk của macOS) — chạy với LC_ALL=C thì mọi máy cùng một nghĩa. Chữ
# tiếng Việt vẫn đi qua nguyên byte. Mọi script của tools/ nạp file này trước khi chạy gì khác.
LC_ALL=C; export LC_ALL

KQ_TEN=""; KQ_DS=""; KQ_DON=""

kq_khai() {
  KQ_TEN="$1"; shift
  KQ_DS=$(printf '%s\n' "$@")
  trap 'kq_in $?' EXIT
}

kq_don() { KQ_DON="$1"; }

kq_in() {
  _kq_ma="$1"
  [ -n "$KQ_DON" ] && eval "$KQ_DON"
  _kq_co=""
  {
    printf '\nResult: %s\n' "$KQ_TEN"
    while IFS= read -r _kq_d; do
      [ -n "$_kq_d" ] || continue
      if [ "${_kq_d%%=*}" = "$_kq_ma" ]; then
        printf '  [x] %s\n' "${_kq_d#*=}"; _kq_co=1
      else
        printf '  [ ] %s\n' "${_kq_d#*=}"
      fi
    done <<EOF
$KQ_DS
EOF
    [ -n "$_kq_co" ] || printf '  [x] UNEXPECTED ERROR — xem thông báo phía trên\n'
  } >&2
  trap - EXIT
  exit "$_kq_ma"
}
