# Nạp config.sh của bản clone ($AW_CONFIG/config.sh).
#
#   . "$HERE/lib/config.sh"
#   ch_nap "$file"        # source file rồi điền tên khoá mới từ tên khoá cũ
#
# Từ 2026.10.21 khoá đổi sang tiếng Anh. config.sh dùng chung cho mọi version
# engine trong một bản clone (việc cũ ghim engine cũ), nên engine mới phải đọc
# được file còn tên cũ — khoá mới thắng nếu khai cả hai:
#   LENH_KIEM_THU          → TEST_CMD
#   LENH_KIEM_TRA_BAO_MAT  → SECURITY_CMDS
#   SO_LAN_DO_TOI_DA       → MAX_RED_RUNS
#   LENH_DO_HIEU_NANG      → PERF_CMD
#   LENH_CHUAN_BI_WT       → WORKTREE_SETUP_CMD

CH_KHOA_CU="LENH_KIEM_THU=TEST_CMD LENH_KIEM_TRA_BAO_MAT=SECURITY_CMDS SO_LAN_DO_TOI_DA=MAX_RED_RUNS LENH_DO_HIEU_NANG=PERF_CMD LENH_CHUAN_BI_WT=WORKTREE_SETUP_CMD"

ch_nap() {
  [ -f "$1" ] || return 0
  . "$1"
  TEST_CMD=${TEST_CMD:-${LENH_KIEM_THU:-}}
  SECURITY_CMDS=${SECURITY_CMDS:-${LENH_KIEM_TRA_BAO_MAT:-}}
  MAX_RED_RUNS=${MAX_RED_RUNS:-${SO_LAN_DO_TOI_DA:-}}
  PERF_CMD=${PERF_CMD:-${LENH_DO_HIEU_NANG:-}}
  WORKTREE_SETUP_CMD=${WORKTREE_SETUP_CMD:-${LENH_CHUAN_BI_WT:-}}
}

# ch_khoa_cu <file> -> mỗi dòng "<khoá cũ> → <khoá mới>" cho khoá cũ còn khai trong file.
ch_khoa_cu() {
  [ -f "$1" ] || return 0
  for _p in $CH_KHOA_CU; do
    grep -q "^[[:space:]]*${_p%%=*}=" "$1" && printf '%s → %s\n' "${_p%%=*}" "${_p#*=}"
  done
  return 0
}
