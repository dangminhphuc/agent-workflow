# Changelog

Mỗi bản phát hành là một git tag `vX.Y.Z` của repo này. Repo đích ghim version
cần dùng (xem README, mục "Nâng cấp"); một việc đã bắt đầu thì chạy hết bằng
version ghi trong `intake.md` của nó.

So version theo luật **khớp chính xác `X.Y.Z`** — không có "tương thích ngược"
ngầm giữa các bản.

## [2.0.0] — chưa phát hành

Bản major: đổi cách cài, phá tương thích với bộ cài 1.x.

### Thay đổi
- Engine có version, phát hành theo tag kèm `SHA256SUMS` (`tools/dong-goi.sh`).
