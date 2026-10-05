#!/usr/bin/env sh
# Đường dẫn repo và cấu hình — do wrapper `aw` truyền vào qua biến môi trường.
# Tool KHÔNG tự suy chúng từ vị trí của chính nó: engine nằm trong cache
# (~/.agent-workflow/engine/<version>/), không nằm trong repo đích.
#
#   AW_REPO     gốc worktree đang làm (git rev-parse --show-toplevel)
#   AW_CONFIG   thư mục cấu hình của bản clone: $(git rev-parse --git-common-dir)/agent-workflow
#               — conventions.md, config.sh; dùng chung cho mọi worktree
#   AW_ENGINE   thư mục engine (bản cài của version đang chạy)
#
# Artifact của việc nằm ở $AW_REPO/.agent-workflow/<tên-branch>/ (artifact_dir
# trong workflow.yaml).

MT_ART_DIR=".agent-workflow"

# mt_dat [HERE] -> đặt MT_REPO, MT_ART (tuyệt đối), MT_CONV, MT_CH. Thiếu biến
# thì dừng (mã 9): không đoán đường dẫn từ vị trí của tool.
mt_dat() {
  if [ -z "${AW_REPO:-}" ] || [ -z "${AW_CONFIG:-}" ]; then
    echo "LỖI: thiếu AW_REPO hoặc AW_CONFIG — chạy qua wrapper aw (vd: aw feature, aw check …)." >&2
    exit 9
  fi
  MT_REPO="$AW_REPO"; MT_ART="$AW_REPO/$MT_ART_DIR"
  MT_CONV="$AW_CONFIG/conventions.md"; MT_CH="$AW_CONFIG/config.sh"
}
