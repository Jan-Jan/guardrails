# Code guidelines

This file states the project's code preferences. An agent reads this file
and no other guidelines file. The compliance floor the skills state wins any
conflict, and a clause that contradicts it is a finding against the clause.
A project that changes a clause rewrites its reason and examples with it.

## Names

1. **No single-character names.** Every name the change writes, a loop
   index and a callback parameter included, says what it holds. A name the
   language or a tool fixes, such as a positional parameter, is not chosen
   and is exempt: sh's `$1` and awk's `$0` and `NF`. Why: a one-letter name
   says nothing where it is used, so every reader goes back to where it was
   set. Example: `for skill_dir in skills/*/`, not `for d in skills/*/`; in
   awk, `index_number`, not `i`.

2. **No code golf.** Write code to be read, not to be short: one action per
   statement, no chained conditional expression standing in for an `if`, no
   trick that saves a line. Why: shorter code is not simpler code, and each
   trick costs every later reader the time it saved the writer. Example: an
   `if ...; then save; else report; fi` in place of
   `[ -n "$value" ] && save || report`, which also runs `report` when `save`
   fails.

3. **Name in concrete terms.** A name says what the thing is in the
   project's domain, not its type or a role in general: no `data`, `info`,
   `item`, `value`, `result`, `manager`, `handle` or `process` alone. Why: a
   generic name sends the reader into the body to find out what it holds.
   Example: `governing_file`, not `get_file`; `guidelines_name`, not
   `name`.

4. **One name per concept across the change.** A concept has one name in
   every file, test and task of the change, and where the codebase already
   names it, that name. Why: two names read as two concepts, and tasks
   written in parallel drift apart unless the name is fixed. Example: the
   checkout's top directory is `gr_repo_root`, the name the scripts already
   give it, not `root_dir` in a new one.

## Simplicity

1. **Write the smallest code that passes.** The change does what its tests
   and requirements ask and nothing more: no extra feature, no case no test
   exercises. Why: code no test exercises is code no test protects. Example:
   a script reads the one config key its test sets, not three more for later.

2. **No speculative option or abstraction.** No parameter, flag, setting or
   hook without a caller that uses it now, and no interface, base class,
   factory or wrapper without a second caller. Why: a speculative option is
   code to read, test and keep working for a use that may never come, and
   the second caller shows what shape the abstraction needs. Example: a
   helper one script calls stays in that script; it moves to `lib.sh` when a
   second script needs it.

3. **Delete dead and commented-out code.** Code no path reaches, an unused
   function, import or variable, and commented-out code are deleted, not
   kept for later. Why: version control keeps the old code; in the tree it
   misleads the reader and has to survive every refactor. Example: delete
   the implementation the change replaced instead of commenting it out
   beside the new one.

4. **No duplication between tasks.** Where two parts of one change add the
   same helper, constant or check, one copy stays, where both can reach it.
   Two passages that look alike but state different rules are not
   duplicates. Why: two copies of one rule drift, and the next change fixes
   only one of them. Example: two tasks that each add a `has_exact_file`
   helper end with one, in `lib.sh`.

## Errors

1. **Fail loudly.** An error is reported where it is detected, naming what
   failed and on what input, and the code stops or returns an error its
   caller must handle. Why: an error reported far from its cause, or not at
   all, costs a debugging session to trace back. Example:
   `gr_die` prints `guardrails:` and what failed to standard error and exits
   2, rather than a bare `exit 1` and a wrong result two scripts later.

2. **No swallowed error.** No empty catch block, no discarded return code or
   error value, no error output sent away where the caller needs it. Where
   an error is expected and handled, the handling says why that is safe.
   Why: a swallowed error turns a failure into wrong output that looks like
   success. Example: no `2>/dev/null || true` on a command whose failure
   the caller needs; `|| true` after `grep -c`, which exits 1 on a count of
   zero, is handled on purpose and its comment says so.

3. **No silent fallback.** A missing file, setting or value is an error
   unless a requirement names the default. Why: a silent default hides a
   misconfiguration until it does damage. Example: a config key with no
   stated default exits 2 naming the key; `prune_plans` falls back to `on`
   because the config schema states that default.

4. **An edit or substitution that matches nothing is an error.** A replace,
   patch, migration or update that changes nothing reports it and fails,
   unless matching nothing is a stated, expected outcome. Why: most edit
   tools report success when they change nothing, so the work is recorded as
   done and never happened. Example: `sed -i.bak` exits 0 when its pattern
   matches nothing, so check the pattern with `grep -q` first, or `cmp` the
   file with its `.bak` afterwards, and fail when nothing changed.

## Comments

1. **A comment says why, not what.** It states a reason, a constraint or a
   rejected alternative the code cannot show. Why: the code already says
   what it does, and a comment that repeats it drifts from it at the next
   edit. Example: ``# NOT `cd "$(gr_root)" || exit 2` alone: ...``
   records why the obvious line is wrong, which no reading of the code
   shows.

2. **No change narration.** A comment describes the code as it is, never
   the change that wrote it: no "added", "now uses", "previously", "fixed"
   or ticket history. Why: narration is true only at the commit that wrote
   it; the commit message and the change's records carry the history.
   Example: `# Retries twice: the device drops the first frame after
   waking`, not `# Changed retries from 1 to 2`.

3. **Match the surrounding code's comment density.** A change comments at
   about the rate of the file it edits, and a new file at the project's
   usual rate. Why: a reader takes an unusual comment as a warning, so
   comments where the code has none, or none where it has many, mislead.
   Example: a script's header comment states its rules, reports and
   exit codes in full, and the body comments only its non-obvious lines.
