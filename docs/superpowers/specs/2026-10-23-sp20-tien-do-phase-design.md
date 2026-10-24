# Spec: SP20 — File tiến độ của việc (phase, thời gian tương tác, token)

- Ngày: 2026-10-23 · Branch: `claude/modest-hypatia-h7npnz`
- Roadmap § SP20. Interface: không đổi — đây là đo đạc của harness (cùng lớp với `aw journal`), không
  phải năng lực của một stage SDLC; không thêm luật chặn/cảnh báo nào.

## Vấn đề

Người làm một việc không có chỗ nào nhìn một lần mà biết: việc đang ở phase nào, mỗi phase tốn bao
nhiêu thời gian người–agent thật sự làm việc, tốn bao nhiêu token. Hiện có:

- `aw ready <dir>` § Tiến độ — artifact nào có, bước tiếp. Chỉ in ra terminal, không có số liệu.
- `journal/checks.tsv` — giờ và mã thoát mỗi lần `aw check`. Có mốc **kết thúc** phase (ĐẠT đầu tiên),
  không có mốc **bắt đầu**, không có thời gian tương tác, không có token.

SP9 cần đúng số liệu này ("thời gian phase") mà công cụ chưa ghi.

## Đã chốt với người (trước spec)

1. File là **Markdown + Mermaid** (`progress.md`): bảng + Gantt + biểu đồ tròn token. HTML không làm:
   không hiển thị trong giao diện git, diff ồn, khó sinh bằng sh/awk.
2. File nằm **trong thư mục việc** (`docs/sdlc/<branch>/progress.md`) và được commit cùng artifact.
3. **Token chỉ đo trên Claude Code** (đọc transcript qua hook). Cursor: chỉ thời gian theo đồng hồ;
   cột token ghi `—`.
4. **Reviewer thấy bảng trong mô tả MR** (lựa chọn B): `aw ship create` tự chèn mục `## Progress` (bảng,
   không Mermaid) vào cuối mô tả gửi đi — § 7. Làm trong SP20.
5. **Nhắc khi chưa ghi được lượt nào** (lựa chọn Y): suy từ dữ liệu, ngay trong `progress.md` /
   `aw status` — § 5. Không kiểm file settings ở `aw ready` (hook có thể nằm ở `settings.local.json`
   hay `~/.claude/settings.json`, kiểm file báo sai).

## Phạm vi

Làm:

- Ghi mốc bắt đầu phase; ghi lượt (thời gian + token) từ hook Claude Code.
- `aw status <dir>` in tóm tắt, `--write` sinh `progress.md`; `aw check <phase>` ĐẠT tự sinh lại file
  trước khi commit artifact.
- `aw journal export` / `report` mang thêm hai nguồn mới (để SP9 gộp nhiều máy).
- `aw ship create` chèn bảng tiến độ vào mô tả MR.
- Dòng nhắc cài hook khi có phase đã chạy mà không có lượt nào.

Không làm:

- Chi phí bằng tiền (giá đổi theo model và thời điểm; người tự nhân).
- Chi tiết từng lượt trong `progress.md` (vài chục lượt làm biểu đồ rối) — chi tiết ở `turns.tsv`.
- Mermaid trong mô tả MR (biểu đồ có ích cho người làm, ít cho reviewer; mô tả dài).
- Cập nhật lại mục `## Progress` khi MR đã mở (đường "MR đang mở — đã push" không gửi lại mô tả).
- `aw ready` kiểm hook đã cài.
- Luật chặn/cảnh báo dựa trên số liệu (vd phase quá lâu). Chờ số liệu SP9.

## Thiết kế

### 1. Dữ liệu — hai nguồn mới ở `$AW_CONFIG/journal/` (không commit, `AW_JOURNAL=0` tắt)

`phases.tsv` — một dòng mỗi lần một phase bắt đầu:

| cột | ví dụ |
|---|---|
| `ts` (UTC ISO, như `checks.tsv`) | `2026-10-23T07:10:00Z` |
| `worktree` (git top) | `/home/u/repo-wt/feat-otp` |
| `feature` (`viec`, như `checks.tsv`) | `feat_login-otp` |
| `phase` | `spec` |

`turns.tsv` — một dòng mỗi lượt (người gửi prompt → agent dừng), hoặc mỗi subagent kết thúc:

| cột | ghi chú |
|---|---|
| `ts_begin`, `ts_end` | UTC ISO; subagent: `ts_begin` = `-` |
| `worktree`, `feature`, `phase` | gắn theo § 3; không gắn được → `-` |
| `session` | `session_id` của payload hook |
| `kind` | `main` \| `subagent` |
| `seconds` | `ts_end − ts_begin`; subagent `0` (thời gian đã nằm trong lượt main) |
| `in`, `out`, `cache_read`, `cache_write` | tổng `usage` của các message assistant trong lượt; không đọc được → rỗng |

