# Re-cutting a mutation anchor

Read this when the `develop-change` step 6 grep finds a line you changed
quoted in `docs/verification/*.mutations/`.

## What the anchor is

A mutation script quotes one line of the script it mutates verbatim: most as a
literal `old = '''…'''` followed by `assert s.count(old) == 1`, the older ones
as a `sed` pattern. An edit to the quoted line makes the mutation fail to
apply, and the verification record that cites it can no longer be reproduced.

`tests/mutations.bats` runs `tests/mutate.sh`, which reports a mutation that
no longer applies, but only when the full suite is run. The grep finds the hit
while the edit is in progress. Nothing checks that a re-cut anchor still kills
tests.

## What to do on a hit

1. Keep your edit. The mutation scripts are kept runnable, so the anchor
   follows the script, including the anchors of earlier changes.
2. Re-cut the anchor to the new text of the line, and make the replacement
   text the same mutation applied to the new line.
3. Prove the re-cut anchor applies: `tests/mutate.sh <the .mutations dir>`
   reports it as applied.
4. Prove it still kills tests: apply it in a scratch copy of the tree, run the
   tests the record lists against it, and see at least one fail.
5. An anchor that applies and kills nothing means the tests never covered that
   mutation. Report it as a finding; it is not a green result.

Commit the re-cut scripts with the change that edited the line.
