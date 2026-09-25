---
id: plan
name: Kế hoạch
summary: Chuyển đặc tả thành thiết kế và danh sách task nằm trong kiến trúc sẵn có
required: true
inputs:
  - spec.md
  - open-questions.md
outputs:
  - plan.md
exit_machine:
  - sh tools/kiem-tra-ke-hoach.sh
exit_human:
  - Chủ repo duyệt phương án ở các mục có ADR
needs_clean_context: true
---

# Phase 02 — Kế hoạch

## Mục tiêu

Chuyển `spec.md` thành thiết kế kỹ thuật và danh sách task thực thi được, **nằm
trong kiến trúc sẵn có của repo đích**.

Ràng buộc "nằm trong kiến trúc sẵn có" là trọng tâm. Agent bỏ qua code hiện có
sẽ đẻ ra phương án sạch đẹp trên giấy nhưng chồng chéo với thứ đã có — và đó là
dạng rác khó gỡ nhất, vì nó chạy được.

## Đầu vào

- `spec.md` — bắt buộc
- `open-questions.md` — để biết chỗ nào đang đứng trên giả định tạm
- Code hiện có của repo đích

## Việc phải làm

1. **Khảo sát code hiện có trước khi thiết kế.** Tìm những chỗ đã giải quyết
   vấn đề tương tự. Ghi lại: module nào sẽ đụng tới, quy ước nào phải theo.
   Bước này đi trước bước chọn phương án, không đảo ngược.

2. **Chọn phương án.** Với mỗi điểm có rủi ro hoặc khó đảo ngược, nêu **ít nhất
   hai** phương án kèm đánh đổi, rồi chọn một và ghi ADR ngắn trong `plan.md`.

   "Khó đảo ngược" nghĩa là: đổi ý sau này phải sửa nhiều chỗ, hoặc phải di trú
   dữ liệu, hoặc phá vỡ giao diện bên ngoài. Điểm dễ đảo ngược thì chọn thẳng,
   không cần ADR — bắt viết ADR cho mọi thứ sẽ khiến không ai đọc ADR nào.

3. **Chia task.** Mỗi task phải:
   - ánh xạ về ít nhất một mã `YC-NNN` trong `spec.md`;
   - nêu rõ **cách kiểm chứng** khi xong (test nào, lệnh nào, quan sát gì);
   - đủ nhỏ để hoàn thành trong một lượt làm việc và tự nó không làm hỏng build.

4. **Đánh dấu task đứng trên giả định tạm.** Task nào phụ thuộc mục `[CẦN-HỎI]`
   thì ghi rõ. Nếu giả định sai, người cần biết ngay *phải làm lại những task
   nào* mà không phải đọc lại toàn bộ.

5. **Nhận diện rủi ro** và ghi phương án xử lý.

## Đầu ra

- `plan.md` — theo `workflow/templates/plan.md`, gồm: bối cảnh code hiện có,
  các ADR, danh sách task, rủi ro.

Danh sách task nằm trong `plan.md` chứ không tách file riêng: `03-implement` cập
nhật trạng thái ngay tại chỗ, để trạng thái luôn đứng cạnh lý do.

## Cấm

- **Viết code.** Kể cả "code mẫu cho dễ hình dung".
- Task không ánh xạ được về mã `YC-NNN` nào.
- Task kiểu "refactor toàn bộ module X", "dọn dẹp code cũ" — không có tiêu chí
  xong, và là cửa ngõ để `03-implement` đi lạc không giới hạn.
- Thêm yêu cầu mới không có trong `spec.md`. Nghĩ ra yêu cầu mới thì quay lại
  `01-spec`, không nhét vào kế hoạch.

## Điều kiện ra

**Máy:**
- Mọi task có ít nhất một mã `YC-NNN` hợp lệ (tồn tại trong `spec.md`).
- Mọi task có mục "Cách kiểm chứng" không rỗng.
- Mọi `YC-NNN` trong `spec.md` được ít nhất một task phủ, **hoặc** được ghi rõ
  trong mục "Hoãn lại" kèm lý do. Kiểm hai chiều như vậy mới bắt được lỗi bỏ
  sót yêu cầu — kiểm một chiều chỉ bắt được lỗi thừa.

**Người:**
- Chủ repo duyệt các phương án có ADR.
