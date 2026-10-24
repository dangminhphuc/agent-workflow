# Spec: SP25 — Open question có mã riêng (`Q-NNN`)

- Ngày: 2026-10-23 · Branch: `claude/compassionate-volta-3q04nv`
- Roadmap § SP25 · Đổi quyết định "open question mang mã REQ" ở `docs/kien-truc.md` § Giả định chưa xác nhận.
- Interface: `CAP-require-02` (giữ nguyên câu chữ — mỗi open question vẫn có giả định và mức chặn); chỉ
  đổi hình dạng artifact `open-questions`. Không bỏ, không nới capability hay invariant nào.
- Trạng thái: **đã chốt 4 điểm thiết kế** (§ 7, người chọn theo đề xuất 2026-10-24); implement cùng PR,
  không viết plan (người chọn).

## 1. Vấn đề

`open-questions.md` đang lặp lại `spec.md`. Gốc của việc lặp: mỗi open question là **bản sao 1:1 của
một REQ** — cùng mã `REQ-NNN`, cùng tiêu đề (template: "tiêu đề trùng với mục trong spec.md") — và
file gánh ba vai cùng lúc:

1. **Câu hỏi chưa chốt** — giả định tạm, mức chặn, hỏi ai.
2. **Nơi lưu lời người làm nguồn** — `Quote:` `[FILE]` của REQ trỏ vào `Answer:`.
3. **Nhật ký đổi REQ** — `/aw-clarify REQ-NNN` tạo mục cho REQ đã có nguồn.

Chỗ lặp cụ thể:

| # | Chỗ lặp | Ghi chú |
|---|---|---|
| 1 | Tiêu đề mục = tiêu đề REQ | Mỗi REQ chưa chốt một mục, file trông như spec lần hai |
| 2 | `Assumption:` ở cả REQ trong spec và mục open question | Máy chỉ kiểm bản ở `open-questions.md`; hai bản lệch không ai báo |
| 3 | `Answer:` chép sang `Quote:` của REQ | **Cố ý, giữ**: `quote.sh` kiểm câu trích có trong file, như mọi nguồn `[FILE]` |
| 4 | Đổi REQ: `Source says` = `Quote` cũ, `Assumption` = `Description` cũ | Lặp nặng nhất; người sửa nhiều REQ thì file thành bản sao spec |
| 5 | Một câu hỏi đụng nhiều REQ (vd phân quyền, NFR ở bước 5 phase spec) | Phải tách thành nhiều mục cùng câu hỏi, mỗi REQ một mục; trả lời một lần nhưng ghi N lần |

## 2. Mục tiêu

**Thành công khi:** mỗi thông tin nằm ở đúng một chỗ — câu hỏi ở `open-questions.md`, yêu cầu ở
`spec.md`, quan hệ câu hỏi ↔ REQ ở **một** phía; một câu hỏi phủ được nhiều REQ; artifact của việc
đang chạy dở ở repo đích vẫn đọc được, không bị chặn chỉ vì engine đổi phiên bản.

Phương án A (gọn trường, giữ khoá `REQ-NNN` — xem lịch sử thảo luận trong PR) **không làm riêng**:
toàn bộ phần bỏ lặp của A nằm trong thiết kế này (§ 3.2, § 3.4).

## 3. Thiết kế

### 3.1 Mã và mục

- Mục open question: `### Q-NNN — <câu hỏi ngắn>` dưới `## Questions`. `Q-` + đúng 3 chữ số, không
  trùng, đánh số riêng (không theo số REQ). Tiêu đề là **câu hỏi**, không chép tiêu đề REQ.
- Trường của mục (tên tiếng Anh, như hiện tại):

  | Trường | Bắt buộc khi | Ghi chú |
  |---|---|---|
  | `Source says` | mục có REQ `[OPEN-QUESTION]` | Câu nguồn mơ hồ, hoặc "không đề cập". Spec không có `Quote` cho REQ này nên không lặp |
  | `Question` | luôn | Trả lời được bằng một câu |
  | `Ask` | `open` | BA / PO / tên người |
  | `Assumption` | mục có REQ `[OPEN-QUESTION]` | **Chỉ ở đây** — bỏ khỏi REQ trong spec |
  | `If wrong, redo` | mục có REQ `[OPEN-QUESTION]` | |
  | `Blocking` | mục có REQ `[OPEN-QUESTION]` | Một mức cho cả câu hỏi |
  | `Status` | luôn | `open` \| `answered` |
  | `Answer` | `answered` | Nguyên văn + ai + ngày |
  | `Superseded answer` | khi có câu trả lời cũ | |

