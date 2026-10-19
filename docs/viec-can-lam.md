# Việc cần làm — phase 01-spec

> Ghi chú tạm cho người phát triển engine, không phải tài liệu dùng. Việc đã làm xem `CHANGELOG.md`.
> Xoá file này khi các mục dưới đã xong hoặc đã quyết định bỏ.

## Còn lại

### 1. Gợi ý nhãn `Risk` bằng từ khoá

Khoá mới `high_risk_keywords` trong `conventions.md`; spec ghi `Risk: normal` mà chứa từ khoá thì
**cảnh báo** (không chặn — từ khoá hay báo nhầm).

## Ngoài phạm vi (luật mới, cần quyết định độ chặt)

`aw check spec` hiện vẫn **cho qua**: `Source: [JIRA]` không có mã issue; `[INFERRED]` không ghi lý
do; nguồn của YC không có trong `## Input` của `intake.md`.

## Tốc độ test (sau khi chia phần song song)

- **Checker gọi lặp `git rev-parse`.** Một lần `aw check review` chạy ~740 tiến trình, ~125 là
  `git rev-parse --show-toplevel/--git-common-dir` lặp lại (`qu_hieu_luc` gọi trong `$(…)` nên cache
  trong shell không giữ được). Cache theo biến môi trường sẽ nhanh cho cả người dùng lẫn test — đổi code
  engine, cần đề xuất riêng.
- **Ca "…đúng lý do" chạy checker lần hai** (~50 cặp `ky_vong` + `dung … | grep`): gộp được thành một
  lần chạy, bớt ~9% CPU của bộ test.
- **`journal.sh` để sót file tạm `findings.tsv.<pid>`** khi chưa có `findings.tsv` và review không có
  finding (`{ … } > tmp && mv` thất bại vì khối trả mã khác 0).
