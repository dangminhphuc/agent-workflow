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

### D-025 — Người duyệt trang `deploy` (2026-11-27)
- Duyệt: `interface/stages/06-deploy.md` (3 lần đọc lạnh). Người đồng ý 4 đề xuất sau lần 1; các sửa sau lần 2, 3 là chữ.
- Chọn:
  1. `delivery` Approval `no`: kết quả phát hành ghi sau khi người xác nhận đường lui, duyệt cả khối sẽ mất hiệu lực
     mỗi lần hệ thống triển khai báo về; người duyệt xác nhận từng phần (merge, đường lui hoặc "không phát hành").
  2. `deploy` không bao giờ bị bỏ (merge nằm ở đó); chỉ phần phát hành được vắng, ghi lý do, người duyệt xác nhận
     trước khi merge. v1 cho bỏ `deploy` ở cả 5 loại việc — không theo (Task 8 phải khớp).
  3. Merge chỉ khi phiên bản sắp merge trùng phiên bản đã rà và phán quyết là "nên merge" (`CAP-deploy-01`, máy kiểm
     trước merge); không đồng ý phán quyết thì sửa báo cáo ở `verify`.
  4. Phát hành không đạt: người duyệt quyết hoàn tác hoặc phát hành lại; chưa có một trong hai thì stage chưa xong; lỗi
     đã gây hoàn tác đi qua `operate` thành việc mới, không quay lại `implement` (thay đổi đã merge).
  5. Triển khai thật là việc của hệ thống bên ngoài; `CAP-deploy-04` chỉ đòi kết quả do hệ thống đó báo về, máy ghi.
  6. `CAP-deploy-02` giữ `Judged by: human` như `CAP-verify-06` (người làm và chịu trách nhiệm).
- Trang đã duyệt bị sửa chữ theo: `overview.md` mục "Khi nào một stage xong" — bước 1 kiểm cả điều phải đúng trước việc
  người làm; bước 2 thêm việc chỉ người được làm (như merge); bước 3 kiểm kết quả việc người làm; chỉ nội dung do agent
  viết mới làm quay lại bước 1.

### D-026 — Người duyệt trang `operate` (2026-11-27)
- Duyệt: `interface/stages/07-operate.md` (3 lần đọc lạnh; các sửa sau mỗi lần là chữ hoặc hệ quả của D-025).
- Chọn:
  1. Output `operational-feedback` (khớp Input của `plan`), Approval `no`: người duyệt quyết từng mục ngay khi mục được ghi.
  2. Quan sát production là `CAP-operate-01` (machine): tín hiệu do hệ thống giám sát bên ngoài báo về, máy ghi.
  3. Người duyệt quyết mỗi mục thành việc mới hay không, kèm lý do (`CAP-operate-03`, v1 `CAP-operate-02`); quyết cả
     hoàn tác khi sự cố xảy ra với bản đang chạy. Lỗi đã gây hoàn tác luôn thành việc mới.
  4. Hậu kiểm sự cố (postmortem) không vào interface.
  5. Mới: khoảng theo dõi — tính từ lúc phát hành, độ dài người duyệt đặt, kết thúc khi hết thời gian hoặc khi hoàn tác —
     để stage có điểm kết thúc; không phát hành thì stage xong ngay.
  6. Mới: `CAP-operate-02` (agent) — agent không làm ra thay đổi ghi mọi điều bất thường thành mục, không tự bỏ.
- Không trang đã duyệt nào bị sửa chữ theo.

### D-027 — Người duyệt `job-types.md` và `INV-008`…`INV-013` (2026-11-27)
- Duyệt: `interface/job-types.md` + `INV-008`…`INV-013` trong `invariants.md` (3 lần đọc lạnh, lần cuối không MAJOR).
  Người đồng ý 5 đề xuất sau lần 1; sửa sau lần 2, 3 là chữ.
