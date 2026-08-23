# Verification — item-blocks (2026-08-23)

Change: an item block ends at the next item, not at any bold line; and an
annotation belonging to no item is reported rather than dropped. Branched from
`main` at `5dabcd0`. Plan: `docs/plans/2026-08-22-item-blocks.md`.

Defect fix. Reported against guardrails 0.1.0 by a class B project running the
toolkit in production ("Where the Gates Leak", addendum 2026-08-21), against
`UNRESOLVED-PR`. Measurement below found the same rule wrong in three further
gates and in both failure directions.

**reproduced:** yes, directly, before any change. A fixture ledger with one
affected and one control item per gate, run against the shipped scripts at
`5dabcd0`, reproduced the reported silence and two failures nobody had
reported. The `UNANALYZED-DERIVED` case was found by this measurement, not by
the report.

## The gate

Every figure derived from the shipped tree, not carried forward.

| Gate | Result |
| --- | --- |
| `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` | `1..260` — **260 ok, 0 not ok, 0 skipped** (`main`: 212) |
| `sh -n` on all six scripts | clean |
| gawk 5.3.2 / mawk / busybox awk | 260/260 on each (reviewer-run, rounds 3 and 4) |
| Working tree | clean, no draft ledger files |
| Corpus (`sightings-app` @ `caed1452`, 1192 tracked files, 156 PR items) | `check-ids.sh` **byte-identical** to `main`. `check-trace.sh` loses nothing and gains exactly two findings, both true — see below |

## What was wrong

One rule, hand-copied into four awk programs:

```awk
/^\*\*/ && $0 !~ defre { flush(); cur = "" }
```

Any line beginning `**` ended the current item — an emphasised sentence in the
item's own body included. Everything after it, annotations included, belonged
to no item.

| Gate | Effect | Direction |
| --- | --- | --- |
| `UNTRACED-DESIGN` | fires despite a correct `traces:` | loud **false positive** |
| `UNSATISFIED-LLR` | fires despite a correct `satisfies:` | loud **false positive** |
| `UNANALYZED-DERIVED` | item stops being seen as derived | **false green** |
| `UNRESOLVED-PR` | open item vanishes from the list | **false green** |

Only the last was reported. `UNANALYZED-DERIVED` is the worse of the two silent
ones: `UNRESOLVED-PR` is a warning by design, so its silence loses a warning,
while `UNANALYZED-DERIVED` is a failing gate, so its silence loses a red.

### Before and after, one ledger

Same tree, `main` scripts then branch scripts:

```
main   UNTRACED-DESIGN SDD-e7q9s6      <- false positive, it DOES trace
       UNSATISFIED-LLR LLR-f8r2t7      <- false positive, it DOES satisfy
       exit 1                           and the open PR is invisible

branch UNANALYZED-DERIVED REQ-c5n7q4   <- real violation, previously silent
       UNRESOLVED-PR PR-a3k9z2         <- open problem, previously silent
       exit 1
```

Both exit 1. Opposite meanings: the old exit code was right by accident.

## What was built

* `GR_AWK_ITEM_BLOCK` in `lib.sh` — one definition of where an item starts and
  ends, consumed by five gates. Each keeps its own extraction; only the
  boundary is shared.
* `gr_def_re_loose` in `lib.sh` — the loose definition form, previously spelled
  out by hand in `check-ids.sh`.
* `ORPHAN-ANNOTATION` — a new gate, exit 1, reporting a `status:`, `traces:` or
  `satisfies:` line at column one that belongs to no item.

The close rule, after four amendments:

```awk
if (substr(line, 1, 1) == "#") return 1
return (substr(line, 1, 2) == "**" && index(line, ":") > 0)
```

Everything the pre-change rule closed, minus the colon-free shape that caused
the defect. Byte-wise, so the verdict does not depend on the operator's awk or
locale.

## Mutation table

23 mutations, each applied to the shipped tree and the full suite run.
`killed_by` is the number of tests that reddened.

