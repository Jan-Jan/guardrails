# Verification — ratchet-self-host (2026-10-05)

One record per change, written at `merge-change` step 6b and checked at step 6c
by `.guardrails/scripts/check-review.sh`. The squash commit references it on
its `Verified:` line, so this file is the evidence that travels with the change.

branch: ratchet-self-host
reviewer: rounds 1 to 4, each a fresh subagent with the diff, the ratchet skill, the predecessor documents, AGENTS.md and `skills/merge-change/references/review-checklist.md`, and no implementation narrative
verdict: round 1 REJECT on one medium requirement finding; round 2 REJECT on one medium requirement finding; round 3 REJECT on one medium requirement finding; round 4 ACCEPT on one low requirement finding and three record findings, which makes it the last review round
reproduced: not applicable to the plan documents, which repair nothing. PR-ww36qr, which this change opens and does not fix, was reproduced: `zsh -c 'true; status=$?'` prints `zsh:1: read-only variable: status` and exits 1, and the change's first gate run lost the suite's exit status that way.

Change: the second `/ratchet` run on this repository, as its own target: a gap
analysis and setup checklist, with the problem item for a defect the run found.
Branched from `main` at `35570e8`; local `main` was unchanged through the four
review rounds, then advanced to `407ffe7` (the `pr-9aaart` change) during the
final gate; base merged from local `main` at `407ffe7` (f6e4ca7), per AGENTS.md
non-negotiable 5.
Plan: `docs/plans/2026-10-05-ratchet-gap-analysis.md` and
`docs/plans/2026-10-05-ratchet-setup.md`.

Opened while `churn-proposal`, `parallel-session-proposals` and `pr-9aaart`
were open, against AGENTS.md non-negotiable 4, by the user's decision of
2026-10-05.

## The gate

Every figure below is measured on one tree, and the table names it, so a later
reader can re-measure the same tree instead of guessing which round produced
these numbers. **No figure here is copied forward from an earlier round.**

The toolkit has no `.guardrails/config.yaml`, so the check scripts run under a
synthesized config: `safety_class: A`, `id_prefixes: PR`,
`doc_problems: docs/problems`, `doc_verification: docs/verification`, the lists
`strict_paths` (`scripts`), `test_paths` (`tests`) and `verify_commands`
(`sh tests/run-tests.sh`), and the template's four triage limits.
`check-ids.sh` and `check-trace.sh` are red on `main`, so the criterion is no
finding on the branch that `main` lacks.

Measured on: `f6e4ca7` — `git rev-parse HEAD` — tree
`6358b420434eea6b15b80a9ebcf1b4d1a1e185e0`, from `git rev-parse HEAD^{tree}` on
a clean worktree, after step 3 renamed this change's draft problem file and
local `main` at `407ffe7` was merged in. The `main` columns compare against a
snapshot of `407ffe7`.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | exit 0 (captured) — `1..1055`, 1055 ok, 0 not ok, 0 skipped, counted from TAP lines |
| `check-ids.sh` | exit 1 on branch and on `main` at `407ffe7`; with line numbers removed, identical |
| `check-trace.sh` | exit 1 on branch and on `main` at `407ffe7`; the only differences are this change's own: `UNRESOLVED-PR PR-ww36qr` and the counts it moves (PR-ww36qr enters the roll-call) |
| Coverage, against the class target | not configured; class A has no target |
| Working tree | clean at start and end; no `DRAFT-` file under `docs/` |
| `merge-preflight.sh --before-review --local-base` | CLEAN-TREE ok, BASE-MERGED ok (local base only); exit 1 at IDS, on the findings `main` has |

The suite also ran at earlier rounds, each on its own tree. Round 1, at
`88ac428` (tree `c21377f52428a81d3b38f6ef83782d442766a49a`, `scripts/` and
`tests/` identical to `35570e8`), is the tool-qualification run the setup
checklist cites: `1..1053`, 1053 ok, 0 not ok, 0 skipped; its exit status was
not captured (PR-ww36qr).

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| none | this change implements no item | not applicable |

## What was wrong, and what was built