- Chọn:
  1. 5 loại như v1; `Definition` mỗi loại nói khác loại gần nó ở đâu. `design` Optional ở `bugfix`, `refactor`; Skipped ở
     `chore`. Không loại nào bỏ `deploy` (D-025). Khái niệm "mã production" (người duyệt khai) ở `job-types.md`.
  2. Luật riêng thành invariant Only for (từ v1 INV-007…011), đều chặn ở `implement`: `INV-008` test tái hiện đỏ rồi xanh;
     `INV-009` yêu cầu ghi loại, yêu cầu giữ hành vi có test có sẵn (báo từ `require`); `INV-010` không xoá test có sẵn,
     kể cả đã khai; `INV-011` số đo trước/sau do máy ghi; `INV-012` không đụng mã production, thư viện đổi được khai.
  3. `INV-013`: bỏ stage tuỳ chọn ghi trong `requirements` kèm lý do, duyệt cùng danh sách yêu cầu; Checked at `breakdown`.
     Không ghi ở `work-item`: quyết muộn sẽ làm `work-item` đổi, phải chạy lại `require`.
  4. → SP7: `bugfix` không thêm hành vi mới; `chore` không nâng phiên bản lớn. Bỏ: hai việc agent phán ở `verify` của v1
     (vì sao test tái hiện đỏ; sửa test không đổi khẳng định) — đã có `INV-008`, `CAP-verify-01`, `CAP-implement-04`.
  5. Ranh giới chặt: lỗi "hiển nhiên" chưa ghi ở tài liệu, yêu cầu hay phiên bản trước là `feature`.
- Trang đã duyệt bị sửa chữ theo: `overview.md` (backtick được chứa tên job type; dòng Job type trỏ tới `job-types.md` và
  invariant có Only for).

### D-028 — Người duyệt `overview.md` đã hoàn thiện (2026-11-27)
- Duyệt: Khái niệm (thêm Thay đổi, Phán quyết, Bằng chứng, Phát hành, Đường lui; sửa Stage, Quyết định, Dấu duyệt —
  "xác nhận" là duyệt một điều cụ thể —, Invariant, Task), bảng Luồng khớp 8 trang, Lý do chung (merge là điểm cuối của
  lõi; phần phát hành của `deploy` và `operate` là điểm nối), Kịch bản xuyên suốt.
- Kịch bản: người chọn `feature` "khoá tài khoản sau 5 lần đăng nhập sai" (có `design`) thay cho `bugfix` đề xuất.
- Giá trị phán quyết ("đạt", "nên merge", mức "chặn"/"nên sửa") định nghĩa bằng văn xuôi ở Khái niệm, không vào bảng
  Giá trị: các trang viết chúng trong ngoặc kép, không trong backtick.
- Giữ: nghĩa đầy đủ của `agent` chờ SP3.

### D-029 — SP1 xong: người duyệt cả bộ `interface/` (2026-11-27)
- Duyệt: `overview.md`, `invariants.md` (`INV-001`…`INV-013`), `job-types.md`, 8 trang stage — sau kiểm chéo (luật chặn §5 của
  spec đạt trên cả bộ) và 3 lần đọc lạnh toàn bộ (8, 4, 2 MAJOR; lần 3 chỉ còn sửa chữ).
- Chọn trong lúc đọc lạnh toàn bộ:
  1. `INV-005` không tính `open-questions` (câu trả lời khác giả định đã buộc sửa `requirements`), và không tính
     `review-report` khi kiểm ở `verify` (để vòng sửa khép được).
  2. `CAP-verify-05`: yêu cầu không nêu mục tiêu tải hay độ trễ → agent rà ghi phát hiện chặn, quay lại `require`.
  3. Lượt `verify` cho "không nên merge" xong khi người duyệt xác nhận báo cáo; `CAP-verify-04`, `-05`, `-07` và `INV-002`
     chỉ bắt buộc ở lượt cho "nên merge".
