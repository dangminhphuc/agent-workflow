# Repository conventions

> File này do **NGƯỜI** viết. Nằm ở `docs/agent-workflow/conventions.md` của repo,
> sửa và commit qua PR như mọi thay đổi khác — cả team dùng chung một bản. `aw init`
> chỉ tạo nó một lần từ mẫu và **không bao giờ ghi đè**, kể cả với `--force`. Riêng
> `worktree_dir` được ghi đè theo máy ở `.git/agent-workflow/conventions.md`.

## Machine-readable

Sửa giá trị trong khối dưới. Mỗi khoá có chú thích một dòng; giải thích đầy đủ,
cú pháp glob/regex và mặc định khi để trống: xem
`.agent-workflow/.engine/templates/conventions-reference.md`.

Nhãn chú thích: **[edit]** phải xem lại cho đúng repo · **[default]** dùng được
ngay · **[optional]** để trống = tắt luật hoặc dùng mặc định của engine.
Kiểm file sau khi sửa: `aw conventions check`.

```conventions
# ── Branches & worktrees ──────────────────────────────────────────
# [edit] nhánh checkout chính luôn đứng; base mặc định của việc mới
base_branch: main
# [default] branch khớp mẫu → tên branch là tên feature
branch_patterns: feat_* fix_* refactor_* perf_* chore_*
# [default] tiền tố branch = loại việc (feature bugfix refactor perf chore)
type_by_prefix: feat_=feature fix_=bugfix refactor_=refactor perf_=perf chore_=chore
# [default] vị trí worktree, phải ngoài repo; {repo} {ten} được thay
worktree_dir: ../{repo}.wt/{ten}
# [optional] glob nhánh phát hành, vd release/*
release_branches:

# ── Merge requests ────────────────────────────────────────────────
# [optional] glob nhánh đích MR theo thứ tự hiện, vd develop uat/* main (trống = base_branch)
mr_target_branches:
# [optional] github | gitlab (trống = đoán từ URL origin)
mr_platform:

# ── File classes (đường dẫn tính từ gốc repo; * khớp cả /) ────────
# [edit] code chạy production — test đặt cạnh code cũng bị tính là production
production_code: src/*
# [edit] file test; test/* chỉ khớp ở gốc repo, monorepo thêm */test/*
test_files: *.test.* *.spec.* *_test.* test/* tests/*
# [edit] manifest/lockfile — chore đụng vào phải khai "Dependency upgrades"
dependency_files: package.json package-lock.json yarn.lock pnpm-lock.yaml
# [default] file đổi không cần nằm trong "Expected files" (lockfile, file sinh)
ignored_files: package-lock.json yarn.lock pnpm-lock.yaml

# ── Test ──────────────────────────────────────────────────────────
# [default] chuỗi trước mã YC trong test, vd // covers: YC-001
covers_tag: covers:
# [optional] regex ERE test bị tắt/chạy riêng (trống = .only( .skip( @Disabled …)
skipped_test_regex:

# ── Security ──────────────────────────────────────────────────────
# [optional] glob code nhạy cảm, vd src/auth/* — đụng vào cần NGƯỜI rà bảo mật
sensitive_code:

# ── Intake input ──────────────────────────────────────────────────
# [default] regex ERE mã Jira, không dùng {n}
jira_key_regex: [A-Z][A-Z0-9]*-[0-9]+
# [optional] glob miền Confluence, vd wiki.cong-ty.vn *.atlassian.net/wiki
confluence_domains:

# ── Durable knowledge (kiến thức bền trong repo, agent đọc qua `aw knowledge`) ──
# [default] thư mục ADR: aw adr promote ghi vào, phase design đọc chỉ mục README.md
knowledge_adr_dir: docs/adr
# [default] glob tài liệu module đã commit; phạm vi của mỗi file = thư mục chứa nó
knowledge_files: */ARCHITECTURE.md

# ── Repo rules (file đã commit, agent đọc qua `aw rules`) ─────────
# [optional] vd rules_implement = docs/coding-style.md .claude/skills/x/SKILL.md
rules_spec:
rules_design:
rules_plan:
rules_implement:
rules_review:
```

