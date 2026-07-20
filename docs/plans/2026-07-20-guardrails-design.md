# Guardrails — Design

**Date:** 2026-07-20
**Status:** Validated with project owner (brainstorming session)

## Purpose

A self-contained, distributable suite of agent skills for managing and developing
software projects under **IEC 62304** (software lifecycle) and **ISO 14971**
(risk management). Adapted from the process discipline of
[obra/superpowers](https://github.com/obra/superpowers) and the interview/documentation
style of [mattpocock/skills](https://github.com/mattpocock/skills)
(`grill-with-docs`, `grilling`, `domain-modeling`).

Non-negotiable rules the suite enforces in every target project:

1. **All work happens in git worktrees** — documentation authoring and code alike.
   Never on the current branch, never directly on main.
2. **Integration is a signed squash merge** — main's history is
   one-signed-commit-per-change, each an auditable change record.
3. **Traceability is checked mechanically before every merge.**

## Decisions (from the brainstorm)

| Decision | Choice |
|---|---|
| Deliverable form | Distributable skills repo (like superpowers): `skills/`, README, install instructions |
| Safety class handling | Class-aware: `/ratchet` records class (A/B/C) in `.guardrails/config.yaml`; skills scale rigor; per-item overrides allowed |
| Scope (v1) | Core dev loop + docs. Deferred: problem resolution/CAPA, release, maintenance, post-market |
| Traceability | Stable IDs in markdown (`REQ-`, `HAZ-`, `RC-`, `SDD-`) + grep-based checker scripts |
| Enforcement | Skills + repo check scripts gating the merge (CI-ready). No git hooks in v1 |
| Agent compatibility | AGENTS.md-first (canonical rules file), CLAUDE.md is a pointer; standard SKILL.md format |
| ID collision strategy | Draft IDs in worktrees (`REQ-DRAFT-<branch>-<n>`), finalized to sequential IDs at merge time with mechanical reference rewrite |
| Dependency on superpowers | None — self-contained; needed patterns are adapted in |
| `/ratchet` on existing projects | Retrofit mode: gap analysis first, incremental adoption, never overwrites |

## The skill suite

Ten skills, each a standard `SKILL.md`:

### Bootstrap

1. **`ratchet`** — bootstrap or retrofit a target project.
   - **Greenfield:** init git if needed; write `AGENTS.md`, `CLAUDE.md` pointer,
     `.guardrails/config.yaml`, doc skeletons, check scripts; run the safety-class
     interview; commit the scaffold via worktree + signed squash merge (practices
     what it preaches).
   - **Retrofit (auto-detected):** inventory what exists (AGENTS.md content, docs,
     test conventions, CI, signing status, any existing requirement/risk docs);
     write `docs/plans/<date>-ratchet-gap-analysis.md`; propose adoption order —
     config + scripts + AGENTS.md rules first, then migrate existing docs into
     ID'd form as separate worktree changes. Existing untraced code is
     grandfathered: checks apply only to `strict_paths` in config, which grows
     over time (the ratchet clicks one tooth at a time).
   - **AGENTS.md managed block:** guardrails rules live in a clearly delimited
     block so re-running `/ratchet` updates its own block without touching
     human-authored content.
   - **Human checklist** (printed and saved to `docs/plans/<date>-ratchet-setup.md`):
     signing key setup (`git config commit.gpgsign true`, SSH or GPG), branch
     protection (require signed commits, no direct pushes), wire check scripts
     into CI, reviewer/approval policy. Flagged clearly: *guardrails supports your
     QMS but is not itself regulatory compliance; the quality manual and human
     sign-offs govern.*

### Documentation & planning (all inside a worktree)

2. **`grill-requirements`** — relentless one-question-at-a-time interview
   (adapted from `grilling` + `domain-modeling`) producing/refining the software
   requirements spec (`REQ-` items). Maintains the `docs/CONTEXT.md` glossary as
   terms crystallize; offers ADRs sparingly (hard to reverse + surprising + real
   trade-off).
3. **`analyze-risks`** — ISO 14971 interview: hazards (`HAZ-`), hazardous
   situations, harm severity/probability, risk evaluation against the
   acceptability matrix, risk controls (`RC-`) which become requirements.
   Writes/updates the risk management file.
4. **`design-architecture`** — IEC 62304 architecture doc (`SDD-` items), SOUP
   inventory (name, version, role, risks), ADRs for real trade-offs. Class C
   requires detailed design per item; Class A skips it.
5. **`plan-change`** — implementation plan with trace IDs on every task and test
   deliverables baked in (adapted from superpowers writing-plans).

### Development

6. **`worktree-discipline`** — mandatory isolation for any change; how to create,
   name, and clean up worktrees; draft-ID minting rules.
7. **`develop-change`** — TDD loop; every test declares which `REQ-`/`RC-` it
   verifies (`// verifies: REQ-001, RC-003`).
8. **`check-traceability`** — run the checker, interpret the orphan/gap report.
9. **`verify-before-merge`** — evidence-before-claims completion gate (adapted
   from verification-before-completion).
10. **`merge-change`** — the compliance chokepoint (sequence below).

## Target project layout (after `/ratchet`)

```
project/
├── AGENTS.md                     # canonical rules (managed block)
├── CLAUDE.md                     # pointer to AGENTS.md
├── .guardrails/
│   ├── config.yaml               # safety_class, doc paths, ID prefixes,
│   │                             # strict_paths, verify_commands, scripts version
│   └── scripts/
│       ├── check-trace.sh        # orphan/gap report across docs, code, tests
│       ├── check-ids.sh          # draft-ID and duplicate detection
│       ├── check-signing.sh      # verify commit signatures on a range
│       └── finalize-ids.sh       # mint sequential IDs, rewrite references
├── docs/
│   ├── CONTEXT.md                # glossary (ubiquitous language)
│   ├── requirements/srs.md       # REQ- items
│   ├── risk/rmf.md               # HAZ-, RC- items + acceptability matrix
│   ├── architecture/sad.md       # SDD- items
│   ├── architecture/soup.md      # SOUP inventory
│   ├── adr/                      # numbered ADRs
│   └── plans/                    # implementation plans, gap analyses
```

### Config (`.guardrails/config.yaml`)

- `safety_class: A | B | C` — skills read it and scale required documents and
  activities (e.g. Class A: no detailed design or unit verification docs;
  Class C: both required). Per-item overrides supported (IEC 62304 allows
  classifying software items separately).
- `verify_commands:` — list of commands `merge-change` and `verify-before-merge`
  run (tests, type checks, linters).
- `strict_paths:` — paths where traceability is enforced (retrofit ramp-up).
- `scripts_version:` — stamped by `/ratchet` so re-running it can update scripts.

### Traceability model

- Items are markdown headings: `**REQ-001**: <text>`.
- Tests reference IDs: `// verifies: REQ-001, RC-003` (comment or test name).
- Commits and plans reference IDs in prose.
- `check-trace.sh` enforces: every REQ has ≥1 verifying test; every HAZ has ≥1 RC;
  every RC traces to a REQ; every SDD traces to ≥1 REQ; no draft IDs on main.
- **Draft IDs:** in a worktree, new items are `REQ-DRAFT-<branch>-<n>`. Final
  sequential IDs are minted only at merge time from main's high-water mark —
  collision-free by construction across parallel worktrees.

## The merge sequence (`merge-change`)

All steps before the squash happen **in the worktree**; main only ever receives
one verified, signed commit.

1. **Merge latest main into the worktree branch** (`git merge main`). Conflicts
   are resolved in the worktree, never on main.
2. **Run the full verification suite** (`verify_commands`). Any failure halts the
   merge; errors are resolved in the worktree (systematic debugging), then this
   step reruns from the top until green.
3. `finalize-ids.sh` — scan for `*-DRAFT-*` IDs, read main's highest finalized ID
   per prefix, mint next sequential numbers, rewrite every reference (docs,
   tests, code, plans) in one commit. Idempotent, dry-runnable.
4. `check-ids.sh` — zero remaining draft IDs, zero duplicates against main.
5. `check-trace.sh` — traceability gates pass (scoped by `strict_paths`).
6. **Re-run the verification suite** — guards the ID rewrite.
7. **Signed squash merge:** `git merge --squash <branch>` on main, then
   `git commit -S` with a structured message: summary line, trace IDs touched,
   plan reference, `Verified: <checks run>`.
8. `check-signing.sh` confirms the new commit is signed; only then clean up the
   branch and worktree. If signing fails (no key configured), the merge stops
   and points to the ratchet setup checklist — never an unsigned fallback.

## The guardrails repo itself

```
guardrails/
├── README.md            # what it is, install, workflow diagram
├── AGENTS.md            # rules for developing guardrails itself
├── install.sh           # symlink skills into ~/.claude/skills
├── skills/<name>/SKILL.md   # the 10 skills; templates/scripts live beside
│                            # the skill that owns them
├── templates/           # AGENTS.md block, config.yaml, doc skeletons
├── scripts/             # the four check/finalize scripts (source of truth;
│                        # /ratchet copies them into target projects)
└── tests/               # bats tests for the scripts against fixture repos
```

- **Scripts are plain POSIX shell + grep/awk** — no runtime dependencies; run
  identically in target projects and CI.
- **Scripts get real tests** (bats + fixture repos seeded with gaps, draft IDs,
  duplicate IDs, unsigned commits) — they are the mechanical backbone.
- **Skills are verified** with the writing-skills discipline.
- **Install:** `git clone` + `install.sh` (symlinks into `~/.claude/skills`).
- Guardrails is developed under its own rules: worktrees + signed squash merges.

## Out of scope (v1)

- Problem resolution / CAPA workflow, release and maintenance skills,
  post-market surveillance hooks.
- Git hooks enforcement (scripts + CI only).
- Per-harness adapter files beyond AGENTS.md/CLAUDE.md.
