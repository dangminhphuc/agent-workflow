# SP1 — Định nghĩa interface SDLC

- Trạng thái: đã duyệt (2026-11-25); SP1 xong (2026-11-27, D-029)
- Ngày: 2026-11-25
- Quyết định liên quan: D-001…D-018 trong `docs/decisions.md` (lịch sử và lý do). File này là **bản hiện
  hành**: chỗ nào khác với một quyết định cũ thì file này đúng, và quyết định mới hơn đã ghi lý do.

## 1. Mục tiêu

Viết xong interface SDLC — tập trang nói một quy trình phát triển phần mềm phải có gì — sao cho người duyệt
đọc là hiểu (là gì, nhận gì, trả gì, thế nào là làm đủ, thế nào là sai), và đủ chặt để SP2 biên dịch, SP4
viết checker và test từ đó.

SP1 chỉ sinh tài liệu. Không có code.

## 2. Phạm vi

**Trong phạm vi**
- 8 trang stage: `plan`, `require` (đã duyệt), `design`, `breakdown`, `implement`, `verify`, `deploy`, `operate`.
- `interface/invariants.md`: mọi luật xuyên stage do máy kiểm.
- `interface/job-types.md`: các loại việc, stage mỗi loại bỏ hay tuỳ chọn, artifact mỗi loại thêm.
- `interface/overview.md`: hoàn thiện — câu một dòng của mọi stage, kịch bản xuyên suốt.

**Ngoài phạm vi**
- Định dạng file, nơi lưu artifact, dạng dấu duyệt, cách agent chạy một stage → SP3.
- Trình biên dịch, phần sinh tự động `interface/generated/` → SP2. Trong SP1, các luật ở §5 được kiểm bằng
  tay và `grep`.
- Chọn lại tính năng v1 không thuộc lõi một stage (câu trích nguyên văn, nhãn nguồn, ADR, luật nghiệp vụ…)
  → SP7. Thấy khi viết trang thì ghi vào `docs/decisions.md` § Ứng viên SP7, không đưa vào trang.
- `deploy` và `operate` chỉ đặc tả **điểm nối** với hệ thống bên ngoài (D-003), không đặc tả cách triển
  khai hay vận hành.

## 3. Sản phẩm

```
interface/
├── overview.md            người viết
├── stages/
│   ├── 00-plan.md         người viết (agent soạn, người duyệt)
│   ├── 01-require.md      đã duyệt (D-018)
│   ├── 02-design.md
│   ├── 03-breakdown.md
│   ├── 04-implement.md
│   ├── 05-verify.md
│   ├── 06-deploy.md
│   └── 07-operate.md
├── invariants.md
└── job-types.md
```

`interface/generated/` do SP2 sinh, không viết tay trong SP1.

## 4. Khuôn (bản hiện hành)

### 4.1 Quy ước chung

- **Ngôn ngữ**: heading, tên trường, mã, tên artifact, giá trị enum bằng tiếng Anh. Mọi chữ người viết —
  kể cả `Rule` — bằng tiếng Việt.
- **Ranh giới**: interface không nhắc tên file của engine, định dạng file, nơi lưu, dạng dấu duyệt, công cụ.
- **Mỗi thông tin một nguồn**: một quan hệ chỉ ghi ở một chỗ; chỗ khác cần thì máy sinh (SP2).
- **Backtick**: chỉ bọc tên stage, tên artifact, mã (`CAP-…`, `INV-…`), hoặc giá trị có trong bảng Giá
  trị của `overview.md`. Không bọc: tên thư mục, tên trường, mẫu mã (CAP-<stage>-NN), giá trị đứng sau
  tên trường (`Judged by: machine`), ô bảng chứa tên artifact hay stage.
- **Ô bảng**: một mã/tên, danh sách mã/tên cách dấu phẩy, `—`, hoặc văn xuôi — văn xuôi chỉ ở cột quy
  định (Used for, Description, Definition).
- **Giá trị mới** (một enum, một mức…) phải thêm vào bảng Giá trị của `overview.md` trước khi dùng.
- **Mã**: `CAP-<stage>-NN` đánh số theo thứ tự trong trang; `INV-NNN` đánh số theo thứ tự thêm vào.
  Chưa duyệt thì được đánh lại số; đã duyệt thì không đổi số, capability bỏ đi giữ chỗ trống.

### 4.2 Trang stage — `interface/stages/NN-<id>.md`

Sáu mục, đúng thứ tự:

