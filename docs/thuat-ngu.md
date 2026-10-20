# Thuật ngữ

Từ ngữ dùng trong [`huong-dan.md`](huong-dan.md), [`kien-truc.md`](kien-truc.md), output của `aw`,
các artifact — và **trong lời agent nói với bạn**.

Agent gọi khái niệm bằng **đúng thuật ngữ tiếng Anh** ở cột đầu — khi nói với bạn và trong phần
chữ tiếng Việt của artifact — không tự dịch; câu quanh nó vẫn là tiếng Việt: "REQ-003 còn một
`open question` chặn design". Danh sách agent đọc lúc chạy:
[`workflow/rules/terms.md`](../workflow/rules/terms.md); file này giải thích nghĩa cho người. Từ
trong ngoặc *(trước: …)* là tên tiếng Việt cũ, để tra nếu gặp ở tài liệu cũ.

Artifact còn từ dịch cũ (cột `Not` của `terms.md`: "điểm mù", "lỗi thời", "ô duyệt"…) thì
`aw check implement` và `aw check review` cảnh báo; riêng `review.md` thì `aw check review` chặn.
Không kiểm `intake.md`, `refactor-requests.md`, `*-results.md` và dòng trích `>` — chỗ đó là
nguyên văn lời người hoặc do máy ghi. Cũng không kiểm chữ trong code span, `"…"`, `“…”` và fenced
code block, nên viết được `"ô duyệt" là từ dịch` khi mô tả lỗi. Lời agent nói trong chat thì không máy nào kiểm được.

Tên trường, heading trong artifact giữ tiếng Anh vì checker đọc đúng chữ đó. Nhãn `aw` in ra
(`Kết quả`, `ĐẠT`, `DỪNG`, `KẸT`…) giữ tiếng Việt vì checker và agent khớp đúng chữ.

## Mã định danh

Mọi mã theo cùng một dạng: `<TIỀN TỐ>-<SỐ>`.

- **Tiền tố** là ba chữ in hoa viết tắt thuật ngữ tiếng Anh (`REQ` = requirement, `DEC` = decision…),
  để mã đọc được, grep được và không lẫn với chữ thường trong câu.
- **Số** có đúng 3 chữ số, có số 0 đứng đầu (`REQ-001`, `DEC-001`, `TSK-012`), đánh liên tiếp trong
  một artifact. Anchor là mã viết thường: `#req-001`, `#dec-001`. Heading có mã không đủ hoặc thừa
  chữ số (`REQ-1`, `DEC-0001`) bị `aw check` của phase viết ra mã chặn; đánh số liên tiếp thì chưa kiểm.
- **Phạm vi**: mã trong job dir (`REQ`, `DEC`, `FND`, `TSK`, `RFR`) chỉ có nghĩa trong một `job`;
  `REQ-001` của hai job là hai thứ khác nhau. Mã của `durable knowledge` dùng chung cả `target repo`
  nên giữ dạng riêng: `BR-<MIỀN>-NNN` có thêm miền, `ADR-NNNN` theo quy ước ADR thông dụng.

Tên cũ (`YC-`, `D-`, `PH-`, `T-`, `RF-`) chỉ còn ở job chạy bằng engine cũ.

