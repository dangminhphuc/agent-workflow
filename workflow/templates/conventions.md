# Quy ước của repo

> File này do **NGƯỜI** viết. Nằm ở `.git/agent-workflow/conventions.md` của bản
> clone — không commit, dùng chung mọi worktree. `aw init` chỉ tạo nó một lần từ
> mẫu và **không bao giờ ghi đè**, kể cả với `--force`. Chia sẻ cho team: repo
> cấu hình riêng + `aw init --from <url>`.

## Phần máy đọc

Khối dưới được script đọc bằng awk. Mỗi dòng `khoá: giá trị`; danh sách cách nhau
bằng dấu cách. Trong mẫu glob, `*` khớp cả `/` (vd `src/*` khớp `src/a/b.ts`).

```conventions
mau_branch: feat_* fix_* refactor_* perf_* chore_*
loai_theo_tien_to: feat_=feature fix_=bugfix refactor_=refactor perf_=perf chore_=chore
nhanh_goc: main
thu_muc_worktree: ../{repo}.wt/{ten}
mau_nhanh_phat_hanh:
bo_qua: package-lock.json yarn.lock pnpm-lock.yaml
mau_file_test: *.test.* *.spec.* *_test.* test/* tests/*
the_covers: covers:
mau_code_production: src/*
mau_file_dependency: package.json package-lock.json yarn.lock pnpm-lock.yaml
mau_jira: [A-Z][A-Z0-9]*-[0-9]+
mien_confluence:
quy_tac_spec:
quy_tac_design:
quy_tac_plan:
quy_tac_implement:
quy_tac_review:
```

| Khoá | Dùng cho |
|---|---|
| `mau_branch` | Branch khớp mẫu thì tên branch là tên feature → artifact ở `.agent-workflow/<tên-branch>/` |
| `nhanh_goc` | Nhánh checkout chính luôn đứng; ứng viên base chính khi tạo worktree. Checker so diff với **base ghi trong `intake.md`**, chỉ quay về khoá này khi intake chưa có dòng Base |
| `thu_muc_worktree` | Mẫu đường dẫn worktree, tương đối với gốc repo (hoặc tuyệt đối). `{repo}` = tên repo gốc, `{ten}` = tên branch (`/` → `_`). Phải nằm **ngoài** repo. Mỗi máy ghi đè được bằng biến môi trường `AW_THU_MUC_WORKTREE` |
| `mau_nhanh_phat_hanh` | Mẫu glob nhánh phát hành, vd `release/*`. `aw worktree new` liệt kê làm ứng viên base (bugfix gấp); base khớp mẫu này thì review không cảnh báo |
| `bo_qua` | File thay đổi mà không cần nằm trong "Expected files" (lockfile, file sinh tự động…) |
| `mau_file_test` | File nào là file test — để tìm tag `covers:` |
| `the_covers` | Chuỗi đứng trước mã YC trong test, vd `// covers: YC-001, YC-002` |
| `loai_theo_tien_to` | Tiền tố branch → loại việc. `/intake` dùng để gợi ý; loại trong `intake.md` lệch tiền tố thì cảnh báo, `review` chặn |
| `mau_code_production` | Code chạy trên production. `chore` đụng vào là chặn; `bugfix`/`perf` đo "trước" thì chưa được đụng |
| `mau_file_dependency` | Manifest/lockfile. `chore` đụng vào thì `plan.md` phải có bảng "Dependency upgrades" |
| `mau_jira` | Regex (ERE, không dùng `{n}`) của mã issue Jira. `aw input` dùng để nhận `[JIRA]` trong tham số `/intake`; `aw check intake` chặn dòng `[JIRA]` không có mã khớp |
| `quy_tac_<phase>` | Quy tắc riêng của repo cho phase đó (`spec` `design` `plan` `implement` `review`): danh sách file, đường dẫn tương đối với gốc repo, không chứa dấu cách — vd `quy_tac_implement: docs/coding-style.md .claude/skills/api-pattern/SKILL.md`. Agent lấy danh sách bằng `aw rules <phase>` và đọc từng file. File phải **đã commit** vào base (worktree mới chỉ có file đã commit); không có hay chưa commit thì `aw check` của phase đó chặn. `review` đối chiếu diff với **mọi** khoá: `review.md` thiếu kết luận cho file nào thì chặn. Quy tắc repo xếp dưới `spec.md`, `tdd.md`, `plan.md` và luật quy trình. Quy tắc máy kiểm được (lint, type, kiến trúc) nên đưa vào `LENH_KIEM_THU` thay vì viết thành văn |
| `mien_confluence` | Mẫu glob `miền[/đường-dẫn]` của Confluence, vd `wiki.cong-ty.vn *.atlassian.net/wiki`. URL khớp → `[CONFLUENCE]`. Bỏ trống: mọi URL không phải Jira đều là `[CONFLUENCE]` (có cảnh báo) |

## Phần người đọc

<Quy ước đặt tên branch cụ thể của team, ví dụ: `feat_<mô-tả>` cho tính năng,
`refactor_<mô-tả>` cho refactor; `<mô-tả>` không nhất thiết là mã Jira.>

Worktree là bắt buộc: checkout chính luôn đứng ở `nhanh_goc` và chỉ dùng để chạy
`/intake`; mỗi việc làm trong worktree riêng (`aw worktree new`), dọn bằng
`aw worktree remove` sau khi merge.

### Commit message

<Chưa định nghĩa. Quy ước viết commit message của team: định dạng tiêu đề,
có gắn mã Jira hay không, phần thân, ví dụ.>

### Merge request

> Mặc định của engine — sửa cho đúng team. Áp dụng như nhau cho MR (GitLab) và
> PR (GitHub). Heading và nhãn trong mô tả MR viết tiếng Anh.

**Scope.** Một MR = một việc = một branch theo `mau_branch`. Diff nên dưới ~400
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

**Target branch.** `nhanh_goc`. Hotfix vào nhánh khớp `mau_nhanh_phat_hanh` thì
phải có MR cherry-pick ngược về `nhanh_goc`, link trong mô tả.

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
