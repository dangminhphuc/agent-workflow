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
exit: machine
invariants:
  - INV-001
  - INV-002
  - INV-003
---

# Stage: implement

- `task-plan`: ordered tasks, each covering requirements and based on approved decisions.
- `change`: the code change.
- `test-evidence`: test results recorded by the machine, bound to the code they ran on.
- Exit: machine checks only — this stage executes what the human already approved.
