# Verification — base-premise-lapsed (2026-10-13)

branch: base-premise-lapsed
reviewer: three independent Claude subagents with fresh context, one per
round, each in its own task worktree off the change branch, each given the
diff, AGENTS.md, the review checklist and the two colliding features, at
`bfa53cb`, `07c700d` and `b7711f2`; the TEST guideline review ran in a fresh
context of its own against `docs/TEST_GUIDELINES.md` at `d997967`
verdict: converged at round 3 — no `code` or `requirement` finding above low in
that round, which `review-checklist.md` makes the last one. Round 1 raised
eight findings, round 2 five and round 3 six; the guideline review raised two.
Every one is fixed, and no round found a `code` finding above low at all.
reproduced: not applicable. PR-z83ka9 is a lapsed premise in a decision record,
not a defect in a script, so it is observable rather than reproducible. At
`be9cfa6`, `origin/main` defined seven PR IDs that no local ref defined —
PR-8zcc72, PR-ad4vmm, PR-cjvv8g, PR-gw6wts, PR-nhf8cy, PR-qm5gfy and PR-x63ejd
— while local `main` defined PR-8um9a9 and PR-z7w5bf that `origin/main` did
not. The reviewer checked each of the nine independently. No gate misreported,
and no script changed for this item.

Change: ADR-y8jmes's Scope states that its condition is about the machine, not
the maintainer, and that reconciling local `main` with the remote is the
maintainer's call. A second paragraph states what reconciling can and cannot
mean under a squash merge. AGENTS.md non-negotiable 4 states the same where an
agent reads the rule. The change also carries in the content merged on the
other machine, resolving conflicts in `scripts/check-trace.sh` and
`tests/check-trace.bats`. Resolves PR-z83ka9.

Branched from `main` at `be9cfa6`; base merged from local `main` at `baa983f`,
per AGENTS.md non-negotiable 4. `main` moved twice while this change was open
(`0c11d77`, then `baa983f`) and was merged in each time.

## The departure from non-negotiable 4, and whose it is

This change merges `origin/main` at `d015a48`. **The user fetched, asked for
the divergence to be checked, and then ruled explicitly that the
reconciliation be carried out inside this change.** The agent did not fetch,
did not push, and did not take `origin/<branch>` as the base: the base is local
`main` at `baa983f`, as the line above records. The agent ran
`git merge origin/main` in the change worktree on 2026-10-13 on that
instruction, and that merge is commit `70a9a7b`. The rule as this change now
states it permits exactly that and no more.

## What a squash can and cannot reconcile

`merge-change` step 7 integrates with `git merge --squash`, so `cfa82e1` and
`d015a48` do not become ancestors of local `main`. After this merges, `main`
holds their content — which is what step 4's `DUPLICATE-ID` scan reads, so the
scan is genuinely fixed — while `git merge-base main origin/main` still names
`1967dc8`, the commit the two machines last shared. The remote relationship
stays diverged and the next push is not a fast-forward. **That decision is the
user's and this change does not make it.**

## The conflict resolution, and why it reads this way

Both machines rewrote the same region of `scripts/check-trace.sh`:

- local `main` (`be9cfa6`) made a credit belong to the block it is written in,
  with `credit_scan` the one reader of `implements:` and of `mitigates:`;
- the other machine (`d015a48`) took RC and HAZ out of force by supersession,
  and to do it taught `oof_scan` to emit its own `I` and `M` credit records,
  intersected with the line-wise `ids_matching`.

Those cannot both stand: D2 of the block-attributed-credits change allows ONE
reader per keyword, so that no two gates disagree on what a line credits. The
resolution keeps `credit_scan` as that reader and keeps every out-of-force
FACT from the other machine. `oof_scan` reports which items are out of force,
now across the RC, HAZ and REQ/LLR families, and emits no credit records. The
gates intersect `credit_scan`'s records with those IDs: an out-of-force RC owes
no `implements:` and its `mitigates:` credits nothing; an out-of-force HAZ owes
no `mitigates:`. The two machines' separate fixes for the same gitignored-file
finding collapse into the shared `unignored_files`, now applied to the RMF list
too. The task prose of the other machine's plan, and its verification record,
described the withdrawn half and are corrected here.

