# Requirements: merge gate

**REQ-6vfb6a**: The software shall exit 2 when a git or awk call whose result it reads fails, never reading the failure as a state of the repository.

**REQ-sn8962**: The software's check-review.sh shall exit 2 under `--cite` in a repository with a unit manifest, naming multi-unit repositories.

**REQ-8adkd3**: The software's check-review.sh shall check disposition citations when `--cite` is given or the configuration sets `review_cite: on`, and not otherwise.

**REQ-u7qgpw**: The software's check-review.sh shall exit 2 for a `review_cite` value other than `on` or `off`.

**REQ-r725hv**: The software's check-review.sh `--cite` shall resolve a path citation only to a file inside the repository's working tree and outside `.git` that git tracks or does not ignore.

**REQ-ec624n**: The software's check-review.sh `--cite` shall not resolve an absolute path, a path with a `..` component, or a URL.

**REQ-8fx3r8**: The software's check-review.sh `--cite` shall resolve a path cited with a `:line` or `:line-line` suffix, a leading `./`, a possessive `'s` or a `#anchor`, as a markdown link target, in backticks with a space, or as `<rev>:<path>` with a 7- to 40-digit hex rev.

**REQ-9qp39w**: The software's check-review.sh `--cite` shall resolve a backtick or double-quoted span as a test name only when a test declares exactly that name: a bats `@test`, a jest `it`, `test` or `describe`, a Python `def test`, a Go `func Test` or testify suite method, or a Rust `fn`.

**REQ-z7fa9d**: The software's check-review.sh `--cite` shall resolve a test name only from a file in `test_paths`, read as a git pathspec, that git tracks or does not ignore, and from none when `test_paths` is empty.

**REQ-498ct8**: The software's check-review.sh `--cite` shall resolve an ID, bare, in backticks or possessive, only when find-items.sh finds its definition.

**REQ-xuwjw3**: The software's check-review.sh `--cite` shall count the dispositions it checked in its `checked:` line.

**REQ-gkrt4j**: The software's check-review.sh `--cite` shall exit 2 when find-items.sh or the `test_paths` search fails, neither resolving nor failing the citation.

**REQ-3xmsqp**: The software's merge-preflight.sh shall run CLEAN-TREE, BASE-MERGED, PLANS, IDS, TRACE, UNITS, REVIEW and NESTED-WORKTREE in that order, printing `preflight: <CHECK> ok` or `preflight: <CHECK> skipped (<reason>)` for each, and exit 0 when every check passes.

**REQ-sufm9q**: The software's merge-preflight.sh shall stop at the first failing check, print the output of the tool it ran and one `fix <CHECK>:` line, and exit 1.

**REQ-7rw8yx**: The software's merge-preflight.sh shall skip PLANS and REVIEW under `--before-review`.

**REQ-bkxg65**: The software's merge-preflight.sh CLEAN-TREE check shall fail on any line `git status --porcelain` prints, listing it.

**REQ-4dajcn**: The software's merge-preflight.sh BASE-MERGED check shall fail when `refs/heads/<base>`, or `origin/<base>` where that ref exists, is not an ancestor of HEAD.

**REQ-6c9zgf**: The software's merge-preflight.sh shall not read `origin/<base>` under `--local-base`, and shall print `preflight: BASE-MERGED ok (local base only)` on a pass.

**REQ-rqa72w**: The software's merge-preflight.sh NESTED-WORKTREE check shall fail when a worktree is registered inside the change worktree or none is registered for the named branch, naming remove and discard and no merge command.

**REQ-e337dy**: The software's merge-preflight.sh shall, when `.guardrails/units.yaml` exists, run check-units.sh and then check-ids.sh and check-trace.sh for every unit of the impact set of `refs/heads/<base>..HEAD`, in place of IDS and TRACE.

**REQ-w2nfbd**: The software's merge-preflight.sh shall print a passing IDS, TRACE or UNITS check's warnings before its `ok` line.

**REQ-vj67wy**: The software's merge-preflight.sh shall exit 2 before any check from the primary checkout, on a detached HEAD, on the base branch, or for a branch other than the current one, and shall print its usage line for a usage error.

**REQ-s8ufhk**: The software's merge-preflight.sh shall exit 2, printing the tool's output, when a tool a check runs exits 2.

**REQ-vjrem8**: The software's tests/run-tests.sh shall run only the `.bats` files and directories its arguments name, and every file in `tests/` when none names one.

**REQ-au82tb**: The software's tests/run-tests.sh shall pass bats `--jobs <CPU count>` when GNU parallel is installed, `RUN_TESTS_JOBS` is unset or empty and the count is above 1, and run serially otherwise.

**REQ-cc3z3w**: The software's tests/run-tests.sh shall pass `--jobs N` for `RUN_TESTS_JOBS=N` above 1, run serially for 1, and exit 2, naming the variable and value, for a value that is not a whole number from 1 to 9999.

**REQ-d4zbeu**: The software's tests/run-tests.sh shall pass a caller's own `--jobs` or `-j` through and add none, and put its own `--jobs` before the caller's arguments.

**REQ-d86bpq**: The software's tests/run-tests.sh shall name the commit it tests when the working tree, ignored files aside, matches HEAD, and otherwise state that it tests no commit or that the commit is unknown.

**REQ-82hmkm**: The software's tests/run-tests.sh shall fail a passing run whose tree or HEAD changed during it, or whose tree it could not read after it, and keep a failing suite's own status.

**REQ-3um87g**: The software's tests/run-tests.sh shall leave the checkout's index and `TMPDIR` as it found them.

**REQ-2d5tsw**: The software's test suite shall give the same results whatever the developer's global, XDG or system git configuration sets.

**REQ-e6ej6b**: The software's test suite shall give the same results run in parallel as run serially.

**REQ-89mnna**: The software's check-signing.sh shall read a commit's verdict the same with `log.showSignature` set.

**REQ-3dxnhf**: The software's check-signing.sh shall print the verifier's own reason once, under a failed or untrusted verdict.

**REQ-ftg567**: The software's check-signing.sh shall not call a signature bad, expired or revoked when its verifier could not run.

**REQ-69eacq**: The software's check-signing.sh shall fail, with or without `--strict`, a commit whose verdict git could not compute.

**REQ-d6vwa2**: The software's check-signing.sh shall exit 2 when the trust root or gpg keyring exists but cannot be read, and exit 1 when a configured trust root is absent.

**REQ-ngmbw6**: The software's check-signing.sh shall count a commit as signed only by its `gpgsig` header, not by its message.

**REQ-mf8nxj**: The software's check-signing.sh `--setup` shall read an unset `gpg.format` as openpgp.

**REQ-vzja7g**: The software's check-signing.sh `--setup` shall ignore a worktree-scoped `commit.gpgsign false`, and report MISSING where the shared configuration never sets `commit.gpgsign`.

**REQ-x2naak**: The software's install.sh shall write, under `--copy`, the checkout's path as the one line of `.guardrails-source` in each copied skill.

**REQ-j6euez**: The software's install.sh shall, without `--copy`, link each skill and write nothing into the checkout.