| Mục | Nội dung | Giới hạn |
|---|---|---|
| `# Stage: <id>` | tên stage | — |
| `## Definition` | là gì, vì sao cần (bỏ đi thì hỏng gì) | tối đa 2 câu |
| `## Input` | bảng Artifact · Required (`yes`/`no`) · Used for | — |
| `## Output` | bảng Artifact · Approval (`yes`/`no`) · Description | — |
| `## Capabilities` | mỗi cái: `### CAP-<id>-NN — <tên>` + `- Rule:` + `- Judged by:` (`machine` / `agent` / `human`) + `- Artifact:` (một hay nhiều artifact trong Output) + `- Fail example:` (bắt buộc) + `- Pass example:` (tuỳ chọn) | mỗi ví dụ 1 dòng |
| `## Not in this stage` | việc dễ tưởng thuộc stage này nhưng không | tối đa 5 gạch |
| `## Rationale` | mỗi gạch mở bằng "Đã loại:", lựa chọn đã loại và vì sao | tối đa 5 gạch |

Quy tắc nội dung (rút từ trang thử):
- **Tách capability theo ai phán được.** Phần máy kiểm chính xác được là một capability `machine`; phần
  cần phán đoán là capability `agent` hay `human` riêng. Điều máy kiểm được thì không để cho người.
- **Capability chỉ nói về stage của nó.** Điều phải đúng xuyên nhiều stage là invariant (máy kiểm), hoặc
  capability của `verify` (agent/người phán).
- **Approval `yes`** khi người duyệt duyệt cả khối artifact. Khi đó phải có ít nhất một capability `human`
  có artifact đó trong trường Artifact.
- **Mỗi artifact trong Output** có ít nhất một capability bảo đảm nó.
- **Fail example** là một trường hợp sai cụ thể, đủ để thành một test case ở SP4.

### 4.3 `interface/invariants.md`

Mỗi luật:

```
### INV-NNN — <tên>
- Rule:          điều phải đúng
- Checked at:    stage (danh sách) hoặc all — luật phải đúng khi kết thúc stage đó
- Warned from:   (tuỳ chọn) stage bắt đầu báo sớm; phải đứng trước mọi stage ở Checked at
- Only for:      (tuỳ chọn) job type; không có = mọi loại việc
- Fail example:  một vi phạm cụ thể, 1 dòng
- Why:           một câu
```

Không có `Judged by` (invariant luôn do máy kiểm). Không có trường nào trỏ tới engine. Thêm invariant khi
viết trang làm lộ ra nó (ví dụ `INV-002` thêm lúc viết `require`, nơi định nghĩa mức `review-blocking`,
dù nó được kiểm ở `verify`).

### 4.4 `interface/job-types.md`

```
## Job types
| Job type | Definition | Optional | Skipped |
## Added artifacts
| Job type | Artifact | Produced by | Consumed by | Description |
## Why
- <job type>: một gạch mỗi loại
```

- `Definition` viết theo kiểu phân biệt với loại gần nó; SP2 đưa nó vào hợp đồng máy (agent cần để phân
  loại việc ở `plan`).
- Bảng chỉ ghi chỗ lệch; stage không ghi là chạy.
- Stage bị bỏ hay tuỳ chọn với một job type → input `Required: yes` lấy từ stage đó được phép vắng, chỉ
  với job type đó (máy suy ra, không ghi tay).
- Danh sách tạm theo v1: `feature`, `bugfix`, `refactor`, `perf`, `chore`.
- Còn phải viết cùng file này: invariant "stage tuỳ chọn bị bỏ phải có người duyệt việc bỏ".

### 4.5 `interface/overview.md`

Mục: giới thiệu + ranh giới · Khái niệm · Luồng (sơ đồ + câu một dòng mỗi stage) · Khi nào một stage
xong · Giá trị · Cách đọc một trang stage · Lý do chung · Kịch bản xuyên suốt (một việc đi qua 8 stage,
output stage trước là input stage sau). Lý do dùng chung nhiều trang chỉ ghi ở đây, không lặp ở trang stage.

## 5. Luật kiểm

SP2 hiện thực các luật này; trong SP1 agent kiểm bằng tay và `grep` trước mỗi lần đưa người duyệt.

**Chặn**
1. Thiếu mục, sai thứ tự mục, mục văn xuôi bắt buộc rỗng.
2. Giá trị không có trong bảng Giá trị; ô bảng sai dạng.
3. Mã trùng; chữ trong backtick không phải tên stage, tên artifact, mã có thật, hay giá trị trong bảng Giá trị.
4. Artifact ở Input không được stage nào trước nó tạo ra (tính cả artifact thêm của job type).
5. Artifact ở Output không có capability nào bảo đảm.
6. Artifact Approval `yes` không có capability `human` nào nhận nó.
7. `Warned from` không đứng trước `Checked at`.
8. (SP2) `interface/generated/` lệch với kết quả biên dịch.

