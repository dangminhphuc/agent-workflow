#!/usr/bin/env sh
# Đường dẫn repo và cấu hình — do wrapper `aw` truyền vào qua biến môi trường.
# Tool KHÔNG tự suy chúng từ vị trí của chính nó: engine nằm trong cache
# (~/.agent-workflow/engine/<version>/), không nằm trong repo đích.
#
#   AW_REPO     gốc worktree đang làm (git rev-parse --show-toplevel)
#   AW_CONFIG   thư mục cấu hình của bản clone: $(git rev-parse --git-common-dir)/agent-workflow
#               — config.sh, conventions.md của bản clone; dùng chung cho mọi worktree.
#               Quy ước của repo nằm trong git (QU_DUONG_DAN, tools/lib/md.sh);
#               bản clone chỉ ghi đè khoá của máy.
#   AW_ENGINE   thư mục engine (bản cài của version đang chạy)
#
# Artifact của việc nằm ở $AW_REPO/<TM_VIEC>/<tên-branch>/; thư mục cục bộ của
# engine là $AW_REPO/<TM_CU>/ (tools/lib/md.sh — script phải nạp md.sh trước mt_dat).

# mt_dat [HERE] -> đặt MT_REPO, MT_ART_DIR, MT_ART (tuyệt đối), MT_CU (tuyệt đối),
# MT_CONV, MT_CH. Thiếu biến thì dừng (mã 9): không đoán đường dẫn từ vị trí của tool.
mt_dat() {
  if [ -z "${AW_REPO:-}" ] || [ -z "${AW_CONFIG:-}" ]; then
    echo "LỖI: thiếu AW_REPO hoặc AW_CONFIG — chạy qua wrapper aw (vd: aw feature, aw check …)." >&2
    exit 9
  fi
  [ -n "${TM_VIEC:-}" ] || { echo "LỖI nội bộ: chưa nạp tools/lib/md.sh trước mt_dat." >&2; exit 9; }
  MT_ART_DIR=$TM_VIEC
  MT_REPO="$AW_REPO"; MT_ART="$AW_REPO/$TM_VIEC"; MT_CU="$AW_REPO/$TM_CU"
  MT_CONV="$AW_CONFIG/conventions.md"; MT_CH="$AW_CONFIG/config.sh"
  # conventions.md hiệu lực (qu_hieu_luc, tools/lib/md.sh): script đọc quy ước đã
  # source md.sh; script không đọc (vd hook guard: MT_BO_QU=1) không tốn bước này.
  if [ "${MT_BO_QU:-}" != 1 ] && command -v qu_hieu_luc >/dev/null 2>&1; then qu_hieu_luc "$AW_REPO" >/dev/null; MT_CONV=$QU_HL; fi
}
