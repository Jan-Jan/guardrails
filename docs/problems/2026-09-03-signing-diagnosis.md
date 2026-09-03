# Problem reports — check-signing.sh reports causes it did not measure

The first two items were found on 2026-09-01 while investigating PR-52rnrn,
and both are the same shape as the defect that investigation actually
uncovered: the gate states a cause it never read. Both were recorded here
before either was fixed, and both are resolved by the change that carries this
file.

Three more items joined them as the change proceeded and are still open:
PR-2scmvn, found by a task subagent running the suite four times; PR-r8q9m7,
split out of PR-52rnrn once the ssh half of the history was measured; and
PR-k4t9k2, found while merging bd41d7a, whose new environment guard misses the
state this whole investigation began from.

**PR-74gcqg**: A signature whose verifier could not run at all is reported as
`UNSIGNED (bad, expired, or revoked signature)` — the wording for a forgery.
affects: scripts/check-signing.sh, its `B|X|Y|R` branch; and
scripts/finish-merge.sh guard 1, which refuses cleanup on that verdict and
repeats the accusation.
opened: 2026-09-01
status: resolved
Root cause: `git log --format=%G?` reports `B` both for a signature the
verifier examined and rejected AND for a verifier that never ran, and the
`B|X|Y|R` branch printed the first reading as though it were measured —
`UNSIGNED (bad, expired, or revoked signature)`, on a commit that is signed.
Fixed by reporting `UNVERIFIED (the verifier did not accept this signature)`,
followed by the verifier's own output; it still fails in BOTH modes, exactly as
before. Reproduced by `check-signing: a verifier that cannot run is not called
a forgery` (tests/check-signing.bats), watched failing against the old wording.
The companion test `check-signing: a rejected signature still fails without
--strict` deliberately carries no `verifies:` annotation: it was green before
the fix and could not have been otherwise, so it pins the verdict against the
wording change without claiming to verify this item.

**PR-mtmr7h**: `check-signing.sh --setup` reports `MISSING gpg.format` against
a project that signs successfully with git's documented default, and returns
before the proof that would have found the real fault.
affects: scripts/check-signing.sh, `run_setup`'s first check and the
`_missing` early return.
opened: 2026-09-01
status: resolved
Root cause: `run_setup` read an unset `gpg.format` as absent, but git documents
the default as `openpgp` (`git-config(1)`: "Default is \"openpgp\""), so a
project that leaves it alone signs perfectly well — this repository's own
OpenPGP history is the proof. The check therefore named a non-problem to the
one operator who had none, and, because it set `_missing=1`, returned at
`[ "$_missing" -eq 0 ] || return 1` BEFORE the signing proof — the only half of
`--setup` that measures anything rather than reading settings. Fixed by
defaulting `_fmt` to `openpgp`, which also removes a latent
`git config gpg.format ""` written into the throwaway repository. Reproduced by
`check-signing: --setup does not call git's default format missing`; the
existing `check-signing: --setup names every missing piece of the
configuration` had its `MISSING gpg.format` assertion INVERTED to a negative
one rather than deleted, so the false positive is now gated against instead of
pinned in place, and that inverted assertion was itself watched failing first.

**PR-whkz8m**: `check-signing.sh` states a cause for a failed verdict that it never
read, because `git log --format=%G?` returns one letter and discards the
verifier's output.
affects: scripts/check-signing.sh, `check_commits` — all three non-passing
branches; and every reader of an `UNVERIFIED` line, including
scripts/finish-merge.sh guard 1, which repeats whatever it says.
opened: 2026-09-01
status: resolved
Recorded 2026-09-03, later than it was found, and that is worth saying: this
defect was investigated and fixed on 2026-09-01 as part of PR-52rnrn, which
named it in its statement. 817156c then closed PR-52rnrn on separate and
correct grounds — the merge flow was never broken, because it runs in the
maintainer's shell — and the reporting defect had no carrier of its own. It is
given one here rather than left implied by a resolved item, so the tests that
verify it name something that is still about them.
Root cause: `%G?` answers with a letter and zero bytes of stderr (measured:
a gpg dying on an unwritable trustdb reaches the script as `N`, silently), so
the script supplied a cause by guessing — it appended the
`gpg.ssh.allowedSignersFile` remedy to every failing verdict alike. On a
history signed both ways (22 ssh, 9 OpenPGP) that remedy was right for one
group and irrelevant to the other, and the OpenPGP failures were something else
entirely: gpg opens `trustdb.gpg` read-write even to read it. Fixed by asking
`git verify-commit` for the verifier's own words and printing them indented
under every non-passing verdict, and by suppressing `%G?`'s own stderr so the
reason appears exactly once and identically for both formats. Reproduced by
`check-signing: a failed verdict carries the verifier's own reason`,
`check-signing: an untrusted signature carries the verifier's reason too` and
`check-signing: the verifier's reason is reported once, under its verdict` —
one per branch of `check_commits`, each watched failing with its line removed.

