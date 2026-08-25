# Verification — problem-report triage

**Change:** `problem-triage` · practice-feedback finding 09a
**Plan:** `docs/plans/2026-08-24-problem-triage.md`
**Base:** `f396c16` (`main`)
**Class:** the toolkit is unclassified and enforces class B/C projects; treated
as class B — normal-case and abnormal-input tests for every new behaviour.

---

## What the finding asked for, and what was actually wrong

> Items carry no owner, no age, and no severity, so there is nothing to triage
> on even if someone wanted to. […] Add `owner:` and `opened:` to problem
> items, and fail rather than warn above an age or count threshold — a warning
> nobody acts on is worse than no warning.

Two of those are what the finding says. The third was found while reading the
reader the finding complains about, and it is the one that mattered:

```awk
cur != "" && /status:[ \t]*open/ { open = 1 }
```

Unanchored, matched anywhere in the line, and **looking where the
`ORPHAN-ANNOTATION` backstop cannot see**. That backstop reports a keyword only
at column one. It exists to catch annotations belonging to no item; a reader
that reads a keyword occurrence the backstop never examines reopens the exact
hole the backstop was built to close.

The consequence is this toolkit's defining failure, inside the gate whose only
job is to make open problems visible: an item whose `status:` line the pattern
did not match read as **resolved** and vanished from the roll-call, with the
run at exit 0.

Not hypothetical. Measured on `sightings-app @ f1fd8d26`, 163 problem reports:

| | |
|---|---|
| items with no readable `status:` | **3** — PR-028, PR-070, PR-122 |
| open items on the roll-call | 48 |
| `status:` values in use | `open`, `resolved`, nothing else |
| items carrying `owner:` or `opened:` | **0** |

Each of the three is a different shape of the same defect:

* **PR-028** records its state in prose bullets (`- **Verification status:**
  the storybook tier could not be executed…`) and has no `status:` line.
* **PR-070** and **PR-122** each *have* a `status: resolved` line, sitting
  outside their own block. `ORPHAN-ANNOTATION` already reported those two
  lines. It could name the stray annotation; it could not name the item left
  without one. Only the two gates together name both ends of the same fact.

All three have read as resolved since the day they were written.

---

## What shipped

`check-trace.sh` gains five failing violations alongside the warning:

| Violation | Fires on |
|---|---|
| `INCOMPLETE-PROBLEM` | no column-one `status:` in the block; or an **open** item with no `owner:` / no `opened:` (an empty value counts as absent) |
| `MALFORMED-STATUS` | a `status:` value that is neither `open` nor `resolved` |
| `MALFORMED-DATE` | an open item's `opened:` is not a `YYYY-MM-DD` calendar date, or is in the **future** |
| `STALE-PROBLEM` | open longer than `problem_age_days` |
| `PROBLEM-BACKLOG` | more open items than `problem_open_max` |

`UNRESOLVED-PR` stays a warning and now carries the triage data the finding
asked for: `UNRESOLVED-PR PR-a3k9z2 (open 10 days, owner jvdv)`.

Reading rules, all three keywords alike: **column one**, **first occurrence in
the block wins**, value trimmed. That is the `GR_AWK_ID_RUN` rule and the
`branch:` rule `check-review.sh` uses, applied to a scalar annotation — and it
is what puts the reader and the backstop back in the same place. `owner:` and
`opened:` join `status:` in `check_orphans` for the same reason.

Anchoring alone would have moved the false green rather than removed it: a
mid-line `status:` would stop being read and nothing would say so. That is why
the missing-`status:` violation ships in the same change. **Neither half is
safe alone.**

### Deliberate omissions

* **No `severity:`.** The finding lists "no owner, no age, and no severity".
  Severity is the one of the three with no mechanical consequence — nothing
  can check it, and an unchecked field drifts. Owner and age each drive a
  gate. The omission is recorded rather than quietly made.
* **`traces:` and `satisfies:` still read anywhere on the line.** They have
  the identical reader/backstop split this change fixes for problem reports,
  with the identical consequence: an indented or mid-line `satisfies:`
  satisfies an LLR while the backstop never sees it. Closing it changes what
  every SAD and SRS ledger already written is allowed to look like, so it is
  stated here and in `check-traceability/SKILL.md` rather than folded in.
