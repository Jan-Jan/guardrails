---
name: review-guidelines
description: Review a change diff against one project guidelines file (such as docs/TEST_GUIDELINES.md) in a fresh context, citing a clause for every finding. Dispatched by develop-change after the deslop pass, once per guidelines file that governs the diff.
---

# Review Guidelines

**Announce at start:** "Using the review-guidelines skill against <file>."

## Preconditions

- You were dispatched with exactly one guidelines file, the paths it governs
  and a diff range. One dispatch reviews one file; a second file is a second
  dispatch.
- You have no implementation narrative: no plan, no dispatch reports, no
  account of why the code is the way it is. The diff and the file are the
  whole case.
- Read the guidelines file and the diff, nothing else of the project's
  guidance: not another guidelines file, not the installed default, not a unit's
  file or the root's in its place. The file you were handed stands alone.

## Steps

1. **Check every changed line under the governed paths against every
   clause.** Restrict the diff to those paths
   (`git diff <range> -- <path>...`). A clause with no changed line it
   applies to needs nothing; a clause that applies is checked on every line it
   applies to, not on a sample.
2. **Write each finding in one shape:**

   ```
   **finding-N**: guideline, <low | medium | high> — <clause cited as Heading N, quoted> — <file:line>
   ```

   Number findings from 1 in the report. Cite the clause by its heading and
   number and quote the words the diff breaks. Severity is as `merge-change`'s
   review checklist defines it: `high` loses work or makes a gate pass that
   should fail in normal use; `medium` misleads in normal use or leaves a
   stated rule unmet; `low` needs a rare or contrived state, or is a gap where
   the code is right.
3. **Report a clause that contradicts the floor as a finding against the clause**,
   cited at the clause's own line in the guidelines file. The floor wins, and
   a change that obeys such a clause against the floor is also a finding. The
   floor, in full:
   - every test carries `verifies:`;
   - every new test was watched red;
   - every test fails when the behavior it `verifies:` breaks, so an assertion
     only that a double was called meets it only where the call is the
     requirement;
   - class B and C: abnormal-input tests for every REQ and LLR;
   - class C: tests at every touched SDD item's interface.
4. **Report a clause that no longer stands as written**, each as a finding
   against the clause:
   - a clause whose reason no longer fits its rule, because the rule was
     changed and the reason kept;
   - a clause that refers to another guidelines file or to a document the project does not contain,
     since the reader cannot apply a rule it cannot open.
5. **What the file does not state is a `note:`, never a finding.** A note
   may say what you would have flagged and why; it blocks nothing.
6. **End with `verdict: <one line>`**: the count of findings by severity and
   whether any is above `low`.

## Red flags

| Thought | Reality |
|---|---|
| "This is bad but the file doesn't say so" | A note, not a finding. |
| "The clause seems wrong here, I'll let it go" | A finding against the clause. Never a silent waiver. |
| "I'll read the installed default for context" | You read one file. |
| "The floor is someone else's review" | A clause that contradicts it is yours to report. |
| "This finding is obvious, the clause need not be cited" | A finding with no clause is a note. |

## Done when

- Every clause was checked against the governed diff.
- Every finding cites a clause, by heading and number, quoted.
- The report ends with a verdict line.
