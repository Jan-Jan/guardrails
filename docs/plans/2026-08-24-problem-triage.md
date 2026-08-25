# Problem-Report Triage Implementation Plan

**Goal:** Make the open-problem roll-call trustworthy and give it teeth — every
open PR item carries an owner and an opened date, and configured age/count
limits fail the check instead of printing another warning nobody reads.
**Implements:** no requirement items exist in this repository yet (tooth 3 of
the ratchet gap analysis). Traced to practice-feedback finding 09a.
**Safety class:** the toolkit itself is unclassified; it enforces class B/C
projects. Treat every gate change as class B — normal-case and abnormal-input
tests for each new behaviour.
**Verification:** `sh tests/run-tests.sh` (bats), plus a corpus differential
against `sightings-app`.

---

## The finding, and what it actually asks for

> **Warning fatigue.** `UNRESOLVED-PR` prints at every merge. With 136 items
> recorded and 15 open, that block has become something to scroll past — the
> exact opposite of its purpose. Items carry no owner, no age, and no severity,
> so there is nothing to triage on even if someone wanted to.
>
> **Recommendation.** Add `owner:` and `opened:` to problem items, and fail
> rather than warn above an age or count threshold — a warning nobody acts on
> is worse than no warning, because it teaches people the output is noise.

Three distinct things, and the third is not in the finding's text:

1. **Triage data** on the roll-call line — who owns it, how old it is.
2. **Enforcement** — configured limits that fail rather than warn.
3. **A roll-call that is actually complete.** Discovered while reading the
   current parser: it is not. See D1. There is no point pricing the warning
   higher if items are missing from it.

## Decisions

### D1 — the `status:` reader and the ORPHAN-ANNOTATION backstop disagree

Current:

```awk
cur != "" && /status:[ \t]*open/ { open = 1 }
```

Unanchored, matched anywhere in the line, and — this is the part that
matters — **the backstop cannot see what it reads**. `check_orphans` reports
a `status:` line only at **column one**. So a `status:` occurrence mid-line
is read by the gate and is invisible to the gate that exists to catch
annotations belonging to no item. ORPHAN-ANNOTATION was built precisely to
backstop the block rule; a reader that looks where the backstop does not
reopens the hole it closed.

The consequences, in the order they cost something:

* **An item whose `status:` line the pattern does not match reads as
  resolved and vanishes from the roll-call.** `Status: open`, `status : open`
  and *no `status:` line at all* all produce the same result: an open problem
  no merge ever sees. Read, not matched, dropped in silence, exit 0 — this
  toolkit's defining defect, inside the gate whose job is to make open
  problems visible.
* Prose inside a PR block containing `status: open` sets the flag for the
  item above it.
* `status: opened by jvdv` reads as open by accident rather than by rule.

**Measured, not hypothesised.** Against `sightings-app @ f1fd8d26`, by
running the gate rather than by grepping (the first attempt grepped, and
undercounted by two — a file's *references* to an item cancelled against its
missing `status:` lines):

```
PR items enumerated ................. 163
items with no readable status: ......   3   (PR-028, PR-070, PR-122)
open items on the roll-call .........  48
distinct status: values ............. resolved, open  (nothing else)
items carrying owner: or opened: ....   0
```

All three have been read as **resolved** since the day they were written, and
each is a different shape of the same defect:

* **PR-028** records its state in prose bullets — `- **Verification status:**
  the storybook tier could not be executed…` — and has no `status:` line at
  all.
* **PR-070** and **PR-122** each *have* a `status: resolved` line, outside
  their own block. `ORPHAN-ANNOTATION` already reported those two lines as
  belonging to no item. It could name the stray line; it could not name the
  item left without one. The two gates together name both ends of the same
  fact, which is the pairing D1 argues for.

Fix: `status:` is read like every other annotation in this toolkit — at
**column one**, **first occurrence in the block wins** (the `GR_AWK_ID_RUN`
rule, and the `branch:` rule `check-review.sh` uses), value trimmed and
compared against a **closed set**: `open` or `resolved`.

Anchoring to column one on its own would make a currently-read mid-line
`status:` invisible — the same false green, moved. So the anchoring ships
**paired** with D2's missing-`status:` violation, which turns every case the
new rule stops reading into a loud failure rather than a silent pass. Neither
half is safe alone; they land in one change for that reason.

This is a **breaking change**, and for more shapes than the compact one-line
form `**PR-001**: X. status: open`. Every one of these was accepted before and
is now reported:

* the compact form, and any `status:` not at column one — an indented one, a
  `- status: open` bullet;
