# SDLC invariants

Rules that hold across stages. Each one names the machine checker that enforces it and the test
that proves the checker blocks. A stage lists the ones it must keep under `invariants:`; a job type
profile (`sdlc/profiles/`) lists the ones only that job type keeps under `adds_invariants:`.

`Rule:` is abstract: no backticks, no engine identifiers (requirement or decision ids, file names,
field names). How this engine implements the rule goes on the optional `- Engine:` line.

`Tested by:` names a test file followed by the exact names of at least one of its cases in double
quotes: `` `tools/tests/NN-x.sh` "case", "case" ``. Each named case must exist in that file.

### INV-001 — Every task traces to a requirement or a review finding
- Rule: every task covers an existing requirement or fixes a finding of the current review; every requirement is covered by a task or explicitly deferred.
- Engine: task line `Covers: REQ-NNN` or `Fixes: RVW-NNN` (or an MR comment URL); plan section "Deferred".
- Enforced by: `tools/check-plan.sh`
- Tested by: `tools/tests/02-design-plan.sh` "chặn REQ chưa được ánh xạ", "task không Covers, không Fixes → chặn", "Fixes: RVW không có trong review.md → chặn"

### INV-002 — Every task decision traces to a design decision
- Rule: every design decision a task relies on exists in the approved design.
- Engine: task line `Based on: DEC-xxx`.
- Enforced by: `tools/check-plan.sh`
- Tested by: `tools/tests/02-design-plan.sh` "chặn Dựa trên trỏ về DEC không tồn tại"

### INV-003 — Every requirement traces to a test
- Rule: every requirement has a test tagged with its id, or is listed for manual verification with a reason; the implement stage warns, the verify stage blocks.
- Engine: test tag `covers: REQ-NNN`; plan section "Manual verification".
- Enforced by: `tools/lib/cross-check.sh` `tools/check-implement.sh`
- Tested by: `tools/tests/06-review-freshness.sh` "CỔNG CUỐI: chặn REQ chưa có test gắn tag"

### INV-004 — Every requirement has a review verdict
- Rule: every requirement has a valid verdict in the review report.
- Engine: review Lens 1 table, verdict `pass | partial | fail | pending`.
- Enforced by: `tools/check-review.sh`
- Tested by: `tools/tests/04-review-trace-security.sh` "chặn khi bỏ sót một yêu cầu"

### INV-005 — The next stage consumes only approved output
- Rule: the requirements and each design decision carry a human approval bound to a hash of their content.
- Engine: checkbox "Approved by human" with `sha256:` stamp.
- Enforced by: `tools/check-design.sh` `tools/check-plan.sh` `tools/lib/approval-tick.sh`
- Tested by: `tools/tests/02-design-plan.sh` "chặn vào design khi người chưa duyệt spec"

### INV-006 — Output is built from the current version of its input
- Rule: each artifact records hashes of the inputs it was built from, and they match those inputs; the implement stage warns, the verify stage blocks.
- Engine: frontmatter `based_on`, written by `aw based-on`; frontmatter the machine cannot read blocks in every stage (it would silence the hash check); missing inputs warn like stale ones.
- Enforced by: `tools/lib/cross-check.sh` `tools/check-review.sh`
- Tested by: `tools/tests/06-review-freshness.sh` "CỔNG CUỐI: chặn artifact lỗi thời", "chặn based_on viết kiểu [a, b] ở plan", "chặn mục based_on không phải <file>@<số> ở implement", "…review chặn"

### INV-007 — Bugfix: the reproduction test fails on the unfixed code
- Rule: the machine runs the reproduction test before any production code changes and records it failing; the implement and verify stages block without that record. After the fix, verify blocks unless the command recorded as passing is that same command; implement only warns.
- Engine: `repro.md` written by `aw check repro`.
- Enforced by: `tools/check-repro.sh` `tools/check-implement.sh` `tools/check-review.sh`
- Tested by: `tools/tests/10-intake-bugfix.sh` "check-repro chặn khi test XANH trên code chưa sửa", "check-repro từ chối khi đã sửa code production", "implement chặn bugfix không có repro.md", "review chặn bugfix không có repro.md", "implement: lệnh tái hiện khác lệnh đang xanh thì chỉ cảnh báo", "review chặn khi lệnh xanh không phải lệnh đã đỏ"

