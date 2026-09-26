---
based_on: []
---

# Thiết kế kỹ thuật — <TÊN TÍNH NĂNG>

> Technical Design Document, sinh bởi phase `02-design`. Output duy nhất của thiết kế.
> `based_on` do `tools/cap-nhat-based-on.sh` ghi — không sửa tay.
> Mục không áp dụng ghi `Không áp dụng: <lý do>`, không bỏ trống.

## Bối cảnh code hiện có

| Module / file | Vai trò hiện tại | Sẽ đụng tới thế nào |
|---|---|---|
| | | |

Quy ước sẵn có phải tuân theo:
- <...>

## Quyết định (D-xx)

Mỗi lựa chọn mà người khác có thể chọn khác. Người duyệt **từng** D. Mục này được
phép rỗng — khi đó ghi "Không có quyết định cần duyệt." và xoá mẫu bên dưới.

### D-01 — <vấn đề cần quyết>

- tac_gia: `<nguoi | agent>`
- Trạng thái: `đề xuất`   <!-- đề xuất | đã duyệt | mở lại — CHỈ NGƯỜI đổi sang đã duyệt -->
- Phương án A: <...> — được: <...> / mất: <...>
- Phương án B: <...> — được: <...> / mất: <...>
- Chọn: <A> — vì <...>
- Khó đảo ngược vì: <...>
<!-- Khi mở lại: đổi Trạng thái thành `mở lại` và thêm dòng
- Lý do mở lại: <...> -->
<!-- Mode 2 (tac_gia: nguoi): agent không sửa mục này, chỉ thêm
- Phản biện (agent): <...> -->

## Mô hình dữ liệu

Dựa trên: <D-xx, nếu có>

<Bảng/entity, cột, ràng buộc, di trú. ERD bằng Mermaid:>

```mermaid
erDiagram
```

## Contract / API

Dựa trên: <D-xx, nếu có>

<Endpoint / hàm công khai / sự kiện: đầu vào, đầu ra, lỗi.>

## Flow

<Luồng chính và luồng lỗi. Sequence / state bằng Mermaid.>

```mermaid
sequenceDiagram
```

## Phi chức năng

<Hiệu năng, bảo mật, khả năng quan sát, tương thích ngược — kèm số liệu.>

## Chiến lược test

<Mức test (unit/integration/e2e) cho từng phần; YC nào chỉ kiểm chứng thủ công và vì sao.>

## Ánh xạ YC

Mọi YC trong `spec.md` phải có mặt ở đây.

| YC | Mục thiết kế đáp ứng |
|---|---|
| YC-001 | § Contract / API |