- Sửa nhất quán (trang đã duyệt đổi chữ theo): `review-report` ghi lựa chọn của người duyệt với phát hiện nên sửa;
  `requirements` ghi stage bị bỏ (`INV-013`); `breakdown` dựng lại kế hoạch khi phát hiện qua `require`/`design`; lời khai
  của `change` gồm điều job type đòi khai; người duyệt đặt khoảng theo dõi (`CAP-operate-03`); kịch bản xuyên suốt.
- MINOR còn lại giữ ở § Đang mở, sửa ở lần chỉnh interface sau (SP2 sẽ bắt một phần bằng máy).
- Tiếp: SP7 — chọn lại tính năng của v1.

### D-030 — SP7 vấn đề 1: tri thức bền vững — lõi nhỏ ở interface, cơ chế cho SP3/SP4 (2026-11-28)
- Bài toán: phiên agent mới chỉ có repo phải biết vì sao mã như vậy (D-004); tài liệu lệch mã tệ hơn không có. v1 giải bằng
  ADR máy dựng lại so byte, luật `BR-`, phạm vi tài liệu, verdict stale, chỉ mục máy giữ — điểm yếu 18–21 của v1 đều nằm ở
  cơ chế này (trùng số ADR, phạm vi thô nên quen tay `pass`, nguồn đổi sau khi nâng).
- Phương án: A. đưa đầy đủ như v1 vào interface (chặt nhất, kéo ADR/`BR-`/chỉ mục vào interface, trái D-014);
  **B. lõi nhỏ ở interface, cơ chế cho SP3/SP4**; C. để sau (nhẹ nhất, trái D-004).
- Chọn **B**. Interface đòi ba điều:
  1. `design` đọc tri thức có sẵn của phần mã bị đụng; thiết kế ghi đã dựa vào hay đi ngược tri thức nào.
  2. Người duyệt đánh dấu quyết định hoặc yêu cầu cần lưu bền; khi đó thay đổi phải chứa tài liệu tương ứng (máy kiểm là có).
  3. `verify` phán tài liệu bị thay đổi ảnh hưởng còn đúng không (agent rà phán, người duyệt xác nhận).
- Chuyển cho SP3/SP4: định dạng ADR, đánh số, chỉ mục, phạm vi tài liệu, máy dựng lại để so, con trỏ tới mục (v1 INV-012,
  INV-013). `/aw-bootstrap` thành tiện ích của SP3/SP5 (dựng tri thức ban đầu cho repo có sẵn), không phải khái niệm interface.
- `implement` đọc tri thức (v1 `CAP-implement-07`) không thành capability riêng: `implement` theo thiết kế đã ghi tri thức
  dùng tới; nạp gì vào ngữ cảnh agent là việc của SP3.
- Lý do: ba điều trên là phần v1 chứng minh là cần; phần gây đau ở v1 nằm ở cơ chế, không ở nhu cầu.

### D-031 — SP7 vấn đề 2: mức rủi ro và chống neo bản nhẹ (2026-11-28)
- Bài toán: agent đề xuất thì người duyệt dễ gật theo (neo); với việc khó đảo ngược (tiền, schema lõi, tích hợp mới) duyệt
  cho qua rất đắt. v1: `Risk: high|normal` ở spec, `high` → Mode 2 (người viết quyết định trước, agent chỉ phản biện);
  Mode 2 phải chữa hai lần (người bị bỏ trơ → hỏi dẫn; hỏi từng quyết định → gom một lượt).
- Phương án: A. giữ Mode 2 như v1 (mạnh nhất, nặng — người phải tự nghĩ phương án); **B. mức rủi ro ở interface, chống neo
  bản nhẹ**; C. bỏ, dựa `CAP-design-01`/`-04` (gọn, không bảo đảm gì cho việc rủi ro cao).
