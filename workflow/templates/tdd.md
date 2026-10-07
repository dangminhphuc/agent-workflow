---
based_on: []
---

# Technical Design — <TÊN TÍNH NĂNG>

> Technical Design Document, sinh bởi phase `02-design`. Output duy nhất của thiết kế.
> `based_on` do `aw based-on` ghi — không sửa tay.
> Mục không áp dụng ghi `Not applicable: <lý do>`, không bỏ trống.

## Existing code

| Module / file | Current role | Planned change |
|---|---|---|
| | | |

Conventions to follow:
- <...>

## Decisions (D-xx)

Mỗi lựa chọn mà người khác có thể chọn khác. Người duyệt **từng** D bằng cách tick
ô "Approved by human" của D đó. Mục này được phép rỗng — khi đó ghi "Không có
quyết định cần duyệt." và xoá mẫu bên dưới.

### D-01 — <vấn đề cần quyết>

- Author: `<human | agent>`
- Option A: <...> — pros: <...> / cons: <...>
- Option B: <...> — pros: <...> / cons: <...>
- Choice: <A> — vì <...>
- Hard to reverse because: <...>
- [ ] **Approved by human**   <!-- CHỈ NGƯỜI tick [x]; agent không bao giờ tick. Máy ghi dấu duyệt (hash của D) cạnh tick; D đổi sau đó thì bị chặn tới khi người duyệt lại -->
<!-- Khi mở lại: bỏ tick và thêm dòng
- Reopen reason: <...> -->
<!-- Mode 2 (Author: human): agent không sửa mục này, chỉ thêm
- Critique (agent): <...> -->

## Data model

Based on: <D-xx, nếu có>

<Bảng/entity, cột, ràng buộc, di trú. ERD bằng Mermaid:>

```mermaid
erDiagram
```

## Contract / API

Based on: <D-xx, nếu có>

<Endpoint / hàm công khai / sự kiện: đầu vào, đầu ra, lỗi.>

## Flow

<Luồng chính và luồng lỗi. Sequence / state bằng Mermaid.>

```mermaid
sequenceDiagram
```

## Non-functional

<Hiệu năng, bảo mật, khả năng quan sát, tương thích ngược — kèm số liệu.>

## Test strategy

<Mức test (unit/integration/e2e) cho từng phần; YC nào chỉ kiểm chứng thủ công và vì sao.>

## YC mapping

Mọi YC trong `spec.md` phải có mặt ở đây.

| YC | Design section |
|---|---|
| YC-001 | § Contract / API |
