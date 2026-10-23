### Bỏ

- `CAP-plan-03` — xếp ưu tiên giữa các việc là việc của người. Engine chỉ nhận việc đã có.
- `CAP-plan-04` — ước lượng công là việc của người, không của engine.
- `CAP-verify-05` — nghiệm thu (UAT) thuộc quy trình của repo đích, không của engine.

### Thay đổi

- Ba capability trên chuyển vào `out_of_scope` của `workflow.yaml`. Bảng "còn thiếu" không còn liệt kê
  chúng; chúng hiện ở mục "Không làm". Trạng thái stage không đổi: `plan` và `verify` vẫn partial.
- `CAP-deploy-03` giữ trên roadmap: engine ghi được đường rollback trong `merge-request.md`.
