# Restoring the mutation evidence — implementation plan

**Goal:** every committed mutation script either applies at HEAD and is still
killed by a test, or declares itself retired with a stated reason.
**Implements:** resolves `PR-dy8yup`; opens and mitigates `PR-hcqjk6`; opens and
disposes of `PR-b7ua4s`. No REQ/LLR is added — this change restores existing
evidence and gates it; the toolkit's shipped behaviour is unchanged.
**Safety class:** B. `.guardrails/config.yaml` is absent because this repository
is guardrails itself rather than an adopter of it, so the class is the one the
templates ship.
**Verification:** `tests/run-tests.sh`, plus the new `tests/mutate.sh`.

Decisions: `docs/plans/2026-09-17-mutation-evidence.md` (D1–D7).

## Census this plan is built on

138 of 184 apply; **46 do not**: 16 retired, 29 re-anchored, 1 never applied.
T2–T5 partition those 46 exactly, and no file appears in two tasks.

## Task order

T1 first and alone — it is the reproduction test for `PR-dy8yup` and must be
watched failing with all 46 named before anything is repaired. T2–T5 then run in
parallel; T6 last.

Every task runs in its own nested worktree, `.worktrees/restore-mutation-evidence-t<N>`,
commits on `restore-mutation-evidence-t<N>`, and does **not** merge.

---

### T1 — The runner and the gate

**Files touched:** `tests/mutate.sh`, `tests/mutations.bats`
**Parallel:** no (first; T2–T5 depend on it)

RED is the deliverable. A green here would mean the gate cannot see the defect
it exists to report.

`tests/mutate.sh` — this text is prototyped and measured, not sketched. It was
run against the tree at `8d78cd4` and reported `138 applied, 0 retired,
46 unusable` in 32 s. `tar --null -T`, `sort -z` and `find -print0` were each
confirmed on this machine's BSD userland before the plan was written.

*(Code pruned at merge: 94 lines. Files touched: `tests/mutate.sh`, `tests/mutations.bats`.)*

`tests/mutations.bats` — four tests. Tests 2–4 exercise the runner against
fixtures and pass from the first commit; test 1 is the one that must be red.

*(Code pruned at merge: 67 lines. Files touched: `tests/mutate.sh`, `tests/mutations.bats`.)*

**Verify RED:** `tests/.bats-core/bin/bats tests/mutations.bats`. Test 1 fails
listing 46 scripts; the others pass. Check the 46 against the census in the
decision record name by name — 46 by coincidence is not 46 by measurement.

---

### T2 — Retire the 17

**Files touched:**
`docs/verification/2026-08-20-scan-pathspec.mutations/M12.sh`, `M13.sh`, `M14.sh`,
`M15.sh`, `M16.sh`, `M18.sh`, `M19.sh`, `M20.sh`, `M21.sh`, `M22.sh`, `M23.sh`;
`docs/verification/2026-08-25-problem-triage.mutations/M05.sh`, `M06.sh`,
`M23.sh`, `M32.sh`, `M36.sh`;
`docs/verification/2026-08-23-review-artefact.mutations/M15.sh`
**Parallel:** yes (with T3, T4, T5)

Note `scan-pathspec` M17 is **not** in this list. It targets `check-trace.sh`,
applies, and must not be touched.

Each file gains a `# retired: ` line after its `# describes:` line; nothing else
changes. Three reasons, one per group:

*(Code pruned at merge: 2 lines. Files touched: `docs/verification/2026-08-20-scan-pathspec.mutations/M12.sh`, `M13.sh`, `M14.sh`, `M15.sh`, `M16.sh`, `M18.sh`, `M19.sh`, `M20.sh`, `M21.sh`, `M22.sh`, `M23.sh`; `docs/verification/2026-08-25-problem-triage.mutations/M05.sh`, `M06.sh`, `M23.sh`, `M32.sh`, `M36.sh`; `docs/verification/2026-08-23-review-artefact.mutations/M15.sh`.)*

*(Code pruned at merge: 2 lines. Files touched: `docs/verification/2026-08-20-scan-pathspec.mutations/M12.sh`, `M13.sh`, `M14.sh`, `M15.sh`, `M16.sh`, `M18.sh`, `M19.sh`, `M20.sh`, `M21.sh`, `M22.sh`, `M23.sh`; `docs/verification/2026-08-25-problem-triage.mutations/M05.sh`, `M06.sh`, `M23.sh`, `M32.sh`, `M36.sh`; `docs/verification/2026-08-23-review-artefact.mutations/M15.sh`.)*

