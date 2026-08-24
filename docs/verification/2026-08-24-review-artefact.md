# Verification — review-artefact (2026-08-24)

branch: review-artefact
reviewer: a fresh subagent, given the diff, the plan and read-only access to a
  consuming project; no implementation narrative and no chat history
verdict: six blocking findings, all fixed in this change; the reviewer also
  refuted one of my own mutation-survival claims by measurement
reproduced: not applicable in the usual sense — this change closes an ABSENCE,
  not a defect, so there was no failing behaviour to reproduce. What was
  measured instead, before any code was written: of the 79 verification records
  in the corpus project, **zero** carry any structured field, so nothing in the
  tree could distinguish a change that was reviewed from one that was not. The
  defects this change DID have were reproduced — every one of the reviewer's
  six blocking findings came with a fixture and a command, and each is pinned
  by a test that reddens against the code as it stood.

Change: the independent review and the verification record become checkable
artefacts, and the record gains a field for what was *not* established.
Branched from `main` at `47cde0b`. Plan: `docs/plans/2026-08-23-review-artefact.md`.

Answers findings **04** (assurance) and **09b** (no field for doubt) of *Where
the Gates Leak*, reported against guardrails 0.1.0 by a class B project running
the toolkit in production.

## The gate

Every figure derived from the shipped tree, not carried forward.

| Gate | Result |
| --- | --- |
| `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` | `1..324` — **324 ok, 0 not ok, 0 skipped** (`main`: 260) |
| `sh -n` on all seven scripts | clean, and pinned by a named test |
| gawk 5.3.2 / mawk / busybox awk | byte-identical output on the new awk program (reviewer-run) |
| Working tree | clean, no draft ledger files |
| Corpus, `sightings-app` @ `05d3b71c` (80 records, 67 problem files) | `check-ids.sh` and `check-trace.sh` **byte-identical** to `main` |

Derived by `tests/evidence.sh main` — do not edit by hand.

- Suite: **324 tests** (main: 260); 319 measured against `main`.
- New or renamed since `main`: **64**.
- Of those, **64** go red when run against `main`'s scripts.
- **0** cannot go red, and none is counted as evidence that a defect was fixed.

**merge-change steps 3, 4 and 5 could not run on this repository.**
`finalize-docs.sh`, `check-ids.sh`, `check-trace.sh` and `check-review.sh` all
exit 2 here with `config not found: .guardrails/config.yaml` — guardrails does
not yet host its own gates (tooth 0,
`docs/plans/2026-08-22-ratchet-gap-analysis.md`). What stood in for them: the
bats suite, which runs all four against fixture projects; the corpus run above,
which runs three of them against a real class B project; and the dogfood
section below, which runs the fourth against this record. Stated so that four
gates reporting nothing is not mistaken for four gates passing.

**The base branch was merged from a LOCAL ref, not from the remote.**
`git fetch origin` fails in this environment — `Bad owner or permissions on
/etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf` — and network access to GitHub
is absent here deliberately, not broken. merge-change step 1 requires that this
be recorded rather than scrolled past, so: the base merged in was local `main`
at `47cde0b`, which the operator confirms is in sync with the remote. That is
what the duplicate scan at step 4 was compared against.

The corpus moved under this change — it was at `caed1452` when measured first
and at `05d3b71c` when measured last — so both figures above were re-derived at
the later commit rather than compared across two trees.

## What was wrong

Nothing was wrong with the code. This change closes an **absence**: the step
that catches the most had nothing behind it.

> Step 6a is the highest-yield step in the sequence. […] Nothing verifies that
> this step happened. There is no check that a reviewer was dispatched, that
> findings were addressed, or that the verdict recorded in the verification
> record corresponds to anything. Sixty-nine verification records exist on this
> repo, entirely on the honour system.

Measured on the corpus, the asymmetry is exactly as reported: of 80
verification records in `sightings-app`, **0** carry any structured field at
all — no `branch:`, no `reviewer:`, no `verdict:`, no `reproduced:`.

