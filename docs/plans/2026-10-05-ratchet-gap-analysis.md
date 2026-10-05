# Ratchet gap analysis — guardrails self-hosting, second pass

Date: 2026-10-05
Mode: **retrofit** (55 commits on `main`, populated `docs/`, no `.guardrails/`)
Guardrails version: **0.5.1** (`templates/config.yaml`), commit `35570e8`
Predecessor: `docs/plans/2026-08-22-ratchet-gap-analysis.md`

The first pass found that the machinery could not be installed on this
repository because its own example and fixture text trips the tree-wide gates,
and it ordered a scan-exclusion mechanism ("tooth 0") before the install. Tooth 0
was never built. This pass re-measures the blocker at `35570e8`, records a
decision the first pass left open (how `.guardrails/scripts/` relates to
`scripts/`), and restates the adoption order.

This change is documentation only. It opens alongside three unmerged changes,
`churn-proposal`, `parallel-session-proposals` and `pr-9aaart`, by the user's
override of AGENTS.md non-negotiable 4 on 2026-10-05.

## 1. What exists

| Area | State |
|---|---|
| `AGENTS.md` | Hand-written, guardrails-shaped, five non-negotiables. No managed block markers. |
| `CLAUDE.md` | Absent. |
| Worktrees | Followed by hand. `.gitignore` has `.worktrees/`, `.claude/worktrees/` and `*.bak`. |
| Signing | The key is now OpenPGP on a hardware key (`gpg.format openpgp`); the 2026-08-22 setup checklist records an SSH key. Of the 55 commits on `main`, 32 read `G` (checked with a writable copy of `~/.gnupg`, per AGENTS.md), 22 carry an SSH signature and read `N`, and the root commit `3f1f457` is unsigned. The two signing eras are interleaved in `git log` order. The SSH-signed commits cannot be verified because `gpg.ssh.allowedSignersFile` is no longer configured (`error: gpg.ssh.allowedSignersFile needs to be configured and exist`), although the first pass recorded it as set. `check-signing.sh --setup` from an agent shell times out waiting for the touch, so the user runs it. |
| Safety class | A, `docs/adr/ADR-q54hjw-safety-class.md`. Eleven verification records call the toolkit "unclassified", which contradicts the ADR. |
| Tests | `tests/*.bats` under `tests/run-tests.sh`, 1053 tests in the last record's final gate (`docs/verification/2026-10-05-adr-ids.md`). |
| Ledgers | `docs/problems/` holds 22 dated files and the README: real `PR-` items, the only ID-bearing ledger among the four per-change ledgers (requirements, risk, architecture, problems). `docs/risk/` holds two prose assessments with no item IDs and no README. `docs/adr/` holds five ADRs. |
| Records | `docs/verification/` holds one record per change since 2026-07-20. |
| How the gates run today | Under a synthesized config (`id_prefixes: PR`, `doc_problems`, `doc_verification`, the list `strict_paths` holding `scripts`, the list `test_paths` holding `tests`). `check-ids.sh` and `check-trace.sh` are red on `main`, so each record's criterion is "no finding on the branch that `main` lacks". |
| `find-items.sh` | Exits 2 here (`file not found: .guardrails/config.yaml`), although the installed skills direct agents to it. |
| CI | None. |

## 2. What is missing

- `.guardrails/config.yaml`, `.guardrails/scripts/` and
  `.guardrails/templates/verification.md`.
- `docs/requirements/` and `docs/architecture/` (with `soup.md`), each with its
  README grammar; a README in `docs/risk/`.
- `docs/CONTEXT.md` and `CLAUDE.md`.
- The managed block in `AGENTS.md`.
- Any REQ, HAZ, RC, SDD or LLR item for the toolkit's own behavior. Its
  requirements are prose in `README.md`, the skills and the script headers, and
  the bats suite is their executable specification.

## 3. Conflicts with the managed block

1. **Two "Non-negotiables" sections.** The block's three are compatible with
   the repository's five. The repository's are narrower: `main` by name, local
   `main` as the base (non-negotiable 5), the gate dispatched to a subagent.
   Keep both, the block appended below, and state that the repository's rules
   govern where they are narrower.
2. **`## Code: names` twice.** The text is identical. Keep both: the block is
   managed and is replaced whole on every upgrade.
3. **`verify_commands`.** The template ships `make test`; set
   `sh tests/run-tests.sh`.
