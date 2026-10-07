---
id: design
name: Thiết kế kỹ thuật
summary: Bước 3/6 · Cần spec đã duyệt. Viết tdd.md, tách mỗi lựa chọn thành quyết định D-xx để người duyệt
required: true
approval_gate: true
inputs:
  - intake.md
  - spec.md
  - open-questions.md
outputs:
  - tdd.md
  - phat-hien-thiet-ke.md
exit_machine:
  - aw check design
exit_human:
  - Người duyệt TỪNG quyết định D-xx trong tdd.md (tick ô "Approved by human" của D đó)
  - Người làm trọng tài cho phát hiện của checker LLM (xác nhận, hoặc bác bỏ kèm lý do)
needs_clean_context: true
llm_checker: workflow/checkers/thiet-ke.md
trace_rule: true
---

# Phase 02 — Thiết kế kỹ thuật

`tdd.md` = **Technical Design Document** (không phải Test-Driven Development).

## Mục tiêu

Ghi mọi thứ `04-implement` cần để làm đúng kỹ thuật, **trong kiến trúc sẵn có** của repo, và tách lựa chọn thật thành mục **D-xx** để người *quyết định*.

- `chore` **không có phase này** — đi thẳng `/aw-plan` (checker chặn design cho chore).
- `refactor`/`perf`: design là phần chính — cấu trúc đích và D-xx về cách chuyển sang đó.

## Đầu vào

- `spec.md`, `open-questions.md` — qua `aw check spec` (checker này chạy lại nó, kể cả spec import từ tool khác), ô "Approved by human" đã tick và dấu duyệt khớp.
- Điểm mù `blocking` chưa `answered` → **chặn**: dừng, nhờ người chạy `clarify`. `review-blocking`/`non-blocking` → thiết kế tiếp trên giả định tạm.
- Code hiện có của repo.
- `aw rules design` — đọc từng file nó in.

## Chọn Mode

| `Risk` | Mode | Ai viết D-xx |
|---|---|---|
| `normal` | **1** | Agent viết cả `tdd.md`, người duyệt từng D |
| `high` | **2** | **Người phác D-xx trước** (`Author: human`); agent viết phần còn lại và chỉ **phản biện** D của người |

Mode 2 chống neo vào phương án agent. `high` mà chưa có D `Author: human` → **dừng, nhờ người phác** (checker chặn). Không sửa D của người; phản biện ghi ngay dưới D đó: `- Critique (agent): …`.

## Việc phải làm

1. **Khảo sát code trước khi thiết kế.** Tìm chỗ đã giải quyết vấn đề tương tự; ghi module sẽ đụng và quy ước phải theo vào `## Existing code`.
2. **Nêu D-xx.** Mỗi lựa chọn người khác có thể chọn khác — nhất là khó đảo ngược (sửa nhiều chỗ, di trú dữ liệu, phá giao diện ngoài): vấn đề, ≥ 2 phương án + đánh đổi, lựa chọn, `Author`, ô `- [ ] **Approved by human**` **chưa tick**. Điểm hiển nhiên không cần D; không có D nào cũng được.
3. **Viết các mục** theo `templates/tdd.md`: dữ liệu + ERD, contract/API, flow + sequence/state (Mermaid), phi chức năng, chiến lược test, ánh xạ YC → mục. Mục dựa vào D thì ghi `Based on: D-xx`. Mục không áp dụng: `Not applicable: <lý do>`, không bỏ trống.
4. **Ghi dấu đầu vào:** `aw based-on <thư-mục-feature> tdd.md spec.md open-questions.md`.
5. **Chạy checker LLM** (subagent/phiên riêng, theo `checkers/thiet-ke.md`) → `phat-hien-thiet-ke.md`. Sửa điều bạn đồng ý (`Xử lý: đã sửa`); phần còn lại người phân xử qua `clarify`.
6. **Chạy `aw check design`**, rồi dừng cho người duyệt từng D.

## Mở lại một D-xx

- Mở **đúng một** D, sửa tại chỗ (git giữ lịch sử). Bỏ tick, thêm `Reopen reason:` (chưa tick + có lý do = `reopened`).
- Grep `Based on: D-xx` trong `plan.md` → chỉ các task đó đặt lại `[ ]`.
- Người chỉ duyệt lại D đang mở. `/aw-plan` chặn tới khi D đó được duyệt lại.

## Đầu ra

- `tdd.md` theo `templates/tdd.md` — output duy nhất của thiết kế (không tách file quyết định).
- `phat-hien-thiet-ke.md` — do checker LLM ghi.

## Cấm

- **Viết code**, kể cả "code mẫu" (chữ ký API/schema trong contract thì được).
- Thêm yêu cầu không có trong `spec.md` — quay lại `01-spec`.
- **Tick ô duyệt D-xx**, sửa/xoá dấu duyệt. Sửa D đã tick → bỏ tick (thêm `- Critique (agent):` thì không cần).
- Mode 2: sửa/thay D của người thay vì phản biện.
- Giấu lựa chọn thật vào văn xuôi thay vì nêu thành D.
- Coi "checker LLM không báo gì" là đạt khi nó chưa chạy.

## Điều kiện ra

**Máy:** `aw check design` ra `[x] ĐẠT` — đầu vào qua checker spec; đủ mục; mỗi D đúng một ô duyệt, D đã tick có dấu duyệt khớp; `Based on` trỏ đúng; mọi YC được ánh xạ; Mode 2 có D của người; có `phat-hien-thiet-ke.md`, không còn phát hiện `Chặn` chưa xử lý.

**Người:** duyệt từng D (tick ô của D đó); phân xử phát hiện của checker LLM.
