# Verification record — ratchet-gap-analysis

Date: 2026-08-22
Branch: `ratchet-gap-analysis`
Change: ratchet gap analysis, safety-class ADR, human setup checklist
(documentation only — no script or test behaviour changed)

## Step 1 — base branch merge

**Merged from a local ref, not a confirmed fetch.** `git fetch origin` fails in
this environment with exit 128:

```
Bad owner or permissions on /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf
fatal: Could not read from remote repository.
```

The file is a symlink owned by `nobody:nogroup`, which OpenSSH refuses — a
system configuration fault, unrelated to this repository.

Base merged from local `main` at **c672c9f** ("feat: item IDs are random tokens
minted when the item is written"). `refs/remotes/origin/main` also stood at
c672c9f, but that ref could not be refreshed, so it is not independent
confirmation. `git merge main` reported "Already up to date".

Recorded per the `merge-change` fallback so a later reader knows what the
duplicate scan was compared against. Risk accepted by the user: the repository
is single-committer and this change touches no code.

## Step 2 / 6 — verification suite

`./tests/run-tests.sh` (the repo's `verify_commands` equivalent; bats-core
1.11.0):

```
1..212
passed: 212
failed: 0
```

Run before the change (baseline), after the documents were written, and again
after the final edits. Identical every time — expected, as no test or script
was touched.

## Correction made during verification

An earlier draft of the setup checklist asserted that no `allowed_signers` file
existed. That was inferred, not checked, and it was wrong:
`gpg.ssh.allowedSignersFile` is configured and the file is maintained with a
`valid-before` bound across a key rotation. `check-signing.sh` therefore
verifies signatures rather than passing them with `WARN-UNVERIFIED`, and
`--strict` can be enabled in CI immediately. Both documents were corrected
before merge.

## Step 3 — ledger finalization

**Not applicable.** No ledger directories exist yet and no `DRAFT-` ledger file
was created, so there is nothing for `finalize-docs.sh` to rename.

## Steps 4 / 5 — check scripts

**These could not be run as merge gates: `.guardrails/` does not exist in this
repository.** That absence is the subject of the change, not an oversight.

```
$ ./scripts/check-ids.sh
guardrails: config not found: .guardrails/config.yaml
```

Run instead against a synthesised config from `templates/config.yaml`
(`safety_class: A`, all else default), purely as evidence for the gap analysis:

```
$ GR_CONFIG=<tmp>/config.yaml ./scripts/check-ids.sh   ; echo $?
     43 DRAFT-ID
      7 DUPLICATE-ID
      2 MALFORMED-ID
1

$ GR_CONFIG=<tmp>/config.yaml ./scripts/check-trace.sh ; echo $?
guardrails: doc_srs is configured as 'docs/requirements', which does not exist
2
```

Both are **expected failures** and are the documented blocker. `check-trace.sh`
exits 2 on config before reaching any gate, so its traceability gates are
unmeasured, not passed.

Confirmed separately that the three documents added by this change contribute
**zero** violations: the counts above are identical before and after, and no
violation names a `2026-08-22-ratchet-*` or `safety-class` file. Verified with
the toolkit's own patterns sourced from `lib.sh` rather than retyped.

## Step 6a — independent review

**Skipped, per safety class A** (`docs/adr/2026-08-22-safety-class.md`), under
which independent review is optional. The change adds no executable artefact
and claims no REQ/LLR — there are no requirement items in this repository yet.

## Open problem reports

None. The problem-report ledger does not exist yet (tooth 1).

## Verdict

Documentation-only change. Test suite green at 212/212. The two check scripts
cannot gate this merge because the machinery they belong to is not installed —
which is precisely what the merged documents analyse and schedule.
