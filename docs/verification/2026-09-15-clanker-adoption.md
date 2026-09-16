# Verification — clanker-adoption (2026-09-15)

branch: clanker-adoption
reviewer: dispatched subagent, two independent rounds, each in its own task worktree off the change branch, given the repository and the two plan documents and no account of how the change was made
verdict: round 2 concluded the shipped behavior is sound — all eight decisions implemented as stated, every `clanker:` test provably fails when the behavior it guards is removed, no ambiguous anchors, no unmarked scope. Its six findings were all in the change's own records, and all six are fixed. Round 1 raised six findings, one of them a test that passed with its behavior deleted; all six are fixed.
reproduced: yes, for every defect either review raised that had an observable failure. Round 1's finding 2 was reproduced twice by deletion: the reviewer deleted `skills/ratchet/SKILL.md`'s gap bullet and the test stayed green, and the dispatcher repeated that deletion after the fix and watched it fail. The record defects in round 2 were reproduced by measurement — each disputed figure recomputed from the tree at a named commit.

Change: adopt the code-craft and plain-language rules from CLANKER.md, install a
scan that keeps the vocabulary swept, and add a deslop pass at `develop-change`'s
exit with a gate check that it was run. Branched from `main` at `51f01b7`;
rebased onto `main` at `d8502d1` mid-change.
Plan: `docs/plans/2026-09-14-clanker-implementation.md`.
Decisions: `docs/plans/2026-09-14-clanker-adoption.md`, D1–D8.

**Base merged from local `main` at `d8502d1`, per AGENTS.md non-negotiable 5.**
The remote was out of scope by policy, not skipped by accident. That rule states
what it costs: step 4's duplicate scan sees the IDs in the local merged tree
only. Here it costs nothing measurable, because this change mints no IDs at all.

## The gate

Every figure derived from the tree under test, not carried forward.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | **688 ok, 0 not ok, 0 skipped**, TAP plan `1..688` matching the count. Measured at `d68bb95` by the dispatched gate, and independently at the same commit by the round 2 reviewer in its own worktree |
| `check-ids.sh` | Inapplicable. Run: exits 2, `guardrails: file not found: .guardrails/config.yaml` |
| `check-trace.sh` | Inapplicable. Run: exits 2, same cause |
| Coverage, against the class target | Inapplicable. No config, so no `coverage_command`. Class A requires none (`docs/adr/2026-08-22-safety-class.md`) |
| Working tree | Clean, checked before and after the suite run |

This repository does not self-host its gates (`docs/plans/2026-08-22-ratchet-gap-analysis.md`).
The four inapplicable rows are reported with the evidence that makes them
inapplicable. A gate that cannot run is not a gate that agreed.

**The 688 figure describes the tree being merged.** Two commits landed after it
was measured, both touching only `docs/plans/*.md`. No test in the suite reads
this repository's own `docs/` — every reference is a comment, a `# verifies:`
annotation, or a fixture the test creates in its own sandbox, confirmed with
`grep -rn 'BATS_TEST_DIRNAME/\.\./docs' tests/*.bats`, which matches nothing.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| D3 | `clanker: the managed block bans the vocabulary by listing it` | yes — watched fail before the block existed (T1) |
| D5 | `clanker: the managed block names concrete naming rules` | yes — watched fail before the block existed (T1) |
| D1 | `clanker: this repository follows the same block` | yes — watched fail before the block existed (T1) |
| D4 | `clanker: develop-change dispatches one deslop pass over the whole diff` | yes — `grep 'deslop pass'` failed before the section existed (T2) |
| D4 | `clanker: the deslop pass is not deferred to the merge review` | yes — `grep 'reruns from step 1'` failed before the section existed (T2) |
| D7 | `clanker: develop-change tells a stuck task to change approach` | yes — `grep 'change the approach'` failed before the pivot existed (T2) |
| D6 | `clanker: the gate checks that the deslop pass was run` | yes — `grep 'deslop pass ran'` failed before check 8 existed (T3) |
| D1 | `clanker: a bug caused by the design escalates to design-architecture` | yes — `grep 'consequence of the design'` failed, and `design-architecture` appeared nowhere in the file (T4) |
| D1 | `clanker: ratchet reports a managed block with no writing rules` | yes — `grep 'writing rules'` failed before the gap bullet existed (T4). Re-anchored in round 1: see the review section |
| D2 | `clanker: no skill body contains the replaced vocabulary` | yes — twice. The task changed `contains no colon` to `carries no colon` at `skills/check-traceability/SKILL.md:42` and watched the scan name that file, line and text. The dispatcher repeated the proof independently in a different file, planting `holds` at `skills/ratchet/SKILL.md:10` |
| D8 | `clanker: the deslop dispatch prohibits a task worktree` | yes — the prose already existed, so the anchor was proved instead: both halves of the prohibition deleted from `skills/develop-change/SKILL.md`, `not ok ... grep -qF 'Work in the change worktree at <path>, on <change-branch>. Do NOT create a task' failed`, restored, green |

Eleven tests, eleven attestations. Each comes from the dispatch report of the
subagent that ran the loop, which is the only party that saw the test fail.

## What was wrong, and what was built

Guardrails had no rule about how anything is written. Its 11 skill bodies had
grown a register of metaphor and anthropomorphism — 127 occurrences of the
vocabulary now on the replace list, measured at `51f01b7` — and nothing bound
new writing. Prose is the whole product here: these skills are instructions to a
model, and a model imitates the register that surrounds it.

