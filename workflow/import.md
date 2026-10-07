---
id: import
name: Import artifact từ ngoài
summary: Đưa artifact làm bằng tool khác vào đúng phase — chỉ sắp xếp lại, không thêm nội dung
arguments: mixed
argument_hint: <file-nguồn> <spec.md|tdd.md|plan.md> [tên-feature]
---

# Import artifact từ ngoài vào

**Không phải phase.** Đây là bước chuyển đổi có kiểm soát để một tài liệu làm
bằng tool khác (AI khác, Confluence, viết tay…) vào được giữa quy trình.

## Tham số

- Đường dẫn file nguồn (hoặc URL Confluence/Jira)
- Artifact đích: `spec.md` | `tdd.md` | `plan.md`

Thiếu một trong hai thì dừng lại hỏi.

## Việc phải làm

1. Đọc hết tài liệu nguồn. Ghi lại định danh chính xác (đường dẫn / URL).
2. Đọc mẫu `templates/<artifact-đích>` và điều kiện ra của phase sinh ra nó.
3. **Sắp xếp lại** nội dung nguồn theo mẫu:
   - mỗi mục mang nhãn nguồn trỏ về tài liệu gốc (`[FILE] <đường dẫn> § <heading>`,
     `[CONFLUENCE] <URL> § <heading>`…);
   - chỗ mẫu đòi mà nguồn không có: **không lấp**. Với `spec.md` ghi
     `[CẦN-HỎI]` + mục trong `open-questions.md`; với mục khác của `tdd.md` /
     `plan.md` ghi `<THIẾU TRONG NGUỒN: …>` để checker chặn và người thấy.
   - D-xx lấy từ tài liệu người viết thì `tac_gia: nguoi`, `Trạng thái: đề xuất`.
4. Chạy **checker của phase sinh ra artifact đó** (`aw check spec`,
   `aw check design`, `aw check plan`) và báo kết quả thật.
5. Dừng lại cho **người xác nhận bản chuyển đổi** — rồi mới qua gate người của
   phase đó (duyệt YC, duyệt từng D-xx…), như khi agent tự viết.

## Cấm

- **Thêm nội dung** không có trong nguồn — kể cả khi "hiển nhiên". Nếu được
  thêm, suy đoán của agent sẽ mang nhãn nguồn như thể có trong tài liệu gốc.
- Đổi `Trạng thái` của D-xx hay `Status` của spec sang `đã duyệt`, kể cả khi tài
  liệu nguồn nói đã duyệt: duyệt ở tool khác không phải duyệt trong quy trình này.
- Bỏ qua checker vì "tài liệu đã được duyệt ở chỗ khác".
