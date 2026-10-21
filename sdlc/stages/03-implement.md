---
id: implement
purpose: Build the approved design in small ordered tasks, each done only when its tests pass
requires:
  - requirements
  - design
provides:
  - task-plan
  - change
  - test-evidence
  - task-evidence
  - security-evidence
exit: machine
skippable: false
invariants:
  - INV-001
  - INV-002
  - INV-003
---

# Stage: implement

- `task-plan`: ordered tasks, each covering requirements and based on approved decisions.
- `change`: the code change.
- `test-evidence`: test results recorded by the machine, bound to the code they ran on.
- `task-evidence`: per task, the result of its verification step, recorded by the machine.
- `security-evidence`: security scan results recorded by the machine, bound to the code they ran on.
- Exit: machine checks only — this stage executes what the human already approved.

## Capabilities

### CAP-implement-01 — Ordered tasks, each tracing to requirements and approved decisions
- Rule: the work is split into ordered tasks; each task covers requirements and is based only on approved decisions.
- Judged by: machine

### CAP-implement-02 — Tests are run by the machine; results are bound to the code they ran on
- Rule: test results are recorded by the machine, not reported by the agent, and name the code version they ran on.
- Judged by: machine

### CAP-implement-03 — The change is scanned for security issues before it leaves the stage
- Rule: the machine scans the change for security issues and the stage cannot exit while the scan fails.
- Judged by: machine