* **The backlog count excludes items whose status could not be read.** The
  gate does not guess an unstated status. The count can therefore
  under-report — but only on a run already red for that very item, never on a
  green one.

### This is a breaking change for one ledger shape

An item written compactly as `**PR-001**: X. status: open` becomes
`INCOMPLETE-PROBLEM (no status:)`. The measurement above says the real ledger
does not use that form (160 of 163 carry a column-one `status:`), but the
toolkit's own bats fixtures did, and they are rewritten to the multi-line form
the templates have always specified. `guardrails_version` goes to **0.4.0**.

---

## Adoption cost, measured

Running the branch against `sightings-app @ f1fd8d26` and diffing against
`main`'s scripts on the same tree:

```
check-ids.sh ............ output byte-identical to main
check-trace.sh .......... same 48 items on the roll-call, same 2 orphans,
                          same checked:/sources: figures
                          + 99 INCOMPLETE-PROBLEM lines
                            = 3 (no status:) + 48 open x 2 fields
```

Nothing else moved. The 99 lines are the one-time backfill, it is bounded to
the items still open, and it shrinks every time one is resolved.
`skills/ratchet/SKILL.md` gains the migration order — read the status-less
items *before* labelling them, since the gate has been calling them resolved.

The two limits do **not** reach an existing project by upgrading the scripts;
they must be added deliberately. Until they are, both print as `none` in the
new `problems:` summary line on every run — an unset limit is a decision that
stays visible.

---

## Gates, run in the worktree

| Check | Result |
|---|---|
| `sh tests/run-tests.sh` | see the evidence block below |
| `sh scripts/check-trace.sh` | n/a — guardrails does not yet self-host its own gates (tooth 0 of the ratchet gap analysis) |
| `sh scripts/check-ids.sh` | n/a — same |
| `sh scripts/check-review.sh` | n/a — same |
| `sh -n` on every script | clean (`every script parses as POSIX sh`, in the suite) |
| corpus differential | `sightings-app @ f1fd8d26`, above |

The three check scripts cannot run on this repository: it has no
`.guardrails/config.yaml` and no requirement items. That is a known,
recorded gap, not an omission of this change. The bats suite is the
qualification basis, and the corpus differential is what stands in for
running the gates on a real ledger.

---

## What mutation testing found, and it was my own tests

Four tests in this change passed for a reason other than the behaviour they
named. Three were found by mutation, one by reading. Each is recorded rather
than quietly repaired, because the count is the point: it has not improved
since the last change, where it was six.

| Test | Passed because | Now |
|---|---|---|
| `an indented status: line no longer states an item's status` | The fixture left out `owner:` and `opened:` too, so `INCOMPLETE-PROBLEM` fired whatever the status rule did. **M01 — restoring the original anywhere-on-the-line reader — survived the whole suite.** | The item is complete but for its status, and the exact parenthetical is asserted |
| `a capitalised Status: does not state an item's status` | Same fixture weakness, same reason | Same repair |
| `a leap day is a calendar date and 29 February 2023 is not` | Used **2100**-02-29. Dropping the century rule made the date valid, the *future* rule then rejected it anyway, and the assertion held. **M11 survived.** | Uses `1900-02-29` — a past date, so only the calendar rule can reject it, and the rejection reason is asserted |
| `an age spanning February` | Did not exist. Every other date test uses `days_ago N`, which never lands in January or February, so the month shift in `days_from_civil` was never exercised. **M29 — applying the March branch to every month — survived.** | New test, with `date` stubbed, asserting exact ages across February, a leap February, and a year boundary |

The shape is the same in all four: **an assertion that is true for more than
one implementation.** A fixture missing several fields at once cannot tell you
which rule rejected it, and a date in the future cannot tell you which rule
called it invalid. Both are cheap to write and both read as coverage.

### The measurement itself lied twice, in the reassuring direction

Worth recording in a document about false greens.

1. **The first battery reported `M01 KILLED`.** It was not. `/tmp` had filled
   while a 134 MB corpus copy ran alongside it, so the runner's `mktemp`/`cp`
   failed, the suite errored, and errors counted as kills. A mutation runner
   that cannot tell "the test caught it" from "the harness broke" reports the
   comforting answer.
