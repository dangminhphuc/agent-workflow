# Việc cần làm — phase 01-spec

> Ghi chú tạm. Xoá file này khi các mục dưới đã xong hoặc đã quyết định bỏ.

## Đã làm (2026-09-28)

- YC không có `Nguồn:` lọt qua khi có heading `###` phụ bên dưới.
- `open-questions.md` 0 byte làm lệch thứ tự file (spec, design; review đồng bộ).
- Kiểm chéo test ↔ YC im lặng khi chưa test nào gắn `covers:` (`cross-check.sh`).
- `spec.md` ghi `based_on: intake.md` → đổi intake sau khi viết spec thì review chặn.
- Gate duyệt spec — design (chore: plan) chặn khi chưa duyệt. (Nay là ô duyệt
  `- [ ] **Approved by human**` kèm dấu duyệt — xem docs/kien-truc.md.)
- Đối chiếu hai chiều `open-questions.md` ↔ `spec.md` (mục mồ côi, trạng thái lệch,
  đã trả lời mà trống "Trả lời").

## Đã làm (2026-10-03)

- Bảng nguồn có cột "Phiên bản" (version Confluence / `updated` Jira / sha).
- Checker chặn: YC thiếu tiêu chí chấp nhận hoặc `Ưu tiên`; spec thiếu
  "Ngoài phạm vi" / "Ràng buộc & phụ thuộc" / bảng mâu thuẫn hoặc để rỗng; mâu
  thuẫn không trỏ tới điểm mù hay nguồn đã chốt. Comment HTML trong spec không
  còn được tính là nội dung.
- Phase 01 có bước rà NFR theo nhóm, mục tuỳ chọn `## Thuật ngữ`, vai trò người
  dùng trong Bối cảnh. Plan cảnh báo khi hoãn YC `bắt buộc`.

## Đã làm (2026-10-04)

- Điểm mù có đúng ba `Mức chặn: chặn | chặn review | không chặn` (thay cho
  `Mức ảnh hưởng: toàn bộ thiết kế | cục bộ`; checker chặn nhãn cũ kèm hướng dẫn
  đổi). Chore: mức `chặn` chặn `plan` — trước đây chore không có cổng nào cho nó.
- Lệnh tiện ích `/open-questions` + `tools/liet-ke-cau-hoi.sh`: liệt kê điểm mù
  theo thứ tự phải chốt, agent dẫn người trả lời từng mục. Manifest đổi `import:`
  thành danh sách `commands:`.

## Còn lại

### 4. Lưu câu trích nguyên văn cho mỗi YC — cần chốt định dạng trước

Bước 2 của phase ("trích nguyên văn") không để lại dấu vết: mẫu spec không có chỗ
ghi câu trích. Đề xuất thêm `- Trích: > "…"` dưới mỗi YC.

- Người duyệt so YC với câu gốc ngay trong spec.
- Nguồn `[FILE]` (kể cả `[HUMAN]` nằm trong `intake.md`): máy kiểm được câu
  trích có thật trong file nguồn bằng `grep -F` → thu hẹp điểm yếu 3 trong
  `docs/kien-truc.md`. Confluence/Jira: chỉ giúp người đọc.
- Cần quyết: bắt buộc hay tuỳ chọn; một hay nhiều câu trích; chuẩn hoá khoảng
  trắng/xuống dòng khi so khớp thế nào.

### 6. Gợi ý nhãn `Risk` bằng từ khoá

Khoá mới `tu_khoa_rui_ro_cao` trong `conventions.md`; spec ghi `normal` mà chứa
từ khoá thì **cảnh báo** (không chặn — từ khoá hay báo nhầm).

## Ngoài phạm vi (luật mới, cần quyết định độ chặt)

Checker hiện vẫn **cho qua**: `Source: [JIRA]` không mã issue; `[INFERRED]` không
lý do; nguồn không có trong `intake.md`.
