# Restoring the mutation evidence — decisions

**Problem:** `PR-dy8yup`, open since 2026-08-27. Mutation scripts under
`docs/verification/*.mutations/` that can no longer apply their mutation. They
measure nothing, and nothing reports that they measure nothing.

**Census at `8d78cd4`:** 184 mutation scripts, **138 apply, 46 do not**. The
problem report states 18, measured at `860dce4`. Reproduce with
`tests/mutate.sh`, which this change ships (D4).

**The figure was 38 until the runner was built, and the difference is the
point.** Reading each script's exit code finds 38. Eight more exit **0** while
changing nothing: `scan-pathspec` M12–M16 count occurrences with awk and simply
find fewer than they want, and `review-artefact` M15–M17 call `s.replace()` with
no assertion, rewriting the file identically. Their own report is "success".

They are found only by checking the tree from outside — the runner checksums the
scratch tree before and after and does not take the script's word for it. **59 of
the 184 scripts contain no self-guard of any kind** (no `assert`, no `cksum`),
including all 33 under `review-artefact`, so this is the standing exposure and not
a quirk of eight files.

## Why this happened

Not rot. Five ordinary, correct changes edited lines that a mutation quotes
verbatim. Attribution is measured, not inferred — the mutation scripts **as they
stood at `8d78cd4`** were run against the tree on each side of each commit, and
the table below counts only those that flipped from applying to not applying.

Naming the corpus is not pedantry. Re-run with the **repaired** scripts this
change ships, the `860dce4` column reads 5 rather than 6: M08's old anchor quoted
`UNRESOLVED-PR %s (open, age unrecorded, owner %s)`, which is the line `860dce4`
changed, and the re-cut anchor no longer mentions `owner`, so M08 now applies on
both sides of that commit. A table like this is a statement about history and is
reproducible only against the corpus history acted on.

| Commit | Subject | Broke |
| --- | --- | --- |
| `c672c9f` | item IDs are random tokens minted when the item is written | 11 |
| `860dce4` | an open problem item needs no `owner:` | 6 |
| `3fe5eb3` | every case pattern opens with `(` | 9 |
| `0a35669` | the unit machinery — a manifest scopes every gate | 13 |
| `47cde0b` | an item block ends at the next item, not at any bold line | 6 |
| *(never applied — see D7)* | — | 1 |

`c672c9f` deleted `scripts/finalize-ids.sh` and, in the same commit, consolidated
`check-ids.sh` from eight `GR_SCAN_EXCLUDE` call sites to three — measured with
`git show <rev>:scripts/check-ids.sh | grep -c`, 8 at `7e9009b` and 3 at
`c672c9f`. That is 6 + 5 of the retirements from one commit.

`3fe5eb3` is the instructive one. It gated a **class** of defect across the whole
repository, and in doing so rewrote every `case` pattern — including the eight a
mutation script quotes. A change that made the toolkit stricter is the change
that silently deleted eight pieces of evidence.

