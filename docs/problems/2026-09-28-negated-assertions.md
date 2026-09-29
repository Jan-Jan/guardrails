# Problem reports — negated assertions

One item, found while auditing `PR-tenhv4` and recorded rather than fixed there.
`affects:` names files rather than item IDs for the reason
`docs/problems/2026-08-27-macos-awk.md` gives: guardrails keeps no REQ/SDD/LLR
ledger of its own yet.

**PR-7za3at**: bash does not apply `errexit` to a `!`-negated command, so a
negated assertion that is not the last command of a bats test body is evaluated
and its result discarded, exactly as a bare `[[ ]]` was.
affects: tests/skills.bats (9), tests/finalize-docs.bats (1).
opened: 2026-09-28
status: open
Reproduced on this machine's `/bin/bash`, `3.2.57(1)-release`. The negated
command has to FAIL for the demonstration to mean anything, so the pattern must
be one the file contains:

    $ bash -c '! grep -q localhost /etc/hosts'
    exit 1
    $ bash -c 'set -eE; ! grep -q localhost /etc/hosts; echo REACHED'
    REACHED
    exit 0

The negation returns 1 both times. As the last command of a body it is the
verdict; anywhere else `errexit` does not stop execution and the result is
discarded. POSIX requires this — `errexit` is suppressed for a pipeline preceded
by `!` — so unlike `PR-tenhv4` it is not a bash 3.2 defect and a newer bash does
not repair it.

Ten lines open with `!` and are neither the last command of their body nor
joined to a `|| { ...; false; }` guard. Two further negated lines in
`tests/finalize-docs.bats` are guarded and are live, and six more are the last
command of their body and are live for that reason; none of the eight is in the
count.

This item first stated eleven. The scan that produced that figure compared each
line against the body's last LINE rather than its last COMMAND, so
`tests/skills.bats:1367`, which continues onto `:1368` and is the body's last
command, was counted as inert. It is live. An independent review caught it, and
the error is the same one the whole `PR-tenhv4` audit is about: a measuring
instrument that reads lines where the shell reads commands.

The ten are named by test rather than by line, because a line number in a ledger
item points at whatever later occupies that line. Another change in flight adds
lines above several of these, which would have made every number below stale
without changing anything this item is about.

| test | file | count |
| --- | --- | --- |
| finalize: a path reference to a renamed draft is rewritten in another ledger | `tests/finalize-docs.bats` | 1 |
| assesses-is-the-remedy: every place that tells an author how to assess names the annotation | `tests/skills.bats` | 2 |
| check-traceability: MALFORMED-STATUS knows there are three values | `tests/skills.bats` | 1 |
| verification template opens every finding with its tag | `tests/skills.bats` | 3 |
| merge-change: the tag does not shorten the sequence | `tests/skills.bats` | 3 |

Re-derive the lines rather than trusting a count above: a negated line that is
neither its body's last command nor joined to a guard. Five of the ten in
`tests/skills.bats` were being changed to `grep -rq` over the skill directory
while this item was written; that changes what they search, not whether their
result is read, and the test names are unchanged.

Three of the ten are repaired by another change that was in flight while
this item was written, all three in `merge-change: the tag does not shorten the
sequence`. That change replaces `! grep -rq PHRASE FILE` with
`run grep -rq PHRASE FILE` followed by `[ "$status" -ne 0 ]`, which is live
because `[` is an ordinary command. Its author checked them one at a time:
each fails with its phrase present and passes without it, and none exposed a
claim that was untrue.

So the count depends on merge order, which is why the table above is keyed to
test names and why the instruction is to re-derive rather than to trust a
figure. If that change is merged first, seven remain: six in
`tests/skills.bats` and one in `tests/finalize-docs.bats`. If this item is
merged first, all ten are present until that change arrives. Whoever
resolves this item should re-derive the set at the tree in front of them and
narrow the table to what is actually there.

This is the same failure as `PR-tenhv4` — an assertion whose result nothing
reads — in a different construct. No gate covers either one: `PR-tenhv4` shipped
its repair without one, and `PR-x4nb48` is open for the rule that would reject
an unguarded `[[ ]]` or `(( ))`. A negated command is any command, so the rule
that catches these is a third rule, with its own reproduction and controls.

Recorded here rather than resolved in the `PR-tenhv4` change for two reasons.
The repair needs a rule nothing in the toolkit expresses, which is a change with
its own review. And nine of the ten lines are in `tests/skills.bats`,
which another change was editing at the time; resolving them here would have
put two changes in one file.

Whoever takes this: the ten assertions are all `! grep`, `! sed | grep` or
`! printf | grep`, and each states that something is absent. Making them live
may expose a claim that was never true, which is what happened to `PR-tenhv4`'s
mutation M39. Run them one at a time rather than repairing the form in bulk.
