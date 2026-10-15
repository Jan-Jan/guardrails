# Architecture guidelines

This file states the project's architecture preferences. An agent reads this
file and no other guidelines file. The compliance floor the skills state wins
any conflict, and a clause that contradicts it is a finding against the
clause. A project that changes a clause rewrites its reason and examples with
it.

## Domain

1. **A public interface uses the templates' terms.** A finding code, a
   script name or flag, a config key and an item field use the term the
   templates and `templates/config.yaml` already use for that concept, one
   term per concept across the scripts and the skills, and never a new
   synonym. Names inside a script are not bound by this clause. Why: the
   templates are what an adopting project reads and copies, so they are this
   project's glossary, and a second word for one concept reads to an agent
   as a second concept. Example: every script reads a problem's `opened:`
   date, and none writes or expects `created:`; a reference to an undefined
   item is `DANGLING-REF` in every script that reports one.

2. **One term, one meaning, across the repository.** A term means one thing
   in every script, skill and template. Where a second meaning is needed, it
   gets its own word. Why: a word with two meanings is read with the wrong
   one, and an agent that reads one skill applies the meaning it learned in
   another. Example: "unit" is only a directory a units manifest lists, in
   the form `templates/units.yaml` ships; the standard's smallest software
   item is never called a unit here.

## Boundaries

1. **One job per script and per skill.** A script and a skill each have one
   job, stated in one sentence without "and" in the script's header comment
   or the skill's description. A second job is a second script or skill.
   Why: a script or skill with two jobs changes for two reasons, and an
   agent that loads a skill for one job reads the instructions for the other
   and may follow them; a narrow task is one an agent does well. Example:
   `check-ids.sh` checks the IDs, and `check-trace.sh` checks the trace
   between them; the skill that runs the red-green loop for one task is not
   the skill that dispatches the tasks.

## Constraints

1. **A rule a script can decide is a bats test.** A structural rule that a
   scan of the tree can check is a test in `tests/`, annotated with the plan
   decision or problem item it enforces, not a clause in this file. A rule
   that needs judgment stays a clause here. Why: a reviewer misses what a
   test does not, and a test runs at every gate. Example: "the scripts are
   POSIX sh, with every `case` pattern opened by `(`" is enforced by
   `tests/portability.bats`, not left to review.

## Existing code

1. **These rules bind the structure a change writes.** Code a change adds or
   moves follows them. Existing code that breaks them is restructured only
   where a change edits it for its own reason, and only as far as that edit
   reaches; code that breaks them and is not edited is left alone. Correcting
   a comment or a citation alone does not edit code. No change restructures a
   codebase wholesale for compliance. Why: a wholesale restructuring is a
   change of its own, with its own design and review, and mixing it into an
   unrelated change hides both. If correcting a comment or a citation pulled
   the code around it into scope, every moved rule would force a restructure
   wherever it is cited, and citations would be left wrong instead. Example:
   a change that would give a script a second job puts that job in a script
   of its own; an existing script whose header already states two jobs is
   left until a change edits it, and a change that repoints a stale citation
   in that header leaves the script as it is.
