---
id: spec
name: Đặc tả
summary: Chưng cất BRD/PRD/ticket thành đặc tả kiểm chứng được và soi ra điểm mù
required: true
inputs:
  - intake.md
  - confluence
  - jira
  - file
outputs:
  - spec.md
  - open-questions.md
exit_machine:
  - aw check spec
exit_human:
  - Chủ repo duyệt danh sách yêu cầu và phần "Ngoài phạm vi"
  - Chủ repo duyệt nhãn "Mức chặn" của từng [CẦN-HỎI] (chặn | chặn review | không chặn)
  - Chủ repo duyệt "Mức rủi ro" (cao → design chạy Mode 2, người phác D-xx trước)
  - Duyệt xong, chủ repo tự tick ô "Người duyệt spec" — design (chore thì plan) chặn tới lúc đó
needs_clean_context: true
---

# Phase 01 — Đặc tả

## Mục tiêu

Chưng cất yêu cầu nghiệp vụ thành đặc tả kỹ thuật **kiểm chứng được**, và soi ra
những chỗ tài liệu thượng nguồn nói chưa rõ hoặc tự mâu thuẫn.

Phase này **không sinh ra yêu cầu mới**. Nó dịch và làm sắc yêu cầu đã có. Mọi
thứ không truy về được nguồn đều phải lộ ra chứ không được trộn lẫn vào.

## Đầu vào

- Quy tắc riêng của repo cho phase này — `aw rules spec`, đọc từng file nó in ra
  (xem `rules/nguyen-tac-chung.md` § 7)

`intake.md` — phải qua `aw check intake` (checker của spec chạy lại nó).
Nó cho biết **loại việc** và **danh sách input**. Đọc hết từng input:

| Input trong `intake.md` | Cách lấy | Nhãn nguồn trong spec |
|---|---|---|
| `[CONFLUENCE]` | MCP Atlassian, đọc page | `[CONFLUENCE]` URL page + tên heading |
| `[JIRA]` | MCP Atlassian, đọc issue | `[JIRA]` mã issue + URL |
| `[FILE]` (kể cả incident note) | Đọc trực tiếp | `[FILE]` đường dẫn + heading |
| `[NGƯỜI-DÙNG]` | Đọc nguyên văn trong `intake.md` | `[FILE] intake.md § Input` |

Chưa có `intake.md`: dừng lại và chạy `/intake` trước. Không đọc nguồn nào nằm
ngoài danh sách input — muốn thêm nguồn thì thêm vào `intake.md` trước.

## Theo loại việc

| Loại | Spec phải có thêm |
|---|---|
| `feature` | — |
| `bugfix` | Mục `## Tái hiện lỗi`: `Cách tái hiện:`, `Hành vi sai:`, `Hành vi đúng:` |
| `refactor` | Mỗi YC có `Loại YC: giữ nguyên \| cấu trúc` — **không có YC hành vi mới**. YC giữ nguyên có `Được bảo vệ bởi: \`<file test>\`` và file đó phải **có sẵn trên nhánh gốc** |
| `perf` | Như refactor, thêm `Loại YC: hiệu năng` (ít nhất một) với `Mục tiêu:` có số liệu |
| `chore` | — |

Refactor mà vùng sắp đụng tới chưa có test bảo vệ: checker chặn. Viết test cho
vùng đó thành một việc riêng trước, hoặc thu hẹp phạm vi — refactor một vùng
không có test rồi tưởng là an toàn là rủi ro lớn nhất của refactor.

## Việc phải làm

1. **Thu thập nguồn.** Đọc hết tài liệu được trỏ tới. Ghi lại định danh chính
   xác của từng nguồn — sẽ dùng làm nhãn truy vết — và **phiên bản** đã đọc
   (Confluence: số version của page; Jira: thời điểm `updated`; `[FILE]`: sha
   commit). Ngày đọc không cho biết nguồn đã đổi sau đó chưa; phiên bản thì có.
   Không đọc lướt rồi tóm tắt.

2. **Trích yêu cầu thô.** Trích *nguyên văn* các câu mang yêu cầu, chưa diễn
   giải. Bước này tách riêng để phân biệt rõ "tài liệu nói gì" với "ta hiểu thế
   nào" — hai thứ này trộn vào nhau là gốc của phần lớn sai lệch về sau.

3. **Chuyển thành yêu cầu kiểm chứng được.** Mỗi yêu cầu nhận mã `YC-NNN` và
   phải có ít nhất một tiêu chí chấp nhận `- [ ] …` **quan sát được từ bên
   ngoài**. "Hệ thống phải nhanh" không đạt; "trả kết quả tìm kiếm dưới 300ms
   với 10k bản ghi" thì đạt.

   Mỗi YC có `Ưu tiên: bắt buộc | nên có`. `nên có` **chỉ khi nguồn nói vậy**
   (BRD ghi "nice to have", ticket ghi "phase 2 nếu kịp"…); nguồn im lặng thì
   `bắt buộc`. `03-plan` cảnh báo khi hoãn một YC `bắt buộc`.

