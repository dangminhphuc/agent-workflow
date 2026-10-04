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
  - sh tools/kiem-tra-ke-hoach.sh
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

- `spec.md`, `tdd.md` — phải qua được `kiem-tra-thiet-ke.sh`, và **mọi D-xx đã
  được người duyệt**. Còn D `đề xuất` hay `mở lại` thì dừng lại.
- `open-questions.md` — để biết task nào đứng trên giả định tạm

Loại việc `chore` không có `tdd.md`: đầu vào lùi về `spec.md` (phải qua
`kiem-tra-truy-vet.sh` và có `Trạng thái spec: đã duyệt` — cổng duyệt spec vốn
nằm ở design), và task không có `Dựa trên: D-xx`.

## Việc phải làm

1. **Chia task.** Mỗi task phải có:
   - `Phủ:` ít nhất một mã `YC-NNN` trong `spec.md`;
   - `Dựa trên: D-xx` nếu nó thực thi một quyết định (để khi D bị mở lại, grep
     ra đúng task bị ảnh hưởng);
   - `Theo: tdd.md § …` — mục thiết kế nó hiện thực;
   - `File dự kiến:` — đường dẫn trong backtick, cho phép glob (`src/todo/*`).
     `04-implement` dùng dòng này để kiểm phạm vi diff;
   - `Cách kiểm chứng:` — test nào, lệnh nào, quan sát gì;
   - `Phụ thuộc:` task phải xong trước (nếu có);
   - đủ nhỏ để hoàn thành trong một lượt làm việc và tự nó không làm hỏng build.

2. **Đánh dấu task đứng trên giả định tạm** (mục `[CẦN-HỎI]`). Giả định sai thì
   người cần biết ngay phải làm lại task nào.

3. **Hoãn lại có lý do.** YC không có task nào phủ thì ghi vào "Hoãn lại" kèm lý do.
   Ưu tiên hoãn YC `nên có`. Hoãn YC `bắt buộc` thì checker cảnh báo (không chặn)
   — nói rõ với người duyệt plan rằng lần giao này thiếu yêu cầu đó.

4. **Kiểm chứng thủ công.** YC không test tự động được thì ghi vào mục
   "Kiểm chứng thủ công" kèm lý do — nếu không, `/implement` cảnh báo và
   `/review` chặn vì YC chưa có test.

5. **Theo loại việc:**
   - `bugfix`: task đầu tiên là **viết test tái hiện**, tách khỏi task sửa code —
     `/implement` phải chạy `kiem-tra-tai-hien.sh` giữa hai task đó.
   - `perf`: task đầu tiên là **đo trước** (`kiem-tra-hieu-nang.sh --truoc`).
   - `refactor`/`perf`: test cũ nào dự kiến phải sửa (vd đổi import khi dời module)
     thì khai sẵn ở "Test cũ bị sửa".
   - `chore`: có nâng dependency thì khai ở "Nâng dependency" (chỉ `vá | minor`).

6. **Ghi dấu đầu vào:** `sh tools/cap-nhat-based-on.sh <thư-mục-feature> plan.md spec.md tdd.md`
   (chore: bỏ `tdd.md`).

## Đầu ra

- `plan.md` — theo `templates/plan.md`

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
- `sh tools/kiem-tra-ke-hoach.sh` ra `[x] ĐẠT`:
  - đầu vào qua `kiem-tra-thiet-ke.sh`, mọi D-xx `đã duyệt`;
  - mọi task có `Phủ:` hợp lệ, `File dự kiến:`, `Cách kiểm chứng:` không rỗng;
    `Dựa trên:` trỏ về D có thật;
  - mọi YC được ít nhất một task phủ, **hoặc** nằm ở "Hoãn lại" kèm lý do. Kiểm
    hai chiều mới bắt được lỗi bỏ sót — kiểm một chiều chỉ bắt được lỗi thừa.
