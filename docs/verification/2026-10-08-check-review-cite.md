# Verification — check-review-cite (2026-10-08)

branch: check-review-cite
reviewer: an independent Claude subagent with fresh context each round, given the diff, the plan, AGENTS.md and the review checklist only (merge-change step 6a), at `e8cb69f`, `4a80505`, `087c32a`, `2ca6cd9` and `d00b349`, and a guideline review against `docs/TEST_GUIDELINES.md` (`review-guidelines`) at `087c32a`
verdict: converged at round 5 — nothing above low and no code or requirement finding; the base moved three times after round 2 and brought shared files each time, so rounds 3, 4 and 5 reviewed the whole change, and each low finding is fixed with a test that reddens without it, or answered in the template and this record
reproduced: no problem item is resolved; the change implements roadmap decision D12. Every new test was watched red, before its fix or under a named mutation of the script, and each reviewer reproduced its findings with probes before they were fixed

Change: `check-review.sh --cite`, and `review_cite: on` in the config, fail a disposition that cites no file git lists, no test declared under `test_paths` and no defined item ID, and does not read `no change — <reason>`. Branched from `main` at `e79b823`; base merged from local `main` at `baa983f`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-08-check-review-cite.md`, phase 5 of `docs/plans/2026-10-06-salvage-churn-and-parallel.md`.

## The gate

Measured on: `d00b349` — `git rev-parse HEAD` — tree `a8a8725eac80be567c5ba87dd8ec23be8d85f5cb`, clean worktree, unchanged through the run, `main` at `baa983f`. Step 1's prune changed nothing, and step 3 renamed nothing, so this is the tree that merges, apart from round 5 and this section of this record.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` (whole suite, parallel default) | 1369 of 1369 ok, 0 not ok, 18:48 to 19:57 on 2026-10-13, load average up to 120 from other sessions |
| `check-ids.sh` (scratch copies, base and change, at `baa983f` and `d9412b6`) | exit 1 on both, as on `main`; output identical |
| `check-trace.sh` (scratch copies, base and change, at `baa983f` and `d9412b6`) | exit 1 on both, as on `main`; the change adds `DANGLING-REF PR-b7k2m4` and `DANGLING-REF PR-c8n3p5`, fixture IDs in `tests/check-review.bats`, of the kind `main` already reports 93 times from test fixtures |
| `check-review.sh`, checking off (one scratch tree at `d00b349`, `main`'s scripts against the change's) | for all 58 branches the records declare, identical stdout, stderr and exit status |
| `check-review.sh --cite --branch check-review-cite` (scratch copy) | exit 0; every disposition in this record resolves |
| Coverage | not configured |
| Working tree | clean |

The repository has no `.guardrails/config.yaml`, so the three check scripts ran on scratch copies built with `templates/config.yaml`, and `merge-preflight.sh` was not run, as in `docs/verification/2026-10-08-prune-plans.md`. For the differential the `review_cite:` line was removed, since `main`'s `scripts/lib.sh` rejects the key as unknown.

Earlier runs of the whole suite, on trees the review rounds then changed: 1218 of 1219 on `e8cb69f`, the failure being the `GR_ID_BODY` pin of round 1, finding-1; 1276 of 1276 on `4a80505`; 1286 of 1286 on `ff89e21`; 1342 of 1342 on `087c32a`; 1366 of 1366 on `2ca6cd9`.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| D12 | the `check-review --cite:` tests in `tests/check-review.bats` | T1's failed on the script without `--cite` (`unknown argument: --cite`); each later test failed before its fix, or, where it guards behavior the script already had, under a named mutation of the script (the review dispositions below) |
| D12, C1 | "check-review: without --cite or review_cite an uncited disposition passes and no citations are counted" and "check-review: review_cite: on without the flag checks citations" in `tests/check-review.bats` | the first failed under a mutation that turns checking on by default (round 3); the second failed with `unknown config key(s): review_cite` |
| C1 | "check-review: review_cite: off without the flag does not check citations" and "check-review: review_cite with a value other than on or off exits 2" in `tests/check-review.bats`; "ratchet: the upgrade notes name review_cite, its default and how to opt in" in `tests/skills.bats` | the two script tests failed with `unknown config key(s): review_cite`; the notes test failed with no `review_cite` section |
| C2 | "check-review --cite: under a unit manifest exits 2 naming multi-unit repositories" in `tests/check-review.bats` | failed with `unknown argument: --cite` in place of the multi-unit message |
| D12 | "verification template: a disposition cites a path, a test name or an item ID, or says no change" and "verification template and upgrade notes: a guideline finding cites as a code finding does" in `tests/skills.bats` | each failed on the unedited text: no escape wording; no guideline escape |