The first ratchet pass (2026-08-22) deferred installing the machinery because
the repository's example and fixture text trips the tree-wide gates, and
ordered a scan exclusion first. That exclusion was never built. This change
re-measures the blocker at `35570e8` (`check-ids.sh` 76 findings,
`check-trace.sh` about 140, nearly all example text), records the ruling that
`.guardrails/scripts/` is a pinned install allowed to differ from `scripts/`,
restates the adoption order with an exit criterion per tooth, and replaces the
setup checklist, whose signing entries described an SSH key no longer in use.
It opens PR-ww36qr, found by its own first gate run.

## Review

### Round 1

**finding-1**: requirement, medium — Gap analysis tooth 1 says that after teeth 0 and 1a, "Both check scripts exit 0 on the result". That is not reachable. Example-ID prose inside the `docs/problems/` ledger causes four `DANGLING-REF`s. No exclusion of non-ledger paths removes them, and tooth 1a does not touch them. §5's paragraph "Real findings, in `docs/problems/`… fail the install whatever tooth 0 excludes" lists only the backlog and the stale items. Evidence: on an extracted copy with the five §6 paths and `skills/` removed and the problem limits raised to 999/99, `check-trace.sh` still exits 1. It prints `DANGLING-REF PR-001`, `REQ-001`, `REQ-002` and `REQ-a3k9z2`. Their sources: `docs/problems/2026-09-28-plan-quoted-ids.md:63` and `docs/problems/2026-09-17-mutation-evidence.md:234,238`.
disposition: fixed in c4cadb5: §5 names the four IDs and their files, tooth 0 must decide how a ledger quotes an example ID, and tooth 1a clears them by the form tooth 0 chooses. Rounds 2 and 3 found the order still unreachable; see findings 9 and 14.

**finding-2**: requirement, low — The tooth 0 path list ("must cover `tests/`, `docs/plans/`, `docs/verification/`, `README.md` and `scripts/`") leaves out `skills/`, which also carries example IDs that `DANGLING-REF` flags. Evidence: `git grep -n 'REQ-002\|REQ-a3k9z2' -- skills` returns `skills/ratchet/references/upgrade-notes.md:94,96,101` and `skills/worktree-discipline/SKILL.md:136`.
disposition: fixed in c4cadb5: `skills/` is in the list.

**finding-3**: record — §5 says the measurement added only "the template READMEs for `docs/requirements/` and `docs/architecture/`". With only those, `check-trace.sh` exits 2, not 1. `docs/architecture/soup.md` must be added too.
disposition: fixed in c4cadb5: §5 names `soup.md` and `CONTEXT.md` as added.

**finding-4**: record — §1 Signing says "the 32 newest read `G`… The 23 oldest read `N`". The two kinds are interleaved, not split at commit 32. The totals (32 G, 22 SSH, 1 unsigned) are correct.
disposition: fixed in c4cadb5: the row gives counts of the 55 and states the eras are interleaved.

**finding-5**: record — Tooth 3 says that without `allowed_signers`, `check-signing.sh --strict` over the full history "fails on 22 commits that carry an SSH signature". This implies restoring the file makes a full-history strict pass. It does not: the unsigned root commit 3f1f457 still fails as `UNSIGNED`.
disposition: fixed in c4cadb5: tooth 3 states the root commit fails, and the pipeline checks `main..HEAD`.

**finding-6**: record — §4's "Consequence for tooth 0. The scans exclude `.guardrails/scripts/` and nothing else, so `scripts/` stays in scope" can be read as contradicting §6, where tooth 0's exclusion "must cover … `scripts/`".
disposition: fixed in c4cadb5: the bullet names the built-in exclusion and leaves `scripts/` to tooth 0.

**finding-7**: record — The header says the change "opens alongside two unmerged changes". A third change, `pr-9aaart`, is also open.
disposition: fixed in c4cadb5: three changes are named.

**finding-8**: record — The setup checklist does not state a suite result. It defers to `docs/verification/2026-10-05-ratchet-self-host.md`, which does not exist on the branch.
disposition: fixed in c4cadb5, and in 20cea89 under finding 13: the checklist states the round 1 figures, and this record exists.

### Round 2

