# Verification — agent-first-skill-shape (2026-10-04)

branch: agent-first-skill-shape
reviewer: rounds 1 and 2, each a fresh subagent with the diff, the change 3 plan, the proposal, the 2026-10-04 ruling and the review checklist (round 2 also this record), and no implementation narrative
verdict: round 1 REJECT on five medium and six low requirement findings, no code or record finding; round 2 ACCEPT on five low requirement findings and one record finding, which makes it the last review round under the 2026-10-04 ruling
reproduced: no defect is repaired; the change rewrites skill text (D3 item 3, D5, D6, D9, D10) and amends the convergence rule of `PR-3s74u3` by the maintainer's ruling of 2026-10-04.

Change: the ten remaining skills in the D9 shape and under the D5 ceiling, no skill exempt, this repository's `AGENTS.md` rewritten (D10), and the review ending on the first round with nothing above low severity. Branched from `main` at `fb0db8d`. The base was merged from local `main`, per AGENTS.md non-negotiable 5.
Plan: `docs/plans/2026-10-04-agent-first-skills-change-3.md`, under the proposal `docs/plans/2026-09-28-agent-first-skills.md`.

## The gate

The toolkit has no `.guardrails/config.yaml`, so the check scripts run under a
synthesized config: `id_prefixes: PR`, `doc_problems: docs/problems`,
`doc_verification: docs/verification`, `strict_paths: scripts`,
`test_paths: tests`. `check-ids.sh` and `check-trace.sh` are red on `main`
already, so the criterion is no finding on the branch that `main` lacks.

### Round 1 gate

Measured on `401fa44`, tree `3b264f36cbcceb01e4f39dc8826d41f12f23741c`, clean
at start and end, against a clone of `main` at `fb0db8d`.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..977`: 977 ok, 0 not ok, 0 skipped, counted from TAP lines |
| `check-trace.sh` | exit 1 on branch and `main`; output byte-identical |
| `check-ids.sh --allow-draft-files` | exit 1 on branch and `main`; output byte-identical (51 `DRAFT-ID` fixture strings, `DUPLICATE-ID PR-001`) |
| Coverage | not configured; the toolkit is unclassified |
| Working tree | clean |

Check 4 found no `verifies:` test for D3 item 3. Check 6 found no
abnormal-input test for any Implements ID: each shape test reads the shipped
tree only. Both are fixed in 992596d and ee6a62c: the two shape tests verify
D3 item 3, and eight fixture tests run the shape predicates against malformed
and well-formed SKILL.md files under `$BATS_TEST_TMPDIR`.

### Round 2 gate

Measured on `27ef0d5`, tree `6bcfe3d2e4aec364b364995a89219336d7c68063`, clean
at start and end, against the same clone of `main` at `fb0db8d`.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..985`: 985 ok, 0 not ok, 0 skipped, counted from TAP lines |
| `check-trace.sh` | exit 1 on branch and `main`; 34 violation lines each, none only on the branch |
| `check-ids.sh --allow-draft-files` | exit 1 on branch and `main`; 52 violation lines each, none only on the branch |
| Coverage | not configured; the toolkit is unclassified |
| Working tree | clean |

Check 6 found no abnormal-input test annotated to D3 item 3, D10 or
`PR-3s74u3`. The two fixture tests that reject a misordered and an oversized
SKILL.md now also verify D3 item 3. D10 and `PR-3s74u3` are requirements on
document text; their abnormal case is the absence assertion inside each test
(`GR_ID_ANY` absent from `AGENTS.md`; the old convergence sentence absent from
`merge-change`), and no fixture input exists for them (Gaps).
The D3 item 3 annotations are in f9c7e58.

### Final gate

