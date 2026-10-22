# Spec: SP5 — Capability `out-of-scope`

- Ngày: 2026-10-22 · Branch: `claude/brave-heisenberg-t70jup` (PR #79)
- Roadmap § SP5 · Đảo quyết định "Không có trạng thái `out-of-scope`" ở `docs/kien-truc.md` § Interface SDLC.
- Interface: không đổi `sdlc/` (out-of-scope là lời khai phía implementation).

## 1. Mục tiêu

Roadmap của `check-sdlc.sh` trộn việc engine sẽ làm với việc engine không bao giờ làm (quan sát
production, kiểm tải ngoài job perf…), nên mất giá trị chỉ đường.

**Thành công:** engine khai được capability không làm kèm lý do; roadmap tách hai nhóm; trạng thái
stage **không đổi** cách suy ra (không giấu chỗ thiếu).

## 2. Thiết kế

- Khoá cấp cao mới trong `workflow.yaml`, ngay sau khối `sdlc:`:
  ```yaml
  out_of_scope:
    - CAP-verify-03: E2E chạy trên hệ thống đã ghép là việc của CI/CD của repo, không của engine
  ```
  Dạng `- <CAP-id>: <lý do>` — trong tập con YAML hiện có (như `adds_provides`).
- Danh sách đề xuất (người duyệt spec quyết):
  - `CAP-verify-03` (e2e) — CI/CD của repo đích chạy.
  - `CAP-verify-04` (kiểm tải mọi thay đổi) — hạ tầng đo tải nằm ngoài engine; job `perf` đã có số đo.
  - `CAP-deploy-02` (release / triển khai) — pipeline triển khai của repo đích.
  - `CAP-operate-01` (quan sát production) — hệ thống observability ngoài.
  Giữ trên roadmap: `CAP-plan-03/04`, `CAP-verify-05`, `CAP-deploy-03`, `CAP-operate-02` (engine tạo
  được chỗ ghi / việc mới).
- `check-sdlc.sh` **chặn**: id không có trong `sdlc/stages/`; id có phase nhận
  (`… vừa out-of-scope vừa được phase P nhận — chọn một`); thiếu lý do; id trùng.
- Trạng thái stage, luật `note` giữ nguyên. Roadmap in hai khối:
  `Capability còn thiếu (roadmap — …):` (chỉ capability còn lại) và
  `Không làm (out-of-scope — lý do trong workflow.yaml):` với `CAP-id  Judged-by  lý do`.
  Stage partial/gap mà mọi capability thiếu đều out-of-scope vẫn in dòng stage + note ở khối thứ hai.

## 3. Test (`20-sdlc-conformance.sh`)

Id không có → chặn; id được phase nhận → chặn; thiếu lý do → chặn; trùng → chặn; engine hiện tại:
khối "Không làm" có đúng 4 id; roadmap không còn 4 id đó; trạng thái 8 stage không đổi.

## 4. Tài liệu

`docs/interface-sdlc.md` § 3 (out-of-scope không đổi trạng thái), § 5 (lỗi), § 6 (ảnh chụp);
`docs/kien-truc.md` § Interface SDLC (thay quyết định cũ + lý do mới); `changes/…` (`Nội bộ`).
