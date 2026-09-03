# Verification — check-signing.sh reports the verifier's reason (2026-09-03)

branch: signing-verifier-reason
reviewer: two rounds, each a fresh subagent dispatched with the diff, the plan
and the ledgers, and with no implementation narrative — each ran the suite
itself in its own nested worktree rather than resting on the author's figures.
verdict: round 1 — "the code does what the plan and the ledger items claim,
and I reproduced every environmental measurement they rest on end to end — but
three of the change's claims outrun their evidence": two behaviours untested and
surviving deletion silently, one item closed while its stated symptom still
reproduced, plus four documentation defects. Seven findings, all accepted, all
answered. Round 2, after the fixes — "five findings, none of them defects in the
shipped behaviour"; it reproduced all three redden-proofs independently, then
mutated the rest of the diff as well and reported "every behaviour this change
adds to scripts/check-signing.sh now has a test that fails when it is removed.
No un-bitten line remains." Its five findings were documentation, three of them
this change failing its own standard applied to itself; all five are answered
below.
reproduced: yes, end to end and in both directions. The reported symptom was
reproduced on the maintainer's machine before any fix — `check-signing.sh
--strict` on `main` printed `UNVERIFIED <sha> (signature present but not
verifiable)` and nothing else, while `git verify-commit` on the same commit
printed `gpg: Fatal: can't open '.../trustdb.gpg': Operation not permitted`,
proving the cause was available and discarded. The root cause was then measured
directly: `git log --format=%G?` returns one letter and zero bytes of stderr
for that state. The fix was reproduced in the other direction too — with a
writable `GNUPGHOME` copy of the same keyring the identical commit verifies
`%G? = G`, "Good signature ... [ultimate]", which is what establishes that the
signature was never the problem.

Change: `check-signing.sh` prints the verifier's own words under every
non-passing verdict instead of guessing a cause, and `--setup` stops calling
git's default signature format missing. Branched from `main` at `bd41d7a`; merged `main` four times as it advanced, last at `817156c`.
Plan: `docs/plans/2026-09-01-verifier-reason.md`.

Resolves PR-whkz8m, PR-74gcqg, PR-mtmr7h. Opens PR-2scmvn, PR-r8q9m7,
PR-k4t9k2 — deliberately, each recorded rather than remembered.

**This change no longer resolves PR-52rnrn.** It did until 2026-09-03, when
`817156c` closed that item on `main` on separate and correct grounds: the merge
flow was never broken, because it runs in the maintainer's own shell. That
closure is the item's disposition and this change does not compete with it. But
the reporting defect PR-52rnrn's statement also named — the gate asserting a
cause it never read — was then a defect this change fixes with no open item
behind it, which is unmarked derived work. It is now carried by **PR-whkz8m**,
minted for it, and the three tests that verify it name that item instead. The
`verifies:` annotations were re-pointed, not deleted: they verify the same
behaviour they always did, under the item that is still about it.

## The gate

Every figure derived from the tree under test, not carried forward.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | 482 ok, 0 failures, 0 skipped, exit 0 (plan `1..482`). Re-run after step 3: identical. |
| `check-ids.sh` (no flag) | 0 DRAFT-FILE, 0 MALFORMED-ID, 0 new DUPLICATE-ID. Output byte-identical to `main`'s. |
| `check-trace.sh` | Delta vs `main`: PR-2scmvn, PR-r8q9m7 and PR-k4t9k2 enter the open list; `checked: PR 21 -> 27`. No other line differs — no new MISSING-TEST, DANGLING-REF, ORPHAN-ANNOTATION or MISPLACED-ITEM. |
| Coverage, against the class target | Not configured — no `coverage_command` exists. Not a pass; nothing was measured. |
| Working tree | Clean. No nested worktree registered (step 6d). |

Both check scripts are red in absolute terms on this branch AND on `main`, for
the same pre-existing violations: the toolkit's own fixtures and plans carry
illustrative draft tokens that a real install excludes via `GR_SCAN_EXCLUDE`,
and this repository cannot yet self-host its own gates — it has no
`.guardrails/config.yaml`, so both runs used a synthesized one. The measurement
is therefore the delta against `main`, not the verdict, and the delta is stated
above.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-whkz8m` | `check-signing: a failed verdict carries the verifier's own reason` | yes — T1 subagent, against the old wording: `the verifier's reason was discarded: UNSIGNED ... (bad, expired, or revoked signature)` |
| `PR-whkz8m` | `check-signing: the verifier's reason is reported once, under its verdict` | yes — T4 subagent: `git's own diagnostic leaked, unindented, above the verdict` |
| `PR-whkz8m` | `check-signing: an untrusted signature carries the verifier's reason too` | yes — orchestrator, first-hand, `verifier_reason` deleted from the `U\|E` branch: `the verifier's reason was discarded: UNVERIFIED ...` |
| `PR-74gcqg` | `check-signing: a verifier that cannot run is not called a forgery` | yes — T1 subagent: `still asserts a cause it did not measure: UNSIGNED ... (bad, expired, or revoked signature)` |
| `PR-mtmr7h` | `check-signing: --setup does not call git's default format missing` | yes — T2 subagent: `still reports the default as missing: MISSING gpg.format ...` |
| `PR-mtmr7h` | `check-signing: --setup carries a real format into the proof, not an empty one` | yes — orchestrator, first-hand, the default line deleted: `UNPROVED signing` / `invalid value for 'gpg.format': ''` |

