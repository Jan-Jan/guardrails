# Out-of-force items Implementation Plan

**Goal:** a superseded or retired REQ or LLR owes no test, so a supersession needs one red-first test for the new item and no re-annotation of a green one; `verify-before-merge` check 4 and the supersession rule stop contradicting each other.
**Implements:** none. No item is claimed or amended: the toolkit keeps no REQ ledger of its own. Delivers D1 to D7 below; resolves PR-kzst5n.
**Safety class:** unclassified (the toolkit has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`; `check-ids.sh` and `check-trace.sh` against scratch copies of `main` and of the change, criterion no finding that `main` lacks.

Decided 2026-10-08 with the maintainer, on a class C adopter's report
(PR-kzst5n): "if a REQ has been superseded there should be no test for it".
The old rule (the superseded item keeps its test, which gains the new ID)
rested on "no gate has to change", written when no script read
`supersedes:`/`superseded-by:`. Since PR-zt5c2v the pair is checked
(`NON-RECIPROCAL-SUPERSESSION`, `MALFORMED-SUPERSESSION`), so a gate can key an
exemption on it without the exemption being writable by one half alone.

## Decisions

- **D1 (2026-10-08): an item is out of force** when its block contains a
  column-one `superseded-by:` naming a REQ or LLR whose block names it back
  with `supersedes:` (the reciprocal pair; amended 2026-10-08 on T1's
  report, since plan test 3 needs a one-sided `superseded-by:` to exempt
  nothing), or a well-formed column-one `retired:` (D5). (amended
  2026-10-08 on review round 3 finding-1: the chain must terminate in an
  item in force or validly retired; a self-pair or a cycle exempts nothing
  and is MALFORMED-SUPERSESSION) (ruled 2026-10-08 on review round 4
  finding-4: an item superseded by two successors, one terminating and one
  in a cycle, is out of force, since it has a successor in force; only the
  cycle's members are reported) Only REQ and LLR items are read for this; the
  exemption is from `MISSING-TEST`, which only those two prefixes owe. Block
  parsing and column-one reading are the ones the supersession scan uses
  (`GR_AWK_ITEM_BLOCK`, `gr_kw_here`, `gr_id_run`).
- **D2 (2026-10-08): `MISSING-TEST` skips an out-of-force REQ or LLR.** The
  exemption cannot be taken by writing one line: a `superseded-by:` with no
  reciprocal `supersedes:` is `NON-RECIPROCAL-SUPERSESSION`, an undefined
  successor is `DANGLING-REF`, an unreadable value is
  `MALFORMED-SUPERSESSION`, and a `retired:` must carry a date and a reason
  (D5). The successor is an ordinary item and owes its own test.
- **D3 (2026-10-08): an out-of-force item discharges nothing.** A tested LLR
  that is out of force does not cover the REQs its `satisfies:` names, and an
  `implements:` inside an out-of-force REQ's block does not implement the RC
  it names (extended 2026-10-08 on review round 2 finding-2: an
  out-of-force exported REQ meets no `expects:`). Without this, retiring the only REQ that implements a risk control
  leaves `UNIMPLEMENTED-CONTROL` green on a control no test verifies any
  longer: before this change the retired REQ still owed a test, after it
  nothing does. `traces:` on an SDD and `mitigates:` on an RC are unchanged:
  neither is a test obligation, and a reference naming an old ID as history
  stays a review job (merge-change review checklist).
- **D4 (2026-10-08): a `verifies:` line that names only out-of-force items
  fails** as `OUT-OF-FORCE-VERIFIES <file>:<line> (verifies: names only
  out-of-force items: <IDs>)`, IDs space-separated in the order written. It
  fires only when every ID on the line is out of force (clarified 2026-10-08
  on T1's report: `verifies: PR-x, REQ-old` is silent); a line that names any
  in-force ID beside an out-of-force one is history and is silent, so a tree that followed the old dual-ID rule
  stays green. Remedy: delete the test, or point it at the item in force and
  record it under check 4 as inherited (D6).
- **D5 (2026-10-08): the retirement form** is a column-one
  `retired: YYYY-MM-DD — <reason>` in the REQ or LLR block. The date is a
  real calendar date at most one day ahead (the rule `opened:` uses); the
  reason is any non-blank text after the date and its separator (`—`, `-`,
  `:` or whitespace). `MALFORMED-RETIREMENT <ID> (retired: <value> — needs a
  YYYY-MM-DD date and a reason)` otherwise, including the empty value. An item
  carrying both `retired:` and `superseded-by:` is `MALFORMED-RETIREMENT <ID>
  (retired: and superseded-by: <IDs> — an item is retired or superseded, not
  both)`. (ruled 2026-10-08 on review round 4 finding-4: such an item is
  not out of force even where its `superseded-by:` is reciprocated; a
  malformed retirement retires nothing, so it owes its test and
  `MISSING-TEST` fires if it is untested.) A `retired:` outside any REQ or
  LLR block is `ORPHAN-ANNOTATION`
  (`check_orphans 'retired:' 'REQ|LLR'` over the SRS and SAD files; scoped
  2026-10-08 on review finding-2: a `retired:` in any other ledger, on an RC,
  HAZ or PR, retires nothing and is not reported). Retire
  when the behavior is gone with no successor; supersede when a successor
  states what the behavior became, a reversal included.
- **D6 (2026-10-08): check 4 reads per ID, and an inherited test is named as
  such.** Every Implements ID needs at least one `verifies:` test with a
  `red -> green:` attestation. A pre-existing test that verified a superseded
  predecessor and is pointed at its successor is allowed when the dispatch
  report and the verification record list it as
  `inherited: <test name> — from <old ID>`; it is coverage, never red-first
  evidence. Any other unattested `verifies:` test of an Implements ID still
  fails the check, and "never re-annotate a test that was green from the
  start" stands for every test that is not inherited from a predecessor.
- **D7 (2026-10-08): the skills state one rule.** `grill-requirements`
  (Supersession section, red flag, Done when) and `references/supersession.md`,
  `merge-change/references/review-checklist.md`, `verify-before-merge` check 4
  and `references/rationale.md`, and `develop-change`'s dispatch report form
  state D1 to D6. The dual-ID `verifies:` instruction is removed everywhere.
  `ratchet/references/upgrade-notes.md` gains an entry for the two new rules.

## Tasks

### T1 — `check-trace.sh` reads out-of-force items

**Files touched:** `scripts/check-trace.sh`, `tests/check-trace.bats`,
`tests/remedies.bats` if it enumerates rules.
**Parallel:** yes, with T2 (disjoint files).

Implement D1 to D5 in `scripts/check-trace.sh`: header roster entries for
`OUT-OF-FORCE-VERIFIES` and `MALFORMED-RETIREMENT`, the `ORPHAN-ANNOTATION`
roster entry gains `retired:`, a `check_trace_remedy` line for each new rule,
and a rewrite of the MISSING-TEST, UNIMPLEMENTED-CONTROL and REQ-coverage
blocks. One block-parse pass over the SRS and SAD files yields the out-of-force
set and the `MALFORMED-RETIREMENT` lines; keep the awk status (no
`awk | sort` pipeline), never pass a newline-bearing value to `awk -v`, and
open `case` patterns with `(`. Existing tests that assert the old behavior
("superseded-by: exempts nothing") are updated in the same commit with their
names changed to say what they now assert.

Tests, each written first and watched failing for the right reason, each
annotated `# verifies: D<n> (docs/plans/2026-10-08-out-of-force-items.md)`:

1. a superseded REQ with a reciprocal pair and no test is not MISSING-TEST (D2);
2. a superseded LLR with a reciprocal pair and no test is not MISSING-TEST (D2);
3. a `superseded-by:` with no reciprocal `supersedes:` still reports
   MISSING-TEST for the untested item and NON-RECIPROCAL-SUPERSESSION (D2);
4. a retired REQ with a valid form and no test is not MISSING-TEST (D2, D5);
5. a REQ covered only by a tested out-of-force LLR is MISSING-TEST (D3);
6. an RC implemented only by an out-of-force REQ is UNIMPLEMENTED-CONTROL (D3);
7. a `verifies:` line naming only a superseded item is OUT-OF-FORCE-VERIFIES
   with file and line (D4);
8. a `verifies:` line naming a superseded item and its successor is silent
   (D4, scope control: may be green first; record it as such, not attested);
9. `retired:` with no date, with an impossible date, with a date two days
   ahead, and with a date and no reason are each MALFORMED-RETIREMENT (D5);
10. `retired:` beside `superseded-by:` in one block is MALFORMED-RETIREMENT
    (D5);
11. an orphaned `retired:` is ORPHAN-ANNOTATION (D5);
12. a `retired:` in an SDD block does not exempt anything and is
    ORPHAN-ANNOTATION (D1, D5).

### T2 — the skills state one rule

**Files touched:** `skills/grill-requirements/SKILL.md`,
`skills/grill-requirements/references/supersession.md`,
`skills/merge-change/references/review-checklist.md`,
`skills/verify-before-merge/SKILL.md`,
`skills/verify-before-merge/references/rationale.md`,
`skills/develop-change/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`,
and `tests/skills.bats` for the test below.
**Parallel:** yes, with T1.

Rewrite per D7. `supersession.md` states why the old rule existed, why the
checked pair now carries the exemption, the supersede-or-retire choice with
the reversal example from PR-kzst5n, and D3. Keep each SKILL.md inside the
2,000-word limit and its section order.

Test, written first and watched failing:

*(Code pruned at merge: 5 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/grill-requirements/references/supersession.md`, `skills/merge-change/references/review-checklist.md`, `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `skills/develop-change/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`, and `tests/skills.bats` for the test below.)*

## Red -> green

T1 (7a9c932):

red -> green: a superseded REQ with a reciprocal pair owes no test — MISSING-TEST REQ-w9hk3p printed
red -> green: a superseded LLR with a reciprocal pair owes no test — MISSING-TEST LLR-w9hk3p printed
red -> green: a retired REQ owes no test — MISSING-TEST for REQ-w9hk3p and REQ-k2vt8n
red -> green: a tested out-of-force LLR covers no REQ — exit 0, no MISSING-TEST REQ-k2vt8n (covered through the superseded LLR)
red -> green: an RC implemented only by an out-of-force REQ is unimplemented — no UNIMPLEMENTED-CONTROL RC-r5jw4h
red -> green: a verifies: line naming only a superseded item is reported with its file and line — exit 0, no OUT-OF-FORCE-VERIFIES line
red -> green: a retired: with no date, a bad date, a far date or no reason is malformed — no MALFORMED-RETIREMENT (only MISSING-TEST lines)
red -> green: retired: beside superseded-by: in one block is malformed — no MALFORMED-RETIREMENT
red -> green: an orphaned retired: is reported — exit 0, no ORPHAN-ANNOTATION
red -> green: a retired: in an SDD block retires nothing and is an orphan — MISSING-TEST LLR-k2vt8n present, ORPHAN-ANNOTATION absent
red -> green: an unreadable architecture ledger fails the out-of-force scan — run against HEAD's script, which never printed "out-of-force scan failed"

Scope controls, green before the implementation and not attested: "a verifies:
line naming a superseded item beside its successor is silent", "a
superseded-by: with no reciprocal supersedes: exempts nothing", "an
unreadable risk ledger fails the orphan scan" (takes over the orphan scan's
unreadable-file coverage, now that the out-of-force scan opens the SAD first).
T1 removed a separate `# verifies: REQ-w9hk3p` line from eight existing
supersession fixtures, which D4 now reports. Measured on BWK awk 20200816
only; gawk, mawk and busybox awk are not installed on the dispatch host.


T2 (0268933):

red -> green: skills: no skill tells a superseded item's test to carry both IDs — watched fail for the right reason before the implementation existed (grep matched grill-requirements/SKILL.md:101 and :181, references/supersession.md:21, merge-change/references/review-checklist.md:38)

T2 also re-aimed `merge-change: text the first rewrite lost is stated again`
from the removed phrase `exempts nothing from` to `The successor has its own
test`, and placed `inherited:` lines below the Red -> green table of
`templates/verification.md` (D6 named no place).

Gate round 1 fixes (4469ef9): three pins in `every gr_def_re call site is
still a call site, and no copy joins them` (tests/check-ids.bats) re-pinned for
the out-of-force scan's shared-fragment uses (`GR_ID_BODY` 9,
`GR_AWK_ITEM_BLOCK` 7, `GR_AWK_CIVIL` 4); red at each pin in turn, green after
the third.

