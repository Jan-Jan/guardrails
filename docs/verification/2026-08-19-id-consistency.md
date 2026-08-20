# Verification — id-consistency (2026-08-19)

Change: make every gate agree on what a definition line is, and make the
cross-branch duplicate gate keep the promises its own header makes. Branched
from `main` at `e63c1e5`. Plan and acceptance criteria:
`docs/plans/2026-08-19-id-consistency.md`.

Three defects, all one class — two pieces of the toolchain holding different
opinions about the same string:

1. `check-ids.sh` suppressed a relocated definition by testing a
   newline-separated set with a space-delimited `case`, so suppression worked
   for exactly one relocated definition and failed for two.
2. `finalize-ids.sh` matched the definition form **unanchored** in `max_final`
   while anchoring it in its own draft scan, and while both other gates
   anchored. Prose raised the mint ceiling invisibly.
3. Found while hardening the same gate, and fixed here because leaving it would
   have shipped a gate that still blocks legitimate work: the diff harvest read
   **every ID on a definition line** as newly defined, so a problem report
   reading `**PR-090**: a new problem caused by REQ-001.` was reported as a
   duplicate of `REQ-001`.

## The gate

Every figure below is derived from the shipped tree after round 2, not carried
forward. Round 2 found this section stale in three places and self-contradictory
in one — two different runtimes for a single measurement — which is exactly what
`tests/evidence.sh` exists to stop.

| Gate | Result |
| --- | --- |
| `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` | **175 ok, 0 not ok** (`main`: 146) |
| `tests/evidence.sh main` | 29 new or renamed; **19 go red** against `main`; 10 cannot |
| `sh -n` on all five scripts | clean, and now a named test |
| Script modes | all five `100755`, unchanged |

The 10 that cannot go red are guards, not evidence that anything was fixed, and
`evidence.sh` lists them as such. Each is nevertheless load-bearing, shown by
mutation rather than asserted, and the enumeration below is one-to-one — an
earlier version of this sentence double-counted the block-parser guard:

| Guard | Reddened by |
| --- | --- |
| an indented definition on the base | M2 |
| an off-column token below the ceiling | M7 |
| an ordinary tree reports no UNANCHORED-DEF | M7 |
| the ceiling counts the base ref | M7, M10, M14 |
| the highest item's own definition line | M7 |
| check-trace: a mid-line definition form | M2 |
| check-trace: an indented definition | M2 |
| check-trace: the awk block parsers agree | M2, M15–M18 |
| check-trace: an indented bold line does not close a block | M19–M22 |
| every script parses as POSIX sh | demonstrated directly, by re-introducing the apostrophe that broke `check-ids.sh` twice during this change |

## Mutation table

Each row reverts one production change and re-runs the whole suite. A change no
test can detect is a change with no evidence behind it.

