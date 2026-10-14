# Verification — gate-proof-in-trailers (2026-10-14)

branch: gate-proof-in-trailers
reviewer: independent Claude subagents with fresh context, one per round,
each in its own task worktree off the change branch, given the diff, AGENTS.md,
the plan, the claimed items and
`skills/merge-change/references/review-checklist.md`; conformance reviews ran
in fresh contexts of their own against `docs/TEST_GUIDELINES.md` and
`docs/CODE_GUIDELINES.md`
verdict: converged at round 4 — no `code` or `requirement` finding above low
in that round, which makes it the last. Each round found the change does what
it claims; rounds 1–3 each raised one `requirement` finding at medium, all
about a squash a forge rebases or squash-merges after the push, and the user
ruled on 2026-10-14 to cut that flow from this change (PR-m7gcuq, open). Every
finding is fixed, cut by that ruling, or carries a `no change` reason.
reproduced: yes, both defects, before their fixes. PR-k4y59t: "finish-merge:
a record committed after the gate leaves a squash its Gate-tree does not name"
commits a record after the gated tree and squashes; before guard 5 existed
the cleanup exited 0 and removed the worktree and branch, so a squash of a
tree no gate measured finished as verified. PR-nyw3ww: with
`log.showSignature` set, `check-signing.sh --strict` reported a good
signature as `UNVERIFIED <sha> (signature present but did not verify)`,
measured by "check-signing: a good signature passes --strict with
log.showSignature set" before the `--no-show-signature` flag.

Change: the squash commit, not the verification record, certifies the gate.
`merge-change` step 7 writes `Base:`, `Gate-tree:` (the tree the step 2 gate
measured) and one `Gate:` line per verify command into the squash message's
trailer paragraph and compares `git write-tree` with that tree before the
hand-over; `finish-merge.sh` guard 5 refuses the cleanup unless the commit
carries exactly one `Gate-tree:` trailer naming its own tree; the record names
no commit or tree the gate measured, no base commit and no gate figure.
Implements ADR-f6ytg7; resolves PR-k4y59t and PR-nyw3ww; opens PR-yd4pug and
PR-m7gcuq;
amends ADR-y8jmes.
Plan: `docs/plans/2026-10-14-gate-proof-in-trailers.md`.

## The gate

The gate's figures are not in this record. This change's squash commit carries them as trailers, and this change's own
`finish-merge.sh` guard 5 is the first to check its `Gate-tree:`; the `Gate:`
totals are copied, not checked (Gaps).

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `ADR-f6ytg7` (D3, D7) | `ADRs: the gate-proof decision is recorded, and the base statement is the Base: trailer` | no ADR-f6ytg7 file |
| `PR-nyw3ww` | `check-signing: a good signature passes --strict with log.showSignature set` | `expected exit 0, got 1: UNVERIFIED <sha> (signature present but did not verify)` |
| D5 | `finish-merge: a squash whose message has no Gate-tree trailer is refused with everything intact` | `expected exit 1, got 0`, cleaned up |
| D5 | `finish-merge: a Gate-tree trailer with no value is refused` | exit 0 |
| D1, D5 | `finish-merge: a Gate-tree line outside the message's last paragraph is not read` | exit 0 |
| D5 | `finish-merge: two Gate-tree trailers are refused, even when both name HEAD's tree` | exit 0 |
| D5 | `finish-merge: a Gate-tree trailer naming another tree is refused, naming both trees` | exit 0 |
| `PR-k4y59t` | `finish-merge: a record committed after the gate leaves a squash its Gate-tree does not name` | exit 0, worktree and branch removed |
| D1, D2, D4 | `merge-change: step 7 writes the gate's trailers and compares the staged tree with the step 2 tree before the hand-over` | `the message template lacks: Base: <base ref> at <its commit>` |
| D6 | `merge-change: the record is written before the last rerun and holds no gate figure` | no `Write the record (6b) before that rerun.` |
| D1, D5 | `finish-merge: the message merge-change step 7 documents passes guard 5` | `no Gate-tree line in the template` |
| `PR-k4y59t`, D6 | `verification template: the gate's figures and their tree are in the squash commit, not the record` | the template lacked the `Gate-tree:` pointer |
| D6 | `verify-before-merge: the gate summary holds what step 7's trailers need` | `verify-before-merge still feeds the gate figures to the record` |
| D9 | `ratchet: the upgrade notes say the squash commit certifies the gate, and how to repair a squash without its trailer` | no section |
| D5, D11 | `finish-merge: one Gate-tree trailer folded onto a second line is read as one value, and refused as another tree` | `HEAD's message has more than one Gate-tree: trailer` before `unfold` |
| D5, D11 | `finish-merge: an empty Gate-tree trailer after one naming HEAD's tree is a second trailer, and refused` | exit 0, cleaned up |
| D11 | `merge-change: the forge flow after the push is an open item, not a procedure` | `the ledger has no forge-flow item` |
| `PR-nyw3ww` | `check-signing: with log.showSignature set, an unsigned commit and an untrusted signature still fail --strict` | green on arrival; red against a mutant that reads every verdict as `G` |

