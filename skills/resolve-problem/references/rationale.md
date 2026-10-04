# Why resolve-problem's rules are what they are

Read this when a rule in `resolve-problem` seems wrong for your case, or before
proposing to change one. Each heading names the step or rule it explains.

## The workflow as a whole

Every bug is a change-control event, not a quick fix. In a regulated project
the record of what went wrong and what was done about it matters as much as
the fix (IEC 62304 problem resolution; DO-178C §7.2.8 problem reports).

## Step 1: record first

If the investigation does not find the cause, the open PR item remains and
appears at every merge as an `UNRESOLVED-PR` warning with its age. A problem
that was never recorded appears nowhere.

## Step 1: the indented item form

The item forms in the skill are indented and use `NNNNNN`, for the two reasons
the ledger READMEs give. A real ID in the skill is a reference to an item that
does not exist, and a definition form at column one is judged wherever it
appears, in a fenced block too.

## Step 1: `opened:`

The date exists so the open list can be triaged rather than scrolled past:
without an age, nothing can go stale.

The one day of tolerance exists because "today" differs by a day across
timezones. Without it, an author ahead of the checking machine's timezone fails
the check on a correct item on the day they record it. One day cannot make a
stale item look fresh against limits measured in weeks.

## Step 1: no owner field

`git blame` on the ledger line already answers who wrote the item, and problems
are not personally owned: anyone may resolve them.

## Step 4: `status: accepted`

A problem that was investigated and deliberately not fixed is not the same as
a problem nobody has got to. `accepted` records that distinction: the item is
decided, not forgotten.

An accepted item stops aging because neither `problem_age_days` nor
`problem_open_max` measures anything about a decision. A project that triages
honestly should not reach the ceiling faster than one that drops items without
a record.

It is still printed at every run, so the decision is shown again to every
author who runs the check.

## Step 4: `disposition:` is required

Without the requirement, `accepted` is a one-word exemption from both limits,
reachable by an author looking at a red `PROBLEM-BACKLOG`, and the gate would
ship its own bypass. Rejecting `accepted` without a `disposition:` makes the
status safe: the ruling is the cost of the exemption.

## Step 4: `accepted` is a resolution outcome

IEC 62304 6.2 treats a documented decision not to change the software as a
resolution outcome in its own right, so `accepted` is a closed state with a
reason, distinct from `resolved`, which requires the fix in the merging change.
