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
- **Cold read** — một trang chỉ xong khi qua: chỉ với trang đó + `overview.md`, trả lời được
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

### D-014 — Chỉnh khuôn sau cold read lần 1 trang `require` (2026-11-25)
- Thay một phần: D-012.
- Bối cảnh: agent làm cold read (chỉ trang `require`) tìm ra: Exit ghi `Judged by: both` nhưng mọi capability
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

### D-015 — Chỉnh sau cold read lần 2 trang `require` (2026-11-25)
- Bối cảnh: cold read lần 2 (trang + `overview.md`) thấy quy tắc "máy trước, người sau" mâu thuẫn với
  `CAP-require-03` (máy kiểm dấu duyệt, mà dấu duyệt chỉ có sau khi người duyệt); `CAP-require-01` gộp
  phần máy kiểm chính xác được với phần máy không phán được ("phải nhanh").
- Chọn:
  - **P1** — "dấu duyệt gắn với nội dung" là invariant, không phải capability: `INV-001` trong
    `interface/invariants.md`, áp cho mọi artifact mà một capability `human` nhận phán. Artifact cần
    duyệt suy ra từ capability `human`, không khai riêng. `Checked at` hiện là `require`, `design`; thêm
    stage khi viết trang của nó.
  - **P2** — thứ tự kết thúc: máy + agent kiểm nội dung → người duyệt (nếu stage có capability `human`)
    → máy xác nhận dấu duyệt khớp và kiểm invariant. Nội dung đổi sau khi duyệt → quay lại đầu. Bước
    gác cuối luôn là máy.
  - **B** — tách capability theo người phán được: máy kiểm "có nguồn trong work item, có tiêu chí";
    agent kiểm "tiêu chí quan sát được".
  - Sửa chữ: thêm khái niệm yêu cầu, tiêu chí chấp nhận, câu hỏi mở, task, agent, người duyệt; bỏ chữ
    "engine" khỏi overview; liệt kê tên trường của capability; tên thư mục và tên trường không viết trong
    backtick; ô bảng chứa tên artifact/stage không cần backtick.

### D-016 — Chỉnh sau cold read lần 3 trang `require` (2026-11-25)
- Thay một phần: D-012 (bỏ `## Exit`, thêm cột `Approval`), D-015 (artifact cần duyệt khai rõ, không suy ra).
- Bối cảnh: cold read lần 3 (overview + invariants + require) ra 4 MAJOR — đều là quyết định nội dung trang
  chưa nói ra: `open-questions` có cần dấu duyệt không; `INV-001` thiếu stage kiểm; "một nguồn" là đúng
  một hay ít nhất một; ranh giới "rút từ nguồn" / "tự trả lời" / "thêm phạm vi".
- Chọn:
  - **D1** — bảng Output có cột `Approval` (`yes`/`no`): artifact cần người duyệt duyệt cả khối, kèm dấu
    duyệt. `INV-001` dùng cột này, không suy từ capability `human` nữa. `open-questions` = `no`: duyệt
    từng câu bằng câu trả lời. Thêm `CAP-require-05` (agent): câu trả lời khác giả định → yêu cầu trỏ
    tới câu hỏi đó được sửa (khi đó `INV-001` buộc duyệt lại `requirements`).
  - **D2** — giá trị `all` cho `Checked at`; `INV-001` kiểm ở mọi stage.
  - **D3** — mỗi yêu cầu chỉ ra **ít nhất một** nguồn; nguồn là một mục trong work item hoặc một câu hỏi
    mở (yêu cầu dựa trên giả định).
  - **D4** — bỏ mục `## Exit`: sau D-014/D-015 nó chỉ chép lại capability bằng lời khác rồi lệch. Trang
    stage còn **6 mục**: Definition, Input, Output, Capabilities, Not in this stage, Rationale. Máy sinh
    phần "xong khi nào" của từng stage vào `generated/overview.md`.
  - M4: ranh giới ba trường hợp ghi ở `Not in this stage`; thêm khái niệm "phạm vi" ở overview.
  - Sửa chữ: "bước gác" → "bước kiểm cuối"; định nghĩa nhánh chính, phiên làm việc mới, ticket; lời người
    = lời người duyệt được ghi lại; mẫu mã không viết trong backtick; thêm lý do loại hai mức chặn.
