# Why verify-before-merge's rules are what they are

Read this when a rule in `verify-before-merge` seems wrong for your case, or
before proposing to change one. Each heading names the rule it explains.

## Dispatch the gate

Test logs, type-checker output and coverage tables displace the plan and the
trace in the dispatcher's context, and none of them has to be in that context
to be evidence. Evidence before assertions still applies: the evidence moves
from the chat log to the log file and the verification record. It does not
become anyone's recollection.

## The log goes outside the tree

Check 7 requires a clean `git status`, and an untracked log fails the gate
that produced it. A test log also quotes item IDs in test names, so a log
under `docs/` is read by the ID and trace checks, where a line shaped like an
item definition becomes a duplicate ID or a dangling reference.

## Check 4 is split

Neither half is the check on its own. The gate subagent can show that every
Implements ID has a `verifies:` test, but it watched nothing fail, so it
cannot attest that each test was red before its implementation existed. Only
the `red -> green:` lines of the dispatch reports state that, and a green run
does not imply it. Re-annotating a test that was green from the start makes
the first half pass with no evidence behind the second.

## Check 4 reads per ID, and an inherited test is named

The check asks whether each Implements ID has red-first evidence, not whether
every test that names it does. One `verifies:` test with a `red -> green:`
line per ID answers it.

A supersession is the one case where a pre-existing green test may gain a new
ID. The test verified the superseded item, which is now out of force, and
`OUT-OF-FORCE-VERIFIES` fails a test that names only out-of-force items. The
author either deletes it or points it at the successor. Pointed at the
successor, it is still coverage worth keeping, but it was never watched
failing against the new behavior. So it is listed as
`inherited: <test name> — from <old ID>` in the dispatch report and the
verification record, and it never stands in for the successor's own red-first
test. Naming it keeps the exception visible: an unlisted green test that
gained an Implements ID is still a re-annotation, and still fails the check.

## Check 8 is the dispatcher's

The tree records no difference between a diff the deslop pass reviewed and a
diff nobody reviewed, so the gate subagent cannot answer the check. The
dispatcher answers it from the pass's report.

## check-review.sh is not a check here

The verification record it reads does not exist yet: `merge-change` step 6b
writes it, after the independent review at 6a, and 6c checks it. Adding it
here would fail every change for a record it is not yet time to write.

## Exit 0 is not a pass

A zero status proves that the runner executed, not that the tests passed.
Storybook-style test runners, some integration harnesses, and anything wrapped
in a script without `set -e` report failures and exit 0, so a zero status is
not a gate result.

## Copy the red -> green lines into the record

The `red -> green:` lines are conversation, and the conversation is not
durable. The verification record keeps the evidence for the failing-test-first
rule after the conversation ends.

## The log is not kept

The log is deleted with the change worktree. The durable evidence is the
verification record `merge-change` step 6b writes: totals, per-command
results, coverage summary, verdict. That is why the record's figures must all
be in the gate summary.
