# Verification — scan-pathspec (2026-08-20)

Change: construct the tree-scan pathspec in one place, and exclude only the
guardrails tooling's own files from it. Branched from `main` at `62f3a48`.
Plan and acceptance criteria: `docs/plans/2026-08-20-scan-pathspec.md`.

One defect, of the class this project exists to remove: a check that exits 0
having proved nothing. Every tree-wide scan in three scripts carried the
pathspec `-- . ":(exclude).guardrails"`, typed out fifteen times. The exclusion
is necessary — the installed scripts carry a literal `REQ-DRAFT-b-1` and
definition-form examples in their own comments — but it was one directory too
wide, and the extra directory held the project's own files.

Reproduced against `main` before any code was written, with `doc_srs` pointing
at `.guardrails/docs/requirements` and one draft item in a `DRAFT-` ledger
there:

| Step | Output | Exit |
| --- | --- | --- |
| `check-ids.sh` (before) | `DRAFT-FILE …/DRAFT-e-srs.md` | 1 |
| `finalize-ids.sh` | `DRAFT-e-srs.md -> 2026-08-20-e-srs.md` | **0** |
| `check-ids.sh` (after) | *(nothing)* | **0** |
| `check-trace.sh` (after) | `checked: REQ 0, …` / `sources: srs 2, …` | **0** |

The ledger was renamed to its merge-date name, no ID was minted, and
`REQ-DRAFT-e-1` survived in the file with all three gates green — the
half-finalized tree `finalize-ids.sh`'s own pre-flight exists to refuse,
produced by the script that owns the pre-flight, because the pre-flight's token
scan carried the same wide pathspec.

The same reproduction on this branch reports the token and mints it:

```
DRAFT-ID .guardrails/docs/requirements/DRAFT-e-srs.md:3:**REQ-DRAFT-e-1**: …
REQ-DRAFT-e-1 -> REQ-001
DRAFT-e-srs.md -> 2026-08-20-e-srs.md
```

## What was attempted and cut

Most of this change's elapsed time went into a config check — "rule 3" — that
refused a `doc_*` configured **inside** the excluded directory. It is not in
the shipped diff.

It was defence in depth for a configuration nobody writes: a project pointing
its requirements ledger into `.guardrails/scripts/`. It reached 136 of the 165
lines this change had added to `lib.sh`, and independent review found **six**
blocking defects in it across three rounds — a linked-worktree pathspec failure,
git's C-quoting of non-ASCII paths, a dropped leading slash, a `..` that leaves
the repository and re-enters, `/..` before an absolute path, and a swallowed
`gr_root` failure. Every one was a false green inside code written to prevent
false greens, and each fix invalidated the mutation table and the figures below,
which is what made the change run long.

The defect this change exists to fix never needed it. Narrowing the exclusion
fixes it, and that commit — `c4094cc` — drew no finding in any round. Cutting
rule 3 took `lib.sh` from 165 added lines to 27, of which **2 are code**.

The residual hole is recorded as gap 1 and is exactly what `main` does today.

### What the attempt taught, kept because it outlives it

`git ls-files` with a negative pathspec can return **nothing** for a path that
plainly exists, whenever the negative pathspec is shorter than the positive
one's directory prefix. Measured on git 2.53.0, in a primary checkout with
plain `--cached` — it is neither worktree-specific nor
`--exclude-standard`-specific, though two earlier drafts of this record claimed
otherwise, and one before that blamed the excluded directory's depth.
Independent review falsified each guess in turn.

`git grep` is unaffected at every pathspec length tested, which is why the
fifteen scan sites this change *does* ship are safe. Worth knowing before
anyone reaches for `git ls-files` to decide something.

## The gate

Every figure below is derived from the shipped tree, not carried forward.

