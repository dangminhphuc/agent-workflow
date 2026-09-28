# Việc cần làm — sửa checker (chưa làm)

> Ghi chú tạm. Xoá file này khi cả ba mục đã xong.
> Nguồn: chạy thử lỗ hổng của `kiem-tra-truy-vet.sh` ngày 2026-09-28.

Đã chốt: làm **cả 3 mục**. Mỗi mục: viết ca kiểm trong `tools/chay-thu.sh`
trước, chạy trên code cũ thấy **đỏ**, rồi mới sửa; cuối cùng `sh tools/chay-thu.sh`
xanh toàn bộ.

## 1. YC không có `Nguồn:` vẫn qua spec (heading `###` phụ)

- **Chỗ:** `tools/kiem-tra-truy-vet.sh:62-71` — chỉ `##` đóng vùng YC.
- **Tái hiện (đã chạy, ĐẠT sai):**
  ```md
  ### YC-001 — x
  - Mô tả: x

  ### Ghi chú về nguồn
  - Nguồn: `[JIRA]` ABC-9
  ```
  Biến thể: YC-001 có `Nguồn:` và `### Ghi chú` cũng có `Nguồn:` → báo oan
  "có 2 dòng Nguồn".
- **Sửa:** mọi heading `###` không phải `### YC-NNN` cũng đặt `cur = ""`.
  `####` trở xuống vẫn thuộc YC.
- **Kèm:** ghi quy ước vào `workflow/templates/spec.md` — `Nguồn`, `Loại YC`,
  `Được bảo vệ bởi`, `Mục tiêu` phải nằm ngay dưới `### YC-NNN`, không dưới
  `###` phụ.
- **Rủi ro:** spec cũ đặt các dòng đó dưới `###` phụ sẽ chuyển sang không đạt.

## 2. `open-questions.md` 0 byte làm lệch thứ tự file

- **Chỗ:** `tools/kiem-tra-truy-vet.sh:46` (`FNR==1 { idx++ }`) — file rỗng không
  có dòng nào nên không tăng `idx`; `spec.md` bị đọc như OQ.
- **Tái hiện (đã chạy):** OQ `: > open-questions.md` + spec hợp lệ → báo
  "thiếu Mức rủi ro", "không có YC nào". OQ chỉ chứa `\n` thì ĐẠT.
- **Sửa:** xác định file theo tên, như `kiem-tra-ke-hoach.sh:63`:
  `FNR==1 { idx = (FILENAME == ARGV[1]) ? 1 : 2 }`
- **Bắt buộc sửa kèm** `tools/kiem-tra-thiet-ke.sh:74` (thứ tự
  `SPEC OQ TDD PHF`) — không thì OQ rỗng qua spec rồi lại làm design đọc
  `tdd.md` như OQ và chặn oan.
- Đồng bộ luôn `tools/kiem-tra-ra-soat.sh:67` (không phải lỗi thật: file đầu là
  `spec.md`, rỗng đã bị chặn trước).

## 3. Kiểm chéo test ↔ YC im lặng khi chưa có test nào gắn `covers:`

- **Chỗ:** `tools/lib/kiem-cheo.sh:63-88`, awk đọc `"$_ds" spec.md plan.md` với
  `FNR==1 { idx++ }`. `$_ds` rỗng khi không test nào có tag → `spec.md` thành
  idx 1 → danh sách YC rỗng → **không cảnh báo gì**.
- **Trạng thái:** suy ra từ code, **chưa chạy tái hiện** — việc đầu tiên là viết
  ca kiểm chứng minh nó.
- **Sửa:** cùng cách mục 2 (theo `FILENAME`/`ARGV`).
- **Tác động:** `implement` xuất hiện cảnh báo mới, `review` chặn mới — đúng ý
  thiết kế, nhưng feature trước giờ "sạch" có thể đột nhiên bị chặn.

## Tác động theo phase

| Phase | Mục 1 | Mục 2 | Mục 3 |
|---|---|---|---|
| intake | — | — | — |
| spec | chặt hơn | chấp nhận OQ 0 byte (đúng tài liệu) | — |
| design | gián tiếp (entry check) | phải sửa kèm | — |
| plan | gián tiếp | gián tiếp | — |
| implement | — | — | cảnh báo mới |
| review | gián tiếp | gián tiếp | chặn mới |

Repo đích nhận bản sửa bằng cách chạy lại `tools/cai-dat.sh`.

## Ngoài phạm vi (luật mới, tách việc riêng)

Checker hiện **cho qua** các ca sau (đã chạy): `Nguồn: [JIRA]` không mã issue;
`[SUY-RA]` không lý do; nguồn không có trong `intake.md`; spec thiếu "Ngoài phạm
vi"/"Tiêu chí chấp nhận"/bảng mâu thuẫn; mục mồ côi trong OQ (design sẽ chặn với
thông báo khó hiểu); OQ còn nguyên mẫu. Cần quyết định độ chặt trước khi làm.