Chỉ ghi **số**, không chép nội dung transcript.

### 2. Mốc bắt đầu phase

- Bước 0 của mọi lệnh phase do `ad_sinh` sinh (`buoc_xac_dinh_feature`, `adapters/lib/common.sh`) gọi
  `aw feature … --phase <id>` thay cho `aw feature …`. Một lệnh, không thêm bước agent có thể quên;
  chữ chung cho mọi adapter nên test `AW_COMPARE=1` vẫn giữ.
- `tools/feature.sh`: `--phase <id>` (id phải có trong `phases:` của `workflow.yaml`, sai → `TÊN KHÔNG
  HỢP LỆ`). Khi kết quả là `ĐÃ XÁC ĐỊNH` thì ghi một dòng `phases.tsv`; mã khác không ghi. Lỗi ghi im
  lặng (như `journal.sh _check`). Không có `--phase` → hành vi như cũ (`aw feature` còn được gọi ngoài
  lệnh phase).
- Mỗi lần chạy lệnh phase là một dòng. Một phase chạy nhiều phiên (mở lại sau khi nghỉ, làm lại sau
  review) → nhiều dòng; § 4 gộp.

### 3. Lượt và token — hook Claude Code

Ba hook, người tự thêm vào `.claude/settings.json` cạnh `aw guard` (adapter không ghi settings của repo
đích — `adapters/claude-code/README.md` § Hook):

| sự kiện | lệnh |
|---|---|
| `UserPromptSubmit` | `aw journal _turn begin` |
| `Stop` | `aw journal _turn end` |
| `SubagentStop` | `aw journal _turn sub` |

`journal.sh _turn`:

- Đọc payload JSON từ stdin bằng `sed` (không jq): `session_id`, `transcript_path`, `cwd`,
  `agent_transcript_path` (subagent). Thiếu trường cần → thoát 0, không ghi.
- **Không in gì ra stdout, luôn thoát 0**: stdout của `UserPromptSubmit` bị chèn vào ngữ cảnh agent;
  mã khác 0 làm hỏng lượt. Mọi lỗi im lặng.
- `begin`: ghi `ts` vào `journal/.turn/<session>`.
- `end`: đọc transcript **từ vị trí đã đọc lần trước** (byte offset lưu cùng file `.turn/<session>`,
  `tail -c +N`) tới cuối; awk cộng `input_tokens`, `output_tokens`, `cache_read_input_tokens`,
  `cache_creation_input_tokens` của dòng `"type":"assistant"`, **khử trùng theo `message.id`** (một
  message có thể xuất hiện nhiều dòng với cùng `usage`). Ghi dòng `turns.tsv`, cập nhật offset.
  Thiếu `begin` (hook cài giữa lượt) → `seconds` rỗng, token vẫn ghi.
- `sub`: như `end` trên `agent_transcript_path`, đọc cả file, `kind=subagent`. Token của subagent
  (vd review) nằm ở transcript riêng, không có trong transcript chính.
- Gắn phase: `worktree` = git top của `cwd`; phase = dòng `phases.tsv` mới nhất của worktree đó có
  `ts` ≤ `ts_end`. Không có → `-`.
- Thời gian chạy hook phải nhỏ: chỉ đọc phần transcript mới, không quét lại cả file.
- Định dạng transcript không phải API công khai: trường thiếu → token rỗng, không vỡ. Test dùng
  transcript mẫu (fixture); đổi định dạng thì sửa awk + fixture.
- Cursor chạy cả hook của `.claude/settings.json` nhưng payload khác: không có `transcript_path` →
  không ghi (không ghi dòng rác).

### 4. Tính số liệu một phase

Với mỗi phase của việc, theo thứ tự `phases:` trong `workflow.yaml`:

- **Lần chạy** = các khoảng từ một dòng `phases.tsv` tới dòng `phases.tsv` kế tiếp của cùng việc (feature)
  (bất kể phase nào; sắp theo từng việc, không theo worktree), hoặc tới bây giờ.
- **Đồng hồ** = tổng độ dài các lần chạy của phase đó; lần chạy cuối của việc đang mở thì tính tới
  sự kiện cuối cùng (không tới "bây giờ", để sinh lại file không đổi số khi không có gì mới — § 5).
