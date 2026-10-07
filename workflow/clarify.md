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

Trong nhóm điểm mù: YC `must` trước `should` → nhiều task đứng trên giả
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

#### Nghĩ kỹ trước khi hỏi — lựa chọn là phương án giải pháp, không phải thủ tục

Người không phải tự nghĩ ra lời giải từ một câu hỏi trống. Trước mỗi mục, agent
**tự phân tích kỹ** rồi mới đặt lựa chọn:

1. **Đọc đủ:** đoạn nguồn liên quan, YC trong `spec.md`, phần `tdd.md` / `plan.md`
   / code đã có đụng tới mục này, `conventions.md`. Phát hiện LLM: đọc đúng chỗ
   `Vị trí`.
2. **Tách quyết định:** mục gói nhiều quyết định độc lập (vd "trả gì khi ngoài
   allowlist" **và** "route chưa khai thì sao") thì mỗi quyết định là **một câu
   hỏi riêng**, hỏi chung trong lượt của mục đó (tối đa 4 câu).
3. **Tìm phương án thật:** 2–3 phương án **khác nhau về hệ quả** — lấy từ nguồn,
   từ chuẩn/thực hành phổ biến của loại hệ thống đó, từ ràng buộc của code
   hiện có. Không chêm phương án yếu cho đủ số; chỉ có một phương án hợp lý
   thì đưa một.
4. **Đánh giá và chọn đề xuất:** so đánh đổi (an toàn, chi phí làm lại, ảnh hưởng
   bên ngoài, khả năng đảo ngược). Phương án agent đề xuất đứng **đầu**, nhãn
   **bắt đầu bằng `(Đề xuất)`**.

Mỗi lựa chọn:
- **Nhãn:** ngắn, nói đúng phương án. Phương án đề xuất: `(Đề xuất) <phương án>`.
- **Mô tả:** hệ quả/đánh đổi một dòng. Phương án khác giả định tạm thì nói luôn
  phải làm lại gì. Phương án lấy từ nguồn thì ghi nguồn (vd `theo Input 2 § 4`);
  không ghi thì là agent đề xuất.
- Phương án trùng **giả định tạm** đang dùng thì ghi rõ trong mô tả
  ("đang dùng làm giả định tạm") — để người biết chọn nó là không phải làm lại gì.

Ngữ cảnh viết **ngay trước** câu hỏi, tối đa 4 dòng: mã · nhóm · đang chặn gì ·
vị trí trong hàng đợi; nguồn nói gì; **vì sao đề xuất** (1–2 dòng).

Mọi câu hỏi, mọi nguồn, người **luôn** có hai lối ra ngoài các lựa chọn:
- **tự nhập** câu trả lời khác;
- **Chat về câu này** — hỏi lại, trao đổi trước khi chốt.

Hai lối này **luôn hiện ở cuối** danh sách, sau các phương án, đúng hai dòng:

```
  N.   Type something.  — tự nhập câu trả lời khác
  N+1. Chat about this.  — trao đổi thêm trước khi chốt
```

Giao diện lựa chọn có sẵn hai lối này (vd Claude Code) thì chúng tự hiện —
**không** thêm trùng vào danh sách phương án (để đủ chỗ cho phương án thật).
Không có giao diện lựa chọn thì agent tự in hai dòng đó, đánh số tiếp sau các
phương án.

#### 2a. Điểm mù

```
YC-006 · CHẶN REVIEW · 5/9 · 2 quyết định
Nguồn: Input 1 chỉ nói "chỉ client trong allowlist được gọi"; không nói mã lỗi, không nói route chưa khai.
Vì sao đề xuất: 403 tách khỏi 401 nên đối tác biết là thiếu quyền chứ không sai key;
  từ chối mặc định để route mới không lọt ra ngoài khi quên khai.

(1/2) Credential hợp lệ nhưng ngoài allowlist thì trả gì?
  1. (Đề xuất) 403 problem+json, mã lỗi riêng — đang dùng làm giả định tạm
  2. 404 — giấu route khỏi bên dò quét; đối tác khó debug
  3. 403 không body chi tiết — đơn giản; đối tác phải hỏi support
  4. Chưa trả lời được — soạn tin gửi chủ admin-portal; /review sẽ chặn
  5. Type something.  — tự nhập câu trả lời khác
  6. Chat about this.  — trao đổi thêm trước khi chốt

(2/2) Route chưa có definition thì chặn hay cho qua?
  1. (Đề xuất) Từ chối mặc định — đang dùng làm giả định tạm; route mới phải khai mới chạy
  2. Cho qua + log cảnh báo — chuyển đổi êm; hở tới khi khai đủ
  3. Từ chối ở prod, cho qua ở non-prod — hai môi trường hành xử khác nhau
  4. Chưa trả lời được
  5. Type something.  — tự nhập câu trả lời khác
  6. Chat about this.  — trao đổi thêm trước khi chốt
```

Lựa chọn, theo đúng thứ tự này (tối đa 4):

1. **`(Đề xuất) <phương án>`**.
2. Các phương án khác (1–2), phương án có trong nguồn trước.
3. **Chưa trả lời được** — agent soạn tin nhắn gửi `<Hỏi ai>`.

Ô tự nhập nhận cả "đổi mức chặn sang …" hay "bỏ qua".

Mục `CHƯA PHÂN MỨC` (thiếu hoặc sai `Mức chặn`): câu hỏi đầu tiên của mục là
chọn mức (`chặn` / `chặn review` / `không chặn`), mức đề xuất theo "Nếu sai"
đứng đầu với `(Đề xuất)` — checker của spec đang chặn vì nó. Xong mới hỏi câu
trả lời.

#### 2b. Phát hiện của checker LLM

```
PH-03 · CHẶN · đang chặn /plan · 3/6 · quyết định ngầm
tdd.md § Contract API: chọn gRPC cho webhook nội bộ nhưng không nêu thành D-xx.
  Checker nói: khó đảo ngược (contract ngoài); người khác có thể chọn REST.
  Vì sao đề xuất: hai service gọi tới đều đã có client gRPC (src/clients/*); đổi REST là thêm việc.

Xử lý phát hiện PH-03 thế nào?
  1. (Đề xuất) Nêu thành D-xx: giữ gRPC, phương án loại REST — bạn duyệt D sau
  2. Đổi sang REST cho khớp contract hiện có — sửa § Contract + § Flow
  3. Bác bỏ — nhập lý do ở ô tự nhập
  4. Type something.  — tự nhập cách xử lý khác
  5. Chat about this.  — trao đổi thêm trước khi chốt
```

Lựa chọn, theo đúng thứ tự này (tối đa 4):

1. **`(Đề xuất) <cách sửa>`** — mô tả: sửa gì, ở mục nào.
2. Cách sửa khác (0–1) — khác hướng thật, không phải cùng cách viết khác đi.
3. **Bác bỏ** — mô tả: "nhập lý do ở ô tự nhập". Agent thấy phát hiện sai thì
   **đề xuất bác bỏ**: đưa `(Đề xuất) Bác bỏ — <lý do agent thấy>` lên đầu;
   người vẫn phải chọn/nhập lý do. Người chọn bác bỏ mà không kèm lý do thì hỏi
   lý do — bác bỏ không lý do là `aw check` chặn.
4. Mục `Cảnh báo`: **Để sau** (giữ `chưa`, sang mục kế) — khi đó chỉ một cách sửa.

#### Chung cho mọi mục

- Hỏi xong thì **dừng chờ người**. Không hỏi mục kế khi mục này chưa xong.
- **Chat về câu này:** trả lời câu hỏi của người, giải thích hệ quả từng lựa chọn,
  trích thêm nguồn nếu cần — **không ghi gì vào file**. Người nói đã rõ (hoặc
  sau vài lượt trao đổi) thì hỏi lại đúng câu đó bằng lựa chọn — sửa phương án
  theo những gì vừa trao đổi. Trong lúc chat mà người nói ra quyết định thì xác
  nhận lại bằng lựa chọn trước khi ghi.

### 3. Ghi lại theo quyết định

#### 3a. Điểm mù

**Người trả lời** (chọn lựa chọn 1, 2, hoặc tự nhập):

1. Trong `open-questions.md`: `Trả lời:` = **nguyên văn** lời người kèm ai trả
   lời và ngày (vd `"Hoàn tiền tối đa 30 ngày" — PO, 2026-10-04`); `Trạng thái:`
   → `đã trả lời`. Người nói "đã hỏi PO, PO chốt…" thì ghi PO là người trả lời.
   Người **chọn** một phương án thì nguyên văn là nhãn phương án (bỏ `(Đề xuất)`),
   kèm `(chọn từ phương án agent đề xuất)` — vd `"403 problem+json, mã lỗi riêng"
   — chủ repo, 2026-10-06 (chọn từ phương án agent đề xuất)`. Mục tách nhiều câu
   hỏi thì ghi từng câu trả lời, mỗi câu một ý.
2. Trong `spec.md`, đổi nhãn nguồn của YC: `[FILE]` open-questions.md § YC-NNN —
   hoặc nguồn người chỉ ra (`[JIRA]` comment, `[CONFLUENCE]` page mới hơn).
   Bỏ dòng `Assumption` của YC đó.
3. **Câu trả lời khác giả định tạm:** sửa mô tả / tiêu chí chấp nhận của YC đó
   theo câu trả lời — chỉ YC đó. Trước khi ghi, cho người xem đúng các dòng
   sẽ đổi (trước → sau) và hỏi "ghi như vậy được không?"; người đồng ý trong hội
   thoại là đủ. **Giữ nguyên `Status` của spec** — người vừa trả lời và xác nhận
   chính chỗ sửa này, không phải mở file sửa tay `proposed` → `approved` lần nữa.
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
   D): thêm/sửa D-xx với `Status: proposed` (sửa D đã duyệt thì theo mục "Mở
   lại một quyết định" của `/design`). **Không** ghi `approved` — người duyệt D
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
- Hỏi khi chưa phân tích: đưa lựa chọn chỉ có "giữ giả định / chưa trả lời được"
  trong khi có phương án thật; chêm phương án yếu cho đủ số; gộp nhiều quyết
  định độc lập vào một câu hỏi.
- Đặt `(Đề xuất)` ở chỗ khác ngoài đầu nhãn, hoặc cho nhiều hơn một lựa chọn.
- Tự hạ `Mức chặn`, hoặc tự đổi mức khi người chưa nói. Đổi `Mức` của phát hiện.
- Đổi `Status` của spec (cả `proposed` → `approved` lẫn ngược lại), hay ghi
  `approved` cho D-xx — lệnh này không đụng vào các dòng đó.
- Sửa YC / mục `tdd.md` khi người chưa xác nhận các dòng sẽ đổi, hoặc sửa ngoài
  phạm vi của mục đang xử lý.
- Trình bày nhiều mục một lúc rồi bắt người trả lời gộp.
- Dán nguyên danh sách của `aw pending` cho người khi người không yêu cầu.
- Làm mất lối tự nhập hoặc "Chat về câu này" (giao diện không có sẵn thì phải in ra).
- Sửa `plan.md` hay code, hoặc chạy lại checker LLM để "làm sạch" phát hiện —
  việc của phase tương ứng; chỉ nói rõ cần chạy lại phase nào.
