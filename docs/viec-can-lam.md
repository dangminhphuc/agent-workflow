# Việc cần làm — phase 01-spec

> Ghi chú tạm cho người phát triển engine, không phải tài liệu dùng. Việc đã làm xem `CHANGELOG.md`.
> Xoá file này khi các mục dưới đã xong hoặc đã quyết định bỏ.

## Còn lại

### 1. Gợi ý nhãn `Risk` bằng từ khoá

Khoá mới `high_risk_keywords` trong `conventions.md`; spec ghi `Risk: normal` mà chứa từ khoá thì
**cảnh báo** (không chặn — từ khoá hay báo nhầm).

### 3. Đồng bộ thuật ngữ trong tài liệu cũ

`docs/huong-dan.md`, `docs/kien-truc.md`, README và output `aw` còn dùng từ dịch ("điểm mù", "lỗi
thời", "phát hiện"…). Đổi sang thuật ngữ trong `workflow/rules/terms.md`. Nhãn `aw` mà checker/test
khớp đúng chữ phải đổi cùng test trong một commit.

## Ngoài phạm vi (luật mới, cần quyết định độ chặt)

`aw check spec` hiện vẫn **cho qua**: `Source: [JIRA]` không có mã issue; `[INFERRED]` không ghi lý
do; nguồn của YC không có trong `## Input` của `intake.md`.