- Chọn **B**:
  - Mức rủi ro chốt ở `require`, agent đề xuất kèm lý do, người duyệt chốt.
  - Rủi ro cao → mỗi quyết định ở `design`: agent liệt kê phương án và đánh đổi, không đề xuất, không xếp hạng; người duyệt
    chọn và ghi lý do bằng lời mình; sau đó agent mới phản biện.
  - Máy kiểm: có mức rủi ro; rủi ro cao thì mỗi quyết định có lý do do người ghi. Agent rà ở `verify` phán "agent không gợi ý".
- Chốt theo đề xuất của agent (người duyệt chọn B, không sửa hai điểm phụ): hai bậc cao/thường như v1; thay đổi đụng mã
  đã khai nhạy cảm (`CAP-verify-06`) thì mặc định rủi ro cao.
- Lý do: thứ chống neo là người chọn trước khi nghe ý agent; bắt người tự nghĩ phương án thêm ít mà là chỗ v1 đau. Gắn với
  mã nhạy cảm để không khai hai lần.

### D-032 — SP7 vấn đề 3: truy vết nguồn — con trỏ tới đoạn và phủ chiều ngược (2026-11-28)
- Bài toán: `CAP-require-01` buộc chỉ ra nguồn nhưng còn hai lỗ — nói sai nguồn (diễn giải lệch, trỏ nhầm mục) và bỏ sót
  nguồn (nguồn nói mà không yêu cầu nào nhận).
- Phương án đã xét: A. câu trích nguyên văn, máy kiểm có trong nguồn; B. không trích, agent rà ở `verify`; **C. con trỏ
  chính xác tới đoạn, máy giải con trỏ**; D. agent rà phiên trắng ở `require`; **E. phủ chiều ngược nguồn → yêu cầu**;
  F. độ chặt theo rủi ro.
- 3a — chọn **C + E**:
  - Work item giữ bản chữ của nguồn, chia đoạn trỏ được (lời người duyệt nói miệng cũng ghi thành chữ ở đây); bản đã ghi
    không sửa, nguồn đổi thì thêm bản mới.
  - Mỗi yêu cầu trỏ tới đoạn cụ thể nó dựa vào; máy kiểm mọi con trỏ tới đoạn có thật. Khi duyệt `require`, công cụ hiện
    đoạn nguồn cạnh từng yêu cầu; người duyệt phán khớp.
  - Mỗi đoạn nguồn được ít nhất một yêu cầu trỏ tới, hoặc ghi "ngoài phạm vi" kèm lý do (người duyệt duyệt cùng
    `requirements`); máy kiểm không đoạn nào bị bỏ.
  - Loại A (chép chữ thêm, C kiểm tương đương), B (bắt quá muộn), D (thêm lượt agent mà vẫn có thể sai), F (thêm nhánh
    luật; C+E đủ nhẹ cho mọi việc).
- 3b — nhãn nguồn (`[JIRA]`, `[FILE]`…) và mã `Q-NNN` chuyển cho SP3 (định dạng); interface chỉ đòi nguồn và câu hỏi mở
  trỏ tới được.
- 3c — giữ "ít nhất một nguồn" (D-016 D3): yêu cầu còn là giả định chừng nào còn câu hỏi nó dựa vào chưa trả lời; câu trả
  lời khác giả định → `INV-005` buộc sửa `requirements`. "Đúng một" bắt tách giả tạo.
- Chuyển cho SP3: định dạng bản chữ nguồn, cách chia đoạn, dạng con trỏ, hiển thị cạnh nhau.

### D-033 — SP7 vấn đề 4: agent phán "đạt" phải có bằng chứng (2026-11-28)
- Bài toán: capability `Judged by agent` (quyết định ngầm, lệch quyết định, mã làm đúng yêu cầu…) — agent được kết luận
  tới đâu. v1: LLM checker không bao giờ nói "đạt", chỉ ghi phát hiện chặn (thực chất "đạt ngầm" khi không có phát hiện);
  v2 D-024: agent rà phán đạt/không, người duyệt xác nhận — agent phán nhầm "đạt" chỉ người duyệt bắt.
