---
id: ship
name: Phát hành
summary: Khe cắm phát hành — chưa hiện thực
required: false
when: repo đích có hạ tầng phát hành muốn đưa vào quy trình
status: chưa hiện thực
inputs:
  - review.md
  - diff
outputs:
  - ghi-chu-phat-hanh.md
exit_machine: []
exit_human: []
needs_clean_context: false
---

# Phase 06 — Phát hành  *(tuỳ chọn, chưa hiện thực)*

## Trạng thái

Đây là **khe cắm** đã khai báo sẵn trong `workflow.yaml`, chưa có nội dung.

## Vì sao để lại sau

Nội dung của phase này gần như hoàn toàn là đặc thù **hạ tầng CI của từng repo**
(GitHub Actions / GitLab CI / Jenkins / nội bộ), chứ không phải đặc thù agent.
Viết bây giờ thì spec trung lập sẽ đầy nhánh điều kiện cho những hạ tầng chưa
biết, và sẽ phải viết lại khi gặp repo thật đầu tiên.

Đây chính là chỗ tính không-phụ-thuộc-agent yếu nhất trong cả quy trình — đáng
để thừa nhận thẳng thay vì che bằng một lớp trừu tượng hoá đoán mò.

## Vì sao thêm sau được mà không phải sửa gì

Vì các phase chỉ nối nhau qua file trong thư mục feature. Thêm `06-ship` chỉ cần:

1. Viết nội dung file này với `inputs: [review.md, diff]`.
2. Bỏ dòng `status`, bật `required` trong `workflow.yaml` nếu muốn.
3. Phát hành engine bản mới (`aw upgrade` ở repo đích; việc đang làm giữ version cũ).

Không phase nào khác phải đổi, vì không phase nào biết gì về phase đứng sau nó.