- **Tương tác** = tổng `seconds` các lượt `main` gắn phase đó.
- **Lượt** = số lượt `main`; **token** = tổng 4 cột, cả `main` lẫn `subagent`.
- **Check chặn** = số dòng `checks.tsv` của checker phase đó, mã khác 0, trong các lần chạy của nó.
- **Status** (giá trị enum tiếng Anh vì là artifact — `AGENTS.md` § Language):
  - `✓ done` — có dòng `checks.tsv` mã 0 sau lần bắt đầu cuối;
  - `▶ active` — phase của dòng `phases.tsv` mới nhất và chưa ĐẠT sau đó;
  - `— skipped` — design khi `kc_bo_design` (`tools/lib/cross-check.sh`) đúng;
  - `· pending` — còn lại.
  Việc bắt đầu trước SP20 (có check, không có mốc bắt đầu): phase có ĐẠT vẫn hiện `✓ done`, ô thời
  gian `—`. Output terminal của `aw status` dùng nhãn tiếng Việt (`ĐẠT`, `đang làm`, `bỏ qua`, `chưa`).

### 5. `progress.md`

`tools/status.sh` (đăng ký trong `bin/aw-engine` — `commands.sh` chỉ giữ checker):

```
aw status <thư-mục-feature>            in bảng ra terminal
aw status <thư-mục-feature> --write    ghi <thư-mục-feature>/progress.md
```

Nhãn (`kq_khai`): `0=XONG` (đã in bảng; `--write`: đã ghi `progress.md`), `1=KHÔNG GHI ĐƯỢC` (`--write` không ghi được file), `2=SAI THAM SỐ`. Không có dữ liệu journal nào →
vẫn in/ghi (mọi ô `—`), không lỗi (XONG).

`aw check <phase>` ĐẠT: gọi `status.sh --write` **trước** `ar_commit` (`bin/aw-engine`), để
`progress.md` đi cùng commit artifact `chore(sdlc): …`. Lỗi sinh file → cảnh báo, không đổi kết quả
check. Check lại mà chỉ `progress.md` đổi thì không tạo commit riêng (file đi cùng commit artifact kế tiếp). Ghi bằng file tạm rồi `mv`; lỗi thì giữ file cũ. Không ghi sau mỗi lượt (tránh commit nhiễu; giữa hai check, xem bằng `aw status`).

Nội dung — artifact nên heading, tên trường, tên cột, enum tiếng Anh; câu giải thích tiếng Việt
(`AGENTS.md` § Language). Dữ liệu máy đọc trong khối chú thích:

````markdown
# Progress — feat_login-otp

- Current phase: **plan**
- Updated: 2026-10-23 07:52 UTC
- Machines: laptop-a, ci-b

| Phase | Status | Active | Wall | Turns | Blocked checks | Tokens in | Tokens out | Cache read | Cache write |
|---|---|---|---|---|---|---|---|---|---|
| intake | ✓ done | 6m | 25m | 4 | 0 | 82k | 6k | 310k | 40k |
| spec | ✓ done | 18m | 2h10m | 11 | 2 | 240k | 21k | 1.2M | 90k |
| design | — skipped | | | | | | | | |
| plan | ▶ active | 9m | 40m | 5 | 0 | 120k | 9k | 600k | 30k |
| implement | · pending | | | | | | | | |
| review | · pending | | | | | | | | |
| ship | · pending | | | | | | | | |
| **Total** | | 33m | 3h15m | 20 | 2 | 442k | 36k | 2.1M | 160k |

<!-- Active = tổng thời gian các lượt (prompt → agent dừng). Wall = từ lúc bắt đầu phase tới khi phase kế tiếp bắt đầu (phase đang làm: tới sự kiện cuối). -->

> Chưa ghi được lượt nào — chỉ có cột Wall. Trên Claude Code, cài hook theo
> `adapters/claude-code/README.md` § Hook đo lượt và token.   ← chỉ có khi điều kiện Y đúng, xem dưới

```mermaid
gantt
  title Timeline
  dateFormat X
  axisFormat %d/%m %H:%M
  section intake
  intake :done, 1761203400, 1761204900
  section spec
  spec :done, 1761206000, 1761213800
  blocked :milestone, crit, 1761210000, 1761210000
  section plan
  plan :active, 1761214000, 1761216400
```

```mermaid
pie title Tokens by phase (k, in + out)
  "intake" : 88
  "spec" : 261
  "plan" : 129
```

<!-- aw-progress v1
machine	phase	runs	wall_s	active_s	turns	blocked	in	out	cache_read	cache_write	first_ts	last_ts
… một dòng mỗi (máy, phase) …
-->
````

