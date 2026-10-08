#!/usr/bin/env sh
# Bảng tên checker của `aw check <tên>` → script trong tools/.
# Một nguồn duy nhất: bin/aw-engine dùng để chạy, adapter dùng để kiểm
# exit_machine trong frontmatter phase (aw check <tên>) có thật.

BL_CHECKERS="intake spec design plan implement security review repro perf ship"

# Phase đọc quy tắc riêng của repo (khoá rules_<phase> trong conventions.md,
# `aw rules <phase>`). Adapter dùng để thêm bước đọc vào đúng các phase này.
BL_QUY_TAC="spec design plan implement review"

# bl_checker <tên> -> tên file script (mã 1 nếu không có)
bl_checker() {
  case "$1" in
    intake)    echo check-intake.sh ;;
    spec)      echo check-spec.sh ;;
    design)    echo check-design.sh ;;
    plan)      echo check-plan.sh ;;
    implement) echo check-implement.sh ;;
    security)  echo check-security.sh ;;
    review)    echo check-review.sh ;;
    repro)     echo check-repro.sh ;;
    perf)      echo check-perf.sh ;;
    ship)      echo check-ship.sh ;;
    *) return 1 ;;
  esac
}
