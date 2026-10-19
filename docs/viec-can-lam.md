# Việc cần làm — phase 01-spec

> Ghi chú tạm cho người phát triển engine, không phải tài liệu dùng. Việc đã làm xem `CHANGELOG.md`.
> Xoá file này khi các mục dưới đã xong hoặc đã quyết định bỏ.

## Mã định danh (sau khi đổi sang `REQ`/`DEC`/`FND`/`TSK`/`RFR`)

- **Cấp heading thống nhất** — PR riêng. Mã hiện nằm ở cấp khác nhau: `### REQ` trong `spec.md` nhưng
  `## REQ` trong `open-questions.md`, `## RFR` nhưng `### FND`. Đề xuất: mã luôn ở `###`, dưới một
  `##` của nhóm.
- **`FND` trùng giữa nhiều checker LLM** — chưa xảy ra (mới có checker design). `pending.sh` phải ghép
  tên file (`design-findings.md:FND-001`) để phân biệt. Thêm checker thứ hai thì cần tiền tố/namespace
  riêng hoặc một file findings chung.
- **Chặn mã sai dạng** — checker vẫn nhận `[0-9]+`, `REQ-1` hay `DEC-01` lọt qua. Chính xác nên có thể
  chặn ở checker của phase viết ra mã; cần quyết độ chặt.

## Tốc độ test (sau khi chia phần song song)

- **Checker gọi lặp `git rev-parse`.** Một lần `aw check review` chạy ~740 tiến trình, ~125 là
  `git rev-parse --show-toplevel/--git-common-dir` lặp lại (`qu_hieu_luc` gọi trong `$(…)` nên cache
  trong shell không giữ được). Cache theo biến môi trường sẽ nhanh cho cả người dùng lẫn test — đổi code
  engine, cần đề xuất riêng.
- **Ca "…đúng lý do" chạy checker lần hai** (~50 cặp `ky_vong` + `dung … | grep`): gộp được thành một
  lần chạy, bớt ~9% CPU của bộ test.
- **`journal.sh` để sót file tạm `findings.tsv.<pid>`** khi chưa có `findings.tsv` và review không có
  finding (`{ … } > tmp && mv` thất bại vì khối trả mã khác 0).