reddened: skills: check 4 reads per ID and names an inherited test as coverage — verifies: D6; written after the prose, so green when written; each of its nine statements mangled in turn and the test went red on each, with its own message (mutation-reddened, not red-first)

Review round 1 fixes (dd0316e), each mutation-reddened, not red-first: the
mutant was applied, the test run alone went red, the script was restored.

reddened: check-trace: a retired: date running straight into its reason is malformed — verifies: D5; with the separator check deleted the run exited 0
reddened: check-trace: the first retired: in a block is the one read — verifies: D5; with `!ret_seen` dropped the valid second line won and nothing was reported
reddened: check-trace: an implements: in the architecture ledger does not keep a control implemented — verifies: D3; with `in_srs &&` dropped the SAD line counted and the run exited 0
reddened: check-trace: doc_srs and doc_sad on one directory report a malformed retirement once — verifies: D5; with the dedupe guard dropped MALFORMED-RETIREMENT printed twice

Review round 2 fixes (7adbc75, 2202f36, c7b13a1, c1cb36c), after the base
merge of `b4484b8`:

red -> green: check-trace: a retired: in a later ledger file's front matter retires nothing — exit 0, no MISSING-TEST REQ-k2vt8n
red -> green: check-trace: a retired: opening a later ledger file belongs to no item — ORPHAN-ANNOTATION printed but no MISSING-TEST REQ-k2vt8n
red -> green: check-trace: a superseded-by: in a later ledger file's front matter completes no pair — exit 0, no NON-RECIPROCAL-SUPERSESSION
red -> green: check-trace: an out-of-force exported REQ meets no expectation — the consumer printed MISSING-TEST REQ-e7x2m4 and no UNMET-EXPECTATION
reddened: check-trace: a retired: with a date and a bare separator is malformed — verifies: D5; exit 0 under M9 and under M10
reddened: check-trace: a valid retired: beside a one-sided superseded-by: exempts nothing — verifies: D5; MISSING-TEST gone under M12
reddened: check-trace: an implements: in a gitignored requirements file implements nothing — verifies: D3; exit 0 under M14

