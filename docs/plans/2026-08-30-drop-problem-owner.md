# Drop `owner:` from the problem-item grammar

Fixes **PR-dudg35** (docs/problems/2026-08-31-drop-owner-tag.md; recorded in
this change's DRAFT ledger file, finalized to that name at merge).

## Decision

The `owner:` field is removed from the problem-item grammar entirely:

- An open item requires `opened:` and `status:` only. `owner:` is no longer
  required, read, or reported — a leftover `owner:` line anywhere in a
  problems ledger is inert prose (backward compatible: existing ledgers with
  `owner:` lines keep passing, including one sitting outside any item, which
  used to be `ORPHAN-ANNOTATION`).
- `UNRESOLVED-PR` output drops the owner clause:
  `UNRESOLVED-PR PR-xxxxxx (open N days)` and
  `UNRESOLVED-PR PR-xxxxxx (open, age unrecorded)`.
- Rationale (goes in the PR resolution, echoed in doc prose where the old
  rationale lived): authorship is already answered by `git blame` on the
  ledger line; problems are not personally owned — anyone may resolve them —
  so the field only added a failure mode (`INCOMPLETE-PROBLEM` for a missing
  name) without adding triage value. Age-based triage (`opened:`,
  `problem_age_days`, `problem_open_max`) is untouched.

## Task 1 — scripts and their tests (TDD core)

**Files touched:** `scripts/check-trace.sh`, `scripts/lib.sh`,
`tests/check-trace.bats`, `tests/helpers.bash`.

RED first, in `tests/check-trace.bats` (annotate each new/changed test
`# verifies: PR-dudg35`):

1. Replace `an open item with no owner: is incomplete` (~line 2045) with
   `an open item needs no owner:`: fixture item has `opened:`+`status: open`
   and NO owner line; assert no `INCOMPLETE-PROBLEM`, and
   `UNRESOLVED-PR PR-001 (open N days)` appears.
2. Replace `an open item with an empty owner: is incomplete` (~2056) with
   `a leftover owner: line inside an item is inert`: fixture keeps
   `owner: jvdv` (and one with empty `owner:`), asserts the run is unchanged
   by it — same UNRESOLVED-PR line, no failure, and NO `owner` text in the
   output.
3. Invert `an owner: belonging to no item is an orphan` (~2324) to
   `an owner: outside any item is inert, not an orphan`: fixture from the old
   test; assert no `ORPHAN-ANNOTATION` (the `status:`/`opened:` orphan gates
   stay — do not touch their tests).
4. Repurpose `an indented owner: does not answer for an open item` (~2383)
   to the `opened:` equivalent: an indented `opened:` does not answer for an
   open item → `INCOMPLETE-PROBLEM PR-001 (open, no opened:)`.
5. Update every output assertion that carries an owner clause:
   `(open 10 days, owner jvdv)` → `(open 10 days)`;
   `(open, age unrecorded, owner jvdv)` → `(open, age unrecorded)`;
   `(open 0 days, owner jvdv)` → `(open 0 days)`;
   `(open 4 days, owner jvdv)` → `(open 4 days)` (incl. the CRLF test).
6. `resolved item needs neither owner: nor opened:` (~2083): keep the name's
   intent but reword to `a resolved item needs no opened:`; drop owner from
   its fixture.
7. `owner: and opened: in another ledger are out of scope` (~2348): drop the
   `owner:` half, keep `opened:`.
8. Remove `owner:` from remaining fixtures — `tests/helpers.bash` `write_pr`
   (~line 130) and the inline printf fixtures — EXCEPT the inert-line tests
   from items 2–3, which exist to keep it.

Watch the changed tests fail for the right reason (the script still demands
and prints owner), then GREEN in the scripts:

- `scripts/check-trace.sh`:
  - `gr_prflush`: delete the `who` local and its computation, the
    `INCOMPLETE-PROBLEM %s (open, no owner:)` branch, and the owner clause
    from both `UNRESOLVED-PR` printfs.
  - Delete the `own`/`own_seen` state (block-close reset and the
    `gr_kw_here(line, "owner:")` scan line).
  - Delete `check_orphans 'owner:' PR $problems_files`; trim its comment to
    cover `opened:` alone.
  - Header comment: drop `owner:` from the ORPHAN-ANNOTATION keyword list;
    `UNRESOLVED-PR` described as carrying its age only; `INCOMPLETE-PROBLEM`
    as "an OPEN one with no opened:".
- `scripts/lib.sh` (comments only, no behavior): the keyword-asymmetry note
  (~244) becomes "`status:`, `opened:` — CLOSED"; the `gr_value` note (~275)
  swaps its example: "an empty `opened:` is an omission wearing the shape of
  compliance". Do NOT touch the unrelated `owner` awk variable in the config
  reader (~line 816).

Full suite green (`tests/run-tests.sh`), refactor, commit.

- [x] Task 1 — done, merged into the change branch (task commit bc2e634)
  red -> green: check-trace: an open item needs no owner: — watched fail for the right reason (old script: `INCOMPLETE-PROBLEM PR-001 (open, no owner:)` and `owner unrecorded`, exit 1) before the implementation existed
  red -> green: check-trace: a leftover owner: line inside an item is inert — watched fail (old script: `(open 2 days, owner jvdv)` and `INCOMPLETE-PROBLEM PR-p9r5wx (open, no owner:)` for the empty owner:)
  red -> green: check-trace: an owner: outside any item is inert, not an orphan — watched fail (old script: `ORPHAN-ANNOTATION docs/problems/0001-01-01-base.md:1 (owner: belongs to no item)`, exit 1)
  red -> green: nine further assertion-updated tests (complete-open-item age line, opened-today, CRLF, trailing whitespace, February span, first-opened-wins, century span, BOM, clock-skew) — each watched fail on the old owner-bearing output (`owner unrecorded` / INCOMPLETE-PROBLEM) before the script change
  note: four changed tests pin retained behavior and cannot go red (resolved-needs-no-opened:, opened:-in-another-ledger, indented-opened: pair); all sixteen annotated `# verifies: PR-dudg35`
  result: 409 passed, 0 failed (full suite in the task worktree, before Task 2's tests; SSH_AUTH_SOCK= workaround for the wedged ssh-agent)

## Task 2 — grammar prose: templates, skills, README, ledgers

**Files touched:** `templates/problems.md`, `templates/AGENTS-block.md`,
`skills/resolve-problem/SKILL.md`, `skills/check-traceability/SKILL.md`,
`skills/ratchet/SKILL.md`, `README.md`, `docs/problems/README.md`,
`docs/problems/2026-08-27-macos-awk.md`,
`docs/problems/2026-08-30-tool-qualification.md`, `tests/skills.bats`.

RED first, in `tests/skills.bats` (`# verifies: PR-dudg35`): a test asserting
that no shipped problem-grammar prose still requires or documents `owner:` —
grep for the literal `owner:` over exactly the files listed above except
`tests/skills.bats` itself and the two dated ledger files; assert zero hits.
Watch it fail (every one of those files carries it today), then GREEN:

- `templates/problems.md` + `docs/problems/README.md` (keep the two in
  step): drop the `owner:` grammar line; "every OPEN item an `owner:` and an
  `opened:` date" → "every OPEN item an `opened:` date"; "Resolved items
  need neither owner nor opened" → "a resolved item needs no `opened:`";
  UNRESOLVED-PR bullet drops "and owner". Where the old text said the field
  exists so "nothing is anyone's", state the replacement rationale from the
  Decision section instead.
- `templates/AGENTS-block.md` (~45): drop the owner clause from the
  problem-report sentence.
- `skills/resolve-problem/SKILL.md`: drop `owner:` from the item template
  (~26) and from the required-fields paragraph (~37–49); UNRESOLVED-PR
  described with age only.
- `skills/check-traceability/SKILL.md`: keyword lists (~78, ~156) drop
  `owner:`; `UNRESOLVED-PR` row (~157) age only; `INCOMPLETE-PROBLEM` row
  (~158) opened:-only.
- `skills/ratchet/SKILL.md` (~218, ~229): retrofit/backfill notes now name
  `status:` + `opened:` only.
- `README.md` (~125): check-trace row — "every open one an `opened:` date".
- The two dated ledger files: delete their `owner:` lines (now inert; edits
  to items happen in place in the file that defines them).

Full suite green, commit.

- [x] Task 2 — done, merged into the change branch (task commit 215fb16)
  red -> green: problem grammar prose: no shipped file still carries owner: — verifies: PR-dudg35 — watched fail for the right reason before the implementation existed (grep found `owner:` in all seven shipped prose files, so the zero-hits assertion failed)
  result: 411 passed, 0 failed (full suite in the task worktree; check-signing run with SSH_AUTH_SOCK= empty around the known wedged ssh-agent)

## Resolution (in the change worktree, after both tasks merge)

Update the PR item in the DRAFT ledger file: drop its own `owner:` line,
`status: resolved`, one-line resolution naming root cause and the reproducing
test (`check-trace: an open item needs no owner:`). Then `check-traceability`
→ `verify-before-merge` → `merge-change`.