| # | Mutation | Result |
| --- | --- | --- |
| M01 | close: heading arm removed | killed by 6 |
| M02 | close: one asterisk instead of two | killed by 1 |
| M03 | close: colon requirement dropped (reinstates the reported defect) | killed by 5 |
| M04 | close: never close on a bold line | killed by 73 |
| M05 | open: trailing colon dropped from the definition form | killed by 1 |
| M06 | open: `^` anchor dropped | killed by 1 |
| M07 | `gr_kw_here`: column-one anchor dropped | killed by 3 |
| M08 | front matter: pass one disabled | killed by 5 |
| M09 | front matter: skip disabled | killed by 4 |
| M10 | front matter: `FNR` reported as `NR` | killed by 2 |
| M11 | front matter: `FNR == 1` anchor dropped | killed by 3 |
| M12 | front matter: `...` terminator dropped | killed by 1 |
| M13 | front matter: BOM strip dropped | killed by 1 |
| M14 | orphan scan: `gr_die` on awk failure dropped | killed by 1 |
| M15 | orphan scan: `\|\| exit 2` propagation dropped | killed by 1 |
| M16 | `status:` opens on `PR\|SDD` | killed by 1 |
| M17 | `traces:` opens on `SDD\|LLR` | killed by 1 |
| M18 | `satisfies:` opens on `LLR` only | killed by 1 |
| M19 | `satisfies:` opens on `REQ` only | killed by 2 |
| M20 | `sort -u` dropped from the union file list | killed by 1 |
| M21 | `LC_ALL=C` dropped from the orphan scan | **SURVIVED** |
| M22 | `gr_def_re_loose`: `[^*]*` → `[^*]+` | killed by 1 |
| M23 | `gr_def_re_loose`: `[^*]*` → `.*` | killed by 1 |

Two further mutations were run by hand and are pinned by the poison test:
replacing the shared block fragment with a private copy in `check-trace.sh`
(killed), and replacing `gr_kw_here` with an inline copy of the column-one rule
(killed).

**M21 survived and is not fixed.** The close and the keyword test are
`substr`/`index`, which count bytes in every locale, so the only
locale-sensitive construct left under that setting is the octal-escape BOM
strip — and no test distinguishes it on gawk 5.3.2, mawk or busybox awk. The
setting is kept as defence in depth and is documented as such at the call site.
It is a behaviour with no test, which this project normally treats as a
liability; recorded here rather than removed, because removing it would trade a
measured non-difference for an unmeasured risk on other awks.

## Base merge

The base was merged from the **local** `main` ref at `5dabcd0`, not from
`origin/main`. This session has no network access to GitHub, by design; the
user confirmed having pushed `main` to `origin` immediately beforehand, so the
two were in sync at merge time. `merge-change` step 1 requires this to be
recorded and the commit named rather than passed over, because the in-tree
duplicate scan is only as good as the base it was compared against. `git merge
main` reported *Already up to date* — this branch was cut from `5dabcd0` and
the base has not moved since.

Steps 3, 4 and 5 of `merge-change` (finalize-docs, check-ids, check-trace on
the repository itself) are **not applicable**: guardrails is not yet a
guardrails project. It has no `.guardrails/` install and no ledger
directories, so there are no draft files to finalize and no configured
documents to scan. This is measured and recorded in
`docs/plans/2026-08-22-ratchet-gap-analysis.md`, which finds 52 violations
arising from bats fixtures and historical plan text, and makes the install
conditional on a scan-exclusion mechanism (tooth 0). The corpus run below is
what stands in for those steps: it exercises both gates against a real
installed project rather than against this one.

## Corpus run

`sightings-app` @ `caed1452` — 1192 tracked files, 137 REQ, 12 HAZ, 36 RC,
33 SDD, 48 LLR, 156 PR. This is the live class B project whose report prompted
the change. Both scripts are read-only scans; the corpus tree was verified
clean before and after.

`checked:` and `sources:` are identical on both sides, so enumeration is
unchanged. `check-ids.sh` output is byte-identical. `check-trace.sh` differs by
**two added lines and none removed**:

```
+ ORPHAN-ANNOTATION docs/problems/2026-08-18-gate-assertion-timeout.md:58 (status: belongs to no item)
+ ORPHAN-ANNOTATION docs/problems/2026-08-20-navigate-back-sync-race.md:210 (status: belongs to no item)
```

Exit goes 0 → 1. Both findings were investigated and both are true.

**PR-122 — the reported defect, in the wild.** `docs/problems/2026-08-20-…:190`
defines `**PR-122**`, and its `status: open` sits at line 210. Between them, at
line 200:

```
**hypothesis, not a finding**: `ISpottedPage.endOneActiveOuting:359` waits via
```

