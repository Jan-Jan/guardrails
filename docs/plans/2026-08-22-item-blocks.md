# Item Blocks: One Definition of Where an Item Ends

**Goal:** an item's block ends at the next *item*, not at the next bold line,
and an annotation that falls outside every block is reported rather than
discarded. One shared rule, consumed by all five gates that need it.
**Implements:** no REQ IDs — guardrails is not yet a guardrails project
(`docs/plans/2026-08-22-ratchet-gap-analysis.md`, tooth 3). The plan and the
verification record are the trace.
**Safety class:** A (`docs/adr/2026-08-22-safety-class.md`). Held to the
project's own standard: every behaviour change gets a test watched to fail
first, and every production hunk gets a mutation row.
**Verification:** `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` — all green,
plus the mutation table in the verification record.

## Why

`check-trace.sh` decides which lines belong to an item with this rule, written
out four times:

```awk
/^\*\*/ && $0 !~ defre { flush(); cur = "" }
```

Any line beginning with `**` ends the current item. A definition form ends it
correctly; an **emphasised sentence in the item's own body** ends it too, and
everything after that line — including the item's annotations — is attributed
to no item and silently dropped.

Reported by a class B project running guardrails 0.1.0 in production
("Where the Gates Leak", addendum 2026-08-21), against `UNRESOLVED-PR`. The
reporter found it only because a reviewer counted the warnings.

### Measured, not estimated

A fixture repo with one affected item and one control item per gate, run
against the shipped scripts at `5dabcd0`:

```
docs/problems/2026-08-22-a.md
  **PR-a3k9z2**: The exporter drops rows.
  **21 of 35 inverted, 14 not.**          <- terminates the item
  status: open

  **PR-b4m8p3**: Control item, no emphasised line in its body.
  status: open
```

```
$ sh .guardrails/scripts/check-trace.sh
UNANALYZED-DERIVED REQ-d6p8r5 (derived item not assessed in the RMF)
UNRESOLVED-PR PR-b4m8p3 (open problem report — review before release)
checked: REQ 2, HAZ 0, RC 0, SDD 1, LLR 1, PR 2
```

`PR-a3k9z2` is open in the ledger and absent from the output. `REQ-c5n7q4` is
marked `satisfies: derived`, is assessed nowhere in the RMF, and is absent too.
Both controls fire. `checked:` counts all four.

### The defect is one rule and four gates, failing in both directions

| Gate | Effect of a bold line in the item body | Direction |
|---|---|---|
| `UNTRACED-DESIGN` | Fires despite a correct `traces:` | Loud **false positive** — a correct document is rejected |
| `UNSATISFIED-LLR` | Fires despite a correct `satisfies:` | Loud **false positive** |
| `UNANALYZED-DERIVED` | Item stops being seen as derived; never checked against the RMF | **False green** |
| `UNRESOLVED-PR` | Open item vanishes from the known-problem list | **False green** |

Only the `UNRESOLVED-PR` half was reported. `UNANALYZED-DERIVED` is the same
shape and has not been reported by anyone; it is the worse of the two, because
`UNRESOLVED-PR` is a warning by design — its silence loses a warning — while
`UNANALYZED-DERIVED` is a failing gate, so its silence loses a red.

The two loud rows are the same complaint as finding 03 of the same document
(a gate rejecting a correct change and being satisfied by moving a line break),
in its louder form. One rule produces both.

### Why it went unnoticed

The two gates that fail red look like ordinary strictness: an author who hits
`UNTRACED-DESIGN` on an item that plainly carries `traces:` reformats the item
and moves on, and the gate has taught them nothing except that it is fussy.
Nothing in that experience suggests two sibling gates are failing green on the
same input.

## Decisions

Taken with the user, 2026-08-22.

1. **Both fixes, not either.** Terminate blocks at item headers (the fix), and
   report annotations that belong to no item (the backstop).
2. **One shared parser**, extracted into `lib.sh`, rather than the same
   correction applied four times.

### Why both

The feedback offered the two as alternatives and called the second stronger.
They are not alternatives; they cover different halves.

