# Đề xuất — kiến thức bền của repo đích vào git

> Ghi chú tạm. Mọi D-xx đã duyệt theo Đề xuất. Lý do của phần đã làm (PR 1: D-00, D-01,
> D-02, D-03, D-09) đã chuyển vào `docs/kien-truc.md`, mục "Trạng thái của việc và kiến thức
> bền"; phần còn lại chuyển khi làm PR tương ứng. Xoá file này sau PR 5.

Mục **Đề xuất** của từng D là phương án đã chốt.

## Phần A — Mâu thuẫn giữa nhiệm vụ và code/tài liệu hiện tại

Mỗi mâu thuẫn được giải bằng một D ở phần B (ghi ở cột cuối).

| # | Nhiệm vụ nói | Hiện tại | Hệ quả nếu làm đúng chữ | Giải ở |
|---|---|---|---|---|
| M1 | Commit `conventions.md` vào repo đích | README: "Không cài gì vào repo đích"; `kien-truc.md` § "Engine có version, cài ngoài repo" lý do 1 (protected branch); `aw init` in "Không có file nào cần commit"; bộ cài cũ từng commit `.agent-workflow/conventions.md` và đã bị bỏ | Đảo ngược một quyết định có ghi lý do. Sửa quy ước sẽ phải qua PR | D-00 |
| M2 | Engine đọc "file đã commit trong repo đích" | Mọi việc chạy trong worktree; file trong worktree là bản agent sửa được | Việc đang làm tự nới luật của chính nó (xoá `sensitive_code`, đổi `test_files`…) rồi checker chấm theo luật đã nới. Trái với "Agent không tự duyệt" và "Việc đang làm không đổi luật" | D-03 |
| M3 | `aw adr promote` chạy "sau review đạt, trước ship", ghi vào worktree | `kiem-tra-ra-soat.sh` chặn khi `Reviewed tree` khác cây hiện tại; `aw check ship` chạy lại checker review; `aw ship create` chặn khi worktree còn thay đổi chưa commit; file ngoài "Expected files" là phạm vi diff lạ | Thêm ADR sau review → review lỗi thời → ship luôn bị chặn | D-04 |
| M4 | BR có `Source: [CONFLUENCE\|JIRA\|FILE\|HUMAN] <định danh> v<version>` | Nhãn YC trong spec là `CONFLUENCE / JIRA / FILE / INFERRED / OPEN-QUESTION` — không có `HUMAN`. Lời người nằm ở `intake.md`, YC trỏ `[FILE] intake.md`; điểm mù đã trả lời trỏ `[FILE] open-questions.md § …`. Chỉ bảng nguồn có cột "Phiên bản" | BR nâng từ những YC này trỏ tới file là **trạng thái của việc** — biến mất khi việc xong. Lời người không có version | D-07 |
| M5 | ADR chép "quyết định, phương án, lý do, YC liên quan, nguồn" và "không thêm nội dung" | Mẫu D-xx (`templates/tdd.md`) chỉ có `Author`, `Option`, `Choice`, `Hard to reverse because` — không có YC hay nguồn. `YC-xxx` đánh số theo từng spec (chính vấn đề 4 của nhiệm vụ) | Lệnh không thể vừa có YC/nguồn vừa không thêm nội dung; và `YC-003` trong ADR vô nghĩa sau khi việc kết thúc | D-08 |
| M6 | Bản máy `$AW_CONFIG/conventions.md` chỉ được ghi khoá trong danh sách cho phép, sai thì `aw conventions check` báo lỗi | `aw init --from <url>` chép `conventions.md` đầy đủ của repo cấu hình team vào `$AW_CONFIG` | Mọi team đang dùng `--from` bị báo lỗi ngay khi nâng engine | D-09 |
| M7 | Tiêu chí: "phiên mới chỉ đọc repo đích mẫu trong test trả lời được 5 câu hỏi" | `tools/chay-thu.sh` là shell, không gọi LLM | Không kiểm được đúng chữ bằng test tự động | D-12 |
| M8 | 3.6: "diff đụng `Scope` của một `ARCHITECTURE.md` … hoặc ADR" | Định dạng ở 3.1/3.3 chỉ cho BR có `Scope`; `ARCHITECTURE.md` và ADR không có trường này | Kiểm chéo không có dữ liệu để chạy | D-11 |

