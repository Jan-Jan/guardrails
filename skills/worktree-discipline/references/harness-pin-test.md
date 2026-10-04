# Does your harness pin dispatched subagents?

Read this when you need to know whether your harness pins dispatched subagents
to a subtree. The containment rule in `worktree-discipline` step 1 does not
depend on the answer: nest every task worktree either way.

Run the test from the change worktree, before you dispatch anything:

1. Create a throwaway worktree beside the change worktree, outside its
   subtree.
2. Dispatch a subagent and have it run `git -C <that path> status`.
3. Read the result:
   - A rejection that names the session's own worktree means your harness
     pins. A task worktree outside the change worktree is unusable to that
     subagent.
   - A clean status means it does not pin. A task worktree could go anywhere,
     and nesting it inside the change worktree works as well.
4. Remove the throwaway worktree.

Do not test by writing a file. A plain shell redirect to a path outside the pin
is not blocked even where the write tool is, so a file appearing there proves
nothing.
