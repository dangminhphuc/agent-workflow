---
id: implement
purpose: Build the change task by task, in plan order, each task done only when its tests pass
requires:
  - requirements
  - design
  - task-plan
provides:
  - change
  - test-evidence
  - task-evidence
  - security-evidence
exit: machine
skippable: false
invariants:
  - INV-003
---

# Stage: implement

- `change`: the code change.
- `test-evidence`: test results recorded by the machine, bound to the code they ran on.
- `task-evidence`: per task, the result of its verification step, recorded by the machine.
- `security-evidence`: security scan results recorded by the machine, bound to the code they ran on.
- Exit: machine checks only — this stage executes the approved task plan.

## Capabilities

### CAP-implement-02 — Tests are run by the machine; results are bound to the code they ran on
- Rule: test results are recorded by the machine, not reported by the agent, and name the code version they ran on.
- Judged by: machine

### CAP-implement-03 — The change is scanned for security issues before it leaves the stage
- Rule: the machine scans the change for security issues and the stage cannot exit while the scan fails.
- Judged by: machine
