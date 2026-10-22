# Spec: SP6 — Tốc độ engine và test · SP7 — Parser YAML báo lỗi

- Ngày: 2026-10-22 · Branch: `claude/brave-heisenberg-t70jup` (PR #79)
- Roadmap § SP6, § SP7
- Interface: không đổi (hạ tầng; "no interface change: tốc độ và kiểm cú pháp file engine").

Gộp một spec vì cả hai là hạ tầng không đổi hành vi người dùng thấy; hai plan task riêng.

## SP6 — Tốc độ

**Mục tiêu.** `sh tools/run-tests.sh` ~5 phút thực / 13 phút CPU; một lần `aw check review` ~740 tiến
trình, ~125 là `git rev-parse --show-toplevel / --git-common-dir` lặp. Mục tiêu: **< 3 phút thực**
trên 4 luồng, không đổi hành vi.

**Thiết kế.**
1. **Đo trước** (ghi số vào plan ledger): thời gian từng phần, số tiến trình của `aw check review`
   trên fixture (`strace -f -c` hoặc đếm qua wrapper `git` trong PATH của test).
2. **Cache gốc repo.** Hàm `git_top <dir>` trong `tools/lib/env.sh`: nếu `AW_TOP` đã đặt và `<dir>`
   nằm dưới `AW_TOP` → in `AW_TOP`; ngược lại gọi git. Mỗi `tools/check-*.sh` và `tools/task.sh` đặt
   `AW_TOP` một lần sau khi biết thư mục việc, `export`. Thay các lời gọi
   `git -C "$x" rev-parse --show-toplevel` trong `tools/lib/*.sh` bằng `git_top "$x"`. Tương tự
   `git_common <dir>` / `AW_GITCOMMON`.
3. **Gộp ca "…đúng lý do".** 68 chỗ chạy checker hai lần (`ky_vong` rồi `dung … | grep`): đổi sang một
   lần chạy, dùng helper kiểu `vi_pham` sẵn có ở `20-…`/`22-…` (mã thoát + grep lý do trên một output).
   Đưa helper vào `tools/tests/lib.sh` (`ky_vong_ly_do <mã> <tên> <lý-do> <lệnh…>`).
4. Phần nào vẫn > 60 giây sau 2–3 → tách theo ranh fixture (`AGENTS.md` § Verify).

**Test.** Bộ test hiện có là lưới an toàn (số ca giữ nguyên hoặc tăng; mọi ca đạt). Thêm ca:
`git_top` trả `AW_TOP` khi dir nằm dưới, gọi git khi không.

## SP7 — Parser YAML báo lỗi

**Mục tiêu.** `tools/lib/md.sh` đọc tập con YAML; dòng ngoài tập con bị bỏ qua và trả rỗng — lỗi lộ
muộn (`docs/kien-truc.md` § Những chỗ thiết kế này yếu, mục 6).

**Thiết kế.** Hàm `yaml_kiem <file> fm|wf` trong `md.sh`, in `dòng N: <lý do>` cho mỗi dòng sai:
- `fm` (frontmatter giữa hai `---`): cho phép dòng trống, `#…`, `key:`, `key: value`, `key: []`,
  `  - item`. `wf` (`workflow.yaml`): thêm `  - key: value` và `    key: value` (danh sách map một cấp).
- Lỗi: thụt bằng tab; `key:value` thiếu dấu cách; thụt sâu hơn cho phép; giá trị khối `|` / `>`;
  flow `{…}` hoặc `[…]` khác `[]`; dòng không thuộc dạng nào.
- `tools/check-sdlc.sh` gọi trên `workflow.yaml` (`wf`), mọi phase, utility command có frontmatter,
  file stage, profile (`fm`), **chặn**: `<file>: dòng N: <lý do>`.

**Test** (`22-sdlc-stage-files.sh` hoặc phần mới): mỗi dạng sai → chặn đúng file + dòng; engine hiện
tại → ĐẠT; dòng chú thích / trống → ĐẠT.

**Tài liệu.** `docs/kien-truc.md` § Tập con YAML, § Những chỗ thiết kế này yếu mục 6; `docs/viec-can-lam.md`
§ Tốc độ test (xoá phần đã làm); `changes/…` (`Nội bộ`).
