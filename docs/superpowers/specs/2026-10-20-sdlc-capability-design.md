# Spec: Capability cho interface SDLC — interface đi trước implementation

- Ngày: 2026-10-20
- Branch: `feat/sdlc-capability`
- Phạm vi: PR 1 trong chuỗi B → A (xem § Ngoài phạm vi).

## 1. Mục tiêu

Người yêu cầu muốn interface SDLC (`sdlc/`) là **kim chỉ nam** cho engine: mọi thay đổi, tạo mới phải
theo đặc tả của interface, và interface phải **định hướng** được các thay đổi implementation sau này.

Hiện trạng không đạt điều đó vì:

1. Interface chỉ mô tả cái engine đang có. Phần thiếu nằm trong một câu `note` tự do của khối `sdlc:`
   (`workflow.yaml`), nên không biết "làm đủ" một stage là gì, cũng không biết lúc nào được đổi
   `partial` → `implemented`.
2. Quy trình đóng góp (`AGENTS.md`) không bắt đầu từ interface: không bước nào buộc người sửa nói thay
   đổi phục vụ cái gì trong interface.
3. Khoảng 200 chỗ chặn/cảnh báo trong `tools/check-*.sh` mà chỉ 11 invariant — phần lớn luật interface
   không biết tới. (Giải quyết ở bước A, không ở spec này — nhưng spec này tạo nền cho A.)

**Tiêu chí thành công của PR này:**

- Mỗi stage có danh sách capability có id mô tả **trạng thái đích**, kể cả phần engine chưa làm.
- Trạng thái stage (`implemented` / `partial` / `gap`) do máy **suy ra** từ capability được phase nhận;
  không còn khai tay. Trạng thái suy ra của engine hiện tại trùng với trạng thái đang khai.
- `sh tools/check-sdlc.sh` in bảng roadmap "capability còn thiếu"; mỗi lỗi nói cách sửa.
- `AGENTS.md` buộc "interface trước" khi đề xuất và khi sửa.
- Người không đọc diff hiểu được interface và biết cách sửa đúng, qua `docs/interface-sdlc.md`.
- `sh tools/run-tests.sh` → `MỌI CA ĐẠT`.

## 2. Các quyết định đã chốt

| # | Quyết định | Lý do |
|---|---|---|
| D1 | Thêm tầng **capability** dưới stage | Interface cần mô tả "làm đủ là gì"; bước A cần chỗ gắn luật hình dạng artifact mà không ép vào invariant |
| D2 | Id dạng `CAP-<stage>-NN` | Đọc id là biết thuộc stage nào; đổi stage thì đổi id — chấp nhận |
| D3 | Không có trạng thái `out-of-scope` | Hai cách nói cùng một điều; engine không làm → stage `gap`/`partial` + `note` nói lý do |
| D4 | Trạng thái stage do máy suy ra, khối `sdlc:` bỏ khoá `status` | Khai tay lệch với thực tế là chỗ interface nói sai; một nguồn duy nhất |
| D5 | Interface đi trước implementation (`AGENTS.md`) | Thay đổi bắt đầu bằng id CAP/INV; không id nào khớp → sửa interface trong cùng PR |
| D6 | Không thêm cổng duyệt riêng cho hạ chuẩn interface | `AGENTS.md` đã buộc người OK mọi thay đổi luật; thứ thiếu là **khả kiến**: ghi dưới `### Bỏ`/`### Thay đổi` của `changes/<branch>.md` |
| D7 | Không bắt commit sửa interface đi trước commit code | Máy không kiểm được, squash làm mất thứ tự; "cùng PR" là đủ |
| D8 | Máy không kiểm lời khai "Interface: …" trong mô tả PR | Khai tay máy không kiểm thành nghi thức; bước A sẽ suy từ diff |
| D9 | Ảnh chụp bảng roadmap trong doc chấp nhận có thể lệch | Theo cách sẵn có của các bảng trong `kien-truc.md`; test so ảnh chụp đưa vào `docs/viec-can-lam.md` |
| D10 | Tài liệu thực hành mới ở `docs/interface-sdlc.md`, không ở `sdlc/README.md` | `docs/` là chỗ tài liệu tiếng Việt cho người; `sdlc/` giữ tiếng Anh cho agent |

## 3. Mô hình

### 3.1 Capability (phía interface)