* `Status:` and other capitalisations;
* any value outside `{open, resolved}` — `closed`, `wontfix`, `open (see
  below)`.

The measurement above says the real ledger uses none of them (160 of 163
carry a column-one `status:` with one of the two values), but the toolkit's
own bats fixtures used the compact form, and they are rewritten to the
multi-line form the templates have always specified.

`guardrails_version` goes to 0.4.0 — which **gates nothing**: no script reads
that key, so an old ledger meeting new scripts is detected by failing, not by
a version check. That is a pre-existing gap, recorded here because this is the
first change whose adoption cost makes it matter.

### D2 — new violations

| Violation | Fires on |
|---|---|
| `INCOMPLETE-PROBLEM ID (no status:)` | any PR item with no column-one `status:` in its block |
| `INCOMPLETE-PROBLEM ID (no owner:)` | an **open** item with no `owner:`, or `owner:` with an empty value |
| `INCOMPLETE-PROBLEM ID (no opened:)` | an **open** item with no `opened:`, or an empty value |
| `MALFORMED-STATUS ID (status: <v>)` | `status:` whose value is neither `open` nor `resolved` |
| `MALFORMED-DATE ID (opened: <v> …)` | an open item whose `opened:` is not `YYYY-MM-DD`, is not a calendar date, or is in the future |
| `STALE-PROBLEM ID (open N days, limit M)` | `problem_age_days` configured and age > M |
| `PROBLEM-BACKLOG (N open, limit M)` | `problem_open_max` configured and count > M |

All set `fail=1`. `UNRESOLVED-PR` stays a warning and stays exit 0 on its own:
it is the roll-call, not a verdict. The known-problem review it serves
(DO-178C §7.2.8) is a review, not a prohibition.

### D3 — `owner:` and `opened:` are required on OPEN items only

A resolved item needs no owner and cannot age. Requiring the fields on
resolved items would redden every ledger already written for no safety gain;
requiring them on open items is the one-time backfill `ratchet` exists to
walk a project through, and the failure names the item and the missing field.

`status:` is required on **every** item, open or resolved, because without it
the item's state is not recorded at all and D1's anchoring would drop it.

### D4 — a future `opened:` is a failure, except by one day

An `opened:` date after today yields a negative age, which compares as
younger than any limit. That is the false-green direction, so it is rejected
rather than clamped.

**Amended after the independent review.** The first version rejected *any*
future date, and the review reproduced what that costs. Dates are compared in
**local time**, from `date +%Y-%m-%d`; `resolve-problem` tells the author to
write *today*; and "today" differs by a day across timezones and under
ordinary clock skew. An author east of the build therefore blocked their own
merge, on a correct item, on the day they recorded it.

So: **one day of tolerance, clamped to age 0.** Tomorrow behaves exactly as
today does against every limit, `problem_age_days: 0` included. Anything
further fails. The trade is exact and small — the only case lost is a date
wrong by exactly one day, which is the one case indistinguishable from skew,
and two local dates differ by more than one only when the offsets differ by
more than 24 hours, which no pair of real timezones does.

### D5 — date arithmetic in awk, not `date -d`

`date -d` is GNU, `date -j -f` is BSD; neither is POSIX. Age is computed with
days-from-civil arithmetic in awk over both dates, which is pure integer work
and runs identically on gawk, mawk and busybox awk. `date +%Y-%m-%d` — which
IS POSIX — supplies today, and its output shape is validated in the shell
before it is trusted, because a garbage "today" makes every age wrong.

### D6 — two config keys, and an unset key is reported, not silent

`problem_age_days` and `problem_open_max`. Non-negative decimal integers.
Present-but-empty or non-integer is **exit 2**, not ignored: a limit the
reader cannot parse must not read as "no limit".

Unset means no limit for that dimension. That is a legitimate configuration —
but it is never silent. The summary gains a third line:

```
problems: open 3, oldest 41 days; limits age 30, open none
```

printed on pass and on failure alike, like `checked:` and `sources:`. A team
that has switched a limit off sees that fact at every single merge.

### D7 — the shipped config sets both limits

`templates/config.yaml` ships `problem_age_days: 30` and
`problem_open_max: 10`, not commented out. A finding whose complaint is that
nobody acts on the warning is not answered by an enforcement mechanism that
defaults to off. The values are policy, they live in the adopting project's
own config, one line changes either, and every run prints them.

Projects already configured keep warning-only thresholds until they add the
keys — the field requirements (D2, D3) reach them immediately, the limits do
not. That is the graduated path, and it is the only part of this change that
treats old and new projects differently.

### D8 — `owner:` and `opened:` get the ORPHAN-ANNOTATION backstop

