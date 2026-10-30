# Requirements: config and guidelines

**REQ-j6h2d9**: The software shall accept a guardrails_commit key in the config.

**REQ-fu7ux3**: The software shall exit 2, naming the key, for a config key set to nothing, scalar and list keys alike.

**REQ-y4xa6r**: The software shall exit 2 from every script run outside a git repository, printing only `guardrails: not inside a git repository`.

**REQ-656yvt**: The software shall return git's status and print no base branch when git cannot list the worktrees.

**REQ-pn4hs8**: The software shall count as nested in a worktree each worktree registered inside its directory, and no sibling.

**REQ-3z8s5a**: The software shall exit 2, naming the wrong form, for a list key written as a scalar or a scalar key written as a list.

**REQ-d9m923**: The software shall read problem_age_days, problem_open_max, expectation_age_days and expectation_open_max as whole numbers the shell can compare, exiting 2 before any check for any other value.

**REQ-72z4ed**: The software shall read `.guardrails/units.yaml` by the same grammar as the config.

**REQ-aeas98**: The software shall exit 2 for a unit manifest entry that is absolute, holds a glob character or whitespace, ends in a slash, is `.`, or reaches outside the repository.

**REQ-8rtckf**: The software shall run every script as in a single-unit repository unless a file named exactly `.guardrails/units.yaml` exists, on a case-insensitive filesystem too.

**REQ-xs9zct**: The software shall exit 2 in a repository with a unit manifest unless GR_CONFIG names a declared unit's config, naming check-units.sh and GR_CONFIG as the remedy.

**REQ-aut3rq**: The software shall take a unit's exports to be exactly the REQ items in its doc_srs whose block carries `exported: yes`.

**REQ-8x9ew2**: The software shall read a REQ block's `expects:` and `opened:` lines as its expectation's provider unit and opening date.

**REQ-82zcjv**: The software shall take a unit's consumers to be exactly the declared units whose depends_on names it.

**REQ-m3pt2e**: The software shall classify a path as a declared unit's, a not_a_unit entry's, or unclaimed, by whole path components.

**REQ-aek2sw**: The software shall run under gawk, mawk, busybox awk and BWK awk, passing awk -v no value that contains a newline.

**REQ-e3n2xj**: The software's test suite shall build a relative date, past or future, that GNU and BSD date both accept.

**REQ-myarn4**: The software's test suite shall give a fixture and the script it tests one pinned day, so a run that crosses local midnight, or a day with no local midnight, changes no result.

**REQ-epx832**: The software shall give every in-place sed an attached backup suffix, `sed -i.bak`.

**REQ-g3bthd**: The software shall open every case pattern in executable shell with a leading parenthesis.

**REQ-5s59f7**: The software's tests shall write no assertion as a bare negation.

**REQ-65dh7e**: The software's test suite shall print, for a test that did not complete, its temporary and test directories and the free inodes, blocks and open files, and keep that directory; a completed test prints nothing and releases it.

**REQ-ky9p6e**: The software shall print, for each path given, the one guidelines file of the kind asked for that governs it: its unit's `<unit>/docs/<KIND>_GUIDELINES.md`, else `docs/<KIND>_GUIDELINES.md`, else the installed default, each name matched exactly.

**REQ-qfwez4**: The software shall take the guidelines kinds TEST, CODE and ARCHITECTURE, exiting 2 and naming them for any other kind.

**REQ-tt875z**: The software shall exit 2 when the installed default of the guidelines kind asked for is missing, whether or not a project file exists.

**REQ-cu2ftg**: The software's guidelines-file.sh shall exit 2 with its usage line for no path or an empty path, and exit 2 naming an absolute path or one containing whitespace.

**REQ-kk87ut**: The software's guidelines-file.sh shall print the governing files in the order first needed, each with its paths in argument order.

**REQ-h8ms4n**: The software shall find its own installation directory the same with CDPATH exported.

**REQ-avc8hp**: The software's shipped test guidelines shall let a test fake only what is outside the codebase, the clock and randomness, put every fake under a contract test, and assert an interaction only where it is the requirement.

**REQ-v8dv6x**: The software's shipped test guidelines shall make a property test repeatable and pinned, and let a surviving mutant never justify a test below the seam.

**REQ-3ptkw8**: The software's shipped test guidelines shall keep a UI section only where the project has a user interface, take a UI's interface to be what the user perceives and does, and forbid a markup snapshot test.

**REQ-s7mbqy**: The software's test guidelines files shall bind their rules to the tests a change writes and those whose setup, doubles, calls or assertions it edits, and the floor to every test.

**REQ-zmkef8**: The software's shipped test guidelines shall have the sections Seams, Doubles, Owned services, Property tests, Mutants, UI, Test runs and Existing suites, in that order.

**REQ-kyb2hq**: The software's own test guidelines shall have the shipped sections, in their order, except UI.

**REQ-764283**: The software's shipped test guidelines shall be at most 1,950 words.

**REQ-u6wzy2**: The software's test guidelines files shall state a reason for every clause.

**REQ-bs735x**: The software's test guidelines files shall define the robustness rule where they first name it.

**REQ-mzgek2**: The software's test guidelines files shall have a Test runs clause that runs, during development, the tests of what the work touches, and the whole suite at the merge gate.

**REQ-9gt5rj**: The software's guidelines files, shipped and its own, shall exempt no test from `verifies:` or from being watched red.

**REQ-g63d3v**: The software's tailor-guidelines skill shall seed an absent `docs/<KIND>_GUIDELINES.md`, or `<unit>/docs/<KIND>_GUIDELINES.md` for a unit, as a complete copy of the root file or the installed default that names no source.

**REQ-8twuzp**: The software's tailor-guidelines skill shall walk a TEST, CODE or ARCHITECTURE file one clause per message, keep, change or drop, asking for an example in the project's own stack.

**REQ-5n6bcc**: The software's tailor-guidelines skill shall reject a change that contradicts the floor, and list the floor, its architecture items included.

**REQ-hw8cub**: The software's tailor-guidelines skill shall, in upgrade mode, walk the shipped template's changes one at a time to adopt, adapt or decline, and never overwrite the project file.

**REQ-rc4sv8**: The software's ratchet skill shall install every shipped guidelines default and run tailor-guidelines for TEST, CODE and ARCHITECTURE: at setup, as a later tooth on a retrofit, and in upgrade mode before an upgrade re-copies the templates.

**REQ-ar6ss5**: The software's ratchet skill shall direct a retrofit of a multi-unit repository to read its multi-unit reference before the first tooth.

**REQ-bhk8cr**: The software's upgrade notes shall state that a project without its own guidelines file of a kind follows the installed default, and to run tailor-guidelines for that kind.

**REQ-84wbmx**: The software's upgrade notes shall name each renamed or removed skill and how to reinstall the skills, by link and by copy.

**REQ-5zrsp9**: The software's upgrade notes shall state that a mechanical architecture constraint is an LLR with a test, and that develop-refactor fixes the architecture findings needing no design change and design-architecture the rest.