Trong **thân** `sdlc/stages/NN-<stage>.md`, thêm mục `## Capabilities`, mỗi capability một khối, cùng
dạng `sdlc/invariants.md`:

```markdown
## Capabilities

### CAP-deploy-03 — Rollback path is recorded before delivery
- Rule: the delivery record states how to undo the change; the human confirms it before release.
- Judged by: human
```

- Heading khớp ERE `^### CAP-[a-z]+-[0-9][0-9] — ` (không dùng `{n}`); phần `<stage>` phải bằng `id` của file.
- `- Rule:` bắt buộc: điều phải đúng, tiếng Anh, một câu, không tên file engine.
- `- Judged by:` bắt buộc, một trong `machine | agent | human` — ai phán capability đạt:
  `machine` = checker máy; `agent` = LLM checker hoặc agent độc lập (review); `human` = người.
  Bước A dùng trường này: capability `machine` mà có phase nhận thì phải có luật checker gắn id.
- Thân file stage giữ các gạch đầu dòng mô tả loại artifact như hiện tại; `## Capabilities` đứng sau.
- Capability không khai lại invariant; invariant vẫn ở `invariants:` của frontmatter.

### 3.2 Phase nhận capability (phía implementation)

Frontmatter phase thêm khoá danh sách `capabilities:` (tập con YAML `md.sh` đọc được):

```yaml
implements: deploy
capabilities:
  - CAP-deploy-01
```

- Chỉ được nhận capability của stage mà phase `implements`.
- Một capability có thể do nhiều phase nhận (stage `implement` = `03-plan` + `04-implement`).
- Utility command không có `capabilities:` (như `implements:`).
- Adapter chỉ đọc khoá frontmatter nó biết → lệnh sinh ra không đổi (test so adapter giữ nguyên).

### 3.3 Trạng thái stage suy ra

| Capability có phase nhận | Trạng thái | `note` trong khối `sdlc:` |
|---|---|---|
| tất cả | `implemented` | cấm (note thừa dễ nói sai) |
| một phần | `partial` | bắt buộc |
| không cái nào | `gap` | bắt buộc |

Stage không có capability nào → lỗi (mọi stage phải mô tả trạng thái đích).

Khối `sdlc:` của `workflow.yaml` mới:

```yaml
sdlc:
  - stage: deploy
    note: Dừng ở MR/PR đã merge; release, triển khai và rollback chưa làm
```

- Khoá `status` bị bỏ; còn `status` → lỗi kèm hướng dẫn xoá (không âm thầm bỏ qua).
- `wf_sdlc` (`tools/lib/md.sh`) đổi thành in `stage|note`.
- Luật cũ "gap mà có phase implement" / "partial mà không phase nào implement" được thay bằng suy ra:
  stage có phase `implements` nhưng không nhận capability nào → `gap` theo suy ra; điều đó hợp lệ nhưng
  `check-sdlc.sh` in **cảnh báo** "phase X implements stage Y mà không nhận capability nào".
  Stage `gap` không có phase nào implement vẫn hợp lệ như hiện nay.

## 4. Nội dung capability ban đầu

Mục tiêu: trạng thái suy ra trùng trạng thái đang khai (`plan` partial, `require`/`design`/`implement`
implemented, `verify`/`deploy` partial, `operate` gap). Cột "Phase nhận" là phía implementation.

| Id | Tên (Rule rút gọn) | Judged by | Phase nhận |
|---|---|---|---|
| `CAP-plan-01` | Work item recorded with type, sources and start point | machine | `00-intake` |
| `CAP-plan-02` | Human confirms work type, sources and base | human | `00-intake` |
| `CAP-plan-03` | Work items are prioritised against each other | human | — |
| `CAP-plan-04` | Work item carries an effort estimate | human | — |
| `CAP-require-01` | Each requirement traces to a source and has observable acceptance criteria | machine | `01-spec` |
| `CAP-require-02` | Each open question carries an assumption and a blocking level | machine | `01-spec` |
| `CAP-require-03` | Human approves the requirements; approval binds to their content | machine | `01-spec` |
| `CAP-design-01` | Every choice is a decision with options, trade-offs and the requirements it serves | machine | `02-design` |
| `CAP-design-02` | An independent agent looks for hidden decisions and deviations | agent | `02-design` |
| `CAP-design-03` | Human approves every decision; approval binds to its content | machine | `02-design` |
| `CAP-implement-01` | Ordered tasks, each tracing to requirements and approved decisions | machine | `03-plan` |
| `CAP-implement-02` | Tests are run by the machine; results are bound to the code they ran on | machine | `04-implement` |
| `CAP-implement-03` | The change is scanned for security issues before it leaves the stage | machine | `04-implement` |
| `CAP-verify-01` | An agent that did not build the change gives a verdict per requirement | agent | `05-review` |
| `CAP-verify-02` | A human security reviewer reads changes to sensitive code | human | `05-review` |
| `CAP-verify-03` | End-to-end tests run against the integrated system | machine | — |
| `CAP-verify-04` | Load and performance are tested beyond perf jobs | machine | — |
| `CAP-verify-05` | Stakeholders accept the change (UAT) | human | — |
| `CAP-deploy-01` | Change is delivered as a reviewed MR/PR that only a human merges | human | `06-ship` |
| `CAP-deploy-02` | Change is released or deployed to its target environment | machine | — |
| `CAP-deploy-03` | Rollback path is recorded before delivery | human | — |
| `CAP-operate-01` | The delivered change is observed in production (metrics, logs, alerts) | machine | — |
| `CAP-operate-02` | Incidents and production findings become new work items | human | — |