**What the withdrawal costs, stated plainly.** The other machine's intersection
also narrowed one case this resolution gives up: an `implements:` inside a REQ
block of an SRS file that `git grep -I` treats as binary now credits its RC
where that REQ is also defined in a text file, which is what `ids_defined` and
the `defined_req_flat` filter still require; a REQ defined only in the binary
file credits nothing either way. `d015a48` reported `UNIMPLEMENTED-CONTROL` for
the first case. That is not a regression
against local `main`, which shipped exactly this and records it as a known
follow-up in the block-attributed-credits plan; it is the price of one reader
per keyword, and it is named here so the trade is not silent.

In `tests/check-trace.bats` the two conflicting tests were not an either/or.
`oof_scan` now reads the RMF, and it opens the RMF and the SAD before
`credit_scan`'s `mitigates:` pass does (the `implements:` pass runs earlier
still, so an unreadable SRS file dies there), so an unreadable tracked risk
ledger fails the out-of-force scan — the other machine's
expectation, kept. A gitignored one is dropped by every block pass and is still
opened by `check_orphans` alone, so local `main`'s fixture stays reachable and
is kept too, beside the other machine's awk fault injector.

## The gate

Measured on: `5dbc6bc` — `git rev-parse HEAD` — tree
`3ec11bda8bcbfc54e10456354bf71e590d013fcf`, clean worktree before and after the
run, `main` at `9eeb8b6`. `main` did not move while the suite ran, so these
figures hold for the tree that merges, apart from this section itself and the
one rename below it. The run was dispatched to a subagent; the verdict is read
from the reported pass and fail counts and not from the exit code.

The merging tree differs from the measured tree `3ec11bd` by exactly two
things: this gate section, and step 3's rename of this change's problems-ledger
file from its draft name to its dated one. Neither is read by the suite, which
drives fixtures rather than this repository's own documents. The three check
scripts WERE re-run after the rename, on the final tree, and report the same
violation classes as before it.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (parallel) | `1..1391`, 1391 ok, 0 not ok, exit 0 (20:44–21:11) |
| `check-ids.sh --allow-draft-files` (scratch copies, base and change) | exit 1 on both, identical violation classes |
| `check-trace.sh` (scratch copies, base and change) | exit 1 on both, identical violation classes, differing only by this change's own counters (PR 85 → 93, problems 32 → 35) |
| `check-review.sh --cite --branch base-premise-lapsed` | exit 0 — 21 findings, 21 dispositions, every citation resolved |
| Coverage | not configured |
| Working tree | clean |

The suite began on an idle machine (0 `bats-exec`, one-minute load 2.95) and two
unrelated suites from other sessions started during it, which is why it took
26m40s against roughly 15m alone. That bears on the figure in one direction
only: the recorded load defect produces false FAILURES, never false passes, so a
clean 1391 under contention is not weaker than one measured quiet.

This repository has no `.guardrails/config.yaml`, so the check scripts ran under
a scratch `GR_CONFIG`. `check-ids.sh` and `check-trace.sh` were run twice, by two
readers: once at base `baa983f` under a config built from
`templates/config.yaml` with `strict_paths` set to `scripts` and placeholder SRS,
SAD, RMF and SOUP documents created so every gate runs, and again at base
`9eeb8b6` under a narrower config declaring `PR` and `ADR` only. Both readings
agree — the set of violation classes is identical on base and change, and every
difference is this change's own items: a line-number shift under
`check-ids.sh`, and under the wider config seven `DANGLING-REF` lines for ID
tokens appearing only inside this change's new bats fixtures, of the same kind
as the hundred or so fixture `DANGLING-REF`s already on the base. The backlog
summary is identical on both sides, so none of the eight incoming PR items adds
to the open backlog. `merge-preflight.sh` was not run, as in
`docs/verification/2026-10-08-test-guidelines.md`.

Earlier full runs, not counted here: 1319 of 1319 at `c97793a` (20:15–20:30) on
a quiet machine, before `main` moved to `9eeb8b6`, before the base was merged
again and before this record passed `check-review --cite`. One earlier attempt
was abandoned without running at all, after a 44-minute wait in which three
suites from other sessions held the machine at load 22; spending the run there
would have produced no evidence.

## Red → green

