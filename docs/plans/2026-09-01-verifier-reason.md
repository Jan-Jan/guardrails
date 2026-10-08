# check-signing.sh reports the verifier's own reason

**Goal:** when a signature does not verify, `check-signing.sh` prints what the
verifier actually said instead of a verdict letter and a guess.
**Implements:** no REQ/SDD items exist in this repository. This is a defect
fix; it resolves PR-52rnrn, PR-74gcqg and PR-mtmr7h.
**Safety class:** the toolkit itself is unclassified; it enforces class B/C
elsewhere.
**Verification:** `sh tests/run-tests.sh` (435 ok, 0 failures on bb7eee5).

## What was measured, on 2026-09-01, on the maintainer's machine

The commit at `bb7eee5` is signed with OpenPGP and **its signature is good.**
Against a writable copy of the same keyring and trustdb:

```
$ GNUPGHOME=<writable copy> git verify-commit HEAD
gpg: Good signature from "Jan-Jan <...>" [ultimate]
$ GNUPGHOME=<writable copy> git log -1 --format='%G?'
G
```

Against the real `~/.gnupg`, from a shell whose write access to it is
restricted:

```
$ git verify-commit HEAD
gpg: Fatal: can't open '/Users/.../.gnupg/trustdb.gpg': Operation not permitted
$ git log -1 --format='%G?'
N                      # and ZERO bytes on stderr
```

gpg opens the trustdb **read-write** — even for `--list-keys`, even under
`--trust-model always` — so any environment that cannot write to `~/.gnupg`
cannot verify anything. Measured directly: the file opens `O_RDONLY` fine and
`O_RDWR` fails.

### The history is signed two different ways

Measured across the last twenty commits, with a writable `GNUPGHOME`:

```
f64be47  PGP  G      bb7eee5  PGP  G      31e2303  PGP  G
860dce4  SSH  N      b7fbd7f  SSH  N      55b5784  SSH  N   ... 17 in all
```

Seventeen of the twenty are **ssh-signed** and three are **OpenPGP**, and the
two fail to verify here for entirely different reasons:

- the ssh ones because `gpg.ssh.allowedSignersFile` is unset and no
  `allowed_signers` file exists — the cause PR-52rnrn recorded, and correct
  for these;
- the PGP ones because gpg cannot open the trustdb read-write — a cause
  nothing in the toolkit has ever mentioned.

`check-signing.sh` printed the same `UNVERIFIED` line for both and appended
the ssh remedy to both. That is the defect exactly: one verdict for two
causes, with a guessed cause supplied for whichever one you happened to be
looking at. Applying the recorded remedy would have fixed seventeen commits
and left the three most recent — including every HEAD a merge gate inspects —
failing for a reason still unnamed.

Measured remedy for the PGP half, end to end:

```
$ GNUPGHOME=<writable copy of ~/.gnupg> .../check-signing.sh --strict
$ echo $?
0
```

So `finish-merge.sh`'s first guard passes from a sandboxed agent under one
environment variable.

**And the severity is narrower than PR-52rnrn recorded.** `~/.gnupg` is
read-only to every shell in the *agent's* process tree — `O_RDONLY` succeeds,
`O_RDWR` and `touch` are refused, with correct ownership, mode `drwx------`,
no ACLs and no flags — and it stays refused with the agent sandbox explicitly
disabled, which places it in the parent application's macOS TCC grants rather
than in the sandbox layer. In the maintainer's own terminal
`check-signing.sh --strict` **exits 0** on `main` (confirmed 2026-09-01). So
the merge path this toolkit prescribes was never blocked: `merge-change`
step 7 hands the compound to the user, and it runs in their shell.

That makes this a defect about **agents in sandboxes**, which is a normal
operating condition for this toolkit and not an edge case — and it is exactly
the condition the old code handled worst, printing a bare `UNVERIFIED` with a
remedy naming the wrong file. What is inside this repository is that the tool
never said why.

`git verify-commit` runs the same verification and lets the verifier's own
words through. That is the whole fix.

Two further defects, found by the same measurement and recorded before this
change touched anything:

- PR-74gcqg — a verifier that cannot run at all is reported as
  `UNSIGNED (bad, expired, or revoked signature)`. Reproduced: with
  `gpg.ssh.program` pointed at a stub that exits non-zero, `%G?` is `B`, and
  `B` is the branch that prints that wording. A crashed verifier is accused
  of forgery, in both modes, with nothing on stderr to correct it.
- PR-mtmr7h — `--setup` reports `MISSING gpg.format` on this machine. Git's
  documented default for `gpg.format` is `openpgp`; a project that leaves it
  unset signs perfectly well. The check names a non-problem AND returns at
  `_missing=1` before the proof, which is the half that would have found the
  real fault.

