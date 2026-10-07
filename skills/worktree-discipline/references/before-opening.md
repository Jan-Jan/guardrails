# Before a change opens: what is already open

Read this at step 2, before you create a change worktree. It has the two
checks step 2 names. Run both from the primary checkout.

Changes may run in parallel, so another session may already be working on the
item you are about to touch. Two changes that resolve the same item duplicate
the work, and one of them is discarded.

Detect the base branch first, as `merge-change` does:

```sh
BASE=$(. .guardrails/scripts/lib.sh && gr_base_branch) && [ -n "$BASE" ]
```

Each check below runs under `sh`, whatever shell you paste it into. Paste
the whole block, from its first line to `EOF`. Each check stops first with
`BASE is empty` when the detection line set nothing: run with an empty BASE,
(a) would print `ahead 0` for every worktree and (b) no `CLAIMED` line, both
of which read as real answers. Run bare in zsh, (b) fails:
zsh does not split `$item_ids` into words, so it prints nothing, the answer
for an unclaimed item.

## (a) A status line per registered worktree

```sh
BASE="$BASE" sh <<'EOF'
[ -n "$BASE" ] || { echo 'BASE is empty: detect the base branch first' >&2; exit 1; }
{ git worktree list --porcelain; echo; } | while IFS= read -r line; do
    case "$line" in
        ("worktree "*) worktree_path=${line#worktree }; branch='(detached)'; state= ;;
        ("branch refs/heads/"*) branch=${line#branch refs/heads/} ;;
        ("bare") state=bare ;;
        ("prunable"*) state=prunable ;;
        ("")
            [ -n "$worktree_path" ] || continue
            if [ -n "$state" ]; then
                printf '%s  %s  %s\n' "$branch" "$state" "$worktree_path"
            else
                ahead=$(git -C "$worktree_path" rev-list --count "$BASE..HEAD" 2>/dev/null || echo '?')
                dirty=$(git -C "$worktree_path" status --porcelain | wc -l | tr -d ' ')
                last=$(git -C "$worktree_path" log -1 --format=%cs)
                printf '%s  ahead %s  dirty %s  last %s  %s\n' \
                    "$branch" "$ahead" "$dirty" "$last" "$worktree_path"
            fi
            worktree_path= ;;
    esac
done
EOF
```

Each line gives the branch, the commits it has that the base branch does not,
the count of uncommitted files, and the date of its last commit. A detached
worktree prints `(detached)` for its branch. A `prunable` worktree has lost
its directory; it prints no counts, and `git worktree prune` removes the
entry. A worktree you did not expect is another session's, or an abandoned
one: ask the user before you touch it.

## (b) The claim check

Put the IDs of the items the new change will resolve or amend in `item_ids`
on the first line, separated by spaces, and run the check:

```sh
BASE="$BASE" item_ids='PR-<token> REQ-<token>' sh <<'EOF'
[ -n "$BASE" ] || { echo 'BASE is empty: detect the base branch first' >&2; exit 1; }
git for-each-ref --format='%(refname:short)' --no-merged "$BASE" refs/heads/ |
while IFS= read -r branch; do
    for id in $item_ids; do
        if git diff "$BASE...$branch" | grep -q -e "^[-+].*$id"; then
            printf 'CLAIMED  %s  by %s\n' "$id" "$branch"
        fi
    done
done
EOF
```

No output means no unmerged local branch adds or removes a line containing
those IDs. A `CLAIMED` line means the named branch's diff adds or removes a
line naming the ID. A branch that resolves the item does that, and so does a
branch that only cites the ID, as evidence in its plan, say. Read the named
lines, `git diff "$BASE...<branch>" | grep -e "^[-+].*<id>"`, and treat the
line as a sign that another change claims the item: stop and ask the user
before you open a second change for it.

A plain `git grep` of each branch is not enough. The item is defined on the
base branch, so every branch contains its ID, and the grep finds it on all of
them. The question is whether a branch changes something about the item, and
only its diff against the base branch answers that. `git diff "$BASE...$branch"`
(three dots) compares the branch with the point where it left the base branch,
so commits the base branch gained since then do not show as the branch's.

The check sees a line that contains the ID. A change that resolves an item
adds such lines: the plan's resolves line, the tests' `verifies:` lines. A
branch whose only edit so far is a status line below the ID line does not
show; (a) still lists that branch, so read its name. The reverse also
happens: a branch that cites the ID without resolving it shows as `CLAIMED`.
The line names the branch, and you ask the user, so nothing is lost.

The check reads committed history only. A claim another session has written
but not yet committed in its worktree does not show. A worktree that (a)
lists with a dirty count above 0 may hold one: look at its uncommitted files,
or ask the user, before you open the change.
