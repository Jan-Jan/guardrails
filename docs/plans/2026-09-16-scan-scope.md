# Closing the writing scan's scope gap — decisions

**Branch:** `close-scan-scope`
**Predecessor:** `docs/plans/2026-09-14-clanker-adoption.md`, section "Known gaps in
the scan's scope, deliberately left for their own change"

The writing rules were merged at `3714f08` in `AGENTS.md` and in the block
`/ratchet` installs. The scan that enforces them reads `skills/*/SKILL.md` and
nothing else: the rules bind every file in this repository, and a gate reports a
breach in eleven of them. This change closes that gap.

## Measurements

Every figure below was counted at `3714f08` with the scan's own word list,
extended by the `sit` family per D3:

```sh
banned='carry|carries|carried|carrying|land|lands|landed|landing|holds|held|holding'
banned="$banned|survive|survives|survived|surviving|says|said|saying"
banned="$banned|refuse|refuses|refused|refusing|refusal|ran|load-bearing"
banned="$banned|sit|sits|sitting"
git grep -Eiow "$banned" -- <pathspec> | wc -l
```

| Surface | Occurrences |
|---|---|
| `skills/` | 3 |
| `AGENTS.md` | 10 |
| `templates/AGENTS-block.md` | 10 |
| `README.md` | 33 |
| `templates/`, other than the block | 23 |
| `install.sh` | 1 |
| `scripts/` | 195 |
| `tests/` | 316 |
| `docs/problems/` | 70 |
| `docs/risk/` | 13 |
| `docs/adr/` | 0 |
| **Total in scope** | **674** |

**These figures were corrected after the independent review, and the error is
recorded rather than repaired in silence.** The table first written here was
counted before `sits` joined the word list, while the command printed above
already includes `sit|sits|sitting`, so this record printed a command that does
not produce the figures beside it. Three rows were wrong — `scripts/` was given
as 185, `tests/` as 307, and the three `docs/` directories as one combined row
of 81 — and the stated total of 664 was not the sum of its own rows either.
Every row above was recounted at `3714f08` with the command above, and two
further parties reproduced the same figures independently. The total is now the
sum of the rows.

Of the 674, 45 are inside the three regions D2 exempts: 10 in the rule text in
`AGENTS.md`, 10 in the rule text in the block, and 25 on the `banned=` lines
that become the word table. Every occurrence in `AGENTS.md` and in the block is
in its rule text; `tests/skills.bats` has 37, of which 25 are on those lines.
The sweep is therefore about 629 occurrences. That figure replaces the earlier
estimate of about 617 edits, which was derived from the wrong total.

The tasks measure a different unit, so the two counts are not comparable. The
scan prints one line per site and a line may contain two matches, so the six
tasks report 589 sites red — 7, 133, 124, 138, 112 and 75 — and T1 swept five
further sites in `scripts/check-trace.sh` that its own pathspec did not yet
cover.

## D1 — Scope is every tracked file except the merged records

In scope: `skills/`, `README.md`, `templates/`, `install.sh`, `scripts/`,
`tests/`, `docs/problems/`, `docs/risk/`, `docs/adr/`, `AGENTS.md`.

Out of scope, permanently: `docs/plans/` and `docs/verification/`. These are
merged evidence. Editing a record to match a later tree falsifies the evidence
in it, and the record for a change is the only durable account of what that
change proved.

Out of scope, for a stated reason rather than by oversight:

- `LICENSE` — third-party text, never edited.
- `.gitignore` — no prose.
- `docs/verification/*.mutations/M*.sh` — executable code, and the rule binds
  it, but it is under a records directory and every edit to a mutation script
  risks the evidence it produced. `M81.sh` demonstrates the hazard directly:
  its anchor quoted a comment block in `scripts/check-signing.sh` containing
  `carried`, and T4's sweep of that comment forced the anchor to be re-cut and
  the mutation to be re-proved.

  **The count was wrong and the exclusion is not absolute.** This record stated
  twenty-seven word-bounded occurrences "left alone". Recounted with
  `git grep -Eiow "$banned" <rev> -- 'docs/verification/*.mutations/M*.sh'`:
  **27 at `3714f08` and 26 at this branch's head.** The difference is
  `docs/verification/2026-08-27-config-schema.mutations/M81.sh`, whose anchor
  text was re-cut from `the script carried on in the caller's directory` to
  `the script continued in the caller's directory` when T4 swept the comment
  the anchor quotes. The re-cut is correct: the anchor still applies to
  `scripts/check-signing.sh` at this head, and T4 re-proved the mutation. So
  one mutation script was edited under this exclusion, deliberately, to keep
  its evidence reproducible. The remaining 26 occurrences are all on `#`
  comment lines of the mutation scripts, none inside an anchor string, and
  those are the ones left alone.

One of those two lists names every tracked path. A file in neither would be an
unstated surface, so listing every path is what makes the scope total.

**The exclusion reason does not draw the line this decision draws.** The
independent review raised this as finding-10, and it is recorded here as an
inconsistency rather than argued away. `docs/problems/` and `docs/risk/` are
merged records too — a problem item records a reproduction, and the risk files
are ISO 14971 hazard analyses — and this change edits twelve files under those
two directories. The reason given above for excluding `docs/plans/` and
`docs/verification/`, that editing a record to match a later tree falsifies the
evidence in it, applies to those files word for word.

There is a real difference between the two groups, and it is narrower than the
line this decision draws. The problem and risk ledgers are live documents that
later changes are expected to edit: `check-trace.sh` reads their `status:`,
`supersedes:` and date fields, a problem item moves from `open` to `resolved`
when a later change resolves it, and a risk file gains controls as the analysis
is extended. Nothing reads a plan or a verification record after its change is
merged, and nothing later is expected to edit one. That difference governs the
ledger fields. It does not govern the evidence prose beside them, which is as
much an observation of one moment as a red-to-green row, and which a vocabulary
sweep can reword.

**The cost, measured, and larger than first recorded.** The first review round
found two such edits and this record stated two. The second round found at
least eight more, so **at least ten** edits to merged problem records are
restatements of an observation rather than substitutions from the replace list.
Each was confirmed here by reading the line at `main` and at this head with
`git show main:<file> | sed -n '<n>p'` beside `sed -n '<n>p' <file>`:

- `docs/problems/2026-09-02-bash32-case-parse.md:18`. The recorded root cause
  `bash 3.2's $(...) parser cannot carry a case pattern's unbalanced )` became
  `cannot parse a case pattern's unbalanced )`. The original is one claim about
  what the parser does with the pattern and the replacement is a different one,
  in the line that records a diagnosis.
- `docs/problems/2026-09-15-class-b-report.md:66`. `a problem that was
  investigated and deliberately accepted has no status to carry` became `no
  status to record it`.
- `docs/problems/2026-09-01-task-worktree-fallback.md:10` and `:34`. `refused
  every git operation` became `denied every git operation` in both. `denied` is
  not on the replace list; the listed replacement is `rejected`.
- `docs/problems/2026-09-01-task-worktree-fallback.md:52`. `hold the entry with
  a test` became `pin the entry with a test`.
- `docs/problems/2026-09-01-task-worktree-fallback.md:81`. `hold prose or
  behavior that already existed` became `cover prose or behavior that already
  existed`.
- `docs/problems/2026-08-27-signing-and-identity.md:50` and `:64`. `carried by
  PR-74gcqg and PR-mtmr7h` became `recorded by`, and `is carried` became `is
  recorded`. The listed replacement is `contains`; `recorded` states something
  the original did not.
- `docs/problems/2026-08-27-macos-awk.md:107`. `Accepting an option is not the
  same as carrying it out` became `not the same as applying it`.
