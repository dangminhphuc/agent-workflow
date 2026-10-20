# SDLC invariants

Rules that hold across stages. Each one names the machine checker that enforces it and the test
that proves the checker blocks. A stage lists the ones it must keep under `invariants:`.

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