Measured after the round 2 fixes on `50bfd27`, tree
`6ce158c26827612f88e20c38c24212e6852136dc`, clean at start and end, against the
same clone of `main` at `fb0db8d`. No reviewer was dispatched (step 6a, last
round).

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..985`: 985 ok, 0 not ok, 0 skipped, counted from TAP lines |
| `check-trace.sh` | exit 1 on branch and `main`; one line only on the branch, `UNRESOLVED-PR PR-s8dcmp`, the item this change opens; none only on `main` |
| `check-ids.sh --allow-draft-files` | exit 1 on branch and `main`; sorted output identical |
| Coverage | not configured; the toolkit is unclassified |
| Working tree | clean |

Check 4: every Implements ID has a `verifies:` test, and each test is in the
Red → green table above. Check 6: D3 item 3, D5, D6 and D9 have normal-case
and abnormal-input tests; D10 and `PR-3s74u3` have none on abnormal input
(Gaps). Check 8: the deslop pass was run (f4e5c62, 01b847e) and its findings
are fixed.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-3s74u3` (2026-10-04 ruling) | merge-change: a round with nothing above low severity is the last | T11: failed before the skill and checklist edits |
| `PR-3s74u3` (2026-10-04 ruling) | merge-change: the reviewer tags every finding | T11: failed before the skill edit |
| `PR-3s74u3` (2026-10-04 ruling) | verification template opens every finding with its tag | T11: failed before the template edit |
| D10 | AGENTS.md: non-negotiable 5 states the rule and points to its ADR | T12: failed at the ADR-pointer grep before the rewrite |
| D9, D3 item 3 | skill shape: every SKILL.md has the D9 sections in order | T13: with the exemption list removed, failed naming analyze-risks with a renamed `## Red flags` heading, which the exemption had skipped |
| D5, D3 item 3 | skill shape: every SKILL.md is at most 2,000 words | T13: with the exemption list removed, failed naming ratchet padded to 2035 words |
| D9, D3 item 3 | skill shape fixture: sections out of order are rejected | fix-r1-tests: failed with `gr_skill_has_d9_order` returning 0 |
| D9 | skill shape fixture: a missing Red flags section is rejected | fix-r1-tests: failed with `gr_skill_has_d9_order` returning 0 |
| D9 | skill shape fixture: a References heading with no reference file is rejected | fix-r1-tests: failed with `gr_skill_reference_failures` returning 0 |
| D6, D9 | skill shape fixture: a References entry that names a missing file is rejected | fix-r1-tests: failed with `gr_skill_reference_failures` returning 0 |
| D9 | skill shape fixture: a References entry with no read-when condition is rejected | fix-r1-tests: failed with `gr_skill_reference_failures` returning 0 |
| D5, D3 item 3 | skill shape fixture: a 2,001-word SKILL.md is rejected, and 2,000 words is accepted | fix-r1-tests: failed with `gr_skill_within_word_ceiling` returning 0, and again returning 1 |
| D5, D9 | skill shape fixture: a SKILL.md with no References section is accepted | fix-r1-tests: failed under each predicate made to reject everything |
| D5, D6, D9 | skill shape fixture: a SKILL.md with a well-formed References section is accepted | fix-r1-tests: failed under each predicate made to reject everything |
| `PR-3s74u3` (2026-10-04 ruling) | verification template opens every finding with its tag, as amended for finding 16 | fix-r2: failed against the old template line before the edit |

T1 to T10 add no test; the shape tests cover them once T13 removes the
exemptions.

## What was wrong, and what was built

Ten skills were out of the D9 section order, and four were over the D5
ceiling: `ratchet` 7759 words, `worktree-discipline` 2740, `check-traceability`
2490, `develop-change` 2121. Each is rewritten into Preconditions, Steps, Red
flags, Done when and References, with reasons, examples and conditional
material in `skills/<name>/references/`, and incident history deleted (D6).
Both exemption lists in `tests/skills.bats` and their two staleness tests are
deleted. `AGENTS.md` keeps its rules; the argument behind non-negotiable 5 is
in `docs/adr/2026-10-04-local-main-is-the-base.md`. `merge-change` step 6a
gives each `code` and `requirement` finding a severity and ends the review on
a round whose such findings are all `low`.

Problem ledger: this change opens `PR-s8dcmp` (`ratchet`'s upgrade mode,
review finding 12), which stays open, and resolves none. `PR-2jr4pj` stays
open; its `affects:` line names the files the claim moved to.

## Review

### Round 1

**finding-1**: requirement, medium — `skills/check-traceability/SKILL.md:78` says "Write annotations at column one, with no list marker." `skills/check-traceability/references/item-blocks.md:76-77` says "write every annotation at column one with no prefix". Main stated only "drop the marker", and it noted that `templates/sad.md` ships the annotation on the definition line (main SKILL.md:104-106, :126-128). The new rule contradicts `templates/sad.md:13,18-19` and the inline forms in design-architecture/SKILL.md:32 (`... traces: REQ-…`) and in analyze-risks' `**RC-…**: <control>. mitigates: HAZ-…`. An agent that follows it moves inline annotations off the definition line. In item-blocks.md, "prefix" is also ambiguous, because elsewhere in the skill it means the ID prefix.
disposition: fixed in ffe4fab: `skills/check-traceability/SKILL.md` states "Write annotations with no list marker" and that an annotation on the definition line, in the form `templates/sad.md` ships, is valid; `references/item-blocks.md` states "no list marker, quote marker or indentation" in place of "no prefix". No test pins the wording; the rule is text the suite does not judge (Gaps).

