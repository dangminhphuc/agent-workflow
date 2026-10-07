# Changelog

Version là `YYYY.M.N`: năm, tháng phát hành, và `N` là **số thứ tự bản phát hành
trong tháng** (1, 2, 3, …; sang tháng mới đếm lại từ 1), không số 0 đứng đầu, vd
`2026.10.8`, `2026.11.1`. Mỗi bản phát hành là một git tag đúng chuỗi đó, không
có tiền tố `v`. (Trước đó `N` là ngày phát hành — `2026.10.6`, `2026.10.7` vẫn
hợp lệ, tháng 10/2026 đếm tiếp từ đó.) Repo đích ghim version cần dùng (xem
README, mục "Nâng cấp"); một việc đã bắt đầu thì chạy hết bằng version ghi trong
`intake.md` của nó.

So version theo luật **khớp chính xác `YYYY.M.N`** — không có "tương thích ngược"
ngầm giữa các bản.

## [Chưa phát hành]

### Đổi
- **Đầu mục của `intake.md` sang tiếng Anh:** `# Tiếp nhận` → `# Intake`,
  `Loại việc:` → `Type:`, `Mục tiêu:` → `Goal:` (`Base:`, `Engine:`, `## Input`
  giữ nguyên). `aw check intake` và luật theo loại việc chỉ đọc dòng
  `- **Type:**` / `- **Goal:**`. Việc đã bắt đầu không bị ảnh hưởng: nó chạy hết
  bằng version ghi ở dòng `Engine:`. Việc mới tạo bằng bản này phải dùng đầu mục
  mới.
- **Nhãn input `[NGƯỜI-DÙNG]` → `[HUMAN]`:** lời người vận hành workflow chép
  nguyên văn trong `## Input` của `intake.md`. Đổi để không nhầm với "người dùng"
  cuối của sản phẩm trong tài liệu nghiệp vụ, và khớp cặp máy / người
  (`exit_machine` / `exit_human`). `aw input` in `[HUMAN]`; `aw check intake`
  chỉ nhận `[HUMAN]`.
- **Đầu mục và tên trường của `spec.md` sang tiếng Anh:** `# Đặc tả` → `# Spec`;
  `Mức rủi ro` → `Risk`, `Lý do` → `Reason`, `Trạng thái spec` → `Status`;
  mục `Nguồn` → `Sources`, `Bối cảnh` → `Context`, `Thuật ngữ` → `Glossary`,
  `Yêu cầu` → `Requirements`, `Tái hiện lỗi` → `Reproduction`
  (`Steps to reproduce`, `Actual behavior`, `Expected behavior`),
  `Ràng buộc & phụ thuộc` → `Constraints & dependencies`, `Ngoài phạm vi` →
  `Out of scope`, `Mâu thuẫn giữa các nguồn` → `Source conflicts` (cột
  `Source A says | Source B says | Resolution`); trường của YC: `Nguồn` →
  `Source`, `Ưu tiên` → `Priority`, `Mô tả` → `Description`, `Tiêu chí chấp nhận`
  → `Acceptance criteria`, `Giả định tạm` → `Assumption`, `Loại YC` → `Type`,
  `Được bảo vệ bởi` → `Protected by`, `Mục tiêu` → `Target`. `aw check spec/design/plan/review` và `aw pending` đọc tên mới,
  neo ở đầu dòng `- `.
- **Giá trị trong `spec.md` sang tiếng Anh:** `Risk: cao | thường` →
  `high | normal`; `Status: đề xuất | đã duyệt` → `proposed | approved`;
  `Priority: bắt buộc | nên có` → `must | should`; `Type: giữ nguyên | cấu trúc |
  hiệu năng` → `preserve | structural | performance`. `Trạng thái` của D-xx trong
  `tdd.md` không đổi (`đề xuất | đã duyệt | mở lại`).
- **Nhãn nguồn `[SUY-RA]` → `[INFERRED]`, `[CẦN-HỎI]` → `[OPEN-QUESTION]`** — ở
  mọi nơi: dòng `Source:` của spec, luật cấm suy đoán trong input của
  `intake.md`, tài liệu và hướng dẫn agent.
