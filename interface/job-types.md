# Job types

Loại việc quyết định một việc đi qua stage nào và cần bảo đảm thêm gì, để độ chặt tỉ lệ với rủi ro. Loại việc
được chọn ở `plan` (ghi trong `work-item`). Bảng chỉ ghi chỗ lệch: stage không ghi ở cột Optional hay Skipped
thì luôn chạy.

- **Optional** — stage được bỏ, khi người duyệt duyệt việc bỏ (`INV-013`).
- **Skipped** — stage không bao giờ chạy với loại việc này.

Stage thực sự bị bỏ thì artifact của nó vắng; Input có Required yes lấy từ stage đó được phép vắng — chỉ khi stage đó đã bị bỏ.

**Mã production** — phần mã chạy ở nơi phát hành, khác mã test, công cụ, tài liệu. Phần nào là mã production do người
duyệt khai (khai ở đâu thuộc cách agent làm việc, ngoài interface).
Luật riêng của từng loại là invariant có trường Only for trong invariants.md.

## Job types
| Job type   | Definition | Optional | Skipped |
|------------|------------|----------|---------|
| `feature`  | Thêm hay đổi hành vi mà người dùng hay hệ thống bên ngoài thấy được. Khác `bugfix`: hành vi đích chưa có trong tài liệu, yêu cầu đã duyệt, hay phiên bản trước. | — | — |
| `bugfix`   | Hành vi hiện tại sai so với tài liệu, yêu cầu đã duyệt trước đây, hay phiên bản trước (lỗi hồi quy); sửa cho đúng. Khác `feature`: hành vi đúng đã được định nghĩa từ trước, việc này không thêm hành vi mới. | design | — |
| `refactor` | Đổi cấu trúc mã mà không đổi hành vi bên ngoài thấy được. Khác `perf`: không có mục tiêu hiệu năng bằng số. | design | — |
| `perf`     | Giữ nguyên hành vi, giảm thời gian hay tài nguyên theo một mục tiêu bằng số. Khác `refactor`: có mục tiêu đo được, và số đo trước, sau. Khác `bugfix`: không có mục tiêu đã ghi nào đang bị vi phạm — vi phạm một mục tiêu đã ghi là `bugfix`. | — | — |
| `chore`    | Không đụng mã production: công cụ, tài liệu, mã test, nâng phiên bản thư viện mà không phải sửa mã production (khai báo phiên bản thư viện không tính là mã production). Khác `refactor`: đổi cấu trúc mã test hay công cụ là `chore`; nâng thư viện mà phải sửa mã production thì là `refactor` (hành vi không đổi), hoặc `feature`/`bugfix`. | — | design |

## Added artifacts
Artifact thêm của job type đều do máy ghi, Approval `no`.

| Job type | Artifact              | Produced by | Consumed by | Description |
|----------|-----------------------|-------------|-------------|-------------|
| `bugfix` | reproduction-evidence | implement   | verify      | một test tái hiện lỗi: máy chạy nó trên mã chưa sửa và ghi không đạt, rồi chạy cùng test đó trên thay đổi và ghi đạt (`INV-008`) |
| `perf`   | performance-evidence  | implement   | verify      | số đo trên điểm xuất phát và trên thay đổi, cùng một cách đo, do máy chạy và ghi (`INV-011`) |

## Why
- `feature`: luồng đầy đủ; không thêm gì ngoài các stage.
- `bugfix`: test đỏ trên mã chưa sửa là bằng chứng duy nhất rằng test bắt đúng lỗi, không phải một test luôn đạt; `design` được phép bỏ (người duyệt duyệt việc bỏ) vì bản sửa nhỏ thường không có lựa chọn nào đáng thành quyết định.
- `refactor`: không có hành vi mới thì test có sẵn là thứ bảo vệ hành vi cũ — xoá nó là mất chính thứ chứng minh việc không đổi hành vi.
- `perf`: như `refactor`, cộng mục tiêu bằng số; `design` luôn chạy vì cách tối ưu thường là lựa chọn có đánh đổi.
- `chore`: không đụng mã production nên không có gì để thiết kế; luật chặn mã production giữ cho loại việc nhẹ nhất không thành lối tắt.
- Không loại nào bỏ `deploy`: merge nằm ở đó; việc không cần phát hành ghi "không phát hành" ở `deploy`.
