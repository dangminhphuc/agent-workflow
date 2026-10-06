---
id: clarify
choice_ui: true
name: Làm rõ với người
summary: Gom mọi việc đang chờ người quyết (điểm mù, phát hiện của checker LLM) theo thứ tự phải chốt trước để không phase nào bị chặn, rồi dẫn người đi từng mục
---

# Làm rõ với người (clarify)

**Không phải phase.** Lệnh này chạy được bất cứ lúc nào sau `/spec`. Nó gom
**mọi việc máy/LLM cần người quyết** vào một hàng đợi và dẫn người đi từng mục.
Việc của agent là **dẫn dắt**: đặt câu hỏi, ghi lại quyết định. Việc **quyết**
là của người.

## Hai nguồn, mỗi nguồn giữ file riêng

| Nguồn | File | Người làm gì | Chặn gì |
|---|---|---|---|
| Điểm mù | `open-questions.md` (do `/spec` ghi) | **Trả lời** — thường phải hỏi PO/BA | Theo `Mức chặn` (bảng dưới) |
| Phát hiện checker LLM | `phat-hien-<checker>.md` (hiện có `phat-hien-thiet-ke.md`) | **Phân xử** — đồng ý (sửa) hoặc bác bỏ kèm lý do | Mức `Chặn`: checker của phase đó (`thiết kế` → `/plan`); `Cảnh báo`: không chặn |

Không gộp hai file: mỗi file có một bên ghi và một vòng đời riêng, và `based_on`
băm cả file — gộp lại thì checker LLM ghi phát hiện sẽ làm `tdd.md` "lỗi thời".
Hàng đợi chỉ gộp ở **chỗ người nhìn**, không gộp chỗ lưu.

### Ba mức chặn của điểm mù

| Mức | Khi nào | Chặn gì |
|---|---|---|
| `chặn` | Sai giả định thì cả thiết kế đổi hướng | `/design` (chore: `/plan`) và mọi phase sau |
| `chặn review` | Sai thì làm lại một phần code | Flow đi tiếp trên giả định tạm; `/implement` cảnh báo, `/review` chặn |
| `không chặn` | Sai thì sửa nhỏ, chấp nhận giao trước | Không chặn; `review` ghi YC đó `chờ xác nhận` |

Mức do agent đề xuất ở `/spec`, **người** duyệt. Chỉ người được đổi mức.

## Việc phải làm

### 1. Liệt kê — cho agent đọc, KHÔNG dán cho người

Chạy `aw pending <thư-mục-feature>`. Output là **dữ liệu cho agent**: thứ tự
phải giải quyết (máy xếp, agent không tự xếp lại) và chi tiết từng mục. Máy xếp
nhóm chặn phase sớm hơn lên trước:

1. điểm mù chưa phân mức → 2. điểm mù `chặn` → 3. phát hiện `Chặn` →
4. điểm mù `chặn review` → 5. phát hiện `Cảnh báo` → 6. điểm mù `không chặn`.

Trong nhóm điểm mù: YC `bắt buộc` trước `nên có` → nhiều task đứng trên giả
định hơn → mã YC.

**Không dán danh sách cho người.** Người chỉ thấy một dòng tóm tắt:

```
Còn 6 việc chờ bạn: 3 đang chặn (YC-001, YC-002 chặn /design; PH-03 chặn /plan), 3 chưa chặn. Bắt đầu từ YC-001.
```

Người hỏi "cho xem hết" thì mới in danh sách (mã + tiêu đề + nhóm, mỗi mục một dòng).

Đọc nhãn được đánh `[x]` trong khối `Kết quả`:

- **KHÔNG CÒN VIỆC CHỜ NGƯỜI:** báo người một dòng (kèm nhóm `[ĐÃ XỬ LÝ]` nếu
  có — xem bước 4), dừng.
- **CÓ VIỆC ĐANG CHẶN:** tóm tắt như trên, sang bước 2.
- **CÒN VIỆC CHỜ NGƯỜI, CHƯA CHẶN:** tóm tắt, rồi hỏi bằng lựa chọn: "Giải quyết
  luôn" / "Để sau". Để sau thì dừng.
- **THIẾU ĐẦU VÀO:** chưa có `spec.md` / `open-questions.md` → chạy `/spec` trước.

### 2. Hỏi từng mục bằng câu hỏi lựa chọn — MỘT mục mỗi lượt, theo thứ tự

Mỗi mục là **một câu hỏi lựa chọn**, ngữ cảnh ngắn, chỉ đủ để chọn. Dòng đầu
luôn: mã · nhóm · đang chặn gì · vị trí trong hàng đợi.

Mọi câu hỏi, mọi nguồn, **luôn** có:
- lựa chọn **Chat về câu này** — người muốn hỏi lại, trao đổi trước khi chốt;
- ô để người **tự nhập** câu trả lời khác.

Cách hiện lựa chọn tuỳ agent: có giao diện hỏi lựa chọn thì dùng nó; không có
thì in các lựa chọn đánh số kèm dòng "hoặc gõ câu trả lời khác".

#### 2a. Điểm mù

```
YC-001 · CHẶN · đang chặn /design · 1/6
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
4. **Chat về câu này**.

Ô tự nhập nhận cả "đổi mức chặn sang …" hay "bỏ qua".

Mục `CHƯA PHÂN MỨC` (thiếu hoặc sai `Mức chặn`): câu hỏi đầu tiên của mục là
chọn mức (`chặn` / `chặn review` / `không chặn`, gợi ý theo "Nếu sai") — checker
của spec đang chặn vì nó. Xong mới hỏi câu trả lời.

#### 2b. Phát hiện của checker LLM

Trước khi hỏi, **đọc đúng chỗ `Vị trí` trong `tdd.md`** (hoặc artifact checker
đó soát) để ngữ cảnh nói được phát hiện chạm vào dòng nào.

```
PH-03 · CHẶN · đang chặn /plan · 3/6 · quyết định ngầm
tdd.md § Contract API: chọn gRPC cho webhook nội bộ nhưng không nêu thành D-xx.
  Checker nói: khó đảo ngược (contract ngoài); người khác có thể chọn REST.
  Nếu đồng ý: thêm D-xx mới (đề xuất: gRPC, phương án loại: REST) — bạn duyệt sau.
