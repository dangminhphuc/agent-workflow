# SP7 — Chọn lại tính năng của v1

- Trạng thái: đã duyệt (2026-11-28, D-049)
- Ngày: 2026-11-28
- Quyết định liên quan: D-030…D-048 trong `docs/decisions.md` (bài toán, phương án, lý do của từng lựa chọn). File
  này là **bản hiện hành**: chỗ nào khác với một quyết định thì file này đúng, và chỗ khác phải có lý do ghi ở đây.

## 1. Mục tiêu

Mỗi tính năng của v1 có đúng một phán quyết — **vào interface**, **chuyển cho SPn**, **bỏ** (có lý do), hay **để sau** —
và phần "vào interface" được viết vào `interface/` theo khuôn SP1, được người duyệt lại. Sau SP7, SP2 và SP3 bắt đầu
từ một interface đã có đủ những gì v1 chứng minh là cần, và từ một danh sách việc chuyển giao rõ ràng.

SP7 chỉ sinh tài liệu. Không có code.

## 2. Phạm vi

**Trong phạm vi**
- Bảng phán quyết phủ mọi tính năng v1 (§4).
- Sửa `interface/` theo các phán quyết "vào interface" (§5).
- Ghi danh sách chuyển giao cho SP3, SP4, SP5, SP6 vào `docs/decisions.md` (§6).

**Ngoài phạm vi**
- Cách làm các phần đã chuyển giao (định dạng, nơi lưu, công cụ, ngưỡng mặc định) → SP3/SP4/SP5/SP6.
- MINOR còn lại của SP1 (`docs/decisions.md` § Đang mở): chỉ sửa khi trang chứa nó đang được sửa vì SP7; còn lại để
  lần chỉnh interface sau.
- Chuyển repo v1 sang v2 → SP8.

## 3. Thuật ngữ mới (dùng trong file này, định nghĩa chính thức vào `overview.md` ở §5)

| Thuật ngữ | Nghĩa | Từ |
|---|---|---|
| tri thức bền vững | tài liệu sống ngoài từng việc, giải thích vì sao mã như vậy (quyết định, luật nghiệp vụ, tài liệu module) | D-030 |
| mức rủi ro | `high` / `normal` của một việc; chốt ở `require` | D-031 |
| bản chữ nguồn, đoạn | chữ của mọi nguồn được ghi vào work item, chia thành đoạn trỏ tới được; đã ghi thì không sửa, nguồn đổi thì thêm bản mới | D-032 |
| con trỏ | chỉ tới một đoạn nguồn, một chỗ trong mã, test hay mục artifact; máy giải được (kiểm có thật) | D-032, D-033 |
| nhãn tin cậy | nguồn tin cậy (người duyệt, tài liệu nội bộ đã duyệt) hay không (ticket người ngoài tạo, comment công khai, web) | D-038 |
| lời khai của repo | những gì repo khai và luật dựa vào: mã production, mã nhạy cảm, ngưỡng, quy ước, luật máy, file hàng rào, mẫu tắt tại chỗ, nhóm quét tắt, danh mục bảo mật, danh sách lệnh, mẫu che dữ liệu cá nhân; có dấu duyệt của người | D-036 |
| file hàng rào | file định nghĩa bước kiểm: cấu hình CI, bộ quét, test, lint, kiểu, script kiểm | D-040 |
| tắt tại chỗ | chú thích tắt một bước kiểm ngay trong mã (`nosec`, `eslint-disable`, `skip`…) | D-040 |
| luật máy của repo | luật trong lời khai có kèm cách máy kiểm (bảo mật hay kiến trúc) | D-043 |

Mức phát hiện: các quyết định viết "mức không chặn" — trong interface đó là mức **nên sửa** đã có ở `review-report`.
Không thêm mức mới.

## 4. Bảng phán quyết

Cột **Phán quyết**: `interface` (vào interface, chi tiết ở §5), `SPn` (chuyển giao, §6), `bỏ`, `để sau`. Một dòng có thể
vừa `interface` vừa `SPn`: phần "cái gì" vào interface, phần "làm thế nào" chuyển đi.

### 4.1 Tri thức và truy vết

