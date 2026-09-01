# Verification — bsd-sed-mutations (2026-08-31)

branch: bsd-sed-mutations
reviewer: an independent subagent, dispatched at step 6a with only the diff, the problem ledger and the claims under test — no implementation narrative and no chat history. It reviewed the PRE-MERGE tree at `31e2303` and returned the seven findings below. Three attempts were needed for it: the first died when the machine slept mid-response, the second stalled, only the third ran; the dead attempts produced no findings and are not counted as review. A SECOND review, of the merge against `860dce4`, was dispatched and died twice to the same cause — it confirmed the re-derived measurement before the first failure but banked no quotable figures, so it is not counted either. The merge is therefore author-verified only; see Gaps.
verdict: accepted after disposition. Seven findings, all dispositioned here. The reviewer re-derived the change's central measurement with an independent harness and got the same figures; one finding is a regression this change introduced and would have shipped without the review.
reproduced: yes, and it is the whole evidence base. Before the fix, every one of the sixteen sites was demonstrated failing by running the mutation scripts against scratch trees on this machine: twelve exited 3 (their own `cksum` guard reporting "mutation changed nothing") and two exited 1 straight from BSD sed. The widened lint was also shown red on exactly those sixteen sites before the fix was applied.

Change: resolves PR-aap8nx — sixteen `sed -i` calls without a backup suffix, across fourteen mutation scripts under `docs/verification/*.mutations/`, which BSD sed rejects, so those mutations never applied and the evidence suites measured nothing. Branched from `main` at `31e2303`; `main` moved to `860dce4` (five commits) before merge and was merged in, which changed three of this record's figures — see "Re-assessed against 860dce4".
Plan: none — a problem resolution. `docs/problems/2026-08-27-macos-awk.md`.

## Provenance of the base merge

The first pass merged the local `main` at `31e2303` because `git fetch origin`
failed (exit 128, `Permission denied (publickey)` — an expired smartcard PIN).
That is no longer the provenance: the maintainer pulled `origin/main` on
2026-08-31, bringing it to `860dce4`, and this branch merged **that** — a real
remote ref, fetched by them, not an assumed-current local one. The gap the
earlier note described is closed.

## The gate

Every figure derived from the tree under test, not carried forward.

| Gate | Result |
| --- | --- |
| `./tests/run-tests.sh` | 435 tests, 435 ok, 0 failures, exit 0 |
| `check-ids.sh` | exit 1 — byte-identical to `main`'s own output (`diff` empty). 0 `DRAFT-FILE`, 0 `MALFORMED-ID` |
| `check-trace.sh` | exit 1 — the same pre-existing fixture residue as `main`, plus three `UNRESOLVED-PR` warnings for the items this change deliberately leaves open. `problems: open 3`, no `INCOMPLETE-PROBLEM`, no `MALFORMED-STATUS`, no `MALFORMED-DATE` |
| Coverage, against the class target | Not applicable — class A |
| Working tree | clean |

Both check scripts ran under a synthesized `GR_CONFIG` declaring `PR` and
`doc_problems`, because this repository still has no `.guardrails/`. What that
establishes is narrow and is stated in Gaps.

### The mutation measurement

The evidence for this change is not a new test. It is the population of
mutation scripts, run against scratch `scripts/` trees, before and after:

| | exit 0 | non-zero |
| --- | --- | --- |
| `main` at `860dce4` | 152 of 184 | 32 |
| this change | 166 of 184 | 18 |

Exactly **14** scripts changed exit code, and they are exactly the 14 mutation
files this change touches. The other 170 are unmoved.

The figures against the ORIGINAL base `31e2303` were 158 and 172, with the same
14 moving. Both totals fell by six when `main` advanced to `860dce4`, because
that commit removed the `owner:` handling in `check-trace.sh` that six
`2026-08-25-problem-triage.mutations` scripts patch — they now abort with
`AssertionError: mutation did not apply: 0 matches`. Those six are the base
branch's collateral, not this change's: they fail identically on both refs.
PR-dy8yup was amended from twelve to eighteen to record it. The superseded
figures are kept here because a measurement that silently changes its base is
the failure this table exists to prevent.

The first harness written for this measurement reported 184/184 on both refs
and was wrong: `echo "$name $?"` captured the exit status of a `basename`
command substitution rather than the mutation script. It is recorded here
because it is the same false-green shape the toolkit exists to catch, and
because the corrected figures are only trustworthy if the discarded ones are
named. The independent reviewer re-derived them with an unrelated harness —
fresh scratch tree per script, status captured on the line after the run, plus
a whole-tree fingerprint — and got 158 and 172.

### What `tests/evidence.sh` cannot say

`tests/evidence.sh main` reports **0** new-or-renamed tests, and therefore 0
that go red against `main`. That is correct and is not a shortfall: this change
widens an existing test rather than adding one, and `evidence.sh` counts test
NAMES. It also rolls back `scripts/` only, so it could not measure a change to
`docs/` in any case. The regression evidence lives in the table above and in
the lint's demonstrated red, neither of which that instrument can see.

