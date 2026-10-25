---
name: ratchet
description: Bootstrap or retrofit a project for IEC 62304 / ISO 14971 development under guardrails. Use when setting up a new regulated project, adopting guardrails in an existing codebase, updating guardrails scripts/config, or when the user runs /ratchet.
---

# Ratchet — bootstrap or tighten a project

**Announce at start:** "Using the ratchet skill to set up guardrails in this project."

## Preconditions

- The user invoked `/ratchet`, or asked to set up, retrofit or update guardrails in
  a project. The current directory is that project.
- In an existing project, tighten enforcement one step at a time. Never
  loosen a gate and never overwrite human work.

## Steps

### Step 0: Locate the guardrails source

The checkout is the directory `.guardrails-source` names beside this
SKILL.md (`install.sh --copy`), else the repository two levels above it, and
has `templates/` and `scripts/`. Before reading it, run
`git clone -q <checkout> <guardrails>` to `<tmp>/guardrails`, `<tmp>` being
a temporary directory outside the project. Every copy and the suite read the
clone, removed when the ratchet is done (`references/rationale.md`).

### Step 1: Detect mode

**Greenfield** = no commits beyond scaffolding AND no source files AND no
existing AGENTS.md/docs. Anything else is a **retrofit**. A project that has
`.guardrails/scripts/` and wants newer ones is an **upgrade**: its own
procedure below, with no gap analysis (`references/rationale.md`).

```sh
git rev-list --count HEAD 2>/dev/null   # none or few → likely greenfield
ls src lib app AGENTS.md docs 2>/dev/null
```

Unless the repository is obviously one program, ask (one question,
recommend an answer): **one system in many packages, or many systems in one
repository?** Packages that version, release and take risk together are one
system: a single-unit project gets no manifest, and the rest of this skill
applies unchanged. Separately compliant systems get the units interview
(step 1b) before any file is copied.

### Step 1b: The units interview (multi-unit repositories only)

`/ratchet` declares the facts; the rules are not configurable. Ask one
question at a time, recommend an answer, and write each fact where the table
directs:

| Ask | Write to |
|---|---|
| What are the units? (each a relative directory) | `units:` in `.guardrails/units.yaml` |
| What is outside compliance, and why? | `not_a_unit:` in the manifest; the why as a `#` comment beside the entry |
| What is each unit's safety class? | `safety_class:` in that unit's config — the step 4 interview, repeated per unit |
| What does each unit depend on? | `depends_on:` in the consumer unit's config — each edge triggers the dependency assessment (`grill-requirements`, "Declaring a dependency") |
| Is any dependency segregated, and under which control? | `segregated_from:` in the consumer's config, cited as `(RC-…)`, `(adr: <path>)` or `(ADR-<token>)` (file in root or consumer `docs/adr/`); `check-units.sh`: uncited is INCOMPLETE-SEGREGATION |

Do **not** ask whether the class floor applies, whether a unit may see
another's internals, or which units run at merge.

Adopt in order, one step at a time. The mandatory first step is the
manifest, the per-unit configs and the disclaimers; a unit with an
empty `depends_on:` is a freestanding guardrails project that shares a
repository. A manifest naming one unit, with everything else disclaimed, is a
valid, passing first step. Declare edges (`depends_on:`, exports,
expectations) when the coupling is real.

Then run `.guardrails/scripts/check-units.sh`. Its findings (UNCLAIMED-PATH
above all) are the worklist for the disclaimers question.

### Step 2 (greenfield): Scaffold

1. `git init` if not a repo (any default branch name works); make an initial
   commit if there is none (a worktree needs a base).
2. Create a worktree for the scaffold (`worktree-discipline`).
3. Copy in, from `<guardrails>`:
   - single unit: `templates/config.yaml` → `.guardrails/config.yaml`
   - multi-unit: `templates/units.yaml` → `.guardrails/units.yaml`, filled in
     from the interview, and `templates/config.yaml` →
     `<unit>/.guardrails/config.yaml` for **each** unit, with its `doc_*`
     paths and `verify_commands` adjusted. There is
     **no root .guardrails/config.yaml** in a manifest repository: two
     authorities over one tree is exit 2 at every gate.
     `references/multi-unit.md` states which files go per unit.
   - `scripts/*.sh` → `.guardrails/scripts/` (keep executable bits)
   - `templates/srs.md` → `docs/requirements/README.md`
   - `templates/rmf.md` → `docs/risk/README.md`
   - `templates/sad.md` → `docs/architecture/README.md`
   - `templates/soup.md` → `docs/architecture/soup.md`
   - `templates/problems.md` → `docs/problems/README.md`
   - `templates/CONTEXT.md` → `docs/CONTEXT.md`
   - `templates/*_GUIDELINES.md` → `.guardrails/templates/`
   - `templates/CLAUDE.md` → `CLAUDE.md` (skip if one exists)
   - `templates/AGENTS-block.md` → the body of a new `AGENTS.md`

   The requirements, risk, architecture and problems directories are
   per-change ledgers: each change adds one file,
   `YYYY-MM-DD-<slug>.md`, dated the day the change creates it. Each README
   contains the item grammar.