## Team conventions

<Quy ước đặt tên branch cụ thể của team, ví dụ: `feat_<mô-tả>` cho tính năng,
`refactor_<mô-tả>` cho refactor; `<mô-tả>` không nhất thiết là mã Jira.>

Worktree là bắt buộc: checkout chính luôn đứng ở `base_branch` và chỉ dùng để chạy
`/aw-intake`; mỗi việc làm trong worktree riêng (`aw worktree new`). Gửi MR bằng
`/aw-ship` trong worktree; sau khi merge, `/aw-ship` ở checkout chính dọn worktree và
branch (`aw ship sweep`). Việc không qua `/aw-ship` thì dọn bằng `aw worktree remove`.

### Commit message

<Chưa định nghĩa. Quy ước viết commit message của team: định dạng tiêu đề,
có gắn mã Jira hay không, phần thân, ví dụ.>

### Merge request

> Mặc định của engine — sửa cho đúng team. Áp dụng như nhau cho MR (GitLab) và
> PR (GitHub). Heading và nhãn trong mô tả MR viết tiếng Anh.

**Scope.** Một MR = một việc = một branch theo `branch_patterns`. Diff nên dưới ~400
dòng (không tính lockfile, file sinh, test); lớn hơn thì tách theo task trong
`plan.md` hoặc ghi lý do trong mô tả. Refactor đi kèm tính năng tách MR riêng.

**Title.** `<JIRA-KEY>: <verb> <what> <where>`, dưới 72 ký tự, nói hành vi đổi
chứ không nói việc đã làm.
- Good: `VPAY-17318: lấy agentType từ bản ghi khi tạo ticket sửa Master Data`
- Bad: `fix bug`, `update UpdateTicket`, `VPAY-17318`
- Chưa sẵn sàng review: tiền tố `Draft:` (GitLab) / draft PR (GitHub).

**Description.** Theo mẫu `.agent-workflow/.engine/templates/merge-request.md`
(chép vào khi `aw adapter build`). Required: `Problem`, `Changes`, `Testing`.
Các mục còn lại không xoá — không áp dụng thì ghi `None`. Phải nêu nổi bật:
- **Breaking change:** API, payload, schema, event đổi và ai đang phụ thuộc;
- **External impact:** hệ thống ngoài phạm vi ticket, kèm đã xác nhận với ai;
- **Out of scope:** điều ticket kỳ vọng mà MR không làm (backfill, phần FE…);
- **Deployment order:** khi có phụ thuộc;
- **Changed expectations:** test cũ bị đổi kỳ vọng.

**Target branch.** Một trong `mr_target_branches` (bỏ trống: `base_branch`) — người
chọn khi chạy `/aw-ship`. Hotfix vào nhánh khớp `release_branches` thì
phải có MR cherry-pick ngược về `base_branch`, link trong mô tả.

**Reviewers.** Ít nhất <1> người ngoài tác giả; MR có breaking change hoặc
external impact thêm người của bên phụ thuộc. Tác giả không tự duyệt.

**Ready for review.**
- `aw check review` đạt, `review.md` không còn mục `Chặn`.
- CI xanh; branch đã cập nhật với target branch.
- Tự đọc lại diff trên giao diện MR (không chỉ trong editor).

**Ready to merge.**
- Đủ approve; mọi thread đã trả lời hoặc resolve — không resolve thread của
  người khác khi chưa trả lời.
- CI xanh trên commit cuối.
- Các mục trong `Deployment` đã sẵn sàng (hoặc ghi rõ đã thống nhất merge trước).
- **Merge strategy:** <squash | merge commit> — <squash: commit title = MR title>.

**After merge.** Đánh dấu checkbox ở `Post-deploy Verification`; mục nào hỏng thì
mở ticket mới và link vào MR, không sửa lặng lẽ.
