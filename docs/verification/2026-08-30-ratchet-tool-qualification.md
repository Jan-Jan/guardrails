# Verification — the ratchet checklist says how the qualification suite runs (2026-08-30)

branch: worktree-ratchet-tool-qualification
reviewer: one independent subagent review, dispatched fresh with the diff and full repository access, no implementation narrative and no chat history; it re-ran the suite in its own task worktree because the diff touches tests/
verdict: approve — the fix addresses PR-ac96zf precisely, the reproduction test is genuinely load-bearing (each of its three anchors mutation-verified: the reviewer deleted or altered each phrase in a scratch copy and watched the test fail), ledger discipline is clean, and the full suite is green. Three findings raised, none blocking, each dispositioned below.
reproduced: yes — tests/skills.bats was written first and watched red for the right reason (`not ok 1`, failing at its first grep because the skill carried no `tests/run-tests.sh` anchor), then green after the one-paragraph fix and nothing else changed.

Change: resolves PR-ac96zf (`docs/problems/2026-08-30-tool-qualification.md`) —
the ratchet skill's step-5 tool-qualification checklist item asked the
installer to record the qualification suite result but never said how or where
the suite runs, leaving a `/ratchet` run in a target project to improvise, up
to and including installing bats there. Branched from `main` at `4536e94`.
Plan: none — a single-task problem fix under the resolve-problem skill; the
problem item is the record of scope.

## The gate

Every figure derived from the tree under test, not carried forward.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` (pre-finalize, HEAD 11d6bf9) | 410/410 ok, TAP plan `1..410`, 0 not ok, 0 skips — counted from the TAP stream, not the exit code |
| `tests/run-tests.sh` (post-finalize, step 6) | 410/410 ok, TAP plan `1..410`, 0 not ok, 0 skips |
| `tests/run-tests.sh` (independent, reviewer's own task worktree) | 410/410 ok, plan `1..410`, 0 not ok — counts the reviewer saw, not counts handed over |
| `check-ids.sh` / `check-trace.sh` | guardrails does not self-install its machinery (no `.guardrails/config.yaml`; the repo's plans and test fixtures legitimately quote draft-token examples that the full-tree scans flag — a pre-existing, documented condition). A scoped run over the problems ledger alone (`id_prefixes: PR`, `doc_problems`/`strict_paths: docs/problems`) reports nothing against this change's file: PR-ac96zf parses, no MALFORMED-ID, no INCOMPLETE-PROBLEM; the one UNRESOLVED-PR warning is the pre-existing, deliberately open PR-aap8nx (3 days, owner Dr. Jan-Jan van der Vyver) |
| Coverage, against the class target | not configured on this repo |
| Working tree | clean (`git status --porcelain` empty, both gate runs) |

The base was merged from a local ref, not a freshly fetched one: `git fetch
origin` fails in this environment with `Bad owner or permissions on
/etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf`, exit 128 — the same recorded
environment fault as the 2026-08-30 skill-context-economy record. The merge
was `Already up to date`; the base commit the duplicate scan was compared
against is **`4536e94`**.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-ac96zf` | `tests/skills.bats: ratchet: tool qualification says how and where the suite runs` | watched failing (`not ok 1`, first anchor grep) before the checklist paragraph existed; green immediately after the minimal edit. First-hand: this single-task fix ran its TDD loop in the change worktree with no fan-out, so the author observed the red directly rather than via a dispatch report |

## What was wrong, and what was built

The step-5 checklist item named the qualification basis (the guardrails bats
suite at the recorded `guardrails_version`) and what the setup document
records, but omitted the procedure that produces the suite result. Nothing
forbade producing it in the target project or installing bats to do so — the
exact improvisation DO-330-lite qualification exists to prevent. Investigation
confirmed every piece the missing paragraph leans on already conforms:
`tests/run-tests.sh` uses a system bats or vendors bats-core v1.11.0 into
`tests/.bats-core`, that path is gitignored, and `guardrails_version` is a
schema key in `templates/config.yaml` and `scripts/lib.sh`. The fix is one
paragraph in the checklist item stating the procedure — run
`<guardrails>/tests/run-tests.sh` exactly once upstream, record the outcome
(version, commit, pass/fail) rather than the tooling, never install bats into
the target project, and record `suite not run at install time: <reason>` when
the run cannot complete — plus `tests/skills.bats`, a content lint pinning the
three load-bearing phrases.

## Review

**finding-1**: [note] The ledger file was renamed to its dated form by commit f0afe79 on the change branch itself, while the README says the dated name carries the merge date assigned by merge-change; if the merge slipped past 2026-08-30 the filename would not be the merge date.
disposition: no change — the rename is merge-change step 3 in flight, and the merge completed on 2026-08-30, so the filename is the merge date. Had the merge slipped, step 3 re-runs and the file would have been renamed to the actual date before the squash.

**finding-2**: [nit] The three greps in tests/skills.bats use unescaped BRE dots, so `tests/run-tests.sh` also matches `tests/run-testsXsh`.
disposition: no change — accepted as harmless for a content lint. The reviewer's own mutation runs demonstrated every phrase-level break the test exists to catch does fail it; the unescaped dot admits only strings no plausible edit produces.

**finding-3**: [note] The resolution block runs ~8 lines against the README grammar's "one line — root cause + fix reference".
disposition: no change — matches the established style of every resolved item in `docs/problems/2026-08-27-macos-awk.md`; the grammar comment describes the minimum, and the checker does not judge length.

## Gaps

- `check-ids.sh` / `check-trace.sh` still cannot run over this repository's
  full tree (pre-existing: the scan-exclusion gap measured in
  `docs/plans/2026-08-22-ratchet-gap-analysis.md`); this change neither
  narrows nor widens that.
- The new content lint pins the ratchet skill only. No other skill has
  content tests; `tests/skills.bats` is the place to add them when a skill
  phrase becomes load-bearing.
- (Closed while writing this record: `check-review.sh --branch
  worktree-ratchet-tool-qualification` DOES run under the scoped config —
  `checked: records 18, for worktree-ratchet-tool-qualification 1, findings
  3`, exit 0 — so this record is mechanically checked, not just shaped by
  hand. Provenance is not checked under `--branch`, as the script states.)
