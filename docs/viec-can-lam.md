# Việc cần làm — phase 01-spec

> Ghi chú tạm cho người phát triển engine, không phải tài liệu dùng. Việc đã làm xem `CHANGELOG.md`.
> Xoá file này khi các mục dưới đã xong hoặc đã quyết định bỏ.

## Còn lại

### 1. Lưu câu trích nguyên văn cho mỗi YC — cần chốt định dạng trước

Phase 01 bảo agent trích nguyên văn nguồn, nhưng mẫu `spec.md` không có chỗ ghi câu trích nên bước
này không để lại dấu vết. Đề xuất thêm `- Quote: > "…"` dưới mỗi YC.

- Người duyệt so YC với câu gốc ngay trong spec.
- Nguồn `[FILE]` (kể cả lời người `[HUMAN]` nằm trong `intake.md`): máy kiểm được câu trích có thật
  trong file nguồn bằng `grep -F` → thu hẹp điểm yếu 3 trong `docs/kien-truc.md`. Confluence/Jira:
  chỉ giúp người đọc.
- Cần quyết: bắt buộc hay tuỳ chọn; một hay nhiều câu trích; chuẩn hoá khoảng trắng/xuống dòng khi
  so khớp thế nào.

### 2. Gợi ý nhãn `Risk` bằng từ khoá

Khoá mới `high_risk_keywords` trong `conventions.md`; spec ghi `Risk: normal` mà chứa từ khoá thì
**cảnh báo** (không chặn — từ khoá hay báo nhầm).

### 3. Đồng bộ thuật ngữ trong tài liệu cũ

`docs/huong-dan.md`, `docs/kien-truc.md`, README và output `aw` còn dùng từ dịch ("điểm mù", "lỗi
thời", "phát hiện"…). Đổi sang thuật ngữ trong `workflow/rules/terms.md`. Nhãn `aw` mà checker/test
khớp đúng chữ phải đổi cùng test trong một commit.

## Ngoài phạm vi (luật mới, cần quyết định độ chặt)

`aw check spec` hiện vẫn **cho qua**: `Source: [JIRA]` không có mã issue; `[INFERRED]` không ghi lý
do; nguồn của YC không có trong `## Input` của `intake.md`.