- `docs/problems/2026-09-02-hardware-key-retrofit.md:122`. Three lines of a
  recorded diagnosis were rewritten: `The item said to capture the suite's exit
  code but not that a pipe replaces $? with the pipe tail's status; the clause
  now says to capture it from the run itself` became `The item required
  capturing the suite's exit code but did not state that a pipe replaces $?
  with the pipe tail's status; the clause now states that it is captured from
  the run itself`. This is the largest of the ten: a sentence recording what a
  merged item did and did not require was rewritten in a merged record.

None is false and all are small. Recording them is the point, and the second
round's eight make the point harder than the first round's two did: the
argument that protects `docs/plans/` from this class of edit was not applied to
`docs/problems/`, no reason for the difference was written down, and the sweep
reworded a recorded diagnosis in at least one place. A later change either
extends the exclusion to the evidence prose in the problem and risk ledgers, or
states a reason that covers the ledger fields and that prose separately. This
record does not settle it.

**Consequence accepted, part one — test names.** 57 of the 688 `@test` names at
`main` contain a word on the list. 56 were renamed; the fifty-seventh,
`gr_check_config says so when it cannot read the config at all, before any
scan`, was swept and then restored, because `says so` is an idiom the exemption
list drops rather than an inanimate-subject use. 29 of the 56 are cited in
already merged records. Those citations become stale, and no gate resolves a
test name. The predecessor change accepted the same cost at a smaller scale —
nine renames, seventeen stale citations. The mitigation is D5.

**Consequence accepted, part two — printed messages.** This was not recorded at
first and is the larger half of the same defect. The sweep reaches `scripts/`,
so it rewrites the strings those scripts print, and a merged record that quotes
a script's output now quotes wording the script no longer produces. Measured
here: every line removed from `scripts/` between `main` and this head that is
message or code text rather than a comment, that no longer occurs anywhere in
`scripts/`, matched by exact substring against every tracked file under
`docs/plans/` and `docs/verification/` other than this change's own records.
**Seven record lines in two files quote a changed script line that no longer
exists** — six of them printed messages, one an `awk` line with a trailing
comment:

- `docs/plans/2026-09-04-units-implementation.md:574` — the `gr_die "manifest
  entry carries a glob character: $_e …"` message, now `contains`.
- `docs/plans/2026-09-04-units-implementation.md:2376` — the `safety_class is …
  which sits on a dependency` message, now `is on`.
- `docs/plans/2026-09-04-units-implementation.md:2711` — the `--unit … and
  GR_CONFIG=… disagree — refusing to guess which one you meant` message, now
  `disagree — rejected rather than guessing which one you meant`.
- `docs/plans/2026-09-04-units-implementation.md:1569` — the `awk` line
  `print (a < 0 ? -1 : a)` with the comment `# further future is refused`.
- `docs/plans/2026-09-10-field-report-fixes.md:221` — `Guard 4 will refuse
  cleanup AFTER the signed squash`, now `will reject`.
- `docs/plans/2026-09-10-field-report-fixes.md:544` and `:548` — the two
  `NON-RECIPROCAL-SUPERSESSION … which carries no superseded-by` / `which
  carries no supersedes` printf formats, now `contains no`.

23 further record lines quote a changed script **comment** verbatim, which the
same measurement reports and which costs a reader nothing: a comment is not
output anybody can go and reproduce.

One nearby line is **not** this change's cost and is recorded so it is not
counted twice: `docs/plans/2026-09-10-field-report-fixes.md:212` quotes `so
guard 4 has nothing to refuse`, wording that had already been replaced by `so
nothing was inspected` before `main`, inside the change that plan belongs to.