| # | Reverted | Red | Caught by |
| --- | --- | --- | --- |
| M1 | `gr_contains` → the old space-delimited `case` | 2 | relocating two definitions in one change is not a duplicate, a real duplicate is still caught alongside a relocation |
| M2 | the default `^` inside `gr_def_re` | 12 | 12 tests incl. a definition-form token off column one is reported, not failed, an indented definition on the base is not something to collide with |
| M3 | `finalize-ids.sh` back to its own unanchored regex | 4 | 4 tests incl. every gr_def_re call site is still a call site, and no copy joins them, poisoning gr_def_re changes every gate's verdict |
| M4 | `check-trace.sh` `ids_defined` back to its own copy | 2 | every gr_def_re call site is still a call site, and no copy joins them, poisoning gr_def_re changes every gate's verdict |
| M5 | delete the `UNANCHORED-DEF` report | 8 | 8 tests incl. every gr_def_re call site is still a call site, and no copy joins them, a definition-form token off column one is reported, not failed |
| M6 | `check-ids.sh` `def_re` back to its own copy | 2 | every gr_def_re call site is still a call site, and no copy joins them, poisoning gr_def_re changes every gate's verdict |
| M7 | report every off-column token, not only those above the ceiling | 5 | 5 tests incl. clean repo passes, an ordinary tree reports no UNANCHORED-DEF |
| M8 | do not seed declared prefixes at zero | 1 | a definition-form token off column one is reported, not failed |
| M9 | harvest every ID on the definition line again | 2 | a definition line declares its own ID, not every ID on it, the ID a definition line does declare is still caught |
| M10 | never consult the base ref for the ceiling | 1 | the ceiling counts the base ref, as finalize-ids does |
| M11 | `${2-^}` → `${2:-^}` | 8 | 8 tests incl. a definition-form token off column one is reported, not failed, an indented token above the ceiling is reported with the ID as written |
| M12 | `max_final` back to the first digit run | 1 | a digit-bearing prefix does not have its own digits read as the number |
| M13 | claim the base was consulted when it was not | 1 | with no usable base the report says the base was not consulted |
| M14 | stop converting the NUL framing | 5 | 5 tests incl. a definition-form token off column one is reported, not failed, an indented token above the ceiling is reported with the ID as written |
| M1x.REQ | unanchor the **REQ** awk block opener | 1 | ct/the awk block parsers agree with gr_def_re on indentation |
| M1x.PR | unanchor the **PR** awk block opener | 1 | ct/the awk block parsers agree with gr_def_re on indentation |
| M1x.LLR | unanchor the **LLR** awk block opener | 1 | ct/the awk block parsers agree with gr_def_re on indentation |
| M1x.SDD | unanchor the **SDD** awk block opener | 1 | ct/the awk block parsers agree with gr_def_re on indentation |
| M2x.REQ | unanchor the **REQ** awk block closer | 1 | ct/an indented bold line does not close a block either |
| M2x.PR | unanchor the **PR** awk block closer | 1 | ct/an indented bold line does not close a block either |
| M2x.LLR | unanchor the **LLR** awk block closer | 1 | ct/an indented bold line does not close a block either |
| M2x.SDD | unanchor the **SDD** awk block closer | 1 | ct/an indented bold line does not close a block either |
| M23 | stop detecting newline paths | 2 | a path with newlines is reported unreadable, not given a made-up location, one newline in a path is caught too |

Derived after the incident recorded below, from a clean `HEAD`. The previous
derivation of this table was contaminated by that incident and its numbers were
wrong — `M4` appeared to redden two `finalize-ids` tests it cannot touch, which
is what made the contamination visible.

Two rows are absent because measuring them changed the code instead.

**Dropping `core.quotePath=false` reddened nothing** — and the reason is that
`-z` suppresses path quoting by itself, so the override had been carried along
doing nothing since the round-1 fix. Verified directly (`git grep -nIz` prints
`café.md` unquoted with the default config) and deleted. A flag that looks
load-bearing and is not is worse than no flag.

**Removing the leading-definition strip reddened nothing** either, back in the
first round of this change. That one turned out to be a proof rather than a gap:
an anchored definition is one of the numbers the ceiling is the maximum *of*, so
it can never exceed it. Deleted, with the reasoning pinned by
`the highest item's own definition line does not report itself` (M7 reddens it).

## Corpus regression

`sightings-app` at **`dev` = `676f090e`**, always a fresh `git clone -s`, never
the working tree. The commit is pinned because that branch moves under active
development — this document has quoted 293, then 326, and now 345 items across
three measurements on three different commits. A row without a commit cannot be
re-derived, which independent review duly pointed out.

Counts at that commit: `REQ 125, HAZ 8, RC 25, SDD 32, LLR 47, PR 108` = 345.

Re-run after the incident recorded below, against the restored scripts: the
earlier corpus figures were taken from a tree that was briefly wrong.