| Gate | Result |
| --- | --- |
| `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` | **184 ok, 0 not ok** (`main`: 175) |
| `tests/evidence.sh main` | 12 new or renamed; **8 go red** against `main`; 4 cannot |
| `sh -n` on all five scripts and both test scripts | clean |
| Script modes | all five `100755`, unchanged |
| Corpus (`sightings-app` @ `6a00145b`, 1135 tracked files) | `check-ids`, `check-trace`, `finalize-ids --dry-run` **byte-identical** to `main` |
| Corpus runtime (`check-ids` + `check-trace`) | three interleaved pairs: `main` 21.7 / 22.0 / 21.8 s, branch 21.6 / 22.1 / 22.6 s — **overlapping ranges, no measurable difference**. Measured under load from the mutation battery, so comparable to each other and to nothing else. An earlier single pair here read as a ~1.5% regression; independent review re-measured and found the branch never slower, so it was noise |

The corpus run is also the compatibility evidence for AC7: `check-ids.sh`
validates the config now, and a real project's config passes it unchanged.

## Mutation table

Each row reverts one production change and re-runs the whole suite. A change no
test can detect is a change with no evidence behind it.

Rows **M01, M03 and M08** revert behaviour. Rows **M09–M23** change no
behaviour at all: each replaces one call site's `"$GR_SCAN_EXCLUDE"` with a
literal of the *same* value, so only a test that makes the value differ — the
poisoning tests, AC8 — can see them. That is what AC11 measures. The numbering
has gaps because M02 and M04–M07 measured rule 3, which was cut; the surviving
rows keep their identifiers rather than being renumbered, so this table can be
compared against the earlier rounds it came from.

**The mutations are committed**, at
`docs/verification/2026-08-20-scan-pathspec.mutations/`. The table is derived,
not typed: `tests/mutate.sh docs/verification/2026-08-20-scan-pathspec.mutations`.

One caveat on provenance, because round 3 rejected an earlier version of this
paragraph for overstating it: `tests/mutate.sh` is the deliverable of a
*separate* unmerged change (`mutation-runner`), so that command does not run on
this branch yet. This table was produced by copying the tool onto a throwaway
copy of this tree, which is why the header line below names a commit that
exists in no ref. Once `mutation-runner` merges and this branch rebases, the
command works as written and the header names a real commit. Until then, take
the header's hash as identifying nothing.

Derived by `tests/mutate.sh 2026-08-20-scan-pathspec.mutations` at commit 1be6195 — do not edit by hand.

- Suite: **179 tests**, green at baseline; 12 job(s).
- Excluded from every run: `tests/check-signing.bats` (its ssh-keygen
  fixture stalls against a wedged agent and would hang the batch). Rows below
  measure the remaining 179 tests only.