Built: a compressed writing section in `templates/AGENTS-block.md`, shipped to
every adopting project by `/ratchet` and mirrored in this repository's own
`AGENTS.md` (D1, D3, D5); a sweep of all 11 skill bodies, leaving 3 occurrences,
all inside quoted tool output that the scan exempts by full wording (D2); a
deslop pass at `develop-change`'s exit with a gate check that it was run (D4,
D6, D8); a re-dispatch pivot in the derailment rule (D7); an architectural
root-cause escalation in `resolve-problem`; and a scan test that fails naming
file, line and text when any skill body regains the vocabulary.

**The scan is the part that will still matter in a year.** Four times inside
this change the replaced vocabulary came back in new prose — once from a task
subagent, twice from the dispatcher's own plan text while specifying the rule,
and once in a fix written after the rule was installed and while citing it. The
sweep without the scan would have decayed immediately.

## Review

Two rounds. Round 1 raised six findings, round 2 raised six more after all of
round 1's were fixed. The full text of both is in
`docs/plans/2026-09-14-clanker-implementation.md`; the dispositions are here.

**finding-1**: D5 was only partly implemented — the replaced vocabulary remained in a bats test name and six comments in `tests/skills.bats`, a file the sweep never scoped, and one comment had drifted out of agreement with the assertion it documents.
disposition: swept in `841155e`. The comment now matches its assertion. The file remains outside the scan's scope, recorded as a known gap.

**finding-2**: `clanker: ratchet reports a managed block with no writing rules` passed with the behavior it names deleted. Its only anchor, `grep -q 'writing rules'`, matched a second occurrence elsewhere in the file.
disposition: re-anchored in `4598e90` on a phrase unique to the gap bullet, verified with `grep -c`. Proved by deletion twice — by the reviewer before the fix, and by the dispatcher after it, which reddens where the old anchor stayed green.

**finding-3**: unmarked scope — `skills/develop-change/SKILL.md` gained a dispatch rule stating the deslop pass gets no task worktree, with no decision and no record behind it.
disposition: recorded as D8 in `bb1020b`, with `clanker: the deslop dispatch prohibits a task worktree` pinning both halves, and T2's record amended to name it as a third deviation.

**finding-4**: the change's own prose broke the rule it installs.
disposition: swept in `a2ec1c9` and again in `2c8792a`. Quotations, fenced blocks and before/after tables keep their original wording, because they are evidence of what was rewritten.

**finding-5**: holes in the scan beyond the one already recorded — the `banned=` list is a hand copy of the shipped list with nothing tying them together, `tests/skills.bats` is out of scope, and the metaphor rule is unenforced.
disposition: the vacuous-pass hole was fixed in `5e21e70` — the scan now asserts a floor of 11 files, proved by pointing the glob at nothing. The rest are recorded in the decision record's known-gaps section for the change that closes the scope gap.

**finding-6**: recorded figures did not describe the tree under review — the gate figure predated the base merge, and three other counts were wrong.
disposition: corrected in `0c0b60b` and again in round 2. Every figure in both documents is now stated with the commit it was measured at and a command that reproduces it.

**finding-7**: the renamed-test record under-counted by eight. Nine tests were renamed, cited by name at seventeen sites across nine already-merged records.
disposition: rewritten in `6568e7e` with the full old-to-new table and the per-document citation list. The archived records are left unedited: each holds the name the test had at its own merge, and editing merged evidence to match a later tree falsifies it.

**finding-8**: three claims written against D1–D7 when the contract is D1–D8, and the eleventh test had no red → green attestation recorded — which is what check 4 fails a change for.
disposition: corrected in `72319ed`, and the attestation is in the table above.

**finding-9**: the change's own records broke the rule the change installs, at fourteen sites.
disposition: swept in `2c8792a`.

**finding-10**: the known-gaps section presented four holes as the complete set, when the scan reads `skills/*/SKILL.md` and nothing else.
disposition: replaced in `6ef835f` with an eleven-row table of every unscanned surface, each with a measured count, whether the rule binds it, and a reproduce command pinned to `d68bb95`.

**finding-11**: two documents stated different, both wrong, counts for the same work — 16 pinned strings in one, 8 strings and 15 test names in the other.
disposition: corrected in `7cd54b9` to the measured 4 assertion strings and 6 test names. The inflated figures came from a wider word list including `named`, `given` and `sits`, which the shipped rule never banned.

**finding-12**: T5's sweep figures were refuted 200 lines later by the same document, and neither figure was right.
disposition: corrected in `47aaa5c` to 127 at `51f01b7` and 20 at `f875970`, with the command, and a pointer to the record that found the residue.

## Gaps

- **The scan reads `skills/*/SKILL.md` and nothing else.** `AGENTS.md`,
  `templates/AGENTS-block.md`, `README.md`, `scripts/`, the other bats files and
  the live ledgers are unscanned. The decision record tabulates every surface
  with a measured count. This change fixes none of them.
- **The scan's word list is a hand copy** of the list in `AGENTS.md`, with no
  check that the two agree. A word added to the shipped rule is not added to the
  scan, and nothing reports the divergence.
- **The scan enforces the replace list only.** The metaphor, anthropomorphism
  and active-voice rules are enforced by the deslop pass and by nothing
  mechanical.
- **Nine renamed tests leave seventeen stale citations** in nine merged records.
  No gate resolves test names, so no gate reports them. Left as they are,
  deliberately.
- **The deslop pass is prose, not a script.** Check 8 verifies that it was run,
  from the dispatcher's report. Nothing verifies how well.
- **No requirement items.** This repository does not self-host its gates, so
  D1–D8 are plan decisions rather than REQ items, and `check-trace.sh` proves
  nothing about them. The bats suite is the whole mechanical evidence.
