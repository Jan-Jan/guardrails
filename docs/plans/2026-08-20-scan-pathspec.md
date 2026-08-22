# Scan Pathspec Implementation Plan

**Goal:** Construct the tree-scan pathspec in one place, and exclude only the
guardrails tooling's own files from it — never the project's.
**Implements:** AC1–AC5, AC7–AC9 and AC11 below. AC6 and AC10 were attempted
and cut; the section "Not done" says why, and both are defined there so a
reader is never sent to a criterion that is only referenced. Task 6 is absent
from the Tasks list for the same reason — it built AC6. No SRS exists for this repository, so the
acceptance criteria *are* the requirement of record for this change.
**Safety class:** n/a — guardrails is tooling, not a medical device. Its own
analogue of class B is the mutation discipline in `tests/evidence.sh`: every
change must be shown to redden a named test.
**Verification:** `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` — all green,
plus the reversal evidence recorded in `docs/verification/`.

## The defect

Reproduced against `main` (`62f3a48`) **before** any code was written, in a
throwaway repo with the stock scripts installed at `.guardrails/scripts/` and
one line changed in the config:

```yaml
doc_srs: .guardrails/docs/requirements
```

with `.guardrails/docs/requirements/DRAFT-e-srs.md` holding a single item:

```markdown
**REQ-DRAFT-e-1**: The pump shall stop on occlusion.
```

Observed, in the order a merge runs them:

| Step | Output | Exit |
| --- | --- | --- |
| `check-ids.sh` (before) | `DRAFT-FILE .guardrails/docs/requirements/DRAFT-e-srs.md` | 1 |
| `finalize-ids.sh` | `DRAFT-e-srs.md -> 2026-08-20-e-srs.md` | **0** |
| `check-ids.sh` (after) | *(nothing)* | **0** |
| `check-trace.sh` (after) | `checked: REQ 0, …` / `sources: srs 2, …` | **0** |

The ledger file is renamed to its merge-date name; **no ID is minted**; and
`REQ-DRAFT-e-1` survives in the file with every gate green. That is precisely
the half-finalized tree finalize-ids.sh's pre-flight exists to refuse — and the
pre-flight cannot see it, because its token scan carries the same
`:(exclude).guardrails` pathspec as everything else.

The `DRAFT-FILE` line in the first row is not a save. It fires from
`git ls-files`, which takes no pathspec, and it is satisfied by the very
rename that strands the token. It reports the symptom and then the fix for the
symptom removes the report.

`check-trace.sh`'s last row carries the tell: `sources: srs 2` counts the doc
files from the config, which is not path-excluded, while `checked: REQ 0`
counts definitions from `ids_defined`, which is. One script, two opinions
about which files exist.

### Why the exclusion is there at all

The installed scripts contain, in their own comments and patterns, text that
matches the gates' own regexes — `REQ-DRAFT-b-1 vs REQ-DRAFT-b-12` in
finalize-ids.sh, definition-form examples in three scripts. Without an
exclusion a stock project reports its own tooling.

But the exclusion was written as the whole `.guardrails/` tree when only the
tooling needs it. Measured on the reproduction repo, every trigger inside
`.guardrails/` comes from `.guardrails/scripts/`:

| Pattern | Files that match, under `.guardrails/` |
| --- | --- |
| draft token | `scripts/finalize-ids.sh` (1) — and the planted `docs/…` file |
| definition form, anchored | *(none)* |
| definition form, anywhere | `scripts/check-ids.sh` (2), `scripts/check-trace.sh` (1), `scripts/finalize-ids.sh` (1) |
| bare ID reference | `scripts/{check-ids,check-trace,finalize-ids,lib}.sh` |

`config.yaml` triggers nothing. Neither does anything else a project might put
there. The exclusion is one directory too wide, and the extra directory is
exactly the project's own content.

## AC1 — one definition of the scan pathspec

