# Adapter Claude Code

Biên dịch định nghĩa phase trung lập sang artifact native của Claude Code.

```sh
sh adapters/claude-code/build.sh --out /đường/dẫn/repo-đích [--force]
```

Thường bạn không gọi trực tiếp — `tools/cai-dat.sh` gọi nó sau khi đã chép bộ
luật/mẫu/công cụ vào repo đích.

## Biên dịch ra gì

| Nguồn trung lập | Artifact Claude Code |
|---|---|
| `workflow/phases/<id>.md` | `.claude/commands/<id>.md` — slash command (`/ideation`, `/spec`, `/design`, `/plan`, `/implement`, `/review`) |
| `05-review.md` + cờ `requires_fresh_agent` | `.claude/agents/ra-soat-doc-lap.md` — subagent |
| `workflow.yaml` + tóm tắt luật | `.claude/skills/quy-trinh-agent/SKILL.md` |

Phase có `status: chưa hiện thực` bị bỏ qua (hiện tại: `06-ship`).

Mỗi command sinh ra đều bắt đầu bằng bước **xác định feature**: suy từ tên branch
theo `conventions.md` → không khớp thì lấy tham số lệnh (vd `/spec feat_tao-todo`)
→ không có thì dừng hỏi. Command in `Đang làm với: …` rồi mới đọc/ghi trong
`.agent-workflow/<tên-branch>/`.

Mỗi command sinh ra gồm hai phần: **hợp đồng phase** (đọc gì, ghi ra đâu, mẫu
nào, điều kiện ra là lệnh gì) do adapter dựng từ frontmatter, và **mô tả phase**
lấy nguyên văn từ thân file nguồn.

## Cái gì KHÔNG biên dịch portable được

Đây là phần quan trọng nhất của tài liệu này. Năm thứ dưới đây là đặc thù agent,
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

Những gì **luôn** portable: file artifact trong `.agent-workflow/<tên-branch>/`,
`conventions.md`, các mẫu, và các script kiểm tra. Đó là lý do phần lõi của quy trình nằm ở đó chứ không nằm
trong prompt.

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
            "command": "sh -c 'for f in $CLAUDE_FILE_PATHS; do case \"$f\" in *.agent-workflow/*/spec.md) sh .agent-workflow/.quy-trinh/tools/kiem-tra-truy-vet.sh \"$(dirname \"$f\")\" >&2 ;; esac; done' || true"
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

## Mã thoát

| Mã | Nghĩa |
|---|---|
| 0 | Thành công |
| 2 | Sai tham số |
| 3 | Đích đã có file người viết tay — dùng `--force` để ghi đè |
| 4 | Spec nguồn sai: `exit_machine` không phải lệnh chạy được, hoặc trỏ tới script không tồn tại |

Mã 4 là chốt chặn quan trọng: nó giữ cho "điều kiện ra loại MÁY" luôn là lệnh
thật. Không có nó, một dòng mô tả bằng chữ sẽ lọt vào mục đó và agent sẽ tự đánh
giá là đã đạt.

## Viết adapter mới

1. Tạo `adapters/<id>/build.sh`, nhận `--out <thư-mục>`.
2. `. "$ROOT/tools/lib/md.sh"` rồi dùng `wf_phases`, `fm_scalar`, `fm_list`, `md_body`.
3. Đọc `workflow.yaml` lấy `artifact_dir`; giữ nguyên đường dẫn artifact
   `<artifact_dir>/<tên-branch>/` và thứ tự xác định feature (branch →
   tham số → hỏi) — đây là giao diện chung giữa các adapter.
4. Với mỗi khả năng không dịch được (ngữ cảnh sạch, hook, MCP, cách gọi, checker
   LLM), **ghi rõ trong output** thay vì bỏ qua.
5. Thêm mục vào `adapters:` trong `workflow.yaml`, đổi `status` thành `active`.
