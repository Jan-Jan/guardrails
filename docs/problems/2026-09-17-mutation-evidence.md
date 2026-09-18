# Problem reports — mutation evidence, and a test idiom that asserts nothing

`affects:` names files rather than item IDs for the reason
`docs/problems/2026-08-27-macos-awk.md` gives: guardrails keeps no REQ/SDD/LLR
ledger of its own yet.

Five items, all found while resolving PR-dy8yup. Two are about the mutation
corpus and are resolved by this change. The other two were found by tasks doing
something else, are wider than this change, and are left open deliberately —
each states why in its own note.

**PR-b7ua4s**: A mutation script whose anchor matched no version of its target
was counted in the mutation population of a merged verification record without
ever running.
affects: docs/verification/2026-08-23-review-artefact.mutations/M15.sh and the
mutation population stated in docs/verification/2026-08-24-review-artefact.md.
opened: 2026-09-17
status: resolved
The anchor `open_line && gr_kw_here(line, "disposition:") {` is in none of the
ten committed revisions of `scripts/check-review.sh`. At `f396c16`, the commit
the mutation was written against, line 216 already reads
`gr_kw_here(line, "disposition:") {` with no pattern-level guard. Because the
script calls `s.replace()` with no assertion, it rewrote the file identically
and exited 0.

**No coverage gap follows from this, and the mutation was not written
carelessly.** `scripts/check-review.sh:163-168` records the analysis: the guard's
substance is the in-body `if (open_line) disposed = 1` at line 228, and
`disposed` is cleared only where a block opens, so the guard cannot change any
verdict today — differentially fuzzed over 8000 generated records with zero
differences. M15 is an equivalent mutant. Retired in place with that reason
rather than rewritten, because an equivalent mutant does not belong in a kill
count. What the record overstates is a population by one row.

