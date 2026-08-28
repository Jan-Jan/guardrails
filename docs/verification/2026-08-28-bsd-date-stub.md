# Verification — the BSD date stub simulates BSD rather than only refusing

branch: worktree-bsd-date-stub
reviewer: none dispatched — see "Rigor" below
verdict: accepted; the instrument now fires on the defect it was built for, demonstrated by reintroducing that defect
reproduced: yes, twice over. The failure was reproduced on `main` alone before
any change (`git archive main` into a clean directory, both tests red with none
of this work present), and the repaired instrument was reproduced against the
defect it exists to catch by reintroducing the doubled sign in `days_ago` and
watching the test go red.

## The defect

`make_bsd_date` builds a stub `date` so that a GNU box can exercise the BSD
branch of `days_ago`. It validated the `-v` adjustment and then handed it to the
real date **unchanged**:

```sh
-v-[0-9]*|-v+[0-9]*|-v[0-9]*) ;;      # accepted …
exec "$_real" "$@"                     # … then passed to a date with no -v
```

Accepting an option is not the same as being able to carry it out. Where the
real `date` is GNU or uutils — every box the stub exists for — `date -v-3d`
reached a program with no `-v`, and a **valid** adjustment was refused. The stub
reproduced BSD's rejections and none of its successes.

Two tests failed as a result, and both failures pointed at the wrong thing:
`days_ago` looked broken when the instrument measuring it was.

## The fix

The stub asks once whether the real date understands GNU's `-d`. Where it does,
`-v±Nd` is translated to `-d "N days [ago]"`; where it does not — a genuine BSD
box — it is passed through, because there it is already right.

## Measurement

- Suite: **409 tests, 0 failures** (`main`: 409 with **2 failures**).
- The two failures are `main`'s, not this change's. Measured, not assumed:
  `git archive main | tar -x` into a clean directory, `bats tests/portability.bats`
  there, same two tests red at the same lines with none of this work present.
- `date` on this machine is **uutils coreutils 0.8.0**, not GNU. It rejects `-v`
  with a clap error (`tip: to pass '-v' as a value, use '-- -v'`), which is what
  made the stub's delegation visible here.

## Is the instrument real?

The question this repository keeps having to ask about its own tests. Answered
by reintroducing the defect the test exists for — the doubled sign in
`days_ago`'s BSD branch, which `31e2303` had just fixed:

```
$ # days_ago's sign folding removed
$ bats --filter "days_ago produces" tests/portability.bats
not ok 1 days_ago produces a date in the future as well as one in the past
   days_ago -1 =
```

Before this change that test could not fail on this platform for the right
reason, because it could not get past the stub at all. Now it fails for the
defect and passes without it.

## Rigor

No independent review round was dispatched, and that is a judgement rather than
an omission. This changes one test helper, touches no script under `scripts/`,
and cannot affect any gate's verdict on any project. The toolkit's own rule
scales review to consequence (`merge-change` step 6a: "Rigor scales with class —
A may skip this step"). The evidence that stands in for it is the mutation
above: the instrument was shown to fire on the defect it was built for, which is
the property a reviewer would have been asked to check.

## What this does not establish

1. **The stub is still a simulation.** It reproduces the two behaviours
   `days_ago` depends on — `-d` refused, a doubled sign in `-v` refused, a
   well-formed `-v±Nd` honoured — and nothing else about BSD `date`. A test
   needing any other BSD behaviour will not get it here.
2. **No real BSD box was used.** The `passthrough` branch is the one that runs
   on macOS, and on this machine it is unreachable: `date -d` succeeds, so the
   stub always takes `translate`. That branch is argued, not measured.
3. **`date` here is uutils, not GNU coreutils.** The `translate` branch was
   exercised against uutils' `-d` parsing. GNU's is a superset for the two
   forms used (`N days ago`, `N days`), but that is reasoning, not a
   measurement on GNU proper.

## Environment

- Linux 7.0.0-29-generic x86_64 · git 2.53.0 · Bats 1.11.0 · `/bin/sh` → dash
- **uutils coreutils 0.8.0** `date` — load-bearing for this change, and the
  reason the defect was visible at all.
- GNU Awk 5.3.2.
