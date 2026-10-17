# Thuật ngữ

Từ ngữ dùng trong [`huong-dan.md`](huong-dan.md), [`kien-truc.md`](kien-truc.md), output của `aw` và
các artifact. Tên trường, heading trong artifact giữ tiếng Anh vì checker đọc đúng chữ đó.

## Mã định danh

| Mã | Là gì | Nằm ở | Ai đặt |
|---|---|---|---|
| `YC-NNN` | **Yêu cầu**: một điều sản phẩm phải làm, có đúng một nhãn nguồn, tiêu chí chấp nhận quan sát được, `Priority: must \| should` | `spec.md` (`### YC-NNN`) | agent viết, người duyệt cả spec |
| `D-NN` | **Quyết định kỹ thuật** (D-xx): lựa chọn mà người khác có thể chọn khác — ≥ 2 phương án, đánh đổi, lựa chọn, vì sao khó đảo ngược. Mỗi D một ô duyệt | `tdd.md` (`### D-NN`) | agent (Mode 1) hoặc người phác trước (Mode 2) |
| `PH-NN` | **Phát hiện** của checker LLM về thiết kế: `Severity: block \| warn` | `design-findings.md` | checker LLM |
| `T-NN` | **Task** của kế hoạch: `Covers` YC nào, `Based on` D nào, `Expected files`, `Verify` | `plan.md` | agent; `Status` do máy giữ |
| `BR-<MIỀN>-NNN` | **Luật nghiệp vụ bền**: YC đã duyệt được nâng thành bất biến của sản phẩm, đọc lại ở các việc sau | `docs/product/rules/<miền>.md` của repo đích | người chọn nâng (`- Promote: BR-…`) |
| `ADR-NNNN` | **Architecture Decision Record**: D-xx đã duyệt được nâng thành "vì sao code như vậy" của repo | `docs/adr/` của repo đích | người chọn nâng (`- Promote: adr`) |

## Quy trình

