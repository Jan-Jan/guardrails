# Requirements: guardrails

**REQ-pwd7br**: The software shall report MISPLACED-ITEM for an item defined outside the files its kind's ledger setting resolves to, and for no item defined inside them.

**REQ-beb6gm**: The software shall exit 2, naming the failed scan, when a scan cannot read a ledger file or the tool it runs fails, after printing the findings already collected.

**REQ-k6mtxa**: The software shall check a configuration that names no requirements or architecture ledger, reading no items from either.

**REQ-x7m2sy**: The software shall report ORPHAN-ANNOTATION for an annotation keyword at column one, or after list markers, that lies in no item block, skipping only YAML front matter: a `---` line on line 1 followed by a key.

**REQ-k773kh**: The software shall credit a column-one annotation to an item only inside that item's block, which ends at the next heading or bold line containing a colon; a line opens a block only when it starts with `**<ID>**:`.

**REQ-qw3aze**: The software shall count an implements: only inside a REQ block of the requirements ledger, and a mitigates: only inside an RC block of the risk ledger.

**REQ-pvz285**: The software shall take the first status: line in a problem report's block as that report's status.

**REQ-fgdd5w**: The software shall warn `UNRESOLVED-PR <ID> (open N days)`, without failing, for each problem report whose status is open, N counted from opened: to today's local date.

**REQ-xyxvm2**: The software shall report MALFORMED-STATUS, naming open and accepted as the values it takes, for a problem report whose status is not open, accepted or resolved.

**REQ-p7xc4t**: The software shall summarise the counts of open and accepted problem reports and the age of the oldest open one, printing n/a for that age when none is open.

**REQ-ars54m**: The software's find-items.sh list shall exit 2, naming the values it takes, for an empty --kind, or a --status other than open or accepted.

**REQ-fdk8kc**: The software shall print each finding as `<CODE> <subject> (<reason>)`.

**REQ-e83fky**: The software shall print, after the findings and before the summary, one `fix <RULE>:` line per code reported, in the order the codes first fired, stating how to clear that code's findings.

**REQ-x3rb2m**: The software shall report DANGLING-REF for an ID that a ledger or test names and no ledger defines.

**REQ-vn6s4v**: The software shall recognise an item definition by the same forms in every script that reads one.

**REQ-h76m4z**: The software shall provide a before-opening worktree check that prints each worktree's branch with its count of commits ahead of the base branch and its count of uncommitted files.

**REQ-wn6kjg**: The software shall provide a before-opening claim check that names each unmerged local branch whose own commits add or remove a line containing a given ID.

**REQ-y8aq53**: The software shall report RESOLVED-PROBLEM for a problem report whose status is resolved.

**REQ-nf4zgj**: The software shall report SUPERSESSION-ANNOTATION FILE:LINE for a supersedes:, superseded-by: or retired: keyword in a ledger.

**REQ-w2j5vm**: The software shall exit 2, naming the unit and its doc_srs, when a provider unit's configured doc_srs does not exist.
