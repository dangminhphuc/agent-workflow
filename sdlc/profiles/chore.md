---
id: chore
purpose: Change nothing that runs in production (tooling, docs, dependency bumps)
skippable:
  - deploy
skipped:
  - design
adds_provides: []
adds_requires: []
adds_invariants:
  - INV-011
---

# Profile: chore

- `design` never runs; the requirements feed `implement` directly.
- No production code; dependency bumps are declared, and a major bump is a refactor, not a chore.
