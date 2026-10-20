---
id: feature
purpose: New or changed externally observable behaviour; the full flow
skippable:
  - deploy
skipped: []
adds_provides: []
adds_requires: []
adds_invariants: []
---

# Profile: feature

- Every stage runs; `deploy` only when the change needs delivering.
- No artifact or invariant beyond the stages.
