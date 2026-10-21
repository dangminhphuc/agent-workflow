---
id: design
purpose: Choose how to build the requirements; split each choice into a decision the human approves
requires:
  - requirements
  - open-questions
provides:
  - design
exit: both
invariants:
  - INV-005
  - INV-006
---

# Stage: design

- `design`: decisions with options and trade-offs, mapped back to requirements.
- Exit: the human approves every decision before implementation consumes it.

## Capabilities

### CAP-design-01 — Every choice is a decision with options, trade-offs and the requirements it serves
- Rule: every choice someone could make differently is a decision listing its options, trade-offs and the requirements it serves.
- Judged by: machine

### CAP-design-02 — An independent agent looks for hidden decisions and deviations
- Rule: an agent that did not write the design searches it for choices not stated as decisions and for parts that contradict a decision.
- Judged by: agent

### CAP-design-03 — Human approves every decision; approval binds to its content
- Rule: each decision is consumed only after the human approves it, and the approval no longer counts once its content changes.
- Judged by: machine