One test in this change deliberately carries **no** `verifies:` annotation:
`check-signing: a rejected signature still fails without --strict`. It was green
on its first run, before the script was touched, and could not have been
otherwise. It pins the verdict against the wording change; it verifies nothing,
and annotating it would put a `verifies:` line behind no red→green attestation.

## What was wrong, and what was built

`git log --format=%G?` answers with one letter and **discards the verifier's
output**. `check-signing.sh` filled that gap by guessing: it appended the
`gpg.ssh.allowedSignersFile` remedy to every failing verdict alike.

This repository's history is signed two ways — measured at `f64be47`, 17 of the
last 20 commits ssh and 3 OpenPGP — and the two fail for entirely different
reasons. The ssh ones because no `allowed_signers` file exists; the OpenPGP
ones because gpg opens `trustdb.gpg` read-write even to read it, and `~/.gnupg`
is not writable by the agent's process tree. One identical line covered both,
with a remedy correct for one and irrelevant to the other. Acting on it would
have repaired seventeen commits and left the three most recent — every HEAD a
merge gate inspects — failing for a reason still unnamed.

The fix asks `git verify-commit` for the verifier's own words and prints them
indented under the verdict, and suppresses `%G?`'s own stderr so the reason
appears once and identically for both formats. On the real repository:

```
WARN-UNVERIFIED bd41d7a (signature present but did not verify)
    gpg: Fatal: can't open '/Users/.../.gnupg/trustdb.gpg': Operation not permitted
WARN-UNVERIFIED 5bc6495 (signature present but did not verify)
    error: gpg.ssh.allowedSignersFile needs to be configured and exist ...
```

Separately, `--setup` reported `MISSING gpg.format` against a project that
signs correctly with git's documented default (`openpgp`), and — because a
named gap returns before the proof — that false positive suppressed the only
half of `--setup` that measures anything.

**The severity recorded against PR-52rnrn was wrong, and measuring it is what
found the defect.** No signature is unverifiable: in the maintainer's own
terminal `check-signing.sh --strict` exits 0. The restriction is on the agent's
process tree — `O_RDONLY` succeeds, `O_RDWR` and `touch` are refused, with
correct ownership, mode `drwx------`, no ACLs, and it survives disabling the
agent's sandbox — so it is the host application's macOS TCC grant. The merge
path this toolkit prescribes was never blocked, because step 7 hands the signed
commit to the user to run in their own shell. What this makes it is a defect
about **agents in sandboxes**, which is a normal operating condition for this
toolkit and precisely the condition the old code handled worst.

## Review

**finding-1**: Two behaviours the change introduces are untested and survive
deletion in silence. Deleting `[ -n "$_fmt" ] || _fmt=openpgp` from `run_setup`
leaves all 29 tests green, yet its removal is a real regression: `_fmt` is
written into the throwaway repository, and `git config gpg.format ""` is
rejected by git, so `--setup` reports a false `UNPROVED` against a project whose
configuration is fine — this repository's own shape.
disposition: `check-signing: --setup carries a real format into the proof, not
an empty one` (tests/check-signing.bats). Watched red with the line deleted:
`UNPROVED signing` / `error: invalid value for 'gpg.format': ''`. Round 2
reproduced the proof independently and confirmed the mutation reddens that test
and no other.

**finding-2**: `verifier_reason "$c"` in the `U|E` branch of `check_commits` has
no test — deleting it leaves the suite green, though the branch is reached three
times across the suite. Of the three call sites the change adds, one was
exercised but entirely unasserted.
disposition: `check-signing: an untrusted signature carries the verifier's
reason too`, reaching `U|E` with a present-and-readable signers file naming a
different key. Watched red with the line deleted: `the verifier's reason was
discarded: UNVERIFIED ...`. The test hard-asserts `%G?` is `U` before running,
so fixture drift to `B` or `N` fails loudly rather than passing silently.

**finding-3**: PR-52rnrn is flipped to resolved, but the second clause of its own
statement — "and the default gate reports that as a pass" — still reproduces:
non-strict exits 0 on an unverifiable HEAD.
disposition: superseded by events, and correctly. `817156c` has since closed
PR-52rnrn on `main` on its own grounds, and this change no longer resolves that
item at all. The residue the finding names was answered on the way there:
`merge-change` step 8 called the tolerant `check-signing.sh` under the comment
`# verifies the new HEAD`, and now passes `--strict`, so no step in this toolkit
calls the tolerant mode verification.