| Thuật ngữ | Nghĩa |
|---|---|
| **Phase** | Một bước của quy trình (`00-intake` … `06-ship`), là một hộp **file vào → file ra**. Gọi bằng lệnh `/aw-<phase>` trong agent |
| **Lệnh tiện ích** | Lệnh không phải phase: `/aw-clarify`, `/aw-import`, `/aw-bootstrap` |
| **Việc** | Một đơn vị công việc đi qua quy trình (một ticket, một bug…). Mỗi việc có một branch, một worktree, một thư mục artifact, cùng tên |
| **Loại việc** (`Type`) | `feature \| bugfix \| refactor \| perf \| chore` — ghi trong `intake.md`, **đổi luật** của mọi phase sau. Xem [`huong-dan.md` §5](huong-dan.md#5-khác-nhau-theo-loại-việc) |
| **Input** | Nguồn duy nhất spec được đọc: mã Jira, URL Confluence, file, hoặc lời người. Liệt kê ở `## Input` của `intake.md` |
| **Nhãn nguồn** | Mỗi YC ghi nguồn: `[CONFLUENCE]`, `[JIRA]`, `[FILE]` (trích từ nguồn), `[INFERRED]` (quyết định kỹ thuật hiển nhiên), `[OPEN-QUESTION]` (nguồn chưa nói). Lời người trong `intake.md` mang nhãn input `[HUMAN]` |
| **Điểm mù** | Chỗ nguồn chưa nói mà agent phải giả định tạm. Ghi trong `open-questions.md` theo YC: câu hỏi, hỏi ai, giả định, *If wrong, redo*, mức chặn |
| **Mức chặn** (`Blocking`) | Của điểm mù: `blocking` (chặn design), `review-blocking` (chạy tiếp, review chặn), `non-blocking` (không chặn, YC ghi `pending`). Agent đề xuất, người duyệt |
| **`Risk`** | `high \| normal` trong `spec.md`. `high` → design chạy **Mode 2** |
| **Mode 1 / Mode 2** | Chế độ của phase design. Mode 1: agent viết mọi D-xx, người duyệt. Mode 2 (`Risk: high`): **người phác D-xx trước** (`Author: human`), agent chỉ phản biện — tránh người neo vào phương án của agent |
| **`Design: skip`** | Bugfix/refactor nhỏ (`Risk: normal`, không có lựa chọn kỹ thuật) bỏ phase design; plan đi thẳng từ spec. Chore luôn bỏ design |
| **Promote** | Người đánh dấu một D-xx (`- Promote: adr`) hay YC (`- Promote: BR-…`) để đưa vào git của repo đích thành kiến thức bền |
| **Kiến thức bền** | Thứ còn đúng sau khi việc xong và nằm trong git của repo đích: `conventions.md`, ADR, luật `BR-`, `ARCHITECTURE.md` của module. Đối lập với *trạng thái của việc* (artifact, chỉ ở máy) |

## Kiểm và duyệt

| Thuật ngữ | Nghĩa |
|---|---|
| **Checker máy** | Script `aw check <tên>` — kiểm những gì kiểm được chính xác (đủ mục, truy vết nguồn, test xanh, phạm vi diff). Điều kiện ra **máy** của phase |
| **Checker LLM** | Subagent ngữ cảnh sạch đọc artifact và ghi phát hiện (`PH-NN`). **Chỉ được chặn, không được duyệt** |
| **Cổng người** (gate người) | Điều kiện ra **người** của phase: agent nêu việc người phải làm rồi dừng |
| **Ô duyệt** | Dòng `- [ ] **Approved by human**` trong `spec.md` và dưới mỗi D-xx. Chỉ người đổi thành `[x]` |
| **Dấu duyệt** | `<!-- approval-hash: … -->` máy ghi cạnh ô khi lần đầu thấy tick. Nội dung đổi sau đó → bị chặn tới khi người duyệt lại |
| **Hook gác ô duyệt** | `aw guard pre\|post` cài vào hook của agent: bỏ tick mà agent tự đánh |
| **Chặn / cảnh báo** | Dòng `✗` = vi phạm, phase không đạt. Dòng `!` = cảnh báo: implement cho qua, **review chặn** |
| **Khối `Kết quả`** | Khối cuối output của mọi lệnh `aw`, đánh `[x]` vào đúng một nhãn (`ĐẠT`, `KHÔNG ĐẠT`, `THIẾU ĐẦU VÀO`…). Người và agent đọc nhãn, không đọc mã thoát |
| **Entry check** | Đầu mỗi checker chạy lại checker của phase trước trên input — artifact đưa vào từ ngoài vẫn phải hợp lệ |
| **`based_on`** | Hash các file đầu vào, ghi ở đầu artifact (`aw based-on`). File đầu vào đổi sau đó → artifact **lỗi thời** |
| **Lỗi thời** | Artifact sinh từ bản cũ của đầu vào (spec sửa sau khi có `tdd.md`; code đổi sau `test-results.md`). Implement cảnh báo, review chặn. Sửa: chạy lại phase sinh ra nó |
| **Kiểm chéo** | Kiểm giữa các phase (lỗi thời, test ↔ YC, file ngoài phạm vi, tài liệu bền bị đụng phạm vi). Hay báo nhầm nên chỉ cảnh báo ở implement |
| **`covers:`** | Tag trong test nối test với YC (`covers: YC-001`) hoặc luật `BR-` |
| **`Expected files`** | Ranh giới diff của một task. File ngoài ranh giới phải ghi vào `## Unplanned` |
| **`Tree`** | Hash cây code mà một kết quả (test, quét, review) gắn với. Code đổi sau đó → kết quả không còn mới |
| **Lens 1–4** | Bốn góc của `review.md`: tuân thủ spec, thiết kế và phạm vi, chất lượng, bảo mật |
| **`Blocker` / `Should fix` / `Nit`** | Mức finding của review: không được merge / nên sửa / tác giả quyết |
| **`Security reviewer`** | Tên **người** đã rà bảo mật, bắt buộc khi diff đụng `sensitive_code`. Agent không bao giờ điền |
| **`DỪNG` / `KẸT`** | Nhãn của `aw task`: đỏ liên tiếp `MAX_RED_RUNS` lần / task còn lại đều chờ phụ thuộc. Agent báo người, không thử mò |
| **Nhật ký harness** | `aw journal`: ghi lại lỗi agent làm mà không checker nào bắt, để biết harness thiếu luật ở đâu |

## Cài đặt và môi trường

| Thuật ngữ | Nghĩa |
|---|---|
| **Wrapper `aw`** | File POSIX sh cài một lần mỗi máy (`~/.local/bin/aw`): chọn version, tải và kiểm sha256 engine, chuyển lệnh |
| **Engine** | Checker, định nghĩa phase, mẫu, adapter — repo này. Cài vào cache `~/.agent-workflow/engine/<V>/`, **không** vào repo đích |
| **Version ghim** | Dòng `Engine: <V>` trong `intake.md`. Mọi `aw check` của việc chạy đúng version này; nâng engine không đổi luật việc đang làm |
| **Adapter** | Bộ sinh lệnh `/aw-*`, subagent, skill cho một agent cụ thể (`.claude/`, `.cursor/`) từ định nghĩa phase. Lớp mỏng — luật nằm ở checker |
| **Repo đích** | Repo dự án chạy quy trình (đối lập với repo engine này) |
| **Checkout chính** | Bản clone gốc, luôn đứng ở `base_branch`. Chỉ chạy `/aw-intake`, `/aw-bootstrap`, và dọn ở `/aw-ship` |
| **Worktree** | Thư mục `git worktree` riêng của một việc, nằm **ngoài** repo (`../<repo>.wt/<tên>`). Mọi phase khác chạy ở đây |
| **Base** | Nhánh/commit việc rẽ ra, **người chọn**, ghi trong `intake.md`. Mọi checker so diff với điểm rẽ khỏi base |
| **Thư mục việc** (`<dir>`) | `.agent-workflow/<tên-branch>/` trong worktree — chứa artifact của việc. Bị exclude: không vào commit |
| **Artifact** | File agent/máy viết ra trong thư mục việc (`intake.md`, `spec.md`, `tdd.md`…). Danh sách: [`huong-dan.md` §4](huong-dan.md#4-bản-đồ-artifact) |
| **`conventions.md`** | Quy ước của repo đích (`docs/agent-workflow/conventions.md`), trong git, sửa qua PR. Mỗi việc đọc bản **tại điểm rẽ khỏi base** |
| **`config.sh`** | Cấu hình của từng bản clone (`.git/agent-workflow/config.sh`), không commit: `TEST_CMD`, `SECURITY_CMDS`, `ADAPTER`… |
| **`rules_<phase>` / `uses_<phase>`** | Khoá trong `conventions.md`: file agent **đọc** / skill, subagent agent **gọi** trong phase đó |
| **`production_code`, `test_files`, `sensitive_code`…** | Glob trong `conventions.md` phân loại file của repo đích. `*` khớp cả `/`. Giải thích từng khoá: [`conventions-reference.md`](../workflow/templates/conventions-reference.md) |
| **Phiên trắng / ngữ cảnh sạch** | Phiên agent mới, không mang hội thoại cũ. Mỗi phase phải chạy được từ phiên trắng; review **bắt buộc** ngữ cảnh sạch |