## What was wrong, and what was built

A disposition said what was done in words a later reader could not check. D12, from D3 of the churn proposal (`733e6a2`), makes a disposition carry one citation the tree can resolve, or say plainly that nothing changed and why.

`check-review.sh` reads each credited disposition, from `disposition:` to the first blank line, the next block or the next credited disposition. With `--cite`, or `review_cite: on` in `.guardrails/config.yaml`, each must contain one of: a regular file, not a symlink, that `git ls-files --cached --others --exclude-standard` lists, written bare, in backticks, as a markdown link target, with a `:<line>`, `:<a>-<b>` or `#anchor` suffix, or as `<rev>:<path>`; a test whose declared name a span in backticks or double quotes gives exactly, found with `git grep` over the `test_paths` pathspecs (bats `@test`, jest `it`/`test`/`describe`, `def test…`, Go `func Test…` and testify methods, Rust `fn`); or an ID with a declared prefix that `find-items.sh show` resolves. The record being checked counts only for a `record` finding. Otherwise it reads `no change — <reason>`. A disposition that does neither is `UNRESOLVABLE-DISPOSITION <file>:<line>`, exit 1, and the `checked:` line counts the dispositions checked. The key is absent, so `off`, by default; any other value is exit 2. With checking off the output is byte-identical to `main`'s script.

Two choices D12 left open: a key as well as the flag, because an adopter cannot edit `merge-change` step 6c's command; and `--cite` refused with exit 2 in a unit-manifest repository, where the record is repository-level but test paths and ledgers belong to units. `templates/verification.md`, `templates/config.yaml`, `skills/ratchet/references/upgrade-notes.md` and the `README.md` row say what the check does.

Before it shipped, the rule was run over this repository's own records (T3). That run found it too loose — a word in backticks passed when any line of any test file quoted it, and a directory passed as a path — and too narrow, missing possessives, `<rev>:<path>` and test names in double quotes. Both were fixed (`42e37f9`) before the first review.

## The corpus

With `--cite`, on a scratch copy of `c0a071a`, over the 55 branches other records declare: 857 dispositions are checked and 646 are `UNRESOLVABLE-DISPOSITION`; 6 branches exit 0 and 49 exit 1; two of the 49, `monorepo-units-risks` and `units-implementation`, check no disposition and exit 1 on `MALFORMED-FINDING` and `ORPHAN-DISPOSITION` reports alone, which they also get with checking off; none exits 2, and stderr is empty. 3 dispositions pass by the escape, all in `docs/verification/2026-08-30-ratchet-tool-qualification.md`; the `no change needed.` lines in `docs/verification/2026-09-17-restore-mutation-evidence.md` fail. T3's sort of the earlier run's failures gives the shape: no citation at all, about two in five; a commit hash only, about one in three, which is not a citation kind under D12 — a hash made on a change branch does not survive its squash; a decision or finding label only, about one in eight; and three citations that no longer resolve, two renamed tests and one deleted. The records predate the rule, and nothing here asks them to meet it.

## Review

### Round 1

**finding-1**: code, medium — The change fails the required test gate. `cite_id_re="^(${cite_prefix_re})-${GR_ID_BODY}\$"` (scripts/check-review.sh:161) adds a GR_ID_BODY use to a script that tests/check-ids.bats pins at 0 (`body_check_review`). That pin keeps one ID grammar across the scripts. Run alone, `bats tests/check-ids.bats` reproduces the failure. The plan's T1 "Done" figure (216 of 216) covers only check-review.bats, lib.bats and portability.bats, so this was never run. Two fixes: build the ID test from a shared lib.sh helper, or raise the pin with a written reason in the test, as the other pins do.
disposition: the pin `body_check_review` in `tests/check-ids.bats` is 1, with the reason the neighbouring pins give: the ID candidate composes the shared `GR_ID_BODY` rather than pasting the shape. "every gr_def_re call site is still a call site, and no copy joins them" failed on the old pin and passes on the new one.

