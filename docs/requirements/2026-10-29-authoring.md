# Requirements: authoring

**REQ-sync6b**: The software shall give each skill a `name:` frontmatter line equal to its directory name.

**REQ-mdxb9m**: The software's code and architecture guidelines templates and docs/ARCHITECTURE_GUIDELINES.md shall state a reason and an example for every clause.

**REQ-n45q7m**: The software's code and architecture guidelines templates shall open with a preface of at most six lines stating that no other guidelines file is read and that a clause contradicting the floor is a finding against the clause.

**REQ-jb83qg**: The software's guidelines templates and this repository's guidelines files shall name no ADR, plan, reference file, SKILL.md, AGENTS.md or guardrails skill.

**REQ-h6e9bu**: The software's code guidelines template shall be at most 1,400 words, and its architecture guidelines template at most 1,300.

**REQ-9q9v3p**: The software's docs/CODE_GUIDELINES.md shall be at most 1,600 words, and its docs/ARCHITECTURE_GUIDELINES.md at most 1,500.

**REQ-hgq5pc**: The software shall ship a `templates/<KIND>_GUIDELINES.md` for every kind `guidelines-file.sh` knows.

**REQ-fmnw9y**: The software's skills, templates, tests, scripts, README, AGENTS.md and install.sh shall name neither retired skill, `deslop` or `review-guidelines`, outside the ratchet upgrade notes.

**REQ-an7yxp**: The software's code guidelines template shall have the sections Names, Simplicity, Errors and Comments, in that order, holding fifteen numbered clauses.

**REQ-d7px4f**: The software's code guidelines template shall permit no abstraction without a second caller.

**REQ-brsh59**: The software's code guidelines template shall have commented-out code deleted.

**REQ-eab32v**: The software's code guidelines template shall forbid an empty catch block.

**REQ-aac3vf**: The software's code guidelines template shall permit a substitution that matches nothing only where matching nothing is a stated outcome.

**REQ-ft7e5p**: The software's code guidelines template shall forbid a comment that narrates the change that wrote it.

**REQ-htmf2j**: The software's docs/CODE_GUIDELINES.md shall keep every heading and clause of the code guidelines template.

**REQ-hfq59z**: The software's docs/CODE_GUIDELINES.md shall give this repository's own POSIX sh as its examples.

**REQ-6k3j4u**: The software's code guidelines template shall permit a fallback to a default a requirement names.

**REQ-r4sebu**: The software's architecture guidelines template shall have the sections Domain, Core and edges, Boundaries, Constraints and Existing code, in that order, holding twelve numbered clauses.

**REQ-fs3xya**: The software's architecture guidelines template shall put every file, network, database, device, environment variable, clock and random-source access in an adapter, out of the core.

**REQ-esqnn8**: The software's architecture guidelines template shall bind exported names to the glossary, but not names inside an item or across units.

**REQ-fcab3d**: The software's architecture guidelines template shall keep adapter, framework and infrastructure imports out of the core.

**REQ-a5wqng**: The software's architecture guidelines template shall keep a received error as the cause.

**REQ-k4q8s6**: The software's architecture guidelines template shall keep a rule that needs judgment a clause.

**REQ-47369y**: The software's architecture guidelines template shall forbid restructuring a codebase wholesale for compliance.

**REQ-a48vvm**: The software's architecture guidelines template shall count the test fake at a boundary as the interface's second implementation, including a duck-typed interface.

**REQ-uytup7**: The software's architecture guidelines template shall make a rule a tool can decide an LLR with a test, with a language-neutral example.

**REQ-3ucveq**: The software's architecture guidelines template and docs/ARCHITECTURE_GUIDELINES.md shall state that correcting a comment or a citation alone does not edit code.

**REQ-4jfpsb**: The software's review-conformance skill shall have each finding state its severity, the clause it cites as Heading N, quoted, and a file:line location.

**REQ-2dte4r**: The software's review-conformance skill shall list the test floor in full.

**REQ-s7f7bc**: The software's review-conformance and develop-refactor skills shall state the architecture floor.

**REQ-xewha4**: The software's review-conformance skill shall report as a finding against the clause a clause that contradicts the floor, whose reason no longer fits its rule, or that refers to another guidelines file or a document the project lacks.

**REQ-h4xp5q**: The software's review-conformance skill shall report what the guidelines file does not state as a note, never a finding.

**REQ-3apcdd**: The software's review-conformance skill shall end its report with a `verdict:` line.

**REQ-6wwrv4**: The software's review-conformance skill shall have the reviewer read only the guidelines file it was given, never the installed default.

**REQ-zwxdx5**: The software's review-conformance description shall name the code and architecture guidelines files and say it runs after every task branch is merged.