| Thuật ngữ | Mã | Là gì | Nằm ở | Ai đặt |
|---|---|---|---|---|
| `requirement` *(trước: yêu cầu)* | `REQ-NNN` | Một điều sản phẩm phải làm, có đúng một `source label`, tiêu chí chấp nhận quan sát được, `Priority: must \| should` | `spec.md` (`### REQ-NNN`) | agent viết, người duyệt cả spec |
| `decision` *(trước: quyết định kỹ thuật)* | `DEC-NNN` | Lựa chọn mà người khác có thể chọn khác — ≥ 2 phương án, đánh đổi, lựa chọn, vì sao khó đảo ngược. Mỗi DEC một `approval checkbox` | `tdd.md` (`### DEC-NNN`) | agent (`Mode 1`) hoặc người phác trước (`Mode 2`) |
| `finding` *(trước: phát hiện)* | `FND-NNN` | Kết quả của `LLM checker` về thiết kế: `Severity: block \| warn` | `design-findings.md` | `LLM checker` |
| `task` | `TSK-NNN` | Bước của kế hoạch: `Covers` REQ nào, `Based on` DEC nào, `Expected files`, `Verify` | `plan.md` | agent; `Status` do máy giữ |
| `refactor request` | `RFR-NNN` | Yêu cầu refactor của người, mới ghi nhận, chưa làm | `refactor-requests.md` | `/aw-refactor` |
| `business rule` *(trước: luật nghiệp vụ bền)* | `BR-<MIỀN>-NNN` | REQ đã duyệt được nâng thành bất biến của sản phẩm, đọc lại ở các `job` sau | `docs/product/rules/<miền>.md` của `target repo` | người chọn nâng (`- Promote: BR-…`) |
| `ADR` | `ADR-NNNN` | **Architecture Decision Record**: DEC-xxx đã duyệt được nâng thành "vì sao code như vậy" của repo | `docs/adr/` của `target repo` | người chọn nâng (`- Promote: adr`) |

## Quy trình

