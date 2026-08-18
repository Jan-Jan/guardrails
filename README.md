# guardrails

Agent skills for managing and developing software projects under
**IEC 62304** (medical device software lifecycle) and **ISO 14971**
(risk management), with mechanically checked traceability, mandatory git
worktrees, and signed squash merges. Borrows DO-178C's strongest mechanics:
high/low-level requirements, derived-requirements feedback into risk
analysis, problem reports, structural-coverage targets, independent review,
and verification records.

> Guardrails supports your quality management system; it is **not** itself
> regulatory compliance. Your quality manual, design controls, and human
> sign-offs govern.

## Install

Via the [skills CLI](https://skills.sh) (Claude Code, Cursor, Codex, and
other agents):

```sh
npx skills add Jan-Jan/guardrails
```

Or manually:

```sh
git clone git@github.com:Jan-Jan/guardrails.git
cd guardrails
./install.sh          # symlinks skills into ~/.claude/skills
                      # (CLAUDE_SKILLS_DIR overrides; --copy for a static copy)
```

Then, in the project you want to bring under guardrails, run the **ratchet**
skill (`/ratchet`). It bootstraps a new project — or audits an existing one
and tightens incrementally — installing `AGENTS.md` rules, `.guardrails/`
config and check scripts, and the document skeletons, and finishing with a
checklist of things only a human can set up (signing keys, branch
protection, CI).

## The workflow

```mermaid
flowchart TD
    R[ratchet<br/>bootstrap / retrofit] --> G[grill-requirements<br/>REQ items + glossary]
    G <--> A[analyze-risks<br/>HAZ / RC items]
    G --> D[design-architecture<br/>SDD items + SOUP]
    A --> D
    D --> P[plan-change]
    P --> W[worktree-discipline<br/>isolate + draft IDs]
    W --> DEV[develop-change<br/>TDD, verifies: annotations]
    B[resolve-problem<br/>PR items for every bug] --> DEV
    DEV --> CT[check-traceability]
    CT --> V[verify-before-merge<br/>evidence + coverage gate]
    V --> M[merge-change<br/>finalize IDs, independent review,<br/>verification record, signed squash merge,<br/>cleanup worktree]
```

Three rules carry the whole system:

1. **All work happens in worktrees** — documentation and code alike. The
   base branch (whatever the primary checkout has checked out — the scripts
   detect it, nothing assumes `main`) never moves except by merge.
2. **Integration is a signed squash merge** — the base branch is one signed,
   verified, auditable commit per change.
3. **Traceability is mechanical** — grep-able IDs link requirements, risks,
   design, and tests; scripts gate every merge.

## ID and trace grammar

| Item | Defined in | Grammar |
|---|---|---|
| Requirement | `docs/requirements/srs.md` | `**REQ-NNN**: The software shall … (implements: RC-NNN)` |
| Hazard | `docs/risk/rmf.md` | `**HAZ-NNN**: hazard, situation, harm. Severity: S_. Probability: P_.` |
| Risk control | `docs/risk/rmf.md` | `**RC-NNN**: control. mitigates: HAZ-NNN` |
| Design item | `docs/architecture/sad.md` | `**SDD-NNN**: item. traces: REQ-NNN` |
| Low-level req | `docs/architecture/sad.md` | `**LLR-NNN**: behavior. satisfies: REQ-NNN` (or `satisfies: derived` — must then be assessed in the RMF) |
| Problem report | `docs/problems/log.md` | `**PR-NNN**: symptom. affects: <IDs>. status: open\|resolved` |
| Test link | test files | comment/name containing `verifies: <IDs>` — lowest level present; REQs covered transitively via tested LLRs |

New items minted inside a worktree use **draft IDs**
(`<PREFIX>-DRAFT-<branch>-<n>`); `finalize-ids.sh` assigns the next
sequential numbers at merge time and rewrites every reference — parallel
worktrees can never collide on an ID.

**Document ledgers:** each doc area is a directory of per-change files, not
a monolith — so parallel worktrees never conflict on documents either. In a
worktree, new items go into `docs/<area>/DRAFT-<branch>-<slug>.md`;
`merge-change` renames it to `YYYY-MM-DD-<slug>.md` (the merge date, so
`ls` reads chronologically; same-day collisions get `-2`). Existing items
are always edited in the dated file that defines them. Each directory's
README carries the grammar; `soup.md` stays a single inventory file, and
every `doc_*` config key also accepts a single file (legacy monoliths keep
working).