`finish-merge: guard 5 reads the trailer when log.showSignature is set` is a
regression guard: green before guard 5, red under mutation M05 (the
`--no-show-signature` flag removed) and under M01.

Mutations: `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/`
M01–M07, each quoting one script line verbatim, each applied and killed:
M01 by the two `log.showSignature` tests, M02 by the two-trailer and the two
empty-trailer tests, M03 by the other-tree and record-after-gate tests, M04 by
the three no-trailer tests, M05 and M06 (the value and the count read without
`--no-show-signature`) by the guard 5 `log.showSignature` test, M07 (the count
read with `valueonly`) by the empty-trailer-after test and "finish-merge: a git
log that cannot count the Gate-tree trailers exits 2 with everything intact".

## What was wrong, and what was built

The record certified a tree it was part of. It named the commit and tree the
gate measured, the base commit and the gate's totals, then was committed,
which made a new tree no gate had measured; a base update or a forge rebase
made every one of those lines stale and asked for another record commit, and
that commit changed the tree again. Nothing checked that the signed squash
was the tree a gate measured (PR-k4y59t).

Now the squash message carries the proof. `merge-change` step 7 writes
`Base: <base ref> at <commit>`, `Gate-tree: <step 2 tree>` and a `Gate:` line
per verify command (and per coverage command where configured) in one
trailer paragraph, with `Co-Authored-By:` in it, since git reads trailers only
in a message's last paragraph. Before the hand-over it compares
`git write-tree` with the step 2 tree. `finish-merge.sh` guard 5, proved after
guard 2 and before the worktree list is read, refuses unless HEAD has exactly
one `Gate-tree:` trailer equal to `HEAD^{tree}`. It counts the trailers with
`%(trailers:key=Gate-tree,unfold)`, one line per trailer whatever its value,
then reads the value with `valueonly,unfold`, both through
`git log --no-show-signature` (git 2.22 or later; an older git leaves the
placeholder unexpanded and the guard refuses). Its remedies are in
`skills/merge-change/references/cleanup-rejections.md`. A squash a forge
rebases or squash-merges after the push is out of scope by the user's ruling
of 2026-10-14 (PR-m7gcuq).

The record template drops the "Branched from" clause, the "Measured on"
paragraph and the gate table, and says where the figures are. Step 6a has the
record written before the rerun after the last review, so the final pass
gates the tree that is squashed, and the record does not change on that rerun.
AGENTS.md non-negotiable 4's base statement is now the `Base:` trailer, and
ADR-y8jmes's Decision says the same; ADR-f6ytg7 records the decision. The
upgrade note tells adopters that their refreshed `finish-merge.sh` refuses a
squash without the trailer, and how to repair one.

Planning found PR-nyw3ww: under `log.showSignature`, `git log --format=%G?`
prints the verifier's output above the letter, so `check-signing.sh --strict`
read a good signature as unverified, and guard 1 blocked every cleanup. Guard
5's own tests could not pass guard 1 without the fix, so it is in this change:
`--no-show-signature` on the verdict line.

## Review

### Round 1

