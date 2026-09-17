# Developing guardrails

Guardrails is developed under its own rules. No exceptions — this repo is the
reference implementation of its own process.

## Non-negotiables

1. **All work happens in a git worktree.** Documentation and code alike. Never
   commit directly to `main`. One change gets one change worktree on one change
   branch off `main`; each plan task is dispatched to a subagent that works in
   its own task worktree, on a task branch off the change branch. That task
   worktree is **nested inside the change worktree**, at
   `.worktrees/<change-branch>-t<N>` for plan task `<N>`, or
   `.worktrees/<change-branch>-<tag>` where the dispatch has no task number
   (`worktree-discipline` step 1 gives both forms and the tags that go in the
   second; `merge-change`'s sequence header is where a fix dispatch's tag is
   required to be unique, and states why) — and the dispatcher
   names that path in the dispatch prompt, because a subagent here is
   pinned to the change worktree's subtree, so a worktree anywhere else is
   created successfully and is then unusable (`worktree-discipline` step 1).
   The subagent commits there and returns its dispatch report; the dispatcher
   — the agent in the change worktree — merges that task branch into the change
   branch and removes the task worktree and branch.
2. **Integration is a signed squash merge.** `main` receives exactly one signed
   commit per change. Intermediate worktree commits may be unsigned
   (`git -c commit.gpgsign=false commit`) — including the base merge, since
   `git merge` honors `commit.gpgsign` and will otherwise block on the key;
   the squash commit must be signed (`git commit -S`) and verified before the
   worktree is cleaned up. The agent stages the squash and hands over one
   command; **the user runs the signing**, and `finish-merge.sh` verifies the
   signature before it removes anything (`merge-change` steps 7 and 8).
3. **Run `tests/run-tests.sh` before any merge.** All bats tests must pass.
   Dispatch it rather than running it in your own context: a subagent runs the
   gate and returns the gate summary (`verify-before-merge`). The verdict comes
   from the reported pass/fail counts — exit 0 is not a pass.
4. **One change at a time.** A change reaches its signed squash before
   the next is opened. Parallelism lives inside a change, across tasks whose
   file sets do not intersect — never across changes.
5. **The local repository is the whole world. Never consult `origin`.** No
   `git fetch`, no `git push`, no reading `origin/<branch>` as though it were
   authoritative. Local `main` is the base branch, full stop: it is what a
   change branches from, what `merge-change` step 1 merges in, and what the
   signed squash is merged onto. Pushing is the user's, done when they
   choose, and an agent that fetches on their behalf blocks on a hardware key
   that only they can touch.

   **This overrides `merge-change` step 1's fetch**, and the override does cost
   something — state what, rather than claiming it is free. That step is written
   for shared repositories, and it is right about the mechanism: step 4's
   `DUPLICATE-ID` scan sees exactly the IDs in the merged tree, so a base merged
   from a local ref while `origin` is ahead gives it a smaller set to check.
   Skipping the fetch does make step 4 prove less.

   What makes that acceptable **here** is not the scan but the ID scheme:
   `check-ids.sh`'s own header records that IDs are minted at item-creation time
   and allocated against nothing, so "two branches cannot mint the same one by
   construction", and the base merge covers only "the vanishing case where
   random draws collide" — six characters from the 31-symbol alphabet
   `GR_ID_ANY` defines: 23 letters with the confusable ones dropped, plus 8
   digits. The residual risk is that collision going unseen until the other
   branch merges locally, where this same scan catches it. This rule also forbids agent
   pushes, so nothing an agent does here reaches a shared history unreviewed.

   That reasoning applies to a single-maintainer repository with random IDs. It
   does **not** generalise: a project with sequential IDs, or several people
   merging to a shared remote, should keep step 1's fetch and is why the skill
   still mandates it.

   Say so plainly in the verification record — "base merged from local `main`
   at `<commit>`, per AGENTS.md non-negotiable 5" — so a later reader knows
   the remote was out of scope by policy rather than skipped by accident.