- **Gantt**: mỗi lần chạy một thanh (`done` nếu đã ĐẠT, `active` nếu đang làm); mỗi check chặn một
  milestone `crit`. Thấy được khoảng chờ người giữa các phase và phase nào bị chặn nhiều.
- **Pie**: chỉ phase có token > 0, đơn vị nghìn token (vào + ra; cache tách riêng ở bảng vì đơn giá
  khác). Không phase nào có token → bỏ khối pie.
- **Dòng nhắc cài hook (Y)**: có ít nhất một phase có mốc bắt đầu mà `turns.tsv` (máy này) và khối
  `aw-progress` (máy khác) đều không có lượt `main` nào của việc → thêm khối trích dẫn ở trên ngay dưới
  bảng; `aw status` in cùng nội dung một dòng `· …`. Có lượt (dù không có token, vd transcript đổi định
  dạng) → không nhắc. Câu nhắc nói "trên Claude Code" vì Cursor không đo được — không đoán agent.
- **Tất định**: cùng dữ liệu → cùng byte. "cập nhật" là giờ sự kiện cuối, không phải giờ chạy lệnh.
  Số làm tròn: thời gian `Xh Ym` / `Ym` / `Zs`; token `k` (nghìn, làm tròn), `M` (triệu, 1 số lẻ).
- Phase id và nhãn trong Mermaid chỉ là id phase (ASCII) và chữ cố định của engine — không chèn chữ
  người viết, không cần thoát ký tự.

**Cộng dồn nhiều máy.** `turns.tsv` chỉ ở máy đang chạy; việc làm tiếp ở máy khác (cùng branch) thì
máy đó không có số liệu cũ. Khối `aw-progress v1` giữ **sự kiện chuẩn hoá** của việc (bắt đầu phase,
lượt, check — không đường dẫn, không chữ người viết; định dạng ở plan) kèm tên máy: khi sinh lại, dòng của
**máy này** lấy lại từ journal, dòng của máy khác giữ nguyên từ file cũ, rồi tính trên cả hai. Tên máy như
`aw journal export` (`hostname` hoặc `AW_JOURNAL_MACHINE`). Khối sai dạng → bỏ, in cảnh báo, sinh từ
journal máy này.

**Sau ship.** `aw ship create` gỡ thư mục việc khỏi branch trước khi push (`docs/kien-truc.md` § Artifact
theo việc), nên `progress.md` không vào diff MR; file vẫn ở máy và trong lịch sử branch (mất nếu
squash-merge). Reviewer thấy số liệu qua mô tả MR — § 7.

### 6. `aw journal export` / `report`

- `export`: thêm nguồn `phases`, `turns` (cùng cột `source`, `machine` như SP9).
- `report`: thêm mục "Thời gian và token theo phase" — trung vị và tổng của tương tác, đồng hồ, token
  theo phase, trên mọi việc trong nhật ký (hoặc trong các file export). Đây là số liệu SP9 cần.

### 7. Bảng tiến độ trong mô tả MR (lựa chọn B)

- `tools/ship.sh`, đường tạo MR mới: sau khi sinh `mr-description.md` (đã bỏ comment HTML của mẫu),
  nối thêm mục `## Progress` = bảng của `status.sh` (cùng hàm sinh bảng với `progress.md`; không
  Mermaid, không khối `aw-progress`, không dòng nhắc hook). Máy sinh, agent không chép tay.
