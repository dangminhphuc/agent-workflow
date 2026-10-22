# Interface SDLC — đọc thế nào, sửa thế nào

Tài liệu này dành cho **người sửa engine** (người hay agent): interface SDLC gồm những gì, đọc ra sao,
và mỗi loại thay đổi phải đi qua interface theo thứ tự nào. Lý do của từng quyết định nằm ở
[`kien-truc.md` § Interface SDLC](kien-truc.md#interface-sdlc); luật đóng góp nằm ở
[`AGENTS.md`](../AGENTS.md); luật máy kiểm nằm ở đầu [`tools/check-sdlc.sh`](../tools/check-sdlc.sh).
File này chỉ giải thích và chỉ đường, không đặt luật mới.

Người chỉ **dùng** `aw` trên repo dự án không cần đọc file này — interface không đổi gì họ thấy.

## 1. Interface là gì

Phase nói engine **làm thế nào**. Interface SDLC nói một quy trình phát triển **phải có gì** — kể cả
phần engine chưa làm. Mọi thay đổi engine bắt đầu từ interface: biết thay đổi phục vụ điều gì trong
interface trước, rồi mới sửa phase, checker, test.

```
INTERFACE (sdlc/ — tiếng Anh, không biết tên file engine)
│
├── stage            sdlc/stages/NN-<stage>.md     plan → require → design → breakdown → implement → verify → deploy → operate
│   ├── requires / provides   loại artifact trừu tượng (requirements, design, change…)
│   ├── invariants            INV-NNN stage phải giữ
│   └── capability   CAP-<stage>-NN   "làm đủ stage này là gì" — trạng thái đích, đã làm hay chưa
│
├── invariant        sdlc/invariants.md            INV-NNN, luật xuyên stage, trỏ tới checker + test
│
└── profile          sdlc/profiles/<job-type>.md   job type bỏ stage nào, thêm artifact / invariant nào

IMPLEMENTATION (engine)
│
├── phase            workflow/phases/NN-<id>.md
│   ├── implements:    stage phase này làm
│   ├── provides:      <loại>: <file> — loại artifact của stage → file thật
│   └── capabilities:  CAP-… phase này làm
│
├── workflow.yaml    khối sdlc:  note cho stage chưa làm đủ (vì sao thiếu)
│
└── tools/check-sdlc.sh   kiểm ánh xạ, SUY RA trạng thái stage, in roadmap
```

Ranh giới: thứ gì nằm trong `sdlc/` thì không nhắc engine (không `spec.md`, không tên phase); thứ gì
nói "engine làm cái đó ở đâu" thì nằm ở phase hoặc `workflow.yaml`.

## 2. Đọc một file stage

Ví dụ rút gọn `sdlc/stages/06-deploy.md`:

```markdown
---
id: deploy
purpose: Deliver the verified change to its target
requires:
  - change
  - review-report
provides:
  - delivery
exit: both
invariants: []
---

# Stage: deploy

- `delivery`: record of what was delivered, where, and how to roll it back.
- Exit: the human merges or releases; the agent never does.

## Capabilities

### CAP-deploy-01 — Change is delivered as a reviewed MR/PR that only a human merges
- Rule: the change reaches its target branch through a merge request that the human reviews and merges; the agent never merges.
- Judged by: human
- Artifact: delivery

### CAP-deploy-02 — Change is released or deployed to its target environment
- Rule: …
- Judged by: machine
- Artifact: delivery
```

| Trường | Nghĩa |
|---|---|
| `id` | Tên stage, trùng phần sau `NN-` của tên file |
| `purpose` | Stage tồn tại để làm gì, một câu |
| `requires` / `provides` | Loại artifact stage đọc / tạo ra. Là **loại**, không phải file: file do phase khai ở `provides:` |
| `exit` | Ai cho stage kết thúc: `machine` (checker), `human`, `both` |
| `skippable` | `false` = không profile nào được bỏ stage này |
| `invariants` | `INV-NNN` stage phải giữ (`sdlc/invariants.md`) |
| `### CAP-<stage>-NN — <tên>` | Một capability: một điều phải đúng khi stage làm **đủ** |
| `- Rule:` | Điều phải đúng, một câu tiếng Anh, không tên file engine |
| `- Judged by:` | **Ai** phán capability đạt: `machine` (checker máy), `agent` (LLM checker, agent review độc lập), `human` (người) |
| `- Artifact:` | Loại artifact (trong `provides` của stage) capability bảo đảm; một hoặc nhiều, cách nhau dấu phẩy, viết trơn; **bắt buộc** |

`Judged by` không phải trang trí: capability `machine` mà engine nhận làm thì sau này (bước A — xem
[roadmap engine](superpowers/2026-10-22-roadmap-cai-thien.md), SP19) phải có luật checker gắn id của nó. Capability `human` nghĩa là engine chỉ có
thể tạo chỗ cho người quyết, không thay người.

Capability **chưa làm vẫn nằm trong file stage**. Đó là cách interface định hướng: đọc file stage là
biết "làm đủ" trông thế nào, kể cả phần chưa ai code.

## 3. Trạng thái stage được suy ra thế nào

Không ai khai tay trạng thái. `tools/check-sdlc.sh` đếm capability của stage và capability được phase
nhận (`capabilities:` trong frontmatter phase):

| Capability có phase nhận | Trạng thái | `note` trong khối `sdlc:` của `workflow.yaml` |
|---|---|---|
| tất cả | `implemented` | **không được có** — note thừa dễ nói sai |
| một phần | `partial` | **bắt buộc** — nói phần thiếu và vì sao |
| không cái nào | `gap` | **bắt buộc** |

Hệ quả cần nhớ:

- Phase `implements` một stage thì phải nhận ít nhất một capability của stage đó. Nên `gap` luôn
  nghĩa là "không phase nào chạy stage này".
- Thêm capability mới vào một stage đang `implemented` → stage thành `partial` ngay → phải thêm note.
- Phase nhận nốt capability cuối của stage → stage thành `implemented` → phải xoá note.
- Khối `sdlc:` không còn khoá `status`; còn sót thì `check-sdlc.sh` chặn và bảo xoá.
- Capability khai ở `out_of_scope:` của `workflow.yaml` (engine quyết không làm, kèm lý do) **vẫn tính là
  thiếu**: stage không vì thế mà thành `implemented`. Nó chỉ chuyển từ bảng roadmap sang khối "Không làm".
- Mỗi loại trong `provides` của stage phải có ít nhất một capability khai `- Artifact:` loại đó, nên
  stage không thể `implemented` chỉ vì viết ít capability. Luật không áp cho `adds_provides` của
  profile: các loại đó đã có invariant máy giữ.

## 4. Công thức theo loại thay đổi

Mọi thay đổi bắt đầu giống nhau: **nêu `CAP-…` / `INV-…` mà thay đổi phục vụ** (đề xuất gửi người
duyệt và mô tả PR đều có dòng `Interface: …`). Không id nào khớp → sửa interface trước, trong cùng PR.
Sau đó theo đúng công thức dưới đây. Mỗi công thức kết thúc bằng `sh tools/check-sdlc.sh` ĐẠT và
`sh tools/run-tests.sh` → `MỌI CA ĐẠT`.

### 4.1 Thêm hoặc sửa một luật checker

1. Tìm capability hay invariant luật đó giữ (`sdlc/stages/`, `sdlc/invariants.md`).
2. Không có cái nào nói điều luật đó kiểm → thêm capability (4.3) hoặc invariant trước.
3. Viết test (đỏ) rồi code checker, như mọi luật (`AGENTS.md` § Verify). Ngay trên khối chặn / cảnh báo, ghi
   chú thích `# giữ: CAP-… [, INV-…]` — capability `machine` được phase nhận mà không luật nào khai thì
   `check-sdlc.sh` chặn; id không có cũng chặn. Mỗi chú thích phủ đúng một chỗ luật ngay dưới nó
   (trước dòng trống kế tiếp). "Chỗ luật" = gọi `loi` / `loi_truoc` / `canh_bao`, dòng in `[LỖI]` / `[CẢNH BÁO]`,
   hoặc `TỪ CHỐI:` / `DỪNG:` / `CẢNH BÁO:` (`tools/task.sh`). Luật mới không gắn thì chặn
   (số luật chưa gắn của file vượt `tools/unclassified-rules.txt`); gắn id cho luật cũ thì hạ số trong danh
   sách (`sh tools/check-sdlc.sh --dem-luat` in số đúng).
4. Luật là invariant → `Enforced by:` / `Tested by:` trong `sdlc/invariants.md` trỏ đúng file và **ít nhất một ca** test
   chặn; `Rule:` viết trừu tượng (không backtick, không mã `REQ-`/`DEC-`…), cú pháp engine ghi ở `- Engine:`.
5. `changes/<branch>.md`: mục `Thêm` / `Thay đổi` (người dùng `aw` thấy luật mới), nêu id.

### 4.2 Làm một capability đang thiếu

1. Chọn id từ bảng roadmap (`sh tools/check-sdlc.sh`, mục 6 bên dưới).
2. Đề xuất cách làm, nêu id, chờ người OK (`AGENTS.md` § Making a change).
3. Test (đỏ) cho hành vi mới → code phase / checker / template.
4. Thêm id vào `capabilities:` của phase đã `implements` stage đó (hoặc phase mới — 4.4).
5. Sửa `note` của stage trong khối `sdlc:` cho đúng phần còn thiếu; hết thiếu thì xoá cả mục stage.
6. `changes/<branch>.md`: mục `Thêm`, nêu id.

### 4.3 Thêm capability mới vào interface

1. Viết khối `### CAP-<stage>-NN — <tên>` + `- Rule:` + `- Judged by:` + `- Artifact:` vào file stage, `NN` là số kế tiếp.
2. Engine chưa làm → stage thành `partial` (hoặc vẫn `gap`) → thêm/sửa `note` trong khối `sdlc:`.
3. Engine đã làm sẵn → thêm id vào `capabilities:` của phase luôn.
4. `changes/<branch>.md`: mục `Nội bộ` (interface đổi, người dùng `aw` không thấy).

### 4.4 Thêm phase

1. Phase thuộc stage nào → `implements:`; loại artifact → `provides: - <loại>: <file>` (file phải nằm
   trong `outputs`); capability nó làm → `capabilities:` (ít nhất một).
2. Phần còn lại theo `AGENTS.md` § Change together (checker, `commands.sh`, template, test).
3. Stage đổi trạng thái → sửa `note` (§ 3).

### 4.5 Thêm job type

1. `sdlc/profiles/<job-type>.md`: stage bỏ được / luôn bỏ, artifact và invariant thêm.
2. `LOAI_HOP_LE` trong `tools/lib/cross-check.sh` + `tools/tests/21-sdlc-profiles.sh`.
3. Capability của stage bị bỏ không áp dụng cho job type đó — không cần khai gì thêm.

### 4.6 Hạ chuẩn interface (bỏ hoặc nới capability / invariant)

Đây là thay đổi luật, nên như mọi thay đổi luật: đề xuất và chờ người OK. Thêm một điều bắt buộc:
ghi **id và lý do** dưới `### Bỏ` hoặc `### Thay đổi` trong `changes/<branch>.md`, để người duyệt PR
thấy interface bị hạ, không phải tự đọc diff `sdlc/` mới biết. Không có cổng duyệt riêng — lý do ở
`kien-truc.md` § Interface SDLC.

### 4.7 Thay đổi không chạm interface

Wrapper `aw`, adapter, hạ tầng test, tài liệu thuần: mô tả PR ghi `no interface change: <lý do>`.
Máy không kiểm dòng này. Nếu diff thật ra đổi hành vi một stage (sửa checker của phase) thì dòng đó
sai — người duyệt PR là người bắt.

## 5. Đọc output `check-sdlc.sh`

Chạy `sh tools/check-sdlc.sh`. Output có ba bảng và các dòng `[LỖI]`:

1. **Stage → phase**: stage, trạng thái **suy ra**, phase implement nó.
2. **Capability còn thiếu (roadmap)**: mỗi stage chưa `implemented`, kèm note, rồi từng capability
   chưa phase nào nhận: id, `Judged by`, tên.
3. **Job type × stage**: profile chạy / bỏ stage nào; dưới bảng có thể có dòng
   `<job type>: có thể vắng: <stage>` — stage mà job type đó được phép bỏ qua.

Lỗi liên quan capability và trạng thái, và cách sửa:

| `[LỖI]` bắt đầu bằng | Nghĩa | Sửa |
|---|---|---|
| `stage X: không có capability` | File stage chưa có `### CAP-X-NN — …` nào | Thêm `## Capabilities` với ít nhất một capability |
| `stage X: heading capability "…" sai dạng` | Gõ `-` thay vì `—`, thiếu tên, `NN` không đủ hai số, id mang tên stage khác, heading `####` hay `Cap-…` trông như capability, hoặc heading `###` lạ nằm trong `## Capabilities` — máy báo thay vì lờ đi, để capability không biến mất âm thầm | Sửa heading đúng `### CAP-X-NN — <tên>` |
| `stage X: CAP-X-NN trùng` | Hai khối cùng id | Đổi số của một khối |
| `CAP-…: thiếu "- Rule:"` / `thiếu "- Judged by:"` | Khối capability thiếu dòng (dòng nằm dưới heading khác không tính) | Thêm dòng ngay dưới heading capability |
| `CAP-…: Judged by "…"` | Giá trị lạ | Chỉ `machine`, `agent`, `human` |
| `…: "Rule:" chứa cú pháp engine` | `Rule:` của capability / invariant có backtick hoặc mã `REQ-`, `DEC-`, `TSK-`, `RVW-`, `FND-`, `RFR-`, `BR-` | Viết điều phải đúng bằng lời; cú pháp engine chuyển sang `- Engine:` (invariant) |
| `INV-…: "Tested by:" không nêu ca test nào` | Invariant chỉ trỏ file test | Thêm tên ca chặn (trong `"…"`) sau đường dẫn file |
| `…: "# giữ: X" — không có capability / invariant đó` | Chú thích trong `tools/` trỏ id gõ sai hoặc đã bỏ | Sửa id hoặc xoá chú thích |
| `CAP-…: Judged by machine, phase … nhận, nhưng không luật checker nào khai` | Capability máy phán mà không chỗ code nào nói mình giữ nó | Thêm `# giữ: CAP-…` ngay trên khối chặn / cảnh báo giữ nó |
| `<file>: N luật chưa gắn "# giữ:" (cho phép M …)` | Có luật chặn / cảnh báo mới không mang id | Gắn `# giữ: CAP-…/INV-…` ngay trên (không id nào hợp → thêm capability / invariant) |
| `tools/unclassified-rules.txt: <file> cho phép M nhưng chỉ còn N` | Đã gắn id cho luật cũ mà chưa hạ danh sách | Hạ số xuống N |
| `tools/unclassified-rules.txt: dòng … sai dạng` / `… không có` / `… lặp` / `… không phải file được đếm` | Dòng danh sách hỏng | Mỗi file một dòng `<file> <số>`, file có thật và thuộc diện đếm |
| `out_of_scope: CAP-… không có` / `vừa out-of-scope vừa được phase … nhận` / `thiếu lý do` / `khai hai lần` | Mục `out_of_scope:` của `workflow.yaml` sai | Sửa id; bỏ khỏi `out_of_scope:` hoặc khỏi `capabilities:` của phase; ghi lý do; xoá dòng trùng |
| `CAP-…: khai "- Artifact:" nhiều dòng` | Hai dòng `- Artifact:` trong một capability — dòng sau đè dòng trước | Gộp vào một dòng, cách nhau dấu phẩy |
| `CAP-…: thiếu "- Artifact:"` | Khối capability không có dòng `- Artifact:`, hoặc dòng rỗng | Thêm loại artifact capability bảo đảm, lấy trong `provides` của stage |
| `CAP-…: Artifact "…" không có trong provides` | Gõ sai tên loại, hoặc capability thuộc stage khác | Sửa tên loại, hoặc chuyển capability sang stage `provides` loại đó |
| `stage X: provides "…" — không capability nào khai` | Một loại stage tạo ra mà không capability nào nói tới | Thêm capability cho loại đó, hoặc gắn loại vào `- Artifact:` của capability có sẵn |
| `phase P: capabilities "…" — không có capability đó` | Gõ sai id, hoặc capability chưa có trong file stage | Sửa id, hoặc thêm capability (4.3) |
| `phase P: capabilities "…" thuộc stage S, phase implements T` | Phase nhận capability của stage khác | Chuyển id sang phase của stage S |
| `phase P: implements T nhưng không nhận capability nào` | Phase chạy stage mà không nói làm gì của stage | Thêm id vào `capabilities:` |
| `utility command C: khai capabilities` | Utility command không thuộc stage nào | Xoá khoá |
| `khối sdlc: stage X còn khoá status` | Khối `sdlc:` kiểu cũ | Xoá dòng `status:` |
| `stage X: suy ra partial/gap nhưng khối sdlc: không có note` | Stage chưa đủ mà không nói vì sao | Thêm `note:` |
| `stage X: suy ra implemented nhưng khối sdlc: còn note` | Stage đã đủ mà note cũ còn | Xoá mục stage X khỏi khối `sdlc:` |

Các lỗi khác (`provides`, `exit`, thứ tự phase, invariant, profile) liệt kê ở đầu
`tools/check-sdlc.sh`; lý do ở `kien-truc.md` § Interface SDLC.

## 6. Roadmap hiện tại

Ảnh chụp ba bảng của `sh tools/check-sdlc.sh` — **ảnh chụp duy nhất** trong docs. Test
`tools/tests/20-sdlc-conformance.sh` so khối dưới đây với output thật; lệch là test hỏng, nên engine đổi
thì phải chép lại khối này:

```
Stage → phase (trạng thái suy ra từ capabilities: của phase):
  plan       partial      intake
  require    implemented  spec
  design     implemented  design
  breakdown  implemented  plan
  implement  implemented  implement
  verify     partial      review
  deploy     partial      ship
  operate    gap          —
Capability còn thiếu (roadmap — mô tả ở sdlc/stages/):
  plan (partial): Chỉ nhận việc đã có (ticket, tài liệu, lời người); không lập roadmap, ước lượng hay ưu tiên giữa các việc
    CAP-plan-03  human    Work items are prioritised against each other
    CAP-plan-04  human    Work item carries an effort estimate
  verify (partial): Review độc lập đối chiếu diff với spec, thiết kế, kế hoạch và bằng chứng test/quét máy ghi; chưa có UAT (e2e, kiểm tải: out_of_scope)
    CAP-verify-05  human    Stakeholders accept the change (UAT)
  deploy (partial): Dừng ở MR/PR đã merge; release, tag, triển khai và rollback chưa làm
    CAP-deploy-03  human    Rollback path is recorded before delivery
  operate (gap): CI/CD và observability nằm ngoài engine; sự cố chưa quay lại thành việc mới
    CAP-operate-02  human    Incidents and production findings become new work items
Không làm (out-of-scope — lý do trong workflow.yaml):
  verify (partial)
    CAP-verify-03  machine  E2E trên hệ thống đã ghép là việc của CI/CD của repo đích, không của engine
    CAP-verify-04  machine  Hạ tầng đo tải nằm ngoài engine; việc loại perf đã có số đo trước/sau do máy ghi
  deploy (partial)
    CAP-deploy-02  machine  Release và triển khai là pipeline của repo đích; engine dừng ở MR/PR người merge
  operate (gap)
    CAP-operate-01  machine  Quan sát production thuộc hệ thống observability bên ngoài
Job type × stage (chạy · tuỳ = có thể bỏ · bỏ · gap = engine không làm):
             plan       require    design     breakdown  implement  verify     deploy     operate
  bugfix     chạy       chạy       tuỳ        chạy       chạy       chạy       tuỳ        gap
  chore      chạy       chạy       bỏ         chạy       chạy       chạy       tuỳ        gap
  feature    chạy       chạy       chạy       chạy       chạy       chạy       tuỳ        gap
  perf       chạy       chạy       chạy       chạy       chạy       chạy       tuỳ        gap
  refactor   chạy       chạy       tuỳ        chạy       chạy       chạy       tuỳ        gap
  bugfix: có thể vắng: design
  chore: có thể vắng: design
  refactor: có thể vắng: design
```

Đọc bảng theo từng stage chưa đủ:

- **`plan` — partial.** Engine nhận một việc đã được ai đó chọn (ticket, tài liệu, lời người), ghi
  loại việc, nguồn, base, và để người xác nhận. Chưa có: xếp ưu tiên giữa các việc (`CAP-plan-03`) và
  ước lượng công (`CAP-plan-04`). Cả hai đều `human`: engine chỉ có thể tạo chỗ ghi và kiểm đã ghi,
  quyết vẫn là người.
- **`verify` — partial.** Có review độc lập theo từng REQ và người review bảo mật cho code nhạy cảm.
  Chưa có: người yêu cầu nghiệm thu (UAT, `CAP-verify-05`). **Không làm** (out-of-scope): e2e trên hệ
  thống đã ghép (`CAP-verify-03`) và đo tải cho mọi thay đổi (`CAP-verify-04`) — việc của CI/CD và
  hạ tầng của repo đích.
- **`deploy` — partial.** Engine dừng ở MR/PR mà người merge. Chưa có: đường rollback được ghi và
  người xác nhận trước khi release (`CAP-deploy-03`). **Không làm**: release / triển khai
  (`CAP-deploy-02`) — pipeline của repo đích.
- **`operate` — gap.** Sự cố chưa quay lại thành việc mới (`CAP-operate-02`) — việc engine có thể làm
  ([roadmap engine](superpowers/2026-10-22-roadmap-cai-thien.md), SP16). **Không làm**: quan sát production (`CAP-operate-01`) —
  hệ thống observability bên ngoài.

Muốn làm một dòng trong bảng: theo công thức 4.2. Muốn đưa một capability vào hay ra khỏi khối
**Không làm**: sửa khoá `out_of_scope:` của `workflow.yaml` (`- CAP-id: lý do`) — trạng thái stage không
đổi, chỉ roadmap đổi.