- Phương án: A. giữ D-024 ("đạt" trông như đã kiểm xong, dễ xác nhận cho qua); B. về v1, chỉ được chặn (người nhẹ nhất,
  agent bỏ sót thì không ai thấy agent đã nhìn gì); **C. bất đối xứng, "đạt" phải có bằng chứng**.
- Chọn **C**:
  - "Không đạt" của agent đủ để chặn.
  - "Đạt" kèm bằng chứng trỏ tới chỗ cụ thể (đoạn mã, test, mục artifact), cùng loại con trỏ máy giải được như D-032;
    "đạt" không bằng chứng hoặc con trỏ hỏng thì máy coi là chưa phán.
  - Người duyệt xác nhận báo cáo, bằng chứng hiện cạnh từng mục (giữ D-024).
  - Áp cho mọi capability `Judged by agent` ở mọi stage, không chỉ `verify`.
- Lý do: giữ ý v1 ("đạt" không rẻ) mà vẫn giữ người xác nhận; dùng lại con trỏ D-032, không thêm khái niệm. Đánh đổi:
  báo cáo dài hơn; bằng chứng thật vẫn có thể bị hiểu sai, người duyệt là chốt cuối.

### D-034 — SP7 vấn đề 5: luật treo của `bugfix` và `chore` (2026-11-28)
- 5a — `bugfix` không thêm hành vi mới (máy không phân biệt sửa với thêm). Phương án: **A. capability agent ở `verify`,
  chỉ `bugfix`**; B. chuyển lên `require`: mỗi yêu cầu `bugfix` trỏ (D-032) tới chỗ hành vi đúng đã định nghĩa, cộng vế
  chung "không thêm hành vi ngoài yêu cầu" ở `verify`; C. bỏ.
  - Chọn **A** (người duyệt chọn khác đề xuất B của agent): agent rà liệt kê mọi thay đổi hành vi quan sát được trong
    diff; mỗi thay đổi trỏ tới chỗ hành vi đúng đã được định nghĩa (tài liệu, yêu cầu đã duyệt, phiên bản trước), bằng
    chứng theo D-033; thiếu thì phát hiện chặn. Đánh đổi: bắt sau khi đã code.
- 5b — `chore` không nâng phiên bản lớn (v1 INV-011). Phương án: A. cấm nâng bản lớn theo semver (trói interface vào cách
  đánh số từng hệ sinh thái, trái D-014); B. bỏ, dựa test và kiểm thử đầu-cuối; **C. phá vỡ theo lời chính thư viện**.
  - Chọn **C**: thư viện được nâng mà ghi chú phát hành có thay đổi phá vỡ thì việc không phải `chore` mà là `refactor`
    (`INV-009` giữ hành vi bằng test có sẵn). Agent rà phán ở `verify`, bằng chứng là con trỏ tới ghi chú phát hành
    (D-033). Đánh đổi: ghi chú phát hành kém thì agent phán sai.

### D-035 — SP7 vấn đề 6: phần mã của task quá rộng — chặn trước bằng ngưỡng, đo sau bằng thực tế (2026-11-28)
- Bài toán: `CAP-implement-03` chỉ chặt bằng phần mã đã khai; task khai `src/**` thì luật luôn đạt. `task-plan` Approval
  `no` nên không người nào duyệt độ rộng. v1: vế sau `CAP-implement-05` báo mẫu quá rộng.
- Phương án: **A. máy kiểm ngưỡng ở `breakdown`**; B. agent phán ở `breakdown` (mơ hồ, dễ cho qua); **C. máy đo sau ở
  `verify`** (khai so với đụng thật); D. bỏ (lỗ `src/**` còn nguyên).
