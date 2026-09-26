# Quy ước của repo

> File này do **NGƯỜI** viết. Bộ cài chỉ tạo nó một lần từ mẫu và **không bao
> giờ ghi đè**, kể cả với `--force`.

## Phần máy đọc

Khối dưới được script đọc bằng awk. Mỗi dòng `khoá: giá trị`; danh sách cách nhau
bằng dấu cách. Trong mẫu glob, `*` khớp cả `/` (vd `src/*` khớp `src/a/b.ts`).

```conventions
mau_branch: feat_* fix_* refactor_* chore_*
nhanh_goc: main
bo_qua: package-lock.json yarn.lock pnpm-lock.yaml
mau_file_test: *.test.* *.spec.* *_test.* test/* tests/*
the_covers: covers:
```

| Khoá | Dùng cho |
|---|---|
| `mau_branch` | Branch khớp mẫu thì tên branch là tên feature → artifact ở `.agent-workflow/<tên-branch>/` |
| `nhanh_goc` | So diff với nhánh này để kiểm phạm vi |
| `bo_qua` | File thay đổi mà không cần nằm trong "File dự kiến" (lockfile, file sinh tự động…) |
| `mau_file_test` | File nào là file test — để tìm tag `covers:` |
| `the_covers` | Chuỗi đứng trước mã YC trong test, vd `// covers: YC-001, YC-002` |

## Phần người đọc

<Quy ước đặt tên branch cụ thể của team, ví dụ: `feat_<mô-tả>` cho tính năng,
`refactor_<mô-tả>` cho refactor; `<mô-tả>` không nhất thiết là mã Jira.>