4. **`merge-change` step 1's fetch.** Already overridden by non-negotiable 5,
   with `ADR-y8jmes-local-main-is-the-base.md`. Unchanged by the install.

## 4. Decision: `.guardrails/scripts/` is a pinned install, separate from `scripts/`

The first pass offered a symlink `.guardrails/scripts -> ../scripts`, or a copy
with a test asserting the two are identical. Both keep the installed scripts
equal to the development scripts. Ruled 2026-10-05: **`.guardrails/scripts/`
is a copy, installed and upgraded by `/ratchet` as in any other project, and
it may differ from `scripts/`.**

- **The gate is not the code under change.** Under a symlink, a change that
  breaks `check-trace.sh` also changes the gate that decides whether it may
  merge. A pinned install judges every change with a version that passed the
  suite at a recorded `guardrails_commit`. The 2026-08-22 setup checklist
  noted that the tool under qualification and the tool doing the qualifying
  were the same code here; a pinned install removes that, where the checklist
  could only note it.
- **The installed skills work here unchanged.** They call
  `.guardrails/scripts/…`, which then exists.
- **An upgrade is a change of its own**, by `/ratchet`'s upgrade procedure, and
  re-records `guardrails_version`, `guardrails_commit` and the suite result, as
  in a downstream project.
- **It is not a fork.** AGENTS.md forbids forking script logic into
  `templates/`; an install is a copy taken from `scripts/`, never edited in
  place. Tooth 1 adds a sentence to the repository's own rules saying so:
  `.guardrails/scripts/` changes only by an upgrade change.
- **Cost.** A grammar change merged in `scripts/` is not enforced on this
  repository's own ledgers until the next upgrade. Accepted: the ledgers here
  are maintained against the installed version, as a downstream project's are.
- **Consequence for tooth 0.** The built-in exclusion (`GR_SCAN_EXCLUDE` in
  `scripts/lib.sh`) covers `.guardrails/scripts/` and nothing else, so
  `scripts/`, with the example IDs in its comments, is left for tooth 0's
  exclusion to cover.

## 5. The blocker, re-measured

Measured at `35570e8` on an extracted copy of the tree, with
`templates/config.yaml` changed only in three keys: `safety_class` set to `A`,
the list `verify_commands` given the one item `sh tests/run-tests.sh`, and the
list `strict_paths` given the one item `scripts`; the template READMEs for `docs/requirements/` and `docs/architecture/` added,
`templates/soup.md` copied to `docs/architecture/soup.md` (without it,
`check-trace.sh` exits 2 on `doc_soup`), and `templates/CONTEXT.md` copied to
`docs/CONTEXT.md`.

```
check-ids.sh    exit 1   51 DRAFT-ID, 22 DUPLICATE-ID, 3 MALFORMED-ID
check-trace.sh  exit 1   76 DANGLING-REF, 29 MISPLACED-ITEM, 16 UNRESOLVED-PR,
                         4 MISSING-TEST, 3 UNMITIGATED-HAZARD,
                         3 UNIMPLEMENTED-CONTROL, 2 STALE-PROBLEM,
                         2 ACCEPTED-PR, 1 PROBLEM-BACKLOG
checked: REQ 10, HAZ 3, RC 3, SDD 3, LLR 3, PR 69, ADR 5
```

The first pass measured 52 `check-ids.sh` findings at 212 tests; the count has
grown with the suite.

**Example and fixture text.** Every flagged REQ, HAZ, RC, SDD and LLR is an
example or a test fixture, in both the six-character form (`REQ-a3k9z2`,
`HAZ-h7z4mn`) and the pre-token forms (`REQ-001`, `REQ-0012`); no ledger here
defines one. They occur in `README.md`, `docs/plans/`, `docs/verification/`,
`tests/`, `scripts/` comments, `skills/`, a comment in
`templates/config.yaml`, and the ledger prose of `docs/problems/` named below.
The flagged PR and ADR references are examples of the same kinds (`PR-0012`,
`ADR-0007`, `ADR-k3n8p2`). The `DRAFT-ID` hits are in `tests/`, `docs/plans/`,
`docs/verification/`, `README.md` and `scripts/` comments. None is a defect
in a ledger.

