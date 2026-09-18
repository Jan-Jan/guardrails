# Verification — restore-mutation-evidence (2026-09-17)

branch: restore-mutation-evidence
reviewer: two independent subagent reviewers, dispatched separately with no implementation narrative — one on the mutation edits and retirements, one on the attribution, problem reports and record
verdict: approved after two blocking findings were fixed — a stale attribution method and a stale gate figure, both in the record rather than the corpus; 24 findings in total, all dispositioned below
reproduced: yes — `tests/mutations.bats` test 1 was written first and watched failing, naming all 46 unusable mutation scripts by path, before any script was repaired. The 46 were then checked name-for-name against the census in the decision record rather than accepted as a count.

Change: every committed mutation script either applies at HEAD and is still
killed by a test, or declares itself retired with a stated reason — and a gate
keeps it that way. Branched from `main` at `8d78cd4`, and merged with `main` at
`650f090` before the gates below were measured — the base advanced during the
change, and `650f090` touches `check-trace.sh`, `lib.sh`, `check-review.sh` and a
mutation script, so every figure here was re-measured after that merge rather
than copied from before it.
Plan: `docs/plans/2026-09-17-mutation-evidence-implementation.md`.
Decisions: `docs/plans/2026-09-17-mutation-evidence.md` (D1–D7).

## The gate

Every figure derived from the tree under test. Exit statuses read directly,
never through a pipe — the first attempt at the bottom four rows piped each
script into `head` and read `head`'s status, which would have recorded four
inapplicable gates as passes.

| Gate | Result |
| --- | --- |
| `tests/.bats-core/bin/bats tests/*.bats` | **`1..719`, 719 ok, 0 not ok, exit 0** — measured at `bd8cdf6`, the base merge |
| `tests/mutate.sh` | **exit 0** — `167 applied, 17 retired, 0 unusable` |
| `tests/mutations.bats` | 7 tests, 0 not ok |
| `tests/skills.bats` (writing scan) | exit 0, 0 not ok |
| `tests/portability.bats` | 0 not ok |
| `check-ids.sh` | **exit 2 — inapplicable**, `.guardrails/config.yaml` not found |
| `check-trace.sh` | **exit 2 — inapplicable**, same cause |
| `check-review.sh` | **exit 2 — inapplicable**, same cause |
| `finalize-docs.sh` | **exit 2 — inapplicable**, `doc_srs` path does not exist here |
| Coverage | not configured in this repository |
| Working tree | clean |

The four exit-2 rows are the standing condition of this repository: guardrails
does not install its own tooling into itself, so there is no config for those
gates to read. They are reported with their evidence and never as passes. Because
`finalize-docs.sh` cannot run, `merge-change` step 3's rename was performed by
hand and committed separately.

The suite total is 712 at `650f090` plus the seven in the new
`tests/mutations.bats` — 719.

**This row was wrong twice, and both times for the reason this change exists.**
It first recorded `1..697` and five tests, measured at `14134a0`; two further
tests — the retirement pin and the name-glob arm, both written in response to
attacks on the gate — arrived after it and the suite was not re-run. Independent
review caught that (finding-11). It was then re-measured at `587140f` as
`1..699`, which went stale within the hour when `650f090` arrived on the base
with 1,782 lines across `lib.sh`, `check-trace.sh` and `check-review.sh`. The
figures above are measured at `bd8cdf6`, after that merge.

A figure in a verification record has a shelf life measured against a moving base
branch, and the only safe rule is the one `merge-change` step 6 already states:
re-run after the base merge, and read the figures from that run and no earlier
one.

## Red → green

This change implements no REQ/LLR — guardrails keeps no requirements ledger of
its own yet — so the rows are keyed by the problem reports and by the gate.

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-dy8yup` | `mutations: every committed mutation applies or declares itself retired` | Watched failing before any repair, naming all 46 unusable scripts, with the per-directory split 11/10/4/9/12 confirmed against the census. Now green at `167 applied, 17 retired, 0 unusable`. |
| `PR-hcqjk6` | `mutations: a mutation that exits 0 having changed nothing is reported` | The tree-checksum arm was watched failing with the `before`/`after` comparison deleted from the runner: the silent mutation was counted as applied and the runner reported `1 applied, 0 unusable`. |
| gate reach | `mutations: a directory containing no mutation scripts is an error, not a pass` | Watched failing when `command -v python3` was broken to an unrelated exit 2 — status 2 alone satisfied the loose assertion, so the assertion was tightened to the runner's own message. |
| positive control | `mutations: a mutation whose anchor no longer matches is reported` | Watched failing when the absolute-path handling was removed from the runner: every fixture mutation exited 127 without running, and the pre-tightening assertion had passed on that. |
| retirement | `mutations: a retired script is counted, not run` | Watched failing with the `# retired:` check deleted: the fixture's `exit 77` appeared in the output, proving the script had been executed. |

