# Spec: SP22 — Số ADR không trùng khi hai việc chạy song song

- Ngày: 2026-10-23 · Branch: `claude/intelligent-volta-famesh` (chỉ spec)
- `docs/kien-truc.md` § Những chỗ thiết kế này yếu mục 18
- Interface: không đổi. ADR là phần lưu tri thức của repo đích (`aw adr`, `aw knowledge`); không
  capability/invariant nào của `sdlc/` nói về số ADR. Hợp đồng của stage `design` (`CAP-design-01…03`)
  giữ nguyên.

## 1. Vấn đề

`adr_so_moi` (`tools/lib/adr.sh`) lấy số lớn nhất trong thư mục ADR **của worktree** rồi cộng 1. Hai việc
rẽ từ cùng base mà cùng nâng ADR thì cùng lấy, ví dụ, `0004`. PR merge sau mang theo hai hậu quả:

- **Hai file trùng số.** `aw adr check` chỉ chặn ở việc kế tiếp, khi lỗi đã nằm trên `main`.
- **Xung đột ở bảng chỉ mục** `README.md` của thư mục ADR. Người phải tự đổi số rồi chạy lại
  `aw adr promote`.

## 2. Thiết kế

Ba bước, mỗi bước đóng một khe:

**A. Cấp số nhìn cả base.** `adr_so_moi <thư-mục ADR> [<ref>]`: số mới lớn hơn mọi số trong worktree **và**
trong `git ls-tree --name-only <ref> -- <knowledge_adr_dir>/`.

- `<ref>` là `origin/<Base>` của việc. `Base` đọc từ `intake.md` bằng `intake_base_dong`. Không có
  `origin/<Base>` thì dùng `<Base>`.
- `aw adr promote` chạy `git fetch -q origin <Base>` trước. Lỗi mạng thì in
  `(không fetch được origin — dùng thông tin đã có)`, như `lay_origin` của `tools/ship.sh`, rồi chạy tiếp.

**B. Chạy lại `promote` thì đổi số khi bị chiếm.** Hiện tại ADR của cùng việc + DEC giữ số cũ (`adr_cua_d`).
Thêm một điều kiện: nếu số đó đã có trên `<ref>` ở một file mang `Origin` **khác**, thì cấp số mới theo
bước A.

Phần còn lại `adr.sh` đã có sẵn:

- xoá file cũ khi tên đổi (`[ "$CU" = "$DICH" ] || rm -f "$CU"`);
- viết lại `Status: superseded by NNNN` của ADR bị thay;
- dựng lại bảng `README.md` (`adr_lam_chi_muc`).

In ra: `  đổi số  NNNN → MMMM (NNNN đã có trên <ref>: <file>)`.

**C. Máy chặn trước khi số trùng tới `main`.**

- Hàm `adr_trung_base <thư-mục-feature>`: ADR của việc này mà số đã có trên `<ref>`, ở file `Origin` khác,
  thì in `"<file>: số NNNN đã có trên <ref> (<file kia>) — chạy lại: aw adr promote <dir> <DEC>"`.
- Gọi từ `adr_loi_viec`, nên `check-implement` và `check-review` đều có (hiện cả hai đều tính
  `adr_loi_viec` là lỗi).
- Gọi thêm từ `aw ship create`, trước khi tạo MR, sau `lay_origin`.
- Luật chính xác: hai file khác `Origin` cùng số là sai, không có ca báo nhầm. Vì vậy **chặn**.

**Bảng chỉ mục:** bảng do máy dựng. Merge base vào nhánh việc mà xung đột ở `README.md` thì cách giải là
nhận bản nào cũng được, rồi chạy lại `aw adr promote`. Không cần thêm lệnh mới. Ghi cách này vào thông báo
của bước C và vào `docs/huong-dan.md`.

**Không làm:** đổi tên ADR sang slug hay ngày. Tên `NNNN-*.md` là định dạng repo đích đang có
(`aw adr check` kiểm), đổi định dạng thì hỏng các tham chiếu `ADR-NNNN` sẵn có. Bước A–C đủ để chặn trùng
số trước merge. Hai PR mở cùng lúc vẫn có thể cùng số tới khi PR đầu merge; khi đó bước C của PR sau chặn
(sau `aw ship` / review chạy lại với base mới).

## 3. Test

Ca thêm vào `tools/tests/16-journal-adr.sh`, cùng fixture ADR hiện có:

- Base (`origin/main` giả) có `0004-feat_y-dec-001.md`, worktree chỉ có tới `0003` → `promote` cấp `0005`.
- Không có remote → vẫn cấp số theo worktree, in dòng không fetch được, nhãn ĐÃ NÂNG.
- Việc đã có `0004-feat_x-dec-001.md`, base có `0004-feat_y-…` → chạy lại `promote` đổi sang `0005`:
  file cũ mất, heading `# ADR-0005`, `superseded by 0005` ở ADR bị thay, bảng chỉ mục đúng.
- Cùng số nhưng cùng `Origin` (base đã merge chính việc này) → giữ số.
- `aw check review` KHÔNG ĐẠT với lỗi trùng số trên base; ĐẠT sau khi chạy lại `promote`.
- `aw ship create` dừng trước khi tạo MR khi trùng số.

## 4. Tài liệu

- `docs/kien-truc.md` mục 18: còn khe giữa hai PR cùng mở, và cách máy đóng nó.
- `docs/huong-dan.md` § ADR: xung đột bảng chỉ mục thì chạy lại `promote`.
- `changes/…`, mục `Sửa`: hai việc song song không còn tạo ADR trùng số trên `main`.

## 5. Cần người duyệt

- `aw ship create` chặn hay chỉ cảnh báo khi trùng số. Đề xuất: chặn. Sửa chỉ tốn một lệnh, còn để lọt thì
  `main` có hai file trùng số.
