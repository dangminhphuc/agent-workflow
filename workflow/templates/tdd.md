---
based_on: []
---

# Technical Design — <TÊN TÍNH NĂNG>

## Contents

<!-- Mục lục — máy sinh bằng `aw toc <thư-mục-feature>`, không viết tay. Mỗi heading ## / ### một link. -->

## Existing code

| Module / file | Current role | Planned change |
|---|---|---|
| | | |

Conventions to follow:
- <...>

## Target structure

Based on: <DEC-xxx, nếu có>

<Cấu trúc module/thành phần trước → sau: thêm, tách, gộp, bỏ gì; ranh giới và phụ thuộc giữa
chúng. Tính năng không đổi cấu trúc thì ghi "Not applicable: <lý do>". Sơ đồ bằng Mermaid:>

```mermaid
flowchart LR
```

## Decisions (DEC-xxx)

Mỗi lựa chọn mà người khác có thể chọn khác. Người duyệt **từng** DEC bằng cách tick
ô "Approved by human" của DEC đó. Mục này được phép rỗng — khi đó ghi "Không có
quyết định cần duyệt." và xoá mẫu bên dưới.

### DEC-001 — <vấn đề cần quyết>

- Author: `<human | agent>`
- Option A: <...> — pros: <...> / cons: <...>
- Option B: <...> — pros: <...> / cons: <...>
- Choice: <A> — vì <...>
- Hard to reverse because: <...>
- [ ] **Approved by human**   <!-- CHỈ NGƯỜI tick [x]; agent không bao giờ tick. Máy ghi approval hash (hash của DEC) cạnh tick; DEC đổi sau đó thì bị chặn tới khi người duyệt lại -->
<!-- Khi mở lại: bỏ tick và thêm dòng
- Reopen reason: <...> -->
<!-- Mode 2 (Author: human): agent không sửa mục này, chỉ thêm
- Critique (agent): <...> -->
<!-- Durable knowledge (tuỳ chọn, NGƯỜI quyết bằng cách duyệt DEC này):
- Promote: adr                  nâng DEC thành ADR khi hiện thực (aw adr promote); mặc định: no
- Scope: `src/<module>/*`       phần code ADR ràng buộc — bắt buộc khi Promote: adr
- Supersedes: ADR-NNNN         DEC đi ngược một ADR accepted: ghi rõ, ADR cũ thành superseded -->

## Data model

Based on: <DEC-xxx, nếu có>

<Bảng/entity, cột, ràng buộc, di trú. ERD bằng Mermaid:>

```mermaid
erDiagram
```

## Contract / API

Based on: <DEC-xxx, nếu có>

<Endpoint / hàm công khai / sự kiện: đầu vào, đầu ra, lỗi.>

## Flow

<Luồng chính và luồng lỗi. Sequence / state bằng Mermaid.>

```mermaid
sequenceDiagram
```

## Non-functional

<Hiệu năng, bảo mật, khả năng quan sát, tương thích ngược — kèm số liệu.>

## Rollout & rollback

Based on: <DEC-xxx, nếu có>

<Thứ tự triển khai, feature flag, các bước di trú dữ liệu, giai đoạn chạy song song cũ/mới,
cách quay lui từng bước — và bước nào KHÔNG quay lui được.>

## Test strategy

<Mức test (unit/integration/e2e) cho từng phần; REQ nào chỉ kiểm chứng thủ công và vì sao.>

## REQ mapping

Mọi REQ trong `spec.md` phải có mặt ở đây.

| REQ | Design section |
|---|---|
| REQ-001 | § Contract / API |