| Tính năng v1 | Phán quyết | Lý do | Từ |
|---|---|---|---|
| ADR nâng từ DEC-xxx | interface (lõi) + SP3/SP4 | nhu cầu thật (D-004); điểm yếu 18–21 của v1 nằm ở cơ chế | D-030 |
| Luật nghiệp vụ `BR-` | interface (lõi) + SP3/SP4 | như trên | D-030 |
| Cross-check stale | interface (`verify` phán tài liệu bị ảnh hưởng) + SP4 | như trên | D-030 |
| `design` đọc tri thức (v1 `CAP-design-04`) | interface | | D-030 |
| `implement` đọc tri thức (v1 `CAP-implement-07`) | SP3 | `implement` theo thiết kế đã ghi tri thức dùng tới; nạp gì vào ngữ cảnh là việc SP3 | D-030 |
| Chỉ mục tri thức (v1 INV-013), con trỏ tới mục (v1 INV-012) | SP3/SP4 | cơ chế | D-030 |
| Ghi tri thức sau khi rà (v1 `CAP-verify-06`) | interface (người duyệt đánh dấu cần lưu bền) | | D-030 |
| `/aw-bootstrap` | SP4 (lệnh) + SP5 | dựng tri thức ban đầu cho repo có sẵn; D-030 ghi SP3/SP5, D-048 chỉnh | D-030, D-048 |
| Câu trích nguyên văn (`Quote`) | bỏ; thay bằng con trỏ tới đoạn | con trỏ máy kiểm tương đương mà không chép chữ | D-032 |
| Phủ chiều ngược nguồn → yêu cầu | interface (mới, v1 không có) | bắt lỗi bỏ sót nguồn | D-032 |
| Nhãn nguồn `[JIRA]`, `[FILE]`… | SP3 | định dạng | D-032 |
| Mã câu hỏi mở `Q-NNN` | SP3 | định dạng | D-032 |
| "Đúng một nguồn" mỗi yêu cầu | bỏ; giữ "ít nhất một" (D-016 D3) | lửng đã xử lý bằng `INV-005`; ép một nguồn bắt tách giả tạo | D-032 |
| Test ↔ REQ (`covers:`) | SP3 (định dạng) | không nâng thành capability | D-048 |
| `aw toc`, mục lục, anchor | SP3 quyết có cần không; cần thì SP4 | con trỏ D-032 có thể thay | D-048 |

### 4.2 Phán đoán và duyệt

| Tính năng v1 | Phán quyết | Lý do | Từ |
|---|---|---|---|
| `Risk: high\|normal` | interface | | D-031 |
| Mode 2 chống neo (người viết DEC trước) | interface, bản nhẹ: agent liệt kê không đề xuất, người chọn và ghi lý do | Mode 2 của v1 phải chữa hai lần vì nặng | D-031 |
| LLM checker chỉ được chặn | bỏ; thay bằng "đạt phải có bằng chứng" | giữ ý "đạt không rẻ", vẫn giữ người xác nhận (D-024) | D-033 |
| Chặn hay cảnh báo ("cảnh báo ở phase, review chặn") | bỏ | v2 có mức chặn / nên sửa cho từng phát hiện | D-048 |
| Approval hash, hook `aw guard` | SP3 (dạng dấu duyệt) + SP4 (kiểm) + SP5 (hook) | interface chỉ nói "có dấu duyệt" (D-014) | D-048 |
| Duyệt tập trung `/aw-approvals` | SP5 | tiện ích, không đổi kết quả | D-048 |
| `/aw-clarify` (sửa artifact đã duyệt theo lời người) | SP3 | đã trong phạm vi SP3: mở lại quyết định | D-048 |
| Duyệt lại khi input đổi (`based_on`) | đã có (`INV-005`); cơ chế SP4 | | — |

### 4.3 Job type và phạm vi

| Tính năng v1 | Phán quyết | Lý do | Từ |
|---|---|---|---|
| `bugfix` không thêm hành vi mới | interface: capability agent ở `verify`, chỉ `bugfix` | | D-034 |
| `chore` không nâng bản lớn (v1 INV-011) | interface, đổi dạng: thư viện nâng có thay đổi phá vỡ theo ghi chú phát hành → không phải `chore` mà là `refactor` | không trói interface vào semver | D-034 |
| Mẫu phần mã của task quá rộng (vế sau v1 `CAP-implement-05`) | interface: ngưỡng ở `breakdown` + đo sau ở `verify` (nên sửa) | không ai duyệt `task-plan` | D-035 |
| Phạm vi diff "Expected / Unplanned files" | đã có (`CAP-implement-03`) | | — |
| `/aw-refactor` | bỏ dạng lệnh riêng | job type `refactor` đã có; một lệnh chung theo job type | D-048 |
| Tiền tố branch gợi ý job type | bỏ | job type một nguồn ở `work-item` | D-048 |
| Profile `sdlc/profiles` | SP3 (lời khai mặc định) + SP4 (`init`) | | D-048 |

