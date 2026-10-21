---
id: deploy
purpose: Deliver the verified change to its target
requires:
  - change
  - review-report
provides:
  - delivery
exit: both
invariants: []
---

# Stage: deploy

- `delivery`: record of what was delivered, where, and how to roll it back.
- Exit: the human merges or releases; the agent never does.

## Capabilities

### CAP-deploy-01 — Change is delivered as a reviewed MR/PR that only a human merges
- Rule: the change reaches its target branch through a merge request that the human reviews and merges; the agent never merges.
- Judged by: human

### CAP-deploy-02 — Change is released or deployed to its target environment
- Rule: the merged change is released or deployed to its target environment, and the machine records what was delivered where.
- Judged by: machine

### CAP-deploy-03 — Rollback path is recorded before delivery
- Rule: the delivery record states how to undo the change, and the human confirms it before release.
- Judged by: human
