# Changelog

Version là `YYYY.M.N`: năm, tháng phát hành, và `N` là **số thứ tự bản phát hành
trong tháng** (1, 2, 3, …; sang tháng mới đếm lại từ 1), không số 0 đứng đầu, vd
`2026.10.8`, `2026.11.1`. Mỗi bản phát hành là một git tag đúng chuỗi đó, không
có tiền tố `v`. (Trước đó `N` là ngày phát hành — `2026.10.6`, `2026.10.7` vẫn
hợp lệ, tháng 10/2026 đếm tiếp từ đó.) Repo đích ghim version cần dùng (xem
README, mục "Nâng cấp"); một việc đã bắt đầu thì chạy hết bằng version ghi trong
`intake.md` của nó.

So version theo luật **khớp chính xác `YYYY.M.N`** — không có "tương thích ngược"
ngầm giữa các bản.

## [2026.10.31]

### Thêm
- **`aw check spec` chặn hai lỗi nguồn trước đây lọt qua:** `Source: [JIRA]` không có mã issue khớp
  `jira_key_regex` (cùng luật với `aw check intake`), và `[INFERRED]` không ghi lý do (để trống hay
  còn `<…>`). Spec đang viết dở có hai lỗi này thì sửa dòng `Source:` rồi chạy lại.
- **Cảnh báo nguồn ngoài intake:** REQ có nguồn `[JIRA]`/`[CONFLUENCE]`/`[FILE]` mà mã, URL hay đường
  dẫn không có trong `## Input` của `intake.md` thì `aw check spec` **cảnh báo** (không chặn). Đúng
  là đầu vào thì thêm vào intake; không thì kiểm lại nguồn.
- **Khoá `high_risk_keywords` trong `conventions.md`** (tuỳ chọn): từ khoá rủi ro cao, cách nhau dấu
  phẩy. Spec ghi `Risk: normal` mà chứa từ khoá thì `aw check spec` **cảnh báo** để người duyệt xem
  lại `Risk`. Repo cài từ trước: thêm dòng `high_risk_keywords: …` nếu muốn bật; không thêm thì như cũ.
- **Hướng dẫn: "Khi nào không dùng `aw`"** (`docs/huong-dan.md` § 1.10) — việc nào làm PR thường (typo, bump
  `patch`, cấu hình một dòng), dấu hiệu nên quay lại `aw`, và cách đo bằng `aw journal export` / `report` để
  quyết đường tắt cho việc nhỏ sau này.
- **`aw journal export <file>` và `aw journal report <file>…`.** Nhật ký harness nằm ở bản clone từng máy; giờ
  xuất được ra một TSV (cột nguồn, máy, rồi cột gốc) và tổng hợp trên nhiều file export — gom số liệu khi chạy
  thử trên nhiều máy / nhiều người. Dòng sai dạng bị bỏ qua và báo số dòng.
- **Vòng review → sửa có đường đi rõ.** Finding `Blocker` / `Should fix` của `review.md` mang mã `RVW-NNN`;
  `/aw-plan` chạy lại sau review ở chế độ **bổ sung**: chỉ thêm task, task sửa ghi `Fixes: RVW-NNN` (hoặc
  `Fixes: <URL bình luận MR>`) thay `Covers:`. `aw check plan` kiểm `Fixes` trỏ mã có thật. `Blocker` vẫn
  luôn phải sửa.
- **Glob `**` trong `plan.md`.** `Expected files` / `Unplanned` dùng được `**` (khớp qua thư mục). Giai đoạn
  chuyển tiếp: `*` vẫn khớp qua `/` nhưng `aw check implement` / `aw check review` cảnh báo (không chặn) file
  chỉ khớp nhờ `*` vượt thư mục và gợi ý cách viết `**` — bản sau `*` của `plan.md` sẽ không qua `/`. Glob
  của `conventions.md` không đổi.
- **Kiểm phạm vi diff theo từng task.** `aw task start` ghi commit lúc bắt đầu; `aw task done` cảnh báo
  file task đổi mà không nằm trong `Expected files` của chính nó (hay hàng `Unplanned` có cột Task = task
  đó) và ghi `Scope warning` vào `task-results.md`. `/aw-review` chặn nếu dòng `Task scope warnings` ở
  Lens 2 không giải trình task đó. Việc bắt đầu ở bản cũ (không có `Started at`) không bị kiểm.
- **Cảnh báo glob rộng ở `aw check plan`.** Mẫu `Expected files` khớp nhiều file đã track trên commit
  `Base:` hơn khoá mới `scope_glob_max_files` (mặc định 30; `0` = tắt) thì cảnh báo. `conventions.md` cũ
  không có khoá vẫn chạy với mặc định; thêm khoá khi muốn đổi ngưỡng.
- **Capability cho mọi stage của interface SDLC (`CAP-<stage>-NN`).** Mỗi file `sdlc/stages/*.md` có
  mục `## Capabilities`: các điều stage phải làm được khi làm **đủ**, kèm `Rule` và `Judged by`
  (`machine`, `agent` hay `human` phán đạt) — 23 capability, gồm cả phần engine chưa làm (ưu tiên,
  ước lượng, e2e, kiểm tải, UAT, release, rollback, quan sát production, sự cố → việc mới). Vì sao:
  trước đây phần thiếu chỉ là một câu `note` tự do, không ai biết "làm đủ một stage" là gì; giờ
  interface là trạng thái đích, chỉ ra việc tiếp theo.
- **Bảng roadmap trong `sh tools/check-sdlc.sh`**: "Capability còn thiếu" theo stage, kèm note. Mỗi lỗi
  của checker nói luôn cách sửa.
- **`docs/interface-sdlc.md`** — hướng dẫn cho người sửa engine: interface gồm gì, đọc file stage,
  trạng thái được suy ra thế nào, công thức cho 7 loại thay đổi (thêm luật, làm capability thiếu, thêm
  capability, thêm phase, thêm job type, hạ chuẩn interface, thay đổi không chạm interface), đọc lỗi
  `check-sdlc.sh`, và roadmap hiện tại giải thích bằng tiếng Việt. Thuật ngữ mới: `capability`.
- **Checker LLM cho spec.** Sau khi viết `spec.md`, agent gọi subagent `spec-checker`. Checker chỉ đối chiếu mô tả và tiêu chí chấp nhận với `Quote` và lời `[HUMAN]` trong `intake.md` — không đọc lại file, Jira, Confluence. Nó chỉ được chặn. Kết quả ghi `spec-findings.md`.
- **`aw check spec` chặn** khi thiếu `spec-findings.md`, hoặc còn phát hiện `block` chưa `fixed` / `rejected: <lý do>`. Cảnh báo (`warn`) không chặn. Người phân xử qua `/aw-clarify` trước khi tick duyệt spec. Khi không có phase design, phát hiện `block` của spec chặn `/aw-plan`.
- **`aw approval`** (cổng vào design hoặc plan) in một dòng nếu finding của spec còn chưa phân xử.
- **Nhãn nguồn `[INCIDENT]`.** `intake.md` ghi được sự cố hoặc postmortem bằng `[INCIDENT] <định danh>` — cùng luật với `[FILE]`: phải có định danh, không còn chỗ giữ chỗ. Bugfix được trỏ về sự cố gốc. Không bắt buộc: lời người không có mã sự cố vẫn là `[HUMAN]`.
- **`sh tools/check-sdlc.sh --suy <file>…`** in các id `CAP-…` / `INV-…` mà dòng `# giữ:` trong những file đó khai — dùng với danh sách file của một diff. Id không có thì không đạt. Lệnh không tự gắn id.

### Thay đổi
- **Mã định danh không đúng 3 chữ số giờ bị chặn.** Luật `<PREFIX>-NNN` (đúng 3 chữ số) đã có từ
  trước nhưng checker vẫn nhận mọi dạng số, nên `REQ-1` hay `DEC-0001` lọt qua. Giờ checker của
  phase viết ra mã sẽ chặn heading sai dạng: `aw check spec` cho `REQ` (trong `spec.md` và
  `open-questions.md`), `aw check design` cho `DEC` và `FND`, `aw check plan` cho `TSK`.
  **Ai bị ảnh hưởng:** chỉ những việc đang có mã sai dạng. Sửa heading về dạng `REQ-001` cùng mọi
  tham chiếu tới nó, rồi chạy lại `aw check`. Việc đã ghim engine cũ trong `intake.md` không bị ảnh
  hưởng. Đánh số liên tiếp vẫn không kiểm. `RFR` được kiểm ở mục mã định danh dưới heading `###`.
- **`aw check review` chặn finding `Blocker` / `Should fix` không có mã `RVW-NNN` hoặc trùng mã.** Review mới
  phải viết tiêu đề dạng `### [Blocker] RVW-001 — <tiêu đề>` (mẫu `review.md` đã đổi); `[Nit]` không cần mã.
- **INV-001 nới** (interface SDLC): "mọi task phủ một REQ" thành "mọi task phủ một REQ **hoặc sửa một finding
  của review hiện tại**". Lý do: finding lỗi (thiếu kiểm null, lỗ hổng) thường không gắn REQ nào; buộc
  `Covers:` khiến agent gán đại REQ, làm sai ánh xạ REQ → task mà review Lens 1 dựa vào.
- **`aw check review` không còn chặn vì từ dịch trong artifact của phase trước — chỉ cảnh báo.**
  Trước đây một từ như "ô duyệt" trong `tdd.md` làm review `KHÔNG ĐẠT` dù code không còn Blocker
  nào; review không được sửa `tdd.md` nên phải quay về `/aw-design` chỉ vì một lỗi văn phong. Giờ
  review in `[CẢNH BÁO] tdd.md dòng 15: "ô duyệt" là từ dịch — viết `approval checkbox``, vẫn ĐẠT.
  Riêng `review.md` (file review tự viết, sửa được ngay) thì vẫn chặn. `aw check implement` vẫn
  cảnh báo như trước, nhưng tách từ dịch ra khỏi nhóm "review sẽ CHẶN nếu còn". Định dạng thông báo
  giữ nguyên.
- **Mã định danh luôn ở heading `###`, dưới một `##` của nhóm.** Trước đây mỗi file một kiểu:
  `### REQ` trong `spec.md` nhưng `## REQ` trong `open-questions.md`, `## RFR` trong
  `refactor-requests.md`, còn `### FND` lại nằm dưới `## Contents`. Giờ:
  `open-questions.md` dùng `## Questions` → `### REQ-NNN`; `refactor-requests.md` dùng
  `## Requests` → `### RFR-NNN`; `design-findings.md` dùng `## Findings` → `### FND-NNN`.
  `aw check spec` **chặn** dạng cũ `## REQ-NNN`/`## RFR-NNN` và chỉ cách đổi. Anchor không đổi nên
  link `open-questions.md#req-002-…` vẫn đúng. **Ai bị ảnh hưởng:** việc đã ghim engine cũ trong
  `intake.md` chạy tiếp bình thường. Việc chuyển sang engine này mà đã có `open-questions.md` hay
  `refactor-requests.md`: đổi `## REQ-`/`## RFR-` thành `### …`, thêm `## Questions`/`## Requests`
  phía trên, rồi chạy `aw toc`.
- **`aw check spec` kiểm `refactor-requests.md`** (nếu có): chặn mã `RFR` không đúng 3 chữ số và
  mã trùng. Phase sau chạy lại spec nên RFR ghi ở phase nào cũng được kiểm. Đánh số liên tiếp vẫn
  không kiểm (xoá một mục giữa chừng là hợp lệ).
- **Trạng thái stage do máy suy ra, khối `sdlc:` của `workflow.yaml` bỏ khoá `status`.** Phase khai
  `capabilities:`; capability có phase nhận hết = `implemented`, một phần = `partial`, không = `gap`.
  Khối `sdlc:` chỉ còn `note` (bắt buộc với `partial`/`gap`, cấm với `implemented`). Phase `implements`
  một stage mà không nhận capability nào → chặn. **Ai bị ảnh hưởng:** người sửa engine hay giữ bản fork
  có khối `sdlc:` riêng — xoá các dòng `status:` (còn sót thì `check-sdlc.sh` chặn và chỉ dòng cần xoá).
  Người dùng `aw` trên repo dự án không thấy gì khác: lệnh adapter sinh ra giữ nguyên (đã so byte với
  `main`); `workflow/rules/terms.md` (danh sách thuật ngữ agent đọc) có thêm `capability` và dòng
  `stage status` nói trạng thái được suy ra.
- Việc mới phải có `spec-findings.md`. Việc đã ghim engine cũ không bị ảnh hưởng.
- **Bugfix: lệnh đã đỏ phải là lệnh đang xanh.** `repro.md` ghi cả lệnh kiểm thử, không ghi riêng tên một test, nên máy không tách tên test (dễ báo nhầm theo ngôn ngữ). `aw check implement` cảnh báo khi lệnh trong `repro.md` khác lệnh trong `test-results.md`. `aw check review` chặn. Người vẫn phán test đỏ đúng vì bug (`Repro test fails because:`).
- **INV-007** nới thêm điều này: sau khi sửa, verify chặn nếu lệnh xanh không phải lệnh đã đỏ; implement chỉ cảnh báo.
- Ba capability trên chuyển vào `out_of_scope` của `workflow.yaml`. Bảng "còn thiếu" không còn liệt kê
  chúng; chúng hiện ở mục "Không làm". Trạng thái stage không đổi: `plan` và `verify` vẫn partial.
- `CAP-deploy-03` giữ trên roadmap: engine ghi được đường rollback trong `merge-request.md`.
- `CAP-operate-02` vẫn do người phán, stage `operate` vẫn gap. Intake implement stage `plan`, không nhận capability của stage khác, và một phase operate phải đứng sau ship — sự cố lại là đầu vào của việc mới.

### Sửa
- **`aw check review` không xoá finding cũ khi review chạy lại mà không còn finding nào.** Nhật ký
  `findings.tsv` giữ lại finding đã sửa xong, nên `aw journal` đếm sai và có thể gợi ý nâng một loại
  finding thành luật dù nó không còn. Lỗi này cũng để sót file tạm `findings.tsv.<pid>` trong thư mục
  nhật ký. Không cần làm gì; lần chạy review kế tiếp của việc đó sẽ ghi đè finding cũ. File tạm đã
  sót có thể xoá tay.
- **Phạm vi diff:** hàng `Unplanned` chỉ lấy cột "Extra files" làm mẫu được phép (backtick ở cột "What came up"
  không còn vô tình miễn file — plan cũ ghi mẫu ở cột khác thì chuyển sang cột "Extra files"); dòng `Base:`
  thiếu sha thì cảnh báo glob rộng lùi về điểm rẽ nhánh thay vì bỏ qua.
