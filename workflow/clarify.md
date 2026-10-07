---
id: clarify
choice_ui: true
name: Chốt việc chờ người
summary: Dẫn bạn chốt từng điểm mù và phát hiện của checker đang chặn phase, việc gấp nhất trước
trace_rule: true
---

# Chốt việc chờ người (clarify)

**Không phải phase** — chạy được bất cứ lúc nào sau `/aw-spec`. Gom mọi việc cần người quyết vào một hàng đợi, dẫn người đi từng mục. Agent **dẫn dắt** (phân tích, đặt câu hỏi, ghi lại); **người quyết**.

## Hai nguồn

| Nguồn | File | Người làm gì | Chặn gì |
|---|---|---|---|
| Điểm mù | `open-questions.md` | **Trả lời** (thường phải hỏi PO/BA) | Theo `Blocking` (`rules/truy-vet-nguon.md`) |
| Phát hiện checker LLM | `phat-hien-<checker>.md` (hiện có `phat-hien-thiet-ke.md`) | **Phân xử**: đồng ý (sửa) hoặc bác bỏ + lý do | `Chặn`: checker của phase đó (`thiết kế` → `/aw-plan`); `Cảnh báo`: không |

Hai file giữ riêng (mỗi file một bên ghi, `based_on` băm cả file); chỉ gộp ở chỗ người nhìn. Mức chặn do agent đề xuất, **chỉ người** được đổi.

## 1. Liệt kê — cho agent đọc, KHÔNG dán cho người

`aw pending <thư-mục-feature>` — thứ tự do máy xếp, agent không xếp lại: chưa phân mức → `blocking` → phát hiện `Chặn` → `review-blocking` → phát hiện `Cảnh báo` → `non-blocking` (trong nhóm điểm mù: `must` trước `should`, nhiều task đứng trên giả định hơn trước, rồi theo mã).

Người chỉ thấy **một dòng**:

```
Còn 6 việc chờ bạn: 3 đang chặn (YC-001, YC-002 chặn /aw-design; PH-03 chặn /aw-plan), 3 chưa chặn. Bắt đầu từ YC-001.
```

Người hỏi "cho xem hết" mới in danh sách (mã + tiêu đề + nhóm, mỗi mục một dòng).

| Kết quả `[x]` | Làm gì |
|---|---|
| `KHÔNG CÒN VIỆC CHỜ NGƯỜI` | Báo một dòng (kèm nhóm `[ĐÃ XỬ LÝ]` nếu có — bước 4), dừng |
| `CÓ VIỆC ĐANG CHẶN` | Tóm tắt, sang bước 2 |
| `CÒN VIỆC CHỜ NGƯỜI, CHƯA CHẶN` | Tóm tắt, hỏi lựa chọn "Giải quyết luôn" / "Để sau" |
| `THIẾU ĐẦU VÀO` | Chưa có `spec.md`/`open-questions.md` → chạy `/aw-spec` trước |

## 2. Hỏi từng mục — MỘT mục mỗi lượt, theo thứ tự

### Nghĩ kỹ trước khi hỏi

Lựa chọn là **phương án giải pháp**, không phải thủ tục. Trước mỗi mục:
1. **Đọc đủ:** đoạn nguồn, YC trong `spec.md`, phần `tdd.md`/`plan.md`/code liên quan, `conventions.md`. Phát hiện LLM: đọc đúng chỗ `Vị trí`.
2. **Tách quyết định:** mục gói nhiều quyết định độc lập → mỗi quyết định một câu hỏi, hỏi chung trong lượt đó (tối đa 4).
3. **Tìm 2–3 phương án khác nhau về hệ quả** — từ nguồn, thực hành phổ biến, ràng buộc code hiện có. Không chêm phương án yếu; chỉ một phương án hợp lý thì đưa một.
4. **Chọn đề xuất:** so đánh đổi (an toàn, chi phí làm lại, ảnh hưởng ngoài, đảo ngược được). Phương án đề xuất đứng **đầu**, nhãn bắt đầu bằng `(Đề xuất)`.

Mỗi lựa chọn: **nhãn** ngắn đúng phương án; **mô tả** một dòng hệ quả/đánh đổi (khác giả định tạm thì nói phải làm lại gì; lấy từ nguồn thì ghi nguồn, vd `theo Input 2 § 4`; trùng giả định tạm thì ghi "đang dùng làm giả định tạm").