| | `main`'s scripts | This branch |
| --- | --- | --- |
| `check-ids.sh --base dev` | exit 0, **no output** | exit 0, **byte-identical** |
| `check-trace.sh` | exit 0 | exit 0, **byte-identical**, same counts |
| `finalize-ids.sh --dry-run` | exit 0 | exit 0, **byte-identical** |

Two of those three comparisons are between empty outputs, which is worth saying
plainly: they establish that this change adds no noise, not that it exercises
anything. `check-trace.sh`'s is the substantive one — 326 items enumerated
identically through a rewritten definition regex.

## Runtime

One measurement per row, three samples each, same machine, warm cache. This
section exists because earlier versions of this document carried **two**
different runtimes for one measurement and the code carried a third for another
— exactly the duplication `tests/evidence.sh` was written to end.

| Tree | `main` | This branch |
| --- | --- | --- |
| corpus at `506fce5b` (326 items) | 1.81 / 1.50 / 1.44s | 3.14 / 3.01 / 2.71s |
| corpus at `676f090e` (345 items) | not re-timed | not re-timed — only the verdicts were re-checked |
| synthetic, 4000 items, worst case | 0.12 / 0.11 / 0.11s | 0.46 / 0.48 / 0.54s |

Call it **1.6s → 2.9s** on the corpus and **0.11s → 0.49s** synthetic. This
change makes `check-ids.sh` roughly twice as slow on a real project and four
times on the synthetic worst case. An earlier cold-cache pair read 2.45s → 1.84s
and would have let this be reported as a *speed-up*; it is not one.

The synthetic tree is generated by the script below rather than described,
because independent review could not reproduce the figure this document
previously carried and had no generator to check against:

```sh
i=1; while [ $i -le 4000 ]; do
  printf '**PR-%04d**: item %d.\nstatus: open\nSee also `**PR-9%03d**:` in prose.\n' \
    $i $i $((i % 1000)) > docs/problems/i$i.md
  i=$((i + 1))
done
```

Every file carries an off-column token above the ceiling, so every one is
reported — the worst case this scan can be given.

The `^.+` candidate pattern the first implementation used, on the same corpus:
**36.9s for a single prefix**, against **0.12s** for the shipped unanchored scan
across all six. Earlier measurements on the smaller corpus gave 21–23s. The
figure moves with corpus size and load, which is why the code comments now say
"tens of seconds" and point here rather than quoting a number that drifted into
three values.

## Corrections made during execution

1. **Task order changed.** The plan put the hand-rolled-regex lint at task 2,
   but it spans three scripts and one of those adoptions is itself a behaviour
   change needing its own test first. Parked until all three had adopted, so
   every commit ends green.
2. **My first lint test was a false green.** It searched for the doubled
   backslashes of a shell regex using a BRE that could not match them; with a
   hand-rolled copy deliberately restored, it printed `ok`. Found by mutation,
   not by its own earlier red — whose cause was something else entirely.
   Rewritten with `grep -F` and verified in **both** directions before being
   kept.
3. **The plan predicted the wrong verdict** for an indented or mid-line
   definition in `check-trace.sh`: it expected exit 0, and the gate exits 1 with
   `DANGLING-REF`, because a token that defines nothing is still a reference to
   something nothing defines. Being reported as a *mention* is stronger evidence
   than silence that it was not read as a definition, so the assertions were
   corrected to demand it.
4. **`UNANCHORED-DEF` was narrowed after measurement.** Reporting every
   off-column token gave **nine** lines on the corpus, every one of them
   ordinary prose (`Resolves **PR-006**: ...`) and not one reserving anything.
   It now reports only tokens above the highest real definition of their
   prefix — the only ones whose reservation this change drops. On the corpus:
   zero lines. AC7 amended accordingly.
5. **The first implementation was 3m36s slow.** Its candidate scan used
   `^.+\*\*(PFX)-…`, and git's matcher backtracks on a leading `.+`: tens of
   seconds per prefix (measured in **Runtime** above, on a pinned corpus). Rewritten as two greps with awk deciding correctness, and
   `gr_def_re`'s second parameter changed from a line prefix to a full POSITION
   (`${2-^}`) so a caller can ask for "anywhere on the line" without hand-rolling
   the token shape. The unit test for that parameter was updated with it.