Terminating at item headers makes the reported failure *much harder to write* —
the bold sentence no longer detaches the item's annotations, and all four gates
above are fixed in both directions at once. (The first draft of this paragraph
said *unrepresentable*, and four amendments later that is not true: an
emphasised sentence that happens to carry a colon still closes an item, and
combined with the column-one limit of the backstop it can still cost an
`UNRESOLVED-PR`. Both halves are disclosed in `lib.sh` and the skill; the
overclaim is corrected here rather than left standing.) This is the shape the same feedback
document argues for in its addendum: *make the unsafe thing unrepresentable
rather than guarded; a gate that enumerates attacks loses, a gate that fails
closed converges.*

But every termination rule has an outside. An annotation before the first
definition in a file, or under a `#` heading with no definition since, belongs
to no item under any rule — and today it is discarded in silence, which is the
same failure with a different cause. `ORPHAN-ANNOTATION` fails closed on
exactly that residue. Without it the fix is unrepresentable-in-the-common-case
and silent-in-the-rest, which is how this defect was born.

### Why one shared parser

The rule is currently hand-copied four times, and that is not incidental to the
defect — it is the defect's shape. `lib.sh` already argues this case against
itself, in the `GR_AWK_ID_RUN` comment:

> One definition is the point. Three near-copies of this rule is how `traces:`
> came to demand a REQ at the head of its run while `satisfies:` scanned from
> the LAST occurrence on the line and credited a REQ mentioned in prose.

`gr_def_re()` carries the same argument for definition forms, and names the
third reader — the old `finalize-ids.sh` — as the one that drifted.

After this change there are **five** consumers of the block rule, not four, so
the cost of a fifth opinion goes up rather than down. `ORPHAN-ANNOTATION` in
particular must agree with the four gates about where a block ends, or the
backstop is merely adjacent to the thing it backs.

The counter-argument considered and rejected: the four gates genuinely differ
in what they extract from a block (LLR accumulates a `satisfies:` list, SDD
wants a boolean, PR wants a `status:` flag, REQ wants a derived flag), and a
forced-common interface can be worse than the duplication. They differ only in
*what they extract*, never in *where blocks start and end* — so the shared part
is exactly the part that is identical, and each gate keeps its own extraction.

## Design

### The block rule

A block **opens** at a column-one definition form for any declared prefix —
`gr_def_re "$P"`, the existing single definition of that string.

A block **closes** at whichever comes first:

* the next column-one definition form for any declared prefix;
* a markdown heading (`^#`);
* end of file.

Nothing else closes a block. A bold line that is not a definition form is
ordinary body text.

Two properties this preserves, both load-bearing and both already argued in the
current code:

* **Heading termination stays.** It was added because an unrelated `traces:`
  far below credited an SDD carrying none of its own. Dropping it would trade a
  silent-green for a different silent-green. With `ORPHAN-ANNOTATION` in place
  it can no longer discard anything quietly: a heading that separates an item
  from its annotation now produces a report rather than a shrug.
* **Indented and blockquoted forms are still inert.** Column-one anchoring is
  what lets the shipped templates carry a grammar example without it becoming
  a live item — `templates/problems.md` indents its `status: open|resolved`
  inside an HTML comment for exactly this reason. Unchanged here, and it is
  what makes `ORPHAN-ANNOTATION` cheap to adopt.

### Amended during implementation: the boundary is loose, the opening is strict

The plan as first written said blocks open *and* close on the strict definition
form, and named the consequence as an acceptable risk:

> a **malformed** definition form (`**REQ-abcdef**:`, no digit) does not match
> `gr_def_re`, so under this rule it reads as body text rather than as a block
> boundary. That is acceptable only because `check-ids.sh` reports it as
> `MALFORMED-ID` and no tree carrying one can merge.

That was wrong, and an **existing test caught it** — `check-trace: open draft PR
does not misattribute to a resolved PR`, whose fixture carries
`**PR-DRAFT-b-1**:`. Under strict-on-both-sides that line stopped closing the
block above it, and its `status: open` was credited to the **resolved**
`PR-001`. The old rule merely dropped such a line; the new one gave it to the
wrong item. A wrong answer, where the defect being fixed produced a missing one.

The first repair attempted was a pre-flight in `check-trace.sh` that refused
(exit 2) any tree containing a definition form it could not read. It worked,
and it was the wrong shape: it made one script's soundness depend on a scan
belonging to another, and it broke two drift tests whose fixtures rely on
malformed forms being inert.

The fix actually taken is an asymmetry:

* **opens** on the strict form — an item whose ID cannot be read is not an item,
  and nothing may be collected under it;