*(Code pruned at merge: 2 lines. Files touched: `docs/verification/2026-08-20-scan-pathspec.mutations/M12.sh`, `M13.sh`, `M14.sh`, `M15.sh`, `M16.sh`, `M18.sh`, `M19.sh`, `M20.sh`, `M21.sh`, `M22.sh`, `M23.sh`; `docs/verification/2026-08-25-problem-triage.mutations/M05.sh`, `M06.sh`, `M23.sh`, `M32.sh`, `M36.sh`; `docs/verification/2026-08-23-review-artefact.mutations/M15.sh`.)*

`review-artefact/M15.sh` takes its own reason (D7):

*(Code pruned at merge: 4 lines. Files touched: `docs/verification/2026-08-20-scan-pathspec.mutations/M12.sh`, `M13.sh`, `M14.sh`, `M15.sh`, `M16.sh`, `M18.sh`, `M19.sh`, `M20.sh`, `M21.sh`, `M22.sh`, `M23.sh`; `docs/verification/2026-08-25-problem-triage.mutations/M05.sh`, `M06.sh`, `M23.sh`, `M32.sh`, `M36.sh`; `docs/verification/2026-08-23-review-artefact.mutations/M15.sh`.)*

Only the first line takes the `# retired: ` prefix; continuations are ordinary
comments.

**Verify:** `tests/mutate.sh` reports `17 retired` and 29 unusable.

---

### T3 — Re-anchor `2026-08-22-id-tokens` (10)

**Files touched:** `docs/verification/2026-08-22-id-tokens.mutations/M09.sh`,
`M16.sh`, `M19.sh`, `M20.sh`, `M23.sh`, `M27.sh`, `M28.sh`, `M29.sh`, `M31.sh`,
`M39.sh`
**Parallel:** yes

* **M09, M16, M23, M39** — `3fe5eb3` gave every `case` pattern a leading `(`.
  `scripts/new-id.sh:183-186` is now `(*["$digits"]*) ;;` / `(*) continue ;;`.
* **M19, M20** — `47cde0b` extracted the regex into `gr_def_re_loose`, so the
  target file becomes `scripts/lib.sh`. The function is `lib.sh:664-666`:
  `printf '%s' "${2-^}\\*\\*(${1})-[^*]*\\*\\*:"`. M19 drops the line-start
  anchor; M20 widens the prefix to `[A-Za-z][A-Za-z0-9]*`.
* **M27, M28, M29, M31** — `47cde0b` replaced
  `BEGIN { defre = "^\\*\\*LLR-" body "\\*\\*:" }` with
  `BEGIN { gr_block_init("LLR", body) }` (`check-trace.sh:417`, `574`, `607`).
  Re-cut each to pass the literal `"[0-9][0-9][0-9]+"` instead of the shared
  `body`, which expresses the same defect.

**Prove the kill** for each, per D1: apply the mutation in a scratch tree and run
the bats file for the script it mutates — `tests/new-id.bats`,
`tests/lib.bats`, `tests/check-trace.bats`, `tests/check-ids.bats`. Record the
name of a failing test per mutation. A mutation its own file does not kill
escalates to the full suite; one still alive after the full suite is a **finding** —
report it, do not repair it and do not delete it.

---

### T4 — Re-anchor `review-artefact` and `problem-triage` (7)

**Files touched:** `docs/verification/2026-08-23-review-artefact.mutations/M03.sh`,
`M16.sh`, `M17.sh`;
`docs/verification/2026-08-25-problem-triage.mutations/M08.sh`, `M18.sh`,
`M27.sh`, `M34.sh`
**Parallel:** yes

