---
id: require
purpose: Turn the work item into verifiable requirements and list what the sources leave open
requires:
  - work-item
provides:
  - requirements
  - open-questions
exit: both
skippable: false
invariants:
  - INV-005
---

# Stage: require

- `requirements`: each one traceable to a source, with observable acceptance criteria.
- `open-questions`: what the sources do not say; each carries an assumption and a blocking level.
- No technical solution in this stage.
- Exit: the human approves the requirements before design consumes them.
