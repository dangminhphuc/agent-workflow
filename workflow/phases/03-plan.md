---
id: plan
name: Lập kế hoạch
summary: Bước 4/6 · Cần D-xx đã duyệt. Chia thiết kế thành task nhỏ, có thứ tự, ghi plan.md
required: true
approval_gate: true
inputs:
  - intake.md
  - spec.md
  - tdd.md
  - open-questions.md
outputs:
  - plan.md
exit_machine:
  - aw check plan
exit_human: []
needs_clean_context: true
---

# Phase 03 — Kế hoạch

## Mục tiêu

Chia `tdd.md` **đã duyệt** thành task thực thi được. `plan.md` chỉ quản lý thực thi — **không có lựa chọn kỹ thuật mới** (phase này không có gate người).

## Đầu vào

- `spec.md`, `tdd.md` — qua `aw check design`, **mọi D-xx đã được người duyệt** (tick, dấu duyệt khớp).
- `open-questions.md` — để biết task nào đứng trên giả định tạm.
- `aw rules plan` — đọc từng file nó in.

`chore` (không có `tdd.md`): đầu vào là `spec.md` — qua `aw check spec`, đã tick "Approved by human", không còn điểm mù `blocking` mở. Task không có `Based on: D-xx`.

## Việc phải làm

1. **Chia task.** Mỗi task:
   - `Covers:` ≥ 1 mã `YC-NNN` có trong `spec.md`;
   - `Based on: D-xx` nếu thực thi một quyết định;
   - `Design: tdd.md § …`;
   - `Expected files:` — đường dẫn trong backtick, glob được (`src/todo/*`) — dùng để kiểm phạm vi diff;
   - `Verify:` — lệnh trong backtick + quan sát gì;
   - `Depends on:` nếu có;
   - đủ nhỏ để xong trong một lượt và tự nó không làm hỏng build.
2. **Task đứng trên giả định tạm:** `On assumption: **yes** — open-questions.md § YC-NNN`, không thì `no`.
3. **Hoãn có lý do:** YC không task nào phủ → `## Deferred` + lý do. Ưu tiên hoãn `should`; hoãn `must` thì checker cảnh báo — nói rõ với người.
4. **`## Manual verification`:** YC không test tự động được + lý do (thiếu → implement cảnh báo, review chặn).
5. **Theo loại việc:**
   - `bugfix`: task đầu là **viết test tái hiện**, tách khỏi task sửa (`aw check repro` chạy giữa hai task).
   - `perf`: task đầu là **đo trước** (`aw check perf <thư-mục-feature> --before`).
   - `refactor`/`perf`: test cũ dự kiến phải sửa → khai ở `## Modified existing tests`.
   - `chore`: nâng dependency → `## Dependency upgrades` (chỉ `patch | minor`).
6. **Ghi dấu đầu vào:** `aw based-on <thư-mục-feature> plan.md spec.md tdd.md` (chore: bỏ `tdd.md`).

## Đầu ra

`plan.md` theo `templates/plan.md`.

## Cấm

- **Viết code.**
- Lựa chọn kỹ thuật không có trong `tdd.md` — quay lại `02-design` (mở lại/thêm D).
- Task không ánh xạ về `YC-NNN` nào; task kiểu "refactor toàn bộ module X", "dọn code cũ" (không có tiêu chí xong).
- Thêm yêu cầu không có trong `spec.md` — quay lại `01-spec`.

## Điều kiện ra

**Máy:** `aw check plan` ra `[x] ĐẠT` — đầu vào qua `aw check design`, mọi D đã duyệt; mọi task có `Covers:` hợp lệ, `Expected files:`, `Verify:` không rỗng, `Based on:` trỏ D có thật; mọi YC có task phủ **hoặc** nằm ở "Deferred" kèm lý do.
