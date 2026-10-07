# Nguyên tắc chung

Áp dụng cho mọi phase, mọi agent. Lý do của từng luật: `docs/kien-truc.md` trong repo engine.

## 1. Bàn giao bằng file

- Phase chỉ nhận đầu vào từ file trong `<artifact_dir>/<tên-branch>/`, không từ hội thoại phía trên.
- Mỗi phase phải chạy được từ phiên trắng. Không chạy được = phase trước ghi thiếu.

## 2. Điều kiện ra

- **Máy** (`exit_machine`): chạy lệnh, đọc nhãn được đánh `[x]` trong khối `Kết quả` cuối output. Không tự tuyên bố đạt.
- **Người** (`exit_human`): nêu ra rồi dừng. Không duyệt thay.

**Agent không tự duyệt:**
- Không tick ô "Approved by human" (spec, D-xx). Không sửa/xoá `<!-- approval-hash: … -->`.
- Không tự đổi `[OPEN-QUESTION]` sang `answered`.
- Sửa nội dung đã tick thì **bỏ** tick.
- Checker LLM chỉ được **chặn**, không bao giờ nói "đạt". Thiếu file phát hiện = checker chưa chạy.

**Chặn hay cảnh báo:** checker hợp đồng output của chính phase thì chặn. Kiểm chéo giữa phase (artifact lỗi thời, test ↔ YC, phạm vi diff) chỉ cảnh báo — nhưng `05-review` chặn mọi cảnh báo còn lại. Xử lý cảnh báo ngay khi thấy.

## 3. Không vượt phạm vi phase

Mỗi phase có mục **Cấm**. Việc thuộc phase khác: ghi vào artifact của phase đó, không làm luôn. Hay gặp nhất: `01-spec` chọn giải pháp kỹ thuật; `04-implement` sửa thêm chỗ "tiện tay".

## 4. Không phá trạng thái sẵn có

Không xoá artifact của phase trước. Chạy lại phase = **cập nhật** (người có thể đã sửa tay), không viết đè trắng.

## 5. Ngôn ngữ

- Nội dung artifact, lời nói với người: tiếng Việt.
- Định danh (mã YC, tên file, khoá cấu hình): tiếng Anh ASCII.
- Heading, tên trường, giá trị, nhãn cố định trong mẫu (`Type`, `Risk`, `Source`, `## Out of scope`, `Blocking`, `## Lens 1`, `high`, `must`, `[INFERRED]`…): giữ **đúng chữ** như mẫu — checker đọc theo đó.

## 6. Artifact viết cho người đọc — BẮT BUỘC

- Heading theo cấp, không nhảy cấp. Mỗi mục một ý; nhiều ý ngang hàng → danh sách hoặc bảng.
- Điều quan trọng nhất (kết luận, quyết định, việc người cần làm) lên đầu mục.
- Câu ngắn, từ thông dụng. Bỏ câu rào đón, nhắc lại, giải thích điều ai cũng biết.
- Cú pháp mẫu/checker đòi thì giữ nguyên.

## 7. Quy tắc riêng của repo

Khai ở khoá `rules_<phase>` trong `conventions.md` (file đã commit trong repo).

- **Đầu phase:** chạy `aw rules <phase>`, đọc **từng file** nó in ra (kể cả `SKILL.md` — đọc như tài liệu thường). Không in gì = không có. `KHAI SAI` → dừng, báo người sửa `conventions.md`, không đoán file thay thế.
- **Ưu tiên:** quy tắc repo xếp **dưới** `spec.md`, `tdd.md`, `plan.md` và luật quy trình. Mâu thuẫn → làm theo artifact, nêu mâu thuẫn ra (`04-implement`: mục "Unplanned"). Không vì quy tắc mà vượt phạm vi phase.
- **`05-review`** đối chiếu diff với mọi file quy tắc, mỗi file một kết luận trong `review.md`.
