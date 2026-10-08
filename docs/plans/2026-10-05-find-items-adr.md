# find-items reads ADR items — Implementation Plan

**Goal:** `find-items.sh list` and `show` read the ADR items in `docs/adr/`,
so an ADR is listed and shown like any other item.
**Implements:** resolves `PR-ka8w9m`
(`docs/problems/2026-10-05-find-items-adr-items.md`).
**Safety class:** the toolkit is unclassified; the class B rules in
`AGENTS.md` apply. `find-items.sh` checks nothing and gates nothing.
**Verification:** `sh tests/run-tests.sh`, dispatched to a subagent
(AGENTS.md non-negotiable 3); the verdict comes from the reported pass and
fail counts. Then `sh tests/evidence.sh main`, which must exit 0 and must
count the new tests as going red.
`check-ids.sh` and `check-trace.sh` run on scratch copies of `main` and the
change (the recipe in `docs/verification/2026-10-03-accept-2scmvn.md`). The
scratch config declares `ADR`, so each ADR literal in a test fixture is a
`DANGLING-REF`, as six already are on `main`; the new fixture IDs add such
lines. The fixture line `**ADR-x7k2m9**:` in `tests/find-items.bats` is at
column one, so `check-trace.sh` counts it as a definition (`ADR 5` becomes
`ADR 6`), and the new problem item adds one to the `PR` and `problems`
counts. (Corrected after review round 2, finding 10.)

**Base.** Branched from local `main` at `17a0d58` on 2026-10-05.

Run single bats files with `tests/.bats-core/bin/bats <file>`, never with
`tests/run-tests.sh <file>`.

## Decisions

**D1 — read the ADR files rather than reject `--kind ADR`.** The adr-ids
decisions (`docs/plans/2026-10-04-adr-ids.md`, D1 and D3) fix where an ADR
is defined: `docs/adr/ADR-<token>-<slug>.md`, opening with
`**ADR-<token>**:`, and in a multi-unit repository a unit's ADR is in that
unit's `docs/adr/`. No config key names the directory. So `find-items.sh`
adds the files that match `docs/adr/ADR-*.md` to the files it reads.
(Amended after review round 1, finding 1: under a unit `GR_CONFIG` it reads
`<unit>/docs/adr/ADR-*.md` and the root `docs/adr/ADR-*.md`, the two places
`scripts/check-units.sh` accepts for an ADR cited by ID; and, finding 3, it
reads them only when `ADR` is declared.)
Rejecting `--kind ADR` would still leave `show ADR-<token>` reporting
`NOT-FOUND` for an ADR that exists.

**D2 — the block rule is unchanged.** `show` ends an ADR's block at its first
heading, as for every item (`GR_AWK_ITEM_BLOCK` in `scripts/lib.sh`). For an
ADR that is the item line and the lines before `## Context`; the `==>`
line gives the file, and the file holds one decision. `list` prints `-` as
an ADR's status, because the ADR form has `Status:`, not a column-one
`status:` line. Neither is changed here.

**D3 — `refs` is unchanged.** It searches the whole working tree already.

---

### T1 — read docs/adr/ADR-*.md in list and show

T1 is the task as dispatched. The amended D1 supersedes its unit rule and
its glob in steps 2 and 3: the root ADRs are read under a unit config too, and
only when `ADR` is declared (review round 1; noted after round 2, finding 11).

**Files touched:** `scripts/find-items.sh`, `tests/find-items.bats`
**Parallel:** no (only task)

1. **Mutation evidence first.** `docs/verification/2026-10-04-find-items.mutations/`
   holds `M*.sh` scripts that quote lines of `scripts/find-items.sh` as anchors.
   Before editing, list the anchors the edit would touch:
   `grep -n 'ledger_files\|doc_key\|key_files' docs/verification/*.mutations/M*.sh`.
   Prefer an edit that adds lines and leaves every quoted line byte-identical.
   Report any anchor the edit changes; do not edit the mutation scripts.