**finding-2**: requirement, medium — The ratchet upgrade procedure deletes `finalize-ids.sh` before drafts in flight are finished. `skills/ratchet/SKILL.md:134` says to follow upgrade-notes' "order of work", and `:136-137` deletes `.guardrails/scripts/finalize-ids.sh`. The order of work (`references/upgrade-notes.md:13-23`) omits "Finish or discard drafts in flight before upgrading … Run the old `finalize-ids.sh` one last time" and "Update any CI line that calls it". Both now exist only further down, at upgrade-notes.md:99-108. On main they were together in one step-2 note (main SKILL.md:245-256). Followed as written, an upgrade can leave `REQ-DRAFT-*` tokens that `check-ids.sh` fails on under every flag, with the old finalizer already deleted.
disposition: fixed in ffe4fab: item 1 of the order of work in `skills/ratchet/references/upgrade-notes.md` finishes or discards drafts in flight with the old `finalize-ids.sh` and updates CI before the scripts are copied; `skills/ratchet/SKILL.md` upgrade step 1 states it precedes the deletion. Text only (Gaps).

**finding-3**: requirement, medium — worktree-discipline turns a permission into an order. Main (SKILL.md:274-277) said compacting between changes "costs nothing". The branch's `skills/worktree-discipline/SKILL.md:194-195` says "Once a change is merged, compact or start a fresh session … before the next change." No decision is behind this new mandatory action. The scope rule "A conversation covers one change, start to finish" (main :257) is also dropped; it is in neither SKILL.md nor `references/rationale.md`.
disposition: fixed in ffe4fab: `skills/worktree-discipline/SKILL.md` step 9 opens with "A conversation covers one change, start to finish", and compacting between changes "costs nothing. It is permitted, not required." Text only (Gaps).

**finding-4**: requirement, medium — verify-before-merge gains preconditions that narrow its scope. `skills/verify-before-merge/SKILL.md:12-13` reads "You are the dispatcher of a change, in its change worktree" and "Every plan task branch is merged onto the change branch". The unchanged description (line 3) still says "Use before any 'done', 'fixed', 'passing' claim", and main applied "Evidence before assertions" to any such claim, including a task subagent's. No decision is behind the narrowing. Related low issue: Done when at :150 ("every check green") conflicts with :55 ("the gate summary has no line for" check 8).
disposition: fixed in ffe4fab: the first precondition of `skills/verify-before-merge/SKILL.md` applies the evidence rule to any claim by any agent; only "Dispatch the gate" onward is the dispatcher's. Done when separates the gate summary's checks from the dispatcher's half of check 4 and check 8. Text only (Gaps).

**finding-5**: requirement, medium — In analyze-risks, the class check moved after controls. Main had a free-standing "Class awareness" section (stop as soon as a harm exceeds the class). The branch makes it step 7 (`skills/analyze-risks/SKILL.md:46-50`), after step 5 (mint RCs) and step 6 (residual risk). Step 3 (Harm, where S3 appears) has no pointer to it. Read in order, an agent mints controls under a classification that is already wrong before it stops.
disposition: fixed in ffe4fab: the class check is step 4 of `skills/analyze-risks/SKILL.md`, as soon as a severity is stated and before any control is minted; later steps and the Red flags references renumbered. Text only (Gaps).

**finding-6**: requirement, low — `skills/check-traceability/SKILL.md:114` (Done when) says "Every violation was fixed in the artifact, not in the checker or the config." Main said only "never the checker". Step 2 (:29) tells the agent to fix the config on exit 2, and the `sources:`-zero case is a config fix. "or the config" contradicts the skill's own steps.
disposition: fixed in ffe4fab: Done when states "never in the checker", and that an exit 2 was fixed in the config (step 2). Text only.