| # | Reverted | Red | Caught by |
| --- | --- | --- | --- |
| M01 | lib.sh: GR_SCAN_EXCLUDE widened back to .guardrails (pre-change value) | 4 | check-ids: a draft ID in a project file under .guardrails/ is reported; check-trace: items in a ledger under .guardrails/ are counted, not silently zero; finalize: a draft in a ledger under .guardrails/ is minted, not just renamed; finalize: an unmintable draft under .guardrails/ blocks instead of being renamed away |
| M03 | check-ids.sh: the gr_check_config call is removed | 1 | check-ids: a misspelled config key is an error here too |
| M08 | lib.sh: GR_SCAN_EXCLUDE narrowed so the tooling is no longer excluded | 42 | check-ids: clean repo passes; check-ids: editing an inherited requirement is not flagged by --base; check-ids: an ID inside the excluded tooling dir is not a duplicate of a minted one; check-ids: an undetectable base says the gate was skipped, and still passes; check-ids: relocating two definitions in one change is not a duplicate; check-ids: a definition-form token off column one is reported, not failed; check-ids: an ordinary tree reports no UNANCHORED-DEF; check-ids: an indented definition on the base is not something to collide with; check-ids: an off-column token below the ceiling is not reported; check-ids: an indented token above the ceiling is reported with the ID as written; check-ids: the highest item's own definition line does not report itself; check-ids: a definition line declares its own ID, not every ID on it; check-ids: the ceiling counts the base ref, as finalize-ids does; check-ids: a non-ASCII filename does not silently skip the scan; check-ids: with no usable base the report says the base was not consulted; check-ids: a colon in a path does not eat the line number; poisoning gr_def_re changes every gate's verdict; check-ids: a path with newlines is reported unreadable, not given a made-up location; check-ids: one newline in a path is caught too; check-ids: a stock install does not report its own tooling; poisoning GR_SCAN_EXCLUDE changes every gate's verdict; check-trace: template READMEs in ledger dirs cause no false positives; finalize: mints next sequential ID and rewrites references; finalize: --dry-run prints mapping and changes nothing; finalize: overlapping draft tokens (-1 and -12) rewritten correctly; finalize: prefixes are numbered independently; finalize: LLR and PR prefixes finalize independently; finalize: renames draft doc file to merge-dated name; finalize: --dry-run does not rename draft doc files; finalize: dated-name collision gets a numeric suffix; finalize: same-run rename collisions get distinct names, no data loss; finalize: default base is the primary checkout's branch, not main; finalize: idempotent second run does nothing; finalize: a rename that fails aborts instead of reporting success; finalize: same-day rename collision never overwrites an existing file; finalize: a draft ledger name with whitespace fails before anything is rewritten; finalize: a draft inside the excluded tooling dir is not minted against a rewrite that skips it; finalize: an ID inside the excluded tooling dir does not shift the next number; a definition-form token off column one does not raise the mint ceiling; an indented definition does not raise the mint ceiling either; a digit-bearing prefix does not have its own digits read as the number; finalize: a draft in a ledger under .guardrails/ is minted, not just renamed |
| M09 | check-ids.sh: call site #1 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE changes every gate's verdict |
| M10 | check-ids.sh: call site #2 holds its own literal instead of the constant | 2 | poisoning GR_SCAN_EXCLUDE changes every gate's verdict; poisoning GR_SCAN_EXCLUDE moves the duplicate-vs-base scan too |
| M11 | check-ids.sh: call site #3 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE moves the duplicate-vs-base scan too |
| M12 | check-ids.sh: call site #4 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE changes every gate's verdict |
| M13 | check-ids.sh: call site #5 holds its own literal instead of the constant | 0 | **none — no test detects this** |
| M14 | check-ids.sh: call site #6 holds its own literal instead of the constant | 0 | **none — no test detects this** |
| M15 | check-ids.sh: call site #7 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE changes every gate's verdict |
| M16 | check-ids.sh: call site #8 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE changes every gate's verdict |
| M17 | check-trace.sh: call site #1 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE changes every gate's verdict |
| M18 | finalize-ids.sh: call site #1 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE moves the mint ceiling too |
| M19 | finalize-ids.sh: call site #2 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE moves the mint ceiling too |
| M20 | finalize-ids.sh: call site #3 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE moves the mint ceiling too |
| M21 | finalize-ids.sh: call site #4 holds its own literal instead of the constant | 2 | poisoning GR_SCAN_EXCLUDE changes every gate's verdict; poisoning GR_SCAN_EXCLUDE moves the mint ceiling too |
| M22 | finalize-ids.sh: call site #5 holds its own literal instead of the constant | 1 | poisoning GR_SCAN_EXCLUDE changes every gate's verdict |
| M23 | finalize-ids.sh: call site #6 holds its own literal instead of the constant | 0 | **none — no test detects this** |

### The four that cannot go red

`evidence.sh` names them, and none is counted as evidence that a defect was
fixed. One is a guard; three are renames.