```

Lựa chọn, theo đúng thứ tự này:

1. **Đồng ý — sửa** — mô tả: agent sẽ sửa gì (một câu) để hết phát hiện.
2. **Bác bỏ** — mô tả: "nhập lý do ở ô tự nhập". Người chọn mà không kèm lý do
   thì hỏi lý do — bác bỏ không lý do là `aw check` chặn.
3. **Chat về câu này**.

Mục `Cảnh báo` thêm lựa chọn **Để sau** (giữ `chưa`, sang mục kế).

#### Chung cho mọi mục

- Hỏi xong thì **dừng chờ người**. Không hỏi mục kế khi mục này chưa xong.
- **Chat về câu này:** trả lời câu hỏi của người, giải thích hệ quả từng lựa chọn,
  trích thêm nguồn nếu cần — **không ghi gì vào file**. Người nói đã rõ (hoặc
  sau vài lượt trao đổi) thì hỏi lại đúng câu đó bằng lựa chọn. Trong lúc chat mà
  người nói ra quyết định thì xác nhận lại bằng lựa chọn trước khi ghi.

### 3. Ghi lại theo quyết định

#### 3a. Điểm mù

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

#### 3b. Phát hiện của checker LLM

**Người đồng ý:**

1. Cho người xem đúng các dòng sẽ đổi trong `tdd.md` (trước → sau) và hỏi "ghi
   như vậy được không?"; người đồng ý trong hội thoại là đủ. Chỉ sửa đúng chỗ
   phát hiện chỉ ra.
2. Phát hiện cần một quyết định (`quyết định ngầm`, `lệch D-xx` mà người muốn đổi
   D): thêm/sửa D-xx với `Trạng thái: đề xuất` (sửa D đã duyệt thì theo mục "Mở
   lại một quyết định" của `/design`). **Không** ghi `đã duyệt` — người duyệt D
   như mọi D khác.
3. Phát hiện `yêu cầu mới`: người đồng ý là **bỏ hành vi đó khỏi `tdd.md`**.
   Người muốn giữ hành vi đó thì đó là yêu cầu mới — báo người phải quay lại
   `/spec`, không tự thêm YC.
4. Trong file phát hiện: `Xử lý:` → `đã sửa`.
5. Chạy `aw check design <thư-mục-feature>` và dán kết quả thật.

**Người bác bỏ:** `Xử lý:` → `bác bỏ: <lý do nguyên văn của người> — <ai>, <ngày>`.
Không sửa `tdd.md`.

**Để sau** (chỉ `Cảnh báo`): giữ `chưa`, sang mục kế.

### 4. Tổng kết

Sau mục cuối (hoặc khi người dừng), chạy lại `aw pending` (đọc, không dán),
rồi nói ngắn gọn:

- còn gì đang chặn phase nào;
- câu hỏi nào đang chờ ai (các mục đã soạn tin nhắn);
- **phát hiện đã đóng mà người chưa phân xử trong lượt này** (nhóm `[ĐÃ XỬ LÝ]`
  — thường là agent tự sửa ở bước checker của `/design`): liệt kê mã + một dòng
  để người biết, người muốn xem lại mục nào thì xử lý như mục mới;
- D-xx mới hoặc vừa sửa đang chờ người duyệt;
- artifact nào đã lỗi thời vì file đầu vào đổi (`tdd.md`, `plan.md` ghi
  `based_on`): điểm mù trả lời **khớp** giả định → chạy lại phase đó để ghi lại
  dấu đầu vào; **khác** giả định → phase đó phải làm lại phần ghi ở "Nếu giả
  định sai", và task trong `plan.md` đứng trên giả định đó đặt lại `[ ]` khi
  chạy lại `/plan`. `tdd.md` vừa sửa theo phát hiện mà đã có `plan.md` → chạy
  lại `/plan`.

## Cấm

- **Tự quyết** thay người: tự trả lời điểm mù, tự đồng ý hay bác bỏ phát hiện,
  hoặc ghi `đã trả lời` / `đã sửa` / `bác bỏ` khi người chưa nói gì.
- Ghi câu trả lời hay lý do bác bỏ đã diễn giải thay cho nguyên văn lời người.
- Coi phương án agent đề xuất là quyết định khi người chưa chọn.
- Tự hạ `Mức chặn`, hoặc tự đổi mức khi người chưa nói. Đổi `Mức` của phát hiện.
- Đổi `Trạng thái spec` (cả `đề xuất` → `đã duyệt` lẫn ngược lại), hay ghi
  `đã duyệt` cho D-xx — lệnh này không đụng vào các dòng đó.
- Sửa YC / mục `tdd.md` khi người chưa xác nhận các dòng sẽ đổi, hoặc sửa ngoài
  phạm vi của mục đang xử lý.
- Trình bày nhiều mục một lúc rồi bắt người trả lời gộp.
- Dán nguyên danh sách của `aw pending` cho người khi người không yêu cầu.
- Bỏ lựa chọn tự nhập hoặc "Chat về câu này" khỏi câu hỏi.
- Sửa `plan.md` hay code, hoặc chạy lại checker LLM để "làm sạch" phát hiện —
  việc của phase tương ứng; chỉ nói rõ cần chạy lại phase nào.
