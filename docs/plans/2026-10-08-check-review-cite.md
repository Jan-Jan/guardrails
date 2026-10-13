# Phase 5: a disposition cites what it changed

**Goal:** `check-review.sh --cite`, opt-in, fails a disposition that cites
nothing the tree can resolve and does not say `no change — <reason>`.
**Implements:** D12 of `docs/plans/2026-10-06-salvage-churn-and-parallel.md`
(D3 of the churn proposal, `733e6a2`). No problem item is resolved or opened.
Each test cites `verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)`
for the citation rule, or C1 or C2 below,
`(docs/plans/2026-10-08-check-review-cite.md)`, for the key and the
manifest refusal, or both where it pins both.
**Safety class:** this repository has no `.guardrails/config.yaml`; the
toolkit itself is unclassed.
**Verification:** `tests/run-tests.sh`, every test passing; `check-ids.sh`,
`check-trace.sh` and `check-review.sh` on scratch copies, as in phase 4.
**Base:** `main` at `e79b823`. Baseline: phase 4's gate, 1183 of 1183 on tree
`2cc5fc3`.

## Two decisions D12 leaves open, taken here

**C1 — Opt-in is a key as well as a flag.** D12 names the flag. An adopter
cannot edit the shipped `merge-change` step 6c command, so a flag alone could
be turned on only for one run. `review_cite` in `.guardrails/config.yaml`,
`on` or `off`, absent meaning `off`, turns it on for every run; `--cite`
turns it on for one. Any other value exits 2, as `prune_plans` does.
`merge-change`'s `SKILL.md` is unchanged: step 6c's command picks up the key.

**C2 — A unit manifest refuses `--cite`.** In a multi-unit repository the
record is repository-level, while test paths and ID ledgers belong to units.
Resolving across units is a design of its own. `--cite` there exits 2 and
says so, and no root config exists to hold the key. The record's Gaps state
this.

## The behavior

- **Which dispositions.** Only those check-review already credits: a
  `disposition:` at column one with a non-empty value, inside a finding block,
  in a record for the change under check. An orphan or a bulleted disposition
  is already reported, or credits nothing, and is not cite-checked.
- **A disposition's text** is its line from after `disposition:` through the
  following lines, up to and not including the first blank line (spaces and
  tabs only), the first line that closes the block (`gr_block_closes`: the
  next finding's header or a heading, with or without a blank line before
  it), the next credited disposition (judged on its own), or the end of the
  file. 221 of this repository's 821 dispositions wrap.
- **The escape.** A disposition whose text opens with `no change — ` (em
  dash, U+2014, spaces around it) needs no citation. A non-space always
  follows: `gr_value` trims the space after a bare `no change —`, and a line
  of spaces ends the text unappended. `no change needed.` is not
  the escape: D12 fixes the wording, as `reproduced: no — <why>` is fixed.