**finding-1**: requirement, medium — The motivating multi-collaborator flow, a rebase after origin moves, is left with no procedure and no check. A squash rebased onto a moved `origin/main`, or squash-merged by the forge onto a newer base, keeps its `Gate-tree:` and `Base:` trailers naming a tree and base it no longer holds. `finish-merge.sh` ran before the push, so nothing ever compares them again. The rebased commit is re-signed and looks fully certified on the shared branch. ADR-f6ytg7 (Consequences, "A squash later rebased onto a moved remote…") records this as accepted. But no skill tells the user to re-gate and amend the trailers after a rebase (`skills/merge-change/references/cleanup-rejections.md:15-16` covers only the local cleanup). `skills/ratchet/references/setup-checklist.md:24-26` lists the CI backstop (`check-signing.sh --strict`) without the one-line trailer-vs-tree comparison that would catch it. Separately, step 1 merges `origin/$BASE` while step 7 squashes onto local `$BASE` (`skills/merge-change/SKILL.md:34-46`, 197-201). Nothing requires local `$BASE` to equal what step 1 merged, so in a fetched flow the push is non-fast-forward by construction and the rebase is routine, not rare. Suggest: a setup-checklist CI item comparing the `Gate-tree` trailer with `HEAD^{tree}`, and one sentence in step 7 or in the ADR on what to do after a rebase.
disposition: fixed, then cut — the CI recipe and a rebase procedure were
added for this finding; review rounds 2 and 3 each found the procedure wrong,
and the user ruled on 2026-10-14 to cut the forge flow from this change.
ADR-f6ytg7's Consequences state that a forge rebase or squash-merge after the
push replaces the signed squash and nothing re-checks `Gate-tree:`, recorded
open as PR-m7gcuq; the step 1 / step 7 base mismatch is recorded open as
PR-yd4pug. Pinned by "merge-change: the forge flow after the push is an open
item, not a procedure".

**finding-2**: requirement, low — A worktree-discipline line the plan's investigation missed: `skills/worktree-discipline/SKILL.md:193-194` still describes the verification record as "what was run and what it reported". After this change the record holds none of that; the squash trailers do.
disposition: fixed — skills/worktree-discipline/SKILL.md says the record holds
the reviews, dispositions, red -> green and gaps, and the squash's trailers
what was run; pinned by "worktree-discipline: the record holds the reviews,
and the squash's trailers hold what was run".

**finding-3**: requirement, low — The template states the record "names no commit" (`templates/verification.md:24`). Two rules in force still have the record name commits: AGENTS.md non-negotiable 4 and ADR-y8jmes Scope ("as the subject of a change whose verification record names … which commit was merged"), which D3 deliberately keeps; and every disposition by convention cites fix commits ("fixed in `<hash>`", for example `docs/verification/2026-10-14-code-guidelines.md:167`). The second matters for the fixed point under a rebase-based PR flow: rewriting the change branch makes those hashes stale and brings back the rewrite loop PR-k4y59t describes. The template's claim should be narrowed, for example to "no commit or tree the gate or base measured", or the hash convention should be addressed.
disposition: fixed — templates/verification.md says the record names no
commit or tree the gate measured, no base commit and no gate figure; ADR-f6ytg7,
PR-k4y59t's resolution and the upgrade note say the same, pinned by
"verification template: the gate's figures and their tree are in the squash
commit, not the record".

**finding-4**: requirement, low — PR-dkm5tq's resolution (`docs/problems/2026-09-15-field-report-two.md:185-192`) says "the record names the tree its figures describe". This change reverses that fix. The resolution also cites as its reproducing test "verification template: the gate table names the tree the figures describe", which the change deleted. D10 deliberately leaves merged items unedited, but the resolved item now points at a test that does not exist and a fix that is undone. Nothing links it to ADR-f6ytg7 or PR-k4y59t.
disposition: fixed — docs/problems/2026-09-15-field-report-two.md gains a
dated note after PR-dkm5tq's resolution naming ADR-f6ytg7, PR-k4y59t and the
test that replaced the deleted one; the item's history is unchanged.

**finding-5**: code, low — When a single `Gate-tree:` value carries a continuation line, the guard says it has two trailers. `valueonly` does not unfold continuation lines: `Gate-tree: <tree>` followed by an indented continuation returns both lines. Guard 5 (`scripts/finish-merge.sh:319-325`) then reports "more than one Gate-tree: trailer" for that single folded trailer, which is the wrong message. Adding `,unfold` to the format, or wording the message as "more than one line", would fix it. This needs a contrived message.
disposition: fixed — scripts/finish-merge.sh reads the trailer with
`valueonly,unfold`, so a folded value is one value and is refused as another
tree; pinned by "finish-merge: one Gate-tree trailer folded onto a second line
is read as one value, and refused as another tree", red before `unfold`.
Mutation M05 was re-cut to the new line and is still killed.

