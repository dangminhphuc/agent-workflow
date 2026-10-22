# Spec: SP8 — Glob `**` cho phạm vi kế hoạch (giai đoạn chuyển tiếp)

- Ngày: 2026-10-22 · Branch: `claude/brave-heisenberg-t70jup` (PR #79)
- Roadmap § SP8 · `docs/kien-truc.md` § Những chỗ thiết kế này yếu mục 9, 21
- Interface: không đổi (cách khớp mẫu; `CAP-implement-04/05` giữ nguyên nghĩa).

## 1. Mục tiêu và phạm vi

`khop_glob` dùng `case`: `*` khớp cả `/`, không có `**` — `src/*` rộng hơn người đọc tưởng.

**Ruling khi thiết kế (người duyệt xác nhận):** chỉ đổi nghĩa glob trong **`plan.md`** (`Expected files`,
cột "Extra files" của `Unplanned`, và phạm vi luật `BR-` suy từ đó). Glob của `conventions.md`
(`production_code`, `test_files`, `knowledge_files`, `branch_patterns`…) **giữ nghĩa cũ**: file do
người viết, engine không ghi đè, và mẫu mặc định (`*/ARCHITECTURE.md`, `*/test/*`) đang dựa vào `*`
qua `/` — đổi sẽ làm hỏng repo đích âm thầm.

**Hai bước (đã chốt "đổi, có chuyển tiếp"):**
- **Bản này:** thêm `**`; `*` vẫn khớp qua `/` nhưng mỗi lần một file chỉ khớp nhờ `*` vượt `/` thì
  **cảnh báo**.
- **Bản sau** (ghi vào `docs/viec-can-lam.md`, không làm trong PR này): `*` không qua `/`.

## 2. Thiết kế

- Hàm `khop_duong <đường-dẫn> <mẫu…>` trong `md.sh`: chuyển mẫu sang ERE trong awk — `**` → `.*`,
  `*` → `[^/]*`, `?` → `[^/]`, ký tự khác escape — khớp cả chuỗi. (mawk-safe: không `{n}`.)
- Hàm `khop_ke_hoach <đường-dẫn> <mẫu…>` (cho glob của `plan.md`): khớp nếu `khop_duong` khớp
  **hoặc** `khop_glob` (nghĩa cũ) khớp; nếu chỉ nghĩa cũ khớp → in ra stdout một dòng cảnh báo để
  bên gọi gom vào khối CẢNH BÁO của nó:
  `CẢNH BÁO: \`src/a/b.ts\` chỉ khớp \`src/*\` nhờ * vượt thư mục — bản sau * không qua /; viết \`src/**\`.`
- Đổi chỗ gọi: `kc_pham_vi` (cross-check), `luat_pham_vi` (rule.sh), kiểm phạm vi theo task và đếm
  glob rộng của SP3. Cảnh báo chuyển tiếp **chỉ cảnh báo** cả ở implement lẫn review (không phải luật
  chặn mới).
- Template `plan.md` ghi chú: "`**` khớp qua `/`; `*` hiện vẫn khớp qua `/` (sắp đổi — dùng `**`)".
  `03-plan.md`: dùng `**` khi cần đệ quy.

## 3. Test

Bảng khớp `khop_duong`: `src/*` vs `src/a.ts` (khớp), `src/a/b.ts` (không); `src/**` vs cả hai (khớp);
`**/x.md` vs `a/b/x.md`; ký tự đặc biệt `.`, `+`, `(` trong tên; `khop_ke_hoach` trả khớp + cảnh báo
cho `src/*` vs `src/a/b.ts`; `aw check implement` in cảnh báo chuyển tiếp, nhãn không đổi; glob
`conventions.md` không đổi kết quả (ca hiện có).

## 4. Tài liệu

Template `plan.md`, `03-plan.md`; `docs/huong-dan.md` § Phase 03; `docs/kien-truc.md` mục 9, 21;
`docs/viec-can-lam.md` (bước 2: đổi nghĩa `*`); `changes/…` (`Thêm`: `**`; cảnh báo chuyển tiếp).