- Tiêu chí dừng cold read: lần 4 là lần cuối của vòng 1. MAJOR còn lại thuộc trang khác hoặc SP3 → ghi vào
  § Đang mở, chuyển trang cho người duyệt; không lặp tiếp.

### D-017 — Agent rà trang `require` một lượt trước khi người duyệt (2026-11-25)
- Bối cảnh: người yêu cầu rà thêm một lượt sau 4 lần cold read. Agent đối chiếu ba file với D-011…D-016 và
  "Lý do chung" của overview; kiểm máy (backtick, giới hạn độ dài) đều đạt.
- Sửa (hệ quả trực tiếp của nguyên tắc đã chốt):
  - **R1** — "điều máy kiểm được thì máy phải kiểm": "mọi câu `blocking` đã có câu trả lời" chuyển từ
    capability `human` sang `CAP-require-03` (machine). `CAP-require-04` giữ phần chỉ người làm được; ví
    dụ sai mới: agent tự điền câu trả lời thay người duyệt.
  - **R2** — `CAP-require-05` bỏ "dù lúc đó đang ở stage nào": capability của `require` mà áp ở mọi stage
    là luật xuyên stage, trái overview ("luật xuyên stage cần agent phán → capability của `verify`"). Câu
    trả lời đến muộn: SP3 + một capability của `verify` (ghi chú bên dưới). Bỏ luôn vế "phải duyệt lại
    (`INV-001`)" — `INV-001` đã giữ, không nhắc lại.
  - **R3** — mức `review-blocking` không có luật nào buộc → thêm `INV-002` (Checked at: verify).
  - **R4** — `blocking` = "trả lời trước khi `require` xong" thay cho "trước khi `design` bắt đầu": đúng cả
    với job type bỏ `design`.
  - **R5** — overview: quay lại bước 1 khi nội dung đổi **sau bước 1** (không chỉ sau khi duyệt), vì
    `CAP-require-05` sửa yêu cầu giữa lúc người trả lời và lúc người duyệt.
  - **R6** — mô tả `open-questions` bỏ "ghi ngay cạnh câu hỏi" (là chuyện định dạng, ngoài interface).
  - **R7** — giá trị trong dòng trường không viết trong backtick (`Checked at: all`, như `Judged by: machine`).
  - **R8** — `INV-001` áp cho "mọi artifact đã có"; sửa câu chữ: "Yêu cầu" trong khái niệm, "người duyệt duyệt".

### D-018 — Người duyệt trang thử `require` (2026-11-25)
- Duyệt: `interface/stages/01-require.md`, `interface/invariants.md` (`INV-001`, `INV-002`), và
  `interface/overview.md` — phần khái niệm, "Khi nào một stage xong", bảng Giá trị, cách đọc trang, lý do chung.
- Còn là nháp trong `overview.md` (duyệt sau): câu một dòng của các stage khác `require` trong bảng Luồng
  (duyệt khi viết trang của stage đó); kịch bản xuyên suốt (viết khi đủ 8 trang); nghĩa của `agent` (chờ SP3).
- Khuôn sau trang thử là bản hiện hành, gom lại ở `docs/specs/SP1-interface.md`.

### D-019 — Người duyệt trang `plan` (2026-11-27)
- Duyệt: `interface/stages/00-plan.md` (qua 2 lần đọc lạnh); trong `overview.md` thêm khái niệm "điểm xuất phát"
  (dự án mới = "chưa có mã") và con trỏ tới danh sách job type.
