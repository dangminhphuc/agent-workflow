### Thêm
- **`aw knowledge implement` và `aw knowledge review`: ADR, luật `BR-` và tài liệu module được nạp theo phạm vi
  ở implement và review.** Implement đọc tài liệu liên quan theo `Expected files` của `plan.md`; review đọc
  theo diff — đúng tập tài liệu review phải ghi verdict ở `## Durable knowledge`. Việc bỏ design (`chore`,
  bugfix/refactor có `Design: skip`) trước đây không đọc ADR nào, nay vẫn đọc chỉ mục ADR ở implement. Không
  cần làm gì thêm: các phase tự gọi lệnh. Khớp được cả đường dẫn có dấu (ví dụ `src/thanh-toán/`).

### Nội bộ
- **Spec đợt 7: durable knowledge của repo đích như RAG (SP26–SP30).** Truy xuất theo phạm vi ở implement và
  review, chunk theo mục và khối ID, chỉ mục kiến thức chung do máy dựng, tìm theo từ khoá, theo liên kết một
  bước kèm trích nguồn — vẫn tất định, không vector. Spec ở
  `docs/superpowers/specs/2026-10-23-sp26-30-rag-markdown-design.md`, roadmap thêm SP26–SP30; plan SP26 ở
  `docs/superpowers/plans/2026-10-24-sp26-knowledge-implement-review.md`. SP26 đã làm; SP27–SP30 mới ở dạng spec.
- **SP26: `kt_lay` tách trong `tools/lib/knowledge.sh`, ba capability mới.** `CAP-implement-07` và `CAP-design-04`
  (agent phán xét), `CAP-verify-06` (máy: luật `kt_loi_review` ở `tools/check-review.sh` gắn tag
  `# giữ: CAP-verify-06`, số luật chưa phân loại 38 → 37); `kt_duong_plan` đọc `test_files` một lần. Test mới `tools/tests/26-knowledge-retrieval.sh`.