4. Create `docs/adr/`, `docs/plans/` and `docs/verification/`, and copy
   `templates/verification.md` → `.guardrails/templates/verification.md`.
   **Never put the template in `docs/verification/`**: every `*.md` there is
   read as a record. If records are kept elsewhere, set `doc_verification`.
   Add any of these missing from `.gitignore`:

   ```
   .worktrees/
   .claude/worktrees/
   *.bak
   ```

   Add both worktree entries even where the project has only ever used
   one: `.claude/worktrees/` covers a harness's change worktrees, and
   `.worktrees/` the manual fallback and
   every task worktree, which is nested inside the change worktree
   (`worktree-discipline` step 1).
5. **Make every configured path exist in the commit**; `check-trace.sh` exits
   2 otherwise, and git does not track empty directories.
   - `strict_paths` / `test_paths` entries are git pathspecs and must match at
     least one committed file; a `.gitkeep` in an empty `src/` is enough.
   - `doc_*` values are a file, or a directory whose `*.md` files are directly
     in it. A directory needs a real `*.md`, not a `.gitkeep`: keep the README
     from sub-step 3.
   - Never leave a key out until its directory has content. To switch a gate
     off, drop its prefix from `id_prefixes`, and record why.
6. Run the **safety-class interview** (step 4), write the answer to
   `safety_class:`, replacing the `TBD` sentinel, and set `verify_commands`
   to the project's real test command.
   Run `tailor-guidelines` for `TEST`, `CODE` and `ARCHITECTURE` (once more
   per unit that wants its own file).
7. Commit in the worktree, then integrate with `merge-change`. The check
   scripts must pass on the result.

### Upgrading the scripts in an existing project

Work in a worktree, as a change of its own.

1. Follow the order of work in `references/upgrade-notes.md`; its first
   three items come before step 2.
2. Before copying, run `tailor-guidelines` in upgrade mode for each
   guidelines file. Then copy, from `<guardrails>`, `scripts/*.sh` →
   `.guardrails/scripts/`, keeping executable bits, and
   `templates/*_GUIDELINES.md` → `.guardrails/templates/`. Delete
   `.guardrails/scripts/finalize-ids.sh`, `finalize-docs.sh` and `prune-plans.sh` if present.
3. **Update the files that document the grammar with the scripts.**
   Re-copy the four ledger READMEs and the verification template from the
   same guardrails version, and re-replace the AGENTS.md managed block. If
   the project edited a README, diff and re-apply its additions.
4. Run `check-trace.sh`; fix each failure, and list each new warning in the
   verification record once Step 5 writes it. Existing ledgers report problem `status:`/`opened:`,
   supersession reciprocity and `DANGLING-FILE`.
   Derived assessments are now declared: a derived REQ/LLR without an
   `assesses:` line in the RMF goes red.
5. Re-record the tool qualification (Step 5), then integrate with
   `merge-change`.

### Step 3 (retrofit): Gap analysis first, then tighten

1. **Inventory** (read only): AGENTS.md/CLAUDE.md content and rules that
   conflict with guardrails ("commit to the base branch directly"); existing
   requirement, risk and architecture docs; a bug tracker or problem log;
   verification evidence worth archiving under `docs/verification/`; test
   layout and command; CI config; signing of recent commits
   (`git log -20 --format='%h %G? %s'`).
2. **Write the gap analysis** to `docs/plans/<YYYY-MM-DD>-ratchet-gap-analysis.md`:
   what exists, what is missing, what conflicts, and a proposed adoption order.
   It is the change's plan, dropped before the gate: copy its adoption
   order into the verification record once Step 5 writes it.
