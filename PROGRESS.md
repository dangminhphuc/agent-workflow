# Tiến độ engine v2

Điểm vào duy nhất khi tiếp tục. Mở phiên mới (người hay agent bất kỳ): đọc file này, làm **Bước tiếp theo**.

## Bước tiếp theo

SP1 Task 4 — soạn trang `interface/stages/04-implement.md` theo `docs/plans/SP1-interface.md` (Chu trình trang), rồi chờ người duyệt.

## Dự án con

| SP  | Tên                              | Trạng thái   | Spec | Plan |
|-----|----------------------------------|--------------|------|------|
| SP1 | Định nghĩa interface SDLC        | đang làm     | `docs/specs/SP1-interface.md` | `docs/plans/SP1-interface.md` |
| SP7 | Chọn lại tính năng của v1        | chưa bắt đầu | —    | —    |
| SP2 | Trình biên dịch interface        | chưa bắt đầu | —    | —    |
| SP3 | Mô hình làm việc của agent       | chưa bắt đầu | —    | —    |
| SP4 | Runtime engine                   | chưa bắt đầu | —    | —    |
| SP5 | Adapter                          | chưa bắt đầu | —    | —    |
| SP6 | Điểm nối deploy/operate          | chưa bắt đầu | —    | —    |
| SP8 | Chuyển đổi từ v1                 | chưa cần     | —    | —    |
| SP9 | Tài liệu người dùng              | rải theo SP  | —    | —    |

Thứ tự: SP1 → SP7 → SP2 ∥ SP3 → SP4 → SP5 → SP6 (`docs/decisions.md` D-008).

Trạng thái: `chưa bắt đầu` → `brainstorm` → `spec chờ duyệt` → `plan chờ duyệt` → `đang làm` → `xong`.

### Phạm vi từng dự án con

- **SP1 — Định nghĩa interface SDLC.** Danh sách stage; mỗi stage: định nghĩa, mục đích, input,
  output, ai cho kết thúc, capability, ví dụ vào/ra; invariant xuyên stage; job type; khuôn viết trang.
  Xong khi người duyệt từng trang. Chưa có code.
- **SP7 — Chọn lại tính năng của v1.** Mỗi tính năng v1 (ADR, luật nghiệp vụ `BR-`, `conventions.md`,
  bootstrap, trạng thái task, ship, cross-check stale…): đưa vào interface, bỏ (có lý do), hay để sau.
- **SP2 — Trình biên dịch interface.** File người → hợp đồng máy; báo lỗi theo dòng; kiểm bản đã commit
  khớp; kiểm tham chiếu. Unit test cho từng loại lỗi.
- **SP3 — Mô hình làm việc của agent.** Agent chạy một stage thế nào: đọc gì, ghi gì, dừng chờ người ở
  đâu, checker nào chạy; cấu trúc artifact ở repo đích; vào giữa chừng; mở lại quyết định. Hợp đồng
  agent-agnostic.
- **SP4 — Runtime engine.** CLI `aw`, checker máy từng stage, đóng gói `.pyz`, wrapper tải theo phiên bản
  kiểm sha256, CI Linux/macOS/Windows.
- **SP5 — Adapter.** Sinh lệnh/skill/hook cho từng agent; Claude Code trước; tăng tốc không đổi kết quả.
- **SP6 — Điểm nối deploy/operate.** Hợp đồng input/output với CI/CD và observability; sự cố thành việc mới.
- **SP8 — Chuyển đổi từ v1.** Chưa cần.
- **SP9 — Tài liệu người dùng.** Cài đặt, ví dụ trọn luồng, xử lý lỗi; viết dần theo từng SP.

## Cách dừng và tiếp tục

1. Chỉ dừng ở ranh giới: sau khi một quyết định đã ghi vào `docs/decisions.md`, hoặc sau khi một task đã
   commit. Không dừng giữa một thay đổi chưa ghi.
2. Trước khi dừng: sửa **Bước tiếp theo** — một câu đủ để người hay agent biết làm gì kế tiếp.
3. Commit sau mỗi quyết định hoặc mỗi lần duyệt, rồi push nhánh `v2`.
4. Tiếp tục: phiên mới, "đọc `PROGRESS.md` và làm bước tiếp theo". Không cần nhớ gì từ phiên trước.

## Tài liệu

- `docs/decisions.md` — quyết định đã chốt và câu hỏi đang mở.
- `docs/specs/SPn-<tên>.md` — spec từng dự án con.
- `docs/plans/SPn-<tên>.md` — plan từng dự án con.
- `interface/` — interface SDLC (SP1 đang viết).
- v1 (tham chiếu): nhánh `main`, `/home/dangminhphuc/github/agent-workflow`.
