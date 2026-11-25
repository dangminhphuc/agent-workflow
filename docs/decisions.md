# Quyết định

Mọi quyết định đã chốt của engine v2, theo thứ tự thời gian. Mỗi mục: các lựa chọn đã xét, chọn gì, vì sao.
Đổi một quyết định → thêm mục mới ghi `Thay thế: D-NNN`, không sửa mục cũ.

Bản cũ (engine v1) nằm trên nhánh `main`, đọc tại `/home/dangminhphuc/github/agent-workflow` — chỉ để
tham chiếu, không phải thứ v2 phải tương thích.

## Đã chốt

### D-001 — Làm lại engine, bắt đầu từ interface SDLC (2026-11-25)
- Bối cảnh: interface SDLC của v1 được thêm sau, phần lớn suy ra từ implementation có sẵn; người chưa
  nắm rõ interface định nghĩa gì trước khi code.
- Chọn: làm lại từ đầu. Interface là bước nền người phải hiểu rõ (định nghĩa, làm gì, input, output),
  sau đó implement từng bước, mỗi bước có unit test rõ ràng.
- Không chọn: xoá toàn bộ v1 — mất bộ test và lý do thiết kế đã trả giá. v1 giữ nguyên trên `main`
  làm kiến thức nền.

### D-002 — Cây sạch: nhánh `v2` orphan (2026-11-25)
- Lựa chọn: (A) worktree từ `origin/main`, giữ toàn bộ cây file; (B) cây trống, v1 chỉ đọc qua
  worktree cũ.
- Chọn: B — thiết kế không bị v1 neo vào.
- Hệ quả: ngoại lệ có chủ ý với quy tắc "worktree từ `origin/main`" trong `AGENTS.md` của v1.

### D-003 — Phạm vi: lõi tới merge, deploy/operate là điểm nối (2026-11-25)
- Lựa chọn: (A) dừng ở PR người merge, deploy/operate ngoài phạm vi; (B) bao cả vòng đời, agent chạm
  hệ thống ngoài; (C) bao cả vòng đời nhưng chia hai lớp.
- Chọn: C — lõi (tới merge) đặc tả và test chặt; deploy/operate chỉ là hợp đồng input/output với
  CI/CD và observability bên ngoài, không implement.
- Vì sao: thấy được SDLC trọn vẹn trên giấy mà không bắt engine làm thứ nó không kiểm được.

### D-004 — Lõi agent-agnostic, tăng tốc tuỳ chọn (2026-11-25)
- Lựa chọn: (A) agent-agnostic hoàn toàn; (B) thiết kế quanh Claude Code; (C) lõi agent-agnostic,
  agent được thêm cơ chế riêng.
- Chọn: C — hợp đồng input/output mỗi stage chỉ là file, luôn đủ để chạy đúng; phép thử: mỗi bước
  chạy được từ phiên trắng. Agent được thêm subagent, hook… để nhanh hơn, nhưng không được đổi kết
  quả hay bỏ qua kiểm tra.

### D-005 — Interface: file cho người là nguồn, biên dịch sang file máy (2026-11-25)
- *Bị thay một phần bởi D-013 (không commit hợp đồng máy).*
- Lựa chọn: (A) Markdown + frontmatter như v1; (B) schema là nguồn, sinh tài liệu người; (C) hai lớp
  có liên kết.
- Chọn: C, biến thể: người chỉ đọc và sửa file cho người; file máy là sản phẩm biên dịch, không ai
  sửa tay; máy kiểm file máy đã commit khớp kết quả biên dịch.
- Vì sao: người phải hiểu rõ — cần ví dụ và lý do, thứ schema không chứa tốt; biên dịch giữ hai bên
  không lệch.

### D-006 — Biên dịch tất định, agent chỉ đề xuất sửa file người (2026-11-25)
- Lựa chọn: (A) script tất định, khuôn cố định; (B) agent biên dịch; (C) script là chính, agent hỗ trợ.
- Chọn: C — trình biên dịch tất định, báo lỗi theo dòng, unit test được. File người sai khuôn → agent
  được đề xuất sửa **file người**, người đồng ý thì biên dịch lại. Agent không bao giờ ghi file máy.

### D-007 — Công nghệ: Python, phát hành một file `.pyz` (2026-11-25)
- Lựa chọn: (A) POSIX sh + awk như v1; (B) Go binary; (C) Python hoặc Node.
- Repo đích đa dạng (Go, Java, .NET, mobile…). Go được đề xuất vì repo đích không cài gì; Node bị loại
  vì repo không phải JS/TS phải cài Node chỉ để chạy engine.
