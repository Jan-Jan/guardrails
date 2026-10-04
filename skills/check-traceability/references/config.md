# Config errors and config gaps

Read this when a run exits 2, when a `sources:` figure is zero, or before
editing `.guardrails/config.yaml`.

## Exit 2

Exit 2 is an environment error and always fatal, because each of these would
otherwise let a gate pass without running. Fix the config; never work around
it by removing the prefix.

| Message | Cause |
|---|---|
| `doc_rmf is configured as 'docs/risk', which does not exist` | A configured path that is absent. |
| `doc_rmf is configured as directory 'docs/risk', which contains no *.md files` | A ledger directory with nothing in it — including the case where the `*.md` files are in a **subdirectory**, since `doc_*` directories are read one level deep only. |
| `id_prefixes entry is not a bare identifier: PR[` | A prefix is interpolated into every scan pattern; a metacharacter makes the pattern invalid, and a scan that errors finds nothing — indistinguishable from a clean tree. |
| `unknown config key(s): doc_rmff` | A mistyped key. Nothing reads it, so the gate it was meant to configure never runs. |
| `config line(s) that are neither a comment, a top-level key, nor a '  - item' belonging to one` | A key that is not `identifier:` at column one (`strict-paths:`, ` strict_paths:`, `strict_paths :`); a list item at column zero; or a list item **orphaned** from its key by a column-one comment or a `---` separator above it. An orphan is ambiguous — it either vanishes with its list or is adopted by the block above — so it is rejected. Commenting a list key out means commenting its items out too. |
| `config begins with a UTF-8 BOM` | The BOM makes the first key unreadable, that is, absent. |
| `config has carriage returns inside a line` | A `\r`-only file is one single record to every reader here, so every key but the first is invisible. Save it with LF or CRLF endings. |
| `cannot read <config> — it exists but this user cannot open it` | Every scan below this would print nothing and pass vacuously, and the verdict would come from an unrelated check naming the wrong cause. |
| `config key(s) set more than once` | Every reader takes the FIRST occurrence and stops, while YAML takes the last — so one of the two is read by nobody. Appending a second `verify_commands:` below the first means the real suite never runs. |
| `config key(s) set to nothing` | A key with no value and no items reads as absent to the gate that uses it, and that gate then passes having examined nothing. Give it a value — deleting it is not the remedy, since absent is the same gate-off. |
| `config key(s) written in the wrong form` | A list key set to a scalar (`strict_paths: src`), or a scalar key set to `  - items` (`doc_soup:`). Read by nobody in either direction. |
| `config key(s) with a commented-out item` | `  - # make test` remains an item whose value starts with `#` — the `#` is stripped from a value only when whitespace precedes it, and the dash strip removed that. For a command key the shell reads it as a comment, so the step runs nothing and reports success. |
| `config key(s) with an item that has no value after its '-'` | Dropped by every reader, so the list that takes effect is shorter than the one written. |
| `strict_paths names no path` | It is the entire scope of the source scan. With none, a reference to an ID nobody defined is never looked for and the run exits 0 having examined no code. |
| `id_prefixes names no prefix with a traceability gate` | At least one of REQ, HAZ, RC, SDD, LLR, PR must appear. Extra prefixes alongside them are fine — `DANGLING-REF`, `DUPLICATE-ID` and ID finalization are keyed on the whole prefix list, so they are checked, just not by a gate of their own. Without any of the six the only checks left are those, and a config that also omits the document keys runs nothing at all. |
| `id_prefixes declares RC but doc_srs is not configured` | A declared prefix needs the documents its gates READ, which is not always where it is defined: `UNIMPLEMENTED-CONTROL` looks for a REQ that implements each RC, so RC needs `doc_srs`. |
| `id_prefixes declares RC but doc_rmf is not configured` | A prefix also needs the one document it may be DEFINED in, because `MISPLACED-ITEM` reads it. A control is defined in the RMF, so `RC` needs `doc_rmf` as well — unconfigured, every control in the project would be misplaced. |
| `id_prefixes declares REQ/LLR but test_paths is empty` | Nothing would be searched for `verifies:`. |
| `strict_paths entry matches no file present in the working tree: src/*.rs` | A `strict_paths`/`test_paths` entry matching nothing. These are **git pathspecs** — a plain path, or a pattern like `*_test.sh` that git matches recursively. An entry matching nothing scans nothing, and an empty directory matches no file. |

## What config validation does not catch

The config is validated, and every shape above is exit 2. Three settings still
narrow what the gates check without any error:

- `doc_soup` is required by no prefix, so omitting it narrows what
  `DANGLING-REF` scans. A zero in `sources:` is where that shows.
- `verify_commands` absent means the merge gate runs no commands and reports
  that nothing failed. The schema does not require it, because nothing in
  these scripts reads it.
- Dropping a prefix from `id_prefixes` does **not** switch its gates off.
  `MISSING-TEST` is keyed on `test_paths` and the rest on the document lists,
  so all of them keep firing. What it removes is that prefix from `checked:`
  and from `DANGLING-REF`'s scope, so references to it stop being checked
  while its other gates continue to run.

A zero in `sources:` for a document the project has means its key is absent,
since a configured but empty ledger directory is itself exit 2.
