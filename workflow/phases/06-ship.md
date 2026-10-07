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
  - ket-qua-bao-mat.md
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

# Phase 06 — Gửi MR và dọn việc *(tuỳ chọn)*

## Mục tiêu

Đưa việc đã rà soát thành **một MR/PR** vào nhánh đích người chọn, theo dõi tới khi merge, rồi **dọn** worktree và branch.

| Gõ ở đâu | Làm gì |
|---|---|
| Worktree của việc | Viết mô tả MR → người chọn đích → tạo MR → báo trạng thái |
| Checkout chính | Dọn mọi việc đã merge (mục dưới) |

## Ở checkout chính

Bước 0 ra **ĐANG Ở CHECKOUT CHÍNH** → chỉ làm phần này.

1. `aw ship sweep` (chỉ in). Nó xếp mỗi worktree có `ship.md` vào: **dọn được** (mọi MR đã merge), **chờ merge**, **✗ người quyết** (MR đóng, chưa rõ, branch local có commit chưa vào MR).
2. In nguyên văn cho người. Có việc **dọn được** → hỏi: dọn tất cả, dọn một (`<branch>`), hay để sau. Dọn = gỡ worktree (artifact chép vào archive), xoá branch local và trên origin — không lấy lại được, nên **phải hỏi**.
3. Người đồng ý → `aw ship sweep [<branch>] --apply`, in kết quả.
4. Mục **✗**: nói lý do máy in, để người xử lý. Không tự `git branch -D`, `git push --delete`, `git worktree remove --force`.

Theo dõi định kỳ: chạy lại lệnh này theo lịch (agent có cơ chế lặp thì dùng; không thì người gõ lại).

## Trong worktree của việc

### 1. Viết `merge-request.md`

Theo `templates/merge-request.md` và mục "Merge request" của `conventions.md` (quy ước team thắng mẫu). Bảng nguồn ở đầu mẫu nói mục nào lấy từ artifact nào.
- Dòng đầu `# <tiêu đề MR>` theo quy ước tiêu đề của team.
- Chỉ chép điều có trong artifact hoặc diff. Chưa chắc → `Open Questions`.
- Mục không áp dụng ghi `None`, không xoá. Comment HTML của mẫu bị `aw ship create` bỏ khi gửi.

Chạy `aw check ship <thư-mục-feature>` tới khi `[x] ĐẠT`. Nó chặn cả khi `aw check review` chưa đạt hay còn `[Blocker]` → quay lại `/aw-implement` + `/aw-review`.

### 2. Người chọn nhánh đích

`aw ship targets <thư-mục-feature>` → đưa danh sách cho **người** chọn (theo `mr_target_branches`; đánh dấu base, `⚠` = kéo theo commit ngoài việc). Không tự chọn, kể cả khi chỉ có một. Cần vào nhiều nhánh: mỗi nhánh một MR, lặp bước 2–3.

### 3. Người xác nhận, rồi tạo MR

Tạo MR là việc **ra ngoài**. Cho người thấy: nguồn → đích, tiêu đề, mô tả sẽ gửi. Người đồng ý thì:

```sh
aw ship create <thư-mục-feature> --target <nhánh-người-chọn> [--draft]
```

Engine không giữ token; dùng đường đầu tiên được: (1) `gh`/`glab` đã đăng nhập — gửi đủ; (2) GitLab không có `glab` — push options, chỉ gửi tiêu đề, mô tả để ở `<thư-mục-feature>/mo-ta-mr.md` cho người dán; (3) in link tạo MR điền sẵn. Không tự cài `gh`/`glab`, xin token, đăng nhập hộ.

| Kết quả `[x]` | Làm gì |
|---|---|
| `ĐÃ TẠO MR` | Đưa URL (stdout) cho người. Báo "Mô tả CHƯA gửi" → đưa nội dung `mo-ta-mr.md` |
| `ĐÃ CÓ MR ĐANG MỞ` | Không tạo thêm; commit mới đã push vào MR cũ. Đưa URL cũ. Engine không ghi đè mô tả MR |
| `CHƯA ĐỦ ĐIỀU KIỆN` | `aw check ship` chưa đạt hoặc còn thay đổi chưa commit. Không commit hộ thay đổi lạ (việc của `/aw-implement`) |
| `KÉO THEO COMMIT NGOÀI VIỆC` | In danh sách commit. Người quyết: đích khác, tách branch + cherry-pick, hoặc chấp nhận — chỉ khi người nói chấp nhận mới thêm `--allow-extra-commits` |
| `KHÔNG TẠO ĐƯỢC MR` | Branch đã push. Đưa link điền sẵn; người tạo xong đưa link → `aw ship create <thư-mục-feature> --target <nhánh> --url <link>` |

### 4. Theo dõi

`aw ship status <thư-mục-feature>` cập nhật `ship.md`. Không có `gh`/`glab`: suy từ git (nhận merge thường và squash sạch; MR đóng hay squash có sửa xung đột thì người kiểm trên web).

- `CÒN MR ĐANG MỞ`: chờ review. Góp ý cần sửa code → `/aw-implement` (task mới) → `/aw-review` → `aw ship create … --target <cùng nhánh>` (push vào MR cũ).
- `ĐÃ MERGE HẾT`: bảo người mở phiên ở **checkout chính** và gõ lệnh này để dọn.
- `CÓ MR BỊ ĐÓNG KHÔNG MERGE`, `CHƯA RÕ`: nêu ra, người quyết.

## Cấm

- **Merge**, duyệt MR, bật auto-merge.
- Tự chọn nhánh đích; tự thêm `--allow-extra-commits`.
- Force-push, rebase branch đã có MR.
- Sửa tay `ship.md`.
- Dọn khi người chưa đồng ý, hoặc bằng lệnh khác ngoài `aw ship sweep --apply`.

## Điều kiện ra

**Máy:** `aw check ship` ra `[x] ĐẠT` — `aw check review` đạt; không còn `[Blocker]`; `merge-request.md` có tiêu đề, đủ mục mẫu, `Problem`/`Changes`/`Testing` có nội dung, không còn chữ giữ chỗ. `aw ship create` ghi MR vào `ship.md`.

**Người:** chọn nhánh đích; xác nhận tiêu đề, mô tả; review và merge; đồng ý dọn.