- Chọn: Python — viết nhanh, dễ đọc, không có bước build; chấp nhận repo đích cần Python.
- Hệ quả:
  - Repo đích cần `python3 ≥ 3.9` (bản Xcode Command Line Tools cài trên macOS).
  - Thư viện bên thứ ba chỉ loại thuần Python, đóng gói kèm vào `.pyz`; repo đích không `pip install`.
  - Engine kiểm phiên bản Python lúc khởi động, báo lỗi rõ ràng (cần gì, cài thế nào).
  - CI của engine chạy `mypy --strict`; unit test cho từng thành phần.

### D-008 — Chia dự án con và thứ tự (2026-11-25)
- Chọn: SP1 → SP7 → SP2 ∥ SP3 → SP4 → SP5 → SP6. SP8 chưa cần. SP9 rải theo từng SP.
- Danh sách và trạng thái: `PROGRESS.md`.
- SP8 (chuyển đổi từ v1) chưa cần: chưa có repo đích thật phải chuyển.

### D-009 — Dừng và tiếp tục bằng sổ tiến độ trong repo (2026-11-25)
- Vấn đề: dự án dài nhiều phiên; lịch sử chat và memory của agent không đáng tin, người không đọc được.
- Chọn: `PROGRESS.md` là điểm vào duy nhất; quyết định ở file này; spec ở `docs/specs/`, plan ở
  `docs/plans/`. Quy tắc dừng/tiếp tục: `PROGRESS.md` § Cách dừng và tiếp tục.

### D-010 — SP1-1: giữ 8 stage của v1 làm khung (2026-11-25)
- Lựa chọn: (A) giữ nguyên 8 stage, duyệt lại nội dung từng stage trong SP1; (B) đổi tên và ranh giới
  ngay từ đầu; (C) bắt đầu từ mô hình SDLC chuẩn (ISO/IEC 12207) rồi chọn lọc.
- Chọn: A — `plan`, `require`, `design`, `breakdown`, `implement`, `verify`, `deploy`, `operate`.
- Vì sao: khung phủ đủ vòng đời và đã qua thực tế; điểm cần sửa nằm ở ranh giới và tên, duyệt từng
  trang sẽ bắt được kèm lý do cụ thể.
- Mang theo khi duyệt từng trang: `plan` của v1 thực chất là tiếp nhận việc (intake); `implement` tạo 4
  loại artifact, `security-evidence` nằm ở đó thay vì `verify` mà lý do không hiển nhiên.

### D-011 — SP1-2: khuôn trang stage, mỗi thông tin một nguồn (2026-11-25)
- *Bị thay một phần bởi D-012 (trang stage còn 7 mục, bỏ `## Invariants` và `Skippable`, thêm giới hạn độ dài).*
- Lựa chọn: (A) khuôn 11 mục (Definition, Purpose, Input có cột From stage, Output, Exit, Capabilities
  có ví dụ đạt + không đạt, Invariants, Example riêng từng trang, Not in this stage, Rationale);
  (B) bản tối ưu ~8 mục + trang tổng quan.
- Chọn: B.
- Người đọc trang stage: người duyệt interface, trình biên dịch (SP2), người viết checker/test (SP4).
  Agent lúc chạy **không** đọc trang này — nó đọc hợp đồng máy đã biên dịch + hướng dẫn của SP3.
- Trang stage `interface/stages/NN-<id>.md`, mục theo thứ tự cố định:

  | Mục | Nội dung | Trình biên dịch |
  |---|---|---|
  | `# Stage: <id>` | Tên stage | đọc |
  | `## Definition` | Hai câu: stage là gì, vì sao cần (bỏ đi thì hỏng gì) | kiểm có, không rỗng |
  | `## Input` | Bảng: Artifact · Required (`yes`/`no`) · Used for | đọc |
  | `## Output` | Bảng: Artifact · Description | đọc |
  | `## Exit` | `- Judged by: machine \| human \| both`, `- Skippable: yes \| no`, rồi văn xuôi: máy kiểm gì, người duyệt gì | đọc 2 dòng đầu |
  | `## Capabilities` | `### CAP-<id>-NN — <tên>` + `- Rule:` + `- Judged by:` + `- Artifact:` + `- Fail example:` (bắt buộc) + `- Pass example:` (tuỳ chọn) | đọc |
  | `## Invariants` | Danh sách `INV-NNN` stage phải giữ | đọc |
  | `## Not in this stage` | Ranh giới: việc dễ tưởng thuộc stage này nhưng không | kiểm có, không rỗng |
  | `## Rationale` | Lý do thiết kế, lựa chọn đã bỏ | kiểm có, không rỗng |

- Trang tổng quan, hai phần tách file:
  - Người viết `interface/overview.md`: giới thiệu + **kịch bản xuyên suốt** một việc đi qua cả 8 stage
    (output stage trước là input stage sau).
  - Máy sinh: sơ đồ luồng + ma trận stage × artifact, suy từ Input/Output các trang. Không ai sửa tay;
    đường dẫn chốt ở SP2.