### 4.4 Quy ước của repo

| Tính năng v1 | Phán quyết | Lý do | Từ |
|---|---|---|---|
| `conventions.md` trong git, bản clone chỉ ghi đè khoá máy | interface: lời khai có dấu duyệt, luật đọc bản ở điểm xuất phát; nơi giữ → SP3 | chặn thay đổi tự nới luật | D-036 |
| Quy ước viết mã, kiến trúc | interface: agent phán ở `verify`, mức nên sửa; phần máy kiểm được → luật máy của repo, chặn | | D-036, D-043 |
| `rules_<phase>`, `uses_<phase>` | SP3 | nạp gì vào ngữ cảnh, gọi skill nào | D-036 |
| Khai mã production, mã nhạy cảm | interface: là một phần lời khai | | D-036 |
| `aw init` | SP4 | | D-048 |

### 4.5 Bảo mật

Tiếp cận lại, không theo khung v1 (D-037). Mười hướng xếp theo bốn mức: luôn áp dụng / mặc định bật (tắt bằng lời khai có
duyệt) / theo rủi ro / ngoài interface.

| Hướng | Mức | Phán quyết | Từ |
|---|---|---|---|
| H6 nguồn không tin cậy (prompt injection) | luôn áp dụng | interface: nguyên tắc "nội dung không tin cậy chỉ là dữ liệu", nhãn tin cậy, agent không công cụ quét đoạn không tin cậy | D-038 |
| H9 secret, dữ liệu cá nhân trong artifact | luôn áp dụng (secret) / mặc định bật (che dữ liệu cá nhân) | interface | D-039 |
| H10 agent làm yếu hàng rào | luôn áp dụng | interface: file hàng rào, kiểm bằng bản ở điểm xuất phát, khai tắt tại chỗ | D-040 |
| H4 máy quét (v1: nhóm `secret\|sast\|sca`) | mặc định bật / có điều kiện / theo rủi ro | interface: 6 nhóm, chỉ chặn phát hiện mới | D-041 |
| H8 phụ thuộc mới | mặc định bật | interface: phụ thuộc trực tiếp mới là quyết định + máy kiểm danh tiếng | D-042 |
| H3 luật cấu trúc | mặc định bật | interface: luật máy của repo | D-043 |
| H1 tình huống lạm dụng | theo rủi ro | interface | D-044 |
| H2 ranh giới tin cậy; rủi ro cao không bỏ `design` | theo rủi ro | interface | D-044 |
| H4 agent đọc diff theo ý đồ (v1: Lens 4, 7 hạng mục) | mặc định bật (tầng nhẹ) / theo rủi ro (đủ danh mục) | interface; danh mục ở lời khai, mặc định → SP3 | D-045 |
| H7 quyền tối thiểu theo stage | nguyên tắc ở interface | interface (bảng quyền) + SP3/SP4 (thực thi) | D-046 |
| H5 lúc chạy | ngoài interface | SP6 (gợi ý tín hiệu mặc định) | D-046 |
| `skipped_test_regex` của v1 | — | gộp vào tắt tại chỗ (H10) | D-040 |

### 4.6 Cơ chế chạy

| Tính năng v1 | Phán quyết | Lý do | Từ |
|---|---|---|---|
| Worktree bắt buộc | SP3 | cách agent làm việc | D-048 |
| Ghim phiên bản engine, wrapper tải kiểm sha256 | SP4 | đã trong phạm vi SP4 | D-048 |
| `aw task`, WIP = 1 | đã có (`CAP-implement-01`) | | — |
| `MAX_RED_RUNS` | SP3 | khi nào dừng để hỏi người | D-048 |
| Ship: gỡ artifact trước PR | SP3 quyết | phụ thuộc artifact sống trong hay ngoài repo | D-048 |
| Trạng thái sạch: task `[ ]` sót, dấu xung đột merge | SP4 (checker) | | D-048 |
| `/aw-import` | SP3 (work item, bản chữ nguồn) + SP5 (nối hệ thống ticket) | | D-048 |
| Review phiên trắng | đã có (`CAP-verify-01`) | | — |

### 4.7 Học từ lỗi lọt

