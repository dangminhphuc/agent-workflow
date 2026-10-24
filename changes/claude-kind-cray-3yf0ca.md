### Thêm
- **`aw knowledge implement` và `aw knowledge review`: ADR, luật `BR-` và tài liệu module được nạp theo phạm vi
  ở implement và review.** Implement đọc tài liệu liên quan theo `Expected files` của `plan.md`; review đọc
  theo diff — đúng tập tài liệu review phải ghi verdict ở `## Durable knowledge`. Việc bỏ design (`chore`,
  bugfix/refactor có `Design: skip`) trước đây không đọc ADR nào, nay vẫn đọc chỉ mục ADR ở implement. Không
  cần làm gì thêm: các phase tự gọi lệnh.

### Nội bộ
- **Spec đợt 6: durable knowledge của repo đích như RAG (SP20–SP24).** Truy xuất theo phạm vi ở implement và
  review, chunk theo mục và khối ID, chỉ mục kiến thức chung do máy dựng, tìm theo từ khoá, theo liên kết một
  bước kèm trích nguồn — vẫn tất định, không vector. Spec ở
  `docs/superpowers/specs/2026-10-23-sp20-24-rag-markdown-design.md`, roadmap thêm SP20–SP24; plan SP20 ở
  `docs/superpowers/plans/2026-10-24-sp20-knowledge-implement-review.md`. SP20 đã làm; SP21–SP24 mới ở dạng spec.
- **SP20: `kt_lay` tách trong `tools/lib/knowledge.sh`, ba capability mới.** `CAP-implement-07` và `CAP-design-04`
  (agent phán xét), `CAP-verify-06` (máy: luật `kt_loi_review` ở `tools/check-review.sh` gắn tag
  `# giữ: CAP-verify-06`, số luật chưa phân loại 38 → 37). Test mới `tools/tests/26-knowledge-retrieval.sh`.
