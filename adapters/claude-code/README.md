# Adapter Claude Code

Biên dịch định nghĩa phase trung lập sang artifact native của Claude Code.

```sh
aw adapter build claude-code [--out <thư-mục>] [--force]
```

Thường bạn không gọi trực tiếp — `aw init` (ở checkout chính) và
`aw worktree new … --create` (ở worktree mới) gọi nó. Mọi file sinh ra nằm trong
`.claude/`, đường dẫn khai ở file [`exclude`](exclude); `aw init` thêm nó vào
`.git/info/exclude` nên không lọt vào commit. File `.claude/` mà git đang theo dõi
(vd bộ cài cũ còn trong base, hay `settings.json` của team) thì adapter bỏ qua.

Lời dặn trong lệnh sinh ra chỉ gọi `aw …` — luật nằm trong checker của engine.
Phần dùng chung với adapter khác ở `adapters/lib/chung.sh` (xem
[../README.md](../README.md)).

`--out` trỏ vào repo agent-workflow hoặc thư mục con của nó sẽ bị từ chối (`SAI THAM SỐ`).

## Biên dịch ra gì

| Nguồn trung lập | Artifact Claude Code |
|---|---|
| `workflow/phases/<id>.md` | `.claude/commands/<id>.md` — slash command (`/intake`, `/spec`, `/design`, `/plan`, `/implement`, `/review`) |
| Phase có `requires_fresh_agent: true` (`05-review.md`) | `.claude/agents/ra-soat-doc-lap.md` — subagent ngữ cảnh sạch |
| `llm_checker:` của phase → `workflow/checkers/<id>.md` | `.claude/agents/soat-<id>.md` — subagent checker LLM (hiện có `soat-thiet-ke`) |
| `commands:` trong `workflow.yaml` → `workflow/<id>.md` | `.claude/commands/<id>.md` — lệnh tiện ích `/import`, `/open-questions` |
| `workflow.yaml` + tóm tắt luật | `.claude/skills/quy-trinh-agent/SKILL.md` |

Phase có `status: chưa hiện thực` bị bỏ qua (hiện tại: `06-ship`).

Mỗi command sinh ra gồm ba phần:

1. **Bước 0 — xác định feature:** chạy
   `aw feature $ARGUMENTS`. Engine suy
   từ tên branch theo `conventions.md` → không khớp thì lấy tham số lệnh (vd
   `/spec feat_tao-todo`) → không có thì ra `CẦN HỎI NGƯỜI` và command bảo agent dừng hỏi.
   Đang ở checkout chính thì ra `ĐANG Ở CHECKOUT CHÍNH`: worktree là bắt buộc, command bảo agent dừng
   và nhờ người mở phiên mới trong worktree của việc.
   Agent in `Đang làm với: …` rồi mới đọc/ghi trong `.agent-workflow/<tên-branch>/`.
   Logic nằm trong script chứ không trong prompt, để mọi adapter dùng chung.

   Ngoại lệ: phase khai `arguments: input` (hiện chỉ `00-intake`). Khi đó tham số
   lệnh là **input** (`/intake JIRA-123 …`), adapter **không** truyền nó vào
   `aw feature`, và `ĐANG Ở CHECKOUT CHÍNH` dẫn tới bước đề xuất
   worktree bằng `aw worktree new` — người chọn base rồi mới tạo. Adapter từ chối build (`ĐỊNH NGHĨA QUY TRÌNH LỖI`) nếu `arguments` mang giá
   trị khác `input`.
2. **Hợp đồng phase** (đọc gì, ghi ra đâu, mẫu nào, checker LLM nào, điều kiện
   ra là lệnh gì) do adapter dựng từ frontmatter.
3. **Mô tả phase** lấy nguyên văn từ thân file nguồn.

Lệnh tiện ích (`commands:` — không phải phase) chỉ có Bước 0 và thân file nguồn,
không có hợp đồng vào/ra. Frontmatter: `name`, `summary`, tuỳ chọn
`argument_hint` (mặc định `[tên-feature]`) và `arguments: mixed` khi tham số còn
thứ khác ngoài tên feature (như `/import <file> <artifact> [tên-feature]`).

