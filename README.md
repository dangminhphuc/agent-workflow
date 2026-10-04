# agent-workflow

Quy trình phát triển phần mềm dựa trên AI agent, **không phụ thuộc vào một agent cụ thể**.

Repo này là *nguồn*. Bạn cài nó vào repo dự án thật, nó sinh ra artifact riêng cho
agent bạn đang dùng. Hiện có adapter cho **Claude Code**; Cursor và Copilot đã có
khe cắm trong manifest nhưng chưa hiện thực.

## Ý tưởng cốt lõi

Tính không-phụ-thuộc-agent **không đến từ lớp trừu tượng hoá API**. Nó đến từ một
quy ước đơn giản hơn nhiều:

> Mỗi phase là một hộp **file vào → file ra**, không dựa vào ngữ cảnh hội thoại.

Agent nào cũng đọc và ghi được file. Vì vậy mỗi phase chạy được bằng Claude Code,
bằng Cursor, bằng một người, hay bằng một phiên mới sau khi phiên cũ đã bị nén
ngữ cảnh. Adapter chỉ làm một việc: dịch định nghĩa phase sang dạng native của
từng agent cho tiện gọi.

Hệ quả kiểm chứng được: **mỗi phase phải chạy được từ một phiên trắng.** Nếu một
phase không chạy nổi khi mở phiên mới, phase trước đã ghi thiếu.

