### Thêm

- **`aw knowledge show <ref>…`.** Đọc đúng khối durable knowledge thay vì cả file. Ref là `<file>` hoặc
  `<file>#<neo>`; neo là nguyên văn heading `##` hay ID `BR-…`. Tài liệu trong `knowledge_files` khai phạm
  vi riêng cho từng mục bằng `- Scope: <glob>` là dòng không trống đầu tiên dưới heading `##`.
- Heading `##` trùng trong file knowledge được cảnh báo; heading mục có `Scope` chứa `|` bị chặn.

### Thay đổi

- **`aw knowledge spec|design|implement|review` in ref**, luật dạng `<file>#BR-…`. Ai parse đầu ra cũ cần đổi.
- **Cột `File` của `## Durable knowledge` (review.md) nhận ref.** Verdict mức file không còn phủ ref có
  neo: việc đang dở khi nâng cấp phải ghi lại verdict, kể cả dòng file luật trần.
- **`updated` ở ref có neo đòi diff đổi dòng trong khối** (cảnh báo ở implement, chặn ở review); mục bị đổi
  tên hay xoá cần verdict.

### Nội bộ

- Spec SP26–SP30 § B (SP27, chunk durable knowledge theo mục): chốt thêm năm điểm trước khi viết plan —
  heading trùng (cảnh báo, SP28 chặn), verdict cũ ở mức file không phủ ref có neo, tập ref gộp từ `Base:`
  và cây làm việc, heading chứa `|` bị chặn, verdict `updated` ngoài khối cảnh báo ở implement / chặn ở
  review. Chưa đổi hành vi `aw`.
- Plan SP27: `docs/superpowers/plans/2026-10-25-sp27-knowledge-theo-muc.md` (5 task); roadmap SP27 → `đang làm`.
