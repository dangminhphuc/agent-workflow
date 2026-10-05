# <MÃ-JIRA>: <động từ> <cái gì> <ở đâu>

<!--
Mẫu mô tả MR/PR. Quy ước đi kèm: mục "Merge request" trong conventions.md.

Viết cho người review CHƯA đọc ticket và CHƯA mở diff. Mỗi mục trả lời một câu
hỏi họ sẽ hỏi; mục nào không áp dụng thì ghi "Không có" — đừng xoá, vì mục bị
xoá trông giống mục bị quên.

Nguồn khi chạy theo quy trình (thư mục .agent-workflow/<branch>/):
  Vấn đề         ← intake.md (mục tiêu, input), spec.md (Bối cảnh)
  Thay đổi       ← tdd.md (D-xx đã duyệt), diff
  Ngoài phạm vi  ← spec.md "Ngoài phạm vi", review.md lăng kính 2
  Kiểm thử       ← ket-qua-kiem-thu.md, tai-hien.md (bugfix), do-hieu-nang.md (perf)
Chỉ chép điều có trong artifact hoặc diff. Điều chưa chắc: ghi vào "Cần người
review quyết", không viết như sự thật.
-->

## Vấn đề

<!-- Hành vi SAI hiện tại, quan sát được: ở đâu, với đầu vào nào, thấy gì, lẽ ra
     phải thấy gì. Có bằng chứng (request/response, log, ảnh). Nguyên nhân gốc
     trong một-hai câu. Lỗi có nhiều nửa (BE + FE…) thì nói PR này sửa nửa nào. -->

- Hiện tại: <…>
- Mong đợi: <…>
- Nguyên nhân: <…>

## Thay đổi

<!-- Hành vi SAU khi merge, không phải danh sách file. Mỗi gạch một thay đổi
     người dùng/hệ thống thấy được. Đánh dấu rõ:
       **Đổi hợp đồng:** API, payload, schema, event, cấu hình — ai đang phụ thuộc
       **Hành vi mới với dữ liệu thiếu/lạ:** null, rỗng, giá trị ngoài miền -->

- <…>

## Ảnh hưởng ngoài phạm vi ticket

<!-- Hệ thống/consumer khác nhận khác đi vì PR này (service khác, job, SAP, báo
     cáo…). Mỗi mục: cái gì đổi, đã xác nhận với ai (link), rủi ro nếu sai.
     Đây là mục người review hay bỏ sót nhất — viết nổi bật. -->

Không có.

## Không làm

<!-- Điều người đọc ticket sẽ tưởng PR này làm nhưng không làm: backfill dữ
     liệu cũ, nửa FE, edge case hoãn… Kèm lý do hoặc ticket theo dõi. -->

- <…>

## Triển khai

<!-- Thứ tự deploy (BE trước FE? migration trước code?), feature flag, cấu hình
     /secret mới, migration (có đảo ngược được không), cách rollback. -->

- Phụ thuộc: <PR/MR liên quan, hoặc "Không có">
- Thứ tự: <…>
- Migration / cấu hình: <…>
- Rollback: <revert MR là đủ / cần thêm bước …>

## Kiểm thử

<!-- Test chứng minh điều gì, không chỉ tên test.
     bugfix: test tái hiện ĐỎ trước khi sửa, đỏ đúng vì bug.
     Test cũ bị đổi kỳ vọng: liệt kê riêng và nói vì sao — đó là đổi hành vi. -->

- Tái hiện (đỏ trước khi sửa): <test> — <chứng minh gì>
- Thêm: <test> — <chứng minh gì>
- Đổi kỳ vọng: <test> — <vì sao>, hoặc "Không có"
- Lệnh đã chạy: `<lệnh>` → <kết quả>

### Cần kiểm sau deploy

<!-- Điều chỉ kiểm được trên môi trường thật. Checkbox để đánh dấu sau deploy. -->

- [ ] <môi trường>: <hành động> → <kết quả mong đợi>

## Cần người review quyết

<!-- Câu hỏi mở, giả định chưa xác nhận, D-xx đáng soi lại. Không có thì ghi
     "Không có" — đừng để người review tự đoán chỗ nào yếu. -->

Không có.

Refs: <MÃ-JIRA>
