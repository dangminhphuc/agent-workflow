# Nguyên tắc chung

Áp dụng cho mọi phase, mọi agent.

## 1. Bàn giao bằng file, không bằng ngữ cảnh hội thoại

Phase chỉ được nhận đầu vào từ **file** trong thư mục feature
(`<artifact_dir>/<tên-branch>/`), không từ những gì
"đã nói ở trên" trong cùng phiên chat.

Đây không phải quy ước cho gọn — nó là toàn bộ lý do quy trình này không phụ
thuộc agent. Nếu `03-plan` cần nhớ điều `01-spec` nói trong hội thoại thì quy
trình chỉ chạy được khi cả hai phase nằm trong cùng một phiên, cùng một agent,
chưa bị nén ngữ cảnh. Ràng buộc đó phá hỏng cả tính portable lẫn tính lặp lại.

Hệ quả thực tế: **mỗi phase phải chạy được từ một phiên hoàn toàn mới.** Nếu
một phase không chạy nổi khi mở phiên trắng, phase trước đã ghi thiếu.

## 2. Phase có điều kiện ra kiểm được bằng máy

Mỗi phase khai báo `exit_machine` và `exit_human`:

- **máy** — chạy được bằng lệnh, cho mã thoát 0/1. Agent không được tự tuyên bố đạt.
- **người** — cần người xác nhận. Agent nêu ra và dừng, không tự duyệt thay.

Tiêu chí nào diễn đạt được dưới dạng máy thì phải để máy kiểm. "Agent tự đánh
giá là đã đạt" không phải tiêu chí.

**Agent không tự duyệt.** Không tự đổi quyết định D-xx sang `đã duyệt`, không tự
đổi `[CẦN-HỎI]` sang `đã trả lời`. Checker dùng LLM chỉ được **chặn**, không bao
giờ là bên nói "đạt" — không có file phát hiện nghĩa là checker chưa chạy.

**Flow không tắc.** Checker chính xác (hợp đồng output của chính phase) thì chặn.
Kiểm chéo giữa phase, hay báo nhầm (artifact lỗi thời, test ↔ YC, phạm vi diff)
thì chỉ cảnh báo — nhưng `05-review` là cổng chặn cuối, cảnh báo nào còn thì
review không đạt. Xử lý cảnh báo ngay khi thấy là rẻ nhất.

## 3. Không vượt phạm vi phase

Mỗi phase có phần **Cấm** liệt kê việc thuộc phase khác. Vi phạm hay gặp nhất:
`01-spec` chọn luôn giải pháp kỹ thuật, và `04-implement` sửa thêm những thứ
"tiện tay thấy chưa đẹp".

Cả hai đều cùng một tác hại: làm mất điểm dừng để người xem lại. Việc nằm ngoài
phạm vi không bị vứt đi — nó được ghi vào artifact của phase phụ trách nó.

## 4. Không phá trạng thái sẵn có

Phase ghi artifact mới thì không được xoá artifact của phase trước. Chạy lại một
phase là **cập nhật**, không phải viết đè trắng — vì phần lớn lần chạy lại xảy
ra sau khi người đã sửa tay vào file.

## 5. Ngôn ngữ

Nội dung người và agent đọc: tiếng Việt. Định danh trong code (mã yêu cầu, tên
file, khoá cấu hình): tiếng Anh ASCII, không dấu.
