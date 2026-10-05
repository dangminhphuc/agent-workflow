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
```

| Khoá | Dùng cho |
|---|---|
| `mau_branch` | Branch khớp mẫu thì tên branch là tên feature → artifact ở `.agent-workflow/<tên-branch>/` |
| `nhanh_goc` | Nhánh checkout chính luôn đứng; ứng viên base chính khi tạo worktree. Checker so diff với **base ghi trong `intake.md`**, chỉ quay về khoá này khi intake chưa có dòng Base |
| `thu_muc_worktree` | Mẫu đường dẫn worktree, tương đối với gốc repo (hoặc tuyệt đối). `{repo}` = tên repo gốc, `{ten}` = tên branch (`/` → `_`). Phải nằm **ngoài** repo. Mỗi máy ghi đè được bằng biến môi trường `AW_THU_MUC_WORKTREE` |
| `mau_nhanh_phat_hanh` | Mẫu glob nhánh phát hành, vd `release/*`. `aw worktree new` liệt kê làm ứng viên base (bugfix gấp); base khớp mẫu này thì review không cảnh báo |
| `bo_qua` | File thay đổi mà không cần nằm trong "File dự kiến" (lockfile, file sinh tự động…) |
| `mau_file_test` | File nào là file test — để tìm tag `covers:` |
| `the_covers` | Chuỗi đứng trước mã YC trong test, vd `// covers: YC-001, YC-002` |
| `loai_theo_tien_to` | Tiền tố branch → loại việc. `/intake` dùng để gợi ý; loại trong `intake.md` lệch tiền tố thì cảnh báo, `review` chặn |
| `mau_code_production` | Code chạy trên production. `chore` đụng vào là chặn; `bugfix`/`perf` đo "trước" thì chưa được đụng |
| `mau_file_dependency` | Manifest/lockfile. `chore` đụng vào thì `plan.md` phải có bảng "Nâng dependency" |
| `mau_jira` | Regex (ERE, không dùng `{n}`) của mã issue Jira. `aw input` dùng để nhận `[JIRA]` trong tham số `/intake`; `aw check intake` chặn dòng `[JIRA]` không có mã khớp |
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

<Chưa định nghĩa. Quy ước tạo MR: tiêu đề, mô tả (mẫu), người review, nhánh
đích, điều kiện trước khi merge.>