| Test | Why it cannot go red | Load-bearing per |
| --- | --- | --- |
| a stock install does not report its own tooling | AC9 — asserts the criterion the narrowing trades against, and `main` already satisfied it. The plan said so before it was written | **M08**, which narrows the exclusion until the tooling is no longer covered. An earlier draft cited M1 here; M1 *widens* the exclusion and leaves this test green, so it was no evidence at all. Found by independent review |
| an ID inside the excluded tooling dir is not a duplicate of a minted one | renamed, and its fixture moved from `.guardrails/notes.md` to `.guardrails/scripts/notes.md` — the requirement is unchanged, only the boundary moved | the requirement it encodes is AC1's, which M09–M23 measure |
| a draft inside the excluded tooling dir is not minted against a rewrite that skips it | same rename | as above |
| an ID inside the excluded tooling dir does not shift the next number | same rename | as above |

### The three call sites no test protects

Behaviourally these mutations change nothing — the literal is the same string —
so only a test that makes the value differ can see them, and the poisoning
fixtures do not reach these three. Named here rather than left implied:

| Site | What it scans | Why the poisoning tests miss it |
| --- | --- | --- |
| `check-ids.sh` #5 — row **M13** | the `-q` probe that gives `UNANCHORED-DEF` an honest exit status outside a pipeline | it reports no output of its own; its only observable effect is suppressing the scan, which the candidates scan (#4, row M12) already demonstrates |
| `check-ids.sh` #6 — row **M14** | detection of newline-bearing paths, which emits `UNANCHORED-DEF-UNREADABLE` | flipping it needs a newline in a filename **and** a definition token, in a tree where moving the exclusion changes which of them is visible. Two existing tests cover the gate itself; neither varies the pathspec |
| `finalize-ids.sh` #6 — row **M23** | the rewrite pass that substitutes final IDs into files | every poison that changes which files it sees also stops excluding the tooling, whose own `REQ-DRAFT-b-1` then trips the pre-flight — so the run exits 1 before reaching the rewrite. Covered by the **value** mutation M01 instead, via `AC4 minted not just renamed`, which asserts no draft token survives under `.guardrails/docs/` after a real run |

The first and third are covered by other means, as the table says. The second
is genuinely unprotected against a future divergent literal, and is the one row
here that a reviewer should weigh.


## Derived evidence block

Derived by `tests/evidence.sh main` — do not edit by hand.

- Suite: **184 tests** (main: 175); 179 measured against `main`.
- New or renamed since `main`: **12**.
- Of those, **8** go red when run against `main`'s scripts.
- **4** cannot go red, and none is counted as evidence that a
  defect was fixed:

  - `check-ids: a stock install does not report its own tooling`
  - `check-ids: an ID inside the excluded tooling dir is not a duplicate of a minted one`
  - `finalize: a draft inside the excluded tooling dir is not minted against a rewrite that skips it`
  - `finalize: an ID inside the excluded tooling dir does not shift the next number`

## Gaps

1. **A ledger the scans cannot see is still accepted.** A `doc_*` configured
   inside `.guardrails/scripts/`, inside `.git/`, on a gitignored path, or
   behind a symlink is invisible to every gate: `finalize-ids.sh` renames the
   draft ledger to its merge-date name, mints nothing, and exits 0, while
   `check-trace.sh` reports the file in `sources:` and zero items in
   `checked:`. This change does **not** fix that — see "What was attempted and
   cut". It is exactly what `main` does today, so nothing regresses; it is
   listed here because the attempt to fix it is the reason this change ran
   long, and because whoever picks it up should know it is a bigger job than it
   looks.

### The measured matrix

Independent review built this; the three shipped passages point here rather
than trying to summarise it, because three attempts to summarise it were each
wrong in a new way. `check-ids` / `check-trace` / `finalize` columns give exit
codes.

