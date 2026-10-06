# Verification — find-items-adr (2026-10-05)

branch: find-items-adr
reviewer: three rounds, each a fresh subagent with the diff, the plan, the problem item, AGENTS.md and the ADR decisions, and no implementation narrative
verdict: round 3 ACCEPT on three low findings and one record-only finding, all disposed; under the low-severity convergence rule (ruled by the user 2026-10-04) it is the last review round. Rounds 1 and 2 were ACCEPT with conditions on medium findings, all fixed.
reproduced: on a scratch copy of `main` at `17a0d58`, `find-items.sh list --kind ADR` printed nothing and exited 0, and `show ADR-y8jmes` printed `NOT-FOUND ADR-y8jmes` and exited 1, while `docs/adr/ADR-y8jmes-local-main-is-the-base.md` opens with `**ADR-y8jmes**:`; reproduced again by the round 1 and round 2 reviewers. On the change, `list --kind ADR` prints the five ADRs and `show ADR-y8jmes` prints its block.

Change: when `id_prefixes` declares `ADR`, `find-items.sh list` and `show` read `docs/adr/ADR-*.md` beside the `doc_*` files, and under a unit `GR_CONFIG` also `<unit>/docs/adr/ADR-*.md`, the two places `check-units.sh` resolves an ADR cited by ID. The header and the README state it, and that an ADR's `Status:` line is not a `status:` line, so `--status` keeps no ADR. Resolves `PR-ka8w9m`. Branched from `main` at `17a0d58` while another session's change, `step-8-trusts-finish-merge`, was open, against AGENTS.md non-negotiable 4; the two share no file. Base merged from local `main` at `17a0d58` before each gate until the last (`Already up to date` each time), and at `ffc6839` (`step-8-trusts-finish-merge`, six files, none shared, no conflict) before the final gate, per AGENTS.md non-negotiable 5.
Plan: `docs/plans/2026-10-05-find-items-adr.md`.

## The gate

Guardrails has no `.guardrails/config.yaml`. `check-ids.sh` and
`check-trace.sh` were run against scratch copies of `main` at `ffc6839` and
of the change at `83a27a1`, built by the recipe in
`docs/verification/2026-10-03-accept-2scmvn.md`. Both are red on `main`
already, so the criterion is no finding on the change that `main` lacks
beyond those the plan states.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh`, final | `1..1069`: 1069 ok, 0 not ok, 0 skipped, no `bats warning:` line, exit 0, on `83a27a1`, tree `c49042e8e6d08660833639696e2b6227713131e3`, 14:13:36 to 14:43:51 CEST 2026-10-06, clean before and after |
| `sh tests/run-tests.sh`, round 3 tree | `1..1064`: 1064 ok, 0 not ok, on `83361f5`, tree `fd1bb496`; the reviewer's run on the same commit gave the same |
| `sh tests/run-tests.sh`, round 2 tree | `1..1061`: 1061 ok, 0 not ok, on `8170b8d`, tree `c6544a8d`; the reviewer's run gave the same |
| `sh tests/run-tests.sh`, round 1 tree | `1..1059`: 1059 ok, 0 not ok, on `d8b4242`; the reviewer's run on `82d158c` gave the same |
| `sh tests/evidence.sh main` | exit 0 on `83a27a1`, 14:43:59 to 15:16:26 CEST; output below |
| `check-ids.sh` | exit 1 on `main` and on the change, 79 lines each, byte-identical |
| `check-trace.sh` | exit 1 on both; 148 lines on `main`, 152 on the change. The difference is the one the plan states: four `DANGLING-REF` lines for the fixture IDs `ADR-h7c4t6`, `ADR-p8w3n5`, `ADR-q3w8e4` and `ADR-r9e5u2`; `checked:` `ADR 5` to `ADR 6` (the column-one fixture line `**ADR-x7k2m9**:` in `tests/find-items.bats`) and `PR 70` to `PR 71`; `sources:` `problems 24` to `problems 25`. `PR-ka8w9m` is resolved, so no `UNRESOLVED-PR` line and no change to the open count |
| `check-review.sh` | run on the commit that adds this record (merge-change step 6c); its result is reported with the hand-over |
| Coverage | not configured; the toolkit is unclassified |
| Working tree | clean before and after every run |

A run on `6424762` was killed at the two-hour background limit after the
machine slept, at 765 of 1066 with no failure, and gives no verdict. The
final run follows the merge of `ffc6839`. This record is committed after it
and changes no file the suite reads.

Output of `sh tests/evidence.sh main` on `83a27a1`, exit 0, verbatim:

    Derived by `tests/evidence.sh main` — do not edit by hand.
    
    - Suite: **1069 tests** (main: 1058); 1038 measured against `main`.
    - New or renamed since `main`: **11**.
    - Of those, **5** go red when run against `main`'s scripts.
    - **6** cannot go red, and none is counted as evidence that a
      defect was fixed:
    
      - `find-items: list in a multi-unit repository with ADR declared and no docs/adr directory prints the unit's items and no error`
      - `find-items: list with ADR declared and no docs/adr directory prints the other items and no error`
      - `find-items: show does not read an item line in a docs/adr file that is not named ADR-*.md`
      - `find-items: the ADR files are not read when id_prefixes declares a prefix that begins with ADR but is not ADR`
      - `find-items: the ADR files are not read when id_prefixes declares a prefix that contains ADR but not ADR`
      - `find-items: the ADR files are not read when id_prefixes does not declare ADR`

