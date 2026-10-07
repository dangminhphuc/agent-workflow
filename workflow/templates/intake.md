# Intake — <TÊN VIỆC>

> Sinh bởi phase `00-intake`. Điểm xuất phát của mọi phase sau.
> Chỉ **trỏ tới** tài liệu nguồn — không tóm tắt, không diễn giải.

- **Type:** `<feature | bugfix | refactor | perf | chore>`   <!-- người xác nhận -->
- **Base:** `<ref>` @ `<sha>`   <!-- chép đúng dòng aw worktree new in ra; người chọn base -->
- **Engine:** <YYYY.M.N>   <!-- chép đúng dòng aw worktree new in ra; mọi aw check của việc chạy đúng version này -->
- **Goal:** <một câu>

Mỗi input là một dòng `-` bắt đầu bằng nhãn: tài liệu thì ghi định danh (URL, mã
issue, đường dẫn); lời người dùng thì chép **nguyên văn** ở dòng `>` bên dưới.

## Input

- `[JIRA]` <mã issue + URL, vd [ABC-123](https://…)>   <!-- hoặc [CONFLUENCE] / [FILE]; không dùng thì xoá dòng -->

- `[HUMAN]`
  > <chép nguyên văn lời người dùng>
