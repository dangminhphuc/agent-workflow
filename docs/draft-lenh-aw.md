# Draft — đổi tên lệnh sang `aw-` và viết lại description

> **Trạng thái: DRAFT** — đã chốt hướng, chưa hiện thực (trừ phase `ship`, xem
> mục cuối). Xoá file này khi đã hiện thực xong hoặc đã quyết định bỏ.

## 1. Tiền tố `aw-` cho mọi slash command

Lệnh sinh ra trong repo đích đổi từ `/<id>` thành `/aw-<id>`:
`/aw-intake`, `/aw-spec`, `/aw-design`, `/aw-plan`, `/aw-implement`,
`/aw-review`, `/aw-ship`, `/aw-import`, `/aw-clarify`.

### Vì sao `aw-` mà không phải `aw:`

| | `aw:` | `aw-` |
|---|---|---|
| Claude Code | `.claude/commands/aw/<id>.md` → `/aw:<id>` (thư mục con thành namespace) | `.claude/commands/aw-<id>.md` → `/aw-<id>` |
| Cursor | chưa kiểm được Cursor có hiểu thư mục con là namespace không | tên file thường → `/aw-<id>` |
| Cơ chế "trùng tên để che" (Cursor nạp `.claude/`, ưu tiên `.cursor/`) | lệch tên giữa hai agent → Cursor hiện cả hai bản | giữ nguyên |
| Test đối chiếu output giống hệt nhau từng byte | cần hook riêng cho tên lệnh | không đổi |

Gõ `/aw-` vẫn lọc ra đủ các lệnh của quy trình — đủ thay cho namespace thật.

### Việc phải làm khi hiện thực

1. `adapters/lib/chung.sh` (`ad_sinh`): sinh `commands/aw-<id>.md`. Lần build sau
   tự dọn file `<id>.md` cũ (mang dấu "SINH TỰ ĐỘNG"); file người viết tay giữ nguyên.
2. Đổi mọi chỗ nhắc `/intake`, `/spec`… thành `/aw-intake`, `/aw-spec`… trong lời
   dặn agent (`workflow/`, `adapters/`), thông báo của engine (`tools/`, `bin/`),
   README, `docs/` và `tools/chay-thu.sh`.
3. Bỏ ghép `<name> — <summary>` trong description: description chỉ còn `summary`.
   `name` vẫn dùng cho bảng của skill `quy-trinh-agent` và dòng đầu file lệnh Cursor.

## 2. `name` và `summary` mới

Nguyên tắc:

- Description trả lời "khi nào chạy, chạy xong có gì": mở bằng động từ, nêu file
  ghi ra và điều kiện trước, dưới ~90 ký tự (menu cắt bớt phần dài).
- Phase ghi `Bước n/6` — menu xếp theo bảng chữ cái nên không thấy thứ tự.
- Phase có cổng duyệt (`approval_gate: true`) nói trước điều kiện duyệt.

| Lệnh | `name` | `summary` (= description) |
|---|---|---|
| `/aw-intake` | Tiếp nhận việc | Bước 1/6 · Bắt đầu việc mới từ ticket, URL hoặc file: chốt loại việc, tạo worktree, ghi intake.md |
| `/aw-spec` | Viết đặc tả | Bước 2/6 · Biến BRD/PRD/ticket thành spec.md kiểm chứng được và liệt kê điểm mù cần người chốt |
| `/aw-design` | Thiết kế kỹ thuật | Bước 3/6 · Cần spec đã duyệt. Viết tdd.md, tách mỗi lựa chọn thành quyết định D-xx để người duyệt |
| `/aw-plan` | Lập kế hoạch | Bước 4/6 · Cần D-xx đã duyệt. Chia thiết kế thành task nhỏ, có thứ tự, ghi plan.md |
| `/aw-implement` | Hiện thực | Bước 5/6 · Làm từng task trong plan.md; task chỉ xong khi test xanh |
| `/aw-review` | Rà soát độc lập | Bước 6/6 · Subagent ngữ cảnh sạch đối chiếu diff với spec, thiết kế, kế hoạch; ghi review.md |
| `/aw-ship` | Gửi MR và dọn việc | Bước 7 (tuỳ chọn) · Tạo MR/PR vào nhánh đích, theo dõi tới khi merge rồi dọn worktree và branch |
| `/aw-import` | Nhập artifact ngoài | Đưa spec/tdd/plan viết bằng tool khác vào quy trình: chỉ sắp lại theo mẫu, không thêm nội dung |
| `/aw-clarify` | Chốt việc chờ người | Dẫn bạn chốt từng điểm mù và phát hiện của checker đang chặn phase, việc gấp nhất trước |

Gợi ý tham số (`argument-hint`) giữ nguyên.

## 3. Phase `ship` — đã hiện thực (giữ id `ship`)

Id giữ là `ship` (không đổi thành `release`): repo này đã dùng "phát hành"/"release"
cho nghĩa khác — nhánh phát hành (`mau_nhanh_phat_hanh`) và bản phát hành của
engine (`tools/chuan-bi-phat-hanh.sh`). Lệnh hiện là `/ship`; thành `/aw-ship`
khi mục 1 được hiện thực.

Thiết kế chi tiết: `workflow/phases/06-ship.md`. Tóm tắt:

| Bước | Ai | Lệnh |
|---|---|---|
| Viết mô tả MR theo mẫu | agent | `merge-request.md` → `aw check ship` |
| Chọn nhánh đích (develop, uat/…, main) | **người** | `aw ship targets` liệt kê theo `nhanh_dich_mr` |
| Tạo MR/PR | agent, sau khi **người** xác nhận | `aw ship create --target <nhánh>` — push, gọi `gh`/`glab`, ghi `ship.md` |
| Theo dõi | agent / người | `aw ship status` — hỏi nền tảng, cập nhật `ship.md` |
| Merge | **người** (trên GitHub/GitLab) | — agent không merge |
| Dọn worktree + branch | từ checkout chính | `aw ship sweep [--apply]` |
