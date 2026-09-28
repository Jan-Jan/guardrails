---
name: check-traceability
description: Run and interpret the guardrails traceability checker - orphaned requirements, unmitigated hazards, unimplemented controls, untraced design, dangling references. Use after documentation or code changes and always before merging.
---

# Check Traceability

**Announce at start:** "Using the check-traceability skill."

```sh
.guardrails/scripts/check-trace.sh              # traceability gates
.guardrails/scripts/check-ids.sh --allow-draft-files  # ID sanity while developing
```

Run from the repo root. Each violation is one line: `<RULE> <ID> (<detail>)`.
Fix the artifact, never the checker.

Every run ends with two summary lines — what it found, and what it read:

```
checked: REQ 90, HAZ 4, RC 7, SDD 20, LLR 23, PR 63
sources: srs 18, rmf 6, sad 4, soup 1, problems 35; strict 5, tests 3
```

*(Illustrative figures — your project's will differ.)*

(The document figures are file counts; `strict` and `tests` count configured
path entries, since one entry may be a directory or a pathspec.)

**Read both lines before believing the verdict.** Exit 0 with only these two
lines above it is clean. `REQ 0` on a project that has requirements, or
`rmf 0` on a project that has an RMF, means the checker found nothing and
proved nothing — a config or layout problem, not a pass. `checked:` alone is
not enough on its own: it counts items found anywhere in the tree, while
`sources:` counts the files the gate for those items actually opened.

**Where an item ends.** An item block **opens** at its definition form and
**closes** at the next markdown heading or the next **bold line containing a
colon**. That is the whole rule. `**ADR-0007**:`, `**Decision 7**:`,
`**LLR-overflow:**`, `**Rationale**:` and `**Note **bold** here**:` all close a
block, whether or not they are valid items and whatever their prefix.
`**21 of 35 inverted, 14 not.**` contains no colon and closes nothing.

The practical rule when writing an item body: a bold label with a colon starts
a new block, so put your annotations *above* it. The one limit: a bold line
with no **ASCII colon** never closes, because nothing distinguishes it from
the emphasised sentence that caused the original defect. (A full-width colon,
U+FF1A, is not an ASCII colon.) The close is byte-wise, so it behaves the same
under every awk and every locale.

Closing is deliberately broader than opening, and getting there took three
review rounds. Until 2026-08-22 any line starting `**` closed the block, which
made two gates reject correct documents (`UNTRACED-DESIGN` and
`UNSATISFIED-LLR` fire when they do *not* find their annotation) and two pass
over real violations in silence (`UNANALYZED-DERIVED` and `UNRESOLVED-PR` fire
when they *do*). Narrowing the close to valid item IDs fixed that and broke
something worse: a line a reader takes for a header became body text, so the
annotations under it were credited to the item *above* — a wrong answer where
the old rule merely dropped them. Narrowing it to *header-shaped* lines was the
same mistake in a narrower form. The rule that works is the one stated as a
subtraction: everything the old rule closed, minus the colon-free shape that
caused the defect. `check-ids.sh` separately reports `**REQ-abcdef**:` as
`MALFORMED-ID`.

`ORPHAN-ANNOTATION` covers what falls outside every block. It fires three ways:
before the first item in a file, under a heading with no item since, and —
the one most likely to reach a real ledger — **inside a block opened by a
prefix whose gate does not read that keyword**, such as a `traces:` line inside
an `**LLR-…**` block.

Its known limit was that it matched a keyword only at column one while the
gates matched one anywhere on the line, so a bulleted `- satisfies: REQ-…`
was credited inside a block but was not backstopped outside one. **A gate that
reads a keyword where the backstop does not is the case the backstop exists to
catch**, and on a bullet-style ledger it meant exit 0 with a derived item no
gate ever checked, or an open problem report absent from the known-problem
list.

That limit is **narrowed, not closed**, and what narrowed is the backstop
alone.
The backstop steps over one or more leading list markers — a bullet (`-`, `*`
or `+`) or an ordered marker (a run of digits closed by `.` or `)`), each
followed by whitespace, indented or not — before it tests the keyword. **Every
reader stays at column one.** So a list-item annotation is never taken as a
value, and is reported `ORPHAN-ANNOTATION` where it belongs to no item. **Bare
indentation still declares nothing**: with no marker present the line is tested
unchanged, which is what keeps the indented item grammar shipped in the ledger
templates inert. A bare number is not a marker either — the `.` or `)` is
required, so `1 status: of the bus` is prose and stays prose.

**What is still open, stated plainly**, because this rule was published as a
full closure three times and was not one. Two forms are stepped over — bullets
and ordered markers, in runs. **Every other form is unenumerated and presumed
live**: a GFM task-list item `- [x] satisfies:` was measured credited inside a
block and unreported outside one, after the second closure claim. The problem
item `PR-h3wujj` stays open for that reason, and the list below is what has
been found rather than what exists. It knew bullets alone, so an
ordered-list item reproduced the defect verbatim — `1. satisfies: REQ-…`
silent outside every block, credited inside one — and independent review
measured it and sent the change back. The backstop steps over list markers and
nothing else, while the gates match a keyword anywhere on its line. So a
blockquoted `> satisfies: REQ-…`, a table cell, or a mention inside a sentence
is still credited inside a block and still unreported outside one. That residue
is deliberate: `templates/sad.md` ships the annotation on the definition line,
so narrowing the gates to column one would reject the documented primary form
and every SAD written to it.

**The invariant is a containment, not an equality**: the backstop must see at
least what every reader sees. Widening in the other direction — the readers up
to the backstop — is unsafe, and was tried and rejected. Every scalar reader
here takes the FIRST occurrence in the block, so a reader that accepted the
bullet form let a quoted one outrank the real one: a problem item quoting
`- status: resolved` above its own `status: open` dropped out of the
known-problem list at exit 0, and a verification record declaring
`branch: other-change` that quoted `- branch: my-change` became the record for
`my-change` — a pass reported over a review that never happened. A backstop
wider than the readers can only over-report; a reader wider than it intends can
answer confidently and wrongly.

So a bulleted annotation INSIDE a block is a missing field, not a silent one:
the item is `INCOMPLETE-PROBLEM`, the record `MISSING-RECORD`, and the fix is
to drop the marker.

**`traces:` and `satisfies:` are still read anywhere on their line** by
`gr_id_run`, and that is deliberate rather than the remainder of the old
asymmetry: `templates/sad.md` ships the annotation ON the definition line, so
requiring column one of the reader would reject the documented primary form
and every SAD written against it. What changed is that the backstop now sees
the bullet form at all. The narrower residue is stated in `lib.sh` and is not
closed here: a `satisfies:` elsewhere on its line — mid-sentence, or indented
with no marker — still satisfies an LLR while this backstop never reads it.

**`MISPLACED-ITEM` is what connects the two.** Each of the six gated
prefixes is checked against the one document it may be defined in
(`REQ`→`doc_srs`, `HAZ`/`RC`→`doc_rmf`, `SDD`/`LLR`→`doc_sad`,
`PR`→`doc_problems`), so while that gate is green every item in `checked:`
is in a document some gate opened. It covers those six only — an item of an
extra declared prefix is still counted without being examined.

A misspelled or misplaced config key no longer belongs on that list: the
config is validated, and the shapes below are exit 2. Three things it still
does not catch, worth knowing rather than assuming:

- `doc_soup` is required by no prefix, so omitting it quietly narrows what
  `DANGLING-REF` scans — a zero in `sources:` is where that shows.
  (`strict_paths` was in this list until it was made mandatory: omitting it
  left the source scan walking nothing at exit 0.);
- `verify_commands` absent means the merge gate runs no commands and reports
  that nothing failed. The schema does not require it, because nothing in
  these scripts reads it;
- dropping a prefix from `id_prefixes` does **not** switch its gates off —
  `MISSING-TEST` is keyed on `test_paths` and the rest on the document lists,
  so all of them keep firing. What it removes is that prefix from `checked:`
  and from `DANGLING-REF`'s scope, so references to it stop being checked
  while its other gates continue to run.

`sources:` remains worth reading: a zero there for a document the project does
have means the key is absent, since a configured-but-empty ledger directory is
itself exit 2.

**Exit 2 is an environment error and always fatal**, because each of these
would otherwise let a gate pass without running:

| Message | Cause |
|---|---|
| `doc_rmf is configured as 'docs/risk', which does not exist` | A configured path that is absent. |
| `doc_rmf is configured as directory 'docs/risk', which contains no *.md files` | A ledger directory with nothing in it — including the case where the `*.md` files are in a **subdirectory**, since `doc_*` directories are read one level deep only. |
| `id_prefixes entry is not a bare identifier: PR[` | A prefix is interpolated into every scan pattern; a metacharacter makes the pattern invalid, and a scan that errors finds nothing — indistinguishable from a clean tree. |
| `unknown config key(s): doc_rmff` | A typo'd key. Nothing reads it, so the gate it was meant to configure silently never runs. |
| `config line(s) that are neither a comment, a top-level key, nor a '  - item' belonging to one` | A key that is not `identifier:` at column one (`strict-paths:`, ` strict_paths:`, `strict_paths :`); a list item at column zero; or a list item **orphaned** from its key by a column-one comment or a `---` separator above it. An orphan is ambiguous — it either vanishes with its list or is adopted by the block above — so it is rejected rather than guessed at. Commenting a list key out means commenting its items out too. |
| `config begins with a UTF-8 BOM` | The BOM makes the first key unreadable, i.e. silently absent. |
| `config has carriage returns inside a line` | A `\r`-only file is one single record to every reader here, so every key but the first is invisible. Save it with LF or CRLF endings. |
| `cannot read <config> — it exists but this user cannot open it` | Every scan below this would print nothing and pass vacuously, and the verdict would come from an unrelated check naming the wrong cause. |
| `config key(s) set more than once` | Every reader takes the FIRST occurrence and stops, while YAML takes the last — so one of the two is read by nobody. Appending a second `verify_commands:` below the first means the real suite never runs. |
| `config key(s) set to nothing` | A key with no value and no items reads as absent to the gate that uses it, and that gate then passes having examined nothing. Give it a value — deleting it is not the remedy, since absent is the same gate-off. |
| `config key(s) written in the wrong form` | A list key set to a scalar (`strict_paths: src`), or a scalar key set to `  - items` (`doc_soup:`). Read by nobody in either direction. |
| `config key(s) with a commented-out item` | `  - # make test` remains an item whose value starts with `#` — the `#` is stripped from a value only when whitespace precedes it, and the dash strip removed that. For a command key the shell reads it as a comment, so the step runs nothing and reports success. |
| `config key(s) with an item that has no value after its '-'` | Dropped by every reader, so the list that takes effect is shorter than the one written. |
| `strict_paths names no path` | It is the entire scope of the source scan. With none, a reference to an ID nobody defined is never looked for and the run exits 0 having examined no code. |
| `id_prefixes names no prefix with a traceability gate` | At least one of REQ, HAZ, RC, SDD, LLR, PR must appear. Extra prefixes alongside them are fine — `DANGLING-REF`, `DUPLICATE-ID` and ID finalization are keyed on the whole prefix list, so they are checked, just not by a gate of their own. Without any of the six the only checks left are those, and a config that also omits the document keys runs nothing at all. |
| `id_prefixes declares RC but doc_srs is not configured` | A declared prefix needs the documents its gates READ, which is not always where it is defined: `UNIMPLEMENTED-CONTROL` looks for a REQ that implements each RC, so RC needs `doc_srs`. |
| `id_prefixes declares RC but doc_rmf is not configured` | A prefix also needs the one document it may be DEFINED in, because `MISPLACED-ITEM` reads it. A control lives in the RMF, so `RC` needs `doc_rmf` as well — unconfigured, every control in the project would be misplaced. |
| `id_prefixes declares REQ/LLR but test_paths is empty` | Nothing would be searched for `verifies:`. |
| `strict_paths entry matches no file present in the working tree: src/*.rs` | A `strict_paths`/`test_paths` entry matching nothing. These are **git pathspecs** — a plain path, or a pattern like `*_test.sh` that git matches recursively. An entry matching nothing scans nothing, and an empty directory matches no file. |

Fix the config; never work around it by removing the prefix.

## Fixing each rule

| Rule | Meaning | Fix |
|---|---|---|
| `MISSING-TEST REQ-…` | No direct `verifies:` test AND no tested LLR `satisfies:` it | Write the test (`develop-change`) at the lowest level that exists — LLR where there is one, else the REQ. If the REQ is untestable as written, sharpen it via `grill-requirements`. Never annotate a test that doesn't actually verify the behavior. |
| `MISSING-TEST LLR-…` | No test is annotated `verifies:` for this low-level requirement | Write the unit test at the software item's own interface (`develop-change`). |
| `UNSATISFIED-LLR LLR-…` | LLR has no `satisfies:` naming a REQ and isn't marked derived | Add the parent REQ trace, or mark `satisfies: derived` and get it assessed via `analyze-risks`. |
| `UNANALYZED-DERIVED <ID>` | Derived REQ/LLR that no `assesses:` line in the RMF names. A mention — the ID in a verification table, a scope note, a parenthetical — is not an assessment and does not count | Run `analyze-risks`: assess hazard impact under the RMF's derived-requirements heading and put `assesses: <ID>` on its own line in that passage. Several items may share one line. |
| `UNMITIGATED-HAZARD HAZ-…` | No risk control `mitigates:` this hazard | Run `analyze-risks` for this hazard; add the RC (or record the acceptability rationale and control in the RMF). |
| `UNIMPLEMENTED-CONTROL RC-…` | No requirement `implements:` this control | Grill the control into a testable REQ (`grill-requirements`); for non-software controls, note the external implementation in the RMF item and add the implementing REQ only if software plays a part. |
| `UNTRACED-DESIGN SDD-…` | Design item has no `traces:` to a REQ | Add the trace if the requirement exists; if none does, the item is speculative — delete it or grill the requirement into existence first. |
| `DANGLING-REF <ID>` | ID referenced but defined nowhere | Typo → fix the reference. Deleted item → remove or update every reference (deleting a defined item is a change requiring its own review). |
| `DANGLING-FILE <file>` | A `DRAFT-*.md` ledger file referenced in a ledger (or the SOUP file) — by path or bare name — that does not exist. Usually a draft another change already merged and renamed, or a draft in another unit; or a relative link (`../risk/DRAFT-x.md`), which resolves while the draft exists but which finalize does not rewrite, or a name wrapped in emphasis or glued to a longer word, which finalize also leaves; `finalize-docs.sh` rewrites the references it can see, and this is the rest. Plans and verification records are not scanned: they narrate the rename | Write the merged file's dated name. Never delete the reference to satisfy the gate — the sentence points somewhere for a reason. A reference to a draft that exists is fine — that is every change in flight — with one edge: a bare name resolves against this unit's ledger directories only, so across units write the path. |
| `MISPLACED-ITEM <ID>` | Item defined outside the document configured for its prefix. It is still *enumerated* — `MISSING-TEST` and the rest fire on it exactly as on a placed item — but the gate that would report it on its own annotations parses only the configured document, so a misplaced `SDD` has no `traces:` obligation and a misplaced `PR` can never be reported open. Two caveats worth knowing: `DANGLING-REF` scans every `doc_*` file plus `strict_paths` and `test_paths`, so an item misfiled into *another* ledger still has its reference IDs read — by that gate, not by its own; and a `HAZ` block contains no annotation of its own that a gate parses, yet moving it out of the RMF still blinds `UNANALYZED-DERIVED`, which reads `assesses:` lines in the RMF files alone — an assessment inside a hazard's block stops counting when that block leaves (it fails red, so nothing passes silently) | Move the definition into that document — `REQ`→`doc_srs`, `HAZ`/`RC`→`doc_rmf`, `SDD`/`LLR`→`doc_sad`, `PR`→`doc_problems`. Adding the stray file to `strict_paths` does **not** fix it: that widens reference scanning, not the document a gate opens. A `doc_*` directory resolves to its `*.md` files **one level deep**, so a `.md` in a subdirectory of it reports — and so does a `.txt` directly in it. A `doc_*` configured as a single *file* resolves to that file whatever its extension. If the ID is illustrative text rather than a real item, indent it or keep it inline — no definition scan matches a form off column one. Do **not** leave `**REQ-NNN**:` at the start of a line: no gate reads it as a definition, but `MALFORMED-ID` reads it as one that failed, which is the correct answer to a line that looks exactly like a real item. |
| `ORPHAN-ANNOTATION <file>:<line>` | A `status:`, `opened:`, `disposition:`, `traces:`, `satisfies:`, `supersedes:` or `superseded-by:` line — and under a unit manifest `exported:` and `expects:` — at column one — or at column one after one or more list markers, bulleted (`-`, `*`, `+`) or ordered (`1.`, `1)`) — that belongs to no item. Three ways: before the first item in the file; under a heading with no item since; or **inside a block opened by a prefix whose gate does not read that keyword** — a `traces:` line inside an `**LLR-…**` block, say — which is the one most likely to reach a real ledger. Nothing reads it in any of the three: the gate keyed on that keyword parses item blocks of its own prefix, and this line is in none, so `status: open` left an item open in the ledger while the run exited 0. Reported only where the keyword is block-parsed (`status:`/`opened:`/`disposition:`→`doc_problems`, `traces:`→`doc_sad`, `satisfies:`→`doc_sad`/`doc_srs`, `supersedes:`/`superseded-by:`→every ledger); `mitigates:`, `implements:`, `verifies:` and `assesses:` are read line-wise and cannot be orphaned. This backstop is deliberately WIDER than every reader — it reports, it takes no value — so a list-item line is reported here even though no gate would have read it | Move the line inside the item it describes, and drop the list marker while you are there: a list-item annotation is never read, so inside a block it leaves the field missing. For the third case, being under the wrong item is the usual cause, so check which item you meant. If a heading separates them, put the heading before the item or drop it. If the line is illustrative rather than real, indent it with no list marker, or keep the form inline in backticks: it is the absence of a MARKER, not the indentation, that keeps the grammar comments in the ledger templates inert. |
| `UNRESOLVED-PR PR-…` | Open problem report (**warning — never fails on its own**). The line contains the item's age, so the list can be triaged rather than scrolled past | Review it: still valid? Fix via `resolve-problem`, or leave open knowingly — the point is that every merge sees the list. |
| `ACCEPTED-PR PR-…` | A problem report with `status: accepted` — one the project investigated and ruled on, deciding the software is not changing (**warning — never fails on its own**). The line prints the `opened:` date and the `disposition:`, which is the ruling itself. An accepted item is exempt from `STALE-PROBLEM` and from `problem_open_max`, because neither limit measures anything about a decision, but it is never exempt from this roll-call: a decision nobody is reminded of decays back into a thing nobody remembers deciding. The `disposition:` is what makes the status safe to have — without it, `accepted` would be a one-word escape from both limits, so an accepted item with no `disposition:` — or no `opened:` — is `INCOMPLETE-PROBLEM`, and its date is judged exactly as an open item's is | Read the ruling on the line and decide whether it still stands. If it does, nothing. If it does not, reopen the item (`status: open`) or fix it under `resolve-problem`. Never reach for `accepted` because `PROBLEM-BACKLOG` is red — the honest moves there are a ruling with a date you can defend, or resolving the item; `resolve-problem` §4 has the form. |
| `INCOMPLETE-PROBLEM PR-…` | A problem report with no column-one `status:` in its block, or an **open** one with no `opened:` (a keyword with an empty value counts as absent). A **list-item** `- status: open` — or `1. status: open` — is not a status: readers are column-one only, and a list-item one inside a block is reported here rather than read, because reading it would let a quoted example outrank the item's own annotation. Without a status the item is not merely unlabelled — it reads as resolved and vanishes from the roll-call, which is why this fails rather than warns | Add the field at column one inside the item's block, with no list marker. `opened:` is `YYYY-MM-DD`. A resolved item needs no `opened:`, so an existing ledger only has to backfill the items still open. |
| `MALFORMED-STATUS PR-…` | `status:` whose value is not one of `open`, `accepted` or `resolved` — the three the gate reads, and the three its message names. `closed`, `wontfix`, `Open` and `open (see below)` are all reported here | Pick one of the three, and pick it for what it means: `open` for a problem still to answer, `accepted` for one the project investigated and ruled on (which then needs a `disposition:` — see `ACCEPTED-PR`), `resolved` for one a change has fixed. An unrecognised status is not a fourth state — it is an item no gate can classify, and before this check it counted as resolved. |
| `MALFORMED-DATE PR-…` | An open item's `opened:` is not a `YYYY-MM-DD` calendar date, or is **more than one day ahead of today**. A future date yields a negative age, which compares as younger than any limit. **Tomorrow is allowed** and counts as 0 days old: `resolve-problem` tells the author to write *today*, and "today" differs by a day across timezones, so without that tolerance an author east of the build blocked their own merge on a correct item | Fix the date. If the clock or the timezone is more than a day out, fix that — the age is computed in local time from `date +%Y-%m-%d`. |
| `STALE-PROBLEM PR-…` | Open longer than `problem_age_days` (strictly more than; the limit itself passes) | Three answers, not two: resolve it; rule on it as `status: accepted` with a `disposition:`, which exempts the item from both problem limits and never from the roll-call; or raise the limit deliberately in `.guardrails/config.yaml`. All three are decisions; leaving it open silently was the option this removes. The middle one is the answer when the item is real, its fix is not this change's, and the merge in front of you is not where that fix gets made — see `resolve-problem`, which requires the ruling before granting the exemption. |
| `PROBLEM-BACKLOG (n open…)` | More open problem reports than `problem_open_max` | The same three choices, and `status: accepted` with a `disposition:` is the one that fits a backlog this change did not create: an accepted item does not count toward the limit, and still appears in the roll-call. Note the count includes items that are open but undatable — a ledger cannot reduce its backlog count by omitting a field. It EXCLUDES items whose status could not be read at all: the gate does not guess an unstated status, so the count can under-report, but only on a run already red for that item. |
| `NON-RECIPROCAL-SUPERSESSION <ID>` | Half a supersession: `supersedes: <old ID>` on the replacement with no `superseded-by: <new ID>` back on the replaced item, or the mirror of that. This is the pair `merge-change` step 6a prescribes, and ONLY that pair. Both annotations are lists, so one item may replace several predecessors, and each predecessor is judged on its own — one applied half never answers for a missing one. It is deliberately not a sweep for other references to a superseded ID: an `affects:` or `traces:` line may name an old ID as history, so there is no unambiguous verdict there and none is invented, and whether the named ID exists at all is `DANGLING-REF`'s question | Add the missing half, at column one inside the named item's block. Never delete the half that is present to quiet the gate: the annotation already written is the true one, and deleting it destroys the only record that the replacement happened. If the two IDs are not really a replacement pair, remove BOTH and state the relationship in prose instead. |
| `MALFORMED-SUPERSESSION <ID>` | A `supersedes:` or `superseded-by:` at column one inside an item block whose value gives the reader no item ID (the empty value included), or whose list mixes a token in a declared prefix that is not an ID in among ones that are. `supersedes: the original dosing requirement` is prose, not a reference, and `supersedes: REQ-m7dq3v, REQ-nope` records half of what it appears to; before this report, each read as no supersession at all while the run exited 0, so a value the reader cannot use is reported rather than quietly dropped. Prose and a parenthetical after the list end it and are never reported — `supersedes: REQ-m7dq3v (was REQ-001)` is clean | Write the ID the annotation means. This is the reference-side twin of `MALFORMED-ID` and takes the same remedy: find the real item and name it, and never widen the form to accept the token that is there. An annotation with nothing after it is the same fix — give it the ID, or delete the line if no supersession happened. |
| `DRAFT-ID …` (check-ids) | A draft ID token (`REQ-DRAFT-<branch>-<n>`) left in the tree. **Always a failure**, under every flag: nothing mints one any more, so nothing would ever turn it into a real ID | Run `.guardrails/scripts/new-id.sh <PREFIX>` and replace the token with what it prints. |
| `DRAFT-FILE …` (check-ids) | A `DRAFT-<branch>-<slug>.md` ledger file. Legitimate while the change is in flight — `--allow-draft-files` suppresses it — and renamed by `finalize-docs.sh` at merge | Nothing mid-change. At merge, run `merge-change` step 3. |
| `DUPLICATE-ID <ID>` (check-ids) | One ID defined at two sites in the tree | Keep one definition and mint a fresh ID for the other. Two random tokens colliding is possible but vanishingly unlikely; a copy-pasted item is the usual cause. |
| `MALFORMED-ID <ID>` (check-ids) | A line opening with a definition form whose body is not a valid ID — a hand-typed token with no digit, or a legacy ID too short to have ever matched. The item it announces defines nothing and no gate is keyed on it, so every other check passes over it in silence | Give the item an ID from `new-id.sh`. Never widen a pattern to accept the one that is there: the whole point of the digit and the six-character length is that ordinary prose cannot be mistaken for an ID. |

## When to run

- After any edit to SRS/RMF/SAD/SOUP or to tests.
- Always inside `verify-before-merge` and `merge-change` (without
  `--allow-draft-files` at the merge — no ledger file with a draft name may
  reach the base branch).
- In CI on every merge.
