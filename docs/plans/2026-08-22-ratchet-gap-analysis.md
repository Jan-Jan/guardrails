# Ratchet gap analysis — guardrails self-hosting

Date: 2026-08-22
Mode: **retrofit** (12 commits, populated `docs/`, no `.guardrails/`)
Guardrails version to install: **0.2.0** (`templates/config.yaml`)

Guardrails is the reference implementation of its own process, and `AGENTS.md`
already asserts that it is "developed under its own rules". This analysis
measures how far that claim currently extends: the *practices* are followed by
hand, but the *machinery* has never been installed on this repo. Installing it
turns out to be blocked, and the blocker is a real property of the toolkit
rather than an accident of this repo's layout.

## 1. What exists

| Area | State |
|---|---|
| `AGENTS.md` | Present, hand-written, already guardrails-shaped. No managed block markers. |
| `CLAUDE.md` | Absent. |
| Worktree discipline | Followed by hand. `.gitignore` excludes `.claude/worktrees/` but **not** `.worktrees/`. |
| Signing | 11 of 12 commits signed and verified (`%G? = G`); only the initial `chore: repo skeleton` is unsigned. Hardware key (`id_ecdsa_sk`, FIDO2). `gpg.ssh.allowedSignersFile` **is** configured and maintained — it carries both the current key and the retired pre-rotation key bounded by `valid-before`, so historic signatures stay verifiable. |
| Tests | `tests/*.bats`, driven by `tests/run-tests.sh` (vendors bats-core 1.11.0 if absent). Baseline this session: **212/212 pass, 0 failures**. |
| `docs/plans/` | 12 design and implementation plans, `YYYY-MM-DD-<topic>.md`. |
| `docs/verification/` | 10 verification records plus a mutation-testing directory. |
| CI | **None.** No `.github/`, no pipeline of any kind. |
| Check scripts | `scripts/` — `check-ids.sh`, `check-trace.sh`, `check-signing.sh`, `finalize-docs.sh`, `lib.sh`, `new-id.sh`. Source of truth per `AGENTS.md`. |

## 2. What is missing

- `.guardrails/config.yaml` and `.guardrails/scripts/` — the machinery itself.
- All four ledger directories: `docs/requirements/`, `docs/risk/`,
  `docs/architecture/` (+ `soup.md`), `docs/problems/`.
- `docs/adr/` — created by this change for the safety-class ADR.
- `docs/CONTEXT.md`.
- `.gitignore` entry for `.worktrees/`.
- Any REQ/HAZ/RC/SDD/LLR item for guardrails' own behaviour. Every requirement
  this toolkit satisfies is currently expressed only as prose in `README.md`,
  the skills, and script header comments, plus the bats suite as executable
  specification.

## 3. Conflicts

Fewer than a typical retrofit — `AGENTS.md` was written against these rules.

1. **Overlapping non-negotiables.** Appending the managed block gives the file
   two "Non-negotiables" sections saying compatible things. The existing one
   also carries repo-specific rules the block does not (POSIX sh only, a bats
   test per behaviour change, no forking script logic into `templates/`).
   Resolution: keep both, append the block below the existing content, and add
   a line noting that the repo-specific rules govern where they are narrower.
2. **`main` hardcoded.** `AGENTS.md` says "never commit directly to `main`";
   the managed block says "the base branch", which the scripts detect. Harmless
   today, wrong if the default branch is ever renamed. Reword when merging.
3. **`verify_commands`.** The template ships `make test`; this repo's command is
   `./tests/run-tests.sh`. Must be set at install, not left at the default.
4. **`.guardrails/scripts/` would duplicate `scripts/`.** `AGENTS.md` forbids
   forking script logic, and a copy inside the repo is exactly that — it will
   drift from the source of truth silently. This is a self-hosting problem no
   other project has. Options, to be decided at install time: a symlink
   `.guardrails/scripts -> ../scripts`; or a copy plus a CI check asserting the
   two are byte-identical. Note that `GR_SCAN_EXCLUDE` excludes the path
   `.guardrails/scripts`, so under a symlink the real `scripts/` is scanned
   under its own path — which is acceptable, because `scripts/` contains no
   definition forms at all (§4).

