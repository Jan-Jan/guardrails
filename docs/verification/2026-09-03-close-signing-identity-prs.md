# Verification — close-signing-identity-prs (2026-09-03)

branch: worktree-close-signing-identity-prs
reviewer: independent agent (fresh subagent, diff + repository only, no author narrative)
verdict: FINDINGS — four raised, all disposed below; form and verifiable claims confirmed, PR-dy8yup confirmed untouched
reproduced: nothing to reproduce — this change fixes no code. PR-52rnrn is closed as not-a-defect on measurements already made (the maintainer's shell ran `check-signing.sh --strict` to exit 0 on 2026-09-01 and completed the bd41d7a merge's cleanup through it on 2026-09-02); PR-tbn6q7's fix is untracked configuration, verified by bd41d7a — authored under the restored identity — sitting on origin/main.

Change: closes two of the three open items in
`docs/problems/2026-08-27-signing-and-identity.md` — PR-52rnrn (not a defect:
the merge flow hands verification and cleanup to the maintainer's own CLI,
where it works) and PR-tbn6q7 (repo-local identity restored, pushes accepted
again). PR-dy8yup stays open. Branched from local `main` at `3fe5eb3`.
Plan: none — a two-item ledger amendment, planned in conversation.

Base ref: `git fetch origin` was REFUSED from the agent shell
(`sign_and_send_pubkey: … agent refused operation` — the ssh auth key is on
the hardware card), so per merge-change step 1 the base was merged from the
local ref: `main` at `3fe5eb3`, which is itself ahead of the last known
`origin/main` (`bd41d7a`).

## The gate

Every figure derived from the tree under test, not carried forward. Run by a
dispatched gate subagent in the change worktree at `cf15266`; log at the
session scratchpad (`close-prs-gate2.log`, dies with the session — this record
is the durable evidence).

| Gate | Result |
| --- | --- |
| `./tests/run-tests.sh` (qualification suite) | 475/475 ok, 0 not ok, exit 0 |
| `check-ids.sh --allow-draft-files` (GR_CONFIG=templates/config.yaml) | exit 1 on main's own pre-existing plan-doc/fixture hits (44 DRAFT-ID, 10 DUPLICATE-ID, 2 MALFORMED-ID, all in `docs/plans/`, `README.md`, `tests/*.bats`); none attributable to this change. This repo has no `.guardrails/config.yaml` — no gate runs on this tree, the template config is a best-effort stand-in |
| `check-trace.sh` (GR_CONFIG=templates/config.yaml) | not runnable here — exit 2, `doc_srs is configured as 'docs/requirements', which does not exist` |
| Coverage, against the class target | not configured (no `coverage_command`); documentation-only change |
| Working tree | clean (`git status --porcelain` empty) |

## Red → green

No row: this change implements no IDs and adds no tests. It amends two
existing problem items from open to resolved; the qualification suite (above)
is the regression evidence that the amendment broke no grammar the tests
enforce.

| Item | Test | Watched red |
| --- | --- | --- |
| — | — | — (documentation-only closure; nothing to redden) |

## What was wrong, and what was built

Two ledger items were open that no longer described problems. PR-52rnrn
claimed signature verification blocks every merge's tail on this machine — but
the flow it worried about never runs where verification fails: merge-change
step 7 hands the signed commit and `finish-merge.sh` to the maintainer's own
CLI, where `--strict` exits 0 (measured 2026-09-01, exercised end-to-end at
the bd41d7a merge). The agent-side UNVERIFIED is a TCC-denied trustdb, which
bd41d7a now reports as exit 2, environment not project. PR-tbn6q7's lost
repo-local identity was restored in `.git/config` and GitHub accepts pushes
again. Both items were flipped to `status: resolved` in the dated file that
defines them, each with a resolution naming what it rests on and what it
leaves behind.

## Review

**finding-1**: PR-52rnrn's closure quietly buries the missing-allowed_signers
sub-problem its own affects: line names — 22 of 31 commits are ssh-signed and
permanently unverifiable while no `allowed_signers` file exists; the exit-0
claim can hold only for HEAD-scoped runs over recent OpenPGP commits.
disposition: accepted — the resolution now states it outright: the ssh-signed
history stays unverifiable everywhere, the flow never needs it verified
(finish-merge.sh checks the new HEAD only), and the gap is accepted for the
history, not repaired. Honesty restored in the ledger text itself (cf15266).

**finding-2**: closing PR-tbn6q7 orphans the residual gap it names — no gate
reads the author identity of the commit it is about to make, and no open
ledger item now tracks that.
disposition: accepted in part — no successor item is minted. The ledger
records observed failures; this is unbuilt gate territory, and it is carried
here in Gaps instead, where it stays a stated gap rather than a silent one.
Minting an open PR for it would re-open exactly what the maintainer asked to
close.

**finding-3**: PR-tbn6q7's resolution stated fix and evidence but no root
cause for how the identity was lost.
disposition: fixed — the resolution now declares the root cause unknown
explicitly ("declared rather than guessed") instead of omitting it (cf15266).

**finding-4**: PR-52rnrn's resolution prose sat between `status: resolved` and
the pre-existing AMENDED 2026-08-31 paragraph, inverting chronology so the
item read resolution-first, then an amendment describing the problem as still
live.
disposition: fixed — the resolution paragraph now follows the amendment,
prefixed RESOLVED 2026-09-03, so the item reads in the order it happened
(cf15266).

## Gaps

- The ssh-signed pre-OpenPGP history (22 commits) remains unverifiable in any
  environment absent an `allowed_signers` file. Accepted deliberately in
  PR-52rnrn's resolution; building that file is open territory nobody has
  claimed.
- No gate reads the author identity of the commit it is about to make
  (`check-signing.sh --setup` checks presence of `user.email`, not
  correctness, and not at commit time). Named by finding-2; deliberately not a
  ledger item.
- How the repo-local identity was lost (PR-tbn6q7) was never established —
  root cause unknown, declared as such in the resolution.
- `check-trace.sh` and `check-ids.sh` cannot run meaningfully on this tree (no
  `.guardrails/config.yaml`); the gate table records their template-config
  behavior verbatim.
- `git fetch origin` was refused from the agent shell, so the base was the
  local `main` (`3fe5eb3`), ahead of the last known `origin/main`. A remote
  moved past that between fetches would not have been seen by this merge.
