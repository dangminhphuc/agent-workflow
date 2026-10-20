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