**finding-9**: requirement, medium — Tooth 1's "Both check scripts exit 0 on the result" cannot be reached after teeth 0 and 1a as §6 now describes them. DANGLING-REF looks for references in the doc files plus `strict_paths` plus `test_paths` (`check-trace.sh:760-761`). `GR_SCAN_EXCLUDE` applies only to the definition scans (`check-trace.sh:497,772`). Excluding `tests/` from the definition scans removes the fixtures' example definitions. Tooth 1's own `test_paths: tests` then reports every fixture reference as dangling. Evidence: `GR_SCAN_EXCLUDE` patched to the six §6 paths, the four ledger IDs reworded, `strict_paths: install.sh`: `trace=1` / `104 DANGLING-REF`.
disposition: fixed in 20cea89: tooth 0 states an exit criterion and lists the reference scope as a design input instead of prescribing a mechanism.

**finding-10**: record — §5 says "The six six-character ones (…) … the rest are the pre-token forms". False: `REQ-a3k9z2`, `REQ-e7x2m4`, `REQ-h8s3t2`, `SDD-d2s6fk` and `LLR-b4r7pq` are flagged too, and `REQ-a3k9z2` occurs in `scripts/` and `skills/`.
disposition: fixed in 20cea89: §5 states every flagged item is an example, in both forms, and lists every path they occur in.

**finding-11**: record — §5 says the four ledger IDs are "reported as `DANGLING-REF` whatever tooth 0 excludes". In §5's own measurement none is a DANGLING-REF; they resolve to example definitions elsewhere.
disposition: fixed in 20cea89: §5 states they become `DANGLING-REF` once tooth 0 removes those definitions.

**finding-12**: requirement, low — §5 and §6 tooth 1 write list keys in scalar form (`verify_commands: sh tests/run-tests.sh`, `strict_paths: scripts`), which the closed schema rejects.
disposition: fixed in 20cea89: list keys are written as lists.

**finding-13**: requirement, low — `setup-checklist.md` asks for "Suite result at install time". The setup document fills this only by pointing to a record not in the diff.
disposition: fixed in 20cea89: the checklist states the round 1 figures and the tree they describe.

### Round 3

**finding-14**: requirement, medium — Tooth 0 cannot meet its own exit criterion if it goes first, which §6 explicitly allows. The criterion says both checks exit 0 "on this tree", but tooth 1a says "either may go first". The problem-ledger findings fail whatever tooth 0 excludes. The criterion also leans on the tooth 1 `strict_paths`, which is not fixed yet.
disposition: fixed in fea0f7f: tooth 0's criterion covers the findings it owns, tooth 0 chooses and records `strict_paths`, and tooth 1's exit 0 needs teeth 0 and 1a.

**finding-15**: record — Design input 2 says `DANGLING-REF` reads references "from every `doc_*` file". It does not read `doc_verification`.
disposition: fixed in fea0f7f: the five keys are named.

**finding-16**: record — Design input 3 says "The four passages of §5". The four IDs sit in three lines across two files.
disposition: fixed in fea0f7f.

**finding-17**: record — In the setup checklist, "the proof is the next item" names the wrong item.
disposition: fixed in fea0f7f: it names "Prove the chain".

### Round 4

**finding-18**: requirement, low — Tooth 0's exit criterion is measured "on this tree" with the tooth 1 configuration, which names `doc_srs` and `doc_soup` that only tooth 1 creates; on the tree tooth 0 owns, check-trace exits 2.
disposition: fixed in 27092ce: the criterion is measured on a scratch copy with the skeleton additions §5 used.

**finding-19**: record — Design input 2 says the reference scan is at line 806; the `git grep` is on line 807.
disposition: fixed in 27092ce.

**finding-20**: record — §1 calls `docs/problems/` "the only ID-bearing ledger", but the five ADRs each define an ID.
disposition: fixed in 27092ce: "among the four per-change ledgers".

**finding-21**: record — Design input 2 says `GR_SCAN_EXCLUDE` "applies only to the definition scans" unqualified; `check-ids.sh` also applies it to the DRAFT-ID scan.
disposition: fixed in 27092ce: qualified to `check-trace.sh`, with the three `check-ids.sh` sites named.

## Gaps

- `check-signing.sh --setup` was not proved: from an agent shell it timed out
  waiting for the hardware-key touch. The user runs it.
- The §4 ruling is recorded here and in the gap analysis, not as an ADR.
- No gate ran under an installed config; every check figure is under the
  synthesized config above.
- Each finding above keeps the reviewer's statement word for word; some of
  the evidence lines that followed it are shortened or left out.
- The round 1 suite's exit status was not captured (PR-ww36qr); its figures are
  counted from the TAP lines.