2. **The clean re-run was read from a stale file.** The waiter tested for the
   existence of `mut.txt`, which the *previous* battery had already written,
   so it returned the old results instantly while the new battery was still
   running. Caught only because a mutation I had just fixed still reported
   `STALE`.

Both are now guarded: the runner asserts that each mutation actually changed
`scripts/` before running anything, and reports `STALE` rather than a verdict
when a mutation's target string no longer matches. That guard is what caught
`M30` after `gr_value` moved into `lib.sh` next to `gr_clean`, where its
replacement text matched twice.

---

## Evidence

```
Derived by `tests/evidence.sh f396c16` — do not edit by hand.

- Suite: **380 tests** (f396c16: 324); 375 measured against `f396c16`.
- New or renamed since `f396c16`: **58**.
- Of those, **51** go red when run against `f396c16`'s scripts.
- **7** cannot go red, and none is counted as evidence that a
  defect was fixed:

  - `check-trace: a later item's open status does not reach the resolved item above`
  - `check-trace: a resolved item needs neither owner: nor opened:`
  - `check-trace: an indented owner: in a grammar comment is not an orphan`
  - `check-trace: an unparseable limit is an environment error, not no limit`
  - `check-trace: an unreadable architecture ledger fails the orphan scan`
  - `check-trace: owner: and opened: in another ledger are out of scope`
  - `check-trace: real front matter is still skipped by the backstop`
