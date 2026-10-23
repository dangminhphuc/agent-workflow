# Spec: SP23 — Dọn nhánh remote và số liệu cũ trên roadmap

- Ngày: 2026-10-23 · Branch: `claude/intelligent-volta-famesh`
- Interface: không đổi. Việc này dọn repo và tài liệu, không đổi engine.

## 1. Số liệu cũ trên roadmap (làm trong PR này)

Roadmap § Việc nhỏ ghi bộ test có 1775 ca, chạy khoảng 5 phút trên 6 luồng, chưa đạt mục tiêu dưới 3 phút,
và phần dài nhất là `21-sdlc-profiles` (103 giây).

Đo lại ngày 2026-10-23 trên `main` (8824ded):

- 1804 ca đạt, **2 phút 41 giây trên 4 luồng**;
- phần dài nhất là `23-sdlc-syntax` (36 giây), rồi `21-sdlc-profiles`, `15-conventions-task`,
  `08-adapters` (mỗi phần khoảng 34 giây);
- không phần nào tới ngưỡng `CẢNH BÁO … nên tách`.

Máy đo khác nên không so trực tiếp với số cũ. Sửa dòng đó theo số mới. Mục tiêu dưới 3 phút đã đạt trên máy
này; giữ dòng để theo dõi trên CI.

## 2. Nhánh remote (người làm, sau khi duyệt danh sách)

Ngày 2026-10-23 remote có 59 nhánh ngoài `main`. Không có PR nào đang mở.

**A. 42 nhánh đã nằm trọn trong `main`** (`git merge-base --is-ancestor <nhánh> origin/main`). Xoá không
mất gì. Lệnh để in danh sách:

```sh
git fetch --prune origin
for b in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v -e HEAD -e '^origin/main$' -e '^origin$'); do
  git merge-base --is-ancestor "$b" origin/main && echo "${b#origin/}"
done
```

Người đọc danh sách in ra rồi xoá bằng `git push origin --delete <nhánh>…`, hoặc qua giao diện GitHub. Nên
bật "Automatically delete head branches" trong cài đặt repo để không phải dọn lại.

**B. 15 nhánh chưa nằm trong `main` nhưng PR của chúng đã đóng** (PR #4 tới #26): `fervent-hopper-ykmmi7`,
`festive-meitner-2tor8f`, `funny-fermi-h7gp14`, `funny-fermi-h7gp14-version-ci`, `gifted-faraday-pcoya9`,
`hopeful-bohr-sbvhwl`, `kind-feynman-lbu180`, `laughing-pascal-ps9kva`, `serene-curie-2yyiix`,
`sharp-ritchie-t8ivhl`, `tender-cori-9h44b3`, `vigilant-planck-30xxlh`, `youthful-ptolemy-8vbtew` (tiền tố
`claude/`), `feat_quy-tac-repo`, `release_2026.10.9`.

Đây là các nhánh phát hành hoặc tính năng từ 03 đến 07/10. Nội dung đã vào `main` bằng merge hay chép lại,
nên commit hash khác. Mỗi nhánh kiểm một lần:

- nhánh phát hành thì tag tương ứng phải có (`git tag -l 2026.10.*`);
- nhánh tính năng thì thông điệp commit cuối phải có mục tương ứng trong `CHANGELOG.md`.

Khớp thì xoá. Không khớp thì chuyển nhánh đó sang nhóm C.

**C. Không xoá trong dự án này:** `claude/light-lane-mr-artifacts` (làn light cho bugfix,
`mr_include_artifacts`) và `claude/tender-mccarthy-3fxmrt` (điểm mù nêu User story + AC). Hai nhánh này
không có PR, và tính năng của chúng chưa có trên `main`. Lấy lại hay bỏ là việc người chủ engine quyết. Ghi
chúng vào roadmap thành SP24, trạng thái `chặn` (mục 3), không viết spec.

## 3. Roadmap

- Bảng thêm SP19 (spec phần còn lại) và SP20–SP23, trạng thái `đang làm` (có spec).
- SP24 "Hai nhánh tính năng chưa merge" có một dòng trong bảng và một mục ở § Chi tiết với **Vấn đề**,
  **Hướng**, **Cần quyết**, theo § Cách dùng.

## 4. Tài liệu

Chỉ roadmap. `changes/<branch>.md`, mục `Nội bộ`.