## What was wrong, and what was built

184 mutation scripts are committed under `docs/verification/*.mutations/`. Each
reverts one production change so the suite can be re-run against the defect and
the tests that detect it named. Each quotes a line of the script it mutates
verbatim.

**46 could not apply at `8d78cd4`.** `PR-dy8yup` recorded 18, measured at
`860dce4` three weeks earlier. Nothing reported the growth because nothing looked.

Attribution is measured, not inferred: the scripts **as they stood at `8d78cd4`**
were run against the tree on each side of each candidate commit, and only scripts
that flipped from applying to not applying are counted.

The corpus must be named. Re-run with the repaired scripts this change ships, the
`860dce4` column reads 5 rather than 6 — M08's re-cut anchor no longer quotes the
`owner` field that commit removed, so it now applies on both sides. Independent
review measured this, and it is the reason the sentence names a revision instead
of stating "today".

| Commit | Subject | Broke |
| --- | --- | --- |
| `c672c9f` | item IDs are random tokens minted when the item is written | 11 |
| `0a35669` | the unit machinery — a manifest scopes every gate | 13 |
| `3fe5eb3` | every case pattern opens with `(` | 9 |
| `860dce4` | an open problem item needs no `owner:` | 6 |
| `47cde0b` | an item block ends at the next item, not at any bold line | 6 |
| — | never applied (`PR-b7ua4s`) | 1 |

`3fe5eb3` closes a loop on itself. It exists to fix `PR-vh6cud` — bash 3.2 cannot
parse a case pattern's unbalanced `)` inside `$(...)` — and it gated that defect
as a class by sweeping every `case` pattern in the repository. Doing so rewrote
nine lines a mutation quotes. The change that made the toolkit stricter did the
most damage here.

**The instruction that would have prevented this already existed.**
`skills/develop-change/SKILL.md` step 6 tells an author to grep the mutation
directories after editing an output line, states the remedy, and cites `bb7eee5`
as precedent. It is correct and it depends on being remembered. That is the
argument for D3: a step nobody runs is not a control.

### The figure was 38 until the runner existed

Reading each script's exit code finds 38. The runner finds 46. Eight exit **0**
while changing nothing — five awk scripts counting `GR_SCAN_EXCLUDE` occurrences
that no longer exist, three `s.replace()` calls with no assertion that rewrite
the file identically. Their own report is success.

`tests/mutate.sh` therefore does not consult the script's account of itself: it
checksums the scratch tree before and after, from outside. **59 of the 184
scripts contain no self-guard at all**, including all 33 under `review-artefact`,
so the eight are the visible part of a standing exposure — `PR-hcqjk6`, resolved
by the one central check rather than by 59 edits a sixtieth would omit.

### Disposition of the 46

- **29 re-anchored** to the current text, each expressing the same defect as
  before. 27 proved to apply and to be killed; one masked (M39, below); one
  survivor (M29, below).
- **16 retired in place** with a declared reason and the commit that removed the
  behaviour. The files stay put: three merged records tabulate these rows by
  number, and a reader following `M18` to a missing file cannot distinguish a
  deliberate retirement from a lost one.
- **1 retired as never having applied** — `review-artefact` M15, `PR-b7ua4s`.

### The kills

Every re-anchored mutation was applied in a scratch tree and the bats file for
the script it mutates was run. Representative rows, with the test that died:

| Mutation | Killed by |
| --- | --- |
| id-tokens M19 | `check-ids: MALFORMED-ID reports the lines that open one, not the lines that mention one` (4 tests) |
| id-tokens M20 | `check-ids: MALFORMED-ID is anchored to the declared prefixes` |
| id-tokens M23 | `check-ids: --allow-drafts is gone, and is rejected rather than ignored` |
| id-tokens M31 | `check-trace: a later item's open status does not reach the resolved item above` (18 tests) |
| review-artefact M03 | `check-review: run on the base branch it exits 2, never 0` |
| review-artefact M17 | `check-review: an unknown argument is rejected, not ignored` |
| problem-triage M18 | `check-trace: a bad limit is diagnosed before any gate runs` (control: pristine 0 not ok) |
| problem-triage M27 / M34 | 2 tests / 1 test — M27 removes both today-guards, M34 only the shell one, so the two have not collapsed into duplicates |
| config-schema M70 | `gr_check_config accepts the shipped config shape` (28 tests) |
| config-schema M90 | 0 in `tests/lib.bats`; killed on escalation by `check-review: an empty doc_verification value is rejected, not defaulted` |