## Check scripts

Source of truth in `scripts/`; `/ratchet` copies them into target projects
at `.guardrails/scripts/`. POSIX sh + git/grep/awk/sed only.

| Script | Purpose |
|---|---|
| `check-ids.sh [--allow-drafts] [--base REF]` | no leftover draft IDs or draft-named files, no duplicate IDs. Prints `SKIPPED-DUPLICATE-BASE` and leaves the duplicate-vs-base gate unrun when there is no usable base branch (a detached HEAD, or one with no commits yet); a `--base` you name yourself must resolve |
| `check-trace.sh` | every REQ/LLR tested (transitive REQ coverage), HAZ mitigated, RC implemented, SDD traced, LLR satisfied-or-derived, derived items assessed in RMF; no dangling refs; open PRs listed as warnings. Ends with `checked:` (items found) and `sources:` (document files read, then the number of configured path entries) |
| `check-signing.sh [--strict] [RANGE]` | commit signatures verified |
| `finalize-ids.sh [--dry-run] [--base REF]` | mint final IDs, rewrite references, rename draft ledger files to merge date; exits 1 without touching anything if a draft ID could never be minted — no bold item header, or a prefix missing from `id_prefixes` (`--dry-run` reports this too) |

Annotations are read as lists: only the IDs immediately following the first
occurrence of `verifies:`/`mitigates:`/`implements:`/`satisfies:`/`traces:`
count, so `verifies: REQ-001 (was REQ-042)` credits REQ-001 alone. The rule
has one definition, shared by every keyword.

**A configured entry that matches nothing is an error, not an empty result.**
Exit 2 — never a quiet exit 0 — for a `doc_*`, `strict_paths` or `test_paths`
entry matching no file present in the working tree, a ledger directory holding
no `*.md`, or an `id_prefixes` entry that is not a bare identifier.
`strict_paths` and `test_paths` entries are **git pathspecs** — a plain path,
or a pattern like `*_test.sh` that git matches recursively — and an empty
directory matches no file. `doc_*` values are plain paths only: a file, or a
directory whose `*.md` files sit directly in it.

Every one of those would otherwise turn a whole gate family into a no-op that
still reports success.

**What this does not yet cover.** Two gaps are known, reproduced, and left to
follow-up changes rather than hidden:

1. **A missing or misspelled config KEY** still reads as "this project does
   not use that". It is not only about documents: `doc_rmff:` disables every
   hazard gate, `test_path:` disables `MISSING-TEST` entirely, and
   `strict_path:` drops half of `DANGLING-REF` — each exiting 0. A config with
   no `doc_*` keys and no path lists at all runs every gate off and still
   exits 0. The `sources:` line is the tell: zeros there mean nothing was
   read. `finalize-ids.sh` has the same blind spot — a misspelled `doc_*` key
   leaves that ledger's `DRAFT-` file un-renamed and exits 0, though
   `check-ids.sh` catches it at the next merge step.
2. **`checked:` counts items found, not items examined.** An item defined
   outside its configured document — `**SDD-001**:` in `docs/design.md` — is
   counted here and read by no gate.

Both are recorded, with reproductions, in
`docs/plans/2026-08-12-false-green-fixes.md`.

Safety-class awareness (IEC 62304 A/B/C) lives in `.guardrails/config.yaml`;
skills scale required documentation and verification to the class.

## Development

```sh
tests/run-tests.sh    # bats suite for the scripts (vendors bats-core if needed)
```

Guardrails is developed under its own rules — see `AGENTS.md`.

## Credits

Process discipline adapted from [obra/superpowers](https://github.com/obra/superpowers)
(worktrees, TDD, verification-before-completion, plan writing) and interview
style from [mattpocock/skills](https://github.com/mattpocock/skills)
(`grilling`, `domain-modeling`, `grill-with-docs`) — both MIT licensed.

## License

MIT © Dr. Jan-Jan van der Vyver — see [LICENSE](LICENSE).