**PR-2scmvn**: The verification suite fails intermittently in
`tests/check-ids.bats`, on a different test each time, with git unable to
create a temporary file.
affects: tests/run-tests.sh and tests/check-ids.bats; and, through them, every
gate verdict in this toolkit that rests on a single suite run.
opened: 2026-09-01
status: open
Found on 2026-09-01 by the T1 subagent of this change, which ran the full suite
four times in one task worktree: runs 1 and 4 green at 438 ok, runs 2 and 3 each
red on a DIFFERENT test — `poisoning gr_def_re changes every gate's verdict`,
then `check-ids: a draft ID fails even with --allow-draft-files`, the latter
with `commit_all` dying at `error: unable to create temporary file: Invalid
argument` / `failed to insert into database`. That is git failing to write a
tempfile, not a logic failure, and `check-ids.bats` does not exercise
`check-signing.sh` at all, so it is not this change. Both red runs started
immediately behind another full suite in the same worktree, which makes
transient temp-directory pressure the best available explanation; it could not
be reproduced deliberately, and `check-ids.bats` alone ran clean twice. Left
open rather than folded in: a suite that was green on 2 of 4 full runs makes
every "0 failures" in this repository's verification records a probabilistic
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
AMENDED 2026-09-03, and narrowed. This was split out of PR-52rnrn on 2026-09-01
carrying two things; PR-52rnrn's own closure (817156c) has since accepted the
first of them explicitly — the ssh commits stay unverifiable while no
`allowed_signers` file exists, and the flow never needs them verified because
`finish-merge.sh` checks the new HEAD only. That is an accepted gap and is not
reopened here. What remains, and what this item now carries alone, is the
second thing: no gate LOOKS. A merge gate that inspects only the commit it just
made reports a green tail over an unverifiable trunk indefinitely, and would do
so whatever the trunk contained.

Measured across all of `main` on 2026-09-03: 32 commits — 22 ssh-signed, 9
OpenPGP, 1 unsigned. The switch is at `31e2303` (2026-08-27), so the two eras
are contiguous rather than interleaved, and every ssh commit predates it. An
earlier draft of this item said "17 of the last 20", which was true of that
window and wrong as a description of the history; the whole-history figure is
the one that belongs in a ledger.

**PR-k4t9k2**: `trust_root_env_guard` treats a keyring it can READ as a working
one, so an unwritable `~/.gnupg` is still reported as a project fault.
affects: scripts/check-signing.sh, the openpgp branch of
`trust_root_env_guard` added by bd41d7a (PR-mvqm4s).
opened: 2026-09-02
status: open
Found on 2026-09-02 while merging bd41d7a into this change, by running its new
guard against the machine state that PR-52rnrn was originally reported from.
The guard fires on `[ ! -r "$_tr_home" ] || [ ! -x "$_tr_home" ]`. Here
`~/.gnupg` is both readable and executable; what it is not is WRITABLE, and
gpg opens `trustdb.gpg` read-write even when only reading it — measured, the
same file opens `O_RDONLY` and is refused `O_RDWR`. So gpg dies
`Fatal: can't open ... Operation not permitted`, `%G?` reads `N`, and the
verdict is `UNVERIFIED` at exit 1 — "the project is wrong" — for a fault that
is purely environmental. That is the case PR-mvqm4s exists to catch, and it is
the single most likely one to be hit, because it is what a sandboxed agent
sees. Not folded into the change that found it: extending the guard changes
which exit code a state produces, which is a decision belonging to the design
bd41d7a introduced rather than to this change, whose fix is orthogonal — it
makes the state DIAGNOSABLE by printing gpg's own words under the verdict,
without reclassifying it. A test for it must assert on writability, not on
`-r`/`-x`, and cannot simply chmod the directory, since removing `w` from a
directory the test user owns is exactly what the current guard already misses.
