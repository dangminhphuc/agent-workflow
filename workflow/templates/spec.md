---
based_on: []
---

# Đặc tả — <TÊN TÍNH NĂNG>

> Sinh bởi phase `01-spec`. Người sửa tay được; chạy lại phase sẽ cập nhật,
> không ghi đè trắng. `based_on` do `tools/cap-nhat-based-on.sh` ghi — không sửa tay.

- **Mức rủi ro:** `<cao | thường>`
- **Lý do:** <cao khi đụng tiền/hạch toán, tích hợp mới, schema lõi, hoặc khó đảo ngược>
- **Trạng thái spec:** `đề xuất`   <!-- đề xuất | đã duyệt — CHỈ NGƯỜI đổi sang đã duyệt; sửa nội dung thì agent đặt lại đề xuất -->

## Nguồn

| # | Loại | Định danh | Ngày đọc |
|---|---|---|---|
| 1 | Confluence | [Tên page](URL) | YYYY-MM-DD |
| 2 | Jira | [ABC-123](URL) | YYYY-MM-DD |

## Bối cảnh

<2–4 câu: vấn đề nghiệp vụ đang giải, cho ai.>

## Yêu cầu

<!-- Nguồn, Loại YC, Được bảo vệ bởi, Mục tiêu phải nằm ngay dưới "### YC-NNN".
Heading "###" khác (vd "### Ghi chú") đóng vùng YC; muốn chia nhỏ một YC thì dùng "####". -->

### YC-001 — <tiêu đề ngắn>

- Nguồn: `[CONFLUENCE]` [Tên page](URL) § Tên heading
- Mô tả: <yêu cầu, diễn đạt lại cho rõ>
- Tiêu chí chấp nhận:
  - [ ] <quan sát được từ bên ngoài, có số liệu nếu là yêu cầu phi chức năng>

### YC-002 — <tiêu đề ngắn>

- Nguồn: `[CẦN-HỎI]` → `open-questions.md` § YC-002
- Mô tả: <...>
- Giả định tạm: <đang hiểu thế nào để đi tiếp>
- Tiêu chí chấp nhận:
  - [ ] <...>

<!-- CHỈ refactor / perf: mỗi YC có thêm
- Loại YC: `giữ nguyên | cấu trúc | hiệu năng`   (hiệu năng: chỉ perf)
- Được bảo vệ bởi: `test/<file>.test.ts`         (YC giữ nguyên — file có sẵn trên nhánh gốc)
- Mục tiêu: p95 < 150 ms với 10k bản ghi         (YC hiệu năng — có số liệu)
Không có YC hành vi mới. -->

<!-- CHỈ bugfix: thêm mục dưới, bỏ comment
## Tái hiện lỗi

- Cách tái hiện: <các bước / đầu vào cụ thể>
- Hành vi sai: <điều đang xảy ra>
- Hành vi đúng: <điều phải xảy ra, theo nguồn nào>
-->

## Ngoài phạm vi

Những thứ **không** làm lần này. Mục này chặn phase sau làm quá tay.

- <...> — lý do: <...>

## Mâu thuẫn giữa các nguồn

| Nguồn A nói | Nguồn B nói | Đang xử lý thế nào |
|---|---|---|
| | | |

<Không có thì ghi "Không phát hiện mâu thuẫn.">
