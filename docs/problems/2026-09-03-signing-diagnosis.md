# Problem reports — check-signing.sh reports causes it did not measure

Two open items and one accepted (PR-2scmvn) from an investigation, begun on 2026-09-01, into a
`check-signing.sh` that stated a cause it never read: PR-2scmvn, found by a
task subagent running the suite four times; PR-r8q9m7, split out once the ssh
half of the history was measured; and PR-k4t9k2, found while merging bd41d7a,
whose new environment guard misses the state the investigation began from.

**PR-2scmvn**: The verification suite fails intermittently in
`tests/check-ids.bats`, on a different test each time, with git unable to
create a temporary file.
affects: tests/run-tests.sh and tests/check-ids.bats; and, through them, every
gate verdict in this toolkit that rests on a single suite run.
opened: 2026-09-01
status: accepted
disposition: ruled on 2026-10-03 — not reproducible; cause disproven.
The suite now instruments a failed test instead of relying on a mechanism.
Six full suite runs across three concurrent lanes in one worktree — a heavier
condition than the observation below, which describes one run started
immediately behind another — were all 749 of 749, exit 0, with
the TAP plan equal to the result count. Six clean runs exclude the observed
two-in-four rate at about the 98% level and do not exclude a per-run rate near
20%, where zero failures in six has probability 26%. That is a bound, not a
proof, and it is what this ruling rests on. Twenty-four further runs of
`tests/check-ids.bats` alone were also clean and are not counted: the
observation below already records that configuration as non-reproducing.
The "transient temp-directory pressure" explanation below rests on a claim in
`tests/helpers.bash` that `/tmp` is a tmpfs with a fixed inode budget. That is
false on macOS, which is the host this suite was measured on and the one
AGENTS.md calls a stock box for its default awk: `/tmp` is APFS and
reported over six billion free inodes at 0% used on 2026-10-01, and bats writes
under `$TMPDIR` in /var/folders rather than `/tmp` at all. The teardown that
bounds that occupancy is byte-identical from `590867a` (2026-08-27) to the base
`051becc`, and this change is what ends the range, by adding the
`gr_failure_environment` call — the `teardown()` function, not the whole file,
which does change across that range — so the mitigation for the named cause was
already active on the day of the failure. This change corrects that comment, because it is what
produced the misdiagnosis.
**The exposure is wider than a lost run, and an earlier draft of this ruling
stated the opposite.** That draft had the fault making a run falsely red
rather than falsely green, and so costing no verdict. An independent reviewer refuted it.
The deleted `tests/evidence.sh` derived its red figure by subtracting the new
tests that PASSED from the new tests submitted, so a test failing for an
environmental reason was counted as a test that proves a defect was fixed, and
dropped off the list of tests that cannot go red; the deleted records quoted a
figure derived that way. Every guard that script had was satisfied by a run
which completed with a spurious failure in it. A mutation kill table inverts the same way, as the corrected
comment in `tests/helpers.bash` states.
Accepted with that understanding recorded. The search stops,
and `tests/helpers.bash` now prints five labelled facts — `tmpdir`, `testdir`,
`inodes`, `blocks` and `openfiles` — on any test that did not complete, so a recurrence is identifiable
from the run that contains it rather than from whoever reads the log. Reopen on any such
capture.
Found on 2026-09-01 from four full suite
runs in one task worktree: runs 1 and 4 green at 438 ok, runs 2 and 3 each
red on a DIFFERENT test — `poisoning gr_def_re changes every gate's verdict`,
then `check-ids: a draft ID fails even with --allow-draft-files`, the latter
with `commit_all` dying at `error: unable to create temporary file: Invalid
argument` / `failed to insert into database`. That is git failing to write a
tempfile, not a logic failure, and `check-ids.bats` does not exercise
`check-signing.sh` at all, so it is not this change. Both red runs started
immediately behind another full suite in the same worktree, which makes
transient temp-directory pressure the best available explanation; it could not
be reproduced deliberately, and `check-ids.bats` alone was run twice with no
failure. Left open rather than folded in: a suite that was green on 2 of 4 full
runs makes every "0 failures" in this repository's verification records a probabilistic
claim, and deciding what to do about that is a larger question than this
change. It is recorded here so the next red run is recognised rather than
re-diagnosed.

**PR-r8q9m7**: Nothing in the toolkit ever asks whether the history is
signed — `check-signing.sh` defaults to HEAD and `finish-merge.sh` passes it a
single commit — so the twenty-two unverifiable ssh-signed commits on `main` are
not merely unfixed, they are unmeasured by every gate.
affects: scripts/check-signing.sh, whose default scope is HEAD alone;
scripts/finish-merge.sh guard 1, which therefore attests the squash commit and
nothing beneath it.
opened: 2026-09-01
status: open
The ssh commits stay unverifiable while no
`allowed_signers` file exists, and the flow never needs them verified because
`finish-merge.sh` checks the new HEAD only. That is an accepted gap (817156c)
and not this item. This item is that no gate LOOKS. A merge gate that inspects only the commit it just
made reports a green tail over an unverifiable trunk indefinitely, and would do
so whatever the trunk contained.

Measured across all of `main` on 2026-09-03: 32 commits — 22 ssh-signed, 9
OpenPGP, 1 unsigned. The switch is at `31e2303` (2026-08-27), so the two eras
are contiguous rather than interleaved, and every ssh commit predates it. An
earlier draft of this item stated "17 of the last 20", which was true of that
window and wrong as a description of the history; the whole-history figure is
the one that belongs in a ledger.

**PR-k4t9k2**: `trust_root_env_guard` treats a keyring it can READ as a working
one, so an unwritable `~/.gnupg` is still reported as a project fault.
affects: scripts/check-signing.sh, the openpgp branch of
`trust_root_env_guard` added by bd41d7a.
opened: 2026-09-02
status: open
Found on 2026-09-02 while merging bd41d7a into this change, by running its new
guard against the machine state the investigation began from.
The guard fires on `[ ! -r "$_tr_home" ] || [ ! -x "$_tr_home" ]`. Here
`~/.gnupg` is both readable and executable; what it is not is WRITABLE, and
gpg opens `trustdb.gpg` read-write even when only reading it — measured, the
same file opens `O_RDONLY` and is denied `O_RDWR`. So gpg dies
`Fatal: can't open ... Operation not permitted`, `%G?` reads `N`, and the
verdict is `UNVERIFIED` at exit 1 — "the project is wrong" — for a fault that
is purely environmental. That is the case the guard exists to catch, and it is
the single most likely one to be hit, because it is what a sandboxed agent
sees. Not folded into the change that found it: extending the guard changes
which exit code a state produces, which is a decision belonging to the design
bd41d7a introduced rather than to this change, whose fix is orthogonal — it
makes the state DIAGNOSABLE by printing gpg's own words under the verdict,
without reclassifying it. A test for it must assert on writability, not on
`-r`/`-x`, and cannot simply chmod the directory, since removing `w` from a
directory the test user owns is exactly what the current guard already misses.