**Real findings, in `docs/problems/`.** 16 open problem reports against
`problem_open_max: 10` (`PROBLEM-BACKLOG`), and two past `problem_age_days: 30`
(`STALE-PROBLEM PR-r8q9m7`, 34 days; `PR-k4t9k2`, 33 days). These fail the
install whatever tooth 0 excludes.

The ledger's own prose also names four example IDs that no ledger defines:
`PR-001` (`docs/problems/2026-09-28-plan-quoted-ids.md`) and `REQ-001`,
`REQ-002`, `REQ-a3k9z2` (`docs/problems/2026-09-17-mutation-evidence.md`). In
this measurement none of the four is a `DANGLING-REF`: each resolves to an
example definition outside the ledgers, and is reported as `MISPLACED-ITEM`
and `DUPLICATE-ID` instead. Each becomes a `DANGLING-REF` once tooth 0
removes those example definitions from the scans. The
convention the ledger READMEs give for illustrative forms, indented or inline
in backticks, keeps a form from reading as a definition but not as a
reference: `PR-001` is already in backticks.

## 6. Adoption order

### Tooth 0: a scan exclusion (a script change)

A way for a project to keep its example and fixture text from being judged
as items. This document states the exit criterion and the design inputs; the
mechanism is tooth 0's to design.

**The `strict_paths` value.** Tooth 0 chooses tooth 1's `strict_paths`: the
smallest path that measures clean under its exclusion. It records that value
in its plan, and tooth 1 installs it unchanged. The exit criterion is measured
against that fixed configuration.

**Exit criterion.** With the tooth 1 configuration of this document, the
`strict_paths` value tooth 0 recorded included, `check-ids.sh` exits 0 on this
tree with the skeleton additions §5 used, in a scratch copy as §5 measured:
the template READMEs in `docs/requirements/` and `docs/architecture/`,
`templates/soup.md` as `docs/architecture/soup.md`, and
`templates/CONTEXT.md` as `docs/CONTEXT.md`. Without them, `check-trace.sh`
exits 2 on `doc_srs`, which only tooth 1 creates. On that copy,
`check-trace.sh` reports no finding whose source is example or fixture
text, the four IDs of design input 3 among them; and every exclusion is
reported. The findings left are the problem-ledger ones tooth 1a owns:
`STALE-PROBLEM` and `PROBLEM-BACKLOG`, which set exit 1
(`scripts/check-trace.sh` lines 1131-1137), and the `UNRESOLVED-PR` and
`ACCEPTED-PR` lines, which are warnings and never set the exit status (lines
78-87; line 1131 sets `fail` on an `F` line only). `check-trace.sh` exits 0
only once tooth 1a is done as well.

**Design inputs.**

1. **Where the example IDs are.** `tests/`, `docs/plans/`,
   `docs/verification/`, `README.md`, `scripts/` comments and `skills/`
   (§5). Re-measure per path before designing.
2. **The reference scope.** In `check-trace.sh`, `GR_SCAN_EXCLUDE` applies
   only to the definition scans: `ids_defined` (`scripts/check-trace.sh`
   line 497) and the definition-site lookup of `classify_unresolved`
   (line 772). `check-ids.sh` applies it to its definition scans, the
   `MALFORMED-ID` scan (`scripts/check-ids.sh` line 187) and the
   `DUPLICATE-ID` scan (line 211), and to its `DRAFT-ID` scan (line 124),
   which bears on design input 4. `DANGLING-REF`
   reads references from the files of five `doc_*` keys, `doc_srs`,
   `doc_rmf`, `doc_sad`, `doc_soup` and `doc_problems`, and from
   `strict_paths` and `test_paths` (lines 760-761, scanned at line 807);
   it does not read `doc_verification`. Excluding a path
   from the definitions while it stays in `test_paths` or `strict_paths`
   turns its fixtures' references into `DANGLING-REF`s. On §5's measured
   tree, with `strict_paths` holding `scripts` and `test_paths` holding
   `tests`, the 76 `DANGLING-REF`s become 88 when `tests/` alone is excluded
   from the definition scans, and 104 when all six paths of input 1 are,
   the four of input 3 among them. The exclusion must cover both scans
   consistently, or the fixtures must be told apart from real references some
   other way. Tooth 2 needs the `verifies:` lines in `tests/` to be read, so
   `tests/` cannot simply leave `test_paths`.