- Số liệu tại lúc tạo MR: dòng ship hiện `▶ active`. MR mở từ trước (đường "đã có MR", "MR đang mở —
  đã push") không gửi lại mô tả nên không cập nhật — như phần còn lại của mô tả hiện nay.
- Đường không gửi được mô tả (không CLI) để `mr-description.md` lại cho người dán — mục `## Progress`
  đã nằm trong file đó.
- Không có dữ liệu nào (mọi ô `—`, vd việc bắt đầu trước SP20 mà cũng không có check) → không chèn mục.
- `status.sh` lỗi → không chèn, cảnh báo; không đổi kết quả `aw ship create`.
- Không đổi `workflow/templates/merge-request.md` và luật kiểm của nó: mục được nối vào bản gửi đi, không
  vào file agent viết. Mẫu MR không có `## Progress` nên `aw check ship` không biết mục này.

## File chạm

| File | Thay đổi |
|---|---|
| `tools/feature.sh` | `--phase <id>`, ghi `phases.tsv` |
| `tools/journal.sh` | `_turn begin\|end\|sub`; export/report hai nguồn mới |
| `tools/status.sh` (mới) | bảng + `progress.md` + dòng nhắc hook |
| `tools/ship.sh` | nối `## Progress` vào `mr-description.md` khi tạo MR mới |
| `bin/aw-engine`, `bin/aw` (usage) | đăng ký `aw status`; `aw check` ĐẠT gọi `status.sh --write` trước `ar_commit` |
| `adapters/lib/common.sh` | bước 0 truyền `--phase <id>` |
| `adapters/claude-code/README.md` | § Hook: ba hook mới |
| `adapters/cursor/README.md` | ghi rõ: không đo token, chỉ thời gian đồng hồ |

## Test — `tools/tests/26-progress.sh` (phần mới, fixture riêng)

- `aw feature --phase spec` ĐÃ XÁC ĐỊNH → một dòng `phases.tsv`; mã khác → không ghi; phase lạ →
  `TÊN KHÔNG HỢP LỆ`; không `--phase` → như cũ, không ghi.
- `_turn begin` + `end` với transcript mẫu → đúng tổng 4 cột token; message lặp `message.id` chỉ tính
  một lần; `end` lần hai chỉ cộng phần mới thêm vào transcript.
- `_turn` với payload thiếu `transcript_path` (kiểu Cursor), JSON hỏng, transcript không tồn tại →
  thoát 0, stdout rỗng, không ghi dòng.
- `_turn sub` → `kind=subagent`, token cộng vào phase, không tăng số lượt.
- Gắn phase: lượt sau `--phase plan` → `plan`; worktree khác → không lẫn.
- `aw status` trên fixture có intake ĐẠT, spec chặn 2 lần rồi ĐẠT, design bỏ qua, plan đang làm →
  đúng trạng thái, đúng số trong bảng, Gantt có 2 milestone `crit`, pie có 3 lát.
- Không journal → bảng toàn `—`, XONG. Không token → không có khối pie.
- Nhắc hook: có mốc bắt đầu, không lượt nào → có khối nhắc trong `progress.md` và dòng `·` ở `aw status`;
  có một lượt (token rỗng) → không nhắc; lượt chỉ có ở khối `aw-progress` của máy khác → không nhắc.
- `aw ship create` tạo MR mới → `mr-description.md` kết thúc bằng `## Progress` + bảng, không có
  ` ```mermaid`; không dữ liệu → không có mục; `status.sh` lỗi → MR vẫn tạo, có cảnh báo; đường "MR đang
  mở — đã push" → không đụng mô tả (thêm ca vào phần test ship hiện có).
- `--write` hai lần không có sự kiện mới → file giống hệt từng byte.
- Khối `aw-progress v1` có dòng máy khác → giữ nguyên và cộng vào tổng; khối sai dạng → cảnh báo, sinh
  từ journal máy này.
- `aw check <phase>` ĐẠT → `progress.md` nằm trong commit artifact; `status.sh` lỗi → check vẫn ĐẠT, có
  cảnh báo.
- `export`/`report` có `phases`/`turns` (thêm ca vào `16-journal-adr.sh`).
- `08-adapters.sh`: lệnh phase sinh ra chứa `--phase <id>` đúng phase; `AW_COMPARE=1` vẫn giống nhau.

Thủ công trước merge: dán một `progress.md` sinh từ fixture vào GitHub (issue/gist) để xác nhận hai khối
Mermaid vẽ được — test không chạy được Mermaid (không có Node).

## Tài liệu

- `docs/huong-dan.md`: mục xem tiến độ (`aw status`, `progress.md`), cài hook token.
- `docs/kien-truc.md`: vì sao số liệu suy từ journal (không agent tự khai), vì sao token chỉ Claude Code,
  vì sao ghi lúc check ĐẠT chứ không mỗi lượt, khối `aw-progress` để cộng dồn nhiều máy.
- `docs/thuat-ngu.md`: "lượt", "thời gian tương tác", "thời gian đồng hồ".
- Roadmap: SP20 → `xong` khi PR merge; SP9 ghi "thời gian phase, token: có công cụ (SP20)".
- `changes/<branch>.md`: `Thêm`.

## Rủi ro

- **Định dạng transcript Claude Code đổi** → token rỗng (trường không
  nhận ra thì rỗng, không 0). Fixture + một dòng ở `docs/kien-truc.md` § điểm yếu.
- **Hook chậm** làm mỗi lượt chậm theo: chỉ đọc phần mới của transcript; test đo không quét lại.
- **Người không cài hook** → chỉ có thời gian đồng hồ; dòng nhắc (§ 5) chỉ hiện sau lần `aw check`
  ĐẠT đầu tiên, nên phase đầu đã mất số liệu lượt.
- **Hai phiên agent cùng worktree** gắn phase theo dòng `phases.tsv` mới nhất — cùng giả định "mỗi
  worktree một agent" của approval guard.
