#!/usr/bin/env sh
# Version của engine là ngày phát hành YYYY.MM.DD (tháng, ngày có số 0 đứng đầu),
# vd 2026.10.06. Git tag trùng đúng chuỗi đó, không có tiền tố "v". So version:
# khớp chính xác cả chuỗi — không suy "mới hơn / tương thích" từ con số.
#
# ver_hop_le <chuỗi> -> 0 nếu đúng dạng YYYY.MM.DD, tháng 01–12, ngày 01–31.
# bin/aw chép lại hàm này (wrapper phải chạy một mình, không nạp được lib).
ver_hop_le() {
  case "$1" in [0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]) ;; *) return 1 ;; esac
  __vh_m=${1#*.}; __vh_m=${__vh_m%.*}
  case "$__vh_m" in 0[1-9]|1[0-2]) ;; *) return 1 ;; esac
  case "${1##*.}" in 0[1-9]|[12][0-9]|3[01]) ;; *) return 1 ;; esac
}