3. **Example IDs quoted in ledger prose.** The three passages that name the
   four IDs of §5: two lines of `docs/problems/2026-09-17-mutation-evidence.md`
   and one of `docs/problems/2026-09-28-plan-quoted-ids.md`. A ledger
   cannot be excluded from the scans, so either the reference scan skips a
   quoting form or the passages are reworded to describe the example rather
   than name it.
4. **Narrowing `DRAFT-ID` to the configured ledgers**, which the first pass
   proposed, as an alternative to listing paths for that check.

**Constraints**, from the first pass: extend `GR_SCAN_EXCLUDE`, never replace
it; any new key is a closed-schema key added to `GR_KNOWN_KEYS`; each
exclusion is reported on the `sources:` line; an entry matching nothing is an
error; a bats test for each behavior. Any project that keeps example
documents meets this wall, so the change is the toolkit's, not a concession to
this repository.

### Tooth 1a: the problem backlog

Bring `docs/problems/` within the limits under `resolve-problem`: resolve or
rule on open items until at most 10 are open and none is older than 30 days,
or raise a limit deliberately with the reason recorded. The four example IDs
in the ledger's prose (§5) are tooth 0's design input 3. Independent of
tooth 0 otherwise; either may go first. Tooth 1's "both check scripts exit
0" needs both done.

### Tooth 1: install the machinery

Starts when tooth 0's exit criterion holds and tooth 1a is done.

- `.guardrails/scripts/` copied from `scripts/` at a recorded commit (§4);
  `.guardrails/templates/verification.md`.
- `.guardrails/config.yaml`: `safety_class` set to `A`; the list
  `verify_commands` with the one item `sh tests/run-tests.sh`;
  `guardrails_version` and `guardrails_commit`; the list `strict_paths` holding
  the value tooth 0 chose and recorded; the list `test_paths` with the one item
  `tests`; and `id_prefixes` with `ADR` declared once its fixtures are
  excluded. The two fixed lists, in the list form the closed schema requires:

      verify_commands:
        - sh tests/run-tests.sh
      test_paths:
        - tests

- The managed block appended to `AGENTS.md` (§3), and the sentence of §4.
- `docs/requirements/`, `docs/architecture/` with `soup.md`, the
  `docs/risk/` README, `docs/CONTEXT.md`, and `CLAUDE.md` from the template.
- Both check scripts exit 0 on the result, which needs tooth 0 and tooth 1a
  both done, and `check-signing.sh --setup`
  exits 0 in the user's terminal.
- From then on, records cite the installed gates, not a synthesized config, and
  state the class as A.

### Tooth 2: the toolkit's requirements as items

Move the prose requirements in `README.md`, the skills and the script headers
into REQ items in `docs/requirements/`, and annotate the bats suite with
`verifies:`. The largest tooth, and the one that makes `checked:` mean
something. Area by area, extending `strict_paths` as each area is traced.

### Tooth 3: CI and branch protection

Before it, the user restores verification of the SSH-signed history: an
`allowed_signers` file listing the retired SSH keys, bounded by
`valid-before`, and `gpg.ssh.allowedSignersFile` pointing at it. Without it,
`check-signing.sh --strict` over the full history fails on 22 commits that
carry an SSH signature (`git cat-file commit` shows `BEGIN SSH SIGNATURE`).
Even with the allowed signers restored, a full-history
`check-signing.sh --strict` still fails on the unsigned root commit `3f1f457`
(`UNSIGNED`), so the pipeline checks a range from the install onward,
`main..HEAD` per change, as the setup checklist states.

The user's: a pipeline running the suite, `check-ids.sh`, `check-trace.sh` and
`check-signing.sh --strict main..HEAD`, and protection of `main`. Pushing and the forge
are outside an agent's scope here (non-negotiable 5).

## 7. Decisions recorded this session

- **Retrofit this repository as its own target**, ruled 2026-10-05.
- **Separate, pinned `.guardrails/scripts/`** (§4), ruled 2026-10-05.
- **Gap analysis first, tooth 0 next**, as in the first pass; installing red and
  burning findings down was offered and declined.
- **Safety class A** stands (`ADR-q54hjw`); no new interview.
- **This change opens `PR-ww36qr`**: `ratchet` step 5 captures the suite's
  exit status in a variable named `status`, which is read-only in zsh, so the
  status is lost. The item is recorded in `docs/problems/` and the skill is
  not changed here.
