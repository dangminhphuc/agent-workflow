---
id: design
name: Thiết kế kỹ thuật
summary: Viết Technical Design Document — tách lựa chọn thành quyết định D-xx để người duyệt
required: true
inputs:
  - muc-dich.md
  - spec.md
  - open-questions.md
outputs:
  - tdd.md
  - phat-hien-thiet-ke.md
exit_machine:
  - sh tools/kiem-tra-thiet-ke.sh
exit_human:
  - Người duyệt TỪNG quyết định D-xx trong tdd.md (đổi Trạng thái sang "đã duyệt")
  - Người làm trọng tài cho phát hiện của checker LLM (xác nhận, hoặc bác bỏ kèm lý do)
needs_clean_context: true
llm_checker: workflow/checkers/thiet-ke.md
---

# Phase 02 — Thiết kế kỹ thuật (Technical Design Document)

`tdd.md` là **Technical Design Document**, không phải Test-Driven Development.

## Mục tiêu

Viết ra mọi thông tin `04-implement` cần để làm đúng kỹ thuật, **nằm trong kiến
trúc sẵn có của repo đích**, và tách các lựa chọn thật thành mục **D-xx** để
người *quyết định* chứ không phải đọc duyệt cả một bài văn xuôi.

**Loại việc `chore` không có phase này** — đi thẳng `/plan`. Checker chặn nếu
chạy design cho chore. Với `refactor`/`perf`, design là phần việc chính: cấu trúc
đích và quyết định D-xx về cách chuyển sang đó.

## Đầu vào

- `spec.md`, `open-questions.md` — phải qua được `kiem-tra-truy-vet.sh`
- Code hiện có của repo đích

Checker của phase này chạy lại checker của `spec` trên đầu vào. Không có đường
tắt: `spec.md` đưa từ tool khác vào cũng phải qua đúng cổng đó.

`[CẦN-HỎI]` có `Mức ảnh hưởng: toàn bộ thiết kế` mà chưa `đã trả lời` thì
**chặn** — thiết kế trên một giả định sẽ lật cả hướng đi là phí công.

## Chọn Mode

| `Mức rủi ro` trong spec | Mode | Ai viết D-xx |
|---|---|---|
| `thường` | **Mode 1** | Agent viết cả `tdd.md`, người duyệt từng D |
| `cao` | **Mode 2** | **Người phác D-xx trước** (`tac_gia: nguoi`); agent viết phần còn lại và chỉ **phản biện** quyết định của người |

Mode 2 tồn tại để chống **neo**: agent đưa phương án trước thì người duyệt có xu
hướng bám vào nó. Rủi ro `cao` mà chưa có D nào `tac_gia: nguoi` thì **dừng lại
nhờ người phác** — checker sẽ chặn.

Ở Mode 2, không sửa D-xx của người. Phản biện ghi ngay dưới D đó, dạng
`- Phản biện (agent): …`.

## Việc phải làm

1. **Khảo sát code hiện có trước khi thiết kế.** Tìm chỗ đã giải quyết vấn đề
   tương tự; ghi module sẽ đụng tới và quy ước phải theo vào mục "Bối cảnh code
   hiện có". Bước này đi trước bước chọn phương án, không đảo ngược.

2. **Nêu quyết định D-xx.** Mỗi lựa chọn mà người khác có thể chọn khác — nhất là
   điểm khó đảo ngược (sửa nhiều chỗ, di trú dữ liệu, phá giao diện ngoài) — là
   một D-xx: vấn đề, ít nhất hai phương án kèm đánh đổi, lựa chọn, `tac_gia`,
   `Trạng thái: đề xuất`. Mục D **được phép rỗng** — thay đổi nhỏ có thể không
   có quyết định nào. Điểm hiển nhiên thì không cần D; bắt viết D cho mọi thứ sẽ
   khiến không ai đọc D nào.

3. **Viết các mục chi tiết** theo `templates/tdd.md`: mô hình dữ liệu + ERD,
   contract/API, flow + sequence/state (Mermaid), phi chức năng, chiến lược test,
   ánh xạ YC → mục. Mục nào dựa vào một quyết định thì ghi `Dựa trên: D-xx`.
   Mục không áp dụng ghi `Không áp dụng: <lý do>`, **không bỏ trống**.

4. **Ghi dấu đầu vào:** `sh tools/cap-nhat-based-on.sh <thư-mục-feature> tdd.md spec.md open-questions.md`.

5. **Chạy checker LLM** (phiên/subagent riêng, theo `checkers/thiet-ke.md`). Nó
   tìm chỗ lệch D-xx và quyết định ngầm chưa nêu thành D, ghi ra
   `phat-hien-thiet-ke.md`. Sửa những gì bạn đồng ý (`Xử lý: đã sửa`); phần còn
   lại để người làm trọng tài.

6. **Chạy `kiem-tra-thiet-ke.sh`**, rồi dừng lại cho người duyệt từng D-xx.

## Mở lại một quyết định

Mở lại **đúng một D-xx**, sửa tại chỗ (lịch sử để git giữ, không giữ bản cũ
trong file). Đổi `Trạng thái: mở lại` và thêm `Lý do mở lại:`. Grep
`Dựa trên: D-xx` trong `plan.md` ra các task bị ảnh hưởng; chỉ các task đó đặt
lại `[ ]`. Người chỉ duyệt lại D đang mở. `/plan` chặn cho tới khi D đó được
duyệt lại.

## Đầu ra

- `tdd.md` — output duy nhất của thiết kế; không có file quyết định riêng, vì
  tách ra thì hai file sẽ lệch nhau.
- `phat-hien-thiet-ke.md` — do checker LLM ghi.

## Cấm

- **Viết code.** Kể cả "code mẫu cho dễ hình dung" (chữ ký API/schema trong
  contract thì được).
- Thêm yêu cầu mới không có trong `spec.md` — quay lại `01-spec`.
- **Tự đổi `Trạng thái` của D-xx sang `đã duyệt`.** Chỉ người làm việc này.
- Ở Mode 2: sửa hoặc thay quyết định của người thay vì phản biện.
- Giấu một lựa chọn thật vào văn xuôi thay vì nêu thành D-xx.
- Coi "checker LLM không báo gì" là đạt khi nó chưa chạy.

## Điều kiện ra

**Máy:**
- `sh tools/kiem-tra-thiet-ke.sh` trả về 0 — đầu vào qua checker của spec; đủ
  mục; D-xx hợp lệ; `Dựa trên` trỏ đúng; mọi YC được ánh xạ; Mode 2 có D của
  người; có `phat-hien-thiet-ke.md` và không còn phát hiện `Chặn` chưa xử lý.

**Người:**
- Duyệt từng D-xx.
- Trọng tài cho phát hiện của checker LLM. LLM chỉ được **chặn**, không bao giờ
  là bên nói "đạt".
