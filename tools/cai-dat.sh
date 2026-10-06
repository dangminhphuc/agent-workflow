#!/usr/bin/env sh
# ĐÃ BỎ từ engine 2026.10.06 — thay bằng wrapper aw. Chỉ in hướng dẫn chuyển đổi.
#
# Bộ cài cũ chép quy trình vào repo đích và phải commit vào base — không làm
# được khi main/develop/uat là protected branch. Từ bản 2026.10.06: engine có version nằm
# trong ~/.agent-workflow/engine/<version>/, cấu hình nằm trong
# .git/agent-workflow/ của từng bản clone, không commit gì vào repo đích.

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/tools/lib/ket-qua.sh"
kq_khai cai-dat.sh "3=ĐÃ BỎ — dùng aw, làm theo hướng dẫn phía trên"
V=$(cat "$ROOT/VERSION" 2>/dev/null)
cat <<EOT
tools/cai-dat.sh đã bỏ từ engine 2026.10.06. Không có gì được cài.

Cài wrapper aw (một lần cho cả máy):
  curl -fsSL https://github.com/dangminhphuc/agent-workflow/releases/download/$V/aw -o ~/.local/bin/aw
  chmod +x ~/.local/bin/aw

Repo chưa từng cài — trong repo đích:
  aw init --test-cmd "npm test"

Repo đã có bộ cài cũ (.agent-workflow/.quy-trinh/) — trong repo đích:
  aw init --from-legacy
  (chuyển conventions.md, cau-hinh.sh vào .git/agent-workflow/; không xoá, không commit gì)

Xem README.md, mục "Cài đặt" và "Chuyển từ bộ cài cũ".
EOT
exit 3
