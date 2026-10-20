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
invariants:
  - INV-004
  - INV-006
---

# Stage: verify

- `review-report`: a verdict per requirement, findings by severity, a merge verdict.
- Run by an agent that did not build the change.
- Exit: the human confirms the verdict.