- **A citation** is any one of:
  1. *A file in the tree.* Split the text on spaces and tabs. A token holding
     `](`, a markdown link, keeps only what follows it. Strip from each
     token's start any of `` ` `` `"` `'` `(` `[` `<`, from its end any of
     `` ` `` `"` `'` `)` `]` `>` `.` `,` `;` `:` `!` `?`, then a `#anchor`
     suffix where what precedes the `#` contains `/` or `.` (`x.sh#L3-L9`
     yields `x.sh`; `notes#1.txt` stays whole), then one trailing
     possessive `'s` or `’s` and the end set again, then a git `<rev>:` prefix
     of 7 to 40 lowercase hex digits (`650f090:templates/verification.md`
     yields `templates/verification.md`), then one trailing `:<digits>` or
     `:<digits>-<digits>`, then the end set once more. Each backtick span,
     stripped the same way as a whole, is a candidate too, so
     `` `dir with space/y.sh` `` can be cited. A candidate containing `/` or
     `.` is a path candidate. Every leading `./` is dropped, with any slashes
     repeated after it (`.//.git/HEAD` reads as `.git/HEAD`); a doubled
     slash inside the path is kept. It resolves if it is a regular file and
     not a symlink (`[ -f ] && [ ! -h ]`), and
     `git ls-files --cached --others --exclude-standard`, read once per run,
     lists it: tracked, or untracked and not ignored. The record being
     checked, often untracked at step 6c, resolves only for a `record`
     finding: the tag is the first word after `**finding-N**:` and its
     spaces, compared byte-wise with `record`, and the scan passes it on the
     `D` fact. A `code`, `requirement` or `guideline` finding citing only
     the record fails. The record's own path is compared with repeated
     slashes collapsed and every leading `./` dropped, so a
     `doc_verification` led by `./` or ending in `/` still names it. A
     directory, a symlink out of the repository, a gitignored file, a
     tracked file deleted from the working tree, an absolute path, a `..`
     path, a URL and anything under `.git` never resolve.
  2. *A test name in `test_paths`.* Each backtick span and each span between
     paired straight double quotes in the text, tried as a test name (a
     backtick span is also a path candidate, above). Quotes pair left to
     right, as CommonMark pairs backticks, so a span is a span on the
     rendered page; an unpaired last quote opens nothing. Each `test_paths`
     entry is a git pathspec, searched as check-trace.sh searches it, with
     `git grep -hI --untracked -F`: `*_test.go` matches recursively, a
     gitignored file is not searched, and a git grep exit above 1 is exit 2.
     The span resolves only where a matched file DECLARES a test of
     that whole name: a line `@test "<span>"` after optional indentation
     (bats); a line whose first call is `it(`, `test(` or `describe(` with the
     span as its whole first argument in single or double quotes (jest); or,
     for an identifier span, `def ` or `func ` before it as a whole word when
     it begins `test` or `Test`, as Go's `func (<receiver>) ` does for a
     testify suite method, and `fn ` before any identifier. A line that
     merely quotes the span, a shell helper (`name() {`, `function name`),
     and a line whose first non-space characters are `#` or `//`, declares
     no test. Rust `fn` accepts any function name: a line grep cannot see
     the `#[test]` attribute on the line before, so a helper `fn main` is a
     test name to this rule, and the template's accepted-forms list says so.
     With no `test_paths`, no span resolves this way.
  3. *An item ID that resolves.* A stripped token matching
     `^(<id_prefixes>)-<GR_ID_BODY>$`. It resolves if
     `find-items.sh show <ID>` exits 0; exit 1 is unresolved; exit 2 is exit 2.
     `id_prefixes` is always set here: `gr_check_config` exits 2 without it,
     before citations are read.
- **The failure.** A disposition with no resolving citation and no escape is
  `UNRESOLVABLE-DISPOSITION <file>:<line> (cites no path in the tree, test name
  in test_paths or defined item ID, and is not "no change — <reason>")`, where
  `<line>` is the `disposition:` line, and the exit is 1.
- **The summary.** With citation checking on, the `checked:` line gains
  `; citations checked over <N> dispositions`. Off, every output is
  byte-identical to `main`'s script: that is the differential T3 runs.
- **Usage.** `--cite` may come before or after `--branch NAME`. An unknown
  argument stays exit 2.

## Tasks

| Task | Files touched | Depends on |
| --- | --- | --- |
| T1 | `scripts/check-review.sh`, `scripts/lib.sh`, `templates/config.yaml`, `tests/check-review.bats` | — |
| T2 | `templates/verification.md`, `skills/ratchet/references/upgrade-notes.md`, `README.md`, `tests/skills.bats` | — |
| T3 | none committed; evidence for the record | T1 |

### T1 — `--cite` and `review_cite` in `check-review.sh`

**Files touched:** `scripts/check-review.sh`, `scripts/lib.sh`,
`templates/config.yaml`, `tests/check-review.bats`
**Parallel:** yes (with T2)

1. Write the failing tests in `tests/check-review.bats`, each annotated
   `# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)`.
   Each builds a record with `write_record` plus a `## Review` section holding
   one `**finding-1**: code, low — x` block, and runs with `--cite` unless the
   name says otherwise:
   - a disposition citing an existing path (`scripts/x.sh`, created in the
     fixture) passes; the same path with `:12` and with `:3-9` passes;
   - a disposition citing a path that does not exist fails with
     `UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:<line>`;
   - a disposition naming a bats test as `` `the test name` `` passes when
     `tests/x.bats` holds `@test "the test name" {`, and fails when it does
     not; a `def test_thing` in `tests/test_x.py` resolves `` `test_thing` ``;
   - a disposition citing a defined `PR-` ID passes; a well-formed undefined
     one fails;
   - `disposition: no change — the reviewer misread the call site` passes;
     `disposition: no change needed.` fails; `disposition: no change —` with
     nothing after the dash fails;
   - a citation on the second line of a wrapped disposition counts; one after
     a blank line does not;
   - without `--cite` and without the key, an uncited disposition passes, and
     the `checked:` line has no `citations` field;
   - `review_cite: on` without the flag fails the uncited disposition;
     `review_cite: off` with no flag passes it; `review_cite: yes` exits 2
     naming the key and the value;
   - with `--cite`, the `checked:` line ends
     `citations checked over 1 dispositions`;
   - `--cite --branch my-change` and `--branch my-change --cite` both check;
   - under a unit manifest, `--cite` exits 2 with a message naming
     multi-unit repositories.
   Run `bats tests/check-review.bats` and watch each new test fail.
2. Add `review_cite` to `GR_KNOWN_KEYS` in `scripts/lib.sh`, next to
   `prune_plans`, and to `templates/config.yaml` after `prune_plans`, as
   `review_cite: off` with a comment stating the rule above in two or three
   lines. `tests/lib.bats` checks the two lists agree.
3. In `scripts/check-review.sh`: parse `--cite`; read the key with `cfg_get`
   only when `^review_cite:` is in `$GR_CONFIG`, as `prune-plans.sh` does;
   refuse `--cite` under `gr_units_present`. Extend `GR_RECORD_SCAN` to print,
   for each credited disposition, `D <line>`, `X` when it is the escape, and
   one `C <token>` per path or ID candidate and one `S <span>` per backtick
   span, all byte-wise (`LC_ALL=C`, `substr`/`index`, no negated bracket
   expressions over non-ASCII). Resolve in the shell. Pass the scan no `-v`
   value containing a newline. Update the header comment's failure list.
   Without citation checking, the scan's extra lines are ignored and the
   output is unchanged.
4. Run `bats tests/check-review.bats tests/lib.bats tests/portability.bats`:
   all pass. Commit.


**Done** (`3ba4a1c`, merged `cc9fbfa`): 20 tests, 216 of 216 across the three
files under BWK awk. Deviations: the escape is matched on the disposition's
whole text, since `gr_value` trims the trailing space a wrapped
`no change —` line ends with; a second credited disposition ends the first's
text; the citation facts are printed only with checking on; a `grep` failure
over `test_paths` exits 2; ID candidates are found in awk from
`-v cite_id_re`; the new disposition rule is written so that no mutation
anchor in `docs/verification/*.mutations/` changes whether it matches.

### T2 — the template, the upgrade note, the README row

**Files touched:** `templates/verification.md`,
`skills/ratchet/references/upgrade-notes.md`, `README.md`, `tests/skills.bats`
**Parallel:** yes (with T1)

1. Write failing tests in `tests/skills.bats`, annotated as in T1:
   - `ratchet: the upgrade notes name review_cite, its default and how to opt
     in`: a `## Dispositions cite what they changed: \`review_cite\`` section
     containing `` `review_cite: on` `` and `--cite`;
   - `verification template: a disposition cites a path, a test name or an
     item ID, or says no change`: `templates/verification.md` contains
     `no change — <reason>` and `UNRESOLVABLE-DISPOSITION`.
   Watch both fail.
2. In `templates/verification.md`, the finding-1 disposition placeholder names
   the three citation kinds and the escape; the `record` placeholder says to
   cite the record's path; the field-grammar comment gains a paragraph on
   `--cite` and `review_cite`. In the upgrade notes, add the section after the
   `prune_plans` one: off by default, how to turn it on, what fails, the
   escape, and that a manifest repository cannot use it yet. In `README.md`,
   the `check-review.sh` row adds "and, opt-in, that each disposition cites
   something the tree resolves".
3. Run `bats tests/skills.bats`: all pass. Commit.

**Done** (`c03669e`, merged `a47cf4f`): 2 tests, 124 of 124 in
`tests/skills.bats`. No deviation.

### T3 — the corpus run and the differential

**Files touched:** none committed. The agent writes its report to the
scratchpad path the dispatch names.
**Parallel:** no (serial, after T1)

1. Build scratch copies of `main` and of the change with
   `scratchpad/gate5/build.sh <commit> <dest>` (they carry
   `templates/config.yaml` as the config, so `test_paths` is `tests` and
   `id_prefixes` is set).
2. For every distinct first `branch:` value among `docs/verification/*.md`,
   run `check-review.sh --branch <value>` in both copies, without `--cite`,
   and compare stdout, stderr and exit status. Expected: no difference.
3. In the change copy, run the same with `--cite` and record, per branch, the
   exit status and the number of `UNRESOLVABLE-DISPOSITION` lines; the total
   of credited dispositions; and a sample of twenty failures with their text,
   sorted into: no citation at all, `no change` without the em dash, a
   citation that no longer resolves (a renamed or deleted path, a test since
   renamed), and anything the rule misreads. Every misread is a defect in T1
   and goes back as a fix dispatch before the gate.
4. Report the figures with the commands that produced them.

**Corpus fixes**: the corpus run checked 808 dispositions and
failed 530. It found the rule too loose: all 32 sampled passes resting on a
short span or a directory were accidental (`` `merge` ``, `` `main` ``,
`` `|` ``, `` `status:` `` quoted somewhere in tests/; `docs/`, `./`,
`.git`). It also found the rule too narrow: 6 tokenization misses (a
possessive `'s` after a path or ID, a git `rev:path`) and 22 bats test names
cited in double quotes. A test-name span now resolves only as a declared
test's whole name, `def`/`func` only for a name beginning `test`, `function`
not at all; a double-quoted span is a test-name candidate; a path resolves
only as a regular file outside `.git`; a possessive and a `<rev>:` prefix are
stripped.

## Review round 1

The review of `e8cb69f` raised nine findings; eight are answered here, in
one fix dispatch on `check-review-cite-r1-fixes`.

- finding-1: `body_check_review` in `tests/check-ids.bats` raised to 1 with
  a reason: the ID test composes `GR_ID_BODY`.
- finding-2: `test_paths` entries are git pathspecs, searched with
  `git grep --untracked`; a pathspec entry resolves and a gitignored file
  does not.
- finding-3: tests added for the `/`, `..` and `://` cases, find-items exit
  2, a git grep failure, Go `func Test`, jest `test(` and `describe(`, and a
  second credited disposition; each guard's mutant is killed.
- finding-4: the unreachable `rest != ""` guard is removed, its reason
  stated at the escape.
- finding-5: a path resolves only as a regular non-symlink file git lists as
  tracked or untracked and not ignored; leading `./` and the slashes after
  it are dropped. The awk refusals of `/`, `..` and `://`, and the `.git`
  check, are removed: the listing decides each of them.
- finding-6: a backtick span is tried as a path; quote pairing is unchanged.
- finding-7: the template, the config comment and the upgrade note say the
  key is read from the root config only, so a manifest repository cannot use
  it.
- finding-8: the text-boundary sentence names the next credited
  disposition, the config comment states the file rule, the long lines are
  rewrapped, and the skills test asserts the default `off`.
- finding-9: a record finding, answered in the record.

## Review round 2

The review of `4a80505` raised five low findings; four are answered here, in
one fix dispatch on `check-review-cite-r2-fixes`.

- finding-1: tests added where the next finding's header and a `## `
  heading follow a disposition with no blank line; the mutant
  `gr_block_closes(line) ||` → `0 ||` is killed by both.
- finding-2: the record being checked resolves only for a `record` finding,
  by the header's first word; a code or requirement finding citing only it
  fails, and another record still resolves.
- finding-3: a markdown link yields its target, a `#anchor` is stripped from
  a path candidate, a commented-out declaration declares nothing, and a
  testify suite method declares its test; the template names the forms. A
  file name git C-quotes and a stray `"` shifting quote pairing stay as
  they are.
- finding-4: the unreachable no-`id_prefixes` branch is removed and the
  sentence above says the config check requires the key.
- finding-5: the record is written after the base merge.

## Review round 3

The review of `087c32a`, after main's `1967dc8` was merged in, raised seven
findings; five are answered here, in one fix dispatch on
`check-review-cite-r3-fixes`.

- finding-1: the guideline review is done and listed below under
  `## Guideline reviews`; the record gains its section when it is written.
- finding-2: the template's guideline disposition placeholder asks for what
  changed, cited, or `no change — <why the clause does not apply here>`; the
  template's `--cite` paragraph and the upgrade note name `guideline` beside
  `code` and `requirement` as findings the record itself does not answer. A
  test pins that a guideline finding citing only the record fails.
- finding-3: four tests kill the four surviving mutants: an absolute
  `/scripts/x.sh` where `scripts/x.sh` exists, a `doc_verification` led by
  `./`, `def test_thing_extra` against `test_thing`, and hex prefixes of 3,
  4, 6 and 41 digits before a path.
- finding-4: the record's path is compared with repeated slashes collapsed,
  so a `doc_verification` ending in `/` no longer lets a code finding cite
  the record.
- finding-5: Rust `fn` keeps accepting any function name; the plan's
  behavior and the template's accepted-forms list say so.
- finding-6: the template's accepted-forms list names every form the script
  accepts, and the template test asserts the three citation kinds and each
  form.
- finding-7: a record finding, answered when the record is written.

## Review round 4

- finding-1: two tests pin the test_paths scope: "check-review --cite: a test
  declared outside test_paths does not resolve" and "check-review --cite: with
  no test_paths no span resolves as a test name".
- finding-2, finding-3: record findings, answered in the record.

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

## After the base merge

Write `docs/verification/2026-10-08-check-review-cite.md`. Its Gaps state the
manifest refusal, that a citation proves presence and not relevance, and T3's
corpus figures. Run this change's own record through `check-review.sh --cite`
on the scratch copy; it must pass.
