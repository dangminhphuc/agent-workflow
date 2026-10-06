---
id: open-questions
choice_ui: true
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

### 1. Liệt kê — cho agent đọc, KHÔNG dán cho người

Chạy `aw questions <thư-mục-feature>`. Output là **dữ liệu cho
agent**: thứ tự phải giải quyết (máy xếp: mức chặn → YC `bắt buộc` trước `nên có`
→ nhiều task đứng trên giả định hơn → mã YC; agent không tự xếp lại) và chi tiết
từng mục. **Không dán danh sách cho người.** Người chỉ thấy một dòng tóm tắt:

```
Còn 8 điểm mù: 2 đang chặn /design (YC-001, YC-002), 6 chưa chặn. Bắt đầu từ YC-001.
```

Người hỏi "cho xem hết" thì mới in danh sách (mã + tiêu đề + mức, mỗi mục một dòng).

Đọc nhãn được đánh `[x]` trong khối `Kết quả`:

- **KHÔNG CÒN ĐIỂM MÙ MỞ:** báo người một dòng, dừng.
- **CÓ ĐIỂM MÙ ĐANG CHẶN:** tóm tắt như trên, sang bước 2.
- **CÒN ĐIỂM MÙ MỞ, CHƯA CHẶN:** tóm tắt, rồi hỏi bằng lựa chọn: "Giải quyết
  luôn" / "Để sau". Để sau thì dừng.
- **THIẾU ĐẦU VÀO:** chưa có `spec.md` / `open-questions.md` → chạy `/spec` trước.

### 2. Hỏi từng mục bằng câu hỏi lựa chọn — MỘT mục mỗi lượt, theo thứ tự

Mỗi mục là **một câu hỏi lựa chọn**. Ngữ cảnh đi kèm ngắn, chỉ đủ để chọn:

```
YC-001 · CHẶN · đang chặn /design · 1/8
Cơ chế ký là HMAC (secret chung) hay chữ ký bất đối xứng (public key)?
  Tài liệu: Input 1 "Apply HMAC…"; Input 2 § 4 "Dùng cặp key…"
  Nếu sai:  làm lại xác minh chữ ký + cấu hình key (kéo theo YC-002, YC-006)
  Hỏi ai:   Security + SAP/MuleSoft
```

Lựa chọn, theo đúng thứ tự này:

1. **Giữ giả định tạm** — `<giả định>`; mô tả: hệ quả nếu chọn.
2. **`<cách hiểu khác có trong nguồn>`** — chỉ khi nguồn thật sự có cách hiểu
   khác. Tối đa **một** lựa chọn loại này; nguồn có nhiều hơn thì nêu các cách
   còn lại trong ngữ cảnh, người chọn qua ô tự nhập. Không bịa cách hiểu mới để
   cho đủ lựa chọn.
3. **Chưa trả lời được** — agent soạn tin nhắn gửi `<Hỏi ai>`.
4. **Chat về câu này** — người muốn hỏi lại, trao đổi trước khi chốt.

Và **luôn** có ô để người **tự nhập** câu trả lời khác — kể cả "đổi mức chặn
sang …" hay "bỏ qua".

Cách hiện lựa chọn tuỳ agent: có giao diện hỏi lựa chọn thì dùng nó; không có
thì in các lựa chọn đánh số kèm dòng "hoặc gõ câu trả lời khác".

- Mục `CHƯA PHÂN MỨC` (thiếu hoặc sai `Mức chặn`): câu hỏi đầu tiên của mục là
  chọn mức (`chặn` / `chặn review` / `không chặn`, gợi ý theo "Nếu sai") — checker
  của spec đang chặn vì nó. Xong mới hỏi câu trả lời.
- Hỏi xong thì **dừng chờ người**. Không hỏi mục kế khi mục này chưa xong.
- **Chat về câu này:** trả lời câu hỏi của người, giải thích hệ quả từng lựa chọn,
  trích thêm nguồn nếu cần — **không ghi gì vào file**. Người nói đã rõ (hoặc
  sau vài lượt trao đổi) thì hỏi lại đúng câu đó bằng lựa chọn. Trong lúc chat mà
  người nói ra câu trả lời thì xác nhận lại bằng lựa chọn trước khi ghi.

### 3. Ghi lại theo câu trả lời

**Người trả lời** (chọn lựa chọn 1, 2, hoặc tự nhập):

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

**Người chưa trả lời được** (chọn "Chưa trả lời được"): soạn sẵn một tin nhắn gửi `Hỏi ai` — tự đủ
ngữ cảnh, đọc được mà không cần mở repo: câu hỏi, tài liệu đang nói gì, giả định
đang dùng, hệ quả nếu sai, và phase nào đang chờ. Giữ `mở`, sang mục kế.

**Người đổi mức chặn** (tự nhập, hoặc nói trong lúc chat): ghi đúng mức người nói vào `Mức chặn:`. Agent
được **đề xuất nâng** mức (vd thấy "Nếu sai" lớn hơn mức đang ghi), không bao giờ
tự hạ.

### 4. Tổng kết

Sau mục cuối (hoặc khi người dừng), chạy lại `aw questions` (đọc, không dán),
rồi nói ngắn gọn:

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
- Dán nguyên danh sách của `aw questions` cho người khi người không yêu cầu.
- Bỏ lựa chọn tự nhập hoặc "Chat về câu này" khỏi câu hỏi.
- Sửa `tdd.md`, `plan.md` hay code — việc của phase tương ứng; chỉ nói rõ cần
  chạy lại phase nào.