- Bỏ so với (A) và vì sao:
  - `Definition` + `Purpose` gộp — viết riêng hay lặp ý.
  - Cột `From stage` — suy ra được từ Output của stage khác; giữ lại là hai nguồn.
  - `Example` từng trang — thay bằng kịch bản xuyên suốt, ít chữ hơn và thấy được luồng.
  - `Pass example` thành tuỳ chọn — `Rule` đã tả trường hợp đạt; ví dụ không đạt mới chỉ ra ranh giới.
- Ngôn ngữ: heading, tên trường, id, tên loại artifact, giá trị enum bằng tiếng Anh (từ khoá ổn định
  cho trình biên dịch). Mọi chữ người viết — kể cả `Rule:` — bằng tiếng Việt.
- Văn xuôi không bị biên dịch nhưng trình biên dịch chặn mục rỗng: trang không thể đủ khuôn mà thiếu
  phần giải thích cho người.

### D-012 — SP1-3: khuôn đầy đủ của interface (2026-11-25)
- Thay một phần: D-011.
- Vai trò các khái niệm: stage = việc của một bước; artifact = thứ stage tạo ra cho stage sau; capability
  = "làm đủ bước đó"; invariant = luật máy kiểm nối nhiều stage, để chuỗi không đứt; job type = loại việc
  chọn đường đi và bảo đảm thêm, để độ chặt tỉ lệ với rủi ro.
- Nguyên tắc: mỗi quan hệ ghi đúng một chỗ; trường có mặc định thì được bỏ dòng; ô bảng chỉ là một id,
  danh sách id cách dấu phẩy, `—`, hoặc văn xuôi (chỉ ở cột quy định là văn xuôi).
- Cấu trúc:
  ```
  interface/
  ├── overview.md          người viết: bảng 5 khái niệm · kịch bản xuyên suốt · lý do chung
  ├── stages/NN-<id>.md    người viết: 7 mục
  ├── invariants.md        người viết
  ├── job-types.md         người viết: 2 bảng + Why
  └── generated/overview.md  máy sinh, commit, CI kiểm không lệch: sơ đồ luồng, ma trận stage × artifact,
                             ma trận job type × stage, invariant theo stage
  ```
- **Trang stage**, 7 mục theo thứ tự (trình biên dịch đọc / kiểm):
  - `# Stage: <id>`
  - `## Definition` — tối đa 2 câu: là gì, vì sao cần.
  - `## Input` — bảng Artifact · Required (`yes`/`no`) · Used for.
  - `## Output` — bảng Artifact · Description.
  - `## Exit` — `- Judged by: machine | human | both` + văn xuôi: máy kiểm gì, người duyệt gì.
  - `## Capabilities` — `### CAP-<id>-NN — <tên>` + `- Rule:` + `- Judged by: machine | agent | human` +
    `- Artifact:` + `- Fail example:` (bắt buộc, 1 dòng) + `- Pass example:` (tuỳ chọn, 1 dòng).
  - `## Not in this stage` — tối đa 5 gạch.
  - `## Rationale` — tối đa 5 gạch, chỉ ghi lựa chọn đã bỏ và vì sao.
  - Bỏ so với D-011: `## Invariants` (quan hệ ghi ở `invariants.md`), dòng `Skippable` (ghi ở `job-types.md`).
- **Invariant** (`invariants.md`), mỗi luật:
  `### INV-NNN — <tên>` + `- Rule:` + `- Checked at:` (stage mà khi kết thúc luật phải đúng) +
  `- Warned from:` (tuỳ chọn, stage báo sớm, phải đứng trước `Checked at`) + `- Only for:` (tuỳ chọn, job
  type; bỏ dòng = mọi loại) + `- Fail example:` + `- Why:` (một câu).
  - Không `Judged by`: invariant luôn do máy kiểm; luật xuyên stage cần người/agent phán là capability của `verify`.
  - Không `Engine` / `Enforced by` / `Tested by` như v1: chúng trỏ tới engine, thuộc SP4.
- **Job type** (`job-types.md`): bảng `Job type · Definition · Optional · Skipped`; bảng `Added artifacts`:
  `Job type · Artifact · Produced by · Consumed by · Description`; `## Why` mỗi loại một gạch.
  `Definition` viết kiểu phân biệt với loại gần nó; trình biên dịch đưa nó vào hợp đồng máy (agent cần để
  phân loại việc ở `plan`).
