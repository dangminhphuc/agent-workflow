---
id: refactor
purpose: Change structure without changing externally observable behaviour
skippable:
  - design
  - deploy
skipped: []
adds_provides: []
adds_requires: []
adds_invariants:
  - INV-008
  - INV-009
---

# Profile: refactor

- `design` may be skipped for a small, normal-risk refactor.
- Requirements only preserve or restructure behaviour; preserved behaviour is protected by a test that exists before the change.
- Existing tests stay; any edit to one is declared, and `verify` checks it changes no assertion.