* **closes** on the *loose* form, `**PREFIX-<anything>**:` for any declared
  prefix — so an unreadable header still ends the item above it.

This keeps the pre-2026-08-22 safety exactly where it was earned, needs no
cross-script coupling, and made both drift tests green again without editing
their premises. `check-ids.sh` still reports the line as `MALFORMED-ID`;
`check-trace.sh` no longer depends on it doing so.

`gr_def_re_loose` in `lib.sh` is that pattern, with two consumers: the
`MALFORMED-ID` scan (which previously spelled it out by hand) and the block
rule's closing side.

### `GR_AWK_ITEM_BLOCK` in `lib.sh`

An awk fragment, prepended to every program that needs it, in the same style as
`GR_AWK_ID_RUN`. It exposes the block boundary and the current item ID; each
gate keeps its own accumulation over the block body.

Built **inside** awk from `GR_ID_BODY`, never passed ready-made with `-v` —
awk runs escape processing over a `-v` value, so a pattern carrying `\*` arrives
as a bare `*` and matches nothing at all. This is recorded in the current
`parse_llr_file` comment, measured on gawk 5.3.2, and must survive the
extraction.

### `ORPHAN-ANNOTATION`

Exit 1, a violation rather than a warning. Reported per occurrence, naming the
file, the line number and the keyword.

Scope is per keyword, covering only the documents where that keyword is
block-parsed:

| Keyword | Documents |
|---|---|
| `status:` | `doc_problems` |
| `traces:` | `doc_sad` |
| `satisfies:` | `doc_sad`, `doc_srs` |

`mitigates:`, `implements:` and `verifies:` are read line-wise by
`ids_matching`, never block-scoped, so they cannot be orphaned and are out of
scope. Checking them anyway would report shapes no gate would have read.

Anchored at column one, for the same reason the definition forms are: the
indented grammar comments the ledger templates ship must not fire it.

### Amended again after independent review: the boundary is a header SHAPE

Review round 1 (2026-08-23) returned two blocking findings, both silent losses
of a failing gate. Both came from the same mistake: asking a *boundary* question
through the project's ID vocabulary, which does not know the answer.

**The loose definition form is not the boundary.** `gr_def_re_loose` requires a
declared prefix, an ASCII hyphen, and the colon outside the bold. Three shapes a
reader takes for an item header satisfy none of those, so they became body text
and handed their annotations to the item above:

| Shape | Why it missed |
|---|---|
| `**ADR-0007**:` | prefix not in `id_prefixes` |
| `**LLR-overflow:**` | colon inside the bold |
| `**LLR‑j3u4w2**:` | U+2011 non-breaking hyphen |

The first is a **regression against `main`**, not merely a gap: `main` closed on
any bold line and reported `UNSATISFIED-LLR`; the change did not. Verified
directly against both script sets.

The fix is to close on a **header shape** — a bold run with no whitespace,
carrying a colon just outside or just inside the closing asterisks — and to
open, still, only on a well-formed ID. Whitespace is the discriminator that
survives: an item header is one unbroken token, emphasis is a phrase, and
`**21 of 35 inverted, 14 not.**` from the original report has spaces. Closing is
now keyed on no vocabulary at all, which is what makes it total.

The review proposed instead "close on `^\*\*` unless it is a strict opener".
That is the pre-change rule, and it reinstates the reported defect: the reported
line *was* an emphasised sentence. Rejected on that ground.

**The backstop opened on the wrong prefix.** `check_orphans` opened a block on
any declared prefix while each gate opens only on its own, which left a third
state — *inside another prefix's block* — that the gate does not read and the
backstop does not report. An extra prefix is a supported config and is not
placement-checked, so `**ADR-…**:` in the SRS swallowed a `satisfies: derived`
with both gates silent at exit 0. Fixed by giving `check_orphans` the opening
prefix of the gate that reads each keyword: `status:`→`PR`, `traces:`→`SDD`,
`satisfies:`→`LLR` over the SAD and `REQ` over the SRS.

Also from that review, non-blocking: a leading YAML front-matter block is now
skipped (`status: draft` there is a title-page field, and reporting it failed a
correct ledger); overlapping `doc_*` paths no longer report the same line twice;
`gr_def_re_loose` gained the behavioural pin it lacked — narrowing it alone
reddened nothing, so `check-ids.sh` could have drifted back to a hand-spelled
copy with the suite green.

