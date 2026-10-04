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

## Trạng thái — chỉ người đóng một điểm mù

| Trạng thái | Ai ghi | Gỡ chặn? |
|---|---|---|
| `mở` | agent (ở `/spec`) | không |
| `đã trả lời` | agent, sau khi ghi **nguyên văn** câu trả lời của người | **không** — chờ người duyệt |
| `đã duyệt` | **chỉ người, sửa tay** trong `open-questions.md` | có |

Người duyệt là xác nhận hai việc agent vừa làm: câu trả lời được ghi đúng ý mình,
và spec được sửa đúng theo câu trả lời. Giống `Trạng thái spec` và D-xx: agent
ghi xong thì dừng, không bao giờ tự đổi sang `đã duyệt` — kể cả khi người nói
"duyệt đi" trong hội thoại. Dấu vết duyệt phải là chính tay người sửa file.

## Việc phải làm

### 1. Liệt kê

Chạy `sh tools/liet-ke-cau-hoi.sh <thư-mục-feature>` và dán **nguyên văn** stdout
cho người — đó là danh sách theo thứ tự phải giải quyết trước. Thứ tự do máy xếp
(mức chặn → YC `bắt buộc` trước `nên có` → nhiều task đứng trên giả định hơn →
mã YC), agent không tự xếp lại.

Đọc nhãn được đánh `[x]` trong khối `Kết quả`:

- **KHÔNG CÒN ĐIỂM MÙ CHƯA DUYỆT:** báo người, dừng.
- **CÓ ĐIỂM MÙ ĐANG CHẶN:** nói rõ phase nào đang bị chặn, rồi sang bước 2.
- **CÒN ĐIỂM MÙ CHƯA DUYỆT, CHƯA CHẶN:** nói rõ chưa có gì chặn phase kế tiếp; hỏi người
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
- Mục `ĐÃ TRẢ LỜI, CHỜ NGƯỜI DUYỆT`: không hỏi lại. Cho người xem câu trả lời
  đã ghi và chỗ spec đã sửa (trích đúng dòng), rồi nhắc: *mở
  `open-questions.md`, tự sửa `Trạng thái` của mục này sang `đã duyệt`*. Ghi sai
  thì người nói — agent sửa lại câu trả lời / spec, giữ `đã trả lời`.
- Mục `CHƯA PHÂN MỨC` (thiếu hoặc sai `Mức chặn`): hỏi người chọn mức trước —
  checker của spec đang chặn vì nó. Đề xuất mức theo "Nếu sai", người quyết.
- Hỏi xong thì **dừng chờ người**. Không trình bày mục kế khi mục này chưa xong.

### 3. Ghi lại theo câu trả lời

**Người trả lời** (chọn a, b, hoặc nói câu khác):

1. Trong `open-questions.md`: `Trả lời:` = **nguyên văn** lời người kèm ai trả
   lời và ngày (vd `"Hoàn tiền tối đa 30 ngày" — PO, 2026-10-04`); `Trạng thái:`
   → `đã trả lời` (không phải `đã duyệt`). Người nói "đã hỏi PO, PO chốt…" thì
   ghi PO là người trả lời.
2. Trong `spec.md`, đổi nhãn nguồn của YC: `[FILE]` open-questions.md § YC-NNN —
   hoặc nguồn người chỉ ra (`[JIRA]` comment, `[CONFLUENCE]` page mới hơn).
   Bỏ dòng `Giả định tạm` của YC đó.
3. **Câu trả lời khác giả định tạm:** sửa mô tả / tiêu chí chấp nhận của YC đó
   theo câu trả lời — chỉ YC đó — và đặt lại `Trạng thái spec: đề xuất`: spec đã
   đổi nghĩa, người phải duyệt lại. Câu trả lời khớp giả định tạm thì chỉ đổi
   nhãn nguồn, giữ `Trạng thái spec`.
4. Chạy `sh tools/kiem-tra-truy-vet.sh <thư-mục-feature>` và dán kết quả thật.
   Không `[x] ĐẠT` thì sửa ngay cho khớp hai file rồi mới sang mục kế.
5. **Dừng cho người duyệt.** Nói rõ: mục này **vẫn chặn** cho tới khi người mở
   `open-questions.md` và tự sửa `Trạng thái` sang `đã duyệt`.

**Người chưa trả lời được** (chọn c): soạn sẵn một tin nhắn gửi `Hỏi ai` — tự đủ
ngữ cảnh, đọc được mà không cần mở repo: câu hỏi, tài liệu đang nói gì, giả định
đang dùng, hệ quả nếu sai, và phase nào đang chờ. Giữ `mở`, sang mục kế.

**Người đổi mức chặn** (chọn d): ghi đúng mức người nói vào `Mức chặn:`. Agent
được **đề xuất nâng** mức (vd thấy "Nếu sai" lớn hơn mức đang ghi), không bao giờ
tự hạ.

### 4. Tổng kết

Sau mục cuối (hoặc khi người dừng), chạy lại `liet-ke-cau-hoi.sh`, dán kết quả,
rồi nói rõ:

- còn gì đang chặn phase nào;
- mục nào `đã trả lời` đang chờ người sửa tay sang `đã duyệt` — liệt kê mã, đây
  thường là cách gỡ chặn nhanh nhất;
- câu hỏi nào đang chờ ai (các mục đã soạn tin nhắn);
- `Trạng thái spec` có bị đặt lại `đề xuất` không — có thì người duyệt lại spec
  trước khi chạy phase sau;
- artifact nào đã lỗi thời vì `spec.md` / `open-questions.md` đổi (`tdd.md`,
  `plan.md` ghi `based_on`): câu trả lời **khớp** giả định → chạy lại phase đó
  để ghi lại dấu đầu vào; **khác** giả định → phase đó phải làm lại phần ghi ở
  "Nếu giả định sai", và task trong `plan.md` đứng trên giả định đó đặt lại `[ ]`
  khi chạy lại `/plan`.

## Cấm

- **Tự trả lời** thay người, hoặc ghi `đã trả lời` khi người chưa nói gì.
- **Tự đổi `Trạng thái` sang `đã duyệt`** — kể cả khi người bảo "duyệt giúp".
  Chỉ người sửa tay.
- Ghi câu trả lời đã diễn giải thay cho nguyên văn lời người.
- Coi phương án agent đề xuất là câu trả lời khi người chưa chọn.
- Tự hạ `Mức chặn`, hoặc tự đổi mức khi người chưa nói.
- Đổi `Trạng thái spec` sang `đã duyệt`.
- Trình bày nhiều mục một lúc rồi bắt người trả lời gộp.
- Sửa `tdd.md`, `plan.md` hay code — việc của phase tương ứng; chỉ nói rõ cần
  chạy lại phase nào.