Câu `Rule:` đầy đủ viết khi code; người review spec chỉ cần duyệt danh sách và cột `Judged by` /
`Phase nhận`. Profile (`sdlc/profiles/`) không đổi: capability của stage bị bỏ theo profile thì không áp
dụng cho job type đó, giống `provides` của stage.

## 5. `tools/check-sdlc.sh`

**Chặn thêm** (mỗi lỗi in cách sửa):

| Lỗi | Thông báo nói cách sửa |
|---|---|
| Stage không có capability nào | thêm `## Capabilities` với ít nhất một `CAP-<stage>-NN` |
| Heading capability sai dạng, `<stage>` khác `id`, `NN` trùng | đổi id; nêu dạng đúng |
| Capability thiếu `- Rule:` / `- Judged by:`, `Judged by` lạ | thêm dòng; nêu giá trị hợp lệ |
| Phase nhận id không tồn tại | sửa id hoặc thêm capability vào stage |
| Phase nhận capability của stage nó không `implements` | chuyển id sang phase đúng stage |
| Utility command có `capabilities:` | xoá khoá |
| Khối `sdlc:` còn khoá `status` | xoá — trạng thái do máy suy ra |
| Stage suy ra `partial`/`gap` mà không có `note` | thêm note nói phần thiếu và lý do |
| Stage suy ra `implemented` mà có `note` | xoá mục khỏi khối `sdlc:` |

**Cảnh báo** (không chặn): phase `implements` một stage mà không nhận capability nào.

**In thêm**: bảng "Capability còn thiếu theo stage" (id, tên, `Judged by`, note của stage) sau bảng
ánh xạ stage → phase; bảng ánh xạ hiện có lấy cột trạng thái từ suy ra.

Đầu script (khối comment liệt kê luật chặn) cập nhật theo.

## 6. Quy tắc đóng góp (`AGENTS.md`)

- **§ Map**: `sdlc/` là nguồn gốc của mọi thay đổi engine; phase khai `capabilities:`; link
  `docs/interface-sdlc.md`.
- **§ Making a change**, bước đầu mới **Locate in the interface**: nêu các `CAP-…`/`INV-…` mà thay đổi
  phục vụ; không id nào khớp → sửa interface (capability hoặc invariant) trong cùng PR. Đề xuất thay đổi
  hành vi/luật nêu các id đó. Link `docs/interface-sdlc.md`.
- **§ Change together**, thêm:
  - Làm capability đang thiếu: id vào `capabilities:` của phase + sửa/bỏ `note` khối `sdlc:` + test hành
    vi; `sh tools/check-sdlc.sh` ĐẠT.
  - Thêm capability: `sdlc/stages/` (+ `note` nếu stage thành `partial`).
  - Hạ chuẩn interface (bỏ/nới capability hoặc invariant): ghi id + lý do dưới `### Bỏ` / `### Thay đổi`
    trong `changes/<branch>.md`.
- **Mô tả PR**: dòng "Interface: CAP-…, INV-…" hoặc "không chạm interface: <lý do>". Quy ước, máy không kiểm (D8).

Viết tiếng Anh, ngắn, đúng giọng `AGENTS.md` hiện tại.

## 7. Tài liệu cho người

### 7.1 `docs/interface-sdlc.md` (mới, tiếng Việt)

