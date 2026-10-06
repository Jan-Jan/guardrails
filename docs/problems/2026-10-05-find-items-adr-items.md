# Problem report — `find-items.sh` does not read ADR items

Found on 2026-10-05 by a run of `find-items.sh` against this repository's own
ledgers at `17a0d58`, under a scratch config built from
`templates/config.yaml` with its `doc_*` paths pointed at directories that
exist. `affects:` names files, because guardrails keeps no
REQ/SDD/LLR ledger of its own.

**PR-ka8w9m**: `find-items.sh` reads only the files of the `doc_*` keys, and an ADR is defined in `docs/adr/ADR-<token>-<slug>.md`, which no `doc_*` key names, so `list --kind ADR` exits 0 with no line and `show` of an existing ADR ID exits 1 with `NOT-FOUND`.
affects: scripts/find-items.sh.
opened: 2026-10-05
status: resolved
`ADR` is a declared prefix in the shipped `templates/config.yaml`, so
`list --kind ADR` is accepted rather than rejected. With the five ADR files on
`main` at `17a0d58`, `list --kind ADR` prints nothing and exits 0, and
`show ADR-y8jmes` prints `NOT-FOUND ADR-y8jmes` and a fix line that says the
ID may be defined in another unit, while
`docs/adr/ADR-y8jmes-local-main-is-the-base.md` opens with
`**ADR-y8jmes**:`. An agent reads the empty list as "no decision exists". ADR
IDs (`35570e8`) were merged after `find-items.sh` (`089f4b4`), and neither
change measured the other. `refs` is not affected: it searches the whole
working tree.

Resolved on 2026-10-05 by the `find-items-adr` change. When `ADR` is declared
in `id_prefixes`, `list` and `show` read each regular file that matches
`docs/adr/ADR-*.md` beside the `doc_*` files, and under a unit `GR_CONFIG`
also `<unit>/docs/adr/ADR-*.md`. These are the two places `check-units.sh`
accepts for an ADR cited by ID. A file in `docs/adr/` with another name is
not read. `show` ends an ADR's block at its first heading, as for every item,
and `list` prints `-` as an ADR's status, because the ADR form has `Status:`
rather than a column-one `status:` line; so `--status` keeps no ADR, and
the script header states it. Verified by the tests in
`tests/find-items.bats` annotated `verifies: PR-ka8w9m`.