The five tests that go red are the ones that need an ADR to be read: `list --kind ADR`, `show` of an ADR, the multi-unit root-and-unit list, the directory test and the `.md.orig` test, each of which expects an ADR line that `main` never prints. The six that cannot go red guard the fix's own failure modes: `main` reads no `docs/adr` file at all, so it already passes a test that an ADR file is *not* read, and one that a missing `docs/adr` raises no error. Their red runs are under mutations of the fix, in the table below, and are not counted as evidence of the repair.

## Red → green

| Item | Test | Watched red, before the fix or under a mutation of it |
| --- | --- | --- |
| PR-ka8w9m | find-items: list --kind ADR prints an ADR defined in docs/adr | exit 0, empty output, before the fix (T1) -> ok |
| PR-ka8w9m | find-items: show prints an ADR block and ends it at the heading | exit 1, `NOT-FOUND ADR-x7k2m9` (T1) -> ok |
| PR-ka8w9m | find-items: show does not read an item line in a docs/adr file that is not named ADR-*.md | with the glob `*.md`, `show ADR-q3w8e4` found the README line (round 2 and 3 reviewers' mutation tables) -> ok |
| PR-ka8w9m | find-items: list in a multi-unit repository reads the root ADRs and those of the unit that GR_CONFIG names | empty output before T1; only the unit's line before the round 1 fix -> ok |
| PR-ka8w9m | find-items: the ADR files are not read when id_prefixes does not declare ADR | `list` printed `REQ-002 - docs/adr/ADR-p8w3n5-x.md:1` before the round 1 fix -> ok |
| PR-ka8w9m | find-items: list with ADR declared and no docs/adr directory prints the other items and no error | with `[ -f ] \|\| continue` deleted, awk fails on the literal `docs/adr/ADR-*.md` -> ok |
| PR-ka8w9m | find-items: list in a multi-unit repository with ADR declared and no docs/adr directory prints the unit's items and no error | the same mutation, the same failure -> ok |
| PR-ka8w9m | find-items: the ADR files are not read when id_prefixes declares a prefix that contains ADR but not ADR | with `(*ADR*)` or `(*'ADR\|'*)`, `list` printed `REQ-002` -> ok |
| PR-ka8w9m | find-items: the ADR files are not read when id_prefixes declares a prefix that begins with ADR but is not ADR | with `(*'\|ADR'*)`, `list` printed `REQ-002` -> ok |
| PR-ka8w9m | find-items: a docs/adr file named ADR-* that does not end in .md is not read | with the glob `ADR-*`, `list` printed a second line from `ADR-x7k2m9-old.md.orig` -> ok |

The directory test, "a directory whose name matches docs/adr/ADR-*.md is
not read", goes red against `main` but cannot catch `[ -e ]` in place of
`[ -f ]` on this host, because BWK awk 20200816 reads a directory operand as
an empty file. Some other awk implementations reject a directory operand, and
none is installed here.

Mutations run by the round 3 reviewer on `83361f5` with
`tests/.bats-core/bin/bats tests/find-items.bats` (56 tests): dropping either
`add_adr_files` call, dropping or loosening the declared-ADR check to
`(*ADR*)` or `(*'ADR|'*)`, deleting the `[ -f ]` line, swapping the call
order, the glob `*.md`, and the unit directory `$GR_UNIT/docs` were each
caught. `(*'|ADR'*)` and the glob `ADR-*` survived (findings 12 and 13) and are
caught after `ab4b7da`. `[ -e ]` for `[ -f ]` survives on BWK awk (finding 15).
These are not kept as `M*.sh` files: no evidence directory for this change was
cut, and the mutations ran on copies.

## Deslop

The pass was run at `8e3b052` and committed `a958a3b`: it rewrapped the
`list` header paragraph, trimmed the ADR loop comment, and removed an
assertion that the exact-output assertion before it already covers.
Considered and kept: the `declare_adr_prefix` check that its substitution
matched, the `write_adr_fixture` helper, the inline unit fixture files, and the
comment sentences that say why the path is fixed and why `[ -f ]` is there.
The review fixes after it were not put through a second pass.

## Findings

**finding-1**: requirement, medium — In a multi-unit repository no `find-items.sh` run can reach an ADR in the root `docs/adr/`: the script read only `${GR_UNIT:+$GR_UNIT/}docs/adr/ADR-*.md`, while `check-units.sh:373` accepts an ADR cited by ID at the root or in the unit. `show` of a root ADR under a unit config printed `NOT-FOUND` and a fix line naming another unit, which no config could satisfy.
disposition: fixed in `9d39324`: under a unit config the root `docs/adr/` is read, then the unit's; the multi-unit test expects both, and not another unit's. Plan D1 amended in `d6f2839`.

**finding-2**: record, medium — `PR-ka8w9m` was still `status: open`, with no resolution, on a branch that contains the fix.
disposition: fixed in `d8b4242` (after the round 1 review's commit `82d158c`): `status: resolved` and a resolution paragraph.

**finding-3**: code, low — The ADR files were read for every prefix even when `ADR` is not declared, so a `**REQ-002**:` line inside an ADR file was listed and shown, with no item behind that behaviour.
disposition: fixed in `9d39324`: the ADR files are read only when `id_prefixes` declares `ADR`, tested by "the ADR files are not read when id_prefixes does not declare ADR".

**finding-4**: code, low — No test covered the `[ -f ]` guard against a directory that matches the glob; `[ -e ]` passed every test.
disposition: fixed in `9d39324` by a test for a directory named `ADR-x7k2m9-dir.md`. It cannot go red on BWK awk, as recorded above and in finding 15.

**finding-5**: record, low — The item's `affects:` named a list rather than a file, and its scratch-config sentence did not run as written because the `doc_*` paths of `templates/config.yaml` do not exist in this repository.
disposition: fixed in `d6f2839`.

**finding-6**: code, medium — No test had `ADR` declared with no `docs/adr` directory, the default for a project made from `templates/config.yaml`; deleting `[ -f "$adr_file" ] || continue` passed every test, and in such a repository made `list` exit 2 with an awk error.
disposition: fixed in `cd479d9` by two tests, single-config and multi-unit, each asserting exit 0, the exact output and an empty stderr; both fail with the line deleted.

**finding-7**: code, low — No test pinned the exact-prefix match; `(*ADR*)` or `(*'ADR|'*)` passed every test, and a config declaring `XADR` would read the ADR files.
disposition: fixed in `cd479d9` by the `XADR` test.

**finding-8**: code, low — The suite's first `bats_require_minimum_version 1.5.0` and `run --separate-stderr` need bats-core 1.7, while `tests/run-tests.sh` prefers a system bats, which can be older.
disposition: fixed in `cd479d9`: both are removed, and a helper redirects stderr to a file under `$BATS_TEST_TMPDIR`, which the suite already uses throughout.

**finding-9**: requirement, low — `list --kind ADR --status accepted` prints nothing, because an ADR has `Status:`, and nothing stated it.
disposition: fixed by stating it, behaviour unchanged: the script header in `cd479d9`, the item in `b4f43c0`, the README in `16f4c25`.

**finding-10**: record, low — The plan said the new fixture IDs add `DANGLING-REF` lines "and nothing else"; the `checked:` and `sources:` counts change too.
disposition: fixed in `b4f43c0`: the plan states the whole difference, which the gate table above measures.

**finding-11**: record, low — T1 in the plan still gave the unit-only rule and glob that the amended D1 replaces.
disposition: fixed in `b4f43c0`: T1 opens with a note that the amended D1 supersedes its unit rule and glob.

**finding-12**: code, low — The declared-ADR check was pinned on its left edge only; `(*'|ADR'*)` passed every test, so a config declaring `ADRX` would read the ADR files.
disposition: fixed in `ab4b7da` by the `ADRX` test, which fails under that mutation.

**finding-13**: code, low — Nothing pinned the `.md` in the glob; `ADR-*` passed every test, so `ADR-x7k2m9-old.md.orig` would be read as a second definition.
disposition: fixed in `ab4b7da` by a test with an `.md.orig` copy beside the ADR, which fails under that mutation.

**finding-14**: record, low — `README.md` still described `list` as reading the `doc_*` files only.
disposition: fixed in `16f4c25`: the `find-items.sh` row names the ADR files, the unit rule, and that `--status` keeps no ADR.

**finding-15**: requirement, low — The directory test is annotated `verifies: PR-ka8w9m` but cannot go red on this host.
disposition: recorded, not fixed: it is listed above as unable to go red, with the reason. A red on BWK awk would need a stub awk that logs its operands.

## Gaps

- The directory test is measured on BWK awk only, where it cannot fail; gawk and mawk are not installed here.
- The round 3 fixes (findings 12 to 14) were not reviewed; under the low-severity rule there is no round 4.
- The review fixes were not put through a second deslop pass.
- An ADR's block in `show` ends at its first heading, so `show` prints the decision line, `Date:` and `Status:`, not the Context and Decision sections; the `==>` line names the file.