**finding-4**: `skills/ratchet/SKILL.md` still says `--setup` checks that
`gpg.format` is set — behaviour this change deleted. The same stale-prose class
the change exists to remove.
disposition: corrected, and the reason stated rather than the sentence merely
trimmed: unset is git's documented `openpgp` default. Round 2 then found the
identical claim still standing in `README.md` (its finding-1) — corrected there
too.

**finding-5**: PR-2scmvn says "green four times out of six", counting two
single-file runs as full suite runs. As measured it was 2 of 4, so an item whose
whole point is that "0 failures" is probabilistic misstated its own probability.
disposition: corrected to "green on 2 of 4 full runs", in the narrative and the
closing sentence both.

**finding-6**: The ledger preamble still reads "Both items were found on
2026-09-01 ... recorded here before either was fixed"; the file now defines five.
disposition: rewritten to name the two found that day and the three that joined
later, each with how it was found.

**finding-7**: `check-signing: the verifier's reason is reported once, under its
verdict` does not verify "once" — two indented copies would pass it unchanged.
disposition: a count assertion added (`n -eq 1`). Watched red with
`verifier_reason` called twice in the `*)` branch: `the reason appeared 2 times,
not once`.

**finding-8**: (round 2) `README.md:132` still lists `gpg.format` among what
`--setup` proves — round 1's finding-4 was applied to `ratchet` but not to the
file most readers see first.
disposition: corrected, naming the default explicitly.

**finding-9**: (round 2) A test comment states a cause it did not measure — the
exact defect this change exists to remove. It claims both other reason tests
land in `*)` (`%G? = N`); measured, the broken-verifier fixture is `B`.
disposition: measured directly (`%G? = B`, confirmed independently by the author)
and the comment corrected to name both branches. The conclusion it supported —
that `U|E` was the uncovered call site — was right; the stated reason was not.
This is the finding worth keeping in view: a change about a tool asserting an
unread cause shipped a comment asserting an unread cause.

**finding-10**: (round 2) PR-52rnrn's "the tolerant mode was never the gate"
overstates by one call site: `merge-change` step 8 invokes the bare form under
`# verifies the new HEAD`.
disposition: closed rather than documented — step 8 now passes `--strict`. The
reviewer offered either; documenting a known-weak check would have been the same
class of error this change is about.

**finding-11**: (round 2) The rewritten header no longer records that a REJECTED
signature fails in BOTH modes with no `WARN-` counterpart — information the old
header carried.
disposition: restored to the verdict table, with the `%G?` letters that
distinguish the case.

**finding-12**: (round 2) The ledger was finalized 2026-09-02 but the review loop
pushed the merge to 2026-09-03, and `finalize-docs.sh` is a no-op once the file
is no longer `DRAFT-`-named, so the ledger would land dated a day before the
commit carrying it.
disposition: re-dated by hand to what `finalize-docs.sh` would have written.

## Gaps

- **`git fetch` could not run.** The hardware key refuses non-interactive
  touches (`sign_and_send_pubkey: signing failed ... agent refused operation`),
  so step 1 merged the base from the LOCAL `main` ref at `bd41d7a`, not from
  `origin/main`. Whether the remote had moved past it is unknown from here.
  `merge-change` step 1 requires this be named rather than glossed over, and
  this is that naming.
- **The suite is not deterministic**, recorded as PR-2scmvn. It was green on 2
  of 4 full runs during one task; every run since has been green, including
  both round-2 runs and both reviewers'. Every "0 failures" in this record is
  therefore a probabilistic claim, and the probability is not known.
- **No coverage was measured.** `coverage_command` is not configured, so no
  class target was judged.
- **PR-k4t9k2 is open, and it is adjacent to this change's own subject.**
  `main`'s `trust_root_env_guard` tests `-r`/`-x` on the keyring; the state
  this whole investigation began from is readable, executable and NOT writable,
  so the guard does not fire and the verdict stays exit 1 for an environment
  fault. This change makes that state legible without reclassifying it, which
  is a decision belonging to the design `bd41d7a` introduced.
- **PR-r8q9m7 is open:** seventeen ssh-signed commits remain unverifiable
  everywhere, and nothing in the toolkit asks about history at all —
  `check-signing.sh` defaults to HEAD and `finish-merge.sh` passes it one
  commit. A merge gate that inspects only the commit it just made will report a
  green tail over an unverifiable trunk indefinitely.
- **PR-52rnrn's disposition is not this change's.** `817156c` closed it, and
  this record does not re-argue it. What this change carries from that
  investigation is PR-whkz8m, minted on 2026-09-03 for a defect found on
  2026-09-01 — a two-day gap between finding and recording that the item states
  itself. `resolve-problem` says record before investigating; that was done, but
  against an item another change then closed for its own reasons, which is a
  failure mode the skill does not describe.
- **T5's tests were authored by a subagent and verified by the orchestrator,
  not by an independent party at the time of writing.** The subagent stalled
  twice without committing; its work was committed by the orchestrator, who
  then took the three redden-proofs first-hand. Round 2's review covers them.