## What was wrong, and what was built

`sed -i` without a suffix is GNU-only; BSD sed reads the next word as the
suffix and is then left with no script. Sixteen calls in the mutation scripts
carried the bare form. On macOS the mutation therefore never applied — and the
scripts that had a `cksum` guard said so honestly (exit 3, "mutation changed
nothing") while the two without one exited 1 from sed. Either way an evidence
suite whose purpose is to prove that a test detects a defect was proving
nothing, on the platform its maintainer uses.

Each call gained `.bak` and an `rm -f` of the backup. The lint added by
PR-44z762 was widened first — to executable content under `docs/`, by mode as
well as by name — and shown red on exactly the sixteen sites, so the fix was
made against a failing check rather than asserted.

Prose under `docs/` is deliberately outside the lint.
`docs/verification/2026-08-24-review-artefact.md` quotes two bare `sed -i`
commands that were actually typed on that day. A record of what happened is not
a defect to be repaired, and rewriting it to satisfy a scan would falsify it.

Three further defects were found and are recorded **open**, in
`docs/problems/2026-08-27-signing-and-identity.md`: PR-52rnrn (no signature on
this repository verifies on the maintainer's machine, and non-strict
`check-signing.sh` reports that as a pass), PR-tbn6q7 (the repository-local
commit identity had been lost, causing a `GH007` push refusal), and PR-dy8yup
(twelve mutation scripts that cannot apply at all — six target a
`scripts/finalize-ids.sh` deleted in `c672c9f`, six carry python `assert old in
s` anchors the source has outgrown).

## Review

**finding-1**: `rm -f` became the last command in M01/M08, which have no `cksum` guard, so sed's failure was discarded and the scripts exited 0 unconditionally — a regression introduced by this change, in the very failure class the change is about.
disposition: confirmed independently before fixing — with the mutation target renamed away, `main`'s M01 exits 1 and the branch's exited 0 while sed still printed its error. Both scripts were given the same `_gr_before`/`cksum` guard the twelve id-tokens scripts already carry, which the reviewer correctly preferred over propagating sed's status: it also catches a pattern that quietly stops matching, where sed exits 0 regardless. Verified in both directions — exit 3 when the target is missing, exit 0 with the intended single edit and no leftover `.bak` when it is not.

**finding-2**: PR-aap8nx was flipped to resolved with no `verifies: PR-aap8nx` anywhere, so `check-trace.sh` could not see that the widened lint is its regression evidence.
disposition: the lint now reads `# verifies: PR-44z762, PR-aap8nx`. This one had been spotted independently and was being held until the review landed, so as not to move files the reviewer was reading — the previous change's reviewer had to work from a stale diff for exactly that reason.

**finding-3**: The new ledger file said "Both items below" and carried three; PR-dy8yup was attributed to a discovery it had nothing to do with, and the file's title named two subjects out of three.
disposition: retitled, and the preamble now separates the two provenances — PR-52rnrn and PR-tbn6q7 found while merging `31e2303`, PR-dy8yup found by this change's own measurement. A record that miscounts its own contents is the defect this toolkit exists to prevent.

**finding-4**: The new `docs` arm guarded on `[ -e docs ]`, which is the one directory certain to exist, so the guard could never fire; what can actually go missing is the mutation scripts' reach.
disposition: the guard is now on the reach — the arm fails in a real checkout when it finds no executable content under `docs/` at all, so relocating or renaming the mutation suites reddens rather than silently passing.

**finding-5**: `--include='*.sh'` is name-based, so an executable mutation script that lost its `.sh` suffix would be invisible to the lint. Latent; no such file exists today.
disposition: the arm now selects by mode as well as name (`-name '*.sh' -o -perm -u+x`). Verified with a planted suffix-less executable under `docs/`: red, and it names the file.

**finding-6**: Adding `docs` to the skip list meant a non-git tree lacking `docs/` would skip the ENTIRE lint, including the `scripts/` arm that could still have run. Latent; no current consumer builds such a tree.
disposition: each arm is now judged on its own and the skip fires only when nothing at all is lintable. Verified with a partial copy carrying `scripts/` and a planted violation: red on the violation, where before it skipped.

**finding-7**: `rm -f <target>.bak` removes that path whether or not the script created it.
disposition: accepted knowingly and written into the resolution rather than changed. BSD `sed -i.bak` clobbers a pre-existing backup anyway, so the file is already lost before the `rm`; mutations run against scratch checkouts, and no `.bak` exists under `scripts/` in this repository.

## Re-assessed against 860dce4

`main` advanced by five commits mid-change and was merged in. Three of them
touch this change's own ground, so the record is re-derived rather than
carried:

* **`860dce4` removed `owner:` from the problem grammar.** Every item this
  change wrote carried one; all are stripped. This was the one merge conflict —
  in `docs/problems/2026-08-27-macos-awk.md`, where my side resolved PR-aap8nx
  and main's side kept it open while adding PR-w8k3np. Both were kept: my
  resolution, main's new item, main's owner-free grammar.
* **`708b8c0` rewrote `make_bsd_date`**, the stub this change's predecessor
  added. The rewrite is correct and the criticism lands: the stub validated
  `-v` and then handed it to the real `date` unchanged, so on a GNU box it
  reproduced BSD's rejections and none of its successes. It is upstream's fix
  to my instrument, taken as-is; this branch does not touch that function.
* **`b7fbd7f` restructured `merge-change` step 7** into a single handover
  command plus `scripts/finish-merge.sh`. That script runs `check-signing.sh
  --strict` unconditionally, which **fails on this machine** — measured on
  `860dce4`: exit 1, `UNVERIFIED`. PR-52rnrn was therefore amended: it has gone
  from a false green to a hard stop on cleanup. The signed commit still lands;
  the worktree and branch removal will refuse until an `allowed_signers` file
  exists. That is the correct trade and is called out here so the refusal is
  expected rather than read as a new defect.

One measurement error was made and corrected during this re-assessment. A `cd`
into the primary checkout persisted across commands, so the mutation population
was briefly measured with `main` on both sides of the comparison — reporting
"0 changed" and, for a moment, appearing to show the branch had lost its work.
It had not. It is recorded because it is the third instance in this change's
history of an instrument answering confidently about the wrong thing, after the
`basename` exit-status bug and the `make_bsd_date` stub, and because the
correct figures above are only as trustworthy as the account of how they were
taken.

## Gaps

- **The check scripts were not run as gates on this repository.** No
  `.guardrails/` exists, so they ran under a synthesized `GR_CONFIG` declaring
  `PR` alone. That shows this change's ledger items are well-formed and that it
  adds nothing to the pre-existing violation set — `check-ids.sh` diffs empty
  against `main`. It does not show the repository is clean. The reviewer noted
  that finding 2 is precisely a defect `check-trace.sh` would have caught if it
  could run here.
- **PR-52rnrn now blocks merge cleanup on this machine**, rather than passing
  quietly. See the re-assessment above.
- **Three problem reports are open**: PR-52rnrn, PR-tbn6q7, PR-dy8yup.
- **PR-dy8yup means eighteen mutations still measure nothing.** This change
  restored fourteen scripts; the evidence suites are not whole until those
  eighteen are re-anchored or retired, and six of them were broken by the base
  branch during this change rather than before it.
- **No GNU sed was executed.** Neither author nor reviewer had `gsed` on this
  machine. That `sed -i.bak` is unchanged in behaviour for GNU is argued from
  the sed programs being untouched — only the `-i` suffix differs — not
  measured. The same gap the previous change recorded for gawk.
- **The mutation measurement is an exit-code population, not a semantic
  check.** The reviewer diffed all fourteen mutated trees against pristine and
  confirmed each makes the single edit its `# describes:` line claims; that
  check is his, recorded here, and was not independently repeated.
- **The ledger and record filenames are dated 2026-08-27 and 2026-08-28; the
  merge is 2026-08-31.** `finalize-docs.sh` ran the day the change was written
  and the base then moved twice. Nothing reads the names, and churning
  regulated documents for a cosmetic date is the worse trade — but the record's
  own heading was corrected, since a record that misdates itself is a different
  matter from a filename that does.
- **The merge has no independent review, and that is a real gap, not a
  formality.** The seven findings below concern the sixteen `sed -i` sites and
  the lint, none of which the merge altered — but the conflict resolution, the
  `owner:` stripping and the re-derived 152/166 figures were checked by their
  own author. Two attempts at a second review died to machine sleep; the second
  reported the measurement confirmed before it was cut off, which is hearsay
  and is not relied on here. What the author did check, and how, is listed
  below — it is verification, not independent verification, and the distinction
  is the whole point of step 6a:
  * the conflict resolution, by diffing the retained PR-w8k3np block against
    main's own copy (identical) and enumerating every item's `status:` and
    `opened:` — six items, all resolved, all well-formed under main's current
    grammar;
  * `owner:` removal, by grepping every file the change touches (none left, and
    no residual code assuming the field);
  * the lint's four guards surviving the auto-merge — positive control, per-arm
    path guard, mode-based `docs/` selection, `docs/` reach guard — each still
    present exactly once;
  * `finish-merge.sh`'s ordering, by locating every removal statement and
    confirming all of them follow the `--strict` check at line 122 (the two
    earlier apparent hits are comment lines);
  * PR-dy8yup's eighteen, by cause: six per mutation suite, and the six
    problem-triage ones failing identically on both refs, which is what makes
    them the base branch's collateral rather than this change's.
