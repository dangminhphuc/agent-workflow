---
based_on: []
---

# Kế hoạch — <TÊN TÍNH NĂNG>

> Sinh bởi phase `03-plan`, chỉ quản lý thực thi — mọi lựa chọn kỹ thuật nằm ở
> `tdd.md`. Phase `04-implement` cập nhật trạng thái task ngay tại file này.
> `based_on` do `tools/cap-nhat-based-on.sh` ghi — không sửa tay.

## Task

### T-01 — <tiêu đề>
- Phủ: `YC-001`
- Dựa trên: `D-01`
- Theo: `tdd.md` § Contract / API
- Phụ thuộc: không
- File dự kiến: `src/<...>` `test/<...>`
- Cách kiểm chứng: `<lệnh cụ thể>` → `<kết quả mong đợi>`
- Đứng trên giả định tạm: không
- Trạng thái: `[ ]`

### T-02 — <tiêu đề>
- Phủ: `YC-002`
- Theo: `tdd.md` § Mô hình dữ liệu
- Phụ thuộc: T-01
- File dự kiến: `<...>`
- Cách kiểm chứng: `<...>`
- Đứng trên giả định tạm: **có** — `open-questions.md` § YC-002
- Trạng thái: `[ ]`

> **Trạng thái task:** `[ ]` chưa làm · `[~]` đang làm · `[x]` xong.
> Còn `[~]` nào thì phase 04 chưa đạt điều kiện ra.
> `File dự kiến` cho phép glob; `*` khớp cả `/`.

## Hoãn lại

Mã `YC` không có task nào phủ, kèm lý do. Để trống mục này mà vẫn thiếu phủ thì
kiểm tra bằng máy sẽ fail.

| Mã | Lý do hoãn |
|---|---|
| | |

## Kiểm chứng thủ công

YC không test tự động được, kèm lý do. Không ghi ở đây mà cũng không có test gắn
tag `covers:` thì `/implement` cảnh báo, `/review` chặn.

| Mã | Lý do không test tự động được |
|---|---|
| | |

## Test cũ bị sửa

CHỈ refactor / perf. Test có sẵn trên nhánh gốc mà bị sửa hay đổi tên phải khai ở
đây (đường dẫn trong backtick) kèm lý do — người rà soát đọc diff để xác nhận chỉ
đổi import/cấu trúc, không đổi assertion. **Xoá** test cũ thì bị chặn, không khai được.

| File test | Lý do sửa |
|---|---|
| | |

## Nâng dependency

CHỈ chore. Diff đụng `mau_file_dependency` thì phải khai từng thư viện. Chỉ
`vá | minor`; nâng major là việc `refactor` riêng.

| Thư viện | Cũ → mới | Mức |
|---|---|---|
| | | |

## Phát sinh

Do `04-implement` ghi khi gặp điều kế hoạch chưa lường. File ngoài "File dự
kiến" phải ghi ở đây (trong backtick) kèm lý do.

| Task | Phát sinh gì | File đụng thêm | Đã xử lý thế nào |
|---|---|---|---|
| | | | |
