---
id: verify
purpose: Independently check the change against requirements, design and plan before it ships
requires:
  - requirements
  - design
  - task-plan
  - change
  - test-evidence
provides:
  - review-report
exit: both
skippable: false
invariants:
  - INV-004
  - INV-006
---

# Stage: verify

- `review-report`: a verdict per requirement, findings by severity, a merge verdict.
- Run by an agent that did not build the change.
- Exit: the human confirms the verdict.

## Capabilities

### CAP-verify-01 — An agent that did not build the change gives a verdict per requirement
- Rule: an agent with a clean context, that did not build the change, gives a verdict for every requirement and a merge verdict.
- Judged by: agent

### CAP-verify-02 — A human security reviewer reads changes to sensitive code
- Rule: a change that touches code declared sensitive is read by a named human security reviewer before it ships.
- Judged by: human

### CAP-verify-03 — End-to-end tests run against the integrated system
- Rule: end-to-end tests run against the integrated system and their results are recorded by the machine.
- Judged by: machine

### CAP-verify-04 — Load and performance are tested beyond perf jobs
- Rule: every change that can affect load or latency is measured against a stated target, whatever the job type.
- Judged by: machine

### CAP-verify-05 — Stakeholders accept the change (UAT)
- Rule: the people who asked for the change accept it against the requirements before it ships.
- Judged by: human