6. **A third defect was fixed beyond the plan** (the harvest, above), because it
   is the same disagreement in the same gate and blocks ordinary work. AC9 was
   added for it rather than fixing it silently.

## Amendments to the acceptance criteria

AC1–AC8 are the requirement of record; two changed during execution and are
amended in the plan rather than reinterpreted here.

- **AC7** now says "above the highest real definition of its prefix", on the
  measurement in correction 4.
- **AC9** added: a definition line declares the ID at its start and no other.

## Open gaps

1. The awk-dialect definition patterns cannot use `gr_def_re` (awk has no
   portable `{3,}`): four block parsers in `check-trace.sh`, spelled by eight
   patterns — an opener and a closer each — plus the scan in `check-ids.sh`.
   All eight are now pinned by test: round 2 found two openers pinned by
   nothing, and round 3 found all four closers pinned by nothing. A test is
   still weaker than shared source.
2. `check-ids.sh`'s base-side scan carries a literal ID and anchors by hand for
   the same reason; pinned by one test.
3. `UNANCHORED-DEF` is reported by `check-ids.sh` alone. A project that runs
   only `check-trace.sh` never sees it.
4. **All three `git grep` status checks are pinned by nothing.** Replacing any
   of them with `true` reddens no test — independent review checked the one
   this document previously exempted, and it is no better off than the others.
   Running the probe outside a pipeline makes its status *real*; it does not
   make the `gr_die` that consumes it *tested*.
5. A path containing a **newline** breaks the three-line framing. It is now
   detected before the scan runs, on the paths the scan would read, and the run
   reports `UNANCHORED-DEF-UNREADABLE` instead of judging anything. Two tests
   pin it — one newline and three. The previous version detected the *symptom*
   inside awk and missed the three-newline case entirely, because six lines is
   two whole records and the framing realigns; it printed an invented location,
   and this document claimed otherwise.
6. A single very long line makes `check-ids.sh` quadratic (20k chars → ~5s).
   Round 2 isolated this to the pre-existing `draft_re` scan, where `main` is
   *slower* than this branch, so it is not this change's to fix — but it is
   real and it is now written down.
7. Untouched, each its own change in the announced split: draft IDs under
   `.guardrails/` are still invisible to finalization and to `check-ids.sh`;
   `guardrails_version` is still `0.1.0` across four behaviour-changing
   releases; there is still no inert way to write about an ID.

## Independent review

### Round 1 — **REJECT**, two blocking findings

One reviewer, given the diff, the worktree and the upstream source, with every
file-mutating probe run in throwaway clones. It reproduced all three defects on
`main` independently, rebuilt the fixtures rather than reusing mine, re-ran 7 of
the 10 mutation rows and matched them exactly, and confirmed the corpus and
`^.+` timing claims. It also found two blocking defects and nine smaller ones.

The two blocking findings, and what closed them:

**1. The AC5 lint was a false green.** It searched for one *spelling* of the
regex — the doubled-backslash form it was written against. The reviewer restored
a genuine hand-rolled copy written with single quotes and the suite stayed
green, with the test's own name (`gr_def_re is the only site`) asserting
something false: four hand-rolled copies were live at the time.

Rewritten to match the *shape*: strip backslashes and both quote characters,
then look for `**…-[0-9]…**:` however it was spelled. It scans every
`scripts/*.sh` rather than a hardcoded three, and pins a per-file count, because
five copies genuinely cannot use `gr_def_re` — eight awk-dialect block parsers,
the awk scan added here, and the DRAFT form, which is a different form. Verified
against **both** bypasses: the reviewer's single-quote copy (`check-trace.sh`
8→9) and the `[0-9][0-9][0-9]+` spelling (`finalize-ids.sh` 1→2). Renamed to
what it can actually prove.

