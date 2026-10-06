#!/usr/bin/env sh
# Version của engine là YYYY.M.N: năm, tháng phát hành, và N = số thứ tự bản
# phát hành trong tháng đó (1, 2, 3, … — sang tháng mới đếm lại từ 1). Không số 0
# đứng đầu ở tháng lẫn N, vd 2026.10.8, 2026.11.1. Git tag trùng đúng chuỗi đó,
# không có tiền tố "v". So version: khớp chính xác cả chuỗi — không suy "mới hơn
# / tương thích" từ con số.
#
# (Trước 2026.10.8, N là ngày phát hành — các tag 2026.10.6, 2026.10.7 vẫn hợp lệ
# và tháng 10/2026 đếm tiếp từ đó.)
#
# ver_hop_le <chuỗi> -> 0 nếu đúng dạng YYYY.M.N: năm 4 chữ số, tháng 1–12, N là
# số nguyên dương; không số 0 đứng đầu (2026.10.8 đúng; 2026.10.08, 2026.10.0 sai).
# bin/aw chép lại hàm này (wrapper phải chạy một mình, không nạp được lib).
ver_hop_le() {
  case "$1" in [0-9][0-9][0-9][0-9].*.*) ;; *) return 1 ;; esac
  __vh_r=${1#*.}
  case "${__vh_r%%.*}" in [1-9]|1[0-2]) ;; *) return 1 ;; esac
  case "${__vh_r#*.}" in [1-9]|[1-9]*[0-9]) ;; *) return 1 ;; esac
  case "${__vh_r#*.}" in *[!0-9]*) return 1 ;; esac
}