- **Không có trường `Affects`.** Quan hệ câu hỏi → REQ chỉ khai ở phía spec (link trong `Source:` của
  REQ); máy suy ngược ra danh sách REQ của mỗi `Q-NNN`. Ghi cả hai phía là tái tạo đúng lỗi đang sửa.
  `aw pending` và cổng duyệt spec in danh sách REQ suy được, nên người không phải tự tra.

### 3.2 Phía spec

- REQ chưa chốt: `- Source: \`[OPEN-QUESTION]\` → [open-questions.md § Q-001](open-questions.md#q-001)`.
  **Không còn dòng `Assumption:`** dưới REQ (template, phase spec, `clarify.md` § 3a bước 2 "Remove
  that REQ's Assumption line" bỏ theo).
- Mỗi REQ vẫn đúng **một** `Source:` (luật cũ, `rules/source-tracing.md`), nên đứng trên tối đa một
  `Q-NNN`; một `Q-NNN` phủ được nhiều REQ (§ 7, điểm 2). Phase spec, bước 7, thêm: "Two independent
  unknowns (different `Ask` or `Blocking`) → split the REQ; never merge them into one question." Máy
  không kiểm "độc lập" (không đo được); LLM checker spec kiểm nếu sau này thấy lỗi này thật.
- Đã trả lời: nhãn `[FILE]` [open-questions.md § Q-001](open-questions.md#q-001), `Quote:` = lời trong
  `Answer:` (giữ chỗ lặp số 3 — có lý do). Nhiều REQ cùng trích một câu trả lời là hợp lệ.
- `## Source conflicts`, cột `Resolution`: trỏ `[open-questions.md § Q-NNN](open-questions.md#q-nnn)`.

### 3.3 Đối chiếu hai chiều (`aw check spec`, chặn)

Thay các luật hiện có theo mã REQ bằng luật theo mã Q (cùng mức chặn, cùng thông báo kiểu cũ):

- REQ `[OPEN-QUESTION]` trỏ tới `Q-NNN` không có mục → chặn. Không có link `Q-NNN` nào → chặn.
- Mục `Q-NNN` không REQ nào trỏ tới (qua `[OPEN-QUESTION]` hay `[FILE] … § Q-NNN`) → chặn (mồ côi, như
  "open-questions.md có mục … nhưng spec.md không có" hiện nay).
- Mục có REQ `[OPEN-QUESTION]` mà thiếu `Assumption` / `Blocking`, hay `Blocking` sai giá trị → chặn
  (luật cũ, đổi khoá).
- `answered` mà còn REQ trỏ tới nó bằng `[OPEN-QUESTION]` → chặn; `open` mà có REQ trỏ bằng
  `[FILE] … § Q-NNN` → chặn (bản theo Q của hai luật đối chiếu cũ).
- `Q-` sai dạng hay trùng → chặn.
- Luật đã có `# giữ:` giữ nguyên tag khi đổi khoá; luật thêm mới gắn `# giữ: CAP-require-02`. Số đếm
  của `tools/check-spec.sh` trong `tools/unclassified-rules.txt` không được tăng.

### 3.4 Đổi một REQ đã có nguồn (`/aw-clarify REQ-NNN`)

Ghi thành một `Q-NNN` mới, `Status: answered` ngay khi tạo, **chỉ** `Question` (cách hiểu đang tranh
chấp, viết dạng "REQ-NNN nên hiểu là X hay Y?" để người đọc phân biệt với câu hỏi thường — quy ước
chữ, máy không kiểm), `Answer` (+ `(đã xác nhận sửa REQ-NNN)`), `Superseded answer` nếu có. Không
thêm trường `Kind`: chưa luật nào cần phân biệt hai loại. Mục này không bao giờ `open` nên không vào
hàng đợi `aw pending` và không được đếm là "còn mở" ở cổng duyệt. Không chép `Source says`,
`Assumption`: cách hiểu cũ nằm ở `Quote`/`Description` cũ trong lịch sử git và ở preview của batch.
REQ đổi nhãn sang `[FILE] … § Q-NNN` như hiện tại. Không tạo file nhật ký riêng: thêm file là thêm
artifact, template, mục lục, chuỗi `based_on` — không đổi lại gì so với một mục `answered`.

### 3.5 Phase sau

| Chỗ | Hiện tại | Sau |
|---|---|---|
| Cổng mức chặn (`kc_diem_mu`, `kc_diem_mu_mo`) — design/plan chặn `blocking`, implement cảnh báo, review chặn | theo `### REQ-NNN` | theo `### Q-NNN`; thông báo in mã Q + các REQ suy được |
| `plan.md` `On assumption` | `yes — [open-questions.md § REQ-NNN](…)` | `yes — [open-questions.md § Q-NNN](…)` |
| `aw task reopen <dir> <mã>` (`tk_phu`) | REQ: `Covers` \| `On assumption`; DEC: `Based on` | thêm `Q-NNN`: task có `On assumption` nhắc mã đó; REQ: `Covers` |
| `/aw-clarify` sau khi trả lời khác giả định | reopen REQ | reopen `Q-NNN` (task đứng trên giả định) + từng REQ đổi mô tả/tiêu chí (task `Covers`) |
| `aw pending` | mỗi mục một REQ, thứ tự `must` trước, nhiều task hơn trước | mỗi mục một Q; `must` nếu **một** REQ suy được là `must`; số task theo `On assumption` của Q |
| Cổng duyệt spec (`aw approval`) | đếm open question theo REQ | đếm theo Q, in kèm REQ |
| `aw rule promote` (`tools/lib/rule.sh`) | lấy `Answer` ở mục có mã REQ | lấy `Answer` ở mục `Q-NNN` mà nhãn REQ trỏ tới |
| Review | REQ `[OPEN-QUESTION]` không được `pass` | không đổi (theo nhãn của REQ) |
| `merge-request.md` § Open Questions | chép từ `open-questions.md` | không đổi |

### 3.6 Chuyển tiếp cho repo đích

Repo đích đang chạy dở có `### REQ-NNN` trong `open-questions.md` và nhãn `§ REQ-NNN` trong spec/plan.

- **Đọc dạng cũ** (`AGENTS.md` § Language: đổi tên thứ người thấy thì giữ tên cũ đọc được): mục
  `### REQ-NNN` là câu hỏi có mã `REQ-NNN`. Gần như miễn phí nhờ quan hệ suy từ phía spec (§ 3.1):
  link cũ `§ REQ-NNN` trong `Source:` của REQ chính là "REQ trỏ tới câu hỏi đó", nên mọi luật ở § 3.3
  áp dụng y nguyên, không nhánh riêng. Code chỉ cần nhận mã `(Q|REQ)-[0-9][0-9][0-9]` và kiểm không
  trùng trong file. Không chặn.
- **Cảnh báo** ở `aw check spec`: "dạng cũ — việc mới dùng `### Q-NNN`" (một dòng, không mỗi mục một
  dòng).
- **Giữ dạng cũ đọc được vô thời hạn**: một việc có thể dở dang vài tháng, giá giữ là một mẫu regex.
- **Không có lệnh chuyển đổi** (§ 7, điểm 3).
- Việc mới (`/aw-spec` chạy với engine mới) viết `Q-NNN`. Trong cùng một file được phép trộn: chỉ
  cần mã không trùng.

## 4. Test

Thêm ca vào đúng phần cùng chủ đề (`AGENTS.md` § Verify), mỗi luật chặn cả hai chiều:

- `02-spec.sh`: `Q-001` phủ hai REQ → đạt; REQ trỏ `Q-009` không có → chặn; `Q-002` mồ côi → chặn;
  `Q-` sai dạng / trùng → chặn; mục có REQ `[OPEN-QUESTION]` thiếu `Assumption` → chặn; REQ không có
  dòng `Assumption` → đạt; `answered` còn REQ `[OPEN-QUESTION]` → chặn; `open` có REQ `[FILE] § Q` →
  chặn; đổi REQ ghi `Q-` answered chỉ có `Question` + `Answer` → đạt; dạng cũ `### REQ-NNN` → đạt +
  cảnh báo; trộn hai dạng → đạt; `Source conflicts` trỏ `§ Q-NNN` không có → chặn.
- `02-design-plan.sh`: `Q-` `blocking` còn mở chặn design và plan (khi bỏ design); thông báo có REQ.
- `03-implement-security.sh` / `04-review-trace-security.sh`: `review-blocking` theo Q — implement
  cảnh báo, review chặn.
- `07-uses-pending-based-on.sh`: `aw pending` in một mục cho câu hỏi phủ hai REQ, thứ tự `must`, đếm task.
- `15-conventions-task.sh`: `aw task reopen <dir> Q-001` chỉ đưa task `On assumption` nhắc Q-001 về `[ ]`.
- `17-rule-crosscheck.sh`: promote REQ có nguồn `[FILE] § Q-NNN` lấy đúng `Answer`.
- `01-fixture-engine-toc.sh`: anchor `#q-001` mở rộng đúng.
- Fixture chung (`tools/tests/lib.sh`) chuyển sang `Q-001`; giữ một fixture dạng cũ cho ca chuyển tiếp.
- `sh tools/run-tests.sh` → `MỌI CA ĐẠT`; `sh tools/check-sdlc.sh` đạt.

## 5. File đụng tới

- Template: `workflow/templates/{open-questions,spec,plan}.md`.
- Hướng dẫn agent: `workflow/phases/{01-spec,02-design,03-plan,05-review}.md`, `workflow/clarify.md`,
  `workflow/import.md`, `workflow/rules/source-tracing.md`, `workflow/rules/terms.md`,
  `workflow/checkers/{spec,design}.md` (nếu nhắc mã).
- Máy: `tools/check-spec.sh`, `tools/lib/cross-check.sh` (`kc_diem_mu*`), `tools/pending.sh`,
  `tools/approval.sh`, `tools/lib/task.sh` (`tk_phu`), `tools/task.sh` (nhận mã `Q-`),
  `tools/lib/rule.sh`, có thể `tools/unclassified-rules.txt`.
- Tài liệu người: `docs/kien-truc.md` § Giả định chưa xác nhận (quyết định mới + lý do "quan hệ ở
  một phía"), `docs/huong-dan.md` (clarify, đổi REQ), `docs/thuat-ngu.md` (`Q-NNN`), README nếu có ví
  dụ; `changes/<branch>.md` mục `Thay đổi` (người dùng `aw` thấy: dạng mới của `open-questions.md`,
  việc cũ vẫn đọc được).
- Roadmap: SP25 → `xong` sau khi merge.

## 6. Ngoài phạm vi

- Không đổi ba mức `Blocking`, thứ tự hàng đợi `aw pending` (ngoài việc gom theo Q), luồng hỏi của
  `/aw-clarify`.
- Không đổi file phát hiện LLM (`*-findings.md`).
- Không thêm source label; không cho một REQ nhiều `Source:`.
- Không có lệnh chuyển đổi artifact cũ (§ 3.6) ở bản này.

## 7. Đã quyết (2026-10-24, người chọn theo đề xuất)

1. **Quan hệ Q ↔ REQ chỉ khai ở phía spec, máy suy ngược; không có `Affects`.**
   - Loại "ghi cả hai phía" (`Affects:` + link): cả hai phía do cùng agent viết cùng lượt, luật đối
     chiếu chủ yếu bắt lỗi quên sửa một phía — lỗi do chính việc ghi hai lần sinh ra (như `Assumption`).
   - Loại "chỉ `Affects:`": REQ mất link tới giả định của nó, trái luật tham chiếu có anchor.
   - Giá phải trả: chỗ cần danh sách REQ của một Q đọc thêm `spec.md` (`pending.sh` vốn đã đọc;
     `kc_diem_mu` in kèm REQ là tuỳ chọn).
2. **Một REQ đứng trên tối đa một Q; một Q phủ được nhiều REQ.**
   - Loại "REQ nhiều Q": REQ rơi vào trạng thái lửng (một Q đã trả lời, một chưa), phải viết lại luật
     "đúng một `Source:`", review `pending`, `aw rule promote`, đếm nhãn ở cổng duyệt, mức chặn của REQ.
   - REQ hai ẩn số độc lập thường là REQ chưa đủ nhỏ → tách (dòng hướng dẫn ở § 3.2).
3. **Chuyển tiếp: đọc dạng cũ vô thời hạn + một dòng cảnh báo; không lệnh chuyển đổi.**
   - Loại `aw migrate`: sửa spec làm approval hash mất hiệu lực (người duyệt lại vì engine đổi định
     dạng), `tdd.md`/`plan.md` stale; tự tính lại hash là máy sửa nội dung người đã duyệt rồi coi như
     vẫn duyệt — trái `CAP-require-03`.
   - Loại "chặn dạng cũ": phá việc đang chạy.
4. **Đổi REQ là một `Q-` answered tối giản; không file nhật ký riêng, không trường `Kind`.**
   - Loại `req-changes.md`: thêm template, `TOC_ART`, parse ở `check-spec.sh`, danh sách nguồn lời
     người (`rule.sh`, `check-spec.sh`), chuỗi `based_on` của `tdd.md`, `outputs` phase spec — không
     chỗ nào bắt thêm lỗi.
   - Phân biệt với câu hỏi thường bằng quy ước viết `Question:` (§ 3.4).