| `doc_*` location | ledger | check-ids | check-trace | finalize |
| --- | --- | --- | --- | --- |
| `docs/requirements` (control) | final | 0 | 1 `MISSING-TEST`, `checked: REQ 1` | 0, nothing |
| `docs/requirements` (control) | draft | 1 `DRAFT-ID`+`DRAFT-FILE` | 0 | 0, **mints** |
| `.guardrails/scripts/…` tracked | final | 0 | **1 `DANGLING-REF`**, `checked: REQ 0` | 0, nothing |
| `.guardrails/scripts/…` tracked | draft | **1 `DRAFT-FILE`** | 0 | 0, renames, no mint |
| `.guardrails/scripts/…` untracked, not ignored | final / draft | 0 / **1** | **1** / 0 | as above |
| `.guardrails/scripts/…` untracked + ignored | final / draft | 0 / 0 | 0 / 0 | 0, renames, no mint |
| `.guardrails/scripts/…` **tracked** + ignored | final / draft | 0 / **1 `DRAFT-FILE`** | 0 / 0 | 0, renames, no mint |
| `.git/…` | final / draft | 0 / 0 | 0 / 0 | 0, renames, no mint |
| gitignored path, untracked | final / draft | 0 / 0 | 0 / 0 | 0, renames, no mint |
| gitignored path, **force-added** | final / draft | 0 / **1 `DRAFT-FILE`** | 0 / 0 | 0, renames, no mint |
| symlink → **outside** the repo | final / draft | 0 / 0 | 0 / 0 | 0, renames, no mint |
| symlink → **inside** the repo | final | 0 | **1 `MISPLACED-ITEM`+`MISSING-TEST`**, `checked: REQ 1` | 0, nothing |
| symlink → **inside** the repo | draft | **1 `DRAFT-ID`+`DRAFT-FILE`** | 0 | 0, **mints** |

Three things this makes plain that prose kept getting wrong:

- **The discriminator under `.guardrails/scripts/` is "not gitignored", not
  "tracked".** An untracked, unignored ledger complains exactly as a tracked
  one does; both scans pass `--untracked` / `--others`.
- **Gitignoring a ledger that git already tracks silences only half of it.**
  `DANGLING-REF` goes quiet; `DRAFT-FILE` does not, because it comes from
  `git ls-files --cached`, which takes no pathspec and lists tracked files
  whatever `.gitignore` says. `DANGLING-REF` comes from a `git grep` that takes
  its own pathspec and so never carries the exclusion. They are different
  mechanisms, and an earlier version of this record called them the same one.
- **The one warning is pre-finalize only.** After `finalize-ids.sh` renames the
  draft ledger, both gates exit 0 over a tree still holding the live draft
  token — and the merge flow runs finalize before the final checks, so the
  warning is removed by the very step that strands the token.

A symlink to a directory **inside** the repository is not an invisible location
at all: it is scanned under the target's real path, so items count, placement
is checked, and drafts mint normally.

2. **`GR_SCAN_EXCLUDE` holds exactly one pathspec.** A project that needed two
   exclusions could not have them, and the poisoning tests exploit this — the
   poison replaces the exclusion rather than adding to it. No project has
   needed two; recorded because the constraint is invisible from the call
   sites.
3. **The `git ls-files` behaviour above is worked around by not using it.** No
   gate in this change hands `git ls-files` a decision a negative pathspec
   makes, and the fifteen scan sites use `git grep`, which is unaffected. The
   mechanism is still not understood, and the trap remains available to anyone
   who reaches for the construct again.
4. `check-signing.sh` still does not call `gr_check_config` — the other half of
   gap 3 in `docs/verification/2026-08-18-config-schema.md`. It reads no config
   key at all, so nothing it does can be silently disabled by one; left as-is
   deliberately, and that gap is now half closed rather than open.
5. **This repository still has no `.guardrails/config.yaml` of its own**, so
   guardrails cannot be run against guardrails. Gap 4 of change B, unchanged.
   It is why this plan's `Implements:` line carries acceptance criteria rather
   than REQ IDs.
6. `guardrails_version` is still `0.1.0` and this change alters behaviour a
   ratcheted project can observe. Recorded, not fixed — the version scheme is
   its own change.