| Tính năng v1 | Phán quyết | Lý do | Từ |
|---|---|---|---|
| `failures.tsv`, phân lớp lỗi lọt | interface, đổi dạng: ghi chép lỗi lọt trong `bugfix` sửa lỗi do thay đổi trước | việc học gắn vào việc thật, không cần ai nhớ khai | D-047 |
| Gợi ý nâng thành luật máy | interface: agent rà gợi ý, mức nên sửa; không tự áp dụng | luật sai chặn mọi việc sau | D-043, D-047 |
| `aw journal`, `checks.tsv`, `jobs.tsv`, retro | SP4, gom tự động (không gom tay) | điểm yếu 14, 23 của v1 | D-047, D-048 |

## 5. Thay đổi `interface/`

Mỗi thay đổi theo khuôn SP1 §4: luật theo một stage → capability của stage đó; luật xuyên stage do máy kiểm → invariant
(`INV-014` trở đi, Only for nếu chỉ một job type); giá trị mới → bảng Giá trị của `overview.md` trước khi dùng. Đã duyệt
thì không đổi số; capability bị thay giữ số.

### 5.1 `overview.md`
- Định nghĩa các thuật ngữ §3.
- Giá trị mới: `high` / `normal` (mức rủi ro); nhãn tin cậy (`trusted` / `untrusted` — tên chốt khi viết).
- Sửa nghĩa `agent` (Judged by): "đạt" phải kèm con trỏ tới bằng chứng; thiếu hoặc con trỏ hỏng thì coi là chưa phán
  (D-033).
- Nguyên tắc: nội dung không tin cậy chỉ là dữ liệu; mọi hành động của agent truy được về artifact đã duyệt hoặc
  capability của stage (D-038).
- Bảng quyền theo stage (D-046): ghi, chạy lệnh, mạng, production.
- Bốn mức bật của luật bảo mật (D-037) nếu cần để đọc các trang.
- Cập nhật kịch bản xuyên suốt cho khớp.

### 5.2 `invariants.md` (mới)
- Lời khai và file hàng rào: luật đọc bản ở điểm xuất phát; thay đổi đụng chúng thì phần đụng được người duyệt duyệt riêng
  (D-036, D-040).
- Không secret trong bất cứ thứ gì quy trình lưu bền; không tắt được (D-039).
- Mọi "đạt" của agent có con trỏ giải được (D-033).
- Lệnh agent chạy nằm trong quyền của stage (D-046); máy đối chiếu nhật ký lệnh khi harness không chặn trước được.

### 5.3 `job-types.md`
- `bugfix`, `refactor`: `design` tuỳ chọn, trừ khi mức rủi ro `high` (D-044); sửa `INV-013` cho khớp.
- `chore`: thư viện nâng có thay đổi phá vỡ theo ghi chú phát hành của nó → không phải `chore` (D-034).
- `bugfix` sửa lỗi do thay đổi trước: ghi chép lỗi lọt (D-047).

### 5.4 `00-plan.md`
- `work-item`: bản chữ nguồn chia đoạn, không sửa sau khi ghi; nhãn tin cậy từng nguồn (D-032, D-038).
- Lúc ghi bản chữ nguồn: quét secret, chặn, đoạn bỏ thay bằng dấu che có lý do; che dữ liệu cá nhân theo mẫu lời khai và
  đánh dấu của agent, người duyệt duyệt phần che (mặc định bật) (D-039).
- Secret thấy trong nguồn → báo người duyệt, mức nên sửa, để cân nhắc đổi secret (D-039).

### 5.5 `01-require.md`
- `CAP-require-01`: yêu cầu trỏ tới **đoạn** (không trỏ cả nguồn); máy kiểm con trỏ có thật (D-032).
- Phủ chiều ngược: mỗi đoạn được ít nhất một yêu cầu trỏ tới, hoặc "ngoài phạm vi" kèm lý do người duyệt duyệt (D-032).
- Mức rủi ro: agent đề xuất kèm lý do, người duyệt chốt; đụng mã nhạy cảm → mặc định `high` (D-031).
- Agent không công cụ đọc đoạn từ nguồn không tin cậy, tìm câu nhắm vào agent → phát hiện chặn (D-038).
- Rủi ro cao: tình huống lạm dụng thành câu hỏi mở giả định "từ chối"; câu trả lời là nguồn của yêu cầu (D-044).
- Người duyệt đánh dấu yêu cầu cần lưu bền (D-030).

