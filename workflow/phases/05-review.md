---
id: review
name: Rà soát
summary: Rà soát độc lập bằng ngữ cảnh sạch — cổng chặn cuối
required: true
inputs:
  - muc-dich.md
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
  - sh tools/kiem-tra-ra-soat.sh
exit_human:
  - Người xác nhận kết luận rà soát và quyết định xử lý các finding mức Chặn
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

Nếu một `YC` gắn `[CẦN-HỎI]` và giả định tạm chưa được xác nhận, kết luận là
`chờ xác nhận` — không phải `đạt`.

### 2. Đúng thiết kế và phạm vi
- Code có theo đúng các D-xx đã duyệt và contract/mô hình dữ liệu trong `tdd.md`?
- Thay đổi nào **không** thuộc task nào? Task nào đánh dấu xong nhưng diff
  không có dấu vết?
- Có mục "Phát sinh" nào bị xử lý lặng lẽ thay vì nêu ra?

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
| `refactor`/`perf` | Với từng file ở "Test cũ bị sửa": diff chỉ đổi import/cấu trúc, **không đổi assertion** |
| `perf` | Đọc `do-hieu-nang.md`, kết luận YC hiệu năng `đạt`/`chưa đạt` theo số đo — tính cả độ dao động |
| `chore` | Mức `vá | minor` khai ở "Nâng dependency" là đúng (major phải là refactor riêng) |

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
- `sh tools/kiem-tra-ra-soat.sh` trả về 0:
  - mọi `YC-NNN` có kết luận hợp lệ, không `[CẦN-HỎI]` nào bị kết luận `đạt`;
  - đầu vào qua `kiem-tra-ke-hoach.sh` (kéo theo design và spec);
  - `ket-qua-kiem-thu.md` có và mã thoát `0`;
  - **không còn cảnh báo nào**: YC chưa có test, diff ngoài phạm vi, artifact lỗi
    thời, loại việc lệch tiền tố branch, test cũ bị sửa chưa khai;
  - luật theo loại việc (như `implement`), và bugfix có dòng `Test tái hiện đỏ vì:`.

**Người:**
- Xác nhận kết luận; quyết định xử lý các finding mức `Chặn`.