- **`tdd.md` sang tiếng Anh:** `# Thiết kế kỹ thuật` → `# Technical Design`; mục
  `Bối cảnh code hiện có` → `Existing code`, `Quyết định (D-xx)` → `Decisions
  (D-xx)`, `Mô hình dữ liệu` → `Data model`, `Phi chức năng` → `Non-functional`,
  `Chiến lược test` → `Test strategy`, `Ánh xạ YC` → `YC mapping`; trường của
  D-xx: `tac_gia: nguoi | agent` → `Author: human | agent`, `Trạng thái: đề xuất
  | đã duyệt | mở lại` → `Status: proposed | approved | reopened`, `Phương án` →
  `Option` (`pros` / `cons`), `Chọn` → `Choice`, `Khó đảo ngược vì` → `Hard to
  reverse because`, `Lý do mở lại` → `Reopen reason`, `Phản biện (agent)` →
  `Critique (agent)`; `Dựa trên:` → `Based on:`, `Không áp dụng:` → `Not
  applicable:`. `aw check design` và `aw check plan` (D-xx phải `approved`) đọc
  tên mới.
- **`plan.md` sang tiếng Anh:** `# Kế hoạch` → `# Plan`, `## Task` → `## Tasks`;
  trường của task: `Phủ` → `Covers`, `Dựa trên` → `Based on`, `Theo` → `Design`,
  `Phụ thuộc` → `Depends on` (`không` → `none`), `File dự kiến` → `Expected
  files`, `Cách kiểm chứng` → `Verify`, `Đứng trên giả định tạm: không | có` →
  `On assumption: no | yes`, `Trạng thái` → `Status` (`[ ] [~] [x]` giữ nguyên);
  mục `Hoãn lại` → `Deferred`, `Kiểm chứng thủ công` → `Manual verification`,
  `Test cũ bị sửa` → `Modified existing tests`, `Nâng dependency` → `Dependency
  upgrades` (cột `Library | Old → new | Level`, mức `vá` → `patch`), `Phát sinh`
  → `Unplanned`. `aw check plan/implement/review` và `aw pending` đọc tên mới.

## [2026.10.9]

### Thêm
- **Quy tắc riêng của repo theo phase:** khoá `quy_tac_spec`, `quy_tac_design`,
  `quy_tac_plan`, `quy_tac_implement`, `quy_tac_review` trong `conventions.md` —
  danh sách file (coding style, skill, chuẩn kiến trúc…) phase đó phải đọc.
  Lệnh mới `aw rules <phase>` in danh sách lúc chạy; lệnh `/spec`…`/review` và
  subagent rà soát gọi nó. `aw check` của phase chặn khi file khai không có,
  chưa commit hoặc khoá gõ nhầm. `aw check review` chặn khi `review.md` thiếu mục
  "Quy tắc repo" hoặc thiếu kết luận (`đạt` / `vi phạm` / `không áp dụng`) cho
  một file. Repo không khai khoá nào thì không đổi gì. Cần wrapper `aw` mới để
  có lệnh `aw rules`.
- Checker LLM soát thiết kế (`soat-thiet-ke`) đọc `quy_tac_design` và có loại
  phát hiện mới `trái quy tắc repo` — mức Chặn, chỉ Cảnh báo khi đã có D-xx cân
  nhắc chuyện đó. Checker LLM khai `quy_tac: <phase>` trong frontmatter để đọc
  quy tắc của phase đó.

### Đổi
- **Version `YYYY.M.N`** thay cho `YYYY.M.D`: `N` là số thứ tự bản phát hành trong
  tháng, không còn giới hạn một bản mỗi ngày. Không số 0 đứng đầu, `N` từ 1.
  Wrapper `aw` cũ (2026.10.6, 2026.10.7) vẫn nhận version mới khi `N` ≤ 31; từ
  bản thứ 32 trong một tháng cần cài wrapper mới.