- Chọn (theo đề xuất của agent):
  1. Giữ `CAP-plan-02` (agent): nguồn chỉ là tham chiếu có định danh hoặc lời người duyệt chép nguyên văn —
     mới so với v1 (v1 chỉ là quy tắc trong hướng dẫn phase). Vì: gốc của chuỗi truy vết; máy không phân biệt
     được lời người thật với câu agent gắn nhãn "lời người duyệt".
  2. Ưu tiên và ước lượng (v1 `CAP-plan-03/04`) ghi ở `Not in this stage`: quyết định giữa nhiều việc, quy trình
     đi theo một việc. Cần đo ước lượng sau này → thêm capability bằng D mới.
  3. `operational-feedback` là Input `Required: no` của `plan` (khớp vòng operate → plan); yêu cầu từ ngoài không
     làm artifact giả.
  4. "Vào ở phase nào cũng được" của v1 → SP3; `INV-001` đã buộc artifact nhập từ ngoài qua người duyệt.
- Không ghi dòng "ai cho phép kết thúc" ở trang: có chủ ý (D-016 D4).

### D-020 — Người duyệt trang `design` (2026-11-27)
- Duyệt: `interface/stages/02-design.md` (2 lần đọc lạnh). Người đồng ý cả 5 đề xuất; trang giữ nguyên.
- Chọn:
  1. Ngưỡng quyết định: người có hiểu biết có thể chọn khác **và** đổi về sau tốn hơn một lần sửa nhỏ (nhiều chỗ,
     dữ liệu đã lưu, giao diện bên ngoài dùng, không đảo ngược được). Chỉ vế đầu thì mọi chi tiết thành quyết định.
  2. `work-item` là Input của `design` (mã ở điểm xuất phát); máy kiểm thiết kế nêu mã bị đụng tới.
  3. `design` Approval `yes` cả khối, người duyệt duyệt từng quyết định (`CAP-design-04`); duyệt lại một quyết định
     hay cả khối → SP3.
  4. Mode 2 chống neo → SP7 (cần khái niệm mức rủi ro). 5. v1 `CAP-design-04` (tri thức bền vững) → SP7.
- Liên kết yêu cầu ↔ thiết kế ghi ở phía thiết kế (phần mô tả ghi yêu cầu nó phục vụ), không sửa `requirements` đã duyệt.
- Trang đã duyệt bị sửa chữ theo: `INV-001` (ví dụ "stage `design`"); `overview.md` (Work item, Yêu cầu, Câu hỏi mở,
  Quyết định, câu `design`).

### D-021 — Người duyệt trang `breakdown` và `INV-003..005` (2026-11-27)
- Duyệt: `interface/stages/03-breakdown.md` + `INV-003`, `INV-004`, `INV-005` trong `invariants.md` (2 lần đọc lạnh).
  Người đồng ý cả 5 đề xuất; trang giữ nguyên.
- Chọn:
  1. Thêm `INV-003` (truy vết task ↔ yêu cầu/phát hiện), `INV-004` (task chỉ dựa quyết định có trong thiết kế),
     `INV-005` (artifact dựng từ bản hiện hành của input; báo từ `design`, chặn ở `verify`) — từ INV-001/002/006 của v1.
     `INV-005` bắt chỗ `INV-001` không bắt: artifact không đổi nhưng input của nó đã đổi.
  2. Không hoãn yêu cầu trong kế hoạch (v1 cho): hoãn là đổi phạm vi → quay lại `require`, người duyệt duyệt lại.
  3. `review-report` là Input không bắt buộc; task sửa phát hiện nối thêm vào cuối, task cũ giữ nguyên (như v1).
  4. `task-plan` Approval `no` (như v1): máy kiểm truy vết, agent kiểm không thêm lựa chọn mới.
  5. `CAP-breakdown-02` (task đủ nhỏ, thứ tự làm được) và `-03` (không lựa chọn ngoài thiết kế), đều agent — mới so với v1.