## What was built

`scripts/check-review.sh`, a fourth gate:

| Violation | Catches |
| --- | --- |
| `MISSING-RECORD BRANCH` | step 6b never happened for this change |
| `STALE-RECORD FILE` | a record declares the branch, but this change did not write it — a reused branch name |
| `INCOMPLETE-RECORD FILE (no KEYWORD:)` | the record omits `reviewer:`, `verdict:` or `reproduced:`, or carries it with no value |
| `UNDISPOSED-FINDING FILE:LINE ID` | a finding with no stated resolution — the half-applied fix |
| `MALFORMED-FINDING FILE:LINE` | a line shaped like a finding header that opens no block, so the finding vanishes and its disposition attaches to the one above |
| `ORPHAN-DISPOSITION FILE:LINE` | a `disposition:` belonging to no finding — the backstop for every shape the rule above cannot name |

plus `templates/verification.md` (the schema and its grammar note),
`doc_verification` in the config schema, and `merge-change` step **6c**.

Three supporting changes in `lib.sh`, each a single definition rather than a
second copy:

* `GR_AWK_FRONT_MATTER` — bounded YAML front-matter skipping, extracted from
  `check-trace.sh`'s orphan scan, which now consumes it. Two gates skip front
  matter and they must skip the same bytes: one reads a `status:` there as
  metadata, and the other must not accept a `reviewer:` there as a field.
* `gr_md_files` — the "a directory of `*.md` holding none is an error, never an
  empty list" rule, extracted from `gr_doc_files`, which now consumes it.
* `gr_verification_dir` — the one `doc_*` key with a default.

## What this gate deliberately does not do

Stated here so that omission is not mistaken for oversight.

* **It judges presence, never quality.** It cannot know whether a review was
  good.
* **It does not test reviewer independence.** With agent reviewers the identity
  string is whatever the author types; a gate keyed on it would be theatre.
* **It never judges the `reproduced:` value.** `reproduced: no` passes. The
  field exists to make silence visible, not to force a yes.
* **It cannot know how many findings a review raised.** A record that omits a
  finding entirely reads identically to a review that did not raise it. The
  gate closes the *detached* and *half-applied* cases, not the *unrecorded* one.
* **Only the record for the change under merge is checked.** Legacy records are
  grandfathered. Failing 80 records on upgrade day is how a gate gets switched
  off.
* **It does not detect forgery.** A record whose fields sit inside an HTML
  comment satisfies it. Those lines were typed by the author on purpose; column
  one is a claim, here as everywhere else in the toolkit.

## Mutation table

32 mutations, each applied to the shipped tree with the suite re-run.
`killed_by` is the number of tests that reddened. The scripts are in
`docs/verification/2026-08-23-review-artefact.mutations/`, one `*.sh` each.

