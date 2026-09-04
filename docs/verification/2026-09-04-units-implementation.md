# Verification record — units-implementation

branch: units-implementation
reviewer: one independent subagent (DO-178C independence: not the author; received only the diff, the architecture, the two risk files and the plan, with the plan's dispatch bookkeeping expressly excluded from its inputs)
verdict: approve-with-findings — 3 IMPORTANT, 3 MINOR; all six fixed and dispositioned below, and the post-fix gate re-ran the full suite green
reproduced: the reviewer re-derived the change's claims directly — re-ran the plan's 41-obligation audit (clean), ran ~100 targeted bats tests across seven files (all green), byte-diffed check-trace/check-ids output between main's scripts and the branch's on a manifest-less fixture (identical, findings included — the engagement rule proven, not assumed), and probed the three IMPORTANT findings to first principles on live fixtures before the fixes were written. Each fix was then watched red -> green by its own dispatch (or sabotage-validated where the fix is a test).

## Scope

The implementation of the monorepo unit machinery designed in
docs/plans/2026-09-03-units-architecture.md (items 1-9), executed per
docs/plans/2026-09-04-units-implementation.md as twelve dispatched tasks plus
one review-fix round. Delivered: the manifest reader/validator, engagement
rule and unit-scope resolver in scripts/lib.sh; the four-way reference
classification, expectation machinery (UNMET-EXPECTATION, aging limits,
MISSING-TEST exemption), export grammar (MISEXPORTED-ITEM,
INCOMPLETE-EXPECTATION) and provider advisory in scripts/check-trace.sh; the
scoped/tree-wide split in scripts/check-ids.sh; scripts/check-units.sh (new:
manifest gate, UNCLAIMED-PATH, class floor + segregation citations,
DISCLAIMED-DRAFT over disclaimed and implicitly-disclaimed surfaces, the
near-miss manifest scan, --impact/--exports/--list); unit selection in
scripts/new-id.sh; repository-level scripts/check-review.sh and per-unit
scripts/finalize-docs.sh under the engagement rule; templates/units.yaml and
the expectation limits shipped set in templates/config.yaml; README coverage.

The binding contract is the architecture's **41 named test obligations**
(no minted REQ/SDD IDs — the repo is not self-hosted;
docs/plans/2026-08-22-ratchet-gap-analysis.md). The plan's audit loop greps
every obligation name against the bats test titles; it printed nothing at
both gate runs. The plan additionally records ten implementation decisions
taken within the architecture (its "Implementation decisions taken here"
section); the reviewer judged each defensible and found no unmarked derived
behavior beyond them. Decision 7 adds one vocabulary token the architecture
did not name: **EXPECTATION-BACKLOG** (exit 1, check-trace scoped), the
count-limit finding mirroring PROBLEM-BACKLOG exactly.

## Base

Merged **from the local ref** `main` = `336cfeb` (fast-forward at the start
of the change, "already up to date" at step 1 before the review and again
after the fix round). A fetch is impossible in this environment (the
hardware key refuses non-interactive operations); local `main` is the
authority in this repository's workflow — both commits it gained during the
track landed from the user's own sessions.

## Test evidence

`sh tests/run-tests.sh`, TAP counts, never exit codes:

- baseline before any task: **482/482** at `336cfeb`;
- after every task (T1-T12, each in its own dispatched task worktree,
  merged serially): **577/577** at `4a7f0f3`, re-confirmed after the
  DRAFT->dated rename at `ddc38dc` (step 6);
- pre-review gate: **577 declared / 577 ok / 0 not ok**, obligation audit
  empty, git status clean (gate log: session scratchpad
  units-implementation-gate.log);
- definitive post-fix gate at `1a46d0a`: **588 declared / 588 ok /
  0 not ok**, obligation audit empty (run twice), git status clean
  (units-implementation-gate2.log). Only this record's own commit follows.

Check scripts do not run against this repository (not self-hosted),
consistent with every prior change. Performed by hand in their stead: the
DRAFT->dated plan rename; zero references to the draft name confirmed
before renaming; the obligation audit as the Implements map.

Red -> green: every task's dispatch report is parked verbatim in the plan
beside its task (sections "T<N> — DONE"). Every new test either (a) was
watched failing for the right reason before its implementation existed, or
(b) is an explicitly named pin/preservation/green-on-arrival test whose
worth was proven by sabotage — the mechanism broken, the test watched red,
restore watched green — or by probe. No test was annotated green-from-birth
without one of those two attestations. Robustness (class-B-equivalent):
abnormal-input tests counted per file at the gate (check-units 7, lib
manifest section 14, check-trace scoped 7), extended by finding-6's four.

## Review findings and dispositions

**finding-1** (IMPORTANT): draft tokens and DRAFT-named files at the repo
root or under root .guardrails/ were scanned by no gate in a manifest
repository — risk assessment 3's hazard on the implicitly-disclaimed
surface, a regression against today's tree-wide scans that no document
declared residual.
disposition: check-units.sh's DISCLAIMED-DRAFT scan now covers tracked
root-level files and .guardrails/ (excluding .guardrails/scripts/, whose
comments legitimately carry draft-shaped tokens) via a shared scan_drafts
helper. Three tests watched red (exit 0) before the fix: a root DRAFT file
with a token, .guardrails/DRAFT-stash.md, a bare token in README.md. The
fixture-passes test is the negative twin.

**finding-2** (IMPORTANT): 32 mid-test bare `[[ ]]` assertions in the NEW
tests were inert under macOS bash 3.2 (a failing mid-test `[[ ]]` is
swallowed; only a test's last command binds) — several obligation clauses
rested solely on dead assertions.
disposition: all 32 armed with ` || false` (check-trace 17, check-ids 2,
lib 5, new-id 3, check-units 5); the swallow was proven by inversion before
arming on a named assertion, and three armed assertions across files were
inversion-checked red after. Pre-existing tests share the pattern and were
left untouched: **carried forward as an open item** — the suite-wide
convention deserves its own change and a problem report once self-hosted
(the finding is recorded in the plan's T4 report).

**finding-3** (IMPORTANT): gr_units_present used `[ -f ]`, which on a
case-insensitive filesystem (APFS) matches UNITS.YAML — scoped scripts
engaged off a manifest that officially does not exist while check-units.sh
refused it; the same tree behaved differently on case-sensitive CI. Both
divergence directions were convict-side (no false green), but the
engagement decision and its byte-exact check lived in different places.
disposition: the byte-exact check (exact name in the directory listing)
moved into gr_units_present — one definition; check-units.sh's local
workaround dropped as redundant, its near-miss diagnosis kept. Red-first
tests: the UNITS.YAML probe reports not-engaged; a scoped check-trace run
under UNITS.YAML stays single-unit. Both hold on case-sensitive filesystems
too.

**finding-4** (MINOR): the draft-token and draft-file patterns were
hand-copied between check-ids.sh and check-units.sh — the drift shape the
toolkit's one-definition rules exist to prevent.
disposition: GR_DRAFT_TOKEN_RE and GR_DRAFT_FILE_RE defined once in lib.sh,
consumed at all four sites. Refactor under green — 71/71 draft-owning tests
unchanged.

**finding-5** (MINOR): a `(RC-…)` segregation citation resolved against a
definition existing only under a disclaimed path — inconsistent with
disclaimed-definitions-do-not-resolve.
disposition: citations resolve through gr_unit_of_path; disclaimed-only
definitions convict INCOMPLETE-SEGREGATION naming the disclaimed file
(watched red first); the twin with the RC defined in a unit's RMF passes.

**finding-6** (MINOR): four abnormal-input gaps — empty-valued `exported:`,
orphan `exported:`/`expects:` outside any block, `--unit` in a single-unit
repository, an absolute manifest entry.
disposition: four tests added, each green on arrival (the implementations
existed) and each sabotage-validated red then restored.

## Known residuals, stated

- The bash-3.2 inert-assertion pattern persists in tests that predate this
  change (finding-2's carried item).
- The expectation-met awk condition appears twice in check-trace.sh (met
  check and provider advisory) — edits to one must reach the other (noted
  by T11's sabotage matching both).
- MALFORMED-ID deliberately scans no disclaimed path (risk assessment 3's
  accepted residual, gated by disclaimed-prose-is-not-malformed).
- A wrong-directory manifest at the repository root is accepted residual
  (risk assessment 2); the near-miss scan covers .guardrails/ only.

## Handoff

Remaining in the monorepo track, all outside this change by the
architecture's own list: skill updates (merge-change consuming --impact,
/ratchet writing the manifest and per-unit configs, the D10
dependency-assessment interview in grill-requirements/design-architecture,
D13 glossary escalation). REQ/SDD/HAZ/RC minting for the whole track awaits
self-hosting.