No script changed for PR-z83ka9, so nothing was watched red for it. The change's
test obligation is that the reconciled tree still passes both machines' tests
for the two features merged above. The reviewer compared `@test` names in
`tests/check-trace.bats` across `main` (320), `d015a48` (320) and HEAD (337):
nothing of that file's from `d015a48` is missing, and the one name from `main` that is gone was retargeted, not dropped
— `an unreadable risk ledger fails the mitigates: scan` now asserts
`out-of-force scan failed`, because `oof_scan` opens doc_rmf first.

## What was wrong, and what was built

ADR-y8jmes justified skipping `merge-change` step 1's fetch on a condition
stated in its Scope: that local `main` contains every ID that was merged. That
condition is about the MACHINE, and it stopped holding as soon as changes were
merged on a second one. On 2026-10-13 a fetch left local `main` one commit
ahead of `origin/main` and two behind; the seven PR IDs named above were
defined on the remote and on no local ref, so step 4's `DUPLICATE-ID` scan
could not see them. Nothing was lost and nothing collided — the two sides' ID
sets are disjoint, and all seven of the remote's problem reports were already
`status: resolved` — so the exposure was latent rather than realised.

What was built is a correction to the decision, not to a script. ADR-y8jmes's
Scope names the right variable, assigns the reconciliation to a person, states
what an unreconciled `main` costs, and states separately what a squash can and
cannot reconcile. AGENTS.md non-negotiable 4 carries the same permission where
an agent reads the rule, bounded to an explicit instruction and to a record
naming whose decision it was. The reconciliation was then performed once, which
is where the two machines' versions of `scripts/check-trace.sh` had to be made
one.

## Review

### Round 1

**finding-1**: record — the other machine's plan says `oof_scan` records each
`mitigates:` with its block and that `UNMITIGATED-HAZARD` intersects the
line-wise set with the block-attributed one. The resolution deleted both.
disposition: fixed in `docs/plans/2026-10-11-superseded-risk-controls.md` —
the task prose states what the merged code does and says the withdrawn half was
withdrawn.

**finding-2**: record — the same false claim in the verification record for
PR-x63ejd, which reaches local `main` for the first time through this change.
disposition: fixed in `docs/verification/2026-10-11-superseded-rc.md` — the
sentence states the merged reader and names why.

**finding-3**: requirement, medium — no verification record existed for this
change, so non-negotiable 4's base line had nowhere to be stated.
disposition: fixed — this record was written, and it states the base line
`AGENTS.md` non-negotiable 4 requires.

**finding-4**: requirement, medium — the rule this change added said an agent
"neither performs nor waits for" the reconciliation, while the change performs
one, unattributed.
disposition: fixed in `AGENTS.md` — it permits an agent to merge an
already-fetched `origin/<branch>` only on the user's explicit direction, with
the record naming whose decision it was; the section above names it.

**finding-5**: requirement, medium — a squash leaves `main` holding the content
but not the ancestry, so "reconciled" overclaimed and nothing said what the
user must decide next.
disposition: fixed in `docs/adr/ADR-y8jmes-local-main-is-the-base.md` — a new
paragraph there and a section above state what is and is not reconciled.

**finding-6**: code, low — the conflict resolution left a duplicated
`[ "$status" -eq 2 ]` assertion.
disposition: fixed in `tests/check-trace.bats`, one line removed.

**finding-7**: code, low — the binary-file narrowing was given up while the
records claimed it survived.
disposition: the loss is stated above and the follow-up it belongs to is in
`docs/plans/2026-10-08-block-attributed-credits.md`; the records are corrected
by findings 1 and 2.

**finding-8**: record — PR-z83ka9 pointed at "the base merge below", which was
not below it.
disposition: fixed — PR-z83ka9's resolution no longer points at anything.

### Round 2

A second reviewer, fresh context, at `07c700d`, verified all eight round 1
findings independently and reported five more.

**finding-1**: requirement, medium — round 1's reword landed in AGENTS.md only,
so AGENTS.md cited "ADR-y8jmes, Scope" as the authority for a permission whose
Scope still read "done before a change opens" and "Agents still never … read
`origin/<branch>`", and this change's ledger entry claimed the two documents
stated the same thing.
disposition: fixed in `docs/adr/ADR-y8jmes-local-main-is-the-base.md` and
`AGENTS.md` — the ADR's Scope states the same bounded permission and points
back at AGENTS.md; the ledger no longer claims a precondition neither states.