* **M03** — the START anchor `    [ "$branch" != "$base" ] || gr_die \` still
  matches at `check-review.sh:118`; the END anchor
  `fi\n\ndir=$(gr_verification_dir)` is what fails. Re-cut the end only, and
  confirm the excised region is still exactly the base-branch rejection.
* **M16** — `0a35669` indented the call: `check-review.sh:69` is now
  `    gr_check_config`, so the anchor `\ngr_check_config\n` no longer matches.
* **M17** — leading-paren drift: `check-review.sh:82` is
  `        (*) gr_die "unknown argument: $1" ;;`.
* **M08** — `860dce4` removed `owner %s` from the printf.
  `check-trace.sh:923-924` is now
  `printf "W -1 UNRESOLVED-PR %s (open, age unrecorded)\n", cur`. The subject —
  an undatable open item dropped from the roll-call — is untouched. This is a
  retirement's near neighbour and is not one: `860dce4` changed the line, not
  the behaviour.
* **M18** — leading-paren drift in `gr_limit`, `scripts/lib.sh:767+`.
* **M27, M34** — leading-paren drift in the today-guard,
  `check-trace.sh:161-164`. M27's **second** anchor, the awk calendar guard at
  `check-trace.sh:165-166`, still matches exactly and must not be touched;
  changing it would turn a two-guard mutation into a one-guard mutation and make
  M27 a duplicate of M34.

Kill proof and escalation as T3 (`tests/check-review.bats`,
`tests/check-trace.bats`, `tests/lib.bats`).

---

### T5 — Re-anchor `2026-08-27-config-schema` (12)

**Files touched:** `docs/verification/2026-08-27-config-schema.mutations/M60.sh`,
`M70.sh`, `M73.sh`, `M74.sh`, `M76.sh`, `M83.sh`, `M85.sh`, `M86.sh`, `M87.sh`,
`M88.sh`, `M89.sh`, `M90.sh`
**Parallel:** yes

All twelve target `scripts/lib.sh`'s config checking. Eleven were broken by
`0a35669`, which generalised the reader to take a file argument — `$GR_CONFIG`
became `$_ff`. M60 is the clearest: `lib.sh:830` now reads
`"cannot read $_ff — it exists but this user cannot open it."`. M73 is
leading-paren drift from `3fe5eb3` instead.

Re-cut each against the current `gr_check_config`, confirm it applies, and prove
the kill with `tests/lib.bats`. The config-schema record claims 26 killed with no
survivors, so a survivor here contradicts merged evidence and is reported as a
finding rather than repaired.

---

### T6 — Problem reports and the verification record

**Files touched:** `docs/problems/2026-08-27-signing-and-identity.md`,
`docs/problems/2026-09-17-mutation-evidence.md`,
`docs/verification/2026-09-17-restore-mutation-evidence.md`
**Parallel:** no (after T1–T5)

Amend `PR-dy8yup` **in the dated file that defines it** — definitions never move:
correct `affects:` to the measured 46, set `status: resolved`, and state what was
re-anchored, what was retired, and what now gates it.

Two new items go in this change's draft ledger file, with the IDs already
minted. Both are shown INDENTED, because a definition form at column one is
read as a definition wherever it appears — a fenced block included — and an
unindented copy here made check-ids.sh report each ID as a duplicate of the
ledger entry it illustrates. Indented, they illustrate and define nothing:

*(Code pruned at merge: 7 lines. Files touched: `docs/problems/2026-08-27-signing-and-identity.md`, `docs/problems/2026-09-17-mutation-evidence.md`, `docs/verification/2026-09-17-restore-mutation-evidence.md`.)*

*(Code pruned at merge: 7 lines. Files touched: `docs/problems/2026-08-27-signing-and-identity.md`, `docs/problems/2026-09-17-mutation-evidence.md`, `docs/verification/2026-09-17-restore-mutation-evidence.md`.)*

`PR-hcqjk6` is resolved by the runner rather than by editing 59 scripts: the
check belongs in one place that cannot be omitted, not in 59 that can. State
that reasoning in the resolution, because "resolved" against unchanged scripts
is otherwise indistinguishable from a resolution that did nothing.

The verification record takes the four required fields, the gate table, the
red → green attestations from T1–T5, the 46-row disposition table, and a Gaps
section naming at least:

1. `tests/mutate.sh` does not derive the records' tables (D4), so three merged
   records still head a table with a command that answers a different question.
2. The `2026-08-23-review-artefact.mutations` directory is dated a day before the
   `2026-08-24-review-artefact.md` record it supports. Pre-existing; untouched.
3. The behaviour D7's retired M15 named — `if (open_line) disposed = 1` at
   `check-review.sh:228` — has no mutation covering it, and provably cannot:
   `check-review.sh:163-168` records it as an equivalent mutant, fuzzed over
   8000 generated records with zero differences. This is a gap in the kill
   count, not in the coverage.
4. Whether each re-anchored mutation is killed by the same tests as when it was
   written is **not** established; D1 proves a kill, not the original kill set.

## Self-review

1. `PR-dy8yup` is reproduced by T1's failing test before any repair — the iron
   law, and why T1 is parallel with nothing.
2. No two parallel tasks name the same file. T2 and T4 both edit inside
   `2026-08-25-problem-triage.mutations/` and `2026-08-23-review-artefact.mutations/`,
   and their lists are disjoint: T2 has problem-triage M05, M06, M23, M32, M36
   and review-artefact M15; T4 has problem-triage M08, M18, M27, M34 and
   review-artefact M03, M16, M17.
3. T2 + T3 + T4 + T5 touch 17 + 10 + 7 + 12 = 46 files, which is the census
   exactly, with no file counted twice.
4. Every re-anchored mutation has a stated kill proof, and a survivor is defined
   as a finding rather than as a repair target.
5. The retirement reason is declared in the script, so the gate never infers a
   retirement from a failure — otherwise every newly broken anchor would retire
   itself and the gate would ratchet itself open.