```

The seven that cannot go red are **guards** — they constrain over-firing
rather than prove a fix, and `evidence.sh` excludes them from the count by
design. Three are worth naming: `an unparseable limit is an environment
error` passes on the base because the base rejects `problem_age_days` as an
*unknown key*; `real front matter is still skipped by the backstop` is the
over-firing side of a fix whose under-firing side (`a leading --- does not
switch the orphan backstop off either`) does go red; and `an unreadable
architecture ledger fails the orphan scan` exists only because the problems
ledger stopped being able to reach that code path.

### Mutation testing — 53 mutations, **53 killed, 0 survived**

Every mutation script asserts its target matched **exactly once** before it
edits, so one that has gone stale against changed code reports `STALE` rather
than a verdict. That guard is the only reason this number can be read at all
— see the two sections below.

| # | Mutation | Verdict | Killed by |
|---|---|---|---|
| `M01` | check-trace: status: read anywhere on the line again (the original defect) | killed | 1 test(s) |
| `M02` | check-trace: an item with no status: is not reported | killed | 3 test(s) |
| `M03` | check-trace: status: value is not checked against the closed set | killed | 1 test(s) |
| `M04` | check-trace: the LAST status: in a block wins, not the first | killed | 1 test(s) |
| `M05` | check-trace: owner: is not required on an open item | killed | 3 test(s) |
| `M06` | check-trace: an empty owner: value counts as an owner | killed | 1 test(s) |
| `M07` | check-trace: opened: is not required on an open item | killed | 3 test(s) |
| `M08` | check-trace: an undatable open item is dropped from the roll-call | killed | 7 test(s) |
| `M09` | lib.sh: a date is accepted on shape alone, never validated as a calendar date | killed | 3 test(s) |
| `M10` | lib.sh: February is given 31 days like any other month | killed | 2 test(s) |
| `M11` | lib.sh: the leap-century rule is dropped — every 4th year is a leap year | killed | 1 test(s) |
| `M13` | check-trace: the age limit fires AT the limit, not past it | killed | 1 test(s) |
| `M14` | check-trace: STALE-PROBLEM never fires | killed | 3 test(s) |
| `M15` | check-trace: the backlog limit fires AT the limit, not past it | killed | 2 test(s) |
| `M16` | check-trace: PROBLEM-BACKLOG never fires | killed | 4 test(s) |
| `M17` | check-trace: the backlog is counted per ledger file, not across the ledger | killed | 6 test(s) |
| `M18` | lib.sh: gr_limit accepts a value that is not a whole number | killed | 1 test(s) |
| `M19` | lib.sh: gr_limit reads a present-but-empty limit as no limit | killed | 2 test(s) |
| `M20` | check-trace: an age limit of 0 is treated as no limit at all | killed | 1 test(s) |
| `M21` | check-trace: the problems: summary line is not printed | killed | 9 test(s) |
| `M22` | check-trace: the summary reports every limit as none, set or not | killed | 2 test(s) |
| `M23` | check-trace: the orphan backstop no longer covers owner: | killed | 2 test(s) |
| `M24` | check-trace: the orphan backstop no longer covers opened: | killed | 2 test(s) |
| `M25` | check-trace: the front-matter skip is restored to the triage scan (review BLOCKING 1) | killed | 1 test(s) |
| `M26` | check-trace: an awk failure in the triage scan is not detected | killed | 1 test(s) |
| `M27` | check-trace: BOTH today-guards removed — a nonsense date is accepted | killed | 3 test(s) |
| `M28` | lib.sh: gr_date_ok does not check the length of the value | killed | 1 test(s) |
| `M29` | lib.sh: days_from_civil uses the wrong month shift | killed | 1 test(s) |
| `M30` | lib.sh: gr_value does not trim the trailing whitespace off a value | killed | 1 test(s) |
| `M31` | check-trace: the triage scan does not strip a trailing CR | killed | 2 test(s) |
| `M32` | check-trace: owner: is read anywhere on the line, not at column one | killed | 1 test(s) |
| `M33` | check-trace: resolved items are counted toward the backlog too | killed | 8 test(s) |
| `M34` | check-trace: only the SHELL today-guard is removed (the calendar guard remains) | killed | 1 test(s) |
| `M35` | check-trace: the oldest-age maximum starts at 0, so an age of 0 never registers | killed | 1 test(s) |
| `M36` | check-trace: the LAST owner: in a block wins, not the first | killed | 1 test(s) |
| `M37` | check-trace: the LAST opened: in a block wins, not the first | killed | 1 test(s) |
| `M38` | check-trace: an empty opened: value counts as a date | killed | 1 test(s) |
| `M39` | lib.sh: a zero month or a zero day is a valid calendar date | killed | 1 test(s) |
| `M40` | lib.sh: gr_digits accepts anything | killed | 1 test(s) |
| `M41` | lib.sh: days_from_civil drops the century term | killed | 1 test(s) |
| `M42` | check-trace: opened: is read anywhere on the line, not at column one | killed | 1 test(s) |
| `M43` | check-trace: the BOM strip is removed from the TRIAGE scan only | killed | 1 test(s) |
| `M45` | check-trace: a future opened: is clamped to zero however far ahead | killed | 2 test(s) |
| `M46` | check-trace: one day of clock tolerance is removed | killed | 1 test(s) |
| `M47` | check-trace: the limits are read at the point of use again | killed | 11 test(s) |
| `M48` | check-trace: the no-usable-date count is dropped from the summary | killed | 2 test(s) |
| `M49` | check-trace: the backlog noun is always plural | killed | 1 test(s) |
| `M50` | check-trace: the calendar guard on today is removed (shape check remains) | killed | 2 test(s) |
| `M51` | lib.sh: front matter opens on any leading --- again, header or rule (review N2) | killed | 1 test(s) |
| `M52` | lib.sh: front matter never opens at all, so a real header is read as ledger prose | killed | 10 test(s) |
| `M53` | lib.sh: gr_limit guesses a digit width instead of asking the shell (review N5) | killed | 1 test(s) |
| `M54` | lib.sh: gr_limit does not check comparability at all (review N5/finding 3) | killed | 12 test(s) |
| `M55` | check-trace: the no-usable-date count only counts a MISSING opened: (review N6) | killed | 2 test(s) |

---

## Corpus differential — `sightings-app @ f1fd8d26`

The same tree, scanned twice: once with `main`'s scripts at `f396c16`, once
with this branch's. The corpus itself ships guardrails **0.1.0**, so a
comparison against its own installed scripts would have measured five changes
at once; that first attempt was discarded.

```
check-ids.sh .............. output byte-identical
check-trace.sh
  checked: / sources: ..... identical
  UNRESOLVED-PR ........... the SAME 48 items (line text now carries age/owner)
  ORPHAN-ANNOTATION ....... the same 2
  MISPLACED-ITEM /
  DANGLING-REF / MISSING-TEST ... 0 -> 0
  INCOMPLETE-PROBLEM ...... 0 -> 99
  MALFORMED-STATUS ........ 0     (every value in the ledger is open or resolved)
  MALFORMED-DATE .......... 0     (no dates to malform yet)
  STALE-PROBLEM ........... 0     (no limits configured)
  PROBLEM-BACKLOG ......... 0     (same)
  problems: ............... open 48, oldest n/a (48 with no usable date)