**2. `UNANCHORED-DEF` had a second ceiling.** `_maxes` scanned the worktree
only, while `finalize-ids.sh` mints from `max(base, worktree)` — two gates with
two ceilings, which is precisely the defect class this change exists to end. The
reviewer reproduced both directions, including a report whose text
(`above PR-005, the highest one defined`) the toolchain contradicted one command
later by minting `PR-951`.

The ceiling now counts the base ref. The residual — a token that exists only on
the base and is deleted by this change stops reserving its number silently — is
stated in the code and left deliberately: the change deleted it.

### Round 1's other findings

| # | Finding | Disposition |
| --- | --- | --- |
| 3 | `gr_prefixes` re-invoked once per candidate file: **0.12s → 18.6s** on a 4000-item tree, 12 of the 18 seconds in that one line | Fixed by the same rewrite — the prefix list is split from the alternation the shell already validated, and there is now one awk for the whole scan. Re-measured; the figure this row first carried did not reproduce for round 3, and the current one is in **Runtime** above with the generator that produces the tree |
| 4 | A quoted non-ASCII filename made `awk` fatal, the file was skipped, and the gate exited 0 — a false green introduced by this change | Fixed: nothing opens a file by name any more. Test added, and `core.quotePath=false` made load-bearing by asserting the path prints readably (mutation showed the flag was otherwise untested) |
| 5 | A new test passed for a different reason than its name: the in-tree gate fired, so it stayed green with the base-side scan stubbed out | Fixed by asserting the `(already defined on main)` suffix, which only the base gate emits. Re-verified by stubbing that scan: the test now reddens. Removing the base definition instead would have made it a *relocation*, which is suppressed by design |
| 6 | README claimed the three scripts "cannot drift apart" (the awk copies can) and omitted the above-the-ceiling rule entirely | Both corrected |
| 7 | `UNANCHORED-DEF` documented nowhere an operator or agent looks, while `check-traceability/SKILL.md` tells an agent every such line is a violation | Added to `check-ids.sh`'s header under a new "Reports without failing" section, to the README script table, and to the skill's rule table with what to do about it |
| 8 | A comment claimed the awk "can tell a leading definition from a later one" — the strip that did so was deleted as dead code 30 lines below | Gone with the rewrite |
| 9 | `gr_def_re`'s synopsis still said `LINE_PREFIX`; the plan's Task 1 still showed `${2:-}`, a different default from the shipped `${2-^}` | Renamed in the synopsis, the test name and the plan, with the amendment recorded |
| 10 | This record's M2 breakdown was wrong (the count was right) | Corrected, and marked as corrected |
| 11 | `max_final` harvested every digit run on a token, so a prefix carrying a digit (`R9-005`) was read as 9 and the next ID minted `R9-010` — while this change's new ceiling scan read it correctly, creating a fresh disagreement | Fixed: the digits after the last hyphen, in both places. Pre-existing on `main`, so not a regression, but it is the exact class AC4 is about |
| 12 | No unit test pinned the empty-`POSITION` contract; the two new scans swallowed `git grep` status | Test added at the constructor (**M11** reddens it — this row said M14 until round 3 caught that the numbering had shifted when the table grew). Both scans check status and `gr_die` above 1, though see Open gap 4: the `gr_die` itself is pinned by nothing |

### Post-round-1 measurements

Deliberately no figures here. This section used to repeat the suite totals,
the corpus result and a runtime, and every one of them went stale the moment
round 2 landed — leaving two different runtimes for one measurement in a single
document, which is the failure `tests/evidence.sh` exists to end. The current
numbers live in **The gate**, **Corpus regression** and **Runtime** above, once
each.

What round 1 changed, in kind rather than in numbers: the base-ref ceiling is
consulted only when a candidate first clears the cheap worktree ceiling — the
combined ceiling is never lower, so what survives the cheap filter is a
superset, and on a healthy project the expensive scan never runs. Round 2
differentially fuzzed that reasoning over 60 randomised trees and found no
divergence from an always-combined variant.

