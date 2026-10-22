---
id: breakdown
purpose: Split the approved design into small ordered tasks, each tracing to requirements and decisions
requires:
  - requirements
  - design
provides:
  - task-plan
exit: machine
skippable: false
invariants:
  - INV-001
  - INV-002
---

# Stage: breakdown

- `task-plan`: ordered tasks, each covering requirements and based on approved decisions; each names the files it may touch and how it is proven done.
- No code in this stage.
- Exit: machine checks only — the plan uses only what the human already approved.

## Capabilities

### CAP-breakdown-01 — Ordered tasks, each tracing to requirements and approved decisions
- Rule: the work is split into ordered tasks; each task covers requirements and is based only on approved decisions.
- Judged by: machine

### CAP-breakdown-02 — Each task names the files it may change and how it is proven done
- Rule: every task lists the files it may change and a verification step; neither may be empty or a placeholder.
- Judged by: machine
- Artifact: task-plan