```

99 = 3 items with no readable `status:` + 48 open items x 2 missing fields.
Nothing else moved.

**And it caught nothing.** The corpus differential was the measurement this
change leaned on hardest, and it was blind to the blocking defect below: no
file in the 68-file ledger begins with `---`, so the output was byte-identical
before and after that repair. A differential against one real project answers
"does this change what is already there", never "what does this change do to
what is not". Only the adversarial review found it.

---

## The independent review, and its two passes

A fresh subagent with the diff, the plan and the tree — no implementation
narrative. Two passes: eleven findings, then eight more against the repairs.
Every one is listed with what was done. Nothing was dismissed.

### Pass 1

| # | Severity | Finding | Disposition |
|---|---|---|---|
| 1 | **BLOCKING** | The front-matter skip I had just added to the triage scan swallowed **item definitions**. `GR_AWK_FRONT_MATTER` opens on ANY `---` at line 1, so a leading horizontal rule hid every item up to the next one: an open problem 236 days old absent from the roll-call, `problem_open_max` not applied, exit 0 — with `checked: PR 2` printed beside `problems: open 1`. **And the test I shipped with it asserted the defect**: it checked the ID appeared nowhere, which is true both when a header is ignored and when a real item is lost | Fixed — the skip is removed entirely and the scan is single-pass. Test replaced by `a leading --- does not hide the items beneath it` (the reviewer's fixture) and `the open count and the item count reconcile`. Mutation M25 restores the skip faithfully and is killed |
| 2 | IMPORTANT | The future-date rule was a **cliff**: `resolve-problem` tells the author to write *today*, and "today" differs by a day across timezones, so an author east of the build blocked their own merge on a correct item | Fixed — one day of tolerance, clamped to age 0; anything further fails. D4 amended, and the rule now appears in `templates/problems.md` and `resolve-problem/SKILL.md`, which is where an author would look |
| 3 | IMPORTANT | `problem_open_max` past the shell's integer range made `[ -gt ]` fail with *Illegal number*, the `if` took its else branch, and the backlog gate switched itself off at exit 0 — the shape `gr_limit`'s own comment forbids | Fixed, then fixed again (see N5) |
| 4 | IMPORTANT | **Seven mutations of mine survived the whole suite**, two of them rules the plan promised to test: first-`owner:`-wins is stated in `templates/problems.md`, listed in the plan as a RED test, and was never written. Also: empty `opened:`, zero month/day, `gr_digits`, the century term in `days_from_civil`, `opened:` column-one, the BOM strip | All seven pinned; the reviewer's mutations adopted as M36–M43 |
| 5 | MINOR | `gr_limit` ran at the point of use, so a typo was diagnosed after a page of violations with every summary line suppressed | Fixed — both limits and both `today` checks now sit beside `gr_check_config` |
| 6 | MINOR | `ORPHAN-ANNOTATION`'s own documentation never gained `owner:`/`opened:` | Fixed in the script header and the SKILL row |
| 7 | MINOR | The `gr_kw_here` comment still described a defect this change removed | Fixed — see N4 |
| 8 | MINOR | The BOM strip is unrequested, untested, and diverges from `ids_defined` | Kept, pinned, and the divergence stated. Removing it makes a BOM'd item appear only as a confusing `DANGLING-REF` |
| 9 | MINOR | A bad `today` was announced as `problem-report scan failed on <ledger>.md` — a clock fault blamed on a ledger file | Fixed — the calendar check is a standalone awk call with its own message, and both date tests now assert the specific wording |
| 10 | MINOR | `oldest` ignored undated open items; `1 open problem reports`; stale test comments | Fixed — see N6, N8 |
| 11 | MINOR | The plan said "158 of 159" where its own table said 163 with 3 lacking a status | Fixed, and the breaking-change list now names all four shapes rather than one |

### Pass 2, against the repairs

| # | Severity | Finding | Disposition |
|---|---|---|---|
| N1 | **BLOCKING** | Six mutation scripts no longer applied — casualties of the repairs — **and the record still certified them killed.** M25, the only one guarding the blocking repair, had a quoting error that made it unparseable, and a naive fix would have restored the skip without the second `"$f"`, breaking 47 tests and proving nothing about the rule it names | Fixed. All six rewritten against the current tree; M25 restores the skip *faithfully* (two-pass read and `gr_fm_reset` included) and is killed by exactly the two new tests. M12 deleted as superseded by M45/M46, M44 by M53/M54. This section, the evidence block and the mutation table are all rewritten from re-derived output |
| N2 | IMPORTANT | The **backstop** had the other half of BLOCKING 1, and my repair's comment asserted it did not. A leading `---` still switched `check_orphans` off for the same span — pre-existing for `status:`, and **newly widened by this change** to `owner:` and `opened:`. The two gates disagreed about what `---` means, in a change whose thesis is that they must agree | Fixed — `GR_AWK_FRONT_MATTER` now requires a key on line 2. YAML has no blank line between the delimiter and the first key, so nothing legitimate is lost, and the rule can only make the scan read *more*. Both sides tested; M51/M52 |
| N3 | IMPORTANT | Repair 2 changed the contract and left **four** statements of the old one in the tree, including the one user-facing table, which still told authors tomorrow would fail | Fixed in all four, plus the two author-facing documents that never stated the rule at all |
| N4 | MINOR | Finding 7 was not "corrected in place" — the false paragraph stood and the correction pointed the wrong way | Fixed — the paragraph itself is rewritten, as a two-item list of what is closed and what is not |
| N5 | MINOR | The magnitude bound was over-strict (`1000000000` refused), misdescribed (every shell compares it), unpinned in both directions (loosening the constant survived the suite), and applied to a key no shell ever compares | Fixed — `[ "$_lv" -ge 0 ] 2>/dev/null` asks the shell instead of guessing a width. Both ends pinned; M53/M54 |
| N6 | MINOR | `(N undated)` counted items whose date was *refused*, which are dated | Fixed — `(N with no usable date)`, true of both, with a test for the refused case |
| N7 | MINOR, **new** | An item pasted inside genuine front matter is read here and invisible to the backstop, so its own fields report as orphans | **Not fixed.** Contrived, fail-loud, named in the code so it is not rediscovered as a surprise. Fixing it means teaching the backstop that front matter containing an item is not front matter |
| N8 | MINOR | Test-comment residue: a superseded rule, and `# only the summary line` where there are now three | Fixed |