**Four of the 29 score zero in the bats file named after the script they
mutate** — M90, M18, M19 and M20 all target `scripts/lib.sh`. The escalation step
in D1 is therefore not a fallback but part of the method, and the locality
assumption behind "run the script's own bats file first" does not apply. One
instance of it is recorded as `PR-8uggn4`.

## Findings this change made and did not fix

Four defects were found while proving kills. All pre-existed this change; none is
repaired here, because each repair is a change with its own reproduction and
review.

- **`PR-2c2k3p` — a genuine survivor.** id-tokens M29 applies and is killed by
  **0 tests** — `1..651` at `bd8cdf6`, after the base merge. It is not an
  equivalent mutant: with one derived-REQ
  fixture ID rewritten from `REQ-002` to a token and nothing else altered, the
  same test goes `ok` → `not ok`. The derived-REQ arm of `check-trace.sh` has no
  coverage for the only ID form minted since `c672c9f`. The LLR arm does.
- **`PR-tenhv4` — 67 inert assertions**, 65 when the item was written and two
  more arriving with `650f090` during this change. Under bash 3.2 a bare `[[ ]]` that is
  not the final command of a bats test body does not fail the test. Demonstrated
  on the real suite: an assertion rewritten to require `XYZZY-CANNOT-APPEAR`
  still reported `ok`. And it is masking a real defect — id-tokens M39 deletes
  `finalize-docs.sh`'s whitespace guard and `tests/finalize-docs.bats:120`
  reports `ok`; with its one inert assertion made live in the same mutated tree,
  the same test reports `not ok` and shows the rename running half-done. M39 is
  therefore killed in substance and unkilled as the suite is written.
- **`PR-8uggn4`** — `tests/lib.bats` states it covers "every key, scalar and list
  alike" and exercises only a list key.
- **`PR-b7ua4s`** — a mutation counted in a merged record's population without
  ever running.

## Review

Two independent reviewers, dispatched separately with the diff, the plan and the
decision record, and with no implementation narrative. Neither repeated the other's
checks. Together they raised 24 findings, of which two were blocking.

Both blocking findings are the defect this change exists to remove — evidence
that stopped being true and nothing noticing. That is not an irony worth
enjoying; it is the measure of how easily it happens.

**finding-1**: The 29 re-anchored mutations are honest. All 184 scripts applied
in a sandbox with diff fingerprinting: 167 apply and each produces a distinct
diff, so no two mutations in any directory now do the same thing, and the 17 that
do not apply each declare a retirement.
disposition: no change needed. This is a stronger check than the spot-check the
reviewer was asked for — sampling would not have shown the absence of collisions.

**finding-2**: M19 and M20 are attributed to `0a35669` in both plan files. They
break at `47cde0b`, measured: `main`'s M19 applies at `47cde0b^`, fails at
`47cde0b`, and fails at both sides of `0a35669`. The plan contradicts itself —
it names `47cde0b` correctly for M27-M31 seven lines earlier.
disposition: corrected in both plans and in the record's attribution table.
Re-measured independently: the six that break at `47cde0b` are exactly M19, M20,
M27, M28, M29, M31 — which is also the row the table had called "6 earlier and
unattributed". The table now accounts for all 46 with no residual row. The
shipped M19/M20 scripts name no commit, so no evidence artefact was wrong.

**finding-3**: M19 and M20 are honest re-cuts. `gr_def_re_loose` is
`printf '%s' "${2-^}\*\*(${1})-[^*]*\*\*:"`; its single call site passes one
argument, so M19's `${2-^}` → `${2-}` really does remove the line-start anchor,
and M20 still widens the prefix to any alphanumeric.
disposition: no change needed.

**finding-4**: M27's numeric pin is the same defect, not a weaker one.
`gr_block_init` is fed `body="$GR_ID_BODY"`, which is the alternation of the
six-character token and the legacy sequential form, so substituting
`[0-9][0-9][0-9]+` blinds the parser to every token minted since `c672c9f` —
exactly what the old `defre` did. M28, M29 and M31 are the same transform on
SDD, REQ and PR, and all four anchors are unique.
disposition: no change needed.

