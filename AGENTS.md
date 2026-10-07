# Developing guardrails

Guardrails is developed under the rules it ships, without exception.

## Non-negotiables

1. **Do all work in a git worktree**, documentation and code alike. Never
   commit directly to `main`. Give one change one change worktree on one change
   branch off `main`. Dispatch each plan task to a subagent that works in its
   own task worktree, on a task branch off the change branch,
   **nested inside the change worktree**:
   `.worktrees/<change-branch>-t<N>` for plan task `<N>`, or
   `.worktrees/<change-branch>-<tag>` where the dispatch has no task number.
   `worktree-discipline` step 1 gives both forms and the tags that go
   in the second; `merge-change`'s sequence header requires a fix dispatch's
   tag to be unique. The dispatcher names that path in the dispatch prompt: a
   subagent here is pinned to the change worktree's subtree, so a worktree
   anywhere else is created and then unusable. The subagent commits there and
   returns its dispatch report. The dispatcher, in the change worktree, merges
   the task branch into the change branch and removes the task worktree and
   branch (`sh scripts/task-worktree.sh merge <tag>`).
2. **Integrate a change as a signed squash merge.** `main` receives exactly one
   signed commit per change. Worktree commits may be unsigned
   (`git -c commit.gpgsign=false commit`), the base merge included: `git merge`
   honors `commit.gpgsign` and otherwise blocks on the key. Sign the squash
   commit (`git commit -S`) and verify it before the worktree is removed. The
   agent stages the squash and hands over one command; **the user runs the
   signing**, and `finish-merge.sh` verifies the signature before it removes
   anything (`merge-change` steps 7 and 8).
3. **Run `tests/run-tests.sh` before any merge.** Every bats test must pass.
   Dispatch it to a subagent, which runs the gate and returns the gate summary
   (`verify-before-merge`); do not run it in your own context. Read the verdict
   from the reported pass and fail counts. Exit 0 is not a pass.
4. **Use local `main` as the base branch. Never consult `origin`.** No
   `git fetch`, no `git push`, no reading `origin/<branch>` as authoritative.
   A change branches from local `main`, `merge-change` step 1 merges local
   `main` in, and the signed squash is merged onto local `main`. Pushing is the
   user's, done when they choose; an agent fetch blocks on a hardware key that
   only the user can touch.

   **This overrides `merge-change` step 1's fetch**, and it makes step 4's
   `DUPLICATE-ID` scan check a smaller set of IDs.
   `docs/adr/ADR-y8jmes-local-main-is-the-base.md` states that cost, why it is
   accepted in this repository, and why the override does not apply to a
   project with sequential IDs or a shared remote.

   State it in the verification record: "base merged from local `main` at
   `<commit>`, per AGENTS.md non-negotiable 4".

## Code: names

- No single-character names. No code golf.
- Name in concrete terms.

## Rules

- Write scripts in `scripts/` in POSIX sh only: no bash-isms, no dependencies
  beyond git, grep, awk, sed. Use `sed -i.bak`, then remove the `.bak`: BSD sed
  takes the suffix as a separate mandatory argument, so a bare `sed -i` takes
  the next word as the suffix. `tests/portability.bats` enforces this.
- **Support four awk implementations: gawk, mawk, busybox awk, and BWK awk**
  (`awk version 20200816`, the default `/usr/bin/awk` on stock macOS). BWK
  awk is the strictest of the four; measure a change on it, not on gawk alone.
  **Never pass a value that contains a literal newline to `awk -v`**: BWK awk
  exits 2 before the program runs (`awk: newline in string ... at source
  line 1`). Flatten the value at the point of use. `tests/portability.bats`
  runs every script under a stub awk that reproduces this on any platform.
- BSD `date` has no `-d`, and its `-v` adjustment uses its own sign syntax.
  Write a relative date in both spellings (`tests/helpers.bash:days_ago`).
- Open every `case` pattern in executable shell with a leading `(`, the
  POSIX-optional spelling. bash 3.2 (macOS `/bin/sh`) cannot parse a pattern's
  unbalanced `)` inside `$(...)`, and a line scan cannot decide whether a
  `case` is inside a command substitution, so use the form everywhere.
  `tests/portability.bats` enforces this.
- **Verifying an OpenPGP signature needs a writable `~/.gnupg`.** gpg opens
  `trustdb.gpg` read-write even to read it; `--list-keys` and
  `--trust-model always` both do. With `~/.gnupg` read-only (a sandboxed agent,
  or a container that mounts it read-only), gpg exits
  `Fatal: can't open ... Operation not permitted`, git reports `%G?` as `N`,
  and a signed commit reads as unsigned. On macOS the denial comes from the
  host application's TCC grant, so disabling the agent's sandbox does not
  remove it. To check a signature from such a shell, copy `pubring.kbx` and
  `trustdb.gpg` to a writable directory and set `GNUPGHOME` to it;
  `check-signing.sh --strict` then exits 0. It also exits 0 in a terminal the
  user launched, which is why `merge-change` step 7 hands the signing to the
  user.
- Add a bats test in `tests/` for every behavior change to a script.
- Put each skill at `skills/<name>/SKILL.md` with `name` and `description`
  frontmatter. Keep skills self-contained: no reference to superpowers or other
  external skill suites.
- Give a `SKILL.md` the `##` sections `Preconditions`, `Steps`, `Red flags`,
  `Done when` and, where it has reference files, `References`, in that order,
  in at most 2,000 words. Put reasons, worked examples and conditional material
  in `skills/<name>/references/<topic>.md`, and name each file in `References`
  with the condition for reading it. Keep incident history in `docs/plans/` and
  git. `tests/skills.bats` enforces this.
- `scripts/` is the source of truth for the check scripts; `/ratchet` copies
  them into target projects. Never fork script logic into `templates/`.
- Put plans and design docs in `docs/plans/`, named `YYYY-MM-DD-<topic>.md`.