### What the reviewer could not fault

`gr_days_from_civil` differentially against Python's proleptic Gregorian over
years 1–9999 at every boundary plus 3000 random dates spanning −800000 to
+3000000 days: **zero disagreements**. `gr_date_ok` rejected every malformed
shape tried, under `LC_ALL=C` and `en_US.UTF-8` alike, including latin-1 and
invalid-UTF-8 bytes. The single-pass triage scan was probed with an empty
file, a BOM-only file, CRLF, CRLF plus a leading `---`, an item at EOF with no
newline, NUL bytes in `owner:`, and an `owner:` value crafted to imitate the
`W`/`F` protocol lines — all clean. Shell correctness clean but for finding 3.

---

## What mutation testing found, and it was my own tests

Eight tests in this change passed for a reason other than the behaviour they
named — four found by mutation, one by reading, three by the reviewer. The
count is recorded rather than quietly repaired: it was six last change and it
has not improved.

| Test | Passed because |
|---|---|
| `an indented status: line no longer states an item's status` | The fixture omitted `owner:`/`opened:` too, so `INCOMPLETE-PROBLEM` fired whatever the status rule did |
| `a capitalised Status: does not state an item's status` | Same weakness |
| `a leap day is a calendar date and 29 February 2023 is not` | Used **2100**-02-29 — a future date, so the future rule rejected it whatever the century rule did |
| `an age spanning February` | Did not exist; `days_ago N` never lands in January or February, so the month shift was unexercised |
| `an opened: that is not a calendar date is malformed` | Asserted `MALFORMED-DATE || INCOMPLETE-PROBLEM` — a disjunction no input could distinguish, leaving the empty-value rule unpinned on all eight |
| `front matter is not ledger prose to the triage scan either` | Asserted the ID appeared nowhere, which is true both when a header is ignored and **when a real item is swallowed** |
| `a date(1) that is date-SHAPED but not a real date is an error` | Asserted only the exit code, so a clock fault reported as a ledger-file failure went unnoticed |
| `a limit too large to compare is an error` | Only input was 20 digits, so the boundary was unpinned in both directions |