### Thêm
- **Phát hành bằng merge PR:** workflow `release` chạy cả khi push vào `main` —
  tag của `VERSION` chưa có thì tự test, đóng gói, tạo tag + Release; đã có thì
  bỏ qua. Cách tay (push tag / tạo trên giao diện GitHub) vẫn giữ.
- `tools/chuan-bi-phat-hanh.sh [YYYY.M.N]`: đặt version cho PR — tự tính số kế
  tiếp từ tag ở remote, ghi `VERSION`, `bin/aw`, mục CHANGELOG, link tải wrapper.
- `tools/kiem-tra-phat-hanh.sh [<base-ref>]` và workflow `kiem-tra` trên PR: test
  hồi quy + version nhất quán (`VERSION` ↔ `bin/aw` ↔ CHANGELOG), PR đổi version
  thì tag đó chưa được có.

## [2026.10.8]

### Đổi
- `/clarify`: lựa chọn là **phương án giải pháp agent đã phân tích**, không còn
  chỉ "giữ giả định / chưa trả lời được". Trước mỗi mục, agent đọc nguồn, spec,
  thiết kế, code đã có; đưa 2–3 phương án khác nhau về hệ quả, mỗi phương án
  kèm đánh đổi một dòng; phương án nên chọn đứng đầu, nhãn **bắt đầu bằng
  `(Đề xuất)`**, ngữ cảnh nói vì sao. Mục gói nhiều quyết định thì tách thành
  nhiều câu hỏi trong cùng lượt. Phát hiện checker LLM: các cách sửa cụ thể +
  Bác bỏ (agent thấy phát hiện sai thì đề xuất bác bỏ).
- Adapter Claude Code: không thêm "Chat về câu này" vào `options` nữa — dùng
  "Chat about this" / "Type something" có sẵn của `AskUserQuestion`, để đủ chỗ
  cho phương án thật. Mẫu câu hỏi luôn kết thúc bằng hai dòng `Type something.`
  và `Chat about this.`; agent không có giao diện lựa chọn thì tự in hai dòng đó.
- Người chọn phương án agent đề xuất thì `Trả lời:` ghi nhãn phương án kèm
  `(chọn từ phương án agent đề xuất)`.

## [2026.10.7]

### Đổi (phá tương thích)
- `/open-questions` → **`/clarify`**: một hàng đợi cho mọi việc máy/LLM cần người
  quyết. Ngoài điểm mù (`open-questions.md`), lệnh dẫn người **phân xử phát hiện
  của checker LLM** (`phat-hien-*.md`, hiện có `phat-hien-thiet-ke.md`) từng mục
  bằng câu hỏi lựa chọn: Đồng ý — sửa · Bác bỏ (kèm lý do) · Chat về câu này, mục
  `Cảnh báo` thêm Để sau. Đồng ý thì agent cho xem dòng `tdd.md` sẽ đổi rồi ghi
  `đã sửa`; quyết định mới thành D-xx `đề xuất` để người duyệt. Phát hiện agent
  đã tự sửa lúc `/design` được nêu lại trong tổng kết.
- `aw questions` → **`aw pending`** (`tools/liet-ke-viec-cho.sh`): gom điểm mù và
  mọi `phat-hien-*.md`, xếp theo phase bị chặn sớm nhất (điểm mù chưa phân mức →
  `chặn` → phát hiện `Chặn` → `chặn review` → phát hiện `Cảnh báo` → `không chặn`).
  Nhãn kết quả đổi theo: `KHÔNG CÒN VIỆC CHỜ NGƯỜI` / `CÓ VIỆC ĐANG CHẶN` /
  `CÒN VIỆC CHỜ NGƯỜI, CHƯA CHẶN`. Wrapper vẫn chuyển `aw questions` cho việc đã
  ghim engine 2026.10.6.
- Tên và cấu trúc file trong `.agent-workflow/<tên-branch>/` **không đổi**. Repo
  đích chạy lại `aw adapter build claude-code`: `/open-questions` cũ tự bị xoá.
