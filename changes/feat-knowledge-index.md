### Thêm
- **Chỉ mục kiến thức chung** — khoá `knowledge_index` (conventions.md, mặc định
  `docs/knowledge-index.md`, khai trống = tắt). `aw knowledge index` dựng lại bảng
  `| Ref | Kind | Scope | Status | Summary |` từ ADR, khối luật `BR-` và các mục khai `- Scope:`
  của tài liệu module; phần người viết phía trên bảng giữ nguyên. `aw adr promote` và
  `aw rule promote` dựng lại chỉ mục tự động khi file đã có. Repo cũ không bị ép: chỉ kiểm khi file
  chỉ mục đã commit; chưa có thì phase đọc như trước (chỉ mục ADR).
- **`aw knowledge check [<dir>]`** — so bảng chỉ mục với bản dựng lại. Chạy một mình hoặc trong
  `aw check implement` / `aw check review`: diff đụng tài liệu kiến thức (thư mục ADR, thư mục
  luật, file khớp `knowledge_files`) hay đụng file chỉ mục mà bảng lệch → KHÔNG ĐẠT, chạy
  `aw knowledge index` để sửa. Diff không đụng → không kiểm, kể cả bảng hỏng sẵn trên base.
  Heading `##` trùng trong một file `knowledge_files` bị chặn ở đây (trước đây chỉ cảnh báo ở
  phase — cảnh báo cũ vẫn giữ).

### Thay đổi
- **`aw knowledge design` / `aw knowledge implement`** in đường dẫn chỉ mục chung thay
  `<knowledge_adr_dir>/README.md` khi file chỉ mục đã commit.
- **Khoá `knowledge_index`** thêm vào mẫu `conventions.md` (bật sẵn giá trị mặc định) và
  `aw conventions check` kiểm dạng: đường dẫn tương đối trong repo, kết thúc `.md`.
- Phase `01-spec`, `02-design` đọc chỉ mục chung trước khi khảo sát (mục `adr`/`module` có thể
  ràng buộc yêu cầu mới).

### Nội bộ
- Bất biến mới **INV-013** (index máy dựng phải khớp dựng lại) trong `sdlc/invariants.md`,
  khai ở stage `implement` và `verify`; tag `# giữ: INV-013` ở `tools/check-implement.sh`,
  `tools/check-review.sh`, `tools/check-conventions.sh`.
- Thư mục test riêng `tools/tests/29-knowledge-index.sh` — fixture riêng để các part lân cận không
  chạy quá ngưỡng `CẢNH BÁO` (cách SP27 tách `28-`).