Front matter is not skipped by the out-of-force scan (finding-1): after the
file-boundary reset no front-matter line reaches a block, and a skip would
drop a front-matter `implements:` from the block pass while the line-wise
reader still counts it. The reason is in a comment beside the reset.

Review round 3 fixes:

red -> green: check-trace: an item that supersedes itself owes its test and is reported — exit 0, no MISSING-TEST REQ-w9hk3p
red -> green: check-trace: two items superseding each other both owe their tests and are reported — exit 0, no MISSING-TEST for either
red -> green: check-trace: a retired REQ and a gitignored requirements file do not implement a control between them — exit 0, no UNIMPLEMENTED-CONTROL RC-r5jw4h
reddened: check-trace: an exported REQ superseded by a provider LLR meets no expectation — verifies: D3; red under `_psad=""` and under `cfg_get doc_srs` in gr_unit_doc_files
reddened: check-trace: a provider whose doc_sad does not exist fails the consumer's run — verifies: D3; red under the same two mutants

Scope controls, green before the implementation and not attested: "a chain
of supersessions ending in a tested item in force is silent", "a
supersession ending in a retired item is silent", and "a provider whose
doc_srs does not exist fails the consumer's run" (the pre-existing behavior
the doc_sad case matches). The cycle report names the item and every item
its chain reaches, so an item leading into a cycle is reported with the
cycle's IDs. `oof_scan` now drops the files git ignores (finding-3); the
per-RC intersection in UNIMPLEMENTED-CONTROL is kept for the binary-file
difference only, and its mutant survives every test (no binary-ledger
fixture).