### Round 2 — **REJECT**, one blocking finding

Given the round-1 record as well as the diff, and asked to attack the fixes.
It reproduced everything it reported, ran every probe in throwaway clones, and
left the worktree clean.

**1 (blocking). The lint was still a false green.** The rewrite changed *which*
spelling the test was blind to, not the fact that it was blind to one: it
required the literal six characters `-[0-9]` on a single physical line. The
reviewer defeated it twice — `[[:digit:]]` in place of `[0-9]`, and the original
spelling split across two lines — and then replaced **every `gr_def_re` call
site in the whole tree** with hand-rolled copies while the suite stayed 168 ok
and the test named "gr\_def\_re is the only site" stayed green.

The record had claimed the rewrite was "verified against both bypasses". Both
of those bypasses happened to contain the token being searched for. Verifying
against two spellings that contain your search string does not establish that
you match the shape — that is the same error as round 1, made once more.

The fix takes the reviewer's advice and stops trying to prove a negative with a
regex. The test now pins the **positive**: the number of `gr_def_re`
*invocations* per script (7/0/2/2/0), which cannot be out-spelled — replace a
call site with anything at all and the count drops. The shape check is kept as
defence in depth for a copy *added* without a call site being removed, with
digit-class spellings folded first. Verified against all three of round 2's
bypasses and against an added copy; renamed to what the pair can prove.

### Round 2's other findings

| # | Finding | Disposition |
| --- | --- | --- |
| 2 | `UNANCHORED-DEF` still judged against a worktree-only ceiling when there is no usable base — a detached HEAD, "what a normal CI checkout produces" — while the header claimed the base was always counted. Reproduced: the same false ceiling claim round 1 rejected | Fixed. With no usable base the line now ends "the base ref was not consulted, so this may be a false alarm", and the header says so. Pinned by a detached-HEAD test; M14 reddens it |
| 3 | AC6 was half met: unanchoring the **REQ** or **PR** awk block parser reddened **nothing**. The agreement test covered only LLR and SDD, while the plan, the README and this record all said "the block parsers" | Fixed. All four are now pinned, each by an assertion naming the verdict its parser would produce (`UNANALYZED-DERIVED`, `UNRESOLVED-PR`, `UNSATISFIED-LLR`, `UNTRACED-DESIGN`). Rows M16.REQ/PR/LLR/SDD. The first attempt at the REQ half passed for the wrong reason — the indented line sat inside REQ-001's still-open block — and is now in its own file |
| 4 | This record's mutation table was stale and self-contradictory: 10 rows against a claim of 14, a cited M14 that did not exist, three stale counts, and **two different runtimes for one measurement** (2.86s and 2.31s) — exactly what `evidence.sh` exists to stop | Every row below re-derived against the shipped tree after all round-2 fixes. One runtime figure per measurement, in **Runtime** above. The `^.+` cost had been quoted as 33s and then 26s; it is corpus- and load-dependent, so the code comments now say "tens of seconds" and point at that section instead of carrying a number |
| 5 | README claimed all three scripts build their shell patterns from one constructor; the base-side scan carries a literal ID and anchors by hand | Corrected — the exception is now named where the claim is made |
| 6 | `UNANCHORED-DEF` was documented in `check-traceability` but not in `merge-change` or `verify-before-merge`, which are where an agent meets check-ids output and is told to expect "pristine output" | Added to both, each saying it is not a violation |
| 7 | The three `git grep` status checks added for round 1 were pinned by nothing | Still true of two of them, and now stated plainly in Open gaps rather than counted as covered. The candidate scan is probed outside a pipeline so its status is real |
| 8 | A colon in a path ate the line number: `path:line:text` was split on the first two colons | Fixed by NUL framing (`git grep -nz`, converted to three-line records). The NUL cannot be passed as an `awk -v` value — execve arguments are NUL-terminated — and cannot survive `$( )` either, so the grep is piped straight into awk. A path containing a *newline* would still slide the framing; that case is now detected and reported as unreadable rather than given an invented location |
| 9 | A single very long line makes `check-ids.sh` quadratic — isolated by the reviewer to the pre-existing `draft_re` scan, where `main` is slower than this branch | Recorded, not fixed. It is not this change's, and fixing it belongs with whatever revisits that scan |

