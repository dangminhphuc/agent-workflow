# Spec: SP19 phần còn lại — gắn CAP/INV cho luật chưa phân loại, `Category` và hàm thư viện

- Ngày: 2026-10-23 · Branch: `claude/intelligent-volta-famesh` (chỉ spec)
- Roadmap § SP19 · spec trước: [`2026-10-22-dot-2-design.md`](2026-10-22-dot-2-design.md) § A
- `docs/kien-truc.md` § Những chỗ thiết kế này yếu mục 22
- Interface: không bỏ hay nới capability/invariant nào. Luật không có id phù hợp → **thêm**
  capability/invariant trong cùng PR (`AGENTS.md` § Making a change), không gắn đại.

## 1. Mục tiêu và phạm vi

Hiện có 223 chỗ luật chưa gắn `# giữ:` (`tools/unclassified-rules.txt`: `check-spec` 60, `check-review` 38,
`check-plan` 25, `check-design` 25, `check-intake` 20, `check-conventions` 20, `check-implement` 15,
`check-ship` 10, `task.sh` 7, `check-security` 3). Ngoài ra còn hai chỗ máy chưa đếm:

- **`Category` của checker LLM** (`workflow/checkers/spec.md` 10 dòng, `design.md` 9 dòng): mỗi loại finding
  phục vụ capability nào thì không ghi ở đâu.
- **Hàm thư viện** (`kc_*`, `tk_*`, `kt_*`, `adr_loi_*`, `toc_loi` trong `tools/lib/`): đa số in finding mà
  bên gọi gom vào `[LỖI]`/`[CẢNH BÁO]`. Hiện chỉ 14 hàm có `# giữ:`.

Mục tiêu: hạ `tools/unclassified-rules.txt` về 0, mọi `Category` mang id, rồi bắt đầu đếm hàm thư viện.
**Không gắn hàng loạt:** id có thật thì máy cho qua dù gắn nhầm, nên mỗi id phải do người đọc luật mà chọn.
Người review đọc lại từng dòng `# giữ:` trong diff.

**Ngoài phạm vi:** dòng "Interface: …" trong mô tả PR vẫn khai tay (máy đã gợi ý qua `--suy`). Đổi luật nào
từ chặn sang cảnh báo hay ngược lại cũng không thuộc dự án này.

## 2. Chia đợt (mỗi đợt một PR)

Nguyên tắc 4 của roadmap: dự án con lớn hơn một PR thì tách. Chia theo file, mỗi PR khoảng 50–60 chỗ, để
người review đọc hết được:

| Đợt | File | Chỗ |
|---|---|---|
| 19b | `check-intake.sh`, `check-conventions.sh`, `check-security.sh`, `check-ship.sh`, `task.sh` | 60 |
| 19c | `check-spec.sh` | 60 |
| 19d | `check-plan.sh`, `check-design.sh` | 50 |
| 19e | `check-implement.sh`, `check-review.sh` | 53 |
| 19f | `Category` của hai checker LLM | 19 dòng |
| 19g | Đếm hàm thư viện (mục 4) | — |

Mỗi đợt từ 19b tới 19e: gắn `# giữ:` cho từng chỗ, hạ số trong `tools/unclassified-rules.txt`
(`sh tools/check-sdlc.sh --dem-luat`), và xoá dòng của file khi số về 0.

## 3. Cách chọn id cho một chỗ luật

1. Luật giữ một invariant (`sdlc/invariants.md`) → `INV-NNN`. Nếu luật cũng là phần máy của capability thì
   ghi cả hai: `# giữ: CAP-…, INV-…`.
2. Không có invariant nào khớp → capability của **stage mà phase đang chạy** (`check-spec` → `CAP-require-*`).
3. Luật hình thức thuần (thiếu file, sai dạng heading, sai enum) phục vụ capability mà artifact đó là bằng
   chứng của → gắn capability đó. Ví dụ: `check-intake` chặn `Type` sai thì gắn `CAP-plan-01`.
4. Không có id nào đúng → dừng đợt đó, đề xuất capability/invariant mới cho người duyệt, rồi mới gắn.
   Không dùng id "gần đúng".
5. Một chỗ luật thuộc capability `human` thì vẫn gắn được: máy giữ phần hình thức, người giữ phần nội dung.
   `check-sdlc` chỉ đòi luật cho capability `machine`, nên gắn vào capability `human` không đổi kết quả của nó.

## 4. Đếm hàm thư viện (đợt 19g)

**Chỗ luật ở `tools/lib/`:** hàm có tên `kc_*`, `tk_*`, `kt_*`, `adr_loi*`, `toc_loi` (hàm trả finding,
theo quy ước đặt tên hiện có). `# giữ:` đặt ở dòng chú thích ngay trên định nghĩa hàm, như `kc_loi_thoi`
đang làm. `dem_luat` có thêm chế độ cho file thư viện: mỗi định nghĩa hàm khớp tên mà không có `# giữ:`
trong khối chú thích liền trên thì đếm là một chỗ.

**Danh sách:** thêm dòng `tools/lib/<file>.sh <n>` vào `tools/unclassified-rules.txt`, tạo bằng
`--dem-luat`. Từ đó hạ dần như các file `check-*`. Hàm thư viện mới mà không gắn thì chặn.

**Test** (`tools/tests/23-sdlc-syntax.sh`):
- hàm `kc_x` mới không có `# giữ:` thì KHÔNG ĐẠT;
- có `# giữ: INV-006` thì ĐẠT;
- hàm tên khác (`qu_*`, `khop_*`) không bị đếm;
- `--dem-luat` in dòng của file lib.

## 5. `Category` (đợt 19f)

- Bảng "Look for" của `workflow/checkers/*.md` thêm cột `Serves`: một hoặc nhiều id, cách nhau dấu phẩy.
  Ví dụ: `quote-misread` → `CAP-require-01`, `unflagged-ambiguity` → `CAP-require-02`.
- `check-sdlc.sh` chặn khi một dòng bảng thiếu `Serves`, khi id không tồn tại, và khi id thuộc stage khác
  stage của phase dùng checker (phase khai `llm_checker:`).
- Checker LLM không đọc cột này lúc chạy: cột chỉ để người và máy truy vết. Thêm một cột không đổi output
  của checker. Test adapter (`AW_COMPARE=1`) vẫn phải giống hệt giữa các adapter.
- **Test** (`23-sdlc-syntax.sh`): thiếu `Serves` → chặn; id lạ → chặn; id của stage khác → chặn; bảng đúng
  → đạt.

## 6. Tài liệu

- `docs/interface-sdlc.md`: mục `# giữ:`, thêm hàm thư viện và cột `Serves`.
- `docs/kien-truc.md` mục 22: bước A đã phủ hết luật.
- Roadmap: SP19 thành `xong` sau đợt 19g.
- `changes/<branch>.md`, mục `Nội bộ`, cho từng đợt.

## 7. Cần người duyệt

- Chia đợt như bảng ở mục 2, hay gộp 19b–19e thành ít PR hơn.
- Có chặn `Serves` của stage khác hay không. Một checker phục vụ capability của stage trước (`design` kiểm
  lại REQ) thì luật này chặn nhầm. Đề xuất: chặn; khi gặp ca thật thì thêm ngoại lệ có lý do.
