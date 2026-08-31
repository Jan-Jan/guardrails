# Signed Merge Command Implementation Plan

**Goal:** Replace the agent-run signed squash and cleanup with one transparent
command the user runs — sign, verify, remove the worktree, delete the branch —
where the destructive tail is guarded by a script that refuses to delete
anything it has not proved is safe to delete.
**Implements:** no requirement items exist in this repository yet. Traced to the
2026-08-30 requirements interview; S1–S10 below are the set the user confirmed.
**Safety class:** the toolkit itself is unclassified; it enforces class B/C
projects. Treat every gate change as class B — normal-case and abnormal-input
tests for each new behavior.
**Verification:** `sh tests/run-tests.sh` — 409 green at `4536e94` before this
change, and green plus the new tests after. Unlike the previous change this one
touches `scripts/`, so `AGENTS.md`'s rule applies: every behavior change to a
script requires a bats test.

**Amended mid-change.** The base branch moved to `55b5784` while T1–T4 were in
flight, bringing `tests/skills.bats` (a content lint over `skills/`) and a
`ratchet` edit adjacent to T4's. It was merged in per `merge-change` step 1;
the baseline is therefore 410, and the target 435.

---

## Why the split

The user asked for one command, and preferred a compound over a script for
transparency: the step that needs their hardware key should be a plain
`git commit -S` they can read, not something hidden behind a wrapper. But the
tail of that command force-deletes a branch — `-D`, necessarily, because git
does not consider a squashed branch merged — and an `&&` chain cannot guard
anything. Nothing in it stands between a subtly incomplete squash and
unrecoverable work.

So the command is compound and the destructive half is a script:

```sh
git commit -S -F <msgfile> && sh .guardrails/scripts/finish-merge.sh <branch>
```

Readable where it needs to be read, guarded where it needs to be guarded.

## Decisions

### D1 — the guards are the point, and none of them has an escape hatch

Three conditions, all proved before anything is removed:

1. **`check-signing.sh --strict` on HEAD.** A signature that cannot be verified
   fails. Always `--strict` — see D2.
2. **`git diff --quiet HEAD <branch>`.** `merge-change` step 1 has already
   merged the base branch into the change branch, so a correct squash leaves the
   base branch's tree *identical* to the change branch's. A difference means
   something did not land: an unstaged file, a partial `git add`, or a base that
   moved between step 1 and the squash. This is the only check standing between
   an incomplete squash and `-D` destroying the difference, and it costs one
   command.
3. **The worktree is clean.** Enforced by *not* passing `--force` to
   `git worktree remove` and letting git's own refusal be the guard.

A failing guard exits non-zero having removed nothing and deleted nothing. The
signed commit always survives — only cleanup is refused, which is a safe thing
to refuse.

### D2 — enforce sign, unconditionally

`check-signing.sh`'s default mode *passes* a signature it cannot verify
(`WARN-UNVERIFIED`, `%G?` = `U`/`E`), which is what a project gets with no
`gpg.ssh.allowedSignersFile`. Letting cleanup proceed on that would be a gate
that answers a question nobody asked. `finish-merge.sh` therefore always passes
`--strict`: no flag to remember, no behavior that changes with configuration.

The consequence is deliberate and benign. Enforcement lands *after* the commit
exists, so a project that cannot verify signatures does not lose its merge — the
signed squash is already on the base branch. What is refused is the cleanup, and
the refusal names the config that fixes it.

### D3 — the signers file becomes a hard prerequisite in `ratchet`

D2 makes the allowed_signers file load-bearing at every merge, so `ratchet`'s
current staging of it is now wrong:

> Until this exists, `check-signing.sh` passes signed commits with
> WARN-UNVERIFIED; after, enable `--strict` in CI.

A project that skips it would complete every merge and then fail to clean up
after itself, accumulating worktrees with no obvious cause. So `ratchet` does not
complete until signing is configured **and proved**.

