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

## Đang mở

### SP1-3 — Khuôn trang invariant và trang job type
- Agent đề xuất (chờ người duyệt), cùng nguyên tắc D-011:
  - `interface/invariants.md`, mỗi luật: `### INV-NNN — <tên>` + `- Rule:` + `- Stages:` (stage phải
    giữ) + `- Judged by:` + `- Fail example:` + `- Rationale:`.
  - Bỏ `Enforced by:` / `Tested by:` của v1 khỏi interface: chúng trỏ tới file engine, phá ranh giới
    "interface không biết engine". Ánh xạ luật → checker → test chuyển sang phía engine (SP4); máy vẫn
    chặn invariant không có checker.
  - `Stages:` ở invariant và `## Invariants` ở trang stage là hai nguồn của cùng một quan hệ → chỉ giữ
    một: `Stages:` ở invariant; trang stage hiển thị danh sách do máy sinh (bỏ mục `## Invariants`
    khỏi khuôn D-011).
  - `interface/job-types/<id>.md`: `# Job type: <id>` + `## Definition` + `## Stages` (bảng: Stage ·
    Run `always` \| `optional` \| `skip` · Why) + `## Adds` (artifact, invariant thêm) + `## Rationale`.
  - Danh sách job type tạm theo v1: `feature`, `bugfix`, `refactor`, `perf`, `chore`; nội dung duyệt khi
    viết trang.
