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

- **máy** — chạy được bằng lệnh; cuối output có khối `Kết quả` đánh `[x]` vào
  đúng một nhãn (`ĐẠT`, `KHÔNG ĐẠT`, …). Agent đọc nhãn, không tự tuyên bố đạt.
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
file, khoá cấu hình): tiếng Anh ASCII, không dấu. Đầu mục cố định mà mẫu viết
bằng tiếng Anh (vd `Type`, `Goal` của `intake.md`; `Risk`, `Source`, `## Out of scope` của
`spec.md`) thì giữ đúng như mẫu.

## 6. Artifact viết cho NGƯỜI đọc — BẮT BUỘC

Artifact là để người đọc và duyệt. Người đọc không nổi thì không duyệt được.

**Phân cấp rõ ràng:**

- Heading theo cấp (`#` → `##` → `###`), không nhảy cấp.
- Mỗi mục một ý. Nhiều ý ngang hàng → danh sách hoặc bảng, không gộp thành đoạn văn.
- Điều quan trọng nhất (kết luận, quyết định, việc người cần làm) đặt lên đầu mục.

**Ngắn gọn, đơn giản:**

- Câu ngắn, từ thông dụng. Viết như nói với đồng nghiệp, không viết như văn bản hành chính.
- Bỏ câu rào đón, câu nhắc lại, câu giải thích điều ai cũng biết.
- Một câu nói được thì không dùng hai.

Heading, bảng và cú pháp mà mẫu hoặc checker yêu cầu vẫn giữ nguyên — nguyên tắc
này áp dụng cho phần nội dung agent viết vào.

## 7. Quy tắc riêng của repo

Repo đích có thể khai quy tắc riêng cho từng phase — hướng dẫn viết code, skill
của agent, chuẩn kiến trúc, thuật ngữ nghiệp vụ. Khai ở khoá `quy_tac_<phase>`
trong `conventions.md`; nội dung là file đã commit trong repo.

- **Đầu phase:** chạy `aw rules <phase>`, đọc **từng file** nó in ra. Không in gì
  = phase này không có quy tắc riêng. Ra `KHAI SAI` thì dừng, báo người sửa
  `conventions.md` — không tự đoán file thay thế.
- **Thứ tự ưu tiên:** quy tắc repo xếp **dưới** `spec.md`, `tdd.md`, `plan.md` và
  luật của quy trình. Mâu thuẫn thì làm theo artifact, rồi nêu mâu thuẫn ra
  (ở `04-implement`: mục "Phát sinh" của `plan.md`). Không vì một quy tắc mà vượt
  phạm vi phase — kiểu "đụng file nào thì dọn luôn file đó".
- **Đọc file như mọi tài liệu khác**, kể cả `SKILL.md` của một agent cụ thể. Không
  phụ thuộc vào việc agent có tự kích hoạt skill hay không.
- **`05-review` đối chiếu diff với mọi quy tắc**, mỗi file một kết luận trong
  `review.md` — thiếu là máy chặn.