### 5.6 `02-design.md`
- Đọc tri thức bền vững của phần mã bị đụng; thiết kế ghi dựa vào hay đi ngược tri thức nào (D-030).
- Người duyệt đánh dấu quyết định cần lưu bền (D-030).
- Rủi ro cao: agent liệt kê phương án và đánh đổi, không đề xuất, không xếp hạng; người duyệt chọn và ghi lý do; agent
  phản biện sau; máy kiểm mỗi quyết định có lý do của người (D-031).
- Rủi ro cao: phần ranh giới tin cậy; agent phán chỗ vượt ranh giới bị sót (D-044).
- Phụ thuộc trực tiếp mới là một quyết định có phương án (D-042).

### 5.7 `03-breakdown.md`
- Số file phần mã mỗi task khớp (trên điểm xuất phát) không vượt ngưỡng lời khai, trừ khi task ghi lý do và người duyệt
  duyệt riêng (D-035).

### 5.8 `04-implement.md`
- `CAP-implement-05`: 6 nhóm quét (secret, sast, sca bắt buộc tắt được; IaC, container có điều kiện); chỉ phát hiện mới so
  với điểm xuất phát chặn; secret có sẵn chặn khi đụng đúng file (D-041).
- Luật máy của repo chạy, chỉ vi phạm mới chặn (D-043).
- Tắt tại chỗ thêm vào được khai kèm lý do (D-040).
- Phụ thuộc trực tiếp mới: máy kiểm danh tiếng (có thật, đủ tuổi, bản không vừa phát hành, không bị đánh dấu độc hại,
  lockfile ghim hash); trỏ tới quyết định, hoặc người duyệt duyệt riêng (D-042).
- Quyết định / yêu cầu đánh dấu lưu bền → thay đổi chứa tài liệu tương ứng, máy kiểm có (D-030).

### 5.9 `05-verify.md`
- Tài liệu bền vững bị thay đổi ảnh hưởng còn đúng không (agent, D-030).
- Rủi ro cao: agent không gợi ý ở `design` (agent, D-031).
- `bugfix`: mỗi thay đổi hành vi quan sát được trỏ tới chỗ hành vi đúng đã định nghĩa; thiếu → chặn (agent, D-034).
- Thư viện nâng có thay đổi phá vỡ thì việc không phải `chore` (agent, con trỏ tới ghi chú phát hành, D-034).
- Phần mã khai rộng hơn nhiều so với đụng thật → nên sửa; task đã được duyệt vượt ngưỡng thì không báo (machine, D-035).
- Quy ước của repo → nên sửa (agent, D-036).
- Lý do của từng chỗ tắt tại chỗ (agent, D-040).
- DAST khi rủi ro cao, trên hệ thống đã ghép (machine, D-041).
- Bảo mật theo ý đồ: tầng nhẹ cho mọi thay đổi đụng mã production (phát hiện + điểm đã xem); rủi ro cao đi đủ danh mục
  lời khai; phát hiện bảo mật chặn (agent, D-045).
- Phát hiện viết được thành luật máy → gợi ý, nên sửa (agent, D-047).

### 5.10 `06-deploy.md`, `07-operate.md`
- Chỉ khớp với bảng quyền theo stage (D-046). Không thêm capability.

## 6. Chuyển giao

Ghi vào `docs/decisions.md` § Đang mở, mỗi SP một mục "Chuyển cho SPn (từ SP7)":

- **SP3**: định dạng và nơi giữ: tri thức bền vững (ADR, đánh số, phạm vi), bản chữ nguồn và đoạn, con trỏ, nhãn nguồn,
  `Q-NNN`, nhãn tin cậy, lời khai (gồm `rules_`/`uses_<phase>`, profile thành lời khai mặc định), dấu duyệt, liên kết
  test ↔ yêu cầu; mặc định: ngưỡng phần mã và tỉ lệ khai/đụng, mẫu tắt tại chỗ theo hệ sinh thái, mẫu che dữ liệu cá nhân,
  danh mục bảo mật (7 hạng mục v1 làm gốc); cách giữ nguyên tắc nội dung không tin cậy (sandbox, tách ngữ cảnh); hiển
  thị đoạn nguồn cạnh yêu cầu; worktree; `MAX_RED_RUNS`; ship (artifact trong hay ngoài repo); có cần mục lục không;
  `/aw-clarify`; `/aw-import` (phần work item).