4. **Rà yêu cầu phi chức năng.** BRD hiếm khi viết NFR, nên agent hay bỏ sót.
   Với mỗi nhóm dưới đây, hỏi: việc này có đụng tới không, và nguồn nói gì?

   | Nhóm | Câu hỏi gợi ý |
   |---|---|
   | Phân quyền | Ai được xem / sửa / duyệt? Vai trò nào bị chặn? |
   | Audit / lịch sử | Thay đổi có phải lưu vết ai, lúc nào, giá trị cũ? |
   | Hiệu năng / khối lượng | Bao nhiêu bản ghi, bao nhiêu người dùng đồng thời? |
   | Dữ liệu nhạy cảm | Có dữ liệu cá nhân, tài chính? Che, mã hoá, thời hạn lưu? |
   | Tương thích ngược | API / file / báo cáo nào bên ngoài đang dùng thứ sắp đổi? |
   | Lỗi & khôi phục | Hệ thống ngoài lỗi thì sao? Có cần thử lại, đảo ngược? |

   Nguồn có nói → thành YC như mọi YC khác. Việc **có đụng** tới nhóm đó mà
   nguồn im lặng → `[CẦN-HỎI]` (thường `chặn review`). Không đụng → bỏ qua, không
   ghi gì. Không bịa con số NFR: số liệu phải từ nguồn hoặc từ câu trả lời.

5. **Bối cảnh và thuật ngữ.** Ghi vai trò người dùng liên quan theo nguồn. Domain
   có từ dễ hiểu lệch ("kỳ", "hạch toán", "khách hàng" vs "người dùng") thì thêm
   mục `## Thuật ngữ` (tuỳ chọn) — mỗi thuật ngữ kèm nguồn định nghĩa nó.

6. **Gắn nhãn nguồn** cho từng yêu cầu theo `rules/truy-vet-nguon.md`.

7. **Tách điểm mù.** Chỗ nào tài liệu không nói rõ: gắn `[CẦN-HỎI]`, ghi vào
   `open-questions.md` kèm:
   - **giả định tạm** đang dùng để đi tiếp;
   - *điều gì sẽ phải làm lại nếu giả định sai*;
   - **Mức chặn** do bạn đề xuất — đúng một trong ba, chọn theo "nếu sai thì
     phải làm lại gì". Người duyệt nhãn này.

     | Mức | Khi nào | Chặn gì |
     |---|---|---|
     | `chặn` | Sai thì cả thiết kế đổi hướng | `02-design` (chore: `03-plan`) và mọi phase sau, tới khi `đã trả lời` |
     | `chặn review` | Sai thì làm lại một phần code | Flow đi tiếp trên giả định tạm; `04-implement` cảnh báo, `05-review` chặn |
     | `không chặn` | Sai thì sửa nhỏ, chấp nhận giao trước | Không chặn; review ghi YC đó `chờ xác nhận` |

   Ưu tiên flow đi tiếp: chỉ mục `chặn` dừng flow ngay. Lệnh `clarify`
   liệt kê các mục còn mở theo thứ tự phải chốt trước và dẫn người trả lời.

8. **Rà mâu thuẫn.** Đối chiếu các nguồn với nhau. Mâu thuẫn giữa BRD và ticket
   là chuyện thường; phát hiện ở đây rẻ hơn phát hiện lúc đang code rất nhiều.
   Cột "Xử lý" **chỉ** được trỏ tới một điểm mù (`open-questions.md § YC-NNN`)
   hoặc một nguồn đã chốt (`[JIRA]` comment của PO, `[CONFLUENCE]` page mới
   hơn…). Chọn bên nào "hợp lý hơn" là quyết định nghiệp vụ — không phải việc
   của agent. Không có mâu thuẫn thì ghi "Không phát hiện mâu thuẫn."

9. **Xác định "Ngoài phạm vi".** Liệt kê thẳng những thứ *không* làm lần này.
   Mục này tồn tại để chặn các phase sau làm quá tay — không có nó, agent sẽ coi
   mọi thứ liền kề là "hợp lý nên làm luôn". Thật sự không có thì ghi "Không có."

10. **Ghi "Ràng buộc & phụ thuộc".** Điều kiện bên ngoài việc này phải chịu: hệ
    thống ngoài, quy định pháp lý–kế toán, deadline, việc của team khác — mỗi
    mục kèm nguồn. Đây là đầu vào của `Mức rủi ro` (bước sau) và của D-xx ở
    `02-design`. Không có thì ghi "Không có ràng buộc hay phụ thuộc ngoài."