- Trang đã duyệt bị sửa chữ theo: `overview.md` (Artifact ghi phiên bản input; Phát hiện; Phiên bản; Task; câu `implement`;
  sơ đồ có vòng `verify` → `breakdown`); `invariants.md` (nghĩa của Warned from).

### D-022 — Người duyệt trang `implement` và `INV-006` (2026-11-27)
- Duyệt: `interface/stages/04-implement.md` + `INV-006` (3 lần đọc lạnh, lần cuối không MAJOR). Người đồng ý cả 5
  đề xuất; trang giữ nguyên.
- Chọn:
  1. `INV-006` (mọi yêu cầu có test hoặc kiểm tay có lý do) chặn ở `implement`, không đợi `verify`: `verify` không
     sửa mã, chặn muộn chỉ làm vòng sửa dài hơn.
  2. Kiểm tay: kế hoạch quyết task nào kiểm tay; người kiểm là người duyệt hoặc agent khác agent đang làm; máy kiểm
     bản ghi đủ ý (ai, gì, thấy gì, vì sao không test được); `verify` phán nội dung.
  3. File ngoài kế hoạch chặn ở `implement` (v1 cảnh báo, chặn ở review); v1 `CAP-implement-04/05` gộp thành
     `CAP-implement-03`.
  4. Mới so với v1: chạy test trên điểm xuất phát (`CAP-implement-02`); khai test có sẵn bị sửa/xoá cho mọi loại việc
     (`CAP-implement-04`); task làm lần lượt.
  5. `security-evidence` ở `implement`, `verify` đọc; v1 `CAP-implement-07`, INV-012, INV-013 → SP7.
- Stage chỉ có capability `machine`: việc cần phán thuộc `verify`.
- Không trang đã duyệt nào bị sửa chữ theo.

### D-023 — Người duyệt trang `verify` và `INV-007` (2026-11-27)
- Duyệt: `interface/stages/05-verify.md` + `INV-007` (3 lần đọc lạnh; lần 3 còn 4 MAJOR: 3 sửa chữ đã sửa, 1 hỏi
  người ở mục 6). Người đồng ý cả 6 đề xuất; trang giữ nguyên.
- Chọn:
  1. Merge ở `deploy`: `verify` kết thúc bằng phán quyết merge được người duyệt xác nhận, người duyệt merge ở
     `deploy`. `INV-002` giữ `Checked at: verify`.
  2. `CAP-verify-03` (agent): đối chiếu yêu cầu với câu trả lời của câu hỏi mở nó trỏ tới (bắt câu trả lời đến
     muộn, D-017 R2).
  3. `INV-007` (`Checked at: verify`): mọi yêu cầu có phán quyết trong báo cáo rà (v1 INV-004).
  4. Kiểm thử đầu-cuối, đo tải, UAT là `CAP-verify-04`, `-05`, `-07`: mô tả trạng thái đích, bắt buộc dù engine
     chưa làm được.
  5. Giữ `CAP-verify-06` (người đọc mã nhạy cảm, v1 `CAP-verify-02`); tri thức bền vững (v1 `CAP-verify-06`) → SP7.
  6. Judged by `agent` ở `verify`: người đồng ý, nhưng lời đề xuất không được ghi vào repo. Ghi theo trang hiện
     hành: agent phán là agent phiên trắng, không phải agent đã làm thay đổi (`CAP-verify-01`). Bảng Giá trị ghi
     "khác với agent đang làm việc"; nghĩa đầy đủ vẫn chờ SP3 (D-018).
- `overview.md` câu `deploy` đã khớp mục 1, không đổi. Không trang đã duyệt nào bị sửa chữ theo.

### D-024 — Judged by `agent` ở `verify` là chính agent rà (2026-11-27)
- Làm rõ: D-023 mục 6.
- Lựa chọn: (A) "agent đang làm việc" là agent đã làm ra thay đổi: agent rà phiên trắng là agent phán, người duyệt
  xác nhận (`CAP-verify-08`); (B) là agent đang viết báo cáo rà: cần thêm một agent chấm báo cáo.
