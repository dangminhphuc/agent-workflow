# Adapter

Adapter là lớp **mỏng** sinh ra từ `workflow/`. Nó chỉ dịch định nghĩa phase sang
dạng native của một agent và dặn agent gọi `aw …`. Luật cứng nằm trong checker
của engine: mã thoát và nhãn `Kết quả` của `aw check <tên>`. Không luật nào dựa
vào tính năng riêng của agent.

## Hợp đồng của một adapter

Thư mục `adapters/<id>/` gồm:

| File | Vai trò |
|---|---|
| `build.sh` | `sh build.sh --out <thư-mục> [--force]` — sinh file native vào `<thư-mục>` |
| `exclude` | Đường dẫn adapter sinh ra, mỗi dòng một mẫu (`/.claude/`). `aw init` thêm vào `.git/info/exclude` |
| `README.md` | Biên dịch ra gì, cái gì không portable |

Phần dùng chung nằm trong `adapters/lib/chung.sh`: kiểm `exit_machine` là
`aw check <tên>` có thật, không ghi đè file người viết tay, bỏ qua file git đang
theo dõi (bộ cài cũ), dọn file sinh tự động đã cũ, các bước "xác định feature"
và "phân loại input".

`aw adapter build <id>` (cũng chạy trong `aw init` và `aw worktree new --create`)
làm hai bước:

1. Chép `workflow/{rules,templates,checkers}` của engine vào
   `.agent-workflow/.engine/` (bị exclude); `conventions.md` ở đó là liên kết
   tới cấu hình của bản clone. Bước này dùng chung, agent nào cũng đọc được.
2. Chạy `adapters/<id>/build.sh --out <worktree>`.

Mọi file sinh ra nằm trong đường dẫn đã exclude — không lọt vào commit, không
cần sửa base.

## Adapter đang có

| id | Trạng thái |
|---|---|
| `claude-code` | Có — xem [claude-code/README.md](claude-code/README.md) |
| `codex` | Chưa viết — ghi chú bên dưới |
| `cursor` | Chưa viết — ghi chú bên dưới |

## Ghi chú cho adapter sau này

Chỉ ghi điều đã kiểm được. Lần soạn này (2026-10) không truy cập được trang tài
liệu của OpenAI và Cursor; phần Codex dưới đây đọc từ mã nguồn `openai/codex`.

### Codex

Đã xác nhận (mã nguồn `codex-rs/core/src/agents_md.rs`):

- Codex đọc `AGENTS.md` theo đường đi từ gốc dự án (mặc định: thư mục chứa `.git`)
  xuống thư mục hiện tại, **nối** các file tìm được theo thứ tự đó.
- Trong mỗi thư mục, `AGENTS.override.md` được ưu tiên trước `AGENTS.md`.
- Skill người dùng nằm dưới `$CODEX_HOME/skills/` (thư mục của máy, không theo repo).

Hệ quả cho adapter:

- Sinh `AGENTS.md` ở gốc worktree chỉ được khi repo **chưa** commit file đó —
  nếu đã có, `ad_bi_theo_doi` sẽ bỏ qua. Không dùng `AGENTS.override.md`: nó
  thay chỗ `AGENTS.md` của team trong thư mục đó.
- Cách an toàn hơn: sinh `AGENTS.md` trong thư mục con không ai commit, vd
  `.agent-workflow/AGENTS.md` — Codex chỉ đọc nó khi agent làm việc ở thư mục
  đó, nên cần kiểm lại trước khi chọn.
- Chưa xác nhận: vị trí và định dạng custom prompt (slash command) theo repo.
  Không có thì mỗi phase phải được gọi bằng lời dặn trong `AGENTS.md`.

### Cursor

Chưa xác nhận được định dạng hiện hành (`.cursor/rules/*.mdc` với frontmatter
`description`, `globs`, `alwaysApply` theo hiểu biết cũ). Kiểm lại tài liệu
Cursor trước khi viết adapter; thêm `/.cursor/rules/<tên-riêng>/` vào `exclude`
thay vì cả `/.cursor/` nếu team có commit rule riêng.
