### Thay đổi
- **Mã định danh luôn ở heading `###`, dưới một `##` của nhóm.** Trước đây mỗi file một kiểu:
  `### REQ` trong `spec.md` nhưng `## REQ` trong `open-questions.md`, `## RFR` trong
  `refactor-requests.md`, còn `### FND` lại nằm dưới `## Contents`. Giờ:
  `open-questions.md` dùng `## Questions` → `### REQ-NNN`; `refactor-requests.md` dùng
  `## Requests` → `### RFR-NNN`; `design-findings.md` dùng `## Findings` → `### FND-NNN`.
  `aw check spec` **chặn** dạng cũ `## REQ-NNN`/`## RFR-NNN` và chỉ cách đổi. Anchor không đổi nên
  link `open-questions.md#req-002-…` vẫn đúng. **Ai bị ảnh hưởng:** việc đã ghim engine cũ trong
  `intake.md` chạy tiếp bình thường. Việc chuyển sang engine này mà đã có `open-questions.md` hay
  `refactor-requests.md`: đổi `## REQ-`/`## RFR-` thành `### …`, thêm `## Questions`/`## Requests`
  phía trên, rồi chạy `aw toc`.
- **`aw check spec` kiểm `refactor-requests.md`** (nếu có): chặn mã `RFR` không đúng 3 chữ số và
  mã trùng. Phase sau chạy lại spec nên RFR ghi ở phase nào cũng được kiểm. Đánh số liên tiếp vẫn
  không kiểm (xoá một mục giữa chừng là hợp lệ).