## Writing: prose, names and messages

Write dry, technical prose. Say what something is. This applies to everything
written: messages to the user, documentation, strings in code, identifiers,
and commit messages.

- No metaphor, no anthropomorphism, no wordplay, no balanced contrast. A file
  exists in a directory; it does not sit there. A gate rejects a commit; it
  does not refuse one.
- Active voice. Cut filler. Do not editorialize.
- Replace these words: carries -> contains, lands -> is merged, survives ->
  remains, says -> states, holds -> contains, refuses -> rejects,
  load-bearing -> critical, ran -> was run, sits -> is in.
- Do not match existing style when it disagrees with these rules.

In code, additionally:

- No single-character names. No code golf.
- Name in concrete terms, and do not use the past participle: write
  `write_timestamp`, not `written_at`.

## Rules

- Scripts in `scripts/` are POSIX sh only: no bash-isms, no dependencies beyond
  git, grep, awk, sed. Use `sed -i.bak` (then remove `.bak`) for portability —
  BSD sed takes the suffix as a separate mandatory argument, so the bare
  `sed -i` eats the next word. `tests/portability.bats` enforces this.
- **Supported awk implementations: gawk, mawk, busybox awk, and BWK awk** (the
  `/usr/bin/awk` that ships with macOS, `awk version 20200816`). BWK awk is the
  strictest of the four and is the default on a stock macOS box, so a change
  measured only on gawk is not measured. Specifically: **a value that contains a
  literal newline must never reach `awk -v`** — BWK awk exits 2 before the
  program runs (`awk: newline in string ... at source line 1`), which is a gate
  that does not run rather than a gate that answers wrong. Flatten at the point
  of use. `tests/portability.bats` runs every script under a stub awk that
  reproduces this on any platform.
- The same caution applies to `date`: BSD `date` has no `-d`, and its `-v`
  adjustment has its own sign, so a relative date needs both spellings
  (`tests/helpers.bash:days_ago`).
- Every `case` pattern in executable shell opens with a leading `(` — the
  POSIX-optional spelling. bash 3.2 (macOS `/bin/sh`, forever) cannot parse a
  pattern's unbalanced `)` inside `$(...)`, and whether a `case` is inside a
  command substitution is not decidable by a line scan, so the uniform form is
  the rule everywhere. `tests/portability.bats` enforces this.
- **Verifying an OpenPGP signature needs a WRITABLE `~/.gnupg`.** gpg opens
  `trustdb.gpg` read-write even when only reading it — `--list-keys` does,
  `--trust-model always` does — so a sandboxed agent, or a container that
  mounts `~/.gnupg` read-only, can verify nothing: gpg exits
  `Fatal: can't open ... Operation not permitted`, git reports `%G?` as `N`,
  and a perfectly good commit reads as unsigned. Measured 2026-09-01 on macOS:
  the same file opens `O_RDONLY` and is denied `O_RDWR`, with correct
  ownership, mode `drwx------`, no ACLs and no flags — and the denial remains
  after disabling the agent's own sandbox, so it is the host application's TCC
  grant rather than the sandbox layer. To check a signature from such a shell,
  copy `pubring.kbx` and `trustdb.gpg` somewhere writable and point
  `GNUPGHOME` at the copy; `check-signing.sh --strict` then exits 0. It also
  exits 0 unaided in a terminal the user launched themselves, which is why
  `merge-change` step 7 hands the signed commit to the user instead of running
  it here.
- Every behavior change to a script requires a bats test in `tests/`.
- Skills live at `skills/<name>/SKILL.md` with `name` and `description`
  frontmatter. Skills are self-contained — they must not reference superpowers
  or other external skill suites.
- `scripts/` is the source of truth for the check scripts; `/ratchet` copies
  them into target projects. Never fork script logic into `templates/`.
- Plans and design docs live in `docs/plans/`, named `YYYY-MM-DD-<topic>.md`.
