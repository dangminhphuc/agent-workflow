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

## Capabilities

### CAP-require-01 — Each requirement traces to a source and has observable acceptance criteria
- Rule: every requirement names the source it comes from and has acceptance criteria that an observer can check.
- Judged by: machine
- Artifact: requirements

### CAP-require-02 — Each open question carries an assumption and a blocking level
- Rule: every open question states the assumption taken meanwhile and how much it blocks later stages.
- Judged by: machine
- Artifact: open-questions

### CAP-require-03 — Human approves the requirements; approval binds to their content
- Rule: requirements are consumed only after the human approves them, and the approval no longer counts once their content changes.
- Judged by: machine
- Artifact: requirements
