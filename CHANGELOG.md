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