**Cảnh báo**: vượt giới hạn độ dài.

**Máy sinh** (SP2, vào `interface/generated/`): sơ đồ luồng; ma trận stage × artifact; ma trận job type
× stage; với từng stage — các invariant phải đúng, ai phán (máy / agent / người, suy từ capability),
artifact cần duyệt.

**Phía engine** (SP4): mỗi Fail example có một test.

## 6. Quy trình viết một trang

Rút từ trang thử `require` (4 lần đọc lạnh + 1 lượt rà, D-014…D-017).

1. **Soạn.** Agent soạn từ v1 (`sdlc/stages/NN-*.md`, invariant và profile liên quan, phần liên quan của
   `docs/kien-truc.md`), theo khuôn §4. Chi tiết v1 không thuộc lõi stage → § Ứng viên SP7. Tự kiểm §5.
2. **Đọc lạnh.** Một agent phiên trắng, chỉ đọc `overview.md`, `invariants.md`, `job-types.md` (nếu đã
   có) và trang đó; trả lời 5 câu: là gì, vì sao cần · nhận gì · trả gì · khi nào xong, ai cho phép · một
   ví dụ làm sai. Mỗi phát hiện xếp MAJOR / MINOR, và nằm trong trang hay ngoài trang.
3. **Xử lý mỗi lần đọc.**
   - Câu chữ, nhất quán, hệ quả trực tiếp của khuôn → agent sửa.
   - Quyết định nội dung hay đổi khuôn → gom lại, hỏi người **một lần** mỗi lần đọc.
   - MAJOR ngoài trang → `docs/decisions.md` § Đang mở (chuyển SP3, SP7, hay ghi chú cho trang khác).
4. **Dừng đọc lạnh** khi không còn MAJOR trong trang, hoặc sau 3 lần. Còn MAJOR sau 3 lần → đưa người quyết.
5. **Rà.** Agent đối chiếu trang với §4, §5 và các trang đã duyệt (như D-017).
6. **Duyệt.** Người đọc trang → duyệt hoặc chỉ chỗ sửa. Duyệt → ghi D-NNN, commit, push, sửa `PROGRESS.md`.

## 7. Thứ tự

1. `plan` → `design` → `breakdown` → `implement` → `verify` → `deploy` → `operate` — theo luồng, để
   Input của mỗi trang đã có trang tạo ra nó.
2. `job-types.md` — sau khi đủ 8 trang (cần biết stage nào tạo artifact nào).
3. Hoàn thiện `overview.md`: câu một dòng của từng stage khớp trang đã duyệt; kịch bản xuyên suốt.
4. **Đọc lạnh toàn bộ**: một agent phiên trắng đọc hết `interface/`, đi theo kịch bản xuyên suốt; tìm chỗ
   các trang mâu thuẫn nhau. Rà, rồi người duyệt cả bộ.

## 8. Khi khuôn phải đổi giữa chừng

Một trang sau làm lộ lỗi khuôn → ghi D-NNN, sửa **mọi trang đã viết** trong cùng commit, sửa §4/§5 của file
này. Lần duyệt kế tiếp liệt kê các trang đã duyệt bị đổi theo, để người duyệt lại phần đổi.

## 9. Xong SP1 khi

- Có đủ các file ở §3, mỗi file người đã duyệt.
- Mỗi trang stage đã qua đọc lạnh (không còn MAJOR trong trang) và lượt rà.
- Các luật chặn ở §5 (1–7) đúng trên toàn bộ `interface/`, kiểm bằng tay.
- Đọc lạnh toàn bộ (§7 bước 4) không còn MAJOR.
- Mọi mục § Đang mở trong `docs/decisions.md` thuộc SP1 đã xử lý; mục thuộc SP khác đã chuyển đi.

## 10. Rủi ro

| Rủi ro | Giảm nhẹ |
|---|---|
| Người duyệt mỏi: 7 trang × nhiều lần đọc lạnh | Gom câu hỏi mỗi lần đọc thành một tin; dừng sau tối đa 3 lần |
| Neo vào v1: chuyển nguyên nội dung cũ mà không xét | Rationale phải nêu lựa chọn đã loại; đọc lạnh hỏi "vì sao cần" |
| Interface đặc tả điều engine không làm được | SP3/SP4 được đề xuất đổi interface bằng D-NNN mới, người duyệt |
| Kiểm tay §5 sót lỗi | Tự kiểm bằng `grep` trước mỗi lần đưa duyệt; SP2 kiểm lại toàn bộ khi có trình biên dịch |