**finding-6**: requirement, low — `AGENTS.md:28` non-negotiable 2 still says only that "`finish-merge.sh` verifies the signature before it removes anything". The shipped `templates/AGENTS-block.md` and README rule 2 now also name the `Gate-tree:` trailer. The repo's own AGENTS.md was not updated to match.
disposition: fixed — AGENTS.md non-negotiable 2 says finish-merge.sh checks
that the `Gate-tree:` trailer names the commit's own tree; pinned by
"AGENTS.md: non-negotiable 2 says finish-merge.sh checks the Gate-tree
trailer".

**finding-7**: code, low — Two test annotations name the wrong decision, and two error paths have no test. "finish-merge: a Gate-tree line outside the message's last paragraph is not read" and "finish-merge: the message merge-change step 7 documents passes guard 5" both claim `verifies: D4`; D4 is the step 7 `git write-tree` comparison, which neither test runs; they verify D1 and D5. The `gr_die` exits (`git log` or `git rev-parse` failing in guard 5, `scripts/finish-merge.sh:309-314`) have no test, and the git < 2.22 fail-closed claim is untested.
disposition: fixed — tests/finish-merge.bats annotates both tests
`verifies: D1, D5`, and "finish-merge: a git log that cannot count the
Gate-tree trailers exits 2 with everything intact", "finish-merge: a git log
that cannot read the Gate-tree value exits 2 with everything intact" and
"finish-merge: a git rev-parse that cannot read HEAD's tree exits 2 with
everything intact" cover guard 5's `gr_die` paths. The git older than 2.22
claim stays untested; Gaps states it.

### Round 2

Base edited `tests/skills.bats` after round 1's reviewed commit (`shared:`); round 2 reviewed the whole change.

**finding-1**: requirement, medium — The rebase procedure re-certifies a tree that has not passed the pre-flight or review. `skills/merge-change/references/cleanup-rejections.md:22-33` says to "Gate the rebased tree as step 2 does" and then rewrite `Gate-tree:`. That runs only `verify_commands`. A rebase onto a moved base brings in IDs merged elsewhere, and the step 4 DUPLICATE-ID scan exists to catch exactly that. A conflict resolution also adds content no reviewer saw. The new rationale (`skills/merge-change/references/rationale.md:402-405`, "The pre-flight has no trailer: the sequence halts when it fails, so a squash exists only after it passed") is false for a squash re-signed by this procedure. The procedure also does not say where to gate: by then `finish-merge.sh` has removed the change worktree. It should rerun the pre-flight checks (`check-ids.sh`, `check-trace.sh`) on the rebased tree as well, or send the change back through the sequence from step 1, and name a worktree to do it in.
disposition: cut — the user ruled on 2026-10-14 to remove the rebase
procedure from this change rather than repair it; skills/merge-change/references/cleanup-rejections.md
has no rebase section, skills/merge-change/references/rationale.md says every
squash exists only after the sequence passed, and PR-m7gcuq records the forge
flow open. Pinned by "merge-change: the forge flow after the push is an open
item, not a procedure".

**finding-2**: requirement, low — The CI item at `skills/ratchet/references/setup-checklist.md:30-36`, repeated in the upgrade note at `skills/ratchet/references/upgrade-notes.md:667-668`, checks "each squash commit on the base branch". Followed as written, it fails on every squash merged before the upgrade, since none has a trailer; the record's Gaps admit as much. It also gives no way to tell a squash from a forge merge commit. It needs a starting commit (squashes after the upgrade) and a selection rule. The one-liner itself is never executed by a test; it is only grepped.
disposition: cut — the user's ruling of 2026-10-14 removed the CI recipe;
skills/ratchet/references/setup-checklist.md is as `main` has it, and PR-m7gcuq
records the forge flow open.

**finding-3**: code, low — Guard 5 is asymmetric about an empty second trailer. With git 2.55.0, `Gate-tree: <tree>` followed by an empty `Gate-tree:` reads as `<tree>`, because command substitution strips the trailing newline. That passes as "exactly one". The reverse order reads as a newline then `<tree>` and is refused as "more than one Gate-tree: trailer". This contradicts the comment at `scripts/finish-merge.sh:316-317` and the ADR's "exactly one". The tree still matches, so nothing ungated passes.
disposition: fixed — scripts/finish-merge.sh counts the trailers with
`%(trailers:key=Gate-tree,unfold)`, one line per trailer whatever its value,
before reading the value; pinned by "finish-merge: an empty Gate-tree trailer
after one naming HEAD's tree is a second trailer, and refused" (red before)
and its "before" twin. Mutations M06 and M07 cover the count line.