Two process failures of mine are worth recording, because both destroyed work
rather than merely wasting time. **Twice** I ran a mutation batch ending in
`git checkout -- scripts/` while my own fixes were still uncommitted, and lost
them; the second time I committed the reverted state before noticing. And
**twice** an apostrophe inside a single-quoted awk program closed the quote and
left a script that could not be parsed — each time surfacing as thirty-odd
unrelated test failures. The second now has a named test,
`every script parses as POSIX sh`. The first got worse before it got a fix —
see below.

### The mutation batch put the defect back into HEAD

The third and worst instance of the same mistake, recorded here because it
reached a commit rather than a working tree.

A mutation batch was running in the background while I ran `git add -A` for a
documentation commit. At that instant the batch had **M3** applied — the row
that reverts `max_final` to its own unanchored regex — so the commit staged it.
For one commit, `HEAD` on this branch carried **the exact defect this change
exists to fix**: `finalize-ids.sh` matching the definition form anywhere on a
line, minting `PR-901` over a token in prose.

It compounded. Every subsequent `git checkout -- scripts/` in the batch restored
`scripts/` to that clobbered `HEAD`, so **every mutation row from M3 onward was
measured against a broken baseline**. The table those rows produced was
nonsense, and the way it announced itself is worth keeping: `M4`, which mutates
`check-trace.sh`, appeared to redden two `finalize-ids.sh` ceiling tests it
cannot possibly affect. A number nobody can explain is a number nobody has
derived.

What caught the clobber was the suite — specifically the two tests written this
round against round 3's findings, `every gr_def_re call site is still a call
site` and `poisoning gr_def_re changes every gate's verdict`, alongside both
ceiling tests. The tests did their job. I had not run them after that commit,
which is the actual failure. `scripts/finalize-ids.sh` was restored from
`59c3ced`, all five scripts verified identical to it byte for byte, and the
mutation table above re-derived from the clean tree.

The lesson is not "commit before mutating" — that was already written down
twice here, and it happened anyway. It is that a batch which rewrites tracked
files must refuse to start against a tree it does not own, and must not leave a
window in which an unrelated `git add -A` can see its work. That belongs in
whatever change next touches `tests/evidence.sh` and the mutation tooling; it is
recorded here and nowhere else yet, which is itself a gap.

### Round 3 — **REJECT**, two blocking findings

**1 (blocking). The lint was a false green for the third round running.** Three
new bypasses, all reproduced, all leaving the suite at 171 ok with the test
green: a **comment** carrying the call-site text so the count stayed at 7 while
the real call became a hand-rolled copy split across lines; a **real call whose
result is overwritten on the next line** by a copy spelled `[-][0-9]`, which the
shape pattern cannot see because `[-][0-9]` contains no `-[0-9]`; and
**`gr_def_re` redefined inside `check-ids.sh` itself**, which left all seven
"call sites" calling a hand-rolled copy.

Three root causes, each sufficient: `grep -c` counts matching *lines*, including
comments and strings; the shape check is still a regex describing regexes; and
nothing checked that the name `gr_def_re` at a call site resolves to `lib.sh`.

This is the same mistake three times — verifying against spellings that happen
to contain the search string — so the fix stops proving a negative with text.
A new test **poisons the constructor**: it appends a `gr_def_re` that returns a
pattern matching nothing to the end of `lib.sh`, where shell rules make it win,
and asserts that all three gates change verdict — `check-ids.sh` stops seeing a
duplicate, `check-trace.sh` counts drop to zero, `finalize-ids.sh` mints
`PR-001` over an existing `PR-005`. A script with its own copy, or one that
calls the real constructor and ignores it, keeps working and is caught by
exactly that. **Verified against all three of round 3's bypasses**; each
reddens. The text checks are kept as defence in depth for a copy added without
a call site being removed.