- Chọn **A + C**:
  - A: máy đếm số file phần mã mỗi task khớp trên điểm xuất phát; vượt ngưỡng repo khai thì chặn, trừ khi task ghi lý do
    và người duyệt duyệt riêng lý do đó.
  - C: ở `verify`, máy so phần mã đã khai với file thực sự đổi; khai rộng hơn nhiều thì ghi phát hiện **mức không chặn**
    (mã đã viết, thu hẹp lúc này không sửa được gì); task đã được duyệt vượt ngưỡng ở A thì C không báo.
- Chuyển cho SP3: nơi khai và mặc định của ngưỡng số file (A) và tỉ lệ khai/đụng (C).
- Lý do: A chặn trước vì không ai duyệt `task-plan`; C bắt phần mã dưới ngưỡng mà vẫn quá rộng và cho số liệu để chỉnh
  ngưỡng (nối vấn đề 9). Đánh đổi: hai con số đoán; C có thể nhiễu — giữ ở mức không chặn để không thành "quen tay pass".

### D-036 — SP7 vấn đề 7: lời khai của repo là thứ được duyệt, luật đọc bản ở điểm xuất phát (2026-11-28)
- Bài toán: nhiều luật dựa vào điều repo khai (mã production, mã nhạy cảm `CAP-verify-06`/D-031, ngưỡng phần mã D-035,
  quy ước); interface chỉ ghi "khai ở đâu ngoài interface" → không gì cấm agent sửa chính lời khai để tự nới luật.
  v1: `conventions.md` trong git, `rules_<phase>`/`uses_<phase>`, bản clone chỉ ghi đè khoá máy.
- Phương án: **A. khái niệm "lời khai của repo" ở interface, nội dung/định dạng cho SP3**; B. giữ hiện tại, để SP3 (lỗ tự
  nới luật không được interface đòi vá); C. như v1, `conventions.md` + rules/uses vào interface (trái D-014).
- Chọn **A**:
  1. Lời khai có dấu duyệt của người.
  2. Thay đổi đụng lời khai thì phần đụng đó được người duyệt duyệt riêng (máy kiểm).
  3. Luật dùng lời khai đọc bản ở điểm xuất phát, không đọc bản thay đổi vừa sửa.
  4. Quy ước của repo (cách viết mã, kiến trúc) là một phần lời khai; agent rà ở `verify` phán mã theo quy ước, bằng
     chứng theo D-033; vi phạm ghi phát hiện **mức không chặn** (người duyệt chọn — vi phạm quy ước thường nhỏ).
- Chuyển cho SP3: nơi giữ và định dạng lời khai; `rules_<phase>`/`uses_<phase>` (nạp gì vào ngữ cảnh, gọi skill nào).
- Lý do: điểm 3 chặn thay đổi tự nới luật cho chính nó — cùng ý v1 "bản clone không ghi đè khoá luật".

### D-037 — SP7 vấn đề 8: bảo mật — khung chọn hướng, không theo v1 (2026-11-28)
- Người duyệt yêu cầu tiếp cận lại, không dùng lại v1 (v1 dồn hết vào phát hiện trong mã: nhóm quét + Lens 4 7 hạng mục).
- Hai loại rủi ro: sản phẩm có lỗ hổng; chính quy trình có agent bị lợi dụng (agent có quyền, đọc nội dung không tin cậy).
- Mười hướng: H1 bảo mật thành yêu cầu (tình huống lạm dụng ở `require`); H2 mô hình mối đe doạ ở `design`; H3 luật cấu
  trúc repo khai, máy kiểm; H4 phát hiện trong mã (máy quét, agent đọc ý đồ, người đọc mã nhạy cảm); H5 lúc chạy; H6 nguồn
  là nội dung không tin cậy (prompt injection); H7 quyền tối thiểu theo stage; H8 phụ thuộc mới do agent đưa vào; H9 secret
  và dữ liệu nhạy cảm trong artifact; H10 agent làm yếu hàng rào (cấu hình quét, CI).
