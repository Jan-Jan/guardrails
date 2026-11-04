# Requirements: traceability

**REQ-8sepe5**: The software shall report INCOMPLETE-PROBLEM for a problem report whose block has no status: line.

**REQ-nw7wy4**: The software shall read a problem report's status: and opened: only from a line that begins with the lower-case keyword at column one.

**REQ-q4kdav**: The software shall require no owner: line in a problem report and print nothing about one.

**REQ-zzdfz4**: The software shall report INCOMPLETE-PROBLEM for an open or accepted problem report with no non-empty opened: line, and still list an open one as UNRESOLVED-PR.

**REQ-6hr9xa**: The software shall report MALFORMED-DATE for an opened: value that is not a YYYY-MM-DD Gregorian calendar date.

**REQ-za8yjf**: The software shall report MALFORMED-DATE for an opened: date more than one day after today, and count a date one day ahead as zero days old.

**REQ-8q9a2u**: The software shall exit 2, naming no ledger file, when the system date is not a YYYY-MM-DD calendar date.

**REQ-ct5sxz**: The software shall report STALE-PROBLEM, and fail, for an open problem report more than problem_age_days days old.

**REQ-cs8dwk**: The software shall report PROBLEM-BACKLOG, and fail, when the open problem reports across every problem ledger file, undated ones included, number more than problem_open_max.

**REQ-w9fctu**: The software shall state in its problems: summary each limit's value, or none when it is unset, and how many open problem reports have no usable opened: date.

**REQ-x6d3n9**: The software shall print an accepted problem report as `ACCEPTED-PR <ID> (opened: <date>, accepted: <disposition>)` and exempt it from STALE-PROBLEM and from problem_open_max.

**REQ-mgp32r**: The software shall report INCOMPLETE-PROBLEM for an accepted problem report with no disposition: line.

**REQ-sbpr3f**: The software shall take the first opened: line in a problem report's block as that report's opened date.

**REQ-r8k6ah**: The software shall read every problem report in a ledger file, including one after a leading `---` line or a byte-order mark.

**REQ-j8dee9**: The software shall read a problem report field's value without its trailing whitespace or carriage return.

**REQ-c3d8yk**: The software shall report no ORPHAN-ANNOTATION for an opened: line outside a problem ledger.

**REQ-czp8dt**: The software shall report UNANALYZED-DERIVED for a derived REQ or LLR that no assesses: line in the risk ledger names, reading an assesses: line's IDs only up to the first character that is not an ID, comma or space.

**REQ-3gzxr3**: The software shall report DANGLING-FILE, stating where it looked, for a draft-named file a ledger file names that exists neither at the repository root nor beside the naming file.

**REQ-p9q9ym**: The software shall look for a bare draft-named file a ledger file names in each ledger directory.

**REQ-2ytmyr**: The software shall read a draft name in angle brackets as no file reference.

**REQ-wwqc2d**: The software shall open no item block and credit no implements: or mitigates: line inside a file's YAML front matter, finding the front matter afresh in each file.

**REQ-hj3fs5**: The software shall credit an implements: or mitigates: line only from a file git does not ignore, and only for an owning item its ID scan defines.

**REQ-a5ehr8**: The software's new-id.sh shall exit 2 for --unit in a single-unit repository.

**REQ-9s5jpc**: The software shall report draft-named files and draft IDs in a scoped run only from the unit's own subtree.

**REQ-27uhud**: The software shall report no MALFORMED-ID in a scoped run from a path the unit manifest disclaims.

**REQ-scc93k**: The software shall report DUPLICATE-ID for an ID defined more than once in the tree, disclaimed paths included, from a unit's scoped run too.

**REQ-79vkt3**: The software shall report MISEXPORTED-ITEM for an exported: annotation whose value is anything but yes, an empty value included.

**REQ-knb3qu**: The software shall report DRAFT-FILE, and fail, for each draft-named ledger file in the tree, or in the unit when scoped.

**REQ-ta654s**: The software's check-ids.sh shall exit 2, naming the argument, for an argument it does not take.

**REQ-why7yf**: The software's scripts shall parse under POSIX sh, bash 3.2 in sh mode included.

**REQ-pxjhm4**: The software shall report no finding from its own installed scripts under `.guardrails/scripts`.

**REQ-43kuvw**: The software shall report INCOMPLETE-SEGREGATION for a segregated_from: ADR ID citation unless its token is a random token and a docs/adr file named for that ID, at the repository root or in the consumer unit, defines that ID on its first line, and name the three accepted citation forms in the message.

**REQ-6s9sfz**: The software's find-items.sh list and show shall read, when id_prefixes declares ADR, each regular file matching `docs/adr/ADR-*.md` at the repository root and in the unit GR_CONFIG names, and no other file in those directories, without error where none exists.
