---
id: review
name: Rà soát
summary: Rà soát độc lập bằng ngữ cảnh sạch — cổng chặn cuối
required: true
inputs:
  - intake.md
  - spec.md
  - open-questions.md
  - tdd.md
  - plan.md
  - ket-qua-kiem-thu.md
  - tai-hien.md (bugfix)
  - do-hieu-nang.md (perf)
  - diff
outputs:
  - review.md
exit_machine:
  - aw check review
exit_human:
  - Người xác nhận kết luận rà soát và quyết định xử lý các finding mức Chặn
  - Người xác nhận base có chủ ý nếu checker cảnh báo base lạ (xếp chồng)
needs_clean_context: true
requires_fresh_agent: true
---

# Phase 05 — Rà soát

## Mục tiêu

Kiểm chứng **độc lập** rằng diff làm đúng `spec.md`, theo đúng `tdd.md` đã
duyệt, và không vượt `plan.md`.

Đây không phải bước rà lỗi cú pháp — linter làm việc đó rẻ hơn. Việc của phase
này là trả lời: *thứ vừa viết ra có đúng là thứ được yêu cầu không?*

Đây cũng là **cổng chặn cuối**. Mọi cảnh báo dồn về từ phase trước — artifact
lỗi thời, YC chưa có test, diff ngoài phạm vi — ở đây thành **chặn**, vì phía sau
không còn chỗ nào bắt lại được.

## Ràng buộc: phải chạy bằng ngữ cảnh sạch

Phase này **không được chạy bởi chính agent vừa hiện thực**. Agent vừa viết
code sẽ rà soát chính lập luận của nó — nó đã tự thuyết phục mình rằng cách làm
đó đúng, và nó thiếu mất thứ người review có: chưa từng nhìn thấy code này.

| Khả năng của agent | Cách làm |
|---|---|
| Có subagent (Claude Code) | Chạy trong subagent với ngữ cảnh trắng |
| Không có subagent | Mở phiên mới, chỉ nạp các file đầu vào + diff |

Adapter chịu trách nhiệm dịch ràng buộc này sang cơ chế của agent đích. Không
dịch được thì phải ghi rõ trong hướng dẫn rằng người dùng phải tự mở phiên mới —
chứ không im lặng bỏ qua.

## Ba lăng kính

Rà theo ba lăng kính tách bạch, không trộn. Trộn lại thì lăng kính dễ nhất
(chất lượng code) sẽ nuốt mất hai lăng kính khó hơn.

### 1. Đúng đặc tả
Duyệt **từng mã `YC-NNN`** trong `spec.md`, chỉ ra code nào thoả nó, kết luận
`đạt` / `chưa đạt` / `đạt một phần`. Không có mã nào được bỏ trống.

Nếu một `YC` gắn `[OPEN-QUESTION]` và giả định tạm chưa được xác nhận, kết luận là
`chờ xác nhận` — không phải `đạt`. Chỉ điểm mù `Mức chặn: không chặn` còn mở được
tới đây; `chặn` / `chặn review` còn mở thì máy chặn.

### 2. Đúng thiết kế và phạm vi
- Code có theo đúng các D-xx đã duyệt và contract/mô hình dữ liệu trong `tdd.md`?
- Thay đổi nào **không** thuộc task nào? Task nào đánh dấu xong nhưng diff
  không có dấu vết?
- Có mục "Unplanned" nào bị xử lý lặng lẽ thay vì nêu ra?

Thêm: đối chiếu diff với **từng file** quy tắc riêng của repo (`aw rules review` —
hợp quy tắc của mọi phase). Mỗi file một dòng trong mục "Quy tắc repo" của
`review.md`: `đạt` / `vi phạm` (kèm `file:dòng`) / `không áp dụng` (kèm lý do).
Vi phạm thì thêm finding ở lăng kính 3, mức do bạn phán. Quy tắc repo xếp dưới
`tdd.md`: code theo D-xx đã duyệt mà trái quy tắc là `không áp dụng`, ghi rõ D nào.

### 3. Chất lượng
Lỗi đúng/sai, chỗ có thể dùng lại thứ đã có, chỗ phức tạp quá mức cần thiết.
Mỗi finding phải có `file:dòng` và mức độ.

## Mức độ finding

| Mức | Nghĩa |
|---|---|
| `Chặn` | Sai đặc tả, lệch quyết định đã duyệt, hoặc lỗi gây hỏng. Không được merge. |
| `Nên sửa` | Đúng nhưng có vấn đề thật về chất lượng. |
| `Góp ý` | Tuỳ người viết quyết định. |

## Theo loại việc

Máy kiểm lại mọi luật chặn của `implement`. Phần người phải phán:

| Loại | Người rà soát làm gì |
|---|---|
| `bugfix` | Đọc `tai-hien.md`: test đỏ **đúng vì bug**, không phải vì lỗi biên dịch/thiếu hàm. Ghi `Test tái hiện đỏ vì: <trích output>` — thiếu dòng này thì máy chặn |
| `refactor`/`perf` | Với từng file ở "Modified existing tests": diff chỉ đổi import/cấu trúc, **không đổi assertion** |
| `perf` | Đọc `do-hieu-nang.md`, kết luận YC hiệu năng `đạt`/`chưa đạt` theo số đo — tính cả độ dao động |
| `chore` | Mức `patch | minor` khai ở "Dependency upgrades" là đúng (major phải là refactor riêng) |

## Đầu ra

- `review.md` — theo `templates/review.md`

## Cấm

- Rà soát ở chế độ "nhìn qua thấy ổn". Không đi hết từng `YC-NNN` thì phase
  này coi như chưa chạy.
- **Tự sửa code.** Phase này chỉ ghi nhận. Sửa là quay lại `04-implement` với
  task mới — nếu không, findings sẽ biến mất vào một diff không ai kiểm lại.
- Nâng một góp ý phong cách lên mức `Chặn`.
- Kết luận `đạt` cho yêu cầu đang đứng trên giả định chưa được xác nhận.

## Điều kiện ra

**Máy:**
- `aw check review` ra `[x] ĐẠT`:
  - mọi `YC-NNN` có kết luận hợp lệ, không `[OPEN-QUESTION]` nào bị kết luận `đạt`;
  - đầu vào qua `aw check plan` (kéo theo design và spec);
  - `ket-qua-kiem-thu.md` có và ghi `Kết quả: XANH`;
  - **không còn cảnh báo nào**: YC chưa có test, diff ngoài phạm vi, artifact lỗi
    thời, loại việc lệch tiền tố branch, test cũ bị sửa chưa khai, điểm mù
    `chặn` / `chặn review` còn mở;
  - luật theo loại việc (như `implement`), và bugfix có dòng `Test tái hiện đỏ vì:`;
  - repo có quy tắc riêng (`quy_tac_*`): file khai có thật, đã commit, và mục
    "Quy tắc repo" của `review.md` có kết luận hợp lệ cho **từng** file.
- Diff được so với **base ghi trong `intake.md`**, không phải `nhanh_goc`. Base
  không phải nhánh gốc hay nhánh phát hành (vd xếp chồng lên branch việc khác)
  thì checker **chỉ cảnh báo** — nêu ra cho người.

**Người:**
- Xác nhận kết luận; quyết định xử lý các finding mức `Chặn`.
- Có cảnh báo base: xác nhận việc dựa trên code của branch khác là có chủ ý.
