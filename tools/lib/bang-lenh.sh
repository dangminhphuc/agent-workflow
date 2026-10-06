#!/usr/bin/env sh
# Bảng tên checker của `aw check <tên>` → script trong tools/.
# Một nguồn duy nhất: bin/aw-engine dùng để chạy, adapter dùng để kiểm
# exit_machine trong frontmatter phase (aw check <tên>) có thật.

BL_CHECKERS="intake spec design plan implement review repro perf"

# bl_checker <tên> -> tên file script (mã 1 nếu không có)
bl_checker() {
  case "$1" in
    intake)    echo kiem-tra-tiep-nhan.sh ;;
    spec)      echo kiem-tra-truy-vet.sh ;;
    design)    echo kiem-tra-thiet-ke.sh ;;
    plan)      echo kiem-tra-ke-hoach.sh ;;
    implement) echo kiem-tra-hien-thuc.sh ;;
    review)    echo kiem-tra-ra-soat.sh ;;
    repro)     echo kiem-tra-tai-hien.sh ;;
    perf)      echo kiem-tra-hieu-nang.sh ;;
    *) return 1 ;;
  esac
}