**REQ-3veknj**: The software's develop-tdd skill shall be loaded by a subagent develop-change dispatched with one plan task, which neither merges its task branch nor dispatches again.

**REQ-z2rbmx**: The software's develop-tdd skill shall fix each TEST conformance finding under its loop, citing the clause, or report it as `no change` with the reason.

**REQ-4bk9tg**: The software's develop-tdd skill shall allow no production code without a failing test first.

**REQ-5e57px**: The software's develop-tdd skill shall number its loop RED, Verify RED and GREEN as steps 1 to 3, and Commit as step 6.

**REQ-sh55a4**: The software's develop-tdd skill shall state the class B and C robustness rule, tests at every touched SDD item's interface, and that a bug is a missing test.

**REQ-d9b96s**: The software's develop-tdd skill shall require every test to fail when the behavior it verifies breaks.

**REQ-6fp3aw**: The software's develop-tdd skill shall read before RED only the test guidelines file `guidelines-file.sh TEST` prints, stopping for a reinstall when it exits 2 or the file is missing.

**REQ-evg2bd**: The software's develop-tdd skill shall state the dispatch report's shape, listing an inherited test as coverage.

**REQ-7ughhm**: The software's skills shall cite develop-tdd for the TDD loop and red-first rule, and the README diagram shall show develop-tdd, review-conformance and develop-refactor.

**REQ-8kgv4d**: The software's develop-tdd skill shall run at GREEN the selection the guidelines file's `Test runs` section states, with a fallback where the section is absent or the runner cannot select, never the whole suite.

**REQ-4rdvvb**: The software's develop-refactor skill shall be loaded only to fix one CODE or ARCHITECTURE conformance review's findings, leaving review of the fix to the next round.

**REQ-gqf3ys**: The software's develop-refactor skill shall work in the task worktree the prompt names, neither merging it nor dispatching again.

**REQ-d5k9zk**: The software's develop-refactor skill shall read only the guidelines file the prompt names and fix each finding at its line, changing nothing else.

**REQ-yz3r49**: The software's develop-refactor skill shall change no behavior, and never delete, skip or loosen a test.

**REQ-k4kb2c**: The software's develop-refactor skill shall report a finding it cannot fix as `no change` with the reason.

**REQ-rp9w93**: The software's develop-refactor skill shall report a finding that needs a design item changed as not fixed, editing no design item.

**REQ-4n7v3y**: The software's develop-refactor skill shall state its report's shape.

**REQ-6axg68**: The software's develop-refactor skill shall run after each fix the tests that verify what it changes, with a fallback for a runner that cannot select, and require only those tests green.

**REQ-zcv5fw**: The software's ratchet upgrade notes shall name the guidelines file's `## Test runs` section.

**REQ-vcxj6k**: The software's config template shall declare ADR in `id_prefixes`.

**REQ-ywgg6c**: The software shall pass an ADR item that nothing references, counting it in check-trace.sh's summary.

**REQ-ezvb8b**: The software shall resolve a reference to a defined ADR ID from a ledger or a strict path.

**REQ-cntxt8**: The software shall accept an ID whose body is three or more digits as a defined item and as a reference.

**REQ-cd7tn5**: The software's check-ids.sh shall report MALFORMED-ID for an item definition whose ID body is neither a token nor three or more digits.

**REQ-yuk987**: The software shall read no prefix followed by fewer than three digits as a reference.

**REQ-wq3bq2**: The software shall pass an ADR file that defines no item.

**REQ-cf2396**: The software's check-ids.sh shall report DRAFT-ID for a draft ID token.

**REQ-ts97ry**: The software's new-id.sh shall print exactly one ID of the given declared prefix.

**REQ-62j2k5**: The software's new-id.sh shall exit 2 for a prefix not declared in `id_prefixes`.

**REQ-n99jz2**: The software shall keep each `fix <RULE>:` line's remedy to at most 200 characters.

**REQ-gtye7w**: The software's DRAFT-ID remedy shall name new-id.sh.

**REQ-xhs26z**: The software's DRAFT-FILE remedy shall direct a `git mv` to the name dated the day the change created the file.

**REQ-4qup72**: The software's check-trace.sh header shall list every report the script prints, each with one remedy entry.

**REQ-5bejtg**: The software's STALE-PROBLEM and PROBLEM-BACKLOG remedies shall offer recording a ruling as `status: accepted`.

**REQ-da2vup**: The software's UNANALYZED-DERIVED remedy shall name `assesses:`.

**REQ-y6c2u5**: The software's DANGLING-FILE message and remedy shall direct writing the name the file has now, never deleting the reference.

**REQ-5v932q**: The software's DANGLING-FILE message for a bare file name shall direct writing the path for a file in another unit.