Proved, not asserted: configuration being present says nothing about whether the
key can sign or the signature verifies. `check-signing.sh` grows a `--setup`
mode that makes a real signed commit in a throwaway repository — carrying the
project's resolved signing settings, so repo-local configuration is honored —
and reads `%G?` from it. (**Amended after implementation:** this said the
settings would be passed via `git -c`. They are written into the throwaway
repository's own config instead, so the existing verification loop can be
reused verbatim on a plain `git log` that carries no overrides. The
implementation's choice is the better one; the plan was wrong, not the code.) That exercises the entire chain
the merge depends on, and reuses the existing verification path rather than
forking its logic (`AGENTS.md`).

Retrofit consequence, stated plainly rather than discovered later: an existing
project must configure commit signing before it can finish adopting guardrails.
`ratchet` cannot do this itself — it needs each committer's public key — so it
stops and says exactly what is missing.

### D4 — the script derives the worktree path; it does not trust a pasted one

`finish-merge.sh` takes the change branch as its only argument and finds the
worktree with `git worktree list --porcelain`. A pasted path is a chance to
remove the wrong directory, and the branch name is already in the command the
agent prints.

If no worktree is registered for the branch — the harness may have removed it
already — removal is skipped and the branch is still deleted once the guards
pass. Tolerant about what is already gone, strict about what it proves.

### D5 — where the script may run

`finish-merge.sh` runs in the primary checkout, on the base branch, because HEAD
must be the squash commit it is verifying. Running it from a linked worktree
would verify the wrong HEAD, so it refuses: the base branch is detected with
`gr_base_branch` and the current branch must equal it. It also refuses when the
named branch is the base branch itself, and when that branch does not exist.

**Amended after implementation.** "The current branch must equal the base" is
unreachable as a *failure* inside the primary checkout: `gr_base_branch` reports
whatever the primary has checked out, so every branch there is its own base. The
reachable case is a **detached HEAD**, where `gr_base_branch` prints nothing —
and an empty base compares equal to an empty current branch, so the comparison
alone sails straight over it. The script therefore requires the base to be
non-empty *and* to match HEAD. Found by T1 while writing the test for it.

### D6 — re-running the compound command is safe

If the commit lands but a guard refuses, the user fixes the cause and runs the
**script alone**. Re-running the whole compound cannot double-commit: the squash
is no longer staged, so `git commit` fails and `&&` short-circuits before the
script. `merge-change` says this rather than leaving it to be discovered.

## The rule set

### `scripts/finish-merge.sh` (new)

- **S1 — one argument, the change branch.** Usage
  `finish-merge.sh <change-branch>`. More or fewer arguments, or an unknown
  flag, is a usage error (exit 2), matching `check-signing.sh`'s conventions.
- **S2 — POSIX sh, sourcing `lib.sh`,** consistent with every sibling in
  `scripts/`: no bash-isms, `sed -i.bak` if it ever edits in place, no
  dependency beyond git, grep, awk, sed. Carried into projects by `ratchet`'s
  existing `scripts/*.sh` copy — no `ratchet` change is needed for the file
  itself.
- **S3 — preconditions (exit 2).** The current checkout is not a linked
  worktree and is on the base branch (`gr_base_branch`); the named branch exists
  and is not the base branch.
- **S4 — guard 1, signature.** Run the sibling `check-signing.sh --strict` on
  HEAD. Non-zero fails (exit 1). Do not reimplement any part of it.
- **S5 — guard 2, the squash landed.** `git diff --quiet HEAD <branch>`. A
  difference fails (exit 1) and the message names what it means: the squash did
  not capture everything, so the branch must not be deleted.
- **S6 — guard 3, clean worktree.** `git worktree remove <path>` without
  `--force`; git refusing a dirty worktree is the guard. Its failure fails the
  script (exit 1).
- **S7 — order.** All guards pass, then remove the worktree, then
  `git branch -D`. Nothing destructive runs before every guard has passed.
- **S8 — no worktree registered:** skip removal, still delete the branch.
- **S9 — report what it did** on success: the commit verified, the worktree
  removed (or that there was none), the branch deleted.

### `scripts/check-signing.sh` (amended)

- **S10 — `--setup` mode.** Verifies that this project can produce a verifiable
  signature: `gpg.format`, `user.signingkey` and `commit.gpgsign` are set, the
  trust root for the format is configured and readable
  (`gpg.ssh.allowedSignersFile` for ssh), and a signed commit made in a
  throwaway repository with those resolved settings reads `%G?` = `G`. Exit 0
  when proved, 1 when the proof fails, 2 on usage or environment error. Naming
  each missing piece separately matters more than a single verdict — the caller
  is a human about to fix it.
- `--setup` is mutually exclusive with a rev range and with `--strict` (which it
  implies).

### `skills/merge-change/SKILL.md`

- **S11 — step 7 becomes a handoff.** The agent performs `git merge --squash`
  onto the base branch in the primary checkout and writes the commit message to
  a file **outside the repository** (an untracked message file inside it would
  dirty the tree the guards are about to inspect). It then hands the user the
  single compound command, and stops. The agent never runs `git commit -S`
  itself: signing may need a hardware touch, and starting a blocking wait on the
  user's behalf is what this replaces.
- **S12 — step 8 becomes confirmation.** On the user's word that the command
  succeeded, the agent confirms HEAD is the signed squash, then reports the
  merge — commit, IDs, verification record — and recommends compacting before
  the next change. R17 is preserved, only resequenced.
- **S13 — the refusal paths are documented, not discovered.** What each guard
  means when it fires, that the signed commit survives a refusal, and that the
  fix is to run the script alone rather than the whole compound (D6).
- **S14 — the existing rules stay verbatim in force:** no unsigned fallback
  ever; cleanup only after the signature check passes.

### `skills/ratchet/SKILL.md`

- **S15 — signing is a hard prerequisite.** The staged wording goes. Ratchet does
  not complete until `check-signing.sh --setup` passes, and says plainly that a
  retrofitted project must configure signing before adoption finishes.
- **S16 — the CI line keeps `--strict`** but no longer presents it as the point
  at which strictness begins; it begins at the first merge.

### `AGENTS.md` and `README.md`

- **S17 — correct who runs the squash.** `AGENTS.md` non-negotiable 2 and
  `README.md`'s workflow describe the signed squash as the agent's act. It is
  now handed to the user as one command, with the cleanup guarded.

## Tasks

Five tasks. T1–T4 touch disjoint file sets and may run in parallel; T5 is serial
because it describes what the others settle.

### T1 — `finish-merge.sh` and its tests (S1–S9)

**Files touched:** `scripts/finish-merge.sh`, `tests/finish-merge.bats`
**Parallel:** yes

TDD, test first, one behavior at a time. The fixtures need a real base branch, a
change branch squashed onto it, and a linked worktree — `tests/helpers.bash`
already has the signing helpers `check-signing.bats` uses; reuse them rather
than writing new ones. Tests to write, each watched failing first:

- happy path: guards pass, worktree removed, branch deleted, exit 0;
- guard 1: an unsigned HEAD fails, nothing removed, nothing deleted;
- guard 1: a signature present but unverifiable (no allowed_signers) fails,
  because `--strict` is unconditional (D2);
- guard 2: a change branch holding a commit the squash missed fails, and the
  branch still exists afterwards;
- guard 3: a dirty worktree fails, and the branch still exists afterwards;
- S8: no registered worktree — branch still deleted, exit 0;
- S3: run from a linked worktree, run on a non-base branch, branch absent,
  branch equals base, wrong argument count — each exit 2;
- ordering: after any guard failure, both the worktree and the branch survive.

### T2 — `check-signing.sh --setup` and its tests (S10)

**Files touched:** `scripts/check-signing.sh`, `tests/check-signing.bats`
**Parallel:** yes

TDD as above. The existing file's structure, exit-code conventions and message
style govern. Tests must not need a hardware key — use the file-based ssh key
and allowed_signers fixtures already in `tests/`. Cover: fully configured
project passes; each missing config element named individually; a key that
cannot sign; a signature that does not verify against the signers file;
`--setup` with a rev range and `--setup --strict` both usage errors.

### T3 — `merge-change` (S11–S14)

**Files touched:** `skills/merge-change/SKILL.md`
**Parallel:** yes

Rewrite steps 7 and 8. Preserve the red-flag table's existing rows and add ones
that earn their place. The command shown must be exactly the one T1 implements.

### T4 — `ratchet` (S15, S16)

**Files touched:** `skills/ratchet/SKILL.md`
**Parallel:** yes

Step 5's checklist item and the CI line. State the retrofit consequence.

### T5 — `AGENTS.md` and `README.md` (S17)

**Files touched:** `AGENTS.md`, `README.md`, `tests/check-ids.bats`,
`tests/lib.bats`
**Parallel:** no (serial, after T1–T4)

**Amended mid-change.** Three sweeps pin the number of scripts in `scripts/`
and redden the moment an eighth appears — two in `tests/check-ids.bats` (the
`gr_def_re` call-site pin and the POSIX-parse pin) and one in `tests/lib.bats`
(the `gr_root` guard sweep). The plan missed all three; T1 found the first two
while implementing and reported them rather than editing a file outside its
set, and the third surfaced at the gate. They belong here because they are
bookkeeping about the new script, not behavior of it. Each new pin must be
honest: `finish-merge.sh` genuinely contains none of what is pinned at zero,
and it already satisfied `lib.bats`'s behavioral assertion (exit 2 with the
exact `not inside a git repository` diagnosis) — only the count was stale.

## Constraints on every task

- POSIX sh only in `scripts/`; gawk, mawk, busybox awk and BWK awk must all
  work; no value carrying a literal newline reaches `awk -v`; `sed -i.bak` where
  in-place editing is needed. `tests/portability.bats` enforces these and runs
  over every script in the repository, including new ones.
- Skills stay self-contained: no superpowers or external skill suites, harness
  features named neutrally with an example.
- Existing voice, American spelling, amendment not rewrite.
- Never fork script logic into a second place (`AGENTS.md`) — `finish-merge.sh`
  calls `check-signing.sh`; it does not reimplement signature checking.

## Self-review before handing off

1. Every rule S1–S17 appears in exactly one file, in the section named above.
2. Every task carries **Files touched:** and **Parallel:**, and no two parallel
   tasks name the same file.
3. Every new behavior in `scripts/` has a bats test that was watched failing
   first, and abnormal-input tests exist alongside the normal-case ones.
4. The command in `merge-change` matches `finish-merge.sh`'s actual usage.
5. `sh tests/run-tests.sh` green, with the new tests included in the count.