Review round 4 fixes (b08be6d, 4b672de, d19c02f):

red -> green: check-trace: a config with no requirements or architecture ledger runs the out-of-force scan on nothing — exit 2, "fatal: no path specified" and "out-of-force scan failed" (an error-path regression test, no verifies: line; main exits 0)
red -> green: check-trace: a retired item with a reciprocal superseded-by: stays in force — MALFORMED-RETIREMENT printed but no MISSING-TEST REQ-w9hk3p
red -> green: prune: a fence holding only an inherited: line keeps its fence — "pruned docs/plans/2026-01-01-x.md: 1 block, 1 line"
reddened: check-trace: a supersession cycle of tested items fails the run on its own — verifies: D1; with `fail=1` dropped after `print_violations "$_cycles"` the run exited 0
reddened: check-trace: an item leading into a supersession cycle is reported with every ID sorted — verifies: D1; with the insertion sort made a no-op BWK awk printed `REQ-t6gm2s REQ-k2vt8n`

Scope control, green when written and not attested: "an item superseded
into both a terminating chain and a cycle is out of force" (finding-4b,
current behavior). The cycle message now reads "no successor in force or
retired", the rule it applies; the two tests asserting it were updated. The
round 3 reddened line above for "a provider whose doc_sad does not exist
fails the consumer's run" names D3; that test is now an error-path test
with no verifies: line, as its doc_srs twin is.

## Follow-ups outside this change

- No form retires an SDD. An SDD owes no test, so D2 does not need one; a
  stale SDD is a review finding today.
- `check-review.sh` does not read `inherited:` lines; D6 is checked by the
  dispatcher reading the record.
- `merge-change/SKILL.md` is at 2,000 of 2,000 words.