Ghi chú thêm (không phải mâu thuẫn, nhưng ảnh hưởng thiết kế):

- `sinh-adapter.sh` liên kết `.agent-workflow/.engine/conventions.md` → `$AW_CONFIG/conventions.md`;
  `04-implement`, `06-ship`, `clarify` bảo agent đọc phần văn xuôi (Merge request…) qua liên kết
  này. Ghi đè theo khoá chỉ áp cho khối ` ```conventions `; phần văn xuôi phải lấy từ file đã
  commit → liên kết phải trỏ sang file đó (D-01, D-03).
- Đường dẫn mới không được nằm dưới `.agent-workflow/` (cả thư mục bị exclude, và `--from-legacy`
  đang dùng `.agent-workflow/conventions.md` làm dấu hiệu bộ cài cũ).
- `conv_get` đọc đúng một file; cần thêm một bước dựng "conventions hiệu lực" (gộp hai nguồn)
  mà mọi chỗ đang dùng `MT_CONV` / `kc_conventions` đi qua — khoảng 15 chỗ gọi.

## Phần B — Quyết định cần người chốt

### D-00 — Xác nhận đảo ngược "không commit gì vào repo đích" (M1)

- Option A: Đảo ngược cho **kiến thức bền** (quy ước, ADR, BR, tài liệu module); vẫn giữ engine,
  adapter sinh ra và trạng thái của việc ngoài git — pros: đúng mục tiêu nhiệm vụ / cons: đổi
  quy ước phải qua PR vào nhánh được bảo vệ (đó chính là lý do bộ cài cũ bị bỏ)
- Option B: Giữ nguyên, chỉ đưa ADR/BR vào git; `conventions.md` vẫn ở `$AW_CONFIG` + `--from` —
  pros: không đảo quyết định cũ / cons: vấn đề 2, 3 của nhiệm vụ không được giải
- Đề xuất: **A**. Lý do cũ nhắm vào *cài/nâng cấp engine* phải qua PR; quy ước của team đi qua
  review là điều mong muốn, không phải chi phí. README và `kien-truc.md` sẽ ghi rõ ranh giới mới.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-01 — Đường dẫn `conventions.md` trong repo đích (mục 6.1)

- Option A: Cố định `docs/agent-workflow/conventions.md` — pros: không có vòng "cấu hình chỗ đặt
  cấu hình" / cons: repo không có `docs/` vẫn phải tạo
- Option B: Mặc định như A, đổi được bằng biến `DUONG_DAN_QUY_UOC` trong `$AW_CONFIG/config.sh` —
  pros: linh hoạt / cons: mỗi máy có thể trỏ một file khác, đúng thứ nhiệm vụ muốn loại bỏ
- Đề xuất: **A**. Liên kết `.agent-workflow/.engine/conventions.md` trỏ sang file đã commit khi có.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-02 — Khoá máy được ghi đè (mục 6.2)

- Option A: Chỉ `worktree_dir` — pros: hẹp, đúng "chỉ ảnh hưởng máy cục bộ" / cons: không có
  chỗ thử luật mới trên một máy
- Option B: `worktree_dir` + `mr_platform` (máy có/không có `gh`/`glab`) — cons: `mr_platform`
  là thuộc tính của origin, không của máy; đoán từ URL đã đủ
- Đề xuất: **A**. Danh sách nằm trong một biến ở engine, `aw conventions check` báo lỗi khoá
  khác ở bản máy. Thêm khoá sau là thay đổi engine, có lý do.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-03 — Đọc bản nào của file đã commit (M2)

- Option A: Cây làm việc của worktree — pros: đơn giản / cons: việc tự đổi luật của chính nó
- Option B: Bản ở commit `Base` của việc (`git show <điểm-rẽ>:docs/agent-workflow/conventions.md`);
  ở checkout chính (trước intake) đọc cây làm việc — pros: luật của việc cố định như version
  engine đã ghim; sửa quy ước có hiệu lực cho việc **sau** khi PR merge / cons: việc nào sửa
  chính `conventions.md` không thấy luật mới của mình (đúng ý đồ)
- Option C: Như B, kèm cảnh báo ở implement và chặn ở review khi diff đụng `conventions.md`
  mà không khai trong plan
- Đề xuất: **B**; C có thể thêm sau nếu thấy cần.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-04 — Lệnh nâng D-xx, cú pháp và thời điểm (mục 6.3, M3)

- Option A: Người đánh dấu ngay trong D-xx bằng trường `- Promote: adr` (được dấu duyệt phủ, nên
  người duyệt D là người quyết nâng); `03-plan` sinh task "nâng D-NN"; `04-implement` chạy
  `aw adr promote <thư-mục-feature> D-NN [--supersedes NNNN]`; ADR nằm trong diff, review
  kiểm nội dung ADR khớp D đã duyệt — pros: không đụng `Reviewed tree`, ADR đi cùng PR /
  cons: thêm trường vào mẫu D-xx (đổi checker thiết kế + test)
- Option B: Chạy sau review, rồi chạy lại review — pros: đúng chữ "sau review" / cons: mỗi lần
  nâng tốn một lượt review ngữ cảnh sạch
- Option C: Chạy ở checkout chính sau khi merge, ra một PR chore riêng — pros: không đụng luồng
  việc / cons: ADR tách khỏi code nó giải thích; dễ bị quên
- Đề xuất: **A**. Cú pháp: `aw adr promote <thư-mục-feature> D-NN [--supersedes NNNN]`,
  `aw adr check` (checker hình thức, đăng ký trong `bang-lenh.sh`).
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-05 — Thiếu verdict cho tài liệu module bị ảnh hưởng: review chặn hay cảnh báo (mục 6.4)

- Option A: Implement cảnh báo, review **chặn** khi thiếu verdict hợp lệ — đúng quy ước "kiểm
  chéo: cảnh báo ở implement, chặn ở review" của `AGENTS.md`
- Option B: Chỉ cảnh báo ở cả hai — cons: cảnh báo dồn về review rồi không ai buộc xử lý
- Đề xuất: **A**. Máy chỉ kiểm có verdict (`pass | updated | not applicable` + lý do), không kiểm
  verdict đúng — giống `## Repo rules`.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-06 — Tách hay gộp `ARCHITECTURE.md` và `RULES.md` trong module (mục 6.5)