- **SP4**: máy dựng lại tri thức để so, chỉ mục; chạy kiểm bằng file hàng rào ở điểm xuất phát; so khớp phát hiện quét
  giữa hai lần (kể cả DAST); nhận ra repo có IaC/container; kiểm danh tiếng gói (nguồn dữ liệu, ngưỡng N); đọc file khai
  phụ thuộc từng hệ sinh thái; nhật ký lệnh và đối chiếu quyền; nhật ký và gom số liệu tự động (gồm số liệu D-035 C);
  ghim phiên bản, sha256; trạng thái sạch; `aw init`; `/aw-bootstrap` (logic).
- **SP5**: hook dấu duyệt; `/aw-approvals`; `/aw-bootstrap` và lệnh chung theo job type cho từng agent; nối hệ thống
  ticket cho `/aw-import`; ánh xạ bảng quyền theo stage sang quyền của từng harness.
- **SP6**: tín hiệu bảo mật mặc định khi chạy (H5).

## 7. Quy trình

Các trang ở §5 đã được duyệt ở SP1, nên đi theo SP1 §8 (khuôn đổi) và §6 (viết trang), rút gọn:

1. **Sửa** — mỗi trang một lượt, theo §5; tự kiểm luật chặn của SP1 §5.
2. **Đọc lạnh** — agent phiên trắng đọc trang đã sửa cùng `overview.md`, `invariants.md`, `job-types.md`; tối đa 2 lần mỗi
   trang (trang đã qua đọc lạnh ở SP1, chỉ phần mới cần đọc).
3. **Rà chéo** — sau khi sửa hết: luật chặn SP1 §5 trên cả bộ; mỗi quyết định D-030…D-048 có chỗ trong `interface/` hoặc
   trong §6.
4. **Duyệt** — người duyệt phần đổi của từng trang (danh sách trang đã duyệt bị đổi, như SP1 §8); ghi D-NNN.

Thứ tự trang: `overview.md` (thuật ngữ, giá trị) → `invariants.md` → `plan` → `require` → `design` → `breakdown` →
`implement` → `verify` → `deploy`/`operate` → `job-types.md`.

## 8. Xong SP7 khi

- Mỗi tính năng v1 ở §4 có phán quyết; không còn mục nào trong § Ứng viên SP7 chưa có `(→ D-0xx)`.
- `interface/` có đủ thay đổi §5, mỗi trang đổi đã qua đọc lạnh và được người duyệt.
- Luật chặn SP1 §5 đúng trên toàn bộ `interface/`.
- Mục chuyển giao §6 đã ghi vào `docs/decisions.md`.
- `PROGRESS.md`: SP7 `xong`, bước tiếp theo là SP2 ∥ SP3.

## 9. Rủi ro

| Rủi ro | Giảm nhẹ |
|---|---|
| Interface phình, mất tính đọc được mà SP1 đạt được | luật độ dài của khuôn SP1; nội dung chung (thuật ngữ, bảng quyền) ở `overview.md`, trang stage chỉ trỏ tới |
| Quá nhiều capability `agent` → báo cáo `verify` dài, người duyệt xác nhận cho qua | D-033 (đạt có bằng chứng); phần máy kiểm được đã chuyển cho máy (D-043); các phán quyết mới phần lớn ở mức nên sửa |
| Quyết định chồng nhau khi viết thành capability (vd. D-030 #2 ở cả `require`, `design`, `implement`) | rà chéo §7 bước 3; mỗi quan hệ ghi một chỗ (khuôn SP1) |
| Chuyển giao quá nhiều cho SP3, SP3 phình | §6 là danh sách đầu vào để SP3 brainstorm chọn lại, không phải cam kết làm hết |
| Thuật ngữ "lời khai" mơ hồ giữa SP3 và interface | interface chỉ định nghĩa lời khai gồm gì và luật nào dựa vào; nơi giữ, định dạng là SP3 |

## 10. Quyết định của agent khi viết spec (người duyệt kiểm khi đọc)

1. "Mức không chặn" trong D-035, D-036, D-039, D-040, D-047 = mức **nên sửa** đã có; không thêm mức.
2. Ghi chép lỗi lọt (D-047) và tình huống lạm dụng (D-044) viết vào `requirements`, không thêm artifact mới.
3. Luật xuyên stage do máy kiểm (lời khai đọc ở điểm xuất phát, không secret, đạt có con trỏ, lệnh trong quyền) thành
   invariant; còn lại là capability của stage — theo khuôn SP1.
4. Thứ tự sửa trang theo luồng, `job-types.md` cuối (như SP1 §7).
5. Đọc lạnh tối đa 2 lần mỗi trang (SP1 là 3) vì chỉ phần mới cần đọc.
