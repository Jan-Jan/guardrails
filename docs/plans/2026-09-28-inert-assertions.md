# Inert `[[ ]]` assertions in the bats suite

Resolves `PR-tenhv4` and `PR-8uggn4`, both in
`docs/problems/2026-09-17-mutation-evidence.md`.

## The defect

Under bash 3.2 — macOS `/bin/bash`, and the shell bats 1.11.0 runs test bodies
with — a `[[ ... ]]` compound command that returns false does not trigger
`errexit`. Reproduced on this machine at `3.2.57(1)-release`:

```
$ /bin/bash -c 'set -eE; trap "echo TRAP-FIRED" ERR; [[ a == b ]]; echo REACHED'
REACHED                                   # exit 0
$ /bin/bash -c 'set -eE; trap "echo TRAP-FIRED" ERR; [ a = b ]; echo REACHED'
TRAP-FIRED                                # exit 1
```

Two compound commands have this hole, not one. `(( 1 == 2 ))` reaches the next
line the same way. A `[` test, a `let`, an assignment from a command
substitution and a failing `grep` all stop it, so what the repair must cover is
the two bracket compounds. `(( ))` appears nowhere in the suite today, so the
repair touches none; a rule covering it belongs with `PR-x4nb48`.

bats takes the test's verdict from the exit status of its body, which is the
status of the body's last command. A bare `[[ ]]` therefore reports a failure
only when it is the last command. Everywhere else its result is discarded.

## Population, measured

Counted with a block-aware scan over `tests/*.bats`, not by grep:

| form | count | live? |
|---|---|---|
| bare `[[ ... ]]`, not last in its body | 69 | no — result discarded |
| bare `[[ ... ]]`, last in its body | 232 | yes, by position only |
| `[[ ... ]] \` continuing into `\|\| { ...; false; }` | 135 | yes |
| `[[ ... ]] \|\| { ...; false; }` on one line | 316 | yes |

752 in all, and every `[[ ]]` in a test body is in exactly one row. The scan
tracks heredocs: a `}` at column one inside a quoted heredoc body — there is one
at `tests/check-trace.bats:1739`, in awk source a fixture writes out — ends no
test, and a scan that reads it as one undercounts the third row by nine.

Every one of the 301 tests `$output`; no other left-hand side appears. The
comparison is a glob in 299 of them — 260 `==` and 39 `!=` — and a regex (`=~`)
in the remaining two, at `tests/new-id.bats:222` and `:255`. So the guard can be
appended uniformly without reading any assertion's meaning.

`tests/helpers.bash` and the `tests/*.sh` helpers contain no bare `[[ ]]`.

### PR-tenhv4 undercounts by two

The item states 67. The true figure is **69**. Its counting rule was "lines
that are exactly a bare `[[ ... ]]`", which excludes a bare assertion with
a trailing comment; `tests/check-trace.bats:252` and `:269` are both
`[[ "$output" == "checked:"* ]]   # summary lines only: ...` and both are
inert. The undercount has the same cause as the defect: a definition that
excluded a case without stating it.

## Scope

The 232 last-position assertions are live only because of their position. A
line appended below any of them makes it inert, with nothing reporting the
change — which is how `650f090` added two to this population while using the
guarded form correctly elsewhere in the same diff. So the repair covers all
301, not the 69: after it, position does not decide whether an assertion can
fail, and a reader can confirm that by grep rather than by trusting a position
analysis.

`PR-8uggn4` is resolved here because `tests/lib.bats` contains three of the
inert assertions and the item's own note asks for one audit of that file rather
than two.

## Tasks

- **T1** — the gate. **Cut from this change and not delivered.** It was built
  as a tree scan in `tests/portability.bats`, written first and failing, and
  calibrated in both directions. Four review rounds then found sixteen
  defective or over-broad readings across six revisions of it, and a blind spot
  live in the tree: an unguarded assertion anywhere in roughly lines 240 to 330
  of `tests/check-ids.bats` was reported by nothing. Every defect was in the
  scan's hand-written approximation of shell lexing, and its failure mode is
  silence. The maintainer ruled to ship T2 to T5 and move the gate to its own
  change, `PR-x4nb48`, with round 4's report as its brief. The reasoning is in
  the verification record under "Why the gate is not here".
- **T2** — the repair. Append `|| { echo "$output"; false; }` to all 301.
  Uniform, one shape, mechanical.
- **T3** — `PR-8uggn4`: give `tests/lib.bats`'s "every key, scalar and list
  alike" test a scalar key, which is what it claims and has never exercised.
- **T4** — re-prove the kill that the inert assertions mask. Mutation
  `2026-08-22-id-tokens.mutations/M39.sh` deletes `finalize-docs.sh`'s
  whitespace guard; `tests/finalize-docs.bats` reports `ok` against it today.
  It must report `not ok` after T2.
- **T5** — ledger and verification record.

- **T6** — record `PR-7za3at`, the same defect in a `!`-negated command, found
  by a parallel session during review. Ten assertions, not repaired here.

## What this change does not do

It ships no gate, so nothing keeps the 301 assertions guarded. That is
`PR-x4nb48`, and it is the largest gap this change leaves.

It does not convert assertions to `[ ]`. Substring matching is why they are
`[[ ]]`, and a rewrite to `case` or `grep` would touch the meaning of 301
assertions rather than their guarding.