- Option A: Một file `ARCHITECTURE.md` / module; luật nghiệp vụ riêng module nằm trong file đó
  dưới khối `### BR-…` cùng định dạng — pros: một chỗ cho mỗi module; checker tìm BR theo
  heading, không theo tên file / cons: file dài hơn
- Option B: Hai file — pros: tách người đọc (kỹ sư vs BA) / cons: thêm một chỗ cho cùng phạm vi
- Đề xuất: **A**.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-07 — Nguồn của BR khi nâng từ YC (M4)

- Option A: Chỉ nâng YC có nguồn bền: `[CONFLUENCE]`, `[JIRA]`, `[FILE]` trỏ tới file **đã
  commit**. Từ chối `[INFERRED]`, `[OPEN-QUESTION]`. Với `[FILE] intake.md` (lời người) và
  `[FILE] open-questions.md` (câu trả lời điểm mù): BR ghi `Source: [HUMAN] <ai>, <ngày>` và
  **chép nguyên văn** câu người nói vào `- Quote:` (đó là nội dung có sẵn, không phải thêm) —
  version của `[HUMAN]` là ngày
- Option B: Chỉ nâng từ `[CONFLUENCE]`/`[JIRA]`/`[FILE]` đã commit; lời người phải được ghi vào
  tài liệu có định danh trước — cons: nhiều luật thật chỉ có ở lời PO
- Đề xuất: **A**. `Source` cần version: Confluence/Jira lấy từ cột "Phiên bản" của bảng nguồn
  trong spec; thiếu thì lệnh từ chối.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-08 — YC và nguồn trong ADR (M5)

- Option A: ADR không ghi `YC-NNN` (số theo việc, vô nghĩa sau đó) mà ghi **nguồn của YC** —
  máy suy từ `Based on: D-NN` + `## YC mapping` → YC → `Source:` trong spec. Đây là chép, không
  phải thêm. Ghi kèm tên nhánh/MR của việc