- Chọn: A — trang `verify` đã viết theo A; báo cáo đã có máy kiểm tính khớp (`CAP-verify-02`, `INV-007`) và người
  xác nhận; B thêm chi phí mà vẫn còn câu hỏi ai chấm agent thêm vào. Đánh đổi: agent rà phán sai "đạt" thì chỉ
  người duyệt bắt được.
- Trang đã duyệt bị sửa chữ theo: `overview.md`, dòng `agent` của bảng Giá trị. Nghĩa đầy đủ của `agent` vẫn chờ SP3.

## Đang mở

### Còn lại từ trang `verify` (để Task 9/10)
- MINOR: các giá trị phán quyết ("đạt", "nên merge", mức "chặn"/"nên sửa") chưa ở bảng Giá trị;
  `reproduction-evidence`, `performance-evidence` chờ `job-types.md` (Task 8) để C1 đạt.

### Ghi từ đọc lạnh trang `verify` (chờ)
- `overview.md`: câu "Luật xuyên stage cần người hay agent phán thì viết thành capability của `verify`" đọc được hai cách (mọi luật như vậy nằm ở `verify`, hay chỉ một số); làm rõ ở Task 9.

### Ứng viên SP7 (ghi khi viết trang, chưa quyết)
- Mode 2 chống neo của v1 (rủi ro cao → người duyệt phác quyết định trước, agent chỉ phản biện); cần thêm khái niệm mức rủi ro.
- Ghi lại tri thức bền vững sau khi rà (v1 `CAP-verify-06`).
- Tri thức bền vững (ADR, tài liệu module) mà `design` phải đọc (v1 `CAP-design-04`), và `implement` đọc trước task
  đầu tiên, tính từ phần mã trong kế hoạch (v1 `CAP-implement-07`); chỉ mục tri thức do máy dựng (v1 INV-013);
  con trỏ tới mục của tài liệu khác do máy giữ đúng (v1 INV-012).
- Mẫu phần mã của task quá rộng so với việc thì bị báo (vế sau của v1 `CAP-implement-05`).
- Câu trích nguyên văn của nguồn (`Quote` ở v1), nhãn nguồn (`[JIRA]`, `[FILE]`…), mã riêng cho câu hỏi mở (`Q-NNN`).
- "Đúng một nguồn" cho mỗi yêu cầu như v1 (tránh trạng thái lửng khi yêu cầu dựa trên hai câu hỏi, một
  đã trả lời một chưa) — v2 đang chọn "ít nhất một" (D-016 D3).

### Trang thử `require`
- `interface/stages/01-require.md` viết theo D-012, chuyển nội dung từ `sdlc/stages/01-require.md` của v1.
- Bước: cold read vòng 1 (agent phiên trắng) → người duyệt (vòng 2) → chỉnh khuôn nếu cần →
  mới viết spec SP1 và các trang còn lại.
- Cold read lần 1 (chỉ trang): ra D-014 và 6 sửa trang — nguồn là các nguồn trong work item; thêm
  `CAP-require-04` (người trả lời câu hỏi `blocking` và duyệt); câu trả lời của người là phần duyệt cho
  câu hỏi đó; "tự trả lời … mà không ghi lại"; viết lại câu ba mức chặn.
