# Việc cần làm — phase 01-spec

> Ghi chú tạm. Xoá file này khi các mục dưới đã xong hoặc đã quyết định bỏ.

## Đã làm (2026-09-28)

- YC không có `Nguồn:` lọt qua khi có heading `###` phụ bên dưới.
- `open-questions.md` 0 byte làm lệch thứ tự file (spec, design; review đồng bộ).
- Kiểm chéo test ↔ YC im lặng khi chưa test nào gắn `covers:` (`kiem-cheo.sh`).
- `spec.md` ghi `based_on: intake.md` → đổi intake sau khi viết spec thì review chặn.
- `Trạng thái spec: đề xuất | đã duyệt` — design (chore: plan) chặn khi chưa duyệt.
- Đối chiếu hai chiều `open-questions.md` ↔ `spec.md` (mục mồ côi, trạng thái lệch,
  đã trả lời mà trống "Trả lời").

## Còn lại

### 4. Lưu câu trích nguyên văn cho mỗi YC — cần chốt định dạng trước

Bước 2 của phase ("trích nguyên văn") không để lại dấu vết: mẫu spec không có chỗ
ghi câu trích. Đề xuất thêm `- Trích: > "…"` dưới mỗi YC.

- Người duyệt so YC với câu gốc ngay trong spec.
- Nguồn `[FILE]` (kể cả `[NGƯỜI-DÙNG]` nằm trong `intake.md`): máy kiểm được câu
  trích có thật trong file nguồn bằng `grep -F` → thu hẹp điểm yếu 3 trong
  `docs/kien-truc.md`. Confluence/Jira: chỉ giúp người đọc.
- Cần quyết: bắt buộc hay tuỳ chọn; một hay nhiều câu trích; chuẩn hoá khoảng
  trắng/xuống dòng khi so khớp thế nào.

### 5. Phiên bản của nguồn ngoài

Bảng nguồn chỉ có "Ngày đọc". Ghi thêm version page Confluence / `updated` của
issue Jira (MCP Atlassian trả về sẵn) để biết spec dựa trên bản nào.

### 6. Gợi ý nhãn `Mức rủi ro` bằng từ khoá

Khoá mới `tu_khoa_rui_ro_cao` trong `conventions.md`; spec ghi `thường` mà chứa
từ khoá thì **cảnh báo** (không chặn — từ khoá hay báo nhầm).

## Ngoài phạm vi (luật mới, cần quyết định độ chặt)

Checker hiện vẫn **cho qua**: `Nguồn: [JIRA]` không mã issue; `[SUY-RA]` không
lý do; nguồn không có trong `intake.md`; spec thiếu "Ngoài phạm vi" / "Tiêu chí
chấp nhận" / bảng mâu thuẫn.