`skills/develop-change/SKILL.md` step 6 already tells an author to grep the
mutation directories after editing an output line, and already states the remedy
("re-cut the anchor … and then prove the re-cut anchor applies AND still kills
tests"), naming `bb7eee5` as precedent. The instruction is correct and was not
followed. **A step that depends on being remembered is not a control** — D3.

## D1 — Re-anchor and prove the kill

The 27 whose behaviour under test still exists are re-anchored to the current
text. Each is then proved to **apply** and to **still be killed**.

Applicability alone is rejected. `PR-dy8yup` names the defect precisely: a
mutation that cannot apply is "an empty row that reads like a covered one".
A mutation that applies and that no test detects is the same empty row with a
better disguise, so restoring the first property without the second would close
the report against its own wording.

**A re-anchored mutation no test kills is a finding, not a green.** It gets its
own problem report and is reported in the record; it is never quietly restored.

Proof is targeted, not exhaustive. 27 full-suite runs at ~6 minutes each is
~2.7 hours and buys little: each mutation edits one script, so the bats file for
that script is run first. Only an apparent survivor escalates to the full suite,
and only a survivor of *that* is a genuine finding.

## D2 — Retire in place, with a declared reason

The 16 whose behaviour is genuinely gone keep their files and gain a header, as
does the one that never applied (D7) — 17 in all:

```sh
# retired: <why the behaviour no longer exists>, removed at <commit>
```

Deletion is rejected: three merged records tabulate these rows by number, and a
reader who follows `M18` to a missing file cannot distinguish a deliberate
retirement from a lost file. A `retired/` subdirectory is rejected for the same
reason — it moves files a merged record names.

The gate at D3 skips a script with this header, and counts it.

## D3 — The gate

`tests/mutations.bats` extracts a pristine tree, runs every mutation script in
it, and fails naming any that neither applies nor declares itself retired.
Measured cost: **32 s for all 184**.

A static check of "does the target file exist" is rejected. It detects the 6
deleted-target cases and none of the 27 anchor drifts, which are the dominant
cause — it would have caught nothing that actually happened.

The gate takes the reach guard `tests/portability.bats` already uses: if the
mutation directories are absent from a full checkout it fails rather than
passing, so renaming the directories cannot silently disable it.

## D4 — `tests/mutate.sh`, applicability only

`tests/mutate.sh` has **never existed in this repository**. No branch defines it;
`git log --all --diff-filter=A -- tests/mutate.sh` is empty, and the
`mutation-runner` branch it was promised from is gone. Three merged records head
a table with "Derived by `tests/mutate.sh …` — do not edit by hand".

This change ships `tests/mutate.sh` as the **applicability** runner — apply each
mutation in a scratch tree, report which fail, exit non-zero if any do. It is
what D3's gate invokes.

It does **not** re-derive the tables. That needs one full-suite run per mutation
against a historical tree, and the figures it produced would be today's, not the
merged records'. The three table headers remain historically true and are not
edited; this change's own record states what the shipped runner does and does
not do, so the gap is recorded where a reader meets it.

## D5 — The classification

**Retire (16)** — behaviour gone:

| Script | Reason |
| --- | --- |
| `2026-08-20-scan-pathspec` M18–M23 | `scripts/finalize-ids.sh` deleted at `c672c9f`; minting moved to `new-id.sh`, and `finalize-docs.sh` contains no `GR_SCAN_EXCLUDE` |
| `2026-08-20-scan-pathspec` M12–M16 | each targets `GR_SCAN_EXCLUDE` call site #4–#8 of `check-ids.sh`; `c672c9f` consolidated eight call sites into three, so these five have no target |
| `2026-08-25-problem-triage` M05, M06, M23, M32, M36 | `owner:` dropped at `860dce4`; `owner` appears 0 times in `check-trace.sh` |

**Re-anchor (29)** — behaviour intact:

| Directory | Scripts | Count |
| --- | --- | --- |
| `2026-08-22-id-tokens` | M09, M16, M19, M20, M23, M27, M28, M29, M31, M39 | 10 |
| `2026-08-23-review-artefact` | M03, M16, M17 | 3 |
| `2026-08-25-problem-triage` | M08, M18, M27, M34 | 4 |
| `2026-08-27-config-schema` | M60, M70, M73, M74, M76, M83, M85, M86, M87, M88, M89, M90 | 12 |

M27–M31 were nearly retired in error. Their premise — a per-prefix parser with
its own numeric body instead of the shared one — reads as gone, because `defre`
was removed from `check-trace.sh` at `47cde0b`. It was refactored, not removed:
`check-trace.sh:417` is now `gr_block_init("LLR", body)` with
`body="$GR_ID_BODY"`. The mutation is still expressible and still meaningful,
because `GR_ID_BODY` is `(${GR_ID_TOKEN}|[0-9][0-9][0-9]+)`, so pinning a parser
to the numeric arm blinds it to every token ID minted since `c672c9f`.

Two mutations change target file. M19 and M20 quote a regex literal that
`47cde0b` extracted from `check-ids.sh` into `gr_def_re_loose` in
`scripts/lib.sh`. The behaviour they name — the scan anchored at line start, and
judging only declared prefixes — is `lib.sh:664-666`, so that is where they are
re-cut.

`review-artefact` M15 is in neither list. See D7.

## D7 — A mutation that never applied, over a guard that cannot be observed

`2026-08-23-review-artefact/M15.sh` replaces
`open_line && gr_kw_here(line, "disposition:") {`. **That string exists in no
committed version of `scripts/check-review.sh`** — all ten revisions of the file
were searched, and `f396c16`, the commit it was written against, already reads
`gr_kw_here(line, "disposition:") {` at line 216 without a pattern-level guard.
M15 therefore never applied, and because the script calls `s.replace()` with no
assertion it exited 0 and was counted in a merged record's population.

**It was not written carelessly, and the behaviour is not uncovered.** The
author investigated this exact mutation and recorded the result in the source,
at `check-review.sh:163-168`:

> An INVARIANT this function relies on, recorded because a reviewer proved no
> test can see it: `disposed` is cleared only where a block OPENS, and never
> here. That is what makes the `open_line &&` guard on the disposition rule
> below unable to change any verdict today (mutation M15, differentially fuzzed
> over 8000 generated records with zero differences). Let a block open by any
> other route and the guard becomes critical with no test to notice.

So M15 is an **equivalent mutant** — a mutation that provably changes no verdict
— and no test can kill it by construction. The guard's substance does exist, as
an in-body `if (open_line) disposed = 1` at `check-review.sh:228` rather than as
the pattern-level form M15 quotes. The defect is narrow and real: the script as
committed matched nothing, so it was neither a kill nor a recorded equivalent
mutant, but a silent no-op inflating a population count by one.

It is **retired** with that reason, citing the invariant so the next reader
reaches the fuzzing evidence rather than re-deriving it. It is deliberately not
rewritten to apply: a mutation that cannot be killed does not belong in a kill
count, and one written in 2026-09 and placed in a 2026-08 record's evidence
directory is new evidence wearing an old date.

`PR-b7ua4s` records the population overstatement, and states explicitly that no
coverage gap follows from it.

## D6 — The problem report

`PR-dy8yup`'s `affects:` list names 18 scripts and is wrong. It is amended in
the dated file that defines it — `docs/problems/2026-08-27-signing-and-identity.md`
— to the measured 46, and resolved in this change. `resolve-problem` step 2
requires the `affects:` list to track the real scope; a resolution against a
list that understates the population by more than half would close a different
problem from the one that exists.

Two further problem reports are opened by this change: D7's never-applied
mutation, and the 59 scripts with no self-guard — the second is mitigated by the
runner rather than fixed in the scripts, and is recorded so that the mitigation
is attached to a stated defect.
