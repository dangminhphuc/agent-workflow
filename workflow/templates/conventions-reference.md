# `conventions.md` key reference

> Tài liệu của engine — cập nhật theo engine, KHÔNG chép vào repo đích. File
> `conventions.md` của repo đích chỉ giữ giá trị và chú thích một dòng; giải thích
> đầy đủ nằm ở đây. Trong worktree: `.agent-workflow/.engine/templates/conventions-reference.md`.

## Location & machine overrides

- **Quy ước của repo nằm trong git**: `docs/agent-workflow/conventions.md`, sửa và
  commit qua PR như mọi thay đổi khác. `aw init` tạo file này từ mẫu khi repo chưa có
  quy ước ở đâu cả; không bao giờ ghi đè.
- **Bản clone** (`.git/agent-workflow/conventions.md`) chỉ được ghi đè khoá của máy:
  `worktree_dir`. Khai khoá khác ở đó thì `aw conventions check` báo ✗ và khoá đó không
  có hiệu lực.
- **Việc đọc quy ước tại điểm rẽ khỏi base** (dòng `Base:` của `intake.md`), không đọc
  bản trong worktree: việc sửa `conventions.md` không đổi luật của chính nó; thay đổi có
  hiệu lực cho việc sau khi PR merge. Checkout chính (và việc rẽ từ base chưa có file)
  đọc bản ở cây làm việc của checkout chính.
- **Repo init bằng engine cũ** (quy ước chỉ ở bản clone): chạy như cũ, `aw conventions
  check` cảnh báo và in cách chuyển — chép file vào `docs/agent-workflow/`, commit qua
  PR, rồi chỉ giữ ở bản clone các khoá máy (hoặc xoá file).
- Agent đọc quy ước hiệu lực (đã gộp) ở `.agent-workflow/.engine/conventions.md`.

## Syntax

- Khối bắt đầu bằng dòng ` ```conventions ` và kết thúc ở dòng ` ``` ` kế tiếp.
  Script chỉ đọc khối này (sh + awk); phần còn lại của file là văn xuôi.
- Mỗi dòng `khoá: giá trị`, khoá viết sát đầu dòng. Danh sách cách nhau bằng dấu cách.
- Dòng bắt đầu bằng `#` và dòng trống trong khối bị bỏ qua — dùng để chú thích.
- Khoá khai hai lần: **dòng đầu thắng**. Khoá thiếu = khoá để trống.
- **Glob**: so bằng `case` của shell; `*` khớp cả `/` (`src/*` khớp `src/a/b.ts`).
  Mẫu so với đường dẫn tính từ gốc repo, nên `test/*` chỉ khớp thư mục `test/` ở
  gốc — monorepo cần thêm `*/test/*`.
- **Regex**: ERE, không dùng `{n}` (mawk không hỗ trợ).
- Đường dẫn file (khoá `rules_*`): tương đối với gốc repo, không chứa dấu cách.

`aw init` không bao giờ ghi đè `conventions.md`. Khoá thêm vào engine sau khi repo
đã init sẽ **thiếu** trong file của repo, tức là được xử lý như để trống — đối chiếu
với `.agent-workflow/.engine/templates/conventions.md` sau khi nâng engine.

**Kiểm sau khi sửa: `aw conventions check`** — báo ✗ cho lỗi cú pháp, khoá lạ
(gõ sai), khoá trùng, khoá bắt buộc trống, giá trị sai dạng; báo ! cho khoá thiếu so
với mẫu, glob không khớp file nào, file vừa là test vừa là production, placeholder
còn sót. `aw ready` gọi lệnh này.

## Branches & worktrees

### `branch_patterns`
Mẫu glob tên branch. Branch khớp mẫu thì tên branch là tên feature → artifact ở
`.agent-workflow/<tên-branch>/` (`aw feature`). Không khớp thì lấy tham số lệnh,
không có thì hỏi người. bắt buộc.

### `type_by_prefix`
Cặp `tiền-tố=loại`, loại thuộc `feature bugfix refactor perf chore`. `aw worktree new`
dùng để đặt tên branch theo loại việc; `/aw-intake` dùng để gợi ý loại. Loại trong
`intake.md` lệch tiền tố thì `implement` cảnh báo, `review` chặn. Bắt buộc; mỗi
tiền tố ghép với mô tả phải khớp `branch_patterns`.

### `base_branch`
Nhánh checkout chính luôn đứng; ứng viên base chính khi tạo worktree. Checker so
diff với **base ghi trong `intake.md`**, chỉ quay về khoá này khi intake chưa có
dòng Base. Bắt buộc; phải có trong repo (local hoặc origin).

### `worktree_dir`
Mẫu đường dẫn worktree, tương đối với gốc repo (hoặc tuyệt đối). `{repo}` = tên repo
gốc, `{ten}` = tên branch (`/` → `_`). Phải nằm **ngoài** repo. Mỗi máy ghi đè được
bằng biến môi trường `AW_THU_MUC_WORKTREE`.

