# Problem reports — evidence.sh and a test name with an escaped backslash

One item found by the static gates of the `find-items` change at `07cd750`,
after `main` at `fb0db8d` was merged into it. `affects:` names files, because
guardrails keeps no REQ/SDD/LLR ledger of its own. `find-items` changes neither
file; it records the item and does not fix it.

**PR-9aaart**: `tests/evidence.sh main` exits 2 before it prints any figure on a branch that contains `main` at `fb0db8d`, because the test name at `tests/task-worktree.bats:173` contains `\\001` in the source and bats reports it as `\001`, so the name read from the source does not match the name the base run reports.
affects: tests/evidence.sh, the check at line 129 (at `35570e8`) that prints "evidence: the base run did not report the tests it was given"; tests/task-worktree.bats:173, the test "task-worktree start: skips an ignored entry whose name contains the byte \\001, and states it".
opened: 2026-10-04
status: resolved
The output at `07cd750`, run once from the `find-items` change worktree:

    evidence: the base run did not report the tests it was given
      task-worktree start: skips an ignored entry whose name contains the byte \\001, and states it
      	task-worktree start: skips an ignored entry whose name contains the byte \001, and states it
    exit 2

The same command at `5ba1e9c`, on the earlier base `fd9a867`, exited 0. That
base did not contain `tests/task-worktree.bats`. Whether the repair belongs in
`evidence.sh`'s name extraction or in the test name was not investigated.

Resolved on 2026-10-05 by the `pr-9aaart` change. bats strips the quotes around
a test name and evaluates the rest as a double-quoted shell string, so a
backslash before `\`, `"`, `$` or `` ` `` is removed. `tests/evidence.sh` read
names from the source in three places and applied none of this. It now
passes every name through one function, `test_names`, which applies the same
unescaping. The same fault also counted a new test with an escaped name as
going red although it passed, at the pass-list comparison, without an error.
Reproduced by the two tests in `tests/evidence.bats`, which run
`evidence.sh` in a fixture repository. Both exited 2 before the fix with
`evidence: the base run did not report the tests it was given`. After the
fix, `sh tests/evidence.sh main` exits 0.
