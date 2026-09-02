# Plan — six findings from a macOS hardware-key retrofit

Change branch: `retrofit-findings`. Problem items:
`docs/problems/DRAFT-retrofit-findings-hardware-key-retrofit.md`.

Each task is one problem item, fixed under TDD: the reproducing test is
written and watched red before the fix, and the `red -> green:` line beside
each task is filled in as the evidence lands.

## Task 1 — pipe swallows the qualification suite's exit status (PR-nzpp57)

Files touched: `skills/ratchet/SKILL.md`, `tests/skills.bats`.
The step-5 tool-qualification item gains a clause: capture the suite's exit
status from the command itself, never through a pipe — `run-tests.sh | tee`
records tee's status. Test: skills.bats grep anchors.
red -> green: `skills.bats: ratchet: tool qualification warns that a pipe
eats the suite's exit status` — watched red (grep found no anchor), green
after the clause landed.

## Task 2 — verification template silent on range-shaped finding headers (PR-geb5db)

Files touched: `templates/verification.md`, `tests/skills.bats`.
The finding-grammar bullet gains the warning that a header naming a range
opens no block and is reported MALFORMED-FINDING. check-review.sh already
enforces this; the template just never taught it.
red -> green: `skills.bats: verification template warns that a range in a
finding header opens no block` — watched red, green after the sentence
landed.

## Task 3 — script updates leave target ledger READMEs stale (PR-uavq3f)

Files touched: `skills/ratchet/SKILL.md`, `tests/skills.bats`.
The upgrade guidance gains a mandatory step: when /ratchet updates scripts in
a target project it also refreshes the grammar carriers — the four ledger
READMEs, `.guardrails/templates/verification.md`, and the AGENTS.md managed
block — from the same shipped version as the scripts.
red -> green: `skills.bats: ratchet: updating the scripts also refreshes the
ledger READMEs` — watched red, green after the step landed.

## Task 4 — qualification basis not recordable in config (PR-dcn2xc)

Files touched: `scripts/lib.sh`, `templates/config.yaml`,
`skills/ratchet/SKILL.md`, `tests/lib.bats`, `tests/skills.bats`.
`guardrails_commit` becomes an accepted (optional) config key so the recorded
basis is a commit, not just a version string; ratchet step 5 says to set it.
red -> green: `lib.bats: gr_check_config accepts a guardrails_commit key` —
watched red (exit 2, unknown config key), green after the schema gained the
key. `skills.bats: ratchet: the qualification basis names a commit, not just
a version` — same pattern.

## Task 5 — --setup false MISSING commit.gpgsign inside a worktree (PR-2qdy9c)

Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.
`run_setup` reads `commit.gpgsign` ignoring the worktree scope: a
worktree-scoped `false` is worktree-discipline doing its job, not a project
gap. A project whose shared config genuinely lacks the key still reports
MISSING from a worktree.
red -> green: `check-signing.bats: --setup ignores a worktree-scoped
commit.gpgsign false` — watched red (exit 1, MISSING commit.gpgsign), green
after the scope filter; `--setup still reports a real commit.gpgsign gap
from a worktree` pins the inverse.

## Task 6 — --strict conflates broken trust chain with unreadable trust root (PR-mvqm4s)

Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.
An unverifiable signature now asks a second question before reporting: is the
configured trust root readable at all? Configured-and-present but
permission-denied is an environment error — exit 2, naming `--setup` — in
the check path and in `--setup` alike. Configured-but-absent stays exit 1
(the typo case, a project error).
red -> green: `check-signing.bats: --strict exits 2 when the trust root
exists but cannot be read` — watched red (exit 1 UNVERIFIED); `--setup exits
2 when the trust root exists but cannot be read` — watched red (exit 1
UNREADABLE); `--setup exits 2 when the gpg keyring cannot be read` — watched
red (exit 1 UNPROVED, gpg error naming no permission problem). All green
after the guard; `--strict stays exit 1 when the trust root path is absent`
pins the typo case.

## Task 7 (added at the base merge, 2026-09-02) — finish-merge.sh unparseable on macOS (PR-xyu6en)

Files touched: `scripts/finish-merge.sh`,
`docs/problems/DRAFT-retrofit-findings-hardware-key-retrofit.md`.
Main's 5bc6495 put a `case` inside a `$(...)` substitution; bash 3.2 (macOS
/bin/sh) mis-parses its unparenthesised patterns and fails the whole script
at parse time. The three guard-4 patterns now carry the optional leading `(`.
red -> green: `check-ids.bats: every script parses as POSIX sh` plus ten
finish-merge.bats tests — red on macOS at the merge (11 failures, one
cause), green after; full suite 474/474, exit 0.