| # | Mutation | Result |
| --- | --- | --- |
| M01 | lib.sh: gr_verification_dir has no default | killed by 52 |
| M02 | lib.sh: gr_verification_dir does not require the directory to exist | killed by 2 |
| M03 | check-review: the base-branch refusal is dropped | killed by 1 |
| M04 | check-review: a detached HEAD is accepted | killed by 1 |
| M05 | check-review: a failed record listing is not propagated | killed by 1 |
| M06 | check-review: the branch is matched as a substring, not whole | killed by 1 |
| M07 | check-review: a field with no value counts as present | killed by 2 |
| M08 | check-review: a field is matched anywhere on the line, not at column one | killed by 1 |
| M09 | check-review: front matter is not skipped | killed by 4 |
| M10 | check-review: the finding line is reported as NR, not FNR | killed by 1 |
| M11 | check-review: a finding at end of file is never flushed | killed by 6 |
| M12 | check-review: a finding is not flushed when the next block opens | killed by 4 |
| M13 | check-review: a finding-shaped line that opens no block is passed over | killed by 5 |
| M14 | check-review: reproduced: is not required | killed by 5 |
| M15 | check-review: a disposition outside any finding block counts | **SURVIVED** |
| M16 | check-review: the config is not validated | killed by 1 |
| M17 | check-review: an unknown argument is ignored | killed by 1 |
| M18 | check-review: --branch accepts a missing value | killed by 1 |
| M19 | check-review: the checked: denominator is not printed | killed by 7 |
| M20 | check-review: findings are never counted in the denominator | killed by 2 |
| M21 | check-review: LC_ALL=C is dropped from the record scan | **SURVIVED** |
| M22 | check-review: an awk failure on a record is not fatal | killed by 1 |
| M23 | check-review: the finding shape is a regex, not a byte test | killed by 2 |
| M24 | check-trace: the front-matter BOM strip is dropped | killed by 1 |
| M25 | check-review: the BOM strip is dropped | killed by 1 |
| M26 | check-review: the trailing-CR strip is dropped | killed by 1 |
| M27 | check-review: every branch: line is a claim, not only the first | killed by 2 |
| M28 | check-review: provenance is never checked | killed by 2 |
| M29 | check-review: an orphan disposition is dropped in silence | killed by 2 |
| M30 | check-review: --branch may name the base branch | killed by 1 |
| M31 | lib.sh: an empty doc_verification value falls back to the default | killed by 1 |
| M32 | lib.sh: gr_md_files accepts a directory with no *.md | killed by 3 |
| M33 | check-review: the finding shape is a regex AND LC_ALL=C is dropped | killed by 3 |

### The two survivors

**M15** — `open_line &&` removed from the `disposition:` rule. An **equivalent
mutant**, and the reviewer tried to refute it: 8000 generated records, fuzzed
differentially against the mutant, **zero differences**. It holds because
`disposed` is cleared only where a block OPENS and never in the flush, so a
`disposition:` seen while no block is open sets a flag that is either cleared
before the next flush or never read. That invariant is now written on
`gr_flush`, because the next person to let a block open by another route makes
the guard load-bearing with no test to notice.

**M21** — `LC_ALL=C` dropped from the record scan. It survives now for a better
reason than it did before review. The reviewer **refuted** the original claim by
finding an input that distinguished it — a latin-1 finding label, under a UTF-8
locale, turning a reported violation into exit 0. That worked because the
matcher was a regex with a negated bracket expression. The matcher is now
`substr`/`index`, so the locale cannot reach it, and M21 alone no longer changes
any answer. **M33** is the pair — regex AND no `LC_ALL=C` — and the latin-1 test
kills it, which is what makes that test load-bearing rather than decorative. The
setting stays as defence in depth over the octal-escape BOM strip, the one
construct left that a locale could in principle touch.

Four mutations initially survived that should not have. Two were test defects
found before review (**M04**, a test whose substring matched two different
guards; **M22**, no test that made awk fail). Two more were mutations that had
gone stale against the code they described — **M19** and **M30** silently
applied nothing after the script changed under them, and reported as survivors.
A mutation that no longer matches its target is a test that no longer runs, and
it reports as the best possible news.

## Review

One independent round, adversarial brief, no implementation narrative. Six
blocking findings and eight observations. Every blocking finding came with a
fixture and a command; each is now pinned by a test that reddens against the
code as it stood when the finding was written.

**finding-1**: a change with NO verification record at all exits 0, because
another record quoted the branch name in a fenced code block. The selector had
no fence awareness, no uniqueness rule, and no tie to the change; a reused
branch name would also let the previous change's record answer for this one.
disposition: two answers, neither of them fence parsing, which no gate in this
toolkit does. A record now claims the FIRST `branch:` it carries and no other,
which is the rule `GR_AWK_ID_RUN` already applies to every annotation; and the
record must be one this change wrote, reported as `STALE-RECORD` otherwise and
skipped-with-announcement under `--branch`. Plan amended as D9. Pinned by
"a branch: inside a fenced code block does not select the record", "the record
claims the first branch it carries, not the last", "a record this change did
not write is reported, not accepted" and three more.

