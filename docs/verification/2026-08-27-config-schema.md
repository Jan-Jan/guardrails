# Verification — the config schema refuses a key that does not take effect

branch: worktree-config-schema
reviewer: an independent subagent, one round, with a second round declined — see below
verdict: accepted after two blocking findings were fixed; both fixes carry mutations killed by their own tests
reproduced: yes. Every rule below was demonstrated as a verdict flip on a real
tree before it was written — a config shape, a `check-trace.sh` run at exit 0,
and the same tree at exit 1 once the shape was corrected. The one rule with no
demonstrated flip is named as such in "What this does not establish".

## What this change is, and why it is separate

It was found inside a larger change (`verify.sh`, the worktree bootstrap and
introduced-vs-inherited failure reporting) and split out of it before merge.
Six review rounds against that change each produced a blocking finding, and
three of the six were the same class: **one more way a config key does not take
effect as written while the run exits 0**. None of them was anything the field
report asked for. Carrying a second change inside the first would have merged a
schema overhaul under a heading about worktree bootstrap, and made the part an
adopter feels on upgrade the part nobody reviewed on its own terms.

## The rules

Each rejects a shape in which a key is read by nobody and the gate that wanted
it passes having examined nothing. All live in `gr_check_config`, which runs
before every gate in every script.

| shape | demonstrated consequence |
|---|---|
| a key set to nothing | `strict_paths:` with its item commented out — the source scan walks no path, `DANGLING-REF` over an undefined ID goes exit 1 → **exit 0** |
| a key in the wrong form | `strict_paths: src` (list key as scalar) or `doc_soup:` + `  - path` (scalar as list) — read by neither reader |
| a key set twice | both readers take the first block; YAML takes the last |
| an item that is only a comment | `  - # make test` survives as a command the shell reads as a comment: runs nothing, reports success |
| an item with nothing after its `-` | dropped by every reader; the list that runs is shorter than the one written |
| bare-CR line endings | the file is one awk record, so every key but the first is invisible |
| `strict_paths` absent | the same gate-off as empty — see below |

Fixes carried with them: a CRLF file no longer truncates a list at its first
blank line; `cfg_get` no longer reads a trailing ` # comment` as the key's
value; `set -f` around the `id_prefixes` split; `gr_die` uses `printf`, because
dash's `echo` de-escapes and these messages quote the operator's config back at
them; `cd "$(gr_root)" || exit 2` replaced in all six scripts, since under dash
`cd ""` returns 0; and a bats `teardown()` releasing each passing test's tmpdir.

## The finding worth repeating

The independent review's first blocking finding was not a defect in the code.
It was that **the diagnosis recommended the harmful remedy**: the emptiness
message said "remove the key and its items entirely", and deleting
`strict_paths` produces exactly the exit-0 no-scan state the rule refuses. The
test written for that rule even asserted the failure it must not produce
(`!= "strict 0"`), and that string is what the recommended remedy prints.

So `strict_paths` is now required outright and the message no longer offers
deletion. `verify_commands` has the same defect one level up and is
**deliberately not** required here: nothing in this change reads it, and a
validator enforcing a rule with no reader behind it is the overreach this
change is otherwise about. It belongs with the script that would run no
commands.

## Measurement

Derived by `tests/evidence.sh e6e8acc`.

- Suite: **400 tests** (`e6e8acc`: 380); 395 measured against `e6e8acc`.
- New since `e6e8acc`: **20**. Of those, **16** go red against `e6e8acc`'s
  scripts. **4** cannot, and none is counted as evidence a defect was fixed:
  - `cfg_get reads a scalar in a CRLF config` — pins behaviour that was already
    correct; `gr_clean` handles a CR at end of record. Kept as a guard, and the
    reason it cannot go red is why the matching `gr_line` call in `cfg_get` was
    **removed** as dead code rather than kept.
  - `gr_prefixes leaves pathname expansion as it found it`
  - `gr_verification_dir refuses a doc_verification set to nothing`
  - `no test file defines its own teardown, which would drop the tmpdir release`

## Mutation testing

**26 mutations, 26 killed, no survivors, no stale.** Serial, one at a time, on
a committed tree, with a null control — no mutation, one added comment — run
**first, middle and last**. All three controls survived, i.e. the sandbox was
green at the start, the middle and the end of the run.

That paragraph is worth more than its numbers. This is the seventh battery
attempted for this work and the first that is worth anything:

- Five were killed mid-run because a review round changed the tree underneath
  them. A battery measuring a tree that no longer exists proves nothing.
- Two ran to completion at 3-way parallelism and were **both wrong**. The suite
  exhausts `/tmp`'s inode budget when runs overlap — each fixture is a real git
  repository and bats holds every test's tmpdir until the run exits — and past
  the budget a redirect fails with ENOSPC, bats short-counts the plan, and a
  runner that treats any failure as a kill **scores a surviving mutant as
  dead**. The null control is what exposed it: it came back "killed" with no
  mutation applied. The first of those two runs had reported 51 of 51 killed.