**Should the rename map cover messages too? No, and here is the reason.** A
stale test-name citation is a dangling reference: the named test does not
exist, nothing in the tree resolves it, and a reader has no way back to what
was meant. A quoted message is not dangling. It is an observation of what a
script printed at the moment that record was written, and that observation
stays true of the tree its change merged — the same status as a red-to-green
count, which no map rewrites either. Mapping messages would also invite the
edit D1 exists to prevent, because the natural next step after a map is to
apply it. What the reader needs instead is this list and the reason, both
above. A later change that disagrees has one clean option: state in the
verification template that quoted program output is accurate as of its own
change and is not maintained afterwards.

## D2 — Exemption by declaration line, not by file name

Three files must state the vocabulary to do their work: `AGENTS.md` and
`templates/AGENTS-block.md` print the replace list, and `tests/skills.bats`
defines the word table the scan reads. Each is in scope, and the scan drops one
named region in each rather than dropping the file:

- In the two markdown files, the region opens at `## Writing: prose, names and
  messages` and closes at the next `## ` heading.
- In `tests/skills.bats`, the region opens at the word table's function
  declaration and closes at the next line that is exactly `}`.

The prose around the rules is therefore scanned. That is the property this
change exists for: the second deslop pass of the predecessor change found
`lands on` and `holds for` in `AGENTS.md` prose, outside the rule text, reported
by no gate.

Rejected: comment markers delimiting exempt regions in every file. One mechanism
instead of two, and a test could assert the exact number of regions — but the
markers would appear in `templates/AGENTS-block.md`, so every adopter's
`AGENTS.md` would contain two lines of scanner scaffolding. People read the
shipped document.

Rejected: naming the three paths and skipping them whole. It reinstates the hole
this change closes.

**Guard against a silent widening.** An exemption that matches more than it
should is the failure mode with no symptom, so the scan counts the exempt
regions' **openers, not the files that contain one**: the markdown opener
`## Writing: prose, names and messages` must occur exactly twice across the
whole pathspec and the table opener `gr_writing_table() {` exactly once. A
renamed heading then fails that assertion rather than changing what the scan
exempts.

**The file count was tried first and was inadequate.** This decision originally
prescribed counting files — the opener in exactly two files and the table
opener in one — and the first review round defeated it: a second
`## Writing: prose, names and messages` heading appended to `AGENTS.md` opens a
second exempt region and leaves the file count at two, so arbitrary prose could
be hidden from the scan with the guard still green. Counting occurrences with
`git grep -cE` summed over the pathspec reports that second heading. The guard
also requires every markdown opener to have a closing `## ` heading, because
demoting the heading that closes the region runs the exemption to end of file
while both counts stay correct.

**A region that closes somewhere was not enough either.** The second review
round defeated the occurrence count one level in: a closer that must exist does
not have to be anywhere in particular, so demoting the heading that closes a
markdown region and adding a `## ` heading further down moves the close over an
arbitrary span, and the shell region had no closer check at all. Both regions
are bounded now rather than only closed. A writing section longer than 35
lines, a word table longer than 45, or either reaching end of file, is reported
by name and line, and the word-table region is reported as well when it
swallows another function declaration — which is what indenting its closing
brace does. The regions are 21 lines in each markdown file and 30 lines in
`tests/skills.bats`, so each bound leaves room to edit the rule text and none
to re-close a region around a document. The pattern that closes a markdown
region is read from one function by the scan and by the guard, because two
copies of it meant the guard matched its own and reported nothing when the
scan's copy changed.

**What a bound does not do is read what is inside it.** A sentence added inside
the rule text's own section, within the bound, is still exempt. That is what an
exemption is; the verification record's Gaps states it, with the reproduction.

## D3 — The metaphor rule gets one named example and no more

`sits -> is in` is added to the replace list in `AGENTS.md` and in the block, and
the scan reads `sit|sits|sitting`. The past tense is excluded: `sat` is an awk
variable in `check-trace.sh` and produces seven false reports. Measured at
`3714f08`, the three scanned forms produce 27 matches in scope and no false
report — the same narrowing the predecessor applied to `hold` against `holds`.