**finding-2**: code, medium — Test-name resolution handles `test_paths` differently from check-trace.sh. check-trace treats each entry as a git pathspec (check-trace.sh:315-319, "`*_test.sh` matches recursively for git") and scans it with `git grep --untracked`. `cite_names_test` (check-review.sh:589-600) runs `[ -e "$cite_test_path" ] || continue` and then `grep -rhF`, so it silently skips a pathspec entry. Reproduction: set `test_paths: [*_test.go]` and create pkg/x_test.go containing `func TestThing(t *testing.T)`. check-trace.sh accepts it (`tests 1`), but a disposition citing `` `TestThing` `` gets UNRESOLVABLE-DISPOSITION, exit 1, with a message that says no test name in test_paths matched. Plain `grep -r` also walks gitignored trees such as node_modules under a test directory, and `-r`/`-h` are not POSIX grep, which every other test_paths scan avoids by using git grep. Fix: use `git grep -hF --untracked -- $test_paths`.
disposition: test names are searched with one `git grep --untracked` over the `test_paths` entries as pathspecs, as `scripts/check-trace.sh` reads them; a search error is exit 2. "check-review --cite: a test_paths entry is a git pathspec, as check-trace.sh reads it" and "check-review --cite: a test declared only in a gitignored file does not resolve" were red before the fix.

**finding-3**: code, low — Several behaviors the plan states have no test, and the mutations above survive (AGENTS.md: "Add a bats test … for every behavior change to a script"):
- the leading-`/` refusal;
- the `..` refusal;
- the `://` refusal;
- find-items exit 2 → exit 2;
- grep failure → exit 2;
- Go `func Test…`;
- jest `test(` and `describe(`;
- the Done-deviation that a second credited disposition ends the first.

The last one matters most. Without its flush (the mutation above), the first disposition is overwritten and never judged, a silent pass. Probe "second-disp" shows the intended behavior: `citations checked over 2 dispositions`, with the uncited first one reported.
disposition: each named behavior has a test that kills its mutant: "check-review --cite: a second credited disposition in one block is judged on its own", "check-review --cite: find-items.sh failing on an ID candidate exits 2, never resolves or fails it", "check-review --cite: a test_paths search that fails exits 2, never reads as no test", "check-review --cite: a Go func Test resolves an identifier span", "check-review --cite: a jest test() and describe() name resolves", and the absolute-path, `..` and URL tests. The last three now guard the git listing that replaced the path-shape refusals (finding-5).

**finding-4**: code, low — The escape's reason guard is unreachable. `gsub(/[ \t]/, "", rest); if (rest != "")` (check-review.sh:~301) never sees an empty `rest`. `gr_value` trims the trailing space of `no change — `, so the prefix comparison already fails on a bare `no change —`. A whitespace-only continuation line is blank and ends the text before it is appended. Replacing the guard with `if (1)` passes all tests. Either remove it or document it as a guard.
disposition: the guard is removed from `scripts/check-review.sh`, with a comment at the escape saying why an empty reason cannot reach it; "check-review --cite: no change — with no reason after the dash fails" still passes.

**finding-5**: code, low — "A file in the tree" is checked with `[ -f ]` on the working directory, not against git's tree. It therefore resolves:
- untracked and gitignored files, for example anything under `.worktrees/` in a primary checkout;
- symlinks that point outside the repository. Probe: `ln -s /etc/hosts outside.txt`, then `disposition: see outside.txt` passes.

Separately, `.//.git/HEAD` passes the path-shape test, and only a single leading `./` is stripped before the `.git` check. In a primary checkout, where `.git` is a directory, it resolves. Each case needs a contrived citation.
disposition: a path resolves only as a regular file, not a symlink, that `git ls-files --cached --others --exclude-standard` lists, after every leading `./` is dropped; the separate `/`, `..`, `://` and `.git` refusals are gone, since the listing decides each. "check-review --cite: a symlink to a file outside the repository does not resolve", "check-review --cite: a gitignored file does not resolve" and "check-review --cite: .//.git/HEAD does not resolve where .git is a directory" were red before the fix.

