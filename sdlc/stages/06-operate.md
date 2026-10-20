---
id: operate
purpose: Run the delivered change and feed what production shows back into new work items
requires:
  - delivery
provides:
  - operational-feedback
exit: both
invariants: []
---

# Stage: operate

- `operational-feedback`: incidents, metrics, postmortems that become new work items.
