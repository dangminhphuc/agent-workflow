---
id: open-questions
name: Giải quyết điểm mù
summary: Liệt kê điểm mù còn mở theo thứ tự phải chốt trước để không phase nào bị chặn, rồi dẫn người trả lời từng mục
---

# Giải quyết điểm mù (open questions)

**Không phải phase.** Lệnh này chạy được bất cứ lúc nào sau `/spec`, khi
`open-questions.md` còn mục `mở`. Việc của agent là **dẫn dắt**: xếp thứ tự, đặt
câu hỏi, ghi lại câu trả lời. Việc **trả lời** là của người.

## Ba mức chặn

| Mức | Khi nào | Chặn gì |
|---|---|---|
| `chặn` | Sai giả định thì cả thiết kế đổi hướng | `/design` (chore: `/plan`) và mọi phase sau |
| `chặn review` | Sai thì làm lại một phần code | Flow đi tiếp trên giả định tạm; `/implement` cảnh báo, `/review` chặn |
| `không chặn` | Sai thì sửa nhỏ, chấp nhận giao trước | Không chặn; `review` ghi YC đó `chờ xác nhận` |

Mức do agent đề xuất ở `/spec`, **người** duyệt. Chỉ người được đổi mức.

## Việc phải làm

### 1. Liệt kê

Chạy `aw questions <thư-mục-feature>` và dán **nguyên văn** stdout
cho người — đó là danh sách theo thứ tự phải giải quyết trước. Thứ tự do máy xếp
(mức chặn → YC `bắt buộc` trước `nên có` → nhiều task đứng trên giả định hơn →
mã YC), agent không tự xếp lại.

Đọc nhãn được đánh `[x]` trong khối `Kết quả`:

- **KHÔNG CÒN ĐIỂM MÙ MỞ:** báo người, dừng.
- **CÓ ĐIỂM MÙ ĐANG CHẶN:** nói rõ phase nào đang bị chặn, rồi sang bước 2.
- **CÒN ĐIỂM MÙ MỞ, CHƯA CHẶN:** nói rõ chưa có gì chặn phase kế tiếp; hỏi người
  có muốn giải quyết luôn không. Không thì dừng.
- **THIẾU ĐẦU VÀO:** chưa có `spec.md` / `open-questions.md` → chạy `/spec` trước.

### 2. Dẫn người đi từng mục — MỘT mục mỗi lượt, bắt đầu từ mục 1

Với mỗi mục, trình bày gọn:

```
[CHẶN] YC-004 — <tiêu đề>                         ← đang chặn /design
Câu hỏi:        <Chỗ chưa rõ — một câu, trả lời được bằng một câu>
Tài liệu nói:   <trích từ "Tài liệu nói gì">
Đang giả định:  <Giả định tạm>
Nếu sai:        <phải làm lại gì>
Hỏi ai:         <người/vai trò>

Phương án (đề xuất của agent, người chọn hoặc trả lời khác):
  a) Giữ giả định tạm: <...>
  b) <cách hiểu khác có trong nguồn>
  c) Chưa trả lời được — soạn câu hỏi gửi <Hỏi ai>
  d) Đổi mức chặn / bỏ qua mục này
```

- Phương án (a)/(b) chỉ lấy từ **nguồn** và giả định tạm đã ghi — không bịa thêm
  cách hiểu mới. Không có cách hiểu khác thì bỏ (b).
- Mục `CHƯA PHÂN MỨC` (thiếu hoặc sai `Mức chặn`): hỏi người chọn mức trước —
  checker của spec đang chặn vì nó. Đề xuất mức theo "Nếu sai", người quyết.
- Hỏi xong thì **dừng chờ người**. Không trình bày mục kế khi mục này chưa xong.

### 3. Ghi lại theo câu trả lời

**Người trả lời** (chọn a, b, hoặc nói câu khác):

