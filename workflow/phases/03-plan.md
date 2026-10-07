---
id: plan
name: Kế hoạch
summary: Chia thiết kế đã duyệt thành task thực thi được — chỉ quản lý thực thi
required: true
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

Chia `tdd.md` **đã duyệt** thành danh sách task thực thi được. `plan.md` chỉ còn
phần **quản lý thực thi** — mọi lựa chọn kỹ thuật đã nằm ở `tdd.md`.

Phase này không có gate người: nó chỉ thực thi những gì đã được duyệt ở `spec`
và `design`. Vì vậy nó **không được** có lựa chọn kỹ thuật mới nào.

Tách khỏi `tdd.md` vì hai lẽ: `plan.md` là ranh giới do một phiên khác đặt cho
`04-implement`, và tick task không bao giờ được sửa vào tài liệu thiết kế đã
duyệt.

## Đầu vào

- `spec.md`, `tdd.md` — phải qua được `aw check design`, và **mọi D-xx đã
  được người duyệt**. Còn D `proposed` hay `reopened` thì dừng lại.
- `open-questions.md` — để biết task nào đứng trên giả định tạm
- Quy tắc riêng của repo cho phase này — `aw rules plan`, đọc từng file nó in ra
  (xem `rules/nguyen-tac-chung.md` § 7)

Loại việc `chore` không có `tdd.md`: đầu vào lùi về `spec.md` (phải qua
`aw check spec`, có `Status: approved` và không còn điểm mù
`Blocking: blocking` đang mở — các cổng này vốn nằm ở design), và task không có
`Based on: D-xx`.

## Việc phải làm

1. **Chia task.** Mỗi task phải có:
   - `Covers:` ít nhất một mã `YC-NNN` trong `spec.md`;
   - `Based on: D-xx` nếu nó thực thi một quyết định (để khi D bị mở lại, grep
     ra đúng task bị ảnh hưởng);
   - `Design: tdd.md § …` — mục thiết kế nó hiện thực;
   - `Expected files:` — đường dẫn trong backtick, cho phép glob (`src/todo/*`).
     `04-implement` dùng dòng này để kiểm phạm vi diff;
   - `Verify:` — test nào, lệnh nào, quan sát gì;
   - `Depends on:` task phải xong trước (nếu có);
   - đủ nhỏ để hoàn thành trong một lượt làm việc và tự nó không làm hỏng build.

2. **Đánh dấu task đứng trên giả định tạm** (mục `[OPEN-QUESTION]`): dòng
   `On assumption: **yes** — open-questions.md § YC-NNN`, không thì `no`. Giả định sai thì
   người cần biết ngay phải làm lại task nào.

3. **Hoãn có lý do.** YC không có task nào phủ thì ghi vào "Deferred" kèm lý do.
   Ưu tiên hoãn YC `should`. Hoãn YC `must` thì checker cảnh báo (không chặn)
   — nói rõ với người duyệt plan rằng lần giao này thiếu yêu cầu đó.

4. **Manual verification.** YC không test tự động được thì ghi vào mục
   "Manual verification" kèm lý do — nếu không, `/implement` cảnh báo và
   `/review` chặn vì YC chưa có test.

5. **Theo loại việc:**
   - `bugfix`: task đầu tiên là **viết test tái hiện**, tách khỏi task sửa code —
     `/implement` phải chạy `aw check repro` giữa hai task đó.
   - `perf`: task đầu tiên là **đo trước** (`aw check perf <thư-mục-feature> --before`).
   - `refactor`/`perf`: test cũ nào dự kiến phải sửa (vd đổi import khi dời module)
     thì khai sẵn ở "Modified existing tests".
   - `chore`: có nâng dependency thì khai ở "Dependency upgrades" (chỉ `patch | minor`).

6. **Ghi dấu đầu vào:** `aw based-on <thư-mục-feature> plan.md spec.md tdd.md`
   (chore: bỏ `tdd.md`).

## Đầu ra

- `plan.md` — theo `templates/plan.md`. Đầu mục, tên trường và giá trị viết tiếng
  Anh, giữ đúng như mẫu (`## Tasks`, `Covers:`, `Expected files:`, `Verify:`,
  `Status: [ ] | [~] | [x]`, `## Deferred`, `## Unplanned`…) — checker đọc theo
  đúng chữ đó; nội dung điền vào viết tiếng Việt.

## Cấm

- **Viết code.**
- Lựa chọn kỹ thuật mới không có trong `tdd.md`. Thấy thiếu thì quay lại
  `02-design` (mở lại hoặc thêm D-xx), không nhét vào kế hoạch.
- Task không ánh xạ được về mã `YC-NNN` nào.
- Task kiểu "refactor toàn bộ module X", "dọn dẹp code cũ" — không có tiêu chí
  xong, và là cửa ngõ để `04-implement` đi lạc không giới hạn.
- Thêm yêu cầu mới không có trong `spec.md` — quay lại `01-spec`.

## Điều kiện ra

**Máy:**
- `aw check plan` ra `[x] ĐẠT`:
  - đầu vào qua `aw check design`, mọi D-xx `approved`;
  - mọi task có `Covers:` hợp lệ, `Expected files:`, `Verify:` không rỗng;
    `Based on:` trỏ về D có thật;
  - mọi YC được ít nhất một task phủ, **hoặc** nằm ở "Deferred" kèm lý do. Kiểm
    hai chiều mới bắt được lỗi bỏ sót — kiểm một chiều chỉ bắt được lỗi thừa.
