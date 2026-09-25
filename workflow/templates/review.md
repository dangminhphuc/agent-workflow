# Rà soát — <TÊN TÍNH NĂNG>

> Sinh bởi phase `04-review`, chạy bằng ngữ cảnh sạch.

## Lăng kính 1 — Đúng đặc tả

Mọi mã `YC` trong `spec.md` phải có mặt ở bảng này.

| Mã | Kết luận | Bằng chứng trong code | Ghi chú |
|---|---|---|---|
| YC-001 | đạt | `file.ts:42` | |
| YC-002 | chờ xác nhận | `file.ts:88` | Giả định tạm chưa được xác nhận |

Kết luận hợp lệ: `đạt` / `đạt một phần` / `chưa đạt` / `chờ xác nhận`.

## Lăng kính 2 — Đúng phạm vi

- Thay đổi không thuộc task nào: <liệt kê, hoặc "không có">
- Task đánh dấu xong nhưng diff không có dấu vết: <...>
- Phát sinh bị xử lý lặng lẽ: <...>

## Lăng kính 3 — Chất lượng

### [Chặn] <tiêu đề>
- Vị trí: `file:dòng`
- Vấn đề: <...>
- Kịch bản hỏng: <đầu vào cụ thể → kết quả sai>

### [Nên sửa] <tiêu đề>
- Vị trí: `file:dòng`
- Vấn đề: <...>

### [Góp ý] <tiêu đề>
- Vị trí: `file:dòng`

## Kết luận

- Số finding mức `Chặn`: <n>
- Merge được chưa: <chưa / được sau khi xử lý các mục Chặn>