3. **First tooth**: install `.guardrails/` (config,
   scripts and templates, or the manifest and per-unit configs from step
   1b), merge the managed block into AGENTS.md, add missing doc skeletons,
   and extend `.gitignore` as step 2.4 lists. Do NOT migrate existing docs in this change.
   On a multi-unit repository, read `references/multi-unit.md` first.
   - If `<!-- guardrails:begin -->` exists, replace only the block between the
     markers. Otherwise append `templates/AGENTS-block.md` whole. Report
     conflicting rules to the user; do not delete them.
   - Set `strict_paths` to a SMALL list of paths that are already clean or
     new. Existing untraced code is grandfathered.
4. **Later teeth** (separate changes, listed in the retrofit's
   verification record): migrate legacy requirement and risk docs via
   `grill-requirements` / `analyze-risks`; run `tailor-guidelines` for each
   guidelines file; extend `strict_paths` area by area.
   Each `doc_*` key accepts a file or a directory, so `srs.md` keeps working;
   in a multi-developer repository, recommend moving each
   monolithic `doc_*` file into a directory as its first dated file, with the
   README, so changes stop conflicting.
5. Integrate via `merge-change`.

### Step 4: Safety-class interview (IEC 62304 4.3)

Ask one question at a time, recommending an answer:

1. Can a failure of this software contribute to a hazardous situation at all?
   If no → **Class A**.
2. If yes: could the resulting harm, after external risk controls outside the
   software are considered, be serious injury or death? If yes → **Class C**;
   non-serious injury → **Class B**.
3. Record the rationale as an ADR (`grill-requirements`, "ADRs").

If the user is unsure, walk through intended use, foreseeable misuse and
hardware safeguards first. Between two classes, the higher governs
until justified otherwise.

In a multi-unit repository, repeat this interview per unit and
record each class in that unit's config.

### Step 5: Human setup checklist

Write the change's verification record now: copy
`.guardrails/templates/verification.md` to
`docs/verification/<date>-<branch>.md`; put the filled, printed
`references/setup-checklist.md` under `## Tool qualification`.

**The signing items gate the ratchet.** It is not complete until `.guardrails/scripts/check-signing.sh --setup` exits 0:
satisfy them before step 2.7 / step 3.5. For a retrofit,
state early that **an existing project must configure commit signing before
it finishes adopting guardrails**. If a committer's public key is missing,
stop and name it.

**Tool qualification.** Record `guardrails_version` AND `guardrails_commit`
(`git -C <guardrails> rev-parse HEAD`) in config and that record,
with the suite result. Never
modify the scripts in the target project.

**The suite runs in the clone, never in the target project, and
bats is never installed.** Never add bats to the target project. Record
one qualifying run per update, or `suite not run at install time: <reason>`.

Capture the exit status from the run itself, never through a pipe, or the
recorded pass/fail is the wrong command's: run
`<guardrails>/tests/run-tests.sh > <tmp>/ratchet.log 2>&1; rc=$?` and read
`$rc` first. Keep the log, outside the clone; it must contain
`run-tests: testing commit <guardrails_commit>`; any other line beginning
`run-tests:` means it describes no commit: run again
(`references/rationale.md`).

## Red flags

| Thought | Reality |
|---|---|
| "I'll just overwrite their AGENTS.md" | Retrofit never overwrites. Managed block only. |
| "Enable strict checks everywhere now" | That blocks all work on legacy code. Tighten one tooth. |
| "Signing can be a later tooth" | The first merge enforces it: no proved signature, no cleanup. |
| "Skip the worktree for the scaffold" | Worktree and signed squash merge, as for any change. |
| "safety_class can stay TBD" | Nothing else scales correctly until it is set. |
| "The scripts are copied, so the upgrade is done" | The READMEs, the template and the managed block are refreshed too. |

## Done when

- `safety_class` is set (per unit where there are units), with its ADR.
- A retrofit's verification record carries its gap analysis's adoption order.
- An upgrade copied scripts and grammar files from one guardrails version,
  fixed each failure, and listed each new warning in the verification record.
- The setup checklist is saved, with the qualification basis.
- `check-signing.sh --setup` exits 0.
- The change is merged through `merge-change`, and the check scripts pass.

## References

- `references/upgrade-notes.md` — read when updating `.guardrails/scripts/` in
  a project that already has them, before copying the new scripts in.
- `references/multi-unit.md` — read when step 1b found more than one unit,
  before step 2.3 or step 3.3 installs any file.
- `references/setup-checklist.md` — read when you reach step 5.
- `references/rationale.md` — read when a rule here seems wrong, or
  before proposing to change one.
