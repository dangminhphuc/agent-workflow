# Spec: SP3 — Kiểm phạm vi diff theo task, cảnh báo glob rộng

- Ngày: 2026-10-22 · Branch: `claude/brave-heisenberg-t70jup` (PR #79)
- Roadmap § SP3 · `docs/viec-can-lam.md` mục 2
- Interface: phase `04-implement` nhận `CAP-implement-05`; stage `implement` về `implemented`
  (xoá `note`). Không bỏ, không nới gì.

## 1. Mục tiêu

`kc_pham_vi` (`tools/lib/cross-check.sh`) chỉ kiểm theo **hợp** `Expected files` của mọi task; task
đụng file của task khác thì máy không biết. Glob rộng (`` `*` ``, `` `src/*` ``) làm kiểm phạm vi vô
nghĩa và lan sang phạm vi luật `BR-`. `Expected files` do agent tự viết ở `/aw-plan`, không cổng người.

**Thành công:** glob rộng bị cảnh báo khi lập plan; task đổi file ngoài phần của nó bị cảnh báo lúc
`aw task done` và được ghi lại; review phải giải trình từng cảnh báo đó (thiếu → chặn).

## 2. Thiết kế

### 2.1 Cảnh báo glob rộng — `aw check plan`

- Khoá mới `scope_glob_max_files` trong `conventions.md` (số nguyên ≥ 0; mặc định **30**; `0` = tắt).
- Với mỗi token trong backtick của dòng `Expected files:`: đếm file đã track trên commit `Base:` của
  `intake.md` (`git ls-tree -r --name-only <sha>`) khớp token (hàm khớp của `Expected files` — xem
  SP8). Vượt ngưỡng → **cảnh báo**, nhãn không đổi:
  `CẢNH BÁO: TSK-003: \`src/*\` khớp 412 file trên base — thu hẹp mẫu (ngưỡng scope_glob_max_files: 30).`
- Khớp 0 file → không cảnh báo (task tạo file mới). Không có `Base:` / không đọc được base → bỏ qua
  im lặng (luật khác đã báo).

### 2.2 Phạm vi theo task — `aw task start` / `aw task done`

- `aw task start` ghi commit hiện tại (`git rev-parse HEAD`) vào khối `## TSK-NNN` của
  `task-results.md`: dòng `- Started at: <sha>`. `done` ghi lại khối nhưng giữ dòng này.
- `aw task done` (khi Verify xanh, trước khi đánh `[x]`): tập file đổi = `git diff --name-only
  <started-at>` (đã commit + working tree) ∪ file chưa track, trừ `ignored_files` và artifact của việc.
  File không khớp `Expected files` của **chính task** và không nằm trong cột "Extra files" của hàng
  `Unplanned` có cột Task = task đó → **cảnh báo**, nhãn vẫn XONG; ghi vào khối task:
  `- Scope warning: \`<file>\`` (một dòng mỗi file). Task không có `Started at` (bắt đầu trước bản
  này) → bỏ qua kiểm.
- Lý do chỉ cảnh báo: sửa file của task trước (bug vừa phát hiện) là chính đáng — cảnh báo đẩy nó vào
  `Unplanned`.

### 2.3 Review giải trình

- `workflow/templates/review.md` Lens 2 thêm dòng:
  `- Task scope warnings: <TSK-NNN: lý do chấp nhận / đã khai Unplanned …, hoặc "none">`.
- `aw check review` **chặn** khi `task-results.md` có `Scope warning` ở một task mà dòng
  `Task scope warnings` không nhắc tên task đó:
  `Lens 2: TSK-002 có cảnh báo phạm vi trong task-results.md — giải trình ở "Task scope warnings".`
- Theo luật "warn ở implement, block ở review" của `AGENTS.md`.

### 2.4 Interface

`04-implement.md` `capabilities:` thêm `CAP-implement-05`; xoá mục `implement` khỏi khối `sdlc:` của
`workflow.yaml`; test `20-sdlc-conformance.sh` đổi lại `implement=implemented`, bỏ `CAP-implement-05`
khỏi chuỗi roadmap, và ca "nhận nốt CAP-implement-05" đổi thành ca tương đương trên capability khác
còn thiếu (`CAP-deploy-02` đã có sẵn ca này — xoá ca trùng).

## 3. Test

- `02-spec-design-plan.sh`: glob khớp > ngưỡng → CẢNH BÁO, nhãn ĐẠT; ≤ ngưỡng → không; `0` → không;
  khớp 0 file → không.
- `15-conventions-task.sh`: `start` ghi `Started at`; task đụng file task khác → `done` cảnh báo, vẫn
  `[x]`, có `Scope warning`; file trong `Unplanned` đúng task → không cảnh báo; file trong `Unplanned`
  của task khác → vẫn cảnh báo; không `Started at` → không kiểm; khoá `scope_glob_max_files` sai giá
  trị → `aw conventions check` báo.
- `05-review-quality.sh`: có `Scope warning`, Lens 2 không nhắc task → chặn; nhắc → ĐẠT.

## 4. Tài liệu

`workflow/phases/03-plan.md` (mẫu hẹp), `04-implement.md` § Loop (cảnh báo phạm vi → `Unplanned`),
`05-review.md` Lens 2; `workflow/templates/conventions.md` + `conventions-reference.md` (khoá mới);
`docs/huong-dan.md` § Phase 03/04/05; `docs/kien-truc.md` § Những chỗ thiết kế này yếu mục 9, 21;
`docs/viec-can-lam.md` mục 2 (xoá); `changes/…` (`Thêm`: cảnh báo mới người dùng thấy).
