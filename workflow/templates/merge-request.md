# <JIRA-KEY>: <verb> <what> <where>

<!--
Mẫu mô tả MR/PR. Quy ước đi kèm: mục "Merge request" trong conventions.md.
Heading và nhãn giữ tiếng Anh; nội dung viết tiếng Việt hoặc tiếng Anh tuỳ team.

Viết cho người review CHƯA đọc ticket và CHƯA mở diff. Mỗi mục trả lời một câu
hỏi họ sẽ hỏi; mục nào không áp dụng thì ghi "None" — đừng xoá, vì mục bị xoá
trông giống mục bị quên.

Nguồn khi chạy theo quy trình (thư mục .agent-workflow/<branch>/):
  Problem          ← intake.md (mục tiêu, input), spec.md (Context)
  Changes          ← tdd.md (D-xx đã duyệt), diff
  External Impact  ← review.md Lens 2
  Out of Scope     ← spec.md "Out of scope"
  Testing          ← test-results.md, repro.md (bugfix), perf.md (perf)
  Open Questions   ← open-questions.md
Chỉ chép điều có trong artifact hoặc diff. Điều chưa chắc: ghi vào "Open
Questions", không viết như sự thật.
-->

## Problem

<!-- Hành vi SAI hiện tại, quan sát được: ở đâu, với đầu vào nào, thấy gì, lẽ ra
     phải thấy gì. Có bằng chứng (request/response, log, ảnh). Nguyên nhân gốc
     trong một-hai câu. Lỗi có nhiều phần (BE + FE…) thì nói PR này sửa phần nào. -->

- **Current:** <…>
- **Expected:** <…>
- **Root cause:** <…>

## Changes

<!-- Hành vi SAU khi merge, không phải danh sách file. Mỗi gạch một thay đổi
     người dùng/hệ thống thấy được. Đánh dấu rõ hai loại dưới. -->

- <…>
- **Breaking change:** <API, payload, schema, event, config đổi — ai đang phụ thuộc>, hoặc None
- **Edge cases:** <xử lý null, rỗng, giá trị ngoài miền>, hoặc None

## External Impact

<!-- Hệ thống/consumer khác nhận khác đi vì PR này (service khác, job, SAP, báo
     cáo…). Mỗi mục: cái gì đổi, đã xác nhận với ai (link), rủi ro nếu sai.
     Đây là mục người review hay bỏ sót nhất — viết nổi bật. -->

None

## Out of Scope

<!-- Điều người đọc ticket sẽ tưởng PR này làm nhưng không làm: backfill dữ
     liệu cũ, phần FE, edge case hoãn… Kèm lý do hoặc ticket theo dõi. -->

- <…>

## Deployment

<!-- Thứ tự deploy (BE trước FE? migration trước code?), feature flag, cấu hình
     /secret mới, migration (có đảo ngược được không), cách rollback. -->

- **Dependencies:** <PR/MR liên quan>, hoặc None
- **Order:** <…>
- **Migration / Config:** <…>, hoặc None
- **Rollback:** <revert MR là đủ / cần thêm bước …>

## Testing

<!-- Test chứng minh điều gì, không chỉ tên test.
     bugfix: test tái hiện ĐỎ trước khi sửa, đỏ đúng vì bug.
     Test cũ bị đổi kỳ vọng: liệt kê riêng và nói vì sao — đó là đổi hành vi. -->

- **Reproduction (red before fix):** <test> — <chứng minh gì>
- **Added:** <test> — <chứng minh gì>
- **Changed expectations:** <test> — <vì sao>, hoặc None
- **Commands:** `<lệnh>` → <kết quả>

### Post-deploy Verification

<!-- Điều chỉ kiểm được trên môi trường thật. Checkbox để đánh dấu sau deploy. -->

- [ ] **<env>:** <hành động> → <kết quả mong đợi>

## Open Questions

<!-- Câu hỏi mở, giả định chưa xác nhận, D-xx đáng soi lại. Không có thì ghi
     "None" — đừng để người review tự đoán chỗ nào yếu. -->

None

Refs: <JIRA-KEY>