**finding-2**: the same finding also observed that `ratchet` copied
`templates/verification.md` into `docs/verification/`, where every `*.md` is
read as a record — so every ratcheted project shipped a schema-shaped record in
the scanned directory from day one.
disposition: `ratchet` now copies it to `.guardrails/templates/` instead, and
`merge-change` step 6b reads it from there. The records directory holds records.

**finding-3**: a finding could disappear silently and its disposition be
credited to a DIFFERENT finding, at exit 0. `**finding-2**` with the colon
forgotten neither opens a block nor closes one, so the next `disposition:` was
attributed to the finding above and both then read as answered — the
half-applied fix this gate exists to catch, inside the gate. An indented
header, a space instead of a hyphen and a capitalised label lost the finding
the same way, and there was no orphan backstop at all.
disposition: the shape is now named byte-wise — a line beginning `**finding`
not followed by a letter or digit, opening no block, is `MALFORMED-FINDING` —
and backed by `ORPHAN-DISPOSITION`, the same mechanism `ORPHAN-ANNOTATION`
provides for ledger items, which catches every shape the rule cannot name.
Plan amended as D10. Six tests, one per shape, plus one proving
`**findings**: three` is still an ordinary heading.

**finding-4**: my claim that mutation M21 was defence in depth was **refuted by
measurement**. Dropping `LC_ALL=C` turned a reported violation into exit 0,
because the loose finding matcher was a regex with a negated bracket
expression, and gawk in a multibyte locale does not match an invalid byte
sequence with one. A latin-1 finding label failed OPEN, decided by the
operator locale — the identical defect `gr_block_closes` was made byte-wise to
remove, reintroduced by new code in the same file.
disposition: the matcher is `substr`/`index`, so no locale can change its
answer, and `gr_block_opens_loose` is deleted from `lib.sh` rather than left as
a shared function with a locale hazard in it. Pinned by "a finding label
carrying a non-UTF-8 byte is reported", which runs under `en_US.UTF-8` on
purpose — under `LC_ALL=C` every awk agrees and the defect is invisible.

**finding-5**: `tests/.bats-core` was committed as an absolute symlink into my
home directory. `.gitignore` had `tests/.bats-core/` with a trailing slash,
which matches directories only, so `git add -A` took the symlink. On any other
machine `tests/run-tests.sh` exits 128 and cannot self-heal.
disposition: untracked, and the ignore rule fixed to match both. Not a false
green — `set -eu` propagates the 128 — which is the only reason it was not
ranked higher.

**finding-6**: two more tests passed for a reason other than the behaviour they
named, both proved by breaking the code and watching the suite stay green. The
`GR_AWK_ITEM_BLOCK` poison pin asserted only that `UNDISPOSED-FINDING` was
ABSENT, which deleting the script also satisfies; its sibling written in the
same sitting asserted positively and was sound.
disposition: both now assert positively as well. That makes six of this class
found in one change — three by me before review, one by mutation, two by the
reviewer — which is worth stating plainly rather than filing.

**finding-7**: `--branch main` on the base branch exited 0, the case D6 says
must be exit 2. The flag was also unrequested by the plan.
disposition: `--branch` naming the base branch is now refused. The flag stays:
pull-request CI has no worktree, and it now announces in the summary line that
provenance was not checked. Recorded as derived work in the plan.

**finding-8**: an empty `doc_verification:` value silently fell back to the
default. A key present in the file whose value the reader cannot see is the
exact shape `gr_check_config` exists to reject, arriving through the one key
with a fallback.
disposition: present-but-empty is now fatal, distinguished from absent by
asking the config file directly, since `cfg_get` cannot tell them apart.

