#!/usr/bin/env sh
# Version của engine là ngày phát hành YYYY.M.D (tháng, ngày không có số 0 đứng đầu),
# vd 2026.10.6. Git tag trùng đúng chuỗi đó, không có tiền tố "v". So version:
# khớp chính xác cả chuỗi — không suy "mới hơn / tương thích" từ con số.
#
# ver_hop_le <chuỗi> -> 0 nếu đúng dạng YYYY.M.D: năm 4 chữ số, tháng 1–12, ngày
# 1–31, không số 0 đứng đầu (2026.10.6 đúng; 2026.10.06 sai).
# bin/aw chép lại hàm này (wrapper phải chạy một mình, không nạp được lib).
ver_hop_le() {
  case "$1" in [0-9][0-9][0-9][0-9].*.*) ;; *) return 1 ;; esac
  __vh_r=${1#*.}
  case "${__vh_r%%.*}" in [1-9]|1[0-2]) ;; *) return 1 ;; esac
  case "${__vh_r#*.}" in [1-9]|[12][0-9]|3[01]) ;; *) return 1 ;; esac
}
