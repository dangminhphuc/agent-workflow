# Luật: Truy vết nguồn

Luật này áp dụng cho `01-spec` và được `02-design`, `05-review` kiểm tra lại (checker của phase sau chạy lại checker của spec trên đầu vào).

## Vì sao có luật này

Khi yêu cầu đến từ tài liệu thượng nguồn (BRD/PRD/Jira/Confluence), thất bại
nguy hiểm nhất của agent **không phải** viết sai code — mà là **tự nghĩ ra yêu
cầu rồi trình bày như thể tài liệu đã nói**. Lỗi này rất khó phát hiện: nó đọc
trôi chảy, hợp lý, và chỉ lộ ra khi BA/PO đọc lại ở cuối sprint.

Luật truy vết biến nó từ lỗi ngữ nghĩa (phải có người đọc mới thấy) thành lỗi
cú pháp (máy kiểm được).

## Nội dung luật

Mỗi yêu cầu trong `spec.md` phải có đúng một dòng `Source:` mang một nhãn:

| Nhãn | Nghĩa | Bắt buộc kèm theo |
|---|---|---|
| `[CONFLUENCE]` | Trích từ page Confluence | URL page + tên heading |
| `[JIRA]` | Trích từ issue Jira | Mã issue + URL |
| `[FILE]` | Trích từ tài liệu trong repo | Đường dẫn + heading |
| `[SUY-RA]` | Quyết định kỹ thuật tự suy ra | Lý do, và yêu cầu gốc nó phục vụ |
| `[CẦN-HỎI]` | Chưa có nguồn, đang dùng giả định | Mục tương ứng trong `open-questions.md` |

**Yêu cầu không có nhãn = fail.** Không có nhãn thứ sáu. Nếu một mục không
xếp được vào năm nhãn trên thì nó không phải yêu cầu — nó là ý tưởng của agent,
và chỗ của nó là `open-questions.md`.

## Ranh giới dễ nhầm giữa `[SUY-RA]` và `[CẦN-HỎI]`

Đây là chỗ agent hay lách luật, nên phân định rõ:

- `[SUY-RA]` — **quyết định kỹ thuật** mà tài liệu nghiệp vụ không cần nói, và
  người khác đọc xong sẽ đồng ý là hiển nhiên. Ví dụ: "dùng index trên cột
  `created_at`" khi BRD yêu cầu lọc theo ngày.
- `[CẦN-HỎI]` — **quyết định nghiệp vụ** mà tài liệu bỏ trống, và người khác có
  thể chọn khác. Ví dụ: BRD nói "thông báo cho người dùng" nhưng không nói qua
  email hay in-app.

Phép thử: *nếu BA/PO đọc mục này mà có thể trả lời "không, ý tôi khác" thì nó là
`[CẦN-HỎI]`, không phải `[SUY-RA]`.*

Gắn `[SUY-RA]` cho một quyết định nghiệp vụ là cách agent che giấu điểm mù —
và là vi phạm nặng hơn việc bỏ trống nhãn, vì nó không kiểm được bằng máy.

## Kiểm tra

```
aw check spec <thư-mục-artifact>
```

Kiểm mười một điều:
1. Mọi `### YC-NNN` trong `spec.md` có đúng một dòng `Source:` với nhãn hợp lệ.
   Vùng của một YC kết thúc ở heading `##` hoặc `###` kế tiếp — dòng `Source:`
   dưới `### Ghi chú` không được tính cho YC phía trên.
2. Mọi mục gắn `[CẦN-HỎI]` có mục tương ứng cùng mã trong `open-questions.md`.
3. Không có mã `YC-NNN` trùng nhau.
4. Mục `[CẦN-HỎI]` trong `open-questions.md` có dòng "Giả định tạm" — không có thì phase sau không đi tiếp được.
5. Mục `[CẦN-HỎI]` có `Mức chặn: chặn | chặn review | không chặn`. Mục `chặn`
   còn `Trạng thái: mở` thì chặn vào design (chore: plan); mục `chặn review` còn
   mở thì `implement` cảnh báo, `review` chặn.
6. `spec.md` có `Risk: cao | thường` và `Status: đề xuất | đã duyệt`.
7. `open-questions.md` khớp `spec.md` theo chiều ngược lại: mỗi mục trỏ về một YC
   có thật; `Trạng thái` là `mở | đã trả lời`; `mở` thì spec phải còn `[CẦN-HỎI]`;
   `đã trả lời` thì phải có dòng "Trả lời" và spec đã đổi nhãn nguồn.
8. `open-questions.md` 0 byte là hợp lệ (đã rà, không có điểm mù).
9. Mọi YC có `Priority: bắt buộc | nên có` và ít nhất một tiêu chí chấp nhận
   `- [ ] …` có nội dung thật (không phải `<...>`, không nằm trong comment HTML).
10. `spec.md` có đủ `## Constraints & dependencies`, `## Out of scope`,
    `## Source conflicts`, mỗi mục có nội dung thật — không có gì thì
    ghi thẳng "Không có…" / "Không phát hiện mâu thuẫn.".
11. Mỗi dòng trong bảng mâu thuẫn có cột "Xử lý" trỏ tới một điểm mù có thật
    (`open-questions.md § YC-NNN`) hoặc một nguồn đã chốt (`[CONFLUENCE]`
    `[JIRA]` `[FILE]`). Mâu thuẫn nghiệp vụ mà agent tự phân xử cũng là tự nghĩ
    ra yêu cầu — chỉ khác là có hai câu trích để che.

Điều thứ 2 quan trọng: không có nó thì agent chỉ cần gắn `[CẦN-HỎI]` là qua được
kiểm tra mà chẳng phải hỏi ai. Điều thứ 7 giữ cho hai file không lệch nhau khi
điểm mù được trả lời — lệch thì `review` buộc "chờ xác nhận" cho một YC đã có
câu trả lời, hoặc design chặn vì một mục mồ côi.
