---
id: bugfix
purpose: Current behaviour is wrong against its documentation or intent; make it right
skippable:
  - design
  - deploy
skipped: []
adds_provides:
  - implement: reproduction-evidence
adds_requires:
  - verify: reproduction-evidence
adds_invariants:
  - INV-007
---

# Profile: bugfix

- `design` may be skipped for a small, normal-risk fix; the requirements then feed `implement` directly.
- `reproduction-evidence`: a test that reproduces the bug, run by the machine on the unfixed code, failing.
- `verify` reads it and states why the test fails — because of the bug, not a build error.