**finding-5**: M03 excises exactly the base-branch rejection. Only the end anchor
changed, and it had to: `dir=$(gr_verification_dir)` is now at line 70, before
the start anchor, so the original end anchor could no longer be found after it.
Applied, it removes precisely `check-review.sh:118-121`.
disposition: no change needed.

**finding-6**: triage M27 and M34 remain different, and M27's awk anchor is
byte-identical to `main` — only the leading `(` that `3fe5eb3` added was re-cut.
Applied, M27 removes both today-guards and M34 only the shell one.
disposition: no change needed. This was the specific risk named in the plan, and
the measured kill counts agree: M27 kills 2 tests, M34 kills 1.

**finding-7**: M60's `$GR_CONFIG` → `$_ff` rename is real — `0a35669` extracted
`gr_check_flat FILE` and `_ff="$1"` at `lib.sh:811`.
disposition: no change needed. One observation recorded rather than fixed:
`gr_check_flat` is now called for both `$GR_CONFIG` and `$GR_UNITS`, so M60's
blast radius is wider than when it was cut, not narrower. Its `# describes:` line
is still true but no longer exhaustive.

**finding-8**: M70 and M86 — the two most substantive config-schema re-cuts — are
faithful. M86 is the only one whose anchor changed shape rather than gaining an
argument, because `coverage_command` is no longer last in `GR_LIST_KEYS`; applied,
it deletes exactly the one line it always did.
disposition: no change needed.

**finding-9**: The retirement reason for scan-pathspec M18-M23 states that
`finalize-docs.sh` contains no `GR_SCAN_EXCLUDE` call site, while the same
sentence states that minting moved to `new-id.sh` — which does contain one, at
`new-id.sh:195`.
disposition: the reason now names that call site and records that id-tokens M36
and M10 mutate it, so retiring these six loses no coverage. Verified: M36's
anchor is that line.

**finding-10**: The attribution table's stated method — "today's mutation scripts
were run against the tree on each side of each commit" — no longer reproduces the
table. With the repaired corpus the `860dce4` column reads 5, not 6.
disposition: **blocking, fixed.** Reproduced: today's corpus gives 5 (M05, M06,
M23, M32, M36), the `8d78cd4` corpus gives 6 (those plus M08). The cause is M08,
whose old anchor quoted `(open, age unrecorded, owner %s)` — the very line
`860dce4` changed — and whose re-cut anchor omits `owner`, so it now applies on
both sides. The figure was right and the method sentence had gone stale the
moment the scripts were repaired. Both the plan and this record now name the
`8d78cd4` corpus and state the difference.

**finding-11**: The gate table recorded `1..697` and "five tests", measured at
`14134a0`. Two further tests arrived after it and the suite was not re-run.
disposition: **blocking, fixed.** The suite was re-run at `587140f`, the final
tree: `1..699`, 699 ok, 0 not ok. `tests/mutations.bats` has seven tests, not
five. `PR-2c2k3p`'s "0 of 697" was restated and M29's survival re-measured
against the 699-test tree rather than copied forward.

**finding-12**: The 17 retirements are sound — none of the retired scripts still
has a live target, checked by running every one against an extracted HEAD tree.
The `c672c9f` 8→3 consolidation, the six `finalize-ids.sh` call sites, and the
`owner` counts (11 at `860dce4^`, 0 after, 0 at HEAD) are all borne out by the blobs, and
every `awk -v n=` matches the site number its reason names.
disposition: no change needed.

**finding-13**: M15's retirement cites "differentially fuzzed over 8000 generated
records". Since M15 never applied to any committed `check-review.sh`, running it
produces no mutant, so that figure cannot be evidence about this script.
disposition: corrected. The retirement now rests on the invariant, stated
explicitly — `disposed` is written in exactly two places and read only inside
`gr_flush`, reachable only after a block open cleared it — and records that the
fuzz evidence concerns the behaviour rather than this script. The reviewer
verified that invariant independently by reading every read and write of
`disposed`, which is better evidence than the figure it replaces.

**finding-14**: The comment at `check-review.sh:165-166` still describes an
`open_line &&` guard that has never existed, and is the likely origin of M15's
false anchor. The change touches no production script, so the root cause outlives
its diagnosis, and this was not declared.
disposition: added to Gaps as gap 7. Not fixed here: editing a production script
to correct a comment is a change with its own review, and this change's scope is
the evidence corpus.

**finding-15**: `PR-dy8yup`'s corrected 46-entry `affects:` list is now above
the original prose enumerating "six, six, six", which accounts only for the 18
known in August.
disposition: a marker at the `affects:` line states that the list is the
corrected one and points at the reconciliation. The original observation is
deliberately preserved rather than rewritten.