## Verdict vocabulary after this change

```
pass            — verifies against trusted signers (%G? = G)
WARN-UNVERIFIED — present, did not verify; passes unless --strict
UNVERIFIED      — present, did not verify; FAILS
UNSIGNED        — no signature at all; FAILS
```

`UNVERIFIED` becomes the label for every signature that did not verify and is
not tolerated: the `--strict` form of the untrusted case (unchanged), and the
rejected-or-crashed case that used to print `UNSIGNED`. `UNSIGNED` narrows to
what it says — no signature. Nothing that fails today starts passing: the
`B|X|Y|R` branch keeps `_fail=1` in both modes.

Checked against every existing assertion: `tests/check-signing.bats:24,60` and
`tests/finish-merge.bats:69` assert `UNSIGNED` on genuinely unsigned commits,
and `tests/check-signing.bats:40` / `tests/finish-merge.bats:84` assert the
untrusted-signature wording. None of them covers `B`, so none changes meaning.

### T1 — the verifier's reason reaches the output

**Files touched:** `scripts/check-signing.sh`, `tests/check-signing.bats`
**Parallel:** no (serial, first — T2 edits the same script)

Resolves PR-52rnrn and PR-74gcqg.

RED first, in `tests/check-signing.bats`. Add this fixture helper next to
`setup_ssh_signing`:

*(Code pruned at merge: 11 lines. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

Then three tests:

*(Code pruned at merge: 45 lines. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

Run them and watch all three fail for the right reason before touching the
script (`sh tests/run-tests.sh` runs the whole suite; `bats tests/check-signing.bats`
runs this file alone).

GREEN, in `scripts/check-signing.sh`. Add above `check_commits()`:

*(Code pruned at merge: 17 lines. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

Rewrite the `case` inside `check_commits` to:

*(Code pruned at merge: 35 lines. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

Update the header comment block to the vocabulary above, and state that every
non-passing verdict is followed by the verifier's own output, indented.

Expected: the three new tests pass, and the suite is 438 ok / 0 failures.

### T2 — `--setup` accepts git's default signature format

**Files touched:** `scripts/check-signing.sh`, `tests/check-signing.bats`
**Parallel:** no (serial, after T1 — same two files)

Resolves PR-mtmr7h.

RED first, in `tests/check-signing.bats`:

*(Code pruned at merge: 15 lines. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

Amend the existing test `--setup names every missing piece of the
configuration` (it asserts `MISSING gpg.format` on a repo with no signing
config at all): drop that assertion, keep the other two, and add

*(Code pruned at merge: 1 line. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

with a comment saying the assertion was removed because it was measured wrong,
not because it was inconvenient: a project with no `gpg.format` has openpgp,
and what it is actually missing is the key.

GREEN, in `run_setup`, replace

*(Code pruned at merge: 1 line. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

with

*(Code pruned at merge: 8 lines. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

and delete the whole `if [ -z "$_fmt" ]; then echo "MISSING gpg.format" ... fi`
block.

Expected: the suite is 439 ok / 0 failures.

### T3 — the ledgers and the prose that carried the wrong remedy

**Files touched:** `docs/problems/2026-08-27-signing-and-identity.md`,
`docs/problems/DRAFT-signing-verifier-reason-signing-diagnosis.md`,
`skills/merge-change/SKILL.md`, `AGENTS.md`
**Parallel:** no (serial, after T2 — its text states what T1 and T2 landed)

Not dispatched: resolving a problem item in the change that fixes it is the
orchestrator's step (`resolve-problem` step 4), and the two skill files are the
change's own instructions.

1. In `docs/problems/2026-08-27-signing-and-identity.md`, flip PR-52rnrn to
   `status: resolved` and append the resolution: the recorded diagnosis was
   wrong — the signature verifies; gpg opens the trustdb read-write and any
   environment that cannot write `~/.gnupg` cannot verify anything — and the
   real repository defect was the discarded reason, fixed in T1, reproduced by
   `check-signing: a failed verdict carries the verifier's own reason`.
   Say plainly that `allowed_signers` was never the fix here.
2. In the DRAFT ledger file, flip PR-74gcqg and PR-mtmr7h to
   `status: resolved`, each with its root cause and its reproducing test.
3. In `skills/merge-change/SKILL.md`, the step-8 refusal table says an
   `UNVERIFIED`/`UNSIGNED` refusal is "usually a missing or incomplete
   `gpg.ssh.allowedSignersFile`". That is the guess this change deleted from
   the script, still written down as advice. Replace it with: read the reason
   the gate now prints under the verdict — it is the verifier's own — and fix
   what it names; a missing signers file is only one of the things it says.
4. In `AGENTS.md`, add one line to the platform notes: gpg opens
   `~/.gnupg/trustdb.gpg` read-write even to read, so a sandbox or a container
   with `~/.gnupg` mounted read-only cannot verify a signature, and
   `GNUPGHOME` pointed at a writable copy is the way to check one from there.

Expected: `sh tests/run-tests.sh` still 439 ok / 0 failures (`skills.bats`
reads the skill files), and `check-trace.sh` reports the three items resolved.

### T4 — the reason is reported once, and by us

**Files touched:** `scripts/check-signing.sh`, `tests/check-signing.bats`
**Parallel:** no (serial, after T2 — same two files)

Also resolves PR-52rnrn; found by running T1's result against the real
repository.

With T1 in place, an ssh-signed commit with no trust root reports its reason
**twice**:

*(Code pruned at merge: 3 lines. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

The first copy is git's own diagnostic, leaked to stderr by
`git log --format=%G?` and landing **above** the verdict, unindented, where it
reads as a separate failure about a different commit. The second is ours,
indented under the verdict it explains.

Worse, the leak is **format-dependent**: git emits it for ssh signatures and
emits nothing at all for OpenPGP ones, which is the exact asymmetry this change
exists to remove. Half the verdicts would carry a stray unattached line and
half would not.

RED first, in `tests/check-signing.bats`:

*(Code pruned at merge: 20 lines. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

GREEN, in `check_commits`, one character of redirection:

*(Code pruned at merge: 1 line. Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.)*

`%G?` is asked for the verdict letter only; whatever git wants to say about
how it got there is collected deliberately by `verifier_reason` instead, where
it is indented under the verdict and where OpenPGP and ssh behave alike. A
`git log` that fails outright still leaves `gstat` empty, which falls to the
`*)` branch and is reported from the commit's own headers.

Expected: 440 ok, 0 failures.

## Review round 1 — seven findings

The independent review of `signing-verifier-reason` returned seven findings and
a verdict of "the code does what it claims, but three claims outrun their
evidence". All seven are accepted; none is disputed. Two tasks, disjoint file
sets, so they may run in parallel.

Findings 1, 2 and 7 share a shape worth naming: **the change added three
behaviours that no test would miss.** The reviewer proved it the only way that
counts — by deleting each line and watching the suite stay green.

### T5 — the untested halves get tests

**Files touched:** `tests/check-signing.bats`
**Parallel:** yes (with T6)

Answers finding-1, finding-2 and finding-7. No script change: the code is
right, the evidence is missing.

**finding-1 — the `_fmt` default is untested.** Deleting
`[ -n "$_fmt" ] || _fmt=openpgp` leaves all 29 tests green, because both
PR-mtmr7h tests assert only the *absence* of `MISSING gpg.format`, which
deleting the MISSING block alone already satisfies. But `_fmt` is written into
the throwaway repository, and an empty value is not "unset" — measured
directly:

*(Code pruned at merge: 3 lines. Files touched: `tests/check-signing.bats`.)*

versus, with the default applied, git proceeding to actually attempt the
signature. So without the default, `--setup` reports `UNPROVED` against a
project whose configuration is fine — and that project shape (OpenPGP,
`gpg.format` unset) is this repository's own.

*(Code pruned at merge: 19 lines. Files touched: `tests/check-signing.bats`.)*

Confirm it reddens with the default line deleted, and that it does not hang:
a signing key that does not exist must make gpg fail fast rather than wait on
a pinentry. If it does hang, say so and pick a key spelling that fails
immediately instead — do not add a timeout to paper over it.

**finding-2 — `verifier_reason` in the `U|E` branch is untested.** Deleting
that one call leaves all 29 tests green, though the reviewer measured the
branch being reached three times across the suite. Both `verifies: PR-52rnrn`
tests land in `*)` (`%G?` = `N`). Of the three call sites this change adds,
`B|X|Y|R` is covered, `*)` is covered, and `U|E` is not.

Reach it with a signature that verifies cryptographically but whose key is not
trusted: a signers file that is **present and readable** — so the environment
guard does not fire — naming a *different* key.

*(Code pruned at merge: 15 lines. Files touched: `tests/check-signing.bats`.)*

**First measure, then write the assertion.** Confirm `git log -1 --format='%G?'`
really is `U` or `E` for that fixture — if it is `B`, this lands in the branch
already covered and the test proves nothing, so find another route to `U|E`.
Then run `git verify-commit` on it, see what the verifier actually says, and
assert on a stable substring of that. **If the verifier prints nothing at all
for this state, stop and report it**: that would mean the `U|E` call site can
never produce a reason, which is a finding about the change, not a test to
force green.

**finding-7 — the "once" test does not check "once".** It asserts exit 0, that
the reason is present, and that no line starts with `error:` at column one.
Two indented copies would pass unchanged. The name and PR-52rnrn's resolution
both say "exactly once", so make the assertion match the claim:

*(Code pruned at merge: 2 lines. Files touched: `tests/check-signing.bats`.)*

Keep the existing unindented-leak assertion; this is an addition, not a
replacement.

### T6 — the documentation that overstates or has gone stale

**Files touched:** `docs/problems/2026-09-03-signing-diagnosis.md`,
`docs/problems/2026-08-27-signing-and-identity.md`,
`skills/ratchet/SKILL.md`
**Parallel:** yes (with T5)

Not dispatched — ledger resolutions are the orchestrator's step
(`resolve-problem` step 4), and finding-4 is a skill file.

- **finding-3** — PR-52rnrn's resolution answers the first clause of its own
  statement and not the second. "The default gate reports that as a pass" still
  reproduces: non-strict exits 0 on an unverifiable HEAD. Say plainly in the
  resolution why that is now the right answer — the tolerant mode is the
  documented one, `finish-merge.sh` passes `--strict` unconditionally, and what
  changed is that both modes now print the reason — or give the residue its own
  carrier. Do not leave the item's headline unanswered.
- **finding-4** — `skills/ratchet/SKILL.md`'s "Prove the chain" item still says
  `--setup` checks that `gpg.format` "and the format's trust root are set and
  readable". T2 removed that requirement. Same stale-prose class T3 exists for.
- **finding-5** — PR-2scmvn says "green four times out of six", counting two
  single-file runs as suite runs. As measured it was **2 of 4**. An item whose
  point is that "0 failures" is probabilistic must not misstate its own
  probability.
- **finding-6** — the ledger preamble still says "Both items were found on
  2026-09-01 … recorded here before either was fixed". The file now defines
  five items and this change resolves two of them.

### Round 1 outcome

All seven findings answered. T6 (findings 3-6, documentation) was done by the
orchestrator; T5 (findings 1, 2, 7, tests) was dispatched, and its subagent
wrote the three tests and restored `scripts/` but stalled twice waiting on the
suite without committing. Its work was committed and merged by the
orchestrator, and **the three redden-proofs were then taken first-hand** rather
than relayed — which is the stronger evidence anyway, since the whole point of
these three tests is that the behaviour they cover survived deletion in
silence:

| Line removed from `scripts/check-signing.sh` | Test | Result |
| --- | --- | --- |
| `[ -n "$_fmt" ] \|\| _fmt=openpgp` | `--setup carries a real format into the proof` | red: `UNPROVED signing` / `invalid value for 'gpg.format': ''` |
| `verifier_reason "$c"` in the `U\|E` branch | `an untrusted signature carries the verifier's reason too` | red: verdict printed with no cause attached |
| (`verifier_reason` called twice in `*)`) | `the verifier's reason is reported once, under its verdict` | red: `the reason appeared 2 times, not once` |

`scripts/check-signing.sh` was restored after each and `git status` is clean;
the proofs changed no committed file.

## Review round 2 — five findings

The second review reproduced all three of round 1's redden-proofs
independently, then mutated the REST of the diff as well and found no line
that survives deletion in silence. Its five findings are all documentation, and
three of them are this change failing its own standard — "do not state a cause
you did not measure" — applied to itself.

| # | Finding | Disposition |
| --- | --- | --- |
| 1 | `README.md` still lists `gpg.format` among what `--setup` requires; T6 corrected only `ratchet` | Corrected, naming the default explicitly. |
| 2 | A test comment says both other PR-52rnrn tests land in `*)` (`%G? = N`). Measured: the broken-verifier fixture is `B`. | Corrected after measuring it directly (`%G? = B`). The conclusion it supported — that `U\|E` was the uncovered call site — was right; the stated reason was not. |
| 3 | PR-52rnrn's "the tolerant mode was never the gate" overstates by one call site: `merge-change` step 8 runs the bare form under `# verifies the new HEAD`. | Closed rather than documented: step 8 now passes `--strict`, and the resolution says so. |
| 4 | The rewritten header no longer records that a REJECTED signature fails in both modes, with no `WARN-` counterpart. | Restored to the table, with the `%G?` letters. |
| 5 | The ledger was finalized 2026-09-02 but the review loop pushed the merge to 2026-09-03. | Re-dated by hand to what `finalize-docs.sh` would have written, since it is a no-op once the file is not `DRAFT-`-named. |

Finding-2 is the one worth keeping in view: a change whose whole subject is a
tool asserting a cause it never read shipped a comment asserting a cause its
author never read. The reviewer measured it; the author had not.