Ngữ cảnh ngay trước câu hỏi, tối đa 4 dòng: mã · nhóm · đang chặn gì · vị trí trong hàng đợi; nguồn nói gì; vì sao đề xuất.

Người **luôn** có hai lối ra, ở **cuối** danh sách: tự nhập câu trả lời khác, và "Chat về câu này" (trao đổi trước khi chốt):

```
  N.   Type something.  — tự nhập câu trả lời khác
  N+1. Chat about this.  — trao đổi thêm trước khi chốt
```

Giao diện lựa chọn có sẵn hai lối này (vd Claude Code) → **không** thêm trùng. Không có giao diện lựa chọn → agent tự in hai dòng đó, đánh số tiếp.

### 2a. Điểm mù

```
YC-006 · CHẶN REVIEW · 5/9 · 2 quyết định
Nguồn: Input 1 chỉ nói "chỉ client trong allowlist được gọi"; không nói mã lỗi, không nói route chưa khai.
Vì sao đề xuất: 403 tách khỏi 401 nên đối tác biết là thiếu quyền chứ không sai key;
  từ chối mặc định để route mới không lọt ra ngoài khi quên khai.

(1/2) Credential hợp lệ nhưng ngoài allowlist thì trả gì?
  1. (Đề xuất) 403 problem+json, mã lỗi riêng — đang dùng làm giả định tạm
  2. 404 — giấu route khỏi bên dò quét; đối tác khó debug
  3. 403 không body chi tiết — đơn giản; đối tác phải hỏi support
  4. Chưa trả lời được — soạn tin gửi chủ admin-portal; /aw-review sẽ chặn
  5. Type something.  — tự nhập câu trả lời khác
  6. Chat about this.  — trao đổi thêm trước khi chốt

(2/2) Route chưa có definition thì chặn hay cho qua?
  …
```

Thứ tự lựa chọn (tối đa 4): `(Đề xuất) <phương án>` → 1–2 phương án khác (có trong nguồn trước) → **Chưa trả lời được** (agent soạn tin gửi `<Ask>`). Ô tự nhập nhận cả "đổi mức chặn sang …" hay "bỏ qua".

Mục `CHƯA PHÂN MỨC`: câu hỏi đầu là chọn mức (`blocking`/`review-blocking`/`non-blocking`), mức đề xuất theo "Nếu sai" đứng đầu — xong mới hỏi câu trả lời.

### 2b. Phát hiện checker LLM