**finding-16**: D2 states "The 11 whose behaviour is genuinely gone", while D5
tabulates 16 and the corpus declares 17.
disposition: corrected to 17, naming the 16 plus D7's never-applied one.

**finding-17**: "one survivor (M29, below)" is ambiguous — `review-artefact` M29
is a different script discussed in the same record.
disposition: disambiguated to "id-tokens M29".

**finding-18**: The declared-retirement path can silence the gate, and the pin at
`tests/mutations.bats` controls it while stating its own limit — nothing can tell
a true retirement reason from a false one, which is a judgement for review.
disposition: no change needed; that division of labour is the intent, and this
review is the half the gate cannot perform. Independently, all 17 retirements
were then checked against a live tree and none still applies, so the swap attack
this path would enable has no material.

**finding-19**: `PR-dy8yup` is honestly resolved — the symptom line and original
body are byte-identical, only `affects:` and `status:` changed, and the new list
is a strict superset of the old totalling 46.
disposition: no change needed.

verdict: approved after two blocking findings were fixed. Both were
evidence-currency defects — a method statement that stopped reproducing its own
table, and a gate figure taken before the last test arrived — in a change whose
subject is evidence currency. Neither was in the mutation corpus; both were in
the record describing it.

## Gaps

What this change did NOT establish.

1. **`tests/mutate.sh` does not derive the records' mutation tables.** It answers
   applicability only. Deriving a table needs one full-suite run per mutation
   against the tree of the day and would print today's figures under a merged
   record's heading. Three merged records — scan-pathspec, id-tokens,
   item-blocks — still head a table with "Derived by `tests/mutate.sh …`", a
   command that has **never existed in this repository** (`git log --all
   --diff-filter=A -- tests/mutate.sh` is empty; the `mutation-runner` branch it
   was promised from is gone). Those records disclose this in their own Gaps
   sections. The shipped runner shares their command's name and answers a
   narrower question, which is itself a trap for a future reader.
2. **A re-anchored mutation is proved killed, not proved killed by the same
   tests as when it was written.** The original kill sets are historical and
   several of the records state only an aggregate. D1 restores that a mutation is
   detected, not that detection is unchanged.
3. **M39's kill is not observable in the suite as written** — see `PR-tenhv4`. It
   is counted here as killed on the strength of a controlled experiment, not on
   the strength of a green suite.
4. **The 51 remaining scripts with no self-guard are unchanged.** `PR-hcqjk6` is
   resolved by the central check, which protects the corpus as it is run through
   `tests/mutate.sh`; a script run by hand still reports its own success.
5. **M29's survival is measured over 651 of the 719 tests, not all of them.**
   `tests/mutations.bats` cannot take part — inside a mutated tree the other 183
   anchors stop matching, so it fails for reasons unrelated to the mutation under
   test — and `check-signing.bats` and `finish-merge.bats` were omitted as
   exercising gpg and worktree removal, reaching no part of the collector. Naming
   the three is the honest form; "0 of 719" would be a figure nobody measured,
   which is finding-11's defect in a different place.
6. **Escalation runs in a `.git`-less extracted tree give one false failure.**
   `clanker: no file in scope contains the replaced vocabulary` fails there for
   want of a repository, mutation or not — confirmed by control. It was nearly
   counted as M29's kill. Escalations should run in a real worktree.
7. **`tests/mutations.bats` cannot be part of an escalation run.** Inside a
   mutated tree the other 183 anchors stop matching, so it fails for reasons
   unrelated to the mutation under test. It was excluded by hand; nothing
   enforces that.
8. **The comment that caused `PR-b7ua4s` is untouched.** `check-review.sh:165-166`
   still describes "the `open_line &&` guard on the disposition rule below", and
   no such pattern-level guard exists — only the in-body `if (open_line)` at line
   228. That wording is the most likely origin of M15's false anchor, and M15's
   own retirement note now contradicts it while pointing at it. This change
   touches no production script at all (`git diff --name-only main HEAD --
   scripts/` is empty), which is deliberate scope discipline, so the root cause
   outlives the change that diagnosed it. Raised by independent review.
9. **The `2026-08-23-review-artefact.mutations` directory is dated a day before
   the `2026-08-24-review-artefact.md` record it supports.** Pre-existing and
   untouched.
10. **No requirement covers any of this.** guardrails keeps no SRS of its own, so
   the mutation corpus, the runner and the gate are unmarked derived work, as is
   everything else in this repository.