**finding-2**: requirement, medium — the record had no `## Guideline reviews`
while the diff touches four test files, so a `docs/TEST_GUIDELINES.md` review
was owed and recorded nowhere.
disposition: fixed — the review against `docs/TEST_GUIDELINES.md` is recorded
in the `## Guideline reviews` section below.

**finding-3**: record, low — the record and a new test comment both said the
out-of-force scan opens the SRS first. `credit_scan`'s `implements:` pass runs
before it, so an unreadable tracked SRS file dies there instead.
disposition: fixed here and in `tests/check-trace.bats`, against the call order
in `scripts/check-trace.sh`. The operative claim — that an unreadable tracked
file no longer reaches the orphan backstop — was unaffected.

**finding-4**: record, low — "nothing from `d015a48` is missing" held inside
`tests/check-trace.bats` but not across the suite: `tests/lib.bats` lost one
test, removed by local `main` in `be9cfa6`, which HEAD correctly follows.
disposition: fixed — the sentence names `tests/check-trace.bats` as the file
it is true of, and `tests/lib.bats` as the one that lost a test.

**finding-5**: record, low — the binary-SRS cost was stated without the
qualifier the code carries: that credit also needs the REQ defined in a text
file, through `ids_defined` and `defined_req_flat` in `scripts/check-trace.sh`.
disposition: fixed — the sentence carries the qualifier `scripts/check-trace.sh`
carries in `ids_defined` and the `defined_req_flat` filter.

The reviewer also confirmed by grep at three refs that the seven PR IDs are
absent from local `main` at `baa983f` and so arrive through `70a9a7b` rather
than through a base merge; that this change introduces no duplicate ID; and
that every ancestry claim in this record is exact.

## Guideline reviews

### docs/TEST_GUIDELINES.md

In force for all four test paths, confirmed with
`sh scripts/guidelines-file.sh TEST tests/check-trace.bats
tests/check-signing.bats tests/portability.bats tests/helpers.bash`; no unit
file applies. Reviewed in a fresh context against the newly authored test
material only. **Verdict: it complies.**

Scope the reviewer established before judging: the conflict resolution
(`70a9a7b`) touches only `scripts/check-trace.sh`,
`skills/ratchet/references/upgrade-notes.md` and `tests/check-trace.bats`.
`tests/check-signing.bats` and `tests/helpers.bash` arrive byte-identical to
`d015a48` and passed their own change's gate, so nothing in them is this
change's to answer for. `tests/portability.bats` is NOT identical to
`d015a48` — local `main` added the bare-negation scan to it in `0c11d77` — but
what this change adds to it against `main` is exactly `d015a48`'s 19-line
PR-cjvv8g fix, so the same conclusion holds for a different reason.

Each newly written or reworded comment was checked against the script rather
than taken on trust, and each of the three kept error-path tests was shown to
reach a different `gr_die`: the tracked RMF reaches `oof_scan`'s, the
gitignored one is the only fixture where a real unreadable file still reaches
`check_orphans`'s (because `check_orphans` alone does not filter through
`unignored_files`), and the awk fault injector reaches that same `gr_die` by
exiting 2 with no output, which an unreadable file cannot do. The resolution's
reason for keeping both machines' tests therefore holds. The awk double is a
fault injector and needs no contract test (Doubles 5); every new assertion
reports what it saw (the negation rule); all three tests drive the command-line
seam (Seams 1). Targeted runs: the three tests plus two neighbours, 5 of 5 ok;
the three repo scans that police test form, 3 of 3 ok.

**finding-1**: guideline, low — `an unreadable gitignored risk ledger fails the
orphan scan` carried no `verifies:` while D1, which arrived with the other
machine, names its exact contract. The test predates D1; the resolution is what
put the two next to each other.
disposition: fixed in `tests/check-trace.bats`, annotated with D1 and with why
the annotation arrives late.

**finding-2**: record accuracy, low, inherited — two comments said the
out-of-force scan is "the first awk to open" a SAD file. `parse_llr_file` runs
awk over every SAD file first; the out-of-force scan is merely the first whose
status is KEPT, which is what the tests actually depend on. Both sentences came
verbatim from `d015a48` and this change did not make them false.
disposition: fixed anyway in `tests/check-trace.bats`, since this change
corrected the same class of claim elsewhere (round 2, finding-3) and would
otherwise leave two behind.

## Gaps