**finding-9**: the `*.md` listing in `check-review.sh` was a hand-copy of
`gr_doc_files`'s count-and-die loop — in a change whose first task was "front
matter has one definition".
disposition: extracted as `gr_md_files`; `gr_doc_files` and `check-review.sh`
both call it, and the call counts are pinned.

**finding-10**: the plan's D5 listed `branch:` as a fourth required field. The
implementation excludes it deliberately.
disposition: the plan was wrong and the code was right; D5 amended to say so
rather than the code changed to match a mistake.

**finding-11**: the BOM strip and the CR strip in the record scan had no test
and no mutation — both survived deletion against the entire suite. The gate
inherited the code from `check-trace.sh` without inheriting its tests.
disposition: three tests added (CRLF record, BOM record, BOM in front of front
matter) and two mutations, M25 and M26.

**finding-12**: M15 could not be refuted. The reviewer fuzzed 8000 generated
records differentially against the mutant and found zero differences, and
identified why: `disposed` is cleared only where a block opens.
disposition: the invariant is now written on `gr_flush`, where the next person
to let a block open by another route will read it. The guard stays; no code
change.

**finding-13**: `MISSING-RECORD` goes to stdout while its explanation goes to
stderr, so a CI job capturing only stdout gets the violation without the
remedy.
disposition: not changed. `check-ids.sh` does exactly this for every one of its
violations, and one gate splitting streams differently is worse than the
inconvenience. Recorded as a gap.

**finding-14**: a symlinked record is counted twice in `checked:`, and records
in subdirectories are invisible to both the count and the scan.
disposition: the subdirectory limit is pinned by a test and stated in
`gr_md_files`, where `gr_doc_files` has always had it. The symlink double-count
is recorded as a gap; it cannot produce a false green, only a denominator that
says something other than what it means.

## Gaps

1. **Legacy records are unchecked**, by design.
2. **A record in a subdirectory of `doc_verification` is not read** — one level
   only, the same limit `gr_doc_files` has.
3. **A symlinked record counts twice** in the denominator.
4. **`reviewer:` is a free string.** Nothing connects it to a real reviewer, a
   commit, or a transcript, and nothing can.
5. **The finding count is unverifiable** — a review's findings are known only
   to the reviewer.
6. **A record whose fields sit in an HTML comment satisfies the gate.**
7. **`MISSING-RECORD` and its remedy go to different streams.**
8. **guardrails still cannot run this gate on itself** — it has no
   `.guardrails/` install (tooth 0,
   `docs/plans/2026-08-22-ratchet-gap-analysis.md`). This record was validated
   by running the shipped gate against a throwaway guardrails project holding a
   copy of it; command and output below.

## Dogfood

guardrails has no `.guardrails/` install of its own, so this record was checked
by copying it, and the shipped scripts, into a throwaway guardrails project. It
passes, and it fails for the right reasons when the two things this change
exists to require are removed:

```
$ sh .guardrails/scripts/check-review.sh --branch review-artefact
checked: records 1, for review-artefact 1, findings 14; provenance NOT checked (--branch)
exit=0

$ sed -i '/^reproduced:/,/^$/d' docs/verification/2026-08-24-review-artefact.md
$ sh .guardrails/scripts/check-review.sh --branch review-artefact
INCOMPLETE-RECORD docs/verification/2026-08-24-review-artefact.md (no reproduced:)
checked: records 1, for review-artefact 1, findings 14; provenance NOT checked (--branch)
exit=1

$ sed -i '0,/^disposition: two answers/{/^disposition: two answers/d}' <same file>
$ sh .guardrails/scripts/check-review.sh --branch review-artefact
UNDISPOSED-FINDING docs/verification/2026-08-24-review-artefact.md:189 finding-1
checked: records 1, for review-artefact 1, findings 14; provenance NOT checked (--branch)
exit=1
```

Fourteen findings, fourteen dispositions, and the run says so. The summary
announces that provenance was not checked, because the fixture is a single
checkout where every branch is its own base — which is the case `--branch`
exists for, saying out loud which question it did not ask.