`check_orphans` already covers `status:` over the problems ledger. The two
new keywords are block-parsed by the same reader, so they are orphanable in
exactly the same way — and an orphaned `owner:` is worse than a missing one,
because the block rule can credit it to the item above and an ownerless item
then reads as owned. That is the `ORPHAN-DISPOSITION` pairing from the
previous change, applied to the same shape of defect.

### D9 — what this does NOT do

No severity field. The finding lists "no owner, no age, and no severity", and
severity is the one of the three with no mechanical consequence: nothing can
check it, and an unchecked field is a field that drifts. Owner and age both
drive a gate. Severity is left out and the omission is recorded here.

No per-owner rollup, no report generation. That is finding 08.

---

## Tasks

Each task is one red→green→commit cycle. Test file is
`tests/check-trace.bats` unless stated. Every test is annotated with the
finding it implements, since no REQ items exist in this repository
(`# verifies: practice-feedback finding 09a`).

### Task 1 — `status:` is read at column one, first occurrence, closed set

1. **RED** — three tests:
   * an item whose only `status:` line is indented is reported
     `INCOMPLETE-PROBLEM … (no status:)` rather than silently reading as
     resolved;
   * `status: openish` is `MALFORMED-STATUS`, and the item does NOT appear in
     `UNRESOLVED-PR`;
   * two `status:` lines in one block — the first wins (`status: resolved`
     then `status: open` leaves the item off the roll-call).
2. **GREEN** — rewrite the PR scan in `scripts/check-trace.sh`.
3. Watch every other `UNRESOLVED-PR` test stay green.

### Task 2 — `owner:` and `opened:` are required on open items

1. **RED** — open item with neither field → two `INCOMPLETE-PROBLEM` lines,
   exit 1. Resolved item with neither → clean. `owner:` present with an empty
   value → `INCOMPLETE-PROBLEM`. Second `owner:` line ignored.
2. **GREEN** — collect both values in the same awk pass, first occurrence
   wins, `gr_value` for the value and emptiness test.

### Task 3 — `opened:` is a calendar date in the past

1. **RED** — `2026-13-01`, `2026-02-30`, `24-08-01`, `2026-08-1`, and a
   future date each give `MALFORMED-DATE`; `2024-02-29` (leap) is accepted
   and `2023-02-29` is not; today's own date is accepted.
2. **GREEN** — `gr_days_from_civil` and a validity test in the awk program;
   `today` passed in with `-v`, its shape validated in the shell first.

### Task 4 — the roll-call carries triage data

1. **RED** — `UNRESOLVED-PR PR-x (open 10 days, owner jvdv)`.
2. **GREEN** — reformat the emitted line.

### Task 5 — the two limits, and their validation

1. **RED** — `problem_age_days: 30` with a 31-day-old item → `STALE-PROBLEM`,
   exit 1; a 30-day-old item → clean (the limit is "more than"). Same shape
   for `problem_open_max`. `problem_age_days:` empty → exit 2.
   `problem_age_days: thirty` → exit 2. `problem_age_days: -1` → exit 2.
   `problem_age_days: 0` is accepted and fails every open item.
2. **GREEN** — add both to `GR_KNOWN_KEYS`; a `gr_limit KEY` helper in
   `lib.sh` returning the integer or empty, dying on anything else.

### Task 6 — the summary line

1. **RED** — `problems:` line present on pass and on failure; says
   `limits age none, open none` when unset; reports the oldest open item's
   age; says `open 0` with no open items.
2. **GREEN**.

### Task 7 — the orphan backstop for the new keywords

1. **RED** — `owner:` at column one before the first item in a problems file
   → `ORPHAN-ANNOTATION`; same for `opened:`. Neither is reported from the
   SRS, where nothing reads them.
2. **GREEN** — two more `check_orphans` calls.

### Task 8 — drift pins

`tests/check-ids.bats` carries the pin families that fail when a new script or
a new shared construct is not registered. Add pins so a future reader cannot
hand-copy the date arithmetic or the limit reader.

### Task 9 — documents

`templates/problems.md` grammar, `templates/config.yaml` (two keys, version
0.4.0), `README.md` gate list, `skills/check-traceability/SKILL.md` table,
`skills/resolve-problem/SKILL.md` step 1, `skills/ratchet/SKILL.md` backfill
step, `scripts/check-trace.sh` header.

---

## Self-review

* Every violation in D2 has at least one RED test naming it.
* Every task states real commands and real expected output.
* Names are consistent across tasks: `gr_days_from_civil`, `gr_limit`,
  `problem_age_days`, `problem_open_max`.