- Option B: Thêm trường `- Requirements:` vào mẫu D-xx để agent ghi tay — cons: thêm thứ agent tự
  khai, máy không kiểm được đúng
- Đề xuất: **A**.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-09 — `aw init --from` dưới cơ chế mới (M6)

- Option A: `--from` thôi chép `conventions.md` (in cảnh báo nếu repo cấu hình còn file đó, gợi
  ý chuyển vào repo đích); vẫn chép `version`, `checksums`, `config.sh`
- Option B: Bản từ `--from` được coi là "bản máy" — cons: lại là hai nguồn sự thật
- Đề xuất: **A**. Repo chỉ có `$AW_CONFIG/conventions.md` (không có file đã commit) vẫn chạy
  như cũ, kèm cảnh báo — tiêu chí tương thích ngược giữ nguyên.
- Khi làm: `--from` chỉ bỏ `conventions.md` khi repo đích **đã có** file; chưa có thì vẫn chép (kèm
  cảnh báo của `aw conventions check`) — bỏ luôn thì clone mới chạy bằng mẫu, phá tương thích ngược.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-10 — Engine tìm file kiến thức bền thế nào (mục 3.5)

- Option A: Khoá mới trong `conventions.md`, mặc định theo bố trí 3.1:
  `knowledge_adr_dir: docs/adr`, `knowledge_files: docs/product/rules/*.md */ARCHITECTURE.md`;
  lệnh mới `aw knowledge <phase> <thư-mục-feature>` in danh sách file (spec: luật `active` có
  `Scope` khớp; design: chỉ mục ADR + `ARCHITECTURE.md` của module trong `## Existing code` /
  diff) — pros: tách nghĩa với `aw rules` ("đọc mọi file") / cons: thêm một lệnh
- Option B: Mở rộng `aw rules <phase>` — cons: `aw rules` đang có nghĩa "đọc hết", review chấm
  từng file; trộn vào làm bảng `## Repo rules` phình theo số module
- Đề xuất: **A**.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-11 — Phạm vi của `ARCHITECTURE.md` và ADR cho kiểm chéo lỗi thời (M8)

- Option A: `ARCHITECTURE.md` phủ thư mục chứa nó (`<thư-mục>/*`); ADR có trường `- Scope: <glob>`
  bắt buộc (lấy từ module trong `## Existing code`, người sửa được trước khi commit)
- Option B: Mọi file kiến thức đều khai `Scope:` tường minh — cons: thêm việc cho tài liệu module
- Đề xuất: **A**.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

### D-12 — Kiểm tiêu chí "phiên mới trả lời được 5 câu hỏi" (M7)

- Option A: Test tự động kiểm **điều kiện cần**: repo đích mẫu trong test có đủ file cho từng câu,
  và `aw knowledge` in đúng các file đó; phép thử với phiên agent thật ghi thành bước tay trong
  README (người chạy một lần khi phát hành)
- Option B: Bỏ tiêu chí này khỏi điều kiện hoàn thành
- Đề xuất: **A**.
- [x] **Approved by human** — theo Đề xuất (người duyệt trong hội thoại, 2026-10-08)

## Phần C — PR nào chờ D nào

| PR | Nội dung | Cần chốt |
|---|---|---|
| 1 | `conventions.md` đã commit, ghi đè có giới hạn, tương thích ngược, `aw init`, `aw conventions check` | D-00, D-01, D-02, D-03, D-09 |
| 2 | Mẫu `AGENTS.md` cho repo đích, khuyến nghị `Makefile`, `config.sh` mẫu | D-00, D-01 |
| 3 | ADR: lệnh nâng, mẫu, chỉ mục, checker, `02-design` đọc chỉ mục | D-04, D-08, D-10, D-11 |
| 4 | Luật `BR-`: định dạng, checker, lệnh nâng, `covers:` nhận `BR-`, `01-spec` đối chiếu | D-06, D-07, D-10 |
| 5 | Kiểm chéo lỗi thời ở implement và review | D-05, D-11, D-12 |