**finding-4**: code, low — A test comment describes history: `tests/finish-merge.bats:779` says "Read unfolded, it arrived as a second line and was reported as a second trailer". That violates CODE_GUIDELINES Comments 2.
disposition: fixed — tests/finish-merge.bats states the folded-trailer test's
reason in the present tense.

**finding-5**: requirement, low — Derived work with no decision behind it. The rebase section, the setup-checklist CI item and `unfold` came from review round 1, but no D-item in the plan covers them. Their tests are annotated `verifies: D5, D7`, and neither decision covers a CI recipe or a rebase procedure. D5 in the plan still says `valueonly` without `unfold`.
disposition: fixed — docs/plans/2026-10-14-gate-proof-in-trailers.md adds
D11 for guard 5's `unfold` and exact count, with the forge flow recorded as cut
by the user's ruling and open as PR-m7gcuq; the tests that verify guard 5's
count cite D5 and D11.

**finding-6**: requirement, low — `skills/verify-before-merge/references/rationale.md:10-11` still says the gate's evidence "moves from the chat log to the log file and the verification record". The gate's figures now move to the squash commit's trailers.
disposition: fixed — skills/verify-before-merge/references/rationale.md says
the evidence moves to the log file and the squash commit's trailers; pinned by
"verify-before-merge: the gate summary holds what step 7's trailers need".

**finding-7**: record — The red→green table still annotates "finish-merge: a Gate-tree line outside the message's last paragraph is not read" and "finish-merge: the message merge-change step 7 documents passes guard 5" as `D4, D5`. Finding-7's disposition says both tests now say `verifies: D1, D5`, so the table contradicts the record's own disposition and the tree.
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.md
annotates both rows `D1, D5`.

**finding-8**: record — The first Gaps bullet says "No CI check compares `Gate-tree:` with the tree after a forge rebase… (ADR-f6ytg7, Consequences)". The ADR's Consequences now say the setup checklist's CI item does that comparison, and finding-1's disposition says the same. It should say what is true: guardrails itself runs no such CI, and adopters get a recipe.
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.md's
first Gaps bullet names PR-m7gcuq.

**finding-9**: record — The Change paragraph says "the record names no commit, no tree and no gate figure", the wording finding-3 narrowed. It lists what the change implements, resolves and amends, but not that it opens PR-yd4pug.
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.md's
Change paragraph uses the narrowed wording and names PR-yd4pug as opened.

**finding-10**: record — The plan does not reflect the round-1 fixes. D5 reads `valueonly` without `unfold`. D10 names only PR-nyw3ww and PR-k4y59t, not PR-yd4pug. "After the tasks" still lists "no CI check compares `Gate-tree:`…" as a gap.
disposition: fixed — docs/plans/2026-10-14-gate-proof-in-trailers.md's D5
names `valueonly,unfold` and the exact count, D10 names PR-yd4pug and
PR-m7gcuq, and its gap bullet names PR-m7gcuq;
docs/verification/2026-10-14-gate-proof-in-trailers.md lists the plan among
this round's fixes.

### Round 3