- Không hướng nào tự bắt buộc. Xếp mỗi hướng vào một mức — luôn áp dụng / mặc định bật, tắt bằng lời khai có duyệt (D-036) /
  theo rủi ro (D-031) / ngoài interface — theo ba câu hỏi: lọt có đảo ngược được không; lớp khác có bắt không; phòng rẻ
  không, máy làm được không.
- Xếp (người duyệt đồng ý, còn chỉnh khi đi sâu): luôn áp dụng H6, H9, H10; mặc định bật H4 máy quét, H8, H3; theo rủi ro
  H1, H2, H4 agent đọc ý đồ (còn cân nhắc mặc định bật); đã có H4 người đọc mã nhạy cảm (`CAP-verify-06`); ngoài interface
  H5 (phần lớn), H7 (cơ chế; interface có thể ghi nguyên tắc).
- Đi sâu theo thứ tự: luôn áp dụng → mặc định bật → theo rủi ro. Mỗi hướng chốt thành mục riêng.

## Đang mở

### Ứng viên SP7 (ghi khi viết trang, chưa quyết)
- (→ D-031) Mode 2 chống neo của v1 (rủi ro cao → người duyệt phác quyết định trước, agent chỉ phản biện); cần thêm khái niệm mức rủi ro.
- (→ D-030) Ghi lại tri thức bền vững sau khi rà (v1 `CAP-verify-06`).
- (→ D-034) `bugfix` không thêm hành vi mới: capability `agent` ở `verify` (máy không phân biệt được sửa với thêm) — Task 8.
- (→ D-034) `chore` không nâng phiên bản lớn của thư viện (v1 INV-011) — phụ thuộc cách đánh số của từng hệ sinh thái — Task 8.
- (→ D-030) Tri thức bền vững (ADR, tài liệu module) mà `design` phải đọc (v1 `CAP-design-04`), và `implement` đọc trước task
  đầu tiên, tính từ phần mã trong kế hoạch (v1 `CAP-implement-07`); chỉ mục tri thức do máy dựng (v1 INV-013);
  con trỏ tới mục của tài liệu khác do máy giữ đúng (v1 INV-012).
- (→ D-035) Mẫu phần mã của task quá rộng so với việc thì bị báo (vế sau của v1 `CAP-implement-05`).
- (→ D-032) Câu trích nguyên văn của nguồn (`Quote` ở v1), nhãn nguồn (`[JIRA]`, `[FILE]`…), mã riêng cho câu hỏi mở (`Q-NNN`).
- (→ D-032) "Đúng một nguồn" cho mỗi yêu cầu như v1 (tránh trạng thái lửng khi yêu cầu dựa trên hai câu hỏi, một
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

### MINOR còn lại của SP1 (sửa ở lần chỉnh interface sau)
- Thuật ngữ chưa ở Khái niệm: kiểm thử đầu-cuối / hệ thống đã ghép, UAT, người yêu cầu, lượt rà, lời khai, loại yêu cầu
  "tái cấu trúc" (`INV-009`), "có thật" (`INV-003`, `INV-007`).
- `INV-005` Warned from `design`: việc bỏ `design` thì báo từ stage nào.
- `INV-009`: ghi thêm yêu cầu vào một test có sẵn có tính là sửa test (phải khai) không.
- `CAP-plan-01` ghi "danh sách job type (xem overview)": danh sách nằm ở job-types.md.
- `delivery` có thuộc `INV-005` không (hiện chỉ `CAP-deploy-01` giữ phiên bản).

### Chuyển cho SP3 (thấy khi cold read trang `require`)
- Việc đã bỏ `design` mà `verify` có phát hiện đụng tới lựa chọn kỹ thuật: chạy `design` lúc đó, việc bỏ ghi trong
  `requirements` hết hiệu lực (duyệt lại) — từ đọc lạnh `job-types.md`.
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
