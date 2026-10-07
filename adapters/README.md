# Adapter

Adapter là lớp **mỏng** sinh ra từ `workflow/`. Nó chỉ dịch định nghĩa phase sang
dạng native của một agent và dặn agent gọi `aw …`. Luật cứng nằm trong checker
của engine: mã thoát và nhãn `Kết quả` của `aw check <tên>`. Không luật nào dựa
vào tính năng riêng của agent.

## Hợp đồng của một adapter

Thư mục `adapters/<id>/` gồm:

| File | Vai trò |
|---|---|
| `build.sh` | `sh build.sh --out <thư-mục> [--force]` — khai `AD_ID`, `AD_TEN`, `AD_GOC`, các hook, rồi gọi `ad_sinh` |
| `exclude` | Đường dẫn adapter sinh ra, mỗi dòng một mẫu (`/.claude/`). `aw init` thêm vào `.git/info/exclude` |
| `README.md` | Biên dịch ra gì, cái gì không portable |

**Toàn bộ việc sinh nằm trong `adapters/lib/chung.sh` (`ad_sinh`)**: lệnh cho từng
phase (Bước 0 xác định feature, phân loại input, cổng duyệt, hợp đồng phase, quy
tắc repo, thân phase), lệnh tiện ích, subagent rà soát, subagent checker LLM,
skill tổng; kiểm `exit_machine` là `aw check <tên>` có thật; không ghi đè file
người viết tay; bỏ qua file git đang theo dõi; dọn file sinh tự động đã cũ (chỉ
trong thư mục của adapter đó). Adapter **không** tự viết phần nào trong đó.

### Hook của adapter

Chữ riêng của một agent chỉ được nằm trong hook:

| Hook | Việc | Claude Code | Cursor |
|---|---|---|---|
| `ad_tham_so` | Cách viết tham số của lệnh trong lời dặn | `$ARGUMENTS` (agent thay) | `<tham-số>` (agent chép nguyên văn) |
| `ad_dau_lenh <id> <mô-tả> <gợi-ý>` | Đầu file lệnh | frontmatter `description`, `argument-hint` | `# /<id> — <mô-tả>` |
| `ad_mo_dau_lenh <id> <gợi-ý> <arguments>` | Khối ngay sau cảnh báo | (rỗng) | Cách lấy `<tham-số>` |
| `ad_hoi_lua_chon` | Lệnh khai `choice_ui: true` | `AskUserQuestion` | Tool hỏi lựa chọn nếu có, không thì đánh số |
| `ad_hoi_cong_duyet <phase>` | Hộp xác nhận của cổng duyệt | `AskUserQuestion` + `preview` | Tool hoặc đánh số, không preview |
| `ad_danh_cho` | Một dòng: file dành cho agent nào | "Dành cho Claude Code… không có `AskUserQuestion` → dừng" | "Dành cho Cursor…" |
| `ad_dau_agent`, `ad_dau_skill` | Frontmatter subagent, skill (có mặc định) | `name`, `description` | `name`, `description` |

Thiếu hook bắt buộc → build từ chối (`ĐỊNH NGHĨA QUY TRÌNH LỖI`), không sinh gì.

**Test đối chiếu** (`tools/chay-thu.sh`, mục "đối chiếu mọi adapter"): build MỌI
adapter trong `adapters/*/` với `AW_DOI_CHIEU=1` — hook in tên của nó thay cho nội
dung — và đòi output giống hệt nhau từng byte. Adapter mới tự động vào phép đối
chiếu. Câu hỏi và ba nhãn của cổng duyệt cũng được so giữa các adapter.

`aw adapter build [<id>[,<id>…]]` (cũng chạy trong `aw init` và
`aw worktree new --create`; bỏ trống id = mọi adapter trong `ADAPTER`) làm hai bước:

1. Chép `workflow/{rules,templates,checkers}` của engine vào
   `.agent-workflow/.engine/` (bị exclude); `conventions.md` ở đó là liên kết
   tới cấu hình của bản clone. Bước này dùng chung, agent nào cũng đọc được.