1. Trong `open-questions.md`: `Trả lời:` = **nguyên văn** lời người kèm ai trả
   lời và ngày (vd `"Hoàn tiền tối đa 30 ngày" — PO, 2026-10-04`); `Trạng thái:`
   → `đã trả lời`. Người nói "đã hỏi PO, PO chốt…" thì ghi PO là người trả lời.
2. Trong `spec.md`, đổi nhãn nguồn của YC: `[FILE]` open-questions.md § YC-NNN —
   hoặc nguồn người chỉ ra (`[JIRA]` comment, `[CONFLUENCE]` page mới hơn).
   Bỏ dòng `Giả định tạm` của YC đó.
3. **Câu trả lời khác giả định tạm:** sửa mô tả / tiêu chí chấp nhận của YC đó
   theo câu trả lời — chỉ YC đó. Trước khi ghi, cho người xem đúng các dòng
   sẽ đổi (trước → sau) và hỏi "ghi như vậy được không?"; người đồng ý trong hội
   thoại là đủ. **Giữ nguyên `Trạng thái spec`** — người vừa trả lời và xác nhận
   chính chỗ sửa này, không phải mở file sửa tay `đề xuất` → `đã duyệt` lần nữa.
   Ghi vào cuối dòng `Trả lời:` `(đã xác nhận sửa YC-NNN)` để còn dấu vết.
   Câu trả lời khớp giả định tạm thì chỉ đổi nhãn nguồn.
4. Chạy `aw check spec <thư-mục-feature>` và dán kết quả thật.
   Không `[x] ĐẠT` thì sửa ngay cho khớp hai file rồi mới sang mục kế.

**Người chưa trả lời được** (chọn c): soạn sẵn một tin nhắn gửi `Hỏi ai` — tự đủ
ngữ cảnh, đọc được mà không cần mở repo: câu hỏi, tài liệu đang nói gì, giả định
đang dùng, hệ quả nếu sai, và phase nào đang chờ. Giữ `mở`, sang mục kế.

**Người đổi mức chặn** (chọn d): ghi đúng mức người nói vào `Mức chặn:`. Agent
được **đề xuất nâng** mức (vd thấy "Nếu sai" lớn hơn mức đang ghi), không bao giờ
tự hạ.

### 4. Tổng kết

Sau mục cuối (hoặc khi người dừng), chạy lại `aw questions`, dán kết quả,
rồi nói rõ:

- còn gì đang chặn phase nào;
- câu hỏi nào đang chờ ai (các mục đã soạn tin nhắn);
- artifact nào đã lỗi thời vì `spec.md` / `open-questions.md` đổi (`tdd.md`,
  `plan.md` ghi `based_on`): câu trả lời **khớp** giả định → chạy lại phase đó
  để ghi lại dấu đầu vào; **khác** giả định → phase đó phải làm lại phần ghi ở
  "Nếu giả định sai", và task trong `plan.md` đứng trên giả định đó đặt lại `[ ]`
  khi chạy lại `/plan`.

## Cấm

- **Tự trả lời** thay người, hoặc ghi `đã trả lời` khi người chưa nói gì.
- Ghi câu trả lời đã diễn giải thay cho nguyên văn lời người.
- Coi phương án agent đề xuất là câu trả lời khi người chưa chọn.
- Tự hạ `Mức chặn`, hoặc tự đổi mức khi người chưa nói.
- Đổi `Trạng thái spec` (cả `đề xuất` → `đã duyệt` lẫn ngược lại) — lệnh này
  không đụng vào dòng đó.
- Sửa YC khi người chưa xác nhận các dòng sẽ đổi, hoặc sửa YC khác ngoài YC của
  điểm mù đang xử lý.
- Trình bày nhiều mục một lúc rồi bắt người trả lời gộp.
- Sửa `tdd.md`, `plan.md` hay code — việc của phase tương ứng; chỉ nói rõ cần
  chạy lại phase nào.