**finding-7**: requirement, low — ratchet multi-unit retrofit has no pointer at the step where it applies. `references/multi-unit.md` is named only from step 2.3 (SKILL.md:83) and in References as "before step 2.3 copies any file" (SKILL.md:253-254). A retrofit never reaches step 2.3, and step 3.3 (SKILL.md:167-168) does not point to it. Also on the retrofit path: the minimal-first-tooth permission from main :61-62 (one unit named, the rest disclaimed) now exists only in `references/rationale.md:17-19`; "an existing single `srs.md` keeps working" (main :616-618) is dropped.
disposition: fixed in ffe4fab: retrofit step 3.3 of `skills/ratchet/SKILL.md` points to `references/multi-unit.md`, whose References condition now names step 2.3 or step 3.3; step 1b states that a manifest naming one unit with the rest disclaimed is a valid first step; step 3.4 states that an existing single `srs.md` keeps working. Text only.

**finding-8**: requirement, low — In grill-requirements, the supersession reference is named as a normal-path read ("read when a new item supersedes or retires an existing one", SKILL.md:180). Neither the Supersession section (:88) nor the amendment step (:67-69) points to it. The time limit on the retirement rule ("Until that change is merged", main :60-66) now exists only in `references/supersession.md:31-33`; SKILL.md:96-98 states the rule with no limit. "Escalate a term to the root glossary" became "Move a term …" (:136), which can be read as deleting the unit's own definition. The example `/agents` became `/agent` (:42).
disposition: fixed in ffe4fab: the amendment step of `skills/grill-requirements/SKILL.md` points to its Supersession section, which names `references/supersession.md`; the retirement rule states its limit in `SKILL.md`; "Escalate a term to the root glossary" is restored with "keep it in the unit glossary". The `/agent` example stays: the deslop pass made it the one dispatch phrase across `develop-change`, `verify-before-merge` and `grill-requirements`. Text only.

**finding-9**: requirement, low — develop-change has new wording with no decision behind it: SKILL.md:60 "(unsigned in the worktree)" reads as an order, where main :66 said "unsigned is fine"; SKILL.md:135-136 adds "Do not merge it" for a wrong `worktree:` line, with no next action (re-dispatch or `task-worktree.sh discard`).
disposition: fixed in ffe4fab: `skills/develop-change/SKILL.md` states "unsigned is fine in the worktree"; a wrong `worktree:` line is sent back to its subagent, or the task is discarded with `task-worktree.sh discard <tag>` and dispatched again. Text only.

**finding-10**: requirement, low — An open problem item and two test comments now point at moved text: `docs/problems/2026-09-29-id-allocation-claim.md:9` (PR-2jr4pj, status open) has `affects:` naming `skills/worktree-discipline/SKILL.md, "Mint the ID now"` for the "allocated against nothing" claim, which is now in `skills/worktree-discipline/references/rationale.md:62`; `tests/skills.bats:474` cites a worktree-discipline section "Inside the worktree" that no longer exists (the removal rule is now step 8); `tests/check-signing.bats:116` cites develop-change's "iron law" heading, which is gone.
disposition: fixed: the `affects:` line of `PR-2jr4pj` names `skills/worktree-discipline/references/rationale.md` and `skills/ratchet/references/upgrade-notes.md`, where the claim moved (ffe4fab); the comments in `tests/check-signing.bats` (ffe4fab) and `tests/skills.bats` (992596d) cite the current develop-change and worktree-discipline text. The fix found the claim also repeated in the new ADR; 6ca81b6 rewrites its passage from the `scripts/new-id.sh` header (collisions detected, not prevented), names `PR-2jr4pj` for the `check-ids.sh` header, and drops AGENTS.md from the item's `affects:`, since neither file still contains the claim.

**finding-11**: requirement, low — `skills/merge-change/SKILL.md` step 6a tells the dispatcher to "record each other one as an open problem item" on the last round. The `templates/verification.md` disposition placeholder is still "<what changed, and the test that reddens without it>", which does not fit a finding that is booked as a problem item rather than fixed. This is a documentation gap; the tree is right.
disposition: fixed in ffe4fab: the disposition placeholder in `templates/verification.md` also covers a finding recorded as an open problem item, with its ID. "verification template opens every finding with its tag" passes.

### Round 2