**finding-6**: code, low — Two shapes cannot be cited:
- A path containing a space is split into tokens and never resolves (probe: `` `dir with space/y.sh` ``, exit 1).
- An unpaired backtick shifts the pairing of every later span (probe: ``the ` operator, see `the test name` `` fails though the test exists).

The plan states "an unpaired quote opens nothing", which holds only when the stray quote comes after the last span.
disposition: a backtick span is also tried whole as a path; "check-review --cite: a backtick span naming a path with a space resolves" was red before the fix. Pairing is unchanged: CommonMark pairs backticks left to right the same way, so a span is read as the rendered page shows it, and a comment in `scripts/check-review.sh` says so.

**finding-7**: requirement, low — `review_cite` is accepted in a unit's config, because GR_KNOWN_KEYS is shared and gr_check_config validates unit configs. Under a manifest, though, the key is never read: `review_cite: on` in a unit config is silently ignored, with no exit 2 and no notice, while `--cite` is refused loudly. The upgrade note says a manifest repository "cannot use it yet" but does not say the key is ignored there.
disposition: the template, `templates/config.yaml` and `skills/ratchet/references/upgrade-notes.md` say the key is read from the root config only, which a manifest repository does not have, so a unit config's `review_cite: on` is not read and `--cite` exits 2 there.

**finding-8**: code, low — Documentation accuracy:
- The template's field-grammar note (templates/verification.md) says the text runs "to the first blank line or the end of its block". It leaves out the next credited disposition, which also ends it (the T1 deviation).
- templates/config.yaml says "a path in the tree", where the script requires a regular file.
- Two new prose lines run well past the wrap width of the text around them: templates/verification.md, the `def test…`/find-items line, and skills/ratchet/references/upgrade-notes.md:425.
- The skills.bats test "the upgrade notes name review_cite, its default and how to opt in" never checks the default (`off`). Its `verifies:` claim is wider than its assertions.

Otherwise the README row, the upgrade note and the config comment match the script.
disposition: the boundary sentence in `templates/verification.md` names the next credited disposition; `templates/config.yaml` states the file rule; the long lines are rewrapped; "ratchet: the upgrade notes name review_cite, its default and how to opt in" now asserts that an absent key is `off`, and failed with that sentence removed.

**finding-9**: record — The plan's "Corpus fixes" paragraph gives only the figure from before the fix (530 of 808 failing). On this tree, with templates/config.yaml as config, the fixed rule fails 610 of 808. The record's Gaps should state the post-fix figure. The most common citation form in this repository's dispositions, a commit SHA such as `e0e38c1` or `b4f43c0`, is not a citation kind under D12. The record should say so, since it drives much of the failure rate.
disposition: the record's Gaps give the corpus figures measured on the merging tree and say that a commit hash is not a citation kind under D12, in `docs/verification/2026-10-08-check-review-cite.md`.

### Round 2

**finding-1**: code, low — The block-close boundary of a disposition's text has no test. Mutant `gr_block_closes(line) ||` → `0 ||` at scripts/check-review.sh:381 passes all 51 cite tests. The live code is right: a probe with `disposition: fixed` followed directly by `**finding-2**: … see src/.gitkeep` reports finding-1 unresolvable. In this repo's corpus, 4 dispositions are followed directly by a bold line with no blank line between, so the boundary is used. Fix: add a test where the next finding's header, or a `## ` heading, follows with no blank line and carries a citation, expecting UNRESOLVABLE.
disposition: no script change, the code being right: "check-review --cite: the next finding's header, with no blank line between, ends a disposition's text" and "check-review --cite: a heading, with no blank line between, ends a disposition's text" both fail under the mutant the finding names.

**finding-2**: requirement, low — The record itself always resolves, because it is untracked and not ignored at step 6c. A `code` finding disposed as `fixed, see docs/verification/<this record>.md` passes. The template steers the same pattern for `record` findings (templates/verification.md, finding-2 placeholder). This is "presence, not relevance", which the plan's Gaps accept, but it is a one-token bypass of D12's intent for code and requirement findings. The record should state it explicitly, or the record under check should be excluded as a citation for findings other than `record` findings.
disposition: the record being checked is not a citation for a `code` or `requirement` finding, only for a `record` one; the scan reads the tag from the finding header. "check-review --cite: a code or requirement finding citing only the record being checked fails" was red before the fix; "check-review --cite: a record finding citing the record being checked resolves" and "check-review --cite: a code finding citing another record in docs/verification resolves" guard the two sides. `templates/verification.md` and `skills/ratchet/references/upgrade-notes.md` say so.

**finding-3**: code, low — Some common citation forms fail although they name real files. The rule rejects them, but nothing tells the author which form would pass.
- `[text](src/x.sh)` strips to `text](src/x.sh` and does not resolve.
- `src/x.sh#L12` does not resolve.
- A filename containing `"` or `\` never resolves: `git ls-files` C-quotes it even with `core.quotePath=false`.
- A stray inch mark (`5" wide; "the name"`) shifts quote pairing, so the real test name is never tried. The pairing rule is documented; the other cases are not.
- Testify suite methods (`func (s *S) TestX(`) are not recognised.
- Conversely, a comment line `# def test_x` counts as a declaration.

No case in this repo's corpus uses links or anchors. Either name the accepted forms in the template, or strip `[..](` and `#…`.
disposition: a markdown link yields its target, a `#anchor` after a path is dropped, a commented-out declaration declares nothing, and a testify suite method declares its test: "check-review --cite: a markdown link names its target path", "check-review --cite: a #anchor suffix is stripped from a path", "check-review --cite: a commented-out declaration declares no test" and "check-review --cite: a Go testify suite method declares its test" were each red before the fix. The template names the accepted forms. Unchanged: a file name git C-quotes, and a stray double quote shifting the pairing, which the template states.

**finding-4**: code, low — The "no `id_prefixes`, no token is an ID" branch cannot be reached. lib.sh exits 2 with `id_prefixes not configured` before check-review.sh runs, with or without `--cite` (probe p5b). The guarded code at scripts/check-review.sh:161–164 and the plan sentence describing it state a behavior no input can produce. It is harmless; the plan sentence should say so.
disposition: the unreachable branch is removed from `scripts/check-review.sh`, and `docs/plans/2026-10-08-check-review-cite.md` says the config check requires `id_prefixes`. A refactor; the existing ID tests pass unchanged.

**finding-5**: record — The plan says "After the base merge … Write docs/verification/2026-10-08-check-review-cite.md". It is not in the tree at 4a80505, so the corpus figures (808 checked / 530 failed) and the self-check of this change's own record with `--cite` have not been recorded yet.
disposition: this record, `docs/verification/2026-10-08-check-review-cite.md`, gives the corpus figures and the result of checking itself with `--cite`.

### Round 3

The base merge of `1967dc8` brought files this change shares, so this round reviewed the whole change.

**finding-1**: requirement, medium — The change has no guideline review, which main now requires.
- Main's checklist, skills/merge-change/references/review-checklist.md (last bullet of the test checklist), says: "the plan lists a guideline review for each file `guidelines-file.sh TEST` prints for the diff … and so does the record's `## Guideline reviews`".
- `sh scripts/guidelines-file.sh TEST tests/check-review.bats scripts/check-review.sh` prints `docs/TEST_GUIDELINES.md: tests/check-review.bats scripts/check-review.sh`.
- Neither docs/plans/2026-10-08-check-review-cite.md nor docs/verification/2026-10-08-check-review-cite.md has a guideline review or a `## Guideline reviews` section.
- Before the record is finalized, a `review-guidelines` dispatch against docs/TEST_GUIDELINES.md is needed. finding-3 is one result it would produce, under Mutants clause 1.
disposition: the guideline review against `docs/TEST_GUIDELINES.md` ran on `087c32a`; its findings and their dispositions are under `## Guideline reviews` in this record, and in `docs/plans/2026-10-08-check-review-cite.md`.

**finding-2**: code, medium — The merged template and the cite check disagree about guideline findings.
- Main's `## Guideline reviews` placeholder (templates/verification.md:125-128) reads `disposition: <what changed on the change branch, or why the clause does not apply here>`.
- check-review.sh credits those `**finding-N**: guideline, …` blocks, so `--cite` checks them too.
- Probe P3: a guideline finding answered "the clause does not apply here; the test runs the script." gives `UNRESOLVABLE-DISPOSITION …:15`, exit 1. An adopter with `review_cite: on` who follows the template literally fails at step 6c.
- This change's cite paragraph in the field grammar (templates/verification.md, the paragraph that begins "With `--cite`") and the upgrade note (skills/ratchet/references/upgrade-notes.md, the `review_cite` section) name only `record`, `code` and `requirement`, never `guideline`.
- Fix: steer the guideline placeholder to a citation or `no change — <reason>`, and name `guideline` alongside `code` and `requirement` in both texts.
- The other merged files are coherent: README row, upgrade-notes order, check-ids.bats pins (`body_check_review=1` next to main's new `*_guidelines_file` pins, with 14 scripts) and skills.bats. Each side's text is kept and nothing contradicts.
disposition: the guideline placeholder in `templates/verification.md` asks for what changed, cited, or `no change — <why the clause does not apply here>`, and the cite paragraph and `skills/ratchet/references/upgrade-notes.md` name `guideline` with `code` and `requirement`. "verification template and upgrade notes: a guideline finding cites as a code finding does" was red before the edit; "check-review --cite: a guideline finding citing only the record being checked fails" fails under a mutant that exempts the `guideline` tag.

**finding-3**: code, low — Four mutants survive their targeted tests, which docs/TEST_GUIDELINES.md "Mutants" 1 treats as a missing test at the seam.
- **M-abs:** in `cite_names_file`, the line `(/*) [ "$cite_path" != "$1" ] || break` is replaced with `(/*)`, which strips the slash from an absolute path. The tests "absolute path" and "led by ./" give 0 of 2 failing.
  - The absolute-path test uses `$BATS_TEST_TMPDIR/outside.txt`, whose stripped form doesn't exist in the repo, so it cannot tell the two apart.
  - Probe P1 shows the current behavior is right (`/scripts/x.sh` with scripts/x.sh present: exit 1). The guard is just unpinned.
- **M-recordstrip:** deleting the `./` strip loop on `cite_record` (check-review.sh, the loop after `cite_record=$f`) gives 0 of 3 failing.
  - The loop is live: with `doc_verification: ./docs/verification`, `$f` starts with `./` (probe P2c).
- **M-wordbound:** dropping the `(^|[^A-Za-z0-9_])…([^A-Za-z0-9_]|$)` boundaries in CITE_TEST_NAME gives 0 of 6 failing.
  - With the mutant, `def test_thing_extra` would resolve `` `test_thing` ``. Probe P5 shows the real code correctly fails it.
- **M-revbounds:** changing `position >= 8 && position <= 41` to `position >= 1` gives 0 of 3 failing.
disposition: four tests, each failing under the mutant the finding names: "check-review --cite: an absolute path does not resolve where the same path relative to the root is a file", "check-review --cite: with doc_verification led by ./ a code finding citing only the record fails", "check-review --cite: def test_thing_extra does not declare test_thing" and "check-review --cite: a hex prefix shorter than 7 or longer than 40 digits is no git rev".

**finding-4**: code, low — The record-self-citation exclusion is bypassed when `doc_verification` has a trailing slash.
- `gr_md_files` then yields `docs/verification//x.md`, and `cite_record` keeps the doubled slash.
- A `code` finding citing only `docs/verification/x.md` therefore passes. Probe P2b: `doc_verification: docs/verification/`, `--cite --branch my-change`, exit 0.
- Without `--branch`, provenance reports STALE-RECORD for the doubled path, which is existing main behavior, so this needs a contrived config.
disposition: repeated slashes in the record path are collapsed before the comparison in `scripts/check-review.sh`; "check-review --cite: with doc_verification ending in / a code finding citing only the record fails" was red before the fix.

**finding-5**: code, low — Rust `fn ` resolves any identifier, so a non-test helper counts as a test name.
- Probe P6: with `fn main() {}` in tests/x.rs, a disposition citing `` `main` `` passes, exit 0. That is the accidental pass on `` `main` `` that T3 removed.
- The plan allows it ("`fn ` before any identifier"), but neither the template nor the record's Gaps says so.
- Either require `#[test]` on the line before, or state it as a gap.
disposition: no change — a line search cannot see a `#[test]` attribute on the line above, so Rust `fn` keeps resolving any function name; `templates/verification.md` and the plan state it, and the Gaps below repeat it.

**finding-6**: code, low — The docs and one test claim less precisely than the script does.
- The template's field-grammar list (templates/verification.md, the cite paragraph) omits Rust `fn` and jest `test(`/`describe(`, though the script accepts all three.
- The skills.bats test "verification template: a disposition cites a path, a test name or an item ID, or says no change" asserts only `no change — <reason>` and `UNRESOLVABLE-DISPOSITION`. It never checks the three citation kinds its name claims.
disposition: the template names every form the script accepts; "verification template: a disposition cites a path, a test name or an item ID, or says no change" now asserts the three kinds and each form, and failed on `it(` before the edit.

**finding-7**: record — Several statements in the record are stale after the base merge.
- "Measured on `ff89e21`" and "base merged from local `main` at `dd411a1`": main is now at 1967dc8, merged by 032de10.
- "1286 of 1286": I saw 1341 of 1342, with one unrelated flake.
- "all 53 branches" and "833 dispositions": there are now 56 branches.
- The verdict says "converged at round 2", but this is round 3.
- The record also lacks `## Guideline reviews` (finding-1).
- The figures in "The corpus" were not re-measured on the merged tree.
disposition: this record, `docs/verification/2026-10-08-check-review-cite.md`, gives the gate, the base merge and the corpus as measured on the merged tree, and its `## Guideline reviews` section.

### Round 4

The base merge of `be9cfa6` brought files this change shares, so this round reviewed the whole change.

**finding-1**: code, low — Nothing pins the scoping of test-name search to `test_paths`.
- Mutant: in `scripts/check-review.sh:638`, `-- $cite_test_paths)` → `-- .)`, so the whole tree is searched.
- Under `bats -f` over the 20 test-name tests, 19 pass. The only failure is "a test_paths search that fails exits 2, never reads as no test", and it fails only because the mutant no longer passes the bogus `:(bogus)tests` pathspec to git grep. That is a different behavior.
- A mutant that adds ` .` after `$cite_test_paths` would keep that test red and survive every test.
- The guard `[ -n "$cite_test_paths" ] || return 1` (no `test_paths` → no span resolves, which the plan states) has no test either.
- The live code is right: a probe with `@test "outside name"` in `scripts/y.bats` and `test_paths: [tests]` gives UNRESOLVABLE, exit 1.
- D12 says "a test name in `test_paths`", and docs/TEST_GUIDELINES.md Mutants 1 treats a survivor as a missing test.
- Fix: one test where a test declared outside `test_paths` (for example `scripts/y.bats`) fails to resolve, and one with no `test_paths` key.
disposition: two tests pin the scope, each failing under the mutation it guards: "check-review --cite: a test declared outside test_paths does not resolve" fails when the search runs over the whole tree, and "check-review --cite: with no test_paths no span resolves as a test name" fails with the guard line deleted. Its config drops `REQ` and `LLR` from `id_prefixes`, since `gr_check_config` in `scripts/lib.sh` requires `test_paths` where either is declared.

**finding-2**: record — The "## Red → green" table (docs/verification/2026-10-08-check-review-cite.md:30-33) no longer matches the annotations.
- Row 2 files "ratchet: the upgrade notes name review_cite, its default and how to opt in" under D12, but since the guideline review's finding-2 that test carries `verifies: C1` (tests/skills.bats).
- No row covers C1 or C2, though four check-review.bats tests and that skills.bats test now verify only C1 or C2.
- The round 3 test "verification template and upgrade notes: a guideline finding cites as a code finding does" is in no row; its red claim appears only in round 3 finding-2's disposition.
- Fix: give C1 and C2 their own rows naming those tests, and add the round 3 template test to the D12 template row.
disposition: the `## Red → green` table in `docs/verification/2026-10-08-check-review-cite.md` gives C1 and C2 their own rows, adds the round 3 template test, and says the default-unchanged test was watched red in round 3.

**finding-3**: record — "two of those on the `MALFORMED-FINDING` and `ORPHAN-DISPOSITION` reports they also get with checking off" (record:47) is ambiguous.
- Four branches get those reports (close-scan-scope, monorepo-units-risks, units-implementation, units-skills).
- Only two exit 1 on them alone, with 0 dispositions checked: monorepo-units-risks and units-implementation.
- The figure is right if it means "exit 1 on those reports alone". The sentence should say so, so a reader re-measuring does not count 4.
disposition: the corpus sentence in `docs/verification/2026-10-08-check-review-cite.md` names the two branches that exit 1 on those reports alone.

### Round 5

The base merge of `baa983f` brought `tests/skills.bats`, which this change shares, so this round reviewed the whole change.

**finding-1**: record — docs/verification/2026-10-08-check-review-cite.md:8 says "base merged from local `main` at `baa983f`". That is stale: the branch now has main at `baa983f`, merged by `b692c2b` (`git merge-base main HEAD` = baa983f). This line is in the record's header, outside the "## The gate" section you said would be updated, so it needs its own update. AGENTS.md non-negotiable 4 requires the sentence to name the current merge commit.
disposition: the header of `docs/verification/2026-10-08-check-review-cite.md` names `baa983f`, the base merged last.

**finding-2**: record — docs/verification/2026-10-08-check-review-cite.md:4, the `reviewer:` field, lists review rounds at `e8cb69f`, `4a80505` and `087c32a` only. It omits round 4, which the record covers at lines 189-214 (dispatched at `2ca6cd9`), and this round at `d00b349`.
disposition: the `reviewer:` field of `docs/verification/2026-10-08-check-review-cite.md` names all five rounds, at `e8cb69f`, `4a80505`, `087c32a`, `2ca6cd9` and `d00b349`.

## Guideline reviews

### docs/TEST_GUIDELINES.md

Governs: README.md docs/plans/2026-10-08-check-review-cite.md docs/verification/2026-10-08-check-review-cite.md scripts/check-review.sh scripts/lib.sh skills/ratchet/references/upgrade-notes.md templates/config.yaml templates/verification.md tests/check-ids.bats tests/check-review.bats tests/skills.bats

### Round 1

**finding-1**: guideline, low — Existing suites 1, "These rules bind the tests a change writes or edits … a change that must edit an existing test that breaks them moves it to the seam instead of repairing it in place" — tests/check-ids.bats:165
The change edits the test "every gr_def_re call site is still a call site, and no copy joins them" (line 109). It changes `body_check_review=0` to `1` and adds a comment, and leaves the test where it was. That test breaks Seams 1, "A test calls only an interface that a REQ or LLR describes": it greps the source of `scripts/` and never runs a script's command line. It also has no `verifies:` line. I rate it low because the edit itself is correct (the count had to move) and no command-line seam can observe a structural rule like this one. Still, the clause binds the edited test and is not met.
disposition: no change — a structural rule over the scripts' source has no
command-line seam to move to, and the edit to `body_check_review` is the count
the rule requires.

**finding-2**: guideline, low — Seams 1, "a test verifies the problem report or the plan decision that states the behavior, at the same seam" — tests/check-review.bats:1244, 1254, 1264, 1296; tests/skills.bats:2398, 2414
Each of these tests carries `verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)`. D12 (lines 89-92 of that plan) states only the `--cite` flag, the kinds of citation, the `no change — <reason>` escape and `UNRESOLVABLE-DISPOSITION`. It does not state the behaviors these tests check:
- the `review_cite` config key with `on`/`off`, absent meaning `off`, and exit 2 on any other value;
- `--cite` refused under a unit manifest;
- the upgrade note and the template wording.

Those are stated in `docs/plans/2026-10-08-check-review-cite.md` ("Two decisions D12 leaves open, taken here", lines 15-27), which has no label a test can cite. So a reader who follows the annotation to D12 does not find the contract these tests pin.
disposition: the plan labels its two decisions C1 and C2, and the tests that
pin only them cite them: "check-review: review_cite: off without the flag does
not check citations", "check-review: review_cite with a value other than on or
off exits 2" and "check-review --cite: under a unit manifest exits 2 naming
multi-unit repositories" in tests/check-review.bats, and "ratchet: the upgrade
notes name review_cite, its default and how to opt in" in tests/skills.bats.
"check-review: review_cite: on without the flag checks citations" and the
no-flag test cite D12 and C1. The template test keeps D12, which states the
citation kinds, the escape and the failure it pins.

## Gaps

- A citation proves presence, not relevance. A disposition passes on a file it only mentions: T3 found ten such passes in the corpus, most on `AGENTS.md`. Telling a mention from the change would need the change set, and the rule does not read it.
- Rust `fn` resolves any function name: a line search cannot see a `#[test]` attribute on the line above.
- `--cite` is refused in a unit-manifest repository, and a unit config's `review_cite: on` is not read: test paths and ledgers belong to units, and resolving across them is a design of its own.
- A file name that git C-quotes, one containing `"` or `\`, never resolves; a stray `"` shifts the pairing of later double-quoted spans, as an unpaired backtick shifts backtick spans.
- This repository has no config, so it does not run the check at `merge-change` step 6c. This record was checked with `check-review.sh --cite` on a scratch copy of the change, where it passes.
- Open and not filed: `check-trace: trailing whitespace on a field is not part of its value` fails when a run crosses local midnight; recorded in `docs/verification/2026-10-07-parallel-changes.md`. It did not affect this change's gate.