- Cold read lần 2 (trang + overview): ra D-015. Lần 3 (+ invariants): ra D-016.
- Cold read lần 4 (lần cuối vòng 1): trả lời đủ 5 câu; 1 MAJOR, phần lớn nằm ngoài trang (xem "Chuyển
  cho SP3"); phần trong trang và các MINOR đã sửa: `CAP-require-05` áp dù câu trả lời đến ở stage nào;
  `CAP-require-04` nói rõ thứ tự (trả lời câu `blocking` → sửa yêu cầu → duyệt); nguồn của yêu cầu gồm
  giả định của câu hỏi mở; nghĩa của Approval `no`; câu trả lời ghi cạnh câu hỏi; liệt kê trường của invariant.
- **Vòng 1 xong.** Người yêu cầu thêm một lượt rà trước khi duyệt → D-017.
- **Bước tiếp: người duyệt trang (vòng 2).**

### Ghi chú cho các trang chưa viết
- `job-types.md`: `deploy` không bao giờ bị bỏ (merge nằm ở đó); chỉ phần phát hành được vắng, ghi "không phát hành"
  kèm lý do, người duyệt xác nhận (Task 6). v1 ghi `deploy` tuỳ chọn ở cả 5 loại — không theo.
- `overview.md` (Task 9), từ đọc lạnh trang `deploy`: định nghĩa artifact `change` ("phiên bản thay đổi"); "xác nhận"
  khác "duyệt" thế nào (báo cáo rà, đường lui); dùng một từ giữa "phát hành" và "triển khai"; môi trường chạy, hệ
  thống triển khai. `delivery` có thuộc `INV-005` không (hiện chỉ `CAP-deploy-01` giữ phiên bản) → Task 10.
- `overview.md` (Task 9): Lý do chung "`deploy` và `operate` chỉ là điểm nối" lệch với merge ở `deploy`; sửa thành
  phần phát hành của `deploy` và `operate` là điểm nối.
- `job-types.md`: chưa viết; khi viết, kiểm `blocking` ("trước khi `require` xong") vẫn đúng với job type bỏ `design`.
- `job-types.md`: stage bị bỏ thì artifact của nó vắng, mà Input của stage sau ghi Required `yes` (ví dụ `design` ở
  `breakdown`, `implement`) — nói rõ luật này. Refactor/perf: không xoá test có sẵn (v1 INV-009), chặt hơn `CAP-implement-04`.

### Chuyển cho SP3 (thấy khi cold read trang `require`)
- Câu trả lời đến **sau khi** `require` đã xong (câu `review-blocking`, `non-blocking`) mà khác giả định:
  ai sửa `requirements`, ở stage nào, có chạy lại `require` không; sau khi duyệt lại thì artifact của các
  stage đã chạy (thiết kế, kế hoạch…) xử lý thế nào.
- Ai tuyên bố một stage xong, và ai khởi động stage tiếp theo.
- `implement`: ngưỡng quét bảo mật (mức nào tính là không đạt); trần số lần chạy đỏ liên tiếp (v1 `MAX_RED_RUNS`);
  quét theo từng task hay một lần cuối; vòng `verify` → `implement` có chạy lại test trên điểm xuất phát không.
- "Vào ở phase nào cũng được" của v1: bắt đầu từ stage bất kỳ với artifact làm bằng công cụ khác (D-019).
- Yêu cầu hay thiết kế đổi sau khi kế hoạch đã có: kế hoạch dựng lại — giữ trạng thái task đã làm thế nào (v1: `aw task reopen`).
- Một quyết định của `design` bị sửa: duyệt lại cả thiết kế hay chỉ quyết định đó (dấu duyệt theo từng quyết định là chi tiết engine; interface chỉ đòi dấu duyệt khớp nội dung, `INV-001`).
- Invariant chỉ được kiểm khi **kết thúc** stage: input chưa duyệt chỉ bị bắt ở cuối stage dùng nó, sau khi
  đã tốn công chạy. Kiểm thêm lúc **bắt đầu** stage là tối ưu của engine, không đổi interface.
- `overview.md` hiện là bản tối thiểu cho phép thử: một câu mỗi stage trong bảng Luồng là nháp từ v1,
  duyệt khi viết từng trang; kịch bản xuyên suốt viết khi đủ 8 trang; nghĩa của `agent` (một agent khác
  với agent đang làm việc) chờ SP3 chốt.
