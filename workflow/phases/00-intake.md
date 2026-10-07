---
id: intake
name: Tiếp nhận việc
summary: Bước 1/6 · Bắt đầu việc mới từ ticket, URL hoặc file: chốt loại việc, tạo worktree, ghi intake.md
required: true
inputs:
  - confluence
  - jira
  - file
outputs:
  - intake.md
exit_machine:
  - aw check intake
exit_human:
  - Người CHỌN BASE cho worktree (agent chỉ đưa đề xuất của aw worktree new)
  - Người xác nhận LOẠI VIỆC (chọn sai loại là sai luật cả chuỗi phía sau)
  - Người xác nhận danh sách input, và lời mình được chép đúng nguyên văn
needs_clean_context: true
arguments: input
---

# Phase 00 — Tiếp nhận

## Mục tiêu

Mọi việc bắt đầu ở đây. Phase này trả lời ba câu, và **chỉ ba câu**:

1. **Làm loại việc gì** — `feature`, `bugfix`, `refactor`, `perf` hay `chore`.
2. **Xuất phát từ input nào** — tài liệu có định danh, hoặc lời người dùng.
3. **Mục tiêu một câu.**

Loại việc không phải nhãn cho đẹp: nó **đổi luật** của các phase sau (xem bảng
dưới). Input là gốc mà mọi yêu cầu `YC-xxx` về sau phải truy về.

## Loại việc

Xếp loại theo **thay đổi gì về hành vi**, không theo "xây cái gì":

```
Có sửa code chạy trên production không?
├─ Không → chore
└─ Có → Hành vi quan sát từ bên ngoài có đổi không?
        ├─ Không → mục tiêu là nhanh hơn / ít tài nguyên hơn? → có: perf / không: refactor
        └─ Có → Hành vi hiện tại có đang SAI so với tài liệu / ý định không?
                ├─ Có  → bugfix
                └─ Không → feature
```

| Loại | Luật khác biệt |
|---|---|
| `feature` | Quy trình chuẩn |
| `bugfix` | Spec có mục "Reproduction"; test tái hiện phải **đỏ trên code chưa sửa** (`aw check repro`) |
| `refactor` | YC chỉ là `preserve` / `structural`, YC preserve phải có test bảo vệ sẵn trên nhánh gốc; không được xoá test cũ, sửa test cũ phải khai |
| `perf` | Như refactor, cộng YC `performance` có số liệu và số đo trước/sau do máy ghi (`aw check perf`) |
| `chore` | Không có phase design; không được đụng code production; nâng dependency phải khai (major thì là refactor) |

Không phải loại riêng: `utils` (thêm hàm dùng chung = feature, gom code trùng =
refactor), `hotfix` (= bugfix gấp), `security` (= bugfix/feature + rủi ro cao).
`spike` nằm ngoài quy trình — output của nó là kết luận, không phải code để merge.
Việc vừa là loại này vừa là loại kia (vd refactor kèm sửa bug) thì **tách thành hai việc** (hai worktree):
luật của hai loại xung đột nhau.

## Tham số của lệnh là input

`/aw-intake JIRA-123 https://confluence/…` — tham số là **danh sách input**, không
phải tên feature. Tên feature luôn lấy từ branch (xem mục dưới).

**Nhãn do máy gán.** Luôn chạy `aw input`, truyền nguyên văn tham
số qua stdin (`-`), rồi chép **đúng stdout** vào `## Input`. Không tự gán nhãn,
không sửa dòng nó in ra. Luật (mẫu khai trong `conventions.md`):

| Token | Nhãn |
|---|---|
| Khớp `jira_key_regex`, hoặc URL `…/browse/<mã>` | `[JIRA]` |
| URL khớp `confluence_domains` (chưa khai: mọi URL còn lại, có cảnh báo) | `[CONFLUENCE]` |
| File có thật trong repo | `[FILE]` |
| Trông như đường dẫn nhưng không có file | lỗi — `ĐƯỜNG DẪN KHÔNG TỒN TẠI` |
| Còn lại | không nhận ra |

**Lời người dùng.** Chỉ cần **một** token không nhận ra, **cả chuỗi** là lời
người dùng: một mục `[HUMAN]` chép nguyên văn (`LỜI NGƯỜI DÙNG`). Tách từng từ sẽ biến
một câu thành vài "input" rác và làm mất câu gốc. Nguồn nhận ra được nằm trong
câu (vd `ABC-123` trong "sửa phí hoàn tiền ABC-123") chỉ là **đề xuất tách thêm**:
hỏi người, người đồng ý mới ghi thành dòng riêng.