- **`overview.md`**: bảng 5 khái niệm; kịch bản xuyên suốt một việc qua 8 stage; lý do chung (không lặp ở từng trang).
- **Trình biên dịch** — chặn: thiếu mục / sai thứ tự; văn xuôi bắt buộc rỗng; giá trị enum sai; ô bảng sai
  dạng; id trùng; tham chiếu trong backtick (stage, artifact, `CAP-…`, `INV-…`) không tồn tại; artifact
  được đọc mà không stage/job type nào tạo; `Warned from` không đứng trước `Checked at`; `generated/` lệch
  (ở CI). Cảnh báo: vượt giới hạn độ dài. Tự suy: stage bị bỏ / tuỳ chọn với một job type → input
  `Required: yes` lấy từ stage đó được phép vắng với job type đó.
- **Phía engine (SP4)**: mỗi `Fail example` phải có một test; máy chặn ví dụ không có test.
- **Phép thử đọc lạnh** — một trang chỉ xong khi qua: chỉ với trang đó + `overview.md`, trả lời được
  (1) là gì, vì sao cần; (2) nhận gì; (3) trả gì; (4) khi nào xong, ai cho phép; (5) một ví dụ làm sai
  cụ thể. Vòng 1: agent ở phiên trắng trả lời. Vòng 2: người đọc trang + câu trả lời, duyệt hoặc chỉ
  chỗ gây hiểu sai.
- Đánh đổi đã chấp nhận: `Rule` và văn xuôi bằng tiếng Việt; cần quốc tế hoá thì xem lại.
- Còn phải viết (nội dung duyệt sau): invariant "stage `optional` bị bỏ phải có người duyệt việc bỏ".

### D-013 — Không commit hợp đồng máy (2026-11-25)
- Thay một phần: D-005 ("máy kiểm file máy đã commit khớp kết quả biên dịch").
- Chọn: hợp đồng máy chỉ sinh lúc chạy test và lúc phát hành (đóng vào `.pyz`). Chỉ commit phần sinh cho
  người đọc (`interface/generated/`), mở đầu bằng dòng báo "sinh tự động — đừng sửa tay"; CI chặn khi lệch.
- Vì sao: không có bản commit thì không thể lệch; người đóng góp không phải nhớ chạy build.

### D-014 — Chỉnh khuôn sau đọc lạnh lần 1 trang `require` (2026-11-25)
- Thay một phần: D-012.
- Bối cảnh: agent đọc lạnh (chỉ trang `require`) tìm ra: Exit ghi `Judged by: both` nhưng mọi capability
  là `machine` (hai nguồn lệch nhau); luật "chữ trong backtick phải tồn tại" chặn nhầm giá trị như
  `blocking`; tiền tố "Bỏ:" khó hiểu; không rõ máy và người ai trước, lúc nào xong.
- Chọn:
  - **K1** — bỏ dòng `Judged by` ở `## Exit`; máy suy ra từ `Judged by` của các capability. Exit chỉ còn văn xuôi.
  - **K2** — `overview.md` có bảng **Giá trị** (giá trị · dùng ở đâu · nghĩa). Mọi chữ trong backtick phải
    là tên stage, artifact, mã, hoặc giá trị trong bảng này; trình biên dịch chặn chữ lạ.
  - **K3** — gạch đầu dòng trong `## Rationale` mở bằng "Đã loại:".
  - **K4** — thứ tự kết thúc chung, ghi một lần ở `overview.md`: máy kiểm trước, người duyệt sau khi máy
    đạt; stage xong khi mọi capability đạt. Trang stage không nhắc lại.
  - `overview.md` nói rõ: interface không quy định định dạng file, nơi lưu, hay dạng dấu duyệt (thuộc SP3).

## Đang mở

### Trang thử `require`
- `interface/stages/01-require.md` viết theo D-012, chuyển nội dung từ `sdlc/stages/01-require.md` của v1.
- Bước: phép thử đọc lạnh vòng 1 (agent phiên trắng) → người duyệt (vòng 2) → chỉnh khuôn nếu cần →
  mới viết spec SP1 và các trang còn lại.
- Đọc lạnh lần 1 (chỉ trang): ra D-014 và 6 sửa trang — nguồn là các nguồn trong work item; thêm
  `CAP-require-04` (người trả lời câu hỏi `blocking` và duyệt); câu trả lời của người là phần duyệt cho
  câu hỏi đó; "tự trả lời … mà không ghi lại"; viết lại câu ba mức chặn.
- Đọc lạnh lần 2: trang đã sửa + `overview.md` tối thiểu.
- `overview.md` hiện là bản tối thiểu cho phép thử: một câu mỗi stage trong bảng Luồng là nháp từ v1,
  duyệt khi viết từng trang; kịch bản xuyên suốt viết khi đủ 8 trang; nghĩa của `agent` (một agent khác
  với agent đang làm việc) chờ SP3 chốt.
- Ứng viên cho SP7 thấy khi viết trang (không đưa vào trang thử): câu trích nguyên văn của nguồn
  (`Quote`), nhãn nguồn (`[JIRA]`, `[FILE]`…), mã riêng cho câu hỏi mở (`Q-NNN`).