**finding-1**: requirement, medium — The CI check in `skills/ratchet/references/setup-checklist.md:477-484` and the rebase procedure in `skills/merge-change/references/cleanup-rejections.md:314-344` trap an adopter together. The fence re-scans every first-parent commit from `$first` on every build. So once a forge squash-merge or rebase lands a stale `Gate-tree:` on the shared base (the routine forge flow, by PR-yd4pug's own account), CI is red on every later build, permanently. Setting `first` to the upgrade commit does not help, because the stale commit comes after it. The only remedy offered is step 1 of the procedure: `git reset --keep <rebased squash>^`, plus "replacing a pushed one on the remote is theirs". For a forge merge, that means force-pushing a protected, shared base branch. That step also drops every commit after the rebased squash, which the text does not say. Nothing describes a forward fix, such as an exemption list or checking only the commits a push introduces. Separately, a forge merge commit onto a moved base also produces an ungated tree on the base. `--no-merges` skips it by design, but neither the ADR nor the checklist states that gap.
disposition: cut — the user ruled on 2026-10-14 to remove the forge flow
from this change: skills/ratchet/references/setup-checklist.md is as `main` has
it, skills/merge-change/references/cleanup-rejections.md has no rebase
procedure, and ADR-f6ytg7's Consequences name PR-m7gcuq, open. Pinned by
"merge-change: the forge flow after the push is an open item, not a
procedure".

**finding-2**: requirement, low — The CI fence fails on a correct history whenever `$first` has no parent (`skills/ratchet/references/setup-checklist.md:479`): in a shallow clone, the default checkout in most CI, and when `$first` is the root commit. `"$first^..$BASE"` then exits with `fatal: ambiguous argument … unknown revision` and the check exits 1. In a shallow clone whose tip lacks the trailer, `first` is empty and the check passes vacuously. The text should require full history, or use `git rev-list --first-parent --no-merges "$BASE" --not "$first^@"`.
disposition: no change — the CI fence it names was removed by the user's
ruling of 2026-10-14; PR-m7gcuq carries the forge flow, CI included.

**finding-3**: requirement, low — The upgrade note's repair (`skills/ratchet/references/upgrade-notes.md:523-527`, "Correct the message file and have the user run `git commit --amend -S`") never says which tree goes in `Gate-tree:`. A squash written from the old skill never had step 7's comparison; its record may have been committed after the gate. Writing `HEAD^{tree}` there certifies a tree no gate measured. `cleanup-rejections.md` gives the right answer; the note should point there, or say "the tree the gate measured, or gate HEAD's tree first".
disposition: fixed — skills/ratchet/references/upgrade-notes.md says the
`Gate-tree:` is the tree a gate measured, and to gate HEAD's tree first where
none did; pinned by "ratchet: the upgrade notes say the squash commit
certifies the gate, and how to repair a squash without its trailer".

**finding-4**: requirement, low — `docs/adr/ADR-y8jmes-local-main-is-the-base.md:26-28` says ADR-f6ytg7 "moved every commit a record named into the squash commit's trailers". That overstates the decision: a disposition may still cite a fix commit, and ADR-y8jmes's own Scope keeps a record that names which commit was merged. The sentence should say "the base commit", or "every commit the gate or base measured".
disposition: fixed — docs/adr/ADR-y8jmes-local-main-is-the-base.md says the
base commit moved into the `Base:` trailer; pinned by "ADRs: the gate-proof
decision is recorded, and the base statement is the Base: trailer".

**finding-5**: code, low — PR-nyw3ww has no abnormal-input test. `tests/check-signing.bats:90` proves that a good signature passes with `log.showSignature` set. No test shows that an unsigned or bad signature still fails `--strict` under that setting.
disposition: fixed — "check-signing: with log.showSignature set, an unsigned
commit and an untrusted signature still fail --strict" in
tests/check-signing.bats, red against a mutant that reads every verdict as `G`.

**finding-6**: record — The `verdict:` field in `docs/verification/2026-10-14-gate-proof-in-trailers.md:9-11` is stale: it says "every finding is fixed, and round 2 reviews the fixes", and does not state round 2's outcome.
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.md's
`verdict:` states each round's outcome.

**finding-7**: record — Two round-1 dispositions cite test names that do not exist in the tree: finding-1 cites "merge-change: a rebased signed squash is re-gated and signed again, and the ADR points there" (now "…goes back through the sequence from step 1…") and describes the procedure round 2 replaced; finding-7 cites "finish-merge: a git log that cannot read the Gate-tree trailer exits 2 with everything intact" (now "…cannot count the Gate-tree trailers…" and "…cannot read the Gate-tree value…"). The TEST guideline finding-2 disposition says "`tests/mutate.sh` applies all five", but there are seven.
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.md's
round 1 dispositions cite the tests in the tree and say the procedure was cut,
and the TEST guideline disposition says seven.

**finding-8**: record — The plan contradicts itself: "After the tasks" lists the squash's trailers without `Opens: PR-yd4pug`, and the Investigation says the five new mutations printed `mutations: 5 applied`, while D8 says seven.
disposition: fixed — docs/plans/2026-10-14-gate-proof-in-trailers.md lists
`Opens: PR-yd4pug, PR-m7gcuq` and says seven mutations;
docs/verification/2026-10-14-gate-proof-in-trailers.md lists the plan among
this round's fixes.

### Round 4

**finding-1**: requirement, low — Step 7 says to write "one for `coverage_command` where configured", but gives no form for it. The only `Gate:` form in the template is `<verify_commands entry> <passed>/<total>`, which a coverage figure does not fit. D2 specifies `Gate: <coverage_command> <figure>`, and that form is not in the skill (`skills/merge-change/SKILL.md:236`, `:239-240`).
disposition: fixed — skills/merge-change/SKILL.md step 7 gives the coverage
trailer's form, `Gate: <coverage_command> <figure>`; pinned by "merge-change:
step 7 writes the gate's trailers and compares the staged tree with the step 2
tree before the hand-over".

**finding-2**: requirement, low — The step 7 template asks for `Base: <base ref> at <its commit>`, and D1 defines that commit as "`git rev-parse <ref>` at that merge". No step tells the agent to record that commit. Step 2 records the tree, but step 1 (`skills/merge-change/SKILL.md:33-46`) records nothing about the base, so at step 7 the agent has to reconstruct it from the primary checkout. That is correct only because the `git diff --cached --quiet <branch>` check has already ruled out a moved base.
disposition: fixed — skills/merge-change/SKILL.md step 7 says the `Base:`
commit is the base ref's commit in the primary checkout before the squash;
pinned by "merge-change: step 7 writes the gate's trailers and compares the
staged tree with the step 2 tree before the hand-over".

**finding-3**: requirement, low — `skills/merge-change/references/rationale.md:403-405` says "The pre-flight's checks read only the tree `Gate-tree:` names, so anyone can run them again on that tree." Three checks read more than the tree: BASE-MERGED reads ancestry (`scripts/merge-preflight.sh:156`), NESTED-WORKTREE reads the worktree registry (`:250`), and the DUPLICATE-ID scan compares against the base's IDs. The reason this rationale gives for having no pre-flight trailer is therefore overstated. ADR-f6ytg7's Decision makes the same "anyone can run them again on the tree" claim.
disposition: fixed — skills/merge-change/references/rationale.md and
ADR-f6ytg7's Decision say the pre-flight has no trailer because the sequence
halts on its failure, and that its tree checks can be rerun on the named
tree.

**finding-4**: code, low — A stale comment that the diff did not touch: `tests/finish-merge.bats:936-938` still says "`--check` proves guard 4 and nothing else: guards 1 and 2 both read the squash commit". Guard 5 reads the squash commit too, and the script's own comments now say "Guards 1, 2 and 5" (`scripts/finish-merge.sh:58`, `:152`).
disposition: fixed — tests/finish-merge.bats's `--check` comment names
guards 1, 2 and 5.

**finding-5**: record — In `## The gate`, "This change's squash commit carries them as trailers, and this change's own `finish-merge.sh` guard 5 is the first to check them" says guard 5 checks the gate's figures. Guard 5 checks only `Gate-tree:`. The record's own Gaps say "no script checks them. Only `Gate-tree:` is checked".
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.md's
`## The gate` says guard 5 checks `Gate-tree:` and the `Gate:` totals are
copied, not checked.

**finding-6**: record — The plan still uses the wording that round 1 finding-3 narrowed: D6 ("It names no commit, no tree, no base commit and no gate figure") and "After the tasks" ("It names no commit, no tree and no gate figure"). The ADR, the template and PR-k4y59t say "no commit or tree the gate measured".
disposition: fixed — docs/plans/2026-10-14-gate-proof-in-trailers.md's D6
and "After the tasks" use the narrowed wording;
docs/verification/2026-10-14-gate-proof-in-trailers.md lists the plan among
this round's fixes.

## Guideline reviews

### docs/TEST_GUIDELINES.md

Governs: every path of the diff (`guidelines-file.sh TEST` printed all of
them); the test-bearing ones are `tests/check-signing.bats`,
`tests/finish-merge.bats`, `tests/skills.bats` and the mutation scripts.

### Round 1

**finding-1**: guideline, low — Mutants 2, "Each `docs/verification/*.mutations/M*.sh` quotes one line of the script it mutates verbatim … While editing a script, run one grep per changed line" — docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh:5
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh
quotes the whole `scripts/check-signing.sh` line in a triple-quoted string with
no escapes; a fixed-string grep of the line finds it.

**finding-2**: guideline, low — Mutants 2, "quotes one line of the script it mutates verbatim" — docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M02.sh:5
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M02.sh
anchors one line, `(*"$gr_nl"*) gr_refuse \`; M03–M05 were re-cut the same
way, and `tests/mutate.sh` applies all seven.

### docs/CODE_GUIDELINES.md

Governs: every path of the diff (`guidelines-file.sh CODE` printed all of
them); the code-bearing ones are `scripts/check-signing.sh`,
`scripts/finish-merge.sh`, the mutation scripts and the three test files.

### Round 1

**finding-1**: guideline, medium — Names 1, "Every name the change writes, a loop index and a callback parameter included, says what it holds … in awk, `index_number`, not `i`" — tests/skills.bats:2259
disposition: fixed — tests/skills.bats names the counter `sh_fences`.

**finding-2**: guideline, medium — Names 1, "No single-character names. Every name the change writes … says what it holds" — docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh:4
disposition: fixed — docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh
and M02–M05 name the path `target` and the contents `text`.

**finding-3**: guideline, medium — Comments 2, "A comment describes the code as it is, never the change that wrote it: no "added" … history" — scripts/finish-merge.sh:40
disposition: fixed — scripts/finish-merge.sh's guard 5 entry states the order
the code proves the guards in and why; the guard 4 entry's "numbered last
because it was added last", false once guard 5 existed, was removed too.

**finding-4**: guideline, medium — Comments 2, "no "added", "now uses", "previously", "fixed" or ticket history" — tests/skills.bats:1336
disposition: fixed — tests/skills.bats states what "verification template:
the gate's figures and their tree are in the squash commit, not the record"
asserts and why.

**finding-5**: guideline, medium — Names 4, "A concept has one name in every file, test and task of the change, and where the codebase already names it, that name" — tests/finish-merge.bats:800
disposition: fixed — tests/finish-merge.bats and tests/skills.bats name the
gated tree `gate_tree`, as scripts/finish-merge.sh does.

**finding-6**: guideline, medium — Names 4, "A concept has one name in every file, test and task of the change" — tests/finish-merge.bats:754
disposition: fixed — tests/finish-merge.bats names HEAD's tree `head_tree`
throughout, as scripts/finish-merge.sh does.

**finding-7**: guideline, low — Names 3, "A name says what the thing is in the project's domain, not its type or a role in general" — tests/finish-merge.bats:781
disposition: fixed — tests/finish-merge.bats names it `parent_tree`.

### Round 2

**finding-1**: guideline, low — Names 4, "A concept has one name in every file, test and task of the change, and where the codebase already names it, that name" — tests/skills.bats:2301
disposition: fixed — tests/skills.bats names it `step_6b`.

**finding-2**: guideline, low — Names 4, "A concept has one name in every file, test and task of the change, and where the codebase already names it, that name" — tests/finish-merge.bats:832
disposition: fixed — tests/finish-merge.bats names the awk flag `fenced`.

**finding-3**: guideline, low — Simplicity 4, "Where two parts of one change add the same helper, constant or check, one copy stays, where both can reach it" — tests/finish-merge.bats:830
disposition: fixed — `step_of` in tests/helpers.bash extracts a numbered
step; the four step 7 extractions in tests/finish-merge.bats and
tests/skills.bats call it.

**finding-4**: guideline, low — Names 2, "no chained conditional expression standing in for an `if`" — tests/skills.bats:2268
disposition: fixed — tests/skills.bats checks the two orderings separately,
each with its own message.

**finding-5**: guideline, low — Comments 2, "A comment describes the code as it is, never the change that wrote it: no ... 'previously' ..." — tests/check-signing.bats:93
disposition: fixed — tests/check-signing.bats states in the present tense what
the value read back is without `--no-show-signature`.

## Gaps

- Nothing compares `Gate-tree:` with the tree after a forge rebase or
  squash-merge: guard 5 runs once, where the squash is signed. The user ruled
  on 2026-10-14 to leave the forge flow to a later change, once they decide how
  PRs land; PR-m7gcuq records it open.
- The `Gate:` totals are copied from the gate summary by the agent; no script
  checks them. Only `Gate-tree:` is checked.
- The installed skill copies under `~/.agents/skills/` are the user's to
  refresh. Until they are, a squash message written from the old step 7 has
  no `Gate-tree:` trailer and guard 5 refuses its cleanup; the upgrade note
  gives the repair.
- Squashes already on `main` carry no `Gate-tree:` trailer; guard 5 reads
  only the squash it is finishing, so they are not re-checked.
- The pre-flight (`merge-preflight.sh`) was not run: this repository has no
  `.guardrails/`. `check-ids.sh` and `check-trace.sh` were run on scratch
  copies of `main` and of the change; both exit 1 on the findings `main`
  already has, and they differ only in this change's own IDs and problem file.
- Guard 5's refusal on a git older than 2.22, where the format placeholder is
  left unexpanded, is argued in its comment and not tested.
- PR-yd4pug stays open: with a remote, step 1 merges `origin/$BASE` while
  step 7 squashes onto the local base. This repository never fetches.