2. **Tests first**, in `tests/find-items.bats`, each with the comment line
   `# verifies: PR-ka8w9m` directly above it, in the form the file's other
   annotated tests use (if none is annotated, the form `tests/evidence.bats`
   uses). In the default fixture, add
   `docs/adr/ADR-x7k2m9-dose-limit-source.md`:

   *(Code pruned at merge: 8 lines. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`.)*

   and `docs/adr/README.md` containing the line
   `**ADR-q3w8e4**: An item line outside an ADR file.`, which must not be read.
   Commit both in the test, not in `setup`, so that no existing test's output
   changes. Tests:
   - "find-items: list --kind ADR prints an ADR defined in docs/adr" — output
     exactly
     `ADR-x7k2m9 - docs/adr/ADR-x7k2m9-dose-limit-source.md:1 The dose limit is read from the pump configuration.`,
     exit 0. No `ADR-q3w8e4` line.
   - "find-items: show prints an ADR block and ends it at the heading" —
     exit 0, first line `==> docs/adr/ADR-x7k2m9-dose-limit-source.md:1`,
     contains `Status: accepted`, does not contain `## Context`.
   - "find-items: show does not read an item line in a docs/adr file that is not named ADR-*.md" —
     `show ADR-q3w8e4` exits 1 with `NOT-FOUND ADR-q3w8e4`.
   - "find-items: list in a multi-unit repository reads the ADRs of the unit that GR_CONFIG names" —
     with `make_units_fixture`, write `**ADR-...**:` files (mint distinct
     valid-looking tokens: lowercase letters without o/l/i and digits 2-9,
     six characters, at least one digit) in `apps/pump/docs/adr/`,
     `platform/hal/docs/adr/` and the root `docs/adr/`; under the
     `apps/pump` config `list --kind ADR` prints only the `apps/pump` one, with
     its root-relative path. Use `unit_run` as the existing unit test does.
     If the units fixture's config does not declare `ADR`, add it to that
     unit's `id_prefixes` in the test and say so in the report.
   Run `tests/.bats-core/bin/bats tests/find-items.bats` and watch the new
   tests fail for the right reason (the ADR line absent, `NOT-FOUND`). The
   README test and any test that passes before the fix: report it as unable
   to go red.
3. **Fix.** In `scripts/find-items.sh`, after the `doc_*` loop and before the
   dedupe, append each regular file matching
   `${GR_UNIT:+$GR_UNIT/}docs/adr/ADR-*.md` to `ledger_files`, one per line.
   An unmatched glob stays literal in POSIX sh, so test each path with
   `[ -f ]`. Pathname expansion is still on there (`set -f` comes later).
   Confirm by reading `scripts/lib.sh` how `GR_UNIT` is set and that it is
   root-relative. Update the header: `list` reads the `doc_*` files and the
   ADR files, with the path rule from D1. The `gr_die` for no `doc_*` key
   stays as it is.
4. Run `tests/.bats-core/bin/bats tests/find-items.bats tests/portability.bats`
   and confirm every test passes. Commit unsigned on the task branch.

Report: commits, the `red -> green:` line for each new test, the anchor list
from step 1, and the final counts of both files.

## Progress

- **T1 done**, `064da4c`, merged into the change branch. `tests/find-items.bats` 51 of 51 ok and `tests/portability.bats` 13 of 13 ok.
  - red -> green: "find-items: list --kind ADR prints an ADR defined in docs/adr": exit 0 with empty output, failing the exact-output assertion -> ok
  - red -> green: "find-items: show prints an ADR block and ends it at the heading": exit 1, `NOT-FOUND ADR-x7k2m9` -> ok
  - red -> green: "find-items: list in a multi-unit repository reads the ADRs of the unit that GR_CONFIG names": exit 0 with empty output, failing the exact-output assertion -> ok
  - unable to go red: "find-items: show does not read an item line in a docs/adr file that is not named ADR-*.md", a guard that passes before the fix too.
  - Mutation anchors: none in `docs/verification/2026-10-04-find-items.mutations/` quotes a changed line.
  - Departure: neither fixture config declares `ADR`, so the tests add it with a `declare_adr_prefix` helper. The ADR glob quotes the unit prefix.
- **Deslop** run at `8e3b052`, committed `a958a3b`. It rewrapped the `list` header paragraph, trimmed the ADR loop comment (now naming `gr_unit_engage` and why the unit prefix is quoted), and removed a `!= *ADR-q3w8e4*` assertion that the exact-output assertion before it already covers. Considered and kept: the `declare_adr_prefix` check that the substitution matched, the `write_adr_fixture` helper, the inline unit fixture files, and the two comment sentences that say why the path is fixed and why `[ -f ]` is there.
- **Review round 1** at `82d158c`: ACCEPT with conditions; findings 1 and 2 medium, so a round 2 follows. Fixes: finding 2 in `d8b4242`; findings 1, 3 and 4 in `9d39324`; finding 5 and the D1 amendment in `d6f2839`.
  - red -> green: "find-items: list in a multi-unit repository reads the root ADRs and those of the unit that GR_CONFIG names": printed only the apps/pump line -> ok
  - red -> green: "find-items: the ADR files are not read when id_prefixes does not declare ADR": `list` printed `REQ-002 - docs/adr/ADR-p8w3n5-x.md:1` -> ok
  - unable to go red: "find-items: a directory whose name matches docs/adr/ADR-*.md is not read". BWK awk reads a directory operand silently, so the test passes with `[ -e ]` in place of `[ -f ]` on this host.
- **Review round 2** at `8170b8d`: ACCEPT with conditions; finding 6 medium, so a round 3 follows. Fixes: findings 6, 7, 8 and the header half of 9 in `cd479d9`; findings 9 (item), 10 and 11 in `b4f43c0`.
  - red -> green: "find-items: list with ADR declared and no docs/adr directory prints the other items and no error": with `[ -f ] || continue` deleted, awk fails on the literal `docs/adr/ADR-*.md` -> ok
  - red -> green: "find-items: list in a multi-unit repository with ADR declared and no docs/adr directory prints the unit's items and no error": same mutation, same failure -> ok
  - red -> green: "find-items: the ADR files are not read when id_prefixes declares a prefix that contains ADR but not ADR": with `(*ADR*)` or `(*'ADR|'*)`, `list` printed `REQ-002` -> ok
  - The directory test no longer needs `bats_require_minimum_version` or `run --separate-stderr`; it redirects stderr to a file. It stays unable to go red on BWK awk.
- **Review round 3** at `83361f5`: ACCEPT, every finding low; under the low-severity rule it is the last round. Fixes: findings 12 and 13 in `ab4b7da`, finding 14 in `16f4c25`; finding 15 is record-only.
  - red -> green: "find-items: the ADR files are not read when id_prefixes declares a prefix that begins with ADR but is not ADR": with `(*'|ADR'*)`, `list` printed `REQ-002` -> ok
  - red -> green: "find-items: a docs/adr file named ADR-* that does not end in .md is not read": with the glob `ADR-*`, `list` printed a second line from `ADR-x7k2m9-old.md.orig` -> ok