Hệ quả thứ hai: **vào quy trình ở phase nào cũng được.** Artifact có thể được tạo
bằng tool bất kỳ — AI khác, Confluence, viết tay — rồi đưa vào đúng phase cần.
Điều kiện: nó vẫn phải qua checker và gate người của phase lẽ ra đã sinh ra nó
(xem [Đưa artifact từ ngoài vào](#đưa-artifact-từ-ngoài-vào)).

Nền tảng gồm bốn nguyên tắc:

1. **Bàn giao bằng file** — không phase nào biết gì về phase đứng sau nó.
2. **Trung lập agent** — phần lõi nằm trong file, mẫu và script, không nằm trong prompt.
3. **Agent không tự duyệt** — điều gì máy kiểm được thì máy kiểm; còn lại người quyết.
4. **Flow không tắc** — chỉ chặn khi checker chính xác; kiểm chéo hay báo nhầm thì
   cảnh báo, `review` là cổng chặn cuối.

Và một lớp quản trị quyết định: các quyết định kỹ thuật được tách thành mục
**D-xx** riêng, để người duyệt *quyết định* chứ không phải đọc duyệt cả một bài
văn xuôi.

## Các phase

```mermaid
flowchart TD
    INTAKE["00-intake · bắt buộc<br/>→ intake.md (loại việc + input)<br/><i>MÁY: kiem-tra-tiep-nhan.sh</i><br/><i>NGƯỜI: xác nhận loại việc, input</i>"]
    SPEC["01-spec<br/>→ spec.md + open-questions.md<br/><i>MÁY: kiem-tra-truy-vet.sh</i><br/><i>NGƯỜI: duyệt YC, Mức chặn, Mức rủi ro</i>"]
    PHAC[/"Người phác D-xx trước<br/>(bắt buộc khi Mức rủi ro: cao)"/]
    DESIGN["02-design<br/>→ tdd.md (quyết định D-xx)<br/><i>MÁY: kiem-tra-thiet-ke.sh + checker LLM (chỉ chặn)</i><br/><i>NGƯỜI: duyệt từng D-xx</i>"]
    PLAN["03-plan<br/>→ plan.md<br/><i>MÁY: kiem-tra-ke-hoach.sh</i>"]
    IMPL["04-implement<br/>→ diff + ket-qua-kiem-thu.md<br/><i>MÁY: kiem-tra-hien-thuc.sh (tự chạy test)</i>"]
    REVIEW["05-review · ngữ cảnh trắng<br/>đọc mọi artifact + diff → review.md<br/><i>MÁY: kiem-tra-ra-soat.sh</i><br/><i>NGƯỜI: xác nhận kết luận</i>"]
    SHIP["06-ship · tuỳ chọn"]

    NGOAI[/"Artifact làm bằng tool khác<br/>(AI khác, Confluence, viết tay)"/]
    IMPORT["Import có kiểm soát<br/>lệnh riêng, không thêm nội dung"]

    INTAKE --> SPEC --> DESIGN
    PHAC -.-> DESIGN
    DESIGN --> PLAN --> IMPL --> REVIEW --> SHIP
    SPEC -. "chore: bỏ design" .-> PLAN

    IMPL -. "cảnh báo dồn về: artifact lỗi thời,<br/>test ↔ YC, phạm vi diff" .-> REVIEW

    NGOAI --> IMPORT
    IMPORT -. "vào giữa chừng" .-> SPEC
    IMPORT -. "vào giữa chừng" .-> DESIGN
    IMPORT -. "vào giữa chừng" .-> PLAN

    classDef nguoi stroke-width:3px
    classDef tuychon stroke-dasharray:5 5
    class INTAKE,SPEC,DESIGN,REVIEW nguoi
    class SHIP tuychon
```

Cách đọc:

- **Viền đậm** = phase có gate **NGƯỜI**. `plan` và `implement` không có người —
  chúng chỉ thực thi những gì đã duyệt ở `spec` và `design`.
- **MÁY** = lệnh phải chạy xanh trước khi agent được nói "xong". Lệnh fail thì
  quay lại sửa trong chính phase đó.
- **Mũi tên nét đứt "cảnh báo"** = kiểm chéo giữa phase: không chặn giữa chừng,
  nhưng dồn về `review` — cổng chặn cuối — và chưa xử lý thì `review` chặn.
- **"Vào giữa chừng"** = artifact từ tool khác, sau khi import, vẫn phải qua
  checker và gate người của phase lẽ ra đã sinh ra nó.

```
00-intake     [bắt buộc]  tài liệu hoặc lời người dùng     →  intake.md
01-spec       [bắt buộc]  intake.md + các input nó liệt kê →  spec.md + open-questions.md
02-design     [bắt buộc*] spec.md                            →  tdd.md          (*chore bỏ qua)
03-plan       [bắt buộc]  spec.md + tdd.md                   →  plan.md
04-implement  [bắt buộc]  plan.md + tdd.md                   →  diff + ket-qua-kiem-thu.md
05-review     [bắt buộc]  mọi artifact + diff                →  review.md
06-ship       [tuỳ chọn]  phụ thuộc hạ tầng CI của repo đích
```

- **Không có phase test riêng.** Test là **điều kiện ra** của `implement`: chưa
  xanh nghĩa là chưa xong. Một phase test đặt phía sau sẽ biến "code xong" thành
  trạng thái hợp lệ dù chưa ai chạy gì.
- **Vận hành không phải phase.** Incident note là một loại nguồn đầu vào của `spec`.

### Người tham gia ở đâu

| Phase | Người | Người làm gì |
|---|---|---|
| `intake` | có | Xác nhận **loại việc** và danh sách input (lời mình được chép đúng nguyên văn) |
| `spec` | có | Duyệt yêu cầu, nhãn `Mức chặn` của `[CẦN-HỎI]`, và `Mức rủi ro`; rồi đổi `Trạng thái spec` sang `đã duyệt`. Trả lời điểm mù qua `/open-questions` |
| `design` | có | Duyệt **từng D-xx** trong `tdd.md` |
| `plan` | không | — |
| `implement` | không | — |
| `review` | có | Xác nhận kết luận; làm trọng tài cho phát hiện của checker |
| `ship` | có | Tuỳ hạ tầng |

`plan` và `implement` không có người vì chúng chỉ thực thi những gì đã được duyệt
ở `spec` và `design`.

### `00-intake` — tiếp nhận: loại việc và input

Điểm xuất phát bắt buộc của mọi việc. `intake.md` trả lời đúng ba câu:

1. **Loại việc** — `feature | bugfix | refactor | perf | chore`. Gợi ý từ tiền tố
   branch (`loai_theo_tien_to` trong `conventions.md`), **người xác nhận**, và
   `intake.md` là nguồn sự thật. Loại lệch tiền tố branch thì cảnh báo, `review`
   chặn — **không có ngoại lệ**: sửa loại, hoặc đổi tên bằng
   `tools/doi-ten-feature.sh` (đổi cả branch, thư mục artifact và thư mục worktree).
2. **Input** — tài liệu có định danh (`[JIRA]`, `[CONFLUENCE]`, `[FILE]`), hoặc
   lời người dùng **chép nguyên văn** (`[NGƯỜI-DÙNG]`). Không có `[SUY-RA]` ở đây:
   suy đoán của agent mà vào input thì mọi phase sau truy về nó như có nguồn.
3. **Mục tiêu** một câu.

Kèm dòng **Base** — base người chọn khi tạo worktree (xem dưới); checker phía sau
so diff với base này.

`00` chỉ **trỏ tới** tài liệu, không tóm tắt hay diễn giải BRD — nếu không nó
thành một lớp diễn giải chen giữa tài liệu thật và spec.

**Cách gọi:** `/intake JIRA-123 https://confluence/…` — tham số là **input**, không
phải tên feature (các lệnh khác thì tham số là tên feature). Tên feature luôn lấy
từ branch.

**Worktree là bắt buộc.** Checkout chính luôn đứng ở `nhanh_goc` và chỉ dùng để
chạy `/intake`; mọi lệnh khác chạy ở đó đều bị chặn (`ĐANG Ở CHECKOUT CHÍNH`). `/intake` ở checkout
chính: agent chốt loại việc với bạn, rồi chạy `tools/tao-worktree.sh <loại-việc>
<mô-tả>` — script **chỉ đề xuất**:

```
  Tên        fix_phi-hoan-tien   (tiền tố fix_ ← bugfix)
  Đường dẫn  /home/dev/shop.wt/fix_phi-hoan-tien
             (thu_muc_worktree: ../{repo}.wt/{ten})

  Base — chọn một:
     [1] main               c629505  2 hours ago  "…"
         nhanh_goc local — ⚠ chậm 2 commit so với origin/main
   ★ [2] origin/main        80dc1bf  1 hour ago   "…"
         bản remote tính tới lần fetch cuối: 2026-09-29 17:25 (script không tự fetch)
     [3] release/1.2        c629505  3 days ago   "…"
         khớp mau_nhanh_phat_hanh — hợp với bugfix gấp trên bản đã phát hành
     [4] ref khác — người nhập (branch, tag, commit). Branch việc khác (xếp chồng): review sẽ cảnh báo
```

**Bạn chọn base**; ★ là gợi ý của máy theo một luật cố định (giữa `main` và
`origin/main`, bản nào chứa bản kia; phân kỳ thì không gợi ý), không phải của
agent. Agent chạy lại với `--tao --goc <ref bạn chọn>` — thiếu `--goc` là bị từ
chối. Script tạo worktree (branch `--no-track`, để `git push` trơn không đẩy lên
`main`), in dòng `Base:` để ghi vào `intake.md`, và nhắc bạn chuẩn bị môi trường
(`LENH_CHUAN_BI_WT`) rồi **mở phiên agent mới** trong worktree để chạy `/spec`.

Branch, thư mục worktree và thư mục artifact dùng **cùng một tên**. Worktree đặt
**ngoài** repo (mặc định `../{repo}.wt/{ten}`), để tool không quét trùng code và
agent không đọc nhầm artifact của worktree khác; mỗi máy ghi đè được bằng biến
môi trường `AW_THU_MUC_WORKTREE`.

**Vì sao ghi Base.** Checker so diff với điểm rẽ nhánh khỏi base, không phải
`nhanh_goc`. Tạo từ `origin/main` khi `main` local đang chậm, hay từ `release/*`,
mà so với `main` local thì commit của người khác bị tính cho việc này. Base là
branch việc khác (xếp chồng) vẫn được — nhập qua "ref khác" — nhưng `review`
cảnh báo để bạn xác nhận có chủ ý: việc dựa trên code chưa được review.

**Dọn dẹp.** `tools/don-worktree.sh <tên-branch>` chạy từ checkout chính: mặc định
chỉ in trạng thái; `--xoa` gỡ worktree (branch giữ nguyên); `--xoa --ca-branch`
xoá thêm branch local bằng `git branch -d`. Không bao giờ `--force` hay `-D`: còn
thay đổi chưa commit thì chặn; squash-merge làm git từ chối xoá branch thì bạn tự
quyết `git branch -D`. Phase nào gọi lệnh này sẽ định sau.

Nhãn input do **máy** gán: `tools/phan-loai-input.sh` nhận mã Jira (`mau_jira`),
URL Confluence (`mien_confluence`), file có thật trong repo. Chỉ cần một từ không
nhận ra thì **cả chuỗi** là lời người dùng, chép nguyên văn thành một mục
`[NGƯỜI-DÙNG]` — vd `/intake sửa phí hoàn tiền bị âm ABC-123`; mã `ABC-123` trong
câu chỉ là đề xuất tách thêm, bạn đồng ý mới thành input riêng. Chạy lại `/intake`
trong worktree đã có `intake.md` thì **gộp thêm** input mới (bỏ trùng), giữ nguyên
loại việc; `spec.md` khi đó thành lỗi thời và phải chạy lại `/spec`.

Xếp loại theo **thay đổi gì về hành vi**, không theo "xây cái gì":

```
Có sửa code chạy trên production không?
├─ Không → chore
└─ Có → Hành vi quan sát từ bên ngoài có đổi không?
        ├─ Không → mục tiêu là nhanh hơn? → có: perf / không: refactor
        └─ Có → Hành vi hiện tại đang SAI so với tài liệu/ý định? → có: bugfix / không: feature
```

Loại việc **đổi luật** của các phase sau:

| Loại | Phase | Máy ghi / chặn thêm | Người phán |
|---|---|---|---|
| `feature` | đủ | — | — |
| `bugfix` | đủ | Spec có "Tái hiện lỗi". `kiem-tra-tai-hien.sh` tự chạy test khi diff **mới chỉ đụng file test**, ghi `tai-hien.md`; test phải **đỏ** | Test đỏ **đúng vì bug** (review ghi "Test tái hiện đỏ vì: …") |
| `refactor` | đủ | YC chỉ `giữ nguyên \| cấu trúc`; YC giữ nguyên có `Được bảo vệ bởi:` file test **có sẵn trên nhánh gốc**. Xoá test cũ → chặn; sửa test cũ phải khai ở "Test cũ bị sửa" | Diff test cũ chỉ đổi import/cấu trúc |
| `perf` | đủ | Như refactor + YC `hiệu năng` có số liệu; `kiem-tra-hieu-nang.sh --truoc/--sau` tự đo, ghi `do-hieu-nang.md` | Số đo có đạt mục tiêu (đo dao động nên máy không chặn theo ngưỡng) |
| `chore` | bỏ design | Diff đụng `mau_code_production` → chặn; đụng `mau_file_dependency` thì plan phải có bảng "Nâng dependency" (chỉ `vá \| minor` — major là `refactor`) | Mức phiên bản khai đúng |

Không phải loại riêng: `utils` (= feature hoặc refactor), `hotfix` (= bugfix gấp),
`security` (= bugfix/feature + rủi ro cao). `spike` nằm ngoài quy trình. Việc lai
(refactor kèm sửa bug) thì **tách branch** — luật hai loại xung đột nhau.

### `01-spec` — yêu cầu

Mỗi yêu cầu `YC-xxx` phải truy được về một input trong `intake.md` (Confluence, Jira, file cục
bộ). Chỗ chưa rõ ghi `[CẦN-HỎI]` kèm **Mức chặn** do agent đề xuất, người duyệt
ở gate spec — đúng ba mức:

| Mức chặn | Sai giả định thì | Chặn gì |
|---|---|---|
| `chặn` | Cả thiết kế đổi hướng | `design` (chore: `plan`) và mọi phase sau, tới khi `đã trả lời` |
| `chặn review` | Làm lại một phần code | Flow đi tiếp trên giả định tạm; `implement` cảnh báo, `review` chặn |
| `không chặn` | Sửa nhỏ | Không chặn; `review` ghi YC đó `chờ xác nhận`, không được `đạt` |

**`/open-questions`** — lệnh tiện ích, chạy bất cứ lúc nào sau `/spec`. Máy
(`tools/liet-ke-cau-hoi.sh`) liệt kê điểm mù còn mở theo thứ tự phải chốt trước —
mức chặn, rồi YC `bắt buộc` trước `nên có`, rồi mục có nhiều task đứng trên giả
định hơn — và đánh dấu mục **đang chặn** phase kế tiếp. Agent dẫn bạn đi **từng
mục một**: câu hỏi, tài liệu nói gì, giả định đang dùng, hệ quả nếu sai, vài
phương án lấy từ nguồn. Bạn trả lời → agent ghi nguyên văn, đổi nhãn nguồn trong
spec, chạy lại checker. Chưa trả lời được → agent soạn sẵn tin nhắn gửi người
cần hỏi. Agent không tự trả lời, không tự hạ mức chặn.

Spec cũng gắn `Mức rủi ro: cao | thường`. **Cao** khi đụng tiền/hạch toán, tích
hợp mới, schema lõi, hoặc thay đổi khó đảo ngược.

Gate người để lại dấu vết trong file: `Trạng thái spec: đề xuất | đã duyệt`, chỉ
người đổi sang `đã duyệt`; `design` (chore: `plan`) chặn tới lúc đó. Khi một
`[CẦN-HỎI]` được trả lời, `open-questions.md` và nhãn nguồn trong spec phải đổi
cùng nhau — checker đối chiếu hai chiều.

### `02-design` — Technical Design Document

Output duy nhất: `tdd.md` (Technical Design Document, **không phải** Test-Driven
Development). Nó chứa mọi thông tin `implement` cần để làm đúng kỹ thuật:

- Bối cảnh code hiện có
- **Quyết định D-xx** — người duyệt từng mục; mục này được phép rỗng
- Mô hình dữ liệu + ERD
- Contract / API
- Flow, sequence, state (Mermaid)
- Yêu cầu phi chức năng
- Chiến lược test
- Ánh xạ YC → mục thiết kế

Mục không áp dụng ghi `Không áp dụng: <lý do>` chứ không bỏ trống. Mục chi tiết
ghi `Dựa trên: D-xx`; checker LLM tìm chỗ lệch D-xx và các quyết định ngầm chưa
được nêu thành D.

Mỗi D-xx có `tac_gia: nguoi | agent` và `Trạng thái: đề xuất | đã duyệt | mở lại`.
**Chỉ người** đổi sang `đã duyệt`; `/plan` chặn nếu còn D chưa duyệt.

Hai cách làm:

- **Mode 1** — agent viết cả `tdd.md` một lần, người duyệt.
- **Mode 2** — người phác các mục D-xx trước (`tac_gia: nguoi`), agent viết phần
  còn lại và chỉ **phản biện** quyết định của người. Spec có `Mức rủi ro: cao` mà
  chưa có bản phác của người thì `design` chặn — để tránh người duyệt bị neo vào
  phương án agent đưa ra.

**Mở lại quyết định:** mở lại đúng một D-xx, sửa tại chỗ (lịch sử để git giữ), ghi
trạng thái `mở lại` + dòng `Lý do mở lại:`. Grep `Dựa trên: D-xx` ra các task bị ảnh hưởng, chỉ
các task đó đặt lại `[ ]`; người chỉ duyệt lại D đang mở.

### `03-plan` — quản lý thực thi

`plan.md` chỉ còn phần thực thi: task, thứ tự/phụ thuộc, `Phủ: YC-xxx`,
`Dựa trên: D-xx`, `Theo: tdd.md § …`, File dự kiến, Cách kiểm chứng, task dựa
trên giả định, trạng thái, Phát sinh, Hoãn lại. Nó tách khỏi `tdd.md` để việc
tick task không bao giờ sửa vào tài liệu thiết kế đã duyệt.

### `04-implement` — code + test

- Test gắn tag `covers: YC-xxx`. YC chưa có test → **cảnh báo**. YC không test tự
  động được ghi `Kiểm chứng: thủ công` + lý do.
- So `git diff --name-only <nhánh-gốc>...HEAD` với "File dự kiến" (cho phép glob)
  và "Phát sinh" của plan. File ngoài phạm vi → **cảnh báo**.

### `05-review` — rà soát độc lập

Chạy bằng phiên/subagent có ngữ cảnh trắng, không phải phiên vừa viết code. Đây
là **cổng chặn cuối**: mọi cảnh báo từ phase trước (artifact lỗi thời, YC chưa có
test, diff ngoài phạm vi) chưa xử lý thì `review` chặn.

## Cổng chặn

Điều kiện ra chia hai loại. Loại **NGƯỜI** thì agent nêu ra rồi dừng. Loại **MÁY**
thì agent không được tự tuyên bố đạt — phải chạy lệnh:

| Phase | Lệnh | Bắt cái gì |
|---|---|---|
| `intake` | `kiem-tra-tiep-nhan.sh` | Loại việc ngoài 5 loại, thiếu mục tiêu, không có input, `[SUY-RA]` trong input, `[NGƯỜI-DÙNG]` không kèm nguyên văn |
| `spec` | `kiem-tra-truy-vet.sh` | Yêu cầu không truy được về nguồn → agent bịa yêu cầu; thiếu phần bắt buộc theo loại việc; `open-questions.md` lệch spec; `Mức chặn` thiếu/sai |
| `design` | `kiem-tra-thiet-ke.sh` | Spec chưa được người duyệt, điểm mù `chặn` còn mở, thiếu mục, D-xx sai trạng thái, `Dựa trên` trỏ sai, YC chưa ánh xạ, rủi ro cao mà thiếu bản phác của người, checker LLM chưa chạy hoặc còn phát hiện `Chặn` |
| `plan` | `kiem-tra-ke-hoach.sh` | D-xx chưa được người duyệt, task thừa, và **yêu cầu bị bỏ sót** (kiểm hai chiều) |
| `implement` | `kiem-tra-hien-thuc.sh` | Test chưa xanh, task còn dở |
| `review` | `kiem-tra-ra-soat.sh` | Bỏ sót yêu cầu, kết luận "đạt" khi còn giả định chưa xác nhận, điểm mù `chặn`/`chặn review` còn mở, test chưa xanh, hoặc **còn cảnh báo** |

Mọi script in khối **Kết quả** ở cuối output (ra stderr), đánh `[x]` vào đúng
một nhãn — người và agent đọc nhãn, không đọc mã số:

```
Kết quả: kiem-tra-ke-hoach.sh
  [ ] ĐẠT — được sang phase sau
  [x] KHÔNG ĐẠT — có vi phạm, sửa trong phase này
  [ ] THIẾU ĐẦU VÀO — chưa có file cần kiểm
```

Mã thoát vẫn còn — script gọi lẫn nhau cần nó — nhưng chỉ là chi tiết của máy.
Nhãn của từng script khai ở dòng `kq_khai` đầu script (`tools/lib/ket-qua.sh`).

`kiem-tra-hien-thuc.sh` **tự chạy lệnh test và tự ghi output** vào
`ket-qua-kiem-thu.md`. Agent không có cơ hội viết lại kết quả bằng lời hay bịa
một dòng "tất cả test đã xanh".

Adapter tự từ chối build nếu một mục `exit_machine` không phải lệnh chạy được —
nếu không, điều kiện loại NGƯỜI sẽ đội lốt loại MÁY và agent sẽ tự duyệt.

**Entry check:** checker của mỗi phase chạy lại checker của phase trước trên
đầu vào (`thiet-ke` → `truy-vet`, `ke-hoach` → `thiet-ke`, …). Artifact đưa từ
tool khác vào cũng phải qua đúng cổng đó.

### Chặn hay cảnh báo

| Loại checker | Ví dụ | Hành vi |
|---|---|---|
| **Chính xác** — hợp đồng output của chính phase | truy vết nguồn, phủ YC, test xanh | **Chặn** |
| **Kiểm chéo giữa phase**, hay báo nhầm | artifact lỗi thời, test ↔ YC, phạm vi diff | **Cảnh báo**; `review` chặn |

Tiêu chí xếp một checker mới: độ chính xác, chi phí nếu lọt, và nơi sửa rẻ nhất.

### Checker LLM: chỉ được chặn, không được duyệt

Checker dùng LLM (subagent `soat-thiet-ke`, định nghĩa ở
`workflow/checkers/thiet-ke.md`) ghi phát hiện ra `phat-hien-thiet-ke.md`;
`kiem-tra-thiet-ke.sh` fail nếu còn mục `Mức: Chặn` mà `Xử lý` chưa là `đã sửa`
hoặc `bác bỏ: <lý do>`. **Không có file phát hiện cũng là fail** — nghĩa là
checker chưa chạy. Người là **trọng tài theo ngoại lệ**: xác nhận, hoặc bác bỏ
kèm lý do. LLM không bao giờ là bên nói "đạt".

### Artifact lỗi thời

Mỗi artifact ghi `based_on` là hash **cả file** của đầu vào:

```
based_on:
  - spec.md@<hash>
```

Hash do máy ghi (`tools/cap-nhat-based-on.sh`, dùng `cksum`, bỏ `\r`), không để
agent tự chép. `spec.md` dựa trên `intake.md`; `tdd.md` dựa trên `spec.md` +
`open-questions.md`; `plan.md` dựa trên `spec.md` + `tdd.md`. Lệch hash chỉ **cảnh báo** ở các phase sau; `review`
chặn nếu còn artifact lỗi thời.

### Kiểm chéo ở `implement`

`kiem-tra-hien-thuc.sh` in **cảnh báo**, `kiem-tra-ra-soat.sh` coi cùng phát hiện đó là **lỗi**
(chung một thư viện `tools/lib/kiem-cheo.sh`, nên hai nơi không lệch nhau):

| Kiểm chéo | Cách kiểm | Xử lý |
|---|---|---|
| Test ↔ YC | Tìm `covers: YC-xxx` trong file khớp `mau_file_test` | Thêm test, hoặc ghi "Kiểm chứng thủ công" + lý do trong `plan.md` |
| Phạm vi diff | File đổi so với merge-base của base trong `intake.md` (kể cả chưa commit, file mới) so với "File dự kiến" + "Phát sinh" + `bo_qua` | Hoàn tác, hoặc ghi vào "Phát sinh" |
| Lỗi thời | `based_on` so với hash hiện tại | Chạy lại phase sinh ra artifact đó |
| Điểm mù | `Mức chặn: chặn review` (hoặc `chặn`) còn `mở` trong `open-questions.md` | Chốt với người qua `/open-questions` |

## Đưa artifact từ ngoài vào

Artifact làm bằng tool khác thường không đúng mẫu. Nó đi qua **bước import có
kiểm soát** — một lệnh riêng, không phải phase:

- Chỉ sắp xếp lại theo mẫu, **không thêm nội dung**.
- Gắn nhãn nguồn trỏ về tài liệu gốc; chỗ không rõ ghi `[CẦN-HỎI]`.
- Kết quả chạy qua checker của phase tương ứng, và người xác nhận bản chuyển đổi.

Với Claude Code: `/import <file-nguồn> <spec.md|tdd.md|plan.md>`. Định nghĩa trung
lập ở `workflow/import.md`.

Entry check của phase N chính là checker của phase N-1 chạy lại trên input, nên
không có đường tắt nào bỏ qua cổng chặn.

## Cài vào một repo

```sh
sh tools/cai-dat.sh /đường/dẫn/repo-của-bạn --lenh-kiem-thu "npm test"
```

Repo đích phải nằm **ngoài** repo agent-workflow: cài vào chính repo này hay bất
kỳ thư mục con nào (vd `adapters/`) đều bị từ chối (`SAI THAM SỐ HOẶC THƯ MỤC ĐÍCH KHÔNG HỢP LỆ`), vì `.claude/` và
`.agent-workflow/` sinh ra sẽ lẫn vào mã nguồn — và Claude Code sẽ nhận nhầm
chúng là lệnh/skill của chính repo này.

Sinh ra trong repo đích:

```
.claude/
  commands/{intake,spec,design,plan,implement,review}.md   ← phase
  commands/{import,open-questions}.md              ← lệnh tiện ích (không phải phase)
  agents/ra-soat-doc-lap.md                        ← rà soát ngữ cảnh sạch
  agents/soat-thiet-ke.md                          ← checker LLM của design
  skills/quy-trinh-agent/SKILL.md
.agent-workflow/
  .quy-trinh/{rules,templates,checkers,tools}      ← bộ cài, cài lại sẽ ghi đè
  .quy-trinh/cau-hinh.sh                           ← LENH_KIEM_THU, LENH_DO_HIEU_NANG (perf), LENH_CHUAN_BI_WT; cài lại không ghi đè
  .quy-trinh/nguon.txt                             ← cài từ repo nào, nhánh nào, commit nào — dong-bo.sh đọc
  conventions.md                                   ← bạn viết; bộ cài chỉ tạo mẫu, KHÔNG BAO GIỜ ghi đè
  <tên-branch>/                                    ← artifact của từng feature, commit vào git
    intake.md, spec.md, open-questions.md, tdd.md, phat-hien-thiet-ke.md,
    plan.md, ket-qua-kiem-thu.md, tai-hien.md (bugfix), do-hieu-nang.md (perf), review.md
```

Rồi sửa `.agent-workflow/conventions.md`, **commit bộ cài vào nhánh gốc** (worktree
chỉ có file đã commit), mở Claude Code ở checkout chính và chạy `/intake` — nó đề
xuất worktree cho việc. Các phase sau chạy trong worktree:
`/intake` → `/spec` → `/design` → `/plan` → `/implement` → `/review`.

Cài lại sau khi sửa quy trình: chạy lại đúng lệnh trên. Adapter **từ chối ghi đè**
file bạn viết tay (file do nó sinh ra đều mang dấu "SINH TỰ ĐỘNG"); dùng `--force`
nếu thật sự muốn mất nội dung cũ. Ngược lại, file mang dấu "SINH TỰ ĐỘNG" mà bản
mới không sinh nữa (vd `/ideation` cũ sau khi đổi thành `/intake`) thì bị **xoá**
khi cài lại — để agent không còn gọi được lệnh cũ với luật cũ.

### Đồng bộ khi repo agent-workflow có bản mới

Bộ cài ghi nguồn của nó vào `.agent-workflow/.quy-trinh/nguon.txt` (URL `origin`
của repo agent-workflow — đã bỏ `user:token` — nhánh, commit). Từ **checkout
chính** của repo đích, đứng ở nhánh gốc:

```sh
sh .agent-workflow/.quy-trinh/tools/dong-bo.sh --kiem-tra   # 0 = mới nhất, 1 = có bản mới
sh .agent-workflow/.quy-trinh/tools/dong-bo.sh              # kéo bản mới + cài lại
```

Script clone nguồn vào thư mục tạm, in các commit mới, rồi chạy `cai-dat.sh`
**của bản mới** vào repo đích — nên mọi luật của cài lại vẫn giữ: `cau-hinh.sh`,
`conventions.md`, file viết tay không bị ghi đè; file trong `.quy-trinh/` mà bản
mới bỏ đi thì bị xoá. Script **không tự commit**: xem diff rồi commit vào nhánh
gốc; worktree đang làm nhận bản mới khi merge nhánh gốc vào.

- Chặn (`BỊ CHẶN`) khi chạy trong worktree, hoặc khi `.quy-trinh/`/`.claude/` có thay
  đổi chưa commit — đè lên thì không còn xem được diff.
- `--nguon <url|thư-mục>` / `--nhanh <tên>`: đổi nguồn hay nhánh theo dõi (được
  ghi lại cho lần sau). Bộ cài cũ chưa có `nguon.txt` thì lần đầu phải truyền `--nguon`.
- `--cai-lai`: cài lại kể cả khi đã ở commit mới nhất.

### Artifact theo feature và `conventions.md`

Artifact của mỗi feature nằm trong `.agent-workflow/<tên-branch>/`, dùng **tên
branch đầy đủ** (vd `feat_tao-todo`) để feat và refactor cùng tên không đè nhau.

Cách xác định feature đang làm:

0. Đang ở checkout chính → `ĐANG Ở CHECKOUT CHÍNH` (worktree là bắt buộc);
1. Suy từ tên branch hiện tại theo quy ước trong `conventions.md`;
2. không khớp thì lấy tham số của lệnh;
3. không có tham số thì dừng lại hỏi.

Agent luôn in `Đang làm với: …` trước khi bắt đầu. Thứ tự này nằm trong script
`tools/xac-dinh-feature.sh` (kết quả `ĐÃ XÁC ĐỊNH`, `CẦN HỎI NGƯỜI` hoặc `ĐANG Ở CHECKOUT CHÍNH`), không nằm trong
prompt — adapter nào cũng dùng chung. Branch có `/` được đổi thành `_`.

`conventions.md` là của repo đích, do bạn viết. Phần máy đọc là một khối
` ```conventions ` gồm các dòng `khoá: giá trị`:

| Khoá | Ví dụ | Dùng cho |
|---|---|---|
| `mau_branch` | `feat_* fix_* refactor_*` | Quy ước tên branch; `xxx` không nhất thiết là mã Jira |
| `nhanh_goc` | `main` | Nhánh checkout chính đứng; ứng viên base chính. Diff so với base trong `intake.md`, chỉ quay về khoá này khi intake chưa có Base |
| `thu_muc_worktree` | `../{repo}.wt/{ten}` | Vị trí worktree (ngoài repo); ghi đè theo máy bằng `AW_THU_MUC_WORKTREE` |
| `mau_nhanh_phat_hanh` | `release/*` | Nhánh phát hành — ứng viên base; base khớp thì review không cảnh báo |
| `bo_qua` | `package-lock.json` | File đổi không cần nằm trong plan |
| `mau_file_test` | `*.test.* test/*` | File nào là test |
| `the_covers` | `covers:` | Tag đứng trước mã YC trong test |
| `loai_theo_tien_to` | `feat_=feature fix_=bugfix` | Tiền tố branch → loại việc (gợi ý ở `/intake`, đối chiếu ở review) |
| `mau_code_production` | `src/*` | Code production — `chore` không được đụng; bugfix/perf đo "trước" khi chưa đụng |
| `mau_file_dependency` | `package.json` | Manifest/lockfile — `chore` đụng vào thì phải khai "Nâng dependency" |

Danh sách cách nhau bằng dấu cách; trong glob, `*` khớp cả `/`.

## Cấu trúc repo

```
workflow.yaml            manifest trung lập — nguồn sự thật duy nhất (phases:, commands:)
workflow/
  phases/*.md            định nghĩa phase (frontmatter + mô tả)
  checkers/*.md          định nghĩa checker LLM (chỉ được chặn)
  import.md              lệnh import artifact từ ngoài (không phải phase)
  open-questions.md      lệnh dẫn người chốt điểm mù theo thứ tự ưu tiên (không phải phase)
  rules/*.md             luật áp dụng cho mọi phase
  templates/*.md         mẫu cho từng artifact + conventions.md
adapters/
  claude-code/build.sh   biên dịch sang .claude/**
tools/
  cai-dat.sh             cài vào repo đích
  dong-bo.sh             repo đích: kéo bản mới của agent-workflow và cài lại
  kiem-tra-*.sh          các cổng chặn bằng máy
  xac-dinh-feature.sh    checkout chính → chặn; branch → tham số → hỏi; in thư mục feature
  kiem-tra-tai-hien.sh   bugfix: ghi bằng chứng test tái hiện đỏ trên code chưa sửa
  kiem-tra-hieu-nang.sh  perf: ghi số đo trước / sau
  doi-ten-feature.sh     đổi tên branch + dời thư mục artifact + dời worktree
  tao-worktree.sh        /intake: đề xuất worktree (tên, vị trí, base) — người chọn base rồi mới tạo
  don-worktree.sh        dọn worktree sau khi merge (không --force, không -D)
  phan-loai-input.sh     /intake: tham số → dòng "## Input" (nhãn do máy gán, gộp khi chạy lại)
  liet-ke-cau-hoi.sh     /open-questions: điểm mù còn mở theo thứ tự phải chốt, mục nào đang chặn
  cap-nhat-based-on.sh   ghi hash đầu vào vào frontmatter artifact
  chay-thu.sh            test hồi quy cho chính các cổng chặn
  lib/md.sh              đọc frontmatter (tập con YAML), conventions, hash
  lib/kiem-cheo.sh       kiểm chéo dùng chung: lỗi thời, test ↔ YC, phạm vi diff, base
  lib/worktree.sh        nhận diện checkout chính / worktree, đường dẫn
docs/kien-truc.md        vì sao thiết kế như vậy, cách thêm phase/adapter
```

## Yêu cầu môi trường

POSIX shell + `awk` + `sed`. Không cần Node, Python, hay cài đặt gì thêm.
Trên Windows dùng Git Bash (Claude Code có sẵn Bash trên mọi nền tảng).

## Vì sao `06-ship` để tuỳ chọn

Nội dung của nó gần như hoàn toàn là đặc thù **hạ tầng CI của từng repo**
(GitHub Actions / GitLab CI / Jenkins), chứ không phải đặc thù agent. Viết chung
thì spec trung lập sẽ đầy nhánh điều kiện cho những hạ tầng chưa biết.

Đây là chỗ tính không-phụ-thuộc-agent yếu nhất trong cả quy trình — đáng thừa
nhận thẳng hơn là che bằng một lớp trừu tượng hoá đoán mò. Thêm sau chỉ cần viết
nội dung `workflow/phases/06-ship.md` và đổi `status` trong manifest; không phase
nào khác phải sửa, vì không phase nào biết gì về phase đứng sau nó.

## Chạy test

```sh
sh tools/chay-thu.sh
```