- **`aw task start` giữ bộ đếm đỏ liên tiếp** — sửa tay Status về `[ ]` rồi start lại không còn né được điều
  kiện DỪNG (đúng như trước PR #79). Bộ đếm chỉ về 0 khi `aw task done` xanh; người đã xử lý xong muốn agent
  thử tiếp thì xoá dòng `- Đỏ liên tiếp: N` của task trong `task-results.md` (`docs/huong-dan.md`).
- **Mã `RVW`:** `aw check plan` đọc mã finding giống `aw check review` (tiêu đề Lens 3 có `[mức]` rồi mã, kể
  cả `### 1. [Blocker] RVW-001 — …`); dòng `Task scope warnings` phải nhắc đúng mã task (`TSK-0021` không
  tính là nhắc `TSK-002`).
- **Glob `[abc]`, `[!a]`, `[[:alpha:]]`** khớp như `case` của shell ở mọi hàm khớp mới (đếm glob rộng, cảnh báo chuyển tiếp).
- **`aw journal report`** không đếm hai lần một file truyền trùng; file / thư mục tạm không còn tên đoán trước
  được (cảnh báo chuyển tiếp không dùng file tạm; report dùng `mktemp -d`).
- **Kiểm từ dịch không còn bắt chính chỗ trích lại từ đó.** Chữ trong code span `` `…` ``, ngoặc
  kép `"…"`, `“…”` và fenced code block được bỏ qua (cùng với dòng trích `>` như cũ), nên người rà
  soát viết được `"ô duyệt" là từ dịch` trong `review.md` mà không bị chặn.

### Bỏ
- **Hai adapter `planned` (`codex`, `copilot`) khỏi `workflow.yaml`.** Chưa có thư mục hay mã nào; mục
  `planned` chỉ là lời hứa trong manifest. Thêm lại khi có người dùng thật cần, theo `adapters/README.md`
  (ghi chú về Codex vẫn giữ ở đó). Người dùng `aw` không thấy gì khác.
- `CAP-plan-03` — xếp ưu tiên giữa các việc là việc của người. Engine chỉ nhận việc đã có.
- `CAP-plan-04` — ước lượng công là việc của người, không của engine.
- `CAP-verify-05` — nghiệm thu (UAT) thuộc quy trình của repo đích, không của engine.

### Nội bộ
- `docs/viec-can-lam.md`: thêm bốn việc cần làm từ một lượt đánh giá các phase, mỗi việc ghi vấn đề
  (kèm file, hàm liên quan), đề xuất cần duyệt, chặn hay cảnh báo, test và tài liệu phải đổi:
  vòng review → implement chưa có cơ chế thêm task; `Expected files` không chặn được glob rộng và
  không kiểm theo từng task; checker LLM cho spec; đường tắt cho việc rất nhỏ (cần quyết định).
  Chưa đổi hành vi của `aw`; người dùng không cần làm gì.
- **Repo engine: mọi thay đổi đi qua worktree từ `origin/main` rồi PR vào `main`, kể cả sửa tài liệu
  hay lỗi chính tả.** Luật đưa lên đầu `AGENTS.md`. Với Claude Code, hook `.claude/hooks/block-main.sh`
  (khai trong `.claude/settings.json`) chặn agent sửa file, commit, merge, push trên checkout đang ở
  `main`, và chặn push thẳng vào `main` từ bất cứ đâu; worktree nhánh khác, repo khác, file ngoài git
  vẫn cho qua. Hook không bắt lệnh shell tự ghi file (`sed -i`, `>`) và không áp cho agent khác
  (Cursor…) — với các trường hợp đó luật chữ là chính. Người dùng `aw` không bị ảnh hưởng; người
  phát triển engine cần mở phiên Claude Code từ repo đã có commit này để hook có hiệu lực.
  `.claude/worktrees/` và `.claude/settings.local.json` được thêm vào `.gitignore`. Test:
  `tools/tests/19-block-main-hook.sh`.
- **Roadmap cải thiện engine theo dự án con.** `docs/superpowers/2026-10-22-roadmap-cai-thien.md` chia
  kết quả lượt đánh giá 10/2026 (engine và interface SDLC) thành 12 dự án con có thứ tự, phụ thuộc và
  câu cần người quyết; mỗi dự án con đi spec → plan → PR theo luồng Superpowers. `docs/viec-can-lam.md`
  trỏ tới roadmap. Không đổi hành vi `aw`.
- **Interface SDLC: capability phạm vi.** Thêm `CAP-breakdown-02` (task nêu file được đổi và cách kiểm),
  `CAP-implement-04` (file đổi nằm trong kế hoạch hoặc khai ngoài kế hoạch), `CAP-implement-05` (phạm vi
  theo từng task, mẫu file hẹp), `CAP-implement-06` (task chỉ xong khi máy ghi bước kiểm đạt). Cả bốn đều có
  phase nhận; stage `implement` vẫn `implemented`. Người dùng `aw` không thấy gì khác.
- **Interface SDLC: capability khai `Artifact`.** Mỗi capability ghi loại artifact nó bảo đảm
  (`- Artifact:`); `tools/check-sdlc.sh` chặn khi thiếu, khi loại không thuộc `provides` của stage,
  khi khai nhiều dòng, và khi một loại `provides` của stage không capability nào trỏ tới.
- **Frontmatter: mục danh sách bỏ khoảng trắng cuối dòng.** `fm_list` (`tools/lib/md.sh`) cắt khoảng
  trắng thừa sau mỗi mục, nên `  - delivery  ` không còn lệch tên với `delivery` ở các checker so tên loại.
- **`check-sdlc.sh` chặn YAML ngoài tập con.** `yaml_kiem` (`tools/lib/md.sh`) báo từng dòng sai kèm
  file + số dòng (tab, `k:v`, thụt sâu, khối `|`/`>`, `{…}`, danh sách `[a, b]`) trên `workflow.yaml`,
  phase, utility command, file stage, profile — trước đây dòng lạ bị đọc thành rỗng, lỗi lộ ở chỗ khác.
- **Invariant chặt hơn.** Mọi invariant nêu ít nhất một ca test chặn (trước đây INV-001…006 chỉ trỏ
  file); `Rule:` của capability và invariant không còn cú pháp engine (máy chặn backtick, mã `REQ-`/
  `DEC-`…), cách engine hiện thực chuyển sang dòng `- Engine:`. Ba bảng của `check-sdlc.sh` chỉ còn một
  ảnh chụp (`docs/interface-sdlc.md` § 6), có test so với output.
- **Capability out-of-scope.** Khoá `out_of_scope:` của `workflow.yaml` khai capability engine quyết không
  làm kèm lý do (e2e, kiểm tải, triển khai, quan sát production); `check-sdlc.sh` in chúng ở khối "Không
  làm" thay vì roadmap. Trạng thái stage không đổi.
- **Checker nhanh hơn: nhớ `git rev-parse` và quy ước hiệu lực.** `git_top` / `git_common` (`tools/lib/md.sh`)
  nhớ theo thư mục trong biến shell; `nho_san` hâm sẵn ở shell chính của mỗi checker và `aw task`, nên các
  `$(…)` sau dùng lại. Một lần `aw check review` trên fixture: 183 → 68 lần gọi git, 2,3 → 1,4 giây.
  `check-sdlc.sh` tra thứ tự stage trong shell thay vì một `awk` mỗi lần.
- **Test:** helper `ky_vong_ly_do` chạy checker một lần cho cặp "mã thoát + lý do" (24 cặp đã chuyển);
  tách `22-sdlc-stage-files` → thêm `23-sdlc-syntax`, `25-sdlc-capabilities`; tách `20-sdlc-conformance` → thêm
  `24-sdlc-stage-status`.
- **Luật checker mới phải gắn `# giữ: CAP-…/INV-…` (bước A, đợt 2).** `tools/unclassified-rules.txt` đếm số chỗ
  luật chưa gắn id của từng `tools/check-*.sh` và `tools/task.sh` (223 chỗ lúc bắt đầu) — gọi `loi` / `loi_truoc` /
  `canh_bao`, dòng in `[LỖI]` / `[CẢNH BÁO]`, `TỪ CHỐI:` / `DỪNG:` / `CẢNH BÁO:`; mỗi `# giữ:` phủ đúng một chỗ
  ngay dưới; `check-sdlc.sh` chặn khi vượt (luật mới không id) và khi thấp hơn mà chưa hạ — danh sách chỉ
  giảm. `sh tools/check-sdlc.sh --dem-luat` in số đúng.
- **Test nhanh hơn:** thêm 14 cặp "mã thoát + lý do" chạy checker một lần (`ky_vong_ly_do`, kể cả mẫu có
  escape); `luon_co` của `check-sdlc.sh` tra chuỗi tính sẵn. Bộ test ~3 phút 45 giây (1760 ca).
- **Profile theo job type trong interface SDLC (`sdlc/profiles/<job-type>.md`).** Một file cho mỗi
  job type (`feature`, `bugfix`, `refactor`, `perf`, `chore`) khai stage nào có thể không chạy
  (`skippable`: design với bugfix/refactor nhỏ, deploy với mọi loại), stage nào luôn bỏ (`skipped`:
  design với chore), loại artifact thêm (`reproduction-evidence` của bugfix, `performance-evidence`
  của perf) và invariant riêng của loại. Vì sao: interface trước đây chỉ mô tả luồng `feature` đầy
  đủ — stage implement `requires: design` vô điều kiện dù chore không có design, `repro.md`/`perf.md`
  không thuộc loại artifact nào, luật riêng của từng loại không có chỗ khai.
- **Năm invariant mới `INV-007`…`INV-011`** (`sdlc/invariants.md`): bugfix — test tái hiện đỏ trên
  code chưa sửa; refactor/perf — REQ không thêm hành vi, test cũ không bị xoá và mọi chỗ sửa được
  khai; perf — số đo trước/sau do máy ghi; chore — không đụng `production_code`, dependency phải khai,
  không nâng major. Mỗi cái trỏ tới checker có thật và **tên ca test cụ thể**: `Tested by:` nay nhận
  tên ca trong ngoặc kép sau file, checker kiểm ca đó có trong file.
- **`tools/check-sdlc.sh` kiểm profile:** tập profile phải trùng tập job type engine nhận
  (`LOAI_HOP_LE`, nguồn `check-intake.sh` dùng); stage bỏ được phải khớp hành vi thật của engine
  (deploy ⇔ `06-ship` có `required: false`; design ⇔ `kc_bo_design`, checker gọi thẳng hàm đó); stage
  khai `skippable: false` (plan, require, implement, verify) không được bỏ; artifact thêm phải được một
  phase map ra file và do stage luôn chạy cung cấp; invariant phải có. Checker in ma trận job type ×
  stage và loại artifact có thể vắng theo từng profile. Test: `tools/tests/21-sdlc-profiles.sh` (part
  mới, tách khỏi `20-sdlc-conformance.sh` vì chậm).
- **`04-implement` khai thêm output `repro.md` (bugfix) và `perf.md` (perf)** — hai file `aw check
  repro` / `aw check perf` vốn đã ghi trong phase này nhưng frontmatter chưa liệt kê. **Ai bị ảnh
  hưởng:** dòng "Writes" của lệnh `/aw-implement` adapter sinh ra có thêm hai file đó; luật và hành vi
  của `aw` không đổi. Người sửa engine: thêm job type mới thì thêm profile (`AGENTS.md` § Change
  together).
- **Hai loại artifact mới của stage `implement`: `task-evidence` và `security-evidence`.** Phase
  `04-implement` map chúng ra `task-results.md` (`aw task done`) và `security-results.md` (`aw check
  implement`); stage `verify` khai `requires` cả hai. Vì sao: review vốn chặn khi thiếu hai file này với
  mọi job type, nhưng interface không biết verify cần bằng chứng từng task và bằng chứng quét bảo mật.
  **Ai bị ảnh hưởng:** không ai — chỉ đổi mô tả interface, lệnh adapter sinh ra giữ nguyên.
- **Stage mới `breakdown` (lập task) tách khỏi `implement` (viết code).** Interface có 8 stage; phase
  `03-plan` nay `implements: breakdown`, mỗi stage tối đa một phase. `breakdown` provides `task-plan`,
  giữ INV-001, INV-002 và capability `CAP-breakdown-01` (trước là `CAP-implement-01`, cùng nội dung);
  `implement` thêm `requires: task-plan`, giữ INV-003, `CAP-implement-02`, `-03`. File stage đánh số lại
  (`03-breakdown` … `07-operate`). Vì sao: phụ thuộc "code theo kế hoạch đã duyệt" trước đây bị giấu
  trong một stage, và `check-sdlc.sh` không bắt được việc đổi chỗ phase `plan` ↔ `implement` trong
  `workflow.yaml` — giờ chặn. **Ai bị ảnh hưởng:** người sửa engine (gắn capability của phase `03-plan`
  vào `CAP-breakdown-*`); người dùng `aw` không thấy gì khác.
- **Test `20-sdlc-conformance.sh` tách đôi** vì chậm: nhóm điều kiện ra, file stage, capability, invariant
  sang part mới `tools/tests/22-sdlc-stage-files.sh`.
- **Repo engine: thay đổi ghi vào mảnh `changes/<tên-nhánh>.md`, không sửa `CHANGELOG.md` nữa.**
  Trước đây PR nào cũng chèn vào cùng một chỗ dưới `## [Chưa phát hành]`, nên hai PR mở song song
  gần như luôn conflict ở `CHANGELOG.md` (13 lần trong lịch sử merge, file kế tiếp chỉ 3). Mỗi PR
  giờ thêm một file riêng; `tools/prepare-release.sh` gom các mảnh vào `## [<version>]` (gộp theo
  mục) rồi xoá, và vẫn gom cả nội dung `## [Chưa phát hành]` còn sót từ PR mở trước thay đổi này.
  `tools/check-release.sh` (workflow `kiem-tra`) chặn mảnh sai dạng ngay ở PR. Dạng mảnh:
  `changes/README.md`. Người dùng `aw` không bị ảnh hưởng.
- **`AGENTS.md`: merge `origin/main` mới nhất và chạy lại test trước mỗi lần push PR; sau khi một PR
  được merge, kiểm các PR còn mở có conflict không** — conflict được phát hiện và giải khi còn nhỏ.
- **Việc còn làm của engine chỉ còn ở roadmap Superpowers; bỏ `docs/viec-can-lam.md`.**
  `docs/superpowers/2026-10-22-roadmap-cai-thien.md` thành danh sách việc duy nhất: thêm cột trạng thái
  (SP1–SP8, SP11, SP12 đã xong qua #79; SP9 còn phần chạy thật), § Cách dùng (thêm, xong, bỏ một dự án
  con), đợt 5 và dự án con mới chuyển từ `viec-can-lam.md` — SP13 checker LLM cho spec, SP14 test tái hiện
  xanh sau khi sửa, SP15 `out_of_scope` cho capability engine không định làm, SP16 `CAP-operate-02`,
  SP17 không đổi assertion, SP18 glob bước 2, SP19 bước A đợt 2 — cùng mục việc nhỏ (tốc độ test) và
  § Không làm có lý do (tách version interface, refactor "không thêm hành vi" mức code, đổi tên
  phase/stage, adapter thứ ba). `AGENTS.md`, `README.md`, `docs/kien-truc.md`, `docs/interface-sdlc.md`
  trỏ tới roadmap. Không đổi hành vi `aw`.
- **Interface đi trước implementation (`AGENTS.md`).** Mọi thay đổi engine nêu `CAP-…` / `INV-…` nó
  phục vụ; không id nào khớp thì sửa interface trong cùng PR. Mô tả PR có dòng "Interface: …" (quy ước,
  máy chưa kiểm). Hạ chuẩn interface (bỏ / nới capability hay invariant) ghi id + lý do dưới `### Bỏ` /
  `### Thay đổi` của mảnh changelog. Lý do từng quyết định: `docs/kien-truc.md` § Interface SDLC.
- `tools/check-sdlc.sh` kiểm thêm: dạng capability (heading, id trùng, `Rule`, `Judged by`), phase nhận
  id có thật của đúng stage, utility command không khai `capabilities`, note khớp trạng thái suy ra.
  Test: `tools/tests/20-sdlc-conformance.sh`.
- **Interface SDLC trong repo engine (`sdlc/`).** Bảy stage có đặc tả (`plan`, `require`, `design`,
  `implement`, `verify`, `deploy`, `operate` — `sdlc/stages/`) và các `invariant` xuyên stage
  (`sdlc/invariants.md`, mỗi luật trỏ tới checker + test có thật). Engine là một implementation: mỗi
  phase khai `implements:` stage nó làm và `provides:` loại artifact → file; khối `sdlc:` của
  `workflow.yaml` khai stage engine chỉ làm một phần (`plan`, `verify`, `deploy`: `partial`) hay không
  làm (`operate`: `gap`), kèm lý do. Vì sao: chỗ engine không làm (deploy, vận hành) trước đây không
  được ghi ở đâu; giờ không khai thì máy chặn.
- **`tools/check-sdlc.sh`** kiểm cấu trúc lời khai đó (stage có phase hay khai `gap`, `provides` phủ
  stage, `exit` khớp `exit_machine`/`exit_human`, thứ tự, `requires`, invariant, utility command không
  khai `implements`). Chỉ kiểm cấu trúc, không kiểm chất lượng. Không phải lệnh `aw check`: chạy trong
  `sh tools/run-tests.sh` (`tools/tests/20-sdlc-conformance.sh`). **Ai bị ảnh hưởng:** người sửa engine —
  thêm hay đổi phase thì khai `implements`/`provides` (`AGENTS.md` § Change together). Người dùng `aw`
  không thấy gì khác: lệnh adapter sinh ra giữ nguyên; `terms.md` (agent đọc) có thêm ba thuật ngữ
  `stage`, `stage status`, `invariant`.
- Không gắn hàng loạt ~200 chỗ luật cũ. Id có sẵn vẫn qua máy dù gắn nhầm capability; chỉ gắn khi đã đọc đúng chỗ luật đó.
- **Hai ca kiểm hai thông báo chạy checker một lần.** `ky_vong_hai_ly_do` nhận hai mẫu grep. Mục lục lệch (thiếu mục mới và thừa link cũ) và cả `test-results.md` lẫn `security-results.md` lỗi thời không còn chạy checker thêm lần. Người dùng `aw` không thấy gì.
- **Test hết chạy checker hai lần cho một lý do.** Cặp "…đúng lý do" còn escape chuyển sang
  `ky_vong_ly_do` (một lần chạy, vừa mã thoát vừa câu thông báo). Thêm một ca: `check-design` vẫn
  chặn khi spec khai `Design: skip`. Hai ca kiểm hai thông báo thì xem mục ngay phía trên.
- **`check-sdlc.sh` tra một lần.** Capability, invariant, phase theo stage, stage `skippable: false`
  và requires của stage không còn gọi awk mỗi lần dò. Output không đổi; mỗi lần chạy khoảng 1,6 giây
  (trước khoảng 2 giây). Người dùng `aw` không thấy gì.

## [2026.10.30]

### Thay đổi
- **Artifact của việc chuyển sang `docs/sdlc/<tên-branch>/` và được commit vào branch của việc.**
  Trước đây artifact nằm ở `.agent-workflow/<tên-branch>/`, bị exclude và chỉ ở máy: mất máy hay
  gỡ worktree là mất (chỉ còn bản trong `archive/`), sang máy khác hay phiên mới cũng không có. Giờ:
  - Mỗi lần `aw check <phase>` ĐẠT, máy commit **riêng** thư mục việc với message
    `chore(sdlc): <tên-branch> <phase>`. Lệnh `aw approvals tick` và `aw rename` cũng commit.
    Code bạn đã stage không bị cuốn theo. Commit chạy với `--no-verify`, vì hook của repo viết cho
    code và có thể định dạng lại artifact, làm mất approval hash.
  - `aw ship create` gỡ thư mục việc khỏi branch bằng một commit trước khi push. Nhờ vậy artifact
    **không bao giờ vào nhánh đích** (develop/uat/main…) và PR chỉ có code. File vẫn ở máy, và từ
    đó `aw check` không commit lại. Nếu MR vẫn mang file trong `docs/sdlc/` (ví dụ thư mục của
    việc khác khi branch xếp chồng), lệnh trả `CHƯA ĐỦ ĐIỀU KIỆN` và nêu file.
  - `docs/sdlc/` được thêm vào `.git/info/exclude`, nên `git add -A` không kéo artifact mới vào
    commit code. Commit artifact không làm đổi `Tree`, nên kết quả máy ghi không thành `stale` và
    approval không mất.
  - `aw conventions check` báo lỗi nếu `knowledge_adr_dir` / `knowledge_rules_dir` nằm trong
    `docs/sdlc/`, vì thư mục đó bị gỡ trước MR.

  **Ai bị ảnh hưởng, cần làm gì:**
  - Việc đang làm dở (đã ghim engine cũ trong `intake.md`) chạy tiếp như cũ ở
    `.agent-workflow/<tên-branch>/`, chỉ ở máy. `aw feature` vẫn in đường dẫn cũ cho việc đó.
  - Repo đã init: chạy lại `aw init` (hoặc `aw adapter build`) để thêm `/docs/sdlc/` vào exclude.
    Lần commit artifact đầu tiên cũng tự thêm; `aw doctor` báo nếu còn thiếu.
  - Tạo MR bằng `aw ship create`. Tự tạo PR trên web thì artifact nằm trong diff.
  - Team squash-merge hoặc xoá branch sau khi merge thì lịch sử artifact mất theo branch. Bản ở
    `archive/` khi gỡ worktree vẫn còn.
  - `.agent-workflow/` vẫn là thư mục cục bộ của engine (`.engine/`, dấu build adapter, mốc của
    `aw guard`), bị exclude như trước.
- **Mã định danh trong artifact theo một dạng chung: `<TIỀN TỐ>-NNN`, tiền tố ba chữ tiếng Anh, đúng
  3 chữ số.** Trước đây mỗi loại mã một kiểu: chữ Việt viết tắt (`YC`, `PH`), một chữ (`D`, `T`), khi
  2 khi 3 chữ số. Giờ:

  | Trước | Giờ | Ở đâu |
  |---|---|---|
  | `YC-001` | `REQ-001` | `spec.md`, `open-questions.md`, tag `covers:` trong test |
  | `D-01` | `DEC-001` | `tdd.md` (mục `## REQ mapping` thay cho `## YC mapping`) |
  | `PH-01` | `FND-001` | `design-findings.md` |
  | `T-01` | `TSK-001` | `plan.md`, commit message `TSK-NNN: …` |
  | `RF-001` | `RFR-001` | `refactor-requests.md` |

  Anchor đổi theo (`#req-001`, `#dec-001`, `#tsk-001`). Tham số lệnh dùng mã mới: `aw task reopen
  <dir> REQ-001|DEC-001`, `aw adr promote <dir> DEC-001`, `aw rule promote <dir> REQ-001`, `aw
  approvals tick <dir> DEC-001 <hash>`, `/aw-clarify REQ-001`. `BR-<MIỀN>-NNN` và `ADR-NNNN` giữ
  nguyên. Quy tắc ghi ở `docs/thuat-ngu.md` § Mã định danh, lý do ở `docs/kien-truc.md`.

  **Ai bị ảnh hưởng:** engine mới **không đọc mã cũ**. Job đang chạy ghim version engine trong
  `intake.md` nên chạy hết bằng engine cũ, không phải làm gì. Job mới dùng mã mới. Test trong target
  repo còn tag `covers: YC-…` từ job cũ thì không ảnh hưởng job mới (chỉ tag của job đang chạy được
  đối chiếu); tag `covers: BR-…` giữ nguyên.

### Nội bộ
- **Test hồi quy chạy song song: nhanh khoảng 3 lần trên máy 4 CPU (8,5 → 2,8 phút; máy chậm 13 → 4,5 phút), đủ 1398 ca như cũ.** `tools/run-tests.sh`
  giờ chia việc cho các phần trong `tools/tests/NN-<tên>.sh` (helper + fixture ở `tools/tests/lib.sh`), chạy
  cùng lúc theo số CPU (`AW_TEST_JOBS` để đổi), rồi cộng tổng. Danh sách ca và kết quả trùng khớp bản cũ;
  phần dừng giữa chừng tính là hỏng. Chạy một phần: `sh tools/run-tests.sh review` hoặc
  `sh tools/tests/05-review-quality.sh`. CI (`kiem-tra`, `release`) không đổi lệnh. Người phát triển engine:
  thêm ca vào phần cùng chủ đề, không thêm vào `tools/run-tests.sh`.
- **`tools/run-tests.sh` in thời gian từng phần và cảnh báo phần quá chậm**, để bộ test song song không
  chậm dần khi ca mới dồn vào một phần. Cuối output có dòng `Thời gian từng phần` (chậm nhất trước); phần
  ≥ 30 giây và gấp hơn 2 lần trung bình các phần còn lại có dòng `CẢNH BÁO … nên tách`. Chỉ cảnh báo,
  kết quả không đổi. Người phát triển engine: thấy cảnh báo do thay đổi của mình thì tách phần đó trong
  cùng PR (`AGENTS.md` § Verify). Thêm biến `AW_TEST_SLOW_MIN` (ngưỡng giây) và `AW_TEST_DIR` (thư mục
  phần, dùng cho test của chính runner); thư mục không có phần nào giờ trả `SAI THAM SỐ`.
  Cảnh báo bắt ngay hai phần đang lệch trên `main`, nên tách luôn trong thay đổi này:
  `02-spec-design-plan.sh` → `02-spec.sh` + `02-design-plan.sh`; `07-ship-rules-uses.sh` →
  `07-ship-rules.sh` + `07-uses-pending-based-on.sh`. Danh sách ca của từng phần cũ trùng khớp từng dòng
  với hai phần mới ghép lại.
- **Sửa test đỏ trên `main` và CI từ khi artifact vào git:** 9 ca của `tools/tests/14-ship-ready.sh` hỏng trên
  máy chưa đặt git identity (gồm runner CI), vì engine tự commit artifact. `tools/tests/lib.sh` giờ đặt identity
  giả qua `GIT_AUTHOR_*`/`GIT_COMMITTER_*` cho mọi phần test.

## [2026.10.29]

### Thay đổi
- **Agent dùng thuật ngữ tiếng Anh gốc, không tự dịch — trong chat và trong artifact.** Trước đây
  agent, tài liệu và output `aw` dùng từ dịch như "điểm mù", "cổng người", "lỗi thời", "kiểm chéo".
  Những từ này không có trong tên field, file hay output, nên người phải tự dịch ngược. Giờ:
  - Danh sách chuẩn ở `workflow/rules/terms.md` (`open question`, `human gate`, `stale`,
    `cross-check`, `job`, `target repo`…). `general.md` §5 bắt agent dùng đúng các từ đó; câu quanh
    vẫn là tiếng Việt.
  - `docs/thuat-ngu.md` viết lại theo thuật ngữ gốc, tên cũ ghi trong ngoặc để tra.
  - Output `aw`, README, `docs/huong-dan.md`, `docs/kien-truc.md`, template và mô tả lệnh `/aw-*`
    dùng thuật ngữ mới. Nhãn `Kết quả` (`ĐẠT`, `DỪNG`, `KẸT`…) và `ĐANG Ở CHECKOUT CHÍNH` giữ nguyên.
  - Neo link đổi theo heading mới, vd `huong-dan.md#2-cài-đặt-và-cấu-hình-target-repo`,
    `adapters/*/README.md#approval-guard`. Ai lưu link cũ thì cập nhật.
- **Artifact còn từ dịch cũ: `aw check implement` cảnh báo, `aw check review` chặn.** Danh sách từ
  là cột `Not` của `terms.md`. Không kiểm `intake.md`, `refactor-requests.md`, `*-results.md` và
  dòng trích `>`, vì đó là nguyên văn lời người hoặc do máy ghi. Job đã ghim engine cũ không bị ảnh
  hưởng. Job mới gặp chặn thì sửa chữ theo gợi ý trong dòng báo.

## [2026.10.28]

### Thêm
- **Bugfix/refactor nhỏ bỏ được phase design — `Design: skip` trong `spec.md`.** Trước đây chỉ chore
  bỏ design; bugfix sửa một dòng vẫn phải viết `tdd.md` đủ 8 mục (gần như toàn "Not applicable"), mở
  phiên mới và chạy checker LLM. Giờ `/aw-spec` đề xuất `- **Design:** \`required | skip\``, người
  duyệt cùng spec; `skip` thì đi như chore: `/aw-plan` làm thẳng từ spec đã duyệt, chặn điểm mù
  `blocking` ở plan, task không có `Based on: D-xx`. Test tái hiện của bugfix vẫn bắt buộc.
- `aw check spec` chặn `Design` khác `required | skip`, `skip` ở feature/perf hoặc khi `Risk: high`,
  và chore ghi `required`. Spec cũ không có dòng `Design` = `required`, chạy như trước.
- `aw approval plan` với `Design: skip` hỏi duyệt spec và nêu `Design: skip` là điểm cần đọc kỹ;
  `aw check design`, `aw approval design` báo "đi thẳng /aw-plan"; `aw pending`, `aw ready` tính phase
  kế tiếp theo.
- **Tài liệu:** `docs/thuat-ngu.md` — bảng thuật ngữ (YC, D-xx, PH, T, BR, ADR, điểm mù, mức chặn,
  Mode 1/2, base, worktree…); `docs/huong-dan.md` §1.1 thêm bảng phân phần việc của "Người" theo vai
  trong team (người cài, dev, người duyệt spec, PO/BA, người duyệt thiết kế, người rà bảo mật,
  reviewer MR).
- **Artifact phải có mục lục, tham chiếu phải là link tới mục — luật cứng.** Mọi artifact agent viết
  (`intake.md`, `spec.md`, `open-questions.md`, `tdd.md`, `design-findings.md`, `plan.md`,
  `review.md`, `merge-request.md`) có heading `##`/`###` thì phải có `## Contents` đứng trước heading
  đầu tiên, liệt kê đúng mọi heading `##`/`###` theo thứ tự. Tham chiếu sang artifact khác viết thành
  link tới mục (`[spec.md § YC-001](spec.md#yc-001--đăng-nhập)`), không còn chữ trơn
  `spec.md § YC-001` hay link chỉ tới file. Checker của phase chặn trên artifact đầu ra của nó;
  `aw check review` chặn trên mọi artifact (link sang file khác gãy khi file đó đổi heading).
- **`aw toc <thư-mục-feature> [artifact…]`** — máy sinh lại `## Contents` theo heading, mở rộng anchor
  rút gọn (`#yc-001`, `#d-01`, `#t-02`) thành anchor đầy đủ của heading, rồi in link còn sai. Anchor
  tính như GitHub / VS Code. Chỉ ghi file khi nội dung đổi — chạy lại không làm artifact phía sau lỗi
  thời. Mẫu artifact có sẵn mục `## Contents`.

### Thay đổi
- **`/aw-clarify` chốt hết rồi mới ghi, một lần.** Trước đây mỗi mục chốt xong là agent hiện dòng
  trước → sau, hỏi "ghi như vậy được không?", ghi file, chạy checker, rồi mới sang mục sau — mỗi mục
  tốn hai lượt. Giờ agent hỏi lần lượt hết hàng đợi, chưa ghi gì; xong (hoặc khi bạn nói `dừng`)
  thì hiện **một** bản xem trước gom theo file, mỗi thay đổi gắn id mục (`PH-38`, `YC-115`…), hỏi
  một lần, ghi tất cả, chạy `aw task reopen` / `aw check spec` / `aw check design` một lần. Muốn ghi
  giữa chừng: nói `ghi luôn`. Nhiều mục cùng sửa một đoạn → một before → after chung; D-xx mới
  đánh số liền nhau trong đợt.
- **`/aw-design` Mode 2 cũng gom: phác hết D-xx rồi mới xác nhận, một lần.** Agent hỏi lần lượt từng
  điểm cần quyết, chưa ghi gì; xong hết thì hiện mọi D-xx sắp ghi trong một bản xem trước, hỏi một
  lần, ghi tất cả vào `tdd.md`. Nói `dừng` giữa chừng → ghi các D đã chốt rồi dừng, chạy lại
  `/aw-design` để làm tiếp. Việc tick ô duyệt D-xx không đổi (bạn tự tick trong file).
- **Agent nói với bạn bằng thuật ngữ tiếng Anh gốc, không tự dịch.** Trước đây agent (và
  `docs/thuat-ngu.md`) dùng từ dịch như "điểm mù", "cổng người", "lỗi thời", "kiểm chéo" — khó đối chiếu
  với tên field, file và output `aw`. Giờ có danh sách chuẩn `workflow/rules/terms.md` (`open question`,
  `human gate`, `stale`, `cross-check`, `job`, `target repo`…); `general.md` §5 bắt agent dùng đúng các
  từ đó, câu quanh vẫn tiếng Việt. `docs/thuat-ngu.md` viết lại theo thuật ngữ gốc, ghi tên cũ trong
  ngoặc để tra. Luật này không có checker (lời nói không kiểm được). Có hiệu lực với job mới hoặc khi
  nâng engine; không cần làm gì.
- **YC có nguồn phải có câu trích nguyên văn — `- Quote:` + các dòng `> …` ngay dưới `Source:`.** Trước
  đây phase spec bảo agent trích câu nguồn nhưng mẫu không có chỗ ghi, nên người duyệt phải tự mở
  nguồn để so YC với câu gốc. Giờ `aw check spec` chặn YC `[CONFLUENCE]` `[JIRA]` `[FILE]` thiếu
  `Quote`; với `[FILE]` (kể cả lời người trong `intake.md`, câu trả lời trong `open-questions.md`)
  chặn câu trích không có trong file nguồn — khoảng trắng, xuống dòng không tính, còn lại phải đúng
  từng chữ. File nguồn đổi sau khi viết spec thì `aw check design` (không có design: `aw check plan`)
  chỉ cảnh báo. `/aw-clarify` đổi nhãn nguồn sang câu trả lời thì đổi cả `Quote`.
  **Ai bị ảnh hưởng:** việc đang làm dở chuyển sang engine mới mà spec chưa có `Quote` bị chặn ở
  spec và mọi phase sau — thêm câu trích cho từng YC có nguồn rồi người duyệt lại spec. Việc đã ghim
  engine cũ không bị ảnh hưởng.
- Nhãn nguồn trả lời điểm mù đổi thành link: `[FILE] [open-questions.md § YC-NNN](open-questions.md#yc-nnn)`;
  `[HUMAN]` trích dẫn là `[FILE] [intake.md § Input](intake.md#input)`; `Design:` / `On assumption:` của
  task và `Location:` của phát hiện checker LLM cũng là link. Việc đã ghim engine cũ không bị ảnh hưởng.
- `tools/run-tests.sh` mặc định in gọn: chỉ ca hỏng (kèm tên nhóm), dòng tổng và khối `Kết quả` —
  output khi đạt hết từ ~2.200 dòng (~97 KB) còn vài dòng, đỡ tốn ngữ cảnh của agent.
  `AW_TEST_VERBOSE=1` in từng ca như trước. Bịt output lọt ra (khối `Kết quả` của `based-on.sh`,
  `git commit` rỗng).

### Sửa
- `tools/prepare-release.sh` cập nhật cả link tải wrapper trong `docs/huong-dan.md` (trước đây chỉ
  README, link trong hướng dẫn bị bỏ lại ở `2026.10.23`).
- `docs/kien-truc.md`: `ket-qua-*` → `*-results.md`. `docs/viec-can-lam.md` bỏ lịch sử đã làm và
  tên trường, lệnh cũ (`Mức chặn`, `/open-questions`); chỉ giữ việc còn lại.

### Nội bộ
- `tools/lib/quote.sh`: so câu trích và đọc đường dẫn nguồn `[FILE]` — một chỗ cho `check-spec.sh`
  và `aw rule promote` (trước đây `rule.sh` tự đọc đường dẫn). `check-spec.sh --entry` cho phase sau
  chạy lại spec.
- **Mọi thay đổi trong repo engine phải kèm tài liệu cho người đọc** (`AGENTS.md` § Human docs): một
  mục tóm tắt trong `CHANGELOG.md` (làm gì, vì sao, ảnh hưởng ai) và cập nhật tài liệu sống (README,
  `docs/huong-dan.md`, `docs/kien-truc.md`, `docs/thuat-ngu.md`) — kể cả thay đổi nội bộ, refactor,
  test. Thay đổi người dùng `aw` không thấy ghi ở mục `Nội bộ`.

## [2026.10.27]

### Thêm
- **`aw self-update [<YYYY.M.N>]`: wrapper tự nâng.** Tải `aw` của bản phát hành (mặc định: version
  engine của repo đang đứng), kiểm sha256 theo `SHA256SUMS`, kiểm đúng `AW_WRAPPER_VERSION`, rồi thay
  chính file wrapper (ghi tạm cạnh nó rồi `mv`). Checksum sai hay thiếu dòng `aw` → không cài.
  `aw upgrade` và `aw version` nhắc chạy lệnh này khi wrapper cũ hơn engine (vd wrapper 2026.10.25
  chưa biết `aw approvals`). Wrapper từ 2026.10.26 trở về trước chưa có lệnh này: tải tay một lần.

## [2026.10.26]

### Thêm
- **Lệnh tiện ích `/aw-approvals [--global]`: duyệt tập trung, không phải mở từng artifact để
  tick.** `aw approvals` liệt kê mọi ô "Approved by human" chưa đạt (spec, từng D-xx: chưa tick, đổi
  sau khi duyệt, mở lại, thiếu ô) của worktree hiện tại — `--global`: mọi worktree, chạy được cả ở
  checkout chính — mỗi mục kèm `đường-dẫn-tuyệt-đối:dòng` mở thẳng tới ô duyệt. Agent đi từng mục, in
  phần cần duyệt do máy dựng, hỏi Duyệt / Chưa duyệt / Bỏ qua / Dừng; chọn Duyệt thì agent chạy
  `aw approvals tick <dir> <spec|D-NN> <hash>` — máy chỉ tick khi nội dung còn đúng bản người vừa
  thấy, ghi `journal/approvals.tsv`. **Nới luật "agent không tự duyệt"**: đây là lối duy nhất agent
  được tick, chỉ sau khi người chọn Duyệt đúng mục đó; tick bằng sửa file vẫn bị `aw guard` bỏ. Nên
  thêm luật hỏi quyền `Bash(aw approvals tick:*)` (adapters/claude-code/README.md). Cần wrapper `aw`
  mới (lệnh `approvals`). Lệnh tiện ích khai được `feature_dir: none` (không chạy `aw feature`).
- **Lệnh tiện ích `/aw-refactor [yêu-cầu]`: review, phản biện rồi ghi nhận yêu cầu refactor, chưa
  làm.** Mỗi lần gọi một yêu cầu. Agent đọc code để kiểm (rõ chưa, có thật là refactor, tiền đề khớp
  code, test bảo vệ trên base, phạm vi/rủi ro, nên tách, trùng/mâu thuẫn RF trước, đụng file việc hiện
  tại), phản biện một vòng kèm `file:dòng` và bản tóm tắt; người quyết cuối. Ghi vào
  `refactor-requests.md` của việc: `RF-NNN` có `Summary` (người duyệt), `Request` (nguyên văn),
  `Location`, `Review` (phản biện + trả lời), `Status`. Không sửa code, intake, spec hay plan. Xong,
  agent chỉ in lệnh: việc `refactor` đang làm → `/aw-intake <dir>/refactor-requests.md` rồi
  `/aw-spec`; loại khác → việc refactor riêng (`/aw-intake` ở checkout chính, chép file sang việc mới
  rồi intake thêm để spec trích `§ RF-NNN`). Chọn "để sau" thì gọi lại `/aw-refactor` không kèm
  yêu cầu để quay về bước chọn đường; RF đã chọn đường thành `routed: …`. Mẫu:
  `templates/refactor-requests.md`.
- **`tdd.md` có thêm hai mục bắt buộc: `## Target structure` và `## Rollout & rollback`.** Target
  structure ghi cấu trúc module/thành phần trước → sau (kèm sơ đồ Mermaid) — chỗ mà refactor/perf
  cần nhất nhưng mẫu cũ không có. Rollout & rollback ghi thứ tự triển khai, flag, di trú, chạy song
  song, cách quay lui và bước nào không quay lui được. Không áp dụng thì ghi
  `Not applicable: <lý do>`; `aw check design` chặn khi thiếu mục hoặc để trống. Checker LLM coi
  bước triển khai không quay lui được mà không có D-xx là quyết định ngầm. Việc đang chạy dở không
  ảnh hưởng (chạy hết bằng version ghi trong `intake.md`).
- **`TASK_FULL_TEST` trong `config.sh`.** `1` = `aw task done` chạy thêm `TEST_CMD` sau khi Verify xanh;
  đỏ tính như Verify đỏ (giữ `[~]`, tăng đỏ liên tiếp), `task-results.md` ghi thêm dòng `Toàn bộ test`.
  Task sau làm hỏng task trước lộ ra ngay ở task gây ra, không đợi tới `aw check implement`. Mặc định tắt.

### Thay đổi
- **`/aw-design` Mode 2 hỏi dẫn người phác D-xx thay vì dừng trơn.** Trước đây `Risk: high` mà chưa
  có D `Author: human` thì agent chỉ dừng và đưa mẫu, người phải tự nghĩ ra các điểm cần quyết từ
  trang trắng. Giờ agent khảo sát code, liệt kê các điểm cần quyết dưới dạng câu hỏi kèm dữ kiện
  (số chỗ gọi, dữ liệu phải di trú, giao diện ngoài, ADR liên quan), rồi hỏi từng điểm bằng câu mở:
  có những cách nào, được/mất gì, chọn gì và vì sao, chỗ nào khó đảo ngược. D-xx ghi đúng lời người
  (`Author: human`). Agent vẫn **không** nêu, xếp hạng hay nghiêng về phương án nào; bị hỏi "nên
  chọn gì" thì chỉ gợi khía cạnh cần cân nhắc. Người muốn tự viết `tdd.md` thì agent dừng như cũ.
- **`/aw-implement` gọn lại.** Bước 1–7 và vòng lặp tự chạy gộp thành một mục `Loop` nói theo nhãn của
  `aw`. Bỏ mục `Common failures` và cột "Machine blocks when" (checker đã in đúng điều đó khi chặn), bỏ
  các luật lặp với `general.md`.
- **Mục `Unplanned` của phase nói rõ khi nào ghi rồi làm tiếp, khi nào ghi rồi dừng** (file ngoài
  phạm vi không tránh được, luật repo xung đột → làm tiếp; `DỪNG`/`KẸT`, việc ngoài plan, phải đổi
  `tdd.md`/`spec.md`/D-xx, test cũ sai, scan báo nhầm → dừng, báo người).
- **Quy ước commit theo task:** task lên `[x]` thì commit file của task đó theo đường dẫn (không
  `git add -A`), message `T-NN: <tiêu đề>` trừ khi luật repo quy định khác.
- **Nói rõ thời điểm nâng ADR / luật:** trong task hiện thực D `Promote: adr` / YC `Promote: BR-…`.

## [2026.10.25]

### Thêm
- **Đổi một YC đã có nguồn — `/aw-clarify YC-NNN`.** Trước đây chỉ điểm mù và phát hiện của checker
  LLM có đường chốt; YC agent đã gắn nguồn mà người không đồng ý thì phải sửa tay `spec.md`, và nhãn
  nguồn cũ vẫn nói đó là lời của Confluence/Jira. Giờ việc đổi được ghi thành điểm mù đã trả lời
  (`Assumption` = cách hiểu cũ, `Answer` = lời người nguyên văn, câu trả lời trước chuyển thành
  `Superseded answer:`), YC đổi nhãn sang `[FILE] open-questions.md § YC-NNN`, spec bỏ tick. Thêm/bỏ
  YC vẫn là đổi phạm vi: `[HUMAN]` trong `intake.md` rồi `/aw-spec`.
- **`aw task reopen <thư-mục-feature> <YC-NNN|D-NN>`** — đưa đúng các task `Covers`/`On assumption` YC
  đó (hay `Based on` D đó) về `[ ]`, task khác giữ nguyên. Dùng khi điểm mù được trả lời khác giả
  định, khi người đổi YC, và khi mở lại D-xx (thay cho việc agent tự grep `plan.md`).

### Thay đổi
- **`aw check spec` chặn nhãn `[FILE] open-questions.md § YC-NNN` trỏ vào mục không có** (hay mục của
  YC khác chưa `answered`): nhãn nói lời người là nguồn thì lời đó phải được ghi.
- `/aw-clarify` nhận tham số `[YC-NNN] [tên-feature]`.

## [2026.10.24]

### Thêm
- **`docs/huong-dan.md` — hướng dẫn dùng cho người:** cách quy trình hoạt động (vai agent/máy/người,
  bàn giao bằng file, ô duyệt, nhãn `Kết quả`, worktree), cài và cấu hình repo đích từng bước
  (`config.sh`, `conventions.md`, bootstrap, hook `aw guard`, skill/subagent), từng phase sinh artifact
  nào và artifact đó quyết định gì, khác biệt theo loại việc, kiến thức bền (ADR, `BR-`), xử lý khi bị
  chặn, tham chiếu lệnh. README trỏ tới.
- **`/aw-intake` hỏi bằng câu hỏi lựa chọn:** loại việc, tên, base, nguyên văn `[HUMAN]` gom vào một
  lượt hỏi (Claude Code: `AskUserQuestion`; Cursor: tool hỏi lựa chọn hoặc lựa chọn đánh số), mỗi câu
  có ô tự nhập cho yêu cầu khác. Base ★ của máy đứng đầu. Câu `Input` trích nguyên văn lời người ngay
  trong lựa chọn `Đúng nguyên văn`; muốn sửa thì gõ bản đúng vào ô tự nhập — không có lựa chọn "cần
  sửa" rỗng. Câu chỉ có một lựa chọn thật thì thêm `Dừng — chưa tạo gì`. Phase nào cũng khai được
  `choice_ui: true` (trước chỉ lệnh tiện ích).

## [2026.10.23]

Lệnh và luật agent đọc gọn lại (ngữ cảnh mỗi phase nhỏ hơn khoảng 20–32%) mà không bỏ chỉ thị nào;
prompt và mẫu hết nói ngược nhau; mỗi phase kết thúc bằng việc người cần làm và lệnh tiếp theo.

### Đổi
- **`design-findings.md` dùng trường tiếng Anh** như mọi artifact khác (`rules/general.md` § 5):
  `Mức` → `Severity: block | warn`, `Loại` → `Category`, `Vị trí` → `Location`, `Vấn đề` →
  `Problem`, `Xử lý: chưa | đã sửa | bác bỏ: <lý do>` → `Resolution: open | fixed | rejected: <lý do>`.
  Giá trị `Category` thành kebab-case (`hidden-decision`, `deviates-from-decision`…). Việc tạo
  trước đó vẫn đọc được trường cũ. Cách đọc nằm một chỗ: `tools/lib/findings.sh` (dùng chung cho
  `aw check design`, `aw approval`, `aw pending`); tên trường chỉ khớp ở đầu dòng.
- Mẫu `design-findings.md` liệt kê đủ 8 `Category` checker LLM dùng (trước thiếu `violates-repo-rule`,
  `violates-adr`).
- `/aw-implement`: bỏ "bước 0" thứ hai (`aw ready`) trùng số với Step 0 của lệnh.
- `/aw-clarify`: lối thảo luận chỉ còn một tên — "Chat about this" (đúng nhãn người thấy).
- Prompt spec / plan: placeholder `BR-<DOMAIN>-NNN`, `<domain>.md` như `/aw-bootstrap`.

- **Lệnh sinh ra gọn hơn** (mọi adapter): đầu file một dòng; Step 0 đặt tên thư mục feature là
  `<dir>` (thay `<thư-mục-feature>` lặp khắp file); "Phase contract" viết Reads/Writes mỗi thứ một
  dòng, mẫu gom một dòng `Templates`; "Read first" + quy tắc repo gộp thành một dòng
  `Before working`. Luật "không sửa dòng `Engine:`" và `aw journal add` chuyển về
  `rules/general.md` (§ 4, § 8) — trước lặp trong từng lệnh.
- **`/aw-implement` viết lại theo khung Goal → Steps → By work type → Forbidden → Common failures**
  (nhỏ hơn 35%): bỏ `Input`/`Output`/`Exit conditions` trùng hợp đồng do adapter dựng, bỏ bảng
  "Warning → Fix" — cách sửa nay nằm ngay trong cảnh báo của `aw check implement`.
- **Mọi phase theo cùng khung** (intake, spec, design, plan, review, ship): bỏ `Input`/`Output`/
  `Exit conditions` trùng hợp đồng do adapter dựng; điều checker hay chặn mà bước chưa nói gom vào
  `Common failures`. Lệnh sinh ra nhỏ hơn 16% tổng; ngữ cảnh mỗi phase nhỏ hơn khoảng 20–32%.
- `rules/general.md` và `rules/source-tracing.md` gọn lại (giữ số mục); danh sách "checker kiểm gì"
  trong `source-tracing.md` thay bằng các lỗi hay gặp.
- `/aw-clarify`: tên trường điểm mù đúng mẫu (`If wrong, redo`, trước còn ghi "Nếu giả định sai");
  bỏ các dòng Forbidden lặp lại bước.
- Cảnh báo "YC chưa có test" và "thay đổi ngoài phạm vi" ghi kèm cách sửa.
- **Tin nhắn kết thúc phase thống nhất:** mọi lệnh phase kết thúc bằng `Kết quả:` · `Cần bạn:` ·
  `Tiếp theo: /aw-…` (lệnh tiếp tính từ thứ tự phase trong manifest) — người thấy ngay việc của mình.
- Mẫu `review.md`: `## Conclusion` lên đầu, thêm `Summary` (1–3 câu cho người đọc).
- Mẫu artifact bỏ các dòng meta "Sinh bởi phase …"; `rules/general.md` § 6: agent xoá chú thích hướng
  dẫn của mẫu khi ghi artifact (trừ dấu duyệt), § 4: không sửa `based_on` và `*-results.md`.

### Bỏ
- Mục `## Carried-over warnings` trong mẫu `review.md`: không phase nào dặn, không checker nào đọc —
  cảnh báo còn sót đã bị `aw check review` chặn.

## [2026.10.22]

Skill, subagent của team gọi được theo phase (`uses_<phase>`, `aw uses`), không chỉ đọc như tài liệu.
Cần cài lại wrapper `aw`.

### Thêm
- **Skill, subagent của team gọi theo phase** — khoá mới `uses_<phase>` trong `conventions.md`
  (`spec design plan implement review`), mục `skill:<tên>` / `agent:<tên>`, vd
  `uses_implement: skill:go-senior agent:db-migrator`. Khác `rules_<phase>` (agent chỉ đọc file):
  agent **gọi** skill qua cơ chế của nó, nên tham số, dòng chèn lệnh shell, `allowed-tools`, `hooks`
  của skill có hiệu lực (Claude Code: Skill tool; Cursor không có tool gọi skill thì đọc file).
  Hướng dẫn: README, mục "Skill, subagent của team cho từng phase".
- Lệnh mới `aw uses <phase>` (mỗi dòng `<mục> <file>`); lệnh `/aw-spec` … `/aw-implement` và subagent
  `independent-reviewer` gọi nó đầu phase. Adapter có hook mới `ad_goi_uses`. Cần wrapper `aw` mới.
- Máy chặn (`aw uses`, `aw check` của phase, `aw conventions check`): mục sai dạng, tên của plugin
  (có `:`), file không có trong `.claude/` / `.cursor/` của repo hay chưa commit, skill khai
  `disable-model-invocation: true`, phase gõ nhầm (`uses_spek`).
- Review: `aw rules review` in thêm file định nghĩa của mọi `uses_*`; `review.md` phải kết luận
  từng file ở `## Repo rules`.

### Đổi
- Mẫu `conventions.md` có thêm khối `uses_*` (trống). Repo có sẵn: `aw conventions check` cảnh báo
  thiếu khoá — chép khối đó từ mẫu, hoặc để vậy (coi như trống).

## [2026.10.21]

Quy trình chỉ chạy khi người gõ lệnh. Tên script, khoá cấu hình, artifact và subagent đổi sang
tiếng Anh; luật không đổi.
Nội dung người đọc (output, nhãn `Kết quả`, mẫu artifact) vẫn tiếng Việt.

### Thêm
- **Kiểm chuẩn định dạng của agent** khi sinh adapter (`adapters/lib/format.sh`): mọi file
  `aw init` / `aw adapter build` / `aw worktree new --create` sinh cho Claude Code và Cursor được kiểm
  trước khi ghi — frontmatter YAML hợp lệ, khoá thuộc chuẩn của agent, `name` khớp tên file / thư mục,
  skill theo chuẩn Agent Skills (`description` ≤ 1024 ký tự), lệnh Cursor không có frontmatter. Sai thì
  nhãn mới `SAI CHUẨN <agent>`, file sai không vào chỗ. Mỗi adapter khai chuẩn riêng (`AD_LENH_FM`,
  `AD_LENH_KHOA`, `AD_AGENT_KHOA`, `AD_SKILL_KHOA`) trong `build.sh`.

### Đổi
- **Agent không tự kích hoạt quy trình.** Lệnh `/aw-*` (Claude Code) và skill `agent-workflow`
  (Claude Code, Cursor) mang `disable-model-invocation: true`: chỉ chạy khi người gõ lệnh, model
  không tự gọi; description của skill không còn nằm trong ngữ cảnh mọi phiên. Subagent
  (`independent-reviewer`, `<checker>-checker`) dặn chỉ được gọi khi lệnh `/aw-*` yêu cầu. Chạy
  `aw adapter build` để sinh lại.
- **Script của engine** (`tools/`, `tools/lib/`, `adapters/lib/`): `kiem-tra-<x>.sh` →
  `check-<phase>.sh`; `chay-thu.sh` → `run-tests.sh`; `chuan-bi-phat-hanh.sh` →
  `prepare-release.sh`; `kiem-tra-phat-hanh.sh` → `check-release.sh`; `dong-goi.sh` →
  `package.sh`; `khoi-tao.sh` → `init.sh`; `lib/ket-qua.sh` → `lib/result.sh`;
  `lib/kiem-cheo.sh` → `lib/cross-check.sh`; `adapters/lib/chung.sh` → `adapters/lib/common.sh`…
  (đầy đủ: `git log --stat`). Người dùng không bị ảnh hưởng — mọi lệnh vẫn gọi qua `aw …`.
- **Khoá `config.sh`**: `LENH_KIEM_THU` → `TEST_CMD`, `LENH_KIEM_TRA_BAO_MAT` → `SECURITY_CMDS`,
  `SO_LAN_DO_TOI_DA` → `MAX_RED_RUNS`, `LENH_DO_HIEU_NANG` → `PERF_CMD`, `LENH_CHUAN_BI_WT` →
  `WORKTREE_SETUP_CMD`. **Tên cũ vẫn đọc được** (khoá mới thắng nếu khai cả hai); `aw ready`
  nhắc đổi tên. Giữ tên cũ tới khi không còn việc nào ghim engine trước bản này.
- Lệnh đo hiệu năng in `RESULT: <số> <đơn vị>` (`KET_QUA:` vẫn nhận).
- Biến môi trường `AW_THU_MUC_WORKTREE` → `AW_WORKTREE_DIR`.
- **Artifact của việc mới**: `ket-qua-kiem-thu.md` → `test-results.md`, `ket-qua-bao-mat.md` →
  `security-results.md`, `ket-qua-task.md` → `task-results.md`, `tai-hien.md` → `repro.md`,
  `do-hieu-nang.md` → `perf.md`, `mo-ta-mr.md` → `mr-description.md`,
  `phat-hien-thiet-ke.md` → `design-findings.md` (mẫu chung `<checker>-findings.md`). Việc đang
  làm ghim engine cũ nên giữ tên cũ.
- **Subagent, skill, file luật**: `ra-soat-doc-lap` → `independent-reviewer`, `soat-thiet-ke` →
  `design-checker` (mẫu `<id>-checker`), skill `quy-trinh-agent` → `agent-workflow`,
  `rules/nguyen-tac-chung.md` → `rules/general.md`, `rules/truy-vet-nguon.md` →
  `rules/source-tracing.md`, `checkers/thiet-ke.md` → `checkers/design.md`; frontmatter checker
  `quy_tac` → `repo_rules`.
- `aw adapter build` tự thêm mẫu exclude còn thiếu (skill Cursor đổi đường dẫn) và dọn skill
  `quy-trinh-agent` cũ do engine sinh ra.
- File mới từ 2026.10.18–2026.10.20: `kien-thuc.sh` → `knowledge.sh`, `luat.sh` → `rule.sh` (cả `tools/lib/`), mẫu
  `templates/repo-dich/` → `templates/target-repo/` (`AGENTS.md`, `Makefile`). Lệnh `aw knowledge`,
  `aw rule` không đổi.

### Sửa
- Lệnh Claude Code: `argument-hint` đặt trong nháy kép — giá trị mở bằng `[` (vd `[tên-feature]`) YAML
  không nháy hiểu thành danh sách.

## [2026.10.20]

### Thay đổi
- **Luật cấu trúc tiếng Anh** (`rules/nguyen-tac-chung.md` §5, `AGENTS.md`): mọi heading, tên trường,
  từ khoá, giá trị enum trong mẫu và artifact agent tạo/sửa phải là tiếng Anh — kể cả heading mẫu
  chưa có. Tiếng Việt chỉ ở nội dung bên dưới.

## [2026.10.19]

### Thêm
- **`/aw-bootstrap`** — lệnh tiện ích, một lần cho mỗi repo đích có sẵn: đưa kiến thức đang nằm ngoài
  repo vào git để phiên agent mới chỉ có repo trả lời được hệ thống là gì, tổ chức ra sao, chạy và
  kiểm thế nào, vì sao code như vậy, đang ở đâu. Ở checkout chính: chạy `aw doctor` và các lệnh
  `aw … check`, đề xuất worktree `chore` (người chọn base). Trong worktree, mỗi bước một commit:
  `conventions.md` vào git, `Makefile` gọi đúng lệnh CI (target chưa có lệnh vẫn thoát mã 1),
  `AGENTS.md` 50–100 dòng chỉ trỏ tới, `ARCHITECTURE.md` cho module có ràng buộc riêng, ADR cho
  quyết định đã có (đúng định dạng `aw adr check`), ứng viên luật `BR-` (chỉ liệt kê), bài kiểm tra
  phiên mới. Chỉ ghi điều có bằng chứng trong repo; điều chỉ người biết thành câu hỏi trong báo cáo
  `<thư-mục-feature>/bootstrap.md`, kèm khoảng cách hiển thị (số mục còn ngoài repo / tổng số).
- Lệnh tiện ích khai được `runs_on_main_checkout: true` như phase.

## [2026.10.18]

Kiến thức bền của repo đích vào git: quy ước, mẫu điểm vào và lệnh kiểm, ADR từ D-xx, luật nghiệp
vụ `BR-`, kiểm chéo lỗi thời. Trạng thái của việc vẫn ngoài git như cũ. Lý do: `docs/kien-truc.md`,
mục "Trạng thái của việc và kiến thức bền".

### Đổi
- **`conventions.md` nằm trong repo đích** ở `docs/agent-workflow/conventions.md`, commit qua PR —
  cả team một bản. `.git/agent-workflow/conventions.md` của bản clone chỉ được ghi đè
  `worktree_dir`; khai khoá khác ở đó thì `aw conventions check` báo ✗ và khoá không có hiệu lực.
- **Việc đọc quy ước tại điểm rẽ khỏi base** (dòng `Base:` của `intake.md`), không đọc bản trong
  worktree: việc sửa `conventions.md` không đổi luật của chính nó. Checkout chính đọc cây làm việc.
- `aw init` tạo `docs/agent-workflow/conventions.md` từ mẫu khi repo chưa có quy ước ở đâu cả
  (không commit, in hướng dẫn commit qua PR); không bao giờ ghi đè.
- `aw init --from`: repo đích đã có quy ước trong git thì bỏ qua `conventions.md` của repo cấu hình.
- `aw doctor` nhận quy ước trong repo; `.agent-workflow/.engine/conventions.md` trỏ tới quy ước
  hiệu lực (repo + khoá máy).

- **Mẫu cho repo đích** `templates/repo-dich/AGENTS.md` (điểm vào, chỉ trỏ tới, 50–100 dòng) và
  `Makefile` (setup, test, lint, security; target chưa khai thoát mã 1). `aw init` nhắc khi repo
  chưa có `AGENTS.md`/`CLAUDE.md`; mẫu `config.sh` khuyến nghị `LENH_KIEM_THU="make test"` và
  `secret: make security-secret`… để lệnh kiểm nằm trong git, cùng lệnh với CI.

- **ADR từ D-xx** (`docs/adr/`, khoá `knowledge_adr_dir`): người quyết nâng trong chính D —
  `- Promote: adr`, `- Scope:`, `- Supersedes: ADR-NNNN` nằm dưới dấu duyệt. Plan phải có task nâng
  (`Expected files` gồm thư mục ADR); implement chạy `aw adr promote <thư-mục-feature> D-NN` (chép D
  + nguồn của YC, không thêm nội dung); implement và review chặn khi ADR thiếu hoặc lệch D đã duyệt.
  `aw adr check` kiểm hình thức thư mục ADR.
- **`aw knowledge design <thư-mục-feature>`**: chỉ mục ADR, ADR accepted và tài liệu module
  (`knowledge_files`, mặc định `*/ARCHITECTURE.md`) liên quan đường dẫn trong `## Existing code`;
  phase design đọc trước khi khảo sát. Checker LLM thiết kế chặn `trái ADR`.

- **Luật nghiệp vụ `BR-`** (`docs/product/rules/<miền>.md`, khoá `knowledge_rules_dir`): người quyết
  trong YC — `- Promote: BR-<MIỀN>-NNN` dưới dấu duyệt spec. Spec chặn ID sai dạng, YC
  `[INFERRED]`/`[OPEN-QUESTION]`, ID đã có ở việc khác; plan đòi task phủ YC ghi file luật;
  `aw rule promote <thư-mục-feature> YC-NNN` chép tên, Description, tiêu chí, nguồn có phiên bản (lời
  người: `[HUMAN]` + `Quote` nguyên văn), phạm vi từ `Expected files`; implement và review chặn khi
  khối thiếu hoặc lệch YC. `aw rule check` kiểm hình thức, cảnh báo luật chưa có test `covers: BR-…`.
  `aw knowledge spec` in luật active; `aw knowledge design` thêm luật có `Scope` khớp.

- **Kiểm chéo kiến thức bền lỗi thời**: diff đụng phạm vi của tài liệu module (thư mục chứa nó), ADR
  accepted (`Scope`) hay file luật (`Scope` của luật active) mà tài liệu không đổi → implement cảnh
  báo; review chặn khi `## Durable knowledge` của `review.md` thiếu verdict hợp lệ cho tài liệu đó
  (`pass | updated | not applicable` + lý do). Luật active trong phạm vi diff chưa có test `covers:`
  → implement cảnh báo. Hình thức thư mục ADR chỉ chặn việc có nâng ADR.
- Bỏ `docs/de-xuat-kien-thuc-ben.md` (đề xuất tạm): lý do đã ở `docs/kien-truc.md`.

### Tương thích
- Repo init bằng engine cũ (quy ước chỉ ở bản clone) chạy như cũ; `aw conventions check` cảnh báo
  và in cách chuyển. `aw init`/`aw upgrade` không tự tạo file trong repo khi bản clone đã có.

## [2026.10.17]

Tinh gọn mọi thứ agent đọc để tiết kiệm ngữ cảnh. Luật không đổi, checker không đổi.

### Đổi
- **Nội dung agent đọc lúc chạy chuyển sang tiếng Anh, chỉ giữ chỉ thị**: thân
  `workflow/phases/*.md`, `clarify.md`, `import.md`, `rules/`, checker LLM, và lời dặn
  adapter sinh ra. Lý do thiết kế chuyển hết về `docs/kien-truc.md`. Nội dung người
  đọc giữ tiếng Việt: `name`/`summary` (menu lệnh), mẫu artifact, output và nhãn
  `Kết quả` của `aw`, câu hỏi và lựa chọn hiện cho người. Agent được dặn nói với người
  và viết artifact bằng tiếng Việt.
- **Mỗi luật một chỗ**: bảng mức chặn của điểm mù ở `rules/truy-vet-nguon.md`; danh sách
  điều checker kiểm không lặp trong file phase; hợp đồng vào/ra chỉ do adapter dựng.
- **Lệnh chỉ bắt đọc file cần thiết**: `rules/truy-vet-nguon.md` chỉ cho lệnh khai
  `trace_rule: true` (spec, design, clarify, import); `conventions.md` thành "tra khi
  cần". `/aw-review` chỉ bàn giao cho subagent `ra-soat-doc-lap`, không nạp mô tả phase
  vào phiên chính.
- Kích thước một lần gọi lệnh (file lệnh + file bắt buộc đọc), byte: `/aw-intake`
  34,6K → 13,1K; `/aw-spec` 34,7K → 15,5K; `/aw-design` 33,4K → 16,6K; `/aw-plan`
  31,1K → 11,0K; `/aw-implement` 34,2K → 12,1K; `/aw-review` 35,7K → 3,4K (subagent
  15,4K → 8,8K); `/aw-clarify` 39,2K → 20,0K. Chữ tiếng Anh còn tốn ít token hơn trên
  mỗi byte.
- `README.md` (54K → 13K) chỉ còn hướng dẫn dùng; `docs/kien-truc.md` (53K → 27K) gọn
  lại, giữ đủ lý do.

### Thêm
- `AGENTS.md` (và `CLAUDE.md` trỏ tới nó): bản đồ repo, quy ước code, cách kiểm và phát
  hành — cho agent phát triển chính repo này.
- Frontmatter `trace_rule: true` cho phase / lệnh tiện ích.
- Test: mọi lệnh sinh ra có đủ hợp đồng phase; `/aw-review` chỉ bàn giao.

## [2026.10.16]

`conventions.md` dễ cấu hình hơn cho người, và có lệnh kiểm sau khi sửa.

### Thêm
- **`aw conventions check`** — kiểm `conventions.md` của bản clone. Lỗi (chặn):
  thiếu / thừa / chưa đóng khối ` ```conventions `; dòng không phải `khoá: giá trị`
  (vd thụt lề); **khoá lạ** (gõ sai — trước đây script bỏ qua ngầm, luật tắt mà
  không ai biết); khoá khai hai lần; khoá bắt buộc trống (`base_branch`,
  `branch_patterns`, `type_by_prefix`, `test_files`); `mr_platform` khác
  github/gitlab; `type_by_prefix` sai loại hoặc lệch `branch_patterns`; regex không
  biên dịch được hoặc dùng `{n}`; `worktree_dir` thiếu `{ten}` hay nằm trong repo;
  `base_branch` không có; file `rules_*` không dùng được. Cảnh báo: thiếu khoá so với
  mẫu của engine, glob không khớp file nào trong repo, file vừa là test vừa là
  production, placeholder còn sót, thiếu mục `### Merge request`.
  `aw ready` gọi lệnh này thay cho phần tự kiểm riêng; `aw init` nhắc chạy nó.
- **`workflow/templates/conventions-reference.md`** — giải thích đầy đủ từng khoá,
  cú pháp glob/regex, mặc định khi để trống. Tài liệu của engine (trong worktree:
  `.agent-workflow/.engine/templates/`), cập nhật theo engine — không còn bị đóng
  băng trong `conventions.md` của repo đích.

### Đổi
- Mẫu `conventions.md` viết lại: khối máy đọc chia nhóm (Branches & worktrees, Merge
  requests, File classes, Test, Security, Intake input, Repo rules), mỗi khoá một
  dòng chú thích gắn nhãn `[edit]` / `[default]` / `[optional]`; bảng giải thích dài
  chuyển sang `conventions-reference.md`. Heading tiếng Anh: `Repository
  conventions`, `Machine-readable`, `Team conventions`. Dòng `#` trong khối là chú
  thích (parser vốn đã bỏ qua).
- Tài liệu sửa cho đúng code: `bugfix` không dùng `production_code` — bước tái hiện
  chỉ cho đụng `test_files` và `ignored_files`.

### Đổi (phá vỡ)
- **Khoá của `conventions.md` đổi sang tiếng Anh, không giữ tên cũ:**
  `mau_branch` → `branch_patterns`, `loai_theo_tien_to` → `type_by_prefix`,
  `nhanh_goc` → `base_branch`, `thu_muc_worktree` → `worktree_dir`,
  `mau_nhanh_phat_hanh` → `release_branches`, `nhanh_dich_mr` → `mr_target_branches`,
  `nen_tang_mr` → `mr_platform`, `bo_qua` → `ignored_files`,
  `mau_file_test` → `test_files`, `the_covers` → `covers_tag`,
  `mau_bo_qua_test` → `skipped_test_regex`, `mau_code_production` → `production_code`,
  `mau_code_nhay_cam` → `sensitive_code`, `mau_file_dependency` → `dependency_files`,
  `mau_jira` → `jira_key_regex`, `mien_confluence` → `confluence_domains`,
  `quy_tac_<phase>` → `rules_<phase>`.
  `aw init` không ghi đè `conventions.md` — **tự đổi tên trong
  `.git/agent-workflow/conventions.md`**, rồi chạy `aw conventions check` (khoá cũ
  hiện là "khoá lạ"). `conventions.md` dùng chung mọi worktree: việc đang ghim
  engine cũ đọc tên khoá cũ — làm xong các việc đó trước khi đổi tên.
- Lệnh mới `aw conventions` cần wrapper `aw` mới.

## [2026.10.15]

Áp dụng các bài học của khoá *Learn Harness Engineering* (walkinglabs): máy giữ
trạng thái thay vì tin lời agent, phiên mới biết ngay đang ở đâu, lỗi bắt được một
lần thành hàng rào vĩnh viễn.

### Thêm
- **`aw ready <thư-mục-feature> [--no-test]`** — đầu phiên mới: cấu hình có đủ khoá
  máy cần (`nhanh_goc`, `mau_file_test`, `mau_branch`, quy tắc repo), lệnh test
  **xanh trên code chưa sửa**, lệnh quét bảo mật đã khai đúng dạng; in tiến độ và
  **bước tiếp** (phase nào, task nào). `aw doctor` vẫn chỉ kiểm phần cài đặt.
- **Trạng thái task do máy giữ — `aw task next|start|done <thư-mục-feature> [T-NN]`.**
  `start`: `[ ]` → `[~]`, từ chối khi đã có task `[~]` (WIP=1) hoặc phụ thuộc chưa
  `[x]`. `done`: chạy lệnh trong backtick của dòng `Verify`, ghi output thật vào
  `ket-qua-task.md`, **xanh** mới lên `[x]`; Verify không có lệnh thì
  `--manual "<bằng chứng>"`. `next`: task làm tiếp. Đỏ liên tiếp tới
  `SO_LAN_DO_TOI_DA` (khoá mới trong `config.sh`, mặc định 3) → DỪNG, báo người.
- **Vòng lặp cho `04-implement`** (tuỳ chọn): `next → start → làm → done` tới khi
  hết task, với điều kiện dừng rõ ràng — mô tả bằng lệnh `aw` trong file phase,
  không phụ thuộc agent.
- **Trạng thái sạch:** `aw check implement` chặn task `[ ]` còn sót và dấu xung đột
  merge trong file đã đổi; cảnh báo (review chặn) dòng **thêm mới** trong file test
  có `.only(` / `.skip(` / `xit(` / `@Disabled` / `pytest.mark.skip`… — khoá mới
  `mau_bo_qua_test` trong `conventions.md` (ERE, bỏ trống = mặc định); file khai ở
  "Unplanned" thì miễn.
- **Nhật ký harness — `aw journal`** (`$AW_CONFIG/journal/`, không commit): engine
  ghi mỗi lần `aw check` (checker, đạt không, vi phạm đầu tiên; `AW_JOURNAL=0` để
  tắt); `aw journal add <task|context|env|verify|state|model> "<mô tả>"` ghi thất bại
  theo lớp; `aw check review` đạt thì ghi finding theo `Category`. `aw journal` tổng
  hợp: checker trượt nhiều nhất, thất bại theo lớp, loại finding lặp lại.
- **`- Category: <loại-lỗi>`** (kebab-case) cho finding `[Blocker]` / `[Should fix]`
  trong `review.md`. Loại đã gặp ở việc khác → `aw check review` in `[GỢI Ý]` nâng
  thành luật máy kiểm.

### Đổi (phá vỡ)
- Việc tạo bằng engine này: task `[x]` phải có bằng chứng xanh trong
  `ket-qua-task.md` khớp `Verify` hiện tại — tự đánh `[x]` thì `aw check implement`
  và `aw check review` KHÔNG ĐẠT. Task `[ ]` còn sót cũng KHÔNG ĐẠT (trước đây chỉ
  chặn `[~]`). Việc đã ghim engine cũ không bị ảnh hưởng.
- `[Blocker]` / `[Should fix]` thiếu `- Category:` hay không phải kebab-case →
  `aw check review` KHÔNG ĐẠT.
- Lệnh mới `aw ready`, `aw task`, `aw journal` cần wrapper `aw` mới.

## [2026.10.14]

### Thêm
- **Cổng bảo mật bằng máy, khớp CI.** Khoá mới `LENH_KIEM_TRA_BAO_MAT` trong
  `config.sh`: mỗi dòng `<nhóm>: <lệnh>` (`secret | sast | sca | other`), khai đúng
  lệnh/config/ngưỡng của pipeline (gitleaks, semgrep, sonar-scanner, trivy, npm
  audit…). `aw check implement` chạy chúng sau test và ghi `ket-qua-bao-mat.md`
  (output thật từng lệnh); `aw check security` chỉ chạy phần quét. Chưa khai, khai
  sai dạng, hay một lệnh đỏ → KHÔNG ĐẠT; thiếu nhóm `secret`/`sast`/`sca` chỉ cảnh báo.
- **Độ mới của bằng chứng:** `ket-qua-kiem-thu.md` và `ket-qua-bao-mat.md` ghi `HEAD`,
  `Tree` (dấu vân tay nội dung code lúc chạy) và thời điểm. `aw check review` chặn khi
  file thiếu `Tree` hoặc `Tree` khác code hiện tại — sửa code sau lần chạy, kể cả chưa
  commit, không còn lọt. Commit lại đúng code đã review thì không tính là đổi.
- **chore đụng file dependency** phải có lệnh nhóm `sca` chạy xanh (CVE/license) —
  mức patch/minor không nói gì về chúng.
- **`## Lens 4 — Security` trong `review.md`:** bảng bảy hạng mục cố định (Input
  validation / injection; Authn / authz; Sensitive data / PII in logs; Secrets /
  config; Crypto; SSRF / path traversal / deserialization; New dependencies), verdict
  `pass | finding | not applicable`. `aw check review` chặn khi thiếu mục, thiếu dòng,
  verdict sai, `finding`/`not applicable` không vị trí/lý do, hoặc có `finding` mà
  Lens 3 không có finding nào.
- **`Blocker`** gồm thêm: lỗ hổng bảo mật khai thác được, mất/lộ dữ liệu, breaking
  change chưa khai.

- **Siết `aw check review`:** Lens 3 phải có finding hoặc đúng dòng `- None`, không
  còn chữ giữ chỗ; `[Blocker]`/`[Should fix]` có `Location` dạng `file:dòng`;
  `[Blocker]` có `Failure scenario`; `Blocker findings: <n>` ở Conclusion bằng số mục
  `[Blocker]`; dòng mới `- Reviewed tree:` phải khớp dấu vân tay code hiện tại (code
  đổi sau khi rà → rà lại).

- **Code nhạy cảm cần người rà bảo mật.** Khoá mới `mau_code_nhay_cam` trong
  `conventions.md` (glob, vd `src/auth/* src/payment/*`; bỏ trống = tắt). Diff đụng
  vào thì `review.md` phải có `- Security reviewer: <tên người>` — `aw check review`
  chặn khi thiếu, còn giữ chỗ, hay là tên agent; `exit_human` của review thêm bước
  người rà bảo mật xác nhận; `aw check implement` in `[LƯU Ý]` (không chặn).

### Sửa
- Lens 1 chỉ đọc dòng bảng có ô đầu là mã YC — bảng khác nhắc `YC-NNN` ở cột lý do
  không còn ghi đè kết luận.

### Đổi (phá vỡ)
- Bản clone có `config.sh` cũ chưa có `LENH_KIEM_TRA_BAO_MAT` → `aw check implement`
  KHÔNG ĐẠT tới khi người khai (`aw init` không ghi đè `config.sh`; chép khối chú
  thích từ `workflow/templates/config.sh`). Việc chuyển sang engine này giữa chừng có `ket-qua-kiem-thu.md` cũ
  (không có `Tree`) → chạy lại `aw check implement` trước `/aw-review`.
- `review.md` thiếu `## Lens 4 — Security`, `## Lens 3` không finding cũng không
  `- None`, thiếu `Blocker findings` hay `Reviewed tree` → `aw check review` KHÔNG ĐẠT.

## [2026.10.13]

### Đổi (phá vỡ thói quen gõ lệnh)
- **Mọi lệnh có tiền tố `aw-`:** `/aw-intake`, `/aw-spec`, `/aw-design`, `/aw-plan`,
  `/aw-implement`, `/aw-review`, `/aw-ship`, `/aw-import`, `/aw-clarify` (file
  `commands/aw-<id>.md`, cả Claude Code lẫn Cursor). Gõ `/aw-` là lọc ra đủ lệnh của
  quy trình. `aw adapter build` / `aw worktree new` tự xoá file lệnh cũ (`intake.md`…)
  do engine sinh; file người viết tay giữ nguyên. Dùng `aw-` chứ không `aw:` (thư mục
  con): Cursor chưa chắc hiểu thư mục con, và hai adapter phải trùng tên lệnh.
- **Description lệnh viết lại:** chỉ còn `summary` (bỏ ghép `<name> — <summary>`),
  nói "khi nào chạy, chạy xong có gì", phase ghi `Bước n/6`, phase có cổng duyệt nói
  trước điều kiện duyệt. `name` mới: Tiếp nhận việc, Viết đặc tả, Thiết kế kỹ thuật,
  Lập kế hoạch, Hiện thực, Rà soát độc lập, Gửi MR và dọn việc, Nhập artifact ngoài,
  Chốt việc chờ người. Hook adapter `ad_dau_lenh <lệnh> <name> <summary> <gợi-ý>`.

### Thêm
- **Phase `06-ship` (`/aw-ship`, tuỳ chọn) — gửi MR/PR và dọn việc.** Trong worktree:
  agent viết `merge-request.md` theo mẫu, `aw check ship` chặn khi review chưa đạt,
  còn `[Blocker]`, mô tả thiếu mục hay còn chữ giữ chỗ. `aw ship targets` liệt kê
  nhánh đích (khoá mới `nhanh_dich_mr`, vd `develop uat/* main`) cho người chọn.
  `aw ship create --target <nhánh>` push và tạo MR, chặn khi MR kéo theo commit không
  thuộc việc (`--allow-extra-commits` khi người chấp nhận), ghi `ship.md`; chạy lại
  cùng đích chỉ push thêm. `aw ship status` hỏi trạng thái MR. Ở checkout chính:
  `aw ship sweep [--apply]` gỡ worktree, xoá branch local và trên origin của việc đã
  merge — xoá cứng chỉ khi đầu branch trùng sha MR đã merge.
- **Tạo MR không cần token:** `gh`/`glab` đã cài **và đăng nhập** thì dùng (khoá mới
  `nen_tang_mr`, bỏ trống = đoán từ origin); GitLab không có `glab` → git push
  options (`merge_request.create`, chỉ cần quyền git; mô tả để ở `mo-ta-mr.md` cho
  người dán); còn lại → link tạo MR điền sẵn đích, tiêu đề, mô tả, ghi lại bằng
  `--url`. Không có CLI thì trạng thái suy từ git, nhận ra cả squash merge sạch
  (patch-id).
- Frontmatter phase `runs_on_main_checkout: true`: lệnh không dừng ở checkout chính
  mà làm theo mục "Ở checkout chính" của phase.

## [2026.10.12]

### Thêm
- **Adapter Cursor** (`adapters/cursor/`): `.cursor/commands/` (lệnh `/intake`…`/review`,
  `/import`, `/clarify`), `.cursor/agents/` (`ra-soat-doc-lap`, `soat-thiet-ke`),
  `.cursor/skills/quy-trinh-agent/`. Tên trùng bản Claude Code để bản `.cursor/` che
  bản `.claude/` mà Cursor nạp để tương thích. Tham số lệnh là `<tham-số>` (Cursor
  không thay `$ARGUMENTS`); hỏi lựa chọn và hộp xác nhận cổng duyệt bằng tool của
  Cursor nếu có, không thì đánh số. Hook `aw guard` cho Cursor: `.cursor/hooks.json`
  — xem adapters/cursor/README.md.
- **Nhiều adapter cho một bản clone:** `ADAPTER` trong `config.sh` nhận nhiều id
  (`"claude-code cursor"`, dấu cách hoặc phẩy); `aw init --adapter claude-code,cursor`.
  `aw init` exclude đường dẫn của mọi adapter; `aw worktree new --create` và
  `aw adapter build` sinh mọi adapter (`aw adapter build` không id = theo `config.sh`).
  Dấu build `.agent-workflow/.adapters`; `aw doctor` báo worktree thiếu bộ lệnh của
  một agent hay `ADAPTER` khai id không có.
- Engine chặn chữ giữ chỗ chưa thay: `aw feature '<tham-số>'` / `'$ARGUMENTS'` →
  `TÊN KHÔNG HỢP LỆ`; `aw input` với đúng chữ giữ chỗ → `SAI CÁCH GỌI`.

### Đổi
- Việc sinh file của adapter dồn vào `adapters/lib/chung.sh` (`ad_sinh`); adapter chỉ
  khai hook (`ad_tham_so`, `ad_dau_lenh`, `ad_mo_dau_lenh`, `ad_hoi_lua_chon`,
  `ad_hoi_cong_duyet`, `ad_danh_cho`). Output Claude Code không đổi, trừ dòng mới
  "Dành cho Claude Code" ở mỗi file (Cursor nạp nhầm thì dừng).
- `aw init --adapter` sai id thì từ chối **trước** khi ghi `config.sh`.
- Test: đối chiếu mọi adapter (`AW_DOI_CHIEU=1`, giống hệt từng byte ngoài hook),
  hai adapter cùng thư mục, exclude phủ đúng file sinh ra, `aw guard` chạy hai lần.

## [2026.10.11]

### Đổi
- **Duyệt bằng ô tick thay cho gõ chữ.** `spec.md` có ô
  `- [ ] **Approved by human**` ở phần đầu file thay cho dòng
  `Status: proposed | approved`; mỗi D-xx trong `tdd.md` có ô
  `- [ ] **Approved by human**` thay cho `Status: …`. D chưa tick mà có
  `Reopen reason:` là D đang mở lại (`reopened`). Gặp dạng cũ thì `aw check` báo
  cách đổi. Việc đã bắt đầu vẫn chạy bằng engine ghim trong `intake.md`, không bị
  ảnh hưởng.
- `/clarify` sửa spec đã duyệt (sửa YC hay đổi nhãn nguồn) thì bỏ tick, người
  tick lại — không còn ngoại lệ "giữ nguyên Status của spec".

### Thêm
- **Dấu duyệt:** lần đầu thấy tick, máy ghi hash nội dung (spec, hoặc từng D) cạnh
  tick, `<!-- approval-hash: … -->`. Nội dung đổi sau đó mà tick còn thì
  `aw check spec|design|plan` chặn "đổi sau khi duyệt". Duyệt lại: xoá dấu, giữ
  tick. Dòng trống, chú thích và `- Critique (agent):` không tính vào hash. Hash
  `based_on` bỏ qua dấu duyệt nên máy ghi dấu không làm artifact phía sau lỗi thời.
- **Parser ô duyệt chặt:** đúng chỗ (spec trước `##` đầu tiên, D trong mục của nó),
  đúng một ô; ô trong chú thích hay khối code không tính; dòng mang nhãn ô duyệt
  mà sai dạng là lỗi.
- **`aw guard pre|post`** — hook PreToolUse/PostToolUse cho Claude Code: ô được
  tick trong lúc lệnh của agent chạy, hoặc ô có dấu mà nội dung đã đổi, bị bỏ tick
  và agent được báo (mã 2). Người tự thêm vào `.claude/settings.json` — xem
  adapters/claude-code/README.md. Cần wrapper `aw` mới để có lệnh `aw guard`.
- **Cổng duyệt khi vào phase:** gõ `/design` khi spec chưa duyệt (hay `/plan` khi
  còn D-xx chưa duyệt; chore: spec) thì agent không làm gì của phase mà chạy
  `aw approval design|plan`, in bản tóm tắt máy dựng từ file (file/dòng phải tick,
  YC `[INFERRED]`, Out of scope, Risk → Mode, điểm mù còn mở; hay từng D chưa
  duyệt: dòng, tác giả, lựa chọn, phản biện), rồi hỏi bằng hộp xác nhận
  (`AskUserQuestion`, có preview): *Tôi đã duyệt xong — kiểm lại* · *Giải thích
  từng điểm cần duyệt* · *Dừng — tôi duyệt sau*. Agent không tick hộ. Phase khai
  `approval_gate: true` trong frontmatter. Cần wrapper `aw` mới để có lệnh
  `aw approval`.

## [2026.10.10]

### Đổi
- **Đầu mục của `intake.md` sang tiếng Anh:** `# Tiếp nhận` → `# Intake`,
  `Loại việc:` → `Type:`, `Mục tiêu:` → `Goal:` (`Base:`, `Engine:`, `## Input`
  giữ nguyên). `aw check intake` và luật theo loại việc chỉ đọc dòng
  `- **Type:**` / `- **Goal:**`. Việc đã bắt đầu không bị ảnh hưởng: nó chạy hết
  bằng version ghi ở dòng `Engine:`. Việc mới tạo bằng bản này phải dùng đầu mục
  mới.
- **Nhãn input `[NGƯỜI-DÙNG]` → `[HUMAN]`:** lời người vận hành workflow chép
  nguyên văn trong `## Input` của `intake.md`. Đổi để không nhầm với "người dùng"
  cuối của sản phẩm trong tài liệu nghiệp vụ, và khớp cặp máy / người
  (`exit_machine` / `exit_human`). `aw input` in `[HUMAN]`; `aw check intake`
  chỉ nhận `[HUMAN]`.
- **Đầu mục và tên trường của `spec.md` sang tiếng Anh:** `# Đặc tả` → `# Spec`;
  `Mức rủi ro` → `Risk`, `Lý do` → `Reason`, `Trạng thái spec` → `Status`;
  mục `Nguồn` → `Sources`, `Bối cảnh` → `Context`, `Thuật ngữ` → `Glossary`,
  `Yêu cầu` → `Requirements`, `Tái hiện lỗi` → `Reproduction`
  (`Steps to reproduce`, `Actual behavior`, `Expected behavior`),
  `Ràng buộc & phụ thuộc` → `Constraints & dependencies`, `Ngoài phạm vi` →
  `Out of scope`, `Mâu thuẫn giữa các nguồn` → `Source conflicts` (cột
  `Source A says | Source B says | Resolution`); trường của YC: `Nguồn` →
  `Source`, `Ưu tiên` → `Priority`, `Mô tả` → `Description`, `Tiêu chí chấp nhận`
  → `Acceptance criteria`, `Giả định tạm` → `Assumption`, `Loại YC` → `Type`,
  `Được bảo vệ bởi` → `Protected by`, `Mục tiêu` → `Target`. `aw check spec/design/plan/review` và `aw pending` đọc tên mới,
  neo ở đầu dòng `- `.
- **Giá trị trong `spec.md` sang tiếng Anh:** `Risk: cao | thường` →
  `high | normal`; `Status: đề xuất | đã duyệt` → `proposed | approved`;
  `Priority: bắt buộc | nên có` → `must | should`; `Type: giữ nguyên | cấu trúc |
  hiệu năng` → `preserve | structural | performance`. `Trạng thái` của D-xx trong
  `tdd.md` không đổi (`đề xuất | đã duyệt | mở lại`).
- **Nhãn nguồn `[SUY-RA]` → `[INFERRED]`, `[CẦN-HỎI]` → `[OPEN-QUESTION]`** — ở
  mọi nơi: dòng `Source:` của spec, luật cấm suy đoán trong input của
  `intake.md`, tài liệu và hướng dẫn agent.
- **`tdd.md` sang tiếng Anh:** `# Thiết kế kỹ thuật` → `# Technical Design`; mục
  `Bối cảnh code hiện có` → `Existing code`, `Quyết định (D-xx)` → `Decisions
  (D-xx)`, `Mô hình dữ liệu` → `Data model`, `Phi chức năng` → `Non-functional`,
  `Chiến lược test` → `Test strategy`, `Ánh xạ YC` → `YC mapping`; trường của
  D-xx: `tac_gia: nguoi | agent` → `Author: human | agent`, `Trạng thái: đề xuất
  | đã duyệt | mở lại` → `Status: proposed | approved | reopened`, `Phương án` →
  `Option` (`pros` / `cons`), `Chọn` → `Choice`, `Khó đảo ngược vì` → `Hard to
  reverse because`, `Lý do mở lại` → `Reopen reason`, `Phản biện (agent)` →
  `Critique (agent)`; `Dựa trên:` → `Based on:`, `Không áp dụng:` → `Not
  applicable:`. `aw check design` và `aw check plan` (D-xx phải `approved`) đọc
  tên mới.
- **`plan.md` sang tiếng Anh:** `# Kế hoạch` → `# Plan`, `## Task` → `## Tasks`;
  trường của task: `Phủ` → `Covers`, `Dựa trên` → `Based on`, `Theo` → `Design`,
  `Phụ thuộc` → `Depends on` (`không` → `none`), `File dự kiến` → `Expected
  files`, `Cách kiểm chứng` → `Verify`, `Đứng trên giả định tạm: không | có` →
  `On assumption: no | yes`, `Trạng thái` → `Status` (`[ ] [~] [x]` giữ nguyên);
  mục `Hoãn lại` → `Deferred`, `Kiểm chứng thủ công` → `Manual verification`,
  `Test cũ bị sửa` → `Modified existing tests`, `Nâng dependency` → `Dependency
  upgrades` (cột `Library | Old → new | Level`, mức `vá` → `patch`), `Phát sinh`
  → `Unplanned`. `aw check plan/implement/review` và `aw pending` đọc tên mới.
- **`open-questions.md` sang tiếng Anh:** `# Điểm mù cần làm rõ` → `# Open
  questions` ("Không có điểm mù." → "No open questions."); trường: `Tài liệu nói
  gì` → `Source says`, `Chỗ chưa rõ` → `Question`, `Hỏi ai` → `Ask`, `Giả định
  tạm đang dùng` → `Assumption`, `Nếu giả định sai thì phải làm lại gì` → `If
  wrong, redo`, `Mức chặn: chặn | chặn review | không chặn` → `Blocking:
  blocking | review-blocking | non-blocking`, `Trạng thái: mở | đã trả lời` →
  `Status: open | answered`, `Trả lời` → `Answer`. Nhãn cũ (`Mức chặn`, `Mức ảnh
  hưởng`) bị chặn kèm hướng dẫn đổi.
- **`review.md` sang tiếng Anh:** `# Review`; `## Lens 1 — Spec conformance`
  (cột `ID | Verdict | Evidence | Notes`, verdict `đạt | đạt một phần | chưa đạt
  | chờ xác nhận` → `pass | partial | fail | pending`), `## By work type`
  (`Test tái hiện đỏ vì` → `Repro test fails because`), `## Lens 2 — Design and
  scope`, `## Repo rules` (`đạt | vi phạm | không áp dụng` → `pass | violation |
  not applicable`), `## Lens 3 — Quality` (`[Chặn] [Nên sửa] [Góp ý]` →
  `[Blocker] [Should fix] [Nit]`, `Location`, `Problem`, `Failure scenario`),
  `## Carried-over warnings`, `## Conclusion`. `aw check review`, `aw check
  spec/design/plan/implement` (điểm mù) và `aw pending` đọc tên mới.

## [2026.10.9]

### Thêm
- **Quy tắc riêng của repo theo phase:** khoá `quy_tac_spec`, `quy_tac_design`,
  `quy_tac_plan`, `quy_tac_implement`, `quy_tac_review` trong `conventions.md` —
  danh sách file (coding style, skill, chuẩn kiến trúc…) phase đó phải đọc.
  Lệnh mới `aw rules <phase>` in danh sách lúc chạy; lệnh `/spec`…`/review` và
  subagent rà soát gọi nó. `aw check` của phase chặn khi file khai không có,
  chưa commit hoặc khoá gõ nhầm. `aw check review` chặn khi `review.md` thiếu mục
  "Quy tắc repo" hoặc thiếu kết luận (`đạt` / `vi phạm` / `không áp dụng`) cho
  một file. Repo không khai khoá nào thì không đổi gì. Cần wrapper `aw` mới để
  có lệnh `aw rules`.
- Checker LLM soát thiết kế (`soat-thiet-ke`) đọc `quy_tac_design` và có loại
  phát hiện mới `trái quy tắc repo` — mức Chặn, chỉ Cảnh báo khi đã có D-xx cân
  nhắc chuyện đó. Checker LLM khai `quy_tac: <phase>` trong frontmatter để đọc
  quy tắc của phase đó.

### Đổi
- **Version `YYYY.M.N`** thay cho `YYYY.M.D`: `N` là số thứ tự bản phát hành trong
  tháng, không còn giới hạn một bản mỗi ngày. Không số 0 đứng đầu, `N` từ 1.
  Wrapper `aw` cũ (2026.10.6, 2026.10.7) vẫn nhận version mới khi `N` ≤ 31; từ
  bản thứ 32 trong một tháng cần cài wrapper mới.

### Thêm
- **Phát hành bằng merge PR:** workflow `release` chạy cả khi push vào `main` —
  tag của `VERSION` chưa có thì tự test, đóng gói, tạo tag + Release; đã có thì
  bỏ qua. Cách tay (push tag / tạo trên giao diện GitHub) vẫn giữ.
- `tools/chuan-bi-phat-hanh.sh [YYYY.M.N]`: đặt version cho PR — tự tính số kế
  tiếp từ tag ở remote, ghi `VERSION`, `bin/aw`, mục CHANGELOG, link tải wrapper.
- `tools/kiem-tra-phat-hanh.sh [<base-ref>]` và workflow `kiem-tra` trên PR: test
  hồi quy + version nhất quán (`VERSION` ↔ `bin/aw` ↔ CHANGELOG), PR đổi version
  thì tag đó chưa được có.

## [2026.10.8]

### Đổi
- `/clarify`: lựa chọn là **phương án giải pháp agent đã phân tích**, không còn
  chỉ "giữ giả định / chưa trả lời được". Trước mỗi mục, agent đọc nguồn, spec,
  thiết kế, code đã có; đưa 2–3 phương án khác nhau về hệ quả, mỗi phương án
  kèm đánh đổi một dòng; phương án nên chọn đứng đầu, nhãn **bắt đầu bằng
  `(Đề xuất)`**, ngữ cảnh nói vì sao. Mục gói nhiều quyết định thì tách thành
  nhiều câu hỏi trong cùng lượt. Phát hiện checker LLM: các cách sửa cụ thể +
  Bác bỏ (agent thấy phát hiện sai thì đề xuất bác bỏ).
- Adapter Claude Code: không thêm "Chat về câu này" vào `options` nữa — dùng
  "Chat about this" / "Type something" có sẵn của `AskUserQuestion`, để đủ chỗ
  cho phương án thật. Mẫu câu hỏi luôn kết thúc bằng hai dòng `Type something.`
  và `Chat about this.`; agent không có giao diện lựa chọn thì tự in hai dòng đó.
- Người chọn phương án agent đề xuất thì `Trả lời:` ghi nhãn phương án kèm
  `(chọn từ phương án agent đề xuất)`.

## [2026.10.7]

### Đổi (phá tương thích)
- `/open-questions` → **`/clarify`**: một hàng đợi cho mọi việc máy/LLM cần người
  quyết. Ngoài điểm mù (`open-questions.md`), lệnh dẫn người **phân xử phát hiện
  của checker LLM** (`phat-hien-*.md`, hiện có `phat-hien-thiet-ke.md`) từng mục
  bằng câu hỏi lựa chọn: Đồng ý — sửa · Bác bỏ (kèm lý do) · Chat về câu này, mục
  `Cảnh báo` thêm Để sau. Đồng ý thì agent cho xem dòng `tdd.md` sẽ đổi rồi ghi
  `đã sửa`; quyết định mới thành D-xx `đề xuất` để người duyệt. Phát hiện agent
  đã tự sửa lúc `/design` được nêu lại trong tổng kết.
- `aw questions` → **`aw pending`** (`tools/liet-ke-viec-cho.sh`): gom điểm mù và
  mọi `phat-hien-*.md`, xếp theo phase bị chặn sớm nhất (điểm mù chưa phân mức →
  `chặn` → phát hiện `Chặn` → `chặn review` → phát hiện `Cảnh báo` → `không chặn`).
  Nhãn kết quả đổi theo: `KHÔNG CÒN VIỆC CHỜ NGƯỜI` / `CÓ VIỆC ĐANG CHẶN` /
  `CÒN VIỆC CHỜ NGƯỜI, CHƯA CHẶN`. Wrapper vẫn chuyển `aw questions` cho việc đã
  ghim engine 2026.10.6.
- Tên và cấu trúc file trong `.agent-workflow/<tên-branch>/` **không đổi**. Repo
  đích chạy lại `aw adapter build claude-code`: `/open-questions` cũ tự bị xoá.
- Wrapper `aw` 2026.10.6 không biết `aw pending` — cài lại wrapper từ bản này
  (README, mục cài đặt) trước khi dùng `/clarify`.

## [2026.10.6]

Bản đầu tiên có version: đổi cách cài, **phá tương thích** với bộ cài cũ. Không còn file nào
phải commit vào repo đích — chạy được khi nhánh gốc là protected branch.

### Thêm
- Wrapper `aw` (POSIX sh, cài global). Tìm repo bằng `git rev-parse`, lấy engine
  đúng version vào `~/.agent-workflow/engine/<YYYY.M.D>/`, kiểm và ghim sha256,
  chuyển lệnh sang engine. `AW_ENGINE_DIR` (không mạng), `AW_MIRROR`, `AW_CACHE`.
- Lệnh: `aw init [--from <url>] [--from-legacy]`, `aw upgrade <YYYY.M.D>`,
  `aw version`, `aw doctor`, `aw check <tên> <thư-mục>`, `aw worktree new|status|remove`,
  `aw adapter build <agent>`, `aw feature`, `aw input`, `aw questions`,
  `aw based-on`, `aw rename`. Tên lệnh và cờ đều tiếng Anh.
- Ghim version theo việc: dòng `- **Engine:** YYYY.M.D` trong `intake.md`; mọi
  `aw check` của việc chạy đúng version đó, không có thì `KHÔNG HỢP LỆ`.
- Đóng gói phát hành (`tools/dong-goi.sh`) và workflow `release` gắn
  `agent-workflow-YYYY.M.D.tar.gz`, `aw`, `SHA256SUMS` vào GitHub Release.
- `adapters/lib/chung.sh` và `adapters/README.md` (hợp đồng adapter, ghi chú Codex/Cursor).
- Mẫu mô tả MR/PR `workflow/templates/merge-request.md` và quy ước mặc định ở
  mục "Merge request" của `conventions.md` (tiêu đề, phạm vi, mục bắt buộc,
  điều kiện trước khi review/merge).

### Đổi
- `/open-questions` hỏi **từng điểm mù một bằng câu hỏi lựa chọn** thay vì dán cả
  danh sách: giữ giả định tạm · cách hiểu khác có trong nguồn · Chưa trả lời được
  · Chat về câu này, luôn kèm ô tự nhập. Output của `aw questions` là dữ liệu cho
  agent; người chỉ thấy một dòng tóm tắt. Lệnh tiện ích khai `choice_ui: true`;
  adapter Claude Code dịch sang tool `AskUserQuestion`.
- Cấu hình nằm trong `$(git rev-parse --git-common-dir)/agent-workflow/`:
  `version`, `checksums`, `conventions.md`, `config.sh` (thay `.quy-trinh/cau-hinh.sh`,
  thêm `ADAPTER`). Dùng chung mọi worktree, không commit.
- `/.agent-workflow/` và thư mục adapter (`/.claude/`) vào `.git/info/exclude`.
  Artifact của việc chỉ ở máy; `aw worktree remove` chép nó vào
  `.git/agent-workflow/archive/` trước khi gỡ.
- Base của worktree tuỳ ý — bỏ điều kiện "base phải có bộ cài".
- Adapter sinh lệnh gọi `aw …`; `exit_machine` là `aw check <tên>`. Rules,
  templates, checkers chép vào `.agent-workflow/.engine/` khi sinh adapter.
- Tool đọc đường dẫn từ `AW_REPO`, `AW_CONFIG`, `AW_ENGINE`; không còn suy từ vị
  trí của chính nó.
- Cờ: `--create --base` (thay `--tao --goc`), `--delete-branch` (thay
  `--xoa --ca-branch`), `--skip` (thay `--tru`), `--before|--after` (thay `--truoc|--sau`).

### Bỏ
- `tools/cai-dat.sh`, `tools/dong-bo.sh`: chỉ in hướng dẫn chuyển sang
  `aw init` / `aw upgrade`. Chuyển repo cũ: `aw init --from-legacy` (không xoá,
  không commit; in lệnh `git rm` để người dọn bằng PR).
