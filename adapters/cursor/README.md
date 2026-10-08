# Adapter Cursor

Biên dịch định nghĩa phase trung lập sang artifact native của Cursor.

```sh
aw adapter build cursor [--out <thư-mục>] [--force]
```

Thường bạn không gọi trực tiếp: khai `ADAPTER="cursor"` (hay `"claude-code cursor"`
cho team dùng cả hai) trong `config.sh`, rồi `aw init` (ở checkout chính) và
`aw worktree new … --create` (ở worktree mới) sẽ gọi nó. Mọi file sinh ra nằm trong
các đường dẫn khai ở file [`exclude`](exclude): `/.cursor/commands/`,
`/.cursor/agents/`, `/.cursor/skills/quy-trinh-agent/`. Adapter **không** exclude cả
`/.cursor/`, vì team hay commit `.cursor/rules/`, `.cursor/hooks.json`, `.cursor/mcp.json`.
File trong `.cursor/` mà git đang theo dõi thì adapter bỏ qua.

Việc sinh nằm trong `adapters/lib/chung.sh` (dùng chung với Claude Code); file
`build.sh` chỉ khai hook riêng của Cursor (xem [../README.md](../README.md#hook-của-adapter)).
Vì vậy hợp đồng phase (Bước 0, cổng duyệt, đọc vào / ghi ra, điều kiện ra, quy tắc
repo, thân phase) **giống hệt** bản Claude Code — `tools/chay-thu.sh` kiểm từng byte.

`--out` trỏ vào repo agent-workflow hoặc thư mục con của nó sẽ bị từ chối (`SAI THAM SỐ`).

## Biên dịch ra gì

| Nguồn trung lập | Artifact Cursor |
|---|---|
| `workflow/phases/<id>.md` | `.cursor/commands/aw-<id>.md` — lệnh `/aw-intake`, `/aw-spec`, `/aw-design`, `/aw-plan`, `/aw-implement`, `/aw-review`, `/aw-ship` |
| `commands:` trong `workflow.yaml` | `.cursor/commands/aw-<id>.md` — `/aw-import`, `/aw-clarify`, `/aw-bootstrap` |
| Phase có `requires_fresh_agent: true` | `.cursor/agents/ra-soat-doc-lap.md` — subagent ngữ cảnh riêng |
| `llm_checker:` của phase | `.cursor/agents/soat-<id>.md` — subagent checker LLM (`soat-thiet-ke`) |
| `workflow.yaml` + tóm tắt luật | `.cursor/skills/quy-trinh-agent/SKILL.md` |

Lệnh của Cursor là markdown thường: dòng đầu `# /<id> — <mô tả>`, không frontmatter.

### Tên trùng với Claude Code — có chủ ý

Cursor nạp cả `.claude/` (chế độ "third-party", bật sẵn; trên CLI không tắt được).
Lệnh, subagent và skill ở đây **trùng tên** với bản Claude Code để bản `.cursor/`
được dùng thay (tài liệu Cursor: subagent trùng tên thì `.cursor/` thắng `.claude/`).
Mỗi file `.claude/` còn có dòng "Dành cho Claude Code — không có tool
`AskUserQuestion` thì dừng, dùng bản `.cursor/`", phòng khi Cursor vẫn nạp nhầm.
Muốn chắc chắn hơn: trên IDE tắt mục nạp cấu hình third-party (Claude Code /
Codex) trong Settings của Cursor.

## Tham số của lệnh: `<tham-số>`

Cursor không thay biến trong file lệnh (không có `$ARGUMENTS`): chữ người gõ sau
`/aw-spec` đi kèm tin nhắn. Mỗi lệnh sinh ra có mục "Tham số của lệnh trong Cursor"
dặn agent: `<tham-số>` là đúng phần chữ đó, chép nguyên văn; không gõ gì thì bỏ hẳn.

Đây là chỗ yếu hơn Claude Code (máy thay, không phải LLM chép), nên **engine chặn**
chữ giữ chỗ còn nguyên: `aw feature '<tham-số>'` → `TÊN KHÔNG HỢP LỆ`,
`aw input` với `<tham-số>` → `SAI CÁCH GỌI`. Agent quên thay thì bị chặn, không tạo
thư mục việc tên `<tham-số>` hay mục `[HUMAN]` rác.

## Cái gì KHÔNG biên dịch portable được — Cursor xử lý thế nào

### 1. Ngữ cảnh sạch cho phase rà soát

`/aw-review` bắt buộc chạy qua subagent `ra-soat-doc-lap` (`.cursor/agents/`). Bản Cursor
chưa có subagent (trước 2.4) thì không tự động hoá được: **người tự mở chat mới**,
gõ `/aw-review` ở đó — không rà soát bằng chính chat vừa viết code.

### 2. Hook gác ô duyệt

Xem [mục dưới](#hook-gác-ô-duyệt). Adapter không tự ghi `.cursor/hooks.json`.

### 3. Truy cập MCP

Cursor có MCP (`.cursor/mcp.json` hoặc cấu hình của máy). Chưa cấu hình MCP
Atlassian thì đầu vào lùi về `file` — nhãn `[FILE]` kèm đường dẫn.

### 4. Cách gọi

Lệnh `/…` trong `.cursor/commands/`. Skill `quy-trinh-agent` được Cursor nạp khi liên quan.

### 5. Checker LLM

`/aw-design` bảo agent gọi subagent `soat-thiet-ke` sau khi viết `tdd.md`.
`aw check design` fail nếu chưa có `phat-hien-thiet-ke.md` — quên gọi cũng không lọt.

### 6. Câu hỏi lựa chọn (`/aw-clarify`)

Có tool hỏi lựa chọn của Cursor (vd `AskQuestion`, tuỳ bản và IDE/CLI) thì dùng;
không có thì in lựa chọn đánh số. Lời dặn **luôn** có lối tự nhập và "Chat về câu
này" — không chắc tool của Cursor tự thêm như `AskUserQuestion` của Claude Code.

### 7. Hộp xác nhận của cổng duyệt

Cùng câu hỏi, cùng ba nhãn, cùng thứ tự với Claude Code (test so giữa hai adapter).
Cursor không có `preview` khi rê chuột: phần "Cách duyệt" (file, dòng phải tick) nằm
nguyên trong khối text agent in ngay trước câu hỏi.

### Model

Cursor chạy nhiều model; chế độ Auto có thể đổi model giữa các phase. Cổng máy
(`aw check`) không đổi theo model, nhưng chất lượng spec, thiết kế và phát hiện của
checker LLM thì có. Nên chọn cố định một model cho phiên chạy phase, nhất là `/aw-design`
(subagent `soat-thiet-ke`) và `/aw-review`.

## Hook gác ô duyệt

Như Claude Code (xem [../claude-code/README.md](../claude-code/README.md#hook-gác-ô-duyệt)):
`aw guard pre` trước mỗi lệnh của agent, `aw guard post` sau lệnh đó. Thêm vào
`.cursor/hooks.json` của repo đích (hay của máy):

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [{ "command": "aw guard pre" }],
    "postToolUse": [{ "command": "aw guard post" }]
  }
}
```

- `pre` và `post` **phải cùng loại sự kiện** (`preToolUse` / `postToolUse`, cùng
  matcher nếu có). Đừng chỉ dùng `afterFileEdit`: không có `pre` thì `post` không
  phân biệt được tick của người với tick của agent, nên không chặn gì.
- Không matcher = mọi tool (kể cả Shell: `sed -i` cũng bị bắt, vì hook so trạng thái
  file chứ không đọc lệnh). Hook chỉ quét `spec.md` / `tdd.md` của worktree nên nhẹ.
- **Bỏ tick là việc của hook, không phụ thuộc Cursor:** `post` sửa thẳng file. Phần
  *báo agent* (mã 2 + stderr) thì tuỳ Cursor có đưa stderr của `postToolUse` lại cho
  agent hay không — chưa kiểm trên Cursor thật. Không được báo thì agent có thể tick
  lại ở lệnh sau; hook lại bỏ tick, và `aw check` vẫn chặn vì thiếu dấu duyệt hợp lệ.
- Cursor cũng chạy hook của `.claude/settings.json` (chế độ tương thích). Team có cả
  hai file thì một lệnh có thể chạy `aw guard` hai lần — **vô hại**, có test
  (`pre pre · lệnh · post post`).
- Hook chạy `aw` từ thư mục repo; `aw` phải có trong `PATH` của Cursor.

## Đã kiểm / chưa kiểm

Định dạng theo tài liệu Cursor (2026-10): lệnh `.cursor/commands/*.md`, subagent
`.cursor/agents/*.md` (frontmatter `name`, `description`), skill
`.cursor/skills/<tên>/SKILL.md`, hook `.cursor/hooks.json`, nạp `.claude/` để tương
thích, subagent trùng tên thì `.cursor/` thắng.

Chưa kiểm trên một phiên Cursor thật — kiểm khi có dịp và ghi lại ở đây:

- Lệnh và skill trùng tên giữa `.cursor/` và `.claude/`: bản nào được dùng.
- Tên và cách dùng tool hỏi lựa chọn của Cursor ở IDE và CLI.
- `postToolUse` trả mã 2: stderr có tới agent không.

## Kết quả

Như Claude Code: khối `Kết quả` cuối output — `ĐÃ SINH`, `SAI THAM SỐ`,
`CÓ FILE VIẾT TAY`, `ĐỊNH NGHĨA QUY TRÌNH LỖI` (spec nguồn sai, hoặc adapter thiếu hook).