## 4. The blocker: this repo's own text trips its tree-wide gates

**Four** gates do **not** respect `strict_paths`. They scan the whole tree,
excluding only `.guardrails/scripts`:

```
git grep ... -- . ':(exclude).guardrails/scripts'
```

So the skill's standard retrofit escape hatch — "set `strict_paths` to a small
list, grandfather the rest" — has no effect on them.

### Measured, not estimated

Running the real scripts against this tree with a synthesised template config
(`safety_class: A`, everything else at template defaults):

```
$ GR_CONFIG=<tmp>/config.yaml ./scripts/check-ids.sh   ; echo $?
     43 DRAFT-ID
      7 DUPLICATE-ID
      2 MALFORMED-ID
1

$ GR_CONFIG=<tmp>/config.yaml ./scripts/check-trace.sh ; echo $?
guardrails: doc_srs is configured as 'docs/requirements', which does not exist
2
```

`check-trace.sh` cannot reach its gates at all until the ledger directories
exist, so its exit 2 is the *config* error, not a clean bill of health. The 52
`check-ids.sh` violations are the measured floor.

| Gate | Count | Location |
|---|---|---|
| `DRAFT-ID` | 43 | `tests/check-ids.bats` (15), `docs/plans/` (19), `docs/verification/` (5), `scripts/lib.sh` (2), `README.md` (1), `tests/check-trace.bats` (1) |
| `DUPLICATE-ID` | 7 | `REQ-001`, `REQ-002`, `HAZ-002`, `SDD-001`, `SDD-002`, `LLR-001`, `LLR-002` — fixture IDs reused across bats files |
| `MALFORMED-ID` | 2 | `docs/plans/2026-08-20-scan-pathspec.md:29`, `tests/check-ids.bats:282` |
| `MISPLACED-ITEM` | 31 | 31 definition forms tree-wide; none sits in a configured ledger. Not yet reachable — `check-trace.sh` exits 2 first. |

Not one of these is a real item. They are fixtures, historical plans, and
prose describing the toolkit's own past behaviour.

**`DRAFT-ID` is the finding that reshapes tooth 0.** It was invisible to a
pattern-only estimate and only appeared when the script was actually run. The
old draft scheme is discussed throughout this repo's written history, and every
mention is now a hard failure under every flag. Critically, **only 16 of the 43
are in `tests/`** — the rest are in `docs/plans/`, `docs/verification/`,
`README.md` and a comment in `scripts/lib.sh`. An exclusion covering the test
fixtures alone would therefore leave 27 failures standing.

**Why indenting is not the fix.** For the bats fixtures, column-one anchoring is
precisely what those tests assert: `check-ids.bats` and `check-trace.bats` exist
to prove a definition form at column one is detected and one in prose is not.
Indenting the fixture deletes the test, and `git grep` cannot tell a heredoc
from a document. For the historical plans, the text is an accurate record of
what the toolkit once did; rewriting it to appease a scan falsifies the record.

Distinct ID *references* per directory, which is what `DANGLING-REF` harvests
once a path enters `strict_paths` or `test_paths` — note it collects **every**
ID-shaped token in scope, not only ones following an annotation keyword:

| Path | Distinct refs | Assessment |
|---|---|---|
| `templates/` | 0 | Clean. Safe for `strict_paths` today. |
| `skills/` | 5 | Illustrative IDs in skill prose. |
| `scripts/` | 6 | Illustrative IDs in comments (`REQ-001`, `SDD-001`, …). |
| `README.md` | 12 | Documentation examples. |
| `docs/verification/` | 20 | Worked examples in records. |
| `docs/plans/` | 32 | Worked examples in plans. |
| `tests/` | 34 | Fixtures. Blocks `test_paths: tests` outright. |

`tests/` is the sharpest instance: it is the natural value for `test_paths`,
and pointing `test_paths` at it turns 34 fixture tokens into dangling
references.

**Conclusion.** Installing the machinery as the skill prescribes leaves
`check-ids.sh` at exit 1 with 52 violations and `check-trace.sh` at exit 2, violating the skill's own
exit condition that the check scripts must pass on the result. The toolkit
needs a way to exclude fixture-bearing paths from its tree-wide scans before it
can be installed on itself.

