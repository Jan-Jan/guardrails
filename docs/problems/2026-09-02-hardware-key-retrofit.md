# Problem reports — findings from a macOS hardware-key retrofit

Six problems reported from running `/ratchet` to retrofit a target project on
macOS with GPG hardware-key signing in use. `affects:` names files rather than
item IDs for the reason `docs/problems/2026-08-27-macos-awk.md` gives:
guardrails keeps no REQ/SDD/LLR ledger of its own yet. When the ledgers
arrive, these lines get the IDs.

A related problem item is being addressed by another agent in a parallel
worktree (its ID is not on this branch, so it is not named here — naming it
would be a dangling reference); the reporter believes that item covers only a
subset of what is recorded below. Reconciled at merge, when both ledgers are
visible.

**PR-mvqm4s**: `check-signing.sh --strict` reports an unreadable trust root
(e.g. a `~/.gnupg` the process cannot read) identically to a broken trust
chain — UNVERIFIED, `%G?` = N, exit 1 — so an environment error reads as "the
project is wrong" and sends the operator hunting in the wrong place.
affects: scripts/check-signing.sh (--strict), tests/check-signing.bats.
opened: 2026-09-01
status: resolved
`check_commits` reported a permission-denied trust root through the same
UNVERIFIED path as an untrusted signature. A guard now exits 2 — naming
`--setup` — when the configured trust root exists but cannot be read (the
ssh signers file, or the openpgp keyring directory), lazily from the check
path so a project that never signs is untouched, and up front in `--setup`;
a configured path that does not exist stays exit 1, the typo case, a project
error. Reproduced by `tests/check-signing.bats: --strict exits 2 when the
trust root exists but cannot be read` and its two `--setup` twins.

**PR-2qdy9c**: `check-signing.sh --setup` reports a false MISSING
`commit.gpgsign` when run inside a worktree, precisely because the project
follows worktree-discipline, which deliberately leaves worktree commits
unsigned — so every guardrails project sees a false MISSING beside any true
one and learns to discount both.
affects: scripts/check-signing.sh (--setup), tests/check-signing.bats,
skills/worktree-discipline/SKILL.md.
opened: 2026-09-01
status: resolved
`run_setup` read the effective `commit.gpgsign`, which inside a worktree
includes the worktree scope that worktree-discipline deliberately sets
false; it now drops that scope (`git config --show-scope`, last non-worktree
value wins) so the project's answer is what is judged, while a shared config
that never set the key still reports MISSING from a worktree. Reproduced by
`tests/check-signing.bats: --setup ignores a worktree-scoped commit.gpgsign
false`.

**PR-uavq3f**: Nothing notices when a target project's installed ledger
READMEs go stale against the shipped grammar — the `owner:` field was removed
upstream while a target's copy kept teaching it, so one commit carried an
AGENTS.md and a docs/problems/README.md contradicting each other about a
required field, and the upstream test for the shipped side passed throughout.
affects: skills/ratchet/SKILL.md — the upgrade path, which is where this
drift arrived by (install.sh only links skills and was not implicated).
opened: 2026-09-01
status: resolved
The upgrade guidance replaced the scripts and the AGENTS.md managed block
but never named the ledger READMEs or the verification template as things
that move with them; ratchet's upgrade section now requires re-copying the
grammar's prose carriers from the same version the scripts came from. A
mechanical staleness gate running in the target between updates remains
unbuilt — this closes the path the reported drift actually arrived by.
Reproduced by `tests/skills.bats: ratchet: updating the scripts also
refreshes the ledger READMEs`.

**PR-dcn2xc**: The recorded tool-qualification basis is a version string
alone, and versions move — upstream advanced mid-change and the reviewer had
to establish by hand that the delta was docs-only before "435 tests at 0.5.1"
meant anything; a recorded `guardrails_commit:` would make the basis
checkable instead of nominal.
affects: skills/ratchet/SKILL.md (step 5 tool-qualification item),
templates/config.yaml, scripts/lib.sh (config schema).
opened: 2026-09-01
status: resolved
The config schema is closed, and it had no `guardrails_commit` key — so a
target project literally could not record the checkable half of the basis
without failing every gate at exit 2. `guardrails_commit` is now an accepted
optional key, the shipped template documents it, and ratchet step 5 records
it alongside the version. Reproduced by `tests/lib.bats: gr_check_config
accepts a guardrails_commit key`, red at exit 2 before the schema knew the
key.

**PR-geb5db**: The verification-record template does not warn that a range in
a finding header opens no block, so a reviewer who writes `finding-1..3`
style headers produces findings no gate attributes a `disposition:` to.
affects: templates/verification.md — check-review.sh already reports the
shape (MALFORMED-FINDING, via the deliberately broad gr_finding_shaped) and
needed no change.
opened: 2026-09-01
status: resolved
The gate enforced the rule but the template never taught it, so reviewers
met it as a failure instead of as guidance; the finding-grammar bullet now
says a range opens no block and each finding gets its own header. Reproduced
by `tests/skills.bats: verification template warns that a range in a finding
header opens no block`.

**PR-xyu6en**: `finish-merge.sh` does not parse at all under macOS `/bin/sh`
(bash 3.2 in sh mode): the guard-4 `case` inside a `$(...)` command
substitution trips that shell's parser unless the patterns carry the optional
leading `(` — `syntax error near unexpected token ';;'`, exit 2 on every
invocation, so no merge can ever be finished on a stock Mac.
affects: scripts/finish-merge.sh guard 4 (nested-worktree scan) — arrived on
the base branch in 5bc6495 and was found by this change's step-1 base merge,
the same route PR-mu8ybm took.
opened: 2026-09-02
status: resolved
bash 3.2 mis-parses `case` patterns inside `$(...)` when they lack the
optional leading parenthesis; the three guard-4 patterns now carry it. The
reproducing test is the existing `tests/check-ids.bats: every script parses
as POSIX sh`, red on macOS (11 failures, all this one cause) before the fix
and green after; the platform-independent sweep for the class is that same
test, which `sh -n`s every script — it can only convict on a shell that
exhibits the bug, which macOS's is.

**PR-nzpp57**: The ratchet tool-qualification instruction does not warn that
piping the qualification suite (e.g. into `tee`) makes `$?` the pipe's exit
status rather than the suite's, so the recorded pass/fail can be the wrong
command's — the reporter nearly recorded a wrong result this way.
affects: skills/ratchet/SKILL.md (step 5 tool-qualification item).
opened: 2026-09-01
status: resolved
The item said to capture the suite's exit code but not that a pipe replaces
`$?` with the pipe tail's status; the clause now says to capture it from the
run itself, never through a pipe, with the redirect shape spelled out.
Reproduced by `tests/skills.bats: ratchet: tool qualification warns that a
pipe eats the suite's exit status`.