This enforces one example of the metaphor rule, not the rule itself. Detecting
metaphor needs the animacy of the subject, which a line scan cannot read, so a
green scan does not mean the prose follows the first bullet. The deslop pass at
`develop-change`'s exit and `verify-before-merge` check 8 enforce that bullet.

Rejected for now: a wider list of inanimate-subject verbs — `lives`, `wants`,
`knows`, `sees`, `decides`. Several have correct uses in this tree, so the list
needs its own measurement before it can be proposed.

## D4 — The word table is keyed by the replace list, and a test compares them

The predecessor's `banned=` list is a hand copy of the replace list in
`AGENTS.md`, and nothing connected the two: no scan read a word added to the
shipped rule, and no check reported the divergence.

The list becomes a table keyed by the word the replace list names, each key
mapping to the forms the scan reads:

```
carries      -> carry carries carried carrying
lands        -> land lands landed landing
holds        -> hold holds held holding
survives     -> survive survives survived surviving
says         -> says said saying
refuses      -> refuse refuses refused refusing refusal
ran          -> ran
load-bearing -> load-bearing
sits         -> sit sits sitting
```

Two rows differ from what this decision first stated, and the difference is the
whole judgment the table encodes. `holds` was given as `holds held holding`,
excluding the bare `hold`; the shipped row is `hold holds held holding`,
because the exemption list drops the one correct English use — `when all three
hold` — by its full phrasing, so the bare form can be scanned. `says` was given
as `says said saying` and ships unchanged; the row that does **not** exist is a
`say` row.

**The bare `say` is deliberately not scanned, and that is a narrowing of the
rule, not of the tree.** Two correct uses would become unwritable. `grep -Eiw
say` matches inside the noun `say-so`, because the word boundary falls at the
hyphen, so `without the user's explicit say-so` reports. And the parenthetical
`say` meaning "for example" — `an extra prefix (ADR, say)` — has no entry on
the shipped replace list at all, so a scan that reported it would enforce a
rule the shipped document does not state. Scanning `say` narrows the tree to
fit the scan: the first sweep deleted one `say-so` and four parentheticals to
keep the suite green, and all five were restored. The forms `says`, `said` and
`saying` stay in, because `states` replaces each of them, and the imperative
`say so` then needs no exemption of its own beyond `says so` and `said so`.

A test parses the replace list out of `templates/AGENTS-block.md` and asserts
that the set of words it names equals the set of keys. The comparison is
bidirectional by construction: a word added to the shipped rule with no table
entry fails, and a table entry with no shipped rule behind it fails too.

The same test parses the replace list out of this repository's own `AGENTS.md`
and requires it to name the same words as the shipped block. The two are one
rule stated twice, and until that comparison existed a word added to either
alone left adopters and this tree following different lists, with nothing
reporting the divergence. All three — this repository's list, the shipped list
and the table's keys — name the same nine words, measured at this head.

The inflections stay hand-written. Each form list was narrowed against this tree
until the correct English uses stopped matching, and the replace list does not
determine that judgment.

## D5 — The verification record maps the renamed test names

`docs/verification/2026-09-16-close-scan-scope.md` records **57** old names and
their replacements as a table: the 56 vocabulary-driven renames, and the scan
test itself, whose name changed because its scope widened. A reader who finds a
stale citation in a merged record then has one place to resolve it. This change
does not edit the merged records themselves — see D1.

**The row count was stated as 58 here and in Cost, and 58 double-counts one
name.** 57 `@test` names contained a word on the list, but one of them —
`gr_check_config says so when it cannot read the config at all, before any
scan` — was swept and then restored, so it is not a rename and has no row. 56
vocabulary renames plus the one scope-driven rename is 57 rows, which is what
the table has. Counted with `grep -c` over the table's rows: 57, of which 30
are marked cited.

## D6 — The scan stays a test in this repository