Giải thích và trỏ tới luật; không chép lại luật (luật ở `AGENTS.md`, `check-sdlc.sh`, lý do ở `kien-truc.md`).

1. **Interface là gì** — stage → capability → invariant → profile; sơ đồ quan hệ; ranh giới interface
   (`sdlc/`) và implementation (phase, `workflow.yaml`).
2. **Đọc một file stage** — `deploy` làm ví dụ, giải thích từng trường kể cả `Judged by`.
3. **Trạng thái stage suy ra** — bảng § 3.3, khi nào cần `note`.
4. **Công thức theo loại thay đổi** — mỗi mục: làm gì, theo thứ tự, file nào, lệnh nào, ghi gì vào `changes/`:
   thêm/sửa luật checker · làm capability đang thiếu · thêm capability · thêm phase · thêm job type ·
   hạ chuẩn interface · thay đổi không chạm interface.
5. **Đọc output `check-sdlc.sh`** — từng loại `[LỖI]`/`[CẢNH BÁO]` và cách sửa; đọc bảng roadmap.
6. **Roadmap hiện tại** — ảnh chụp bảng capability còn thiếu + giải thích tiếng Việt cho từng stage
   `partial`/`gap` (thiếu gì, vì sao); ghi "`sh tools/check-sdlc.sh` in lại bảng này".

### 7.2 Tài liệu sửa cùng PR

- `docs/kien-truc.md` § Interface SDLC: mô hình capability, trạng thái suy ra, bảng ánh xạ cập nhật
  (cột trạng thái suy ra), các quyết định D1–D10 kèm lý do.
- `docs/thuat-ngu.md`: `capability`, `trạng thái stage` (suy ra), `hạ chuẩn interface`.
- `docs/viec-can-lam.md` § Interface SDLC: bỏ danh sách phần thiếu tự viết, trỏ tới bảng roadmap; thêm
  "Bước A — gắn mọi luật checker vào CAP/INV" (tóm tắt § 9) và "test so ảnh chụp bảng trong doc với
  output `check-sdlc.sh`".
- `README.md`: link `docs/interface-sdlc.md` trong danh sách tài liệu.
- `changes/feat-sdlc-capability.md`: `Thêm` (capability, `docs/interface-sdlc.md`), `Thay đổi` (khối
  `sdlc:` bỏ `status`), `Nội bộ` (`check-sdlc.sh`, `AGENTS.md`, `capabilities:` trong phase).
- `docs/huong-dan.md`: **không đổi** — người dùng `aw` không thấy gì khác; PR ghi rõ.

## 8. Test

Thêm vào `tools/tests/20-sdlc-conformance.sh` (cùng chủ đề; tách part nếu chạy chậm theo `AGENTS.md`):

- Engine hiện tại ĐẠT; bảng ánh xạ in trạng thái suy ra đúng 7 stage như § 4; bảng roadmap liệt kê đúng
  các id có "—".
- Mỗi lỗi § 5 có một ca trên bản chép bị làm hỏng → KHÔNG ĐẠT, grep đúng thông báo.
- Cảnh báo phase không nhận capability: ĐẠT nhưng in cảnh báo.
- Chiều ngược: phase nhận nốt capability còn thiếu của một stage + xoá note → ĐẠT, stage thành
  `implemented`; nhận thêm mà giữ note → KHÔNG ĐẠT.
- Ca cũ về khối `sdlc:` (`status` lạ, `gap` có phase…) sửa theo mô hình mới trong cùng commit.
- Test so adapter (`AW_COMPARE=1`) vẫn giống hệt — chứng minh `capabilities:` không đổi lệnh sinh ra.

`sh tools/run-tests.sh` → `MỌI CA ĐẠT`.

## 9. Ngoài phạm vi (bước A, spec riêng sau khi PR này merge)

- Gắn id `CAP-…`/`INV-…` cho mọi chỗ chặn/cảnh báo trong `tools/check-*.sh` và mọi `Category` của
  `workflow/checkers/*.md`; `check-sdlc.sh` chặn luật mồ côi và id không tồn tại.
- Capability `Judged by: machine` có phase nhận mà không luật nào gắn id → chặn.
- Suy ra "diff chạm CAP/INV nào" từ file thay đổi, thay lời khai tay trong PR.
- Cho phép tạm danh sách luật "chưa phân loại" rồi rút dần (~200 luật).
