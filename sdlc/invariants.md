# SDLC invariants

Rules that hold across stages. Each one names the machine checker that enforces it and the test
that proves the checker blocks. A stage lists the ones it must keep under `invariants:`; a job type
profile (`sdlc/profiles/`) lists the ones only that job type keeps under `adds_invariants:`.

`Tested by:` names a test file, optionally followed by the exact names of its cases in double
quotes: `` `tools/tests/NN-x.sh` "case", "case" ``. Each named case must exist in that file.

### INV-001 — Every task traces to a requirement
- Rule: every task covers an existing REQ; every REQ is covered by a task or deferred.
- Enforced by: `tools/check-plan.sh`
- Tested by: `tools/tests/02-design-plan.sh`

### INV-002 — Every task decision traces to a design decision
- Rule: a task's `Based on: DEC-xxx` names a decision that exists in the design.
- Enforced by: `tools/check-plan.sh`
- Tested by: `tools/tests/02-design-plan.sh`

### INV-003 — Every requirement traces to a test
- Rule: every REQ has a test tagged `covers:` with its id; implement warns, review blocks.
- Enforced by: `tools/lib/cross-check.sh` `tools/check-implement.sh`
- Tested by: `tools/tests/06-review-freshness.sh`

### INV-004 — Every requirement has a review verdict
- Rule: every REQ in the requirements has a valid verdict in the review report.
- Enforced by: `tools/check-review.sh`
- Tested by: `tools/tests/04-review-trace-security.sh`

### INV-005 — The next stage consumes only approved output
- Rule: requirements and each decision carry a human approval whose hash matches the content.
- Enforced by: `tools/check-design.sh` `tools/check-plan.sh` `tools/lib/approval-tick.sh`
- Tested by: `tools/tests/02-design-plan.sh`

### INV-006 — Output is built from the current version of its input
- Rule: an artifact's `based_on` hashes match its inputs; implement warns, review blocks.
- Enforced by: `tools/lib/cross-check.sh` `tools/check-review.sh`
- Tested by: `tools/tests/06-review-freshness.sh`

### INV-007 — Bugfix: the reproduction test fails on the unfixed code
- Rule: the machine runs the reproduction test before any production code changes and records it failing; implement and review block without that record.
- Enforced by: `tools/check-repro.sh` `tools/check-implement.sh` `tools/check-review.sh`
- Tested by: `tools/tests/10-intake-bugfix.sh` "check-repro chặn khi test XANH trên code chưa sửa", "check-repro từ chối khi đã sửa code production", "implement chặn bugfix không có repro.md", "review chặn bugfix không có repro.md"

### INV-008 — Refactor and perf: requirements add no behaviour
- Rule: every REQ is `preserve` or `structural` (perf: also `performance` with a numeric target); a `preserve` REQ is protected by a test that exists on the base branch.
- Enforced by: `tools/check-spec.sh`
- Tested by: `tools/tests/11-design-skip-refactor.sh` "spec refactor chặn REQ không có Loại REQ (hành vi mới)", "spec refactor chặn test bảo vệ không có sẵn trên nhánh gốc"
- Tested by: `tools/tests/12-perf-guard-chore.sh` "spec perf chặn REQ hiệu năng không có số liệu"

### INV-009 — Refactor and perf: existing tests are kept, edits are declared
- Rule: an existing test is never deleted; an edited one is listed in "Modified existing tests"; implement warns, review blocks.
- Enforced by: `tools/lib/cross-check.sh` `tools/check-implement.sh` `tools/check-review.sh`
- Tested by: `tools/tests/11-design-skip-refactor.sh` "implement chặn refactor XOÁ test cũ", "sửa test cũ chưa khai chỉ CẢNH BÁO ở implement", "…nhưng review chặn"

### INV-010 — Perf: before and after numbers are measured by the machine
- Rule: the machine runs the measurement before production code changes and after; implement blocks without the numbers.
- Enforced by: `tools/check-perf.sh` `tools/check-implement.sh`
- Tested by: `tools/tests/12-perf-guard-chore.sh` "perf.md có số đo trước và sau (lệnh đo in KET_QUA: cũ vẫn nhận)", "implement chặn perf không có số đo"

### INV-011 — Chore: no production code, dependency bumps declared, no major bump
- Rule: the diff touches no `production_code`; a changed dependency file has a valid "Dependency upgrades" entry; a major bump is not a chore.
- Enforced by: `tools/lib/cross-check.sh` `tools/check-implement.sh`
- Tested by: `tools/tests/12-perf-guard-chore.sh` "chore đụng code production thì chặn", "chore nâng dependency không khai thì chặn", "nâng major không được là chore"