| Kết quả `[x]` | Làm gì |
|---|---|
| `NGUỒN` | Chép stdout (rỗng = không có input mới) |
| `LỜI NGƯỜI DÙNG` | Chép mục `[HUMAN]`; hỏi người về "đề xuất tách thêm" nếu có |
| `KHÔNG CÓ THAM SỐ` | Hỏi người dùng, chạy lại script với **nguyên văn** câu trả lời |
| `ĐƯỜNG DẪN KHÔNG TỒN TẠI` | Hỏi lại, không tự đoán |

## Chạy lại `/aw-intake`

Đã có `intake.md` thì chạy lại là **gộp thêm input**, không viết lại:

1. Không tạo lại từ mẫu. **Giữ nguyên** dòng `Type` và `Goal`.
2. Chạy `aw input --skip <thư-mục-feature>/intake.md -` — nó bỏ các
   input đã có (so theo định danh: `ABC-1` và `…/browse/ABC-1` là một nguồn).
   **Thêm** stdout vào cuối `## Input`.
3. Input mới làm loại việc có vẻ khác đi (vd thêm incident note vào việc
   `feature`): **nêu ra cho người**, không tự sửa dòng `Type`. Người đổi loại
   thì xác nhận lại như lần đầu (và đổi tên bằng `aw rename` nếu lệch tiền tố).
4. Chạy checker, dừng cho người xác nhận **các input mới**.

Không có đường xoá input qua lệnh — muốn bỏ thì người sửa tay `intake.md`. Chỉ
gộp thêm để agent không lặng lẽ làm mất một nguồn.

`intake.md` đổi thì `spec.md` (ghi `based_on: intake.md`) thành **lỗi thời**:
chạy lại `/aw-spec` để đọc input mới. Các phase sau cảnh báo, `review` chặn nếu còn.

## Tạo worktree

Worktree là **bắt buộc**. Checkout chính luôn đứng ở `base_branch` và chỉ dùng để
chạy `/aw-intake`; mỗi việc làm trong một worktree riêng, một phiên agent riêng.
`aw feature` ra `ĐANG Ở CHECKOUT CHÍNH` khi đang ở checkout chính — với `/aw-intake` nghĩa là
"tạo worktree", với mọi lệnh khác nghĩa là "dừng lại".

Agent **không quyết** worktree đặt ở đâu hay tạo từ base nào. Làm theo thứ tự:

1. Đọc input, **chốt loại việc với người** (cây phân loại ở trên).
2. Chọn một mô tả ngắn: chữ thường ASCII, số, dấu `-` (vd `phi-hoan-tien`).
3. Chạy `aw worktree new <loại-việc> <mô-tả>` — nó **chỉ in đề xuất**:
   - tên theo `type_by_prefix` (vd `fix_phi-hoan-tien`) — branch, thư mục
     worktree và thư mục artifact dùng **cùng một tên**;
   - đường dẫn theo `worktree_dir` (mặc định `../{repo}.wt/{ten}`);
   - danh sách **base** kèm dữ kiện: `base_branch` local, `origin/<base_branch>`,
     nhánh khớp `release_branches`, hoặc ref khác do người nhập. Dấu ★ là
     gợi ý của **máy** theo một luật cố định, không phải của agent.
4. Đưa **nguyên văn** đề xuất cho người, hỏi người **chọn base** (và xác nhận
   tên). Người muốn tên khác thì đổi `<mô-tả>` và chạy lại bước 3.
5. Người chọn rồi mới chạy `aw worktree new <loại-việc> <mô-tả> --create --base <ref>`
   với **đúng ref người chọn**. Script in dòng `Base:` và dòng `Engine:` — chép
   nguyên cả hai vào `intake.md`.
6. Ghi `intake.md` vào `<worktree>/.agent-workflow/<tên>/`, chạy checker trên
   thư mục đó, rồi **dừng**: người chuẩn bị môi trường (lệnh `LENH_CHUAN_BI_WT`
   script in ra) và mở phiên agent **mới** trong worktree để chạy `/aw-spec`.
   Trong phiên mới, `aw ready <thư-mục-feature>` cho biết môi trường đã đủ chưa
   (lệnh test xanh trên base, cấu hình đủ) và bước tiếp là gì.