**2 (blocking). `UNANCHORED-DEF-UNREADABLE` did not detect the case it names.**
The guard asked whether a record's second line was numeric, which catches a path
carrying one newline and misses one carrying three: six lines is exactly two
whole records, the framing realigns, and the scan reported `(d:1 — …)`, a
location that does not exist. Both the code comment and this document claimed
otherwise.

Fixed by detecting the cause instead of the symptom — `git grep -lIz` lists the
files the scan will read, raw and NUL-separated, so any newline in that stream
came from inside a name. The run then reports `UNANCHORED-DEF-UNREADABLE` and
judges nothing, rather than judging wrongly. Two tests pin it, at one newline
and at three. The awk-side check is gone: with the cause detected up front it
was unreachable.

### Round 3's other findings

| # | Finding | Disposition |
| --- | --- | --- |
| S1 | Three different figures for the `^.+` cost — 26s in two code comments, 33s in a correction, 21.4s in a table; the reviewer measured 22.5s | The number moves with corpus size and load. Both code comments now say "tens of seconds" and point at **Runtime**, which carries one measurement against a pinned corpus commit |
| S2 | Two runtimes for one measurement still live in the record, after round 2 rejected exactly that | The post-round-1 section no longer carries figures at all. Every number lives in one place |
| S3 | The 4000-item baseline did not reproduce — `main` measured 0.09s against the recorded 0.25s, turning a real +230% into a reported +20%, with no generator checked in | Re-measured (**0.11s → 0.49s**) and the generator is now recorded in **Runtime** so the tree can be rebuilt |
| S4 | Open gap 4 said two of three `git grep` status checks were unpinned; it is three of three | Corrected. Running the probe outside a pipeline makes its status real, which is not the same as its `gr_die` being tested |
| S5 | `UNANCHORED-DEF-UNREADABLE` was documented nowhere — round-1 finding 7's exact class, reintroduced by round 2's fix | Added to `check-ids.sh`'s header, the README script table, and all three skills |
| S6 | The corpus row pinned no commit, and `dev` had moved: 326 items today against the recorded 293 | Pinned at `506fce5b`, counts restated, and the fact that two of the three comparisons are between empty outputs is now said plainly |
| N1 | A disposition cited "M14 reddens it" after row numbers shifted; it is M11 | Corrected, with the reason |
| N2 | The guard enumeration double-counted the block-parser test — nine guards described as ten | Replaced with a one-to-one table |
| N3 | "Eight awk-dialect block parsers" versus Open gap 1's "four": there are four parsers spelled by eight patterns, and **only the four openers were pinned** — unanchoring a closer reddened nothing | All eight are now pinned. A closer that fires on an indented bold line truncates the block and drops the annotation after it; the new test asserts the finding that would be lost, for each of the four. The first attempt missed SDD, whose annotation sat on the definition line where truncation costs nothing |
| N4 | The two-stage design calls `candidates()` twice, so a tree edited between them yields a report from a different snapshot than the ceiling | Accepted, not fixed. Contrived, and the alternative is a temp file needing cleanup on every exit path |
| N5 | `[[ "$output" == *"REQ 1"* ]]` also matches `REQ 12` | Every count assertion now matches the whole `checked:` line |

Round 3 also reproduced clean what the previous rounds fixed: the `consulted`
flag correct on every base path it could construct (detected, named, tag,
invalid, detached, unborn, empty repo), 12 mutation rows matching exactly, the
`core.quotePath` redundancy, and the deleted strip's reasoning.

### Round 4

Not yet run. Three rounds, three REJECTs, and every blocking finding so far has
been a test of mine rather than the gate it tests.