2. Chạy `adapters/<id>/build.sh --out <worktree>` cho từng adapter, ghi dòng
   `<id> <version>` vào `.agent-workflow/.adapters` khi đạt (`aw doctor` đọc).
   Một adapter hỏng không chặn adapter khác.

Mọi file sinh ra nằm trong đường dẫn đã exclude — không lọt vào commit, không
cần sửa base.

## Adapter đang có

| id | Trạng thái |
|---|---|
| `claude-code` | Có — xem [claude-code/README.md](claude-code/README.md) |
| `codex` | Chưa viết — ghi chú bên dưới |
| `cursor` | Có — xem [cursor/README.md](cursor/README.md) |

## Ghi chú cho adapter sau này

Chỉ ghi điều đã kiểm được. Phần Codex dưới đây đọc từ mã nguồn `openai/codex`.

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

## Nhiều adapter trong một bản clone

`ADAPTER` trong `config.sh` là một hoặc nhiều id (cách nhau dấu cách hoặc dấu
phẩy): `ADAPTER="claude-code cursor"`. `aw init` exclude đường dẫn của mọi adapter,
`aw worktree new --create` và `aw adapter build` sinh mọi adapter.

Để hai bộ ít ảnh hưởng nhau nhất:

- **Mỗi adapter chỉ ghi vào thư mục gốc của nó** (`AD_GOC`), dọn file cũ cũng chỉ
  trong đó. Test: build hai adapter vào cùng thư mục cho ra đúng như build riêng.
- **Tên trùng nhau** giữa các adapter (lệnh, subagent, skill) — agent nạp thư mục
  của agent khác (Cursor nạp `.claude/`) sẽ ưu tiên bản của chính nó.
- **`ad_danh_cho`**: file nào cũng nói nó dành cho agent nào, agent khác nạp nhầm thì dừng.
- **Engine chặn chữ giữ chỗ chưa thay** (`$ARGUMENTS`, `<tham-số>`) ở `aw feature`
  và `aw input`: agent quên thay tham số thì bị chặn, không thành thư mục việc hay
  mục `[HUMAN]` rác.
- **`aw guard` chạy hai lần là vô hại** (Cursor có thể chạy cả hook của
  `.claude/settings.json` lẫn `.cursor/hooks.json`) — có test.
- **Mỗi worktree chỉ một agent chạy tại một lúc**: mốc của hook gác ô duyệt
  (`.agent-workflow/.gac-duyet-pre`) là một file chung trong worktree.

## Viết adapter mới

1. Tạo `adapters/<id>/build.sh`: đặt `ROOT`, `AD_ID`, `AD_TEN`, `AD_GOC` (thư mục
   gốc của agent, vd `.cursor`), source `adapters/lib/chung.sh`, định nghĩa các hook
   (bảng trên), rồi `ad_sinh "$@"`. Xem `adapters/cursor/build.sh` — chỉ có hook.
2. Tạo `adapters/<id>/exclude` liệt kê đường dẫn adapter sinh ra. Chỉ exclude thư
   mục adapter thật sự ghi vào, không cả thư mục gốc của agent nếu team hay commit
   file khác trong đó (Cursor: `.cursor/rules/`, `hooks.json`).
3. Lời dặn agent chỉ gọi `aw …` và đọc mẫu/luật trong `.agent-workflow/.engine/`.
   Không nhúng luật vào hook.
4. Với mỗi khả năng không dịch được (ngữ cảnh sạch, hook, MCP, cách gọi, checker
   LLM, câu hỏi lựa chọn, hộp xác nhận của cổng duyệt), **ghi rõ trong output và
   README** thay vì bỏ qua.
5. Thêm mục vào `adapters:` trong `workflow.yaml`, đổi `status` thành `active`.
6. Chạy `sh tools/chay-thu.sh`: phép đối chiếu tự lấy adapter mới; thêm test riêng
   cho chữ trong hook của nó (như mục `adapters/cursor/build.sh`).