```
PH-03 · CHẶN · đang chặn /aw-plan · 3/6 · quyết định ngầm
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

Thứ tự (tối đa 4): `(Đề xuất) <cách sửa>` (sửa gì, ở mục nào) → 0–1 cách sửa khác hướng thật → **Bác bỏ** ("nhập lý do ở ô tự nhập") → mục `Cảnh báo`: **Để sau** (khi đó chỉ một cách sửa). Agent thấy phát hiện sai → đưa `(Đề xuất) Bác bỏ — <lý do>` lên đầu; người vẫn phải chọn. Bác bỏ không lý do → hỏi lý do (`aw check` chặn bác bỏ trống).

### Chung

- Hỏi xong thì **dừng chờ người**. Không hỏi mục kế khi mục này chưa xong.
- **Chat về câu này:** trả lời, giải thích hệ quả, trích thêm nguồn — **không ghi file**. Rõ rồi thì hỏi lại đúng câu đó bằng lựa chọn (sửa phương án theo trao đổi). Người nói ra quyết định trong lúc chat → xác nhận lại bằng lựa chọn trước khi ghi.

## 3. Ghi lại

### 3a. Điểm mù

**Người trả lời:**
1. `open-questions.md`: `Answer:` = **nguyên văn** lời người + ai trả lời + ngày (vd `"Hoàn tiền tối đa 30 ngày" — PO, 2026-10-04`); `Status: answered`. Người **chọn** phương án → nguyên văn là nhãn (bỏ `(Đề xuất)`) kèm `(chọn từ phương án agent đề xuất)`. Nhiều câu hỏi → ghi từng câu trả lời.
2. `spec.md`: đổi nhãn nguồn của YC thành `[FILE]` open-questions.md § YC-NNN (hoặc nguồn người chỉ ra). Bỏ dòng `Assumption` của YC.
3. **Trả lời khác giả định tạm:** sửa mô tả / tiêu chí của **chỉ YC đó**. Trước khi ghi, cho người xem các dòng sẽ đổi (trước → sau), hỏi "ghi như vậy được không?" (đồng ý trong hội thoại là đủ). Thêm `(đã xác nhận sửa YC-NNN)` cuối `Answer:`. Khớp giả định → chỉ đổi nhãn.
4. Spec đã tick duyệt mà bước 2–3 làm đổi → **bỏ tick** (được bỏ, không bao giờ tick). Nhắc người tick lại ở tổng kết.
5. `aw check spec <thư-mục-feature>`, dán kết quả thật. Không `[x] ĐẠT` → sửa cho khớp rồi mới sang mục kế.

**Chưa trả lời được:** soạn tin gửi `Ask`, tự đủ ngữ cảnh (đọc không cần mở repo): câu hỏi, tài liệu nói gì, giả định đang dùng, hệ quả nếu sai, phase nào đang chờ. Giữ `open`, sang mục kế.

**Người đổi mức:** ghi đúng mức người nói vào `Blocking:`. Agent chỉ được **đề xuất nâng**, không tự hạ.

### 3b. Phát hiện checker LLM

**Đồng ý:**
1. Cho người xem các dòng sẽ đổi trong `tdd.md` (trước → sau), hỏi "ghi như vậy được không?". Chỉ sửa đúng chỗ phát hiện chỉ ra.
2. Cần quyết định (`quyết định ngầm`, `lệch D-xx` mà người muốn đổi D) → thêm/sửa D-xx, ô duyệt **chưa tick** (sửa D đã duyệt: theo "Mở lại một D-xx" của `/aw-design`).
3. `yêu cầu mới` → **bỏ hành vi đó khỏi `tdd.md`**. Người muốn giữ → đó là yêu cầu mới: quay lại `/aw-spec`, không tự thêm YC.
4. File phát hiện: `Xử lý: đã sửa`.
5. `aw check design <thư-mục-feature>`, dán kết quả thật.

**Bác bỏ:** `Xử lý: bác bỏ: <lý do nguyên văn> — <ai>, <ngày>`. Không sửa `tdd.md`.

**Để sau** (chỉ `Cảnh báo`): giữ `chưa`, sang mục kế.

## 4. Tổng kết

Chạy lại `aw pending` (đọc, không dán), rồi nói ngắn:
- còn gì đang chặn phase nào; câu hỏi nào đang chờ ai (tin đã soạn);
- phát hiện đã đóng mà người chưa phân xử trong lượt này (nhóm `[ĐÃ XỬ LÝ]`, thường do agent tự sửa ở `/aw-design`): mã + một dòng;
- D-xx mới/vừa sửa chờ duyệt; spec vừa bị bỏ tick → người tick lại;
- artifact lỗi thời vì đầu vào đổi (`tdd.md`, `plan.md`): trả lời **khớp** giả định → chạy lại phase đó để ghi dấu; **khác** → phase đó làm lại phần "Nếu giả định sai", task đứng trên giả định đặt lại `[ ]` khi chạy lại `/aw-plan`. `tdd.md` vừa sửa mà đã có `plan.md` → chạy lại `/aw-plan`.

## Cấm

- **Tự quyết** thay người: tự trả lời, tự đồng ý/bác bỏ, ghi `answered`/`đã sửa`/`bác bỏ` khi người chưa nói.
- Ghi câu trả lời / lý do đã diễn giải thay vì nguyên văn.
- Coi phương án đề xuất là quyết định khi người chưa chọn.
- Hỏi khi chưa phân tích: chỉ đưa "giữ giả định / chưa trả lời được" khi có phương án thật; chêm phương án yếu; gộp quyết định độc lập vào một câu.
- `(Đề xuất)` ở chỗ khác ngoài đầu nhãn, hoặc trên nhiều hơn một lựa chọn.
- Tự hạ/đổi `Blocking` khi người chưa nói; đổi `Mức` của phát hiện.
- Tick ô duyệt, sửa/xoá `<!-- approval-hash: … -->` (chỉ được **bỏ** tick spec ở 3a bước 4).
- Sửa YC / `tdd.md` khi người chưa xác nhận các dòng sẽ đổi, hoặc ngoài phạm vi mục đang xử lý.
- Trình bày nhiều mục một lúc; dán nguyên danh sách `aw pending` khi người không yêu cầu.
- Làm mất lối tự nhập hoặc "Chat về câu này".
- Sửa `plan.md` hay code, chạy lại checker LLM để "làm sạch" phát hiện — chỉ nói cần chạy lại phase nào.