- **`merge-preflight.sh` was not run**, for the reason the gate section gives:
  this repository configures no `.guardrails/`, so the preflight has nothing to
  read. The three check scripts were run under a scratch config instead.
- **The remote relationship is left diverged, deliberately.** After the squash
  `main` holds the other machine's content but not its commits, so the next
  push is not a fast-forward. The decision is the maintainer's and no document
  here makes it.
- **Two gate records arrive attesting trees that are not what merges.**
  `docs/verification/2026-10-11-linux-suite.md` and
  `docs/verification/2026-10-11-superseded-rc.md` each say "this is the tree
  that merges, apart from this record", and each quotes a passing figure. That
  was true of their integration onto the other machine's `main`. It is not true
  here: `70a9a7b` rewrote `scripts/check-trace.sh` and `tests/check-trace.bats`
  after those gates ran, so the merged script is code that existed on neither
  machine and has been gated in no form. A reader seeing those two records
  beside this one on `main` must take this record's `## The gate` as the
  statement about the merged tree, not theirs.
- **One narrowing was given up**, stated under the conflict resolution above:
  an `implements:` in a REQ block of an SRS file `git grep -I` treats as
  binary, where that REQ is also defined in a text file. Local `main` already
  shipped this and records it as a follow-up in the block-attributed-credits
  plan; this change does not close it.

### Round 3

A third reviewer, fresh context, at `b7711f2`. **No `code` or `requirement`
finding above low, which `review-checklist.md` makes the last round.** It
verified round 2's five findings and the guideline review's two by grep, and
checked the "first awk whose status is kept" justification against the script
rather than taking it: `parse_llr_file` is called at `:988-993`, before
`oof_scan` at `:1074`, and its status is dropped into a command substitution,
with `set -e` never set. Six low findings, all record.

**finding-1**: record, low — the header `reviewer:` and `verdict:` still
described round 1 alone and ended "A second round is owed", contradicting the
rounds recorded below them.
disposition: fixed — the header names all three rounds and the guideline
review, with their refs and the convergence rule from
`skills/merge-change/references/review-checklist.md`.

**finding-2**: record, low — the guideline-review scope paragraph said
`tests/portability.bats` arrives unmodified from `d015a48`. It does not: local
`main` added the bare-negation scan to it in `0c11d77`. The conclusion survives
because what this change adds to that file against `main` is exactly
`d015a48`'s PR-cjvv8g fix.
disposition: fixed — the scope paragraph names `tests/portability.bats` and the
real reason it is excluded.

**finding-3**: record, low — the two gate records arriving from the other
machine each say "this is the tree that merges", which stopped being true when
`70a9a7b` rewrote `scripts/check-trace.sh` and `tests/check-trace.bats` after
those gates ran.
disposition: fixed — `## Gaps` names
`docs/verification/2026-10-11-superseded-rc.md` and
`docs/verification/2026-10-11-linux-suite.md`, and states that the merged
script existed on neither machine and that this record's `## The gate` governs.

**finding-4**: record, low — a third "the first scan to open a working-tree SAD
file" claim survived, in `scripts/check-trace.sh` two lines above a line this
diff edits.
disposition: fixed in `scripts/check-trace.sh`, to match the two already
corrected.

**finding-5**: record, low — the message catalogue said `MALFORMED-SUPERSESSION`
covers "a REQ, LLR or RC", while `oof_scan` now opens HAZ blocks too and the
self-pair and cycle reports are not filtered by prefix. The change's own
upgrade note already said a looping HAZ supersession is reported.
disposition: fixed in `scripts/check-trace.sh` — the catalogue names HAZ and
says what a reported one owes.

**finding-6**: record, low — the same incoming record quotes gate figures (1301
ok, 320 tests in `check-trace.bats`) that no longer describe the suite. Same
root as finding-3.
disposition: no change — the same gap entry written for finding-3 covers it,
and nothing further is owed for this one.

The reviewer independently re-verified every ancestry and hash claim in this
record by `git rev-parse`, all nine PR-ID claims by grep at two refs, the
320/320/337 test-name arithmetic and that the merge invented no test, that no
line this change authored claims a gate pass, and that `sh -n` and the `set -u`
audit are clean. It also extracted the bare-negation scan's awk program and ran
it directly over the merged `tests/*.bats`: no output, so the two machines'
test material does not trip local `main`'s new scan.
