# Problem reports — the assertion gate

One item, recorded when the gate it describes was cut from the change that
resolved `PR-tenhv4`. `affects:` names files rather than item IDs for the reason
`docs/problems/2026-08-27-macos-awk.md` gives: guardrails keeps no REQ/SDD/LLR
ledger of its own yet.

**PR-x4nb48**: Nothing rejects an unguarded `[[ ]]` or `(( ))` assertion in a
bats test body, so the 301 guards that `PR-tenhv4` applied can be undone one
line at a time with no gate reporting it.
affects: tests/*.bats, which contain 301 guarded assertions no rule keeps
guarded; tests/portability.bats, where such a gate belongs beside the
`case`-pattern and in-place-`sed` scans.
opened: 2026-09-28
status: open

`PR-tenhv4` repaired 69 inert assertions and guarded all 301 so that position
would stop deciding whether an assertion can fail. It did not deliver a gate.
One was written and cut, and the reason it was cut is this item's starting
evidence rather than a reason to write the same thing again.

**Six revisions of a line-based awk scan repaired sixteen distinct defective or
over-broad readings, and the last two repairs each introduced a new defect.**
The final revision had a blind spot live in the tree: an unguarded assertion
inserted anywhere in roughly lines 240 to 330 of `tests/check-ids.bats` was
reported by nothing and the gate exited 0. Its cause was
`tests/check-ids.bats:236`, `| tr -d "\\\\" | tr -d "\"'" \`, where a
backslash-escaped quote desynchronised the scan's quote tracking; the brace
join added one revision earlier then consumed every following line to the end of
the construct. Measured by inserting a probe at lines 100, 200, 240, 300,
320, 330, 400 and 600: reported at 100, 200, 400 and 600, silent at the rest.

The count is not the reason. Every one of the sixteen was in one of five
hand-written approximations of shell lexing — a quote masker, a brace-depth
counter, a command-position test, a guard-segment reader and a heredoc
recogniser — and when one of them desynchronises, the scan reports nothing and
exits 0. The calibration block cannot detect that: it proves the scan still
matches known defective strings, which remains true while the scan has stopped
reading a hundred lines. A gate that reports success after examining nothing is
the defect this toolkit exists to remove.

Four independent review rounds produced the evidence. Round 4's report is the
fullest and lists seventeen findings against the gate, eight of them defects
found after three earlier rounds had each found their own. Whoever takes this
item should read it before writing anything: it is in this change's verification
record, `docs/verification/2026-09-28-inert-assertions.md`, under the findings
that record why the gate was cut.

Prefer a rule that cannot fail silently over a rule that is exactly right. One
candidate, from round 4: every `[[` or `((` in a `.bats` file must
appear on a logical line that also contains the literal guard string, with no
lexing at all. Its false positives are visible. Measured on the tree this item is recorded in:
245 lines contain `[[` or `((` without the literal guard string. They overlap
rather than partition — 135 are continuations needing a line join, 90 are guard
spellings such as `|| false` or a custom message needing normalisation, 14 are
in `tests/portability.bats`, and the rest are arithmetic `$(( ))` and bracket
expressions needing an exemption. A count taken while the gate was still in the
tree gives 308 and 77, because 63 of those lines were the gate's own controls
and awk source; this item quotes the figures for the tree without it. This item does not mandate it; it records that the subtle
approach was tried six times and states what its failures cost.

## The second attempt, also cut

A second gate was built and cut, on 2026-09-30, after five independent review
rounds raised forty-one findings. The first four rejected it; the fifth
reviewed the cut and raised no code finding. It is recorded in
`docs/verification/2026-09-29-assertion-gate.md`, and the plan it was built
from is `docs/plans/2026-09-29-assertion-gate.md`.

**What the second attempt established, and it is the useful part: reading the
corpus is not the hard problem.** The scan judged a whole logical line's shape
rather than a command's position, joined physical lines only on a trailing
backslash, and kept no other state. Measured on four successive trees, and
reproduced independently by each reviewer that had the scan in its tree: an
unguarded assertion
inserted at every line of every corpus file was reported at every one — 12,020
insertion points at the last measurement, none silent — and a guard stripped
from each of the 620 single-line bracket assertions was reported every time.
The blind spot that cut the first gate did not recur once. Round 3 also gave an
argument for why it cannot: a probe ending in `]]` can end no logical line in a
guard, and it always contains `[[`, so it is always judged.

**What could not be settled is whether a guard CAN FAIL.** That is a property
of shell semantics, not of the line's shape, and six spellings that are inert
under bats were accepted in turn. Each repair closed the spelling it was shown
and not the class behind it:

| round | accepted and inert | why the text looks like a guard |
|---|---|---|
| 1 | `\|\| echo "$output" \|\| false` | ends in `\|\| false`; the echo succeeds first |
| 1 | `\|\| { echo a; } \|\| { echo b; false; }` | ends in the canonical guard |
| 2 | `\|\| { echo x; return 0; false; }` | `false` is present and never executed |
| 3† | `\|\| { echo x && return; false; }` | the argument chains to a control transfer |
| 3 | `\|\| { echo "$output" \; false; }` | the escape stops `;` separating, so `false` is an argument |
| 4 | `\|\| { echo "$output" \\; return 0; false; }` | the escaped backslash makes `;` a separator again, and round 3's repair blanks it |

† found by the author between rounds 3 and 4, not by a reviewer.

**The number of backslashes is the whole point of the last row and is easy to
lose in transcription.** One backslash before the `;` is a LIVE guard: the
escape makes `;` an argument, the separator after `return 0` still runs, and
`false` executes. Two backslashes are inert: the first escapes the second, the
`;` separates, and `return 0` leaves before `false`. Measured under bats
1.11.0 on `GNU bash 3.2.57`, with a body of `run true` and an assertion against
`-eq 99`: one backslash reports `not ok`, two report `ok`, and the canonical
guard reports `not ok`. Anyone re-measuring this row must write the fixture with
a tool that does not re-interpret backslashes and check the byte count before
running it; a shell heredoc silently halves them.

The last pair is the shape of the whole difficulty. Round 3's repair blanked a
backslash-escaped `;` so it could not be read as the separator the template
requires; round 4 then escaped the backslash, which makes the `;` a real
separator that the repair now blanks. A rule that reads one level of escaping
fails on two, and a rule that reads two fails on three. Deciding
which `;` separates needs the quoting and escaping read — which is the lexing
that cut the first gate.

**The accounting controls worked and are worth reusing.** Each bucket counted
the physical lines it accounted for, and `tests/portability.bats` compared each
against an independent `grep` over the same files. Four deliberate breaks were
detected: a bucket credited over part of the corpus only, a counter reset
before classification, a file never read, and a continuation that never
terminates. One was not, and it is the residual hole in that design: a path
that credits its own bucket and then returns leaves every count correct.

**What a third attempt should know.** The corpus-reading half is solved and its
evidence is in the record. The verdict half is the open question, and five
rounds of evidence indicate a line-based template cannot answer it. Two directions neither
attempt tried: run each test body under a shell that reports the answer
directly, so the question stops being textual; or drop the inertness question
entirely and enforce ONE literal guard spelling by exact string comparison,
accepting that every diagnostic message in the suite becomes uniform. That
touches every line containing `|| {` — 1,070 in the tree this item is recorded
in, and 1,087 in the gate tree the figure was first taken on.

Related: `PR-7za3at` is the same class of defect in a negated command, also
unguarded by anything today.
