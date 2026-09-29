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

Related: `PR-7za3at` is the same class of defect in a negated command, also
unguarded by anything today.
