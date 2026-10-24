### Thay đổi
- **`aw check` chặn frontmatter `based_on` máy không đọc được.** Trước đây `spec.md` / `tdd.md` / `plan.md`
  có frontmatter sai tập con YAML (viết `based_on: [a, b]`, thụt tab, thiếu dòng `---` đóng) hay mục không
  phải `<file>@<số>` thì máy đọc ra rỗng và **im lặng bỏ qua** kiểm stale. Giờ mọi `aw check` (spec,
  design, plan, implement, review) chặn và nêu dòng sai. **Việc đang dở:** ai đã sửa frontmatter bằng tay
  thì chạy lại `aw based-on …` (lệnh in trong thông báo).
- **Cảnh báo khi quên `aw based-on`.** Artifact có mà `based_on` thiếu đầu vào bắt buộc (`spec.md` ←
  `intake.md`; `tdd.md` ← `spec.md`, `open-questions.md`; `plan.md` ← `spec.md`, `tdd.md` trừ khi bỏ
  design) thì design / plan / implement cảnh báo, review chặn — như artifact lỗi thời.