## Loại việc không cần gì từ adapter

Luật theo loại việc (`feature | bugfix | refactor | perf | chore`, ghi trong
`intake.md` ở `/intake`) nằm **hoàn toàn** trong thân file phase và trong các
script kiểm tra — adapter không sinh nhánh nào theo loại. `/design` với `chore`
vẫn được sinh ra; chính `aw check design` chặn khi chạy design cho chore.
Adapter mới vì thế không phải biết gì về loại việc.

## Cái gì KHÔNG biên dịch portable được

Đây là phần quan trọng nhất của tài liệu này. Sáu thứ dưới đây là đặc thù agent,
và adapter tương lai cho Cursor/Copilot sẽ phải tự xử lý — hoặc **nói rõ là
không làm được** chứ không im lặng bỏ qua.

### 1. Ngữ cảnh sạch cho phase rà soát

`05-review` khai `requires_fresh_agent: true`. Ràng buộc thật là: *không được rà
soát bằng chính phiên vừa viết code* — agent vừa viết sẽ rà soát chính lập luận
của nó.

| Khả năng agent | Cách thoả |
|---|---|
| Có subagent (Claude Code) | Sinh subagent riêng, ngữ cảnh trắng |
| Không có subagent | Không tự động hoá được → adapter **phải** ghi vào hướng dẫn rằng người dùng tự mở phiên mới |

Bỏ qua âm thầm sẽ làm phase rà soát mất gần hết giá trị mà nhìn vẫn như đang chạy.

### 2. Hook

Claude Code có hook; phần lớn agent khác không. Adapter này **cố tình không ghi**
`.claude/settings.json` — xem mục dưới.

### 3. Truy cập MCP

`01-spec` đọc Confluence/Jira qua MCP Atlassian. Agent không có MCP thì đầu vào
phải lùi về `file` (tự tải tài liệu về repo) — nhãn truy vết khi đó là `[FILE]`
kèm đường dẫn, thay vì `[CONFLUENCE]` kèm URL.

### 4. Cách gọi

Slash command là quy ước của Claude Code. Cursor dùng rules, Copilot dùng
`copilot-instructions.md`. Nội dung chuyển được; *cách kích hoạt* thì không.

### 5. Checker LLM

`02-design` (và những chỗ khác dùng checker LLM) cần một lượt gọi LLM để tìm lệch
D-xx và quyết định ngầm. *Cách gọi* lượt đó là đặc thù agent. Phần portable là
**hợp đồng**: checker ghi phát hiện ra file, và một script fail nếu còn mục
`Chặn` chưa xử lý. Adapter nào không tự gọi được checker thì phải ghi rõ người
dùng tự chạy — không được coi "không có file phát hiện" là đạt.

Adapter này dịch nó thành subagent `soat-thiet-ke` (thân lấy từ
`workflow/checkers/thiet-ke.md`); command `/design` bảo agent gọi subagent đó sau
khi viết xong `tdd.md`. `aw check design` fail nếu chưa có
`phat-hien-thiet-ke.md` — nên quên gọi subagent cũng không lọt.

### 6. Câu hỏi lựa chọn

Lệnh khai `choice_ui: true` (hiện có `open-questions`) mô tả việc hỏi người bằng
**câu hỏi lựa chọn** — luôn kèm ô tự nhập và lựa chọn "Chat về câu này". Adapter
này dịch nó sang tool `AskUserQuestion` (ô "Other" của tool là ô tự nhập).
Agent không có giao diện lựa chọn thì in lựa chọn đánh số kèm "hoặc gõ câu trả
lời khác" — mô tả trung lập đã nói cách lùi này.

Những gì **luôn** portable: file artifact trong `.agent-workflow/<tên-branch>/`,
`conventions.md`, các mẫu (chép vào `.agent-workflow/.engine/`), và lệnh `aw check`. Đó là lý do phần lõi của quy trình nằm ở đó chứ không nằm
trong prompt.

## Dọn file cũ khi sinh lại

