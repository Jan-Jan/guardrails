# Superseded risk controls Implementation Plan

**Goal:** an RC or HAZ superseded by a reciprocal pair is out of force: the RC owes no implementing REQ and its `mitigates:` mitigates nothing, the HAZ owes no `mitigates:`; a control and its implementing REQ superseded together leave the tree green, a hazard superseded with its control too, and a hazard the successor control drops goes red.
**Implements:** none. No item is claimed or amended: the toolkit keeps no REQ ledger of its own. Delivers D1 to D4 and D6 below, D5 being superseded by local `main`'s PR-8zcc72 fix; resolves PR-x63ejd, PR-ad4vmm, PR-nhf8cy and PR-qm5gfy.
**Safety class:** unclassified (the toolkit has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`; `check-ids.sh` and `check-trace.sh` against scratch copies of `main` and of the change, criterion no finding that `main` lacks.

Decided 2026-10-11 with the maintainer, on a class B adopter's report
(PR-x63ejd). Upgrading from 17a0d58 to 1967dc8, a tree whose `RC-46yapu` was
superseded by `RC-q9xdv2` on the same day its implementing `REQ-uutw7x` was
superseded by `REQ-t8ej3q` went red on `UNIMPLEMENTED-CONTROL RC-46yapu`.
`docs/plans/2026-10-08-out-of-force-items.md` D3 stopped the out-of-force
REQ's `implements:` crediting the control, but its D1 defined out of force for
REQ and LLR only, so the superseded control still owed an in-force REQ. Each
project-side remedy was false (a REQ claiming behavior the software
deliberately lacks), destructive (deleting the RC, or its supersession
lines), or both. D3's own rationale, "a control no test verifies any longer",
assumes a control in force; it did not consider a control superseded with its
REQ.

## Decisions

- **D1 (2026-10-11): an RC is out of force when its block contains a
  column-one `superseded-by:` naming another RC whose own block names it back
  with `supersedes:`,** by the chain rule of 2026-10-08 D1: the chain must end
  in an RC in force, a self-pair or a cycle exempts nothing and is
  `MALFORMED-SUPERSESSION`. An out-of-force RC owes no `implements:`
  (`UNIMPLEMENTED-CONTROL` skips it); its successor is an ordinary control
  and owes one. A pair takes an item out of force only within its family, RC
  to RC or REQ/LLR to REQ/LLR: a control is replaced by a control. A
  `retired:` on an RC still retires nothing and is still not reported
  (2026-10-08 D5); retiring a control is a risk decision this change does not
  take. The supersession checks (`NON-RECIPROCAL-SUPERSESSION`,
  `MALFORMED-SUPERSESSION`, `DANGLING-REF`) already read RC blocks, so the
  exemption is keyed on a pair the gates check, as for a REQ. (added
  2026-10-11 on the test-guidelines review: a scan that fails on the RMF,
  the out-of-force scan or the orphan backstop that reads the same files
  after it, is exit 2 and never a clean result, as for the SRS and SAD.)
- **D2 (2026-10-11): an out-of-force RC mitigates nothing.** A `mitigates:`
  inside an out-of-force RC's block does not mitigate the HAZ it names, as an
  out-of-force REQ's `implements:` implements nothing (2026-10-08 D3, whose
  "`mitigates:` on an RC are unchanged" this amends). Without it, a control
  superseded by a narrower one that drops a hazard leaves `UNMITIGATED-HAZARD`
  green on a control no longer in force. A `mitigates:` outside every RC
  block counts as before.
- **D3 (2026-10-11, on review round 1 finding-1): a HAZ is out of force by
  a reciprocal pair with another HAZ,** by the same chain rule, and an
  out-of-force HAZ owes no `mitigates:` (`UNMITIGATED-HAZARD` skips it); its
  successor is an ordinary hazard and owes one. Without D3, D2 moved
  PR-x63ejd one level up: a hazard reworded together with its control,
  `RC-old mitigates: HAZ-old` superseded by `RC-new mitigates: HAZ-new`, went
  red on `UNMITIGATED-HAZARD HAZ-old`, which `main` passed, and every remedy
  was false or deleted the record. The families are three: RC, HAZ, and
  REQ/LLR; a pair across families takes nothing out of force. A `retired:` on
  a HAZ retires nothing and is not reported, as on an RC.
- **D4 (2026-10-11): the test fixtures read no global or system git
  config** (PR-ad4vmm). The gate for this change failed two
  `check-signing.bats` tests on a host whose `~/.gitconfig` sets
  `gpg.ssh.allowedSignersFile`: a test that unsets the fixture's own setting
  fell back to the user's. The suite passed with `GIT_CONFIG_GLOBAL=/dev/null`
  three runs in three. The user's signing configuration is deliberate; the
  fixtures, not the host, are fixed.
- **D5 (2026-10-11): a signed commit whose `%G?` cannot be read fails**
  (PR-nhf8cy). T4 found the gate's intermittent failure had a separate cause:
  a verifier that exits without reading its input makes `git log` die of
  SIGPIPE under load, the empty `%G?` fell to the catch-all branch, and
  `check-signing.sh` printed WARN-UNVERIFIED with exit 0 for a commit that
  reads `B`, exit 1, on an idle machine. A verdict must not depend on timing:
  a failed `git log`, or an empty `%G?` on a commit that carries a signature,
  is the "verifier cannot run" verdict, exit 1 in both modes. (superseded
  2026-10-11 at the base merge of local `main` at cfa82e1: `main` fixed the
  same defect as PR-8zcc72, a failed `git log` on a signed commit giving
  `UNVERIFIED (git could not compute a verdict for this signature)` in both
  modes; T5's script change and its tests were withdrawn in favor of it, and
  PR-nhf8cy is resolved as its duplicate)
- **D6 (2026-10-11, on review round 2 finding-1): a signature is read from
  the commit header only** (PR-qm5gfy). Both places that ask whether a
  commit carries a signature matched `^gpgsig` against the whole commit
  object, so a message line starting with `gpgsig` made an unsigned commit
  read as signed: WARN-UNVERIFIED, exit 0, in default mode. The header ends
  at the first empty line.

## Tasks

### T1 — `check-trace.sh` reads out-of-force controls

**Files touched:** `scripts/check-trace.sh`, `tests/check-trace.bats`.

`oof_scan` takes the RMF files as an optional third list, opens blocks on RC
beside REQ and LLR, reads `retired:` in REQ and LLR blocks only, and keeps a
pair inside one family when it builds the chain. It reports which items are out
of force and records no credits of its own: `credit_scan` is the one reader of
`implements:` and of `mitigates:`, by D2 of the block-attributed-credits
change, and each gate intersects that reader's records with these IDs. (This
task was written against a tree where `oof_scan` emitted its own `I` and `M`
records and the gates intersected them with the line-wise reader. That half was
withdrawn where this change met the block-attributed-credits change on local
`main`, which allows one reader per keyword; PR-z83ka9's change records the
resolution.) The provider scan passes no RMF list. `UNIMPLEMENTED-CONTROL`
skips an out-of-force RC and drops an `implements:` credited inside an
out-of-force REQ's block; `UNMITIGATED-HAZARD` skips an out-of-force HAZ and
drops a `mitigates:` credited inside an out-of-force RC's block. The out-of-force list the test-side readers use keeps REQ
and LLR only, so `OUT-OF-FORCE-VERIFIES` is unchanged. The RMF files are
read with blocks opening on REQ and LLR as well, so a REQ misplaced in the
RMF has its `retired:` read; it is `MISPLACED-ITEM` already, so nothing goes
green that was red (review round 1, finding-5).

Tests, annotated `# verifies: D<n> (docs/plans/2026-10-11-superseded-risk-controls.md)`:

1. a superseded RC owes no implementing requirement (D1; the reporter's shape);
2. the successor of a superseded RC still owes one (D1);
3. a one-sided `superseded-by:` on an RC exempts nothing (D1, scope control);
4. an RC supersession cycle exempts nothing and is reported (D1);
5. an RC superseded by a REQ stays in force (D1, scope control);
6. a `retired:` on an RC retires nothing and is not reported (D1, scope
   control);
7. a hazard mitigated only by a superseded RC is unmitigated (D2);
8. a superseded RC's successor keeps its hazard mitigated (D2, scope control).

### T3 — superseded hazards, and the review round 1 fixes

**Files touched:** `scripts/check-trace.sh`, `tests/check-trace.bats`,
`skills/analyze-risks/SKILL.md`,
`skills/grill-requirements/references/supersession.md`,
`skills/ratchet/references/upgrade-notes.md`, this plan (Red -> green only).

D3 in `oof_scan` (blocks open on HAZ; three families in the chain rule) and
in `UNMITIGATED-HAZARD`. Tests:

9. a hazard superseded together with its control owes nothing (D3; review
   finding-1's shape);
10. the successor of a superseded HAZ still owes a `mitigates:` (D3);
11. a HAZ superseded by an RC stays in force (D3, scope control);
12. a REQ superseded by an RC still owes its test (D1; review finding-2, the
    REQ side of the family rule, mutation-reddened);
13. a `mitigates:` outside the RMF does not keep a hazard mitigated that only a
    superseded RC names (D2; review finding-3, mutation-reddened).

Docs: `analyze-risks` moves its supersession bullet out of Preconditions into
Steps and covers a hazard; `supersession.md` covers a superseded hazard and
says a table directly under an out-of-force RC belongs to its block (finding
4); the upgrade notes cover D3 and stop dating the RC rule from `dd411a1`.

### T4 — fixtures read no global or system git config

**Files touched:** `tests/helpers.bash`, a test file for the new test,
`docs/problems/2026-10-11-superseded-rc.md` (resolve
PR-ad4vmm), this plan (Red -> green only).

D4, with a red-first test that fails on a host config carrying
`gpg.ssh.allowedSignersFile` without depending on the host running it.

### T5 — `check-signing.sh` reads a failed `%G?` as a verifier that cannot run

**Withdrawn** at the base merge of cfa82e1 (D5), in favor of local `main`'s
PR-8zcc72 fix; PR-nhf8cy resolved as its duplicate. Kept as history.

**Files touched:** `scripts/check-signing.sh`, `tests/check-signing.bats`,
`docs/problems/2026-10-11-superseded-rc.md` (resolve
PR-nhf8cy).

D5, with a deterministic red-first test: one that makes `git log`'s `%G?`
come back failed or empty without depending on load.

### T6 — review round 1 follow-ups to T3

**Files touched:** `tests/check-trace.bats`,
`skills/ratchet/references/upgrade-notes.md`.

A permanent test that a HAZ supersession cycle is `MALFORMED-SUPERSESSION`
and exempts nothing (D3); the upgrade-notes HAZ bullet cites PR-x63ejd, not a
plan path an adopter does not have.

### T7 — review round 2 fixes

**Files touched:** `scripts/check-signing.sh`, `tests/check-signing.bats`,
`docs/problems/2026-10-11-superseded-rc.md` (resolve
PR-qm5gfy), `docs/plans/2026-10-08-out-of-force-items.md` (amendment note
for D3 of this plan on its D1),
`skills/ratchet/references/upgrade-notes.md` (D5 and D6 entries),
`skills/merge-change/references/review-checklist.md`.

D6 with a red-first test. The review checklist names an in-force REQ whose
`implements:` names only an out-of-force RC as a finding (review round 2
finding-3: no gate reports it, as 2026-10-08 D3 leaves history references to
review).

### T2 — the skills and upgrade notes state it

**Files touched:** `skills/analyze-risks/SKILL.md`,
`skills/grill-requirements/references/supersession.md`,
`skills/ratchet/references/upgrade-notes.md`,
`docs/plans/2026-10-08-out-of-force-items.md` (amendment notes on D1 and D3).

`analyze-risks` states how a replaced control is recorded and what that does
to its hazards. `supersession.md` gains a section on a superseded control.
The upgrade notes correct the claim that every new discharge finding is a
real gap, and add the two new behaviors.

## Red -> green

Measured on gawk 5, mawk and busybox awk; BWK awk 20200816 is not installed
on this host (see the verification record).

red -> green: check-trace: a superseded RC owes no implementing requirement — UNIMPLEMENTED-CONTROL RC-46yapu, exit 1
red -> green: check-trace: the successor of a superseded RC still owes an implementing requirement — UNIMPLEMENTED-CONTROL RC-46yapu printed beside RC-q9xdv2
red -> green: check-trace: an RC supersession cycle exempts nothing and is reported — no MALFORMED-SUPERSESSION RC-46yapu
red -> green: check-trace: a hazard mitigated only by a superseded RC is unmitigated — exit 1 on UNIMPLEMENTED-CONTROL only, no UNMITIGATED-HAZARD HAZ-k4wq8r

Scope controls, green on their own assertions before the fix (not red-first
evidence): tests 3, 5 and 6. Test 8 failed before the fix only on
`UNIMPLEMENTED-CONTROL RC-46yapu`, the D1 defect; its D2 assertion held.

The out-of-force scan now opens the RMF before the orphan backstop does, so
`check-trace: an unreadable risk ledger fails the orphan scan` reached the
scan's error path instead and failed on its message. It is renamed
`check-trace: an unreadable risk ledger fails the out-of-force scan`, the
RMF half of the SAD test beside it. No ledger is left that the backstop opens
first, so its own error path was then reached through GR_AWK_FRONT_MATTER,
which only the backstop reads in this script. That test was later rewritten
to use a PATH `awk` stub that fails only the backstop's invocation, on
guideline review finding-2 (f56e60d):

reddened: check-trace: a failing orphan-scan awk is exit 2, not a clean backstop — with `|| gr_die "orphan scan failed on $_f"` dropped the test went red (mutation-reddened, not red-first)

T4 (21a90b1). Its test, `check-signing: a fixture reads no global or system
git config`, was watched red (expected nothing, got 0: the scratch global
config's trust root) and later replaced at the script seam on guideline
review finding-3 (below); the replacement was reddened, not red-first.

T3 (fb65c73):

red -> green: check-trace: a hazard superseded together with its control owes nothing — UNMITIGATED-HAZARD HAZ-m7c4xd, exit 1
red -> green: check-trace: the successor of a superseded HAZ still owes a mitigates: — UNMITIGATED-HAZARD HAZ-m7c4xd printed beside HAZ-n3hb5f
reddened: check-trace: a REQ superseded by an RC still owes its test — verifies: D1; with the family check applied only when the old item is an RC the run exited 0 with no MISSING-TEST REQ-uutw7x (mutation-reddened, not red-first)
reddened: check-trace: a mitigates: outside the risk ledger keeps no hazard mitigated — verifies: D2; with `in_rmf &&` dropped the run exited 0 with no UNMITIGATED-HAZARD HAZ-k4wq8r (mutation-reddened, not red-first)

Scope control, green first: `check-trace: a HAZ superseded by an RC stays in
force`.

T5 (4702cc0), withdrawn at the base merge of cfa82e1 (D5); kept as history:

red -> green: check-signing: a signed commit whose verdict letter is lost fails in both modes — mode '': expected exit 1, got 0: WARN-UNVERIFIED <sha> (signature present but did not verify)
red -> green: check-signing: an empty verdict letter on a signed commit fails like a lost one — expected exit 1, got 0: WARN-UNVERIFIED <sha> (signature present but did not verify)

Scope control, green first: `check-signing: a lost verdict letter on an
unsigned commit is still UNSIGNED`. Under load (44 busy workers on 22 CPUs)
`check-signing: a verifier that cannot run is not called a forgery` passed 20
of 20 after the fix; the race fired in 66 of 200 bare calls on the same load.

T6 (6e74d31):

reddened: check-trace: a HAZ supersession cycle exempts nothing and is reported — verifies: D3; with HAZ pairs kept from forming edges the run printed no MALFORMED-SUPERSESSION HAZ-m7c4xd (mutation-reddened, not red-first)

T7 (9aa7304, rebuilt on the base merge dc4efb4):

red -> green: check-signing: a gpgsig line in the message does not make a commit signed — expected exit 1, got 0: WARN-UNVERIFIED <sha> (signature present but did not verify)

The lost-letter half of PR-qm5gfy has no test: git calls no verifier for an
unsigned commit, so the `failed` branch is unreachable there without a new
seam; the shared `carries_signature` covers that condition by construction.

Review round 4 fix (finding-1), green on its first run:

reddened: check-trace: doc_rmf on doc_srs's directory still reads its mitigates: lines — verifies: D2; with `in_rmf=0` whenever `in_srs=1` the run printed a false UNMITIGATED-HAZARD HAZ-001 (mutation-reddened, not red-first)

## Guideline reviews

### docs/TEST_GUIDELINES.md

Governs: docs/plans/2026-10-08-out-of-force-items.md docs/plans/2026-10-11-superseded-risk-controls.md docs/problems/2026-10-11-superseded-rc.md scripts/check-signing.sh scripts/check-trace.sh skills/analyze-risks/SKILL.md skills/grill-requirements/references/supersession.md skills/merge-change/references/review-checklist.md skills/ratchet/references/upgrade-notes.md tests/check-signing.bats tests/check-trace.bats tests/helpers.bash

#### Round 1 (at 97efd05)

**finding-1**: guideline, medium — Seams 1, "a test verifies the problem report or the plan decision that states the behavior, at the same seam" — tests/check-trace.bats:2124, tests/check-trace.bats:2135
disposition: no written decision stated either scan-failure contract, so D1 gained one clause (exit 2, never a clean result, for the RMF scan and the orphan backstop after it) and both tests verify D1 (f56e60d).

**finding-2**: guideline, medium — Doubles 1, "No mock of code the project owns" — tests/check-trace.bats:2142-2150
disposition: the poisoned `GR_AWK_FRONT_MATTER` is replaced by a PATH `awk` stub that fails only the backstop's invocation and execs the real awk otherwise (f56e60d).

**finding-3**: guideline, low — Seams 1, "In this repository the interface is a script's command line" — tests/check-signing.bats:91-114
disposition: replaced by `check-trace: the host's global or system git config does not change the verdict`, which plants `core.excludesFile` in every config git reads outside the repository and asserts check-trace.sh's verdict (f56e60d).

Floor note (every new test watched red): the scope controls, and the D2 assertion of `check-trace: a superseded RC's successor keeps its hazard mitigated`, were reddened by mutants (f56e60d):

reddened: check-trace: a failing orphan-scan awk is exit 2, not a clean backstop — verifies: D1; with `|| gr_die "orphan scan failed on $_f"` dropped the message assertion failed (mutation-reddened, not red-first)
reddened: check-trace: the host's global or system git config does not change the verdict — verifies: PR-ad4vmm; with the export line removed from tests/helpers.bash the run exited 1 on MISSING-TEST LLR-001 and REQ-001 (mutation-reddened, not red-first)
reddened: check-trace: a one-sided superseded-by: on an RC exempts nothing — verifies: D1; with the reciprocity check dropped there was no UNIMPLEMENTED-CONTROL RC-46yapu (mutation-reddened, not red-first)
reddened: check-trace: an RC superseded by a requirement stays in force — verifies: D1; with the family check dropped the run exited 0 (mutation-reddened, not red-first)
reddened: check-trace: a HAZ superseded by an RC stays in force — verifies: D3; with the family check dropped the run exited 0 (mutation-reddened, not red-first)
reddened: check-trace: a retired: on an RC retires nothing — verifies: D1; with retired: read in RC blocks the run exited 0 (mutation-reddened, not red-first)
reddened: check-trace: a superseded RC's successor keeps its hazard mitigated — verifies: D2; with mitigates: dropped in every RC block the run printed UNMITIGATED-HAZARD HAZ-001 (mutation-reddened, not red-first)