**PR-hcqjk6**: 59 of the 184 mutation scripts contain no self-guard, so a
mutation whose anchor stops matching rewrites its target identically, exits 0,
and reports success for having done nothing.
affects: docs/verification/*.mutations/ — all 33 under
2026-08-23-review-artefact, 16 under 2026-08-20-scan-pathspec, 10 under
2026-08-22-id-tokens.
opened: 2026-09-17
status: resolved
Measured, not estimated: eight of the 59 were already failing this way at
`8d78cd4` — scan-pathspec M12-M16 and review-artefact M15-M17 — and reading exit
codes alone put the stale population at 38 when it is 46. The other 51 are
correct today by luck rather than by construction.

Resolved by `tests/mutate.sh` rather than by editing 59 scripts. The runner
checksums the scratch tree before and after each mutation and does not consult
the script's own account of itself, so the check is in one place that cannot be
omitted instead of 59 that can. The 59 scripts are deliberately unchanged: a
per-script guard would have to be added again to every mutation written after
this one, which is the same dependence on memory that produced PR-dy8yup.

**PR-tenhv4**: Under bash 3.2, a bare `[[ ... ]]` that is not the final command
of a bats test body does not fail the test, so 67 assertions across five test
files are evaluated and their results discarded.
affects: tests/check-trace.bats (51), tests/check-review.bats (5),
tests/finalize-docs.bats (5), tests/check-ids.bats (3), tests/lib.bats (3).
opened: 2026-09-17
status: open
The count is of lines that are exactly a bare `[[ ... ]]` and are not the last
command in their test body. It deliberately excludes the 61 lines in
check-trace.bats that end `]] \` and continue into `|| { ...; false; }` — every
one of those was checked and every one resolves to a live guard, so they are not
at risk. A reader counting `[[` occurrences alone reaches a higher figure and is
counting working assertions among them.

**The count was 65 when this item was written and is 67 now.** `650f090` reached
the base branch during this change and added two more to `check-trace.bats`, both
`ORPHAN-ANNOTATION` assertions in tests that end with a live one. That commit's
author used the `|| { echo; false; }` form correctly elsewhere in the same diff,
which is the point: the idiom is right most of the time and silently wrong the
rest, and nothing reports the difference. The defect grows with the suite.
Reproduced twice. Directly:
`bash -c 'set -eE; trap "echo FIRED" ERR; [[ a == b ]]; echo reached'` prints
`reached` and exits 0 on `GNU bash 3.2.57(1)-release (arm64-apple-darwin25)`,
which is this machine's `/bin/bash` and the shell bats 1.11.0 runs test bodies
with; the same line with `[ a = b ]` fires the trap and exits 1. And on the real
suite: the first assertion of `check-trace: open PR warning coexists with real
failure exit 1` was changed to require the string `XYZZY-CANNOT-APPEAR`, and the
test still reported `ok`.

Only the LAST command of a test body decides the verdict, so in each of these
tests one assertion is live and the earlier ones are decoration. bash 4 and
later honour `set -e` here, so a Linux run would fail where macOS passes — a
platform-dependent false green, which is the exact class this toolkit exists to
remove.

**This is already masking a real defect, and the proof is in this change.**
Mutation `2026-08-22-id-tokens.mutations/M39.sh` deletes the guard in
`finalize-docs.sh` that rejects a draft ledger filename containing whitespace.
`tests/finalize-docs.bats:120` exists to detect exactly that. With M39 applied
the test reports **ok**. With its one inert assertion — line 130,
`[[ "$output" == *"whitespace"* ]]` — made live and nothing else altered in the
same mutated tree, the same test reports **not ok**:

```
OUTPUT WAS: DRAFT-my -> 2026-09-17-my notes.md
mv: rename docs/requirements/DRAFT-my to notes.md
    docs/requirements/2026-09-17-my notes.md: No such file or directory
guardrails: rename failed: ...
```

The filename split at the space, leaving the rename half-done — the precise
failure the test's own comment describes. The script still exits 2, because it
fails later during the rename instead of during planning, so the live
`[ "$status" -eq 2 ]` is satisfied either way. The only assertion that separates
"rejected before anything was rewritten" from "failed partway through rewriting"
is the inert one, and that distinction is the whole point of the test.

So this item is not a tidiness concern about an idiom. At least one guard in the
shipped toolkit currently has no working test, and the count of others in the
same position is unknown until the 65 are audited.

Left **open** rather than fixed here. The repair is an audit of 65 assertions in
five files that this change does not otherwise touch, and several will turn out
to be assertions nobody has ever actually checked — that is its own change, with
its own reproduction and its own review. It is recorded now so it appears at
every merge instead of being remembered. Related: the same shell version
produced PR-vh6cud (`docs/problems/2026-09-02-bash32-case-parse.md`), whose
tree-wide fix is `3fe5eb3` — the commit that silently broke nine of the
mutations PR-dy8yup is about.

**PR-8uggn4**: `tests/lib.bats` "gr_check_config rejects a key set to nothing,
whichever key it is" states that it covers "every key, scalar and list alike"
but exercises only `strict_paths`, a list key, so the scalar-emptiness branch it
names is never reached there.
affects: tests/lib.bats:510-525 and the `gr_check_config` scalar-emptiness arm in
scripts/lib.sh that no test in that file reaches.
opened: 2026-09-17
status: open
Found by measurement rather than by reading, while proving the kill for mutation
`2026-08-27-config-schema.mutations/M90.sh` under D1. M90 deletes the
scalar-emptiness arm. `tests/lib.bats` — the file for the script M90 mutates —
kills it 0 times; escalation to the full suite found it killed by
`tests/check-review.bats`, "check-review: an empty doc_verification value is
rejected, not defaulted". Controlled comparison on that file: pristine 0
failures, M90-mutated 1 failure.

So the arm IS covered and the merged record's "26 killed, no survivors" stands —
what is wrong is the claim `tests/lib.bats` makes about itself. The comment at
line 511-516 records the reasoning for widening the rule to every key; the body
was never widened to match.

Left **open** alongside PR-tenhv4 rather than fixed here. The repair is a new
scalar-key case in that test, and `tests/lib.bats` also contains three of
PR-tenhv4's inert assertions — auditing the file once, in one change, beats
touching it twice.

**PR-2c2k3p**: `check-trace.sh`'s derived-REQ collector is pinned to the shared ID
body by nothing any test observes, so if it were narrowed to numeric IDs only,
`UNANALYZED-DERIVED` would stop firing for every derived REQ with a token ID
and the gate would exit 0 having reported nothing.
affects: scripts/check-trace.sh (the derived-REQ block at the `gr_block_init("REQ",
body)` call) and tests/check-trace.bats, which exercises derived REQs only with
numeric IDs.
opened: 2026-09-17
status: open
Found by mutation, which is what mutation testing is for. Mutation
`2026-08-22-id-tokens.mutations/M29.sh` replaces the shared `body` argument with
the literal `[0-9][0-9][0-9]+`. Re-anchored under this change it applies
correctly and is then killed by **zero** tests.

Measured at `bd8cdf6` in a real git worktree, `1..651` with 0 `not ok`. That is
the 719-test suite less three files: `tests/mutations.bats`, which cannot take
part — inside a mutated tree the other 183 anchors stop matching, so it fails for
reasons unrelated to the mutation under test — and `tests/check-signing.bats` and
`tests/finish-merge.bats`, which exercise gpg and worktree removal and reach no
part of `check-trace.sh`'s derived-REQ collector. The figure is 0 of 651 actually
run, and the three omitted files are named rather than folded into a rounder
number.

Measured **after** the base advanced to `650f090`, which rewrites 82 lines of
`check-trace.sh` — the script M29 mutates — and adds 120 tests to
`tests/check-trace.bats`. The first measurement predated that commit and was
re-run rather than copied forward, because those 120 tests could have killed it
and that would have made this item wrong.

It is not an equivalent mutant. The derived-REQ fixtures in
`tests/check-trace.bats` all use numeric IDs — `REQ-001` and `REQ-002`, twelve
occurrences, no token among them — while token IDs are the only form
`new-id.sh` has minted since `c672c9f`. Change one fixture ID and the mutation
dies at once. Measured on `check-trace: derived REQ not assessed in RMF fails`
with its `REQ-002` rewritten to `REQ-a3k9z2` and nothing else altered:

| tree | verdict |
| --- | --- |
| token-ID fixture, no mutation | `ok` — UNANALYZED-DERIVED fires |
| token-ID fixture, M29 applied | `not ok` — it does not fire |

The LLR side of the same gate **is** covered for tokens, by `check-trace: a
token derived LLR absent from the RMF fails` and its neighbour. Only the REQ arm
is uncovered, so this is an asymmetry in the fixtures rather than an oversight
about tokens in general.

Left open: the repair is a token-ID derived-REQ test, which is a test-coverage
change with its own red → green, and D1 of this change's decision record states
that a mutation no test detects is reported rather than repaired by the change
that found it.