### `release_branches`
Mẫu glob nhánh phát hành, vd `release/*`. `aw worktree new` liệt kê làm ứng viên base
(bugfix gấp); base khớp mẫu này thì review không cảnh báo. Trống = không có nhánh
phát hành.

## Merge requests

### `mr_target_branches`
Mẫu glob các nhánh được làm đích MR, theo thứ tự muốn hiện, vd `develop uat/* main`.
`aw ship targets` liệt kê nhánh trên origin khớp mẫu để người chọn; `aw ship create`
từ chối đích khác. Trống = chỉ `base_branch`.

### `mr_platform`
`github` hoặc `gitlab` — `aw ship` tạo MR/PR bằng `gh` / `glab` (người cài và đăng
nhập sẵn). Trống: đoán từ URL của origin (`github.com` → github, có chữ `gitlab` →
gitlab). GitLab tự host tên miền khác thì phải khai.

## File classes

### `production_code`
Mẫu glob code chạy trên production.
- `chore` đụng vào → chặn (đây là việc loại khác, tách branch).
- `perf`: `aw check perf --before` từ chối khi diff đã đụng file khớp mẫu — phải đo
  "trước" khi sửa.
- `bugfix` **không** dùng khoá này: bước tái hiện chỉ cho đụng file khớp
  `test_files` và `ignored_files`, mọi file khác đều bị từ chối.

**Lưu ý test đặt cạnh code**: file khớp cả `production_code` lẫn `test_files`
(vd `src/a.test.ts` với `src/*`) vẫn bị coi là code production — `chore` sửa test
trong `src/` sẽ bị chặn. Repo đặt test cạnh code cần thu hẹp mẫu này nếu muốn
chore được sửa test.

### `test_files`
Mẫu glob file test — để tìm tag `covers:`, nhận test tái hiện của bugfix, phát hiện
test cũ bị sửa/xoá. Bắt buộc.

### `dependency_files`
Manifest/lockfile. `chore` đụng vào thì `plan.md` phải có bảng "Dependency upgrades".

### `ignored_files`
File thay đổi mà không cần nằm trong "Expected files" của `plan.md` (lockfile, file
sinh tự động…). Bugfix được đụng các file này ở bước tái hiện.

## Test

### `covers_tag`
Chuỗi đứng trước mã YC trong test, vd `// covers: YC-001, YC-002`. Trống = `covers:`.

### `skipped_test_regex`
Regex (ERE) cho test bị tắt / chạy riêng trong **dòng thêm mới** của file test. Khớp
thì `/aw-implement` cảnh báo, `/aw-review` chặn — trừ file khai ở "Unplanned" của
`plan.md`. Trống = mặc định: `.only(` `.skip(` `fit(` `fdescribe(` `xit(` `xdescribe(`
`xtest(` `@Disabled` `@Ignore` `pytest.mark.skip` `t.Skip(` `#[ignore]`.

## Security

### `sensitive_code`
Mẫu glob code nhạy cảm về bảo mật, vd `src/auth/* src/payment/* */crypto/*`. Diff đụng
vào (kể cả đổi tên từ/đến) thì `review.md` phải có dòng `- Security reviewer: <tên người>`
— một NGƯỜI rà bảo mật đã đọc Lens 4 và diff; thiếu là `aw check review` chặn.
Trống = không bật luật này.

## Intake input

### `jira_key_regex`
Regex (ERE, không dùng `{n}`) của mã issue Jira. `aw input` dùng để nhận `[JIRA]` trong
tham số `/aw-intake`; `aw check intake` chặn dòng `[JIRA]` không có mã khớp.
Trống = `[A-Z][A-Z0-9]*-[0-9]+`.

### `confluence_domains`
Mẫu glob `miền[/đường-dẫn]` của Confluence, vd `wiki.cong-ty.vn *.atlassian.net/wiki`.
URL khớp → `[CONFLUENCE]`. Trống: mọi URL không phải Jira đều là `[CONFLUENCE]` (có
cảnh báo).

## Repo rules

### `rules_<phase>`
Phase: `spec` `design` `plan` `implement` `review`. Giá trị là danh sách file, vd
`rules_implement: docs/coding-style.md .claude/skills/api-pattern/SKILL.md`.
- Agent lấy danh sách bằng `aw rules <phase>` và đọc từng file. Đọc lúc chạy, không cần
  build lại adapter; việc đang làm theo quy ước tại điểm rẽ khỏi base của nó (mục
  "Location & machine overrides"), nên sửa khoá có hiệu lực cho việc sau khi merge.
- File phải **đã commit** vào base (worktree mới chỉ có file đã commit); không có hay
  chưa commit thì `aw check` của phase đó chặn. Phase gõ nhầm (vd `rules_spek`) là khoá lạ.
- `review` đối chiếu diff với **mọi** khoá: `review.md` thiếu kết luận cho file nào
  thì chặn.
- Quy tắc repo xếp dưới `spec.md`, `tdd.md`, `plan.md` và luật quy trình. Quy tắc máy
  kiểm được (lint, type, kiến trúc) nên đưa vào `LENH_KIEM_THU` thay vì viết thành văn.