## 5. Adoption order

### Tooth 0 — scan exclusion (prerequisite, upstream)

Add a mechanism letting a project exclude paths from the tree-wide scans, most
plausibly a `scan_exclude` config list that extends `GR_SCAN_EXCLUDE` rather
than replacing it. Design constraints, all of which the existing code already
argues for in comments:

- `GR_SCAN_EXCLUDE` is deliberately not overridable from the environment,
  because a widened value silently blinds every scan while still exiting 0.
  A config key must preserve that property: extend, never replace, and validate
  each entry.
- The key joins a **closed** schema, so it must be added to `GR_KNOWN_KEYS` in
  the same change or every existing config becomes invalid.
- An exclusion is a hole in the safety net. It should be reported — the
  `sources:` summary line is the existing place for it — so that a project
  cannot quietly exclude its way to a false green. This is the same reasoning
  that produced `checked:` and `MISPLACED-ITEM`.
- The exclusion must cover `docs/plans/`, `docs/verification/`, `README.md` and
  `scripts/` — not just `tests/`. Two thirds of the `DRAFT-ID` failures are
  outside the test tree (§4), so a fixtures-only exclusion does not unblock
  tooth 1.
- Consider whether `DRAFT-ID` should scan the whole tree at all now that the
  draft scheme is abolished. Its tree-wide reach was justified when a draft
  token could appear anywhere and had to be finalized; today the token is
  simply dead, and the gate's remaining job is to stop a *live* item carrying
  one — which only the configured ledgers can hold. Narrowing it may be a
  truer fix than excluding six paths from it.
- Needs bats tests per `AGENTS.md`: at minimum that an excluded path is skipped
  by all four tree-wide gates, that exclusion is additive to the built-in one,
  and that an entry matching nothing is an error rather than a silent no-op.

This is guardrails' own business as a toolkit, not a concession made to install
it here: any project vendoring fixture documents hits the same wall.

### Tooth 1 — install the machinery

Only after tooth 0. Install `.guardrails/` (resolving §3.4), set
`safety_class: A` and `verify_commands: ./tests/run-tests.sh`, append the
managed block to `AGENTS.md`, create the four ledger directories with their
README grammars, add `docs/CONTEXT.md`, add `.worktrees/` to `.gitignore`, and
set `strict_paths` to `templates` alone — the only path measured clean.
`test_paths` awaits tooth 0's exclusion covering the bats fixtures.

### Tooth 2 — clear the residue tooth 0 does not cover

Whatever tooth 0 excludes, some residue is a genuine defect rather than
protected text:

- The two `MALFORMED-ID` hits are legacy draft tokens from the pre-token
  scheme. `tests/check-ids.bats:282` is a fixture asserting such a token now
  fails and must stay; `docs/plans/2026-08-20-scan-pathspec.md:29` is a
  historical record and is covered by excluding `docs/plans/`.
- The 7 `DUPLICATE-ID` collisions are fixture IDs reused across bats files.
  If tooth 0 excludes `tests/`, they vanish; if tooth 0 instead narrows the
  gates to configured scope, they vanish too. Either way, do not renumber
  fixtures to dodge a gate — that is the false-green reflex this project
  exists to remove.

### Tooth 3 — express guardrails' own requirements as items

Migrate the prose requirements in `README.md` and the skill files into REQ
items in `docs/requirements/`, with the bats suite annotated `verifies:`. This
is the largest tooth by far and the one that makes `checked:` meaningful. It
depends on tooth 0, because annotating `tests/*.bats` is impossible while every
token in that tree is scanned as a reference.

### Tooth 4 — CI and signing enforcement

Add a pipeline running `./tests/run-tests.sh`, `check-ids.sh`, `check-trace.sh`
and `check-signing.sh --strict`. Create an `allowed_signers` file so
`check-signing.sh` verifies rather than warning, and enable branch protection.
Independent of teeth 0–3 and can proceed in parallel.

## 6. Decisions recorded this session

- **Safety class A** — see `docs/adr/2026-08-22-safety-class.md`.
- **Fix upstream before installing** — tooth 0 precedes tooth 1, rather than
  installing red and burning violations down, or narrowing `id_prefixes` to
  dodge the fixtures.