- Wrapper `aw` 2026.10.6 không biết `aw pending` — cài lại wrapper từ bản này
  (README, mục cài đặt) trước khi dùng `/clarify`.

## [2026.10.6]

Bản đầu tiên có version: đổi cách cài, **phá tương thích** với bộ cài cũ. Không còn file nào
phải commit vào repo đích — chạy được khi nhánh gốc là protected branch.

### Thêm
- Wrapper `aw` (POSIX sh, cài global). Tìm repo bằng `git rev-parse`, lấy engine
  đúng version vào `~/.agent-workflow/engine/<YYYY.M.D>/`, kiểm và ghim sha256,
  chuyển lệnh sang engine. `AW_ENGINE_DIR` (không mạng), `AW_MIRROR`, `AW_CACHE`.
- Lệnh: `aw init [--from <url>] [--from-legacy]`, `aw upgrade <YYYY.M.D>`,
  `aw version`, `aw doctor`, `aw check <tên> <thư-mục>`, `aw worktree new|status|remove`,
  `aw adapter build <agent>`, `aw feature`, `aw input`, `aw questions`,
  `aw based-on`, `aw rename`. Tên lệnh và cờ đều tiếng Anh.
- Ghim version theo việc: dòng `- **Engine:** YYYY.M.D` trong `intake.md`; mọi
  `aw check` của việc chạy đúng version đó, không có thì `KHÔNG HỢP LỆ`.
- Đóng gói phát hành (`tools/dong-goi.sh`) và workflow `release` gắn
  `agent-workflow-YYYY.M.D.tar.gz`, `aw`, `SHA256SUMS` vào GitHub Release.
- `adapters/lib/chung.sh` và `adapters/README.md` (hợp đồng adapter, ghi chú Codex/Cursor).
- Mẫu mô tả MR/PR `workflow/templates/merge-request.md` và quy ước mặc định ở
  mục "Merge request" của `conventions.md` (tiêu đề, phạm vi, mục bắt buộc,
  điều kiện trước khi review/merge).

### Đổi
- `/open-questions` hỏi **từng điểm mù một bằng câu hỏi lựa chọn** thay vì dán cả
  danh sách: giữ giả định tạm · cách hiểu khác có trong nguồn · Chưa trả lời được
  · Chat về câu này, luôn kèm ô tự nhập. Output của `aw questions` là dữ liệu cho
  agent; người chỉ thấy một dòng tóm tắt. Lệnh tiện ích khai `choice_ui: true`;
  adapter Claude Code dịch sang tool `AskUserQuestion`.
- Cấu hình nằm trong `$(git rev-parse --git-common-dir)/agent-workflow/`:
  `version`, `checksums`, `conventions.md`, `config.sh` (thay `.quy-trinh/cau-hinh.sh`,
  thêm `ADAPTER`). Dùng chung mọi worktree, không commit.
- `/.agent-workflow/` và thư mục adapter (`/.claude/`) vào `.git/info/exclude`.
  Artifact của việc chỉ ở máy; `aw worktree remove` chép nó vào
  `.git/agent-workflow/archive/` trước khi gỡ.
- Base của worktree tuỳ ý — bỏ điều kiện "base phải có bộ cài".
- Adapter sinh lệnh gọi `aw …`; `exit_machine` là `aw check <tên>`. Rules,
  templates, checkers chép vào `.agent-workflow/.engine/` khi sinh adapter.
- Tool đọc đường dẫn từ `AW_REPO`, `AW_CONFIG`, `AW_ENGINE`; không còn suy từ vị
  trí của chính nó.
- Cờ: `--create --base` (thay `--tao --goc`), `--delete-branch` (thay
  `--xoa --ca-branch`), `--skip` (thay `--tru`), `--before|--after` (thay `--truoc|--sau`).

### Bỏ
- `tools/cai-dat.sh`, `tools/dong-bo.sh`: chỉ in hướng dẫn chuyển sang
  `aw init` / `aw upgrade`. Chuyển repo cũ: `aw init --from-legacy` (không xoá,
  không commit; in lệnh `git rm` để người dọn bằng PR).
