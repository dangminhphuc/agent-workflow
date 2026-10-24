### Thêm
- **Nhãn input `[ISSUE]` cho issue / PR / MR của GitHub và GitLab.** `aw input` (`/aw-intake`) gán
  `[ISSUE]` cho URL `github.com/<o>/<r>/issues/N` hay `/pull/N`, URL GitLab `…/-/issues/N` hay
  `…/-/merge_requests/N` (mọi host, cả GitLab tự host), và URL GitHub Enterprise khi host trùng host
  của `origin`. Trước đây các URL này thành `[CONFLUENCE]` khi chưa khai `confluence_domains`.
  `aw check intake` chặn `[ISSUE]` không có URL đúng dạng; `/aw-spec` đọc bằng `gh`/`glab` (hoặc MCP),
  REQ ghi `Source: [ISSUE] <URL>` kèm `Quote:` bắt buộc; `aw check spec` chặn URL sai dạng, thiếu
  câu trích, cảnh báo URL không có trong `## Input`. `aw rule promote` / `aw rule check` nhận nguồn
  `[ISSUE]` (phiên bản lấy ở bảng `## Sources`). Không có khoá `conventions.md` mới; không cần làm gì
  — `intake.md` cũ vẫn hợp lệ. URL issue đang ghi `[CONFLUENCE]` thì có thể đổi tay sang `[ISSUE]`.
  Lưu ý: URL issue/PR/MR trên host có trong `confluence_domains` nay cũng thành `[ISSUE]`, không còn
  `[CONFLUENCE]`.
  Interface: CAP-plan-01 (intake ghi nguồn dạng máy kiểm), CAP-require-01 (REQ truy về nguồn) —
  không đổi interface.
