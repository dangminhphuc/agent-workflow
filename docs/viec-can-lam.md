# Việc cần làm — phase 01-spec

> Ghi chú tạm cho người phát triển engine, không phải tài liệu dùng. Việc đã làm xem `CHANGELOG.md`.
> Xoá file này khi các mục dưới đã xong hoặc đã quyết định bỏ.

## Còn lại

### 1. Gợi ý nhãn `Risk` bằng từ khoá

Khoá mới `high_risk_keywords` trong `conventions.md`; spec ghi `Risk: normal` mà chứa từ khoá thì
**cảnh báo** (không chặn — từ khoá hay báo nhầm).

## Mã định danh (sau khi đổi sang `REQ`/`DEC`/`FND`/`TSK`/`RFR`)

- **Cấp heading thống nhất** — PR riêng. Mã hiện nằm ở cấp khác nhau: `### REQ` trong `spec.md` nhưng
  `## REQ` trong `open-questions.md`, `## RFR` nhưng `### FND`. Đề xuất: mã luôn ở `###`, dưới một
  `##` của nhóm.
- **`FND` trùng giữa nhiều checker LLM** — chưa xảy ra (mới có checker design). `pending.sh` phải ghép
  tên file (`design-findings.md:FND-001`) để phân biệt. Thêm checker thứ hai thì cần tiền tố/namespace
  riêng hoặc một file findings chung.
- **Chặn mã sai dạng** — checker vẫn nhận `[0-9]+`, `REQ-1` hay `DEC-01` lọt qua. Chính xác nên có thể
  chặn ở checker của phase viết ra mã; cần quyết độ chặt.

## Ngoài phạm vi (luật mới, cần quyết định độ chặt)

`aw check spec` hiện vẫn **cho qua**: `Source: [JIRA]` không có mã issue; `[INFERRED]` không ghi lý
do; nguồn của REQ không có trong `## Input` của `intake.md`.
