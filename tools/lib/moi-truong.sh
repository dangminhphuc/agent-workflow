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

# mt_dat <HERE> -> đặt MT_REPO, MT_ART (tuyệt đối), MT_CONV, MT_CH
mt_dat() {
  if [ -n "${AW_REPO:-}" ]; then
    MT_REPO="$AW_REPO"; MT_ART="$AW_REPO/$MT_ART_DIR"
  else
    # TẠM — bộ cài 1.x: tool nằm ở <repo>/.agent-workflow/.quy-trinh/tools/. Bỏ khi có aw init --from-legacy.
    MT_ART=$(CDPATH= cd -- "$1/../.." && pwd); MT_REPO=$(dirname "$MT_ART")
  fi
  if [ -n "${AW_CONFIG:-}" ]; then
    MT_CONV="$AW_CONFIG/conventions.md"; MT_CH="$AW_CONFIG/config.sh"
  else
    MT_CONV="$MT_ART/conventions.md"; MT_CH="$MT_ART/.quy-trinh/cau-hinh.sh"
  fi
}