`/ratchet` installs the writing rules into every adopter's `AGENTS.md` and
installs no gate for them, so a gate enforces the rules in this repository and
nothing enforces them in any adopter's. A shipped `scripts/check-writing.sh`
would close that.

Not taken. It needs argument handling, a pathspec contract, its own mutation
suite, README documentation and a `verify-before-merge` integration — three to
four times this change, on top of the same sweep. This change does what the
predecessor's record specified and no more. This record states the gap between
the shipped rule and the shipped gate, and the reason for it, so that a later
change does not have to rediscover either.

## What the scan exempts afterwards

**Seven exemptions, listed as data in `gr_writing_exemptions` in
`tests/skills.bats`.** This section first named two, both git quotations in one
skill. The shipped list has seven entries, each a `path|phrase` pair where the
path is either one file or `*` for every file the scan reads. The scan compiles
them into one `sed` script, one substitution per entry, with every letter
written as a case-insensitive bracket pair, and applies it to each line before
the `grep`. The compilation is what makes them case-insensitive: `sed`'s own
`I` flag is not POSIX, and a case-sensitive chain is what rewrote `SAID SO` in
`scripts/check-review.sh` into non-English to keep the suite green.

Four are verbatim git output, each scoped to the file that quotes it:

- `skills/worktree-discipline/SKILL.md` — `refusing to update checked out branch`
- `skills/worktree-discipline/SKILL.md` — `refusing to fetch into branch`
- `tests/skills.bats` — `refusing to update checked out branch`
- `tests/skills.bats` — `refusing to fetch into branch`

git prints that wording; this repository only quotes it, and the test that
asserts the skill quotes it correctly must contain the same bytes.

Three are English idioms, scoped to every file:

- `says so` — as in "a review that found nothing must still say so".
- `said so` — the same idiom in the past tense.
- `when all three hold` — which is what lets the bare `hold` be scanned (D4).

**The idiom exemptions are phrase-specific, and that is deliberate.** `when all
three hold` is dropped; `when both hold`, which is equally correct English,
is not, and a future use of it would be reported. The narrow phrase is chosen
over a general one because a general exemption for `hold` returns this scan to
the state D4 exists to leave: the word unscanned everywhere, with no gate to
say so. The cost is that a correct sentence can be reported, and the remedy
then is to add its phrase to this list rather than to reword the sentence.

**The length of this list is pinned, and the compiled script is validated.**
One added entry removes a phrase from every line the scan reads, anywhere in
scope, and no other check reports it: the form canary feeds the scan one form
per line and every exemption is a phrase. A test therefore asserts that
`gr_writing_exemptions` contains exactly seven entries, so an eighth is an edit
in two places and appears in the diff as a changed expectation. The scan also
compiles the list against no input before it reads any file and exits 2 if the
compilation fails. An entry with an empty phrase makes the script begin with a
substitution whose pattern is empty; BSD sed exits 1, grep then reads an empty
stream and exits 1 as well, and a scan that never ran would otherwise be
indistinguishable from a clean tree.

This change drops the predecessor's third exemption. `which carries no
superseded-by` is a message `check-trace.sh` prints, and `scripts/` is now in
scope, so the sweep reaches the message and the skill's quotation of it.

## Cost

About 629 occurrences, nearly all single-word substitutions, reported by the
tasks as 589 sites. Six serial tasks, then four fix rounds against three
review rounds, the third of them targeted at the first two rounds'
dispositions. One mutation script re-cut and re-proved. Fifty-six test
renames for the vocabulary, of which 29 leave a stale citation in a merged
record, and one further rename because the scan test widened in scope. **The
map D5 requires therefore has 57 rows, 30 of them cited** — not 58, which
counted a name that was swept and then restored. Seven lines in two merged
plans quote a script message that changed; see D1. No behavior changes: every
edit is prose, a comment, a printed message, or a test name, and where a
printed message changes, the assertion that reads it changes in the same task.