11. **Đề xuất `Mức rủi ro`**: `cao` khi đụng tiền/hạch toán, tích hợp mới, schema
    lõi, hoặc thay đổi khó đảo ngược (xem cả "Ràng buộc & phụ thuộc"); còn lại
    `thường`. Ghi lý do một dòng. Nhãn này quyết định `02-design` chạy Mode 1 hay Mode 2.

12. **Để ô `- [ ] **Người duyệt spec**` chưa tick.** Mỗi lần sửa nội dung spec
    (kể cả chạy lại phase, kể cả `clarify`) đều **bỏ tick** — bản người đã duyệt
    không còn là bản này. Khi người tick, máy ghi dấu duyệt (hash nội dung) cạnh
    tick; nội dung đổi sau đó mà tick còn thì `aw check` chặn, và hook `aw guard`
    (nếu repo cài) tự bỏ tick. Không bao giờ sửa hay xoá `<!-- dấu duyệt: … -->`.

13. **Ghi dấu đầu vào:** `aw based-on <thư-mục-feature> spec.md intake.md`.
    `intake.md` đổi sau đó (`/intake` chạy lại gộp thêm input, đổi loại việc) thì
    spec thành lỗi thời — cảnh báo ở các phase sau, `review` chặn; phải chạy lại
    phase này để đọc input mới.

Khi một điểm mù được trả lời: ghi `Trả lời:`, đổi `Trạng thái` sang `đã trả lời`,
**và** đổi nhãn nguồn của YC trong spec (vd `[FILE]` open-questions.md § YC-002).
Checker chặn nếu hai file lệch nhau.

## Đầu ra

- `spec.md` — theo `templates/spec.md`
- `open-questions.md` — theo `templates/open-questions.md`.
  Phải tồn tại kể cả khi rỗng, và khi rỗng phải ghi rõ "Không có điểm mù".
  File rỗng và file thiếu là hai chuyện khác nhau: một cái nghĩa là đã rà và
  không thấy gì, cái kia nghĩa là chưa rà.

## Cấm

- Bịa yêu cầu không truy được về nguồn.
- **Chọn giải pháp kỹ thuật** (chọn thư viện, thiết kế bảng, chia module) —
  việc của `02-design`.
- Tự chọn một cách hiểu cho chỗ mơ hồ rồi đi tiếp mà không ghi `[CẦN-HỎI]`.
- Gắn `[SUY-RA]` cho một quyết định nghiệp vụ để né việc phải hỏi.
- Hạ `Mức rủi ro` hoặc `Mức chặn` xuống để khỏi bị chặn.
- Ghi `Ưu tiên: nên có` khi nguồn không nói vậy — để plan hoãn được cho nhẹ việc.
- Tự phân xử mâu thuẫn giữa các nguồn ("chọn bên an toàn hơn").
- **Tick ô "Người duyệt spec"**, hay sửa/xoá dấu duyệt cạnh nó. Chỉ người làm việc này.
- Viết code, kể cả code minh hoạ.

## Điều kiện ra

**Máy:**
- `aw check spec` ra `[x] ĐẠT` — mọi YC có đúng một nhãn nguồn hợp
  lệ, `Ưu tiên` hợp lệ và ít nhất một tiêu chí chấp nhận; mọi `[CẦN-HỎI]` có mục
  trong `open-questions.md` với giả định tạm và mức chặn hợp lệ; trạng thái hai
  file khớp nhau; spec có `Mức rủi ro` hợp lệ và đúng một ô duyệt ở phần đầu file,
  tick thì dấu duyệt còn khớp nội dung; có đủ các mục
  "Ràng buộc & phụ thuộc", "Ngoài phạm vi", "Mâu thuẫn giữa các nguồn" với nội
  dung thật; mỗi mâu thuẫn trỏ tới điểm mù hoặc nguồn đã chốt.

**Người:**
- Duyệt yêu cầu và "Ngoài phạm vi" — chỗ hiểu lệch nhau nhiều nhất, máy không
  kiểm thay được.
- Duyệt nhãn `Mức chặn` và `Mức rủi ro` do agent đề xuất.
- Tick ô "Người duyệt spec". `02-design` (chore: `03-plan`) chặn cho tới lúc
  đó — gate người để lại dấu vết trong file, như D-xx. Sửa spec sau khi đã tick
  thì phải duyệt lại: đọc chỗ đổi rồi xoá `<!-- dấu duyệt: … -->` (giữ tick), hoặc
  tick lại nếu tick đã bị bỏ.

Mục `[CẦN-HỎI]` còn mở không được để `05-review` kết luận "đạt" cho YC đó; mục
`chặn` hoặc `chặn review` còn mở thì `05-review` chặn hẳn.
