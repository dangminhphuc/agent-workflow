# Spec: SP20 — Kiểm frontmatter `based_on` của artifact ở repo đích

- Ngày: 2026-10-23 · Branch: `claude/intelligent-volta-famesh` (chỉ spec)
- `docs/kien-truc.md` § Những chỗ thiết kế này yếu mục 6
- Interface: siết **INV-006** (Output is built from the current version of its input). Phần đổi là
  `Engine:` / `Enforced by:` / `Tested by:`; câu `Rule:` giữ nguyên. Không nới gì.

## 1. Vấn đề

`spec.md`, `tdd.md`, `plan.md` mang frontmatter `based_on`, do `aw based-on` ghi. `kc_loi_thoi`
(`tools/lib/cross-check.sh`) đọc nó bằng `fm_list`. Tập con YAML đọc sai thì trả về **rỗng**, không báo
lỗi. Kết quả là kiểm lỗi thời (INV-006) **im lặng cho qua**:

| Ca | Ví dụ | Hiện tại |
|---|---|---|
| Danh sách viết kiểu flow | `based_on: [spec.md@123]` | `fm_list` rỗng → không kiểm |
| Thụt bằng tab, thiếu dấu cách sau `-` | `\t- spec.md@123` | rỗng hoặc bỏ mục |
| Thiếu dòng `---` đóng | — | cả file bị coi là frontmatter |
| Mục sai dạng | `- spec.md` (không có `@hash`), `- spec.md@abc` | `_cu` = cả chuỗi → báo "stale" sai lý do, hoặc không khớp gì |
| Quên chạy `aw based-on` | template còn `based_on: []` | không có gì để kiểm |

Ba dòng đầu thường do agent tự sửa frontmatter thay vì chạy lệnh. Dòng cuối là bước 14/4/6 của phase
(`Record inputs`) bị bỏ qua.

## 2. Thiết kế

Hàm mới `kc_fm_hong <thư-mục-feature>` trong `cross-check.sh`, gắn `# giữ: INV-006`. Với mỗi
`spec.md`, `tdd.md`, `plan.md` có trong thư mục:

1. Dòng 1 là `---` mà không có dòng `---` đóng → `"<file>: frontmatter thiếu dòng --- đóng"`.
2. `yaml_kiem <file> fm` (`tools/lib/md.sh`, đã dùng cho file của engine) có dòng nào thì in
   `"<file>: frontmatter <dòng N: lý do>"`.
3. Mỗi mục `based_on` phải đúng dạng `<tên-file>@<số>`, vì `file_hash` là `cksum`, ra số thập phân. Sai thì
   `"<file>: based_on \"<mục>\" sai dạng — chạy lại aw based-on, không sửa tay"`.

Cả ba là luật chính xác (không báo nhầm) nên **chặn** ở mọi checker đang gọi `kc_loi_thoi`: `check-design`,
`check-plan`, `check-implement`, `check-review`. Riêng `check-spec` thì kiểm `spec.md`.

**Thiếu `based_on`** (rỗng, hoặc thiếu đầu vào bắt buộc) là luật thứ hai, hàm `kc_based_on_thieu`, cũng
`# giữ: INV-006`. Đầu vào bắt buộc lấy từ bước `Record inputs` của phase:

- `spec.md` ← `intake.md`;
- `tdd.md` ← `spec.md`, `open-questions.md`;
- `plan.md` ← `spec.md`, thêm `tdd.md` trừ khi bỏ design (`kc_bo_design`).

Luật này **cảnh báo** ở design/plan/implement và **chặn** ở review, cùng kiểu với lỗi thời
(`Rule:` của INV-006). Lý do: phase hiện tại có thể đang chạy dở, chưa tới bước ghi.

Bảng đầu vào chỉ có một nguồn. Đề xuất dùng hàm `kc_dau_vao <artifact>` trong `cross-check.sh`; ba file
phase vẫn ghi lệnh `aw based-on …` như cũ. Test so hai nơi để chúng không lệch nhau.

## 3. Test

Ca thêm vào `tools/tests/06-review-freshness.sh`, cùng chủ đề INV-006:

- `based_on: [spec.md@1]` trong `plan.md` → `aw check plan` KHÔNG ĐẠT, nêu dòng.
- Thụt tab → KHÔNG ĐẠT.
- Thiếu `---` đóng → KHÔNG ĐẠT.
- Mục `spec.md` không có `@` → KHÔNG ĐẠT.
- Frontmatter do `aw based-on` ghi → ĐẠT, không có cảnh báo mới.
- `plan.md` còn `based_on: []`: `aw check implement` chỉ cảnh báo, `aw check review` KHÔNG ĐẠT.
- Chore (bỏ design): `plan.md` không có `tdd.md` trong `based_on` → không cảnh báo.
- `kc_dau_vao` khớp lệnh `aw based-on` trong `workflow/phases/01-spec.md`, `02-design.md`, `03-plan.md`.

Ca thêm vào `20-sdlc-conformance.sh` hoặc `22-sdlc-stage-files.sh` (theo chỗ đang kiểm INV-006): `Tested by:`
của INV-006 trỏ đúng tên ca mới.

## 4. Tài liệu và tương thích

- **Việc đang dở:** frontmatter tự sửa sai sẽ bị chặn từ bản này. Cách sửa: chạy lại `aw based-on …`.
  Ghi vào `changes/…`, mục `Thay đổi`.
- `docs/kien-truc.md` mục 6: frontmatter artifact ở repo đích đã được kiểm.
- `docs/huong-dan.md`: phần lỗi thường gặp có thông báo mới.
- `sdlc/invariants.md` INV-006: `Enforced by:` / `Tested by:`.

## 5. Cần người duyệt

- Mức chặn/cảnh báo như mục 2. Đề xuất: sai dạng thì chặn ở mọi nơi; thiếu thì cảnh báo trước review, chặn
  ở review.
