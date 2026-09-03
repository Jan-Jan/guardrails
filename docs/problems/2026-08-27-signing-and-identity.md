# Problem reports — signing, commit identity, and stale mutations

Three items, found two different ways, none of them by a gate.

PR-52rnrn and PR-tbn6q7 were found on 2026-08-27 while merging the macOS
portability change (`31e2303`) and were not recorded at the time. PR-dy8yup was
found during THIS change, by running all 184 mutation scripts to measure
PR-aap8nx's fix — the ones it names are those that change made no difference
to.

They are recorded here so they surface at every merge rather than being
remembered. That two of them went unrecorded for a day is the argument for the
ledger, not against it.

**PR-52rnrn**: No commit signature on this repository can be verified on the
maintainer's machine, and the default gate reports that as a pass.
affects: scripts/check-signing.sh — its non-strict mode; scripts/finish-merge.sh,
which calls it with `--strict` and so cannot complete a merge's cleanup here;
and the missing `allowed_signers` file that
docs/plans/2026-08-22-ratchet-gap-analysis.md records as configured and
maintained.
opened: 2026-08-27
status: resolved
AMENDED 2026-08-31, and the severity has changed with the base branch. When
this was recorded it was a false green — `check-signing.sh` printing
`WARN-UNVERIFIED` and exiting 0. b7fbd7f then added `finish-merge.sh`, which
runs `check-signing.sh --strict` unconditionally before it removes anything.
Measured on 860dce4: `--strict` exits 1, `UNVERIFIED`. So the false green is
gone and a hard stop has replaced it: the signed commit still lands, and the
worktree and branch cleanup will refuse until an `allowed_signers` file exists
or the GPG trustdb is readable. That is the right trade — it withholds cleanup,
never the merge — but it means this item now blocks the tail of every merge on
this machine rather than passing quietly.
RESOLVED 2026-09-03: not a defect in the flow. The design already routes
signing, verification and cleanup through the maintainer's own shell:
merge-change step 7 hands over exactly one command —
`git commit -S -F <msgfile> && sh scripts/finish-merge.sh <branch>` — and in
that shell `check-signing.sh --strict` exits 0 over the new HEAD (measured
2026-09-01; reconfirmed 2026-09-02, when the bd41d7a merge's cleanup completed
through it). The UNVERIFIED that prompted this item is the sandboxed agent's
environment — a TCC-denied GPG trustdb — which bd41d7a now reports as exit 2,
environment not project (PR-mvqm4s). What this closure does NOT repair, and
accepts: the twenty-two ssh-signed commits predating the switch to OpenPGP
stay unverifiable everywhere while no `allowed_signers` file exists. The flow
never needs them verified — finish-merge.sh checks the new HEAD only — so
that is an accepted gap in the history, not a fixed one.

FOUND WHILE MEASURING THIS, and fixed elsewhere: the closure above is the
disposition of this item. What measuring it turned up was a separate defect in
the tool, carried by PR-74gcqg and PR-mtmr7h in
docs/problems/2026-09-03-signing-diagnosis.md — `check-signing.sh` printed one
identical `UNVERIFIED` line whatever the cause and appended the ssh trust-root
remedy to all of them, because `git log --format=%G?` returns a letter and
discards the verifier's output. On a history signed both ways that remedy was
correct for the ssh commits and irrelevant to the OpenPGP ones, which is how
this item's own diagnosis came to name a missing `allowed_signers` file as the
reason a PGP commit would not verify. It is not: measured against a writable
`GNUPGHOME` copy of the same keyring, those commits verify `%G? = G`, "Good
signature ... [ultimate]", and what defeats them is that gpg opens
`trustdb.gpg` read-write even to read it. The gate now prints the verifier's
own words under every non-passing verdict, so the next reader of an
`UNVERIFIED` gets the cause instead of a guess.

The unverifiable ssh history that this closure accepts as a gap is carried,
as a gap, by PR-r8q9m7 in the same file — not to reopen it, but because
nothing in the toolkit ever inspects history at all.


**PR-tbn6q7**: The repository-local commit identity was lost at some point
before 2026-08-27, so a commit was authored from the global
`jan-jan@parity.io` and GitHub refused the push with `GH007`.
affects: .git/config — not a tracked artefact, which is the difficulty; no
gate in the toolkit reads the author identity of the commit it is about to
make.
opened: 2026-08-27
status: resolved
The repository-local identity is restored in `.git/config`
(`user.email = 111935+Jan-Jan@users.noreply.github.com`) and GitHub accepts
pushes again — bd41d7a, authored under that identity, is on origin/main. How
the local identity was lost was never established: root cause unknown,
declared rather than guessed. The
fix is untracked configuration, so there is no reproducing test; the gap the
item names — no gate reads the author identity of the commit it is about to
make — remains open territory, unclaimed by this closure.

**PR-dy8yup**: Eighteen of the 184 mutation scripts under `docs/verification/`
can no longer apply their mutation, so they measure nothing and nothing reports
it.
affects: docs/verification/2026-08-20-scan-pathspec.mutations/ (M18-M23),
docs/verification/2026-08-22-id-tokens.mutations/ (M19, M20, M27-M29, M31), and
docs/verification/2026-08-25-problem-triage.mutations/ (M05, M06, M08, M23, M32,
M36).
opened: 2026-08-27
status: open
Measured, not estimated. Against `main` at 860dce4: 152 of 184 exit 0, 166 with
PR-aap8nx fixed, and the remaining 18 are unchanged by that fix. Three causes,
all the same shape — a mutation whose target has moved on:

* six target `scripts/finalize-ids.sh`, deleted in c672c9f and replaced by
  `finalize-docs.sh`;
* six carry a python patch whose `assert old in s` anchor no longer matches the
  source it edits;
* six patch the `owner:` handling in `check-trace.sh` that 860dce4 removed —
  `AssertionError: mutation did not apply: 0 matches`. These six were live when
  this change began and were broken by the base branch moving under it, which
  is the argument for measuring the population at merge time rather than citing
  a figure from the day the work started. A mutation suite is evidence that a test
detects a defect, so one that cannot apply its defect is an empty row that
reads like a covered one. Whether each should be re-anchored or retired is a
judgement about what the original evidence claimed, which is why this is not
folded into PR-aap8nx.