`ĐÃ CÓ WORKTREE` (branch đã có worktree): không tạo gì — bảo người mở phiên ở đường dẫn
script in ra, rồi chạy lại `/aw-intake` ở đó nếu cần gộp thêm input.

**Vì sao ghi Base.** Checker phía sau so diff với điểm rẽ nhánh khỏi base này.
So với `base_branch` khi base là `origin/main` (local đang chậm) hay `release/*`
sẽ quy commit của người khác cho việc này: phạm vi diff báo sai, review đọc code
không phải của mình. Base là branch việc khác (xếp chồng) thì được, nhưng review
cảnh báo: việc này dựa trên code chưa được review.

**Vì sao ghi Engine.** Mỗi việc chạy hết bằng **một** version engine — version
của bản clone lúc tạo worktree. Nâng cấp (`aw upgrade`) giữa chừng không đổi
luật của việc đang làm. Mọi checker của việc chạy đúng version ghi ở dòng
`Engine:`; máy không có version đó và không tải được thì checker báo KHÔNG HỢP
LỆ, không chạy tạm bằng version khác. So version: khớp chính xác `YYYY.M.N`.

## Việc phải làm

1. **Chốt loại việc** với người. Đang ở checkout chính: tạo worktree theo mục
   trên. Đang trong worktree (chạy lại để gộp input): gợi ý loại từ tiền tố
   branch (`type_by_prefix`), đối chiếu với input, rồi hỏi người xác nhận.

   Loại người chốt lệch tiền tố branch thì **không có ngoại lệ**: sửa loại, hoặc
   đổi tên bằng `aw rename` — nó đổi cả branch, thư mục artifact
   và thư mục worktree; người phải mở phiên mới ở đường dẫn mới.

2. **Ghi input** bằng `aw input` (mục "Tham số của lệnh là input"):
   - tài liệu: `[CONFLUENCE]` / `[JIRA]` / `[FILE]` + định danh (URL, mã issue, đường dẫn);
   - lời người dùng: `[HUMAN]`, **chép nguyên văn** ở dòng `>` bên dưới.

3. **Ghi mục tiêu** một câu vào dòng `Goal`, và hai dòng **Base**, **Engine** đúng như `aw worktree new` in ra.

4. Chạy `aw check intake` rồi dừng lại cho người xác nhận.

## Đầu ra

- `intake.md` — theo `templates/intake.md`. Đầu mục viết tiếng Anh, giữ đúng như
  mẫu (`Type`, `Base`, `Engine`, `Goal`, `## Input`) — checker đọc theo đúng chữ đó;
  nội dung điền vào vẫn viết tiếng Việt.

`01-spec` đọc các tài liệu được liệt kê, và trích lời người dùng bằng nhãn
`[FILE] intake.md § Input`.

## Cấm

- **Tóm tắt, diễn giải hay trích yêu cầu từ tài liệu nguồn.** Chỉ trỏ tới nó.
  Viết lại BRD ở đây là tạo một lớp diễn giải chen giữa tài liệu thật và spec —
  và sai lệch của lớp đó sẽ được spec gắn nhãn như có nguồn đàng hoàng.
- Tự gán nhãn input, hay sửa dòng `aw input` in ra.
- Ghi `[INFERRED]` vào input, hay ghi lời người dùng mà không phải nguyên văn.
- Chạy lại mà viết lại `intake.md` từ đầu, hay tự đổi dòng `Type`.
  Suy đoán của agent vào input thì mọi phase sau truy về nó như thể có nguồn.
- Tự chốt loại việc thay người.
- Tự chọn base, tự điền `--base`, hay tạo worktree trước khi người chọn.
- Tự sửa dòng `Engine:` — đổi version giữa chừng là đổi luật của việc.
- Tự chuyển phiên sang worktree mới — người mở phiên mới ở đó.
- Chốt phạm vi hoặc giải pháp kỹ thuật.

## Điều kiện ra

**Máy:**
- `aw check intake` ra `[x] ĐẠT` — loại việc (`Type`) hợp lệ, có mục tiêu (`Goal`), có ít
  nhất một input với nhãn hợp lệ, không `[INFERRED]`, `[HUMAN]` có nguyên văn,
  `[JIRA]` có mã khớp `jira_key_regex`, có dòng `Base:` mà sha là tổ tiên của HEAD,
  có dòng `Engine:` dạng `YYYY.M.N` khớp engine đang chạy.
  Loại lệch tiền tố branch thì cảnh báo; `review` chặn.

**Người:**
- Chọn base, xác nhận loại việc và input.