A bold label at column one. It closes the block under the old rule (any bold
line) and under the new one (bold plus a colon) alike, so PR-122 is **absent
from the `UNRESOLVED-PR` list on both sides** — `main`'s list runs
…PR-119, PR-124… That is an open problem report, in a live class B project,
that has never appeared in the known-problem review. The change does not
attribute it — no rule can, the annotation genuinely belongs to no item — but
it stops the loss being silent, which is precisely what the backstop is for.
The operator's fix is to move `status: open` above the bold label.

**PR-070 — the same shape, closed by a heading.** `2026-08-18-…:3` defines
`**PR-070**`; `## Fix` at line 27 closes the block; `status: resolved` at line
58 has never been read by any gate, on either side. Harmless today because the
value is `resolved` — had it been `open`, it would have been invisible exactly
as PR-122 is.

Neither finding is a false positive, and nothing `main` reported was lost. On
the one corpus available, the upgrade cost is two true findings and no
migration work beyond acting on them.

## Independent review

Four rounds, each returning a blocking verdict. Rounds 2, 3 and 4 each found
that the previous round's fix had closed the demonstrated instances and left
the class open.

| Round | Blocking findings |
| --- | --- |
| 1 | The backstop opened on any declared prefix while each gate opens on its own, leaving a third state neither reads. Closing on the loose definition form missed three header shapes, handing their annotations to the item above — a **regression against `main`** |
| 2 | Three more header shapes still missed. The whitespace discriminator was untested **and not load-bearing** — the colon fixes the defect. Unclosed front matter blanked a whole file. The poison stub reimplemented `gr_kw_here` faithfully, so a private copy would pass |
| 3 | Substituting `^\*\*.*:` — the plan's own stated rule — reddened **zero tests**, so the suite could not tell the implementation from the rule, and every difference was a lost close. Four surviving mutants |
| 4 | `.` does not match invalid UTF-8 under gawk in a multibyte locale, so a latin-1 header silently stopped closing and the verdict depended on the operator's locale. The fail-closed fix from round 3 shipped with no test. Comments described an abandoned design for the fourth consecutive round |

The pattern is the finding. Each fix was fitted to the examples the previous
round produced, and each was narrower than the rule it was meant to implement.
What broke it was not another example: it was substituting the plainly-stated
rule for the implementation and observing that the suite could not tell them
apart.

## Gaps

Recorded, not resolved.

1. **One corpus, not several.** The run above covers `sightings-app`, the only
   project on this machine with guardrails installed. It is a strong sample —
   1192 files, 156 problem reports, and it exercised the exact reported defect
   — but it is one project, written by one author, in one house style. A ledger
   using bullet-style annotations or non-ASCII colons would exercise the two
   disclosed limits below, and none is measured here.
2. **M21 survived** — see the mutation table.
3. **The backstop matches a keyword only at column one**, while the gates match
   one anywhere on the line. A bullet-style ledger (`- status: open`) therefore
   gets no backstop: exit 0 with an open problem report absent from the
   known-problem list. Extending the anchor to list markers was implemented and
   reverted — it fired on prose in this project's own `templates/problems.md`.
   Documented in `lib.sh` and the skill.
4. **The residual close limit**: a bold line carrying no ASCII colon does not
   close. Nothing distinguishes such a line from the sentence in the original
   report, so it is irreducible under this design. A full-width colon (U+FF1A)
   is not an ASCII colon.
5. **`tests/mutate.sh` lives on the unmerged `mutation-runner` branch**, so the
   mutations above were run with an ad-hoc harness rather than the project's
   own. The harness is recorded in this change's history, not committed.

## Upgrade impact

A green tree can go red, and that is the intent:

* an open PR item previously invisible now appears in `UNRESOLVED-PR`
  (warning, does not fail);
* a derived REQ/LLR previously invisible now fires `UNANALYZED-DERIVED`
  (**fails**);
* an orphaned `status:`/`traces:`/`satisfies:` now fires `ORPHAN-ANNOTATION`
  (**fails**), most often for an annotation sitting inside another prefix's
  block;
* an SDD or LLR previously reported because of a bold line in its body stops
  being reported — any ledger text reworded to appease those two gates can be
  reverted.

No grace period and no `--warn-only`: a warning nobody acts on teaches people
the output is noise.