### INV-008 — Refactor and perf: requirements add no behaviour
- Rule: every requirement preserves or restructures existing behaviour (perf: or states a numeric performance target); preserved behaviour is protected by a test that exists on the base branch.
- Engine: requirement type `preserve | structural | performance`.
- Enforced by: `tools/check-spec.sh`
- Tested by: `tools/tests/11-design-skip-refactor.sh` "spec refactor chặn REQ không có Loại REQ (hành vi mới)", "spec refactor chặn test bảo vệ không có sẵn trên nhánh gốc"
- Tested by: `tools/tests/12-perf-guard-chore.sh` "spec perf chặn REQ hiệu năng không có số liệu"

### INV-009 — Refactor and perf: existing tests are kept, edits are declared
- Rule: an existing test is never deleted; an edited one is declared with a reason; the implement stage warns, the verify stage blocks.
- Engine: plan section "Modified existing tests".
- Enforced by: `tools/lib/cross-check.sh` `tools/check-implement.sh` `tools/check-review.sh`
- Tested by: `tools/tests/11-design-skip-refactor.sh` "implement chặn refactor XOÁ test cũ", "sửa test cũ chưa khai chỉ CẢNH BÁO ở implement", "…nhưng review chặn"

### INV-010 — Perf: before and after numbers are measured by the machine
- Rule: the machine runs the measurement before production code changes and after; the implement stage blocks without the numbers.
- Engine: `perf.md` written by `aw check perf`.
- Enforced by: `tools/check-perf.sh` `tools/check-implement.sh`
- Tested by: `tools/tests/12-perf-guard-chore.sh` "perf.md có số đo trước và sau (lệnh đo in KET_QUA: cũ vẫn nhận)", "implement chặn perf không có số đo"

### INV-011 — Chore: no production code, dependency bumps declared, no major bump
- Rule: the change touches no production code; every changed dependency is declared with its old and new version; a major version bump is not a chore.
- Engine: conventions key `production_code`; plan section "Dependency upgrades".
- Enforced by: `tools/lib/cross-check.sh` `tools/check-implement.sh`
- Tested by: `tools/tests/12-perf-guard-chore.sh` "chore đụng code production thì chặn", "chore nâng dependency không khai thì chặn", "nâng major không được là chore"

### INV-012 — The machine keeps a pointer to another document's section correct
- Rule: a document that points at a section of another document points at a section that exists; when that section is renamed the tool repairs the pointer, and a pointer the tool cannot safely repair is reported — with its location, why it was left alone, and the form that would be correct — all faults in one pass, so one repair round is enough.
- Engine: `tools/lib/toc.sh` — `aw toc` sinh `## Contents`, mở rộng anchor rút gọn và mở rộng lại anchor theo mã của mục khi heading đổi chữ; mã chỉ nhiều hơn một mục thì không đoán. Lỗi còn lại in kèm file, số dòng và dạng đúng.
- Enforced by: `tools/lib/toc.sh` `tools/check-spec.sh` `tools/check-review.sh`
- Tested by: `tools/tests/01-fixture-engine-toc.sh` "heading đổi → aw toc một lượt, ĐÃ KHỚP", "link trong cùng file cũng được sửa, một lượt", "link tới mã không có → còn chặn sau một lượt aw toc", "chỗ giữ chỗ chưa điền → lỗi nêu rõ là chỗ giữ chỗ", "mã khớp hai heading → vẫn chặn sau một lượt", "…nêu rõ có hai mục mang mã đó", "…không nói sai là không có heading nào", "hai lỗi dạng ở hai file → in hết một lượt"
