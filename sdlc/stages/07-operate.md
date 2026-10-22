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

## Capabilities

### CAP-operate-01 — The delivered change is observed in production
- Rule: metrics, logs and alerts show whether the delivered change behaves as its requirements state.
- Judged by: machine
- Artifact: operational-feedback

### CAP-operate-02 — Incidents and production findings become new work items
- Rule: every incident or production finding about the change becomes a new work item that names it as its source.
- Judged by: human
- Artifact: operational-feedback