| Thuật ngữ | Nghĩa |
|---|---|
| `phase` | Một bước của quy trình (`00-intake` … `06-ship`), là một hộp **file vào → file ra**. Gọi bằng lệnh `/aw-<phase>` trong agent |
| `utility command` *(trước: lệnh tiện ích)* | Lệnh không phải phase: `/aw-clarify`, `/aw-import`, `/aw-bootstrap` |
| `job` *(trước: việc)* | Một đơn vị công việc đi qua quy trình (một ticket, một bug…). Mỗi `job` có một branch, một `worktree`, một `job dir`, cùng tên |
| `job type` *(trước: loại việc)* | `Type` trong `intake.md`: `feature \| bugfix \| refactor \| perf \| chore`, **đổi luật** của mọi phase sau. Xem [`huong-dan.md` §5](huong-dan.md#5-khác-nhau-theo-job-type) |
| `input` | Nguồn duy nhất spec được đọc: mã Jira, URL Confluence, file, hoặc lời người. Liệt kê ở `## Input` của `intake.md` |
| `source label` *(trước: nhãn nguồn)* | Mỗi REQ ghi nguồn: `[CONFLUENCE]`, `[JIRA]`, `[FILE]` (trích từ nguồn), `[INFERRED]` (quyết định kỹ thuật hiển nhiên), `[OPEN-QUESTION]` (nguồn chưa nói). Lời người trong `intake.md` mang nhãn `[HUMAN]` |
| `Quote` *(câu trích)* | Câu nguồn chép **nguyên văn** dưới `Source:` của REQ (`[CONFLUENCE]` `[JIRA]` `[FILE]`), mỗi câu một dòng `> …`. Với `[FILE]` máy kiểm câu có thật trong file |
| `open question` *(trước: điểm mù)* | Chỗ nguồn chưa nói mà agent phải giả định tạm. Ghi trong `open-questions.md` theo REQ: câu hỏi, hỏi ai, giả định, *If wrong, redo*, `Blocking` |
| `Blocking` *(trước: mức chặn)* | Mức của một `open question`: `blocking` (chặn design), `review-blocking` (chạy tiếp, review chặn), `non-blocking` (không chặn, REQ ghi `pending`). Agent đề xuất, người duyệt |
| `Risk` | `high \| normal` trong `spec.md`. `high` → design chạy `Mode 2` |
| `Mode 1` / `Mode 2` | Chế độ của phase design. `Mode 1`: agent viết mọi DEC-xxx, người duyệt. `Mode 2` (`Risk: high`): **người phác DEC-xxx trước** (`Author: human`), agent chỉ phản biện — tránh người neo vào phương án của agent |
| `Design: skip` | Bugfix/refactor nhỏ (`Risk: normal`, không có lựa chọn kỹ thuật) bỏ phase design; plan đi thẳng từ spec. Chore luôn bỏ design |
| `Promote` | Người đánh dấu một DEC-xxx (`- Promote: adr`) hay REQ (`- Promote: BR-…`) để đưa vào git của `target repo` thành `durable knowledge` |
| `durable knowledge` *(trước: kiến thức bền)* | Thứ còn đúng sau khi `job` xong và nằm trong git của `target repo`: `conventions.md`, ADR, `business rule`, `ARCHITECTURE.md` của module. Đối lập với *trạng thái của job* (artifact, chỉ ở máy) |

## Kiểm và duyệt

| Thuật ngữ | Nghĩa |
|---|---|
| `machine checker` *(trước: checker máy)* | Script `aw check <tên>` — kiểm những gì kiểm được chính xác (đủ mục, truy vết nguồn, test xanh, phạm vi diff). Điều kiện ra **máy** của phase |
| `LLM checker` *(trước: checker LLM)* | Subagent `clean context` đọc artifact và ghi `finding` (`FND-NNN`). **Chỉ được chặn, không được duyệt** |
| `human gate` *(trước: cổng người)* | Điều kiện ra **người** của phase: agent nêu việc người phải làm rồi dừng |
| `approval checkbox` *(trước: ô duyệt)* | Dòng `- [ ] **Approved by human**` trong `spec.md` và dưới mỗi DEC-xxx. Chỉ người đổi thành `[x]` |
| `approval hash` *(trước: dấu duyệt)* | `<!-- approval-hash: … -->` máy ghi cạnh ô khi lần đầu thấy tick. Nội dung đổi sau đó → bị chặn tới khi người duyệt lại |
| `approval guard` *(trước: hook gác ô duyệt)* | `aw guard pre\|post` cài vào hook của agent: bỏ tick mà agent tự đánh |
| `block` / `warn` *(trước: chặn / cảnh báo)* | Dòng `✗` = vi phạm, phase không đạt. Dòng `!` = cảnh báo: implement cho qua, **review chặn** |
| Khối `Kết quả` | Khối cuối output của mọi lệnh `aw`, đánh `[x]` vào đúng một nhãn (`ĐẠT`, `KHÔNG ĐẠT`, `THIẾU ĐẦU VÀO`…). Người và agent đọc nhãn, không đọc mã thoát |
| `entry check` | Đầu mỗi checker chạy lại checker của phase trước trên input — artifact đưa vào từ ngoài vẫn phải hợp lệ |
| `based_on` | Hash các file đầu vào, ghi ở đầu artifact (`aw based-on`). File đầu vào đổi sau đó → artifact `stale` |
| `stale` *(trước: lỗi thời)* | Artifact sinh từ bản cũ của đầu vào (spec sửa sau khi có `tdd.md`; code đổi sau `test-results.md`). Implement cảnh báo, review chặn. Sửa: chạy lại phase sinh ra nó |
| `cross-check` *(trước: kiểm chéo)* | Kiểm giữa các phase (`stale`, test ↔ REQ, file ngoài phạm vi, `durable knowledge` bị đụng phạm vi). Hay báo nhầm nên chỉ `warn` ở implement |
| `covers:` | Tag trong test nối test với REQ (`covers: REQ-001`) hoặc `business rule` |
| `Expected files` | Ranh giới diff của một `task`. File ngoài ranh giới phải ghi vào `## Unplanned` |
| `Tree` | Hash cây code mà một kết quả (test, quét, review) gắn với. Code đổi sau đó → kết quả không còn mới |
| `Lens 1–4` | Bốn góc của `review.md`: tuân thủ spec, thiết kế và phạm vi, chất lượng, bảo mật |
| `Blocker` / `Should fix` / `Nit` | Mức finding của review: không được merge / nên sửa / tác giả quyết |
| `Security reviewer` | Tên **người** đã rà bảo mật, bắt buộc khi diff đụng `sensitive_code`. Agent không bao giờ điền |
| `DỪNG` / `KẸT` | Nhãn của `aw task`: đỏ liên tiếp `MAX_RED_RUNS` lần / `task` còn lại đều chờ phụ thuộc. Agent báo người, không thử mò |
| `harness journal` *(trước: nhật ký harness)* | `aw journal`: ghi lại lỗi agent làm mà không checker nào bắt, để biết harness thiếu luật ở đâu |

## Cài đặt và môi trường

| Thuật ngữ | Nghĩa |
|---|---|
| `wrapper` | File `aw` (POSIX sh) cài một lần mỗi máy (`~/.local/bin/aw`): chọn version, tải và kiểm sha256 `engine`, chuyển lệnh |
| `engine` | Checker, định nghĩa phase, mẫu, adapter — repo này. Cài vào cache `~/.agent-workflow/engine/<V>/`, **không** vào `target repo` |
| `pinned version` *(trước: version ghim)* | Dòng `Engine: <V>` trong `intake.md`. Mọi `aw check` của `job` chạy đúng version này; nâng engine không đổi luật `job` đang làm |
| `adapter` | Bộ sinh lệnh `/aw-*`, subagent, skill cho một agent cụ thể (`.claude/`, `.cursor/`) từ định nghĩa phase. Lớp mỏng — luật nằm ở checker |
| `target repo` *(trước: repo đích)* | Repo dự án chạy quy trình (đối lập với repo `engine` này) |
| `main checkout` *(trước: checkout chính)* | Bản clone gốc, luôn đứng ở `base_branch`. Chỉ chạy `/aw-intake`, `/aw-bootstrap`, và dọn ở `/aw-ship` |
| `worktree` | Thư mục `git worktree` riêng của một `job`, nằm **ngoài** repo (`../<repo>.wt/<tên>`). Mọi phase khác chạy ở đây |
| `base` | Nhánh/commit `job` rẽ ra, **người chọn**, ghi trong `intake.md`. Mọi checker so diff với điểm rẽ khỏi base |
| `job dir` *(trước: thư mục việc, <dir>)* | `docs/sdlc/<tên-branch>/` trong `worktree` — chứa artifact của `job`. `aw check` ĐẠT thì commit vào branch của việc; `aw ship create` gỡ khỏi branch trước MR, không vào nhánh đích. Việc tạo bằng engine cũ: `.agent-workflow/<tên-branch>/`, chỉ ở máy |
| `artifact` | File agent/máy viết ra trong `job dir` (`intake.md`, `spec.md`, `tdd.md`…). Danh sách: [`huong-dan.md` §4](huong-dan.md#4-bản-đồ-artifact) |
| `conventions.md` | Quy ước của `target repo` (`docs/agent-workflow/conventions.md`), trong git, sửa qua PR. Mỗi `job` đọc bản **tại điểm rẽ khỏi base** |
| `config.sh` | Cấu hình của từng bản clone (`.git/agent-workflow/config.sh`), không commit: `TEST_CMD`, `SECURITY_CMDS`, `ADAPTER`… |
| `rules_<phase>` / `uses_<phase>` | Khoá trong `conventions.md`: file agent **đọc** / skill, subagent agent **gọi** trong phase đó |
| `production_code`, `test_files`, `sensitive_code`… | Glob trong `conventions.md` phân loại file của `target repo`. `*` khớp cả `/`. Giải thích từng khoá: [`conventions-reference.md`](../workflow/templates/conventions-reference.md) |
| `fresh session` / `clean context` *(trước: phiên trắng / ngữ cảnh sạch)* | Phiên agent mới, không mang hội thoại cũ. Mỗi phase phải chạy được từ `fresh session`; review và `LLM checker` **bắt buộc** `clean context` |
