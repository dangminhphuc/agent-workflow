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

## Đang mở

### SP1-2 — Khuôn của một trang stage
- Câu hỏi: một trang stage gồm những mục nào, mục nào trình biên dịch đọc, mục nào là văn xuôi tự do,
  viết bằng ngôn ngữ nào.
- Agent đề xuất (chờ người duyệt):
  - Một file mỗi stage: `interface/stages/NN-<id>.md`.
  - Mục theo thứ tự cố định (heading tiếng Anh, là từ khoá trình biên dịch tìm):

    | Mục | Nội dung | Trình biên dịch |
    |---|---|---|
    | `# Stage: <id>` | Tên stage | đọc `id` |
    | `## Definition` | Một–hai câu: stage này là gì | chỉ kiểm có, không rỗng |
    | `## Purpose` | Vì sao cần; bỏ đi thì hỏng gì | chỉ kiểm có, không rỗng |
    | `## Input` | Bảng: Artifact · Required (`yes`/`no`) · From stage · Used for | đọc |
    | `## Output` | Bảng: Artifact · Description | đọc |
    | `## Exit` | `- Judged by: machine \| human \| both`, `- Skippable: yes \| no`, rồi văn xuôi: máy kiểm gì, người duyệt gì | đọc 2 dòng đầu |
    | `## Capabilities` | Mỗi cái: `### CAP-<id>-NN — <tên>` + `- Rule:` + `- Judged by:` + `- Artifact:` + `- Pass example:` + `- Fail example:` | đọc tất cả |
    | `## Invariants` | Danh sách `INV-NNN` stage phải giữ | đọc |
    | `## Example` | Ví dụ vào/ra cụ thể, trọn một lượt | chỉ kiểm có, không rỗng |
    | `## Not in this stage` | Ranh giới: việc dễ tưởng thuộc stage này nhưng không | chỉ kiểm có, không rỗng |
    | `## Rationale` | Lý do thiết kế, lựa chọn đã bỏ | chỉ kiểm có, không rỗng |

  - Ngôn ngữ: heading, tên trường, id, tên loại artifact, giá trị enum bằng tiếng Anh (từ khoá ổn định
    cho trình biên dịch). Mọi chữ người viết — kể cả `Rule:` — bằng tiếng Việt.
  - Mới so với v1: ví dụ đạt/không đạt cho từng capability (giúp người hiểu, và là mầm test case cho
    SP4); bảng Input ghi stage nguồn và dùng để làm gì; mục ranh giới và lý do nằm ngay trong trang.
  - Văn xuôi bắt buộc có nhưng không bị biên dịch: trình biên dịch chặn mục rỗng, nên trang không thể
    "đủ khuôn" mà thiếu phần giải thích cho người.
