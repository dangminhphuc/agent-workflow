### Thay đổi
- **Nhãn máy và heading của `aw` đổi sang tiếng Anh, ngắn.** Ví dụ `ĐẠT` / `KHÔNG ĐẠT` → `PASS` / `FAIL`,
  `ĐÃ DUYỆT` / `CHƯA DUYỆT` → `APPROVED` / `NOT APPROVED`, `XANH` / `ĐỎ` → `GREEN` / `RED`,
  `Kết quả` / `Cần bạn` / `Tiếp theo` → `Result` / `Needs you` / `Next`. Bảng đầy đủ trong
  `docs/superpowers/specs/2026-10-27-nhan-tieng-anh-design.md` §3. Phần mô tả sau dấu ` — ` vẫn là tiếng Việt;
  mã thoát không đổi.
- **Artifact do máy ghi đổi dòng kết quả.** `security-results.md` ghi `- Result: **GREEN**` (trước:
  `- Kết quả: **XANH**`). Job đang chạy dở: chạy lại `aw check security` (hoặc `aw check implement`) trước
  khi `aw check review`, nếu không cổng review sẽ báo artifact cũ.
- **Tag đánh dấu đổi:** `[LỖI]` → `[ERROR]`, `[CẢNH BÁO]` → `[WARN]`, `[ĐÃ XỬ LÝ]` → `[HANDLED]`,
  nhóm heading của `aw pending` đổi sang tiếng Anh (`UNRATED`, `FOUND — BLOCKING`, `FOUND — WARN`).
  Nếu bạn có script tự đọc output `aw` bằng các chữ cũ, cập nhật script theo bảng trong spec.

### Nội bộ
- Test mới `tools/tests/01-fixture-engine-toc.sh`: mọi nhãn `kq_khai` phải là chữ ASCII, chặn tái phát nhãn tiếng Việt.
- Test và checker cũ cập nhật cùng lúc theo bảng ánh xạ; prompt sinh ra (`adapters/lib/common.sh`) và tài liệu cùng đổi.