Sau khi sinh xong, adapter xoá mọi file trong `.claude/commands/` và
`.claude/agents/` **mang dấu "SINH TỰ ĐỘNG"** mà lần build này không sinh ra — tức
lệnh của phase đã đổi tên hoặc bị bỏ. Không dọn thì repo đích vẫn còn lệnh cũ
(vd `/ideation` sau khi đổi thành `/intake`) chạy theo luật cũ. File không có dấu
đó là do người viết, adapter không đụng tới.

## Hook — vì sao adapter không tự ghi settings.json

Ghi đè `.claude/settings.json` của repo đích là thao tác **không đảo ngược được**
và file đó thường đã có nội dung của người khác. Adapter không đụng vào.

Nếu bạn muốn chặn cứng bằng hook, tự thêm đoạn này vào `.claude/settings.json`
của repo đích. Nó nhắc khi một artifact vừa bị sửa mà cổng chặn chưa chạy:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "sh -c 'for f in $CLAUDE_FILE_PATHS; do case \"$f\" in *.agent-workflow/*/spec.md) aw check spec \"$(dirname \"$f\")\" >&2 ;; esac; done' || true"
          }
        ]
      }
    ]
  }
}
```

Cân nhắc trước khi dùng: hook chạy **mỗi lần** sửa file, kể cả lúc agent mới viết
được nửa `spec.md` — khi đó nó sẽ báo lỗi hàng loạt và gây nhiễu. Quy trình này
mặc định đặt cổng chặn ở **cuối phase** (agent tự chạy lệnh trước khi tuyên bố
xong) thay vì ở mỗi lần ghi file. Chỉ thêm hook nếu bạn thấy agent hay bỏ qua
bước chạy lệnh.

## Kết quả

Cuối output có khối `Kết quả`, đánh `[x]` vào đúng một nhãn:

| Nhãn | Nghĩa |
|---|---|
| `ĐÃ SINH` | Thành công |
| `SAI THAM SỐ` | Sai tham số |
| `CÓ FILE VIẾT TAY` | Đích đã có file người viết tay — dùng `--force` để ghi đè |
| `ĐỊNH NGHĨA QUY TRÌNH LỖI` | Spec nguồn sai: `exit_machine` không phải `aw check <tên>` / tên không có trong bảng checker của engine, hoặc `llm_checker` / mục `commands:` trỏ tới file không tồn tại, hoặc `arguments` sai giá trị |

`ĐỊNH NGHĨA QUY TRÌNH LỖI` là chốt chặn quan trọng: nó giữ cho "điều kiện ra loại MÁY" luôn là lệnh
thật. Không có nó, một dòng mô tả bằng chữ sẽ lọt vào mục đó và agent sẽ tự đánh
giá là đã đạt.

## Viết adapter mới

1. Tạo `adapters/<id>/build.sh`, nhận `--out <thư-mục>`; từ chối `--out` nằm
   trong repo agent-workflow (`SAI THAM SỐ`), như adapter Claude Code.
2. Tạo `adapters/<id>/exclude` liệt kê đường dẫn adapter sinh ra (vd `/.cursor/rules/agent-workflow/`)
   — `aw init` thêm vào `.git/info/exclude`.
3. Nạp `tools/lib/md.sh`, `tools/lib/ket-qua.sh`, `tools/lib/bang-lenh.sh`, rồi
   `adapters/lib/chung.sh` (đặt `ROOT`, `OUT`, `FORCE`, `DA_SINH` trước). Dùng
   `kiem_tra_nguon`, `ghi_file`, `kiem_tra_ghi_de`, `buoc_xac_dinh_feature`,
   `buoc_phan_loai_input`, `doc_truoc`, `don_file_cu` — đừng viết lại.
4. Lời dặn agent chỉ gọi `aw …` (`aw feature`, `aw check <tên>`, `aw input`…) và
   đọc mẫu/luật trong `.agent-workflow/.engine/`. Không nhúng luật vào prompt.
5. Với mỗi khả năng không dịch được (ngữ cảnh sạch, hook, MCP, cách gọi, checker
   LLM, câu hỏi lựa chọn), **ghi rõ trong output** thay vì bỏ qua.
6. Thêm mục vào `adapters:` trong `workflow.yaml`, đổi `status` thành `active`.