### Rejected: extending the backstop to list markers

The review noted that the gates match a keyword anywhere on a line while the
backstop matches only column one, so a bullet-style ledger gets a weaker
backstop. Extending the anchor to list markers was implemented and reverted: it
fired on `- status: resolved only in the same change that merges the fix.` in
this project's own `templates/problems.md`, which is prose in a README.
Rewording a correct document to satisfy a scan is the failure this change
exists to remove. The asymmetry is recorded in `lib.sh` and in the skill
documentation as a known limit instead.

### Amended a third time: the colon, not whitespace, and the close must not shrink

Review round 2 found the class open, not the instances. Three more header
spellings still failed to close — `***ADR-0007***:`, `**ADR-0007** :`,
`**Decision 7**:` — two of them red on `main` and green on the branch.

The framing that settles it, and that the first two attempts both lacked:

> The close set must be everything the pre-change rule closed, minus the shape
> that caused the defect. Any other difference is a regression.

The pre-change rule closed on every `^\*\*` line. The reported defect was
`**21 of 35 inverted, 14 not.**` — which carries **no colon**. This amendment
required the colon to *adjoin* the closing asterisks, which was still an
approximation of the rule rather than the rule; round 3 found the gap and it is
recorded below.

**The whitespace exclusion was wrong and is gone.** It was asserted as the
discriminator in the previous amendment. Round 2 showed it was untested —
deleting it reddened no test — and, worse, that it was not load-bearing:
with it removed the reported defect stays fixed, because the colon carries
that. Its stated rationale was false in both directions. `**Decision 7**:` is a
header that is a phrase; `**Note:**` is emphasis that is one token. The cost of
keeping it was the `**Decision 7**:` regression.

Two asterisks minimum is kept, matching the old anchor: widening to one would
close on `*Note*: an aside` and newly reject ledgers that always passed.

The residual limit, now stated in the code and the skill: a bold line with no
colon anywhere does not close, because nothing distinguishes it from the
sentence in the original report.

Also from round 2:

* **The front-matter skip had no bound.** A leading `---` with no terminator —
  a thematic break, a half-deleted block — switched the backstop off for the
  whole file. Now a first pass locates the terminator and a second skips only
  as far as it; with no terminator nothing is skipped. Reporting switched from
  `NR` to `FNR`, since the file is read twice and every line number was
  otherwise offset by a whole pass. A test caught that.
* **`gr_kw_here` was not pinned.** The round-1 poison stub reimplemented it
  faithfully, so `check-trace.sh` could carry a private copy of the column-one
  rule with the suite green. The stub now poisons it to fire on every line, and
  the test asserts a line carrying no keyword is reported.
* **Overlapping `doc_*` paths produced a false positive.** With `doc_srs` and
  `doc_sad` on one directory, the REQ-opening scan called an LLR annotation an
  orphan while the LLR gate read it correctly. There is now one `satisfies:`
  scan over the deduplicated union, opening on `LLR|REQ`. The output
  deduplication that existed only to halve this is gone.
* Comments describing the two abandoned designs were corrected, and four dead
  `-v pall="$P"` arguments removed — they were the vestige suggesting the close
  was still prefix-keyed.

### Amended a fourth time: the rule itself, written down

Round 3 returned the same verdict as round 2 — the class open, the demonstrated
instances closed. The three regex edits of amendment 3 mapped one-to-one onto
round 2's three examples and generalised nothing. Still failing to close, all
with a colon, all closed by the pre-change rule:

```
**PR-b4m8p3** (duplicate of PR-a3k9z2):     text between the bold and the colon
**Note **bold** here**:                     an asterisk inside the bold run
**Decision: seven revisited**               the colon interior to the bold
**ADR-0007**<U+00A0>:                       a non-ASCII space before the colon
****:                                       an empty label
```

The first credits `status: open` to a **resolved** PR — the wrong-answer
failure that amendment 2 was written to prevent, still live after two attempts
at preventing it.

**The finding that ends it.** Round 3 substituted the whole pattern with
`^\*\*.*:` — the governing principle spelled directly — and **no test
reddened**. The suite could not distinguish the elaborate regex from the rule
it claimed to implement, and by that rule every difference between them was a
lost close, hence a regression. Three rounds were spent describing examples
instead of writing the rule down.

The close is now exactly:

```awk
GR_BLOCK_HEAD_RE = "^\\*\\*.*:"
```

