---
id: ideation
name: Lên ý tưởng
summary: Tạo brief khi không có tài liệu thượng nguồn
required: false
when: không có tài liệu thượng nguồn (BRD/PRD/ticket)
inputs: []
outputs:
  - brief.md
exit_machine: []
exit_human:
  - Chủ repo xác nhận brief.md phản ánh đúng ý định
needs_clean_context: true
---

# Phase 00 — Lên ý tưởng  *(tuỳ chọn)*

## Khi nào chạy

**Chỉ khi không có tài liệu thượng nguồn.** Trong môi trường có BRD/PRD/ticket,
phase này bị bỏ qua — `01-spec` đọc thẳng nguồn thật.

Tồn tại để lấp một khoảng trống cụ thể: `01-spec` bị cấm bịa yêu cầu, nên khi
không có nguồn nào thì nó không có gì để làm. Phase này tạo ra nguồn đó, và
đánh dấu rõ rằng nguồn này đến từ người dùng chứ không phải tài liệu nghiệp vụ —
để nhãn truy vết ở `01-spec` không nói dối.

## Việc phải làm

1. Hỏi người dùng đủ để trả lời được: **giải quyết vấn đề gì, cho ai, dấu hiệu
   nào cho biết đã xong.**
2. Ghi lại nguyên văn câu trả lời vào `brief.md`, tách rõ *điều người dùng nói*
   với *điều agent suy ra*.
3. Nêu những gì còn chưa rõ — không tự lấp.

## Đầu ra

- `brief.md` — mỗi mục có nhãn `[NGƯỜI-DÙNG]` hoặc `[SUY-RA]`.

`01-spec` khi đọc `brief.md` sẽ chuyển các mục này thành nhãn `[FILE]` trỏ về
chính `brief.md`, giữ nguyên chuỗi truy vết.

## Cấm

- Chạy phase này khi đã có BRD/PRD/ticket. Khi ấy nó chỉ tạo ra một lớp diễn
  giải thừa nằm chen giữa tài liệu thật và spec — và mọi sai lệch của nó sẽ
  được `01-spec` gắn nhãn như thể có nguồn đàng hoàng.
- Chốt phạm vi hoặc giải pháp kỹ thuật.