The shape is the same in all eight: **an assertion true for more than one
implementation.** A fixture missing several fields at once cannot say which
rule fired; a date in the future cannot say which rule called it invalid; a
disjunction cannot say which branch was taken; an exit code cannot say why.
Each is cheap to write and each reads as coverage.

### The measurement lied three times, always reassuringly

In a document about false greens.

1. **The first battery reported `M01 KILLED`.** It had not been. `/tmp` filled
   while a 134 MB corpus copy ran beside it, the runner's `cp` failed, the
   suite errored, and errors counted as kills.
2. **A clean re-run was read from a stale file** — the waiter tested for the
   existence of `mut.txt`, which the previous battery had already written.
3. **The record certified five verdicts that could no longer be obtained**
   (N1). The `STALE` guard fired correctly; nothing acted on it. A guard that
   reports into an artefact nobody re-reads is a guard that does not run.

All three are now closed: the runner asserts each mutation changed `scripts/`
before running anything, reports `STALE` instead of a verdict when the target
no longer matches, and the numbers in this document are pasted from a single
final battery over the shipped tree.

---

## Environment

`ssh-add -l` times out against `/run/user/1001/gcr/ssh`. `ssh-keygen -Y sign`
consults the agent before the key file, so **every** signed commit blocks
indefinitely — including `merge-change` step 7. Reproduced outside the test
harness; `SSH_AUTH_SOCK= git commit -S` succeeds instantly and verifies `G`.

The suite figures above were taken with `SSH_AUTH_SOCK=` set empty, which is
recorded here rather than hidden: three tests in `check-signing.bats` (a file
this change does not touch) cannot run otherwise. The signed squash itself
needs the real key and cannot be worked around.

`merge-change` step 1 merged the base from a **local ref**, not from the
remote. `git fetch origin` fails with "Please make sure you have the correct
access rights" — this session has no GitHub access, deliberately. The base
merged was `main` at **f396c16**, which is named here so a later reader knows
what step 4's duplicate scan would have been compared against. `main` and
`origin/main` were in sync at the start of this work, by the operator.

Steps 3–5 could not run at all: there is no `.guardrails/config.yaml` in this
repository (tooth 0), so `finalize-docs.sh`, `check-ids.sh` and
`check-trace.sh` have nothing to read. The bats suite and the corpus
differential stand in, as they did for the previous change.

---

## Open gaps

1. **`traces:` and `satisfies:` keep the reader/backstop split** this change
   closes for problem reports. `gr_id_run` finds its keyword anywhere on the
   line while the backstop reports only column one, so an indented
   `satisfies:` satisfies an LLR the backstop never sees. Named in
   `lib.sh`, in `check-traceability/SKILL.md`, and here.
2. **No `severity:`**, deliberately — nothing could check it.
3. **An item inside genuine front matter draws spurious orphans** (N7).
   Fail-loud; not fixed.
4. **The backlog count excludes items with an unreadable status.** It can
   only under-report on a run already red for that item.
5. **`guardrails_version` is read by no script.** The 0.4.0 bump gates
   nothing; an old ledger meeting new scripts is detected by failing. Found
   by the reviewer, pre-existing, and now the first change whose adoption
   cost makes it matter.
6. **guardrails still cannot run its own gates** (tooth 0).
7. **Local time**, with one day of tolerance on `opened:` only.
8. **The limits do not reach an existing project** by upgrading the scripts.
   Until added, both print as `none` on every run.

---

## Verdict

Two review passes, nineteen findings, two of them blocking. Every finding
fixed except N7, which is recorded with its reasoning. **380 tests**, 58 new,
51 red against `f396c16`. **53 mutations, 53 killed, none survived, none
stale.** Corpus differential clean against `main` but for the 99 backfill
lines it is meant to produce.

Merge blocked on the wedged ssh-agent, not on this change.