Every bold line carrying a colon. `^\*\*` is the pre-change anchor, so the
close set is a strict subset of it by construction and no ledger that rule
accepted can be newly rejected. The colon is the single subtraction, and it is
the one the reported defect requires. The five shapes above are now fixtures,
because they are precisely what the difference contained.

The residual limit, stated exactly rather than approximately: a bold line with
**no colon anywhere on it** does not close.

Also from round 3:

* **Four surviving mutants**, three of them real gaps now pinned: the `...`
  front-matter terminator, the `sort -u` on the union file list, and the
  `status:`→`PR` opening prefix — round 1's per-keyword fix had been pinned for
  `satisfies:` only.
* **CRLF front matter was not recognised**, so a title-page `status: draft` in
  a CRLF ledger became a hard failure. The delimiters now tolerate `\r`.
* **`check_orphans` swallowed its own failure.** An unreadable ledger printed
  an awk error and the run exited 0 — a scan that errors finds nothing, and
  finding nothing is what a clean ledger looks like. It now dies.
* Comments describing the round-1 and round-2 designs were corrected in
  `check-trace.sh` and in a test comment, and the whitespace claim was removed
  from `README.md` and the skill — the third round running in which a review
  found documentation describing an abandoned design.

### The generalisable lesson

Three rounds failed the same way, and it is worth naming because it is not
specific to this parser. Each fix was fitted to the examples the previous round
produced, and each time the fix was *narrower* than the rule it was supposed to
implement. The test that finally exposed it was not another example: it was
substituting the plainly-stated rule for the implementation and observing that
the suite could not tell them apart. Where a change subtracts from existing
behaviour, state the subtraction and implement exactly that — and pin it with a
test that fails when the implementation is narrower than the statement.

## What this changes for a project already running guardrails

**A green tree can go red on upgrade.** That is the intent — the violations
were always there — but it must be stated rather than discovered:

* an open PR item previously invisible now appears in `UNRESOLVED-PR`
  (a warning; does not fail the run);
* a derived REQ/LLR previously invisible now fires `UNANALYZED-DERIVED`
  (**fails**);
* an orphaned `status:`/`traces:`/`satisfies:` now fires `ORPHAN-ANNOTATION`
  (**fails**);
* an SDD or LLR previously reported by `UNTRACED-DESIGN` / `UNSATISFIED-LLR`
  because of a bold line in its body **stops** being reported. Any ledger text
  reworded to appease those two gates can be reverted.

No grace period and no `--warn-only`. The same feedback document argues that a
warning nobody acts on is worse than no warning, because it teaches people the
output is noise; shipping this as a warning first would be that pattern
exactly. The remedy in every case is mechanical — move the annotation inside
its item — and the message names the file and line.

## Test plan

Per `AGENTS.md`, every behaviour change gets a bats test, watched to fail first.

Against the current scripts these must fail; after the change they must pass:

1. an open PR item with a bold line in its body is listed by `UNRESOLVED-PR`;
2. a derived REQ with a bold line in its body fires `UNANALYZED-DERIVED`;
3. an SDD with a bold line before its `traces:` is **not** reported;
4. an LLR with a bold line before its `satisfies:` is **not** reported;
5. a `status:` line before the first item in a file fires `ORPHAN-ANNOTATION`;
6. a `traces:` line under a heading, with no definition since, fires it;
7. an indented `status:` inside an HTML comment does **not** fire it
   (the shipped `templates/problems.md` shape);
8. a definition form for a *different* prefix still closes a block;
9. a markdown heading still closes a block;
10. the block rule has one definition — a test that makes the shared fragment
    inert and requires all five consumers to follow, in the style of
    "poisoning gr_def_re changes every gate's verdict". The four block gates
    are caught by their silence, the orphan gate by its noise;
11. the textual pins in "every gr_def_re call site is still a call site" extend
    to `gr_def_re_loose` and `GR_AWK_ITEM_BLOCK`, and both constructors are
    asserted to exist exactly once.

Regression surface: the existing `check-trace.bats` cases must stay green
unchanged, since they encode the boundaries this keeps.

## Out of scope

* `owner:`/`opened:` on PR items and an `UNRESOLVED-PR` threshold — change 3.
* The review-artefact gate and the verification-record schema — change 2.
* `scan_exclude` and self-hosting — tooth 0, after the leaks.