`scripts/lib.sh` sets `GR_SCAN_EXCLUDE` once; all 15 call sites across
`check-ids.sh`, `check-trace.sh` and `finalize-ids.sh` read it instead of
spelling the pathspec themselves.

A **variable**, not a function like `gr_def_re`. A pathspec is a separate
`git grep` argument, so a function returning it would have to be expanded
unquoted and word-split — and `finalize-ids.sh` and `check-trace.sh` both set
`IFS` to newline at top level, so splitting on spaces is not available to
them. `-- . "$GR_SCAN_EXCLUDE"` needs no splitting and keeps every call site
honestly quoted.

The assignment is unconditional (`GR_SCAN_EXCLUDE=':(exclude)…'`, never
`${GR_SCAN_EXCLUDE:-…}`), so an inherited environment variable cannot widen
the exclusion. A caller who could set it to `:(exclude).` would blind every
gate in the toolkit while every exit code stayed 0.

## AC2 — the exclusion covers the tooling, not the tree

`GR_SCAN_EXCLUDE` is `:(exclude).guardrails/scripts`, not
`:(exclude).guardrails`.

## AC3 — a draft ID in a project file under `.guardrails/` is reported

`check-ids.sh` reports `DRAFT-ID` for `**REQ-DRAFT-x-1**:` in
`.guardrails/docs/requirements/DRAFT-x-srs.md` and exits 1.

## AC4 — finalize-ids mints it, and its pre-flight sees it

`finalize-ids.sh --dry-run` prints `REQ-DRAFT-x-1 -> REQ-001` alongside the
file rename. With the token's header un-bolded so it cannot be minted, the
pre-flight reports `UNMINTED-DRAFT` and exits 1 with the tree untouched,
instead of renaming the file and exiting 0.

## AC5 — check-trace counts items defined under `.guardrails/`

With `doc_srs` pointing there and one final `**REQ-001**:` defined, the
summary reads `checked: REQ 1, …` rather than `REQ 0`.

## AC7 — check-ids validates the config too

`check-ids.sh` calls `gr_check_config`. This closes the `check-ids.sh` **half**
of gap 3 recorded in `docs/verification/2026-08-18-config-schema.md`, which
names two scripts; `check-signing.sh` reads no config key at all and is left
alone deliberately. Without the call, every shape `gr_check_config` exists to
refuse — a misspelled key, a key hidden behind a BOM, a declared prefix whose
gate inputs are unconfigured — was refused by two of the three gates, and a
project running `check-ids.sh` alone got no config validation at all.

## AC8 — poisoning `GR_SCAN_EXCLUDE` changes every gate's verdict

Change D's lesson: a lint that greps for the right spelling is defeated by a
different spelling. The test that proves the single source of truth is
behavioural — redefine `GR_SCAN_EXCLUDE` at the end of `lib.sh` so it excludes
the project's docs, and assert that `check-ids.sh`, `check-trace.sh` and
`finalize-ids.sh` all change their verdict. A call site that kept its own
literal pathspec would be unaffected and fail this test.

## AC9 — a stock ratcheted project is still clean

The installed scripts must not report themselves. With guardrails installed at
`.guardrails/scripts/` and no project items at all, `check-ids.sh` exits 0 and
`finalize-ids.sh --dry-run` prints nothing. This is the criterion AC2 is
trading against, so it is asserted rather than assumed.

## Not done: AC6 and AC10, attempted and cut

**AC6, as it read:** *a doc ledger inside the excluded tree is rejected* —
`gr_check_config` refuses any `doc_*` value resolving inside
`GR_SCAN_EXCLUDE`'s directory, naming the key and the path.

**AC10, as it read** (added mid-change, after the first attempt at AC6 failed):
*no gate may hand `git ls-files` a decision a negative pathspec makes.* It
existed only to constrain how AC6 was implemented; with AC6 gone it constrains
nothing this change ships, so it is cut too rather than left as a rule with no
subject. What it was learned from is kept below, because that outlives both.

