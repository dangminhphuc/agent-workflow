#!/usr/bin/env sh
# ĐÃ BỎ từ engine 2026.10.6 — thay bằng aw upgrade <version>. Chỉ in hướng dẫn.
#
# Bộ cài cũ đồng bộ bằng cách chép bản mới vào repo đích rồi commit vào base.
# dong-bo.sh cũ trong repo đích clone repo này và chạy tools/cai-dat.sh của bản
# mới — nay script đó chỉ in hướng dẫn chuyển đổi, không ghi gì vào repo đích.

main() {
  ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
  if [ -f "$ROOT/tools/lib/ket-qua.sh" ]; then
    . "$ROOT/tools/lib/ket-qua.sh"
    kq_khai dong-bo.sh "3=ĐÃ BỎ — dùng aw upgrade, làm theo hướng dẫn phía trên"
  fi
  cat <<EOT
tools/dong-bo.sh đã bỏ từ engine 2026.10.6. Không có gì được đổi.

Nâng cấp engine (không commit gì vào repo đích):
  aw upgrade <YYYY.M.D>

Việc đang làm vẫn chạy bằng version ghi ở dòng Engine: trong intake.md của nó.
Repo còn bộ cài cũ: chạy aw init --from-legacy trước. Xem README.md, mục "Nâng cấp".
EOT
  return 3
}

main "$@"; exit $?
