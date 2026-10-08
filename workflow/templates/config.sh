# Cấu hình của bản clone này cho agent-workflow.
# Nằm ở $(git rev-parse --git-common-dir)/agent-workflow/ — KHÔNG commit, dùng chung
# mọi worktree. Do NGƯỜI sửa; aw init / aw upgrade không ghi đè.

# Adapter sinh lệnh cho agent team dùng — một hoặc nhiều id, cách nhau dấu cách:
#   ADAPTER="claude-code"            chỉ Claude Code (.claude/)
#   ADAPTER="claude-code cursor"     cả hai — mỗi worktree có cả .claude/ lẫn .cursor/
# Sửa xong thì chạy aw init (thêm exclude) rồi aw adapter build ở checkout chính.
ADAPTER="claude-code"

# Lệnh kiểm thử — điều kiện ra của phase 04-implement.
# Bỏ trống thì phase implement sẽ KHÔNG ĐẠT, không phải "bỏ qua".
# Nên trỏ tới lệnh ĐÃ COMMIT mà CI cũng chạy, vd TEST_CMD="make test" — lệnh thật
# nằm trong git, sửa một chỗ là local và CI cùng đổi. Mẫu Makefile:
# .agent-workflow/.engine/templates/target-repo/Makefile
TEST_CMD=""

# Lệnh quét bảo mật — cũng là điều kiện ra của 04-implement; 05-review chặn khi
# kết quả không xanh hoặc code đã đổi sau lần quét.
# Bỏ trống thì phase implement sẽ KHÔNG ĐẠT, không phải "bỏ qua".
#
# Khai ĐÚNG lệnh, file config, ngưỡng mà pipeline CI/CD đang chạy — chép từ file
# pipeline (.gitlab-ci.yml, .github/workflows/…). Lệch CI (khác rule, khác ngưỡng)
# thì local đạt mà pipeline vẫn chặn release — đúng lỗi gate này sinh ra để chặn.
#
# Mỗi dòng "<nhóm>: <lệnh>", nhóm ∈ secret | sast | sca | other. Lệnh chạy ở gốc
# repo; mã thoát khác 0 = ĐỎ, nên lệnh phải tự thoát khác 0 khi vượt ngưỡng.
# Báo cáo (json, sarif…) ghi ra ngoài repo hoặc vào chỗ .gitignore — file lạ trong
# repo làm kết quả bị coi là lỗi thời. Dòng trống và dòng bắt đầu bằng # bỏ qua.
# Nên khai qua target đã commit mà CI cũng gọi (mẫu Makefile ở trên):
#
# SECURITY_CMDS="
# secret: make security-secret
# sast: make security-sast
# sca: make security-sca
# "
#
# Hoặc chép thẳng lệnh từ pipeline (sửa theo pipeline của bạn):
#
# SECURITY_CMDS="
# secret: gitleaks detect --no-banner --redact --exit-code 1 --config .gitleaks.toml
# sast: semgrep scan --config p/ci --error --metrics off
# sast: sonar-scanner -Dsonar.qualitygate.wait=true
# sca: trivy fs --scanners vuln,license --severity HIGH,CRITICAL --exit-code 1 .
# sca: npm audit --omit=dev --audit-level=high
# "
#
# SonarQube cần server và token (SONAR_HOST_URL, SONAR_TOKEN). Máy dev không chạy
# được thì để dòng đó thành comment KÈM LÝ DO — người chấp nhận rằng quality gate
# của Sonar chỉ chặn ở CI.
SECURITY_CMDS=""

# Số lần một task được đỏ liên tiếp (aw task done) trước khi máy báo DỪNG — lặp
# tiếp là đoán mò; agent ghi "Unplanned" và báo người. Bỏ trống = 3.
MAX_RED_RUNS=""

# Lệnh đo hiệu năng — chỉ dùng cho loại việc perf. Phải in một dòng
# "RESULT: <số> <đơn vị>", vd: RESULT: 138 ms
PERF_CMD=""

# Lệnh chuẩn bị worktree mới (cài dependency…) — aw worktree IN RA cho người
# chạy, không tự chạy. Worktree mới chỉ có file đã commit: không có
# node_modules, .env… Vd: WORKTREE_SETUP_CMD="npm ci"
WORKTREE_SETUP_CMD=""
