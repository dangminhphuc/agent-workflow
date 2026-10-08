# AGENTS.md — phát triển repo agent-workflow

Repo này là **engine** (wrapper `aw` + checker + định nghĩa phase + adapter). Đây không phải repo
dự án chạy quy trình. Hướng dẫn dùng: `README.md`. Lý do thiết kế: `docs/kien-truc.md`.

## Bản đồ

```
workflow.yaml            manifest — nguồn sự thật (phases:, commands:, rules:, adapters:)
workflow/phases/*.md     định nghĩa phase: frontmatter (hợp đồng) + thân (chỉ thị cho agent)
workflow/{clarify,import}.md   lệnh tiện ích (không phải phase)
workflow/checkers/*.md   checker LLM (chỉ được chặn)
workflow/rules/*.md      luật chung — agent đọc lúc chạy
workflow/templates/      mẫu artifact (người đọc), conventions.md, config.sh, conventions-reference.md
bin/aw                   wrapper cài global: chọn version, tải + kiểm sha256
bin/aw-engine            điểm vào engine: init, check, worktree, adapter, feature…
adapters/lib/chung.sh    bộ sinh dùng chung (ad_sinh); adapters/<id>/build.sh chỉ khai hook
tools/kiem-tra-*.sh      checker máy (`aw check <tên>`); tên đăng ký ở tools/lib/bang-lenh.sh
tools/*.sh               lệnh khác của aw (worktree, task, ship, journal, approval, guard…)
tools/lib/               md.sh (YAML con, conventions), kiem-cheo.sh, duyet.sh, task.sh, ket-qua.sh…
tools/chay-thu.sh        toàn bộ test hồi quy (~1000 ca, ~4 phút)
```

## Ngôn ngữ

- Nội dung **agent đọc lúc chạy** (`workflow/phases`, `clarify.md`, `import.md`, `rules/`,
  `checkers/`, chữ do adapter sinh): tiếng Anh, ngắn, chỉ chỉ thị.
- Nội dung **người đọc** (README, docs, CHANGELOG, mẫu artifact, output của `aw`, nhãn `Kết quả`):
  tiếng Việt. Artifact agent viết ra: tiếng Việt.
- Heading/tên trường/giá trị cố định trong mẫu (`## Out of scope`, `Blocking`, `must`…): tiếng
  Anh, checker đọc đúng chữ — đổi là phải đổi checker + test.
- **Bắt buộc:** mọi mẫu (`workflow/templates/`) và artifact do agent tạo/sửa — kể cả heading, tên
  trường, từ khoá, giá trị enum mà mẫu chưa có — phải là **tiếng Anh**. Tiếng Việt chỉ ở nội dung
  dưới heading và placeholder (`<tiêu đề>`). Không dịch heading/từ khoá tiếng Anh sẵn có. Luật cho
  agent lúc chạy: `workflow/rules/nguyen-tac-chung.md` §5.
- Tên hàm/biến shell: tiếng Việt không dấu (`kq_khai`, `ghi_file`), giữ theo code xung quanh.

## Quy ước code

- **POSIX sh + awk + sed + git.** Không bash-ism, không Node/Python, không jq. Regex ERE, không
  `{n}` (mawk). awk đọc nhiều file: `FILENAME == ARGV[i]`, không `FNR==1`.
- Mọi script khai nhãn kết quả bằng `kq_khai` (`tools/lib/ket-qua.sh`), in khối `Kết quả` ra stderr.
  Prompt/tài liệu nói theo **nhãn**, không theo mã thoát.
- Tool đọc đường dẫn repo/cấu hình **chỉ** từ `AW_REPO`, `AW_CONFIG` (`tools/lib/moi-truong.sh`).
- Adapter build chạy `set -e`: `[ … ] && printf` ở cuối khối/vòng lặp sẽ giết pipeline — dùng `if`.
- Chữ riêng của một agent chỉ nằm trong hook adapter; test đối chiếu (`AW_DOI_CHIEU=1`) đòi output
  mọi adapter giống hệt nhau.
- Luật mới: checker chính xác thì chặn; kiểm chéo/hay báo nhầm thì cảnh báo ở implement, chặn ở
  review. Lý do ghi vào `docs/kien-truc.md`, không vào file phase.
- Mỗi luật ở một chỗ. File phase không lặp lại hợp đồng vào/ra (adapter dựng từ frontmatter) hay
  danh sách điều checker kiểm.

## Kiểm

```sh
sh tools/chay-thu.sh                     # phải ra [x] MỌI CA ĐẠT
sh adapters/claude-code/build.sh --out <thư-mục-git-tạm>   # xem lệnh sinh ra
```

Test viết bằng `ky_vong <mã> "<tên>" <lệnh>` và `dung "<tên>" <phép-thử>`; mỗi checker kiểm cả hai
chiều (chặn đúng lúc, cho qua đúng lúc). Đổi chữ mà test grep → sửa test cùng commit.

## Phát hành

1. Ghi thay đổi vào `## [Chưa phát hành]` của `CHANGELOG.md` (tiếng Việt).
2. `sh tools/chuan-bi-phat-hanh.sh` — đặt `YYYY.M.N` vào VERSION, `bin/aw`, CHANGELOG, README.
3. PR vào `main`; CI `kiem-tra` chạy test + kiểm version. Merge → workflow `release` tự tạo tag +
   Release. **Không tự tạo tag tay** trước khi merge.