**finding-12**: requirement, low — Upgrade is a new third mode with its own procedure, and no decision is behind it. `skills/ratchet/SKILL.md:29-30` adds "A project that has `.guardrails/scripts/` and wants newer ones is an **upgrade**", and `:131-153` gives a six-step procedure. On main, mode detection had only greenfield and retrofit (main `skills/ratchet/SKILL.md:21-22`), and a re-ratchet reached retrofit step 3, whose inventory names "existing `.guardrails/` version if re-ratcheting" (main `:589-590`, branch `:164-165`). On the branch an upgrade skips step 3, and so skips the gap analysis that Done when requires of a retrofit (`:250`). D6 moves the upgrade notes to a reference file; it does not create a mode. Each procedure step comes from main text and nothing is lost. A smaller point in the same section: upgrade step 1 (`:135-138`) says only the first item of the order of work comes "before step 2", but items 2 and 3 (`references/upgrade-notes.md:20-23`) also precede the copy.
disposition: the order point is fixed in f9c7e58: upgrade step 1 of `skills/ratchet/SKILL.md` states that the first three items of the order of work precede the copy. The mode question is not a mechanical fix and is recorded as the open problem item `PR-s8dcmp` (`docs/problems/2026-10-04-ratchet-upgrade-mode.md`), per step 6a.

**finding-13**: requirement, low — `skills/ratchet/references/multi-unit.md:3-4` still opens "Read this when `ratchet` step 1b found more than one unit, before step 2.3 copies any file." The finding-7 fix changed the References entry (`skills/ratchet/SKILL.md:259-260`, "before step 2.3 or step 3.3 installs any file") and the step 3.3 pointer (`:175`), but not this sentence. The file's own read-when sentence therefore leaves out the retrofit path. The plan requires each reference file to open with one sentence stating when to read it. SKILL.md is right.
disposition: fixed in f9c7e58: the opening sentence of `skills/ratchet/references/multi-unit.md` names step 2.3 or step 3.3, as the References entry does.

**finding-14**: requirement, low — The comment in `tests/skills.bats:1287-1289` ("develop-change: the loop greps the mutation anchors…") still says "No gate catches it — portability.bats reads that directory only for `sed -i` spellings — so the obligation lives in the TDD loop or nowhere." T4 removed that claim from the skill because `tests/mutations.bats` catches a dead anchor (`skills/develop-change/references/mutation-anchors.md:13-16`; plan dispatch log, T4). The comment is unchanged from main and now contradicts the skill.
disposition: fixed in f9c7e58: the comment states that `tests/mutations.bats` reports a mutation that no longer applies when the full suite is run, and that the grep in the loop finds the hit during the edit.

**finding-15**: requirement, low — D6 says the SKILL.md names each reference file at the step where it applies. `skills/check-traceability/SKILL.md:121-122` lists `references/config.md` for "when a `sources:` figure is zero", but step 3 (`:48-51`), where the agent reads `sources:`, does not name the file. Only step 2 names it (`:29`), and only for exit 2. The three gaps that config validation does not catch (`doc_soup`, absent `verify_commands`, dropping a prefix) were in main's SKILL.md (main `:140-155`). On the branch they exist only in `references/config.md:34-48`.
disposition: fixed in f9c7e58: the `sources:` bullet of step 3 of `skills/check-traceability/SKILL.md` names `references/config.md`.

**finding-16**: requirement, low — The finding-1 line in `templates/verification.md:67` reads `<code | requirement | record>, <high | medium | low>`, which shows a severity on every finding, including a `record` one. Step 6a, `review-checklist.md` and the template's own field grammar (`:103-104`) all state that a `record` finding states none. The template is the one place the shape is shown rather than described. The test pins the line as written (`tests/skills.bats:1436`).
disposition: fixed in f9c7e58: `templates/verification.md` shows a `code`/`requirement` finding with a severity and a `record` finding without one. The test "verification template opens every finding with its tag" asserts both lines and rejects a `record` finding with a severity; it failed against the old template line before the edit.

**finding-17**: record — The finding-8 disposition in `docs/verification/2026-10-04-agent-first-skill-shape.md` says "the amendment step and the Supersession section of `skills/grill-requirements/SKILL.md` name `references/supersession.md`". Only the Supersession section names the file (`skills/grill-requirements/SKILL.md:91`). The amendment step (`:69-70`) points to the "Supersession" section, not the file. Following that pointer reaches the line that names the file, so the tree works, but the disposition is not literally true.
disposition: fixed in this record: the finding-8 disposition now states that the amendment step points to the Supersession section, which names the file.

## Gaps

- The suite proves rules are present in the skill text, not that an agent
  follows them better after the rewrite (proposal, "Acceptance, and its
  limit"). Skill evals are out of scope. Round 1's text fixes and round 2's
  mechanical fixes are verified by review, not by a test.
- D10 and `PR-3s74u3` have no abnormal-input test: they are requirements on
  document text, and their abnormal case is the absence assertion inside each
  test.
