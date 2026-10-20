---
id: perf
purpose: Same behaviour, fewer resources or less time
skippable:
  - deploy
skipped: []
adds_provides:
  - implement: performance-evidence
adds_requires:
  - verify: performance-evidence
adds_invariants:
  - INV-008
  - INV-009
  - INV-010
---

# Profile: perf

- Like refactor, plus a performance requirement with a numeric target; `design` always runs.
- `performance-evidence`: measurements before and after the change, taken and recorded by the machine.
- `verify` judges the performance requirement from those numbers, allowing for noise.
