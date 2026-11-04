# Requirements: example paths

**REQ-v2wmnh**: The software shall accept an optional example_paths list key in the config, each entry a path resolved as a strict_paths entry is, and with the key absent run every gate as without it.

**REQ-mmfxd8**: The software's check-ids.sh and check-trace.sh shall exit 2, naming the entry, for an example_paths entry that matches no file present in the working tree.

**REQ-h7cjtr**: The software's check-ids.sh and check-trace.sh shall exit 2, naming the entry and the file, for an example_paths entry that matches a file a doc_* key resolves to.

**REQ-esb4nh**: The software's check-ids.sh and check-trace.sh shall read no `**ID**:` line in a file an example_paths entry matches as an item definition.

**REQ-5smhcm**: The software's check-ids.sh shall report no DRAFT-ID from a file an example_paths entry matches.

**REQ-3e7gxt**: The software's check-trace.sh shall read no reference for DANGLING-REF and no citation for HISTORY-CITATION from a file an example_paths entry matches, except the IDs on a `verifies:` line whose keyword is preceded on that line only by blanks and the characters `#`, `/`, `-`, `;` and `*`.

**REQ-7tdvfe**: The software's check-trace.sh shall count a `verifies:` annotation in a file an example_paths entry matches toward MISSING-TEST only when its keyword is preceded on that line only by blanks and the characters `#`, `/`, `-`, `;` and `*`.

**REQ-6pnt2j**: The software's check-trace.sh shall end its `sources:` line with `examples N`, N the number of example_paths entries, 0 when the key is absent.

**REQ-ptg7rd**: The software's check-signing.sh shall exit 2, naming a writable GNUPGHOME copy of pubring.kbx and trustdb.gpg as the fix, when the gpg keyring's trustdb.gpg exists but cannot be opened read-write.

**REQ-ycwkd5**: The software's check-signing.sh `--setup` shall name each missing signing setting on its own MISSING line in one run.

**REQ-wnvm4a**: The software's new-id.sh shall exit 2, saying no usable randomness came from its source, when that source yields no usable byte, and saying the token is already present in the tree when every token it draws is taken.

**REQ-m9b22v**: The software's new-id.sh shall exit 2 without opening a randomness source that is a FIFO.

**REQ-smh4jf**: The software's check-trace.sh shall read a satisfies:, traces:, implements: or mitigates: annotation inside its item's block only where the keyword starts at column one or stands on the item's definition line.

**REQ-ae3zr8**: The software's check-trace.sh shall report ORPHAN-ANNOTATION for an annotation keyword at column one, or after a run of list markers, task-list boxes and blockquote markers, that lies in no item block, and for a satisfies:, traces:, implements: or mitigates: keyword after such a run inside its item's block, skipping only YAML front matter: a `---` line on line 1 followed by a key.
