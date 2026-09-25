---
id: implement
name: Hiện thực
summary: Thực thi từng task trong kế hoạch; test xanh mới tính là xong
required: true
inputs:
  - plan.md
  - spec.md
outputs:
  - diff
  - plan.md (cập nhật trạng thái task)
  - ket-qua-kiem-thu.md
exit_machine:
  - sh tools/kiem-tra-hien-thuc.sh
exit_human: []
needs_clean_context: false
---

# Phase 03 — Hiện thực

## Mục tiêu

Thực thi từng task trong `plan.md`, không vượt ra ngoài phạm vi của chúng.

Đây là phase agent cần **ít hướng dẫn nhất về cách viết code** và **nhiều ràng
buộc nhất về phạm vi**. Agent viết code khá tốt; thứ nó làm hỏng là tự ý mở
rộng phạm vi — sửa thêm chỗ "tiện tay thấy chưa đẹp", đổi thêm vài chữ ký hàm,
dọn thêm vài file. Kết quả là một diff không ai review nổi.

## Đầu vào

- `plan.md` — nguồn duy nhất của việc phải làm
- `spec.md` — tra khi cần hiểu *vì sao* một task tồn tại

## Việc phải làm

1. **Làm từng task một.** Không gộp nhiều task vào một lượt, kể cả khi chúng
   trông giống nhau. Gộp lại thì mất điểm dừng để kiểm tra giữa chừng.

2. **Chạy kiểm chứng đã khai trong task** ngay sau khi làm xong task đó — không
   dồn tới cuối. Dán **output thật** vào `ket-qua-kiem-thu.md`, không viết lại
   bằng lời.

3. **Cập nhật trạng thái task** trong `plan.md`: `[ ]` → `[x]`, kèm danh sách
   file đã đụng tới.

4. **Dừng và báo khi gặp điều kế hoạch chưa lường.** Không tự quyết rồi đi
   tiếp. Ghi vào `plan.md` mục "Phát sinh" và nêu ra.

   Đây là điểm quyết định chất lượng của cả phase: task gặp bất ngờ là tín hiệu
   `02-plan` thiếu sót, và thông tin đó phải chảy ngược về chứ không bị agent
   âm thầm xử lý.

5. **Giữ diff trong phạm vi.** File nằm ngoài danh sách dự kiến của task thì
   chỉ được đụng khi task không thể hoàn thành nếu không đụng — và phải ghi lý
   do vào `plan.md`.

## Đầu ra

- Thay đổi code trong repo đích
- `plan.md` đã cập nhật trạng thái
- `ket-qua-kiem-thu.md` — output thật của lệnh kiểm thử

## Cấm

- Làm việc không có trong `plan.md`.
- **Tuyên bố xong khi chưa chạy kiểm thử.** Đây là thất bại phổ biến nhất của
  agent trong toàn quy trình.
- Sửa hoặc vô hiệu hoá test để test xanh. Test đỏ là thông tin, không phải
  chướng ngại. Nếu test cũ thực sự sai, đó là một mục "Phát sinh" cần nêu ra,
  không phải việc sửa lặng lẽ.
- Bỏ qua lỗi lint/type với lý do "không liên quan tới task".

## Điều kiện ra — `test` nằm ở đây

Quy trình này **không có phase test riêng**. Lý do: một phase test riêng không
có đầu vào riêng — nó ăn đúng cái diff mà `04-review` ăn — và đặt nó ở phía sau
sẽ biến "code xong" thành một trạng thái hợp lệ dù chưa ai chạy gì.

Đặt ở đây thì ràng buộc mạnh hơn: **chưa xanh nghĩa là chưa xong.**

**Máy:**
- Lệnh kiểm thử của repo đích trả về 0, và output thật nằm trong
  `ket-qua-kiem-thu.md`.
- Không còn task nào ở trạng thái đang làm dở.

Nếu repo đích chưa có lệnh kiểm thử, phải khai báo lúc cài đặt. Không khai thì
điều kiện ra này coi như **fail**, không phải "bỏ qua" — im lặng bỏ qua sẽ làm
cả ràng buộc trên mất tác dụng ở đúng những repo cần nó nhất.