**Blunt kills are weak evidence, and are marked as such.** Six mutations were
killed by 311–317 tests each (M65, M70, M71, M72, M77, M84). Inverting a guard
so that every valid config dies proves the line *executes*; it does not prove it
*discriminates*. Four further mutations (M87–M90) were written afterwards to
remove only the collection for each half of the two rules that had blunt
evidence alone, and each was killed by **one or two** tests — the tests for that
rule. Where this record cites evidence for a rule, it cites the precise
mutation.

Every other mutation was killed by a single test, and in each case by the test
written for it.

Five mutations survived the first review's spot-check and are recorded because
the pattern matters more than the fix: `M52` (`gr_die` via `printf`), `M66` (the
CR guard's every-record half), `M76` (the blank-item rule, which had **no test
at all**), the `coverage_command` bucket, and a `set -f` in `finalize-docs.sh`.
Four got tests. The fifth was **deleted**: no input could reach it, no mutation
of it could change any output, and unkillable code is code nobody can show
works. The same reasoning removed a redundant CR strip in the key extractor.

## Corpus differential

The reporting project's tree, run with `e6e8acc`'s scripts and this branch's:

| | base `e6e8acc` | this branch |
|---|---|---|
| `check-trace.sh` | exit 1 | exit 1, **byte-identical output** |
| `check-ids.sh` | exit 1 | exit 1, **byte-identical output** |

This differential is doing real work here, unlike the last change's. Every rule
in this change makes a previously-valid config **fatal**, in every gate, for
every adopter — so the question "does a real project's config still pass" is
the one that matters, and the answer is measured rather than assumed. All
eleven of that project's keys are in the form their consumer reads, none is
duplicated, none is empty, and `strict_paths` names four paths.

What it does not tell us: it is one config. A project that wrote
`strict_paths: src` — a shape that looks right and that `id_prefixes: REQ HAZ`
two lines above actively suggests — now fails every gate until they fix it.
That is intended, and it is the cost.

## What this does not establish

1. **`doc_soup` absent still narrows `DANGLING-REF` silently.** It is required
   by no prefix and no rule here. The wrong-form and emptiness rules cover the
   shapes where it is present; absent, it is the same gap `strict_paths` had,
   and `sources:` remains the only tell. Recorded in
   `skills/check-traceability/SKILL.md` rather than fixed, because the fix is a
   decision about which documents are mandatory and that is not this change.
2. **`verify_commands` absent** — as above, deliberately left to the change
   that owns the script that runs them.
3. **`guardrails_version` is read by nothing.** This change makes six
   previously-valid shapes fatal and bumps that key to 0.5.0, and no script
   compares it to the installed scripts. A version key validated for form and
   read by nobody is, in this change's own vocabulary, a key that does not take
   effect as written — in every configuration.
4. **The orphan-item diagnosis names the item, not the comment that orphaned
   it**, so it points one line past the cause. Pre-existing; the most plausible
   adopter shape among the exit-2 cases.
5. **The `teardown()` is pinned by a test that no `.bats` file defines its own**,
   not by one asserting a directory was released. bats replaces `teardown`
   wholesale, so the drift pin is the real protection; the release itself is
   evidenced only by `/tmp` inode usage staying flat across a full run.
6. **One review round, not two.** Six rounds against the parent change examined
   this code and every finding against it is fixed; one round examined it in
   this shape. The convergence argument is that this round's blocking findings
   were a wrong *diagnosis message* and missing *tests*, not wrong behaviour —
   but that is an argument, not a measurement, and a second round could still
   find a seventh shape. Five of the six previous rounds did.

## The base this was merged against

`merge-change` step 1 requires a fetch, and calls a failed one a stop rather
than a warning. It failed here:

```
$ git fetch origin; echo $?
Bad owner or permissions on /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf
fatal: Could not read from remote repository.
128
```

This environment has no network access to the remote, deliberately. So, as that
step directs when the fetch cannot succeed: **the base was merged from a local
ref, and the commit is named.** Base branch `main` at
`e6e8acc5dae462162ace35dc93d3426aea0ca443`; this clone's `origin/main` is the
same commit; the change branch already contains it, so the merge is a
fast-forward with nothing to resolve. What that does not rule out is the real
`origin/main` having moved since this clone last saw it — which is exactly the
staleness the mandatory fetch exists to remove, and it is unremoved here.

One note on the transcript above, because it is the defect this toolkit is
about: the first attempt at that command was `git fetch origin 2>&1 | head -5;
echo "fetch exit $?"`, which printed **`fetch exit 0`** — the status of `head`,
not of `git`. A pipe reported success for a command that had failed with 128.
The same shape as `exit $?` after a pipeline, in a hand-typed command, while
verifying a change about gates that pass having proved nothing.

## Environment

- Linux 7.0.0-29-generic x86_64 · git 2.53.0 · Bats 1.11.0
- `/bin/sh` → **dash**. Load-bearing: the `cd ""` fail-open and the `gr_die`
  escape processing are both dash behaviours, and their tests run under `dash`
  explicitly where one is present, because on a bash `/bin/sh` they would pass
  with the defect present.
- GNU Awk 5.3.2. The review additionally checked `mawk` and `busybox awk`
  against `cfg_get`, `cfg_list`, the CRLF block read, and the BOM and bare-CR
  rejections; all three agree.
- `/tmp` is tmpfs, 1048576 inodes, 41% used with no leaked run directories at
  the start of the battery.