A `doc_*` configured **inside** `.guardrails/scripts/` — or inside `.git/` —
stays invisible to every gate, exactly as it is on `main` today. This change
does not fix that, deliberately.

It tried to, through three review rounds, and the attempt is why the change ran
long. The check was defence in depth for a configuration nobody writes: a
project pointing its requirements ledger into the guardrails scripts directory.
It grew to 136 of the 165 lines this change added to `lib.sh`, and produced six
blocking defects of its own — a linked-worktree pathspec failure, git's
C-quoting of non-ASCII paths, a dropped leading slash, a `..` that leaves the
repository and re-enters, `/..` before an absolute path, and a swallowed
`gr_root` failure. Every one was a false green in code written to prevent false
greens.

The defect this change exists to fix needed none of it. Narrowing the exclusion
(AC2) fixes it, and that commit drew no finding in any round.

Recorded as a gap rather than shipped half-verified. If it is worth doing it is
worth doing as its own change, where its cost is visible against its value
instead of hidden inside an unrelated fix.

### What the attempt taught, kept because it outlives it

`git ls-files` with a negative pathspec can return **nothing** for a path that
plainly exists, whenever the negative pathspec is shorter than the positive
one's directory prefix — in any checkout, with any flags, primary checkout with
plain `--cached` included. Measured on git 2.53.0. `git grep` is unaffected at
every length tested, which is why the fifteen scan sites this change does ship
are safe. Worth knowing before anyone reaches for `git ls-files` to decide
something.

## AC11 — every call site is covered by the poisoning test, or the record says why not

AC8 proves the three scripts share one definition. It proves nothing about a
call site the poisoning fixture never reaches: a site that kept its own literal
of the same value is behaviourally identical, so only a test that makes the
value *differ* can see it. The mutation table therefore literalizes each of the
15 sites individually, and any site reddening no test is named in the record as
unprotected against future divergence, with the reason.

## Tasks

Each task is one red → green → commit cycle. Tests live in the `.bats` file
named beside them.

1. **AC9 guard first** (`tests/check-ids.bats`) — a stock install stays clean.
   Written before AC2 so the narrowing has a standing witness. Expected to
   pass immediately against `main`; its value is as a regression guard, and
   the evidence record must say so rather than claiming a red.
2. **AC3** (`tests/check-ids.bats`) — draft ID under `.guardrails/docs/`
   reported. RED against `main`.
3. **AC2 + AC1** (`scripts/lib.sh`, three scripts) — introduce
   `GR_SCAN_EXCLUDE`, narrow it, replace all 15 call sites. Greens AC3.
4. **AC4** (`tests/finalize-ids.bats`) — both halves: minted, and pre-flight
   refusal on an un-mintable header.
5. **AC5** (`tests/check-trace.bats`) — `checked: REQ 1`.
7. **AC7** (`tests/check-ids.bats`) — check-ids rejects a malformed config.
8. **AC8** (`tests/check-ids.bats`) — the poisoning test.
9. **Evidence** — `docs/verification/2026-08-20-scan-pathspec.md`: mutation
   table (every production hunk reverted, suite re-run, reddened tests cited
   by name), guard→mutation one-to-one table, and the updated gap list.

## Self-review

- Every AC has at least one task whose test asserts it: AC1→8, AC2→3+9, AC3→2,
  AC4→4, AC5→5, AC7→7, AC8→8, AC9→1.
- **AC11 has no test, by construction.** It is a statement about what the
  mutation table must contain, and it is discharged by the table itself and by
  the record's "three call sites no test protects" section. Said here so that
  its absence from the suite is not mistaken for an oversight.
- `GR_SCAN_EXCLUDE` is the only new name; it is used identically in all three
  scripts and defined in exactly one.
- Task 1 is expected green on arrival. That is recorded here so the evidence
  record cannot later present it as a demonstrated red.
