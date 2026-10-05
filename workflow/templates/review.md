# Rà soát — <TÊN TÍNH NĂNG>

> Sinh bởi phase `05-review`, chạy bằng ngữ cảnh sạch.

## Lăng kính 1 — Đúng đặc tả

Mọi mã `YC` trong `spec.md` phải có mặt ở bảng này.

| Mã | Kết luận | Bằng chứng trong code | Ghi chú |
|---|---|---|---|
| YC-001 | đạt | `file.ts:42` | |
| YC-002 | chờ xác nhận | `file.ts:88` | Giả định tạm chưa được xác nhận |

Kết luận hợp lệ: `đạt` / `đạt một phần` / `chưa đạt` / `chờ xác nhận`.

## Theo loại việc

<!-- bugfix — BẮT BUỘC, máy chặn nếu thiếu. Máy chỉ biết test tái hiện đã đỏ;
     bạn xác nhận nó đỏ ĐÚNG VÌ BUG, không phải vì lỗi biên dịch / thiếu hàm. -->
- Test tái hiện đỏ vì: <trích dòng lỗi trong tai-hien.md>

<!-- refactor / perf: với từng file ở "Test cũ bị sửa" của plan.md, xác nhận diff chỉ
     đổi import/cấu trúc, không đổi assertion.
     perf: đọc do-hieu-nang.md, kết luận YC hiệu năng đạt/chưa đạt theo số đo.
     chore: xác nhận mức "vá | minor" ở "Nâng dependency" là đúng.
     Loại việc khác: xoá mục này. -->

## Lăng kính 2 — Đúng thiết kế và phạm vi

- Lệch D-xx / contract / mô hình dữ liệu trong `tdd.md`: <liệt kê, hoặc "không có">
- Thay đổi không thuộc task nào: <...>
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

## Cảnh báo dồn về

Lỗi "Cảnh báo chưa xử lý" từ `aw check review` (YC chưa có test, diff ngoài
phạm vi, artifact lỗi thời). Còn mục nào thì review không đạt.

- <...>

## Kết luận

- Số finding mức `Chặn`: <n>
- Merge được chưa: <chưa / được sau khi xử lý các mục Chặn>
