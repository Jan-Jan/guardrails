# Verification — bare-negations (2026-10-13)

branch: bare-negations
reviewer: independent Claude subagents with fresh context, one per round, each given the diff, the plan, AGENTS.md, the review checklist and PR-3kvpze (merge-change step 6a), at `ae58d34`, `0aaa84b` and `dc173d6`; the guideline reviews ran in fresh contexts of their own against this repository's `docs/TEST_GUIDELINES.md`
verdict: converged at round 3 — every code finding low; the mechanical one is fixed (T5), the others are recorded as PR-z7jq9k, and no further reviewer was dispatched
reproduced: yes — at `1967dc8` a prototype scan listed the 15 bare negations, and the plan's investigation identifies the 9 that a following command made dead; the new test was watched red on that tree, listing the same 15, before any was converted. Each converted assertion was shown to bite by breaking what it guards (T1 step 4)

Change: every negative assertion in the bats suite can now fail its test, and `tests/portability.bats` rejects a bare negation and reports a file it cannot scan to the end. Branched from `main` at `1967dc8`; base merged from local `main` at `be9cfa6`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-13-bare-negations.md`.

## The gate

Measured on: `a41c27d` — `git rev-parse HEAD` — tree `0ad6a1cd62cf81ddd75188adff6170a50e3c12cf`, clean worktree, `main` at `be9cfa6`. This tree has step 3's one rename (the draft problems file), every review fix and this record's first version. It differs from the merging tree only by this gate section. `main` moved to `be9cfa6` (`implements-one-reader`) after the squash was first staged, so the squash was withdrawn and step 1 rerun. No `shared:` line was printed: no file of this change was edited by that base.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (parallel) | 1..1297, all ok, exit 0 (16:01–16:18) |
| `check-ids.sh --allow-draft-files` (scratch copies, base and change) | exit 1 on both, with identical output |
| `check-trace.sh` (scratch copies, base and change) | exit 1 on both; differing only by this change's items: PR-3kvpze leaves the open list, PR-z7jq9k enters it |
| Coverage | not configured |
| Working tree | clean |

The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran on scratch copies built from `main` and from the change with `templates/config.yaml` (its `strict_paths` entry set to `scripts`, and one-line placeholder SRS, SAD, RMF and SOUP files so the trace gate runs), and `merge-preflight.sh` was not run, as in `docs/verification/2026-10-08-test-guidelines.md`. PR-z7jq9k was minted with `new-id.sh` under a scratch `GR_CONFIG` declaring `PR` and `ADR`; `finalize-docs.sh` ran under the same config.

Earlier full runs, not counted here: 1280 of 1280 at `a77584b`, before the review rounds changed the tree; 1280 of 1280 at `bea8ad9`, before `main` moved; two later runs were stopped unfinished when a review round's fix was about to change the tree they measured.

## Red → green

This repository has no SRS: the change resolves PR-3kvpze, and every task's test is the one below. The plan's `red -> green:` lines, one per task, are the full list.

| Item | Test | Watched red |
| --- | --- | --- |
| PR-3kvpze | `no test asserts through a bare negation` | T1: on the unconverted tree, listing the 15 statements; T2: "the scan misses the unfailing-braced shape"; T3: "the scan misreports the single-quoted-heredoc shape", and the old scan missed each bad control that could fail; T4: "the scan misreports:" with 14 controls; T5: each new control against the mutant it targets (M1–M3), as controls for behavior the scan already had |

## What was wrong, and what was built

Bash ignores errexit for a command negated with `!`, so a bats assertion written `! grep …` fails its test only as the body's last command. At `1967dc8` the suite had 15 such statements. Nine were dead, each followed by another command: `tests/finalize-docs.bats:215`, `tests/prune-plans.bats:589`, and `tests/skills.bats` 1055, 1371, 1408, 1420–1422 and 2357. Six were live only because each was its test's last line. None of the dead nine matched the tree, so no regression had been hidden.

All 15 now end in `|| { echo "<what matched>"; false; }`. `tests/portability.bats` gains `no test asserts through a bare negation`, an awk scan over `tests/*.bats` and `tests/*.bash` that runs under BWK awk. It reads only code: quoted text, `((…))` and comments are removed first. It skips heredoc bodies, joins continuation lines, and follows a multi-line `|| {` group by brace depth. It accepts a negation that opens a statement only when the statement has exactly one `||` and that list's last command is `false`. It rejects any `!` after `;`, `&`, `&&`, `||`, `then`, `do`, `else` or `{`. It reports a heredoc or group still open at a file's end, so a scan that loses its place fails loudly instead of passing the rest of the file. Calibration controls in both directions pin each rule, and the plan records the mutants each was run against. AGENTS.md "Rules" states the rule and what the scan enforces.

## Review

### Round 1

**finding-1**: code, high — The scan opens a heredoc on any `<<WORD` in a line, including one inside a quoted string or a comment. A heredoc opened that way never closes, so the scan skips everything after it in that file. The change's own control fixture triggers this: line 627 of `tests/portability.bats` is `printf ... 'cat <<-EOF' ...`, so lines 627–718 are never scanned. That is the rest of the new test plus the PR-2scmvn tests. I confirmed this with the real bats test: I appended `@test "probe" { ! grep -q x /dev/null; true; }` (one statement per line) to a copy of portability.bats, and the test still reported `ok`. A comment such as `# stubs are written with cat <<EOF` in any test file has the same effect. The same rule also makes `$((x<<y))` open a heredoc. The gate therefore passes a bare negation that it should fail, and anyone adding a test at the end of portability.bats reaches that state in normal use.
disposition: fixed in bd6fee9 (T3): the scan reads heredoc tags only from code, after quoted text, comments and arithmetic are removed; the single-quoted, double-quoted, comment and arithmetic controls were each red against the old scan.

**finding-2**: requirement, low — The scan only flags a `!` at the start of a statement. It misses `x; ! cmd`, `true && ! cmd`, `if c; then ! cmd; fi`, `for …; do ! cmd; done` and `{ ! cmd; }`. I checked each one under bash `set -e`: errexit ignores the negation in all of them. `( ! cmd )` is the only one that does fail, so the scan is right not to flag it. I grepped `tests/*.bats` and `tests/*.bash` for all of these mid-line forms and found none, so the tree is clean today. But AGENTS.md says "`tests/portability.bats` enforces this" with no qualifier, and neither the plan nor the test comment says these forms are out of scope.
disposition: fixed in bd6fee9 (T3): a `!` after `;`, `&&`, `||`, `then`, `do`, `else` or `{` is flagged, with controls for each; AGENTS.md states the scope.

**finding-3**: code, low — Two further edge cases cause false negatives. (a) A multi-line `|| {` group whose closing `}` shares a line with `false` (e.g. `echo hit; false; }`) is never seen to close. The scan swallows the following lines until the next line that starts with `}`, usually the test's own end, so any negation in between goes unchecked. (b) A file whose last line ends in `\` leaves its held statement unevaluated. Both are contrived, and neither has a control.
disposition: fixed in bd6fee9 (T3): `closed-block` and `trailing-continuation` controls, each red against the old scan.

**finding-4**: record — The plan does not match the diff in two places. T1 step 1 says the tree scan uses "the case test's search-path guard and its partial-checkout skip". Commit 06e7e4d removed both in favour of direct globs, and no task or note in the plan records that. T1 step 6 specifies a `resolution:` line, but the ledger got `Resolved:` (commit 00fd551), and the plan text still says `resolution:`.
disposition: the plan's T1 steps 1 and 6 state what was built and why (68e0626).

**finding-5**: record — The AGENTS.md rule is accurate about the mechanism: errexit ignores a negated command, so it fails a test only as the body's last line, and the two remedies it gives both work. Its "enforces this" claim is broader than the scan delivers; see finding-1 and finding-2.
disposition: AGENTS.md states the scan's scope (bd6fee9, T3).

### Round 2

**finding-1**: code, medium — The test cannot detect a scan that stops at the first heredoc of each file. I mutated `if (trim(line) == heredoc_tag) heredoc_tag = ""` to never close, and `no test asserts through a bare negation` still passes. The good heredoc controls only need to stay silent, which they do. No bad control puts a bare `!` after a closed heredoc. The tree scan then comes back empty because everything after each file's first heredoc goes unread. This is the same class as round 1's high finding-1, and nothing in the test guards it. The plan's T3 probe (a negation appended at the end of a file) was manual and is not in the test.
disposition: fixed in 7aeae4c (T4): bad controls put a bare negation after closed `<<'EOF'`, `<<-EOF` and spaced heredocs; the scan reports a heredoc or group still open at a file's end, with controls for both; the never-close mutant is among those killed.

**finding-2**: code, low — Some false negatives remain, all in rare shapes; I confirmed each with a probe file under BWK awk. Each of these opens a heredoc or group that never closes, so the rest of the file goes unscanned and nothing is reported: `"$(echo "a <<EOF")"`; `$'it\'s <<EOF'`; a multi-line single-quoted string whose inner line contains `<<EOF`; the arithmetic command `(( x << y ))`; `<<'END-X'`, whose tag is read as `END`; a multi-line `|| {` group closed by `} >&2`; a comment ending in `\`, joined to the next line, which then disappears as comment. The scan also accepts these shapes, which check nothing: a multi-line `|| {` group whose body contains a one-line `... || { echo; false; }`, closed early, so a group ending `echo hit` passes; `! grep -q a f || echo hit || false`; `true & ! grep -q z f`; a `! … || {` group left open at end of file, which is silently dropped.
disposition: fixed in 7aeae4c (T4): each shape has a control. The tag is read to a blank, quote or operator; `((…))` is removed; continuation is decided on code; groups close by brace depth; a negation needs exactly one `||`; `&` is a separator. The first three shapes are now reported loudly as unclosed.

**finding-3**: code, low — Several rules can be removed without the test failing: `\` escape handling in `code_of`; the `#`-is-a-comment-only-after-`[ \t;&|(]` precondition; `<<<` handling, which is dead code; opening a heredoc from inside a multi-line group; the `FNR == 1` flush of a held continuation; the `FNR == 1` resets of `heredoc_tag` and `group_line`; the literal-`false` requirement, since no control uses `|| true` or `{ …; true; }`.
disposition: fixed in 7aeae4c (T4): the dead `<<<` branch is deleted, and controls kill each other rule; 45 one-rule mutants of the scan, all killed.

**finding-4**: record — The plan has no formal guideline-review entry. `guidelines-file.sh TEST` names `docs/TEST_GUIDELINES.md` for 7 diff files. The plan mentions the guideline review only in T2's preamble, as the one finding that T2 dispositions. It does not record the review's scope or rounds, or whether it was re-run after T3's rework. No verification record exists yet that could carry `## Guideline reviews`.
disposition: the plan's `## Guideline reviews` records round 1 (b209373), and the second guideline review ran after T4; both are below.

**finding-5**: record — The AGENTS.md bullet says "End it in an `||` list that fails", but the scan accepts only a list whose last command is literally `false`. So `|| { echo …; exit 1; }` or `|| return 1` fails the test yet is rejected. The bullet's examples do use `false`, so the tree is right.
disposition: AGENTS.md says the list's only `||` must end in `false` (7aeae4c, T4).

### Round 3

**finding-1**: code, low — Some shapes still let a bare negation through silently, each checked under `/bin/bash -e` (3.2.57): a `!` after a case-arm pattern, `(a) ! grep -q x f ;;`; a `!` opening a one-line subshell that runs another command after it, `( ! grep -q x f; echo hi )`; `time ! grep -q x f`; an escaped backslash at the end of a line (`printf a \\`), read as a continuation, so a bare `! grep` on the next line is missed. All of these are rare shapes for a bats assertion. Nothing in the real tree uses them.
disposition: recorded as PR-z7jq9k: each changes what the scan accepts, which is not a mechanical fix.

**finding-2**: code, low — The scan rejects some legitimate shapes, each reported loudly with its cause: `!` inside a test expression after `&&` or `||`, as in `[[ -f a && ! -f b ]]`; a compliant list broken across lines as `! grep -q x f ||` with `false` on the next line; the one-line helper `refute() { ! grep -q "$1" "$2"; }`, which works because errexit applies to the caller. None of these appears in the tree today. The AGENTS.md bullet does describe the `&&`/`||` rule literally, so the bullet itself is accurate.
disposition: recorded as PR-z7jq9k, for the same reason.

**finding-3**: code, low — 44 one-rule mutants of the awk scan; 41 killed and 3 survived: a single quote never closed on its line, treated as an ordinary character instead of ending the line's code; two heredocs on one line, with the `opened_tag == ""` guard dropped so the last tag wins (no control covers `cat <<A <<B`); the multi-line group's last-command check loosened to `code !~ /false/`, so a group ending in `echo false` would be accepted.
disposition: fixed in e760b6c (T5): controls `open-quote`, `two-heredocs` and `block-echo-false`, each red against its mutant and green against the scan, which is unchanged.

**finding-4**: record — The plan's `## Guideline reviews` says "Round 2 runs after T4, over the whole change diff" but records no outcome and no dispositions. The review checklist requires each guideline review with every finding and its disposition.
disposition: the plan records the second guideline review's outcome and notes (453affc); this record carries both reviews below.

## Guideline reviews

### `docs/TEST_GUIDELINES.md`

Governs: `tests/portability.bats`, `tests/skills.bats`, `tests/prune-plans.bats` and `tests/finalize-docs.bats`; `guidelines-file.sh TEST` printed this one file for them.

### Round 1

Ran after T1 and the deslop pass, at `00fd551`. No findings. Its note that the scan accepted `! grep -q x f || { echo hit; }`, which still checks nothing, became T2.

### Round 2

Ran after T4, at `dc173d6`, over the whole change diff. No findings. Notes, not findings: each repaired assertion sits in a test already at its seam, so Existing suites 1 allows repairing it in place; the lint test runs no script, which Seams 1 does not address; a property test would be possible but is only preferred (Property tests 1); whether the new test was watched red is the record's to show (above).

## Gaps

- The scan was run under BWK awk only. gawk, mawk and busybox awk are not installed on this host, so the scan has not been run under them. It uses no gawk extension and passes nothing through `-v`.
- Open: PR-z7jq9k. Some shapes still get through silently: a negation in a `case` arm, inside a subshell followed by another command, after `time`, or after a line ending in an escaped backslash. Some compliant shapes are rejected: `[[ … && ! … ]]`, a `||` with `false` on the next line, and a one-line `refute()` helper. None is in the tree. A line scan of shell removes these one shape at a time.
- The T5 fix ran after the last review round, so no reviewer has read it. It adds three controls and leaves the scan unchanged.
- Bare `[[ … ]]` assertions mid-test have the same weakness under bash 3.2, as the comments in `tests/mutations.bats` and `tests/remedies.bats` note. This change neither scans for them nor counts them.
