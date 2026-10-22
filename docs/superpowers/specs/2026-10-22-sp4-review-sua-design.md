# Spec: SP4 — Vòng review → sửa

- Ngày: 2026-10-22 · Branch: `claude/brave-heisenberg-t70jup` (PR #79)
- Roadmap § SP4 · `docs/viec-can-lam.md` mục 1
- Interface: **nới** INV-001 ("every task covers a requirement **or fixes a review finding**") —
  ghi dưới `### Thay đổi` trong `changes/…`. Không bỏ capability nào.

## 1. Mục tiêu

Sau review, không phase nào nói ai thêm task sửa, thêm vào đâu, theo dạng nào: `04-implement` cấm tự
thêm task; `/aw-plan` chạy lại có thể viết lại cả `plan.md`; `aw check plan` buộc `Covers:` nên agent
gán đại REQ cho finding không gắn REQ; finding không có mã nên task không trỏ được về nó.

**Quyết định đã chốt:** `Blocker` **luôn phải sửa** — không thêm trường `Decision`; `aw check ship`
giữ nguyên luật chặn mọi `[Blocker]`.

**Thành công:** finding cần sửa có mã; `/aw-plan` bổ sung task sửa mà không đụng task cũ; task sửa trỏ
về finding (hoặc bình luận MR) và máy kiểm được; một vòng review → plan → implement → review chạy
trọn trong test.

## 2. Thiết kế

### 2.1 Mã finding

- Heading Lens 3: `### [Blocker] RVW-001 — <tiêu đề>`, `### [Should fix] RVW-002 — <tiêu đề>`.
  `[Nit]` không bắt buộc mã. Dạng mã theo `docs/kien-truc.md` § Mã định danh (`RVW-NNN`).
- `aw check review` **chặn**: Blocker / Should fix thiếu mã; mã trùng trong file.
- `journal.sh`, `check-ship.sh` đếm theo `[Blocker]` như cũ — không đổi; tiêu đề trong nhật ký bỏ mã.

### 2.2 `/aw-plan` chế độ bổ sung

`workflow/phases/03-plan.md` thêm mục **Supplement**: khi `review.md` tồn tại và còn finding
`Blocker` / `Should fix` chưa có task `Fixes` trỏ tới (hoặc REQ Lens 1 `fail` / `partial`):

- Chỉ **thêm** task cuối danh sách: số `TSK` tiếp theo, `Status: [ ]`; không sửa task đã có.
- Finding không gắn REQ → `- Fixes: RVW-NNN` thay cho `Covers:`; REQ Lens 1 `fail` / `partial` →
  `Covers: REQ-NNN` như thường.
- `Expected files` lấy từ `Location` của finding (+ file test); `Verify` tái hiện `Failure scenario`.
- Finding đụng DEC / spec → dừng, chỉ `/aw-design` hay `/aw-spec` (như hiện nay).
- Phản hồi reviewer MR (`06-ship.md` § 4): `- Fixes: <URL bình luận MR>`.

### 2.3 `aw check plan`

- Task phải có `Covers:` **hoặc** `Fixes:` — thay luật "thiếu Covers" hiện tại. Thông báo:
  `TSK-NNN: thiếu "Covers:" hoặc "Fixes:" — task phải phủ một REQ hoặc sửa một finding review.`
- `Fixes:` nhận danh sách `RVW-NNN` và/hoặc URL `http(s)://…`; giá trị khác → chặn.
- Task `[ ]` / `[~]` có `Fixes: RVW-NNN` mà `review.md` không có finding mã đó → chặn. Task `[x]` bỏ qua
  (review lại đã ghi đè `review.md`; lịch sử nằm trong git).
- Task `[x]` bị sửa nội dung sau lần đạt trước: **không** kiểm bằng máy — review Lens 2 bắt.

### 2.4 Phase text

`05-review.md` § Forbidden: "Fixes go back to `/aw-plan` (supplement), then `/aw-implement`".
`06-ship.md` § 4: bình luận MR cần sửa → `/aw-plan` bổ sung với `Fixes: <URL>`. `04-implement.md`
không đổi luật (vẫn không tự thêm task).

## 3. Test

- `05-review-quality.sh`: Blocker thiếu mã → chặn; Should fix thiếu mã → chặn; mã trùng → chặn; Nit
  không mã → ĐẠT.
- `02-spec-design-plan.sh`: task chỉ `Fixes: RVW-001` (có trong review.md) → ĐẠT; không `Covers`
  không `Fixes` → chặn; `Fixes: RVW-009` không có → chặn; `Fixes` trên task `[x]` khi review.md không
  còn mã đó → ĐẠT; `Fixes: https://…/merge_requests/1#note_2` → ĐẠT; `Fixes: abc` → chặn.
- Ca trọn vòng (`06-review-freshness.sh` hoặc phần mới nếu chậm): review có RVW-001 → thêm task Fixes
  → `aw task next` trả task mới → `aw check review` chặn vì task chưa `[x]`.
- `20-sdlc-conformance.sh` / `sdlc/invariants.md`: INV-001 `Tested by` nêu ca mới.

## 4. Tài liệu

Template `review.md`, `plan.md`; phase 03/05/06; `docs/huong-dan.md` § Phase 03, 05, 06;
`docs/kien-truc.md` § Mã định danh (`RVW`), § Review; `docs/thuat-ngu.md` (`RVW`, plan bổ sung);
`docs/viec-can-lam.md` mục 1 (xoá); `changes/…` (`Thêm`, `Thay đổi` — INV-001 nới + lý do).
