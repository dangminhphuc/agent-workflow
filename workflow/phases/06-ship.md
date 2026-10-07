---
id: ship
name: Gửi MR và dọn việc
summary: Bước 7 (tuỳ chọn) · Tạo MR/PR vào nhánh đích, theo dõi tới khi merge rồi dọn worktree và branch
required: false
when: việc đã qua /aw-review và cần gửi MR/PR
runs_on_main_checkout: true
inputs:
  - intake.md
  - spec.md
  - open-questions.md
  - tdd.md
  - review.md
  - ket-qua-kiem-thu.md
  - tai-hien.md (bugfix)
  - do-hieu-nang.md (perf)
  - diff
outputs:
  - merge-request.md
  - ship.md (aw ship create ghi — không sửa tay)
  - mo-ta-mr.md (aw ship create ghi khi chưa gửi được mô tả — để người dán)
exit_machine:
  - aw check ship
exit_human:
  - Người chọn nhánh đích (develop, uat/…, main…) từ danh sách aw ship targets
  - Người xác nhận tiêu đề, mô tả và nhánh đích trước khi tạo MR
  - Người review và merge MR trên GitHub/GitLab — agent không merge
needs_clean_context: false
---

# Phase 06 — Gửi MR và dọn việc  *(tuỳ chọn)*

## Mục tiêu

Đưa việc đã rà soát xong thành **một MR/PR** vào nhánh đích người chọn, theo dõi
tới khi nó được merge, rồi **dọn** worktree và branch để checkout không đầy
worktree chết.

Phase này có hai chế độ, tuỳ chỗ lệnh được gõ:

| Gõ ở đâu | Làm gì |
|---|---|
| Worktree của việc | Viết mô tả MR → người chọn đích → tạo MR → báo trạng thái |
| Checkout chính | Dọn mọi việc đã merge (mục "Ở checkout chính") |

Tách như vậy vì không thể gỡ worktree mà chính phiên agent đang đứng trong đó.

## Ở checkout chính

Bước 0 ra **ĐANG Ở CHECKOUT CHÍNH** thì làm phần này, bỏ qua mọi phần còn lại.

1. Chạy `aw ship sweep` (chỉ in, không đụng gì). Nó hỏi lại trạng thái MR của
   mọi worktree có `ship.md` và xếp từng việc vào: **dọn được** (mọi MR đã
   merge), **chờ merge**, hoặc **✗ người quyết** (MR bị đóng, chưa rõ trạng thái,
   branch local có commit chưa vào MR).
2. In nguyên văn kết quả cho người. Có việc **dọn được** thì hỏi người: dọn tất
   cả, dọn một việc (`aw ship sweep <branch> --apply`), hay để sau. Dọn gồm: gỡ
   worktree (artifact chép vào archive), xoá branch local, xoá branch trên
   origin — đều không lấy lại được bằng `git` thường, nên **phải hỏi**.
3. Người đồng ý thì chạy `aw ship sweep [<branch>] --apply`, in kết quả.
4. Mục **✗**: nói rõ lý do máy in ra và để người xử lý. Không tự `git branch -D`,
   không tự `git push --delete`, không tự `git worktree remove --force`.

Người muốn theo dõi định kỳ thì cho chạy lại lệnh này ở checkout chính theo
lịch (agent có cơ chế lặp/hẹn giờ thì dùng nó; không có thì người gõ lại).

## Trong worktree của việc

### Bước 1 — Viết `merge-request.md`

Theo mẫu `templates/merge-request.md` và mục "Merge request" của
`conventions.md` (quy ước của team thắng mặc định của mẫu). Bảng nguồn ở đầu mẫu
nói mục nào lấy từ artifact nào.

- Dòng đầu là `# <tiêu đề MR>` — đúng quy ước tiêu đề của team.
- Chỉ chép điều có trong artifact hoặc diff. Điều chưa chắc ghi vào
  `Open Questions`, không viết như sự thật.
- Mục không áp dụng ghi `None` — không xoá.
- Comment HTML của mẫu là lời dặn: `aw ship create` bỏ chúng khi gửi đi.

Chạy `aw check ship <thư-mục-feature>` tới khi `[x] ĐẠT`. Nó chặn cả khi
`aw check review` chưa đạt hay `review.md` còn finding `[Blocker]` — khi đó
quay lại `/aw-implement` + `/aw-review`, không sửa ở đây.

### Bước 2 — Người chọn nhánh đích

Chạy `aw ship targets <thư-mục-feature>` và đưa danh sách cho **người** chọn.
Danh sách theo khoá `nhanh_dich_mr` của `conventions.md` (vd `develop uat/* main`;
bỏ trống = `nhanh_goc`), đánh dấu base của việc và nhánh nào sẽ kéo theo commit
không thuộc việc (`⚠`). Không tự chọn, kể cả khi chỉ có một nhánh.

Việc cần vào nhiều nhánh (vd `develop` rồi `uat/…`): mỗi nhánh một MR, mỗi lần
người chọn một — chạy lại Bước 2–3.

### Bước 3 — Người xác nhận, rồi tạo MR

Tạo MR là việc **ra ngoài** (người khác thấy, có thể kích CI/thông báo). Trước
khi chạy, cho người thấy: nhánh nguồn → nhánh đích, tiêu đề, và mô tả sẽ gửi.
Người đồng ý thì:

```sh
aw ship create <thư-mục-feature> --target <nhánh-người-chọn> [--draft]
```

Engine không giữ token. Nó tạo MR theo đường đầu tiên dùng được:

1. `gh` / `glab` đã cài **và đã đăng nhập** — gửi đủ tiêu đề và mô tả.
2. GitLab mà không có `glab`: tạo MR ngay trong `git push` (push options) — chỉ
   cần quyền git sẵn có. Chỉ gửi được tiêu đề: lệnh để mô tả ở
   `<thư-mục-feature>/mo-ta-mr.md`, **đưa người nội dung đó** để dán vào MR.
3. Còn lại: in link tạo MR đã điền sẵn đích, tiêu đề, mô tả.

Không tự cài `gh`/`glab`, không xin token, không đăng nhập hộ.

Làm theo nhãn được đánh `[x]` trong khối `Kết quả`:

- **ĐÃ TẠO MR:** stdout là URL — đưa cho người. `ship.md` đã ghi MR. Lệnh báo
  "Mô tả CHƯA gửi" thì đưa người nội dung `mo-ta-mr.md` để dán.
- **ĐÃ CÓ MR ĐANG MỞ:** không tạo thêm; lệnh chỉ push commit mới lên branch (MR
  tự cập nhật). Đưa URL cũ. Muốn đổi mô tả thì sửa trên nền tảng — engine không
  ghi đè mô tả MR.
- **CHƯA ĐỦ ĐIỀU KIỆN:** `aw check ship` chưa đạt hoặc còn thay đổi chưa commit.
  Commit là việc của `/aw-implement` (code) — không commit hộ thay đổi lạ.
- **KÉO THEO COMMIT NGOÀI VIỆC:** in danh sách commit cho người. Người quyết:
  chọn đích khác, tách branch mới từ đích rồi cherry-pick, hoặc chấp nhận (base
  có chủ ý chứa các commit đó) — chỉ khi người nói chấp nhận mới thêm
  `--allow-extra-commits`.
- **KHÔNG TẠO ĐƯỢC MR:** branch đã push; không đường tự động nào dùng được (lý do
  in phía trên, vd `gh chưa đăng nhập`). Đưa người link điền sẵn mà lệnh in ra;
  người tạo xong đưa link MR thì ghi lại:
  `aw ship create <thư-mục-feature> --target <nhánh> --url <link>`.

### Bước 4 — Theo dõi

`aw ship status <thư-mục-feature>` hỏi nền tảng và cập nhật `ship.md`. Không có
`gh`/`glab` dùng được thì trạng thái suy từ git: nhận ra merge thường và squash
merge sạch; MR bị đóng hay squash có sửa xung đột thì không thấy — người kiểm trên web.

- **CÒN MR ĐANG MỞ:** chờ review. Góp ý review cần sửa code → `/aw-implement` (task
  mới trong `plan.md`), rồi `/aw-review` lại, rồi chạy lại `aw ship create … --target
  <cùng nhánh>`: nó push commit mới vào MR cũ, không tạo MR mới.
- **ĐÃ MERGE HẾT:** báo người: mở phiên ở **checkout chính** và gõ lệnh này để dọn.
- **CÓ MR BỊ ĐÓNG KHÔNG MERGE / CHƯA RÕ:** nêu ra, người quyết.

## Cấm

- **Merge MR**, duyệt MR, hay bật auto-merge. Merge là quyết định của người.
- Tự chọn nhánh đích, tự thêm `--allow-extra-commits`.
- Force-push, rebase lại branch đã có MR để "cho sạch" — người review mất dấu.
- Sửa tay `ship.md` để đổi trạng thái — máy dựa vào nó để quyết việc xoá branch.
- Dọn (gỡ worktree, xoá branch) mà người chưa đồng ý, hoặc bằng lệnh khác ngoài
  `aw ship sweep --apply`.

## Điều kiện ra

**Máy:**
- `aw check ship` ra `[x] ĐẠT`: `aw check review` đạt; `review.md` không còn
  `[Blocker]`; `merge-request.md` có tiêu đề, đủ mục của mẫu, `Problem`/`Changes`/
  `Testing` có nội dung, không còn chữ giữ chỗ của mẫu.
- `aw ship create` ghi MR vào `ship.md` (MR có thật trên nền tảng).

**Người:**
- Chọn nhánh đích; xác nhận tiêu đề, mô tả trước khi tạo MR.
- Review và merge trên GitHub/GitLab.
- Đồng ý dọn ở checkout chính.
